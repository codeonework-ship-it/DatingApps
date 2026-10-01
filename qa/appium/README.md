# Appium Android UI Automation

This suite automates the Flutter Android app with Appium's Selenium WebDriver protocol.

## Covered flows

- Signup
- Existing-account sign-in
- Username/password validation and duplicate-username rejection
- Profile setup entry/finish path
- Profile setup photo-step entry, zero-photo gate, and background/foreground resume
- Edit Profile binding checks
- Discover screen
- Filter sheet
- Matches tab
- Chat message send smoke test
- Signup validation edge sample
- Profile details UI sample
- Swipe pass/undo UI sample
- Chat gift tray or locked-chat UI sample
- Background/foreground resilience sample
- API contract preflight for backend health, OpenAPI traceability, seeded discovery/matches, gifts, wallets, profile details, and unlock/engagement surfaces
- JSON matrix artifact generation at `qa/reports/appium/matrix-results.json`

## One-time setup

```bash
cd qa/appium
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
./setup_android.sh
```

Start an Android emulator and Appium:

```bash
npm run appium
```

The default emulator/device id is `emulator-5554`.

## Backend/app prerequisites

Start the local backend from [backend](../../backend/):

```bash
cd backend
./scripts/dev_up.sh
```

The runner builds the app with:

- `API_BASE_URL=http://10.0.2.2:18080/v1`
- `ENABLE_QA_AUTOMATION=true`

Authentication always uses a unique username and password. No mobile number,
email address, or one-time-code bypass participates in signup or sign-in.

## Run all Android UI smoke flows

Fully automated setup + run:

```bash
cd qa/appium
./run_full_android_automation.sh
```

Use global Appium installation when required:

```bash
cd qa/appium
APPIUM_INSTALL_SCOPE=global ./run_full_android_automation.sh
```

Manual run when Appium is already installed and running:

```bash
cd qa/appium
source .venv/bin/activate
./run_android.sh
```

HTML report:

```text
qa/reports/appium/android-smoke.html
```

The full runner executes `tests/test_00_seed_preflight.py -m seed` before starting Appium. This fails fast on backend health, OpenAPI, seed-script traceability, discovery, matches, gifts, wallet, and unlock-state drift. The seed snapshot is written to:

```text
qa/reports/appium/seed-preflight-summary.json
```

## Useful environment variables

```bash
export APPIUM_SERVER_URL=http://127.0.0.1:4723
export ANDROID_DEVICE_NAME=emulator-5554
export API_BASE_URL=http://10.0.2.2:18080/v1
export QA_API_BASE_URL=http://127.0.0.1:18080/v1
export QA_EXISTING_USERNAME=workflow_qa_20260803_final
export QA_EXISTING_PASSWORD='Password123!'
export QA_FILTER_STATE=Maharashtra
export QA_FILTER_CITY=Thane
export QA_FILTER_SMOKING=Never
export QA_FILTER_DRINKING=Never
```

## Run focused tests

```bash
python -m pytest tests/test_02_edit_profile.py -m smoke
python -m pytest tests/test_03_discover_filters.py -m discovery
python -m pytest tests/test_04_matches_chat.py -m matches
```

Run by flow marker:

```bash
python -m pytest -m signup
python -m pytest -m signin
python -m pytest -m profile_setup
python -m pytest tests/test_03_profile_setup_flow.py -m profile_setup
python -m pytest -m edit_profile
python -m pytest -m discovery
python -m pytest -m filters
python -m pytest -m matches
python -m pytest -m chat
python -m pytest -m "contract and not requires_appium"
python -m pytest -m "discovery_matrix or gift_matrix or unlock_matrix"
python -m pytest -m "signup_edge or profile_detail or swipe_matrix or resilience"
python -m pytest -m seed
```

Run by suite profile:

```bash
./run_full_android_automation.sh smoke
./run_full_android_automation.sh release
./run_full_android_automation.sh preflight
./run_full_android_automation.sh discovery-full
./run_full_android_automation.sh chat-full
./run_full_android_automation.sh gifts-full
./run_full_android_automation.sh engagement-full
./run_full_android_automation.sh negative
./run_full_android_automation.sh nightly
```

