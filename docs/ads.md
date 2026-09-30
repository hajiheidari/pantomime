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
dart run tool/store.dart dev        # adivery + admob (committed default)
# then `flutter pub get` (or `flutter pub upgrade google_mobile_ads` when the
# tool says so), then build.
```

Add `--with-tapsell` to include Tapsell (see the warning below).
`AdManager` also refuses AdMob on Bazaar/Myket at runtime, and the config
validator rejects configs that name AdMob for those stores.

Only SDKs compiled into a build can be switched remotely. A brand-new network
needs an app update. No code is ever downloaded.

## ⚠️ Tapsell Plus finding (checked 2026-09-30, verified by building)

`tapsell_plus` 2.3.2 (latest on pub.dev, published 2025-02-24) **does not
build** with the current Flutter toolchain (Flutter 3.47, AGP 9, Gradle 9):

1. Its `android/build.gradle` calls `jcenter()`, which Gradle 9 removed. The
   build fails at configuration.
2. It pins `google_mobile_ads ^4.0.0`, whose Android build also fails on
   Gradle 9 (`configurations.all`). Forcing 9.1.0 via `dependency_overrides`
   fixes this part (the Dart side still resolves), but not point 1.
3. Its native SDK (`ir.tapsell.plus:tapsell-plus-sdk-flutter:2.3.2`) pulls
   `play-services-auth` and `play-services-appset`, which isn't allowed in
   Bazaar/Myket builds.

So Tapsell is **opt-in (`--with-tapsell`) and excluded from every profile,
`dev` included**. The provider (`packages/ads_tapsell`) is implemented and
analyzed standalone, ready for when Tapsell ships a fixed plugin. Remote
config may still list `tapsell`; it's simply skipped because it isn't
compiled in.

Ways forward (your call):
- (a) Adivery only on Bazaar/Myket (current default). Adivery mediates
  other networks itself. The A/B test then compares Adivery vs. nothing, so
  keep `ab_split` off for now.
- (b) Vendor a patched copy of `tapsell_plus` (remove `jcenter()`, loosen
  the AdMob constraint). This is small, but check Tapsell's license first and
  test on a phone without Play Services.
- (c) Ask Tapsell support for an updated Flutter plugin, or wrap their
  plain Android SDK through our own platform channel.

### What the Bazaar build actually contains (verified)

`flutter build apk --dart-define=STORE=bazaar` with the `bazaar` profile
builds. `apkanalyzer` shows **no** `com.google.android.gms` classes defined
in the APK. Only Adivery's built-in AdMob mediation adapter
(`com.adivery.sdk.networks.admob.*`) *references* AdMob types, and it's
dormant without the AdMob SDK. The merged manifest does contain
`com.google.android.gms.permission.AD_ID` (from the ad SDK). It's harmless
without Play Services, but will be stripped in the Bazaar/Myket flavors in M6.

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
