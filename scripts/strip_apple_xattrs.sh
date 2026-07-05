#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/dev_env.sh

paths=(
  "../flutter/bin/cache/artifacts/engine"
  "ios/Pods"
  "macos/Pods"
  "build/ios"
  "build/macos"
)

for path in "${paths[@]}"; do
  if [ -e "$path" ]; then
    /usr/bin/xattr -cr "$path" || true
  fi
done

