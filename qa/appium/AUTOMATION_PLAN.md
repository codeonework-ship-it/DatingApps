# Appium Android Automation Implementation Plan

> Full workflow expansion plan: [FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md](FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md). It expands this smoke plan into user creation -> discovery filters -> matches -> chat -> gifts/unlocks -> resilience coverage with API/DB permutation matrices and Appium UI samples.

## Goal and scope

Automate the Android Flutter critical path from username/password account creation through profile setup, discovery filtering, matching, and chat. Appium validates the mobile UI and navigation contracts; exhaustive data permutations are seeded and asserted through API/DB automation, then sampled in Appium so the suite stays reliable and fast.

## Existing coverage baseline

Current tests already cover the smoke spine:

- `tests/test_01_signup_credentials_profile_setup.py`: username/password signup and setup entry.
- `tests/test_02_edit_profile.py`: seeded QA sign-in and edit profile binding.
- `tests/test_03_discover_filters.py`: Discover tab and a Maharashtra/Thane filter path.
- `tests/test_04_matches_chat.py`: Matches tab, open conversation, send message.

The runner `./run_full_android_automation.sh` installs Appium/UiAutomator2, checks the native local-PostgreSQL backend, builds a debug APK with QA selectors enabled, runs pytest, and writes `qa/reports/appium/android-smoke.html`.

## Architecture under test

```text
Flutter app → API Gateway :18080 → Mobile BFF :18081 → gRPC modules → local PostgreSQL :55433
```

Important contracts to validate:

- Flutter adds `X-Correlation-ID` and `X-Client-Platform` from `app/lib/core/providers/api_client_provider.dart`.
- Signup uses `/v1/auth/signup` with a unique username/password, then bearer-authenticated `/v1/auth/signup/bootstrap`.
- Profile setup is draft-first: `PATCH /v1/profile/{userID}/draft`, photo metadata/upload endpoints, and `POST /v1/profile/{userID}/complete`.
- Discovery uses `GET /v1/discovery/{userID}?limit=50&mode=all|spotlight` plus manual filter query parameters from the Flutter swipe provider.
- Matching/chat use `/v1/swipe`, `/v1/matches/{userID}`, `/v1/chat/{matchID}/messages`, and rose gift/chat-lock endpoints.

## Test data strategy

1. Keep one canonical credential viewer from config: `QA_EXISTING_USERNAME=workflow_qa_20260803_final`.
2. Seed deterministic cohorts through SQL/API before Appium:
        - 100 rich profiles from `backend/scripts/044_seed_100_users_rich_matches_spotlight.sql`.
        - India state/city master data from `backend/scripts/049_seed_india_states_cities.sql`.
        - Matches, messages, photos, spotlight eligibility, trust filters, and wallet/gift rows from existing backend seed/migration scripts.
3. Use API/DB checks to verify all permutations exist before launching Appium; fail fast if seed data is missing.
4. Appium samples one or two representative rows per equivalence class instead of generating every user through the UI.

## Implementation phases

### Phase 1 — Runner hardening

- Add a preflight script under `qa/appium/` that verifies: gateway `:8080/healthz`, BFF `:8081/healthz`, `/openapi.yaml`, seeded viewer profile, seeded matches, and discovery candidates for configured filters.
- Add pytest markers: `seed`, `signup_edge`, `profile_setup_edge`, `discovery_matrix`, `match_matrix`, `chat_matrix`, `negative`.
- Extend failure artifacts to include screenshot, XML page source, current package/activity, and backend correlation ID when visible in logs.
- Add stable widget semantics/value keys in Flutter screens where text-only selectors are brittle: credential fields, setup next/complete CTAs, filter fields, match rows, chat composer/send/gift buttons.

### Phase 2 — Credential account matrix

Automate with Appium, backed by unique generated usernames:

| Case | Input | Expected |
|---|---|---|
| New valid user | unique username, strong matching password, valid name, adult DOB | profile setup entry |
| Duplicate signup | existing username | inline/account-exists error, no authenticated advance |
| Invalid username | too short / illegal characters | validation error, no API call path |
| Empty name / 1-char name | blank / `A` | validation error |
| Adult boundary | exactly 18 years | allowed |
| Underage | 17 years | blocked |
| Weak password | fewer than eight chars or missing letter/number | validation retained on signup |
| Password mismatch | confirmation differs | validation retained on signup |

