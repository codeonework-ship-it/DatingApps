# Mobile BFF OpenAPI Contracts

- Canonical live file: `backend/internal/platform/docs/openapi.yaml`
- Versioned snapshot: `backend/internal/platform/docs/contracts/openapi-mobile-bff-v2026-03-02.yaml`

## Snapshot scope (v2026-03-02)
This snapshot includes the implemented engagement API surface used by the mobile BFF:
- Unlock state + quest template/workflow endpoints
- Gesture timeline/create/decision/score endpoints
- Activity session start/submit/summary endpoints
- Trust badge and trust-filter endpoints
- Conversation room list/join/leave/moderate endpoints
- Chat locked response contract with domain error code `CHAT_LOCKED_REQUIREMENT_PENDING`

## Error envelope contract
Standard error fields are documented in OpenAPI components under:
- `components.schemas.ErrorResponse`
- `components.schemas.ChatLockedErrorResponse`
