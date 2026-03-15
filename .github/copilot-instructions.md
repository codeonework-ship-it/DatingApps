# Copilot Instructions

Use these repo-specific rules to make safe, minimal changes across Flutter (`app/`), Go backend (`backend/`), and Django control panel (`control-panel/`).

## Architecture (work from boundaries)
- Request flow: Flutter / Django Control Panel → API Gateway (`backend/cmd/api-gateway`) → Mobile BFF (`backend/cmd/mobile-bff`) → module gateways + Supabase/Postgres.
- Gateway (`backend/internal/gateway/http/server.go`) is a resiliency edge, not feature logic: reverse proxying, correlation IDs, panic envelope, inflight shed, IP rate limit, ready-probe to BFF.
- Mobile BFF (`backend/internal/bff/mobile/server.go`) is the composition boundary: mediator registration, module orchestration, bulkheads, idempotency, activity/admin surfaces.
- Module layering is enforced as `backend/internal/modules/<module>/{application,infrastructure}`; compliance script validates this (`backend/scripts/check_backend_compliance.sh`).

## Non-negotiable backend contracts
- Keep runtime config in `backend/internal/platform/config/config.go`; avoid hardcoded `localhost` / emulator URLs in runtime Go files.
- Do not spend time probing for an active git repo; assume the provided workspace is authoritative and proceed with code/file workflows directly.
- Do not inspect active git changed-file state (`git status`/diff tooling) unless the user explicitly asks.
- Preserve middleware order:
  - Gateway: correlation → exception → inflight shed → `httprate` → request logging
  - BFF: correlation → exception → inflight shed → bulkhead → idempotency → request logging
- Keep observability HTTP contract in `backend/internal/platform/observability/http.go`:
  - header round-trip: `X-Correlation-ID`
  - panic envelope keys: `success`, `error`, `error_code`, `correlation_id`
- Add new backend behavior in module `application` and register handlers in BFF bootstrap (mediator wiring in `backend/internal/bff/mobile/server.go`).

## Critical workflows
- Backend lifecycle (`backend/`): `make run-all`, `make stop-all`, `make backend-compliance-check`.
- `make run-all` runs `backend/scripts/dev_up.sh` (loads `config/.env` or `.env.local`, writes logs to `.run/logs`, pids to `.run/pids`).
- Fast health checks:
  - Gateway: `http://localhost:8080/healthz`, `/readyz`, `/docs`, `/openapi.yaml`
  - BFF: `http://localhost:8081/healthz`, `/readyz`
- Proto updates: edit `backend/api/proto/*.proto` then run `make proto`.
- Durable engagement SQL rollout is order-sensitive; follow `backend/scripts_run_order.txt` (notably `014`, `018`, `019`, `020`, `021`, `025`, `027`, `028`, `029`).

## Cross-app integration points
- OpenAPI source of truth: `backend/internal/platform/docs/openapi.yaml`; keep snapshots in `backend/internal/platform/docs/contracts/` in sync.
- Flutter sets `X-Correlation-ID` and `X-Client-Platform` in `app/lib/core/providers/api_client_provider.dart`; backend changes must not break these headers.
- Flutter runtime config is env + dart-define (`app/lib/core/config/app_runtime_config.dart`), default Android emulator API URL: `http://10.0.2.2:8080/v1`.
- `app/lib/main.dart` blocks `USE_MOCK_AUTH` / `USE_MOCK_DISCOVERY_DATA` in release mode; do not introduce release paths that rely on mock flags.
- Control panel is BFF-consumer-only: use `control-panel/control_panel/services/go_client.py` (`X-Admin-User` required), keep domain logic in Go services.

## Tests and observability touchpoints
- Backend: prefer targeted `_test.go` updates near changed modules, then `go test ./...` from `backend/`.
- Flutter: run focused tests in `app/test/` before broader `flutter test`.
- Flutter UI/dev loop: after Flutter code changes, hot reload the running emulator/device session when available before reporting completion.
- Control panel local flow is defined in `control-panel/README.md` (venv, requirements, migrate, runserver).
- ELK local lifecycle (`backend/`): `make elk-up-local`, `make elk-status-local`, `make elk-down-local`.
- Kibana index/data-view pattern used across backend + control panel: `dating-app-logs-*`.
