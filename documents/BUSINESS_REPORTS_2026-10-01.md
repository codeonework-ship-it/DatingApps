# Connect — Business development and commercial reports

Status: **built 2026-10-01.** Covers the money and market-launch reports: the BFF API under `/v1/admin/business/...`, the corrected billing analytics (`/v1/admin/billing/revenue-analytics`, `/v1/admin/billing/stats`), the console "Business" section, and migration `124_business_reports.sql`.

Engagement, activation, retention and liquidity are covered by the product analytics reports (migration 123, `/v1/admin/analytics/*`). Where the two overlap, this document says which one to use.

---

## 1. Ground rules (every report)

| Rule | What it means |
|---|---|
| **Window** | `since` (inclusive) and `until` (exclusive for RFC3339; a `YYYY-MM-DD` until is the whole day). Default is the last 30 days, ending at the start of tomorrow. Cohort-style reports (subscriptions, conversion, investor pack, marketing spend) default to 12 whole months, and referrals to 6. A window can be up to 1,100 days and 400 buckets. |
| **Time zone** | `tz` is any IANA zone. The default is `UTC`; use `Asia/Kolkata` for Indian reporting. Dates, calendar days, ISO weeks (Monday start) and months are all in that zone. |
| **Live vs sandbox** | `mode=live` (default), `sandbox` or `all` (live + sandbox). A row is **sandbox** if its provider is `sandbox`, if it is a `stripe` row while the server runs on Stripe test keys (`sk_test_`/`rk_test_`), or if its metadata says `livemode=false`. A row is **local** if its provider is `local`, `internal` or `promo`. Local rows moved no money: they are never revenue in any mode and appear only under `local_activations`. Each report's `data_status` counts live, sandbox and local payments in the window, so the console can say "sandbox data exists; switch mode". |
| **Money** | Stored and computed in **minor units** of the payment currency. Every money field comes in a pair: `<name>_minor` (an integer) and `<name>` (a decimal string, for example `"193.00"`). Rows always carry `currency`. **Different currencies are never added together.** No FX conversion is done anywhere. Multi-currency totals are a list with one row per currency, and `billing/stats` sets `total_revenue_minor` only when the window has a single currency. |
| **Small counts** | Member-level counts from 1 to 4 are shown as `"<5"`. Zero is shown as zero. Per-member averages (ARPPU, ARPU, LTV per member, conversion and churn rates) are `null` when the denominator is under 5 members. Payer cities with fewer than 5 payers are pooled into one "other cities" row. Revenue totals themselves are not suppressed, because finance needs exact figures; reconciliation remains the place for line-level review. |
| **CSV** | Any GET report accepts `format=csv&table=<name>`. The JSON response lists the table names in `tables`. Suppressed cells read `<5`. Text cells that start with `= + - @` are prefixed with `'`, so a spreadsheet will not run them as formulas. |
| **Snapshots** | Each report is read in a single repeatable-read, read-only transaction, so all of its figures describe the same instant. |
| **Who counts as a member** | A member has `account_kind='dating'`, is not erased, and holds no operator role. When product analytics is installed, test accounts flagged by `analytics.member_exclusions` (test usernames, reserved test e-mail domains, explicit flags) are also left out, so member counts match the analytics reports. Payments are **not** filtered this way: a payment is money, and it stays consistent with reconciliation. |

### Billing is off in release 1

Billing is excluded from the first release (`documents/RELEASE_CONTRACT_AND_GOVERNANCE_2026-09-27.md`, PEN-25). Expect zero live revenue until it ships. Every report still answers with zeros and empty lists instead of errors. `data_status` carries:

- `release_1_billing_excluded`
- `release_note`
- the `billing_enabled` flag
- the payments provider and its mode
- `empty`

The console uses these to show an explanation in place of blank charts. Sandbox payments made during QA appear only in `mode=sandbox` or `mode=all`.

---

## 2. Data sources

