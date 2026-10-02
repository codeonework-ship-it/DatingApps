"""Live console sockets: one channel-layer group per console session, and the
same-origin check every socket passes before it reaches the consumer."""
from __future__ import annotations

import hashlib
import logging
from urllib.parse import urlsplit

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings

logger = logging.getLogger(__name__)


def session_group(session_key: str) -> str:
    """Channel-layer group of every live socket of one console session."""
    return "op-session." + hashlib.sha256(session_key.encode()).hexdigest()[:32]


def end_session_sockets(session_key: str | None) -> None:
    """Close every live socket of this session (called on sign-out)."""
    layer = get_channel_layer()
    if not session_key or layer is None:
        return
    try:
        async_to_sync(layer.group_send)(session_group(session_key), {"type": "session.ended"})
    except Exception:  # sign-out must never fail because of the socket layer
        logger.warning("could not notify live sockets of sign-out", exc_info=True)


class SameOriginValidator:
    """Refuses a WebSocket whose Origin is not the console itself.

    Channels' AllowedHostsOriginValidator accepts any origin when
    ALLOWED_HOSTS is "*" (the local default), which would let another site's
    page open a socket with the operator's cookie. Here the Origin must name
    the host the socket was opened on, or be listed in CSRF_TRUSTED_ORIGINS.
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "websocket" and not self.allowed(scope):
            await receive()  # websocket.connect
            await send({"type": "websocket.close", "code": 4403})
            return None
        return await self.app(scope, receive, send)

    @staticmethod
    def allowed(scope) -> bool:
        headers = dict(scope.get("headers") or [])
        origin = headers.get(b"origin", b"").decode("latin1").strip().lower()
        host = headers.get(b"host", b"").decode("latin1").strip().lower()
        if not origin or origin == "null":
            return False
        if origin in {o.strip().lower().rstrip("/") for o in getattr(settings, "CSRF_TRUSTED_ORIGINS", [])}:
            return True
        parts = urlsplit(origin)
        return bool(host) and parts.scheme in {"http", "https"} and parts.netloc == host
