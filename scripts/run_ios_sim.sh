#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/dev_env.sh

if [ ! -f .env ]; then
  echo "Missing .env. Create it from .env.example before running the app." >&2
  exit 1
fi

flutter run -d ios --dart-define-from-file=.env

