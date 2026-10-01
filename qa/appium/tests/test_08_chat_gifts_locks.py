from __future__ import annotations

import pytest

from tests.test_04_matches_chat import (
    _first_match,
    _match_display_name,
    _open_first_chat,
)


@pytest.mark.requires_appium
@pytest.mark.chat_matrix
@pytest.mark.gift_matrix
def test_chat_gift_tray_or_locked_banner_sample(app, api_client, qa_user_id):
    match = _first_match(api_client, qa_user_id)
    app.sign_in_existing_user()
    _open_first_chat(app, _match_display_name(match))
    app.assert_any_text_visible("Chat", "Type a message", "Message", timeout=20)

    if app.is_text_visible("unlock chat", timeout=3) or app.is_text_visible(
        "Chat is temporarily locked", timeout=1
    ):
        app.wait_for_qa("qa.chat.locked_banner", timeout=10)
        return

    if not app.maybe_tap_qa("qa.chat.gift_tray_button", timeout=8):
        pytest.skip("Rose gift tray button is not available in this build/state")

    app.assert_any_text_visible("Gifts", "Send a rose gift", timeout=15)
    app.wait_for_qa("qa.chat.gift_tray", timeout=10)
