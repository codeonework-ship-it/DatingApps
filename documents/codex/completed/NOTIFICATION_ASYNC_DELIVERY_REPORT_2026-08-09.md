# Notification and Asynchronous Delivery — Completion Report

Date: 2026-08-09  
Runtime: Native local PostgreSQL; no Docker, Supabase, PostgREST, or Supabase
Realtime.

## Outcome

The functional local notification engine is complete. Notification intent is
created in the same PostgreSQL transaction as the domain write, delivery is
recoverable across process restarts, and Flutter owns an authenticated global
stream instead of depending on a feature screen being open.

External background push now has native FCM HTTP v1 and APNs HTTP/2 adapters in
addition to the idempotent webhook bridge. Flutter real-token lifecycle and
background/terminated tap handling are also implemented. Live signed-device
acceptance remains operationally pending because no provider credentials or
physical devices are configured in this workspace. See
`NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md`.

## PostgreSQL migration

Migration `057_notification_delivery_engine.sql` adds:

- category and channel preferences for match nudges, incoming calls, safety,
  in-app delivery, and push delivery;
- `user_management.device_push_tokens`, including disable/failure state;
- `matching.notification_outbox`, with a monotonic replay sequence, unique
  dedupe key, priority, lease, retry, dead-letter, and expiry state;
- `matching.user_notifications`, including read and dismiss state;
- `matching.notification_deliveries`, including per-channel/per-device
  attempts and provider message IDs;
- partial claim, unread, replay, active-device, and stale-lease indexes;
- queue metrics and dead-letter views.

Triggers enqueue likes, mutual matches, messages, match nudges, and incoming
calls. `ON CONFLICT (dedupe_key) DO NOTHING` makes producer retries safe.

The migration was applied idempotently to
`127.0.0.1:55432/dating_app` and recorded as
`057_notification_delivery_engine`. The local runtime now contains 94 base
tables across `user_management` and `matching`.

## Worker and push boundary

- Multiple workers claim priority batches with `FOR UPDATE SKIP LOCKED`.
- Network calls never occur while a database transaction is held.
- In-app insertion and delivery recording are idempotent.
- Disabled categories or channels produce a terminal suppressed outbox state.
- Transient provider errors use bounded quadratic backoff and exhaust into a
  dead letter; HTTP 400/404/410 permanently disables the affected device.
- Processing leases older than two minutes are recovered on startup.
- Expired pending events are suppressed rather than remaining in queue depth.
- The optional push bridge receives an opaque device token, event envelope,
  bearer credential, and stable `Idempotency-Key`.

Configuration is documented through:

- `NOTIFICATION_WORKER_COUNT`
- `NOTIFICATION_BATCH_SIZE`
- `NOTIFICATION_POLL_INTERVAL_MS`
- `NOTIFICATION_MAX_ATTEMPTS`
- `NOTIFICATION_PUSH_WEBHOOK_URL`
- `NOTIFICATION_PUSH_WEBHOOK_TOKEN`

## API and security

The authenticated API now provides:

- inbox pagination and monotonic resume cursors;
- unread count, mark-one/read-all, and dismiss;
- category/channel preference GET/PATCH;
- push-device register/disable without echoing the raw token;
- resumable `/v1/realtime/notifications` WebSocket;
- admin-only queue/dead-letter telemetry.

Notification paths participate in the platform ownership middleware. Live
negative testing proved that one bearer principal cannot read another user's
inbox (`403`). The administrative metrics path remains protected by admin RBAC.

## Flutter behavior

- The signed-in app shell starts one bearer-authenticated notification stream.
- Reconnect uses exponential backoff and the last durable sequence.
- Inbox, unread badge, read-all, read-one, swipe-to-dismiss, and pull-to-refresh
  are implemented.
- Settings cover in-app, push, match, message, like, nudge, incoming-call, and
  safety delivery.
- Match nudges surface as foreground banners.
- Incoming calls surface as a global call sheet even when the call/history
  screens are not open.
- The notification inbox is included in the five-device responsive layout
  matrix and maintains the repository's 4-point spacing floor.

## Verification evidence

- `go test ./...`: passed.
- Full Flutter suite: 471 tests passed.
- Notification Flutter analyzer scope: no issues.
- Repository-wide Flutter analysis is down to 370 pre-existing catalog/style
  findings; every file touched for this notification implementation is clean.
- Debug Android rebuild:
  `app/build/app/outputs/flutter-apk/app-debug.apk`.
- OpenAPI route coverage and open-object ratchet: passed.
- Push adapter tests proved stable idempotency headers, bearer forwarding,
  response message IDs, and permanent invalid-token classification.
- Live native PostgreSQL proof created two credential-authenticated users and
  demonstrated:
  - mutual match -> `match.created`;
  - match nudge -> `match_nudge.received`;
  - call start -> `call.incoming`;
  - unread count changing after mark-read;
  - disabled nudge preference suppressing the next nudge;
  - zero queued, processing, or dead-letter jobs after delivery;
  - all delivered inbox records surviving a complete backend restart.

## Remaining operational acceptance

Supply production credentials and signed physical devices, then run the
documented foreground/background/terminated acceptance matrix plus the
production-shaped queue-SLO burst. The adapters and client lifecycle no longer
remain implementation work; only credentialed device and load sign-off remain.
