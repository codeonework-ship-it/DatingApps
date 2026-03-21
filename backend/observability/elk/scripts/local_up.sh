#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ELK_DIR="$ROOT_DIR/observability/elk"
RUN_DIR="$ROOT_DIR/.run/elk"
PID_DIR="$RUN_DIR/pids"
LOG_DIR="$RUN_DIR/logs"
DATA_DIR="$RUN_DIR/data"

mkdir -p "$PID_DIR" "$LOG_DIR" "$DATA_DIR/elasticsearch" "$DATA_DIR/logstash" "$DATA_DIR/filebeat" "$DATA_DIR/kibana"

resolve_bin() {
  local bin_name="$1"
  local env_name="$2"
  local from_env="${!env_name:-}"
  if [[ -n "$from_env" && -x "$from_env" ]]; then
    printf "%s" "$from_env"
    return 0
  fi
  if command -v "$bin_name" >/dev/null 2>&1; then
    command -v "$bin_name"
    return 0
  fi
  return 1
}

wait_http() {
  local url="$1"
  local timeout_secs="${2:-60}"
  local i=0
  until curl -fsS "$url" >/dev/null 2>&1; do
    sleep 1
    i=$((i + 1))
    if [[ "$i" -ge "$timeout_secs" ]]; then
      echo "Timed out waiting for $url"
      return 1
    fi
  done
}

start_proc() {
  local name="$1"
  local cmd="$2"
  local pid_file="$PID_DIR/$name.pid"
  local out_file="$LOG_DIR/$name.out.log"

  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      echo "$name already running (pid=$pid)"
      return 0
    fi
    rm -f "$pid_file"
  fi

  nohup bash -lc "$cmd" >"$out_file" 2>&1 &
  local pid=$!
  echo "$pid" >"$pid_file"
  echo "started $name (pid=$pid)"
}

ES_BIN="$(resolve_bin elasticsearch ELASTICSEARCH_BIN || true)"
LS_BIN="$(resolve_bin logstash LOGSTASH_BIN || true)"
KB_BIN="$(resolve_bin kibana KIBANA_BIN || true)"
FB_BIN="$(resolve_bin filebeat FILEBEAT_BIN || true)"

if [[ -z "$ES_BIN" || -z "$KB_BIN" ]]; then
  echo "Missing required binaries. Required: elasticsearch, kibana"
  echo "Optional: logstash, filebeat"
  echo "You can set explicit paths via ELASTICSEARCH_BIN, LOGSTASH_BIN, KIBANA_BIN, FILEBEAT_BIN"
  exit 1
fi

start_proc "elasticsearch" "cd '$ROOT_DIR' && ES_JAVA_OPTS='${ES_JAVA_OPTS:--Xms256m -Xmx256m}' '$ES_BIN' -Epath.data='$DATA_DIR/elasticsearch' -Epath.logs='$LOG_DIR/elasticsearch' -Ediscovery.type=single-node -Expack.security.enabled=false -Ehttp.host=127.0.0.1 -Ehttp.port=9200"
wait_http "http://127.0.0.1:9200" 90

if [[ -n "$LS_BIN" ]]; then
  start_proc "logstash" "cd '$ROOT_DIR' && LS_JAVA_OPTS='${LS_JAVA_OPTS:--Xms256m -Xmx256m}' '$LS_BIN' --path.data '$DATA_DIR/logstash' -f '$ELK_DIR/logstash/pipeline/logstash.local.conf'"
else
  echo "Skipping logstash: binary not found"
fi

start_proc "kibana" "cd '$ROOT_DIR' && NODE_OPTIONS='${KIBANA_NODE_OPTIONS:---max-old-space-size=512}' '$KB_BIN' --path.data '$DATA_DIR/kibana' -c '$ELK_DIR/kibana/kibana.local.yml'"

if [[ -n "$FB_BIN" ]]; then
  start_proc "filebeat" "cd '$ROOT_DIR' && '$FB_BIN' --strict.perms=false --path.data '$DATA_DIR/filebeat' --path.logs '$LOG_DIR/filebeat' -c '$ELK_DIR/filebeat/filebeat.local.yml'"
else
  echo "Skipping filebeat: binary not found"
fi

wait_http "http://127.0.0.1:5601" 120

echo "ELK local started"
echo "Elasticsearch: http://127.0.0.1:9200"
echo "Kibana:        http://127.0.0.1:5601"
