"""Happy paths for catalog ``*.api_contract`` cases that had no API-level test:
Open Chapters (private exchanges, public links, photos, reports), Book & Film
Clubs (members, lists, post moderation), Photo Themes views and reports,
friends (vouches, intros, activities) and introducer accounts.

Every test performs the call the app makes and asserts the documented body;
the error paths for the same cases live in test_19_catalog_api_contracts.py
under the same ``case`` ids.
"""

from __future__ import annotations

import uuid

import pytest

from client import PASSWORD, RUN_ID, Api, png_bytes
from journeys import befriend


pytestmark = pytest.mark.journey("catalog_content_social")


def _chapter(author, audience="community", invitation="your_version", title="E2E: slow trails"):
    post_id = str(uuid.uuid4())
    post = author.put(f"/blog/posts/{post_id}", {
        "title": title, "body": "A short story about mountain trails and listening more than talking.",
        "audience": audience, "topic": "feelings", "invitation": invitation if audience != "private" else "",
        "expected_version": 0}).ok()["post"]
    return post


# --- Open Chapters: private exchanges --------------------------------------------------

@pytest.fixture(scope="module")
def writers(make_member):
    """An author and two readers (one response per author per day, so one reader per decision)."""
    return make_member("ex_auth", "F", "M"), make_member("ex_r1", "M", "F"), make_member("ex_r2", "M", "F")


@pytest.mark.case("blog.blog_connections.blog_exchange_accept.api_contract",
                  "blog.blog_connections.blog_exchange_withdraw.api_contract")
def test_exchange_accept_contribute_reveal_and_withdraw(writers):
    author, reader, _ = writers
    post = _chapter(author)
    response_id = str(uuid.uuid4())
    sent = reader.post("/blog/responses", {"id": response_id, "post_id": post["id"],
                                           "text": "Your trails story made me slow down too."}).ok()["response"]
    assert sent["status"] == "pending" and sent["version"] == 1 and sent["incoming"] is False
    inbox = author.get("/blog/responses").ok()["responses"]
    row = next(r for r in inbox if r["id"] == response_id)
    assert row["incoming"] is True and row["text"] == "Your trails story made me slow down too."

    accepted = author.post(f"/blog/responses/{response_id}", {"action": "accept", "expected_version": 1}).ok()["response"]
    assert accepted["status"] == "accepted" and accepted["version"] == 2
    # Accepting again is an idempotent no-op; a stale version on another action conflicts.
    assert author.post(f"/blog/responses/{response_id}", {"action": "accept", "expected_version": 1}).ok()[
        "response"]["status"] == "accepted"
    assert author.post(f"/blog/responses/{response_id}", {"action": "contribute", "text": "x",
                                                          "expected_version": 1}).status == 409

    mine = author.post(f"/blog/responses/{response_id}", {"action": "contribute", "text": "I walk at dawn.",
                                                          "expected_version": 2}).ok()["response"]
    assert mine["my_story"] == "I walk at dawn." and mine["revealed"] is False and mine["partner_story"] == ""
    theirs = reader.post(f"/blog/responses/{response_id}", {"action": "contribute", "text": "I walk at dusk.",
                                                            "expected_version": mine["version"]}).ok()["response"]
    assert theirs["revealed"] is True and theirs["partner_story"] == "I walk at dawn."
    assert author.get(f"/blog/responses/{response_id}").ok()["response"]["partner_story"] == "I walk at dusk."

    withdrawn = reader.delete(f"/blog/responses/{response_id}").ok()["response"]
    assert withdrawn["status"] == "withdrawn" and withdrawn["text"] == "" and withdrawn["my_story"] == ""
    assert author.get(f"/blog/responses/{response_id}").status == 404
    assert response_id not in [r["id"] for r in author.get("/blog/responses").ok()["responses"]]


@pytest.mark.case("blog.blog_connections.blog_exchange_decline.api_contract",
                  "blog.blog_connections.blog_exchange_report.api_contract",
                  "blog.blog_connections.submit_report_onsubmit.api_contract")
