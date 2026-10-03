"""Account & Data screen: pause, export and deletion, driven on device.

The lifecycle API was verified server-side, but nothing had tapped these
controls in the running app. This journey closes that gap.

Cleanup is not optional here. The suite shares one QA account, and a deletion
left scheduled would hide it from Discover and break every later test, so each
case that changes lifecycle state restores it through the API in a `finally`
rather than relying on the UI path it is testing.
"""

from __future__ import annotations

import pytest


def _lifecycle(api_client, user_id: str) -> dict:
    body = api_client.get(f"/account/{user_id}/lifecycle").require_status(200).body
    return body.get("lifecycle", {}) if isinstance(body, dict) else {}


def _restore_account(api_client, user_id: str) -> None:
    """Return the shared account to a normal, visible state."""
    state = _lifecycle(api_client, user_id)
    if state.get("deletion_effective_at"):
        api_client.request("DELETE", f"/account/{user_id}/deletion")
    if _lifecycle(api_client, user_id).get("deactivated"):
        api_client.post(f"/account/{user_id}/reactivate", {})


def _open_account_data(app) -> None:
    app.open_tab("Settings")
    app.assert_any_text_visible("Settings", "Preferences", timeout=20)
    app.tap_scroll_text("Account & Data", timeout=15)
    app.assert_any_text_visible("Account & Data", "Take a break", timeout=20)


@pytest.mark.requires_appium
@pytest.mark.account_lifecycle
def test_account_data_screen_shows_every_journey(app):
    app.sign_in_existing_user()
    _open_account_data(app)

    # All three options are reachable from one screen: a member weighing
    # deletion must see the reversible alternatives without hunting.
    app.assert_any_text_visible("Take a break", timeout=10)
    assert app.scroll_sheet_to_text("Download your data"), (
        "the export option must be reachable on the Account & Data screen"
    )
    assert app.scroll_sheet_to_text("Delete my account"), (
        "the delete option must be reachable on the Account & Data screen"
    )


@pytest.mark.requires_appium
@pytest.mark.account_lifecycle
@pytest.mark.case("journeys.e2e.account_lifecycle")
def test_pause_hides_profile_and_can_be_undone(app, api_client, qa_user_id):
    app.sign_in_existing_user()
    try:
        _open_account_data(app)
        assert app.maybe_tap_qa("qa.account.pause_toggle_button", timeout=8), (
            "pause control not found on the Account & Data screen"
        )
        app.assert_any_text_visible("Your profile is hidden", timeout=20)

        # The server must agree with the screen; a UI that says hidden while
        # the account is still discoverable is the failure that matters.
        assert _lifecycle(api_client, qa_user_id).get("deactivated") is True, (
            "tapping pause must deactivate the account server-side"
        )

        assert app.maybe_tap_qa("qa.account.pause_toggle_button", timeout=8)
        app.assert_any_text_visible("Take a break", timeout=20)
        assert _lifecycle(api_client, qa_user_id).get("deactivated") is False, (
            "unhiding must clear the deactivation server-side"
        )
    finally:
        _restore_account(api_client, qa_user_id)


@pytest.mark.requires_appium
@pytest.mark.account_lifecycle
@pytest.mark.case("journeys.e2e.account_lifecycle")
def test_export_produces_the_members_own_data(app, api_client, qa_user_id):
    app.sign_in_existing_user()
    _open_account_data(app)
    app.scroll_sheet_to_text_or_fail("Download your data")
    assert app.maybe_tap_qa("qa.account.export_button", timeout=8), (
        "export control not found on the Account & Data screen"
    )

    # The dialog renders the payload, so the member's own identifier appearing
    # in it is evidence the export is theirs rather than an empty document.
    app.assert_any_text_visible("Your data", timeout=45)
    assert app.is_text_visible(qa_user_id, timeout=15), (
        "the export dialog should contain the member's own account data"
    )
    app.tap_text("Close", timeout=10)

    assert _lifecycle(api_client, qa_user_id).get("export_ready") is True, (
        "a completed export must be retrievable afterwards"
    )


@pytest.mark.requires_appium
@pytest.mark.account_lifecycle
@pytest.mark.negative
def test_delete_requires_confirmation_and_offers_hiding(app):
    """Deletion is the only irreversible action; one tap must not do it."""
    app.sign_in_existing_user()
    _open_account_data(app)
    app.scroll_sheet_to_text_or_fail("Delete my account")
    assert app.maybe_tap_qa("qa.account.delete_button", timeout=8)

    app.assert_any_text_visible("Delete your account?", timeout=20)
    assert app.is_text_visible("Hide instead", timeout=5), (
        "the confirmation must offer the reversible alternative"
    )
    # Back out: this case proves the guard exists, it must not schedule one.
    app.tap_text("Keep my account", timeout=10)
    app.assert_any_text_visible("Take a break", "Delete my account", timeout=20)


@pytest.mark.requires_appium
@pytest.mark.account_lifecycle
@pytest.mark.case("journeys.e2e.account_lifecycle")
def test_scheduled_deletion_can_be_cancelled(app, api_client, qa_user_id):
    """The grace window is the member's recovery path, so it is exercised."""
    app.sign_in_existing_user()
    try:
        _open_account_data(app)
        app.scroll_sheet_to_text_or_fail("Delete my account")
        assert app.maybe_tap_qa("qa.account.delete_button", timeout=8)
        app.assert_any_text_visible("Delete your account?", timeout=20)
        assert app.maybe_tap_qa("qa.account.delete_confirm_button", timeout=8)

        app.assert_any_text_visible("Deletion in", "Deletion is due", timeout=25)
        state = _lifecycle(api_client, qa_user_id)
        assert state.get("deletion_effective_at"), (
            "confirming deletion must schedule it server-side"
        )
        assert state.get("deletion_cancellable") is True

        assert app.maybe_tap_qa("qa.account.cancel_deletion_button", timeout=10)
        app.assert_any_text_visible("Take a break", timeout=25)
        assert not _lifecycle(api_client, qa_user_id).get("deletion_effective_at"), (
            "cancelling in the grace window must clear the scheduled deletion"
        )
    finally:
        _restore_account(api_client, qa_user_id)
