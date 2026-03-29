# Phased Implementation Plan - Activity-First Chat Unlock

Date: 28 Feb 2026
Owner: Product + Flutter + Backend + QA

## Objective
Implement activity-first engagement (quests, gestures, mini-activities, trust badges, rooms) phase by phase, while preserving existing core app stability on Android emulator and current backend architecture.

This plan is execution-oriented and maps to current codebase surfaces:
- Flutter app: `app/lib/features/*`, `app/lib/main.dart`
- BFF routes: `backend/internal/bff/mobile/server.go`
- Matching/chat services: `backend/internal/services/matching/service.go`, `backend/internal/services/chat/service.go`
- Existing planning baseline: `documents/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md`

---

## Phase 0 - Foundations & Hardening (1 sprint)

## Goals
- Ensure app runs reliably on Android emulator for all core current flows.
- Stabilize environment, observability, and baseline regression coverage.
- Freeze API contracts for the new unlock model.

## Scope

### Backend
1. Environment hardening
- Validate all required config keys for local/dev in config loader.
- Add startup checks for required dependencies (BFF, matching, chat, Supabase reachability).

2. Existing API contract audit
- Confirm route payload contracts for:
  - `/v1/swipe`
  - `/v1/matches/{userID}`
  - `/v1/chat/{matchID}/messages`
  - `/v1/safety/*`
  - `/v1/billing/*`
- Generate/refresh OpenAPI for current routes.

3. Logging + metrics baseline
- Ensure request IDs and action logs are present for all user interactions.
- Add lightweight dashboard checks for gateway readiness and BFF health.

### Flutter
1. Runtime readiness
- Confirm `API_BASE_URL` emulator value `http://10.0.2.2:8080/v1`.
- Confirm mock/live mode behavior from feature flags (`kUseMockAuth`).

2. Core flow smoke harness
- Add internal smoke test checklist screen or documented script for:
  - OTP login
  - profile complete
  - discovery swipe
  - match list
  - chat send/read

### QA
- Establish baseline test matrix (Android emulator API level + device profile).

## Deliverables
- Runbook: Android emulator + backend startup + failure recovery.
- Current API contract reference (as-is).
- Baseline regression checklist.

## Exit criteria
- Team can run end-to-end core flow on emulator without manual guesswork.
- No P0 blocker in auth/profile/swipe/match/chat path.

---

## Phase 1 - MVP Unlock Gating with Quests (2 sprints)

## Goals
- Introduce unlock state and quest-based progression.
- Gate chat send by unlock state.
- Enable women-defined quest requirement and review workflow.

## Scope

### Data & schema
1. Add tables (minimum set)
- `engagement.quest_templates`
- `engagement.match_unlock_requirements`
- `engagement.quest_submissions`

2. Extend match state
- Add `unlock_state` with states:
  - `matched`
  - `quest_pending`
  - `quest_under_review`
  - `conversation_unlocked`
  - `restricted`

### Backend
1. BFF route additions
- `GET /v1/matches/{matchID}/unlock-state`
- `POST /v1/matches/{matchID}/unlock-requirements`
- `GET /v1/matches/{matchID}/quests`
- `POST /v1/matches/{matchID}/quests/submit`
- `POST /v1/matches/{matchID}/quests/{submissionID}/review`

2. Chat gating enforcement
- Update existing `POST /v1/chat/{matchID}/messages` path to enforce unlock.
- Return domain error: `CHAT_LOCKED_REQUIREMENT_PENDING`.

3. Moderation controls
- Basic moderation validation for quest content.
- Cooldown and rate-limit checks per match/user.

### Flutter
1. New engagement module skeleton
- `app/lib/features/engagement/models`
- `app/lib/features/engagement/providers`
- `app/lib/features/engagement/screens`
- `app/lib/features/engagement/widgets`

2. Match detail integration
- Show unlock state banner.
- Show required quest and submit CTA.

3. Chat integration
- Disable composer when locked.
- Show next-step CTA and rejection reasons.

4. Women settings integration
- Allow setting one required quest template.

### QA
- Test scenarios:
  - Successful quest submission + approve unlocks chat.
  - Rejected quest keeps chat locked with reason.
  - Rate-limited submissions blocked with friendly message.

## Deliverables
- MVP quest unlock flow live behind feature flag.
- Chat gating fully functional and observable.

## Exit criteria
- At least one complete match-to-chat unlock path works in production-like env.
- No regressions in existing non-engagement match/chat flows.

---

## Phase 2 - Digital Gestures + Effort Signals (1-2 sprints)

## Goals
- Add meaningful non-monetary gestures beyond likes.
- Introduce quality scoring and women response controls.

## Scope

### Data
- Add `engagement.digital_gestures`.
- Add status model for gesture lifecycle (`pending`, `appreciated`, `declined`, `improve_request`).

### Backend
- `POST /v1/matches/{matchID}/gestures`
- `GET /v1/matches/{matchID}/gestures`
- `POST /v1/matches/{matchID}/gestures/{gestureID}/respond`
- Add quality scoring pipeline v1 (rule-based):
  - minimum content length
  - toxicity/profanity checks
  - duplicate/low-effort heuristics

### Flutter
- Match timeline component for gestures.
- Gesture composer templates:
  - thoughtful opener
  - micro-card
- Women response controls and feedback state.

### QA
- Positive path: gesture accepted -> trust score impact.
- Negative path: low-quality gesture flagged/blocked.

