from __future__ import annotations

import pytest

from api_client import extract_items
from matrix import load_fixture


@pytest.mark.contract
@pytest.mark.discovery_matrix
@pytest.mark.parametrize("case", load_fixture("discovery_matrix.json"), ids=lambda case: case["name"])
def test_discovery_filter_contract_matrix(api_client, qa_user_id, case):
    response = api_client.get(f"/discovery/{qa_user_id}", query=case["params"]).require_status(200)
    candidates = extract_items(response.body, "candidates")
    assert len(candidates) >= int(case.get("min_candidates", 0)), response.body
    assert len(candidates) <= int(case["params"].get("limit", 25)), response.body

    if case["name"] == "no-match-city-empty-state":
        assert candidates == [], "A nonexistent city must exclude every candidate"

    if case["params"].get("verified_only") == "true":
        assert all(item.get("isVerified") is True for item in candidates), response.body
        assert response.body["advanced_filter"]["applied"]["verified_only"] is True

    for key in ("state", "city", "smoking", "drinking", "min_age", "max_age"):
        if key in case["params"]:
            expected = case["params"][key]
            if isinstance(expected, str):
                expected = expected.strip().lower()
            assert response.body["advanced_filter"]["applied"][key] == expected

    if case["params"].get("mode") == "spotlight" and isinstance(response.body, dict):
        assert "spotlight_profiles" in response.body or any(
            item.get("is_spotlight") is True for item in candidates
        ), response.body

    if isinstance(response.body, dict) and "trust_filter" in response.body:
        assert isinstance(response.body["trust_filter"], dict), response.body
