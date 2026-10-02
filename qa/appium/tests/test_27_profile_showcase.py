"""Profile showcase: "Writing & moments" (migration 130, profile_showcase.dart).

A member's community chapters and wall photos appear on their profile only
with their consent ("Show my public writing on my profile", Privacy & safety,
default off; GET|PUT /v1/profile/{me}/showcase/consent). The owner always sees
a preview with an "Only you can see this" card while consent is off.

Everything created here (counterpart chapter, like, consent changes) is undone
afterwards; the device member's consent is restored to its original value.
"""

from __future__ import annotations

import time
import uuid

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.theme_privacy]

SWITCH_TITLE = "Show my public writing on my profile"
CHAPTER_TITLE = "Showcase: the long way home"
CHAPTER_BODY = "I took the slow train along the coast and talked to a stranger about bread for an hour."


def _consent(member) -> bool:
    return bool(member.api.get(f"/profile/{member.user_id}/showcase/consent").require_status(200).body.get("visible"))


def _set_consent(member, visible: bool) -> None:
    body = member.api.put(f"/profile/{member.user_id}/showcase/consent", {"visible": visible}).require_status(200).body
    assert body.get("visible") is visible, body


def _wait_api(predicate, timeout: float = 10):
    deadline = time.time() + timeout
    value = predicate()
    while not value and time.time() < deadline:
        time.sleep(0.7)
        value = predicate()
    return value


@pytest.fixture
def consent_restored(device_member):
    original = _consent(device_member)
    yield original
    _set_consent(device_member, original)


def _switch(app):
    app.scroll_into_middle(SWITCH_TITLE)
    return app.element_desc_contains(SWITCH_TITLE, timeout=10)


def _checked(element) -> bool:
    return (element.get_attribute("checked") or "").lower() == "true"


def test_privacy_switch_reflects_and_persists_consent(app, device_member, consent_restored, counterpart_factory):
    # Default off: a brand-new member has not opted in.
    newcomer = counterpart_factory("scd")
    assert _consent(newcomer) is False, "showcase consent must default to off"

    _set_consent(device_member, False)
    app.open_settings_entry("Privacy & Safety")
    switch = _switch(app)
    assert not _checked(switch), "switch shows on while the account says off"
    app.save_artifact("privacy_profile_showcase_off")

    switch.click()
    assert _wait_api(lambda: _consent(device_member) is True), "turning the switch on did not persist"
    assert _wait_api(lambda: _checked(_switch(app)), timeout=5)

    # Re-open the screen: the stored value comes back.
    app.press_back()
    app.wait_for_tab("settings")
    app.scroll_into_middle("Privacy & Safety")
    app.tap_text("Privacy & Safety")
    assert _checked(_switch(app)), "consent on was not shown after re-opening Privacy & Safety"
    app.save_artifact("privacy_profile_showcase_on")

    _switch(app).click()
    assert _wait_api(lambda: _consent(device_member) is False), "turning the switch off did not persist"
    app.press_back()
    app.wait_for_tab("settings")


def _labels_down_the_page(app, max_swipes: int = 14) -> list[str]:
    """Every label seen while scrolling the current screen to its end."""
    seen: list[str] = []
    size = app.driver.get_window_size()
    x = size["width"] // 2
    previous = ""
    for _ in range(max_swipes):
        source = app.driver.page_source
        seen.extend(app.visible_labels())
        if source == previous:
            break
        previous = source
        app.driver.swipe(x, int(size["height"] * 0.75), x, int(size["height"] * 0.35), 500)
        time.sleep(0.6)
    return seen


def _open_liker_profile(app, name: str) -> None:
    """Profile tab → Who Liked Me → the counterpart's card."""
    app.sign_in_existing_user()
    app.go_today()
    app.open_tab("Profile")
    app.wait_for_tab("profile")
    app.scroll_into_middle("Who Liked Me")
    app.tap_text_contains("Who Liked Me")
    app.wait_for_text_contains(name, timeout=25)
    app.tap_text_contains(name)
    app.wait_for_text("INTRODUCING", timeout=20)
    app.wait_for_text_contains(name, timeout=10)