## Deliverables
- Gesture system integrated into match timeline.
- Audit trail for all gesture interactions.

## Exit criteria
- Gesture interactions measurable and moderation-safe.

---

## Phase 3 - Co-op 3-minute Activities (2 sprints)

## Goals
- Launch short co-op compatibility activities.
- Use activity completion as unlock/quality signal.

## Scope

### Data
- `engagement.activity_sessions`
- `engagement.activity_responses`

### Backend
- `POST /v1/matches/{matchID}/activities/start`
- `POST /v1/activities/{sessionID}/responses`
- `GET /v1/activities/{sessionID}/summary`
- Timer/expiry logic (180s hard timeout).
- Partial-completion handling.

### Flutter
- Activity launcher from match detail.
- Activity play UI for 3 types:
  - this-or-that
  - value match
  - scenario choice
- Summary card in timeline.

### QA
- Both users complete within time.
- One-sided timeout.
- Duplicate submission prevention.

## Deliverables
- First co-op activity loop complete and saved per session.

## Exit criteria
- Activity sessions stable under concurrent usage.

---

## Phase 4 - Trust Milestones, Badges, and Women Filters (1-2 sprints)

## Goals
- Make trust visible and actionable.
- Provide women control via trust-based discovery/match filters.

## Scope

### Data
- `engagement.trust_milestones`
- `engagement.user_badges`

### Backend
- Badge/risk calculation job (rule engine v1).
- `GET /v1/users/{userID}/trust-badges`
- `GET /v1/discovery/{userID}/filters/trust`
- `PATCH /v1/discovery/{userID}/filters/trust`
- Apply filter in candidate/match aggregation path.

### Flutter
- Badge chips on discovery and match cards.
- Trust filter settings (women-facing).
- Badge explanation UI (why awarded/revoked).

### QA
- Filter correctness tests.
- Badge revocation on unsafe behavior.

## Deliverables
- Trust scoring + badge + filter loop.

## Exit criteria
- Women can reliably filter by trust thresholds without breaking matching performance.

---

## Phase 5 - Weekly Conversation Rooms + Moderation (2 sprints)

## Goals
- Build recurring community engagement loop.
- Add moderator tooling for room safety.

## Scope

### Data
- `engagement.conversation_rooms`
- `engagement.room_participants`

### Backend
- `GET /v1/rooms`
- `POST /v1/rooms/{roomID}/join`
- `POST /v1/rooms/{roomID}/leave`
- `POST /v1/rooms/{roomID}/moderate`
- Capacity controls, scheduling windows, and moderation actions.

### Flutter
- Room listing and join UX.
- Room state and participation UI.
- Room moderation event banners.

### QA
- Capacity edge cases.
- Removed/banned participant behavior.
- Room lifecycle (scheduled -> active -> closed).

## Deliverables
- Weekly themed room capability with moderation controls.

## Exit criteria
- Rooms safely operate with measurable engagement and manageable moderation load.

---

## Cross-Phase Technical Workstreams

## A) Feature Flags
- `engagement_unlock_mvp`
- `digital_gestures`
- `mini_activities`
- `trust_badges`
- `conversation_rooms`

## B) Migration Strategy
- Forward/backward SQL migrations per phase.
- Data backfill tasks where required.
- Rollback scripts for critical schema changes.

## C) API Versioning / Backward Compatibility
- Keep current routes functional.
- Add new fields as additive, avoid breaking existing app clients.

## D) Observability
- Per-feature metrics:
  - unlock attempt rate
  - unlock success rate
  - gesture acceptance rate
  - activity completion rate
  - report rate per 1k interactions

## E) Security & Safety
- Abuse prevention, moderation queues, and audit trail retention.
- Access control for review/moderation endpoints.

---

## Testing Plan by Phase

## Minimum test gates (all phases)
1. Flutter
- Unit tests for providers/state transitions.
- Widget tests for critical UI states.
- Integration smoke tests for end-to-end journey.

2. Backend
- Unit/service tests for business rules.
- API tests for request validation + status codes.
- Migration tests for schema integrity.

3. Release gates
- No open P0 defects.
- Android emulator regression pass.
- Feature-flag rollback tested before production rollout.

---

## Team Execution Model

## Sprint format
- Sprint N Planning: define API + data + UI stories.
- Mid-sprint checkpoint: demo backend contracts to Flutter.
- Sprint close: integration demo on Android emulator + regression report.

## Suggested ownership
- Backend Lead: route contracts, services, migrations.
- Flutter Lead: providers, UI flows, feature flags.
- QA Lead: phase test matrix and release signoff.
- Product Owner: policy decisions and acceptance.

---

## Risks & Mitigations

1. Risk: Complexity of multi-service local environment
- Mitigation: standardized startup scripts + readiness checks + troubleshooting runbook.

2. Risk: Abuse of prompts/gestures
- Mitigation: moderation rules + rate limiting + admin review tooling.

3. Risk: Regression in core chat/match experience
- Mitigation: strict additive rollout and chat-gating behind feature flag.

4. Risk: Low adoption of quests/activities
- Mitigation: A/B test copy, defaults, and onboarding hints.

---

## Definition of Done (Program Level)
The activity-first model is considered implemented when:
- Users can progress to conversations via meaningful activity paths.
- Women control prompt and trust thresholds.
- Safety and moderation are enforceable and auditable.
- Android emulator and core app flow remain stable throughout rollout.
- Metrics show non-trivial unlock adoption without safety regressions.
