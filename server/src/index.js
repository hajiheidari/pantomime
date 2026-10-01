// Cloudflare Worker: serves the app's remote config and hosts the Telegram
// control bot.
//
//   GET  /config.json                  → current config (cached 5 min)
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
import { ConfigStore } from './store.js';

const CONFIG_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'public, max-age=300',
  'access-control-allow-origin': '*',
};

const cacheKey = (url) => new Request(new URL('/config.json', url).toString());

async function serveConfig(request, env, ctx) {
  const cache = typeof caches !== 'undefined' ? caches.default : null;
  if (cache) {
    const hit = await cache.match(cacheKey(request.url));
    if (hit) return hit;
  }
  const config = await new ConfigStore(env.CONFIG).current();
  const res = new Response(JSON.stringify(config), { headers: CONFIG_HEADERS });
  if (cache) ctx.waitUntil(cache.put(cacheKey(request.url), res.clone()));
  return res;
}

/** Constant-time string comparison for secrets. */
function safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function telegram(env, method, payload, fetchFn) {
  try {
    await fetchFn(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/${method}`, {
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
  if (!msg?.text || String(msg.from?.id) !== String(env.ADMIN_TELEGRAM_ID)) {
    return new Response('ok');
  }
  const chatId = msg.chat.id;
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
    if (request.method === 'POST' && env.WEBHOOK_PATH && url.pathname === `/tg/${env.WEBHOOK_PATH}`) {
      return handleTelegram(request, env, ctx);
    }
    if (url.pathname === '/') return new Response('pantomime config: ok');
    return new Response('not found', { status: 404 });
  },
};
