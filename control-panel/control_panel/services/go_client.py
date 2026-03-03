from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import requests
from django.conf import settings


@dataclass
class APIResult:
    ok: bool
    data: dict[str, Any]
    error: str = ""


class GoBFFClient:
    def __init__(self) -> None:
        self.api_base = settings.GO_API_BASE_URL
        self.health_base = settings.GO_HEALTH_BASE_URL
        self.timeout = settings.GO_API_TIMEOUT_SEC
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Content-Type": "application/json",
                "X-Admin-User": settings.GO_ADMIN_USER,
            }
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        payload: dict[str, Any] | None = None,
        use_health_base: bool = False,
    ) -> APIResult:
        base = self.health_base if use_health_base else self.api_base
        url = f"{base.rstrip('/')}/{path.lstrip('/')}"
        try:
            response = self.session.request(
                method=method,
                url=url,
                params=params,
                json=payload,
                timeout=self.timeout,
            )
            data = response.json() if response.content else {}
        except requests.RequestException as exc:
            return APIResult(ok=False, data={}, error=str(exc))
        except ValueError:
            return APIResult(ok=False, data={}, error="invalid JSON response from Go API")

        if response.status_code >= 400:
            message = str(data.get("error") or f"request failed with {response.status_code}")
            return APIResult(ok=False, data=data, error=message)
        return APIResult(ok=True, data=data)

    def health(self) -> APIResult:
        return self._request("GET", "/healthz", use_health_base=True)

    def readiness(self) -> APIResult:
        return self._request("GET", "/readyz", use_health_base=True)

    def list_verifications(self, *, status: str = "", limit: int = 100) -> APIResult:
        params: dict[str, Any] = {"limit": limit}
        if status.strip():
            params["status"] = status.strip()
        return self._request("GET", "/admin/verifications", params=params)

    def approve_verification(self, user_id: str) -> APIResult:
        return self._request("POST", f"/admin/verifications/{user_id}/approve", payload={})

    def reject_verification(self, user_id: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/verifications/{user_id}/reject",
            payload={"rejection_reason": reason},
        )

    def list_activities(self, *, limit: int = 100) -> APIResult:
        return self._request("GET", "/admin/activities", params={"limit": limit})

    def list_appeals(self, *, status: str = "", limit: int = 100) -> APIResult:
        params: dict[str, Any] = {"limit": limit}
        if status.strip():
            params["status"] = status.strip()
        return self._request("GET", "/admin/moderation/appeals", params=params)

    def action_appeal(self, appeal_id: str, status: str, resolution_reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/moderation/appeals/{appeal_id}/action",
            payload={
                "status": status,
                "resolution_reason": resolution_reason,
            },
        )

    def analytics_overview(self) -> APIResult:
        return self._request("GET", "/admin/analytics/overview")

