from __future__ import annotations

import pytest

from api_client import extract_items


def _open_discovery(app) -> None:
    app.open_discovery_deck()


@pytest.fixture
def reset_filters_after(app):
    """Applied filters live in the app session and would empty the deck for
    every later spec; clear them with the sheet's own Reset afterwards."""
    yield
    try:
        app.go_today()
        app.open_discovery_deck()
        _open_filters(app)
        app.scroll_sheet_to_text_or_fail("Reset")
        app.tap_qa_coordinate("qa.filters.reset_button", timeout=5)
        app.press_back()
        app.maybe_tap_qa("qa.discovery.state_action_button", timeout=3)
    except Exception as exc:  # noqa: BLE001 - cleanup must not mask the result
        print(f"[filter reset failed] {exc!r}")


def _open_filters(app) -> None:
    if not app.maybe_tap_qa("qa.discovery.filter_button", timeout=5):
        app.tap_first_visible_text(["Filters", "Filter"], timeout=15)
    app.assert_any_text_visible(
        "Filter Matches",
        "Profile & Lifestyle Filters",
        "qa.filters.sheet",
        timeout=20,
    )


def _select_filter(app, field: str, value: str) -> bool:
    """Set one dropdown on the open filter sheet.

    Two things made the previous version silently do nothing. It reached the
    control with `tap_scroll_text`, whose UiScrollable drags the sheet shut
    rather than scrolling it; and it swallowed the resulting TimeoutException,
    so the sheet was gone and the test carried on as though the filter had
    been applied. Returns whether the value was actually selected.
    """
    label = field.replace("_", " ").title()
    if not app.scroll_sheet_to_text(label):
        return False
    if not app.maybe_tap_qa(f"qa.filters.{field}_dropdown", timeout=4):
        if not app.maybe_tap_contains(label, timeout=4):
            return False
    # Take the option straight if it is already rendered, otherwise walk the
    # open menu with forward-only swipes. UiScrollable must not be used here:
    # when the menu is short enough not to be scrollable it targets the first
    # scrollable it can find — the sheet underneath — and drags that shut.
    if app.maybe_tap_contains(value, timeout=4):
        return True
    if app.scroll_sheet_to_text(value, max_swipes=6) and app.maybe_tap_contains(
        value, timeout=3
    ):
        return True

    # Master data may legitimately not offer this option. Close the menu by
    # tapping its barrier near the top of the screen rather than pressing
    # back: back popped the sheet, then the route beneath it, and after four
    # of these the suite had walked the app out to the Android home screen —
    # every later assertion then failed against a launcher, not the product.
    size = app.driver.get_window_size()
    app.driver.tap([(size["width"] // 2, int(size["height"] * 0.04))])
    return False


def _apply_filters(app) -> None:
    # Apply sits at the very bottom of the sheet. `tap_scroll_text` cannot
    # reach it: UiScrollable scrolls backwards first, which drags the sheet
    # shut. Walk down with forward-only swipes instead.
    app.scroll_sheet_to_text_or_fail("Apply")
    app.tap_qa_coordinate("qa.filters.apply_button", timeout=5)
    app.assert_any_text_visible("Discover Matches", "Filters saved", timeout=30)


def _candidate_names(api_client, user_id: str) -> list[str]:
    response = api_client.get(
        f"/discovery/{user_id}",
        query={"limit": 10, "mode": "all"},
    ).require_status(200)
    candidates = extract_items(response.body, "candidates", "profiles", "items")
    names = []
    for candidate in candidates:
        name = candidate.get("name") or candidate.get("display_name")
        if name:
            names.append(str(name))
    return names


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.filters
@pytest.mark.smoke
def test_discover_and_filters(app, appium_config, api_client, qa_user_id, reset_filters_after):
    expected_names = _candidate_names(api_client, qa_user_id)

    _open_discovery(app)
    if expected_names:
        assert app.assert_any_text_visible(
            *expected_names[:3],
            "qa.discovery.card_root",
            "Ready",
            timeout=30,
        )
    _open_filters(app)

    selected = {
        "country": _select_filter(app, "country", "India"),
        "state": _select_filter(app, "state", appium_config.filter_state),
        "city": _select_filter(app, "city", appium_config.filter_city),
        "smoking": _select_filter(app, "smoking", appium_config.filter_smoking),
        "drinking": _select_filter(app, "drinking", appium_config.filter_drinking),
    }
    # The point of this test is that filters can be set, so a selection that
    # quietly did nothing must fail rather than be swallowed.
    assert all(selected.values()), (
        f"every requested filter must be selected on the open sheet: {selected}"
    )

    assert app.is_text_visible("Filter Matches", timeout=5), (
        "the filter sheet closed while filters were being selected"
    )
    _apply_filters(app)
    app.assert_any_text_visible(appium_config.filter_city, "Ready", "Spotlight", timeout=30)


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.filters
def test_discovery_filters_reopen_after_save(app, appium_config, reset_filters_after):
    _open_discovery(app)
    _open_filters(app)
    _apply_filters(app)

    _open_filters(app)
    app.assert_any_text_visible(
        "Filter Matches",
        "Profile & Lifestyle Filters",
        "State",
        "City",
        timeout=15,
    )
    # Smoking and Drinking sit below the fold, so scroll the sheet before
    # asserting rather than reading a screen they were never on.
    assert app.scroll_sheet_to_text("Smoking"), (
        "the reopened sheet never showed the Smoking filter"
    )
    assert app.scroll_sheet_to_text("Drinking"), (
        "the reopened sheet never showed the Drinking filter"
    )
    _apply_filters(app)


@pytest.mark.discovery
@pytest.mark.filters
@pytest.mark.contract
@pytest.mark.negative
def test_discovery_no_result_filter_contract(api_client, qa_user_id):
    response = api_client.get(
        f"/discovery/{qa_user_id}",
        query={
            "mode": "all",
            "limit": 20,
            "state": "Maharashtra",
            "city": "NoSuchAppiumCity",
        },
    ).require_status(200)
    assert extract_items(response.body, "candidates", "profiles", "items") == []
