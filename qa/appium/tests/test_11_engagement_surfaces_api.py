from __future__ import annotations

import time
import uuid

import pytest

from api_client import extract_items


@pytest.mark.contract
@pytest.mark.unlock_matrix
@pytest.mark.chat_matrix
def test_daily_prompt_submit_responders_and_streak_contract(api_client, qa_user_id):
    prompt_response = api_client.get(f"/engagement/daily-prompt/{qa_user_id}").require_status(200)
    assert isinstance(prompt_response.body, dict), prompt_response.body
    view = prompt_response.body.get("daily_prompt")
    assert isinstance(view, dict), prompt_response.body
    prompt = view.get("prompt") if isinstance(view.get("prompt"), dict) else {}
    prompt_id = prompt.get("id")
    assert prompt_id, prompt_response.body

    answer_text = f"Appium daily prompt answer {int(time.time())}"
    idempotency_key = f"appium-daily-prompt-{uuid.uuid4()}"
    submit_response = api_client.post(
        f"/engagement/daily-prompt/{qa_user_id}/answer",
        body={"prompt_id": prompt_id, "answer_text": answer_text},
        headers={"Idempotency-Key": idempotency_key},
    ).require_status(200, 409, 422)
    if submit_response.status != 200:
        pytest.skip(f"Daily prompt answer not accepted in current seed state: {submit_response.body}")

    submit_body = submit_response.body if isinstance(submit_response.body, dict) else {}
    submit_view = submit_body.get("daily_prompt") if isinstance(submit_body.get("daily_prompt"), dict) else {}
    assert submit_view.get("answer") or submit_view.get("streak") or submit_view.get("spark"), submit_response.body
    if isinstance(submit_view.get("streak"), dict):
        assert "current_days" in submit_view["streak"], submit_response.body

    retry_response = api_client.post(
        f"/engagement/daily-prompt/{qa_user_id}/answer",
        body={"prompt_id": prompt_id, "answer_text": answer_text},
        headers={"Idempotency-Key": idempotency_key},
    ).require_status(200)
    retry_headers = {key.lower(): value for key, value in retry_response.headers.items()}
    assert retry_headers.get("x-idempotent-replay") == "true", retry_response.headers
    assert retry_response.body == submit_response.body

    responders = api_client.get(
        f"/engagement/daily-prompt/{qa_user_id}/responders",
        query={"limit": 5, "offset": 0},
    ).require_status(200)
    assert isinstance(responders.body, dict), responders.body
    assert "responders" in responders.body or "items" in responders.body, responders.body


@pytest.mark.contract
@pytest.mark.unlock_matrix
def test_daily_prompt_responder_pagination_validation(api_client, qa_user_id):
    bad_limit = api_client.get(
        f"/engagement/daily-prompt/{qa_user_id}/responders",
        query={"limit": "bad"},
    )
    assert bad_limit.status in (400, 422), bad_limit.body

    bad_offset = api_client.get(
        f"/engagement/daily-prompt/{qa_user_id}/responders",
        query={"offset": "bad"},
    )
    assert bad_offset.status in (400, 422), bad_offset.body


@pytest.mark.contract
@pytest.mark.unlock_matrix
def test_community_groups_list_contract(api_client, qa_user_id):
    response = api_client.get(
        "/engagement/groups",
        query={"user_id": qa_user_id, "limit": 10},
    ).require_status(200, 404)
    if response.status == 404:
        pytest.skip(f"Community groups surface is unavailable in current backend: {response.body}")

    assert isinstance(response.body, dict), response.body
    groups = extract_items(response.body, "groups", "items", "data")
    assert isinstance(groups, list), response.body
    if "pagination" in response.body:
        assert isinstance(response.body["pagination"], dict), response.body
