"""Report server pages: the catalog (/reports/) and the report viewer
(/reports/<id>/) with Excel, CSV and PDF export.

Roles: Go enforces every read (a 403 shows as "not available to your role");
the catalog hides reports the operator's stored roles cannot read.
"""
from __future__ import annotations

from django.http import Http404, HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_GET

from .operator_access import can_access_admin_route, stored_roles
from .reports import exporters
from .reports.catalog import BY_ID, CATEGORIES, REPORTS
from .reports.engine import read_params, run
from .views import _base_context


def _visible(request: HttpRequest):
    roles = stored_roles(request.session)
    return [r for r in REPORTS if roles is None or can_access_admin_route(roles, "GET", r.admin_path)]


@require_GET
def report_catalog(request: HttpRequest) -> HttpResponse:
    q = request.GET.get("q", "").strip()[:100]
    reports = _visible(request)
    if q:
        needle = q.lower()
        reports = [r for r in reports if needle in " ".join((r.title, r.description, r.category, *r.keywords)).lower()]
    context = _base_context()
    context.update({
        "q": q,
        "sections": [{"name": c, "reports": [r for r in reports if r.category == c]} for c in CATEGORIES],
        "count": len(reports),
    })
    return render(request, "control_panel/reports/catalog.html", context)


@require_GET
def report_view(request: HttpRequest, report_id: str) -> HttpResponse:
    report = BY_ID.get(report_id)
    if report is None:
        raise Http404("No such report")
    params = read_params(report, request.GET)
    # Per-dataset "Group by" choices: group_<dataset>=field (repeatable).
    overrides = {}
    for ds in report.datasets:
        key = f"group_{ds.key}"
        if key in request.GET:
            overrides[ds.key] = tuple(v for v in request.GET.getlist(key) if v)
    result = run(report, params, group_overrides=overrides)

    export = request.GET.get("export", "")
    if export == "xlsx":
        return exporters.xlsx(result)
    if export == "pdf":
        return exporters.pdf(result)
    if export == "csv":
        wanted = request.GET.get("dataset", "")
        for ds in result.datasets:
            if ds.spec.key == wanted:
                return exporters.csv_dataset(result, ds)
        raise Http404("No such dataset")

    query = request.GET.copy()
    for key in ("export", "dataset"):
        query.pop(key, None)
    base_query = query.urlencode()
    datasets = []
    for ds in result.datasets:
        offered = [f for f in ds.fields if f.key in (set(ds.spec.groupable) | set(ds.spec.group_by))]
        datasets.append({
            "result": ds,
            "group_options": [{"key": f.key, "label": f.label, "selected": f.key in ds.group_by} for f in offered],
            "chart": ds.chart,
            "chart_id": f"chart-{ds.spec.key}",
            "csv_url": f"?{base_query + '&' if base_query else ''}export=csv&dataset={ds.spec.key}",
        })
    context = _base_context()
    context.update({
        "report": report,
        "result": result,
        "params": [{"spec": p, "value": params.get(p.name, "")} for p in report.params],
        "datasets": datasets,
        "export_base": f"?{base_query + '&' if base_query else ''}export=",
        "share_query": base_query,
    })
    status = 403 if result.denied else 200
    return render(request, "control_panel/reports/view.html", context, status=status)
