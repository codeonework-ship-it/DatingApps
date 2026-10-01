# QA Automation Execution Plan — All Modules

Date: 2026-05-10  
Scope: Run every available automated suite and track gaps from the all-module catalog.

## Goal

Validate all automated test cases currently present in the repository and produce a clear run order for repeatable QA execution across:

1. Flutter unit/widget tests
2. Go backend/API tests
3. Django control panel tests
4. Appium Android/API E2E suite
5. Manual or future automation gaps documented in the module catalog

## Preconditions

| Area | Required state |
|---|---|
| Backend | Native local PostgreSQL on `:55432`, gateway on `:18080`, BFF on `:18081`; no Docker/Supabase runtime |
| Flutter | SDK available, Android toolchain available for Appium run |
| Android | Emulator running, usually `emulator-5554` |
| Appium | Node/npm available; runner can install/start Appium if missing |
| Python | Workspace venv available at `.venv/` |
| Auth | Seeded unique username/password account is complete and has discovery plus match fixtures |
| API base | Android Appium build uses `http://10.0.2.2:18080/v1` |

## Recommended run order

Run lower-level suites first so functional failures are easier to isolate before launching mobile E2E.

| Step | Suite | Command | Output/report |
|---:|---|---|---|
| 1 | Backend Go tests | `cd backend && go test ./...` | Terminal output |
| 2 | Backend compliance | `cd backend && make backend-compliance-check` | Terminal output |
| 3 | Flutter tests | `cd app && flutter test` | Terminal output |
| 4 | Flutter analyzer | `cd app && flutter analyze` | Known info-level lint noise; use as advisory unless compile errors appear |
| 5 | Control panel tests | `cd control-panel && python manage.py test` | Terminal output |
| 6 | Appium full Android automation | `cd qa/appium && ./run_full_android_automation.sh` | `qa/reports/appium/android-smoke.html` |

## Focused rerun commands

Use these when a full E2E run fails or a specific module changes.

| Module | Command |
|---|---|
| Signup/auth | `cd qa/appium && python -m pytest -m signup -vv` |
| Signup edge cases | `cd qa/appium && python -m pytest -m signup_edge -vv` |
| Credential contract | `cd qa/appium && python -m pytest -m auth_contract -vv` |
| Device core journey | `cd qa/appium && python -m pytest -m core_journey -vv` |
| Profile setup | `cd qa/appium && python -m pytest -m profile_setup -vv` |
| Edit profile | `cd qa/appium && python -m pytest -m edit_profile -vv` |
| Discovery/filter | `cd qa/appium && python -m pytest -m "discovery or filters or discovery_matrix" -vv` |
| Profile detail | `cd qa/appium && python -m pytest -m profile_detail -vv` |
| Swipe/match matrix | `cd qa/appium && python -m pytest -m "swipe_matrix or matches or match_matrix" -vv` |
| Chat/gifts/locks | `cd qa/appium && python -m pytest -m "chat or chat_matrix or gift_matrix or unlock_matrix" -vv` |
| Resilience | `cd qa/appium && python -m pytest -m resilience -vv` |
| API contracts only | `cd qa/appium && python -m pytest -m contract -vv` |

## Execution checklist

| Check | Expected result | Status |
|---|---|---|
| Confirm backend tests run | All Go packages pass or failures triaged | PASS — 2026-08-09 |
| Confirm backend compliance | No module-boundary/runtime-localhost compliance failures | PASS — 2026-08-09 |
| Confirm Flutter tests run | All unit/widget tests pass | PASS — 471 tests on 2026-08-09 |
| Confirm retired-auth ratchet | Executable QA contains no retired phone/code auth selectors, flags, or endpoints | PASS — enforced by `test_auth_automation_contract.py` |
| Confirm control panel tests run | Django test suite passes | PASS — 7 tests on 2026-08-09 |
| Confirm emulator ready | `adb devices` includes `emulator-5554` or selected target | PASS — `emulator-5554` on 2026-08-09 |
| Confirm app fresh install | App cache cleared/uninstalled/reinstalled by runner or manual step | PASS — current QA APK rebuilt and installed before the release profile |
| Confirm Appium report generated | `qa/reports/appium/android-smoke.html` exists | PASS — 4 release tests on 2026-08-09 |

