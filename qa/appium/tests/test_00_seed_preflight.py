from __future__ import annotations

from pathlib import Path
from urllib.request import urlopen

import pytest

from api_client import extract_items, first_id
from matrix import load_fixture, write_json_report


def _summary_payload(appium_config, **extra):
    payload = {
        "api_base_url": appium_config.api_base_url,
        "api_host_base_url": appium_config.api_host_base_url,
        "bff_health_url": appium_config.bff_health_url,
        "viewer_username": appium_config.existing_username,
        "viewer_user_id": appium_config.existing_user_id,
    }
    payload.update(extra)
    write_json_report("seed-preflight-summary.json", payload)


@pytest.mark.seed
@pytest.mark.contract
def test_backend_health_and_openapi_contract(appium_config):
    for url in (f"{appium_config.api_host_base_url}/healthz", appium_config.bff_health_url):
        with urlopen(url, timeout=10) as response:  # noqa: S310 - local QA health check
            assert response.status == 200, f"{url} did not return 200"

    with urlopen(f"{appium_config.api_host_base_url}/openapi.yaml", timeout=10) as response:  # noqa: S310 - local QA contract check
        assert response.status == 200, "Gateway OpenAPI endpoint did not return 200"
        live_contract = response.read().decode("utf-8", errors="replace")

    openapi_path = Path(__file__).resolve().parents[3] / "backend" / "internal" / "platform" / "docs" / "openapi.yaml"
    contract = openapi_path.read_text(encoding="utf-8")
    for required_path in (
        "/v1/auth/login",
        "/v1/auth/signup",
        "/v1/auth/refresh",
        "/v1/auth/logout",
        "/v1/auth/signup/bootstrap",
        "/v1/profile/{userID}/draft",
        "/v1/discovery/{userID}",
        "/v1/swipe",
        "/v1/matches/{userID}",
        "/v1/chat/{matchID}/messages",
        "/v1/chat/gifts",
        "/v1/chat/{matchID}/gifts/send",
        "/v1/wallet/{userID}/coins",
        "/v1/matches/{matchID}/unlock-state",
    ):
        assert required_path in contract, f"OpenAPI contract is missing {required_path}"
        assert required_path in live_contract, f"Live OpenAPI contract is missing {required_path}"


@pytest.mark.seed
def test_required_seed_scripts_are_present_and_ordered(appium_config):
    workspace = Path(__file__).resolve().parents[3]
    scripts_dir = workspace / "backend" / "scripts"
    run_order = (workspace / "backend" / "scripts_run_order.txt").read_text(encoding="utf-8")
    users_fixture = load_fixture("users.json")
    missing = []
    unordered = []
    for cohort in users_fixture["cohorts"]:
        script = cohort["seed_script"]
        if not (scripts_dir / script).exists():
            missing.append(script)
        if script not in run_order:
            unordered.append(script)
    assert not missing, f"Required Appium QA seed scripts are missing: {missing}"
    assert not unordered, f"Required Appium QA seed scripts are not in scripts_run_order.txt: {unordered}"
    _summary_payload(appium_config, required_seed_scripts=[item["seed_script"] for item in users_fixture["cohorts"]])


@pytest.mark.seed
def test_seeded_viewer_profile_and_discovery(api_client, appium_config, qa_user_id):
    users_fixture = load_fixture("users.json")
    assert users_fixture["viewer"]["default_username"], users_fixture

    summary = api_client.get(f"/profile/{qa_user_id}/summary").require_status(200, 404)
    if summary.status == 200 and isinstance(summary.body, dict):
        assert summary.body.get("found", True) is not False, summary.body

    discovery = api_client.get(
        f"/discovery/{qa_user_id}",
        # Seed availability is independent of whatever saved filters earlier
        # preference tests left on this long-lived synthetic account.
        query={
            "limit": 20,
            "mode": "all",
            "seeking_genders": "m,f,other",
            "min_age": 18,
            "max_age": 80,
            "serious_only": "false",
            "verified_only": "false",
        },
    ).require_status(200)
    candidates = extract_items(discovery.body, "candidates")
    assert len(candidates) >= appium_config.expected_min_discovery_candidates, discovery.body
    _summary_payload(
        appium_config,
        profile_summary_status=summary.status,
        discovery_candidate_count=len(candidates),
    )


@pytest.mark.seed
def test_seeded_matches_chat_gifts_and_wallet(api_client, appium_config, qa_user_id):
    matches_response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
    matches = extract_items(matches_response.body, "matches")
    assert len(matches) >= appium_config.expected_min_matches, matches_response.body

    match_id = first_id(matches, "match_id", "id")
    assert match_id, f"No match_id/id found in matches payload: {matches_response.body}"

    api_client.get(f"/chat/{match_id}/messages", query={"limit": 10}).require_status(200, 423)
    unlock_state = api_client.get(f"/matches/{match_id}/unlock-state").require_status(200, 404)

    catalog = api_client.get("/chat/gifts").require_status(200)
    gifts = extract_items(catalog.body, "gifts")
    assert gifts, catalog.body

    wallet = api_client.get(f"/wallet/{qa_user_id}/coins").require_status(200, 404)
    _summary_payload(
        appium_config,
        match_count=len(matches),
        sampled_match_id=match_id,
        unlock_state_status=unlock_state.status,
        gift_count=len(gifts),
        wallet_status=wallet.status,
    )
