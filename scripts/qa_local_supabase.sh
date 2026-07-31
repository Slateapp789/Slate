#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for isolated local Supabase tests." >&2
  exit 69
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but its daemon is not available." >&2
  exit 69
fi
if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is required for local database tests." >&2
  exit 69
fi

if rg -q 'imtbyrvsonzvtddswbtb|workloop\\.app|workloop\\.co\\.uk' \
  supabase/config.toml; then
  echo "Refusing to run: local config contains a production identifier." >&2
  exit 78
fi

supabase start
supabase db reset --local
supabase test db
