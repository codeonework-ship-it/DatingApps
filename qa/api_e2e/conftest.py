"""Session fixtures for the API end-to-end suite.

Members are created once per run (signup journey) and retired at the end.
Each test module that mutates relationships uses its own members so modules
can run independently and in any order.
"""

from __future__ import annotations

import os
import sys

import pytest
import requests

sys.path.insert(0, os.path.dirname(__file__))

from client import API_BASE, Member, create_member, retire_member  # noqa: E402

_CREATED: list[Member] = []


def pytest_configure(config):
    config.addinivalue_line("markers", "journey(name): member journey covered by the test")


@pytest.fixture(scope="session", autouse=True)
def stack_is_up():
    try:
        health = requests.get(f"{API_BASE}/healthz", timeout=5)
    except requests.RequestException as exc:  # pragma: no cover - environment guard
        pytest.exit(f"API gateway not reachable at {API_BASE}: {exc}", returncode=3)
    if health.status_code not in (200, 401):
        pytest.exit(f"API gateway unhealthy at {API_BASE}: {health.status_code}", returncode=3)
    yield
    if os.getenv("E2E_KEEP_MEMBERS", "").lower() != "true":
        for member in _CREATED:
            retire_member(member)


@pytest.fixture(scope="session")
def make_member():
    """Factory: make_member('role', gender='F', seeking='M') -> Member."""

    def _make(role: str, gender: str = "F", seeking: str = "M") -> Member:
        member = create_member(role, gender=gender, seeking=seeking)
        _CREATED.append(member)
        return member

    return _make


@pytest.fixture(scope="module")
def pair(make_member, request):
    """A woman and a man seeking each other, unique to the calling module."""
    tag = request.module.__name__.rsplit(".", 1)[-1].replace("test_", "")[:8]
    return make_member(f"{tag}_w", "F", "M"), make_member(f"{tag}_m", "M", "F")


def pytest_terminal_summary(terminalreporter):
    from client import STATS

    terminalreporter.write_line(
        f"api-e2e: {STATS['requests']} HTTP requests, {STATS['throttled']} throttled (429) and retried")
