"""AND-09 regression: a SnackBar action is readable on the bar.

The in-app notification banner (main_navigation_screen.dart) is a SnackBar
with an "Open" action. AND-09 was the action label sinking into the dark bar.
A synthetic counterpart sends the device member a friend request, which
raises the banner; the rendered pixels of the action are then measured on
the device screenshot: the label's colour against the bar must reach 3:1
(WCAG non-text / large-text minimum; the theme test in
app/test/core/theme/snack_bar_contrast_test.dart pins 4.5:1 for the tokens).
"""

from __future__ import annotations

import io
import time
from pathlib import Path

import pytest
from appium.webdriver.common.appiumby import AppiumBy
from PIL import Image

from seed_members import remove_friend

pytestmark = [pytest.mark.requires_appium, pytest.mark.theme_privacy]

RESULTS = Path(__file__).resolve().parents[2] / "results" / "appium"


def _luminance(rgb) -> float:
    def channel(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb[:3])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _contrast(a, b) -> float:
    la, lb = _luminance(a), _luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def test_banner_snackbar_action_is_readable(app, device_member, counterpart_factory):
    app.go_today()
    other = counterpart_factory("sb", f"Nia {int(time.time()) % 100000}")
    counterpart_factory.cleanups.append(lambda: remove_friend(other, device_member.user_id))
    other.api.post(
        f"/friends/{other.user_id}", {"friend_user_id": device_member.user_id, "source": "search"}
    ).require_status(200, 201)

    locator = (AppiumBy.XPATH, '//android.widget.Button[@content-desc="Open" or @text="Open"]')
    deadline = time.time() + 60
    actions = []
    while time.time() < deadline and not actions:
        actions = app.driver.find_elements(*locator)
        time.sleep(0.5)
    assert actions, "no notification banner with an Open action appeared for the friend request"
    rect = actions[0].rect
    png = app.driver.get_screenshot_as_png()
    RESULTS.mkdir(parents=True, exist_ok=True)
    (RESULTS / "and09_snackbar_action.png").write_bytes(png)

    image = Image.open(io.BytesIO(png)).convert("RGB")
    crop = image.crop((rect["x"], rect["y"], rect["x"] + rect["width"], rect["y"] + rect["height"]))
    crop.save(RESULTS / "and09_snackbar_action_crop.png")
    colours = crop.getcolors(maxcolors=crop.width * crop.height)
    background = max(colours)[1]  # the bar: the most common colour under the button
    best = max(_contrast(colour, background) for _, colour in colours)
    assert best >= 3.0, f"SnackBar action label contrast {best:.2f}:1 on bar {background} is unreadable"

    # Using the action dismisses the banner and opens the inbox.
    actions[0].click()
    app.wait_for_text("Read all", timeout=10)
    app.press_back()
    app.wait_for_tab("today")
