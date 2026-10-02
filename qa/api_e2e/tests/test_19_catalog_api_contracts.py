"""Error-path contract matrix for every ``*.api_contract`` case in the QA Lab
catalog (qa/catalog/feature_catalog.json).

Each catalog case names the API behind one app control. For every endpoint of
the case this module sends the requests a real client must be refused for and
asserts the documented 4xx:

* no session                          -> 401 (public routes: their own 4xx)
* another member's id / not a participant / not the owner -> 403 or 404
* malformed or missing fields         -> 400 (or 404/409/415/422 where documented)
* unknown or malformed resource ids   -> 404 (400 for a malformed id)
* and never a 5xx

Happy paths (the valid call returns 2xx with the documented body) live in the
journey modules and in test_20/test_21; every one of those tests carries the
same ``case`` marker, so a case id selects both halves:
``pytest -m case`` does not filter by id, use ``-k <case id>`` or the junit
properties instead.

A probe is sent once per run and its result reused by every case that shares
the endpoint, so the matrix stays light on the shared local stack.
Feature-flagged routes whose flag is off on the local stack (support
ticketing, city pilot) assert the documented gated answer instead.
"""

from __future__ import annotations

import datetime as dt
import json as jsonlib
import os
import struct
import uuid
from dataclasses import dataclass, field

import pytest

from client import Api, png_bytes
from journeys import befriend, match


pytestmark = [pytest.mark.journey("catalog_api_contracts"), pytest.mark.authz, pytest.mark.validation]

CATALOG = os.path.join(os.path.dirname(__file__), "..", "..", "catalog", "feature_catalog.json")

ANON = {401}
DENY = {403, 404}
MISSING = {404}
BAD = {400}
GATED = {403}  # FEATURE_DISABLED while the route's flag is off


# --- probes -----------------------------------------------------------------------

@dataclass(frozen=True)
class Probe:
    label: str
    actor: str          # "anon" | "a" (owner) | "b" (match partner / friend) | "c" (outsider)
    method: str
    path: str           # placeholders filled from the world: {me} {peer} {match} {uuid} ...
    body: object = None  # JSON body, or the form fields when multipart is set
    expect: frozenset = field(default_factory=frozenset)
    multipart: str = ""   # file field name: the request is multipart with a 320px PNG in it
    gated_flag: str = ""  # when set, a 403 must carry FEATURE_DISABLED for this flag


def P(label, actor, method, path, body=None, expect=BAD, multipart="", gated_flag=""):
    if multipart is True:
        multipart = "image"
    return Probe(label, actor, method, path, body, frozenset(expect), multipart or "", gated_flag)


def anon(method, path, body=None):
    return P("no session", "anon", method, path, body, ANON)


def foreign(method, path, body=None, expect=DENY, actor="c"):
    return P("another member's resource", actor, method, path, body, expect)


def bad(method, path, body=None, expect=BAD, label="invalid input", actor="a"):
    return P(label, actor, method, path, body, expect)


def unknown(method, path, body=None, expect=MISSING, actor="a"):
    return P("unknown id", actor, method, path, body, expect)


def malformed(method, path, body=None, expect=(400, 404), actor="a"):
    return P("malformed id", actor, method, path, body, expect)


def gated(method, path, body=None, flag="", actor="a", multipart=False):
    return P(f"gated while {flag} is off", actor, method, path, body, GATED, multipart, flag)


def wav_bytes(seconds: float = 0.5, rate: int = 8000) -> bytes:
    """A silent mono 16-bit PCM WAV (the voice icebreaker upload accepts wav by magic bytes)."""
    data = b"\x00\x00" * int(rate * seconds)
    return (b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt "
            + struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16) + b"data" + struct.pack("<I", len(data)) + data)


def _monday(weeks=0):
    today = dt.date.today()
    return (today - dt.timedelta(days=today.weekday()) + dt.timedelta(weeks=weeks)).isoformat()


def _window(days=2, hours=2):
    start = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=days)).replace(microsecond=0)
    return (start.isoformat().replace("+00:00", "Z"),
            (start + dt.timedelta(hours=hours)).isoformat().replace("+00:00", "Z"))


V = {"expected_version": 1}

