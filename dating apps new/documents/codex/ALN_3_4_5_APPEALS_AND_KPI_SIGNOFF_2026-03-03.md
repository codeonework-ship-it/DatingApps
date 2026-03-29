# ALN-3.4 + ALN-4.1 Signoff Notes (3 Mar 2026)

## ALN-3.4: Moderation Appeal Workflow

### API Surface
- User submit appeal: `POST /v1/moderation/appeals`
- User view status: `GET /v1/moderation/appeals/{appealID}`
- Admin list queue: `GET /v1/admin/moderation/appeals`
- Admin review/resolve: `POST /v1/admin/moderation/appeals/{appealID}/action`

### Appeal State Model
- `submitted`: user appeal accepted and waiting triage.
- `under_review`: assigned to moderator queue.
- `resolved_upheld`: moderation decision remains in effect.
- `resolved_reversed`: moderation decision reversed.

### SLA and Notification Rules
- SLA target: each appeal is assigned `sla_deadline_at = created_at + 48h`.
- Notification policy persisted per appeal as `status_change_email_and_inbox`.
- Notification trigger points:
  - on `submitted` (acknowledgment)
  - on transition to `under_review`
  - on transition to any `resolved_*` status

### Audit/Test Coverage
- Activity stream emits:
  - `appeal.submitted` with `appeal_id`, `status`, `sla_deadline_at`, `notification_policy`
  - `appeal.resolved` with `appeal_id`, `status`, `reviewed_by`
- Backend tests validate:
  - submit/get lifecycle
  - admin action transition
  - unauthorized user cannot read another user’s appeal

## ALN-4.1: KPI Dashboard + Event Taxonomy Signoff

### Dashboard Panel Set
- `unlock_completion_rate`
- `unlock_attempt_count_by_policy`
- `chat_lock_count_by_policy`
- `gesture_acceptance_rate`
- `activity_completion_rate`
- `report_rate_per_1k_interactions`
- `appeal_resolution_count`

### Event Taxonomy Version
- Version key: `engagement_unlock.v2026-03-03`
- Required events tracked in payload metadata:
  - `quest.submit`
  - `quest.review.auto`
  - `chat.locked`
  - `appeal.submitted`
  - `appeal.resolved`

### Data Quality Checks (Staging)
- `staging_event_completeness.unlock_policy_variant_coverage_pct`
- `staging_event_completeness.appeal_notification_policy_coverage_pct`
- `staging_event_completeness.checks_passed`

### Operational Validation
1. Trigger at least one appeal through submit → resolve in staging.
2. Confirm `dashboard_panels`, `event_taxonomy`, and `data_quality_checks` are present in `GET /v1/admin/analytics/overview`.
3. Verify `checks_passed=true` before release gate review.

## ALN-4.2: Release Gate and Go/No-Go Artifacts

- Release gate checklist: `ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md`
- Go/No-Go runbook: `ALN_4_2_PHASE_A_GO_NO_GO_RUNBOOK_2026-03-03.md`
- Staging dry-run evidence log: `ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md`
