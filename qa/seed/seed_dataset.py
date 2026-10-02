#!/usr/bin/env python3
"""Deterministic QA dataset for QA Lab, created through the public API only.

    .venv/bin/python qa/seed/seed_dataset.py ensure            # create or top up today's dataset
    .venv/bin/python qa/seed/seed_dataset.py ensure --fresh    # new prefix (new members)
    .venv/bin/python qa/seed/seed_dataset.py status            # what the manifest says
    .venv/bin/python qa/seed/seed_dataset.py needs             # catalog seed_needs -> seeded?
    .venv/bin/python qa/seed/seed_dataset.py retire --prior    # retire members of earlier prefixes
    .venv/bin/python qa/seed/seed_dataset.py retire --prefix P # retire one prefix

Members are named ``qal_<prefix>_<role>`` (prefix defaults to today's yymmdd,
or QA_SEED_PREFIX). Every member goes through the real signup journey (same as
qa/api_e2e/client.py create_member) and uses that module's local *test*
password; it is never written to the manifest, logs or reports.

Idempotent: each step is recorded in the manifest and skipped on a re-run
with the same prefix; client-generated ids (chapters, clubs, lists, entries,
messages) are uuid5 values derived from the prefix, so a replayed PUT is a
no-op conflict rather than a duplicate.

Writes qa/results/qa_lab/seed_manifest.json (ids + usernames, no secrets) and a
copy per prefix under qa/results/qa_lab/seed_history/. ``retire`` schedules
deletion and deactivates members through the account API (the same calls as
client.retire_member); it never deletes rows directly.

Off by default (they change shared local config other suites assert on):
support tickets and city pilot need feature flags an operator must enable.
Pass --enable-flags to let the seeder turn them on with the local operator.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import time
import traceback
import uuid
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "qa" / "api_e2e"))

import requests  # noqa: E402

from client import API_BASE, PASSWORD, Api, Member, png_bytes  # noqa: E402

RESULTS = Path(os.environ.get("QA_LAB_RESULTS_DIR") or ROOT / "qa" / "results" / "qa_lab")
MANIFEST = RESULTS / "seed_manifest.json"
HISTORY = RESULTS / "seed_history"
CATALOG = ROOT / "qa" / "catalog" / "feature_catalog.json"
NS = uuid.UUID("6f3c1f1e-8d7a-4c39-9a51-0c6a5e0d9a11")

# role -> (gender, seeking, description)
PERSONAS = {
    "qa": ("F", "M", "primary QA member: complete profile, 3 photos, stories, chapters, wall photo, showcase on"),
    "deck1": ("M", "F", "undecided Discover candidate"),
    "deck2": ("M", "F", "undecided Discover candidate"),
    "deck3": ("M", "F", "undecided Discover candidate"),
    "spot": ("M", "F", "gold (sandbox) subscriber, so Spotlight ranks him first"),
    "liker1": ("M", "F", "liked the QA member (Liked you)"),
    "liker2": ("M", "F", "liked the QA member (Liked you)"),
    "passed": ("M", "F", "QA member passed him"),
    "liked": ("M", "F", "QA member liked him, no match yet"),
    "match": ("M", "F", "match with chat history, a free gift and an accepted date plan past its start"),
    "match2": ("M", "F", "new match, no messages"),
    "grad_a": ("F", "M", "graduated with 'grad' (graduation pauses her Discover, so it is not the QA member)"),
    "grad": ("M", "F", "match both members graduated (with grad_a)"),
    "friend": ("F", "M", "accepted friend: friend chat, owns a group the QA member joined, vouched, introducer"),
    "pal": ("M", "F", "friend of 'friend'; introduced to the QA member (intro pending)"),
    "friend_in": ("F", "M", "sent the QA member a friend request (pending incoming)"),
    "friend_out": ("F", "M", "QA member sent her a friend request (pending outgoing)"),
    "writer": ("F", "M", "writer with 2 community chapters the QA member follows"),
    "blocked": ("M", "F", "reported the QA member, then was blocked by her (appeal possible)"),
    "reportable": ("M", "F", "untouched member for report/block tests"),
    "verify": ("F", "M", "pending ID verification (manual review)"),
    "disposable": ("F", "M", "for destructive tests (delete account, etc.)"),
}

# catalog seed_needs category -> steps that provide it ([] = needs nothing)
NEEDS = {
    "signed-in member with completed profile": ["members"],
    "member with complete profile": ["members"],
    "member with settings defaults": ["members"],
    "member": ["members"], "existing member": ["members"], "two members": ["members"],
    "free member": ["members"], "member on free plan": ["members"],
    "existing member credentials from qa seed": ["members"],
    "disposable member": ["members"], "unverified member": ["members"],
    "two compatible members": ["members"],
    "operator account": ["operator"], "operator": ["operator"],
    "blocked user": ["safety"], "a blocked member": ["safety"], "appeal": ["safety"],
    "a reportable member": ["members"], "moderator queue": ["safety"],
    "records for the target (user/ticket/report)": ["safety"],
    ">=2 published chapters, 1 draft, 1 writer to follow": ["chapters", "follow"],
    "member with 3+ photos, prompts, chapters and wall photos (public + opted-in)": ["photos", "stories", "chapters", "theme_entry", "showcase"],
    "active daily prompt, challenges, coffee polls, rooms, nudges": ["daily_prompt", "coffee_poll", "room"],
    "club with posts": ["club"], "titles in lists": ["title_list"],
    "wallet with coins": ["wallet"], "wallet coins": ["wallet"],
    "seeded BFF data": ["members", "swipes", "friends"],
    ">=3 undecided discovery candidates": ["members"],
    ">=1 spotlight profile": ["spotlight"], "member with >=3 spotlight profiles": ["spotlight"],
    "matched + unmatched spotlight members": ["spotlight", "swipes"],
    ">=1 member who liked the seeded member": ["swipes"], "member with >=1 liker": ["swipes"],
    ">=1 passed profile": ["swipes"],
    "member with deck, spotlight, Today set, >=1 liker, >=1 liked and >=1 passed profile": ["swipes", "spotlight", "today_set"],
    "one candidate already matched (for Message)": ["swipes"],
    "member with 1 friend, 1 pending incoming and 1 outgoing request": ["friends"],
    "member with friend": ["friends"], "friend": ["friends"], ">=1 friend for fan-out": ["friends"],
    "introducer account": ["introducer_account"],
    "member owning one group and member of another": ["groups"], "pending invite": ["groups"],
    "match with an accepted date plan": ["date_plan"], "plan past its time (for debrief)": ["date_plan"],
    "curated Today set": ["today_set"], "today wall posts": ["wall_reactions"],
    "introductions": ["intro"], "stories": ["stories"],
    "match with unlocked chat and message history": ["chat"], "match with chat": ["chat"],
    "gift catalog active": ["gift"], "gift catalog": ["gift"], "daily message limit state": ["chat"],
    "member with >=2 matches (one with messages, one new)": ["swipes", "chat"],
    "match eligible for call/plan/graduation": ["swipes"], "match": ["swipes"],
    "match that both members graduated": ["graduation"],
    "fresh device (no session)": [], "fresh device": [], "none (public page)": [],
    "member with recovery code": ["recovery_code"],
    "member with 1 open and 1 resolved ticket": ["support_tickets"],
    "sandbox/Stripe test provider": ["wallet"], "sandbox provider": ["wallet"], "coin packages active": ["wallet"],
    "active theme with entries and comments": ["theme_entry"],
    "city pilot with experiences": ["city_pilot"],
    "match with first-chapter studio unlocked": ["first_chapter"],
    "friend pair / room / group membership with messages": ["friend_chat", "room", "groups"],
    "emergency contacts": ["emergency_contacts"],
    "member with pending verification": ["verification"],
    "test ID photo fixture": ["fixtures"], "test photo fixture": ["fixtures"],
    "match with call history": ["call_history"], "call permissions granted": ["call_permissions"],
    "unread notifications of each category": ["notifications"],
}
NOT_SEEDABLE = {
    "introducer_account": "introducer accounts are a separate account kind with their own signup; tests create one",
    "first_chapter": "First Chapter Studio unlock has no public seeding call; tests unlock it through the match flow",
    "call_history": "calls need two live realtime clients (WebRTC); not seedable through the REST API",
    "call_permissions": "a device permission (camera/microphone), granted on the emulator, not data",
}


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def uid5(prefix: str, name: str) -> str:
    return str(uuid.uuid5(NS, f"{prefix}:{name}"))


class StepSkip(Exception):
    pass


class Seeder:
    def __init__(self, prefix: str, enable_flags: bool = False, log=print):
        self.prefix = prefix
        self.enable_flags = enable_flags
        self.log = log
        self.m: dict[str, Member] = {}
        self.manifest = self._load()

    # ------------------------------------------------------------ manifest
    def _load(self) -> dict:
        path = HISTORY / f"{self.prefix}.json"
        for p in (path, MANIFEST):
            if p.exists():
                try:
                    data = json.loads(p.read_text())
                    if data.get("prefix") == self.prefix:
                        return data
                except ValueError:
                    pass
        return {"prefix": self.prefix, "created_at": now_iso(), "api_base": API_BASE,
                "password": "not stored: the local test password from qa/api_e2e/client.py (E2E_TEST_PASSWORD)",
                "members": {}, "data": {}, "steps": {}}

    def save(self) -> None:
        RESULTS.mkdir(parents=True, exist_ok=True)
        HISTORY.mkdir(parents=True, exist_ok=True)
        self.manifest["updated_at"] = now_iso()
        self.manifest["seed_needs"] = needs_report(self.manifest)
        text = json.dumps(self.manifest, indent=1, ensure_ascii=False)
        assert PASSWORD not in text, "refusing to write a password into the manifest"
        MANIFEST.write_text(text)
        (HISTORY / f"{self.prefix}.json").write_text(text)

    @property
    def data(self) -> dict:
        return self.manifest["data"]

    def step(self, name: str, fn, force: bool = False) -> None:
        prev = self.manifest["steps"].get(name, {})
        if prev.get("status") == "ok" and not force:
            self.log(f"  = {name}: already seeded")
            return
        t0 = time.time()
        try:
            detail = fn() or ""
            self.manifest["steps"][name] = {"status": "ok", "detail": str(detail)[:300], "at": now_iso()}
            self.log(f"  + {name}: ok {detail if detail else ''} ({time.time() - t0:.1f}s)")
        except StepSkip as e:
            self.manifest["steps"][name] = {"status": "skipped", "detail": str(e)[:300], "at": now_iso()}
            self.log(f"  - {name}: skipped ({e})")
        except Exception as e:  # noqa: BLE001 - one failed step must not stop the seed
            msg = f"{type(e).__name__}: {str(e)[:400]}"
            self.manifest["steps"][name] = {"status": "failed", "detail": msg, "at": now_iso()}
            self.log(f"  ! {name}: FAILED {msg}")
            if os.environ.get("QA_SEED_DEBUG"):
                traceback.print_exc()
        self.save()

    # ------------------------------------------------------------ members
    def username(self, role: str) -> str:
        return f"qal_{self.prefix}_{role}".lower()[:30]

    def _login(self, username: str) -> Member | None:
        r = Api().post("/auth/login", {"username": username, "password": PASSWORD})
        if r.status != 200 or not r.get("access_token"):
            return None
        return Member(username=username, user_id=r["user_id"], token=r["access_token"], gender="", name="", api=Api(r["access_token"]))

    def _create(self, role: str, gender: str, seeking: str) -> Member:
        username = self.username(role)
        name = f"QA Lab {role.replace('_', ' ').title()}"
        anon = Api()
        signup = anon.post("/auth/signup", {"username": username, "password": PASSWORD})
        if signup.status not in (200, 201):
            existing = self._login(username)
            if existing is None:
                signup.ok(200, 201)
            member = existing
        else:
            member = Member(username=username, user_id=signup["user_id"], token=signup["access_token"],
                            gender=gender, name=name, api=Api(signup["access_token"]))
        api, user_id = member.api, member.user_id
        # Each call tolerates "already done" so a half-created member is completed.
        api.post("/auth/signup/bootstrap", {"user_id": user_id, "username": username, "name": name,
                                            "date_of_birth": "1994-08-03" if gender == "F" else "1991-03-14",
                                            "gender": gender})
        api.patch(f"/users/{user_id}/agreements/terms", {"accepted": True, "terms_version": "v1"})
        api.patch(f"/profile/{user_id}/draft", {
            "bio": f"QA Lab {role}: curious architect who enjoys hiking and thoughtful conversations.",
            "seeking_genders": [seeking], "min_age_years": 21, "max_age_years": 60,
            "max_distance_km": 200, "intent_tags": ["long_term"]})
        for n, rgb in enumerate([(0x31, 0x78, 0xC6), (0xC6, 0x55, 0x31)], start=1):
            api.call("POST", f"/profile/{user_id}/photos", files={"image": (f"photo-{n}.png", png_bytes(rgb), "image/png")})
        api.post(f"/profile/{user_id}/complete").ok(200, 201, 202, 204, 409)
        member.gender, member.name = gender, name
        return member

    def ensure_members(self) -> str:
        created = 0
        for role, (gender, seeking, desc) in PERSONAS.items():
            known = self.manifest["members"].get(role)
            member = self._login(self.username(role)) if known else None
            if member is None:
                member = self._create(role, gender, seeking)
                created += 1
            member.gender, member.name = gender, f"QA Lab {role.replace('_', ' ').title()}"
            self.m[role] = member
            self.manifest["members"][role] = {"username": member.username, "user_id": member.user_id,
                                              "gender": gender, "seeking": seeking, "role": desc}
        self.save()
        return f"{len(self.m)} members ({created} new)"

    # ------------------------------------------------------------ helpers
    def match_id(self, a: Member, b: Member) -> str | None:
        body = a.get(f"/matches/{a.user_id}").ok().body or {}
        for m in body.get("matches") or []:
            other = m.get("userId") or m.get("user_id") or m.get("matched_user_id") or m.get("other_user_id")
            if other == b.user_id:
                return m.get("matchId") or m.get("match_id") or m.get("id")
        return None

    def ensure_match(self, a: Member, b: Member) -> str:
        mid = self.match_id(a, b)
        if mid:
            return mid
        a.post("/swipe", {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True})
        r = b.post("/swipe", {"user_id": b.user_id, "target_user_id": a.user_id, "is_like": True})
        mid = (r.get("match_id") if r.status == 200 else None) or self.match_id(a, b)
        if not mid:
            raise RuntimeError(f"no match between {a.username} and {b.username}: {r.status} {r.text[:200]}")
        return mid

    def friend_status(self, a: Member, b: Member) -> str | None:
        for f in (a.get(f"/friends/{a.user_id}").ok().body or {}).get("friends") or []:
            if f.get("friend_user_id") == b.user_id:
                return f.get("status")
        return None

    def befriend(self, a: Member, b: Member) -> None:
        if self.friend_status(a, b) == "accepted":
            return
        if self.friend_status(a, b) is None:
            a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "search"}).ok(200, 201, 409)
        b.post(f"/friends/{b.user_id}/{a.user_id}/decision", {"decision": "accept"}).ok(200, 201, 409)

    # ------------------------------------------------------------ steps
    def s_photos(self):
        qa = self.m["qa"]
        r = qa.api.call("POST", f"/profile/{qa.user_id}/photos", files={"image": ("photo-3.png", png_bytes((0x55, 0x31, 0xC6)), "image/png")})
        r.ok(200, 201)
        return "3rd photo uploaded"

    def s_stories(self):
        qa = self.m["qa"]
        base = f"/profile/{qa.user_id}/stories"
        cur = qa.get(base).ok()
        if cur.get("stories"):
            return "stories already published"
        prompts = sorted(cur["prompts"])
        qa.put(base, {"stories": [{"prompt_id": prompts[0], "text": "Small kindnesses, daily."},
                                  {"prompt_id": prompts[1], "text": "A long walk by the sea, then soup."}],
                      "published": True, "expected_version": cur.get("version") or 0}).ok()
        return "2 stories"

    def s_showcase(self):
        qa = self.m["qa"]
        qa.put(f"/profile/{qa.user_id}/showcase/consent", {"visible": True},
               headers={"Idempotency-Key": uid5(self.prefix, "showcase")}).ok()
        return "showcase visible"

    def s_swipes(self):
        qa, m = self.m["qa"], self.m
        for role in ("liker1", "liker2"):
            m[role].post("/swipe", {"user_id": m[role].user_id, "target_user_id": qa.user_id, "is_like": True}).ok(200, 201, 409)
        qa.post("/swipe", {"user_id": qa.user_id, "target_user_id": m["passed"].user_id, "is_like": False}).ok(200, 201, 409)
        qa.post("/swipe", {"user_id": qa.user_id, "target_user_id": m["liked"].user_id, "is_like": True}).ok(200, 201, 409)
        mids = {role: self.ensure_match(qa, m[role]) for role in ("match", "match2")}
        mids["grad"] = self.ensure_match(m["grad_a"], m["grad"])
        self.data["matches"] = mids
        return f"2 likers, 1 passed, 1 liked, matches {sorted(mids)}"

    def s_chat(self):
        qa, partner = self.m["qa"], self.m["match"]
        mid = self.data["matches"]["match"]
        msgs = (qa.get(f"/chat/{mid}/messages", params={"limit": 50}).ok().body or {}).get("messages") or []
        if len(msgs) >= 4:
            return f"{len(msgs)} messages already"
        script = [(qa, "Hi! Your trail photos are lovely."), (partner, "Thank you! Do you hike often?"),
                  (qa, "Most weekends, usually somewhere coastal."), (partner, "Coffee before a walk sometime?")]
        for who, text in script[len(msgs):]:
            who.post(f"/chat/{mid}/messages", {"text": text, "sender_id": who.user_id}).ok()
        return "4 messages"

    def s_gift(self):
        partner = self.m["match"]
        mid = self.data["matches"]["match"]
        gifts = partner.get("/chat/gifts").ok()
        self.data["gift_catalog_count"] = gifts.get("count")
        r = partner.post(f"/chat/{mid}/gifts/send", {"gift_id": "rose_red_single", "sender_user_id": partner.user_id,
                                                     "message_text": "A rose for the trail"},
                         headers={"Idempotency-Key": uid5(self.prefix, "gift")})
        if r.status == 429:
            return "free gift already sent today"
        r.ok(200, 201)
        self.data["gift_send_id"] = (r.get("gift_send") or {}).get("id")
        return "free rose sent to the QA member"

    def s_date_plan(self):
        qa, partner = self.m["qa"], self.m["match"]
        mid = self.data["matches"]["match"]
        base = f"/matches/{mid}/plans"
        now = dt.datetime.now(dt.timezone.utc)
        iso = lambda t: t.replace(microsecond=0).isoformat().replace("+00:00", "Z")  # noqa: E731
        r = qa.post(base, {"window_start": iso(now - dt.timedelta(minutes=50)), "window_end": iso(now + dt.timedelta(hours=2)),
                           "venue_category": "coffee", "venue_name": "QA Lab Corner Café", "note": "Seeded plan"})
        if r.status == 409:
            return "a plan is already open on this match"
        r.ok(201)
        plan = r["plan"]
        partner.post(f"{base}/{plan['id']}/decision", {"decision": "accept", "expected_version": plan.get("lock_version", 0)}).ok()
        self.data["date_plan_id"] = plan["id"]
        return "accepted plan whose window started 50 min ago (debrief allowed)"

    def s_graduation(self):
        # Graduating pauses Discover for both members, so the pair is grad_a + grad.
        qa, partner = self.m["grad_a"], self.m["grad"]
        mid = self.data["matches"]["grad"]
        base = f"/matches/{mid}/graduation"
        cur = qa.get(base)
        if cur.status == 200 and cur.get("graduated") is True:
            return "already graduated"
        r = qa.post(base, {"note": "Closing our apps together", "share_with_friends": False})
        r.ok(201)
        gid = r["graduation"]["id"]
        partner.post(f"{base}/{gid}/decision", {"decision": "confirm"}).ok()
        self.data["graduation_id"] = gid
        return "both confirmed"

    def s_friends(self):
        qa, m = self.m["qa"], self.m
        self.befriend(qa, m["friend"])
        self.befriend(m["friend"], m["pal"])
        if self.friend_status(qa, m["friend_in"]) is None:
            m["friend_in"].post(f"/friends/{m['friend_in'].user_id}", {"friend_user_id": qa.user_id, "source": "profile"}).ok(200, 201, 409)
        if self.friend_status(qa, m["friend_out"]) is None:
            qa.post(f"/friends/{qa.user_id}", {"friend_user_id": m["friend_out"].user_id, "source": "search"}).ok(200, 201, 409)
        return "1 friend, 1 incoming, 1 outgoing; friend<->pal"

    def s_friend_chat(self):
        qa, fr = self.m["qa"], self.m["friend"]
        ch = qa.post(f"/social/friends/{fr.user_id}/channel").ok()["channel"]["id"]
        self.data["friend_channel_id"] = ch
        for who, n, body in ((qa, 1, "Hey you! Coffee this week?"), (fr, 2, "Yes please. Thursday?")):
            who.post(f"/social/channels/{ch}/messages", {"client_message_id": uid5(self.prefix, f"fc{n}"), "body": body}).ok(200, 201, 409)
        return "2 friend messages"

    def s_groups(self):
        qa, fr = self.m["qa"], self.m["friend"]
        g = self.data.setdefault("groups", {})
        if "owned" not in g:
            r = qa.post("/engagement/groups", {"kind": "private", "name": f"QA Lab {self.prefix} circle",
                                               "description": "Seeded group the QA member owns", "invitee_user_ids": [fr.user_id]}).ok(201)
            g["owned"] = r["group"]["id"]
            g["owned_channel_id"] = r["group"].get("channel_id")
            fr.post(f"/engagement/groups/{g['owned']}/invites/respond", {"decision": "accept"}).ok()
        if "member_of" not in g:
            r = fr.post("/engagement/groups", {"kind": "private", "name": f"QA Lab {self.prefix} friends",
                                               "description": "Seeded group the QA member joined", "invitee_user_ids": [qa.user_id]}).ok(201)
            g["member_of"] = r["group"]["id"]
            qa.post(f"/engagement/groups/{g['member_of']}/invites/respond", {"decision": "accept"}).ok()
        if "pending_invite" not in g:
            r = fr.post("/engagement/groups", {"kind": "private", "name": f"QA Lab {self.prefix} invite",
                                               "description": "QA member has a pending invite here", "invitee_user_ids": [qa.user_id]}).ok(201)
            g["pending_invite"] = r["group"]["id"]
        self.save()
        if g.get("owned_channel_id"):
            qa.post(f"/social/channels/{g['owned_channel_id']}/messages",
                    {"client_message_id": uid5(self.prefix, "group1"), "body": "Welcome to the circle!"}).ok(200, 201, 409)
        return "owns 1, member of 1, 1 pending invite, 1 group message"

    def s_room(self):
        qa, fr = self.m["qa"], self.m["friend"]
        rooms = (qa.get("/rooms").ok().body or {}).get("rooms") or []
        room = next((r for r in rooms if r.get("id") == self.data.get("room_id")), None)
        if room is None:
            room = fr.post("/rooms", {"title": f"QA Lab {self.prefix} lounge", "description": "Seeded room",
                                      "category": "talk", "duration_minutes": 60, "capacity": 10}).ok(201)["room"]
            self.data["room_id"] = room["id"]
        joined = qa.post(f"/rooms/{room['id']}/join", {"user_id": qa.user_id}).ok()
        ch = joined.get("channel_id") or room.get("channel_id")
        if ch:
            qa.post(f"/social/channels/{ch}/messages", {"client_message_id": str(uuid.uuid4()), "body": "Hello room!"}).ok(200, 201)
        return "room live for ~60 min (re-created on each seed)"

    def _post(self, author: Member, key: str, title: str, audience: str, featuring: bool = False) -> dict:
        pid = uid5(self.prefix, key)
        r = author.put(f"/blog/posts/{pid}", {"title": title, "body": f"{title}: a short story about mountain trails and listening more than talking.",
                                              "audience": audience, "topic": "feelings", "expected_version": 0,
                                              **({"allow_featuring": True} if featuring else {})})
        if r.status in (200, 201):
            return r["post"]
        got = author.get(f"/blog/posts/{pid}")
        if got.status == 200:
            return got.get("post") or {"id": pid}
        r.ok()
        return {"id": pid}

    def s_chapters(self):
        qa, w = self.m["qa"], self.m["writer"]
        ch = self.data.setdefault("chapters", {})
        ch["qa_community"] = self._post(qa, "qa_c", "QA Lab community chapter", "community", True)["id"]
        ch["qa_friends"] = self._post(qa, "qa_f", "QA Lab friends chapter", "friends")["id"]
        ch["qa_draft"] = self._post(qa, "qa_d", "QA Lab draft chapter", "private")["id"]
        ch["writer_1"] = self._post(w, "w_1", "QA Lab writer: first light", "community", True)["id"]
        ch["writer_2"] = self._post(w, "w_2", "QA Lab writer: second wind", "community", True)["id"]
        return "QA: community + friends + private draft; writer: 2 community"

    def s_follow(self):
        qa, w = self.m["qa"], self.m["writer"]
        qa.put(f"/blog/authors/{w.user_id}/subscription").ok()
        return "QA member follows writer"

    def s_wall_reactions(self):
        w = self.m["writer"]
        post = self.data["chapters"]["writer_1"]
        for role in ("qa", "friend", "pal"):
            self.m[role].put(f"/blog/posts/{post}/like", {"reaction": "love"}).ok(200, 201, 409)
        cid = uid5(self.prefix, "wall_comment")
        c = self.m["qa"].put(f"/blog/posts/{post}/comments/{cid}", {"body": "This made my morning."})
        if c.status in (200, 201):
            w.post(f"/blog/posts/{post}/comments/{cid}/decision", {"decision": "approve"}).ok(200, 201, 409)
        return "writer chapter: 3 reactions + 1 approved comment (wall tier with BLOG_WALL_TIERS=3:1:50)"

    def s_theme_entry(self):
        qa, fr = self.m["qa"], self.m["friend"]
        themes = qa.get("/themes").ok()
        if not themes.get("eligible"):
            raise StepSkip("QA member is not theme-eligible")
        mine = next((t for t in themes["themes"] if t.get("my_entry_id")), None)
        if mine:
            tid, eid = mine["id"], mine["my_entry_id"]
        else:
            theme = next((t for t in themes["themes"] if t.get("status") == "active"), None)
            if not theme:
                raise StepSkip("no active photo theme (an operator creates one in the console)")
            tid, eid = theme["id"], uid5(self.prefix, "theme_entry")
            r = qa.api.call("PUT", f"/themes/{tid}/entries/{eid}", headers={"Idempotency-Key": uid5(self.prefix, "theme_key")},
                            files={"image": ("qa.png", png_bytes((0x22, 0x99, 0x55)), "image/png"),
                                   "caption": (None, "QA Lab: green hour"),
                                   "alt_text": (None, "A green square standing in for a park at dusk"),
                                   "allow_featuring": (None, "true")})
            r.ok(200, 201)
        fr.put(f"/themes/{tid}/entries/{eid}/like", {"reaction": "love"}).ok(200, 201, 409)
        cid = uid5(self.prefix, "theme_comment")
        c = fr.put(f"/themes/{tid}/entries/{eid}/comments/{cid}", {"body": "Gorgeous light!"})
        if c.status in (200, 201):
            qa.post(f"/themes/{tid}/entries/{eid}/comments/{cid}/decision", {"decision": "approve"}).ok(200, 201, 409)
        self.data["theme"] = {"theme_id": tid, "entry_id": eid}
        return "wall photo entered (featuring on), liked and commented by friend"

    def s_vouch(self):
        qa, fr = self.m["qa"], self.m["friend"]
        r = fr.post(f"/friends/{fr.user_id}/vouches", {"for_user_id": qa.user_id, "text": "Kind, curious and always on time for coffee."})
        if r.status == 409:
            return "vouch already written"
        r.ok(200, 201)
        vid = r["vouch"]["id"]
        qa.post(f"/friends/{qa.user_id}/vouches/{vid}/decision", {"decision": "approve"}).ok()
        self.data["vouch_id"] = vid
        return "friend vouched, QA approved"

    def _allow_intros(self, member: Member) -> None:
        base = f"/account/{member.user_id}/dating-preferences"
        cur = member.get(base).ok()["preferences"]
        if cur.get("allow_friend_intros"):
            return
        member.put(base, {**{k: cur[k] for k in ("intent", "pace", "activities", "share_pace", "share_availability", "availability")},
                          "allow_friend_intros": True, "version": cur["version"]}).ok()

    def s_intro(self):
        qa, fr, pal = self.m["qa"], self.m["friend"], self.m["pal"]
        for who in (qa, pal):
            self._allow_intros(who)
        r = fr.post(f"/friends/{fr.user_id}/intros", {"first_user_id": qa.user_id, "second_user_id": pal.user_id,
                                                      "message": "You both love coastal walks!"})
        if r.status == 409:
            return "intro already open"
        r.ok(201)
        self.data["intro_id"] = r["intro"]["id"]
        return "friend introduced QA member to pal (pending)"

    def s_daily_prompt(self):
        qa = self.m["qa"]
        r = qa.get(f"/engagement/daily-prompt/{qa.user_id}").ok()
        prompt = ((r.get("daily_prompt") or {}).get("prompt") or {}).get("id")
        if not prompt:
            raise StepSkip("no daily prompt today")
        a = qa.post(f"/engagement/daily-prompt/{qa.user_id}/answer", {"prompt_id": prompt, "answer_text": "A slow breakfast and a long walk."},
                    headers={"Idempotency-Key": uid5(self.prefix, "prompt" + dt.date.today().isoformat())})
        if a.status in (409, 422):
            return f"answer not accepted today ({a.status})"
        a.ok(200, 201)
        return "answered today's prompt"

    def s_coffee_poll(self):
        qa, fr = self.m["qa"], self.m["friend"]
        deadline = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=24)).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        r = qa.post("/engagement/group-coffee-polls", {"creator_user_id": qa.user_id, "participant_user_ids": [fr.user_id],
                                                       "options": [{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Harbour"},
                                                                   {"day": "Sunday", "time_window": "15:00-17:00", "neighborhood": "Old Town"}],
                                                       "deadline_at": deadline})
        r.ok(200, 201)
        self.data["coffee_poll_id"] = (r.get("poll") or {}).get("id") or r.get("id")
        return "coffee poll with friend"

    def _title(self, member: Member) -> dict:
        found = member.get("/clubs/titles", params={"kind": "book", "q": "QA Lab Fixture Novel"}).ok()["titles"]
        if found:
            return found[0]
        return member.put(f"/clubs/titles/{uid5(self.prefix, 'title')}", {"kind": "book", "title": "QA Lab Fixture Novel",
                                                                           "creator": "QA Automation", "release_year": 2001}).ok()["title"]

    def s_club(self):
        qa, fr = self.m["qa"], self.m["friend"]
        cid = uid5(self.prefix, "club")
        r = qa.put(f"/clubs/{cid}", {"kind": "book", "name": f"QA Lab {self.prefix} readers", "description": "One chapter a week.",
                                     "expected_version": 0})
        if r.status not in (200, 201, 409):
            r.ok()
        title = self._title(qa)
        today = dt.date.today()
        monday = today - dt.timedelta(days=today.weekday())
        qa.put(f"/clubs/{cid}/selections/{monday.isoformat()}", {"title_id": title["id"], "note": "Start with part one"}).ok(200, 201, 409)
        joined = fr.post(f"/clubs/{cid}/membership", {"action": "join"}).ok(200, 201, 409)
        club = joined.get("club") or qa.get(f"/clubs/{cid}").ok().get("club") or {}
        sel = (club.get("current_selection") or {}).get("id")
        if sel:
            fr.put(f"/clubs/{cid}/posts/{uid5(self.prefix, 'club_post')}", {"selection_id": sel, "body": "Loving the opening chapter",
                                                                           "has_spoilers": False}).ok(200, 201, 409)
        self.data["club"] = {"club_id": cid, "title_id": title["id"]}
        return "club with this week's pick and a member post"

    def s_title_list(self):
        qa = self.m["qa"]
        lid = uid5(self.prefix, "list")
        r = qa.put(f"/clubs/lists/{lid}", {"name": "QA Lab favourites", "kind": "book", "audience": "friends", "expected_version": 0})
        if r.status not in (200, 201, 409):
            r.ok()
        title = self._title(qa)
        qa.put(f"/clubs/lists/{lid}/items/{title['id']}", {"note": "Read it twice"}).ok(200, 201, 409)
        self.data["title_list_id"] = lid
        return "list with 1 title"

    def _sandbox_checkout(self, member: Member, body: dict, key: str) -> None:
        r = member.post("/billing/checkout", body, headers={"Idempotency-Key": uid5(self.prefix, key)})
        r.ok(200, 201)
        url = (r.get("checkout") or {}).get("checkout_url") or ""
        session_id = urlparse(url).path.rstrip("/").rsplit("/", 1)[-1]
        if not session_id:
            raise RuntimeError("checkout returned no session url")
        # The sandbox provider's published test card: no real payment is made.
        paid = requests.post(f"{API_BASE}/billing/sandbox/checkout/{session_id}",
                             data={"card_number": "4242424242424242", "exp_month": "12", "exp_year": "2035", "cvc": "123", "name": "QA Lab Sandbox"},
                             allow_redirects=False, timeout=20)
        if paid.status_code not in (200, 303):
            raise RuntimeError(f"sandbox pay -> {paid.status_code}")

    def s_wallet(self):
        qa = self.m["qa"]
        packages = qa.get("/billing/coin-packages").ok()
        self.data["billing_mode"] = packages.get("mode")
        if packages.get("mode") != "sandbox":
            raise StepSkip(f"billing provider is {packages.get('mode')!r}, not the sandbox; never touching a real provider")
        bal = qa.get(f"/wallet/{qa.user_id}/coins").ok()["wallet"]["coin_balance"]
        if bal <= 0:
            package = min(packages["packages"], key=lambda p: p["total_coins"])
            self._sandbox_checkout(qa, {"kind": "coin_package", "package_id": package["id"]}, "coins")
            bal = qa.get(f"/wallet/{qa.user_id}/coins").ok()["wallet"]["coin_balance"]
        self.data["coin_balance"] = bal
        return f"{bal} coins (sandbox)"

    def s_spotlight(self):
        spot, qa = self.m["spot"], self.m["qa"]
        ent = spot.get(f"/billing/entitlements/{spot.user_id}")
        plan = (ent.body or {}).get("plan") or (ent.body or {}).get("plan_code") if ent.status == 200 else None
        if not (isinstance(plan, str) and plan not in ("free", "")):
            if (qa.get("/billing/coin-packages").ok().get("mode")) != "sandbox":
                raise StepSkip("billing provider is not the sandbox")
            plans = Api().get("/billing/plans").ok().body or {}
            codes = [p.get("code") or p.get("id") for p in plans.get("plans") or []]
            code = next((c for c in codes if c and "gold" in str(c).lower()), None) or next((c for c in codes if c and c != "free"), None)
            if not code:
                raise StepSkip("no paid plan in /billing/plans")
            self._sandbox_checkout(spot, {"plan_id": code, "billing_cycle": "monthly"}, "spot_plan")
        deck = qa.get(f"/discovery/{qa.user_id}", params={"mode": "spotlight", "limit": 50}).ok().body or {}
        profiles = deck.get("spotlight_profiles") or deck.get("candidates") or []
        ids = [p.get("user_id") or p.get("id") for p in profiles]
        self.data["spotlight_count"] = len(ids)
        self.data["spot_in_spotlight"] = spot.user_id in ids
        if not ids:
            raise RuntimeError("QA member sees no Spotlight profiles")
        return f"{len(ids)} spotlight profiles for QA (spot persona included: {spot.user_id in ids})"

    def s_today_set(self):
        qa = self.m["qa"]
        r = qa.get(f"/discovery/{qa.user_id}/today").ok()
        n = len(r.get("candidates") or [])
        self.data["today_set_count"] = n
        deck = qa.get(f"/discovery/{qa.user_id}", params={"limit": 100}).ok()
        self.data["deck_count"] = len(deck.get("candidates") or [])
        if n == 0:
            raise RuntimeError("empty Today set")
        return f"Today set {n}, deck {self.data['deck_count']}"

    def s_safety(self):
        qa, bl = self.m["qa"], self.m["blocked"]
        if not self.data.get("report_id"):
            r = bl.post("/safety/report", {"reporter_user_id": bl.user_id, "reported_user_id": qa.user_id, "reason": "spam",
                                           "description": "QA Lab seeded report (for the appeal flow)"}).ok(200, 201)
            self.data["report_id"] = (r.get("report") or {}).get("id")
        qa.post("/safety/block", {"user_id": qa.user_id, "blocked_user_id": bl.user_id}).ok(200, 201, 409)
        return "blocked persona reported QA (appealable); QA blocked him"

    def s_emergency_contacts(self):
        qa = self.m["qa"]
        base = f"/emergency-contacts/{qa.user_id}"
        if qa.get(base).ok().get("contacts"):
            return "contact exists"
        qa.post(base, {"name": "QA Lab Contact", "phone_number": "+447700900123"}).ok()
        return "1 contact"

    def s_recovery_code(self):
        qa = self.m["qa"]
        r = qa.post("/auth/recovery-code/rotate")
        r.ok()
        # The code is displayed once and is a credential: never stored or printed.
        return "recovery code rotated (not stored)"

    def s_verification(self):
        v = self.m["verify"]
        cur = v.get(f"/verification/{v.user_id}").ok()
        if str(cur.get("status") or "").lower() in ("pending", "manual_review", "submitted", "in_review"):
            return f"already {cur.get('status')}"
        r = v.api.call("POST", f"/verification/{v.user_id}/submit", files={
            "id_document": ("id.png", png_bytes((0x80, 0x80, 0x80)), "image/png"),
            "selfie": ("selfie.png", png_bytes((0xC0, 0xA0, 0x90)), "image/png")})
        r.ok(200, 201, 202)
        return f"submitted -> {r.get('status') or (r.get('verification') or {}).get('status')}"

    def s_notifications(self):
        qa = self.m["qa"]
        r = qa.get(f"/notifications/{qa.user_id}/unread-count").ok()
        n = r.get("unread_count") if r.get("unread_count") is not None else r.get("count")
        lst = qa.get(f"/notifications/{qa.user_id}", params={"limit": 100}).ok().get("notifications") or []
        kinds = sorted({x.get("event_type") for x in lst if x.get("event_type")})
        self.data["notifications"] = {"unread": n, "event_types": kinds}
        return f"{n} unread; types: {', '.join(kinds)[:200]}"

    def s_fixtures(self):
        d = RESULTS / "fixtures"
        d.mkdir(parents=True, exist_ok=True)
        (d / "photo.png").write_bytes(png_bytes((0x31, 0x78, 0xC6)))
        (d / "id_document.png").write_bytes(png_bytes((0x80, 0x80, 0x80)))
        (d / "selfie.png").write_bytes(png_bytes((0xC0, 0xA0, 0x90)))
        self.data["fixtures"] = {k: str((d / f"{k}.png").relative_to(ROOT)) for k in ("photo", "id_document", "selfie")}
        return "synthetic PNG fixtures"

    def s_operator(self):
        user = os.environ.get("LOCAL_OPERATOR_USERNAME", "local_control_admin")
        self.data["operator_username"] = user
        return f"operator account is {user} (backend/scripts/provision_local_operator.sh); password not stored"

    def _operator_api(self) -> Api:
        src = (ROOT / "backend/scripts/provision_local_operator.sh").read_text()
        default = re.search(r'password="\$\{LOCAL_OPERATOR_PASSWORD:-([^}]*)\}"', src)
        pw = os.environ.get("LOCAL_OPERATOR_PASSWORD") or (default.group(1) if default else "")
        r = Api().post("/auth/login", {"username": os.environ.get("LOCAL_OPERATOR_USERNAME", "local_control_admin"), "password": pw})
        if r.status != 200:
            raise StepSkip("local operator login failed; run backend/scripts/provision_local_operator.sh")
        return Api(r["access_token"])

    def s_support_tickets(self):
        if not self.enable_flags:
            raise StepSkip("support_ticketing_enabled is off by default and api_e2e asserts that; re-run with --enable-flags")
        op = self._operator_api()
        op.put("/admin/config/flags/support_ticketing_enabled", {"value_bool": True}).ok()
        qa = self.m["qa"]
        ids = []
        for n in (1, 2):
            t = qa.post("/support/tickets", {"category": "technical", "subject": f"QA Lab ticket {n}", "description": "Seeded ticket for QA Lab."}).ok(201)
            ids.append(t["ticket"]["id"])
        op.patch(f"/admin/support/tickets/{ids[1]}", {"status": "resolved"}).ok()
        self.data["support_tickets"] = {"open": ids[0], "resolved": ids[1]}
        return "1 open, 1 resolved"

    def s_city_pilot(self):
        if not self.enable_flags:
            raise StepSkip("city_pilot_enabled is off by default and api_e2e asserts that; re-run with --enable-flags")
        raise StepSkip("city pilot setup is operator-only (console > Growth > City pilot); not automated by the seeder yet")

    def s_not_seedable(self, name):
        raise StepSkip(NOT_SEEDABLE[name])

    # ------------------------------------------------------------ orchestration
    def run(self, only: list[str] | None = None, force: bool = False) -> dict:
        self.log(f"QA Lab seed: prefix {self.prefix} against {API_BASE}")
        self.step("members", self.ensure_members, force=True)
        if len(self.m) != len(PERSONAS):
            raise SystemExit("members could not be created; is the local stack up?")
        plan = [("fixtures", self.s_fixtures), ("operator", self.s_operator), ("photos", self.s_photos), ("stories", self.s_stories),
                ("showcase", self.s_showcase), ("swipes", self.s_swipes), ("chat", self.s_chat), ("gift", self.s_gift),
                ("date_plan", self.s_date_plan), ("graduation", self.s_graduation), ("friends", self.s_friends),
                ("friend_chat", self.s_friend_chat), ("groups", self.s_groups), ("room", self.s_room),
                ("chapters", self.s_chapters), ("follow", self.s_follow), ("wall_reactions", self.s_wall_reactions),
                ("theme_entry", self.s_theme_entry), ("vouch", self.s_vouch), ("intro", self.s_intro),
                ("daily_prompt", self.s_daily_prompt), ("coffee_poll", self.s_coffee_poll), ("club", self.s_club),
                ("title_list", self.s_title_list), ("wallet", self.s_wallet), ("spotlight", self.s_spotlight),
                ("today_set", self.s_today_set), ("safety", self.s_safety), ("emergency_contacts", self.s_emergency_contacts),
                ("recovery_code", self.s_recovery_code), ("verification", self.s_verification),
                ("support_tickets", self.s_support_tickets), ("city_pilot", self.s_city_pilot),
                ("notifications", self.s_notifications)]
        plan += [(n, (lambda n=n: self.s_not_seedable(n))) for n in NOT_SEEDABLE]
        always = {"room", "today_set", "spotlight", "notifications"}  # time-dependent: refresh every seed
        for name, fn in plan:
            if only and name not in only:
                continue
            self.step(name, fn, force=force or name in always)
        self.save()
        return self.manifest


def needs_report(manifest: dict) -> dict:
    steps = manifest.get("steps") or {}
    cats = set(NEEDS)
    try:
        cat = json.loads(CATALOG.read_text())
        for f in cat["features"]:
            for c in f["cases"]:
                cats.update(c.get("seed_needs") or [])
    except (OSError, ValueError, KeyError):
        pass
    out = {}
    for cat in sorted(cats):
        req = NEEDS.get(cat)
        if req is None:
            out[cat] = {"status": "unmapped", "steps": []}
            continue
        if not req:
            out[cat] = {"status": "n/a", "steps": []}
            continue
        st = [steps.get(s, {}).get("status", "missing") for s in req]
        status = "seeded" if all(s == "ok" for s in st) else ("partial" if any(s == "ok" for s in st) else "not_seeded")
        reasons = [f"{s}: {steps.get(s, {}).get('detail', 'not run')}" for s, v in zip(req, st) if v != "ok"]
        out[cat] = {"status": status, "steps": req, **({"why": reasons[:3]} if reasons else {})}
    return out


def default_prefix() -> str:
    """Today's yymmdd, skipping prefixes that were retired (yymmddb, yymmddc, ...)."""
    base = dt.datetime.now().strftime("%y%m%d")
    for suffix in [""] + [chr(c) for c in range(ord("b"), ord("z") + 1)]:
        h = HISTORY / f"{base}{suffix}.json"
        try:
            if not h.exists() or not json.loads(h.read_text()).get("retired_at"):
                return base + suffix
        except ValueError:
            return base + suffix
    return dt.datetime.now().strftime("%y%m%d%H%M")


