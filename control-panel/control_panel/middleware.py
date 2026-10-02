from __future__ import annotations

from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect
from django.urls import reverse

from .operator_context import OperatorSession, current_operator_session


class OperatorSessionMiddleware:
    """Require a BFF-issued operator session for every console page."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        login_path = reverse("operator_login")
        public_paths = {login_path, reverse("operator_logout")}
        if request.path.startswith("/static/") or request.path.startswith("/admin/"):
            return self.get_response(request)
        if request.path in public_paths:
            return self.get_response(request)

        access_token = str(request.session.get("operator_access_token") or "").strip()
        refresh_token = str(request.session.get("operator_refresh_token") or "").strip()
        if not access_token or not refresh_token:
            next_path = request.get_full_path()
            return redirect(f"{login_path}?next={next_path}")

        def update_tokens(access: str, refresh: str) -> None:
            request.session["operator_access_token"] = access
            request.session["operator_refresh_token"] = refresh
            request.session.modified = True

        def clear_tokens() -> None:
            for key in (
                "operator_access_token",
                "operator_refresh_token",
                "operator_username",
                "operator_user_id",
                "operator_roles",
            ):
                request.session.pop(key, None)
            request.session.modified = True

        token = current_operator_session.set(
            OperatorSession(
                access_token=access_token,
                refresh_token=refresh_token,
                username=str(request.session.get("operator_username") or "operator"),
                update_tokens=update_tokens,
                clear_tokens=clear_tokens,
            )
        )
        try:
            return self.get_response(request)
        finally:
            current_operator_session.reset(token)
