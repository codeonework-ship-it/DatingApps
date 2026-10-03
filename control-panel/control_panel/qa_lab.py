"""QA Lab results for the console: read-only views of what QA Lab wrote.

QA Lab (``website/qa-lab``, mounted with ``QA_LAB=1``, never in production)
runs the suites and writes everything to disk under ``QA_LAB_RESULTS_DIR``
(default ``<repo>/qa/results/qa_lab``):

* ``runs/index.json``: run history, newest first;
* ``runs/<id>/run.json``, ``cases.json``, ``results.json``, ``diff.json``;
* ``ledger.json``: the latest executed result per case across runs;
* ``manual_checks.json``: append-only manual checklist marks.

The catalog is ``qa/catalog/feature_catalog.json`` (``QA_LAB_CATALOG_PATH``).
Whether a case is *verified*, and why not, comes from QA Lab's own coverage
gate (``qa/lab/coverage_gate.py``, loaded from ``QA_LAB_GATE_PATH``), so the
console and the gate can never disagree.

Every read is defensive: a missing file is an empty state, a corrupt or
wrongly shaped file is a warning, never a 500. Run ids are checked against
QA Lab's id format before any path is built, so a URL cannot reach outside
the runs directory. Runs are started in QA Lab itself; nothing here writes.

The section exists only when ``QA_LAB_ENABLED`` (unset: follows ``DEBUG``)
and only for the admin, ops_admin and analyst roles (a read-only page, like
Client errors). There is no Go route behind it, so the console enforces the
role itself and refuses operators whose roles are unknown.
"""
from __future__ import annotations

import collections
import importlib.util
import json
import re
import threading
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from django.conf import settings

RUN_ID_RE = re.compile(r"^\d{8}-\d{6}-[0-9a-f]{4}$")
CASE_ID_RE = re.compile(r"^[A-Za-z0-9_.\-]{1,200}$")
ALLOWED_ROLES = frozenset({"admin", "ops_admin", "analyst"})

RUN_STATUSES = (("passed", "Passed"), ("failed", "Failed"), ("running", "Running"),
                ("cancelled", "Cancelled"), ("error", "Error"))
RUN_MODES = (("all", "All suites"), ("area", "Area"), ("features", "Features"), ("cases", "Selected cases"),
             ("tags", "Tags"))
RESULTS = (("pass", "Pass"), ("fail", "Fail"), ("not_run", "Not run"), ("skipped", "Skipped"),
           ("manual", "Manual"), ("not_automated", "Not automated"))
RESULT_LABELS = dict(RESULTS)

# Used only when the gate script cannot be loaded (QA_LAB_GATE_PATH missing).
_FALLBACK_REASONS = {
    "fail": "automated, latest result FAILED",
    "not_run": "automated, never run in QA Lab (or not in the selected run)",
    "skipped": "automated, latest result skipped / xfail",
    "manual_unchecked": "manual, not checked yet",
    "manual_fail": "manual, last check FAILED",
    "not_automated": "not automated and not listed as manual",
}
DETAIL_LIST_CAP = 200
HISTORY_RUNS = 5
_MAX_FILE_BYTES = 200 * 1024 * 1024


# ── settings and access ───────────────────────────────────────────────────

def enabled() -> bool:
    value = getattr(settings, "QA_LAB_ENABLED", None)
    return bool(settings.DEBUG) if value is None else bool(value)


def role_allowed(roles: Iterable[str] | None) -> bool:
    """Admin, ops_admin and analyst may read. Unknown roles (None) are
    refused: no Go route stands behind these pages to refuse for us."""
    return roles is not None and bool(set(roles) & ALLOWED_ROLES)


def visible(roles: Iterable[str] | None) -> bool:
    return enabled() and role_allowed(roles)


def _repo() -> Path:
    return Path(settings.BASE_DIR).resolve().parent


def _setting_path(name: str, default: Path) -> Path:
    value = getattr(settings, name, None)
    return Path(value) if value else default


def results_dir() -> Path:
    return _setting_path("QA_LAB_RESULTS_DIR", _repo() / "qa" / "results" / "qa_lab")


