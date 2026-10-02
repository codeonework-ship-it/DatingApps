from __future__ import annotations

import pytest

from api_client import first_id
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
    _open_first_chat(app, _match_display_name(match), str(first_id([match], "match_id", "id")))

    if app.is_text_visible("unlock chat", timeout=3) or app.is_text_visible(
        "Chat is temporarily locked", timeout=1
    ):
        app.wait_for_qa("qa.chat.locked_banner", timeout=10)
        return

    # The gift button is the composer's "Send a gift" icon (chat_chrome.dart);
    # it opens the tray titled "A little something for them".
    if not app.maybe_tap("Send a gift", timeout=8):
        pytest.skip("Gift tray button is not available in this build/state")

    app.wait_for_text("A little something for them", timeout=15)
    app.wait_for_text("Close gifts", timeout=5)
    app.save_artifact("chat_gift_tray_open")
    app.tap_text("Close gifts")
    app.wait_for_text_gone("A little something for them", timeout=10)
    app.driver.back()
