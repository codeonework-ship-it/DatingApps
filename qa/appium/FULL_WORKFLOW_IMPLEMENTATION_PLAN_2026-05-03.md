# Appium Full Workflow Automation Implementation Plan

Date: 3 May 2026  
Scope: Android Flutter app automation from user creation through discovery filters, matches, chat, gifts, chat unlocks, and resilience edges.

## 1. Goal

Build a deterministic Appium automation workflow that validates the complete user journey:

1. New user creation.
2. Credential/session verification.
3. Terms acceptance.
4. Profile setup and profile completion gates.
5. Discovery and profile detail review.
6. Discovery filters across locations, lifestyle, trust, and preference dimensions.
7. Swipe actions and match creation.
8. Matches list, unread/read state, unmatch/report actions.
9. Chat send, locked chat behavior, delete-message behavior.
10. Rose gift tray, catalog, wallet, send, insufficient balance, daily limit, and idempotency behavior.
11. Activity/quest unlock journeys where UI is available, backed by API verification.

The suite must cover all meaningful permutations and combinations, but it must not create thousands of users through Appium. Appium will validate mobile UI flows and representative equivalence classes. API/DB preflight and matrix tests will cover the exhaustive combinations, then Appium will sample each class so the workflow stays stable and fast.

## 2. Sources studied and traceability

### Documents

- `documents/BRD_PROFILE_SETUP_FLOW_SCREENS_4_TO_8_2026-04-11.md`
  - Draft-first profile setup, durable persistence, idempotent PATCH, photo requirements, resume/back navigation, completion gate, and screen 4-8 acceptance criteria.
- `documents/codex/BA_VIEW_MORE_PROFILE_DETAILS_2026-04-11.md`
  - Profile details acceptance criteria: photo carousel, bio, lifestyle fields, null hiding, retry, spotlight badge, love/message/report actions.
- `documents/codex/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md`
  - Implemented unlock-state, quest workflow, gestures, activities, trust badges, and rooms endpoints.
- `documents/codex/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md`
  - Rose gift QA checklist: tray, wallet, catalog, free/paid gift, telemetry, idempotency, audit.
- `.github/copilot-instructions.md`
  - Appium critical journey guidance, local backend run expectations, durable-first backend behavior, route conventions, and validation workflow.

### Web API contract

Source of truth: `backend/internal/platform/docs/openapi.yaml`.

Key endpoint groups used by this plan:

| Flow | Endpoints |
|---|---|
| Auth/signup | `POST /v1/auth/signup`, `POST /v1/auth/login`, bearer session endpoints, `POST /v1/auth/signup/bootstrap` |
| Profile setup | `GET/PATCH /v1/profile/{userID}/draft`, `POST /v1/profile/{userID}/photos`, `DELETE /v1/profile/{userID}/photos/{photoID}`, `POST /v1/profile/{userID}/photos/reorder`, `POST /v1/profile/{userID}/complete` |
| Discovery | `GET /v1/discovery/{userID}?limit=&mode=all|spotlight` plus manual query filters from Flutter |
| Swipe/matches | `POST /v1/swipe`, `GET /v1/matches/{userID}`, `DELETE /v1/matches/{matchID}`, `POST /v1/matches/{matchID}/read` |
| Profile detail | `GET /v1/profile/{userID}`, `GET /v1/profile/{userID}/draft` |
| Chat | `GET/POST /v1/chat/{matchID}/messages`, `DELETE /v1/chat/{matchID}/messages/{messageID}` |
| Gifts/wallet | `GET /v1/chat/gifts`, `POST /v1/chat/{matchID}/gifts/send`, `POST /v1/chat/{matchID}/gifts/events`, `GET/POST /v1/wallet/{userID}/coins`, `GET /v1/wallet/{userID}/coins/audit` |
| Unlocks | `GET /v1/matches/{matchID}/unlock-state`, `GET/PUT /v1/matches/{matchID}/quest-template`, `GET/POST /v1/matches/{matchID}/quest-workflow`, `POST /v1/matches/{matchID}/quest-workflow/review` |
| Engagement | `POST /v1/matches/{matchID}/gestures`, `POST /v1/matches/{matchID}/gestures/{gestureID}/decision`, `POST /v1/activities/sessions/start`, `POST /v1/activities/sessions/{sessionID}/submit`, `GET /v1/activities/sessions/{sessionID}/summary`, `GET /v1/users/{userID}/trust-badges`, `GET /v1/rooms` |
| Safety | `POST /v1/safety/report`, `POST /v1/safety/block`, `GET /v1/blocked-users/{userID}` |

