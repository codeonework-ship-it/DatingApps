"""Business (commercial) reports.

Every number is defined and computed by the BFF (/v1/admin/business/...,
documents/BUSINESS_REPORTS_2026-10-01.md); this module only chooses the
window, renders tables and charts, and proxies CSV downloads with the
operator's token. Roles are enforced by the BFF: admin, finance, ops_admin and
analyst read; finance and admin record marketing spend; finance, ops_admin and
admin maintain launch-market gates.
"""
from __future__ import annotations

import re
from typing import Any

from django.contrib import messages
from django.http import Http404, HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.urls import reverse
from django.views.decorators.http import require_GET, require_POST

from . import listing
from .services.go_client import GoBFFClient

TIMEZONES = ("UTC", "Asia/Kolkata", "Europe/London", "Europe/Berlin", "Europe/Paris", "Europe/Warsaw")
MODES = ("live", "sandbox", "all")
BUCKETS = ("day", "week", "month")
CSV_REPORTS = set(GoBFFClient.BUSINESS_REPORTS)
_TABLE = re.compile(r"^[a-z_]{1,40}$")
_UUID = re.compile(r"^[0-9a-fA-F-]{36}$")

PAGES = (
    ("business_revenue", "Revenue", "bi-graph-up-arrow"),
    ("business_subscriptions", "Subscriptions & MRR", "bi-arrow-repeat"),
    ("business_conversion", "Conversion & funnel", "bi-funnel"),
    ("business_coins", "Coin economy", "bi-coin"),
    ("business_referrals", "Referrals & introducers", "bi-people"),
    ("business_markets", "Market readiness", "bi-geo-alt"),
    ("business_investor_pack", "Investor KPI pack", "bi-briefcase"),
    ("business_spend", "Marketing spend", "bi-cash-stack"),
)

RELEASE_NOTE = (
    "Billing is excluded from release 1 (PEN-25), so zero live revenue is expected. "
    "Sandbox payments from QA are shown only when you choose the sandbox or all mode."
)


def _filters(request: HttpRequest, *, default_bucket: str = "") -> dict[str, str]:
    """Validated query parameters forwarded to the BFF (empty ones omitted)."""
    out: dict[str, str] = {}
    for key in ("since", "until"):
        value = request.GET.get(key, "").strip()
        if value and listing.is_day(value):
            out[key] = value
    tz = request.GET.get("tz", "").strip()
    if tz in TIMEZONES:
        out["tz"] = tz
    mode = request.GET.get("mode", "").strip()
    if mode in MODES:
        out["mode"] = mode
    bucket = request.GET.get("bucket", "").strip() or default_bucket
    if bucket in BUCKETS:
        out["bucket"] = bucket
    months = request.GET.get("months", "").strip()
    if months.isdigit() and 1 <= int(months) <= 36:
        out["months"] = months
    return out


def _display(value: Any) -> str:
    if value is None:
        return "—"
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, float):
        return f"{value:.4g}" if abs(value) < 10 else f"{value:,.2f}"
    return str(value)


def _pct(value: Any) -> str:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f"{value * 100:.1f}%"
    return "—"


def _money(row: dict, key: str) -> str:
    value = row.get(key)
    if value in (None, ""):
        return "—"
    return f"{value} {row.get('currency', '')}".strip()


def _table(title: str, csv: str, columns: list[str], rows: list[list[Any]], *, note: str = "") -> dict:
    return {"title": title, "csv": csv, "columns": columns, "rows": [[_display(v) for v in r] for r in rows], "note": note}


def _render(request: HttpRequest, template: str, page: str, report: str, filters: dict, result, extra: dict) -> HttpResponse:
    from .views import _base_context  # late import keeps module import cheap and patchable

    data = result.data if result.ok and isinstance(result.data, dict) else {}
    status = data.get("data_status") or {}
    context = _base_context()
    context.update({
        "page": page,
        "pages": PAGES,
        "report": report,
        "data": data,
        "error": result.error if not result.ok else "",
        "filters": filters,
        "timezones": TIMEZONES,
        "modes": MODES,
        "buckets": BUCKETS,
        "data_status": status,
        "release_note": RELEASE_NOTE,
        "show_empty": bool(status.get("empty")),
        "csv_tables": data.get("tables", []),
        "csv_url": reverse("business_csv", args=[report]),
        "query": "&".join(f"{k}={v}" for k, v in filters.items()),
        "fields": ("since", "until", "tz", "mode", "bucket"),
    })
    context.update(extra)
    return render(request, template, context)


