# Functional QA report: Connect (2026-10-01)

This report covers the plan in [FUNCTIONAL_QA_PLAN_2026-10-01.md](FUNCTIONAL_QA_PLAN_2026-10-01.md).

**Stack under test:**

- gateway `:18080`, BFF `:18081`
- Postgres `:55433`
- website and web app `:4190`
- emulator `emulator-5556`
- console on its own runserver at `:8765`

**Excluded:** the support ticket system and the rich-text chapter editor. Both are still being built.

Raw evidence (junit, screenshots, JSON page reports) is under `qa/results/` and is gitignored.

## 1. Results by suite

| Suite | Location | Result |
|---|---|---|
| API end-to-end (new) | `qa/api_e2e` (8 modules) | **94 pass, 0 xfail** after the defect fixes and the stack restart on 2026-10-02 (the API-02 xfail is now a passing regression test). Before the fixes: 93 pass, 1 strict xfail, green on 4 of 5 runs; the bad run had 3 errors from ENV-02. A further API-05 regression test was added after that run; `test_06` passes with it (19 pass). |
| Console live smoke (new) | `qa/console_smoke` | 55 pass, 2 fail (CON-01 waiting on a BFF restart; ENV-02 intermittent), 1 skip (support pages) |
| Django | `control-panel` | **173 pass, 0 fail** after the CON-03/04/05 fixes (16 new tests). Before: 125 pass, including 3 new tests for CON-02. |
| Go | `backend` | **All packages pass** on 2026-10-02 with `PROFILE_TEST_DATABASE_URL` on 55433. This includes the graduation test that GO-01 broke. `go build ./...` and `go vet ./internal/... ./cmd/...` are clean, and `scripts/check_backend_compliance.sh` passes (QA-03). The first full run that day failed on connections only: Postgres PANICked mid-run (ENV-02); the rerun was green. |
| Flutter widget | `app/test` | Before: 1770 pass, 27 fail (the baseline). After triage: 1891 pass, 3 fail (2 discover goldens needing review, FLT-05; Support screens missing from the screen matrix, owned by the support workstream). |
| Governance contract gate | `qa/governance` | Passes after 2 stale anchors and 1 evidence path were fixed. Release status is still NO_GO, as designed. |
| Website and web app Playwright | `website/tests` | Agent still running when this report was written. Results pending. |
| Android Appium | `qa/appium/tests` | Agent still running when this report was written. Results pending. |

## 2. Defects

Severity scale: S1 blocker, S2 major, S3 moderate, S4 minor.

### Fixed (each has a regression test)

