"""Product analytics pages.

Every number, the small-count suppression and the role check come from the
BFF (/v1/admin/analytics/*): the console only formats tables and charts. A
chart always has the same numbers in a table next to it.
"""
from __future__ import annotations

import re
from datetime import date

from django.contrib import messages
from django.http import HttpRequest, HttpResponse, StreamingHttpResponse
from django.shortcuts import redirect, render
from django.urls import reverse
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient

SEGMENTS = {
    "gender": ("Gender", ["female", "male", "other", "unknown"]),
    "age_band": ("Age band", ["18-24", "25-29", "30-34", "35-44", "45+", "unknown"]),
    "account_age_band": ("Account age", ["day_0", "days_1_6", "days_7_29", "days_30_89", "days_90_plus", "unknown"]),
    "level_band": ("Level band", ["L1-L3", "L4-L7", "L8-L10"]),
}
GRAINS = ("day", "week", "month")
REPORTS = GoBFFClient.ANALYTICS_REPORTS
_DAY = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_UUID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
EXPORT_PARAMS = ("from", "to", "as_of", "grain", "group_by", "metric", "cohort", "within_days", "experiment", "table",
                 "gender", "city", "age_band", "account_age_band", "level_band")

PAGES = [
    ("analytics_overview", "Overview"),
    ("analytics_funnel", "Activation funnel"),
    ("analytics_retention", "Retention"),
    ("analytics_engagement", "Engagement"),
    ("analytics_liquidity", "Liquidity by city"),
    ("analytics_safety", "Safety health"),
    ("analytics_data", "Data & exclusions"),
]


def _valid_day(value: str) -> str:
    value = (value or "").strip()
    if not _DAY.match(value):
        return ""
    try:
        date.fromisoformat(value)
    except ValueError:
        return ""
    return value


def _filters(request: HttpRequest, *, grain_default: str = "day", allow_grain: bool = True, segments: tuple = ("gender", "city", "age_band", "account_age_band", "level_band")) -> dict:
    """Validated query parameters for the BFF plus the form state to render."""
    q = request.GET
    params: dict[str, str] = {}
    for key in ("from", "to"):
        day = _valid_day(q.get(key, ""))
        if day:
            params[key] = day
    for key in segments:
        value = (q.get(key) or "").strip()
        if key == "city":
            if value and len(value) <= 100:
                params["city"] = value
        elif value in SEGMENTS[key][1]:
            params[key] = value
    grain = (q.get("grain") or "").strip()
    if allow_grain:
        params["grain"] = grain if grain in GRAINS else grain_default
    return {
        "params": params,
        "segment_fields": [
            {"key": key, "label": SEGMENTS[key][0], "choices": SEGMENTS[key][1], "value": params.get(key, "")}
            for key in segments if key != "city"
        ],
        "show_city": "city" in segments,
        "city": params.get("city", ""),
        "allow_grain": allow_grain,
        "grain": params.get("grain", ""),
        "grains": GRAINS,
        "from": params.get("from", ""),
        "to": params.get("to", ""),
    }


def _format(value, column: dict, suppressed: bool) -> str:
    if suppressed:
        return "<5"
    if value is None:
        return "—"
    unit = column.get("unit") or ""
    if isinstance(value, float):
        text = f"{value:,.4f}".rstrip("0").rstrip(".") if abs(value) < 1000 else f"{value:,.1f}"
    elif isinstance(value, int) and not isinstance(value, bool):
        text = f"{value:,}" if column.get("kind") != "dimension" else str(value)
    else:
        text = str(value)
    if unit == "%":
        return f"{text}%"
    return text


def _table(result, name: str) -> dict:
    """A report table shaped for templates: headers and display cells."""
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    table = (data.get("tables") or {}).get(name) or {}
    columns = [c for c in table.get("columns") or [] if isinstance(c, dict)]
    rows = []
    for row in table.get("rows") or []:
        if not isinstance(row, dict):
            continue
        suppressed = set(row.get("suppressed") or [])
        cells = []
        for column in columns:
            key = column.get("key")
            cells.append({
                "key": key,
                "text": _format(row.get(key), column, key in suppressed),
                "raw": None if key in suppressed else row.get(key),
                "numeric": column.get("kind") != "dimension",
                "suppressed": key in suppressed,
            })
        rows.append({"cells": cells, "raw": row})
    return {"columns": columns, "rows": rows, "name": name}


