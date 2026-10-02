"""Client error ingestion (self-hosted crash reporting): POST /v1/client/errors."""

from __future__ import annotations

import datetime as dt
import secrets

import pytest

from client import Api


pytestmark = pytest.mark.journey("client_errors")


def _event(**overrides):
    event = {
        "error_type": "StateError", "message": "e2e synthetic error", "stack": "#0 main (e2e.dart:1)",
        "fatal": False, "handled": True, "source": "flutter", "app_version": "1.0.0",
        "build_number": "1", "platform": "android", "os_version": "14", "device_class": "phone",
        "locale": "en-GB", "screen": "today",
        "occurred_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "breadcrumbs": [{"at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                         "category": "navigation", "message": "opened today"}],
    }
    event.update(overrides)
    return event


def _install():
    return "e2e-" + secrets.token_hex(10)


def test_anonymous_report_is_accepted():
    response = Api().post("/client/errors", {"install_id": _install(), "events": [_event()]})
    assert response.status == 202, response.text
    assert response["accepted"] == 1 and response["dropped"] == 0


def test_signed_in_report_is_accepted(make_member):
    member = make_member("ce_w", "F", "M")
    response = member.post("/client/errors", {"install_id": _install(),
                                              "events": [_event(platform="web", fatal=True)]})
    assert response.status == 202, response.text


def test_invalid_token_is_treated_as_anonymous():
    response = Api("not-a-real-token").post("/client/errors",
                                            {"install_id": _install(), "events": [_event()]})
    assert response.status == 202, response.text


@pytest.mark.parametrize("payload,why", [
    ({"events": [_event()]}, "missing install id"),
    ({"install_id": "short", "events": [_event()]}, "install id too short"),
    ({"install_id": "has spaces in it!!!!!", "events": [_event()]}, "install id charset"),
    ({"install_id": "e2e-" + "a" * 20, "events": []}, "empty batch"),
    ({"install_id": "e2e-" + "a" * 20, "events": [_event()] * 21}, "batch over 20"),
])
def test_malformed_reports_are_rejected(payload, why):
    response = Api().post("/client/errors", payload)
    assert response.status == 400, f"{why}: {response.status} {response.text}"


def test_oversized_report_is_rejected():
    response = Api().post("/client/errors", {"install_id": _install(),
                                             "events": [_event(stack="x" * 70_000)]})
    assert response.status == 413, response.text


def test_invalid_events_are_dropped_not_stored():
    response = Api().post("/client/errors", {"install_id": _install(), "events": [
        _event(), _event(platform="toaster"), _event(error_type="")]})
    assert response.status == 202, response.text
    assert response["accepted"] == 1 and response["dropped"] == 2, response.text
