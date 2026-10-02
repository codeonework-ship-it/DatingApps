#!/usr/bin/env bash
# Prepare an Ubuntu VPS for Connect media storage.
#
#   sudo deploy/scripts/setup_media_storage.sh [--media-root DIR] [--nginx-user www-data]
#                                              [--fix-existing] [--dry-run]
#
# Creates the "connect" system user, /etc/connect (root:connect 0750),
# /var/lib/connect/spool and the media layout:
#
#   <root>/public/{profile_photos,legacy_profile_photos,group_covers}   0750 dirs / 0640 files
#   <root>/quarantine/profile_photos                                    0700 / 0600
#   <root>/private/{chapter_photos,theme_photos,voice,verification}     0700 / 0600
#   <root>/tmp                                                          0700 (atomic uploads)
#
# nginx's user joins the connect group so it can read public/ (only through the
# internal X-Accel location); private/, quarantine/ and tmp/ stay owner-only.
# Idempotent: safe to re-run. --fix-existing also re-applies ownership and
# permissions to files already present (e.g. after copying legacy media).
set -euo pipefail

media_root=/var/lib/connect/media
nginx_user=www-data
fix_existing=false
dry_run=false
connect_user=connect

while [[ $# -gt 0 ]]; do
  case "$1" in
    --media-root) media_root="$2"; shift 2 ;;
    --nginx-user) nginx_user="$2"; shift 2 ;;
    --fix-existing) fix_existing=true; shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

run() {
  if $dry_run; then printf '+ %s\n' "$*"; else "$@"; fi
}

if [[ $EUID -ne 0 ]] && ! $dry_run; then
  echo "run as root (sudo)" >&2
  exit 1
fi
case "$media_root" in
  /*) ;;
  *) echo "--media-root must be an absolute path" >&2; exit 1 ;;
esac
if [[ -L "$media_root" ]]; then
  echo "$media_root is a symlink; point MEDIA_STORAGE_ROOT at the real directory instead" >&2
  exit 1
fi

# 1) dedicated system user without a login shell
if ! id -u "$connect_user" >/dev/null 2>&1; then
  run useradd --system --user-group --home-dir /var/lib/connect --no-create-home \
    --shell /usr/sbin/nologin --comment "Connect app services" "$connect_user"
fi

# 2) configuration directory: root owns, services read via the group
run install -d -o root -g "$connect_user" -m 0750 /etc/connect
run install -d -o root -g "$connect_user" -m 0750 /etc/connect/aws
for env_file in /etc/connect/connect.env /etc/connect/storage.env /etc/connect/aws/credentials /etc/connect/aws/config; do
  if [[ -f "$env_file" ]]; then
    run chown root:"$connect_user" "$env_file"
    run chmod 0640 "$env_file"
  fi
done

# 3) state + media layout
run install -d -o "$connect_user" -g "$connect_user" -m 0750 /var/lib/connect
run install -d -o "$connect_user" -g "$connect_user" -m 0700 /var/lib/connect/spool
run install -d -o "$connect_user" -g "$connect_user" -m 0750 "$media_root"
for dir in public public/profile_photos public/legacy_profile_photos public/group_covers; do
  run install -d -o "$connect_user" -g "$connect_user" -m 0750 "$media_root/$dir"
done
for dir in quarantine quarantine/profile_photos private private/chapter_photos private/theme_photos \
           private/voice private/verification tmp; do
  run install -d -o "$connect_user" -g "$connect_user" -m 0700 "$media_root/$dir"
done

# 4) nginx may traverse <root> and read public/ through the connect group
if id -u "$nginx_user" >/dev/null 2>&1; then
  if ! id -nG "$nginx_user" | tr ' ' '\n' | grep -qx "$connect_user"; then
    run usermod -a -G "$connect_user" "$nginx_user"
    echo "added $nginx_user to group $connect_user (reload nginx afterwards)"
  fi
else
  echo "note: user $nginx_user not found; install nginx first or pass --nginx-user" >&2
fi

# 5) optional: normalize what is already on disk
if $fix_existing; then
  run chown -R "$connect_user":"$connect_user" "$media_root"
  run find "$media_root/public" -type d -exec chmod 0750 {} +
  run find "$media_root/public" -type f -exec chmod 0640 {} +
  for dir in private quarantine tmp; do
    run find "$media_root/$dir" -type d -exec chmod 0700 {} +
    run find "$media_root/$dir" -type f -exec chmod 0600 {} +
  done
  # Symlinks are never followed by the app; report any so they can be removed.
  if find "$media_root" -type l | grep -q .; then
    echo "warning: symlinks found under $media_root (the app refuses to serve them):" >&2
    find "$media_root" -type l >&2
  fi
fi

# 6) tmp/ must share a filesystem with the media directories (atomic rename)
if ! $dry_run; then
  root_dev=$(stat -c %d "$media_root")
  tmp_dev=$(stat -c %d "$media_root/tmp")
  if [[ "$root_dev" != "$tmp_dev" ]]; then
    echo "error: $media_root/tmp is on a different filesystem than $media_root" >&2
    exit 1
  fi
  avail_mb=$(df -Pm "$media_root" | awk 'NR==2 {print $4}')
  echo "media root $media_root ready (${avail_mb} MiB free)"
fi

# 7) Local disk is the chosen backend (no S3 for now): install the local
#    storage env file unless one already exists. Switching to S3 later means
#    replacing it with backend/config/storage.s3.env.example.
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
storage_env=/etc/connect/storage.env
if [[ ! -f "$storage_env" ]]; then
  run install -o root -g "$connect_user" -m 0640 \
    "$repo_root/backend/config/storage.local.env.example" "$storage_env"
  echo "installed $storage_env (local disk; set MEDIA_STORAGE_ROOT if not $media_root)"
else
  echo "$storage_env already exists; left unchanged"
fi

cat <<EOF
next steps:
  1. check $storage_env (local disk by default; for S3 later, replace it with
     backend/config/storage.s3.env.example as root:connect 0640)
  2. sudo -u $connect_user env ENVIRONMENT=production STORAGE_CONFIG_FILE=/etc/connect/storage.env /opt/connect/bin/mediactl check -probe
  3. sudo systemctl restart connect-mobile-bff && sudo journalctl -u connect-mobile-bff -n 50
EOF
