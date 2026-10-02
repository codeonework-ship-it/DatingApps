"""pytest plugin used by QA Lab to record results with their catalog case ids.

Loaded with ``-p qalab_pytest`` (PYTHONPATH must include qa/lab). Writes one
JSON object per finished test to ``$QA_LAB_PYTEST_JSON``:

    {"nodeid": "tests/test_x.py::test_y[p]", "file": "tests/test_x.py",
     "test": "test_y[p]", "outcome": "passed|failed|skipped|error",
     "duration": 1.23, "cases": ["auth.signin.action"], "message": "..."}

``cases`` come from ``@pytest.mark.case("<id>", ...)`` on the test, its class,
the module's ``pytestmark`` or a ``pytest.param(..., marks=...)``. The marker
is also registered here so suites without a pytest.ini (qa/console_smoke)
accept it.
"""
from __future__ import annotations

import json
import os
import re

_ID_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.\-]*$")
_seen: dict[str, dict] = {}
_cases: dict[str, list[str]] = {}


def case_ids(item) -> list[str]:
    out: list[str] = []
    for mark in item.iter_markers(name="case"):
        for arg in mark.args:
            if not isinstance(arg, str):
                continue
            for part in re.split(r"[\s,]+", arg.strip()):
                if part and _ID_RE.match(part) and part not in out:
                    out.append(part)
    return out


def pytest_configure(config):
    config.addinivalue_line("markers", "case(*ids): QA Lab catalog case ids this test proves")


def _write(rec: dict) -> None:
    path = os.environ.get("QA_LAB_PYTEST_JSON")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(rec, ensure_ascii=False) + "\n")


def _message(report) -> str:
    try:
        text = report.longreprtext or ""
    except Exception:  # noqa: BLE001
        text = str(report.longrepr or "")
    return text[-2000:]


def pytest_runtest_logreport(report):
    nodeid = report.nodeid
    rec = _seen.get(nodeid)
    if rec is None:
        file, _, test = nodeid.partition("::")
        rec = {"nodeid": nodeid, "file": file, "test": test, "outcome": None, "duration": 0.0,
               "cases": _cases.get(nodeid, []), "message": ""}
        _seen[nodeid] = rec
    rec["duration"] += float(getattr(report, "duration", 0.0) or 0.0)
    if report.when == "setup":
        if report.failed:
            rec["outcome"], rec["message"] = "error", _message(report)
        elif report.skipped:
            rec["outcome"] = "skipped"
            rec["message"] = _message(report)[-400:]
    elif report.when == "call":
        if getattr(report, "wasxfail", None) is not None:
            # xfailed (documented defect) never counts as passing; a non-strict
            # xpass is a pass. A strict xpass arrives as a plain failure.
            rec["outcome"] = "skipped" if report.skipped else report.outcome
            rec["message"] = "xfail: " + str(report.wasxfail)
        else:
            rec["outcome"] = report.outcome
            if report.failed:
                rec["message"] = _message(report)
    elif report.when == "teardown":
        if report.failed and rec["outcome"] == "passed":
            rec["outcome"], rec["message"] = "error", _message(report)
        if rec["outcome"] is None:
            rec["outcome"] = "skipped"
        _write(rec)
        _seen.pop(nodeid, None)


def pytest_collection_modifyitems(session, config, items):  # noqa: ARG001 - hook signature
    for item in items:
        _cases[item.nodeid] = case_ids(item)
