# Rose GIF Gifts — Delta Execution Plan (19 Mar 2026)

## Why this document
This plan converts the product backlog (RG-101..RG-112) into a delivery delta based on current implementation in this monorepo.

## Live Validation Snapshot (19 Mar 2026)

### Verified green
- Backend runtime health checks are healthy (`/healthz`, `/readyz`).
- Gift catalog endpoint returns active free + paid entries (`/v1/chat/gifts`).
- Wallet read endpoint returns expected balance (`/v1/wallet/{userID}/coins`).
- Gift send lock guard path is working (`423 CHAT_LOCKED_REQUIREMENT_PENDING` when chat is locked).

### Verified blocked
- End-to-end success-path send demo is currently blocked in this environment by unlock policy + authorization context.
- Attempts to unlock via quest workflow returned `unauthorized quest action` for test identities.
- Because lock remains active, send success/timeline gift persistence evidence could not be captured in this run.

### Immediate unblock actions
1. Use an authorized test match pair that can complete quest template + submit + review in current environment.
2. Or temporarily run with `allow_without_template` unlock policy in local QA environment.
3. Re-run demo script to capture:
  - free send success
  - paid send success + wallet decrement
  - timeline gift message retrieval evidence

## Monorepo Mapping
- Flutter UI/client state: `app/lib/features/messaging/`
- Mobile BFF routes: `backend/internal/bff/mobile/server_gifts.go`
- Gift + wallet persistence: `backend/internal/bff/mobile/gifts.go`, `gifts_repository.go`
- API contract: `backend/internal/platform/docs/openapi.yaml`

## Story Status Matrix (as of 19 Mar 2026)

### Implemented (Ready for QA evidence closeout)
1) RG-101 — Inline rose tray in chat
- Status: Implemented
- Evidence: tray state + lock-state disable behavior in `chat_screen.dart`.

2) RG-102 — Free/paid cards + wallet balance
- Status: Implemented
- Evidence: wallet label and coin affordability handling in `chat_screen.dart`, `message_provider.dart`.

3) RG-103 — Preview + confirm flow
- Status: Implemented
- Evidence: modal preview + paid confirm path in `chat_screen.dart`.

4) RG-104 — Gift sends in chat timeline
- Status: Implemented
- Evidence: encoded gift payload + message bubble gift renderer in `message_provider.dart`, `message_bubble.dart`.

5) RG-105 — Catalog API (DB-backed)
- Status: Implemented
- Evidence: `/v1/chat/gifts` route + repository query + OpenAPI schema.

6) RG-107 — Wallet read/top-up API (MVP)
- Status: Implemented (MVP)
- Evidence: `/v1/wallet/{userID}/coins` and `/coins/top-up` plus activity event logging.

### Partially Implemented (Hardening needed)
7) RG-106 — Send gift API with wallet debit
- Status: Partial
- What exists:
  - gift send endpoint and insufficient-balance error path.
  - idempotency middleware includes `/chat/{matchID}/gifts/send`.
- Remaining gap:
  - strengthen debit+send durability semantics to avoid partial state under downstream failure.
  - add explicit operational audit/event model for retry/replay outcomes.

8) RG-110 — Gift telemetry + dashboards
- Status: Partial
- What exists:
  - activity events for wallet top-up and gift send.
- Remaining gap:
  - formalized event taxonomy for funnel (panel open, preview open, send success/fail, insufficient coins).
  - dashboard definitions and ownership.

9) RG-111 — Weekly limited rose drop
- Status: Partial
- What exists:
  - `is_limited` metadata on catalog items.
- Remaining gap:
  - schedule/rotation control and expiry activation workflow without deploy.

### Not Started
10) RG-108 — Daily login streak coins
11) RG-109 — Active session rewards with anti-idle
12) RG-112 — Abuse/fraud controls for economy

## Recommended Sprint Rebaseline

### Sprint 2 (Safety + instrumentation)
Goal: Production-safe spend flow and measurable funnel.

Commit:
- RG-106 (hardening)
- RG-110 (full telemetry)
- RG-107 (ops hardening)

Exit criteria:
- Idempotent replay tests for gift send retries are added.
- OpenAPI includes idempotency expectations and error envelope examples.
- Dashboard spec is published with event owners.

### Sprint 3 (Earning loops + abuse controls)
Goal: Retention loops with anti-abuse guardrails.

Commit:
- RG-108
- RG-109
- RG-112

Exit criteria:
- Daily earn caps and cooldowns are policy-configurable.
- Anti-idle checks are enforced for session rewards.
- Rule-based anomaly events and response actions are feature-flagged.

### Sprint 4 (Monetization novelty)
Goal: Increase conversion and content freshness.

Commit:
- RG-111 completion
- starter/bundle offers follow-up stories

Exit criteria:
- weekly limited drop schedule is runtime-configurable.
- experiment flags exist for offer variants.

## Engineering Task List (next 10 working days)
1. Add gift-send resilience test cases for network retry + downstream partial failure.
2. Add explicit idempotency examples to OpenAPI for gift send route.
3. Define and emit `gift_panel_opened`, `gift_preview_opened`, `gift_send_attempted`, `gift_send_succeeded`, `gift_send_failed_insufficient_coins`.
4. Add analytics payload field dictionary (required properties + owners).
5. Add admin/report view requirement for wallet mutation audit trail.
6. Define configurable policy values: daily earn cap, reward cooldown, anti-idle minimum interaction threshold.
7. Implement daily streak coin award endpoint + tests.
8. Implement session reward evaluator with anti-idle checks + tests.
9. Implement anomaly detector for reward/send velocity and throttle action path.
10. Add rollout playbook with feature flags per story.

## Feature Flag Plan
- `rose_gifts_enabled` (already implied by UI gating patterns)
- `rose_wallet_topup_enabled`
- `rose_rewards_enabled`
- `rose_anti_abuse_enforced`
- `rose_limited_drop_enabled`

## DoR / DoD Addendum (Delta)
Before story start:
- API schema, feature flag, and event list must be attached.
- Failure-mode behavior must be listed (retry, duplicate, partial failure).

Before story close:
- Unit/integration tests pass.
- OpenAPI updated and contract snapshot synced.
- Dashboard/event validation evidence attached.
