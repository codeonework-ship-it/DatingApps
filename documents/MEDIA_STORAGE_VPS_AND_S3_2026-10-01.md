# Media storage on the Ubuntu VPS and AWS S3 — 2026-10-01

How Connect stores uploaded media in production: one storage abstraction for
every media kind, a local directory layout for the Linux VPS, a separate AWS S3
configuration (bucket, encryption, authentication), deployment files, and the
copy tool for moving media between backends.

| Piece | Location |
|---|---|
| Storage abstraction (local + S3) | `backend/internal/platform/mediastore/` |
| Storage config section + validation | `backend/internal/platform/config/storage.go` |
| API glue (upload, serve, delete, cleanup) | `backend/internal/bff/mobile/media_store.go` |
| Check / copy tool | `backend/cmd/mediactl` |
| Local storage env template | `backend/config/storage.local.env.example` |
| S3 storage env template | `backend/config/storage.s3.env.example` |
| systemd, tmpfiles, nginx, setup + backup scripts, IAM JSON | `deploy/` |

## 1. Media kinds

Every kind now stores, reads and deletes bytes through `mediastore.Store`. Before
this change each upload handler chose between local disk and S3 itself, files
went to one flat directory (`MEDIA_UPLOADS_DIR`), and S3 mode put every kind,
identity documents included, under the profile-photo prefix. No media is
stored in PostgreSQL (`bytea`); the database holds only storage keys, sizes,
hashes and moderation state.

| Kind | Storage key (stored in DB, unchanged) | Before | After (local) | After (S3, default prefix) | How it is served |
|---|---|---|---|---|---|
| Profile photos (approved) | `approved/<user>/<id>.<ext>` in `user_management.photos.storage_path` | flat dir or S3 `profile-photos/…` | `public/profile_photos/` | `public/profile_photos/` (public bucket if set) | `GET /v1/media/<key>` after a DB check (row exists, not deleted, approved); nginx `X-Accel-Redirect` or Go stream; S3 proxy or presigned redirect |
| Profile photos (review/quarantine) | `quarantine/<user>/<id>.<ext>` | same | `quarantine/profile_photos/` | `quarantine/profile_photos/` | API only (admin review route, or `/v1/media` once approved); never through nginx |
| Older profile photos | any other key, e.g. `<user>/<file>`, `seed/…` | same | `public/legacy_profile_photos/` | `public/legacy_profile_photos/` | as approved photos |
| Chapter (blog) photos | `private/blog/<user>/<post>/<uuid>.<ext>` in `matching.blog_photos` (also referenced by `blog_evidence_photos`) | same | `private/chapter_photos/` | `private/chapter_photos/` | API stream after audience check (`/v1/blog/…/photos/{id}`, public publication page, operator case view) |
| Photo Theme entries | `private/themes/<user>/<theme>/<uuid>.<ext>` in `matching.photo_theme_entries` | same | `private/theme_photos/` | `private/theme_photos/` | API stream after visibility check |
| Voice recordings (icebreakers/intros) | `private/voice/<user>/<icebreaker>/<uuid>.<ext>` in `matching.voice_icebreakers.audio_storage_path` | same | `private/voice/` | `private/voice/` | HMAC-signed short-lived URL (`/v1/media/voice/{id}?token=`, `PRIVATE_MEDIA_SIGNING_KEY`), streamed by the API, `no-store` |
| Identity evidence (ID document, selfie) | `private/verification/<user>/<field>/<id>.<ext>` in `matching.verification_states.details` | same | `private/verification/` | `private/verification/` | never served to members; sent to the verification provider at upload; deleted by the retention worker |
| Group covers | `group_covers/<group>/<file>` | — | `public/group_covers/` | `public/group_covers/` | group cover photos (migration 121): moderated, served by `GET /v1/engagement/groups/{id}/cover` after a visibility check |

Chapter and theme photos are **private** even though members see them on walls:
every read is gated by the post/theme audience, so they must never be reachable
from a static URL.

Deletion paths (all go through the store): photo delete and quota rollback,
the hourly lifecycle cleanup (expired staged photos, deleted chapter/theme
photos, released case evidence, unreferenced local files older than 24 h,
stale `tmp/` uploads), account erasure and the identity-evidence retention
worker.

### Storage keys and backward compatibility

