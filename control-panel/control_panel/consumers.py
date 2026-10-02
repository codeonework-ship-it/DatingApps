"""The console's live socket (``/ws/live/``), served on asyncio by Channels.

A page opens one socket and subscribes to topics (``live.TOPICS``). While the
page is visible, the consumer re-reads each topic on its interval with the
operator's own BFF session and pushes it only when something changed. A hidden
tab pauses reads. Signing out, in any tab, closes every socket of that
session at once (``end_session_sockets``).

The BFF client is synchronous (requests), so reads run in worker threads;
session reads and writes go through the database thread. Reads are shared for
a moment between the tabs of one session, so ten open tabs cost one read.
"""
from __future__ import annotations

import asyncio
import logging
import time
from importlib import import_module
from typing import Any

from asgiref.sync import sync_to_async
from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.conf import settings
from django.contrib.sessions.backends.base import SessionBase

from . import live
from .live_sessions import session_group
from .operator_access import stored_roles
from .operator_context import OperatorSession, current_operator_session
from .services.go_client import GoBFFClient

logger = logging.getLogger(__name__)

SIGNED_OUT = 4401  # close code the page treats as "go to sign-in"
MIN_REFRESH_GAP_SECONDS = 3

# (session group, topic) -> (monotonic time read, payload); shared by tabs.
_recent: dict[tuple[str, str], tuple[float, dict]] = {}


class LiveConsoleConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self) -> None:
        session: SessionBase | None = self.scope.get("session")
        self.session_key = getattr(session, "session_key", None) or ""
        self.store_class = import_module(settings.SESSION_ENGINE).SessionStore
        self.topics: set[str] = set()
        self.paused = False
        self.wake = asyncio.Event()
        self.next_due: dict[str, float] = {}
        self.sent: dict[str, str] = {}
        self.last_refresh = 0.0
        self.task: asyncio.Task | None = None
        if not self.session_key or await self._load() is None:
            await self.close(code=SIGNED_OUT)
            return
        self.group = session_group(self.session_key)
        if self.channel_layer is not None:
            await self.channel_layer.group_add(self.group, self.channel_name)
        await self.accept()

    async def disconnect(self, code: int) -> None:
        if self.task is not None:
            self.task.cancel()
        if getattr(self, "group", None) and self.channel_layer is not None:
            await self.channel_layer.group_discard(self.group, self.channel_name)

    async def receive_json(self, content: Any, **kwargs) -> None:
        if not isinstance(content, dict):
            return
        kind = content.get("type")
        if kind == "subscribe":
            requested = content.get("topics")
            self.topics = {t for t in requested if t in live.TOPICS} if isinstance(requested, list) else set()
            self.next_due = {t: 0.0 for t in self.topics}
            self.sent = {t: v for t, v in self.sent.items() if t in self.topics}
            if self.task is None:
                self.task = asyncio.create_task(self._run())
        elif kind == "pause":
            self.paused = True
        elif kind == "resume":
            self.paused = False
        elif kind == "refresh":
            now = time.monotonic()
            if now - self.last_refresh < MIN_REFRESH_GAP_SECONDS:
                return
            self.last_refresh = now
            self.next_due = {t: 0.0 for t in self.topics}
            for topic in self.topics:
                _recent.pop((self.group, topic), None)
        else:
            return
        self.wake.set()

    async def session_ended(self, event: dict) -> None:
        await self._signed_out()

    # ── Read loop ─────────────────────────────────────────────────────────

    async def _run(self) -> None:
        try:
            while True:
                now = time.monotonic()
                due = [t for t in self.topics if self.next_due.get(t, 0.0) <= now]
                if due and not self.paused:
                    if not await self._push(due):
                        return
                    after = time.monotonic()
                    for topic in due:
                        self.next_due[topic] = after + live.INTERVAL_SECONDS[topic]
                waits = [d - time.monotonic() for d in self.next_due.values()] or [60.0]
                timeout = 60.0 if self.paused else max(1.0, min(waits))
                self.wake.clear()
                try:
                    await asyncio.wait_for(self.wake.wait(), timeout=timeout)
                except TimeoutError:
                    pass
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("live console loop stopped")
            await self.close(code=1011)

    async def _push(self, due: list[str]) -> bool:
        """Reads and sends the due topics. False when the session is over."""
        payloads: dict[str, dict] = {}
        stale: list[str] = []
        now = time.monotonic()
        for topic in due:
            cached = _recent.get((self.group, topic))
            if cached and now - cached[0] < live.INTERVAL_SECONDS[topic] - 1:
                payloads[topic] = cached[1]
            else:
                stale.append(topic)
        if stale:
            state = await self._load()
            if state is None:
                await self._signed_out()
                return False
            fresh, tokens, cleared = await sync_to_async(_read, thread_sensitive=False)(state, stale)
            if cleared:
                await self._signed_out()
                return False
            if tokens:
                await self._save_tokens(*tokens)
            read_at = time.monotonic()
            for key in [k for k, (at, _) in _recent.items() if read_at - at > 300]:
                _recent.pop(key, None)
            for topic, payload in fresh.items():
                _recent[(self.group, topic)] = (read_at, payload)
                payloads[topic] = payload
        for topic, payload in payloads.items():
            mark = live.fingerprint(topic, payload)
            if self.sent.get(topic) == mark:
                continue
            self.sent[topic] = mark
            await self.send_json({"type": "topic", "topic": topic, "data": payload})
        return True

    async def _signed_out(self) -> None:
        for topic in live.TOPICS:
            _recent.pop((getattr(self, "group", ""), topic), None)
        try:
            await self.send_json({"type": "signed_out"})
        finally:
            await self.close(code=SIGNED_OUT)

    # ── Session store (fresh on every read: another tab may have signed
    #    out or refreshed the tokens) ──────────────────────────────────────

    @database_sync_to_async
    def _load(self) -> dict | None:
        store = self.store_class(session_key=self.session_key)
        access = str(store.get("operator_access_token") or "").strip()
        refresh = str(store.get("operator_refresh_token") or "").strip()
        if not access or not refresh:
            return None
        return {
            "access": access,
            "refresh": refresh,
            "username": str(store.get("operator_username") or "operator"),
            "roles": stored_roles(store),
        }

    @database_sync_to_async
    def _save_tokens(self, access: str, refresh: str) -> None:
        store = self.store_class(session_key=self.session_key)
        if not store.get("operator_access_token"):
            return  # signed out meanwhile
        store["operator_access_token"] = access
        store["operator_refresh_token"] = refresh
        store.save()


def _read(state: dict, topics: list[str]) -> tuple[dict[str, dict], tuple[str, str] | None, bool]:
    """Runs in a worker thread: the BFF reads for ``topics`` as this operator.
    Returns (payloads, refreshed tokens or None, whether Go ended the session)."""
    rotated: list[tuple[str, str]] = []
    ended: list[bool] = []
    reset = current_operator_session.set(
        OperatorSession(
            access_token=state["access"],
            refresh_token=state["refresh"],
            username=state["username"],
            update_tokens=lambda access, refresh: rotated.append((access, refresh)),
            clear_tokens=lambda: ended.append(True),
        )
    )
    try:
        client = GoBFFClient()
        payloads: dict[str, dict] = {}
        for topic in topics:
            try:
                payloads[topic] = live.build(topic, client, state["roles"])
            except Exception:
                logger.exception("live topic %s failed", topic)
            if ended:
                break
        return payloads, (rotated[-1] if rotated else None), bool(ended)
    finally:
        current_operator_session.reset(reset)
