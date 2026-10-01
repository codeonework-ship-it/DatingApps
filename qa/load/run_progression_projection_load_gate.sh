#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
backend_dir="$root_dir/backend"
pg_bin="${POSTGRES_BIN_DIR:-/opt/homebrew/opt/postgresql@17/bin}"
pg_host="${LOCAL_POSTGRES_HOST:-127.0.0.1}"
pg_port="${LOCAL_POSTGRES_PORT:-55433}"
pg_user="${LOCAL_POSTGRES_USER:-dating_app}"
source_db="${LOCAL_POSTGRES_DB:-dating_app}"
load_db="dating_app_progression_load_$(date +%s)_$RANDOM"
source_url="postgresql://$pg_user@$pg_host:$pg_port/$source_db?sslmode=disable"
load_url="postgresql://$pg_user@$pg_host:$pg_port/$load_db?sslmode=disable"
report="${PROGRESSION_LOAD_REPORT:-$root_dir/documents/evidence/progression_projection_load_local_2026-09-27.json}"

if [[ "$pg_host" != "127.0.0.1" && "$pg_host" != "localhost" ]]; then
  echo "refusing load gate against non-local PostgreSQL host $pg_host" >&2
  exit 2
fi

cleanup() {
  "$pg_bin/dropdb" --if-exists --force -h "$pg_host" -p "$pg_port" -U "$pg_user" "$load_db" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"$backend_dir/scripts/local_postgres.sh" up >/dev/null
"$pg_bin/psql" "$source_url" -X -v ON_ERROR_STOP=1 -Atqc \
  "SELECT 1 FROM public.schema_migrations WHERE version='079_progression_production_rollout'" | grep -q 1 || {
    echo "migration 079 must be applied before the progression load gate" >&2
    exit 1
  }
"$pg_bin/createdb" -h "$pg_host" -p "$pg_port" -U "$pg_user" -T template0 "$load_db"
"$pg_bin/pg_dump" "$source_url" --schema-only --no-owner --no-privileges | "$pg_bin/psql" "$load_url" -X -v ON_ERROR_STOP=1 >/dev/null
"$pg_bin/pg_dump" "$source_url" --data-only --column-inserts --no-owner --no-privileges \
  -t progression.level_definitions -t progression.xp_source_policies \
  -t progression.fraud_rule_policies | "$pg_bin/psql" "$load_url" -X -v ON_ERROR_STOP=1 >/dev/null

mkdir -p "$(dirname "$report")"
(
  cd "$backend_dir"
  PROGRESSION_LOAD_DATABASE_URL="$load_url" \
  PROGRESSION_LOAD_REPORT="$report" \
  go test ./internal/bff/mobile -run 'TestProgression(ProjectionLoadGate|FraudTuningGate)$' -count=1 -v
)

echo "progression projection load gate passed: $report"
