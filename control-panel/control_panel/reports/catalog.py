"""The report catalog: every report the console's report server offers.

Business reports read /v1/admin/business/<name> (documents/
BUSINESS_REPORTS_2026-10-01.md); product reports read the durable analytics
snapshots at /v1/admin/analytics/<name>, which describe their own tables.
"""
from __future__ import annotations

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
        ), group_by=("kind",), groupable=("kind", "product", "platform")),
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
        ("trends", "Active members over time", "DAU, WAU and MAU by period.", ANALYTICS_PARAMS, ("dau", "wau", "mau")),
        ("funnel", "Activation funnel", "Signup to first match and first date, by step.", ANALYTICS_PARAMS, ("activation", "onboarding")),
        ("retention", "Retention cohorts", "Weekly retention triangle by signup cohort.", ANALYTICS_PARAMS, ("cohort", "churn")),
        ("engagement", "Engagement", "Likes, matches, messages and plans per active member.", ANALYTICS_PARAMS, ("messages", "matches")),
        ("liquidity", "Liquidity by city", "Supply, demand and match rates by city.", ANALYTICS_PARAMS + (A_CITY,), ("city", "market")),
        ("safety", "Safety health", "Reports, blocks and SOS per 1,000 DAU, and response times.", ANALYTICS_PARAMS, ("reports", "blocks", "sos")),
    )
)

REPORTS: tuple[Report, ...] = (REVENUE, SUBSCRIPTIONS, CONVERSION, COINS, REFERRALS, SPEND, *PRODUCT)
BY_ID = {r.id: r for r in REPORTS}
CATEGORIES = ("Business", "Product")
