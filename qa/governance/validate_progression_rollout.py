#!/usr/bin/env python3
"""Validate Level/XP production-rollout controls and launch evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/progression_production_rollout.v1.json"


class ProgressionRolloutContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ProgressionRolloutContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.progression-production-rollout", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    sequence = contract["rollout_sequence"]
    require([item["stage"] for item in sequence] == ["dogfood", "five_percent", "twenty_five_percent", "general_availability"], "rollout stage order changed")
    require([item["rollout_percent"] for item in sequence] == [1, 5, 25, 100], "rollout percentages changed")
    require(all(item["minimum_exposed_members"] > 0 and item["minimum_observation_days"] >= 7 for item in sequence), "stage exposure requirements are incomplete")
    gates = contract["stage_entry_gates"]
    require(set(gates) == {"cohort_safety", "retention", "fraud", "xp_economy", "projection", "decision_record"}, "stage entry gates are incomplete")
    owners = contract["stop_policy"]["owners"]
    require(set(owners) == {"progression_runtime", "member_safety", "product_decision"} and all(owners.values()), "safety-stop ownership is incomplete")
    require(contract["stop_policy"]["pause_minutes"] <= 15, "safety stop must pause within 15 minutes")
    require(contract["fraud_tuning"]["response_action"] == "review_only", "fraud tuning must remain review-only")
    local = contract["local_controls"]
    require(len({item["id"] for item in local}) == 8, "local rollout controls must have eight unique rows")
    require(all(item["status"] == "passed" and item["evidence"] for item in local), "local rollout controls require evidence")
    production = contract["production_acceptance_matrix"]
    require(len({item["id"] for item in production}) == 8, "production rollout matrix must have eight unique rows")
    require(set(contract["backlog_disposition"]) == {"PEN-45", "XP-005", "XP-006", "XP-007"}, "progression backlog mapping is incomplete")


def validate_anchors(contract: dict[str, Any]) -> None:
    for item in contract["local_controls"]:
        require((ROOT / item["evidence"]).is_file(), f"missing local evidence: {item['evidence']}")
    load_evidence = next(item["evidence"] for item in contract["local_controls"] if item["id"] == "PROG-PROJECTION-LOAD")
    load_report = json.loads((ROOT / load_evidence).read_text(encoding="utf-8"))
    require(load_report.get("passed") is True, "local projection load report did not pass")
    require(load_report.get("dead_letters") == 0 and load_report.get("projection_mismatches") == 0, "local projection load has integrity failures")
    anchors = {
        "backend/scripts/079_progression_production_rollout.sql": (
            "enforce_rollout_stage_transition", "rollout_stage_history", "fraud_rule_policies", "production_health"
        ),
        "backend/internal/bff/mobile/level_progression.go": (
            "validateProgressionRolloutChange", "response_action", "productionHealth", "refreshProductionMetrics"
        ),
        "backend/internal/platform/observability/metrics_http.go": (
            "ProgressionQueueDepth", "ProgressionCompletionP95", "ProgressionOpenFraudCases"
        ),
        "backend/observability/prometheus/rules/progression-production.yml": (
            "VerifiedDatingProgressionProjectionLagHigh", "VerifiedDatingProgressionDeadLetters", "owner: trust-safety-oncall"
        ),
        "backend/scripts/level_rollout_cohort_report.sh": (
            "LEVEL_ROLLOUT_REQUIRE_EXPOSURE", "SAFETY STOP NOT PROVEN"
        ),
        "qa/load/run_progression_projection_load_gate.sh": (
            "PROGRESSION_LOAD_DATABASE_URL", "progression_load_", "--force"
        ),
        "qa/progression/validate_stage_evidence.py": (
            "moderation_report_denominator", "fraud_false_positive_rate", "projection_dead_letters", "decision"
        ),
        "control-panel/templates/control_panel/progression.html": (
            "Safety-stop owner", "Reviewed stage", "Fraud tuning"
        ),
    }
    missing: list[str] = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "progression rollout implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "progression production decision is not GO")
    incomplete = [item["id"] for item in contract["production_acceptance_matrix"] if item["status"] != "passed" or not item["evidence"]]
    require(not incomplete, "progression production evidence is incomplete: " + ", ".join(incomplete))


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
    except (ProgressionRolloutContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"progression rollout {args.mode} gate passed (production {result['decision']})")
        return 0
    print("progression rollout gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
