# QA Test Case Catalog — All Modules

Date: 2026-05-10  
Owner: QA automation  
Scope: Flutter app, Go backend/API gateway/BFF, Django control panel, Appium Android E2E

## Existing automation inventory

| Surface | Test files | Test cases/functions counted | Primary command |
|---|---:|---:|---|
| Flutter unit/widget | 27 | 148 | `cd app && flutter test` |
| Go backend unit/API | 47 | 194 | `cd backend && go test ./...` |
| Appium/API E2E | 17 | 26 direct pytest tests plus fixture parametrization | `cd qa/appium && ./run_full_android_automation.sh` |
| Django control panel | 1 | 5 | `cd control-panel && python manage.py test` |

## Module coverage matrix

Legend: Automated = executable test exists. Documented = manual/automation-ready case specified below. Gap = not yet fully automated.

| Module | Features covered | Current automated coverage | Status |
|---|---|---|---|
| Auth & onboarding | welcome, unique-username signup, password sign-in, terms, agreement, app gate | Flutter, Appium, Go BFF/API | Automated + documented |
| Profile | setup basics/about/photos/preferences/preview, draft persistence, edit profile | Flutter, Appium, Go BFF | Automated + documented |
| Discovery / Swipe | home discovery, card rendering, filters, profile details, pass/undo, spotlight | Flutter, Appium/API, Go BFF | Automated + documented |
| Matching / Unlock | matches, quest workflow, activity session, trust filters, unlock state | Flutter, Appium/API, Go BFF/modules | Automated + documented |
| Messaging / Chat | chat list, send, delete/undo, bubbles, locked chat | Flutter, Appium, Go services/BFF | Automated + documented |
| Rose gifts / Wallet / Payment | catalog, wallet, buy/top-up, gift send, limits, telemetry, payment UI | Flutter, Appium/API, Go BFF/repository | Automated + documented |
| Engagement | daily prompts, groups, polls, rooms, voice icebreakers, circle challenges, trust badges, nudges, moderation appeals | Flutter provider subset, Appium/API, Go BFF/modules | Automated + documented; UI breadth gap |
| Verification & Safety | verification workflow, admin verification, moderation, reporting, blocked/unsafe flows | Go BFF, Flutter screens smoke gap | Partial automation + documented |
| Friends / Social filters | friend filters, advanced/social filters, friends endpoint flow | Go BFF | API automated; Flutter UI gap |
| Admin control panel | dashboard/views, Go client integration, analytics, Kibana embedding | Django view tests, Go admin BFF | Partial automation + documented |
| Platform / Ops | config, gateway, docs/OpenAPI, readiness, idempotency, migrations, concurrency | Go platform tests, Appium preflight | Automated + documented |

## End-to-end smoke flow test cases