def retire(prefix: str, log=print) -> int:
    path = HISTORY / f"{prefix}.json"
    data = json.loads(path.read_text()) if path.exists() else (json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {})
    if data.get("prefix") != prefix:
        log(f"no manifest for prefix {prefix}")
        return 1
    n = 0
    for role, info in (data.get("members") or {}).items():
        r = Api().post("/auth/login", {"username": info["username"], "password": PASSWORD})
        if r.status != 200:
            log(f"  {info['username']}: cannot sign in ({r.status}); already retired?")
            continue
        api = Api(r["access_token"])
        uid = r["user_id"]
        d = api.post(f"/account/{uid}/deletion", {"reason": "qa lab seed retire"})
        a = api.post(f"/account/{uid}/deactivate", {"reason": "qa lab seed retire"})
        log(f"  {info['username']}: deletion {d.status}, deactivate {a.status}")
        n += 1
    data["retired_at"] = now_iso()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False))
    log(f"retired {n} members of prefix {prefix}")
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("ensure", help="create or top up the dataset")
    e.add_argument("--prefix", default=os.environ.get("QA_SEED_PREFIX"))
    e.add_argument("--fresh", action="store_true", help="new prefix (yymmddHHMM) instead of today's")
    e.add_argument("--only", nargs="*", help="only these steps (members always run)")
    e.add_argument("--force", action="store_true", help="re-run steps already recorded as ok")
    e.add_argument("--enable-flags", action="store_true", help="let the seeder enable support/city-pilot flags with the local operator")
    e.add_argument("--json", action="store_true", help="print the manifest summary as JSON at the end")
    sub.add_parser("status")
    sub.add_parser("needs")
    r = sub.add_parser("retire")
    g = r.add_mutually_exclusive_group(required=True)
    g.add_argument("--prefix")
    g.add_argument("--prior", action="store_true", help="every prefix in seed_history except the current manifest's")
    a = ap.parse_args(argv)
    if a.cmd == "ensure":
        if not API_BASE.startswith(("http://127.0.0.1", "http://localhost", "http://[::1]")):
            raise SystemExit(f"refusing to seed a non-loopback API: {API_BASE}")
        prefix = a.prefix or (dt.datetime.now().strftime("%y%m%d%H%M") if a.fresh else default_prefix())
        if not re.fullmatch(r"[a-z0-9]{1,12}", prefix):
            raise SystemExit("prefix must be 1-12 lowercase letters/digits")
        s = Seeder(prefix, enable_flags=a.enable_flags)
        manifest = s.run(only=a.only, force=a.force)
        st = manifest["steps"]
        summary = {"prefix": prefix, "manifest": str(MANIFEST.relative_to(ROOT)) if MANIFEST.is_relative_to(ROOT) else str(MANIFEST),
                   "steps": {k: v["status"] for k, v in st.items()},
                   "needs": {k: v["status"] for k, v in manifest["seed_needs"].items()}}
        if a.json:
            print(json.dumps(summary))
        failed = [k for k, v in st.items() if v["status"] == "failed"]
        print(f"seed {prefix}: {sum(1 for v in st.values() if v['status'] == 'ok')} ok, "
              f"{sum(1 for v in st.values() if v['status'] == 'skipped')} skipped, {len(failed)} failed {failed if failed else ''}")
        return 0 if "members" not in failed else 1
    if a.cmd == "status":
        if not MANIFEST.exists():
            print("no manifest yet")
            return 1
        m = json.loads(MANIFEST.read_text())
        print(json.dumps({"prefix": m["prefix"], "updated_at": m.get("updated_at"),
                          "members": {k: v["username"] for k, v in m["members"].items()},
                          "steps": {k: v["status"] for k, v in m["steps"].items()}}, indent=1))
        return 0
    if a.cmd == "needs":
        m = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"steps": {}}
        rep = needs_report(m)
        for k, v in sorted(rep.items(), key=lambda kv: (kv[1]["status"], kv[0])):
            print(f"{v['status']:<11} {k}" + (f"  <- {'; '.join(v.get('why', []))[:160]}" if v.get("why") else ""))
        return 0
    if a.cmd == "retire":
        if a.prefix:
            return retire(a.prefix)
        current = json.loads(MANIFEST.read_text()).get("prefix") if MANIFEST.exists() else None
        rc = 0
        for p in sorted(HISTORY.glob("*.json")):
            data = json.loads(p.read_text())
            if data.get("prefix") != current and not data.get("retired_at"):
                rc |= retire(data["prefix"])
        return rc
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
