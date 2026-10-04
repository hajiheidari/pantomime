# Web / PWA version

| Address | What | Source | Deploy config |
|---|---|---|---|
| https://pantomime.espadna.com | the game (also the old `pantomime.sepanta-hesaban.workers.dev`) | Flutter `web/` build → `build/game` | `web_deploy/` |
| https://espadna.com | studio home: en `/`, `/fa/`, `/ar/` (generated: edit `site/products.json`, run `python3 tool/site_home.py`) | `site/` → `build/espadna` | `site_deploy/` |
| https://espadna.com/pantomime-app/ | landing page en (`/fa/`, `/ar/`), `privacy` → api | `site/pantomime-app/` | `site_deploy/` |
| https://api.espadna.com | config, word list, privacy, bot | `server/` | `server/wrangler.toml` |

Every web app gets its own subdomain (`<app>.espadna.com`) and its landing page
in a folder `espadna.com/<app>-app/` (English; `fa/` and `ar/` subfolders).

## What it is

- The same Flutter game compiled for the browser (`tool/store.dart web`:
  no ad SDKs in the browser yet).
- **Offline:** `play/sw.js` (generated from `web/sw.template.js`) caches the
  game after the first visit; reloading without internet works. The remote
  config and word list are fetched in the background like on mobile.
- **Installable (PWA):** Persian manifest, icons, standalone display.
  Android Chrome shows an install button on the landing page; iPhone users
  use Share → "Add to Home Screen" (instructions on the landing page).
- **Forehead mode:** motion comes from `devicemotion` events
  (`lib/features/game/application/motion/motion_platform_web.dart`).
  iPhone Safari asks for permission when "Start" is tapped; the sign of the
  readings is checked against the screen rotation during calibration
  (`gravitySign`). If sensors are missing or denied, the existing
  "start with buttons" fallback appears.
- **Not on web:** video recording, vibration toggle, "rate the app".
- **Fonts:** Vazirmatn + `assets/fonts/EmojiSubset.ttf` (only the emoji the
  app uses; `tool/subset_emoji.py`), so nothing is fetched from Google
  Fonts (offline, and reachable from Iran). CanvasKit is served locally too
  (`--no-web-resources-cdn`).
- **Ads on web:** none yet (spec 9c). When a web ad network is chosen, add an
  `ads_<network>` package with a web implementation and a `web` profile entry
  in `tool/store.dart`.

## Build and deploy

```bash
tool/build_web.sh            # → build/game, build/espadna, build/pantomime-web.zip
tool/build_web.sh --deploy   # + upload both to Cloudflare (needs CLOUDFLARE_API_TOKEN)
```

Both are Cloudflare Workers static assets (free, unlimited requests) with
custom domains. Cache rules and old-link redirects for the game are generated
into `build/game/_headers` and `_redirects`; the site's redirects are in
`site/_redirects`. Every CI run also uploads `pantomime-web.zip` as an
artifact.

## Mirror on an Iranian host

All game paths are relative, so `build/pantomime-web.zip` works inside any
folder: unzip it into e.g. `public_html/pantomime/` and open
`https://<host>/pantomime/`. (It contains the game only.) (The service worker needs HTTPS.)

## Regenerating icons / emoji

```bash
node tool/render_branding.js        # app + web icons, og.png
python3 tool/subset_emoji.py        # after adding new emoji to the UI
```
