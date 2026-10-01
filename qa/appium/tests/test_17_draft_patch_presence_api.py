from __future__ import annotations

import os

import pytest

from api_client import ApiClient


@pytest.mark.contract
@pytest.mark.profile_detail
def test_bio_only_patch_preserves_saved_location_and_education(appium_config):
    username = os.getenv("QA_PUBLIC_PROFILE_VIEWER_USERNAME")
    if not username or not appium_config.enable_mutating_matrix:
        pytest.skip("Requires a separate synthetic peer and QA_ENABLE_MUTATING_MATRIX=true")
    client = ApiClient(appium_config.api_base_url)
    client.authenticate(
        username,
        os.getenv("QA_PUBLIC_PROFILE_VIEWER_PASSWORD", appium_config.existing_password),
    )
    path = f"/profile/{client.authenticated_user_id}/draft"
    original = client.get(path).require_status(200).body["draft"]
    seeded = {"country": "India", "state": "Maharashtra", "city": "Thane", "education": "Graduate", "height_cm": 175}
    try:
        client.patch(path, seeded).require_status(200)
        client.patch(path, {"bio": "A synthetic QA biography changed independently."}).require_status(200)
        stored = client.get(path).require_status(200).body["draft"]
        assert {key: stored.get(key) for key in seeded} == seeded, (
            "A partial bio update must preserve unrelated location and education"
        )
        client.patch(path, {"height_cm": None}).require_status(200)
        cleared = client.get(path).require_status(200).body["draft"]
        assert cleared.get("height_cm") is None, "Explicit null must clear a saved height"
        assert cleared.get("city") == seeded["city"], "Clearing height must preserve location"
    finally:
        client.patch(path, {key: original.get(key) for key in (*seeded, "bio")}).require_status(200)
