#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/dev_env.sh
source scripts/dev_env.sh

device_id="${QUALITY_DEVICE_ID:-}"
if [[ -z "$device_id" ]]; then
  echo "Set QUALITY_DEVICE_ID to an emulator, simulator, or test device." >&2
  exit 64
fi

flutter test integration_test \
  -d "$device_id" \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=ci-public-anon-key