def _number(row: dict, key: str):
    value = row.get(key)
    if key in set(row.get("suppressed") or []):
        return None
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def _error(*results) -> str:
    for result in results:
        if not result.ok:
            if result.status_code == 403:
                return "Analytics reports require the analyst or admin role."
            return result.error or "Analytics are unavailable."
    return ""


def _range(result) -> dict:
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    meta = data.get("meta") if isinstance(data.get("meta"), dict) else {}
    return {"from": data.get("from", ""), "to": data.get("to", ""), "latest": meta.get("latest_built_day", ""),
            "definition": meta.get("definition", ""), "warning": meta.get("warning", "")}


def _export_query(params: dict, **extra) -> str:
    from urllib.parse import urlencode

    merged = {**params, **{k: v for k, v in extra.items() if v not in (None, "")}}
    return urlencode({k: v for k, v in merged.items() if k in EXPORT_PARAMS})


def _context(request: HttpRequest, page: str, filters: dict, **extra) -> dict:
    from django.conf import settings

    return {
        "project_name": settings.PROJECT_DISPLAY_NAME,
        "analytics_pages": [{"url_name": name, "label": label, "active": name == page} for name, label in PAGES],
        "filters": filters,
        **extra,
    }


# ── Overview ──────────────────────────────────────────────────────────────────

@require_GET
def analytics_overview(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request)
    params = filters["params"]
    segment_params = {k: v for k, v in params.items() if k not in ("from", "grain")}
    kpis = client.analytics_report("kpis", {**segment_params, **({"as_of": params["to"]} if "to" in params else {})})
    series = {metric: client.analytics_report("trends", {**params, "metric": metric}) for metric in ("dau", "wau", "mau")}
    tiles = []
    kpi_data = kpis.data if kpis.ok and isinstance(kpis.data, dict) else {}
    for row in ((kpi_data.get("tables") or {}).get("tiles") or {}).get("rows") or []:
        if not isinstance(row, dict):
            continue
        suppressed = set(row.get("suppressed") or [])
        column = {"unit": "%" if row.get("unit") == "%" else ""}
        tiles.append({
            "key": row.get("key"), "label": row.get("label"), "unit": row.get("unit"), "definition": row.get("definition"),
            "value": _format(row.get("value"), column, "value" in suppressed),
            "previous": _format(row.get("previous"), column, "previous" in suppressed),
        })
    labels, datasets, table_rows = [], {}, {}
    for metric, result in series.items():
        rows = _table(result, "series")["rows"]
        for row in rows:
            period = row["raw"].get("period")
            if period not in table_rows:
                table_rows[period] = {"period": period}
                labels.append(period)
            table_rows[period][metric] = next(c["text"] for c in row["cells"] if c["key"] == "value")
        datasets[metric] = {r["raw"].get("period"): _number(r["raw"], "value") for r in rows}
    chart = {
        "type": "line",
        "labels": labels,
        "datasets": [
            {"label": label, "data": [datasets.get(metric, {}).get(p) for p in labels]}
            for metric, label in (("dau", "DAU (average per day)"), ("wau", "WAU"), ("mau", "MAU"))
        ],
    }
    return render(request, "control_panel/analytics/overview.html", _context(
        request, "analytics_overview", filters,
        tiles=tiles, chart=chart, trend_rows=[table_rows[p] for p in labels],
        range=_range(kpis), series_range=_range(series["dau"]),
        error=_error(kpis, *series.values()),
        export_query=_export_query(params, metric="dau"),
        kpi_export_query=_export_query(segment_params, as_of=params.get("to")),
    ))


# ── Activation funnel ─────────────────────────────────────────────────────────

@require_GET
def analytics_funnel(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request, allow_grain=False)
    params = filters["params"]
    within = (request.GET.get("within_days") or "").strip()
    if within and (not within.isdigit() or int(within) > 365):
        within = ""
    extra = {"within_days": within} if within else {}
    total = client.analytics_report("funnel", {**params, **extra, "cohort": "all"})
    weekly = client.analytics_report("funnel", {**params, **extra, "cohort": "week"})
    total_table = _table(total, "steps")
    chart = {
        "type": "bar",
        "labels": [r["raw"].get("step_label") for r in total_table["rows"]],
        "datasets": [{"label": "Members reaching the step", "data": [_number(r["raw"], "members") for r in total_table["rows"]]}],
    }
    return render(request, "control_panel/analytics/funnel.html", _context(
        request, "analytics_funnel", filters,
        total_table=total_table, weekly_table=_table(weekly, "steps"), chart=chart, within_days=within,
        extra_filter={"name": "within_days", "label": "Steps within days (0 = any)", "value": within, "number": True},
        range=_range(total), error=_error(total, weekly),
        export_query=_export_query(params, cohort="week", within_days=within),
    ))


