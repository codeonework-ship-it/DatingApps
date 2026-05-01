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

    # ── Health ────────────────────────────────────────────────────────────────

    def health(self) -> APIResult:
        return self._request("GET", "/healthz", use_health_base=True)

    def readiness(self) -> APIResult:
        return self._request("GET", "/readyz", use_health_base=True)

    # ── Verifications ─────────────────────────────────────────────────────────

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

    # ── Activities ────────────────────────────────────────────────────────────

    def list_activities(self, *, limit: int = 100) -> APIResult:
        return self._request("GET", "/admin/activities", params={"limit": limit})

    # ── Appeals / Moderation ──────────────────────────────────────────────────

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

    def list_reports(self, *, status: str = "", limit: int = 100) -> APIResult:
        params: dict[str, Any] = {"limit": limit}
        if status.strip():
            params["status"] = status.strip()
        return self._request("GET", "/admin/moderation/reports", params=params)

    def action_report(self, report_id: str, action: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/moderation/reports/{report_id}/action",
            payload={"action": action, "reason": reason},
        )

    # ── Analytics ─────────────────────────────────────────────────────────────

    def analytics_overview(self) -> APIResult:
        return self._request("GET", "/admin/analytics/overview")

    # ── Gift Catalog ──────────────────────────────────────────────────────────

    def list_catalog_gifts(self, *, category: str = "", tier: str = "", active: str = "", q: str = "", limit: int = 50, offset: int = 0) -> APIResult:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if category.strip():
            params["category"] = category.strip()
        if tier.strip():
            params["tier"] = tier.strip()
        if active.strip():
            params["active"] = active.strip()
        if q.strip():
            params["q"] = q.strip()
        return self._request("GET", "/admin/catalog/gifts", params=params)

    def create_catalog_gift(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/catalog/gifts", payload=payload)

    def update_catalog_gift(self, gift_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/catalog/gifts/{gift_id}", payload=payload)

    def toggle_catalog_gift(self, gift_id: str, *, is_active: bool) -> APIResult:
        return self._request(
            "POST",
            f"/admin/catalog/gifts/{gift_id}/toggle",
            payload={"is_active": is_active},
        )

    def delete_catalog_gift(self, gift_id: str) -> APIResult:
        return self._request("DELETE", f"/admin/catalog/gifts/{gift_id}")

    # ── User Management ───────────────────────────────────────────────────────

    def list_users(self, *, limit: int = 50, offset: int = 0, q: str = "", status: str = "", gender: str = "", verified: str = "") -> APIResult:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if q.strip():
            params["q"] = q.strip()
        if status.strip():
            params["status"] = status.strip()
        if gender.strip():
            params["gender"] = gender.strip()
        if verified.strip():
            params["verified"] = verified.strip()
        return self._request("GET", "/admin/users", params=params)

    def get_user(self, user_id: str) -> APIResult:
        return self._request("GET", f"/admin/users/{user_id}")

    def create_user(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/users", payload=payload)

    def update_user(self, user_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/users/{user_id}", payload=payload)

    def delete_user(self, user_id: str) -> APIResult:
        return self._request("DELETE", f"/admin/users/{user_id}")

    def suspend_user(self, user_id: str, reason: str, days: int = 0) -> APIResult:
        return self._request(
            "POST",
            f"/admin/users/{user_id}/suspend",
            payload={"reason": reason, "days": days},
        )

    def unsuspend_user(self, user_id: str) -> APIResult:
        return self._request("POST", f"/admin/users/{user_id}/unsuspend", payload={})

    def grant_coins(self, user_id: str, coins: int, reason: str = "admin_grant") -> APIResult:
        return self._request(
            "POST",
            f"/wallet/{user_id}/coins/top-up",
            payload={"coins": coins, "source": reason, "provider": "admin"},
        )

    def ban_user(self, user_id: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/users/{user_id}/ban",
            payload={"reason": reason},
        )

    def unban_user(self, user_id: str) -> APIResult:
        return self._request("POST", f"/admin/users/{user_id}/unban", payload={})

    def force_verify_user(self, user_id: str) -> APIResult:
        return self._request("POST", f"/admin/users/{user_id}/verify", payload={})

    def get_wallet_transactions(self, user_id: str, *, limit: int = 20) -> APIResult:
        return self._request(
            "GET",
            "/admin/billing/transactions",
            params={"limit": limit, "source": "eq.admin_grant"},
        )

    def list_billing_transactions(self, *, limit: int = 50, offset: int = 0) -> APIResult:
        return self._request(
            "GET",
            "/admin/billing/transactions",
            params={"limit": limit, "offset": offset},
        )

    def create_coin_package(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/billing/coin-packages", payload=payload)

    def update_coin_package(self, package_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/billing/coin-packages/{package_id}", payload=payload)

    # ── Feature Flags ─────────────────────────────────────────────────────────

    def list_config_flags(self) -> APIResult:
        return self._request("GET", "/admin/config/flags")

    def update_config_flag(self, key: str, value: bool, updated_by: str = "admin") -> APIResult:
        return self._request(
            "PUT",
            f"/admin/config/flags/{key}",
            payload={"value_bool": value, "updated_by": updated_by},
        )

    # ── Engagement Prompts ────────────────────────────────────────────────────

    def list_engagement_prompts(self) -> APIResult:
        return self._request("GET", "/admin/engagement/prompts")

    def create_engagement_prompt(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/engagement/prompts", payload=payload)

    def update_engagement_prompt(self, prompt_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/engagement/prompts/{prompt_id}", payload=payload)

    def activate_engagement_prompt(self, prompt_id: str) -> APIResult:
        return self._request(
            "POST", f"/admin/engagement/prompts/{prompt_id}/activate", payload={}
        )

    # ── Billing ───────────────────────────────────────────────────────────────

    def list_billing_plans(self) -> APIResult:
        return self._request("GET", "/admin/billing/plans")

    def list_coin_packages(self) -> APIResult:
        return self._request("GET", "/admin/billing/coin-packages")

    def toggle_coin_package(self, package_id: str, *, is_active: bool) -> APIResult:
        return self._request(
            "POST",
            f"/admin/billing/coin-packages/{package_id}/toggle",
            payload={"is_active": is_active},
        )

    def get_billing_stats(self) -> APIResult:
        return self._request("GET", "/admin/billing/stats")

    def admin_grant_coins(self, user_id: str, amount: int, reason: str = "admin_grant") -> APIResult:
        return self._request(
            "POST",
            "/admin/billing/grant-coins",
            payload={"user_id": user_id, "amount": amount, "reason": reason},
        )

    def list_subscriptions(self, *, limit: int = 50, offset: int = 0, status: str = "", plan_code: str = "") -> APIResult:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if status.strip():
            params["status"] = status.strip()
        if plan_code.strip():
            params["plan_code"] = plan_code.strip()
        return self._request("GET", "/admin/billing/subscriptions", params=params)

    def list_payments(self, *, limit: int = 50, offset: int = 0, status: str = "") -> APIResult:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if status.strip():
            params["status"] = status.strip()
        return self._request("GET", "/admin/billing/payments", params=params)

    def get_revenue_analytics(self) -> APIResult:
        return self._request("GET", "/admin/billing/revenue-analytics")

    def get_wallet_balance(self, user_id: str) -> APIResult:
        return self._request("GET", f"/admin/users/{user_id}/wallet")

    # ── Safety / SOS ──────────────────────────────────────────────────────────

    def list_sos_alerts(self) -> APIResult:
        return self._request("GET", "/admin/safety/sos-alerts")

    def resolve_sos_alert(self, alert_id: str) -> APIResult:
        return self._request("POST", f"/admin/safety/sos-alerts/{alert_id}/resolve", payload={})

