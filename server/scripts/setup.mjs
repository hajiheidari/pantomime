#!/usr/bin/env node
// One-command Cloudflare + Telegram setup for the config Worker.
//
//   cd server && node scripts/setup.mjs
//
// Reads (environment variables, never pasted into chat or committed):
//   CLOUDFLARE_API_TOKEN   API token, template "Edit Cloudflare Workers"
//   CLOUDFLARE_ACCOUNT_ID  optional; the first account is used when missing
//   TELEGRAM_BOT_TOKEN     from @BotFather
//   ADMIN_TELEGRAM_ID      your numeric id (from @userinfobot)
//   CONTACT_EMAIL          optional, shown on /privacy
//   MIRROR_*               optional S3 mirror (see README)
//
// Does: verify token → pick account → make sure a workers.dev subdomain
// exists → create/reuse the KV namespace (writes its id to wrangler.toml)
// → deploy → set secrets (fresh random webhook path + secret token) →
// check GET /config.json → set the Telegram webhook → send you a test
// message → write CONFIG_URL into ../ad_keys.json (git-ignored).
// Safe to run again.
import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { existsSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const WORKER = 'pantomime-config';
const KV_TITLE = 'pantomime-config-CONFIG';
const root = new URL('..', import.meta.url).pathname;
const env = process.env;

const step = (msg) => console.log(`\n▶ ${msg}`);
const ok = (msg) => console.log(`  ✅ ${msg}`);
const die = (msg) => {
  console.error(`\n❌ ${msg}`);
  process.exit(1);
};

for (const k of ['CLOUDFLARE_API_TOKEN', 'TELEGRAM_BOT_TOKEN', 'ADMIN_TELEGRAM_ID']) {
  if (!env[k]) die(`missing environment variable ${k} (see server/README.md)`);
}
if (!/^\d+$/.test(env.ADMIN_TELEGRAM_ID)) die('ADMIN_TELEGRAM_ID must be numbers only');

async function cf(path, init = {}) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      authorization: `Bearer ${env.CLOUDFLARE_API_TOKEN}`,
      'content-type': 'application/json',
      ...init.headers,
    },
  });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, ...body };
}

