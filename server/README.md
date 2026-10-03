# Config server + Telegram bot (Cloudflare Workers, free plan)

One small Worker does two jobs:

- `GET https://<name>.<you>.workers.dev/config.json` serves the app's ad
  config (cached 5 minutes, tiny JSON).
- `POST https://<name>.<you>.workers.dev/tg/<secret-path>` is the Telegram
  webhook for your control bot. Only your Telegram account is obeyed.

Every bot change is validated with the **same rules as the app**, bumps
`config_version`, keeps the previous version (last 10, for `/rollback`), and
is logged with a timestamp. It can optionally be copied to a second host (the
mirror). Everything fits in the **free** plan: KV has 100k reads/day and 1k
writes/day; the app fetches at most once an hour per device, and responses
are edge-cached.

You need: a computer with **Node.js 20+** (`node -v`) and a Telegram account.

---

## ⚡ Automatic setup (recommended)

You only do the parts that need your own login:

1. Create a free Cloudflare account (step 1 below; no card, no domain).
2. Create an API token: dashboard → **My Profile → API Tokens → Create
   Token → template "Edit Cloudflare Workers"** → *Account Resources*: your
   account → *Continue* → *Create Token* → copy it.
3. Create the bot with @BotFather and get your numeric id from
   @userinfobot (step 4 below).
4. Store them as environment variables, **not in any chat or file in git**:
   `CLOUDFLARE_API_TOKEN`, `TELEGRAM_BOT_TOKEN`, `ADMIN_TELEGRAM_ID`
   (optional: `CLOUDFLARE_ACCOUNT_ID`, `CONTACT_EMAIL`, `MIRROR_*`).

Then one command does everything else: workers.dev subdomain, KV namespace,
deploy, secrets (random webhook path + secret token), smoke test,
Telegram webhook + command menu, a test message to you, and `CONFIG_URL` in
`../ad_keys.json`:

```bash
cd server && npm ci && node scripts/setup.mjs
# behind an HTTP(S) proxy:  NODE_USE_ENV_PROXY=1 node scripts/setup.mjs
```

It is safe to run again (it reuses the KV namespace and rotates the webhook
secret). The manual steps below do the same thing by hand.

## 1. Create a free Cloudflare account

1. Go to <https://dash.cloudflare.com/sign-up>, enter an email and a
   password, and verify the email. **No credit card and no domain are
   needed.**
2. In the dashboard, open **Workers & Pages** (left menu). The first time,
   Cloudflare asks you to pick a free `*.workers.dev` subdomain (for example
   `pantomime-ir`). Your Worker will live at
   `https://pantomime-config.<subdomain>.workers.dev`.
3. Make sure the plan says **Free**. Nothing here needs a paid plan.

## 2. Log in with wrangler

```bash
cd server
npm install                 # installs wrangler locally
npx wrangler login          # opens the browser → "Allow"
npx wrangler whoami         # shows your account: logged in ✅
```

> If the browser login is blocked, create an API token instead:
> Dashboard → My Profile → API Tokens → *Create Token* → template
> **"Edit Cloudflare Workers"** → copy it, then `export CLOUDFLARE_API_TOKEN=…`.

## 3. Create the KV namespace

```bash
npx wrangler kv namespace create CONFIG
```

It prints something like `id = "3f2a…"`. Paste that id into
`wrangler.toml` in place of `REPLACE_WITH_YOUR_KV_NAMESPACE_ID`.

## 4. Create the Telegram bot (BotFather)

1. In Telegram, open **@BotFather** → `/newbot` → pick a name (for example
   *Pantomime Ads*) and a username ending in `bot`.
2. BotFather replies with the **bot token** (`123456:ABC…`). Keep it secret.
3. Find **your numeric user id**: message **@userinfobot**; it replies with
   `Id: 123456789`.
4. Optional, for nicer command menus: in BotFather, `/setcommands` → choose
   your bot → paste:
   ```
   status - Summary
   show - Full config (ids masked)
   provider - <store> <network>
   split - <store> adivery:50,tapsell:50 | off
   fallback - <store> a,b,c
   ads - on|off
   every - N turns between interstitials
   rewarded - on|off
   banner - on|off
   notice - <text> | off
   minversion - 1.2.0
   keys - Set ad ids step by step
   rollback - Previous version
   cancel - Stop /keys
   ```

## 5. Set the secrets

Secrets live only in Cloudflare, never in the repo. Generate two random
strings first, for example with `openssl rand -hex 24`:

```bash
npx wrangler secret put TELEGRAM_BOT_TOKEN   # paste the BotFather token
npx wrangler secret put ADMIN_TELEGRAM_ID    # paste your numeric id
npx wrangler secret put WEBHOOK_PATH         # random string #1
npx wrangler secret put TG_SECRET_TOKEN      # random string #2 (A–Z a–z 0–9 _ -)
```

## 6. Deploy

```bash
npx wrangler deploy
```

It prints the URL, for example
`https://pantomime-config.pantomime-ir.workers.dev`.

## 7. Test with curl

```bash
curl -i https://pantomime-config.<subdomain>.workers.dev/config.json
```

You should get `HTTP 200`, `cache-control: public, max-age=300` and the JSON
(`"config_version": 0` until you change something).

## 8. Connect the bot (webhook)

Replace the placeholders and run:

```bash
TOKEN='<bot token>'
URL='https://pantomime-config.<subdomain>.workers.dev/tg/<WEBHOOK_PATH>'
SECRET='<TG_SECRET_TOKEN>'
curl "https://api.telegram.org/bot$TOKEN/setWebhook" \
  -d "url=$URL" -d "secret_token=$SECRET" -d 'allowed_updates=["message"]'
curl "https://api.telegram.org/bot$TOKEN/getWebhookInfo"   # check: no last_error_message
```