| ID | Sev | Defect | Fix | Regression test |
|---|---|---|---|---|
| API-01 | S2 | Every new match without messages showed the preview `"<nil>"` in the Matches list on Android and web. The cause: the matching service's `toString(nil)` used `fmt.Sprintf("%v")`, and the app's `_cleanText` doesn't strip `<nil>`. | `backend/internal/services/matching/service.go`: `toString(nil)` now returns `""`, so the "Say hi 👋" fallback applies. `matching-svc` was rebuilt and restarted, and the fix is verified live. | `internal/services/matching/list_matches_preview_test.go`; `qa/api_e2e/tests/test_02::test_new_match_lists_friendly_preview_not_nil` |
| CON-01 | S2 | NUMERIC columns leaked the Go struct text, e.g. `"{499 -2 false finite true}"` for billing prices. This affects every NUMERIC read through `postgresdata`, including SOS lat/long, which became 0. | `backend/internal/platform/postgresdata/client.go` (`normalizeNumeric`). Live since the stack restart on 2026-10-02. | `postgresdata/numeric_test.go` |
| CON-02 | S4 | Console `/users/<unknown uuid>/` returned 200. | It now returns 404 (`control-panel/control_panel/views.py`, `user_detail`). | `control_panel/tests/test_user_detail.py` |
| FLT-01 | S3 | The chat load-error state overflowed: by 28px at 320×568, and by 159px at 1.3× text. The Retry button was clipped. | `chat_screen.dart`: the error block now scrolls. | Existing ChatScreen screen-matrix cases |
| FLT-02 | S4 | 13 off-grid spacing literals came in with commit 2fb572180. | Rounded to the grid in 6 files. | `spacing_grid_test` |
| API-02 | S3 | A match quest review that broke a business rule returned 502, which the gateway shows as "temporarily unavailable". Examples: the submitter reviewing their own response, or a review sent after approval. The cause: the BFF mapped only `ErrValidation`, and the quest store returned plain `errors.New`. | New `backend/internal/bff/mobile/quest_errors.go` adds typed rule errors that carry an HTTP status and an `error_code`. `quest_repository.go` and `store.go` return them. The in-memory store also refuses a self-review now. The quest template, submit and review handlers and both gesture handlers in `server.go` use `writeQuestWorkflowRuleError`. Codes: self-review 403 `QUEST_SELF_REVIEW`; not pending 409 `QUEST_NOT_PENDING`; nothing submitted 404; cooldown 409; rate limit 429; wrong response length 400; not a match participant 403. Infrastructure errors stay 502. | `quest_errors_test.go` (`TestServer_QuestReviewRuleViolationsAreClientErrors`, `TestQuestWorkflowErrorStatus_WrappedErrorsKeepTheirStatus`). `server_quest_workflow_test.go` now expects 409 for cooldown and 429 for rate limit. The strict xfail is removed: `qa/api_e2e/tests/test_02::test_quest_review_by_the_submitter_is_a_client_error` passes live. |
| GO-01 | S3 | Graduation never notified opted-in friends. Migration 099 made date plans private and turned `matching.date_plan_share_recipients` into a fail-closed stub. `notify_graduation` (094) still used it. | Migration **128** `scripts/128_graduation_friend_recipients.sql` is registered in `scripts_run_order.txt` and `migrate_local_postgres.sh`, and applied to 55433. It adds `matching.graduation_share_recipients(member, partner)`: the member's accepted friends, never the partner, never inactive or banned accounts, and never a pair blocked in either direction. `notify_graduation` is repointed to it; the body is otherwise identical to 094. Graduation's per-event `share_with_friends` choice is the explicit consent that 099 requires (ENG-010). The date-plan function stays fail-closed, and friend groups aren't included because graduation never offered a group choice. | `TestGraduationConfirmHidesBothAndTellsOptedInFriendsPostgres` passes. New `graduation_recipients_test.go` covers partner, pending request, block in either direction, inactive account, and the date-plan stub staying closed. |
| GO-02 | S3 | `GET /v1/admin/users/{id}/wallet` wrote to the database. It created a `user_wallets` row, and for an unknown id it returned 200 while the `user_wallets` insert and the request-telemetry `activity_events` insert failed their foreign keys. | `adminGetWalletBalance` returns 404 `member not found` for an unknown or malformed id, then reads through the new side-effect-free `roseGiftRepository.readWallet` / `runtimeStore.readWalletCoins`. A member with no wallet reads as a zero balance. Request telemetry (`apiRequestActivityEvent`) no longer attributes a 404 to the id in the path. **A follow-up is in code but not yet live:** the same function stopped using a match id as `user_id`. That fallback was failing the users foreign key on every match route, which was seen in `postgres.log` after the restart. It goes live at the next BFF restart. | `admin_wallet_read_test.go`: `TestAdminGetWalletBalance_IsReadOnlyAnd404sUnknownMembers` (counts writes), `TestApiRequestActivityEventDropsUserForNotFound`, `TestApiRequestActivityEventNeverUsesAMatchIDAsTheMember` |
| API-03 | S4 | `GET /v1/walls/today` locked the member's `users` row (`lockBlogAuthor` … `FOR UPDATE`), so a write holding that row turned the read into a lock-timeout 503. | `today_wall.go` changes: <br>• The member check is now a plain `EXISTS` (no lock). <br>• The first-of-day choice is serialised per member and day with `pg_try_advisory_xact_lock`. <br>• The insert runs under a savepoint; a `55P03` lock timeout rolls back to it. <br>• If another request is choosing, or the insert can't get its locks, the request serves the same ranking read-only without persisting. A later request persists the day's choice, and the day then stays stable. | `today_wall_contention_test.go` `TestTodayWallDoesNotBlockOnMemberRowPostgres` covers three cases with `lock_timeout=300`: the row held `FOR UPDATE`, a concurrent first pick, and the uncontended path that persists and stays stable. The existing `TestTodayWallPicksViewsAndCoverPostgres` still passes. |
| API-04 | S4 | A DELETE without a JSON body answered with the raw decoder error `"EOF"`. | `readJSON` (`server.go`) treats a missing or empty body (and `null`) as `{}`, so the handler names the field it needs, e.g. "A current expected_version is required". A malformed body now gets "request body is not valid JSON" or "request body must be a JSON object". Raw decoder errors are never returned. | `read_json_test.go` `TestReadJSONEmptyBodiesAndReadableErrors`; `qa/api_e2e/tests/test_06::test_title_review_rating_validation` asserts the message names `expected_version` and contains no `EOF` |
| API-05 | S4 | Social and blog payloads used the server's local offset (`+05:30`), while matches and notifications used `Z`. The cause: pgx decodes `timestamptz` into `time.Local`, and SQL that renders timestamps as text uses the session TimeZone, which was the server's `Asia/Kolkata`. | New `backend/internal/platform/postgresdata/utc.go`. Every connection opened through `postgresdata` (`Open` and `OpenSQL`) runs with session `TimeZone=UTC`, unless the database URL sets a zone, and decodes `timestamptz` in UTC. Every API timestamp is now RFC 3339 UTC (`…Z`). Clients already parse both forms. The UTC session also makes SQL `CURRENT_DATE` match the product's UTC days. | `postgresdata/utc_test.go` (`TestSQLConfigRunsSessionsInUTCUnlessTheURLChoosesAZone`, `TestTimestamptzIsUTCOnBothConnectionTypesPostgres`, both connection types); `qa/api_e2e/tests/test_06::test_blog_timestamps_are_utc` (live) |
| CON-03 | S4 | Raw database errors (`SQLSTATE …`) appeared in console banners. | One helper, `operator_error_message()` in `control_panel/services/go_client.py`, is applied inside the BFF client, so every view and banner is covered without per-view edits. <br>• Readable 4xx messages (validation, 403, 404, 409, 429) still show as written. <br>• 5xx errors, transport failures, invalid JSON, and anything that looks like a database or runtime error (SQLSTATE, `pq:`, `violates`, `lock timeout`, `panic`) become a generic message with the correlation id as a reference. <br>• The raw detail is logged server-side with method, path, status and correlation id. | `control_panel/tests/test_bff_errors.py` |
| CON-04 | S4 | User detail listed only the member's transactions that were among the latest 20 platform-wide. | BFF: `GET /v1/admin/billing/transactions` accepts `user_id` (UUID-validated, 400 otherwise) and filters by it. Console: `list_billing_transactions(user_id=…)` sends it, and `user_detail` asks for this member's rows. As a defence, it still drops any row for another member and shows a "may be incomplete" note if it had to. | `admin_transactions_filter_test.go` `TestAdminListBillingTransactionsFiltersByMember`; `control_panel/tests/test_user_detail.py` (`UserDetailTransactionsTest`, `GoClientTransactionsFilterTest`) |
| CON-05 | S4 | The sidebar wasn't filtered by role; analysts saw links that lead to 403s. | New `control_panel/operator_access.py`: <br>• `can_access_admin_route()` mirrors Go's `principalCanAccessAdminRoute`. <br>• `NAV_ITEMS` maps each sidebar link to the admin reads it makes, and the `operator_nav` context processor hides a link, or a whole section, when Go would refuse it. <br>• Roles are resolved once at login, because Go doesn't expose an operator's roles; see the follow-up below. If they can't be resolved, the full sidebar shows, as before. <br>Result: an analyst sees 24 of 42 links; an admin sees all 42. | `control_panel/tests/test_sidebar_roles.py` |
| QA-03 | S4 | `scripts/check_backend_compliance.sh` failed because `cmd/mediactl` had no structured logger. | `cmd/mediactl/main.go` bootstraps `observability.NewLogger` (`ENVIRONMENT`, `LOG_LEVEL`). Start, finish (with exit code) and failure events go to stderr; stdout stays the human-readable report. | `scripts/check_backend_compliance.sh` passes |
| OBS-01 | Info | A member created by `verify_signup_workflow.sh` had no intent tags. Everyone's deck defaults to `serious_only=true`, which drops candidates without a serious intent tag, so that member was never dealt. | **Test data, fixed here.** The script sets `intent_tags:["long_term"]` before `/complete` (the publish step), as `qa/api_e2e` already does. It now asserts the tag is stored. Verified live with a new member (`obs01_…`, left in the local database like every run of this script). The product side is listed below as an open product decision. | `backend/scripts/verify_signup_workflow.sh` (self-asserting) |

