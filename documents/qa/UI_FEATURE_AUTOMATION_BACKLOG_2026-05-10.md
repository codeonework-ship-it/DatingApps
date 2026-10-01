# UI Feature Automation Backlog — Appium + Flutter

Date: 2026-05-10  
Scope: Feature-by-feature UI automation list derived from the QA test case catalog, execution plan, and Appium full workflow plan.

## Feature implementation order

| Order | Feature area | Appium/UI automation target | Status | Primary files |
|---:|---|---|---|---|
| 1 | Auth sign-in | Existing-account username/password sign-in and authenticated landing | Implemented | `qa/appium/tests/test_01b_signin_credentials_existing_account.py` |
| 2 | Auth signup validation | Unique username/password/name/DOB validation, duplicate username guard, durable profile bootstrap | Implemented, including retired-auth ratchet | `qa/appium/tests/test_01_signup_credentials_profile_setup.py`, `test_02_profile_setup_edges.py`, `test_auth_automation_contract.py` |
| 3 | Profile setup | Signup entry to setup, photo-step validation, resume/background retention, preferences/preview gates | Implemented phase 3A; preferences/preview expansion remains | `qa/appium/tests/test_01_signup_credentials_profile_setup.py`, `qa/appium/tests/test_03_profile_setup_flow.py` |
| 4 | Edit profile | Seeded profile values bind and save path remains stable | Existing smoke | `qa/appium/tests/test_02_edit_profile.py` |
| 5 | Discovery filters | Apply/reset/persist location, lifestyle, verified, trust, no-results filters | Existing partial | `qa/appium/tests/test_03_discover_filters.py` |
| 6 | Profile details | Open detail page, carousel/read-more/safety actions, retry/not-found states | Existing partial/API | `qa/appium/tests/test_05_profile_details.py`, `test_06_profile_details_contract_api.py` |
| 7 | Swipe/pass/undo | Pass, undo, like/match sample, rollback on failed action | Existing partial | `qa/appium/tests/test_06_swipe_match_creation.py` |
| 8 | Matches list | Match list, unread/read state, unmatch/report options | Existing chat smoke; expand | `qa/appium/tests/test_04_matches_chat.py` |
| 9 | Chat | Send, persistence, empty/long message guards, delete/undo sample | Existing smoke/API | `qa/appium/tests/test_04_matches_chat.py`, `test_05_chat_gifts_contract_api.py` |
| 10 | Rose gifts/wallet | Tray, catalog, free/paid gift, low balance, locked chat, telemetry | Existing partial/API | `qa/appium/tests/test_08_chat_gifts_locks.py`, `test_05_chat_gifts_contract_api.py` |
| 11 | Engagement unlock and hub breadth | Quest, gesture, activity, trust badge and room contracts plus all nine engagement-hub destinations | Implemented API and device traversal | `qa/appium/tests/test_07_unlock_engagement_contract_api.py`, `test_09_engagement_unlocks_api.py`, `test_14_engagement_ui_breadth.py` |
| 12 | Engagement hub UI | Daily prompts, groups, polls, rooms, voice, circles, trust badges | Gap | New Appium and Flutter widget tests |
| 13 | Verification/safety | Landing/upload/selfie/status, report/block, moderation appeal surfaces | Gap/partial backend | New Flutter widget and Appium smoke tests |
| 14 | Friends/social | Friends list, filters, empty/error states, block/report path | Gap/partial backend | New Flutter widget and Appium/API tests |
| 15 | Resilience | Background/foreground, keyboard, network off/on, orientation/tablet smoke | Existing partial | `qa/appium/tests/test_10_resilience_edges.py` |
| 16 | Control panel UI | Go client headers, Kibana config, auth redirects, admin actions | Gap/partial Django | `control-panel/control_panel/tests/` |

## Feature 1 acceptance criteria

- Launch a clean app session.
- Open the existing-account sign-in surface.
- Enter `QA_EXISTING_USERNAME` and `QA_EXISTING_PASSWORD`.
- Submit the credential form without phone, email, or OTP fields.
- Handle terms if shown.
- Assert the authenticated surface is visible.
- Include the test in the smoke marker so the default Android workflow covers both signup and returning-user auth.

## Feature 2 acceptance criteria

- Launch a clean app session.
- Verify invalid/duplicate username remains on signup with clear guidance.
- Verify weak or mismatched passwords remain on signup.
- Verify short name and missing/underage date of birth remain on signup.
- Verify successful signup persists the username identity and reaches profile setup without phone, email, or OTP input.

## Next feature to implement

Feature 4: expand edit profile UI automation. Recommended first tests:

1. Existing seeded profile values bind on edit-profile entry.
2. Basic text fields can be modified and saved.
3. Preferences edit path saves without completing setup flow.
4. Back navigation from edit profile preserves previously saved values.
5. Validation prevents empty/invalid edited values.
