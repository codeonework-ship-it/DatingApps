#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${SCALE_API_BASE_URLS:?SCALE_API_BASE_URLS must contain production-shaped targets}"
: "${SCALE_CHAOS_HOOK:?SCALE_CHAOS_HOOK must be an absolute executable path}"
: "${SCALE_RECOVERY_HOOK:?SCALE_RECOVERY_HOOK must be an absolute executable path}"

if [[ "${SCALE_ALLOW_CHAOS:-false}" != "true" ]]; then
  echo "Set SCALE_ALLOW_CHAOS=true only inside the approved test environment." >&2
  exit 2
fi
case "$SCALE_API_BASE_URLS" in
  *127.0.0.1*|*localhost*) echo "Production chaos gate refuses loopback targets." >&2; exit 2 ;;
esac
for hook in "$SCALE_CHAOS_HOOK" "$SCALE_RECOVERY_HOOK"; do
  [[ "$hook" = /* && -x "$hook" ]] || { echo "Hook is not an absolute executable: $hook" >&2; exit 2; }
done

report="${SCALE_CHAOS_REPORT:-$root_dir/qa/reports/reliability/production-chaos.json}"
# Money invariants (one debit, one gift send per idempotency key) are checked
# under chaos too; set SCALE_MONEY_STORM=false only if gifts are not enabled in
# the target environment, and record why in the evidence.
SCALE_MONEY_STORM="${SCALE_MONEY_STORM:-true}" python3 "$root_dir/qa/reliability/distributed_scale_gate.py" \
  --profile distributed-burst --report "$report" &
load_pid=$!
trap 'kill "$load_pid" 2>/dev/null || true' EXIT

sleep 30
"$SCALE_CHAOS_HOOK"
sleep "${SCALE_CHAOS_HOLD_SECONDS:-60}"
"$SCALE_RECOVERY_HOOK"
wait "$load_pid"
trap - EXIT

echo "Production failover/chaos gate passed: $report"
