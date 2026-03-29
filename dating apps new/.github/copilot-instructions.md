# Copilot Instructions

## Repository reality
- This workspace is **documentation-first**. Source directories (`backend/`, `app/`, `control-panel/`) are described in docs but not present here. Treat docs as source of truth; do not invent code edits unless matching files actually exist.
- Production stack: Flutter app -> Nginx (VPS `72.61.242.87`) -> Go API gateway (`:8080`) -> Go mobile BFF (`:8081`) -> Supabase/Postgres.
- This repo tracks rollout plans, evidence, runbooks, and backlogs for that system. All 7 activity-unlock epics (145 SP) are complete as of 2 Mar 2026. Active work: **Rose GIF Gifts Economy** (19 Mar 2026 sprint) and **Persistence Table Backlog** (21 Mar 2026).

## Architecture and delivery model
- Build and document work as **vertical features**, not horizontal slices. Each feature should cut through API contract, domain logic, persistence, client behavior, observability, and rollout evidence.
- Prefer clean architecture boundaries and DDD-style modeling: domain rules explicit, application/use-case orchestration isolated, infrastructure behind interfaces.
- Use the **repository pattern** for all persistence-facing code. Never leak storage details into handlers, providers, or domain logic.
- Do not abstract early; only extract shared paths after feature behavior is clear.

## Domain model and persistence
- Core product themes: quest-based unlocks, digital gestures, co-op mini activities, trust badges/filters, conversation rooms, daily prompts, groups, moderation flows, and the Rose GIF gift economy.
- **Unlock flow is effort-first, not paywall-first.** The gift economy (coins/wallet) must not reverse this -- free catalog share must stay 30-40%.
- Canonical schemas: `user_management` and `matching`. All new tables go there.
- Migrations must run in the exact order in `backend/scripts_run_order.txt`. Latest is through `034_gift_spend_activities.sql`. Missing migrations surface as `502` on profile or agreements routes.
- `REQUIRE_DURABLE_ENGAGEMENT_STORE=true` (default in production/staging) causes startup failure if any engagement feature still uses in-memory state.
- **Current durable store gaps** (see `documents/codex/ALN_2_1_DURABLE_STORE_INVENTORY_20260302.md`): activity sessions, trust badges/filters, and conversation rooms are still memory-backed -- blocked at startup in durable mode. Replacement tables tracked in `documents/codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md`.

## Key monorepo file mappings (documented paths, not present in this workspace)
- Gateway routing: `backend/internal/gateway/http/server.go`
- Mobile BFF server + error envelope: `backend/internal/bff/mobile/server.go`
- In-memory store (to replace): `backend/internal/bff/mobile/store.go`
- Quest/gesture durable repository: `backend/internal/bff/mobile/quest_repository.go`
- Gift catalog + wallet logic: `backend/internal/bff/mobile/gifts.go`, `gifts_repository.go`
- Gift send routes: `backend/internal/bff/mobile/server_gifts.go`
- Flutter API client + correlation interceptors: `app/lib/core/providers/api_client_provider.dart`
- Flutter structured logger: `app/lib/core/utils/logger.dart`
- Flutter chat + gift UI: `app/lib/features/messaging/`
- OpenAPI spec: `backend/internal/platform/docs/openapi.yaml`

## API and coding conventions
- Stable error envelope: `{ "success": false, "error": "...", "error_code": "..." }`. Never change this shape.
- Propagate `X-Correlation-ID` across gateway, BFF, Flutter client, and evidence artifacts.
- Structured JSON logging only -- pretty logs were explicitly removed from both backend and Flutter.
- Chat send gating uses domain error code `CHAT_LOCKED_REQUIREMENT_PENDING` (HTTP 423); gift send must respect this lock.
- Gift send (`RG-106`) requires idempotency middleware; wallet debit + send must be durable -- no partial state under downstream failure.
- Stateless handlers, bounded worker pools, async fanout for non-critical writes, idempotency keys for write APIs.
- Add unit tests for domain rules, application logic, and critical edge cases for every new feature.

## Developer workflows
- **Backend:** `go test ./...` -> `make backend-compliance-check` -> `make run-all`; stop with `make stop-all`.
- **Logs:** `.run/logs/api-gateway.log` and `.run/logs/mobile-bff.log`.
- **Smoke checks (production):** `http://72.61.242.87` -- `/healthz`, `/readyz`, `/openapi.yaml`, `/docs`, OTP/auth routes, `/v1/chat/gifts`, `/v1/wallet/{userID}/coins`.
- **Flutter:** macOS + Android emulator `Medium_Phone_API_36.1` (`emulator-5554`). Emulator base URL: `http://10.0.2.2:8080/v1`.
- **App config precedence:** `.env.local` / `.env` -> `--dart-define` -> code defaults. `API_BASE_URL` is the highest-priority override.
- **Control panel:** `.venv/bin/python manage.py test control_panel.tests.test_views` (editor test discovery may miss these).
- **To unblock gift send QA:** use an authorized test match pair that can complete quest template + submit + review, or run with `allow_without_template` unlock policy in local QA.

## Documentation conventions
- Preserve `Date`, `Status`, acceptance criteria, checklist state, evidence notes, and rollback notes -- these are operational records.
- Keep "implemented reality" clearly separated from "planned follow-up".
- Files in `documents/codex` are **immutable artifacts** -- add new timestamped files instead of editing existing ones.
- Naming: descriptive uppercase filenames, suffixed with a date or UTC timestamp (e.g., `ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md`).
- Runbooks must include exact commands, expected outputs, failure interpretation, and rollback steps.

## Best starting points for context
- `documents/VPS_NGINX_AND_FLUTTER_PRODUCTION_RUNBOOK.md` -- production bring-up and env config
- `documents/FLUTTER_LOCAL_TERMINAL_AND_AVD_RUN_GUIDE.md` -- local emulator setup
- `documents/codex/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md` -- unlock flow design and implemented routes
- `documents/codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md` -- tables still to migrate from memory to Postgres
- `documents/codex/JIRA_STORY_PROGRESS_TRACKER.md` -- full epic/story completion status
- `documents/codex/ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md` -- active feature: gift economy
- `documents/codex/ROSE_GIFTS_DELTA_EXECUTION_PLAN_2026-03-19.md` -- story-by-story implementation status for gifts
