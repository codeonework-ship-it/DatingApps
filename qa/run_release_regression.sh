#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_dir="${QA_RELEASE_REPORT_DIR:-$root_dir/qa/reports/release}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
python_bin="${PYTHON_BIN:-$root_dir/.venv/bin/python}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

mkdir -p "$report_dir"

say() { printf '\n==> %s\n' "$*"; }

run_logged() {
  local name="$1"
  shift
  say "$name"
  "$@" 2>&1 | tee "$report_dir/$name.log"
}

case "$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *)
    echo "Release regression only accepts a local PostgreSQL URL; got a non-local host." >&2
    exit 2
    ;;
esac

if [[ "$database_url" == *supabase* ]]; then
  echo "Supabase connections are forbidden for this release regression." >&2
  exit 2
fi

if [[ ! -x "$python_bin" ]]; then
  python_bin="$(command -v python3)"
fi
if [[ ! -x "$psql_bin" ]]; then
  psql_bin="$(command -v psql)"
fi

say "Local PostgreSQL migration state"
"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -Atqc "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '060_admin_engagement_controls') THEN
    RAISE EXCEPTION 'required migration 060_admin_engagement_controls is not recorded';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '075_domain_event_backbone') THEN
    RAISE EXCEPTION 'required migration 075_domain_event_backbone is not recorded';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '076_privacy_safety_trust_operations') THEN
    RAISE EXCEPTION 'required migration 076_privacy_safety_trust_operations is not recorded';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '077_calls_identity_voice_providers') THEN
    RAISE EXCEPTION 'required migration 077_calls_identity_voice_providers is not recorded';
  END IF;
  IF to_regclass('user_management.auth_credentials') IS NULL
     OR to_regclass('user_management.user_login_sessions') IS NULL
     OR to_regclass('matching.matches') IS NULL
     OR to_regclass('matching.messages') IS NULL
     OR to_regclass('matching.notification_outbox') IS NULL THEN
    RAISE EXCEPTION 'required native PostgreSQL runtime tables are missing';
  END IF;
END
\$\$;"

run_logged "auth-automation-contract" \
  "$python_bin" -m pytest "$root_dir/qa/appium/tests/test_auth_automation_contract.py" -q

run_logged "release-governance-contract" \
  "$root_dir/qa/governance/run_release_governance_gate.sh" contract

if [[ "${QA_SKIP_GO:-false}" != "true" ]]; then
  run_logged "backend-go-tests" bash -lc "cd '$root_dir/backend' && go test ./..."
  run_logged "backend-compliance" bash -lc "cd '$root_dir/backend' && make backend-compliance-check"
fi

run_logged "event-architecture" env LOCAL_DATABASE_URL="$database_url" \
  "$root_dir/qa/event_architecture/run_event_architecture_gate.sh"

if [[ "${QA_SKIP_FLUTTER:-false}" != "true" ]]; then
  run_logged "flutter-tests" bash -lc "cd '$root_dir/app' && flutter test"
  run_logged "flutter-authenticated-screens" bash -lc \
    "cd '$root_dir/app' && flutter test --dart-define=USE_MOCK_AUTH=true --dart-define=QA_SCREEN_FIXTURES=true test/features/responsive/screen_matrix_test.dart"
  run_logged "flutter-analyze-errors" bash -lc \
    "cd '$root_dir/app' && flutter analyze --no-fatal-infos --no-fatal-warnings"
fi

if [[ "${QA_SKIP_CONTROL_PANEL:-false}" != "true" ]]; then
  run_logged "control-panel-tests" bash -lc \
    "cd '$root_dir/control-panel' && '$python_bin' manage.py test"
  run_logged "admin-control-plane-live" bash -lc \
    "cd '$root_dir' && ./backend/scripts/provision_local_operator.sh && LOCAL_OPERATOR_USERNAME=local_control_analyst LOCAL_OPERATOR_PASSWORD=LocalAnalyst123! LOCAL_OPERATOR_ROLE=analyst ./backend/scripts/provision_local_operator.sh && python3 qa/admin/admin_control_plane_acceptance.py"
fi

export QA_API_BASE_URL="${QA_API_BASE_URL:-http://127.0.0.1:18080/v1}"
export QA_BFF_HEALTH_URL="${QA_BFF_HEALTH_URL:-http://127.0.0.1:18081/healthz}"
run_logged "native-postgres-qa-viewer" \
  "$root_dir/backend/scripts/provision_local_qa_viewer.sh"
run_logged "native-postgres-api-preflight" bash -lc \
  "cd '$root_dir/qa/appium' && '$python_bin' -m pytest tests/test_00_seed_preflight.py -m seed -q"

if [[ "${QA_SKIP_RELIABILITY_BURST:-false}" != "true" ]]; then
  run_logged "native-postgres-reliability" bash -lc \
    "cd '$root_dir' && PYTHON_BIN='$python_bin' QA_RELIABILITY_PROFILE=smoke ./qa/reliability/run_local_reliability_gate.sh"
fi

if [[ "${QA_RUN_DEVICE:-false}" == "true" ]]; then
  run_logged "android-core-journey" bash -lc \
    "cd '$root_dir/qa/appium' && QA_SKIP_DEPENDENCY_INSTALL='${QA_SKIP_DEPENDENCY_INSTALL:-true}' ./run_full_android_automation.sh release"
fi

say "Release regression passed"
echo "Reports: $report_dir"
