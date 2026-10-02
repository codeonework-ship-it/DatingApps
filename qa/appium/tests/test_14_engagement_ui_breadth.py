from __future__ import annotations

import time

import pytest

# (tile title on the Engage hub, a title the opened screen shows, runtime flag
# that gates the tile or None). Titles come from engagement_hub_screen.dart and
# each destination screen's own AppBar / page header (2026-10-02 build).
ENGAGEMENT_SURFACES = (
    ("Daily Prompt Streak", "Daily Prompt Streak", "daily_prompts_enabled"),
    ("Guided Voice Icebreakers", "A voice, a little closer", "voice_icebreakers_enabled"),
    ("Local Circle Challenges", "Local Circle Challenges", "circles_enabled"),
    ("Group Coffee Poll", "Group Coffee Polls", "group_coffee_polls_enabled"),
    ("Groups", "Find your people.", "groups_enabled"),
    ("Conversation Rooms", "LIVE CHAT", "rooms_enabled"),
    ("Friends & Introductions", "Your people", None),
    ("Trust Badges", "Trust Badges", None),
    ("Trust Filters", "Trust Filters", None),
)


def _tap_tile(app, tile: str) -> None:
    """Tap the hub tile itself: its node reads "<title>\n<subtitle>".

    A plain contains-match on short titles ("Groups") can hit another node
    first, so match the tile's own label prefix.
    """
    xpath = f'//*[@clickable="true" and starts-with(@content-desc, "{tile}\n")]'
    deadline = time.time() + 10
    while time.time() < deadline:
        nodes = app.driver.find_elements("xpath", xpath)
        if nodes:
            nodes[0].click()
            return
        time.sleep(0.5)
    raise AssertionError(f"Engage tile {tile!r} is not tappable")


def _flags(api_client) -> dict[str, bool]:
    body = api_client.get("/config/flags").require_status(200).body
    return {f["key"]: bool(f.get("value_bool")) for f in body.get("flags", [])}


@pytest.mark.requires_appium
@pytest.mark.engagement_ui
def test_engagement_hub_opens_every_documented_surface(app, api_client):
    flags = _flags(api_client)
    app.sign_in_existing_user()
    app.go_today()
    app.open_tab("Engage")
    app.wait_for_tab("engage")
    # The hub's page header (eyebrow ENGAGE) — there is no "Engagement" title.
    # The tab keeps its scroll offset between visits, so scroll to it.
    app.scroll_to_text("Make something together.", timeout=30)

    opened = []
    for tile, screen_title, flag in ENGAGEMENT_SURFACES:
        if flag and not flags.get(flag, False):
            continue
        app.scroll_into_middle(tile)
        _tap_tile(app, tile)
        app.assert_any_text_visible(screen_title, timeout=20)
        app.press_back()
        # Back pops the surface and leaves the Engage tab selected.
        app.wait_for_tab("engage")
        opened.append(tile)
    assert len(opened) >= 3, f"too few Engage surfaces enabled to be meaningful: {opened}"
