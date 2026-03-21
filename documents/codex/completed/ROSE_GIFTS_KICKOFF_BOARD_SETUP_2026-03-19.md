# Rose GIF Gifts — Kickoff Board Setup (19 Mar 2026)

## Board Columns
1. Backlog
2. Ready
3. In Progress
4. Code Review
5. QA Validation
6. Done
7. Blocked

## Working Agreements
- WIP limit: max 3 tickets per engineer in `In Progress`.
- Every story in `Ready` must include API schema examples + analytics event notes.
- Any blocker > 24h must be moved to `Blocked` with owner and ETA.

## Sprint 1 Initial Placement

### Done
- RG-101 — Inline rose tray in chat
- RG-102 — Free/paid gift cards + wallet balance visibility
- RG-103 — Preview + confirm send flow
- RG-104 — Gift events in chat timeline
- RG-105 — DB-backed gift catalog API

### QA Validation
- ✅ RG-101..RG-105 QA evidence package (API smoke + UI evidence artifact)

### Blocked
- (none)

### Done (Sprint 2 hardening)
- RG-106 — Send gift API with wallet debit consistency/idempotency hardening
- RG-107 — Wallet read/top-up hardening + audit visibility
- RG-110 — Gift telemetry taxonomy + dashboard baseline

### Backlog (Sprint 3+)
- RG-108 — Daily streak coin rewards
- RG-109 — Active session rewards + anti-idle
- RG-112 — Abuse/fraud controls
- RG-111 — Weekly limited rose drop

## Owner Map
- PM owner: catalog mix, free-share guardrail, sprint acceptance
- Backend owner: RG-106/RG-107 service hardening and unlock test context
- Flutter owner: tray/send UX and fallback behavior
- Data owner: RG-110 event dictionary + dashboard definitions
- Trust owner: abuse policy thresholds and response actions

## Ceremony Cadence
- Sprint planning: 90 min
- Daily standup: 15 min
- Mid-sprint risk review: 30 min
- Sprint review: 60 min
- Retro: 45 min

## Definition of Ready Checklist (ticket-level)
- [x] Acceptance criteria measurable
- [x] API/request-response example attached
- [x] Feature flag strategy attached
- [x] Analytics events + owner listed
- [x] QA scenarios listed

## Definition of Done Checklist (ticket-level)
- [x] Unit/integration tests pass
- [x] OpenAPI updated when API changes
- [x] Feature behind rollout flag
- [x] Error + idempotency behavior validated
- [x] Analytics events verified in logs/dashboard
