# Backend-only user journeys — Flutter completion report

Date: 2026-08-09  
Runtime: local API Gateway/Mobile BFF + native PostgreSQL  
Excluded: Docker, Supabase, external payment providers

## Outcome

The previously backend-only calls, SOS, match-nudge, and subscription operations now have discoverable Flutter journeys backed by the existing authenticated API contracts.

## Implemented

### Calls

- Start a call session from a match's action sheet.
- Request camera and microphone permissions before creating the session.
- Local mute/camera controls and an explicit end action.
- Persisted call history with status, duration, date, and match reference.
- Honest UI copy that live audio/video transport is unavailable until a media provider and room-token contract exist.

### Emergency SOS

- Prominent entry from Privacy & Safety.
- High/critical severity selection, message capture, and destructive confirmation.
- One-time foreground location request with a supported no-location fallback.
- Success confirmation states whether location was recorded.
- Durable alert history with severity, status, timestamp, location presence, and resolution note.

### Match nudges

- Send a nudge from a match action sheet or the Match Nudges screen.
- Server daily-cap and safety-suppression errors are shown to the user.
- Notification-click and conversation-resume API hooks are implemented for the notification-delivery epic to call.

### Subscriptions

- Browse durable subscription plans.
- View current plan/entitlement state and payment history.
- Activate a local monthly/yearly subscription with an idempotency key.
- UI clearly identifies local PostgreSQL ledger behavior and does not claim a real provider charge.

### Platform and contract work

- Android camera, microphone, and foreground-location permissions.
- iOS camera, microphone, and foreground-location usage descriptions.
- Typed OpenAPI payloads for calls, SOS, nudges, conversation resume, plans, subscriptions, and payments.
- OpenAPI open-object ratchet reduced from 40 to 35.

## Verification

- Flutter provider tests cover successful calls, permission denial, call end/history state, SOS with and without coordinates, nudge success, nudge daily-cap failure, subscription loading, and idempotent activation.
- Changed Flutter files analyze without errors or warnings; repository-wide informational lint debt remains pre-existing.
- Local API Gateway health returned HTTP 200.
- Authenticated local calls returned HTTP 200 for call history, SOS history, billing plans, current subscription, and payment history.
- OpenAPI semantic tests pass and the YAML parses successfully.
- No emulator installation was attempted because emulator `/data` has only about 546 MB free.

## Remaining dependency-bound scope

1. Live call media: select WebRTC/media provider and define room credentials, signaling, incoming-call, timeout, and reconnect contracts.
2. Push notification delivery: connect match-nudge notification payloads to the durable notification outbox, device tokens, deep links, retry/dead-letter behavior, and preferences.
3. Subscription cancellation/refund/provider checkout: define API contracts, select a payment provider, and provision test/live credentials plus receipt verification.
4. Emulator/Appium E2E: clear emulator storage, then automate permission allow/deny, SOS confirmation, nudge cap, call lifecycle, and subscription activation.

These residuals belong to the media-provider, notification-delivery, billing-provider, and QA epics; they are not hidden behind simulated success in the Flutter UI.
