"""Server activity and consumption: what the servers did and what they used.

Go records it durably (backend M/admin_system.go, migration 133):
- server events: process start/stop, panics, 5xx, refused requests
  (401/403/429, timeouts), worker failures and staleness, retention passes;
- background job runs (every worker);
- hourly request rollups (every request, including refused ones);
- hourly capacity snapshots (database, tables, media, disk);
- daily third-party usage.

Roles: admin and ops_admin read everything; analysts read traffic, capacity
and third-party usage. Go enforces it; the sidebar mirrors it.
"""
from __future__ import annotations

import re

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_GET

from . import listing
from .services.go_client import GoBFFClient
from .views import _base_context

_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
C = listing.Column

TABS = (
    ("system_events", "Events", "bi-journal-text"),
    ("system_jobs", "Background jobs", "bi-gear-wide-connected"),
    ("system_requests", "API traffic", "bi-speedometer"),
    ("system_capacity", "Capacity", "bi-database"),
    ("system_third_party", "Third-party usage", "bi-plug"),
)

KINDS = (("process_start", "Process start"), ("process_stop", "Process stop"), ("panic", "Panic"),
         ("server_error", "Server error (5xx)"), ("refused", "Refused request"), ("worker_failed", "Worker failed"),
         ("worker_stale", "Worker stale"), ("retention_summary", "Retention pass"), ("migration_applied", "Migration"))
SEVERITIES = (("critical", "Critical"), ("error", "Error"), ("warning", "Warning"), ("info", "Info"))


def _context(active: str, **extra) -> dict:
    ctx = _base_context()
    ctx.update({"system_tabs": [{"url_name": u, "label": l, "icon": i, "active": u == active} for u, l, i in TABS]})
    ctx.update(extra)
    return ctx


def _dates(request: HttpRequest) -> dict[str, str]:
    return {k: v for k in ("from", "to") if _DATE.match(v := request.GET.get(k, "").strip())}


def _details(row: dict) -> str:
    d = row.get("details")
    return ", ".join(f"{k}: {v}" for k, v in sorted(d.items())) if isinstance(d, dict) else ""


EVENT_LIST = listing.ListSpec(
    name="server-events", search_label="Search message or route", default_page_size=50,
    filters=(
        listing.Filter("kind", "Kind", KINDS),
        listing.Filter("severity", "Severity", SEVERITIES),
        listing.Filter("service", "Service", kind="text", max_length=60),
        listing.Filter("from", "From (UTC)", kind="date"),
        listing.Filter("to", "To (UTC)", kind="date"),
    ),
    columns=(
        C("at", "Time (UTC)", width=22), C("kind", "Kind", width=16), C("severity", "Severity", width=10),
        C("service", "Service", width=14), C("instance", "Instance", width=18), C("message", "Message", width=50),
        C("route", "Route", width=30), C("count", "Count", width=8), C("first_at", "First (UTC)", width=22),
        C("last_at", "Last (UTC)", width=22), C("correlation_id", "Correlation ID", width=38),
        C("details", "Details", _details, width=60),
    ),
)

RUN_LIST = listing.ListSpec(
    name="job-runs", search_label="Search error", default_page_size=50,
    filters=(
        listing.Filter("worker", "Worker", kind="text", max_length=60),
        listing.Filter("status", "Status", (("succeeded", "Succeeded"), ("failed", "Failed"), ("skipped", "Skipped"), ("busy", "Busy"))),
        listing.Filter("from", "From (UTC)", kind="date"),
        listing.Filter("to", "To (UTC)", kind="date"),
    ),
    columns=(
        C("worker", "Worker", width=22), C("status", "Status", width=10), C("started_at", "Started (UTC)", width=22),
        C("finished_at", "Finished (UTC)", width=22), C("duration_ms", "Duration (ms)", width=12),
        C("items_processed", "Items", width=8), C("items_failed", "Failed items", width=10),
        C("backlog_after", "Backlog after", width=10), C("instance", "Instance", width=18), C("error", "Error", width=50),
        C("details", "Details", _details, width=50),
    ),
)


