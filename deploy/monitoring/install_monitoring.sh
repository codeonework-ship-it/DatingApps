#!/usr/bin/env bash
# Install or update the Connect monitoring stack on an Ubuntu VPS.
#
#   sudo deploy/monitoring/install_monitoring.sh --domain connect.example.com
#        [--with-grafana] [--with-loki] [--only COMPONENT] [--skip-download]
#        [--src /opt/connect/src] [--dry-run]
#
# Components (all bound to 127.0.0.1, managed by connect-monitoring.target):
#   prometheus      upstream release, 30d / 20GB retention, rules from
#                   backend/observability/prometheus/rules
#   alertmanager    upstream release on :9193, config rendered from
#                   backend/observability/alertmanager + /etc/connect-monitoring/alertmanager.env
#   exporters       node_exporter (+ systemd + textfile), postgres_exporter
#                   (connect_monitor role), blackbox_exporter, connect-disk-usage.timer
#   grafana         (--with-grafana) APT package, provisioned datasources and
#                   one folder per dashboard directory
#   loki            (--with-loki) APT loki + alloy, journald -> Loki, 14 days
# --only re-applies one of: prometheus | rules | alertmanager | exporters | grafana | dashboards | loki
#
# Idempotent. --dry-run prints every command instead of running it.
# Guide: documents/MONITORING_AND_OBSERVABILITY_2026-10-01.md
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$(cd "$script_dir/../.." && pwd)"
domain=""
with_grafana=false
with_loki=false
only=""
skip_download=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) domain="$2"; shift 2 ;;
    --with-grafana) with_grafana=true; shift ;;
    --with-loki) with_loki=true; shift ;;
    --only) only="$2"; shift 2 ;;
    --skip-download) skip_download=true; shift ;;
    --src) src="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# shellcheck disable=SC1091
. "$script_dir/versions.env"

etc=/etc/connect-monitoring
opt=/opt/connect-monitoring
data=/var/lib/connect-monitoring
cache=/var/cache/connect-monitoring
textfile_dir=/var/lib/node_exporter/textfile
grafana_dashboards=/var/lib/grafana/dashboards/connect
rules_src="$src/backend/observability/prometheus/rules"
dash_src="$src/backend/observability/grafana/dashboards"
prov_src="$src/backend/observability/grafana/provisioning"
am_src="$src/backend/observability/alertmanager"

run() {
  if $dry_run; then printf '+ %s\n' "$*"; else "$@"; fi
}
# write_file MODE OWNER:GROUP DEST < content
write_file() {
  local mode="$1" owner="$2" dest="$3"
  if $dry_run; then
    printf '+ write %s (%s %s)\n' "$dest" "$mode" "$owner"
    cat >/dev/null
    return
  fi
  local tmp
  tmp="$(mktemp "${dest}.XXXXXX")"
  cat >"$tmp"
  chmod "$mode" "$tmp"
  chown "$owner" "$tmp"
  mv "$tmp" "$dest"
}
wants() { [[ -z "$only" || "$only" == "$1" ]]; }
note() { printf '\n== %s\n' "$*"; }

[[ -n "$domain" ]] || { echo "--domain is required (public host name probed by blackbox)" >&2; exit 2; }
case "$domain" in
  *[!A-Za-z0-9.-]*) echo "--domain must be a bare host name" >&2; exit 2 ;;
esac
if [[ $EUID -ne 0 ]] && ! $dry_run; then
  echo "run as root (sudo)" >&2
  exit 1
fi
for dir in "$rules_src" "$dash_src" "$prov_src" "$am_src"; do
  [[ -d "$dir" ]] || { echo "missing $dir (use --src <checkout>)" >&2; exit 1; }
done

case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

# keep_blocks VAR=true... : drop "#@IF VAR ... #@END" blocks whose VAR is not "true".
keep_blocks() {
  awk -v enabled="$*" '
    BEGIN { n = split(enabled, list, " "); for (i = 1; i <= n; i++) on[list[i]] = 1 }
    /^#@IF / { skipping = !($2 in on); next }
    /^#@END/ { skipping = 0; next }
    !skipping { print }
  '
}

system_user() {
  local name="$1"
  if ! id -u "$name" >/dev/null 2>&1; then
    run useradd --system --user-group --no-create-home --home-dir /nonexistent \
      --shell /usr/sbin/nologin --comment "Connect monitoring ($name)" "$name"
  fi
}

