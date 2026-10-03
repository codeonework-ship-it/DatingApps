# Connect — Feature, Control & Test Inventory (2026-10-02)

Machine-readable twin: [`qa/catalog/feature_catalog.json`](../../qa/catalog/feature_catalog.json) (same ids; drives the QA runner).

**How this was built.** Every Dart file under `app/lib` was scanned for interactive widgets (buttons, `InkWell`/`GestureDetector`, switches, chips, sliders, fields, menus, `Dismissible`, `RefreshIndicator`, `PageView`, `showModalBottomSheet`/`showDialog`, long-press/drag handlers) including private wrapper widgets and helper methods that forward a callback, with each callback followed through local methods → Riverpod notifiers → Dio calls and matched against the Go BFF route table (`backend/internal/bff/mobile/server.go`). Tests were scanned in all suites (Flutter `app/test`, Playwright `website/tests`, Appium `qa/appium/tests`, API e2e `qa/api_e2e/tests`, Go `backend/**/_test.go`, Django `control-panel/control_panel/tests`, console smoke) for the controls they **act on** and whether an **outcome is asserted after the action**. Website pages and operator-console routes are inventoried at page/route level.

**Snapshot.** Working tree on 2026-10-02, which includes the lead's *uncommitted* fix for the profile Message/Love and Spotlight buttons (`profile_actions.dart`, `app/test/features/swipe/profile_actions_test.dart`). Where HEAD (`b96977f9d`) differs it is called out.

**Status legend.** `automated` = a test performs the action and asserts its effect · `manual` = cannot be automated locally; a person checks it in QA Lab · `presence-only` = tests find the control (or tap it) but never assert what it does — the pattern that hid the profile-dock bug · `partial` = covered indirectly · **GAP** = nothing. *API* is inferred statically; rows marked *unclassified* need a human look.

## 1. Coverage summary

| Metric | Value |
|---|---|
| Features (screens, sheets, shared widgets, web pages, console areas) | 225 |
| Screens in the Flutter screen matrix | 80 |
| Interactive controls (all surfaces) | 1873 |
| … in the Flutter app | 1102 |
| … website (public pages) | 35 |
| … operator console routes | 736 |
| Test cases | 2804 |
| Cases automated / partial / presence-only / manual / not automated | 2164 / 62 / 28 / 0 / 550 |
| Automated cases proven by a `[case:…]` tag / by heuristic match | 1773 / 391 |
| Cases automated (%) | 77.2% (incl. partial 79.4%) |
| App controls whose **action** is asserted by a UI test | 802 of 1108 (72.4%) |
| App controls tested for presence only | 28 (2.5%) |
| App controls with no UI test at all | 278 (25.1%) |

**Controls by type**

| field | sheet | button | toggle | menu | gesture | link | swipe |
|---|---|---|---|---|---|---|---|
| 395 | 71 | 911 | 122 | 218 | 37 | 114 | 5 |

**Cases by type and status**

| Type | automated | partial | presence-only | manual | not automated |
|---|---|---|---|---|---|
| a11y | 157 | 0 | 0 | 0 | 0 |
| edge | 117 | 0 | 0 | 0 | 39 |
| happy | 1321 | 0 | 28 | 0 | 453 |
| l10n | 124 | 62 | 0 | 0 | 2 |
| layout | 99 | 0 | 0 | 0 | 0 |
| negative | 346 | 0 | 0 | 0 | 56 |

**Cases automated, by suite** (a case can be covered by several suites) and tests scanned

| Suite | Cases covered | Tests scanned |
|---|---|---|
| flutter | 1613 | 1962 |
| api_e2e | 292 | 281 |
| django | 271 | 415 |
| go | 191 | 747 |
| appium | 161 | 89 |
| playwright | 134 | 103 |

**By area (app + web + console)**

| Area | Features | Controls | Action asserted | Presence-only | GAP |
|---|---|---|---|---|---|
| Operator console | 63 | 736 | 0 | 0 | 0 |
| Navigation & Settings | 16 | 139 | 91 | 3 | 45 |
| Blog / Chapters | 8 | 104 | 95 | 1 | 8 |
| Profile | 11 | 91 | 80 | 0 | 11 |
| Engagement Hub | 11 | 84 | 57 | 1 | 26 |
| Clubs & Lists | 11 | 72 | 72 | 0 | 0 |
| Discover | 8 | 63 | 61 | 0 | 2 |
| Friends & Introducer | 4 | 61 | 61 | 0 | 0 |
| Groups | 6 | 57 | 27 | 1 | 29 |
| Date Plans | 5 | 55 | 16 | 2 | 37 |
| Today / Intentional Dating | 7 | 47 | 8 | 10 | 29 |
| Chat (dating) | 2 | 41 | 41 | 0 | 0 |
| Help & Support | 6 | 40 | 22 | 2 | 16 |
| Matches | 4 | 35 | 35 | 0 | 0 |
| Website (public) | 11 | 35 | 0 | 0 | 0 |
| Auth & Onboarding | 7 | 33 | 32 | 1 | 0 |
| First Chapter Studio | 2 | 31 | 1 | 1 | 29 |
| Payments & Membership | 4 | 26 | 26 | 0 | 0 |
| Photo Themes | 4 | 22 | 0 | 5 | 17 |
| City Pilot | 1 | 18 | 18 | 0 | 0 |
| Shared components | 3 | 14 | 4 | 0 | 10 |
| Social Chat (friends/rooms/groups) | 1 | 12 | 4 | 0 | 8 |
| Web Workspace | 4 | 11 | 3 | 1 | 7 |
| Graduation | 3 | 10 | 9 | 0 | 1 |
| Verification | 4 | 10 | 10 | 0 | 0 |
| Safety | 1 | 9 | 9 | 0 | 0 |
| Calls | 2 | 5 | 5 | 0 | 0 |
| Notifications | 1 | 5 | 4 | 0 | 1 |
| Celebrations & Rewards | 2 | 4 | 2 | 0 | 2 |
| Today Wall | 1 | 3 | 3 | 0 | 0 |
| End-to-end journeys | 1 | 0 | 0 | 0 | 0 |
| Localization | 10 | 0 | 0 | 0 | 0 |
| Backend platform | 1 | 0 | 0 | 0 | 0 |

_Operator-console and website controls carry their own cases (`.performs`, `.renders`, `.authz`, page cases) instead of `.action`; their coverage is in the case totals above._

## 2. Biggest gaps, prioritised

Score = area risk (money/auth/safety highest) + mutating API + navigation + (presence-only tests ⇒ false confidence) + risk flags (no-op, result popped to opener, known regression). The top of this list is where a bug like the profile dock can ship unnoticed.

### 2.1 Top 40 controls whose action is never asserted

| # | Area | Screen | Control | qa key | What it should do | Tests today |
|---|---|---|---|---|---|---|
| 1 | Today / Intentional Dating | TodayCoverAndWall | Comments | `qa.today.wall.chapter.*` | calls POST /v1/walls/views; may open BlogDetailScreen | presence-only: flutter: `today_wall_test.dart` › Today wall carousel > shows up to ten mixed picks with a position indi; flutter: `today_wall_test.dart` › Today wall carousel > opening a chapter records a view and opens it |
| 2 | Discover | HomeDiscoveryScreen | Open profile (icon person) | `qa.spotlight.rail.row.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen | **none** |
| 3 | Navigation & Settings | MainNavigationScreen | Discovery preferences | `—` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens sho | **none** |
| 4 | Navigation & Settings | MainNavigationScreen | Discovery preferences | `—` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens sho | **none** |
| 5 | Navigation & Settings | MainNavigationScreen | View | `—` | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open Notific | **none** |
| 6 | Navigation & Settings | MainNavigationScreen | Filters | `—` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens sho | **none** |
| 7 | Auth & Onboarding | AccountRecoveryScreen | Hide password | `qa.recovery.password_visibility` | updates local state | presence-only: flutter: `auth_controls_test.dart` › Sign in > Show password reveals and hides the password; flutter: `auth_controls_test.dart` › Show password toggles the new password |
| 8 | Blog / Chapters | BlogTextCommandScreen | Accept an exchange | `qa.blog.exchange.accept` | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, | presence-only: flutter: `blog_connections_controls_test.dart` › private exchange > Refresh reloads the exchange and shows the new stat |
| 9 | Navigation & Settings | MainNavigationScreen | Dismiss | `—` | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; closes screen/sh | **none** |
| 10 | Navigation & Settings | CommunityActions | Report could not be submitted. | `—` | calls POST /v1/blog/reports/{kind}/{contentID}; shows snackbar | **none** |
| 11 | Groups | GroupDetailScreen | Decline | `—` | calls POST /v1/engagement/groups/{groupID}/invites/respond; shows snackbar, updates local state | **none** |
| 12 | Groups | GroupDetailScreen | Options for {name} | `—` | calls POST /v1/engagement/groups/{groupID}/members/{userID}; opens showDialog; closes screen/sheet, pops a result to cal | **none** |
| 13 | Today / Intentional Dating | DatingRhythmScreen | Pause introductions | `—` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{};  | **none** |
| 14 | Today / Intentional Dating | ProfileStoriesScreen | Save privately | `qa.stories.save` | calls PUT /v1/profile/{userID}/stories; refreshes data, shows snackbar, updates local state | **none** |
| 15 | Today / Intentional Dating | TodayCoverAndWall | InkWell onTap | `—` | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | **none** |
| 16 | Photo Themes | PhotoThemeGalleryScreen | Share a photo for this theme | `—` | calls PUT /v1/themes/{themeID}/entries/{entryID}; opens showDialog; opens photo/file picker, opens share sheet, shows sn | presence-only: flutter: `photo_themes_data_test.dart` › PhotoThemesScreen renders themes from the API |
| 17 | Photo Themes | ThemeEntrySheet | Let it reach other members’ walls | `—` | calls POST /v1/themes/{themeID}/entries/{entryID}/featuring; shows snackbar, updates local state | presence-only: flutter: `photo_wall_test.dart` › entry sheet > the author approves pending comments and controls reach; flutter: `photo_wall_test.dart` › entry sheet > other members never see pending comments and can report |
| 18 | Date Plans | DebriefDatePlanSheet | Submit report | `—` | calls POST /v1/safety/report | **none** |
| 19 | Social Chat (friends/rooms/groups) | SocialChatScreen | Long-press message | `—` | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; closes screen/sheet, co | **none** |
| 20 | Help & Support | SupportStatusChip | Retry upload | `—` | calls POST /v1/support/attachments | **none** |
| 21 | Web Workspace | WebMemberWorkspace | Sign out | `—` | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID} | presence-only: flutter: `web_member_workspace_test.dart` › phone width drops the sidebar and shows Discover |
| 22 | Blog / Chapters | BlogTextCommandScreen | Decline kindly | `qa.blog.exchange.decline` | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, | **none** |
| 23 | Navigation & Settings | HelpSupportScreen | If someone is in immediate danger, contact lo | `—` | calls GET /v1/support/tickets; refreshes data | presence-only: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets; flutter: `help_support_screen_test.dart` › support centre is translated |
| 24 | Navigation & Settings | HelpSupportScreen | My tickets | `—` | may open SupportTicketsScreen; refreshes data | presence-only: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets |
| 25 | Engagement Hub | VoiceIcebreakersScreen | Share your hello | `qa.voice.share` | calls POST /v1/engagement/voice-icebreakers/start, POST /v1/engagement/voice-icebreakers/{icebreakerID}/send; refreshes  | **none** |
| 26 | Engagement Hub | VoiceIcebreakersScreen | Listen · {seconds}s | `qa.voice.listen.*` | calls POST /v1/engagement/voice-icebreakers/{icebreakerID}/play | **none** |
| 27 | Today / Intentional Dating | ChemistrySheet | Create your first chapter | `—` | may open ChapterStudioScreen | presence-only: flutter: `intentional_dating_test.dart` › connection card keeps a way into A little chemistry |
| 28 | Today / Intentional Dating | TodayActivities | Photo Themes | `qa.today.photo_themes` | may open PhotoThemesScreen | presence-only: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale |
| 29 | Today / Intentional Dating | TodayActivities | First Chapter Studio | `qa.today.chapter_studio` | may open ChapterStudioScreen | presence-only: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale |
| 30 | Today / Intentional Dating | TodayIntroductions | Set your rhythm | `qa.today.rhythm` | may open DatingRhythmScreen | presence-only: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale |
| 31 | Today / Intentional Dating | TodayIntroductions | Take the time you need. | `—` | may open DatingRhythmScreen | presence-only: flutter: `today_introductions_test.dart` › Pause hides cached introductions |
| 32 | Today / Intentional Dating | TodayCoverAndWall | Share a photo | `qa.today.wall.share` | may open PhotoThemesScreen | presence-only: flutter: `today_wall_test.dart` › Today wall carousel > an empty wall invites the member to write or sha |
| 33 | Photo Themes | PhotoThemeGalleryScreen | ThemeEntryTile onTap | `—` | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | **none** |
| 34 | Photo Themes | ThemeEntrySheet | Love (icon favorite_rounded) | `—` | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscriptio | **none** |
| 35 | Photo Themes | ThemeEntrySheet | Report | `—` | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | **none** |
| 36 | Photo Themes | ThemeEntrySheet | Block {name} | `—` | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | **none** |
| 37 | Photo Themes | PhotoWallRail | InkWell onTap | `—` | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | **none** |
| 38 | Date Plans | PlanSharingSheet | Reload sharing choices | `qa.plan.sharing.reload` | calls GET /v1/matches/{matchID}/plans/{planID}/sharing; shows snackbar, updates local state | presence-only: flutter: `plan_sharing_sheet_test.dart` › Failed save preserves choices and never announces success |
| 39 | Help & Support | SupportTicketFormScreen | Open SOS | `—` | may open SosScreen | presence-only: flutter: `support_ticket_form_test.dart` › safety topic points to SOS and emergency services |
| 40 | Discover | ProfileActions | See plans | `—` | may open SubscriptionScreen | **none** |

### 2.2 Structural findings

* **No-op controls (0)** — callbacks with an empty body; they look tappable and do nothing:
* **Result popped to opener — GraduationCelebrationScreen**: 2 opener call site(s) do not read the result: app/lib/features/graduation/widgets/graduation_banner.dart:167, app/lib/features/graduation/widgets/graduation_banner.dart:203. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **Result popped to opener — ActivitySessionScreen**: 1 opener call site(s) do not read the result: app/lib/features/matching/screens/matches_list_screen.dart:570. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **Result popped to opener — ProfileDetailsScreen**: 3 opener call site(s) do not read the result: app/lib/features/swipe/screens/liked_me_screen.dart:109, app/lib/features/swipe/screens/liked_profiles_screen.dart:111, app/lib/features/swipe/screens/passed_profiles_screen.dart:109. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).
* **qa keys shared by different screens (2)** — an Appium/Playwright step that finds the key cannot tell which screen it is on, so a pass on Discover can mask a broken Spotlight. Examples: `qa.blog.retry` (BlogScreen, BlogTextCommandScreen, BlogWritersScreen, SocialLikeButton); `qa.add_friend.*` (ProfileDetailsScreen, RoomPresenceHeader)
* **Automation readiness** — 467 of 1031 app controls have **no `qa.*` key/semantics id**; device suites must fall back to visible text, which changes per locale (10 locales) and look.
* **Unclassified actions** — 85 controls whose effect could not be resolved statically (focus moves, local filters, callbacks into generic helpers). Each is listed per screen below; the runner should at least assert a visible state change.
* **API tested, UI wiring not** — 39 controls call an endpoint that has Go/api_e2e coverage, but no UI test proves the control actually calls it. This is the Spotlight failure mode (endpoint fine, button never called it).
* **Error paths** — 244 of 300 API-backed controls have a UI test for the failure path (500/timeout → readable error, state rolled back, no double submit).
* **Gestures** — the Discover deck has **no drag-to-swipe gesture**: Like/Pass/Super like/Undo are buttons (`SwipeButtons`). Real swipe/drag gestures are: Today wall `PageView`, profile photo reels (`PageView`), setup preview pager, notification inbox swipe-to-dismiss (`Dismissible`), reward burst dismiss, photo reorder drag (setup photos), long-press on chat/social-chat bubbles, and ~29 pull-to-refresh lists. Only a handful of `tester.drag/fling` calls exist in the Flutter suite.
* **Locale rendering** — the hard-coded-strings guard is a static ratchet; no test renders app screens in each of the 10 locales (only the website does).

## 3. Inventory by area

Each table lists every control: type, `qa` key, what it does (API + visible result), the tests that **perform it and assert the outcome**, and status. Non-action cases (API contract, failure path, validation, layout, a11y, l10n, back affordance) are in the JSON under each feature's `cases`.

### Auth & Onboarding

#### AccountRecoveryScreen — `auth.account_recovery`

Route: opened from: auth_screen · Source: `app/lib/features/auth/screens/account_recovery_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to sign in | button | `qa.recovery.back_to_sign_in` | closes screen/sheet | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) Back to sign in closes recovery [cas<br>flutter: `auth_controls_test.dart` › Back to sign in closes recovery | automated |
| I have my code | toggle | — | updates local state | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) Choosing "I lost my code" swaps the <br>flutter: `account_recovery_screen_test.dart` › lost code sends a help request and shows the neutral answer | automated |
| Username | field | `qa.recovery.username` | opens TextField | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) A recovery code resets the password <br>flutter: `auth_controls_test.dart` › Recovery needs a username; any script is kept<br>+10 more | automated |
| Recovery code | field | `qa.recovery.code` | opens TextField | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) A recovery code resets the password <br>flutter: `auth_controls_test.dart` › A recovery code resets the password<br>+5 more | automated |
| Hide password | field | `qa.recovery.new_password` | opens TextField | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) A recovery code resets the password <br>flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) Show password toggles the new passwo<br>+7 more | automated |
| Hide password | button | `qa.recovery.password_visibility` | updates local state | — | presence-only |
| Anything that helps us (optional) | field | `qa.recovery.message` | opens TextField | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) Lost code asks the safety team with <br>flutter: `auth_controls_test.dart` › Lost code asks the safety team with the optional note<br>+1 more | automated |
| Ask for help | button | `qa.recovery.submit` | calls POST /v1/auth/password/recover, POST /v1/auth/recovery/assistance; updates local state | flutter: `auth_controls_test.dart` › Can't sign in? (account recovery) A recovery code resets the password <br>flutter: `auth_controls_test.dart` › A recovery code resets the password<br>+9 more | automated |
| Something else wrong? Contact support | button | `qa.recovery.contact_support` | may open SupportContactFormScreen | flutter: `support_entry_points_test.dart` › [case:auth.account_recovery.recovery_contact_support.action] signed ou | automated |

#### AuthScreen — `auth.auth`

Route: opened from: signup_screen, web_entry_screen, welcome_screen · Source: `app/lib/features/auth/screens/auth_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to welcome | button | `qa.signin.back` | may open WelcomeScreen; closes screen/sheet | flutter: `auth_controls_test.dart` › Sign in Back returns to the welcome screen [case:auth.auth.signin_back<br>flutter: `auth_controls_test.dart` › Sign in > Back returns to the welcome screen | automated |
| Password | field | — | calls POST /v1/auth/login; may open MainNavigationScreen; closes screen/sheet, shows snackbar | flutter: `auth_controls_test.dart` › Sign in Done on the password keyboard signs in [case:auth.auth.passwor<br>playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>+8 more | automated |
| Hide password | button | `qa.signin.password_visibility` | updates local state | flutter: `auth_controls_test.dart` › Sign in Show password reveals and hides the password [case:auth.auth.s | automated |
| Can't sign in? | button | `qa.signin.cant_sign_in` | may open AccountRecoveryScreen | flutter: `auth_controls_test.dart` › Sign in Can't sign in? opens recovery with the typed username [case:au<br>flutter: `auth_controls_test.dart` › Sign in > Can't sign in? opens recovery with the typed username | automated |
| Sign in | button | `qa.signin.login_button` | calls POST /v1/auth/login; may open MainNavigationScreen; closes screen/sheet, shows snackbar | flutter: `auth_controls_test.dart` › Sign in Sign in with valid credentials opens the app and keeps the ses<br>flutter: `auth_controls_test.dart` › Sign in > Sign-in username is checked before anything is sent<br>+20 more | automated |
| username | field | — | local/unclassified action — callback: (_) => passwordFocusNode.requestFocus() | flutter: `auth_controls_test.dart` › Sign in Next on the username keyboard moves to the password [case:auth<br>playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>+8 more | automated |

#### SignupScreen — `auth.signup`

Route: opened from: web_entry_screen, welcome_screen · Source: `app/lib/features/auth/screens/signup_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Select date of birth | sheet | — | presents a dialog/picker | flutter: `signup_controls_test.dart` › Create account signs up, saves the profile basics and closes sign-up [ | automated |
| Back | button | `qa.signup.back` | closes screen/sheet | flutter: `signup_controls_test.dart` › Back leaves sign-up [case:auth.signup.signup_back.action] | automated |
| your_username | field | — | local/unclassified action — callback: (_) => _passwordFocus.requestFocus() | flutter: `signup_controls_test.dart` › Next walks through username, password, confirmation and name [case:aut | automated |
| At least 8 characters | field | — | local/unclassified action — callback: (_) => _confirmPasswordFocus.requestFocus() | flutter: `signup_controls_test.dart` › Next walks through username, password, confirmation and name [case:aut | automated |
| Hide password | button | `qa.signup.password_visibility` | updates local state | flutter: `signup_controls_test.dart` › Password and confirmation each have their own show/hide [case:auth.sig<br>flutter: `signup_controls_test.dart` › Password and confirmation each have their own show/hide | automated |
| Confirm password | field | — | local/unclassified action — callback: (_) => _nameFocus.requestFocus() | flutter: `signup_controls_test.dart` › Next walks through username, password, confirmation and name [case:aut | automated |
| Hide password | button | `qa.signup.confirm_password_visibility` | updates local state | flutter: `signup_controls_test.dart` › Password and confirmation each have their own show/hide [case:auth.sig<br>flutter: `signup_controls_test.dart` › Password and confirmation each have their own show/hide | automated |
| Select date | button | `qa.signup.dob_field` | opens showDatePicker; updates local state | flutter: `signup_controls_test.dart` › Create account signs up, saves the profile basics and closes sign-up [<br>flutter: `auth_server_errors_l10n_test.dart` › sign-up errors in German > $name [case:auth.l10n.signup_server_error]<br>+6 more | automated |
| gender | button | `qa.signup.gender.*` | updates local state | flutter: `signup_controls_test.dart` › Create account signs up, saves the profile basics and closes sign-up [<br>flutter: `auth_server_errors_l10n_test.dart` › sign-up errors in German > $name [case:auth.l10n.signup_server_error] | automated |
| Create account | button | `qa.signup.create_account_button` | calls POST /v1/auth/signup, POST /v1/auth/signup/bootstrap; shows snackbar | flutter: `signup_controls_test.dart` › Create account signs up, saves the profile basics and closes sign-up [<br>flutter: `signup_controls_test.dart` › A friend-only account signs up without a dating profile [case:auth.sig<br>+14 more | automated |
| Sign in | button | `qa.signup.sign_in_link` | may open AuthScreen | flutter: `signup_controls_test.dart` › Sign in swaps sign-up for sign-in [case:auth.signup.signup_sign_in_lin<br>playwright: `qa-lab.spec.js` › wrong password is refused with a readable error<br>+2 more | automated |

#### UserAgreementScreen — `auth.user_agreement`

Route: opened from: main · Source: `app/lib/features/auth/screens/user_agreement_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| I agree to the Terms & Privacy Policy | button | `qa.terms.accept_checkbox` | updates local state | flutter: `terms_controls_test.dart` › Accepting the terms saves the agreement and the gate moves on [case:au<br>appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup<br>+1 more | automated |
| accept checkbox input | toggle | `qa.terms.accept_checkbox_input` | updates local state | flutter: `terms_controls_test.dart` › The checkbox itself ticks and unticks [case:auth.user_agreement.terms_<br>flutter: `terms_controls_test.dart` › The checkbox itself ticks and unticks | automated |
| I Accept and Continue | button | `qa.terms.continue_button` | calls PATCH /v1/users/{userID}/agreements/terms; shows snackbar | flutter: `terms_controls_test.dart` › Accepting the terms saves the agreement and the gate moves on [case:au<br>flutter: `terms_controls_test.dart` › Accepting the terms saves the agreement and the gate moves on<br>+2 more | automated |
| Sign out | button | `qa.terms.sign_out` | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID} | flutter: `terms_controls_test.dart` › Sign out removes this device from push, ends the session and shows Wel<br>flutter: `terms_controls_test.dart` › Sign out offline (no session reachable) still lands on Welcome | automated |

#### WelcomeScreen — `auth.welcome`

Route: opened from: auth_screen, main, settings_screen, web_entry_screen · Source: `app/lib/features/auth/screens/welcome_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create account | button | `qa.welcome.signup_button` | may open SignupScreen | flutter: `auth_controls_test.dart` › Welcome Create account opens dating sign-up [case:auth.welcome.welcome<br>flutter: `auth_controls_test.dart` › Welcome > Create account opens dating sign-up<br>+6 more | automated |
| Just here to introduce friends | button | `qa.welcome.introducer_button` | may open SignupScreen | flutter: `auth_controls_test.dart` › Welcome Just here to introduce friends opens the friend-only sign-up [<br>flutter: `auth_controls_test.dart` › Welcome > Just here to introduce friends opens the friend-only sign-up | automated |
| Already a member?  | button | `qa.welcome.signin_button` | may open AuthScreen | flutter: `auth_controls_test.dart` › Welcome Already a member? Sign in opens sign-in [case:auth.welcome.wel<br>flutter: `auth_controls_test.dart` › Welcome > Already a member? Sign in opens sign-in<br>+3 more | automated |

#### Auth server errors in every language — `auth.l10n`

Route: cross-cutting · Source: `app/lib/features/auth/auth_error_messages.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Server replies map to message codes | l10n | flutter: `auth_server_errors_l10n_test.dart` › server replies map to message codes [case:auth.l10n.server_error_mappi | automated |
| Sign-in errors read in the member's language | l10n | flutter: `auth_server_errors_l10n_test.dart` › sign-in errors in German $name [case:auth.l10n.signin_server_error] | automated |
| Sign-up errors read in the member's language | l10n | flutter: `auth_server_errors_l10n_test.dart` › sign-up errors in German $name [case:auth.l10n.signup_server_error] | automated |

#### Session and account switch — `auth.session`

Route: cross-cutting · Source: `app/lib/core/session`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Every member-scoped provider starts afresh for the next member | edge | flutter: `account_switch_isolation_test.dart` › every member-scoped provider starts afresh for the next member [case:a | automated |

### Discover

#### ProfileActions — `swipe.profile_actions`

Route: embedded / not directly routed · Source: `app/lib/features/swipe/profile_actions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See plans | button | — | may open SubscriptionScreen | — | **GAP** |

#### HomeDiscoveryScreen — `swipe.home_discovery`

Route: #/discover (web) / bottom nav: Discover tab (mobile) · Source: `app/lib/features/swipe/screens/home_discovery_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Not now | sheet | — | presents a bottom sheet | flutter: `discover_deck_controls_test.dart` › Like the daily like limit opens the limit sheet; Not now closes it and | automated |
| See plans | button | `qa.discovery.daily_limit.see_plans` | may open SubscriptionScreen; closes screen/sheet | flutter: `discover_deck_controls_test.dart` › Like See plans on the limit sheet opens the plans [case:swipe.home_dis<br>flutter: `discover_deck_controls_test.dart` › Like > See plans on the limit sheet opens the plans | automated |
| Not now | button | `qa.discovery.daily_limit.not_now` | closes screen/sheet | flutter: `discover_deck_controls_test.dart` › Like the daily like limit opens the limit sheet; Not now closes it and<br>flutter: `discover_deck_controls_test.dart` › Like > the daily like limit opens the limit sheet; Not now closes | automated |
| Meet {name} | button | `qa.today.profile.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | flutter: `discover_deck_controls_test.dart` › Today screen Meet <name> opens the pick; Love there likes that member <br>flutter: `discover_deck_controls_test.dart` › Today screen > a Today pick whose like hits the daily limit says so | automated |
| Back to Today | button | `qa.discovery.back_to_today` | updates local state | flutter: `discover_deck_controls_test.dart` › Today screen Explore profiles opens the deck; Back to Today returns [c<br>flutter: `discover_deck_controls_test.dart` › Today screen > Explore profiles opens the deck; Back to Today returns | automated |
| Open profile (icon person) | button | `qa.spotlight.rail.row.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | — | **GAP** |
| Open card (icon verified) | button | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | flutter: `discover_deck_controls_test.dart` › Today rail > Love from a Today pick likes that member and reloads Toda<br>flutter: `discover_deck_controls_test.dart` › Today rail > Message from a Today pick without a match likes and expla | automated |
| View all | button | `qa.spotlight.rail.view_all` | may open SpotlightProfilesScreen | playwright: `app-journeys.spec.js` › Spotlight screen: View more → Love, card Message without a match, View<br>playwright: `app-journeys.spec.js` › Spotlight screen: Like, Pass and Super like reach the server and move  | automated |
| Open card (icon verified) | button | `qa.discover.today.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | flutter: `discover_deck_controls_test.dart` › Today rail a pick opens that member and records the view [case:swipe.h<br>flutter: `discover_deck_controls_test.dart` › Today rail > Love from a Today pick likes that member and reloads Toda<br>+1 more | automated |
| Open profile (icon person) | button | `qa.spotlight.rail.card.*` | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | flutter: `discover_deck_controls_test.dart` › Spotlight rail a card opens that member and records the view [case:swi<br>flutter: `discover_deck_controls_test.dart` › Spotlight rail > Love from a rail profile likes that member, not the d<br>+1 more | automated |
| View more | button | `qa.spotlight.rail.view_more` | may open SpotlightProfilesScreen | flutter: `discover_deck_controls_test.dart` › Spotlight rail View more opens the full Spotlight screen with the rail<br>flutter: `discover_deck_controls_test.dart` › Spotlight rail > View more opens the full Spotlight screen with the ra | automated |
| Unable to load profiles | button | `qa.discovery.state_action_button` | calls GET /v1/discovery/{userID} | flutter: `discover_deck_controls_test.dart` › error and empty states a failed load shows the error; Try Again reload<br>flutter: `discover_deck_controls_test.dart` › error and empty states > offline retry keeps the error state with the <br>+3 more | automated |
| No profiles | gesture | `qa.discovery.state_action_button` | calls GET /v1/discovery/{userID} | flutter: `discover_deck_controls_test.dart` › error and empty states the empty deck refreshes on Refresh [case:swipe<br>flutter: `discover_deck_controls_test.dart` › error and empty states > offline retry keeps the error state with the <br>+3 more | automated |
| Like (icon favorite) | button | — | calls POST /v1/swipe; may open MatchNotificationScreen; refreshes data, shows snackbar, updates local state | flutter: `discover_deck_controls_test.dart` › Like saves one like for the top card and deals the next [case:swipe.ho<br>flutter: `discover_deck_controls_test.dart` › Like a mutual like opens the match screen, and Send Message opens the  | automated |
| Message | button | — | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local state | flutter: `discover_deck_controls_test.dart` › card Message without a match: one like for this member, explained, and<br>flutter: `discover_deck_controls_test.dart` › card Message with a match: opens that chat and sends no like [case:swi<br>+1 more | automated |
| View more | button | — | calls POST /v1/profile/views, POST /v1/swipe; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes data, shows snackbar, update | flutter: `discover_deck_controls_test.dart` › View more (profile from the deck) opens the profile and records the vi<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Discover deck: View <br>+10 more | automated |
| Pass (icon close) | button | — | calls POST /v1/swipe; shows snackbar, updates local state | flutter: `discover_deck_controls_test.dart` › Pass and Undo Pass saves a pass for the top card and deals the next [c | automated |
| Super like (icon star) | button | — | calls POST /v1/swipe; may open MatchNotificationScreen; refreshes data, shows snackbar, updates local state | flutter: `discover_deck_controls_test.dart` › Super like saves a like for the top card, confirms it and deals the ne | automated |
| Undo (icon undo) | button | — | local/unclassified action — callback: swipeNotifier.undoSwipe ⚠  | flutter: `discover_deck_controls_test.dart` › Pass and Undo Undo brings the last card back without another request [ | automated |
| Notifications (icon notifications_none_rounded) | button | `qa.discovery.notifications_button` | opens showDialog | flutter: `discover_deck_controls_test.dart` › header > with nothing unread the sheet says so | automated |
| Notifications | sheet | `qa.discovery.notifications_button` | presents a dialog/picker | flutter: `discover_deck_controls_test.dart` › header > with nothing unread the sheet says so | automated |
| Passed | button | — | may open PassedProfilesScreen | appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| notifications button | button | `qa.discovery.notifications_button` | opens showModalBottomSheet | flutter: `discover_deck_controls_test.dart` › header the bell opens the notifications sheet; Who liked me opens the <br>flutter: `discover_deck_controls_test.dart` › header > with nothing unread the sheet says so | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `discover_deck_controls_test.dart` › header the bell opens the notifications sheet; Who liked me opens the <br>flutter: `discover_deck_controls_test.dart` › header with nothing unread the sheet says so [case:swipe.home_discover | automated |
| Passed | button | — | may open PassedProfilesScreen | flutter: `discover_deck_controls_test.dart` › header Passed opens the passed list with the member just passed [case:<br>appium: `test_06_swipe_match_creation.py` › test_discovery_pass_and_undo_sample | automated |
| Who liked me (icon visibility_outlined) | button | `qa.discovery.notification.who_liked_me` | may open LikedMeScreen; closes screen/sheet | flutter: `discover_deck_controls_test.dart` › header the bell opens the notifications sheet; Who liked me opens the <br>flutter: `liked_me_screen_test.dart` › the Discover notification opens who liked me | automated |
| Fits your week | button | `qa.discover.today.fits_your_week` | may open DatingRhythmScreen | flutter: `discover_deck_controls_test.dart` › Today rail Fits your week opens the dating rhythm settings [case:swipe<br>flutter: `discover_deck_controls_test.dart` › Today rail > Fits your week opens the dating rhythm settings | automated |

#### LikedMeScreen — `swipe.liked_me`

Route: opened from: home_discovery_screen, main_navigation_screen, notification_inbox_screen, profile_view_screen, web_member_workspace · Source: `app/lib/features/swipe/screens/liked_me_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See plans | button | — | may open SubscriptionScreen | flutter: `liked_me_controls_test.dart` › the daily like limit is explained; See plans opens the plans [case:swi<br>flutter: `liked_me_controls_test.dart` › the daily like limit is explained; See plans opens the plans | automated |
| Retry | button | `qa.liked_me.retry` | calls GET /v1/discovery/{userID}/liked-me; shows snackbar | flutter: `liked_me_controls_test.dart` › a failed load offers Retry, which loads the list [case:swipe.liked_me.<br>flutter: `liked_me_controls_test.dart` › a failed load offers Retry, which loads the list<br>+1 more | automated |
| Like back | button | `qa.liked_me.like_back.*` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar | flutter: `liked_me_controls_test.dart` › Like back sends a like; the liker leaves the list [case:swipe.liked_me<br>flutter: `liked_me_controls_test.dart` › a like back that makes the match opens the match screen and reloads th<br>+6 more | automated |
| Verified | button | `qa.liked_me.open.*` | calls POST /v1/profile/views, POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen; refreshes da | flutter: `profile_entry_points_test.dart` › Liked you Love on a liker likes back through the swipe API and the lik<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Liked you (from My p<br>+5 more | automated |
| Pass | button | `qa.liked_me.pass.*` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar | flutter: `liked_me_controls_test.dart` › Pass sends a pass, says so privately, and removes the liker [case:swip<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > web #/likes: Love an<br>+6 more | automated |
| refresh | gesture | `qa.liked_me.refresh` | calls GET /v1/discovery/{userID}/liked-me; shows snackbar | flutter: `liked_me_controls_test.dart` › pull to refresh reloads the list [case:swipe.liked_me.liked_me_refresh | automated |

#### LikedProfilesScreen — `swipe.liked_profiles`

Route: opened from: profile_view_screen · Source: `app/lib/features/swipe/screens/liked_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| chevron right (icon chevron_right) | button | `qa.liked_profiles.open.*` | may open ProfileDetailsScreen | flutter: `profile_entry_points_test.dart` › Liked profiles list the chevron opens that member [case:swipe.liked_pr<br>flutter: `profile_entry_points_test.dart` › Liked profiles list > the chevron opens that member<br>+2 more | automated |

#### PassedProfilesScreen — `swipe.passed_profiles`

Route: opened from: home_discovery_screen, spotlight_profiles_screen · Source: `app/lib/features/swipe/screens/passed_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| chevron right (icon chevron_right) | button | `qa.passed_profiles.open.*` | may open ProfileDetailsScreen | flutter: `profile_entry_points_test.dart` › Passed profiles list the chevron opens that member [case:swipe.passed_<br>flutter: `profile_entry_points_test.dart` › Passed profiles list > Love on a passed member likes them and they lea<br>+1 more | automated |

#### ProfileDetailsScreen — `swipe.profile_details`

Route: opened from: home_discovery_screen, liked_me_screen, liked_profiles_screen, passed_profiles_screen, spotlight_profiles_screen · Source: `app/lib/features/swipe/screens/profile_details_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Submit report | button | — | calls POST /v1/safety/report | flutter: `profile_entry_points_test.dart` › profile page controls Report sends the report; the confirmation offers<br>flutter: `profile_details_report_test.dart` › a sent report is confirmed even without a report id | automated |
| Appeal | button | — | may open ModerationAppealsScreen | flutter: `profile_entry_points_test.dart` › profile page controls Report sends the report; the confirmation offers<br>flutter: `profile_entry_points_test.dart` › profile page controls > Report sends the report; the confirmation offe | automated |
| Introducing | button | — | may open ProfileGalleryScreen | flutter: `profile_entry_points_test.dart` › profile page controls the main photo opens the full-screen gallery [ca | automated |
| {name}, photo {index} of {count} | button | — | may open ProfileGalleryScreen | flutter: `profile_entry_points_test.dart` › profile page controls a photo in the strip opens the gallery on that p | automated |
| Go back | button | `qa.profile_detail.go_back` | closes screen/sheet | flutter: `profile_entry_points_test.dart` › profile page controls Go back on an unavailable profile closes it [cas<br>flutter: `profile_entry_points_test.dart` › profile page controls > Go back on an unavailable profile closes it | automated |
| Retry | button | `qa.profile_detail.retry` | refreshes data | flutter: `profile_entry_points_test.dart` › profile page controls an unavailable profile offers Retry, which reloa<br>flutter: `profile_entry_points_test.dart` › profile page controls > an unavailable profile offers Retry, which rel | automated |
| Back (icon arrow_back_rounded) | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `profile_entry_points_test.dart` › profile page controls Back returns to the opener with no action [case: | automated |
| Report | button | — | calls POST /v1/safety/report; may open ModerationAppealsScreen; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `profile_entry_points_test.dart` › profile page controls Report sends the report; the confirmation offers | automated |
| Love (icon favorite_rounded) | button | `qa.profile_detail.love_button` | calls POST /v1/swipe, GET /v1/matches/{userID}; may open MatchNotificationScreen, SubscriptionScreen; closes screen/sheet, pops a result to caller, refreshes da ⚠ pops a result to its opener — verify every opener handles it ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) Love saves one like for thi<br>flutter: `profile_entry_points_test.dart` › profile page controls Love that makes a match → Send Message stays in <br>+16 more | automated |
| Message (icon chat_bubble_outline_rounded) | button | `qa.profile_detail.message_button` | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  ⚠ see history in JSON (profile/Spotlight dock regression) | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) Message with an existing ma<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Today rail: Meet → M<br>+10 more | automated |
| Add friend (profile page) | button | `qa.add_friend.*` | AddFriendButton embedded in the profile page; extracted under friends.friend_actions only | flutter: `profile_entry_points_test.dart` › profile page controls Add friend sends a friend request for this membe | automated |

#### SpotlightProfilesScreen — `swipe.spotlight_profiles`

Route: opened from: home_discovery_screen · Source: `app/lib/features/swipe/screens/spotlight_profiles_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Apply | sheet | — | presents a bottom sheet | flutter: `spotlight_screen_controls_test.dart` › header and filters Filters → Verified only → Apply hides unverified me | automated |
| Verified only | toggle | `qa.spotlight.filters.verified_only` | local/unclassified action — callback: (value) { setSheetState(() => localVerifiedOnly = value); } | flutter: `spotlight_screen_controls_test.dart` › header and filters Filters → Verified only → Apply hides unverified me<br>flutter: `spotlight_screen_controls_test.dart` › header and filters > Filters → Verified only → Apply hides unverified <br>+2 more | automated |
| age range | toggle | `qa.spotlight.filters.age_range` | local/unclassified action — callback: (value) { setSheetState(() => localAgeRange = value); } | flutter: `spotlight_screen_controls_test.dart` › header and filters the age range slider narrows the members shown [cas | automated |
| Reset | button | `qa.spotlight.filters.reset` | local/unclassified action — callback: !localVerifiedOnly && localAgeRange == _defaultAgeRange ? null : () { setSheetState(() { l ⚠  | flutter: `spotlight_screen_controls_test.dart` › header and filters Reset puts the filters back before applying [case:s<br>flutter: `spotlight_screen_controls_test.dart` › header and filters > Reset puts the filters back before applying | automated |
| Apply | button | `qa.spotlight.filters.apply` | closes screen/sheet, updates local state | flutter: `spotlight_screen_controls_test.dart` › header and filters Filters → Verified only → Apply hides unverified me<br>flutter: `spotlight_screen_controls_test.dart` › header and filters the age range slider narrows the members shown [cas<br>+5 more | automated |
| Back (icon arrow_back_ios_new_rounded) | button | `qa.spotlight.back_button` | closes screen/sheet | flutter: `spotlight_screen_controls_test.dart` › header and filters Back closes Spotlight [case:swipe.spotlight_profile | automated |
| Filters | button | — | opens showModalBottomSheet; closes screen/sheet, updates local state | flutter: `spotlight_screen_controls_test.dart` › header and filters Filters → Verified only → Apply hides unverified me | automated |
| Like (icon favorite) | button | — | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  | flutter: `spotlight_screen_controls_test.dart` › deck buttons Like saves a like for the member on the card and moves on<br>flutter: `spotlight_screen_controls_test.dart` › deck buttons after the last card the screen says everyone was reviewed<br>+1 more | automated |
| Message | button | — | calls GET /v1/matches/{userID}, POST /v1/swipe; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar | flutter: `spotlight_screen_controls_test.dart` › Message $label Message without a match likes, explains and stays [case<br>flutter: `spotlight_screen_controls_test.dart` › Message Message with a match opens that chat, no like [case:swipe.spot<br>+3 more | automated |
| View more | button | — | calls POST /v1/profile/views, POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, ProfileDetailsScreen, SubscriptionScreen;  | flutter: `spotlight_screen_controls_test.dart` › View more opens the member on the card and records the view [case:swip<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Vi<br>+3 more | automated |
| Pass (icon close) | button | — | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  | flutter: `spotlight_screen_controls_test.dart` › deck buttons Pass saves a pass, moves on and counts it [case:swipe.spo<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Li | automated |
| Super like (icon star) | button | — | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, MatchNotificationScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local  | flutter: `spotlight_screen_controls_test.dart` › deck buttons Super like saves a like and moves on [case:swipe.spotligh<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Li | automated |
| Undo (icon undo) | button | — | calls POST /v1/swipe, GET /v1/matches/{userID}; may open ChatScreen, SubscriptionScreen; refreshes data, shows snackbar, updates local state | flutter: `spotlight_screen_controls_test.dart` › deck buttons Undo shows the last card again (local only, no request) [<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Li | automated |
| Passed ({count}) | button | — | may open PassedProfilesScreen | flutter: `spotlight_screen_controls_test.dart` › deck buttons Passed (n) opens the members passed on, with the one just | automated |
| Messages | button | — | shows snackbar | flutter: `spotlight_screen_controls_test.dart` › header and filters Messages points the member to Discover [case:swipe. | automated |
| notifications button | button | `qa.spotlight.notifications_button` | shows snackbar | flutter: `spotlight_screen_controls_test.dart` › header and filters the bell says there is nothing new [case:swipe.spot<br>flutter: `spotlight_screen_controls_test.dart` › header and filters > the bell says there is nothing new | automated |

#### ProfileDetailsScreen (opened from every entry point) — `discover.profile_entry_points`

Route: Discover card View more / Spotlight rail / Spotlight screen / Today rail / Liked you / Liked / Passed / Matches · Source: `app/lib/features/swipe/screens/profile_details_screen.dart`, `app/lib/features/swipe/profile_actions.dart`, `app/lib/features/swipe/screens/home_discovery_screen.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Love works when the profile is opened from Discover deck card 'View more' | happy | flutter: `discover_deck_controls_test.dart` › View more (profile from the deck) Love there likes this member, closes<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Discover deck: View <br>+7 more | automated |
| Message works when the profile is opened from Discover deck card 'View more' | happy | flutter: `discover_deck_controls_test.dart` › View more (profile from the deck) Message there (no match) likes, expl<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Discover deck: View <br>+7 more | automated |
| Love works when the profile is opened from Discover Spotlight rail avatar | happy | flutter: `discover_deck_controls_test.dart` › Spotlight rail Love from a rail profile likes that member, not the dec<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight rail: avat | automated |
| Message works when the profile is opened from Discover Spotlight rail avatar | happy | flutter: `discover_deck_controls_test.dart` › Spotlight rail Message from a rail profile with a match opens the chat<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight rail: avat | automated |
| Love works when the profile is opened from Full Spotlight screen 'View more' | happy | flutter: `spotlight_screen_controls_test.dart` › View more Love on a Spotlight profile (Discover → Spotlight → View mor<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Vi | automated |
| Message works when the profile is opened from Full Spotlight screen 'View more' | happy | flutter: `spotlight_screen_controls_test.dart` › View more Message on a Spotlight profile with a match opens the chat [<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Vi | automated |
| Love works when the profile is opened from Today rail card | happy | flutter: `discover_deck_controls_test.dart` › Today rail Love from a Today pick likes that member and reloads Today <br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Today rail: Meet → L | automated |
| Message works when the profile is opened from Today rail card | happy | flutter: `discover_deck_controls_test.dart` › Today rail Message from a Today pick without a match likes and explain<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Today rail: Meet → M | automated |
| Love works when the profile is opened from Liked you list (own Love rule = like back) | happy | flutter: `profile_entry_points_test.dart` › Liked you Love on a liker likes back through the swipe API and the lik<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Liked you (from My p | automated |
| Message works when the profile is opened from Liked you list (own Love rule = like back) | happy | flutter: `profile_entry_points_test.dart` › Liked you Message on a liker likes back; the match screen leads to the<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Liked you (from My p | automated |
| Love works when the profile is opened from Liked profiles list | happy | flutter: `profile_entry_points_test.dart` › Liked profiles list Love from the liked list sends one like for that m | automated |
| Message works when the profile is opened from Liked profiles list | happy | flutter: `profile_entry_points_test.dart` › Liked profiles list Message from the liked list with a match opens the | automated |
| Love works when the profile is opened from Passed profiles list | happy | flutter: `profile_entry_points_test.dart` › Passed profiles list Love on a passed member likes them and they leave | automated |
| Message works when the profile is opened from Passed profiles list | happy | flutter: `profile_entry_points_test.dart` › Passed profiles list Message on a passed member whose like makes the m | automated |
| Love works when the profile is opened from Web #/likes | happy | flutter: `profile_entry_points_test.dart` › Liked you the web /likes page is Liked you: Love likes back there too <br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > web #/likes: Love an | automated |
| Message works when the profile is opened from Web #/likes | happy | flutter: `profile_entry_points_test.dart` › Liked you the web /likes page: Message likes back and opens the match <br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > web #/likes: Love an | automated |
| Full Spotlight screen Like/Pass/Super like call POST /v1/swipe | happy | flutter: `profile_actions_test.dart` › Spotlight screen buttons reach the server $key saves is_like=$like for<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Spotlight screen: Li<br>+1 more | automated |
| Full Spotlight screen Message opens chat or likes+explains | happy | flutter: `spotlight_screen_controls_test.dart` › Message $label Message without a match likes, explains and stays [case<br>flutter: `spotlight_screen_controls_test.dart` › Message Message with a match opens that chat, no like [case:swipe.spot<br>+1 more | automated |
| Liked-you profile Love uses like-back endpoint (override) and returns love | edge | flutter: `profile_actions_test.dart` › profile page (any entry point, empty deck) a screen with its own rule <br>flutter: `profile_entry_points_test.dart` › Liked you Love on a liker likes back through the swipe API and the lik<br>+2 more | automated |

### Today / Intentional Dating

#### ChemistrySheet — `intentional_dating.connection_card`

Route: embedded / not directly routed · Source: `app/lib/features/intentional_dating/connection_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create your first chapter | button | — | may open ChapterStudioScreen | only checks presence: flutter: `intentional_dating_test.dart` › connection card keeps a way into A little chemistry | presence-only |
| A little chemistry? | button | `qa.connection.chemistry` | opens showChemistrySheet, showModalBottomSheet | flutter: `intentional_dating_test.dart` › connection card keeps a way into A little chemistry<br>playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| A little chemistry? | sheet | — | presents a bottom sheet | playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| Try loading again | button | — | refreshes data | — | **GAP** |
| OutlinedButton onPressed | button | — | refreshes data, shows snackbar, updates local state | — | **GAP** |
| OutlinedButton onPressed | button | — | refreshes data, shows snackbar, updates local state | — | **GAP** |

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
| Explore more profiles | gesture | `qa.today.screen` | local/unclassified action — callback: refresh ⚠  | only checks presence: flutter: `discover_deck_controls_test.dart` › Today screen > Explore profiles opens the deck; Back to Today returns | presence-only |
| Refresh Today | gesture | — | local/unclassified action — callback: refresh ⚠  | — | **GAP** |
| Set your rhythm | button | `qa.today.rhythm` | may open DatingRhythmScreen | only checks presence: flutter: `today_wall_test.dart` › the whole Today screen > lays out at $width with text x$scale | presence-only |
| Take the time you need. | button | — | may open DatingRhythmScreen | only checks presence: flutter: `today_introductions_test.dart` › Pause hides cached introductions | presence-only |
| Your introductions are taking a moment. | button | — | local/unclassified action — callback: refresh ⚠  | only checks presence: flutter: `today_introductions_test.dart` › Failed refresh hides cached profiles and offers retry | presence-only |
| All introductions | toggle | — | updates local state | — | **GAP** |
| All introductions | toggle | `qa.today.activity.*` | updates local state | — | **GAP** |
| Explore profiles (Today breathing room) | button | — | passed as an action: parameter to an empty-state widget | flutter: `discover_deck_controls_test.dart` › Today screen Explore profiles opens the deck; Back to Today returns [c | automated |

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
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `reaction_widgets_controls_test.dart` › the picker opens with all six reactions, marks the current one and off | automated |
| Take my reaction back | button | — | closes screen/sheet, pops a result to caller | flutter: `reaction_widgets_controls_test.dart` › Take my reaction back closes the sheet with an empty answer and remove | automated |
| option | button | — | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `reaction_widgets_controls_test.dart` › choosing a reaction closes the sheet and hands back its id; on a photo | automated |

### Matches

#### ActivitySessionScreen — `matching.activity_session`

Route: opened from: matches_list_screen · Source: `app/lib/features/matching/screens/activity_session_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Start a new session | button | `qa.activity.restart` | calls POST /v1/activities/sessions/start | flutter: `activity_session_controls_test.dart` › Start a new session starts again and clears the answers [case:matching<br>flutter: `activity_session_controls_test.dart` › Start a new session starts again and clears the answers<br>+1 more | automated |
| answer | toggle | `qa.activity.answer.*.*` | local/unclassified action — callback: (value) => notifier.selectAnswer(question.id, value) | flutter: `activity_session_controls_test.dart` › choosing an answer selects it [case:matching.activity_session.activity<br>flutter: `activity_session_controls_test.dart` › Start a new session starts again and clears the answers<br>+1 more | automated |
| Submit Responses | button | `qa.activity.submit` | calls POST /v1/activities/sessions/{sessionID}/submit, GET /v1/activities/sessions/{sessionID}/summary | flutter: `activity_session_controls_test.dart` › Submit sends every answer, then shows the summary [case:matching.activ<br>flutter: `activity_session_controls_test.dart` › Submit with a round unanswered asks for all answers<br>+5 more | automated |
| Time is up — Load Summary | button | `qa.activity.time_up_load` | calls GET /v1/activities/sessions/{sessionID}/summary | flutter: `activity_session_controls_test.dart` › when time is up the summary loads once, and Load Summary fetches it ag<br>flutter: `activity_session_controls_test.dart` › when time is up the summary loads once, and Load Summary | automated |
| Refresh Summary | button | `qa.activity.refresh_summary` | calls GET /v1/activities/sessions/{sessionID}/summary | flutter: `activity_session_controls_test.dart` › waiting on the other person: Refresh Summary fetches it [case:matching<br>flutter: `activity_session_controls_test.dart` › waiting on the other person: Refresh Summary fetches it<br>+1 more | automated |
| Share Result to Chat | button | `qa.activity.share_result` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `activity_session_controls_test.dart` › Share Result to Chat hands the result back to the opener [case:matchin<br>flutter: `activity_session_controls_test.dart` › Share Result to Chat hands the result back to the opener | automated |

#### MatchNotificationScreen — `matching.match_notification`

Route: opened from: home_discovery_screen, liked_me_screen, profile_actions · Source: `app/lib/features/matching/screens/match_notification_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Send Message | button | `qa.match_notification.send_message` | may open ChatScreen | flutter: `discover_deck_controls_test.dart` › Like a mutual like opens the match screen, and Send Message opens the <br>flutter: `profile_entry_points_test.dart` › profile page controls Love that makes a match → Send Message stays in <br>+5 more | automated |
| Keep Swiping | button | `qa.match_notification.keep_swiping` | closes screen/sheet | flutter: `discover_deck_controls_test.dart` › Like Keep Swiping closes the match screen back to the deck [case:match<br>flutter: `discover_deck_controls_test.dart` › Like > Keep Swiping closes the match screen back to the deck<br>+2 more | automated |

#### MatchesListScreen — `matching.matches_list`

Route: #/matches (web) / bottom nav: Matches tab (mobile) · Source: `app/lib/features/matching/screens/matches_list_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Messages | button | — | local/unclassified action — callback: () => ref.read(matchesViewProvider.notifier).state = MatchesView.conversations ⚠  | flutter: `matches_list_controls_test.dart` › views, search and filters Discover's Messages opens the conversations  | automated |
| Call history | button | `qa.calls.history` | may open CallHistoryScreen | flutter: `matches_list_controls_test.dart` › views, search and filters Call history opens the call history [case:ma<br>flutter: `matches_list_controls_test.dart` › views, search and filters > Call history opens the call history | automated |
| Search your matches | field | `qa.chat.search_conversations` | updates local state | flutter: `matches_list_controls_test.dart` › views, search and filters search narrows conversations by name or last<br>flutter: `matches_list_controls_test.dart` › views, search and filters > search narrows conversations by name or la<br>+1 more | automated |
| All conversations | toggle | `qa.matches.filter_all` | updates local state | flutter: `matches_list_controls_test.dart` › views, search and filters Unread shows only unread conversations; All <br>flutter: `matches_list_controls_test.dart` › views, search and filters > Unread shows only unread conversations; Al<br>+2 more | automated |
| Unread · {count} | toggle | `qa.matches.filter_unread` | updates local state | flutter: `matches_list_controls_test.dart` › views, search and filters Unread shows only unread conversations; All <br>flutter: `matches_list_controls_test.dart` › views, search and filters > Unread shows only unread conversations; Al<br>+1 more | automated |
| Retry | button | `qa.matches.retry` | calls GET /v1/matches/{userID}; refreshes data | flutter: `matches_list_controls_test.dart` › load and retry a failed load offers Retry, which shows the matches [ca<br>flutter: `matches_list_controls_test.dart` › load and retry > a failed load offers Retry, which shows the matches<br>+1 more | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `matches_list_controls_test.dart` › rows and cards a match card's options open the match options [case:mat | automated |
| Conversation options for {name} | gesture | `qa.matches.match_row.*` | calls POST /v1/engagement/match-nudges/send, POST /v1/safety/report, DELETE /v1/matches/{matchID}; may open ActivitySessionScreen, CallSessionScreen, Moderation | flutter: `matches_list_controls_test.dart` › rows and cards long-pressing a conversation opens its options [case:ma<br>flutter: `matches_list_controls_test.dart` › rows and cards > a conversation row marks it read and opens the chat<br>+7 more | automated |
| Conversation options for {name} | button | `qa.matches.match_row.*` | calls POST /v1/matches/{matchID}/read; may open ChatScreen | flutter: `matches_list_controls_test.dart` › rows and cards a conversation row marks it read and opens the chat [ca<br>flutter: `matches_list_controls_test.dart` › rows and cards > a conversation row marks it read and opens the chat<br>+7 more | automated |
| First Chapter | button | `qa.matches.person.*.chapter` | may open ChapterStudioScreen | flutter: `matches_list_controls_test.dart` › rows and cards First Chapter on a match card opens the chapter studio <br>flutter: `matches_list_controls_test.dart` › rows and cards > First Chapter on a match card opens the chapter studi | automated |
| Match options for {name} | button | `qa.matches.person.*.options` | calls POST /v1/engagement/match-nudges/send, POST /v1/safety/report, DELETE /v1/matches/{matchID}; may open ActivitySessionScreen, CallSessionScreen, Moderation | flutter: `matches_list_controls_test.dart` › rows and cards a match card's options open the match options [case:mat<br>flutter: `add_friend_match_sheet_test.dart` › the match options sheet sends a friend request from match<br>+1 more | automated |
| Plan a date | button | `qa.matches.person.*.plan` | opens showModalBottomSheet, showProposeDatePlanSheet | flutter: `matches_list_controls_test.dart` › rows and cards Plan a date on a match card proposes a plan [case:match<br>flutter: `matches_list_controls_test.dart` › rows and cards > Plan a date on a match card proposes a plan | automated |
| * tab | toggle | `qa.matches.*_tab` | local/unclassified action — callback: (_) => ref.read(matchesViewProvider.notifier).state = entry.key | flutter: `matches_list_controls_test.dart` › views, search and filters the tabs switch between Discover, people and<br>flutter: `matches_list_controls_test.dart` › views, search and filters > the tabs switch between Discover, people a<br>+2 more | automated |
| Start call session | button | `qa.matches.call_action` | may open CallSessionScreen; closes screen/sheet | flutter: `matches_list_controls_test.dart` › match options Start call session opens the call for this match [case:m<br>flutter: `matches_list_controls_test.dart` › match options > Start call session opens the call for this match | automated |
| Start an activity | button | `qa.matches.activity_action` | may open ActivitySessionScreen; closes screen/sheet | flutter: `matches_list_controls_test.dart` › match options Start an activity opens the activity for this match [cas<br>flutter: `matches_list_controls_test.dart` › match options > Start an activity opens the activity for this match | automated |
| Plan a date | button | `qa.matches.plan_action` | opens showModalBottomSheet, showProposeDatePlanSheet; closes screen/sheet, shows snackbar | flutter: `matches_list_controls_test.dart` › match options Plan a date sends the plan and confirms it [case:matchin<br>flutter: `matches_list_controls_test.dart` › match options > Plan a date sends the plan and confirms it | automated |
| We found each other | button | `qa.matches.graduation_action` | opens showModalBottomSheet, showProposeGraduationSheet; closes screen/sheet, shows snackbar | flutter: `matches_list_controls_test.dart` › match options We found each other asks to graduate and confirms it [ca<br>flutter: `matches_list_controls_test.dart` › match options > We found each other asks to graduate and confirms it | automated |
| Send a nudge | button | `qa.matches.nudge_action` | calls POST /v1/engagement/match-nudges/send; closes screen/sheet, shows snackbar | flutter: `matches_list_controls_test.dart` › match options Send a nudge sends it and confirms [case:matching.matche<br>flutter: `matches_list_controls_test.dart` › match options > a refused nudge shows the reason | automated |
| Close conversation | button | `qa.matches.unmatch_action` | calls DELETE /v1/matches/{matchID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `matches_list_controls_test.dart` › match options Close conversation ends the match and removes the row [c<br>flutter: `matches_list_controls_test.dart` › match options > Close conversation asks first; Keep talking keeps it<br>+2 more | automated |
| Close this conversation? | sheet | `qa.matches.unmatch_action` | presents a dialog/picker | flutter: `matches_list_controls_test.dart` › match options Close conversation asks first; Keep talking keeps it [ca<br>flutter: `matches_list_controls_test.dart` › match options > Close conversation asks first; Keep talking keeps it<br>+2 more | automated |
| Keep talking | button | `qa.matches.close_dialog.keep` | closes screen/sheet, pops a result to caller | flutter: `matches_list_controls_test.dart` › match options Close conversation asks first; Keep talking keeps it [ca<br>flutter: `matches_list_controls_test.dart` › match options > Close conversation asks first; Keep talking keeps it | automated |
| Close conversation | button | `qa.matches.close_dialog.confirm` | closes screen/sheet, pops a result to caller | flutter: `matches_list_controls_test.dart` › match options Close conversation ends the match and removes the row [c<br>flutter: `matches_list_controls_test.dart` › match options > Close conversation ends the match and removes the row<br>+1 more | automated |
| Report | button | `qa.matches.report_action` | calls POST /v1/safety/report; may open ModerationAppealsScreen; opens showModalBottomSheet, showReportUserSheet; closes screen/sheet, shows snackbar | flutter: `matches_list_controls_test.dart` › match options Report sends the report; Appeal opens the appeal [case:m<br>flutter: `matches_list_controls_test.dart` › match options > Report sends the report; Appeal opens the appeal<br>+1 more | automated |
| Submit report | button | — | calls POST /v1/safety/report | flutter: `matches_list_controls_test.dart` › match options Report sends the report; Appeal opens the appeal [case:m<br>flutter: `matches_list_controls_test.dart` › match options > Report sends the report; Appeal opens the appeal<br>+1 more | automated |
| Appeal | button | — | may open ModerationAppealsScreen | flutter: `matches_list_controls_test.dart` › match options Report sends the report; Appeal opens the appeal [case:m<br>flutter: `matches_list_controls_test.dart` › match options > Report sends the report; Appeal opens the appeal | automated |
| Add friend (match options) | menu | — | an option inside the match options sheet; the sheet's items are not extracted | flutter: `matches_list_controls_test.dart` › match options Add friend in the options sends a friend request [case:m | automated |

#### MatchOverviewCard — `matching.match_overview_card`

Route: opened from: matches_list_screen · Source: `app/lib/features/matching/widgets/match_overview_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Open chat | button | `qa.matches.person.*.chat` | local/unclassified action — callback: onChat ⚠  | flutter: `matches_list_controls_test.dart` › rows and cards Open chat on a match card opens the chat [case:matching<br>flutter: `matches_list_controls_test.dart` › rows and cards > Open chat on a match card opens the chat | automated |

### Chat (dating)

#### ChatScreen — `messaging.chat`

Route: opened from: match_notification_screen, matches_list_screen, plans_screen, profile_actions · Source: `app/lib/features/messaging/screens/chat_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| All conversations | button | `qa.chat.sidebar.back` | may open MainNavigationScreen; closes screen/sheet | flutter: `chat_controls_test.dart` › gift tray and gift send the wide layout: Send a little joy opens the t<br>flutter: `chat_controls_test.dart` › gift tray and gift send > the wide layout: Send a little joy opens the<br>+2 more | automated |
| Find the words | button | `qa.chat.sidebar.copilot` | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | flutter: `chat_controls_test.dart` › gift tray and gift send the wide layout: Send a little joy opens the t<br>flutter: `chat_controls_test.dart` › gift tray and gift send > the wide layout: Send a little joy opens the | automated |
| Send a little joy | button | `qa.chat.sidebar.gift` | calls POST /v1/chat/{matchID}/gifts/events; updates local state | flutter: `chat_controls_test.dart` › gift tray and gift send the wide layout: Send a little joy opens the t<br>flutter: `chat_controls_test.dart` › gift tray and gift send > the wide layout: Send a little joy opens the | automated |
| Back to conversations | button | `qa.chat.back_button` | may open MainNavigationScreen; closes screen/sheet | flutter: `chat_controls_test.dart` › history, read and send back returns to the conversations [case:messagi<br>flutter: `chat_controls_test.dart` › history, read and send > back returns to the conversations | automated |
| Wallet (icon toll_outlined) | button | `qa.chat.wallet_button` | calls GET /v1/chat/gifts, GET /v1/wallet/{userID}/coins; may open WalletPaymentScreen | flutter: `chat_controls_test.dart` › history, read and send the wallet chip opens the wallet and re-reads t<br>flutter: `chat_controls_test.dart` › history, read and send > the wallet chip opens the wallet and re-reads<br>+1 more | automated |
| Share a voice hello · read & listen | button | `qa.chat.voice_hello` | may open VoiceIcebreakersScreen | flutter: `chat_controls_test.dart` › history, read and send Share a voice hello opens voice hellos for this<br>flutter: `chat_controls_test.dart` › history, read and send > Share a voice hello opens voice hellos for th | automated |
| Retry | button | `qa.chat.retry` | refreshes data | flutter: `chat_controls_test.dart` › history, read and send a failed load offers Retry, which loads the his<br>flutter: `chat_controls_test.dart` › history, read and send > a failed load offers Retry, which loads the h | automated |
| starter | button | `qa.chat.starter.*` | local/unclassified action — callback: canCompose ? (text) { _messageController .text = text; _messageController .selection = Tex ⚠  | flutter: `chat_controls_test.dart` › history, read and send a starter fills the composer in an empty chat [<br>flutter: `chat_controls_test.dart` › history, read and send > a starter fills the composer in an empty chat | automated |
| Long-press message | gesture | `qa.chat.message.*` | calls DELETE /v1/chat/{matchID}/messages/{messageID}, POST /v1/chat/{}/messages/{}/gift/{}; opens showModalBottomSheet; closes screen/sheet, pops a result to ca | flutter: `chat_controls_test.dart` › long-press delete Delete for everyone removes the message; the server <br>flutter: `chat_controls_test.dart` › long-press delete > Delete for everyone removes the message; the serve<br>+4 more | automated |
| More (icon more_horiz_rounded) | button | `qa.chat.gift_receiver_actions` | calls POST /v1/chat/{}/messages/{}/gift/{}; opens showModalBottomSheet; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `chat_controls_test.dart` › received gifts Hide gift hides it from this chat only [case:messaging.<br>flutter: `chat_controls_test.dart` › received gifts > Hide gift hides it from this chat only<br>+5 more | automated |
| See plans | button | `qa.chat.daily_limit.see_plans` | may open SubscriptionScreen | flutter: `chat_controls_test.dart` › history, read and send the daily message limit shows a banner; See pla<br>flutter: `chat_controls_test.dart` › history, read and send > the daily message limit shows a banner; See p | automated |
| Conversation paused | field | `qa.chat.composer` | local/unclassified action — callback: (value) => ref .read( messageNotifierProvider( widget.matchId, ).notifier, ) .setTyping(is | flutter: `chat_controls_test.dart` › history, read and send Send posts the message, clears the composer and<br>flutter: `chat_controls_test.dart` › history, read and send > Send posts the message, clears the composer a<br>+14 more | automated |
| Help me say it | button | `qa.chat.copilot_button` | calls POST /v1/matches/{matchID}/copilot/draft; opens showCopilotSheet, showModalBottomSheet; updates local state | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills <br>flutter: `chat_controls_test.dart` › Help me say it > drafts in the chosen kind and tone; Use and edit fill<br>+3 more | automated |
| Add an emoji | button | `qa.chat.emoji_button` | opens showModalBottomSheet; closes screen/sheet | flutter: `chat_controls_test.dart` › history, read and send the emoji sheet adds the chosen emoji and close<br>flutter: `chat_controls_test.dart` › history, read and send > the emoji sheet adds the chosen emoji and clo | automated |
| Send a gift | button | `qa.chat.gift_tray_button` | calls POST /v1/chat/{matchID}/gifts/events; updates local state | flutter: `chat_controls_test.dart` › gift tray and gift send the gift button opens the tray and records the<br>flutter: `chat_controls_test.dart` › gift tray and gift send > the gift button opens the tray and records t<br>+11 more | automated |
| Send message | button | `qa.chat.send_button` | calls POST /v1/chat/{matchID}/messages, GET /v1/chat/{matchID}/messages, GET /v1/matches/{matchID}/unlock-state, POST /v1/matches/{matchID}/read; refreshes data | flutter: `chat_controls_test.dart` › history, read and send Send posts the message, clears the composer and<br>playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Today rail: Meet → M<br>+10 more | automated |
| Close gifts | button | `qa.chat.gift_tray_close` | calls POST /v1/chat/{matchID}/gifts/events; updates local state | flutter: `chat_controls_test.dart` › gift tray and gift send Close gifts closes the tray [case:messaging.ch<br>flutter: `chat_controls_test.dart` › gift tray and gift send > Close gifts closes the tray<br>+1 more | automated |
| All gifts | toggle | `qa.chat.gift_category.${category ?? ` | updates local state | flutter: `chat_controls_test.dart` › gift tray and gift send a collection chip filters the gifts; All gifts | automated |
| {count, plural, =1{1 coin} other{{count} coins}} | button | `qa.chat.gift_item.*` | calls GET /v1/chat/gifts, GET /v1/wallet/{userID}/coins, POST /v1/chat/{matchID}/gifts/send, GET /v1/chat/{matchID}/messages; may open WalletPaymentScreen; open | flutter: `chat_controls_test.dart` › gift tray and gift send a free gift is sent in one tap with the note, <br>flutter: `chat_controls_test.dart` › gift tray and gift send > a free gift is sent in one tap with the note<br>+4 more | automated |
| Not now | sheet | — | presents a bottom sheet | flutter: `chat_controls_test.dart` › gift tray and gift send a paid gift is confirmed with its price and ba | automated |
| Send for {price} | button | `qa.chat.gift_confirm.send` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › gift tray and gift send a paid gift is confirmed with its price and ba<br>flutter: `chat_controls_test.dart` › gift tray and gift send > a paid gift is confirmed with its price and  | automated |
| Not now | button | `qa.chat.gift_confirm.not_now` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › gift tray and gift send Not now sends nothing and keeps the note [case<br>flutter: `chat_controls_test.dart` › gift tray and gift send > Not now sends nothing and keeps the note | automated |
| Delete (icon delete_outline) | sheet | — | presents a bottom sheet | flutter: `chat_controls_test.dart` › long-press delete Delete for everyone removes the message; the server  | automated |
| Delete (icon delete_outline) | button | `qa.chat.delete_message_action` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › long-press delete Delete for everyone removes the message; the server <br>flutter: `chat_controls_test.dart` › long-press delete > Delete for everyone removes the message; the serve<br>+2 more | automated |
| delete message cancel | button | `qa.chat.delete_message_cancel` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › long-press delete Cancel keeps the message [case:messaging.chat.chat_d<br>flutter: `chat_controls_test.dart` › long-press delete > Cancel keeps the message | automated |
| SnackBarAction onPressed | button | — | shows snackbar | flutter: `chat_controls_test.dart` › long-press delete Undo restores the message and nothing is deleted [ca | automated |
| Hide (icon visibility_off_outlined) | sheet | — | presents a bottom sheet | flutter: `chat_controls_test.dart` › received gifts Hide gift hides it from this chat only [case:messaging. | automated |
| Hide (icon visibility_off_outlined) | button | `qa.chat.gift_hide` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › received gifts Hide gift hides it from this chat only [case:messaging.<br>flutter: `chat_controls_test.dart` › received gifts > Hide gift hides it from this chat only<br>+1 more | automated |
| Report (icon flag_outlined) | button | `qa.chat.gift_report` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › received gifts Report and hide sends the reason and details [case:mess<br>flutter: `chat_controls_test.dart` › received gifts > Report and hide sends the reason and details<br>+2 more | automated |
| gift receiver cancel | button | `qa.chat.gift_receiver_cancel` | closes screen/sheet | flutter: `chat_controls_test.dart` › received gifts long-pressing a received gift opens the same choices; C<br>flutter: `chat_controls_test.dart` › received gifts > long-pressing a received gift opens the same choices; | automated |
| gift report reason | menu | `qa.chat.gift_report_reason` | local/unclassified action — callback: (value) { if (value != null) { setSheetState(() => selectedReason = value); } } | flutter: `chat_controls_test.dart` › received gifts Report and hide sends the reason and details [case:mess<br>flutter: `chat_controls_test.dart` › received gifts > Report and hide sends the reason and details | automated |
| gift report details | field | `qa.chat.gift_report_details` | local/unclassified action — callback: (value) => details = value | flutter: `chat_controls_test.dart` › received gifts Report and hide sends the reason and details [case:mess<br>flutter: `chat_controls_test.dart` › received gifts > Report and hide sends the reason and details<br>+1 more | automated |
| Submit report (icon shield_outlined) | button | `qa.chat.gift_report_submit` | closes screen/sheet, pops a result to caller | flutter: `chat_controls_test.dart` › received gifts Report and hide sends the reason and details [case:mess<br>flutter: `chat_controls_test.dart` › received gifts > Report and hide sends the reason and details<br>+1 more | automated |
| gift report cancel | button | `qa.chat.gift_report_cancel` | closes screen/sheet | flutter: `chat_controls_test.dart` › received gifts Cancel on the report sheet sends nothing [case:messagin<br>flutter: `chat_controls_test.dart` › received gifts > Cancel on the report sheet sends nothing | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `chat_controls_test.dart` › history, read and send the emoji sheet adds the chosen emoji and close | automated |
| emoji | button | `qa.chat.emoji.*` | closes screen/sheet | flutter: `chat_controls_test.dart` › history, read and send the emoji sheet adds the chosen emoji and close<br>flutter: `chat_controls_test.dart` › history, read and send > the emoji sheet adds the chosen emoji and clo | automated |

#### CopilotSheet — `messaging.copilot_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/messaging/widgets/copilot_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills  | automated |
| kind | toggle | `qa.copilot.kind.*` | updates local state | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills <br>flutter: `chat_controls_test.dart` › Help me say it > drafts in the chosen kind and tone; Use and edit fill | automated |
| tone | toggle | `qa.copilot.tone.*` | updates local state | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills <br>flutter: `chat_controls_test.dart` › Help me say it > drafts in the chosen kind and tone; Use and edit fill<br>+1 more | automated |
| Try another | button | `qa.copilot.generate` | calls POST /v1/matches/{matchID}/copilot/draft; updates local state | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills <br>flutter: `chat_controls_test.dart` › Help me say it Try another asks for a fresh draft [case:messaging.copi<br>+5 more | automated |
| Use and edit | button | `qa.copilot.use` | calls POST /v1/matches/{matchID}/copilot/draft; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `chat_controls_test.dart` › Help me say it drafts in the chosen kind and tone; Use and edit fills <br>flutter: `chat_controls_test.dart` › Help me say it > drafts in the chosen kind and tone; Use and edit fill<br>+1 more | automated |

### Profile

#### EditProfileScreen — `profile.edit_profile`

Route: opened from: main_navigation_screen, profile_view_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/edit_profile_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Refresh profile | button | `qa.edit_profile.refresh` | refreshes data | flutter: `edit_profile_controls_test.dart` › Refresh reloads the draft and shows what changed elsewhere [case:profi<br>flutter: `edit_profile_controls_test.dart` › a failed refresh shows the error with Retry [case:profile.edit_profile<br>+3 more | automated |
| Something went wrong. Please try again. | button | — | refreshes data | flutter: `edit_profile_controls_test.dart` › Retry reloads a profile that failed to load [case:profile.edit_profile | automated |
| About you | button | — | may open SetupAboutScreen | flutter: `edit_profile_controls_test.dart` › Edit About opens About you; the saved bio shows on return [case:profil<br>appium: `test_02_edit_profile.py` › test_edit_profile_bio_save_persists_after_reopen<br>+1 more | automated |
| Location & social | button | — | may open SetupPreferencesScreen | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows on return<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Dating preferences | button | — | may open SetupPreferencesScreen | flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on return [<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile<br>+1 more | automated |
| Lifestyle | button | — | may open SetupPreferencesScreen | flutter: `edit_profile_controls_test.dart` › Lifestyle opens preferences; a saved diet shows on return [case:profil<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile<br>+1 more | automated |
| Interests & details | button | — | may open SetupPreferencesScreen | flutter: `edit_profile_controls_test.dart` › Interests & details opens preferences; saved hobbies show on return [c<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Photo gallery | button | — | may open SetupPhotosScreen | flutter: `edit_profile_controls_test.dart` › Manage photos opens the photo editor; a removed photo is gone on retur | automated |

#### ProfileViewScreen — `profile.profile_view`

Route: #/profile (web) / bottom nav: Profile tab (mobile) · Source: `app/lib/features/profile/screens/profile_view_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Starring | button | — | may open ProfileGalleryScreen | flutter: `profile_view_controls_test.dart` › photos tapping the starring photo opens the gallery on photo 1 [case:p | automated |
| {name}, photo {index} of {count} | button | — | may open ProfileGalleryScreen | flutter: `profile_view_controls_test.dart` › photos tapping a frame in the photo reel opens that photo [case:profil | automated |
| Retry | button | `qa.profile.retry` | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; refreshes data | flutter: `profile_view_controls_test.dart` › load, retry and refresh a failed load shows the server reason; Retry l<br>flutter: `profile_view_controls_test.dart` › load, retry and refresh > a failed load shows the server reason; Retry<br>+1 more | automated |
| You liked | button | `qa.profile.stat.liked` | may open LikedProfilesScreen | flutter: `profile_view_controls_test.dart` › behind the scenes You liked opens the profiles I liked [case:profile.p<br>flutter: `profile_view_controls_test.dart` › behind the scenes > You liked opens the profiles I liked | automated |
| Matches | button | `qa.profile.stat.matches` | local/unclassified action — callback: () => _openMatchesTab(MatchesView.people) ⚠  | flutter: `profile_view_stat_tiles_test.dart` › Matches tile opens the Matches tab on Your matches [case:profile.profi<br>flutter: `profile_view_stat_tiles_test.dart` › Matches tile opens the Matches tab on Your matches | automated |
| Messages | button | `qa.profile.stat.messages` | local/unclassified action — callback: () => _openMatchesTab( MatchesView.conversations, ) ⚠  | flutter: `profile_view_stat_tiles_test.dart` › Messages tile opens the Matches tab on Conversations [case:profile.pro<br>flutter: `profile_view_stat_tiles_test.dart` › Messages tile opens the Matches tab on Conversations | automated |
| Who Liked Me | button | `qa.profile.who_liked_me` | may open LikedMeScreen | flutter: `profile_view_controls_test.dart` › behind the scenes Who liked me opens the members who liked me [case:pr<br>flutter: `profile_view_controls_test.dart` › behind the scenes > Who liked me opens the members who liked me<br>+2 more | automated |
| Who Viewed My Profile | button | `qa.profile.who_viewed` | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; may open ProfileViewersScreen; refreshes data | flutter: `profile_view_controls_test.dart` › who viewed my profile the tile opens the viewers list; coming back ref<br>flutter: `profile_view_controls_test.dart` › who viewed my profile > the tile opens the viewers list; coming back r<br>+1 more | automated |
| Who viewed my profile | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; may open ProfileViewersScreen; refreshes data | flutter: `profile_view_controls_test.dart` › who viewed my profile the eye button in the top bar opens the viewers  | automated |
| Refresh profile | button | — | calls GET /v1/profile/{userID}/summary, GET /v1/profile/{userID}/draft; refreshes data | flutter: `profile_view_controls_test.dart` › load, retry and refresh Refresh reloads the summary and the published <br>appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile | automated |
| OutlinedButton.icon onPressed | button | — | local/unclassified action — callback: onTap ⚠  | flutter: `profile_view_controls_test.dart` › owner tools Edit profile opens Edit Profile; the preview reloads on re<br>flutter: `profile_view_controls_test.dart` › owner tools Photos opens the photo editor [case:profile.profile_view.o<br>+2 more | automated |
| Edit profile (profile tools) | button | `qa.profile.tool.edit` | tool row items are built from a list the extractor does not expand | flutter: `profile_view_controls_test.dart` › owner tools Edit profile opens Edit Profile; the preview reloads on re | automated |
| Photos (profile tools) | button | `qa.profile.tool.photos` | tool row items are built from a list the extractor does not expand | flutter: `profile_view_controls_test.dart` › owner tools Photos opens the photo editor [case:profile.profile_view.o | automated |
| Stories (profile tools) | button | `qa.profile.tool.stories` | tool row items are built from a list the extractor does not expand | flutter: `profile_view_controls_test.dart` › owner tools Stories opens my profile stories [case:profile.profile_vie | automated |
| Viewers (profile tools) | button | `qa.profile.tool.viewers` | tool row items are built from a list the extractor does not expand | flutter: `profile_view_controls_test.dart` › owner tools Viewers opens who viewed my profile [case:profile.profile_ | automated |

#### ProfileViewersScreen — `profile.profile_viewers`

Route: opened from: profile_view_screen · Source: `app/lib/features/profile/screens/profile_viewers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | flutter: `profile_view_controls_test.dart` › who viewed my profile a viewers list that fails explains; Retry loads <br>flutter: `profile_view_controls_test.dart` › who viewed my profile no viewers yet says so [case:profile.profile_vie | automated |

#### ProfileSetupEntryScreen — `profile.profile_setup_entry`

Route: opened from: main · Source: `app/lib/features/profile/screens/setup/profile_setup_entry_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | refreshes data | flutter: `setup_preview_entry_controls_test.dart` › ProfileSetupEntryScreen Retry reloads the setup status and resumes at <br>flutter: `setup_preview_entry_controls_test.dart` › ProfileSetupEntryScreen a member without photos starts at the photo st | automated |

#### SetupAboutScreen — `profile.setup_about`

Route: opened from: edit_profile_screen, profile_setup_entry_screen, setup_photos_screen · Source: `app/lib/features/profile/screens/setup/setup_about_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back | button | — | closes screen/sheet | flutter: `setup_about_controls_test.dart` › Back closes and keeps the edits in the draft [case:profile.setup_about | automated |
| Something went wrong. Please try again. | button | — | refreshes data | flutter: `setup_about_controls_test.dart` › Retry reloads a draft that failed to load [case:profile.setup_about.so | automated |
| Select | menu | `qa.setup.about.drinking_dropdown` | updates local state | flutter: `setup_about_controls_test.dart` › drinking choice is saved [case:profile.setup_about.setup_about_drinkin | automated |
| Select education | menu | `qa.setup.about.education_dropdown` | updates local state | flutter: `setup_about_controls_test.dart` › education picked from the menu is saved [case:profile.setup_about.setu | automated |
| Select height | menu | `qa.setup.about.height_dropdown` | updates local state | flutter: `setup_about_controls_test.dart` › height picked from the menu is saved in cm [case:profile.setup_about.s | automated |
| Prefer not to say | menu | — | updates local state | flutter: `setup_about_controls_test.dart` › income range picked under "Prefer not to say" is saved [case:profile.s | automated |
| Prefer not to say | menu | — | updates local state | flutter: `setup_about_controls_test.dart` › religion is saved with the lifestyle part [case:profile.setup_about.pr | automated |
| Save About | button | — | calls PATCH /v1/profile/{userID}/draft; may open SetupPreviewScreen; closes screen/sheet, shows snackbar, updates local state | flutter: `setup_about_controls_test.dart` › Save About sends the about and lifestyle fields once, then closes [cas<br>flutter: `setup_about_controls_test.dart` › Continue in the setup flow saves and opens the preview [case:profile.s<br>+3 more | automated |
| Select | menu | `qa.setup.about.smoking_dropdown` | updates local state | flutter: `setup_about_controls_test.dart` › smoking choice is saved [case:profile.setup_about.setup_about_smoking_ | automated |
| {min, plural, =1{Tell people about you (min 1 char)} other{T | field | `qa.setup.about.bio_field` | opens TextField | flutter: `setup_about_controls_test.dart` › typing in the bio lands in the saved draft [case:profile.setup_about.s<br>flutter: `edit_profile_controls_test.dart` › Edit About opens About you; the saved bio shows on return<br>+9 more | automated |
| e.g. Software Engineer | field | `qa.setup.about.profession_field` | opens TextField | flutter: `setup_about_controls_test.dart` › profession is saved trimmed [case:profile.setup_about.setup_about_prof<br>flutter: `setup_about_controls_test.dart` › Save About sends the about and lifestyle fields once, then<br>+1 more | automated |

#### SetupPhotosScreen — `profile.setup_photos`

Route: opened from: edit_profile_screen, profile_setup_entry_screen, profile_view_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/setup/setup_photos_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Remove this photo? | sheet | — | presents a dialog/picker | flutter: `setup_photos_controls_test.dart` › Delete the trash button asks "Remove this photo?" first [case:profile.<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+1 more | automated |
| Cancel | button | `qa.setup.photos.cancel_delete` | closes screen/sheet, pops a result to caller | flutter: `setup_photos_controls_test.dart` › Delete Cancel closes the question and keeps the photo [case:profile.se<br>flutter: `setup_photos_controls_test.dart` › Delete > Cancel closes the question and keeps the photo | automated |
| Remove | button | `qa.setup.photos.confirm_delete` | closes screen/sheet, pops a result to caller | flutter: `setup_photos_controls_test.dart` › Delete Remove deletes that photo on the server and from the list [case<br>flutter: `edit_profile_controls_test.dart` › Manage photos opens the photo editor; a removed photo is gone<br>+1 more | automated |
| Back | button | — | closes screen/sheet | flutter: `setup_photos_controls_test.dart` › Next and Back Back closes the photo editor [case:profile.setup_photos. | automated |
| Something went wrong. Please try again. | button | — | refreshes data | flutter: `setup_photos_controls_test.dart` › Next and Back Retry reloads photos that failed to load [case:profile.s | automated |
| Remove photo | button | `qa.setup.photos.delete_*` | calls DELETE /v1/profile/{userID}/photos/{photoID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `setup_photos_controls_test.dart` › Delete Remove deletes that photo on the server and from the list [case<br>flutter: `edit_profile_controls_test.dart` › Manage photos opens the photo editor; a removed photo is gone<br>+1 more | automated |
| Save Photos | button | `qa.setup.photos.next_button` | may open SetupAboutScreen; closes screen/sheet, shows snackbar | flutter: `setup_photos_controls_test.dart` › Next and Back Save Photos with fewer than 2 photos explains and stays <br>flutter: `setup_photos_controls_test.dart` › Next and Back Save Photos with enough photos closes the editor [case:p<br>+6 more | automated |
| Camera | button | `qa.setup.photos.*_button` | calls POST /v1/profile/{userID}/photos; opens photo/file picker, shows snackbar, updates local state | flutter: `setup_photos_controls_test.dart` › Camera uploads the captured photo [case:profile.setup_photos.setup_pho<br>flutter: `setup_photos_controls_test.dart` › Camera > uploads the captured photo<br>+6 more | automated |
| Gallery | button | `qa.setup.photos.*_button` | calls POST /v1/profile/{userID}/photos; opens photo/file picker, shows snackbar, updates local state | flutter: `setup_photos_controls_test.dart` › Gallery uploads the picked photo as multipart and shows it [case:profi<br>flutter: `setup_photos_controls_test.dart` › Gallery a cancelled pick sends nothing and says nothing [case:profile.<br>+7 more | automated |
| {min, plural, =1{Please upload at least 1 photo to continue. | gesture | — | calls POST /v1/profile/{userID}/photos/reorder; shows snackbar | flutter: `setup_photos_controls_test.dart` › Order dragging the first photo below the second reorders them [case:pr | automated |
| Set as profile picture | button | `qa.setup.photos.set_primary_*` | calls POST /v1/profile/{userID}/photos/reorder; shows snackbar | flutter: `setup_photos_controls_test.dart` › Order Set as profile picture moves that photo first [case:profile.setu<br>flutter: `setup_photos_controls_test.dart` › Order a double tap on Set as profile picture sends one reorder [case:p | automated |

#### SetupPreferencesScreen — `profile.setup_preferences`

Route: opened from: edit_profile_screen, main_navigation_screen, settings_screen, web_member_workspace · Source: `app/lib/features/profile/screens/setup/setup_preferences_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | `qa.setup.preferences.retry_button` | refreshes data | flutter: `setup_preferences_controls_test.dart` › Retry reloads preferences that failed to load [case:profile.setup_pref | automated |
| Back (icon arrow_back_ios_new) | button | `qa.setup.preferences.back_button` | calls PATCH /v1/profile/{userID}/draft; closes screen/sheet, shows snackbar, updates local state | flutter: `setup_preferences_controls_test.dart` › Back setup Back saves what was chosen, then goes back [case:profile.se<br>flutter: `setup_preferences_controls_test.dart` › Back Back while editing closes without saving [case:profile.setup_pref<br>+1 more | automated |
| age range | toggle | `qa.setup.preferences.age_range` | updates local state | flutter: `setup_preferences_controls_test.dart` › Basic tab dragging the age thumbs saves the new range [case:profile.se | automated |
| {km} km | toggle | `qa.setup.preferences.distance` | updates local state | flutter: `setup_preferences_controls_test.dart` › Basic tab tapping the distance track saves that distance [case:profile | automated |
| Hookups only | toggle | — | updates local state | — | **GAP** |
| Men | button | `qa.setup.preferences.seeking_*` | updates local state | flutter: `setup_preferences_controls_test.dart` › Basic tab Men toggles off and on, and the choice is saved [case:profil<br>flutter: `setup_preferences_screen_test.dart` › QA empty seeking selection prevents save | automated |
| Serious relationship only | toggle | — | updates local state | — | **GAP** |
| Verified profiles only | toggle | — | updates local state | appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| City | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Country | menu | `qa.setup.preferences.*` | updates local state | flutter: `setup_preferences_controls_test.dart` › Advanced tab dropdowns changing country clears state and city on scree<br>flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>+16 more | automated |
| Diet preference | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Diet type | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Language | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Mother tongue | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Political comfort range | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Religion preference | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Sleep schedule | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| State / Region | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Travel style | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Workout frequency | menu | `qa.setup.preferences.*` | updates local state | flutter: `edit_profile_controls_test.dart` › Location & social opens preferences; the saved country shows<br>flutter: `edit_profile_controls_test.dart` › Dating preferences opens preferences; a saved switch shows on<br>+15 more | automated |
| Save Preferences | button | — | calls POST /v1/profile/{userID}/complete, PATCH /v1/profile/{userID}/draft; may open MainNavigationScreen; closes screen/sheet, refreshes data, shows snackbar,  | flutter: `setup_preferences_controls_test.dart` › Save Preferences sends the preferences then the lifestyle part, return<br>flutter: `setup_preferences_controls_test.dart` › Save Preferences Finish in the setup flow saves, completes the profile<br>+7 more | automated |
| Basic | menu | — | local/unclassified action — callback:  | flutter: `setup_preferences_controls_test.dart` › Basic tab the Basic and Advanced tabs switch by tap and by swipe [case<br>flutter: `setup_preferences_screen_test.dart` › QA empty seeking selection prevents save<br>+4 more | automated |
| Instagram handle (without @) | field | `qa.setup.preferences.instagram_field` | opens TextField | — | **GAP** |
| Intent tags (long-term, marriage, casual…) | field | `qa.setup.preferences.intent_tags_field` | opens TextField | — | **GAP** |
| Hobbies (comma-separated) | field | `qa.setup.preferences.hobbies_field` | opens TextField | flutter: `edit_profile_controls_test.dart` › Interests & details opens preferences; saved hobbies show on | automated |
| Favourite books (comma-separated) | field | `qa.setup.preferences.books_field` | opens TextField | — | **GAP** |
| Favourite novels (comma-separated) | field | `qa.setup.preferences.novels_field` | opens TextField | — | **GAP** |
| Favourite songs (comma-separated) | field | `qa.setup.preferences.songs_field` | opens TextField | — | **GAP** |
| Extra-curricular activities (comma-separated) | field | `qa.setup.preferences.extra_curriculars_field` | opens TextField | — | **GAP** |
| Additional information | field | `qa.setup.preferences.additional_info_field` | opens TextField | — | **GAP** |
| Pet preference | field | `qa.setup.preferences.pet_preference_field` | opens TextField | — | **GAP** |
| Tags (comma-separated) | field | `qa.setup.preferences.deal_breakers_field` | opens TextField | — | **GAP** |

#### SetupPreviewScreen — `profile.setup_preview`

Route: opened from: profile_setup_entry_screen, setup_about_screen · Source: `app/lib/features/profile/screens/setup/setup_preview_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back | button | — | closes screen/sheet | flutter: `setup_preview_entry_controls_test.dart` › SetupPreviewScreen Back returns to the previous step [case:profile.set | automated |
| Something went wrong. Please try again. | button | — | refreshes data | flutter: `setup_preview_entry_controls_test.dart` › SetupPreviewScreen Retry reloads a preview that failed to load [case:p | automated |
| Complete Profile | button | `qa.setup.preview.complete_button` | calls POST /v1/profile/{userID}/complete; may open MainNavigationScreen; refreshes data, shows snackbar, updates local state | flutter: `setup_preview_entry_controls_test.dart` › SetupPreviewScreen Complete Profile completes on the server and opens <br>flutter: `setup_preview_entry_controls_test.dart` › SetupPreviewScreen a double tap completes once [case:profile.setup_pre<br>+4 more | automated |
| _PreviewBody onPageChanged | swipe | — | updates local state | flutter: `setup_preview_entry_controls_test.dart` › SetupPreviewScreen swiping the photos moves the active dot [case:profi | automated |

#### ProfileGalleryScreen — `profile.cinematic_profile`

Route: embedded / not directly routed · Source: `app/lib/features/profile/widgets/cinematic_profile.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| view full screen | swipe | — | updates local state | flutter: `profile_widgets_controls_test.dart` › ProfileGalleryScreen swiping the reel moves its counter [case:profile. | automated |
| {name}, photo {index} of {count} | swipe | `qa.profile.gallery` | updates local state | flutter: `profile_widgets_controls_test.dart` › ProfileGalleryScreen swiping moves through the photos and the counter <br>flutter: `profile_widgets_controls_test.dart` › ProfileGalleryScreen > swiping moves through the photos and the counte<br>+3 more | automated |
| Close photos | button | `qa.profile.gallery.close` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `profile_widgets_controls_test.dart` › ProfileGalleryScreen Close returns the photo that was showing [case:pr<br>flutter: `profile_widgets_controls_test.dart` › ProfileGalleryScreen system back also closes with the photo that was s<br>+3 more | automated |

#### ProfileScenes — `profile.profile_scenes`

Route: opened from: profile_details_screen, profile_view_screen · Source: `app/lib/features/profile/widgets/profile_scenes.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Read more | button | — | updates local state | flutter: `profile_widgets_controls_test.dart` › ProfileScenes Read more unfolds a long bio and Read less folds it [cas<br>flutter: `profile_widgets_controls_test.dart` › ProfileScenes a short bio has no Read more [case:profile.profile_scene | automated |

#### ShowcaseChapter — `profile.profile_showcase`

Route: embedded / not directly routed · Source: `app/lib/features/profile/widgets/profile_showcase.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| ThemeEntryTile onTap | button | — | calls POST /v1/walls/views; opens showModalBottomSheet, showThemeEntrySheet | flutter: `profile_widgets_controls_test.dart` › ProfileShowcaseScene a wall photo opens larger and counts one view [ca | automated |
| Read all their chapters | button | `qa.profile.showcase.read_all` | may open BlogScreen | flutter: `profile_widgets_controls_test.dart` › ProfileShowcaseScene "Read all their chapters" opens that writer\'s ch<br>flutter: `profile_widgets_controls_test.dart` › ProfileShowcaseScene > "Read all their chapters" opens that writer\'s <br>+1 more | automated |
| favorite border rounded (icon favorite_border_rounded) | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | flutter: `profile_widgets_controls_test.dart` › ProfileShowcaseScene a chapter opens the chapter and counts one view [ | automated |
| Only you can see this | toggle | `qa.profile.showcase.consent` | calls PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | flutter: `profile_widgets_controls_test.dart` › ProfileShowcaseScene the owner turns the showcase on and off; each cha<br>flutter: `profile_showcase_test.dart` › the owner previews it privately and can turn it on<br>+1 more | automated |

### Verification

#### VerificationLandingScreen — `verification.verification_landing`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/verification/screens/verification_landing_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| View review status | button | `qa.verification.landing.status_button` | may open VerificationStatusScreen | flutter: `verification_controls_test.dart` › Landing View review status opens the status of a submitted check [case<br>flutter: `verification_controls_test.dart` › Landing > View review status opens the status of a submitted check | automated |
| Start secure verification | button | `qa.verification.landing.start_button` | may open VerificationUploadIdScreen | flutter: `verification_controls_test.dart` › Landing Start secure verification opens the ID step [case:verification | automated |

#### VerificationSelfieScreen — `verification.verification_selfie`

Route: opened from: verification_upload_id_screen · Source: `app/lib/features/verification/screens/verification_selfie_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Gallery | button | `qa.verification.selfie.gallery_button` | opens photo/file picker, updates local state | flutter: `verification_controls_test.dart` › Selfie Gallery picks the selfie and enables Submit [case:verification. | automated |
| Camera | button | `qa.verification.selfie.camera_button` | opens photo/file picker, updates local state | flutter: `verification_controls_test.dart` › Selfie Camera takes the selfie and enables Submit [case:verification.v<br>flutter: `verification_controls_test.dart` › Selfie > Camera takes the selfie and enables Submit | automated |
| Submit | button | `qa.verification.selfie.submit_button` | calls POST /v1/verification/{userID}/submit; may open VerificationStatusScreen; updates local state | flutter: `verification_controls_test.dart` › Selfie Submit uploads both photos and shows the review status [case:ve<br>appium: `test_12_verification_safety.py` › test_verification_selfie_from_gallery_submit_reaches_status | automated |

#### VerificationStatusScreen — `verification.verification_status`

Route: opened from: verification_landing_screen, verification_selfie_screen · Source: `app/lib/features/verification/screens/verification_status_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | `qa.verification.status.retry` | refreshes data | flutter: `verification_controls_test.dart` › Status REGRESSION: an unreachable status offers Retry, which reloads i | automated |
| Rejection reason (status card) | link | — | status card content, shown for a rejected check | flutter: `verification_controls_test.dart` › Status Rejected status shows the reviewer reason [case:verification.ve | automated |

#### VerificationUploadIdScreen — `verification.verification_upload_id`

Route: opened from: main_navigation_screen, settings_screen, verification_landing_screen · Source: `app/lib/features/verification/screens/verification_upload_id_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Gallery | button | `qa.verification.id.gallery_button` | opens photo/file picker, updates local state | flutter: `verification_controls_test.dart` › ID photo Gallery picks the ID photo, shows it and enables Next [case:v | automated |
| Camera | button | `qa.verification.id.camera_button` | opens photo/file picker, updates local state | flutter: `verification_controls_test.dart` › ID photo Camera takes the ID photo and shows it [case:verification.ver<br>flutter: `verification_controls_test.dart` › ID photo > Camera takes the ID photo and shows it | automated |
| Next | button | `qa.verification.id.next_button` | may open VerificationSelfieScreen | flutter: `verification_controls_test.dart` › ID photo Next carries the ID photo to the selfie step [case:verificati<br>appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>+1 more | automated |

### Payments & Membership

#### CheckoutWaitingSheet — `payment.checkout_waiting_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/payment/screens/checkout_waiting_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to account | sheet | — | presents a bottom sheet | flutter: `checkout_controls_test.dart` › web: complete in a new tab the waiting sheet tells the member to finis | automated |
| Check confirmation | button | `qa.checkout.waiting.check_confirmation` | closes screen/sheet, pops a result to caller | flutter: `checkout_controls_test.dart` › web: complete in a new tab Check confirmation closes the sheet and ask | automated |
| Back to account | button | `qa.checkout.waiting.back_to_account` | closes screen/sheet, pops a result to caller | flutter: `checkout_controls_test.dart` › web: complete in a new tab Back to account closes the sheet as not pai<br>flutter: `checkout_controls_test.dart` › web: complete in a new tab > Back to account closes the sheet as not p | automated |

#### CheckoutWebViewScreen — `payment.checkout_webview`

Route: embedded / not directly routed · Source: `app/lib/features/payment/screens/checkout_webview_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Close checkout | button | `qa.checkout.close` | closes screen/sheet, pops a result to caller ⚠ pops a result to its opener — verify every opener handles it | flutter: `checkout_controls_test.dart` › CheckoutWebViewScreen Close checkout pops with no outcome (member left<br>flutter: `membership_controls_test.dart` › subscribe with card closing the checkout early leaves the member on Fr | automated |

#### SubscriptionScreen — `payment.subscription`

Route: opened from: chat_screen, home_discovery_screen, liked_me_screen, profile_actions, settings_screen, web_member_workspace · Source: `app/lib/features/payment/screens/subscription_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Your plan renews automatically at the end of each billing pe | gesture | — | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account | flutter: `membership_controls_test.dart` › plan catalog pull to refresh reloads plans, subscription, payments and | automated |
| Check status | button | `qa.payment.check_status.*` | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account; shows snackbar, updates local st | flutter: `membership_controls_test.dart` › unfinished checkouts on the payment account Check status re-reads the <br>flutter: `membership_controls_test.dart` › unfinished checkouts on the payment account > Check status when the ac | automated |
| Resume checkout | button | `qa.payment.resume_checkout.*` | calls GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}, GET /v1/billing/account; shows snackbar, updates local st | flutter: `membership_controls_test.dart` › unfinished checkouts on the payment account Resume checkout reopens th<br>flutter: `membership_controls_test.dart` › unfinished checkouts on the payment account > Resume checkout reopens  | automated |
| Auto-renew | toggle | `qa.membership.auto_renew` | calls POST /v1/billing/subscription/{}/${enabled ; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `membership_controls_test.dart` › auto-renew Turn off sends cancel-at-period-end and the switch, chip an<br>flutter: `membership_controls_test.dart` › auto-renew > turning auto-renew back on resumes without a confirmation | automated |
| Update card | button | `qa.membership.update_card` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; shows snackbar | flutter: `membership_controls_test.dart` › update card Update card opens a card-update checkout and confirms the <br>flutter: `membership_controls_test.dart` › update card > a failed card update explains and re-enables the button | automated |
| Payment problem? Contact support | button | `qa.membership.cycle.*` | updates local state | flutter: `membership_controls_test.dart` › plan catalog Monthly/Yearly toggle switches every price and the checko | automated |
| Subscribe with card | button | `qa.membership.plan.*` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; opens showDialog, showModa | flutter: `membership_controls_test.dart` › subscribe with card Subscribe → Continue to card → provider success → <br>flutter: `membership_controls_test.dart` › switch plan > switching asks first; Not now sends nothing<br>+1 more | automated |
| Subscribe with card | button | `qa.membership.plan.*` | calls POST /v1/billing/subscription/{userID}/change-plan, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}, GET /v1/billing/payments/{userID}; opens | flutter: `membership_controls_test.dart` › switch plan Switch plan changes the live subscription and confirms [ca<br>flutter: `membership_controls_test.dart` › switch plan > switching asks first; Not now sends nothing<br>+1 more | automated |
| sandbox | button | `qa.membership.sandbox.*` | calls POST /v1/billing/sandbox/subscriptions/{userID}/simulate | flutter: `membership_controls_test.dart` › sandbox renewal clock (debug builds only) Renewal paid advances the sa | automated |
| Switch plan | sheet | — | presents a dialog/picker | flutter: `membership_controls_test.dart` › switch plan switching asks first; Not now sends nothing [case:payment. | automated |
| Not now | button | `qa.membership.switch.not_now` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › switch plan switching asks first; Not now sends nothing [case:payment.<br>flutter: `membership_controls_test.dart` › switch plan > switching asks first; Not now sends nothing | automated |
| Switch plan | button | `qa.membership.switch.confirm` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › switch plan Switch plan changes the live subscription and confirms [ca<br>flutter: `membership_controls_test.dart` › switch plan > Switch plan changes the live subscription and confirms | automated |
| Turn off | sheet | — | presents a dialog/picker | flutter: `membership_controls_test.dart` › auto-renew turning auto-renew off asks first; Keep renewing changes no | automated |
| Keep renewing | button | `qa.membership.auto_renew_off.keep` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › auto-renew turning auto-renew off asks first; Keep renewing changes no | automated |
| Turn off | button | `qa.membership.auto_renew_off.confirm` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › auto-renew Turn off sends cancel-at-period-end and the switch, chip an | automated |
| Subscribe to {plan} | sheet | — | presents a dialog/picker | flutter: `membership_controls_test.dart` › subscribe with card Subscribe → Continue to card → provider success →  | automated |
| Not now | button | `qa.membership.subscribe.not_now` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › subscribe with card Not now closes the subscribe dialog without creati | automated |
| Continue to card | button | `qa.membership.subscribe.continue` | closes screen/sheet, pops a result to caller | flutter: `membership_controls_test.dart` › subscribe with card Subscribe → Continue to card → provider success →  | automated |
| Start exploring | sheet | — | presents a bottom sheet | flutter: `membership_controls_test.dart` › subscribe with card Subscribe → Continue to card → provider success →  | automated |
| Start exploring | button | `qa.membership.start_exploring` | closes screen/sheet | flutter: `membership_controls_test.dart` › subscribe with card Subscribe → Continue to card → provider success →  | automated |

#### WalletPaymentScreen — `payment.wallet_payment`

Route: opened from: chat_screen · Source: `app/lib/features/payment/screens/wallet_payment_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Coins are used for gifts and boosts inside Connect. Purchase | gesture | — | local/unclassified action — callback: ref.read(_wallet.notifier).load ⚠  | flutter: `wallet_controls_test.dart` › pull to refresh re-reads the balance and history from the server [case | automated |
| Opening… | button | `qa.wallet.buy.*` | calls POST /v1/billing/checkout, GET /v1/billing/checkout/{checkoutID}, GET /v1/billing/plans, GET /v1/billing/subscription/{userID}; shows snackbar | flutter: `wallet_controls_test.dart` › buying a pack opens the coin checkout, and the settled credit shows in<br>flutter: `wallet_controls_test.dart` › a checkout that ends without paying adds nothing and says so | automated |

### Friends & Introducer

#### AddFriendButton — `friends.friend_actions`

Route: opened from: friends_screen, group_detail_screen, matches_list_screen, profile_details_screen, room_chat · Source: `app/lib/features/friends/friend_actions.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Cancel request | sheet | — | presents a dialog/picker | flutter: `friend_actions_controls_test.dart` › cancelling a request Requested asks first; Keep it sends nothing [case<br>flutter: `friend_actions_controls_test.dart` › cancelling a request > Requested asks first; Keep it sends nothing<br>+1 more | automated |
| Keep it | button | — | closes screen/sheet, pops a result to caller | flutter: `friend_actions_controls_test.dart` › cancelling a request Requested asks first; Keep it sends nothing [case<br>flutter: `friend_actions_controls_test.dart` › cancelling a request > Requested asks first; Keep it sends nothing | automated |
| Cancel request | button | — | closes screen/sheet, pops a result to caller | flutter: `friend_actions_controls_test.dart` › cancelling a request Cancel request withdraws it and the button is Add<br>flutter: `friend_actions_controls_test.dart` › cancelling a request > a failed cancel says why and stays Requested | automated |
| IconButton onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | flutter: `friend_actions_controls_test.dart` › the icon style sends the request from the app bar [case:friends.friend | automated |
| ListTile onTap | button | — | local/unclassified action — callback: onPressed ⚠  | flutter: `friend_actions_controls_test.dart` › the tile style (option sheets) sends the request and explains itself [ | automated |
| OutlinedButton.icon onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | flutter: `friend_actions_controls_test.dart` › cancelling a request Requested asks first; Keep it sends nothing [case | automated |
| FilledButton.tonalIcon onPressed | button | — | local/unclassified action — callback: onPressed ⚠  | flutter: `friend_actions_controls_test.dart` › Add friend sends a request from its source and turns into Requested [c | automated |

#### FriendsScreen — `friends.friends`

Route: opened from: engagement_hub_screen, main_navigation_screen, notification_inbox_screen, settings_screen, web_member_workspace · Source: `app/lib/features/friends/screens/friends_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Activity | gesture | — | local/unclassified action — callback: refresh ⚠  | flutter: `friends_controls_test.dart` › pull to refresh fetches friends, activity, vouches, intros and chats a<br>flutter: `friends_controls_test.dart` › Back closes Friends and returns to the opener<br>+11 more | automated |
| Back | button | — | closes screen/sheet | flutter: `friends_controls_test.dart` › Back closes Friends and returns to the opener [case:friends.friends.ba<br>flutter: `friends_controls_test.dart` › Back closes Friends and returns to the opener | automated |
| Add friend | button | `qa.friends.add` | opens showAddFriendSheet, showModalBottomSheet | flutter: `friends_screen_test.dart` › Add friend searches by name and sends a request [case:friends.friends.<br>flutter: `friends_controls_test.dart` › Add friend search > the Add friend sheet opens with its search and cap<br>+5 more | automated |
| Create a group | button | `qa.friends.create_group` | local/unclassified action — callback: accepted.isEmpty ? null : () => _createGroup(context, accepted) ⚠  | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups [case:friends.frien<br>flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups<br>+1 more | automated |
| Accept | button | `qa.friends.accept.*` | calls POST /v1/friends/{userID}/{friendUserID}/decision, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API [case:friends.f<br>flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API<br>+1 more | automated |
| Decline | button | `qa.friends.decline.*` | calls POST /v1/friends/{userID}/{friendUserID}/decision, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API [case:friends.f<br>flutter: `friends_controls_test.dart` › requests > a failed Decline (offline) explains and keeps the request<br>+1 more | automated |
| Cancel | button | `qa.friends.cancel.*` | calls DELETE /v1/friends/{userID}/{friendUserID}, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities | flutter: `friends_screen_test.dart` › accepting and declining requests call the decision API [case:friends.f<br>flutter: `friends_controls_test.dart` › requests > a failed Cancel keeps the outgoing request and explains<br>+1 more | automated |
| Friend | button | `qa.friends.chat.*` | may open SocialChatScreen; refreshes data | flutter: `friends_controls_test.dart` › friend chats tapping a friend conversation opens that chat and refresh | automated |
| No thanks | button | `qa.friends.intro_decline.*` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | flutter: `friends_controls_test.dart` › intros and vouches waiting on me No thanks declines the intro and remo<br>flutter: `friends_controls_test.dart` › intros and vouches waiting on me > No thanks declines the intro and re<br>+1 more | automated |
| Keep private | button | `qa.friends.vouch_hide.*` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | flutter: `friends_controls_test.dart` › intros and vouches waiting on me Keep private hides a pending vouch fr<br>flutter: `friends_controls_test.dart` › intros and vouches waiting on me > Keep private hides a pending vouch <br>+1 more | automated |
| Introduce | button | `qa.friends.intro_action` | opens showIntroSheet, showModalBottomSheet; shows snackbar | flutter: `friend_social_test.dart` › the intro sheet needs two different friends [case:friends.friends.frie<br>flutter: `friend_social_test.dart` › the intro sheet needs two different friends | automated |
| More for {name} | menu | `qa.friends.menu.*` | calls DELETE /v1/friends/{userID}/{friendUserID}, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities, POST /v1/safety/block; opens showDialog, showIn | flutter: `friends_controls_test.dart` › friend menu Remove friend asks first, then deletes the friendship and <br>appium: `test_19_friends.py` › test_remove_friend_from_menu | automated |
| Message {name} | button | `qa.friends.message.*` | calls POST /v1/social/friends/{friendID}/channel; may open SocialChatScreen; refreshes data, shows snackbar | flutter: `friends_screen_test.dart` › Message opens the friend chat [case:friends.friends.friends_message_x_<br>flutter: `friends_screen_test.dart` › Message opens the friend chat<br>+1 more | automated |
| Hide from profile | button | — | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros | flutter: `friends_controls_test.dart` › intros and vouches waiting on me Hide from profile takes an approved v<br>flutter: `friends_controls_test.dart` › intros and vouches waiting on me > Hide from profile takes an approved<br>+1 more | automated |
| Date plans shared with you | button | `qa.friends.plans_link` | may open PlansScreen | flutter: `friends_controls_test.dart` › more links Date plans shared with you opens Plans on the friends tab [<br>flutter: `friends_controls_test.dart` › more links > Date plans shared with you opens Plans on the friends tab | automated |
| Invite a friend who isn’t dating | button | — | may open IntroducerScreen | flutter: `friends_controls_test.dart` › more links Invite a friend who isn’t dating opens the introducer contr | automated |
| Introductions, on your terms | button | — | may open DatingRhythmScreen | flutter: `friends_controls_test.dart` › more links Introductions, on your terms opens the dating rhythm settin<br>flutter: `friends_controls_test.dart` › more links > Introductions, on your terms opens the dating rhythm sett | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `friends_controls_test.dart` › Add friend search the Add friend sheet opens with its search and capti | automated |
| Name or @username | field | `qa.friends.search_field` | updates local state | flutter: `friends_screen_test.dart` › Add friend searches by name and sends a request [case:friends.friends.<br>flutter: `friends_controls_test.dart` › Add friend search > submitting from the keyboard searches at once (no <br>+2 more | automated |
| Name or @username | field | `qa.friends.search_field` | updates local state | flutter: `friends_controls_test.dart` › Add friend search submitting from the keyboard searches at once (no de<br>flutter: `friends_controls_test.dart` › Add friend search > submitting from the keyboard searches at once (no <br>+2 more | automated |
| @${f.username} | toggle | `qa.friends.group_pick.*` | updates local state | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups [case:friends.frien<br>flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups | automated |
| Create a group with {count} | button | `qa.friends.group_continue` | closes screen/sheet, pops a result to caller | flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups [case:friends.frien<br>flutter: `friends_screen_test.dart` › Create a group passes the chosen friends to Groups<br>+1 more | automated |
| Accept intro | button | `qa.friends.intro_accept.*` | keyed control inside a list builder the extractor does not reach | flutter: `friend_social_test.dart` › an incoming intro shows the other person and can be accepted [case:fri | automated |
| Approve vouch | button | `qa.friends.vouch_approve.*` | keyed control inside a list builder the extractor does not reach | flutter: `friend_social_test.dart` › a pending vouch can be approved for the profile [case:friends.friends. | automated |

#### IntroducerScreen — `friends.introducer`

Route: opened from: friends_screen, main · Source: `app/lib/features/friends/screens/introducer_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Remove permission for {name}? | sheet | — | presents a dialog/picker | flutter: `introducer_test.dart` › removing permission requires the clear in-app choice [case:friends.int<br>flutter: `introducer_controls_test.dart` › member: Your introducers > Decline request asks, then removes the pend<br>+3 more | automated |
| Keep permission | button | — | closes screen/sheet, pops a result to caller | flutter: `introducer_controls_test.dart` › introducer workspace Keep permission closes the question and changes n<br>flutter: `introducer_controls_test.dart` › introducer workspace > Keep permission closes the question and changes | automated |
| Remove permission | button | — | closes screen/sheet, pops a result to caller | flutter: `introducer_test.dart` › removing permission requires the clear in-app choice [case:friends.int<br>flutter: `introducer_controls_test.dart` › member: Your introducers > Decline request asks, then removes the pend<br>+2 more | automated |
| Refresh permissions | button | — | refreshes data | flutter: `introducer_controls_test.dart` › introducer workspace Refresh permissions reloads permissions and sent  | automated |
| Account | menu | — | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open AccountDataScreen | flutter: `introducer_controls_test.dart` › introducer workspace Account: Account & privacy opens account data; Si<br>flutter: `introducer_controls_test.dart` › introducer workspace > Sign out still ends the local session when the <br>+3 more | automated |
| Try again | button | — | refreshes data | flutter: `introducer_controls_test.dart` › introducer workspace when permissions fail to load, Try again reloads  | automated |
| Allow introductions | button | — | calls POST /v1/introducer/connections/{consentID}/approve; refreshes data, shows snackbar, updates local state | flutter: `introducer_controls_test.dart` › member: Your introducers Allow introductions approves the request and <br>flutter: `introducer_test.dart` › member can approve a named request with explicit disclosure | automated |
| Decline request | button | — | calls DELETE /v1/introducer/connections/{consentID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates loc | flutter: `introducer_controls_test.dart` › member: Your introducers Decline request asks, then removes the pendin | automated |
| Reload sent introductions | button | — | refreshes data | flutter: `introducer_controls_test.dart` › introducer workspace when sent introductions fail to load, Reload brin | automated |
| Include my profile photo | toggle | — | updates local state | flutter: `introducer_controls_test.dart` › member: Your introducers the preview switches decide what the invitati | automated |
| Include my city | toggle | — | updates local state | flutter: `introducer_controls_test.dart` › member: Your introducers the preview switches decide what the invitati | automated |
| Create invitation code | button | — | calls POST /v1/introducer/invites; refreshes data, shows snackbar, updates local state | flutter: `introducer_controls_test.dart` › member: Your introducers Create invitation code shows the one-time cod<br>flutter: `introducer_test.dart` › invitation preview defaults to no photo and no city | automated |
| SelectableText input | field | — | opens SelectableText | flutter: `introducer_controls_test.dart` › member: Your introducers Create invitation code shows the one-time cod | automated |
| Copy code | button | — | copies to clipboard, shows snackbar | flutter: `introducer_controls_test.dart` › member: Your introducers Copy code puts the code on the clipboard and  | automated |
| Cancel unused invitations | button | — | calls DELETE /v1/introducer/invites; refreshes data, shows snackbar, updates local state | flutter: `introducer_controls_test.dart` › member: Your introducers Cancel unused invitations revokes the code an | automated |
| Manage all introduction preferences | button | — | may open DatingRhythmScreen; refreshes data | flutter: `introducer_controls_test.dart` › member: Your introducers Manage all introduction preferences opens Dat | automated |
| Invitation code | field | — | opens TextField | flutter: `introducer_controls_test.dart` › introducer workspace typing an invitation code fills the field [case:f<br>flutter: `introducer_controls_test.dart` › introducer workspace > typing an invitation code fills the field<br>+1 more | automated |
| Ask for permission | button | — | calls POST /v1/introducer/redeem; refreshes data, shows snackbar, updates local state | flutter: `introducer_controls_test.dart` › introducer workspace Ask for permission redeems the code, confirms and | automated |
| First friend | menu | — | updates local state | flutter: `introducer_controls_test.dart` › introducer workspace suggesting an introduction only friends who gave  | automated |
| Second friend | menu | — | updates local state | flutter: `introducer_controls_test.dart` › introducer workspace suggesting an introduction only friends who gave  | automated |
| Why you thought of them (optional) | field | — | opens TextField | flutter: `introducer_controls_test.dart` › introducer workspace suggesting an introduction Suggest sends both fri | automated |
| Suggest an introduction | button | — | calls POST /v1/friends/{userID}/intros; refreshes data, shows snackbar, updates local state | flutter: `introducer_controls_test.dart` › introducer workspace suggesting an introduction Suggest sends both fri | automated |

#### FriendSocialSheets — `friends.friend_social_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/friends/widgets/friend_social_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `friend_social_sheets_controls_test.dart` › vouch sheet opens for that friend with the field and Send vouch [case: | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `friend_social_sheets_controls_test.dart` › intro sheet opens with two pickers of accepted friends only [case:frie | automated |
| Your vouch | field | `qa.friends.vouch_text` | opens TextField | flutter: `friend_social_sheets_controls_test.dart` › vouch sheet typing fills the vouch and counts towards 200 characters [<br>flutter: `friend_social_sheets_controls_test.dart` › vouch sheet > typing fills the vouch and counts towards 200 characters<br>+1 more | automated |
| Send vouch | button | `qa.friends.vouch_submit` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities; closes screen/sheet, pop | flutter: `friend_social_sheets_controls_test.dart` › vouch sheet Send vouch posts it, reloads vouches and closes with true <br>flutter: `friend_social_sheets_controls_test.dart` › vouch sheet > Send vouch posts it, reloads vouches and closes with tru | automated |
| First friend | toggle | `qa.friends.intro_first` | updates local state | flutter: `friend_social_sheets_controls_test.dart` › intro sheet choosing a first friend selects it and removes it from the | automated |
| Second friend | toggle | `qa.friends.intro_second` | updates local state | flutter: `friend_social_sheets_controls_test.dart` › intro sheet choosing a second friend selects it and removes it from th | automated |
| Why they should meet (optional) | field | `qa.friends.intro_message` | opens TextField | flutter: `friend_social_sheets_controls_test.dart` › intro sheet the note is sent trimmed with the intro and the sheet clos | automated |
| Make the intro | button | `qa.friends.intro_submit` | calls GET /v1/friends/{userID}/vouches, GET /v1/friends/{userID}/intros, GET /v1/friends/{userID}, GET /v1/friends/{userID}/activities; closes screen/sheet, pop | flutter: `friend_social_test.dart` › the intro sheet needs two different friends [case:friends.friends.frie<br>flutter: `friend_social_test.dart` › the intro sheet needs two different friends | automated |

### Social Chat (friends/rooms/groups)

#### SocialChatScreen — `social_chat.social_chat`

Route: embedded / not directly routed · Source: `app/lib/features/social_chat/social_chat_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| This member | sheet | — | presents a bottom sheet | — | **GAP** |
| Try sending again | button | `qa.social_chat.action.retry` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Copy text | button | `qa.social_chat.action.copy` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Remove message | button | `qa.social_chat.action.delete` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report message | button | `qa.social_chat.action.report` | closes screen/sheet, pops a result to caller | — | **GAP** |
| This member | button | `qa.social_chat.action.sender` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Mute notifications | button | — | calls DELETE /v1/social/channels/{channelID}/mute, PUT /v1/social/channels/{channelID}/mute, DELETE /v1/social/channels/{channelID}/messages/{messageID}; opens  | flutter: `chat_mutes_test.dart` › the bell mutes a friend chat’s notifications and turns them<br>flutter: `chat_mutes_test.dart` › the chat and the mute sheet speak German<br>+1 more | automated |
| This conversation is unavailable. You may no longer be a mem | button | `qa.social_chat.retry` | refreshes data | — | **GAP** |
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
| Save changes | button | — | closes screen/sheet, shows snackbar, updates local state | — | **GAP** |
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
| Join | gesture | — | local/unclassified action — callback: refresh ⚠  | flutter: `groups_controls_test.dart` › pull to refresh reloads my groups, invitations, lifestyles, discover a | automated |
| Start a group | button | — | may open CreateGroupScreen | flutter: `groups_controls_test.dart` › Start a group opens the create flow as a community group [case:groups. | automated |
| Invitation declined. | button | — | may open GroupDetailScreen | flutter: `groups_controls_test.dart` › invitations tapping an invitation opens that group [case:groups.groups | automated |
| Decline | button | — | calls POST /v1/engagement/groups/{groupID}/invites/respond; shows snackbar, updates local state | flutter: `groups_controls_test.dart` › invitations Decline answers the invitation, says so and removes the ca | automated |
| Join a community below, or start a private group with your f | button | — | may open GroupDetailScreen | flutter: `groups_controls_test.dart` › tapping one of my groups opens it [case:groups.groups.join_a_community<br>flutter: `groups_controls_test.dart` › with no groups yet the empty note invites me to join or start [case:gr | automated |
| All | toggle | — | updates local state | flutter: `groups_controls_test.dart` › discover by lifestyle All clears a lifestyle filter and shows every co | automated |
| ${c.emoji}  ${c.title} ·  | toggle | — | updates local state | flutter: `groups_controls_test.dart` › discover by lifestyle a lifestyle chip filters Discover on the server <br>flutter: `groups_test.dart` › discover filters by lifestyle and joins a group | automated |
| Be the first: start a community group and invite your friend | button | — | may open CreateGroupScreen | flutter: `groups_controls_test.dart` › discover by lifestyle an empty lifestyle offers Start one, which opens | automated |
| Join | button | — | may open GroupDetailScreen | flutter: `groups_controls_test.dart` › discover by lifestyle tapping a community card opens it [case:groups.g | automated |
| Join | button | — | shows snackbar, updates local state | flutter: `groups_controls_test.dart` › discover by lifestyle Join on a community joins it, welcomes me and mo<br>flutter: `groups_test.dart` › discover filters by lifestyle and joins a group | automated |
| Join (group invitation) | button | — | the invitation card's Join callback (onRespond) is extracted only for Decline | flutter: `groups_controls_test.dart` › invitations Join on an invitation accepts it, welcomes me and lists th | automated |
| Try again (groups failed to load) | button | — | retry notice rendered by a shared error widget | flutter: `groups_controls_test.dart` › pull to refresh a refresh while offline shows the retry notice without<br>flutter: `groups_controls_test.dart` › pull to refresh lifestyles that fail to load offer Try again, which br | automated |

### Engagement Hub

#### CircleChallengesScreen — `engagement.circle_challenges`

Route: opened from: engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/circle_challenges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Submit Entry | gesture | — | calls GET /v1/engagement/circles/{circleID}/challenge | flutter: `circle_challenges_controls_test.dart` › pull to refresh pull to refresh reloads every circle's challenge for t | automated |
| Join Circle | button | `qa.circles.join.*` | calls POST /v1/engagement/circles/{circleID}/join | flutter: `circle_challenges_controls_test.dart` › Join Circle Join Circle joins this member and flips the card to Joined | automated |
| Weekly challenge response | field | `qa.circles.response.*` | opens TextField | flutter: `circle_challenges_controls_test.dart` › weekly challenge response the response field takes typed text and show | automated |
| Submit Entry | button | `qa.circles.submit.*` | calls POST /v1/engagement/circles/{circleID}/challenge/entries | flutter: `circle_challenges_controls_test.dart` › Submit Entry Submit Entry posts this week's entry and the card shows J | automated |

#### ConversationRoomsScreen — `engagement.conversation_rooms`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/conversation_rooms_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `rooms_controls_test.dart` › start a room Start a room opens the start sheet; dismissing it sends n | automated |
| tile | button | — | calls POST /v1/rooms/{roomID}/join, GET /v1/rooms; may open SocialChatScreen; opens showModalBottomSheet; shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › tapping a room joins it and opens its chat [case:engagement.conversati<br>flutter: `rooms_controls_test.dart` › room tile Tapping a room joins it once, shows it is busy, opens its ch<br>+8 more | automated |
| Start a room | button | — | calls GET /v1/rooms; may open SocialChatScreen; opens showModalBottomSheet | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room > Start now that fails shows the reason in the sheet, kee<br>+2 more | automated |
| Rooms members are hosting. Join early to save a spot. | gesture | — | calls GET /v1/rooms; shows snackbar | flutter: `rooms_controls_test.dart` › list Pull to refresh reloads the rooms and shows the new counts [case: | automated |
| Back (icon arrow_back_rounded) | button | `qa.rooms.back` | closes screen/sheet | flutter: `rooms_controls_test.dart` › list Back closes Rooms and returns to where it was opened [case:engage | automated |
| Try again | button | `qa.rooms.retry` | calls GET /v1/rooms; shows snackbar | flutter: `rooms_controls_test.dart` › list Try again after a failed first load fetches the rooms and shows t<br>flutter: `rooms_controls_test.dart` › list > Try again after a failed first load fetches the rooms and | automated |
| All | toggle | — | local/unclassified action — callback: notifier.setCategory | flutter: `rooms_controls_test.dart` › list Topic chips filter the browse list; All brings every room back; a | automated |
| Friends here | toggle | — | local/unclassified action — callback: (on) => notifier.setFriendOnly(value: on) | flutter: `rooms_controls_test.dart` › list Friends here keeps only rooms with a friend inside; with no match | automated |
| Room name | field | — | opens TextField | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room > Start now that fails shows the reason in the sheet, kee<br>+1 more | automated |
| What’s it about? (optional) | field | — | opens TextField | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room > Start now that fails shows the reason in the sheet, kee | automated |
| category | toggle | `qa.rooms.start.category.*` | updates local state | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room Topic chips and lengths switch the pick: City and 2 hours | automated |
| 30 min | toggle | `qa.rooms.start.length` | updates local state | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room Topic chips and lengths switch the pick: City and 2 hours | automated |
| Start now | button | — | calls POST /v1/rooms; closes screen/sheet, pops a result to caller, updates local state | flutter: `rooms_controls_test.dart` › start a room Start now sends the name, line, topic and length once, cl<br>flutter: `rooms_controls_test.dart` › start a room > Start now that fails shows the reason in the sheet, kee<br>+1 more | automated |

#### DailyPromptScreen — `engagement.daily_prompt`

Route: opened from: engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/daily_prompt_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Update Answer | gesture | — | calls GET /v1/engagement/daily-prompt/{userID}, GET /v1/engagement/daily-prompt/{userID}/responders | flutter: `daily_prompt_controls_test.dart` › pull to refresh pull to refresh reloads the prompt and responders and  | automated |
| Type your response in under 60 seconds. | field | `qa.daily_prompt.answer` | opens TextField | flutter: `daily_prompt_controls_test.dart` › answer field typing fills the answer field and counts characters again | automated |
| Update Answer | button | `qa.daily_prompt.submit` | calls POST /v1/engagement/daily-prompt/{userID}/answer, GET /v1/engagement/daily-prompt/{userID}/responders | flutter: `daily_prompt_controls_test.dart` › Update Answer Update Answer saves the edited answer, reloads responder<br>flutter: `daily_prompt_controls_test.dart` › Update Answer first answer of the day uses Submit Daily Answer and the | automated |

#### EngagementHubScreen — `engagement.engagement_hub`

Route: #/engagement (web) / bottom nav: Engage tab (mobile) · Source: `app/lib/features/engagement/screens/engagement_hub_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Blog · Open Chapters | button | — | may open BlogScreen | — | **GAP** |
| Photo Themes | button | — | may open PhotoThemesScreen | — | **GAP** |
| Book & Film Clubs | button | — | may open ClubsScreen | — | **GAP** |
| The City Pilot | button | — | may open CityPilotScreen | — | **GAP** |
| Daily Prompt Streak | button | — | may open DailyPromptScreen | flutter: `engagement_hub_controls_test.dart` › Daily Prompt tile previews how many people replied today and opens tha | automated |
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
| Finalize Poll | gesture | — | calls GET /v1/engagement/group-coffee-polls | flutter: `group_coffee_polls_controls_test.dart` › pull to refresh pull to refresh reloads my polls and shows the latest  | automated |
| Participant user IDs (comma-separated) | field | `qa.coffee.participants` | opens TextField | flutter: `group_coffee_polls_controls_test.dart` › participants field typed participant ids are split on commas into the  | automated |
| Deadline ISO (optional) | field | `qa.coffee.deadline` | opens TextField | flutter: `group_coffee_polls_controls_test.dart` › deadline field a typed deadline is sent as deadline_at [case:engagemen | automated |
| Create Poll | button | `qa.coffee.create` | calls POST /v1/engagement/group-coffee-polls, GET /v1/engagement/group-coffee-polls | flutter: `group_coffee_polls_controls_test.dart` › Create Poll Create Poll sends the participants, both options and the d | automated |
| Action user ID override (optional) | field | `qa.coffee.actor` | opens TextField | flutter: `group_coffee_polls_controls_test.dart` › action user override field an override id is sent as the vote and fina | automated |
| Vote | button | `qa.coffee.vote.` | calls POST /v1/engagement/group-coffee-polls/{pollID}/votes, GET /v1/engagement/group-coffee-polls | flutter: `group_coffee_polls_controls_test.dart` › Vote Vote records my vote for that option and the list shows the new c | automated |
| Finalize Poll | button | `qa.coffee.finalize.*` | calls POST /v1/engagement/group-coffee-polls/{pollID}/finalize, GET /v1/engagement/group-coffee-polls | flutter: `group_coffee_polls_controls_test.dart` › Finalize Poll Finalize Poll closes the poll for everyone and the butto | automated |
| Day | field | — | opens TextField | — | **GAP** |
| Time window | field | — | opens TextField | — | **GAP** |
| Neighborhood | field | — | opens TextField | — | **GAP** |

#### LevelProgressionScreen — `engagement.level_progression`

Route: opened from: blog_follow, engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/level_progression_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| retry | button | `qa.level.retry` | calls GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | — | **GAP** |
| Progression is paused while an account safety review is acti | gesture | — | calls GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | flutter: `level_progression_controls_test.dart` › pull to refresh pull to refresh reloads progress and ledger and shows  | automated |
| Locked | button | `qa.level.claim.*` | calls POST /v1/progression/{userID}/rewards/claim, GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | flutter: `level_progression_controls_test.dart` › Claim Claim redeems an unlocked reward, reloads my progress and celebr | automated |
| retry | button | `qa.level.retry` | calls GET /v1/progression/{userID}, GET /v1/progression/{userID}/ledger | flutter: `level_progression_controls_test.dart` › error card Retry Retry after a failed first load fetches progress and  | automated |

#### MatchNudgesScreen — `engagement.match_nudges`

Route: opened from: main_navigation_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/match_nudges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Nudge | button | `qa.nudges.send.*` | calls POST /v1/engagement/match-nudges/send; shows snackbar | flutter: `match_nudges_controls_test.dart` › Nudge sends a stalled-conversation nudge for that match, confirms it a | automated |

#### RoomPresenceHeader — `engagement.room_chat`

Route: embedded / not directly routed · Source: `app/lib/features/engagement/screens/room_chat.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| message | button | — | opens showModalBottomSheet | flutter: `room_chat_controls_test.dart` › chat Tapping a sender's name opens their card with Add friend, Report  | automated |
| People (icon people_alt_outlined) | button | — | opens showModalBottomSheet, showRoomMembersSheet | flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation [case:engagement.<br>flutter: `room_chat_controls_test.dart` › people People lists who is here: hosts first, roles, here now, you [ca<br>+20 more | automated |
| Room options | menu | — | calls POST /v1/rooms/{roomID}/leave, POST /v1/rooms/{roomID}/moderate, GET /v1/rooms; opens showDialog, showModalBottomSheet, showRoomMembersSheet; closes scree | flutter: `room_chat_controls_test.dart` › room options A participant: People here opens the list; Leave asks fir<br>flutter: `room_chat_controls_test.dart` › room options A host of their own room: Moderate opens the moderation l<br>+9 more | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `room_chat_controls_test.dart` › people People lists who is here: hosts first, roles, here now, you [ca | automated |
| Try again | button | `qa.room.members.retry` | refreshes data | flutter: `room_chat_controls_test.dart` › people regression: who is here that fails to load shows the server's r<br>flutter: `room_chat_controls_test.dart` › people > regression: who is here that fails to load shows the<br>+1 more | automated |
| {name} (you) | button | — | opens showModalBottomSheet | flutter: `conversation_rooms_screen_test.dart` › members sheet offers Add friend and hides moderation [case:engagement.<br>flutter: `room_chat_controls_test.dart` › people Tapping someone in the list opens their card; your own row open<br>+18 more | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `room_chat_controls_test.dart` › chat Tapping a sender's name opens their card with Add friend, Report  | automated |
| Until the room ends | sheet | — | presents a bottom sheet | flutter: `room_chat_controls_test.dart` › host moderation Mute in a room the host started offers "Until the room | automated |
| timer outlined (icon timer_outlined) | button | — | closes screen/sheet, pops a result to caller | flutter: `conversation_rooms_screen_test.dart` › a host mutes a participant for an hour with mute_user [case:engagement<br>flutter: `room_chat_controls_test.dart` › host moderation Mute in an always-on room offers 10 minutes, 1 hour or<br>+5 more | automated |
| Submit report | button | — | calls POST /v1/safety/report | flutter: `room_chat_controls_test.dart` › member card Report opens the report form; Submit report sends the reas | automated |
| Report | button | — | calls POST /v1/safety/report; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `room_chat_controls_test.dart` › member card Report opens the report form; Submit report sends the reas<br>flutter: `room_chat_controls_test.dart` › member card > Report opens the report form; Submit report sends the<br>+11 more | automated |
| Block | button | — | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | flutter: `room_chat_controls_test.dart` › member card Block asks first (Cancel sends nothing), then blocks, clos<br>flutter: `room_chat_controls_test.dart` › member card > Block asks first (Cancel sends nothing), then blocks,<br>+1 more | automated |
| Warn | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › a host can warn a participant with warn_user [case:engagement.room_cha<br>flutter: `room_chat_controls_test.dart` › host moderation Warn asks first (Cancel sends nothing), then sends war<br>+3 more | automated |
| Unmute | button | — | calls POST /v1/rooms/{roomID}/moderate; closes screen/sheet, refreshes data, shows snackbar, updates local state | flutter: `conversation_rooms_screen_test.dart` › a muted member shows as muted with Unmute for the host [case:engagemen<br>flutter: `room_chat_controls_test.dart` › host moderation A muted member shows Unmute: it sends unmute_user (no <br>+3 more | automated |
| Mute | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showModalBottomSheet; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local  | flutter: `conversation_rooms_screen_test.dart` › a host mutes a participant for an hour with mute_user [case:engagement<br>flutter: `room_chat_controls_test.dart` › host moderation Mute in an always-on room offers 10 minutes, 1 hour or<br>+5 more | automated |
| Remove from room | button | — | calls POST /v1/rooms/{roomID}/moderate; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `room_chat_controls_test.dart` › host moderation Remove asks first with what it means (Cancel sends not<br>flutter: `room_chat_controls_test.dart` › host moderation > regression: Remove that fails shows the server's rea | automated |
| Send (room chat composer) | button | — | the composer is the shared social chat engine (ValueKey social.chat.send); static extraction attributes it to SocialChatScreen only | flutter: `room_chat_controls_test.dart` › chat Send posts the message to the room channel and shows it [case:eng | automated |
| Add friend (room people sheet) | button | `qa.add_friend.*` | AddFriendButton embedded in the people sheet; extracted under friends.friend_actions only | flutter: `room_chat_controls_test.dart` › people Add friend in the list sends a request that started in a room a | automated |

#### TrustBadgesScreen — `engagement.trust_badges`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/trust_badges_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| No trust history available yet. | gesture | — | calls GET /v1/users/{userID}/trust-badges | flutter: `trust_controls_test.dart` › Trust Badges pull to refresh fetches my badges and history and shows t | automated |

#### TrustFilterScreen — `engagement.trust_filter`

Route: opened from: engagement_hub_screen, settings_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/trust_filter_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Save Trust Filters | gesture | — | calls GET /v1/discovery/{userID}/filters/trust | flutter: `trust_controls_test.dart` › Trust Filters pull to refresh reloads my saved filters into the contro<br>flutter: `additional_filter_screens_test.dart` › standalone trust controls persist complete payload<br>+1 more | automated |
| Enable trust filters | toggle | `qa.trust_filter.enabled` | updates local state | flutter: `trust_controls_test.dart` › Trust Filters Enable trust filters toggles the switch locally; Save se | automated |
| minimum | toggle | `qa.trust_filter.minimum` | updates local state | flutter: `trust_controls_test.dart` › Trust Filters the minimum-badges slider updates the label locally; Sav | automated |
| badge | toggle | `qa.trust_filter.badge.*` | updates local state | flutter: `trust_controls_test.dart` › Trust Filters required-badge checkboxes toggle locally; Save sends the | automated |
| Save Trust Filters | button | `qa.trust_filter.save` | calls PATCH /v1/discovery/{userID}/filters/trust; refreshes data, shows snackbar | flutter: `trust_controls_test.dart` › Trust Filters Save Trust Filters sends the complete filter, confirms a<br>flutter: `additional_filter_screens_test.dart` › standalone trust controls persist complete payload<br>+1 more | automated |

#### VoiceIcebreakersScreen — `engagement.voice_icebreakers`

Route: opened from: chat_screen, engagement_hub_screen, web_member_workspace · Source: `app/lib/features/engagement/screens/voice_icebreakers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Try again | button | `qa.voice.retry_conversations` | refreshes data | — | **GAP** |
| Who would you like to say hello to? | menu | `qa.voice.conversation` | updates local state | — | **GAP** |
| Choose a prompt | menu | `qa.voice.prompt` | updates local state | — | **GAP** |
| Your words, in writing | field | `qa.voice.transcript` | updates local state | — | **GAP** |
| Record again · {seconds}s | button | `qa.voice.recording_button` | updates local state | only checks presence: playwright: `member-routes.spec.js` › member feature routes render at ${width}px | presence-only |
| Discard recording | button | `qa.voice.discard` | updates local state | — | **GAP** |
| Share your hello | button | `qa.voice.share` | calls POST /v1/engagement/voice-icebreakers/start, POST /v1/engagement/voice-icebreakers/{icebreakerID}/send; refreshes data, shows snackbar, updates local stat | — | **GAP** |
| Try again | button | `qa.voice.retry_intros` | refreshes data | — | **GAP** |
| SelectableText input | field | — | opens SelectableText | — | **GAP** |
| Listen · {seconds}s | button | `qa.voice.listen.*` | calls POST /v1/engagement/voice-icebreakers/{icebreakerID}/play | — | **GAP** |
| Reload prompts | button | `qa.voice.reload_prompts` | calls GET /v1/engagement/voice-icebreakers/prompts | — | **GAP** |

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
| Not now | button | `qa.debrief.not_now` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Report | button | `qa.debrief.report` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Submit report | button | — | calls POST /v1/safety/report | — | **GAP** |

#### PlanSharingSheet — `plans.plan_sharing_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/plans/screens/plan_sharing_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Close sharing | button | `qa.plan.sharing.close` | closes screen/sheet | — | **GAP** |
| A friend | toggle | `qa.plan.contact.${contact[` | updates local state | — | **GAP** |
| Reload sharing choices | button | `qa.plan.sharing.reload` | calls GET /v1/matches/{matchID}/plans/{planID}/sharing; shows snackbar, updates local state | only checks presence: flutter: `plan_sharing_sheet_test.dart` › Failed save preserves choices and never announces success | presence-only |
| Share with selected contacts | button | `qa.plan.sharing.save` | calls POST /v1/matches/{matchID}/plans/{planID}/sharing; closes screen/sheet, shows snackbar, updates local state | flutter: `plan_sharing_sheet_test.dart` › Failed save preserves choices and never announces success | automated |
| Deselect everyone | button | `qa.plan.sharing.deselect_all` | updates local state | — | **GAP** |

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
| Refresh shared times | button | `qa.plan.refresh_shared_times` | refreshes data | — | **GAP** |
| Set my availability | button | `qa.plan.set_availability` | may open DatingRhythmScreen; refreshes data | — | **GAP** |
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
| Reload latest plan · discard edits | button | `qa.plan.reload_latest` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; updates local state | — | **GAP** |
| Send your suggestion | button | `qa.plan.submit` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; closes screen/sheet, pops a result to caller, updates local state | flutter: `intentional_dating_test.dart` › counterproposal submits the version that was shown<br>flutter: `matches_list_controls_test.dart` › rows and cards > Plan a date on a match card proposes a plan<br>+1 more | automated |
| FilterChip onSelected | toggle | — | updates local state | — | **GAP** |
| Accept plan | button | `qa.plan.accept_confirm` | closes screen/sheet, pops a result to caller | — | **GAP** |

#### DatePlanCard — `plans.date_plan_card`

Route: opened from: chat_screen · Source: `app/lib/features/plans/widgets/date_plan_card.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Plan another hello | button | `qa.plan.another_hello` | opens showModalBottomSheet, showProposeDatePlanSheet | flutter: `plan_card_controls_test.dart` › Propose, counter, second yes after a mutual second yes, Plan another h | automated |
| Propose | button | `qa.plan.propose_cta` | opens showModalBottomSheet, showProposeDatePlanSheet | flutter: `plan_card_controls_test.dart` › Propose, counter, second yes Propose opens the plan sheet; sending it  | automated |
| Suggest a change | button | `qa.plan.counter` | opens showModalBottomSheet, showProposeDatePlanSheet | flutter: `plan_card_controls_test.dart` › Propose, counter, second yes Suggest a change opens the counter sheet  | automated |
| Choose who gets your updates | button | `qa.plan.sharing` | opens showModalBottomSheet, showPlanSharingSheet | flutter: `plan_card_controls_test.dart` › Choose who gets your updates opens contact sharing for this plan [case | automated |
| Ten-second debrief | button | `qa.plan.debrief` | calls POST /v1/safety/report, GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showDebriefDatePlanSheet, showDialo | flutter: `plan_card_controls_test.dart` › Debrief Ten-second debrief opens the private debrief, saves the answer<br>flutter: `date_plan_card_test.dart` › after checking in the member answers the debrief | automated |
| Decline | button | `qa.plan.decline` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | flutter: `plan_card_controls_test.dart` › Accept / Decline Decline sends the decision and the card offers a new  | automated |
| Accept | button | `qa.plan.accept` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showAcceptDatePlanSheet | flutter: `plan_card_controls_test.dart` › Accept / Decline Accept sends the decision once, opens no sheet and sh<br>flutter: `date_plan_card_test.dart` › invitee sees the proposal and accepts it<br>+2 more | automated |
| Cancel plan | button | `qa.plan.cancel` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans; opens showDialog; closes screen/sheet, pops a result to caller | flutter: `plan_card_controls_test.dart` › Cancel confirming cancels on the server and the card offers a new plan | automated |
| I need help | button | `qa.plan.need_help` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | flutter: `plan_card_controls_test.dart` › Check-in I need help records a help check-in and the card confirms fri | automated |
| I'm safe | button | `qa.plan.safe` | calls GET /v1/matches/{matchID}/plans, GET /v1/plans/{userID}, GET /v1/friends/{userID}/plans | flutter: `plan_card_controls_test.dart` › Check-in I'm safe records a safe check-in and the card says so [case:p<br>flutter: `date_plan_card_test.dart` › after the window the member can check in safe | automated |
| Cancel this plan? | sheet | — | presents a dialog/picker | flutter: `plan_card_controls_test.dart` › Cancel Cancel plan asks first and says who will be told; nothing is se | automated |
| Keep it | button | `qa.plan.keep_it` | closes screen/sheet, pops a result to caller | flutter: `plan_card_controls_test.dart` › Cancel Keep it closes the question and keeps the plan, nothing sent [c | automated |
| Cancel plan | button | `qa.plan.cancel_confirm` | closes screen/sheet, pops a result to caller | flutter: `plan_card_controls_test.dart` › Cancel confirming cancels on the server and the card offers a new plan | automated |

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
| Ask them | button | `qa.graduation.submit` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{}; closes screen/sheet, pops a result to ca | flutter: `graduation_banner_test.dart` › a member proposes from the sheet with a note and share<br>flutter: `matches_list_controls_test.dart` › match options > We found each other asks to graduate and confirms it | automated |

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
| Keep private | button | `qa.chapter.preview_keep_private` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Create share link | button | `qa.chapter.preview_share` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Refresh chapter | button | `qa.chapter.refresh` | refreshes data | — | **GAP** |
| Try again | button | `qa.chapter.retry` | refreshes data | — | **GAP** |
| ${scene[ (icon check_circle) | button | `qa.chapter.scene.${scene[` | updates local state | — | **GAP** |
| Start our chapter | button | `qa.chapter.start` | refreshes data, shows snackbar, updates local state | — | **GAP** |
| Pass the Chapter | button | `qa.chapter.pass` | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | — | **GAP** |
| Make this a date idea | button | `qa.chapter.date_idea` | opens showModalBottomSheet, showProposeDatePlanSheet | — | **GAP** |
| surprise | button | `qa.chapter.surprise.*` | refreshes data, shows snackbar, updates local state | — | **GAP** |
| Close this chapter | button | `qa.chapter.close` | refreshes data, shows snackbar, updates local state | — | **GAP** |
| Preview our anonymous story | button | `qa.chapter.give_back` | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | — | **GAP** |
| Make room for what matters to you | button | `qa.chapter.comfort_cards` | may open ComfortCardsScreen | — | **GAP** |
| Create a first chapter together | button | `qa.chapter.match.*` | may open ChapterStudioScreen | — | **GAP** |
| Reload shared chapters | button | `qa.chapter.reload_shared` | refreshes data | — | **GAP** |
| green | toggle | `qa.chapter.green.*` | updates local state | — | **GAP** |
| Save privately | button | `qa.chapter.save_green` | refreshes data, shows snackbar, updates local state | — | **GAP** |
| Copy link | button | `qa.chapter.copy.${p[` | copies to clipboard, shows snackbar | playwright: `blog-public.spec.js` › Copy link and Pass this Chapter share the canonical story URL [case:si<br>playwright: `blog-public.spec.js` › Share without a share sheet copies, and a withdrawn story hands out no | automated |
| Approve this exact story | button | `qa.chapter.approve.${p[` | refreshes data, shows snackbar, updates local state | — | **GAP** |
| Revoke link | button | `qa.chapter.revoke.${p[` | refreshes data, shows snackbar, updates local state | — | **GAP** |

#### ComfortCardsScreen — `first_chapter.comfort_cards`

Route: opened from: chapter_studio_screen · Source: `app/lib/features/first_chapter/comfort_cards_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Reload saved version | button | `qa.comfort.reload` | refreshes data | — | **GAP** |
| Reload comfort cards | button | `qa.comfort.retry` | refreshes data | — | **GAP** |
| Share these cards with my matches | toggle | `qa.comfort.shared` | updates local state | — | **GAP** |
| Remove from draft | button | `qa.comfort.remove.${card[` | updates local state | — | **GAP** |
| A little context about | menu | `qa.comfort.topic` | updates local state | — | **GAP** |
| Original language | field | `qa.comfort.language` | opens TextField | — | **GAP** |
| In your own words | field | `qa.comfort.original` | opens TextField | — | **GAP** |
| Your translation (optional) | field | `qa.comfort.translation` | opens TextField | — | **GAP** |
| Translation language (if added) | field | `qa.comfort.translation_language` | opens TextField | — | **GAP** |
| Add / replace this card in draft | button | `qa.comfort.add` | updates local state | — | **GAP** |
| Save my choices | button | `qa.comfort.save` | closes screen/sheet, refreshes data, shows snackbar, updates local state | — | **GAP** |

### Calls

#### CallHistoryScreen — `calls.call_history`

Route: opened from: matches_list_screen, settings_screen, web_member_workspace · Source: `app/lib/features/calls/screens/call_history_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Join live room | gesture | — | calls GET /v1/calls/history/{userID}; shows snackbar | flutter: `call_controls_test.dart` › call history pull to refresh reloads the history [case:calls.call_hist | automated |
| Join live room | link | `qa.calls.history.join.*` | opens external link | flutter: `call_controls_test.dart` › call history Join live room on an active call opens its room [case:cal<br>flutter: `call_controls_test.dart` › call history > Join live room on an active call opens its room | automated |

#### CallSessionScreen — `calls.call_session`

Route: opened from: matches_list_screen · Source: `app/lib/features/calls/screens/call_session_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Join live room | link | `qa.calls.join_live_room` | opens external link | flutter: `call_controls_test.dart` › call screen Join live room opens the room link outside the app [case:c<br>flutter: `call_controls_test.dart` › call screen > Join live room opens the room link outside the app<br>+2 more | automated |
| End | button | `qa.calls.end` | calls POST /v1/calls/{callID}/end; closes screen/sheet | flutter: `call_controls_test.dart` › call screen End ends the session and closes the screen [case:calls.cal<br>flutter: `call_controls_test.dart` › call screen > End ends the session and closes the screen<br>+1 more | automated |
| Try again | button | `qa.calls.try_again` | calls POST /v1/calls/start; shows snackbar | flutter: `call_controls_test.dart` › call screen a session that failed to start can be tried again [case:ca<br>flutter: `call_controls_test.dart` › call screen > a session that failed to start can be tried again<br>+1 more | automated |

### Blog / Chapters

#### BlogTextCommandScreen — `blog.blog_connections`

Route: embedded / not directly routed · Source: `app/lib/features/blog/blog_connections.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| In your own words | field | `qa.blog.text_command.field` | updates local state | flutter: `blog_connections_controls_test.dart` › private response composer Typing fills "In your own words", counts cha | automated |
| Sending… | button | `qa.blog.text_command.submit` | closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state ⚠ pops a result to its opener — verify every opener handles it | flutter: `blog_connections_controls_test.dart` › private response composer While sending, the button says Sending… and  | automated |
| Refresh | button | `qa.blog.connections.refresh` | refreshes data | flutter: `blog_connections_controls_test.dart` › connections hub Refresh reloads the current list from the server [case | automated |
| section | toggle | `qa.blog.connections.section.*` | updates local state | flutter: `blog_connections_controls_test.dart` › connections hub Section chips switch between responses, shared links a | automated |
| Could not load your connections. | button | `qa.blog.retry` | refreshes data | flutter: `blog_connections_controls_test.dart` › connections hub When connections fail to load, Try again loads them [c | automated |
| Open private exchange | button | `qa.blog.connections.open_exchange.${item[` | may open BlogExchangeScreen | flutter: `blog_connections_controls_test.dart` › connections hub Open private exchange opens that exchange [case:blog.b | automated |
| The source changed or access was withdrawn. Withdraw this li | field | `qa.blog.connections.excerpt.${item[` | opens SelectableText | flutter: `blog_connections_controls_test.dart` › shared links A shared excerpt can be selected and copied exactly [case | automated |
| Approve exact public copy | button | `qa.blog.connections.approve_copy.${item[` | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `blog_connections_controls_test.dart` › shared links Approve exact public copy asks first; Cancel sends nothin | automated |
| Copy link | button | `qa.blog.connections.copy_link.${item[` | opens showDialog; copies to clipboard, shows snackbar | flutter: `blog_connections_controls_test.dart` › shared links Copy link copies the public page link and confirms; when <br>playwright: `blog-public.spec.js` › Copy link and Pass this Chapter share the canonical story URL [case:si<br>+1 more | automated |
| Withdraw link | button | `qa.blog.connections.withdraw_link.${item[` | opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `blog_connections_controls_test.dart` › shared links Withdraw link asks first; Cancel keeps it, Withdraw delet | automated |
| Appeal this decision | button | `qa.blog.connections.appeal.${item[` | may open BlogTextCommandScreen | flutter: `blog_connections_controls_test.dart` › Appeal this decision opens the appeal composer; the appeal is sent wit | automated |
| Previous | button | `qa.blog.connections.previous` | updates local state | flutter: `blog_connections_controls_test.dart` › connections hub More loads the next page with the server cursor; Previ | automated |
| More | button | `qa.blog.connections.more` | updates local state | flutter: `blog_connections_controls_test.dart` › connections hub More loads the next page with the server cursor; Previ | automated |
| Submit report | button | — | calls POST /v1/blog/reports/{kind}/{contentID} | flutter: `blog_connections_controls_test.dart` › private exchange regression: Report exchange opens the report sheet, s | automated |
| Refresh | button | `qa.blog.exchange.refresh` | refreshes data | flutter: `blog_connections_controls_test.dart` › private exchange Refresh reloads the exchange and shows the new state  | automated |
| This exchange is no longer available. | button | `qa.blog.retry` | refreshes data | flutter: `blog_connections_controls_test.dart` › private exchange An unavailable exchange says so and Try again reloads | automated |
| Accept an exchange | button | `qa.blog.exchange.accept` | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, shows snackbar, updates local state | only checks presence: flutter: `blog_connections_controls_test.dart` › private exchange > Refresh reloads the exchange and shows the new stat | presence-only |
| Decline kindly | button | `qa.blog.exchange.decline` | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; closes screen/sheet, refreshes data, shows snackbar, updates local state | — | **GAP** |
| Add my contribution | button | `qa.blog.exchange.contribute` | may open BlogTextCommandScreen | flutter: `blog_connections_controls_test.dart` › private exchange Add my contribution opens the contribution composer;  | automated |
| my story | field | `qa.blog.exchange.my_story` | opens SelectableText | — | **GAP** |
| partner story | field | `qa.blog.exchange.partner_story` | opens SelectableText | — | **GAP** |
| Shape a date together | button | `qa.blog.exchange.shape_date` | opens showModalBottomSheet, showProposeDatePlanSheet | flutter: `blog_connections_controls_test.dart` › private exchange Shape a date together opens the date plan sheet for t | automated |
| Try First Chapter Studio | button | `qa.blog.exchange.studio` | may open ChapterStudioScreen | flutter: `blog_connections_controls_test.dart` › private exchange Try First Chapter Studio opens the studio for this ma | automated |
| Propose a shared journal page | button | `qa.blog.exchange.journal_page` | may open BlogShareScreen; shows snackbar, updates local state | flutter: `blog_connections_controls_test.dart` › private exchange Propose a shared journal page loads the chapter and o | automated |
| Withdraw exchange | button | `qa.blog.exchange.withdraw` | calls DELETE /v1/blog/responses/{responseID}, POST /v1/blog/responses/{responseID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes da | flutter: `blog_connections_controls_test.dart` › private exchange Withdraw exchange asks first; Cancel keeps it, Withdr | automated |
| Report exchange | button | `qa.blog.exchange.report` | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `blog_connections_controls_test.dart` › private exchange regression: Report exchange opens the report sheet, s | automated |
| Block member | button | `qa.blog.exchange.block` | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `blog_connections_controls_test.dart` › private exchange Block member asks first; Cancel sends nothing, Block  | automated |

#### BlogEditor — `blog.blog_editor`

Route: opened from: blog_screen · Source: `app/lib/features/blog/blog_editor.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| See my level | button | — | may open LevelProgressionScreen | flutter: `blog_editor_controls_test.dart` › writing and saving See my level regression: the shared snack bar opens | automated |
| Saved version · {audience} | sheet | — | presents a bottom sheet | flutter: `blog_editor_controls_test.dart` › saved version Check saved version shows the server copy next to my edi | automated |
| SelectableText input | field | — | opens SelectableText | flutter: `blog_editor_controls_test.dart` › saved version Check saved version shows the server copy next to my edi | automated |
| Keep my edits for the next save | button | `qa.blog.editor.keep_edits` | closes screen/sheet, updates local state | flutter: `blog_editor_controls_test.dart` › saved version Keep my edits closes the sheet and saves my words over t | automated |
| Use saved version | button | `qa.blog.editor.use_saved` | closes screen/sheet, updates local state | flutter: `blog_editor_controls_test.dart` › saved version Use saved version replaces my edits with the server copy<br>flutter: `blog_editor_controls_test.dart` › saved version > Use saved version replaces my edits with the server co | automated |
| Add to private draft | sheet | — | presents a dialog/picker | flutter: `blog_editor_controls_test.dart` › photos Add a photo: describe it, then it is saved with the private dra<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+1 more | automated |
| What is in this photo? | field | `qa.blog.editor.photo_alt` | local/unclassified action — callback: (value) => setDialogState(() => altText = value) | flutter: `blog_editor_controls_test.dart` › photos Add a photo: describe it, then it is saved with the private dra<br>flutter: `blog_editor_controls_test.dart` › photos > Cancel closes the photo description and sends nothing | automated |
| Cancel | button | `qa.blog.editor.photo_cancel` | closes screen/sheet | flutter: `blog_editor_controls_test.dart` › photos Cancel closes the photo description and sends nothing [case:blo<br>flutter: `blog_editor_controls_test.dart` › photos > Cancel closes the photo description and sends nothing | automated |
| Add to private draft | button | `qa.blog.editor.photo_add` | closes screen/sheet, pops a result to caller | — | **GAP** |
| Preview | button | `qa.blog.editor.preview` | updates local state | flutter: `blog_editor_controls_test.dart` › writing and saving Preview shows the chapter as readers will, writes n<br>flutter: `blog_editor_controls_test.dart` › writing and saving > End with an invitation is previewed and saved | automated |
| Check saved version | button | `qa.blog.editor.check_saved` | calls GET /v1/blog/posts/{postID}; opens showModalBottomSheet; closes screen/sheet, shows snackbar, updates local state | flutter: `blog_editor_controls_test.dart` › saved version Check saved version shows the server copy next to my edi<br>flutter: `blog_editor_controls_test.dart` › saved version > Check saved version shows the server copy next to my e<br>+2 more | automated |
| Chapter title | field | `qa.blog.editor.title` | opens TextField | flutter: `blog_editor_controls_test.dart` › writing and saving Save only for me saves the trimmed title and story <br>flutter: `blog_editor_controls_test.dart` › writing and saving > End with an invitation is previewed and saved<br>+6 more | automated |
| End with an invitation (optional) | menu | — | updates local state | flutter: `blog_editor_controls_test.dart` › writing and saving End with an invitation is previewed and saved [case | automated |
| topic | toggle | — | updates local state | flutter: `blog_editor_controls_test.dart` › writing and saving a topic chip files the chapter; tapping it again cl<br>flutter: `blog_editor_controls_test.dart` › writing and saving > a topic chip files the chapter; tapping it again  | automated |
| Remove photo | button | `qa.blog.editor.remove_photo.*` | calls DELETE /v1/blog/posts/{postID}/photos/{photoID}; refreshes data, shows snackbar, updates local state | flutter: `blog_editor_controls_test.dart` › photos Remove photo deletes it from this version of the draft [case:bl<br>flutter: `blog_editor_controls_test.dart` › photos > Remove photo deletes it from this version of the draft | automated |
| Add a photo | button | `qa.blog.editor.add_photo` | calls PUT /v1/blog/posts/{postID}/photos/{photoID}, PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, opens p | flutter: `blog_editor_controls_test.dart` › photos Add a photo: describe it, then it is saved with the private dra<br>flutter: `blog_editor_controls_test.dart` › photos Add a photo is not offered for a published chapter [case:blog.b<br>+2 more | automated |
| audience | toggle | `qa.blog.editor.audience.*` | updates local state | flutter: `blog_editor_controls_test.dart` › writing and saving audience chips change the help, the button and what | automated |
| Allow featuring | toggle | — | updates local state | flutter: `blog_editor_controls_test.dart` › writing and saving Allow featuring is offered for the community only a | automated |
| {audience, select, private{Publish to Only me} friends{Publi | button | — | calls PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackb | flutter: `blog_editor_controls_test.dart` › writing and saving Save only for me saves the trimmed title and story <br>flutter: `blog_editor_controls_test.dart` › writing and saving publishing asks first, publishes, explains XP and c<br>+7 more | automated |
| Save as Only me | button | `qa.blog.editor.save_private` | calls PUT /v1/blog/posts/{postID}; may open LevelProgressionScreen; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackb | flutter: `blog_editor_controls_test.dart` › writing and saving Save as Only me keeps a chosen audience private wit | automated |
| Leave editor (back with unsaved words) | button | — | the leave confirmation is shown from a PopScope handler, not a control callback | flutter: `blog_editor_controls_test.dart` › writing and saving unsaved words ask before leaving; Leave discards, C | automated |
| Formatting toolbar (block menu, italic, underline) | button | — | toolbar buttons are keyed blog.editor.* (not qa.*) inside a toolbar widget | flutter: `blog_editor_controls_test.dart` › the formatting toolbar shapes what the chapter saves [case:blog.blog_e | automated |

#### BlogFollowButton — `blog.blog_follow`

Route: opened from: blog_writers_screen · Source: `app/lib/features/blog/blog_follow.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Following | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | flutter: `blog_follow_writers_controls_test.dart` › follow on a chapter Following stops following and shows the confirmed <br>flutter: `blog_follow_writers_controls_test.dart` › Writers you follow Following in the list unfollows and the writer leav | automated |
| Follow their chapters | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | flutter: `blog_follow_writers_controls_test.dart` › follow on a chapter Follow their chapters follows at once and shows th | automated |
| See my level | sheet | — | presents a bottom sheet | flutter: `blog_screen_controls_test.dart` › feed How rewards work lists rewards and See my level opens the level s | automated |
| See my level | button | `qa.blog.rewards.see_my_level` | may open LevelProgressionScreen; closes screen/sheet | flutter: `blog_screen_controls_test.dart` › feed How rewards work lists rewards and See my level opens the level s | automated |

#### BlogScreen — `blog.blog`

Route: opened from: web_member_workspace · Source: `app/lib/features/blog/blog_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| How rewards work | button | — | may open LevelProgressionScreen; opens showBlogRewardsSheet, showModalBottomSheet; closes screen/sheet | flutter: `blog_screen_controls_test.dart` › feed How rewards work lists rewards and See my level opens the level s | automated |
| Writers you follow | button | — | may open BlogWritersScreen | flutter: `blog_screen_controls_test.dart` › feed Writers you follow opens the list of writers [case:blog.blog.blog<br>flutter: `blog_screen_controls_test.dart` › feed > Writers you follow opens the list of writers | automated |
| Private responses, sharing and notices | button | `qa.blog.connections` | may open BlogConnectionsScreen | — | **GAP** |
| More chapters | gesture | — | refreshes data | flutter: `blog_screen_controls_test.dart` › feed pull to refresh reloads the same feed [case:blog.blog.more_chapte<br>playwright: `blog-editor.spec.js` › story toolbar keeps the cursor in the story<br>+1 more | automated |
| Write a chapter | button | — | may open BlogEditor | flutter: `blog_screen_controls_test.dart` › feed Write a chapter opens an empty editor and back returns [case:blog<br>flutter: `blog_screen_controls_test.dart` › feed > Write a chapter opens an empty editor and back returns<br>+2 more | automated |
| Private responses | button | `qa.blog.private_responses` | may open BlogConnectionsScreen | — | **GAP** |
| Shared links | button | `qa.blog.shared_links` | may open BlogConnectionsScreen | — | **GAP** |
| Review notices | button | `qa.blog.review_notices` | may open BlogConnectionsScreen | — | **GAP** |
| scope | toggle | — | updates local state | flutter: `blog_screen_controls_test.dart` › feed scope chips load each feed and explain it [case:blog.blog.blog_sc<br>flutter: `blog_screen_controls_test.dart` › feed > scope chips load each feed and explain it<br>+2 more | automated |
| isEmpty ?  | toggle | — | updates local state | flutter: `blog_screen_controls_test.dart` › feed topic chips filter the feed and All clears the filter [case:blog. | automated |
| Chapters could not load. | button | `qa.blog.retry` | refreshes data | flutter: `blog_screen_controls_test.dart` › feed a feed that cannot load explains and Try again reloads [case:blog<br>flutter: `blog_screen_controls_test.dart` › feed > a feed that cannot load explains and Try again reloads<br>+1 more | automated |
| Find writers in Top rated | button | — | updates local state | flutter: `blog_screen_controls_test.dart` › feed empty Following points to Top rated, which loads it [case:blog.bl<br>flutter: `blog_screen_controls_test.dart` › feed > empty Following points to Top rated, which loads it | automated |
| Previous page | button | `qa.blog.previous_page` | updates local state | flutter: `blog_screen_controls_test.dart` › feed More chapters loads the next page and Previous page returns [case<br>flutter: `blog_screen_controls_test.dart` › feed > More chapters loads the next page and Previous page returns | automated |
| More chapters | button | `qa.blog.more_chapters` | updates local state | flutter: `blog_screen_controls_test.dart` › feed More chapters loads the next page and Previous page returns [case<br>flutter: `blog_screen_controls_test.dart` › feed > More chapters loads the next page and Previous page returns | automated |
| Read chapter → | button | `qa.blog.post.*` | calls POST /v1/walls/views; may open BlogDetailScreen | flutter: `blog_screen_controls_test.dart` › reading a chapter Read chapter counts one view and opens the chapter [<br>flutter: `blog_screen_controls_test.dart` › reading a chapter > Read chapter counts one view and opens the chapter<br>+1 more | automated |
| Photo unavailable · Retry | button | `qa.blog.photo_retry.*` | refreshes data | flutter: `blog_screen_controls_test.dart` › feed Photo unavailable · Retry loads the photo again [case:blog.blog.b<br>flutter: `blog_screen_controls_test.dart` › feed > Photo unavailable · Retry loads the photo again | automated |
| This chapter is unavailable or its audience has changed. | button | `qa.blog.retry` | refreshes data | flutter: `blog_screen_controls_test.dart` › reading a chapter an unavailable chapter explains and Try again loads <br>flutter: `blog_screen_controls_test.dart` › feed > a feed that cannot load explains and Try again reloads<br>+1 more | automated |
| Respond privately | button | `qa.blog.detail.respond` | may open BlogConnectionsScreen, BlogTextCommandScreen | flutter: `blog_screen_controls_test.dart` › reading a chapter Respond privately sends a response and opens private | automated |
| Create a public preview | button | `qa.blog.detail.public_preview` | may open BlogShareScreen | flutter: `blog_screen_controls_test.dart` › reading a chapter Create a public preview opens sharing with the chapt<br>flutter: `blog_screen_controls_test.dart` › reading a chapter > Create a public preview opens sharing with the cha | automated |
| Edit chapter | button | `qa.blog.detail.edit` | may open BlogEditor | flutter: `blog_screen_controls_test.dart` › reading a chapter Edit chapter opens this chapter in the editor and sa | automated |
| Delete chapter | button | `qa.blog.detail.delete` | calls DELETE /v1/blog/posts/{postID}; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | flutter: `blog_screen_controls_test.dart` › delete, report and block Delete chapter deletes this version and retur<br>flutter: `blog_screen_controls_test.dart` › delete, report and block > Delete asks first; Cancel keeps the chapter | automated |
| Report chapter | button | `qa.blog.detail.report` | calls POST /v1/blog/posts/{postID}/report; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `blog_screen_controls_test.dart` › delete, report and block Report chapter sends the reason and details, <br>flutter: `blog_screen_controls_test.dart` › delete, report and block > Report chapter sends the reason and details | automated |
| Report could not be submitted. | button | `qa.blog.detail.report` | calls POST /v1/blog/posts/{postID}/report; shows snackbar | flutter: `blog_screen_controls_test.dart` › delete, report and block Report chapter sends the reason and details, <br>flutter: `blog_screen_controls_test.dart` › delete, report and block > Report chapter sends the reason and details | automated |
| Block this member | button | `qa.blog.detail.block` | calls POST /v1/safety/block; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar | flutter: `blog_screen_controls_test.dart` › delete, report and block Block this member asks, blocks the writer and<br>flutter: `blog_screen_controls_test.dart` › delete, report and block > a failed block explains and keeps the chapt | automated |
| Cancel | sheet | — | presents a dialog/picker | flutter: `blog_screen_controls_test.dart` › delete, report and block Delete asks first; Cancel keeps the chapter a | automated |
| Cancel | button | `qa.blog.confirm.cancel` | closes screen/sheet, pops a result to caller | flutter: `blog_screen_controls_test.dart` › delete, report and block Delete asks first; Cancel keeps the chapter a<br>flutter: `blog_screen_controls_test.dart` › delete, report and block > Delete asks first; Cancel keeps the chapter<br>+1 more | automated |
| ok | button | `qa.blog.confirm.ok` | closes screen/sheet, pops a result to caller | flutter: `blog_screen_controls_test.dart` › delete, report and block Delete chapter deletes this version and retur<br>flutter: `blog_editor_controls_test.dart` › saved version > Use saved version replaces my edits with the server co<br>+1 more | automated |

#### BlogShareScreen — `blog.blog_sharing`

Route: opened from: blog_connections, blog_screen · Source: `app/lib/features/blog/blog_sharing.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Your public link | sheet | — | presents a dialog/picker | flutter: `blog_sharing_controls_test.dart` › When the clipboard refuses, the link is shown in a "Your public link"  | automated |
| text | field | `qa.blog.public_link.text` | opens SelectableText | flutter: `blog_sharing_controls_test.dart` › The link in the dialog can be selected and copied by hand [case:blog.b | automated |
| preview | field | `qa.blog.share.preview` | opens SelectableText | flutter: `blog_sharing_controls_test.dart` › shared journal page (joint) Both contributions show read-only, author  | automated |
| Exact excerpt from your chapter | field | `qa.blog.share.excerpt` | updates local state | flutter: `blog_sharing_controls_test.dart` › Editing the excerpt withdraws consent; the edited words are what goes  | automated |
| Include: {description} | toggle | `qa.blog.share.photo.*` | updates local state | flutter: `blog_sharing_controls_test.dart` › Ticking a photo withdraws consent and adds exactly that photo; unticki | automated |
| I approve this exact public copy | toggle | `qa.blog.share.approve` | updates local state | flutter: `blog_sharing_controls_test.dart` › Consent starts unchecked; ticking it enables Create, unticking disable | automated |
| Create public link | button | `qa.blog.share.create` | calls POST /v1/blog/publications; opens share sheet, refreshes data, shows snackbar, updates local state | flutter: `blog_sharing_controls_test.dart` › Create public link sends exactly the approved copy once, then shows it | automated |
| Copy public link | button | `qa.blog.share.copy_link` | opens showDialog; copies to clipboard, shows snackbar | flutter: `blog_sharing_controls_test.dart` › Copy public link copies the link of exactly the publication just creat | automated |
| Manage shared links | button | `qa.blog.share.manage_links` | may open BlogConnectionsScreen | flutter: `blog_sharing_controls_test.dart` › Manage shared links opens Shared links with the new copy listed [case: | automated |

#### SocialLikeButton — `blog.blog_social`

Route: opened from: photo_theme_widgets · Source: `app/lib/features/blog/blog_social.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| {noun, select, photo{You can’t react to your own photo} othe | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | flutter: `blog_social_controls_test.dart` › likes and reactions React opens the picker; a choice is sent and shown<br>flutter: `blog_social_controls_test.dart` › likes and reactions Authors cannot react to their own chapter: both co | automated |
| Love (icon favorite_rounded) | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | flutter: `blog_social_controls_test.dart` › likes and reactions Heart likes then unlikes: PUT then DELETE, the cou | automated |
| Comments | button | — | calls POST /v1/walls/views; may open BlogDetailScreen | flutter: `blog_social_controls_test.dart` › Featured Stories card Tapping a featured chapter counts one wall view  | automated |
| Report could not be submitted. | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; shows snackbar | flutter: `blog_social_controls_test.dart` › comment options regression: Report comment sends the reason and detail | automated |
| Leave a comment | field | — | updates local state | flutter: `blog_social_controls_test.dart` › comment composer Typing fills the composer, shows the count and enable | automated |
| Send to the author | button | — | shows snackbar, updates local state | flutter: `blog_social_controls_test.dart` › comment composer Send puts the trimmed comment under a fresh id, clear | automated |
| Comments could not load. | button | `qa.blog.retry` | refreshes data | flutter: `blog_social_controls_test.dart` › comment composer Comments that fail to load offer Try again, which loa<br>flutter: `blog_screen_controls_test.dart` › feed > a feed that cannot load explains and Try again reloads<br>+1 more | automated |
| Decline | button | — | shows snackbar, updates local state | flutter: `blog_social_controls_test.dart` › author decisions Decline keeps the comment off the chapter with a conf | automated |
| Comment options | menu | `qa.*.comment.options.*` | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `blog_social_controls_test.dart` › comment options regression: Report comment sends the reason and detail | automated |
| SelectableText input | field | — | opens SelectableText | flutter: `blog_social_controls_test.dart` › comment text A comment is selectable: select all and copy puts its exa | automated |
| Approve | button | — | local/unclassified action — callback: busy ? null : onApprove ⚠  | flutter: `blog_social_controls_test.dart` › author decisions Approve shares the comment: one decision request, a c | automated |
| Delete comment (comment options) | menu | `qa.*.comment.options.*` | the comment options menu's onDelete branch; only onReport is extracted | flutter: `blog_social_controls_test.dart` › comment options Delete comment asks first; Cancel keeps it, Delete rem | automated |

#### BlogWritersScreen — `blog.blog_writers`

Route: embedded / not directly routed · Source: `app/lib/features/blog/blog_writers_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Writers you follow could not load. | button | `qa.blog.retry` | refreshes data | flutter: `blog_follow_writers_controls_test.dart` › Writers you follow a list that cannot load explains and Try again relo | automated |
| An untitled chapter | gesture | — | refreshes data | flutter: `blog_follow_writers_controls_test.dart` › Writers you follow pull to refresh reloads the writers [case:blog.blog<br>flutter: `blog_follow_writers_controls_test.dart` › Writers you follow an empty list explains how to follow writers [case: | automated |
| An untitled chapter | button | `qa.blog.writer.latest.` | calls POST /v1/walls/views; may open BlogDetailScreen | flutter: `blog_follow_writers_controls_test.dart` › Writers you follow Latest: An untitled chapter counts a view and opens | automated |

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
| Love (icon favorite_rounded) | button | — | calls PUT /v1/blog/posts/{postID}/like, DELETE /v1/blog/posts/{postID}/like, PUT /v1/blog/authors/{authorID}/subscription, DELETE /v1/blog/authors/{authorID}/su | — | **GAP** |
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
| Club options | menu | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showClubMembersSheet, showClubSheet, showModalBottomSheet; shows snackbar | flutter: `club_detail_controls_test.dart` › club options Club options → Members opens the member list; Report club | automated |
| This club could not load | button | — | refreshes data | flutter: `club_detail_controls_test.dart` › Club could not load shows why; Try again reloads it [case:clubs.club_d | automated |
| Members talk about each pick together. Join the club to read | gesture | — | local/unclassified action — callback: () async { invalidateClub(ref, club.id); await ref.read(clubDetailProvider(club.id).future ⚠  | flutter: `club_detail_controls_test.dart` › Pull to refresh reloads the club for a visitor [case:clubs.club_detail | automated |
| Members | button | — | opens showClubMembersSheet, showClubSheet, showModalBottomSheet | flutter: `club_detail_controls_test.dart` › Members opens the member list (no actions for a member) [case:clubs.cl | automated |
| Discuss this pick | button | — | updates local state | flutter: `club_detail_controls_test.dart` › Open the discussion on an earlier pick, then Discuss this pick back [c | automated |
| Set this week’s pick | button | — | opens showClubSheet, showModalBottomSheet, showSetPickSheet; updates local state | flutter: `club_detail_controls_test.dart` › weekly pick Set this week’s pick: search, choose, add a note, save [ca | automated |
| {week} · {count, plural, =1{1 post} other{{count} posts}} | button | — | may open TitleDetailScreen | flutter: `club_detail_controls_test.dart` › An earlier pick row opens that title [case:clubs.club_detail.week_coun | automated |
| Open the discussion | button | — | updates local state | flutter: `club_detail_controls_test.dart` › Open the discussion on an earlier pick, then Discuss this pick back [c | automated |
| Join club | button | — | local/unclassified action — callback: busy ? null : onJoin ⚠  | flutter: `club_detail_controls_test.dart` › membership Join club joins, welcomes and opens the discussion [case:cl | automated |
| Leave club | button | — | local/unclassified action — callback: busy ? null : onLeave ⚠  | flutter: `club_detail_controls_test.dart` › membership Leave club asks first; Cancel keeps me in, Leave leaves [ca | automated |
| chevron right (icon chevron_right) | button | — | may open TitleDetailScreen | flutter: `club_detail_controls_test.dart` › The pick title (with chevron) opens the title page [case:clubs.club_de | automated |

#### ClubDiscussion — `clubs.club_discussion`

Route: opened from: club_detail_screen · Source: `app/lib/features/clubs/club_discussion.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| The discussion could not load | button | — | updates local state | flutter: `club_discussion_controls_test.dart` › The discussion could not load: Try again reloads it [case:clubs.club_d | automated |
| Load more posts | button | — | updates local state | flutter: `club_discussion_controls_test.dart` › Load more posts fetches the older page and shows it first [case:clubs. | automated |
| Post | button | — | calls PUT /v1/clubs/{clubID}/posts/{postID}; shows snackbar, updates local state | flutter: `club_discussion_controls_test.dart` › composer Post sends the trimmed text to this pick, shows it and clears | automated |
| Contains spoilers | toggle | — | updates local state | flutter: `club_discussion_controls_test.dart` › composer Contains spoilers marks the post and resets after sending [ca | automated |
| Add to the discussion | field | — | opens TextField | flutter: `club_discussion_controls_test.dart` › composer Post sends the trimmed text to this pick, shows it and clears | automated |
| Post actions | menu | — | calls DELETE /v1/clubs/{clubID}/posts/{postID}, POST /v1/clubs/{clubID}/posts/{postID}/visibility, POST /v1/blog/reports/{kind}/{contentID}; opens showDialog, s | flutter: `club_discussion_controls_test.dart` › post actions Delete (my post, after confirming), Hide/Show (moderator) | automated |

#### ClubMembersSheet — `clubs.club_members_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/club_members_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Actions for {name} | menu | — | calls POST /v1/clubs/{clubID}/members/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `club_detail_controls_test.dart` › members sheet Owner promotes, demotes and (after confirming) removes m | automated |

#### ClubPickSheet — `clubs.club_pick_sheet`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/club_pick_sheet.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Next week | toggle | — | updates local state | flutter: `club_detail_controls_test.dart` › weekly pick Next week saves the pick for next Monday [case:clubs.club_ | automated |
| Search (icon search) | button | — | opens showClubSheet, showModalBottomSheet; updates local state | flutter: `club_detail_controls_test.dart` › weekly pick Set this week’s pick: search, choose, add a note, save [ca | automated |
| Change | button | — | opens showClubSheet, showModalBottomSheet; updates local state | flutter: `club_detail_controls_test.dart` › weekly pick Change swaps the chosen title before saving [case:clubs.cl | automated |
| A note for the club (optional) | field | — | opens TextField | flutter: `club_detail_controls_test.dart` › weekly pick Set this week’s pick: search, choose, add a note, save [ca | automated |
| Save pick | button | — | calls PUT /v1/clubs/{clubID}/selections/{weekStart}; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `club_detail_controls_test.dart` › weekly pick Set this week’s pick: search, choose, add a note, save [ca | automated |

#### KindBadge — `clubs.club_widgets`

Route: opened from: club_detail_screen, clubs_screen, my_lists_screen, title_detail_screen · Source: `app/lib/features/clubs/club_widgets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showModalBottomSheet open | sheet | — | presents a bottom sheet | flutter: `clubs_screen_controls_test.dart` › showClubSheet opens with a drag handle and a Close button that dismiss | automated |

#### ClubsScreen — `clubs.clubs`

Route: opened from: today_activities · Source: `app/lib/features/clubs/clubs_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| My lists | button | — | may open MyListsScreen | flutter: `clubs_screen_controls_test.dart` › My lists opens the member\'s shelf with their lists [case:clubs.clubs. | automated |
| Start a book or film club | button | — | may open ClubDetailScreen; opens showClubSheet, showModalBottomSheet; refreshes data | flutter: `clubs_screen_controls_test.dart` › Start a club: name, about and Books create the club and open it [case: | automated |
| Try again | gesture | — | refreshes data | flutter: `clubs_screen_controls_test.dart` › Pull to refresh reloads the clubs [case:clubs.clubs.try_again_onrefres | automated |
| My clubs | toggle | — | updates local state | flutter: `clubs_screen_controls_test.dart` › My clubs / Discover switches the list [case:clubs.clubs.my_clubs_onsel | automated |
| ChoiceChip onSelected | toggle | — | updates local state | flutter: `clubs_screen_controls_test.dart` › Kind chips filter the clubs by Books / Films / All [case:clubs.clubs.c | automated |
| Clubs could not load | button | — | refreshes data | flutter: `clubs_screen_controls_test.dart` › Clubs could not load shows the reason; Try again reloads [case:clubs.c | automated |
| No clubs here yet | button | — | updates local state | flutter: `clubs_screen_controls_test.dart` › No clubs of my own: Discover clubs switches to Discover [case:clubs.cl | automated |
| No pick yet this week | button | — | may open ClubDetailScreen | flutter: `clubs_screen_controls_test.dart` › Tapping a club card opens that club [case:clubs.clubs.no_pick_yet_this | automated |
| SegmentedButton onSelectionChanged | toggle | — | updates local state | flutter: `clubs_screen_controls_test.dart` › Start a club: the Films segment makes a film club [case:clubs.clubs.se | automated |
| Club name | field | — | opens TextField | flutter: `clubs_screen_controls_test.dart` › Start a club: name, about and Books create the club and open it [case: | automated |
| What is your club about? (optional) | field | — | opens TextField | flutter: `clubs_screen_controls_test.dart` › Start a club: name, about and Books create the club and open it [case: | automated |
| Create club | button | — | calls PUT /v1/clubs/{clubID}; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `clubs_screen_controls_test.dart` › Start a club: name, about and Books create the club and open it [case: | automated |

#### ListSheets — `clubs.list_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/list_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| List name | field | — | opens TextField | flutter: `club_lists_reviews_controls_test.dart` › my lists New list: name, Films, Friends → Create list adds it to the s | automated |
| SegmentedButton onSelectionChanged | toggle | — | updates local state | flutter: `club_lists_reviews_controls_test.dart` › my lists New list: name, Films, Friends → Create list adds it to the s | automated |
| ChoiceChip onSelected | toggle | — | updates local state | flutter: `club_lists_reviews_controls_test.dart` › my lists New list: name, Films, Friends → Create list adds it to the s | automated |
| Create list | button | — | calls PUT /v1/clubs/lists/{listID}; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state ⚠ pops a result to its opener — verify every opener handles it | flutter: `club_lists_reviews_controls_test.dart` › my lists New list: name, Films, Friends → Create list adds it to the s<br>appium: `test_01_signup_credentials_profile_setup.py` › test_username_signup_reaches_profile_setup | automated |
| showDialog open | sheet | — | presents a dialog/picker | flutter: `club_lists_reviews_controls_test.dart` › my lists Item options: Edit note (Cancel keeps it, Save note saves it) | automated |
| Why it is on this list | field | — | opens TextField | flutter: `club_lists_reviews_controls_test.dart` › my lists Item options: Edit note (Cancel keeps it, Save note saves it) | automated |
| Cancel | button | — | closes screen/sheet | flutter: `club_lists_reviews_controls_test.dart` › my lists Item options: Edit note (Cancel keeps it, Save note saves it) | automated |
| Save note | button | — | closes screen/sheet, pops a result to caller | flutter: `club_lists_reviews_controls_test.dart` › my lists Item options: Edit note (Cancel keeps it, Save note saves it) | automated |

#### MyListsScreen — `clubs.my_lists`

Route: opened from: clubs_screen · Source: `app/lib/features/clubs/my_lists_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create a new list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | flutter: `club_lists_reviews_controls_test.dart` › my lists New list: name, Films, Friends → Create list adds it to the s | automated |
| New list | gesture | — | refreshes data | flutter: `club_lists_reviews_controls_test.dart` › my lists Pull to refresh reloads the lists [case:clubs.my_lists.new_li | automated |
| Your lists could not load | button | — | refreshes data | flutter: `club_lists_reviews_controls_test.dart` › my lists Your lists could not load: Try again reloads them [case:clubs | automated |
| Start your first list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | flutter: `club_lists_reviews_controls_test.dart` › my lists No lists yet: the notice\'s New list opens the editor [case:c | automated |
| List options | menu | — | calls PUT /v1/clubs/lists/{listID}/items/{titleID}, DELETE /v1/clubs/lists/{listID}; opens showClubSheet, showDialog, showListEditorSheet; closes screen/sheet,  | flutter: `club_lists_reviews_controls_test.dart` › my lists List options: Add a title, Edit list and (after confirming) D | automated |
| “{note}” | button | — | may open TitleDetailScreen | flutter: `club_lists_reviews_controls_test.dart` › my lists Tapping a listed title opens its page [case:clubs.my_lists.no | automated |
| Options for {title} | menu | — | calls PUT /v1/clubs/lists/{listID}/items/{titleID}, DELETE /v1/clubs/lists/{listID}/items/{titleID}; opens showDialog; refreshes data, shows snackbar, updates l | flutter: `club_lists_reviews_controls_test.dart` › my lists Item options: Edit note (Cancel keeps it, Save note saves it) | automated |

#### ReviewSheets — `clubs.review_sheets`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/review_sheets.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| {count, plural, =1{1 star} other{{count} stars}} | button | — | updates local state | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| What did you think? (optional) | field | — | opens TextField | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| Contains spoilers | toggle | — | updates local state | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| ChoiceChip onSelected | toggle | — | updates local state | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| Save review | button | — | calls PUT /v1/clubs/titles/{titleID}/reviews/{reviewID}; closes screen/sheet, pops a result to caller, shows snackbar, updates local state | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| {count, plural, =1{1 title} other{{count} titles}} | button | — | local/unclassified action — callback: () => add(list) ⚠  | flutter: `club_lists_reviews_controls_test.dart` › add to a list sheet Add to a list shows my lists of this kind; tapping | automated |
| New list | button | — | opens showClubSheet, showListEditorSheet, showModalBottomSheet | flutter: `club_lists_reviews_controls_test.dart` › add to a list sheet New list from Add to a list creates a list of this | automated |

#### TitleDetailScreen — `clubs.title_detail`

Route: opened from: club_detail_screen, my_lists_screen · Source: `app/lib/features/clubs/title_detail_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| This title could not load | button | — | refreshes data | flutter: `title_controls_test.dart` › title page This title could not load: Try again reloads it [case:clubs | automated |
| When members you can see share a review, it shows up here. | gesture | — | refreshes data | flutter: `title_controls_test.dart` › title page Pull to refresh brings in new reviews [case:clubs.title_det | automated |
| Add to a list | button | — | opens showAddToListSheet, showClubSheet, showModalBottomSheet | flutter: `club_lists_reviews_controls_test.dart` › add to a list sheet Add to a list shows my lists of this kind; tapping | automated |
| Write a review | button | — | opens showClubSheet, showModalBottomSheet, showReviewSheet | flutter: `club_lists_reviews_controls_test.dart` › review sheet Write a review: stars, words, spoilers and audience are s | automated |
| Edit | button | — | opens showClubSheet, showModalBottomSheet, showReviewSheet | flutter: `club_lists_reviews_controls_test.dart` › review sheet Edit opens my review prefilled and saves the new version  | automated |
| Delete | button | — | calls DELETE /v1/clubs/reviews/{reviewID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `title_controls_test.dart` › title page Delete my review asks first, then removes it [case:clubs.ti | automated |
| Report this review | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; opens showModalBottomSheet, showReportUserSheet; shows snackbar | flutter: `title_controls_test.dart` › title page Report this review files a review report [case:clubs.title_ | automated |

#### TitlePicker — `clubs.title_picker`

Route: embedded / not directly routed · Source: `app/lib/features/clubs/title_picker.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Type at least 2 letters | field | — | updates local state | flutter: `title_controls_test.dart` › title picker Search waits for typing to pause, then lists matches [cas | automated |
| ListTile onTap | button | — | closes screen/sheet, pops a result to caller | flutter: `title_controls_test.dart` › title picker Tapping a result closes the picker and hands the title ba | automated |
| Add (icon add) | button | — | updates local state | flutter: `title_controls_test.dart` › title picker Add a new book opens the form, prefilled from the search  | automated |
| Title | field | — | opens TextField | flutter: `title_controls_test.dart` › title picker Add and choose saves the new title and hands it back; an  | automated |
| Author | field | — | opens TextField | flutter: `title_controls_test.dart` › title picker Add and choose saves the new title and hands it back; an  | automated |
| Year (optional) | field | — | opens TextField | flutter: `title_controls_test.dart` › title picker Add and choose saves the new title and hands it back; an  | automated |
| Add and choose | button | — | local/unclassified action — callback: busy ? null : add ⚠  | flutter: `title_controls_test.dart` › title picker Add and choose saves the new title and hands it back; an  | automated |

### City Pilot

#### CityPilotScreen — `city_pilot.city_pilot`

Route: opened from: engagement_hub_screen · Source: `app/lib/features/city_pilot/city_pilot_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Leave the city pilot? | sheet | — | presents a dialog/picker | flutter: `city_pilot_controls_test.dart` › leaving Leave pilot asks first and spells out what leaving does [case: | automated |
| Stay in pilot | button | `qa.city_pilot.leave_stay` | closes screen/sheet, pops a result to caller | flutter: `city_pilot_controls_test.dart` › leaving Stay in pilot closes the question and keeps me in [case:city_p | automated |
| Leave pilot | button | `qa.city_pilot.leave_confirm` | closes screen/sheet, pops a result to caller | flutter: `city_pilot_controls_test.dart` › leaving confirming Leave pilot withdraws me on the server and says so  | automated |
| Join {title}? | sheet | — | presents a dialog/picker | flutter: `city_pilot_controls_test.dart` › booking an experience Reserve a free place shows the event’s safety te | automated |
| Not now | button | `qa.city_pilot.booking_not_now` | closes screen/sheet, pops a result to caller | flutter: `city_pilot_controls_test.dart` › booking an experience Not now closes the terms without booking [case:c | automated |
| Accept & reserve a place | button | `qa.city_pilot.booking_accept` | closes screen/sheet, pops a result to caller | flutter: `city_pilot_controls_test.dart` › booking an experience Accept & reserve books my place and offers Cance | automated |
| I couldn’t make it | toggle | `qa.city_pilot.attended.*` | local/unclassified action — callback: (_) => update(() { attended = value; worthwhile = null; }) | flutter: `city_pilot_controls_test.dart` › feedback I couldn’t make it hides the worth-it question and clears its | automated |
| Not this time | toggle | `qa.city_pilot.worthwhile.*` | local/unclassified action — callback: (selected) => update( () => worthwhile = selected ? value : null, ) | flutter: `city_pilot_controls_test.dart` › feedback Not this time answers no, and tapping it again takes the answ | automated |
| Skip | button | `qa.city_pilot.feedback_skip` | closes screen/sheet | flutter: `city_pilot_controls_test.dart` › feedback Skip closes the questions and sends nothing [case:city_pilot. | automated |
| Share feedback | button | `qa.city_pilot.feedback_share` | closes screen/sheet, pops a result to caller | flutter: `city_pilot_controls_test.dart` › feedback Share optional feedback asks whether I went; Share feedback s | automated |
| Refresh pilot | button | `qa.city_pilot.refresh` | refreshes data | flutter: `city_pilot_controls_test.dart` › loading Refresh pilot reloads and shows what changed [case:city_pilot. | automated |
| Try again | button | `qa.city_pilot.retry` | refreshes data | flutter: `city_pilot_controls_test.dart` › loading an unreachable pilot says so; Try again reloads it (and a seco | automated |
| I agree to take part in this pilot and its outcome measureme | toggle | `qa.city_pilot.consent` | updates local state | flutter: `city_pilot_controls_test.dart` › joining the consent box arms Join; Join sends the pilot and consent ve | automated |
| Join the city pilot | button | `qa.city_pilot.join` | calls POST /v1/city-pilot/membership; refreshes data, shows snackbar, updates local state | flutter: `city_pilot_controls_test.dart` › joining the consent box arms Join; Join sends the pilot and consent ve | automated |
| Leave pilot | button | `qa.city_pilot.leave` | calls DELETE /v1/city-pilot/membership; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `city_pilot_controls_test.dart` › leaving confirming Leave pilot withdraws me on the server and says so  | automated |
| Cancel my place | button | `qa.city_pilot.cancel.${event[` | calls DELETE /v1/city-pilot/events/${event[; refreshes data, shows snackbar, updates local state | flutter: `city_pilot_controls_test.dart` › booking an experience Cancel my place cancels the booking and offers R | automated |
| Reserve a free place | button | `qa.city_pilot.reserve.${event[` | calls POST /v1/city-pilot/events/${event[; opens showDialog; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `city_pilot_controls_test.dart` › booking an experience Accept & reserve books my place and offers Cance | automated |
| Share optional feedback | button | `qa.city_pilot.feedback.${event[` | calls POST /v1/city-pilot/events/${event[; closes screen/sheet, pops a result to caller, refreshes data, shows snackbar, updates local state | flutter: `city_pilot_controls_test.dart` › feedback Share optional feedback asks whether I went; Share feedback s | automated |

### Notifications

#### NotificationInboxScreen — `notifications.notification_inbox`

Route: opened from: main_navigation_screen, notification_settings_screen, settings_screen, web_member_workspace · Source: `app/lib/features/notifications/screens/notification_inbox_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Read all | button | `qa.notifications.read_all` | calls POST /v1/notifications/{userID}/read-all; shows snackbar | flutter: `notification_inbox_controls_test.dart` › Read all marks every notification read on the server and in the list [<br>flutter: `notification_inbox_controls_test.dart` › Read all > marks every notification read on the server and in the list | automated |
| Couldn't remove that notification. Try again. | gesture | `qa.notifications.refresh` | calls POST /v1/notifications/{userID}/devices, GET /v1/notifications/{userID}, GET /v1/notifications/{userID}/unread-count, GET /v1/notifications/{userID}/prefe | flutter: `notification_inbox_controls_test.dart` › Pull to refresh reloads the inbox, the unread count and preferences an | automated |
| Retry | button | `qa.notifications.retry` | calls POST /v1/notifications/{userID}/devices, GET /v1/notifications/{userID}, GET /v1/notifications/{userID}/unread-count, GET /v1/notifications/{userID}/prefe | — | **GAP** |
| Someone liked you | swipe | `qa.notifications.item.*` | calls DELETE /v1/notifications/{userID}/{notificationID}; shows snackbar | flutter: `notification_inbox_controls_test.dart` › Swipe to dismiss deletes the notification on the server and removes th<br>flutter: `notification_inbox_controls_test.dart` › Open a notification > a like marks it read and opens who liked me | automated |
| InkWell onTap | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open FriendsScreen, HelpSupportScreen, LikedMeScreen | flutter: `notification_inbox_controls_test.dart` › Open a notification a like marks it read and opens who liked me [case: | automated |

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
| Resolution: {note} | gesture | — | calls GET /v1/safety/sos/{userID}; shows snackbar | flutter: `sos_controls_test.dart` › pull to refresh reloads the history with the safety team\'s resolution | automated |
| Urgent | toggle | `qa.safety.sos_level` | updates local state | flutter: `sos_controls_test.dart` › Critical level is what the alert is sent with [case:safety.sos.safety_ | automated |
| Message for the safety team | field | `qa.safety.sos_message` | opens TextField | flutter: `sos_controls_test.dart` › the message is prefilled, editable and sent as typed (trimmed) [case:s<br>flutter: `sos_controls_test.dart` › the message is prefilled, editable and sent as typed (trimmed) | automated |
| Activate SOS | button | `qa.safety.activate_sos` | calls POST /v1/safety/sos; opens showDialog; closes screen/sheet, pops a result to caller | flutter: `sos_controls_test.dart` › Activate SOS → confirm → alert sent with level, message and location →<br>flutter: `sos_controls_test.dart` › Critical level is what the alert is sent with<br>+2 more | automated |
| Activate SOS now? | sheet | — | presents a dialog/picker | flutter: `sos_controls_test.dart` › Activate SOS → confirm → alert sent with level, message and location →<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+1 more | automated |
| Cancel | button | `qa.safety.sos_confirm.cancel` | closes screen/sheet, pops a result to caller | flutter: `sos_controls_test.dart` › Cancel in the confirmation sends nothing [case:safety.sos.safety_sos_c | automated |
| Activate | button | `qa.safety.sos_confirm.activate` | closes screen/sheet, pops a result to caller | flutter: `sos_controls_test.dart` › Activate SOS → confirm → alert sent with level, message and location →<br>flutter: `sos_controls_test.dart` › Critical level is what the alert is sent with<br>+2 more | automated |
| Done | sheet | — | presents a dialog/picker | flutter: `sos_controls_test.dart` › Activate SOS → confirm → alert sent with level, message and location → | automated |
| Done | button | `qa.safety.sos_done` | closes screen/sheet | flutter: `sos_controls_test.dart` › Activate SOS → confirm → alert sent with level, message and location →<br>flutter: `sos_controls_test.dart` › Critical level is what the alert is sent with<br>+1 more | automated |

### Help & Support

#### SupportContactFormScreen — `support.support_contact_form`

Route: opened from: account_recovery_screen · Source: `app/lib/features/support/screens/support_contact_form_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to sign in | button | — | closes screen/sheet | — | **GAP** |
| Your email | field | — | opens TextField | — | **GAP** |
| Your name (optional) | field | — | opens TextField | — | **GAP** |
| support guest category * | toggle | — | updates local state | — | **GAP** |
| Subject | field | — | opens TextField | playwright: `contact.spec.js` › client validation lists errors, focuses the summary and sends nothing  | automated |
| What happened? | field | — | opens TextField | — | **GAP** |
| Send request | button | — | calls POST /v1/support/contact; updates local state | flutter: `support_resilience_test.dart` › signed-out contact form [case:support.support_contact_form.support_gue | automated |

#### SupportTicketFormScreen — `support.support_ticket_form`

Route: opened from: help_support_screen, support_entry_points, support_tickets_screen · Source: `app/lib/features/support/screens/support_ticket_form_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Back to Help & Support | button | — | closes screen/sheet | — | **GAP** |
| Discard draft | button | — | updates local state | flutter: `support_resilience_test.dart` › new request draft [case:support.support_ticket_form.support_draft_disc | automated |
| support category * | toggle | — | updates local state | flutter: `support_resilience_test.dart` › [case:support.support_ticket_form.support_category_x.action] offers th<br>flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>+6 more | automated |
| Open SOS | button | — | may open SosScreen | only checks presence: flutter: `support_ticket_form_test.dart` › safety topic points to SOS and emergency services | presence-only |
| Subject | field | — | opens TextField | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+5 more | automated |
| What happened? | field | — | opens TextField | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+3 more | automated |
| Add screenshot | button | — | calls POST /v1/support/attachments; opens photo/file picker | flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids | automated |
| Send request | button | — | calls POST /v1/support/tickets; may open SupportTicketThreadScreen; refreshes data, shows snackbar, updates local state | flutter: `support_ticket_form_test.dart` › creates a ticket with the contract payload and opens it<br>flutter: `support_ticket_form_test.dart` › uploads screenshots first and sends their ids<br>+4 more | automated |

#### SupportTicketThreadScreen — `support.support_ticket_thread`

Route: opened from: support_routes, support_ticket_form_screen, support_tickets_screen · Source: `app/lib/features/support/screens/support_ticket_thread_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | — | calls POST /v1/support/tickets/{ticketID}/messages; refreshes data, shows snackbar, updates local state | flutter: `support_resilience_test.dart` › thread [case:support.support_ticket_thread.retry.action] [case:support | automated |
| Close this request? | sheet | — | presents a dialog/picker | playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>playwright: `console-layout.spec.js` › destructive actions confirm in the Bootstrap dialog, not window.confir | automated |
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

#### SupportEntryTile — `support.support_entry_points`

Route: opened from: settings_screen · Source: `app/lib/features/support/widgets/support_entry_points.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Help & Support | button | — | may open HelpSupportScreen; refreshes data | flutter: `support_entry_points_test.dart` › Settings: Help & Support tile [case:support.support_entry_points.help_<br>flutter: `support_entry_points_test.dart` › Settings: Help & Support tile [case:support.support_entry_points.help_<br>+1 more | automated |
| support agent rounded (icon support_agent_rounded) | button | — | may open SupportTicketFormScreen; closes screen/sheet | flutter: `support_entry_points_test.dart` › Contact support links [case:support.support_entry_points.support_agent<br>flutter: `support_entry_points_test.dart` › Contact support links [case:support.support_entry_points.support_agent<br>+4 more | automated |
| Help & Support | button | — | may open HelpSupportScreen | flutter: `support_entry_points_test.dart` › [case:support.support_entry_points.support_centre_button.action] the s | automated |

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
| Retry | button | `qa.account.retry` | calls GET /v1/account/{userID}/lifecycle; refreshes data | flutter: `account_data_controls_test.dart` › load Retry reloads the account after a failed load [case:common.accoun<br>flutter: `account_data_controls_test.dart` › load > Retry reloads the account after a failed load | automated |
| Keep my account | button | `qa.account.cancel_deletion_button` | calls DELETE /v1/account/{userID}/deletion, GET /v1/account/{userID}/lifecycle; shows snackbar | flutter: `account_data_controls_test.dart` › delete Keep my account on the countdown cancels the deletion [case:com<br>flutter: `account_data_controls_test.dart` › delete > Keep my account on the countdown cancels the deletion<br>+2 more | automated |
| Hide my profile | button | `qa.account.pause_toggle_button` | calls POST /v1/account/{userID}/reactivate, GET /v1/account/{userID}/lifecycle, POST /v1/account/{userID}/deactivate; shows snackbar | flutter: `account_data_controls_test.dart` › take a break Hide my profile hides it; Unhide brings it back [case:com<br>flutter: `account_data_controls_test.dart` › take a break > Hide my profile hides it; Unhide brings it back<br>+2 more | automated |
| Prepare my data | button | `qa.account.export_button` | calls POST /v1/account/{userID}/export, GET /v1/account/{userID}/lifecycle; opens showDialog; shows snackbar, updates local state | flutter: `account_data_controls_test.dart` › export Prepare my data shows the export in a dialog [case:common.accou<br>flutter: `account_data_controls_test.dart` › export while preparing, the button is busy and a second tap sends noth<br>+5 more | automated |
| showDialog open | sheet | — | presents a dialog/picker | flutter: `account_data_controls_test.dart` › export Prepare my data shows the export in a dialog [case:common.accou | automated |
| export text | field | `qa.account.export_text` | opens SelectableText | flutter: `account_data_controls_test.dart` › export Prepare my data shows the export in a dialog [case:common.accou | automated |
| Copy | button | `qa.account.export_copy` | closes screen/sheet, copies to clipboard | flutter: `account_data_controls_test.dart` › export Copy puts the whole export on the clipboard, unicode intact, an | automated |
| Close | button | `qa.account.export_close` | closes screen/sheet | flutter: `account_data_controls_test.dart` › export Close dismisses the export without copying [case:common.account<br>flutter: `account_data_controls_test.dart` › export > Close dismisses the export without copying<br>+1 more | automated |
| Delete my account | button | `qa.account.delete_button` | calls POST /v1/account/{userID}/deletion, GET /v1/account/{userID}/lifecycle, POST /v1/account/{userID}/deactivate; opens showDialog; closes screen/sheet, pops  | flutter: `account_data_controls_test.dart` › delete confirming Delete schedules the deletion and shows the countdow<br>flutter: `account_data_controls_test.dart` › delete > Delete my account asks first and offers hiding instead<br>+7 more | automated |
| Delete your account? | sheet | — | presents a dialog/picker | flutter: `account_data_controls_test.dart` › delete Delete my account asks first and offers hiding instead [case:co<br>flutter: `account_data_screen_test.dart` › AccountDataScreen delete asks for confirmation and offers hiding inste<br>+1 more | automated |
| Keep my account | button | `qa.account.delete_keep` | closes screen/sheet, pops a result to caller | flutter: `account_data_controls_test.dart` › delete Keep my account closes the question and changes nothing [case:c<br>flutter: `account_data_controls_test.dart` › delete > Keep my account closes the question and changes nothing<br>+1 more | automated |
| Hide instead | button | `qa.account.delete_hide_instead` | closes screen/sheet, pops a result to caller | flutter: `account_data_controls_test.dart` › delete Hide instead hides the profile and deletes nothing [case:common<br>flutter: `account_data_controls_test.dart` › delete > Hide instead hides the profile and deletes nothing | automated |
| Delete | button | `qa.account.delete_confirm_button` | closes screen/sheet, pops a result to caller | flutter: `account_data_controls_test.dart` › delete confirming Delete schedules the deletion and shows the countdow<br>flutter: `account_data_controls_test.dart` › delete > a refused deletion explains and leaves the account untouched<br>+1 more | automated |

#### BlockedUsersScreen — `common.blocked_users`

Route: opened from: privacy_safety_screen, web_member_workspace · Source: `app/lib/features/common/screens/blocked_users_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | `qa.blocked.retry` | refreshes data | flutter: `blocked_users_controls_test.dart` › a failed load is not shown as "no blocked users"; Retry reloads (regre<br>flutter: `blocked_users_controls_test.dart` › a failed load is not shown as "no blocked users"; Retry reloads | automated |
| Unblock | button | `qa.blocked.unblock.*` | calls POST /v1/safety/unblock, GET /v1/blocked-users/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `blocked_users_controls_test.dart` › Unblock → confirm unblocks on the server, re-reads the list and confir<br>flutter: `blocked_users_controls_test.dart` › Cancel keeps the member blocked and sends nothing<br>+1 more | automated |
| Unblock User | sheet | — | presents a dialog/picker | flutter: `blocked_users_controls_test.dart` › Unblock → confirm unblocks on the server, re-reads the list and confir<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+1 more | automated |
| Cancel | button | `qa.blocked.unblock_cancel` | closes screen/sheet, pops a result to caller | flutter: `blocked_users_controls_test.dart` › Cancel keeps the member blocked and sends nothing [case:common.blocked<br>flutter: `blocked_users_controls_test.dart` › Cancel keeps the member blocked and sends nothing | automated |
| Unblock | button | `qa.blocked.unblock_confirm` | closes screen/sheet, pops a result to caller | flutter: `blocked_users_controls_test.dart` › Unblock → confirm unblocks on the server, re-reads the list and confir | automated |

#### EmergencyContactsScreen — `common.emergency_contacts`

Route: opened from: privacy_safety_screen, web_member_workspace · Source: `app/lib/features/common/screens/emergency_contacts_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | `qa.emergency.retry` | refreshes data | flutter: `emergency_contacts_controls_test.dart` › a failed load is not shown as "no contacts" (which would invite duplic<br>flutter: `emergency_contacts_controls_test.dart` › a failed load is not shown as "no contacts" (which would invite | automated |
| Add Contact | button | `qa.emergency.add` | calls POST /v1/emergency-contacts/{userID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `emergency_contacts_controls_test.dart` › add Add Contact → name and phone → Save adds it on the server and list<br>flutter: `emergency_contacts_controls_test.dart` › add > Cancel in the editor adds nothing<br>+3 more | automated |
| Edit (icon edit_outlined) | button | `qa.emergency.edit.*` | calls PUT /v1/emergency-contacts/{userID}/{contactID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `emergency_contacts_controls_test.dart` › edit Edit opens the editor prefilled; Save updates that contact [case:<br>flutter: `emergency_contacts_controls_test.dart` › edit > Edit opens the editor prefilled; Save updates that contact | automated |
| Delete (icon delete_outline) | button | `qa.emergency.delete.*` | calls DELETE /v1/emergency-contacts/{userID}/{contactID}; opens showDialog; closes screen/sheet, pops a result to caller, shows snackbar | flutter: `emergency_contacts_controls_test.dart` › remove Delete asks first; Remove deletes it on the server [case:common<br>flutter: `emergency_contacts_controls_test.dart` › remove > Delete asks first; Remove deletes it on the server | automated |
| Remove Contact | sheet | — | presents a dialog/picker | flutter: `emergency_contacts_controls_test.dart` › remove Delete asks first; Remove deletes it on the server [case:common<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+1 more | automated |
| Cancel | button | `qa.emergency.remove_cancel` | closes screen/sheet, pops a result to caller | flutter: `emergency_contacts_controls_test.dart` › remove Cancel keeps the contact [case:common.emergency_contacts.emerge | automated |
| Remove | button | `qa.emergency.remove_confirm` | closes screen/sheet, pops a result to caller | flutter: `emergency_contacts_controls_test.dart` › remove Delete asks first; Remove deletes it on the server [case:common<br>flutter: `emergency_contacts_controls_test.dart` › remove > Delete asks first; Remove deletes it on the server | automated |
| Save | sheet | — | presents a dialog/picker | flutter: `emergency_contacts_controls_test.dart` › add Add Contact → name and phone → Save adds it on the server and list<br>playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>+2 more | automated |
| Name | field | `qa.emergency.name_field` | opens TextField | flutter: `emergency_contacts_controls_test.dart` › add Add Contact → name and phone → Save adds it on the server and list<br>flutter: `emergency_contacts_controls_test.dart` › add > Cancel in the editor adds nothing<br>+2 more | automated |
| Phone Number | field | `qa.emergency.phone_field` | opens TextField | flutter: `emergency_contacts_controls_test.dart` › add Add Contact → name and phone → Save adds it on the server and list<br>flutter: `emergency_contacts_controls_test.dart` › add > a refused add explains and keeps the list as it was<br>+1 more | automated |
| Cancel | button | `qa.emergency.editor_cancel` | closes screen/sheet | flutter: `emergency_contacts_controls_test.dart` › add Cancel in the editor adds nothing [case:common.emergency_contacts.<br>flutter: `emergency_contacts_controls_test.dart` › add > Cancel in the editor adds nothing | automated |
| Save | button | `qa.emergency.editor_save` | closes screen/sheet, pops a result to caller | flutter: `emergency_contacts_controls_test.dart` › add Add Contact → name and phone → Save adds it on the server and list<br>flutter: `emergency_contacts_controls_test.dart` › add > a refused add explains and keeps the list as it was<br>+2 more | automated |

#### HelpSupportScreen — `common.help_support`

Route: opened from: support_entry_points, support_routes, web_member_workspace · Source: `app/lib/features/common/screens/help_support_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| If someone is in immediate danger, contact local emergency s | gesture | — | calls GET /v1/support/tickets; refreshes data | only checks presence: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets | presence-only |
| Contact support | button | — | may open SupportTicketFormScreen | flutter: `support_centre_test.dart` › Help & Support centre > keeps the FAQ and shows contact and My tickets | automated |
| My tickets | button | — | may open SupportTicketsScreen; refreshes data | only checks presence: flutter: `help_support_screen_test.dart` › support centre offers contact and My tickets | presence-only |

#### MainNavigationScreen — `common.main_navigation`

Route: app shell (signed-in) · Source: `app/lib/features/common/screens/main_navigation_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Explore more profiles | button | — | local/unclassified action — callback: () => _setSelectedIndex(1) ⚠  | playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Discover deck: View  | automated |
| Discovery preferences | button | — | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | — | **GAP** |
| Messages | button | — | local/unclassified action — callback: () { _setSelectedIndex(1); ref.read(matchesViewProvider.notifier).state = MatchesView.conv ⚠  | — | **GAP** |
| Discovery preferences | button | — | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | — | **GAP** |
| Settings | menu | — | local/unclassified action — callback: _setSelectedIndex | — | **GAP** |
| View | sheet | — | presents a bottom sheet | — | **GAP** |
| Dismiss | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; closes screen/sheet | — | **GAP** |
| View | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open NotificationInboxScreen; closes screen/sheet | — | **GAP** |
| Open | button | — | calls POST /v1/notifications/{userID}/{notificationID}/read, POST /v1/social/channels/{channelID}/read; may open HelpSupportScreen, NotificationInboxScreen, Sup | appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat | automated |
| View call details | sheet | — | presents a bottom sheet | — | **GAP** |
| View call details | button | — | may open NotificationInboxScreen; closes screen/sheet | — | **GAP** |
| Filters | button | — | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; may open SetupPreferencesScreen; opens showModalBottomSheet; closes screen/sheet,  | — | **GAP** |
| Verify | button | — | may open VerificationUploadIdScreen | — | **GAP** |
| Edit Profile | button | — | may open EditProfileScreen | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| showModalBottomSheet open | sheet | — | presents a bottom sheet | — | **GAP** |
| Close (icon close_rounded) | button | `qa.filters.close` | closes screen/sheet | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Age Range | toggle | `qa.filters.age_range_slider` | local/unclassified action — callback: (values) => setSheetState(() => _filterAge = values) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+4 more | automated |
| Country | menu | — | local/unclassified action — callback: (value) => setSheetState(() { _filterCountry = value; _filterState = null; _filterCity = n | — | **GAP** |
| State | menu | — | local/unclassified action — callback: (value) => setSheetState(() { _filterState = value; _filterCity = null; }) | — | **GAP** |
| City | menu | — | local/unclassified action — callback: (value) => setSheetState(() => _filterCity = value) | — | **GAP** |
| Mother Tongue | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterMotherTongue = value, ) | — | **GAP** |
| Religion | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterReligion = value, ) | — | **GAP** |
| Relationship Status | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterRelationshipStatus = value, ) | — | **GAP** |
| Smoking | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterSmoking = value, ) | appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save | automated |
| Drinking | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterDrinking = value, ) | appium: `test_03_discover_filters.py` › test_discovery_filters_reopen_after_save | automated |
| Personality Type | menu | — | local/unclassified action — callback: (value) => setSheetState( () => _filterPersonalityType = value, ) | — | **GAP** |
| Party lover only | toggle | `qa.filters.party_lover_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterPartyLoverOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Hookups only | toggle | `qa.filters.hookup_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterHookupOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Open Dating Preferences | button | — | may open SetupPreferencesScreen; closes screen/sheet | — | **GAP** |
| {distance} km | toggle | `qa.filters.distance_slider` | local/unclassified action — callback: (value) => setSheetState( () => _filterDistance = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Show only verified profiles | toggle | `qa.filters.verified_only_switch` | local/unclassified action — callback: (value) => setSheetState( () => _filterVerifiedOnly = value, ) | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Enable trust-based filtering | toggle | `qa.filters.trust_switch` | local/unclassified action — callback: (value) { setSheetState(() { trustEnabled = value; }); } | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Minimum active trust badges: {count} | toggle | `qa.filters.trust_badge_slider` | local/unclassified action — callback: trustEnabled ? (value) { setSheetState(() { minimumActiveBadges = value .round(); }); } :  | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| FilterChip onSelected | toggle | — | local/unclassified action — callback: trustEnabled ? (value) { setSheetState(() { if (value) { requiredBadgeCodes.add( badge.cod | — | **GAP** |
| Reset | button | `qa.filters.reset_button` | local/unclassified action — callback: trustState.isSaving ? null : () { setSheetState(() { _filterAge = const RangeValues( 20, 5 ⚠  | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+3 more | automated |
| Apply | button | `qa.filters.apply_button` | calls PATCH /v1/discovery/{userID}/filters/trust, GET /v1/discovery/{userID}; closes screen/sheet, refreshes data, shows snackbar | flutter: `discovery_filters_test.dart` › discovery ${entry.key} applies selected value<br>flutter: `discovery_filters_test.dart` › all discovery sliders, switches and trust badges apply<br>+5 more | automated |

#### ModerationAppealsScreen — `common.moderation_appeals`

Route: opened from: matches_list_screen, privacy_safety_screen, profile_details_screen, web_member_workspace · Source: `app/lib/features/common/screens/moderation_appeals_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Reason | field | `qa.appeals.reason` | opens TextField | flutter: `moderation_appeals_controls_test.dart` › Submit sends reason, report id and context, lists the appeal and clear | automated |
| Report ID (optional) | field | `qa.appeals.report_id` | opens TextField | flutter: `moderation_appeals_controls_test.dart` › Submit sends reason, report id and context, lists the appeal and clear | automated |
| Additional context (optional) | field | `qa.appeals.context` | opens TextField | flutter: `moderation_appeals_controls_test.dart` › Submit sends reason, report id and context, lists the appeal and clear | automated |
| Submit appeal | button | `qa.appeals.submit` | calls POST /v1/moderation/appeals, GET /v1/moderation/appeals; shows snackbar, updates local state | flutter: `moderation_appeals_controls_test.dart` › Submit sends reason, report id and context, lists the appeal and clear | automated |
| Retry | button | `qa.appeals.retry` | refreshes data | flutter: `moderation_appeals_controls_test.dart` › a failed load is not shown as "no appeals"; Retry reloads (regression) | automated |
| Reviewed by: {reviewer} | gesture | — | calls GET /v1/moderation/appeals; refreshes data, shows snackbar | flutter: `moderation_appeals_controls_test.dart` › pull to refresh shows the reviewer\'s decision [case:common.moderation | automated |

#### NotificationSettingsScreen — `common.notification_settings`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/common/screens/notification_settings_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Notification inbox | button | `qa.notifications.inbox` | may open NotificationInboxScreen | flutter: `notification_settings_controls_test.dart` › the inbox row shows the unread count and opens the inbox [case:common.<br>flutter: `notification_settings_controls_test.dart` › the inbox row shows the unread count and opens the inbox | automated |
| In-app notifications | toggle | `qa.notifications.in_app` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Push notifications | toggle | `qa.notifications.push` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$<br>flutter: `notification_settings_controls_test.dart` › offline: the switch goes back with a translated reason<br>+2 more | automated |
| New matches | toggle | `qa.notifications.new_matches` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| New messages | toggle | `qa.notifications.new_messages` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Likes | toggle | `qa.notifications.likes` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Match nudges | toggle | `qa.notifications.match_nudges` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Incoming calls | toggle | `qa.notifications.incoming_calls` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Safety updates | toggle | `qa.notifications.safety` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |
| Friends' date plans | toggle | `qa.notifications.friend_plans` | calls PATCH /v1/notifications/{userID}/preferences; shows snackbar | flutter: `notification_settings_controls_test.dart` › $key turns $field off and back on [case:common.notification_settings.$ | automated |

#### PrivacySafetyScreen — `common.privacy_safety`

Route: opened from: settings_screen, web_member_workspace · Source: `app/lib/features/common/screens/privacy_safety_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Retry | button | `qa.privacy.retry` | refreshes data | flutter: `privacy_safety_controls_test.dart` › Retry reloads the settings after a failed load [case:common.privacy_sa<br>flutter: `settings_controls_test.dart` › privacy save failure displays retry and reloads persisted value [case:<br>+3 more | automated |
| Show age | toggle | `qa.privacy.show_age` | calls PATCH /v1/settings/{userID}; refreshes data, shows snackbar | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action]<br>+1 more | automated |
| Show exact distance | toggle | `qa.privacy.show_exact_distance` | calls PATCH /v1/settings/{userID}; refreshes data, shows snackbar | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action]<br>+1 more | automated |
| Show online status | toggle | `qa.privacy.show_online_status` | calls PATCH /v1/settings/{userID}; refreshes data, shows snackbar | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › a privacy switch never overwrites the theme, language or notification <br>+1 more | automated |
| Emergency SOS | button | `qa.safety.sos_journey` | may open SosScreen | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action] | automated |
| Emergency Contacts | button | `qa.privacy.emergency_contacts` | may open EmergencyContactsScreen | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action] | automated |
| Blocked Users | button | `qa.privacy.blocked_users` | may open BlockedUsersScreen | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action] | automated |
| Moderation Appeals | button | `qa.privacy.moderation_appeals` | may open ModerationAppealsScreen | flutter: `privacy_safety_controls_test.dart` › $key saves both directions and only itself [case:common.privacy_safety<br>flutter: `privacy_safety_controls_test.dart` › $key opens $screen [case:common.privacy_safety.$name.action] | automated |
| Let people find me in friend search | toggle | `qa.privacy.friend_search` | calls PUT /v1/friends/{userID}/search-visibility, PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | flutter: `privacy_safety_controls_test.dart` › friend search: PUT /friends/{me}/search-visibility both directions [ca<br>flutter: `friend_search_visibility_test.dart` › privacy switch turns friend search off and back on [case:common.privac<br>+2 more | automated |
| Show my public writing on my profile | toggle | `qa.privacy.profile_showcase` | calls PUT /v1/profile/{userID}/showcase/consent; refreshes data, shows snackbar | flutter: `privacy_safety_controls_test.dart` › profile showcase: PUT /profile/{me}/showcase/consent both directions [ | automated |
| Share crash reports | toggle | `qa.privacy.crash_reports` | local/unclassified action — callback: (v) => reporter.setOptIn(enabled: v) | flutter: `privacy_crash_reports_test.dart` › Share crash reports is on by default and persists toggles [case:common<br>flutter: `privacy_crash_reports_test.dart` › Share crash reports is on by default and persists toggles | automated |
| Resume | button | `qa.graduation.discovery_resume` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | flutter: `privacy_safety_controls_test.dart` › Pause hides the member from discovery; Resume brings them back [case:c<br>flutter: `privacy_safety_controls_test.dart` › Pause hides the member from discovery; Resume brings them back<br>+1 more | automated |
| Pause | button | `qa.graduation.discovery_pause` | calls GET /v1/matches/{matchID}/graduation, GET /v1/account/{userID}/discovery/pause, POST /v1/account/{}/discovery/{} | flutter: `privacy_safety_controls_test.dart` › Pause hides the member from discovery; Resume brings them back [case:c<br>flutter: `privacy_safety_controls_test.dart` › Pause hides the member from discovery; Resume brings them back | automated |

#### SettingsScreen — `common.settings`

Route: #/settings (web) / bottom nav: Settings tab (mobile) · Source: `app/lib/features/common/screens/settings_screen.dart` · in screen matrix

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Notification inbox | button | `qa.settings.notification_inbox` | may open NotificationInboxScreen | — | **GAP** |
| Your dating rhythm | button | `qa.settings.dating_rhythm` | may open DatingRhythmScreen | playwright: `intentional-dating.spec.js` › intentional dating ${part} at ${width}px | automated |
| Your profile stories | button | `qa.settings.profile_stories` | may open ProfileStoriesScreen | — | **GAP** |
| Blog · Open Chapters | button | `qa.settings.blog` | may open BlogScreen | — | **GAP** |
| Edit Profile | button | `qa.settings.edit_profile` | may open EditProfileScreen | appium: `test_02_edit_profile.py` › test_edit_profile_binds_saved_profile<br>appium: `test_02_edit_profile.py` › test_edit_preferences_toggle_saves_and_returns_to_edit_profile | automated |
| Photos | button | `qa.settings.photos` | may open SetupPhotosScreen | — | **GAP** |
| Language | button | `qa.settings.language` | may open LanguageSettingsScreen | flutter: `settings_navigation_test.dart` › Settings rows $key opens $screen [case:$caseId] | automated |
| Dating Preferences | button | `qa.settings.dating_preferences` | may open SetupPreferencesScreen | — | **GAP** |
| Account & Data | button | `qa.settings.account_data` | may open AccountDataScreen | appium: `test_15_account_lifecycle.py` › test_account_data_screen_shows_every_journey<br>appium: `test_15_account_lifecycle.py` › test_pause_hides_profile_and_can_be_undone<br>+3 more | automated |
| Notifications | button | `qa.settings.notifications` | may open NotificationSettingsScreen | — | **GAP** |
| Trust Badges | button | `qa.settings.trust_badges` | may open TrustBadgesScreen | — | **GAP** |
| Trust Filters | button | `qa.settings.trust_filters` | may open TrustFilterScreen | — | **GAP** |
| Conversation Rooms | button | `qa.settings.conversation_rooms` | may open ConversationRoomsScreen | — | **GAP** |
| Friends & Connections | button | `qa.settings.friends` | may open FriendsScreen | appium: `test_19_friends.py` › test_friend_search_sends_request_to_counterpart<br>appium: `test_19_friends.py` › test_remove_friend_from_menu<br>+1 more | automated |
| Call History | button | `qa.settings.call_history` | may open CallHistoryScreen | — | **GAP** |
| Match Nudges | button | `qa.settings.match_nudges` | may open MatchNudgesScreen | — | **GAP** |
| Subscriptions | button | `qa.settings.subscriptions` | may open SubscriptionScreen | — | **GAP** |
| Privacy & Safety | button | `qa.settings.privacy_safety` | may open PrivacySafetyScreen | playwright: `app-member-workspace.spec.js` › phone: a screen opened from Settings goes back to Settings<br>playwright: `profile-cinematic.spec.js` › back, forward and reload across profile and privacy keep the member si<br>+1 more | automated |
| Government Verification | button | `qa.settings.government_verification` | may open VerificationLandingScreen | flutter: `settings_navigation_test.dart` › Settings rows $key opens $screen [case:$caseId]<br>appium: `test_12_verification_safety.py` › test_verification_landing_renders | automated |
| QA Verification Upload | button | `qa.settings.verification_upload` | may open VerificationUploadIdScreen | flutter: `settings_navigation_test.dart` › Settings rows QA Verification Upload opens the ID upload only in an au<br>appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>+1 more | automated |
| About | button | `qa.settings.about` | may open AboutAppScreen | — | **GAP** |
| Sign out | button | `qa.settings.logout` | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open WelcomeScreen; opens showDialog; closes screen/sheet, pops a result t | flutter: `settings_logout_test.dart` › Logout unregisters this device, revokes the session and shows Welcome <br>flutter: `settings_logout_test.dart` › a double tap on the confirm button sends each request once [case:commo<br>+6 more | automated |
| Sign out of all devices | button | `qa.settings.logout_all` | calls POST /v1/auth/sessions/revoke, POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID}; may open WelcomeScreen; opens showDialog; close | flutter: `settings_logout_test.dart` › Sign out of all devices ends every session on the server, then signs o<br>flutter: `settings_logout_test.dart` › Sign out of all devices ends every session on the server, | automated |
| Cancel | sheet | — | presents a dialog/picker | — | **GAP** |
| Cancel | button | — | closes screen/sheet, pops a result to caller | flutter: `blog_screen_controls_test.dart` › delete, report and block > Delete asks first; Cancel keeps the chapter<br>flutter: `blog_screen_controls_test.dart` › delete, report and block > a failed block explains and keeps the chapt<br>+1 more | automated |
| confirm | button | — | closes screen/sheet, pops a result to caller | flutter: `settings_logout_test.dart` › Logout while offline still signs the member out on this device<br>flutter: `settings_logout_test.dart` › Logout when the server rejects it still signs the member out<br>+11 more | automated |
| Could not save your theme. Please try again. | toggle | `qa.settings.theme_selector` | calls PATCH /v1/settings/{userID}; shows snackbar | flutter: `settings_theme_test.dart` › Light, Dark and Match device are each saved to the account [case:commo<br>flutter: `settings_controls_test.dart` › appearance saves light dark and system themes [case:common.settings.se | automated |
| check circle (icon check_circle) | button | `qa.settings.theme_preset.*` | calls PATCH /v1/settings/{userID}; opens showGeneralDialog; closes screen/sheet, shows snackbar | flutter: `settings_theme_test.dart` › choosing a look saves it, plays its title card and ticks it [case:comm<br>flutter: `settings_theme_test.dart` › a calm (reduced-motion) look saves without a title card [case:common.s<br>+2 more | automated |

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
| Report could not be submitted. | button | — | calls POST /v1/blog/reports/{kind}/{contentID}; shows snackbar | — | **GAP** |

#### LanguageOptionList — `common.language_picker`

Route: opened from: language_settings_screen · Source: `app/lib/features/common/widgets/language_picker.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Use device language | button | — | refreshes data, shows snackbar | flutter: `language_settings_controls_test.dart` › Use device language clears the stored language [case:common.language_p | automated |
| check circle rounded (icon check_circle_rounded) | button | — | refreshes data, shows snackbar | flutter: `language_settings_controls_test.dart` › picking ${language.nativeName} saves "${language.tag}" [case:common.la | automated |
| Pick the language Connect uses. It changes right away, and w | sheet | — | presents a bottom sheet | — | **GAP** |
| language rounded (icon language_rounded) | button | — | opens showLanguagePickerSheet, showModalBottomSheet; closes screen/sheet | — | **GAP** |
| language rounded (icon language_rounded) | button | — | opens showLanguagePickerSheet, showModalBottomSheet; closes screen/sheet | — | **GAP** |

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
| About renders in every shipped language | l10n | flutter: `about_app_test.dart` › About renders in every shipped language [case:common.about_app.l10n] | automated |
| About shows the build's own version | happy | flutter: `about_app_test.dart` › About shows the build\'s own version [case:common.about_app.version] | automated |

#### LanguageSettingsScreen — `common.language_settings`

Route: see screen matrix · Source: `app/lib/features/common/screens/language_settings_screen.dart` · in screen matrix

_No interactive control detected in this file by static extraction (display-only, or controls live in shared child widgets listed under their own feature)._

| Case | Type | Automated by | Status |
|---|---|---|---|
| LanguageSettingsScreen lays out on every device size/theme | layout | flutter: `screen_matrix_test.dart` › $screenLabel lays out on $deviceLabel [$themeLabel] | automated |
| LanguageSettingsScreen meets accessibility guidelines | a11y | flutter: `screen_accessibility_test.dart` › $label meets accessibility guidelines [$themeLabel] | automated |
| LanguageSettingsScreen shows a visible way back when pushed | a11y | flutter: `back_affordance_audit_test.dart` › ${entry.key} shows a way back when pushed | automated |
| Language settings renders in every shipped language | l10n | flutter: `language_settings_controls_test.dart` › Language renders in every shipped language [case:common.language_setti | automated |
| After an account switch the next member gets their own stored language | edge | flutter: `account_switch_isolation_test.dart` › the next member gets their own stored language [case:common.language_s | automated |

#### Push token lifecycle — `core.push`

Route: cross-cutting · Source: `app/lib/core/push/push_notification_service.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Signing out after every session was revoked deletes only the device token | edge | flutter: `push_notification_service_test.dart` › signing out after every session was revoked only the token is deleted  | automated |
| An offline sign-out still deletes the device push token | edge | flutter: `push_notification_service_test.dart` › signing out an offline sign-out still deletes the device push token [c | automated |
| A failing token deletion never fails sign-out | negative | flutter: `push_notification_service_test.dart` › signing out a failing token deletion never fails sign-out [case:core.p | automated |
| Sign-out without a Firebase plugin (tests, web, desktop) completes | edge | flutter: `push_notification_service_test.dart` › signing out sign-out without a Firebase plugin (tests, web, desktop) c | automated |

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
| Sign out | button | — | calls POST /v1/auth/logout, DELETE /v1/notifications/{userID}/devices/{deviceID} | only checks presence: flutter: `web_member_workspace_test.dart` › phone width drops the sidebar and shows Discover | presence-only |
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
| Open this link? | sheet | — | presents a dialog/picker | playwright: `console-layout.spec.js` › report actions open in a centred, opaque Bootstrap modal [case:console<br>playwright: `console-layout.spec.js` › destructive actions confirm in the Bootstrap dialog, not window.confir | automated |
| Cancel | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Open link | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |

#### RichTextEditor — `core.rich_text_editor`

Route: opened from: blog_editor, profile_stories · Source: `app/lib/core/rich_text/rich_text_editor.dart`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| showDialog open | sheet | — | presents a dialog/picker | — | **GAP** |
| TextFormField input | field | — | opens TextFormField | — | **GAP** |
| style | toggle | — | local/unclassified action — callback: (style) => c.style = style | — | **GAP** |
| Text style | menu | — | local/unclassified action — callback: (type) => editor.run(() => c.setBlockType(type)) | flutter: `blog_editor_controls_test.dart` › the formatting toolbar shapes what the chapter saves | automated |
| Alignment | menu | — | local/unclassified action — callback: (align) => editor.run(() => c.setAlign(align)) | — | **GAP** |
| Web address | field | — | closes screen/sheet, pops a result to caller, updates local state | flutter: `blog_editor_controls_test.dart` › the formatting toolbar shapes what the chapter saves | automated |
| Cancel | button | — | closes screen/sheet | — | **GAP** |
| Remove link | button | — | closes screen/sheet, pops a result to caller | — | **GAP** |
| Add link | button | — | closes screen/sheet, pops a result to caller, updates local state | flutter: `blog_editor_controls_test.dart` › the formatting toolbar shapes what the chapter saves | automated |

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
| Like → mutual like → match screen → unlock chat → send first message → other member receives | happy | playwright: `app-journeys.spec.js` › profile Love and Message from every entry point > Today rail: Meet → M<br>playwright: `app-journeys.spec.js` › Today rail: Meet → Message with someone who liked you makes the match,<br>+4 more | automated |
| Send a gift in chat: free daily gift, coin gift, insufficient coins → wallet top-up | happy | appium: `test_00_seed_preflight.py` › test_seeded_matches_chat_gifts_and_wallet<br>appium: `test_05_chat_gifts_contract_api.py` › test_chat_gift_wallet_contract_matrix<br>+8 more | automated |
| Upgrade plan via checkout (sandbox/Stripe test), auto-renew off, wallet coin purchase | happy | appium: `test_00_seed_preflight.py` › test_seeded_matches_chat_gifts_and_wallet<br>appium: `test_05_chat_gifts_contract_api.py` › test_chat_gift_wallet_contract_matrix<br>+6 more | automated |
| Report and block a member; blocked member disappears everywhere; appeal flow | happy | appium: `test_05_profile_details.py` › test_discovery_profile_detail_report_entry_renders<br>appium: `test_12_verification_safety.py` › test_profile_report_submit_success<br>+8 more | automated |
| Add friend → accept → open friend chat → send message | happy | appium: `test_19_friends.py` › test_friend_search_sends_request_to_counterpart<br>appium: `test_19_friends.py` › test_incoming_request_accept_and_friend_chat<br>+8 more | automated |
| Join a room / create a group → invite → group chat | happy | appium: `test_11_engagement_surfaces_api.py` › test_community_groups_list_contract<br>appium: `test_20_conversation_rooms.py` › test_rooms_list_join_send_and_leave<br>+8 more | automated |
| Propose date plan → partner accepts → friend fan-out → debrief after the date | happy | api_e2e: `test_15_social_graph_dating_extras.py` › test_date_plan_state_machine<br>api_e2e: `test_21_catalog_engagement_billing_safety.py` › test_date_plan_shared_with_a_trusted_friend | automated |
| Download data, pause discovery, delete account | happy | appium: `test_15_account_lifecycle.py` › test_export_produces_the_members_own_data<br>appium: `test_15_account_lifecycle.py` › test_delete_requires_confirmation_and_offers_hiding<br>+8 more | automated |
| Upload ID + selfie → pending → approved by operator | happy | appium: `test_12_verification_safety.py` › test_verification_landing_renders<br>appium: `test_12_verification_safety.py` › test_verification_upload_id_from_gallery_reaches_selfie_step<br>+3 more | automated |
| Change look and language in Settings; persists after restart | happy | appium: `test_23_settings_theme_privacy.py` › test_theme_strip_snow_and_gothic_persist_to_account<br>playwright: `a11y-smoke.spec.js` › a11y smoke ${url} [${locale.hreflang}] [case:site.site_header.a11y]<br>+8 more | automated |
| Back from every pushed screen returns to the opener (Android back + on-screen back) | happy | appium: `test_05_profile_details.py` › test_discovery_profile_detail_back_preserves_deck<br>appium: `test_22_back_navigation_today.py` › test_system_back_from_tab_returns_to_today<br>+6 more | automated |

### Website (public)

#### Shared header/footer (all public pages) — `site.site_header`

Route: / , /features, /safety, /contact, /membership, /guidelines, /privacy (+ /{de,en-gb,es,fr,it,nl,pl,pt,ru}/...) · Source: `website/public/site.js`, `website/generate_pages.py`, `website/locales/`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Language (select[data-lang-switch]) | menu | — | navigates to the same page in the chosen locale (site.js change handler sets location.href) | playwright: `public-pages.spec.js` › locale switcher moves between every locale on the same page [case:site<br>playwright: `website.spec.js` › localised pages carry their language, the full feature list and altern | automated |
| Open menu (.menu-toggle) | button | — | toggles aria-expanded and the mobile nav (<=1000px) | playwright: `public-pages.spec.js` › header navigation, skip link and mobile menu work in every locale [cas<br>playwright: `responsive.spec.js` › WEB-04: tablet header fits at 768px in long-label locales [case:site.s<br>+3 more | automated |
| Features / How it works / Safety / Sign in / Join | link | — | navigates to page or /app/#/signin, /app/#/signup; closes mobile menu | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `public-pages.spec.js` › header navigation, skip link and mobile menu work in every locale [cas<br>+6 more | automated |
| Skip to content | link | — | moves focus to #main | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `public-pages.spec.js` › header navigation, skip link and mobile menu work in every locale [cas | automated |
| Footer: Contact, Privacy, Guidelines, Safety, Membership | link | — | navigates to the localized page | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Every internal link, asset and app deep link resolves | happy | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |
| Public pages pass axe smoke, heading order and visible focus | a11y | playwright: `a11y-smoke.spec.js` › WEB-05: heading levels never skip on generated pages [case:site.site_h<br>playwright: `a11y-smoke.spec.js` › a11y smoke ${url} [${locale.hreflang}] [case:site.site_header.a11y]<br>+3 more | automated |
| Every browser-facing response carries security headers (CSP etc.) | negative | playwright: `website.spec.js` › every browser-facing response carries security headers [case:site.site<br>playwright: `website.spec.js` › website rejects untrusted hosts and oversized proxy bodies [case:site. | automated |

#### Home page — `site.index`

Route: / (+9 locale prefixes) · Source: `website/public/index.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Create account / Join | link | — | opens /app/#/signup | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |
| Sign in | link | — | opens /app/#/signin | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |
| FAQ <details> items | toggle | — | expand/collapse answers | playwright: `website.spec.js` › mobile navigation and FAQ operate with keyboard and touch targets [cas | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Home renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `responsive.spec.js` › ${locale.hreflang} pages fit ${viewport.name} ${manifest.pages.map(p =<br>+1 more | automated |

#### Features page — `site.features`

Route: /features (+9 locale prefixes) · Source: `website/public/features.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Find a feature (#feature-search) | field | — | filters feature cards live; announces result count politely | playwright: `public-forms.spec.js` › feature search is keyboard operable and announces results politely [ca<br>playwright: `public-pages.spec.js` › features page lists every feature in every locale and search works [ca<br>+1 more | automated |
| Feature card deep links (/app/#/discover, /matches, /prefere | link | — | opens the web app route | playwright: `links.spec.js` › every feature card opens its own page in the signed-in web app [case:s<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_ | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Features renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `public-pages.spec.js` › features page lists every feature in every locale and search works [ca<br>+4 more | automated |

#### Safety page — `site.safety`

Route: /safety (+9 locale prefixes) · Source: `website/public/safety.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Safety resources / Contact links | link | — | navigates | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Safety renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `website.spec.js` › ${path} has working content and fits ${width}px [case:site.${path === <br>+1 more | automated |

#### Membership page — `site.membership`

Route: /membership (+9 locale prefixes) · Source: `website/public/membership.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Plan call-to-action | link | — | opens /app/#/membership (sign-in gated) | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Membership renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `website.spec.js` › ${path} has working content and fits ${width}px [case:site.${path === <br>+1 more | automated |

#### Community guidelines page — `site.guidelines`

Route: /guidelines (+9 locale prefixes) · Source: `website/public/guidelines.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Links | link | — | navigates | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Community guidelines renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `website.spec.js` › ${path} has working content and fits ${width}px [case:site.${path === <br>+1 more | automated |

#### Privacy page — `site.privacy`

Route: /privacy (+9 locale prefixes) · Source: `website/public/privacy.html`, `website/generate_pages.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Links | link | — | navigates | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Privacy renders in every locale with one h1 and fits phone/tablet/desktop | layout | playwright: `public-pages.spec.js` › ${url} [${locale.hreflang}] renders its locale [case:site.${page}.rend<br>playwright: `website.spec.js` › ${path} has working content and fits ${width}px [case:site.${path === <br>+1 more | automated |

#### Contact page — `site.contact`

Route: /contact (+locales) · Source: `website/public/contact.html`, `website/public/contact.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Email (#contact-email) | field | — | required, validated email | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [<br>+1 more | automated |
| Name (#contact-name, optional) | field | — | optional; omitted from payload when empty | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [ | automated |
| Category (#contact-category) | menu | — | required select | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [<br>+1 more | automated |
| Subject (#contact-subject) | field | — | 4-120 chars | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [<br>+1 more | automated |
| Description (#contact-description) + live counter | field | — | required, max 5000 | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [<br>+1 more | automated |
| Hidden website honeypot (#contact-website) | field | — | bots filling it are dropped | playwright: `contact.spec.js` › honeypot is present, hidden from people and skipped by keyboard [case: | automated |
| Send (#contact-submit) | button | — | client-validates, then POST /v1/support/contact with locale; shows reference number | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact<br>playwright: `contact.spec.js` › success without a reference still confirms; optional name is omitted [<br>+3 more | automated |
| Send another message (#contact-again) | button | — | resets the form for a new message | playwright: `contact.spec.js` › valid submission posts JSON and shows the reference [case:site.contact | automated |
| Error summary links | link | — | focus the invalid field | playwright: `contact.spec.js` › client validation lists errors, focuses the summary and sends nothing  | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Honeypot hidden from people and skipped by keyboard | a11y | playwright: `contact.spec.js` › honeypot is present, hidden from people and skipped by keyboard [case: | automated |
| Localized contact page sends its locale and shows translated copy | l10n | playwright: `contact.spec.js` › localised contact page sends its locale and shows translated copy [cas | automated |
| With support switched off (live stack) the form explains it and keeps the message | negative | playwright: `contact.spec.js` › live stack: with support switched off the form explains it and keeps t | automated |
| Contact page renders the form without CSP violations at phone and desktop widths | layout | playwright: `contact.spec.js` › contact page renders the form without CSP violations at ${width}px [ca | automated |
| POST /v1/support/contact validates and stores the message | happy | api_e2e: `test_19_catalog_api_contracts.py` › test_api_contract_error_paths[site.contact.api_contract]<br>api_e2e: `test_21_catalog_engagement_billing_safety.py` › test_support_ticket_lifecycle<br>+2 more | automated |

#### Shared story page — `site.story`

Route: /story.html?id=<publication> · Source: `website/public/story.html`, `website/public/story.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Share (#share) | button | — | navigator.share or copy fallback | playwright: `blog-public.spec.js` › Copy link and Pass this Chapter share the canonical story URL [case:si<br>playwright: `blog-public.spec.js` › Share without a share sheet copies, and a withdrawn story hands out no<br>+1 more | automated |
| Copy link (#copy) | button | — | copies share URL to clipboard | playwright: `blog-public.spec.js` › Copy link and Pass this Chapter share the canonical story URL [case:si<br>playwright: `blog-public.spec.js` › Share without a share sheet copies, and a withdrawn story hands out no | automated |
| Retry (#retry) | button | — | re-fetches the publication | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials [case:site | automated |
| Report reason (#reason) | menu | — | required | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials [case:site | automated |
| Report description (#description) | field | — | max 1000 | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials [case:site | automated |
| Send report (#report-submit) | button | — | POST {endpoint}/report without credentials | playwright: `blog-public.spec.js` › report retry preserves text and sends no member credentials [case:site | automated |
| Start your own chapter / Join | link | — | opens /chapter.html or /app/#/signup | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Approved story renders safe DOM at phone/desktop widths | happy | playwright: `blog-public.spec.js` › approved story renders safely at ${width}px [case:site.story.renders_s<br>playwright: `blog-public.spec.js` › formatted excerpt renders as safe DOM in the chosen writing style [cas<br>+1 more | automated |
| Withdrawn/invalid links clear content and never fetch a bad source | negative | playwright: `blog-public.spec.js` › withdrawn link clears its previously displayed content [case:site.stor<br>playwright: `blog-public.spec.js` › incomplete links never fetch a source [case:site.story.withdrawn] | automated |
| Copy and Share produce the canonical share URL | happy | playwright: `blog-public.spec.js` › Copy link and Pass this Chapter share the canonical story URL [case:si<br>playwright: `blog-public.spec.js` › Share without a share sheet copies, and a withdrawn story hands out no | automated |
| Without a share sheet, Share copies the link; a withdrawn story hands out nothing | edge | playwright: `blog-public.spec.js` › Share without a share sheet copies, and a withdrawn story hands out no | automated |
| The story page loads with a language and one h1 before any id is resolved | l10n | — | **GAP** |
| The story page fits every viewport | layout | playwright: `responsive.spec.js` › standalone pages fit ${viewport.name} [case:site.story.layout] [case:s | automated |

#### Pass the Chapter (public studio) — `site.chapter`

Route: /chapter.html[?scene=&beginning=&surprise=\|?share=] · Source: `website/public/chapter.html`, `website/public/chapter.js`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Beginning / surprise choice buttons (aria-pressed) | toggle | — | select options; updates remix URL | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset [case | automated |
| Copy remix link (#copy) | button | — | copies remix URL | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset [case | automated |
| Share (#share) | button | — | navigator.share or copy | playwright: `public-forms.spec.js` › Pass the Chapter: Share passes the remix link, with a copy fallback [c | automated |
| Start again (#reset) | button | — | clears choices | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset [case | automated |
| Join Connect | link | — | opens /app/#/signup | playwright: `contact.spec.js` › footer links to the contact page in each locale [case:site.site_header<br>playwright: `links.spec.js` › every internal link, asset and app deep link resolves [case:site.site_<br>+4 more | automated |

| Case | Type | Automated by | Status |
|---|---|---|---|
| Choose, copy a remix link, reopen it and reset | happy | playwright: `public-forms.spec.js` › Pass the Chapter: choose, copy a remix link, reopen it and reset [case | automated |
| Tampered remix links degrade safely (no XSS) | negative | playwright: `public-forms.spec.js` › Pass the Chapter: tampered remix links degrade safely [case:site.chapt | automated |
| Missing shared card shows a calm error | negative | playwright: `public-forms.spec.js` › Pass the Chapter: a missing shared card shows a calm error, no studio  | automated |
| Share passes the remix link, with a copy fallback | happy | playwright: `public-forms.spec.js` › Pass the Chapter: Share passes the remix link, with a copy fallback [c | automated |
| The chapter studio loads with a language and one h1 | l10n | — | **GAP** |
| The chapter studio fits every viewport | layout | playwright: `responsive.spec.js` › standalone pages fit ${viewport.name} [case:site.story.layout] [case:s | automated |

#### Generated public pages — `site.generator`

Route: website/public/*.html (+ locales) · Source: `website/generate_pages.py`, `website/locales/`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Committed public/ pages match the generator output | edge | playwright: `public-pages.spec.js` › committed public/ pages match the generator output [case:site.generato | automated |

### Operator console

#### Member activity — `console.activity`

Route: control-panel /activity/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_activity.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| member activity | link | — | page → /activity/ (views_activity.member_activity) | django: `test_member_activity.py` › MemberActivityPageTest.test_lists_actions_with_detail_and_escapes_text<br>django: `test_member_activity.py` › MemberActivityPageTest.test_failure_shows_banner<br>+11 more | automated |
| Search action or route (member activity) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Member ID filter (member activity) | field | — | text filter 'member' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Area filter (member activity) | menu | — | choice filter 'category' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Action key filter (member activity) | field | — | text filter 'action' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Outcome filter (member activity) | menu | — | choice filter 'outcome' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Source filter (member activity) | menu | — | choice filter 'source' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Method filter (member activity) | menu | — | choice filter 'method' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Include reads filter (member activity) | menu | — | choice filter 'include_reads' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| From (UTC) filter (member activity) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| To (UTC) filter (member activity) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_member_activity.py` › MemberActivityPageTest.test_filters_reach_go<br>django: `test_member_activity.py` › test_filters_reach_go<br>+1 more | automated |
| Export Excel (member activity) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_member_activity.py` › MemberActivityPageTest.test_export_has_every_detail_column<br>django: `test_member_activity.py` › test_export_has_every_detail_column | automated |
| Member page: latest actions + link to the full log | link | — | user_detail renders the member's latest actions (Go member_activity) and links to /activity/?member= | django: `test_member_activity.py` › MemberPageActivityTest.test_member_page_shows_summary_and_latest_actio<br>django: `test_member_activity.py` › MemberPageActivityTest.test_role_without_access_sees_a_note | automated |

#### Server activity — `console.system`

Route: control-panel /system/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_system.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| system events | link | — | page → /system/ (views_system.system_events) | django: `test_console_smoke.py` › test_nav_page_loads_cleanly | partial |
| Search message or route (system events) | field | — | free-text search sent to Go as q (escaped in page links) | — | **GAP** |
| Kind filter (system events) | menu | — | choice filter 'kind' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Severity filter (system events) | menu | — | choice filter 'severity' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Service filter (system events) | field | — | text filter 'service' sent to Go only when allowed by the ListSpec | — | **GAP** |
| From (UTC) filter (system events) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | — | **GAP** |
| To (UTC) filter (system events) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | — | **GAP** |
| Export Excel (system events) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| system jobs | link | — | page → /system/jobs/ (views_system.system_jobs) | — | **GAP** |
| Search error (system jobs) | field | — | free-text search sent to Go as q (escaped in page links) | — | **GAP** |
| Worker filter (system jobs) | field | — | text filter 'worker' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Status filter (system jobs) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | — | **GAP** |
| From (UTC) filter (system jobs) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | — | **GAP** |
| To (UTC) filter (system jobs) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | — | **GAP** |
| Export Excel (system jobs) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| system requests | link | — | page → /system/traffic/ (views_system.system_requests) | — | **GAP** |
| from (system requests) | field | — | GET filter 'from' | — | **GAP** |
| to (system requests) | field | — | GET filter 'to' | — | **GAP** |
| grain (system requests) | menu | — | GET filter 'grain' | — | **GAP** |
| group by (system requests) | menu | — | GET filter 'group_by' | — | **GAP** |
| status class (system requests) | menu | — | GET filter 'status_class' | — | **GAP** |
| /v1/swipe (system requests) | field | — | GET filter 'route' | — | **GAP** |
| system capacity | link | — | page → /system/capacity/ (views_system.system_capacity) | — | **GAP** |
| from (system capacity) | field | — | GET filter 'from' | — | **GAP** |
| to (system capacity) | field | — | GET filter 'to' | — | **GAP** |
| system third party | link | — | page → /system/third-party/ (views_system.system_third_party) | — | **GAP** |
| from (system third party) | field | — | GET filter 'from' | — | **GAP** |
| to (system third party) | field | — | GET filter 'to' | — | **GAP** |

#### Report server — `console.reports`

Route: control-panel /reports/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/reports/engine.py`, `control-panel/control_panel/reports/exporters.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| report catalog | link | — | page → /reports/ (views_reports.report_catalog) | django: `test_reports.py` › test_catalog_lists_reports_and_searches<br>django: `test_reports.py` › test_catalog_hides_reports_the_role_cannot_read<br>+2 more | automated |
| Revenue, churn, retention, city… (report catalog) | field | — | GET filter 'q' | django: `test_reports.py` › test_catalog_lists_reports_and_searches | automated |
| report view | link | — | page → /reports/<slug:report_id>/ (views_reports.report_view) | django: `test_reports.py` › test_city_drills_through_to_liquidity<br>django: `test_reports.py` › test_role_refusal_is_shown_not_crashed<br>+12 more | automated |
| Find a report (q) | field | — | filters the catalog by title, description, category and keywords | django: `test_reports.py` › ReportServerTest.test_catalog_lists_reports_and_searches | automated |
| Group by (per table) | menu | — | group_<dataset>=field regroups a table or shows it flat | django: `test_reports.py` › ReportServerTest.test_group_by_can_be_changed_or_removed | automated |
| Drill-through links | link | — | a drill field links to another report with its parameters | django: `test_reports.py` › ReportServerTest.test_city_drills_through_to_liquidity | automated |
| Export Excel | button | — | ?export=xlsx | django: `test_reports.py` › ReportServerTest.test_excel_export_has_typed_sheets_and_parameters | automated |
| Export CSV (per table) | button | — | ?export=csv&dataset=<key> | django: `test_reports.py` › ReportServerTest.test_csv_export_of_one_table | automated |
| Export PDF | button | — | ?export=pdf | django: `test_reports.py` › ReportServerTest.test_pdf_export | automated |

#### Analytics — `console.analytics`

Route: control-panel /analytics/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_analytics.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| analytics overview | link | — | page → /analytics/ (views_analytics.analytics_overview) | django: `test_analytics.py` › AnalyticsPagesTest.test_overview_renders_tiles_chart_and_table_with_su<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_overview_bff_failure_shows_banner<br>+4 more | partial |
| from (analytics overview) | field | — | GET filter 'from' | — | **GAP** |
| to (analytics overview) | field | — | GET filter 'to' | — | **GAP** |
| grain (analytics overview) | menu | — | GET filter 'grain' | — | **GAP** |
| All cities (analytics overview) | field | — | GET filter 'city' | — | **GAP** |
| analytics funnel | link | — | page → /analytics/funnel/ (views_analytics.analytics_funnel) | django: `test_analytics.py` › AnalyticsPagesTest.test_member_role_sees_role_message<br>django: `test_analytics.py` › AnalyticsPagesTest.test_funnel_forwards_window_and_renders_both_tables<br>+4 more | automated |
| from (analytics funnel) | field | — | GET filter 'from' | django: `test_analytics.py` › test_funnel_forwards_window_and_renders_both_tables | automated |
| to (analytics funnel) | field | — | GET filter 'to' | django: `test_analytics.py` › test_funnel_forwards_window_and_renders_both_tables | automated |
| grain (analytics funnel) | menu | — | GET filter 'grain' | django: `test_analytics.py` › test_funnel_forwards_window_and_renders_both_tables | automated |
| All cities (analytics funnel) | field | — | GET filter 'city' | django: `test_analytics.py` › test_funnel_forwards_window_and_renders_both_tables | automated |
| analytics retention | link | — | page → /analytics/retention/ (views_analytics.analytics_retention) | django: `test_analytics.py` › AnalyticsPagesTest.test_retention_heatmap_and_experiment<br>django: `test_analytics.py` › test_retention_heatmap_and_experiment<br>+1 more | partial |
| from (analytics retention) | field | — | GET filter 'from' | — | **GAP** |
| to (analytics retention) | field | — | GET filter 'to' | — | **GAP** |
| grain (analytics retention) | menu | — | GET filter 'grain' | — | **GAP** |
| All cities (analytics retention) | field | — | GET filter 'city' | — | **GAP** |
| analytics engagement | link | — | page → /analytics/engagement/ (views_analytics.analytics_engagement) | django: `test_cases_reports.py` › AnalyticsCasesTest.test_engagement_renders_report<br>django: `test_analytics.py` › test_invalid_filters_are_not_forwarded<br>+3 more | automated |
| from (analytics engagement) | field | — | GET filter 'from' | django: `test_analytics.py` › test_invalid_filters_are_not_forwarded | automated |
| to (analytics engagement) | field | — | GET filter 'to' | django: `test_analytics.py` › test_invalid_filters_are_not_forwarded | automated |
| grain (analytics engagement) | menu | — | GET filter 'grain' | django: `test_analytics.py` › test_invalid_filters_are_not_forwarded | automated |
| All cities (analytics engagement) | field | — | GET filter 'city' | django: `test_analytics.py` › test_invalid_filters_are_not_forwarded | automated |
| analytics liquidity | link | — | page → /analytics/liquidity/ (views_analytics.analytics_liquidity) | django: `test_analytics.py` › AnalyticsPagesTest.test_liquidity_and_safety_escape_member_text<br>django: `test_analytics.py` › test_liquidity_and_safety_escape_member_text<br>+1 more | partial |
| from (analytics liquidity) | field | — | GET filter 'from' | — | **GAP** |
| to (analytics liquidity) | field | — | GET filter 'to' | — | **GAP** |
| grain (analytics liquidity) | menu | — | GET filter 'grain' | — | **GAP** |
| All cities (analytics liquidity) | field | — | GET filter 'city' | — | **GAP** |
| analytics safety | link | — | page → /analytics/safety/ (views_analytics.analytics_safety) | django: `test_analytics.py` › AnalyticsPagesTest.test_liquidity_and_safety_escape_member_text<br>django: `test_analytics.py` › test_liquidity_and_safety_escape_member_text<br>+1 more | partial |
| from (analytics safety) | field | — | GET filter 'from' | — | **GAP** |
| to (analytics safety) | field | — | GET filter 'to' | — | **GAP** |
| grain (analytics safety) | menu | — | GET filter 'grain' | — | **GAP** |
| All cities (analytics safety) | field | — | GET filter 'city' | — | **GAP** |
| analytics data | link | — | page → /analytics/data/ (views_analytics.analytics_data) | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_analytics.py` › test_data_page_rebuild_and_flags<br>+4 more | automated |
| from (analytics data) | field | — | GET filter 'from' | django: `test_analytics.py` › test_data_page_rebuild_and_flags | automated |
| to (analytics data) | field | — | GET filter 'to' | django: `test_analytics.py` › test_data_page_rebuild_and_flags | automated |
| grain (analytics data) | menu | — | GET filter 'grain' | django: `test_analytics.py` › test_data_page_rebuild_and_flags | automated |
| All cities (analytics data) | field | — | GET filter 'city' | django: `test_analytics.py` › test_data_page_rebuild_and_flags | automated |
| analytics rebuild | button | — | POST form → /analytics/data/rebuild/ (views_analytics.analytics_rebuild) | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_rebuild_refusal_and_failure_messages<br>+9 more | automated |
| from (analytics rebuild form) | field | — | form field 'from' posted to /analytics/data/rebuild/ | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_rebuild_refusal_and_failure_messages<br>+4 more | automated |
| to (analytics rebuild form) | field | — | form field 'to' posted to /analytics/data/rebuild/ | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_rebuild_refusal_and_failure_messages<br>+4 more | automated |
| analytics exclude | button | — | POST form → /analytics/data/exclusions/ (views_analytics.analytics_exclude) | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_exclude_confirms_and_reports_failure<br>+5 more | automated |
| member id (analytics exclude form) | field | — | form field 'member_id' posted to /analytics/data/exclusions/ | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_exclude_confirms_and_reports_failure<br>+3 more | automated |
| reason (analytics exclude form) | field | — | form field 'reason' posted to /analytics/data/exclusions/ | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_exclude_confirms_and_reports_failure<br>+3 more | automated |
| analytics include | button | — | POST form → /analytics/data/exclusions/<uuid:member_id>/remove/ (views_analytics.analytics_include) | django: `test_analytics.py` › AnalyticsPagesTest.test_data_page_rebuild_and_flags<br>django: `test_cases_reports.py` › AnalyticsCasesTest.test_include_confirms<br>+5 more | automated |
| analytics export | link | — | download/stream → /analytics/export/<slug:report>/ (views_analytics.analytics_export) | django: `test_analytics.py` › AnalyticsPagesTest.test_csv_export_streams_and_whitelists_params<br>django: `test_analytics.py` › AnalyticsPagesTest.test_csv_export_error_redirects<br>+2 more | automated |

#### Business reports — `console.business`

Route: control-panel /business/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_business.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| business revenue | link | — | page → /business/ (views_business.business_revenue) | django: `test_business.py` › BusinessViewsTest.test_empty_revenue_explains_release_one<br>django: `test_business.py` › BusinessViewsTest.test_revenue_forwards_validated_filters_and_renders_<br>+6 more | automated |
| business subscriptions | link | — | page → /business/subscriptions/ (views_business.business_subscriptions) | django: `test_business.py` › BusinessViewsTest.test_subscriptions_waterfall_uses_one_currency<br>django: `test_business.py` › test_subscriptions_waterfall_uses_one_currency<br>+1 more | partial |
| currency (business subscriptions) | menu | — | GET filter 'currency' | — | **GAP** |
| business conversion | link | — | page → /business/conversion/ (views_business.business_conversion) | django: `test_business.py` › BusinessViewsTest.test_conversion_page_calls_conversion_and_funnel<br>django: `test_business.py` › test_conversion_page_calls_conversion_and_funnel<br>+1 more | automated |
| business coins | link | — | page → /business/coins/ (views_business.business_coins) | django: `test_cases_reports.py` › BusinessCasesTest.test_coins_report<br>django: `test_cases_reports.py` › test_coins_report<br>+1 more | automated |
| business referrals | link | — | page → /business/referrals/ (views_business.business_referrals) | django: `test_cases_reports.py` › BusinessCasesTest.test_referrals_report<br>django: `test_cases_reports.py` › test_referrals_report<br>+1 more | automated |
| business markets | link | — | page → /business/markets/ (views_business.business_markets) | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › test_markets_shows_status_and_saves_gates<br>+1 more | automated |
| business market save | button | — | POST form → /business/markets/save/ (views_business.business_market_save) | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+7 more | automated |
| bengaluru (business market save form) | field | — | form field 'city_key' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| display name (business market save form) | field | — | form field 'display_name' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| country (business market save form) | field | — | form field 'country' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| INR (business market save form) | field | — | form field 'currency' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| launch order (business market save form) | field | — | form field 'launch_order' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| verified target (business market save form) | field | — | form field 'verified_target' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| max gender share (business market save form) | field | — | form field 'max_gender_share' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| plans kept target (business market save form) | field | — | form field 'plans_kept_target' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| approaching share (business market save form) | field | — | form field 'approaching_share' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| bangalore (business market save form) | field | — | form field 'aliases' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| notes (business market save form) | field | — | form field 'notes' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| active (business market save form) | toggle | — | form field 'active' posted to /business/markets/save/ | django: `test_business.py` › BusinessViewsTest.test_markets_shows_status_and_saves_gates<br>django: `test_business.py` › BusinessViewsTest.test_invalid_market_targets_do_not_call_api<br>+5 more | automated |
| business investor pack | link | — | download/stream → /business/investor-pack/ (views_business.business_investor_pack) | django: `test_business.py` › BusinessViewsTest.test_investor_pack_is_printable_and_flags_missing_sp<br>django: `test_business.py` › test_investor_pack_is_printable_and_flags_missing_spend | automated |
| business spend | link | — | page → /business/spend/ (views_business.business_spend) | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › test_spend_form_records_and_deletes<br>+2 more | automated |
| business spend save | button | — | POST form → /business/spend/save/ (views_business.business_spend_save) | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+8 more | automated |
| month (business spend save form) | field | — | form field 'month' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| channel (business spend save form) | menu | — | form field 'channel' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| market (business spend save form) | menu | — | form field 'market' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| INR (business spend save form) | field | — | form field 'currency' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| 25000.00 (business spend save form) | field | — | form field 'amount' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| attributed members (business spend save form) | field | — | form field 'attributed_members' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| note (business spend save form) | field | — | form field 'note' posted to /business/spend/save/ | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_business.py` › BusinessViewsTest.test_spend_rejects_bad_month_and_shows_api_errors<br>+4 more | automated |
| business spend delete | button | — | POST form → /business/spend/<str:spend_id>/delete/ (views_business.business_spend_delete) | django: `test_business.py` › BusinessViewsTest.test_spend_form_records_and_deletes<br>django: `test_cases_reports.py` › BusinessCasesTest.test_spend_delete_confirms_and_rejects_bad_ids<br>+5 more | automated |
| business csv | link | — | download/stream → /business/csv/<str:report>/ (views_business.business_csv) | django: `test_business.py` › BusinessViewsTest.test_csv_download_proxies_table_and_filters<br>django: `test_business.py` › test_csv_download_proxies_table_and_filters | automated |

#### Engagement admin — `console.engagement`

Route: control-panel /engagement/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`, `control-panel/control_panel/views_photo_themes.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| photo themes | link | — | page → /engagement/photo-themes/ (views_photo_themes.photo_themes) | django: `test_cases_engagement.py` › PhotoThemesTest.test_bff_server_error_is_502_with_banner<br>django: `test_paged_lists.py` › PhotoThemePagingTest.test_themes_page_in_display_order_with_status_fil<br>+8 more | partial |
| Search slug, title or prompt (photo themes) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_paged_lists.py` › test_themes_page_in_display_order_with_status_filter | automated |
| Status filter (photo themes) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_themes_page_in_display_order_with_status_filter | automated |
| Sort (sort_order, title, created_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_paged_lists.py` › test_themes_page_in_display_order_with_status_filter | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_paged_lists.py` › test_themes_page_in_display_order_with_status_filter | automated |
| Export Excel (photo themes) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| photo theme save | button | — | POST form → /engagement/photo-themes/save/ (views_photo_themes.photo_theme_save) | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+9 more | automated |
| rainy-day-plans (photo theme save form) | field | — | form field 'slug' posted to /engagement/photo-themes/save/ | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+5 more | automated |
| Rainy day plans (photo theme save form) | field | — | form field 'title' posted to /engagement/photo-themes/save/ | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+5 more | automated |
| status (photo theme save form) | menu | — | form field 'status' posted to /engagement/photo-themes/save/ | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+5 more | automated |
| sort order (photo theme save form) | field | — | form field 'sort_order' posted to /engagement/photo-themes/save/ | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+5 more | automated |
| What does a perfect rainy afternoon look like for you? (phot | field | — | form field 'prompt' posted to /engagement/photo-themes/save/ | django: `test_cases_engagement.py` › PhotoThemesTest.test_save_failure_is_reported<br>django: `test_photo_themes.py` › PhotoThemesViewTest.test_save_validates_before_calling_api<br>+5 more | automated |
| engagement prompts | link | — | page → /engagement/prompts/ (views.engagement_prompts) | django: `test_cases_engagement.py` › EngagementPromptsTest.test_prompts_page_shows_go_question_text<br>django: `test_cases_engagement.py` › EngagementPromptsTest.test_prompts_bff_failure_shows_banner<br>+10 more | partial |
| Search prompt text or category (engagement prompts) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Category filter (engagement prompts) | menu | — | choice filter 'category' sent to Go only when allowed by the ListSpec | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Status filter (engagement prompts) | menu | — | choice filter 'active' sent to Go only when allowed by the ListSpec | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Created from (UTC) filter (engagement prompts) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Created to (UTC) filter (engagement prompts) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Sort (created_at, active_date) | menu | — | sort + direction sent to Go as sort/order | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>django: `test_paged_lists.py` › test_prompts_page_with_filters_and_question_text | automated |
| Export Excel (engagement prompts) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| engagement prompt new | button | — | POST form → /engagement/prompts/new/ (views.engagement_prompt_new) | django: `test_cases_engagement.py` › EngagementPromptsTest.test_new_prompt_sends_question_text<br>django: `test_cases_engagement.py` › EngagementPromptsTest.test_new_prompt_validation_and_failure<br>+5 more | automated |
| engagement prompt edit | button | — | POST form → /engagement/prompts/<str:prompt_id>/edit/ (views.engagement_prompt_edit) | django: `test_cases_engagement.py` › EngagementPromptsTest.test_edit_prompt_prefills_and_sends_question_tex<br>django: `test_cases_engagement.py` › EngagementPromptsTest.test_edit_unknown_prompt_is_404_and_blank_text_r<br>+8 more | automated |
| engagement prompt activate | button | — | POST form → /engagement/prompts/<str:prompt_id>/activate/ (views.engagement_prompt_activate) | django: `test_cases_engagement.py` › EngagementPromptsTest.test_activate_sets_todays_prompt<br>django: `test_cases_engagement.py` › test_prompts_page_shows_go_question_text<br>+5 more | automated |
| engagement nudges | link | — | page → /engagement/nudges/ (views.engagement_nudges) | django: `test_cases_engagement.py` › EngagementNudgesTest.test_nudges_unavailable_is_not_shown_as_disabled<br>django: `test_paged_lists.py` › NudgePagingTest.test_nudges_page_filters_and_page_level_counts<br>+6 more | partial |
| Search nudge type (engagement nudges) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Nudge type filter (engagement nudges) | field | — | text filter 'nudge_type' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Status filter (engagement nudges) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Clicked filter (engagement nudges) | menu | — | choice filter 'clicked' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Recipient ID filter (engagement nudges) | field | — | text filter 'user_id' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Match ID filter (engagement nudges) | field | — | text filter 'match_id' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Sent from (UTC) filter (engagement nudges) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Sent to (UTC) filter (engagement nudges) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Sort (created_at, clicked_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_paged_lists.py` › test_nudges_page_filters_and_page_level_counts | automated |
| Export Excel (engagement nudges) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |

#### Moderation: rooms — `console.moderation_rooms`

Route: control-panel /moderation/rooms/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_rooms.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| rooms | link | — | page → /moderation/rooms/ (views_rooms.rooms) | django: `test_cases_moderation.py` › RoomsCasesTest.test_rooms_bff_server_error_is_502_with_banner<br>django: `test_rooms.py` › RoomsViewTest.test_lists_and_filters_rooms_escaped<br>+6 more | automated |
| room detail | link | — | page → /moderation/rooms/<uuid:room_id>/ (views_rooms.room_detail) | django: `test_cases_moderation.py` › RoomsCasesTest.test_rooms_bff_server_error_is_502_with_banner<br>django: `test_rooms.py` › RoomsViewTest.test_detail_shows_room_actions_and_people<br>+6 more | automated |
| room action | button | — | POST form → /moderation/rooms/<uuid:room_id>/actions/ (views_rooms.room_action) | django: `test_rooms.py` › RoomsViewTest.test_member_row_unmute_uses_the_action_flow<br>django: `test_rooms.py` › RoomsViewTest.test_actions_validate_before_calling_api<br>+12 more | automated |
| action (room action form) | menu | — | form field 'action' posted to /moderation/rooms/<uuid:room_id>/actions/ | django: `test_rooms.py` › RoomsViewTest.test_member_row_unmute_uses_the_action_flow<br>django: `test_rooms.py` › RoomsViewTest.test_actions_validate_before_calling_api<br>+8 more | automated |
| 00000000-0000-0000-0000-000000000000 (room action form) | field | — | form field 'target_user_id' posted to /moderation/rooms/<uuid:room_id>/actions/ | django: `test_rooms.py` › RoomsViewTest.test_member_row_unmute_uses_the_action_flow<br>django: `test_rooms.py` › RoomsViewTest.test_actions_validate_before_calling_api<br>+8 more | automated |
| duration (room action form) | menu | — | form field 'duration' posted to /moderation/rooms/<uuid:room_id>/actions/ | django: `test_rooms.py` › RoomsViewTest.test_member_row_unmute_uses_the_action_flow<br>django: `test_rooms.py` › RoomsViewTest.test_actions_validate_before_calling_api<br>+8 more | automated |
| reason (room action form) | field | — | form field 'reason' posted to /moderation/rooms/<uuid:room_id>/actions/ | django: `test_rooms.py` › RoomsViewTest.test_member_row_unmute_uses_the_action_flow<br>django: `test_rooms.py` › RoomsViewTest.test_actions_validate_before_calling_api<br>+8 more | automated |
| room role | button | — | POST form → /moderation/rooms/<uuid:room_id>/roles/ (views_rooms.room_role) | django: `test_rooms.py` › RoomsViewTest.test_appoint_and_revoke_moderators<br>django: `test_cases_moderation.py` › test_room_role_authz<br>+6 more | automated |
| member id (room role form) | field | — | form field 'member_id' posted to /moderation/rooms/<uuid:room_id>/roles/ | django: `test_rooms.py` › RoomsViewTest.test_appoint_and_revoke_moderators<br>django: `test_cases_moderation.py` › test_room_role_authz<br>+2 more | automated |
| role (room role form) | menu | — | form field 'role' posted to /moderation/rooms/<uuid:room_id>/roles/ | django: `test_rooms.py` › RoomsViewTest.test_appoint_and_revoke_moderators<br>django: `test_cases_moderation.py` › test_room_role_authz<br>+2 more | automated |

#### Moderation: group covers — `console.moderation_group_covers`

Route: control-panel /moderation/group-covers/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_group_covers.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| group covers | link | — | page → /moderation/group-covers/ (views_group_covers.group_covers) | django: `test_cases_moderation.py` › GroupCoverCasesTest.test_queue_and_content_upstream_5xx_is_502<br>django: `test_group_covers.py` › GroupCoversViewTest.test_pending_queue_lists_covers_with_actions<br>+13 more | automated |
| Search group name (group covers) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_paged_lists.py` › test_queue_pages_and_searches_without_overriding_go_order | automated |
| Queue filter (group covers) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_queue_pages_and_searches_without_overriding_go_order | automated |
| Uploaded from (UTC) filter (group covers) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_queue_pages_and_searches_without_overriding_go_order | automated |
| Uploaded to (UTC) filter (group covers) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_queue_pages_and_searches_without_overriding_go_order | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_paged_lists.py` › test_queue_pages_and_searches_without_overriding_go_order | automated |
| Export Excel (group covers) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_paged_lists.py` › test_export_lists_covers_with_go_keys | automated |
| group cover content | link | — | download/stream → /moderation/group-covers/<uuid:cover_id>/content/ (views_group_covers.group_cover_content) | django: `test_cases_moderation.py` › GroupCoverCasesTest.test_queue_and_content_upstream_5xx_is_502<br>django: `test_group_covers.py` › GroupCoversViewTest.test_content_proxy_streams_images_only<br>+4 more | automated |
| group cover decision | button | — | POST form → /moderation/group-covers/<uuid:cover_id>/decision/ (views_group_covers.group_cover_decision) | django: `test_group_covers.py` › GroupCoversViewTest.test_decisions_validate_before_calling_api<br>django: `test_group_covers.py` › GroupCoversViewTest.test_approve_and_reject<br>+9 more | automated |
| Shows a person who has not agreed to be in the group cover ( | field | — | form field 'reason' posted to /moderation/group-covers/<uuid:cover_id>/decision/ | django: `test_group_covers.py` › GroupCoversViewTest.test_decisions_validate_before_calling_api<br>django: `test_group_covers.py` › GroupCoversViewTest.test_approve_and_reject<br>+6 more | automated |

#### Moderation: blog — `console.moderation_blog`

Route: control-panel /moderation/blog/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_blog.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| blog reviews | link | — | page → /moderation/blog/ (views_blog.blog_reviews) | django: `test_blog.py` › BlogReviewsTest.test_evidence_and_appeals_are_escaped<br>django: `test_blog.py` › BlogReviewsTest.test_formatted_chapter_snapshot_renders_safely<br>+22 more | automated |
| Search report reason or description (blog reviews) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Queue filter (blog reviews) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Content filter (blog reviews) | menu | — | choice filter 'content_type' sent to Go only when allowed by the ListSpec | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Reported from (UTC) filter (blog reviews) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Reported to (UTC) filter (blog reviews) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Sort (review_due_at, created_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_blog.py` › test_invalid_mutation_does_not_reach_api<br>django: `test_paged_lists.py` › test_queue_pages_filters_and_keeps_metrics_and_decisions<br>+2 more | automated |
| Export Excel (blog reviews) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_paged_lists.py` › test_excel_export_has_every_case_but_no_reported_content | automated |
| blog decision | button | — | POST form → /moderation/blog/<uuid:case_id>/decision/ (views_blog.blog_decision) | django: `test_blog.py` › BlogReviewsTest.test_decision_uses_version_and_backend_error<br>django: `test_blog.py` › BlogReviewsTest.test_invalid_mutation_does_not_reach_api<br>+11 more | automated |
| decision (blog decision form) | menu | — | form field 'decision' posted to /moderation/blog/<uuid:case_id>/decision/ | django: `test_blog.py` › BlogReviewsTest.test_decision_uses_version_and_backend_error<br>django: `test_blog.py` › BlogReviewsTest.test_invalid_mutation_does_not_reach_api<br>+7 more | automated |
| note (blog decision form) | field | — | form field 'note' posted to /moderation/blog/<uuid:case_id>/decision/ | django: `test_blog.py` › BlogReviewsTest.test_decision_uses_version_and_backend_error<br>django: `test_blog.py` › BlogReviewsTest.test_invalid_mutation_does_not_reach_api<br>+7 more | automated |
| blog evidence | link | — | download/stream → /moderation/blog/<uuid:case_id>/photos/<uuid:photo_id>/ (views_blog.blog_evidence) | django: `test_blog.py` › BlogReviewsTest.test_evidence_never_cached_or_executed<br>django: `test_cases_moderation.py` › BlogCasesTest.test_reviews_upstream_5xx_is_502<br>+2 more | automated |

#### City pilot — `console.city_pilot`

Route: control-panel /city-pilot/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_city_pilot.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| city pilot | link | — | page → /city-pilot/ (views_city_pilot.city_pilot) | django: `test_cases_reports.py` › CityPilotCasesTest.test_page_bff_failure_shows_error<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_empty_pilot_shows_configuration<br>+7 more | automated |
| city pilot save | button | — | POST form → /city-pilot/save/ (views_city_pilot.city_pilot_save) | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+5 more | automated |
| city (city pilot save form) | field | — | form field 'city' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| country (city pilot save form) | field | — | form field 'country' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| owner (city pilot save form) | field | — | form field 'owner' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| safety owner (city pilot save form) | field | — | form field 'safety_owner' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| starts at (city pilot save form) | field | — | form field 'starts_at' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| closes at (city pilot save form) | field | — | form field 'closes_at' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| capacity (city pilot save form) | field | — | form field 'capacity' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| minimum pairs (city pilot save form) | field | — | form field 'minimum_pairs' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| conversation target (city pilot save form) | field | — | form field 'conversation_target' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| plan target (city pilot save form) | field | — | form field 'plan_target' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| date target (city pilot save form) | field | — | form field 'date_target' posted to /city-pilot/save/ | django: `test_city_pilot.py` › CityPilotViewsTest.test_save_forwards_utc_dates_and_declared_targets<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_invalid_dates_do_not_call_api<br>+3 more | automated |
| city pilot stage | button | — | POST form → /city-pilot/<uuid:pilot_id>/stage/ (views_city_pilot.city_pilot_stage) | django: `test_cases_reports.py` › CityPilotCasesTest.test_stage_success<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_failed_gate_error_is_displayed<br>+8 more | automated |
| status (city pilot stage form) | menu | — | form field 'status' posted to /city-pilot/<uuid:pilot_id>/stage/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_stage_success<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_failed_gate_error_is_displayed<br>+4 more | automated |
| note (city pilot stage form) | field | — | form field 'note' posted to /city-pilot/<uuid:pilot_id>/stage/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_stage_success<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_failed_gate_error_is_displayed<br>+4 more | automated |
| safety ready (city pilot stage form) | toggle | — | form field 'safety_ready' posted to /city-pilot/<uuid:pilot_id>/stage/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_stage_success<br>django: `test_city_pilot.py` › CityPilotViewsTest.test_failed_gate_error_is_displayed<br>+4 more | automated |
| city pilot experience create | button | — | POST form → /city-pilot/<uuid:pilot_id>/experiences/ (views_city_pilot.city_pilot_experience_create) | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+3 more | automated |
| title (city pilot experience create form) | field | — | form field 'title' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| host (city pilot experience create form) | field | — | form field 'host' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| summary (city pilot experience create form) | field | — | form field 'summary' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| venue (city pilot experience create form) | field | — | form field 'venue' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| safety contact (city pilot experience create form) | field | — | form field 'safety_contact' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| accessibility (city pilot experience create form) | field | — | form field 'accessibility' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| starts at (city pilot experience create form) | field | — | form field 'starts_at' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| ends at (city pilot experience create form) | field | — | form field 'ends_at' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| registration closes at (city pilot experience create form) | field | — | form field 'registration_closes_at' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| capacity (city pilot experience create form) | field | — | form field 'capacity' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| host vetted (city pilot experience create form) | toggle | — | form field 'host_vetted' posted to /city-pilot/<uuid:pilot_id>/experiences/ | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_create_forwards_utc_times<br>django: `test_cases_reports.py` › test_experience_create_forwards_utc_times<br>+1 more | automated |
| city pilot experience cancel | button | — | POST form → /city-pilot/<uuid:pilot_id>/experiences/<uuid:event_id>/cancel/ (views_city_pilot.city_pilot_experience_cancel) | django: `test_cases_reports.py` › CityPilotCasesTest.test_experience_cancel<br>django: `test_cases_reports.py` › test_experience_cancel<br>+3 more | automated |

#### Auth — `console.login`

Route: control-panel /login/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| operator login | button | — | POST form → /login/ (views.operator_login) | django: `test_cases_platform.py` › OperatorLoginTest.test_login_signs_in_and_honours_safe_next<br>django: `test_views.py` › OperatorAuthenticationTest.test_login_stores_bff_session_after_admin_p<br>+17 more | automated |

#### Auth — `console.logout`

Route: control-panel /logout/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| operator logout | button | — | POST form → /logout/ (views.operator_logout) | django: `test_cases_platform.py` › OperatorLogoutTest.test_logout_revokes_and_flushes<br>django: `test_views.py` › OperatorAuthenticationTest.test_logout_flushes_operator_session<br>+5 more | automated |

#### Dashboard — `console.dashboard`

Route: control-panel // · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| dashboard | link | — | page → / (views.dashboard) | django: `test_analytics.py` › DashboardDurableKpiTest.test_dashboard_uses_durable_snapshot_kpis<br>django: `test_analytics.py` › DashboardDurableKpiTest.test_dashboard_falls_back_to_live_activity_wit<br>+11 more | partial |
| Member UUID (dashboard) | field | — | GET filter 'user_id' | — | **GAP** |
| refresh (dashboard) | menu | — | GET filter 'refresh' | — | **GAP** |

#### Verification queue — `console.verifications`

Route: control-panel /verifications/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| verification queue | link | — | page → /verifications/ (views.verification_queue) | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › VerificationsTest.test_queue_renders_with_dates_and_filters<br>+9 more | partial |
| Search member ID or username (verification queue) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| Status filter (verification queue) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| From (UTC) filter (verification queue) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| To (UTC) filter (verification queue) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| Sort (submitted_at, updated_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_moderation.py` › VerifiedStatusTest.test_verified_rows_show_as_verified_and_the_filter_<br>django: `test_cases_moderation.py` › test_verified_rows_show_as_verified_and_the_filter_uses_gos_value<br>+1 more | automated |
| Export Excel (verification queue) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| approve verification | button | — | POST form → /verifications/<str:user_id>/approve/ (views.approve_verification) | django: `test_cases_moderation.py` › VerificationsTest.test_approve<br>django: `test_views.py` › DashboardViewsTest.test_approve_redirects_with_success<br>+6 more | automated |
| reject verification | button | — | POST form → /verifications/<str:user_id>/reject/ (views.reject_verification) | django: `test_cases_moderation.py` › VerificationsTest.test_reject<br>django: `test_views.py` › DashboardViewsTest.test_reject_requires_reason<br>+7 more | automated |
| Rejection reason… (reject verification form) | field | — | form field 'rejection_reason' posted to /verifications/<str:user_id>/reject/ | django: `test_cases_moderation.py` › VerificationsTest.test_reject<br>django: `test_views.py` › DashboardViewsTest.test_reject_requires_reason<br>+4 more | automated |

#### Activity feed — `console.activities`

Route: control-panel /activities/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| activity feed | link | — | page → /activities/ (views.activity_feed) | django: `test_cases_platform.py` › LogPagesTest.test_activity_feed_bounds_limit_and_shows_failure<br>django: `test_views.py` › DashboardViewsTest.test_activity_feed_filters_latest_events<br>+3 more | automated |
| login, match, report… (activity feed) | field | — | GET filter 'action' | django: `test_views.py` › test_activity_feed_filters_latest_events | automated |
| UUID (activity feed) | field | — | GET filter 'user_id' | django: `test_views.py` › test_activity_feed_filters_latest_events | automated |
| status (activity feed) | menu | — | GET filter 'status' | django: `test_views.py` › test_activity_feed_filters_latest_events | automated |
| limit (activity feed) | field | — | GET filter 'limit' | django: `test_views.py` › test_activity_feed_filters_latest_events | automated |

#### Audit log — `console.audit`

Route: control-panel /audit/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| audit log | link | — | page → /audit/ (views.audit_log) | django: `test_cases_platform.py` › LogPagesTest.test_audit_log_failure_banner<br>django: `test_views.py` › DashboardViewsTest.test_operator_audit_page_forwards_filters<br>+4 more | partial |
| Search event or resource type (audit log) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Event type filter (audit log) | field | — | text filter 'event_type' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Actor ID filter (audit log) | field | — | text filter 'actor_user_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Subject member ID filter (audit log) | field | — | text filter 'subject_user_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Resource type filter (audit log) | field | — | text filter 'resource_type' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| From (UTC) filter (audit log) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| To (UTC) filter (audit log) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_views.py` › test_operator_audit_page_forwards_filters | automated |
| Export Excel (audit log) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |

#### Domain events — `console.events`

Route: control-panel /events/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| domain events | link | — | page → /events/ (views.domain_events) | django: `test_cases_platform.py` › LogPagesTest.test_domain_events_failure_banner<br>django: `test_views.py` › DashboardViewsTest.test_domain_event_page_forwards_filters_and_renders<br>+4 more | partial |
| Search event, aggregate or producer (domain events) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Event filter (domain events) | field | — | text filter 'event_name' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Aggregate type filter (domain events) | field | — | text filter 'aggregate_type' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Aggregate ID filter (domain events) | field | — | text filter 'aggregate_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Producer filter (domain events) | field | — | text filter 'producer' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Correlation ID filter (domain events) | field | — | text filter 'correlation_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Subject member ID filter (domain events) | field | — | text filter 'subject_user_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Actor ID filter (domain events) | field | — | text filter 'actor_user_id' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| From (UTC) filter (domain events) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| To (UTC) filter (domain events) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_views.py` › test_domain_event_page_forwards_filters_and_renders_pipeline_health | automated |
| Export Excel (domain events) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |

#### Client errors — `console.client_errors`

Route: control-panel /client-errors/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_client_errors.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| client errors | link | — | page → /client-errors/ (views_client_errors.client_errors) | django: `test_cases_platform.py` › ClientErrorStatusAuthzTest.test_list_and_detail_upstream_5xx_is_502<br>django: `test_client_errors.py` › ClientErrorsViewTest.test_list_renders_issues_summary_and_privacy_note<br>+13 more | automated |
| status (client errors) | menu | — | GET filter 'status' | django: `test_client_errors.py` › test_filters_and_pagination_pass_through<br>django: `test_client_errors.py` › test_unknown_filters_fall_back_to_defaults | automated |
| platform (client errors) | menu | — | GET filter 'platform' | django: `test_client_errors.py` › test_filters_and_pagination_pass_through<br>django: `test_client_errors.py` › test_unknown_filters_fall_back_to_defaults | automated |
| e.g. 1.4.2 (client errors) | field | — | GET filter 'version' | django: `test_client_errors.py` › test_filters_and_pagination_pass_through<br>django: `test_client_errors.py` › test_unknown_filters_fall_back_to_defaults | automated |
| fatal (client errors) | menu | — | GET filter 'fatal' | django: `test_client_errors.py` › test_filters_and_pagination_pass_through<br>django: `test_client_errors.py` › test_unknown_filters_fall_back_to_defaults | automated |
| sort (client errors) | menu | — | GET filter 'sort' | django: `test_client_errors.py` › test_filters_and_pagination_pass_through<br>django: `test_client_errors.py` › test_unknown_filters_fall_back_to_defaults | automated |
| client error detail | link | — | page → /client-errors/<uuid:issue_id>/ (views_client_errors.client_error_detail) | django: `test_cases_platform.py` › ClientErrorStatusAuthzTest.test_list_and_detail_upstream_5xx_is_502<br>django: `test_client_errors.py` › ClientErrorsViewTest.test_detail_renders_and_escapes_report_text<br>+9 more | automated |
| client error status | button | — | POST form → /client-errors/<uuid:issue_id>/status/ (views_client_errors.client_error_status) | django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_calls_client_and_redirects<br>django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_validates_before_calling_api<br>+12 more | automated |
| e.g. 1.4.3 (client error status form) | field | — | form field 'resolved_in_version' posted to /client-errors/<uuid:issue_id>/status/ | django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_calls_client_and_redirects<br>django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_validates_before_calling_api<br>+7 more | automated |
| Fixed by the image cache patch (client error status form) | field | — | form field 'note' posted to /client-errors/<uuid:issue_id>/status/ | django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_calls_client_and_redirects<br>django: `test_client_errors.py` › ClientErrorsViewTest.test_status_post_validates_before_calling_api<br>+7 more | automated |

#### Appeals — `console.appeals`

Route: control-panel /appeals/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| appeal queue | link | — | page → /appeals/ (views.appeal_queue) | django: `test_cases_moderation.py` › AppealsTest.test_queue_renders_rows_and_deadline<br>django: `test_views.py` › DashboardViewsTest.test_appeal_queue_renders<br>+4 more | partial |
| Search reason (appeal queue) | field | — | free-text search sent to Go as q (escaped in page links) | — | **GAP** |
| Status filter (appeal queue) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | — | **GAP** |
| From (UTC) filter (appeal queue) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | — | **GAP** |
| To (UTC) filter (appeal queue) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | — | **GAP** |
| Sort (created_at, sla_deadline_at) | menu | — | sort + direction sent to Go as sort/order | — | **GAP** |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | — | **GAP** |
| Export Excel (appeal queue) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| action appeal | button | — | POST form → /appeals/<str:appeal_id>/action/ (views.action_appeal) | django: `test_cases_moderation.py` › AppealsTest.test_action_appeal<br>django: `test_views.py` › DashboardViewsTest.test_action_appeal_redirects<br>+6 more | automated |
| status (action appeal form) | menu | — | form field 'status' posted to /appeals/<str:appeal_id>/action/ | django: `test_cases_moderation.py` › AppealsTest.test_action_appeal<br>django: `test_views.py` › DashboardViewsTest.test_action_appeal_redirects<br>+4 more | automated |
| Resolution note… (action appeal form) | field | — | form field 'resolution_reason' posted to /appeals/<str:appeal_id>/action/ | django: `test_cases_moderation.py` › AppealsTest.test_action_appeal<br>django: `test_views.py` › DashboardViewsTest.test_action_appeal_redirects<br>+4 more | automated |

#### Support desk — `console.support`

Route: control-panel /support/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views_support.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| support queue | link | — | page → /support/ (views_support.support_queue) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_queue_detail_dashboard_and_canned<br>django: `test_support.py` › SupportQueueViewTest.test_queue_renders_filters_badges_and_controls<br>+13 more | automated |
| Reference, subject, username, email (support queue) | field | — | GET filter 'q' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| status (support queue) | menu | — | GET filter 'status' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| category (support queue) | menu | — | GET filter 'category' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| priority (support queue) | menu | — | GET filter 'priority' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| team (support queue) | menu | — | GET filter 'team' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| channel (support queue) | menu | — | GET filter 'channel' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| assignee (support queue) | menu | — | GET filter 'assignee' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| sla (support queue) | menu | — | GET filter 'sla' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| sort (support queue) | menu | — | GET filter 'sort' | django: `test_support.py` › test_queue_renders_filters_badges_and_controls<br>django: `test_support.py` › test_invalid_filters_fall_back_to_defaults<br>+1 more | automated |
| support export | link | — | download/stream → /support/export/ (views_support.support_export) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_attachment_and_export_go_5xx_is_5<br>django: `test_support.py` › SupportExportTest.test_csv_export_streams_with_filters<br>+6 more | automated |
| support bulk | button | — | POST form → /support/bulk/ (views_support.support_bulk) | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+10 more | automated |
| action (support bulk form) | menu | — | form field 'action' posted to /support/bulk/ | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+4 more | automated |
| assign value (support bulk form) | menu | — | form field 'assign_value' posted to /support/bulk/ | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+4 more | automated |
| status value (support bulk form) | menu | — | form field 'status_value' posted to /support/bulk/ | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+4 more | automated |
| priority value (support bulk form) | menu | — | form field 'priority_value' posted to /support/bulk/ | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+4 more | automated |
| Select {{ ticket.reference\|default:ticket.id }} (support bu | toggle | — | form field 'ticket_ids' posted to /support/bulk/ | django: `test_support.py` › SupportQueueViewTest.test_bulk_actions_validate_and_forward<br>django: `test_cases_support.py` › test_bulk_authz<br>+4 more | automated |
| support dashboard | link | — | page → /support/dashboard/ (views_support.support_dashboard) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_queue_detail_dashboard_and_canned<br>django: `test_support.py` › SupportDashboardTest.test_dashboard_renders_kpis_charts_and_safety<br>+8 more | partial |
| days (support dashboard) | menu | — | GET filter 'days' | — | **GAP** |
| support canned responses | link | — | page → /support/canned/ (views_support.support_canned_responses) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_queue_detail_dashboard_and_canned<br>django: `test_support.py` › SupportCannedResponsesTest.test_list_includes_inactive_and_placeholder<br>+4 more | automated |
| support canned save | button | — | POST form → /support/canned/save/ (views_support.support_canned_save) | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_save_authz<br>+9 more | automated |
| title (support canned save form) | field | — | form field 'title' posted to /support/canned/save/ | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_save_authz<br>+3 more | automated |
| category (support canned save form) | menu | — | form field 'category' posted to /support/canned/save/ | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_save_authz<br>+3 more | automated |
| body (support canned save form) | field | — | form field 'body' posted to /support/canned/save/ | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_save_authz<br>+3 more | automated |
| is active (support canned save form) | toggle | — | form field 'is_active' posted to /support/canned/save/ | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_save_authz<br>+3 more | automated |
| support canned deactivate | button | — | POST form → /support/canned/<uuid:response_id>/deactivate/ (views_support.support_canned_deactivate) | django: `test_support.py` › SupportCannedResponsesTest.test_create_edit_deactivate<br>django: `test_cases_support.py` › test_canned_deactivate_authz<br>+7 more | automated |
| support attachment | link | — | download/stream → /support/attachments/<uuid:attachment_id>/ (views_support.support_attachment) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_attachment_and_export_go_5xx_is_5<br>django: `test_support.py` › SupportQueueViewTest.test_analyst_sees_no_mutation_controls_and_posts_<br>+8 more | automated |
| support ticket detail | link | — | page → /support/tickets/<uuid:ticket_id>/ (views_support.support_ticket_detail) | django: `test_cases_support.py` › SupportPagesUpstreamFailureTest.test_queue_detail_dashboard_and_canned<br>django: `test_support.py` › SupportTicketDetailTest.test_detail_renders_thread_notes_events_and_co<br>+13 more | automated |
| support ticket reply | button | — | POST form → /support/tickets/<uuid:ticket_id>/reply/ (views_support.support_ticket_reply) | django: `test_support.py` › SupportTicketDetailTest.test_reply_posts_payload<br>django: `test_support.py` › SupportTicketDetailTest.test_reply_validation_keeps_draft<br>+13 more | automated |
| visibility (support ticket reply form) | menu | — | form field 'visibility' posted to /support/tickets/<uuid:ticket_id>/reply/ | django: `test_support.py` › SupportTicketDetailTest.test_reply_posts_payload<br>django: `test_support.py` › SupportTicketDetailTest.test_reply_validation_keeps_draft<br>+7 more | automated |
| Write to the requester, or add a note for other agents (supp | field | — | form field 'body' posted to /support/tickets/<uuid:ticket_id>/reply/ | django: `test_support.py` › SupportTicketDetailTest.test_reply_posts_payload<br>django: `test_support.py` › SupportTicketDetailTest.test_reply_validation_keeps_draft<br>+7 more | automated |
| status (support ticket reply form) | menu | — | form field 'status' posted to /support/tickets/<uuid:ticket_id>/reply/ | django: `test_support.py` › SupportTicketDetailTest.test_reply_posts_payload<br>django: `test_support.py` › SupportTicketDetailTest.test_reply_validation_keeps_draft<br>+7 more | automated |
| support ticket update | button | — | POST form → /support/tickets/<uuid:ticket_id>/update/ (views_support.support_ticket_update) | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+10 more | automated |
| status (support ticket update form) | menu | — | form field 'status' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| priority (support ticket update form) | menu | — | form field 'priority' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| category (support ticket update form) | menu | — | form field 'category' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| team (support ticket update form) | menu | — | form field 'team' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| assignee id (support ticket update form) | menu | — | form field 'assignee_id' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| refund, android (support ticket update form) | field | — | form field 'tags' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| Leave empty to unlink (support ticket update form) | field | — | form field 'client_error_issue_id' posted to /support/tickets/<uuid:ticket_id>/update/ | django: `test_support.py` › SupportTicketDetailTest.test_update_sends_only_changed_fields<br>django: `test_cases_support.py` › test_update_authz<br>+4 more | automated |
| support ticket claim | button | — | POST form → /support/tickets/<uuid:ticket_id>/claim/ (views_support.support_ticket_claim) | django: `test_support.py` › SupportQueueViewTest.test_go_403_on_post_is_explained<br>django: `test_support.py` › SupportQueueViewTest.test_claim_from_queue_returns_to_filtered_queue<br>+15 more | automated |
| support ticket merge | button | — | POST form → /support/tickets/<uuid:ticket_id>/merge/ (views_support.support_ticket_merge) | django: `test_cases_support.py` › SupportRoleGateTest.test_merge_needs_confirmation_and_reports_failure<br>django: `test_support.py` › SupportTicketDetailTest.test_merge_by_reference_and_id<br>+6 more | automated |
| CN-2026-000123 (support ticket merge form) | field | — | form field 'into' posted to /support/tickets/<uuid:ticket_id>/merge/ | django: `test_cases_support.py` › SupportRoleGateTest.test_merge_needs_confirmation_and_reports_failure<br>django: `test_support.py` › SupportTicketDetailTest.test_merge_by_reference_and_id<br>+4 more | automated |
| confirm (support ticket merge form) | toggle | — | form field 'confirm' posted to /support/tickets/<uuid:ticket_id>/merge/ | django: `test_cases_support.py` › SupportRoleGateTest.test_merge_needs_confirmation_and_reports_failure<br>django: `test_support.py` › SupportTicketDetailTest.test_merge_by_reference_and_id<br>+4 more | automated |
| support canned preview | button | — | POST form → /support/tickets/<uuid:ticket_id>/canned/<uuid:response_id>/preview/ (views_support.support_canned_preview) | django: `test_cases_support.py` › SupportCannedPreviewAuthzTest.test_preview_returns_rendered_body<br>django: `test_support.py` › SupportTicketDetailTest.test_canned_preview_proxy<br>+5 more | automated |

#### Growth governance — `console.growth`

Route: control-panel /growth/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| growth governance | link | — | page → /growth/governance/ (views.growth_governance) | django: `test_cases_platform.py` › GrowthGovernanceTest.test_register_renders_and_failure_banner<br>django: `test_paged_lists.py` › GrowthFraudPagingTest.test_fraud_signals_are_listed_and_paged<br>+6 more | partial |
| Search signal or action mode (growth governance) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Review status filter (growth governance) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Signal filter (growth governance) | menu | — | choice filter 'signal_type' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Member ID filter (growth governance) | field | — | text filter 'member' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| From (UTC) filter (growth governance) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| To (UTC) filter (growth governance) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Sort (confidence, created_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_paged_lists.py` › test_fraud_signals_are_listed_and_paged | automated |
| Export Excel (growth governance) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |

#### Moderation: reports — `console.moderation_reports`

Route: control-panel /moderation/reports/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| moderation reports | link | — | page → /moderation/reports/ (views.moderation_reports) | django: `test_cases_moderation.py` › ModerationReportsTest.test_reports_render_with_dates_and_filters<br>django: `test_cases_moderation.py` › ModerationReportsTest.test_reports_bff_failure_shows_banner<br>+5 more | partial |
| Search description or reason (moderation reports) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| Status filter (moderation reports) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| Reason filter (moderation reports) | field | — | text filter 'category' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| From (UTC) filter (moderation reports) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| To (UTC) filter (moderation reports) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_moderation.py` › test_reports_render_with_dates_and_filters | automated |
| Export Excel (moderation reports) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| action report | button | — | POST form → /moderation/reports/<str:report_id>/action/ (views.action_report) | django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_sends_the_status_go_requires<br>django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_validation_and_failure<br>+7 more | automated |
| action (action report form) | menu | — | form field 'action' posted to /moderation/reports/<str:report_id>/action/ | django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_sends_the_status_go_requires<br>django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_validation_and_failure<br>+4 more | automated |
| Optional notes… (action report form) | field | — | form field 'reason' posted to /moderation/reports/<str:report_id>/action/ | django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_sends_the_status_go_requires<br>django: `test_cases_moderation.py` › ModerationReportsTest.test_action_report_validation_and_failure<br>+4 more | automated |

#### Moderation: media — `console.moderation_media`

Route: control-panel /moderation/media/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| media moderation queue | link | — | page → /moderation/media/ (views.media_moderation_queue) | django: `test_cases_moderation.py` › MediaModerationTest.test_queue_filters_and_failure<br>django: `test_views.py` › DashboardViewsTest.test_media_moderation_queue_and_content_proxy<br>+5 more | partial |
| Search username (media moderation queue) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_moderation.py` › test_queue_filters_and_failure | automated |
| Queue filter (media moderation queue) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_queue_filters_and_failure | automated |
| From (UTC) filter (media moderation queue) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_queue_filters_and_failure | automated |
| To (UTC) filter (media moderation queue) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_moderation.py` › test_queue_filters_and_failure | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_moderation.py` › test_queue_filters_and_failure | automated |
| Export Excel (media moderation queue) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| media moderation content | link | — | download/stream → /moderation/media/<str:photo_id>/content/ (views.media_moderation_content) | django: `test_cases_moderation.py` › MediaModerationTest.test_content_failures_are_plain_text_and_never_500<br>django: `test_views.py` › DashboardViewsTest.test_media_moderation_queue_and_content_proxy<br>+3 more | automated |
| media moderation decision | button | — | POST form → /moderation/media/<str:photo_id>/decision/ (views.media_moderation_decision) | django: `test_cases_moderation.py` › MediaModerationTest.test_decision_approve_and_reject<br>django: `test_views.py` › DashboardViewsTest.test_media_rejection_requires_reason<br>+4 more | automated |
| Reason required when rejecting (media moderation decision fo | field | — | form field 'reason' posted to /moderation/media/<str:photo_id>/decision/ | django: `test_cases_moderation.py` › MediaModerationTest.test_decision_approve_and_reject<br>django: `test_views.py` › DashboardViewsTest.test_media_rejection_requires_reason<br>+2 more | automated |

#### Gift catalog — `console.catalog`

Route: control-panel /catalog/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| catalog list | link | — | page → /catalog/ (views.catalog_list) | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_renders_gifts_and_forwards_filters<br>django: `test_cases_catalog.py` › CatalogListTest.test_catalog_bff_failure_shows_banner<br>+23 more | automated |
| Search gift name or ID (catalog list) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Category filter (catalog list) | menu | — | choice filter 'category' sent to Go only when allowed by the ListSpec | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Rarity tier filter (catalog list) | menu | — | choice filter 'tier' sent to Go only when allowed by the ListSpec | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Status filter (catalog list) | menu | — | choice filter 'active' sent to Go only when allowed by the ListSpec | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Sort (sort_order, name, price_coins, created_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_catalog.py` › CatalogListTest.test_catalog_pages_past_the_first_fifty<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+4 more | automated |
| Export Excel (catalog list) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_paged_lists.py` › test_excel_export_holds_every_matching_gift | automated |
| catalog new | button | — | POST form → /catalog/new/ (views.catalog_new) | django: `test_cases_catalog.py` › CatalogNewTest.test_form_offers_every_tier_and_category<br>django: `test_cases_catalog.py` › CatalogNewTest.test_create_forwards_gift_and_confirms<br>+7 more | automated |
| catalog edit | button | — | POST form → /catalog/<str:gift_id>/edit/ (views.catalog_edit) | django: `test_cases_catalog.py` › CatalogEditTest.test_edit_prefills_and_puts_changes<br>django: `test_cases_catalog.py` › CatalogEditTest.test_edit_finds_gifts_past_the_first_page<br>+13 more | automated |
| catalog toggle | button | — | POST form → /catalog/<str:gift_id>/toggle/ (views.catalog_toggle) | django: `test_cases_catalog.py` › CatalogToggleDeleteTest.test_toggle_activates_and_deactivates<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+5 more | automated |
| catalog delete | button | — | POST form → /catalog/<str:gift_id>/delete/ (views.catalog_delete) | django: `test_cases_catalog.py` › CatalogToggleDeleteTest.test_delete<br>django: `test_cases_catalog.py` › test_catalog_renders_gifts_and_forwards_filters<br>+6 more | automated |

#### Members — `console.users`

Route: control-panel /users/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| user list | link | — | page → /users/ (views.user_list) | django: `test_cases_users.py` › UserListAndDetailTest.test_user_list_renders_rows_and_escapes_member_t<br>django: `test_cases_users.py` › UserListAndDetailTest.test_user_list_bff_failure_shows_banner_not_500<br>+24 more | automated |
| Search name, phone or ID (user list) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_users.py` › test_create_forwards_profile_and_confirms<br>django: `test_listing.py` › test_page_size_and_page_reach_go_as_limit_and_offset<br>+5 more | automated |
| Status filter (user list) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_users.py` › test_create_forwards_profile_and_confirms<br>django: `test_listing.py` › test_page_size_and_page_reach_go_as_limit_and_offset<br>+5 more | automated |
| Gender filter (user list) | menu | — | choice filter 'gender' sent to Go only when allowed by the ListSpec | django: `test_cases_users.py` › test_create_forwards_profile_and_confirms<br>django: `test_listing.py` › test_page_size_and_page_reach_go_as_limit_and_offset<br>+5 more | automated |
| Verified filter (user list) | menu | — | choice filter 'verified' sent to Go only when allowed by the ListSpec | django: `test_cases_users.py` › test_create_forwards_profile_and_confirms<br>django: `test_listing.py` › test_page_size_and_page_reach_go_as_limit_and_offset<br>+5 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_users.py` › test_create_forwards_profile_and_confirms<br>django: `test_listing.py` › test_page_size_and_page_reach_go_as_limit_and_offset<br>+5 more | automated |
| Export Excel (user list) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_listing.py` › test_export_pages_through_go_and_returns_a_workbook<br>django: `test_listing.py` › test_export_failure_is_a_clear_error | automated |
| user create | button | — | POST form → /users/new/ (views.user_create) | django: `test_cases_users.py` › UserCreateTest.test_create_forwards_profile_and_confirms<br>django: `test_cases_users.py` › UserCreateTest.test_create_failure_keeps_the_form<br>+10 more | automated |
| user detail | link | — | page → /users/<str:user_id>/ (views.user_detail) | django: `test_user_detail.py` › UserDetailStatusTest.test_known_member_renders_200<br>django: `test_user_detail.py` › UserDetailStatusTest.test_unknown_member_is_404_not_200<br>+21 more | automated |
| user edit | button | — | POST form → /users/<str:user_id>/edit/ (views.user_edit) | django: `test_cases_users.py` › UserEditTest.test_edit_prefills_and_forwards_changes<br>django: `test_cases_users.py` › UserEditTest.test_edit_unknown_member_is_404<br>+12 more | automated |
| user delete | button | — | POST form → /users/<str:user_id>/delete/ (views.user_delete) | django: `test_cases_users.py` › UserLifecycleActionsTest.test_delete_schedules_erasure<br>django: `test_cases_users.py` › test_delete_schedules_erasure<br>+3 more | automated |
| user suspend | button | — | POST form → /users/<str:user_id>/suspend/ (views.user_suspend) | django: `test_bff_errors.py` › BFFErrorBannerTest.test_failed_action_banner_hides_sqlstate<br>django: `test_cases_users.py` › UserLifecycleActionsTest.test_suspend_forwards_reason_and_days<br>+5 more | automated |
| Reason for suspension… (user suspend form) | field | — | form field 'reason' posted to /users/<str:user_id>/suspend/ | django: `test_bff_errors.py` › BFFErrorBannerTest.test_failed_action_banner_hides_sqlstate<br>django: `test_cases_users.py` › UserLifecycleActionsTest.test_suspend_forwards_reason_and_days<br>+3 more | automated |
| 0 (user suspend form) | field | — | form field 'days' posted to /users/<str:user_id>/suspend/ | django: `test_bff_errors.py` › BFFErrorBannerTest.test_failed_action_banner_hides_sqlstate<br>django: `test_cases_users.py` › UserLifecycleActionsTest.test_suspend_forwards_reason_and_days<br>+3 more | automated |
| user unsuspend | button | — | POST form → /users/<str:user_id>/unsuspend/ (views.user_unsuspend) | django: `test_cases_users.py` › UserLifecycleActionsTest.test_unsuspend<br>django: `test_cases_users.py` › test_unsuspend<br>+3 more | automated |
| user ban | button | — | POST form → /users/<str:user_id>/ban/ (views.user_ban) | django: `test_cases_users.py` › UserLifecycleActionsTest.test_ban_requires_reason<br>django: `test_cases_users.py` › test_ban_requires_reason<br>+8 more | automated |
| Reason for ban… (user ban form) | field | — | form field 'reason' posted to /users/<str:user_id>/ban/ | django: `test_cases_users.py` › UserLifecycleActionsTest.test_ban_requires_reason<br>django: `test_cases_users.py` › test_ban_requires_reason<br>+3 more | automated |
| user unban | button | — | POST form → /users/<str:user_id>/unban/ (views.user_unban) | django: `test_cases_users.py` › UserLifecycleActionsTest.test_unban<br>django: `test_cases_users.py` › test_unban<br>+3 more | automated |
| user force verify | button | — | POST form → /users/<str:user_id>/verify/ (views.user_force_verify) | django: `test_cases_users.py` › UserLifecycleActionsTest.test_force_verify<br>django: `test_cases_users.py` › test_force_verify<br>+3 more | automated |
| user grant coins | button | — | POST form → /users/<str:user_id>/grant-coins/ (views.user_grant_coins) | django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_uses_the_audited_admin_route<br>django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_validates_amount_and_reports_failures<br>+5 more | automated |
| 50 (user grant coins form) | field | — | form field 'coins' posted to /users/<str:user_id>/grant-coins/ | django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_uses_the_audited_admin_route<br>django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_validates_amount_and_reports_failures<br>+3 more | automated |
| compensation, promo, test… (user grant coins form) | field | — | form field 'reason' posted to /users/<str:user_id>/grant-coins/ | django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_uses_the_audited_admin_route<br>django: `test_cases_users.py` › UserGrantCoinsTest.test_grant_validates_amount_and_reports_failures<br>+3 more | automated |

#### Feature flags — `console.config`

Route: control-panel /config/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| config flags | link | — | page → /config/flags/ (views.config_flags) | django: `test_cases_platform.py` › FeatureFlagsTest.test_flags_render<br>django: `test_cases_platform.py` › test_flags_render<br>+2 more | automated |
| config flag toggle | button | — | POST form → /config/flags/<str:key>/toggle/ (views.config_flag_toggle) | django: `test_cases_platform.py` › FeatureFlagsTest.test_toggle_records_the_operator<br>django: `test_cases_platform.py` › test_flags_render<br>+4 more | automated |

#### Progression — `console.progression`

Route: control-panel /progression/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| progression admin | link | — | page → /progression/ (views.progression_admin) | django: `test_cases_progression.py` › ProgressionPageTest.test_bff_failures_show_banners<br>django: `test_paged_lists.py` › ProgressionFraudPagingTest.test_xp_fraud_queue_pages_with_filters<br>+9 more | partial |
| Search username or rule (progression admin) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Case status filter (progression admin) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Severity filter (progression admin) | menu | — | choice filter 'severity' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Rule filter (progression admin) | field | — | text filter 'rule_code' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Member ID filter (progression admin) | field | — | text filter 'user_id' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| From (UTC) filter (progression admin) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| To (UTC) filter (progression admin) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Sort (created_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>django: `test_paged_lists.py` › test_xp_fraud_queue_pages_with_filters | automated |
| Export Excel (progression admin) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| progression policy update | button | — | POST form → /progression/policies/<str:source>/ (views.progression_policy_update) | django: `test_cases_progression.py` › ProgressionActionsTest.test_policy_update_forwards_whole_numbers<br>django: `test_cases_progression.py` › test_policy_update_forwards_whole_numbers<br>+3 more | automated |
| progression experiment update | button | — | POST form → /progression/experiments/<str:key>/ (views.progression_experiment_update) | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+5 more | automated |
| status (progression experiment update form) | menu | — | form field 'status' posted to /progression/experiments/<str:key>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+3 more | automated |
| rollout stage (progression experiment update form) | menu | — | form field 'rollout_stage' posted to /progression/experiments/<str:key>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+3 more | automated |
| progression-oncall (progression experiment update form) | field | — | form field 'safety_stop_owner' posted to /progression/experiments/<str:key>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+3 more | automated |
| https://dashboard/review (progression experiment update form | field | — | form field 'evidence_uri' posted to /progression/experiments/<str:key>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+3 more | automated |
| Reviewed cohort safety, fraud, retention and projection SLO  | field | — | form field 'decision_note' posted to /progression/experiments/<str:key>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_experiment_update_rejects_mismatched_stage<br>django: `test_views.py` › DashboardViewsTest.test_progression_rollout_forwards_reviewed_fixed_st<br>+3 more | automated |
| progression fraud rule update | button | — | POST form → /progression/fraud-rules/<str:rule_code>/ (views.progression_fraud_rule_update) | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+5 more | automated |
| rejected attempt threshold (progression fraud rule update fo | field | — | form field 'rejected_attempt_threshold' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| window seconds (progression fraud rule update form) | field | — | form field 'window_seconds' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| review sla minutes (progression fraud rule update form) | field | — | form field 'review_sla_minutes' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| severity (progression fraud rule update form) | menu | — | form field 'severity' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| enabled (progression fraud rule update form) | toggle | — | form field 'enabled' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| tuning note (progression fraud rule update form) | field | — | form field 'tuning_note' posted to /progression/fraud-rules/<str:rule_code>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_rule_update_validates<br>django: `test_views.py` › DashboardViewsTest.test_progression_fraud_tuning_forwards_bounded_revi<br>+3 more | automated |
| progression fraud resolve | button | — | POST form → /progression/fraud/<str:case_id>/ (views.progression_fraud_resolve) | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_resolve_requires_final_status_and_re<br>django: `test_cases_progression.py` › test_fraud_resolve_requires_final_status_and_resolution<br>+5 more | automated |
| Resolution evidence (progression fraud resolve form) | field | — | form field 'resolution' posted to /progression/fraud/<str:case_id>/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_fraud_resolve_requires_final_status_and_re<br>django: `test_cases_progression.py` › test_fraud_resolve_requires_final_status_and_resolution<br>+2 more | automated |
| progression user adjust | button | — | POST form → /progression/users/adjust/ (views.progression_user_adjust) | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_adjust_posts_audited_amount<br>django: `test_views.py` › DashboardViewsTest.test_progression_adjustment_requires_auditable_reas<br>+6 more | automated |
| User UUID (progression user adjust form) | field | — | form field 'user_id' posted to /progression/users/adjust/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_adjust_posts_audited_amount<br>django: `test_views.py` › DashboardViewsTest.test_progression_adjustment_requires_auditable_reas<br>+3 more | automated |
| XP amount (progression user adjust form) | field | — | form field 'amount' posted to /progression/users/adjust/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_adjust_posts_audited_amount<br>django: `test_views.py` › DashboardViewsTest.test_progression_adjustment_requires_auditable_reas<br>+3 more | automated |
| Audit reason (minimum 10 characters) (progression user adjus | field | — | form field 'reason' posted to /progression/users/adjust/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_adjust_posts_audited_amount<br>django: `test_views.py` › DashboardViewsTest.test_progression_adjustment_requires_auditable_reas<br>+3 more | automated |
| progression user control | button | — | POST form → /progression/users/control/ (views.progression_user_control) | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_control_bounds_risk<br>django: `test_views.py` › DashboardViewsTest.test_progression_control_forwards_freeze_and_risk<br>+5 more | automated |
| User UUID (progression user control form) | field | — | form field 'user_id' posted to /progression/users/control/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_control_bounds_risk<br>django: `test_views.py` › DashboardViewsTest.test_progression_control_forwards_freeze_and_risk<br>+3 more | automated |
| risk multiplier (progression user control form) | field | — | form field 'risk_multiplier' posted to /progression/users/control/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_control_bounds_risk<br>django: `test_views.py` › DashboardViewsTest.test_progression_control_forwards_freeze_and_risk<br>+3 more | automated |
| Safety or risk reason (progression user control form) | field | — | form field 'reason' posted to /progression/users/control/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_control_bounds_risk<br>django: `test_views.py` › DashboardViewsTest.test_progression_control_forwards_freeze_and_risk<br>+3 more | automated |
| progression frozen (progression user control form) | toggle | — | form field 'progression_frozen' posted to /progression/users/control/ | django: `test_cases_progression.py` › ProgressionActionsTest.test_user_control_bounds_risk<br>django: `test_views.py` › DashboardViewsTest.test_progression_control_forwards_freeze_and_risk<br>+3 more | automated |

#### Billing — `console.billing`

Route: control-panel /billing/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| billing dashboard | link | — | page → /billing/ (views.billing_dashboard) | django: `test_cases_billing.py` › BillingDashboardTest.test_dashboard_renders_plans_packages_and_stats<br>django: `test_cases_billing.py` › BillingDashboardTest.test_stats_outage_is_unavailable_not_zero<br>+7 more | automated |
| billing package toggle | button | — | POST form → /billing/packages/<str:package_id>/toggle/ (views.billing_package_toggle) | django: `test_cases_billing.py` › CoinPackagesTest.test_toggle<br>django: `test_cases_billing.py` › test_dashboard_renders_plans_packages_and_stats<br>+4 more | automated |
| billing package new | button | — | POST form → /billing/packages/new/ (views.billing_package_new) | django: `test_cases_billing.py` › CoinPackagesTest.test_new_package_validates_and_creates<br>django: `test_cases_billing.py` › test_new_package_validates_and_creates<br>+3 more | automated |
| billing package edit | button | — | POST form → /billing/packages/<str:package_id>/edit/ (views.billing_package_edit) | django: `test_cases_billing.py` › CoinPackagesTest.test_edit_package_prefills_and_updates<br>django: `test_cases_billing.py` › CoinPackagesTest.test_edit_unknown_package_is_404<br>+6 more | automated |
| billing transactions | link | — | page → /billing/transactions/ (views.billing_transactions) | django: `test_cases_billing.py` › BillingListsTest.test_transactions_render_and_page<br>django: `test_cases_billing.py` › test_transactions_render_and_page<br>+1 more | partial |
| Search member ID or reference (billing transactions) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| Source filter (billing transactions) | field | — | text filter 'source' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| Provider filter (billing transactions) | field | — | text filter 'provider' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| From (UTC) filter (billing transactions) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| To (UTC) filter (billing transactions) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_billing.py` › test_transactions_render_and_page | automated |
| Export Excel (billing transactions) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| billing grant coins | button | — | POST form → /billing/grant-coins/ (views.billing_grant_coins) | django: `test_cases_billing.py` › BillingGrantCoinsTest.test_quick_grant<br>django: `test_cases_billing.py` › test_dashboard_renders_plans_packages_and_stats<br>+4 more | automated |
| UUID (billing grant coins form) | field | — | form field 'user_id' posted to /billing/grant-coins/ | django: `test_cases_billing.py` › BillingGrantCoinsTest.test_quick_grant<br>django: `test_cases_billing.py` › test_dashboard_renders_plans_packages_and_stats<br>+2 more | automated |
| amount (billing grant coins form) | field | — | form field 'amount' posted to /billing/grant-coins/ | django: `test_cases_billing.py` › BillingGrantCoinsTest.test_quick_grant<br>django: `test_cases_billing.py` › test_dashboard_renders_plans_packages_and_stats<br>+2 more | automated |
| admin_grant (billing grant coins form) | field | — | form field 'reason' posted to /billing/grant-coins/ | django: `test_cases_billing.py` › BillingGrantCoinsTest.test_quick_grant<br>django: `test_cases_billing.py` › test_dashboard_renders_plans_packages_and_stats<br>+2 more | automated |
| billing subscriptions | link | — | page → /billing/subscriptions/ (views.billing_subscriptions) | django: `test_cases_billing.py` › BillingListsTest.test_subscriptions_render_with_filters<br>django: `test_cases_billing.py` › test_subscriptions_render_with_filters<br>+1 more | partial |
| Search member ID or reference (billing subscriptions) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| Status filter (billing subscriptions) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| Plan filter (billing subscriptions) | field | — | text filter 'plan_code' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| From (UTC) filter (billing subscriptions) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| To (UTC) filter (billing subscriptions) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_billing.py` › test_subscriptions_render_with_filters | automated |
| Export Excel (billing subscriptions) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| billing payments | link | — | page → /billing/payments/ (views.billing_payments) | django: `test_cases_billing.py` › BillingListsTest.test_payments_render_with_filters<br>django: `test_cases_billing.py` › test_payments_render_with_filters<br>+4 more | automated |
| Search member ID or reference (billing payments) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_billing.py` › test_payments_render_with_filters<br>django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| Status filter (billing payments) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_payments_render_with_filters<br>django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| From (UTC) filter (billing payments) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_payments_render_with_filters<br>django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| To (UTC) filter (billing payments) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_payments_render_with_filters<br>django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_billing.py` › test_payments_render_with_filters<br>django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| Export Excel (billing payments) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | django: `test_listing.py` › test_search_and_dates_reach_go_and_export_matches | automated |
| billing revenue analytics | link | — | page → /billing/revenue/ (views.billing_revenue_analytics) | django: `test_business.py` › BillingRevenuePageTest.test_revenue_page_uses_windowed_per_currency_ap<br>django: `test_business.py` › BillingRevenuePageTest.test_revenue_page_empty_state<br>+6 more | automated |
| since (billing revenue analytics) | field | — | GET filter 'since' | django: `test_business.py` › test_revenue_page_uses_windowed_per_currency_api<br>django: `test_business.py` › test_revenue_page_empty_state | automated |
| until (billing revenue analytics) | field | — | GET filter 'until' | django: `test_business.py` › test_revenue_page_uses_windowed_per_currency_api<br>django: `test_business.py` › test_revenue_page_empty_state | automated |
| tz (billing revenue analytics) | menu | — | GET filter 'tz' | django: `test_business.py` › test_revenue_page_uses_windowed_per_currency_api<br>django: `test_business.py` › test_revenue_page_empty_state | automated |
| mode (billing revenue analytics) | menu | — | GET filter 'mode' | django: `test_business.py` › test_revenue_page_uses_windowed_per_currency_api<br>django: `test_business.py` › test_revenue_page_empty_state | automated |
| billing webhook events | link | — | page → /billing/webhooks/ (views.billing_webhook_events) | django: `test_cases_billing.py` › BillingListsTest.test_webhook_events_render_with_filters<br>django: `test_cases_billing.py` › test_webhook_events_render_with_filters<br>+1 more | partial |
| Search event ID or reference (billing webhook events) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| Status filter (billing webhook events) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| Event type filter (billing webhook events) | field | — | text filter 'event_type' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| From (UTC) filter (billing webhook events) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| To (UTC) filter (billing webhook events) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_billing.py` › test_webhook_events_render_with_filters | automated |
| Export Excel (billing webhook events) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| billing reconciliation | link | — | page → /billing/reconciliation/ (views.billing_reconciliation) | django: `test_cases_billing.py` › BillingListsTest.test_reconciliation_bff_failure_shows_banners<br>django: `test_paged_lists.py` › EconomyFraudPagingTest.test_fraud_cases_page_on_reconciliation<br>+15 more | partial |
| Search rule or event type (billing reconciliation) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Case status filter (billing reconciliation) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Severity filter (billing reconciliation) | menu | — | choice filter 'severity' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Rule filter (billing reconciliation) | field | — | text filter 'rule_code' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Member ID filter (billing reconciliation) | field | — | text filter 'user_id' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Detected from (UTC) filter (billing reconciliation) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Detected to (UTC) filter (billing reconciliation) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Sort (severity, last_detected_at, first_detected_at) | menu | — | sort + direction sent to Go as sort/order | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| since (billing reconciliation) | field | — | GET filter 'since' | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| until (billing reconciliation) | field | — | GET filter 'until' | django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>django: `test_paged_lists.py` › test_fraud_cases_page_on_reconciliation<br>+1 more | automated |
| Export Excel (billing reconciliation) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| billing gift reverse | button | — | POST form → /billing/gifts/reverse/ (views.billing_gift_reverse) | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_gift_reverse_reports_refund<br>django: `test_views.py` › BillingIntegrityViewsTest.test_gift_reversal_posts_reason_to_bff<br>+7 more | automated |
| UUID from the audit event (billing gift reverse form) | field | — | form field 'gift_send_id' posted to /billing/gifts/reverse/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_gift_reverse_reports_refund<br>django: `test_views.py` › BillingIntegrityViewsTest.test_gift_reversal_posts_reason_to_bff<br>+5 more | automated |
| Explain why this gift is being reversed (billing gift revers | field | — | form field 'reason' posted to /billing/gifts/reverse/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_gift_reverse_reports_refund<br>django: `test_views.py` › BillingIntegrityViewsTest.test_gift_reversal_posts_reason_to_bff<br>+5 more | automated |
| billing wallet review | button | — | POST form → /billing/wallets/<str:user_id>/review/ (views.billing_wallet_review) | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_wallet_review_validates_and_reports<br>django: `test_views.py` › BillingIntegrityViewsTest.test_wallet_review_posts_audited_resolution_<br>+5 more | automated |
| action (billing wallet review form) | menu | — | form field 'action' posted to /billing/wallets/<str:user_id>/review/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_wallet_review_validates_and_reports<br>django: `test_views.py` › BillingIntegrityViewsTest.test_wallet_review_posts_audited_resolution_<br>+3 more | automated |
| Evidence and decision (billing wallet review form) | field | — | form field 'note' posted to /billing/wallets/<str:user_id>/review/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_wallet_review_validates_and_reports<br>django: `test_views.py` › BillingIntegrityViewsTest.test_wallet_review_posts_audited_resolution_<br>+3 more | automated |
| billing fraud case resolve | button | — | POST form → /billing/fraud/cases/<str:case_id>/resolve/ (views.billing_fraud_case_resolve) | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_fraud_case_resolve_validates_and_repo<br>django: `test_views.py` › BillingIntegrityViewsTest.test_fraud_false_positive_posts_attributed_c<br>+6 more | automated |
| resolution (billing fraud case resolve form) | menu | — | form field 'resolution' posted to /billing/fraud/cases/<str:case_id>/resolve/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_fraud_case_resolve_validates_and_repo<br>django: `test_views.py` › BillingIntegrityViewsTest.test_fraud_false_positive_posts_attributed_c<br>+4 more | automated |
| note (billing fraud case resolve form) | field | — | form field 'note' posted to /billing/fraud/cases/<str:case_id>/resolve/ | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_fraud_case_resolve_validates_and_repo<br>django: `test_views.py` › BillingIntegrityViewsTest.test_fraud_false_positive_posts_attributed_c<br>+4 more | automated |
| billing fraud rule update | button | — | POST form → /billing/fraud/rules/<str:rule_code>/ (views.billing_fraud_rule_update) | django: `test_cases_billing.py` › BillingIntegrityActionsTest.test_fraud_rule_update_forwards_policy<br>django: `test_cases_billing.py` › test_fraud_rule_update_forwards_policy<br>+4 more | automated |

#### Safety (SOS) — `console.safety`

Route: control-panel /safety/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| safety sos | link | — | page → /safety/sos/ (views.safety_sos) | django: `test_cases_safety.py` › SafetySosTest.test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › SafetySosTest.test_sos_page_bff_failure_shows_banner<br>+6 more | partial |
| Search message or note (safety sos) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › test_sos_page_bff_failure_shows_banner | automated |
| Status filter (safety sos) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › test_sos_page_bff_failure_shows_banner | automated |
| From (UTC) filter (safety sos) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › test_sos_page_bff_failure_shows_banner | automated |
| To (UTC) filter (safety sos) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › test_sos_page_bff_failure_shows_banner | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>django: `test_cases_safety.py` › test_sos_page_bff_failure_shows_banner | automated |
| Export Excel (safety sos) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| safety sos resolve | button | — | POST form → /safety/sos/<str:alert_id>/resolve/ (views.safety_sos_resolve) | django: `test_cases_safety.py` › SafetySosTest.test_resolve_alert<br>django: `test_cases_safety.py` › test_sos_page_shows_open_alerts_with_trigger_time<br>+6 more | automated |

#### Account recovery — `console.account_recovery`

Route: control-panel /account-recovery/ · Source: `control-panel/control_panel/urls.py`, `control-panel/control_panel/views.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| account recovery queue | link | — | page → /account-recovery/ (views.account_recovery_queue) | django: `test_cases_safety.py` › AccountRecoveryTest.test_queue_filters_and_bff_failure<br>django: `test_views.py` › AccountRecoveryViewsTest.test_queue_lists_open_requests<br>+7 more | partial |
| Search username or message (account recovery queue) | field | — | free-text search sent to Go as q (escaped in page links) | django: `test_cases_safety.py` › test_queue_filters_and_bff_failure | automated |
| Status filter (account recovery queue) | menu | — | choice filter 'status' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_queue_filters_and_bff_failure | automated |
| From (UTC) filter (account recovery queue) | field | — | date filter 'from' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_queue_filters_and_bff_failure | automated |
| To (UTC) filter (account recovery queue) | field | — | date filter 'to' sent to Go only when allowed by the ListSpec | django: `test_cases_safety.py` › test_queue_filters_and_bff_failure | automated |
| Page size and pager | link | — | page/page_size reach Go as limit/offset; past-the-end clamps | django: `test_cases_safety.py` › test_queue_filters_and_bff_failure | automated |
| Export Excel (account recovery queue) | button | — | ?export=xlsx pages through Go with the same filters and returns a workbook | — | **GAP** |
| account recovery resolve | button | — | POST form → /account-recovery/<str:request_id>/resolve/ (views.account_recovery_resolve) | django: `test_cases_safety.py` › AccountRecoveryTest.test_resolve_failure_is_reported_without_a_code<br>django: `test_views.py` › AccountRecoveryViewsTest.test_issued_code_is_shown_once_and_never_cach<br>+7 more | automated |
| identity check (account recovery resolve form) | menu | — | form field 'identity_check' posted to /account-recovery/<str:request_id>/resolve/ | django: `test_cases_safety.py` › AccountRecoveryTest.test_resolve_failure_is_reported_without_a_code<br>django: `test_views.py` › AccountRecoveryViewsTest.test_issued_code_is_shown_once_and_never_cach<br>+5 more | automated |
| What you checked (10+ characters). Never paste the code here | field | — | form field 'resolution_note' posted to /account-recovery/<str:request_id>/resolve/ | django: `test_cases_safety.py` › AccountRecoveryTest.test_resolve_failure_is_reported_without_a_code<br>django: `test_views.py` › AccountRecoveryViewsTest.test_issued_code_is_shown_once_and_never_cach<br>+5 more | automated |

#### Report: Member 360 (Members) — `console.reports.member_360`

Route: control-panel /reports/member-360/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Member ID or @username parameter | field | — | member parameter 'member' (required) | django: `test_reports.py` › MemberReportsTest.test_member_360_asks_for_a_member_first<br>django: `test_reports.py` › MemberReportsTest.test_unknown_username_is_explained | partial |
| From (UTC) parameter | field | — | date parameter 'from' | django: `test_reports.py` › MemberReportsTest.test_member_360_asks_for_a_member_first<br>django: `test_reports.py` › MemberReportsTest.test_unknown_username_is_explained | partial |
| To (UTC) parameter | field | — | date parameter 'to' | django: `test_reports.py` › MemberReportsTest.test_member_360_asks_for_a_member_first<br>django: `test_reports.py` › MemberReportsTest.test_unknown_username_is_explained | partial |
| Group by (recent_actions, reports_filed, reports_received, p | menu | — | regroups the table(s) | django: `test_reports.py` › MemberReportsTest.test_member_360_resolves_a_username_and_reads_every_ | automated |
| Export Excel | button | — | /reports/member-360/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/member-360/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/member-360/?export=pdf | — | **GAP** |

#### Report: Member directory (Members) — `console.reports.member_directory`

Route: control-panel /reports/member-directory/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Name, phone or id parameter | field | — | text parameter 'q' | — | **GAP** |
| Status parameter | menu | — | choice parameter 'status' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Verified parameter | menu | — | choice parameter 'verified' | — | **GAP** |
| Group by (members) | menu | — | regroups the table(s) | django: `test_reports.py` › MemberReportsTest.test_directory_pages_through_go_and_drills_into_memb | automated |
| Export Excel | button | — | /reports/member-directory/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/member-directory/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/member-directory/?export=pdf | — | **GAP** |

#### Report: Dormant members (Members) — `console.reports.dormant_members`

Route: control-panel /reports/dormant-members/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Inactive for at least parameter | menu | — | choice parameter 'days' | django: `test_reports.py` › OperationsReportsTest.test_dormant_members_filters_and_sorts_by_inacti | automated |
| Verified parameter | menu | — | choice parameter 'verified' | django: `test_reports.py` › OperationsReportsTest.test_dormant_members_filters_and_sorts_by_inacti | automated |
| Group by (dormant) | menu | — | regroups the table(s) | django: `test_reports.py` › OperationsReportsTest.test_dormant_members_filters_and_sorts_by_inacti | automated |
| Export Excel | button | — | /reports/dormant-members/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/dormant-members/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/dormant-members/?export=pdf | — | **GAP** |

#### Report: Sign-in and account security (Members) — `console.reports.signin_security`

Route: control-panel /reports/signin-security/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (auth) | menu | — | regroups the table(s) | django: `test_reports.py` › OperationsReportsTest.test_signin_security_reads_auth_actions | automated |
| Export Excel | button | — | /reports/signin-security/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/signin-security/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/signin-security/?export=pdf | — | **GAP** |

#### Report: Most-reported members (Members) — `console.reports.most_reported_members`

Route: control-panel /reports/most-reported-members/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Report status parameter | menu | — | choice parameter 'status' | — | **GAP** |
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (by_member) | menu | — | regroups the table(s) | django: `test_reports.py` › MemberReportsTest.test_most_reported_lists_the_largest_groups_first | automated |
| Export Excel | button | — | /reports/most-reported-members/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/most-reported-members/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/most-reported-members/?export=pdf | — | **GAP** |

#### Report: Paying members by plan (Members) — `console.reports.paying_members`

Route: control-panel /reports/paying-members/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Subscription status parameter | menu | — | choice parameter 'status' | — | **GAP** |
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (subscribers) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/paying-members/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/paying-members/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/paying-members/?export=pdf | — | **GAP** |

#### Report: Daily operations summary (Operations) — `console.reports.daily_operations`

Route: control-panel /reports/daily-operations/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| As of (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Export Excel | button | — | /reports/daily-operations/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/daily-operations/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/daily-operations/?export=pdf | django: `test_reports.py` › OperationsReportsTest.test_daily_operations_survives_unavailable_sourc | automated |

#### Report: Queue SLA (Operations) — `console.reports.queue_sla`

Route: control-panel /reports/queue-sla/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Export Excel | button | — | /reports/queue-sla/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/queue-sla/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/queue-sla/?export=pdf | — | **GAP** |

#### Report: Operator productivity (Operations) — `console.reports.operator_productivity`

Route: control-panel /reports/operator-productivity/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (by_operator) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/operator-productivity/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/operator-productivity/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/operator-productivity/?export=pdf | — | **GAP** |

#### Report: Moderation outcomes (Operations) — `console.reports.moderation_outcomes`

Route: control-panel /reports/moderation-outcomes/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (reports, appeals) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/moderation-outcomes/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/moderation-outcomes/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/moderation-outcomes/?export=pdf | — | **GAP** |

#### Report: SOS incident log (Operations) — `console.reports.sos_incidents`

Route: control-panel /reports/sos-incidents/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (alerts) | menu | — | regroups the table(s) | django: `test_reports.py` › OperationsReportsTest.test_sos_minutes_to_resolve | automated |
| Export Excel | button | — | /reports/sos-incidents/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/sos-incidents/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/sos-incidents/?export=pdf | — | **GAP** |

#### Report: Payment operations (Operations) — `console.reports.payment_operations`

Route: control-panel /reports/payment-operations/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (failed, refunded, webhooks) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/payment-operations/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/payment-operations/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/payment-operations/?export=pdf | — | **GAP** |

#### Report: Configuration change log (Operations) — `console.reports.config_changes`

Route: control-panel /reports/config-changes/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (changes) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/config-changes/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/config-changes/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/config-changes/?export=pdf | — | **GAP** |

#### Report: API traffic and latency (Server) — `console.reports.api_traffic`

Route: control-panel /reports/api-traffic/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Per parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Group by (by_route, by_status) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/api-traffic/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/api-traffic/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/api-traffic/?export=pdf | — | **GAP** |

#### Report: Background job runs (Server) — `console.reports.background_jobs`

Route: control-panel /reports/background-jobs/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Status parameter | menu | — | choice parameter 'status' | — | **GAP** |
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (runs) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/background-jobs/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/background-jobs/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/background-jobs/?export=pdf | — | **GAP** |

#### Report: Database and storage consumption (Server) — `console.reports.database_consumption`

Route: control-panel /reports/database-consumption/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Export Excel | button | — | /reports/database-consumption/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/database-consumption/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/database-consumption/?export=pdf | — | **GAP** |

#### Report: Third-party usage (Server) — `console.reports.third_party_usage`

Route: control-panel /reports/third-party-usage/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Group by (totals, daily) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/third-party-usage/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/third-party-usage/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/third-party-usage/?export=pdf | — | **GAP** |

#### Report: Revenue (Business) — `console.reports.revenue`

Route: control-panel /reports/revenue/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Time zone parameter | menu | — | choice parameter 'tz' | — | **GAP** |
| Payments parameter | menu | — | choice parameter 'mode' | — | **GAP** |
| Period parameter | menu | — | choice parameter 'bucket' | — | **GAP** |
| Group by (totals, by_product, by_city, trend) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/revenue/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/revenue/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/revenue/?export=pdf | — | **GAP** |

#### Report: Subscriptions & MRR (Business) — `console.reports.subscriptions`

Route: control-panel /reports/subscriptions/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Time zone parameter | menu | — | choice parameter 'tz' | — | **GAP** |
| Payments parameter | menu | — | choice parameter 'mode' | — | **GAP** |
| Period parameter | menu | — | choice parameter 'bucket' | — | **GAP** |
| Months parameter | field | — | int parameter 'months' | — | **GAP** |
| Group by (movements, plan_mix) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/subscriptions/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/subscriptions/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/subscriptions/?export=pdf | — | **GAP** |

#### Report: Conversion & checkout funnel (Business) — `console.reports.conversion`

Route: control-panel /reports/conversion/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Time zone parameter | menu | — | choice parameter 'tz' | — | **GAP** |
| Payments parameter | menu | — | choice parameter 'mode' | — | **GAP** |
| Group by (funnel) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/conversion/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/conversion/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/conversion/?export=pdf | — | **GAP** |

#### Report: Coin economy (Business) — `console.reports.coins`

Route: control-panel /reports/coins/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Time zone parameter | menu | — | choice parameter 'tz' | — | **GAP** |
| Payments parameter | menu | — | choice parameter 'mode' | — | **GAP** |
| Period parameter | menu | — | choice parameter 'bucket' | — | **GAP** |
| Group by (purchases) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/coins/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/coins/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/coins/?export=pdf | — | **GAP** |

#### Report: Referrals & introducers (Business) — `console.reports.referrals`

Route: control-panel /reports/referrals/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Time zone parameter | menu | — | choice parameter 'tz' | — | **GAP** |
| Payments parameter | menu | — | choice parameter 'mode' | — | **GAP** |
| Period parameter | menu | — | choice parameter 'bucket' | — | **GAP** |
| Export Excel | button | — | /reports/referrals/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/referrals/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/referrals/?export=pdf | — | **GAP** |

#### Report: Marketing spend & CAC (Business) — `console.reports.marketing_spend`

Route: control-panel /reports/marketing-spend/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From parameter | field | — | date parameter 'since' | — | **GAP** |
| To parameter | field | — | date parameter 'until' | — | **GAP** |
| Group by (cac) | menu | — | regroups the table(s) | — | **GAP** |
| Export Excel | button | — | /reports/marketing-spend/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/marketing-spend/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/marketing-spend/?export=pdf | — | **GAP** |

#### Report: Headline KPIs (Product) — `console.reports.kpis`

Route: control-panel /reports/kpis/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/kpis/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/kpis/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/kpis/?export=pdf | — | **GAP** |

#### Report: Active members over time (Product) — `console.reports.trends`

Route: control-panel /reports/trends/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/trends/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/trends/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/trends/?export=pdf | — | **GAP** |

#### Report: Activation funnel (Product) — `console.reports.funnel`

Route: control-panel /reports/funnel/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/funnel/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/funnel/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/funnel/?export=pdf | — | **GAP** |

#### Report: Retention cohorts (Product) — `console.reports.retention`

Route: control-panel /reports/retention/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/retention/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/retention/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/retention/?export=pdf | — | **GAP** |

#### Report: Engagement (Product) — `console.reports.engagement`

Route: control-panel /reports/engagement/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/engagement/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/engagement/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/engagement/?export=pdf | — | **GAP** |

#### Report: Liquidity by city (Product) — `console.reports.liquidity`

Route: control-panel /reports/liquidity/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| City parameter | field | — | text parameter 'city' | — | **GAP** |
| Export Excel | button | — | /reports/liquidity/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/liquidity/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/liquidity/?export=pdf | — | **GAP** |

#### Report: Safety health (Product) — `console.reports.safety`

Route: control-panel /reports/safety/ · Source: `control-panel/control_panel/reports/catalog.py`, `control-panel/control_panel/views_reports.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| From (UTC) parameter | field | — | date parameter 'from' | — | **GAP** |
| To (UTC) parameter | field | — | date parameter 'to' | — | **GAP** |
| Grain parameter | menu | — | choice parameter 'grain' | — | **GAP** |
| Gender parameter | menu | — | choice parameter 'gender' | — | **GAP** |
| Export Excel | button | — | /reports/safety/?export=xlsx | — | **GAP** |
| Export CSV (per table) | button | — | /reports/safety/?export=csv | — | **GAP** |
| Export PDF | button | — | /reports/safety/?export=pdf | — | **GAP** |

#### Live socket (/ws/live/) — `console.live`

Route: control-panel ws /ws/live/ · Source: `control-panel/control_panel/consumers.py`, `control-panel/control_panel/live.py`, `control-panel/control_panel_project/asgi.py`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Live topic 'nav' | link | — | open-item counts for the sidebar's queue links, the BFF health badge, and the open SOS ids (for the new-SOS alert). Every console page subscribes to it. | django: `test_live.py` › LiveSocketTest.test_nav_counts_open_items_and_the_bff_state<br>django: `test_live.py` › LiveSocketTest.test_nav_reads_only_what_the_role_may_see | automated |
| Live topic 'dashboard' | link | — | the command center's live region, rendered from the same snapshot the page itself renders. | django: `test_live.py` › LiveSocketTest.test_dashboard_region_is_pushed_as_rendered_html | automated |
| Live topic 'activity' | link | — | new member actions after this connection's cursor, matching the activity page's filters, as rendered table rows. | django: `test_member_activity.py` › ActivityLiveTailTest.test_tail_primes_then_pushes_new_rows_for_the_pag | automated |

#### Server-side lists (shared paging, search, filters, Excel export) — `console.lists`

Route: every list page (listing.ListSpec) · Source: `control-panel/control_panel/listing.py`, `control-panel/templates/control_panel/partials/_list_toolbar.html`, `control-panel/templates/control_panel/partials/_list_controls.html`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| List toolbar: search, filters, sort, page size | field | — | shared list controls | django: `test_listing.py` › UserListPagingTest.test_unknown_values_never_reach_go<br>django: `test_paged_lists.py` › CatalogPagingTest.test_unknown_filter_values_are_dropped<br>+2 more | automated |
| Pagination links | link | — | page links keep every parameter | django: `test_listing.py` › UserListPagingTest.test_page_size_and_page_reach_go_as_limit_and_offse<br>django: `test_paged_lists.py` › CatalogPagingTest.test_page_filters_and_sort_reach_go<br>+2 more | automated |
| Export Excel | button | — | ?export=xlsx | django: `test_listing.py` › ExcelExportTest.test_export_pages_through_go_and_returns_a_workbook<br>django: `test_paged_lists.py` › CatalogPagingTest.test_excel_export_holds_every_matching_gift<br>+4 more | automated |

#### Console shell (sidebar, phone menu, dialogs, styles) — `console.layout`

Route: every console page (base.html) · Source: `control-panel/templates/control_panel/base.html`, `control-panel/static`

| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |
|---|---|---|---|---|---|
| Fold sidebar into an icon rail (desktop) | button | — | toggles the icon rail | playwright: `console-layout.spec.js` › operator console layout > desktop menu folds the sidebar into an icon  | automated |
| Phone menu | button | — | opens/closes the sidebar on phones | playwright: `console-layout.spec.js` › operator console layout > phone menu opens and closes [case:console.la | automated |
| Confirm dialog for destructive actions | button | — | Bootstrap dialog instead of window.confirm | playwright: `console-layout.spec.js` › destructive actions confirm in the Bootstrap dialog, not window.confir | automated |
| Report action modal | button | — | centred opaque Bootstrap modal | playwright: `console-layout.spec.js` › operator console layout > report actions open in a centred, opaque Boo | automated |

### Localization

#### Spoken labels and qa ids in every language — `l10n.a11y`

Route: cross-cutting · Source: `app/lib/core/qa_ids.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Bottom nav and filter sheet keep qa ids as identifiers and speak the member's language | a11y | flutter: `qa_ids_are_identifiers_test.dart` › [case:l10n.a11y.qa_ids_nav_and_filters] bottom nav and filter sheet ke | automated |
| Deck action buttons are named in the member's language and keep their ids | a11y | flutter: `qa_ids_are_identifiers_test.dart` › [case:l10n.a11y.qa_ids_swipe_buttons] deck action buttons are named in | automated |
| Welcome, sign-in and sign-up speak the language; ids stay ids | a11y | flutter: `auth_qa_ids_spoken_labels_test.dart` › welcome, sign-in and sign-up speak German, ids stay ids [case:l10n.a11 | automated |
| Terms, recovery and setup speak the language; ids stay ids | a11y | flutter: `auth_qa_ids_spoken_labels_test.dart` › terms, recovery and setup speak German, ids stay ids [case:l10n.a11y.s | automated |

#### App language before and after sign-in — `l10n.language`

Route: cross-cutting · Source: `app/lib/core/l10n`

| Case | Type | Automated by | Status |
|---|---|---|---|
| An unsupported device language opens in English | l10n | flutter: `pre_sign_in_language_test.dart` › an unsupported device language opens in English, not German [case:l10n | automated |
| A cached language is saved to an account that has none | l10n | flutter: `pre_sign_in_language_test.dart` › a cached language is saved to an account that has none [case:l10n.lang | automated |
| A new account gets the language picked before sign-in | l10n | flutter: `pre_sign_in_language_test.dart` › a new account gets the language picked before sign-in saved [case:l10n | automated |
| An explicit pick before sign-in wins over an older stored language | l10n | flutter: `pre_sign_in_language_test.dart` › an explicit pick before sign-in wins over an older stored language [ca | automated |
| A failed save keeps the pick and retries at the next sign-in | l10n | flutter: `pre_sign_in_language_test.dart` › a failed save keeps the pick and retries at the next sign-in [case:l10 | automated |
| Without a pick the stored language wins over the device cache | l10n | flutter: `pre_sign_in_language_test.dart` › without a pick the stored language wins over the device cache [case:l1 | automated |
| The website lang parameter is read from the query or hash and seeds the cache only when empty | l10n | flutter: `pre_sign_in_language_test.dart` › website lang parameter [case:l10n.language.web_lang_param] is read fro<br>flutter: `pre_sign_in_language_test.dart` › website lang parameter [case:l10n.language.web_lang_param] seeds the c | automated |
| The welcome screen changes language before sign-in | l10n | flutter: `pre_sign_in_language_test.dart` › the welcome screen changes language before sign-in [case:l10n.language | automated |

#### Onboarding in every language — `l10n.setup`

Route: cross-cutting · Source: `app/lib/features/profile/screens/setup`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Onboarding dropdowns read in the language; stored values stay master-data words | l10n | flutter: `setup_preferences_screen_test.dart` › onboarding dropdowns read in German; the stored values stay the master | automated |
| Onboarding errors never show raw server or exception text | l10n | flutter: `setup_preview_entry_controls_test.dart` › onboarding errors in German never show raw server or exception text [c<br>flutter: `setup_preview_entry_controls_test.dart` › onboarding errors in German never show raw server or exception text [c | automated |

#### API error messages (ApiErrorMessage) — `l10n.api_errors`

Route: cross-cutting · Source: `app/lib/core/network/api_error_message.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| A 5xx with technical text uses the fallback in English | l10n | flutter: `api_error_message_test.dart` › a 5xx with technical text uses the fallback in English [case:l10n.api_ | automated |
| An empty fallback stays empty for unknown server text (callers pick their own message) | l10n | flutter: `api_error_message_test.dart` › an empty fallback stays empty for unknown server text in German (calle | automated |
| English shows the server message, trimmed | l10n | flutter: `api_error_message_test.dart` › English shows the server message, trimmed [case:l10n.api_errors.englis | automated |
| Friendly English sentences are not flagged as technical | l10n | flutter: `api_error_message_test.dart` › friendly English sentences are not flagged as technical [case:l10n.api | automated |
| A status-derived BAD_REQUEST keeps the caller fallback | l10n | flutter: `api_error_message_test.dart` › a status-derived BAD_REQUEST keeps the caller fallback in German [case | automated |
| A known error_code is translated in English too | l10n | flutter: `api_error_message_test.dart` › a known error_code is translated in English too, not the server text [ | automated |
| A known error_code maps to the German message | l10n | flutter: `api_error_message_test.dart` › a known error_code maps to the German message [case:l10n.api_errors.kn | automated |
| currentAppLocaleIsEnglish follows the app locale | l10n | flutter: `api_error_message_test.dart` › currentAppLocaleIsEnglish follows the app locale [case:l10n.api_errors | automated |
| A non-network error returns the fallback | l10n | flutter: `api_error_message_test.dart` › a non-network error returns the fallback [case:l10n.api_errors.non_net | automated |
| A connection failure maps to the translated offline message | l10n | flutter: `api_error_message_test.dart` › a connection failure maps to the translated offline message [case:l10n | automated |
| Technical server text in English uses the fallback | l10n | flutter: `api_error_message_test.dart` › technical server text in English uses the fallback: $technical [case:l | automated |
| TOO_MANY_REQUESTS without usable text maps to the generic wait message | l10n | flutter: `api_error_message_test.dart` › TOO_MANY_REQUESTS without usable text maps to the generic wait message | automated |
| Unknown server text in German falls back to the caller fallback | l10n | flutter: `api_error_message_test.dart` › unknown server text in German falls back to the caller fallback [case: | automated |

#### Chat bubbles and gift captions in every language — `l10n.chat_bubbles`

Route: cross-cutting · Source: `app/lib/features/messaging/widgets`

| Case | Type | Automated by | Status |
|---|---|---|---|
| A deleted message never shows its stored text | l10n | flutter: `chat_bubble_l10n_test.dart` › a deleted message never shows its stored text [case:l10n.chat_bubbles. | automated |
| A deleted message shows the placeholder in the reader's language | l10n | flutter: `chat_bubble_l10n_test.dart` › a deleted message shows the placeholder in the reader language [case:l | automated |
| Unknown chat errors get a translated generic message (English keeps readable server text) | l10n | flutter: `chat_bubble_l10n_test.dart` › unknown chat errors: English shows readable server text, technical tex | automated |
| Gift errors name the gift in the reader's language | l10n | flutter: `chat_bubble_l10n_test.dart` › gift errors name the gift in the reader language [case:l10n.chat_bubbl | automated |
| An English caption stored by older builds is not shown | l10n | flutter: `chat_bubble_l10n_test.dart` › an English caption stored by older builds is not shown [case:l10n.chat | automated |
| A note written with the gift is kept as written | l10n | flutter: `chat_bubble_l10n_test.dart` › a note the member wrote with the gift is kept as written [case:l10n.ch | automated |
| The recipient sees who sent the gift, in their language | l10n | flutter: `chat_bubble_l10n_test.dart` › the recipient sees who sent the gift, named in German [case:l10n.chat_ | automated |
| The sender sees their gift titled for them | l10n | flutter: `chat_bubble_l10n_test.dart` › the sender sees their gift titled for them, named in German [case:l10n | automated |
| Gift names resolve by id, by English name, or keep the server name | l10n | flutter: `chat_bubble_l10n_test.dart` › gift names resolve by id, by English name, or keep the server name [ca | automated |

#### Fallback names and brand constant — `l10n.fallback_names`

Route: cross-cutting · Source: `app/lib/core/l10n`

| Case | Type | Automated by | Status |
|---|---|---|---|
| The brand name is one constant | l10n | flutter: `fallback_names_l10n_test.dart` › the brand name is one constant [case:l10n.fallback_names.brand_name_co | automated |
| A discovery profile without a name gets the translated placeholder | l10n | flutter: `fallback_names_l10n_test.dart` › a discovery profile without a name gets the German placeholder, never  | automated |
| A photo byline without a name reads the translated 'a member' | l10n | flutter: `fallback_names_l10n_test.dart` › a photo byline without a name reads "Ein Mitglied" in German [case:l10 | automated |
| A date plan without names reads in the member's language | l10n | flutter: `date_plan_card_test.dart` › [case:l10n.fallback_names.plan_names_german] a plan without names read | automated |
| Cancelling a plan whose partner has no name names 'your match' in the language | l10n | flutter: `plan_card_controls_test.dart` › Cancel a plan whose partner has no name names "Dein Match" in German [ | automated |

#### Dates, numbers and defaults per locale — `l10n.formats`

Route: cross-cutting · Source: `app/lib/core/l10n`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Prefilled coffee-poll weekend days are in the member's language and sent as shown | l10n | flutter: `group_coffee_polls_controls_test.dart` › the prefilled weekend days are German for a German member and are sent | automated |
| The chapter comfort card language starts as the app language and is saved as shown | l10n | flutter: `chapter_studio_test.dart` › the comfort card language starts as the app language, in German "Deuts | automated |
| Date of birth reads in the member's own date order | l10n | flutter: `edit_profile_controls_test.dart` › the date of birth (1998-06-20 on the server) reads in the member's own | automated |
| Profile counts and completeness use the locale's separators | l10n | flutter: `profile_view_controls_test.dart` › behind the scenes counts and the completeness percent use German separ | automated |

#### Payment error text — `l10n.payment_errors`

Route: cross-cutting · Source: `app/lib/features/payment`

| Case | Type | Automated by | Status |
|---|---|---|---|
| In English a server message is shown as sent, without a code | l10n | flutter: `payment_error_test.dart` › in English a server message is shown as sent, without a code [case:l10 | automated |
| In German unknown server text falls back to the translated fallback | l10n | flutter: `payment_error_test.dart` › in German unknown server text falls back to the translated fallback [c | automated |

#### Chapter connections in every language — `l10n.blog_connections`

Route: cross-cutting · Source: `app/lib/features/blog/blog_connections.dart`

| Case | Type | Automated by | Status |
|---|---|---|---|
| A review notice names its kind and outcome in the member's language | l10n | flutter: `blog_connections_l10n_test.dart` › a review notice names its kind and outcome in German [case:l10n.blog_c | automated |
| A shared link whose source changed reads in the language and offers no approval | l10n | flutter: `blog_connections_l10n_test.dart` › a shared link whose source changed reads in German and offers no appro | automated |

#### Trust milestones — `l10n.trust_milestones`

Route: cross-cutting · Source: `app/lib/features/engagement`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Trust milestones read as translated labels; bookkeeping fields are hidden; unknown keys are humanized | l10n | flutter: `trust_milestones_l10n_test.dart` › trust milestones read as German labels, bookkeeping fields are hidden  | automated |

### Backend platform

#### Domain events and outbox retention (migration 134) — `platform.domain_events`

Route: backend (Postgres) · Source: `backend/internal/bff/mobile/domain_event_retention_postgres_test.go`, `backend/migrations`

| Case | Type | Automated by | Status |
|---|---|---|---|
| Excluded event sources stay excluded across migration reruns | edge | go: `domain_event_retention_postgres_test.go` › TestDomainEventRetentionExcludedSourcesSurviveMigrationReruns | automated |
| The outbox is append-only and retention removes only expired, unneeded events | edge | go: `domain_event_retention_postgres_test.go` › TestDomainEventRetentionRemovesOnlyExpiredUnneededEvents | automated |

## 4. Using the catalog in the QA runner

* Iterate `features[].cases[]`; `steps`/`expected` are written to be executed against seeded data (`seed_needs`). Prefer `qa_key` locators; fall back to `label` (English) or `alt_labels`.
* Treat `status: presence_only` as **failing coverage**: the runner must perform the action and assert `expected` (network call + visible result), not just locate the control.
* `*.api_contract` cases are API-level and already backed by Go/api_e2e tests where listed; `*.api_failure` cases need a fault-injecting proxy or stubbed BFF.
* Regenerate after UI or test changes: `python3 qa/catalog/tools/regenerate.py` (deterministic; rewrites `feature_catalog.json` and this file). New controls appear with status GAP.
* Test → case contract (QA Lab): Flutter/Playwright put `[case:<id>]` in the test name; pytest uses `@pytest.mark.case("<id>")`; Go puts `// case: <id>` directly above `func TestX`; Django puts `[case:<id>]` in the test method docstring (or `# case: <id>` above `def test_x`); interpolated ids (`[case:a.$name.action]`) count only for values that are string literals of the same file; `qa/catalog/extra_cases.json` declares, with a reason, controls/cases the static extraction cannot see. Tagged cases become `automated` (`mapped_by: tag`); cases listed in `qa/catalog/manual_cases.json` become `manual`. Run them from QA Lab (`documents/qa/QA_LAB_2026-10-02.md`).

## 5. Method limits

* Static inference: API calls reached only through dynamic dispatch or generic helpers may be missing (rows marked *unclassified*), and a callback that can take several branches lists all endpoints it can reach.
* Test matching is by `qa` key, then English label within the screens a test pumps; Appium/Playwright label matches are accepted only when the label is near-unique. Parameterised tests (`$key`) are credited to every key they iterate.
* Operator console is inventoried per URL route (each POST route = one control); template-level buttons are not enumerated individually.
