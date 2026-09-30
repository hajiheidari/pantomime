# Project: "پانتومیم دورهمی" (Pantomime Dorehami) — Persian charades party game

You are building a cross-platform (iOS + Android) **offline** charades / pantomime party game in **Flutter**.
Read this whole file first, then build in the milestone order at the bottom. Ask me only when a decision below is genuinely missing.

- **Store title:** پانتومیم دورهمی  |  **Name under the icon:** پانتومیم
- **Market:** Persian-speaking users only (mostly Iran, plus Persian speakers abroad). UI is **Persian, fully RTL**.
- **Goals (in order):** 1) popularity/virality, 2) promote my other products later, 3) ad revenue.
- **Developer account:** my personal account. The app has its own name and brand; there is no umbrella brand.
- Also ship an English UI string set (auto-selected from device language) so the store listing/reviewers see a normal localized app. Persian is the default/primary experience. English uses a small English word pack.

---

## 1. Tech decisions

- Flutter (latest stable), Dart null-safety. Targets: iOS 13+, Android minSdk 23.
- State management: Riverpod. Local storage: shared_preferences (or Hive).
- Packages to evaluate (verify they are maintained and compatible before using): `sensors_plus`, `camera`, `share_plus`, `gal` or `image_gallery_saver`, `audioplayers`, `vibration` or `HapticFeedback`, `google_mobile_ads`, `http`, `package_info_plus`.
- Font: bundle **Vazirmatn** locally (open license). No network font loading.
- Fully offline gameplay. Network is used only for the remote config (section 6).
- Project folder: `~/Desktop/pantomime app` (create a Flutter project inside it).

## 2. Visual design

- **Cheerful, cartoon style.** Bright saturated colors, rounded shapes, thick outlines, playful illustrations/emoji, bouncy animations.
- High contrast (it is played in dim rooms), **big buttons** (one-hand, high excitement), big word text.
- Each team gets a distinct color + avatar emoji.
- Sounds + haptics for: correct, pass, last-10-seconds tick, round end. Global mute toggle.

## 3. Screens (v1)

1. **Splash** (≤2s): logo + name.
2. **Home:** two big buttons — «بازی تیمی» (Team game) and «گوشی روی پیشونی» (Forehead mode) — plus settings icon.
3. **Game setup:**
   - Teams: 2–4, editable names (defaults: تیم ۱…۴).
   - Round duration: 30 / 60 / 90 seconds (default 60).
   - Rounds per team: 3 / 5 / 7.
   - Difficulty: easy / medium / hard / mixed.
   - Categories: multi-select with checkboxes (see section 5).
   - Pass limit per round: default 3 (configurable 0–5 or unlimited).
4. **Ready screen:** whose turn (team name + color), "Start" button, 3-2-1 countdown.
5. **Play screen:** huge word in the center, timer at top, two big buttons «درست» (correct) and «پاس» (pass), pass counter. Nothing else on screen. **No ads here, ever.**
6. **Round summary:** list of correct + passed words, round score, per-word toggle to fix a mistake, button to share the recorded clip (if recording was on).
7. **Scoreboard** between turns and **final result** with winner + "share result" (image card).
8. **Settings:** sound, vibration, recording on/off, language, about, privacy policy link, "rate app".

## 4. Game modes & rules

**Mode A – Team game (classic):**
- Teams alternate. One player acts (no speaking, no sound-words), teammates guess.
- Someone from the *other* team (or any non-acting player) taps «درست» or «پاس» — UI must make this one-tap and obvious.
- +1 point per correct word. Pass costs nothing but is limited per round (configurable).
- Last 10 s: tick sound + vibration. On time-up show summary.
- Game ends after N rounds per team; highest score wins; ties → one sudden-death round.

**Mode B – Forehead mode:**
- Landscape-locked. Phone held on the forehead, screen facing the group.
- Tilt **down** = correct, tilt **up** = pass (use accelerometer/gyro, with debounce and a short neutral-position requirement between actions; include a brief calibration step).
- Front camera may record the round if the user enabled recording (section 7).
- Score = correct count; reuse the same timer/summary flow. Also allow a simple multi-player loop (each player takes a turn, scoreboard at end).