ENDPOINT_PROBES: dict[str, list[Probe]] = {
    # --- auth (public routes) --------------------------------------------------------
    "POST /auth/login": [
        P("empty body", "anon", "POST", "/auth/login", {}, (400, 401)),
        P("wrong password", "anon", "POST", "/auth/login", {"username": "{username}", "password": "Wrong-Password-1"}, ANON),
        P("wrong types", "anon", "POST", "/auth/login", {"username": ["a"], "password": {"b": 1}}, (400, 401)),
    ],
    "POST /auth/password/recover": [
        P("missing fields", "anon", "POST", "/auth/password/recover", {}, BAD),
        P("wrong recovery code", "anon", "POST", "/auth/password/recover",
          {"username": "{username}", "recovery_code": "WRONG-CODE-0000", "new_password": "Password123!x"}, BAD),
    ],
    "POST /auth/recovery/assistance": [
        P("missing username", "anon", "POST", "/auth/recovery/assistance", {"message": "help"}, BAD),
        P("username too long", "anon", "POST", "/auth/recovery/assistance", {"username": "u" * 65}, BAD),
    ],
    "POST /auth/signup": [
        P("username too short", "anon", "POST", "/auth/signup", {"username": "ab", "password": "Password123!"}, BAD),
        P("weak password", "anon", "POST", "/auth/signup", {"username": "e2e_cat_weak_pw", "password": "short"}, BAD),
        P("username taken", "anon", "POST", "/auth/signup", {"username": "{username}", "password": "Password123!"}, (400, 409)),
    ],
    "POST /auth/signup/bootstrap": [
        anon("POST", "/auth/signup/bootstrap", {"user_id": "{me}", "username": "x", "name": "x",
                                                "date_of_birth": "1990-01-01", "gender": "F"}),
        foreign("POST", "/auth/signup/bootstrap", {"user_id": "{me}", "username": "{username}", "name": "Hijack",
                                                   "date_of_birth": "1990-01-01", "gender": "M"}, (401, 403)),
    ],
    "PATCH /users/{userID}/agreements/terms": [
        anon("PATCH", "/users/{me}/agreements/terms", {"accepted": True, "terms_version": "v1"}),
        foreign("PATCH", "/users/{me}/agreements/terms", {"accepted": True, "terms_version": "v1"}, {403}),
    ],
    "POST /auth/logout": [
        anon("POST", "/auth/logout", {}),
        P("unknown token", "anon", "POST", "/auth/logout", {}, ANON),
    ],
    "DELETE /notifications/{userID}/devices/{deviceID}": [
        anon("DELETE", "/notifications/{me}/devices/{uuid}"),
        foreign("DELETE", "/notifications/{me}/devices/{uuid}", expect={403}),
        unknown("DELETE", "/notifications/{me}/devices/{uuid}"),
    ],

    # --- Open Chapters -----------------------------------------------------------------
    "POST /blog/responses/{responseID}": [
        anon("POST", "/blog/responses/{response}", {"action": "accept", **V}),
        unknown("POST", "/blog/responses/{uuid}", {"action": "accept", **V}),
        malformed("POST", "/blog/responses/not-a-uuid", {"action": "accept", **V}),
        foreign("POST", "/blog/responses/{response}", {"action": "accept", **V}),
        bad("POST", "/blog/responses/{response}", {"action": "accept"}, label="missing expected_version"),
        bad("POST", "/blog/responses/{response}", {"action": "shrug", **V}, label="unknown action"),
        P("sender cannot accept their own response", "b", "POST", "/blog/responses/{response}",
          {"action": "accept", **V}, {403}),
    ],
    "DELETE /blog/responses/{responseID}": [
        anon("DELETE", "/blog/responses/{response}"),
        unknown("DELETE", "/blog/responses/{uuid}"),
        malformed("DELETE", "/blog/responses/not-a-uuid"),
        foreign("DELETE", "/blog/responses/{response}"),
    ],
    "POST /blog/reports/{kind}/{contentID}": [
        anon("POST", "/blog/reports/post/{post}", {"reason": "fake"}),
        bad("POST", "/blog/reports/post/{post}", {"reason": "because"}, actor="c", label="unknown reason"),
        bad("POST", "/blog/reports/post/{post}", {"reason": "fake", "description": "d" * 1001}, actor="c",
            label="description too long"),
        bad("POST", "/blog/reports/teapot/{post}", {"reason": "fake"}, actor="c", label="unknown kind"),
        bad("POST", "/blog/reports/post/{post}", {"reason": "fake"}, label="report your own chapter"),
        unknown("POST", "/blog/reports/post/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/club/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/review/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/theme_entry/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/social_message/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/group/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/response/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/club_post/{uuid}", {"reason": "fake"}, actor="c"),
        unknown("POST", "/blog/reports/comment/{uuid}", {"reason": "fake"}, actor="c"),
        malformed("POST", "/blog/reports/post/not-a-uuid", {"reason": "fake"}, actor="c"),
    ],
    "POST /safety/block": [
        anon("POST", "/safety/block", {"user_id": "{me}", "blocked_user_id": "{outsider}"}),
        P("actor must be the caller", "c", "POST", "/safety/block", {"user_id": "{me}", "blocked_user_id": "{peer}"}, {403}),
        bad("POST", "/safety/block", {"user_id": "{me}", "blocked_user_id": "{me}"}, label="self block"),
        bad("POST", "/safety/block", {"user_id": "{me}", "blocked_user_id": "not-a-uuid"}, (400, 404), label="malformed target"),
    ],
    "GET /blog/posts/{postID}": [
        anon("GET", "/blog/posts/{post}"),
        unknown("GET", "/blog/posts/{uuid}"),
        malformed("GET", "/blog/posts/not-a-uuid"),
        foreign("GET", "/blog/posts/{private_post}"),
    ],
    "DELETE /blog/posts/{postID}/photos/{photoID}": [
        anon("DELETE", "/blog/posts/{private_post}/photos/{uuid}", V),
        unknown("DELETE", "/blog/posts/{private_post}/photos/{uuid}", {"expected_version": "{private_version}"}),
        bad("DELETE", "/blog/posts/{private_post}/photos/{uuid}", None, label="missing expected_version"),
        bad("DELETE", "/blog/posts/{post}/photos/{uuid}", {"expected_version": "{post_version}"}, {409},
            label="community chapter must be Only me first"),
        foreign("DELETE", "/blog/posts/{private_post}/photos/{uuid}", {"expected_version": "{private_version}"}),
        malformed("DELETE", "/blog/posts/{private_post}/photos/not-a-uuid", {"expected_version": "{private_version}"}),
    ],
    "PUT /blog/posts/{postID}/photos/{photoID}": [
        anon("PUT", "/blog/posts/{private_post}/photos/{uuid}"),
        bad("PUT", "/blog/posts/{private_post}/photos/{uuid}", {"image": "base64?"}, (400, 415), label="not multipart"),
        P("missing alt text", "a", "PUT", "/blog/posts/{private_post}/photos/{uuid}",
          {"expected_version": "{private_version}"}, BAD, multipart=True),
        P("missing expected_version", "a", "PUT", "/blog/posts/{private_post}/photos/{uuid}",
          {"alt_text": "A grey square"}, BAD, multipart=True),
        P("community chapter must be Only me first", "a", "PUT", "/blog/posts/{post}/photos/{uuid}",
          {"expected_version": "{post_version}", "alt_text": "A grey square"}, {409}, multipart=True),
        P("another member's chapter", "c", "PUT", "/blog/posts/{private_post}/photos/{uuid}",
          {"expected_version": "{private_version}", "alt_text": "A grey square"}, DENY, multipart=True),
        P("unknown chapter", "a", "PUT", "/blog/posts/{uuid}/photos/{uuid}",
          {"expected_version": "1", "alt_text": "A grey square"}, MISSING, multipart=True),
    ],
    "PUT /blog/posts/{postID}": [
        anon("PUT", "/blog/posts/{uuid}", {"title": "t", "body": "b", "audience": "community", "expected_version": 0}),
        bad("PUT", "/blog/posts/{uuid}", {"title": "t", "body": "b", "audience": "everyone", "expected_version": 0},
            label="unknown audience"),
        bad("PUT", "/blog/posts/{uuid}", {"title": "", "body": "", "audience": "community", "expected_version": 0},
            label="empty chapter"),
        bad("PUT", "/blog/posts/{uuid}", {"title": "t", "body": "b", "audience": "community",
                                         "invitation": "marry_me", "expected_version": 0}, label="unknown invitation"),
        foreign("PUT", "/blog/posts/{post}", {"title": "hijack", "body": "hijack", "audience": "community",
                                             "expected_version": "{post_version}"}, (403, 404, 409)),
        bad("PUT", "/blog/posts/{post}", {"title": "stale", "body": "stale", "audience": "community",
                                         "expected_version": 0}, {409}, label="stale expected_version"),
    ],
    "PUT /blog/posts/{postID}/like": [
        anon("PUT", "/blog/posts/{post}/like", {"reaction": "hug"}),
        bad("PUT", "/blog/posts/{post}/like", {"reaction": "angry"}, actor="c", label="unknown reaction"),
        unknown("PUT", "/blog/posts/{uuid}/like", {"reaction": "hug"}, actor="c"),
        foreign("PUT", "/blog/posts/{private_post}/like", {"reaction": "hug"}),
    ],
    "DELETE /blog/posts/{postID}/like": [
        anon("DELETE", "/blog/posts/{post}/like"),
        unknown("DELETE", "/blog/posts/{uuid}/like", actor="c"),
        malformed("DELETE", "/blog/posts/not-a-uuid/like", actor="c"),
    ],
    "PUT /blog/authors/{authorID}/subscription": [
        anon("PUT", "/blog/authors/{me}/subscription"),
        bad("PUT", "/blog/authors/{me}/subscription", None, (400, 403), label="follow yourself"),
        unknown("PUT", "/blog/authors/{uuid}/subscription", actor="c"),
        malformed("PUT", "/blog/authors/not-a-uuid/subscription", actor="c"),
    ],
    "DELETE /blog/authors/{authorID}/subscription": [
        anon("DELETE", "/blog/authors/{me}/subscription"),
        malformed("DELETE", "/blog/authors/not-a-uuid/subscription", actor="c"),
    ],
    "POST /walls/views": [
        anon("POST", "/walls/views", {"kind": "chapter", "id": "{post}"}),
        bad("POST", "/walls/views", {"kind": "bogus", "id": "{post}"}, actor="c", label="unknown kind"),
        bad("POST", "/walls/views", {"kind": "chapter", "id": "not-a-uuid"}, (400, 404), actor="c", label="malformed id"),
        bad("POST", "/walls/views", {}, (400, 404), actor="c", label="missing fields"),
        unknown("POST", "/walls/views", {"kind": "chapter", "id": "{uuid}"}, actor="c"),
        foreign("POST", "/walls/views", {"kind": "chapter", "id": "{private_post}"}),
    ],
    "DELETE /blog/posts/{postID}": [
        anon("DELETE", "/blog/posts/{post}", {"expected_version": "{post_version}"}),
        bad("DELETE", "/blog/posts/{post}", None, label="missing expected_version"),
        foreign("DELETE", "/blog/posts/{post}", {"expected_version": "{post_version}"}, (403, 404, 409)),
        unknown("DELETE", "/blog/posts/{uuid}", V, (404, 409)),
        malformed("DELETE", "/blog/posts/not-a-uuid", V, (400, 404, 409)),
    ],
    "POST /blog/posts/{postID}/report": [
        anon("POST", "/blog/posts/{post}/report", {"reason": "fake"}),
        unknown("POST", "/blog/posts/{uuid}/report", {"reason": "fake"}, actor="c"),
        malformed("POST", "/blog/posts/not-a-uuid/report", {"reason": "fake"}, actor="c"),
        bad("POST", "/blog/posts/{post}/report", {"reason": "fake"}, label="report your own chapter"),
        bad("POST", "/blog/posts/{post}/report", {"reason": "because"}, actor="c", label="unknown reason"),
    ],
    "POST /blog/publications": [
        anon("POST", "/blog/publications", {"id": "{uuid}", "post_id": "{post}", "approved": True}),
        bad("POST", "/blog/publications", {"id": "{uuid}", "post_id": "{post}", "expected_version": "{post_version}",
                                           "excerpt": "trails"}, label="not explicitly approved"),
        bad("POST", "/blog/publications", {"id": "nope", "post_id": "{post}", "approved": True,
                                           "expected_version": 1}, label="malformed ids"),
        bad("POST", "/blog/publications", {"id": "{uuid}", "post_id": "{post}", "approved": True,
                                           "expected_version": "{post_version}", "excerpt": "not in the story"},
            label="excerpt not from the story"),
        foreign("POST", "/blog/publications", {"id": "{uuid}", "post_id": "{post}", "approved": True,
                                               "expected_version": "{post_version}", "excerpt": "trails"},
                (400, 403, 404)),
    ],

    # --- calls ---------------------------------------------------------------------------
    "GET /calls/history/{userID}": [
        anon("GET", "/calls/history/{me}"),
        foreign("GET", "/calls/history/{me}", expect={403}),
    ],
    "POST /calls/{callID}/end": [
        anon("POST", "/calls/{uuid}/end", {"ended_by_user_id": "{me}"}),
        unknown("POST", "/calls/{uuid}/end", {"ended_by_user_id": "{me}"}),
        P("actor must be the caller", "c", "POST", "/calls/{uuid}/end", {"ended_by_user_id": "{me}"}, {403}),
        P("not a participant", "c", "POST", "/calls/{call}/end", {"ended_by_user_id": "{outsider}"}, DENY),
    ],
    "POST /calls/start": [
        anon("POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{me}", "recipient_user_id": "{peer}"}),
        P("not a participant", "c", "POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{outsider}",
                                                              "recipient_user_id": "{me}"}, DENY),
        P("actor must be the caller", "c", "POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{me}",
                                                                     "recipient_user_id": "{peer}"}, {403}),
        bad("POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{me}", "recipient_user_id": "{outsider}"},
            (400, 403, 409), label="recipient outside the match"),
        bad("POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{me}"}, (400,),
            label="missing recipient"),
    ],

    # --- city pilot (city_pilot_enabled is off on the local stack) -------------------------
    "POST /city-pilot/membership": [
        anon("POST", "/city-pilot/membership", {"pilot_id": "{uuid}", "consent_version": "city-pilot-v1"}),
        bad("POST", "/city-pilot/membership", {"action": "join"}, label="missing pilot"),
        bad("POST", "/city-pilot/membership", {"pilot_id": "not-a-uuid", "consent_version": "city-pilot-v1"},
            label="malformed pilot"),
        unknown("POST", "/city-pilot/membership", {"pilot_id": "{uuid}", "consent_version": "city-pilot-v1"}),
    ],
    "DELETE /city-pilot/membership": [
        anon("DELETE", "/city-pilot/membership", {"pilot_id": "{uuid}"}),
        bad("DELETE", "/city-pilot/membership", None, label="missing pilot"),
        unknown("DELETE", "/city-pilot/membership", {"pilot_id": "{uuid}"}),
    ],
    "POST /city-pilot/events/{eventID}/registration": [
        anon("POST", "/city-pilot/events/{uuid}/registration", {"safety_terms_accepted": True}),
        unknown("POST", "/city-pilot/events/{uuid}/registration", {"safety_terms_accepted": True}),
        malformed("POST", "/city-pilot/events/not-a-uuid/registration", {"safety_terms_accepted": True}),
    ],
    "DELETE /city-pilot/events/{eventID}/registration": [
        anon("DELETE", "/city-pilot/events/{uuid}/registration"),
        unknown("DELETE", "/city-pilot/events/{uuid}/registration"),
        malformed("DELETE", "/city-pilot/events/not-a-uuid/registration"),
    ],
    "POST /city-pilot/events/{eventID}/feedback": [
        anon("POST", "/city-pilot/events/{uuid}/feedback", {"attended": True}),
        bad("POST", "/city-pilot/events/{uuid}/feedback", {"worthwhile": True}, label="missing attended"),
        bad("POST", "/city-pilot/events/{uuid}/feedback", {"attended": False, "worthwhile": True},
            label="worthwhile without attending"),
        unknown("POST", "/city-pilot/events/{uuid}/feedback", {"attended": True}),
        malformed("POST", "/city-pilot/events/not-a-uuid/feedback", {"attended": True}),
    ],

    # --- clubs -----------------------------------------------------------------------------
    "PUT /clubs/{clubID}/posts/{postID}": [
        anon("PUT", "/clubs/{club}/posts/{uuid}", {"selection_id": "{selection}", "body": "hi"}),
        foreign("PUT", "/clubs/{club}/posts/{uuid}", {"selection_id": "{selection}", "body": "hi"}, {403}),
        bad("PUT", "/clubs/{club}/posts/{uuid}", {"selection_id": "{selection}", "body": ""}, label="empty post"),
        bad("PUT", "/clubs/{club}/posts/{uuid}", {"selection_id": "{selection}", "body": "x" * 2001},
            label="post too long"),
        bad("PUT", "/clubs/{club}/posts/{club_post}", {"selection_id": "{selection}", "body": "an edit"}, {409},
            label="posts cannot be edited"),
        bad("PUT", "/clubs/{club}/posts/{uuid}", {"selection_id": "not-a-uuid", "body": "hi"}, (400, 404),
            label="malformed selection"),
        unknown("PUT", "/clubs/{uuid}/posts/{uuid}", {"selection_id": "{selection}", "body": "hi"}, (403, 404)),
    ],
    "DELETE /clubs/{clubID}/posts/{postID}": [
        anon("DELETE", "/clubs/{club}/posts/{club_post}"),
        unknown("DELETE", "/clubs/{club}/posts/{uuid}"),
        foreign("DELETE", "/clubs/{club}/posts/{club_post}"),
        P("a member cannot delete someone else's post", "b", "DELETE", "/clubs/{club}/posts/{club_post}", None, DENY),
        malformed("DELETE", "/clubs/{club}/posts/not-a-uuid"),
    ],
    "POST /clubs/{clubID}/posts/{postID}/visibility": [
        anon("POST", "/clubs/{club}/posts/{club_post}/visibility", {"hidden": True}),
        foreign("POST", "/clubs/{club}/posts/{club_post}/visibility", {"hidden": True}, (403, 404)),
        P("a plain member cannot hide posts", "b", "POST", "/clubs/{club}/posts/{club_post}/visibility",
          {"hidden": True}, {403}),
        unknown("POST", "/clubs/{club}/posts/{uuid}/visibility", {"hidden": True}),
        bad("POST", "/clubs/{club}/posts/{club_post}/visibility", {"hidden": "maybe"}, (400,), label="wrong type"),
    ],
    "POST /clubs/{clubID}/members/{userID}": [
        anon("POST", "/clubs/{club}/members/{peer}", {"action": "make_moderator"}),
        foreign("POST", "/clubs/{club}/members/{peer}", {"action": "remove"}, {403}),
        P("a plain member cannot promote", "b", "POST", "/clubs/{club}/members/{me}", {"action": "make_member"}, {403}),
        bad("POST", "/clubs/{club}/members/{peer}", {"action": "crown"}, label="unknown action"),
        bad("POST", "/clubs/{club}/members/{me}", {"action": "remove"}, label="remove yourself"),
        unknown("POST", "/clubs/{club}/members/{uuid}", {"action": "remove"}),
        malformed("POST", "/clubs/{club}/members/not-a-uuid", {"action": "remove"}),
    ],
    "PUT /clubs/{clubID}/selections/{weekStart}": [
        anon("PUT", "/clubs/{club}/selections/{monday}", {"title_id": "{title}"}),
        foreign("PUT", "/clubs/{club}/selections/{monday}", {"title_id": "{title}"}, {403}),
        P("a plain member cannot pick", "b", "PUT", "/clubs/{club}/selections/{monday}", {"title_id": "{title}"}, {403}),
        bad("PUT", "/clubs/{club}/selections/{tuesday}", {"title_id": "{title}"}, label="not a Monday"),
        bad("PUT", "/clubs/{club}/selections/not-a-date", {"title_id": "{title}"}, label="not a date"),
        bad("PUT", "/clubs/{club}/selections/{far_monday}", {"title_id": "{title}"}, label="more than 28 days out"),
        bad("PUT", "/clubs/{club}/selections/{monday}", {"title_id": "not-a-uuid"}, label="malformed title"),
        unknown("PUT", "/clubs/{club}/selections/{monday}", {"title_id": "{uuid}"}),
    ],
    "PUT /clubs/{clubID}": [
        anon("PUT", "/clubs/{uuid}", {"kind": "book", "name": "x", "expected_version": 0}),
        bad("PUT", "/clubs/{uuid}", {"kind": "podcast", "name": "E2E bad kind", "expected_version": 0}, label="unknown kind"),
        bad("PUT", "/clubs/{uuid}", {"kind": "book", "name": "ab", "expected_version": 0}, label="name too short"),
        bad("PUT", "/clubs/{uuid}", {"kind": "book", "name": "E2E no version"}, label="missing expected_version"),
        bad("PUT", "/clubs/{club}", {"kind": "book", "name": "E2E stale", "expected_version": 0}, {409},
            label="stale expected_version"),
        foreign("PUT", "/clubs/{club}", {"kind": "book", "name": "Hijacked", "expected_version": "{club_version}"},
                {403}),
        malformed("PUT", "/clubs/not-a-uuid", {"kind": "book", "name": "E2E bad id", "expected_version": 0}),
    ],
    "PUT /clubs/lists/{listID}": [
        anon("PUT", "/clubs/lists/{uuid}", {"name": "x", "kind": "book", "audience": "private", "expected_version": 0}),
        bad("PUT", "/clubs/lists/{uuid}", {"name": "", "kind": "book", "audience": "private", "expected_version": 0},
            label="empty name"),
        bad("PUT", "/clubs/lists/{uuid}", {"name": "E2E", "kind": "podcast", "audience": "private",
                                           "expected_version": 0}, label="unknown kind"),
        bad("PUT", "/clubs/lists/{uuid}", {"name": "E2E", "kind": "book", "audience": "everyone",
                                           "expected_version": 0}, label="unknown audience"),
        foreign("PUT", "/clubs/lists/{list}", {"name": "Hijacked", "kind": "book", "audience": "private",
                                               "expected_version": "{list_version}"}, {403}),
        malformed("PUT", "/clubs/lists/not-a-uuid", {"name": "x", "kind": "book", "audience": "private",
                                                     "expected_version": 0}),
    ],
    "PUT /clubs/lists/{listID}/items/{titleID}": [
        anon("PUT", "/clubs/lists/{list}/items/{title}", {}),
        foreign("PUT", "/clubs/lists/{list}/items/{title}", {}, {403}),
        bad("PUT", "/clubs/lists/{list}/items/{title}", {"note": "n" * 281}, label="note too long"),
        unknown("PUT", "/clubs/lists/{list}/items/{uuid}", {}),
        unknown("PUT", "/clubs/lists/{uuid}/items/{title}", {}),
        malformed("PUT", "/clubs/lists/{list}/items/not-a-uuid", {}),
    ],
    "DELETE /clubs/lists/{listID}": [
        anon("DELETE", "/clubs/lists/{list}", V),
        bad("DELETE", "/clubs/lists/{list}", None, label="missing expected_version"),
        foreign("DELETE", "/clubs/lists/{list}", {"expected_version": "{list_version}"}, (403, 404, 409)),
        unknown("DELETE", "/clubs/lists/{uuid}", V, (404, 409)),
        malformed("DELETE", "/clubs/lists/not-a-uuid", V),
    ],
    "DELETE /clubs/lists/{listID}/items/{titleID}": [
        anon("DELETE", "/clubs/lists/{list}/items/{title}"),
        foreign("DELETE", "/clubs/lists/{list}/items/{title}", None, {403}),
        P("title not on the list (idempotent)", "a", "DELETE", "/clubs/lists/{list}/items/{uuid}", None, (200, 404)),
        unknown("DELETE", "/clubs/lists/{uuid}/items/{title}"),
        malformed("DELETE", "/clubs/lists/{list}/items/not-a-uuid"),
    ],
    "PUT /clubs/titles/{titleID}/reviews/{reviewID}": [
        anon("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 4, "body": "x", "audience": "community",
                                                             "expected_version": 0}),
        bad("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 6, "body": "x", "audience": "community",
                                                            "expected_version": 0}, label="rating above 5"),
        bad("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 4, "body": "x", "audience": "everyone",
                                                            "expected_version": 0}, label="unknown audience"),
        bad("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 0, "body": "x", "audience": "private",
                                                            "expected_version": 0}, label="rating below 1"),
        bad("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 4, "body": "x" * 4001, "audience": "private",
                                                            "expected_version": 0}, label="review too long"),
        bad("PUT", "/clubs/titles/{title}/reviews/{uuid}", {"rating": 4, "body": "second", "audience": "private",
                                                            "expected_version": 0}, {409}, label="second review of a title"),
        foreign("PUT", "/clubs/titles/{title}/reviews/{review}", {"rating": 1, "body": "hijack",
                                                                  "audience": "community",
                                                                  "expected_version": "{review_version}"},
                {403}),
        unknown("PUT", "/clubs/titles/{uuid}/reviews/{uuid}", {"rating": 4, "body": "x", "audience": "community",
                                                               "expected_version": 0}),
    ],
    "DELETE /clubs/reviews/{reviewID}": [
        anon("DELETE", "/clubs/reviews/{review}", {"expected_version": 1}),
        bad("DELETE", "/clubs/reviews/{review}", None, label="missing expected_version"),
        foreign("DELETE", "/clubs/reviews/{review}", {"expected_version": "{review_version}"}, (403, 404, 409)),
        unknown("DELETE", "/clubs/reviews/{uuid}", V, (404, 409)),
        malformed("DELETE", "/clubs/reviews/not-a-uuid", V),
    ],

    # --- account ---------------------------------------------------------------------------
    "GET /account/{userID}/lifecycle": [
        anon("GET", "/account/{me}/lifecycle"),
        foreign("GET", "/account/{me}/lifecycle", expect={403}),
    ],
    "DELETE /account/{userID}/deletion": [
        anon("DELETE", "/account/{me}/deletion"),
        foreign("DELETE", "/account/{me}/deletion", expect={403}),
        bad("DELETE", "/account/{me}/deletion", None, {409}, label="nothing to cancel"),
    ],
    "POST /account/{userID}/reactivate": [
        anon("POST", "/account/{me}/reactivate", {}),
        foreign("POST", "/account/{me}/reactivate", {}, {403}),
    ],
    "POST /account/{userID}/deactivate": [
        anon("POST", "/account/{me}/deactivate", {"reason": "x"}),
        foreign("POST", "/account/{me}/deactivate", {"reason": "idor"}, {403}),
    ],
    "POST /account/{userID}/export": [
        anon("POST", "/account/{me}/export", {}),
        foreign("POST", "/account/{me}/export", {}, {403}),
    ],
    "POST /account/{userID}/deletion": [
        anon("POST", "/account/{me}/deletion", {"reason": "x"}),
        foreign("POST", "/account/{me}/deletion", {"reason": "idor"}, {403}),
    ],
    "POST /safety/unblock": [
        anon("POST", "/safety/unblock", {"user_id": "{me}", "blocked_user_id": "{outsider}"}),
        P("actor must be the caller", "c", "POST", "/safety/unblock", {"user_id": "{me}", "blocked_user_id": "{peer}"}, {403}),
        bad("POST", "/safety/unblock", {"user_id": "{me}", "blocked_user_id": "{uuid}"}, (400, 404), label="never blocked"),
    ],
    "GET /blocked-users/{userID}": [
        anon("GET", "/blocked-users/{me}"),
        foreign("GET", "/blocked-users/{me}", expect={403}),
    ],
    "POST /emergency-contacts/{userID}": [
        anon("POST", "/emergency-contacts/{me}", {"name": "Mum", "phone_number": "+447700900001"}),
        foreign("POST", "/emergency-contacts/{me}", {"name": "Mallory", "phone_number": "+447700900002"}, {403}),
        bad("POST", "/emergency-contacts/{me}", {"name": "Mum"}, label="missing phone"),
        bad("POST", "/emergency-contacts/{me}", {"phone_number": "+447700900003"}, label="missing name"),
    ],
    "PUT /emergency-contacts/{userID}/{contactID}": [
        anon("PUT", "/emergency-contacts/{me}/{contact}", {"name": "x", "phone_number": "+447700900004"}),
        foreign("PUT", "/emergency-contacts/{me}/{contact}", {"name": "x", "phone_number": "+447700900005"}, {403}),
        bad("PUT", "/emergency-contacts/{me}/{contact}", {"name": "", "phone_number": ""}, label="empty contact"),
        bad("PUT", "/emergency-contacts/{me}/{contact}", {"name": "Mum"}, label="missing phone"),
        malformed("PUT", "/emergency-contacts/{me}/not-a-uuid", {"name": "Mum", "phone_number": "+447700900007"}),
    ],
    "DELETE /emergency-contacts/{userID}/{contactID}": [
        anon("DELETE", "/emergency-contacts/{me}/{contact}"),
        foreign("DELETE", "/emergency-contacts/{me}/{contact}", expect={403}),
        P("unknown contact (idempotent)", "a", "DELETE", "/emergency-contacts/{me}/{uuid}", None, (200, 404)),
    ],

    # --- support (support_ticketing_enabled is off on the local stack) -----------------------
    "GET /support/tickets": [
        anon("GET", "/support/tickets"),
        gated("GET", "/support/tickets", flag="support_ticketing_enabled"),
    ],
    "POST /support/tickets": [
        anon("POST", "/support/tickets", {"subject": "Help", "body": "x", "category": "account"}),
        gated("POST", "/support/tickets", {"subject": "Help please", "body": "e2e", "category": "account"},
              flag="support_ticketing_enabled"),
    ],
    "GET /support/tickets/{ticketID}": [
        anon("GET", "/support/tickets/{uuid}"),
        gated("GET", "/support/tickets/{uuid}", flag="support_ticketing_enabled"),
    ],
    "POST /support/tickets/{ticketID}/close": [
        anon("POST", "/support/tickets/{uuid}/close", {}),
        gated("POST", "/support/tickets/{uuid}/close", {}, flag="support_ticketing_enabled"),
    ],
    "POST /support/tickets/{ticketID}/rating": [
        anon("POST", "/support/tickets/{uuid}/rating", {"rating": 5}),
        gated("POST", "/support/tickets/{uuid}/rating", {"rating": 5}, flag="support_ticketing_enabled"),
    ],
    "POST /support/tickets/{ticketID}/reopen": [
        anon("POST", "/support/tickets/{uuid}/reopen", {}),
        gated("POST", "/support/tickets/{uuid}/reopen", {}, flag="support_ticketing_enabled"),
    ],
    "POST /support/attachments": [
        anon("POST", "/support/attachments", {}),
        gated("POST", "/support/attachments", None, flag="support_ticketing_enabled", multipart=True),
    ],
    "POST /support/contact": [
        gated("POST", "/support/contact", {"email": "qa@example.test", "subject": "Hello there",
                                           "message": "e2e contract", "name": "QA"},
              flag="support_ticketing_enabled", actor="anon"),
    ],

    # --- settings, privacy, notifications ------------------------------------------------------
    "PATCH /settings/{userID}": [
        anon("PATCH", "/settings/{me}", {"theme": "auto"}),
        foreign("PATCH", "/settings/{me}", {"theme": "dark:gothic"}, {403}),
        bad("PATCH", "/settings/{me}", {"locale": "english"}, label="unknown locale"),
        bad("PATCH", "/settings/{me}", {"locale": 7}, label="locale not a string"),
    ],
    "PATCH /discovery/{userID}/filters/trust": [
        anon("PATCH", "/discovery/{me}/filters/trust", {"enabled": True}),
        foreign("PATCH", "/discovery/{me}/filters/trust", {"enabled": True}, {403}),
        bad("PATCH", "/discovery/{me}/filters/trust", {"enabled": True, "required_badge_codes": ["made_up"]},
            label="unknown badge"),
    ],
    "GET /discovery/{userID}/filters/trust": [
        anon("GET", "/discovery/{me}/filters/trust"),
        foreign("GET", "/discovery/{me}/filters/trust", expect={403}),
    ],
    "GET /discovery/{userID}": [
        anon("GET", "/discovery/{me}"),
        foreign("GET", "/discovery/{me}", expect={403}),
        P("hostile limit", "a", "GET", "/discovery/{me}?limit=abc", None, (200, 400)),
    ],
    "GET /discovery/{userID}/liked-me": [
        anon("GET", "/discovery/{me}/liked-me"),
        foreign("GET", "/discovery/{me}/liked-me", expect={403}),
    ],
    "POST /notifications/{userID}/{notificationID}/read": [
        anon("POST", "/notifications/{me}/{uuid}/read", {}),
        foreign("POST", "/notifications/{me}/{uuid}/read", {}, {403}),
        unknown("POST", "/notifications/{me}/{uuid}/read", {}),
    ],
    "POST /social/channels/{channelID}/read": [
        anon("POST", "/social/channels/{channel}/read", {}),
        foreign("POST", "/social/channels/{channel}/read", {}),
        unknown("POST", "/social/channels/{uuid}/read", {}, DENY),
        malformed("POST", "/social/channels/not-a-uuid/read", {}, (400, 403, 404)),
    ],
    "POST /moderation/appeals": [
        anon("POST", "/moderation/appeals", {"report_id": "{uuid}", "reason": "not me"}),
        bad("POST", "/moderation/appeals", {"report_id": "{uuid}", "reason": "not me"}, label="unknown report"),
        bad("POST", "/moderation/appeals", {"reason": "not me"}, label="missing report"),
    ],
    "GET /moderation/appeals": [
        anon("GET", "/moderation/appeals"),
        P("another member's appeals", "c", "GET", "/moderation/appeals?user_id={me}", None, (200, 403)),
    ],
    "PATCH /notifications/{userID}/preferences": [
        anon("PATCH", "/notifications/{me}/preferences", {"notify_likes": False}),
        foreign("PATCH", "/notifications/{me}/preferences", {"notify_likes": False}, {403}),
        bad("PATCH", "/notifications/{me}/preferences", {"notify_likes": "nope"}, label="wrong type"),
    ],
    "GET /notifications/{userID}/preferences": [
        anon("GET", "/notifications/{me}/preferences"),
        foreign("GET", "/notifications/{me}/preferences", expect={403}),
    ],
    "PUT /friends/{userID}/search-visibility": [
        anon("PUT", "/friends/{me}/search-visibility", {"visible": True}),
        foreign("PUT", "/friends/{me}/search-visibility", {"visible": False}, {403}),
        bad("PUT", "/friends/{me}/search-visibility", {"visible": "nope"}, label="wrong type"),
    ],
    "PUT /profile/{userID}/showcase/consent": [
        anon("PUT", "/profile/{me}/showcase/consent", {"visible": True}),
        foreign("PUT", "/profile/{me}/showcase/consent", {"visible": True}, {403}),
        bad("PUT", "/profile/{me}/showcase/consent", {"visible": "true"}, label="wrong type"),
    ],
    "GET /matches/{matchID}/graduation": [
        anon("GET", "/matches/{match}/graduation"),
        foreign("GET", "/matches/{match}/graduation"),
        unknown("GET", "/matches/{uuid}/graduation", expect=DENY),
    ],
    "GET /account/{userID}/discovery/pause": [
        anon("GET", "/account/{me}/discovery/pause"),
        foreign("GET", "/account/{me}/discovery/pause", expect={403}),
    ],
    "POST /account/{userID}/discovery/pause": [
        anon("POST", "/account/{me}/discovery/pause", {}),
        foreign("POST", "/account/{me}/discovery/pause", {}, {403}),
        bad("POST", "/account/{me}/discovery/pause", {"reason": "vacation"}, label="unknown reason"),
    ],
    "POST /account/{userID}/discovery/resume": [
        anon("POST", "/account/{me}/discovery/resume", {}),
        foreign("POST", "/account/{me}/discovery/resume", {}, {403}),
        bad("POST", "/account/{me}/discovery/resume", {}, {404}, label="discovery is not paused"),
    ],

    # --- engagement ----------------------------------------------------------------------------
    "GET /engagement/circles/{circleID}/challenge": [
        anon("GET", "/engagement/circles/{circle}/challenge"),
        unknown("GET", "/engagement/circles/no-such-circle/challenge"),
        unknown("GET", "/engagement/circles/not-a-uuid/challenge"),
    ],
    "POST /engagement/circles/{circleID}/join": [
        anon("POST", "/engagement/circles/{circle}/join", {"user_id": "{me}"}),
        unknown("POST", "/engagement/circles/no-such-circle/join", {"user_id": "{me}"}),
        bad("POST", "/engagement/circles/{circle}/join", {}, label="missing user_id"),
        P("actor must be the caller", "c", "POST", "/engagement/circles/{circle}/join", {"user_id": "{me}"}, {403}),
    ],
    "POST /engagement/circles/{circleID}/challenge/entries": [
        anon("POST", "/engagement/circles/{circle}/challenge/entries", {"user_id": "{me}", "entry_text": "x"}),
        unknown("POST", "/engagement/circles/no-such-circle/challenge/entries",
                {"user_id": "{me}", "entry_text": "A small win this week."}),
        bad("POST", "/engagement/circles/{circle}/challenge/entries", {"user_id": "{me}"}, label="missing entry"),
        bad("POST", "/engagement/circles/{circle}/challenge/entries", {"user_id": "{me}", "entry_text": "x" * 281},
            label="entry too long"),
        bad("POST", "/engagement/circles/{circle}/challenge/entries", {"user_id": "{me}", "entry_text": "A quote",
                                                                       "challenge_id": "last-year"},
            label="wrong challenge week"),
        P("actor must be the caller", "c", "POST", "/engagement/circles/{circle}/challenge/entries",
          {"user_id": "{me}", "entry_text": "spoofed entry"}, {403}),
    ],
    "GET /rooms": [
        anon("GET", "/rooms"),
        bad("GET", "/rooms?category=nightclub", None, (200, 400), label="unknown category filter"),
    ],
    "POST /rooms/{roomID}/join": [
        anon("POST", "/rooms/{room}/join", {"user_id": "{me}"}),
        P("actor must be the caller", "c", "POST", "/rooms/{room}/join", {"user_id": "{me}"}, {403}),
        unknown("POST", "/rooms/{uuid}/join", {"user_id": "{outsider}"}, actor="c"),
        malformed("POST", "/rooms/not-a-uuid/join", {"user_id": "{outsider}"}, actor="c"),
    ],
    "POST /rooms": [
        anon("POST", "/rooms", {"title": "x room", "category": "talk"}),
        bad("POST", "/rooms", {"title": "x room", "category": "nightclub", "duration_minutes": 60}, actor="c",
            label="unknown category"),
        bad("POST", "/rooms", {"title": "ab", "category": "talk"}, actor="c", label="title too short"),
        bad("POST", "/rooms", {"title": "Valid title", "category": "talk", "capacity": 51}, actor="c",
            label="capacity too big"),
    ],
    "POST /rooms/{roomID}/leave": [
        anon("POST", "/rooms/{room}/leave", {"user_id": "{me}"}),
        P("actor must be the caller", "c", "POST", "/rooms/{room}/leave", {"user_id": "{me}"}, {403}),
        unknown("POST", "/rooms/{uuid}/leave", {"user_id": "{outsider}"}, (404, 409), actor="c"),
    ],
    "POST /rooms/{roomID}/moderate": [
        anon("POST", "/rooms/{room}/moderate", {"target_user_id": "{peer}", "action": "mute"}),
        P("guest cannot moderate", "c", "POST", "/rooms/{room}/moderate",
          {"target_user_id": "{me}", "action": "mute", "duration_minutes": 10}, DENY),
        bad("POST", "/rooms/{room}/moderate", {"target_user_id": "{peer}", "action": "banish"},
            label="unknown action"),
        unknown("POST", "/rooms/{uuid}/moderate", {"target_user_id": "{peer}", "action": "mute"}, DENY),
    ],
    "GET /engagement/daily-prompt/{userID}": [
        anon("GET", "/engagement/daily-prompt/{me}"),
        foreign("GET", "/engagement/daily-prompt/{me}", expect={403}),
    ],
    "GET /engagement/daily-prompt/{userID}/responders": [
        anon("GET", "/engagement/daily-prompt/{me}/responders"),
        foreign("GET", "/engagement/daily-prompt/{me}/responders", expect={403}),
    ],
    "POST /engagement/daily-prompt/{userID}/answer": [
        anon("POST", "/engagement/daily-prompt/{me}/answer", {"answer_text": "x"}),
        foreign("POST", "/engagement/daily-prompt/{me}/answer", {"answer_text": "spoofed"}, {403}),
        bad("POST", "/engagement/daily-prompt/{me}/answer", {"answer_text": ""}, label="empty answer"),
        bad("POST", "/engagement/daily-prompt/{me}/answer", {"answer_text": "x" * 241}, label="answer too long"),
    ],
    "GET /engagement/group-coffee-polls": [
        anon("GET", "/engagement/group-coffee-polls?user_id={me}"),
        bad("GET", "/engagement/group-coffee-polls", None, label="missing user_id"),
        bad("GET", "/engagement/group-coffee-polls?user_id={me}&limit=abc", None, label="non-numeric limit"),
    ],
    "POST /engagement/group-coffee-polls": [
        anon("POST", "/engagement/group-coffee-polls", {"creator_user_id": "{me}"}),
        P("actor must be the caller", "c", "POST", "/engagement/group-coffee-polls",
          {"creator_user_id": "{me}", "participant_user_ids": ["{peer}"],
           "options": [{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"}]}, {403}),
        bad("POST", "/engagement/group-coffee-polls", {"creator_user_id": "{me}", "participant_user_ids": ["{peer}"]},
            label="missing options"),
        bad("POST", "/engagement/group-coffee-polls", {"creator_user_id": "{me}", "participant_user_ids": [],
                                                       "options": [{"day": "Saturday", "time_window": "10:00-12:00",
                                                                    "neighborhood": "Indiranagar"}]},
            label="nobody to meet"),
        bad("POST", "/engagement/group-coffee-polls", {"creator_user_id": "{me}", "participant_user_ids": ["{peer}"],
                                                       "options": [{"day": "Saturday"}]}, label="incomplete option"),
    ],
    "POST /engagement/group-coffee-polls/{pollID}/votes": [
        anon("POST", "/engagement/group-coffee-polls/{uuid}/votes", {"user_id": "{me}", "option_id": "{uuid}"}),
        unknown("POST", "/engagement/group-coffee-polls/{uuid}/votes", {"user_id": "{me}", "option_id": "{uuid}"},
                (403, 404)),
        P("not a participant", "c", "POST", "/engagement/group-coffee-polls/{poll}/votes",
          {"user_id": "{outsider}", "option_id": "{poll_option}"}, {403}),
        malformed("POST", "/engagement/group-coffee-polls/not-a-uuid/votes", {"user_id": "{me}", "option_id": "{uuid}"},
                  (400, 403, 404)),
        P("actor must be the caller", "c", "POST", "/engagement/group-coffee-polls/{uuid}/votes",
          {"user_id": "{me}", "option_id": "{uuid}"}, {403}),
    ],
    "POST /engagement/group-coffee-polls/{pollID}/finalize": [
        anon("POST", "/engagement/group-coffee-polls/{uuid}/finalize", {"user_id": "{me}"}),
        unknown("POST", "/engagement/group-coffee-polls/{uuid}/finalize", {"user_id": "{me}"}),
        P("only the creator finalizes", "b", "POST", "/engagement/group-coffee-polls/{poll}/finalize",
          {"user_id": "{peer}"}, {403}),
        malformed("POST", "/engagement/group-coffee-polls/not-a-uuid/finalize", {"user_id": "{me}"}),
        P("actor must be the caller", "c", "POST", "/engagement/group-coffee-polls/{uuid}/finalize",
          {"user_id": "{me}"}, {403}),
    ],
    "GET /progression/{userID}": [
        anon("GET", "/progression/{me}"),
        foreign("GET", "/progression/{me}", expect={403}),
    ],
    "GET /progression/{userID}/ledger": [
        anon("GET", "/progression/{me}/ledger"),
        foreign("GET", "/progression/{me}/ledger", expect={403}),
    ],
    "POST /progression/{userID}/rewards/claim": [
        anon("POST", "/progression/{me}/rewards/claim", {"reward_key": "starter_accent"}),
        foreign("POST", "/progression/{me}/rewards/claim", {"reward_key": "starter_accent"}, {403}),
        bad("POST", "/progression/{me}/rewards/claim", {"reward_key": "starter_accent"}, {409},
            label="reward above the member's level"),
        bad("POST", "/progression/{me}/rewards/claim", {"reward_key": "no_such_reward"}, (400, 404, 409),
            label="unknown reward"),
    ],
    "POST /engagement/match-nudges/send": [
        anon("POST", "/engagement/match-nudges/send", {"match_id": "{match}", "user_id": "{me}",
                                                       "counterparty_user_id": "{peer}"}),
        P("not a participant", "c", "POST", "/engagement/match-nudges/send",
          {"match_id": "{match}", "user_id": "{outsider}", "counterparty_user_id": "{me}"}, DENY),
        P("actor must be the caller", "c", "POST", "/engagement/match-nudges/send",
          {"match_id": "{match}", "user_id": "{me}", "counterparty_user_id": "{peer}"}, DENY),
        bad("POST", "/engagement/match-nudges/send", {"user_id": "{me}", "counterparty_user_id": "{peer}"},
            label="missing match"),
        bad("POST", "/engagement/match-nudges/send", {"match_id": "{match}", "user_id": "{me}"},
            label="missing counterparty"),
    ],
    "POST /safety/report": [
        anon("POST", "/safety/report", {"reporter_user_id": "{me}", "reported_user_id": "{peer}", "reason": "spam"}),
        P("actor must be the caller", "c", "POST", "/safety/report",
          {"reporter_user_id": "{me}", "reported_user_id": "{peer}", "reason": "spam"}, {403}),
        bad("POST", "/safety/report", {"reporter_user_id": "{me}", "reported_user_id": "{me}", "reason": "spam"},
            label="self report"),
        bad("POST", "/safety/report", {"reporter_user_id": "{me}", "reported_user_id": "{peer}"},
            label="missing reason"),
        bad("POST", "/safety/report", {"reporter_user_id": "{me}", "reported_user_id": "{uuid}", "reason": "spam"},
            (400, 404), label="unknown member"),
    ],
    "GET /users/{userID}/trust-badges": [
        anon("GET", "/users/{me}/trust-badges"),
        P("another member's badges are public", "c", "GET", "/users/{me}/trust-badges", None, {200}),
    ],
    "GET /engagement/voice-icebreakers/prompts": [
        anon("GET", "/engagement/voice-icebreakers/prompts"),
    ],
    "POST /engagement/voice-icebreakers/start": [
        anon("POST", "/engagement/voice-icebreakers/start", {"match_id": "{match}"}),
        P("not a participant", "c", "POST", "/engagement/voice-icebreakers/start",
          {"match_id": "{match}", "sender_user_id": "{outsider}", "receiver_user_id": "{me}",
           "prompt_id": "voice-lite-calm-sunday"}, DENY),
        P("actor must be the caller", "b", "POST", "/engagement/voice-icebreakers/start",
          {"match_id": "{match}", "sender_user_id": "{me}", "receiver_user_id": "{peer}"}, {403}),
        bad("POST", "/engagement/voice-icebreakers/start", {"match_id": "{match}", "sender_user_id": "{me}",
                                                            "receiver_user_id": "{me}"}, label="send to yourself"),
        bad("POST", "/engagement/voice-icebreakers/start", {"match_id": "{match}", "sender_user_id": "{me}",
                                                            "receiver_user_id": "{peer}", "prompt_id": "made-up"},
            (400, 409), label="unknown prompt"),
    ],
    "POST /engagement/voice-icebreakers/{icebreakerID}/send": [
        anon("POST", "/engagement/voice-icebreakers/{uuid}/send", {}),
        bad("POST", "/engagement/voice-icebreakers/{uuid}/send", {"transcript": "hi"}, {415}, label="not multipart"),
    ],
    "POST /engagement/voice-icebreakers/{icebreakerID}/play": [
        anon("POST", "/engagement/voice-icebreakers/{uuid}/play", {}),
        unknown("POST", "/engagement/voice-icebreakers/{uuid}/play", {"user_id": "{me}"}, (403, 404)),
        P("actor must be the caller", "c", "POST", "/engagement/voice-icebreakers/{uuid}/play", {"user_id": "{me}"},
          {403}),
    ],

    # --- friends and introductions ---------------------------------------------------------------
    "POST /friends/{userID}/{friendUserID}/decision": [
        anon("POST", "/friends/{me}/{outsider}/decision", {"decision": "accept"}),
        foreign("POST", "/friends/{me}/{peer}/decision", {"decision": "accept"}, {403}),
        unknown("POST", "/friends/{me}/{uuid}/decision", {"decision": "accept"}),
        bad("POST", "/friends/{me}/{outsider}/decision", {"decision": "maybe"}, (400, 404), label="unknown decision"),
    ],
    "GET /friends/{userID}": [
        anon("GET", "/friends/{me}"),
        foreign("GET", "/friends/{me}", expect={403}),
    ],
    "GET /friends/{userID}/activities": [
        anon("GET", "/friends/{me}/activities"),
        foreign("GET", "/friends/{me}/activities", expect={403}),
    ],
    "DELETE /friends/{userID}/{friendUserID}": [
        anon("DELETE", "/friends/{me}/{peer}"),
        foreign("DELETE", "/friends/{me}/{peer}", expect={403}),
        P("no friendship to remove (idempotent)", "a", "DELETE", "/friends/{me}/{uuid}", None, (200, 404)),
    ],
    "POST /social/friends/{friendID}/channel": [
        anon("POST", "/social/friends/{peer}/channel", {}),
        P("not friends", "c", "POST", "/social/friends/{me}/channel", {}, DENY),
        malformed("POST", "/social/friends/not-a-uuid/channel", {}, (400, 403, 404)),
    ],
    "GET /friends/{userID}/vouches": [
        anon("GET", "/friends/{me}/vouches"),
        foreign("GET", "/friends/{me}/vouches", expect={403}),
    ],
    "GET /friends/{userID}/intros": [
        anon("GET", "/friends/{me}/intros"),
        foreign("GET", "/friends/{me}/intros", expect={403}),
    ],
    "POST /friends/{userID}/intros": [
        anon("POST", "/friends/{me}/intros", {"first_user_id": "{peer}", "second_user_id": "{outsider}"}),
        foreign("POST", "/friends/{me}/intros", {"first_user_id": "{peer}", "second_user_id": "{outsider}"}, {403}),
        bad("POST", "/friends/{me}/intros", {"first_user_id": "{peer}", "second_user_id": "{me}",
                                             "message": "Meet me!"}, label="introduce yourself"),
        bad("POST", "/friends/{me}/intros", {"first_user_id": "{peer}"}, label="missing second member"),
    ],
    "GET /friends/{userID}/plans": [
        anon("GET", "/friends/{me}/plans"),
        foreign("GET", "/friends/{me}/plans", expect={403}),
    ],
    "POST /introducer/invites": [
        anon("POST", "/introducer/invites", {}),
        P("an introducer account cannot invite", "intro", "POST", "/introducer/invites", {}, {403}),
    ],
    "DELETE /introducer/invites": [
        anon("DELETE", "/introducer/invites"),
        P("an introducer account cannot cancel member invites", "intro", "DELETE", "/introducer/invites", None, {403}),
    ],
    "POST /introducer/redeem": [
        anon("POST", "/introducer/redeem", {"code": "NOPE"}),
        P("a dating member cannot redeem", "c", "POST", "/introducer/redeem", {"code": "{invite_code}"}, (403, 409)),
        P("unknown code", "intro", "POST", "/introducer/redeem", {"code": "x" * 43}, (400, 404, 409)),
        P("missing code", "intro", "POST", "/introducer/redeem", {}, (400, 409)),
    ],
    "POST /introducer/connections/{consentID}/approve": [
        anon("POST", "/introducer/connections/{uuid}/approve", {}),
        unknown("POST", "/introducer/connections/{uuid}/approve", {}, (403, 404, 409)),
        malformed("POST", "/introducer/connections/not-a-uuid/approve", {}, (400, 404, 409)),
        P("an introducer cannot approve", "intro", "POST", "/introducer/connections/{uuid}/approve", {}, {403}),
    ],
    "DELETE /introducer/connections/{consentID}": [
        anon("DELETE", "/introducer/connections/{uuid}"),
        unknown("DELETE", "/introducer/connections/{uuid}", None, (403, 404, 409)),
        malformed("DELETE", "/introducer/connections/not-a-uuid", None, (400, 404, 409)),
    ],

    # --- groups ------------------------------------------------------------------------------------
    "PUT /engagement/groups/{groupID}/cover": [
        anon("PUT", "/engagement/groups/{group}/cover", {}),
        P("not the owner", "c", "PUT", "/engagement/groups/{group}/cover", None, DENY, multipart=True),
        P("unknown group", "a", "PUT", "/engagement/groups/{uuid}/cover", None, DENY, multipart=True),
        bad("PUT", "/engagement/groups/{group}/cover", {"image": "base64?"}, (400, 415), label="not multipart"),
    ],
    "POST /engagement/groups/{groupID}/invites/respond": [
        anon("POST", "/engagement/groups/{group}/invites/respond", {"decision": "accept"}),
        P("no invite", "c", "POST", "/engagement/groups/{group}/invites/respond", {"decision": "accept"}, DENY),
        unknown("POST", "/engagement/groups/{uuid}/invites/respond", {"decision": "accept"}, DENY, actor="b"),
        bad("POST", "/engagement/groups/{group}/invites/respond", {"decision": "perhaps"}, (400, 404), actor="b",
            label="unknown decision"),
    ],
    "POST /engagement/groups/{groupID}/members/{userID}": [
        anon("POST", "/engagement/groups/{group}/members/{peer}", {"action": "remove"}),
        P("not a manager", "c", "POST", "/engagement/groups/{group}/members/{peer}", {"action": "remove"}, DENY),
        bad("POST", "/engagement/groups/{group}/members/{peer}", {"action": "crown"}, (400, 404), label="unknown action"),
        unknown("POST", "/engagement/groups/{group}/members/{uuid}", {"action": "remove"}, (400, 404)),
    ],
    "PUT /account/{userID}/dating-preferences": [
        anon("PUT", "/account/{me}/dating-preferences", {"intent": "relationship"}),
        foreign("PUT", "/account/{me}/dating-preferences", {"intent": "relationship"}, {403}),
        bad("PUT", "/account/{me}/dating-preferences", {"intent": "polyamory-ish", "version": 1}, (400, 409),
            label="unknown intent"),
    ],
    "PUT /profile/{userID}/stories": [
        anon("PUT", "/profile/{me}/stories", {"stories": [], "published": False, "expected_version": 0}),
        foreign("PUT", "/profile/{me}/stories", {"stories": [], "published": False, "expected_version": 0}, {403}),
        bad("PUT", "/profile/{me}/stories", {"stories": [{"prompt_id": "not_a_prompt", "text": "hello there"}],
                                             "published": True, "expected_version": "{stories_version}"},
            label="unknown prompt"),
        bad("PUT", "/profile/{me}/stories", {"stories": [], "published": False}, label="missing expected_version"),
    ],

    # --- mini activities --------------------------------------------------------------------------
    "POST /activities/sessions/start": [
        anon("POST", "/activities/sessions/start", {"match_id": "{match}"}),
        P("not a participant", "c", "POST", "/activities/sessions/start",
          {"match_id": "{match}", "initiator_user_id": "{outsider}", "participant_user_id": "{me}",
           "activity_type": "co_op_prompt"}, DENY),
        P("actor must be the caller", "c", "POST", "/activities/sessions/start",
          {"match_id": "{match}", "initiator_user_id": "{me}", "participant_user_id": "{peer}",
           "activity_type": "co_op_prompt"}, DENY),
    ],
    "POST /activities/sessions/{sessionID}/submit": [
        anon("POST", "/activities/sessions/{uuid}/submit", {"user_id": "{me}", "responses": ["a"]}),
        unknown("POST", "/activities/sessions/{uuid}/submit", {"user_id": "{me}", "responses": ["a"]}),
        P("actor must be the caller", "c", "POST", "/activities/sessions/{session}/submit",
          {"user_id": "{me}", "responses": ["a"]}, {403}),
    ],
    "GET /activities/sessions/{sessionID}/summary": [
        anon("GET", "/activities/sessions/{session}/summary"),
        unknown("GET", "/activities/sessions/{uuid}/summary"),
    ],

    # --- matches and chat ---------------------------------------------------------------------------
    "GET /matches/{userID}": [
        anon("GET", "/matches/{me}"),
        foreign("GET", "/matches/{me}", expect={403}),
    ],
    "POST /matches/{matchID}/read": [
        anon("POST", "/matches/{match}/read", {"user_id": "{me}"}),
        foreign("POST", "/matches/{match}/read", {"user_id": "{outsider}"}),
        P("actor must be the caller", "b", "POST", "/matches/{match}/read", {"user_id": "{me}"}, {403}),
        unknown("POST", "/matches/{uuid}/read", {"user_id": "{me}"}, DENY),
    ],
    "DELETE /matches/{matchID}": [
        anon("DELETE", "/matches/{match}"),
        foreign("DELETE", "/matches/{match}?user_id={outsider}"),
        unknown("DELETE", "/matches/{uuid}?user_id={me}", expect=DENY),
        malformed("DELETE", "/matches/not-a-uuid?user_id={me}", expect=(400, 403, 404)),
    ],
    "POST /matches/{matchID}/copilot/draft": [
        anon("POST", "/matches/{match}/copilot/draft", {"kind": "opener", "tone": "warm"}),
        foreign("POST", "/matches/{match}/copilot/draft", {"kind": "opener", "tone": "warm"}),
        bad("POST", "/matches/{match}/copilot/draft", {"kind": "love_letter"}, label="unknown kind"),
        bad("POST", "/matches/{match}/copilot/draft", {"kind": "opener", "tone": "sarcastic"}, label="unknown tone"),
    ],
    "POST /chat/{matchID}/gifts/events": [
        anon("POST", "/chat/{match}/gifts/events", {"event_name": "gift_panel_opened", "user_id": "{me}"}),
        foreign("POST", "/chat/{match}/gifts/events", {"event_name": "gift_panel_opened", "user_id": "{outsider}"}),
        P("actor must be the caller", "b", "POST", "/chat/{match}/gifts/events",
          {"event_name": "gift_panel_opened", "user_id": "{me}"}, {403}),
        bad("POST", "/chat/{match}/gifts/events", {"event_name": "made_up_event", "user_id": "{me}"},
            label="unknown event"),
        bad("POST", "/chat/{match}/gifts/events", {"event_name": "gift_panel_opened"}, label="missing user_id"),
        bad("POST", "/chat/{match}/gifts/events", {"event_name": "gift_panel_opened", "user_id": "{me}",
                                                   "match_id": "{uuid}"}, (400, 403), label="body match differs from path"),
        unknown("POST", "/chat/{uuid}/gifts/events", {"event_name": "gift_panel_opened", "user_id": "{me}"}, DENY),
    ],
    "GET /chat/gifts": [
        anon("GET", "/chat/gifts"),
    ],
    "GET /wallet/{userID}/coins": [
        anon("GET", "/wallet/{me}/coins"),
        foreign("GET", "/wallet/{me}/coins", expect={403}),
    ],
    "DELETE /chat/{matchID}/messages/{messageID}": [
        anon("DELETE", "/chat/{match}/messages/{msg}", {"requester_user_id": "{me}"}),
        foreign("DELETE", "/chat/{match}/messages/{msg}", {"requester_user_id": "{outsider}"}),
        P("partner cannot delete it", "b", "DELETE", "/chat/{match}/messages/{msg}", {"requester_user_id": "{peer}"}, DENY),
        unknown("DELETE", "/chat/{match}/messages/{uuid}", {"requester_user_id": "{me}"}),
    ],
    "POST /chat/{matchID}/messages/{messageID}/gift/hide": [
        anon("POST", "/chat/{match}/messages/{gift_msg}/gift/hide", {}),
        P("the sender cannot hide it", "a", "POST", "/chat/{match}/messages/{gift_msg}/gift/hide", {}, DENY),
        foreign("POST", "/chat/{match}/messages/{gift_msg}/gift/hide", {}),
        unknown("POST", "/chat/{match}/messages/{uuid}/gift/hide", {}, actor="b"),
        malformed("POST", "/chat/{match}/messages/not-a-uuid/gift/hide", {}, actor="b"),
    ],
    "POST /chat/{matchID}/messages/{messageID}/gift/report": [
        anon("POST", "/chat/{match}/messages/{gift_msg}/gift/report", {"reason": "unwanted"}),
        foreign("POST", "/chat/{match}/messages/{gift_msg}/gift/report", {"reason": "unwanted"}),
        bad("POST", "/chat/{match}/messages/{gift_msg}/gift/report", {"reason": "because"}, actor="b",
            label="unknown reason"),
        bad("POST", "/chat/{match}/messages/{gift_msg}/gift/report", {"reason": "other", "details": "d" * 501},
            actor="b", label="details too long"),
        unknown("POST", "/chat/{match}/messages/{uuid}/gift/report", {"reason": "unwanted"}, actor="b"),
    ],
    "POST /chat/{matchID}/gifts/send": [
        anon("POST", "/chat/{match}/gifts/send", {"gift_id": "rose_red_single"}),
        foreign("POST", "/chat/{match}/gifts/send", {"gift_id": "rose_red_single", "sender_user_id": "{outsider}"}),
        bad("POST", "/chat/{match}/gifts/send", {"gift_id": "no_such_gift", "sender_user_id": "{me}"},
            (400, 404, 422), label="unknown gift"),
        P("wrong receiver", "a", "POST", "/chat/{match}/gifts/send",
          {"gift_id": "rose_red_single", "sender_user_id": "{me}", "receiver_user_id": "{outsider}"}, {403}),
    ],
    "POST /chat/{matchID}/messages": [
        anon("POST", "/chat/{match}/messages", {"text": "hi"}),
        foreign("POST", "/chat/{match}/messages", {"text": "intruder", "sender_id": "{outsider}"}),
        P("sender must be the caller", "b", "POST", "/chat/{match}/messages", {"text": "spoof", "sender_id": "{me}"}, {403}),
        unknown("POST", "/chat/{uuid}/messages", {"text": "hi", "sender_id": "{me}"}, DENY),
    ],
    "GET /chat/{matchID}/messages": [
        anon("GET", "/chat/{match}/messages"),
        foreign("GET", "/chat/{match}/messages"),
        unknown("GET", "/chat/{uuid}/messages", expect=DENY),
        malformed("GET", "/chat/not-a-uuid/messages", expect=(400, 403, 404)),
    ],
    "GET /matches/{matchID}/unlock-state": [
        anon("GET", "/matches/{match}/unlock-state"),
        foreign("GET", "/matches/{match}/unlock-state"),
        unknown("GET", "/matches/{uuid}/unlock-state", expect=DENY),
    ],

    # --- notifications -------------------------------------------------------------------------------
    "POST /notifications/{userID}/read-all": [
        anon("POST", "/notifications/{me}/read-all", {}),
        foreign("POST", "/notifications/{me}/read-all", {}, {403}),
    ],
    "POST /notifications/{userID}/devices": [
        anon("POST", "/notifications/{me}/devices", {"provider": "fcm", "platform": "android", "token": "t"}),
        foreign("POST", "/notifications/{me}/devices", {"provider": "fcm", "platform": "android", "token": "t"}, {403}),
        bad("POST", "/notifications/{me}/devices", {"provider": "carrier-pigeon", "platform": "android", "token": "t"},
            label="unknown provider"),
        bad("POST", "/notifications/{me}/devices", {"provider": "fcm", "platform": "android", "token": ""},
            label="empty token"),
    ],
    "GET /notifications/{userID}": [
        anon("GET", "/notifications/{me}"),
        foreign("GET", "/notifications/{me}", expect={403}),
    ],
    "GET /notifications/{userID}/unread-count": [
        anon("GET", "/notifications/{me}/unread-count"),
        foreign("GET", "/notifications/{me}/unread-count", expect={403}),
    ],
    "DELETE /notifications/{userID}/{notificationID}": [
        anon("DELETE", "/notifications/{me}/{uuid}"),
        foreign("DELETE", "/notifications/{me}/{uuid}", expect={403}),
        unknown("DELETE", "/notifications/{me}/{uuid}"),
    ],

    # --- billing (sandbox provider) --------------------------------------------------------------------
    "GET /billing/plans": [
        P("public catalogue needs no session", "anon", "GET", "/billing/plans", None, {200}),
    ],
    "GET /billing/subscription/{userID}": [
        anon("GET", "/billing/subscription/{me}"),
        foreign("GET", "/billing/subscription/{me}", expect={403}),
    ],
    "GET /billing/payments/{userID}": [
        anon("GET", "/billing/payments/{me}"),
        foreign("GET", "/billing/payments/{me}", expect={403}),
    ],
    "GET /billing/account": [
        anon("GET", "/billing/account"),
    ],
    "POST /billing/subscription/{userID}/resume": [
        anon("POST", "/billing/subscription/{me}/resume", {}),
        foreign("POST", "/billing/subscription/{me}/resume", {}, {403}),
        bad("POST", "/billing/subscription/{me}/resume", {}, (404, 409), label="free plan has nothing to resume"),
    ],
    "POST /billing/subscription/{userID}/cancel": [
        anon("POST", "/billing/subscription/{me}/cancel", {}),
        foreign("POST", "/billing/subscription/{me}/cancel", {}, {403}),
        bad("POST", "/billing/subscription/{me}/cancel", {}, (404, 409), label="free plan has nothing to cancel"),
    ],
    "POST /billing/checkout": [
        anon("POST", "/billing/checkout", {"kind": "coin_package", "package_id": "{uuid}"}),
        bad("POST", "/billing/checkout", {"plan_id": "free"}, label="free plan"),
        bad("POST", "/billing/checkout", {"plan_id": "no-such-plan"}, (400, 404), label="unknown plan"),
        unknown("POST", "/billing/checkout", {"kind": "coin_package", "package_id": "{uuid}"}),
    ],
    "GET /billing/checkout/{checkoutID}": [
        anon("GET", "/billing/checkout/{uuid}"),
        unknown("GET", "/billing/checkout/{uuid}"),
        malformed("GET", "/billing/checkout/not-a-uuid"),
        foreign("GET", "/billing/checkout/{checkout}", expect={403}),
    ],
    "POST /billing/subscription/{userID}/change-plan": [
        anon("POST", "/billing/subscription/{me}/change-plan", {"plan_id": "premium"}),
        foreign("POST", "/billing/subscription/{me}/change-plan", {"plan_id": "premium"}, {403}),
        bad("POST", "/billing/subscription/{me}/change-plan", {"plan_id": "no-such-plan"}, (400, 404, 409),
            label="unknown plan"),
        bad("POST", "/billing/subscription/{me}/change-plan", {}, (400, 404, 409), label="missing plan"),
    ],
    "POST /billing/sandbox/subscriptions/{userID}/simulate": [
        anon("POST", "/billing/sandbox/subscriptions/{me}/simulate", {"event": "renewal_succeeded"}),
        foreign("POST", "/billing/sandbox/subscriptions/{me}/simulate", {"event": "renewal_succeeded"}, {403}),
        bad("POST", "/billing/sandbox/subscriptions/{me}/simulate", {"event": "free_money"}, (400, 404, 409),
            label="unknown event"),
    ],

    # --- photo themes ------------------------------------------------------------------------------------
    "PUT /themes/{themeID}/entries/{entryID}": [
        anon("PUT", "/themes/{theme}/entries/{uuid}", {}),
        bad("PUT", "/themes/{theme}/entries/{uuid}", {"caption": "json is not multipart"}, (400, 415),
            label="not multipart"),
        P("unknown theme", "c", "PUT", "/themes/{uuid}/entries/{uuid}", None, (400, 404), multipart=True),
        P("another member's entry", "c", "PUT", "/themes/{theme}/entries/{entry}", None, (403, 404, 409), multipart=True),
    ],
    "POST /themes/{themeID}/entries/{entryID}/featuring": [
        anon("POST", "/themes/{theme}/entries/{entry}/featuring", {"allow": True}),
        foreign("POST", "/themes/{theme}/entries/{entry}/featuring", {"allow": False}, (403, 404)),
        bad("POST", "/themes/{theme}/entries/{entry}/featuring", {"allow": "yes"}, label="wrong type"),
        unknown("POST", "/themes/{theme}/entries/{uuid}/featuring", {"allow": True}, (403, 404)),
    ],

    # --- date plans --------------------------------------------------------------------------------------
    "GET /matches/{matchID}/plans": [
        anon("GET", "/matches/{match}/plans"),
        foreign("GET", "/matches/{match}/plans"),
        unknown("GET", "/matches/{uuid}/plans", expect=DENY),
    ],
    "GET /plans/{userID}": [
        anon("GET", "/plans/{me}"),
        foreign("GET", "/plans/{me}", expect={403}),
    ],
    "GET /matches/{matchID}/plans/{planID}/sharing": [
        anon("GET", "/matches/{match}/plans/{plan}/sharing"),
        foreign("GET", "/matches/{match}/plans/{plan}/sharing"),
        unknown("GET", "/matches/{match}/plans/{uuid}/sharing"),
    ],
    "POST /matches/{matchID}/plans/{planID}/sharing": [
        anon("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": [], "expected_version": 0}),
        foreign("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": [], "expected_version": 0}),
        unknown("POST", "/matches/{match}/plans/{uuid}/sharing", {"contact_ids": [], "expected_version": 0}),
        bad("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": ["{outsider}"], "expected_version": 0},
            {403}, label="share with a non-friend"),
        bad("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": ["{peer}"], "expected_version": 0},
            {403}, label="share with the date partner"),
        bad("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": "everyone", "expected_version": 0},
            label="contact_ids not a list"),
        bad("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": []}, label="missing expected_version"),
        bad("POST", "/matches/{match}/plans/{plan}/sharing", {"contact_ids": [], "expected_version": 7}, {409},
            label="stale expected_version"),
    ],

    # --- profile -------------------------------------------------------------------------------------------
    "GET /profile/{userID}/summary": [
        anon("GET", "/profile/{me}/summary"),
        foreign("GET", "/profile/{me}/summary", expect={403}),
    ],
    "GET /profile/{userID}/draft": [
        anon("GET", "/profile/{me}/draft"),
        foreign("GET", "/profile/{me}/draft", expect={403}),
    ],
    "PATCH /profile/{userID}/draft": [
        anon("PATCH", "/profile/{me}/draft", {"bio": "x"}),
        foreign("PATCH", "/profile/{me}/draft", {"bio": "hijacked bio"}, {403}),
        bad("PATCH", "/profile/{me}/draft", "not an object", label="body is not an object"),
    ],
    "DELETE /profile/{userID}/photos/{photoID}": [
        anon("DELETE", "/profile/{me}/photos/{uuid}"),
        foreign("DELETE", "/profile/{me}/photos/{photo}", expect={403}),
        unknown("DELETE", "/profile/{me}/photos/{uuid}"),
    ],
    "POST /profile/{userID}/photos": [
        anon("POST", "/profile/{me}/photos", {}),
        P("another member's profile", "c", "POST", "/profile/{me}/photos", None, {403}, multipart=True),
        bad("POST", "/profile/{me}/photos", {"image": "base64?"}, {415}, label="not multipart"),
    ],
    "POST /profile/{userID}/photos/reorder": [
        anon("POST", "/profile/{me}/photos/reorder", {"photo_ids": []}),
        foreign("POST", "/profile/{me}/photos/reorder", {"photo_ids": []}, {403}),
        bad("POST", "/profile/{me}/photos/reorder", {"photo_ids": []}, label="empty order"),
        bad("POST", "/profile/{me}/photos/reorder", {"photo_ids": ["{photo}", "{uuid}"]}, label="foreign photo id"),
    ],
    "POST /profile/{userID}/complete": [
        anon("POST", "/profile/{me}/complete", {}),
        foreign("POST", "/profile/{me}/complete", {}, {403}),
    ],
    "POST /profile/views": [
        anon("POST", "/profile/views", {"viewer_user_id": "{me}", "viewed_user_id": "{peer}"}),
        P("viewer must be the caller", "c", "POST", "/profile/views",
          {"viewer_user_id": "{me}", "viewed_user_id": "{peer}"}, {403}),
        bad("POST", "/profile/views", {"viewer_user_id": "{me}"}, label="missing viewed member"),
        bad("POST", "/profile/views", {"viewed_user_id": "{peer}"}, label="missing viewer"),
    ],

    # --- safety --------------------------------------------------------------------------------------------
    "GET /safety/sos/{userID}": [
        anon("GET", "/safety/sos/{me}"),
        foreign("GET", "/safety/sos/{me}", expect={403}),
    ],
    "POST /safety/sos": [
        anon("POST", "/safety/sos", {"user_id": "{me}", "emergency_level": "high"}),
        P("actor must be the caller", "c", "POST", "/safety/sos", {"user_id": "{me}", "emergency_level": "high"}, {403}),
        bad("POST", "/safety/sos", {"emergency_level": "high"}, label="missing user_id"),
    ],

    # --- social chat -------------------------------------------------------------------------------------
    "DELETE /social/channels/{channelID}/messages/{messageID}": [
        anon("DELETE", "/social/channels/{channel}/messages/{uuid}"),
        foreign("DELETE", "/social/channels/{channel}/messages/{social_msg}"),
        P("not the sender", "b", "DELETE", "/social/channels/{channel}/messages/{social_msg}", None, DENY),
        unknown("DELETE", "/social/channels/{channel}/messages/{uuid}"),
    ],
    "PUT /social/channels/{channelID}/mute": [
        anon("PUT", "/social/channels/{channel}/mute", {"duration": "8h"}),
        foreign("PUT", "/social/channels/{channel}/mute", {"duration": "8h"}),
        bad("PUT", "/social/channels/{channel}/mute", {"duration": "3d"}, label="unknown duration"),
    ],
    "DELETE /social/channels/{channelID}/mute": [
        anon("DELETE", "/social/channels/{channel}/mute"),
        foreign("DELETE", "/social/channels/{channel}/mute"),
        unknown("DELETE", "/social/channels/{uuid}/mute", expect=DENY),
    ],

    # --- swipe -----------------------------------------------------------------------------------------------
    "POST /swipe": [
        anon("POST", "/swipe", {"user_id": "{me}", "target_user_id": "{outsider}", "is_like": True}),
        P("actor must be the caller", "c", "POST", "/swipe", {"user_id": "{me}", "target_user_id": "{outsider}",
                                                              "is_like": True}, {403}),
        bad("POST", "/swipe", {"user_id": "{me}", "target_user_id": "{me}", "is_like": True}, label="self like"),
    ],

    # --- verification ------------------------------------------------------------------------------------------
    "POST /verification/{userID}/submit": [
        anon("POST", "/verification/{me}/submit", {}),
        P("another member's verification", "c", "POST", "/verification/{me}/submit", {}, {403}, multipart="selfie"),
        bad("POST", "/verification/{me}/submit", {"selfie": "x"}, {415}, label="not multipart"),
        P("selfie without an ID document", "a", "POST", "/verification/{me}/submit", {}, BAD, multipart="selfie"),
    ],
}


