#!/usr/bin/env bash
set -euo pipefail

api_base="${SIGNUP_API_BASE_URL:-http://127.0.0.1:18081/v1}"
username="${SIGNUP_TEST_USERNAME:-workflow_qa}"
password="${SIGNUP_TEST_PASSWORD:-Password123!}"

signup_json=$(curl --fail-with-body -sS -X POST "$api_base/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")
user_id=$(jq -er '.user_id' <<<"$signup_json")
access_token=$(jq -er '.access_token' <<<"$signup_json")

auth_header="Authorization: Bearer $access_token"

curl --fail-with-body -sS -X POST "$api_base/auth/signup/bootstrap" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data "{\"user_id\":\"$user_id\",\"username\":\"$username\",\"name\":\"Workflow QA\",\"date_of_birth\":\"1994-08-03\",\"gender\":\"F\"}" >/dev/null

curl --fail-with-body -sS -X PATCH "$api_base/users/$user_id/agreements/terms" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data '{"accepted":true,"terms_version":"v1"}' >/dev/null

# Intent tags make the member discoverable (OBS-01): every member's deck
# defaults to "serious relationship only", which drops candidates without a
# serious intent tag, and intent is optional in onboarding. Set them before
# /complete, which publishes the profile; later edits need a re-publish.
curl --fail-with-body -sS -X PATCH "$api_base/profile/$user_id/draft" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data '{"bio":"Curious architect who enjoys hiking and thoughtful conversations.","seeking_genders":["M"],"min_age_years":25,"max_age_years":42,"max_distance_km":80,"intent_tags":["long_term"]}' >/dev/null

fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT
python3 - "$fixture_dir/photo.png" <<'PY'
import binascii
import struct
import sys
import zlib

width = height = 320
raw = b''.join(b'\x00' + (b'\x31\x78\xc6' * width) for _ in range(height))

def chunk(kind, payload):
    return (struct.pack('>I', len(payload)) + kind + payload +
            struct.pack('>I', binascii.crc32(kind + payload) & 0xffffffff))

png = (b'\x89PNG\r\n\x1a\n' +
       chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
       chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
with open(sys.argv[1], 'wb') as output:
    output.write(png)
PY

for photo_number in 1 2; do
  curl --fail-with-body -sS -X POST "$api_base/profile/$user_id/photos" \
    -H "$auth_header" \
    -F "image=@$fixture_dir/photo.png;filename=photo-$photo_number.png;type=image/png" >/dev/null
done

curl --fail-with-body -sS -X POST "$api_base/profile/$user_id/complete" \
  -H 'Content-Type: application/json' -H "$auth_header" >/dev/null

workflow_json=$(curl --fail-with-body -sS "$api_base/auth/signup/workflow/$user_id" -H "$auth_header")
login_json=$(curl --fail-with-body -sS -X POST "$api_base/auth/login" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")

jq -e '.state == "completed" and .current_activity == "done" and .signup_required == false' \
  <<<"$workflow_json" >/dev/null
jq -e '.success == true and .workflow_state == "completed" and .signup_required == false' \
  <<<"$login_json" >/dev/null

# OBS-01: the member must carry a serious intent tag or nobody's default deck
# ("serious relationship only") will show them.
draft_json=$(curl --fail-with-body -sS "$api_base/profile/$user_id/draft" -H "$auth_header")
jq -e '[.. | objects | .intent_tags? // empty | .[]?] | index("long_term") != null' \
  <<<"$draft_json" >/dev/null

jq -n --arg user_id "$user_id" --arg username "$username" \
  '{success:true,user_id:$user_id,username:$username,workflow_state:"completed",signup_required:false}'
