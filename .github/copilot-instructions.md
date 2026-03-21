
# Copilot Instructions for AI Coding Agents

## Monorepo shape and request flow
- Runtime surfaces: Flutter app (`app/`), Go backend (`backend/`), Django operator console (`control-panel/`).
- Runtime path is: client/control-panel → API Gateway (`backend/cmd/api-gateway`) → Mobile BFF (`backend/cmd/mobile-bff`) → module services/stores.
- Keep gateway thin (reverse proxy + edge middleware). Put feature orchestration in Mobile BFF or module `application` services.
- Backend module boundary is enforced: `backend/internal/modules/<module>/{application,infrastructure}` (`backend/scripts/check_backend_compliance.sh`).

## Non-negotiable backend conventions
- Preserve middleware order exactly:
  - Gateway (`backend/internal/gateway/http/server.go`): CorrelationID → exception handler → inflight shedding → IP rate limit → request logging.
  - Mobile BFF (`backend/internal/bff/mobile/server.go`): CorrelationID → exception handler → inflight shedding → bulkhead → idempotency → request logging → activity middleware.
- Correlation is end-to-end: backend expects `X-Correlation-ID`; Flutter injects it in `app/lib/core/providers/api_client_provider.dart`.
- Do not hardcode runtime local URLs in non-test Go files (`http://localhost`, `10.0.2.2`) except config defaults; compliance check fails otherwise.
- For route renames, keep compatibility using `withAliasDeprecation` in BFF routes.
- `validateDurableEngagementReadiness` in BFF startup can block boot when durable persistence is required; schema changes must respect this gate.

## API contract + persistence workflow
- OpenAPI source of truth: `backend/internal/platform/docs/openapi.yaml`.
- After API changes: update OpenAPI, run `make proto` (from `backend/`), and sync contract snapshot in `backend/internal/platform/docs/contracts/`.
- Apply DB migrations in strict order from `backend/scripts_run_order.txt` (canonical schemas: `matching`, `user_management`).
- Durable engagement features commonly use repository + fallback memory patterns under `backend/internal/bff/mobile/` (see `groups.go` + `groups_repository.go`).

## Persistence-first module policy (mandatory)
- In-memory-only product functionality is not allowed for backend production paths.
- Any new module or feature state must have a durable repository and table(s) before endpoint rollout.
- Treat `memoryStore` as temporary fallback/test scaffolding only; do not introduce new persistent product state there.
- If a fallback is temporarily required, gate it behind config and keep `RequireDurableEngagementStore=true` compatibility.
- Every persistence-bearing endpoint must document:
  - storage table(s),
  - idempotency strategy,
  - retry/recovery behavior,
  - reporting/event outputs.
- Use repository + application service orchestration (Clean Architecture) for all new persistent flows.

### Persistence enforcement (PR blocking)
- Reject any PR that introduces new product state fields/maps/slices in `backend/internal/bff/mobile/memoryStore` unless the same PR includes durable table(s) + repository + migration.
- Reject any PR that exposes a write endpoint without:
  - durable table write path,
  - idempotency contract (header/key + conflict behavior),
  - retry/recovery handling,
  - event emission into reporting pipeline (`matching.activity_events` or module-specific durable event table).
- Reject any PR that adds analytics from process memory. Analytics/reporting must be generated from durable tables or materialized views.

### Mandatory persistent module design pattern
- `application` layer:
  - define use-cases/commands/queries and transaction boundaries,
  - enforce invariants and idempotency semantics,
  - emit domain events for reporting.
- `infrastructure` layer:
  - implement repository interfaces against PostgreSQL/Supabase,
  - include optimistic concurrency/version or uniqueness constraints where needed,
  - support deterministic retries and compensating updates where multi-write flows exist.
- `delivery` (BFF handlers):
  - call application services only,
  - no direct in-memory mutation for persistent product state,
  - preserve correlation-id and structured logging.

### Definition of done for persistent features
- Migration SQL created and ordered in `backend/scripts_run_order.txt`.
- OpenAPI updated and contracts regenerated where API changed.
- Durable-mode startup passes (`RequireDurableEngagementStore=true`).
- Tests cover happy path + idempotent replay + failure/retry path + reporting event output.

### Required backend module pattern for persistent features
- Add use-cases in `backend/internal/modules/<module>/application`.
- Add adapters/repositories in `backend/internal/modules/<module>/infrastructure`.
- Wire BFF handlers to application services, not direct in-memory state mutation.
- Add migration SQL under `backend/scripts/` and append ordering in `backend/scripts_run_order.txt`.
- Add read models/queries needed for reporting and admin analytics at implementation time.

### Mandatory table backlog reference
- Use `documents/codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md` as the source backlog for eliminating in-memory state and creating missing durable tables.

## Critical local workflows
- Backend lifecycle (from `backend/`): `make run-all`, `make stop-all`.
- Health checks: gateway `:8080/healthz` + `:8080/readyz`, BFF `:8081/healthz` + `:8081/readyz`.
- Validation loop for backend changes: `go test ./...` then `make backend-compliance-check`.
- ELK local stack: `make elk-up-local`, `make elk-status-local`, `make elk-down-local` (docker fallback: `make elk-up`, `make elk-down`).
- Flutter checks (from `app/`): `flutter analyze`, `flutter test`.

## Flutter + Django integration points
- Flutter runtime config precedence is `.env.local/.env` → `--dart-define` → defaults (`app/lib/core/config/app_runtime_config.dart`).
- `app/lib/main.dart` explicitly disallows mock-auth/mock-discovery flags in release; keep this guard.
- Flutter API client always sends `X-Correlation-ID` and `X-Client-Platform`; do not remove.
- Control panel is API-consumer only (no duplicated domain logic): `control-panel/control_panel/services/go_client.py`.
- Admin API calls rely on `X-Admin-User` header set by `GoBFFClient`; preserve this behavior when adding `/v1/admin/*` endpoints.

## High-value implementation patterns
- New backend capability: add module use-case in `internal/modules/<module>/application`, adapter in `infrastructure`, then wire BFF route/handler.
- New BFF persistence feature: follow `*_repository.go` + store wrapper pattern with durable-first behavior and controlled fallback.
- New client-visible API: update OpenAPI and keep error envelope compatibility (`components.schemas.ErrorResponse`, `ChatLockedErrorResponse`).

## Delivery guardrails
- Prefer Clean Architecture, DDD, Mediator/MediatR-style request orchestration, KISS, DRY, and SOLID for all new changes.
- Every transactional workflow must preserve ACID properties end-to-end across application logic, persistence, retries, and recovery handling.
- For Flutter and Go changes, preserve structured logging, correlation-id propagation, and explicit exception/error handling on every networked or stateful flow.
- Add explicit user-facing handling for network instability: detect offline/weak-network states, notify users clearly, and design networked experiences around a minimum smooth-usage target of roughly 5 Mbps.
- Keep UI fixes thin in screens/widgets and move non-trivial orchestration into providers, application services, or module/application layers.