| ID | Module | Scenario | Preconditions | Steps | Expected result | Existing automation |
|---|---|---|---|---|---|---|
| E2E-001 | Auth/Profile | New credential account and profile setup | Backend healthy, emulator ready | Enter unique username, strong password, profile basics → create account | User lands in profile setup without alternate identity input | `qa/appium/tests/test_01_signup_credentials_profile_setup.py` |
| E2E-002 | Auth | Signup validation negative path | App installed fresh | Invalid/duplicate username, weak/mismatched password, short name, or missing DOB → submit | Inline/snackbar validation blocks invalid progression | `qa/appium/tests/test_02_profile_setup_edges.py` |
| E2E-003 | Auth | Existing credential account sign-in | Seed completed username/password account | Sign in with credentials | User reaches authenticated surface | `qa/appium/tests/test_01b_signin_credentials_existing_account.py` |
| E2E-004 | Profile | Edit profile binds saved profile | Seeded profile exists | Login → edit profile → verify fields | Existing profile values render and persist | `qa/appium/tests/test_02_edit_profile.py` |
| E2E-005 | Discovery | Discover and filters | Seed discovery candidates | Navigate discover → open filters → apply city/lifestyle filters | Candidate list remains stable/filtered | `qa/appium/tests/test_03_discover_filters.py`, `test_04_discovery_matrix_api.py` |
| E2E-006 | Discovery | Profile details | Seed candidate | Open candidate details | Details surface renders safety/profile fields | `qa/appium/tests/test_05_profile_details.py`, API contract test |
| E2E-007 | Swipe | Pass and undo | Seed candidate | Pass profile → undo | Original candidate restored or undo state visible | `qa/appium/tests/test_06_swipe_match_creation.py` |
| E2E-008 | Matching/Chat | Matches and chat message | Seed match/chat | Open matches → chat → send message | Message appears in thread | `qa/appium/tests/test_04_matches_chat.py` |
| E2E-009 | Gifts | Chat gift tray/locked banner | Seed wallet/gift/match | Open chat gift tray or locked chat | Gift UI or lock banner renders correctly | `qa/appium/tests/test_08_chat_gifts_locks.py` |
| E2E-010 | Resilience | Background/foreground | App logged in/discovery loaded | Background app → foreground | Discovery state is preserved | `qa/appium/tests/test_10_resilience_edges.py` |

## Flutter app module test cases

### Auth module

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| AUTH-FL-001 | Welcome | Welcome screen renders hero, mid-card, and CTAs in safe area | Widget/UI | Documented; add widget test for latest layout |
| AUTH-FL-002 | Credential sign-in | Username/password fields render and validate input | Widget/Appium | `auth_and_terms_screen_smoke_test.dart`, credential Appium smoke |
| AUTH-FL-003 | Credential signup | Unique username, strong password, confirmation, name, and DOB validation | Widget/E2E | `auth_and_terms_screen_smoke_test.dart`, Appium signup matrix |
| AUTH-FL-004 | Retired-auth guard | Executable QA cannot reintroduce prior selectors, flags, or endpoints | Static regression | `test_auth_automation_contract.py` |
| AUTH-FL-005 | Terms | Local migration, remote failure, success persistence | Unit | `terms_provider_test.dart` |
| AUTH-FL-006 | App gate | Authenticated, unauthenticated, loading, no white flash | Widget | `app_gate_regression_test.dart` |

### Profile module

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| PROF-FL-001 | Draft model | Completion %, copyWith, validation priority | Unit | `profile_draft_test.dart` |
| PROF-FL-002 | Setup notifier | Save basics/about/photos, immutability, completion | Unit | `profile_setup_notifier_test.dart` |
| PROF-FL-003 | Basic info screen | Compact/tablet layout, name/DOB validation, valid submit | Widget | `setup_basic_info_screen_test.dart` |
| PROF-FL-004 | Preferences | Setup vs edit CTAs, save/complete behavior | Widget | `setup_preferences_screen_test.dart` |
| PROF-FL-005 | Preview | Valid draft, loading, incomplete draft, API failure, no photos | Widget | `setup_preview_screen_test.dart` |
| PROF-FL-006 | Photos/About | No overflow smoke for setup photos/about/preview | Widget | `widget_test.dart` |

### Discovery, swipe, and profile detail modules

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| DISC-FL-001 | Home discovery | Loading/error/empty/filter-hidden/card states | Widget | `home_discovery_error_states_test.dart` |
| DISC-FL-002 | Spotlight rail | Empty photo fallback renders safely | Widget | `home_discovery_screen_test.dart` |
| DISC-FL-003 | Swipe card | Responsive height, no photo fallback, spotlight tier badge | Widget | `swipe_card_test.dart` |
| DISC-FL-004 | Responsive | Discovery phone/tablet no-overflow/golden | Widget | `phase3_golden_and_overflow_test.dart` |
| DISC-FL-005 | Profile details | Details UI surface opens from discovery | Appium/UI | `test_05_profile_details.py` |

