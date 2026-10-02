#!/usr/bin/env python3
"""Validate Connect's release contract and its critical implementation anchors."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/release_contract.v1.json"


class ContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.release-contract", "unexpected contract_id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", str(contract.get("contract_version", ""))) is not None, "contract_version must be semantic")

    auth = contract["member_contract"]["authentication"]
    username = auth["username"]
    password = auth["password"]
    require((username["minimum_characters"], username["maximum_characters"]) == (3, 30), "username boundary must be 3-30")
    require((password["minimum_utf8_bytes"], password["maximum_utf8_bytes"]) == (8, 72), "password boundary must be 8-72 UTF-8 bytes")

    age = contract["member_contract"]["age_and_identity"]
    require((age["minimum_age_years"], age["maximum_age_years"]) == (18, 80), "age boundary must be 18-80")
    require(age["gender_selection_required"] is True, "gender must be explicitly selected")
    require(age["supported_gender_codes"] == ["M", "F", "Other"], "gender code contract changed without a versioned decision")

    profile = contract["profile_contract"]
    require(profile["completion_percent_required"] == 100, "publication requires complete profile")
    require(profile["approved_active_photos_required"] == 2, "publication requires two approved active photos")
    require(profile["private_draft_fallback_allowed"] is False, "foreign private-draft fallback is forbidden")

    economy = contract["economy_contract"]
    require(economy["first_release_mode"] == "disabled", "first release cannot enable the separately owned economy")
    for key in ("real_money_checkout_enabled", "coin_purchase_enabled", "paid_gifts_enabled", "free_gifts_enabled"):
        require(economy[key] is False, f"{key} must remain false in first release")

    quest = contract["quest_contract"]
    require(quest["first_release_mode"] == "disabled", "quest workflow must be excluded from first release")
    require(quest["gender_based_role_assignment_allowed"] is False, "gender-based quest authorization is forbidden")
    require(quest["assisted_review_enabled"] is False, "assisted review must remain off")

    enabled = set(contract["release_scope"]["enabled_capabilities"])
    excluded = set(contract["release_scope"]["excluded_capabilities"])
    require(enabled.isdisjoint(excluded), "release capability cannot be both enabled and excluded")
    require({"real_money_billing", "digital_gifts", "quest_unlock_workflow"}.issubset(excluded), "high-risk incomplete capabilities must be excluded")

    owners = contract["ownership"]
    areas = [owner["area"] for owner in owners]
    require(len(areas) == len(set(areas)), "ownership areas must be unique")
    require(all(owner["accountable_role"] for owner in owners), "every area requires an accountable role")

    gates = contract["production_release"]["gates"]
    ids = [gate["id"] for gate in gates]
    require(len(ids) == len(set(ids)), "gate ids must be unique")
    require(all(gate["status"] in {"passed", "pending", "failed", "waived"} for gate in gates), "unsupported gate status")
    require(all(gate["evidence"] for gate in gates if gate["status"] == "passed"), "passed gates require evidence")

    expected_pen = {"PEN-14", "PEN-15", "PEN-16", "PEN-17", "PEN-25", "PEN-26", "PEN-27", "PEN-46"}
    require(set(contract["backlog_disposition"]) == expected_pen, "release epic backlog mapping is incomplete")


def validate_implementation_anchors() -> None:
    anchors: dict[str, tuple[str, ...]] = {
        "backend/internal/modules/auth/domain/username.go": (
            "^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$",
            "len(password) < 8 || len(password) > 72",
        ),
        "backend/internal/bff/mobile/server.go": (
            "if age < 18",
            "if age > 80",
            'gender != "M" && gender != "F" && gender != "Other"',
        ),
        "backend/internal/bff/mobile/public_profile.go": (
            "u.profile_completion=100",
            "media.approved_count>=2",
            "moderation_status='approved'",
            "blocked_users",
        ),
        "backend/internal/platform/config/config.go": (
            "FeatureAssistedReviewAutomation: getBool(\"FEATURE_ASSISTED_REVIEW_AUTOMATION\", false)",
        ),
        "app/lib/features/auth/providers/auth_provider.dart": (
            "utf8.encode(password).length >= 8",
            "utf8.encode(password).length <= 72",
        ),
        "app/lib/features/auth/screens/signup_screen.dart": (
            "String? _gender;",
            "passwordBytes > 72",
            # Introducer accounts carry no gender; dating accounts must still choose one.
            "if (!widget.introducer && gender == null)",
        ),
    }
    missing: list[str] = []
    for relative_path, needles in anchors.items():
        content = read_text(relative_path)
        for needle in needles:
            if needle not in content:
                missing.append(f"{relative_path}: {needle}")
    require(not missing, "implementation contract drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    release = contract["production_release"]
    require(release["decision"] == "GO", "production decision is not GO")
    require(bool(release["decision_timestamp_utc"]), "GO requires decision_timestamp_utc")

    missing_owners = [owner["area"] for owner in contract["ownership"] if owner["approval_required_for_go"] and not owner["named_owner"]]
    require(not missing_owners, "required named owners are missing: " + ", ".join(missing_owners))

    blocking = [gate["id"] for gate in release["gates"] if gate["priority"] == "P0" and gate["status"] != "passed"]
    require(not blocking, "blocking P0 gates: " + ", ".join(blocking))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--mode", choices=("contract", "launch"), default="contract")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    result: dict[str, Any] = {"contract": str(args.contract), "mode": args.mode, "passed": False, "errors": []}
    try:
        contract = json.loads(args.contract.read_text(encoding="utf-8"))
        validate_shape(contract)
        validate_implementation_anchors()
        if args.mode == "launch":
            validate_launch(contract)
        result.update({
            "passed": True,
            "contract_id": contract["contract_id"],
            "contract_version": contract["contract_version"],
            "production_decision": contract["production_release"]["decision"],
        })
    except (ContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    if result["passed"]:
        print(f"release governance {args.mode} gate passed: {result['contract_id']} v{result['contract_version']} (production {result['production_decision']})")
        return 0
    print("release governance gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