async function tg(method, payload) {
  const res = await fetch(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/${method}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return res.json().catch(() => ({ ok: false }));
}

function wrangler(args, input) {
  return execFileSync('npx', ['wrangler', ...args], {
    cwd: root,
    input,
    stdio: input ? ['pipe', 'pipe', 'pipe'] : ['ignore', 'pipe', 'pipe'],
    env: { ...env, CLOUDFLARE_ACCOUNT_ID: env.CLOUDFLARE_ACCOUNT_ID },
    encoding: 'utf8',
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// 1. Token + account. Both kinds of API token work: user tokens (My Profile →
// API Tokens) and account-owned tokens (Manage Account → Account API Tokens),
// which are verified under /accounts/<id>/tokens/verify instead.
step('Checking the Cloudflare API token');
if (!env.CLOUDFLARE_ACCOUNT_ID) {
  const accounts = await cf('/accounts?per_page=5');
  const first = accounts.result?.[0];
  if (first) env.CLOUDFLARE_ACCOUNT_ID = first.id;
}
const account = env.CLOUDFLARE_ACCOUNT_ID;
const userVerify = await cf('/user/tokens/verify');
let tokenOk = userVerify.success === true;
let accountVerify = null;
if (!tokenOk && account) {
  accountVerify = await cf(`/accounts/${account}/tokens/verify`);
  tokenOk = accountVerify.success === true;
}
if (!tokenOk) {
  die(`token rejected: ${JSON.stringify((accountVerify ?? userVerify).errors ?? userVerify)}`);
}
if (!account) die('no Cloudflare account visible to this token (set CLOUDFLARE_ACCOUNT_ID)');
ok(`token is valid (${userVerify.success ? 'user' : 'account'} token)`);
ok(`account ${account}`);

// 2. workers.dev subdomain
step('Making sure a free *.workers.dev subdomain exists');
let sub = (await cf(`/accounts/${account}/workers/subdomain`)).result?.subdomain;
if (!sub) {
  for (let i = 0; i < 5 && !sub; i++) {
    const wanted = `pantomime-${randomBytes(3).toString('hex')}`;
    const r = await cf(`/accounts/${account}/workers/subdomain`, {
      method: 'PUT',
      body: JSON.stringify({ subdomain: wanted }),
    });
    if (r.success) sub = r.result?.subdomain ?? wanted;
  }
  if (!sub) die('could not create a workers.dev subdomain; pick one in the dashboard → Workers & Pages');
}
ok(`${sub}.workers.dev`);

// 3. KV namespace → wrangler.toml
step('KV namespace');
const list = await cf(`/accounts/${account}/storage/kv/namespaces?per_page=100`);
let ns = list.result?.find((n) => n.title === KV_TITLE);
if (!ns) {
  const created = await cf(`/accounts/${account}/storage/kv/namespaces`, {
    method: 'POST',
    body: JSON.stringify({ title: KV_TITLE }),
  });
  if (!created.success) die(`KV create failed: ${JSON.stringify(created.errors)}`);
  ns = created.result;
}
const tomlPath = join(root, 'wrangler.toml');
const toml = readFileSync(tomlPath, 'utf8').replace(/^id = ".*"$/m, `id = "${ns.id}"`);
writeFileSync(tomlPath, toml);
ok(`${KV_TITLE} (${ns.id}) → wrangler.toml`);

// 4. Deploy
step('Deploying the Worker');
if (!existsSync(join(root, 'node_modules', 'wrangler'))) {
  execFileSync('npm', ['ci', '--no-audit', '--no-fund'], { cwd: root, stdio: 'inherit' });
}
wrangler(['deploy']);
const base = `https://${WORKER}.${sub}.workers.dev`;
ok(base);

// 5. Secrets (fresh random webhook path + secret token on every run)
step('Setting secrets');
const secrets = {
  TELEGRAM_BOT_TOKEN: env.TELEGRAM_BOT_TOKEN,
  ADMIN_TELEGRAM_ID: env.ADMIN_TELEGRAM_ID,
  WEBHOOK_PATH: randomBytes(18).toString('hex'),
  TG_SECRET_TOKEN: randomBytes(24).toString('hex'),
};
for (const k of Object.keys(env)) {
  if (k.startsWith('MIRROR_') || k === 'CONTACT_EMAIL') secrets[k] = env[k];
}
const file = join(tmpdir(), `pantomime-secrets-${process.pid}.json`);
writeFileSync(file, JSON.stringify(secrets), { mode: 0o600 });
try {
  wrangler(['secret', 'bulk', file]);
} finally {
  unlinkSync(file);
}
ok(`${Object.keys(secrets).length} secrets set (values not shown)`);

// 6. Smoke test (new subdomains can take a minute or two)
step('Checking GET /config.json');
let served = null;
for (let i = 0; i < 24 && !served; i++) {
  try {
    const res = await fetch(`${base}/config.json`);
    if (res.ok) served = await res.json();
  } catch {
    // DNS for a brand-new subdomain may not exist yet.
  }
  if (!served) await sleep(5000);
}
if (!served) die(`${base}/config.json is not answering yet; wait a few minutes and run this script again`);
ok(`config v${served.config_version} served`);

// 7. Telegram webhook + hello
step('Connecting the Telegram bot');
const hook = await tg('setWebhook', {
  url: `${base}/tg/${secrets.WEBHOOK_PATH}`,
  secret_token: secrets.TG_SECRET_TOKEN,
  allowed_updates: ['message', 'edited_message'],
  drop_pending_updates: true,
});
if (!hook.ok) die(`setWebhook failed: ${hook.description ?? 'unknown error'} (check TELEGRAM_BOT_TOKEN)`);
await tg('setMyCommands', {
  commands: [
    ['status', 'Summary'], ['show', 'Full config (ids masked)'],
    ['provider', '<store> <network>'], ['split', '<store> a:50,b:50 | off'],
    ['fallback', '<store> a,b,c'], ['ads', 'on|off'], ['every', 'N turns'],
    ['rewarded', 'on|off'], ['banner', 'on|off'], ['notice', '<text> | off'],
    ['minversion', 'x.y.z'], ['keys', 'Set ad ids'], ['rollback', 'Previous version'],
    ['cancel', 'Stop /keys'],
  ].map(([command, description]) => ({ command, description })),
});
const hello = await tg('sendMessage', {
  chat_id: Number(env.ADMIN_TELEGRAM_ID),
  text: '✅ ربات پانتومیم وصل شد.\n/status را بفرستید تا وضعیت تبلیغات را ببینید.',
});
ok(hello.ok ? 'webhook set, test message sent to you' : 'webhook set (send /start to the bot once, then /status)');

// 8. App config URL
step('Writing CONFIG_URL into ad_keys.json');
const keysPath = join(root, '..', 'ad_keys.json');
const examplePath = join(root, '..', 'ad_keys.example.json');
const keys = JSON.parse(readFileSync(existsSync(keysPath) ? keysPath : examplePath, 'utf8'));
keys.CONFIG_URL = `${base}/config.json`;
writeFileSync(keysPath, `${JSON.stringify(keys, null, 2)}\n`);
ok(`CONFIG_URL = ${keys.CONFIG_URL}`);

console.log(`
🎉 Done.
   Config:   ${base}/config.json
   Privacy:  ${base}/privacy
   Bot:      send /status
   Next:     test both URLs from Iran without VPN; set up the mirror (README).`);