Keys are logical and backend independent: the same key resolves to a file
under the media root or to an object in a bucket. Consequences:

- Existing rows keep working; no database migration.
- Switching local → S3 is a byte copy (`mediactl copy`), no SQL.
- Old flat files (`MEDIA_UPLOADS_DIR`) are still found: with the new layout,
  reads and deletes fall back to that directory until it is copied.
- Rows written by an earlier S3 deployment store the full object key including
  `AWS_S3_PROFILE_PHOTOS_PREFIX` (default `profile-photos/…`). Such keys are
  read from `AWS_S3_BUCKET` verbatim, and `/v1/media/<path>` also looks them up
  with that prefix, so their URLs keep working.
- Keys are validated (`[A-Za-z0-9._-]` segments, no `..`, no hidden segments,
  no absolute paths); an unknown key under `private/`, `public/`, `quarantine/`
  or `tmp/` is rejected instead of being treated as a public photo.

## 2. Local directory layout (Ubuntu VPS)

`MEDIA_STORAGE_ROOT=/var/lib/connect/media` (the production default), owned by
the dedicated `connect` system user:

```
/var/lib/connect/media                    0750 connect:connect
├── public/                               0750   nginx (www-data in group connect) may read
│   ├── profile_photos/<user>/<id>.png    0640
│   ├── legacy_profile_photos/…
│   └── group_covers/…
├── quarantine/                           0700   API only
│   └── profile_photos/<user>/<id>.png    0600
├── private/                              0700   API only
│   ├── chapter_photos/<user>/<post>/…    0600
│   ├── theme_photos/<user>/<theme>/…
│   ├── voice/<user>/<icebreaker>/…
│   └── verification/<user>/<field>/…
└── tmp/                                  0700   in-progress uploads
/var/lib/connect/spool                    0700   XP award spool (PROGRESSION_AWARD_SPOOL_PATH)
/etc/connect                              0750 root:connect (env files 0640)
```

Guarantees of the local backend:

- **Atomic writes**: bytes go to `tmp/.upload-*`, are `fsync`ed and `chmod`ed,
  then `rename`d into place, and the directory is synced. Readers never see a
  partial file; a failed upload leaves nothing behind.
- **Traversal protection**: keys are validated, joined paths must stay under
  the root, files are opened with `O_NOFOLLOW`, and symlinks are refused.
- **Free space**: uploads are refused with HTTP 507 when less than
  `MEDIA_MIN_FREE_MB` (500 MB) would remain.
- **Permissions**: `public/` uses `MEDIA_PUBLIC_DIR_MODE`/`MEDIA_PUBLIC_FILE_MODE`
  (0750/0640); `private/`, `quarantine/` and `tmp/` are always 0700/0600,
  independent of the umask.
- **Startup self-check** (mobile BFF and `mediactl check`): creates missing
  directories, refuses symlinked or world-writable directories, tightens a
  private directory that became group/world readable, writes a probe in
  `tmp/` and renames it into every kind directory (proves write access and
  that `tmp/` is on the same filesystem). Failure stops the BFF with a message
  such as:

  ```
  configure media storage: media storage self-check failed: /var/lib/connect/media/tmp is not writable by uid 998: permission denied
    hint: run deploy/scripts/setup_media_storage.sh (creates the connect user and /var/lib/connect/media with the right owner/permissions)
  ```

Development is unchanged: without `MEDIA_STORAGE_ROOT` (and outside
production/staging) the flat layout under `MEDIA_UPLOADS_DIR`
(`.run/uploads/profile_photos`) is used, exactly as before. Set
`MEDIA_STORAGE_ROOT=.run/media` locally to try the VPS layout; old files are
then read from `MEDIA_UPLOADS_DIR` as a fallback.

## 3. Configuration

Storage settings live in their **own file**, separate from the main runtime
env, so S3 credentials can be managed and rotated alone and are visible only
to the mobile BFF:

- systemd: `EnvironmentFile=/etc/connect/storage.env` in
  `connect-mobile-bff.service` (the other services do not load it);
- without systemd: `STORAGE_CONFIG_FILE=/etc/connect/storage.env`. Only
  `MEDIA_*`, `AWS_S3_*`, `FILE_STORAGE_BACKEND` and `USE_AWS_S3_STORAGE` are
  accepted in it; values already in the environment win; a world-readable file
  that contains a secret is refused.

