from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable
import logging
import re
import uuid

import requests
from django.conf import settings

from control_panel.operator_context import current_operator_session


logger = logging.getLogger(__name__)

# Text that only makes sense to an engineer: driver/SQL errors, Go runtime
# errors and transport failures. A 4xx carrying one of these is hidden too.
_INTERNAL_ERROR_PATTERN = re.compile(
    r"sqlstate|\bpq:|pgx|pgconn|postgres|\bsql\b|syntax error|violates|duplicate key|"
    r"relation \"|column \"|deadlock|lock timeout|canceling statement|no rows in result set|"
    r"invalid input syntax|unexpected eof|context deadline|context canceled|dial tcp|"
    r"connection refused|connection reset|broken pipe|i/o timeout|panic|runtime error|"
    r"goroutine|nil pointer|httpconnectionpool|max retries|traceback",
    re.IGNORECASE,
)
_MAX_READABLE_ERROR_LENGTH = 300


def operator_error_message(
    status_code: int,
    raw_error: str,
    *,
    correlation_id: str = "",
    method: str = "",
    path: str = "",
) -> str:
    """What an operator sees for a failed BFF call (CON-03).

    Actionable 4xx answers (validation, 403, 404, 409, 429...) are shown as Go
    wrote them. 5xx answers, transport failures and anything that reads like a
    database or runtime error become one generic message; the raw detail is
    logged here with the correlation id so it can be found in both logs.
    """
    raw = str(raw_error or "").strip()
    if (
        400 <= status_code < 500
        and raw
        and len(raw) <= _MAX_READABLE_ERROR_LENGTH
        and not _INTERNAL_ERROR_PATTERN.search(raw)
    ):
        return raw
    if 400 <= status_code < 500 and not raw:
        return f"request failed with {status_code}"
    logger.warning(
        "BFF request failed: %s %s status=%s correlation_id=%s error=%s",
        method or "-",
        path or "-",
        status_code or "no-response",
        correlation_id or "-",
        raw or "<empty>",
    )
    ref = f" (ref {correlation_id})" if correlation_id else ""
    return (
        "The service couldn't complete that request. Try again; if it keeps "
        f"happening, check the logs{ref}."
    )


def _response_correlation_id(data: Any, sent: str) -> str:
    if isinstance(data, dict):
        value = data.get("correlation_id")
        if isinstance(value, str) and value.strip():
            return value.strip()
    return sent


@dataclass
class APIResult:
    ok: bool
    data: dict[str, Any]
    error: str = ""
    status_code: int = 0


@dataclass
class BinaryAPIResult:
    ok: bool
    content: bytes = b""
    content_type: str = "application/octet-stream"
    error: str = ""
    status_code: int = 0


@dataclass
class StreamAPIResult:
    """A binary Go response passed through in chunks (CSV exports, private
    support attachments) so large bodies are never held in console memory."""
    ok: bool
    chunks: Iterable[bytes] = ()
    content_type: str = "application/octet-stream"
    content_disposition: str = ""
    content_length: str = ""
    error: str = ""
    status_code: int = 0


