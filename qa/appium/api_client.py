from __future__ import annotations

import json
import uuid
from dataclasses import dataclass
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


@dataclass(frozen=True)
class ApiResponse:
    status: int
    body: Any
    headers: dict[str, str]
    raw: str

    def require_status(self, *allowed: int) -> "ApiResponse":
        if self.status not in allowed:
            raise AssertionError(
                f"Expected HTTP status {allowed}, got {self.status}. Body: {self.raw[:1000]}"
            )
        return self


class ApiClient:
    def __init__(self, base_url: str, timeout: int = 15):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.access_token: str | None = None
        self.authenticated_user_id: str | None = None

    def authenticate(self, username: str, password: str) -> ApiResponse:
        response = self.post(
            "/auth/login",
            {"username": username, "password": password},
        ).require_status(200)
        if not isinstance(response.body, dict):
            raise AssertionError(f"Login returned a non-object payload: {response.raw[:1000]}")
        token = str(response.body.get("access_token") or "").strip()
        user_id = str(response.body.get("user_id") or "").strip()
        if response.body.get("success") is not True or not token or not user_id:
            raise AssertionError(f"Login did not return a usable session: {response.raw[:1000]}")
        self.access_token = token
        self.authenticated_user_id = user_id
        return response

    def get(self, path: str, query: dict[str, Any] | None = None) -> ApiResponse:
        return self.request("GET", path, query=query)

    def post(
        self,
        path: str,
        body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> ApiResponse:
        return self.request("POST", path, body=body, headers=headers)

    def put(
        self,
        path: str,
        body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> ApiResponse:
        return self.request("PUT", path, body=body, headers=headers)

    def patch(
        self,
        path: str,
        body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> ApiResponse:
        return self.request("PATCH", path, body=body, headers=headers)

    def delete(
        self,
        path: str,
        body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> ApiResponse:
        return self.request("DELETE", path, body=body, headers=headers)

    def request(
        self,
        method: str,
        path: str,
        query: dict[str, Any] | None = None,
        body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> ApiResponse:
        url = self._url(path, query=query)
        payload = None if body is None else json.dumps(body).encode("utf-8")
        merged_headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Client-Platform": "appium-api-matrix",
            "X-Correlation-ID": f"appium-{uuid.uuid4()}",
        }
        if self.access_token:
            merged_headers["Authorization"] = f"Bearer {self.access_token}"
        if headers:
            merged_headers.update(headers)
        request = Request(url, data=payload, headers=merged_headers, method=method.upper())
        try:
            with urlopen(request, timeout=self.timeout) as response:  # noqa: S310 - local QA HTTP client
                raw = response.read().decode("utf-8", errors="replace")
                return ApiResponse(
                    status=response.status,
                    body=_decode_json(raw),
                    headers=dict(response.headers.items()),
                    raw=raw,
                )
        except HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace")
            return ApiResponse(
                status=exc.code,
                body=_decode_json(raw),
                headers=dict(exc.headers.items()),
                raw=raw,
            )
        except URLError as exc:
            raise AssertionError(f"API request failed for {method} {url}: {exc}") from exc

    def _url(self, path: str, query: dict[str, Any] | None = None) -> str:
        if path.startswith("http://") or path.startswith("https://"):
            url = path
        else:
            url = f"{self.base_url}/{path.lstrip('/')}"
        clean_query = {
            key: value
            for key, value in (query or {}).items()
            if value is not None and str(value).strip() != ""
        }
        if clean_query:
            return f"{url}?{urlencode(clean_query, doseq=True)}"
        return url


def _decode_json(raw: str) -> Any:
    if raw.strip() == "":
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def extract_items(payload: Any, *preferred_keys: str) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if not isinstance(payload, dict):
        return []
    keys = preferred_keys or (
        "audit",
        "badges",
        "candidates",
        "gifts",
        "items",
        "matches",
        "messages",
        "profiles",
        "results",
        "rooms",
        "sessions",
        "spotlight_profiles",
        "timeline",
        "data",
    )
    for key in keys:
        value = payload.get(key)
        if isinstance(value, list):
            return [item for item in value if isinstance(item, dict)]
    return []


def first_id(items: list[dict[str, Any]], *keys: str) -> str | None:
    candidate_keys = keys or ("id", "match_id", "user_id", "target_user_id")
    for item in items:
        for key in candidate_keys:
            value = item.get(key)
            if value:
                return str(value)
    return None


def pick_value(payload: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = payload.get(key)
        if value not in (None, ""):
            return value
    return None