Start from `backend/config/storage.local.env.example` or
`backend/config/storage.s3.env.example`, and remove the storage lines from the
main env file. All values are validated at startup (`config.LoadMediaStorage`);
every problem is listed in one error, and secrets are never logged (the startup
log line shows bucket, region, SSE, serve mode and the auth mode with a masked
access key id).

### Local backend

| Variable | Default | Notes |
|---|---|---|
| `FILE_STORAGE_BACKEND` | `local_fs` | `local_fs` or `aws_s3` (`USE_AWS_S3_STORAGE=true` forces S3); unknown values are an error |
| `MEDIA_STORAGE_ROOT` | `/var/lib/connect/media` in production/staging, empty in development | must be absolute in production/staging |
| `MEDIA_STORAGE_LAYOUT` | `kinds` when a root is set, else `flat` | production requires `kinds` |
| `MEDIA_UPLOADS_DIR` | `.run/uploads/profile_photos` (dev) | legacy flat dir: root in flat layout, read/delete fallback in kinds layout; must not overlap the root |
| `MEDIA_MIN_FREE_MB` | `500` | |
| `MEDIA_PUBLIC_DIR_MODE` / `MEDIA_PUBLIC_FILE_MODE` | `0750` / `0640` | must not be world-writable |
| `MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX` | empty | `/_connect_media/` with the nginx site below |
| `MEDIA_PUBLIC_BASE_URL` | `auto` | base of photo URLs returned by the API |

### S3 backend

| Variable | Default | Notes |
|---|---|---|
| `AWS_S3_REGION` | — | required in production/staging unless an endpoint is set |
| `AWS_S3_BUCKET` | — | required; private bucket |
| `AWS_S3_PUBLIC_BUCKET` | empty | optional bucket for public kinds (CDN origin) |
| `AWS_S3_ENDPOINT`, `AWS_S3_FORCE_PATH_STYLE` | empty, `false` | S3-compatible services; https required in production |
| `AWS_S3_KEY_PREFIX` | empty | global prefix, e.g. `prod` |
| `AWS_S3_PREFIX_<KIND>` | see template | one per kind; overlapping prefixes are an error |
| `AWS_S3_PROFILE_PHOTOS_PREFIX` | `profile-photos` | only for keys from earlier S3 deployments |
| `AWS_S3_SSE` | empty (bucket default) | `AES256` or `aws:kms` |
| `AWS_S3_SSE_KMS_KEY_ID` | empty | only with `aws:kms` |
| `AWS_S3_BUCKET_KEY_ENABLED` | `true` with KMS | |
| `AWS_S3_SEND_CHECKSUMS` | `true` | sends `x-amz-checksum-sha256`; S3 rejects corrupted uploads |
| `AWS_S3_SERVE_MODE` | `proxy` | `proxy` (API streams) or `redirect` (302 to presigned GET / CDN for public kinds; private kinds are always streamed) |
| `AWS_S3_PRESIGN_TTL_SECONDS` | `300` | 30–3600 |
| `AWS_S3_PUBLIC_BASE_URL` | empty | CDN URL of the public bucket (redirect mode) |
| `AWS_S3_AUTH_MODE` | inferred | see §4 |

Multipart upload is not used: the largest object is about 10 MB (identity
evidence, per image), far below the 5 GB single-PUT limit, and every object is
uploaded from memory after validation and moderation. The lifecycle rule still
aborts stray multipart uploads.

## 4. AWS authentication modes

| `AWS_S3_AUTH_MODE` | Variables | Use when |
|---|---|---|
| `static` | `AWS_S3_ACCESS_KEY_ID`, `AWS_S3_SECRET_ACCESS_KEY`, optional `AWS_S3_SESSION_TOKEN` | plain VPS (non-AWS); dedicated IAM user; rotate keys every 90 days |
| `profile` | `AWS_S3_PROFILE` (or `AWS_PROFILE`), `AWS_S3_SHARED_CREDENTIALS_FILE`, `AWS_S3_SHARED_CONFIG_FILE` (absolute) | keys managed by tooling in a credentials file; keep it in `/etc/connect/aws/` (0640 root:connect) because `ProtectHome=yes` hides `~/.aws` |
| `default_chain` (aliases `instance_role`, `iam_role`) | none | EC2 instance profile (IMDSv2), ECS task role, web identity, or `AWS_ACCESS_KEY_ID` env |
| `assume_role` | `AWS_S3_ROLE_ARN`, `AWS_S3_ROLE_EXTERNAL_ID`, `AWS_S3_ROLE_SESSION_NAME` (default `connect-media`), `AWS_S3_ROLE_DURATION_SECONDS` (900–43200) | short-lived credentials; source credentials are the static keys if set, else the profile, else the default chain |