class GoBFFClient:
    def __init__(
        self,
        *,
        access_token: str = "",
        refresh_token: str = "",
        use_operator_context: bool = True,
    ) -> None:
        self.api_base = settings.GO_API_BASE_URL
        self.health_base = settings.GO_HEALTH_BASE_URL
        self.timeout = settings.GO_API_TIMEOUT_SEC
        operator_session = current_operator_session.get() if use_operator_context else None
        self.access_token = access_token or (operator_session.access_token if operator_session else "")
        self.refresh_token = refresh_token or (operator_session.refresh_token if operator_session else "")
        self._update_tokens = operator_session.update_tokens if operator_session else None
        self._clear_tokens = operator_session.clear_tokens if operator_session else None
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Content-Type": "application/json",
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
        allow_refresh: bool = True,
    ) -> APIResult:
        base = self.health_base if use_health_base else self.api_base
        url = f"{base.rstrip('/')}/{path.lstrip('/')}"
        correlation_id = f"control-panel-{uuid.uuid4()}"
        headers: dict[str, str] = {"X-Correlation-ID": correlation_id}
        if self.access_token and not use_health_base:
            headers["Authorization"] = f"Bearer {self.access_token}"
        if method.upper() not in {"GET", "HEAD", "OPTIONS"}:
            headers["Idempotency-Key"] = f"control-panel-{uuid.uuid4()}"
        response = None
        try:
            response = self.session.request(
                method=method,
                url=url,
                params=params,
                json=payload,
                headers=headers,
                timeout=self.timeout,
            )
            data = response.json() if response.content else {}
        except requests.RequestException as exc:
            error = operator_error_message(0, str(exc), correlation_id=correlation_id, method=method, path=path)
            return APIResult(ok=False, data={}, error=error)
        except ValueError:
            status = response.status_code if response is not None and isinstance(response.status_code, int) else 0
            error = operator_error_message(
                max(status, 500), "invalid JSON response from Go API",
                correlation_id=correlation_id, method=method, path=path,
            )
            return APIResult(ok=False, data={}, error=error, status_code=status)

        if response.status_code == 401 and allow_refresh and self._refresh_session():
            return self._request(
                method,
                path,
                params=params,
                payload=payload,
                use_health_base=use_health_base,
                allow_refresh=False,
            )

        if response.status_code >= 400:
            raw = data.get("error") if isinstance(data, dict) else ""
            message = operator_error_message(
                response.status_code, str(raw or ""),
                correlation_id=_response_correlation_id(data, correlation_id), method=method, path=path,
            )
            return APIResult(ok=False, data=data, error=message, status_code=response.status_code)
        return APIResult(ok=True, data=data, status_code=response.status_code)

    def _refresh_session(self) -> bool:
        if not self.refresh_token:
            return False
        status_code = 0
        try:
            response = self.session.post(
                f"{self.api_base}/auth/refresh",
                json={"refresh_token": self.refresh_token},
                timeout=self.timeout,
            )
            data = response.json() if response.content else {}
            status_code = response.status_code
        except (requests.RequestException, ValueError):
            data = {}
        access_token = str(data.get("access_token") or "").strip()
        refresh_token = str(data.get("refresh_token") or "").strip()
        if status_code >= 400 or not access_token or not refresh_token:
            if self._clear_tokens:
                self._clear_tokens()
            return False
        self.access_token = access_token
        self.refresh_token = refresh_token
        if self._update_tokens:
            self._update_tokens(access_token, refresh_token)
        return True

    def login(self, username: str, password: str) -> APIResult:
        return self._request(
            "POST",
            "/auth/login",
            payload={"username": username, "password": password},
            allow_refresh=False,
        )

    def logout(self) -> APIResult:
        return self._request("POST", "/auth/logout", payload={}, allow_refresh=False)

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

    def list_audit_events(
        self,
        *,
        limit: int = 100,
        event_type: str = "",
        actor_user_id: str = "",
        subject_user_id: str = "",
        resource_type: str = "",
    ) -> APIResult:
        params: dict[str, Any] = {"limit": limit}
        for key, value in {
            "event_type": event_type,
            "actor_user_id": actor_user_id,
            "subject_user_id": subject_user_id,
            "resource_type": resource_type,
        }.items():
            if value.strip():
                params[key] = value.strip()
        return self._request("GET", "/admin/audit-events", params=params)

    def list_domain_events(
        self,
        *,
        limit: int = 100,
        event_name: str = "",
        aggregate_type: str = "",
        aggregate_id: str = "",
        producer: str = "",
        correlation_id: str = "",
        subject_user_id: str = "",
        after_sequence: str = "",
    ) -> APIResult:
        params: dict[str, Any] = {"limit": limit}
        for key, value in {
            "event_name": event_name,
            "aggregate_type": aggregate_type,
            "aggregate_id": aggregate_id,
            "producer": producer,
            "correlation_id": correlation_id,
            "subject_user_id": subject_user_id,
            "after_sequence": after_sequence,
        }.items():
            if value.strip():
                params[key] = value.strip()
        return self._request("GET", "/admin/events", params=params)

    def domain_event_metrics(self) -> APIResult:
        return self._request("GET", "/admin/events/metrics")

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

    # ── Deferred growth governance ───────────────────────────────────────────

    def growth_portfolio(self) -> APIResult:
        return self._request("GET", "/growth/portfolio")

    # ── Support tickets (operator API, /v1/admin/support/...) ────────────────
    # Go allows admin, ops_admin, support, trust_safety and moderator; analyst
    # may only GET the dashboard.

    SUPPORT_TICKET_FILTERS = ("status", "category", "priority", "team", "channel", "assignee", "sla", "q", "sort")

    @classmethod
    def _support_filter_params(cls, filters: dict[str, Any]) -> dict[str, Any]:
        params: dict[str, Any] = {}
        for key in cls.SUPPORT_TICKET_FILTERS:
            value = str(filters.get(key) or "").strip()
            if value:
                params[key] = value
        return params

    def list_support_tickets(self, *, limit: int = 50, offset: int = 0, **filters: Any) -> APIResult:
        params = self._support_filter_params(filters)
        params["limit"] = limit
        params["offset"] = offset
        return self._request("GET", "/admin/support/tickets", params=params)

    def export_support_tickets(self, **filters: Any) -> StreamAPIResult:
        """The filtered queue as CSV (no message bodies), streamed through."""
        return self._stream_get("/admin/support/tickets/export", params=self._support_filter_params(filters))

    def get_support_ticket(self, ticket_id: str) -> APIResult:
        return self._request("GET", f"/admin/support/tickets/{ticket_id}")

    def update_support_ticket(self, ticket_id: str, changes: dict[str, Any]) -> APIResult:
        """PATCH status/priority/category/team/assignee_id/tags/client_error_issue_id.
        Only the keys present are changed; "" unassigns or clears the error link."""
        return self._request("PATCH", f"/admin/support/tickets/{ticket_id}", payload=dict(changes))

    def claim_support_ticket(self, ticket_id: str) -> APIResult:
        return self._request("POST", f"/admin/support/tickets/{ticket_id}/claim", payload={})

    def reply_support_ticket(
        self,
        ticket_id: str,
        *,
        body: str,
        visibility: str,
        canned_response_id: str = "",
        status: str = "",
    ) -> APIResult:
        payload: dict[str, Any] = {"body": body, "visibility": visibility}
        if canned_response_id:
            payload["canned_response_id"] = canned_response_id
        if status:
            payload["status"] = status
        return self._request("POST", f"/admin/support/tickets/{ticket_id}/messages", payload=payload)

    def merge_support_ticket(self, ticket_id: str, into_ticket_id: str) -> APIResult:
        return self._request(
            "POST", f"/admin/support/tickets/{ticket_id}/merge", payload={"into_ticket_id": into_ticket_id}
        )

    def bulk_support_tickets(self, ticket_ids: list[str], action: str, value: str = "") -> APIResult:
        return self._request(
            "POST",
            "/admin/support/tickets/bulk",
            payload={"ticket_ids": list(ticket_ids), "action": action, "value": value},
        )

    def preview_support_canned_response(self, ticket_id: str, response_id: str) -> APIResult:
        return self._request(
            "GET", f"/admin/support/tickets/{ticket_id}/canned-responses/{response_id}/preview"
        )

    def support_attachment_content(self, attachment_id: str) -> StreamAPIResult:
        """Private attachment bytes, fetched with the operator's token server-side."""
        return self._stream_get(f"/admin/support/attachments/{attachment_id}/content")

    def support_dashboard(self, *, days: int = 30) -> APIResult:
        return self._request("GET", "/admin/support/dashboard", params={"days": days})

    def support_agents(self) -> APIResult:
        return self._request("GET", "/admin/support/agents")

    def list_support_canned_responses(self, *, include_inactive: bool = False) -> APIResult:
        params = {"include_inactive": 1} if include_inactive else None
        return self._request("GET", "/admin/support/canned-responses", params=params)

    def create_support_canned_response(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/support/canned-responses", payload=dict(payload))

    def update_support_canned_response(self, response_id: str, changes: dict[str, Any]) -> APIResult:
        return self._request("PATCH", f"/admin/support/canned-responses/{response_id}", payload=dict(changes))

    def deactivate_support_canned_response(self, response_id: str) -> APIResult:
        return self._request("DELETE", f"/admin/support/canned-responses/{response_id}")

    def _stream_get(
        self, path: str, *, params: dict[str, Any] | None = None, allow_refresh: bool = True
    ) -> StreamAPIResult:
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        try:
            response = self.session.get(
                f"{self.api_base.rstrip('/')}/{path.lstrip('/')}",
                params=params or None,
                headers=headers,
                timeout=self.timeout,
                stream=True,
            )
        except requests.RequestException as exc:
            return StreamAPIResult(ok=False, error=operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET", path=path))
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            response.close()
            return self._stream_get(path, params=params, allow_refresh=False)
        if response.status_code >= 400:
            try:
                body = response.json()
                message = str(body.get("error") or "") if isinstance(body, dict) else ""
            except ValueError:
                message = ""
            finally:
                response.close()
            return StreamAPIResult(
                ok=False,
                error=operator_error_message(
                    response.status_code, message,
                    correlation_id=headers["X-Correlation-ID"], method="GET", path=path,
                ),
                status_code=response.status_code,
            )

        def chunks():
            try:
                for chunk in response.iter_content(chunk_size=64 * 1024):
                    if chunk:
                        yield chunk
            finally:
                response.close()

        return StreamAPIResult(
            ok=True,
            chunks=chunks(),
            content_type=response.headers.get("Content-Type", "application/octet-stream"),
            content_disposition=response.headers.get("Content-Disposition", ""),
            content_length=response.headers.get("Content-Length", ""),
            status_code=response.status_code,
        )

    def list_growth_fraud_graph(self, *, status: str = "open", limit: int = 100) -> APIResult:
        return self._request(
            "GET", "/admin/growth/fraud-graph", params={"status": status, "limit": limit}
        )

    def resolve_growth_fraud_edge(self, edge_id: str, status: str) -> APIResult:
        return self._request(
            "POST", f"/admin/growth/fraud-graph/{edge_id}/resolve", payload={"status": status}
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

    def list_media_moderation(self, *, status: str = "review_required", limit: int = 50) -> APIResult:
        return self._request(
            "GET",
            "/admin/moderation/media",
            params={"status": status, "limit": limit},
        )

    def decide_media_moderation(self, photo_id: str, decision: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/moderation/media/{photo_id}/decision",
            payload={"decision": decision, "reason": reason},
        )

    def get_media_moderation_content(self, photo_id: str, *, allow_refresh: bool = True) -> BinaryAPIResult:
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        try:
            response = self.session.get(
                f"{self.api_base.rstrip('/')}/admin/moderation/media/{photo_id}/content",
                headers=headers,
                timeout=self.timeout,
            )
        except requests.RequestException as exc:
            return BinaryAPIResult(ok=False, error=operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET"))
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            return self.get_media_moderation_content(photo_id, allow_refresh=False)
        if response.status_code >= 400:
            return BinaryAPIResult(
                ok=False,
                error=f"request failed with {response.status_code}",
                status_code=response.status_code,
            )
        return BinaryAPIResult(
            ok=True,
            content=response.content,
            content_type=response.headers.get("Content-Type", "application/octet-stream"),
            status_code=response.status_code,
        )

    def photo_themes(self) -> APIResult:
        return self._request("GET", "/admin/engagement/photo-themes")

    def save_photo_theme(self, payload) -> APIResult:
        return self._request("POST", "/admin/engagement/photo-themes", payload=payload)

    def blog_reviews(self, *, status="pending", offset=0) -> APIResult:
        return self._request("GET", "/admin/moderation/blog", params={"status": status, "offset": offset})

    def blog_decision(self, case_id, payload) -> APIResult:
        return self._request("POST", f"/admin/moderation/blog/{case_id}", payload=payload)

    def blog_evidence(self, case_id, photo_id, *, allow_refresh=True) -> BinaryAPIResult:
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        try:
            response = self.session.get(f"{self.api_base.rstrip('/')}/admin/moderation/blog/{case_id}/photos/{photo_id}", headers=headers, timeout=self.timeout)
        except requests.RequestException as exc:
            return BinaryAPIResult(ok=False, error=operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET"))
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            return self.blog_evidence(case_id, photo_id, allow_refresh=False)
        if response.status_code >= 400:
            return BinaryAPIResult(ok=False, error="Evidence unavailable", status_code=response.status_code)
        return BinaryAPIResult(ok=True, content=response.content, content_type=response.headers.get("Content-Type", "application/octet-stream"), status_code=response.status_code)

    # ── Analytics ─────────────────────────────────────────────────────────────

    def analytics_overview(self) -> APIResult:
        return self._request("GET", "/admin/analytics/overview")

    # Durable product analytics reports (admin, analyst; read-only).
    ANALYTICS_REPORTS = ("kpis", "trends", "funnel", "retention", "engagement", "liquidity", "safety")

    def analytics_report(self, name: str, params: dict[str, Any] | None = None) -> APIResult:
        if name not in self.ANALYTICS_REPORTS:
            return APIResult(ok=False, data={}, error="unknown analytics report")
        return self._request("GET", f"/admin/analytics/{name}", params=params or {})

    def analytics_report_csv(self, name: str, params: dict[str, Any] | None = None, *, allow_refresh: bool = True):
        """Open a streamed CSV export. Returns (response, error); the caller
        iterates response.iter_content() and closes it."""
        if name not in self.ANALYTICS_REPORTS:
            return None, "unknown analytics report"
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}", "Accept": "text/csv"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        query = dict(params or {})
        query["format"] = "csv"
        try:
            response = self.session.get(
                f"{self.api_base.rstrip('/')}/admin/analytics/{name}",
                params=query, headers=headers, timeout=self.timeout, stream=True,
            )
        except requests.RequestException as exc:
            return None, operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET", path=f"/admin/analytics/{name}")
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            response.close()
            return self.analytics_report_csv(name, params, allow_refresh=False)
        if response.status_code >= 400:
            try:
                message = str(response.json().get("error") or "")
            except ValueError:
                message = ""
            response.close()
            return None, operator_error_message(
                response.status_code, message, correlation_id=headers["X-Correlation-ID"],
                method="GET", path=f"/admin/analytics/{name}")
        return response, ""

    def analytics_definitions(self) -> APIResult:
        return self._request("GET", "/admin/analytics/definitions")

    def analytics_snapshots(self) -> APIResult:
        return self._request("GET", "/admin/analytics/snapshots")

    def analytics_rebuild(self, from_day: str, to_day: str) -> APIResult:
        return self._request("POST", "/admin/analytics/snapshots/rebuild", payload={"from": from_day, "to": to_day})

    def analytics_excluded_accounts(self) -> APIResult:
        return self._request("GET", "/admin/analytics/excluded-accounts")

    def analytics_exclude_account(self, member_id: str, reason: str) -> APIResult:
        return self._request("POST", "/admin/analytics/excluded-accounts", payload={"member_id": member_id, "reason": reason})

    def analytics_include_account(self, member_id: str) -> APIResult:
        return self._request("DELETE", f"/admin/analytics/excluded-accounts/{member_id}")

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

    def list_billing_transactions(self, *, limit: int = 50, offset: int = 0, user_id: str = "") -> APIResult:
        """Coin purchases, newest first. ``user_id`` asks Go for one member's
        rows (CON-04, filtered by the BFF); callers still drop any row for
        another member as a defence against an older BFF."""
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if user_id.strip():
            params["user_id"] = user_id.strip()
        return self._request("GET", "/admin/billing/transactions", params=params)

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

    def list_engagement_nudges(self) -> APIResult:
        return self._request("GET", "/admin/engagement/nudges")

    # ── Level / XP progression ───────────────────────────────────────────────

    def progression_overview(self) -> APIResult:
        return self._request("GET", "/admin/progression")

    def update_progression_policy(self, source: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/progression/policies/{source}", payload=payload)

    def list_progression_fraud(self, *, status: str = "open") -> APIResult:
        params = {"status": status} if status.strip() else {}
        return self._request("GET", "/admin/progression/fraud", params=params)

    def resolve_progression_fraud(
        self, case_id: str, status: str, resolution: str
    ) -> APIResult:
        return self._request(
            "POST",
            f"/admin/progression/fraud/{case_id}/resolve",
            payload={"status": status, "resolution": resolution},
        )

    def adjust_user_xp(self, user_id: str, amount: int, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/progression/users/{user_id}/adjust-xp",
            payload={"amount": amount, "reason": reason},
        )

    def set_user_progression_control(
        self,
        user_id: str,
        *,
        progression_frozen: bool,
        risk_multiplier: float,
        reason: str,
    ) -> APIResult:
        return self._request(
            "PUT",
            f"/admin/progression/users/{user_id}/control",
            payload={
                "progression_frozen": progression_frozen,
                "risk_multiplier": risk_multiplier,
                "reason": reason,
            },
        )

    def update_progression_experiment(
        self,
        key: str,
        *,
        status: str,
        rollout_stage: str,
        rollout_percent: int,
        safety_stop_owner: str,
        evidence_uri: str,
        decision_note: str,
    ) -> APIResult:
        return self._request(
            "PUT",
            f"/admin/progression/experiments/{key}",
            payload={
                "status": status,
                "rollout_stage": rollout_stage,
                "rollout_percent": rollout_percent,
                "safety_stop_owner": safety_stop_owner,
                "evidence_uri": evidence_uri,
                "decision_note": decision_note,
            },
        )

    def update_progression_fraud_rule(
        self, rule_code: str, payload: dict[str, Any]
    ) -> APIResult:
        return self._request(
            "PUT", f"/admin/progression/fraud-rules/{rule_code}", payload=payload
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

    def get_billing_stats(self, params: dict[str, Any] | None = None) -> APIResult:
        return self._request("GET", "/admin/billing/stats", params=params or None)

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

    def get_revenue_analytics(self, params: dict[str, Any] | None = None) -> APIResult:
        return self._request("GET", "/admin/billing/revenue-analytics", params=params or None)

    def get_billing_reconciliation(self, *, since: str = "", until: str = "") -> APIResult:
        params: dict[str, Any] = {}
        if since.strip():
            params["since"] = since.strip()
        if until.strip():
            params["until"] = until.strip()
        return self._request("GET", "/admin/billing/reconciliation", params=params)

    def list_billing_webhook_events(self, *, limit: int = 50, offset: int = 0, status: str = "", event_type: str = "") -> APIResult:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if status.strip():
            params["status"] = status.strip()
        if event_type.strip():
            params["event_type"] = event_type.strip()
        return self._request("GET", "/admin/billing/webhook-events", params=params)

    def get_wallet_balance(self, user_id: str) -> APIResult:
        return self._request("GET", f"/admin/users/{user_id}/wallet")

    def reverse_gift_send(self, send_id: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/billing/gift-sends/{send_id}/reverse",
            payload={"reason": reason},
        )

    def list_frozen_wallets(self) -> APIResult:
        return self._request("GET", "/admin/billing/wallets/frozen")

    def review_frozen_wallet(self, user_id: str, *, action: str, note: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/billing/wallets/{user_id}/review",
            payload={"action": action, "note": note},
        )

    def list_economy_fraud_cases(self, *, status: str = "open", limit: int = 100) -> APIResult:
        return self._request("GET", "/admin/billing/fraud/cases", params={"status": status, "limit": limit})

    def list_economy_fraud_rules(self) -> APIResult:
        return self._request("GET", "/admin/billing/fraud/rules")

    def resolve_economy_fraud_case(self, case_id: str, *, resolution: str, note: str) -> APIResult:
        return self._request("POST", f"/admin/billing/fraud/cases/{case_id}/resolve", payload={"resolution": resolution, "note": note})

    def update_economy_fraud_rule(self, rule_code: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/billing/fraud/rules/{rule_code}", payload=payload)

    # ── Safety / SOS ──────────────────────────────────────────────────────────

    def list_sos_alerts(self) -> APIResult:
        return self._request("GET", "/admin/safety/sos-alerts")

    def resolve_sos_alert(self, alert_id: str) -> APIResult:
        return self._request("POST", f"/admin/safety/sos-alerts/{alert_id}/resolve", payload={})

    # ── Account recovery (PEN-06) ─────────────────────────────────────────────

    def list_account_recovery(self, *, status: str = "open") -> APIResult:
        return self._request("GET", "/admin/safety/account-recovery", params={"status": status})

    def resolve_account_recovery(
        self, request_id: str, *, action: str, identity_check: str, resolution_note: str
    ) -> APIResult:
        return self._request(
            "POST",
            f"/admin/safety/account-recovery/{request_id}/resolve",
            payload={
                "action": action,
                "identity_check": identity_check,
                "resolution_note": resolution_note,
            },
        )

    def city_pilot(self) -> APIResult:
        return self._request("GET", "/admin/growth/city-pilot")

    def save_city_pilot(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/growth/city-pilot", payload=payload)

    def transition_city_pilot(self, pilot_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", f"/admin/growth/city-pilot/{pilot_id}/stage", payload=payload)

    def city_pilot_experiences(self, pilot_id: str) -> APIResult:
        return self._request("GET", f"/admin/growth/city-pilot/{pilot_id}/experiences")

    def create_city_pilot_experience(self, pilot_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", f"/admin/growth/city-pilot/{pilot_id}/experiences", payload=payload)

    def cancel_city_pilot_experience(self, pilot_id: str, event_id: str) -> APIResult:
        return self._request("POST", f"/admin/growth/city-pilot/{pilot_id}/experiences/{event_id}/cancel", payload={})

    # ── Client errors (self-hosted app crash/error reporting) ────────────────

    def list_client_errors(self, **filters: Any) -> APIResult:
        """Issues grouped by fingerprint. Accepted filters: status, platform,
        version, fatal, sort, limit, offset; empty values are not sent."""
        allowed = ("status", "platform", "version", "fatal", "sort", "limit", "offset")
        params: dict[str, Any] = {}
        for key in allowed:
            value = filters.get(key)
            if value is None or (isinstance(value, str) and not value.strip()):
                continue
            if isinstance(value, bool):
                value = "true" if value else "false"
            params[key] = value.strip() if isinstance(value, str) else value
        return self._request("GET", "/admin/client-errors", params=params)

    def get_client_error(self, issue_id: str) -> APIResult:
        return self._request("GET", f"/admin/client-errors/{issue_id}")

    def set_client_error_status(
        self,
        issue_id: str,
        status: str,
        resolved_in_version: str | None = None,
        note: str | None = None,
    ) -> APIResult:
        payload: dict[str, Any] = {"status": status}
        if resolved_in_version and resolved_in_version.strip():
            payload["resolved_in_version"] = resolved_in_version.strip()
        if note and note.strip():
            payload["note"] = note.strip()
        return self._request("POST", f"/admin/client-errors/{issue_id}/status", payload=payload)

    # ── Conversation Rooms (operator moderation) ─────────────────────────────

    def admin_rooms(self) -> APIResult:
        return self._request("GET", "/admin/moderation/rooms")

    def admin_room_action(self, room_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", f"/admin/moderation/rooms/{room_id}/actions", payload=payload)

    def room_members(self, room_id: str) -> APIResult:
        """Current members, then anyone still muted or removed (operators)."""
        return self._request("GET", f"/admin/moderation/rooms/{room_id}/members")

    def admin_room_role(self, room_id: str, member_id: str, role: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/moderation/rooms/{room_id}/roles",
            payload={"member_id": member_id, "role": role},
        )

    # ── Group cover review (operator moderation) ─────────────────────────────

    def group_covers(self, *, status: str = "pending", limit: int = 50) -> APIResult:
        return self._request("GET", "/admin/moderation/group-covers", params={"status": status, "limit": limit})

    def group_cover_decision(self, cover_id: str, decision: str, reason: str) -> APIResult:
        return self._request(
            "POST",
            f"/admin/moderation/group-covers/{cover_id}/decision",
            payload={"decision": decision, "reason": reason},
        )

    def group_cover_content(self, cover_id: str, *, allow_refresh: bool = True) -> BinaryAPIResult:
        """Cover image bytes, fetched with the operator's token server-side so
        the browser never sees Go credentials."""
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        try:
            response = self.session.get(
                f"{self.api_base.rstrip('/')}/admin/moderation/group-covers/{cover_id}/content",
                headers=headers,
                timeout=self.timeout,
            )
        except requests.RequestException as exc:
            return BinaryAPIResult(ok=False, error=operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET"))
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            return self.group_cover_content(cover_id, allow_refresh=False)
        if response.status_code >= 400:
            return BinaryAPIResult(ok=False, error="Cover unavailable", status_code=response.status_code)
        return BinaryAPIResult(
            ok=True,
            content=response.content,
            content_type=response.headers.get("Content-Type", "application/octet-stream"),
            status_code=response.status_code,
        )

    # ── Business reports (documents/BUSINESS_REPORTS_2026-10-01.md) ──────────

    BUSINESS_REPORTS = (
        "revenue", "subscriptions", "conversion", "funnel", "coins",
        "referrals", "markets", "investor-pack", "marketing-spend",
    )

    def business_report(self, report: str, params: dict[str, Any] | None = None) -> APIResult:
        if report not in self.BUSINESS_REPORTS:
            return APIResult(ok=False, data={}, error="unknown business report")
        return self._request("GET", f"/admin/business/{report}", params=params or None)

    def business_csv(self, report: str, params: dict[str, Any] | None = None, *, allow_refresh: bool = True) -> BinaryAPIResult:
        """One report table as CSV, fetched server-side with the operator's token."""
        if report not in self.BUSINESS_REPORTS:
            return BinaryAPIResult(ok=False, error="unknown business report")
        headers = {"X-Correlation-ID": f"control-panel-{uuid.uuid4()}"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        query = dict(params or {})
        query["format"] = "csv"
        try:
            response = self.session.get(
                f"{self.api_base.rstrip('/')}/admin/business/{report}",
                params=query,
                headers=headers,
                timeout=self.timeout,
            )
        except requests.RequestException as exc:
            return BinaryAPIResult(ok=False, error=operator_error_message(
                0, str(exc), correlation_id=headers["X-Correlation-ID"], method="GET"))
        if response.status_code == 401 and allow_refresh and self._refresh_session():
            return self.business_csv(report, params, allow_refresh=False)
        if response.status_code >= 400:
            try:
                message = str(response.json().get("error") or "")
            except ValueError:
                message = ""
            return BinaryAPIResult(ok=False, error=operator_error_message(
                response.status_code, message, correlation_id=headers["X-Correlation-ID"],
                method="GET", path=f"/admin/business/{report}"), status_code=response.status_code)
        return BinaryAPIResult(
            ok=True,
            content=response.content,
            content_type=response.headers.get("Content-Type", "text/csv"),
            status_code=response.status_code,
        )

    def save_marketing_spend(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/business/marketing-spend", payload=payload)

    def update_marketing_spend(self, spend_id: str, payload: dict[str, Any]) -> APIResult:
        return self._request("PUT", f"/admin/business/marketing-spend/{spend_id}", payload=payload)

    def delete_marketing_spend(self, spend_id: str) -> APIResult:
        return self._request("DELETE", f"/admin/business/marketing-spend/{spend_id}")

    def save_launch_market(self, payload: dict[str, Any]) -> APIResult:
        return self._request("POST", "/admin/business/markets", payload=payload)
