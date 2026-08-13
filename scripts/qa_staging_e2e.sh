#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/dev_env.sh
source scripts/dev_env.sh

required_vars=(
  QUALITY_DEVICE_ID
  E2E_SUPABASE_URL
  E2E_SUPABASE_ANON_KEY
  E2E_STAGING_PROJECT_REF
  E2E_USER_A_EMAIL
  E2E_USER_A_PASSWORD
  E2E_USER_B_EMAIL
  E2E_USER_B_PASSWORD
  E2E_PUBLIC_HANDLE
  E2E_REQUESTER_EMAIL
)

for variable in "${required_vars[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    echo "Set $variable before running staging E2E." >&2
    exit 64
  fi
done

production_project_ref="imtbyrvsonzvtddswbtb"
if [[ "$E2E_STAGING_PROJECT_REF" == "$production_project_ref" ]]; then
  echo "Refusing to run write-capable E2E against the production project." >&2
  exit 65
fi

expected_staging_url="https://${E2E_STAGING_PROJECT_REF}.supabase.co"
if [[ "${E2E_SUPABASE_URL%/}" != "$expected_staging_url" ]]; then
  echo "E2E_SUPABASE_URL must exactly match the declared staging project ref." >&2
  echo "Expected: $expected_staging_url" >&2
  exit 65
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required to create the private Dart define file." >&2
  exit 69
fi

e2e_defines_file="$(mktemp "${TMPDIR:-/tmp}/workloop-e2e-defines.XXXXXX.json")"
trap 'rm -f "$e2e_defines_file"' EXIT
export E2E_PUBLIC_HANDLE E2E_STAGING_PROJECT_REF E2E_SUPABASE_ANON_KEY
export E2E_SUPABASE_URL E2E_USER_A_EMAIL E2E_USER_A_PASSWORD
export E2E_USER_B_EMAIL E2E_USER_B_PASSWORD E2E_REQUESTER_EMAIL
export WORKLOOP_E2E_DEFINES_FILE="$e2e_defines_file"
python3 <<'PY'
import json
import os

keys = (
    "E2E_PUBLIC_HANDLE",
    "E2E_STAGING_PROJECT_REF",
    "E2E_USER_A_EMAIL",
    "E2E_USER_A_PASSWORD",
    "E2E_USER_B_EMAIL",
    "E2E_USER_B_PASSWORD",
    "E2E_REQUESTER_EMAIL",
)
defines = {key: os.environ[key] for key in keys}
defines.update({
    "E2E_ALLOW_WRITES": True,
    "SUPABASE_ANON_KEY": os.environ["E2E_SUPABASE_ANON_KEY"],
    "SUPABASE_URL": os.environ["E2E_SUPABASE_URL"],
})
with open(os.environ["WORKLOOP_E2E_DEFINES_FILE"], "w", encoding="utf-8") as handle:
    json.dump(defines, handle)
PY

flutter test \
  integration_test/staging_core_workflow_test.dart \
  integration_test/staging_tenant_isolation_test.dart \
  integration_test/staging_public_booking_test.dart \
  -d "$QUALITY_DEVICE_ID" \
  --dart-define-from-file="$e2e_defines_file"
