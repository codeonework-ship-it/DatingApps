# Business Requirements Document (BRD)
## AegisConnect Admin Control Panel — v1.0

| Field | Value |
|---|---|
| **Document ID** | BRD-ACP-001 |
| **Version** | 1.0 |
| **Date** | 11 April 2026 |
| **Author** | GitHub Copilot (AI BA / PM) |
| **Status** | APPROVED — Implementation In Progress |
| **Scope** | Django admin control panel — 8 feature sections controlling all live app content |

---

## 1. Executive Summary

The AegisConnect Admin Control Panel is a Django-based operator console that gives product managers and administrators full runtime control over every configurable aspect of the mobile app — without requiring a new app build or backend deployment. All changes made in the control panel take effect immediately in the Flutter app, driven through the Go BFF's admin API endpoints.

### Business Objectives
- **Zero-build content updates**: PM can add a gift item, change a daily prompt, or toggle a feature flag and the app reflects it within seconds.
- **Centralised moderation**: All reports, appeals, and verifications handled from one console.
- **User management**: Suspend, unsuspend, verify, and reward users from the control panel.
- **Analytics visibility**: Real-time KPIs, DAU/MAU, match funnel, gift metrics all on one dashboard.

---

## 2. Architecture

```
Control Panel (Django :9000)
    ├─ All pages call Go BFF via GoBFFClient (X-Admin-User header)
    ├─ Bootstrap 5 + custom glassmorphism CSS
    └─ No direct DB access — all state via Go BFF
            │
            ▼
    Go BFF (:8081) — admin endpoints (X-Admin-User gated)
            │
            ▼
    PostgreSQL / Supabase — single source of truth
            │
            ▼
    Flutter App — reads same BFF endpoints → instant update
```

---

## 3. Database Changes

### Migration 046 — platform_feature_flags
```sql
CREATE TABLE IF NOT EXISTS matching.platform_feature_flags (
    key          TEXT        NOT NULL,
    value_bool   BOOLEAN     NOT NULL DEFAULT TRUE,
    description  TEXT,
    updated_by   TEXT        NOT NULL DEFAULT 'system',
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT platform_feature_flags_pkey PRIMARY KEY (key)
);
-- Seed default flags
INSERT INTO matching.platform_feature_flags (key, value_bool, description) VALUES
  ('gifts_enabled',               TRUE,  'Show/hide gift tray in chat'),
  ('voice_icebreakers_enabled',   TRUE,  'Show/hide voice icebreaker CTA'),
  ('rooms_enabled',               TRUE,  'Show/hide conversation rooms tab'),
  ('calls_enabled',               TRUE,  'Show/hide video call button'),
  ('billing_enabled',             TRUE,  'Show/hide paywall and billing'),
  ('quest_workflow_v2_enabled',   TRUE,  'Use quest workflow v2'),
  ('circles_enabled',             TRUE,  'Enable community circles'),
  ('daily_prompts_enabled',       TRUE,  'Show daily engagement prompts')
ON CONFLICT (key) DO NOTHING;
```

### Migration 047 — user_suspension_columns
```sql
ALTER TABLE user_management.users
  ADD COLUMN IF NOT EXISTS suspended_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS suspended_reason  TEXT,
  ADD COLUMN IF NOT EXISTS suspended_until   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_banned         BOOLEAN NOT NULL DEFAULT FALSE;
```

---

## 4. Go BFF New Admin Endpoints

All require `X-Admin-User` header.

| Method | Path | Description |
|---|---|---|
| GET | `/v1/admin/catalog/gifts` | List all gift catalog items |
| POST | `/v1/admin/catalog/gifts` | Create new gift item |
| PUT | `/v1/admin/catalog/gifts/{giftID}` | Update gift item |
| POST | `/v1/admin/catalog/gifts/{giftID}/toggle` | Toggle is_active |
| GET | `/v1/admin/users` | List users (paginated, filterable) |
| GET | `/v1/admin/users/{userID}` | Get user detail |
| POST | `/v1/admin/users/{userID}/suspend` | Suspend user |
| POST | `/v1/admin/users/{userID}/unsuspend` | Unsuspend user |
| GET | `/v1/admin/config/flags` | List feature flags |
| PUT | `/v1/admin/config/flags/{key}` | Update feature flag |
| GET | `/v1/admin/engagement/prompts` | List daily prompts |
| POST | `/v1/admin/engagement/prompts` | Create daily prompt |
| PUT | `/v1/admin/engagement/prompts/{promptID}` | Update daily prompt |
| POST | `/v1/admin/engagement/prompts/{promptID}/activate` | Set as today's prompt |
| GET | `/v1/admin/billing/plans` | List billing subscription plans |
| GET | `/v1/admin/billing/coin-packages` | List coin packages |
| GET | `/v1/admin/safety/sos-alerts` | List SOS alerts |
| POST | `/v1/admin/safety/sos-alerts/{alertID}/resolve` | Resolve SOS alert |

