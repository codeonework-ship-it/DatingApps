# Command center epics completion

**Date:** 2026-09-27  
**Scope:** Django operator UI, secured Go BFF administration APIs, local PostgreSQL monitoring data, and repeatable browser acceptance. Billing workflows remain separately owned; this work reads their existing monitoring surfaces without changing provider behavior.

## Outcome

The local command-center software backlog is complete. The console now provides a single operational surface for platform health, members, safety SLAs, product events, operator accountability, feature operations, progression, engagement, billing visibility, and deep-log links. Values are labelled with their source and measurement window; unavailable aggregates are shown as unavailable rather than as fabricated zeroes.

Production SSO/MFA, managed secrets, staffed queue coverage, paging, and deployed dashboards remain release acceptance controls. They require production identity and operations ownership and are deliberately shown as deployment gates in the UI.

## Completed epics

| Epic | Result | Evidence |
|---|---|---|
| CC-01 Unified operations command center | Complete locally | Health/readiness, platform snapshot, product ratios, safety queues, current activities and observability links are combined in the [dashboard](../control-panel/templates/control_panel/dashboard.html). |
| CC-02 Immutable operator accountability | Complete locally | New role-protected `GET /v1/admin/audit-events` reads `audit.operator_action_log` with actor, subject, resource and event filters. Django exposes a dedicated [operator audit screen](../control-panel/templates/control_panel/audit_log.html). |
| CC-03 KPI contracts and truthful empty states | Complete locally | User, risk and product metrics state their source, scope and window. DAU and MAU remain visibly unavailable until a durable time-window aggregate exists. Queue zeroes and unavailable source errors are distinct states. |
| CC-04 Accurate user-management monitoring | Complete locally | The user API now returns a filtered total plus global active, suspended, banned, verified and verification-rate KPIs from PostgreSQL. The UI no longer derives global KPIs from one page. |
| CC-05 Safety and moderation SLA watch | Complete locally | SOS, reports, appeals, verification and media queues show open count, overdue count, oldest age and target. Existing queue action pages remain the execution surfaces. |
| CC-06 Operator authentication and role access | Complete locally | Existing bearer-backed server-side sessions and refresh remain in force. Admin, ops, trust/safety, moderator and analyst roles can read the audit stream; mutation restrictions remain unchanged. |
| CC-07 Activity exploration | Complete locally | Product activities support action, user and status filtering; operator mutations have an independent filtered evidence log. |
| CC-08 Complete-screen acceptance | Complete locally | The repeatable [screen gate](../qa/admin/command_center_screen_gate.py) signs in through CSRF-protected Django and verifies 22 command-center screens, including the canonical domain-event stream. The main admin gate now launches an isolated Django instance and runs it automatically. |

## Product decisions implemented

- Queue targets are presented as SOS 5 minutes, reports 24 hours, appeals 48 hours, verification 24 hours, and media review 24 hours.
- Dashboard queue values are current snapshots. Product funnel ratios are labelled as runtime-lifetime measures until durable windowed aggregation is implemented.
- DAU and MAU are defined as rolling 24-hour and rolling 30-day unique-user aggregates. They are unavailable because no durable aggregate currently satisfies those definitions.
- Product activity and operator audit are intentionally separate. Product events explain member/system behavior; the append-only audit answers who changed administrative state.
- Billing screens remain visible for monitoring, while checkout/provider implementation remains coordinated separately.

## Validation

| Gate | Result |
|---|---|
| Django system check | Passed |
| Django production security check | Passed with TLS redirect, secure cookies, HSTS and proxy controls enabled through environment configuration |
| Django tests | 25 passed |
| Go route, RBAC, SQL-filter and OpenAPI tests | Passed |
| Authenticated live BFF preflight | Audit, users/KPIs, analytics, reports and SOS returned 200 |
| Live browser visual inspection | Sign-in, command center and operator audit rendered correctly |
| Complete command-center screen gate | 22/22 screens returned 200 without Django error pages |

## Production acceptance gates

1. Connect deployed operator access to SSO/MFA or an approved equivalent and exercise provisioning, deprovisioning and session revocation.
2. Supply Django and service credentials through managed secrets and disable development settings.
3. Assign named primary and backup owners for SOS, reports, appeals, verification and media queues; connect overdue thresholds to paging.
4. Deploy retained metrics/log exporters and Kibana-equivalent dashboards, then prove alert delivery with induced failures.
5. Add a durable analytics aggregate before enabling DAU/MAU or time-window conversion claims.
6. Repeat the role-denial and 22-screen gates against the deployed environment.
