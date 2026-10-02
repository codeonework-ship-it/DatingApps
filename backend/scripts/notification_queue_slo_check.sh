#!/usr/bin/env bash
set -euo pipefail

psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
max_depth="${NOTIFICATION_SLO_MAX_QUEUE_DEPTH:-1000}"
max_age="${NOTIFICATION_SLO_MAX_OLDEST_AGE_SEC:-30}"
min_success="${NOTIFICATION_SLO_MIN_SUCCESS_PCT:-99}"
max_p95_ms="${NOTIFICATION_SLO_MAX_PUSH_P95_MS:-10000}"

row="$($psql_bin "$database_url" -X -AtF '|' -v ON_ERROR_STOP=1 -c '
  SELECT queue_depth, oldest_pending_age_seconds, push_attempts_15m,
         push_delivered_15m, push_dead_letter_15m,
         push_success_percent_15m, push_p95_latency_ms_15m
  FROM matching.notification_queue_metrics;
')"

IFS='|' read -r depth age attempts delivered dead_letters success p95_ms <<<"$row"

echo "queue_depth=$depth max=$max_depth"
echo "oldest_pending_age_seconds=$age max=$max_age"
echo "push_attempts_15m=$attempts delivered=$delivered dead_letters=$dead_letters"
echo "push_success_percent_15m=$success min=$min_success"
echo "push_p95_latency_ms_15m=$p95_ms max=$max_p95_ms"

if (( depth > max_depth || age > max_age )); then
  echo "notification queue SLO failed" >&2
  exit 1
fi

# With no delivery attempts the metrics view reports 100% success, so the
# success check below passes without a single push having been sent. The
# latency check already guards on attempts; the success check did not, which
# made a no-traffic run print the same "passed" line as a proven SLO — and the
# acceptance procedure attaches this output to the release record as evidence.
#
# Depth and age stay meaningful with an empty queue, so a no-traffic run is
# still a legitimate CI gate. It just must not claim the push SLOs were proven.
# Set NOTIFICATION_SLO_REQUIRE_TRAFFIC=true for the acceptance runs after the
# device matrix and the production-shaped burst, where absence of traffic means
# the run itself did not happen.
require_traffic="${NOTIFICATION_SLO_REQUIRE_TRAFFIC:-false}"

if (( attempts == 0 )); then
  if [[ "$require_traffic" == true ]]; then
    echo "notification push SLO not proven: no delivery attempts in the window" >&2
    exit 1
  fi
  echo "queue depth and age SLOs passed"
  echo "push success and latency SLOs NOT PROVEN: no delivery attempts in the window"
  exit 0
fi

if ! awk -v actual="$success" -v minimum="$min_success" \
  'BEGIN { exit !(actual >= minimum) }'; then
  echo "notification push success SLO failed" >&2
  exit 1
fi

if ! awk -v actual="$p95_ms" -v maximum="$max_p95_ms" \
  'BEGIN { exit !(actual <= maximum) }'; then
  echo "notification push latency SLO failed" >&2
  exit 1
fi

echo "notification queue SLO passed"
