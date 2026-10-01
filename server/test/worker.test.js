import assert from 'node:assert/strict';
import { test } from 'node:test';

import worker, { handleTelegram } from '../src/index.js';
import { pushToMirror, signingKey, signPut } from '../src/mirror.js';
import { ConfigStore } from '../src/store.js';
import { FakeKV, fakeFetch } from './helpers.js';

const ADMIN = 4242;
const ctx = { waitUntil() {} };

function env(kv = new FakeKV(), extra = {}) {
  return {
    CONFIG: kv,
    TELEGRAM_BOT_TOKEN: 'bot-token',
    TG_SECRET_TOKEN: 'tg-secret',
    WEBHOOK_PATH: 'hook-path',
    ADMIN_TELEGRAM_ID: String(ADMIN),
    ...extra,
  };
}

function update(text, fromId = ADMIN, messageId = 1) {
  return new Request('https://w.example/tg/hook-path', {
    method: 'POST',
    headers: { 'x-telegram-bot-api-secret-token': 'tg-secret', 'content-type': 'application/json' },
    body: JSON.stringify({
      update_id: 1,
      message: { message_id: messageId, from: { id: fromId, username: 'me' }, chat: { id: fromId }, text },
    }),
  });
}

const replies = (f) => f.calls.filter((c) => c.url.endsWith('/sendMessage')).map((c) => c.body.text);

test('GET /config.json serves the bundled default until something is published', async () => {
  const res = await worker.fetch(new Request('https://w.example/config.json'), env(), ctx);
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('cache-control'), 'public, max-age=300');
  const body = await res.json();
  assert.equal(body.config_version, 0);
  assert.equal(body.ads.active_provider.bazaar, 'adivery');
});

test('unknown paths and wrong webhook path → 404', async () => {
  assert.equal((await worker.fetch(new Request('https://w.example/x'), env(), ctx)).status, 404);
  const wrong = new Request('https://w.example/tg/guess', { method: 'POST', body: '{}' });
  assert.equal((await worker.fetch(wrong, env(), ctx)).status, 404);
});

test('webhook without the secret token header → 404, nothing changes', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  const req = new Request('https://w.example/tg/hook-path', {
    method: 'POST',
    body: JSON.stringify({ message: { from: { id: ADMIN }, chat: { id: ADMIN }, text: '/ads off' } }),
  });
  const res = await handleTelegram(req, env(kv), ctx, f);
  assert.equal(res.status, 404);
  assert.equal(kv.map.size, 0);
  assert.equal(f.calls.length, 0);
});

test('non-admin users are ignored silently', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  const res = await handleTelegram(update('/ads off', 999), env(kv), ctx, f);
  assert.equal(res.status, 200);
  assert.equal(kv.map.size, 0);
  assert.equal(f.calls.length, 0);
});

test('admin change: bumps version, keeps history, logs, replies with summary', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  await handleTelegram(update('/provider play tapsell'), env(kv), ctx, f);
  const store = new ConfigStore(kv);
  const current = await store.current();
  assert.equal(current.config_version, 1);
  assert.equal(current.ads.active_provider.play, 'tapsell');
  assert.equal((await store.history())[0].config_version, 0);
  const [log] = await store.log();
  assert.equal(log.command, '/provider play tapsell');
  assert.equal(log.actor, 'me');
  assert.ok(log.ts);
  assert.match(replies(f)[0], /play → tapsell[\s\S]*config v1/);

  // The served config follows.
  const served = await (await worker.fetch(new Request('https://w.example/config.json'), env(kv), ctx)).json();
  assert.equal(served.config_version, 1);
});

test('rejected change publishes nothing', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  await handleTelegram(update('/provider myket admob'), env(kv), ctx, f);
  assert.equal(kv.map.has('config:current'), false);
  assert.match(replies(f)[0], /not allowed/);
});

test('/rollback restores previous content under a higher version', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  const e = env(kv);
  await handleTelegram(update('/every 5'), e, ctx, f); // v1
  await handleTelegram(update('/ads off'), e, ctx, f); // v2
  await handleTelegram(update('/rollback'), e, ctx, f); // v3 = content of v1
  const store = new ConfigStore(kv);
  let c = await store.current();
  assert.equal(c.config_version, 3);
  assert.equal(c.ads.enabled, true);
  assert.equal(c.ads.interstitial_every_n_rounds, 5);
  await handleTelegram(update('/rollback'), e, ctx, f); // v4 = content of v0
  c = await store.current();
  assert.equal(c.config_version, 4);
  assert.equal(c.ads.interstitial_every_n_rounds, 3);
  await handleTelegram(update('/rollback'), e, ctx, f);
  assert.match(replies(f).at(-1), /Nothing to roll back/);
});

