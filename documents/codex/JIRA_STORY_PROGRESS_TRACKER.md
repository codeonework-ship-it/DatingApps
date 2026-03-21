# Jira Story Progress Tracker

Date: 1 Mar 2026
Backlog Source: `documents/codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_BACKLOG.md`

## Overall Progress Snapshot
- Total planned story points: **145**
- Completed: **145**
- In progress: **0**
- Remaining not started: **0**

## Epic-wise Status

| Epic | Planned SP | Done SP | In Progress SP | Remaining SP | Status |
|---|---:|---:|---:|---:|---|
| Epic 1: Platform Readiness & Baseline Stability | 13 | 13 | 0 | 0 | Completed |
| Epic 2: Quest-Based Unlock MVP | 37 | 37 | 0 | 0 | Completed |
| Epic 3: Digital Gestures | 16 | 16 | 0 | 0 | Completed |
| Epic 4: Co-op 3-Minute Activities | 26 | 26 | 0 | 0 | Completed |
| Epic 5: Trust Milestones & Badges | 16 | 16 | 0 | 0 | Completed |
| Epic 6: Weekly Conversation Rooms | 16 | 16 | 0 | 0 | Completed |
| Epic 7: QA, Observability, and Release Gating | 21 | 21 | 0 | 0 | Completed |

## Current Implementation Mapping (this session)

### Implemented technical foundation
1. Backend HTTP correlation middleware and panic handler
- Added correlation ID middleware and global exception middleware.
- File: `backend/internal/platform/observability/http.go`

2. Backend routing middleware integration
- Enabled correlation and global exception middleware in gateway and mobile BFF.
- Files:
  - `backend/internal/gateway/http/server.go`
  - `backend/internal/bff/mobile/server.go`

3. Backend structured error response enrichment
- `writeError` now emits structured fields (`success`, `error`, `error_code`) and attaches correlation id in payload/headers.
- File: `backend/internal/bff/mobile/server.go`

4. Flutter structured logger
- Replaced pretty logging with structured JSON logging utility.
- File: `app/lib/core/utils/logger.dart`

5. Flutter API correlation + structured request/response/error logs
- Added Dio interceptors that generate/propagate `X-Correlation-ID` and log each request flow.
- File: `app/lib/core/providers/api_client_provider.dart`

6. Flutter global exception handling
- Added framework, platform, and zone-level global exception hooks.
- File: `app/lib/main.dart`

## Story-level status detail

### Epic 1
- Story 1.1 Android emulator runbook/readiness checks (5 SP): **Completed**
  - Runbook/checklist created and validated.
  - Emulator base URL documented as `http://10.0.2.2:8080/v1`.
  - Recovery playbooks documented for ADB offline, gateway 503/502, and Supabase schema exposure.
  - Evidence: `documents/codex/completed/PHASE_1_STORY_1_1_ANDROID_EMULATOR_RUNBOOK.md`

- Story 1.2 Baseline regression suite (8 SP): **Completed**
  - Structured backend + Flutter logging foundation completed.
  - Backend regression tests passing (latest baseline: 17/17).
  - Emulator connected and live smoke executed.
  - OTP + profile completion flows passed in smoke.
  - Runtime endpoint drift to `example.supabase.co` was fixed by startup script hardening and explicit env wiring.
  - Supabase credentials, schema exposure, and RLS blockers were remediated for smoke validation.
  - Core API smoke now passes for OTP verify, profile draft completion, swipe/mutual match, match list, chat send/list.
  - Flutter emulator UI evidence captured and attached (screenshots + recording + UI hierarchy dumps).
  - Production-hardening cleanup applied:
    - canonical schemas restored in runtime config (`user_management`, `matching`)
    - temporary public smoke tables removed from Supabase via cleanup migration
  - Runtime remediation evidence:
    - `backend/scripts/dev_up.sh`
    - `backend/scripts/019_remove_public_smoke_compat.sql`
  - Regression artifact updated with command evidence and blocker details.
  - Evidence:
    - `documents/codex/completed/PHASE_1_STORY_1_2_BASELINE_REGRESSION_REPORT.md`
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`
    - `documents/codex/artifacts/story_1_2_emulator/01_welcome.png`
    - `documents/codex/artifacts/story_1_2_emulator/02_auth_phone_step.png`
    - `documents/codex/artifacts/story_1_2_emulator/03_auth_otp_step.png`
    - `documents/codex/artifacts/story_1_2_emulator/04_post_verify.png`
    - `documents/codex/artifacts/story_1_2_emulator/story1_2_flow.mp4`

### Epic 2
- Story 2.1 Add unlock state model to match lifecycle (8 SP): **Completed**
  - Added deterministic unlock state domain model with required states:
    - `matched`, `quest_pending`, `quest_under_review`, `conversation_unlocked`, `restricted`
  - Added transition function and unit tests for happy path + rejection + restriction + invalid transitions.
  - Evidence:
    - `backend/internal/modules/matching/domain/unlock_state.go`
    - `backend/internal/modules/matching/domain/unlock_state_test.go`
  - Test result: `go test ./internal/modules/matching/domain -v` passed.
  - Added unlock state API wiring and match payload enrichment (`unlock_state`) while preserving backward compatibility.
  - Added durable unlock-state persistence repository wiring against Supabase table mapping.
  - Evidence:
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/quest_repository.go`
    - `backend/internal/bff/mobile/server.go`
  - Runtime evidence captured in canonical smoke artifact.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

