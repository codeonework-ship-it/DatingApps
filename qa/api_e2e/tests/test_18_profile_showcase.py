"""Profile showcase (migration 130): public chapters and wall photos on a profile.

GET /profile/{id}/showcase -> {enabled, chapters[], photos[]}
GET|PUT /profile/{id}/showcase/consent -> {visible}

Other members see items only while the owner's consent is on, and then only
community-audience chapters that are active and not under a pending report,
plus wall-featured photos. A block in either direction hides everything. The
owner always gets a preview of what would show, together with ``enabled``.

Community content needs both members to be community-eligible (profile 100%
complete with two approved photos); the signup journey in client.py provisions
exactly that, so every member made here is eligible.
"""

from __future__ import annotations

import uuid

import pytest

from client import png_bytes
from journeys import befriend


pytestmark = pytest.mark.journey("profile_showcase")


def _key() -> dict:
    return {"Idempotency-Key": f"e2e-{uuid.uuid4()}"}


def _chapter(author, title: str, audience: str) -> dict:
    post_id = str(uuid.uuid4())
    saved = author.put(f"/blog/posts/{post_id}", {
        "title": title,
        "body": f"{title}: a short story about mountain trails and listening more than talking.",
        "audience": audience, "topic": "feelings", "expected_version": 0}).ok()
    return saved["post"]


def _consent(member, owner, visible: bool):
    return member.put(f"/profile/{owner.user_id}/showcase/consent", {"visible": visible},
                      headers=_key())


def _set_consent(owner, visible: bool) -> None:
    assert _consent(owner, owner, visible).ok()["visible"] is visible


def _payload(response) -> dict:
    """Response body without the gateway's correlation_id envelope field."""
    return {k: v for k, v in response.body.items() if k != "correlation_id"}


def _showcase(viewer, owner) -> dict:
    response = viewer.get(f"/profile/{owner.user_id}/showcase").ok()
    body = _payload(response)
    assert set(body) >= {"enabled", "chapters", "photos"}, response.text
    assert isinstance(body["chapters"], list) and isinstance(body["photos"], list), response.text
    return body


def _ids(items: list) -> list[str]:
    return [item["id"] for item in items]


@pytest.fixture(scope="module")
def cast(make_member):
    """Owner with one chapter per audience and one wall-featured theme photo,
    a stranger and a friend of the owner."""
    owner = make_member("sc_own", "F", "M")
    viewer = make_member("sc_view", "M", "F")
    friend = make_member("sc_frnd", "M", "F")
    befriend(friend, owner)
    chapters = {audience: _chapter(owner, f"E2E showcase {audience}", audience)
                for audience in ("community", "friends", "private")}
    themes = owner.get("/themes").ok()
    assert themes["eligible"] is True, themes.text
    theme = next(t for t in themes["themes"] if t["status"] == "active" and not t["my_entry_id"])
    entry_id = str(uuid.uuid4())
    entry = owner.api.call(
        "PUT", f"/themes/{theme['id']}/entries/{entry_id}", headers=_key(),
        files={"image": ("e2e.png", png_bytes((0x22, 0x99, 0x55)), "image/png"),
               "caption": (None, "E2E showcase: green hour"),
               "alt_text": (None, "A green square standing in for a park at dusk"),
               "allow_featuring": (None, "true")})
    assert entry.status in (200, 201), entry.text
    assert entry["entry"]["allow_featuring"] is True, entry.text
    yield {"owner": owner, "viewer": viewer, "friend": friend, "chapters": chapters,
           "theme_id": theme["id"], "entry_id": entry_id}
    owner.delete(f"/themes/{theme['id']}/entries/{entry_id}")
    for post in chapters.values():
        owner.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]})


def test_consent_defaults_off_and_hides_the_showcase(cast):
    owner, viewer = cast["owner"], cast["viewer"]
    consent = owner.get(f"/profile/{owner.user_id}/showcase/consent").ok()
    assert _payload(consent) == {"visible": False}, consent.text
    for other in (viewer, cast["friend"]):
        assert _showcase(other, owner) == {"enabled": False, "chapters": [], "photos": []}
    # An unknown member reads the same as a hidden one: nothing to learn.
    unknown = viewer.get(f"/profile/{uuid.uuid4()}/showcase").ok()
    assert _payload(unknown) == {"enabled": False, "chapters": [], "photos": []}, unknown.text


