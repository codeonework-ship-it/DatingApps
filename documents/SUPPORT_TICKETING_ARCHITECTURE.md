# Support ticketing: architecture (2026-10-02)

The owner's request: members raise an issue in the app, and the command centre (the operator console) receives it.

The system was built in migration 126, but member access stayed switched off by the runtime flag `support_ticketing_enabled`. This document describes the design as the code stands on 2026-10-02. It records the end-to-end check against the local stack, the gaps that were fixed, and what remains.

The operator runbook (statuses, SLA table, how agents work the queue) is `documents/SUPPORT_TICKET_SYSTEM_2026-10-01.md`. This document does not repeat it; it links to it.

## 1. Components

```
 Flutter app (member)            Website (visitor)           Operator console (Django, :8000)
 features/support/*              public/contact.{html,js}    views_support.py, templates/support/*
 Settings › Account › Help       POST /v1/support/contact    live socket "nav" topic (sidebar badge)
        │  /v1/support/*                 │                           │  /v1/admin/support/*
        ▼                                ▼                           ▼
 ┌──────────────────────── mobile BFF (Go, :18081, via gateway :18080) ─────────────────────────┐
 │ securityMiddleware → featureFlagEnforcementMiddleware (support_ticketing_enabled)            │
 │   → idempotency → operator audit → member activity log                                       │
 │ support_tickets.go   member API, contact form, notifications                                 │
 │ support_attachments.go  upload sanitising, private storage, authorised download              │
 │ support_admin.go     queue, detail, claim/assign, replies/notes, canned, merge, bulk,        │
 │                      dashboard, CSV export, agents                                           │
 │ support_worker.go    "support_sla" worker: breaches, auto-close, attachment release,         │
 │                      retention, gauges                                                       │
 └──────────────┬──────────────────────────────────┬───────────────────────────────────────────┘
                ▼                                  ▼
   Postgres schema `support` (migration 126)    matching.notification_outbox → inbox + push
   media store kind support_attachments (private/support/<uploader>/…)
```

| Part | Path |
|---|---|
| Schema | `backend/scripts/126_support_ticket_system.sql`; the foundation gate is `088_support_ticketing_foundation_gate.sql` |
| Member API, contact form, notifications | `backend/internal/bff/mobile/support_tickets.go` |
| Attachments | `backend/internal/bff/mobile/support_attachments.go` |
| Operator API | `backend/internal/bff/mobile/support_admin.go` |
| Worker | `backend/internal/bff/mobile/support_worker.go` |
| Route gate | `backend/internal/bff/mobile/server_feature_flags.go` (`featureFlagForRoute`, `defaultOffFeatureFlags`) |
| Route roles | `backend/internal/bff/mobile/server_security.go` (`principalCanAccessAdminRoute`, `isPublicSecurityPath`) |
| Erasure and export | `account_erasure.go`, `account_lifecycle_repository.go` (section `support_tickets`) |
| App | `app/lib/features/support/` and `app/lib/features/common/screens/help_support_screen.dart` |
| Console | `control-panel/control_panel/views_support.py`, `templates/control_panel/support/`, `live.py` (nav badge) |
| API contract | `backend/internal/platform/docs/openapi.yaml`, tag `support` |
| Tests | Go: `support_tickets_test.go`. Flutter: `app/test/features/support/`. Django: `control_panel/tests/test_support.py` |

## 2. Actors

| Actor | How they reach support | Identity | Where replies arrive |
|---|---|---|---|
| **Member** (signed in) | App: Settings › Account › Help & Support, contextual "Contact support" links, notifications | `requester_member_id`; ticket channel `app` | In the ticket thread in the app, plus an inbox notification and a push |
| **Signed-out person** (cannot sign in, or has no account yet) | App: "Can't sign in?" › "Something else wrong? Contact support"; website: Contact page | Only the email address (and optional name) they type, stored as `contact_email`/`contact_name`. No account is created, found or linked. Channel `website` | By email from the support mailbox. The API sends no email |
| **Support agent** | Console › Support (queue, ticket, SLA dashboard, canned responses) | Operator account with role `support`, `admin`, `ops_admin`, `trust_safety` or `moderator` | — |
| **Analyst** | Console › SLA dashboard only, read-only | Role `analyst` | — |
| **System** | The `support_sla` worker; merge messages | `actor_kind = system` | — |

