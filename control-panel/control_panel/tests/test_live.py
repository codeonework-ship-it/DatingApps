"""The live console socket (/ws/live/): who may connect, what is pushed,
and that signing out closes it."""
from __future__ import annotations

from importlib import import_module
from unittest.mock import patch

from asgiref.sync import sync_to_async
from channels.testing import WebsocketCommunicator
from django.conf import settings
from django.test import Client, TransactionTestCase
from django.urls import reverse

from control_panel import consumers
from control_panel.operator_context import current_operator_session
from control_panel.services.go_client import APIResult
from control_panel_project.asgi import application

from .case_support import AutoOKClient, login

SessionStore = import_module(settings.SESSION_ENGINE).SessionStore


def _bff() -> AutoOKClient:
    api = AutoOKClient()
    api.health.return_value = APIResult(True, {"status": "ok"})
    api.list_reports.return_value = APIResult(True, {"reports": [
        {"id": "r1", "status": "pending", "created_at": "2020-01-01T00:00:00Z"},
        {"id": "r2", "status": "resolved", "created_at": "2020-01-01T00:00:00Z"},
    ]})
    api.list_sos_alerts.return_value = APIResult(True, {"alerts": [
        {"id": "s1", "status": "active", "triggered_at": "2099-01-01T00:00:00Z"},
    ]})
    return api


class LiveSocketBase(TransactionTestCase):
    """Session, BFF stub and socket helpers for live-socket tests."""

    def setUp(self):
        consumers._recent.clear()
        self.api = _bff()
        patcher = patch("control_panel.consumers.GoBFFClient", return_value=self.api)
        patcher.start()
        self.addCleanup(patcher.stop)

    def _session(self, roles=None) -> tuple[Client, str]:
        client = login(Client(), roles=roles)
        return client, client.session.session_key

    def _socket(self, session_key: str | None, origin: bytes = b"http://testserver") -> WebsocketCommunicator:
        headers = [(b"origin", origin), (b"host", b"testserver")]
        if session_key:
            headers.append((b"cookie", f"{settings.SESSION_COOKIE_NAME}={session_key}".encode()))
        return WebsocketCommunicator(application, "/ws/live/", headers=headers)

    async def _subscribe(self, socket, *topics):
        connected, _ = await socket.connect()
        self.assertTrue(connected)
        await socket.send_json_to({"type": "subscribe", "topics": list(topics)})


