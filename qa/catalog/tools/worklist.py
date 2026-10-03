#!/usr/bin/env python3
"""Coverage work list: every catalog case that is not proven by a [case:...]
tagged test, grouped by suite owner, area and feature, with a suggested test
file and a split into parallel work packages that never share a file.

    python3 qa/catalog/tools/worklist.py            # writes the two outputs below
    python3 qa/catalog/tools/worklist.py --print    # summary only

Outputs: qa/results/coverage_worklist.json and
documents/qa/COVERAGE_WORKLIST_<date>.md (QA_WORKLIST_MD overrides the path).

A gap is a case whose status is not_automated, presence_only or partial, or
an automated case that only the heuristic maps (heuristic_only: the strict
gate, ``coverage_gate.py --strict-tags``, does not count it). Manual cases are
not gaps here (QA Lab tracks their checklist).
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paths import CATALOG, ROOT  # noqa: E402
import case_tags as CT  # noqa: E402

OUT_JSON = os.path.join(ROOT, "qa", "results", "coverage_worklist.json")

# Work packages: areas (app) or owners, chosen so no two packages edit the same test file.
PACKAGES = [
    ("A", "App A: Navigation & Settings, Notifications, Shared components, Web Workspace, Localization",
     {"Navigation & Settings", "Notifications", "Shared components", "Web Workspace", "Localization"}),
    ("B", "App B: Engagement Hub, Groups, Clubs, Social Chat, Celebrations",
     {"Engagement Hub", "Groups", "Clubs & Lists", "Social Chat (friends/rooms/groups)", "Celebrations & Rewards"}),
    ("C", "App C: Blog/Chapters, First Chapter Studio, Photo Themes, Today Wall, City Pilot, Help & Support",
     {"Blog / Chapters", "First Chapter Studio", "Photo Themes", "Today Wall", "City Pilot", "Help & Support"}),
    ("D", "App D: Date Plans, Today/Intentional Dating, Discover, Matches, Chat",
     {"Date Plans", "Today / Intentional Dating", "Discover", "Matches", "Chat (dating)"}),
    ("E", "App E: Auth, Profile, Verification, Payments, Safety, Calls, Friends, Graduation, device journeys",
     {"Auth & Onboarding", "Profile", "Verification", "Payments & Membership", "Safety", "Calls", "Friends & Introducer",
      "Graduation", "End-to-end journeys"}),
    ("F", "Console + Website + Backend API (Django, Playwright, api_e2e/Go)", None),
]


def kind_of(cid: str, feature_id: str) -> str:
    """The case kind: the id part after the control (action, api_failure, renders, ...)."""
    tail = cid[len(feature_id) + 1:] if cid.startswith(feature_id + ".") else cid.rsplit(".", 1)[-1]
    last = tail.rsplit(".", 1)[-1]
    return re.sub(r"_\d+$", "", last)


def owner_of(feature: dict, cid: str) -> str:
    fid = feature["id"]
    if fid.startswith("console."):
        return "command_center"
    if fid.startswith("site."):
        return "website"
    if fid.startswith("platform.") or cid.endswith((".api_contract", ".api_contract_route")):
        return "backend_api"
    if fid.startswith("journeys."):
        return "e2e_journeys"
    return "flutter_app"


def control_of(feature: dict, case: dict) -> str | None:
    cov = case.get("covers_controls") or []
    if cov:
        return cov[0]
    best = None
    for c in feature.get("controls", []):
        if case["id"].startswith(c["id"] + ".") and (best is None or len(c["id"]) > len(best)):
            best = c["id"]
    return best


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--print", action="store_true", help="print the summary only, write nothing")
    ap.add_argument("--date", default=os.environ.get("QA_CATALOG_DATE") or dt.date.today().isoformat())
    a = ap.parse_args(argv)
    cat = json.load(open(CATALOG))
    scan = CT.scan_all(ROOT)
    # tagged test files per feature prefix -> most used file (suggested home for new tests)
    files_by_prefix: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for suite, tests in scan.items():
        for t in tests:
            for cid in t.get("cases") or []:
                parts = cid.split(".")
                for n in (2, 3):
                    files_by_prefix[(suite, ".".join(parts[:n]))][t["file"]] += 1
    ctl_by_id = {c["id"]: c for f in cat["features"] for c in f["controls"]}
    area_of_case = {c["id"]: f["area"] for f in cat["features"] for c in f["cases"]}
    pkg_of_area = {a: pid for pid, _, areas in PACKAGES if areas for a in areas}
    # files that already prove cases of several packages are shared: never suggest them
    pkgs_in_file = collections.defaultdict(set)
    for suite, tests in scan.items():
        for t in tests:
            for cid in t.get("cases") or []:
                area = area_of_case.get(cid)
                if area:
                    pkgs_in_file[t["file"]].add(pkg_of_area.get(area, "F") if suite == "flutter" else "F")
    shared_files = {f for f, ps in pkgs_in_file.items() if len(ps) > 1}

    def suggest(feature, case, owner, control):
        fid = feature["id"]
        suites = {"flutter_app": "flutter", "command_center": "django", "website": "playwright", "backend_api": "api_e2e",
                  "e2e_journeys": "appium"}
        suite = suites[owner]
        if owner == "backend_api":
            if fid.startswith("platform."):
                return "backend/internal/bff/mobile/domain_event_retention_postgres_test.go"
            return "qa/api_e2e/tests/test_19_catalog_api_contracts.py (CASE_ENDPOINTS) + a happy path in test_20/test_21"
        for key in ([(suite, ".".join(control.split(".")[:3]))] if control else []) + [(suite, fid)]:
            for f_, _n in (files_by_prefix.get(key) or collections.Counter()).most_common():
                if f_ not in shared_files:
                    return f_
        if owner == "command_center":
            area = fid.split(".")[1]
            return f"control-panel/control_panel/tests/test_cases_{area.split('_')[0]}.py"
        if owner == "website":
            return f"website/tests/{fid.split('.')[1]}.spec.js"
        if owner == "e2e_journeys":
            return "qa/appium/tests (device journey)"
        src = (feature.get("source_files") or [""])[0]
        m = re.match(r"app/lib/features/([^/]+)/(?:screens/|widgets/)?(?:.*/)?([^/]+)\.dart$", src)
        if m:
            return f"app/test/features/{m.group(1)}/{m.group(2).replace('_screen', '')}_controls_test.dart"
        return f"app/test/features/{fid.split('.')[0]}/{fid.split('.')[1]}_controls_test.dart"

    gaps = []
    for f in cat["features"]:
        for c in f["cases"]:
            st = c.get("status")
            if st == "manual":
                continue
            if st == "automated" and c.get("mapped_by") == "tag":
                continue
            reason = "heuristic_only" if st == "automated" else st
            owner = owner_of(f, c["id"])
            control = control_of(f, c)
            ctl = ctl_by_id.get(control) or {}
            gaps.append({
                "case": c["id"], "kind": kind_of(c["id"], control or f["id"]), "type": c.get("type"), "reason": reason,
                "feature": f["id"], "area": f["area"], "owner": owner, "control": control,
                "control_label": ctl.get("label"), "qa_key": ctl.get("qa_key"),
                "source": ctl.get("source") or (f.get("source_files") or [None])[0],
                "suggested_test_file": suggest(f, c, owner, control),
                "title": c.get("title"),
                **({"heuristic_tests": [f"{x['suite']}: {x['file']} :: {x['test']}" for x in c.get("automated_by", [])][:4]} if reason == "heuristic_only" else {}),
                **({"declared_in": c["declared_in"]} if c.get("declared_in") else {}),
            })

    def package_of(g):
        if g["owner"] in ("command_center", "website", "backend_api"):
            return "F"
        for pid, _, areas in PACKAGES:
            if areas and g["area"] in areas:
                return pid
        return "E"

    for g in gaps:
        g["package"] = package_of(g)
    by = lambda key: dict(collections.Counter(g[key] for g in gaps).most_common())  # noqa: E731
    files_per_pkg = collections.defaultdict(set)
    for g in gaps:
        files_per_pkg[g["package"]].add(g["suggested_test_file"])
    overlap = {f for p, fs in files_per_pkg.items() for f in fs if sum(f in o for o in files_per_pkg.values()) > 1}
    stats = cat["stats"]
    cases = [c for f in cat["features"] for c in f["cases"]]
    out = {
        "generated": a.date,
        "catalog_generated": cat.get("generated"),
        "definition": __doc__.split("\n\n")[2].replace("\n", " "),
        "totals": {"cases": len(cases), "automated": stats["case_status"].get("automated", 0),
                   "automated_by_tag": sum(1 for c in cases if c.get("status") == "automated" and c.get("mapped_by") == "tag"),
                   "gaps": len(gaps)},
        "gaps_by_reason": by("reason"), "gaps_by_owner": by("owner"), "gaps_by_kind": by("kind"), "gaps_by_area": by("area"),
        "packages": [{"id": pid, "title": title, "areas": sorted(areas) if areas else ["Operator console", "Website (public)", "backend API"],
                      "gaps": sum(1 for g in gaps if g["package"] == pid),
                      "by_reason": dict(collections.Counter(g["reason"] for g in gaps if g["package"] == pid).most_common()),
                      "test_files": sorted(files_per_pkg[pid])} for pid, title, areas in PACKAGES],
        "file_overlap_between_packages": sorted(overlap),
        "gaps": sorted(gaps, key=lambda g: (g["package"], g["owner"], g["area"], g["feature"], g["case"])),
    }
    if a.print:
        print(json.dumps({k: out[k] for k in ("totals", "gaps_by_reason", "gaps_by_owner")}, indent=1))
        for p in out["packages"]:
            print(p["id"], p["gaps"], p["by_reason"], p["title"])
        return 0
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    json.dump(out, open(OUT_JSON, "w"), indent=1, ensure_ascii=False)
    md_path = os.environ.get("QA_WORKLIST_MD") or os.path.join(ROOT, "documents", "qa", f"COVERAGE_WORKLIST_{a.date}.md")
    write_md(out, md_path)
    print(os.path.relpath(OUT_JSON, ROOT), os.path.relpath(md_path, ROOT), out["totals"])
    return 0


def write_md(out: dict, path: str) -> None:
    t = out["totals"]
    L = [f"# Coverage work list ({out['generated']})", "",
         "Generated by `python3 qa/catalog/tools/worklist.py` from `qa/catalog/feature_catalog.json`; the full list, with control, "
         "source file and suggested test file per case, is `qa/results/coverage_worklist.json`.", "",
         "A **gap** is a case that is not automated, presence-only or partial, or that only the heuristic maps "
         "(`heuristic_only`: `coverage_gate.py --strict-tags` does not count it). To close one, add a test that performs the action "
         "and asserts the outcome, and name the case in it (`[case:<id>]`, `@pytest.mark.case`, `// case:`, or a Django docstring tag). "
         "Where the heuristic test really proves the case, adding the tag to that test is enough.", "",
         f"Cases {t['cases']}, automated {t['automated']}, proven by a tag {t['automated_by_tag']} "
         f"({100 * t['automated_by_tag'] / t['cases']:.1f}%), gaps {t['gaps']}.", "",
         "| Reason | Gaps |", "|---|---:|"]
    L += [f"| {k} | {v} |" for k, v in out["gaps_by_reason"].items()]
    L += ["", "| Suite owner | Gaps |", "|---|---:|"]
    L += [f"| {k} | {v} |" for k, v in out["gaps_by_owner"].items()]
    L += ["", "## Work packages", "",
          "Each package owns its test files; no suggested test file appears in two packages"
          + ("." if not out["file_overlap_between_packages"] else f" except: {', '.join(out['file_overlap_between_packages'])}."), "",
          "| Package | Scope | Gaps | not_automated | heuristic_only | presence_only | partial |", "|---|---|---:|---:|---:|---:|---:|"]
    for p in out["packages"]:
        r = p["by_reason"]
        L.append(f"| {p['id']} | {p['title']} | {p['gaps']} | {r.get('not_automated', 0)} | {r.get('heuristic_only', 0)} | "
                 f"{r.get('presence_only', 0)} | {r.get('partial', 0)} |")
    L += ["", "## Gaps by area", "", "| Area | Gaps |", "|---|---:|"]
    L += [f"| {k} | {v} |" for k, v in out["gaps_by_area"].items()]
    L += ["", "## Gaps by kind", "", "| Kind | Gaps |", "|---|---:|"]
    L += [f"| {k} | {v} |" for k, v in out["gaps_by_kind"].items()]
    L += ["", "## Features with the most gaps", "", "| Package | Feature | Owner | Gaps | Suggested test file |", "|---|---|---|---:|---|"]
    feats = collections.Counter((g["package"], g["feature"], g["owner"]) for g in out["gaps"])
    sugg = {}
    for g in out["gaps"]:
        sugg.setdefault(g["feature"], collections.Counter())[g["suggested_test_file"]] += 1
    for (pid, fid, owner), n in feats.most_common(40):
        L.append(f"| {pid} | `{fid}` | {owner} | {n} | `{sugg[fid].most_common(1)[0][0]}` |")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write("\n".join(L) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
