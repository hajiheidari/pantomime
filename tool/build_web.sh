#!/usr/bin/env bash
# Web / PWA build:
#   build/game     → https://pantomime.espadna.com   (web_deploy/)
#   build/espadna  → https://espadna.com             (site_deploy/, studio
#                    home + /pantomime-app/ landing pages from site/)
#
#   tool/build_web.sh            # build only
#   tool/build_web.sh --deploy   # + upload both to Cloudflare
#
# build/game also works inside any folder of another host (mirror): all game
# paths are relative. See docs/web.md.
set -euo pipefail
cd "$(dirname "$0")/.."

defines=()
[[ -f ad_keys.json ]] && defines+=(--dart-define-from-file=ad_keys.json)

restore() {
  dart run tool/store.dart dev >/dev/null
  flutter pub get >/dev/null
}
trap restore EXIT

dart run tool/store.dart web
flutter pub get
# Local CanvasKit (no gstatic CDN: offline + reachable from Iran).
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run "${defines[@]}"
node tool/web_finish.mjs

if [[ "${1:-}" == "--deploy" ]]; then
  (cd web_deploy && ../server/node_modules/.bin/wrangler deploy)
  (cd site_deploy && ../server/node_modules/.bin/wrangler deploy)
fi