Empty mode is inferred: role ARN → `assume_role`, keys → `static`,
`AWS_S3_PROFILE` → `profile`, otherwise `default_chain`. Conflicting settings
(for example static mode with a role ARN, or keys with `default_chain`) are
rejected. At startup the BFF resolves credentials once (STS is called in
`assume_role` mode) and refuses to start if that fails.

AWS Rekognition (photo moderation) still reads `AWS_S3_REGION` and
`AWS_S3_ACCESS_KEY_ID`/`AWS_S3_SECRET_ACCESS_KEY` when those are set, otherwise
its own default chain; give that identity `rekognition:DetectModerationLabels`
if you use it.

### IAM policies (least privilege)

`deploy/aws/iam-policy-connect-media.json` grants `s3:PutObject`,
`s3:GetObject`, `s3:DeleteObject` on the kind prefixes only, plus
`s3:ListBucket` limited to those prefixes (without it a `HEAD` of a missing
object returns 403 instead of 404, which breaks idempotent copies):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ConnectMediaObjects",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": [
        "arn:aws:s3:::connect-media-private-example/public/profile_photos/*",
        "arn:aws:s3:::connect-media-private-example/public/legacy_profile_photos/*",
        "arn:aws:s3:::connect-media-private-example/public/group_covers/*",
        "arn:aws:s3:::connect-media-private-example/quarantine/profile_photos/*",
        "arn:aws:s3:::connect-media-private-example/private/chapter_photos/*",
        "arn:aws:s3:::connect-media-private-example/private/theme_photos/*",
        "arn:aws:s3:::connect-media-private-example/private/voice/*",
        "arn:aws:s3:::connect-media-private-example/private/verification/*",
        "arn:aws:s3:::connect-media-private-example/profile-photos/*"
      ]
    },
    {
      "Sid": "HeadMissingObjectsReturn404NotAccessDenied",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::connect-media-private-example",
      "Condition": {"StringLike": {"s3:prefix": ["public/*", "quarantine/*", "private/*", "profile-photos/*"]}}
    }
  ]
}
```

Adjust the bucket names, add `AWS_S3_KEY_PREFIX` in front of each prefix if you
use one, repeat the `public/*` resources for `AWS_S3_PUBLIC_BUCKET` if you use a
second bucket, and drop the `profile-photos/*` lines if S3 mode never ran
before. With SSE-KMS also attach `deploy/aws/iam-policy-connect-media-kms.json`
(`kms:GenerateDataKey` and `kms:Decrypt` on the key, restricted with
`kms:ViaService=s3.<region>.amazonaws.com`) and allow the same principal in the
key policy.

For `assume_role`, attach the policies to the role and use
`deploy/aws/assume-role-trust-policy.json` (trusts the source IAM user and
requires `sts:ExternalId`); the source user needs only `sts:AssumeRole` on that
role ARN.

### Bucket settings

1. Block Public Access: all four settings on (both buckets).
2. Object Ownership: bucket owner enforced (ACLs disabled). The app never sets ACLs.
3. Default encryption: SSE-S3, or SSE-KMS with a customer key and Bucket Key.
4. Bucket policy `deploy/aws/bucket-policy-private.json`: denies non-TLS access
   and uploads without an encryption header (keep `AWS_S3_SSE` set when you use
   the second statement).
5. Versioning on, with `deploy/aws/bucket-lifecycle.json`: non-current versions
   expire after 30 days (7 days under `private/verification/`, so erased
   identity evidence does not linger), stray multipart uploads abort after one
   day, `_healthcheck` probes expire after a day.
6. Optional public bucket for redirect mode: front it with CloudFront using
   Origin Access Control (the bucket stays private) and set
   `AWS_S3_PUBLIC_BASE_URL=https://<distribution domain>`. CORS is not needed
   in proxy mode; in redirect mode allow `GET` from the web app origin.

## 5. Installing on the VPS

Paths used by the deploy files: sources in `/opt/connect/src` (the repo),
binaries in `/opt/connect/bin`, config in `/etc/connect`, state in
`/var/lib/connect`.

```bash
# 1) user, directories, permissions (idempotent)
sudo deploy/scripts/setup_media_storage.sh            # --dry-run to preview
sudo install -m 0644 deploy/tmpfiles.d/connect.conf /etc/tmpfiles.d/connect.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/connect.conf

# 2) binaries
cd /opt/connect/src/backend
for s in auth-svc profile-svc matching-svc chat-svc mobile-bff api-gateway mediactl; do
  go build -trimpath -o /tmp/connect-$s ./cmd/$s && sudo install -m 0755 /tmp/connect-$s /opt/connect/bin/$s
done

# 3) configuration (root:connect 0640)
sudo install -m 0640 -g connect backend/config/.env.example /etc/connect/connect.env        # then edit; remove storage lines;
#    bind services to loopback: API_GATEWAY_ADDR=127.0.0.1:8080, MOBILE_BFF_ADDR=127.0.0.1:8081
sudo install -m 0640 -g connect backend/config/storage.local.env.example /etc/connect/storage.env   # or storage.s3.env.example
sudo -u connect env ENVIRONMENT=production STORAGE_CONFIG_FILE=/etc/connect/storage.env \
  /opt/connect/bin/mediactl check -probe

# 4) services
sudo install -m 0644 deploy/systemd/connect-mobile-bff.service deploy/systemd/connect-backend@.service \
  deploy/systemd/connect-website.service deploy/systemd/connect.target /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now connect.target
sudo journalctl -u connect-mobile-bff -n 50 | grep -i "media storage"

# 5) nginx
sudo install -m 0644 deploy/nginx/connect.conf /etc/nginx/sites-available/connect.conf
sudo ln -sf /etc/nginx/sites-available/connect.conf /etc/nginx/sites-enabled/connect.conf
sudo nginx -t && sudo systemctl reload nginx
```

systemd hardening: `ProtectSystem=strict` with `ReadWritePaths` limited to
`/var/lib/connect/media` and `/var/lib/connect/spool` (BFF only),
`ProtectHome`, `PrivateTmp`, `NoNewPrivileges`, an empty capability set, a
`@system-service` syscall filter, `UMask=0027`. The other services cannot see
the media directory at all (`InaccessiblePaths`) and do not load
`storage.env`.

nginx (`deploy/nginx/connect.conf`): TLS, `client_max_body_size 25m`, `/v1/`
to the gateway (uploads streamed, not spooled), `/v1/realtime/` with WebSocket
upgrade (`/v1/realtime/chat`) and unbuffered event streams
(`/v1/realtime/notifications`), `/` to the website, `/metrics` denied,
`/readyz` loopback only. Media: an `internal` location aliases **only**
`public/`, with symlinks disabled, no directory listing, `GET`/`HEAD` only and
`Cache-Control: private, max-age=300`; any other path under the internal prefix
returns 404. It is reachable only through the API's `X-Accel-Redirect`, so
deleted, re-quarantined or blocked photos stop being served at once. Private
media is always streamed by the API with `Cache-Control: private, no-store`.

Logs: all services log to journald (`journalctl -u connect-mobile-bff`), so no
logrotate configuration is needed for them; set `SystemMaxUse=` in
`/etc/systemd/journald.conf` to cap journal size. nginx keeps its own logrotate
from the Ubuntu package.

## 6. Switching backends with `mediactl`

`mediactl copy` walks the source, copies each object under the same key,
verifies it by SHA-256 (S3 checksum or metadata, or `-verify download` to read
it back), skips objects that are already identical, and reports objects whose
bytes differ instead of overwriting them (`-overwrite` to replace). It is a dry
run unless `-apply` is given, and it never changes the database.

```bash
as_connect="sudo -u connect env ENVIRONMENT=production STORAGE_CONFIG_FILE=/etc/connect/storage.env"

# A. Old flat upload directory -> VPS layout
$as_connect /opt/connect/bin/mediactl copy -from legacy -legacy-dir /opt/connect/legacy/uploads/profile_photos -to local
$as_connect /opt/connect/bin/mediactl copy -from legacy -legacy-dir /opt/connect/legacy/uploads/profile_photos -to local -apply
#   then remove MEDIA_UPLOADS_DIR from storage.env and restart the BFF

# B. Local layout -> S3 (storage.env still says local_fs; S3 settings added to it)
$as_connect /opt/connect/bin/mediactl copy -from local -to s3            # dry run
$as_connect /opt/connect/bin/mediactl copy -from local -to s3 -apply     # copy + verify
#   switch FILE_STORAGE_BACKEND=aws_s3, restart, then copy again to catch
#   uploads made in between (identical objects are skipped):
$as_connect /opt/connect/bin/mediactl copy -from local -to s3 -apply
```

Keep the local directory (read-only backup) until the S3 deployment has run
cleanly for a while. `-kinds voice,verification` limits a run to some kinds.
Rehearsed locally: copying the 38 development files into a fresh VPS layout
reported `copied=38`, and a second run `identical=38`.

## 7. Backups

- **Local backend**: `deploy/scripts/backup_media.sh restic` (encrypted,
  deduplicated snapshots; excludes `tmp/`; `forget` keeps 7 daily / 4 weekly /
  3 monthly) or `… rsync` to mirror to another host. Back up PostgreSQL at the
  same time: it holds the keys. Retention must match the privacy policy,
  because erased members' files persist in older snapshots until those expire.
  Test a restore regularly.
- **S3 backend**: bucket versioning + the lifecycle rules above; optionally
  S3 Replication to a second region/account; AWS Backup for S3 if you need
  point-in-time restore. Restoring a deleted object means restoring the
  previous version under the same key.

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| BFF exits with `media storage self-check failed: … not writable` | run `setup_media_storage.sh`; check `ReadWritePaths` in the unit matches `MEDIA_STORAGE_ROOT` |
| `… must be a real directory (symlinks are refused)` | point `MEDIA_STORAGE_ROOT` at the real mount path instead of a symlink |
| `… are on different filesystems` | `tmp/` must sit on the same filesystem as the media directories (don't mount it separately) |
| `media storage configuration is invalid:` list | each line names the variable to fix |
| Uploads fail with HTTP 507 | free space below `MEDIA_MIN_FREE_MB`; grow the disk or move to S3 |
| Photos 404 behind nginx with the accel prefix set | nginx user not in the `connect` group (`id www-data`), or the site's `alias` path differs from `MEDIA_STORAGE_ROOT` |
| Photo bytes are empty without nginx | `MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX` is set but no nginx is in front; unset it |
| `resolve AWS credentials (S3Auth{mode=default_chain})` | no instance role on this host; use `static`, `profile` or `assume_role` |
| `AccessDenied` on HEAD of new objects / copy reports failures | add the `s3:ListBucket` statement with the prefix condition |
| `BadDigest` or checksum errors with an S3-compatible service | set `AWS_S3_SEND_CHECKSUMS=false` |
| `KMS.AccessDeniedException` | add the KMS policy and allow the principal in the key policy |
| Old photo URLs broke after enabling S3 | keep `AWS_S3_PROFILE_PHOTOS_PREFIX` at the value used before |

## 9. Owner actions still required

1. Pick the backend for launch. Local storage on the VPS is ready; for S3,
   create the bucket(s) (Block Public Access, ownership enforced, encryption,
   versioning, lifecycle, bucket policy) and choose an auth mode:
   instance role on EC2; otherwise an IAM user with a static key (or a role
   assumed with an external id).
2. Create the IAM user/role and attach the policies in `deploy/aws/` (and the
   KMS key and its key policy if you use SSE-KMS).
3. Install the deploy files on the VPS, replace `connect.example.com` and the
   certificate paths, run `mediactl check -probe`.
4. If any environment ran the old flat directory, copy it with
   `mediactl copy -from legacy … -apply`, then unset `MEDIA_UPLOADS_DIR`.
5. Schedule backups (restic/rsync timer, or S3 versioning/replication) and
   rehearse a restore.
6. The deploy files (systemd units, nginx site, tmpfiles) were not run on an
   Ubuntu host from this workstation (no nginx/systemd here); validate them
   with `nginx -t`, `systemd-analyze verify` and
   `systemd-analyze security connect-mobile-bff` on the VPS.
