from __future__ import annotations

from django.contrib import messages
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect
from django.urls import NoReverseMatch, reverse

from .operator_access import CONSOLE_ACTIONS, action_allowed, refusal_message, stored_roles
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


class OperatorRoleGateMiddleware:
    """Refuse a console change the operator's role cannot make (CON-05).

    Go enforces every /v1/admin call; this only stops the console from
    sending a change Go is certain to refuse, so a mis-clicked form never
    reaches the BFF and the operator is told why. It applies to POSTs listed
    in ``operator_access.CONSOLE_ACTIONS`` when the operator's roles are
    known (resolved at login); with unknown roles Go decides, as before.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_view(self, request: HttpRequest, view_func, view_args, view_kwargs):
        if request.method != "POST":
            return None
        match = getattr(request, "resolver_match", None)
        url_name = match.url_name if match else ""
        action = CONSOLE_ACTIONS.get(url_name or "")
        if action is None:
            return None
        roles = stored_roles(getattr(request, "session", None))
        if action_allowed(roles, url_name, view_kwargs):
            return None
        messages.error(request, refusal_message(roles or []))
        try:
            target = reverse(action.back, kwargs={k: str(v) for k, v in view_kwargs.items()})
        except NoReverseMatch:
            target = reverse(action.back)
        return redirect(target)
