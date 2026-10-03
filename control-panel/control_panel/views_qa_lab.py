"""QA Lab: test runs, case coverage and the coverage gate, read from the
files QA Lab writes (control_panel/qa_lab.py). Read-only: runs are started
in QA Lab itself (QA_LAB_URL), never from the console.

Only when ``QA_LAB_ENABLED`` (unset: DEBUG); otherwise every page is a 404
and the sidebar has no entry. Admin, ops_admin and analyst may read; any
other or unknown role gets a 403 page.

The lists use the console's listing engine (paging, search, filters, Excel
export). Their rows come from local JSON files, not Go, so the fetch
functions here filter and page in Python; the total, the page and the export
still come from the same filtered list, so they always agree.
"""
from __future__ import annotations

from dataclasses import replace
from functools import wraps

from django.http import Http404, HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET

from . import listing, qa_lab
from .operator_access import stored_roles
from .views import _base_context

C = listing.Column

TABS = (
    ("qa_lab", "Overview", "bi-speedometer2"),
    ("qa_lab_runs", "Runs", "bi-play-circle"),
    ("qa_lab_cases", "Cases", "bi-list-check"),
)


def _context(active: str, **extra) -> dict:
    ctx = _base_context()
    ctx.update({"qa_tabs": [{"url_name": u, "label": l, "icon": i, "active": u == active} for u, l, i in TABS],
                "qa_lab_url": qa_lab.qa_lab_url()})
    ctx.update(extra)
    return ctx


