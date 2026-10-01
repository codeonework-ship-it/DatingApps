#!/usr/bin/env bash
# Render the Alertmanager configuration from alertmanager.yml.tmpl.
#
#   render_config.sh [OUTPUT] [ENV_FILE]
#
# ENV_FILE (optional) is sourced first, e.g. /etc/connect-monitoring/alertmanager.env.
# Required: ALERTMANAGER_PAGE_WEBHOOK_URL, ALERTMANAGER_TICKET_WEBHOOK_URL.
# Optional channels (blocks are dropped when unset): PAGERDUTY_ROUTING_KEY,
# SLACK_WEBHOOK_URL (+ SLACK_PAGE_CHANNEL, SLACK_TICKET_CHANNEL),
# ALERT_EMAIL_TO (+ ALERT_SMTP_SMARTHOST, ALERT_SMTP_FROM, ALERT_SMTP_USERNAME,
# ALERT_SMTP_PASSWORD), DEADMANS_SWITCH_URL. RUNBOOK_BASE_URL prefixes the
# relative runbook_url annotations (e.g. https://github.com/<org>/<repo>/blob/main).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output="${1:-$script_dir/alertmanager.generated.yml}"
env_file="${2:-}"

if [[ -n "$env_file" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
fi

: "${ALERTMANAGER_PAGE_WEBHOOK_URL:?ALERTMANAGER_PAGE_WEBHOOK_URL is required}"
: "${ALERTMANAGER_TICKET_WEBHOOK_URL:?ALERTMANAGER_TICKET_WEBHOOK_URL is required}"
export ALERTMANAGER_TEMPLATES_DIR="${ALERTMANAGER_TEMPLATES_DIR:-$(cd "$(dirname "$output")" && pwd)}"
export RUNBOOK_BASE_URL="${RUNBOOK_BASE_URL:-}"
export SLACK_PAGE_CHANNEL="${SLACK_PAGE_CHANNEL:-#connect-pages}"
export SLACK_TICKET_CHANNEL="${SLACK_TICKET_CHANNEL:-#connect-alerts}"
if [[ -n "${ALERT_EMAIL_TO:-}" && -z "${ALERT_SMTP_SMARTHOST:-}" ]]; then
  echo "ALERT_EMAIL_TO needs ALERT_SMTP_SMARTHOST (host:port) and ALERT_SMTP_FROM" >&2
  exit 1
fi

vars=(ALERTMANAGER_PAGE_WEBHOOK_URL ALERTMANAGER_TICKET_WEBHOOK_URL ALERTMANAGER_TEMPLATES_DIR
  RUNBOOK_BASE_URL PAGERDUTY_ROUTING_KEY SLACK_WEBHOOK_URL SLACK_PAGE_CHANNEL SLACK_TICKET_CHANNEL
  ALERT_EMAIL_TO ALERT_SMTP_SMARTHOST ALERT_SMTP_FROM ALERT_SMTP_USERNAME ALERT_SMTP_PASSWORD
  DEADMANS_SWITCH_URL)
for name in "${vars[@]}"; do export "$name=${!name:-}"; done

# Keep "#@IF VAR ... #@END" blocks only when VAR is non-empty.
filtered="$(awk '
  /^#@IF / { name=$2; keep = (ENVIRON[name] != ""); skipping = !keep; next }
  /^#@END/ { skipping = 0; next }
  !skipping { print }
' "$script_dir/alertmanager.yml.tmpl")"

subst=""
for name in "${vars[@]}"; do subst+="\${$name} "; done

umask 027
tmp="$(mktemp "${output}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$filtered" | envsubst "$subst" >"$tmp"
# Notification templates carry the runbook base URL too.
envsubst '${RUNBOOK_BASE_URL}' <"$script_dir/connect.tmpl.in" >"$ALERTMANAGER_TEMPLATES_DIR/connect.tmpl"

if command -v amtool >/dev/null 2>&1; then
  amtool check-config "$tmp"
fi
mv "$tmp" "$output"
trap - EXIT
echo "Rendered Alertmanager config: $output"