## 3. Ticket lifecycle

Statuses: `new → open → pending_member ⇄ open → on_hold → resolved → closed`.

- **Created** as `new`, with SLA due times set from its category and priority.
- **Claim** (or the first public reply) assigns the ticket to that agent. Claiming moves a `new` ticket to `open`.
- **A public agent reply** to a `new` or `open` ticket moves it to `pending_member`, unless the agent picks a status. While the ticket is `pending_member`, the resolution clock is paused.
- **A member reply** moves `pending_member`, `resolved` and recently `closed` tickets back to `open`.
- **Resolved:** the member can rate it (CSAT, 1–5, once). After 7 days with no member reply, the worker auto-closes it.
- **Closed:** the member can reopen it, or reply to it, for 14 days. After that they start a new request.
- **Merge:** only tickets from the same requester can be merged. The source ticket closes with `merged_into_id` set, and its messages and attachments move to the target.
- **Event trail:** every change is written to `support.ticket_events`. The table is append-only; a trigger refuses UPDATE.

Members see five states:

| Status | Member sees |
|---|---|
| `new`, `open` | Open |
| `pending_member` | Waiting for you |
| `on_hold` | On hold |
| `resolved` | Resolved |
| `closed` | Closed |

## 4. Categories, priorities and teams

The server owns the closed list of categories. Each category sets the team and the starting priority (`supportCategories`).

| Category | Team | Starting priority |
|---|---|---|
| account_login | general | normal |
| verification | trust_safety | normal |
| payments_billing | billing | normal |
| safety_harassment | trust_safety | **high** (SLA capped at 1 h / 24 h) |
| matches_chat | general | normal |
| technical | technical | normal |
| feature_request | general | low |
| privacy_data | privacy | normal |
| other | general | normal |

- **Priorities:** low, normal, high, urgent.
- **Teams:** general, trust_safety, billing, privacy, technical.
- **Category change:** an agent's change re-routes the team and recomputes the SLA. A move into the safety category raises the priority to at least high.
- **New, 2026-10-02:** `GET /v1/support/categories` returns the categories in display order with English labels, plus the limits the server enforces. The app offers only the categories the server lists, showing its own localized labels, and falls back to its built-in list if the call fails.

## 5. SLA targets and the worker

| Priority | First response | Resolution |
|---|---|---|
| urgent | 1 h | 8 h |
| high | 4 h | 24 h |
| normal | 24 h | 72 h |
| low | 48 h | 7 days |

- **Clock:** calendar time, measured from creation. Safety tickets are capped at 1 h first response and 24 h resolution.
- **States:** "at risk" means less than a quarter of the target window is left. Breaches are *latched* in `first_response_breached` and `resolution_breached`, so they never clear.
- **The `support_sla` worker** (`support_worker.go`) runs every 5 minutes, whether or not the flag is on. Each run it:
  - latches breaches and writes `sla_breached` events;
  - auto-closes tickets that have been resolved for 7 days;
  - deletes attachment bytes that are marked deleted, and unattached uploads older than 24 h;
  - purges tickets past retention (section 10);
  - refreshes the gauges;
  - beats the `support_sla` heartbeat.

## 6. Attachments

- **Upload first:** `POST /v1/support/attachments` (multipart). The returned id is then passed in `attachment_ids` on the create or reply call.
- **Allowed files:**
  - JPEG or PNG up to 8 MB and 8000 px per side; PDF up to 10 MB.
  - At most 5 per message and 20 per ticket.
  - A member may upload 30 files per hour and hold 20 unattached uploads.
- **Type check:** the type is sniffed from the bytes. The declared type and the filename are ignored.
- **Sanitising (the "scan"):**
  - Images are decoded and re-encoded, which drops EXIF and GPS data and anything appended to the file.
  - PDFs must end in `%%EOF`.
  - PDFs are refused if they carry active content: `/JavaScript`, `/JS`, `/Launch`, `/EmbeddedFile`, `/OpenAction`, `/AA`, `/RichMedia`, `/XFA`, `/SubmitForm` or `/ImportData`. The check also looks inside Flate streams and decodes `#xx` name escapes.
  - **There is no antivirus engine** (see gaps).