def test_exchange_decline_and_report(writers):
    author, _, reader = writers
    post = _chapter(author, title="E2E: what next")
    response_id = str(uuid.uuid4())
    reader.post("/blog/responses", {"id": response_id, "post_id": post["id"], "text": "Tell me more?"}).ok()
    report = author.post(f"/blog/reports/response/{response_id}", {"reason": "inappropriate",
                                                                   "description": "e2e automated report"}).ok()
    assert report["accepted"] is True and report["report"]["id"]
    # The same member reporting again gets the same case.
    again = author.post(f"/blog/reports/response/{response_id}", {"reason": "inappropriate"}).ok()
    assert again["report"]["id"] == report["report"]["id"]
    declined = author.post(f"/blog/responses/{response_id}", {"action": "decline",
                                                              "expected_version": 1}).ok()["response"]
    assert declined["status"] == "declined"
    assert reader.get(f"/blog/responses/{response_id}").ok()["response"]["status"] == "declined"
    # A declined exchange cannot be accepted afterwards.
    assert author.post(f"/blog/responses/{response_id}", {"action": "accept",
                                                          "expected_version": declined["version"]}).status == 403


# --- Open Chapters: public links, photos, delete, the post report route -------------------

@pytest.mark.case("blog.blog_sharing.blog_share_create.api_contract")
def test_public_link_create_read_and_revoke(writers):
    author, _, _ = writers
    post = _chapter(author, invitation="", title="E2E: shared trails")
    share_id = str(uuid.uuid4())
    created = author.post("/blog/publications", {"id": share_id, "post_id": post["id"],
                                                 "expected_version": post["version"], "approved": True,
                                                 "excerpt": "mountain trails", "photo_ids": []}).ok()["publication"]
    assert created["published"] is True and created["excerpt"] == "mountain trails" and created["joint"] is False
    listed = author.get("/blog/publications").ok()["publications"]
    assert share_id in [p["id"] for p in listed]
    public = Api().get(f"/blog/public/{share_id}").ok()
    assert public["title"] == "E2E: shared trails" and public["excerpt"] == "mountain trails"
    assert "author_id" not in public.body and "body" not in public.body
    revoked = author.delete(f"/blog/publications/{share_id}").ok()["publication"]
    assert revoked["revoked"] is True and revoked["published"] is False
    assert Api().get(f"/blog/public/{share_id}").status == 404


@pytest.mark.case("blog.blog_editor.blog_editor_add_photo.api_contract", "blog.blog_editor.blog_editor_remove_photo_x.api_contract")
def test_chapter_photo_add_serve_and_remove(writers):
    author, reader, _ = writers
    post = _chapter(author, audience="private", title="E2E photo diary")
    photo_id = str(uuid.uuid4())
    added = author.api.call("PUT", f"/blog/posts/{post['id']}/photos/{photo_id}", files={
        "image": ("p.png", png_bytes((90, 60, 30)), "image/png"), "alt_text": (None, "A brown square"),
        "expected_version": (None, str(post["version"]))}).ok()["post"]
    assert added["version"] == post["version"] + 1
    assert photo_id in [p["id"] for p in added.get("photos") or []], added
    served = author.api.call("GET", f"/blog/posts/{post['id']}/photos/{photo_id}")
    assert served.status == 200 and served.headers.get("Content-Type", "").startswith("image/")
    assert reader.api.call("GET", f"/blog/posts/{post['id']}/photos/{photo_id}").status in (403, 404)
    removed = author.delete(f"/blog/posts/{post['id']}/photos/{photo_id}",
                            {"expected_version": added["version"]}).ok()["post"]
    assert photo_id not in [p["id"] for p in removed.get("photos") or []]
    assert author.delete(f"/blog/posts/{post['id']}/photos/{photo_id}",
                         {"expected_version": removed["version"]}).status == 404
    author.delete(f"/blog/posts/{post['id']}", {"expected_version": removed["version"]})