## Known risks before execution

| Risk | Impact | Mitigation |
|---|---|---|
| Flutter analyzer returns many existing lint/catalog findings | Exit code can be non-zero even without compile failures | Treat the known warning/info backlog as advisory; fail on analyzer errors or new compile/runtime failures |
| Emulator `/data` capacity is low | APK install may fail before Appium starts | Use the ABI-specific split APK and skip rebuild/install when the current build is already installed |
| Appium full run depends on emulator/backend/Appium readiness | E2E may fail before app tests begin | Run backend health and emulator checks first; use full runner for orchestration |
| Durable backend tests require the local database | Tests fail if migration `057` or required runtime tables are absent | Run the local PostgreSQL migration workflow before the release gate |
| Appium fixtures require seeded data | Discovery/chat/gift tests can fail with empty data | Use `test_00_seed_preflight.py` and runner seed setup |

## Defect triage rules

| Severity | Criteria | Examples |
|---|---|---|
| Blocker | Prevents app launch, signup/sign-in, API startup, or complete E2E smoke | App crashes on launch; BFF fails readiness; credential login fails |
| Critical | Core monetization/matching/messaging flow broken | Cannot send chat; gift wallet debits incorrectly; discovery empty despite seed |
| Major | Feature works partially but user-facing correctness or safety degraded | Filters wrong; moderation action not persisted; profile setup loses draft |
| Minor | Visual, copy, analytics, or non-critical edge issue | Spacing issue; missing empty-state copy; non-blocking telemetry gap |
| Info | Test/doc improvement or known lint cleanup | Advisory analyzer lint; missing optional test marker |

## Result recording template

After automation runs, append results below.

| Timestamp | Suite | Command | Result | Notes/report |
|---|---|---|---|---|
| 2026-05-10 | Backend Go | `go test ./...` | PASS | All backend packages passed or had no test files |
| 2026-05-10 | Backend compliance | `make backend-compliance-check` | PASS | Compliance checks succeeded |
| 2026-05-10 | Flutter tests | `flutter test -r json` | PASS | 200 completed tests, success `true` |
| 2026-05-10 | Flutter goldens | `flutter test --update-goldens test/features/responsive/phase3_golden_and_overflow_test.dart` | PASS | Responsive baselines updated for current intended UI |
| 2026-05-10 | Control panel | `python manage.py test` | PASS | 5 tests passed |
| 2026-05-10 | Appium full | `./run_full_android_automation.sh` | PASS | 29 passed, 4 expected skips; report `qa/reports/appium/android-smoke.html` |
| 2026-08-09 | Native PostgreSQL release gate | `QA_RUN_DEVICE=false ./qa/run_release_regression.sh` | PASS | Migration, Go, compliance, Flutter, analyzer-error, Django, and API preflight gates passed |
| 2026-08-09 | Android release profile | `./run_full_android_automation.sh release` | PASS | 4 passed, 59 deselected: retired-auth ratchet, duplicate username, complete signup/profile workflow, and durable core dating restart journey |

## Exit criteria

QA execution is complete when:

1. All available automated suites have been run or explicitly blocked by environment prerequisites.
2. Every failure is classified as product regression, stale test, environment issue, or known existing lint/noise.
3. Appium report is generated for Android full workflow, or blocker evidence is documented.
4. The all-module catalog is updated with newly identified gaps.
5. P0/P1 automation gaps have tickets or concrete next-test recommendations.

## Current unified command

Run `./qa/run_release_regression.sh` from the repository root. It rejects
non-local database URLs, checks the applied native-PostgreSQL schema, and runs
the code-level gates. Set `QA_RUN_DEVICE=true` to append the Android credential
signup/profile completion, duplicate-username security rejection, and credential
login → discovery → match → persisted chat restart/resume journeys.