- Story 2.2 Create quest templates and requirement assignment (8 SP): **Completed**
  - Added domain model scaffolding for quest templates including deterministic constraints (`min/max chars`, identity fields, timestamping).
  - Added strict template validation to reject unsafe prompt content patterns and invalid lengths.
  - Added BFF + application wiring for requirement create/read endpoints:
    - `PUT /v1/matches/{matchID}/quest-template`
    - `GET /v1/matches/{matchID}/quest-template`
  - Added match list payload enrichment so requirement is visible under `quest_template` when configured.
  - Added unit tests covering success, unsafe content rejection, boundary validation, and constructor constraints.
  - Evidence:
    - `backend/internal/modules/matching/domain/quest_template.go`
    - `backend/internal/modules/matching/domain/quest_template_test.go`
    - `backend/internal/modules/matching/application/commands.go`
    - `backend/internal/modules/matching/application/service.go`
    - `backend/internal/modules/matching/infrastructure/store_gateway.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
  - Added durable template persistence via Supabase-backed quest repository.
  - Added authorization semantics: only match participants can manage templates and only original creator can edit existing requirement.
  - Evidence:
    - `backend/internal/bff/mobile/quest_repository.go`
    - `backend/internal/platform/config/config.go`
    - `backend/scripts/014_engagement_unlock_tables.sql`
  - Runtime evidence captured for template upsert/read and assignment in canonical smoke artifact.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

- Story 2.3 Quest submission and review workflow (8 SP): **Completed**
  - Added matching application commands and handlers for workflow lifecycle operations:
    - `matching.quest.workflow.get`
    - `matching.quest.workflow.submit`
    - `matching.quest.workflow.review`
  - Added infrastructure gateway surface area for workflow retrieval, submission, and review across store and gRPC adapters.
  - Added BFF endpoints for workflow lifecycle:
    - `GET /v1/matches/{matchID}/quest-workflow`
    - `POST /v1/matches/{matchID}/quest-workflow/submit`
    - `POST /v1/matches/{matchID}/quest-workflow/review`
  - Added durable Supabase-backed workflow persistence including:
    - status progression (`pending`, `approved`, `rejected`, `cooldown`)
    - rejection reason capture
    - cooldown enforcement
    - submission rate limiting per rolling window
  - Added match list enrichment with `quest_workflow` payload when workflow data exists.
  - Added endpoint-level integration tests for submit/get/review lifecycle, rejection cooldown behavior, and explicit rate-limit saturation behavior.
  - Evidence:
    - `backend/internal/modules/matching/application/commands.go`
    - `backend/internal/modules/matching/application/service.go`
    - `backend/internal/modules/matching/infrastructure/store_gateway.go`
    - `backend/internal/modules/matching/infrastructure/grpc_gateway.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_quest_workflow_test.go`
    - `backend/internal/bff/mobile/quest_repository.go`
  - Test result:
    - `go test ./internal/bff/mobile -count=1` passed.
  - Live smoke evidence:
    - template upsert succeeded
    - submit/review approval succeeded
    - unlock transitioned to `conversation_unlocked`
  - Runtime evidence captured for submit + review approval + unlock progression.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

- Story 2.4 Gate chat send by unlock state (8 SP): **Completed**
  - Added unlock-state endpoint:
    - `GET /v1/matches/{matchID}/unlock-state`
  - Added chat send gate on existing endpoint:
    - `POST /v1/chat/{matchID}/messages`
    - returns `CHAT_LOCKED_REQUIREMENT_PENDING` when unlock is not complete.
  - Added backend integration tests for locked-chat behavior and unlock-state contract.
  - Added Flutter chat unlock CTA behavior when backend returns `CHAT_LOCKED_REQUIREMENT_PENDING`.
  - Live smoke evidence:
    - chat blocked with `CHAT_LOCKED_REQUIREMENT_PENDING` while quest pending
    - chat accepted immediately after quest approval
  - Evidence:
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_quest_workflow_test.go`
    - `app/lib/features/messaging/providers/message_provider.dart`
    - `app/lib/features/messaging/screens/chat_screen.dart`
  - Runtime evidence captured for unlocked chat send after quest approval.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