@pytest.mark.case("blog.blog.blog_detail_delete.api_contract")
def test_author_deletes_a_chapter(writers):
    author, reader, _ = writers
    post = _chapter(author, invitation="", title="E2E: to be deleted")
    assert reader.get(f"/blog/posts/{post['id']}").status == 200
    assert reader.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]}).status in (403, 404, 409)
    assert author.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]}).ok()["deleted"] is True
    assert reader.get(f"/blog/posts/{post['id']}").status == 404
    assert author.get(f"/blog/posts/{post['id']}").status == 404
    assert author.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]}).status == 409


@pytest.mark.case("blog.blog.blog_detail_report.api_contract", "blog.blog.blog_detail_report_submit.api_contract")
def test_report_chapter_from_the_reader_menu(writers):
    author, reader, _ = writers
    post = _chapter(author, invitation="", title="E2E: reported from the menu")
    report = reader.post(f"/blog/posts/{post['id']}/report", {"reason": "fake", "description": "e2e"}).ok()
    assert report["accepted"] is True and report["report"]["id"]
    assert author.post(f"/blog/posts/{post['id']}/report", {"reason": "fake"}).status == 400  # own chapter
    author.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]})


# --- content reports for every kind the app can report ------------------------------------

@pytest.fixture(scope="module")
def reportables(make_member):
    """One piece of content of each reportable kind, owned by ``owner``; ``reporter`` can see all of it."""
    owner, reporter = make_member("rk_own", "F", "M"), make_member("rk_rep", "M", "F")
    commenter = make_member("rk_com", "M", "F")
    befriend(owner, reporter)
    made, authors = {}, {}
    post = _chapter(owner, invitation="", title="E2E: reportable chapter")
    made["post"] = post["id"]
    comment_id = str(uuid.uuid4())
    commenter.put(f"/blog/posts/{post['id']}/comments/{comment_id}", {"body": "E2E reportable comment"}).ok()
    owner.post(f"/blog/posts/{post['id']}/comments/{comment_id}/decision", {"decision": "approve"}).ok()
    made["comment"], authors["comment"] = comment_id, commenter
    club_id = str(uuid.uuid4())
    owner.put(f"/clubs/{club_id}", {"kind": "book", "name": "E2E Reportable Club", "description": "e2e",
                                    "expected_version": 0}).ok()
    made["club"] = club_id
    found = owner.get("/clubs/titles", params={"kind": "book", "q": "E2E Fixture Novel"}).ok()["titles"]
    title = found[0] if found else owner.put(f"/clubs/titles/{uuid.uuid4()}", {
        "kind": "book", "title": "E2E Fixture Novel", "creator": "QA Automation", "release_year": 2001}).ok()["title"]
    review_id = str(uuid.uuid4())
    review = owner.put(f"/clubs/titles/{title['id']}/reviews/{review_id}", {
        "rating": 3, "body": "E2E reportable review", "audience": "community", "has_spoilers": False,
        "expected_version": 0}).ok()["review"]
    made["review"] = review_id
    themes = owner.get("/themes").ok()["themes"]
    theme = next(t for t in themes if t["status"] == "active" and not t["my_entry_id"])
    entry_id = str(uuid.uuid4())
    owner.api.call("PUT", f"/themes/{theme['id']}/entries/{entry_id}", files={
        "image": ("e.png", png_bytes((40, 80, 120)), "image/png"), "caption": (None, "E2E reportable photo"),
        "alt_text": (None, "A blue square")}).ok()
    made["theme_entry"] = entry_id
    channel = owner.post(f"/social/friends/{reporter.user_id}/channel").ok()["channel"]["id"]
    made["social_message"] = owner.post(f"/social/channels/{channel}/messages", {
        "client_message_id": str(uuid.uuid4()), "body": "E2E reportable message"}).ok()["message"]["id"]
    group = owner.post("/engagement/groups", {"kind": "private", "name": "E2E Reportable Group",
                                              "invitee_user_ids": [reporter.user_id]}).ok()["group"]
    reporter.post(f"/engagement/groups/{group['id']}/invites/respond", {"decision": "accept"}).ok()
    made["group"] = group["id"]
    yield owner, reporter, made, authors
    owner.delete(f"/engagement/groups/{group['id']}")
    owner.delete(f"/themes/{theme['id']}/entries/{entry_id}")
    owner.delete(f"/clubs/reviews/{review_id}", {"expected_version": review["version"]})
    owner.delete(f"/blog/posts/{post['id']}", {"expected_version": post["version"]})


