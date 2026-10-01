#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_dir="$(cd "$script_dir/.." && pwd)"
run_dir="$backend_dir/.run"
data_dir="$run_dir/postgres-data"
socket_dir="${LOCAL_POSTGRES_SOCKET_DIR:-/tmp/dating-app-postgres-55432}"
log_file="$run_dir/postgres.log"
port="${LOCAL_POSTGRES_PORT:-55433}"
pg_bin="${POSTGRES_BIN_DIR:-/opt/homebrew/opt/postgresql@17/bin}"
db_name="${LOCAL_POSTGRES_DB:-dating_app}"
db_user="${LOCAL_POSTGRES_USER:-dating_app}"

mkdir -p "$run_dir" "$socket_dir"

case "${1:-status}" in
  up)
    if [[ ! -f "$data_dir/PG_VERSION" ]]; then
      "$pg_bin/initdb" -D "$data_dir" -U "$db_user" --auth-local=trust --auth-host=trust --encoding=UTF8
    fi
    if ! "$pg_bin/pg_ctl" -D "$data_dir" status >/dev/null 2>&1; then
      "$pg_bin/pg_ctl" -D "$data_dir" -l "$log_file" \
        -o "-p $port -h 127.0.0.1 -k $socket_dir" start
    fi
    if ! "$pg_bin/psql" -h 127.0.0.1 -p "$port" -U "$db_user" -d postgres -Atqc \
      "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1; then
      "$pg_bin/createdb" -h 127.0.0.1 -p "$port" -U "$db_user" "$db_name"
    fi
    echo "postgresql://$db_user@127.0.0.1:$port/$db_name?sslmode=disable"
    ;;
  stop)
    if [[ -f "$data_dir/PG_VERSION" ]] && "$pg_bin/pg_ctl" -D "$data_dir" status >/dev/null 2>&1; then
      "$pg_bin/pg_ctl" -D "$data_dir" stop -m fast
    fi
    ;;
  status)
    "$pg_bin/pg_ctl" -D "$data_dir" status
    ;;
  *)
    echo "usage: $0 {up|stop|status}" >&2
    exit 2
    ;;
esac
