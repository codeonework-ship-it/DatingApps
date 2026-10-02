#!/usr/bin/env bash
set -euo pipefail

api_base="${SIGNUP_API_BASE_URL:-http://127.0.0.1:18081/v1}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
username="${QA_EXISTING_USERNAME:-workflow_qa_20260803_final}"
password="${QA_EXISTING_PASSWORD:-Password123!}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$api_base|$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "QA viewer provisioning only accepts loopback services." >&2; exit 2 ;;
esac
[[ "$api_base|$database_url" != *supabase* ]] || { echo "Supabase is forbidden." >&2; exit 2; }

login_json="$(curl -sS -X POST "$api_base/auth/login" -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")"
if [[ "$login_json" != *'"success":true'* ]]; then
  exists="$($psql_bin "$database_url" -X -Atq -v qa_username="$username" <<'SQL'
SELECT EXISTS (
  SELECT 1 FROM user_management.auth_credentials WHERE username = :'qa_username'
);
SQL
)"
  if [[ "$exists" == "t" ]]; then
    echo "QA viewer exists but its configured password was rejected." >&2
    exit 1
  fi
  SIGNUP_API_BASE_URL="$api_base" SIGNUP_TEST_USERNAME="$username" \
    SIGNUP_TEST_PASSWORD="$password" "$script_dir/verify_signup_workflow.sh" >/dev/null
fi

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -v qa_username="$username" <<'SQL' >/dev/null
WITH viewer AS (
  SELECT id FROM user_management.users WHERE username = :'qa_username'
), candidate AS (
  SELECT id FROM user_management.users
  WHERE id <> (SELECT id FROM viewer) AND is_active AND NOT is_banned
  ORDER BY created_at
  LIMIT 1
)
INSERT INTO matching.matches(user_id_1, user_id_2)
SELECT LEAST(viewer.id, candidate.id), GREATEST(viewer.id, candidate.id)
FROM viewer, candidate
WHERE NOT EXISTS (
  SELECT 1 FROM matching.matches m
  WHERE (m.user_id_1 = viewer.id OR m.user_id_2 = viewer.id)
    AND m.unmatched_at IS NULL
)
ON CONFLICT DO NOTHING;
SQL

echo "local QA viewer ready: username=$username"
