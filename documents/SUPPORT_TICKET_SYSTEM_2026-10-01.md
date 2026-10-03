# Support ticket system (2026-10-01)

Members raise questions and problems from **Help & Support** in the app. Signed-out visitors use the **Contact** page on the website. The support team tracks and resolves both in the operator console under **Support**.

| Part | Where |
|---|---|
| Schema | `backend/scripts/126_support_ticket_system.sql`, schema `support` |
| Member API, contact form | `backend/internal/bff/mobile/support_tickets.go` |
| Attachments | `backend/internal/bff/mobile/support_attachments.go`, media kind `support_attachments` (`private/support/...`) |
| Operator API | `backend/internal/bff/mobile/support_admin.go` |
| SLA / auto-close / retention worker | `backend/internal/bff/mobile/support_worker.go`, heartbeat `support_sla` |
| Tests | `backend/internal/bff/mobile/support_tickets_test.go` |
| App | `app/lib/features/support/`, `app/lib/features/common/screens/help_support_screen.dart` |
| Website | `website/public/contact.html` (all locales), `website/public/contact.js` |
| Console | `control-panel/control_panel/views_support.py`, `templates/control_panel/support/` |
| API reference | `backend/internal/platform/docs/openapi.yaml`, tag `support` |

Migration 126 replaces the foundation tables from migration 080 (`growth.support_tickets` and related tables). Those were never switched on. Their rows are copied once into `support.*`; `legacy_ticket_id` keeps the link. The old tables stay, read-only by convention.

## Launch switch

Every member route (`/v1/support/...`, including the website form) is behind the runtime flag `support_ticketing_enabled`. Migration 088 held that flag **off** by product decision, and migration 126 does not change it. When the flag is off:

- Member routes return `403 FEATURE_DISABLED`.
- The app shows the FAQ plus a "not available right now" panel.
- The website shows a neutral "not available" message.
- The operator queue keeps working.

To launch:

1. A product owner accepts the workflow.
2. An operator sets `support_ticketing_enabled = true` in Config → Flags.
3. Update the `growth.portfolio_modules` row `support_ticketing` (lifecycle, production_enabled, decision note naming the approver).

## Ticket model

- **Reference:** `CN-<year>-<6+ digits>`, for example `CN-2026-000123`, from one global sequence.
- **Requester:** a member (`requester_member_id`, channel `app`) or, for website tickets, only the email address and optional name the visitor typed (channel `website`). The contact form never creates, finds or links an account. Channel `email` is reserved for tickets an agent logs from the support mailbox.
- **Category, team and starting priority:**

| Category | Team | Starting priority |
|---|---|---|
| account_login (Account & login) | general | normal |
| verification (Verification) | trust_safety | normal |
| payments_billing (Payments & billing) | billing | normal |
| safety_harassment (Safety & harassment) | **trust_safety** | **high**, tighter SLA |
| matches_chat (Matches & chat) | general | normal |
| technical (Technical problem / bug) | technical | normal |
| feature_request (Feature request) | general | low |
| privacy_data (Privacy & data request) | privacy | normal |
| other (Other) | general | normal |

- **Diagnostics:** app version, platform, OS version and locale are attached by the app automatically. The app does not read the device model. An agent can link a ticket to a client error issue, but the app never does this, because crash reports stay anonymous.
- **Messages:** public replies (visible to the member) or internal notes (agents only; a database check stops members writing them). System messages record merges.
- **Attachments:**
  - Types and sizes: JPEG/PNG up to 8 MB (8000 px per side) and PDF up to 10 MB; at most 5 per message and 20 per ticket.
  - The type is sniffed from the bytes, never taken from the name or the declared type.
  - Images are decoded and re-encoded, which drops EXIF/GPS data and anything appended to the file.
  - PDFs are refused if they contain `/JavaScript`, `/JS`, `/Launch`, `/EmbeddedFile`, `/OpenAction`, `/AA`, `/RichMedia`, `/XFA`, `/SubmitForm` or `/ImportData`. The check also looks inside compressed object streams and decodes `#xx` escapes.
  - Files are stored privately and served only through the API with `private, no-store`, `nosniff` and a sandbox CSP. Members can open files on their own tickets; operators through the console proxy.
  - An upload not attached to a message within 24 h is deleted.
