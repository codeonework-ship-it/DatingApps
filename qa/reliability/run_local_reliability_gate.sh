#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55432/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
python_bin="${PYTHON_BIN:-python3}"
report="${QA_RELIABILITY_REPORT:-$root_dir/qa/reports/reliability/native-postgres-burst.json}"

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Reliability gate requires a loopback PostgreSQL URL." >&2; exit 2 ;;
esac
if [[ "$database_url" == *supabase* ]]; then
  echo "Supabase connections are forbidden for this gate." >&2
  exit 2
fi

(cd "$root_dir/backend" && go test -race \
  ./internal/bff/mobile ./internal/platform/config ./internal/platform/postgresdata \
  -run 'TestTimeoutTier|TestBulkhead|TestIdempotency|TestLoad_UsesNative|TestSetRuntime|TestClassify' -count=1)
(cd "$root_dir/backend" && go test ./internal/platform/observability -run TestReliabilityDashboardAndAlertsAreProvisionable -count=1)

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -Atqc "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version='058_reliability_scale_guardrails') THEN
    RAISE EXCEPTION 'migration 058_reliability_scale_guardrails is not recorded';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version='063_shared_idempotency_and_retention') THEN
    RAISE EXCEPTION 'migration 063_shared_idempotency_and_retention is not recorded';
  END IF;
  IF to_regclass('matching.idx_messages_match_timeline_cover') IS NULL
     OR to_regclass('matching.idx_notification_outbox_claim_cover') IS NULL
     OR to_regclass('user_management.idx_users_discovery_active_cover') IS NULL THEN
    RAISE EXCEPTION 'reliability covering indexes are missing';
  END IF;
  IF to_regclass('platform.idempotency_records') IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM pg_inherits
       WHERE inhparent='platform.idempotency_archive'::regclass
     ) THEN
    RAISE EXCEPTION 'shared idempotency or current archive partition is missing';
  END IF;
END
\$\$;"

mkdir -p "$(dirname "$report")"

# The distributed gate is the only barrier between a laptop run and a signed
# production capacity claim. Re-check its guards here so they cannot be removed
# quietly: this needs no services and no load.
"$python_bin" "$root_dir/qa/reliability/scale_gate_integrity_test.py"

"$root_dir/qa/reliability/run_query_plan_gate.sh"
"$python_bin" "$root_dir/qa/reliability/native_postgres_burst_gate.py" \
  --profile "${QA_RELIABILITY_PROFILE:-smoke}" --report "$report"

echo "Reliability gate passed: $report"
