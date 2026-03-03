# Epic 6 - Story 6.2 Room Moderation Controls Report

Date: 1 Mar 2026
Story: Epic 6 / Story 6.2 (8 SP)
Status: Completed

## Scope
Implement moderator safety controls for weekly rooms with:
1. Moderator action endpoint available
2. Action audit trail persisted
3. Removed user blocked from active session

## Implemented
- Added room moderation endpoint:
  - `POST /v1/rooms/{roomID}/moderate`
- Added moderation policy actions:
  - `warn_user`
  - `remove_user`
- Added persistent moderation action trail in store (`roomModerationActions`) with:
  - moderator user
  - target user
  - room id
  - action
  - reason
  - timestamp
- Added active-session enforcement for removed users:
  - removal from current participants
  - active-session block entry (`roomActiveBlocks`) until room end
  - join rejection while active with `ROOM_BLOCKED_ACTIVE_SESSION`
- Added moderation event logging to activity stream:
  - `room.moderation.action`

## Files
- `backend/internal/bff/mobile/rooms.go`
- `backend/internal/bff/mobile/server_rooms.go`
- `backend/internal/bff/mobile/server.go`
- `backend/internal/bff/mobile/store.go`
- `backend/internal/bff/mobile/server_room_moderation_test.go`

## Automated Test Evidence
- `runTests` target:
  - `backend/internal/bff/mobile/server_room_moderation_test.go`
  - `backend/internal/bff/mobile/server_rooms_test.go`
  - Result: passed 6, failed 0

## Acceptance Criteria Mapping
1. Moderator action endpoint available.
- Implemented via `POST /v1/rooms/{roomID}/moderate` with payload-based action handling.

2. Action audit trail persisted.
- Implemented via persisted moderation records in `roomModerationActions` and mirrored activity stream events.

3. Removed user is blocked from active session.
- Implemented by enforcing active-room block entries after `remove_user`; blocked users cannot rejoin until active session window ends.

## Notes
- Story 6.1 and 6.2 together now complete Epic 6 backend MVP surface for room participation and moderation safety controls.
