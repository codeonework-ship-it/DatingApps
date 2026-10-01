#!/usr/bin/env bash
# Write Connect media/database disk usage for node_exporter's textfile collector.
#
#   connect-disk-usage.sh [--media-root DIR] [--postgres-dir DIR] [--out FILE]
#
# Run by connect-disk-usage.timer every 15 minutes (nice/ionice'd). Produces:
#   verified_dating_disk_avail_bytes{path_role="media|postgres",path="..."}
#   verified_dating_disk_size_bytes{path_role="media|postgres",path="..."}
#   verified_dating_media_bytes{area="public|private|quarantine|tmp"}
#   verified_dating_disk_usage_report_timestamp_seconds
# The file is replaced atomically so node_exporter never reads half a report.
set -euo pipefail

media_root=/var/lib/connect/media
postgres_dir=/var/lib/postgresql
out=/var/lib/node_exporter/textfile/connect_disk.prom

while [[ $# -gt 0 ]]; do
  case "$1" in
    --media-root) media_root="$2"; shift 2 ;;
    --postgres-dir) postgres_dir="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

fs_lines() {
  local role="$1" path="$2" avail size
  [[ -d "$path" ]] || return 0
  # POSIX df: 1024-byte blocks; columns: fs blocks used avail capacity mount
  read -r size avail < <(df -P -k "$path" | awk 'NR==2 {print $2*1024, $4*1024}')
  printf 'verified_dating_disk_avail_bytes{path_role="%s",path="%s"} %s\n' "$role" "$(escape "$path")" "$avail"
  printf 'verified_dating_disk_size_bytes{path_role="%s",path="%s"} %s\n' "$role" "$(escape "$path")" "$size"
}

tmp="$(mktemp "${out}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
{
  echo '# HELP verified_dating_disk_avail_bytes Free bytes on the filesystem holding a Connect data directory.'
  echo '# TYPE verified_dating_disk_avail_bytes gauge'
  echo '# HELP verified_dating_disk_size_bytes Size of the filesystem holding a Connect data directory.'
  echo '# TYPE verified_dating_disk_size_bytes gauge'
  fs_lines media "$media_root"
  fs_lines postgres "$postgres_dir"
  echo '# HELP verified_dating_media_bytes Bytes stored under each media area.'
  echo '# TYPE verified_dating_media_bytes gauge'
  for area in public private quarantine tmp; do
    if [[ -d "$media_root/$area" ]]; then
      bytes="$(du -sb "$media_root/$area" 2>/dev/null | awk '{print $1}')"
      printf 'verified_dating_media_bytes{area="%s"} %s\n' "$area" "${bytes:-0}"
    fi
  done
  echo '# HELP verified_dating_disk_usage_report_timestamp_seconds When this report was written.'
  echo '# TYPE verified_dating_disk_usage_report_timestamp_seconds gauge'
  printf 'verified_dating_disk_usage_report_timestamp_seconds %s\n' "$(date +%s)"
} >"$tmp"
chmod 0644 "$tmp"
mv "$tmp" "$out"
trap - EXIT
