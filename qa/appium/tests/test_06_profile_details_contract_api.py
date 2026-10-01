from __future__ import annotations

import pytest

from api_client import extract_items, first_id, pick_value


@pytest.mark.contract
@pytest.mark.profile_detail
def test_profile_detail_contract_for_seeded_discovery_candidate(api_client, qa_user_id):
    discovery = api_client.get(
        f"/discovery/{qa_user_id}",
        # This test needs a published candidate, independently of the viewer's
        # restrictive saved preferences. Default eligibility has its own contract.
        query={"limit": 10, "mode": "all", "seeking_genders": "M,F,Other",
               "serious_only": "false", "verified_only": "false", "min_age": 18, "max_age": 80},
    ).require_status(200)
    candidates = extract_items(discovery.body, "candidates", "profiles", "items")
    candidate_id = first_id(candidates, "user_id", "id", "profile_id")
    assert candidate_id, f"No profile candidate id found in discovery payload: {discovery.body}"

    profile = api_client.get(f"/profile/{candidate_id}").require_status(200)
    # Discovery must never need another member's private setup draft.
    api_client.get(f"/profile/{candidate_id}/draft").require_status(403)
    payload = profile.body
    assert isinstance(payload, dict), payload
    nested_profile = payload.get("profile", {}) if isinstance(payload.get("profile"), dict) else {}
    assert pick_value(payload, "id", "user_id", "profile_id") or pick_value(
        nested_profile,
        "id",
        "user_id",
        "profile_id",
    ), payload


@pytest.mark.contract
@pytest.mark.profile_detail
@pytest.mark.negative
def test_profile_detail_missing_user_returns_not_found(api_client):
    response = api_client.get("/profile/00000000-0000-4000-8000-000000000404")
    assert response.status == 404, response.body
