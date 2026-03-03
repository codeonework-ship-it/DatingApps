# Jira Import-Ready Backlog - Activity-First Unlock

Date: 28 Feb 2026
Format: Epic + Story template with acceptance criteria, dependencies, and story points placeholders.

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

## Epic 1: Platform Readiness & Baseline Stability

### Story 1.1
- Issue Type: Story
- Summary: Android emulator runbook and readiness checks
- Description: Document and automate startup of backend + Flutter app for emulator usage.
- Acceptance Criteria:
  1) Emulator startup checklist exists and is validated.
  2) API base URL for emulator uses `10.0.2.2`.
  3) Known failures (ADB offline, gateway 503, Supabase schema exposure) have recovery steps.
- Depends On: None
- Story Points: 5

### Story 1.2
- Summary: Baseline regression suite for core flows
- Description: Add smoke checks for OTP, profile completion, swipe, match list, chat send.
- Acceptance Criteria:
  1) Core flow passes on Android emulator.
  2) Failures produce actionable logs.
  3) Regression report artifact generated.
- Depends On: Story 1.1
- Story Points: 8

---

## Epic 2: Quest-Based Unlock MVP

### Story 2.1
- Summary: Add unlock state model to match lifecycle
- Description: Extend match state with unlock states and transition rules.
- Acceptance Criteria:
  1) States: matched, quest_pending, quest_under_review, conversation_unlocked, restricted.
  2) State transition rules are deterministic and tested.
  3) Existing match APIs remain backward compatible.
- Depends On: Epic 1
- Story Points: 8

### Story 2.2
- Summary: Create quest templates and requirement assignment
- Description: Women can set required quest template for engagement unlock.
- Acceptance Criteria:
  1) Requirement create/edit endpoints available.
  2) Requirement visible in match detail payload.
  3) Input validation rejects unsafe/invalid prompt templates.
- Depends On: Story 2.1
- Story Points: 8

### Story 2.3
- Summary: Quest submission and review workflow
- Description: Men submit quest response; women approve/reject.
- Acceptance Criteria:
  1) Submission statuses: pending, approved, rejected, cooldown.
  2) Review reason captured for rejection.
  3) Cooldown enforcement and rate limits active.
- Depends On: Story 2.2
- Story Points: 13

### Story 2.4
- Summary: Gate chat send by unlock state
- Description: Block `POST /chat/{matchID}/messages` until unlock complete.
- Acceptance Criteria:
  1) Locked chats return `CHAT_LOCKED_REQUIREMENT_PENDING`.
  2) Approved quests enable chat send immediately.
  3) Chat UI shows unlock CTA when locked.
- Depends On: Story 2.3
- Story Points: 8

---

## Epic 3: Digital Gestures

### Story 3.1
- Summary: Add gesture composer and timeline integration
- Description: Allow thoughtful opener, micro-card, and challenge token gestures.
- Acceptance Criteria:
  1) Gesture appears in timeline with sender and timestamp.
  2) Women can respond with appreciate/decline/request better.
  3) Gesture status updates reflected in timeline.
- Depends On: Epic 2
- Story Points: 8

### Story 3.2
- Summary: Implement effort signal scoring v1
- Description: Rule-based scoring for quality and safety.
- Acceptance Criteria:
  1) Score considers minimum content quality checks.
  2) Toxic/profane content flagged.
  3) Scoring outcome stored and queryable.
- Depends On: Story 3.1
- Story Points: 8

---

## Epic 4: Co-op 3-Minute Activities

### Story 4.1
- Summary: Activity session lifecycle APIs
- Description: Start session, submit responses, compute summary.
- Acceptance Criteria:
  1) Timer-based expiry at 180 seconds.
  2) Handles partial completion and timeout states.
  3) Summary persisted and available via API.
- Depends On: Epic 2
- Story Points: 13

### Story 4.2
- Summary: Build activity UI flows in Flutter
- Description: This-or-that, value match, scenario choice interfaces.
- Acceptance Criteria:
  1) User can start and complete activity from match flow.
  2) Timeout UX is handled cleanly.
  3) Summary is visible post-completion.
- Depends On: Story 4.1
- Story Points: 13

---

## Epic 5: Trust Milestones & Badges

### Story 5.1
- Summary: Compute trust milestones and assign badges
- Description: Deterministic badge engine with revocation support.
- Acceptance Criteria:
  1) Badge assignment based on documented rules.
  2) Badge revocation on unsafe behavior.
  3) Badge history is auditable.
- Depends On: Epic 2, Epic 3
- Story Points: 8

### Story 5.2
- Summary: Women trust filter controls in discovery/matches
- Description: Allow filtering by minimum trust/badge criteria.
- Acceptance Criteria:
  1) Filters persist per user.
  2) Discovery/match lists honor active filters.
  3) Empty-state UX explains filter impact.
- Depends On: Story 5.1
- Story Points: 8

---

## Epic 6: Weekly Conversation Rooms

### Story 6.1
- Summary: Room scheduling and participation endpoints
- Description: Browse, join, leave themed rooms with capacity rules.
- Acceptance Criteria:
  1) Room lifecycle states supported.
  2) Capacity limits enforced.
  3) Participation events logged.
- Depends On: Epic 1
- Story Points: 8

### Story 6.2
- Summary: Moderator controls for room safety
- Description: Moderator actions for removal and policy enforcement.
- Acceptance Criteria:
  1) Moderator action endpoint available.
  2) Action audit trail persisted.
  3) Removed user is blocked from active session.
- Depends On: Story 6.1
- Story Points: 8

---

## Epic 7: QA, Observability, and Release Gating

### Story 7.1
- Summary: Add test coverage for success/failure/edge scenarios
- Description: Expand Flutter + backend tests for new unlock and activity flows.
- Acceptance Criteria:
  1) Provider/state tests cover happy + failure paths.
  2) Backend service/API tests cover validation + transitions.
  3) CI run includes all new tests.
- Depends On: Epics 2-6
- Story Points: 13

### Story 7.2
- Summary: Production metrics and feature flag rollout
- Description: Add rollout flags and funnel metrics dashboards.
- Acceptance Criteria:
  1) Feature flags per capability exist.
  2) Metrics: unlock completion, gesture acceptance, activity completion, report rate.
  3) Rollback playbook validated.
- Depends On: Epics 2-6
- Story Points: 8

---

## Definition of Ready (DoR)
A story is ready when:
1) API contract is defined.
2) UX state behavior documented.
3) Test cases identified (success/failure/edge).
4) Dependencies and rollout flag identified.

## Definition of Done (DoD)
A story is done when:
1) Implementation merged.
2) Tests pass in CI and emulator smoke checks pass.
3) Observability and logs are present.
4) Acceptance criteria are demonstrably satisfied.