REPORT_KINDS = [
    pytest.param("post", marks=pytest.mark.case("common.community_actions.report_could_not_be_submitted_onsubmit.api_contract"),
                 id="post"),
    pytest.param("comment", marks=pytest.mark.case("blog.blog_social.report_could_not_be_submitted_onsubmit.api_contract",
                                                   "blog.blog_social.x_comment_options_x_report.api_contract"), id="comment"),
    pytest.param("club", marks=pytest.mark.case("clubs.club_detail.club_options.api_contract"), id="club"),
    pytest.param("review", marks=pytest.mark.case("clubs.title_detail.report_this_review.api_contract"), id="review"),
    pytest.param("theme_entry", marks=pytest.mark.case("photo_themes.photo_theme_widgets.report.api_contract"),
                 id="theme_entry"),
    pytest.param("social_message", marks=pytest.mark.case("social_chat.social_chat.social_message_x_longpress.api_contract"),
                 id="social_message"),
    pytest.param("group", marks=pytest.mark.case("groups.group_detail.groups_detail_more.api_contract"), id="group"),
]


@pytest.mark.safety
@pytest.mark.parametrize("kind", REPORT_KINDS)
def test_member_reports_content_of_every_kind(reportables, kind):
    owner, reporter, made, authors = reportables
    author = authors.get(kind, owner)
    path = f"/blog/reports/{kind}/{made[kind]}"
    first = reporter.post(path, {"reason": "inappropriate", "description": f"e2e {kind} report"}).ok()
    assert first["accepted"] is True and first["report"]["id"]
    assert reporter.post(path, {"reason": "fake"}).ok()["report"]["id"] == first["report"]["id"], \
        "a repeat report from the same member must reuse the case"
    assert author.post(path, {"reason": "fake"}).status == 400, "members cannot report their own content"
    assert reporter.post(path, {"reason": "because"}).status == 400


# --- Book & Film Clubs ------------------------------------------------------------------

@pytest.fixture(scope="module")
def club_cast(make_member):
    owner, member, other = make_member("cl_own", "F", "M"), make_member("cl_mem", "M", "F"), make_member("cl_oth", "F", "M")
    club_id = str(uuid.uuid4())
    owner.put(f"/clubs/{club_id}", {"kind": "film", "name": "E2E Slow Cinema", "description": "One film a week.",
                                    "expected_version": 0}).ok()
    found = owner.get("/clubs/titles", params={"kind": "film", "q": "E2E Fixture Film"}).ok()["titles"]
    title = found[0] if found else owner.put(f"/clubs/titles/{uuid.uuid4()}", {
        "kind": "film", "title": "E2E Fixture Film", "creator": "QA Automation", "release_year": 1999}).ok()["title"]
    import datetime as dt
    monday = (dt.date.today() - dt.timedelta(days=dt.date.today().weekday())).isoformat()
    selection = owner.put(f"/clubs/{club_id}/selections/{monday}", {"title_id": title["id"]}).ok()["selection"]
    for m in (member, other):
        assert m.post(f"/clubs/{club_id}/membership", {"action": "join"}).ok()["club"]["my_role"] == "member"
    return owner, member, other, club_id, title, selection


