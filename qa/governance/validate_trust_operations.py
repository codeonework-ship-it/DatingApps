#!/usr/bin/env python3
"""Validate privacy, safety and production trust policy plus code anchors."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/trust_operations.v1.json"


class TrustContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise TrustContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.trust-operations", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    controls = contract["member_controls"]
    require(controls["deletion"]["grace_days"] == 14, "deletion grace must be 14 days")
    require(controls["export"]["payload_retention_days"] == 7, "exports must expire after 7 days")
    require(controls["export"]["partial_exports_may_report_success"] is False, "partial exports cannot succeed")
    classes = {item["class"] for item in contract["retention_policy"]}
    required_classes = {"identity_documents_and_selfies", "sos_contact_delivery_snapshot", "production_backups", "moderation_safety_and_security_audit", "revoked_authentication_sessions"}
    require(required_classes.issubset(classes), "retention policy is missing a sensitive data class")
    slos = contract["service_levels"]
    require(slos["sos_response_minutes"] == {"critical": 2, "high": 5, "medium": 15, "low": 30}, "SOS deadlines drifted")
    require(slos["appeal_resolution_hours"] == 48, "appeal SLA drifted")
    require(set(contract["backlog_disposition"]) == {f"PEN-{n:02d}" for n in (5, 6, 7, 8, 20, 37, 38, 39)}, "epic mapping incomplete")


def validate_anchors() -> None:
    anchors = {
        "backend/internal/bff/mobile/server_security.go": ("authorizeRealtimeSession", "u.deletion_requested_at IS NULL"),
        "backend/internal/bff/mobile/chat_realtime_repository.go": ("blocked_users", "m.unmatched_at IS NULL"),
        "backend/internal/bff/mobile/account_lifecycle_repository.go": ("return nil, fmt.Errorf(\"export %s", "user_id_1"),
        "backend/internal/bff/mobile/account_erasure.go": ("verification_evidence", "audio_storage_path=NULL"),
        "backend/internal/bff/mobile/safety_repository_postgres.go": ("sos_delivery_outbox", "moderation.appeal.status_changed"),
        "backend/internal/platform/config/config.go": ("MEDIA_MODERATION_PROVIDER must be configured", "SOS_DELIVERY_WEBHOOK_URL is required"),
        "backend/scripts/076_privacy_safety_trust_operations.sql": ("sos_delivery_metrics", "status_change_in_app_and_configured_push"),
    }
    missing = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "trust implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "trust operations production decision is not GO")
    staffing = contract["staffing"]
    shifts = staffing["launch_coverage_hours"] // staffing["shift_hours"]
    for field in ("named_primary_by_shift", "named_backup_by_shift", "named_appeals_owner_by_shift", "named_sos_on_call_by_shift"):
        require(len(staffing[field]) == shifts and all(staffing[field]), f"{field} must name all {shifts} shifts")
    for field in ("trust_and_safety_manager", "incident_commander", "paging_rehearsal_evidence"):
        require(bool(staffing[field]), f"{field} is required")
    require(not contract["production_acceptance"]["blocking_evidence"], "production evidence remains outstanding")


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
        validate_anchors()
        if args.mode == "launch":
            validate_launch(contract)
        result.update(passed=True, decision=contract["production_acceptance"]["decision"])
    except (TrustContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"trust operations {args.mode} gate passed (production {result['decision']})")
        return 0
    print("trust operations gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
