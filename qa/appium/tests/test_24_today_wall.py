"""Today screen: Cover of the Week and Today's wall (TODAY_WALL_AND_COVER_OF_THE_WEEK_2026-10-01).

What the device renders is compared with what the API serves the same member:
GET /themes/cover and GET /walls/today (items in display order).
"""

from __future__ import annotations

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.today_wall]


def _item_title(item: dict) -> str:
    if item.get("kind") == "chapter":
        return str((item.get("post") or {}).get("title") or "").strip()
    return str((item.get("entry") or {}).get("caption") or "").strip()


def test_today_renders_cover_of_the_week_from_api(app, device_member):
    cover = device_member.api.get("/themes/cover").require_status(200).body.get("cover")
    app.go_today()
    app.wait_for_text_contains("A little hello", timeout=20)
    if not cover:
        assert not app.is_text_visible("COVER OF THE WEEK", timeout=5), "cover shown while the API has none"
        pytest.skip("No Cover of the Week this week for this member (API returned null)")
    entry = cover["entry"]
    first_name = str(entry.get("author_name") or "").split(" ")[0]
    app.scroll_to_text("COVER OF THE WEEK", timeout=20)
    app.element_desc_contains(f"Open the Cover of the Week by {first_name}", timeout=10)
    caption = str(entry.get("caption") or "").strip()
    if caption:
        app.wait_for_text_contains(caption[:30], timeout=10)
    app.wait_for_text("This week", timeout=10)
    app.save_artifact("today_cover_of_the_week")


def test_today_wall_matches_api_and_pages(app, device_member):
    wall = device_member.api.get("/walls/today").require_status(200).body
    items = wall.get("items") or []
    app.go_today()
    app.scroll_to_text("Today’s wall", timeout=30)
    app.wait_for_text("Stories and photos members loved — new picks every day", timeout=10)
    if not items:
        # Empty wall: the calm card invites the member to write or share,
        # and no carousel position is shown.
        app.scroll_into_middle("Your wall fills up as members share stories and photos they love")
        app.wait_for_text("Write a chapter", timeout=10)
        app.wait_for_text("Share a photo", timeout=10)
        assert not app.driver.find_elements(*app.ui_text_contains(" / ")), "carousel position shown for an empty wall"
        app.save_artifact("today_wall_empty")
        return

    total = len(items)
    app.scroll_into_middle(f"1 / {total}")
    first = _item_title(items[0])
    if first:
        app.wait_for_text_contains(first[:25], timeout=10)
    app.save_artifact("today_wall_first")
    if total > 1:
        app.tap_text("Next pick")
        app.wait_for_text(f"2 / {total}", timeout=10)
        second = _item_title(items[1])
        if second:
            app.wait_for_text_contains(second[:25], timeout=10)
        app.tap_text("Previous pick")
        app.wait_for_text(f"1 / {total}", timeout=10)
    # The wall is fixed for the day: a second read returns the same order.
    again = device_member.api.get("/walls/today").require_status(200).body.get("items") or []
    assert [_item_title(i) for i in again] == [_item_title(i) for i in items]
