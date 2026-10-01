# Full application QA automation — 26 September 2026

Status: automated QA execution complete. Release sign-off remains blocked by the product and acceptance gaps below. This report distinguishes functional assertions, layout checks, live API checks and external/device acceptance.

Follow-up: [Feature logic improvements](FEATURE_LOGIC_IMPROVEMENTS_2026-09-26.md) fixes the age-privacy defect and adds saved preference enforcement, published-profile filtering and shared editor bounds. The findings below describe the original QA run; consult the follow-up for current validation and remaining gaps.

## Environment and evidence

- Native local PostgreSQL on port 55433; API gateway 18080 and mobile BFF 18081.
- ARM64 Android emulator, API 36.1. Debug APK built with real API access and QA selectors enabled.
- Appium 2.19.0/UiAutomator2, pytest 8.3.4/Python 3.13.12, Flutter 3.41.2/Dart 3.11.0, Go 1.26.0 and Django tests.
- Raw evidence: `qa/results/2026-09-26-full/`. Device failures also include screenshot, accessibility XML and Appium logs in `qa/reports/appium/artifacts/`.
- The initial Android run was interrupted after a selector defect was identified. The next run was interrupted after Appium keyboard/instrumentation failures. Those results are retained as `android-full.*` and `android-resumed.*`; they are not clean runs or final acceptance evidence.
- Concurrent QA was discovered sharing the original emulator and account. Final device execution uses a separate AVD (`Dating_QA_Isolated`, `emulator-5556`), Appium port 4725, UiAutomator2 system port 8201, and synthetic account `qa_full_20260926_isolated`. Artifacts are isolated under `qa/results/2026-09-26-full/isolated/`. The AVD creation tool incorrectly wrote `target=android-0`; correcting it to `android-36.1` restored hardware acceleration and boot.
- A separate synthetic peer account supplies an unlocked match through the actual quest submission/approval APIs; the older fixture remains locked. The persisted-chat test explicitly selects an unlocked match rather than assuming the first match can send messages.

## Final results

| Suite | Latest result | Evidence |
|---|---|---|
| Standard Flutter unit/widget/golden suite | 827 passed | `flutter-final.jsonl` |
| Signed-in screen layout matrix | 531 passed: 530 layouts plus screen inventory guard | `flutter-authenticated-layouts-final.jsonl` |
| Backend Go suite | 481 tests/subtests passed | `backend-final.jsonl` |
| Django control panel suite | 21 passed | `django-initial.log` |
| Live API contracts and mutations | **30 distinct cases passed; 1 failed (age privacy)** | `api-latest.xml`, `api-daily-fresh.xml` |
| Backend compliance | Passed | `backend-compliance.log` |
| Flutter static analysis | No errors or warnings; 377 informational lint findings | `flutter-analyze-final.log` |
| Android device journeys | **43 distinct scenarios passed across batches and focused reruns** | `android-complete.xml`, `android-remaining.xml`, `android-rerun.xml`, `android-empty-final.xml` |

