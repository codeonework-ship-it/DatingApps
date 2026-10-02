from __future__ import annotations

import time

import pytest


def _profile_draft(api_client, user_id: str) -> dict:
    response = api_client.get(f"/profile/{user_id}/draft").require_status(200)
    body = response.body if isinstance(response.body, dict) else {}
    draft = body.get("draft") if isinstance(body.get("draft"), dict) else body
    return draft if isinstance(draft, dict) else {}


def _restore_verified_only(api_client, user_id: str, value: bool) -> None:
    api_client.patch(f"/profile/{user_id}/draft", {"verified_only": value}).require_status(
        200,
        204,
    )


def _restore_bio(api_client, user_id: str, value: str | None) -> None:
    api_client.patch(f"/profile/{user_id}/draft", {"bio": value}).require_status(
        200,
        204,
    )


def _seed_location(api_client, user_id: str, country: str, state: str, city: str) -> None:
    api_client.patch(
        f"/profile/{user_id}/draft",
        {"country": country, "state": state, "city": city},
    ).require_status(200, 201, 204)


def _restore_location(api_client, user_id: str, draft: dict) -> None:
    api_client.patch(
        f"/profile/{user_id}/draft",
        {
            "country": draft.get("country"),
            "state": draft.get("state"),
            "city": draft.get("city"),
        },
    ).require_status(200, 201, 204)


def _open_edit_profile(app) -> None:
    app.sign_in_existing_user()
    app.open_tab("Profile")
    app.assert_any_text_visible("Settings", "Edit Profile", "Profile", timeout=15)
    if not app.is_text_visible("Edit Profile", timeout=3):
        app.tap_first_visible_text(["Settings", "More"], timeout=10)
    app.tap_scroll_text("Edit Profile", timeout=15)
    app.assert_any_text_visible("Edit Profile", timeout=20)


def _open_edit_about(app) -> None:
    _open_edit_profile(app)
    app.tap_scroll_text("Edit about", timeout=15)
    app.assert_any_text_visible("Make your profile shine", "Bio", timeout=20)


def _tap_save_about(app) -> None:
    app.hide_keyboard()
    if not app.maybe_tap_qa("qa.setup.about.save_button", timeout=4):
        app.tap_scroll_text("Save About", timeout=10)


def _reopen_edit_profile(app) -> None:
    for _ in range(4):
        if app.is_authenticated_surface_visible(timeout=1):
            break
        try:
            app.driver.back()
            time.sleep(0.4)
        except Exception:  # noqa: BLE001 - best-effort navigation reset
            break
    _open_edit_profile(app)


@pytest.mark.requires_appium
@pytest.mark.edit_profile
@pytest.mark.smoke
def test_edit_profile_binds_saved_profile(app, api_client, qa_user_id):
    """Edit Profile must render the member's own saved name and location.

    This previously asserted the literal strings "Kalyan Test Viewer",
    "Kalyan", "Maharashtra" and "India" — values from a seed set that no
    longer matches the QA account, whose country/state/city are unset. The
    test therefore failed on data, not on a screen defect. It now seeds a
    known location through the API and asserts the screen reflects it, and
    takes the display name from the API rather than a literal, so the
    assertion stays strong without being tied to one fixture.
    """
    original = _profile_draft(api_client, qa_user_id)
    country, state, city = "India", "Maharashtra", "Kalyan"

    try:
        _seed_location(api_client, qa_user_id, country, state, city)

        seeded = _profile_draft(api_client, qa_user_id)
        assert seeded.get("city") == city, (
            "seeding did not persist; the screen assertions below would be vacuous"
        )
        name = str(seeded.get("name") or "").strip()

        _open_edit_profile(app)
        # The location was written behind the app's back (API). Edit Profile
        # keeps the draft it loaded earlier in the session (AND-13), so use
        # its own "Refresh profile" control before asserting the binding.
        app.tap_text("Refresh profile", timeout=10)
        time.sleep(1.5)

        app.assert_any_text_visible(
            "About you",
            "Location",
            "Dating preferences",
            timeout=30,
        )
        if name:
            app.assert_any_text_visible(name, timeout=15)

        app.scroll_to_text("Location", timeout=10)
        for expected in (city, state, country):
            assert app.is_text_visible(expected, timeout=10), (
                f"Edit Profile did not bind the saved location: {expected!r} "
                f"is not on screen although the profile stores it"
            )
    finally:
        _restore_location(api_client, qa_user_id, original)


