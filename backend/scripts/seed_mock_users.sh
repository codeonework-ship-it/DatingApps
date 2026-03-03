#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
TOTAL_USERS="${TOTAL_USERS:-100}"

if ! [[ "$TOTAL_USERS" =~ ^[0-9]+$ ]] || [ "$TOTAL_USERS" -lt 2 ]; then
  echo "TOTAL_USERS must be an integer >= 2"
  exit 1
fi

MEN_COUNT=$((TOTAL_USERS / 2))
WOMEN_COUNT=$((TOTAL_USERS - MEN_COUNT))

men_names=(
  Aarav Vivaan Aditya Arjun Sai Krishna Rahul Karthik Nikhil Rohan
  Sandeep Varun Akash Harish Pranav Tejas Vikas Yash Manish Dev
)

women_names=(
  Ananya Diya Isha Kavya Meera Nisha Priya Riya Sneha Tanya
  Aditi Pooja Neha Shreya Nandini Aisha Sanjana Trisha Mahi Divya
)

bios=(
  "Love long drives and coffee chats."
  "Weekend trekker, weekday problem solver."
  "Foodie who can cook a great biryani."
  "Books, music, and meaningful conversations."
  "Fitness enthusiast with a soft spot for dogs."
  "Traveling across India one city at a time."
  "Early riser, gym regular, and chai fan."
  "Startup mindset with old-school values."
  "Movie buff who enjoys beach sunsets."
  "Looking for genuine connection and laughter."
)

professions=(
  "Software Engineer"
  "Product Manager"
  "Designer"
  "Doctor"
  "Teacher"
  "Consultant"
  "Marketing Specialist"
  "Data Analyst"
  "Architect"
  "Entrepreneur"
)

educations=(
  "B.Tech"
  "MBA"
  "M.Tech"
  "B.Com"
  "B.Sc"
  "M.Sc"
  "MBBS"
  "BA"
  "BBA"
  "PhD"
)

random_item() {
  local count=$#
  local pick=$((1 + RANDOM % count))
  printf '%s\n' "${!pick}"
}

random_dob() {
  local year=$((1988 + RANDOM % 13))
  local month=$((1 + RANDOM % 12))
  local day=$((1 + RANDOM % 28))
  printf "%04d-%02d-%02d" "$year" "$month" "$day"
}

random_phone() {
  local n=""
  for _ in {1..10}; do
    n+=$((RANDOM % 10))
  done
  echo "seed-$n"
}

upsert_user() {
  local user_id=$1
  local name=$2
  local gender=$3
  local dob=$4
  local bio=$5
  local profession=$6
  local education=$7
  local phone=$8

  local payload
  payload=$(cat <<JSON
{"profile":{"id":"$user_id","name":"$name","gender":"$gender","dateOfBirth":"$dob","bio":"$bio","profession":"$profession","education":"$education","phoneNumber":"$phone","isActive":true,"isVerified":false}}
JSON
)

  local status
  status=$(curl -sS -o /tmp/seed_profile_upsert.json -w "%{http_code}" -X PUT "$API_BASE_URL/v1/profile/$user_id" \
    -H "content-type: application/json" \
    --data "$payload")

  if [ "$status" != "200" ]; then
    echo "Upsert failed for $user_id (status=$status)"
    cat /tmp/seed_profile_upsert.json
    echo
    exit 1
  fi
}

printf "Seeding %d users (men=%d, women=%d) into %s\n" "$TOTAL_USERS" "$MEN_COUNT" "$WOMEN_COUNT" "$API_BASE_URL"

for ((i=1; i<=MEN_COUNT; i++)); do
  user_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  name="SeedM$(printf '%03d' "$i") $(random_item "${men_names[@]}")"
  upsert_user \
    "$user_id" \
    "$name" \
    "M" \
    "$(random_dob)" \
    "$(random_item "${bios[@]}")" \
    "$(random_item "${professions[@]}")" \
    "$(random_item "${educations[@]}")" \
    "$(random_phone)"
done

for ((i=1; i<=WOMEN_COUNT; i++)); do
  user_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  name="SeedW$(printf '%03d' "$i") $(random_item "${women_names[@]}")"
  upsert_user \
    "$user_id" \
    "$name" \
    "F" \
    "$(random_dob)" \
    "$(random_item "${bios[@]}")" \
    "$(random_item "${professions[@]}")" \
    "$(random_item "${educations[@]}")" \
    "$(random_phone)"
done

echo "Seed complete."
echo "Example check: curl -sS '$API_BASE_URL/v1/discovery/<your-user-id>?limit=100'"
