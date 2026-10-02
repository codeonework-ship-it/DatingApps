#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
scale_rows="${SCALE_PLAN_ROWS:-250000}"
report="${SCALE_PLAN_REPORT:-$root_dir/qa/reports/reliability/query-plans.txt}"

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Query-plan gate requires loopback PostgreSQL." >&2; exit 2 ;;
esac
if (( scale_rows < 100000 )); then
  echo "SCALE_PLAN_ROWS must be at least 100000." >&2
  exit 2
fi

mkdir -p "$(dirname "$report")"
"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -v scale_rows="$scale_rows" \
  -f "$root_dir/qa/reliability/production_cardinality_query_plans.sql" >"$report"

for marker in PLAN_CHAT_RESUME PLAN_NOTIFICATION_CLAIM PLAN_IDEMPOTENCY_CLAIM PLAN_IDEMPOTENCY_RETENTION; do
  grep -q "$marker" "$report" || { echo "missing plan marker $marker" >&2; exit 1; }
done
if grep -Eq 'Seq Scan on scale_(messages|notification_outbox|idempotency_records)' "$report"; then
  echo "A production-shape critical query regressed to a sequential scan." >&2
  grep -E 'Seq Scan on scale_' "$report" >&2
  exit 1
fi
grep -Eq '(Index Scan|Index Only Scan).*scale_messages_timeline_cover' "$report"
grep -Eq '(Index Scan|Index Only Scan).*scale_notification_claim_cover' "$report"
grep -Eq 'Index Scan using scale_idempotency_records_pkey' "$report"

echo "Query-plan gate passed at $scale_rows rows per workload: $report"
