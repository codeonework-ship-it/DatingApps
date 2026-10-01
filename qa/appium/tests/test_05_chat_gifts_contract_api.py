from __future__ import annotations

import uuid

import pytest

from api_client import extract_items, first_id
from matrix import load_fixture


def _load_matrix() -> list[dict]:
    return [
        *load_fixture("chat_matrix.json"),
        *load_fixture("gifts_matrix.json"),
    ]


@pytest.mark.contract
@pytest.mark.chat_matrix
@pytest.mark.gift_matrix
@pytest.mark.parametrize("case", _load_matrix(), ids=lambda case: case["name"])
def test_chat_gift_wallet_contract_matrix(api_client, qa_user_id, case):
    kind = case["kind"]

    if kind == "gift_catalog":
        response = api_client.get("/chat/gifts").require_status(200)
        gifts = extract_items(response.body, "gifts")
        assert len(gifts) >= int(case.get("min_gifts", 0)), response.body
        assert all(item.get("id") or item.get("gift_id") for item in gifts), response.body
        return

    if kind == "wallet_balance":
        response = api_client.get(f"/wallet/{qa_user_id}/coins").require_status(200, 404)
        if response.status == 200 and isinstance(response.body, dict):
            assert "wallet" in response.body or "balance" in response.body or "coins" in response.body, response.body
        return

    if kind == "wallet_audit":
        response = api_client.get(f"/wallet/{qa_user_id}/coins/audit", query={"limit": 10}).require_status(200, 404)
        if response.status == 200 and isinstance(response.body, dict):
            assert "audit" in response.body or "items" in response.body or "events" in response.body, response.body
        return

    if kind == "matches":
        response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
        matches = extract_items(response.body, "matches")
        assert len(matches) >= int(case.get("min_matches", 0)), response.body
        return

    if kind == "message_list":
        match_id = _first_match_id(api_client, qa_user_id)
        api_client.get(f"/chat/{match_id}/messages", query={"limit": 10}).require_status(200, 423)
        return

    if kind == "gift_telemetry":
        match_id = _first_match_id(api_client, qa_user_id)
        response = api_client.post(
            f"/chat/{match_id}/gifts/events",
            body={
                "event_name": "gift_panel_opened",
                "user_id": qa_user_id,
                "match_id": match_id,
                "catalog_count": 0,
                "idempotency_key": f"appium-telemetry-{uuid.uuid4()}",
            },
        ).require_status(202, 404)
        if response.status == 202 and isinstance(response.body, dict):
            assert response.body.get("accepted", True) is not False, response.body
        return

    raise AssertionError(f"Unknown chat/gift matrix kind: {kind}")


def _first_match_id(api_client, qa_user_id: str) -> str:
    response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
    matches = extract_items(response.body, "matches")
    match_id = first_id(matches, "match_id", "id")
    assert match_id, f"No match_id/id found in matches payload: {response.body}"
    return str(match_id)