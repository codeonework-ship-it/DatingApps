"""The console-side role gate (OperatorRoleGateMiddleware, CONSOLE_ACTIONS)."""
from unittest.mock import patch

from django.test import Client, SimpleTestCase, TestCase
from django.urls import URLPattern, URLResolver, get_resolver, reverse

from control_panel.operator_access import CONSOLE_ACTIONS, action_allowed, can_access_admin_route
from control_panel.services.go_client import APIResult, GoBFFClient
from control_panel.tests.case_support import AutoOKClient, flash, login

# Console routes that accept POST but change nothing in Go's admin API.
NOT_ADMIN_CHANGES = {"operator_login", "operator_logout"}


def _console_patterns(patterns=None, prefix=""):
    """Every named URLPattern under the console's URLconf (includes flattened)."""
    for pattern in get_resolver().url_patterns if patterns is None else patterns:
        if isinstance(pattern, URLResolver):
            if getattr(pattern, "app_name", None) == "admin" or "admin" in str(pattern.pattern):
                continue
            yield from _console_patterns(pattern.url_patterns)
        elif isinstance(pattern, URLPattern) and pattern.name:
            yield pattern


class ConsoleActionTableTest(SimpleTestCase):
    def test_every_console_change_is_in_the_gate_table(self):
        """Every POST-accepting console route is mapped to the BFF call it makes, so a new form cannot skip the role gate."""
        from django.test import RequestFactory

        factory = RequestFactory()
        missing = []
        patterns = list(_console_patterns())
        self.assertGreater(len(patterns), 100, "URLconf walk found too few console routes")
        for pattern in patterns:
            if pattern.name in NOT_ADMIN_CHANGES:
                continue
            if pattern.name in CONSOLE_ACTIONS:
                continue
            # A view that is not a change answers POST with 405 before doing anything.
            kwargs = {}
            for key, converter in pattern.pattern.converters.items():
                kwargs[key] = converter.to_python("11111111-1111-1111-1111-111111111111") if "uuid" in type(converter).__name__.lower() else "x"
            request = factory.post("/")
            request.session = {}
            with patch("control_panel.views.GoBFFClient", AutoOKClient()):
                try:
                    response = pattern.callback(request, **kwargs)
                except Exception:  # noqa: BLE001 - only the status matters here
                    missing.append(pattern.name)
                    continue
            if response.status_code != 405:
                missing.append(pattern.name)
        self.assertEqual(missing, [], "POST routes missing from CONSOLE_ACTIONS")

    def test_action_paths_match_what_the_client_sends(self):
        """Each gate entry's method and path are exactly what GoBFFClient sends for that console change."""
        U = "11111111-1111-1111-1111-111111111111"
        calls = {
            "analytics_rebuild": (lambda c: c.analytics_rebuild("2026-09-01", "2026-09-02"), {}),
            "analytics_exclude": (lambda c: c.analytics_exclude_account(U, "QA phone"), {}),
            "analytics_include": (lambda c: c.analytics_include_account(U), {"member_id": U}),
            "business_market_save": (lambda c: c.save_launch_market({}), {}),
            "business_spend_save": (lambda c: c.save_marketing_spend({}), {}),
            "business_spend_delete": (lambda c: c.delete_marketing_spend(U), {"spend_id": U}),
            "photo_theme_save": (lambda c: c.save_photo_theme({}), {}),
            "engagement_prompt_new": (lambda c: c.create_engagement_prompt({}), {}),
            "engagement_prompt_edit": (lambda c: c.update_engagement_prompt("p1", {}), {"prompt_id": "p1"}),
            "engagement_prompt_activate": (lambda c: c.activate_engagement_prompt("p1"), {"prompt_id": "p1"}),
            "room_action": (lambda c: c.admin_room_action(U, {}), {"room_id": U}),
            "room_role": (lambda c: c.admin_room_role(U, U, "moderator"), {"room_id": U}),
            "group_cover_decision": (lambda c: c.group_cover_decision(U, "approved", ""), {"cover_id": U}),
            "blog_decision": (lambda c: c.blog_decision(U, {}), {"case_id": U}),
            "action_report": (lambda c: c.action_report("r1", "dismiss", ""), {"report_id": "r1"}),
            "media_moderation_decision": (lambda c: c.decide_media_moderation("ph1", "approved", ""), {"photo_id": "ph1"}),
            "action_appeal": (lambda c: c.action_appeal("a1", "upheld", ""), {"appeal_id": "a1"}),
            "approve_verification": (lambda c: c.approve_verification("u1"), {"user_id": "u1"}),
            "reject_verification": (lambda c: c.reject_verification("u1", "blurry"), {"user_id": "u1"}),
            "city_pilot_save": (lambda c: c.save_city_pilot({}), {}),
            "city_pilot_stage": (lambda c: c.transition_city_pilot(U, {}), {"pilot_id": U}),
            "city_pilot_experience_create": (lambda c: c.create_city_pilot_experience(U, {}), {"pilot_id": U}),
            "city_pilot_experience_cancel": (lambda c: c.cancel_city_pilot_experience(U, U), {"pilot_id": U, "event_id": U}),
            "client_error_status": (lambda c: c.set_client_error_status(U, "resolved"), {"issue_id": U}),
            "support_bulk": (lambda c: c.bulk_support_tickets([U], "claim"), {}),
            "support_canned_save": (lambda c: c.create_support_canned_response({}), {}),
            "support_canned_deactivate": (lambda c: c.deactivate_support_canned_response(U), {"response_id": U}),
            "support_ticket_reply": (lambda c: c.reply_support_ticket(U, body="hi", visibility="public"), {"ticket_id": U}),
            "support_ticket_update": (lambda c: c.update_support_ticket(U, {"status": "open"}), {"ticket_id": U}),
            "support_ticket_claim": (lambda c: c.claim_support_ticket(U), {"ticket_id": U}),
            "support_ticket_merge": (lambda c: c.merge_support_ticket(U, U), {"ticket_id": U}),
            "catalog_new": (lambda c: c.create_catalog_gift({}), {}),
            "catalog_edit": (lambda c: c.update_catalog_gift("rose", {}), {"gift_id": "rose"}),
            "catalog_toggle": (lambda c: c.toggle_catalog_gift("rose", is_active=True), {"gift_id": "rose"}),
            "catalog_delete": (lambda c: c.delete_catalog_gift("rose"), {"gift_id": "rose"}),
            "user_create": (lambda c: c.create_user({}), {}),
            "user_edit": (lambda c: c.update_user("u1", {}), {"user_id": "u1"}),
            "user_delete": (lambda c: c.delete_user("u1"), {"user_id": "u1"}),
            "user_suspend": (lambda c: c.suspend_user("u1", "r", 0), {"user_id": "u1"}),
            "user_unsuspend": (lambda c: c.unsuspend_user("u1"), {"user_id": "u1"}),
            "user_ban": (lambda c: c.ban_user("u1", "r"), {"user_id": "u1"}),
            "user_unban": (lambda c: c.unban_user("u1"), {"user_id": "u1"}),
            "user_force_verify": (lambda c: c.force_verify_user("u1"), {"user_id": "u1"}),
            "user_grant_coins": (lambda c: c.admin_grant_coins("u1", 5, "r"), {"user_id": "u1"}),
            "config_flag_toggle": (lambda c: c.update_config_flag("f1", True), {"key": "f1"}),
            "progression_policy_update": (lambda c: c.update_progression_policy("s1", {}), {"source": "s1"}),
            "progression_experiment_update": (lambda c: c.update_progression_experiment(
                "e1", status="draft", rollout_stage="draft", rollout_percent=0, safety_stop_owner="", evidence_uri="",
                decision_note=""), {"key": "e1"}),
            "progression_fraud_rule_update": (lambda c: c.update_progression_fraud_rule("r1", {}), {"rule_code": "r1"}),
            "progression_fraud_resolve": (lambda c: c.resolve_progression_fraud("c1", "dismissed", "ok"), {"case_id": "c1"}),
            "progression_user_adjust": (lambda c: c.adjust_user_xp("-", 5, "reason"), {}),
            "progression_user_control": (lambda c: c.set_user_progression_control(
                "-", progression_frozen=False, risk_multiplier=1.0, reason="r"), {}),
            "billing_package_toggle": (lambda c: c.toggle_coin_package("pk", is_active=True), {"package_id": "pk"}),
            "billing_package_new": (lambda c: c.create_coin_package({}), {}),
            "billing_package_edit": (lambda c: c.update_coin_package("pk", {}), {"package_id": "pk"}),
            "billing_grant_coins": (lambda c: c.admin_grant_coins("u1", 5, "r"), {}),
            "billing_gift_reverse": (lambda c: c.reverse_gift_send("-", "reason"), {}),
            "billing_wallet_review": (lambda c: c.review_frozen_wallet("u1", action="a", note="n"), {"user_id": "u1"}),
            "billing_fraud_case_resolve": (lambda c: c.resolve_economy_fraud_case("c1", resolution="cleared", note="n"), {"case_id": "c1"}),
            "billing_fraud_rule_update": (lambda c: c.update_economy_fraud_rule("r1", {}), {"rule_code": "r1"}),
            "safety_sos_resolve": (lambda c: c.resolve_sos_alert("a1"), {"alert_id": "a1"}),
            "account_recovery_resolve": (lambda c: c.resolve_account_recovery(
                "q1", action="decline", identity_check="", resolution_note=""), {"request_id": "q1"}),
        }
        self.assertEqual(set(calls), set(CONSOLE_ACTIONS), "every gate entry needs a client-call check")
        for name, (call, kwargs) in calls.items():
            with self.subTest(name), patch.object(GoBFFClient, "_request") as request:
                call(GoBFFClient(use_operator_context=False))
                sent_method, sent_path = request.call_args.args[:2]
                action = CONSOLE_ACTIONS[name]
                self.assertEqual(sent_method, action.method)
                self.assertEqual(sent_path, "/admin/" + action.path.format(**kwargs))

    def test_every_console_mutation_goes_through_an_audited_admin_route(self):
        """Go's operator audit middleware records /v1/admin/* writes only; every console change must use one."""
        for name, action in CONSOLE_ACTIONS.items():
            with self.subTest(name):
                self.assertNotEqual(action.method, "GET")
                self.assertFalse(action.path.startswith("/"))
                self.assertNotIn("wallet/", action.path.split("billing/")[0])


