# Notification Push Production Integration — Implementation Report

Date: 2026-08-09  
Database: native PostgreSQL on `127.0.0.1:55432`; no Docker, Supabase,
PostgREST, or Supabase Realtime.

## Outcome

The production integration code is implemented. The BFF can select direct FCM
HTTP v1, direct APNs HTTP/2, the existing webhook bridge, or disabled local-only
delivery. Flutter now owns permission, real-token registration/refresh,
background receipt evidence, logout cleanup, and background/terminated tap
routing for incoming calls and match nudges.

Provider credentials are deliberately file-mounted and remain absent from this
repository. Therefore the signed physical-device acceptance matrix is still a
release blocker; it is not represented as a passing test.

## Provider behavior

- FCM uses a service-account JWT assertion to obtain a short-lived OAuth token
  and sends to the HTTP v1 project endpoint.
- APNs uses an ES256 `.p8` provider token refreshed every 50 minutes and sends
  over an HTTP/2-capable client with topic, push-type, priority, collapse, and
  expiry headers.
- Incoming calls use a 45-second TTL and the high-importance
  `incoming_calls` Android channel. Match nudges use a six-hour TTL.
- FCM `UNREGISTERED`/sender mismatch and APNs bad/unregistered token responses
  disable only the affected device. Provider authentication/configuration
  failures remain retry/dead-letter events and do not erase healthy tokens.
- Service-account JSON, APNs `.p8`, and raw device tokens are never logged or
  bundled into Flutter.

## Flutter behavior

- Firebase client configuration is opt-in; local development remains fully
  functional with empty identifiers.
- Android 13 notification permission and high-importance activity/call channels
  are declared. iOS has the APNs entitlement, remote-notification background
  mode, and call/nudge categories.
- Android registers FCM. iOS registers FCM by default or the raw APNs token when
  `PUSH_TOKEN_PROVIDER=apns` is selected.
- Token refresh upserts through the bearer-authenticated device endpoint, and
  logout disables the registered device before revoking the session.
- `onMessageOpenedApp` and `getInitialMessage` route to match nudges or the
  incoming-call detail UX. The background entry point writes receipt evidence
  without attempting UI work from a background isolate.

## PostgreSQL and SLOs

Migration `061_notification_production_slos.sql` is applied and recorded in
`public.schema_migrations`. It extends the queue view with 15-minute push
attempt, delivered, dead-letter, success percentage, and outbox-to-provider p95
latency values.

Release thresholds are:

- queue depth <= 1,000;
- oldest pending age <= 30 seconds;
- 15-minute provider success >= 99%;
- 15-minute push p95 <= 10 seconds when traffic exists;
- no dead letters in the acceptance cohort.

The admin metrics contract returns both observations and evaluated thresholds.
Prometheus gauges and alerts cover success and p95. The executable
`notification_queue_slo_check.sh` gate passes against the current local queue.

## Verification

- Direct FCM payload/auth/message-ID and invalid-token contract tests: pass.
- Direct APNs headers and bad-token classification test: pass.
- Provider configuration validation tests: pass.
- Flutter background receipt test: pass.
- Changed Flutter analysis scope: no issues.
- Android debug build with Firebase Messaging: pass.
- Local migration 061 and queue view query: pass.
- Local queue SLO gate: pass with depth 0, age 0, success 100%, and no traffic.
- Isolated current-source BFF live readback: authenticated admin endpoint returned
  the expanded metrics plus `slo.met=true`; the isolated process was then shut
  down without disturbing the existing app stack.
- Full repository regression: all Go tests and backend compliance pass; all 474
  Flutter tests pass; Android debug APK build passes.

## Remaining operational gate

Mount live credentials, register signed physical devices, run
`notification_push_preflight.sh`, and execute every case in
`NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md`. Capture provider
message IDs, database delivery rows, OS/app versions, timestamps, tap routes,
and the post-burst SLO output. Until that evidence exists, the correct status is
"production integration implemented; physical-device sign-off pending."