Now send `/status` to your bot. Messages from anyone else are ignored
silently, and requests without the secret header get `404`.

## 9. Point the app at it

Put the URLs into `ad_keys.json` (see `../ad_keys.example.json`):

```json
"CONFIG_URL": "https://pantomime-config.<subdomain>.workers.dev/config.json",
"CONFIG_MIRROR_URL": "https://<your mirror>/config.json"
```

and build with `--dart-define-from-file=ad_keys.json`.

---

## Bot commands

| Command | Example |
|---|---|
| `/status` | provider per store, ads on/off, frequency, version |
| `/provider <play\|bazaar\|myket\|ios> <adivery\|tapsell\|admob>` | `/provider bazaar adivery` |
| `/split <play\|bazaar\|myket> a:50,b:50` / `off` | `/split myket adivery:50,tapsell:50` |
| `/fallback <store> a,b,c` | `/fallback play adivery,admob` |
| `/ads on\|off`, `/rewarded on\|off`, `/banner on\|off` | `/ads off` |
| `/every N` (1–10) | `/every 3` |
| `/notice <text>` / `/notice off` | `/notice نسخه جدید آمد!` |
| `/minversion x.y.z` | shows an "update available" notice to older apps |
| `/keys` | guided: provider → field → value (`-` clears it) |
| `/keys <target> <field> <value>` | `/keys adivery app_id abc123` |
| `/show` | full JSON, ids masked |
| `/rollback` | republishes the previous version under a new number |

Rules the bot enforces (same as the app): known networks only, AdMob never on
`bazaar`/`myket`, splits sum to 100, `every` between 1 and 10, notice up to 500
characters. When you send an id, the bot deletes your message and only ever
shows ids masked (`abc…xyz`). Changes reach phones at their next launch or
next ad request (never mid-round). Apps re-fetch at most once per hour, and
the edge cache adds up to 5 minutes.

Tapsell can be configured, but the app currently ships without it (see
`../docs/ads.md`). Builds without Tapsell just skip it.

## Second mirror (reachability inside Iran)

`*.workers.dev` may be filtered for some Iranian ISPs. The app tries the
primary URL, then the mirror, then its cached copy, so a mirror inside Iran
keeps control working. Test both URLs from Iran without a VPN.

### Option 0, simplest: one PHP file on an Iranian host

`mirror/pantomime-config.php`: upload this single file to any PHP host
(PHP 7+, no database, nothing to configure, no keys). It re-fetches the
Worker's `config.json` at most every 5 minutes. If the Worker is unreachable
it keeps serving the last good copy, or the bundled default. It never accepts
a lower `config_version` and rejects anything that isn't a valid config.
Then use `https://<your-host>/pantomime-config.php` as `CONFIG_MIRROR_URL`.
Tested in `test/mirror_php.test.js` (runs when PHP is installed).

### Option A, automatic (recommended): S3-compatible bucket in Iran

With the `MIRROR_*` secrets set, the Worker uploads `config.json` to the
bucket after **every** change, so the mirror is never stale. It uses an AWS
SigV4-signed PUT to the path-style URL `<endpoint>/<bucket>/<key>`. The
signing is tested against AWS's reference values, but it has **not yet been
tried against a live ArvanCloud bucket**, so do step 4 below once.

Example: **ArvanCloud Object Storage** (Iranian, has a free tier):

1. Create an ArvanCloud account → *Object Storage* → create a bucket (for
   example `pantomime-config`). Set the bucket's access to **public-read**.
2. *Access keys* → create a key pair.
3. Set the secrets (the endpoint is shown in the bucket panel, for example
   `https://s3.ir-thr-at1.arvanstorage.ir`):
   ```bash
   npx wrangler secret put MIRROR_ENDPOINT          # https://s3.ir-thr-at1.arvanstorage.ir
   npx wrangler secret put MIRROR_BUCKET            # pantomime-config
   npx wrangler secret put MIRROR_ACCESS_KEY_ID
   npx wrangler secret put MIRROR_SECRET_ACCESS_KEY
   # optional: MIRROR_KEY (default config.json), MIRROR_REGION (default "default")
   ```
4. Send any change to the bot (for example `/every 3`). The reply ends with
   `🪞 mirror updated`. Check
   `curl -i https://pantomime-config.s3.ir-thr-at1.arvanstorage.ir/config.json`
   (or the path-style URL shown in the panel).
5. Use that public URL as `CONFIG_MIRROR_URL`.

If the reply says `⚠️ mirror upload failed`, check the keys, the endpoint and
the bucket name. The primary still works.

### Option B, manual: any static host

Any HTTPS static host reachable from Iran works (an Iranian CDN, your own
server, Liara, and so on). After a change, copy the live file:

```bash
curl -s https://pantomime-config.<subdomain>.workers.dev/config.json > config.json
# upload config.json to the mirror
```

A stale mirror is safe: the app never applies a config with a lower
`config_version` than the one it already has.

## Rollback, history and logs

- `/rollback` steps back through the last 10 versions; each step is published
  with a new, higher `config_version` (apps ignore lower numbers).
- Inspect the raw log:
  `npx wrangler kv key get --binding CONFIG log --remote`

## Development

```bash
npm test                         # unit + webhook tests (node:test)
npm run fixtures                 # regenerate configs the Dart tests check
npx wrangler dev                 # local Worker with local KV; needs .dev.vars:
#   TELEGRAM_BOT_TOKEN=000:fake
#   TG_SECRET_TOKEN=local
#   WEBHOOK_PATH=local
#   ADMIN_TELEGRAM_ID=123
```

`src/default_config.json` must equal `../assets/config/default_config.json`
(a test checks this).
