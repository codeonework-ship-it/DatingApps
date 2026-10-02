"""CON-03: raw database / runtime errors from the BFF never reach operators."""
from unittest.mock import Mock, patch

import requests
from django.test import SimpleTestCase, TestCase, override_settings
from django.urls import reverse

from control_panel.services.go_client import GoBFFClient, operator_error_message

RAW_DB_ERROR = 'SQLSTATE XX000: could not open file "base/16384/2619": Interrupted system call'
MEMBER_ID = "54120969-404d-46e4-94b1-cb40fdb96bfb"
GO_SETTINGS = dict(
    GO_API_BASE_URL="http://127.0.0.1:18081/v1",
    GO_HEALTH_BASE_URL="http://127.0.0.1:18081",
    GO_API_TIMEOUT_SEC=2,
)


def api_response(status_code, payload):
    response = Mock()
    response.status_code = status_code
    response.content = b"{}"
    response.json.return_value = payload
    return response


def operator_client():
    return GoBFFClient(access_token="access-token", refresh_token="refresh-token", use_operator_context=False)


@override_settings(**GO_SETTINGS)
class BFFErrorSanitisingTest(SimpleTestCase):
    def test_server_error_with_sql_detail_becomes_generic_and_is_logged(self):
        client = operator_client()
        client.session.request = Mock(
            return_value=api_response(500, {"error": RAW_DB_ERROR, "correlation_id": "corr-123"})
        )

        with self.assertLogs("control_panel.services.go_client", level="WARNING") as logs:
            result = client.list_users()

        self.assertFalse(result.ok)
        self.assertEqual(result.status_code, 500)
        self.assertNotIn("SQLSTATE", result.error)
        self.assertIn("The service couldn't complete that request", result.error)
        self.assertIn("ref corr-123", result.error)
        self.assertIn("SQLSTATE XX000", "\n".join(logs.output))
        self.assertIn("corr-123", "\n".join(logs.output))

    def test_actionable_client_errors_stay_readable(self):
        for status, message in (
            (400, "reason is required"),
            (403, "operator role does not permit this administrative action"),
            (404, "user not found"),
            (409, "version conflict: reload and try again"),
        ):
            with self.subTest(status=status):
                client = operator_client()
                client.session.request = Mock(return_value=api_response(status, {"error": message}))
                result = client.suspend_user(MEMBER_ID, "spam", 1)
                self.assertEqual(result.error, message)
                self.assertEqual(result.status_code, status)

    def test_client_error_that_leaks_a_database_error_is_hidden(self):
        client = operator_client()
        client.session.request = Mock(return_value=api_response(
            400, {"error": 'pq: duplicate key value violates unique constraint "coin_packages_label_key"'}
        ))

        with self.assertLogs("control_panel.services.go_client", level="WARNING"):
            result = client.create_coin_package({"label": "x"})

        self.assertNotIn("duplicate key", result.error)
        self.assertIn("The service couldn't complete that request", result.error)

    def test_transport_failure_does_not_show_hosts_or_ports(self):
        client = operator_client()
        client.session.request = Mock(side_effect=requests.ConnectionError(
            "HTTPConnectionPool(host='127.0.0.1', port=18081): Max retries exceeded"
        ))

        with self.assertLogs("control_panel.services.go_client", level="WARNING"):
            result = client.list_users()

        self.assertNotIn("127.0.0.1", result.error)
        self.assertIn("ref control-panel-", result.error)

    def test_helper_keeps_empty_client_errors_short(self):
        self.assertEqual(operator_error_message(404, ""), "request failed with 404")


@override_settings(**GO_SETTINGS)
class BFFErrorBannerTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    def test_failed_action_banner_hides_sqlstate(self):
        """[case:console.users.user_suspend.performs]"""
        failure = api_response(500, {"error": RAW_DB_ERROR, "correlation_id": "corr-456"})
        with patch("requests.Session.request", return_value=failure), \
                self.assertLogs("control_panel.services.go_client", level="WARNING"):
            response = self.client.post(
                reverse("user_suspend", args=[MEMBER_ID]), {"reason": "spam", "days": "1"}, follow=True
            )

        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, "SQLSTATE")
        self.assertContains(response, "Failed to suspend user: The service couldn&#x27;t complete that request")
        self.assertContains(response, "ref corr-456")
