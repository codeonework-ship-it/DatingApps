"""Initial discovery must honor durable partner preferences without opening filters."""
import pytest


@pytest.mark.contract
@pytest.mark.discovery_matrix
def test_discovery_applies_saved_partner_preferences(api_client, qa_user_id):
    draft = api_client.get(f"/profile/{qa_user_id}/draft").require_status(200).body["draft"]
    response = api_client.get(f"/discovery/{qa_user_id}", query={"limit": 20}).require_status(200).body
    applied = response["advanced_filter"]["applied"]
    for key, stored in (("min_age", "min_age_years"), ("max_age", "max_age_years"),
                        ("serious_only", "serious_only"), ("verified_only", "verified_only")):
        assert applied[key] == draft[stored], (key, applied, draft)
    for key in ("seeking_genders", "education_filter"):
        assert applied[key] == list(dict.fromkeys(v.strip().lower() for v in draft[key] if v.strip()))
    if draft["verified_only"]:
        assert all(row["isVerified"] for row in response["candidates"])
    for row in response["candidates"]:
        assert "date_of_birth" not in row and "dateOfBirth" not in row


@pytest.mark.contract
@pytest.mark.discovery_matrix
def test_discovery_explicit_false_overrides_saved_switches(api_client, qa_user_id):
    response = api_client.get(f"/discovery/{qa_user_id}", query={
        "verified_only": "false", "serious_only": "false", "min_age": 18, "max_age": 80,
    }).require_status(200).body
    applied = response["advanced_filter"]["applied"]
    assert applied["verified_only"] is False
    assert applied["serious_only"] is False
    assert (applied["min_age"], applied["max_age"]) == (18, 80)
