#!/usr/bin/env python3
"""Validate provider implementation policy and real-device release evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "documents/contracts/provider_acceptance.v1.json"


class ProviderContractError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ProviderContractError(message)


def validate_shape(contract: dict[str, Any]) -> None:
    require(contract.get("contract_id") == "connect.calls-identity-voice-push", "unexpected contract id")
    require(re.fullmatch(r"\d+\.\d+\.\d+", contract.get("contract_version", "")) is not None, "invalid version")
    implementation = contract["implementation"]
    require(implementation["call_transport"]["public_jitsi_allowed_in_production"] is False, "public calls cannot ship")
    require(implementation["call_transport"]["member_and_room_bound_tokens"] is True, "call tokens must be scoped")
    require(implementation["identity_verification"]["evidence_delivery"] == "validated_multipart_bytes", "identity provider must receive validated bytes")
    require(implementation["voice"]["rejected_or_manual_review_audio_is_deliverable"] is False, "unapproved audio cannot play")
    matrix = contract["physical_push_matrix"]
    require(len(matrix) == 12, "push matrix must contain twelve physical-device cases")
    combinations = {(item["platform"], item["app_state"], item["event"]) for item in matrix}
    expected = {(platform, state, event) for platform in ("android", "ios") for state in ("foreground", "background", "terminated") for event in ("incoming_call", "match_nudge")}
    require(combinations == expected, "push matrix combinations are incomplete")
    require(len({item["id"] for item in matrix}) == 12, "push case ids must be unique")
    require(set(contract["backlog_disposition"]) == {"PEN-03", "PEN-04", "PEN-09", "PEN-35", "PEN-36"}, "provider epic mapping incomplete")


def validate_anchors() -> None:
    anchors = {
        "backend/internal/bff/mobile/call_room.go": ("jitsi_jwt", "callRoomToken", "context"),
        "backend/internal/bff/mobile/provider_media_review.go": ("identity_document_and_selfie", "manual_review", "postMultipart"),
        "backend/internal/bff/mobile/voice_playback.go": ("verifyVoicePlaybackToken", "no-store", "voice_moderation_events"),
        "backend/internal/bff/mobile/notification_push_sender.go": ("FCM send returned", "APNs send returned", "InvalidToken"),
        "app/lib/features/engagement/providers/voice_icebreaker_provider.dart": ("AudioPlayer", "audioUrl", "playLatest"),
        "backend/scripts/077_calls_identity_voice_providers.sql": ("voice_moderation_events", "register_event_source"),
    }
    missing = []
    for relative, needles in anchors.items():
        content = (ROOT / relative).read_text(encoding="utf-8")
        missing.extend(f"{relative}: {needle}" for needle in needles if needle not in content)
    require(not missing, "provider implementation drift:\n  " + "\n  ".join(missing))


def validate_launch(contract: dict[str, Any]) -> None:
    require(contract["production_acceptance"]["decision"] == "GO", "provider production decision is not GO")
    incomplete = [item["id"] for item in contract["physical_push_matrix"] + contract["additional_acceptance"] if item["status"] != "passed" or not item["evidence"]]
    require(not incomplete, "provider acceptance evidence is incomplete: " + ", ".join(incomplete))


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
    except (ProviderContractError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as exc:
        result["errors"].append(str(exc))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["passed"]:
        print(f"provider acceptance {args.mode} gate passed (production {result['decision']})")
        return 0
    print("provider acceptance gate failed: " + "; ".join(result["errors"]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
