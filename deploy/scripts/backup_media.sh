#!/usr/bin/env bash
# Back up local Connect media (FILE_STORAGE_BACKEND=local_fs).
#
#   sudo deploy/scripts/backup_media.sh restic   # encrypted, deduplicated snapshots
#   sudo deploy/scripts/backup_media.sh rsync    # mirror to another host
#
# restic: export RESTIC_REPOSITORY (e.g. sftp:backup@backup-host:/srv/restic/connect
#         or s3:s3.amazonaws.com/connect-backups) and RESTIC_PASSWORD_FILE
#         (e.g. /etc/connect/restic.pass, root 0600) before running.
# rsync:  export BACKUP_RSYNC_TARGET (e.g. backup@backup-host:/srv/connect-media/).
#
# tmp/ is excluded (in-progress uploads). Run it from a systemd timer or cron,
# and back up PostgreSQL at the same time: the database holds the storage keys.
# Erasure note: deleted members' files disappear from new snapshots only; set
# a retention (forget --keep-*) that matches the privacy policy.
set -euo pipefail

media_root="${MEDIA_STORAGE_ROOT:-/var/lib/connect/media}"
mode="${1:-}"

if [[ ! -d "$media_root/public" || ! -d "$media_root/private" ]]; then
  echo "$media_root does not look like a Connect media root" >&2
  exit 1
fi

case "$mode" in
  restic)
    : "${RESTIC_REPOSITORY:?set RESTIC_REPOSITORY}"
    : "${RESTIC_PASSWORD_FILE:?set RESTIC_PASSWORD_FILE}"
    restic backup "$media_root" --exclude "$media_root/tmp" --tag connect-media
    restic forget --tag connect-media --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
    restic check --read-data-subset=1/50
    ;;
  rsync)
    : "${BACKUP_RSYNC_TARGET:?set BACKUP_RSYNC_TARGET}"
    rsync -a --delete --numeric-ids --exclude '/tmp/' "$media_root/" "$BACKUP_RSYNC_TARGET"
    ;;
  *)
    echo "usage: $0 restic|rsync" >&2
    exit 2
    ;;
esac
