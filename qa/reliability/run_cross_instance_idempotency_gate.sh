#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
backend_dir="$root_dir/backend"
run_dir="$backend_dir/.run/local-signup-stack"
binary="$run_dir/bin/mobile-bff"
env_file="$backend_dir/config/.env.local-postgres.example"
second_port="${SCALE_SECOND_BFF_PORT:-18082}"
report="${SCALE_DISTRIBUTED_REPORT:-$root_dir/qa/reports/reliability/cross-instance.json}"

mkdir -p "$(dirname "$binary")"
(cd "$backend_dir" && go build -o "$binary" ./cmd/mobile-bff)

set -a
# shellcheck disable=SC1090
source "$env_file"
MOBILE_BFF_ADDR="127.0.0.1:$second_port"
set +a

"$binary" >"$run_dir/mobile-bff-scale-second.log" 2>&1 &
second_pid=$!
cleanup() {
  kill "$second_pid" 2>/dev/null || true
  wait "$second_pid" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 100); do
  if curl -fsS "http://127.0.0.1:$second_port/readyz" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done
curl -fsS "http://127.0.0.1:$second_port/readyz" >/dev/null

mkdir -p "$(dirname "$report")"
python3 "$root_dir/qa/reliability/distributed_scale_gate.py" \
  --profile local \
  --base-urls "http://127.0.0.1:18081/v1,http://127.0.0.1:$second_port/v1" \
  --report "$report"

echo "Cross-instance idempotency/reconnect gate passed: $report"
