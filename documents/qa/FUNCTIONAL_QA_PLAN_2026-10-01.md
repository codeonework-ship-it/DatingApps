# Functional QA plan: Connect (2026-10-01)

**Scope:** functional coverage of the member product and the operator tools on five surfaces:

- the Android app (Flutter);
- the Flutter web member app (`/app/`);
- the public website;
- the Go API (gateway at `:18080` → BFF at `:18081`);
- the Django operator console.

**Out of scope for this pass:**

- The support ticket system (migration 126, help & support screen, console support pages, website contact page) is still being built.
- The rich-text chapter/story editor (migration 127, `blog_editor.dart` and the related files) is also still being built.

The coordinator will QA both once they are finished. Reading and reacting to chapters stays in scope. Composing with the rich editor does not.

## Approach

1. **The API end-to-end suite is the backbone.** It is in `qa/api_e2e`. Every member journey runs through the public gateway, exactly as the apps call it. The suite creates its own members through the real signup journey, and it retires them afterwards (deletion requested and the account deactivated). It never signs in as the shared device account (`qa_full_20260926_isolated`), so it can't sign out the emulator or a browser session.
2. **UI suites cover each surface's own behaviour:**
   - navigation;
   - rendering of real data;
   - back-button rules;
   - theme and settings persistence;
   - responsive layout and accessibility.

   The UI suites seed counterpart actions (friend requests, invites) through the API, and they check persisted state through the API instead of trusting the UI.
3. **Console smoke** logs in as a provisioned local operator. It finds every page from the rendered sidebar, so new pages are covered automatically. Each page must load without errors and show data or a real empty state.
4. **Regression suites** (Flutter widget, Go, Django, governance) run unchanged. Each failure is triaged as a product bug, a test bug or an environment problem.
5. **Triage rules:**
   - Fix test bugs.
   - Fix product bugs only when they are small, clearly scoped and outside the in-progress workstreams, and add a regression test for each one.
   - Document everything else with repro steps, expected vs actual, severity and the suspected file.
   - A known open defect may be marked `xfail(strict=True)` with its defect ID, so the test turns red when the bug is fixed. Never hide a failure, and never use hidden semantics labels or fake data.

## Priorities and risk

| Priority | Meaning |
|---|---|
| P0 | Sign-in, safety or data integrity. A failure blocks release. |
| P1 | Core member journey (dating loop, chat, social). |
| P2 | Engagement or retention feature. |
| P3 | Cosmetic, operator convenience or polish. |

## Feature × platform matrix

| # | Feature | Pri | Risk | Android (Appium) | Web app `/app/` (Playwright) | Website (Playwright) | Console (smoke) | API (api_e2e) |
|---|---|---|---|---|---|---|---|---|
| 1 | Signup, sign-in, logout, session revocation, validation | P0 | Account takeover, broken onboarding | existing test_01/01b | sign-in + route guard | – | operator login, CSRF, `next=` | test_01 |
| 2 | Authorization: cross-member access, actor spoofing | P0 | Data leak | – | – | – | role gating | test_01, 02, 03, 04 |
| 3 | Profile view/edit/publish, photos | P1 | Stale or unpublished data | existing test_02/05 | profile route | – | user detail | test_01 |
| 4 | Discovery, liked-me, swipe, match | P1 | Empty deck, wrong gender | existing test_03/06/13 | discover route | – | – | test_02 |
| 5 | Quest unlock + match chat, previews, read state | P1 | Locked/unsent chat, bad previews | existing test_04/08/13 | chat route | – | – | test_02 |
| 6 | Safety: block/unblock, report, unmatch | P0 | Harassment exposure | existing test_12 | – | – | moderation queues | test_02, 05, 06 |
| 7 | Notifications: inbox, unread, read/dismiss, preferences | P1 | Noise or missed matches | – | – | – | queue metrics | test_02, 08, 01 |
| 8 | Today screen, wall, Cover of the Week, celebrations | P2 | Empty or broken home | new test_24 | feed route | – | photo themes | test_06 |
| 9 | Open Chapters: topics, scopes, follow, top rated, report | P2 | Private content leak | – | blog route | blog-public.spec | blog moderation | test_06 |
| 10 | Empathetic reactions (chapters and photos) | P2 | Wrong counts | – | – | – | – | test_06 |
| 11 | Photo Themes: entry, one per theme, comments approval | P2 | Unmoderated media | – | – (photos open, WEB known) | – | photo themes | test_06 |
| 12 | Book & Film Clubs: club, picks, posts, reviews | P2 | Spoilers, membership leak | – | – | – | – | test_06 |
| 13 | Friends: search, opt-out, request/accept/decline, sources, remove | P1 | Privacy (search opt-out) | new test_19 | friends route | – | – | test_03 |
| 14 | Friend chat: send, idempotency, unread/read, mute, delete | P1 | Lost or duplicate messages | new test_19 | – | – | – | test_03 |
| 15 | Conversation Rooms: directory, create, join, live chat, host mute/remove/close, leave | P1 | Abuse in live rooms | new test_20 | rooms route | – | rooms + members | test_04 |
| 16 | Lifestyle groups: create from friends, invite, join, roles, group chat, report, leave, delete | P1 | Private group leak | new test_21 | groups route | – | group covers | test_05 |
| 17 | Themes (Snow, Gothic, cinematic), reward bursts, Settings theme strip | P2 | Unreadable contrast | new test_23 | settings route | theme.spec | – | test_01 (`settings.theme`) |
| 18 | Back-button: Matches/Engage/Profile/Settings → Today | P1 | Accidental app exit | new test_22 | browser back | – | – | – |
| 19 | Privacy & safety: crash-report switch, friend-search visibility, online status | P0 | Consent | new test_23 | settings route | – | – | test_01, 03 |
| 20 | Client error reporting (ingest, validation, size limits) | P1 | Missing crash data or abuse | – | console errors on pages | console errors | client errors page | test_07 |
| 21 | Console pages: rooms, group covers, client errors, analytics, business, billing | P1 | Operator blind spots | – | – | – | console_smoke | – |
| 22 | Website public pages × all locales: nav, links, hreflang, a11y, responsive | P1 | SEO and broken funnel | – | – | public-pages and related specs | – | – |

## Environment risks

- The gateway rate-limits per IP: 120 requests per second, shared by every local client. The API suite paces itself at 20 ms per request and honours 429 responses.
- Local Postgres sometimes hits `Interrupted system call` (EINTR) on `open()`, which once crashed it (see ENV-02 in the report). Transient 503s line up with these log entries.
- Several helper scripts still default to port 55432, which belongs to another project (see ENV-01).
- The BFF build is broken while the support workstream is mid-edit, so backend fixes in the BFF can't be deployed to the live stack until it builds again.

## Exit criteria

- Every P0/P1 journey passes in api_e2e and in at least one UI suite.
- No open S1 or S2 product defects without an owner.
- Regression suites are back at their recorded baseline, or better.