def _currency_series(rows: list[dict], label_key: str, value_key: str) -> dict:
    """{labels, datasets:[{label: currency, data}]} for Chart.js; never mixes currencies."""
    labels: list[str] = []
    series: dict[str, dict[str, Any]] = {}
    for row in rows:
        label = str(row.get(label_key, ""))
        if label not in labels:
            labels.append(label)
        series.setdefault(str(row.get("currency", "")), {})[label] = row.get(value_key)
    datasets = []
    for currency, values in sorted(series.items()):
        datasets.append({"label": currency, "data": [_minor_to_major(values.get(l)) for l in labels]})
    return {"labels": labels, "datasets": datasets}


def _minor_to_major(value: Any) -> Any:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return round(value / 100, 2)
    return None


# ── Revenue ────────────────────────────────────────────────────────────────

@require_GET
def business_revenue(request: HttpRequest) -> HttpResponse:
    filters = _filters(request)
    result = GoBFFClient().business_report("revenue", filters)
    data = result.data if result.ok else {}
    totals = data.get("totals") or []
    trend = data.get("trend") or []
    tables = [
        _table("Totals by currency", "totals",
               ["Currency", "Market", "Gross", "Refunded", "Chargebacks", "Disputed (held)", "Net", "Settled payments", "Paying members", "ARPPU", "ARPU", "Refund rate", "Chargeback rate"],
               [[r.get("currency"), r.get("market"), r.get("gross"), r.get("refunded"), r.get("chargeback"), r.get("disputed"), r.get("net"),
                 r.get("settled_payments"), r.get("paying_members"), r.get("arppu"), r.get("arpu"), _pct(r.get("refund_rate")), _pct(r.get("chargeback_rate"))] for r in totals]),
        _table("By product", "by_product", ["Currency", "Type", "Product", "Payments", "Gross", "Refunded", "Chargebacks", "Net"],
               [[r.get("currency"), r.get("product_type"), r.get("product_code"), r.get("payments"), r.get("gross"), r.get("refunded"), r.get("chargeback"), r.get("net")] for r in data.get("by_product") or []]),
        _table("By payer city", "by_city", ["City", "Currency", "Paying members", "Net"],
               [[r.get("city"), r.get("currency"), r.get("paying_members"), r.get("net")] for r in data.get("by_city") or []],
               note="Cities with fewer than five paying members are pooled."),
        _table("Trend", "trend", ["Bucket", "Currency", "Gross", "Refunded", "Chargebacks", "Net", "Subscriptions", "Coin packages", "Refund rate", "Chargeback rate"],
               [[r.get("bucket"), r.get("currency"), r.get("gross"), r.get("refunded"), r.get("chargeback"), r.get("net"),
                 _minor_to_major(r.get("subscription_net_minor")), _minor_to_major(r.get("coin_package_net_minor")),
                 _pct(r.get("refund_rate")), _pct(r.get("chargeback_rate"))] for r in trend]),
    ]
    charts = {
        "net": _currency_series(trend, "bucket", "net_minor"),
        "refunds": _currency_series(trend, "bucket", "refunded_minor"),
    }
    reconciliation = reverse("billing_reconciliation")
    recon_query = "&".join(f"{k}={v}" for k, v in filters.items() if k in ("since", "until"))
    return _render(request, "control_panel/business/revenue.html", "business_revenue", "revenue", filters, result, {
        "totals": totals, "tables": tables, "charts": charts,
        "reconciliation_url": f"{reconciliation}?{recon_query}" if recon_query else reconciliation,
    })


# ── Subscriptions & MRR ────────────────────────────────────────────────────

