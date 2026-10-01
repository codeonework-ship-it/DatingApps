from __future__ import annotations

import uuid

import pytest

from api_client import extract_items, first_id, pick_value
from matrix import load_fixture


def _first_match(api_client, qa_user_id) -> tuple[str, str | None]:
    response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
    matches = extract_items(response.body, "matches")
    match_id = first_id(matches, "match_id", "id")
    assert match_id, f"No match_id/id found in matches payload: {response.body}"
    receiver_id = None
    for item in matches:
        if str(pick_value(item, "match_id", "id")) == match_id:
            receiver_id = pick_value(item, "target_user_id", "user_id", "userId")
            break
    return match_id, str(receiver_id) if receiver_id else None


@pytest.mark.contract
@pytest.mark.unlock_matrix
@pytest.mark.parametrize("case", load_fixture("unlock_matrix.json"), ids=lambda case: case["name"])
def test_unlock_engagement_contract_matrix(api_client, appium_config, qa_user_id, case):
    if case.get("mutating") and not appium_config.enable_mutating_matrix:
        pytest.skip("Set QA_ENABLE_MUTATING_MATRIX=true to run mutating engagement matrix rows")

    kind = case["kind"]
    match_id, receiver_id = _first_match(api_client, qa_user_id)

    if kind == "unlock_state":
        response = api_client.get(f"/matches/{match_id}/unlock-state").require_status(200, 404)
        if response.status == 200:
            assert isinstance(response.body, dict), response.body
            assert pick_value(response.body, "match_id") == match_id, response.body
            assert "chat_unlocked" in response.body or "unlock_state" in response.body, response.body
        return

    if kind == "quest_workflow":
        response = api_client.get(f"/matches/{match_id}/quest-workflow").require_status(200, 404)
        if response.status == 200:
            assert isinstance(response.body, dict), response.body
        return

    if kind == "gestures_list":
        response = api_client.get(f"/matches/{match_id}/gestures").require_status(200, 404)
        if response.status == 200:
            assert isinstance(response.body, (dict, list)), response.body
        return

    if kind == "trust_badges":
        response = api_client.get(f"/users/{qa_user_id}/trust-badges").require_status(200, 404)
        if response.status == 200:
            assert isinstance(response.body, (dict, list)), response.body
        return

    if kind == "rooms":
        response = api_client.get("/rooms").require_status(200, 404)
        if response.status == 200:
            assert isinstance(response.body, (dict, list)), response.body
        return

    if kind == "activity_session":
        assert receiver_id, "Activity session sample requires a match target user id"
        start = api_client.post(
            "/activities/sessions/start",
            body={
                "match_id": match_id,
                "initiator_user_id": qa_user_id,
                "participant_user_id": receiver_id,
                "activity_type": "appium_qa_compatibility",
            },
            headers={"Idempotency-Key": f"appium-activity-{uuid.uuid4()}"},
        ).require_status(200, 404, 409, 422)
        if start.status == 200:
            body = start.body if isinstance(start.body, dict) else {}
            session_id = pick_value(body, "session_id", "id")
            if session_id:
                api_client.post(
                    f"/activities/sessions/{session_id}/submit",
                    body={"user_id": qa_user_id, "responses": ["Appium matrix response"]},
                ).require_status(200, 404, 409, 422)
                api_client.get(f"/activities/sessions/{session_id}/summary").require_status(200, 404)
        return

    raise AssertionError(f"Unknown unlock matrix kind: {kind}")