### Epic 3
- Story 3.1 Add gesture composer and timeline integration (8 SP): **Completed**
  - Added gesture timeline endpoints and persistence wiring:
    - `GET /v1/matches/{matchID}/timeline`
    - `POST /v1/matches/{matchID}/gestures`
    - `POST /v1/matches/{matchID}/gestures/{gestureID}/decision`
  - Added decision flows for `appreciate`, `decline`, `request_better` with timeline status updates.
  - Added durable table migration and repository flow for gesture lifecycle.
  - Added Flutter gesture timeline + composer integration in chat flow with one-tap decision controls:
    - timeline cards show sender content, timestamp/status, and effort score
    - composer supports thoughtful opener / micro-card / challenge token with tone and message
    - receiver can decide `appreciate` / `request_better` / `decline`
  - Evidence:
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/gestures.go`
    - `backend/internal/bff/mobile/quest_repository.go`
    - `backend/internal/modules/matching/application/service.go`
    - `backend/internal/modules/matching/infrastructure/store_gateway.go`
    - `backend/scripts/018_match_gestures_effort_signals.sql`
    - `app/lib/features/matching/providers/gesture_timeline_provider.dart`
    - `app/lib/features/messaging/screens/chat_screen.dart`
  - Runtime evidence captured for gesture create/decision/timeline lifecycle.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

- Story 3.2 Implement effort signal scoring v1 (8 SP): **Completed**
  - Added rule-based effort scoring for gestures with:
    - minimum quality checks
    - originality heuristic checks
    - profanity/safety flagging
  - Added score retrieval endpoint:
    - `GET /v1/matches/{matchID}/gestures/{gestureID}/score`
  - Score outcomes are persisted and queryable from durable storage.
  - Added backend activity logging hooks for trust/analytics (`gesture.create`, `gesture.decision`).
  - Moved scoring policy to config/env (no hard-coded thresholds/token list in service logic).
  - Added focused endpoint tests for timeline decision flow and profanity flagging.
  - Evidence:
    - `backend/internal/bff/mobile/gestures.go`
    - `backend/internal/bff/mobile/server_gesture_timeline_test.go`
    - `backend/internal/platform/config/config.go`
    - `backend/config/.env`
    - `backend/internal/modules/matching/application/commands.go`
    - `backend/internal/modules/matching/application/service.go`
  - Test result:
    - `runTests`: `server_quest_workflow_test.go` + `server_gesture_timeline_test.go` + `service_quest_template_test.go` passed (9 tests).
  - Runtime evidence captured for score endpoint and appreciated-state score output.
  - Evidence:
    - `documents/codex/CANONICAL_SMOKE_EVIDENCE_20260228T183910Z.json`

### Epic 4
- Story 4.1 Activity session lifecycle APIs (13 SP): **Completed**
  - Added activity session lifecycle endpoints in mobile BFF:
    - `POST /v1/activities/sessions/start`
    - `POST /v1/activities/sessions/{sessionID}/submit`
    - `GET /v1/activities/sessions/{sessionID}/summary`
  - Added timer-based expiry (180 seconds), partial-timeout handling, timeout finalization, and persisted summary retrieval.
  - Added focused backend tests for complete and partial-timeout lifecycles.
  - Runtime smoke artifact captured with successful start/submit/summary flow.
  - Evidence:
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/server_activity_session_test.go`
    - `documents/codex/ACTIVITY_SESSION_SMOKE_20260228T185526Z.json`
    - `documents/codex/completed/EPIC4_STORY_4_1_ACTIVITY_SESSION_LIFECYCLE_REPORT.md`