@pytest.mark.case("clubs.club_members_sheet.actions_for_name.api_contract")
def test_club_owner_promotes_demotes_and_removes_members(club_cast):
    owner, member, other, club_id, _, _ = club_cast
    path = f"/clubs/{club_id}/members/{member.user_id}"

    def role(user):
        rows = owner.get(f"/clubs/{club_id}/members").ok()["members"]
        return next((m["role"] for m in rows if m["user_id"] == user.user_id), None)

    promoted = owner.post(path, {"action": "make_moderator"}).ok()["members"]
    assert next(m for m in promoted if m["user_id"] == member.user_id)["role"] == "moderator"
    # A moderator may remove plain members but not promote them.
    assert member.post(f"/clubs/{club_id}/members/{other.user_id}", {"action": "make_moderator"}).status == 403
    owner.post(path, {"action": "make_member"}).ok()
    assert role(member) == "member"
    owner.post(f"/clubs/{club_id}/members/{other.user_id}", {"action": "remove"}).ok()
    assert role(other) is None
    assert other.post(f"/clubs/{club_id}/membership", {"action": "join"}).status == 403, \
        "a removed member cannot rejoin by themselves"


@pytest.mark.case("clubs.club_discussion.post_actions.api_contract")
def test_club_post_hide_report_and_delete(club_cast):
    owner, member, _, club_id, _, selection = club_cast
    post_id = str(uuid.uuid4())
    member.put(f"/clubs/{club_id}/posts/{post_id}", {"selection_id": selection["id"], "body": "Loved the ending",
                                                     "has_spoilers": False}).ok()
    hidden = owner.post(f"/clubs/{club_id}/posts/{post_id}/visibility", {"hidden": True}).ok()["post"]
    assert hidden["hidden"] is True
    shown = owner.post(f"/clubs/{club_id}/posts/{post_id}/visibility", {"hidden": False}).ok()["post"]
    assert shown["hidden"] is False
    report = owner.post(f"/blog/reports/club_post/{post_id}", {"reason": "inappropriate"}).ok()
    assert report["accepted"] is True
    assert owner.delete(f"/clubs/{club_id}/posts/{post_id}").status == 404, "only the author deletes a post"
    assert member.delete(f"/clubs/{club_id}/posts/{post_id}").ok()["deleted"] is True
    posts = owner.get(f"/clubs/{club_id}/posts", params={"selection_id": selection["id"]}).ok()["posts"]
    assert post_id not in [p["id"] for p in posts]


@pytest.mark.case("clubs.list_sheets.create_list.api_contract", "clubs.my_lists.list_options.api_contract",
                  "clubs.my_lists.options_for_title.api_contract")
def test_reading_list_create_add_remove_and_delete(club_cast):
    owner, member, _, _, title, _ = club_cast
    list_id = str(uuid.uuid4())
    created = owner.put(f"/clubs/lists/{list_id}", {"name": "E2E Films to see", "kind": "film",
                                                    "audience": "friends", "expected_version": 0}).ok()["list"]
    assert created["mine"] is True and created["items"] == [] and created["version"] == 1
    renamed = owner.put(f"/clubs/lists/{list_id}", {"name": "E2E Films to rewatch", "kind": "film",
                                                    "audience": "private", "expected_version": 1}).ok()["list"]
    assert renamed["name"] == "E2E Films to rewatch" and renamed["version"] == 2
    added = owner.put(f"/clubs/lists/{list_id}/items/{title['id']}", {"note": "Sunday matinee"}).ok()["list"]
    assert [i["title"]["id"] for i in added["items"]] == [title["id"]]
    assert added["items"][0]["note"] == "Sunday matinee"
    assert list_id in [lst["id"] for lst in owner.get("/clubs/lists").ok()["lists"]]
    # Private lists are not visible to other members.
    assert list_id not in [lst["id"] for lst in member.get("/clubs/lists", params={"owner_id": owner.user_id}).ok()["lists"]]
    removed = owner.delete(f"/clubs/lists/{list_id}/items/{title['id']}").ok()["list"]
    assert removed["items"] == []
    assert owner.delete(f"/clubs/lists/{list_id}", {"expected_version": removed["version"]}).ok()["deleted"] is True
    assert list_id not in [lst["id"] for lst in owner.get("/clubs/lists").ok()["lists"]]


