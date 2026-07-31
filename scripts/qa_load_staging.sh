#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v k6 >/dev/null 2>&1; then
  echo "k6 is required for staging load tests." >&2
  exit 69
fi
if [[ "${LOAD_TEST_ENV:-}" != "staging" ]]; then
  echo "Refusing to run unless LOAD_TEST_ENV=staging." >&2
  exit 78
fi
if [[ "${ALLOW_STAGING_LOAD:-false}" != "true" ]]; then
  echo "Refusing to run unless ALLOW_STAGING_LOAD=true." >&2
  exit 78
fi

k6 run quality/load/workloop_staging.js
