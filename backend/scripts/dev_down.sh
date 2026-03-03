#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/.run/pids"

if [[ ! -f "$PID_FILE" ]]; then
  echo "No pid file found: $PID_FILE"
  exit 0
fi

while read -r pid name; do
  if [[ -n "${pid:-}" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    echo "Stopped $name ($pid)"
  fi
done <"$PID_FILE"

rm -f "$PID_FILE"
