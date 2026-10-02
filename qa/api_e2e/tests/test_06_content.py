"""Open Chapters (blog), empathetic reactions, Photo Themes, Book & Film Clubs, Today wall.

Reading/reacting/commenting is covered; the rich-text editor contract is being
rebuilt by another workstream, so posts here use the plain title/body fields.
"""

from __future__ import annotations

import datetime as dt
import uuid

import pytest

from client import png_bytes


pytestmark = pytest.mark.journey("content")

REACTIONS = ["love", "hear_you", "me_too", "with_you", "hug", "proud"]


@pytest.fixture(scope="module")
def duo(make_member):
    return make_member("ct_auth", "F", "M"), make_member("ct_read", "M", "F")


@pytest.fixture(scope="module")
def chapter(duo):
    author, _ = duo
    post_id = str(uuid.uuid4())
    saved = author.put(f"/blog/posts/{post_id}", {
        "title": "E2E: learning to slow down",
        "body": "A short story about mountain trails and listening more than talking.",
        "audience": "community", "topic": "feelings", "expected_version": 0}).ok()
    yield saved["post"]
    author.delete(f"/blog/posts/{post_id}", {"expected_version": saved["post"]["version"]})


# --- Open Chapters ---------------------------------------------------------

def test_topics_are_listed(duo):
    topics = duo[0].get("/blog/topics").ok()["topics"]
    assert {"feelings", "love", "growth"} <= {t["slug"] for t in topics}


def test_publish_validation(duo):
    author, _ = duo
    base = f"/blog/posts/{uuid.uuid4()}"
    assert author.put(base, {"title": "", "body": "", "audience": "community",
                             "expected_version": 0}).status == 400
    assert author.put(base, {"title": "t", "body": "b", "audience": "everyone",
                             "expected_version": 0}).status == 400
    assert author.put(base, {"title": "t" * 101, "body": "b", "audience": "community",
                             "expected_version": 0}).status == 400


def test_community_chapter_is_visible_by_scope_and_topic(chapter, duo):
    _, reader = duo
    community = reader.get("/blog/posts", params={"scope": "community"}).ok()["posts"]
    assert chapter["id"] in [p["id"] for p in community]
    by_topic = reader.get("/blog/posts", params={"scope": "community", "topic": "feelings"}).ok()["posts"]
    assert chapter["id"] in [p["id"] for p in by_topic]
    other_topic = reader.get("/blog/posts", params={"scope": "community", "topic": "love"}).ok()["posts"]
    assert chapter["id"] not in [p["id"] for p in other_topic]
    assert reader.get("/blog/posts", params={"scope": "nonsense"}).status == 400


def _timestamps(value, key=""):
    """Every string under a *_at key, recursively."""
    if isinstance(value, dict):
        for k, v in value.items():
            yield from _timestamps(v, k)
    elif isinstance(value, list):
        for v in value:
            yield from _timestamps(v, key)
    elif isinstance(value, str) and key.endswith("_at") and value:
        yield key, value


def test_blog_timestamps_are_utc(chapter, duo):
    """Regression API-05: blog/social payloads carried the server's local offset (+05:30)."""
    _, reader = duo
    post = reader.get(f"/blog/posts/{chapter['id']}").ok().body
    feed = reader.get("/blog/posts", params={"scope": "community"}).ok().body
    stamps = list(_timestamps(post)) + list(_timestamps(feed))
    assert stamps, "expected timestamped fields in blog payloads"
    for key, value in stamps:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        assert parsed.utcoffset() == dt.timedelta(0), f"{key}={value} is not UTC"


def test_private_chapter_is_hidden_from_others(duo):
    author, reader = duo
    post_id = str(uuid.uuid4())
    author.put(f"/blog/posts/{post_id}", {"title": "Diary", "body": "only me",
                                          "audience": "private", "expected_version": 0}).ok()
    assert reader.get(f"/blog/posts/{post_id}").status in (403, 404)
    mine = author.get("/blog/posts", params={"scope": "mine"}).ok()["posts"]
    assert post_id in [p["id"] for p in mine]


def test_empathetic_reactions(chapter, duo):
    author, reader = duo
    path = f"/blog/posts/{chapter['id']}/like"
    post = reader.put(path, {"reaction": "hug"}).ok()["post"]
    assert post["my_reaction"] == "hug" and post["reactions"] == {"hug": 1}
    # Changing the reaction is still one like.
    post = reader.put(path, {"reaction": "hear_you"}).ok()["post"]
    assert post["reactions"] == {"hear_you": 1}
    # A plain like keeps the chosen reaction.
    post = reader.api.call("PUT", path).ok()["post"]
    assert post["my_reaction"] == "hear_you"
    assert reader.put(path, {"reaction": "angry"}).status == 400
    assert author.get(f"/blog/posts/{chapter['id']}").ok()["post"]["reactions"] == {"hear_you": 1}
    post = reader.delete(path).ok()["post"]
    assert post["my_reaction"] == "" and not post.get("reactions")


