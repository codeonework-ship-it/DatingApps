"""Today's "YOUR STORY" card (profile_story_nudge.dart, 2026-10-02).

The card explains profile stories, shows how many of the three are written
and opens the story editor ("A little more you"). With no stories it offers
"Write your first story" and up to three prompt ideas; after one story is
published (PUT /v1/profile/{id}/stories) it reads "1 of 3 stories shared".

The account's stories are read first and put back afterwards.
"""

from __future__ import annotations

import time

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.today_wall]

STORY_TEXT = "Sunday market coffee with my notebook, before anyone else is awake."


def _stories(member) -> dict:
    return member.api.get(f"/profile/{member.user_id}/stories").require_status(200).body


def _put_stories(member, stories: list[dict], published: bool) -> dict:
    version = int(_stories(member).get("version") or 0)
    return member.api.put(
        f"/profile/{member.user_id}/stories",
        {"stories": stories, "published": published, "expected_version": version},
    ).require_status(200).body


@pytest.fixture
def original_stories(device_member):
    before = _stories(device_member)
    original = [
        {k: v for k, v in s.items() if k in ("prompt_id", "text", "content", "photo_id", "photo_description")}
        for s in before.get("stories") or []
    ]
    published = bool(before.get("published"))
    yield original
    _put_stories(device_member, original, published)
    after = _stories(device_member)
    assert [s.get("prompt_id") for s in after.get("stories") or []] == [s["prompt_id"] for s in original]


def _story_card_into_view(app, text: str) -> None:
    app.go_today()
    app.scroll_into_middle("YOUR STORY")
    app.scroll_into_middle(text)


def _pull_to_refresh(app) -> None:
    """Scroll Today to the top and pull down (RefreshIndicator)."""
    size = app.driver.get_window_size()
    x = size["width"] // 2
    for _ in range(8):
        if app.is_text_visible("TODAY", timeout=1) and app.is_text_visible("A little hello", timeout=1):
            break
        app.driver.swipe(x, int(size["height"] * 0.3), x, int(size["height"] * 0.85), 300)
    app.driver.swipe(x, int(size["height"] * 0.25), x, int(size["height"] * 0.8), 700)
    time.sleep(3)


def test_story_card_empty_state_opens_editor(app, device_member, original_stories):
    if original_stories:
        _put_stories(device_member, [], False)
    app.go_today()
    _pull_to_refresh(app)
    _story_card_into_view(app, "Tell a little more of your story")
    app.wait_for_text("Ideas to start with", timeout=10)
    # Three unused prompts are offered as ideas.
    app.wait_for_text("A small thing I always make time for", timeout=10)
    assert not app.is_text_visible("stories shared", timeout=1)
    app.scroll_into_middle("Write your first story")
    app.save_artifact("today_story_card_empty")
    app.tap_text("Write your first story")
    app.wait_for_text("A little more you", timeout=20)
    app.save_artifact("today_story_editor_open")
    app.press_back()
    app.wait_for_tab("today")


def test_story_card_counts_a_published_story(app, device_member, original_stories):
    _put_stories(device_member, [{"prompt_id": "little_joy", "text": STORY_TEXT}], True)
    app.go_today()
    _pull_to_refresh(app)
    refreshed = True
    try:
        _story_card_into_view(app, "1 of 3 stories shared")
    except Exception:  # noqa: BLE001 - pull-to-refresh did not update the card
        refreshed = False
    if not refreshed:
        # Re-open: the editor round trip invalidates the card's provider.
        app.save_artifact("today_story_card_stale_after_refresh")
        _story_card_into_view(app, "Tell a little more of your story")
        app.tap_text("Write your first story")
        app.wait_for_text("A little more you", timeout=20)
        app.press_back()
        app.wait_for_tab("today")
        _story_card_into_view(app, "1 of 3 stories shared")
    # The latest prompt is quoted and the action becomes "Add another story".
    app.wait_for_text_contains("A small thing I always make time for", timeout=10)
    app.scroll_into_middle("Add another story")
    assert not app.is_text_visible("Write your first story", timeout=1)
    app.save_artifact("today_story_card_one_of_three")
    assert refreshed, (
        "Pull-to-refresh on Today did not refresh the YOUR STORY card; it only "
        "updated after re-opening the story editor"
    )
