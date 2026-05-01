# BRD: Billing & Plans Admin Console
**Document ID:** BRD-BPA-002
**Date:** 2026-04-18
**Status:** Approved for Implementation
**Author:** Product / Web Development
**Scope:** Control Panel (Django), Go BFF Admin/Client API, PostgreSQL
**Priority:** P0 (blocking) — plan prices show $0.00, package names blank

---

## 1. Executive Summary

The Billing & Monetisation page has two categories of issues:

1. **Field mismatches**: The subscription plans section shows "$0.00" prices and "—"
   billing periods because the in-memory plan struct returns `monthly_price`/
   `yearly_price` while the template renders `plan.price_usd`/`plan.billing_period`.
   Coin packages show blank names because Go returns `label` but the template uses
   `pkg.name`.

2. **Missing capabilities**: No plan create/edit, no package create/edit, no payment
   transaction log, no subscription lookup by user, no revenue analytics.

Additionally, subscription plans, user subscriptions, and payment records are entirely
in-memory (lost on restart) — violating the persistence-first policy. The persistence
backlog lists `billing_subscriptions_runtime` and `billing_payments_runtime` tables
as P2 priority.

This BRD fixes the display bugs and builds a full billing admin console.

---

## 2. Problem Statement

### 2.1 Plan Field Naming (Severity: High)

In-memory `subscriptionPlan` struct fields:
```
id, name, monthly_price, yearly_price, likes_per_day,
messages_per_day, features []string
```

Template billing.html renders:
```
plan.price_usd     → does not exist → "$0.00"
plan.billing_period → does not exist → "—"
plan.is_active     → does not exist → always "Inactive"
```

### 2.2 Coin Package Name (Severity: Medium)

DB column and Go response: `label`
Template: `pkg.name` → blank

### 2.3 Persistence Gap (Severity: Medium — Architectural)

| State | Storage | Risk |
|---|---|---|
| Subscription plans | Memory array | Lost on restart |
| User subscriptions | Memory map | Lost on restart |
| Payment records | Memory map | Lost on restart |
| Coin packages | Durable (DB) | OK |
| Wallet balances | Durable (DB) | OK |
| Wallet purchases | Durable (DB) | OK |

---

## 3. Goals

| # | Goal | Measure |
|---|---|---|
| G1 | Plan prices display correctly | Monthly/yearly amounts visible |
| G2 | Coin package names visible | `label` field rendered |
| G3 | Admin can create/edit coin packages | Full CRUD for packages |
| G4 | Payment transaction log available | Paginated list of wallet_coin_purchases |
| G5 | Subscription lookup by user | View user's plan and payment history |
| G6 | Plan comparison view | Side-by-side feature comparison cards |
| G7 | Durable billing_plans table | Plans survive backend restart |

---

## 4. Personas

| Persona | Role | Use Case |
|---|---|---|
| **Billing Admin** | Monetisation Ops | Creates/edits packages, toggles plans, views transaction logs |
| **Customer Support** | Support | Looks up user subscription, grants coins, checks payments |
| **Product Manager** | Growth | Views revenue KPIs, adjusts pricing/feature allocations |

---

## 5. Feature Requirements

### 5.1 P0 — Fix Display

**FR-01: Fix plan template fields**
- `plan.price_usd` → show `plan.monthly_price` and `plan.yearly_price`
- Remove `plan.billing_period` (plans have both monthly and yearly)
- Remove `plan.is_active` badge (memory plans always active)
- Add likes/day and messages/day columns

**FR-02: Fix coin package name**
- `pkg.name` → `pkg.label` throughout billing.html

### 5.2 P1 — Essential Billing Admin

**FR-03: Plan Comparison Cards**
Replace plans table with Bootstrap cards:
- Plan name + tier badge (Free=green, Premium=purple, VIP=gold)
- Monthly and yearly prices
- Feature list with check/cross icons
- Likes/day and messages/day

**FR-04: Coin Package Create/Edit**
- New Go endpoints: POST + PUT `/v1/admin/billing/coin-packages`
- Django views: `billing_package_new`, `billing_package_edit`
- Form: label, coin_amount, price_usd, bonus_percent, sort_order, is_active

**FR-05: Payment Transaction Log**
- New Go endpoint: `GET /v1/admin/billing/transactions`
  → queries `matching.wallet_coin_purchases` table
- Django view: `billing_transactions`
- Template with filters: source, provider, date range
- Paginated table: user_id, coins, amount, source, provider, date

**FR-06: Billing KPI Cards**
Above plans: Total Packages, Active Packages, Total Coins Purchased, Revenue, Unique Buyers

**FR-07: Admin Coin Grant from Billing**
Quick top-up section: user_id + amount + reason

### 5.3 P2 — Durable & Advanced

**FR-08: Durable Billing Plans Migration**
Create `matching.billing_plans` table with columns matching in-memory struct.
Seed with Free/Premium/VIP from current defaults. Update billing module gateway.