# --- the catalog cases -----------------------------------------------------------------
# Generated from feature_catalog.json (2026-10-02); broken title templates were
# resolved against the Flutter caller and the BFF route table:
#   POST /account/{}/discovery/{}          -> /discovery/pause and /discovery/resume
#   POST /billing/subscription/{}/${enabled -> /resume (on) and /cancel (off)
#   POST /chat/{}/messages/{}/gift/{}       -> /gift/hide and /gift/report
#   /city-pilot/events/${event[...}         -> /city-pilot/events/{eventID}/registration|feedback
#   POST /support/tickets/{}/{}             -> /close, /rating, /reopen per control
#   site.contact                            -> POST /support/contact

CASE_ENDPOINTS = {
    'auth.account_recovery.recovery_submit.api_contract': ['POST /auth/password/recover', 'POST /auth/recovery/assistance'],
    'auth.auth.signin_password_field_submit.api_contract': ['POST /auth/login'],
    'auth.auth.signin_login_button.api_contract': ['POST /auth/login'],
    'auth.signup.signup_create_account_button.api_contract': ['POST /auth/signup', 'POST /auth/signup/bootstrap'],
    'auth.user_agreement.terms_continue_button.api_contract': ['PATCH /users/{userID}/agreements/terms'],
    'auth.user_agreement.terms_sign_out.api_contract': ['POST /auth/logout', 'DELETE /notifications/{userID}/devices/{deviceID}'],
    'blog.blog_connections.accept_an_exchange.api_contract': ['DELETE /blog/responses/{responseID}', 'POST /blog/responses/{responseID}'],
    'blog.blog_connections.decline_kindly.api_contract': ['DELETE /blog/responses/{responseID}', 'POST /blog/responses/{responseID}'],
    'blog.blog_connections.withdraw_exchange.api_contract': ['DELETE /blog/responses/{responseID}', 'POST /blog/responses/{responseID}'],
    'blog.blog_connections.report_exchange.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'blog.blog_connections.submit_report_onsubmit.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'blog.blog_connections.block_member.api_contract': ['POST /safety/block'],
    'blog.blog_editor.check_saved_version.api_contract': ['GET /blog/posts/{postID}'],
    'blog.blog_editor.remove_photo.api_contract': ['DELETE /blog/posts/{postID}/photos/{photoID}'],
    'blog.blog_editor.add_a_photo.api_contract': ['PUT /blog/posts/{postID}/photos/{photoID}', 'PUT /blog/posts/{postID}'],
    'blog.blog_editor.blog_save.api_contract': ['PUT /blog/posts/{postID}'],
    'blog.blog_editor.save_as_only_me.api_contract': ['PUT /blog/posts/{postID}'],
    'blog.blog_follow.following.api_contract': ['PUT /blog/posts/{postID}/like', 'DELETE /blog/posts/{postID}/like', 'PUT /blog/authors/{authorID}/subscription', 'DELETE /blog/authors/{authorID}/subscription'],
    'blog.blog_follow.follow_their_chapters.api_contract': ['PUT /blog/posts/{postID}/like', 'DELETE /blog/posts/{postID}/like', 'PUT /blog/authors/{authorID}/subscription', 'DELETE /blog/authors/{authorID}/subscription'],
    'blog.blog.read_chapter.api_contract': ['POST /walls/views'],
    'blog.blog.delete_chapter.api_contract': ['DELETE /blog/posts/{postID}'],
    'blog.blog.report_chapter.api_contract': ['POST /blog/posts/{postID}/report'],
    'blog.blog.report_could_not_be_submitted_onsubmit.api_contract': ['POST /blog/posts/{postID}/report'],
    'blog.blog.block_this_member.api_contract': ['POST /safety/block'],
    'blog.blog_sharing.create_public_link.api_contract': ['POST /blog/publications'],
    'blog.blog_social.x_react.api_contract': ['PUT /blog/posts/{postID}/like', 'DELETE /blog/posts/{postID}/like', 'PUT /blog/authors/{authorID}/subscription', 'DELETE /blog/authors/{authorID}/subscription'],
    'blog.blog_social.state_count_ontoggle.api_contract': ['PUT /blog/posts/{postID}/like', 'DELETE /blog/posts/{postID}/like', 'PUT /blog/authors/{authorID}/subscription', 'DELETE /blog/authors/{authorID}/subscription'],
    'blog.blog_social.comments.api_contract': ['POST /walls/views'],
    'blog.blog_social.report_could_not_be_submitted_onsubmit.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'blog.blog_social.comment_options_onreport.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'blog.blog_writers.an_untitled_chapter.api_contract': ['POST /walls/views'],
    'calls.call_history.join_live_room_onrefresh.api_contract': ['GET /calls/history/{userID}'],
    'calls.call_session.end.api_contract': ['POST /calls/{callID}/end'],
    'calls.call_session.try_again.api_contract': ['POST /calls/start'],
    'city_pilot.city_pilot.join_the_city_pilot.api_contract': ['POST /city-pilot/membership'],
    'city_pilot.city_pilot.leave_pilot_2.api_contract': ['DELETE /city-pilot/membership'],
    'city_pilot.city_pilot.cancel_my_place.api_contract': ['DELETE /city-pilot/events/{eventID}/registration'],
    'city_pilot.city_pilot.reserve_a_free_place.api_contract': ['POST /city-pilot/events/{eventID}/registration'],
    'city_pilot.city_pilot.share_optional_feedback.api_contract': ['POST /city-pilot/events/{eventID}/feedback'],
    'clubs.club_detail.club_options.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'clubs.club_discussion.post_onsend.api_contract': ['PUT /clubs/{clubID}/posts/{postID}'],
    'clubs.club_discussion.post_actions.api_contract': ['DELETE /clubs/{clubID}/posts/{postID}', 'POST /clubs/{clubID}/posts/{postID}/visibility', 'POST /blog/reports/{kind}/{contentID}'],
    'clubs.club_members_sheet.actions_for_name.api_contract': ['POST /clubs/{clubID}/members/{userID}'],
    'clubs.club_pick_sheet.save_pick.api_contract': ['PUT /clubs/{clubID}/selections/{weekStart}'],
    'clubs.clubs.create_club.api_contract': ['PUT /clubs/{clubID}'],
    'clubs.list_sheets.create_list.api_contract': ['PUT /clubs/lists/{listID}'],
    'clubs.my_lists.list_options.api_contract': ['PUT /clubs/lists/{listID}/items/{titleID}', 'DELETE /clubs/lists/{listID}'],
    'clubs.my_lists.options_for_title.api_contract': ['PUT /clubs/lists/{listID}/items/{titleID}', 'DELETE /clubs/lists/{listID}/items/{titleID}'],
    'clubs.review_sheets.save_review.api_contract': ['PUT /clubs/titles/{titleID}/reviews/{reviewID}'],
    'clubs.title_detail.delete.api_contract': ['DELETE /clubs/reviews/{reviewID}'],
    'clubs.title_detail.report_this_review.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'common.account_data.retry_onretry.api_contract': ['GET /account/{userID}/lifecycle'],
    'common.account_data.account_cancel_deletion_button.api_contract': ['DELETE /account/{userID}/deletion', 'GET /account/{userID}/lifecycle'],
    'common.account_data.account_pause_toggle_button.api_contract': ['POST /account/{userID}/reactivate', 'GET /account/{userID}/lifecycle', 'POST /account/{userID}/deactivate'],
    'common.account_data.account_export_button.api_contract': ['POST /account/{userID}/export', 'GET /account/{userID}/lifecycle'],
    'common.account_data.account_delete_button.api_contract': ['POST /account/{userID}/deletion', 'GET /account/{userID}/lifecycle', 'POST /account/{userID}/deactivate'],
    'common.blocked_users.unblock.api_contract': ['POST /safety/unblock', 'GET /blocked-users/{userID}'],
    'common.emergency_contacts.add_contact.api_contract': ['POST /emergency-contacts/{userID}'],
    'common.emergency_contacts.edit_icon_edit_outlined.api_contract': ['PUT /emergency-contacts/{userID}/{contactID}'],
    'common.emergency_contacts.delete_icon_delete_outline.api_contract': ['DELETE /emergency-contacts/{userID}/{contactID}'],
    'common.help_support.if_someone_is_in_immediate_dange_onrefresh.api_contract': ['GET /support/tickets'],
    'common.language_settings.use_device_language.api_contract': ['PATCH /settings/{userID}'],
    'common.language_settings.check_circle_rounded_icon_check.api_contract': ['PATCH /settings/{userID}'],
    'common.main_navigation.discovery_preferences_onopenfilters.api_contract': ['PATCH /discovery/{userID}/filters/trust', 'GET /discovery/{userID}'],
    'common.main_navigation.discovery_preferences_onopenfilters_2.api_contract': ['PATCH /discovery/{userID}/filters/trust', 'GET /discovery/{userID}'],
    'common.main_navigation.dismiss.api_contract': ['POST /notifications/{userID}/{notificationID}/read', 'POST /social/channels/{channelID}/read'],
    'common.main_navigation.view_2.api_contract': ['POST /notifications/{userID}/{notificationID}/read', 'POST /social/channels/{channelID}/read'],
    'common.main_navigation.open.api_contract': ['POST /notifications/{userID}/{notificationID}/read', 'POST /social/channels/{channelID}/read'],
    'common.main_navigation.discovery_filter_button.api_contract': ['PATCH /discovery/{userID}/filters/trust', 'GET /discovery/{userID}'],
    'common.main_navigation.filters_apply_button.api_contract': ['PATCH /discovery/{userID}/filters/trust', 'GET /discovery/{userID}'],
    'common.moderation_appeals.submit_appeal.api_contract': ['POST /moderation/appeals', 'GET /moderation/appeals'],
    'common.moderation_appeals.reviewed_by_reviewer_onrefresh.api_contract': ['GET /moderation/appeals'],
    'common.notification_settings.in_app_notifications.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.push_notifications.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.new_matches.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.new_messages.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.likes.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.match_nudges.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.incoming_calls.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.safety_updates.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.notification_settings.notifications_friend_plans.api_contract': ['PATCH /notifications/{userID}/preferences'],
    'common.privacy_safety.show_age.api_contract': ['PATCH /settings/{userID}'],
    'common.privacy_safety.show_exact_distance.api_contract': ['PATCH /settings/{userID}'],
    'common.privacy_safety.show_online_status.api_contract': ['PATCH /settings/{userID}'],
    'common.privacy_safety.privacy_friend_search.api_contract': ['PUT /friends/{userID}/search-visibility', 'PUT /profile/{userID}/showcase/consent'],
    'common.privacy_safety.privacy_profile_showcase.api_contract': ['PUT /profile/{userID}/showcase/consent'],
    'common.privacy_safety.graduation_discovery_resume.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'common.privacy_safety.graduation_discovery_pause.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'common.settings.logout.api_contract': ['POST /auth/logout', 'DELETE /notifications/{userID}/devices/{deviceID}'],
    'common.settings.settings_theme_selector_selectionchanged.api_contract': ['PATCH /settings/{userID}'],
    'common.settings.settings_theme_preset_x.api_contract': ['PATCH /settings/{userID}'],
    'common.community_actions.report_could_not_be_submitted_onsubmit.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'engagement.circle_challenges.submit_entry_onrefresh.api_contract': ['GET /engagement/circles/{circleID}/challenge'],
    'engagement.circle_challenges.join_circle.api_contract': ['POST /engagement/circles/{circleID}/join'],
    'engagement.circle_challenges.submit_entry.api_contract': ['POST /engagement/circles/{circleID}/challenge/entries'],
    'engagement.conversation_rooms.rooms_tile_x.api_contract': ['POST /rooms/{roomID}/join', 'GET /rooms'],
    'engagement.conversation_rooms.rooms_start.api_contract': ['GET /rooms'],
    'engagement.conversation_rooms.rooms_members_are_hosting_join_e_onrefresh.api_contract': ['GET /rooms'],
    'engagement.conversation_rooms.try_again.api_contract': ['GET /rooms'],
    'engagement.conversation_rooms.rooms_start_submit.api_contract': ['POST /rooms'],
    'engagement.daily_prompt.update_answer_onrefresh.api_contract': ['GET /engagement/daily-prompt/{userID}', 'GET /engagement/daily-prompt/{userID}/responders'],
    'engagement.daily_prompt.update_answer.api_contract': ['POST /engagement/daily-prompt/{userID}/answer', 'GET /engagement/daily-prompt/{userID}/responders'],
    'engagement.group_coffee_polls.finalize_poll_onrefresh.api_contract': ['GET /engagement/group-coffee-polls'],
    'engagement.group_coffee_polls.create_poll.api_contract': ['POST /engagement/group-coffee-polls', 'GET /engagement/group-coffee-polls'],
    'engagement.group_coffee_polls.vote.api_contract': ['POST /engagement/group-coffee-polls/{pollID}/votes', 'GET /engagement/group-coffee-polls'],
    'engagement.group_coffee_polls.finalize_poll.api_contract': ['POST /engagement/group-coffee-polls/{pollID}/finalize', 'GET /engagement/group-coffee-polls'],
    'engagement.level_progression.progression_is_paused_while_an_a_onrefresh.api_contract': ['GET /progression/{userID}', 'GET /progression/{userID}/ledger'],
    'engagement.level_progression.locked_onclaim.api_contract': ['POST /progression/{userID}/rewards/claim', 'GET /progression/{userID}', 'GET /progression/{userID}/ledger'],
    'engagement.level_progression.errorcard_onretry_onretry.api_contract': ['GET /progression/{userID}', 'GET /progression/{userID}/ledger'],
    'engagement.match_nudges.nudge.api_contract': ['POST /engagement/match-nudges/send'],
    'engagement.room_chat.room_chat_menu.api_contract': ['POST /rooms/{roomID}/leave', 'POST /rooms/{roomID}/moderate', 'GET /rooms'],
    'engagement.room_chat.submit_report_onsubmit.api_contract': ['POST /safety/report'],
    'engagement.room_chat.room_member_report.api_contract': ['POST /safety/report'],
    'engagement.room_chat.room_member_block.api_contract': ['POST /safety/block'],
    'engagement.room_chat.room_member_warn.api_contract': ['POST /rooms/{roomID}/moderate'],
    'engagement.room_chat.room_member_unmute.api_contract': ['POST /rooms/{roomID}/moderate'],
    'engagement.room_chat.room_member_mute.api_contract': ['POST /rooms/{roomID}/moderate'],
    'engagement.room_chat.room_member_remove.api_contract': ['POST /rooms/{roomID}/moderate'],
    'engagement.trust_badges.no_trust_history_available_yet_onrefresh.api_contract': ['GET /users/{userID}/trust-badges'],
    'engagement.trust_filter.save_trust_filters_onrefresh.api_contract': ['GET /discovery/{userID}/filters/trust'],
    'engagement.trust_filter.save_trust_filters.api_contract': ['PATCH /discovery/{userID}/filters/trust'],
    'engagement.voice_icebreakers.share_your_hello.api_contract': ['POST /engagement/voice-icebreakers/start', 'POST /engagement/voice-icebreakers/{icebreakerID}/send'],
    'engagement.voice_icebreakers.listen_seconds_s.api_contract': ['POST /engagement/voice-icebreakers/{icebreakerID}/play'],
    'engagement.voice_icebreakers.reload_prompts.api_contract': ['GET /engagement/voice-icebreakers/prompts'],
    'friends.friends.friends_accept_x_accept.api_contract': ['POST /friends/{userID}/{friendUserID}/decision', 'GET /friends/{userID}', 'GET /friends/{userID}/activities'],
    'friends.friends.friends_decline_x_decline.api_contract': ['POST /friends/{userID}/{friendUserID}/decision', 'GET /friends/{userID}', 'GET /friends/{userID}/activities'],
    'friends.friends.friends_cancel_x_cancel.api_contract': ['DELETE /friends/{userID}/{friendUserID}', 'GET /friends/{userID}', 'GET /friends/{userID}/activities'],
    'friends.friends.friends_intro_decline_x_decide.api_contract': ['GET /friends/{userID}/vouches', 'GET /friends/{userID}/intros'],
    'friends.friends.friends_vouch_hide_x_decide.api_contract': ['GET /friends/{userID}/vouches', 'GET /friends/{userID}/intros'],
    'friends.friends.friends_menu_x_action.api_contract': ['DELETE /friends/{userID}/{friendUserID}', 'GET /friends/{userID}', 'GET /friends/{userID}/activities', 'POST /safety/block'],
    'friends.friends.friends_message_x_message.api_contract': ['POST /social/friends/{friendID}/channel'],
    'friends.friends.hide_from_profile.api_contract': ['GET /friends/{userID}/vouches', 'GET /friends/{userID}/intros'],
    'friends.introducer.account.api_contract': ['POST /auth/logout', 'DELETE /notifications/{userID}/devices/{deviceID}'],
    'friends.introducer.allow_introductions.api_contract': ['POST /introducer/connections/{consentID}/approve'],
    'friends.introducer.decline_request.api_contract': ['DELETE /introducer/connections/{consentID}'],
    'friends.introducer.create_invitation_code.api_contract': ['POST /introducer/invites'],
    'friends.introducer.cancel_unused_invitations.api_contract': ['DELETE /introducer/invites'],
    'friends.introducer.ask_for_permission.api_contract': ['POST /introducer/redeem'],
    'friends.introducer.suggest_an_introduction.api_contract': ['POST /friends/{userID}/intros'],
    'friends.friend_social_sheets.friends_vouch_submit.api_contract': ['GET /friends/{userID}/vouches', 'GET /friends/{userID}/intros', 'GET /friends/{userID}', 'GET /friends/{userID}/activities'],
    'friends.friend_social_sheets.friends_intro_submit.api_contract': ['GET /friends/{userID}/vouches', 'GET /friends/{userID}/intros', 'GET /friends/{userID}', 'GET /friends/{userID}/activities'],
    'graduation.graduation_celebration.graduation_celebration_done.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'graduation.propose_graduation_sheet.graduation_submit.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'graduation.graduation_banner.graduation_decline.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'graduation.graduation_banner.graduation_withdraw.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'groups.create_group.create_group.api_contract': ['PUT /engagement/groups/{groupID}/cover'],
    'groups.group_detail.owner_tools.api_contract': ['PUT /engagement/groups/{groupID}/cover'],
    'groups.group_detail.groups_detail_more.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'groups.group_detail.decline_onrespond.api_contract': ['POST /engagement/groups/{groupID}/invites/respond'],
    'groups.group_detail.options_for_name.api_contract': ['POST /engagement/groups/{groupID}/members/{userID}'],
    'groups.groups.decline_onrespond.api_contract': ['POST /engagement/groups/{groupID}/invites/respond'],
    'intentional_dating.dating_rhythm.rhythm_save.api_contract': ['PUT /account/{userID}/dating-preferences'],
    'intentional_dating.dating_rhythm.pause_introductions.api_contract': ['GET /matches/{matchID}/graduation', 'GET /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/pause', 'POST /account/{userID}/discovery/resume'],
    'intentional_dating.profile_stories.stories_save.api_contract': ['PUT /profile/{userID}/stories'],
    'intentional_dating.today_wall.inkwell_ontap.api_contract': ['POST /walls/views'],
    'intentional_dating.today_wall.today_wall_chapter_x.api_contract': ['POST /walls/views'],
    'matching.activity_session.start_a_new_session.api_contract': ['POST /activities/sessions/start'],
    'matching.activity_session.submit_responses.api_contract': ['POST /activities/sessions/{sessionID}/submit', 'GET /activities/sessions/{sessionID}/summary'],
    'matching.activity_session.time_is_up_load_summary.api_contract': ['GET /activities/sessions/{sessionID}/summary'],
    'matching.activity_session.refresh_summary.api_contract': ['GET /activities/sessions/{sessionID}/summary'],
    'matching.matches_list.retry.api_contract': ['GET /matches/{userID}'],
    'matching.matches_list.matches_match_row_x_options.api_contract': ['POST /engagement/match-nudges/send', 'POST /safety/report', 'DELETE /matches/{matchID}'],
    'matching.matches_list.matches_match_row_x.api_contract': ['POST /matches/{matchID}/read'],
    'matching.matches_list.matches_person_x_options.api_contract': ['POST /engagement/match-nudges/send', 'POST /safety/report', 'DELETE /matches/{matchID}'],
    'matching.matches_list.matches_nudge_action.api_contract': ['POST /engagement/match-nudges/send'],
    'matching.matches_list.matches_unmatch_action.api_contract': ['DELETE /matches/{matchID}'],
    'matching.matches_list.matches_report_action.api_contract': ['POST /safety/report'],
    'matching.matches_list.submit_report_onsubmit.api_contract': ['POST /safety/report'],
    'messaging.chat.find_the_words_oncopilot.api_contract': ['POST /matches/{matchID}/copilot/draft'],
    'messaging.chat.send_a_little_joy_ongift.api_contract': ['POST /chat/{matchID}/gifts/events'],
    'messaging.chat.walletcoins.api_contract': ['GET /chat/gifts', 'GET /wallet/{userID}/coins'],
    'messaging.chat.chat_message_x_longpress.api_contract': ['DELETE /chat/{matchID}/messages/{messageID}', 'POST /chat/{matchID}/messages/{messageID}/gift/hide', 'POST /chat/{matchID}/messages/{messageID}/gift/report'],
    'messaging.chat.chat_gift_receiver_actions_giftactions.api_contract': ['POST /chat/{matchID}/messages/{messageID}/gift/hide', 'POST /chat/{matchID}/messages/{messageID}/gift/report'],
    'messaging.chat.chat_copilot_button_copilot.api_contract': ['POST /matches/{matchID}/copilot/draft'],
    'messaging.chat.chat_gift_tray_button_gift.api_contract': ['POST /chat/{matchID}/gifts/events'],
    'messaging.chat.chat_send_button_send.api_contract': ['POST /chat/{matchID}/messages', 'GET /chat/{matchID}/messages', 'GET /matches/{matchID}/unlock-state', 'POST /matches/{matchID}/read'],
    'messaging.chat.close_gifts.api_contract': ['POST /chat/{matchID}/gifts/events'],
    'messaging.chat.chat_gift_item_x.api_contract': ['GET /chat/gifts', 'GET /wallet/{userID}/coins', 'POST /chat/{matchID}/gifts/send', 'GET /chat/{matchID}/messages'],
    'messaging.copilot_sheet.copilot_generate.api_contract': ['POST /matches/{matchID}/copilot/draft'],
    'messaging.copilot_sheet.copilot_use.api_contract': ['POST /matches/{matchID}/copilot/draft'],
    'notifications.notification_inbox.read_all.api_contract': ['POST /notifications/{userID}/read-all'],
    'notifications.notification_inbox.you_are_all_caught_up_onrefresh.api_contract': ['POST /notifications/{userID}/devices', 'GET /notifications/{userID}', 'GET /notifications/{userID}/unread-count', 'GET /notifications/{userID}/preferences'],
    'notifications.notification_inbox.someone_liked_you_ondismissed.api_contract': ['DELETE /notifications/{userID}/{notificationID}'],
    'notifications.notification_inbox.inkwell_ontap.api_contract': ['POST /notifications/{userID}/{notificationID}/read', 'POST /social/channels/{channelID}/read'],
    'payment.subscription.your_plan_renews_automatically_a_onrefresh.api_contract': ['GET /billing/plans', 'GET /billing/subscription/{userID}', 'GET /billing/payments/{userID}', 'GET /billing/account'],
    'payment.subscription.check_status_oncheck.api_contract': ['GET /billing/plans', 'GET /billing/subscription/{userID}', 'GET /billing/payments/{userID}', 'GET /billing/account'],
    'payment.subscription.resume_checkout_onresume.api_contract': ['GET /billing/plans', 'GET /billing/subscription/{userID}', 'GET /billing/payments/{userID}', 'GET /billing/account'],
    'payment.subscription.auto_renew_onautorenewchanged.api_contract': ['POST /billing/subscription/{userID}/resume', 'POST /billing/subscription/{userID}/cancel'],
    'payment.subscription.update_card_onupdatecard.api_contract': ['POST /billing/checkout', 'GET /billing/checkout/{checkoutID}', 'GET /billing/plans', 'GET /billing/subscription/{userID}'],
    'payment.subscription.subscribe_with_card_onsubscribe.api_contract': ['POST /billing/checkout', 'GET /billing/checkout/{checkoutID}', 'GET /billing/plans', 'GET /billing/subscription/{userID}'],
    'payment.subscription.subscribe_with_card_onswitch.api_contract': ['POST /billing/subscription/{userID}/change-plan', 'GET /billing/plans', 'GET /billing/subscription/{userID}', 'GET /billing/payments/{userID}'],
    'payment.subscription.sandboxcontrols_onevent_onevent.api_contract': ['POST /billing/sandbox/subscriptions/{userID}/simulate'],
    'payment.wallet_payment.opening_onbuy.api_contract': ['POST /billing/checkout', 'GET /billing/checkout/{checkoutID}', 'GET /billing/plans', 'GET /billing/subscription/{userID}'],
    'photo_themes.photo_theme_gallery.share_a_photo_for_this_theme.api_contract': ['PUT /themes/{themeID}/entries/{entryID}'],
    'photo_themes.photo_theme_gallery.themeentrytile_ontap.api_contract': ['POST /walls/views'],
    'photo_themes.photo_theme_widgets.state_count_ontoggle.api_contract': ['PUT /blog/posts/{postID}/like', 'DELETE /blog/posts/{postID}/like', 'PUT /blog/authors/{authorID}/subscription', 'DELETE /blog/authors/{authorID}/subscription'],
    'photo_themes.photo_theme_widgets.photo_featuring_x.api_contract': ['POST /themes/{themeID}/entries/{entryID}/featuring'],
    'photo_themes.photo_theme_widgets.report.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'photo_themes.photo_theme_widgets.block_name.api_contract': ['POST /safety/block'],
    'photo_themes.photo_wall.inkwell_ontap.api_contract': ['POST /walls/views'],
    'plans.debrief_date_plan_sheet.debrief_submit.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.debrief_date_plan_sheet.submit_report_onsubmit.api_contract': ['POST /safety/report'],
    'plans.plan_sharing_sheet.reload_sharing_choices.api_contract': ['GET /matches/{matchID}/plans/{planID}/sharing'],
    'plans.plan_sharing_sheet.plan_sharing_save.api_contract': ['POST /matches/{matchID}/plans/{planID}/sharing'],
    'plans.plans.no_plans_yet_onrefresh.api_contract': ['GET /plans/{userID}', 'GET /friends/{userID}/plans', 'GET /matches/{matchID}/plans'],
    'plans.plans.nothing_shared_yet_onrefresh.api_contract': ['GET /plans/{userID}', 'GET /friends/{userID}/plans', 'GET /matches/{matchID}/plans'],
    'plans.propose_date_plan_sheet.reload_latest_plan_discard_edits.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.propose_date_plan_sheet.plan_submit.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_debrief.api_contract': ['POST /safety/report', 'GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_decline.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_accept.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_cancel.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_need_help.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'plans.date_plan_card.plan_safe.api_contract': ['GET /matches/{matchID}/plans', 'GET /plans/{userID}', 'GET /friends/{userID}/plans'],
    'profile.profile_view.retry.api_contract': ['GET /profile/{userID}/summary', 'GET /profile/{userID}/draft'],
    'profile.profile_view.who_viewed_my_profile.api_contract': ['GET /profile/{userID}/summary', 'GET /profile/{userID}/draft'],
    'profile.profile_view.who_viewed_my_profile_2.api_contract': ['GET /profile/{userID}/summary', 'GET /profile/{userID}/draft'],
    'profile.profile_view.refresh_profile.api_contract': ['GET /profile/{userID}/summary', 'GET /profile/{userID}/draft'],
    'profile.setup_about.save_about_onsave.api_contract': ['PATCH /profile/{userID}/draft'],
    'profile.setup_photos.setup_photos_delete_x_deletephoto.api_contract': ['DELETE /profile/{userID}/photos/{photoID}'],
    'profile.setup_photos.setup_photos_x_button_pickcamera.api_contract': ['POST /profile/{userID}/photos'],
    'profile.setup_photos.setup_photos_x_button_pickgallery.api_contract': ['POST /profile/{userID}/photos'],
    'profile.setup_photos.min_plural_1_please_upload_at_le_onreorder.api_contract': ['POST /profile/{userID}/photos/reorder'],
    'profile.setup_photos.set_as_profile_picture_onsetprimary.api_contract': ['POST /profile/{userID}/photos/reorder'],
    'profile.setup_preferences.arrow_back_ios_new_icon_arrow_ba.api_contract': ['PATCH /profile/{userID}/draft'],
    'profile.setup_preferences.save_preferences.api_contract': ['POST /profile/{userID}/complete', 'PATCH /profile/{userID}/draft'],
    'profile.setup_preview.setup_preview_complete_button_complete.api_contract': ['POST /profile/{userID}/complete'],
    'profile.profile_showcase.themeentrytile_ontap.api_contract': ['POST /walls/views'],
    'profile.profile_showcase.favorite_border_rounded_icon_fav.api_contract': ['POST /walls/views'],
    'profile.profile_showcase.profile_showcase_consent.api_contract': ['PUT /profile/{userID}/showcase/consent'],
    'safety.sos.resolution_note_onrefresh.api_contract': ['GET /safety/sos/{userID}'],
    'safety.sos.safety_activate_sos.api_contract': ['POST /safety/sos'],
    'social_chat.social_chat.social_chat_mute.api_contract': ['DELETE /social/channels/{channelID}/mute', 'PUT /social/channels/{channelID}/mute', 'DELETE /social/channels/{channelID}/messages/{messageID}'],
    'social_chat.social_chat.social_message_x_longpress.api_contract': ['POST /blog/reports/{kind}/{contentID}'],
    'support.support_ticket_form.support_add_screenshot.api_contract': ['POST /support/attachments'],
    'support.support_ticket_form.submit_support_ticket.api_contract': ['POST /support/tickets'],
    'support.support_ticket_thread.try_again.api_contract': ['GET /support/tickets/{ticketID}'],
    'support.support_ticket_thread.try_again_onrefresh.api_contract': ['GET /support/tickets/{ticketID}'],
    'support.support_ticket_thread.support_close_close.api_contract': ['POST /support/tickets/{ticketID}/close'],
    'support.support_ticket_thread.support_rating_submit_rate.api_contract': ['POST /support/tickets/{ticketID}/rating'],
    'support.support_ticket_thread.support_reopen_reopen.api_contract': ['POST /support/tickets/{ticketID}/reopen'],
    'support.support_widgets.retry_upload.api_contract': ['POST /support/attachments'],
    'swipe.home_discovery.today_profile_x_openprofile.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.open_profile_icon_person_onopenspotlightprofi.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.discover_today_card_x_opentodayprofile.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.discover_today_card_x_openprofile.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.open_profile_icon_person_onopenprofile.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.discovery_retry_state_retry.api_contract': ['GET /discovery/{userID}'],
    'swipe.home_discovery.discovery_empty_state_refresh.api_contract': ['GET /discovery/{userID}'],
    'swipe.home_discovery.discovery_like_button_like.api_contract': ['POST /swipe'],
    'swipe.home_discovery.discovery_card_message_button_message.api_contract': ['GET /matches/{userID}', 'POST /swipe'],
    'swipe.home_discovery.discovery_view_more_button_openprofile.api_contract': ['POST /profile/views', 'POST /swipe'],
    'swipe.home_discovery.discovery_pass_button_pass.api_contract': ['POST /swipe'],
    'swipe.home_discovery.discovery_superlike_button_superlike.api_contract': ['POST /swipe'],
    'swipe.liked_me.retry.api_contract': ['GET /discovery/{userID}/liked-me'],
    'swipe.liked_me.liked_me_like_back_x_likeback.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.liked_me.liked_me_card_x_open.api_contract': ['POST /profile/views', 'POST /swipe', 'GET /matches/{userID}'],
    'swipe.liked_me.liked_me_pass_x_pass.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.liked_me.refreshindicator_onrefresh_onrefresh.api_contract': ['GET /discovery/{userID}/liked-me'],
    'swipe.profile_details.submit_report_onsubmit.api_contract': ['POST /safety/report'],
    'swipe.profile_details.profile_detail_report_button.api_contract': ['POST /safety/report'],
    'swipe.profile_details.profile_detail_love_button_love.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.profile_details.profile_detail_message_button_message.api_contract': ['GET /matches/{userID}', 'POST /swipe'],
    'swipe.spotlight_profiles.discovery_like_button_like.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.spotlight_profiles.discovery_card_message_button_message.api_contract': ['GET /matches/{userID}', 'POST /swipe'],
    'swipe.spotlight_profiles.discovery_view_more_button_openprofile.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.spotlight_profiles.discovery_pass_button_pass.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.spotlight_profiles.discovery_superlike_button_superlike.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'swipe.spotlight_profiles.discovery_undo_button_undo.api_contract': ['POST /swipe', 'GET /matches/{userID}'],
    'verification.verification_selfie.verification_selfie_submit_button.api_contract': ['POST /verification/{userID}/submit'],
    'web.web_member_workspace.sign_out.api_contract': ['POST /auth/logout', 'DELETE /notifications/{userID}/devices/{deviceID}'],
    'web.web_membership_page.retry.api_contract': ['GET /billing/plans', 'GET /billing/subscription/{userID}', 'GET /billing/payments/{userID}', 'GET /billing/account'],
    'site.contact.api_contract': ['POST /support/contact'],
}


# --- the world every probe runs against ----------------------------------------------------

def make_introducer(role):
    """An introducer account (signup with account_kind=introducer + terms), like the app's intro flow."""
    from client import PASSWORD, RUN_ID

    username = f"e2e_{RUN_ID}_{role}"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD,
                                         "account_kind": "introducer", "name": "E2E Introducer",
                                         "date_of_birth": "1990-05-05"}).ok(200, 201)
    api = Api(signup["access_token"])
    api.patch(f"/users/{signup['user_id']}/agreements/terms", {"accepted": True, "terms_version": "v1"}).ok()
    return api