def catalog_path() -> Path:
    return _setting_path("QA_LAB_CATALOG_PATH", _repo() / "qa" / "catalog" / "feature_catalog.json")


def manual_cases_path() -> Path:
    return _setting_path("QA_LAB_MANUAL_CASES_PATH", _repo() / "qa" / "catalog" / "manual_cases.json")


def gate_path() -> Path:
    return _setting_path("QA_LAB_GATE_PATH", _repo() / "qa" / "lab" / "coverage_gate.py")


def qa_lab_url() -> str:
    return str(getattr(settings, "QA_LAB_URL", "") or "http://127.0.0.1:4190/qa-lab/")


def valid_run_id(run_id: str) -> bool:
    return bool(RUN_ID_RE.match(run_id or ""))


def valid_case_id(case_id: str) -> bool:
    return bool(CASE_ID_RE.match(case_id or ""))


# ── defensive, cached JSON reads ──────────────────────────────────────────

_CORRUPT = object()
_CACHE_SIZE = 16
_cache: "collections.OrderedDict[str, tuple[tuple[int, int], Any]]" = collections.OrderedDict()
_lock = threading.Lock()


def _signature(path: Path) -> tuple[int, int] | None:
    try:
        st = path.stat()
    except OSError:
        return None
    return (st.st_mtime_ns, st.st_size) if path.is_file() else None


def read_json(path: Path, expect: type | tuple[type, ...]) -> tuple[Any, str]:
    """``(data, problem)``: problem is "" (ok), "missing" or "corrupt"
    (unreadable, not JSON, or not the expected top-level type)."""
    sig = _signature(path)
    if sig is None:
        return None, "missing"
    key = str(path)
    with _lock:
        hit = _cache.get(key)
        if hit is not None and hit[0] == sig:
            _cache.move_to_end(key)
            data = hit[1]
        else:
            hit = None
    if hit is None:
        try:
            if sig[1] > _MAX_FILE_BYTES:
                raise ValueError("file too large")
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError, UnicodeDecodeError):
            data = _CORRUPT
        with _lock:
            _cache[key] = (sig, data)
            _cache.move_to_end(key)
            while len(_cache) > _CACHE_SIZE:
                _cache.popitem(last=False)
    if data is _CORRUPT or not isinstance(data, expect):
        return None, "corrupt"
    return data, ""


def clear_cache() -> None:
    with _lock:
        _cache.clear()
        _evaluation.clear()
        _gate.clear()


def _dict(value: Any) -> dict:
    return value if isinstance(value, dict) else {}


def _list(value: Any) -> list:
    return value if isinstance(value, list) else []