**FR-09: Durable Subscriptions & Payments**
Tables per persistence backlog: `billing_subscriptions_runtime`, `billing_payments_runtime`.

**FR-10: Revenue Analytics Dashboard**
Aggregated queries against wallet_coin_purchases.

---

## 6. Acceptance Criteria

**AC-1:** Plan prices display as amounts (monthly + yearly columns).
**AC-2:** Coin package labels render correctly.
**AC-3:** Admin can create a new coin package via form → appears in list.
**AC-4:** Admin can edit existing package → changes reflected.
**AC-5:** Transaction log shows real wallet_coin_purchases data.
**AC-6:** KPI cards show accurate metrics.
**AC-7:** All actions produce flash messages.
**AC-8:** Mobile `/v1/billing/**` endpoints unaffected.
**AC-9:** Coin packages CRUD survives backend restart (durable).
**AC-10:** Coin package bonus_percent column available after migration.

---

## 7. UI Wireframe — Billing Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│ 💳 Billing & Monetisation                                   │
├─────────────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐              │
│ │  5   │ │  4   │ │12.5K │ │$892  │ │  87  │              │
│ │Pkgs  │ │Active│ │Coins │ │Rev.  │ │Buyers│              │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘              │
├─────────────────────────────────────────────────────────────┤
│              SUBSCRIPTION PLANS                             │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│ │   🟢 FREE   │ │  🟣 PREMIUM │ │  🟡 VIP     │           │
│ │  ₹0/mo      │ │  ₹499/mo    │ │  ₹999/mo    │           │
│ │  ₹0/yr      │ │  ₹4990/yr   │ │  ₹9990/yr   │           │
│ │ 15 likes/d  │ │ 100 likes/d │ │ 500 likes/d │           │
│ │ 30 msgs/d   │ │ 500 msgs/d  │ │ 2000 msgs/d │           │
│ │ ✓ Basic     │ │ ✓ Filters   │ │ ✓ Everything│           │
│ └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│ COIN PACKAGES                          [+ New Package]     │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│ │ Starter │ │ Popular │ │ Best Val│ │ Premium │          │
│ │ 🪙 100   │ │ 🪙 500   │ │ 🪙 1200  │ │ 🪙 3000  │          │
│ │ $0.99   │ │ $3.99   │ │ $7.99   │ │ $17.99  │          │
│ │ ● Live  │ │ ● Live  │ │ ● Live  │ │ ● Live  │          │
│ │[Edit][⚡]│ │[Edit][⚡]│ │[Edit][⚡]│ │[Edit][⚡]│          │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
├─────────────────────────────────────────────────────────────┤
│ RECENT TRANSACTIONS                    [View All →]        │
│ ┌──────┬────────┬──────┬────────┬──────┬─────────────────┐ │
│ │User  │Coins   │Amount│Source  │Prov. │Date             │ │
│ │a1b2..│ +500   │$3.99 │buy     │stripe│Apr 18, 2026     │ │
│ │c3d4..│ +100   │$0    │admin   │admin │Apr 17, 2026     │ │
│ └──────┴────────┴──────┴────────┴──────┴─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Technical Implementation

### Files Modified
| File | Changes |
|---|---|
| `server_admin_extended.go` | Add billing transaction list, coin package CRUD endpoints |
| `server.go` | Register new admin billing routes |
| `views.py` | Add billing transaction, package create/edit views |
| `go_client.py` | Add transaction list, package create/update methods |
| `urls.py` | Add billing sub-routes |
| `billing.html` | Fix field names, plan cards, KPI cards, transaction preview |
| `coin_package_edit.html` | New: package create/edit form |
| `billing_transactions.html` | New: payment transaction log |

### DB Migration Required
Migration 047: Add `bonus_percent` and `description` columns to `matching.coin_packages`.
Create `matching.billing_plans` table for durable plan storage (P2 prep).

---

## 9. Test Scenarios

| # | Scenario | Expected |
|---|---|---|
| TS-1 | Load /billing/ | Plan cards show prices, package labels display |
| TS-2 | Click "New Package" → fill → submit | Package created in DB |
| TS-3 | Edit existing package price | Updated in DB |
| TS-4 | Toggle package active/hidden | Status flips |
| TS-5 | View transactions log | wallet_coin_purchases data |
| TS-6 | Filter transactions by source=buy | Only purchases shown |
| TS-7 | Backend restart → reload billing | Packages persist |
| TS-8 | No transactions yet | "No transactions" empty state |

---

## 10. Sprint Plan

| Sprint | Scope | Duration |
|---|---|---|
| Sprint 1 (P0) | FR-01–FR-02: Fix field alignment | 0.5 day |
| Sprint 2 (P1) | FR-03–FR-07: Cards, CRUD, transactions, KPIs | 3 days |
| Sprint 3 (P2) | FR-08–FR-10: Durable migration, analytics | 3 days |

---

*Document ends.*
