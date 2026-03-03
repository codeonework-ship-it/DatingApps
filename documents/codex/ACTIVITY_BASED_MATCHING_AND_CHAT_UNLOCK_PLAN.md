# Activity-Based Matching & Chat Unlock Plan

## Document Purpose
This document defines a functionality-first and implementation-first plan to shift conversation unlocks from payment-first to effort-and-intent-first interactions.

Core product direction:
- Men unlock deeper conversation opportunities through meaningful gestures and activities.
- Women define prompt preferences and gate conditions for engagement.
- Safety and trust quality remain central, with moderation controls and measurable signals.

Date: 28 Feb 2026

Status Update: 2 Mar 2026

---

## 0) Implementation Status Update (2 Mar 2026)

This plan has been largely implemented in the current codebase and test suite. The sections below remain valid as product direction, but most MVP/phase items now exist in production-ready backend and Flutter surfaces.

### Completed against this plan
- Quest-based unlock lifecycle is implemented (template setup, submission, review, unlock-state transitions).
- Chat send gating is implemented with domain error code `CHAT_LOCKED_REQUIREMENT_PENDING`.
- Digital gesture flow is implemented (create, decision, score/timeline behaviors).
- Co-op mini activity lifecycle APIs are implemented (start, submit, summary, timeout handling).
- Trust badges and trust filter endpoints are implemented.
- Conversation room APIs and moderation controls are implemented.
- Analytics/feature-flag rollout layer and regression tests are in place.

### Route reality check (implemented endpoints)
The original route proposal in Section 5 is conceptually covered, with some naming differences in current implementation:

- Unlock and quest workflow:
  - `GET /v1/matches/{matchID}/unlock-state`
  - `GET /v1/matches/{matchID}/quest-template`
  - `PUT /v1/matches/{matchID}/quest-template`
  - `GET /v1/matches/{matchID}/quest-workflow`
  - `POST /v1/matches/{matchID}/quest-workflow/submit`
  - `POST /v1/matches/{matchID}/quest-workflow/review`
- Gestures:
  - `GET /v1/matches/{matchID}/timeline`
  - `POST /v1/matches/{matchID}/gestures`
  - `POST /v1/matches/{matchID}/gestures/{gestureID}/decision`
  - `GET /v1/matches/{matchID}/gestures/{gestureID}/score`
- Activities:
  - `POST /v1/activities/sessions/start`
  - `POST /v1/activities/sessions/{sessionID}/submit`
  - `GET /v1/activities/sessions/{sessionID}/summary`
- Trust:
  - `GET /v1/users/{userID}/trust-badges`
  - `GET /v1/discovery/{userID}/filters/trust`
  - `PATCH /v1/discovery/{userID}/filters/trust`
- Rooms:
  - `GET /v1/rooms`
  - `POST /v1/rooms/{roomID}/join`
  - `POST /v1/rooms/{roomID}/leave`
  - `POST /v1/rooms/{roomID}/moderate`

### Remaining alignment work (if desired)
- Rename/alias endpoints to match original Section 5 naming (`quests`, `activities/{sessionID}/responses`, etc.) for stricter API-spec parity.
- Promote currently in-memory fallback stores to fully durable stores in all environments.
- Close open policy decisions in Section 11 (default unlock policy, review automation, billing coexistence details, appeal flows).

---

## 1) Current System Baseline (As-Is)

### Mobile app (Flutter)
Existing surfaces and providers:
- Discovery/swiping: `app/lib/features/swipe/providers/swipe_provider.dart`
- Match list: `app/lib/features/matching/providers/match_provider.dart`
- Messaging: `app/lib/features/messaging/providers/message_provider.dart`
- Payment domain models: `app/lib/features/payment/models/payment_models.dart`
- Safety/reporting screens/providers: `app/lib/features/common/widgets/report_user_sheet.dart`, `app/lib/core/providers/safety_actions_provider.dart`