def test_comments_need_author_approval(chapter, duo):
    author, reader = duo
    comment_id = str(uuid.uuid4())
    comment = reader.put(f"/blog/posts/{chapter['id']}/comments/{comment_id}",
                         {"body": "This made me smile."}).ok()["comment"]
    assert comment["status"] == "pending" and comment["mine"] is True
    listed = author.get(f"/blog/posts/{chapter['id']}/comments").ok()["comments"]
    row = next(c for c in listed if c["id"] == comment_id)
    assert row["can_moderate"] is True
    # Only the author decides.
    assert reader.post(f"/blog/posts/{chapter['id']}/comments/{comment_id}/decision",
                       {"decision": "approve"}).status in (403, 404)
    approved = author.post(f"/blog/posts/{chapter['id']}/comments/{comment_id}/decision",
                           {"decision": "approve"}).ok()
    assert approved["comment"]["status"] == "approved"
    reader.delete(f"/blog/posts/{chapter['id']}/comments/{comment_id}").ok()


def test_follow_writer_and_subscriptions_feed(chapter, duo):
    author, reader = duo
    sub = reader.put(f"/blog/authors/{author.user_id}/subscription").ok()
    assert sub["subscribed"] is True and sub["subscriber_count"] >= 1
    writers = reader.get("/blog/subscriptions").ok()["writers"]
    assert author.user_id in [w["author_id"] for w in writers]
    feed = reader.get("/blog/posts", params={"scope": "subscriptions"}).ok()["posts"]
    assert chapter["id"] in [p["id"] for p in feed]
    assert author.put(f"/blog/authors/{author.user_id}/subscription").status in (400, 403)
    assert reader.delete(f"/blog/authors/{author.user_id}/subscription").ok()["subscribed"] is False


def test_top_rated_and_featured_feeds_load(duo):
    _, reader = duo
    assert isinstance(reader.get("/blog/posts", params={"scope": "top"}).ok()["posts"], list)
    featured = reader.get("/blog/featured")
    assert featured.status == 200, featured.text


def test_report_chapter(chapter, duo):
    _, reader = duo
    report = reader.post(f"/blog/reports/post/{chapter['id']}",
                         {"reason": "fake", "description": "e2e automated report"})
    assert report.status in (200, 201, 202), report.text


# --- Photo Themes ----------------------------------------------------------

@pytest.fixture(scope="module")
def theme_entry(duo):
    author, _ = duo
    themes = author.get("/themes").ok()
    assert themes["eligible"] is True
    theme = next(t for t in themes["themes"] if t["status"] == "active" and not t["my_entry_id"])
    entry_id = str(uuid.uuid4())
    response = author.api.call(
        "PUT", f"/themes/{theme['id']}/entries/{entry_id}",
        files={"image": ("e2e.png", png_bytes((0x88, 0x44, 0xAA)), "image/png"),
               "caption": (None, "E2E: my perfect Sunday light"),
               "alt_text": (None, "A purple square standing in for a sunny window")})
    assert response.status in (200, 201), response.text
    yield theme, response["entry"]
    author.delete(f"/themes/{theme['id']}/entries/{entry_id}")


def test_photo_entry_validation(duo):
    author, _ = duo
    theme = author.get("/themes").ok()["themes"][0]
    no_caption = author.api.call(
        "PUT", f"/themes/{theme['id']}/entries/{uuid.uuid4()}",
        files={"image": ("e.png", png_bytes(), "image/png"), "caption": (None, ""),
               "alt_text": (None, "alt")})
    assert no_caption.status == 400
    not_image = author.api.call(
        "PUT", f"/themes/{theme['id']}/entries/{uuid.uuid4()}",
        files={"image": ("e.txt", b"hello", "text/plain"), "caption": (None, "c"),
               "alt_text": (None, "alt")})
    assert not_image.status in (400, 415)


def test_photo_entry_listed_and_photo_served(theme_entry, duo):
    _, reader = duo
    theme, entry = theme_entry
    entries = reader.get(f"/themes/{theme['id']}/entries").ok()["entries"]
    assert entry["id"] in [e["id"] for e in entries]
    photo = reader.api.session.get(
        f"{reader.api.base}/themes/{theme['id']}/entries/{entry['id']}/photo",
        headers={"Authorization": f"Bearer {reader.token}"}, timeout=15)
    assert photo.status_code == 200 and photo.headers["Content-Type"].startswith("image/")


def test_one_entry_per_theme(theme_entry, duo):
    author, _ = duo
    theme, _ = theme_entry
    again = author.api.call(
        "PUT", f"/themes/{theme['id']}/entries/{uuid.uuid4()}",
        files={"image": ("e.png", png_bytes(), "image/png"), "caption": (None, "second"),
               "alt_text": (None, "second alt")})
    assert again.status == 409, again.text


def test_photo_reactions_and_comments(theme_entry, duo):
    author, reader = duo
    theme, entry = theme_entry
    base = f"/themes/{theme['id']}/entries/{entry['id']}"
    liked = reader.put(f"{base}/like", {"reaction": "proud"}).ok()["entry"]
    assert liked["my_reaction"] == "proud"
    comment_id = str(uuid.uuid4())
    reader.put(f"{base}/comments/{comment_id}", {"body": "Gorgeous light!"}).ok()
    decided = author.post(f"{base}/comments/{comment_id}/decision", {"decision": "approve"}).ok()
    assert decided["comment"]["status"] == "approved"
    reader.delete(f"{base}/like").ok()


