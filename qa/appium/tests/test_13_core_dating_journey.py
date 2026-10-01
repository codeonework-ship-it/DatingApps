from __future__ import annotations

import time

import pytest

from api_client import extract_items, first_id


def _first_match_id(api_client, user_id: str) -> str:
    response = api_client.get(f"/matches/{user_id}").require_status(200)
    for match in extract_items(response.body, "matches"):
        match_id = first_id([match], "match_id", "id")
        if not match_id:
            continue
        state = api_client.get(f"/matches/{match_id}/unlock-state").require_status(200)
        if isinstance(state.body, dict) and state.body.get("chat_unlocked") is True:
            return str(match_id)
    raise AssertionError(
        "The persisted-chat journey requires a synthetic match whose quest has "
        "been approved by its counterparty; no unlocked fixture was found."
    )


def _message_is_persisted(api_client, match_id: str, content: str) -> bool:
    response = api_client.get(
        f"/chat/{match_id}/messages",
        query={"limit": 100},
    ).require_status(200)
    return any(
        content == str(item.get("content") or item.get("message") or item.get("text") or "")
        for item in extract_items(response.body, "messages", "items", "data")
    )


@pytest.mark.requires_appium
@pytest.mark.core_journey
def test_username_login_discovery_match_and_chat_restart_resume(
    app,
    appium_config,
    api_client,
    qa_user_id,
):
    match_id = _first_match_id(api_client, qa_user_id)
    message = f"Appium core journey {time.time_ns()}"

    app.sign_in_existing_user()
    app.open_tab("Discover")
    app.assert_any_text_visible("Discover Matches", "Find meaningful verified matches", timeout=25)
    app.assert_any_text_visible("qa.discovery.card_root", "Ready", "No profiles", timeout=25)

    app.open_tab("Matches")
    app.assert_any_text_visible("Matches", "Your Matches", "New matches", timeout=25)
    if not app.maybe_tap_qa(f"qa.matches.match_row.{match_id}", timeout=10):
        app.tap_first_visible_text(["Chat", "Message", "Open"], timeout=10)
    app.assert_any_text_visible("Chat", "Type a message", "Message", timeout=20)

    app.type_into_qa("qa.chat.composer", message, timeout=8)
    app.hide_keyboard()
    if not app.maybe_tap_qa("qa.chat.send_button", timeout=5):
        app.tap_first_visible_text(["Send", "➤"], timeout=10)
    app.assert_any_text_visible(message, "sent", "Delivered", timeout=20)
    assert _message_is_persisted(api_client, match_id, message)

    app.driver.background_app(2)
    app.driver.activate_app(appium_config.app_package)
    app.assert_any_text_visible(message, "Chat", timeout=20)

    app.driver.back()
    app.assert_any_text_visible("Matches", "Your Matches", "New matches", timeout=20)
    app.tap_qa(f"qa.matches.match_row.{match_id}", timeout=10)
    app.assert_any_text_visible(message, timeout=20)
