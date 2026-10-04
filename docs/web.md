# Web / PWA version

| Address | What | Where |
|---|---|---|
| https://pantomime.espadna.com | the game (also the old `pantomime.sepanta-hesaban.workers.dev`) | this repo: Flutter `web/` → `build/game`, deploy `web_deploy/` |
| https://api.espadna.com | config, word list, privacy, bot | this repo: `server/` |
| https://espadna.com, `/pantomime-app/` (+ `fa/`, `ar/`) | studio home and landing pages | **hajiheidari/espadna-site** (deployed by its GitHub Actions) |
| https://espadna.com/tiaro-app/, tiaro.espadna.com | Tiaro (another app) | hajiheidari/crowns-app (its own Worker route), not this repo |

Landing page images (icon, og images) are rendered here by
`node tool/render_branding.js` into `assets/branding/landing/`; copy them to
`espadna-site/public/pantomime-app/`.

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
tool/build_web.sh            # → build/game, build/pantomime-web.zip
tool/build_web.sh --deploy   # + upload to Cloudflare (needs CLOUDFLARE_API_TOKEN)
```

The game is Cloudflare Workers static assets (free, unlimited requests) with
a custom domain. Cache rules and old-link redirects are generated into
`build/game/_headers` and `_redirects`. Every CI run also uploads `pantomime-web.zip` as an
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
