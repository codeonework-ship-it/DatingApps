"""Lifestyle groups: create from friends, invite, accept, chat, roles, report, leave, join."""

from __future__ import annotations

import uuid

import pytest

from journeys import befriend


pytestmark = pytest.mark.journey("groups")


@pytest.fixture(scope="module")
def crew(make_member):
    owner = make_member("gr_own", "F", "M")
    friend = make_member("gr_fr", "M", "F")
    friend2 = make_member("gr_fr2", "F", "M")
    stranger = make_member("gr_str", "M", "F")
    befriend(owner, friend)
    befriend(owner, friend2)
    return owner, friend, friend2, stranger


@pytest.fixture(scope="module")
def group(crew):
    owner, friend, _, _ = crew
    created = owner.post("/engagement/groups", {
        "kind": "private", "name": "E2E Weekend hikers",
        "description": "Small crew for weekend trails", "invitee_user_ids": [friend.user_id]})
    assert created.status == 201, created.text
    assert friend.user_id in created["invited_user_ids"]
    return created["group"]


def _send(member, channel_id, body):
    return member.post(f"/social/channels/{channel_id}/messages",
                       {"client_message_id": str(uuid.uuid4()), "body": body})


def test_group_friends_lists_accepted_friends(crew):
    owner, friend, friend2, stranger = crew
    ids = {f["user_id"] for f in owner.get("/engagement/group-friends").ok()["friends"]}
    assert {friend.user_id, friend2.user_id} <= ids and stranger.user_id not in ids


def test_creator_is_owner_with_channel(group):
    assert group["my_role"] == "owner" and group["is_member"] and group["channel_id"]
    assert group["can_invite"] and group["can_manage"] and group["member_count"] == 1


def test_group_name_is_required(crew):
    owner, _, _, _ = crew
    response = owner.post("/engagement/groups", {"kind": "private", "name": "  "})
    assert response.status == 400, response.text


def test_invitee_sees_invite_and_accepts(group, crew):
    _, friend, _, _ = crew
    invites = friend.get("/engagement/group-invites").ok()["invites"]
    assert any(i["group_id"] == group["id"] and i["status"] == "pending" for i in invites)
    accepted = friend.post(f"/engagement/groups/{group['id']}/invites/respond",
                           {"decision": "accept"}).ok()
    assert accepted["group"]["is_member"] is True


def test_non_member_cannot_see_private_group_members_or_chat(group, crew):
    _, _, _, stranger = crew
    assert stranger.get(f"/engagement/groups/{group['id']}/members").status in (403, 404)
    assert stranger.get(f"/social/channels/{group['channel_id']}/messages").status in (403, 404)
    assert stranger.post(f"/engagement/groups/{group['id']}/join").status in (403, 404)


def test_group_chat_between_members(group, crew):
    owner, friend, _, _ = crew
    _send(friend, group["channel_id"], "Trail on Saturday?").ok()
    _send(owner, group["channel_id"], "Count me in").ok()
    bodies = [m["body"] for m in owner.get(
        f"/social/channels/{group['channel_id']}/messages").ok()["messages"]]
    assert {"Trail on Saturday?", "Count me in"} <= set(bodies)
    mine = next(g for g in friend.get("/engagement/groups").ok()["groups"] if g["id"] == group["id"])
    assert mine["is_member"] is True


def test_owner_invites_second_friend_who_declines(group, crew):
    owner, _, friend2, stranger = crew
    invited = owner.post(f"/engagement/groups/{group['id']}/invites",
                         {"invitee_user_ids": [friend2.user_id]}).ok()
    assert friend2.user_id in invited["invited_user_ids"]
    friend2.post(f"/engagement/groups/{group['id']}/invites/respond", {"decision": "decline"}).ok()
    members = {m["user_id"] for m in owner.get(f"/engagement/groups/{group['id']}/members").ok()["members"]}
    assert friend2.user_id not in members
    # Only friends can be invited.
    not_friend = owner.post(f"/engagement/groups/{group['id']}/invites",
                            {"invitee_user_ids": [stranger.user_id]})
    assert not_friend.status in (400, 403) or stranger.user_id not in not_friend.get("invited_user_ids", [])


def test_roles_promote_and_demote(group, crew):
    owner, friend, _, _ = crew
    path = f"/engagement/groups/{group['id']}/members/{friend.user_id}"
    members = owner.post(path, {"action": "make_moderator"}).ok()["members"]
    assert next(m for m in members if m["user_id"] == friend.user_id)["role"] == "moderator"
    # A moderator cannot touch the owner.
    assert friend.post(f"/engagement/groups/{group['id']}/members/{owner.user_id}",
                       {"action": "remove"}).status == 403
    members = owner.post(path, {"action": "make_member"}).ok()["members"]
    assert next(m for m in members if m["user_id"] == friend.user_id)["role"] == "member"
    assert owner.post(path, {"action": "crown"}).status == 400


def test_member_can_report_group(group, crew):
    _, friend, _, _ = crew
    bad = friend.post(f"/blog/reports/group/{group['id']}", {"reason": "spam"})
    assert bad.status == 400
    report = friend.post(f"/blog/reports/group/{group['id']}",
                         {"reason": "inappropriate", "description": "e2e automated report"})
    assert report.status in (200, 201, 202), report.text


def test_member_leaves_and_loses_chat_access(group, crew):
    owner, friend, _, _ = crew
    left = friend.post(f"/engagement/groups/{group['id']}/leave").ok()
    assert left["left"] is True and left["deleted"] is False
    assert _send(friend, group["channel_id"], "after leave").status == 404
    members = {m["user_id"] for m in owner.get(f"/engagement/groups/{group['id']}/members").ok()["members"]}
    assert friend.user_id not in members


def test_public_community_group_join_and_owner_delete(crew):
    owner, _, _, stranger = crew
    category = owner.get("/engagement/group-categories").ok()["categories"][0]["slug"]
    created = owner.post("/engagement/groups", {
        "kind": "community", "category_slug": category, "name": f"E2E Open Run Club {uuid.uuid4().hex[:4]}",
        "description": "Anyone can join for a Sunday 5K"})
    assert created.status == 201, created.text
    gid = created["group"]["id"]
    try:
        discover = stranger.get("/engagement/groups", params={"scope": "discover",
                                                              "category": category}).ok()
        assert gid in [g["id"] for g in discover["groups"]]
        joined = stranger.post(f"/engagement/groups/{gid}/join").ok()["group"]
        assert joined["is_member"] is True and joined["my_role"] == "member"
        channel = stranger.get(f"/engagement/groups/{gid}").ok()["group"]["channel_id"]
        _send(stranger, channel, "Hi runners").ok()
        # The owner can remove a member.
        owner.post(f"/engagement/groups/{gid}/members/{stranger.user_id}", {"action": "remove"}).ok()
        assert _send(stranger, channel, "still here?").status in (403, 404)
    finally:
        deleted = owner.delete(f"/engagement/groups/{gid}")
    assert deleted.status == 200 and deleted["deleted"] is True, deleted.text
    assert owner.get(f"/engagement/groups/{gid}").status == 404


def test_scope_must_be_mine_or_discover(crew):
    owner, _, _, _ = crew
    assert owner.get("/engagement/groups", params={"scope": "everything"}).status == 400


def test_owner_deletes_private_group(group, crew):
    owner, _, _, _ = crew
    assert owner.delete(f"/engagement/groups/{group['id']}").ok()["deleted"] is True