def test_owner_always_gets_a_preview(cast):
    owner, chapters = cast["owner"], cast["chapters"]
    _set_consent(owner, False)
    preview = owner.get(f"/profile/{owner.user_id}/showcase").ok()
    assert "no-store" in preview.headers.get("Cache-Control", ""), dict(preview.headers)
    assert preview["enabled"] is False
    assert _ids(preview["chapters"]) == [chapters["community"]["id"]], preview.text
    assert _ids(preview["photos"]) == [cast["entry_id"]], preview.text
    _set_consent(owner, True)
    assert _showcase(owner, owner)["enabled"] is True


def test_enabling_shows_only_the_community_chapter_and_featured_photo(cast):
    owner, chapters = cast["owner"], cast["chapters"]
    _set_consent(owner, True)
    for other in (cast["viewer"], cast["friend"]):
        shown = _showcase(other, owner)
        assert shown["enabled"] is True
        # Friends-audience chapters stay off the profile even for a friend.
        assert _ids(shown["chapters"]) == [chapters["community"]["id"]], shown
        assert _ids(shown["photos"]) == [cast["entry_id"]], shown
    chapter = _showcase(cast["viewer"], owner)["chapters"][0]
    assert set(chapter) >= {"id", "title", "excerpt", "published_at", "like_count", "comment_count"}
    assert chapter["title"] == "E2E showcase community"
    assert chapter["excerpt"].startswith("E2E showcase community: a short story")
    assert "body" not in chapter


def test_withdrawing_consent_hides_the_showcase_immediately(cast):
    owner, viewer = cast["owner"], cast["viewer"]
    _set_consent(owner, True)
    assert _ids(_showcase(viewer, owner)["chapters"])
    _set_consent(owner, False)
    assert _showcase(viewer, owner) == {"enabled": False, "chapters": [], "photos": []}
    assert owner.get(f"/profile/{owner.user_id}/showcase/consent").ok()["visible"] is False
    _set_consent(owner, True)
    assert _ids(_showcase(viewer, owner)["chapters"]) == [cast["chapters"]["community"]["id"]]


def test_unfeatured_wall_photo_leaves_the_showcase(cast):
    owner, viewer = cast["owner"], cast["viewer"]
    _set_consent(owner, True)
    path = f"/themes/{cast['theme_id']}/entries/{cast['entry_id']}/featuring"
    owner.post(path, {"allow": False}, headers=_key()).ok()
    try:
        assert _showcase(viewer, owner)["photos"] == []
        assert _showcase(owner, owner)["photos"] == []
    finally:
        owner.post(path, {"allow": True}, headers=_key()).ok()
    assert _ids(_showcase(viewer, owner)["photos"]) == [cast["entry_id"]]


def test_reported_chapter_leaves_the_showcase(cast, make_member):
    owner, viewer = cast["owner"], cast["viewer"]
    _set_consent(owner, True)
    reported = _chapter(owner, "E2E showcase reported", "community")
    reporter = make_member("sc_rep", "M", "F")
    assert reported["id"] in _ids(_showcase(viewer, owner)["chapters"])
    report = reporter.post(f"/blog/reports/post/{reported['id']}",
                           {"reason": "fake", "description": "e2e showcase report"}, headers=_key())
    assert report.status in (200, 201, 202), report.text
    assert reported["id"] not in _ids(_showcase(viewer, owner)["chapters"])
    assert cast["chapters"]["community"]["id"] in _ids(_showcase(viewer, owner)["chapters"])


@pytest.mark.safety
@pytest.mark.parametrize("direction", ["owner_blocks_viewer", "viewer_blocks_owner"])
def test_a_block_either_way_hides_everything(cast, make_member, direction):
    owner = cast["owner"]
    _set_consent(owner, True)
    viewer = make_member(f"sc_b{direction[0]}", "M", "F")
    assert _ids(_showcase(viewer, owner)["chapters"]), "precondition: showcase visible before the block"
    blocker, blocked = (owner, viewer) if direction == "owner_blocks_viewer" else (viewer, owner)
    blocker.post("/safety/block", {"user_id": blocker.user_id, "blocked_user_id": blocked.user_id},
                 headers=_key()).ok()
    hidden = _showcase(viewer, owner)
    assert hidden["chapters"] == [] and hidden["photos"] == [], hidden
    # The owner's own preview is unaffected by blocks.
    assert _ids(_showcase(owner, owner)["chapters"]) == [cast["chapters"]["community"]["id"]]


