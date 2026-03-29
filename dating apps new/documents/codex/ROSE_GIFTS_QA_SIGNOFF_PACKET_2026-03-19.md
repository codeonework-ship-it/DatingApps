# Rose Gifts — QA Evidence + Signoff Packet (19 Mar 2026)

## Scope
- Sprint-1 closeout evidence unblock: auth context + success-path capture for RG-101..RG-105.
- Sprint-2 hardening evidence: RG-106, RG-107, RG-110.

## Current Technical Delta Implemented
- RG-106 hardening:
  - Gift send telemetry now includes explicit `gift_tier` on success events.
  - Gift send attempt telemetry now records idempotency-key presence.
- RG-107 hardening/audit visibility:
  - Wallet top-up enforces controlled actor (`X-Admin-User`) in production-like environments.
  - Wallet top-up now returns audit receipt metadata.
  - New wallet audit endpoint: `GET /v1/wallet/{userID}/coins/audit?limit=...`.
- RG-110 baseline:
  - Funnel events remain available and now include richer payload for tier visibility.
  - OpenAPI updated for top-up controls and wallet audit endpoint.

## QA Evidence Runbook
1. Start backend with local unlock override for demo identities:
   - `cd backend && DEFAULT_UNLOCK_POLICY_VARIANT=allow_without_template make run-all`
2. Run rose gifts success-path smoke capture:
   - `cd backend && python scripts/rose_gifts_success_path_smoke.py`
3. Collect generated artifact path from stdout:
   - `documents/codex/ROSE_GIFTS_SUCCESS_PATH_EVIDENCE_<timestamp>.json`
4. Optional UI proof:
   - Record emulator flow for tray open → preview → free send → paid send → timeline bubble.

## Required Evidence Checklist (RG-101..RG-105)
- [ ] Gift tray opens/closes without composer text loss (RG-101)
- [ ] Wallet + free/paid state visible in tray (RG-102)
- [ ] Preview + confirm behavior for paid gift (RG-103)
- [ ] Gift appears in timeline payload/message list (RG-104)
- [ ] Catalog API payload captured from `/v1/chat/gifts` (RG-105)
- [ ] Free gift send returns `200`
- [ ] Paid gift send returns `200` with wallet decrement

## Sprint-2 Hardening Verification
- [x] RG-106: Gift send emits tier-aware success telemetry
- [x] RG-107: Wallet top-up actor control in production-like environments
- [x] RG-107: Wallet mutation audit receipt returned
- [x] RG-107: Wallet audit endpoint available
- [x] RG-110: Funnel telemetry payload has tier/idempotency context

## Ticket-level DoR/DoD Status Update
### Definition of Ready (ticket level)
- [x] Acceptance criteria measurable
- [x] API/request-response example attached
- [x] Feature flag strategy attached
- [x] Analytics events + owner listed
- [x] QA scenarios listed

### Definition of Done (ticket level)
- [x] Unit/integration tests pass
- [x] OpenAPI updated when API changes
- [ ] Feature behind rollout flag (wallet top-up remains controlled by env+admin actor; dedicated flag pending)
- [x] Error + idempotency behavior validated
- [ ] Analytics events verified in dashboard runtime (endpoint and payload are ready; dashboard screenshot evidence pending)

## Evidence Attachments (to fill during closeout)
- API smoke artifact: `documents/codex/ROSE_GIFTS_SUCCESS_PATH_EVIDENCE_<timestamp>.json`
- Emulator recording: `documents/codex/artifacts/rose_gifts_sprint1_closeout/<video>.mp4`
- Screenshot set: `documents/codex/artifacts/rose_gifts_sprint1_closeout/*.png`

## Signoff
- PM: ☐
- Backend Lead: ☐
- Flutter Lead: ☐
- QA Lead: ☐
- Data/Analytics Owner: ☐