| Source | Used for |
|---|---|
| `matching.billing_payments_runtime` | All revenue. `created_at` is the payment date. Statuses are success, partially_refunded, refunded, disputed, chargeback, failed, created and pending. `refunded_amount_paise` holds partial refunds. `period_start`/`period_end` give subscription periods. `billing_reason` is subscription_create, subscription_cycle, subscription_update or coin_purchase. |
| `matching.billing_subscriptions_runtime` | Plan, cycle, contracted `amount_minor`, status, `cancel_at_period_end`, `cancelled_at`, `end_date`, and `metadata.ended_reason` |
| `matching.billing_checkout_sessions` (071) | Funnel, and the coin package behind a coin payment |
| `matching.wallet_coin_purchases` | Coin credits by source: `buy` (money), `admin_topup`, `promo`, `bootstrap` and `opening_balance` (grants), `gift_refund` (returned) |
| `matching.match_gift_sends`, `matching.wallet_coin_debits`, `matching.user_wallets` | Coin sinks, clawbacks, outstanding balance and debt |
| `matching.graduation_rewards`, `matching.match_graduations` | Graduation Refund model; graduation as a churn reason |
| `growth.referral_codes`, `growth.referral_redemptions` (080) | Referrals and K-factor |
| `matching.introducer_invites`, `matching.introducer_consents`, `matching.friend_intros` (102) | Introducer programme |
| `user_management.users` | Cohorts (`created_at`), city, gender, `is_verified` |
| `platform.member_last_activity`, `analytics.member_active_days` (123) | Active members (see 3.6) |
| `matching.match_date_plans` (`status='completed'`) | Plans kept, which feed the north star and the live gate |
| `business.marketing_spend` (124) | CAC inputs entered by operators |
| `business.launch_markets` (124) | City launch gates |

---

## 3. Metric definitions

### 3.1 Revenue — `GET /v1/admin/business/revenue`

These semantics are identical to `GET /v1/admin/billing/reconciliation`. Each figure below is per currency.

