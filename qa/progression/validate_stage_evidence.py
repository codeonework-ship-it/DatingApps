#!/usr/bin/env python3
"""Fail-closed validator for one real Level/XP rollout-stage review."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "documents/contracts/progression_production_rollout.v1.json"


class StageEvidenceError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise StageEvidenceError(message)


def validate_stage_evidence(contract: dict[str, Any], evidence: dict[str, Any], stage: str) -> None:
    stages = {item["stage"]: item for item in contract["rollout_sequence"]}
    require(stage in stages, f"unknown rollout stage: {stage}")
    expected = stages[stage]
    require(evidence.get("stage") == stage, "evidence stage does not match requested stage")
    require(evidence.get("rollout_percent") == expected["rollout_percent"], "rollout percentage does not match contract")
    require(evidence.get("exposed_members", 0) >= expected["minimum_exposed_members"], "exposed cohort is below minimum")
    require(evidence.get("observation_days", 0) >= expected["minimum_observation_days"], "observation window is too short")
    require(evidence.get("moderation_report_denominator", 0) > 0, "moderation report denominator must be nonzero")
    safety_threshold = evidence.get("safety_stop_report_rate", -1)
    report_rate = evidence.get("moderation_report_rate", 1)
    require(0 <= safety_threshold <= 0.05, "safety-stop report threshold is outside the approved maximum")
    require(0 <= report_rate <= safety_threshold, "cohort safety threshold breached")
    require(evidence.get("day7_retention_regression_percentage_points", 999) <= 2, "day-7 retention regression exceeds two percentage points")
    fraud_cases = evidence.get("fraud_cases_in_window", -1)
    total_cases = evidence.get("resolved_fraud_cases", -1)
    require(fraud_cases >= 0 and total_cases >= min(100, fraud_cases), "fraud review sample is incomplete")
    require(0 <= evidence.get("fraud_false_positive_rate", 1) <= 0.10, "fraud false-positive rate exceeds ten percent")
    require(evidence.get("critical_fraud_cases_over_sla", 1) == 0, "critical fraud case exceeded SLA")
    require(evidence.get("xp_inflation_rate", 1) <= 0.05, "cohort XP inflation exceeds five percent")
    require(0 <= evidence.get("projection_completion_p95_seconds", 999) <= 2, "projection completion p95 exceeds two seconds")
    require(0 <= evidence.get("projection_oldest_pending_age_seconds", 999) <= 30, "projection oldest pending age exceeds 30 seconds")
    require(evidence.get("projection_dead_letters", 1) == 0, "projection has dead letters")
    require(bool(str(evidence.get("safety_stop_owner", "")).strip()), "safety-stop owner is missing")
    require(bool(str(evidence.get("evidence_uri", "")).strip()), "evidence URI is missing")
    require(len(str(evidence.get("decision_note", "")).strip()) >= 10, "decision note is missing")
    require(evidence.get("decision") == "promote", "stage decision is not promote")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", required=True)
    parser.add_argument("--evidence", required=True, type=Path)
    args = parser.parse_args()
    try:
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        evidence = json.loads(args.evidence.read_text(encoding="utf-8"))
        validate_stage_evidence(contract, evidence, args.stage)
    except (StageEvidenceError, OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        print(f"progression stage evidence failed: {exc}", file=sys.stderr)
        return 1
    print(f"progression stage evidence passed: {args.stage}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
