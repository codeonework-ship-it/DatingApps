"""ASGI entry point: HTTP pages plus the console's live socket (/ws/live/).

``manage.py runserver`` serves this through Daphne (listed first in
INSTALLED_APPS). In production run it under an ASGI server, e.g.
``daphne control_panel_project.asgi:application``.
"""
import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "control_panel_project.settings")

# Django must be set up before anything imports models or the consumers.
django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402
from channels.sessions import SessionMiddlewareStack  # noqa: E402
from django.urls import path  # noqa: E402

from control_panel.consumers import LiveConsoleConsumer  # noqa: E402
from control_panel.live_sessions import SameOriginValidator  # noqa: E402

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        # Same-origin pages only (cross-site WebSocket hijacking), and the
        # console's own session cookie decides who the operator is.
        "websocket": SameOriginValidator(
            SessionMiddlewareStack(URLRouter([path("ws/live/", LiveConsoleConsumer.as_asgi())]))
        ),
    }
)
