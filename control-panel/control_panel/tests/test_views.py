from unittest.mock import patch

from django.test import TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult


class DashboardViewsTest(TestCase):
    @patch("control_panel.views.GoBFFClient")
    def test_dashboard_renders(self, client_cls):
        client = client_cls.return_value
        client.health.return_value = APIResult(ok=True, data={"status": "ok"})
        client.readiness.return_value = APIResult(ok=True, data={"status": "ready"})
        client.list_verifications.return_value = APIResult(ok=True, data={"verifications": []})
        client.list_activities.return_value = APIResult(ok=True, data={"activities": []})
        client.analytics_overview.return_value = APIResult(ok=True, data={"metrics": {}})

        response = self.client.get(reverse("dashboard"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "AegisConnect Control Panel")

    @patch("control_panel.views.GoBFFClient")
    def test_approve_redirects_with_success(self, client_cls):
        client = client_cls.return_value
        client.approve_verification.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(reverse("approve_verification", kwargs={"user_id": "user-1"}))

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("verification_queue"))

    @patch("control_panel.views.GoBFFClient")
    def test_reject_requires_reason(self, client_cls):
        client = client_cls.return_value
        client.reject_verification.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(reverse("reject_verification", kwargs={"user_id": "user-1"}), {})

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("verification_queue"))
        client.reject_verification.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_appeal_queue_renders(self, client_cls):
        client = client_cls.return_value
        client.list_appeals.return_value = APIResult(ok=True, data={"appeals": []})

        response = self.client.get(reverse("appeal_queue"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Moderation Appeals Queue")

    @patch("control_panel.views.GoBFFClient")
    def test_action_appeal_redirects(self, client_cls):
        client = client_cls.return_value
        client.action_appeal.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(
            reverse("action_appeal", kwargs={"appeal_id": "apl-1"}),
            {"status": "under_review", "resolution_reason": "triage started"},
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("appeal_queue"))