The latest full API run recorded 29 passed, 1 failed (age privacy), and 1 skipped (the primary fixture's daily-prompt edit window had expired). That skipped case passed separately on the fresh peer account. The consolidated total is 30 passes and one confirmed failure, not an all-green API suite.

Android counts use the latest result for each named scenario: 16 retained passes from the first batch, 22 from the remaining batch, seven successful focused reruns, and the final empty-message check. Repeated cases are counted once. This is consolidated evidence across repaired harnesses/builds, not one uninterrupted clean run. Earlier failures and skips remain in their original reports. Account pause/export/deletion/cancellation passed, and lifecycle cleanup restored the synthetic account.

`summary.json` contains per-case evidence links, tool versions, previous/current APK checksums and the consolidated totals. The final APK SHA-256 is `d80146371d33c3c0be27d2b989a10c7f4fc20970fbd07adc38930443893c8a8b`. The final build revalidated sign-in, bio/preferences save-and-reopen, filter apply/reopen and saved slider values, empty-message behavior, persisted chat and report submission. The other device scenarios retain their preceding batch evidence.

The screen inventory contains 53 screens. Both light and dark themes run at 320×568, 360×780, 430×932, 768×1024 and 1024×1366. The normal matrix exercises default/loading/error states; the additional matrix supplies a signed-in profile and uses mock feature data. Neither matrix alone proves complete end-to-end behavior. Runtime/plugin/network errors outside layout are intentionally excluded by that layout harness.

## Preferences and filters covered

| Surface | Automated assertions |
|---|---|
| Dating preferences — basic | Gender selection, empty-selection rejection, age range, distance, serious/verified/hookup switches, save failure and retry, saved values outside slider bounds |
| Dating preferences — advanced | Country/state/city dependency; religion; mother tongue; language; diet preference/type; workout; sleep; travel; political preference; Instagram; hobbies; books; novels; songs; extra-curriculars; additional information; intent tags; pets; deal breakers; preservation of saved education and multiple languages |
| Discovery filters | All nine dropdown controls; age/distance sliders; party, hookup, verified and trust switches; minimum trust badges; all four required badge chips; apply; Reset; Any; reopening; provider rebuild; country dependency; failed save |
| Standalone Trust Filters | Enable, badge count, all badge checkboxes, complete payload, failure without a success message |
| Spotlight | Age and verification actually exclude supplied profiles; Reset restores the deck |
| Conversation rooms | All lifecycle choices and friend-only on/off sent in requests |
| Notifications | All eight switches in both directions, preservation of peers, save rollback and visible error |
| Privacy | Age, exact-distance and online-status switches in both directions; failed save and retry reload |
| Appearance | Light, dark and device theme selections; failed-save rollback |
| Backend advanced filters | Positive and negative candidate cases for 22 inputs, exclusions/deal breakers, combined AND behavior, normalization, actual verification state and leap-year age boundaries |

Widget tests verify payloads and state changes with controlled providers or HTTP interceptors. Live API tests and deterministic backend tests supply separate server-side evidence. This is not a claim that every possible combination of user data or master-data values was exhaustively tested.

## Defects found and corrected

1. Verified-only discovery did not remove unverified candidates.
2. Mother-tongue filtering compared spoken languages instead of the mother-tongue field.
3. Hookup-only ignored the explicit stored boolean; legacy intent-tag compatibility remains supported.
4. Age filtering was incorrect around leap-year calendar boundaries.
5. Saving preferences cleared an existing education filter and truncated an untouched multi-language list.
6. Persisted novels, extra-curricular activities and additional information had no editable controls.
7. Discovery Reset, Any and country changes were undone by repeated seeding from saved preferences. Any also lacked an actual dropdown option.
8. Failed discovery trust saves closed the sheet and applied a partial filter set.
9. Privacy save errors were displayed as if the new value had persisted; load failures silently substituted defaults.
10. Standalone trust saves displayed a success message even after a failed request.
11. Out-of-range saved preference sliders could assert instead of rendering.
12. Signed-in layouts exposed 52 failing size/theme cases across 11 screens. Fixes include bounded action buttons, expanded dropdowns, wrapping profile rows/section headers, bounded date labels, narrow-screen discovery metrics and a scrollable deck when vertical space is insufficient. All 530 signed-in layouts now pass.
13. Short discovery requests could exhaust the initial candidate slice before publication filtering. Candidate overfetch now applies even without manual filters; the requested response limit is retained. This is a bounded pool, not a replacement for eligible-candidate pagination at scale.
14. Trust-badge recomputation attempted to persist `not_earned`, which violates the database status constraint. Durable writes normalize it to `inactive`.
15. Profile draft writes swallowed server errors, so save handlers could claim success after a failed request. They now propagate the failure while retaining edited state for retry; setup Preferences stays on the form if saving on Back fails.
16. Discovery also asserted on an inverted persisted age range. Bounds are now ordered after clamping; a regression reproduced the assertion before the fix.
17. Appium input fallbacks counted both Flutter semantics wrappers and their actual inputs, so a hidden Full name field could overwrite Password. QA hint selectors, keyboard dismissal and deduplicated native inputs fixed signup. Native-text scrolling also skipped lazily rendered labels; incremental page scrolling now checks both text and descriptions.
18. Draft PATCH treated an omitted optional field as explicit null and erased 19 unrelated fields. The backend now distinguishes absence from an intentional clear. Unit tests cover omitted/null/blank/replacement behavior for every affected field, and a live bio-only update preserves location and education.
19. Long device runs reused a single API bearer session beyond its 30-minute expiry. API fixtures now authenticate per test, leaving authorization-negative behavior intact.
20. Flutter draft copies interpreted explicit null as “keep the old value,” so optional values could not be cleared. Nullable edits now distinguish omitted arguments from intentional clears; backend height clearing also preserves unrelated fields.
21. Appium rejected enabled native switches with `clickable=false`. The helper now recognizes enabled, displayed semantic controls. Assertions remain responsible for verifying their resulting state.

Device assertion fixes also removed assumptions about the first match being unlocked and Send being disabled for an empty composer. The tests now select an approved synthetic match, verify no empty message is persisted, and require the explicit report-submission acknowledgement.

Phone and tablet discovery golden images were visually compared before updating the references for the intentional metric layout change. Golden text uses Flutter's test font; these are geometry checks, not typography acceptance.

## Open release gaps

| ID | Priority | Finding and required work |
|---|---|---|
| QA-01 | High | Discovery sends `max_distance_km`, but the matching/BFF path has no distance-enforcement implementation. Slider rendering and request serialization pass; geographical eligibility does not have acceptance coverage. Implement consented location storage and distance filtering with known near/far fixtures. |
| QA-02 | High | Saved partner preferences are not consistently applied on initial discovery. Manual filter state starts empty; the candidate service receives user ID and limit, and saved seeking-gender/serious-only preferences are not enforced by the advanced criteria. Add default preference enforcement and explicit override/reset semantics with positive/negative fixtures. |
| QA-03 | Medium | Candidate overfetch is capped at 300. Large datasets need filtering/pagination at the repository/query boundary to avoid empty or underfilled pages after eligibility checks. |
| QA-06 | High | Privacy enforcement defect confirmed with two synthetic accounts: `show_age=false` persists, but the public profile API still returns `date_of_birth` to the other account. Apply visibility settings in public/discovery projections and support hidden age in client models. Evidence: `isolated/privacy-enforcement-check.json`, `privacy-release-blocker.xml`; automated in `test_16_privacy_preferences_api.py`. |
| QA-08 | Medium | Preference bounds differ across surfaces: setup allows age 18–60/distance 1–200, discovery allows 18–70/1–500, while FRD PROF-005 describes historical age bounds up to 80. Clamping avoids a crash but can change previously saved values. Resolve and centralize the intended limits, then verify cross-screen round trips. |
| QA-07 | Medium | About-screen Back still uses asynchronous autosave and preference edit Back can discard unsaved changes. Save/retry coverage does not certify durable persistence on every navigation path; finish the existing autosave/navigation work. |
| QA-05 | Acceptance | Real FCM/APNs delivery, payment provider flows, camera/ID verification providers, physical devices, other Android API levels, iOS, TalkBack/large-font accessibility and release-build/store behavior have not been certified by this local Android run. |

## Requirement traceability and priority

- **First: privacy enforcement (QA-06)** — PEN-05/PEN-14, SAFE-007/PROF-015. Successful settings persistence is insufficient until public responses and client rendering honor it.
- **Then: discovery eligibility (QA-01/QA-02)** — DISC-001/PROF-005. Location storage/consent and saved-preference semantics are dependencies of filter acceptance.
- **Then: save/navigation and consistent bounds (QA-07/QA-08)** — PEN-18, PROF-003/PROF-005. Existing failures now surface correctly; navigation durability and a shared bounds contract remain open.
- **Before release: external device/provider acceptance (QA-05)** — local deterministic tests and layout checks do not replace these gates.

## Repeatable commands

Run from the repository root, with the native backend and emulator available:

```sh
(cd app && flutter test --no-pub)
(cd app && flutter test --no-pub --dart-define=USE_MOCK_AUTH=true --dart-define=QA_SCREEN_FIXTURES=true test/features/responsive/screen_matrix_test.dart)
(cd backend && PROFILE_TEST_DATABASE_URL='postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable' go test ./...)
(cd control-panel && .venv/bin/python manage.py test)
QA_EXISTING_USERNAME=qa_full_20260926_isolated \
  QA_PUBLIC_PROFILE_VIEWER_USERNAME=qa_peer_20260926_isolated \
  QA_ENABLE_MUTATING_MATRIX=true .venv/bin/python -m pytest qa/appium/tests -m 'not requires_appium'
ANDROID_DEVICE_NAME=emulator-5556 APPIUM_SERVER_URL=http://127.0.0.1:4725 APPIUM_SYSTEM_PORT=8201 \
  QA_EXISTING_USERNAME=qa_full_20260926_isolated QA_ENABLE_MUTATING_MATRIX=true \
  .venv/bin/python -m pytest qa/appium/tests -m requires_appium -vv
```

The device command assumes a separate Appium server is running on port 4725 and the current ARM64 QA APK is installed on emulator-5556. Set `QA_REPORT_DIR`, `QA_ARTIFACT_DIR` and `QA_MATRIX_RESULTS_PATH` to unique paths when running alongside another task. Use `flutter build apk --debug --split-per-abi --target-platform android-arm64 --dart-define=API_BASE_URL=http://10.0.2.2:18080/v1 --dart-define=ENABLE_QA_AUTOMATION=true` from `app/`, then install `app/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` with adb. Device fixtures reset this app's local data between tests and use synthetic QA accounts. The release regression script now includes the signed-in layout matrix.

## Screen layout evidence

Each row below passed five sizes in both themes. These are layout assertions; use the control coverage and Android journey results above for interaction evidence.

| Screen | Signed-in layout checks passed |
|---|---:|
| `WelcomeScreen` | 10/10 |
| `AuthScreen` | 10/10 |
| `SignupScreen` | 10/10 |
| `UserAgreementScreen` | 10/10 |
| `CallHistoryScreen` | 10/10 |
| `CallSessionScreen` | 10/10 |
| `AboutAppScreen` | 10/10 |
| `BlockedUsersScreen` | 10/10 |
| `EmergencyContactsScreen` | 10/10 |
| `HelpSupportScreen` | 10/10 |
| `MainNavigationScreen` | 10/10 |
| `ModerationAppealsScreen` | 10/10 |
| `NotificationSettingsScreen` | 10/10 |
| `AccountDataScreen` | 10/10 |
| `PrivacySafetyScreen` | 10/10 |
| `SettingsScreen` | 10/10 |
| `CircleChallengesScreen` | 10/10 |
| `CommunityGroupsScreen` | 10/10 |
| `ConversationRoomsScreen` | 10/10 |
| `DailyPromptScreen` | 10/10 |
| `EngagementHubScreen` | 10/10 |
| `GroupCoffeePollsScreen` | 10/10 |
| `LevelProgressionScreen` | 10/10 |
| `MatchNudgesScreen` | 10/10 |
| `TrustBadgesScreen` | 10/10 |
| `TrustFilterScreen` | 10/10 |
| `VoiceIcebreakersScreen` | 10/10 |
| `FriendsScreen` | 10/10 |
| `ActivitySessionScreen` | 10/10 |
| `MatchNotificationScreen` | 10/10 |
| `MatchesListScreen` | 10/10 |
| `ChatScreen` | 10/10 |
| `NotificationInboxScreen` | 10/10 |
| `SubscriptionScreen` | 10/10 |
| `WalletPaymentScreen` | 10/10 |
| `EditProfileScreen` | 10/10 |
| `ProfileViewScreen` | 10/10 |
| `ProfileViewersScreen` | 10/10 |
| `ProfileSetupEntryScreen` | 10/10 |
| `SetupAboutScreen` | 10/10 |
| `SetupPhotosScreen` | 10/10 |
| `SetupPreferencesScreen` | 10/10 |
| `SetupPreviewScreen` | 10/10 |
| `SosScreen` | 10/10 |
| `HomeDiscoveryScreen` | 10/10 |
| `LikedProfilesScreen` | 10/10 |
| `PassedProfilesScreen` | 10/10 |
| `ProfileDetailsScreen` | 10/10 |
| `SpotlightProfilesScreen` | 10/10 |
| `VerificationLandingScreen` | 10/10 |
| `VerificationSelfieScreen` | 10/10 |
| `VerificationStatusScreen` | 10/10 |
| `VerificationUploadIdScreen` | 10/10 |