@pytest.mark.safety
# Regression guard: API-22 (the blocked side could read the owner's consent).
@pytest.mark.parametrize("direction", ["owner_blocks_viewer", "viewer_blocks_owner"])
def test_blocked_side_cannot_read_the_owners_consent(cast, make_member, direction):
    owner = cast["owner"]
    _set_consent(owner, True)
    viewer = make_member(f"sc_c{direction[0]}", "M", "F")
    blocker, blocked = (owner, viewer) if direction == "owner_blocks_viewer" else (viewer, owner)
    blocker.post("/safety/block", {"user_id": blocker.user_id, "blocked_user_id": blocked.user_id},
                 headers=_key()).ok()
    assert viewer.get(f"/profile/{owner.user_id}").status == 404
    assert _showcase(viewer, owner) == {"enabled": False, "chapters": [], "photos": []}


@pytest.mark.authz
def test_other_member_cannot_read_or_write_consent(cast):
    owner, viewer = cast["owner"], cast["viewer"]
    _set_consent(owner, False)
    path = f"/profile/{owner.user_id}/showcase/consent"
    assert viewer.get(path).status == 403
    for visible in (True, False):
        attempt = _consent(viewer, owner, visible)
        assert attempt.status == 403, attempt.text
    # Actor fields in the body do not help either.
    spoof = viewer.put(path, {"visible": True, "user_id": owner.user_id}, headers=_key())
    assert spoof.status in (400, 403), spoof.text
    assert owner.get(path).ok()["visible"] is False
    assert _showcase(viewer, owner)["chapters"] == []
    _set_consent(owner, True)


@pytest.mark.validation
@pytest.mark.parametrize("body", [{}, {"visible": "true"}, {"visible": 1}, {"visible": None},
                                  {"shown": True}], ids=["empty", "string", "number", "null", "wrong-key"])
def test_bad_consent_body_is_a_400(cast, body):
    owner = cast["owner"]
    before = owner.get(f"/profile/{owner.user_id}/showcase/consent").ok()["visible"]
    response = owner.put(f"/profile/{owner.user_id}/showcase/consent", body, headers=_key())
    assert response.status == 400, response.text
    assert owner.get(f"/profile/{owner.user_id}/showcase/consent").ok()["visible"] is before


@pytest.mark.validation
def test_malformed_requests_are_client_errors(cast):
    owner = cast["owner"]
    path = f"/profile/{owner.user_id}/showcase/consent"
    not_json = owner.api.call("PUT", path, data=b"{visible: yes", headers={
        "Content-Type": "application/json", **_key()})
    assert not_json.status == 400, not_json.text
    assert owner.get("/profile/not-a-uuid/showcase").status == 400
    assert owner.get("/profile/not-a-uuid/showcase/consent").status in (400, 403)
    anonymous = owner.api.call("GET", f"/profile/{owner.user_id}/showcase", auth=False)
    assert anonymous.status == 401, anonymous.text


@pytest.mark.idempotency
def test_consent_put_replay_is_idempotent(cast):
    owner = cast["owner"]
    path = f"/profile/{owner.user_id}/showcase/consent"
    headers = _key()
    first = owner.put(path, {"visible": True}, headers=headers).ok()
    owner.put(path, {"visible": False}, headers=_key()).ok()
    replay = owner.put(path, {"visible": True}, headers=headers)
    assert replay.status == first.status, replay.text
    assert replay.headers.get("X-Idempotent-Replay") == "true", dict(replay.headers)
    assert _payload(replay) == _payload(first)
    # A replay must not re-run the command.
    assert owner.get(path).ok()["visible"] is False
    conflict = owner.put(path, {"visible": False}, headers=headers)
    assert conflict.status == 409, conflict.text
    # Setting the same value twice with fresh keys is a harmless no-op.
    for _ in range(2):
        assert owner.put(path, {"visible": True}, headers=_key()).ok()["visible"] is True