# ── Retention ─────────────────────────────────────────────────────────────────

@require_GET
def analytics_retention(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request, grain_default="week")
    params = filters["params"]
    experiment = (request.GET.get("experiment") or "").strip()
    if experiment and not re.match(r"^[a-z0-9_.-]{1,80}$", experiment):
        experiment = ""
    result = client.analytics_report("retention", {**params, **({"experiment": experiment} if experiment else {})})
    triangle = _table(result, "triangle")
    for row in triangle["rows"]:
        for cell in row["cells"]:
            raw = cell["raw"]
            cell["heat"] = (
                round(min(max(raw, 0), 100) / 100, 2)
                if cell["key"].startswith("week_") and isinstance(raw, (int, float)) else None
            )
    return render(request, "control_panel/analytics/retention.html", _context(
        request, "analytics_retention", filters,
        summary=_table(result, "summary"), triangle=triangle, experiment=experiment,
        extra_filter={"name": "experiment", "label": "Experiment key (variants)", "value": experiment, "number": False},
        range=_range(result), error=_error(result),
        export_summary=_export_query(params, experiment=experiment, table="summary"),
        export_triangle=_export_query(params, experiment=experiment, table="triangle"),
    ))


# ── Engagement ────────────────────────────────────────────────────────────────

@require_GET
def analytics_engagement(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request, allow_grain=False)
    params = filters["params"]
    result = client.analytics_report("engagement", params)
    table = _table(result, "surfaces")
    chart = {
        "type": "bar", "horizontal": True,
        "labels": [r["raw"].get("surface_label") for r in table["rows"]],
        "datasets": [
            {"label": "Share of active members (%)", "data": [_number(r["raw"], "reach") for r in table["rows"]]},
            {"label": "Repeat use (%)", "data": [_number(r["raw"], "repeat_rate") for r in table["rows"]]},
        ],
    }
    return render(request, "control_panel/analytics/engagement.html", _context(
        request, "analytics_engagement", filters, table=table, chart=chart,
        range=_range(result), error=_error(result), export_query=_export_query(params),
    ))


# ── Liquidity ─────────────────────────────────────────────────────────────────

@require_GET
def analytics_liquidity(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request, allow_grain=False, segments=("age_band", "account_age_band", "level_band"))
    params = filters["params"]
    result = client.analytics_report("liquidity", params)
    table = _table(result, "cities")
    top = [r for r in table["rows"] if _number(r["raw"], "active_members") is not None][:15]
    chart = {
        "type": "bar",
        "labels": [r["raw"].get("city") for r in top],
        "datasets": [
            {"label": "Women", "data": [_number(r["raw"], "women") for r in top]},
            {"label": "Men", "data": [_number(r["raw"], "men") for r in top]},
        ],
    }
    return render(request, "control_panel/analytics/liquidity.html", _context(
        request, "analytics_liquidity", filters, table=table, chart=chart,
        range=_range(result), error=_error(result), export_query=_export_query(params),
    ))


# ── Safety health ─────────────────────────────────────────────────────────────

