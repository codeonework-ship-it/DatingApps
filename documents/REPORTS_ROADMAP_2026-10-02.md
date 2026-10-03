# Command center reports: roadmap (2026-10-02)

Owner brief: SSRS-style reports in the command center, user-based reports,
reports for production activity, and server consumption reports. This is the
product view: what each report answers, who it is for, what it needs, and
in what order to build it.

Status key: **Live** = in the command center now · **Next** = data exists, report
to build · **Build** = needs new data or an endpoint first.

## 1. What exists today

**Update (later on 2026-10-02):** 30 reports in five categories:
- **Members:** Member 360, directory, dormant members, sign-in and security, most-reported, paying members.
- **Operations:** daily summary (PDF), queue SLA, operator productivity, moderation outcomes, SOS incidents, payment operations, config changes.
- **Business** and **Product:** as below.
- **Server:** API traffic and latency, background jobs, database and storage consumption, third-party usage.

The Server pages and reports fill in once the server-activity recording (migration 133) is deployed.


- **Report server** (`/reports/`): parameters, group-by with subtotals,
  drill-through, charts, and Excel/CSV/PDF export. 17 reports:
  - **Members:** Member 360, member directory, most-reported members, paying
    members by plan.
  - **Business:** revenue, subscriptions & MRR, conversion & checkout funnel,
    coin economy, referrals, marketing spend & CAC.
  - **Product:** headline KPIs, active members, activation funnel, retention,
    engagement, liquidity by city, safety health.
- **Member activity** (`/activity/`): every member action across all 215
  mutating routes, with who, what, when, device, IP and outcome. Live tail,
  filters, Excel export. Each member's page has an Activity section.
- **Server-side lists** for every queue and log: search, filters, paging,
  real totals, Excel.

## 2. User-based reports

| Report | Question it answers | For | Status |
|---|---|---|---|
| Member 360 | Everything about one member, on one page and in one export | Support, T&S, legal requests | **Live** |
| Member directory | Who are our members, by city, gender, verification, status? | Ops, growth | **Live** |
| Most-reported members | Who are the repeat offenders, and what for? | Trust & Safety | **Live** |
| Paying members by plan | Who pays, on which plan, renewing or ending? | Finance, CRM | **Live** |
| New members | Signups per day/week by city, source, platform, gender, age band; how many finished onboarding, got verified, made a first match | Growth | **Next** (analytics funnel + users list) |
| Onboarding drop-off by member | Members stuck at each setup step for more than 3 days (for nudges) | Growth, CRM | **Build** (step timestamps per member) |
| Engagement scorecard | Per member: active days, likes sent/received, matches, messages, plans made/kept, last seen | Product, CRM | **Next** (member_action rollup) |
| Dormant and at-risk members | Paying or highly engaged members with no activity in 7/14/30 days | CRM, retention | **Live** |
| Login and security report | Sign-ins, failed sign-ins, password resets, sessions revoked, new devices and IPs per member; shared devices across accounts | T&S, security | **Live** ("Sign-in and account security") · failed sign-ins **Build** (401s not recorded yet) |
| Device and app-version mix | Members by platform and app version; adoption of each release | Mobile team | **Build** (the app must send `X-App-Version` and `X-Device-ID`) |
| Wallet statement | One member's coin ledger: purchases, gifts sent and received, refunds, clawbacks, balance over time | Support, finance | **Next** (billing transactions + gift ledger) |
| Member LTV | Net revenue per member and per signup cohort | Finance | **Next** (business conversion LTV) |
| Safety history | Per member: reports filed/received, blocks, appeals, SOS, enforcement actions | Trust & Safety | **Live** in Member 360; a cross-member version is **Next** |
| Privacy requests | Data exports, deactivations, deletions and erasures with SLA (GDPR/DPDP) | Legal, DPO | **Next** (account lifecycle security events) |
| Referral and introducer report | Who brought whom; introducer acceptance and match rates per introducer | Growth | **Next** (business referrals) |
| Support history | Tickets per member, CSAT, repeat contacts | Support lead | **Live** in Member 360; cross-member **Next** |

## 3. Production activity reports (running the platform day to day)

