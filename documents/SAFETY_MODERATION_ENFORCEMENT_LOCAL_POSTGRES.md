# Safety, Moderation, Verification, and Admin Enforcement

Date: 2026-08-03  
Status: implemented and end-to-end verified  
Migration: `055_safety_moderation_enforcement.sql`

## Security invariant

Every operator action is authorized by the database-backed bearer principal.
Caller-provided admin headers do not establish authority. A suspend or ban is
committed in one PostgreSQL transaction with active-session revocation and an
append-only security event. Bearer validation checks active, banned, and
effective-suspension state on every protected request.

The previously vulnerable sequence was reproduced before the patch:

```text
authenticated request before ban = 200
admin ban                         = 200
same bearer token after ban       = 200  (vulnerable)
```

After the patch:

```text
authenticated request before ban = 200
admin ban                         = 200
same bearer token after ban       = 401
password login while banned       = success=false
```

The same next-request rejection and login refusal were verified for a timed
suspension. Unban/unsuspend restore eligibility but do not resurrect revoked
sessions; the user must authenticate again.

## Native PostgreSQL workflows

- Block and unblock use `user_management.blocked_users` and append security
  events in the same transaction.
- Reports use row-locked state transitions in
  `matching.moderation_reports`; resolved reports cannot be actioned again.
- Appeals require a report belonging to the authenticated reported user. The
  persisted state machine is `submitted -> under_review -> resolved_upheld |`
  `resolved_reversed`.
- Verification review synchronizes `matching.verification_states` and
  `user_management.users.is_verified` in one transaction.
- SOS creation computes a persisted priority deadline; admin queue reads the
  correct `matching.sos_alerts` table, and resolution is row-locked and audited.
- Ban, suspension, session revocation, and operator audit are atomic.

There is no memory fallback in the production local runtime. The older
transport-neutral compatibility paths remain unreachable from native local
composition and are retained only for existing non-production compatibility
tests.

## SLA policy and indexes

- Moderation appeals: 48 hours.
- Moderation reports: 24 hours.
- Verification review: 24 hours from submission.
- SOS response: critical 2 minutes, high 5 minutes, medium 15 minutes, low 30
  minutes.

Partial indexes cover only open queue rows and order by deadline, keeping the
operator SLA scans small. Live proof showed a 48-hour appeal deadline, a
5-minute high-priority SOS deadline, and resolution before the stored appeal
deadline. Automated tests assert the 48-hour and high-priority SOS calculations
and the required migration/index controls.

## Immutable audit boundary

`audit.security_events` stores actor, role, subject, resource, transaction ID,
timestamp, and event-specific JSON. A database trigger rejects both update and
delete. User IDs deliberately have no foreign key from this table so account
deletion cannot rewrite historical audit identity.

Live verification attempted both operations; each failed with
`audit.security_events is append-only`. Events were verified for report and
appeal transitions, verification, SOS, block/unblock, ban/unban, and
suspend/unsuspend.

## Verification commands

```text
go test ./internal/bff/mobile ./internal/modules/verification/... \
  ./internal/services/auth ./internal/platform/postgres
go test ./...
```

The migration was applied to
`postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable`, rerun
successfully to prove idempotency, and recorded as
`055_safety_moderation_enforcement`.
