"""Operator console: Support tickets — role gate and remaining authz cases (catalog feature console.support).

The broader support behaviour is in test_support.py; tests there carry their own case tags.
"""
import json

from django.test import Client
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash, login

TICKET = "11111111-1111-4111-8111-111111111111"
OTHER = "22222222-2222-4222-8222-222222222222"
CANNED = "66666666-6666-4666-8666-666666666666"
SUPPORT = "control_panel.views_support"


class SupportRoleGateTest(ConsoleCaseTest):
    module = SUPPORT

    def test_bulk_authz(self):
        """[case:console.support.support_bulk.authz]"""
        self.assert_action_authz(reverse("support_bulk"), {"ticket_ids": [TICKET], "action": "claim"}, "bulk_support_tickets",
                                 refused_roles=("analyst", "finance"), allowed_roles=("support", "moderator"), module=SUPPORT)

    def test_canned_save_authz(self):
        """[case:console.support.support_canned_save.authz]"""
        self.assert_action_authz(reverse("support_canned_save"), {"title": "Refund", "body": "Hi"}, "create_support_canned_response",
                                 refused_roles=("analyst", "finance"), allowed_roles=("support",), module=SUPPORT)

    def test_canned_deactivate_authz(self):
        """[case:console.support.support_canned_deactivate.authz]"""
        self.assert_action_authz(reverse("support_canned_deactivate", args=[CANNED]), {}, "deactivate_support_canned_response",
                                 refused_roles=("analyst",), allowed_roles=("ops_admin",), module=SUPPORT)

    def test_reply_authz(self):
        """[case:console.support.support_ticket_reply.authz]"""
        self.assert_action_authz(reverse("support_ticket_reply", args=[TICKET]), {"body": "Hello", "visibility": "public"},
                                 "reply_support_ticket", refused_roles=("analyst", "finance"), allowed_roles=("support", "trust_safety"),
                                 module=SUPPORT)

    def test_update_authz(self):
        """[case:console.support.support_ticket_update.authz]"""
        self.assert_action_authz(reverse("support_ticket_update", args=[TICKET]), {"status": "resolved", "orig_status": "open"},
                                 "update_support_ticket", refused_roles=("analyst",), allowed_roles=("support",), module=SUPPORT)

    def test_claim_authz(self):
        """[case:console.support.support_ticket_claim.authz]"""
        self.assert_action_authz(reverse("support_ticket_claim", args=[TICKET]), {}, "claim_support_ticket",
                                 refused_roles=("analyst", "finance"), allowed_roles=("support",), module=SUPPORT)

    def test_merge_authz(self):
        """[case:console.support.support_ticket_merge.authz]"""
        self.assert_action_authz(reverse("support_ticket_merge", args=[TICKET]), {"into": OTHER, "confirm": "on"}, "merge_support_ticket",
                                 refused_roles=("analyst", "finance"), allowed_roles=("support", "moderator"), module=SUPPORT)

    def test_merge_needs_confirmation_and_reports_failure(self):
        """[case:console.support.support_ticket_merge.performs]"""
        api = self.bff()
        url = reverse("support_ticket_merge", args=[TICKET])
        self.assertTrue(any("Tick the confirmation box" in m for m in flash(self.client.post(url, {"into": OTHER}))))
        api.merge_support_ticket.assert_not_called()
        api.merge_support_ticket.return_value = bff_error("The service couldn't complete that request.", 502)
        response = self.client.post(url, {"into": OTHER, "confirm": "on"})
        self.assertRedirects(response, reverse("support_ticket_detail", args=[TICKET]), fetch_redirect_response=False)
        self.assertTrue(any(m.startswith("Merge failed:") for m in flash(response)))


class SupportCannedPreviewAuthzTest(ConsoleCaseTest):
    module = SUPPORT

    def test_preview_is_read_only_and_operator_only(self):
        """Anonymous callers are sent to login, POST is refused, and a role Go refuses gets its 403 as JSON (never a 500).
        [case:console.support.support_canned_preview.authz]"""
        api = self.bff()
        url = reverse("support_canned_preview", args=[TICKET, CANNED])
        anonymous = Client().get(url)
        self.assertEqual(anonymous.status_code, 302)
        self.assertTrue(anonymous["Location"].startswith("/login/"))
        self.assertEqual(self.client.post(url).status_code, 405)
        api.preview_support_canned_response.assert_not_called()
        api.preview_support_canned_response.return_value = APIResult(False, {}, "operator role does not permit this administrative action", 403)
        response = login(Client(), roles=["analyst"]).get(url)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(json.loads(response.content), {"error": "operator role does not permit this administrative action"})
        api.preview_support_canned_response.return_value = APIResult(False, {}, "boom", 500)
        self.assertEqual(self.client.get(url).status_code, 502)

    def test_preview_returns_rendered_body(self):
        """[case:console.support.support_canned_preview.performs]"""
        api = self.bff()
        api.preview_support_canned_response.return_value = APIResult(True, {"body": "Hi <Priya>"})
        response = self.client.get(reverse("support_canned_preview", args=[TICKET, CANNED]))
        self.assertEqual(json.loads(response.content), {"body": "Hi <Priya>"})
        self.assertEqual(response["Content-Type"], "application/json")


class SupportPagesUpstreamFailureTest(ConsoleCaseTest):
    module = SUPPORT

    def test_queue_detail_dashboard_and_canned_map_go_5xx_to_502(self):
        """Regression: a Go 500 made the support pages answer 500; they now answer 502 with the banner.
        [case:console.support.support_queue.renders] [case:console.support.support_ticket_detail.renders]
        [case:console.support.support_dashboard.renders] [case:console.support.support_canned_responses.renders]"""
        api = self.bff()
        failure = bff_error("The service couldn't complete that request.", 500)
        api.list_support_tickets.return_value = failure
        api.get_support_ticket.return_value = failure
        api.support_dashboard.return_value = failure
        api.list_support_canned_responses.return_value = failure
        for url in (reverse("support_queue"), reverse("support_ticket_detail", args=[TICKET]),
                    reverse("support_dashboard"), reverse("support_canned_responses")):
            with self.subTest(url):
                response = self.client.get(url)
                self.assertEqual(response.status_code, 502)
                self.assertContains(response, "couldn&#x27;t complete that request", status_code=502)

    def test_attachment_and_export_go_5xx_is_502(self):
        """[case:console.support.support_attachment.renders] [case:console.support.support_export.renders]"""
        from control_panel.services.go_client import StreamAPIResult

        api = self.bff()
        api.support_attachment_content.return_value = StreamAPIResult(False, error="boom", status_code=500)
        self.assertEqual(self.client.get(reverse("support_attachment", args=[TICKET])).status_code, 502)
        api.export_support_tickets.return_value = StreamAPIResult(False, error="boom", status_code=500)
        response = self.client.get(reverse("support_export"), {"status": "open"})
        self.assertRedirects(response, reverse("support_queue") + "?status=open&sort=sla", fetch_redirect_response=False)
        self.assertTrue(any(m.startswith("CSV export failed:") for m in flash(response)))
