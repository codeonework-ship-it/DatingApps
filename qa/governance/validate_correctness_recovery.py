#!/usr/bin/env python3
"""Validate correctness controls and production recovery evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/correctness_recovery.v1.json"


class CorrectnessContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CorrectnessContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.correctness-idempotency-recovery", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    local = contract["local_controls"]
    require(len({item["id"] for item in local}) == 7, "local control matrix must have seven unique cases")
    require(all(item["status"] == "passed" and item["evidence"] for item in local), "local controls must have evidence")
    production = contract["production_acceptance_matrix"]
    require(len({item["id"] for item in production}) == 7, "production matrix must have seven unique cases")
    require(set(contract["backlog_disposition"]) == {
        "PEN-18", "PEN-19", "PEN-21", "PEN-22", "PEN-23", "PEN-24",
        "PEN-40", "PEN-41", "PEN-42", "PEN-43",
    }, "correctness backlog mapping is incomplete")


def validate_anchors(contract: dict[str, Any]) -> None:
    for item in contract["local_controls"]:
        path = ROOT / item["evidence"]
        require(path.is_file(), f"missing local evidence: {item['evidence']}")
    anchors = {
        "backend/internal/bff/mobile/idempotency_postgres.go": ("errIdempotencyOutcomeUncertain", "reconciled"),
        "backend/internal/bff/mobile/replay_recovery.go": ("REPLAY_CURSOR_EXPIRED", "snapshot_url"),
        "backend/internal/bff/mobile/level_progression.go": ("xp_award_repair_queue", "runAwardRepairs"),
        "backend/internal/bff/mobile/server_feature_flags.go": ("FEATURE_DISABLED", "billing_enabled"),
        "app/lib/core/providers/api_client_provider.dart": ("idempotent_transport_retry", "operation_recovered"),
        "app/lib/features/messaging/providers/message_provider.dart": ("_cursorRecoveryAttempted", "lastEventSequence: 0"),
        "app/lib/features/notifications/providers/notification_provider.dart": ("_loadAuthoritativeState", "_cursorRecoveryAttempted"),
        "backend/scripts/078_correctness_recovery_contracts.sql": ("aggregate_ownership", "replay_cursor_checkpoints"),
        "qa/reliability/distributed_scale_gate.py": ("production-soak", "capacity_claim"),
        "qa/reliability/run_production_chaos_gate.sh": ("SCALE_ALLOW_CHAOS", "SCALE_CHAOS_HOOK"),
    }
    missing: list[str] = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "correctness implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "correctness production decision is not GO")
    incomplete = [
        item["id"] for item in contract["production_acceptance_matrix"]
        if item["status"] != "passed" or not item["evidence"]
    ]
    require(not incomplete, "production recovery evidence is incomplete: " + ", ".join(incomplete))


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
    except (CorrectnessContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"correctness recovery {args.mode} gate passed (production {result['decision']})")
        return 0
    print("correctness recovery gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
