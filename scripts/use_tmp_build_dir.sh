#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

tmp_build_dir="${TMPDIR:-/private/tmp}/workloop-build"
mkdir -p "$tmp_build_dir"

if [ -e build ] && [ ! -L build ]; then
  backup_dir="${TMPDIR:-/private/tmp}/workloop-build-backup-$(date +%Y%m%d%H%M%S)"
  mv build "$backup_dir"
  echo "Moved existing generated build directory to $backup_dir"
fi

ln -sfn "$tmp_build_dir" build
echo "Using $tmp_build_dir for generated build output"