- Story 4.2 Build activity UI flows in Flutter (13 SP): **Completed**
  - Added new activity session provider for Story 4.1 APIs:
    - session start, response submit, summary retrieval
    - timeout-aware submit behavior and summary fallback
  - Added dedicated Flutter activity UI flow screen with required interfaces:
    - This-or-that prompt card
    - Value-match prompt card
    - Scenario-choice prompt card
  - Added timer countdown UX and timeout handling CTA to load summary.
  - Added summary card rendering for completion/timeout states.
  - Integrated activity launch from match/chat flow via chat CTAs.
  - Added focused Flutter tests for question-set contract and countdown helper logic.
  - Evidence:
    - `app/lib/features/matching/providers/activity_session_provider.dart`
    - `app/lib/features/matching/screens/activity_session_screen.dart`
    - `app/lib/features/messaging/screens/chat_screen.dart`
    - `app/test/features/matching/providers/activity_session_provider_test.dart`
    - `documents/codex/completed/EPIC4_STORY_4_2_ACTIVITY_UI_FLOW_REPORT.md`
    - `documents/codex/EPIC4_STORY_4_2_EMULATOR_EVIDENCE_20260301.json`
    - `documents/codex/artifacts/story_4_2_emulator/01_discover_after_auth.png`
    - `documents/codex/artifacts/story_4_2_emulator/02_matches_tab.png`
    - `documents/codex/artifacts/story_4_2_emulator/03_chat_screen.png`
    - `documents/codex/artifacts/story_4_2_emulator/04_activity_screen_loaded.png`
    - `documents/codex/artifacts/story_4_2_emulator/05_activity_after_submit.png`
    - `documents/codex/artifacts/story_4_2_emulator/06_activity_summary_visible.png`
    - `documents/codex/artifacts/story_4_2_emulator/07_activity_refreshed_for_timeout.png`
    - `documents/codex/artifacts/story_4_2_emulator/08_activity_timeout_state.png`

### Epic 5
- Story 5.1 Compute trust milestones and assign badges (8 SP): **Completed**
  - Added deterministic trust milestone + badge computation engine for MVP badge set:
    - `prompt_completer`
    - `respectful_communicator`
    - `consistent_profile`
    - `verified_active`
  - Added automatic unsafe-behavior revocation logic tied to moderation/safety signals.
  - Added auditable badge history event model for award/revoke transitions.
  - Added trust badge APIs:
    - `GET /v1/users/{userID}/trust-badges`
    - `GET /v1/users/{userID}/trust-badges/history`
  - Added focused backend tests for assignment/history and revocation behavior.
  - Evidence:
    - `backend/internal/bff/mobile/trust_badges.go`
    - `backend/internal/bff/mobile/server_trust_badges.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/server_trust_badges_test.go`
    - `documents/codex/completed/EPIC5_STORY_5_1_TRUST_BADGES_REPORT.md`