class RoleGateMiddlewareTest(TestCase):
    def setUp(self):
        self.api = AutoOKClient()
        patcher = patch("control_panel.views.GoBFFClient", return_value=self.api)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_unknown_roles_are_left_to_go(self):
        """With no stored roles the console forwards the change and Go decides (pre-CON-05 behaviour)."""
        client = login(Client())
        client.post(reverse("safety_sos_resolve", args=["alert-1"]))
        self.api.resolve_sos_alert.assert_called_once_with("alert-1")

    def test_refusal_redirects_back_with_reason_and_names_the_role(self):
        """A refused change goes back to the page it came from and says which role was refused."""
        response = login(Client(), roles=["analyst"]).post(reverse("user_ban", args=["member-1"]), {"reason": "spam"})
        self.assertRedirects(response, reverse("user_detail", args=["member-1"]), fetch_redirect_response=False)
        self.assertTrue(any("Analyst" in m and "cannot make this change" in m for m in flash(response)))
        self.api.ban_user.assert_not_called()

    def test_gate_does_not_touch_reads(self):
        """GET pages are never refused by the gate; Go answers reads."""
        response = login(Client(), roles=["analyst"]).get(reverse("catalog_list"))
        self.assertEqual(response.status_code, 200)

    def test_csrf_is_checked_before_the_role_gate(self):
        client = login(Client(enforce_csrf_checks=True), roles=["analyst"])
        self.assertEqual(client.post(reverse("user_ban", args=["member-1"]), {"reason": "spam"}).status_code, 403)

    def test_empty_role_list_refuses_every_change(self):
        response = login(Client(), roles=[]).post(reverse("catalog_delete", args=["rose"]))
        self.assertRedirects(response, reverse("catalog_list"), fetch_redirect_response=False)
        self.assertTrue(any("no operator role" in m for m in flash(response)))
        self.api.delete_catalog_gift.assert_not_called()


