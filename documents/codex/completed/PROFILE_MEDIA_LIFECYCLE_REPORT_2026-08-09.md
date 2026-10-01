# Profile Media Lifecycle and Quality — Completion Report

Date: 2026-08-09  
Runtime: Native local PostgreSQL and local filesystem; no Docker, Supabase,
PostgREST, or Supabase Realtime.

## Outcome

The media lifecycle/profile-quality beta gate is functionally complete for the
local runtime. A photo is no longer considered accepted merely because a file
was written: content validation, filesystem persistence, PostgreSQL metadata,
profile-draft state, quotas, lifecycle state, and workflow activity are handled
as one recoverable workflow.

## Enforced policy

- Maximum 5 active profile photos.
- Maximum 10 MB per photo and 50 MB active storage per user.
- Width and height must each be 300-4096 pixels.
- Accepted content: JPEG, PNG, WebP, and HEIC/HEIF-compatible HEIC brands.
- File type is derived from bytes, not the client filename or MIME claim.
- Metadata-only URL insertion is rejected with HTTP 415.
- Local uploads are rejected with HTTP 507 below 500 MB filesystem headroom.
- Completed mutable drafts have 30-day safety retention; durable profile
  snapshots remain available after draft payload purge.
- Staged media receives an expiry; deleted media enters a retryable cleanup
  state before the row is finalized as deleted.

## PostgreSQL migration

Migration `056_profile_media_lifecycle.sql` adds:

- original filename, canonical MIME, dimensions, byte size, SHA-256,
  lifecycle, retention, deletion, and moderation fields to profile photos;
- database checks for size, dimensions, MIME, lifecycle, and moderation state;
- a partial unique active-photo ordering index and cleanup/retention indexes;
- completed-draft retention/purge fields;
- durable `profile_snapshots` so retention cleanup does not destroy the active
  profile representation.

The migration was applied to `127.0.0.1:55432/dating_app` and passed two
consecutive idempotent applications. The schema marker is
`056_profile_media_lifecycle`.

## Backend behavior

- Multipart bytes are validated before persistence and assigned server UUIDs.
- The photo row is inserted immediately instead of waiting for profile
  completion.
- Count/storage quota checks and draft/activity updates run in serializable,
  user-locked PostgreSQL transactions.
- Reorder requires the exact active-photo set and uses collision-safe two-phase
  ordering.
- Delete soft-marks the row, updates/reorders the draft transactionally,
  removes the object, then marks the row deleted. Failed object deletes remain
  retryable.
- Cleanup runs at BFF startup and hourly. It handles lifecycle candidates,
  completed draft purge, and unreferenced local files older than 24 hours.
- Moderation fields are present from upload time (`pending`) for provider or
  operator workflow integration.

## Flutter behavior

- The screen explains format, dimension, item-size, and total quota rules.
- Server validation messages are surfaced instead of a generic upload error.
- Delete requires explicit confirmation.
- Failed delete/reorder restores the previous ordered state and propagates an
  actionable error.
- Upload disables conflicting delete/reorder/primary actions.
- Durable metadata is parsed into `ProfilePhotoItem`; HEIC uses native decoding
  when available and a labelled fallback thumbnail otherwise.
- Provider initialization reloads the durable draft for resume.

## Verification evidence

- `go test ./...`: passed.
- Full Flutter suite: 463 tests passed.
- Media/profile targeted `flutter analyze`: no issues.
- Debug Android rebuild: `app/build/app/outputs/flutter-apk/app-debug.apk`.
- `scripts/verify_profile_media_lifecycle.sh`: passed against the live local
  stack and proved:
  - metadata-only upload rejected with 415;
  - five-photo quota enforced with 409 and no orphan object;
  - canonical dimensions/MIME/size/hash persisted for every active photo;
  - reorder persisted;
  - delete removed the filesystem object and finalized lifecycle state;
  - completed draft resumed with stable ordering;
  - 30-day retention timestamp persisted.

The local PostgreSQL services and API gateway were rebuilt and left running on
ports 55432, 18081, and 18080 respectively.