- **Event trail** (`support.ticket_events`, append-only): created, status/priority/category/team changes, assigned/unassigned, tags, client error link, member and agent replies, notes, reopened, closed by member, auto-closed, merged, SLA breached, rated.
- **Canned responses:** title, body and optional category; placeholders `{{member_name}}`, `{{reference}}` and `{{agent_name}}` (first names). Removing one only deactivates it, so past replies keep their reference. Edits are audited in `audit.change_log`. Five starter responses are included.
- **CSAT:** after a ticket is resolved or closed, the member can rate it once, 1–5 with an optional comment.

## Statuses

| Status | Meaning | Member sees |
|---|---|---|
| `new` | Raised, nobody has picked it up | Open |
| `open` | An agent is working on it | Open |
| `pending_member` | Waiting on the member; the resolution clock is paused | Waiting for you |
| `on_hold` | Parked by the agent (for example waiting on engineering); the clock keeps running | On hold |
| `resolved` | Agent considers it done | Resolved – reply to reopen |
| `closed` | Finished | Closed – reopen until a date |

Transitions:

- Claiming a `new` ticket opens it.
- An agent's **public reply** to a `new` or `open` ticket moves it to `pending_member`, unless the agent picks a status. It also records the first response, assigns the ticket to that agent if nobody owns it, and notifies the member.
- A **member reply** moves `pending_member`, `resolved` and (within the reopen window) `closed` back to `open`.
- **Auto-close:** a ticket resolved for 7 days with no member reply since is closed by the worker.
- **Reopen window:** the member can reopen a closed ticket, or reply to it, for 14 days after it was closed. After that they start a new request. Resolved tickets can always be reopened until auto-close.
- **Merge:** only tickets from the same requester can be merged. The duplicate's messages and attachments move to the target, the duplicate closes with `merged_into`, and the member sees "merged into CN-…" on it.

Member notifications use category `system` and route `/support/tickets/<id>`, both as push and in the in-app inbox:

- `support.reply` for each public agent reply.
- `support.status` when an agent resolves or closes a ticket, or sets it to `pending_member` without a public reply. A public reply that also resolves or closes sends only the `support.status` notice (one notification per action). The payload carries `ticket_id`, `reference` and `status`.

Internal notes never notify. Website requesters cannot be notified: the console shows their address with "Reply by email — this visitor has no account". The API does not send email.

## SLA targets

Calendar time, measured from creation:

| Priority | First response | Resolution |
|---|---|---|
| urgent | 1 h | 8 h |
| high | 4 h | 24 h |
| normal | 24 h | 72 h |
| low | 48 h | 7 days |

- **Safety & harassment** is capped at 1 h first response and 24 h resolution, whatever the priority.
- **Changing priority or category** recomputes the targets. Moving a ticket into the safety category raises it to at least high priority and moves it to the trust_safety team.
- **The resolution clock pauses** while the ticket is `pending_member`: the due time moves later by the time spent waiting.
- **A reopened ticket** gets a fresh resolution target.
- **At risk** means less than a quarter of the target window is left.
- **Breached** means the due time has passed. Breaches are *latched* (`first_response_breached`, `resolution_breached`) the moment they happen and never clear, so reports stay true after the ticket is resolved.
- **Who latches them:** the `support_sla` worker every 5 minutes, writing an `sla_breached` event, and every status change.

Trust & Safety sees safety tickets through:

- the queue filter `team=trust_safety` (or `category=safety_harassment`),
- the `safety` block of the SLA dashboard,
- the "Safety tickets" card on the console dashboard.

## Roles

| Role | Support access |
|---|---|
| `support` (new, migration 126) | Full support area: queue, tickets, replies and notes, canned responses, dashboard, export. Can open the console. No other admin areas (no user admin, billing or moderation) |
| `admin`, `ops_admin`, `trust_safety`, `moderator` | Full support area, plus their existing areas |
| `analyst` | SLA dashboard only, read-only |
| `finance` and members | None |

- Only operators with one of the five agent roles can be assignees.
- Every operator mutation is also written to the operator audit trail (`audit.operator_action_log`, which now includes `support`).
- To grant the role: insert `(user_id, 'support')` into `user_management.auth_account_roles`. The user also needs an `auth_credentials` row.

