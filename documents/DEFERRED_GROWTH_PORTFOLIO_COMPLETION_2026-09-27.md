# Deferred growth portfolio — architecture and delivery record

Date: 2026-09-27  
Priority: P2, behind P0/P1 launch work  
Decision owner: Product, Architecture, Trust & Safety, Privacy and Billing according to module

## Outcome

The old proposal tables were not promoted as production truth. Migration `080_deferred_growth_portfolio.sql` creates one canonical snake_case `growth` domain, registers every mutable table with the durable domain-event outbox, and gives each module an owner, risk tier, lifecycle, runtime flag and explicit blocker.

Support ticketing is the first complete vertical slice. Authenticated members can create idempotent cases, see status and conversation history, and reply. Safety cases receive a 15-minute first-response target. Operators can filter the command-center queue, assign themselves, change priority/status, reply, and resolve or close a ticket. Ticket audit events are append-only. Member, operator and state changes also enter the canonical event outbox in the same database transaction.

## Delivered foundations

| Module | Delivered now | Production decision |
|---|---|---|
| Support ticketing | Member UI/API, conversation messages, SLA deadlines, operator queue, assignment, audited transition and OpenAPI contract | Enabled locally; production requires staffed ownership and escalation rehearsal |
| Referrals | Unique code and one-time redemption persistence/API | Disabled; no reward, coins, XP, cash or entitlement can be granted |
| Events | Free published-event listing, capacity-safe registration/cancellation and explicit safety acceptance | Disabled; host vetting and physical-safety runbook pending |
| Partnerships | Due-diligence-gated published directory | Disabled; legal terms and any commission/accounting design pending |
| Social imports | Revocable 30-day provider consent only | Disabled; no contacts or external social graph are ingested |
| Member history | Explicit preference snapshots, city/state/country foreground check-ins, 30-day location expiry and immediate deletion | Disabled; no latitude, longitude, address, accuracy or background collection |
| Recommendation graph | Versioned, expiring edges with a score and non-empty visible reasons | Disabled; model card, fairness evaluation and monitoring pending |
| Fraud graph | Evidence-bearing relationship edges and operator resolution | Internal/disabled; review-only and incapable of automatic enforcement |
| Admirer gifts | Reserved route, owner and fail-closed flag | Blocked until consent, refunds, abuse controls and billing settlement are approved |
| Expanded gift economy | Separate launch contract; existing matched gifts remain independently governed | Marketplace, trading, creator settlement and shared wallets blocked |
| Paid XP | Reserved route, owner and fail-closed flag | Blocked; money cannot change XP, streak, level or recommendation rank |

## Non-negotiable contracts

1. Turning on a runtime flag does not equal production approval. Both `production_enabled` and the server flag must be true in operator reporting.
2. Monetized features remain off until billing issues a production GO and Product, Safety and Finance approve pricing, refunds, settlement and abuse controls.
3. Recommendation output must show reasons and model version. Fraud signals require a human decision and never trigger an adverse member action by themselves.
4. Social import stores consent metadata only. Location history stores a city-level foreground check-in that expires after 30 days.
5. Every growth mutation is written to `platform.domain_event_outbox`; support case audit events cannot be edited or deleted.

## Acceptance evidence

- `go test ./...`, including registered-route and idempotency-key OpenAPI contract checks
- `flutter test`: 937 tests, including every-screen responsive and accessibility-text matrices
- Focused `flutter analyze` for the support provider, screen and widget test: no issues
- `.venv/bin/python manage.py test control_panel`: 30 tests and clean system check
- `npm run build` and `npm test`: release web bundle plus 23 Playwright checks at phone and desktop widths
- `backend/scripts/verify_deferred_growth_portfolio.sh`
- `python3 backend/scripts/deferred_growth_api_smoke.py`
- Live browser verification of the member support center and operator launch register

The repository-wide Flutter analyzer also reports 596 existing style-level
`info` notices. It reports no errors or warnings when infos are non-fatal; the
new support files are individually clean.

Production activation of any disabled module remains a separate reviewed decision. This is enforced in the database and BFF rather than left as a UI convention.