- Story 5.2 Women trust filter controls in discovery/matches (8 SP): **Completed**
  - Added trust filter persistence model and validation with per-user storage:
    - `enabled`
    - `minimum_active_badges`
    - `required_badge_codes`
  - Added trust filter APIs:
    - `GET /v1/discovery/{userID}/filters/trust`
    - `PATCH /v1/discovery/{userID}/filters/trust`
  - Added response-layer trust filtering for:
    - discovery candidates (`/v1/discovery/{userID}`)
    - match list (`/v1/matches/{userID}`)
  - Added trust filter summary metadata to response payloads (`active`, `filtered_out_count`) for UI empty-state explanations.
  - Added Flutter trust filter controls in existing Discover filter sheet with backend persistence and profile/match refresh on apply.
  - Added Flutter empty-state explanation when trust filtering removes all results.
  - Added focused tests:
    - `backend/internal/bff/mobile/server_trust_filters_test.go`
    - `app/test/features/matching/providers/trust_filter_provider_test.dart`
  - Evidence:
    - `backend/internal/bff/mobile/trust_filters.go`
    - `backend/internal/bff/mobile/server_trust_filters.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_trust_filters_test.go`
    - `app/lib/features/matching/providers/trust_filter_provider.dart`
    - `app/lib/features/common/screens/main_navigation_screen.dart`
    - `app/lib/features/swipe/providers/swipe_provider.dart`
    - `app/lib/features/matching/providers/match_provider.dart`
    - `app/lib/features/swipe/screens/home_discovery_screen.dart`
    - `app/lib/features/matching/screens/matches_list_screen.dart`
    - `app/test/features/matching/providers/trust_filter_provider_test.dart`
    - `documents/codex/completed/EPIC5_STORY_5_2_TRUST_FILTERS_REPORT.md`

### Epic 6
- Story 6.1 Room scheduling and participation endpoints (8 SP): **Completed**
  - Added weekly conversation room endpoints:
    - `GET /v1/rooms`
    - `POST /v1/rooms/{roomID}/join`
    - `POST /v1/rooms/{roomID}/leave`
  - Implemented room lifecycle support with state transitions:
    - `scheduled` → `active` → `closed`
  - Enforced room capacity limits on join and returned conflict when full (`ROOM_CAPACITY_REACHED`).
  - Added participation activity events for join/leave operations (`room.participation.join`, `room.participation.leave`).
  - Added focused backend tests for lifecycle state coverage, capacity enforcement, and activity logging.
  - Evidence:
    - `backend/internal/bff/mobile/rooms.go`
    - `backend/internal/bff/mobile/server_rooms.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_rooms_test.go`
    - `documents/codex/completed/EPIC6_STORY_6_1_ROOM_ENDPOINTS_REPORT.md`

