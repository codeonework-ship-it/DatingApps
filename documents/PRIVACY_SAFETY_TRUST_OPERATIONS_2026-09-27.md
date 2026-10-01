# Privacy, safety and production trust operations — 27 September 2026

## Decision

The P0 local architecture controls are implemented and machine checked. The
production decision remains **NO_GO** because production trust requires real
providers, deployed controls and named people. Repository code cannot truthfully
manufacture that evidence.

The canonical policy is
`documents/contracts/trust_operations.v1.json`. Its contract gate runs from
`qa/governance/run_release_governance_gate.sh`, and release regression requires
migration `076_privacy_safety_trust_operations`.

## Delivered controls

- Account export uses the current matches and messages schema and fails the
  request if any allow-listed section cannot be produced. A partial payload is
  never stored as a completed export.
- Account erasure collects object paths from profile photos, identity document
  evidence, verification selfies and voice recordings. It deletes those objects
  through the existing retrying storage-release pass and clears the database
  evidence, voice transcript and media metadata.
- Existing chat and notification WebSockets recheck the session and account on
  each poll. Revoked, expired, disabled, inactive, banned, suspended,
  deactivated, deletion-pending and erased accounts are disconnected. Chat
  outbox reads also re-evaluate active match, unmatch and both-direction block
  state before delivering a queued event.
- SOS creation and trusted-contact delivery commit together. Each contact gets
  an idempotent outbox job with retry, dead-letter, response deadline and
  operator metrics. Successful HTTP 2xx means the configured downstream
  provider durably accepted the request; it does not mean emergency services
  were contacted. Resolving the alert cancels unsent work. Sensitive snapshots
  are redacted after 30 days.
- Report, appeal and identity-verification status changes use the existing
  durable notification engine. The contract promises in-app plus configured
  push and no longer claims email exists.
- The existing Rekognition provider remains fail closed when moderation is
  required. The existing production preflight must still pass against the real
  private S3 bucket, IAM policy and labelled fixtures.

## Approved retention classes

The policy records the deletion grace (14 days), export expiry (7 days), SOS
snapshot redaction (30 days), revoked-session target (90 days), safety/audit
target (24 months), verification evidence limit and rolling backup target (30
days). Legal holds are explicit exceptions, not silent retention.

Policy approval does not prove that every production scheduler, backup system
or legal-hold workflow is active. Those controls are named as blocking evidence
and keep the launch gate closed.

## Production closure requirements

Before changing trust operations to `GO`, attach all of the following:

1. Six named eight-hour shifts covering the first 48 hours, each with primary,
   backup, appeals owner and SOS on-call; name the Trust and Safety manager and
   incident commander.
2. A paging rehearsal proving the 15-minute acknowledgement and 30-minute
   containment targets, plus missed-SOS acknowledgement escalation.
3. SOS provider delivery/dead-letter acceptance and approved user-facing copy.
4. Private S3/Rekognition, quarantine access and provider-failure acceptance.
5. Deployed operator SSO/MFA, managed secrets, provisioning and offboarding,
   role denial and active-session revocation evidence.
6. Production retention jobs, backup restore, erasure propagation and legal-hold
   evidence.

## Verification completed

- All backend Go tests passed.
- `go vet ./...` passed.
- Focused WebSocket, export/erasure and SOS webhook tests passed.
- Release and trust governance contract gates passed in contract mode.
- Local migration 076 applied successfully.
- Event architecture gate passed with 116 registered mutable event sources.
