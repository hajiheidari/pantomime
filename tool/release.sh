#!/usr/bin/env bash
# Release build for one store:
#   tool/release.sh play     → AAB  (Google Play)
#   tool/release.sh bazaar   → APK  (Cafe Bazaar)
#   tool/release.sh myket    → APK  (Myket)
#   tool/release.sh ios      → IPA  (App Store; macOS + Xcode only)
#
# Selects the store's ad-SDK profile (tool/store.dart), builds the matching
# Android flavor with your ad_keys.json, then restores the dev profile.
# Signing: android/keys/<store>.properties (see docs/store_notes.md).
set -euo pipefail
cd "$(dirname "$0")/.."

store="${1:-}"
case "$store" in
  play | bazaar | myket | ios) ;;
  *) echo "usage: tool/release.sh <play|bazaar|myket|ios>" >&2; exit 64 ;;
esac

defines=()
if [[ -f ad_keys.json ]]; then
  defines+=(--dart-define-from-file=ad_keys.json)
else
  echo "⚠️  ad_keys.json not found: building without ad ids / config URLs" >&2
fi
gradle_props=()
if [[ -n "${ADMOB_APP_ID:-}" ]]; then
  gradle_props+=(--android-project-arg="ADMOB_APP_ID=$ADMOB_APP_ID")
fi

restore() {
  dart run tool/store.dart dev >/dev/null
  flutter pub upgrade google_mobile_ads >/dev/null
}
trap restore EXIT

dart run tool/store.dart "$store"
if [[ "$store" == "bazaar" || "$store" == "myket" ]]; then
  flutter pub get
else
  flutter pub upgrade google_mobile_ads
fi

common=(--release --obfuscate --split-debug-info="build/symbols/$store" "${defines[@]}")
case "$store" in
  play)
    flutter build appbundle --flavor play "${common[@]}" "${gradle_props[@]}"
    echo "→ build/app/outputs/bundle/playRelease/app-play-release.aab"
    ;;
  bazaar | myket)
    flutter build apk --flavor "$store" "${common[@]}"
    echo "→ build/app/outputs/flutter-apk/app-$store-release.apk"
    ;;
  ios)
    flutter build ipa "${common[@]}"
    echo "→ build/ios/ipa/"
    ;;
esac
echo "Keep build/symbols/$store to symbolicate crash reports (obfuscated build)."
