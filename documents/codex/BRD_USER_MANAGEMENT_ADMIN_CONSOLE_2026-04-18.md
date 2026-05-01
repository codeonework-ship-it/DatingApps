# BRD: User Management Admin Console
**Document ID:** BRD-UMA-001
**Date:** 2026-04-18
**Status:** Approved for Implementation
**Author:** Product / Web Development
**Scope:** Control Panel (Django), Go BFF Admin API, PostgreSQL
**Priority:** P0 (blocking) — user list shows blanks, detail page is empty

---

## 1. Executive Summary

The AegisConnect Operator Console's User Management page is partially non-functional.
The user list renders "—" for names and phones because the Django template references
`display_name`/`phone_number` while the Go handler returns `name`/`phone`. The user
detail page is completely empty because the Go handler returns a flat JSON row but
Django expects a `{"user": {...}}` wrapper. Additionally, verified badge, coin balance,
and last-seen always show defaults because these columns aren't in the SELECT query.

Beyond fixing the data pipeline, the module is missing critical admin capabilities
called for in BRD-ACP-001: ban/unban, force-verify, grant coins, profile editing,
match/gift history, and trust/report panels.

This BRD defines requirements to fix the broken pipeline and build a full-featured
user management console.

---

## 2. Problem Statement

### 2.1 Response Wrapping Mismatch (Severity: Critical)

`adminGetUser` in server_admin_extended.go returns:
```go
writeJSON(w, http.StatusOK, rows[0])
```

Django user_detail view does:
```python
"user": result.data.get("user", {})
```

Result: template context `user` is always `{}` — the entire detail page is blank.

### 2.2 Field Name Mismatches (Severity: High)

| Template Field | Go Returns | Renders As |
|---|---|---|
| `u.display_name` | `name` | "—" |
| `u.phone_number` | `phone` | "—" |
| `u.is_verified` | *(not selected)* | Always "No" |
| `u.coin_balance` | *(not selected, cross-schema)* | Always "0" |
| `u.last_seen_at` | *(not selected)* | Always "—" |

### 2.3 Count Key Mismatch

Go returns `"count"` in user list response, Django reads `"total"` — pagination counter shows 0.

### 2.4 Missing Admin Actions

No ban/unban, no force-verify, no grant coins UI, no profile edit, no gender filter.

---

## 3. Goals

| # | Goal | Measure |
|---|---|---|
| G1 | User list displays all fields correctly | Name, phone, verified, status render real data |
| G2 | User detail page is functional | Full profile loads with 20+ fields from DB |
| G3 | Admin can ban/unban users | is_banned toggleable via UI buttons |
| G4 | Admin can force-verify users | is_verified settable without selfie upload |
| G5 | Admin can grant coins | Coins added to wallet with audit trail |
| G6 | Admin can view wallet & transactions | Balance + purchase history on user detail |
| G7 | User KPIs visible on list page | Total, active, suspended, banned, verified % |

---

## 4. Personas

| Persona | Role | Use Case |
|---|---|---|
| **Ops Admin** | Customer Support | Views user profiles, suspends abusers, grants coins for compensation |
| **Trust & Safety** | Moderation | Bans serial offenders, force-verifies trusted users |
| **Growth Analyst** | Analytics | Views user counts, filters by status/gender, exports data |

---

## 5. Feature Requirements

### 5.1 P0 — Fix Data Pipeline

**FR-01: Fix adminGetUser response**
Wrap response in `{"user": row}` to match Django's `.get("user")`.

**FR-02: Fix SELECT columns**
Add `is_verified, last_login_at, bio, height_cm, education, profession, city, state, country, profile_completion` to both list and detail SELECTs.

**FR-03: Fix count key**
Change `"count"` to `"total"` in adminListUsers response.

**FR-04: Fix template field names**
- users.html: `display_name` → `name`, `phone_number` → `phone`
- user_detail.html: same + `last_seen_at` → `last_login_at`

### 5.2 P1 — Admin Actions

**FR-05: Ban/Unban**
- New Go endpoints: `POST /admin/users/{userID}/ban`, `POST /admin/users/{userID}/unban`
- Django views: `user_ban`, `user_unban` with flash messages
- UI: Red "Ban User" button with reason form; "Unban" button when banned

**FR-06: Force-Verify**
- New Go endpoint: `POST /admin/users/{userID}/verify`
- Django view: `user_force_verify`
- UI: Blue "Force Verify" button on non-verified users

**FR-07: Grant Coins**
- UI form on user detail: amount (number input) + reason (text)
- Calls existing `GoBFFClient.grant_coins()` → `POST /wallet/{userID}/coins/top-up`
- Django view: `user_grant_coins`

**FR-08: Wallet & Transaction Display**
- On user detail, show wallet coin_balance via separate API call
- Show recent purchases via `GET /v1/wallet/{userID}/coins/audit`

**FR-09: User KPI Cards**
Above user list table: Total Users, Active, Suspended, Banned, Verified %

**FR-10: Rich Profile Panel**
User detail shows: gender, bio, height, education, profession, city/state/country, profile completion bar

