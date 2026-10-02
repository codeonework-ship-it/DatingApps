#!/usr/bin/env python3
"""Regenerate the feature/test catalog from the working tree.

    python3 qa/catalog/tools/regenerate.py            # catalog JSON + inventory Markdown
    python3 qa/catalog/tools/regenerate.py --no-md    # catalog JSON only
    python3 qa/catalog/tools/regenerate.py --tags-only  # re-apply [case:...] tags + manual_cases.json
                                                        # to the last extraction (fast, ~5 s)

Pipeline (each step is a plain script, runnable on its own, in this order):
  extract_app.py   app/lib controls            -> <build>/app_controls.json
  test_scan.py     tests in every suite         -> <build>/tests.json
  build_catalog.py app features + cases         -> <build>/app_features.json
  build_other.py   website + operator console   -> <build>/other_features.json
  final_catalog.py merge, tags, manual, stats   -> qa/catalog/feature_catalog.json
  write_md.py      human inventory              -> documents/qa/FEATURE_AND_TEST_INVENTORY_2026-10-02.md

<build> is QA_CATALOG_BUILD_DIR (default qa/results/catalog_build, git-ignored).
Outputs can be redirected with QA_CATALOG_OUT / QA_INVENTORY_OUT (used by tests).
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paths import BUILD, CATALOG, ROOT, build_path  # noqa: E402

STEPS = ["extract_app.py", "test_scan.py", "build_catalog.py", "build_other.py", "final_catalog.py", "write_md.py"]


def run(step: str, quiet: bool) -> None:
    t0 = time.time()
    proc = subprocess.run([sys.executable, os.path.join(HERE, step)], cwd=ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout[-4000:] + proc.stderr[-4000:])
        raise SystemExit(f"catalog step {step} failed (exit {proc.returncode})")
    if not quiet:
        print(f"  {step:<18} {time.time() - t0:5.1f}s")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-md", action="store_true", help="skip the Markdown inventory")
    ap.add_argument("--tags-only", action="store_true", help="re-run only final_catalog (+ write_md) using the last extraction")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    steps = list(STEPS)
    if a.tags_only:
        needed = ["app_features.json", "other_features.json", "tests.json"]
        if all(os.path.exists(build_path(n)) for n in needed):
            steps = ["final_catalog.py", "write_md.py"]
        elif not a.quiet:
            print("no previous extraction in", BUILD, "- running the full pipeline")
    if a.no_md:
        steps.remove("write_md.py")
    t0 = time.time()
    for s in steps:
        run(s, a.quiet)
    stats = json.load(open(CATALOG))["stats"]
    if not a.quiet:
        print(f"catalog: {os.path.relpath(CATALOG, ROOT)} in {time.time() - t0:.1f}s")
    print(json.dumps({"cases": stats["cases"], "case_status": stats["case_status"], "mapped_by": stats.get("mapped_by"),
                      "tag_issues": {k: len(v) for k, v in (stats.get("tag_issues") or {}).items()}}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
