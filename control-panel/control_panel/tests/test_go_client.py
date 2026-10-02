from unittest.mock import Mock

from django.test import SimpleTestCase, override_settings

from control_panel.services.go_client import GoBFFClient


def api_response(status_code, payload):
    response = Mock()
    response.status_code = status_code
    response.content = b"{}"
    response.json.return_value = payload
    return response


@override_settings(
    GO_API_BASE_URL="http://127.0.0.1:18081/v1",
    GO_HEALTH_BASE_URL="http://127.0.0.1:18081",
    GO_API_TIMEOUT_SEC=2,
)
class GoBFFClientSecurityTest(SimpleTestCase):
    def test_authenticated_request_uses_bearer_not_spoofable_admin_header(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(return_value=api_response(200, {"ok": True}))

        result = client.analytics_overview()

        self.assertTrue(result.ok)
        headers = client.session.request.call_args.kwargs["headers"]
        self.assertEqual(headers["Authorization"], "Bearer access-token")
        self.assertNotIn("X-Admin-User", headers)

    def test_expired_access_token_refreshes_and_retries_once(self):
        client = GoBFFClient(
            access_token="expired",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(
            side_effect=[
                api_response(401, {"error": "expired"}),
                api_response(200, {"metrics": {}}),
            ]
        )
        client.session.post = Mock(
            return_value=api_response(
                200,
                {"access_token": "rotated-access", "refresh_token": "rotated-refresh"},
            )
        )

        result = client.analytics_overview()

        self.assertTrue(result.ok)
        self.assertEqual(client.access_token, "rotated-access")
        retry_headers = client.session.request.call_args_list[1].kwargs["headers"]
        self.assertEqual(retry_headers["Authorization"], "Bearer rotated-access")
        self.assertEqual(client.session.request.call_count, 2)

    def test_media_content_uses_bearer_and_preserves_binary_content_type(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        response = Mock()
        response.status_code = 200
        response.content = b"\x89PNG"
        response.headers = {"Content-Type": "image/png"}
        client.session.get = Mock(return_value=response)

        result = client.get_media_moderation_content("photo-1")

        self.assertTrue(result.ok)
        self.assertEqual(result.content, b"\x89PNG")
        self.assertEqual(result.content_type, "image/png")
        headers = client.session.get.call_args.kwargs["headers"]
        self.assertEqual(headers["Authorization"], "Bearer access-token")

    def test_progression_adjustment_is_authenticated_and_idempotent(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(
            return_value=api_response(200, {"award": {"awarded_xp": 100}})
        )

        result = client.adjust_user_xp(
            "user-1", 100, "manual QA progression adjustment"
        )

        self.assertTrue(result.ok)
        request = client.session.request.call_args
        self.assertEqual(
            request.kwargs["url"],
            "http://127.0.0.1:18081/v1/admin/progression/users/user-1/adjust-xp",
        )
        self.assertEqual(request.kwargs["headers"]["Authorization"], "Bearer access-token")
        self.assertIn("Idempotency-Key", request.kwargs["headers"])

    def test_audit_event_filters_are_sent_to_secured_admin_route(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(return_value=api_response(200, {"events": []}))

        result = client.list_audit_events(
            limit=25,
            event_type="admin.request",
            actor_user_id="operator-1",
            resource_type="users",
        )

        self.assertTrue(result.ok)
        request = client.session.request.call_args.kwargs
        self.assertEqual(request["url"], "http://127.0.0.1:18081/v1/admin/audit-events")
        self.assertEqual(
            request["params"],
            {
                "limit": 25,
                "event_type": "admin.request",
                "actor_user_id": "operator-1",
                "resource_type": "users",
            },
        )
        self.assertEqual(request["headers"]["Authorization"], "Bearer access-token")

    def test_domain_event_filters_and_metrics_use_secured_admin_routes(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(return_value=api_response(200, {"events": []}))

        result = client.list_domain_events(
            limit=25,
            event_name="matching.messages.created",
            producer="matching",
            after_sequence="40",
        )

        self.assertTrue(result.ok)
        request = client.session.request.call_args.kwargs
        self.assertEqual(request["url"], "http://127.0.0.1:18081/v1/admin/events")
        self.assertEqual(
            request["params"],
            {
                "limit": 25,
                "event_name": "matching.messages.created",
                "producer": "matching",
                "after_sequence": "40",
            },
        )
        self.assertEqual(request["headers"]["Authorization"], "Bearer access-token")

        metrics = client.domain_event_metrics()
        self.assertTrue(metrics.ok)
        self.assertEqual(
            client.session.request.call_args.kwargs["url"],
            "http://127.0.0.1:18081/v1/admin/events/metrics",
        )

    def test_support_ticket_patch_is_authenticated_and_idempotent(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(
            return_value=api_response(200, {"success": True, "ticket": {"id": "ticket-1"}})
        )

        result = client.update_support_ticket(
            "ticket-1",
            {"status": "pending_member", "priority": "high", "assignee_id": ""},
        )

        self.assertTrue(result.ok)
        request = client.session.request.call_args.kwargs
        self.assertEqual(request["method"], "PATCH")
        self.assertEqual(
            request["url"],
            "http://127.0.0.1:18081/v1/admin/support/tickets/ticket-1",
        )
        self.assertEqual(request["headers"]["Authorization"], "Bearer access-token")
        self.assertIn("Idempotency-Key", request["headers"])
        self.assertEqual(
            request["json"],
            {"status": "pending_member", "priority": "high", "assignee_id": ""},
        )

    def test_support_reply_posts_message_with_visibility_and_status(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(return_value=api_response(201, {"success": True}))

        self.assertTrue(
            client.reply_support_ticket(
                "ticket-1", body="Thanks, fixed.", visibility="public", status="resolved"
            ).ok
        )
        request = client.session.request.call_args.kwargs
        self.assertEqual(request["method"], "POST")
        self.assertEqual(
            request["url"],
            "http://127.0.0.1:18081/v1/admin/support/tickets/ticket-1/messages",
        )
        self.assertIn("Idempotency-Key", request["headers"])
        self.assertEqual(
            request["json"],
            {"body": "Thanks, fixed.", "visibility": "public", "status": "resolved"},
        )

    def test_refund_operations_use_secured_idempotent_admin_routes(self):
        client = GoBFFClient(
            access_token="access-token",
            refresh_token="refresh-token",
            use_operator_context=False,
        )
        client.session.request = Mock(return_value=api_response(200, {"success": True}))

        self.assertTrue(client.reverse_gift_send("gift-1", "Member requested reversal").ok)
        gift_request = client.session.request.call_args.kwargs
        self.assertEqual(
            gift_request["url"],
            "http://127.0.0.1:18081/v1/admin/billing/gift-sends/gift-1/reverse",
        )
        self.assertEqual(gift_request["json"], {"reason": "Member requested reversal"})
        self.assertEqual(gift_request["headers"]["Authorization"], "Bearer access-token")
        self.assertIn("Idempotency-Key", gift_request["headers"])

        self.assertTrue(
            client.review_frozen_wallet(
                "user-1",
                action="write_off_and_unfreeze",
                note="Approved after reviewing the dispute evidence.",
            ).ok
        )
        wallet_request = client.session.request.call_args.kwargs
        self.assertEqual(
            wallet_request["url"],
            "http://127.0.0.1:18081/v1/admin/billing/wallets/user-1/review",
        )
        self.assertEqual(
            wallet_request["json"],
            {
                "action": "write_off_and_unfreeze",
                "note": "Approved after reviewing the dispute evidence.",
            },
        )
        self.assertIn("Idempotency-Key", wallet_request["headers"])

    def test_economy_fraud_review_uses_secured_idempotent_route(self):
        client = GoBFFClient(access_token="access-token", refresh_token="refresh-token", use_operator_context=False)
        client.session.request = Mock(return_value=api_response(200, {"status": "cleared"}))

        result = client.resolve_economy_fraud_case(
            "case-1", resolution="cleared", note="False positive confirmed from account history."
        )

        self.assertTrue(result.ok)
        request = client.session.request.call_args.kwargs
        self.assertEqual(request["url"], "http://127.0.0.1:18081/v1/admin/billing/fraud/cases/case-1/resolve")
        self.assertEqual(request["json"], {"resolution": "cleared", "note": "False positive confirmed from account history."})
        self.assertEqual(request["headers"]["Authorization"], "Bearer access-token")
        self.assertIn("Idempotency-Key", request["headers"])