| Report | Question it answers | For | Status |
|---|---|---|---|
| Daily operations summary | Yesterday at a glance: signups, DAU, matches, messages, revenue, open queue items, SLA breaches, incidents, errors (one PDF, emailable) | Leadership, on-call | **Live** |
| Queue SLA report | Per queue (reports, appeals, verifications, media, support, SOS, recovery): volume in and out, backlog, median and p90 time to decision, breaches with links | Ops leads | **Live** |
| Operator productivity | Per operator: decisions per day, time to decision, reversal rate (appeals upheld against their decisions) | Ops leads | **Live** |
| Moderation outcomes | Reports by reason and outcome; warnings, suspensions, bans; appeal reversal rate | Trust & Safety | **Live** |
| SOS incident log | Every SOS with time to acknowledge, time to resolve, delivery to contacts | Safety lead, legal | **Live** |
| Notification delivery | Push/email/SMS sent, delivered, failed, opened, per type and day | Product, CRM | **Build** (delivery outcomes per message) |
| Payment operations | Failed payments, retries, refunds, chargebacks, webhook failures, reconciliation differences | Finance | **Live** |
| Release health | Per app version: crash-free sessions, client errors, adoption curve | Mobile team | **Next** (client errors) + **Build** (app version) |
| Feature flag and config change log | Who changed which flag, when, and what moved afterwards | Engineering, audit | **Live** |
| Data quality | Snapshot build status, excluded accounts, unregistered event sources, suppressed metrics | Analytics | **Live** (Data & exclusions) |
| Event backbone health | Events per producer, consumer lag, dead letters | Engineering | **Live** (domain events + metrics) |

## 4. Server consumption reports

Two kinds of data:
- **Live metrics** (Prometheus): rates and latencies right now.
- **Durable hourly rollups** in Postgres: trends and month-over-month questions, and they survive metric retention.

| Report | Question it answers | Source | Status |
|---|---|---|---|
| API traffic | Requests per hour/day by route, method, status class; top routes | Hourly request rollups (every request, incl. refused) | **Live in the console**; data from the server-activity rollout (migration 133) |
| Latency | p50/p95/p99 per route per hour; slowest endpoints; regressions after a release | Same rollup (duration_ms) or Prometheus histograms | **Build** |
| Error budget | 5xx rate per route and overall vs SLO; refused (401/403/429) volume | Rollup + security middleware recording | **Build** |
| Database consumption | DB size, table and index sizes and growth per day, row counts, dead tuples, connections in use vs pool max, slow queries | `pg_database_size`, `pg_stat_user_tables`, `pg_stat_statements` (if enabled), pool metrics | **Build** (daily snapshot table + admin endpoint) |
| Background jobs | Every worker run: start, end, duration, items processed, failures (retention, SOS delivery, notifications, billing, erasure, analytics builds) | A `platform.job_runs` table written by each worker | **Build** |
| Realtime capacity | Concurrent websocket connections, messages per second, wake-hub lag | Prometheus gauges | **Build** (expose + snapshot) |
| Storage | Media and attachment bytes by type and month; growth; orphaned files | Storage listing + DB metadata | **Build** |
| Third-party usage and cost | SMS/OTP, email, push, payment fees, maps, AI/copilot calls per day, with unit cost → monthly cost | Counters per provider call + a price table | **Build** |
| Cost per active member | Infrastructure + third-party cost ÷ MAU, by month | The two rows above + business KPIs | **Build** |
| Capacity forecast | Days until the DB, connection pool or storage reaches its limit at the current growth rate | DB and storage snapshots | **Build** |

## 5. Build order

1. **Now:** what is already recorded.
   - Queue SLA report, operator productivity, daily operations summary (PDF).
   - Engagement scorecard, dormant/at-risk members, login and security report (successful sign-ins).
2. **Server activity foundation:**
   - Record refused requests (401/403/429) and 5xx.
   - Add `platform.job_runs` for every worker.
   - Add a "Server activity" page in the command center.
3. **Consumption rollups:**
   - Hourly API traffic, latency and error rollups.
   - A daily DB and storage snapshot.
   - API traffic, latency, database consumption, background jobs and storage reports.
4. **Cost:**
   - Third-party call counters and a price table.
   - Third-party cost, cost per active member, capacity forecast.
5. **App:**
   - Send `X-App-Version` and `X-Device-ID`.
   - Then the device/app-version mix and release health reports.

## 6. Report server features still to add (SSRS parity)

- **Subscriptions:** email a report (PDF/Excel) on a schedule, e.g. the daily
  ops summary at 08:00 IST. Needs a scheduler and outbound email.
- **Saved views:** a named report with its parameters. Today **Copy link**
  covers this, and the URL carries every parameter.
- **Snapshots:** keep a dated copy of month-end reports (finance close).
- **Row-level access:** already enforced by Go roles. Analysts see IP and
  device redacted.