### Open product decisions

The defects listed open on 2026-10-01 (API-02 to API-05, GO-01, GO-02, CON-03 to CON-05, QA-03) are fixed above. These are product calls, not code defects:

| ID | Sev | Finding | Why it is still open |
|---|---|---|---|
| OBS-01 (product) | Info | In the app, intent tags are an optional free-text field ("Intent tags (long-term, marriage, casual…)") on the preferences step, and "Serious relationship only" defaults to on for every viewer. A real member who leaves intent empty is filtered out of every default deck. Intent edits after completion only take effect on re-publish (`/complete`). | The fix is a product choice. One option is to require a relationship intent at onboarding. The other is to treat an unspecified intent as eligible under `serious_only` (`server_advanced_filters.go`). Either changes discovery behaviour for real members, so the founder should decide. The seed-script part is fixed above. |
| CON-05 follow-up | Info | The console works out an operator's roles at login by probing three admin reads, because Go doesn't expose them. `operator_access.py` copies Go's route rule. | Returning `roles` from `POST /v1/auth/login`, or adding `GET /v1/admin/me`, would remove the probes. Until then, `can_access_admin_route` must change whenever `principalCanAccessAdminRoute` changes. Go still enforces every request. |

Already known and being fixed elsewhere, so not duplicated here:

