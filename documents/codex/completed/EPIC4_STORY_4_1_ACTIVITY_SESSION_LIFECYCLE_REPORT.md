# Epic 4 - Story 4.1 Activity Session Lifecycle APIs Report

Date: 1 Mar 2026
Story: Epic 4 / Story 4.1 (13 SP)

## Acceptance Criteria Validation

1. Timer-based expiry at 180 seconds
- Implemented `activitySessionDuration = 180 * time.Second`.
- Session `expires_at` is set at creation and evaluated on submit/summary retrieval.
- Evidence:
  - `backend/internal/bff/mobile/store.go`

2. Handles partial completion and timeout states
- Implemented status model:
  - `active`
  - `completed`
  - `timed_out`
  - `partial_timeout`
- Timeout finalization logic runs on submit and summary reads.
- Partial timeout occurs when at least one participant submitted before expiry.
- Evidence:
  - `backend/internal/bff/mobile/store.go`
  - `backend/internal/bff/mobile/server_activity_session_test.go`

3. Summary persisted and available via API
- Summary is generated and stored in session record after completion/timeout transitions.
- Summary endpoint returns persisted summary + current session snapshot.
- Evidence:
  - `backend/internal/bff/mobile/server.go`
  - `backend/internal/bff/mobile/store.go`

## Delivered API Endpoints

- `POST /v1/activities/sessions/start`
  - Starts an activity session for two participants, sets 180-second expiry.
- `POST /v1/activities/sessions/{sessionID}/submit`
  - Submits participant responses and advances lifecycle.
- `GET /v1/activities/sessions/{sessionID}/summary`
  - Returns persisted activity summary and session state.

## Runtime Evidence

- Live smoke artifact (all steps passed):
  - `documents/codex/ACTIVITY_SESSION_SMOKE_20260228T185526Z.json`
- Includes successful start, dual submissions, and summary retrieval with `completed` state.

## Test Evidence

- Focused backend tests passed:
  - `backend/internal/bff/mobile/server_activity_session_test.go`
  - `backend/internal/bff/mobile/server_quest_workflow_test.go`
  - `backend/internal/bff/mobile/server_gesture_timeline_test.go`
- Result: `8 passed / 0 failed`

## Story Status

- Status: Completed
- Notes:
  - Story 4.2 (Flutter activity UX) remains pending and should consume these APIs.
