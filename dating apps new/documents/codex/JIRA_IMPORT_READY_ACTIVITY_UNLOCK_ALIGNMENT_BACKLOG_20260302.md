# Jira Import-Ready Backlog - Activity Unlock Alignment (Post-Implementation)

Date: 2 Mar 2026
Source Plan: Activity-Based Matching & Chat Unlock Plan (updated 2 Mar 2026)
Context: Core build is largely implemented. This backlog covers remaining alignment, policy closure, and production hardening.

## Suggested CSV Columns (for Jira import)
- Issue Type
- Epic Name
- Summary
- Description
- Acceptance Criteria
- Labels
- Components
- Priority
- Story Points
- Depends On

---

## Epic ALN-1: API Contract Parity & Backward Compatibility

### Story ALN-1.1
- Issue Type: Story
- Summary: Publish v1 engagement API contract baseline from implemented routes
- Description: Generate canonical OpenAPI contract reflecting currently implemented route names and payloads for unlock workflow, gestures, activities, trust, and rooms.
- Acceptance Criteria:
  1) OpenAPI spec includes all currently implemented engagement endpoints.
  2) Request/response schemas include error envelope and domain codes.
  3) Contract is versioned and committed under docs/contracts.
- Labels: engagement, api-contract, alignment
- Components: backend/mobile-bff, backend/contracts
- Priority: High
- Story Points: 5
- Depends On: None

### Story ALN-1.2
- Summary: Add alias routes for original Section 5 naming parity
- Description: Add non-breaking aliases for originally proposed routes (`/quests`, `/activities/{sessionID}/responses`, etc.) mapped to implemented handlers.
- Acceptance Criteria:
  1) Alias routes return behavior-equivalent payloads and status codes.
  2) Existing route behavior remains unchanged.
  3) Route-level tests cover both canonical and alias paths.
- Labels: engagement, api-compatibility
- Components: backend/mobile-bff
- Priority: High
- Story Points: 8
- Depends On: Story ALN-1.1

### Story ALN-1.3
- Summary: Introduce API deprecation policy for duplicate route names
- Description: Define and implement deprecation headers and timeline for old/new route naming overlap.
- Acceptance Criteria:
  1) Deprecation header contract documented.
  2) Sunset dates defined and published.
  3) Metrics dashboard tracks alias route traffic share.
- Labels: engagement, api-lifecycle
- Components: backend/mobile-bff, backend/ops, documents
- Priority: Medium
- Story Points: 3
- Depends On: Story ALN-1.2

---

## Epic ALN-2: Durable Persistence Hardening

### Story ALN-2.1
- Summary: Inventory and remove in-memory fallback stores for engagement flows
- Description: Identify all in-memory fallback code paths for quest workflow, gestures, activities, trust badges, and rooms and migrate to durable stores in all environments.
- Acceptance Criteria:
  1) Inventory doc maps each fallback path to durable replacement.
  2) Production and staging run with durable-only mode enabled.
  3) Startup fails fast if durable dependencies are unavailable (no silent fallback).
- Labels: engagement, persistence, reliability
- Components: backend/mobile-bff, backend/services
- Priority: High
- Story Points: 8
- Depends On: None

### Story ALN-2.2
- Summary: Add migration safety tests for engagement schema durability
- Description: Validate forward/backward migrations and data retention for engagement tables under schema change scenarios.
- Acceptance Criteria:
  1) Automated migration tests run in CI for engagement schema.
  2) Rollback safety is proven for at least one prior release version.
  3) No data loss for active unlock workflows in migration tests.
- Labels: engagement, migrations, ci
- Components: backend/database, backend/ops
- Priority: High
- Story Points: 5
- Depends On: Story ALN-2.1

### Story ALN-2.3
- Summary: Add resilience tests for timeout, partial write, and retry scenarios
- Description: Add service/API tests to validate consistency during timeout and retry paths (quest review, activity summary, gesture decision).
- Acceptance Criteria:
  1) Idempotent retry behavior validated for critical write endpoints.
  2) Partial failure scenarios preserve consistent unlock state.
  3) Test suite includes regression cases for duplicate submit/review calls.
- Labels: engagement, reliability, testing
- Components: backend/mobile-bff, backend/services
- Priority: Medium
- Story Points: 8
- Depends On: Story ALN-2.2