# install_release NAME ORG VERSION: download, verify and unpack an upstream
# Prometheus-ecosystem release into $opt/NAME-VERSION and point $opt/NAME at it.
install_release() {
  local name="$1" org="$2" version="$3"
  local base="${name}-${version}.linux-${arch}"
  local url="https://github.com/${org}/${name}/releases/download/v${version}"
  if [[ -x "$opt/$name-$version/$name" ]] && ! $dry_run; then
    run ln -sfn "$opt/$name-$version" "$opt/$name"
    return
  fi
  if $skip_download; then
    echo "--skip-download: $opt/$name-$version is missing" >&2
    exit 1
  fi
  run mkdir -p "$cache"
  run curl -fsSL --proto '=https' -o "$cache/$base.tar.gz" "$url/$base.tar.gz"
  run curl -fsSL --proto '=https' -o "$cache/$name-$version.sha256sums.txt" "$url/sha256sums.txt"
  if ! $dry_run; then
    (cd "$cache" && grep " $base.tar.gz\$" "$name-$version.sha256sums.txt" | sha256sum -c -) \
      || { echo "checksum mismatch for $base.tar.gz" >&2; exit 1; }
  else
    printf '+ verify %s against sha256sums.txt\n' "$base.tar.gz"
  fi
  run mkdir -p "$opt/$name-$version"
  run tar -xzf "$cache/$base.tar.gz" -C "$opt/$name-$version" --strip-components=1 --no-same-owner
  run chown -R root:root "$opt/$name-$version"
  run ln -sfn "$opt/$name-$version" "$opt/$name"
}

install_unit() {
  run install -m 0644 "$script_dir/systemd/$1" "/etc/systemd/system/$1"
}

note "Directories and users"
run mkdir -p "$opt/bin" "$etc/prometheus/rules" "$etc/alertmanager" "$etc/blackbox" \
  "$data/prometheus" "$data/alertmanager" "$textfile_dir"
run chmod 0755 "$etc" "$opt"
for user in prometheus alertmanager node_exporter postgres_exporter blackbox_exporter; do
  system_user "$user"
done
run chown prometheus:prometheus "$data/prometheus"
run chown alertmanager:alertmanager "$data/alertmanager"
run chmod 0750 "$data/prometheus" "$data/alertmanager"

if wants prometheus || wants exporters || wants alertmanager; then
  note "Upstream releases ($arch)"
  wants prometheus && install_release prometheus prometheus "$PROMETHEUS_VERSION"
  wants alertmanager && install_release alertmanager prometheus "$ALERTMANAGER_VERSION"
  if wants exporters; then
    install_release node_exporter prometheus "$NODE_EXPORTER_VERSION"
    install_release postgres_exporter prometheus-community "$POSTGRES_EXPORTER_VERSION"
    install_release blackbox_exporter prometheus "$BLACKBOX_EXPORTER_VERSION"
  fi
fi

