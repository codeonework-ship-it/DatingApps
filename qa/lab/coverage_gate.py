#!/usr/bin/env python3
"""QA Lab coverage gate: exit 0 only when every catalog case is verified.

A case is *verified* when either
  * it is automated (catalog status ``automated`` - by ``[case:...]`` tag or
    heuristic - or a run saw its tag) AND its latest executed result is pass, or
  * it is a manual case (``qa/catalog/manual_cases.json`` / status ``manual``)
    AND the latest checklist mark in QA Lab is pass.

Everything else is a gap and is printed, grouped by reason and area.

    python3 qa/lab/coverage_gate.py                 # ledger: latest result per case across runs
    python3 qa/lab/coverage_gate.py --run latest    # only the most recent run's results
    python3 qa/lab/coverage_gate.py --run 20261002-131500-ab12
    python3 qa/lab/coverage_gate.py --strict-tags   # heuristic matches do not count as automated
    python3 qa/lab/coverage_gate.py --max-age-days 7 --list 50 --json

Inputs (QA_LAB_RESULTS_DIR, default qa/results/qa_lab): ledger.json,
manual_checks.json, runs/index.json, runs/<id>/cases.json. Runs are produced
by QA Lab (/qa-lab with QA_LAB=1). Exit codes: 0 = 100% verified, 1 = gaps,
2 = missing inputs.
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REASONS = {
    "fail": "automated, latest result FAILED",
    "not_run": "automated, never run in QA Lab (or not in the selected run)",
    "skipped": "automated, latest result skipped / xfail",
    "stale": "automated, latest result older than --max-age-days",
    "manual_unchecked": "manual, not checked yet",
    "manual_fail": "manual, last check FAILED",
    "presence_only": "presence-only: a test finds the control but asserts no outcome",
    "partial": "partial: covered only indirectly",
    "not_automated": "not automated and not listed as manual",
    "heuristic_only": "automated only by heuristic match (--strict-tags)",
}


def load(path: Path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def parse_time(s: str | None) -> dt.datetime | None:
    if not s:
        return None
    try:
        return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def evaluate(catalog: dict, manual_cases: dict, results: dict, marks: dict, *, strict_tags: bool = False,
             max_age_days: float | None = None, now: dt.datetime | None = None) -> list[dict]:
    """Return one row per case: {id, area, feature, ok, reason}."""
    now = now or dt.datetime.now(dt.timezone.utc)
    cutoff = now - dt.timedelta(days=max_age_days) if max_age_days else None
    manual_ids = {k for k in manual_cases if not k.startswith("_")}
    rows = []
    for f in catalog.get("features", []):
        for c in f.get("cases", []):
            cid = c["id"]
            res = results.get(cid) or {}
            tagged_run = res.get("via") == "tag"
            status = c.get("status")
            automated = status == "automated" or tagged_run
            if automated and strict_tags and c.get("mapped_by") != "tag" and not tagged_run:
                automated = False
                reason = "heuristic_only"
            else:
                reason = None
            if automated:
                result = res.get("result")
                at = parse_time(res.get("at"))
                if result is None or result == "not_run":
                    reason = "not_run"
                elif cutoff and at and at < cutoff:
                    reason = "stale"
                elif result == "pass":
                    reason = None
                elif result == "fail":
                    reason = "fail"
                else:
                    reason = "skipped"
            elif reason is None and (status == "manual" or cid in manual_ids):
                mark = marks.get(cid) or {}
                at = parse_time(mark.get("at"))
                if mark.get("result") == "pass" and not (cutoff and at and at < cutoff):
                    reason = None
                elif mark.get("result") == "fail":
                    reason = "manual_fail"
                else:
                    reason = "manual_unchecked"
            elif reason is None:
                reason = status if status in ("presence_only", "partial") else "not_automated"
            rows.append({"id": cid, "area": f.get("area"), "feature": f.get("id"), "ok": reason is None, "reason": reason})
    return rows


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--results", default=os.environ.get("QA_LAB_RESULTS_DIR") or str(ROOT / "qa" / "results" / "qa_lab"))
    ap.add_argument("--catalog", default=str(ROOT / "qa" / "catalog" / "feature_catalog.json"))
    ap.add_argument("--manual-cases", default=str(ROOT / "qa" / "catalog" / "manual_cases.json"))
    ap.add_argument("--run", help="a run id, or 'latest'; default = the ledger (latest result per case across runs)")
    ap.add_argument("--strict-tags", action="store_true", help="only [case:...]-tagged tests count as automation")
    ap.add_argument("--max-age-days", type=float, help="results / manual marks older than this do not count")
    ap.add_argument("--list", type=int, default=30, help="gap ids to print per reason (0 = none, -1 = all)")
    ap.add_argument("--json", action="store_true", help="print the full evaluation as JSON")
    a = ap.parse_args(argv)

    results_dir = Path(a.results)
    catalog = load(Path(a.catalog), None)
    if not catalog:
        print(f"coverage gate: catalog not found at {a.catalog}", file=sys.stderr)
        return 2
    manual_cases = load(Path(a.manual_cases), {})
    history = load(results_dir / "manual_checks.json", {})
    marks = {k: v[-1] for k, v in history.items() if isinstance(v, list) and v}
    source = "ledger (latest result per case across runs)"
    if a.run:
        run_id = a.run
        if run_id == "latest":
            idx = load(results_dir / "runs" / "index.json", [])
            done = [r for r in idx if r.get("status") not in ("running",)]
            if not done:
                print("coverage gate: no QA Lab runs yet", file=sys.stderr)
                return 2
            run_id = done[0]["id"]
        cases = load(results_dir / "runs" / run_id / "cases.json", None)
        if cases is None:
            print(f"coverage gate: run {run_id} has no cases.json", file=sys.stderr)
            return 2
        run = load(results_dir / "runs" / run_id / "run.json", {})
        at = run.get("finishedAt") or run.get("startedAt")
        results = {k: {**v, "at": at} for k, v in cases.items()}
        source = f"run {run_id}"
    else:
        results = load(results_dir / "ledger.json", {})

    rows = evaluate(catalog, manual_cases, results, marks, strict_tags=a.strict_tags, max_age_days=a.max_age_days)
    total = len(rows)
    ok = sum(1 for r in rows if r["ok"])
    gaps = [r for r in rows if not r["ok"]]
    by_reason = collections.defaultdict(list)
    for r in gaps:
        by_reason[r["reason"]].append(r)
    if a.json:
        print(json.dumps({"source": source, "total": total, "verified": ok, "verified_pct": round(100 * ok / total, 2) if total else 0,
                          "gaps": {k: [r["id"] for r in v] for k, v in by_reason.items()}}, indent=1))
        return 0 if not gaps else 1
    pct = 100 * ok / total if total else 0.0
    print(f"QA Lab coverage gate - {source}")
    print(f"verified {ok}/{total} cases ({pct:.1f}%)" + ("" if gaps else " - PASS"))
    if not gaps:
        return 0
    print(f"{len(gaps)} gaps:")
    for reason in REASONS:
        lst = by_reason.get(reason)
        if not lst:
            continue
        areas = collections.Counter(r["area"] for r in lst)
        print(f"\n  {REASONS[reason]}: {len(lst)}")
        print("    by area: " + ", ".join(f"{k} {v}" for k, v in areas.most_common()))
        limit = len(lst) if a.list < 0 else a.list
        for r in lst[:limit]:
            print(f"    - {r['id']}")
        if limit < len(lst):
            print(f"    ... {len(lst) - limit} more (--list -1 for all)")
    print("\nFAIL: not every case is automated-and-passing or manual-and-checked.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