---

## Epic ALN-3: Policy Decisions Closure (Section 11)

### Story ALN-3.1
- Summary: Finalize default unlock policy when no prompt is configured
- Description: Decide and implement default behavior (Option A no lock vs Option B platform default values prompt), including UI copy and analytics dimensions.
- Acceptance Criteria:
  1) Policy decision recorded in product ADR.
  2) Backend and Flutter behavior match selected default.
  3) Metric dimension `unlock_policy_variant` is emitted.
- Labels: engagement, product-policy, unlock
- Components: product, backend/mobile-bff, app/flutter
- Priority: High
- Story Points: 5
- Depends On: None

### Story ALN-3.2
- Summary: Define assisted review automation thresholds
- Description: Specify optional auto-approve thresholds and abuse guardrails while preserving manual override by women.
- Acceptance Criteria:
  1) Threshold rules documented and configurable by feature flag.
  2) Manual review remains available for all cases.
  3) Audit log captures automated decision rationale.
- Labels: engagement, moderation, policy
- Components: product, backend/services, backend/mobile-bff
- Priority: High
- Story Points: 8
- Depends On: Story ALN-3.1

### Story ALN-3.3
- Summary: Finalize billing coexistence matrix for non-blocking monetization
- Description: Define and implement what remains monetized (boosts, cosmetics, analytics) without blocking meaningful progression.
- Acceptance Criteria:
  1) Feature matrix approved by product and revenue stakeholders.
  2) Billing routes/UI reflect approved matrix.
  3) No paywall-only block remains on core conversation progression.
- Labels: engagement, billing, monetization
- Components: product, backend/billing, app/flutter
- Priority: High
- Story Points: 5
- Depends On: Story ALN-3.1

### Story ALN-3.4
- Summary: Implement rejection and moderation appeal workflow
- Description: Add appeal submission, review, resolution states, and user-visible status for unfair rejections/moderation actions.
- Acceptance Criteria:
  1) Appeal API and status model implemented.
  2) Moderation tooling can review and resolve appeals.
  3) SLA and notification rules are documented and tested.
- Labels: engagement, moderation, appeals
- Components: backend/mobile-bff, control-panel, app/flutter
- Priority: Medium
- Story Points: 8
- Depends On: Story ALN-3.2

---

## Epic ALN-4: Launch Readiness & KPI Certification

### Story ALN-4.1
- Summary: KPI dashboard and event taxonomy signoff for engagement unlock
- Description: Finalize event schema and dashboards for primary, quality, and safety metrics listed in Section 9.
- Acceptance Criteria:
  1) Dashboard panels exist for all primary and safety metrics.
  2) Event names/properties are versioned and documented.
  3) Data quality checks validate event completeness in staging.
- Labels: engagement, analytics, launch-readiness
- Components: backend/ops, app/flutter, data
- Priority: High
- Story Points: 5
- Depends On: Story ALN-1.1, Story ALN-3.1

### Story ALN-4.2
- Summary: Phase A release gate checklist and go/no-go runbook
- Description: Create a deployment gate checklist for unlock flow stability, moderation coverage, and rollback readiness.
- Acceptance Criteria:
  1) Checklist includes API health, test pass criteria, moderation staffing, and rollback steps.
  2) Dry run executed in staging with evidence artifacts.
  3) Production go/no-go owner assignments are explicit.
- Labels: engagement, release, operations
- Components: backend/ops, app/flutter, product
- Priority: High
- Story Points: 3
- Depends On: Story ALN-2.3, Story ALN-4.1

---

## Sprint-0 Recommended Cut (next 2 weeks)
1) ALN-1.1 Publish API contract baseline
2) ALN-2.1 Remove in-memory fallbacks
3) ALN-3.1 Finalize default unlock policy
4) ALN-3.3 Finalize billing coexistence matrix
5) ALN-4.1 KPI dashboard and taxonomy signoff

## Definition of Ready (DoR)
A story is ready when:
1) Product policy assumptions are explicit.
2) API/schema contracts are attached.
3) Telemetry and moderation implications are identified.
4) Rollout/flag strategy is declared.

## Definition of Done (DoD)
A story is done when:
1) Code merged with tests passing.
2) Acceptance criteria demonstrated in staging.
3) Metrics and audit logs verified.
4) User-facing copy and docs updated.
