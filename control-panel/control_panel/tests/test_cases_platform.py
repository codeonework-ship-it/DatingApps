"""Operator console: sign-in/out, command center, feature flags, growth governance and logs
(catalog features console.login, console.logout, console.dashboard, console.config, console.growth,
console.activities, console.audit, console.events, console.client_errors)."""
from unittest.mock import patch

from django.test import Client
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import AutoOKClient, ConsoleCaseTest, bff_error, flash, login

TOKENS = APIResult(True, {"access_token": "new-access", "refresh_token": "new-refresh", "user_id": "operator-1"}, status_code=200)


class OperatorLoginTest(ConsoleCaseTest):
    def setUp(self):  # anonymous by default here
        pass

    def test_login_signs_in_and_honours_safe_next(self):
        """A BFF-accepted operator gets a fresh session (key cycled, tokens stored) and lands on a same-site next only.
        [case:console.login.operator_login.performs]"""
        api = self.bff()
        api.login.return_value = TOKENS
        api.support_agents.return_value = APIResult(True, {"agents": [{"id": "operator-1", "roles": ["moderator"]}]})
        api.analytics_definitions.return_value = APIResult(False, {}, "forbidden", 403)
        api.list_coin_packages.return_value = APIResult(False, {}, "forbidden", 403)
        anonymous_key = self.client.session.session_key
        response = self.client.post(reverse("operator_login"), {"username": " Mod_One ", "password": "pw", "next": "/moderation/reports/"})
        self.assertRedirects(response, "/moderation/reports/", fetch_redirect_response=False)
        api.login.assert_called_once_with("mod_one", "pw")
        session = self.client.session
        self.assertEqual(session["operator_access_token"], "new-access")
        self.assertEqual(session["operator_user_id"], "operator-1")
        self.assertEqual(session["operator_roles"], ["moderator"])
        self.assertNotEqual(session.session_key, anonymous_key)
        other = Client()
        response = other.post(reverse("operator_login"), {"username": "mod_one", "password": "pw", "next": "//evil.example/x"})
        self.assertRedirects(response, "/", fetch_redirect_response=False)

    def test_login_refusals(self):
        """Wrong password and non-operator accounts get no session; the form needs a CSRF token; GET renders it.
        [case:console.login.operator_login.authz]"""
        api = self.bff()
        page = self.client.get(reverse("operator_login"))
        self.assertContains(page, 'name="password"')
        api.login.return_value = APIResult(False, {}, "invalid username or password", 401)
        response = self.client.post(reverse("operator_login"), {"username": "x", "password": "bad"})
        self.assertContains(response, "invalid username or password")
        self.assertNotIn("operator_access_token", self.client.session)
        api.login.return_value = TOKENS
        api.analytics_overview.return_value = APIResult(False, {}, "operator role does not permit this administrative action", 403)
        response = self.client.post(reverse("operator_login"), {"username": "member", "password": "pw"})
        self.assertContains(response, "does not have permission to use the operator console")
        self.assertNotIn("operator_access_token", self.client.session)
        self.assertEqual(Client(enforce_csrf_checks=True).post(reverse("operator_login"), {"username": "x", "password": "y"}).status_code, 403)
        self.assertEqual(self.client.put(reverse("operator_login")).status_code, 405)


class OperatorLogoutTest(ConsoleCaseTest):
    def test_logout_revokes_and_flushes(self):
        """[case:console.logout.operator_logout.performs]"""
        api = self.bff()
        response = self.client.post(reverse("operator_logout"))
        api.logout.assert_called_once_with()
        self.assertRedirects(response, reverse("operator_login"), fetch_redirect_response=False)
        self.assertNotIn("operator_access_token", self.client.session)
        self.assertEqual(self.client.get(reverse("dashboard")).status_code, 302)

    def test_logout_needs_a_csrf_protected_post(self):
        """Regression: GET /logout/ signed the operator out, so any page linking or redirecting there could end a session.
        [case:console.logout.operator_logout.authz]"""
        api = self.bff()
        self.assertEqual(self.client.get(reverse("operator_logout")).status_code, 405)
        self.assertIn("operator_access_token", self.client.session)
        csrf_client = login(Client(enforce_csrf_checks=True))
        self.assertEqual(csrf_client.post(reverse("operator_logout")).status_code, 403)
        self.assertIn("operator_access_token", csrf_client.session)
        api.logout.assert_not_called()
        anonymous = Client().post(reverse("operator_logout"))
        self.assertRedirects(anonymous, reverse("operator_login"), fetch_redirect_response=False)
        api.logout.assert_not_called()


