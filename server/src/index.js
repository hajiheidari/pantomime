// Cloudflare Worker: serves the app's remote config and hosts the Telegram
// control bot.
//
//   GET  /config.json                  → current config (cached 5 min)
//   GET  /words_fa.json                → current word list (cached 5 min)
//   GET  /privacy                      → privacy policy page (fa + en)
//   POST /tg/<WEBHOOK_PATH>            → Telegram webhook (admin only)
//
// Bindings (see wrangler.toml / README):
//   CONFIG             KV namespace
//   TELEGRAM_BOT_TOKEN secret
//   TG_SECRET_TOKEN    secret, also passed to setWebhook as secret_token
//   WEBHOOK_PATH       secret, random path segment for the webhook URL
//   ADMIN_TELEGRAM_ID  your numeric Telegram user id; everyone else ignored
//   MIRROR_*           optional S3-compatible mirror (see mirror.js)
import { runCommand } from './commands.js';
import { summary } from './config.js';
import { mirrorEnabled, pushToMirror } from './mirror.js';
import { privacyHtml } from './privacy.js';
import { ConfigStore, WordStore } from './store.js';
import { runWordsCommand, validatePack, WordsError } from './words.js';

const CONFIG_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'public, max-age=300',
  'access-control-allow-origin': '*',
};

const cacheKey = (url, path = '/config.json') => new Request(new URL(path, url).toString());

async function serveCached(request, ctx, path, load) {
  const cache = typeof caches !== 'undefined' ? caches.default : null;
  if (cache) {
    const hit = await cache.match(cacheKey(request.url, path));
    if (hit) return hit;
  }
  const res = new Response(JSON.stringify(await load()), { headers: CONFIG_HEADERS });
  if (cache) ctx.waitUntil(cache.put(cacheKey(request.url, path), res.clone()));
  return res;
}

const serveConfig = (request, env, ctx) =>
  serveCached(request, ctx, '/config.json', () => new ConfigStore(env.CONFIG).current());

const serveWords = (request, env, ctx) =>
  serveCached(request, ctx, '/words_fa.json', () => new WordStore(env.CONFIG).current());