- web Photo Theme / Cover photos don't render;
- the web app doesn't return to sign-in after a 401.

### Environment findings

| ID | Sev | Finding |
|---|---|---|
| ENV-01 | S2 | `backend/scripts/provision_local_operator.sh` and `provision_local_qa_viewer.sh` default to port **55432**, which is another project's live database. `run_release_regression.sh` and `qa/admin/run_admin_control_plane_gate.sh` call them without a database URL. The one-line fix (default to 55433) **was denied by the permission system and has not been applied**; the owner needs to apply or approve it. Other scripts also default to 55432. |
| ENV-02 | S2 (local) | Local Postgres 17 on 55433 hits `could not open file …: Interrupted system call` (more than 60 times since 20:56). At 23:39:55 this PANICked on a WAL file and Postgres crash-recovered. Every transient 503 seen in this pass lines up with these log lines (`backend/.run/postgres.log`). The disk is 93% full. |
| ENV-03 | Info | The gateway rate-limits per IP: 120 requests per second, and every local client shares 127.0.0.1. The API suite paces itself and retries on 429; the last runs had 0 throttled requests. |

## 3. What was tested

**API e2e (`qa/api_e2e`):** each run creates about 40 members through the real signup journey (username `e2e_<run>_<role>`) and retires them at the end (deletion requested and the account deactivated). Module teardowns delete or close the content they create.

- **test_01 (auth and profile):**
  - signup workflow and login;
  - wrong and unknown credentials give the same 401;
  - duplicate username;
  - signup validation;
  - 401 without a session;
  - 403 on other members' resources;
  - draft → publish round trip;
  - photos served;
  - logout revokes the token;
  - `settings.theme` round trip (`light:snow`, `dark:gothic`, `auto`) and the online-status privacy toggle;
  - notification preferences;
  - account lifecycle.
- **test_02 (dating loop):**
  - discovery shows both members and respects seeking gender;
  - a like appears in liked-me;
  - a mutual like creates a match, and the matched pair leaves each other's deck;
  - preview regression (API-01);
  - chat locked (423) → quest unlock → messages, with previews;
  - sender spoofing gives 403;
  - like and match notifications, unread count, read-all;
  - mark-read;
  - block hides the member from discovery and friend search, unblock restores;
  - unmatch.
- **test_03 (friends):**
  - search fields, `@` prefix, minimum query length;
  - search-visibility opt-out (hidden from search, but still requestable from a profile);
  - outgoing and incoming → accept;
  - invalid source and decision;
  - decline;
  - befriending yourself;
  - friend chat: idempotent `client_message_id`, unread/read, mute 8h / forever / invalid / unmute;
  - message validation;
  - outsiders can't open the chat;
  - deleting your own message;
  - removing a friend closes the chat.
- **test_04 (rooms):**
  - directory and categories;
  - create (the creator is host) and create validation;
  - join → live chat → members/presence;
  - outsiders can't read the chat;
  - host mute → `CHANNEL_READ_ONLY` → unmute;
  - guests can't moderate;
  - notification mute;
  - leave revokes access;
  - actor spoofing;
  - host removes a member;
  - host closes the room, which leaves the directory.
