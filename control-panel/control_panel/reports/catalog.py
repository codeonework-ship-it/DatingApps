"""The report catalog: every report the console's report server offers.

Business reports read /v1/admin/business/<name> (documents/
BUSINESS_REPORTS_2026-10-01.md); product reports read the durable analytics
snapshots at /v1/admin/analytics/<name>, which describe their own tables.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from .model import (BOOL, DATE, INT, MONEY, NUMBER, PCT, SUM, TEXT, Chart, Dataset, Field, Param,
                    Report)

# ── Parameters ────────────────────────────────────────────────────────────

SINCE = Param("since", "From", "date", help="First day, inclusive.")
UNTIL = Param("until", "To", "date", help="Last day, inclusive.")
TZ = Param("tz", "Time zone", choices=tuple((z, z) for z in (
    "UTC", "Asia/Kolkata", "Europe/London", "Europe/Berlin", "Europe/Paris", "Europe/Warsaw")), default="UTC")
MODE = Param("mode", "Payments", choices=(("live", "Live"), ("sandbox", "Sandbox"), ("all", "Live + sandbox")),
             default="live", help="Sandbox payments come from QA only.")
BUCKET = Param("bucket", "Period", choices=(("day", "Day"), ("week", "Week"), ("month", "Month")), default="week")
MONTHS = Param("months", "Months", "int", default="12", min=1, max=36)
BUSINESS_PARAMS = (SINCE, UNTIL, TZ, MODE, BUCKET)

A_FROM = Param("from", "From (UTC)", "date")
A_TO = Param("to", "To (UTC)", "date")
A_GRAIN = Param("grain", "Grain", choices=(("day", "Day"), ("week", "Week"), ("month", "Month")), default="day")
A_GENDER = Param("gender", "Gender", choices=(("female", "Female"), ("male", "Male"), ("other", "Other")))
A_CITY = Param("city", "City", "text")
ANALYTICS_PARAMS = (A_FROM, A_TO, A_GRAIN, A_GENDER)
# Go defaults retention cohorts and safety trends to weeks (only when grain is
# absent), so the report server must not override that with "day".
A_GRAIN_WEEK = Param("grain", "Grain", choices=A_GRAIN.choices, default="week")
WEEKLY_PARAMS = (A_FROM, A_TO, A_GRAIN_WEEK, A_GENDER)
A_METRIC = Param("metric", "Metric", choices=(
    ("dau", "Daily active members"), ("wau", "Weekly active members"), ("mau", "Monthly active members"),
    ("signups", "Signups"), ("matches", "Matches"), ("messages_sent", "Messages sent"), ("dates_kept", "Dates kept")),
    default="dau", help="One metric per run (Go's /admin/analytics/definitions lists them all).")


def _money(key: str, label: str, **kw) -> Field:
    return Field(key, label, MONEY, SUM, minor=f"{key}_minor", **kw)


def _count(key: str, label: str, **kw) -> Field:
    return Field(key, label, INT, SUM, **kw)


def _rate(key: str, label: str) -> Field:
    # Rates are never summed or averaged across rows (that would misstate
    # them); Go's own totals carry the true rate.
    return Field(key, label, PCT)


CURRENCY = Field("currency", "Currency", width=10)

# ── Business ──────────────────────────────────────────────────────────────

REVENUE = Report(
    "revenue", "Revenue", "Business",
    "Gross, refunds, chargebacks and net revenue by currency, market, product, payer city and period.",
    ("business", "revenue"), BUSINESS_PARAMS,
    datasets=(
        Dataset("totals", "Totals by currency and market", ("totals",), (
            CURRENCY, Field("market", "Market"), _money("gross", "Gross"), _money("refunded", "Refunded"),
            _money("chargeback", "Chargebacks"), _money("disputed", "Disputed (held)"), _money("net", "Net"),
            _count("settled_payments", "Settled payments"), _count("paying_members", "Paying members"),
            Field("arppu", "ARPPU", MONEY, minor="arppu_minor"), Field("arpu", "ARPU", MONEY, minor="arpu_minor"),
            _rate("refund_rate", "Refund rate"), _rate("chargeback_rate", "Chargeback rate"),
        ), group_by=("currency",), groupable=("currency", "market")),
        Dataset("by_product", "By product", ("by_product",), (
            CURRENCY, Field("product_type", "Type"), Field("product_code", "Product", width=24),
            _count("payments", "Payments"), _money("gross", "Gross"), _money("refunded", "Refunded"),
            _money("chargeback", "Chargebacks"), _money("net", "Net"),
        ), group_by=("currency", "product_type"), groupable=("currency", "product_type")),
        Dataset("by_city", "By payer city", ("by_city",), (
            Field("city", "City", drill=("liquidity", {"city": "city"}), width=20), CURRENCY,
            _count("paying_members", "Paying members"), _money("net", "Net"),
        ), groupable=("currency",), note="Cities with fewer than five paying members are pooled."),
        Dataset("trend", "Trend", ("trend",), (
            Field("bucket", "Period", DATE), CURRENCY, _money("gross", "Gross"), _money("refunded", "Refunded"),
            _money("chargeback", "Chargebacks"), _money("net", "Net"),
            Field("subscription_net", "Subscriptions", MONEY, SUM, minor="subscription_net_minor"),
            Field("coin_package_net", "Coin packages", MONEY, SUM, minor="coin_package_net_minor"),
            _rate("refund_rate", "Refund rate"), _rate("chargeback_rate", "Chargeback rate"),
        ), groupable=("currency",), chart=Chart("line", "bucket", ("net", "refunded"), series="currency",
                                                  title="Net and refunded by period")),
    ),
    keywords=("money", "payments", "refunds", "arpu", "arppu", "chargebacks"),
)

SUBSCRIPTIONS = Report(
    "subscriptions", "Subscriptions & MRR", "Business",
    "MRR movements (new, expansion, contraction, churn), churn reasons and the active plan mix.",
    ("business", "subscriptions"), BUSINESS_PARAMS + (MONTHS,),
    datasets=(
        Dataset("movements", "MRR movements", ("movements",), (
            Field("bucket", "Period", DATE), CURRENCY, _money("mrr_start", "Start MRR"), _money("new", "New"),
            _money("expansion", "Expansion"), _money("contraction", "Contraction"),
            _money("churned", "Churned"), _money("mrr_end", "End MRR"),
            Field("subscribers_start", "Subscribers start", INT), _count("new_subscribers", "New subs"),
            _count("churned_subscribers", "Churned subs"), Field("subscribers_end", "Subscribers end", INT),
            _rate("logo_churn_rate", "Logo churn"), _rate("revenue_churn_rate", "Revenue churn"),
            _rate("net_mrr_retention", "Net MRR retention"),
        ), groupable=("currency",), chart=Chart("bar", "bucket", ("new", "churned"), series="currency",
                                                  title="New vs churned MRR")),
        Dataset("churn_reasons", "Churn reasons", ("churn", "reasons"), (
            Field("reason", "Reason", width=28), _count("subscribers", "Subscribers"), Field("healthy", "Healthy", BOOL),
        )),
        Dataset("plan_mix", "Active plan mix", ("plan_mix",), (
            Field("plan", "Plan"), Field("billing_cycle", "Cycle"), CURRENCY,
            _count("active_subscribers", "Active subscribers"), _count("cancel_at_period_end", "Cancelling at period end"),
        ), group_by=("plan",), groupable=("plan", "billing_cycle", "currency")),
    ),
    keywords=("mrr", "churn", "plans", "retention"),
)

CONVERSION = Report(
    "conversion", "Conversion & checkout funnel", "Business",
    "Free-to-paid conversion by signup cohort and the checkout funnel by product and platform.",
    ("business", "conversion"), (SINCE, UNTIL, TZ, MODE),
    datasets=(
        Dataset("cohorts", "Free → paid by signup cohort", ("cohorts",), (
            Field("cohort", "Cohort", DATE), _count("members", "Members"), _count("paid_7d", "Paid ≤7d"),
            _count("paid_30d", "Paid ≤30d"), _count("paid_90d", "Paid ≤90d"), _count("paid_to_date", "Paid to date"),
            _count("subscribed_to_date", "Subscribed"), _rate("conversion_30d", "Conv. 30d"),
            _rate("conversion_to_date", "Conv. to date"), Field("mature_30d", "30d mature", BOOL),
        ), chart=Chart("bar", "cohort", ("conversion_30d", "conversion_to_date"), title="Conversion by cohort")),
        Dataset("funnel", "Checkout funnel", ("detail",), source=("business", "funnel"), fields=(
            Field("kind", "Kind"), Field("product", "Product", width=22), Field("platform", "Platform"),
            _count("created", "Created"), _count("completed", "Completed"), _count("paid", "Paid"),
            _count("refunded", "Refunded"), _count("abandoned_or_expired", "Abandoned/expired"), _count("open", "Open"),
            _rate("completion_rate", "Completion"), _rate("paid_rate", "Paid rate"), _rate("refund_rate", "Refund rate"),
        ), group_by=("kind",), groupable=("kind", "product", "platform"),
            # Go's funnel never buckets but still caps a window at 400 *day*
            # buckets by default; month keeps long conversion windows valid.
            query=lambda p: {**p, "bucket": "month"}),
    ),
    keywords=("checkout", "cohort", "free to paid", "ltv"),
)

COINS = Report(
    "coins", "Coin economy", "Business",
    "Coin purchases, grants, returns, gift spend and clawbacks; purchases by currency; top gifts.",
    ("business", "coins"), BUSINESS_PARAMS,
    datasets=(
        Dataset("trend", "Coin flows", ("trend",), (
            Field("bucket", "Period", DATE), _count("purchased", "Purchased"), _count("granted", "Granted"),
            _count("returned", "Returned"), _count("gift_spend", "Gift spend"), _count("clawback_debits", "Clawbacks"),
            _count("net_flow", "Net flow"),
        ), chart=Chart("bar", "bucket", ("purchased", "granted", "gift_spend"), title="Coin flows")),
        Dataset("purchases", "Purchases by currency", ("sources", "purchased", "by_currency"), (
            CURRENCY, Field("mode", "Mode"), _count("count", "Purchases"), _count("coins", "Coins"),
            Field("amount", "Amount", MONEY, SUM, minor="amount_minor"), _count("buyers", "Buyers"),
        ), groupable=("currency", "mode")),
        Dataset("top_gifts", "Top gifts by coins", ("sinks", "gifts", "top_gifts"), (
            Field("gift_id", "Gift", width=28), _count("sends", "Sends"), _count("coins", "Coins"),
        )),
        Dataset("clawbacks", "Clawbacks", ("sinks", "clawbacks"), (
            Field("source", "Source"), _count("count", "Debits"), _count("coins_debited", "Coins debited"),
            _count("coins_shortfall", "Shortfall"),
        )),
    ),
    keywords=("wallet", "gifts", "coins", "liability"),
)

REFERRALS = Report(
    "referrals", "Referrals & introducers", "Business",
    "Friend K-factor by signup cohort and introducer outcomes.",
    ("business", "referrals"), BUSINESS_PARAMS,
    datasets=(
        Dataset("k_factor", "Friend K-factor by signup cohort", ("k_factor", "by_cohort"), (
            Field("cohort", "Cohort", DATE), _count("members", "Members"),
            _count("referral_signups_30d", "Referral signups ≤30d"), _count("introducer_invites_30d", "Introducer invites ≤30d"),
            _count("introducer_accepted_30d", "Introducer accepted ≤30d"), Field("k_referral", "K referral", NUMBER),
            Field("k_introducer", "K introducer", NUMBER), Field("k_total", "K total", NUMBER),
            Field("introducer_invites_per_member", "Invites / member", NUMBER),
            _rate("introducer_acceptance_rate", "Acceptance"),
        ), chart=Chart("line", "cohort", ("k_total",), title="K-factor by cohort")),
        Dataset("intros", "Intros", ("introducers", "intros"), (
            Field("introducer_kind", "Introducer"), _count("intros", "Intros"), _count("matched", "Matched"),
            _count("declined", "Declined"), _count("expired", "Expired"), _count("open", "Open"),
            _rate("match_rate", "Match rate"),
        )),
    ),
    keywords=("virality", "k-factor", "invites"),
)

SPEND = Report(
    "marketing-spend", "Marketing spend & CAC", "Business",
    "Customer acquisition cost by month, market and currency.",
    ("business", "marketing-spend"), (SINCE, UNTIL),
    datasets=(
        Dataset("cac", "CAC by month, market and currency", ("cac",), (
            Field("month", "Month", DATE), Field("market", "Market"), CURRENCY,
            Field("spend", "Spend", MONEY, SUM, minor="spend_minor"), _count("new_members", "New members"),
            Field("cac", "CAC", MONEY, minor="cac_minor"), _count("attributed_members", "Attributed members"),
            Field("attributed_cac", "Attributed CAC", MONEY, minor="attributed_cac_minor"),
        ), group_by=("market",), groupable=("market", "currency", "month")),
    ),
    keywords=("cac", "acquisition", "marketing"),
)

# ── Product (durable analytics snapshots; tables self-described) ─────────

PRODUCT = tuple(
    Report(name, title, "Product", description, ("analytics", name), params, auto_tables=True, keywords=keywords)
    for name, title, description, params, keywords in (
        ("kpis", "Headline KPIs", "DAU, WAU, MAU, stickiness, new members and the north-star rates, with the week before.",
         (A_TO, A_GENDER), ("dau", "mau", "stickiness")),
        ("trends", "Active members over time", "One metric (DAU by default; WAU, MAU, signups and more) by period.",
         (A_FROM, A_TO, A_GRAIN, A_GENDER, A_METRIC), ("dau", "wau", "mau")),
        ("funnel", "Activation funnel", "Signup to first match and first date, by step.", ANALYTICS_PARAMS, ("activation", "onboarding")),
        ("retention", "Retention cohorts", "Weekly retention triangle by signup cohort.", WEEKLY_PARAMS, ("cohort", "churn")),
        ("engagement", "Engagement", "Reach, actions and repeat use of each product surface among active members.",
         ANALYTICS_PARAMS, ("messages", "matches")),
        # Go's liquidity report has no gender filter (it splits by gender itself).
        ("liquidity", "Liquidity by city", "Supply, demand and match rates by city.", (A_FROM, A_TO, A_GRAIN, A_CITY), ("city", "market")),
        ("safety", "Safety health", "Reports and blocks per 1,000 DAU, queue response times and reports by surface.",
         WEEKLY_PARAMS, ("reports", "blocks", "sos")),
    )
)

# ── Members (per-member and member-list reports, from admin endpoints) ───
# Field keys are the exact JSON keys Go sends (store.go, admin_list_endpoints.go,
# server_admin_extended.go): a wrong key renders as an empty column.

MEMBER = Param("member", "Member ID or @username", "member", required=True,
               help="A member's id, or their username with or without @.")
M_FROM = Param("from", "From (UTC)", "date")
M_TO = Param("to", "To (UTC)", "date")


def _member(*keys: str, **fixed):
    """Query builder: the resolved member id under ``keys`` plus the date range."""
    def build(p: dict) -> dict:
        q = {k: p["member"] for k in keys}
        q.update({k: p[k] for k in ("from", "to") if p.get(k)})
        q.update(fixed)
        return q
    return build


def _member_args(dates: bool = False, **fixed):
    """Positional member id (get_user, wallet, member_activity); the date
    range only for sources that take one."""
    def build(p: dict) -> dict:
        q = {"_args": (p["member"],), **fixed}
        if dates:
            q.update({k: p[k] for k in ("from", "to") if p.get(k)})
        return q
    return build


def _admin(name: str, title: str, path: tuple[str, ...], fields: tuple, **kw) -> Dataset:
    key = kw.pop("key", path[-1] if path else name)
    return Dataset(key, title, path, fields, source=("admin", name), **kw)


WHEN = Field("created_at", "Created (UTC)", DATE, width=22)

MEMBER_360 = Report(
    "member-360", "Member 360", "Members",
    "Everything about one member: profile, wallet, activity by area and recent actions, reports filed and "
    "received, appeals, verification, subscriptions, payments, coin purchases, support tickets and SOS alerts.",
    ("admin", "users"), (MEMBER, M_FROM, M_TO),
    datasets=(
        _admin("get_user", "Profile", ("user",), (
            Field("id", "Member ID"), Field("username", "Username"), Field("name", "Name"),
            Field("phone_number", "Phone"), Field("gender", "Gender"), Field("city", "City"), Field("state", "State"),
            Field("country", "Country"), Field("profile_completion", "Profile complete (%)", INT),
            Field("is_verified", "Verified", BOOL), Field("created_at", "Joined (UTC)"),
            Field("last_login_at", "Last sign-in (UTC)"), Field("suspended_at", "Suspended at (UTC)"),
            Field("suspended_reason", "Suspension reason"), Field("is_banned", "Banned", BOOL),
        ), key="profile", shape="record", query=_member_args()),
        _admin("get_wallet_balance", "Wallet", ("wallet",), (Field("coin_balance", "Coin balance", INT),),
               key="wallet", shape="record", query=_member_args()),
        _admin("member_activity", "Activity summary", ("summary",), (
            Field("total", "Actions in range", INT), Field("first_seen", "First seen (UTC)"),
            Field("last_seen", "Last seen (UTC)"), Field("distinct_devices", "Devices", INT),
            Field("distinct_ips", "IP addresses", INT),
        ), key="activity_summary", shape="record", query=_member_args(dates=True, limit=1)),
        _admin("member_activity", "Actions by area", ("summary", "by_category"), (
            Field("area", "Area"), Field("count", "Actions", INT, SUM),
        ), key="activity_by_area", shape="pairs", query=_member_args(dates=True, limit=1)),
        _admin("member_activity", "Recent actions (latest 50)", ("actions",), (
            Field("at", "Time (UTC)", DATE, width=22), Field("action_label", "Action", width=30),
            Field("category", "Area"), Field("outcome", "Outcome"), Field("status_code", "Status", INT),
            Field("platform", "Platform"), Field("ip", "IP address"), Field("route", "Route", width=30),
        ), key="recent_actions", groupable=("category", "outcome", "platform"), query=_member_args(dates=True, limit=50),
            note="The full history, with filters and Excel export, is in Member activity (filter by this member)."),
        _admin("list_reports", "Reports filed by this member", ("reports",), (
            WHEN, Field("reported_user_id", "Reported member", width=38), Field("reason", "Reason"),
            Field("status", "Status"), Field("description", "Description", width=40),
        ), key="reports_filed", paged=True, groupable=("status", "reason"), query=_member("reporter_user_id")),
        _admin("list_reports", "Reports against this member", ("reports",), (
            WHEN, Field("reporter_user_id", "Reporter", width=38), Field("reason", "Reason"),
            Field("status", "Status"), Field("description", "Description", width=40),
        ), key="reports_received", paged=True, groupable=("status", "reason"), query=_member("reported_user_id")),
        _admin("list_appeals", "Appeals", ("appeals",), (
            WHEN, Field("reason", "Reason", width=40), Field("status", "Status"),
            Field("sla_deadline_at", "SLA deadline (UTC)"),
        ), key="appeals", paged=True, query=_member("user_id")),
        _admin("list_verifications", "Verification", ("verifications",), (
            Field("submitted_at", "Submitted (UTC)", DATE), Field("status", "Status"),
            Field("reviewed_at", "Reviewed (UTC)"), Field("rejection_reason", "Rejection reason", width=40),
        ), key="verification", paged=True, query=_member("user_id")),
        _admin("list_subscriptions", "Subscriptions", ("subscriptions",), (
            Field("plan_code", "Plan"), Field("billing_cycle", "Cycle"), Field("status", "Status"),
            Field("provider", "Provider"), Field("start_date", "Started (UTC)"),
            Field("current_period_end", "Period end (UTC)"), Field("end_date", "Ended (UTC)"),
        ), key="subscriptions", paged=True, query=_member("user_id")),
        _admin("list_payments", "Payments", ("payments",), (
            WHEN, Field("amount", "Amount", MONEY, SUM, minor="amount_paise"), CURRENCY, Field("status", "Status"),
            Field("billing_reason", "Reason"), Field("provider_payment_id", "Provider reference", width=30),
        ), key="payments", paged=True, groupable=("currency", "status"), query=_member("user_id")),
        _admin("list_billing_transactions", "Coin purchases", ("transactions",), (
            WHEN, _count("coins", "Coins"), Field("amount", "Amount", MONEY, SUM, minor="amount_minor"), CURRENCY,
            Field("source", "Source"), Field("provider", "Provider"), Field("purchase_ref", "Reference", width=30),
        ), key="coin_purchases", paged=True, groupable=("currency", "source"), query=_member("user_id")),
        # Go lists only active tickets unless asked for all, and has no date filter for tickets.
        _admin("list_support_tickets", "Support tickets", ("tickets",), (
            WHEN, Field("reference", "Reference"), Field("subject", "Subject", width=40), Field("status", "Status"),
            Field("priority", "Priority"), Field("category", "Category"), Field("team", "Team"),
        ), key="support_tickets", paged=True, groupable=("status", "category"),
            query=lambda p: {"member": p["member"], "status": "all"}),
        # SOS rows carry triggered_at (Go sends no created_at for alerts).
        _admin("list_sos_alerts", "SOS alerts", ("alerts",), (
            Field("triggered_at", "Triggered (UTC)", DATE, width=22), Field("emergency_level", "Level"), Field("status", "Status"),
            Field("resolved_at", "Resolved (UTC)"),
        ), key="sos_alerts", paged=True, query=_member("user_id")),
    ),
    keywords=("member", "user", "profile", "360", "timeline", "history", "customer"),
)

DIRECTORY = Report(
    "member-directory", "Member directory", "Members",
    "Members with status, gender and verification filters, grouped by city or gender. Export the full list to Excel.",
    ("admin", "users"), (
        Param("q", "Name, username or phone", "text"),
        Param("status", "Status", choices=(("active", "Active"), ("suspended", "Suspended"), ("banned", "Banned"))),
        Param("gender", "Gender", choices=(("female", "Female"), ("male", "Male"), ("other", "Other"))),
        Param("verified", "Verified", choices=(("yes", "Yes"), ("no", "No"))),
    ),
    datasets=(
        _admin("list_users", "Members", ("users",), (
            Field("username", "Username"), Field("name", "Name", width=22), Field("gender", "Gender"),
            Field("city", "City"), Field("profile_completion", "Profile (%)", INT), Field("is_verified", "Verified", BOOL),
            Field("created_at", "Joined (UTC)", DATE), Field("last_login_at", "Last sign-in (UTC)"),
            Field("is_banned", "Banned", BOOL), Field("id", "Member ID", width=38, drill=("member-360", {"member": "id"})),
        ), key="members", paged=True, groupable=("city", "gender", "is_verified"),
            query=lambda p: {k: p.get(k, "") for k in ("q", "status", "gender", "verified")}),
    ),
    keywords=("users", "members", "list", "directory", "export"),
)

MOST_REPORTED = Report(
    "most-reported-members", "Most-reported members", "Members",
    "Reports grouped by the reported member, largest first, to find repeat offenders. Each member links to Member 360.",
    ("admin", "moderation/reports"), (
        Param("status", "Report status", choices=(("pending", "Pending"), ("under_review", "Under review"),
                                                   ("resolved", "Resolved"), ("rejected", "Dismissed"))),
        M_FROM, M_TO,
    ),
    datasets=(
        _admin("list_reports", "Reports by reported member", ("reports",), (
            Field("reported_user_id", "Reported member", width=38, drill=("member-360", {"member": "reported_user_id"})),
            WHEN, Field("reporter_user_id", "Reporter", width=38), Field("reason", "Reason"), Field("status", "Status"),
            Field("description", "Description", width=40),
        ), key="by_member", paged=True, group_by=("reported_user_id",), groupable=("reported_user_id", "reason", "status"),
            group_order="count", query=lambda p: {k: p[k] for k in ("status", "from", "to") if p.get(k)}),
    ),
    keywords=("safety", "abuse", "offenders", "reports", "moderation"),
)

PAYING_MEMBERS = Report(
    "paying-members", "Paying members by plan", "Members",
    "Subscribers grouped by plan, with cycle, provider, renewal date and whether they are ending.",
    ("admin", "billing/subscriptions"), (
        Param("status", "Subscription status", choices=(("active", "Active"), ("past_due", "Past due"), ("cancelled", "Cancelled"),
                                                         ("expired", "Expired")), default="active"),
        M_FROM, M_TO,
    ),
    datasets=(
        _admin("list_subscriptions", "Subscribers", ("subscriptions",), (
            Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})), Field("plan_code", "Plan"),
            Field("billing_cycle", "Cycle"), Field("provider", "Provider"), Field("start_date", "Started (UTC)"),
            Field("current_period_end", "Renews / ends (UTC)"), Field("cancel_at_period_end", "Ending", BOOL),
        ), key="subscribers", paged=True, group_by=("plan_code",), groupable=("plan_code", "billing_cycle", "provider"),
            group_order="count", query=lambda p: {k: p[k] for k in ("status", "from", "to") if p.get(k)}),
    ),
    keywords=("subscribers", "paying", "plans", "revenue", "customers"),
)


# ── Operations (running the platform day to day) ─────────────────────────



def _ts(value: Any) -> datetime | None:
    try:
        parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except (TypeError, ValueError):
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _hours_since(*keys: str):
    def get(row: dict) -> float | None:
        for key in keys:
            when = _ts(row.get(key))
            if when:
                return round((datetime.now(timezone.utc) - when).total_seconds() / 3600, 1)
        return None
    return get


def _minutes_between(start: str, end: str):
    def get(row: dict) -> float | None:
        a, b = _ts(row.get(start)), _ts(row.get(end))
        return round((b - a).total_seconds() / 60, 1) if a and b else None
    return get


def _dated(**fixed):
    def build(p: dict) -> dict:
        return {**{k: p[k] for k in ("from", "to") if p.get(k)}, **fixed}
    return build


# (label, client method, open filter, items key, timestamp keys, SLA target hours)
QUEUES = (
    ("SOS alerts", "list_sos_alerts", {"status": "active"}, "alerts", ("triggered_at",), 5 / 60),
    ("Reports", "list_reports", {"status": "pending"}, "reports", ("created_at",), 24),
    ("Appeals", "list_appeals", {"status": "submitted"}, "appeals", ("created_at",), 48),
    ("Verifications", "list_verifications", {"status": "pending"}, "verifications", ("submitted_at",), 24),
    ("Profile media", "list_media_moderation", {"status": "review_required"}, "items", ("uploaded_at",), 24),
    ("Account recovery", "list_account_recovery", {"status": "open"}, "requests", ("created_at",), 24),
)


def _queue_snapshot(client: Any, params: dict) -> list[dict]:
    """Open items, oldest item and whether it is past target, per queue."""
    rows = []
    for label, method, open_filter, key, stamps, target in QUEUES:
        result = getattr(client, method)(limit=1, offset=0, order="asc", **open_filter)
        data = result.data if result.ok and isinstance(result.data, dict) else {}
        items = [i for i in data.get(key) or [] if isinstance(i, dict)]
        oldest = _hours_since(*stamps)(items[0]) if items else None
        rows.append({
            "queue": label, "open": data.get("total") if result.ok else None, "oldest_hours": oldest,
            "target_hours": round(target, 2), "past_target": (oldest is not None and oldest > target) if result.ok else None,
            "status": "" if result.ok else (result.error or "unavailable"),
        })
    return rows


QUEUE_SNAPSHOT = Dataset("queues", "Queues right now", (), (
    Field("queue", "Queue"), _count("open", "Open items"), Field("oldest_hours", "Oldest (hours)", NUMBER),
    Field("target_hours", "Target (hours)", NUMBER), Field("past_target", "Past target", BOOL), Field("status", "Note"),
), compute=_queue_snapshot)


def _sla_rows(label: str, method: str, open_filter: dict, key: str, stamps: tuple, target: float, extra: tuple = ()):
    return Dataset(key + "_open", f"{label}: open items", (key,), (
        Field(stamps[0], "Opened (UTC)", DATE, width=20), Field("age_hours", "Age (hours)", NUMBER, get=_hours_since(*stamps)),
        Field("past_target", "Past target", BOOL,
              get=lambda r, s=stamps, t=target: (lambda h: h is not None and h > t)(_hours_since(*s)(r))),
        Field("status", "Status"), *extra,
    ), source=("admin", method), paged=True, query=lambda p, f=open_filter: dict(f),
        sort=_hours_since(*stamps), sort_desc=True)


QUEUE_SLA = Report(
    "queue-sla", "Queue SLA", "Operations",
    "Every open item in every operational queue with its age, oldest first, and whether it is past its target.",
    ("admin", "moderation/reports"), (),
    datasets=(
        QUEUE_SNAPSHOT,
        _sla_rows("SOS", "list_sos_alerts", {"status": "active"}, "alerts", ("triggered_at",), 5 / 60,
                  (Field("emergency_level", "Level"), Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})))),
        _sla_rows("Reports", "list_reports", {"status": "pending"}, "reports", ("created_at",), 24,
                  (Field("reason", "Reason"), Field("reported_user_id", "Reported member", width=38,
                                                    drill=("member-360", {"member": "reported_user_id"})))),
        _sla_rows("Appeals", "list_appeals", {"status": "submitted"}, "appeals", ("created_at",), 48,
                  (Field("sla_deadline_at", "SLA deadline (UTC)"), Field("user_id", "Member", width=38))),
        _sla_rows("Verifications", "list_verifications", {"status": "pending"}, "verifications", ("submitted_at",), 24,
                  (Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})),)),
        _sla_rows("Profile media", "list_media_moderation", {"status": "review_required"}, "items", ("uploaded_at",), 24,
                  (Field("username", "Username"), Field("reason", "Reason"))),
        _sla_rows("Account recovery", "list_account_recovery", {"status": "open"}, "requests", ("created_at",), 24,
                  (Field("username", "Username"),)),
    ),
    keywords=("sla", "backlog", "queues", "moderation", "operations", "aging"),
)

OPERATOR_PRODUCTIVITY = Report(
    "operator-productivity", "Operator productivity", "Operations",
    "Operator actions from the immutable audit log, grouped by operator (busiest first): what each did and when.",
    ("admin", "audit-events"), (M_FROM, M_TO),
    datasets=(
        _admin("list_audit_events", "Actions by operator", ("events",), (
            Field("actor_user_id", "Operator", width=38), Field("actor_role", "Role"), Field("occurred_at", "When (UTC)", DATE, width=20),
            Field("event_type", "Action", width=30), Field("resource_type", "Resource", width=30), Field("resource_id", "Resource ID", width=38),
        ), key="by_operator", paged=True, group_by=("actor_user_id",), groupable=("actor_user_id", "actor_role", "event_type"),
            group_order="count", query=_dated()),
    ),
    keywords=("operators", "moderators", "workload", "audit", "team", "performance"),
)

MODERATION_OUTCOMES = Report(
    "moderation-outcomes", "Moderation outcomes", "Operations",
    "Member reports by reason and outcome in the window, and appeals by outcome.",
    ("admin", "moderation/reports"), (M_FROM, M_TO),
    datasets=(
        _admin("list_reports", "Reports by reason", ("reports",), (
            Field("reason", "Reason"), Field("status", "Outcome"), WHEN,
            Field("reported_user_id", "Reported member", width=38, drill=("member-360", {"member": "reported_user_id"})),
        ), key="reports", paged=True, group_by=("reason",), groupable=("reason", "status"), group_order="count", query=_dated()),
        _admin("list_appeals", "Appeals by outcome", ("appeals",), (
            Field("status", "Outcome"), WHEN, Field("reason", "Reason", width=40), Field("user_id", "Member", width=38),
        ), key="appeals", paged=True, group_by=("status",), groupable=("status",), group_order="count", query=_dated()),
    ),
    keywords=("moderation", "reports", "appeals", "outcomes", "safety", "enforcement"),
)

SOS_LOG = Report(
    "sos-incidents", "SOS incident log", "Operations",
    "Every SOS alert with its level, status and minutes to resolve.",
    ("admin", "safety/sos-alerts"), (M_FROM, M_TO),
    datasets=(
        _admin("list_sos_alerts", "SOS alerts", ("alerts",), (
            Field("triggered_at", "Triggered (UTC)", DATE, width=20), Field("emergency_level", "Level"), Field("status", "Status"),
            Field("resolved_at", "Resolved (UTC)"),
            Field("minutes_to_resolve", "Minutes to resolve", NUMBER, get=_minutes_between("triggered_at", "resolved_at")),
            Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})),
            Field("resolution_note", "Resolution note", width=40),
        ), key="alerts", paged=True, groupable=("emergency_level", "status"), query=_dated()),
    ),
    keywords=("sos", "safety", "incidents", "emergency"),
)

PAYMENT_OPS = Report(
    "payment-operations", "Payment operations", "Operations",
    "Failed and refunded payments and failed payment webhooks in the window.",
    ("admin", "billing/payments"), (M_FROM, M_TO),
    datasets=(
        _admin("list_payments", "Failed payments", ("payments",), (
            WHEN, Field("amount", "Amount", MONEY, SUM, minor="amount_paise"), CURRENCY, Field("failure_reason", "Failure", width=36),
            Field("billing_reason", "Reason"), Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})),
        ), key="failed", paged=True, groupable=("currency", "failure_reason"), query=_dated(status="failed")),
        _admin("list_payments", "Refunded payments", ("payments",), (
            WHEN, Field("amount", "Amount", MONEY, SUM, minor="amount_paise"),
            Field("refunded", "Refunded", MONEY, SUM, minor="refunded_amount_paise"), CURRENCY,
            Field("user_id", "Member", width=38, drill=("member-360", {"member": "user_id"})),
        ), key="refunded", paged=True, groupable=("currency",), query=_dated(status="refunded")),
        _admin("list_billing_webhook_events", "Failed webhooks", ("events",), (
            Field("received_at", "Received (UTC)", DATE, width=20), Field("provider", "Provider"), Field("event_type", "Event", width=30),
            Field("error", "Error", width=40), Field("event_id", "Event ID", width=30),
        ), key="webhooks", paged=True, groupable=("provider", "event_type"), query=_dated(status="failed")),
    ),
    keywords=("payments", "refunds", "chargebacks", "webhooks", "finance", "billing"),
)

CONFIG_LOG = Report(
    "config-changes", "Configuration change log", "Operations",
    "Every feature flag and configuration change, who made it and when.",
    ("admin", "audit-events"), (M_FROM, M_TO),
    datasets=(
        _admin("list_audit_events", "Changes", ("events",), (
            Field("occurred_at", "When (UTC)", DATE, width=20), Field("actor_user_id", "Operator", width=38), Field("actor_role", "Role"),
            Field("event_type", "Action"), Field("resource_type", "Resource", width=30), Field("payload", "Details", width=60),
        ), key="changes", paged=True, groupable=("resource_type", "actor_user_id"), query=_dated(q="config/")),
    ),
    keywords=("flags", "config", "changes", "audit", "feature flags"),
)


def _kpi_rows(client: Any, params: dict) -> list[dict]:
    result = client.analytics_report("kpis", {"as_of": params["to"]} if params.get("to") else {})
    tiles = (((result.data or {}).get("tables") or {}).get("tiles") or {}).get("rows") if result.ok else None
    return [t for t in tiles or [] if isinstance(t, dict)]


def _server_rows(client: Any, params: dict) -> list[dict]:
    rows = []
    traffic = client.system_requests(grain="day", group_by="none")
    totals = traffic.data.get("totals") if traffic.ok and isinstance(traffic.data, dict) else None
    if isinstance(totals, dict):
        rows += [{"signal": "Requests (last 24 h)", "value": totals.get("requests")},
                 {"signal": "Server errors (5xx)", "value": totals.get("server_errors")},
                 {"signal": "Refused requests", "value": totals.get("refused")},
                 {"signal": "Latency p95 (ms)", "value": totals.get("p95_ms")}]
    jobs = client.system_jobs()
    workers = jobs.data.get("workers") if jobs.ok and isinstance(jobs.data, dict) else None
    if isinstance(workers, list):
        rows += [{"signal": "Background workers stale", "value": sum(1 for w in workers if isinstance(w, dict) and w.get("stale"))},
                 {"signal": "Workers with failures (24 h)",
                  "value": sum(1 for w in workers if isinstance(w, dict) and (w.get("failures_24h") or 0) > 0)}]
    return rows or [{"signal": "Server activity", "value": "unavailable"}]


DAILY_OPS = Report(
    "daily-operations", "Daily operations summary", "Operations",
    "One page for the morning check-in: headline KPIs, every queue and its oldest item, and server health. "
    "Export as PDF to share.",
    ("admin", "moderation/reports"), (Param("to", "As of (UTC)", "date", help="Defaults to the latest built day."),),
    datasets=(
        Dataset("kpis", "Headline KPIs", (), (
            Field("label", "KPI", width=30), Field("value", "Value", NUMBER), Field("previous", "Week before", NUMBER),
            Field("unit", "Unit"),
        ), compute=_kpi_rows),
        QUEUE_SNAPSHOT,
        Dataset("server", "Server health", (), (Field("signal", "Signal", width=30), Field("value", "Value")), compute=_server_rows),
    ),
    keywords=("daily", "summary", "morning", "ops", "standup", "pdf"),
)

OPERATIONS_REPORTS = (DAILY_OPS, QUEUE_SLA, OPERATOR_PRODUCTIVITY, MODERATION_OUTCOMES, SOS_LOG, PAYMENT_OPS, CONFIG_LOG)

# More member reports

DORMANT = Report(
    "dormant-members", "Dormant members", "Members",
    "Members who have not signed in for a while, longest-inactive first, for win-back campaigns.",
    ("admin", "users"), (
        Param("days", "Inactive for at least", choices=(("7", "7 days"), ("14", "14 days"), ("30", "30 days"), ("60", "60 days"),
                                                        ("90", "90 days")), default="30"),
        Param("verified", "Verified", choices=(("yes", "Yes"), ("no", "No"))),
    ),
    datasets=(
        _admin("list_users", "Dormant members", ("users",), (
            Field("username", "Username"), Field("name", "Name", width=22), Field("city", "City"),
            Field("last_login_at", "Last sign-in (UTC)", DATE, width=20),
            Field("days_inactive", "Days inactive", NUMBER,
                  get=lambda r: (lambda h: round(h / 24) if h is not None else None)(_hours_since("last_login_at", "created_at")(r))),
            Field("is_verified", "Verified", BOOL), Field("created_at", "Joined (UTC)", DATE),
            Field("id", "Member ID", width=38, drill=("member-360", {"member": "id"})),
        ), key="dormant", paged=True, groupable=("city", "is_verified"),
            query=lambda p: {"status": "active", **({"verified": p["verified"]} if p.get("verified") else {})},
            row_filter=lambda r, p: (lambda h: h is not None and h >= int(p.get("days") or 30) * 24)(
                _hours_since("last_login_at", "created_at")(r)),
            sort=_hours_since("last_login_at", "created_at"), sort_desc=True),
    ),
    keywords=("inactive", "churn", "win-back", "dormant", "re-engagement", "members"),
)

SIGNIN_SECURITY = Report(
    "signin-security", "Sign-in and account security", "Members",
    "Sign-ins, sign-outs, password and recovery-code changes and session revocations by members, with IP and platform.",
    ("admin", "activity"), (M_FROM, M_TO),
    datasets=(
        _admin("list_member_actions", "Account security actions", ("actions",), (
            Field("at", "When (UTC)", DATE, width=20), Field("action_label", "Action", width=28), Field("outcome", "Outcome"),
            Field("status_code", "Status", INT), Field("ip", "IP address"), Field("platform", "Platform"),
            Field("member_id", "Member", width=38, drill=("member-360", {"member": "member_id"})),
            Field("user_agent", "User agent", width=40),
        ), key="auth", paged=True, group_by=("action_label",), groupable=("action_label", "outcome", "member_id", "ip"),
            group_order="count", query=_dated(category="Auth", source="request")),
    ),
    keywords=("login", "sign-in", "security", "sessions", "password", "ip", "devices"),
)

MEMBER_REPORTS = (MEMBER_360, DIRECTORY, DORMANT, SIGNIN_SECURITY, MOST_REPORTED, PAYING_MEMBERS)

# ── Server (activity and consumption, from /admin/system/...) ─────────────

S_FROM = Param("from", "From (UTC)", "date")
S_TO = Param("to", "To (UTC)", "date")
S_GRAIN = Param("grain", "Per", choices=(("hour", "Hour"), ("day", "Day")), default="day")


def _system(**fixed):
    def build(p: dict) -> dict:
        return {**{k: p[k] for k in ("from", "to", "grain") if p.get(k)}, **fixed}
    return build


TRAFFIC_FIELDS = (
    Field("bucket", "Period", DATE, width=20), _count("requests", "Requests"), _count("server_errors", "Server errors (5xx)"),
    _count("refused", "Refused"), Field("avg_ms", "Avg ms", NUMBER), Field("p50_ms", "p50 ms", NUMBER),
    Field("p95_ms", "p95 ms", NUMBER), Field("p99_ms", "p99 ms", NUMBER),
)

API_TRAFFIC = Report(
    "api-traffic", "API traffic and latency", "Server",
    "Requests, server errors, refused requests and latency percentiles by period, overall and by route.",
    ("admin", "system/requests"), (S_FROM, S_TO, S_GRAIN),
    datasets=(
        # Go returns 500 rows unless asked (5,000 at most); Go fills only the
        # group_by column, so "By route" rows carry no method.
        _admin("system_requests", "Overall", ("rows",), TRAFFIC_FIELDS, key="overall", query=_system(group_by="none", limit=5000),
               chart=Chart("line", "bucket", ("requests", "server_errors", "p95_ms"), title="Requests, 5xx and p95")),
        _admin("system_requests", "By route", ("rows",), (
            Field("bucket", "Period", DATE, width=20), Field("route", "Route", width=36), *TRAFFIC_FIELDS[1:]),
            key="by_route", query=_system(group_by="route", limit=5000), groupable=("route",)),
        _admin("system_requests", "By status class", ("rows",), (
            Field("bucket", "Period", DATE, width=20), Field("status_class", "Status class"), _count("requests", "Requests")),
            key="by_status", query=_system(group_by="status_class", limit=5000), group_by=("status_class",), groupable=("status_class",)),
    ),
    keywords=("server", "requests", "latency", "errors", "traffic", "api", "consumption", "p95"),
)

JOB_RUNS = Report(
    "background-jobs", "Background job runs", "Server",
    "Every background worker run: status, duration, items processed and failed, backlog, errors.",
    ("admin", "system/job-runs"), (
        Param("status", "Status", choices=(("succeeded", "Succeeded"), ("failed", "Failed"), ("skipped", "Skipped"), ("busy", "Busy"))),
        S_FROM, S_TO),
    datasets=(
        _admin("system_job_runs", "Runs", ("runs",), (
            Field("worker", "Worker", width=22), Field("status", "Status"), Field("started_at", "Started (UTC)", DATE, width=20),
            Field("duration_ms", "Duration (ms)", INT), _count("items_processed", "Items"), _count("items_failed", "Failed items"),
            Field("backlog_after", "Backlog after", INT), Field("error", "Error", width=40),
        ), key="runs", paged=True, group_by=("worker",), groupable=("worker", "status"),
            query=lambda p: {k: p[k] for k in ("status", "from", "to") if p.get(k)}),
    ),
    keywords=("workers", "jobs", "cron", "server", "failures", "retention"),
)

DB_CONSUMPTION = Report(
    "database-consumption", "Database and storage consumption", "Server",
    "Database size over time, the largest tables (size, rows, dead rows, autovacuum) and media storage by kind.",
    ("admin", "system/capacity"), (S_FROM, S_TO),
    datasets=(
        _admin("system_capacity", "Size over time", ("series",), (
            Field("at", "Snapshot (UTC)", DATE, width=20), Field("db_size_bytes", "Database bytes", INT),
            Field("media_bytes_total", "Media bytes", INT), Field("outbox_rows", "Domain events (rows)", INT),
            Field("activity_rows", "Activity rows", INT),
        ), key="series", query=_system(),
            chart=Chart("line", "at", ("db_size_bytes", "media_bytes_total"), title="Database and media bytes")),
        _admin("system_capacity", "Largest tables (latest snapshot)", ("tables",), (
            Field("table", "Table", width=36), _count("total_bytes", "Total bytes"), _count("table_bytes", "Table bytes"),
            _count("index_bytes", "Index bytes"), _count("live_rows", "Live rows"), _count("dead_rows", "Dead rows"),
            Field("last_autovacuum", "Last autovacuum (UTC)"), _count("seq_scan", "Seq scans"), _count("idx_scan", "Index scans"),
        ), key="tables", query=_system()),
        _admin("system_capacity", "Media storage by kind", ("latest", "media_bytes"), (
            Field("kind", "Kind"), Field("bytes", "Bytes", INT, SUM)), key="media", shape="pairs", query=_system()),
    ),
    keywords=("database", "storage", "disk", "tables", "size", "consumption", "capacity"),
)

THIRD_PARTY = Report(
    "third-party-usage", "Third-party usage", "Server",
    "Calls, failures and units per provider and operation per day: push, image moderation, AI copilot, voice "
    "moderation, SOS webhook, payments and video calls.",
    ("admin", "system/third-party"), (S_FROM, S_TO),
    datasets=(
        _admin("system_third_party", "Totals", ("totals",), (
            Field("provider", "Provider"), Field("operation", "Operation"), _count("calls", "Calls"),
            _count("failures", "Failures"), Field("units", "Units", NUMBER, SUM),
        ), key="totals", query=_system(), group_by=("provider",), groupable=("provider",)),
        _admin("system_third_party", "By day", ("rows",), (
            Field("day", "Day", DATE), Field("provider", "Provider"), Field("operation", "Operation"),
            _count("calls", "Calls"), _count("failures", "Failures"), Field("units", "Units", NUMBER, SUM),
            Field("unit_label", "Unit"),
        ), key="daily", query=_system(), groupable=("provider", "operation", "day")),
    ),
    keywords=("vendors", "cost", "push", "stripe", "ai", "usage", "consumption"),
)

SERVER_REPORTS = (API_TRAFFIC, JOB_RUNS, DB_CONSUMPTION, THIRD_PARTY)

REPORTS: tuple[Report, ...] = (*MEMBER_REPORTS, *OPERATIONS_REPORTS, *SERVER_REPORTS, REVENUE, SUBSCRIPTIONS, CONVERSION, COINS, REFERRALS, SPEND, *PRODUCT)
BY_ID = {r.id: r for r in REPORTS}
CATEGORIES = ("Members", "Operations", "Business", "Product", "Server")