class LiveSocketTest(LiveSocketBase):

    async def test_signed_out_visitors_are_refused(self):
        """No console session, no socket. [case:console.live.socket.requires_session]"""
        socket = self._socket(None)
        connected, code = await socket.connect()
        self.assertFalse(connected)
        self.assertEqual(code, consumers.SIGNED_OUT)

    async def test_other_sites_cannot_open_the_socket(self):
        """A page on another origin is refused even with the cookie. [case:console.live.socket.same_origin_only]"""
        _, key = await sync_to_async(self._session)()
        connected, _ = await self._socket(key, origin=b"https://evil.example").connect()
        self.assertFalse(connected)

    async def test_nav_counts_open_items_and_the_bff_state(self):
        """The sidebar topic counts open queue items. [case:console.live.nav.counts]"""
        _, key = await sync_to_async(self._session)()
        socket = self._socket(key)
        await self._subscribe(socket, "nav", "not-a-topic")
        message = await socket.receive_json_from(timeout=5)
        self.assertEqual(message["type"], "topic")
        self.assertEqual(message["topic"], "nav")
        data = message["data"]
        self.assertTrue(data["bff_ok"])
        self.assertEqual(data["queues"]["moderation_reports"]["count"], 1)
        self.assertEqual(data["queues"]["moderation_reports"]["overdue"], 1)
        self.assertEqual(data["sos_open_ids"], ["s1"])
        # Nothing changed: a refresh pushes nothing.
        await socket.send_json_to({"type": "refresh"})
        self.assertTrue(await socket.receive_nothing(timeout=1))
        await socket.disconnect()

    async def test_nav_reads_only_what_the_role_may_see(self):
        """A finance operator's socket never reads moderation queues. [case:console.live.nav.role_scoped]"""
        _, key = await sync_to_async(self._session)(roles=["finance"])
        socket = self._socket(key)
        await self._subscribe(socket, "nav")
        data = (await socket.receive_json_from(timeout=5))["data"]
        self.assertNotIn("moderation_reports", data["queues"])
        self.api.list_reports.assert_not_called()
        self.api.list_sos_alerts.assert_not_called()
        await socket.disconnect()

    async def test_dashboard_region_is_pushed_as_rendered_html(self):
        """The command center's live region arrives rendered. [case:console.live.dashboard.pushes_region]"""
        _, key = await sync_to_async(self._session)()
        socket = self._socket(key)
        await self._subscribe(socket, "dashboard")
        message = await socket.receive_json_from(timeout=10)
        self.assertEqual(message["topic"], "dashboard")
        self.assertIn("SLA watch", message["data"]["html"])
        self.assertTrue(message["data"]["stamp"].startswith("Snapshot "))
        await socket.disconnect()

    async def test_a_hidden_tab_reads_nothing(self):
        """Paused sockets make no BFF reads. [case:console.live.socket.pauses_when_hidden]"""
        _, key = await sync_to_async(self._session)()
        socket = self._socket(key)
        connected, _ = await socket.connect()
        self.assertTrue(connected)
        await socket.send_json_to({"type": "pause"})
        await socket.send_json_to({"type": "subscribe", "topics": ["nav"]})
        self.assertTrue(await socket.receive_nothing(timeout=1))
        self.api.health.assert_not_called()
        await socket.send_json_to({"type": "resume"})
        self.assertEqual((await socket.receive_json_from(timeout=5))["topic"], "nav")
        await socket.disconnect()

    async def test_signing_out_closes_every_socket_of_the_session(self):
        """Sign out in one tab ends the live socket in all of them. [case:console.live.socket.closed_on_sign_out]"""
        client, key = await sync_to_async(self._session)()
        socket = self._socket(key)
        await self._subscribe(socket, "nav")
        await socket.receive_json_from(timeout=5)
        with patch("control_panel.views.GoBFFClient", return_value=AutoOKClient()):
            response = await sync_to_async(client.post)(reverse("operator_logout"))
        self.assertEqual(response.status_code, 302)
        self.assertEqual(await socket.receive_json_from(timeout=5), {"type": "signed_out"})
        self.assertEqual((await socket.receive_output(timeout=5))["code"], consumers.SIGNED_OUT)

    async def test_a_session_go_ended_signs_the_page_out(self):
        """Go refusing the refresh ends the socket too. [case:console.live.socket.go_session_ended]"""
        def ended(*args, **kwargs):
            current_operator_session.get().clear_tokens()
            return self.api

        _, key = await sync_to_async(self._session)()
        with patch("control_panel.consumers.GoBFFClient", side_effect=ended):
            socket = self._socket(key)
            await self._subscribe(socket, "nav")
            self.assertEqual(await socket.receive_json_from(timeout=5), {"type": "signed_out"})

    async def test_refreshed_tokens_are_saved_to_the_session(self):
        """Tokens Go rotates during a live read reach the page's session. [case:console.live.socket.saves_rotated_tokens]"""
        def rotating(*args, **kwargs):
            current_operator_session.get().update_tokens("access-2", "refresh-2")
            return self.api

        _, key = await sync_to_async(self._session)()
        with patch("control_panel.consumers.GoBFFClient", side_effect=rotating):
            socket = self._socket(key)
            await self._subscribe(socket, "nav")
            await socket.receive_json_from(timeout=5)
            await socket.disconnect()
        store = await sync_to_async(SessionStore)(session_key=key)
        self.assertEqual(await sync_to_async(store.get)("operator_access_token"), "access-2")
        self.assertEqual(await sync_to_async(store.get)("operator_refresh_token"), "refresh-2")
