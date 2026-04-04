#!/usr/bin/env bash
set -euo pipefail

PG_DUMP_BIN="$(command -v pg_dump || true)"
PSQL_BIN="$(command -v psql || true)"
PG_RESTORE_BIN="$(command -v pg_restore || true)"

if [[ -z "$PG_DUMP_BIN" || -z "$PSQL_BIN" || -z "$PG_RESTORE_BIN" ]]; then
  if [[ -x "/opt/homebrew/opt/libpq/bin/pg_dump" && -x "/opt/homebrew/opt/libpq/bin/psql" && -x "/opt/homebrew/opt/libpq/bin/pg_restore" ]]; then
    PG_DUMP_BIN="/opt/homebrew/opt/libpq/bin/pg_dump"
    PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
    PG_RESTORE_BIN="/opt/homebrew/opt/libpq/bin/pg_restore"
  fi
fi

if [[ -z "$PG_DUMP_BIN" ]]; then
  echo "ERROR: pg_dump is not installed." >&2
  exit 1
fi

if [[ -z "$PSQL_BIN" ]]; then
  echo "ERROR: psql is not installed." >&2
  exit 1
fi

if [[ -z "$PG_RESTORE_BIN" ]]; then
  echo "ERROR: pg_restore is not installed." >&2
  exit 1
fi

: "${SUPABASE_DATABASE_URL:?SUPABASE_DATABASE_URL is required}"
: "${LOCAL_DATABASE_URL:?LOCAL_DATABASE_URL is required}"

TMP_DIR="$(mktemp -d)"
DUMP_FILE="$TMP_DIR/supabase_dump.dump"
SCHEMA_REPORT="$TMP_DIR/local_schema_report.txt"
SCHEMAS_FILE="$TMP_DIR/source_schemas.txt"
RESET_SQL="$TMP_DIR/reset_schemas.sql"
ROW_COUNT_REPORT="$TMP_DIR/row_counts.txt"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

build_admin_db_url() {
  local db_url="$1"
  local base="${db_url%%\?*}"
  local query=""
  if [[ "$db_url" == *\?* ]]; then
    query="?${db_url#*\?}"
  fi
  echo "${base%/*}/postgres${query}"
}

LOCAL_ADMIN_DB_URL="$(build_admin_db_url "$LOCAL_DATABASE_URL")"

LOCAL_DB_NAME="$(
  echo "$LOCAL_DATABASE_URL" |
    sed -E 's|^[^:]+://([^@/]+@)?[^/]+/([^?]+)(\?.*)?$|\2|'
)"

if [[ -z "$LOCAL_DB_NAME" || "$LOCAL_DB_NAME" == "$LOCAL_DATABASE_URL" ]]; then
  echo "ERROR: unable to parse local database name from LOCAL_DATABASE_URL" >&2
  exit 1
fi

echo "[0/6] Ensuring local database exists..."
LOCAL_DB_EXISTS="$($PSQL_BIN "$LOCAL_ADMIN_DB_URL" -tAc "SELECT 1 FROM pg_database WHERE datname='${LOCAL_DB_NAME}'" || true)"
if [[ "$LOCAL_DB_EXISTS" != "1" ]]; then
  "$PSQL_BIN" "$LOCAL_ADMIN_DB_URL" -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"${LOCAL_DB_NAME}\";"
  echo "Created local database: ${LOCAL_DB_NAME}"
else
  echo "Local database already exists: ${LOCAL_DB_NAME}"
fi

echo "[1/6] Discovering source schemas with tables..."
"$PSQL_BIN" "$SUPABASE_DATABASE_URL" -v ON_ERROR_STOP=1 -At <<'SQL' > "$SCHEMAS_FILE"
SELECT n.nspname
FROM pg_namespace n
WHERE n.nspname <> 'information_schema'
  AND n.nspname <> 'pg_toast'
  AND n.nspname <> 'pg_catalog'
  AND n.nspname <> 'auth'
  AND n.nspname <> 'storage'
  AND n.nspname <> 'realtime'
  AND n.nspname <> 'vault'
  AND n.nspname NOT LIKE 'pg_%'
  AND EXISTS (
    SELECT 1
    FROM pg_class c
    WHERE c.relnamespace = n.oid
      AND c.relkind IN ('r', 'p')
  )
ORDER BY n.nspname;
SQL

if [[ ! -s "$SCHEMAS_FILE" ]]; then
  echo "ERROR: no source schemas with tables were discovered." >&2
  exit 1
fi

SCHEMAS=()
while IFS= read -r schema; do
  [[ -n "$schema" ]] && SCHEMAS+=("$schema")
done < "$SCHEMAS_FILE"

if [[ "${#SCHEMAS[@]}" -eq 0 ]]; then
  echo "ERROR: schema discovery returned no entries." >&2
  exit 1
fi

echo "Source schemas: ${SCHEMAS[*]}"

echo "[2/6] Exporting Supabase database..."
DUMP_ARGS=(
  --no-owner
  --no-privileges
  --format=custom
  --encoding=UTF8
)
for schema in "${SCHEMAS[@]}"; do
  DUMP_ARGS+=(--schema "$schema")
done

"$PG_DUMP_BIN" \
  "${DUMP_ARGS[@]}" \
  --dbname "$SUPABASE_DATABASE_URL" \
  > "$DUMP_FILE"

echo "[3/6] Resetting target schemas..."
{
  for schema in "${SCHEMAS[@]}"; do
    echo "DROP SCHEMA IF EXISTS \"${schema}\" CASCADE;"
  done
  for schema in "${SCHEMAS[@]}"; do
    echo "CREATE SCHEMA IF NOT EXISTS \"${schema}\";"
  done
} > "$RESET_SQL"

"$PSQL_BIN" "$LOCAL_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$RESET_SQL"

echo "[4/6] Restoring into local PostgreSQL..."
"$PG_RESTORE_BIN" \
  --no-owner \
  --no-privileges \
  --clean \
  --if-exists \
  --dbname "$LOCAL_DATABASE_URL" \
  "$DUMP_FILE"

echo "[5/6] Running schema presence check..."
"$PSQL_BIN" "$LOCAL_DATABASE_URL" -v ON_ERROR_STOP=1 -At <<'SQL' > "$SCHEMA_REPORT"
SELECT table_schema || '.' || table_name
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_schema NOT LIKE 'pg_%'
ORDER BY table_schema, table_name;
SQL

echo "[6/6] Running row-count summary..."
while IFS= read -r schema; do
  "$PSQL_BIN" "$LOCAL_DATABASE_URL" -v ON_ERROR_STOP=1 -At <<SQL >> "$ROW_COUNT_REPORT"
SELECT '${schema}.' || table_name || '=' || row_count
FROM (
  SELECT c.relname AS table_name, c.reltuples::bigint AS row_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = '${schema}'
    AND c.relkind IN ('r', 'p')
) t
ORDER BY table_name;
SQL
done < "$SCHEMAS_FILE"

echo "Done. Tables discovered:"
cat "$SCHEMA_REPORT"

echo "Row-count summary (estimated from reltuples):"
cat "$ROW_COUNT_REPORT"

echo "Migration completed successfully."
