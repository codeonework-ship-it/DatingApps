#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
api_base="${MEDIA_API_BASE_URL:-http://127.0.0.1:18081/v1}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
operator_username="${LOCAL_OPERATOR_USERNAME:-local_control_admin}"
operator_password="${LOCAL_OPERATOR_PASSWORD:-LocalAdmin123!}"

case "$api_base|$database_url" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "Local media verification only accepts loopback services." >&2; exit 2 ;;
esac
[[ "$api_base|$database_url" != *supabase* ]] || { echo "Supabase is forbidden." >&2; exit 2; }

lifecycle_json="$("$script_dir/verify_profile_media_lifecycle.sh")"
user_id="$(jq -er '.user_id' <<<"$lifecycle_json")"
username="$(jq -er '.username' <<<"$lifecycle_json")"
password="${MEDIA_TEST_PASSWORD:-Password123!}"

login_json="$(curl --fail-with-body -sS -X POST "$api_base/auth/login" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")"
user_token="$(jq -er '.access_token' <<<"$login_json")"
draft_json="$(curl --fail-with-body -sS "$api_base/profile/$user_id/draft" \
  -H "Authorization: Bearer $user_token")"
photo_id="$(jq -er '.draft.photos[0].id' <<<"$draft_json")"
photo_url="$(jq -er '.draft.photos[0].photo_url' <<<"$draft_json")"

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -v photo_id="$photo_id" <<'SQL' >/dev/null
UPDATE user_management.photos
SET moderation_status='review_required',moderation_reason='local_acceptance_review'
WHERE id=:'photo_id'::uuid;
SQL

public_before="$(curl -sS -o /dev/null -w '%{http_code}' "$photo_url")"
if [[ "$public_before" != "404" ]]; then
  echo "quarantined media unexpectedly returned HTTP $public_before" >&2
  exit 1
fi

LOCAL_OPERATOR_USERNAME="$operator_username" LOCAL_OPERATOR_PASSWORD="$operator_password" \
  "$script_dir/provision_local_operator.sh" >/dev/null
operator_login="$(curl --fail-with-body -sS -X POST "$api_base/auth/login" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$operator_username\",\"password\":\"$operator_password\"}")"
operator_token="$(jq -er '.access_token' <<<"$operator_login")"

content_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  "$api_base/admin/moderation/media/$photo_id/content" \
  -H "Authorization: Bearer $operator_token")"
if [[ "$content_status" != "200" ]]; then
  echo "operator media content returned HTTP $content_status" >&2
  exit 1
fi

decision_json="$(curl --fail-with-body -sS -X POST \
  "$api_base/admin/moderation/media/$photo_id/decision" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $operator_token" \
  -H "Idempotency-Key: local-media-approve-$photo_id" \
  --data '{"decision":"approved","reason":"local acceptance review passed"}')"
jq -e '.item.status == "approved"' <<<"$decision_json" >/dev/null

public_after="$(curl -sS -o /dev/null -w '%{http_code}' "$photo_url")"
if [[ "$public_after" != "200" ]]; then
  echo "approved media returned HTTP $public_after" >&2
  exit 1
fi

event_count="$("$psql_bin" "$database_url" -X -Atq -v photo_id="$photo_id" <<'SQL'
SELECT COUNT(*)
FROM user_management.media_moderation_events
WHERE photo_id=:'photo_id'::uuid;
SQL
)"
[[ "$event_count" -ge 2 ]]

jq -n \
  --arg user_id "$user_id" \
  --arg photo_id "$photo_id" \
  --arg public_before "$public_before" \
  --arg content_status "$content_status" \
  --arg public_after "$public_after" \
  --argjson event_count "$event_count" \
  '{success:true,user_id:$user_id,photo_id:$photo_id,public_while_quarantined:$public_before,operator_content:$content_status,public_after_approval:$public_after,audit_events:$event_count}'