### Flutter surfaces

| Surface | Files |
|---|---|
| App gate | `app/lib/main.dart` |
| API headers/correlation | `app/lib/core/providers/api_client_provider.dart` |
| Main navigation and filters | `app/lib/features/common/screens/main_navigation_screen.dart` |
| Discovery/swipe | `app/lib/features/swipe/screens/home_discovery_screen.dart`, `app/lib/features/swipe/providers/swipe_provider.dart` |
| Profile details | `app/lib/features/swipe/screens/profile_details_screen.dart`, `app/lib/features/swipe/providers/profile_details_provider.dart` |
| Matches | `app/lib/features/matching/screens/matches_list_screen.dart`, `app/lib/features/matching/providers/match_provider.dart` |
| Chat/gifts | `app/lib/features/messaging/screens/chat_screen.dart`, `app/lib/features/messaging/providers/message_provider.dart` |
| Profile setup | `app/lib/features/profile/screens/setup/*`, `app/lib/features/profile/providers/profile_setup_provider.dart` |
| Trust filters | `app/lib/features/matching/providers/trust_filter_provider.dart`, `app/lib/features/engagement/screens/trust_filter_screen.dart` |

## 3. Current baseline

Implementation progress as of 3 May 2026:

- Phase 1 foundation is underway with `api_client.py`, seed preflight, discovery matrix, chat/gift/wallet matrix, profile-detail contract checks, unlock/engagement contract checks, and `qa/reports/appium/matrix-results.json` generation.
- `run_full_android_automation.sh` now executes `tests/test_00_seed_preflight.py -m seed` before starting Appium, and writes `qa/reports/appium/seed-preflight-summary.json` for failure reproduction.
- Shared fixture loading lives in `matrix.py`; deterministic seed/user traceability lives in `fixtures/users.json`; broad chat and gift contract rows are split into `fixtures/chat_matrix.json` and `fixtures/gifts_matrix.json`.
- Failure artifacts now include Appium and backend log tails when available.
- Appium helpers can target accessibility-id/semantics labels first, with existing text selectors retained as fallbacks.
- Mutating API matrix rows are guarded behind `QA_ENABLE_MUTATING_MATRIX=true` so default smoke/full contract runs do not mutate durable QA state unexpectedly.
- Runner profiles are now wired: default `smoke`, `preflight`, `discovery-full`, `chat-full`, `gifts-full`, `negative`, `contract`, and `nightly` map to the planned pytest marker sets.
- Failure artifacts now include device network diagnostics plus seed/matrix summaries when available.

Existing Appium files:

- `tests/test_01_signup_credentials_profile_setup.py` — credential signup, terms/setup entry, non-media setup progression.
- `tests/test_02_edit_profile.py` — seeded sign-in and edit profile checks.
- `tests/test_03_discover_filters.py` — Discover tab and a Maharashtra/Thane filter sample.
- `tests/test_04_matches_chat.py` — Matches tab, open conversation, send message.
- `helpers.py` — text/description selectors, credential entry, terms handling, tab navigation, failure artifacts.
- `run_full_android_automation.sh` — installs/runs Appium, builds an ABI-specific QA APK, runs pytest, writes HTML report.

Gaps:

- Signup/profile setup, discovery, chat/gift, unlock, and resilience coverage exists, but several edge rows remain representative instead of exhaustive for the current local seed set.
- Backend correlation extracts and current Flutter route context are still future artifact improvements.