---

## 5. Control Panel Sections

### 5.1 Dashboard
- KPI cards: Total Users, DAU, New Today, Profile Completion Rate, Active Matches, Gifts Sent Today
- DAU trend chart (Chart.js line chart, 7-day)
- Match funnel chart (swipes → likes → matches → chats)
- Gift sends by category (doughnut chart)
- Alert rail: Active SOS, Open Reports, Pending Verifications, Pending Appeals
- BFF + Gateway health badges

### 5.2 Gift Catalog Management
- Full CRUD for `matching.gift_catalog`
- Toggle active/inactive instantly → app reflects within seconds
- Fields: display_name, category, coin_cost, icon_emoji, icon_url, max_per_match_per_day, start_date, end_date, sort_order
- Category filter tabs: All / Roses / Themed Pack / Reaction / Experience / Seasonal / Exclusive

### 5.3 User Management
- Paginated user list with search by name/phone
- Filter by: status, verified, gender, subscription tier
- User detail: profile photo, bio, trust badges, coin balance, match count, reports filed
- Actions: Suspend (with reason + duration), Unsuspend, Force-Verify, Grant Coins

### 5.4 Content Moderation
- Verification queue (existing — enhanced UI)
- Reports queue with SLA traffic light (>48h = red)
- Appeals queue (existing — enhanced UI)
- Report detail with reporter/reportee cards and message excerpts
- Actions: Warn / Suspend / Ban / Dismiss

### 5.5 Engagement Configuration
- Daily prompts CRUD: create/edit/schedule/activate
- Nudge template management: trigger type, message, active state
- Community groups/circles: list, moderate, feature

### 5.6 Billing & Plans
- Subscription plan editor: name, price, duration, rose allocation, features
- Coin package editor: label, amount, price, active state
- Recent payment transaction log
- Active subscription lookup by user

### 5.7 Feature Flags & Live Config
- Toggle any feature flag → instant effect in app
- Master data editor: education, religion, income, diet, workout options
- All changes written to DB → served by BFF on next app call

### 5.8 Safety & SOS
- Active SOS alert feed with real-time status
- Resolve alert with audit trail
- Emergency contact notification status
- Safety report summary

---

## 6. UI/UX Design

- **Style**: Glassmorphism + Bootstrap 5 — frosted glass sidebar, gradient backgrounds, glowing KPI cards
- **Colour palette**: Deep purple/indigo gradient background, gold/amber accent, white frosted panels
- **Charts**: Chart.js (embedded CDN, no npm required)
- **Icons**: Bootstrap Icons
- **Sidebar**: Collapsible with section grouping and active state highlighting
- **Responsive**: Works on 1280px+ desktop screens

---

## 7. Acceptance Criteria (Key)

| AC# | Criterion |
|---|---|
| AC-1 | Adding a gift in the catalog → next `GET /v1/chat/gifts` from the app returns it |
| AC-2 | Toggling `gifts_enabled = false` → app gift tray hidden within one poll cycle |
| AC-3 | Suspending a user → BFF returns 403 on user's next authenticated request |
| AC-4 | Activating a daily prompt → `GET /v1/engagement/daily-prompt/{userID}` returns new question |
| AC-5 | Control panel accessible at `localhost:9000` with `admin` / `admin@123` |
| AC-6 | All pages load within 1 second with BFF healthy |
| AC-7 | All write actions show success/error toast feedback |

---

## 8. Definition of Done

- [ ] All 8 Django sections implemented with full Bootstrap 5 glassmorphism UI
- [ ] All Go BFF admin endpoints implemented and registered in server.go
- [ ] DB migrations 046–047 applied
- [ ] Django superuser `admin` / `admin@123` created
- [ ] Django runserver accessible at `http://localhost:9000`
- [ ] Gift catalog CRUD: adding a gift reflects in app API
- [ ] Feature flags GET/PUT working end-to-end
- [ ] All existing tests passing: `go test ./...`
- [ ] `make backend-compliance-check` passing

---

*End of BRD-ACP-001 v1.0*
