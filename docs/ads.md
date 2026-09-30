# Ads & remote config (M3)

## Rules the code enforces

- No ad ever shows while a round is running (`AdManager` checks the game
  phase; the only interstitial slot is scoreboard → next turn).
- Interstitial at most every **N** turn transitions (`interstitial_every_n_rounds`).
- Small banner on **Home only**.
- Rewarded ad unlocks the 🎁 bonus categories (`"bonus": true` in the word
  JSON) for the app session. If no ad can be shown (ads off, no fill, error,
  3 s timeout) the category unlocks anyway, so ads never block gameplay and
  remote config never hides a feature. Closing the ad early keeps it locked.
- Every ad wait is capped at 3 s and failures are silent.
- After 3 consecutive failures (error or nothing ready in 3 s) a network is
  skipped for the session and the next one in `fallback_chain` is used.

## Architecture

```
packages/ads_core     AdProvider interface (init, isReady, preload,
                      showInterstitial, showRewarded, buildBanner)
packages/ads_adivery  Adivery   (pub: adivery 4.9.x, Android only)
packages/ads_tapsell  Tapsell+  (pub: tapsell_plus 2.3.x, Android only)
packages/ads_admob    AdMob     (pub: google_mobile_ads, Android + iOS)

lib/features/ads/
  config/remote_config.dart          schema + strict validation
  config/provider_selection.dart     A/B bucket + fallback chain (pure)
  config/remote_config_service.dart  primary → mirror → cache → bundled
  ad_manager.dart                    placement rules, failures, fallback
  ad_keys.dart                       build-time ids (--dart-define)
  generated/ad_providers.g.dart      written by tool/store.dart
assets/config/default_config.json    bundled default config
```

### Store profiles (which SDKs are compiled in)

Flutter can't drop a plugin per Android flavor, so the dependency set is
switched per store build:

```bash
dart run tool/store.dart bazaar     # adivery
dart run tool/store.dart myket      # adivery
dart run tool/store.dart play       # adivery + admob
dart run tool/store.dart ios        # admob
dart run tool/store.dart dev        # all three (committed default: tests/analysis)
# then `flutter pub get` (or `flutter pub upgrade google_mobile_ads` when the
# tool says so), then build.
```

Add `--with-tapsell` to include Tapsell (see the warning below).
`AdManager` also refuses AdMob on Bazaar/Myket at runtime, and the config
validator rejects configs that name AdMob for those stores.

Only SDKs compiled into a build can be switched remotely. A brand-new network
needs an app update. No code is ever downloaded.

## ⚠️ Tapsell Plus finding (checked 2026-09-30)

`tapsell_plus` 2.3.2 (latest on pub.dev, published 2025-02-24):

1. Its Dart code imports `google_mobile_ads` and pins it to `^4.0.0`
   (a 2023 version). In any build that includes Tapsell, AdMob is held at 4.0.0.
2. Its native SDK (`ir.tapsell.plus:tapsell-plus-sdk-flutter:2.3.2`) pulls
   `com.google.android.gms:play-services-auth` and `play-services-appset`.

So a Bazaar/Myket build with Tapsell would contain AdMob and Google Play
Services code, which the spec forbids. Tapsell is therefore **opt-in**
(`--with-tapsell`) and **off by default in every store profile**. The Tapsell
provider is fully implemented and tested through `dev`.

Options:
- (a) Keep Adivery only on Bazaar/Myket (default). Adivery also mediates other
  networks.
- (b) Accept Tapsell's dependencies with `--with-tapsell`, after testing the
  build on a phone without Play Services.
- (c) Later: wrap Tapsell's plain Android SDK through our own platform channel,
  if it doesn't need GMS. This needs a decision first.

Adivery 4.9.0's native SDK depends only on OkHttp, Kotlin coroutines and
**Sentry** (crash reporting inside the ad SDK). Declare Sentry in the store
privacy forms.

## Remote config

- On launch: cached last-good config (else the bundled default) is used
  immediately; the network refresh runs in the background (primary URL, then
  mirror, 3 s timeout each, at most once per hour). Start is never blocked.
- A config is applied only if it is **valid** and its `config_version` is not
  lower than the current one (a stale mirror can't roll you back; the bot's
  `/rollback` publishes the old content under a new version).
- Invalid config (unknown provider/store, AdMob on Bazaar/Myket, split not
  summing to 100, wrong types…) → ignored, last good config kept.
- Unknown keys are ignored, so config can't change gameplay.
- Changes apply at the next ad request (never mid-round) or next launch.
- `message` shows a notice on Home; if the app version is below
  `min_supported_version` an "update available" notice shows (non-blocking).

URLs are build-time: `--dart-define=CONFIG_URL=… --dart-define=CONFIG_MIRROR_URL=…`
(set in M4).

### A/B split

If `ab_split[store]` is present, the install is placed in a bucket
`fnv1a32("<installId>:<store>") % 100` and gets the provider whose cumulative
percentage covers it (providers sorted by name). The install id is random,
stored locally, never sent anywhere, so an install keeps its network for the
whole test. `null` (or absent) = everyone uses `active_provider`.

## Ad ids / keys (never in git)

1. Copy `ad_keys.example.json` to `ad_keys.json` (git-ignored), fill it in,
   build with `--dart-define-from-file=ad_keys.json`.
2. Ids in remote config (`ads.providers`) override the build-time ones when
   non-empty.
3. AdMob **app id** (not unit ids) must be in the native config:
   - Android: `flutter build … -PADMOB_APP_ID=ca-app-pub-…~…`
     (defaults to Google's test app id)
   - iOS: `ios/Flutter/AdKeys.xcconfig` (git-ignored) containing
     `ADMOB_APP_ID=ca-app-pub-…~…`
4. Debug builds without AdMob unit ids use Google's public test units.

iOS: no ATT prompt (AdMob works without IDFA; add ATT only if you want
personalized ads). `SKAdNetworkItems` has Google's id; add the partner list
from Google's docs if you enable AdMob mediation.
