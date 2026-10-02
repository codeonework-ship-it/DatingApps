"""Repo-relative paths shared by the catalog generator scripts.

Intermediate JSON (app_controls/tests/app_features/other_features) goes to
QA_CATALOG_BUILD_DIR, default qa/results/catalog_build/ (git-ignored). The
outputs are qa/catalog/feature_catalog.json and
documents/qa/FEATURE_AND_TEST_INVENTORY_2026-10-02.md.
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
BUILD = os.environ.get("QA_CATALOG_BUILD_DIR") or os.path.join(ROOT, "qa", "results", "catalog_build")
CATALOG = os.environ.get("QA_CATALOG_OUT") or os.path.join(ROOT, "qa", "catalog", "feature_catalog.json")
MANUAL = os.environ.get("QA_MANUAL_CASES") or os.path.join(ROOT, "qa", "catalog", "manual_cases.json")
INVENTORY_MD = os.environ.get("QA_INVENTORY_OUT") or os.path.join(ROOT, "documents", "qa", "FEATURE_AND_TEST_INVENTORY_2026-10-02.md")


def build_path(name):
    os.makedirs(BUILD, exist_ok=True)
    return os.path.join(BUILD, name)
