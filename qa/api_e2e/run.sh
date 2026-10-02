#!/usr/bin/env bash
# API end-to-end functional suite against the running local stack.
#   qa/api_e2e/run.sh [pytest args]
# Env: E2E_API_BASE_URL (default http://127.0.0.1:18080/v1), E2E_KEEP_MEMBERS=true to skip cleanup.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
python="${PYTHON:-$root/.venv/bin/python}"
out="$root/qa/results/api_e2e"
mkdir -p "$out"
cd "$here"
exec "$python" -m pytest -q --junitxml="$out/junit-$(date +%Y%m%d-%H%M%S).xml" "$@"
