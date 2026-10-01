#!/usr/bin/env python3
"""Validate approved product semantics and complete-screen acceptance evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/product_screen_acceptance.v1.json"


class ProductScreenContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ProductScreenContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.product-rules-screen-acceptance", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    rules = contract["product_rules"]
    require(set(rules) == {"activity", "discovery", "chat", "prompts_and_nudges", "groups_and_friends", "kpis"}, "product rule domains are incomplete")
    require(rules["activity"]["timeout_seconds"] == 120, "activity timeout must be 120 seconds")
    require(rules["groups_and_friends"]["friend_consent"], "friend consent rule is required")
    controls = contract["local_acceptance_controls"]
    require(len({item["id"] for item in controls}) == 11, "local acceptance matrix must have eleven unique controls")
    require(all(item["status"] == "passed" and item["evidence"] for item in controls), "local controls must pass with evidence")
    devices = contract["representative_device_matrix"]
    require(len({item["id"] for item in devices}) == 6, "representative device matrix must have six unique rows")
    local_device = contract["local_device_execution"]
    require(local_device["status"] == "passed" and len(local_device["cases"]) == 3, "local Android resilience execution is incomplete")
    require(set(contract["backlog_disposition"]) == {f"PEN-{value}" for value in (28, 29, 30, 31, 32, 33, 34, 44)}, "product acceptance backlog mapping is incomplete")


def validate_anchors(contract: dict[str, Any]) -> None:
    for item in contract["local_acceptance_controls"]:
        require((ROOT / item["evidence"]).is_file(), f"missing evidence: {item['evidence']}")
    require((ROOT / contract["local_device_execution"]["evidence"]).is_file(), "missing local device execution report")
    anchors = {
        "backend/internal/bff/mobile/store.go": (
            "activitySessionDuration             = 120 * time.Second",
            "activitySessionMaxThisOrThatPerWeek = 2",
            "dailyPromptEditWindow             = 10 * time.Minute",
            "dailyPromptMilestones = []int{3, 7}",
            "groupCoffeePollMaxParticipants    = 4",
            "decideFriendRequest",
        ),
        "backend/internal/bff/mobile/activity_repository.go": ("normalizeActivitySessionType",),
        "backend/internal/bff/mobile/server.go": ("delete window expired (24h)", "/friends/{userID}/{friendUserID}/decision"),
        "app/lib/features/messaging/screens/chat_screen.dart": ("_deleteUndoWindow = Duration(seconds: 4)",),
        "app/lib/core/auth/auth_session_store.dart": ("FlutterSecureStorage", "readNative", "persistNative"),
        "app/lib/main.dart": ("_restorePersistedSession", "/auth/refresh"),
        "app/test/features/responsive/screen_matrix_test.dart": ("TextScaler.linear(1.3)",),
        # The semantics pass moved into the shared harness that both the layout
        # matrix and the accessibility suite pump through.
        "app/test/features/responsive/screen_matrix_harness.dart": ("ensureSemantics",),
        "qa/appium/tests/test_10_resilience_edges.py": ("test_process_death_restores_authenticated_session", "font_scale", "1.3"),
        "documents/COMMAND_CENTER_EPICS_COMPLETION_2026-09-27.md": ("rolling 24-hour", "rolling 30-day", "unavailable"),
    }
    missing: list[str] = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "product acceptance implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "product-screen production decision is not GO")
    incomplete = [item["id"] for item in contract["representative_device_matrix"] if item["status"] != "passed" or not item["evidence"]]
    require(not incomplete, "representative-device evidence is incomplete: " + ", ".join(incomplete))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--mode", choices=("contract", "launch"), default="contract")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result: dict[str, Any] = {"passed": False, "mode": args.mode, "errors": []}
    try:
        contract = json.loads(args.contract.read_text(encoding="utf-8"))
        validate_shape(contract)
        validate_anchors(contract)
        if args.mode == "launch":
            validate_launch(contract)
        result.update(passed=True, decision=contract["production_acceptance"]["decision"])
    except (ProductScreenContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"product screen acceptance {args.mode} gate passed (production {result['decision']})")
        return 0
    print("product screen acceptance gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
