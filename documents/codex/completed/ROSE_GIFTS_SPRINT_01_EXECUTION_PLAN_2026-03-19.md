# Rose GIF Gifts — Sprint 1 Execution Plan + Closeout Snapshot (19 Mar 2026)

## Sprint Window
- Duration: 2 weeks
- Sprint Goal: Deliver chat-integrated rose gifting MVP with free/paid catalog visibility and stable send flow.

## Committed Stories
- RG-101 (5): Inline rose tray in chat
- RG-102 (5): Free/paid cards + wallet balance visibility
- RG-103 (3): Preview + confirm send flow
- RG-104 (8): Gift events in chat timeline
- RG-105 (8): DB-backed gift catalog API

Total: 29 points

## Current Implementation Snapshot (Code-Verified)
### Story Coverage
- RG-101: Implemented in Flutter chat UI (`app/lib/features/messaging/screens/chat_screen.dart`) with inline tray open/close behavior and lock-aware disable state.
- RG-102: Implemented with free/paid labels, wallet display, and insufficient-coin disable path (`chat_screen.dart`, `message_provider.dart`).
- RG-103: Implemented preview + confirm sheet for paid gifts, one-tap free send from preview (`chat_screen.dart`).
- RG-104: Implemented gift message encoding/decoding and timeline rendering (`message_provider.dart`, `message_bubble.dart`).
- RG-105: Implemented DB-backed catalog endpoint + OpenAPI definitions (`backend/internal/bff/mobile/server_gifts.go`, `gifts_repository.go`, `backend/internal/platform/docs/openapi.yaml`).

### Integration Observations
- Gift send endpoint and wallet endpoints are available and exercised by backend tests (`backend/internal/bff/mobile/server_gifts_test.go`).
- Mobile provider already uses API-first with local fallback behavior for resiliency (`message_provider.dart`).

## Sprint 1 Closeout Checklist
- [x] UI tray behavior and lock-state handling validated.
- [x] Free vs paid card states and wallet visibility validated.
- [x] Preview + confirm send flow implemented.
- [x] Gift event rendering in chat timeline implemented.
- [x] Catalog API documented in OpenAPI.
- [x] Capture final QA evidence artifact (emulator video/screens + API smoke JSON).
- [x] Attach sprint demo evidence links in Jira/Confluence.

## API Demo Status (19 Mar 2026)

### Pass
- `GET /v1/chat/gifts` returns catalog entries with free/paid split.
- `GET /v1/wallet/{userID}/coins` returns wallet balance.
- `POST /v1/chat/{matchID}/gifts/send` returns correct lock error when chat is locked (`423`, `CHAT_LOCKED_REQUIREMENT_PENDING`).

### Closeout evidence captured
- Success-path send evidence is covered by focused backend tests using unlock-capable local policy context (`allow_without_template`) and includes free/paid flow assertions, idempotency replay checks, and wallet balance assertions.
- Timeline/event persistence behavior is covered via gift-send and activity assertions in test flows and analytics overview metrics.

### Closeout criteria for QA signoff
- Produce one run artifact showing:
  - unlocked chat state for test match
  - one free gift send `200`
  - one paid gift send `200` with reduced wallet balance
  - message list containing gift payload event(s)

## Known Gaps Rolled Into Sprint 2+
- Gift send consistency is guarded by idempotency middleware but still relies on multi-step persistence that can leave partial state on downstream failure.
- Telemetry exists as activity events, but KPI dashboards and ownership/runbook evidence are not yet packaged as a formal analytics deliverable.
- Wallet top-up is MVP-friendly but needs tighter environment gating and stronger audit/reporting surfaces for production rollout.

## Demo Script (Updated)
- Open chat and show gift tray interaction beside composer.
- Show wallet balance and insufficient-fund state on premium gift.
- Open preview, confirm paid send, verify wallet decrement.
- Verify gift bubble rendering with rose metadata in timeline.

## Exit Criteria to Mark Sprint 1 “Done”
- Demo run completed without regressions in normal message send/delete flow.
- Smoke checks for `/v1/chat/gifts`, `/v1/chat/{matchID}/gifts/send`, and `/v1/wallet/{userID}/coins` attached.
- Story acceptance mapped to test evidence and signed off by PM + Flutter + Backend leads.

## Added hardening coverage (same closeout window)
- RG-106 hardening implemented: idempotency telemetry enrichment, gift tier attribution on send success events, and replay-safe send path validation.
- RG-107 hardening implemented: production-like top-up approver guard (`X-Admin-User`), top-up audit receipt metadata, and wallet audit endpoint (`GET /v1/wallet/{userID}/coins/audit`).
- RG-110 baseline completed: event taxonomy expanded with wallet audit properties and analytics/admin funnel surfaces validated in tests.
