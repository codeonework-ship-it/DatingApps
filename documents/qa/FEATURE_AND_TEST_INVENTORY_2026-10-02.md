# Connect — Feature, Control & Test Inventory (2026-10-02)

Machine-readable twin: [`qa/catalog/feature_catalog.json`](../../qa/catalog/feature_catalog.json) (same ids; drives the QA runner).

**How this was built.** Every Dart file under `app/lib` was scanned for interactive widgets (buttons, `InkWell`/`GestureDetector`, switches, chips, sliders, fields, menus, `Dismissible`, `RefreshIndicator`, `PageView`, `showModalBottomSheet`/`showDialog`, long-press/drag handlers) including private wrapper widgets and helper methods that forward a callback, with each callback followed through local methods → Riverpod notifiers → Dio calls and matched against the Go BFF route table (`backend/internal/bff/mobile/server.go`). Tests were scanned in all suites (Flutter `app/test`, Playwright `website/tests`, Appium `qa/appium/tests`, API e2e `qa/api_e2e/tests`, Go `backend/**/_test.go`, Django `control-panel/control_panel/tests`, console smoke) for the controls they **act on** and whether an **outcome is asserted after the action**. Website pages and operator-console routes are inventoried at page/route level.

**Snapshot.** Working tree on 2026-10-02, which includes the lead's *uncommitted* fix for the profile Message/Love and Spotlight buttons (`profile_actions.dart`, `app/test/features/swipe/profile_actions_test.dart`). Where HEAD (`b96977f9d`) differs it is called out.

**Status legend.** `automated` = a test performs the action and asserts its effect · `presence-only` = tests find the control (or tap it) but never assert what it does — the pattern that hid the profile-dock bug · `partial` = covered indirectly · **GAP** = nothing. *API* is inferred statically; rows marked *unclassified* need a human look.

## 1. Coverage summary

| Metric | Value |
|---|---|
| Features (screens, sheets, shared widgets, web pages, console areas) | 171 |
| Screens in the Flutter screen matrix | 79 |
| Interactive controls (all surfaces) | 1221 |
| … in the Flutter app | 1063 |
| … website (public pages) | 35 |
| … operator console routes | 123 |
| Test cases | 2309 |
| Cases automated / partial / presence-only / not automated | 868 / 131 / 87 / 1223 |
| Cases automated (%) | 37.6% (incl. partial 43.3%) |
| App controls whose **action** is asserted by a UI test | 218 of 1063 (20.5%) |
| App controls tested for presence only | 87 (8.2%) |
| App controls with no UI test at all | 758 (71.3%) |

**Controls by type**

| field | sheet | button | toggle | menu | gesture | link | swipe |
|---|---|---|---|---|---|---|---|
| 107 | 69 | 753 | 113 | 57 | 37 | 80 | 5 |

**Cases by type and status**

| Type | automated | partial | presence-only | not automated |
|---|---|---|---|---|
| a11y | 149 | 0 | 0 | 0 |
| edge | 18 | 0 | 0 | 89 |
| happy | 575 | 2 | 87 | 835 |
| l10n | 2 | 129 | 0 | 0 |
| layout | 86 | 0 | 0 | 0 |
| negative | 38 | 0 | 0 | 299 |

**Cases automated, by suite** (a case can be covered by several suites) and tests scanned

| Suite | Cases covered | Tests scanned |
|---|---|---|
| flutter | 528 | 829 |
| api_e2e | 196 | 237 |
| go | 188 | 690 |
| appium | 166 | 89 |
| django | 112 | 173 |
| playwright | 72 | 75 |

**By area (app + web + console)**

| Area | Features | Controls | Action asserted | Presence-only | GAP |
|---|---|---|---|---|---|
| Navigation & Settings | 14 | 132 | 40 | 4 | 88 |
| Operator console | 27 | 123 | 0 | 0 | 0 |
| Blog / Chapters | 8 | 101 | 2 | 13 | 86 |
| Profile | 11 | 87 | 27 | 3 | 57 |
| Engagement Hub | 11 | 81 | 11 | 8 | 62 |
| Clubs & Lists | 11 | 72 | 1 | 6 | 65 |
| Discover | 8 | 62 | 17 | 9 | 36 |
| Friends & Introducer | 4 | 59 | 19 | 2 | 38 |
| Groups | 6 | 55 | 17 | 2 | 36 |
| Date Plans | 5 | 55 | 6 | 4 | 45 |
| Today / Intentional Dating | 7 | 46 | 7 | 9 | 30 |
| Chat (dating) | 2 | 41 | 10 | 1 | 30 |
| Website (public) | 10 | 35 | 0 | 0 | 0 |
| Matches | 4 | 34 | 8 | 3 | 23 |
| Auth & Onboarding | 5 | 32 | 18 | 2 | 12 |
| First Chapter Studio | 2 | 31 | 0 | 1 | 30 |
| Help & Support | 4 | 28 | 14 | 3 | 11 |
| Payments & Membership | 4 | 26 | 0 | 6 | 20 |
| Photo Themes | 4 | 22 | 0 | 5 | 17 |
| City Pilot | 1 | 18 | 0 | 3 | 15 |
| Shared components | 3 | 14 | 0 | 1 | 13 |
| Social Chat (friends/rooms/groups) | 1 | 12 | 4 | 0 | 8 |
| Web Workspace | 4 | 11 | 4 | 0 | 7 |
| Graduation | 3 | 10 | 9 | 0 | 1 |
| Safety | 1 | 9 | 0 | 1 | 8 |
| Verification | 4 | 9 | 2 | 0 | 7 |
| Calls | 2 | 5 | 0 | 1 | 4 |
| Celebrations & Rewards | 2 | 4 | 2 | 0 | 2 |
| Notifications | 1 | 4 | 0 | 0 | 4 |
| Today Wall | 1 | 3 | 0 | 0 | 3 |
| End-to-end journeys | 1 | 0 | 0 | 0 | 0 |

_Operator-console and website controls carry their own cases (`.performs`, `.renders`, `.authz`, page cases) instead of `.action`; their coverage is in the case totals above._

## 2. Biggest gaps, prioritised

Score = area risk (money/auth/safety highest) + mutating API + navigation + (presence-only tests ⇒ false confidence) + risk flags (no-op, result popped to opener, known regression). The top of this list is where a bug like the profile dock can ship unnoticed.

### 2.1 Top 40 controls whose action is never asserted

