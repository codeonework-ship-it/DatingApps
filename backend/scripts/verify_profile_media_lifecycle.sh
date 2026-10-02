#!/usr/bin/env bash
set -euo pipefail

api_base="${MEDIA_API_BASE_URL:-http://127.0.0.1:18081/v1}"
username="${MEDIA_TEST_USERNAME:-media_qa_$(date +%Y%m%d%H%M%S)}"
password="${MEDIA_TEST_PASSWORD:-Password123!}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"

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

signup_json=$(curl --fail-with-body -sS -X POST "$api_base/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"$username\",\"password\":\"$password\"}")
user_id=$(jq -er '.user_id' <<<"$signup_json")
access_token=$(jq -er '.access_token' <<<"$signup_json")
auth_header="Authorization: Bearer $access_token"

curl --fail-with-body -sS -X POST "$api_base/auth/signup/bootstrap" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data "{\"user_id\":\"$user_id\",\"username\":\"$username\",\"name\":\"Media QA\",\"date_of_birth\":\"1994-08-03\",\"gender\":\"F\"}" >/dev/null
curl --fail-with-body -sS -X PATCH "$api_base/users/$user_id/agreements/terms" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data '{"accepted":true,"terms_version":"v1"}' >/dev/null
curl --fail-with-body -sS -X PATCH "$api_base/profile/$user_id/draft" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data '{"bio":"Media lifecycle verification profile with a complete durable draft.","seeking_genders":["M"],"min_age_years":25,"max_age_years":42,"max_distance_km":80}' >/dev/null

metadata_only_code=$(curl -sS -o "$fixture_dir/metadata-only.json" -w '%{http_code}' \
  -X POST "$api_base/profile/$user_id/photos" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data '{"photo_url":"https://untrusted.example/photo.jpg"}')
[[ "$metadata_only_code" == "415" ]]

for photo_number in 1 2 3 4 5; do
  curl --fail-with-body -sS -X POST "$api_base/profile/$user_id/photos" \
    -H "$auth_header" \
    -F "image=@$fixture_dir/photo.png;filename=photo-$photo_number.png;type=image/png" >/dev/null
done

quota_code=$(curl -sS -o "$fixture_dir/quota.json" -w '%{http_code}' \
  -X POST "$api_base/profile/$user_id/photos" -H "$auth_header" \
  -F "image=@$fixture_dir/photo.png;filename=photo-6.png;type=image/png")
[[ "$quota_code" == "409" ]]

draft_json=$(curl --fail-with-body -sS "$api_base/profile/$user_id/draft" -H "$auth_header")
reversed_ids=$(jq -cer '.draft.photos | map(.id) | reverse' <<<"$draft_json")
expected_primary=$(jq -er '.[0]' <<<"$reversed_ids")
reordered_json=$(curl --fail-with-body -sS -X POST "$api_base/profile/$user_id/photos/reorder" \
  -H 'Content-Type: application/json' -H "$auth_header" \
  --data "{\"photo_ids\":$reversed_ids}")
jq -e --arg expected "$expected_primary" \
  '.draft.photos[0].id == $expected' <<<"$reordered_json" >/dev/null

delete_id=$(jq -er '.draft.photos[-1].id' <<<"$reordered_json")
deleted_json=$(curl --fail-with-body -sS -X DELETE \
  "$api_base/profile/$user_id/photos/$delete_id" -H "$auth_header")
jq -e '.draft.photos | length == 4' <<<"$deleted_json" >/dev/null

curl --fail-with-body -sS -X POST "$api_base/profile/$user_id/complete" \
  -H "$auth_header" >/dev/null
resumed_json=$(curl --fail-with-body -sS "$api_base/profile/$user_id/draft" -H "$auth_header")
jq -e --arg expected "$expected_primary" \
  '.draft.photos | length == 4 and .[0].id == $expected' <<<"$resumed_json" >/dev/null

db_summary=$("$psql_bin" "$database_url" -X -At -F '|' -c "
  SELECT COUNT(*),COUNT(width_px),COUNT(height_px),COUNT(mime_type),
         COUNT(size_bytes),COUNT(content_sha256)
  FROM user_management.photos
  WHERE user_id='$user_id' AND deleted_at IS NULL")
[[ "$db_summary" == "4|4|4|4|4|4" ]]
retention_count=$("$psql_bin" "$database_url" -X -At -c "
  SELECT COUNT(*) FROM user_management.profile_drafts
  WHERE user_id='$user_id' AND completed_at IS NOT NULL
    AND retained_until BETWEEN NOW()+INTERVAL '29 days' AND NOW()+INTERVAL '31 days'")
[[ "$retention_count" == "1" ]]

jq -n --arg user_id "$user_id" --arg username "$username" \
  '{success:true,user_id:$user_id,username:$username,active_photos:4,metadata_only_status:415,quota_status:409,reorder:true,delete:true,resume:true,retention_days:30}'
