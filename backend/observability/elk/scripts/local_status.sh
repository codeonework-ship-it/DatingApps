#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PID_DIR="$ROOT_DIR/.run/elk/pids"

show_proc() {
  local name="$1"
  local pid_file="$PID_DIR/$name.pid"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      echo "$name: running (pid=$pid)"
      return
    fi
  fi
  echo "$name: stopped"
}

show_proc elasticsearch
show_proc logstash
show_proc kibana
show_proc filebeat

echo "Elasticsearch HTTP: $(curl -fsS http://127.0.0.1:9200 >/dev/null 2>&1 && echo up || echo down)"
echo "Kibana HTTP:        $(curl -fsS http://127.0.0.1:5601 >/dev/null 2>&1 && echo up || echo down)"
