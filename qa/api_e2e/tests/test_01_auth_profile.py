"""Signup, sign-in, session and profile journeys."""

from __future__ import annotations

import pytest

from client import PASSWORD, RUN_ID, Api, items, login


pytestmark = pytest.mark.journey("auth_profile")


@pytest.fixture(scope="module")
def member(make_member):
    return make_member("auth_w", "F", "M")


def test_signup_journey_completes_and_login_returns_completed_workflow(member):
    workflow = member.get(f"/auth/signup/workflow/{member.user_id}").ok()
    assert workflow["state"] == "completed"
    assert workflow["signup_required"] is False

    session = login(member.username).ok()
    assert session["success"] is True
    assert session["user_id"] == member.user_id
    assert session["workflow_state"] == "completed"
    assert session["access_token"]


def test_login_rejects_wrong_password_and_unknown_user():
    bad = login(f"e2e_{RUN_ID}_auth_w", PASSWORD + "x")
    assert bad.status == 401, bad.text
    unknown = login(f"e2e_{RUN_ID}_nobody_here")
    assert unknown.status == 401, unknown.text
    # Same message for both so usernames cannot be enumerated.
    assert bad.get("error") == unknown.get("error")


def test_duplicate_username_is_rejected(member):
    dup = Api().post("/auth/signup", {"username": member.username, "password": PASSWORD})
    assert dup.status in (400, 409), dup.text
    assert dup.get("success") is False


@pytest.mark.parametrize("username,password", [
    ("ab", "Password123!"),            # too short
    ("valid_user_name_e2e", "short"),  # weak password
    ("bad name with spaces", "Password123!"),
])
def test_signup_validation(username, password):
    response = Api().post("/auth/signup", {"username": username, "password": password})
    assert response.status == 400, f"{username!r}/{password!r}: {response.status} {response.text}"


def test_requests_without_session_are_unauthorised(member):
    anon = Api()
    for path in (f"/profile/{member.user_id}/draft", f"/matches/{member.user_id}",
                 f"/friends/{member.user_id}", "/rooms", "/engagement/groups",
                 f"/notifications/{member.user_id}"):
        response = anon.get(path)
        assert response.status == 401, f"{path}: {response.status} {response.text[:200]}"


def test_member_cannot_read_another_members_private_resources(member, make_member):
    other = make_member("auth_o", "M", "F")
    for path in (f"/matches/{other.user_id}", f"/notifications/{other.user_id}",
                 f"/profile/{other.user_id}/draft", f"/settings/{other.user_id}",
                 f"/friends/{other.user_id}"):
        response = member.get(path)
        assert response.status == 403, f"{path}: {response.status} {response.text[:200]}"


def test_profile_read_and_draft_edit_round_trip(member):
    profile = member.get(f"/profile/{member.user_id}").ok()
    assert profile["found"] is True
    assert profile["profile"]["gender"] == "female"

    new_bio = "Weekend potter, weekday architect, always up for a long walk."
    member.patch(f"/profile/{member.user_id}/draft", {"bio": new_bio}).ok()
    draft = member.get(f"/profile/{member.user_id}/draft").ok()
    assert draft["draft"]["bio"] == new_bio
    # Publishing again makes the edit visible on the profile.
    member.post(f"/profile/{member.user_id}/complete").ok()
    assert member.get(f"/profile/{member.user_id}").ok()["profile"]["bio"] == new_bio


def test_profile_summary_and_photos_are_served(member):
    summary = member.get(f"/profile/{member.user_id}/summary")
    assert summary.status == 200, summary.text
    profile = member.get(f"/profile/{member.user_id}").ok()["profile"]
    photos = profile.get("photos") or profile.get("photo_urls") or profile.get("photoUrls") or []
    assert len(photos) >= 2, f"expected the two signup photos, got {photos!r}"
    first = photos[0]["url"] if isinstance(photos[0], dict) else photos[0]
    image = member.api.session.get(first, headers={"Authorization": f"Bearer {member.token}"},
                                   timeout=15)
    assert image.status_code == 200 and image.headers.get("Content-Type", "").startswith("image/")


def test_logout_revokes_the_session(make_member):
    member = make_member("auth_lo", "F", "M")
    session = login(member.username).ok()
    api = Api(session["access_token"])
    assert api.get(f"/settings/{member.user_id}").status == 200
    api.post("/auth/logout", {}).ok()
    after = api.get(f"/settings/{member.user_id}")
    assert after.status == 401, f"token still valid after logout: {after.status}"


def test_settings_theme_and_privacy_round_trip(member):
    for theme in ("light:snow", "dark:gothic", "auto"):
        member.patch(f"/settings/{member.user_id}", {"theme": theme}).ok()
        stored = member.get(f"/settings/{member.user_id}").ok()["settings"]
        assert stored["theme"] == theme
    member.patch(f"/settings/{member.user_id}", {"show_online_status": False}).ok()
    assert member.get(f"/settings/{member.user_id}").ok()["settings"]["show_online_status"] is False
    member.patch(f"/settings/{member.user_id}", {"show_online_status": True}).ok()


def test_notification_preferences_round_trip(member):
    base = f"/notifications/{member.user_id}/preferences"
    member.patch(base, {"notify_likes": False}).ok()
    assert member.get(base).ok()["preferences"]["notify_likes"] is False
    member.patch(base, {"notify_likes": True}).ok()
    assert member.get(base).ok()["preferences"]["notify_likes"] is True


def test_account_lifecycle_state_is_readable(member):
    state = member.get(f"/account/{member.user_id}/lifecycle").ok()
    assert "lifecycle" in state.body or "state" in state.body, state.text
    assert items(member.get(f"/blocked-users/{member.user_id}").ok().body,
                 "blocked_users", "items", "users") == []