### Phase 3 — Profile setup matrix

Use API-seeded drafts for photo-heavy cases, and Appium for visible validation/navigation:

| Area | Appium cases | API/DB exhaustive cases |
|---|---|---|
| Basic info | empty name, 2-char name, exact-18 DOB, gender `M/F/Other`, back/forward retention | 50/51-char names, leap-day DOB, Unicode/emoji names |
| Photos | 0/1 photo blocks Next, 2 photos enables Next, 5-photo max UI, delete causes re-disable, primary badge visible | 10 MB limit, MIME rejection, 0-byte file, duplicate file, reorder persistence |
| About | bio <10 blocked, bio 10 accepted, optional fields blank, drinking/smoking selections, back auto-save retention | 500/501-char bio, height 100/250 boundaries, master-data offline fallback |
| Preview/complete | missing photo/bio/name blocks, valid complete lands on Discover, hardware back does not return to setup | idempotent double complete, BFF restart durability, 422/5xx mapping |

### Phase 4 — Discovery and filter permutations

Run full combinations at API level and Appium samples per class:

| Dimension | Values |
|---|---|
| Discovery mode | `all`, `spotlight` |
| Location | Maharashtra/Thane, Maharashtra/Mumbai, empty city, no matching city |
| Lifestyle | smoking `Never/Socially/Regularly`, drinking `Never/Socially/Regularly` |
| Preference | age min/max, distance, education, serious-only, verified-only, hookup-only |
| Trust | trust filter off, trust filter on with filtered-out count |
| Result shape | profiles returned, empty state, backend error/retry |

Appium should verify opening the filter sheet, changing one value per dimension, applying filters, seeing the expected chip/result/empty state, switching spotlight mode, and preserving filters after tab navigation.

### Phase 5 — Swipe, matches, and chat permutations

| Flow | Cases |
|---|---|
| Swipe | pass profile, like profile without match, mutual like creates match, retriable swipe failure rolls back UI |
| Matches | list seeded matches, unread count/read state, trust-filter summary, empty matches state, unmatch confirmation |
| Chat text | open first match, send message, long/empty message guard, refresh/list persistence, delete-own-message path |
| Chat lock | locked conversation disables composer/gifts and shows unlock requirement from `CHAT_LOCKED_REQUIREMENT_PENDING` |
| Gifts | open rose tray, catalog renders, free/paid gift send, insufficient coins, daily limit, idempotent retry sampled through API |

### Phase 6 — Edge and resilience coverage

- Network unavailable while saving draft, uploading photo, applying filters, sending message: Appium toggles emulator network where safe and verifies retry/error UI.
- App background/foreground during setup and chat: draft/message state remains stable.
- Keyboard/small-height device checks: no CTA hidden behind keyboard on signup/setup/chat composer.
- Rotation/tablet smoke when emulator supports it: state does not reset.
- Terms acceptance modal: present only when needed; acceptance persists for returning viewer.

## Proposed test file layout

```text
qa/appium/tests/
  test_00_seed_preflight.py
  test_01_signup_credentials_profile_setup.py
  test_02_profile_setup_edges.py
  test_03_discover_filters.py
  test_04_discovery_matrix.py
  test_05_matches_chat.py
  test_06_chat_gifts_locks.py
  test_07_resilience_edges.py
```

## Execution commands

Run the current smoke suite:

```bash
cd qa/appium
./run_full_android_automation.sh
```

Run focused matrix groups after seed preflight:

```bash
python -m pytest -m discovery_matrix
python -m pytest -m match_matrix
python -m pytest -m chat_matrix
python -m pytest -m negative
```

## Definition of done

- Appium report covers credential signup → setup entry/complete sample → credential sign-in → Discover → durable match → persisted Chat.
- API/DB preflight proves all configured permutation cohorts are present before UI tests run.
- Negative/edge cases verify validation messages without corrupting durable drafts or seeded viewer state.
- Every failure stores screenshot, page source, and enough metadata to reproduce on the same emulator.
- Broad permutation results are reported separately from Appium smoke to avoid making mobile UI automation slow/flaky.
