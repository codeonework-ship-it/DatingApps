#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Admin gate only accepts a loopback PostgreSQL database." >&2; exit 2 ;;
esac
[[ "$database_url" != *supabase* ]] || { echo "Supabase is forbidden in the local admin gate." >&2; exit 2; }

"$psql_bin" "$database_url" -X -Atqc \
  "SELECT 1 FROM public.schema_migrations WHERE version='060_admin_engagement_controls'" | grep -qx 1

"$workspace/backend/scripts/provision_local_operator.sh"
LOCAL_OPERATOR_USERNAME="${LOCAL_ANALYST_USERNAME:-local_control_analyst}" \
LOCAL_OPERATOR_PASSWORD="${LOCAL_ANALYST_PASSWORD:-LocalAnalyst123!}" \
LOCAL_OPERATOR_ROLE=analyst \
  "$workspace/backend/scripts/provision_local_operator.sh"

(cd "$workspace/backend" && go test ./internal/bff/mobile -run \
  'TestRuntimeConfigFlags|TestOpenAPI_DocumentsEveryRegisteredRoute|TestPrincipalCanAccessAdminRoute|TestOperatorAudit' -count=1)
(cd "$workspace/control-panel" && .venv/bin/python manage.py test control_panel.tests -v 1)
(cd "$workspace/app" && flutter test test/core/providers/runtime_feature_flags_provider_test.dart)
python3 "$workspace/qa/admin/admin_control_plane_acceptance.py"

command_center_port="${COMMAND_CENTER_PORT:-19000}"
command_center_url="http://127.0.0.1:${command_center_port}"
command_center_log="$(mktemp -t command-center-gate.XXXXXX)"
cleanup_command_center() {
  if [[ -n "${command_center_pid:-}" ]] && kill -0 "$command_center_pid" 2>/dev/null; then
    kill "$command_center_pid"
  fi
  rm -f "$command_center_log"
}
trap cleanup_command_center EXIT
(
  cd "$workspace/control-panel"
  GO_API_BASE_URL="${ADMIN_ACCEPTANCE_API:-http://127.0.0.1:18081/v1}" \
  GO_HEALTH_BASE_URL="${ADMIN_ACCEPTANCE_HEALTH:-http://127.0.0.1:18081}" \
  DJANGO_ALLOWED_HOSTS="127.0.0.1,localhost" \
    .venv/bin/python manage.py runserver "127.0.0.1:${command_center_port}" --noreload
) >"$command_center_log" 2>&1 &
command_center_pid=$!
for _ in $(seq 1 100); do
  if curl -fsS "$command_center_url/login/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
COMMAND_CENTER_URL="$command_center_url" \
  "$workspace/control-panel/.venv/bin/python" "$workspace/qa/admin/command_center_screen_gate.py"

echo "admin control plane gate passed"