- **test_05 (groups):**
  - group-friends list;
  - create a private group with an invitee (owner and channel);
  - the name is required;
  - invite → accept;
  - non-members are locked out;
  - group chat;
  - invite → decline;
  - roles: moderator, member, invalid action, and moderators can't remove the owner;
  - report (invalid and valid reason);
  - leave revokes chat;
  - public community group: discover → join → chat → owner removes the member → delete;
  - scope validation;
  - owner deletes the group.
- **test_06 (content):**
  - topics;
  - publish validation;
  - community / topic / private scopes;
  - empathetic reactions (switch, plain like keeps the reaction, invalid → 400, remove);
  - comments need author approval;
  - follow a writer and the subscriptions feed, including following yourself (403);
  - top rated and featured feeds;
  - report a chapter;
  - Photo Themes: upload validation (caption, 415), entry listed and photo served, one entry per theme (409), reactions, comment approval;
  - wall and Cover of the Week;
  - Today wall, celebrations and views;
  - Clubs: create, pick a title (Mondays only), join, outsider post → 403, discussion post, members, membership validation, leave;
  - review rating validation and delete.
- **test_07 (client errors):**
  - anonymous, signed-in and invalid-token reports are accepted;
  - malformed batches → 400;
  - more than 64 KB → 413;
  - invalid events are dropped and counted.
- **test_08 (notifications):**
  - friend request received and accepted;
  - group invite;
  - mark one read and dismiss;
  - the likes preference.

**Console smoke (`qa/console_smoke`):**

- logged-out redirects, CSRF, open-redirect `next=`;
- all 8 key pages are in the sidebar;
- every sidebar page (38) loads with no traceback or struct leak and shows a table or empty state;
- detail pages for a room, a client error and a user;
- 404s for missing records;
- CSV exports.

**Website, web app and Android:** see sections 1 and 4. Those agents had not finished when this report was written.

## 4. Coverage gaps

- **Pending:** the Playwright results (public pages × locales, links, a11y, responsive, `/app/` routes) and the Appium results for the new Android features (friends, rooms, groups, back navigation, settings theme and privacy, Today). Those agents were still running when this report was written.
- **Not tested:** the support ticket system, rich-text chapter/story composition, operator write actions in the console, and admin APIs for client errors, group covers and photo themes beyond page loads.
- **The API suite doesn't cover:** realtime websockets (`/realtime/*`), gifts and wallet, date plans, graduation, vouches and intros, copilot, billing, group covers upload, media moderation flows.
- **Fixes not yet live:** CON-01 and the 2026-10-02 defect fixes went live with the stack restart on 2026-10-02. One exception: the GO-02 follow-up (request telemetry no longer uses a match id as `user_id`) was made after that restart and goes live at the next BFF restart. The console smoke suite (`qa/console_smoke`) hasn't been re-run since the fixes.
- **Leftover test data:** club catalogue titles can't be deleted through the API. The suite reuses one title, "E2E Fixture Novel".

## 5. How to run each suite

```bash
# API e2e (needs the local stack; uses the repo .venv)
qa/api_e2e/run.sh                      # junit -> qa/results/api_e2e/
E2E_KEEP_MEMBERS=true qa/api_e2e/run.sh tests/test_05_groups.py   # keep members for debugging

# Console smoke (start your own runserver; don't touch :8000)
cd control-panel && .venv/bin/python manage.py runserver 127.0.0.1:8765 --noreload &
CONSOLE_BASE_URL=http://127.0.0.1:8765 .venv/bin/python -m pytest qa/console_smoke -q

# Regression suites
cd control-panel && .venv/bin/python manage.py test
cd backend && PROFILE_TEST_DATABASE_URL="postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable" go test ./... -count=1
cd app && flutter test
QA_RELEASE_REPORT_DIR=$PWD/qa/results/console/governance ./qa/governance/run_release_governance_gate.sh contract

# Website / web app
npm --prefix website test

# Android (emulator-5556, Appium on 4723)
ANDROID_DEVICE_NAME=emulator-5556 APPIUM_NO_RESET=true .venv/bin/python -m pytest qa/appium/tests -m <marker>
```
