import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import worker, { handleTelegram } from '../src/index.js';
import { bundledPack, countWords, normalizeWord, runWordsCommand, validatePack, WordsError } from '../src/words.js';
import { FakeKV, fakeFetch } from './helpers.js';

const ADMIN = 4242;
const ctx = { waitUntil() {} };
const env = (kv = new FakeKV()) => ({
  CONFIG: kv,
  TELEGRAM_BOT_TOKEN: 'bot-token',
  TG_SECRET_TOKEN: 'tg-secret',
  WEBHOOK_PATH: 'hook-path',
  ADMIN_TELEGRAM_ID: String(ADMIN),
});
const msg = (message) =>
  new Request('https://w.example/tg/hook-path', {
    method: 'POST',
    headers: { 'x-telegram-bot-api-secret-token': 'tg-secret' },
    body: JSON.stringify({
      update_id: 1,
      message: { message_id: 1, from: { id: ADMIN, username: 'me' }, chat: { id: ADMIN }, ...message },
    }),
  });
const replies = (f) => f.calls.filter((c) => c.url.endsWith('/sendMessage')).map((c) => c.body.text);

test('bundled pack is the app asset and valid', () => {
  const asset = JSON.parse(readFileSync(new URL('../../assets/words/words_fa.json', import.meta.url)));
  assert.deepEqual(bundledPack(), asset);
  validatePack(bundledPack());
});

test('normalizeWord matches the app (yeh, kaf, half-space, spaces)', () => {
  assert.equal(normalizeWord('مي‌روم'), normalizeWord('میروم'));
  assert.equal(normalizeWord('كتاب'), normalizeWord('کتاب'));
  assert.equal(normalizeWord('شیر شاه'), normalizeWord('شیرشاه'));
});

test('/addword: by id, emoji or title, level aliases, duplicates skipped', () => {
  const pack = bundledPack();
  const cat = pack.categories[0];
  const existing = cat.words.easy[0];
  const r = runWordsCommand('/addword', `${cat.id} سخت کلمه‌یک، کلمه دو\n${existing}`, pack);
  const added = r.pack.categories[0];
  assert.ok(added.words.hard.includes('کلمه‌یک'));
  assert.ok(added.words.hard.includes('کلمه دو'));
  assert.equal(countWords(r.pack), countWords(pack) + 2);
  assert.match(r.reply, /2 added/);
  assert.match(r.reply, /already in/);

  const byEmoji = runWordsCommand('/addword', `${cat.emoji} واژه`, pack);
  assert.ok(byEmoji.pack.categories[0].words.medium.includes('واژه'));
  const byTitle = runWordsCommand('/addword', `${cat.title.split(' ')[0]} x`, pack);
  if (!cat.title.includes(' ')) assert.ok(byTitle.pack);

  assert.equal(runWordsCommand('/addword', 'nope word', pack).pack, undefined);
  assert.equal(runWordsCommand('/addword', `${cat.id} ${existing}`, pack).pack, undefined);
});

test('/delword removes everywhere, reports missing; /findword', () => {
  const pack = bundledPack();
  const w = pack.categories[1].words.medium[0];
  assert.match(runWordsCommand('/findword', w, pack).reply, new RegExp(pack.categories[1].id));
  const r = runWordsCommand('/delword', `${w}، ناموجود‌ترین`, pack);
  assert.equal(countWords(r.pack), countWords(pack) - 1);
  assert.match(r.reply, /not found/);
  assert.match(runWordsCommand('/findword', w, r.pack).reply, /not in the list/);
});

test('validatePack rejects what the app would reject', () => {
  const bad = [
    { ...bundledPack(), version: 0 },
    { ...bundledPack(), language: 'en' },
    { ...bundledPack(), categories: bundledPack().categories.slice(0, 2) },
    { version: 2, language: 'fa', categories: [{ id: 'a', title: 'a', words: { easy: ['x'] } }] },
  ];
  for (const p of bad) assert.throws(() => validatePack(p), WordsError);
});

test('GET /words_fa.json: bundled until edited, then the new version', async () => {
  const kv = new FakeKV();
  let res = await worker.fetch(new Request('https://w.example/words_fa.json'), env(kv), ctx);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).version, bundledPack().version);

  const f = fakeFetch();
  const cat = bundledPack().categories[0].id;
  await handleTelegram(msg({ text: `/addword ${cat} easy واژه‌ی نو` }), env(kv), ctx, f);
  assert.match(replies(f).at(-1), /words v2 published/);

  res = await worker.fetch(new Request('https://w.example/words_fa.json'), env(kv), ctx);
  const pack = await res.json();
  assert.equal(pack.version, 2);
  assert.ok(pack.categories[0].words.easy.includes('واژه‌ی نو'));

  await handleTelegram(msg({ text: '/wordsundo' }), env(kv), ctx, f);
  res = await worker.fetch(new Request('https://w.example/words_fa.json'), env(kv), ctx);
  const undone = await res.json();
  assert.equal(undone.version, 3);
  assert.ok(!undone.categories[0].words.easy.includes('واژه‌ی نو'));
});

test('a .json file sent to the bot replaces the list; a broken one does not', async () => {
  const kv = new FakeKV();
  const edited = bundledPack();
  edited.categories[0].words.easy.push('از فایل');
  const files = { good: JSON.stringify(edited), bad: '{"version": 3, "categories": []}' };
  const calls = [];
  const f = async (url, init = {}) => {
    url = String(url);
    calls.push({ url, body: init.body && typeof init.body === 'string' ? JSON.parse(init.body) : null });
    if (url.endsWith('/getFile')) {
      const id = JSON.parse(init.body).file_id;
      return Response.json({ ok: true, result: { file_path: `docs/${id}.json` } });
    }
    const m = /\/file\/botbot-token\/docs\/(\w+)\.json$/.exec(url);
    if (m) return new Response(files[m[1]]);
    return Response.json({ ok: true });
  };
  const said = () => calls.filter((c) => c.url.endsWith('/sendMessage')).map((c) => c.body.text).at(-1);

  await handleTelegram(msg({ document: { file_id: 'bad', file_name: 'w.json', file_size: 50 } }), env(kv), ctx, f);
  assert.match(said(), /not changed/);
  assert.equal(kv.map.get('words:fa'), undefined);

  await handleTelegram(msg({ document: { file_id: 'good', file_name: 'w.json', file_size: 50 } }), env(kv), ctx, f);
  assert.match(said(), /replaced/);
  assert.ok(JSON.parse(kv.map.get('words:fa')).categories[0].words.easy.includes('از فایل'));

  await handleTelegram(msg({ document: { file_id: 'good', file_name: 'w.txt', file_size: 50 } }), env(kv), ctx, f);
  assert.match(said(), /\.json/);
});

test('/wordsfile sends a document; strangers are ignored', async () => {
  const f = fakeFetch();
  await handleTelegram(msg({ text: '/wordsfile' }), env(), ctx, f);
  assert.ok(f.calls.some((c) => c.url.endsWith('/sendDocument')));

  const kv = new FakeKV();
  const g = fakeFetch();
  const stranger = new Request('https://w.example/tg/hook-path', {
    method: 'POST',
    headers: { 'x-telegram-bot-api-secret-token': 'tg-secret' },
    body: JSON.stringify({ message: { from: { id: 1 }, chat: { id: 1 }, text: '/delword x' } }),
  });
  await handleTelegram(stranger, env(kv), ctx, g);
  assert.equal(g.calls.length, 0);
  assert.equal(kv.map.size, 0);
});
