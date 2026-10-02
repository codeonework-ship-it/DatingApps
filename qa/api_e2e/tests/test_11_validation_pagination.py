"""Input validation and pagination bounds.

Payloads: empty, max length and max+1, unicode / emoji / RTL / zero-width,
HTML and script tags (must come back as inert JSON strings, never rendered),
SQL-looking strings, malformed JSON and wrong types. Lists: limit=0, negative,
non-numeric, huge, and malformed cursors must never produce a 5xx.
"""

from __future__ import annotations

import uuid

import pytest

from journeys import befriend, match


pytestmark = [pytest.mark.journey("validation"), pytest.mark.validation]

TRICKY = [
    "مرحبا שלום",          # Arabic + Hebrew (RTL)
    "emoji \U0001F469‍❤️‍\U0001F468 \U0001F1EC\U0001F1E7",  # ZWJ family + flag
    "zero​width‌join‍",                                 # zero-width characters
    "<script>alert('x')</script><img src=x onerror=alert(1)>",          # stored XSS probe
    "'; DROP TABLE users; --",                                          # SQL-looking text
    "Robert'); SELECT pg_sleep(5);--",
    "‮RTL override text",                                          # bidi override
    "line one\nline two",
]


@pytest.fixture(scope="module")
def couple(make_member):
    a, b = make_member("val_a", "F", "M"), make_member("val_b", "M", "F")
    return a, b, match(a, b)


@pytest.fixture(scope="module")
def friends(make_member):
    a, b = make_member("val_fa", "F", "M"), make_member("val_fb", "M", "F")
    befriend(a, b)
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    return a, b, cid


def _server_ok(response):
    assert response.status < 500, f"{response.method} {response.url} -> {response.status} {response.text[:300]}"
    return response


# --- inert round trips -------------------------------------------------------------

def test_tricky_text_round_trips_verbatim_in_friend_chat(friends):
    """Friend chat has no daily quota, so every payload is sent here."""
    a, b, cid = friends
    for text in TRICKY:
        sent = a.post(f"/social/channels/{cid}/messages",
                      {"client_message_id": str(uuid.uuid4()), "body": text})
        assert sent.status in (200, 201), f"{text!r}: {sent.status} {sent.text[:200]}"
        assert sent.headers.get("Content-Type", "").startswith("application/json")
    bodies = [m["body"] for m in b.get(f"/social/channels/{cid}/messages", params={"limit": 100}).ok()["messages"]]
    for text in TRICKY:
        assert text.strip() in bodies, f"{text!r} was altered or lost"


def test_tricky_text_round_trips_in_match_chat_and_preview(couple):
    a, b, match_id = couple
    text = TRICKY[3]  # HTML: the API stores and returns it as data, never markup
    a.post(f"/chat/{match_id}/messages", {"text": text, "sender_id": a.user_id}).ok()
    response = b.get(f"/chat/{match_id}/messages")
    assert response.headers.get("Content-Type", "").startswith("application/json")
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert text in [m["text"] for m in response.ok()["messages"]]


def test_tricky_text_in_profile_bio_and_settings(couple):
    a, _, _ = couple
    bio = "Hiker \U0001F3D4️ مرحبا <b>bold?</b> '; DROP TABLE users; --"
    a.patch(f"/profile/{a.user_id}/draft", {"bio": bio}).ok()
    assert a.get(f"/profile/{a.user_id}/draft").ok()["draft"]["bio"] == bio
    a.post(f"/profile/{a.user_id}/complete").ok()
    assert a.get(f"/profile/{a.user_id}").ok()["profile"]["bio"] == bio


def test_friend_search_treats_wildcards_and_sql_as_text(friends):
    a, _, _ = friends
    for q in ("%%%", "___", "' OR '1'='1", "\\\\\\", "a" * 200, "\U0001F600\U0001F600\U0001F600"):
        response = _server_ok(a.get(f"/friends/{a.user_id}/search", params={"q": q}))
        assert response.status in (200, 400), response.text
        if response.status == 200:
            assert len(response["results"]) <= 10
    wildcard = a.get(f"/friends/{a.user_id}/search", params={"q": "%%%"}).ok()["results"]
    assert wildcard == [], "a LIKE wildcard must not match everyone"


# --- lengths ---------------------------------------------------------------------------