- Story 6.2 Moderator controls for room safety (8 SP): **Completed**
  - Added moderator endpoint for room safety actions:
    - `POST /v1/rooms/{roomID}/moderate`
  - Added moderation action handling for policy enforcement actions:
    - `warn_user`
    - `remove_user`
  - Added persistent moderation audit trail storage for room actions in mobile BFF memory store.
  - Added active-session removal enforcement: removed users are blocked from rejoining while room session remains active (`ROOM_BLOCKED_ACTIVE_SESSION`).
  - Added moderation activity events (`room.moderation.action`) including moderator, target, room, and reason metadata.
  - Added focused backend tests for endpoint behavior, audit persistence, and active-session block enforcement.
  - Evidence:
    - `backend/internal/bff/mobile/rooms.go`
    - `backend/internal/bff/mobile/server_rooms.go`
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_room_moderation_test.go`
    - `documents/codex/completed/EPIC6_STORY_6_2_ROOM_MODERATION_REPORT.md`

### Epic 7
- Story 7.1 Add test coverage for success/failure/edge scenarios (13 SP): **Completed**
  - Expanded Flutter provider/state tests for happy + failure paths:
    - `ActivitySessionState` completion/terminal/error-clearing behavior
    - `ActivitySummary.fromJson` happy path and malformed payload fallback behavior
    - `TrustFilterState` active filter + error-clearing + criteria replacement behavior
  - Hardened `ActivitySummary.fromJson` parsing to safely handle malformed numeric fields.
  - Expanded backend API tests for room moderation validation and transition cases:
    - invalid moderation action validation (`400`)
    - active-room transition enforcement for removal (`ROOM_NOT_ACTIVE`)
    - removal block enforcement for active room rejoin (`ROOM_BLOCKED_ACTIVE_SESSION`)
  - Executed expanded cross-epic backend and Flutter suites to cover new unlock/activity/trust/room flows.
  - Evidence:
    - `app/test/features/matching/providers/activity_session_provider_test.dart`
    - `app/test/features/matching/providers/trust_filter_provider_test.dart`
    - `app/lib/features/matching/providers/activity_session_provider.dart`
    - `backend/internal/bff/mobile/server_room_moderation_test.go`
    - `backend/internal/bff/mobile/server_rooms_test.go`
    - `backend/internal/bff/mobile/server_trust_filters_test.go`
    - `backend/internal/bff/mobile/server_activity_session_test.go`
    - `backend/internal/bff/mobile/server_quest_workflow_test.go`
    - `backend/internal/bff/mobile/server_gesture_timeline_test.go`
    - `backend/internal/bff/mobile/server_trust_badges_test.go`
    - `documents/codex/completed/EPIC7_STORY_7_1_TEST_COVERAGE_REPORT.md`

- Story 7.2 Production metrics and feature flag rollout (8 SP): **Completed**
  - Added capability feature flags across backend + Flutter runtime configuration:
    - `engagement_unlock_mvp`
    - `digital_gestures`
    - `mini_activities`
    - `trust_badges`
    - `conversation_rooms`
  - Added funnel metrics to admin analytics overview for Story 7.2 KPI requirements:
    - `unlock_completion_rate`
    - `gesture_acceptance_rate`
    - `activity_completion_rate`
    - `report_rate_per_1k_interactions`
  - Added validation tests for feature-flag loading and analytics payload shape.
  - Rollback playbook validation documented with toggle-and-verify procedure and evidence run.
  - Evidence:
    - `backend/internal/platform/config/config.go`
    - `backend/internal/platform/config/config_test.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_admin_test.go`
    - `backend/config/.env`
    - `app/lib/core/config/feature_flags.dart`
    - `app/test/core/config/feature_flags_test.dart`
    - `documents/codex/completed/EPIC7_STORY_7_2_FEATURE_FLAGS_METRICS_REPORT.md`

### Epic 7 (Post-backlog enhancements requested on 1 Mar 2026)
- Story 7.3 Advanced profile tags + real discovery/match filtering (extension): **Completed**
  - Added latest profile preferences fields and tags in setup UX:
    - intent, language, pet preference, workout frequency, diet type, sleep schedule, travel style, political comfort range, deal-breaker tags.
  - Added real API impact by passing advanced filters from Flutter and applying them in backend discovery/match pipelines.
  - Added durable DB table/index coverage for profile tag filters and trust filter preferences.
  - Evidence:
    - `app/lib/features/profile/screens/setup/setup_preferences_screen.dart`
    - `app/lib/features/profile/providers/profile_setup_provider.dart`
    - `app/lib/features/swipe/providers/swipe_provider.dart`
    - `app/lib/features/matching/providers/match_provider.dart`
    - `backend/internal/bff/mobile/server_advanced_filters.go`
    - `backend/scripts/021_social_graph_and_tag_filter_indexes.sql`

- Story 7.4 Friends graph + friends engagement surfaces (extension): **Completed**
  - Added friends APIs (list/add/remove) and friend activity feed APIs.
  - Added Friends app surfaces and integration in Engagement + Settings.
  - Added dedicated Friends bottom navigation tab and friend-only room filter toggle.
  - Added backend friend-only room filtering and tests.
  - Added durable DB table/index coverage for social graph and friend activities.
  - Evidence:
    - `backend/internal/bff/mobile/server_friends.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_rooms.go`
    - `backend/internal/bff/mobile/rooms.go`
    - `backend/internal/bff/mobile/server_social_filters_test.go`
    - `backend/internal/bff/mobile/server_rooms_test.go`
    - `app/lib/features/friends/providers/friends_provider.dart`
    - `app/lib/features/friends/screens/friends_screen.dart`
    - `app/lib/features/common/screens/main_navigation_screen.dart`
    - `app/lib/features/engagement/screens/conversation_rooms_screen.dart`
    - `backend/scripts/021_social_graph_and_tag_filter_indexes.sql`

## Story 1-7 Visibility/API/DB Audit (1 Mar 2026)

| Story | UI visibility in app | API implemented | DB table/migration coverage | Result |
|---|---|---|---|---|
| 1.1 | Operational runbook story (no new screen) | N/A | N/A | Completed |
| 1.2 | Baseline smoke flow (Auth/Profile/Swipe/Chat visible) | Core APIs verified | Core schema + smoke migrations | Completed |
| 2.1 | Unlock state exposed in match/chat flow | `/matches/{id}/unlock-state` | `014_engagement_unlock_tables.sql` | Completed |
| 2.2 | Quest requirement visible in match/chat flow | quest template GET/PUT endpoints | `014_engagement_unlock_tables.sql` | Completed |
| 2.3 | Quest submit/review visible from chat unlock flow | quest workflow endpoints | `014_engagement_unlock_tables.sql` | Completed |
| 2.4 | Chat lock CTA visible in chat UI | chat send gate + lock error code | unlock/workflow tables in `014` | Completed |
| 3.1 | Gesture timeline/composer visible in chat | timeline/create/decision APIs | `018_match_gestures_effort_signals.sql` | Completed |
| 3.2 | Gesture score and moderation outcome surfaced | score endpoint | `018_match_gestures_effort_signals.sql` | Completed |
| 4.1 | Activity state consumed by UI | session start/submit/summary APIs | activity tables in `020_engagement_surfaces_tables.sql` | Completed |
| 4.2 | Activity screen fully visible from chat | Uses 4.1 APIs | activity tables in `020` | Completed |
| 5.1 | Trust badges visible in Engagement + Settings | trust badge + history APIs | trust badge tables in `020_engagement_surfaces_tables.sql` | Completed |
| 5.2 | Trust filters visible in Discover + dedicated screen | trust filter GET/PATCH + applied in discovery/matches | trust filter preferences table in `021_social_graph_and_tag_filter_indexes.sql` | Completed |
| 6.1 | Conversation rooms visible in Engagement + Settings | list/join/leave APIs | rooms/participants tables in `020_engagement_surfaces_tables.sql` | Completed |
| 6.2 | Moderation controls visible in room screen | moderation API | moderation action tables in `020_engagement_surfaces_tables.sql` | Completed |
| 7.1 | Test stories (no standalone UI) | coverage expanded and passing in focused suites | N/A | Completed |
| 7.2 | Feature flags visible in runtime behavior | admin metrics + flag configuration APIs | N/A (config/observability story) | Completed |

## Remaining Work Summary
- No backlog stories remain pending from the imported Jira scope.

## ALN Alignment Tracker Update (3 Mar 2026)
- ALN-3.4 Rejection/moderation appeals workflow: **Completed**
  - Added user appeal submit/status APIs and admin appeal queue/action APIs.
  - Added appeal state model (`submitted`, `under_review`, `resolved_upheld`, `resolved_reversed`) with SLA + notification policy fields.
  - Added moderation appeal activity audit events and backend tests.
  - Evidence:
    - `backend/internal/bff/mobile/server.go`
    - `backend/internal/bff/mobile/store.go`
    - `backend/internal/bff/mobile/server_appeals_test.go`
    - `backend/internal/platform/docs/openapi.yaml`

- ALN-4.1 KPI dashboard and event taxonomy signoff: **Completed**
  - Added analytics dimensions for panel coverage, taxonomy versioning, and data quality checks.
  - Added signoff documentation and control-panel visibility for metrics metadata.
  - Evidence:
    - `backend/internal/bff/mobile/store.go`
    - `control-panel/control_panel/views.py`
    - `control-panel/templates/control_panel/dashboard.html`
    - `documents/codex/ALN_3_4_5_APPEALS_AND_KPI_SIGNOFF_2026-03-03.md`

- ALN-4.2 Phase A release gate checklist + go/no-go runbook: **Completed (artifacts prepared)**
  - Added explicit release gate checklist with API health, test criteria, moderation staffing, and rollback steps.
  - Added go/no-go runbook with owner approvals and decision protocol.
  - Added staging dry-run evidence artifact template including local validation results and staging execution fields.
  - Evidence:
    - `documents/codex/ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md`
    - `documents/codex/ALN_4_2_PHASE_A_GO_NO_GO_RUNBOOK_2026-03-03.md`
    - `documents/codex/ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md`

## Completion Rule Used
A story is marked **Completed** only when all of the below are done:
1. Functional implementation merged.
2. Acceptance criteria validated.
3. Required automated tests added/passing.
4. Release/rollback and observability checks complete.