if wants prometheus || wants rules; then
  note "Prometheus configuration and rules"
  enabled=""
  $with_grafana && enabled+="WITH_GRAFANA "
  $with_loki && enabled+="WITH_LOKI "
  # shellcheck disable=SC2086
  keep_blocks $enabled <"$script_dir/prometheus/prometheus.yml" \
    | sed "s/\${CONNECT_DOMAIN}/$domain/g" \
    | write_file 0640 root:prometheus "$etc/prometheus/prometheus.yml"
  run find "$etc/prometheus/rules" -name '*.yml' -delete
  for rule in "$rules_src"/*.yml; do
    run install -m 0640 -o root -g prometheus "$rule" "$etc/prometheus/rules/"
  done
  if [[ -x "$opt/prometheus/promtool" ]] && ! $dry_run; then
    "$opt/prometheus/promtool" check config "$etc/prometheus/prometheus.yml"
  fi
  if [[ ! -f "$etc/prometheus.env" ]]; then
    printf 'PROMETHEUS_RETENTION_TIME=30d\nPROMETHEUS_RETENTION_SIZE=20GB\nPROMETHEUS_EXTERNAL_URL=http://127.0.0.1:9090/\n' \
      | write_file 0644 root:root "$etc/prometheus.env"
  fi
  install_unit connect-prometheus.service
fi

if wants alertmanager; then
  note "Alertmanager"
  if [[ ! -f "$etc/alertmanager.env" ]]; then
    run install -m 0640 -o root -g alertmanager "$script_dir/alertmanager/alertmanager.env.example" "$etc/alertmanager.env"
    if ! $dry_run; then
      echo "Created $etc/alertmanager.env from the example: fill in the receivers, then re-run with --only alertmanager." >&2
      exit 3
    fi
  fi
  if $dry_run; then
    printf '+ %s/render_config.sh %s %s\n' "$am_src" "$etc/alertmanager/alertmanager.yml" "$etc/alertmanager.env"
  else
    PATH="$opt/alertmanager:$PATH" ALERTMANAGER_TEMPLATES_DIR="$etc/alertmanager" \
      bash "$am_src/render_config.sh" "$etc/alertmanager/alertmanager.yml" "$etc/alertmanager.env"
    chown root:alertmanager "$etc/alertmanager/alertmanager.yml" "$etc/alertmanager/connect.tmpl"
    chmod 0640 "$etc/alertmanager/alertmanager.yml" "$etc/alertmanager/connect.tmpl"
  fi
  install_unit connect-alertmanager.service
fi

if wants exporters; then
  note "Exporters and disk usage report"
  run install -m 0640 -o root -g blackbox_exporter "$script_dir/blackbox/blackbox.yml" "$etc/blackbox/blackbox.yml"
  if [[ ! -f "$etc/postgres_exporter.env" ]]; then
    run install -m 0640 -o root -g postgres_exporter "$script_dir/postgres/postgres_exporter.env.example" "$etc/postgres_exporter.env"
    echo "Created $etc/postgres_exporter.env: run deploy/monitoring/postgres/create_monitoring_role.sql and set the password." >&2
  fi
  run install -m 0755 "$script_dir/scripts/connect-disk-usage.sh" "$opt/bin/connect-disk-usage.sh"
  for unit in connect-node-exporter.service connect-postgres-exporter.service connect-blackbox-exporter.service \
    connect-disk-usage.service connect-disk-usage.timer; do
    install_unit "$unit"
  done
fi
install_unit connect-monitoring.target

if $with_grafana || $with_loki; then
  if ! $dry_run && [[ ! -f /etc/apt/sources.list.d/grafana.list ]]; then
    note "Grafana APT repository"
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL --proto '=https' https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
    apt-get update
  elif $dry_run; then
    printf '+ add https://apt.grafana.com (signed-by /etc/apt/keyrings/grafana.gpg) and apt-get update\n'
  fi
fi

if $with_grafana && { wants grafana || wants dashboards; }; then
  note "Grafana"
  wants grafana && run apt-get install -y grafana
  run mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards "$grafana_dashboards"
  run install -m 0640 -o root -g grafana "$prov_src/datasources/prometheus.yml" /etc/grafana/provisioning/datasources/connect-prometheus.yml
  if $with_loki; then
    run install -m 0640 -o root -g grafana "$prov_src/datasources/loki.yml" /etc/grafana/provisioning/datasources/connect-loki.yml
  else
    run rm -f /etc/grafana/provisioning/datasources/connect-loki.yml
  fi
  run install -m 0640 -o root -g grafana "$prov_src/dashboards/connect.yml" /etc/grafana/provisioning/dashboards/connect.yml
  # Only reviewed dashboards, one directory (= Grafana folder) each.
  run rm -rf "$grafana_dashboards"
  for dir in "$dash_src"/*/; do
    folder="$(basename "$dir")"
    run mkdir -p "$grafana_dashboards/$folder"
    for json in "$dir"*.json; do
      run install -m 0644 "$json" "$grafana_dashboards/$folder/"
    done
  done
  run chown -R root:grafana "$grafana_dashboards"
  if [[ ! -f "$etc/grafana.env" ]]; then
    sed "s/connect\.example\.com/$domain/g" "$script_dir/grafana/grafana.env.example" \
      | write_file 0640 root:grafana "$etc/grafana.env"
  fi
  if [[ ! -f "$etc/grafana_admin_password" ]]; then
    if $dry_run; then
      printf '+ generate %s (root:grafana 0640)\n' "$etc/grafana_admin_password"
    else
      openssl rand -base64 24 | write_file 0640 root:grafana "$etc/grafana_admin_password"
      echo "Grafana admin password written to $etc/grafana_admin_password" >&2
    fi
  fi
  run mkdir -p /etc/systemd/system/grafana-server.service.d
  run install -m 0644 "$script_dir/grafana/grafana-server.override.conf" /etc/systemd/system/grafana-server.service.d/connect.conf
fi

if $with_loki && wants loki; then
  note "Loki + Alloy (central logs, 14 days)"
  run apt-get install -y loki alloy
  run mkdir -p /var/lib/loki
  run chown loki:loki /var/lib/loki
  run chmod 0750 /var/lib/loki
  run install -m 0644 "$script_dir/loki/loki.yml" /etc/loki/config.yml
  run mkdir -p /etc/systemd/system/loki.service.d
  run install -m 0644 "$script_dir/loki/loki.override.conf" /etc/systemd/system/loki.service.d/connect.conf
  run install -m 0644 "$script_dir/alloy/config.alloy" /etc/alloy/config.alloy
  run install -m 0644 "$script_dir/alloy/alloy.env" /etc/default/alloy
  run usermod -aG systemd-journal,adm alloy
fi

note "Start"
run systemctl daemon-reload
run systemctl enable --now connect-monitoring.target
for unit in connect-prometheus connect-alertmanager connect-node-exporter connect-postgres-exporter \
  connect-blackbox-exporter; do
  if [[ -f "/etc/systemd/system/$unit.service" ]] || $dry_run; then
    run systemctl enable "$unit.service"
    run systemctl restart "$unit.service"
  fi
done
run systemctl enable --now connect-disk-usage.timer
if $with_grafana; then run systemctl enable grafana-server; run systemctl restart grafana-server; fi
if $with_loki; then
  run systemctl enable loki alloy
  run systemctl restart loki alloy
fi

if ! $dry_run; then
  note "Smoke checks"
  sleep 3
  for url in http://127.0.0.1:9090/-/ready http://127.0.0.1:9193/-/ready http://127.0.0.1:9100/metrics \
    http://127.0.0.1:9187/metrics http://127.0.0.1:9115/metrics; do
    if curl -fsS -o /dev/null --max-time 5 "$url"; then echo "ok   $url"; else echo "FAIL $url"; fi
  done
  echo "Targets: ssh -L 9090:127.0.0.1:9090 <vps>  then open http://localhost:9090/targets"
fi