### Matching and engagement-unlock modules

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| MATCH-FL-001 | Activity session state | Answer completeness, terminal states, copyWith | Unit | `activity_session_provider_test.dart` |
| MATCH-FL-002 | Activity summary | JSON happy path and malformed defaults | Unit | `activity_session_provider_test.dart` |
| MATCH-FL-003 | Trust filters | Active criteria, clearError, replace criteria | Unit | `trust_filter_provider_test.dart` |
| MATCH-FL-004 | Unlock journey | Quest/activity/gesture matrix via API | API/E2E | `test_07_unlock_engagement_contract_api.py`, `test_09_engagement_unlocks_api.py` |

### Messaging, gifts, and wallet modules

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| MSG-FL-001 | Chat screen | Smoke render without layout exceptions | Widget | `chat_screen_smoke_test.dart` |
| MSG-FL-002 | Message bubble | Plain text, gift card, read receipts | Widget | `message_bubble_test.dart` |
| MSG-FL-003 | Delete undo | Undo before timer, commit after timer | Unit | `message_provider_delete_undo_test.dart` |
| MSG-FL-004 | Gifts provider | Idempotency headers, lock response, telemetry | Unit | `message_provider_gifts_test.dart` |
| MSG-FL-005 | Gift catalog model | Categories, exclusive limit, lookup defaults | Unit | `rose_gift_category_test.dart` |
| PAY-FL-001 | Wallet screen | Balance and key sections render | Widget | `wallet_payment_screen_test.dart` |

### Engagement, verification, friends, admin, and common modules

| ID | Feature | Test case | Type | Current automation |
|---|---|---|---|---|
| ENG-FL-001 | Appeals provider | JSON mapping, defaults, status labels | Unit | `moderation_appeals_provider_test.dart` |
| ENG-FL-002 | Daily prompt UI | Prompt load/answer/responders/error states | Widget/API | Documented gap; backend/API automated |
| ENG-FL-003 | Groups/polls/rooms UI | List, join/create/vote/moderation states | Widget/API | Documented UI gap; backend/API automated |
| VER-FL-001 | Verification screens | Landing/upload/selfie/status safe-area smoke | Widget | Documented gap |
| FRIEND-FL-001 | Friends UI | Friends list, filter, block/report path | Widget/API | Documented UI gap; API automated |
| ADMIN-FL-001 | Admin models/UI | Admin model serialization and control surfaces | Unit/Widget | Documented gap in Flutter admin feature |
| COMMON-FL-001 | Themed scaffold | Loading/error/empty/pre-login/post-login/appBar | Widget | `themed_screen_scaffold_test.dart`, `post_login_screen_smoke_test.dart` |

## Backend/API module test cases

### Gateway and platform

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| PLAT-GO-001 | Gateway proxy | Preserve original forwarded host | `server_forwarded_headers_test.go` |
| PLAT-GO-002 | Config | Required Supabase config, defaults, feature flags, durable store | `config_test.go` |
| PLAT-GO-003 | Mediator | Registered and missing handler behavior | `mediator_test.go` |
| PLAT-GO-004 | Concurrency | Worker pool executes tasks | `worker_pool_test.go` |
| PLAT-GO-005 | Migrations | Engagement/rose gift forward coverage, idempotency, rollback safety | postgres migration tests |
| PLAT-GO-006 | Readiness/idempotency | `readyz`, idempotency replay, non-cache server errors | BFF ready/resilience tests |