@require_GET
def business_subscriptions(request: HttpRequest) -> HttpResponse:
    filters = _filters(request, default_bucket="month")
    result = GoBFFClient().business_report("subscriptions", filters)
    data = result.data if result.ok else {}
    moves = data.get("movements") or []
    currencies = sorted({m.get("currency") for m in moves if m.get("currency")})
    currency = request.GET.get("currency", "") if request.GET.get("currency", "") in currencies else (currencies[0] if currencies else "")
    waterfall = None
    selected = [m for m in moves if m.get("currency") == currency]
    if selected:
        def total(key: str) -> int:
            return sum(int(m.get(key) or 0) for m in selected)
        start = int(selected[0].get("mrr_start_minor") or 0)
        steps = [("Start MRR", 0, start), ("New", start, start + total("new_minor"))]
        level = start + total("new_minor")
        steps.append(("Expansion", level, level + total("expansion_minor")))
        level += total("expansion_minor")
        steps.append(("Contraction", level - total("contraction_minor"), level))
        level -= total("contraction_minor")
        steps.append(("Churned", level - total("churned_minor"), level))
        level -= total("churned_minor")
        steps.append(("End MRR", 0, level))
        waterfall = {"currency": currency, "labels": [s[0] for s in steps], "data": [[round(a / 100, 2), round(b / 100, 2)] for _, a, b in steps]}
    churn = data.get("churn") or {}
    graduation = data.get("graduation_refund") or {}
    tables = [
        _table("MRR movements", "movements", ["Bucket", "Currency", "Start MRR", "New", "Expansion", "Contraction", "Churned", "End MRR", "Subscribers start", "New subs", "Churned subs", "Subscribers end", "Logo churn", "Revenue churn", "Net MRR retention"],
               [[m.get("bucket"), m.get("currency"), m.get("mrr_start"), m.get("new"), m.get("expansion"), m.get("contraction"), m.get("churned"), m.get("mrr_end"),
                 m.get("subscribers_start"), m.get("new_subscribers"), m.get("churned_subscribers"), m.get("subscribers_end"),
                 _pct(m.get("logo_churn_rate")), _pct(m.get("revenue_churn_rate")), _pct(m.get("net_mrr_retention"))] for m in moves]),
        _table("Churn reasons", "churn_reasons", ["Reason", "Subscribers", "Healthy"],
               [[r.get("reason"), r.get("subscribers"), r.get("healthy")] for r in churn.get("reasons") or []],
               note=churn.get("note", "")),
        _table("Active plan mix", "plan_mix", ["Plan", "Cycle", "Currency", "Active subscribers", "Cancelling at period end"],
               [[r.get("plan"), r.get("billing_cycle"), r.get("currency"), r.get("active_subscribers"), r.get("cancel_at_period_end")] for r in data.get("plan_mix") or []]),
        _table("Graduation Refund (model)", "", ["Currency", "Eligible members", "Estimated cost"],
               [[r.get("currency"), r.get("eligible_members"), r.get("estimated_cost")] for r in graduation.get("estimated_costs") or []],
               note=graduation.get("note", "")),
    ]
    charts = {"mrr": _currency_series(data.get("mrr") or [], "label", "mrr_minor"), "waterfall": waterfall}
    return _render(request, "control_panel/business/subscriptions.html", "business_subscriptions", "subscriptions", filters, result, {
        "tables": tables, "charts": charts, "churn": churn, "currencies": currencies, "currency": currency,
        "trials": data.get("trials") or {},
    })


# ── Conversion & funnel ────────────────────────────────────────────────────