@pytest.fixture
def showcase_counterpart(device_member, counterpart_factory):
    name = f"Sage {int(time.time()) % 100000}"
    other = counterpart_factory("sc", name)
    post_id = str(uuid.uuid4())
    saved = other.api.put(
        f"/blog/posts/{post_id}",
        {"title": CHAPTER_TITLE, "body": CHAPTER_BODY, "audience": "community", "topic": "feelings",
         "expected_version": 0},
    ).require_status(200, 201).body
    version = saved["post"]["version"]
    counterpart_factory.cleanups.append(
        lambda: other.api.delete(f"/blog/posts/{post_id}", {"expected_version": version})
    )
    # The counterpart likes the device member so their profile is reachable
    # from "Who Liked Me"; afterwards the device member passes to clear it.
    other.api.post("/swipe", {"user_id": other.user_id, "target_user_id": device_member.user_id,
                              "is_like": True}).require_status(200, 201)
    counterpart_factory.cleanups.append(
        lambda: device_member.api.post("/swipe", {"user_id": device_member.user_id,
                                                  "target_user_id": other.user_id, "is_like": False})
    )
    counterpart_factory.cleanups.append(lambda: _set_consent(other, False))
    return other, name


def test_counterpart_writing_shows_only_with_their_consent(app, device_member, showcase_counterpart):
    other, name = showcase_counterpart
    assert _consent(other) is False
    hidden = device_member.api.get(f"/profile/{other.user_id}/showcase").require_status(200).body
    assert hidden.get("enabled") is False and not hidden.get("chapters"), hidden

    _open_liker_profile(app, name)
    labels = _labels_down_the_page(app)
    app.save_artifact("showcase_counterpart_consent_off")
    assert "WRITING & MOMENTS" not in labels, "showcase shown while the counterpart's consent is off"
    assert not any(CHAPTER_TITLE in label for label in labels), "chapter leaked onto the profile"

    _set_consent(other, True)
    shown = device_member.api.get(f"/profile/{other.user_id}/showcase").require_status(200).body
    assert shown.get("enabled") is True and [c["title"] for c in shown["chapters"]] == [CHAPTER_TITLE], shown

    # Re-open the profile (the showcase is fetched per visit).
    app.press_back()
    app.tap_text_contains(name, timeout=20)
    app.wait_for_text("INTRODUCING", timeout=20)
    app.scroll_into_middle("WRITING & MOMENTS")
    app.wait_for_text("In their own words", timeout=10)
    app.scroll_into_middle(CHAPTER_TITLE)
    app.save_artifact("showcase_counterpart_consent_on")
    app.scroll_into_middle("Read all their chapters")
    app.press_back()
    app.press_back()
    app.wait_for_tab("profile")


def test_own_profile_previews_hidden_writing(app, device_member, consent_restored):
    _set_consent(device_member, False)
    created = None
    mine = device_member.api.get("/blog/posts", query={"scope": "mine"}).require_status(200).body.get("posts", [])
    community = [p for p in mine if p.get("audience") == "community" and p.get("moderation_state") == "active"]
    if not community:
        post_id = str(uuid.uuid4())
        saved = device_member.api.put(
            f"/blog/posts/{post_id}",
            {"title": CHAPTER_TITLE, "body": CHAPTER_BODY, "audience": "community", "topic": "feelings",
             "expected_version": 0},
        ).require_status(200, 201).body
        created = (post_id, saved["post"]["version"])
    try:
        preview = device_member.api.get(f"/profile/{device_member.user_id}/showcase").require_status(200).body
        assert preview.get("enabled") is False and preview.get("chapters"), preview
        title = preview["chapters"][0]["title"]

        app.sign_in_existing_user()
        app.go_today()
        app.open_tab("Profile")
        app.wait_for_tab("profile")
        app.scroll_into_middle("WRITING & MOMENTS")
        app.wait_for_text("Your public writing & photos", timeout=10)
        app.scroll_into_middle("Only you can see this")
        app.wait_for_text_contains("hidden from your profile", timeout=10)
        app.save_artifact("showcase_own_preview_hidden")
        app.scroll_into_middle(title[:30])
    finally:
        if created:
            device_member.api.delete(f"/blog/posts/{created[0]}", {"expected_version": created[1]})
