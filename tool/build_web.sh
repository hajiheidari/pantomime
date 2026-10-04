#!/usr/bin/env bash
# Web / PWA build → build/site (landing page at /, game at /play/).
#
#   tool/build_web.sh                       # build only
#   tool/build_web.sh --deploy              # + upload to Cloudflare (web_deploy/)
#   SITE_URL=https://example.ir tool/build_web.sh
#
# The same build/site also works inside any folder of another host (mirror):
# all game paths are relative. See docs/web.md.
set -euo pipefail
cd "$(dirname "$0")/.."

SITE_URL="${SITE_URL:-https://pantomime.sepanta-hesaban.workers.dev}"
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
SITE_URL="$SITE_URL" node tool/web_finish.mjs
echo "→ build/site  (open: python3 -m http.server -d build/site 8080)"

if [[ "${1:-}" == "--deploy" ]]; then
  (cd web_deploy && ../server/node_modules/.bin/wrangler deploy)
fi