@require_GET
def business_conversion(request: HttpRequest) -> HttpResponse:
    filters = _filters(request)
    client = GoBFFClient()
    conv_filters = {k: v for k, v in filters.items() if k != "bucket"}
    result = client.business_report("conversion", conv_filters)
    # Go's funnel never buckets but caps a window at 400 *day* buckets by
    # default, so a long conversion window would make it fail; month keeps it valid.
    funnel_result = client.business_report("funnel", {**conv_filters, "bucket": "month"})
    data = result.data if result.ok else {}
    funnel = funnel_result.data if funnel_result.ok else {}
    ltv_rows = data.get("ltv") or []
    max_months = 0
    for r in ltv_rows:
        max_months = max(max_months, len(r.get("cumulative_net_per_member_minor") or []))
    max_months = min(max_months, 13)
    ltv_table = _table("LTV — cumulative net revenue per member by month since signup", "ltv",
                       ["Cohort", "Currency", "Members"] + [f"M{i}" for i in range(max_months)],
                       [[r.get("cohort"), r.get("currency"), r.get("members")] + [
                           _minor_to_major(v) for v in (r.get("cumulative_net_per_member_minor") or [])[:max_months]
                       ] + [None] * (max_months - len((r.get("cumulative_net_per_member_minor") or [])[:max_months])) for r in ltv_rows])
    tables = [
        _table("Free → paid by signup cohort", "cohorts", ["Cohort", "Members", "Paid ≤7d", "Paid ≤30d", "Paid ≤90d", "Paid to date", "Subscribed", "Conv. 30d", "Conv. to date", "30d mature"],
               [[c.get("cohort"), c.get("members"), c.get("paid_7d"), c.get("paid_30d"), c.get("paid_90d"), c.get("paid_to_date"), c.get("subscribed_to_date"),
                 _pct(c.get("conversion_30d")), _pct(c.get("conversion_to_date")), c.get("mature_30d")] for c in data.get("cohorts") or []]),
        ltv_table,
    ]
    funnel_table = _table("Checkout funnel", "funnel", ["Kind", "Product", "Platform", "Created", "Completed", "Paid", "Refunded", "Abandoned/expired", "Open", "Completion", "Paid rate", "Refund rate"],
                          [[r.get("kind"), r.get("product"), r.get("platform"), r.get("created"), r.get("completed"), r.get("paid"), r.get("refunded"),
                            r.get("abandoned_or_expired"), r.get("open"), _pct(r.get("completion_rate")), _pct(r.get("paid_rate")), _pct(r.get("refund_rate"))] for r in funnel.get("detail") or []])
    totals = funnel.get("totals") or {}
    funnel_chart = {"labels": ["Created", "Completed", "Paid", "Refunded"],
                    "data": [totals.get(k) if isinstance(totals.get(k), int) else None for k in ("created", "completed", "paid", "refunded")]}
    return _render(request, "control_panel/business/conversion.html", "business_conversion", "conversion", conv_filters, result, {
        "fields": ("since", "until", "tz", "mode"),
        "tables": tables, "funnel": funnel, "funnel_table": funnel_table, "funnel_chart": funnel_chart,
        "funnel_error": funnel_result.error if not funnel_result.ok else "",
        "actives": data.get("actives_conversion") or {},
        "funnel_csv_url": reverse("business_csv", args=["funnel"]),
    })


# ── Coin economy ───────────────────────────────────────────────────────────

@require_GET
def business_coins(request: HttpRequest) -> HttpResponse:
    filters = _filters(request)
    result = GoBFFClient().business_report("coins", filters)
    data = result.data if result.ok else {}
    trend = data.get("trend") or []
    sinks = data.get("sinks") or {}
    gifts = sinks.get("gifts") or {}
    sources = data.get("sources") or {}
    tables = [
        _table("Coin flows", "trend", ["Bucket", "Purchased", "Granted", "Returned", "Gift spend", "Clawbacks", "Net flow"],
               [[r.get("bucket"), r.get("purchased"), r.get("granted"), r.get("returned"), r.get("gift_spend"), r.get("clawback_debits"), r.get("net_flow")] for r in trend]),
        _table("Purchases by currency", "", ["Currency", "Mode", "Purchases", "Coins", "Amount", "Buyers"],
               [[r.get("currency"), r.get("mode"), r.get("count"), r.get("coins"), r.get("amount"), r.get("buyers")] for r in (sources.get("purchased") or {}).get("by_currency") or []]),
        _table("Non-revenue credits", "", ["Source", "Credits", "Coins"],
               [[k, v.get("count"), v.get("coins")] for k, v in sorted((sources.get("non_revenue") or {}).items())]),
        _table("Top gifts by coins", "", ["Gift", "Sends", "Coins"], [[g.get("gift_id"), g.get("sends"), g.get("coins")] for g in gifts.get("top_gifts") or []]),
        _table("Clawbacks", "", ["Source", "Debits", "Coins debited", "Shortfall"], [[d.get("source"), d.get("count"), d.get("coins_debited"), d.get("coins_shortfall")] for d in sinks.get("clawbacks") or []]),
    ]
    chart = {"labels": [r.get("bucket") for r in trend], "datasets": [
        {"label": "Purchased", "data": [r.get("purchased") for r in trend]},
        {"label": "Granted", "data": [r.get("granted") for r in trend]},
        {"label": "Gift spend", "data": [-(r.get("gift_spend") or 0) for r in trend]},
        {"label": "Clawbacks", "data": [-(r.get("clawback_debits") or 0) for r in trend]},
    ]}
    return _render(request, "control_panel/business/coins.html", "business_coins", "coins", filters, result, {
        "tables": tables, "chart": chart, "liability": data.get("liability") or {}, "velocity": data.get("velocity") or {},
        "gifts": gifts, "sources": sources, "sinks": sinks,
    })


# ── Referrals & introducers ────────────────────────────────────────────────