test('history keeps the last 10 versions', async () => {
  const kv = new FakeKV();
  const store = new ConfigStore(kv);
  for (let i = 1; i <= 15; i++) {
    const c = await store.current();
    c.ads.interstitial_every_n_rounds = (i % 10) + 1;
    await store.publish(c, { actor: 't', command: `#${i}` });
  }
  const h = await store.history();
  assert.equal(h.length, 10);
  assert.equal(h[0].config_version, 14);
  assert.equal((await store.current()).config_version, 15);
});

test('/keys guided flow over the webhook: secret message deleted, never logged', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  const e = env(kv);
  await handleTelegram(update('/keys', ADMIN, 10), e, ctx, f);
  await handleTelegram(update('adivery', ADMIN, 11), e, ctx, f);
  await handleTelegram(update('interstitial_placement', ADMIN, 12), e, ctx, f);
  await handleTelegram(update('PLACEMENT-SECRET-99', ADMIN, 13), e, ctx, f);
  const c = await new ConfigStore(kv).current();
  assert.equal(c.ads.providers.adivery.interstitial_placement, 'PLACEMENT-SECRET-99');
  const deleted = f.calls.filter((x) => x.url.endsWith('/deleteMessage'));
  assert.deepEqual(deleted.map((d) => d.body.message_id), [13]);
  assert.ok(!replies(f).join('\n').includes('PLACEMENT-SECRET-99'));
  assert.ok(!JSON.stringify(await new ConfigStore(kv).log()).includes('PLACEMENT-SECRET-99'));
  assert.equal(await kv.get('session:4242'), null);
  // Session writes expire.
  assert.ok(kv.puts.filter((p) => p.key === 'session:4242').every((p) => p.opts?.expirationTtl === 600));
});

test('long replies are split under Telegram’s 4096 limit', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  const store = new ConfigStore(kv);
  const c = await store.current();
  c.ads.providers = { adivery: {} };
  for (const k of ['app_id', 'interstitial_placement', 'rewarded_placement', 'banner_placement']) {
    c.ads.providers.adivery[k] = 'x'.repeat(190);
  }
  c.message = 'm'.repeat(500);
  await store.publish(c, { actor: 't', command: 'seed' });
  await handleTelegram(update('/show'), env(kv), ctx, f);
  assert.ok(replies(f).every((t) => t.length <= 4096));
});

// AWS documented SigV4 key-derivation example
// (secret wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY, 20150830, us-east-1, iam).
test('SigV4 signing key matches the AWS example', async () => {
  const key = await signingKey('wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY', '20150830', 'us-east-1', 'iam');
  const hex = [...new Uint8Array(key)].map((b) => b.toString(16).padStart(2, '0')).join('');
  assert.equal(hex, 'c4afb1cc5771d871763a393e44b703571b55cc28424d1a5e86da6ed3c154a4b9');
});

test('mirror upload: signed PUT with all x-amz headers signed', async () => {
  const headers = await signPut({
    url: 'https://s3.ir-thr-at1.arvanstorage.ir/bucket/config.json',
    body: '{}',
    contentType: 'application/json',
    accessKeyId: 'AK',
    secretAccessKey: 'SK',
    region: 'default',
    extraHeaders: { 'x-amz-acl': 'public-read' },
    now: new Date('2026-01-02T03:04:05Z'),
  });
  assert.equal(headers['x-amz-date'], '20260102T030405Z');
  assert.match(
    headers.authorization,
    /^AWS4-HMAC-SHA256 Credential=AK\/20260102\/default\/s3\/aws4_request, SignedHeaders=content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date, Signature=[0-9a-f]{64}$/,
  );

  const f = fakeFetch();
  const ok = await pushToMirror(
    {
      MIRROR_ENDPOINT: 'https://s3.example.ir/',
      MIRROR_BUCKET: 'b',
      MIRROR_ACCESS_KEY_ID: 'AK',
      MIRROR_SECRET_ACCESS_KEY: 'SK',
    },
    '{"a":1}',
    f,
  );
  assert.equal(ok, true);
  assert.equal(f.calls[0].url, 'https://s3.example.ir/b/config.json');
  assert.equal(f.calls[0].init.method, 'PUT');
  assert.equal(await pushToMirror({}, '{}', f), false);
});

test('a change with the mirror configured pushes the new config', async () => {
  const kv = new FakeKV();
  const f = fakeFetch();
  await handleTelegram(
    update('/every 4'),
    env(kv, {
      MIRROR_ENDPOINT: 'https://s3.example.ir',
      MIRROR_BUCKET: 'b',
      MIRROR_ACCESS_KEY_ID: 'AK',
      MIRROR_SECRET_ACCESS_KEY: 'SK',
    }),
    ctx,
    f,
  );
  const put = f.calls.find((c) => c.init.method === 'PUT');
  assert.equal(put.body.ads.interstitial_every_n_rounds, 4);
  assert.match(replies(f)[0], /mirror updated/);
});