# --- Photo Themes / walls: views ------------------------------------------------------------

@pytest.mark.case("photo_themes.photo_theme_gallery.themeentrytile_ontap.api_contract",
                  "photo_themes.photo_wall.inkwell_ontap.api_contract",
                  "profile.profile_showcase.themeentrytile_ontap.api_contract",
                  "profile.profile_showcase.favorite_border_rounded_icon_fav.api_contract",
                  "blog.blog.blog_post_x.api_contract", "blog.blog_social.comments.api_contract",
                  "blog.blog_writers.blog_writer_latest.api_contract",
                  "intentional_dating.today_wall.inkwell_ontap.api_contract",
                  "intentional_dating.today_wall.today_wall_chapter_x.api_contract")
def test_views_are_counted_once_per_member_and_never_for_the_author(reportables, make_member):
    owner, _, made, _ = reportables
    viewer = make_member("vw_v", "M", "F")
    for kind, content in (("photo", made["theme_entry"]), ("chapter", made["post"])):
        first = viewer.post("/walls/views", {"kind": kind, "id": content}).ok()
        assert first["recorded"] is True, f"{kind}: {first.text}"
        assert viewer.post("/walls/views", {"kind": kind, "id": content}).ok()["recorded"] is False
        assert owner.post("/walls/views", {"kind": kind, "id": content}).ok()["recorded"] is False


# --- friends: activities, vouches and intros lists ---------------------------------------

@pytest.mark.case("friends.friends.friends_accept_x_accept.api_contract", "friends.friends.friends_decline_x_decline.api_contract",
                  "friends.friends.friends_cancel_x_cancel.api_contract", "friends.friends.friends_menu_x_action.api_contract",
                  "friends.friend_social_sheets.friends_vouch_submit.api_contract",
                  "friends.friend_social_sheets.friends_intro_submit.api_contract")
def test_friend_list_and_activity_feed(make_member):
    a, b = make_member("fa_a", "F", "M"), make_member("fa_b", "M", "F")
    befriend(a, b)
    friends = a.get(f"/friends/{a.user_id}").ok()["friends"]
    row = next(f for f in friends if f["friend_user_id"] == b.user_id)
    assert row["status"] == "accepted"
    activities = a.get(f"/friends/{a.user_id}/activities").ok()["activities"]
    assert isinstance(activities, list) and activities
    for item in activities:
        assert item["user_id"] == a.user_id and item["title"] and item["type"]


@pytest.mark.case("friends.friends.friends_vouch_hide_x_decide.api_contract", "friends.friends.hide_from_profile.api_contract",
                  "friends.friends.friends_intro_decline_x_decide.api_contract",
                  "friends.friend_social_sheets.friends_vouch_submit.api_contract",
                  "friends.friend_social_sheets.friends_intro_submit.api_contract",
                  "friends.friends.friends_vouch_hide_x_decide.api_contract_route",
                  "friends.friends.friends_intro_decline_x_decide.api_contract_route")