Current behavior:
- Mutual like creates a match.
- Chat messages can be sent after match via `/chat/{matchID}/messages`.
- Billing endpoints and subscription/payment models exist in backend + Flutter.

### Backend (Go BFF + services)
Current API entrypoints are defined in:
- `backend/internal/bff/mobile/server.go`

Relevant existing routes:
- `POST /v1/swipe`
- `GET /v1/matches/{userID}`
- `GET /v1/chat/{matchID}/messages`
- `POST /v1/chat/{matchID}/messages`
- `POST /v1/safety/report`
- `POST /v1/safety/block`
- Billing routes:
  - `GET /v1/billing/plans`
  - `GET /v1/billing/subscription/{userID}`
  - `POST /v1/billing/subscribe`
  - `GET /v1/billing/payments/{userID}`

Core services:
- Matching service: `backend/internal/services/matching/service.go`
- Chat service: `backend/internal/services/chat/service.go`

### Product docs baseline
- PRD currently includes subscription-first approach: `documents/Verified_Dating_App_Full_PRD.md`
- API summary currently minimal and payment-included: `documents/Verified_Dating_App_API_Spec.md`
- Existing enhancement ideas library: `documents/02_NEW_FEATURES_FUNCTIONALITY.md`

---

## 2) Target Product Model (To-Be)

## 2.1 Core Principle
Conversation progression should be earned through respectful intent and meaningful engagement, not only through monetary purchase.

## 2.2 New Engagement Framework
1. Intent-based Mini Quests (women-defined prompts)
2. Digital Gestures (effort-signaling actions)
3. Co-op 3-minute Mini Activities
4. Safety-first Trust Milestones + Filterable Badges
5. Time-boxed Weekly Conversation Rooms

## 2.3 Positioning with Billing
- Billing remains optional for convenience perks (e.g., profile boosts, cosmetic personalization, advanced analytics).
- Core ability to progress with a match should not be locked behind paywall-only rules.
- Activity completion creates eligibility signals that unlock richer interactions.

---

## 3) Functional Specification

## 3.1 Intent-Based Mini Quests

### User story
As a woman, I can define the type of respectful prompt a match must complete before unrestricted chat opens.

### Quest types (MVP)
- Voice-intent note (30–60 sec)
- Values prompt (short structured response)
- Creativity prompt (micro-card / thoughtful gesture)

### Rules
- Women choose one required quest template (or default app template).
- Men submit one quest attempt per cooldown window.
- Women can approve/reject quest completion.
- On approval, match moves from `matched` -> `conversation_unlocked`.

### Acceptance criteria
- Women can set and edit prompt rules per profile.
- Men can view requirements from match detail.
- Submission status visible: pending, approved, rejected, cooldown.
- Chat composer enforces unlock state correctly.

---

## 3.2 Digital Gestures (Effort Signals)

### User story
As a man, I can send meaningful gestures to express intent beyond a simple like.

### Gesture types (MVP)
- Thoughtful opener template (customized answer)
- Personalized micro-card (short form + selected tone)
- Challenge completion token (derived from mini quest)

### Rules
- Gesture quality score generated from objective checks (length, originality score, profanity/safety pass, completion quality).
- Women can react: appreciate / request better effort / decline.

### Acceptance criteria
- Gesture appears in match timeline.
- Women get one-tap decision controls.
- Gesture interactions are logged for trust/analytics.

---

## 3.3 Co-op Mini Activities (3-minute)

### User story
As matched users, we can play a short activity to reveal compatibility before long-form chat.

### Activity types (MVP)
- This-or-that
- Value match
- Scenario choice

### Rules
- Activity session has strict timer (180s).
- Both users complete independently; compatibility summary shown after both submit or timer expires.
- Completion contributes to unlock eligibility and trust scoring.

### Acceptance criteria
- Start activity from match detail screen.
- Handle timeout and partial completion gracefully.
- Persist summary and visible insights in timeline.

