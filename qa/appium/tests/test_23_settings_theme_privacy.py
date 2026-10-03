"""Settings theme strip and Privacy & Safety switches.

Theme: SNOW_ROSE_GOTHIC_THEMES_AND_REWARD_BURSTS_2026-10-01 /
EMPATHETIC_REACTIONS_AND_TODAY_THEME_2026-10-01 -- choosing a look persists
`settings.theme` as `<mode>:<preset>`; verified through GET /settings/{me}.
Privacy: friend search opt-out (FRIENDS doc, migration 120) is verified via
GET /friends/{me}/search-visibility and a counterpart's search; the crash
report switch is a device preference (CLIENT_ERROR_REPORTING doc) verified in
the debug build's shared preferences.
"""

from __future__ import annotations

import re
import time

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.theme_privacy]


def _wait_api(predicate, timeout: float = 15, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _stored_theme(member) -> str:
    return str(
        member.api.get(f"/settings/{member.user_id}").require_status(200).body["settings"].get("theme") or ""
    )


def _open_theme_strip(app):
    app.go_today()
    app.open_tab("Settings")
    app.wait_for_tab("settings")
    app.scroll_to_text("Make it yours", timeout=30)
    # scroll_to_text's swipes can leave the page flinging; a tap on a moving
    # Flutter list only stops it, so the first card tap would be lost.
    time.sleep(1.2)
    return app.wait_for_qa("qa.settings.theme_presets", timeout=10)


def _tap_look(app, preset_id: str) -> None:
    """Swipe the horizontal strip until the look's card is on screen, then tap it."""
    label = f"qa.settings.theme_preset.{preset_id}"
    size = app.driver.get_window_size()
    for direction in ("left", "right"):
        for _ in range(8):
            cards = app.find_qa_containing(label)
            if cards:
                rect = cards[0].rect
                # The strip paints with Clip.none, so a card scrolled past the
                # viewport edge still reports a thin on-screen sliver that does
                # not take taps. Only a card at full width is really in view.
                widths = [c.rect["width"] for c in app.find_qa_containing("qa.settings.theme_preset.")]
                full = rect["width"] >= 0.95 * max(widths)
                if full and rect["x"] >= 0 and rect["x"] + rect["width"] <= size["width"]:
                    time.sleep(0.8)  # let the strip/page settle before tapping
                    cards = app.find_qa_containing(label)
                    if cards and cards[0].rect == rect:
                        cards[0].click()
                        return
                    continue
            # Swipe along the row of cards (the strip's own semantics node
            # also spans the mode selector above it).
            row = app.find_qa_containing("qa.settings.theme_preset.")
            if not row:
                app.scroll_to_text("qa.settings.theme_preset.", timeout=10)
                row = app.find_qa_containing("qa.settings.theme_preset.")
            card = row[0].rect
            y = int(card["y"] + card["height"] / 2)
            start, end = (0.8, 0.25) if direction == "left" else (0.2, 0.75)
            app.driver.swipe(int(size["width"] * start), y, int(size["width"] * end), y, 600)
            time.sleep(0.8)
    raise AssertionError(f"theme card {preset_id!r} never came into view")


def _wait_title_card_gone(app) -> None:
    # The "Now showing" title card dismisses itself (or on a tap).
    deadline = time.time() + 12
    while time.time() < deadline and app.driver.find_elements(*app.ui_desc_contains("Theme preview")):
        time.sleep(0.5)


def _card_selected(app, preset_id: str) -> bool:
    cards = app.find_qa_containing(f"qa.settings.theme_preset.{preset_id}")
    return bool(cards) and (cards[0].get_attribute("selected") or "").lower() == "true"


def test_theme_strip_snow_and_gothic_persist_to_account(app, device_member):
    original = _stored_theme(device_member)
    mode = original.split(":")[0] or "auto"
    try:
        _open_theme_strip(app)
        for preset in ("snow", "gothic"):
            _tap_look(app, preset)
            _wait_title_card_gone(app)
            stored = _wait_api(lambda: _stored_theme(device_member).endswith(f":{preset}") and _stored_theme(device_member))
            assert stored == f"{mode}:{preset}", f"theme not persisted: {_stored_theme(device_member)!r}"
            assert _wait_api(lambda: _card_selected(app, preset), timeout=8), f"{preset} card not marked selected"
            app.save_artifact(f"settings_theme_{preset}")

        # Back to the original look through the UI.
        restore = original.split(":")[1] if ":" in original else "classic"
        _tap_look(app, restore)
        _wait_title_card_gone(app)
        assert _wait_api(lambda: _stored_theme(device_member) == original), (
            f"restore failed: {_stored_theme(device_member)!r} != {original!r}"
        )
    finally:
        if _stored_theme(device_member) != original:
            device_member.api.patch(f"/settings/{device_member.user_id}", {"theme": original})


def _visibility(member) -> bool | None:
    return member.api.get(f"/friends/{member.user_id}/search-visibility").require_status(200).body.get("visible")


def _found_by(searcher, target) -> bool:
    body = searcher.api.get(f"/friends/{searcher.user_id}/search", query={"q": target.username}).require_status(200).body
    return any(r.get("user_id") == target.user_id for r in body.get("results", []))


def _switch(app, title: str):
    app.scroll_to_text(title, timeout=20)
    for node in app.driver.find_elements(*app.ui_class("android.widget.Switch")):
        if title in (node.get_attribute("content-desc") or "") + (node.get_attribute("text") or ""):
            return node
    # SwitchListTile merges into one node that carries the title.
    return app.element_desc_contains(title, timeout=5)


def _checked(node) -> bool:
    return (node.get_attribute("checked") or "").lower() == "true"


def test_friend_search_visibility_opt_out_round_trip(app, device_member, counterpart_factory):
    searcher = counterpart_factory("sv", "Sami Searcher")
    if _visibility(device_member) is not True:
        device_member.api.put(f"/friends/{device_member.user_id}/search-visibility", {"visible": True})
    assert _found_by(searcher, device_member), "precondition: the device member is searchable"
    counterpart_factory.cleanups.append(
        lambda: device_member.api.put(f"/friends/{device_member.user_id}/search-visibility", {"visible": True})
    )

    app.open_settings_entry("Privacy & Safety")
    title = "Let people find me in friend search"
    switch = _switch(app, title)
    assert _checked(switch), "the switch should start on (default)"
    switch.click()
    assert _wait_api(lambda: _visibility(device_member) is False), "opt-out not saved"
    assert not _checked(_switch(app, title))
    assert not _found_by(searcher, device_member), "opted-out member still appears in search"
    app.save_artifact("privacy_friend_search_off")

    # Friends > Add friend explains the hidden state.
    app.open_settings_entry("Friends & Connections")
    app.scroll_to_text("Add friend", timeout=15)
    app.tap_text("Add friend")
    app.wait_for_text_contains("You’re hidden from friend search", timeout=10)
    app.dismiss_sheet()

    app.open_settings_entry("Privacy & Safety")
    switch = _switch(app, title)
    assert not _checked(switch)
    switch.click()
    assert _wait_api(lambda: _visibility(device_member) is True), "opt-in not saved"
    assert _found_by(searcher, device_member), "member not searchable after opting back in"


def _pref_opt_in(app) -> str | None:
    xml = app.shared_preferences_xml()
    # Stored by the reporter as the string "1" / "0".
    match = re.search(r'name="flutter\.client_errors\.opt_in"[^>]*>([01])<', xml)
    return {"1": "true", "0": "false"}[match.group(1)] if match else None


def _has_install_id(app) -> bool:
    return 'name="flutter.client_errors.install_id"' in app.shared_preferences_xml()


def test_crash_reports_switch_persists_on_device(app):
    app.open_settings_entry("Privacy & Safety")
    title = "Share crash reports"
    switch = _switch(app, title)
    initially_on = _checked(switch)
    if not initially_on:
        switch.click()
        assert _wait_api(lambda: _pref_opt_in(app) == "true", timeout=8)
        switch = _switch(app, title)
    switch.click()
    assert _wait_api(lambda: _pref_opt_in(app) == "false", timeout=8), _pref_opt_in(app)
    assert not _checked(_switch(app, title))
    # Opting out deletes the install id (a later opt-in starts a new one).
    assert not _has_install_id(app), "install id kept after opting out"

    # Survives leaving and reopening the screen.
    app.press_back()
    app.open_settings_entry("Privacy & Safety")
    switch = _switch(app, title)
    assert not _checked(switch)
    switch.click()
    assert _wait_api(lambda: _pref_opt_in(app) == "true", timeout=8)
    assert _checked(_switch(app, title))