def test_friend_chat_message_length_bounds(friends):
    a, _, cid = friends
    at_max = a.post(f"/social/channels/{cid}/messages",
                    {"client_message_id": str(uuid.uuid4()), "body": "x" * 2000})
    assert at_max.status in (200, 201), at_max.text[:200]
    over = a.post(f"/social/channels/{cid}/messages",
                  {"client_message_id": str(uuid.uuid4()), "body": "x" * 2001})
    assert over.status == 400, over.text[:200]


@pytest.mark.known_defect("API-17")
@pytest.mark.xfail(strict=True, reason="API-17: match chat accepts messages of any length (no cap below the 1 MiB body limit)")
def test_match_chat_message_has_a_length_cap(couple):
    a, _, match_id = couple
    response = a.post(f"/chat/{match_id}/messages", {"text": "y" * 20_000, "sender_id": a.user_id})
    assert response.status == 400, f"{response.status}: 20,000-character message accepted"


@pytest.mark.known_defect("API-18")
@pytest.mark.xfail(strict=True, reason="API-18: an empty match chat message is answered 200 accepted:false, not 400")
def test_empty_match_chat_message_is_a_400(couple):
    a, _, match_id = couple
    response = a.post(f"/chat/{match_id}/messages", {"text": "   ", "sender_id": a.user_id})
    assert response.status == 400, response.text