- **Storage:** private media kind `support_attachments`, keys under `private/support/<uploader>/…`. Files are never served by nginx or a CDN.
  - A member downloads through `/v1/support/tickets/{id}/attachments/{aid}`, which checks the ticket is theirs.
  - An agent downloads through `/v1/admin/support/attachments/{aid}/content`, which the console proxies.
  - Responses carry `private, no-store`, `nosniff` and a sandbox CSP.
- **App:** picks screenshots from the gallery, re-encoded to at most 2048 px. Each file uploads as soon as it is picked and shows progress; a failed upload can be retried or removed, and the server's error is shown.
  - **New:** a file over 8 MB is refused before upload, with the localized "too large" message.
  - The app cannot attach PDFs (no document picker). Agents cannot attach files.

## 7. Notifications to the member

Notifications go through `matching.enqueue_notification` into `matching.notification_outbox`. The outbox worker delivers them to the in-app inbox and to push for every registered device token. Category `system`, route `/support/tickets/<id>`, payload `{ticket_id, reference, status}`.

| Event | When | Text (English, built on the server by policy) |
|---|---|---|
| `support.reply` | Each public agent reply, unless it also resolves or closes the ticket | "Connect Support replied" |
| `support.status` (`pending_member`) | **New:** an agent sets "waiting on member" without a public reply | "We need a reply from you" |
| `support.status` (`resolved`/`closed`) | An agent resolves or closes the ticket, including by a reply that resolves it (**new:** one notification, not two) | "Your request is resolved" / "…is closed" |

- Internal notes never notify.
- Signed-out (website-channel) requesters get no notification; agents answer them by email.
- **App handling:**
  - Tapping a push, or an inbox item, opens the ticket thread (`openSupportRoute`).
  - **New:** when a support notification arrives while the app is open, the unread badges refresh. An open thread for that ticket reloads itself, and the banner's "Open" goes to the thread instead of the inbox.

## 8. Command centre (console) flows

- **Queue** (`/support/`):
  - Default view: unresolved tickets, sorted with the next SLA due time first.
  - Filters: status, category, priority, team, channel, assignee (me, unassigned or an id), SLA (breached, at risk), member, and search (reference, subject, username, email).
  - Server-side paging, bulk claim/assign/status/priority, and CSV export of operational fields only (no subjects, text, names or emails).
- **Ticket detail:**
  - Shows the thread with public and internal messages, the event timeline, a minimal member context panel (account state, verification, report counts, ticket count; no profile content) and related tickets.
  - Actions: claim and take-over, assign, change status/priority/category/team/tags, link a client error issue, reply publicly or add an internal note, and merge.
- **Canned responses:** title, body and optional category, with placeholders `{{member_name}}`, `{{reference}}` and `{{agent_name}}`. They can be previewed rendered for the ticket. Removing one only deactivates it. Usage is counted, and edits are audited by an `audit.change_log` trigger.
- **SLA dashboard:**
  - Open tickets by status, priority and team.
  - Breach and at-risk counts, plus median first-response and resolution times.
  - CSAT average and distribution.
  - Daily created/resolved counts, categories, and a safety block.
- **Live sidebar badge:** `control_panel/live.py` (`nav` topic) counts `new + open` from `/admin/support/dashboard`. It turns red ("past target") when there are breaches. Checked 2026-10-02: the badge showed 2, then 3, as app and website tickets arrived.

## 9. Roles and permissions

| Role | Access |
|---|---|
| `support` | Whole support area (queue, tickets, replies and notes, canned responses, dashboard, export). Can sign in to the console; nothing outside support |
| `admin`, `ops_admin`, `trust_safety`, `moderator` | Whole support area, plus their own areas |
| `analyst` | `GET /admin/support/dashboard` only |
| `finance`, members | None |