@require_GET
def business_referrals(request: HttpRequest) -> HttpResponse:
    filters = {k: v for k, v in _filters(request).items() if k != "bucket"}
    result = GoBFFClient().business_report("referrals", filters)
    data = result.data if result.ok else {}
    k = data.get("k_factor") or {}
    intro = data.get("introducers") or {}
    tables = [
        _table("Friend K-factor by signup cohort", "k_factor", ["Cohort", "Members", "Referral signups ≤30d", "Introducer invites ≤30d", "Introducer accepted ≤30d", "K referral", "K introducer", "K total", "Invites / member", "Acceptance"],
               [[r.get("cohort"), r.get("members"), r.get("referral_signups_30d"), r.get("introducer_invites_30d"), r.get("introducer_accepted_30d"),
                 r.get("k_referral"), r.get("k_introducer"), r.get("k_total"), r.get("introducer_invites_per_member"), _pct(r.get("introducer_acceptance_rate"))] for r in k.get("by_cohort") or []],
               note=k.get("definition", "")),
        _table("Intros", "intros", ["Introducer", "Intros", "Matched", "Declined", "Expired", "Open", "Match rate"],
               [[r.get("introducer_kind"), r.get("intros"), r.get("matched"), r.get("declined"), r.get("expired"), r.get("open"), _pct(r.get("match_rate"))] for r in intro.get("intros") or []]),
    ]
    return _render(request, "control_panel/business/referrals.html", "business_referrals", "referrals", filters, result, {
        "fields": ("since", "until", "tz", "mode"),
        "tables": tables, "k": k, "referrals": data.get("referrals") or {}, "introducers": intro,
        "referrals_enabled": data.get("referrals_enabled"), "referrals_note": data.get("referrals_note", ""),
    })


# ── Market readiness ───────────────────────────────────────────────────────

@require_GET
def business_markets(request: HttpRequest) -> HttpResponse:
    filters = {k: v for k, v in _filters(request).items() if k in ("until", "tz")}
    result = GoBFFClient().business_report("markets", filters)
    data = result.data if result.ok else {}
    rows = []
    for m in data.get("markets") or []:
        gates = m.get("gates") or {}
        verified = gates.get("verified_members") or {}
        gender = gates.get("gender_balance") or {}
        plans = gates.get("plans_kept_per_active") or {}
        rows.append({**m, "verified_target": verified.get("target"), "verified_progress": _pct(verified.get("progress")),
                     "verified_met": verified.get("met"), "gender_share": _pct(gender.get("largest_share")), "gender_met": gender.get("met"),
                     "plans_value": plans.get("value"), "plans_target": plans.get("target"), "plans_met": plans.get("met"),
                     "live_gate_met": gates.get("live_gate_met")})
    return _render(request, "control_panel/business/markets.html", "business_markets", "markets", filters, result, {
        "fields": ("until", "tz"),
        "rows": rows, "defaults": data.get("default_gates") or {}, "members_without_city": data.get("members_without_city"),
    })


@require_POST
def business_market_save(request: HttpRequest) -> HttpResponse:
    try:
        payload: dict[str, Any] = {key: request.POST.get(key, "").strip() for key in ("city_key", "display_name", "country", "currency", "notes")}
        payload["city_key"] = payload["city_key"].lower()
        payload["currency"] = payload["currency"].upper()
        payload["verified_target"] = int(request.POST.get("verified_target") or "3000")
        payload["max_gender_share"] = float(request.POST.get("max_gender_share") or "0.6")
        payload["plans_kept_target"] = float(request.POST.get("plans_kept_target") or "0.08")
        payload["approaching_share"] = float(request.POST.get("approaching_share") or "0.5")
        order = request.POST.get("launch_order", "").strip()
        if order:
            payload["launch_order"] = int(order)
        payload["aliases"] = [a.strip().lower() for a in request.POST.get("aliases", "").split(",") if a.strip()]
        payload["active"] = request.POST.get("active", "on") == "on"
    except (TypeError, ValueError):
        messages.error(request, "Targets must be numbers (verified target a whole number, shares between 0 and 1).")
        return redirect("business_markets")
    result = GoBFFClient().save_launch_market(payload)
    (messages.success if result.ok else messages.error)(request, "Launch market saved." if result.ok else result.error)
    return redirect("business_markets")


# ── Investor KPI pack ──────────────────────────────────────────────────────