def test_empty_match_chat_message_is_not_stored(couple):
    a, b, match_id = couple
    response = _server_ok(a.post(f"/chat/{match_id}/messages", {"text": "   ", "sender_id": a.user_id}))
    assert response.get("accepted") is not True
    assert "   " not in [m["text"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]


# Regression guard: API-15 (fixed, verified live 2026-10-02)
def test_overlong_bio_blocks_publishing_with_a_client_error(make_member):
    member = make_member("val_bio", "F", "M")
    member.patch(f"/profile/{member.user_id}/draft", {"bio": "b" * 501}).ok()
    response = member.post(f"/profile/{member.user_id}/complete")
    try:
        assert response.status == 400, f"{response.status}: {response.text[:200]}"
    finally:
        member.patch(f"/profile/{member.user_id}/draft",
                     {"bio": "Curious architect who enjoys hiking and thoughtful conversations."}).ok()
        member.post(f"/profile/{member.user_id}/complete")


def test_overlong_bio_is_never_published(make_member):
    member = make_member("val_bio2", "F", "M")
    member.patch(f"/profile/{member.user_id}/draft", {"bio": "c" * 501}).ok()
    response = member.post(f"/profile/{member.user_id}/complete")
    assert response.status != 200, "a 501-character bio was published"
    assert member.get(f"/profile/{member.user_id}").ok()["profile"]["bio"] != "c" * 501
    member.patch(f"/profile/{member.user_id}/draft",
                 {"bio": "Curious architect who enjoys hiking and thoughtful conversations."}).ok()
    member.post(f"/profile/{member.user_id}/complete").ok()


@pytest.mark.parametrize("body,why", [
    ({"title": "ab", "category": "talk"}, "title too short"),
    ({"title": "t" * 61, "category": "talk"}, "title too long"),
    ({"title": "Valid title", "category": "talk", "description": "d" * 281}, "description too long"),
    ({"title": "Valid title", "category": "talk", "duration_minutes": 29}, "duration too short"),
    ({"title": "Valid title", "category": "talk", "duration_minutes": 181}, "duration too long"),
    ({"title": "Valid title", "category": "talk", "capacity": 1}, "capacity too small"),
    ({"title": "Valid title", "category": "talk", "capacity": 51}, "capacity too big"),
])
def test_room_creation_bounds(couple, body, why):
    a, _, _ = couple
    response = a.post("/rooms", body)
    assert response.status == 400, f"{why}: {response.status} {response.text[:200]}"


@pytest.mark.parametrize("body,why", [
    ({"kind": "private", "name": "ab"}, "name too short"),
    ({"kind": "private", "name": "n" * 61}, "name too long"),
    ({"kind": "private", "name": "Valid name", "description": "d" * 501}, "description too long"),
    ({"kind": "secret", "name": "Valid name"}, "unknown kind"),
    ({"kind": "private", "name": "Valid name", "cover_color": "neon"}, "unknown colour"),
])
def test_group_creation_bounds(couple, body, why):
    a, _, _ = couple
    response = a.post("/engagement/groups", body)
    if response.status == 201:
        a.delete(f"/engagement/groups/{response['group']['id']}")
    assert response.status == 400, f"{why}: {response.status} {response.text[:200]}"


# --- rich text -----------------------------------------------------------------------

def _rich(blocks, style="modern"):
    return {"version": 1, "style": style, "blocks": blocks}


def _para(text, marks=None, href=None):
    span = {"text": text, "marks": marks or []}
    if href:
        span["href"] = href
    return {"type": "paragraph", "spans": [span]}


@pytest.mark.parametrize("content,why", [
    (_rich([_para("click", ["link"], "javascript:alert(1)")]), "javascript: link"),
    (_rich([_para("click", ["link"], "http://example.com")]), "plain http link"),
    (_rich([_para("click", ["link"], "data:text/html,<b>x</b>")]), "data: link"),
    (_rich([_para("click", ["link"])]), "link mark without href"),
    (_rich([{"type": "iframe", "spans": [{"text": "x", "marks": []}]}]), "unknown block type"),
    (_rich([_para("x", ["blink"])]), "unknown mark"),
    (_rich([_para("x", ["bold", "bold"])]), "duplicate mark"),
    (_rich([_para("two\nlines")]), "newline inside a span"),
    (_rich([{"type": "divider", "spans": [{"text": "x", "marks": []}]}]), "divider with text"),
    (_rich([_para("x")] * 401), "more than 400 blocks"),
    ({"version": 1, "style": "modern", "blocks": [], "script": "x"}, "unknown top-level field"),
    ("<p>html is not rich text</p>", "HTML string"),
])
def test_rich_text_chapter_validation(couple, content, why):
    a, _, _ = couple
    response = a.put(f"/blog/posts/{uuid.uuid4()}", {"title": "Rich text probe", "content": content,
                                                     "audience": "private", "expected_version": 0})
    assert response.status == 400, f"{why}: {response.status} {response.text[:200]}"


def test_rich_text_chapter_derives_plain_body(couple):
    a, b, _ = couple
    post_id = str(uuid.uuid4())
    content = _rich([
        {"type": "heading", "spans": [{"text": "A small walk", "marks": []}]},
        {"type": "bullet", "spans": [{"text": "coffee ", "marks": ["bold"]},
                                     {"text": "first", "marks": ["italic"]}]},
        _para("read more", ["link"], "https://example.com/chapter"),
    ])
    saved = a.put(f"/blog/posts/{post_id}", {"title": "Rich chapter", "content": content,
                                             "body": "IGNORED", "audience": "private",
                                             "expected_version": 0}).ok()["post"]
    try:
        assert "IGNORED" not in saved["body"] and "A small walk" in saved["body"]
        assert "• coffee first" in saved["body"]
        stale = a.put(f"/blog/posts/{post_id}", {"title": "Rich chapter v2", "body": "edit",
                                                 "audience": "private", "expected_version": 0})
        assert stale.status == 409, f"stale expected_version must conflict: {stale.status}"
    finally:
        a.delete(f"/blog/posts/{post_id}", {"expected_version": saved["version"]})


# --- malformed requests ------------------------------------------------------------------

@pytest.mark.parametrize("raw,ctype", [
    (b"{not json", "application/json"),
    (b"[1,2,3]", "application/json"),
    (b"\"just a string\"", "application/json"),
    (b"\xff\xfe\x00garbage", "application/json"),
    (b"", "application/json"),
], ids=["broken", "array", "string", "binary", "empty"])
def test_malformed_json_is_a_client_error(couple, raw, ctype):
    a, _, _ = couple
    response = a.api.call("PATCH", f"/settings/{a.user_id}", data=raw, headers={"Content-Type": ctype})
    assert response.status in (200, 400), f"{response.status} {response.text[:200]}"
    if raw:
        assert response.status == 400, response.text
    assert "EOF" not in response.text and "invalid character" not in response.text


@pytest.mark.parametrize("payload", [
    {"locale": "english"}, {"locale": "EN-gb"}, {"locale": 7},
])
def test_settings_locale_validation(couple, payload):
    a, _, _ = couple
    assert a.patch(f"/settings/{a.user_id}", payload).status == 400


def test_dating_preferences_validation_and_version_conflict(couple):
    a, _, _ = couple
    base = f"/account/{a.user_id}/dating-preferences"
    current = a.get(base).ok()["preferences"]
    for bad in ({"intent": "polyamory-ish"}, {"pace": "warp"},
                {"activities": ["coffee", "meal", "drinks", "walk", "activity", "event"]},
                {"activities": ["skydiving"]}):
        response = a.put(base, {**bad, "version": current["version"]})
        assert response.status == 400, f"{bad}: {response.status} {response.text[:200]}"
    saved = a.put(base, {"intent": "relationship", "pace": "steady", "activities": ["coffee", "walk"],
                         "version": current["version"]}).ok()["preferences"]
    assert saved["intent"] == "relationship" and saved["version"] == current["version"] + 1
    stale = a.put(base, {"intent": "casual", "version": current["version"]})
    assert stale.status == 409, stale.text


def test_notification_device_registration_rules(couple):
    a, _, _ = couple
    base = f"/notifications/{a.user_id}/devices"
    for bad in ({"provider": "carrier-pigeon", "platform": "android", "token": "t"},
                {"provider": "fcm", "platform": "android", "token": ""},
                {"provider": "apns", "platform": "android", "token": "abc"},
                {"provider": "fcm", "platform": "android", "token": "t" * 4097}):
        assert a.post(base, bad).status == 400, bad
    device = a.post(base, {"provider": "fcm", "platform": "android", "token": f"e2e-{uuid.uuid4()}"})
    assert device.status == 201, device.text
    a.delete(f"{base}/{device['device_id']}").ok()
    assert a.delete(f"{base}/{uuid.uuid4()}").status == 404


# --- pagination ------------------------------------------------------------------------------

LIMITS = ["0", "-1", "abc", "1.5", "100000", "9" * 30]


@pytest.mark.pagination
@pytest.mark.parametrize("limit", LIMITS)
def test_list_endpoints_survive_hostile_limits(couple, friends, limit):
    a, _, match_id = couple
    fa, _, cid = friends
    calls = [
        (a, f"/discovery/{a.user_id}", 300),
        (a, f"/discovery/{a.user_id}/liked-me", 100),
        (a, f"/chat/{match_id}/messages", 200),
        (a, f"/notifications/{a.user_id}", 200),
        (fa, f"/social/channels/{cid}/messages", 100),
        (a, "/blog/posts", 100),
        (a, f"/plans/{a.user_id}", 100),
        (a, f"/wallet/{a.user_id}/coins/audit", 200),
        (a, "/rooms", 500),
        (a, "/engagement/groups", 500),
    ]
    for member, path, cap in calls:
        response = _server_ok(member.get(path, params={"limit": limit}))
        assert response.status in (200, 400), f"{path}?limit={limit}: {response.status} {response.text[:200]}"
        if response.status == 200 and isinstance(response.body, dict):
            for value in response.body.values():
                if isinstance(value, list):
                    assert len(value) <= cap, f"{path}?limit={limit} returned {len(value)} rows"


@pytest.mark.pagination
@pytest.mark.parametrize("cursor", ["garbage", str(uuid.uuid4()), "' OR 1=1 --", "-1", "%00"])
def test_list_endpoints_survive_bad_cursors(couple, friends, cursor):
    a, _, _ = couple
    fa, _, cid = friends
    for member, path, key in ((fa, f"/social/channels/{cid}/messages", "before"),
                              (a, "/blog/posts", "before"), (a, "/blog/notices", "cursor"),
                              (a, f"/notifications/{a.user_id}", "cursor")):
        response = _server_ok(member.get(path, params={key: cursor}))
        assert response.status in (200, 400, 404), f"{path}?{key}={cursor}: {response.status}"


@pytest.mark.pagination
def test_friend_chat_before_cursor_pages_backwards(friends):
    a, b, cid = friends
    for n in range(5):
        a.post(f"/social/channels/{cid}/messages",
               {"client_message_id": str(uuid.uuid4()), "body": f"page probe {n}"}).ok()
    first = b.get(f"/social/channels/{cid}/messages", params={"limit": 2}).ok()
    assert len(first["messages"]) == 2 and first["has_more"] is True
    oldest = first["messages"][0]["id"]
    older = b.get(f"/social/channels/{cid}/messages", params={"limit": 2, "before": oldest}).ok()
    assert older["messages"] and oldest not in [m["id"] for m in older["messages"]]
    assert {m["id"] for m in older["messages"]}.isdisjoint({m["id"] for m in first["messages"]})


@pytest.mark.pagination
def test_chat_history_limit_is_respected(couple):
    a, b, match_id = couple
    messages = b.get(f"/chat/{match_id}/messages", params={"limit": 1}).ok()["messages"]
    assert len(messages) == 1