### Auth, profile, verification, safety

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| AUTH-GO-001 | Credential signup | Unique normalized username, password policy, durable credential/session creation | auth service/module tests |
| AUTH-GO-002 | Credential login/session | Password verification, bearer issue/refresh/revoke/logout | auth service/module tests |
| AUTH-GO-003 | Signup bootstrap | Creates draft, preserves completed profile, rejects underage | `server_signup_test.go` |
| AUTH-GO-004 | Terms | Default agreement and accepted patch | `server_terms_agreements_test.go` |
| PROF-GO-001 | Draft store | Patch/merge/photos/delete/reorder/default retrieval | `store_profile_draft_test.go` |
| VER-GO-001 | Verification workflow | Submission/status/admin verification activity | `store_test.go`, `server_admin_test.go` |
| SAFE-GO-001 | Appeals | Submit/status/admin resolve/user rejection/analytics taxonomy | `server_appeals_test.go` |
| SAFE-GO-002 | Moderation | Room moderation audit, removed user blocked, invalid action | `server_room_moderation_test.go` |

### Discovery, matching, unlock, and social graph

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| DISC-GO-001 | Mock users | Gender count and age range | `service_mock_test.go` |
| DISC-GO-002 | Social filters | Advanced filters, age range, friends flow | `server_social_filters_test.go` |
| DISC-GO-003 | Spotlight | Metadata, non-premium fairness, telemetry, spotlight-only mode | `server_spotlight_test.go` |
| MATCH-GO-001 | Quest domain | Template validation, unsafe patterns, boundaries | matching domain tests |
| MATCH-GO-002 | Quest workflow | Approve/reject/cooldown/rate-limit/chat lock/auto-approve | `server_quest_workflow_test.go` |
| MATCH-GO-003 | Unlock state | Happy path, reject loop, restrict/reset, invalid transition | `unlock_state_test.go` |
| MATCH-GO-004 | Activity session | Complete, partial timeout, summary, replay limit | `server_activity_session_test.go` |
| MATCH-GO-005 | Trust filters | Get/patch persistence and row filtering | `server_trust_filters_test.go` |
| MATCH-GO-006 | Match nudges | Lifecycle, daily cap, blocked/reported suppression | `server_match_nudge_test.go` |

### Messaging, gifts, wallet, billing

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| CHAT-GO-001 | Delete message | Validation, success, repository errors, requester required | chat service/BFF tests |
| GIFT-GO-001 | Catalog/wallet | Catalog, top-up, buy, audit list | `server_gifts_test.go` |
| GIFT-GO-002 | Send gift | Success, insufficient coins, locked chat, idempotency, telemetry | `server_gifts_test.go` |
| GIFT-GO-003 | Durable repository | Rollbacks, durable idempotency, activity persistence, bootstraps users | `gifts_repository_test.go` |
| GIFT-GO-004 | Catalog mapping | Category defaults, icon key, exclusive daily limits | gifts tests |
| BILL-GO-001 | Billing plans | Coexistence matrix endpoint and plan payload | `server_billing_matrix_test.go` |

### Engagement and retention

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| ENG-GO-001 | Daily prompts | Lifecycle, edit window, responders pagination/safety, invalid pagination | `server_daily_prompt_test.go` |
| ENG-GO-002 | Circle challenges | Lifecycle, duplicate submission, not found, membership view | `server_circle_challenge_test.go` |
| ENG-GO-003 | Voice icebreakers | Lifecycle, daily limit, invalid duration | `server_voice_icebreaker_test.go` |
| ENG-GO-004 | Gesture timeline | Decision/score and profanity flag | `server_gesture_timeline_test.go` |
| ENG-GO-005 | Conversation rooms | Lifecycle states, capacity, participation events, friend-only filter | `server_rooms_test.go` |
| ENG-GO-006 | Group coffee polls | Lifecycle, cap, non-participant vote, state, list/filter/limit | `server_group_coffee_poll_test.go` |
| ENG-GO-007 | Community groups | Create/invite/accept and access enforcement | `server_groups_test.go` |
| ENG-GO-008 | Trust badges | Assignment/history and revocation on unsafe behavior | `server_trust_badges_test.go` |
| ENG-GO-009 | Resilience/reporting | Retry behavior, duplicate avoidance, reporting outputs | `server_engagement_resilience_test.go` |
| ENG-GO-010 | Durable mode | Requires quest repo and rejects memory-only engagement features | `server_durable_mode_test.go` |