@require_GET
def system_events(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    return listing.simple_view(request, EVENT_LIST, client.system_events, items_key="events",
                               template="control_panel/system/events.html", title="Server events",
                               base_context=lambda: _context("system_events"), context_name="events")


@require_GET
def system_jobs(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    jobs = client.system_jobs()

    def extra(page: listing.Page, data: dict) -> dict:
        workers = [w for w in (jobs.data.get("workers") or []) if isinstance(w, dict)] if jobs.ok else []
        return {"workers": workers, "jobs_error": "" if jobs.ok else jobs.error,
                "stale_count": sum(1 for w in workers if w.get("stale")),
                "failing_count": sum(1 for w in workers if (w.get("failures_24h") or 0) > 0)}

    return listing.simple_view(request, RUN_LIST, client.system_job_runs, items_key="runs",
                               template="control_panel/system/jobs.html", title="Background job runs",
                               base_context=lambda: _context("system_jobs"), context_name="runs", extra=extra)


GROUPS = (("none", "Overall"), ("route", "Route"), ("status_class", "Status class"), ("method", "Method"), ("service", "Service"))


@require_GET
def system_requests(request: HttpRequest) -> HttpResponse:
    g = request.GET
    params = _dates(request)
    params["grain"] = g.get("grain") if g.get("grain") in ("hour", "day") else "hour"
    params["group_by"] = g.get("group_by") if g.get("group_by") in dict(GROUPS) else "none"
    for key in ("route", "method", "service"):
        if (value := g.get(key, "").strip()[:120]):
            params[key] = value
    if g.get("status_class") in ("2xx", "3xx", "4xx", "5xx"):
        params["status_class"] = g["status_class"]
    result = GoBFFClient().system_requests(**params)
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    rows = [r for r in data.get("rows") or [] if isinstance(r, dict)]
    chart = None
    if rows and params["group_by"] == "none":
        chart = {"kind": "line", "title": "Requests, server errors and p95 latency",
                 "labels": [str(r.get("bucket") or "")[:16].replace("T", " ") for r in rows],
                 "datasets": [{"label": "Requests", "data": [r.get("requests") for r in rows]},
                              {"label": "Server errors (5xx)", "data": [r.get("server_errors") for r in rows]},
                              {"label": "Refused", "data": [r.get("refused") for r in rows]},
                              {"label": "p95 ms", "data": [r.get("p95_ms") for r in rows]}]}
    return render(request, "control_panel/system/requests.html", _context(
        "system_requests", rows=rows, totals=data.get("totals") or {}, chart=chart, params=params,
        groups=GROUPS, error="" if result.ok else result.error, denied=result.status_code == 403))


@require_GET
def system_capacity(request: HttpRequest) -> HttpResponse:
    result = GoBFFClient().system_capacity(**_dates(request))
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    series = [s for s in data.get("series") or [] if isinstance(s, dict)]
    chart = None
    if series:
        mb = lambda v: round(v / 1_048_576, 1) if isinstance(v, (int, float)) else None  # noqa: E731
        chart = {"kind": "line", "title": "Database and media size (MB)",
                 "labels": [str(s.get("at") or "")[:16].replace("T", " ") for s in series],
                 "datasets": [{"label": "Database MB", "data": [mb(s.get("db_size_bytes")) for s in series]},
                              {"label": "Media MB", "data": [mb(s.get("media_bytes_total")) for s in series]}]}
    latest = data.get("latest") if isinstance(data.get("latest"), dict) else {}
    media = latest.get("media_bytes") if isinstance(latest.get("media_bytes"), dict) else {}
    return render(request, "control_panel/system/capacity.html", _context(
        "system_capacity", latest=latest, media=sorted(media.items(), key=lambda kv: -(kv[1] or 0)),
        tables=[t for t in data.get("tables") or [] if isinstance(t, dict)], chart=chart,
        dates=_dates(request), error="" if result.ok else result.error, denied=result.status_code == 403))


@require_GET
def system_third_party(request: HttpRequest) -> HttpResponse:
    result = GoBFFClient().system_third_party(**_dates(request))
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    return render(request, "control_panel/system/third_party.html", _context(
        "system_third_party", rows=[r for r in data.get("rows") or [] if isinstance(r, dict)],
        totals=[t for t in data.get("totals") or [] if isinstance(t, dict)], dates=_dates(request),
        error="" if result.ok else result.error, denied=result.status_code == 403))