**FR-11: Gender Filter**
Add gender dropdown to user list filter bar, pass as `?gender=male` to Go handler.

---

## 6. Acceptance Criteria

**AC-1:** User list displays name and phone for all rows.
**AC-2:** User detail page loads with full profile data (not blank).
**AC-3:** Verified badge reflects actual DB value.
**AC-4:** Ban → user shows "Banned" badge; Unban → reverts to "Active".
**AC-5:** Force-Verify → user shows verified badge immediately.
**AC-6:** Grant coins → wallet balance increases; audit record created.
**AC-7:** KPI cards show accurate counts.
**AC-8:** Gender filter narrows results correctly.
**AC-9:** All actions produce flash messages (success/error).
**AC-10:** No regression on mobile `/v1/users/*` or `/v1/wallet/*` endpoints.

---

## 7. UI Wireframe — User List

```
┌─────────────────────────────────────────────────────────────┐
│ 👤 User Management                                          │
│ Search, view, and manage all registered users               │
├─────────────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐              │
│ │ 1247 │ │ 1198 │ │  32  │ │   5  │ │ 78%  │              │
│ │Total │ │Active│ │Susp. │ │Banned│ │Verif.│              │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘              │
├─────────────────────────────────────────────────────────────┤
│ Search: [___________] Status: [▼All] Gender: [▼All] [Go]   │
├─────────────────────────────────────────────────────────────┤
│ User          │ Phone        │ Gender │ Joined │ Status     │
│ John Smith    │ +91 987...   │ Male   │ Apr 26 │ ● Active   │
│ Priya K       │ +91 876...   │ Female │ Mar 26 │ ● Verified │
│ Alex R        │ +91 765...   │ Male   │ Feb 26 │ ⚠ Suspended│
└─────────────────────────────────────────────────────────────┘
```

## 8. UI Wireframe — User Detail

```
┌─────────────────────┬───────────────────────────────────────┐
│   PROFILE CARD      │  ── Actions ──────────────────────── │
│                     │  Suspend: [reason____] [days] [Go]   │
│   [Avatar Circle]   │  Ban:     [reason____]        [Ban]  │
│   John Smith        │  Verify:              [Force Verify] │
│   +91 98765 43210   │                                       │
│   ● Active ✓ Verif  │  ── Grant Coins ──────────────────── │
│                     │  Amount: [___] Reason: [_____] [Grant]│
│   Joined: Apr 2026  │                                       │
│   Last Seen: Today  │  ── Wallet ───────────────────────── │
│   Coins: 🪙 245     │  Balance: 🪙 245                      │
│                     │  Recent Transactions:                 │
│  ── Profile ──      │  ┌──────┬──────┬────────┬──────────┐ │
│  Gender: Male       │  │Coins │Source│Provider│Date      │ │
│  Height: 178cm      │  │ +100 │buy   │stripe  │Apr 15    │ │
│  Education: Masters │  │  -3  │gift  │internal│Apr 14    │ │
│  Profession: Eng.   │  └──────┴──────┴────────┴──────────┘ │
│  City: Bangalore    │                                       │
│  Completion: 80%    │  ── Raw Data ─────────────────────── │
└─────────────────────┴───────────────────────────────────────┘
```

---

## 9. Technical Implementation

### Files Modified
| File | Changes |
|---|---|
| `server_admin_extended.go` | Fix user response wrapping, SELECT columns, add ban/unban/verify endpoints |
| `server.go` | Register new admin routes |
| `views.py` | Add ban/unban/verify/grant views |
| `go_client.py` | Add ban/unban/verify client methods |
| `urls.py` | Add new URL patterns |
| `users.html` | Fix field names, add KPI cards, gender filter |
| `user_detail.html` | Fix field names, add all action panels, rich profile |

### No DB Migration Required
User columns `is_verified`, `is_banned`, `suspended_*` already exist. Wallet tables exist.

---

## 10. Test Scenarios

| # | Scenario | Expected |
|---|---|---|
| TS-1 | Navigate to /users/ | Users render with names and phones |
| TS-2 | Click user → /users/{id}/ | Full profile visible |
| TS-3 | Ban a user | "Banned" badge, is_banned=true in DB |
| TS-4 | Unban the user | "Active" badge restored |
| TS-5 | Force-verify | "Verified" badge appears |
| TS-6 | Grant 50 coins | Wallet +50, audit record created |
| TS-7 | Filter by "suspended" | Only suspended users |
| TS-8 | Filter by gender "male" | Only male users |
| TS-9 | Search "john" | ilike matching |
| TS-10 | Backend unavailable | Error flash message |

---

## 11. Sprint Plan

| Sprint | Scope | Duration |
|---|---|---|
| Sprint 1 (P0) | FR-01–FR-04: Fix data pipeline + field alignment | 1 day |
| Sprint 2 (P1) | FR-05–FR-11: Ban, verify, grant, wallet, KPIs, profile, filters | 3 days |
| Sprint 3 (P2) | Edit, history, reports, timeline | 3 days |

---

*Document ends.*
