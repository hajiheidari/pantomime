#!/usr/bin/env bash
# Runs every local check: app analysis + tests, and each ad package analyzed
# standalone (their dependency sets differ per store profile).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter analyze
flutter test
for p in packages/*/; do
  echo "== $p"
  (cd "$p" && flutter pub get >/dev/null && flutter analyze)
done
echo "== server"
(cd server && npm test)
