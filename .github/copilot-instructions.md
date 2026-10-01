# Copilot instructions

## Architecture and request flow
- Monorepo surfaces: Flutter app (`app/`), Go backend (`backend/`), Django operator console (`control-panel/`), and Appium QA (`qa/appium/`).
- Runtime path is Flutter/Django → API Gateway (`backend/cmd/api-gateway`) → Mobile BFF (`backend/cmd/mobile-bff`) → gRPC services and/or Supabase/Postgres repositories.
- Keep `backend/internal/gateway/http/server.go` thin: reverse proxy, `/healthz|readyz`, docs, metrics, and edge middleware only. Put orchestration in BFF handlers or `backend/internal/modules/<module>/application`.
- Go module boundaries are `backend/internal/modules/<module>/{application,infrastructure}` and are enforced by `backend/scripts/check_backend_compliance.sh`.
- BFF routes are centralized in `backend/internal/bff/mobile/server.go`; route renames should keep old paths through `withAliasDeprecation`.
- Preserve middleware order: gateway = correlation ID → exception → inflight shedding → IP rate limit → request logging; BFF = correlation ID → exception → inflight shedding → bulkhead → idempotency → request logging → activity middleware.
- Correlation is end-to-end: Flutter injects `X-Correlation-ID` and `X-Client-Platform` in `app/lib/core/providers/api_client_provider.dart`; Go logging/middleware expects those headers.
- Do not add runtime `http://localhost` or `10.0.2.2` literals in non-test Go files outside `backend/internal/platform/config/config.go`; compliance fails this.

## Backend data, contracts, and migrations
- Product state is durable-first: extend repositories such as `profile_repository.go`, `daily_prompt_repository.go`, `groups_repository.go`, or `gifts_repository.go`; `memoryStore` is fallback/test scaffolding only.
- `validateDurableEngagementReadiness` can block BFF startup when durable stores are required; keep `RequireDurableEngagementStore=true` viable.
- Persisting write endpoints need durable table writes plus idempotency/retry/reporting/activity behavior; model rose gift wallet flows in `backend/internal/bff/mobile/gifts.go`.
- OpenAPI source of truth is `backend/internal/platform/docs/openapi.yaml`; snapshots live in `backend/internal/platform/docs/contracts/` and include envelopes like `ErrorResponse` and `ChatLockedErrorResponse`.
- For client-visible API changes, update BFF route/handler, OpenAPI, snapshot if applicable, and run `make proto` from `backend/` when protobufs change.
- Migrations live in `backend/scripts/` and must be ordered in `backend/scripts_run_order.txt`; canonical production schemas are `matching` and `user_management`.

## Flutter app conventions
- Runtime config precedence is `.env.local` / `.env` → `--dart-define` → defaults in `app/lib/core/config/app_runtime_config.dart`; Android emulator API base is usually `http://10.0.2.2:8080/v1`.
- `app/lib/main.dart` intentionally rejects mock auth/discovery flags in release builds; keep this guard when touching startup.
- Use Riverpod notifiers/providers plus Dio under `app/lib/features/**/providers` and `app/lib/core/providers`; after Riverpod/Freezed/JSON annotations run `dart run build_runner build --delete-conflicting-outputs`.
- Never hand-edit generated `*.g.dart` or `*.freezed.dart` files.
- Profile setup is draft-first: `ProfileSetupNotifier` patches `/profile/{userID}/draft`; completion calls `/profile/{userID}/complete` and must survive BFF restarts.
- Preserve the premium glass/gold visual identity, typography scale, and navigation hierarchy unless explicitly asked for a redesign; setup CTAs use shared glass buttons.
- Full-screen Flutter surfaces must be safe-area/keyboard aware and avoid `Spacer`/`Expanded` inside unbounded scrolls; protect onboarding progress from accidental resets.

## Operations and validation workflows
- Backend: from `backend/`, use `make run-all` / `make stop-all`; logs and PIDs are under `backend/.run/`; health is gateway `:8080/healthz|readyz` and BFF `:8081/healthz|readyz`.
- Backend validation: from `backend/`, run `go test ./...` then `make backend-compliance-check`.
- Flutter validation: from `app/`, run `flutter analyze` and `flutter test`.
- ELK: from `backend/`, local binaries use `make elk-up-local`, `make elk-status-local`, `make elk-down-local`; Docker fallback is `make elk-up`, `make elk-down`. Logs index as `dating-app-logs-*`.
- Django control panel is an API consumer only: use `control-panel/.venv`, install `requirements.txt`, run migrations, then `python manage.py runserver`; `control_panel/services/go_client.py` calls Go `/v1/admin/*` APIs and passes `X-Admin-User`.
- Kibana embedding in control panel uses `KIBANA_BASE_URL`, `KIBANA_DISCOVER_INDEX`, and `KIBANA_DASHBOARD_PATH`.
- Appium Android: from `qa/appium/`, run `./run_full_android_automation.sh`; it builds with `API_BASE_URL=http://10.0.2.2:8080/v1` and `BYPASS_OTP_VALIDATION=true`, then writes `qa/reports/appium/android-smoke.html`.
- Keep Appium focused on critical journeys; seed broad permutations through API/DB, then sample in UI tests.