---

## 3.4 Safety-First Trust Milestones + Badges

### User story
As a woman, I can filter matches by trust and communication quality signals.

### Milestone inputs
- Profile completeness
- Verification status consistency
- Respectful communication score
- Prompt completion reliability
- Report history risk penalties

### Badges (MVP)
- Prompt Completer
- Respectful Communicator
- Consistent Profile
- Verified & Active

### Acceptance criteria
- Badge computation runs on deterministic rules (MVP).
- Women can toggle minimum trust/badge filters in discovery and matches.
- Unsafe behavior can remove badge eligibility automatically.

---

## 3.5 Weekly Conversation Rooms (Moderated)

### User story
As a user, I can join weekly themed rooms for meaningful introductions.

### Room examples
- Books
- Fitness
- Travel
- Career

### Rules
- Fixed schedule windows.
- Capacity and moderation controls.
- Lightweight prompts + pair recommendations after room interaction.

### Acceptance criteria
- Users can browse upcoming rooms and join.
- Moderators can remove bad actors.
- Room participation creates compatibility signals.

---

## 4) Data Model Additions (Proposed)

Add schema namespace: `engagement` (or keep in existing schema with clear prefixes).

## 4.1 Core tables
- `engagement.quest_templates`
  - `id`, `created_by_user_id`, `type`, `prompt_text`, `is_default`, `is_active`
- `engagement.match_unlock_requirements`
  - `match_id`, `required_quest_template_id`, `required_activity_count`, `state`
- `engagement.quest_submissions`
  - `id`, `match_id`, `submitted_by_user_id`, `template_id`, `payload_json`, `status`, `reviewed_by_user_id`, `review_reason`, `created_at`
- `engagement.digital_gestures`
  - `id`, `match_id`, `sender_user_id`, `gesture_type`, `content_json`, `quality_score`, `status`, `created_at`
- `engagement.activity_sessions`
  - `id`, `match_id`, `activity_type`, `started_at`, `expires_at`, `status`
- `engagement.activity_responses`
  - `id`, `session_id`, `user_id`, `response_json`, `submitted_at`
- `engagement.trust_milestones`
  - `user_id`, `profile_depth_score`, `communication_score`, `consistency_score`, `last_computed_at`
- `engagement.user_badges`
  - `user_id`, `badge_code`, `awarded_at`, `revoked_at`
- `engagement.conversation_rooms`
  - `id`, `theme`, `starts_at`, `ends_at`, `capacity`, `status`, `moderator_id`
- `engagement.room_participants`
  - `room_id`, `user_id`, `joined_at`, `status`

## 4.2 Match state extension
Extend match state model with:
- `unlock_state` enum:
  - `matched`
  - `quest_pending`
  - `quest_under_review`
  - `conversation_unlocked`
  - `restricted`

---

## 5) API Additions (BFF Layer)

Add to `backend/internal/bff/mobile/server.go` routes under `/v1`:

Quest & unlock:
- `GET /matches/{matchID}/unlock-state`
- `POST /matches/{matchID}/unlock-requirements`
- `GET /matches/{matchID}/quests`
- `POST /matches/{matchID}/quests/submit`
- `POST /matches/{matchID}/quests/{submissionID}/review`

Digital gestures:
- `POST /matches/{matchID}/gestures`
- `GET /matches/{matchID}/gestures`
- `POST /matches/{matchID}/gestures/{gestureID}/respond`

Mini activities:
- `POST /matches/{matchID}/activities/start`
- `POST /activities/{sessionID}/responses`
- `GET /activities/{sessionID}/summary`

Trust & badges:
- `GET /users/{userID}/trust-badges`
- `GET /discovery/{userID}/filters/trust`
- `PATCH /discovery/{userID}/filters/trust`

Conversation rooms:
- `GET /rooms`
- `POST /rooms/{roomID}/join`
- `POST /rooms/{roomID}/leave`
- `POST /rooms/{roomID}/moderate`