The default profile is `smoke`. The `release` profile runs four release-blocking
checks: the retired-auth ratchet, duplicate-username rejection, complete
username/password signup and profile completion, and credential login →
discovery → durable match → persisted chat restart/resume. Use `nightly` for
all UI samples and API matrices.

To reuse an already built or installed APK on a space-constrained emulator:

```bash
QA_SKIP_APK_BUILD=true QA_SKIP_APK_INSTALL=true ./run_full_android_automation.sh release
```

The runner selects the split APK matching the emulator ABI.

## Repository release gate

The non-Docker native-PostgreSQL gate validates migration state, the retired-auth
ratchet, Go tests/compliance, Flutter tests/analyzer errors, Django tests, and the
credential-authenticated API preflight:

```bash
./qa/run_release_regression.sh
```

Set `QA_RUN_DEVICE=true` to append the Appium `release` profile.

Mutating API matrix rows are disabled by default. Enable them only against a resettable QA database:

```bash
QA_ENABLE_MUTATING_MATRIX=true python -m pytest -m unlock_matrix
```

## Notes

- Appium is used for mobile UI verification only. Large permutation testing should run at API/DB level for speed.
- Keep Appium tests focused on critical user journeys; do not use them to generate thousands of users through the UI.
- Seed QA users and matches through SQL/API automation before running broad discovery/match checks.
- Smoke plan: [AUTOMATION_PLAN.md](AUTOMATION_PLAN.md)
- Full workflow expansion plan: [FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md](FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md)

## Full workflow implementation status

- Phase 1 is implemented for the current QA seed set: preflight checks, discovery matrix, chat/gift/wallet matrix, profile detail contract checks, unlock/engagement contract checks, and matrix JSON reporting are present.
- Phase 2 selector support is in place for accessibility-id/semantics selectors in signup/sign-in, terms, setup, navigation, filters, discovery cards/buttons, profile details, matches, chat, and rose gifts while visible text fallbacks remain.
- Additional representative Appium samples now cover signup validation, profile details, swipe pass/undo, chat gifts/locks, engagement unlock contracts, background/foreground resilience, authenticated process-death recovery, and Android large-font restart behavior.
- Failure artifacts now include screenshot, XML, package/activity/window/network context, Appium log tail, backend log tails, seed summary, and matrix summary when local run artifacts exist.

### Full screen and preference QA (26 September 2026)

See [the execution report](../../documents/qa/FULL_QA_AUTOMATION_2026-09-26.md)
for screen-by-screen layout results, preference/filter interaction coverage,
actual device results, and unresolved release gates. Layout checks are not
end-to-end acceptance.

Concurrent device suites need separate **AVDs, Appium ports, UiAutomator2 system
ports, synthetic accounts, and report paths**. Separate Appium sessions alone
still reset each other's app data. Configure all of these before running:

```sh
export ANDROID_DEVICE_NAME=emulator-5556
export APPIUM_SERVER_URL=http://127.0.0.1:4725
export APPIUM_SYSTEM_PORT=8201
export QA_EXISTING_USERNAME=qa_full_20260926_isolated
export QA_PUBLIC_PROFILE_VIEWER_USERNAME=qa_peer_20260926_isolated
export QA_REPORT_DIR="$PWD/../results/isolated-qa"
export QA_ARTIFACT_DIR="$QA_REPORT_DIR/artifacts"
export QA_MATRIX_RESULTS_PATH="$QA_REPORT_DIR/matrix-results.json"
export QA_ENABLE_MUTATING_MATRIX=true
./run_full_android_automation.sh nightly
```

The accounts above must be provisioned in the local backend. The primary needs
a published profile, a discovery deck, and both locked and unlocked match
fixtures. Unlock the latter through a quest submission approved by its synthetic
counterparty. The public-profile viewer must be a different account; the privacy
regression skips explicitly if it is absent and fails while hidden age leaks.
All synthetic mutations should stay on a dedicated local QA backend.

To execute just the live API regressions from this directory:

```sh
../../.venv/bin/python -m pytest tests -m 'not requires_appium'
```