/** Constant-time string comparison for secrets. */
function safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function telegram(env, method, payload, fetchFn) {
  try {
    return await fetchFn(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/${method}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch {
    // Telegram unreachable: nothing else to do.
  }
}

async function reply(env, chatId, text, fetchFn) {
  // Telegram limit is 4096 characters per message.
  for (let i = 0; i < text.length; i += 4000) {
    await telegram(env, 'sendMessage', { chat_id: chatId, text: text.slice(i, i + 4000) }, fetchFn);
  }
}

/** Sends the current word list to the admin as a .json file. */
async function sendWordsFile(env, chatId, pack, fetchFn) {
  const form = new FormData();
  form.append('chat_id', String(chatId));
  form.append('caption', `words v${pack.version}. Edit and send the file back to replace the list.`);
  form.append(
    'document',
    new Blob([JSON.stringify(pack, null, 2)], { type: 'application/json' }),
    `words_fa_v${pack.version}.json`,
  );
  try {
    await fetchFn(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendDocument`, {
      method: 'POST',
      body: form,
    });
  } catch {
    // Telegram unreachable.
  }
}

/** Downloads a .json file the admin sent and checks it. */
async function receiveWordsFile(env, doc, fetchFn) {
  if (!/\.json$/i.test(doc.file_name ?? '')) throw new WordsError('send a .json file');
  if ((doc.file_size ?? 0) > 2 * 1024 * 1024) throw new WordsError('file too big (max 2 MB)');
  const info = await (await telegram(env, 'getFile', { file_id: doc.file_id }, fetchFn))?.json();
  const path = info?.result?.file_path;
  if (!path) throw new WordsError('could not download the file from Telegram');
  const res = await fetchFn(`https://api.telegram.org/file/bot${env.TELEGRAM_BOT_TOKEN}/${path}`);
  let pack;
  try {
    pack = JSON.parse((await res.text()).replace(/^\uFEFF/, ''));
  } catch {
    throw new WordsError('the file is not valid JSON');
  }
  pack.language ??= 'fa';
  pack.version = Number.isInteger(pack.version) ? pack.version : 1;
  validatePack(pack);
  return pack;
}

async function handleWords(env, ctx, request, msg, cmd, restText, fetchFn) {
  const chatId = msg.chat.id;
  const words = new WordStore(env.CONFIG);
  const actor = msg.from.username ?? String(msg.from.id);
  let published = null;
  let text;
  try {
    if (msg.document) {
      published = await words.publish(await receiveWordsFile(env, msg.document, fetchFn), {
        actor,
        command: `words file ${msg.document.file_name}`,
      });
      text = '📥 Word list replaced from your file.';
    } else {
      const current = await words.current();
      const result = runWordsCommand(cmd, restText, current);
      text = result.reply;
      if (result.sendFile) {
        await sendWordsFile(env, chatId, current, fetchFn);
        return;
      }
      if (result.undo) {
        published = await words.undo({ actor });
        text = published ? '↩️ Word list restored.' : '⚠️ Nothing to undo.';
      } else if (result.pack) {
        published = await words.publish(result.pack, { actor, command: msg.text.slice(0, 200) });
      }
    }
  } catch (e) {
    if (!(e instanceof WordsError)) throw e;
    text = `⚠️ ${e.message}. The word list was not changed.`;
  }
  if (published) {
    const cache = typeof caches !== 'undefined' ? caches.default : null;
    if (cache) ctx.waitUntil(cache.delete(cacheKey(request.url, '/words_fa.json')));
    text += `\n\n📚 words v${published.version} published. Phones get it within a few hours.`;
  }
  await reply(env, chatId, text, fetchFn);
}

async function afterChange(env, ctx, request, config, fetchFn) {
  const json = JSON.stringify(config);
  const cache = typeof caches !== 'undefined' ? caches.default : null;
  if (cache) ctx.waitUntil(cache.delete(cacheKey(request.url)));
  if (mirrorEnabled(env)) return pushToMirror(env, json, fetchFn);
  return null;
}

export async function handleTelegram(request, env, ctx, fetchFn = fetch) {
  if (!safeEqual(request.headers.get('x-telegram-bot-api-secret-token') ?? '', env.TG_SECRET_TOKEN ?? '')) {
    return new Response('not found', { status: 404 });
  }
  let update;
  try {
    update = await request.json();
  } catch {
    return new Response('ok');
  }
  const msg = update.message ?? update.edited_message;
  // Allow-list: everyone except the admin is ignored silently.
  if (!(msg?.text || msg?.document) || String(msg.from?.id) !== String(env.ADMIN_TELEGRAM_ID)) {
    return new Response('ok');
  }
  const chatId = msg.chat.id;
  const [head = ''] = (msg.text ?? '').trim().split(/\s+/);
  const cmd = head.split('@')[0].toLowerCase();
  if (msg.document || ['/words', '/wordsfile', '/wordsundo', '/addword', '/delword', '/findword'].includes(cmd)) {
    const restText = (msg.text ?? '').trim().slice(head.length).trim();
    await handleWords(env, ctx, request, msg, cmd, restText, fetchFn);
    return new Response('ok');
  }
  const store = new ConfigStore(env.CONFIG);
  const actor = msg.from.username ?? String(msg.from.id);
  const current = await store.current();
  const session = await store.session(chatId);
  const result = runCommand(msg.text, current, session);

  if (result.session !== undefined) await store.setSession(chatId, result.session);
  if (result.deleteMessage) {
    await telegram(env, 'deleteMessage', { chat_id: chatId, message_id: msg.message_id }, fetchFn);
  }

  let text = result.reply;
  let published = null;
  if (result.rollback) {
    published = await store.rollback({ actor });
    text = published ? `↩️ Rolled back.` : '⚠️ Nothing to roll back to.';
  } else if (result.config) {
    // Never log secrets: ids are masked in the command text.
    const command = msg.text.startsWith('/keys') || session?.step === 'value'
      ? '/keys (id changed)'
      : msg.text.slice(0, 200);
    published = await store.publish(result.config, { actor, command });
  }
  if (published) {
    const mirrored = await afterChange(env, ctx, request, published, fetchFn);
    text += `\n\n${summary(published)}`;
    if (mirrored === false) text += '\n⚠️ mirror upload failed';
    if (mirrored === true) text += '\n🪞 mirror updated';
  }
  await reply(env, chatId, text, fetchFn);
  return new Response('ok');
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if ((request.method === 'GET' || request.method === 'HEAD') && url.pathname === '/config.json') {
      return serveConfig(request, env, ctx);
    }
    if ((request.method === 'GET' || request.method === 'HEAD') && url.pathname === '/words_fa.json') {
      return serveWords(request, env, ctx);
    }
    if (request.method === 'POST' && env.WEBHOOK_PATH && url.pathname === `/tg/${env.WEBHOOK_PATH}`) {
      return handleTelegram(request, env, ctx);
    }
    if (url.pathname === '/privacy') {
      return new Response(privacyHtml(env.CONTACT_EMAIL), {
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'public, max-age=3600',
        },
      });
    }
    if (url.pathname === '/') return new Response('pantomime config: ok');
    return new Response('not found', { status: 404 });
  },
};