| # | Area | Screen | Control | qa key | What it should do | Tests today |
|---|---|---|---|---|---|---|
| 1 | Discover | SpotlightProfilesScreen | Message | `qa.discovery.card_message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar | **none** |
| 2 | Payments & Membership | SubscriptionScreen | Auto-renew | `—` | calls POST /v1/billing/subscription/{}/${enabled ; opens showDialog; closes screen/sheet, pops a result to caller, shows | presence-only: flutter: `membership_l10n_de_test.dart` › membership screen renders in German; flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons |
| 3 | Payments & Membership | SubscriptionScreen | Update card | `—` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscript | presence-only: flutter: `subscription_screen_test.dart` › paid member sees card, renewal date and the auto-renew switch |
| 4 | Payments & Membership | SubscriptionScreen | Subscribe with card | `—` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscript | presence-only: flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons; flutter: `subscription_screen_test.dart` › paid member sees card, renewal date and the auto-renew switch |
| 5 | Payments & Membership | SubscriptionScreen | Subscribe with card | `—` | calls POST /v1/billing/subscription/{userID}/change-plan, GET /v1/billing/plans, GET /v1/billing/subscription/{userID},  | presence-only: flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons; flutter: `subscription_screen_test.dart` › paid member sees card, renewal date and the auto-renew switch |
| 6 | Discover | HomeDiscoveryScreen | Meet {name} | `qa.today.profile.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | presence-only: flutter: `today_introductions_test.dart` › Pause hides cached introductions; flutter: `today_introductions_test.dart` › Failed refresh hides cached profiles and offers retry |
| 7 | Discover | HomeDiscoveryScreen | Open card (icon verified) | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | presence-only: flutter: `today_rail_test.dart` › renders the Today rail with reason chips |
| 8 | Discover | HomeDiscoveryScreen | Open card (icon verified) | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | presence-only: flutter: `today_rail_test.dart` › renders the Today rail with reason chips |
| 9 | Discover | SpotlightProfilesScreen | Passed ({count}) | `—` | NO-OP: callback body is empty | **none** |
| 10 | Today / Intentional Dating | TodayCoverAndWall | Comments | `qa.today.wall.chapter.*` | calls POST /v1/walls/views; may open BlogDetailScreen | presence-only: flutter: `today_wall_test.dart` › Today wall carousel > shows up to ten mixed picks with a position indi; flutter: `today_wall_test.dart` › Today wall carousel > opening a chapter records a view and opens it |
| 11 | Matches | MatchesListScreen | Report | `qa.matches.report_action` | calls POST /v1/safety/report; may open ModerationAppealsScreen; opens showModalBottomSheet, showReportUserSheet; closes  | **none** |
| 12 | Chat (dating) | ChatScreen | Long-press message | `qa.chat.message.*` | calls DELETE /v1/chat/{matchID}/messages/{messageID}, POST /v1/chat/{}/messages/{}/gift/{}; opens showModalBottomSheet;  | presence-only: playwright: `chat.spec.js` › conversation redesign at ${width}px |
| 13 | Chat (dating) | ChatScreen | {count, plural, =1{1 coin} other{{count} coin | `qa.chat.gift_item.*` | calls GET /v1/chat/gifts, GET /v1/wallet/{userID}/coins, POST /v1/chat/{matchID}/gifts/send, GET /v1/chat/{matchID}/mess | **none** |
| 14 | Payments & Membership | SubscriptionScreen | _SandboxControls onEvent | `—` | calls POST /v1/billing/sandbox/subscriptions/{userID}/simulate | **none** |
| 15 | Payments & Membership | WalletPaymentScreen | Opening… | `—` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscript | **none** |
| 16 | Safety | SosScreen | Activate SOS | `qa.safety.activate_sos` | calls POST /v1/safety/sos; opens showDialog; closes screen/sheet, pops a result to caller | **none** |
| 17 | Discover | HomeDiscoveryScreen | Open profile (icon person) | `—` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | **none** |
| 18 | Discover | HomeDiscoveryScreen | Open profile (icon person) | `—` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | **none** |
| 19 | Discover | HomeDiscoveryScreen | Message | `qa.discovery.card_message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, | **none** |
| 20 | Discover | HomeDiscoveryScreen | Super like (icon star) | `qa.discovery.superlike_button` | calls POST /v1/swipe; may open MatchNotificationScreen; refreshes data, shows snackbar, updates local state | **none** |
| 21 | Discover | LikedMeScreen | Verified | `qa.liked_me.card.*` | calls POST /v1/profile/views, POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, ProfileDetails | **none** |
| 22 | Discover | SpotlightProfilesScreen | View more | `qa.discovery.view_more_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, ProfileDetailsScreen, Subs | **none** |
| 23 | Discover | SpotlightProfilesScreen | Undo (icon undo) | `qa.discovery.undo_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, | **none** |
| 24 | Blog / Chapters | SocialLikeButton | Comments | `—` | calls POST /v1/walls/views; may open BlogDetailScreen | presence-only: flutter: `blog_social_test.dart` › community feed leads with Featured Stories and engagement; flutter: `today_featured_rail_test.dart` › shows up to five featured cards |
| 25 | Navigation & Settings | MainNavigationScreen | Discovery preferences | `—` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens sho | **none** |
| 26 | Navigation & Settings | MainNavigationScreen | Discovery preferences | `—` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens sho | **none** |
| 27 | Navigation & Settings | MainNavigationScreen | View | `—` | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open Notific | **none** |
| 28 | Navigation & Settings | SettingsScreen | Logout | `—` | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open WelcomeScreen; refreshes data | **none** |
| 29 | Friends & Introducer | IntroducerScreen | Suggest an introduction | `—` | calls POST /v1/friends/{userID}/intros; refreshes data, updates local state | presence-only: flutter: `introducer_test.dart` › friend workspace only fetches consent and private receipts; flutter: `introducer_test.dart` › offline consent load gives retry and no composer |
| 30 | Matches | ActivitySessionScreen | Start a new session | `—` | calls POST /v1/activities/sessions/start | **none** |
| 31 | Matches | ActivitySessionScreen | Submit Responses | `—` | calls POST /v1/activities/sessions/{sessionID}/submit, GET /v1/activities/sessions/{sessionID}/summary | **none** |
| 32 | Matches | MatchesListScreen | Send a nudge | `qa.matches.nudge_action` | calls POST /v1/engagement/match-nudges/send; closes screen/sheet, shows snackbar | **none** |
| 33 | Matches | MatchesListScreen | Close conversation | `qa.matches.unmatch_action` | calls DELETE /v1/matches/{matchID}; opens showDialog; closes screen/sheet, pops a result to caller | **none** |
| 34 | Matches | MatchesListScreen | Submit report | `—` | calls POST /v1/safety/report | **none** |
| 35 | Chat (dating) | ChatScreen | Find the words | `—` | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | **none** |
| 36 | Chat (dating) | ChatScreen | Send a little joy | `—` | calls POST /v1/chat/{matchID}/gifts/events; updates local state | **none** |
| 37 | Chat (dating) | ChatScreen | Help me say it | `qa.chat.copilot_button` | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | **none** |
| 38 | Payments & Membership | SubscriptionScreen | Your plan renews automatically at the end of  | `—` | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/a | presence-only: flutter: `membership_l10n_de_test.dart` › membership screen renders in German; flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons |
| 39 | Profile | ShowcaseChapter | favorite border rounded (icon favorite_border | `—` | calls POST /v1/walls/views; may open BlogDetailScreen | **none** |
| 40 | Safety | SosScreen | Resolution: {note} | `—` | calls GET /v1/safety/sos/{userID} | presence-only: flutter: `sos_screen_l10n_test.dart` › English alert history keeps its wording |

### 2.2 Structural findings

* **No-op controls (1)** — callbacks with an empty body; they look tappable and do nothing:
  * SpotlightProfilesScreen › **Passed ({count})** (`app/lib/features/swipe/screens/spotlight_profiles_screen.dart:475`)
* **Result popped to opener — GraduationCelebrationScreen**: 2 opener call site(s) do not read the result: app/lib/features/graduation/widgets/graduation_banner.dart:167, app/lib/features/graduation/widgets/graduation_banner.dart:203. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **Result popped to opener — ActivitySessionScreen**: 1 opener call site(s) do not read the result: app/lib/features/matching/screens/matches_list_screen.dart:565. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **Result popped to opener — ProfileDetailsScreen**: 3 opener call site(s) do not read the result: app/lib/features/swipe/screens/liked_me_screen.dart:109, app/lib/features/swipe/screens/liked_profiles_screen.dart:108, app/lib/features/swipe/screens/passed_profiles_screen.dart:106. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **qa keys shared by different screens (6)** — an Appium/Playwright step that finds the key cannot tell which screen it is on, so a pass on Discover can mask a broken Spotlight. Examples: `qa.discovery.like_button` (HomeDiscoveryScreen, SpotlightProfilesScreen); `qa.discovery.card_message_button` (HomeDiscoveryScreen, SpotlightProfilesScreen); `qa.discovery.view_more_button` (HomeDiscoveryScreen, SpotlightProfilesScreen); `qa.discovery.pass_button` (HomeDiscoveryScreen, SpotlightProfilesScreen); `qa.discovery.superlike_button` (HomeDiscoveryScreen, SpotlightProfilesScreen); `qa.discovery.undo_button` (HomeDiscoveryScreen, SpotlightProfilesScreen)
* **Automation readiness** — 767 of 994 app controls have **no `qa.*` key/semantics id**; device suites must fall back to visible text, which changes per locale (10 locales) and look.
* **Unclassified actions** — 85 controls whose effect could not be resolved statically (focus moves, local filters, callbacks into generic helpers). Each is listed per screen below; the runner should at least assert a visible state change.
* **API tested, UI wiring not** — 161 controls call an endpoint that has Go/api_e2e coverage, but no UI test proves the control actually calls it. This is the Spotlight failure mode (endpoint fine, button never called it).
* **Error paths** — 12 of 271 API-backed controls have a UI test for the failure path (500/timeout → readable error, state rolled back, no double submit).
* **Gestures** — the Discover deck has **no drag-to-swipe gesture**: Like/Pass/Super like/Undo are buttons (`SwipeButtons`). Real swipe/drag gestures are: Today wall `PageView`, profile photo reels (`PageView`), setup preview pager, notification inbox swipe-to-dismiss (`Dismissible`), reward burst dismiss, photo reorder drag (setup photos), long-press on chat/social-chat bubbles, and ~29 pull-to-refresh lists. Only a handful of `tester.drag/fling` calls exist in the Flutter suite.
* **Locale rendering** — the hard-coded-strings guard is a static ratchet; no test renders app screens in each of the 10 locales (only the website does).

## 3. Inventory by area

Each table lists every control: type, `qa` key, what it does (API + visible result), the tests that **perform it and assert the outcome**, and status. Non-action cases (API contract, failure path, validation, layout, a11y, l10n, back affordance) are in the JSON under each feature's `cases`.

### Auth & Onboarding

#### AccountRecoveryScreen — `auth.account_recovery`

Route: opened from: auth_screen · Source: `app/lib/features/auth/screens/account_recovery_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to sign in | button | — | closes screen/sheet | — | **GAP** |
| I have my code | toggle | — | updates local state | flutter: `account_recovery_screen_test.dart` › lost code sends a help request and shows the neutral answer | automated |
| Username | field | `qa.recovery.username` | opens TextField | flutter: `auth_l10n_de_test.dart` › account recovery speaks German<br>playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>+7 more | automated |
| Recovery code | field | `qa.recovery.code` | opens TextField | flutter: `account_recovery_screen_test.dart` › recovery code resets the password with a strong password<br>flutter: `account_recovery_screen_test.dart` › an invalid code shows a clear error | automated |
| Hide password | field | `qa.recovery.new_password` | opens TextField | flutter: `account_recovery_screen_test.dart` › recovery code resets the password with a strong password<br>flutter: `account_recovery_screen_test.dart` › an invalid code shows a clear error | automated |
| Hide password | button | `qa.recovery.new_password` | updates local state | flutter: `account_recovery_screen_test.dart` › recovery code resets the password with a strong password<br>flutter: `account_recovery_screen_test.dart` › an invalid code shows a clear error | automated |
| Anything that helps us (optional) | field | `qa.recovery.message` | opens TextField | — | **GAP** |
| Ask for help | button | `qa.recovery.submit` | calls POST /v1/auth/password/recover, POST /v1/auth/recovery/assistance; updates local state | flutter: `account_recovery_screen_test.dart` › lost code sends a help request and shows the neutral answer<br>flutter: `account_recovery_screen_test.dart` › recovery code resets the password with a strong password<br>+2 more | automated |

#### AuthScreen — `auth.auth`

Route: opened from: signup_screen, web_entry_screen, welcome_screen · Source: `app/lib/features/auth/screens/auth_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to welcome | button | — | may open WelcomeScreen; closes screen/sheet | — | **GAP** |
| Password | field | `qa.signin.password_field` | calls POST /v1/auth/login; may open MainNavigationScreen; closes screen/sheet, shows snackbar | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `chat.spec.js` › conversation redesign at ${width}px<br>+15 more | automated |
| Hide password | button | — | updates local state | — | **GAP** |
| Can't sign in? | button | `qa.signin.cant_sign_in` | may open AccountRecoveryScreen | — | **GAP** |
| Sign in | button | `qa.signin.login_button` | calls POST /v1/auth/login; may open MainNavigationScreen; closes screen/sheet, shows snackbar | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `chat.spec.js` › conversation redesign at ${width}px<br>+16 more | automated |
| username | field | `qa.signin.username_field` | local/unclassified action — callback: (_) => passwordFocusNode.requestFocus() | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `chat.spec.js` › conversation redesign at ${width}px<br>+15 more | automated |

#### SignupScreen — `auth.signup`

Route: opened from: web_entry_screen, welcome_screen · Source: `app/lib/features/auth/screens/signup_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Select date of birth | sheet | — | presents a dialog/picker | — | **GAP** |
| Back | button | — | closes screen/sheet | — | **GAP** |
| your_username | field | `qa.signup.username_field` | local/unclassified action — callback: (_) => _passwordFocus.requestFocus() | flutter: `auth_l10n_de_test.dart` › sign-up validation messages are German | automated |
| At least 8 characters | field | `qa.signup.password_field` | local/unclassified action — callback: (_) => _confirmPasswordFocus.requestFocus() | only checks presence: flutter: `auth_and_terms_screen_smoke_test.dart` › SignupScreen smoke > renders username and password signup without OTP | presence-only |
| Hide password | button | `qa.signup.password_field` | updates local state | only checks presence: flutter: `auth_and_terms_screen_smoke_test.dart` › SignupScreen smoke > renders username and password signup without OTP | presence-only |
| Confirm password | field | `qa.signup.confirm_password_field` | local/unclassified action — callback: (_) => _nameFocus.requestFocus() | — | **GAP** |
| Hide password | button | `qa.signup.confirm_password_field` | updates local state | — | **GAP** |
| Select date | button | `qa.signup.dob_field` | opens showDatePicker; updates local state | appium: `test_02_profile_setup_edges.py` › test_signup_validation_blocks_invalid_username<br>appium: `test_02_profile_setup_edges.py` › test_signup_validation_blocks_weak_password_and_short_name<br>+2 more | automated |
| _GenderSelector onChanged | button | — | updates local state | — | **GAP** |
| Create account | button | `qa.signup.create_account_button` | calls POST /v1/auth/signup, POST /v1/auth/signup/bootstrap; shows snackbar | flutter: `auth_and_terms_screen_smoke_test.dart` › SignupScreen smoke > rejects a one-character username before submittin<br>flutter: `auth_l10n_de_test.dart` › sign-up validation messages are German<br>+6 more | automated |
| Sign in | button | — | may open AuthScreen | playwright: `website.spec.js` › signup sign-in link preserves browser auth routing<br>appium: `test_01b_signin_credentials_existing_account.py` › test_existing_account_username_signin_reaches_authenticated_surface | automated |

#### UserAgreementScreen — `auth.user_agreement`

Route: opened from: main · Source: `app/lib/features/auth/screens/user_agreement_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| I agree to the Terms & Privacy Policy | button | `qa.terms.accept_checkbox` | updates local state | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup<br>appium: `test_01b_signin_credentials_existing_account.py` › test_existing_account_username_signin_reaches_authenticated_surface | automated |
| accept checkbox input | toggle | `qa.terms.accept_checkbox_input` | updates local state | — | **GAP** |
| I Accept and Continue | button | `qa.terms.continue_button` | calls PATCH /v1/users/{userID}/agreements/terms; shows snackbar | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup<br>appium: `test_01b_signin_credentials_existing_account.py` › test_existing_account_username_signin_reaches_authenticated_surface | automated |
| Sign out | button | `qa.terms.sign_out` | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID} | playwright: `photo-upload.spec.js` › browser upload, reload and onboarding completion preserve the auth gat<br>playwright: `website.spec.js` › browser login, live stream, deep links, preferences and reload recover | automated |

#### WelcomeScreen — `auth.welcome`

Route: opened from: auth_screen, main, settings_screen, web_entry_screen · Source: `app/lib/features/auth/screens/welcome_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create account | button | `qa.welcome.signup_button` | may open SignupScreen | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup<br>appium: `test_02_profile_setup_edges.py` › test_signup_validation_blocks_invalid_username<br>+4 more | automated |
| Just here to introduce friends | button | — | may open SignupScreen | — | **GAP** |
| Already a member?  | button | `qa.welcome.signin_button` | may open AuthScreen | playwright: `website.spec.js` › signup sign-in link preserves browser auth routing<br>appium: `test_01b_signin_credentials_existing_account.py` › test_existing_account_username_signin_reaches_authenticated_surface | automated |

### Discover

#### ProfileActions — `swipe.profile_actions`

Route: embedded / not directly routed · Source: `app/lib/features/swipe/profile_actions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See plans | button | — | may open SubscriptionScreen | only checks presence: flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > the daily like limit is e | presence-only |

#### HomeDiscoveryScreen — `swipe.home_discovery`

Route: #/discover (web) / bottom nav: Discover tab (mobile) · Source: `app/lib/features/swipe/screens/home_discovery_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Not now | sheet | — | presents a bottom sheet | — | **GAP** |
| See plans | button | — | may open SubscriptionScreen; closes screen/sheet | — | **GAP** |
| Not now | button | — | closes screen/sheet | — | **GAP** |
| Meet {name} | button | `qa.today.profile.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | only checks presence: flutter: `today_introductions_test.dart` › Pause hides cached introductions | presence-only |
| Back to Today | button | — | updates local state | only checks presence: flutter: `discover_matches_test.dart` › $plan opens Discover Matches with a real deck and filters | presence-only |
| Open profile (icon person) | button | — | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | — | **GAP** |
| Open card (icon verified) | button | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | only checks presence: flutter: `today_rail_test.dart` › renders the Today rail with reason chips | presence-only |
| View all | button | — | may open SpotlightProfilesScreen | — | **GAP** |
| Open card (icon verified) | button | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | only checks presence: flutter: `today_rail_test.dart` › renders the Today rail with reason chips | presence-only |
| Open profile (icon person) | button | — | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | — | **GAP** |
| View more | button | — | may open SpotlightProfilesScreen | — | **GAP** |
| Unable to load profiles | button | `qa.discovery.retry_state` | calls GET /v1/discovery/{userID} | only checks presence: flutter: `home_discovery_error_states_test.dart` › HomeDiscoveryScreen error states > shows error state when profiles fai | presence-only |
| No profiles | gesture | `qa.discovery.empty_state` | calls GET /v1/discovery/{userID} | only checks presence: flutter: `home_discovery_error_states_test.dart` › HomeDiscoveryScreen error states > shows empty state with refresh butt | presence-only |
| Like (icon favorite) | button | `qa.discovery.like_button` | calls POST /v1/swipe; may open MatchNotificationScreen; refreshes data, shows snackbar, updates local state | appium: `test_06_swipe_match_creation.py` › test_discovery_like_updates_deck_state | automated |
| Message | button | `qa.discovery.card_message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local state | — | **GAP** |
| View more | button | `qa.discovery.view_more_button` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | appium: `test_05_profile_details.py` › test_discovery_profile_detail_surface<br>appium: `test_05_profile_details.py` › test_discovery_profile_detail_back_preserves_deck<br>+3 more | automated |
| Pass (icon close) | button | `qa.discovery.pass_button` | calls POST /v1/swipe; updates local state | appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| Super like (icon star) | button | `qa.discovery.superlike_button` | calls POST /v1/swipe; may open MatchNotificationScreen; refreshes data, shows snackbar, updates local state | — | **GAP** |
| Undo (icon undo) | button | `qa.discovery.undo_button` | local/unclassified action — callback: swipeNotifier.undoSwipe ⚠  | appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| Notifications (icon notifications_none_rounded) | button | — | opens showDialog | — | **GAP** |
| Notifications | sheet | — | presents a dialog/picker | — | **GAP** |
| Passed | button | `qa.discovery.passed_button` | may open PassedProfilesScreen | appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| _NotificationBell onTap | button | — | opens showModalBottomSheet | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Passed | button | `qa.discovery.passed_button` | may open PassedProfilesScreen | appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| Who liked me (icon visibility_outlined) | button | `qa.discovery.notification.who_liked_me` | may open LikedMeScreen; closes screen/sheet | flutter: `liked_me_screen_test.dart` › the Discover notification opens who liked me | automated |
| Fits your week | button | — | may open DatingRhythmScreen | — | **GAP** |

#### LikedMeScreen — `swipe.liked_me`

Route: opened from: home_discovery_screen, main_navigation_screen, notification_inbox_screen, profile_view_screen, web_member_workspace · Source: `app/lib/features/swipe/screens/liked_me_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See plans | button | — | may open SubscriptionScreen | — | **GAP** |
| Retry | button | — | calls GET /v1/discovery/{userID}/liked-me | — | **GAP** |
| Like back | button | `qa.liked_me.like_back.*` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar | flutter: `liked_me_screen_test.dart` › liking back a match opens the match screen | automated |
| Verified | button | `qa.liked_me.card.*` | calls POST /v1/profile/views, POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes da | — | **GAP** |
| Pass | button | `qa.liked_me.pass.*` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar | flutter: `liked_me_screen_test.dart` › passing removes the member without a match<br>appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| RefreshIndicator onRefresh | gesture | — | calls GET /v1/discovery/{userID}/liked-me | — | **GAP** |

#### LikedProfilesScreen — `swipe.liked_profiles`

Route: opened from: profile_view_screen · Source: `app/lib/features/swipe/screens/liked_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| chevron right (icon chevron_right) | button | — | may open ProfileDetailsScreen | — | **GAP** |

#### PassedProfilesScreen — `swipe.passed_profiles`

Route: opened from: home_discovery_screen · Source: `app/lib/features/swipe/screens/passed_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| chevron right (icon chevron_right) | button | — | may open ProfileDetailsScreen | — | **GAP** |

#### ProfileDetailsScreen — `swipe.profile_details`

Route: opened from: home_discovery_screen, liked_me_screen, liked_profiles_screen, passed_profiles_screen, spotlight_profiles_screen · Source: `app/lib/features/swipe/screens/profile_details_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Submit report | button | — | calls POST /v1/safety/report | flutter: `profile_details_report_test.dart` › a sent report is confirmed even without a report id | automated |
| Appeal | button | — | may open ModerationAppealsScreen | only checks presence: flutter: `profile_details_report_test.dart` › a sent report is confirmed even without a report id | presence-only |
| Introducing | button | — | may open ProfileGalleryScreen | only checks presence: flutter: `profile_details_cinematic_test.dart` › hero introduces the member by name and age | presence-only |
| {name}, photo {index} of {count} | button | — | may open ProfileGalleryScreen | — | **GAP** |
| Go back | button | — | closes screen/sheet | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| Back (icon arrow_back_rounded) | button | `qa.profile_detail.back_button` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `profile_details_cinematic_test.dart` › back returns none<br>appium: `test_05_profile_details.py` › test_discovery_profile_detail_back_preserves_deck | automated |
| Report | button | `qa.profile_detail.report_button` | calls POST /v1/safety/report; may open ModerationAppealsScreen; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `profile_details_cinematic_test.dart` › report stays one tap away in the top bar<br>flutter: `profile_details_report_test.dart` › dismissing the report sheet does not claim a report was sent<br>+4 more | automated |
| Love (icon favorite_rounded) | button | `qa.profile_detail.love_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; closes screen/sheet, pops a result to caller, refreshes da ⚠ pops a result to its opener — verify every opener handles it ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love saves one like for t<br>flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love that makes a match s<br>+3 more | automated |
| Message (icon chat_bubble_outline_rounded) | button | `qa.profile_detail.message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Message with an existing <br>flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Message without a match s<br>+2 more | automated |

#### SpotlightProfilesScreen — `swipe.spotlight_profiles`

Route: opened from: home_discovery_screen · Source: `app/lib/features/swipe/screens/spotlight_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Apply | sheet | — | presents a bottom sheet | — | **GAP** |
| Verified only | toggle | — | local/unclassified action — callback: (value) { setSheetState(() => localVerifiedOnly = value); } | — | **GAP** |
| RangeSlider onChanged | toggle | — | local/unclassified action — callback: (value) { setSheetState(() => localAgeRange = value); } | — | **GAP** |
| Reset | button | — | local/unclassified action — callback: () { setSheetState(() { localVerifiedOnly = false; localAgeRange = const RangeValues(20, 5 ⚠  | — | **GAP** |
| Apply | button | — | closes screen/sheet, updates local state | — | **GAP** |
| Back (icon arrow_back_ios_new_rounded) | button | — | closes screen/sheet | — | **GAP** |
| Filters | button | — | opens showModalBottomSheet; closes screen/sheet, updates local state | — | **GAP** |
| Like (icon favorite) | button | `qa.discovery.like_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › Spotlight screen buttons reach the server > $key saves is_like=$like f | automated |
| Message | button | `qa.discovery.card_message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar ⚠ see history in JSON (profile/Spotlight dock regression) | — | **GAP** |
| View more | button | `qa.discovery.view_more_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows sn | — | **GAP** |
| Pass (icon close) | button | `qa.discovery.pass_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › Spotlight screen buttons reach the server > $key saves is_like=$like f | automated |
| Super like (icon star) | button | `qa.discovery.superlike_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › Spotlight screen buttons reach the server > $key saves is_like=$like f | automated |
| Undo (icon undo) | button | `qa.discovery.undo_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local state | — | **GAP** |
| Passed ({count}) | button | — | NO-OP: callback body is empty ⚠ NO-OP callback: control does nothing when used | — | **GAP** |
| Messages | button | — | shows snackbar | — | **GAP** |
| GestureDetector onTap | button | — | shows snackbar | — | **GAP** |

#### ProfileDetailsScreen (opened from every entry point) — `discover.profile_entry_points`

Route: Discover card View more / Spotlight rail / Spotlight screen / Today rail / Liked you / Liked / Passed / Matches · Source: `app/lib/features/swipe/screens/profile_details_screen.dart`, `app/lib/features/swipe/profile_actions.dart`, `app/lib/features/swipe/screens/home_discovery_screen.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Love works when the profile is opened from Discover deck card 'View more' | happy | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love saves one like for t<br>flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love that makes a match s<br>+5 more | partial |
| Message works when the profile is opened from Discover deck card 'View more' | happy | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love saves one like for t<br>flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > Love that makes a match s<br>+5 more | partial |
| Love works when the profile is opened from Discover Spotlight rail avatar | happy | — | **GAP** |
| Message works when the profile is opened from Discover Spotlight rail avatar | happy | — | **GAP** |
| Love works when the profile is opened from Full Spotlight screen 'View more' | happy | — | **GAP** |
| Message works when the profile is opened from Full Spotlight screen 'View more' | happy | — | **GAP** |
| Love works when the profile is opened from Today rail card | happy | — | **GAP** |
| Message works when the profile is opened from Today rail card | happy | — | **GAP** |
| Love works when the profile is opened from Liked you list (own Love rule = like back) | happy | — | **GAP** |
| Message works when the profile is opened from Liked you list (own Love rule = like back) | happy | — | **GAP** |
| Love works when the profile is opened from Liked profiles list | happy | — | **GAP** |
| Message works when the profile is opened from Liked profiles list | happy | — | **GAP** |
| Love works when the profile is opened from Passed profiles list | happy | — | **GAP** |
| Message works when the profile is opened from Passed profiles list | happy | — | **GAP** |
| Love works when the profile is opened from Web #/likes | happy | — | **GAP** |
| Message works when the profile is opened from Web #/likes | happy | — | **GAP** |
| Full Spotlight screen Like/Pass/Super like call POST /v1/swipe | happy | flutter: `profile_actions_test.dart` › Spotlight screen buttons reach the server > $key saves is_like=$like f | automated |
| Full Spotlight screen Message opens chat or likes+explains | happy | — | **GAP** |
| Liked-you profile Love uses like-back endpoint (override) and returns love | edge | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) > a screen with its own rul | automated |

### Today / Intentional Dating

#### ChemistrySheet — `intentional_dating.connection_card`

Route: embedded / not directly routed · Source: `app/lib/features/intentional_dating/connection_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create your first chapter | button | — | may open ChapterStudioScreen | only checks presence: flutter: `intentional_dating_test.dart` › connection card keeps a way into A little chemistry | presence-only |
| A little chemistry? | button | `qa.connection.chemistry` | opens showChemistrySheet, showModalBottomSheet | flutter: `intentional_dating_test.dart` › connection card keeps a way into A little chemistry<br>playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| A little chemistry? | sheet | — | presents a bottom sheet | playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| Try loading again | button | — | refreshes data | — | **GAP** |
| OutlinedButton onPressed | button | — | refreshes data, updates local state | — | **GAP** |
| OutlinedButton onPressed | button | — | refreshes data, updates local state | — | **GAP** |

#### DatingRhythmScreen — `intentional_dating.dating_rhythm`

Route: embedded / not directly routed · Source: `app/lib/features/intentional_dating/dating_rhythm.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Try again | button | — | refreshes data | — | **GAP** |
| Slow replies this week | toggle | — | updates local state | — | **GAP** |
| FilterChip onSelected | toggle | — | updates local state | — | **GAP** |
| Reload saved choices | button | — | refreshes data | — | **GAP** |
| Save my rhythm | button | `qa.rhythm.save` | calls PUT /v1/account/{userID}/dating-preferences; refreshes data, shows snackbar, updates local state | flutter: `intentional_dating_test.dart` › turning availability off removes selected windows from save<br>flutter: `intentional_dating_test.dart` › a failed rhythm save keeps the member choices<br>+1 more | automated |
| Pause introductions | button | — | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{}; shows snackbar | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| SwitchListTile.adaptive onChanged | toggle | — | updates local state | — | **GAP** |
| FilterChip onSelected | toggle | — | updates local state | — | **GAP** |

#### ProfileStoriesScreen — `intentional_dating.profile_stories`

Route: embedded / not directly routed · Source: `app/lib/features/intentional_dating/profile_stories.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Try again | button | — | refreshes data | — | **GAP** |
| Show these stories on my profile | toggle | `qa.stories.publish` | updates local state | — | **GAP** |
| Preview my stories | button | — | updates local state | — | **GAP** |
| Add a story | button | `qa.stories.add` | updates local state | — | **GAP** |
| Reload saved stories · discard edits | button | — | refreshes data | only checks presence: flutter: `profile_stories_test.dart` › stale saves retain edits and offer explicit reload | presence-only |
| Save privately | button | `qa.stories.save` | calls PUT /v1/profile/{userID}/stories; refreshes data, shows snackbar, updates local state | — | **GAP** |
| Remove story {number} | button | — | updates local state | — | **GAP** |
| A starting point | menu | — | updates local state | — | **GAP** |
| A photo, if you like | menu | — | updates local state | — | **GAP** |
| Describe this photo | field | — | local/unclassified action — callback: (v) => story['photo_description'] = v | — | **GAP** |
| Try loading stories again | button | — | refreshes data | — | **GAP** |

#### ProfileStoryNudge — `intentional_dating.profile_story_nudge`

Route: opened from: today_introductions · Source: `app/lib/features/intentional_dating/profile_story_nudge.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| stories | button | `qa.today.stories` | may open ProfileStoriesScreen; refreshes data | flutter: `profile_story_nudge_test.dart` › the button opens the stories screen | automated |

#### TodayActivities — `intentional_dating.today_activities`

Route: opened from: today_introductions · Source: `app/lib/features/intentional_dating/today_activities.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Book clubs | button | `qa.today.book_clubs` | may open ClubsScreen | — | **GAP** |
| Film clubs | button | `qa.today.film_clubs` | may open ClubsScreen | — | **GAP** |
| Photo Themes | button | `qa.today.photo_themes` | may open PhotoThemesScreen | only checks presence: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale | presence-only |
| First Chapter Studio | button | `qa.today.chapter_studio` | may open ChapterStudioScreen | only checks presence: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale | presence-only |
| SOMETHING TO TALK ABOUT | button | — | may open BlogScreen | — | **GAP** |

#### TodayIntroductions — `intentional_dating.today_introductions`

Route: opened from: home_discovery_screen · Source: `app/lib/features/intentional_dating/today_introductions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Explore more profiles | gesture | `qa.today.screen` | local/unclassified action — callback: refresh ⚠  | — | **GAP** |
| Refresh Today | gesture | — | local/unclassified action — callback: refresh ⚠  | — | **GAP** |
| Set your rhythm | button | `qa.today.rhythm` | may open DatingRhythmScreen | only checks presence: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale | presence-only |
| Take the time you need. | button | — | may open DatingRhythmScreen | only checks presence: flutter: `today_introductions_test.dart` › Pause hides cached introductions | presence-only |
| Your introductions are taking a moment. | button | — | local/unclassified action — callback: refresh ⚠  | only checks presence: flutter: `today_introductions_test.dart` › Failed refresh hides cached profiles and offers retry | presence-only |
| All introductions | toggle | — | updates local state | — | **GAP** |
| All introductions | toggle | `qa.today.activity.*` | updates local state | — | **GAP** |

#### TodayCoverAndWall — `intentional_dating.today_wall`

Route: opened from: today_introductions · Source: `app/lib/features/intentional_dating/today_wall.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| InkWell onTap | button | — | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | — | **GAP** |
| pages | swipe | `qa.today.wall.pages` | updates local state | — | **GAP** |
| Previous pick | button | — | local/unclassified action — callback: page > 0 ? () => _go(page - 1) : null ⚠  | appium: `test_24_today_wall.py` › test_today_wall_matches_api_and_pages | automated |
| Next pick | button | — | local/unclassified action — callback: page < items.length - 1 ? () => _go(page + 1) : null ⚠  | appium: `test_24_today_wall.py` › test_today_wall_matches_api_and_pages | automated |
| Comments | button | `qa.today.wall.chapter.*` | calls POST /v1/walls/views; may open BlogDetailScreen | only checks presence: flutter: `today_wall_test.dart` › Today wall carousel > shows up to ten mixed picks with a position indi | presence-only |
| Write a chapter | button | `qa.today.wall.write` | may open BlogScreen | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `blog-editor.spec.js` › bold, italic and underline then typing lands formatted; writing style  | automated |
| Share a photo | button | `qa.today.wall.share` | may open PhotoThemesScreen | only checks presence: flutter: `today_wall_test.dart` › Today wall carousel > an empty wall invites the member to write or sha | presence-only |

### Today Wall

#### ReactionPicker — `walls.reaction_widgets`

Route: embedded / not directly routed · Source: `app/lib/features/walls/reaction_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Take my reaction back | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| option | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |

### Matches

#### ActivitySessionScreen — `matching.activity_session`

Route: opened from: matches_list_screen · Source: `app/lib/features/matching/screens/activity_session_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Start a new session | button | — | calls POST /v1/activities/sessions/start | — | **GAP** |
| _QuestionCard onSelected | toggle | — | local/unclassified action — callback: (value) => notifier.selectAnswer(question.id, value) | — | **GAP** |
| Submit Responses | button | — | calls POST /v1/activities/sessions/{sessionID}/submit, GET /v1/activities/sessions/{sessionID}/summary | — | **GAP** |
| Time is up — Load Summary | button | — | calls GET /v1/activities/sessions/{sessionID}/summary | — | **GAP** |
| Refresh Summary | button | — | calls GET /v1/activities/sessions/{sessionID}/summary | — | **GAP** |
| Share Result to Chat | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |

#### MatchNotificationScreen — `matching.match_notification`

Route: opened from: home_discovery_screen, liked_me_screen, profile_actions · Source: `app/lib/features/matching/screens/match_notification_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Send Message | button | — | may open ChatScreen | playwright: `chat.spec.js` › conversation redesign at ${width}px<br>appium: `test_13_core_dating_journey.py` › test_username_login_discovery_match_and_chat_restart_resume | automated |
| Keep Swiping | button | — | closes screen/sheet | — | **GAP** |

#### MatchesListScreen — `matching.matches_list`

Route: #/matches (web) / bottom nav: Matches tab (mobile) · Source: `app/lib/features/matching/screens/matches_list_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Messages | button | — | local/unclassified action — callback: () => ref.read(matchesViewProvider.notifier).state = MatchesView.conversations ⚠  | — | **GAP** |
| Call history | button | `qa.calls.history` | may open CallHistoryScreen | — | **GAP** |
| Search your matches | field | `qa.chat.search_conversations` | updates local state | flutter: `chat_redesign_test.dart` › conversation search and unread filter narrow real rows | automated |
| All conversations | toggle | — | updates local state | flutter: `chat_redesign_test.dart` › conversation search and unread filter narrow real rows<br>playwright: `app-member-workspace.spec.js` › matches, conversations and a chat with a real match | automated |
| Unread · {count} | toggle | — | updates local state | flutter: `chat_redesign_test.dart` › conversation search and unread filter narrow real rows | automated |
| Retry | button | — | calls GET /v1/matches/{userID}; refreshes data | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Conversation options for {name} | gesture | `qa.matches.match_row.*` | calls POST /v1/engagement/match-nudges/send, POST /v1/safety/report, DELETE /v1/matches/{matchID}; may open ActivitySessionScreen, CallSessionScreen, Moderation | playwright: `app-member-workspace.spec.js` › matches, conversations and a chat with a real match<br>playwright: `app-member-workspace.spec.js` › WEB-08: a new match can send a first message<br>+3 more | automated |
| Conversation options for {name} | button | `qa.matches.match_row.*` | calls POST /v1/matches/{matchID}/read; may open ChatScreen | playwright: `app-member-workspace.spec.js` › matches, conversations and a chat with a real match<br>playwright: `app-member-workspace.spec.js` › WEB-08: a new match can send a first message<br>+3 more | automated |
| First Chapter | button | `qa.matches.person.*` | may open ChapterStudioScreen | only checks presence: flutter: `chat_redesign_test.dart` › people cards and conversations remain separate choices | presence-only |
| Match options for {name} | button | `qa.matches.person.*` | calls POST /v1/engagement/match-nudges/send, POST /v1/safety/report, DELETE /v1/matches/{matchID}; may open ActivitySessionScreen, CallSessionScreen, Moderation | flutter: `add_friend_match_sheet_test.dart` › the match options sheet sends a friend request from match | automated |
| Plan a date | button | `qa.matches.person.*` | opens showModalBottomSheet, showProposeDatePlanSheet | only checks presence: flutter: `chat_redesign_test.dart` › people cards and conversations remain separate choices | presence-only |
| * tab | toggle | `qa.matches.*_tab` | local/unclassified action — callback: (_) => ref.read(matchesViewProvider.notifier).state = entry.key | flutter: `chat_redesign_test.dart` › conversation search and unread filter narrow real rows<br>flutter: `chat_redesign_test.dart` › people cards and conversations remain separate choices | automated |
| Start call session | button | `qa.matches.call_action` | may open CallSessionScreen; closes screen/sheet | — | **GAP** |
| Start an activity | button | `qa.matches.activity_action` | may open ActivitySessionScreen; closes screen/sheet | — | **GAP** |
| Plan a date | button | `qa.matches.plan_action` | opens showModalBottomSheet, showProposeDatePlanSheet; closes screen/sheet, shows snackbar | — | **GAP** |
| We found each other | button | `qa.matches.graduation_action` | opens showModalBottomSheet, showProposeGraduationSheet; closes screen/sheet, shows snackbar | — | **GAP** |
| Send a nudge | button | `qa.matches.nudge_action` | calls POST /v1/engagement/match-nudges/send; closes screen/sheet, shows snackbar | — | **GAP** |
| Close conversation | button | `qa.matches.unmatch_action` | calls DELETE /v1/matches/{matchID}; opens showDialog; closes screen/sheet, pops a result to caller | — | **GAP** |
| Close this conversation? | sheet | `qa.matches.unmatch_action` | presents a dialog/picker | — | **GAP** |
| Keep talking | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Close conversation | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report | button | `qa.matches.report_action` | calls POST /v1/safety/report; may open ModerationAppealsScreen; opens showModalBottomSheet, showReportUserSheet; closes screen/sheet, shows snackbar | — | **GAP** |
| Submit report | button | — | calls POST /v1/safety/report | — | **GAP** |
| Appeal | button | — | may open ModerationAppealsScreen | — | **GAP** |

#### MatchOverviewCard — `matching.match_overview_card`

Route: opened from: matches_list_screen · Source: `app/lib/features/matching/widgets/match_overview_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Open chat | button | — | local/unclassified action — callback: onChat ⚠  | only checks presence: flutter: `matches_l10n_de_test.dart` › English text is unchanged | presence-only |

### Chat (dating)

#### ChatScreen — `messaging.chat`

Route: opened from: match_notification_screen, matches_list_screen, plans_screen, profile_actions · Source: `app/lib/features/messaging/screens/chat_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| All conversations | button | — | may open MainNavigationScreen; closes screen/sheet | flutter: `chat_redesign_test.dart` › conversation search and unread filter narrow real rows<br>playwright: `app-member-workspace.spec.js` › matches, conversations and a chat with a real match | automated |
| Find the words | button | — | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | — | **GAP** |
| Send a little joy | button | — | calls POST /v1/chat/{matchID}/gifts/events; updates local state | — | **GAP** |
| Back to conversations | button | — | may open MainNavigationScreen; closes screen/sheet | — | **GAP** |
| $walletCoins | button | — | calls GET /v1/chat/gifts, GET /v1/wallet/{userID}/coins; may open WalletPaymentScreen | — | **GAP** |
| Share a voice hello · read & listen | button | — | may open VoiceIcebreakersScreen | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| ChatWelcome onStarter | button | — | local/unclassified action — callback: canCompose ? (text) { _messageController .text = text; _messageController .selection = Tex ⚠  | — | **GAP** |
| Long-press message | gesture | `qa.chat.message.*` | calls DELETE /v1/chat/{matchID}/messages/{messageID}, POST /v1/chat/{}/messages/{}/gift/{}; opens showModalBottomSheet; closes screen/sheet, pops a result to ca | only checks presence: playwright: `chat.spec.js` › conversation redesign at ${width}px | presence-only |
| More (icon more_horiz_rounded) | button | `qa.chat.gift_receiver_actions` | calls POST /v1/chat/{}/messages/{}/gift/{}; opens showModalBottomSheet; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `chat_screen_smoke_test.dart` › received gift offers hide and report controls<br>flutter: `message_bubble_test.dart` › MessageBubble > labels a received gift and exposes receiver controls | automated |
| See plans | button | — | may open SubscriptionScreen | — | **GAP** |
| Conversation paused | field | `qa.chat.composer` | local/unclassified action — callback: (value) => ref .read( messageNotifierProvider( widget.matchId, ).notifier, ) .setTyping(is | flutter: `chat_redesign_test.dart` › large text and keyboard leave the composer usable<br>flutter: `chat_redesign_test.dart` › a newer draft survives completion of an earlier send<br>+5 more | automated |
| Help me say it | button | `qa.chat.copilot_button` | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | — | **GAP** |
| Add an emoji | button | — | opens showModalBottomSheet; closes screen/sheet | — | **GAP** |
| Send a gift | button | `qa.chat.gift_tray_button` | calls POST /v1/chat/{matchID}/gifts/events; updates local state | flutter: `chat_redesign_test.dart` › chat fits ${size.width} in ${preset.id}<br>flutter: `chat_redesign_test.dart` › focusing the composer closes the gift panel<br>+1 more | automated |
| Send message | button | `qa.chat.send_button` | calls POST /v1/chat/{matchID}/messages, GET /v1/chat/{matchID}/messages, GET /v1/matches/{matchID}/unlock-state, POST /v1/matches/{matchID}/read; refreshes data | flutter: `chat_redesign_test.dart` › a newer draft survives completion of an earlier send<br>playwright: `chat.spec.js` › conversation redesign at ${width}px<br>+3 more | automated |
| Close gifts | button | — | calls POST /v1/chat/{matchID}/gifts/events; updates local state | appium: `test_08_chat_gifts_locks.py` › test_chat_gift_tray_or_locked_banner_sample | automated |
| All gifts | toggle | — | updates local state | — | **GAP** |
| {count, plural, =1{1 coin} other{{count} coins}} | button | `qa.chat.gift_item.*` | calls GET /v1/chat/gifts, GET /v1/wallet/{userID}/coins, POST /v1/chat/{matchID}/gifts/send, GET /v1/chat/{matchID}/messages; may open WalletPaymentScreen; open | — | **GAP** |
| Not now | sheet | — | presents a bottom sheet | — | **GAP** |
| Send for {price} | button | `qa.chat.gift_confirm.send` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Not now | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Delete (icon delete_outline) | sheet | — | presents a bottom sheet | — | **GAP** |
| Delete (icon delete_outline) | button | `qa.chat.delete_message_action` | closes screen/sheet, pops a result to caller | — | **GAP** |
| TextButton onPressed | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| SnackBarAction onPressed | button | — | shows snackbar | — | **GAP** |
| Hide (icon visibility_off_outlined) | sheet | — | presents a bottom sheet | — | **GAP** |
| Hide (icon visibility_off_outlined) | button | `qa.chat.gift_hide` | closes screen/sheet, pops a result to caller | flutter: `chat_screen_smoke_test.dart` › received gift offers hide and report controls | automated |
| Report (icon flag_outlined) | button | `qa.chat.gift_report` | closes screen/sheet, pops a result to caller | — | **GAP** |
| TextButton onPressed | button | — | closes screen/sheet | — | **GAP** |
| gift report reason | menu | `qa.chat.gift_report_reason` | local/unclassified action — callback: (value) { if (value != null) { setSheetState(() => selectedReason = value); } } | — | **GAP** |
| gift report details | field | `qa.chat.gift_report_details` | local/unclassified action — callback: (value) => details = value | — | **GAP** |
| Submit report (icon shield_outlined) | button | `qa.chat.gift_report_submit` | closes screen/sheet, pops a result to caller | — | **GAP** |
| TextButton onPressed | button | — | closes screen/sheet | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| GestureDetector onTap | button | — | closes screen/sheet | — | **GAP** |

#### CopilotSheet — `messaging.copilot_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/messaging/widgets/copilot_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| kind | toggle | `qa.copilot.kind.*` | updates local state | — | **GAP** |
| tone | toggle | `qa.copilot.tone.*` | updates local state | flutter: `copilot_sheet_test.dart` › drafts in the chosen kind and tone and hands back the draft | automated |
| Try another | button | `qa.copilot.generate` | calls POST /v1/matches/{matchID}/copilot/draft; updates local state | flutter: `copilot_sheet_test.dart` › drafts in the chosen kind and tone and hands back the draft | automated |
| Use and edit | button | `qa.copilot.use` | calls POST /v1/matches/{matchID}/copilot/draft; closes screen/sheet, pops a result to caller | flutter: `copilot_sheet_test.dart` › drafts in the chosen kind and tone and hands back the draft | automated |

### Profile

#### EditProfileScreen — `profile.edit_profile`

Route: opened from: main_navigation_screen, profile_view_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/edit_profile_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Refresh profile | button | — | refreshes data | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile | automated |
| Retry | button | — | refreshes data | — | **GAP** |
| About you | button | — | may open SetupAboutScreen | appium: `test_02_edit_profile.py` › test_edit_profile_bio_save_persists_after_reopen<br>appium: `test_02_edit_profile.py` › test_edit_profile_invalid_bio_is_blocked | automated |
| Location & social | button | — | may open SetupPreferencesScreen | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Dating preferences | button | — | may open SetupPreferencesScreen | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile<br>appium: `test_03b_filter_preference_seeding.py` › test_filter_sheet_shows_a_readable_value_for_every_slider | automated |
| Lifestyle | button | — | may open SetupPreferencesScreen | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile<br>appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save | automated |
| Interests & details | button | — | may open SetupPreferencesScreen | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Photo gallery | button | — | may open SetupPhotosScreen | — | **GAP** |

#### ProfileViewScreen — `profile.profile_view`

Route: #/profile (web) / bottom nav: Profile tab (mobile) · Source: `app/lib/features/profile/screens/profile_view_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Starring | button | — | may open ProfileGalleryScreen | only checks presence: flutter: `profile_view_cinematic_test.dart` › returning to the Profile tab starts at the top | presence-only |
| {name}, photo {index} of {count} | button | — | may open ProfileGalleryScreen | — | **GAP** |
| Retry | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; refreshes data | — | **GAP** |
| You liked | button | — | may open LikedProfilesScreen | — | **GAP** |
| Matches | button | — | local/unclassified action — callback: () => _openMatchesTab(MatchesView.people) ⚠  | flutter: `profile_view_stat_tiles_test.dart` › Matches tile opens the Matches tab on Your matches | automated |
| Messages | button | — | local/unclassified action — callback: () => _openMatchesTab( MatchesView.conversations, ) ⚠  | flutter: `profile_view_stat_tiles_test.dart` › Messages tile opens the Matches tab on Conversations | automated |
| Who Liked Me | button | `qa.profile.who_liked_me` | may open LikedMeScreen | appium: `test_27_profile_showcase.py` › test_counterpart_writing_shows_only_with_their_consent | automated |
| Who Viewed My Profile | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; may open ProfileViewersScreen; refreshes data | — | **GAP** |
| Who viewed my profile | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; may open ProfileViewersScreen; refreshes data | — | **GAP** |
| Refresh profile | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; refreshes data | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile | automated |
| OutlinedButton.icon onPressed | button | — | local/unclassified action — callback: onTap ⚠  | — | **GAP** |

#### ProfileViewersScreen — `profile.profile_viewers`

Route: opened from: profile_view_screen · Source: `app/lib/features/profile/screens/profile_viewers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |

#### ProfileSetupEntryScreen — `profile.profile_setup_entry`

Route: opened from: main · Source: `app/lib/features/profile/screens/setup/profile_setup_entry_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |

#### SetupAboutScreen — `profile.setup_about`

Route: opened from: edit_profile_screen, profile_setup_entry_screen, setup_photos_screen · Source: `app/lib/features/profile/screens/setup/setup_about_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back | button | — | closes screen/sheet | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| Select | menu | `qa.setup.about.drinking_dropdown` | updates local state | — | **GAP** |
| Select education | menu | `qa.setup.about.education_dropdown` | updates local state | — | **GAP** |
| Select height | menu | `qa.setup.about.height_dropdown` | updates local state | — | **GAP** |
| Prefer not to say | menu | — | updates local state | — | **GAP** |
| Prefer not to say | menu | — | updates local state | — | **GAP** |
| Save About | button | — | calls PATCH /v1/profile/{userID}/draft; may open SetupPreviewScreen; closes screen/sheet, shows snackbar, updates local state | appium: `test_02_edit_profile.py` › test_edit_profile_bio_save_persists_after_reopen<br>appium: `test_02_edit_profile.py` › test_edit_profile_invalid_bio_is_blocked | automated |
| Select | menu | `qa.setup.about.smoking_dropdown` | updates local state | — | **GAP** |
| {min, plural, =1{Tell people about you (min 1 char)} other{T | field | `qa.setup.about.bio_field` | opens TextField | appium: `test_02_edit_profile.py` › test_edit_profile_bio_save_persists_after_reopen<br>appium: `test_02_edit_profile.py` › test_edit_profile_invalid_bio_is_blocked | automated |
| e.g. Software Engineer | field | `qa.setup.about.profession_field` | opens TextField | — | **GAP** |

#### SetupPhotosScreen — `profile.setup_photos`

Route: opened from: edit_profile_screen, profile_setup_entry_screen, profile_view_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/setup/setup_photos_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Remove this photo? | sheet | — | presents a dialog/picker | only checks presence: flutter: `profile_setup_notifier_test.dart` › Photo deletion confirmation > does not delete until the confirmation a | presence-only |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Remove | button | `qa.setup.photos.confirm_delete` | closes screen/sheet, pops a result to caller | flutter: `profile_setup_notifier_test.dart` › Photo deletion confirmation > does not delete until the confirmation a | automated |
| Back | button | — | closes screen/sheet | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| Remove photo | button | `qa.setup.photos.delete_*` | calls DELETE /v1/profile/{userID}/photos/{photoID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `profile_setup_notifier_test.dart` › Photo deletion confirmation > does not delete until the confirmation a | automated |
| Save Photos | button | `qa.setup.photos.next_button` | may open SetupAboutScreen; closes screen/sheet, shows snackbar | appium: `test_03_profile_setup_flow.py` › test_profile_setup_zero_photos_blocks_preferences<br>appium: `test_03_profile_setup_flow.py` › test_profile_setup_uploads_gallery_photos_and_continues | automated |
| Camera | button | `qa.setup.photos.*_button` | calls POST /v1/profile/{userID}/photos; opens photo/file picker, shows snackbar, updates local state | playwright: `photo-upload.spec.js` › browser upload, reload and onboarding completion preserve the auth gat<br>appium: `test_03_profile_setup_flow.py` › test_profile_setup_zero_photos_blocks_preferences<br>+1 more | automated |
| Gallery | button | `qa.setup.photos.*_button` | calls POST /v1/profile/{userID}/photos; opens photo/file picker, shows snackbar, updates local state | playwright: `photo-upload.spec.js` › browser upload, reload and onboarding completion preserve the auth gat<br>appium: `test_03_profile_setup_flow.py` › test_profile_setup_zero_photos_blocks_preferences<br>+1 more | automated |
| {min, plural, =1{Please upload at least 1 photo to continue. | gesture | — | calls POST /v1/profile/{userID}/photos/reorder; shows snackbar | — | **GAP** |
| Set as profile picture | button | — | calls POST /v1/profile/{userID}/photos/reorder; shows snackbar | — | **GAP** |

#### SetupPreferencesScreen — `profile.setup_preferences`

Route: opened from: edit_profile_screen, main_navigation_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/setup/setup_preferences_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |
| arrow back ios new (icon arrow_back_ios_new) | button | — | calls PATCH /v1/profile/{userID}/draft; closes screen/sheet, shows snackbar, updates local state | flutter: `setup_preferences_screen_test.dart` › QA setup Back keeps edits on screen when save fails | automated |
| _BasicTab onAgeChanged | toggle | — | updates local state | — | **GAP** |
| {km} km | toggle | — | updates local state | — | **GAP** |
| Hookups only | toggle | `qa.setup.preferences.hookup_only_toggle` | updates local state | — | **GAP** |
| Men | button | — | updates local state | flutter: `setup_preferences_screen_test.dart` › QA empty seeking selection prevents save | automated |
| Serious relationship only | toggle | `qa.setup.preferences.serious_only_toggle` | updates local state | — | **GAP** |
| Verified profiles only | toggle | `qa.setup.preferences.verified_only_toggle` | updates local state | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| City | menu | — | updates local state | — | **GAP** |
| Country | menu | — | updates local state | — | **GAP** |
| Diet preference | menu | — | updates local state | — | **GAP** |
| Diet type | menu | — | updates local state | — | **GAP** |
| Language | menu | — | updates local state | — | **GAP** |
| Mother tongue | menu | — | updates local state | — | **GAP** |
| Political comfort range | menu | — | updates local state | — | **GAP** |
| Religion preference | menu | — | updates local state | — | **GAP** |
| Sleep schedule | menu | — | updates local state | — | **GAP** |
| State / Region | menu | — | updates local state | — | **GAP** |
| Travel style | menu | — | updates local state | — | **GAP** |
| Workout frequency | menu | — | updates local state | — | **GAP** |
| Save Preferences | button | — | calls POST /v1/profile/{userID}/complete, PATCH /v1/profile/{userID}/draft; may open MainNavigationScreen; closes screen/sheet, refreshes data, shows snackbar,  | flutter: `setup_preferences_screen_test.dart` › QA empty seeking selection prevents save<br>flutter: `setup_preferences_screen_test.dart` › QA changing country visibly clears saved state and city<br>+4 more | automated |
| Basic | menu | — | local/unclassified action — callback:  | flutter: `setup_preferences_screen_test.dart` › QA empty seeking selection prevents save<br>flutter: `setup_preferences_screen_test.dart` › QA out-of-range saved sliders are bounded safely<br>+3 more | automated |
| Instagram handle (without @) | field | — | opens TextField | — | **GAP** |
| Intent tags (long-term, marriage, casual…) | field | — | opens TextField | — | **GAP** |
| Hobbies (comma-separated) | field | — | opens TextField | — | **GAP** |
| Favourite books (comma-separated) | field | — | opens TextField | — | **GAP** |
| Favourite novels (comma-separated) | field | — | opens TextField | — | **GAP** |
| Favourite songs (comma-separated) | field | — | opens TextField | — | **GAP** |
| Extra-curricular activities (comma-separated) | field | — | opens TextField | — | **GAP** |
| Additional information | field | — | opens TextField | — | **GAP** |
| Pet preference | field | — | opens TextField | — | **GAP** |
| Tags (comma-separated) | field | — | opens TextField | — | **GAP** |

#### SetupPreviewScreen — `profile.setup_preview`

Route: opened from: profile_setup_entry_screen, setup_about_screen · Source: `app/lib/features/profile/screens/setup/setup_preview_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back | button | — | closes screen/sheet | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| Complete Profile | button | `qa.setup.preview.complete_button` | calls POST /v1/profile/{userID}/complete; may open MainNavigationScreen; refreshes data, shows snackbar, updates local state | flutter: `setup_preview_screen_test.dart` › SetupPreviewScreen > shows validation snackbar when draft is incomplet<br>flutter: `setup_preview_screen_test.dart` › SetupPreviewScreen > shows API error snackbar on backend failure<br>+1 more | automated |
| _PreviewBody onPageChanged | swipe | — | updates local state | — | **GAP** |

#### ProfileGalleryScreen — `profile.cinematic_profile`

Route: embedded / not directly routed · Source: `app/lib/features/profile/widgets/cinematic_profile.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| view full screen | swipe | — | updates local state | — | **GAP** |
| {name}, photo {index} of {count} | swipe | `qa.profile.gallery` | updates local state | flutter: `profile_details_cinematic_test.dart` › tapping a photo opens the full-screen gallery | automated |
| Close photos | button | `qa.profile.gallery.close` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `profile_details_cinematic_test.dart` › tapping a photo opens the full-screen gallery | automated |

#### ProfileScenes — `profile.profile_scenes`

Route: opened from: profile_details_screen, profile_view_screen · Source: `app/lib/features/profile/widgets/profile_scenes.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Read more | button | — | updates local state | only checks presence: flutter: `profile_details_cinematic_test.dart` › keeps every automation handle the QA suites rely on | presence-only |

#### ShowcaseChapter — `profile.profile_showcase`

Route: embedded / not directly routed · Source: `app/lib/features/profile/widgets/profile_showcase.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| ThemeEntryTile onTap | button | — | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | — | **GAP** |
| Read all their chapters | button | `qa.profile.showcase.read_all` | may open BlogScreen | playwright: `profile-showcase.spec.js` › showcase consent gates "Writing & moments" for other members | automated |
| favorite border rounded (icon favorite_border_rounded) | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | — | **GAP** |
| Only you can see this | toggle | `qa.profile.showcase.consent` | calls PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | flutter: `profile_showcase_test.dart` › the owner previews it privately and can turn it on<br>playwright: `profile-showcase.spec.js` › showcase consent gates "Writing & moments" for other members | automated |

### Verification

#### VerificationLandingScreen — `verification.verification_landing`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/verification/screens/verification_landing_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| View review status | button | — | may open VerificationStatusScreen | — | **GAP** |
| Start secure verification | button | `qa.verification.landing.start_button` | may open VerificationUploadIdScreen | — | **GAP** |

#### VerificationSelfieScreen — `verification.verification_selfie`

Route: opened from: verification_upload_id_screen · Source: `app/lib/features/verification/screens/verification_selfie_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Gallery | button | `qa.verification.selfie.gallery_button` | opens photo/file picker, updates local state | — | **GAP** |
| Camera | button | — | opens photo/file picker, updates local state | — | **GAP** |
| Submit | button | `qa.verification.selfie.submit_button` | calls POST /v1/verification/{userID}/submit; may open VerificationStatusScreen | appium: `test_12_verification_safety.py` › test_verification_selfie_from_gallery_submit_reaches_status | automated |

#### VerificationStatusScreen — `verification.verification_status`

Route: opened from: verification_landing_screen, verification_selfie_screen · Source: `app/lib/features/verification/screens/verification_status_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |

#### VerificationUploadIdScreen — `verification.verification_upload_id`

Route: opened from: main_navigation_screen, settings_screen, verification_landing_screen · Source: `app/lib/features/verification/screens/verification_upload_id_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Gallery | button | `qa.verification.id.gallery_button` | opens photo/file picker, updates local state | — | **GAP** |
| Camera | button | — | opens photo/file picker, updates local state | — | **GAP** |
| Next | button | `qa.verification.id.next_button` | may open VerificationSelfieScreen | appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>appium: `test_12_verification_safety.py` › test_verification_selfie_from_gallery_submit_reaches_status | automated |

### Payments & Membership

#### CheckoutWaitingSheet — `payment.checkout_waiting_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/payment/screens/checkout_waiting_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to account | sheet | — | presents a bottom sheet | — | **GAP** |
| Check confirmation | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Back to account | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### CheckoutWebViewScreen — `payment.checkout_webview`

Route: embedded / not directly routed · Source: `app/lib/features/payment/screens/checkout_webview_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Close checkout | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |

#### SubscriptionScreen — `payment.subscription`

Route: opened from: chat_screen, home_discovery_screen, liked_me_screen, profile_actions, settings_screen, web_member_workspace · Source: `app/lib/features/payment/screens/subscription_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Your plan renews automatically at the end of each billing pe | gesture | — | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account | only checks presence: flutter: `membership_l10n_de_test.dart` › membership screen renders in German | presence-only |
| Check status | button | — | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account; shows snackbar, updates local st | — | **GAP** |
| Resume checkout | button | — | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account; shows snackbar, updates local st | — | **GAP** |
| Auto-renew | toggle | — | calls POST /v1/billing/subscription/{}/${enabled ; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | only checks presence: flutter: `membership_l10n_de_test.dart` › membership screen renders in German | presence-only |
| Update card | button | — | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; shows snackbar | only checks presence: flutter: `subscription_screen_test.dart` › paid member sees card, renewal date and the auto-renew switch | presence-only |
| Monthly | button | — | updates local state | — | **GAP** |
| Subscribe with card | button | — | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; opens showDialog, showModa | only checks presence: flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons | presence-only |
| Subscribe with card | button | — | calls POST /v1/billing/subscription/{userID}/change-plan, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}; opens | only checks presence: flutter: `subscription_screen_test.dart` › free member sees the catalog with card subscribe buttons | presence-only |
| _SandboxControls onEvent | button | — | calls POST /v1/billing/sandbox/subscriptions/{userID}/simulate | — | **GAP** |
| Switch plan | sheet | — | presents a dialog/picker | — | **GAP** |
| Not now | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Switch plan | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Turn off | sheet | — | presents a dialog/picker | — | **GAP** |
| Keep renewing | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Turn off | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Subscribe to {plan} | sheet | — | presents a dialog/picker | — | **GAP** |
| Not now | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Continue to card | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Start exploring | sheet | — | presents a bottom sheet | — | **GAP** |
| Start exploring | button | — | closes screen/sheet | — | **GAP** |

#### WalletPaymentScreen — `payment.wallet_payment`

Route: opened from: chat_screen · Source: `app/lib/features/payment/screens/wallet_payment_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Coins are used for gifts and boosts inside Connect. Purchase | gesture | — | local/unclassified action — callback: ref.read(_wallet.notifier).load ⚠  | only checks presence: flutter: `wallet_payment_screen_test.dart` › wallet shows the settled balance, packs and history | presence-only |
| Opening… | button | — | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; shows snackbar | — | **GAP** |

### Friends & Introducer

#### AddFriendButton — `friends.friend_actions`

Route: opened from: friends_screen, group_detail_screen, matches_list_screen, profile_details_screen, room_chat · Source: `app/lib/features/friends/friend_actions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Cancel request | sheet | — | presents a dialog/picker | — | **GAP** |
| Keep it | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Cancel request | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| IconButton onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | — | **GAP** |
| ListTile onTap | button | — | local/unclassified action — callback: onPressed ⚠  | — | **GAP** |
| OutlinedButton.icon onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | — | **GAP** |
| FilledButton.tonalIcon onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | — | **GAP** |

#### FriendsScreen — `friends.friends`

Route: opened from: engagement_hub_screen, main_navigation_screen, notification_inbox_screen, settings_screen, web_member_workspace · Source: `app/lib/features/friends/screens/friends_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| With your friends | gesture | — | local/unclassified action — callback: refresh ⚠  | playwright: `app-member-workspace.spec.js` › WEB-09: phone Back arrow returns to the previous page<br>playwright: `app-member-workspace.spec.js` › phone: a screen opened from Settings goes back to Settings<br>+8 more | automated |
| Back | button | — | closes screen/sheet | — | **GAP** |
| Add friend | button | `qa.friends.add` | opens showAddFriendSheet, showModalBottomSheet | flutter: `friends_screen_test.dart` › Add friend searches by name and sends a request<br>appium: `test_19_friends.py` › test_friend_search_sends_request_to_counterpart<br>+1 more | automated |
| Create a group | button | `qa.friends.create_group` | local/unclassified action — callback: accepted.isEmpty ? null : () => _createGroup(context, accepted) ⚠  | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups<br>appium: `test_21_lifestyle_groups.py` › test_create_group_from_friends_invite_chat_and_leave | automated |
| Accept | button | `qa.friends.accept.*` | calls POST /v1/friends/{userID}/{friendUserID}/decision, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| Decline | button | `qa.friends.decline.*` | calls POST /v1/friends/{userID}/{friendUserID}/decision, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API | automated |
| Cancel | button | `qa.friends.cancel.*` | calls DELETE /v1/friends/{userID}/{friendUserID}, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API | automated |
| Friend | button | `qa.friends.chat.*` | may open SocialChatScreen; refreshes data | — | **GAP** |
| No thanks | button | `qa.friends.intro_decline.*` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | — | **GAP** |
| Keep private | button | `qa.friends.vouch_hide.*` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | — | **GAP** |
| Introduce | button | `qa.friends.intro_action` | opens showIntroSheet, showModalBottomSheet; shows snackbar | flutter: `friend_social_test.dart` › the intro sheet needs two different friends | automated |
| More for {name} | menu | `qa.friends.menu.*` | calls DELETE /v1/friends/{userID}/{friendUserID}, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities, POST /v1/safety/block; opens showDialog, showIn | appium: `test_19_friends.py` › test_remove_friend_from_menu | automated |
| Message {name} | button | `qa.friends.message.*` | calls POST /v1/social/friends/{friendID}/channel; may open SocialChatScreen; refreshes data, shows snackbar | flutter: `friends_screen_test.dart` › Message opens the friend chat<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| Hide from profile | button | — | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | — | **GAP** |
| Date plans shared with you | button | `qa.friends.plans_link` | may open PlansScreen | — | **GAP** |
| Invite a friend who isn’t dating | button | — | may open IntroducerScreen | — | **GAP** |
| Introductions, on your terms | button | — | may open DatingRhythmScreen | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Name or @username | field | `qa.friends.search_field` | updates local state | flutter: `friends_screen_test.dart` › Add friend searches by name and sends a request | automated |
| Name or @username | field | `qa.friends.search_field` | updates local state | flutter: `friends_screen_test.dart` › Add friend searches by name and sends a request | automated |
| @${f.username} | toggle | `qa.friends.group_pick.*` | updates local state | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups | automated |
| Create a group with {count} | button | `qa.friends.group_continue` | closes screen/sheet, pops a result to caller | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups<br>appium: `test_21_lifestyle_groups.py` › test_create_group_from_friends_invite_chat_and_leave | automated |

#### IntroducerScreen — `friends.introducer`

Route: opened from: friends_screen, main · Source: `app/lib/features/friends/screens/introducer_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Remove permission for {name}? | sheet | — | presents a dialog/picker | flutter: `introducer_test.dart` › removing permission requires the clear in-app choice | automated |
| Keep permission | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Remove permission | button | — | closes screen/sheet, pops a result to caller | flutter: `introducer_test.dart` › removing permission requires the clear in-app choice | automated |
| Refresh permissions | button | — | refreshes data | — | **GAP** |
| Account | menu | — | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open AccountDataScreen | playwright: `photo-upload.spec.js` › browser upload, reload and onboarding completion preserve the auth gat<br>playwright: `website.spec.js` › browser login, live stream, deep links, preferences and reload recover | automated |
| Try again | button | — | refreshes data | only checks presence: flutter: `introducer_test.dart` › offline consent load gives retry and no composer | presence-only |
| Allow introductions | button | — | calls POST /v1/introducer/connections/{consentID}/approve; refreshes data, updates local state | flutter: `introducer_test.dart` › member can approve a named request with explicit disclosure | automated |
| Decline request | button | — | calls DELETE /v1/introducer/connections/{consentID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Reload sent introductions | button | — | refreshes data | — | **GAP** |
| Include my profile photo | toggle | — | updates local state | — | **GAP** |
| Include my city | toggle | — | updates local state | — | **GAP** |
| Create invitation code | button | — | calls POST /v1/introducer/invites; refreshes data, updates local state | flutter: `introducer_test.dart` › invitation preview defaults to no photo and no city | automated |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Copy code | button | — | copies to clipboard, shows snackbar | — | **GAP** |
| Cancel unused invitations | button | — | calls DELETE /v1/introducer/invites; refreshes data, updates local state | — | **GAP** |
| Manage all introduction preferences | button | — | may open DatingRhythmScreen; refreshes data | — | **GAP** |
| Invitation code | field | — | opens TextField | — | **GAP** |
| Ask for permission | button | — | calls POST /v1/introducer/redeem; refreshes data, updates local state | — | **GAP** |
| First friend | menu | — | updates local state | — | **GAP** |
| Second friend | menu | — | updates local state | — | **GAP** |
| Why you thought of them (optional) | field | — | opens TextField | — | **GAP** |
| Suggest an introduction | button | — | calls POST /v1/friends/{userID}/intros; refreshes data, updates local state | only checks presence: flutter: `introducer_test.dart` › friend workspace only fetches consent and private receipts | presence-only |

#### FriendSocialSheets — `friends.friend_social_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/friends/widgets/friend_social_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Your vouch | field | `qa.friends.vouch_text` | opens TextField | — | **GAP** |
| Send vouch | button | `qa.friends.vouch_submit` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities; closes screen/sheet, pop | — | **GAP** |
| First friend | toggle | `qa.friends.intro_first` | updates local state | — | **GAP** |
| Second friend | toggle | `qa.friends.intro_second` | updates local state | — | **GAP** |
| Why they should meet (optional) | field | `qa.friends.intro_message` | opens TextField | — | **GAP** |
| Make the intro | button | `qa.friends.intro_submit` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities; closes screen/sheet, pop | flutter: `friend_social_test.dart` › the intro sheet needs two different friends | automated |

### Social Chat (friends/rooms/groups)

#### SocialChatScreen — `social_chat.social_chat`

Route: embedded / not directly routed · Source: `app/lib/features/social_chat/social_chat_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| This member | sheet | — | presents a bottom sheet | — | **GAP** |
| Try sending again | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Copy text | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Remove message | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report message | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| This member | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Mute notifications | button | — | calls DELETE /v1/social/channels/{channelID}/mute, PUT /v1/social/channels/{channelID}/mute, DELETE /v1/social/channels/{channelID}/messages/{messageID}; opens  | flutter: `chat_mutes_test.dart` › the bell mutes a friend chat’s notifications and turns them<br>flutter: `chat_mutes_test.dart` › the chat and the mute sheet speak German<br>+1 more | automated |
| This conversation is unavailable. You may no longer be a mem | button | — | refreshes data | — | **GAP** |
| Long-press message | gesture | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; closes screen/sheet, copies to clipboard, pops a result to call | — | **GAP** |
| Until I turn it back on | sheet | — | presents a bottom sheet | appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| notifications paused outlined (icon notifications_paused_out | button | — | closes screen/sheet, pops a result to caller | flutter: `chat_mutes_test.dart` › the bell mutes a friend chat’s notifications and turns them | automated |
| Turn notifications back on | button | — | closes screen/sheet, pops a result to caller | flutter: `chat_mutes_test.dart` › the bell mutes a friend chat’s notifications and turns them<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |

### Groups

#### CreateGroupScreen — `groups.create_group`

Route: opened from: group_launch · Source: `app/lib/features/groups/create_group_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Community group | button | — | updates local state | — | **GAP** |
| Private group | button | — | updates local state | — | **GAP** |
| Lifestyles could not load | button | — | refreshes data | — | **GAP** |
| ${c.emoji}  ${c.title} | toggle | — | updates local state | — | **GAP** |
| The Sunday brunch crew | field | — | opens TextField | flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group<br>flutter: `groups_test.dart` › create flow starts private with the preselected friends<br>+1 more | automated |
| What is it about? (optional) | field | — | opens TextField | — | **GAP** |
| City (optional) | field | — | opens TextField | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Cover emoji {emoji} | button | — | updates local state | — | **GAP** |
| Change photo | button | — | opens showGroupSheet, showModalBottomSheet; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group | automated |
| Remove photo | button | — | updates local state | — | **GAP** |
| Friend | toggle | — | updates local state | — | **GAP** |
| Change friends | button | — | updates local state | — | **GAP** |
| Create group | button | — | calls PUT /v1/engagement/groups/{groupID}/cover; may open GroupDetailScreen; shows snackbar, updates local state | flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group<br>flutter: `groups_test.dart` › create flow starts private with the preselected friends<br>+2 more | automated |

#### GroupFriendPicker — `groups.friend_picker`

Route: embedded / not directly routed · Source: `app/lib/features/groups/friend_picker.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| $confirmLabel (${chosen.length}) | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Search friends | field | — | updates local state | — | **GAP** |
| Friends could not load | button | — | refreshes data | — | **GAP** |
| Friend | toggle | — | updates local state | only checks presence: flutter: `groups_test.dart` › the invite picker sends invitations to chosen friends only | presence-only |

#### GroupCoverPreview — `groups.group_cover_picker`

Route: opened from: create_group_screen · Source: `app/lib/features/groups/group_cover_picker.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Choose from your photos | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `group_covers_test.dart` › the owner picks, previews and uploads a cover | automated |
| Take a photo | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group | automated |
| Cancel | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |
| Use this photo | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `group_covers_test.dart` › the owner picks, previews and uploads a cover<br>flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group | automated |

#### GroupDetailScreen — `groups.group_detail`

Route: opened from: create_group_screen, group_launch, groups_screen · Source: `app/lib/features/groups/group_detail_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| $kind · ${group.memberLabel(l10n)} | button | — | opens showGroupSheet, showModalBottomSheet | — | **GAP** |
| Invitation declined. | gesture | — | refreshes data | flutter: `groups_test.dart` › owners get owner tools instead of Report<br>flutter: `groups_test.dart` › members of a removed group see the notice and no chat | automated |
| Owner tools | menu | — | calls PUT /v1/engagement/groups/{groupID}/cover; opens showDialog, showGroupSheet, showModalBottomSheet; closes screen/sheet, pops a result to caller, shows sna | flutter: `groups_test.dart` › owners get owner tools instead of Report<br>flutter: `groups_test.dart` › members of a removed group see the notice and no chat | automated |
| More options | menu | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `groups_test.dart` › a member who does not run the group can report it<br>appium: `test_21_lifestyle_groups.py` › test_accept_invitation_and_report_group | automated |
| This group is unavailable | button | — | refreshes data | — | **GAP** |
| Leave | button | — | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `groups_test.dart` › leave warns from the current member count, not the loaded one<br>appium: `test_21_lifestyle_groups.py` › test_create_group_from_friends_invite_chat_and_leave<br>+1 more | automated |
| Remove cover | button | — | opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `group_covers_test.dart` › the owner removes the cover after confirming | automated |
| Decline | button | — | calls POST /v1/engagement/groups/{groupID}/invites/respond; shows snackbar, updates local state | — | **GAP** |
| Add cover photo | button | — | local/unclassified action — callback: busy ? null : onChangeCover ⚠  | flutter: `group_covers_test.dart` › the owner picks, previews and uploads a cover | automated |
| Members | button | — | local/unclassified action — callback: busy ? null : onMembers ⚠  | — | **GAP** |
| Group chat | button | — | local/unclassified action — callback: busy \|\| group.channelId.isEmpty ? null : onChat ⚠  | flutter: `groups_test.dart` › a member opens the group chat from the detail screen<br>appium: `test_21_lifestyle_groups.py` › test_create_group_from_friends_invite_chat_and_leave | automated |
| Invite friends | button | — | local/unclassified action — callback: busy ? null : onInvite ⚠  | flutter: `groups_test.dart` › the invite picker sends invitations to chosen friends only<br>appium: `test_21_lifestyle_groups.py` › test_create_group_from_friends_invite_chat_and_leave | automated |
| Members | button | — | local/unclassified action — callback: busy ? null : onMembers ⚠  | — | **GAP** |
| See all | button | — | local/unclassified action — callback: onMembers ⚠  | — | **GAP** |
| Join group | button | — | local/unclassified action — callback: busy ? null : onJoin ⚠  | — | **GAP** |
| Options for {name} | menu | — | calls POST /v1/engagement/groups/{groupID}/members/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | — | **GAP** |
| Save changes | button | — | closes screen/sheet, updates local state | — | **GAP** |
| Group name | field | — | opens TextField | flutter: `group_covers_test.dart` › a cover chosen while creating is uploaded to the new group<br>flutter: `groups_test.dart` › create flow starts private with the preselected friends<br>+1 more | automated |
| What is it about? | field | — | opens TextField | — | **GAP** |
| City (optional) | field | — | opens TextField | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| ${c.emoji}  ${c.title} | toggle | — | updates local state | — | **GAP** |

#### GroupCover — `groups.group_widgets`

Route: opened from: create_group_screen, group_detail_screen · Source: `app/lib/features/groups/group_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |

#### GroupsScreen — `groups.groups`

Route: opened from: group_launch, web_member_workspace · Source: `app/lib/features/groups/groups_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Join | gesture | — | local/unclassified action — callback: refresh ⚠  | only checks presence: flutter: `groups_test.dart` › discover filters by lifestyle and joins a group | presence-only |
| Start a group | button | — | may open CreateGroupScreen | — | **GAP** |
| Invitation declined. | button | — | may open GroupDetailScreen | — | **GAP** |
| Decline | button | — | calls POST /v1/engagement/groups/{groupID}/invites/respond; shows snackbar, updates local state | — | **GAP** |
| Join a community below, or start a private group with your f | button | — | may open GroupDetailScreen | — | **GAP** |
| All | toggle | — | updates local state | — | **GAP** |
| ${c.emoji}  ${c.title} ·  | toggle | — | updates local state | flutter: `groups_test.dart` › discover filters by lifestyle and joins a group | automated |
| Be the first: start a community group and invite your friend | button | — | may open CreateGroupScreen | — | **GAP** |
| Join | button | — | may open GroupDetailScreen | — | **GAP** |
| Join | button | — | shows snackbar, updates local state | flutter: `groups_test.dart` › discover filters by lifestyle and joins a group | automated |

### Engagement Hub

#### CircleChallengesScreen — `engagement.circle_challenges`

Route: opened from: engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/circle_challenges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Submit Entry | gesture | — | calls GET /v1/engagement/circles/{circleID}/challenge | — | **GAP** |
| Join Circle | button | — | calls POST /v1/engagement/circles/{circleID}/join | — | **GAP** |
| Weekly challenge response | field | — | opens TextField | — | **GAP** |
| Submit Entry | button | — | calls POST /v1/engagement/circles/{circleID}/challenge/entries | — | **GAP** |

#### ConversationRoomsScreen — `engagement.conversation_rooms`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/conversation_rooms_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| tile | button | — | calls POST /v1/rooms/{roomID}/join, GET /v1/rooms; may open SocialChatScreen; opens showModalBottomSheet; shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › tapping a room joins it and opens its chat<br>flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation<br>+4 more | automated |
| Start a room | button | — | calls GET /v1/rooms; may open SocialChatScreen; opens showModalBottomSheet | only checks presence: flutter: `conversation_rooms_screen_test.dart` › rooms render in German | presence-only |
| Rooms members are hosting. Join early to save a spot. | gesture | — | calls GET /v1/rooms | only checks presence: flutter: `conversation_rooms_screen_test.dart` › lists the always-on rooms with live presence | presence-only |
| Back (icon arrow_back_rounded) | button | — | closes screen/sheet | — | **GAP** |
| Try again | button | — | calls GET /v1/rooms | — | **GAP** |
| All | toggle | — | local/unclassified action — callback: notifier.setCategory | — | **GAP** |
| Friends here | toggle | — | local/unclassified action — callback: (on) => notifier.setFriendOnly(value: on) | — | **GAP** |
| Room name | field | — | opens TextField | — | **GAP** |
| What’s it about? (optional) | field | — | opens TextField | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| 30 min | toggle | — | updates local state | — | **GAP** |
| Start now | button | — | calls POST /v1/rooms; closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |

#### DailyPromptScreen — `engagement.daily_prompt`

Route: opened from: engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/daily_prompt_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Update Answer | gesture | — | calls GET /v1/engagement/daily-prompt/{userID}, GET /v1/engagement/daily-prompt/{userID}/responders | — | **GAP** |
| Type your response in under 60 seconds. | field | — | opens TextField | — | **GAP** |
| Update Answer | button | — | calls POST /v1/engagement/daily-prompt/{userID}/answer, GET /v1/engagement/daily-prompt/{userID}/responders | — | **GAP** |

#### EngagementHubScreen — `engagement.engagement_hub`

Route: #/engagement (web) / bottom nav: Engage tab (mobile) · Source: `app/lib/features/engagement/screens/engagement_hub_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Blog · Open Chapters | button | — | may open BlogScreen | — | **GAP** |
| Photo Themes | button | — | may open PhotoThemesScreen | — | **GAP** |
| Book & Film Clubs | button | — | may open ClubsScreen | — | **GAP** |
| The City Pilot | button | — | may open CityPilotScreen | — | **GAP** |
| Daily Prompt Streak | button | — | may open DailyPromptScreen | — | **GAP** |
| Guided Voice Icebreakers | button | — | may open VoiceIcebreakersScreen | — | **GAP** |
| Local Circle Challenges | button | — | may open CircleChallengesScreen | — | **GAP** |
| Group Coffee Poll | button | — | may open GroupCoffeePollsScreen | — | **GAP** |
| Groups | button | — | may open GroupsScreen | playwright: `app-member-workspace.spec.js` › WEB-09: phone Back arrow returns to the previous page | automated |
| Conversation Rooms | button | — | may open ConversationRoomsScreen | — | **GAP** |
| Friends & Introductions | button | — | may open FriendsScreen | — | **GAP** |
| Level & XP | button | — | may open LevelProgressionScreen | — | **GAP** |
| Trust Badges | button | — | may open TrustBadgesScreen | — | **GAP** |
| Trust Filters | button | — | may open TrustFilterScreen | — | **GAP** |

#### GroupCoffeePollsScreen — `engagement.group_coffee_polls`

Route: opened from: engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/group_coffee_polls_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Finalize Poll | gesture | — | calls GET /v1/engagement/group-coffee-polls | — | **GAP** |
| Participant user IDs (comma-separated) | field | — | opens TextField | — | **GAP** |
| Deadline ISO (optional) | field | — | opens TextField | — | **GAP** |
| Create Poll | button | — | calls POST /v1/engagement/group-coffee-polls, GET /v1/engagement/group-coffee-polls | — | **GAP** |
| Action user ID override (optional) | field | — | opens TextField | — | **GAP** |
| Vote | button | — | calls POST /v1/engagement/group-coffee-polls/{pollID}/votes, GET /v1/engagement/group-coffee-polls | — | **GAP** |
| Finalize Poll | button | — | calls POST /v1/engagement/group-coffee-polls/{pollID}/finalize, GET /v1/engagement/group-coffee-polls | — | **GAP** |
| Day | field | — | opens TextField | — | **GAP** |
| Time window | field | — | opens TextField | — | **GAP** |
| Neighborhood | field | — | opens TextField | — | **GAP** |

#### LevelProgressionScreen — `engagement.level_progression`

Route: opened from: blog_follow, engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/level_progression_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Progression is paused while an account safety review is acti | gesture | — | calls GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | only checks presence: flutter: `engagement_l10n_test.dart` › Level & XP screen renders in German | presence-only |
| Locked | button | — | calls POST /v1/progression/{userID}/rewards/claim, GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | — | **GAP** |
| _ErrorCard onRetry | button | — | calls GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | — | **GAP** |

#### MatchNudgesScreen — `engagement.match_nudges`

Route: opened from: main_navigation_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/match_nudges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Nudge | button | — | calls POST /v1/engagement/match-nudges/send; shows snackbar | — | **GAP** |

#### RoomPresenceHeader — `engagement.room_chat`

Route: embedded / not directly routed · Source: `app/lib/features/engagement/screens/room_chat.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| message | button | — | opens showModalBottomSheet | — | **GAP** |
| People (icon people_alt_outlined) | button | — | opens showModalBottomSheet, showRoomMembersSheet | flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation<br>flutter: `conversation_rooms_screen_test.dart` › a muted member shows as muted with Unmute for the host | automated |
| Room options | menu | — | calls POST /v1/rooms/{roomID}/leave, POST /v1/rooms/{roomID}/moderate, GET /v1/rooms; opens showDialog, showModalBottomSheet, showRoomMembersSheet; closes scree | flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation<br>flutter: `conversation_rooms_screen_test.dart` › a host can warn a participant with warn_user<br>+3 more | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Try again | button | — | refreshes data | — | **GAP** |
| {name} (you) | button | — | opens showModalBottomSheet | flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation<br>flutter: `conversation_rooms_screen_test.dart` › a host can warn a participant with warn_user<br>+2 more | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Until the room ends | sheet | — | presents a bottom sheet | only checks presence: flutter: `conversation_rooms_screen_test.dart` › a host mutes a participant for an hour with mute_user | presence-only |
| timer outlined (icon timer_outlined) | button | — | closes screen/sheet, pops a result to caller | flutter: `conversation_rooms_screen_test.dart` › a host mutes a participant for an hour with mute_user | automated |
| Submit report | button | — | calls POST /v1/safety/report | — | **GAP** |
| Report | button | — | calls POST /v1/safety/report; opens showModalBottomSheet, showReportUserSheet | only checks presence: flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation | presence-only |
| Block | button | — | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | only checks presence: flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation | presence-only |
| Warn | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › a host can warn a participant with warn_user | automated |
| Unmute | button | — | calls POST /v1/rooms/{roomID}/moderate; closes screen/sheet, refreshes data, shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › a muted member shows as muted with Unmute for the host | automated |
| Mute | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showModalBottomSheet; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local  | flutter: `conversation_rooms_screen_test.dart` › a host mutes a participant for an hour with mute_user | automated |
| Remove from room | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | only checks presence: flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation | presence-only |

#### TrustBadgesScreen — `engagement.trust_badges`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/trust_badges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| No trust history available yet. | gesture | — | calls GET /v1/users/{userID}/trust-badges | — | **GAP** |

#### TrustFilterScreen — `engagement.trust_filter`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/trust_filter_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Save Trust Filters | gesture | — | calls GET /v1/discovery/{userID}/filters/trust | flutter: `additional_filter_screens_test.dart` › standalone trust controls persist complete payload<br>flutter: `additional_filter_screens_test.dart` › standalone trust save failure never claims success | automated |
| Enable trust filters | toggle | — | updates local state | — | **GAP** |
| Slider onChanged | toggle | — | updates local state | — | **GAP** |
| CheckboxListTile onChanged | toggle | — | updates local state | — | **GAP** |
| Save Trust Filters | button | — | calls PATCH /v1/discovery/{userID}/filters/trust; refreshes data, shows snackbar | flutter: `additional_filter_screens_test.dart` › standalone trust controls persist complete payload<br>flutter: `additional_filter_screens_test.dart` › standalone trust save failure never claims success | automated |

#### VoiceIcebreakersScreen — `engagement.voice_icebreakers`

Route: opened from: chat_screen, engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/voice_icebreakers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Try again | button | — | refreshes data | — | **GAP** |
| Who would you like to say hello to? | menu | `qa.voice.conversation` | updates local state | — | **GAP** |
| Choose a prompt | menu | — | updates local state | — | **GAP** |
| Your words, in writing | field | `qa.voice.transcript` | updates local state | — | **GAP** |
| Record again · {seconds}s | button | `qa.voice.recording_button` | updates local state | only checks presence: playwright: `member-routes.spec.js` › member feature routes render at ${width}px | presence-only |
| Discard recording | button | — | updates local state | — | **GAP** |
| Share your hello | button | — | calls POST /v1/engagement/voice-icebreakers/start, POST /v1/engagement/voice-icebreakers/{icebreakerID}/send; refreshes data, shows snackbar, updates local stat | — | **GAP** |
| Try again | button | — | refreshes data | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Listen · {seconds}s | button | — | calls POST /v1/engagement/voice-icebreakers/{icebreakerID}/play | — | **GAP** |
| Reload prompts | button | — | calls GET /v1/engagement/voice-icebreakers/prompts | — | **GAP** |

### Date Plans

#### DebriefDatePlanSheet — `plans.debrief_date_plan_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/plans/screens/debrief_date_plan_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Did the date happen? | toggle | `qa.debrief.happened` | updates local state | — | **GAP** |
| Would you meet again? | toggle | `qa.debrief.again` | updates local state | — | **GAP** |
| Share a second yes | toggle | `qa.debrief.second_yes` | updates local state | — | **GAP** |
| Did you feel safe? | toggle | `qa.debrief.safe` | updates local state | — | **GAP** |
| Anything to add? (optional) | field | `qa.debrief.note` | opens TextField | — | **GAP** |
| Save debrief | button | `qa.debrief.submit` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; closes screen/sheet, pops a result to caller, updates local state | flutter: `date_plan_card_test.dart` › after checking in the member answers the debrief | automated |
| Sorry that did not feel safe | sheet | — | presents a dialog/picker | — | **GAP** |
| Not now | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report | button | `qa.debrief.report` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Submit report | button | — | calls POST /v1/safety/report | — | **GAP** |

#### PlanSharingSheet — `plans.plan_sharing_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/plans/screens/plan_sharing_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Close sharing | button | — | closes screen/sheet | — | **GAP** |
| A friend | toggle | `qa.plan.contact.${contact[` | updates local state | — | **GAP** |
| Reload sharing choices | button | — | calls GET /v1/matches/{matchID}/plans/{planID}/sharing; updates local state | only checks presence: flutter: `plan_sharing_sheet_test.dart` › Failed save preserves choices and never announces success | presence-only |
| Share with selected contacts | button | `qa.plan.sharing.save` | calls POST /v1/matches/{matchID}/plans/{planID}/sharing; closes screen/sheet, shows snackbar, updates local state | flutter: `plan_sharing_sheet_test.dart` › Failed save preserves choices and never announces success | automated |
| Deselect everyone | button | — | updates local state | — | **GAP** |

#### PlansScreen — `plans.plans`

Route: opened from: friends_screen, main_navigation_screen, web_member_workspace · Source: `app/lib/features/plans/screens/plans_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Mine | menu | — | local/unclassified action — callback:  | — | **GAP** |
| No plans yet | gesture | — | calls GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans, GET /v1/matches/{matchID}/plans | — | **GAP** |
| Nothing shared yet | gesture | — | calls GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans, GET /v1/matches/{matchID}/plans | — | **GAP** |
| Manage your contact sharing | button | `qa.plans.mine.*` | may open ChatScreen | — | **GAP** |
| Manage your contact sharing | button | `qa.plans.sharing.*` | opens showModalBottomSheet, showPlanSharingSheet | — | **GAP** |

#### ProposeDatePlanSheet — `plans.propose_date_plan_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/plans/screens/propose_date_plan_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| showDatePicker open | sheet | — | presents a dialog/picker | — | **GAP** |
| showTimePicker open | sheet | — | presents a dialog/picker | — | **GAP** |
| check circle outline (icon check_circle_outline) | button | `qa.plan.overlap.*` | updates local state | — | **GAP** |
| Refresh shared times | button | — | refreshes data | — | **GAP** |
| Set my availability | button | — | may open DatingRhythmScreen; refreshes data | — | **GAP** |
| Pick day (icon calendar_today_outlined) | button | `qa.plan.pick_day` | opens showDatePicker; updates local state | — | **GAP** |
| ${describeDatePlanTime(_start)}–${describeDatePlanTime(_end) | button | `qa.plan.pick_time` | opens showTimePicker; updates local state | — | **GAP** |
| {minutes} min | toggle | `qa.plan.duration.*` | updates local state | — | **GAP** |
| venue | toggle | `qa.plan.venue.*` | updates local state | — | **GAP** |
| Place (optional) | field | `qa.plan.venue_name` | opens TextField | — | **GAP** |
| Area or neighborhood | field | `qa.plan.venue_area` | opens TextField | — | **GAP** |
| budget | toggle | `qa.plan.budget.*` | updates local state | — | **GAP** |
| atmosphere | toggle | `qa.plan.atmosphere.*` | updates local state | — | **GAP** |
| accessibility | toggle | `qa.plan.accessibility.*` | updates local state | — | **GAP** |
| Note for them (optional) | field | `qa.plan.note` | opens TextField | only checks presence: flutter: `better_date_planning_test.dart` › chapter idea prefills an editable proposal without sending it | presence-only |
| Reload latest plan · discard edits | button | — | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; updates local state | — | **GAP** |
| Send your suggestion | button | `qa.plan.submit` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; closes screen/sheet, pops a result to caller, updates local state | flutter: `intentional_dating_test.dart` › counterproposal submits the version that was shown | automated |
| FilterChip onSelected | toggle | — | updates local state | — | **GAP** |
| Accept plan | button | `qa.plan.accept_confirm` | closes screen/sheet, pops a result to caller | — | **GAP** |

#### DatePlanCard — `plans.date_plan_card`

Route: opened from: chat_screen · Source: `app/lib/features/plans/widgets/date_plan_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Plan another hello | button | `qa.plan.second_yes` | opens showModalBottomSheet, showProposeDatePlanSheet | — | **GAP** |
| Propose | button | `qa.plan.propose_cta` | opens showModalBottomSheet, showProposeDatePlanSheet | only checks presence: flutter: `date_plan_card_test.dart` › shows the propose call to action only when allowed | presence-only |
| Suggest a change | button | `qa.plan.counter` | opens showModalBottomSheet, showProposeDatePlanSheet | — | **GAP** |
| Choose who gets your updates | button | `qa.plan.sharing` | opens showModalBottomSheet, showPlanSharingSheet | — | **GAP** |
| Ten-second debrief | button | `qa.plan.debrief` | calls POST /v1/safety/report, GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showDebriefDatePlanSheet, showDialo | flutter: `date_plan_card_test.dart` › after checking in the member answers the debrief | automated |
| Decline | button | `qa.plan.decline` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | — | **GAP** |
| Accept | button | `qa.plan.accept` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showAcceptDatePlanSheet | flutter: `date_plan_card_test.dart` › invitee sees the proposal and accepts it<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| Cancel plan | button | `qa.plan.cancel` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showDialog; closes screen/sheet, pops a result to caller | only checks presence: flutter: `date_plan_card_test.dart` › invitee sees the proposal and accepts it | presence-only |
| I need help | button | `qa.plan.need_help` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | — | **GAP** |
| I'm safe | button | `qa.plan.safe` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | flutter: `date_plan_card_test.dart` › after the window the member can check in safe | automated |
| Cancel this plan? | sheet | — | presents a dialog/picker | — | **GAP** |
| Keep it | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Cancel plan | button | `qa.plan.cancel_confirm` | closes screen/sheet, pops a result to caller | — | **GAP** |

### Graduation

#### GraduationCelebrationScreen — `graduation.graduation_celebration`

Route: opened from: graduation_banner · Source: `app/lib/features/graduation/screens/graduation_celebration_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Tell my friends | toggle | `qa.graduation.celebration.share` | updates local state | flutter: `graduation_banner_test.dart` › the partner confirms through the celebration screen | automated |
| Back to Connect | button | `qa.graduation.celebration.done` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{}; closes screen/sheet, pops a result to ca ⚠ pops a result to its opener — verify every opener handles it | flutter: `graduation_banner_test.dart` › the partner confirms through the celebration screen | automated |

#### ProposeGraduationSheet — `graduation.propose_graduation_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/graduation/screens/propose_graduation_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| A note for them (optional) | field | `qa.graduation.note` | opens TextField | flutter: `graduation_banner_test.dart` › a member proposes from the sheet with a note and share | automated |
| Tell my friends | toggle | `qa.graduation.share_switch` | updates local state | flutter: `graduation_banner_test.dart` › a member proposes from the sheet with a note and share | automated |
| Ask them | button | `qa.graduation.submit` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{}; closes screen/sheet, pops a result to ca | flutter: `graduation_banner_test.dart` › a member proposes from the sheet with a note and share | automated |

#### GraduationBanner — `graduation.graduation_banner`

Route: opened from: chat_screen · Source: `app/lib/features/graduation/widgets/graduation_banner.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Celebrate | button | `qa.graduation.celebrate` | may open GraduationCelebrationScreen | flutter: `graduation_banner_test.dart` › the partner confirms through the celebration screen | automated |
| Not yet | button | `qa.graduation.decline` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | flutter: `graduation_banner_test.dart` › the partner can decline from the banner | automated |
| Confirm | button | `qa.graduation.confirm` | may open GraduationCelebrationScreen | flutter: `graduation_banner_test.dart` › the banner and celebration follow the member language<br>flutter: `graduation_banner_test.dart` › the partner confirms through the celebration screen | automated |
| Withdraw | button | `qa.graduation.withdraw` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | flutter: `graduation_banner_test.dart` › the proposer waits and can withdraw | automated |

### First Chapter Studio

#### ChapterStudioScreen — `first_chapter.chapter_studio`

Route: opened from: web_member_workspace · Source: `app/lib/features/first_chapter/chapter_studio_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create share link | sheet | — | presents a dialog/picker | only checks presence: flutter: `chapter_studio_test.dart` › a share needs the explicit public preview approval | presence-only |
| Keep private | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Create share link | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Refresh chapter | button | — | refreshes data | — | **GAP** |
| Try again | button | — | refreshes data | — | **GAP** |
| check circle (icon check_circle) | button | — | updates local state | — | **GAP** |
| Start our chapter | button | — | refreshes data, updates local state | — | **GAP** |
| Pass the Chapter | button | — | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Make this a date idea | button | — | opens showModalBottomSheet, showProposeDatePlanSheet | — | **GAP** |
| OutlinedButton onPressed | button | — | refreshes data, updates local state | — | **GAP** |
| Close this chapter | button | — | refreshes data, updates local state | — | **GAP** |
| Preview our anonymous story | button | — | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Make room for what matters to you | button | — | may open ComfortCardsScreen | — | **GAP** |
| Create a first chapter together | button | — | may open ChapterStudioScreen | — | **GAP** |
| Reload shared chapters | button | — | refreshes data | — | **GAP** |
| FilterChip onSelected | toggle | — | updates local state | — | **GAP** |
| Save privately | button | — | refreshes data, updates local state | — | **GAP** |
| Copy link | button | — | copies to clipboard, shows snackbar | — | **GAP** |
| Approve this exact story | button | — | refreshes data, updates local state | — | **GAP** |
| Revoke link | button | — | refreshes data, updates local state | — | **GAP** |

#### ComfortCardsScreen — `first_chapter.comfort_cards`

Route: opened from: chapter_studio_screen · Source: `app/lib/features/first_chapter/comfort_cards_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Reload saved version | button | — | refreshes data | — | **GAP** |
| Reload comfort cards | button | — | refreshes data | — | **GAP** |
| Share these cards with my matches | toggle | — | updates local state | — | **GAP** |
| Remove from draft | button | — | updates local state | — | **GAP** |
| A little context about | menu | — | updates local state | — | **GAP** |
| Original language | field | — | opens TextField | — | **GAP** |
| In your own words | field | — | opens TextField | — | **GAP** |
| Your translation (optional) | field | — | opens TextField | — | **GAP** |
| Translation language (if added) | field | — | opens TextField | — | **GAP** |
| Add / replace this card in draft | button | — | updates local state | — | **GAP** |
| Save my choices | button | — | closes screen/sheet, refreshes data, updates local state | — | **GAP** |

### Calls

#### CallHistoryScreen — `calls.call_history`

Route: opened from: matches_list_screen, settings_screen, web_member_workspace · Source: `app/lib/features/calls/screens/call_history_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Join live room | gesture | — | calls GET /v1/calls/history/{userID} | only checks presence: flutter: `call_screens_localization_test.dart` › call history speaks German | presence-only |
| Join live room | link | — | opens external link | — | **GAP** |

#### CallSessionScreen — `calls.call_session`

Route: opened from: matches_list_screen · Source: `app/lib/features/calls/screens/call_session_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Join live room | link | — | opens external link | — | **GAP** |
| End | button | — | calls POST /v1/calls/{callID}/end; closes screen/sheet | — | **GAP** |
| Try again | button | — | calls POST /v1/calls/start | — | **GAP** |

### Blog / Chapters

#### BlogTextCommandScreen — `blog.blog_connections`

Route: embedded / not directly routed · Source: `app/lib/features/blog/blog_connections.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| In your own words | field | — | updates local state | — | **GAP** |
| Sending… | button | — | closes screen/sheet, pops a result to caller, refreshes data, updates local state ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |
| Refresh | button | — | refreshes data | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Could not load your connections. | button | — | refreshes data | — | **GAP** |
| Open private exchange | button | — | may open BlogExchangeScreen | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Approve exact public copy | button | — | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Copy link | button | — | opens showDialog; copies to clipboard, shows snackbar | — | **GAP** |
| Withdraw link | button | — | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Appeal this decision | button | — | may open BlogTextCommandScreen | — | **GAP** |
| Previous | button | — | updates local state | — | **GAP** |
| More | button | — | updates local state | — | **GAP** |
| Refresh | button | — | refreshes data | — | **GAP** |
| This exchange is no longer available. | button | — | refreshes data | — | **GAP** |
| Accept an exchange | button | — | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, updates local state | — | **GAP** |
| Decline kindly | button | — | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, updates local state | — | **GAP** |
| Add my contribution | button | — | may open BlogTextCommandScreen | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Shape a date together | button | — | opens showModalBottomSheet, showProposeDatePlanSheet | only checks presence: flutter: `blog_connections_test.dart` › exchange waiting state hides partner text and planning | presence-only |
| Try First Chapter Studio | button | — | may open ChapterStudioScreen | — | **GAP** |
| Propose a shared journal page | button | — | may open BlogShareScreen; updates local state | — | **GAP** |
| Withdraw exchange | button | — | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes da | — | **GAP** |
| Report exchange | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet | — | **GAP** |
| Submit report | button | — | calls POST /v1/blog/reports/{kind}/{contentID} | — | **GAP** |
| Block member | button | — | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |

#### BlogEditor — `blog.blog_editor`

Route: opened from: blog_screen · Source: `app/lib/features/blog/blog_editor.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See my level | button | — | may open LevelProgressionScreen | only checks presence: flutter: `blog_topics_test.dart` › editor > first share beyond Only me points to XP and level | presence-only |
| Saved version · {audience} | sheet | — | presents a bottom sheet | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Keep my edits for the next save | button | — | closes screen/sheet, updates local state | — | **GAP** |
| Use saved version | button | — | closes screen/sheet, updates local state | — | **GAP** |
| Describe your photo | sheet | — | presents a dialog/picker | — | **GAP** |
| What is in this photo? | field | — | local/unclassified action — callback: (value) => altText = value | — | **GAP** |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Add to private draft | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Preview | button | — | updates local state | — | **GAP** |
| Check saved version | button | — | calls GET /v1/blog/posts/{postID}; opens showModalBottomSheet; closes screen/sheet, updates local state | — | **GAP** |
| Chapter title | field | — | opens TextField | — | **GAP** |
| End with an invitation (optional) | menu | — | updates local state | — | **GAP** |
| topic | toggle | — | updates local state | — | **GAP** |
| Remove photo | button | — | calls DELETE /v1/blog/posts/{postID}/photos/{photoID}; refreshes data, updates local state | — | **GAP** |
| Add a photo | button | — | calls PUT /v1/blog/posts/{postID}/photos/{photoID}, PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, opens p | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Allow featuring | toggle | — | updates local state | only checks presence: flutter: `blog_test.dart` › allow featuring is offered for community only and is sent | presence-only |
| {audience, select, private{Publish to Only me} friends{Publi | button | — | calls PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackb | — | **GAP** |
| Save as Only me | button | — | calls PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackb | — | **GAP** |

#### BlogFollowButton — `blog.blog_follow`

Route: opened from: blog_writers_screen · Source: `app/lib/features/blog/blog_follow.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Following | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | only checks presence: flutter: `blog_topics_test.dart` › follow on a chapter > flips at once, then confirms with the server | presence-only |
| Follow their chapters | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | only checks presence: flutter: `blog_topics_test.dart` › follow on a chapter > rolls back and explains when the server fails | presence-only |
| See my level | sheet | — | presents a bottom sheet | only checks presence: flutter: `blog_topics_test.dart` › editor > first share beyond Only me points to XP and level | presence-only |
| See my level | button | — | may open LevelProgressionScreen; closes screen/sheet | only checks presence: flutter: `blog_topics_test.dart` › editor > first share beyond Only me points to XP and level | presence-only |

#### BlogScreen — `blog.blog`

Route: opened from: web_member_workspace · Source: `app/lib/features/blog/blog_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| How rewards work | button | — | may open LevelProgressionScreen; opens showBlogRewardsSheet, showModalBottomSheet; closes screen/sheet | only checks presence: flutter: `blog_topics_test.dart` › rewards sheet lists the contract values | presence-only |
| Writers you follow | button | — | may open BlogWritersScreen | — | **GAP** |
| Private responses, sharing and notices | button | — | may open BlogConnectionsScreen | — | **GAP** |
| More chapters | gesture | — | refreshes data | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `blog-editor.spec.js` › bold, italic and underline then typing lands formatted; writing style  | automated |
| Write a chapter | button | — | may open BlogEditor | playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>playwright: `blog-editor.spec.js` › bold, italic and underline then typing lands formatted; writing style  | automated |
| Private responses | button | — | may open BlogConnectionsScreen | — | **GAP** |
| Shared links | button | — | may open BlogConnectionsScreen | — | **GAP** |
| Review notices | button | — | may open BlogConnectionsScreen | — | **GAP** |
| scope | toggle | — | updates local state | — | **GAP** |
| isEmpty ?  | toggle | — | updates local state | — | **GAP** |
| Chapters could not load. | button | — | refreshes data | — | **GAP** |
| Find writers in Top rated | button | — | updates local state | — | **GAP** |
| Previous page | button | — | updates local state | — | **GAP** |
| More chapters | button | — | updates local state | — | **GAP** |
| Read chapter → | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | — | **GAP** |
| Photo unavailable · Retry | button | — | refreshes data | — | **GAP** |
| This chapter is unavailable or its audience has changed. | button | — | refreshes data | — | **GAP** |
| Respond privately | button | — | may open BlogConnectionsScreen, BlogTextCommandScreen | — | **GAP** |
| Create a public preview | button | — | may open BlogShareScreen | — | **GAP** |
| Edit chapter | button | — | may open BlogEditor | — | **GAP** |
| Delete chapter | button | — | calls DELETE /v1/blog/posts/{postID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | — | **GAP** |
| Report chapter | button | — | calls POST /v1/blog/posts/{postID}/report; opens showModalBottomSheet, showReportUserSheet | — | **GAP** |
| Report could not be submitted. | button | — | calls POST /v1/blog/posts/{postID}/report | — | **GAP** |
| Block this member | button | — | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | — | **GAP** |
| Cancel | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| FilledButton onPressed | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### BlogShareScreen — `blog.blog_sharing`

Route: opened from: blog_connections, blog_screen · Source: `app/lib/features/blog/blog_sharing.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Your public link | sheet | — | presents a dialog/picker | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Exact excerpt from your chapter | field | — | updates local state | — | **GAP** |
| Include: {description} | toggle | — | updates local state | — | **GAP** |
| I approve this exact public copy | toggle | — | updates local state | — | **GAP** |
| Create public link | button | — | calls POST /v1/blog/publications; opens share sheet, refreshes data, updates local state | only checks presence: flutter: `blog_connections_test.dart` › public copy requires unchecked explicit consent | presence-only |
| Copy public link | button | — | opens showDialog; copies to clipboard, shows snackbar | only checks presence: flutter: `blog_connections_test.dart` › joint preview shows both exact contributions but no live link | presence-only |
| Manage shared links | button | — | may open BlogConnectionsScreen | — | **GAP** |

#### SocialLikeButton — `blog.blog_social`

Route: opened from: photo_theme_widgets · Source: `app/lib/features/blog/blog_social.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| {noun, select, photo{You can’t react to your own photo} othe | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | — | **GAP** |
| ${state.count} | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | — | **GAP** |
| Comments | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | only checks presence: flutter: `blog_social_test.dart` › community feed leads with Featured Stories and engagement | presence-only |
| Report could not be submitted. | button | — | calls POST /v1/blog/reports/{kind}/{contentID} | — | **GAP** |
| Leave a comment | field | — | updates local state | only checks presence: flutter: `blog_social_test.dart` › comments section > the author sees pending comments and can approve th | presence-only |
| Send to the author | button | — | updates local state | — | **GAP** |
| Comments could not load. | button | — | refreshes data | — | **GAP** |
| Decline | button | — | shows snackbar, updates local state | — | **GAP** |
| Comment options | menu | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Approve | button | — | local/unclassified action — callback: busy ? null : onApprove ⚠  | only checks presence: flutter: `blog_social_test.dart` › comments section > readers see approved and their own pending comments | presence-only |

#### BlogWritersScreen — `blog.blog_writers`

Route: embedded / not directly routed · Source: `app/lib/features/blog/blog_writers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Writers you follow could not load. | button | — | refreshes data | — | **GAP** |
| An untitled chapter | gesture | — | refreshes data | — | **GAP** |
| An untitled chapter | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | — | **GAP** |

#### BlogDetailScreen — `blog.blog_detail`

Route: see screen matrix · Source: `app/lib/features/blog/blog_screen.dart` · in screen matrix

_No interactive control detected in this file by static extraction (display-only, or controls live in shared child widgets listed under their own feature)._

| Case | Type | Automated by | Status |
|---|---|---|---|
| BlogDetailScreen lays out on every device size/theme | layout | flutter: `screen_matrix_test.dart` › $screenLabel lays out on $deviceLabel [$themeLabel] | automated |
| BlogDetailScreen meets accessibility guidelines | a11y | flutter: `screen_accessibility_test.dart` › $label meets accessibility guidelines [$themeLabel] | automated |
| BlogDetailScreen shows a visible way back when pushed | a11y | flutter: `back_affordance_audit_test.dart` › ${entry.key} shows a way back when pushed | automated |

### Photo Themes

#### PhotoThemeGalleryScreen — `photo_themes.photo_theme_gallery`

Route: opened from: photo_themes_screen, rose_rain · Source: `app/lib/features/photo_themes/photo_theme_gallery_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Share a photo for this theme | button | — | calls PUT /v1/themes/{themeID}/entries/{entryID}; opens showDialog; opens photo/file picker, opens share sheet, shows snackbar, updates local state | only checks presence: flutter: `photo_themes_data_test.dart` › PhotoThemesScreen renders themes from the API | presence-only |
| Be the first to share for “{title}” | gesture | — | updates local state | — | **GAP** |
| Load more | button | — | updates local state | — | **GAP** |
| More photos could not load. Reload | button | — | updates local state | — | **GAP** |
| ThemeEntryTile onTap | button | — | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | — | **GAP** |

#### ThemeEntrySheet — `photo_themes.photo_theme_widgets`

Route: embedded / not directly routed · Source: `app/lib/features/photo_themes/photo_theme_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Photo unavailable. Retry | button | — | refreshes data | — | **GAP** |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| ${state.count} | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | — | **GAP** |
| Let it reach other members’ walls | toggle | — | calls POST /v1/themes/{themeID}/entries/{entryID}/featuring; shows snackbar, updates local state | only checks presence: flutter: `photo_wall_test.dart` › entry sheet > the author approves pending comments and controls reach | presence-only |
| Remove my photo | button | — | local/unclassified action — callback: busy ? null : remove ⚠  | — | **GAP** |
| Report | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | — | **GAP** |
| Block {name} | button | — | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| showDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| Caption | field | — | updates local state | only checks presence: flutter: `photo_wall_test.dart` › Photo wall rail > renders magazine covers for wall photos | presence-only |
| Describe the photo | field | — | updates local state | — | **GAP** |
| Let it reach other members’ walls | toggle | — | updates local state | only checks presence: flutter: `photo_wall_test.dart` › upload > the dialog switch is off by default and reports its value | presence-only |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Share | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### PhotoThemesScreen — `photo_themes.photo_themes`

Route: opened from: today_activities · Source: `app/lib/features/photo_themes/photo_themes_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Show a little of your world | gesture | — | refreshes data | — | **GAP** |
| Themes could not load | button | — | refreshes data | — | **GAP** |
| See everyone’s photos → | button | — | may open PhotoThemeGalleryScreen | only checks presence: flutter: `photo_themes_data_test.dart` › PhotoThemesScreen renders themes from the API | presence-only |

#### PhotoWallRail — `photo_themes.photo_wall`

Route: embedded / not directly routed · Source: `app/lib/features/photo_themes/photo_wall.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| InkWell onTap | button | — | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | — | **GAP** |

### Clubs & Lists

#### ClubDetailScreen — `clubs.club_detail`

Route: opened from: clubs_screen · Source: `app/lib/features/clubs/club_detail_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Club options | menu | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showClubMembersSheet, showClubSheet, showModalBottomSheet; shows snackbar | — | **GAP** |
| This club could not load | button | — | refreshes data | — | **GAP** |
| Members talk about each pick together. Join the club to read | gesture | — | local/unclassified action — callback: () async { invalidateClub(ref, club.id); await ref.read(clubDetailProvider(club.id).future ⚠  | — | **GAP** |
| Members | button | — | opens showClubMembersSheet, showClubSheet, showModalBottomSheet | — | **GAP** |
| Discuss this pick | button | — | updates local state | — | **GAP** |
| Set this week’s pick | button | — | opens showClubSheet, showModalBottomSheet, showSetPickSheet; updates local state | only checks presence: flutter: `clubs_data_test.dart` › ClubDetailScreen shows the pick and collapses spoilers | presence-only |
| {week} · {count, plural, =1{1 post} other{{count} posts}} | button | — | may open TitleDetailScreen | — | **GAP** |
| Open the discussion | button | — | updates local state | — | **GAP** |
| Join club | button | — | local/unclassified action — callback: busy ? null : onJoin ⚠  | — | **GAP** |
| Leave club | button | — | local/unclassified action — callback: busy ? null : onLeave ⚠  | only checks presence: flutter: `clubs_data_test.dart` › ClubDetailScreen shows the pick and collapses spoilers | presence-only |
| chevron right (icon chevron_right) | button | — | may open TitleDetailScreen | — | **GAP** |

#### ClubDiscussion — `clubs.club_discussion`

Route: opened from: club_detail_screen · Source: `app/lib/features/clubs/club_discussion.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| The discussion could not load | button | — | updates local state | — | **GAP** |
| Load more posts | button | — | updates local state | — | **GAP** |
| Post | button | — | calls PUT /v1/clubs/{clubID}/posts/{postID}; shows snackbar, updates local state | — | **GAP** |
| Contains spoilers | toggle | — | updates local state | — | **GAP** |
| Add to the discussion | field | — | opens TextField | — | **GAP** |
| Post actions | menu | — | calls DELETE /v1/clubs/{clubID}/posts/{postID}, POST /v1/clubs/{clubID}/posts/{postID}/visibility, POST /v1/blog/reports/{kind}/{contentID}; opens showDialog, s | — | **GAP** |

#### ClubMembersSheet — `clubs.club_members_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/club_members_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Actions for {name} | menu | — | calls POST /v1/clubs/{clubID}/members/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | — | **GAP** |

#### ClubPickSheet — `clubs.club_pick_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/club_pick_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Next week | toggle | — | updates local state | only checks presence: flutter: `clubs_data_test.dart` › ClubsScreen renders clubs and filters by kind | presence-only |
| Search (icon search) | button | — | opens showClubSheet, showModalBottomSheet; updates local state | — | **GAP** |
| Change | button | — | opens showClubSheet, showModalBottomSheet; updates local state | — | **GAP** |
| A note for the club (optional) | field | — | opens TextField | — | **GAP** |
| Save pick | button | — | calls PUT /v1/clubs/{clubID}/selections/{weekStart}; closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |

#### KindBadge — `clubs.club_widgets`

Route: opened from: club_detail_screen, clubs_screen, my_lists_screen, title_detail_screen · Source: `app/lib/features/clubs/club_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |

#### ClubsScreen — `clubs.clubs`

Route: opened from: today_activities · Source: `app/lib/features/clubs/clubs_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| My lists | button | — | may open MyListsScreen | — | **GAP** |
| Start a book or film club | button | — | may open ClubDetailScreen; opens showClubSheet, showModalBottomSheet; refreshes data | only checks presence: flutter: `clubs_data_test.dart` › ClubsScreen renders clubs and filters by kind | presence-only |
| Try again | gesture | — | refreshes data | — | **GAP** |
| My clubs | toggle | — | updates local state | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Clubs could not load | button | — | refreshes data | — | **GAP** |
| No clubs here yet | button | — | updates local state | — | **GAP** |
| No pick yet this week | button | — | may open ClubDetailScreen | only checks presence: flutter: `clubs_data_test.dart` › ClubsScreen renders clubs and filters by kind | presence-only |
| SegmentedButton onSelectionChanged | toggle | — | updates local state | — | **GAP** |
| Club name | field | — | opens TextField | only checks presence: flutter: `clubs_data_test.dart` › ClubDetailScreen shows the pick and collapses spoilers | presence-only |
| What is your club about? (optional) | field | — | opens TextField | — | **GAP** |
| Create club | button | — | calls PUT /v1/clubs/{clubID}; closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |

#### ListSheets — `clubs.list_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/list_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| List name | field | — | opens TextField | — | **GAP** |
| SegmentedButton onSelectionChanged | toggle | — | updates local state | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Create list | button | — | calls PUT /v1/clubs/lists/{listID}; closes screen/sheet, pops a result to caller, refreshes data, updates local state ⚠ pops a result to its opener — verify every opener handles it | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup | automated |
| showDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| Why it is on this list | field | — | opens TextField | — | **GAP** |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Save note | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### MyListsScreen — `clubs.my_lists`

Route: opened from: clubs_screen · Source: `app/lib/features/clubs/my_lists_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create a new list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | — | **GAP** |
| New list | gesture | — | refreshes data | — | **GAP** |
| Your lists could not load | button | — | refreshes data | — | **GAP** |
| Start your first list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | — | **GAP** |
| List options | menu | — | calls PUT /v1/clubs/lists/{listID}/items/{titleID}, DELETE /v1/clubs/lists/{listID}; opens showClubSheet, showDialog, showListEditorSheet; closes screen/sheet,  | — | **GAP** |
| “{note}” | button | — | may open TitleDetailScreen | — | **GAP** |
| Options for {title} | menu | — | calls PUT /v1/clubs/lists/{listID}/items/{titleID}, DELETE /v1/clubs/lists/{listID}/items/{titleID}; opens showDialog; refreshes data, shows snackbar, updates l | — | **GAP** |

#### ReviewSheets — `clubs.review_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/review_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| {count, plural, =1{1 star} other{{count} stars}} | button | — | updates local state | — | **GAP** |
| What did you think? (optional) | field | — | opens TextField | — | **GAP** |
| Contains spoilers | toggle | — | updates local state | — | **GAP** |
| ChoiceChip onSelected | toggle | — | updates local state | — | **GAP** |
| Save review | button | — | calls PUT /v1/clubs/titles/{titleID}/reviews/{reviewID}; closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |
| {count, plural, =1{1 title} other{{count} titles}} | button | — | local/unclassified action — callback: () => add(list) ⚠  | — | **GAP** |
| New list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | — | **GAP** |

#### TitleDetailScreen — `clubs.title_detail`

Route: opened from: club_detail_screen, my_lists_screen · Source: `app/lib/features/clubs/title_detail_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| This title could not load | button | — | refreshes data | — | **GAP** |
| When members you can see share a review, it shows up here. | gesture | — | refreshes data | — | **GAP** |
| Add to a list | button | — | opens showAddToListSheet, showClubSheet, showModalBottomSheet | — | **GAP** |
| Write a review | button | — | opens showClubSheet, showModalBottomSheet, showReviewSheet | — | **GAP** |
| Edit | button | — | opens showClubSheet, showModalBottomSheet, showReviewSheet | — | **GAP** |
| Delete | button | — | calls DELETE /v1/clubs/reviews/{reviewID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| Report this review | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | — | **GAP** |

#### TitlePicker — `clubs.title_picker`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/title_picker.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Type at least 2 letters | field | — | updates local state | — | **GAP** |
| ListTile onTap | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Add (icon add) | button | — | updates local state | — | **GAP** |
| Title | field | — | opens TextField | — | **GAP** |
| Author | field | — | opens TextField | — | **GAP** |
| Year (optional) | field | — | opens TextField | — | **GAP** |
| Add and choose | button | — | local/unclassified action — callback: busy ? null : add ⚠  | — | **GAP** |

### City Pilot

#### CityPilotScreen — `city_pilot.city_pilot`

Route: opened from: engagement_hub_screen · Source: `app/lib/features/city_pilot/city_pilot_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Leave the city pilot? | sheet | — | presents a dialog/picker | only checks presence: flutter: `city_pilot_test.dart` › leaving is reachable when paused and flag is off | presence-only |
| Stay in pilot | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Leave pilot | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Join {title}? | sheet | — | presents a dialog/picker | — | **GAP** |
| Not now | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Accept & reserve a place | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| I couldn’t make it | toggle | — | local/unclassified action — callback: (_) => update(() { attended = value; worthwhile = null; }) | — | **GAP** |
| Not this time | toggle | — | local/unclassified action — callback: (selected) => update( () => worthwhile = selected ? value : null, ) | — | **GAP** |
| Skip | button | — | closes screen/sheet | — | **GAP** |
| Share feedback | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Refresh pilot | button | — | refreshes data | — | **GAP** |
| Try again | button | — | refreshes data | — | **GAP** |
| I agree to take part in this pilot and its outcome measureme | toggle | — | updates local state | — | **GAP** |
| Join the city pilot | button | — | calls POST /v1/city-pilot/membership; refreshes data, updates local state | only checks presence: flutter: `city_pilot_test.dart` › explicit unchecked consent is needed to join | presence-only |
| Leave pilot | button | — | calls DELETE /v1/city-pilot/membership; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |
| Cancel my place | button | — | calls DELETE /v1/city-pilot/events/${event[; refreshes data, updates local state | — | **GAP** |
| Reserve a free place | button | — | calls POST /v1/city-pilot/events/${event[; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, updates local state | only checks presence: flutter: `city_pilot_test.dart` › cancelled experience offers no reservation | presence-only |
| Share optional feedback | button | — | calls POST /v1/city-pilot/events/${event[; closes screen/sheet, pops a result to caller, refreshes data, updates local state | — | **GAP** |

### Notifications

#### NotificationInboxScreen — `notifications.notification_inbox`

Route: opened from: main_navigation_screen, notification_settings_screen, web_member_workspace · Source: `app/lib/features/notifications/screens/notification_inbox_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Read all | button | — | calls POST /v1/notifications/{userID}/read-all | — | **GAP** |
| You are all caught up | gesture | — | calls POST /v1/notifications/{userID}/devices, GET /v1/notifications/{userID}, GET /v1/notifications/{userID}/unread-count, GET /v1/notifications/{userID}/prefe | — | **GAP** |
| Someone liked you | swipe | — | calls DELETE /v1/notifications/{userID}/{notificationID} | — | **GAP** |
| InkWell onTap | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open FriendsScreen, HelpSupportScreen, LikedMeScreen | — | **GAP** |

### Celebrations & Rewards

#### RewardBurstOverlay — `celebrations.reward_burst`

Route: embedded / not directly routed · Source: `app/lib/features/celebrations/reward_burst.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Close | button | `qa.reward_burst.close` | local/unclassified action — callback: () { if (closed) { return; } closed = true; entry.remove(); _activeEntry = null; next.done ⚠  | flutter: `reward_burst_test.dart` › showRewardBurst queues bursts and closes on demand<br>flutter: `reward_burst_test.dart` › RewardBurstHost > baselines on first look, then celebrates new XP once<br>+1 more | automated |

#### RoseRainHost — `celebrations.rose_rain`

Route: opened from: main_navigation_screen · Source: `app/lib/features/celebrations/rose_rain.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showGeneralDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| Lovely | button | `qa.rose_rain.close` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `rose_rain_test.dart` › the host plays each celebration once and marks it seen | automated |
| See chapter | button | `qa.rose_rain.open` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | — | **GAP** |

### Safety

#### SosScreen — `safety.sos`

Route: opened from: privacy_safety_screen, support_ticket_form_screen · Source: `app/lib/features/safety/screens/sos_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Resolution: {note} | gesture | — | calls GET /v1/safety/sos/{userID} | only checks presence: flutter: `sos_screen_l10n_test.dart` › English alert history keeps its wording | presence-only |
| Urgent | toggle | — | updates local state | — | **GAP** |
| Message for the safety team | field | — | opens TextField | — | **GAP** |
| Activate SOS | button | `qa.safety.activate_sos` | calls POST /v1/safety/sos; opens showDialog; closes screen/sheet, pops a result to caller | — | **GAP** |
| Activate SOS now? | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Activate | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Done | sheet | — | presents a dialog/picker | — | **GAP** |
| Done | button | — | closes screen/sheet | — | **GAP** |

### Help & Support

#### SupportTicketFormScreen — `support.support_ticket_form`

Route: opened from: help_support_screen, support_tickets_screen · Source: `app/lib/features/support/screens/support_ticket_form_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to Help & Support | button | — | closes screen/sheet | — | **GAP** |
| support category * | toggle | — | updates local state | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+5 more | automated |
| Open SOS | button | — | may open SosScreen | only checks presence: flutter: `support_ticket_form_test.dart` › safety topic points to SOS and emergency services | presence-only |
| Subject | field | — | opens TextField | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+5 more | automated |
| What happened? | field | — | opens TextField | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+3 more | automated |
| Add screenshot | button | — | calls POST /v1/support/attachments; opens photo/file picker | flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids | automated |
| Send request | button | — | calls POST /v1/support/tickets; may open SupportTicketThreadScreen; refreshes data, shows snackbar, updates local state | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+4 more | automated |

#### SupportTicketThreadScreen — `support.support_ticket_thread`

Route: opened from: support_routes, support_ticket_form_screen, support_tickets_screen · Source: `app/lib/features/support/screens/support_ticket_thread_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Close this request? | sheet | — | presents a dialog/picker | only checks presence: flutter: `support_ticket_thread_test.dart` › close asks for confirmation first | presence-only |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Close request | button | — | closes screen/sheet, pops a result to caller | flutter: `support_ticket_thread_test.dart` › close asks for confirmation first | automated |
| Try again | button | — | calls GET /v1/support/tickets/{ticketID}; refreshes data, updates local state | — | **GAP** |
| Try again | gesture | — | calls GET /v1/support/tickets/{ticketID}; refreshes data, updates local state | — | **GAP** |
| Close request | button | — | calls POST /v1/support/tickets/{}/{}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `support_ticket_thread_test.dart` › close asks for confirmation first | automated |
| Send rating | button | — | calls POST /v1/support/tickets/{}/{}; refreshes data, shows snackbar, updates local state | flutter: `support_ticket_thread_test.dart` › resolved: explains reopening by reply and offers a rating | automated |
| {count, plural, =1{1 star} other{{count} stars}} | button | — | updates local state | flutter: `support_ticket_thread_test.dart` › resolved: explains reopening by reply and offers a rating | automated |
| Reopen request | button | — | calls POST /v1/support/tickets/{}/{}; refreshes data, shows snackbar, updates local state | flutter: `support_ticket_thread_test.dart` › closed: reply disabled, reopen offered until the date | automated |
| Anything to add? (optional) | field | — | opens TextField | flutter: `support_ticket_thread_test.dart` › resolved: explains reopening by reply and offers a rating | automated |
| Replies are closed for this request | field | — | opens TextField | flutter: `support_ticket_thread_test.dart` › a reply is posted and appears in the thread | automated |

#### SupportTicketsScreen — `support.support_tickets`

Route: opened from: help_support_screen, support_routes · Source: `app/lib/features/support/screens/support_tickets_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Try again | button | — | local/unclassified action — callback: refresh ⚠  | only checks presence: flutter: `support_centre_test.dart` › My tickets > a failed load shows the real error with retry | presence-only |
| Contact support | button | — | may open SupportTicketFormScreen | — | **GAP** |
| New request | button | — | may open SupportTicketFormScreen | — | **GAP** |
| SUPPORT | gesture | — | local/unclassified action — callback: refresh ⚠  | — | **GAP** |
| {count, plural, =1{1 new reply} other{{count} new replies}} | button | — | may open SupportTicketThreadScreen | flutter: `support_centre_test.dart` › My tickets > lists reference, subject, status chips and unread replies | automated |

#### SupportStatusChip — `support.support_widgets`

Route: opened from: support_ticket_thread_screen, support_tickets_screen · Source: `app/lib/features/support/widgets/support_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| broken image outlined (icon broken_image_outlined) | button | — | opens showDialog; closes screen/sheet | — | **GAP** |
| Close (icon close_rounded) | sheet | — | presents a dialog/picker | — | **GAP** |
| Close (icon close_rounded) | button | — | closes screen/sheet | — | **GAP** |
| Retry upload | button | — | calls POST /v1/support/attachments | — | **GAP** |
| Remove {name} | button | — | local/unclassified action — callback: () => tray.remove(item) ⚠  | appium: `test_19_friends.py` › test_remove_friend_from_menu | automated |

### Navigation & Settings

#### AccountDataScreen — `common.account_data`

Route: opened from: introducer_screen, settings_screen, web_member_workspace · Source: `app/lib/features/common/screens/account_data_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | calls GET /v1/account/{userID}/lifecycle; refreshes data | — | **GAP** |
| Keep my account | button | `qa.account.cancel_deletion_button` | calls DELETE /v1/account/{userID}/deletion, GET /v1/account/{userID}/lifecycle; shows snackbar | appium: `test_15_account_lifecycle.py` › test_delete_requires_confirmation_and_offers_hiding<br>appium: `test_15_account_lifecycle.py` › test_scheduled_deletion_can_be_cancelled | automated |
| Hide my profile | button | `qa.account.pause_toggle_button` | calls POST /v1/account/{userID}/reactivate, GET /v1/account/{userID}/lifecycle, POST /v1/account/{userID}/deactivate; shows snackbar | appium: `test_15_account_lifecycle.py` › test_pause_hides_profile_and_can_be_undone | automated |
| Prepare my data | button | `qa.account.export_button` | calls POST /v1/account/{userID}/export, GET /v1/account/{userID}/lifecycle; opens showDialog; shows snackbar, updates local state | appium: `test_15_account_lifecycle.py` › test_export_produces_the_members_own_data | automated |
| showDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Copy | button | — | closes screen/sheet, copies to clipboard | — | **GAP** |
| Close | button | — | closes screen/sheet | appium: `test_15_account_lifecycle.py` › test_export_produces_the_members_own_data | automated |
| Delete my account | button | `qa.account.delete_button` | calls POST /v1/account/{userID}/deletion, GET /v1/account/{userID}/lifecycle, POST /v1/account/{userID}/deactivate; opens showDialog; closes screen/sheet, pops  | flutter: `account_data_screen_test.dart` › AccountDataScreen > delete asks for confirmation and offers hiding ins<br>appium: `test_15_account_lifecycle.py` › test_account_data_screen_shows_every_journey<br>+2 more | automated |
| Delete your account? | sheet | — | presents a dialog/picker | appium: `test_15_account_lifecycle.py` › test_delete_requires_confirmation_and_offers_hiding | automated |
| Keep my account | button | — | closes screen/sheet, pops a result to caller | appium: `test_15_account_lifecycle.py` › test_delete_requires_confirmation_and_offers_hiding | automated |
| Hide instead | button | — | closes screen/sheet, pops a result to caller | only checks presence: flutter: `account_data_screen_test.dart` › AccountDataScreen > delete asks for confirmation and offers hiding ins | presence-only |
| Delete | button | `qa.account.delete_confirm_button` | closes screen/sheet, pops a result to caller | appium: `test_15_account_lifecycle.py` › test_scheduled_deletion_can_be_cancelled | automated |

#### BlockedUsersScreen — `common.blocked_users`

Route: opened from: privacy_safety_screen, web_member_workspace · Source: `app/lib/features/common/screens/blocked_users_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |
| Unblock | button | — | calls POST /v1/safety/unblock, GET /v1/blocked-users/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| Unblock User | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Unblock | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### EmergencyContactsScreen — `common.emergency_contacts`

Route: opened from: privacy_safety_screen, web_member_workspace · Source: `app/lib/features/common/screens/emergency_contacts_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |
| Add Contact | button | — | calls POST /v1/emergency-contacts/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| Edit (icon edit_outlined) | button | — | calls PUT /v1/emergency-contacts/{userID}/{contactID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| Delete (icon delete_outline) | button | — | calls DELETE /v1/emergency-contacts/{userID}/{contactID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | — | **GAP** |
| Remove Contact | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Remove | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Save | sheet | — | presents a dialog/picker | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup | automated |
| Name | field | — | opens TextField | — | **GAP** |
| Phone Number | field | — | opens TextField | — | **GAP** |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Save | button | — | closes screen/sheet, pops a result to caller | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup | automated |

#### HelpSupportScreen — `common.help_support`

Route: opened from: settings_screen, support_routes, web_member_workspace · Source: `app/lib/features/common/screens/help_support_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| If someone is in immediate danger, contact local emergency s | gesture | — | calls GET /v1/support/tickets; refreshes data | only checks presence: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets | presence-only |
| Contact support | button | — | may open SupportTicketFormScreen | flutter: `support_centre_test.dart` › Help & Support centre > keeps the FAQ and shows contact and My tickets | automated |
| My tickets | button | — | may open SupportTicketsScreen; refreshes data | only checks presence: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets | presence-only |

#### LanguageSettingsScreen — `common.language_settings`

Route: opened from: settings_screen · Source: `app/lib/features/common/screens/language_settings_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Use device language | button | — | calls PATCH /v1/settings/{userID}; shows snackbar | — | **GAP** |
| check circle rounded (icon check_circle_rounded) | button | — | calls PATCH /v1/settings/{userID}; shows snackbar | — | **GAP** |

#### MainNavigationScreen — `common.main_navigation`

Route: app shell (signed-in) · Source: `app/lib/features/common/screens/main_navigation_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Explore more profiles | button | — | local/unclassified action — callback: () => _setSelectedIndex(1) ⚠  | — | **GAP** |
| Discovery preferences | button | — | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | — | **GAP** |
| Messages | button | — | local/unclassified action — callback: () { _setSelectedIndex(1); ref.read(matchesViewProvider.notifier).state = MatchesView.conv ⚠  | — | **GAP** |
| Discovery preferences | button | — | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | — | **GAP** |
| Settings | menu | — | local/unclassified action — callback: _setSelectedIndex | — | **GAP** |
| View | sheet | — | presents a bottom sheet | — | **GAP** |
| Dismiss | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; closes screen/sheet | — | **GAP** |
| View | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open NotificationInboxScreen; closes screen/sheet | — | **GAP** |
| Open | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open NotificationInboxScreen | appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| View call details | sheet | — | presents a bottom sheet | — | **GAP** |
| View call details | button | — | may open NotificationInboxScreen; closes screen/sheet | — | **GAP** |
| filter button | button | `qa.discovery.filter_button` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | appium: `test_03_discover_filters.py` › test_discover_and_filters<br>appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save<br>+3 more | automated |
| shortcut upload | button | `qa.verification.shortcut_upload` | may open VerificationUploadIdScreen | appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>appium: `test_12_verification_safety.py` › test_verification_selfie_from_gallery_submit_reaches_status | automated |
| Edit Profile | button | — | may open EditProfileScreen | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Close (icon close_rounded) | button | `qa.filters.close` | closes screen/sheet | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| age range slider | toggle | `qa.filters.age_range_slider` | local/unclassified action — callback: (values) => setSheetState(() => _filterAge = values) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Country | menu | — | local/unclassified action — callback: (value) => setSheetState(() { _filterCountry = value; _filterState = null; _filterCity = n | — | **GAP** |
| State | menu | — | local/unclassified action — callback: (value) => setSheetState(() { _filterState = value; _filterCity = null; }) | — | **GAP** |
| City | menu | — | local/unclassified action — callback: (value) => setSheetState(() => _filterCity = value) | — | **GAP** |
| Mother Tongue | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterMotherTongue = value, ) | — | **GAP** |
| Religion | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterReligion = value, ) | — | **GAP** |
| Relationship Status | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterRelationshipStatus = value, ) | — | **GAP** |
| Smoking | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterSmoking = value, ) | appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save | automated |
| Drinking | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterDrinking = value, ) | appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save | automated |
| Personality Type | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterPersonalityType = value, ) | — | **GAP** |
| party lover switch | toggle | `qa.filters.party_lover_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterPartyLoverOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| hookup switch | toggle | `qa.filters.hookup_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterHookupOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Open Dating Preferences | button | — | may open SetupPreferencesScreen; closes screen/sheet | — | **GAP** |
| {distance} km | toggle | `qa.filters.distance_slider` | local/unclassified action — callback: (value) => setSheetState( () => _filterDistance = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| verified only switch | toggle | `qa.filters.verified_only_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterVerifiedOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| trust switch | toggle | `qa.filters.trust_switch` | local/unclassified action — callback: (value) { setSheetState(() { trustEnabled = value; }); } | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| trust badge slider | toggle | `qa.filters.trust_badge_slider` | local/unclassified action — callback: trustEnabled ? (value) { setSheetState(() { minimumActiveBadges = value .round(); }); } :  | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| FilterChip onSelected | toggle | — | local/unclassified action — callback: trustEnabled ? (value) { setSheetState(() { if (value) { requiredBadgeCodes.add( badge.cod | — | **GAP** |
| Reset | button | `qa.filters.reset_button` | local/unclassified action — callback: trustState.isSaving ? null : () { setSheetState(() { _filterAge = const RangeValues( 20, 5 ⚠  | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Apply | button | `qa.filters.apply_button` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; closes screen/sheet, refreshes data, shows snackbar | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+5 more | automated |

#### ModerationAppealsScreen — `common.moderation_appeals`

Route: opened from: matches_list_screen, privacy_safety_screen, profile_details_screen, web_member_workspace · Source: `app/lib/features/common/screens/moderation_appeals_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Reason | field | — | opens TextField | — | **GAP** |
| Report ID (optional) | field | — | opens TextField | — | **GAP** |
| Additional context (optional) | field | — | opens TextField | — | **GAP** |
| Submit appeal | button | — | calls POST /v1/moderation/appeals, GET /v1/moderation/appeals; shows snackbar, updates local state | — | **GAP** |
| Retry | button | — | refreshes data | — | **GAP** |
| Reviewed by: {reviewer} | gesture | — | calls GET /v1/moderation/appeals; refreshes data | — | **GAP** |

#### NotificationSettingsScreen — `common.notification_settings`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/common/screens/notification_settings_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Notification inbox | button | — | may open NotificationInboxScreen | — | **GAP** |
| In-app notifications | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Push notifications | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | flutter: `settings_controls_test.dart` › notification save failure rolls back and shows error<br>flutter: `settings_controls_test.dart` › privacy ${entry.key} saves both directions | automated |
| New matches | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| New messages | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Likes | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Match nudges | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Incoming calls | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Safety updates | toggle | — | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |
| Friends' date plans | toggle | `qa.notifications.friend_plans` | calls PATCH /v1/notifications/{userID}/preferences | — | **GAP** |

#### PrivacySafetyScreen — `common.privacy_safety`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/common/screens/privacy_safety_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | — | **GAP** |
| Show age | toggle | — | calls PATCH /v1/settings/{userID} | — | **GAP** |
| Show exact distance | toggle | — | calls PATCH /v1/settings/{userID} | playwright: `app-member-workspace.spec.js` › privacy toggle persists and keeps the stored theme and language | automated |
| Show online status | toggle | — | calls PATCH /v1/settings/{userID} | — | **GAP** |
| Emergency SOS | button | `qa.safety.sos_journey` | may open SosScreen | — | **GAP** |
| Emergency Contacts | button | — | may open EmergencyContactsScreen | — | **GAP** |
| Blocked Users | button | — | may open BlockedUsersScreen | — | **GAP** |
| Moderation Appeals | button | — | may open ModerationAppealsScreen | — | **GAP** |
| Let people find me in friend search | toggle | `qa.privacy.friend_search` | calls PUT /v1/friends/{userID}/search-visibility, PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | flutter: `friend_search_visibility_test.dart` › privacy switch turns friend search off and back on<br>flutter: `friend_search_visibility_test.dart` › a failed save puts the switch back and explains | automated |
| Show my public writing on my profile | toggle | `qa.privacy.profile_showcase` | calls PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | — | **GAP** |
| Share crash reports | toggle | `qa.privacy.crash_reports` | local/unclassified action — callback: (v) => reporter.setOptIn(enabled: v) | flutter: `privacy_crash_reports_test.dart` › Share crash reports is on by default and persists toggles | automated |
| Resume | button | `qa.graduation.discovery_resume` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | — | **GAP** |
| Pause | button | `qa.graduation.discovery_pause` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | — | **GAP** |

#### SettingsScreen — `common.settings`

Route: #/settings (web) / bottom nav: Settings tab (mobile) · Source: `app/lib/features/common/screens/settings_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Your dating rhythm | button | — | may open DatingRhythmScreen | playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| Your profile stories | button | — | may open ProfileStoriesScreen | — | **GAP** |
| Blog · Open Chapters | button | — | may open BlogScreen | — | **GAP** |
| Edit Profile | button | — | may open EditProfileScreen | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Photos | button | — | may open SetupPhotosScreen | — | **GAP** |
| Language | button | `qa.settings.language` | may open LanguageSettingsScreen | — | **GAP** |
| Dating Preferences | button | — | may open SetupPreferencesScreen | — | **GAP** |
| Account & Data | button | — | may open AccountDataScreen | appium: `test_15_account_lifecycle.py` › test_account_data_screen_shows_every_journey<br>appium: `test_15_account_lifecycle.py` › test_pause_hides_profile_and_can_be_undone<br>+3 more | automated |
| Notifications | button | — | may open NotificationSettingsScreen | — | **GAP** |
| Trust Badges | button | — | may open TrustBadgesScreen | — | **GAP** |
| Trust Filters | button | — | may open TrustFilterScreen | — | **GAP** |
| Conversation Rooms | button | — | may open ConversationRoomsScreen | — | **GAP** |
| Friends & Connections | button | — | may open FriendsScreen | appium: `test_19_friends.py` › test_friend_search_sends_request_to_counterpart<br>appium: `test_19_friends.py` › test_remove_friend_from_menu<br>+1 more | automated |
| Call History | button | — | may open CallHistoryScreen | — | **GAP** |
| Match Nudges | button | — | may open MatchNudgesScreen | — | **GAP** |
| Subscriptions | button | — | may open SubscriptionScreen | — | **GAP** |
| Privacy & Safety | button | — | may open PrivacySafetyScreen | playwright: `app-member-workspace.spec.js` › phone: a screen opened from Settings goes back to Settings<br>playwright: `profile-cinematic.spec.js` › back, forward and reload across profile and privacy keep the member si<br>+1 more | automated |
| Government Verification | button | `qa.settings.government_verification` | may open VerificationLandingScreen | appium: `test_12_verification_safety.py` › test_verification_landing_renders | automated |
| QA Verification Upload | button | `qa.settings.verification_upload` | may open VerificationUploadIdScreen | appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>appium: `test_12_verification_safety.py` › test_verification_selfie_from_gallery_submit_reaches_status | automated |
| Help & Support | button | — | may open HelpSupportScreen | — | **GAP** |
| About | button | — | may open AboutAppScreen | — | **GAP** |
| Logout | button | — | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open WelcomeScreen; refreshes data | — | **GAP** |
| Could not save your theme. Please try again. | toggle | `qa.settings.theme_selector` | calls PATCH /v1/settings/{userID}; shows snackbar | flutter: `settings_controls_test.dart` › appearance saves light dark and system themes | automated |
| check circle (icon check_circle) | button | `qa.settings.theme_preset.*` | calls PATCH /v1/settings/{userID}; opens showGeneralDialog; closes screen/sheet, shows snackbar | flutter: `settings_controls_test.dart` › appearance saves and previews the Deep Field preset | automated |

#### ActivityHero — `common.activity_visuals`

Route: opened from: clubs_screen, my_lists_screen, photo_themes_screen · Source: `app/lib/features/common/widgets/activity_visuals.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Spoiler — tap to reveal | button | — | updates local state | only checks presence: flutter: `clubs_data_test.dart` › ClubDetailScreen shows the pick and collapses spoilers | presence-only |

#### CommunityActions — `common.community_actions`

Route: embedded / not directly routed · Source: `app/lib/features/common/widgets/community_actions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Cancel | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| FilledButton onPressed | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report could not be submitted. | button | — | calls POST /v1/blog/reports/{kind}/{contentID} | — | **GAP** |

#### ReportUserSheet — `common.report_user_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/common/widgets/report_user_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Reason | menu | — | updates local state | — | **GAP** |
| Description (optional) | field | — | opens TextField | — | **GAP** |

#### AboutAppScreen — `common.about_app`

Route: see screen matrix · Source: `app/lib/features/common/screens/about_app_screen.dart` · in screen matrix

_No interactive control detected in this file by static extraction (display-only, or controls live in shared child widgets listed under their own feature)._

| Case | Type | Automated by | Status |
|---|---|---|---|
| AboutAppScreen lays out on every device size/theme | layout | flutter: `screen_matrix_test.dart` › $screenLabel lays out on $deviceLabel [$themeLabel] | automated |
| AboutAppScreen meets accessibility guidelines | a11y | flutter: `screen_accessibility_test.dart` › $label meets accessibility guidelines [$themeLabel] | automated |
| AboutAppScreen shows a visible way back when pushed | a11y | flutter: `back_affordance_audit_test.dart` › ${entry.key} shows a way back when pushed | automated |

### Web Workspace

#### WebIcebreakerPage — `web.web_icebreaker_page`

Route: embedded / not directly routed · Source: `app/lib/features/web/web_icebreaker_page.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Open my matches | button | — | local/unclassified action — callback: () => setWebRoute('/matches') ⚠  | — | **GAP** |

#### WebMemberWorkspace — `web.web_member_workspace`

Route: opened from: main · Source: `app/lib/features/web/web_member_workspace.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| north east rounded (icon north_east_rounded) | button | — | updates local state | — | **GAP** |
| Back to Discover | button | — | routes to /discover; updates local state | flutter: `web_member_workspace_test.dart` › a destination switched off while open is replaced, not shown<br>playwright: `app-member-workspace.spec.js` › unknown routes show a recoverable not-found page | automated |
| Back to Discover | button | — | routes to /discover; updates local state | flutter: `web_member_workspace_test.dart` › a destination switched off while open is replaced, not shown<br>playwright: `app-member-workspace.spec.js` › unknown routes show a recoverable not-found page | automated |
| BackButton onPressed | button | — | updates local state | — | **GAP** |
| All features | button | — | routes to /features; updates local state | flutter: `web_member_workspace_test.dart` › shell pages meet accessibility guidelines on ${entry.key}<br>playwright: `website.spec.js` › browser login, live stream, deep links, preferences and reload recover | automated |
| Connect website | button | — | local/unclassified action — callback: openWebsiteHome ⚠  | — | **GAP** |
| Sign out | button | — | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID} | playwright: `photo-upload.spec.js` › browser upload, reload and onboarding completion preserve the auth gat<br>playwright: `website.spec.js` › browser login, live stream, deep links, preferences and reload recover | automated |
| _SidebarItem onTap | button | — | updates local state | — | **GAP** |

#### WebMembershipPage — `web.web_membership_page`

Route: embedded / not directly routed · Source: `app/lib/features/web/web_membership_page.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Monthly | toggle | — | updates local state | — | **GAP** |
| Retry | button | — | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account | — | **GAP** |

#### WebEntryScreen — `web.web_entry`

Route: see screen matrix · Source: `app/lib/features/web/web_entry_screen.dart` · in screen matrix

_No interactive control detected in this file by static extraction (display-only, or controls live in shared child widgets listed under their own feature)._

| Case | Type | Automated by | Status |
|---|---|---|---|
| WebEntryScreen lays out on every device size/theme | layout | flutter: `screen_matrix_test.dart` › $screenLabel lays out on $deviceLabel [$themeLabel] | automated |
| WebEntryScreen meets accessibility guidelines | a11y | flutter: `screen_accessibility_test.dart` › $label meets accessibility guidelines [$themeLabel] | automated |

### Shared components

#### RichBody — `core.rich_document_view`

Route: opened from: blog_editor, blog_screen, profile_stories · Source: `app/lib/core/rich_text/rich_document_view.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Open this link? | sheet | — | presents a dialog/picker | only checks presence: flutter: `rich_text_widgets_test.dart` › RichDocumentView > renders formatting with semantic headings and safe  | presence-only |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Open link | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### RichTextEditor — `core.rich_text_editor`

Route: opened from: blog_editor, profile_stories · Source: `app/lib/core/rich_text/rich_text_editor.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| TextFormField input | field | — | opens TextFormField | — | **GAP** |
| style | toggle | — | local/unclassified action — callback: (style) => c.style = style | — | **GAP** |
| Text style | menu | — | local/unclassified action — callback: (type) => editor.run(() => c.setBlockType(type)) | — | **GAP** |
| Alignment | menu | — | local/unclassified action — callback: (align) => editor.run(() => c.setAlign(align)) | — | **GAP** |
| Web address | field | — | closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Remove link | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Add link | button | — | closes screen/sheet, pops a result to caller, updates local state | — | **GAP** |

#### SheetCloseBar — `core.sheet_close_bar`

Route: opened from: club_widgets, connection_card, group_widgets, photo_theme_widgets · Source: `app/lib/core/widgets/sheet_close_bar.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Close (icon close_rounded) | button | — | closes screen/sheet | — | **GAP** |

### End-to-end journeys

#### Multi-screen journeys — `journeys.e2e`

Route: mobile (Appium) / web (Playwright) / API (api_e2e) · Source: `qa/appium/tests`, `qa/api_e2e/tests`, `website/tests`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Sign up → terms → profile setup (photos, about, preferences, preview) → Discover | happy | appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup<br>appium: `test_02_profile_setup_edges.py` › test_signup_validation_blocks_invalid_username<br>+8 more | automated |
| Sign in with existing credentials lands on Discover; wrong password shows error | happy | appium: `test_01b_signin_credentials_existing_account.py` › test_existing_account_username_signin_reaches_authenticated_surface<br>appium: `test_13_core_dating_journey.py` › test_username_login_discovery_match_and_chat_restart_resume<br>+5 more | automated |
| Like → mutual like → match screen → unlock chat → send first message → other member receives | happy | playwright: `app-member-workspace.spec.js` › WEB-08: a new match can send a first message<br>api_e2e: `test_02_discovery_match_chat.py` › test_like_appears_in_liked_me_then_mutual_like_creates_match<br>+1 more | automated |
| Send a gift in chat: free daily gift, coin gift, insufficient coins → wallet top-up | happy | appium: `test_00_seed_preflight.py` › test_seeded_matches_chat_gifts_and_wallet<br>appium: `test_05_chat_gifts_contract_api.py` › test_chat_gift_wallet_contract_matrix<br>+8 more | automated |
| Upgrade plan via checkout (sandbox/Stripe test), auto-renew off, wallet coin purchase | happy | appium: `test_00_seed_preflight.py` › test_seeded_matches_chat_gifts_and_wallet<br>appium: `test_05_chat_gifts_contract_api.py` › test_chat_gift_wallet_contract_matrix<br>+4 more | automated |
| Report and block a member; blocked member disappears everywhere; appeal flow | happy | appium: `test_05_profile_details.py` › test_discovery_profile_detail_report_entry_renders<br>appium: `test_12_verification_safety.py` › test_profile_report_submit_success<br>+8 more | automated |
| Add friend → accept → open friend chat → send message | happy | appium: `test_19_friends.py` › test_friend_search_sends_request_to_counterpart<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat<br>+8 more | automated |
| Join a room / create a group → invite → group chat | happy | appium: `test_11_engagement_surfaces_api.py` › test_community_groups_list_contract<br>appium: `test_20_conversation_rooms.py` › test_rooms_list_join_send_and_leave<br>+8 more | automated |
| Propose date plan → partner accepts → friend fan-out → debrief after the date | happy | api_e2e: `test_15_social_graph_dating_extras.py` › test_date_plan_state_machine | automated |
| Download data, pause discovery, delete account | happy | appium: `test_15_account_lifecycle.py` › test_export_produces_the_members_own_data<br>appium: `test_15_account_lifecycle.py` › test_delete_requires_confirmation_and_offers_hiding<br>+8 more | automated |
| Upload ID + selfie → pending → approved by operator | happy | appium: `test_12_verification_safety.py` › test_verification_landing_renders<br>appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>+2 more | automated |
| Change look and language in Settings; persists after restart | happy | appium: `test_23_settings_theme_privacy.py` › test_theme_strip_snow_and_gothic_persist_to_account<br>playwright: `a11y-smoke.spec.js` › a11y smoke ${url} [${locale.hreflang}]<br>+8 more | automated |
| Back from every pushed screen returns to the opener (Android back + on-screen back) | happy | appium: `test_05_profile_details.py` › test_discovery_profile_detail_back_preserves_deck<br>appium: `test_22_back_navigation_today.py` › test_system_back_from_tab_returns_to_today<br>+5 more | automated |

### Website (public)

#### Shared header/footer (all public pages) — `site.site_header`

Route: / , /features, /safety, /contact, /membership, /guidelines, /privacy (+ /{de,en-gb,es,fr,it,nl,pl,pt,ru}/...) · Source: `website/public/site.js`, `website/generate_pages.py`, `website/locales/`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Language (select[data-lang-switch]) | menu | — | navigates to the same page in the chosen locale (site.js change handler sets location.href) | playwright: `public-pages.spec.js` › locale switcher moves between every locale on the same page | automated |
| Open menu (.menu-toggle) | button | — | toggles aria-expanded and the mobile nav (<=1000px) | playwright: `responsive.spec.js` › WEB-04: menu button drives the nav up to 1000px, inline nav from 1001p<br>playwright: `responsive.spec.js` › open phone menu stays within the viewport and does not cover the heade<br>+1 more | automated |
| Features / How it works / Safety / Sign in / Join | link | — | navigates to page or /app/#/signin, /app/#/signup; closes mobile menu | playwright: `public-pages.spec.js` › header navigation, skip link and mobile menu work in every locale<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>+2 more | automated |
| Skip to content | link | — | moves focus to #main | playwright: `public-pages.spec.js` › header navigation, skip link and mobile menu work in every locale | automated |
| Footer: Contact, Privacy, Guidelines, Safety, Membership | link | — | navigates to the localized page | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Every internal link, asset and app deep link resolves | happy | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |
| Public pages pass axe smoke, heading order and visible focus | a11y | playwright: `a11y-smoke.spec.js` › WEB-05: heading levels never skip on generated pages<br>playwright: `a11y-smoke.spec.js` › a11y smoke ${url} [${locale.hreflang}]<br>+3 more | automated |
| Every browser-facing response carries security headers (CSP etc.) | negative | playwright: `website.spec.js` › every browser-facing response carries security headers<br>playwright: `website.spec.js` › website rejects untrusted hosts and oversized proxy bodies | automated |

#### Home page — `site.index`

Route: / (+9 locale prefixes) · Source: `website/public/index.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create account / Join | link | — | opens /app/#/signup | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |
| Sign in | link | — | opens /app/#/signin | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |
| FAQ <details> items | toggle | — | expand/collapse answers | playwright: `website.spec.js` › mobile navigation and FAQ operate with keyboard and touch targets | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Home renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Features page — `site.features`

Route: /features (+9 locale prefixes) · Source: `website/public/features.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Find a feature (#feature-search) | field | — | filters feature cards live; announces result count politely | playwright: `public-forms.spec.js` › feature search is keyboard operable and announces results politely<br>playwright: `website.spec.js` › feature search, empty results and recovery<br>+1 more | automated |
| Feature card deep links (/app/#/discover, /matches, /prefere | link | — | opens the web app route | playwright: `links.spec.js` › every internal link, asset and app deep link resolves | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Features renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Safety page — `site.safety`

Route: /safety (+9 locale prefixes) · Source: `website/public/safety.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Safety resources / Contact links | link | — | navigates | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Safety renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Membership page — `site.membership`

Route: /membership (+9 locale prefixes) · Source: `website/public/membership.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Plan call-to-action | link | — | opens /app/#/membership (sign-in gated) | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Membership renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Community guidelines page — `site.guidelines`

Route: /guidelines (+9 locale prefixes) · Source: `website/public/guidelines.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Links | link | — | navigates | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Community guidelines renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Privacy page — `site.privacy`

Route: /privacy (+9 locale prefixes) · Source: `website/public/privacy.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Links | link | — | navigates | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Privacy renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name}<br>+1 more | automated |

#### Contact page — `site.contact`

Route: /contact (+locales) · Source: `website/public/contact.html`, `website/public/contact.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Email (#contact-email) | field | — | required, validated email | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted<br>+1 more | automated |
| Name (#contact-name, optional) | field | — | optional; omitted from payload when empty | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted | automated |
| Category (#contact-category) | menu | — | required select | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted<br>+1 more | automated |
| Subject (#contact-subject) | field | — | 4-120 chars | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted<br>+1 more | automated |
| Description (#contact-description) + live counter | field | — | required, max 5000 | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted<br>+1 more | automated |
| Hidden website honeypot (#contact-website) | field | — | bots filling it are dropped | playwright: `contact.spec.js` › honeypot is present, hidden from people and skipped by keyboard | automated |
| Send (#contact-submit) | button | — | client-validates, then POST /v1/support/contact with locale; shows reference number | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted<br>+3 more | automated |
| Send another message (#contact-again) | button | — | resets the form for a new message | — | **GAP** |
| Error summary links | link | — | focus the invalid field | playwright: `contact.spec.js` › client validation lists errors, focuses the summary and sends nothing | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Honeypot hidden from people and skipped by keyboard | a11y | playwright: `contact.spec.js` › honeypot is present, hidden from people and skipped by keyboard | automated |
| Localized contact page sends its locale and shows translated copy | l10n | playwright: `contact.spec.js` › localised contact page sends its locale and shows translated copy | automated |
| POST /v1/support/contact validates and stores the message | happy | api_e2e: `test_16_flags_realtime_media.py` › test_support_ticketing_gate_holds_while_the_flag_is_off<br>go: `support_tickets_test.go` › TestSupportRoleAccessToAdminRoutes | automated |

#### Shared story page — `site.story`

Route: /story.html?id=<publication> · Source: `website/public/story.html`, `website/public/story.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Share (#share) | button | — | navigator.share or copy fallback | — | **GAP** |
| Copy link (#copy) | button | — | copies share URL to clipboard | — | **GAP** |
| Retry (#retry) | button | — | re-fetches the publication | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials | automated |
| Report reason (#reason) | menu | — | required | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials | automated |
| Report description (#description) | field | — | max 1000 | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials | automated |
| Send report (#report-submit) | button | — | POST {endpoint}/report without credentials | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials | automated |
| Start your own chapter / Join | link | — | opens /chapter.html or /app/#/signup | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Approved story renders safe DOM at phone/desktop widths | happy | playwright: `blog-public.spec.js` › approved story renders safely at ${width}px<br>playwright: `blog-public.spec.js` › formatted excerpt renders as safe DOM in the chosen writing style<br>+1 more | automated |
| Withdrawn/invalid links clear content and never fetch a bad source | negative | playwright: `blog-public.spec.js` › withdrawn link clears its previously displayed content<br>playwright: `blog-public.spec.js` › incomplete links never fetch a source | automated |
| Copy and Share produce the canonical share URL | happy | — | **GAP** |

#### Pass the Chapter (public studio) — `site.chapter`

Route: /chapter.html[?scene=&beginning=&surprise=\|?share=] · Source: `website/public/chapter.html`, `website/public/chapter.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Beginning / surprise choice buttons (aria-pressed) | toggle | — | select options; updates remix URL | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset | automated |
| Copy remix link (#copy) | button | — | copies remix URL | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset | automated |
| Share (#share) | button | — | navigator.share or copy | — | **GAP** |
| Start again (#reset) | button | — | clears choices | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset | automated |
| Join Connect | link | — | opens /app/#/signup | playwright: `links.spec.js` › every internal link, asset and app deep link resolves<br>playwright: `links.spec.js` › same-page and cross-page anchors land on an element<br>+1 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Choose, copy a remix link, reopen it and reset | happy | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset | automated |
| Tampered remix links degrade safely (no XSS) | negative | playwright: `public-forms.spec.js` › Pass the Chapter: tampered remix links degrade safely | automated |
| Missing shared card shows a calm error | negative | playwright: `public-forms.spec.js` › Pass the Chapter: a missing shared card shows a calm error, no studio | automated |

### Operator console

#### Analytics — `console.analytics`

Route: control-panel /analytics/ · Source: `control-panel/control_panel/views_analytics.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| analytics overview | link | — | page → /analytics/ (views_analytics.analytics_overview) | django: `test_analytics.py` › test_login_required<br>django: `test_analytics.py` › test_overview_renders_tiles_chart_and_table_with_suppression<br>+1 more | automated |
| analytics funnel | link | — | page → /analytics/funnel/ (views_analytics.analytics_funnel) | django: `test_analytics.py` › test_member_role_sees_role_message<br>django: `test_analytics.py` › test_funnel_forwards_window_and_renders_both_tables<br>+1 more | automated |
| analytics retention | link | — | page → /analytics/retention/ (views_analytics.analytics_retention) | django: `test_analytics.py` › test_retention_heatmap_and_experiment<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| analytics engagement | link | — | page → /analytics/engagement/ (views_analytics.analytics_engagement) | django: `test_analytics.py` › test_invalid_filters_are_not_forwarded<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| analytics liquidity | link | — | page → /analytics/liquidity/ (views_analytics.analytics_liquidity) | django: `test_analytics.py` › test_liquidity_and_safety_escape_member_text<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| analytics safety | link | — | page → /analytics/safety/ (views_analytics.analytics_safety) | django: `test_analytics.py` › test_liquidity_and_safety_escape_member_text<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| analytics data | link | — | page → /analytics/data/ (views_analytics.analytics_data) | django: `test_analytics.py` › test_data_page_rebuild_and_flags<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| analytics rebuild | button | — | POST form → /analytics/data/rebuild/ (views_analytics.analytics_rebuild) | django: `test_analytics.py` › test_data_page_rebuild_and_flags<br>django: `test_analytics.py` › test_mutations_require_csrf<br>+1 more | automated |
| analytics exclude | button | — | POST form → /analytics/data/exclusions/ (views_analytics.analytics_exclude) | django: `test_analytics.py` › test_data_page_rebuild_and_flags | partial |
| analytics include | button | — | POST form → /analytics/data/exclusions/<uuid:member_id>/remove/ (views_analytics.analytics_include) | django: `test_analytics.py` › test_data_page_rebuild_and_flags | partial |
| analytics export | link | — | download/stream → /analytics/export/<slug:report>/ (views_analytics.analytics_export) | django: `test_analytics.py` › test_csv_export_streams_and_whitelists_params<br>django: `test_analytics.py` › test_csv_export_error_redirects | automated |

#### Business reports — `console.business`

Route: control-panel /business/ · Source: `control-panel/control_panel/views_business.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| business revenue | link | — | page → /business/ (views_business.business_revenue) | django: `test_business.py` › test_login_required<br>django: `test_business.py` › test_empty_revenue_explains_release_one<br>+2 more | automated |
| business subscriptions | link | — | page → /business/subscriptions/ (views_business.business_subscriptions) | django: `test_business.py` › test_subscriptions_waterfall_uses_one_currency<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business conversion | link | — | page → /business/conversion/ (views_business.business_conversion) | django: `test_business.py` › test_conversion_page_calls_conversion_and_funnel<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business coins | link | — | page → /business/coins/ (views_business.business_coins) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business referrals | link | — | page → /business/referrals/ (views_business.business_referrals) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business markets | link | — | page → /business/markets/ (views_business.business_markets) | django: `test_business.py` › test_markets_shows_status_and_saves_gates<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business market save | button | — | POST form → /business/markets/save/ (views_business.business_market_save) | django: `test_business.py` › test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › test_invalid_market_targets_do_not_call_api | partial |
| business investor pack | link | — | download/stream → /business/investor-pack/ (views_business.business_investor_pack) | django: `test_business.py` › test_investor_pack_is_printable_and_flags_missing_spend | automated |
| business spend | link | — | page → /business/spend/ (views_business.business_spend) | django: `test_business.py` › test_spend_form_records_and_deletes<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| business spend save | button | — | POST form → /business/spend/save/ (views_business.business_spend_save) | django: `test_business.py` › test_spend_form_records_and_deletes<br>django: `test_business.py` › test_spend_rejects_bad_month_and_shows_api_errors<br>+2 more | automated |
| business spend delete | button | — | POST form → /business/spend/<str:spend_id>/delete/ (views_business.business_spend_delete) | django: `test_business.py` › test_spend_form_records_and_deletes | partial |
| business csv | link | — | download/stream → /business/csv/<str:report>/ (views_business.business_csv) | django: `test_business.py` › test_csv_download_proxies_table_and_filters | automated |

#### Engagement admin — `console.engagement`

Route: control-panel /engagement/ · Source: `control-panel/control_panel/views.py`, `control-panel/control_panel/views_photo_themes.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| photo themes | link | — | page → /engagement/photo-themes/ (views_photo_themes.photo_themes) | django: `test_photo_themes.py` › test_requires_login_and_csrf<br>django: `test_photo_themes.py` › test_lists_themes_escaped<br>+1 more | automated |
| photo theme save | button | — | POST form → /engagement/photo-themes/save/ (views_photo_themes.photo_theme_save) | django: `test_photo_themes.py` › test_requires_login_and_csrf<br>django: `test_photo_themes.py` › test_save_validates_before_calling_api<br>+1 more | automated |
| engagement prompts | link | — | page → /engagement/prompts/ (views.engagement_prompts) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| engagement prompt new | button | — | POST form → /engagement/prompts/new/ (views.engagement_prompt_new) | — | **GAP** |
| engagement prompt edit | button | — | POST form → /engagement/prompts/<str:prompt_id>/edit/ (views.engagement_prompt_edit) | — | **GAP** |
| engagement prompt activate | button | — | POST form → /engagement/prompts/<str:prompt_id>/activate/ (views.engagement_prompt_activate) | — | **GAP** |
| engagement nudges | link | — | page → /engagement/nudges/ (views.engagement_nudges) | django: `test_views.py` › test_engagement_nudges_renders_durable_delivery_state<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |

#### Moderation: rooms — `console.moderation_rooms`

Route: control-panel /moderation/rooms/ · Source: `control-panel/control_panel/views_rooms.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| rooms | link | — | page → /moderation/rooms/ (views_rooms.rooms) | django: `test_rooms.py` › test_requires_login_and_csrf<br>django: `test_rooms.py` › test_lists_and_filters_rooms_escaped<br>+2 more | automated |
| room detail | link | — | page → /moderation/rooms/<uuid:room_id>/ (views_rooms.room_detail) | django: `test_rooms.py` › test_detail_shows_room_actions_and_people<br>django: `test_rooms.py` › test_detail_lists_members_with_per_member_actions<br>+1 more | automated |
| room action | button | — | POST form → /moderation/rooms/<uuid:room_id>/actions/ (views_rooms.room_action) | django: `test_rooms.py` › test_requires_login_and_csrf<br>django: `test_rooms.py` › test_member_row_unmute_uses_the_action_flow<br>+4 more | automated |
| room role | button | — | POST form → /moderation/rooms/<uuid:room_id>/roles/ (views_rooms.room_role) | django: `test_rooms.py` › test_requires_login_and_csrf<br>django: `test_rooms.py` › test_appoint_and_revoke_moderators<br>+1 more | automated |

#### Moderation: group covers — `console.moderation_group_covers`

Route: control-panel /moderation/group-covers/ · Source: `control-panel/control_panel/views_group_covers.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| group covers | link | — | page → /moderation/group-covers/ (views_group_covers.group_covers) | django: `test_group_covers.py` › test_requires_login_and_csrf<br>django: `test_group_covers.py` › test_pending_queue_lists_covers_with_actions<br>+3 more | automated |
| group cover content | link | — | download/stream → /moderation/group-covers/<uuid:cover_id>/content/ (views_group_covers.group_cover_content) | django: `test_group_covers.py` › test_requires_login_and_csrf<br>django: `test_group_covers.py` › test_pending_queue_lists_covers_with_actions<br>+1 more | automated |
| group cover decision | button | — | POST form → /moderation/group-covers/<uuid:cover_id>/decision/ (views_group_covers.group_cover_decision) | django: `test_group_covers.py` › test_requires_login_and_csrf<br>django: `test_group_covers.py` › test_pending_queue_lists_covers_with_actions<br>+4 more | automated |

#### Moderation: blog — `console.moderation_blog`

Route: control-panel /moderation/blog/ · Source: `control-panel/control_panel/views_blog.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| blog reviews | link | — | page → /moderation/blog/ (views_blog.blog_reviews) | django: `test_blog.py` › test_login_and_csrf<br>django: `test_blog.py` › test_evidence_and_appeals_are_escaped<br>+4 more | automated |
| blog decision | button | — | POST form → /moderation/blog/<uuid:case_id>/decision/ (views_blog.blog_decision) | django: `test_blog.py` › test_login_and_csrf<br>django: `test_blog.py` › test_decision_uses_version_and_backend_error<br>+2 more | automated |
| blog evidence | link | — | download/stream → /moderation/blog/<uuid:case_id>/photos/<uuid:photo_id>/ (views_blog.blog_evidence) | django: `test_blog.py` › test_evidence_never_cached_or_executed | automated |

#### City pilot — `console.city_pilot`

Route: control-panel /city-pilot/ · Source: `control-panel/control_panel/views_city_pilot.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| city pilot | link | — | page → /city-pilot/ (views_city_pilot.city_pilot) | django: `test_city_pilot.py` › test_operator_login_required<br>django: `test_city_pilot.py` › test_empty_pilot_shows_configuration<br>+2 more | automated |
| city pilot save | button | — | POST form → /city-pilot/save/ (views_city_pilot.city_pilot_save) | django: `test_city_pilot.py` › test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › test_invalid_dates_do_not_call_api | partial |
| city pilot stage | button | — | POST form → /city-pilot/<uuid:pilot_id>/stage/ (views_city_pilot.city_pilot_stage) | django: `test_city_pilot.py` › test_failed_gate_error_is_displayed<br>django: `test_city_pilot.py` › test_csrf_required_for_stage_changes<br>+1 more | automated |
| city pilot experience create | button | — | POST form → /city-pilot/<uuid:pilot_id>/experiences/ (views_city_pilot.city_pilot_experience_create) | — | **GAP** |
| city pilot experience cancel | button | — | POST form → /city-pilot/<uuid:pilot_id>/experiences/<uuid:event_id>/cancel/ (views_city_pilot.city_pilot_experience_cancel) | — | **GAP** |

#### Auth — `console.login`

Route: control-panel /login/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| operator login | button | — | POST form → /login/ (views.operator_login) | django: `test_views.py` › test_console_redirects_anonymous_operator_to_login<br>django: `test_views.py` › test_login_requires_bff_operator_authorization<br>+5 more | automated |

#### Auth — `console.logout`

Route: control-panel /logout/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| operator logout | button | — | POST form → /logout/ (views.operator_logout) | django: `test_views.py` › test_logout_flushes_operator_session | partial |

#### Dashboard — `console.dashboard`

Route: control-panel // · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| dashboard | link | — | page → / (views.dashboard) | django: `test_analytics.py` › test_dashboard_uses_durable_snapshot_kpis<br>django: `test_analytics.py` › test_dashboard_falls_back_to_live_activity_without_analyst_role<br>+4 more | automated |

#### Verification queue — `console.verifications`

Route: control-panel /verifications/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| verification queue | link | — | page → /verifications/ (views.verification_queue) | django: `test_views.py` › test_approve_redirects_with_success<br>django: `test_views.py` › test_reject_requires_reason<br>+1 more | automated |
| approve verification | link | — | page → /verifications/<str:user_id>/approve/ (views.approve_verification) | django: `test_views.py` › test_approve_redirects_with_success | automated |
| reject verification | link | — | page → /verifications/<str:user_id>/reject/ (views.reject_verification) | django: `test_views.py` › test_reject_requires_reason | automated |

#### Activity feed — `console.activities`

Route: control-panel /activities/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| activity feed | link | — | page → /activities/ (views.activity_feed) | django: `test_views.py` › test_activity_feed_filters_latest_events<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |

#### Audit log — `console.audit`

Route: control-panel /audit/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| audit log | link | — | page → /audit/ (views.audit_log) | django: `test_views.py` › test_operator_audit_page_forwards_filters<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |

#### Domain events — `console.events`

Route: control-panel /events/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| domain events | link | — | page → /events/ (views.domain_events) | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |

#### Client errors — `console.client_errors`

Route: control-panel /client-errors/ · Source: `control-panel/control_panel/views_client_errors.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| client errors | link | — | page → /client-errors/ (views_client_errors.client_errors) | django: `test_client_errors.py` › test_requires_login_and_csrf<br>django: `test_client_errors.py` › test_list_renders_issues_summary_and_privacy_note<br>+5 more | automated |
| client error detail | link | — | page → /client-errors/<uuid:issue_id>/ (views_client_errors.client_error_detail) | django: `test_client_errors.py` › test_requires_login_and_csrf<br>django: `test_client_errors.py` › test_list_renders_issues_summary_and_privacy_note<br>+4 more | automated |
| client error status | button | — | POST form → /client-errors/<uuid:issue_id>/status/ (views_client_errors.client_error_status) | django: `test_client_errors.py` › test_requires_login_and_csrf<br>django: `test_client_errors.py` › test_detail_renders_and_escapes_report_text<br>+4 more | automated |

#### Appeals — `console.appeals`

Route: control-panel /appeals/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| appeal queue | link | — | page → /appeals/ (views.appeal_queue) | django: `test_views.py` › test_appeal_queue_renders<br>django: `test_views.py` › test_action_appeal_redirects<br>+1 more | automated |
| action appeal | link | — | page → /appeals/<str:appeal_id>/action/ (views.action_appeal) | django: `test_views.py` › test_action_appeal_redirects | automated |

#### Support desk — `console.support`

Route: control-panel /support/ · Source: `control-panel/control_panel/views_support.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| support queue | link | — | page → /support/ (views_support.support_queue) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>+4 more | automated |
| support export | link | — | download/stream → /support/export/ (views_support.support_export) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>+2 more | automated |
| support bulk | button | — | POST form → /support/bulk/ (views_support.support_bulk) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>+4 more | automated |
| support dashboard | link | — | page → /support/dashboard/ (views_support.support_dashboard) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_dashboard_renders_kpis_charts_and_safety<br>+3 more | automated |
| support canned responses | link | — | page → /support/canned/ (views_support.support_canned_responses) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_list_includes_inactive_and_placeholder_help<br>+1 more | automated |
| support canned save | button | — | POST form → /support/canned/save/ (views_support.support_canned_save) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_analyst_sees_no_mutation_controls_and_posts_are_refused<br>+3 more | automated |
| support canned deactivate | button | — | POST form → /support/canned/<uuid:response_id>/deactivate/ (views_support.support_canned_deactivate) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_list_includes_inactive_and_placeholder_help<br>+2 more | automated |
| support attachment | link | — | download/stream → /support/attachments/<uuid:attachment_id>/ (views_support.support_attachment) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_analyst_sees_no_mutation_controls_and_posts_are_refused<br>+3 more | automated |
| support ticket detail | link | — | page → /support/tickets/<uuid:ticket_id>/ (views_support.support_ticket_detail) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>+6 more | automated |
| support ticket reply | button | — | POST form → /support/tickets/<uuid:ticket_id>/reply/ (views_support.support_ticket_reply) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_analyst_sees_no_mutation_controls_and_posts_are_refused<br>+6 more | automated |
| support ticket update | button | — | POST form → /support/tickets/<uuid:ticket_id>/update/ (views_support.support_ticket_update) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_analyst_sees_no_mutation_controls_and_posts_are_refused<br>+4 more | automated |
| support ticket claim | button | — | POST form → /support/tickets/<uuid:ticket_id>/claim/ (views_support.support_ticket_claim) | django: `test_support.py` › test_requires_login_and_csrf<br>django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>+7 more | automated |
| support ticket merge | button | — | POST form → /support/tickets/<uuid:ticket_id>/merge/ (views_support.support_ticket_merge) | django: `test_support.py` › test_detail_renders_thread_notes_events_and_context<br>django: `test_support.py` › test_merge_by_reference_and_id | partial |
| support canned preview | button | — | POST form → /support/tickets/<uuid:ticket_id>/canned/<uuid:response_id>/preview/ (views_support.support_canned_preview) | django: `test_support.py` › test_detail_renders_thread_notes_events_and_context<br>django: `test_support.py` › test_canned_preview_proxy | partial |

#### Growth governance — `console.growth`

Route: control-panel /growth/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| growth governance | link | — | page → /growth/governance/ (views.growth_governance) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |

#### Moderation: reports — `console.moderation_reports`

Route: control-panel /moderation/reports/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| moderation reports | link | — | page → /moderation/reports/ (views.moderation_reports) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| action report | link | — | page → /moderation/reports/<str:report_id>/action/ (views.action_report) | — | **GAP** |

#### Moderation: media — `console.moderation_media`

Route: control-panel /moderation/media/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| media moderation queue | link | — | page → /moderation/media/ (views.media_moderation_queue) | django: `test_views.py` › test_media_moderation_queue_and_content_proxy<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| media moderation content | link | — | download/stream → /moderation/media/<str:photo_id>/content/ (views.media_moderation_content) | django: `test_views.py` › test_media_moderation_queue_and_content_proxy | automated |
| media moderation decision | button | — | POST form → /moderation/media/<str:photo_id>/decision/ (views.media_moderation_decision) | django: `test_views.py` › test_media_rejection_requires_reason<br>django: `test_views.py` › test_media_rejection_requires_reason | automated |

#### Gift catalog — `console.catalog`

Route: control-panel /catalog/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| catalog list | link | — | page → /catalog/ (views.catalog_list) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| catalog new | button | — | POST form → /catalog/new/ (views.catalog_new) | — | **GAP** |
| catalog edit | button | — | POST form → /catalog/<str:gift_id>/edit/ (views.catalog_edit) | — | **GAP** |
| catalog toggle | button | — | POST form → /catalog/<str:gift_id>/toggle/ (views.catalog_toggle) | — | **GAP** |
| catalog delete | button | — | POST form → /catalog/<str:gift_id>/delete/ (views.catalog_delete) | — | **GAP** |

#### Members — `console.users`

Route: control-panel /users/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| user list | link | — | page → /users/ (views.user_list) | django: `test_views.py` › test_user_list_uses_global_kpis_from_api<br>django: `test_views.py` › test_user_create_forwards_username_credentials<br>+1 more | automated |
| user create | button | — | POST form → /users/new/ (views.user_create) | django: `test_views.py` › test_user_create_forwards_username_credentials<br>django: `test_views.py` › test_user_create_requires_username_and_password<br>+1 more | automated |
| user detail | link | — | page → /users/<str:user_id>/ (views.user_detail) | django: `test_support.py` › test_detail_renders_thread_notes_events_and_context<br>django: `test_support.py` › test_support_only_role_hides_user_link_and_claim_when_mine<br>+5 more | automated |
| user edit | button | — | POST form → /users/<str:user_id>/edit/ (views.user_edit) | — | **GAP** |
| user delete | button | — | POST form → /users/<str:user_id>/delete/ (views.user_delete) | — | **GAP** |
| user suspend | button | — | POST form → /users/<str:user_id>/suspend/ (views.user_suspend) | django: `test_bff_errors.py` › test_failed_action_banner_hides_sqlstate | partial |
| user unsuspend | button | — | POST form → /users/<str:user_id>/unsuspend/ (views.user_unsuspend) | — | **GAP** |
| user ban | button | — | POST form → /users/<str:user_id>/ban/ (views.user_ban) | — | **GAP** |
| user unban | button | — | POST form → /users/<str:user_id>/unban/ (views.user_unban) | — | **GAP** |
| user force verify | button | — | POST form → /users/<str:user_id>/verify/ (views.user_force_verify) | — | **GAP** |
| user grant coins | link | — | page → /users/<str:user_id>/grant-coins/ (views.user_grant_coins) | — | **GAP** |

#### Feature flags — `console.config`

Route: control-panel /config/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| config flags | link | — | page → /config/flags/ (views.config_flags) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| config flag toggle | button | — | POST form → /config/flags/<str:key>/toggle/ (views.config_flag_toggle) | — | **GAP** |

#### Progression — `console.progression`

Route: control-panel /progression/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| progression admin | link | — | page → /progression/ (views.progression_admin) | django: `test_views.py` › test_progression_console_renders_policies_experiments_and_fraud<br>django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| progression policy update | button | — | POST form → /progression/policies/<str:source>/ (views.progression_policy_update) | — | **GAP** |
| progression experiment update | button | — | POST form → /progression/experiments/<str:key>/ (views.progression_experiment_update) | django: `test_views.py` › test_progression_rollout_forwards_reviewed_fixed_stage | partial |
| progression fraud rule update | button | — | POST form → /progression/fraud-rules/<str:rule_code>/ (views.progression_fraud_rule_update) | django: `test_views.py` › test_progression_fraud_tuning_forwards_bounded_review_policy | partial |
| progression fraud resolve | button | — | POST form → /progression/fraud/<str:case_id>/ (views.progression_fraud_resolve) | — | **GAP** |
| progression user adjust | button | — | POST form → /progression/users/adjust/ (views.progression_user_adjust) | django: `test_views.py` › test_progression_adjustment_requires_auditable_reason<br>django: `test_views.py` › test_progression_adjustment_requires_auditable_reason | automated |
| progression user control | button | — | POST form → /progression/users/control/ (views.progression_user_control) | django: `test_views.py` › test_progression_control_forwards_freeze_and_risk | partial |

#### Billing — `console.billing`

Route: control-panel /billing/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| billing dashboard | link | — | page → /billing/ (views.billing_dashboard) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| billing package toggle | button | — | POST form → /billing/packages/<str:package_id>/toggle/ (views.billing_package_toggle) | — | **GAP** |
| billing package new | button | — | POST form → /billing/packages/new/ (views.billing_package_new) | — | **GAP** |
| billing package edit | button | — | POST form → /billing/packages/<str:package_id>/edit/ (views.billing_package_edit) | — | **GAP** |
| billing transactions | link | — | page → /billing/transactions/ (views.billing_transactions) | — | **GAP** |
| billing grant coins | link | — | page → /billing/grant-coins/ (views.billing_grant_coins) | — | **GAP** |
| billing subscriptions | link | — | page → /billing/subscriptions/ (views.billing_subscriptions) | — | **GAP** |
| billing payments | link | — | page → /billing/payments/ (views.billing_payments) | — | **GAP** |
| billing revenue analytics | link | — | page → /billing/revenue/ (views.billing_revenue_analytics) | django: `test_business.py` › test_revenue_page_uses_windowed_per_currency_api<br>django: `test_business.py` › test_revenue_page_empty_state | automated |
| billing webhook events | link | — | page → /billing/webhooks/ (views.billing_webhook_events) | — | **GAP** |
| billing reconciliation | link | — | page → /billing/reconciliation/ (views.billing_reconciliation) | django: `test_views.py` › test_reconciliation_renders_refund_controls_and_frozen_wallets<br>django: `test_views.py` › test_gift_reversal_posts_reason_to_bff<br>+3 more | automated |
| billing gift reverse | button | — | POST form → /billing/gifts/reverse/ (views.billing_gift_reverse) | django: `test_views.py` › test_gift_reversal_posts_reason_to_bff<br>django: `test_views.py` › test_short_gift_reversal_reason_is_rejected_before_api_call | partial |
| billing wallet review | button | — | POST form → /billing/wallets/<str:user_id>/review/ (views.billing_wallet_review) | django: `test_views.py` › test_wallet_review_posts_audited_resolution_to_bff | partial |
| billing fraud case resolve | button | — | POST form → /billing/fraud/cases/<str:case_id>/resolve/ (views.billing_fraud_case_resolve) | django: `test_views.py` › test_fraud_false_positive_posts_attributed_clear | partial |
| billing fraud rule update | button | — | POST form → /billing/fraud/rules/<str:rule_code>/ (views.billing_fraud_rule_update) | — | **GAP** |

#### Safety (SOS) — `console.safety`

Route: control-panel /safety/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| safety sos | link | — | page → /safety/sos/ (views.safety_sos) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | automated |
| safety sos resolve | button | — | POST form → /safety/sos/<str:alert_id>/resolve/ (views.safety_sos_resolve) | — | **GAP** |

#### Account recovery — `console.account_recovery`

Route: control-panel /account-recovery/ · Source: `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| account recovery queue | link | — | page → /account-recovery/ (views.account_recovery_queue) | django: `test_views.py` › test_queue_lists_open_requests<br>django: `test_views.py` › test_issued_code_is_shown_once_and_never_cached_or_flashed<br>+2 more | automated |
| account recovery resolve | button | — | POST form → /account-recovery/<str:request_id>/resolve/ (views.account_recovery_resolve) | django: `test_views.py` › test_issued_code_is_shown_once_and_never_cached_or_flashed<br>django: `test_views.py` › test_decline_redirects_back_to_queue | partial |

## 4. Using the catalog in the QA runner

* Iterate `features[].cases[]`; `steps`/`expected` are written to be executed against seeded data (`seed_needs`). Prefer `qa_key` locators; fall back to `label` (English) or `alt_labels`.
* Treat `status: presence_only` as **failing coverage**: the runner must perform the action and assert `expected` (network call + visible result), not just locate the control.
* `*.api_contract` cases are API-level and already backed by Go/api_e2e tests where listed; `*.api_failure` cases need a fault-injecting proxy or stubbed BFF.
* Regenerate after UI changes: the extraction scripts are deterministic; re-run them and diff `feature_catalog.json` — new controls appear with status GAP.

## 5. Method limits

* Static inference: API calls reached only through dynamic dispatch or generic helpers may be missing (rows marked *unclassified*), and a callback that can take several branches lists all endpoints it can reach.
* Test matching is by `qa` key, then English label within the screens a test pumps; Appium/Playwright label matches are accepted only when the label is near-unique. Parameterised tests (`$key`) are credited to every key they iterate.
* Operator console is inventoried per URL route (each POST route = one control); template-level buttons are not enumerated individually.
