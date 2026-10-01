from __future__ import annotations

import pytest


ENGAGEMENT_SURFACES = (
    ("Daily Prompt Streak", "Daily Prompt Streak"),
    ("Trust Badges", "Trust Badges"),
    ("Trust Filters", "Trust Filters"),
    ("Guided Voice Icebreakers", "Guided Voice Icebreakers"),
    ("Local Circle Challenges", "Local Circle Challenges"),
    ("Group Coffee Poll", "Group Coffee Polls"),
    ("Groups", "Find your people."),
    ("Conversation Rooms", "Conversation Rooms"),
    ("Friends & Activities", "Friends & Connections"),
)


@pytest.mark.requires_appium
@pytest.mark.engagement_ui
def test_engagement_hub_opens_every_documented_surface(app):
    app.sign_in_existing_user()
    app.open_tab("Engage")
    app.assert_any_text_visible("Engagement", "Daily Prompt Streak", timeout=25)

    for tile, screen_title in ENGAGEMENT_SURFACES:
        app.tap_scroll_text(tile, timeout=15)
        app.assert_any_text_visible(screen_title, timeout=20)
        app.driver.back()
        app.assert_any_text_visible("Engagement", timeout=20)