## Chat gating update
In existing message send flow:
- `POST /chat/{matchID}/messages` must validate `unlock_state` before accepting messages.
- Return clear domain error when blocked: `CHAT_LOCKED_REQUIREMENT_PENDING`.

---

## 6) Flutter App Changes (Planned)

## 6.1 New feature module
Create new module:
- `app/lib/features/engagement/`
  - `models/`
  - `providers/`
  - `screens/`
  - `widgets/`

## 6.2 Integration points
- Discovery card/detail: show trust badges.
- Match card/detail: show unlock state + CTA to complete quest/activity.
- Chat screen: gate composer by unlock state; show action banner with next step.
- Settings/profile: women prompt preference setup.

## 6.3 Providers to add
- `EngagementUnlockProvider`
- `QuestProvider`
- `GestureProvider`
- `MiniActivityProvider`
- `TrustBadgeProvider`
- `ConversationRoomProvider`

---

## 7) Safety & Moderation Requirements

Mandatory safeguards:
- Content moderation for voice/text submissions.
- Prompt abuse prevention (no degrading/harassing prompts).
- Attempt rate limits + cooldowns.
- Full moderation audit logs for approvals/rejections.
- Admin controls in existing moderation surfaces for quest/gesture abuse.

---

## 8) Rollout Plan (Phased)

## Phase A (MVP - unlock through quest)
Scope:
- Single required quest template per woman.
- Submission + review + chat unlock state.
- Basic trust badge: Prompt Completer.

Outcomes:
- Replaces paywall-only chat unlock for core progression.
- Establishes gating and moderation primitives.

## Phase B (Engagement depth)
Scope:
- Digital gestures.
- 2 mini-activity types.
- Expanded trust badges + discovery filters.

Outcomes:
- Higher quality interactions and better compatibility signals.

## Phase C (Community loops)
Scope:
- Weekly conversation rooms.
- Moderator tooling and event analytics.

Outcomes:
- Recurring engagement beyond one-to-one swiping.

---

## 9) Metrics & Success Criteria

Primary metrics:
- Match -> meaningful interaction conversion rate
- Unlock completion rate
- Female response rate after unlock
- 7-day retention for women and men
- Report rate per 1k interactions

Quality metrics:
- Average gesture quality score
- Quest rejection reasons distribution
- Time-to-first-meaningful-message

Safety metrics:
- Moderation actions per 1k submissions
- Repeat offender rate
- Badge revocation rate

---

## 10) Testing Strategy

## Flutter
- Unit tests:
  - unlock state reducer/provider transitions
  - quest submission validation rules
  - badge calculation display mapping
- Widget tests:
  - chat composer lock/unlock banner states
  - match card unlock CTA states
  - mini activity timer UI states
- Integration tests:
  - complete unlock flow from match to first message

## Backend
- Service tests:
  - quest submit/review workflows
  - unlock gating on chat send
  - mini activity timeout + summary
- API tests:
  - route-level authz and validation
  - moderation actions and audit events
- Data tests:
  - migration forward/backward checks
  - unlock state consistency constraints

---

## 11) Open Decisions to Finalize

1. Default unlock policy when woman sets no prompt:
   - Option A: no lock
   - Option B: platform default values prompt
2. Review model:
   - Manual by woman only vs assisted auto-approve thresholds
3. Voice quest in MVP:
   - Include now vs defer to Phase B for moderation readiness
4. Billing coexistence:
   - Which benefits remain monetized without blocking meaningful progression
5. Abuse recovery:
   - Appeal flow for unfair rejection/moderation actions

---

## 12) Recommended Immediate Next Step

Run a product + engineering alignment session to freeze MVP scope for Phase A:
- Finalize unlock policy
- Finalize first quest types
- Finalize schema + endpoint contracts
- Convert into Jira epics/stories and API contract tasks

This enables implementation kickoff without ambiguity.
