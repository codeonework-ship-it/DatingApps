from __future__ import annotations

from contextvars import ContextVar
from dataclasses import dataclass
from typing import Callable


@dataclass(frozen=True)
class OperatorSession:
    access_token: str
    refresh_token: str
    username: str
    update_tokens: Callable[[str, str], None]
    clear_tokens: Callable[[], None]


current_operator_session: ContextVar[OperatorSession | None] = ContextVar(
    "current_operator_session",
    default=None,
)


# Operator roles the Go BFF recognises (user_management.auth_account_roles).
# The console has no role store of its own: Go enforces every route, and the
# console mirrors these sets only to hide controls an operator cannot use.
OPERATOR_ROLE_LABELS = {
    "admin": "Admin",
    "ops_admin": "Ops admin",
    "support": "Support agent",
    "trust_safety": "Trust & Safety",
    "moderator": "Moderator",
    "analyst": "Analyst",
    "finance": "Finance",
}

# /v1/admin/support/...: these roles work tickets; analyst may only GET the
# support dashboard.
SUPPORT_MANAGE_ROLES = frozenset({"admin", "ops_admin", "support", "trust_safety", "moderator"})
SUPPORT_DASHBOARD_ROLES = SUPPORT_MANAGE_ROLES | {"analyst"}
# Roles Go lets read /v1/admin/users (the member detail page).
USER_READ_ROLES = frozenset({"admin", "ops_admin", "trust_safety", "moderator", "analyst"})
