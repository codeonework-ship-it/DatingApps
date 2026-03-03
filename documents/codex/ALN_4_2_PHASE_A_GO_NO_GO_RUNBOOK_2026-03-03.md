# ALN-4.2 Phase A Go/No-Go Runbook (3 Mar 2026)

## Purpose
Operational runbook for final launch gate decision for engagement unlock alignment rollout.

## Preconditions
- ALN-3.4 and ALN-4.1 implementation merged and deployed to staging candidate build.
- Checklist baseline document available:
  - `ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md`

## Meeting Cadence
- T-60 min: Pre-flight checks begin
- T-30 min: Dry-run evidence review
- T-15 min: Owner signoff round
- T-0 min: Final decision call (`GO` / `NO_GO`)

## Step-by-Step Procedure

### Step 1: Health + API Smoke
1. Verify health endpoints:
   - `GET /healthz`
   - `GET /readyz`
2. Execute smoke requests for core alignment endpoints:
   - unlock-state
   - quest-workflow
   - moderation appeals
   - admin appeals queue/action
   - admin analytics overview
3. Record response status and latency snapshots in evidence log.

### Step 2: Test Verification
1. Run backend targeted tests for mobile BFF.
2. Run control-panel tests.
3. Confirm ALN-specific assertions:
   - appeals lifecycle and authorization
   - analytics payload schema dimensions

### Step 3: Moderation Readiness Check
1. Confirm shift roster for first 48h.
2. Confirm named escalation contacts:
   - moderation duty lead
   - trust & safety manager
   - platform incident commander
3. Confirm SLA ownership for appeals queue.
4. Populate and attach templates:
   - `ALN_4_2_MODERATION_STAFFING_ROSTER_TEMPLATE_2026-03-03.md`
   - `ALN_4_2_ESCALATION_PATH_TEMPLATE_2026-03-03.md`

### Step 4: Rollback Drill Validation
1. Confirm feature flag rollback plan and ordering:
   - disable assisted review automation first
   - disable engagement unlock capabilities second
2. Confirm service control commands available to operators:
   - `backend-clean-ports`
   - `backend-run-all`
   - `backend-kill-listeners`
3. Validate rollback communications template and incident channel routing.
4. Use template:
   - `ALN_4_2_ROLLBACK_COMMUNICATION_TEMPLATE_2026-03-03.md`

### Step 5: Analytics/Data Quality Gate
1. Check `GET /v1/admin/analytics/overview` payload in staging.
2. Validate:
   - `dashboard_panels` contains required panel list
   - `event_taxonomy.version` is present
   - `data_quality_checks.staging_event_completeness.checks_passed=true`
3. Attach payload snapshot hash/time to evidence log.

### Step 6: Decision and Signoff
Use all-owner explicit approvals:
- Product Manager: ______
- Backend Lead: ______
- Flutter Lead: ______
- Trust & Safety Ops Lead: ______
- Data/Analytics Lead: ______
- Incident Commander: ______

Record approvals in:
- `ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md`

Decision:
- [ ] GO
- [ ] NO_GO

Final timestamp (UTC): ___________

## Go/No-Go Rules
- Any failed P0 checklist item => `NO_GO`.
- Missing named owner approval => `NO_GO`.
- Data quality checks failing in staging => `NO_GO` unless written exception approved by Product + Incident Commander.

## Rollback Procedure (If NO_GO after partial rollout)
1. Set feature flags OFF:
   - `FEATURE_ASSISTED_REVIEW_AUTOMATION=false`
   - `FEATURE_ENGAGEMENT_UNLOCK_MVP=false`
   - `FEATURE_DIGITAL_GESTURES=false`
   - `FEATURE_MINI_ACTIVITIES=false`
   - `FEATURE_TRUST_BADGES=false`
   - `FEATURE_CONVERSATION_ROOMS=false`
2. Restart backend services with known-good config.
3. Re-run health checks and critical API smoke.
4. Post incident summary in release channel with rollback timestamp and observed blast radius.

## Evidence Linkage
Attach evidence doc:
- `ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md`
