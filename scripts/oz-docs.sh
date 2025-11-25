#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)/..
ROOT=$(pwd)
DOCS=$ROOT/docs
OZ_DOCS=$DOCS/oz-docs
rm -rf $OZ_DOCS
cd $DOCS
git clone --branch main https://github.com/OpenZeppelin/docs.git oz-docs
cp -r $DOCS/modules/api/pages/*  $OZ_DOCS/content/community-contracts/api
cp -r $DOCS/modules/api/examples $OZ_DOCS/content/community-contracts/api 
cd $OZ_DOCS
pnpm i
if [ "$WATCH" = "true" ]; then
  pnpm run dev
else
  pnpm run build
fi