## How agents work the queue

1. **Open Support → Queue.** It shows unresolved tickets, the next due SLA target first. Start with **SLA: breached**, then **at risk**. Trust & Safety agents filter by team `trust_safety`.
2. **Claim** a ticket, or bulk-claim several. Claiming opens a `new` ticket and makes you the owner; tickets owned by someone else need a deliberate takeover.
3. **Read the thread and the member panel.** The panel shows account status, verification, report counts in the last 90 days, total tickets and related tickets. It holds no profile content, messages or location; open the member's profile only if your role allows it and you need to.
4. **Reply publicly or add an internal note.** Use a canned response as a starting point and edit it. Choose what happens next:
   - *Waiting for member*: the default after a public reply.
   - *Resolved*: when you have fixed it.
   - *On hold*: when you are waiting on another team; add a note saying why.
5. **Triage** as you go: correct the category (this re-routes the team), raise the priority, add tags, link a client error issue for app bugs.
6. **Merge** duplicates into the oldest ticket from the same requester.
7. **Resolve.** The member is notified and can rate. If they reply, the ticket comes back to the queue as **awaiting reply**.

Safety tickets:

- Reply within the hour, even if only to acknowledge.
- Never ask the member to go back to the other person.
- Escalate to moderation through the existing report and enforcement tools; the ticket is not an enforcement record.
- For immediate danger, point the member to local emergency services and the in-app SOS.

Website tickets: reply from the support mailbox to the address shown, then record the reply as a public message so the history is complete.

## Rate limits and abuse controls

- **Members:**
  - 5 new tickets per hour and 15 per day.
  - 10 unresolved tickets at a time.
  - 30 replies per hour.
  - 30 uploads per hour and 20 pending uploads.
  - The same category, subject and text within 10 minutes returns the existing ticket (`duplicate: true`) instead of a new one.
  - Idempotency keys make retries safe.
- **Website form:**
  - A honeypot field: bots that fill it get a normal `202` and nothing is stored.
  - 5 per hour per IP. The IP is held in memory only and never stored.
  - 3 per hour and 10 per day per email address.
  - 300 per hour overall.
  - At most 5 links per message.
  - No captcha and no account creation.

## Privacy and retention

- **Members see only** their own tickets and their public messages. Internal notes, priority, assignee, tags and SLA data are never in member responses. Agents appear as "Connect Support".
- **Export:** the account export has a `support_tickets` section: the member's tickets, the public conversation and attachment names. It leaves out internal notes, storage keys and file bytes.
- **Erasure:**
  - The tickets stay as anonymous records for SLA reporting.
  - The subject and every message body on the member's tickets (agents often quote members) are replaced with `[erased]`.
  - The rating comment and device details are cleared.
  - All attachments are queued for deletion, and the worker deletes the files.
  - A legal hold defers erasure as it does elsewhere.
- **Retention**, applied by the worker:
  - Member tickets are deleted 24 months after closing; members on a legal hold are skipped.
  - Website tickets are deleted 12 months after closing.
  - Attachment files are deleted before their rows.
  - The event trail is deleted with its ticket and is otherwise append-only.
- **CSV export:** operational fields only (reference, timestamps, category, team, priority, status, assignee, SLA figures, rating, tags). It has no subjects, message text, member names or email addresses. Cells that could start a spreadsheet formula are prefixed with an apostrophe.

## Monitoring

- `verified_dating_support_open_tickets{priority}` and `verified_dating_support_sla_breached_tickets{target}`: gauges refreshed each worker run.
- `verified_dating_support_tickets_created_total{channel,category}`.
- `verified_dating_worker_*{worker="support_sla"}`: heartbeat; expected interval 5 min.

Suggested alerts:

- Any safety ticket with a breached first response for more than 15 minutes.
- More than 10 unresolved tickets with a breached first response.
- The `support_sla` heartbeat stale for more than 3 intervals.

## Known gaps

- No outbound email: website requesters are answered from the support mailbox by hand. Channel `email` exists, but no inbound mailbox integration creates tickets.
- Agents cannot attach files to replies yet; members can.
- SLA targets are constants in code (`supportSLATargets`), not operator-editable, and use calendar hours, not business hours.
- Support agents cannot open member profiles unless they also hold a user-reading role.