- **Enforcement:** twice. `principalCanAccessAdminRoute` checks the route, and each handler checks again (`supportOperator`). Only active operators with an agent role can be assignees.
- **Members:** see only their own tickets and only public messages. Priority, team, assignee, tags, SLA data and internal notes are never in member responses, and agents appear as "Connect Support".
- **Audit:** every operator mutation is recorded in `audit.security_events` (`audit.operator_action_log` includes `support`). Member support actions appear in the member activity log (`member_action_catalog.go`: `support.ticket.create`, `.reply`, `.close`, `.reopen`, `.rate`, `.view`, `support.attachment.upload`, `support.contact`).

## 10. Privacy

- **PII in messages:** members are asked never to send passwords, recovery codes, card numbers or identity documents. This is in the form subtitle, in every locale. Nothing scans or redacts message text (see gaps).
- **Export:** the account export has a `support_tickets` section with the member's tickets, the public conversation and the attachment names. It leaves out internal notes, storage keys and file bytes.
- **Erasure:**
  - The subject and every message body on the member's tickets become the tombstone.
  - The rating comment and device details are cleared.
  - All attachments are marked for deletion, and the worker deletes the bytes.
  - The ticket rows stay as anonymous records for SLA reporting.
  - A legal hold defers erasure.
- **Retention,** applied by the worker:
  - Member tickets are deleted 24 months after closing; members on a legal hold are skipped.
  - Website tickets are deleted 12 months after closing.
  - Unattached uploads are deleted after 24 h.
- **The signed-out form** stores only the email address and name that were typed. The client IP is held in memory for rate limiting and never stored.

## 11. Rate limits and abuse

| Surface | Limits |
|---|---|
| Member create | 5 per hour, 15 per day, 10 unresolved at a time. The same category, subject and text within 10 min returns the existing ticket (`duplicate: true`). Creates are serialised per requester by an advisory lock |
| Member reply | 30 per hour |
| Member uploads | 30 per hour, 20 pending |
| Signed-out contact (`/support/contact`) | Honeypot field (a filled honeypot gets a fake 202). 5 per hour per IP (in memory, per BFF instance), 3 per hour and 10 per day per address, 300 per hour overall, at most 5 links, 32 KB body. Identity headers are stripped |
| Retries | `Idempotency-Key` on every mutation. The app reuses the key after an offline failure, so a retried send is never stored twice |

## 12. Observability

- **Metrics:**
  - `verified_dating_support_tickets_created_total{channel,category}`
  - `verified_dating_support_open_tickets{priority}`
  - `verified_dating_support_sla_breached_tickets{target}`
  - worker metrics `verified_dating_worker_*{worker="support_sla"}`, with heartbeat interval 5 min
- **Logs:** `support_sla_cycle` and `support_sla_cycle_failed`. App-side failures are logged as `support_<operation> failed`.
- **Trails:** the per-ticket event trail, the operator audit trail, the member activity log and notification outbox status.
- **Suggested alerts** (from the runbook):
  - a safety ticket with a breached first response for more than 15 min;
  - more than 10 tickets with a breached first response;
  - the heartbeat stale for more than 3 intervals.

## 13. What the feature flag gates

`support_ticketing_enabled` is listed in `defaultOffFeatureFlags`, so a missing row means **off**. `featureFlagForRoute` maps `support` and `support/*` (under `/v1`) to it.

| Gated (403 `FEATURE_DISABLED` when off) | Not gated |
|---|---|
| Every member route: `GET /support/categories`, `GET/POST /support/tickets`, `GET /support/tickets/{id}`, `…/messages`, `…/close`, `…/reopen`, `…/rating`, `…/attachments/{aid}`, `POST /support/attachments` | All `/v1/admin/support/*` routes: the console keeps working, so agents can finish existing tickets |
| The signed-out contact form `POST /support/contact`, used by both the website and the app | The `support_sla` worker; notifications already queued |

**App behaviour while the flag is off:**
- Help & Support still shows the FAQ and explains that requests are unavailable.
- Contextual "Contact support" links (payment errors, the report sheet) are hidden.
- The Settings tile shows no badge and makes no ticket call.
- The signed-out form explains on submit and keeps what was typed. The app cannot read flags before sign-in (see gaps).