## Django control panel test cases

| ID | Feature | Test case | Current automation |
|---|---|---|---|
| CP-001 | Views | Dashboard/list/detail views render with expected templates/status | `control_panel/tests/test_views.py` |
| CP-002 | Go client | Admin API calls pass `X-Admin-User` and handle errors | Documented gap |
| CP-003 | Kibana embedding | Uses configured base URL/index/dashboard path | Documented gap |
| CP-004 | Auth/session | Operator access control, unauthenticated redirects | Documented gap |
| CP-005 | Admin actions | Resolve appeals/verify users/billing actions call Go APIs | Documented gap |

## Appium/API automation cases

| ID | Feature | File/test |
|---|---|---|
| APP-000 | Environment/seed preflight | `test_00_seed_preflight.py` — health, OpenAPI, seeds, discovery/matches/gifts/wallet |
| APP-001 | Credential signup profile setup | `test_01_signup_credentials_profile_setup.py` |
| APP-001B | Existing account credential sign-in | `test_01b_signin_credentials_existing_account.py` |
| APP-002 | Signup/profile setup negative | `test_02_profile_setup_edges.py` |
| APP-002B | Profile setup entry/photo gate/resume | `test_03_profile_setup_flow.py` |
| APP-003 | Edit profile | `test_02_edit_profile.py` |
| APP-004 | Discover filters UI | `test_03_discover_filters.py` |
| APP-005 | Discovery API matrix | `test_04_discovery_matrix_api.py` + `fixtures/discovery_matrix.json` |
| APP-006 | Matches/chat UI | `test_04_matches_chat.py` |
| APP-007 | Chat/gift API matrix | `test_05_chat_gifts_contract_api.py` + fixtures |
| APP-008 | Profile details UI/API | `test_05_profile_details.py`, `test_06_profile_details_contract_api.py` |
| APP-009 | Swipe pass/undo | `test_06_swipe_match_creation.py` |
| APP-010 | Unlock/engagement contracts | `test_07_unlock_engagement_contract_api.py`, `test_09_engagement_unlocks_api.py` |
| APP-011 | Engagement hub UI breadth | `test_14_engagement_ui_breadth.py` traverses every documented engagement and friends surface |
| APP-011 | Gifts/locked chat UI | `test_08_chat_gifts_locks.py` |
| APP-012 | Resilience | `test_10_resilience_edges.py` |

## Priority gaps to automate next

| Priority | Gap | Recommended automation |
|---|---|---|
| P0 | Android native-PostgreSQL release journey | Keep credential signup/sign-in plus discovery/match/persisted-chat restart/resume green on device |
| P1 | Verification Flutter screens | Add smoke/validation widget tests for landing/upload/selfie/status |
| P1 | Friends Flutter UI | Add friends list/filter/error/empty widget tests |
| P1 | Engagement Flutter screens | Add smoke tests for daily prompt, rooms, groups, polls, trust badges, voice, circles |
| P1 | Control panel Go client/Kibana/auth | Add Django tests with mocked Go client and env-driven Kibana settings |
| P2 | Admin Flutter feature | Add model/provider/widget tests or remove from runtime build if unused |
| P2 | Calls backend module | Add placeholder contract/unit tests once active call endpoints exist |

## Release QA gate

A module is QA-complete when all apply:

1. Unit/provider/domain tests cover validation, success, error, and retry/idempotency paths.
2. Widget tests cover loading, error, empty, success, small phone, and tablet layout states.
3. API contract tests cover happy path, invalid input, auth/actor headers, and backward-compatible aliases.
4. E2E Appium tests cover at least one critical user journey per user-facing module.
5. Durable writes have persistence, idempotency, rollback/retry, activity/reporting output tests.
6. Reports are attached under `qa/reports/` or documented in a QA execution report.
