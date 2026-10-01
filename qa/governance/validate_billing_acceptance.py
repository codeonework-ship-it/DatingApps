#!/usr/bin/env python3
"""Validate billing implementation boundaries and real-money launch evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/billing_acceptance.v1.json"
RELEASE_CONTRACT = ROOT / "documents/contracts/release_contract.v1.json"


class BillingContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BillingContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.billing-coin-economy", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    require(contract.get("currency") == "INR" and contract.get("minor_unit") == "paise", "billing currency contract drift")
    require(contract.get("owner") == "separate_billing_owner", "billing ownership drift")
    implementation = contract["implementation"]
    require(implementation["refund_and_dispute_lifecycle"] == "implemented_locally", "dispute implementation is not recorded")
    require(implementation["provider_balance_transaction_reconciliation"] == "pending", "provider settlement status is inaccurate")
    require(implementation["payout_and_bank_reconciliation"] == "pending", "payout status is inaccurate")
    require(len({item["id"] for item in contract["stripe_test_mode_acceptance"]}) == 11, "Stripe acceptance matrix must contain eleven unique cases")
    require(len({item["id"] for item in contract["financial_reconciliation_acceptance"]}) == 6, "financial reconciliation matrix must contain six unique cases")
    rewards = contract["optional_reward_mechanics"]
    require(rewards["status"] == "deferred" and rewards["launch_blocking_while_disabled"] is False, "optional rewards must remain deferred while disabled")
    require(set(contract["backlog_disposition"]) == {"PEN-01", "PEN-02", "PEN-10", "PEN-11", "PEN-12", "PEN-13"}, "billing backlog mapping is incomplete")


def validate_release_exclusion() -> None:
    release = json.loads(RELEASE_CONTRACT.read_text(encoding="utf-8"))
    economy = release["economy_contract"]
    require(economy["first_release_mode"] == "disabled", "release must keep economy disabled before billing acceptance")
    for flag in ("real_money_checkout_enabled", "coin_purchase_enabled", "paid_gifts_enabled", "free_gifts_enabled"):
        require(economy[flag] is False, f"{flag} must remain false before billing GO")


def validate_anchors() -> None:
    anchors = {
        "backend/internal/platform/payments/stripe.go": ("CreateSubscriptionCheckout", "CreatePaymentCheckout", "ParseWebhook"),
        "backend/internal/platform/payments/stripe_events.go": ("EventDisputeUpdated", "charge.dispute.closed", "charge.refunded"),
        "backend/internal/bff/mobile/billing_checkout.go": ("settleCoinCheckout", "changePlan", "settleCardUpdate"),
        "backend/internal/bff/mobile/billing_repository_postgres.go": ("func (r *billingRepository) reconcile", "chargeback_on_live_subscription", "coin_payment_without_wallet_credit"),
        "backend/scripts/stripe_test_mode_acceptance.sh": ("provider must be stripe", "replayed webhook", "charge.dispute.created"),
        "backend/scripts/072_billing_single_currency_disputes.sql": ("currency = 'INR'", "dispute_status", "previous_plan_code"),
    }
    missing: list[str] = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "billing implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "billing production decision is not GO")
    pricing = contract["pricing_approval"]
    require(pricing["status"] == "approved" and pricing["approved_by"] and pricing["approved_at"] and pricing["evidence"], "pricing approval evidence is incomplete")
    incomplete = [
        item["id"]
        for item in contract["stripe_test_mode_acceptance"] + contract["financial_reconciliation_acceptance"]
        if item["status"] != "passed" or not item["evidence"]
    ]
    require(not incomplete, "billing acceptance evidence is incomplete: " + ", ".join(incomplete))


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
        validate_release_exclusion()
        validate_anchors()
        if args.mode == "launch":
            validate_launch(contract)
        result.update(passed=True, decision=contract["production_acceptance"]["decision"])
    except (BillingContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"billing acceptance {args.mode} gate passed (production {result['decision']})")
        return 0
    print("billing acceptance gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