**How the flag is changed:**
- `PUT /v1/admin/config/flags/{key}` with `{"value_bool": true}`, as an operator allowed on `config/` (admin or ops_admin), or Console › Config › Flags.
- The change is audited as `admin.request` on `config/flags` in `audit.security_events`.
- The app re-reads flags every 15 s.

## 14. End-to-end check against the local stack (2026-10-02)

Setup:
- Stack: BFF :18081, gateway :18080, console :8000, Postgres :55433.
- Member: `support_qa_1002`, created with `verify_signup_workflow.sh`.
- Operator: `local_control_admin`. Credentials were read at runtime from the repo scripts and README, and never written down.

| Step | Result |
|---|---|
| Flag off: `GET /support/tickets` | 403 `FEATURE_DISABLED` ✔ |
| Enable: `PUT /admin/config/flags/support_ticketing_enabled` | 200, `updated: true` ✔. `/config/flags` reports it on ✔. Audited as an `admin.request` on `config/flags` in `audit.security_events` ✔ |
| Member: list categories | **Gap:** no endpoint existed (404). Added `GET /support/categories`, and it now returns 200 with the 9 categories and the limits ✔ |
| Member: upload a PNG | 201 ✔ |
| Member: create a ticket with the attachment | 201: `CN-2026-000372`, status `new`, 1 message with 1 attachment ✔ |
| Member: list tickets; read the thread; download the attachment | ✔. The download returned `image/png` with `private, no-store` |
| Operator: queue | The ticket is listed with `first_response_due_at` (+24 h) and `resolution_due_at` (+72 h), SLA `ok`, team `technical` ✔ |
| Operator: assign, claim, internal note, public reply | Assigned ✔; claim moved `new`→`open` ✔; note is internal ✔; the public reply recorded the first response ✔ |
| Operator: canned response | The preview rendered the placeholders ✔. A canned reply with status `pending_member` was stored with `canned_response_id`; SLA shows `paused` ✔ |
| Member: sees the replies | `unread_count` 2 and status "Waiting for you" ✔. The thread shows 3 messages, no internal note, author "Connect Support" ✔. Opening the thread clears unread ✔ |
| Member: in-app notifications | 2 × `support.reply` with route `/support/tickets/<id>` ✔ |
| Member: push | Not verifiable locally. The QA member has no device token, and local push is inbox/WebSocket only (`NOTIFICATION_PUSH_WEBHOOK_URL` is blank). The same outbox row feeds push in environments that have a bridge |
| Member: replies back | `pending_member` → `open` ✔ |
| Operator: resolve | 200 ✔. The `support.status` notice was delivered. The first check ran about 20 ms before the asynchronous outbox delivery; a recheck found it ✔ |
| Member: CSAT | Rating 5 accepted; the dashboard shows CSAT 5.0 ✔ |
| After the fixes: PATCH `pending_member` | "We need a reply from you" notice with payload status ✔. A reply that also resolves sends exactly one notification ✔. CSAT ✔ |
| Signed-out: `POST /support/contact` (BFF and gateway) | 202 with reference `CN-2026-000456`. Resubmitting the same request returns the same reference (duplicate guard) ✔ |
| Console (headless Playwright) | Sign-in ✔; `/support/` renders ✔; the new app ticket and the website ticket are in the queue ✔; SLA column ✔; live sidebar badge 2, then 3 ✔; ticket detail renders with subject, internal note and CSAT ✔; no JS errors ✔. The script was deleted afterwards |

## 15. Gaps found and fixed (2026-10-02)

