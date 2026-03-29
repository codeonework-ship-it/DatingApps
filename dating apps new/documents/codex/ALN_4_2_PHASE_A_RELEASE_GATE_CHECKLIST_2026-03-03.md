# ALN-4.2 Phase A Release Gate Checklist (3 Mar 2026)

## Scope
Release gate for Activity Unlock alignment rollout (ALN-1 to ALN-4) covering:
- API stability
- moderation readiness
- metrics quality
- rollback safety

## Gate Decision
- Final state must be one of:
  - `GO`
  - `NO_GO`
- Any unchecked **P0** item forces `NO_GO`.

## Checklist

### 1) API Health & Platform Readiness (P0)
- [x] `GET /healthz` is healthy on API Gateway and mobile BFF.
- [x] `GET /readyz` is healthy on API Gateway and mobile BFF.
- [ ] Engagement API contract routes respond successfully in staging smoke:
  - `/v1/matches/{matchID}/unlock-state`
  - `/v1/matches/{matchID}/quest-workflow`
  - `/v1/moderation/appeals`
  - `/v1/admin/moderation/appeals`
  - `/v1/admin/analytics/overview`
- [x] Error envelope is stable (`success=false`, `error`, `error_code`).

Status note (2026-03-03): staging endpoint execution is still pending environment/operator run.
Local rehearsal note (UTC): `2026-03-02T19:32:07Z` and `2026-03-02T19:32:23Z` recorded successful local health/ready and key endpoint smoke responses.
Latest local evidence note (UTC): `2026-03-14T21:10:52Z` and `2026-03-14T21:11:09Z` recorded `readyz=200` (gateway + BFF), engagement daily-prompt GET/answer/responders success, engagement groups list success, and BAD_REQUEST envelope with `success=false,error,error_code`.

### 2) Test Pass Criteria (P0)
- [x] Backend package tests pass for `./internal/bff/mobile` with no flakes across 2 consecutive runs.
- [x] Control-panel view tests pass (`manage.py test control_panel.tests.test_views`).
- [x] ALN-3.4 specific tests pass:
  - submit/get appeal lifecycle
  - admin appeal resolve action
  - unauthorized user cannot fetch other user appeal status
- [x] ALN-4.1 analytics payload checks pass:
  - `dashboard_panels` exists
  - `event_taxonomy.version` exists
  - `data_quality_checks.staging_event_completeness` exists

Evidence note (2026-03-03):
- Backend: `runTests` on `backend/internal/bff/mobile/*_test.go` -> 34 passed / 0 failed (run twice).
- Control-panel: `python manage.py test control_panel.tests.test_views` -> 5 passed / 0 failed.

### 3) Moderation Staffing & Operational Coverage (P0)
- [ ] Moderator on-call roster includes minimum staffing for first 48h launch window.
- [ ] Appeals queue ownership is assigned for all shifts.
- [ ] SLA target is staffed for 48h appeal resolution objective.
- [x] Escalation path documented for safety-critical disputes.

Template references:
- `ALN_4_2_MODERATION_STAFFING_ROSTER_TEMPLATE_2026-03-03.md`
- `ALN_4_2_ESCALATION_PATH_TEMPLATE_2026-03-03.md`

### 4) Rollback Readiness (P0)
- [ ] Feature flags rollback plan reviewed and approved:
  - `FEATURE_ENGAGEMENT_UNLOCK_MVP=false`
  - `FEATURE_DIGITAL_GESTURES=false`
  - `FEATURE_MINI_ACTIVITIES=false`
  - `FEATURE_TRUST_BADGES=false`
  - `FEATURE_CONVERSATION_ROOMS=false`
  - `FEATURE_ASSISTED_REVIEW_AUTOMATION=false`
- [ ] Alias routes deprecation safety confirmed (non-breaking rollback path).
- [x] Rollback communication template prepared (eng/product/moderation).
- [x] Backout execution drill completed in non-prod or staging rehearsal.

Evidence note (UTC): local stop/start rehearsal completed and post-restart health verified at `2026-03-02T19:32:49Z` (`/healthz=200`, `/readyz=200`).
Template reference:
- `ALN_4_2_ROLLBACK_COMMUNICATION_TEMPLATE_2026-03-03.md`

### 5) Analytics and Data Quality (P1)
- [x] `GET /v1/admin/analytics/overview` includes:
  - `dashboard_panels`
  - `event_taxonomy`
  - `data_quality_checks`
- [x] Data quality check `checks_passed=true` in local rehearsal.
- [x] Dashboard panel coverage includes all ALN-4.1 panel names (local rehearsal).

Evidence note (UTC): local rehearsal call to `/v1/admin/analytics/overview` returned `200` with `dashboard_panels`, `event_taxonomy.version=engagement_unlock.v2026-03-03`, and `data_quality_checks.staging_event_completeness.checks_passed=true`.

### 6) Signoff & Evidence Attachments (P0)
- [x] Runbook completed: `ALN_4_2_PHASE_A_GO_NO_GO_RUNBOOK_2026-03-03.md`.
- [x] Dry-run evidence attached: `ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md`.
- [ ] Owner signoff packet completed: `ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md`.
- [ ] Final decision log includes owner approvals + timestamp.

## Owner Matrix (Explicit)
- Product decision owner: Product Manager (Engagement)
- Engineering release owner: Backend Lead
- Mobile owner: Flutter Lead
- Moderation owner: Trust & Safety Ops Lead
- Analytics owner: Data/Analytics Lead
- Incident commander (launch day): SRE/Platform Lead

## Exit Criteria
Gate is **GO** only if all P0 items are checked and owners provide explicit approval in runbook signoff section.