def test_photo_wall_and_cover_of_the_week_load(duo):
    _, reader = duo
    assert isinstance(reader.get("/themes/wall").ok()["entries"], list)
    cover = reader.get("/themes/cover").ok()
    assert "cover" in cover.body
    if cover["cover"]:
        assert cover["cover"]["entry"]["id"]


# --- Today wall -------------------------------------------------------------

def test_today_wall_celebrations_and_views(chapter, duo):
    _, reader = duo
    today = reader.get("/walls/today").ok()
    assert today["day"] == dt.datetime.now(dt.timezone.utc).date().isoformat() or today["day"]
    assert isinstance(today["items"], list)
    assert isinstance(reader.get("/walls/celebrations").ok()["celebrations"], list)
    view = reader.post("/walls/views", {"kind": "chapter", "id": chapter["id"]})
    assert view.status in (200, 201, 202, 204), view.text
    assert reader.post("/walls/views", {"kind": "bogus", "id": chapter["id"]}).status == 400


# --- Book & Film Clubs ------------------------------------------------------

@pytest.fixture(scope="module")
def club(duo):
    owner, _ = duo
    club_id = str(uuid.uuid4())
    created = owner.put(f"/clubs/{club_id}", {"kind": "book", "name": "E2E Slow Readers",
                                              "description": "One chapter a week, no rush.",
                                              "expected_version": 0}).ok()["club"]
    # Reuse one catalogue title across runs rather than adding a new one each time.
    found = owner.get("/clubs/titles", params={"kind": "book", "q": "E2E Fixture Novel"}).ok()["titles"]
    if found:
        title = found[0]
    else:
        title = owner.put(f"/clubs/titles/{uuid.uuid4()}", {
            "kind": "book", "title": "E2E Fixture Novel", "creator": "QA Automation",
            "release_year": 2001}).ok()["title"]
    return created, title


def test_club_owner_picks_title_for_this_week(club, duo):
    owner, _ = duo
    created, title = club
    assert created["my_role"] == "owner" and created["member_count"] == 1
    today = dt.date.today()
    monday = today - dt.timedelta(days=today.weekday())
    selection = owner.put(f"/clubs/{created['id']}/selections/{monday.isoformat()}",
                          {"title_id": title["id"], "note": "Start with part one"}).ok()["selection"]
    assert selection["title"]["id"] == title["id"]
    not_monday = owner.put(f"/clubs/{created['id']}/selections/{(monday + dt.timedelta(days=1)).isoformat()}",
                           {"title_id": title["id"]})
    assert not_monday.status == 400


def test_member_joins_and_discusses_the_pick(club, duo):
    owner, reader = duo
    created, _ = club
    outsider_post = reader.put(f"/clubs/{created['id']}/posts/{uuid.uuid4()}",
                               {"selection_id": str(uuid.uuid4()), "body": "hi"})
    assert outsider_post.status == 403, outsider_post.text
    joined = reader.post(f"/clubs/{created['id']}/membership", {"action": "join"}).ok()["club"]
    assert joined["my_role"] == "member" and joined["member_count"] == 2
    selection_id = joined["current_selection"]["id"]
    post_id = str(uuid.uuid4())
    reader.put(f"/clubs/{created['id']}/posts/{post_id}",
               {"selection_id": selection_id, "body": "Loving the opening chapter",
                "has_spoilers": False}).ok()
    posts = owner.get(f"/clubs/{created['id']}/posts", params={"selection_id": selection_id}).ok()
    assert post_id in [p["id"] for p in posts["posts"]]
    members = owner.get(f"/clubs/{created['id']}/members").ok()
    assert reader.user_id in [m["user_id"] for m in members["members"]]
    assert reader.post(f"/clubs/{created['id']}/membership", {"action": "maybe"}).status == 400
    reader.post(f"/clubs/{created['id']}/membership", {"action": "leave"}).ok()


def test_title_review_rating_validation(club, duo):
    _, reader = duo
    _, title = club
    review_id = str(uuid.uuid4())
    bad = reader.put(f"/clubs/titles/{title['id']}/reviews/{review_id}",
                     {"rating": 6, "body": "x", "audience": "community", "expected_version": 0})
    assert bad.status == 400
    review = reader.put(f"/clubs/titles/{title['id']}/reviews/{review_id}",
                        {"rating": 4, "body": "Warm and quiet.", "audience": "community",
                         "has_spoilers": False, "expected_version": 0})
    assert review.status == 200, review.text
    version = review["review"]["version"]
    # Regression API-04: a DELETE without a JSON body names the missing field
    # instead of returning the raw decoder error "EOF".
    bodyless = reader.delete(f"/clubs/reviews/{review_id}")
    assert bodyless.status == 400, bodyless.text
    assert "expected_version" in bodyless["error"] and "EOF" not in bodyless.text
    reader.delete(f"/clubs/reviews/{review_id}", {"expected_version": version}).ok()