def _num(value: Any) -> int | float | None:
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def parse_time(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def duration(start: Any, end: Any) -> str:
    a, b = parse_time(start), parse_time(end)
    if not a or not b or b < a:
        return ""
    seconds = int((b - a).total_seconds())
    hours, rest = divmod(seconds, 3600)
    minutes, secs = divmod(rest, 60)
    if hours:
        return f"{hours}h {minutes:02d}m"
    if minutes:
        return f"{minutes}m {secs:02d}s"
    return f"{secs}s"


# ── data sources ──────────────────────────────────────────────────────────

@dataclass
class Problems:
    """Friendly notes about missing or unreadable inputs, for the page."""

    items: list[str] = field(default_factory=list)

    def note(self, what: str, path: Path, problem: str) -> None:
        if problem == "missing":
            self.items.append(f"{what} not found yet ({path.name}).")
        elif problem == "corrupt":
            self.items.append(f"{what} could not be read ({path.name} is not valid QA Lab JSON); it is shown as empty.")


@dataclass
class Catalog:
    generated: str
    features: list[dict]
    cases: dict[str, tuple[dict, dict]]  # case id -> (feature, case)
    problem: str = ""


def catalog() -> Catalog:
    data, problem = read_json(catalog_path(), dict)
    features = [f for f in _list(_dict(data).get("features")) if isinstance(f, dict)]
    cases: dict[str, tuple[dict, dict]] = {}
    for f in features:
        for c in _list(f.get("cases")):
            if isinstance(c, dict) and isinstance(c.get("id"), str):
                cases[c["id"]] = (f, c)
    if data is not None and not features:
        problem = "corrupt"
    return Catalog(generated=str(_dict(data).get("generated") or ""), features=features, cases=cases, problem=problem)


def run_index() -> tuple[list[dict], str]:
    data, problem = read_json(results_dir() / "runs" / "index.json", list)
    rows = [r for r in _list(data) if isinstance(r, dict) and valid_run_id(str(r.get("id") or ""))]
    return rows, problem


def ledger() -> tuple[dict, str]:
    data, problem = read_json(results_dir() / "ledger.json", dict)
    return {k: v for k, v in _dict(data).items() if isinstance(v, dict)}, problem


def manual_marks() -> tuple[dict, str]:
    """Latest manual checklist mark per case (the file is append-only)."""
    data, problem = read_json(results_dir() / "manual_checks.json", dict)
    marks = {k: v[-1] for k, v in _dict(data).items() if isinstance(v, list) and v and isinstance(v[-1], dict)}
    return marks, problem


def manual_cases() -> dict:
    data, _ = read_json(manual_cases_path(), dict)
    return _dict(data)


def run_dir(run_id: str) -> Path | None:
    """The run's directory, or None for an invalid id or a run that does not exist."""
    if not valid_run_id(run_id):
        return None
    path = results_dir() / "runs" / run_id
    return path if path.is_dir() else None


def run_file(run_id: str, name: str, expect: type) -> tuple[Any, str]:
    path = run_dir(run_id)
    if path is None:
        return None, "missing"
    return read_json(path / name, expect)


# ── the coverage gate (qa/lab/coverage_gate.py) ───────────────────────────

_gate: dict[str, Any] = {}


def gate_module():
    """QA Lab's coverage gate module, or None when it cannot be loaded."""
    path = gate_path()
    sig = _signature(path)
    if sig is None:
        return None
    with _lock:
        if _gate.get("sig") == sig:
            return _gate.get("module")
    module = None
    try:
        spec = importlib.util.spec_from_file_location("qa_lab_coverage_gate", path)
        if spec and spec.loader:
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            if not callable(getattr(module, "evaluate", None)) or not isinstance(getattr(module, "REASONS", None), dict):
                module = None
    except Exception:  # noqa: BLE001 - a broken script must not break the console
        module = None
    with _lock:
        _gate.update({"sig": sig, "module": module})
    return module


def reasons() -> dict[str, str]:
    module = gate_module()
    return dict(module.REASONS) if module else dict(_FALLBACK_REASONS)


def _is_automated(case: dict, led: dict) -> bool:
    # The gate's own definition (coverage_gate.evaluate).
    return case.get("status") == "automated" or led.get("via") == "tag"


def _fallback_rows(cat: Catalog, led: dict, marks: dict, manual: dict) -> list[dict]:
    """Ledger-only evaluation when the gate script is unavailable."""
    manual_ids = {k for k in manual if not k.startswith("_")}
    rows = []
    for f in cat.features:
        for c in _list(f.get("cases")):
            if not isinstance(c, dict) or not isinstance(c.get("id"), str):
                continue
            entry = _dict(led.get(c["id"]))
            if _is_automated(c, entry):
                result = entry.get("result")
                reason = None if result == "pass" else ("fail" if result == "fail" else ("skipped" if result == "skipped" else "not_run"))
            elif c.get("status") == "manual" or c["id"] in manual_ids:
                mark = _dict(marks.get(c["id"])).get("result")
                reason = None if mark == "pass" else ("manual_fail" if mark == "fail" else "manual_unchecked")
            else:
                reason = "not_automated"
            rows.append({"id": c["id"], "area": f.get("area"), "feature": f.get("id"), "ok": reason is None, "reason": reason})
    return rows


def _result(reason: str | None, automated: bool) -> str:
    if reason is None:
        return "pass" if automated else "manual"
    if reason in ("fail", "not_run", "skipped"):
        return reason
    if reason == "stale":
        return "not_run"
    if reason in ("manual_unchecked", "manual_fail"):
        return "manual"
    return "not_automated"


_evaluation: dict[str, Any] = {}


@dataclass
class Evaluation:
    rows: list[dict]  # one per catalog case, in catalog order
    by_id: dict[str, dict]
    reasons: dict[str, str]
    gate_loaded: bool
    catalog: Catalog
    problems: Problems


def evaluate() -> Evaluation:
    """Every catalog case with its result, verified flag and gap reason."""
    paths = (catalog_path(), results_dir() / "ledger.json", results_dir() / "manual_checks.json",
             manual_cases_path(), gate_path())
    key = tuple((str(p), _signature(p)) for p in paths)
    with _lock:
        if _evaluation.get("key") == key:
            return _evaluation["value"]
    problems = Problems()
    cat = catalog()
    problems.note("The case catalog", catalog_path(), cat.problem)
    led, led_problem = ledger()
    problems.note("The results ledger", results_dir() / "ledger.json", led_problem)
    marks, marks_problem = manual_marks()
    if marks_problem == "corrupt":
        problems.note("Manual checks", results_dir() / "manual_checks.json", marks_problem)
    manual = manual_cases()
    module = gate_module()
    gate_rows: list[dict] | None = None
    if module is not None:
        try:
            gate_catalog = {"features": cat.features}
            gate_rows = [r for r in module.evaluate(gate_catalog, manual, led, marks) if isinstance(r, dict)]
        except Exception:  # noqa: BLE001
            gate_rows = None
    if gate_rows is None:
        if cat.features:
            problems.items.append("The coverage gate (qa/lab/coverage_gate.py) could not be loaded; results come from the ledger alone.")
        gate_rows = _fallback_rows(cat, led, marks, manual)
    gate_reasons = reasons()
    rows = []
    for g in gate_rows:
        cid = g.get("id")
        if cid not in cat.cases:
            continue
        feature, case = cat.cases[cid]
        entry = _dict(led.get(cid))
        automated = _is_automated(case, entry)
        refs = [a for a in _list(case.get("automated_by")) if isinstance(a, dict)]
        rows.append({
            "id": cid, "linkable": valid_case_id(cid), "title": str(case.get("title") or ""), "area": str(feature.get("area") or ""),
            "feature": str(feature.get("id") or ""), "screen": str(feature.get("screen") or ""),
            "kind": str(case.get("type") or ""), "status": str(case.get("status") or ""),
            "automated": automated, "ok": bool(g.get("ok")), "reason": g.get("reason") or "",
            "reason_label": gate_reasons.get(g.get("reason") or "", g.get("reason") or ""),
            "result": _result(g.get("reason"), automated),
            "tests": _num(case.get("automated_by_total")) or len(refs),
            "last_run": str(entry.get("run") or ""), "last_at": str(entry.get("at") or ""),
            "_search": " ".join([cid, str(case.get("title") or ""), str(feature.get("screen") or ""),
                                 str(feature.get("id") or "")] + [f"{a.get('file', '')} {a.get('test', '')}" for a in refs]).lower(),
        })
    value = Evaluation(rows=rows, by_id={r["id"]: r for r in rows}, reasons=gate_reasons, gate_loaded=module is not None,
                       catalog=cat, problems=problems)
    with _lock:
        _evaluation.update({"key": key, "value": value})
    return value


# ── page data ─────────────────────────────────────────────────────────────

def _pct(part: int, total: int) -> float:
    return round(100 * part / total, 1) if total else 0.0


def overview() -> dict:
    ev = evaluate()
    rows = ev.rows
    total = len(rows)
    counts = collections.Counter(r["result"] for r in rows)
    automated = sum(1 for r in rows if r["automated"])
    verified = sum(1 for r in rows if r["ok"])
    breakdown = [{"key": k, "label": label, "count": counts.get(k, 0), "pct": _pct(counts.get(k, 0), total)}
                 for k, label in RESULTS if counts.get(k, 0)]
    areas: dict[str, dict] = {}
    for r in rows:
        a = areas.setdefault(r["area"], {"area": r["area"], "cases": 0, "pass": 0, "fail": 0, "not_run": 0, "gaps": 0, "verified": 0})
        a["cases"] += 1
        a["pass"] += r["result"] == "pass"
        a["fail"] += r["result"] == "fail"
        a["not_run"] += r["result"] in ("not_run", "skipped")
        a["gaps"] += not r["ok"]
        a["verified"] += r["ok"]
    by_area = sorted(areas.values(), key=lambda a: (-a["gaps"], -a["fail"], a["area"]))
    for a in by_area:
        a["verified_pct"] = _pct(a["verified"], a["cases"])
    gaps_by_reason = collections.defaultdict(list)
    for r in rows:
        if not r["ok"]:
            gaps_by_reason[r["reason"]].append(r)
    gaps = []
    order = list(ev.reasons) + [k for k in gaps_by_reason if k not in ev.reasons]
    for reason in order:
        lst = gaps_by_reason.get(reason)
        if not lst:
            continue
        gaps.append({"reason": reason, "label": ev.reasons.get(reason, reason), "count": len(lst),
                     "areas": collections.Counter(r["area"] for r in lst).most_common(), "cases": lst[:10],
                     "more": max(0, len(lst) - 10)})
    runs, runs_problem = run_index()
    problems = Problems(list(ev.problems.items))  # the evaluation is cached: never add to its list
    if runs_problem == "corrupt":
        problems.note("The run history", results_dir() / "runs" / "index.json", runs_problem)
    latest = dict(runs[0]) if runs else None
    if latest:
        latest["duration"] = duration(latest.get("startedAt"), latest.get("finishedAt"))
        run, _ = run_file(latest["id"], "run.json", dict)
        latest["diff"] = _dict(_dict(_dict(run).get("summary")).get("diff"))
    return {
        "total": total, "automated": automated, "verified": verified,
        "automated_pct": _pct(automated, total), "verified_pct": _pct(verified, total),
        "failing": counts.get("fail", 0), "not_run": counts.get("not_run", 0) + counts.get("skipped", 0),
        "gap_count": total - verified, "breakdown": breakdown, "by_area": by_area, "gaps": gaps,
        "latest": latest, "run_count": len(runs), "catalog_generated": ev.catalog.generated,
        "feature_count": len(ev.catalog.features), "gate_loaded": ev.gate_loaded, "problems": problems.items,
    }


def run_rows() -> tuple[list[dict], list[str]]:
    rows, problem = run_index()
    problems = Problems()
    problems.note("The run history", results_dir() / "runs" / "index.json", problem)
    out = []
    for r in rows:
        row = dict(r)
        row["duration"] = duration(r.get("startedAt"), r.get("finishedAt"))
        row["_search"] = " ".join(str(x) for x in (r.get("id"), r.get("by"), r.get("mode"), r.get("status"),
                                                    " ".join(str(s) for s in _list(r.get("suites"))))).lower()
        out.append(row)
    return out, problems.items


def _links(ids: Any) -> list[dict]:
    """Case ids as ``{id, ok}``: only ids in the catalog's id format get a link."""
    return [{"id": i, "ok": valid_case_id(i)} for i in _list(ids) if isinstance(i, str)]


def run_detail(run_id: str) -> dict | None:
    """Everything the run page shows, or None when the run does not exist."""
    if run_dir(run_id) is None:
        return None
    problems = Problems()
    base = run_dir(run_id)
    run, problem = run_file(run_id, "run.json", dict)
    problems.note("run.json", base / "run.json", problem)
    index_entry = next((r for r in run_index()[0] if r.get("id") == run_id), {})
    run = run or {}
    summary = _dict(run.get("summary"))
    results, problem = run_file(run_id, "results.json", list)
    problems.note("results.json", base / "results.json", problem)
    results = [t for t in _list(results) if isinstance(t, dict)]
    suites: dict[str, dict] = {}
    for t in results:
        s = suites.setdefault(str(t.get("suite") or "other"), {"suite": str(t.get("suite") or "other"), "total": 0,
                                                                 "passed": 0, "failed": 0, "skipped": 0})
        s["total"] += 1
        status = t.get("status")
        if status in ("passed", "failed", "skipped"):
            s[status] += 1
    failed = [dict(t, case_links=_links(t.get("cases"))) for t in results if t.get("status") == "failed"]
    diff, problem = run_file(run_id, "diff.json", dict)
    if problem == "corrupt":
        problems.note("diff.json", base / "diff.json", problem)
    diff = _dict(diff)
    diff_lists = []
    for key, label in (("regressed", "Regressed"), ("newlyFailing", "Newly failing"), ("fixed", "Fixed"),
                       ("newlyPassing", "Newly passing"), ("noLongerRun", "No longer run")):
        ids = [i for i in _list(diff.get(key)) if isinstance(i, str)]
        diff_lists.append({"key": key, "label": label, "count": len(ids), "ids": _links(ids[:DETAIL_LIST_CAP]),
                           "more": max(0, len(ids) - DETAIL_LIST_CAP)})
    cases, problem = run_file(run_id, "cases.json", dict)
    problems.note("cases.json", base / "cases.json", problem)
    failing_cases = []
    for cid, c in _dict(cases).items():
        if isinstance(c, dict) and c.get("result") == "fail":
            test = next((t for t in _list(c.get("tests")) if isinstance(t, dict) and t.get("status") == "failed"), None)
            failing_cases.append({"id": cid, "ok": valid_case_id(cid), "area": c.get("area") or "", "test": test})
    steps = [dict(s, duration=duration(s.get("startedAt"), s.get("finishedAt")))
             for s in _list(run.get("steps")) if isinstance(s, dict)]
    head = {**index_entry, **{k: v for k, v in run.items() if k in ("id", "status", "mode", "by", "startedAt", "finishedAt")}}
    head.setdefault("id", run_id)
    return {
        "run": run, "head": head, "run_request": _dict(run.get("request")), "steps": steps,
        "suite_names": [str(x) for x in _list(_dict(run.get("request")).get("suites")) or _list(head.get("suites"))],
        "tests": _dict(summary.get("tests")) or _dict(index_entry.get("tests")),
        "cases": _dict(summary.get("cases")) or _dict(index_entry.get("cases")),
        "coverage": _dict(summary.get("coverage")) or _dict(index_entry.get("coverage")),
        "unknown_tags": [t for t in _list(summary.get("unknownTags")) if isinstance(t, str)],
        "duration": duration(head.get("startedAt"), head.get("finishedAt")),
        "suites": sorted(suites.values(), key=lambda s: -s["total"]),
        "failed": failed[:DETAIL_LIST_CAP], "failed_total": len(failed),
        "diff": diff, "diff_against": str(diff.get("against") or ""),
        "diff_against_ok": run_dir(str(diff.get("against") or "")) is not None, "diff_lists": diff_lists,
        "failing_cases": failing_cases[:DETAIL_LIST_CAP], "failing_cases_total": len(failing_cases),
        "problems": problems.items,
    }


def case_detail(case_id: str) -> dict | None:
    if not valid_case_id(case_id):
        return None
    ev = evaluate()
    if case_id not in ev.catalog.cases:
        return None
    feature, case = ev.catalog.cases[case_id]
    led, _ = ledger()
    entry = _dict(led.get(case_id))
    marks, _ = manual_marks()
    history = []
    runs, _ = run_index()
    for r in runs[:HISTORY_RUNS]:
        cases, problem = run_file(r["id"], "cases.json", dict)
        if problem:
            continue
        c = _dict(cases).get(case_id)
        if isinstance(c, dict):
            history.append({"run": r, "result": c.get("result") or "", "via": c.get("via") or "",
                            "tests": [t for t in _list(c.get("tests")) if isinstance(t, dict)],
                            "tests_total": _num(c.get("testsTotal"))})
    return {
        "case": case, "feature": feature, "row": ev.by_id.get(case_id, {}), "reason_label": ev.reasons.get(ev.by_id.get(case_id, {}).get("reason") or "", ""),
        "automated_by": [a for a in _list(case.get("automated_by")) if isinstance(a, dict)],
        "automated_by_total": _num(case.get("automated_by_total")),
        "ledger": entry, "ledger_run_ok": run_dir(str(entry.get("run") or "")) is not None, "ledger_tests": [t for t in _list(entry.get("tests")) if isinstance(t, dict)],
        "manual": _dict(marks.get(case_id)), "history": history, "problems": list(ev.problems.items),
    }


def match(row: dict, q: str) -> bool:
    words = q.lower().split()
    return all(w in row.get("_search", "") for w in words)