@require_GET
def analytics_safety(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    filters = _filters(request, grain_default="week")
    params = filters["params"]
    result = client.analytics_report("safety", params)
    trend = _table(result, "trend")
    chart = {
        "type": "line",
        "labels": [r["raw"].get("period") for r in trend["rows"]],
        "datasets": [
            {"label": "Reports per 1,000 DAU", "data": [_number(r["raw"], "reports_per_1k_dau") for r in trend["rows"]]},
            {"label": "Blocks per 1,000 DAU", "data": [_number(r["raw"], "blocks_per_1k_dau") for r in trend["rows"]]},
        ],
    }
    return render(request, "control_panel/analytics/safety.html", _context(
        request, "analytics_safety", filters, trend=trend, queues=_table(result, "queues"),
        by_surface=_table(result, "by_surface"), chart=chart, range=_range(result), error=_error(result),
        export_trend=_export_query(params, table="trend"), export_queues=_export_query(params, table="queues"),
        export_surfaces=_export_query(params, table="by_surface"),
    ))


# ── Data freshness, rebuilds and test accounts ────────────────────────────────

@require_GET
def analytics_data(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    status = client.analytics_snapshots()
    accounts = client.analytics_excluded_accounts()
    status_data = status.data if status.ok and isinstance(status.data, dict) else {}
    accounts_data = accounts.data if accounts.ok and isinstance(accounts.data, dict) else {}
    return render(request, "control_panel/analytics/data.html", _context(
        request, "analytics_data", _filters(request, allow_grain=False),
        status=status_data, error=_error(status),
        accounts=accounts_data.get("accounts") or [],
        accounts_error="" if accounts.ok else ("Flagging test accounts is admin-only." if accounts.status_code == 403 else accounts.error),
    ))


@require_POST
def analytics_rebuild(request: HttpRequest) -> HttpResponse:
    from_day, to_day = _valid_day(request.POST.get("from", "")), _valid_day(request.POST.get("to", ""))
    if not from_day or not to_day:
        messages.error(request, "Choose a from and to day (YYYY-MM-DD).")
        return redirect("analytics_data")
    result = GoBFFClient().analytics_rebuild(from_day, to_day)
    if result.ok:
        messages.success(request, f"Rebuild of {from_day} → {to_day} started (run {result.data.get('run_id', '')}).")
    else:
        messages.error(request, "Only an admin can rebuild snapshots." if result.status_code == 403 else result.error)
    return redirect("analytics_data")


@require_POST
def analytics_exclude(request: HttpRequest) -> HttpResponse:
    member_id = (request.POST.get("member_id") or "").strip()
    reason = (request.POST.get("reason") or "").strip()
    if not _UUID.match(member_id) or not 3 <= len(reason) <= 200:
        messages.error(request, "Provide the member's id and a reason of 3 to 200 characters.")
        return redirect("analytics_data")
    result = GoBFFClient().analytics_exclude_account(member_id, reason)
    (messages.success if result.ok else messages.error)(
        request, "Account flagged as a test account. Rebuild past days to update daily rollups." if result.ok else result.error)
    return redirect("analytics_data")


@require_POST
def analytics_include(request: HttpRequest, member_id) -> HttpResponse:
    result = GoBFFClient().analytics_include_account(str(member_id))
    (messages.success if result.ok else messages.error)(request, "Test-account flag removed." if result.ok else result.error)
    return redirect("analytics_data")


# ── CSV export ────────────────────────────────────────────────────────────────

@require_GET
def analytics_export(request: HttpRequest, report: str) -> HttpResponse:
    if report not in REPORTS:
        return HttpResponse("Unknown report", status=404, content_type="text/plain")
    params = {key: request.GET[key] for key in EXPORT_PARAMS if request.GET.get(key)}
    response, error = GoBFFClient().analytics_report_csv(report, params)
    if response is None:
        messages.error(request, f"Export failed: {error}")
        return redirect(reverse("analytics_overview"))

    def stream():
        try:
            for chunk in response.iter_content(chunk_size=16384):
                if chunk:
                    yield chunk
        finally:
            response.close()

    out = StreamingHttpResponse(stream(), content_type="text/csv; charset=utf-8")
    out["Content-Disposition"] = response.headers.get("Content-Disposition") or f'attachment; filename="connect_{report}.csv"'
    out["Cache-Control"] = "no-store"
    return out


# ── Dashboard tiles ───────────────────────────────────────────────────────────

def durable_dashboard_kpis(client) -> dict:
    """KPI tiles for the command center from the durable snapshots, or an
    explicit unavailable state (never a zero) when they cannot be read."""
    try:
        result = client.analytics_report("kpis", {})
    except Exception:  # noqa: BLE001 - the dashboard must render regardless
        return {"available": False, "tiles": {}, "error": "Analytics are unavailable."}
    data = result.data if getattr(result, "ok", False) is True and isinstance(getattr(result, "data", None), dict) else None
    if data is None:
        status = getattr(result, "status_code", 0)
        return {"available": False, "tiles": {}, "error": "Requires the analyst or admin role." if status == 403 else "Analytics are unavailable."}
    tiles = {}
    for row in ((data.get("tables") or {}).get("tiles") or {}).get("rows") or []:
        if isinstance(row, dict) and row.get("key"):
            suppressed = set(row.get("suppressed") or [])
            column = {"unit": "%" if row.get("unit") == "%" else ""}
            tiles[row["key"]] = {
                "label": row.get("label"), "unit": row.get("unit"), "definition": row.get("definition"),
                "value": _format(row.get("value"), column, "value" in suppressed),
                "previous": _format(row.get("previous"), column, "previous" in suppressed),
            }
    as_of = ((data.get("meta") or {}) if isinstance(data.get("meta"), dict) else {}).get("as_of") or data.get("to", "")
    return {"available": True, "tiles": tiles, "as_of": as_of, "error": ""}
