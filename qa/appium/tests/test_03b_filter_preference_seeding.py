"""Filter sheet must open pre-filled with the member's saved preferences.

Why this file exists
--------------------
`test_03_discover_filters.py` drives the filter surface but only ever *sets*
values: it taps a dropdown, picks an option, applies, and asserts the sheet
opened. Nothing asserted that a freshly opened sheet already reflects what the
member had saved.

That gap let a real defect ship. The sheet auto-filled exactly one control
(Country, and only to the first entry of the master list rather than the
member's own choice); State, City, Mother Tongue, Religion, Smoking, Drinking,
Age Range and Distance all opened blank or on hardcoded defaults. A member who
completed setup had to re-enter everything.

These cases seed known values through the API first, so they assert real
behaviour instead of whatever the account happens to hold.
"""

from __future__ import annotations

import pytest

# Deliberately distinct from the app's hardcoded fallbacks (age 20-50,
# distance 50km) so a regression cannot pass by coincidence.
SEEDED_MIN_AGE = 27
SEEDED_MAX_AGE = 39
SEEDED_MAX_DISTANCE_KM = 123
SEEDED_SMOKING = "Never"
SEEDED_DRINKING = "Never"


def _seed_preferences(api_client, user_id: str) -> None:
    api_client.patch(
        f"/profile/{user_id}/draft",
        {
            "min_age_years": SEEDED_MIN_AGE,
            "max_age_years": SEEDED_MAX_AGE,
            "max_distance_km": SEEDED_MAX_DISTANCE_KM,
            "smoking": SEEDED_SMOKING,
            "drinking": SEEDED_DRINKING,
        },
    ).require_status(200, 201, 204)


def _read_preferences(api_client, user_id: str) -> dict:
    body = api_client.get(f"/profile/{user_id}/draft").require_status(200).body
    return body.get("draft", body) if isinstance(body, dict) else {}


def _open_filters(app) -> None:
    app.sign_in_existing_user()
    app.open_tab("Discover")
    app.assert_any_text_visible(
        "Discover Matches",
        "Find meaningful verified matches",
        timeout=25,
    )
    if not app.maybe_tap_qa("qa.discovery.filter_button", timeout=5):
        app.tap_first_visible_text(["Filters", "Filter"], timeout=15)
    app.assert_any_text_visible(
        "Filter Matches",
        "Profile & Lifestyle Filters",
        "qa.filters.sheet",
        timeout=20,
    )


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.filters
def test_filter_sheet_seeds_age_and_distance_from_saved_preferences(
    app, api_client, qa_user_id
):
    """Age and distance open on the member's saved values, not the defaults."""
    _seed_preferences(api_client, qa_user_id)

    stored = _read_preferences(api_client, qa_user_id)
    assert stored.get("min_age_years") == SEEDED_MIN_AGE, (
        "seeding did not persist; the assertions below would be vacuous"
    )

    _open_filters(app)

    # The readouts render the live slider values. Before the fix the sheet
    # always opened on 20-50 and 50 km regardless of what was stored.
    #
    # Asserted as the whole "27 – 39" readout rather than "27" and "39"
    # separately: the finder matches on substrings, so a bare "27" would also
    # be satisfied by an unrelated number elsewhere in the sheet.
    expected_age = f"{SEEDED_MIN_AGE} – {SEEDED_MAX_AGE}"
    assert app.is_text_visible(expected_age, timeout=10), (
        f"Age Range did not seed from saved preferences: expected {expected_age!r}"
    )

    # Distance sits below the fold on a compact device, so scroll it into view
    # before asserting rather than reading a screen it was never on.
    app.scroll_sheet_to_text_or_fail("Distance (km)")
    assert app.is_text_visible(f"{SEEDED_MAX_DISTANCE_KM} km", timeout=5), (
        f"Distance did not seed from saved preferences: "
        f"expected {SEEDED_MAX_DISTANCE_KM} km to be shown"
    )


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.filters
def test_filter_sheet_seeds_lifestyle_dropdowns_from_saved_preferences(
    app, api_client, qa_user_id
):
    """Smoking and Drinking open on the saved values rather than "Any"."""
    _seed_preferences(api_client, qa_user_id)

    _open_filters(app)

    for label, expected in (
        ("Smoking", SEEDED_SMOKING),
        ("Drinking", SEEDED_DRINKING),
    ):
        app.scroll_sheet_to_text_or_fail(label)
        assert app.is_text_visible(expected, timeout=5), (
            f"{label} did not seed from saved preferences: "
            f"expected {expected!r}, the sheet is still showing the unset state"
        )


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.filters
def test_filter_sheet_shows_a_readable_value_for_every_slider(app):
    """Sliders must display their value at rest, not only while dragging.

    `RangeSlider.labels` and `Slider.label` only render during a drag, so both
    controls previously showed a bare track with no number on them — the member
    could not tell what was selected without grabbing a thumb.
    """
    _open_filters(app)

    app.scroll_sheet_to_text_or_fail("Age Range")
    assert app.is_text_visible("–", timeout=5) or app.is_text_visible("-", timeout=2), (
        "Age Range shows no value readout at rest"
    )

    app.scroll_sheet_to_text_or_fail("Distance (km)")
    assert app.is_text_visible("km", timeout=5), (
        "Distance shows no value readout at rest"
    )