@pytest.mark.requires_appium
@pytest.mark.edit_profile
def test_edit_profile_bio_save_persists_after_reopen(
    app,
    api_client,
    qa_user_id,
):
    original = _profile_draft(api_client, qa_user_id).get("bio")
    updated_bio = f"Appium edit profile bio {int(time.time())}"

    try:
        _open_edit_about(app)
        app.type_into_qa("qa.setup.about.bio_field", updated_bio, timeout=8)
        _tap_save_about(app)

        app.assert_any_text_visible("Edit Profile", timeout=30)
        app.scroll_to_text("Bio", timeout=10)
        app.assert_any_text_visible(updated_bio, timeout=10)

        persisted = _profile_draft(api_client, qa_user_id)
        assert persisted.get("bio") == updated_bio

        _reopen_edit_profile(app)
        app.scroll_to_text("Bio", timeout=10)
        app.assert_any_text_visible(updated_bio, timeout=15)
    finally:
        _restore_bio(api_client, qa_user_id, original)


@pytest.mark.requires_appium
@pytest.mark.edit_profile
@pytest.mark.negative
def test_edit_profile_invalid_bio_is_blocked(
    app,
    api_client,
    qa_user_id,
):
    original = _profile_draft(api_client, qa_user_id).get("bio")

    _open_edit_about(app)
    app.type_into_qa("qa.setup.about.bio_field", "short", timeout=8)
    _tap_save_about(app)

    app.assert_any_text_visible("Bio must be at least 10 characters.", timeout=10)
    app.assert_any_text_visible("Make your profile shine", "Bio", timeout=5)
    persisted = _profile_draft(api_client, qa_user_id)
    assert persisted.get("bio") == original


@pytest.mark.requires_appium
@pytest.mark.edit_profile
def test_edit_preferences_toggle_saves_and_returns_to_edit_profile(
    app,
    api_client,
    qa_user_id,
):
    draft = _profile_draft(api_client, qa_user_id)
    original_verified = bool(draft.get("verified_only"))
    expected_verified = not original_verified
    expected_label = "Yes" if expected_verified else "No"

    try:
        _open_edit_profile(app)
        app.tap_scroll_text("Edit preferences", timeout=15)
        app.assert_any_text_visible("Edit Preferences", timeout=20)

        app.scroll_to_text("Verified profiles only", timeout=10)
        if not app.maybe_tap_qa("qa.setup.preferences.verified_only_toggle", timeout=5):
            app.tap_text("Verified profiles only", timeout=10)

        if not app.maybe_tap_qa("qa.setup.preferences.save_button", timeout=5):
            app.tap_scroll_text("Save Preferences", timeout=10)

        app.assert_any_text_visible("Edit Profile", timeout=30)
        app.scroll_to_text("Verified only", timeout=10)
        app.assert_any_text_visible("Verified only", expected_label, timeout=10)
        persisted = _profile_draft(api_client, qa_user_id)
        assert bool(persisted.get("verified_only")) is expected_verified

        _reopen_edit_profile(app)
        app.scroll_to_text("Verified only", timeout=10)
        app.assert_any_text_visible("Verified only", expected_label, timeout=10)
        assert not app.is_text_visible("Finish & Find Matches", timeout=2)
    finally:
        _restore_verified_only(api_client, qa_user_id, original_verified)