## 4. Automation architecture

### Layer 1 — Seed and contract preflight

Run before UI automation.

Responsibilities:

- Verify gateway and BFF health.
- Verify OpenAPI is reachable.
- Verify migrations/seeds required for QA are present.
- Verify deterministic users, matches, discovery candidates, wallet balances, gift catalog, trust filters, and locked/unlocked match states.
- Fail fast with actionable diagnostics before Appium launches.

Implementation files:

- Add `qa/appium/api_client.py` for HTTP helpers.
- Add `qa/appium/seed_preflight.py` or `tests/test_00_seed_preflight.py`.
- Add JSON fixture definitions under `qa/appium/fixtures/`.

### Layer 2 — API/DB permutation matrix

Run through pytest using HTTP/API assertions and optional SQL checks. This layer covers all combinations that are too broad for UI automation.

Examples:

- Location × lifestyle × trust × mode discovery matrix.
- Wallet balance × gift tier × daily limit × idempotency matrix.
- Chat unlock state × quest workflow state × sender role matrix.
- Profile setup validation boundaries.

### Layer 3 — Appium UI workflow

Appium validates one or two representative samples per equivalence class:

- Signup happy path plus critical validation negatives.
- Profile setup screen validations and navigation persistence.
- Filter sheet apply/reset/persistence.
- Discovery profile details, swipe, match creation.
- Matches list, chat send, gift tray, locked chat UI.
- Report/unmatch options.
- Network/background/keyboard resilience on critical screens.

### Layer 4 — Artifacts and reporting

For every failure collect:

- Screenshot.
- XML page source.
- Current package/activity.
- Device size/orientation.
- Appium server log tail.
- Backend gateway/BFF log tail by test timestamp and correlation ID when available.
- Seed/preflight summary JSON.
- HTML report under `qa/reports/appium/android-smoke.html` and matrix JSON under `qa/reports/appium/matrix-results.json`.

## 5. Test data and seeds

Use deterministic data. Do not use Appium to generate all users.

Required seeds/migrations:

| Need | Source |
|---|---|
| 100 rich users, matches, spotlight, 3 photos | `backend/scripts/044_seed_100_users_rich_matches_spotlight.sql` |
| India location master data | `backend/scripts/049_seed_india_states_cities.sql` |
| Filter-specific users | `backend/scripts/048_seed_filter_test_female_users.sql` |
| Gift catalog/wallet | `backend/scripts/032_rose_gifts_wallet_tables.sql`, `backend/scripts/045_gift_catalog_expansion.sql` |
| Unlock/activity/trust/rooms | `backend/scripts/020_engagement_surfaces_tables.sql` and related engagement migrations |
| Canonical API users | existing smoke IDs such as `11111111-1111-1111-1111-111111111111` where available |

QA identities:

| Identity | Purpose |
|---|---|
| `QA_EXISTING_USERNAME=workflow_qa_20260803_final` | Returning seeded viewer for filters/matches/chat |
| Generated unique username per run | Signup happy path and validation negatives |
| Seed match with unlocked chat | Message send, delete, gift success |
| Seed match with quest pending | Locked chat composer and gift disabled/423 behavior |
| Seed match with low wallet | Gift insufficient coins |
| Seed match with exclusive gift already used | Daily limit |

## 6. Permutation coverage strategy

### Full matrix rule

Every dimension must be covered by either:

1. API/DB matrix assertion, and
2. at least one Appium UI sample for that feature family.

This gives full permutation confidence without making the mobile UI suite slow or flaky.

### Discovery/filter dimensions

| Dimension | Values |
|---|---|
| Discovery mode | `all`, `spotlight` |
| Age | min 18, exact configured range, max 70, invalid min > max via API |
| Distance | 1 km, 50 km default, 500 km |
| Location | no filter, Maharashtra/Thane, Maharashtra/Mumbai, state-only, no-match city |
| Verified | true, false |
| Lifestyle | smoking `Never`, `Occasionally`, `Regularly`; drinking `Never`, `Occasionally`, `Socially`, `Regularly` |
| Identity | religion, mother tongue, relationship status, personality type |
| Intent | party lover only, hookup only |
| Trust | disabled, enabled min 1-4 badges, required badge subset, filtered-out empty state |
| Result shape | normal list, empty state, retry/error state, spotlight summary |

