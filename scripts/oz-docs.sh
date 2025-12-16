#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
DOCS="$ROOT/docs"
OZ_DOCS="$DOCS/oz-docs"

API_TARGET="$OZ_DOCS/content/community-contracts/api"

sync_once() {
  mkdir -p "$API_TARGET"
  rsync -a --delete "$DOCS/modules/api/pages/" "$API_TARGET/"
  mkdir -p "$API_TARGET/examples"
  rsync -a --delete "$DOCS/modules/api/examples/" "$API_TARGET/examples/"
}

# Entry point used by the watcher (no clone/install/dev).
if [ "${SYNC_ONCE:-false}" = "true" ]; then
  sync_once
  exit 0
fi

rm -rf "$OZ_DOCS"
cd "$DOCS"
git clone --branch main https://github.com/OpenZeppelin/docs.git oz-docs

sync_once

cd "$OZ_DOCS"
pnpm i

if [ "${WATCH:-false}" = "true" ]; then
  CHOKIDAR_BIN="$ROOT/node_modules/.bin/chokidar"
  if [ ! -x "$CHOKIDAR_BIN" ]; then
    echo "error: chokidar-cli not found (run: npm i -D chokidar-cli)" >&2
    exit 1
  fi

  "$CHOKIDAR_BIN" \
    "$DOCS/modules/api/pages/**/*" \
    "$DOCS/modules/api/examples/**/*" \
    --ignoreInitial \
    --throttle 200 \
    --debounce 200 \
    -c "SYNC_ONCE=true WATCH=false bash \"$ROOT/scripts/oz-docs.sh\"" \
    >/dev/null 2>&1 &

  pnpm run dev
else
  pnpm run build
fi