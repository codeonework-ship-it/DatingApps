# ALN-4.2 Staging Dry-Run Evidence (3 Mar 2026)

## Evidence Status
- Repository-side preparation: **Completed**
- True staging execution from this workspace: **Pending external environment access**

This artifact captures validated pre-flight evidence from repository execution and defines the exact staging evidence fields to fill during release rehearsal.

## Local/Repo Validation Evidence (Completed)

### Backend test evidence
- Command intent: run ALN moderation + analytics impacted package tests.
- Result run #1: `./internal/bff/mobile` passed (`34 passed / 0 failed`).
- Result run #2: `./internal/bff/mobile` passed (`34 passed / 0 failed`).
- Flake check outcome: no failures across two consecutive runs.

### Control-panel test evidence
- Command intent: run Django view tests after appeals queue + dashboard taxonomy integration.
- Result: `control_panel.tests.test_views` passed (`5 passed / 0 failed`).
- Execution note: workspace `runTests` does not detect Django tests for this file, so command was executed via configured Python interpreter:
	- `"/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/.venv/bin/python" manage.py test control_panel.tests.test_views`

### API/contract and docs evidence
- OpenAPI updated for moderation appeals and analytics overview payload dimensions.
- Runbook + checklist + owner matrix created for Phase A release gate.

## Required Staging Dry-Run Fields (To Execute Before Production)

### Environment
- Staging build version: PENDING (staging candidate not executed from this workspace)
- Staging deploy timestamp (UTC): PENDING
- Operator: PENDING

### Local rehearsal snapshot (prefilled)
- Rehearsal environment: local gateway + mobile-bff
- Rehearsal timestamp (UTC): `2026-03-02T19:32:07Z` (health/ready), `2026-03-02T19:32:23Z` (key endpoints)
- Rehearsal operator: Copilot agent

### Health/API checks
- `/healthz`: PASS (gateway `200`, mobile-bff `200`) at `2026-03-02T19:32:07Z`
- `/readyz`: PASS (gateway `200`, mobile-bff `200`) at `2026-03-02T19:32:07Z`
- Core API smoke endpoints: PASS (local rehearsal route reachability + payload schema)
	- `GET /v1/matches/local-rehearsal-match/unlock-state` -> `200`
	- `GET /v1/matches/local-rehearsal-match/quest-workflow` -> `200`
	- `GET /v1/moderation/appeals` -> `400` with stable error envelope (`success=false`, `error`, `error_code`)
	- `GET /v1/admin/moderation/appeals` -> `200`
	- `GET /v1/admin/analytics/overview` -> `200`

### Moderation staffing checks
- Shift roster attached: PENDING (staging/ops owner)
- Appeals queue owner for first 48h: PENDING (Trust & Safety Ops Lead)
- Escalation contacts validated: PENDING (Trust & Safety Ops + Incident Commander)

Use templates:
- `ALN_4_2_MODERATION_STAFFING_ROSTER_TEMPLATE_2026-03-03.md`
- `ALN_4_2_ESCALATION_PATH_TEMPLATE_2026-03-03.md`

### Rollback rehearsal
- Flags toggled OFF in rehearsal: PARTIAL (service restart rehearsal executed; flag toggles pending staging operator)
- Service restart completed: YES (local)
- Post-rollback health check pass: YES (`/healthz=200`, `/readyz=200` at `2026-03-02T19:32:49Z`)
- Restore to candidate config completed: YES (local service stack restored)

Communication template:
- `ALN_4_2_ROLLBACK_COMMUNICATION_TEMPLATE_2026-03-03.md`

### Analytics data quality checks
- `dashboard_panels` present: YES (local rehearsal)
- `event_taxonomy.version` present: YES (`engagement_unlock.v2026-03-03`, local rehearsal)
- `checks_passed=true`: YES (`data_quality_checks.staging_event_completeness.checks_passed=true`, local rehearsal)

## Approval Signatures (Staging Dry-Run)
- Product Manager: __________
- Backend Lead: __________
- Flutter Lead: __________
- Trust & Safety Ops Lead: __________
- Data/Analytics Lead: __________
- Incident Commander: __________

Final signoff carrier:
- `ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md`

## Dry-Run Outcome
- [ ] PASS (eligible for production go/no-go)
- [ ] FAIL (remediation required)

Current state (2026-03-03): pending staging execution + owner approvals.

Remediation notes:
- ______________________________________________
- ______________________________________________