Appium samples:

- Apply Maharashtra/Thane + `Never` smoking/drinking.
- Reset filters.
- Toggle verified-only and trust filter.
- Navigate away and back to verify chips persist.
- Select spotlight mode and open profile details.
- Apply a no-match filter and verify empty state copy.

### Signup credential dimensions

| Case | UI/API coverage | Expected |
|---|---|---|
| New valid username/password | Appium | terms/setup gate |
| Existing username | Appium/API | duplicate/account exists path, no setup corruption |
| Invalid username | Appium | validation message, no authenticated advance |
| Empty name/one-char name | Appium | validation message |
| Adult exactly 18 | Appium/API | allowed |
| Under 18 | Appium/API | blocked |
| Strong matching password | Appium | authenticated state |
| Weak or mismatched password | Appium/API | error retained on credential screen |
| Retry signup | API/Appium sample | no duplicate user/draft overwrite |

### Profile setup dimensions

| Area | Appium samples | API/DB exhaustive |
|---|---|---|
| Entry/resume | new signup enters screen 4, returning incomplete resumes | current step 1-4 and draft merge |
| Basic info | blank/short name, exact 18 DOB, gender values | 50/51-char name, leap-day, Unicode/emoji, invalid dates |
| Photos | zero photo blocks, seeded metadata enables completion, delete/reorder UI if accessible | max count, MIME, size, 0-byte, duplicate, local path persistence |
| About | bio min accepted/blocked, optional fields blank, lifestyle dropdowns | 500/501-char bio, height 100/250/invalid, all master-data values |
| Preferences | age/distance/verified toggles saved | full filter payload persistence |
| Preview/complete | valid complete lands on Discover and back stack cleared | idempotent double complete, BFF restart durability, 422/5xx mapping |

### Profile detail dimensions

| Case | Expected |
|---|---|
| 0 photos | placeholder, no thumbnail strip |
| 1 photo | single photo/counter safe |
| 3+ photos | carousel, counter, thumbnails |
| Null profile fields | omitted rows, no `N/A` |
| Long bio | read more/read less |
| Draft fallback | education/profession visible from draft fallback |
| Profile deleted/not found | user not found/back state |
| Network failure | retry state |
| Buttons | Love and Message pinned and working |
| Safety | report sheet submits and appeal action appears |

### Swipe, matches, and chat dimensions

| Feature | Cases |
|---|---|
| Swipe | pass, like without match, mutual like creates match, undo, retriable failure rollback |
| Matches | non-empty list, empty list, unread -> read, trust-filter hidden matches copy, unmatch, report |
| Chat | send text, empty send guard, long message guard/API, refresh persistence, read state, delete own message, delete expired/not-owner API |
| Locked chat | composer disabled, gift button disabled, `CHAT_LOCKED_REQUIREMENT_PENDING` error copy |
| Quest unlock | template visible/API, submit, pending review, approve, chat unlocks |
| Gestures/activity | gesture create/decision/score API, activity start/submit/summary API, UI sample where available |

### Gift and wallet dimensions

| Case | Coverage | Expected |
|---|---|---|
| Catalog visible | Appium/API | tray lists gifts/categories |
| Free gift | Appium/API | no wallet debit, message appears |
| Paid gift | Appium/API | wallet decremented, audit row |
| Insufficient coins | Appium/API | error copy, no debit |
| Daily limit | API plus Appium sample if visible | `GIFT_DAILY_LIMIT_REACHED` |
| Idempotent retry | API | same response, no double debit, `X-Idempotent-Replay` |
| Locked chat gift | Appium/API | disabled UI or 423 |
| Telemetry | API | panel/preview/send event accepted |

### Resilience dimensions

