#!/usr/bin/env bash
set -euo pipefail

api_base="${OPERATOR_API_BASE_URL:-http://127.0.0.1:18081/v1}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
username="${LOCAL_OPERATOR_USERNAME:-local_control_admin}"
password="${LOCAL_OPERATOR_PASSWORD:-LocalAdmin123!}"
role="${LOCAL_OPERATOR_ROLE:-admin}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

case "$api_base|$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Local operator provisioning only accepts loopback API/database URLs." >&2; exit 2 ;;
esac
if [[ "$api_base|$database_url" == *supabase* ]]; then
  echo "Supabase connections are forbidden for local operator provisioning." >&2
  exit 2
fi
case "$role" in
  admin|ops_admin|trust_safety|analyst|moderator|finance) ;;
  *) echo "Unsupported operator role: $role" >&2; exit 2 ;;
esac
if [[ ! "$username" =~ ^[A-Za-z0-9][A-Za-z0-9._]{1,28}[A-Za-z0-9]$ ]]; then
  echo "LOCAL_OPERATOR_USERNAME must be 3-30 letters, numbers, dots, or underscores." >&2
  exit 2
fi
if [[ "$password" == *'"'* || "$password" == *'\'* || "$password" == *$'\n'* || "$password" == *$'\r'* ]]; then
  echo "LOCAL_OPERATOR_PASSWORD cannot contain quotes, backslashes, or newlines." >&2
  exit 2
fi

user_id="$($psql_bin "$database_url" -X -Atq -v operator_username="$username" <<'SQL'
SELECT user_id
FROM user_management.auth_credentials
WHERE lower(username) = lower(:'operator_username')
LIMIT 1;
SQL
)"
if [[ -z "$user_id" ]]; then
  signup_status="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$api_base/auth/signup" \
    -H 'Content-Type: application/json' \
    --data "{\"username\":\"$username\",\"password\":\"$password\"}")"
  case "$signup_status" in
    200|201) ;;
    *) echo "Operator signup failed with HTTP $signup_status" >&2; exit 1 ;;
  esac
  user_id="$($psql_bin "$database_url" -X -Atq -v operator_username="$username" <<'SQL'
SELECT user_id
FROM user_management.auth_credentials
WHERE lower(username) = lower(:'operator_username')
LIMIT 1;
SQL
)"
fi

if [[ -z "$user_id" ]]; then
  echo "Operator credential row was not created." >&2
  exit 1
fi

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -v operator_id="$user_id" -v operator_role="$role" <<'SQL' >/dev/null
INSERT INTO user_management.users
  (id, username, name, date_of_birth, gender, profile_completion, is_active)
SELECT c.user_id, c.username, 'Local Control Operator', DATE '1990-01-01', 'other', 0, TRUE
FROM user_management.auth_credentials c
WHERE c.user_id = :'operator_id'::uuid
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_management.auth_account_roles(user_id, role, granted_by)
VALUES (:'operator_id'::uuid, :'operator_role', :'operator_id'::uuid)
ON CONFLICT (user_id, role) DO NOTHING;
SQL

login_json="$(curl -sS -X POST "$api_base/auth/login" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")"
if [[ "$login_json" != *'"success":true'* || "$login_json" != *'"access_token"'* ]]; then
  echo "Provisioned operator login was rejected; check LOCAL_OPERATOR_PASSWORD." >&2
  exit 1
fi

echo "local operator ready: username=$username role=$role user_id=$user_id"
