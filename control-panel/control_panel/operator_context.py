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