@pytest.fixture(scope="module")
def world(make_member):
    """a and b are matched and friends; c is an outsider. a owns one of everything."""
    cleanup = []
    try:
        yield _build_world(make_member, cleanup)
    finally:
        for undo in reversed(cleanup):
            try:
                undo()
            except Exception:  # noqa: BLE001 - cleanup must never fail the run
                pass


def _build_world(make_member, cleanup):
    a, b, c = make_member("cat_a", "F", "M"), make_member("cat_b", "M", "F"), make_member("cat_c", "F", "M")
    match_id = match(a, b)
    befriend(a, b)
    ctx = {"me": a.user_id, "peer": b.user_id, "outsider": c.user_id, "username": a.username,
           "match": match_id, "monday": _monday(), "far_monday": _monday(weeks=6),
           "tuesday": (dt.date.fromisoformat(_monday()) + dt.timedelta(days=1)).isoformat()}

    # Chapters: a community chapter that invites private responses, and a private one.
    post_id = str(uuid.uuid4())
    post = a.put(f"/blog/posts/{post_id}", {
        "title": "E2E contract: learning to slow down",
        "body": "A short story about mountain trails and listening more than talking.",
        "audience": "community", "topic": "feelings", "invitation": "your_version",
        "expected_version": 0}).ok()["post"]
    ctx.update(post=post_id, post_version=post["version"])
    private_id = str(uuid.uuid4())
    private = a.put(f"/blog/posts/{private_id}", {"title": "E2E diary", "body": "only me", "audience": "private",
                                                  "expected_version": 0}).ok()["post"]
    ctx.update(private_post=private_id, private_version=private["version"])
    response_id = str(uuid.uuid4())
    b.post("/blog/responses", {"id": response_id, "post_id": post_id,
                               "text": "Your trails story made me want to walk more slowly too."}).ok()
    ctx["response"] = response_id

    # Match chat: a text message from a and a free gift from a to b.
    ctx["msg"] = a.post(f"/chat/{match_id}/messages", {"text": "contract probe",
                                                         "sender_id": a.user_id}).ok()["message_id"]
    gift = a.post(f"/chat/{match_id}/gifts/send", {"gift_id": "rose_red_single", "sender_user_id": a.user_id})
    ctx["gift_msg"] = gift["message"]["id"] if gift.status == 200 else str(uuid.uuid4())

    # Friend chat channel and one message from a.
    channel = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    ctx["channel"] = channel
    ctx["social_msg"] = a.post(f"/social/channels/{channel}/messages",
                               {"client_message_id": str(uuid.uuid4()), "body": "contract probe"}).ok()["message"]["id"]

    # A private group with b invited.
    group = a.post("/engagement/groups", {"kind": "private", "name": "E2E contract crew",
                                          "invitee_user_ids": [b.user_id]}).ok()["group"]
    ctx["group"] = group["id"]
    cleanup.append(lambda: a.delete(f"/engagement/groups/{group['id']}"))

    # A conversation room hosted by a.
    room = a.post("/rooms", {"title": "E2E contract room", "category": "talk", "duration_minutes": 30})
    if room.status == 201:
        ctx["room"] = room["room"]["id"]
        cleanup.append(lambda: a.post(f"/rooms/{ctx['room']}/moderate", {"action": "close", "reason": "e2e cleanup"}))
    else:
        ctx["room"] = str(uuid.uuid4())

    # A date plan inside the match.
    start, end = _window()
    plan = a.post(f"/matches/{match_id}/plans", {"window_start": start, "window_end": end,
                                                  "venue_category": "coffee"}).ok()["plan"]
    ctx["plan"] = plan["id"]
    cleanup.append(lambda: a.post(f"/matches/{match_id}/plans/{plan['id']}/cancel", {"reason": "e2e cleanup"}))

    # An emergency contact and a's first profile photo.
    contacts = a.post(f"/emergency-contacts/{a.user_id}", {"name": "E2E Contact",
                                                           "phone_number": "+447700900321"}).ok()["contacts"]
    ctx["contact"] = contacts[0]["id"]
    ctx["photo"] = a.get(f"/profile/{a.user_id}/draft").ok()["draft"]["photos"][0]["id"]

    # Book club: a's club, a catalogue title, this week's pick, a's post, list and review.
    club_id = str(uuid.uuid4())
    club = a.put(f"/clubs/{club_id}", {"kind": "book", "name": "E2E Contract Readers",
                                       "description": "Contract probes only.", "expected_version": 0}).ok()["club"]
    ctx.update(club=club_id, club_version=club.get("version", 1))
    found = a.get("/clubs/titles", params={"kind": "book", "q": "E2E Fixture Novel"}).ok()["titles"]
    title = found[0] if found else a.put(f"/clubs/titles/{uuid.uuid4()}", {
        "kind": "book", "title": "E2E Fixture Novel", "creator": "QA Automation", "release_year": 2001}).ok()["title"]
    ctx["title"] = title["id"]
    selection = a.put(f"/clubs/{club_id}/selections/{ctx['monday']}", {"title_id": title["id"]}).ok()["selection"]
    ctx["selection"] = selection["id"]
    b.post(f"/clubs/{club_id}/membership", {"action": "join"}).ok()
    club_post = str(uuid.uuid4())
    a.put(f"/clubs/{club_id}/posts/{club_post}", {"selection_id": selection["id"], "body": "Contract probe post",
                                                   "has_spoilers": False}).ok()
    ctx["club_post"] = club_post
    list_id = str(uuid.uuid4())
    saved_list = a.put(f"/clubs/lists/{list_id}", {"name": "E2E contract list", "kind": "book",
                                                   "audience": "private", "expected_version": 0}).ok()["list"]
    ctx.update(list=list_id, list_version=saved_list.get("version", 1))
    a.put(f"/clubs/lists/{list_id}/items/{title['id']}", {}).ok()
    cleanup.append(lambda: a.delete(f"/clubs/lists/{list_id}", {"expected_version": ctx["list_version"]}))
    review_id = str(uuid.uuid4())
    review = a.put(f"/clubs/titles/{title['id']}/reviews/{review_id}", {
        "rating": 4, "body": "Quiet and warm.", "audience": "community", "has_spoilers": False,
        "expected_version": 0}).ok()["review"]
    ctx.update(review=review_id, review_version=review["version"])
    cleanup.append(lambda: a.delete(f"/clubs/reviews/{review_id}", {"expected_version": ctx["review_version"]}))

    # Photo themes: a's entry in the first open theme.
    themes = a.get("/themes").ok()["themes"]
    theme = next((t for t in themes if t["status"] == "active" and not t["my_entry_id"]), themes[0])
    ctx["theme"] = theme["id"]
    entry_id = str(uuid.uuid4())
    entry = a.api.call("PUT", f"/themes/{theme['id']}/entries/{entry_id}",
                       files={"image": ("e2e.png", png_bytes((0x55, 0x22, 0x99)), "image/png"),
                              "caption": (None, "E2E contract light"), "alt_text": (None, "A purple square")})
    ctx["entry"] = entry_id if entry.status in (200, 201) else str(uuid.uuid4())
    if entry.status in (200, 201):
        cleanup.append(lambda: a.delete(f"/themes/{theme['id']}/entries/{entry_id}"))

    # Profile stories version and one of the three Bengaluru circles.
    ctx["stories_version"] = a.get(f"/profile/{a.user_id}/stories").ok().get("version", 0)
    ctx["circle"] = "circle-blr-books"

    # An ended call, a mini-activity session and a coffee poll between a and b.
    call = a.post("/calls/start", {"match_id": match_id, "initiator_user_id": a.user_id,
                                   "recipient_user_id": b.user_id}).ok()["session"]
    a.post(f"/calls/{call['id']}/end", {"ended_by_user_id": a.user_id}).ok()
    ctx["call"] = call["id"]
    ctx["session"] = a.post("/activities/sessions/start", {
        "match_id": match_id, "initiator_user_id": a.user_id, "participant_user_id": b.user_id,
        "activity_type": "co_op_prompt"}).ok()["session"]["id"]
    poll = a.post("/engagement/group-coffee-polls", {
        "creator_user_id": a.user_id, "participant_user_ids": [b.user_id],
        "options": [{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"}]}).ok()["poll"]
    ctx.update(poll=poll["id"], poll_option=poll["options"][0]["id"])

    # A pending coin checkout (sandbox provider; nothing is paid) and an introducer invite.
    package = a.get("/billing/coin-packages").ok()["packages"][0]
    ctx["checkout"] = a.post("/billing/checkout", {"kind": "coin_package",
                                                   "package_id": package["id"]}).ok()["checkout"]["id"]
    ctx["invite_code"] = a.post("/introducer/invites", {}).ok()["code"]
    cleanup.append(lambda: a.delete("/introducer/invites"))

    return {"a": a, "b": b, "c": c, "anon": Api(), "intro": make_introducer("cat_i"), "ctx": ctx}


_RESULTS: dict[tuple, tuple] = {}


def _fill(value, ctx):
    if isinstance(value, str):
        if value.startswith("{") and value.endswith("}") and value[1:-1] in ctx and \
                not isinstance(ctx[value[1:-1]], str):
            return ctx[value[1:-1]]  # numeric placeholders such as {post_version}
        out = value
        while "{uuid}" in out:
            out = out.replace("{uuid}", str(uuid.uuid4()), 1)
        for key, val in ctx.items():
            out = out.replace("{" + key + "}", str(val))
        return out
    if isinstance(value, dict):
        return {k: _fill(v, ctx) for k, v in value.items()}
    if isinstance(value, list):
        return [_fill(v, ctx) for v in value]
    return value


def _run(world, probe: Probe):
    key = (probe.actor, probe.method, probe.path, jsonlib.dumps(probe.body, sort_keys=True, default=str),
           probe.multipart)
    if key in _RESULTS:
        return _RESULTS[key]
    ctx = world["ctx"]
    caller = world[probe.actor]
    api = caller if isinstance(caller, Api) else caller.api
    path = _fill(probe.path, ctx)
    params = None
    if "?" in path:
        path, query = path.split("?", 1)
        params = dict(part.split("=", 1) for part in query.split("&"))
    if probe.multipart:
        form = _fill(probe.body, ctx) if probe.body is not None else \
            {"caption": "contract probe", "alt_text": "probe"}
        files = {name: (None, str(value)) for name, value in form.items()}
        if probe.multipart == "audio":
            files["audio"] = ("hello.wav", wav_bytes(), "audio/wav")
        else:
            files[probe.multipart] = ("probe.png", png_bytes((7, 7, 7)), "image/png")
        response = api.call(probe.method, path, params=params, files=files)
    else:
        response = api.call(probe.method, path, json=_fill(probe.body, ctx), params=params)
    _RESULTS[key] = (response.status, response.text[:240], f"{probe.method} {path}", response.body)
    return _RESULTS[key]


def _check(world, endpoint):
    probes = ENDPOINT_PROBES.get(endpoint)
    assert probes, f"no contract probes defined for {endpoint}"
    failures = []
    for probe in probes:
        status, text, sent, body = _run(world, probe)
        if status >= 500 or status not in probe.expect:
            failures.append(f"[{probe.label}] {probe.actor}: {sent} -> {status}, expected "
                            f"{sorted(probe.expect)}: {text}")
            continue
        if probe.gated_flag and status == 403:
            ok = isinstance(body, dict) and body.get("error_code") == "FEATURE_DISABLED" \
                and body.get("feature_flag") == probe.gated_flag
            if not ok:
                failures.append(f"[{probe.label}] {sent} -> 403 without FEATURE_DISABLED/{probe.gated_flag}: {text}")
    return failures


def _flags(world):
    return {f["key"]: f["value_bool"] for f in world["a"].get("/config/flags").ok()["flags"]}


@pytest.mark.parametrize("case_id", [
    pytest.param(case_id, id=case_id, marks=pytest.mark.case(case_id)) for case_id in CASE_ENDPOINTS
])
def test_api_contract_error_paths(world, case_id):
    """Unauthenticated, foreign, malformed and unknown requests get the documented 4xx, never a 5xx."""
    flags = _flags(world) if "support" in case_id or "city_pilot" in case_id or case_id == "site.contact.api_contract" else {}
    if flags.get("support_ticketing_enabled") and ("support" in case_id or case_id == "site.contact.api_contract"):
        pytest.skip("support_ticketing_enabled is on: the gated-off contract does not apply (see test_21 happy paths)")
    if flags.get("city_pilot_enabled") and "city_pilot" in case_id:
        pytest.skip("city_pilot_enabled is on: the closed-pilot contract does not apply")
    failures = []
    for endpoint in CASE_ENDPOINTS[case_id]:
        failures += _check(world, endpoint)
    assert not failures, "\n".join(failures)


def test_every_catalog_api_contract_case_is_in_the_matrix():
    """Coverage guard: a new api_contract case in the catalog must get probes here."""
    if not os.path.exists(CATALOG):
        pytest.skip("qa/catalog/feature_catalog.json is not present in this checkout")
    with open(CATALOG, encoding="utf-8") as handle:
        catalog = jsonlib.load(handle)
    ids = {case["id"] for feature in catalog["features"] for case in feature["cases"]
           if case["id"].endswith(".api_contract")}
    assert ids - set(CASE_ENDPOINTS) == set(), f"catalog cases without contract probes: {sorted(ids - set(CASE_ENDPOINTS))}"
    stale = set(CASE_ENDPOINTS) - ids
    assert not stale, f"matrix cases no longer in the catalog: {sorted(stale)}"
    missing = {e for eps in CASE_ENDPOINTS.values() for e in eps} - set(ENDPOINT_PROBES)
    assert not missing, f"endpoints without probes: {sorted(missing)}"


# --- known product defects found by the matrix -------------------------------------------
# Each entry asserts the CORRECT behaviour and is a strict xfail until the backend is
# fixed (backend/ is owned by another workstream). When a fix lands the param XPASSes,
# strict mode fails it, and the probe moves into ENDPOINT_PROBES above.

@dataclass(frozen=True)
class Defect:
    id: str
    endpoint: str   # route key; the case marks are every catalog case behind it
    reason: str
    probe: Probe
    check: object = None  # optional callable(status, body) -> bool for body-level contracts
    extra_cases: tuple = ()


def _cases_for(endpoint, extra=()):
    ids = [cid for cid, eps in CASE_ENDPOINTS.items() if endpoint in eps]
    return tuple(ids) + tuple(extra)


C01 = ("API-C01: a malformed or unknown id is not validated and reaches Postgres (uuid cast / foreign key); "
       "the failure surfaces as 502/503 instead of 400/404")
C02 = "API-C02: request validation errors are not mapped and surface as 502 UPSTREAM_SERVICE_ERROR instead of 400"
NEW_GRAD_DECIDE = "graduation.graduation_banner.graduation_decline.api_contract_route"
NEW_GRAD_WITHDRAW = "graduation.graduation_banner.graduation_withdraw.api_contract_route"
NEW_VOUCH_DECIDE = "friends.friends.friends_vouch_hide_x_decide.api_contract_route"
NEW_INTRO_DECIDE = "friends.friends.friends_intro_decline_x_decide.api_contract_route"
NEW_POLL_READ = "engagement.group_coffee_polls.vote.api_contract_route"

KNOWN_DEFECTS = [
    # API-C01: 5xx for malformed / unknown ids
    Defect("API-C01", "POST /swipe", C01,
           bad("POST", "/swipe", {"user_id": "{me}", "target_user_id": "not-a-uuid", "is_like": True}, (400, 404),
               label="malformed like target")),
    Defect("API-C01", "POST /notifications/{userID}/{notificationID}/read", C01,
           malformed("POST", "/notifications/{me}/not-a-uuid/read", {})),
    Defect("API-C01", "DELETE /notifications/{userID}/{notificationID}", C01,
           malformed("DELETE", "/notifications/{me}/not-a-uuid")),
    Defect("API-C01", "DELETE /notifications/{userID}/devices/{deviceID}", C01,
           malformed("DELETE", "/notifications/{me}/devices/not-a-uuid")),
    Defect("API-C01", "POST /social/friends/{friendID}/channel", C01,
           unknown("POST", "/social/friends/{uuid}/channel", {}, DENY)),
    Defect("API-C01", "GET /users/{userID}/trust-badges", C01,
           malformed("GET", "/users/not-a-uuid/trust-badges", actor="c")),
    Defect("API-C01", "DELETE /profile/{userID}/photos/{photoID}", C01,
           malformed("DELETE", "/profile/{me}/photos/not-a-uuid")),
    Defect("API-C01", "POST /calls/{callID}/end", C01,
           malformed("POST", "/calls/not-a-uuid/end", {"ended_by_user_id": "{me}"})),
    Defect("API-C01", "POST /activities/sessions/{sessionID}/submit", C01,
           malformed("POST", "/activities/sessions/not-a-uuid/submit", {"user_id": "{me}", "responses": ["a"]})),
    Defect("API-C01", "GET /activities/sessions/{sessionID}/summary", C01,
           malformed("GET", "/activities/sessions/not-a-uuid/summary")),
    Defect("API-C01", "GET /matches/{matchID}/plans/{planID}/sharing", C01,
           malformed("GET", "/matches/{match}/plans/not-a-uuid/sharing")),
    Defect("API-C01", "POST /matches/{matchID}/plans/{planID}/sharing", C01,
           malformed("POST", "/matches/{match}/plans/not-a-uuid/sharing", {"contact_ids": [], "expected_version": 0})),
    Defect("API-C01", "POST /engagement/voice-icebreakers/{icebreakerID}/send", C01,
           P("unknown icebreaker", "a", "POST", "/engagement/voice-icebreakers/{uuid}/send",
             {"sender_user_id": "{me}", "transcript": "Hello from the contract suite", "duration_seconds": "25"},
             (403, 404), multipart="audio")),
    Defect("API-C01", "POST /matches/{matchID}/graduation/{graduationID}/decision", C01,
           malformed("POST", "/matches/{match}/graduation/not-a-uuid/decision", {"decision": "decline"}, actor="b"),
           extra_cases=(NEW_GRAD_DECIDE,)),
    Defect("API-C01", "POST /matches/{matchID}/graduation/{graduationID}/withdraw", C01,
           malformed("POST", "/matches/{match}/graduation/not-a-uuid/withdraw", {}),
           extra_cases=(NEW_GRAD_WITHDRAW,)),
    Defect("API-C01", "POST /friends/{userID}/vouches/{vouchID}/decision", C01,
           malformed("POST", "/friends/{me}/vouches/not-a-uuid/decision", {"decision": "hide"}),
           extra_cases=(NEW_VOUCH_DECIDE,)),
    Defect("API-C01", "POST /friends/{userID}/intros/{introID}/decision", C01,
           malformed("POST", "/friends/{me}/intros/not-a-uuid/decision", {"decision": "decline"}),
           extra_cases=(NEW_INTRO_DECIDE,)),

    # API-C02: validation errors surface as 502
    Defect("API-C02", "POST /calls/start", C02,
           bad("POST", "/calls/start", {"initiator_user_id": "{me}", "recipient_user_id": "{peer}"},
               label="missing match_id")),
    Defect("API-C02", "POST /calls/start", C02,
           bad("POST", "/calls/start", {"match_id": "{match}", "initiator_user_id": "{me}",
                                        "recipient_user_id": "{me}"}, label="call yourself")),
    Defect("API-C02", "POST /activities/sessions/start", C02,
           bad("POST", "/activities/sessions/start", {"match_id": "{match}", "initiator_user_id": "{me}",
                                                      "participant_user_id": "{peer}", "activity_type": "karaoke"},
               label="unknown activity type")),
    Defect("API-C02", "POST /activities/sessions/start", C02,
           bad("POST", "/activities/sessions/start", {"match_id": "{match}", "initiator_user_id": "{me}"},
               label="missing participant")),
    Defect("API-C02", "POST /activities/sessions/{sessionID}/submit", C02,
           bad("POST", "/activities/sessions/{session}/submit", {"user_id": "{me}", "responses": []},
               label="no responses")),
    Defect("API-C02", "POST /safety/sos", C02,
           bad("POST", "/safety/sos", {"user_id": "{me}", "emergency_level": "apocalyptic"},
               label="unknown emergency level")),

    # API-C03..C05: other members' data readable (IDOR)
    Defect("API-C03", "GET /activities/sessions/{sessionID}/summary",
           "API-C03: any signed-in member can read any mini-activity session summary, including "
           "responses_by_user (no participant check in getActivitySessionSummary)",
           foreign("GET", "/activities/sessions/{session}/summary")),
    Defect("API-C04", "GET /engagement/circles/{circleID}/challenge",
           "API-C04: GET /engagement/circles/{id}/challenge?user_id=<other> returns that member's private "
           "challenge entry (the query user_id is not checked against the caller)",
           P("another member's entry via ?user_id", "c", "GET",
             "/engagement/circles/circle-blr-music/challenge?user_id={me}", None, (200, 403)),
           check=lambda status, body: status == 403 or "user_entry" not in jsonlib.dumps(body)),
    Defect("API-C05", "GET /engagement/group-coffee-polls",
           "API-C05: GET /engagement/group-coffee-polls?user_id=<other> lists another member's coffee polls "
           "(user_id is not checked against the caller)",
           P("another member's polls via ?user_id", "c", "GET", "/engagement/group-coffee-polls?user_id={me}",
             None, (200, 403)),
           check=lambda status, body: status == 403 or not (body or {}).get("polls")),
    Defect("API-C05", "GET /engagement/group-coffee-polls/{pollID}",
           "API-C05: GET /engagement/group-coffee-polls/{id} has no participant check",
           foreign("GET", "/engagement/group-coffee-polls/{poll}"), extra_cases=(NEW_POLL_READ,)),

    # API-C06: the other member of the match is not validated
    Defect("API-C06", "POST /engagement/match-nudges/send",
           "API-C06: a match nudge can be addressed to a counterparty_user_id outside the match",
           bad("POST", "/engagement/match-nudges/send", {"match_id": "{match}", "user_id": "{me}",
                                                         "counterparty_user_id": "{outsider}"}, (400, 403, 409),
               label="counterparty outside the match")),
    Defect("API-C06", "POST /engagement/voice-icebreakers/start",
           "API-C06: a voice icebreaker can be addressed to a receiver_user_id outside the match",
           bad("POST", "/engagement/voice-icebreakers/start", {"match_id": "{match}", "sender_user_id": "{me}",
                                                               "receiver_user_id": "{outsider}"}, (400, 403, 409),
               label="receiver outside the match")),
    Defect("API-C06", "POST /activities/sessions/start",
           "API-C06: a mini-activity session can name a participant_user_id outside the match",
           bad("POST", "/activities/sessions/start", {"match_id": "{match}", "initiator_user_id": "{me}",
                                                      "participant_user_id": "{outsider}",
                                                      "activity_type": "co_op_prompt"}, (400, 403, 409),
               label="participant outside the match")),

    # API-C07: emergency contacts report success for ids that matched nothing
    Defect("API-C07", "PUT /emergency-contacts/{userID}/{contactID}",
           "API-C07: PUT /emergency-contacts/{me}/{unknown id} answers 200 although nothing was updated",
           unknown("PUT", "/emergency-contacts/{me}/{uuid}", {"name": "Mum", "phone_number": "+447700900006"})),
    Defect("API-C07", "DELETE /emergency-contacts/{userID}/{contactID}",
           "API-C07: DELETE /emergency-contacts/{me}/not-a-uuid answers 200 with an EMPTY contacts list, so the "
           "app believes every contact is gone",
           malformed("DELETE", "/emergency-contacts/{me}/not-a-uuid")),

    # API-C08: terms consent recorded from a non-boolean
    Defect("API-C08", "PATCH /users/{userID}/agreements/terms",
           "API-C08: PATCH terms with a non-boolean accepted (e.g. \"no\") records acceptance (defaults to true)",
           bad("PATCH", "/users/{me}/agreements/terms", {"accepted": "no", "terms_version": "v1"},
               label="accepted is not a boolean")),

    # API-C09: wrong-typed or unknown values silently accepted
    Defect("API-C09", "PATCH /settings/{userID}",
           "API-C09: PATCH /settings stores any theme string (e.g. neon:rave) instead of rejecting it",
           bad("PATCH", "/settings/{me}", {"theme": "neon:rave"}, label="unknown theme")),
    Defect("API-C09", "PATCH /settings/{userID}",
           "API-C09: PATCH /settings ignores a wrong-typed privacy toggle and answers 200",
           bad("PATCH", "/settings/{me}", {"show_age": "yes"}, label="toggle is not a boolean")),
    Defect("API-C09", "PATCH /profile/{userID}/draft",
           "API-C09: PATCH /profile/{me}/draft ignores a wrong-typed field and answers 200",
           bad("PATCH", "/profile/{me}/draft", {"min_age_years": "old"}, label="age is not a number")),
    Defect("API-C09", "POST /profile/views",
           "API-C09: POST /profile/views accepts a malformed viewed_user_id (200 success, queued write)",
           bad("POST", "/profile/views", {"viewer_user_id": "{me}", "viewed_user_id": "not-a-uuid"},
               label="malformed viewed member")),
    Defect("API-C09", "DELETE /friends/{userID}/{friendUserID}",
           "API-C09: DELETE /friends/{me}/not-a-uuid answers 200 success",
           malformed("DELETE", "/friends/{me}/not-a-uuid")),

    # API-C10: likes to members that do not exist
    Defect("API-C10", "POST /swipe",
           "API-C10: POST /swipe accepts a like for a well-formed but unknown member id (200 accepted:true)",
           bad("POST", "/swipe", {"user_id": "{me}", "target_user_id": "{uuid}", "is_like": True}, (400, 404),
               label="unknown like target")),
    Defect("API-C10", "POST /swipe",
           "API-C10: POST /swipe without a target_user_id answers 200 accepted:true",
           bad("POST", "/swipe", {"user_id": "{me}", "is_like": True}, (400,), label="missing like target")),
]


def _defect_param(defect):
    return pytest.param(defect, id=f"{defect.id}:{defect.probe.method} {defect.probe.path} [{defect.probe.label}]",
                        marks=[pytest.mark.known_defect(defect.id),
                               pytest.mark.case(*_cases_for(defect.endpoint, defect.extra_cases)),
                               pytest.mark.xfail(strict=True, reason=defect.reason)])


@pytest.mark.parametrize("defect", [_defect_param(d) for d in KNOWN_DEFECTS])
def test_known_contract_defects(world, defect):
    """The documented 4xx contract for probes that the backend currently gets wrong."""
    if defect.endpoint == "GET /engagement/circles/{circleID}/challenge":
        a = world["a"]
        a.post("/engagement/circles/circle-blr-music/challenge/entries",
               {"user_id": a.user_id, "entry_text": "Private: the song I hum when nervous."})
    status, text, sent, body = _run(world, defect.probe)
    if defect.check is not None:
        assert status < 500 and defect.check(status, body), f"{sent} -> {status}: {text}"
    else:
        assert status < 500 and status in defect.probe.expect, (
            f"{sent} -> {status}, expected {sorted(defect.probe.expect)}: {text}")
