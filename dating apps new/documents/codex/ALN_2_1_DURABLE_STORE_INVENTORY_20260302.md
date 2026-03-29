# ALN-2.1 Durable Store Inventory (2 Mar 2026)

Scope: engagement flows only (`quest workflow`, `gestures`, `activities`, `trust badges`, `conversation rooms`).

## Durable mode guardrail
- Config: `REQUIRE_DURABLE_ENGAGEMENT_STORE`
- Default behavior:
  - `true` in `production/staging` environments
  - `false` in `development` unless explicitly set
- Startup policy (mobile BFF): fail fast when durable mode is on and requirements are not met.

## Fallback inventory mapping

| Flow | Previous in-memory fallback path | Durable replacement path | ALN-2.1 status |
|---|---|---|---|
| Quest template/workflow/unlock-state | `memoryStore.questTemplates` / `memoryStore.questWorkflows` in [backend/internal/bff/mobile/store.go](backend/internal/bff/mobile/store.go) | `questRepository` (`Supabase` engagement tables) in [backend/internal/bff/mobile/quest_repository.go](backend/internal/bff/mobile/quest_repository.go) | **Fallback removed in durable mode** |
| Digital gestures | `memoryStore.matchGestures` in [backend/internal/bff/mobile/gestures.go](backend/internal/bff/mobile/gestures.go) | `questRepository` gesture persistence in [backend/internal/bff/mobile/quest_repository.go](backend/internal/bff/mobile/quest_repository.go) | **Fallback removed in durable mode** |
| Mini activities | `memoryStore.activitySessions` in [backend/internal/bff/mobile/store.go](backend/internal/bff/mobile/store.go) | Durable store not yet implemented | **Startup blocked in durable mode** |
| Trust badges/filters | `memoryStore.trustMilestones`, `memoryStore.userBadges`, `memoryStore.trustFilters` in [backend/internal/bff/mobile/store.go](backend/internal/bff/mobile/store.go) | Durable store not yet implemented | **Startup blocked in durable mode** |
| Conversation rooms | `memoryStore.rooms`, `memoryStore.roomParticipants`, moderation maps in [backend/internal/bff/mobile/store.go](backend/internal/bff/mobile/store.go) | Durable store not yet implemented | **Startup blocked in durable mode** |

## Implementation notes
1. Durable mode now disables silent fallback for quest/gesture operations and surfaces persistence errors.
2. Chat unlock checks fail-safe in durable mode when persistent unlock state cannot be read.
3. `NewServer` now validates durable readiness and returns startup error when:
   - quest/gesture durable repository is unavailable, or
   - memory-only engagement features are enabled under durable mode.

## Follow-up required
- Implement durable repositories for:
  - activity sessions and summaries
  - trust milestones/badges/filter preferences
  - room lifecycle/participants/moderation actions
- Once implemented, remove corresponding startup-block conditions.
