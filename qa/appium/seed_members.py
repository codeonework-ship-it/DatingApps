"""Synthetic counterpart members for social-feature device specs.

A counterpart is a fully completed local test member created through the
project's own `backend/scripts/verify_signup_workflow.sh`, then signed in
through the API so a spec can act as "the other person" (send a friend
request, accept a group invitation, host a room, post a message) while the
device member is driven through the UI.

The password comes from the same script (`SIGNUP_TEST_PASSWORD` or the
script's local default) and is never printed.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from api_client import ApiClient
from config import CONFIG

REPO_ROOT = Path(__file__).resolve().parents[2]
SIGNUP_SCRIPT = REPO_ROOT / "backend" / "scripts" / "verify_signup_workflow.sh"


def signup_script_password() -> str:
    explicit = os.getenv("SIGNUP_TEST_PASSWORD", "")
    if explicit:
        return explicit
    text = SIGNUP_SCRIPT.read_text(encoding="utf-8")
    match = re.search(r'^password="\$\{SIGNUP_TEST_PASSWORD:-(.*)\}"$', text, re.MULTILINE)
    if not match:
        raise AssertionError("Could not read the local default password from verify_signup_workflow.sh")
    return match.group(1)


@dataclass
class Member:
    username: str
    user_id: str
    name: str
    api: ApiClient


def unique_username(role: str) -> str:
    # Usernames are capped at 30 characters; keep the role short.
    return f"and_{role}_{time.time_ns() % 10_000_000_000:010d}"[:30]


def create_member(role: str, display_name: str | None = None) -> Member:
    # The local gateway occasionally answers 502 while a service restarts;
    # retry the whole signup with a fresh username rather than fail the spec.
    for attempt in range(3):
        username = unique_username(role)
        env = dict(os.environ, SIGNUP_TEST_USERNAME=username)
        result = subprocess.run(
            ["bash", str(SIGNUP_SCRIPT)],
            env=env,
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
        if result.returncode == 0:
            break
        time.sleep(3 * (attempt + 1))
    if result.returncode != 0:
        raise AssertionError(
            f"verify_signup_workflow.sh failed for {username}: "
            f"{(result.stderr or result.stdout)[-800:]}"
        )
    payload = json.loads(result.stdout[result.stdout.index("{"):])
    user_id = str(payload["user_id"])
    api = ApiClient(CONFIG.api_base_url)
    api.authenticate(username, signup_script_password())
    name = "Workflow QA"
    if display_name:
        # A draft edit is published by completing the profile again.
        api.patch(f"/profile/{user_id}/draft", {"name": display_name}).require_status(200)
        api.post(f"/profile/{user_id}/complete", {}).require_status(200)
        name = display_name
    return Member(username=username, user_id=user_id, name=name, api=api)


def create_deck_candidate(display_name: str) -> Member:
    """A completed male member seeking women, so he is a discovery candidate
    for the device member (a woman seeking men; the signup script itself
    always creates women)."""
    member = create_member("dk")
    member.api.patch(
        f"/profile/{member.user_id}/draft",
        {"gender": "M", "seeking_genders": ["F"], "name": display_name},
    ).require_status(200)
    member.api.post(f"/profile/{member.user_id}/complete", {}).require_status(200)
    member.name = display_name
    return member


def login_member(username: str) -> Member:
    api = ApiClient(CONFIG.api_base_url)
    api.authenticate(username, signup_script_password())
    user_id = api.authenticated_user_id or ""
    return Member(username=username, user_id=user_id, name="", api=api)


def make_friends(a: Member, b: Member) -> None:
    """a asks b, b accepts, through the public friend API."""
    a.api.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "search"}).require_status(200, 201)
    b.api.post(
        f"/friends/{b.user_id}/{a.user_id}/decision", {"decision": "accept"}
    ).require_status(200, 201)


def friend_status(member: Member, other_id: str) -> str:
    response = member.api.get(f"/friends/{member.user_id}").require_status(200)
    for row in response.body.get("friends", []):
        if row.get("friend_user_id") == other_id:
            direction = row.get("direction") or ""
            return f"{row.get('status')}:{direction}" if direction else str(row.get("status"))
    return "none"


def remove_friend(member: Member, other_id: str) -> None:
    member.api.delete(f"/friends/{member.user_id}/{other_id}").require_status(200, 204, 404)