| Gap | Fix |
|---|---|
| No category list for clients | `GET /v1/support/categories` (`support_tickets.go`, route in `server.go`, `openapi.yaml`). The app form uses it, with a fallback |
| Status notification only for resolved/closed. Resolving by reply sent two notifications. The payload had no status | `support.status` for `pending_member` set without a reply; one notification per reply-and-resolve; `status` added to the payload (`support_admin.go`, `support_tickets.go`) |
| Help & Support sat at the bottom of Settings with no unread indicator | `SupportEntryTile` is now first in the Settings Account section, with an unread badge and an "n new replies" / "n open requests" subtitle. It makes no call while the flag is off (`support/widgets/support_entry_points.dart`, `settings_screen.dart`) |
| No way into support where things go wrong | "Payment problem? Contact support" under Membership and Wallet errors (category `payments_billing`). "Need more help? Contact support" on the report sheet (closes the sheet without reporting; category `safety_harassment`). "Help & Support" on the start-up connection-error screen (`main.dart`). All are hidden while the flag is off, except the FAQ button |
| No support before sign-in | `SupportContactFormScreen`: an email-based form using `/support/contact`, linked from "Can't sign in?". It keeps the text when requests are off or the device is offline |
| A failed send lost the draft once the member left the form | Per-member in-memory draft (`supportDraftProvider`) with a "We kept your unsent request" notice and "Discard draft". Cleared after a successful send |
| An offline reply needed retyping with no retry | The reply stays in the box. The snack bar has Retry, which reuses the idempotency key |
| A reply arriving while the thread was open did not show | A foreground support notification refreshes the badges and reloads the open thread. The banner opens the thread |
| Oversized screenshots reached the server | Client-side 8 MB check with the localized message |
| Localization | 13 new keys in all 10 locales, added with `l10n_add.py` (informal tone) |

Tests (all carry `[case:…]` / `// case:` ids):
- Go: `TestSupportCategoriesEndpoint`, `TestSupportStatusNotificationsPostgres`.
- Flutter: `app/test/features/support/support_entry_points_test.dart` and `support_resilience_test.dart`, 20 tests.
- `SupportContactFormScreen` was added to the screen matrix, so it also runs the layout, accessibility, back-affordance and dead-control audits.

## 16. Remaining gaps

1. **No outbound email.** Signed-out and website requesters are answered by hand from the support mailbox. The app tells them "We'll reply to {email}", so the mailbox must be staffed before launch.
2. **The app cannot know the flag before sign-in.** `/config/flags` needs a session. The signed-out form therefore shows "not available" only after submit, and keeps the draft. A small public availability endpoint would need a one-line change in `isPublicSecurityPath` (`server_security.go`); that file was outside this change's edit scope.
3. **No antivirus scan** of PDFs, only static active-content checks. Add ClamAV or a provider scan if PDFs are expected in volume.
4. **No PII redaction** in message text: card numbers and similar data typed by members are stored as typed. Consider a card-number (Luhn) mask on ingest.
5. **App sends screenshots only.** There is no PDF picker. Agents cannot attach files.
6. **SLA in calendar hours** and as code constants. There are no business hours, holidays or per-team targets.
7. **One flag for both channels.** It gates the app and the website form together; they cannot be launched separately.
8. **Push and notification text is English** (owner policy).
9. **Contact-form IP limits are per BFF instance** (held in memory). With several replicas the effective limit multiplies.
10. **Tests not caused by this change, but failing in the shared tree:**
    - `settings_logout_test.dart` (9) and `settings_theme_test.dart` (1) fail with "A Timer is still pending". They fail the same way with the new support tile disabled; the cause is the new Settings notification-inbox row.
    - The pre-sign-in accessibility audits fail on the language picker's 40 px tap target.

## 17. Recommendation for production

Turn the flag on in production after these steps:

1. **Staffing:** at least one `support` agent per shift. A Trust & Safety owner covers the 1 h safety SLA. The support mailbox is monitored for website and signed-out requests.
2. **Alerts:** the three alerts in section 12 are set up, and the `support_sla` heartbeat is on the on-call dashboard.
3. **Push:** the push bridge (`NOTIFICATION_PUSH_WEBHOOK_URL`) is configured, so replies reach members who are not in the app.
4. **Acceptance:** a product owner accepts the workflow. The flag is then switched on in Console › Config › Flags (audited). The `growth.portfolio_modules` row `support_ticketing` is updated with the approver.
5. **Watch the first 48 h:** creation rate, breaches, the 429 rate on `/support/contact`, and CSAT. Rollback is a single flag flip:
   - members get the "not available" explanation and contextual links disappear within 15 s;
   - agents can still finish open tickets in the console.

Gaps 3 and 4 (antivirus and PII masking) are worth doing before volume grows, but they need not block launch. Attachments are already restricted and sanitised, and members are told not to send secrets.