| Case | Expected |
|---|---|
| Backend down before test | preflight fail fast |
| Network off during discovery | retry/error state, no crash |
| Network off during draft save | rollback/snackbar, local state not corrupted |
| Network off during message send | retry/error, composer text behavior documented |
| Background/foreground during setup/chat | state survives |
| Small keyboard height | CTA/composer remains usable |
| Rotation/tablet smoke | no reset/crash when emulator supports it |
| Terms modal | appears only for signup/incomplete users, acceptance persists |

## 7. Proposed test layout

```text
qa/appium/
  api_client.py
  matrix.py
  seed_preflight.py
  fixtures/
    users.json
    discovery_matrix.json
    chat_matrix.json
    gifts_matrix.json
  tests/
    test_00_seed_preflight.py
    test_01_signup_credentials_profile_setup.py
    test_02_profile_setup_edges.py
    test_03_discover_filters.py
    test_04_discovery_matrix_api.py
    test_05_profile_details.py
    test_06_swipe_match_creation.py
    test_07_matches_chat.py
    test_08_chat_gifts_locks.py
    test_09_engagement_unlocks_api.py
    test_10_resilience_edges.py
```

## 8. Pytest markers

Add to `pytest.ini`:

| Marker | Purpose |
|---|---|
| `seed` | seed/preflight checks |
| `contract` | OpenAPI/API contract checks |
| `signup_edge` | credential signup negative/boundary cases |
| `profile_setup_edge` | profile setup validation/resume cases |
| `discovery_matrix` | discovery/filter API matrix |
| `profile_detail` | profile detail UI/API cases |
| `swipe_matrix` | swipe/match creation cases |
| `match_matrix` | matches list/read/unmatch/report cases |
| `chat_matrix` | chat send/delete/lock cases |
| `gift_matrix` | gifts/wallet/telemetry cases |
| `unlock_matrix` | quest/gesture/activity unlock cases |
| `resilience` | network/background/keyboard/orientation cases |
| `negative` | validation/error-path cases |

## 9. Stable selector work required in Flutter

Add `ValueKey` and semantics labels before expanding Appium coverage. Keep visible text assertions too, but prefer stable keys.

| Surface | Required keys/semantics |
|---|---|
| Signup | username, password, confirmation, name, DOB, gender, and create-account button |
| Terms | accept checkbox, accept continue button |
| Setup | step root keys, next/back/complete CTAs, photo add/delete/reorder, bio/height/lifestyle fields |
| Navigation | bottom nav items: discover, matches, engage, profile, settings |
| Discovery | filter button, mode toggle, card root, pass/like/superlike/message/view-more buttons, empty/retry states |
| Filter sheet | each dropdown, switch, slider, reset/apply buttons, chip labels |
| Profile detail | carousel, thumbnails, read-more, love/message/report buttons, retry |
| Matches | match row key by match id, unread badge, long-press/options, unmatch/report |
| Chat | composer, send button, gift tray button, gift item, delete-message action, locked banner |

## 10. Implementation phases

### Phase 0 — Preconditions

- Confirm the native local-PostgreSQL run is healthy: gateway `:18080/healthz`, BFF `:18081/healthz`.
- Confirm Appium builds with `API_BASE_URL=http://10.0.2.2:18080/v1` and `ENABLE_QA_AUTOMATION=true`.
- Confirm seeds 044, 048, 049 and gift/engagement migrations are applied in the target database.

### Phase 1 — Preflight and matrix foundation

- Add API client and preflight test.
- Add fixtures listing expected QA users/matches/candidates.
- Add discovery, gift, chat-lock, and unlock API matrix tests.
- Add report JSON output for matrix coverage.

### Phase 2 — Selector hardening

- Add Flutter keys/semantics for signup, setup, discovery, filters, matches, chat, and gifts.
- Extend Appium helper to locate by accessibility id/resource id/value key where Flutter exposes semantics.
- Preserve existing text-based fallbacks.

### Phase 3 — Signup/profile setup UI expansion

