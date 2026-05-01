
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

- Reject any PR that exposes a write endpoint without:
  - durable table write path,
## Architecture map
- Monorepo surfaces: Flutter mobile app in `app/`, Go services/BFF/gateway in `backend/`, Django operator console in `control-panel/`.
- Runtime request path is Flutter or Django → API Gateway (`backend/cmd/api-gateway`) → Mobile BFF (`backend/cmd/mobile-bff`) → gRPC services and/or Supabase/Postgres repositories.
- Keep the gateway thin: `backend/internal/gateway/http/server.go` is reverse proxy plus edge middleware only. Put feature orchestration in Mobile BFF handlers or `backend/internal/modules/<module>/application` services.
- Go module boundaries use `backend/internal/modules/<module>/{application,infrastructure}`; `backend/scripts/check_backend_compliance.sh` enforces this for auth/profile/matching/chat/admin/billing/verification/safety/calls.
- BFF route wiring is centralized in `backend/internal/bff/mobile/server.go`; route aliases must use `withAliasDeprecation` instead of silently removing old paths.

## Backend invariants
- Preserve middleware order exactly: gateway = correlation ID → exception → inflight shedding → IP rate limit → request logging; BFF = correlation ID → exception → inflight shedding → bulkhead → idempotency → request logging → activity middleware.
- Correlation IDs are end-to-end: Flutter injects `X-Correlation-ID` and `X-Client-Platform` in `app/lib/core/providers/api_client_provider.dart`; Go logs and middleware expect them.
- Do not add runtime `http://localhost` or `10.0.2.2` literals in non-test Go files outside config defaults; compliance fails this.
- `validateDurableEngagementReadiness` blocks BFF boot when durable engagement persistence is required; schema/repository changes must keep `RequireDurableEngagementStore=true` viable.
- Product state should be durable-first: add/extend Supabase/Postgres repositories like `backend/internal/bff/mobile/groups_repository.go`, `daily_prompt_repository.go`, or `gifts_repository.go`; treat `memoryStore` as fallback/test scaffolding.

## API, persistence, and contracts
- OpenAPI source of truth is `backend/internal/platform/docs/openapi.yaml`; snapshots live in `backend/internal/platform/docs/contracts/` and document error envelopes such as `ErrorResponse` and `ChatLockedErrorResponse`.
- For client-visible API changes: update BFF route/handler, OpenAPI, contract snapshot if applicable, and run `make proto` from `backend/` when protobufs changed.
- Migrations live in `backend/scripts/` and must be ordered in `backend/scripts_run_order.txt`; canonical production schemas are `matching` and `user_management`.
- Write endpoints that persist data need durable table writes, idempotency semantics, and durable reporting/activity output (for example wallet/gift flows use gift/wallet tables plus spend/activity records).

## Local workflows
- Backend: from `backend/`, use `make run-all` / `make stop-all`; logs and PIDs are under `backend/.run/`; health is gateway `:8080/healthz|readyz` and BFF `:8081/healthz|readyz`.
- Backend validation: run `go test ./...` then `make backend-compliance-check` from `backend/`.
- ELK observability: from `backend/`, local binaries use `make elk-up-local`, `make elk-status-local`, `make elk-down-local`; Docker fallback is `make elk-up`, `make elk-down`.
- Flutter: from `app/`, use `flutter analyze` and `flutter test`; run codegen with `dart run build_runner build --delete-conflicting-outputs` after Freezed/JSON/Riverpod annotation changes; do not edit generated `*.g.dart` or `*.freezed.dart` files.
- Django control panel: from `control-panel/`, use the virtualenv, install `requirements.txt`, run migrations, then `python manage.py runserver`; it talks to Go admin APIs rather than local Django domain models.

## Client and admin integration
- Flutter config precedence is `.env.local` / `.env` → `--dart-define` → defaults in `app/lib/core/config/app_runtime_config.dart`; Android emulator API base is typically `http://10.0.2.2:8080/v1`.
- `app/lib/main.dart` intentionally rejects mock auth/discovery flags in release builds; keep this guard when touching startup.
- Flutter state/network patterns are Riverpod providers plus Dio clients under `app/lib/features/**/providers` and `app/lib/core/providers`.
- `control-panel/control_panel/services/go_client.py` is an API consumer only; it sets `X-Admin-User` and calls `/v1/admin/*` (plus selected wallet endpoints), so do not duplicate Go business logic in Django.
- Control-panel Kibana embedding reads `KIBANA_BASE_URL`, `KIBANA_DISCOVER_INDEX`, and `KIBANA_DASHBOARD_PATH`; backend ELK indexes logs as `dating-app-logs-*`.
