#!/usr/bin/env bash
set -euo pipefail

api_base="${PROGRESSION_API_BASE_URL:-http://127.0.0.1:18081/v1}"
database_url="${DATABASE_URL:-postgresql://dating_app@127.0.0.1:55432/dating_app?sslmode=disable}"
psql_bin="${POSTGRES_BIN_DIR:-/opt/homebrew/opt/postgresql@17/bin}/psql"
operator_username="${PROGRESSION_OPERATOR_USERNAME:-local_control_admin}"
operator_password="${PROGRESSION_OPERATOR_PASSWORD:-LocalAdmin123!}"
member_password="${PROGRESSION_MEMBER_PASSWORD:-Password123!}"
member_username="level_qa_$(date +%s)_$RANDOM"

signup_json=$(curl --fail-with-body -sS -X POST "$api_base/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$member_username\",\"password\":\"$member_password\"}")
user_id=$(jq -er '.user_id' <<<"$signup_json")
member_token=$(jq -er '.access_token' <<<"$signup_json")

curl --fail-with-body -sS -X POST "$api_base/auth/signup/bootstrap" \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $member_token" \
  -H "Idempotency-Key: bootstrap-$user_id" \
  --data "{\"user_id\":\"$user_id\",\"username\":\"$member_username\",\"name\":\"Level QA\",\"date_of_birth\":\"1994-08-09\",\"gender\":\"F\"}" >/dev/null

operator_json=$(curl --fail-with-body -sS -X POST "$api_base/auth/login" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$operator_username\",\"password\":\"$operator_password\"}")
operator_token=$(jq -er '.access_token' <<<"$operator_json")

member_auth="Authorization: Bearer $member_token"
operator_auth="Authorization: Bearer $operator_token"

initial=$(curl --fail-with-body -sS "$api_base/progression/$user_id" -H "$member_auth")
jq -e '.progression.current_level == 1 and .progression.total_xp == 0 and (.progression.levels|length) == 10' \
  <<<"$initial" >/dev/null

award_key="level-e2e-award-$user_id"
award_payload='{"amount":100,"reason":"Local progression end-to-end verification"}'
first_award=$(curl --fail-with-body -sS -X POST "$api_base/admin/progression/users/$user_id/adjust-xp" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: $award_key" \
  --data "$award_payload")
replayed_award=$(curl --fail-with-body -sS -X POST "$api_base/admin/progression/users/$user_id/adjust-xp" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: $award_key" \
  --data "$award_payload")
jq -e '.award.awarded_xp == 100 and .award.event_id != null' <<<"$first_award" >/dev/null
test "$(jq -r '.award.event_id' <<<"$first_award")" = "$(jq -r '.award.event_id' <<<"$replayed_award")"

conflict_code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  "$api_base/admin/progression/users/$user_id/adjust-xp" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: $award_key" \
  --data '{"amount":99,"reason":"Different payload must be rejected safely"}')
test "$conflict_code" = "409"

for _ in $(seq 1 30); do
  state=$(curl --fail-with-body -sS "$api_base/progression/$user_id" -H "$member_auth")
  if jq -e '.progression.current_level == 2 and .progression.total_xp == 100' <<<"$state" >/dev/null; then
    break
  fi
  sleep 0.2
done
jq -e '.progression.current_level == 2 and .progression.total_xp == 100' <<<"$state" >/dev/null

claim_key="level-e2e-claim-$user_id"
claim_payload='{"reward_key":"starter_accent"}'
claim=$(curl --fail-with-body -sS -X POST "$api_base/progression/$user_id/rewards/claim" \
  -H 'Content-Type: application/json' -H "$member_auth" -H "Idempotency-Key: $claim_key" \
  --data "$claim_payload")
replayed_claim=$(curl --fail-with-body -sS -X POST "$api_base/progression/$user_id/rewards/claim" \
  -H 'Content-Type: application/json' -H "$member_auth" -H "Idempotency-Key: $claim_key" \
  --data "$claim_payload")
test "$(jq -r '.claim.id' <<<"$claim")" = "$(jq -r '.claim.id' <<<"$replayed_claim")"

curl --fail-with-body -sS -X PUT "$api_base/admin/progression/users/$user_id/control" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: freeze-$user_id" \
  --data '{"progression_frozen":true,"risk_multiplier":1,"reason":"E2E safety freeze"}' >/dev/null
frozen=$(curl --fail-with-body -sS "$api_base/progression/$user_id" -H "$member_auth")
jq -e '.progression.progression_frozen == true' <<<"$frozen" >/dev/null

blocked_code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  "$api_base/admin/progression/users/$user_id/adjust-xp" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: frozen-award-$user_id" \
  --data '{"amount":10,"reason":"Frozen progression must reject this award"}')
test "$blocked_code" = "409"

curl --fail-with-body -sS -X PUT "$api_base/admin/progression/users/$user_id/control" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: unfreeze-$user_id" \
  --data '{"progression_frozen":false,"risk_multiplier":1,"reason":"E2E safety release"}' >/dev/null
curl --fail-with-body -sS -X POST "$api_base/admin/progression/users/$user_id/adjust-xp" \
  -H 'Content-Type: application/json' -H "$operator_auth" -H "Idempotency-Key: compensate-$user_id" \
  --data '{"amount":-100,"reason":"Compensating E2E verification adjustment"}' >/dev/null

ledger=$(curl --fail-with-body -sS "$api_base/progression/$user_id/ledger?limit=20" -H "$member_auth")
jq -e '[.entries[] | select(.source == "admin_adjustment")] | length == 2' <<<"$ledger" >/dev/null

ledger_count=$("$psql_bin" "$database_url" -Atqc "SELECT COUNT(*) FROM progression.xp_ledger WHERE user_id='$user_id' AND source='admin_adjustment'")
test "$ledger_count" = "2"

mutation_guard=$("$psql_bin" "$database_url" -Atqc "DO \$\$ BEGIN BEGIN UPDATE progression.xp_ledger SET awarded_xp=0 WHERE user_id='$user_id'; EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE 'xp_ledger is append-only%' THEN RAISE; END IF; END; END \$\$; SELECT COUNT(*) FROM progression.xp_ledger WHERE user_id='$user_id' AND awarded_xp=0;")
test "$mutation_guard" = "0"

jq -n --arg user_id "$user_id" --arg username "$member_username" \
  '{success:true,user_id:$user_id,username:$username,level_transition:"1->2",reward_claimed:"starter_accent",freeze_enforced:true,ledger_append_only:true}'