class ActionAllowedMirrorTest(SimpleTestCase):
    """action_allowed follows principalCanAccessAdminRoute for the console's own routes."""

    def test_matrix(self):
        cases = [
            (["trust_safety"], "user_suspend", {"user_id": "u"}, True),
            (["moderator"], "user_force_verify", {"user_id": "u"}, True),
            (["ops_admin"], "user_suspend", {"user_id": "u"}, False),
            (["trust_safety"], "user_delete", {"user_id": "u"}, False),
            (["trust_safety"], "user_grant_coins", {"user_id": "u"}, False),
            (["ops_admin"], "user_grant_coins", {"user_id": "u"}, True),
            (["finance"], "billing_package_new", {}, False),
            (["ops_admin"], "billing_package_new", {}, True),
            (["trust_safety"], "billing_fraud_case_resolve", {"case_id": "c"}, True),
            (["trust_safety"], "billing_fraud_rule_update", {"rule_code": "r"}, False),
            (["trust_safety"], "city_pilot_stage", {"pilot_id": "p"}, True),
            (["trust_safety"], "city_pilot_experience_cancel", {"pilot_id": "p", "event_id": "e"}, True),
            (["trust_safety"], "city_pilot_experience_create", {"pilot_id": "p"}, False),
            (["finance"], "business_spend_save", {}, True),
            (["ops_admin"], "business_spend_save", {}, False),
            (["ops_admin"], "business_market_save", {}, True),
            (["analyst"], "analytics_rebuild", {}, False),
            (["support"], "support_ticket_claim", {"ticket_id": "t"}, True),
            (["analyst"], "support_ticket_claim", {"ticket_id": "t"}, False),
            (["admin"], "analytics_include", {"member_id": "m"}, True),
            (None, "analytics_include", {"member_id": "m"}, True),
        ]
        for roles, name, kwargs, expected in cases:
            with self.subTest(roles=roles, name=name):
                self.assertIs(action_allowed(roles, name, kwargs), expected)
                if roles is not None:
                    action = CONSOLE_ACTIONS[name]
                    self.assertIs(can_access_admin_route(roles, action.method, action.path.format(**kwargs)), expected)
