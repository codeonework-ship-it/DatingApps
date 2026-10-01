"""Privacy controls must affect what a different authenticated member receives."""

from __future__ import annotations

import os

import pytest

from api_client import ApiClient


@pytest.mark.contract
@pytest.mark.profile_detail
@pytest.mark.security_negative
def test_hidden_age_is_not_exposed_in_public_profile(api_client, appium_config, qa_user_id):
    peer_username = os.getenv("QA_PUBLIC_PROFILE_VIEWER_USERNAME")
    if not peer_username:
        pytest.skip("Set QA_PUBLIC_PROFILE_VIEWER_USERNAME to a separate synthetic member")
    if not appium_config.enable_mutating_matrix:
        pytest.skip("Set QA_ENABLE_MUTATING_MATRIX=true for privacy save/restore")

    peer = ApiClient(appium_config.api_base_url)
    peer.authenticate(
        peer_username,
        os.getenv("QA_PUBLIC_PROFILE_VIEWER_PASSWORD", appium_config.existing_password),
    )
    assert peer.authenticated_user_id != qa_user_id, "Privacy requires a different viewer"
    original = api_client.get(f"/settings/{qa_user_id}").require_status(200).body
    original = original.get("settings", original)
    try:
        api_client.patch(f"/settings/{qa_user_id}", {"show_age": False}).require_status(200)
        stored = api_client.get(f"/settings/{qa_user_id}").require_status(200).body
        assert stored.get("settings", stored)["show_age"] is False

        response = peer.get(f"/profile/{qa_user_id}").require_status(200)
        profile = response.body.get("profile", response.body)
        exposed = [
            key for key in ("age", "date_of_birth", "dateOfBirth", "dob")
            if profile.get(key) is not None
        ]
        assert not exposed, (
            "show_age=false persisted, but another member received age/DOB fields: "
            f"{exposed}"
        )
    finally:
        api_client.patch(
            f"/settings/{qa_user_id}", {"show_age": original.get("show_age", True)}
        ).require_status(200)
