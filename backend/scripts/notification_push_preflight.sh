#!/usr/bin/env bash
set -euo pipefail

provider="${NOTIFICATION_PUSH_PROVIDER:-disabled}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"

case "$provider" in
  direct)
    fcm_file="${NOTIFICATION_FCM_CREDENTIALS_FILE:-${GOOGLE_APPLICATION_CREDENTIALS:-}}"
    apns_file="${NOTIFICATION_APNS_PRIVATE_KEY_FILE:-}"
    fcm_ready=false
    apns_ready=false
    if [[ -n "${NOTIFICATION_FCM_PROJECT_ID:-}" && -f "$fcm_file" ]]; then
      fcm_ready=true
    fi
    if [[ -n "${NOTIFICATION_APNS_TEAM_ID:-}" && \
          -n "${NOTIFICATION_APNS_KEY_ID:-}" && \
          -n "${NOTIFICATION_APNS_BUNDLE_ID:-}" && \
          -f "$apns_file" ]]; then
      apns_ready=true
    fi
    if [[ "$fcm_ready" != true && "$apns_ready" != true ]]; then
      echo "direct push has no complete FCM or APNs credential set" >&2
      exit 1
    fi
    echo "direct push credentials: fcm=$fcm_ready apns=$apns_ready"
    ;;
  webhook)
    if [[ -z "${NOTIFICATION_PUSH_WEBHOOK_URL:-}" ]]; then
      echo "webhook push URL is missing" >&2
      exit 1
    fi
    echo "webhook push endpoint configured"
    ;;
  *)
    echo "NOTIFICATION_PUSH_PROVIDER must be direct or webhook" >&2
    exit 1
    ;;
esac

$psql_bin "$database_url" -X -v ON_ERROR_STOP=1 -c '
  SELECT provider, platform, COUNT(*) AS enabled_tokens,
         MAX(last_seen_at) AS newest_registration
  FROM user_management.device_push_tokens
  WHERE enabled
  GROUP BY provider, platform
  ORDER BY provider, platform;
'

"$(dirname "$0")/notification_queue_slo_check.sh"