| Metric | Definition |
|---|---|
| **Gross** | Sum of `amount` over charged payments: success, partially_refunded, refunded, disputed and chargeback |
| **Refunded** | For partially_refunded rows, `refunded_amount`. For refunded rows, the full `amount`. |
| **Chargebacks** | `amount` of chargeback rows |
| **Disputed (held)** | `amount` of disputed rows. This money is held by the processor and is not net until the dispute is won. |
| **Net** | success `amount` + (partially_refunded `amount` − `refunded_amount`). Check: gross − refunded − chargebacks − disputed = net. |
| **Refund rate** | refunded ÷ gross (by amount). `refund_count_rate` is refunding payments ÷ charged payments. |
| **Chargeback rate** | chargeback payments ÷ charged payments (the processor's definition). `chargeback_amount_rate` uses amounts instead. |
| **Paying members** | Distinct members with a success or partially_refunded payment in the window |
| **ARPPU** | net ÷ paying members (`null` under 5) |
| **ARPU** | net ÷ active members in the window (see 3.6) |

**Product type**

| Product type | Rule |
|---|---|
| `coin_package` | `billing_reason='coin_purchase'`, or the checkout kind is `coin_package`. The product code is the package id. |
| `subscription` | The payment has a subscription, or a `subscription*` reason. The product code is `plan:cycle`. |
| `other` | Anything else |

Gifts are bought with coins, so their money is recognised when the coins are purchased, as a `coin_package` sale. Gift spend is a coin sink and is reported in the coin economy. The trend splits net into subscription, coin package and other.

**Refund timing.** A refund is attributed to the period of the original payment, because the schema has no refund timestamp. This matches reconciliation.

**Corrected legacy endpoints.** `/v1/admin/billing/revenue-analytics` and `/v1/admin/billing/stats` use the same code. They previously had four problems:

- they covered all time, with no window;
- they loaded whole tables into memory;
- they counted admin top-ups and promotions as coins sold and buyers;
- they counted only `success` payments, so partial refunds were lost.

Both now accept `since`, `until`, `tz` and `mode`. They return money per currency in minor units, plus a major-unit string.

**Agreement test.** `TestBusinessRevenueAgreesWithReconciliationPostgres` checks that business revenue with `mode=all` matches reconciliation on gross, refunded, chargebacks and net over the same window. Reconciliation adds every currency into a single number, so compare per currency only when the window holds one currency.

### 3.2 Subscriptions and MRR — `GET /v1/admin/business/subscriptions`

**MRR at an instant T** is the sum, over subscriptions, of the monthly run-rate of the latest settled payment period that covers T. A payment counts as settled if it is success, partially_refunded or disputed. "Covers" means `period_start ≤ T < period_end`. There are two exclusions:

- refunded and charged-back periods do not count;
- a subscription that is cancelled or expired with `end_date ≤ T` does not count.

The run-rate of a period depends on its type:

- **A normal period** (create or cycle): (amount − partial refund) ÷ period length in months (`round(seconds ÷ 30.44 days)`, at least 1). A yearly 12,000 gives 1,000 per month.
- **A plan change** (`subscription_update`, which is a prorated charge): the subscription's contracted `amount_minor`, divided by 12 for yearly plans.

Other subscription metrics:

| Metric | Definition |
|---|---|
| **ARR** | MRR × 12 |
| **Active subscribers** | Subscribers with MRR > 0 at T, per currency |
| **Snapshot boundaries** | The window start, every bucket start, and the window end. Instants after "now" are dropped, so periods that have not yet had a chance to renew are not counted as churn. |

**Movements** are computed per member and currency, between consecutive boundaries:

| Movement | Change |
|---|---|
| New | 0 → >0 (includes reactivations) |
| Expansion | Up |
| Contraction | Down, but still > 0 |
| Churned | >0 → 0 |

These satisfy MRR_start + new + expansion − contraction − churned = MRR_end, give or take one minor unit of rounding. A subscriber who starts and leaves between two boundaries is invisible to snapshots; use `bucket=day` when that matters.

**Churn rates**

| Rate | Definition |
|---|---|
| **Logo churn** | churned subscribers ÷ subscribers at the bucket start |
| **Revenue churn** | (churned + contraction MRR) ÷ starting MRR |
| **Net MRR retention** | (start + expansion − contraction − churned) ÷ start |

**Churn reasons.** Members are not yet asked why they cancel, so the reason is inferred. The rules are checked in this order:

1. `graduated`: a confirmed graduation in the 120 days before. This is healthy churn and is also excluded in `average_logo_churn_rate_ex_graduation`.
2. `chargeback`: `ended_reason='chargeback'`.
3. `refunded`: a fully refunded payment.
4. `payment_failed`: expired without a cancellation.
5. `member_cancelled`: `cancel_at_period_end`, `cancelled_at` set, or the subscription is cancelled.
6. `other`.

**Trials.** Billing has no trial primitive, so `trials.offered=false` and trial→paid does not apply.

**Graduation Refund (model).** Graduation records a `subscription_pause` reward for members with a live subscription. Billing has no pause or refund primitive yet, so no money has moved. The report estimates the cost as **unused whole months × monthly run-rate**. Only members who had been on the plan for at least one month qualify, matching the pricing promise. It also lists reward counts by kind and status.

### 3.3 Conversion and LTV — `GET /v1/admin/business/conversion`

| Metric | Definition |
|---|---|
| **Cohort** | Members by month of `users.created_at` in the reporting time zone |
| **Paid ≤ N days** | Members whose first charged payment (any product, selected mode) came within N days of signup. N is 7, 30 or 90; there is also a to-date count. A charged payment is the same as in gross. `mature_30d=false` means the cohort is too young for its 30-day figure to be final. |
| **Subscribed to date** | Members with any charged subscription payment |
| **LTV curve** | Cumulative net revenue of the cohort's members by month since signup (month 0 is the signup month), divided by the cohort size. Each currency has its own curve, capped at 24 months, and stops at the cohort's age. |
| **Actives conversion** | Subscribers with MRR at `until` (or now) ÷ members active in the 30 days before. The pricing strategy assumes 4–6%. |

### 3.4 Checkout funnel — `GET /v1/admin/business/funnel`

Covers checkout sessions created in the window. Card-update sessions are excluded.

| Stage | Definition |
|---|---|
| **created** | The session was created |
| **completed** | The provider marked the session completed |
| **paid** | A charged payment is linked to the session, either by `checkout_id` or as the subscription's first invoice (`subscription_create`) |
| **refunded** | The paid session's payment was refunded, partially refunded or charged back |

Rates are completion (completed ÷ created), paid (paid ÷ created) and refund (refunded ÷ paid). Results are grouped by kind, product and platform.

Paywall *views* are not instrumented, so the funnel starts at checkout creation. Checkout sessions do not record the client platform yet, so every row shows `not_captured`. To fix this, write `metadata.platform` when the checkout is created.

### 3.5 Coin economy — `GET /v1/admin/business/coins`

**Flows in the window**

| Kind | What counts |
|---|---|
| **Sources** | Purchased (`buy` from a payment provider, in the selected mode); granted (`admin_topup`, `promo`, `bootstrap`, `opening_balance`, never revenue); returned (`gift_refund`) |
| **Sinks** | Gift spend (`total_cost_coins` at send time, with refunded sends also listed); clawbacks (`wallet_coin_debits.coins_debited` by source) |

Boosts are not sold, because the pricing strategy rules them out. Theme packs are not built yet. Both appear with zero so the list of sinks is explicit.

**Liability (now, not windowed)**

- Outstanding coins (the sum of `coin_balance`), debt coins and frozen wallets.
- Only the **purchased share** of outstanding coins is valued, at the average price paid per coin in each currency. The purchased share is coins bought (selected mode) ÷ all coins ever credited. Granted coins carry no cash liability.

**Velocity** = coins spent in the window (gifts + clawbacks) ÷ coins outstanding now.

### 3.6 Active members (ARPU, MAU, north star)

1. If product analytics (migration 123) is installed **and every UTC day in the window has been built** (`analytics.snapshot_days.built_at`), active members are the distinct members in `analytics.member_active_days`, with the analytics exclusions applied.
2. Otherwise the count comes from `platform.member_last_activity`. This table keeps only first and last activity, so it is exact for a window ending now and an upper bound for a past window. The `*_source` field says which method was used.
3. In the investor pack, MAU for past months is `null` (shown as "unavailable") unless the analytics snapshots cover that month.

### 3.7 Referrals, K-factor and introducers — `GET /v1/admin/business/referrals`

The `referrals_enabled` flag defaults to off, so these figures stay empty until the owner turns it on.

| Metric | Definition |
|---|---|
| **Referrals** | Codes issued in the window and active codes; redemptions by status (recorded, verified, void); **activated** (non-void and the referred member is verified); **paid** (non-void and the referred member has a charged payment) |
| **Invites sent** | Not instrumented. Referral codes are reusable links and shares are not recorded. |
| **K-factor** | Pricing strategy 5.2: invites accepted per new member in their first 30 days, by signup cohort. `k_referral` = non-void redemptions of the member's own code within 30 days of their signup ÷ cohort members. `k_introducer` = the member's introducer invite links accepted within 30 days ÷ cohort members. `k_total` is the sum. |
| **K for introducer links** | Instrumented, so `invites_per_member × acceptance_rate` is also reported |
| **K targets** | 0.5 is healthy. Below 0.2, redesign the loops before spending on ads. |
| **Introducers** | Invites created, accepted, revoked and expired unused in the window; active and pending consents; friend intros by introducer kind (member introducers vs introducer accounts), with matched, declined, expired and open counts and the match rate |

### 3.8 Market and city launch readiness — `GET /v1/admin/business/markets`

**Who is counted.** A city's members must also not be deactivated, deletion-pending or banned. The city comes from the member's profile, lower-cased. `business.launch_markets.aliases` map spellings onto a market (`bangalore` → `bengaluru`).

**Gates per city.** The defaults are the strategy's assumptions from section 5.1. The owner sets the real values per market.

| Gate | Default | Measure |
|---|---|---|
| Verified members | 3,000 | `is_verified` members in the city |
| Gender balance | Larger share ≤ 0.60 | Share held by the larger of women and men among verified women + men (60/40). Other genders are counted and shown separately. The gate needs at least 5 verified women + men. |
| Plans kept per active member (launch → live) | ≥ 0.08 per week | Completed date plans in the last 7 days with a city member as proposer or invitee ÷ members active in the last 30 days |

**Status**

| Status | Rule |
|---|---|
| `ready` | Verified ≥ target **and** the gender gate is met |
| `approaching` | Not ready, and verified ≥ `approaching_share` (default 0.5) × target |
| `not_ready` | Anything else |
| `live_gate_met` | Ready, and the plans-kept gate is met |

**Also reported:** 30- and 7-day actives, new verified members in the last 30 days and the 30 days before, the growth rate, and projected days to target at the current pace. Membership date stands in for verification date, because verification time is not stored.

**Which cities appear.** Configured markets come first in launch order, even with no members yet. Other cities with at least 5 members follow, scored against the default gates. Smaller cities are pooled into one row with the status `not_assessed`.

**Overlap with product analytics.** Analytics owns engagement liquidity per city (matches, conversations, `analytics.daily_metrics` by city). This report computes only the launch gates and does not duplicate liquidity.

### 3.9 Investor KPI pack — `GET /v1/admin/business/investor-pack?months=12`

The pack has one row per month, split by currency for money.

| Field | Definition |
|---|---|
| `members_total` | Members who joined before the month end (current non-erased population) |
| `new_members`, `new_verified_members` | Members who joined in the month, and those of them who are verified now |
| `mau` | See 3.6 |
| `plans_kept` | Date plans completed in the month |
| `north_star` | Weekly plans kept per active member: plans kept ÷ weeks in the month ÷ MAU. It needs MAU. |
| `gross`, `net` | Revenue in the month (3.1) |
| `mrr`, `arr`, `subscribers` | At the month end (3.2) |
| `paying_members`, `arppu` | Members with a settled payment in the month; net ÷ paying members |
| `conversion` | Subscribers at month end ÷ MAU |
| `subscriber_churn_rate` | Subscribers lost in the month ÷ subscribers at the month start |
| `marketing_spend`, `cac`, `payback_months` | See section 4. Without spend these show "needs spend data". |
| `burn` | "not available". Take it from the finance system. |

**How to read it**

1. Check `data_status`. In release 1, live revenue is expected to be zero.
2. Read members, MAU and the north star first: density before money.
3. Read MRR and conversion against the 4–6% assumption, and churn with graduation kept separate.
4. Read CAC and payback only for months and currencies that have recorded spend.
5. Never add up currency rows.

To print, use the console's *Print* button: the print stylesheet hides navigation. The CSV export is `table=monthly`.

---

## 4. CAC inputs and marketing spend

**API**

| Call | Use |
|---|---|
| `GET /v1/admin/business/marketing-spend` | Entries plus CAC per month, market and currency |
| `POST /v1/admin/business/marketing-spend` | Upsert by (month, channel, market, currency). Returns 201 when created and 200 when replaced. |
| `PUT /v1/admin/business/marketing-spend/{id}` | Replace an entry. Returns 409 if another entry already has the same key. |
| `DELETE /v1/admin/business/marketing-spend/{id}` | Delete an entry |

All writes accept `Idempotency-Key` and are written to the operator audit trail.

**Request fields**

| Field | Values |
|---|---|
| `month` | `YYYY-MM` |
| `channel` | paid_social, search, influencer, events, referral_rewards, partnerships, pr, content, app_store or other |
| `market` | `all` or a launch-market `city_key` |
| `currency` | An ISO code |
| `amount_minor` or `amount` | `amount` is a decimal string in major units. More than 2 decimals is rejected; the 0-decimal currencies JPY, KRW, VND, CLP, ISK and UGX take whole numbers only. |
| `attributed_members` | Optional |
| `note` | Optional, up to 500 characters |

**Formulas**

| Measure | Formula |
|---|---|
| **CAC** | Spend in the month and currency ÷ members who joined that month (in that market, when the spend names a market) |
| **Attributed CAC** | Spend ÷ the members the channel itself reports (`attributed_members`) |
| **Payback (months)** | CAC ÷ (net revenue in the month ÷ MAU), in the same currency. When MAU is unknown, the month's members are the denominator. |

Spend in one currency is never converted to another.

**Without spend data**, CAC and payback show **"needs spend data"**, and the investor pack flags the missing input. The strategy's blended CAC assumptions (India ₹180, Europe €6) and its payback target (under 3 months) live in `PRICING_AND_GO_TO_MARKET_STRATEGY_2026-09-27.md` section 4. They are not hard-coded here.

---

## 5. Roles

Migration 124 adds the **`finance`** operator role. To grant it, insert into `user_management.auth_account_roles`. Locally, run `LOCAL_OPERATOR_ROLE=finance backend/scripts/provision_local_operator.sh`.

| Route | admin | finance | ops_admin | analyst | trust_safety / moderator |
|---|---|---|---|---|---|
| `GET /admin/business/*` | ✓ | ✓ | ✓ | ✓ | — |
| `POST/PUT/DELETE /admin/business/marketing-spend` | ✓ | ✓ | — | — | — |
| `POST /admin/business/markets` | ✓ | ✓ | ✓ | — | — |
| `GET` billing reports (stats, transactions, subscriptions, payments, webhook-events, reconciliation, revenue-analytics, plans, coin-packages) | ✓ | ✓ | ✓ | ✓ (as before) | — |
| `GET /admin/analytics/overview` (console login probe) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Coin grants, refunds, moderation, users, configuration | ✓ | — | as before | — | as before |

The handlers check roles again, in addition to the security middleware. Operator audit rows record `actor_role='finance'`, and `audit.operator_action_log` includes it.

---

## 6. Console — "Business" section

| Page | Path | Shows |
|---|---|---|
| Revenue | `/business/` | KPI tiles per currency; net and refund trend charts (one line per currency); totals, product, payer-city and trend tables; link to reconciliation for the same window |
| Subscriptions & MRR | `/business/subscriptions/` | MRR line per currency; MRR movements waterfall for the chosen currency (start, new, expansion, contraction, churned, end); movements, churn reasons, plan mix and Graduation Refund tables; trial note |
| Conversion & funnel | `/business/conversion/` | Cohort conversion, LTV curves (up to M12), actives conversion; checkout funnel chart and table |
| Coin economy | `/business/coins/` | Sources-and-sinks chart; liability, valuation and velocity tiles; purchases, non-revenue credits, top gifts and clawbacks |
| Referrals | `/business/referrals/` | K-factor tiles and cohort table, introducer programme, flag state |
| Market readiness | `/business/markets/` | City table with gates and status badges; form to add or update a launch market and its gates |
| Investor KPI pack | `/business/investor-pack/` | Monthly KPI table, "how to read" definitions, printable layout, CSV |
| Marketing spend | `/business/spend/` | Form to record spend, list of entries with delete, CAC table |

Every page has filters for date range, time zone, data mode (live, sandbox, or live + sandbox), bucket and months, plus CSV downloads for each table. CSVs are proxied through Django with the operator's token, so the browser never holds BFF credentials. Charts use Chart.js only. When billing data is empty, the pages explain that billing is off in release 1 and point to sandbox mode if sandbox data exists.

The existing **Billing → Revenue** page (`/billing/revenue/`) now uses the corrected API. It has a window, mode and time zone; revenue per currency; purchases separated from grants; and local activations excluded. The billing dashboard tiles show the last 30 days of live net revenue per currency.

---

## 7. Limitations

- **Billing is excluded from release 1.** Live figures will be zero, and IAP (Apple/Google) is not built. When IAP ships, its providers (`apple_iap`, `google_play`) are already classified as live.
- **Stripe test mode** is detected from the server's key prefix and from `livemode=false`. If a database ever holds both test and live Stripe rows without `livemode` metadata, the test rows will count as live.
- **Refunds** are dated at the original payment, not the refund event.
- **MRR is snapshot-based.** Same-bucket start-and-churn is invisible, and plan changes use the contracted amount.
- **Churn reasons are inferred,** because cancellation reasons are not captured from members yet.
- **Paywall views and checkout platform** are not instrumented.
- **Historical MAU** needs the analytics daily snapshots. Without them, past-month MAU and the north star are unavailable.
- **Verification time** is not stored, so verified growth uses the signup date.
- **The Graduation Refund** is modelled only. No billing primitive pays it yet.
- **Burn** is not available from product data.
- **Reconciliation adds currencies together** in its single gross/net figure. Compare it per currency only for single-currency windows.

## 8. What the owner must provide

1. **Marketing spend** per month, channel, market and currency (console → Business → Marketing spend), so CAC and payback are computed.
2. **Finance role assignments** for the people who read money and record spend.
3. **The market list and gates.** Confirm or change the seeded launch markets: Bengaluru, London, Dublin, Berlin, Vienna, Zurich, Paris, Amsterdam, Warsaw, Madrid, Milan and Lisbon. Choose the second Indian metro. Replace the assumed gates (3,000 verified, 60/40, 0.08 plans kept per active member, approaching from 50%) with decisions. Set CHF prices for Zurich.
4. **Turn on `referrals_enabled`** when referral credits are approved; until then referral K stays empty.
5. **Instrumentation decisions:** record `metadata.platform` on checkout sessions; capture cancellation reasons; record paywall views (product analytics).
