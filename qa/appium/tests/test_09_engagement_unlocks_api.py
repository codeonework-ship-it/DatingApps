from __future__ import annotations

import pytest

from api_client import extract_items, first_id


@pytest.mark.contract
@pytest.mark.unlock_matrix
def test_engagement_unlock_seed_contract_smoke(api_client, qa_user_id):
    matches_response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
    matches = extract_items(matches_response.body, "matches")
    match_id = first_id(matches, "match_id", "id")
    assert match_id, f"No seeded match found for unlock smoke: {matches_response.body}"

    api_client.get(f"/matches/{match_id}/unlock-state").require_status(200, 404)
    api_client.get(f"/matches/{match_id}/quest-workflow").require_status(200, 404)
    api_client.get(f"/users/{qa_user_id}/trust-badges").require_status(200, 404)
    api_client.get("/rooms").require_status(200, 404)
