"""Coverage gate (qa/lab/coverage_gate.py) on a synthetic results directory."""
import datetime as dt
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "qa", "lab"))

import coverage_gate as G  # noqa: E402

CATALOG = {"features": [
    {"id": "f1", "area": "Discover", "cases": [
        {"id": "a", "status": "automated", "mapped_by": "tag"},
        {"id": "b", "status": "automated", "mapped_by": "heuristic"},
        {"id": "c", "status": "not_automated"},
        {"id": "d", "status": "presence_only"},
    ]},
    {"id": "f2", "area": "Calls", "cases": [
        {"id": "m1", "status": "manual"},
        {"id": "m2", "status": "not_automated"},
    ]},
]}


def _write(tmp_path, ledger, marks, manual=None):
    (tmp_path / "ledger.json").write_text(json.dumps(ledger))
    (tmp_path / "manual_checks.json").write_text(json.dumps(marks))
    cat = tmp_path / "catalog.json"
    cat.write_text(json.dumps(CATALOG))
    man = tmp_path / "manual.json"
    man.write_text(json.dumps(manual or {"m2": "needs a real phone call"}))
    return ["--results", str(tmp_path), "--catalog", str(cat), "--manual-cases", str(man)]


def test_reasons_per_case():
    rows = G.evaluate(CATALOG, {"m2": "x"}, {"a": {"result": "pass"}, "b": {"result": "fail"}},
                      {"m1": {"result": "pass"}, "m2": {"result": "fail"}})
    got = {r["id"]: r["reason"] for r in rows}
    assert got == {"a": None, "b": "fail", "c": "not_automated", "d": "presence_only", "m1": None, "m2": "manual_fail"}


def test_runtime_tag_counts_as_automated_and_strict_tags_rejects_heuristics():
    rows = G.evaluate(CATALOG, {}, {"c": {"result": "pass", "via": "tag"}, "b": {"result": "pass"}}, {}, strict_tags=True)
    got = {r["id"]: r["reason"] for r in rows}
    assert got["c"] is None
    assert got["b"] == "heuristic_only"
    assert got["a"] == "not_run"


def test_max_age_marks_old_results_stale():
    now = dt.datetime(2026, 10, 2, tzinfo=dt.timezone.utc)
    rows = G.evaluate(CATALOG, {}, {"a": {"result": "pass", "at": "2026-09-01T00:00:00Z"}},
                      {"m1": {"result": "pass", "at": "2026-09-01T00:00:00Z"}}, max_age_days=7, now=now)
    got = {r["id"]: r["reason"] for r in rows}
    assert got["a"] == "stale"
    assert got["m1"] == "manual_unchecked"


def test_exit_codes(tmp_path, capsys):
    args = _write(tmp_path, {"a": {"result": "pass"}, "b": {"result": "pass"}}, {})
    assert G.main(args) == 1
    out = capsys.readouterr().out
    assert "verified 2/6" in out and "- c" in out and "manual, not checked yet: 2" in out
    full = {"features": [{"id": "f", "area": "X", "cases": [{"id": "a", "status": "automated"}, {"id": "m", "status": "manual"}]}]}
    (tmp_path / "catalog.json").write_text(json.dumps(full))
    (tmp_path / "manual_checks.json").write_text(json.dumps({"m": [{"result": "fail"}, {"result": "pass", "by": "op"}]}))
    assert G.main(args) == 0
    assert "PASS" in capsys.readouterr().out


def test_run_latest_uses_that_runs_cases(tmp_path, capsys):
    args = _write(tmp_path, {}, {})
    run = tmp_path / "runs" / "20261002-120000-abcd"
    run.mkdir(parents=True)
    (tmp_path / "runs" / "index.json").write_text(json.dumps([{"id": run.name, "status": "passed"}]))
    (run / "run.json").write_text(json.dumps({"finishedAt": "2026-10-02T12:10:00Z"}))
    (run / "cases.json").write_text(json.dumps({"a": {"result": "pass"}, "b": {"result": "pass"}}))
    assert G.main(args + ["--run", "latest", "--json"]) == 1
    data = json.loads(capsys.readouterr().out)
    assert data["source"] == f"run {run.name}" and data["verified"] == 2
    assert sorted(data["gaps"]) == ["manual_unchecked", "not_automated", "presence_only"]


def test_missing_catalog_is_exit_2(tmp_path):
    assert G.main(["--catalog", str(tmp_path / "nope.json"), "--results", str(tmp_path)]) == 2
