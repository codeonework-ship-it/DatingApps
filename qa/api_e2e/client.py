"""Thin HTTP client and member factory for the API end-to-end suite.

Every test member is created through the public signup journey (signup ->
bootstrap -> terms -> draft -> photos -> complete), exactly like
backend/scripts/verify_signup_workflow.sh, so the suite exercises the same
path a real member takes. Members are named ``e2e_<run>_<role>`` and are
deactivated + scheduled for deletion at session end.
"""

from __future__ import annotations

import binascii
import os
import struct
import time
import uuid
import zlib
from dataclasses import dataclass, field
from typing import Any

import requests

API_BASE = os.getenv("E2E_API_BASE_URL", "http://127.0.0.1:18080/v1").rstrip("/")
# Local test-only credential shared with backend/scripts/verify_signup_workflow.sh.
PASSWORD = os.getenv("E2E_TEST_PASSWORD", "Password123!")
TIMEOUT = float(os.getenv("E2E_HTTP_TIMEOUT", "20"))
# The gateway rate-limits per IP (GATEWAY_RATE_LIMIT_REQUESTS, default 120/s) and
# every local client (emulator, web app, Playwright, this suite) shares 127.0.0.1.
# Pace requests so the suite does not starve the others, and honour 429s.
MIN_INTERVAL = float(os.getenv("E2E_MIN_REQUEST_INTERVAL", "0.02"))
MAX_429_RETRIES = int(os.getenv("E2E_MAX_429_RETRIES", "5"))
STATS = {"requests": 0, "throttled": 0}
_last_request = [0.0]
RUN_ID = os.getenv("E2E_RUN_ID", time.strftime("%m%d%H%M%S"))


class ApiError(AssertionError):
    pass


@dataclass
class Resp:
    status: int
    body: Any
    text: str
    method: str
    url: str
    headers: dict = field(default_factory=dict)

    def ok(self, *allowed: int) -> "Resp":
        allowed = allowed or (200, 201, 202, 204)
        if self.status not in allowed:
            raise ApiError(
                f"{self.method} {self.url} -> {self.status}, expected {allowed}: {self.text[:800]}"
            )
        return self

    def __getitem__(self, key: str) -> Any:
        if not isinstance(self.body, dict):
            raise ApiError(f"{self.method} {self.url}: body is not an object: {self.text[:400]}")
        return self.body[key]

    def get(self, key: str, default: Any = None) -> Any:
        return self.body.get(key, default) if isinstance(self.body, dict) else default


class Api:
    def __init__(self, token: str | None = None, base: str = API_BASE):
        self.base = base
        self.token = token
        self.session = requests.Session()

    def call(self, method: str, path: str, json: Any = None, params: dict | None = None,
             files: Any = None, headers: dict | None = None, auth: bool = True,
             data: Any = None) -> Resp:
        url = path if path.startswith("http") else f"{self.base}/{path.lstrip('/')}"
        hdrs = {"Accept": "application/json", "X-Correlation-ID": f"e2e-{uuid.uuid4()}",
                "X-Client-Platform": "api-e2e"}
        if auth and self.token:
            hdrs["Authorization"] = f"Bearer {self.token}"
        if headers:
            hdrs.update(headers)
        for attempt in range(MAX_429_RETRIES + 1):
            wait = MIN_INTERVAL - (time.monotonic() - _last_request[0])
            if wait > 0:
                time.sleep(wait)
            _last_request[0] = time.monotonic()
            STATS["requests"] += 1
            r = self.session.request(method, url, json=json, params=params, files=files,
                                     data=data, headers=hdrs, timeout=TIMEOUT)
            if r.status_code != 429 or attempt == MAX_429_RETRIES:
                break
            STATS["throttled"] += 1
            time.sleep(float(r.headers.get("Retry-After") or 1))
        try:
            body = r.json() if r.content else None
        except ValueError:
            body = r.text
        return Resp(r.status_code, body, r.text, method, url, r.headers)

    def get(self, path, **kw):
        return self.call("GET", path, **kw)

    def post(self, path, json=None, **kw):
        return self.call("POST", path, json=json if json is not None else {}, **kw)

    def put(self, path, json=None, **kw):
        return self.call("PUT", path, json=json if json is not None else {}, **kw)

    def patch(self, path, json=None, **kw):
        return self.call("PATCH", path, json=json if json is not None else {}, **kw)

    def delete(self, path, json=None, **kw):
        return self.call("DELETE", path, json=json, **kw)