@require_GET
def business_investor_pack(request: HttpRequest) -> HttpResponse:
    filters = {k: v for k, v in _filters(request).items() if k != "bucket"}
    result = GoBFFClient().business_report("investor-pack", filters)
    data = result.data if result.ok else {}
    months = data.get("months") or []
    rows = []
    for m in months:
        per = m.get("by_currency") or [{}]
        for i, c in enumerate(per):
            rows.append({"month": m.get("month") if i == 0 else "", "first": i == 0, "span": len(per), **{k: m.get(k) for k in (
                "members_total", "new_members", "mau", "plans_kept", "north_star", "burn")}, "c": c})
    return _render(request, "control_panel/business/investor_pack.html", "business_investor_pack", "investor-pack", filters, result, {
        "fields": ("since", "until", "tz", "mode", "months"),
        "rows": rows, "months": months, "inputs": data.get("inputs") or {}, "definitions": data.get("definitions") or {},
        "printable": request.GET.get("print") == "1",
    })


# ── Marketing spend ────────────────────────────────────────────────────────

@require_GET
def business_spend(request: HttpRequest) -> HttpResponse:
    filters = {k: v for k, v in _filters(request).items() if k in ("since", "until", "tz")}
    result = GoBFFClient().business_report("marketing-spend", filters)
    data = result.data if result.ok else {}
    cac = _table("CAC by month, market and currency", "cac", ["Month", "Market", "Currency", "Spend", "New members", "CAC", "Attributed members", "Attributed CAC"],
                 [[r.get("month"), r.get("market"), r.get("currency"), r.get("spend"), r.get("new_members"), r.get("cac"), r.get("attributed_members"), r.get("attributed_cac")] for r in data.get("cac") or []])
    return _render(request, "control_panel/business/spend.html", "business_spend", "marketing-spend", filters, result, {
        "fields": ("since", "until", "tz"),
        "entries": data.get("entries") or [], "cac_table": cac, "channels": data.get("channels") or [],
        "markets": data.get("markets") or ["all"], "spend_status": data.get("status", ""), "spend_note": data.get("note", ""),
    })


@require_POST
def business_spend_save(request: HttpRequest) -> HttpResponse:
    payload: dict[str, Any] = {key: request.POST.get(key, "").strip() for key in ("month", "channel", "market", "currency", "amount", "note")}
    payload["currency"] = payload["currency"].upper()
    attributed = request.POST.get("attributed_members", "").strip()
    if attributed:
        if not attributed.isdigit():
            messages.error(request, "Attributed members must be a whole number.")
            return redirect("business_spend")
        payload["attributed_members"] = int(attributed)
    if not re.match(r"^\d{4}-\d{2}$", payload["month"]):
        messages.error(request, "Choose a month (YYYY-MM).")
        return redirect("business_spend")
    result = GoBFFClient().save_marketing_spend(payload)
    if result.ok:
        messages.success(request, "Spend recorded." if result.data.get("created") else "Spend for that month, channel, market and currency was replaced.")
    else:
        messages.error(request, result.error)
    return redirect("business_spend")


@require_POST
def business_spend_delete(request: HttpRequest, spend_id: str) -> HttpResponse:
    if not _UUID.match(spend_id):
        raise Http404
    result = GoBFFClient().delete_marketing_spend(spend_id)
    (messages.success if result.ok else messages.error)(request, "Spend entry deleted." if result.ok else result.error)
    return redirect("business_spend")


# ── CSV downloads ──────────────────────────────────────────────────────────

@require_GET
def business_csv(request: HttpRequest, report: str) -> HttpResponse:
    if report not in CSV_REPORTS:
        raise Http404
    params: dict[str, str] = _filters(request)
    table = request.GET.get("table", "").strip()
    if table and _TABLE.match(table):
        params["table"] = table
    result = GoBFFClient().business_csv(report, params)
    if not result.ok:
        messages.error(request, f"CSV export failed: {result.error}")
        return redirect(dict(PAGES_BY_REPORT).get(report, "business_revenue"))
    response = HttpResponse(result.content, content_type="text/csv; charset=utf-8")
    response["Content-Disposition"] = f'attachment; filename="business-{report}-{params.get("table", "report")}.csv"'
    response["Cache-Control"] = "no-store"
    return response


PAGES_BY_REPORT = (
    ("revenue", "business_revenue"), ("subscriptions", "business_subscriptions"), ("conversion", "business_conversion"),
    ("funnel", "business_conversion"), ("coins", "business_coins"), ("referrals", "business_referrals"),
    ("markets", "business_markets"), ("investor-pack", "business_investor_pack"), ("marketing-spend", "business_spend"),
)
