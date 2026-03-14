#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PID_DIR="$ROOT_DIR/.run/elk/pids"

if [[ ! -d "$PID_DIR" ]]; then
  echo "No local ELK pid directory found."
  exit 0
fi

stop_one() {
  local name="$1"
  local pid_file="$PID_DIR/$name.pid"
  if [[ ! -f "$pid_file" ]]; then
    return 0
  fi
  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    sleep 1
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
    echo "stopped $name (pid=$pid)"
  fi
  rm -f "$pid_file"
}

stop_one filebeat
stop_one kibana
stop_one logstash
stop_one elasticsearch

echo "ELK local stopped"
