#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f "config/.env" ]]; then
  # shellcheck disable=SC1091
  source "config/.env"
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL is not set. Export it or define it in backend/config/.env"
  exit 1
fi

if ! command -v /opt/homebrew/opt/libpq/bin/psql >/dev/null 2>&1 && ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found. Install libpq first."
  exit 1
fi

PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
if ! command -v "$PSQL_BIN" >/dev/null 2>&1; then
  PSQL_BIN="$(command -v psql)"
fi

DB_HOST="${DATABASE_HOST:-${SUPABASE_DB_HOST:-}}"
if [[ -z "$DB_HOST" ]]; then
  DB_HOST="$(printf '%s' "$DATABASE_URL" | sed -E 's|^[^@]*@([^:/?]+).*$|\1|')"
fi

if [[ "$DB_HOST" != *"supabase.co"* && "$DB_HOST" != *"pooler.supabase.com"* ]]; then
  echo "ERROR: Refusing to run because host does not look like Supabase: $DB_HOST"
  exit 1
fi

if [[ "${ALLOW_PROD_FULL_REBUILD:-}" != "YES" ]]; then
  echo "ERROR: This operation is destructive. Set ALLOW_PROD_FULL_REBUILD=YES to continue."
  exit 1
fi

if [[ "${CONFIRM_PROD_FULL_REBUILD:-}" != "REBUILD_PRODUCTION_NOW" ]]; then
  echo "ERROR: Set CONFIRM_PROD_FULL_REBUILD=REBUILD_PRODUCTION_NOW to confirm destructive execution."
  exit 1
fi

SCRIPTS=(
  "scripts/035_full_drop_all_screens_schema.sql"
  "scripts/036_full_create_all_screens_schema.sql"
  "scripts/037_seed_full_screens_100_users_50_matches.sql"
)

for script in "${SCRIPTS[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "ERROR: Missing required script: $script"
    exit 1
  fi
done

echo "Target host: $DB_HOST"
echo "Applying destructive full rebuild scripts in order..."

for script in "${SCRIPTS[@]}"; do
  echo "-> Running $script"
  "$PSQL_BIN" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$script"
done

echo "FULL_REBUILD_APPLY_OK"
