#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
DOCS="$ROOT/docs"
OZ_DOCS="$DOCS/oz-docs"
OUTDIR="$OZ_DOCS/content/community-contracts/api"

# Init the docs project locally by cloning and installing it.
init() {
  rm -rf "$OZ_DOCS"
  cd "$DOCS"
  git clone --branch main https://github.com/OpenZeppelin/docs.git oz-docs
  cd $OZ_DOCS
  pnpm i
}

# Sync the locally prepared docs into the local docs project.
sync() {
  mkdir -p "$OUTDIR"
  rsync -a --delete "$DOCS/modules/api/pages/" "$OUTDIR/"
  mkdir -p "$OUTDIR/examples"
  rsync -a --delete "$DOCS/modules/api/examples/" "$OUTDIR/examples/"
}

# Entry point used by the watcher. (no init).
if [ "${SYNC_ONCE:-false}" = "true" ]; then
  echo "[oz-docs] changes detected, syncing…"
  sync
  exit 0
fi

# Always run once.
init

# Always run once.
sync

# Watch mode: keep regenerating in the background.
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
