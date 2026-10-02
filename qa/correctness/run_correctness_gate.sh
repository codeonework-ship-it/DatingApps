#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Correctness gate only runs against loopback PostgreSQL." >&2; exit 2 ;;
esac

(cd "$root_dir/backend" && go test ./internal/bff/mobile -run \
  'TestCursorNeedsSnapshot|TestXPAwardRepairPayload|TestFeatureFlagForRoute|TestIdempotencyMiddleware|TestOpenAPI' -count=1)

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 \
  -f "$root_dir/qa/correctness/correctness_acceptance.sql"

python3 "$root_dir/qa/governance/validate_correctness_recovery.py" --mode contract

echo "Correctness, idempotency and recovery gate passed"