def qa_lab_page(view):
    """404 unless QA Lab is enabled; 403 page unless the role may read it."""

    @wraps(view)
    def wrapped(request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not qa_lab.enabled():
            raise Http404("QA Lab is not enabled on this console.")
        if not qa_lab.role_allowed(stored_roles(getattr(request, "session", None))):
            return render(request, "control_panel/qa_lab/denied.html", _context("", denied=True), status=403)
        return view(request, *args, **kwargs)

    return wrapped


def _local_fetch(rows: list[dict], keep):
    """A listing fetch over an in-memory list: filter with ``keep(row,
    query)``, then page. Problems are shown by the page, not as a list error."""

    def fetch(query: listing.ListQuery, limit: int, offset: int):
        matched = [r for r in rows if keep(r, query)]
        return matched[offset:offset + limit], len(matched), ""

    return fetch


def _get(*path):
    def value(row: dict):
        cur = row
        for key in path:
            cur = cur.get(key) if isinstance(cur, dict) else None
        return cur
    return value


# ── Overview ──────────────────────────────────────────────────────────────

@require_GET
@qa_lab_page
def qa_lab_overview(request: HttpRequest) -> HttpResponse:
    return render(request, "control_panel/qa_lab/overview.html", _context("qa_lab", **qa_lab.overview()))


# ── Runs ──────────────────────────────────────────────────────────────────

RUN_LIST = listing.ListSpec(
    name="qa-lab-runs", search_label="Search run id, operator or suite", default_page_size=25,
    filters=(
        listing.Filter("status", "Status", qa_lab.RUN_STATUSES),
        listing.Filter("mode", "Mode", qa_lab.RUN_MODES),
    ),
    columns=(
        C("id", "Run", width=22), C("status", "Status", width=10), C("mode", "Mode", width=10), C("by", "By", width=20),
        C("startedAt", "Started (UTC)", width=22), C("finishedAt", "Finished (UTC)", width=22),
        C("duration", "Took", width=10), C("suites", "Suites", width=36),
        C("tests_total", "Tests", _get("tests", "total"), width=8),
        C("tests_passed", "Tests passed", _get("tests", "passed"), width=10),
        C("tests_failed", "Tests failed", _get("tests", "failed"), width=10),
        C("tests_skipped", "Tests skipped", _get("tests", "skipped"), width=10),
        C("cases_in_scope", "Cases in scope", _get("cases", "inScope"), width=10),
        C("cases_pass", "Cases pass", _get("cases", "pass"), width=10),
        C("cases_fail", "Cases fail", _get("cases", "fail"), width=10),
        C("cases_skipped", "Cases skipped", _get("cases", "skipped"), width=10),
        C("cases_not_run", "Cases not run", _get("cases", "notRun"), width=10),
        C("cases_unmatched", "Cases unmatched", _get("cases", "unmatched"), width=10),
        C("automated_pct", "Automated %", _get("coverage", "automatedPct"), width=11),
        C("verified_pct", "Verified %", _get("coverage", "verifiedPct"), width=10),
    ),
)


def _keep_run(row: dict, query: listing.ListQuery) -> bool:
    f = query.filters
    if f.get("status") and row.get("status") != f["status"]:
        return False
    if f.get("mode") and row.get("mode") != f["mode"]:
        return False
    return qa_lab.match(row, query.q) if query.q else True


@require_GET
@qa_lab_page
def qa_lab_runs(request: HttpRequest) -> HttpResponse:
    rows, problems = qa_lab.run_rows()

    def render_page(page: listing.Page) -> HttpResponse:
        ctx = _context("qa_lab_runs", runs=page.rows, total=page.total, error=page.error, problems=problems,
                       has_history=bool(rows))
        ctx.update(listing.context(page))
        return render(request, "control_panel/qa_lab/runs.html", ctx)

    return listing.respond(request, RUN_LIST, _local_fetch(rows, _keep_run), title="QA Lab runs", render_page=render_page)


@require_GET
@qa_lab_page
def qa_lab_run_detail(request: HttpRequest, run_id: str) -> HttpResponse:
    if run_id == "latest":  # a stable link to the newest run
        runs, _ = qa_lab.run_index()
        if not runs:
            raise Http404("No QA Lab runs yet.")
        return redirect("qa_lab_run_detail", run_id=runs[0]["id"])
    detail = qa_lab.run_detail(run_id)
    if detail is None:
        raise Http404("No such QA Lab run.")
    return render(request, "control_panel/qa_lab/run_detail.html", _context("qa_lab_runs", run_id=run_id, **detail))


# ── Cases ─────────────────────────────────────────────────────────────────

# Area and kind choices come from the catalog at request time (_case_spec).
CASE_LIST = listing.ListSpec(
    name="qa-lab-cases", search_label="Search case, title, screen or test", default_page_size=50,
    filters=(
        listing.Filter("area", "Area", ()),
        listing.Filter("result", "Result", qa_lab.RESULTS),
        listing.Filter("kind", "Kind", ()),
        listing.Filter("reason", "Gap reason", ()),
    ),
    columns=(
        C("id", "Case", width=60), C("title", "Title", width=60), C("area", "Area", width=24),
        C("feature", "Feature", width=36), C("screen", "Screen", width=28), C("kind", "Kind", width=10),
        C("result", "Result", lambda r: qa_lab.RESULT_LABELS.get(r.get("result"), r.get("result")), width=12),
        C("ok", "Verified (gate)", width=12), C("reason", "Gap reason", lambda r: r.get("reason_label") or "", width=40),
        C("tests", "Tests", width=8), C("last_run", "Last run", width=22), C("last_at", "Last result (UTC)", width=22),
    ),
)


def _case_spec(ev: qa_lab.Evaluation) -> listing.ListSpec:
    areas = tuple((a, a) for a in sorted({r["area"] for r in ev.rows if r["area"]}))
    kinds = tuple((k, k.replace("_", " ").capitalize()) for k in sorted({r["kind"] for r in ev.rows if r["kind"]}))
    reasons = tuple((k, label) for k, label in ev.reasons.items())
    choices = {"area": areas, "kind": kinds, "reason": reasons}
    return replace(CASE_LIST, filters=tuple(replace(f, choices=choices[f.name]) if f.name in choices else f
                                            for f in CASE_LIST.filters))


def _keep_case(row: dict, query: listing.ListQuery) -> bool:
    f = query.filters
    for key in ("area", "result", "kind", "reason"):
        if f.get(key) and row.get(key) != f[key]:
            return False
    return qa_lab.match(row, query.q) if query.q else True


@require_GET
@qa_lab_page
def qa_lab_cases(request: HttpRequest) -> HttpResponse:
    ev = qa_lab.evaluate()
    spec = _case_spec(ev)

    def render_page(page: listing.Page) -> HttpResponse:
        ctx = _context("qa_lab_cases", cases=page.rows, total=page.total, error=page.error,
                       problems=list(ev.problems.items), has_catalog=bool(ev.rows), reasons=ev.reasons,
                       result_labels=qa_lab.RESULT_LABELS)
        ctx.update(listing.context(page))
        return render(request, "control_panel/qa_lab/cases.html", ctx)

    return listing.respond(request, spec, _local_fetch(ev.rows, _keep_case), title="QA Lab cases", render_page=render_page)


@require_GET
@qa_lab_page
def qa_lab_case_detail(request: HttpRequest, case_id: str) -> HttpResponse:
    detail = qa_lab.case_detail(case_id)
    if detail is None:
        raise Http404("No such catalog case.")
    return render(request, "control_panel/qa_lab/case_detail.html",
                  _context("qa_lab_cases", case_id=case_id, result_labels=qa_lab.RESULT_LABELS, **detail))
