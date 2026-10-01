# Production deployment readiness — 27 September 2026

## Implemented release surface

- The browser member app is built under `/app/` and served with the public
  website through the same-origin Node proxy.
- Hosted checkout opens the URL returned by the separately owned billing API
  and waits for backend-confirmed state. No browser redirect is treated as a
  successful payment.
- Active call sessions return a shared HTTPS provider-room URL. Development
  defaults to Jitsi Meet; production returns no room URL until an approved host
  is configured.
- Voice icebreakers capture 20–45 seconds from the microphone and upload a
  signature-validated WebM, Ogg, M4A, or WAV file to private storage. Storage
  keys are omitted from member responses.
- Verification sends identity-document and selfie bytes as authenticated
  multipart data. Both images are validated, stored under a private namespace,
  referenced through protected metadata, and removed on a failed submission.
- Call start/history/end, voice send, and verification submission bind the
  requested member ID to the authenticated local session. Only a call
  participant can end the call.

## Required production configuration

The deployment must supply these values through the platform secret manager.
They must not be embedded in Flutter assets or the website bundle.

| Area | Required configuration |
|---|---|
| Public edge | HTTPS domain, WSS support, trusted forwarded-host policy, health checks |
| API | `ENVIRONMENT=production`, public gateway origin, private BFF/upstream networking |
| Database | managed PostgreSQL URL, TLS verification, backups, restore test, migration 073 |
| Private media | `FILE_STORAGE_BACKEND=aws_s3`, private bucket, region and workload credentials |
| Calls | `CALL_ROOM_BASE_URL` pointing to the approved private Jitsi-compatible deployment |
| Billing | provider and webhook secrets from the separate billing release |
| Moderation | approved production media-moderation provider and credentials |
| Notifications | production FCM/APNs or approved bridge credentials |
| Policies | approved terms, privacy policy, retention schedule and identity-review operating procedure |

## Remaining release gates

Production deployment is not complete. A hosting account, domain, TLS/control
plane, production database, private object store, private call-room host,
identity-review provider and production secrets were not supplied in this
workspace. Publishing before those inputs exist would disable calls or weaken
the private-media and payment boundaries.

Before traffic is enabled:

1. Apply migrations through `073_private_identity_and_voice_media` to the target
   database and record the migration ledger.
2. Configure private object lifecycle rules that match the approved identity
   and voice retention policy. Public-read access must remain disabled.
3. Set a private `CALL_ROOM_BASE_URL`; do not use the development
   `meet.jit.si` default for production.
4. Complete the separate billing provider/webhook acceptance and reconcile a
   test-mode checkout before live credentials are introduced.
5. Run the Go suite, all Flutter tests, the release web build, Playwright tests,
   a two-participant physical-device call, a real microphone recording, and a
   reviewer-access identity submission in the target environment.
6. Verify backup restore, alert delivery, rollback, secret rotation and account
   erasure of the newly referenced private media.

## Current local evidence

- Backend: `go test ./...` passes.
- Flutter: 872 tests pass, including the responsive screen matrix and the
  account-saved Star Wars preset.
- Browser: the member-route matrix covers both 390 px and 1440 px, including
  hosted-checkout controls, microphone capture and verification entry.
- Android: the debug APK builds, installs and launches on the ARM64 emulator.
- Live local API checks confirmed a Jitsi join URL, participant-ended call,
  private identity submission with `evidence_received=true`, and a voice send
  with `has_audio=true` and no leaked storage path.

These results validate the local integration. They do not substitute for the
target-environment acceptance gates above.
