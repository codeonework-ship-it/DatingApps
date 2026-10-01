from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any


APPium_DIR = Path(__file__).resolve().parent
FIXTURES_DIR = APPium_DIR / "fixtures"
REPORT_DIR = Path(os.getenv("QA_REPORT_DIR", str(APPium_DIR.parents[1] / "qa" / "reports" / "appium")))


def load_fixture(name: str) -> Any:
    path = FIXTURES_DIR / name
    return json.loads(path.read_text(encoding="utf-8"))


def write_json_report(name: str, payload: Any) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    path = REPORT_DIR / name
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return path
