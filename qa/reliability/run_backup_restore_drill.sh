#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
pg_dump_bin="${PG_DUMP_BIN:-/opt/homebrew/opt/postgresql@17/bin/pg_dump}"
createdb_bin="${CREATEDB_BIN:-/opt/homebrew/opt/postgresql@17/bin/createdb}"
dropdb_bin="${DROPDB_BIN:-/opt/homebrew/opt/postgresql@17/bin/dropdb}"
pg_restore_bin="${PG_RESTORE_BIN:-/opt/homebrew/opt/postgresql@17/bin/pg_restore}"

case "$source_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Local restore drill refuses non-loopback databases." >&2; exit 2 ;;
esac

host="${LOCAL_POSTGRES_HOST:-127.0.0.1}"
port="${LOCAL_POSTGRES_PORT:-55433}"
user="${LOCAL_POSTGRES_USER:-dating_app}"
restore_db="dating_app_restore_drill_$$"
artifact="${QA_BACKUP_ARTIFACT:-${TMPDIR:-/tmp}/local-backup-$restore_db.dump}"
report="${QA_BACKUP_REPORT:-$root_dir/qa/reports/reliability/local-backup-restore.json}"
started="$(date +%s)"
mkdir -p "$(dirname "$artifact")"

cleanup() {
  "$dropdb_bin" -h "$host" -p "$port" -U "$user" --if-exists "$restore_db" >/dev/null 2>&1 || true
  if [[ -z "${QA_BACKUP_ARTIFACT:-}" ]]; then
    rm -f "$artifact"
  fi
}
trap cleanup EXIT

"$pg_dump_bin" "$source_url" --format=custom --no-owner --no-privileges --file="$artifact"
"$createdb_bin" -h "$host" -p "$port" -U "$user" "$restore_db"
"$pg_restore_bin" -h "$host" -p "$port" -U "$user" --dbname="$restore_db" \
  --no-owner --no-privileges "$artifact"

restored_url="postgresql://$user@$host:$port/$restore_db?sslmode=disable"
"$psql_bin" "$restored_url" -X -v ON_ERROR_STOP=1 -Atqc "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version='078_correctness_recovery_contracts') THEN
    RAISE EXCEPTION 'latest correctness migration missing after restore';
  END IF;
  IF to_regclass('platform.domain_event_outbox') IS NULL
     OR to_regclass('platform.idempotency_records') IS NULL
     OR to_regclass('progression.xp_ledger') IS NULL THEN
    RAISE EXCEPTION 'critical durable relations missing after restore';
  END IF;
END
\$\$;"

elapsed="$(( $(date +%s) - started ))"
bytes="$(stat -f '%z' "$artifact")"
mkdir -p "$(dirname "$report")"
cat >"$report" <<JSON
{
  "scope": "local_only",
  "production_rpo_rto_evidence": false,
  "passed": true,
  "elapsed_seconds": $elapsed,
  "backup_bytes": $bytes,
  "checks": ["latest_migration", "domain_event_outbox", "idempotency_records", "xp_ledger"]
}
JSON
echo "Local backup/restore drill passed in ${elapsed}s: $report"