- Expand `test_01_signup_credentials_profile_setup.py` for terms and completion gate.
- Add `test_02_profile_setup_edges.py` for validation and resume/back-retention samples.
- Use unique generated usernames and durable draft cleanup where needed.

### Phase 4 — Discovery/profile/filter UI expansion

- Expand `test_03_discover_filters.py` for apply/reset/persistence/trust toggle/no-results.
- Add `test_05_profile_details.py` for carousel, read more, love/message/report, retry state where possible.
- Add `test_06_swipe_match_creation.py` for pass/like/mutual-match/undo rollback samples.

### Phase 5 — Matches/chat/gifts UI expansion

- Expand `test_07_matches_chat.py` for read state, unmatch, report, message persistence.
- Add `test_08_chat_gifts_locks.py` for gift tray, free gift, paid gift, low wallet, locked chat banner.

### Phase 6 — Unlock/resilience

- Add `test_09_engagement_unlocks_api.py` for quest/gesture/activity/room contracts.
- Add `test_10_resilience_edges.py` for network toggles, background/foreground, keyboard/small-height, orientation.

### Phase 7 — CI and run profiles

- Keep default smoke fast.
- Add nightly/full matrix profile.
- Add focused profiles for discovery, chat, gifts, and negative cases.

## 11. Execution profiles

| Profile | Command | Purpose |
|---|---|---|
| Smoke | `./run_full_android_automation.sh -m smoke` | critical journey only |
| Preflight | `python -m pytest -m seed` | validate environment and seed data |
| Discovery full | `python -m pytest -m "seed or discovery_matrix or filters"` | filter permutations |
| Chat full | `python -m pytest -m "seed or match_matrix or chat_matrix"` | matches/chat permutations |
| Gifts full | `python -m pytest -m "seed or gift_matrix"` | gifts/wallet/idempotency |
| Negative | `python -m pytest -m negative` | validation/error paths |
| Nightly | `python -m pytest` | all UI samples and API matrices |

## 12. Acceptance criteria

- Preflight proves required backend health, OpenAPI availability, seed users, seed matches, discovery candidates, gift catalog, wallet state, trust filters, and locked/unlocked matches.
- Appium covers the full happy path: credential signup -> terms -> setup gate -> credential sign-in -> Discover -> filters -> durable match -> persisted Chat -> restart/resume.
- API/DB matrix covers all configured combinations for discovery filters, chat lock states, gift/wallet states, and profile setup boundaries.
- Appium samples every feature family and at least one edge/negative state per critical screen.
- Failure artifacts are sufficient to reproduce: screenshot, XML, package/activity, logs, seed snapshot, matrix row.
- Tests do not hand-edit generated Flutter files and do not depend on mock auth/discovery in release builds.
- Suite remains deterministic on a clean emulator and seeded backend.

## 13. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Exhaustive Appium permutations become slow/flaky | Use API/DB matrix for exhaustive combinations and Appium for representative UI classes |
| Text selectors break with copy changes | Add Flutter `ValueKey`/semantics and keep text fallback |
| Seed drift | Preflight validates every required cohort before UI tests |
| External image URLs fail | Seed local/placeholder-tolerant profile photo expectations |
| Wallet/gift tests mutate durable data | Reset/top-up controlled QA identities before each gift matrix row |
| Chat/delete tests mutate seeded messages | Use per-run messages and idempotency keys; cleanup by API where possible |
| Network toggles impact later tests | Always restore network in fixture teardown |

## 14. Definition of done

- `qa/appium/FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md` is created and linked from the Appium README/plan.
- New pytest markers and test files are added.
- Flutter semantics/keys required by Appium are added.
- `./run_full_android_automation.sh` can run the smoke profile end-to-end.
- Full matrix profile produces HTML plus JSON coverage artifacts.
- At least one seeded unlocked chat, locked chat, low-wallet match, no-result filter, and profile-detail rich candidate are validated.
- Plan traceability maps each Appium/API matrix to the documents and OpenAPI endpoints above.
