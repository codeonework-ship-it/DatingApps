#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Event architecture gate only accepts a loopback PostgreSQL database." >&2; exit 2 ;;
esac

"$psql_bin" "$database_url" -X -Atqc \
  "SELECT 1 FROM public.schema_migrations WHERE version='075_domain_event_backbone'" | grep -qx 1

(cd "$workspace/backend" && go test ./internal/platform/postgres ./internal/bff/mobile \
  -run 'TestDomainEventBackbone|TestEventFilterSQL|TestPrincipalCanAccessAdminRouteByRole|TestOpenAPI_DocumentsEveryRegisteredRoute' \
  -count=1)
"$psql_bin" "$database_url" -X -f "$workspace/qa/event_architecture/event_backbone_acceptance.sql"

echo "event architecture gate passed"
