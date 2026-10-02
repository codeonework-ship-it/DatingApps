"""Operator console: SOS alerts and account recovery (catalog features console.safety, console.account_recovery)."""
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

ALERT = {"id": "a1b2c3d4-0000-4000-8000-000000000001", "user_id": "u9u9u9u9-0000-4000-8000-000000000009",
         "emergency_level": "sos", "latitude": 18.52, "longitude": 73.85, "triggered_at": "2026-10-02T09:15:00Z"}
RESOLVE = {"action": "decline", "identity_check": "", "resolution_note": "Could not confirm identity."}


class SafetySosTest(ConsoleCaseTest):
    def test_sos_page_shows_open_alerts_with_trigger_time(self):
        """Open alerts are listed with location, trigger time and a Resolve control; resolved ones are not counted as active.
        Regression: the trigger time rendered "—" because |date was applied to the BFF's ISO string. [case:console.safety.safety_sos.renders]"""
        self.bff().list_sos_alerts.return_value = APIResult(True, {"alerts": [
            ALERT, {**ALERT, "id": "resolved-0000", "resolved_at": "2026-10-02T09:30:00Z"}]})
        response = self.client.get(reverse("safety_sos"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "SOS Alerts")
        self.assertContains(response, "Oct 02, 2026 09:15")
        self.assertContains(response, "18.5200, 73.8500")
        self.assertContains(response, "1 active SOS alert</strong>")
        self.assertContains(response, reverse("safety_sos_resolve", args=[ALERT["id"]]))
        self.assertNotContains(response, reverse("safety_sos_resolve", args=["resolved-0000"]))

    def test_sos_page_bff_failure_shows_banner(self):
        """[case:console.safety.safety_sos.renders]"""
        self.bff().list_sos_alerts.return_value = bff_error()
        response = self.client.get(reverse("safety_sos"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")

    def test_resolve_alert(self):
        """[case:console.safety.safety_sos_resolve.performs]"""
        api = self.bff()
        response = self.client.post(reverse("safety_sos_resolve", args=[ALERT["id"]]))
        api.resolve_sos_alert.assert_called_once_with(ALERT["id"])
        self.assertRedirects(response, reverse("safety_sos"), fetch_redirect_response=False)
        self.assertIn(f"SOS alert {ALERT['id']} resolved.", flash(response))
        api.resolve_sos_alert.return_value = bff_error("alert already resolved", 409)
        self.assertIn("Failed to resolve alert: alert already resolved",
                      flash(self.client.post(reverse("safety_sos_resolve", args=[ALERT["id"]]))))

    def test_resolve_alert_authz(self):
        """[case:console.safety.safety_sos_resolve.authz]"""
        self.assert_action_authz(reverse("safety_sos_resolve", args=[ALERT["id"]]), {}, "resolve_sos_alert",
                                 refused_roles=("ops_admin", "finance", "support", "analyst"),
                                 allowed_roles=("trust_safety", "moderator"))


class AccountRecoveryTest(ConsoleCaseTest):
    def test_queue_filters_and_bff_failure(self):
        """[case:console.account_recovery.account_recovery_queue.renders]"""
        api = self.bff()
        api.list_account_recovery.return_value = APIResult(True, {"requests": [
            {"id": "req-1", "username": "member_one", "member_message": "<b>Lost phone</b>", "status": "declined",
             "created_at": "2026-09-27T10:00:00Z"}]})
        response = self.client.get(reverse("account_recovery_queue"), {"status": "declined"})
        api.list_account_recovery.assert_called_once_with(limit=25, offset=0, status="declined")
        self.assertContains(response, "&lt;b&gt;Lost phone&lt;/b&gt;")
        api.list_account_recovery.return_value = bff_error()
        failed = self.client.get(reverse("account_recovery_queue"))
        self.assertEqual(failed.status_code, 200)
        self.assertContains(failed, "couldn&#x27;t complete that request")

    def test_resolve_failure_is_reported_without_a_code(self):
        """[case:console.account_recovery.account_recovery_resolve.performs]"""
        api = self.bff()
        api.resolve_account_recovery.return_value = bff_error("identity check required to issue a code", 400)
        response = self.client.post(reverse("account_recovery_resolve", args=["req-1"]),
                                    {"action": "issue_recovery_code", "identity_check": "", "resolution_note": "Checked."})
        api.resolve_account_recovery.assert_called_once_with(
            "req-1", action="issue_recovery_code", identity_check="", resolution_note="Checked.")
        self.assertRedirects(response, reverse("account_recovery_queue"), fetch_redirect_response=False)
        self.assertIn("Could not resolve recovery request: identity check required to issue a code", flash(response))
        api.resolve_account_recovery.return_value = APIResult(True, {"status": "declined"})
        self.assertIn("Recovery request declined.", flash(self.client.post(reverse("account_recovery_resolve", args=["req-1"]), RESOLVE)))

    def test_resolve_authz(self):
        """[case:console.account_recovery.account_recovery_resolve.authz]"""
        self.assert_action_authz(reverse("account_recovery_resolve", args=["req-1"]), RESOLVE, "resolve_account_recovery",
                                 refused_roles=("ops_admin", "finance", "analyst"), allowed_roles=("trust_safety",))
