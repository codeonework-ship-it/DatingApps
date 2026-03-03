#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
LOG_DIR="$RUN_DIR/logs"
PID_FILE="$RUN_DIR/pids"
mkdir -p "$LOG_DIR"

if [[ -f "$ROOT_DIR/config/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/config/.env"
elif [[ -f "$ROOT_DIR/config/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/config/.env.local"
fi

: "${ENVIRONMENT:=development}"
: "${LOG_LEVEL:=debug}"
: "${API_GATEWAY_ADDR:=:8080}"
: "${MOBILE_BFF_ADDR:=:8081}"
: "${AUTH_SVC_GRPC_ADDR:=:9091}"
: "${PROFILE_SVC_GRPC_ADDR:=:9092}"
: "${MATCHING_SVC_GRPC_ADDR:=:9093}"
: "${CHAT_SVC_GRPC_ADDR:=:9094}"
: "${AUTH_SVC_ADMIN_ADDR:=:10091}"
: "${PROFILE_SVC_ADMIN_ADDR:=:10092}"
: "${MATCHING_SVC_ADMIN_ADDR:=:10093}"
: "${CHAT_SVC_ADMIN_ADDR:=:10094}"
: "${MOCK_OTP_ENABLED:=true}"
: "${SUPABASE_DB_HOST:=}"
: "${SUPABASE_DB_PORT:=5432}"
: "${SUPABASE_DB_NAME:=postgres}"
: "${SUPABASE_DB_USER:=postgres}"
: "${SUPABASE_DB_PASSWORD:=}"
: "${SUPABASE_DB_SSLMODE:=require}"
: "${SUPABASE_URL:=}"
: "${SUPABASE_ANON_KEY:=}"
: "${SUPABASE_SERVICE_ROLE:=}"
: "${SUPABASE_USER_SCHEMA:=user_management}"
: "${SUPABASE_USERS_TABLE:=users}"
: "${SUPABASE_PREFERENCES_TABLE:=preferences}"
: "${SUPABASE_PHOTOS_TABLE:=photos}"
: "${SUPABASE_MATCHING_SCHEMA:=matching}"
: "${SUPABASE_SWIPES_TABLE:=swipes}"
: "${SUPABASE_MATCHES_TABLE:=matches}"
: "${SUPABASE_MESSAGES_TABLE:=messages}"
: "${SUPABASE_ENGAGEMENT_SCHEMA:=matching}"
: "${SUPABASE_UNLOCK_STATES_TABLE:=match_unlock_states}"
: "${SUPABASE_QUEST_TEMPLATES_TABLE:=match_quest_templates}"
: "${SUPABASE_QUEST_WORKFLOWS_TABLE:=match_quest_workflows}"
: "${SUPABASE_GESTURES_TABLE:=match_gestures}"
: "${GESTURE_MIN_CONTENT_CHARS:=40}"
: "${GESTURE_MIN_WORD_COUNT:=8}"
: "${GESTURE_ORIGINALITY_PERCENT:=65}"
: "${GESTURE_PROFANITY_TOKENS:=fuck,shit,bitch,asshole,bastard,slut}"
: "${DATABASE_URL:=}"
: "${MOCK_USER_ID:=mock-user-001}"
: "${MOCK_ACCESS_TOKEN:=mock-access-token}"
: "${MOCK_REFRESH_TOKEN:=mock-refresh-token}"

if [[ ( -z "${SUPABASE_URL}" || "${SUPABASE_URL}" == *"example.supabase.co"* ) && -n "${SUPABASE_DB_HOST}" ]]; then
  if [[ "${SUPABASE_DB_HOST}" =~ ^db\.([^.]+)\.supabase\.co$ ]]; then
    SUPABASE_URL="https://${BASH_REMATCH[1]}.supabase.co"
  fi
fi

if [[ -z "${DATABASE_URL}" && -n "${SUPABASE_DB_HOST}" ]]; then
  if [[ -n "${SUPABASE_DB_PASSWORD}" ]]; then
    DATABASE_URL="postgresql://${SUPABASE_DB_USER}:${SUPABASE_DB_PASSWORD}@${SUPABASE_DB_HOST}:${SUPABASE_DB_PORT}/${SUPABASE_DB_NAME}?sslmode=${SUPABASE_DB_SSLMODE}"
  else
    DATABASE_URL="postgresql://${SUPABASE_DB_USER}@${SUPABASE_DB_HOST}:${SUPABASE_DB_PORT}/${SUPABASE_DB_NAME}?sslmode=${SUPABASE_DB_SSLMODE}"
  fi
fi

export ENVIRONMENT LOG_LEVEL API_GATEWAY_ADDR MOBILE_BFF_ADDR \
  AUTH_SVC_GRPC_ADDR PROFILE_SVC_GRPC_ADDR MATCHING_SVC_GRPC_ADDR CHAT_SVC_GRPC_ADDR \
  AUTH_SVC_ADMIN_ADDR PROFILE_SVC_ADMIN_ADDR MATCHING_SVC_ADMIN_ADDR CHAT_SVC_ADMIN_ADDR \
  MOCK_OTP_ENABLED SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE \
  SUPABASE_USER_SCHEMA SUPABASE_USERS_TABLE SUPABASE_PREFERENCES_TABLE SUPABASE_PHOTOS_TABLE \
  SUPABASE_MATCHING_SCHEMA SUPABASE_SWIPES_TABLE SUPABASE_MATCHES_TABLE SUPABASE_MESSAGES_TABLE \
  SUPABASE_ENGAGEMENT_SCHEMA SUPABASE_UNLOCK_STATES_TABLE SUPABASE_QUEST_TEMPLATES_TABLE SUPABASE_QUEST_WORKFLOWS_TABLE SUPABASE_GESTURES_TABLE \
  GESTURE_MIN_CONTENT_CHARS GESTURE_MIN_WORD_COUNT GESTURE_ORIGINALITY_PERCENT GESTURE_PROFANITY_TOKENS \
  MOCK_USER_ID MOCK_ACCESS_TOKEN MOCK_REFRESH_TOKEN \
  SUPABASE_DB_HOST SUPABASE_DB_PORT SUPABASE_DB_NAME SUPABASE_DB_USER SUPABASE_DB_PASSWORD SUPABASE_DB_SSLMODE \
  DATABASE_URL

if [[ -z "${SUPABASE_URL}" ]]; then
  echo "ERROR: SUPABASE_URL is empty. Set SUPABASE_URL directly or provide SUPABASE_DB_HOST (db.<project-ref>.supabase.co)." >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  rm -f "$PID_FILE"
fi

run_service() {
  local name="$1"
  local cmd="$2"
  local log_file="$LOG_DIR/$name.log"
  (
    cd "$ROOT_DIR"
    nohup bash -c "$cmd" >"$log_file" 2>&1 &
    echo "$! $name" >>"$PID_FILE"
  )
}

run_service "auth-svc" "go run ./cmd/auth-svc"
run_service "profile-svc" "go run ./cmd/profile-svc"
run_service "matching-svc" "go run ./cmd/matching-svc"
run_service "chat-svc" "go run ./cmd/chat-svc"
run_service "mobile-bff" "go run ./cmd/mobile-bff"
run_service "api-gateway" "go run ./cmd/api-gateway"

echo "Started services. Logs: $LOG_DIR"
echo "PIDs:"
cat "$PID_FILE"

sleep 3
echo
echo "Gateway:"
echo "  Health:  http://localhost:8080/healthz"
echo "  Ready:   http://localhost:8080/readyz"
echo "  Metrics: http://localhost:8080/metrics"
echo "  Docs:    http://localhost:8080/docs"
echo "  OpenAPI: http://localhost:8080/openapi.yaml"
echo
echo "Service Admin Endpoints:"
echo "  Auth:     http://localhost:10091/healthz"
echo "  Profile:  http://localhost:10092/healthz"
echo "  Matching: http://localhost:10093/healthz"
echo "  Chat:     http://localhost:10094/healthz"

if [[ "${OPEN_CHROME:-false}" == "true" ]]; then
  if command -v open >/dev/null 2>&1; then
    open -a "Google Chrome" "http://localhost:8080/docs" || true
  fi
fi