@dataclass
class Member:
    username: str
    user_id: str
    token: str
    gender: str
    name: str
    api: Api = field(repr=False)

    # Convenience pass-throughs so tests read like a member's actions.
    def get(self, path, **kw):
        return self.api.get(path, **kw)

    def post(self, path, json=None, **kw):
        return self.api.post(path, json, **kw)

    def put(self, path, json=None, **kw):
        return self.api.put(path, json, **kw)

    def patch(self, path, json=None, **kw):
        return self.api.patch(path, json, **kw)

    def delete(self, path, json=None, **kw):
        return self.api.delete(path, json, **kw)


def png_bytes(rgb: tuple[int, int, int] = (0x31, 0x78, 0xC6), size: int = 320) -> bytes:
    """A small solid-colour PNG, same as the signup verification script."""
    raw = b"".join(b"\x00" + bytes(rgb) * size for _ in range(size))

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF))

    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def create_member(role: str, gender: str = "F", seeking: str = "M",
                  dob: str = "1994-08-03", city_bio: str | None = None) -> Member:
    username = f"e2e_{RUN_ID}_{role}"[:30].lower()
    name = f"E2E {role.replace('_', ' ').title()}"
    anon = Api()
    signup = anon.post("/auth/signup", {"username": username, "password": PASSWORD}).ok(200, 201)
    user_id, token = signup["user_id"], signup["access_token"]
    api = Api(token)
    api.post("/auth/signup/bootstrap", {"user_id": user_id, "username": username, "name": name,
                                        "date_of_birth": dob, "gender": gender}).ok()
    api.patch(f"/users/{user_id}/agreements/terms", {"accepted": True, "terms_version": "v1"}).ok()
    api.patch(f"/profile/{user_id}/draft", {
        "bio": city_bio or "Curious architect who enjoys hiking and thoughtful conversations.",
        "seeking_genders": [seeking], "min_age_years": 21, "max_age_years": 60,
        "max_distance_km": 200, "intent_tags": ["long_term"],
    }).ok()
    for n, rgb in enumerate([(0x31, 0x78, 0xC6), (0xC6, 0x55, 0x31)], start=1):
        api.call("POST", f"/profile/{user_id}/photos",
                 files={"image": (f"photo-{n}.png", png_bytes(rgb), "image/png")}).ok()
    api.post(f"/profile/{user_id}/complete").ok()
    return Member(username=username, user_id=user_id, token=token, gender=gender, name=name, api=api)


def login(username: str, password: str = PASSWORD) -> Resp:
    return Api().post("/auth/login", {"username": username, "password": password})


def retire_member(member: Member) -> None:
    """Best-effort cleanup: schedule deletion (grace period) and deactivate."""
    try:
        member.post(f"/account/{member.user_id}/deletion", {"reason": "api e2e cleanup"})
        member.post(f"/account/{member.user_id}/deactivate", {"reason": "api e2e cleanup"})
    except Exception:  # noqa: BLE001 - cleanup must never fail the run
        pass


def items(body: Any, *keys: str) -> list:
    if isinstance(body, list):
        return body
    if not isinstance(body, dict):
        return []
    for key in keys or ("items", "results", "data"):
        value = body.get(key)
        if isinstance(value, list):
            return value
    return []


def wait_for(fn, timeout: float = 8.0, interval: float = 0.4):
    """Poll ``fn`` until it returns a truthy value (async side effects)."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        last = fn()
        if last:
            return last
        time.sleep(interval)
    return last