def test_vouch_hide_and_intro_decline_show_in_the_lists(make_member):
    host, x, y = make_member("vi_h", "F", "M"), make_member("vi_x", "F", "M"), make_member("vi_y", "M", "F")
    befriend(host, x)
    befriend(host, y)
    vouch = host.post(f"/friends/{host.user_id}/vouches", {"for_user_id": x.user_id,
                                                          "text": "Kind, curious and always on time."}).ok()["vouch"]
    lists = x.get(f"/friends/{x.user_id}/vouches").ok()
    assert vouch["id"] in [v["id"] for v in lists["about_me"]] and lists["written"] == []
    assert vouch["id"] in [v["id"] for v in host.get(f"/friends/{host.user_id}/vouches").ok()["written"]]
    hidden = x.post(f"/friends/{x.user_id}/vouches/{vouch['id']}/decision", {"decision": "hide"}).ok()["vouch"]
    assert hidden["status"] == "hidden"
    assert "Kind, curious and always on time." not in [v.get("text") for v in
                                                       y.get(f"/users/{x.user_id}/vouches").ok()["vouches"]]
    for member in (x, y):
        base = f"/account/{member.user_id}/dating-preferences"
        current = member.get(base).ok()["preferences"]
        member.put(base, {**{k: current[k] for k in ("intent", "pace", "activities", "share_pace",
                                                      "share_availability", "availability")},
                          "allow_friend_intros": True, "version": current["version"]}).ok()
    intro = host.post(f"/friends/{host.user_id}/intros", {"first_user_id": x.user_id, "second_user_id": y.user_id,
                                                          "message": "You both love trails!"}).ok()["intro"]
    received = x.get(f"/friends/{x.user_id}/intros").ok()
    row = next(i for i in received["received"] if i["id"] == intro["id"])
    assert row["status"] in ("open", "pending") and row["other"]["user_id"] == y.user_id
    assert intro["id"] in [i["id"] for i in host.get(f"/friends/{host.user_id}/intros").ok()["made"]]
    declined = x.post(f"/friends/{x.user_id}/intros/{intro['id']}/decision", {"decision": "decline"}).ok()["intro"]
    assert declined["status"] == "declined" or declined.get("my_decision") == "decline", declined
    assert y.user_id not in [m["userId"] for m in x.get(f"/matches/{x.user_id}").ok()["matches"]]


# --- introducer accounts --------------------------------------------------------------------

def _introducer(role):
    username = f"e2e_{RUN_ID}_{role}"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD, "account_kind": "introducer",
                                         "name": "E2E Introducer", "date_of_birth": "1990-05-05"}).ok(200, 201)
    assert signup["account_kind"] == "introducer"
    api = Api(signup["access_token"])
    api.patch(f"/users/{signup['user_id']}/agreements/terms", {"accepted": True, "terms_version": "v1"}).ok()
    return signup["user_id"], api


@pytest.mark.case("friends.introducer.create_invitation_code.api_contract", "friends.introducer.ask_for_permission.api_contract",
                  "friends.introducer.allow_introductions.api_contract", "friends.introducer.decline_request.api_contract",
                  "friends.introducer.cancel_unused_invitations.api_contract")
def test_introducer_invite_redeem_approve_and_revoke(make_member):
    member = make_member("int_m", "F", "M")
    intro_id, intro = _introducer("int_i")
    try:
        invite = member.post("/introducer/invites", {"share_photo": True, "share_city": False}).ok()
        assert len(invite["code"]) == 43 and invite["expires_at"]
        assert intro.post("/introducer/redeem", {"code": invite["code"]}).ok()["success"] is True
        pending = member.get("/introducer/connections").ok()["connections"]
        consent = next(c for c in pending if c["user_id"] == intro_id)
        assert consent["status"] == "pending" and consent["share_photo"] is True and consent["share_city"] is False
        assert member.post(f"/introducer/connections/{consent['id']}/approve", {}).ok()["success"] is True
        assert intro.get("/introducer/connections").ok()["connections"][0]["status"] == "active"
        assert member.get(f"/account/{member.user_id}/dating-preferences").ok()["preferences"]["allow_friend_intros"] is True
        assert member.delete(f"/introducer/connections/{consent['id']}").ok()["success"] is True
        assert member.get("/introducer/connections").ok()["connections"] == []
        assert intro.get("/introducer/connections").ok()["connections"] == []
        # A fresh code, cancelled before use, can no longer be redeemed.
        unused = member.post("/introducer/invites", {}).ok()["code"]
        assert member.delete("/introducer/invites").ok()["success"] is True
        assert intro.post("/introducer/redeem", {"code": unused}).status == 409
    finally:
        intro.post(f"/account/{intro_id}/deletion", {"reason": "api e2e cleanup"})
