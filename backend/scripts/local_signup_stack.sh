#!/usr/bin/env bash
set -euo pipefail

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run_dir="$backend_dir/.run/local-signup-stack"
bin_dir="$run_dir/bin"
env_file="$backend_dir/config/.env.local-postgres.example"

load_environment() {
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

pid_file() {
  printf '%s/%s.pid' "$run_dir" "$1"
}

is_running() {
  local service="$1"
  local file
  file="$(pid_file "$service")"
  [[ -f "$file" ]] && kill -0 "$(<"$file")" 2>/dev/null
}

build_services() {
  mkdir -p "$bin_dir"
  (
    cd "$backend_dir"
    for service in auth-svc profile-svc matching-svc chat-svc mobile-bff api-gateway; do
      go build -o "$bin_dir/$service" "./cmd/$service"
    done
  )
}

start_service() {
  local service="$1"
  if is_running "$service"; then
    printf '%s already running (pid %s)\n' "$service" "$(<"$(pid_file "$service")")"
    return
  fi

  nohup "$bin_dir/$service" >"$run_dir/$service.log" 2>&1 &
  local service_pid=$!
  printf '%s\n' "$service_pid" >"$(pid_file "$service")"
  printf 'started %s (pid %s)\n' "$service" "$service_pid"
}

wait_for_http() {
  local name="$1"
  local url="$2"
  for _ in $(seq 1 100); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      printf '%s ready at %s\n' "$name" "$url"
      return
    fi
    sleep 0.2
  done
  printf '%s failed to become ready; inspect %s/%s.log\n' "$name" "$run_dir" "$name" >&2
  return 1
}

up() {
  load_environment
  "$backend_dir/scripts/local_postgres.sh" up
  mkdir -p "$run_dir"
  build_services
  start_service auth-svc
  start_service profile-svc
  start_service matching-svc
  start_service chat-svc
  start_service mobile-bff
  wait_for_http mobile-bff "http://127.0.0.1:18081/healthz"
  start_service api-gateway
  wait_for_http api-gateway "http://127.0.0.1:18080/healthz"
}

down() {
  for service in api-gateway mobile-bff chat-svc matching-svc profile-svc auth-svc; do
    local file
    file="$(pid_file "$service")"
    if [[ -f "$file" ]]; then
      local service_pid
      service_pid="$(<"$file")"
      if kill -0 "$service_pid" 2>/dev/null; then
        kill "$service_pid"
        printf 'stopped %s (pid %s)\n' "$service" "$service_pid"
      fi
      rm -f "$file"
    fi
  done
}

status() {
  for service in auth-svc profile-svc matching-svc chat-svc mobile-bff api-gateway; do
    if is_running "$service"; then
      printf '%s: running (pid %s)\n' "$service" "$(<"$(pid_file "$service")")"
    else
      printf '%s: stopped\n' "$service"
    fi
  done
}

case "${1:-up}" in
  up) up ;;
  down) down ;;
  restart) down; up ;;
  status) status ;;
  *)
    printf 'usage: %s {up|down|restart|status}\n' "$0" >&2
    exit 2
    ;;
esac
