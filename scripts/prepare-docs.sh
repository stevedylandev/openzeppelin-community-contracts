#!/usr/bin/env bash

set -euo pipefail
shopt -s globstar

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

OUTDIR="$(node -p 'require("./docs/config.js").outputDir')"

if [ ! -d node_modules ]; then
  npm ci
fi

examples_source_dir="contracts/mocks/docs"
examples_target_dir="docs/modules/api/examples"

prepare() {
  rm -rf "$OUTDIR"
  hardhat docgen

  rm -rf "$examples_target_dir"
  mkdir -p "$examples_target_dir"

  for f in "$examples_source_dir"/**/*.sol; do
    name="${f/#"$examples_source_dir/"/}"
    mkdir -p "$examples_target_dir/$(dirname "$name")"
    sed -Ee '/^import/s|"(\.\./)+|"@openzeppelin/community-contracts/|' "$f" > "$examples_target_dir/$name"
  done
}

# Entry point used by the watcher.
if [ "${PREPARE_ONCE:-false}" = "true" ]; then
  echo "[prepare-docs] changes detected, preparing…"
  prepare
  exit 0
fi

# Always run once.
prepare

# Watch mode: keep regenerating in the background.
if [ "${WATCH:-false}" = "true" ]; then
  CHOKIDAR_BIN="$ROOT/node_modules/.bin/chokidar"
  if [ ! -x "$CHOKIDAR_BIN" ]; then
    echo "error: chokidar-cli not found (run: npm i -D chokidar-cli)" >&2
    exit 1
  fi

  "$CHOKIDAR_BIN" \
    "contracts/**/*.{sol,mdx,adoc}" \
    "docs/config.js" \
    --ignoreInitial \
    --throttle 200 \
    --debounce 200 \
    -c "PREPARE_ONCE=true WATCH=false bash \"$ROOT/scripts/prepare-docs.sh\"" \
    >/dev/null 2>&1 &
fi