**No-repeat logic:** a word shown once is not shown again in the same game, and is deprioritized across games (persist a "seen" set; reset a category's seen-set only when it is exhausted).

## 5. Words (content)

- Data file: `assets/words/words_fa.json` (provided with this spec). Schema:
  `{ version, language, categories: [{ id, title, emoji, words: { easy: [], medium: [], hard: [] } }] }`
- 11 categories: فیلم و سریال، غذا و نوشیدنی ایرانی، حیوانات، شغل‌ها، ضرب‌المثل و اصطلاح، ورزش، شهرها و مکان‌ها، وسایل خانه و اشیا، کارها و حرکت‌ها، خاطرات دهه ۶۰ و ۷۰، خنده‌دار و خجالت‌آور.
- Content rules: **no +18/sexual content, no politics, no religion, no controversial public figures.** People allowed only if uncontroversial (athletes, cartoon/historical characters, non-controversial artists). The "funny & embarrassing" category is mild humor only (e.g., hiccups, snoring, slipping on a banana peel).
- Load words through a repository class so the source can later be swapped for downloadable word packs without touching game logic (don't build download yet).
- Keep the word list **easy to extend**: adding a category should only need editing the JSON.
- Normalize Persian text (ZWNJ, Arabic vs Persian ی/ک) when comparing/deduplicating.

## 6. Ads + **remote config** (important)

### 6.1 Ad placement rules
- Never during a round. Small banner only on Home. Interstitial at most every **N rounds** (config, default 3) when moving to the next turn. **Rewarded ad** unlocks a premium/bonus word pack for the session.
- Ads must never block gameplay: if an ad fails/times out (≤3 s), skip silently.
- No in-app purchases in v1.

### 6.2 Provider abstraction
Create an `AdProvider` interface (`init`, `showInterstitial`, `showRewarded`, `buildBanner`, `isReady`) and an `AdManager` that chooses the provider at runtime from remote config. Implement:
- `AdiveryProvider` — **Adivery** is the in-app ad platform of Yektanet (largest Iranian ad company); it also mediates foreign networks such as AdMob/Unity/Mintegral. Flutter package: `adivery` (pub.dev). **Default provider on Android.**
- `TapsellProvider` — Tapsell Plus (mediation SDK). Flutter package: `tapsell_plus`. **Fallback on Android.**
- `AdmobProvider` — `google_mobile_ads`, works on iOS + Android. **Default on iOS.**

**Facts checked when this spec was written (re-verify before coding):**
- The pub.dev packages `adivery` (4.8.x) and `tapsell_plus` (2.3.x) both declare **Android-only** support (no iOS). So on iOS the Iranian networks are NOT available through Flutter plugins. iOS uses AdMob (or no ads). If the vendors publish a native iOS SDK, you may wrap it with a platform channel later — tell me before doing that.
- Iranian networks' docs: `docs.adivery.com/flutter` and Tapsell's docs. Follow the current official docs, not old blog posts.
- I could not find reliable public eCPM comparisons between these networks, so do not hard-code a winner: build the **A/B split** below so real data decides.
- Only SDKs **compiled into the app** can be switched remotely. Adding a *brand-new* network needs an app update. Never download or execute code remotely (violates App Store / Play policy).
- Keep all ad IDs/keys out of source control (use `--dart-define` or a git-ignored `ad_keys.dart`); the remote config may also supply them.

### 6.3 Remote config
- On launch, fetch `config.json` from a primary URL, then a secondary mirror if the primary fails (timeout ~3 s each). Cache the last good config locally; if everything fails use the cached one, else a bundled default. **Never block app start on the network.**
- Both URLs must be reachable from inside Iran without a VPN (I will test this); keep the file tiny.
- Config schema (example):

```json
{
  "config_version": 12,
  "ads": {
    "enabled": true,
    "active_provider": { "play": "adivery", "bazaar": "adivery", "myket": "adivery", "ios": "admob" },
    "ab_split": {
      "play":   { "adivery": 50, "tapsell": 50 },
      "bazaar": { "adivery": 50, "tapsell": 50 },
      "myket":  { "adivery": 50, "tapsell": 50 }
    },
    "fallback_chain": {
      "play":   ["adivery", "tapsell", "admob"],
      "bazaar": ["adivery", "tapsell"],
      "myket":  ["adivery", "tapsell"],
      "ios":    ["admob"]
    },
    "providers": {
      "adivery": { "app_id": "", "interstitial_placement": "", "rewarded_placement": "", "banner_placement": "" },
      "tapsell": { "app_key": "", "interstitial_zone": "", "rewarded_zone": "", "banner_zone": "" },
      "admob": { "android": {"interstitial": "", "rewarded": "", "banner": ""}, "ios": {"interstitial": "", "rewarded": "", "banner": ""} }
    },
    "interstitial_every_n_rounds": 3,
    "banner_on_home": true,
    "rewarded_enabled": true
  },
  "min_supported_version": "1.0.0",
  "message": null
}
```

- **A/B split (optional, per store flavor):** if `ab_split` is present, each install is assigned to a provider once (deterministic hash of a random install ID, stored locally) using the given percentages, so I can compare revenue per network from each dashboard for 2–4 weeks. If `ab_split` is absent/null, everyone uses `active_provider`. Telegram bot controls it.
- Validate config strictly (unknown provider → ignore it and keep the last good config). Apply a new config on the next app launch or next ad request, never mid-round.
- Remote config may change **only** ad provider, ad IDs, frequency, on/off and an optional notice. It must **not** change or hide gameplay features (store compliance: reviewers and users must see the same app).
- Track provider failures; after several consecutive load failures, walk down `fallback_chain` for this session.

## 7. Video recording & sharing (growth engine)

- Optional, **off by default**. Ask camera/mic permission only when the user turns it on (clear Persian explanation). Permission texts must be filled in `Info.plist` and the Android manifest.
- In Forehead mode, record the front camera during the round. Save locally (gallery) and offer "Share" (Instagram Story/WhatsApp/etc. via `share_plus`). **Never upload videos anywhere.**
- Watermark: app name + logo + the round score. If burning a watermark into the video with a well-maintained package is not feasible, ship v1 with (a) raw video + (b) a generated **share-card image** (score + words list + app name), and add the watermark in a later version. Tell me which path you took.
- Final result screen: "share result" image card with team scores and app name.

## 8. Privacy / store compliance

- No account, no login, no analytics that identify users. If you add crash reporting/analytics, keep it minimal and disclose it.
- Implement iOS App Tracking Transparency prompt only if an ad SDK requires it; add required `SKAdNetworkItems` for the ad networks used.
- Provide a simple privacy policy page (static text inside the app + a placeholder URL constant). Fill Android Data Safety / iOS privacy-label notes in `docs/store_notes.md`.
- Content rating notes: mild crude humor; no sexual content, violence, gambling, or user-generated content.
- Bundle ID placeholders: `com.REPLACE_ME.pantomime` (I will set the real one).

## 9. Server side (small, separate folder `server/`)

### 9.1 Config endpoint
- I have **no Cloudflare account/domain yet**. Use the **free** tier only: a `*.workers.dev` subdomain is fine (no custom domain needed). `server/README.md` must start with step-by-step account creation (free plan), `wrangler login`, creating the KV namespace, setting secrets, deploying, and a `curl` test. Stay within free-tier limits (cache the config; the app fetches at most once per launch / several hours).
- Serverless, preferably **Cloudflare Workers + KV** (free tier): `GET /config.json` returns the current config (HTTPS, `Cache-Control: max-age=300`). Keep the last 10 versions in KV for rollback.
- Provide a second mirror option (document how to deploy the same JSON on a second host) for reachability inside Iran.

### 9.2 Telegram control bot
So I can change ads without releasing an app update.
- Webhook handled by the same Worker. Secret path + Telegram `secret_token` header check.
- **Allow-list:** only my Telegram user ID (env var `ADMIN_TELEGRAM_ID`); ignore everyone else silently.
- Commands (whitelist-validate every argument; reply with the new config summary):
  - `/status` – show active provider per platform, ads on/off, frequency, version
  - `/provider play|bazaar|myket|ios adivery|tapsell|admob`
  - `/split play|bazaar|myket adivery:50,tapsell:50` (A/B test) and `/split <flavor> off`
  - `/fallback play|bazaar|myket|ios a,b,c`
  - `/ads on|off`
  - `/every N` – interstitial every N rounds (1–10)
  - `/rewarded on|off`, `/banner on|off`
  - `/keys` – guided flow to set provider IDs (never echo secrets back in full)
  - `/show` – print the full current JSON (mask sensitive IDs)
  - `/rollback` – revert to the previous version
  - `/notice <text>` / `/notice off`
- Every change bumps `config_version`, stores the previous version, and is logged with a timestamp.
- Secrets only in environment variables / Worker secrets, never in the repo. Provide `server/README.md` with exact deploy steps (wrangler), how to create the bot with BotFather, and how to set the webhook.

## 9b. Distribution: Android store flavors (Iran)

Most Iranian Android users install from **Cafe Bazaar (بازار)** and **Myket (مایکت)**, not only Google Play. Build **Android product flavors**: `play`, `bazaar`, `myket` (+ iOS App Store). Same code base, same applicationId unless a store requires otherwise (tell me if so).
- Each flavor exposes its `storeId` to the app and to the remote config (section 6.3 uses flavor keys).
- Store-specific: "Rate app" / "Update available" deep links (Bazaar and Myket have their own intents/URLs), store listing assets, and the ad-SDK store setting if Adivery/Tapsell require one (follow their docs per store).
- **Bazaar/Myket builds must not depend on Google Play Services** (many devices there lack it): in these flavors AdMob is disabled and never used as a fallback; do not add Firebase/Play-only dependencies to them. Keep the `play` and `ios` builds free to use AdMob.
- Each store has its own developer account, review process, upload format (APK/AAB) and signing rules; put checklists for all three in `docs/store_notes.md` (I will register the accounts myself).
- Use one **upload/signing key per store** as required, stored outside the repo.
- Keep store-specific code behind a small `StoreService` interface.

## 9c. PHASE 2 (version 2): Web / PWA — DO NOT BUILD in v1

**Scope rule:** everything in this section is for a later release. Do not build it during M1–M6. Only keep the architecture web-friendly (no `dart:io` in shared game logic, words/config/ad code behind interfaces) so this can be added later without a rewrite.

Goal: a playable, installable (PWA) web version so a shared link opens the game instantly without any store.
- Flutter Web build of the same game logic, deployed on a static host reachable from Iran without a VPN (test from Iran; Cloudflare Pages free tier is the first candidate, plus a second mirror).
- A separate, lightweight **HTML landing page** at the site root (fast, SEO-friendly, Persian meta tags, OpenGraph/Twitter cards for link previews, "play now" button). The game itself lives at a separate path (e.g. `/play`) because Flutter Web is heavy on first load and poorly indexed.
- PWA: web app manifest (Persian name, icons, RTL, standalone display), service worker for offline play after the first visit, "Add to Home Screen" prompt/instructions for iPhone.
- Forehead mode on web: device-orientation/motion sensors need HTTPS and, on iOS Safari, an explicit user permission tap. Include a permission screen and a **touch-button fallback** (correct/pass buttons) if sensors are unavailable or denied.
- Video recording on web is unreliable (especially iOS Safari): treat it as optional and feature-detect; if unsupported, hide it and keep the share-card image instead.
- Ads on web are a separate integration (different SDKs/scripts than the mobile ones). Use the same remote-config mechanism (extra key `web` in section 6.3); decide the web ad network when we get there. No ads during a round, same rules as mobile.
- Keep the initial load small: deferred loading, compressed assets, bundled Vazirmatn subset.
- Acceptance: loads and plays on a mid-range Android Chrome and on iPhone Safari; works offline after first load; Lighthouse PWA checks pass; landing page is indexable.

## 10. Code quality

- Clean feature-based structure (`features/game`, `features/words`, `features/ads`, `features/settings`, `core`).
- Unit tests for: scoring, turn order, no-repeat word picker, config validation/parsing, tilt debounce logic.
- `README.md` at the repo root: how to run, where to put ad keys, how to add a word category, how to release.
- Keep the app size small; no heavy assets.

## 11. Milestones (do in order, stop and show me after each)

1. **M1 – Core offline game:** home, setup, team mode, scoring, words loader, summary/scoreboard, cartoon theme, RTL + Persian.
2. **M2 – Forehead mode:** sensors, calibration, sounds, haptics, polish.
3. **M3 – Ads abstraction:** `AdProvider`/`AdManager`, Adivery + Tapsell on Android flavors (verify current SDKs), AdMob on `play` and iOS, per-flavor A/B split, remote-config client with cache + fallbacks, bundled default config.
4. **M4 – Server + Telegram bot:** Worker, KV, bot commands, deploy docs.
5. **M5 – Recording & sharing:** camera recording, share card, watermark if feasible.
6. **M6 – Store prep:** flavors (play/bazaar/myket/ios), icons, splash, screenshots checklist, privacy text, `docs/store_notes.md`, release builds for each store.
7. **M7 – Web/PWA (PHASE 2, version 2 — not part of the first release):** see section 9c. Start only after M1–M6 are done and I say go.

## 12. Acceptance checklist

- [ ] Fully playable offline in Persian RTL, both modes, 2–4 teams.
- [ ] No ads ever appear during a running round.
- [ ] Switching `active_provider` from the Telegram bot changes the ad network on the next launch with no app update.
- [ ] App works normally when the config server is unreachable.
- [ ] No +18/political/religious/controversial content in the word file.
- [ ] Camera/mic permissions requested only when recording is enabled.
- [ ] Builds and runs on a real iPhone and a real Android phone.
- [ ] `bazaar` and `myket` flavors run on a device without Google Play Services and never reference AdMob/Firebase.