class CommandCenterTest(ConsoleCaseTest):
    def test_dashboard_survives_a_full_bff_outage(self):
        """Every read failing still renders the command center with unavailable states (never zeros or a 500).
        [case:console.dashboard.dashboard.renders]"""
        api = self.bff()
        for name in ("health", "readiness", "list_verifications", "list_activities", "analytics_overview", "list_users",
                     "list_reports", "list_appeals", "list_media_moderation", "list_sos_alerts", "list_audit_events",
                     "list_domain_events", "domain_event_metrics", "analytics_report", "support_dashboard"):
            getattr(api, name).return_value = bff_error()
        response = self.client.get(reverse("dashboard"), {"refresh": "7"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Operations command center")
        self.assertContains(response, "UNAVAILABLE")
        self.assertTrue(response.context["live_updates"])
        self.assertFalse(any(m["available"] for m in response.context["headline_metrics"][:2]))
        self.assertEqual(Client().get(reverse("dashboard")).status_code, 302)


class FeatureFlagsTest(ConsoleCaseTest):
    def test_flags_render(self):
        """[case:console.config.config_flags.renders]"""
        api = self.bff()
        api.list_config_flags.return_value = APIResult(True, {"flags": [
            {"key": "support_ticketing_enabled", "value_bool": True, "description": "<b>Tickets</b>", "updated_at": "2026-10-01T09:30:00Z"},
            {"key": "gifts_enabled", "value_bool": False}]})
        response = self.client.get(reverse("config_flags"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Feature Flags")
        self.assertContains(response, "&lt;b&gt;Tickets&lt;/b&gt;")
        self.assertContains(response, "Oct 01 09:30")
        self.assertContains(response, reverse("config_flag_toggle", args=["support_ticketing_enabled"]))
        api.list_config_flags.return_value = bff_error()
        self.assertContains(self.client.get(reverse("config_flags")), "alert-glass warning")

    def test_toggle_records_the_operator(self):
        """Regression: every flag change was stored as updated_by="admin"; the signed-in operator is now sent.
        [case:console.config.config_flag_toggle.performs]"""
        api = self.bff()
        response = self.client.post(reverse("config_flag_toggle", args=["gifts_enabled"]), {"value": "1"})
        api.update_config_flag.assert_called_once_with("gifts_enabled", True, updated_by="console_admin")
        self.assertRedirects(response, reverse("config_flags"), fetch_redirect_response=False)
        self.assertIn("Flag 'gifts_enabled' enabled.", flash(response))
        response = self.client.post(reverse("config_flag_toggle", args=["gifts_enabled"]), {"value": "0"})
        self.assertIn("Flag 'gifts_enabled' disabled.", flash(response))
        api.update_config_flag.return_value = bff_error("admin repository unavailable", 503)
        self.assertIn("Failed to update flag 'gifts_enabled': admin repository unavailable",
                      flash(self.client.post(reverse("config_flag_toggle", args=["gifts_enabled"]), {"value": "1"})))

    def test_toggle_authz(self):
        """[case:console.config.config_flag_toggle.authz]"""
        self.assert_action_authz(reverse("config_flag_toggle", args=["gifts_enabled"]), {"value": "1"}, "update_config_flag",
                                 refused_roles=("trust_safety", "analyst", "finance"), allowed_roles=("ops_admin",))


class GrowthGovernanceTest(ConsoleCaseTest):
    def test_register_renders_and_failure_banner(self):
        """[case:console.growth.growth_governance.renders]"""
        api = self.bff()
        api.growth_portfolio.return_value = APIResult(True, {"modules": [
            {"key": "referrals", "name": "<b>Referrals</b>", "lifecycle": "deferred", "risk_tier": "high", "owner": "growth", "blocker": "fraud graph"}]})
        api.list_growth_fraud_graph.return_value = APIResult(True, {"edges": []})
        response = self.client.get(reverse("growth_governance"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "P2 launch register")
        self.assertContains(response, "&lt;b&gt;Referrals&lt;/b&gt;")
        api.list_growth_fraud_graph.assert_called_once_with(status="open", limit=100)
        api.growth_portfolio.return_value = bff_error("portfolio unavailable", 503)
        failed = self.client.get(reverse("growth_governance"))
        self.assertEqual(failed.status_code, 200)
        self.assertContains(failed, "portfolio unavailable")


class LogPagesTest(ConsoleCaseTest):
    def test_activity_feed_bounds_limit_and_shows_failure(self):
        """[case:console.activities.activity_feed.renders]"""
        api = self.bff()
        self.client.get(reverse("activity_feed"), {"limit": "99999"})
        api.list_activities.assert_called_with(limit=1000)
        api.list_activities.return_value = bff_error()
        response = self.client.get(reverse("activity_feed"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")

    def test_audit_log_failure_banner(self):
        """[case:console.audit.audit_log.renders]"""
        self.bff().list_audit_events.return_value = bff_error("audit store unavailable", 503)
        response = self.client.get(reverse("audit_log"), {"limit": "0"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "audit store unavailable")
        self.bff().list_audit_events.assert_called_once_with(limit=1, event_type="", actor_user_id="", subject_user_id="", resource_type="")

    def test_domain_events_failure_banner(self):
        """[case:console.events.domain_events.renders]"""
        api = self.bff()
        api.list_domain_events.return_value = bff_error("outbox unavailable", 503)
        response = self.client.get(reverse("domain_events"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "outbox unavailable")


class ClientErrorStatusAuthzTest(ConsoleCaseTest):
    module = "control_panel.views_client_errors"

    def test_status_change_role_gate(self):
        """Analysts may read client errors but only ops_admin/admin change their status; the console refuses before Go.
        [case:console.client_errors.client_error_status.authz]"""
        issue = "11111111-1111-1111-1111-111111111111"
        self.assert_action_authz(reverse("client_error_status", args=[issue]), {"status": "resolved"}, "set_client_error_status",
                                 refused_roles=("analyst", "trust_safety", "support"), allowed_roles=("ops_admin",),
                                 module=self.module)

    def test_list_and_detail_upstream_5xx_is_502(self):
        """[case:console.client_errors.client_errors.renders] [case:console.client_errors.client_error_detail.renders]"""
        api = self.bff()
        api.list_client_errors.return_value = bff_error("The service couldn't complete that request.", 500)
        self.assertEqual(self.client.get(reverse("client_errors")).status_code, 502)
        api.get_client_error.return_value = bff_error("The service couldn't complete that request.", 500)
        self.assertEqual(self.client.get(reverse("client_error_detail", args=["11111111-1111-1111-1111-111111111111"])).status_code, 502)
