# Rose GIF Gifts — Completed vs Pending Tasks (From MD Docs)

Generated on: 19 Mar 2026
Source documents:
- `documents/codex/completed/ROSE_GIFTS_KICKOFF_BOARD_SETUP_2026-03-19.md`
- `documents/codex/completed/ROSE_GIFTS_SPRINT_01_EXECUTION_PLAN_2026-03-19.md`
- `documents/codex/ROSE_GIFTS_DELTA_EXECUTION_PLAN_2026-03-19.md`
- `documents/codex/ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md`

## Completed Tasks

### Sprint 1 stories marked done/implemented
- RG-101 — Inline rose tray in chat.
- RG-102 — Free/paid gift cards + wallet balance visibility.
- RG-103 — Preview + confirm send flow.
- RG-104 — Gift events in chat timeline.
- RG-105 — DB-backed gift catalog API.

### Implementation/validation items marked complete in docs
- UI tray behavior and lock-state handling validated.
- Free vs paid card states and wallet visibility validated.
- Preview + confirm send flow implemented.
- Gift event rendering in chat timeline implemented.
- Catalog API documented in OpenAPI.
- Runtime/API checks passing in docs:
  - `GET /v1/chat/gifts`
  - `GET /v1/wallet/{userID}/coins`
  - lock-path for `POST /v1/chat/{matchID}/gifts/send` (`423 CHAT_LOCKED_REQUIREMENT_PENDING`).

### Completed hardening (new in this iteration)
- RG-106 — Send gift API hardening completed (idempotency replay safety validation + enriched send telemetry dimensions).
- RG-107 — Wallet read/top-up hardening completed (production-like approver guard, audit receipt metadata, wallet audit endpoint).
- RG-110 — Telemetry/dashboard baseline completed (event taxonomy + admin analytics funnel coverage).

## Pending Tasks

### Blocked / closeout pending (Sprint 1)
- None.

### Ready / in-progress hardening (Sprint 2)
- None (RG-106, RG-107, RG-110 are completed).

### Partial / not complete per delta status
- RG-111 — Partial (needs weekly schedule/rotation controls).

### Not started / backlog
- RG-108 — Daily streak coin rewards.
- RG-109 — Active session rewards + anti-idle.
- RG-112 — Abuse/fraud controls.
- RG-111 — Weekly limited rose drop (completion backlog).

### Checklist-level pending items (DoR/DoD)
- Ticket-level DoR checklist items are now checked in kickoff doc.
- Ticket-level DoD checklist items are now checked in kickoff doc.

## Note on doc status mismatch
- Kickoff board marks RG-107 as Ready (Sprint 2), while Delta plan marks RG-107 as Implemented (MVP) with remaining hardening tasks.
- Recommended interpretation: treat RG-107 as "implemented but not production-complete".
