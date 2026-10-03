"""Operator console: Level & XP progression (catalog feature console.progression)."""
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

POLICY_FORM = {"base_xp": "25", "daily_xp_cap": "50", "daily_event_cap": "2", "cooldown_seconds": "60", "enabled": "on"}
EXPERIMENT_FORM = {"status": "active", "rollout_stage": "twenty_five_percent", "safety_stop_owner": "progression-oncall",
                   "evidence_uri": "report://25", "decision_note": "Gates passed."}
FRAUD_RULE_FORM = {"rejected_attempt_threshold": "4", "window_seconds": "86400", "review_sla_minutes": "240",
                   "severity": "medium", "enabled": "on", "tuning_note": "Reviewed false positives."}


class ProgressionPageTest(ConsoleCaseTest):
    def test_bff_failures_show_banners(self):
        """[case:console.progression.progression_admin.renders]"""
        api = self.bff()
        api.progression_overview.return_value = bff_error("progression store unavailable", 503)
        api.list_progression_fraud.return_value = bff_error("fraud queue unavailable", 503)
        response = self.client.get(reverse("progression_admin"), {"status": "resolved"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Level & XP Progression")
        self.assertContains(response, "progression store unavailable")
        self.assertContains(response, "fraud queue unavailable")
        # "resolved" is not a case status: it is dropped and the open queue is read.
        api.list_progression_fraud.assert_called_once_with(status="open", sort="created_at", order="desc", limit=25, offset=0)


class ProgressionActionsTest(ConsoleCaseTest):
    def test_policy_update_forwards_whole_numbers(self):
        """[case:console.progression.progression_policy_update.performs]"""
        api = self.bff()
        url = reverse("progression_policy_update", args=["daily_prompt_submitted"])
        self.assertIn("XP policy values must be whole numbers.", flash(self.client.post(url, {**POLICY_FORM, "base_xp": "2.5"})))
        api.update_progression_policy.assert_not_called()
        response = self.client.post(url, POLICY_FORM)
        api.update_progression_policy.assert_called_once_with("daily_prompt_submitted", {
            "base_xp": 25, "daily_xp_cap": 50, "daily_event_cap": 2, "cooldown_seconds": 60, "enabled": True})
        self.assertRedirects(response, reverse("progression_admin"), fetch_redirect_response=False)
        self.assertIn("XP policy daily_prompt_submitted updated.", flash(response))
        self.client.post(url, {**POLICY_FORM, "enabled": ""})
        self.assertFalse(api.update_progression_policy.call_args.args[1]["enabled"])
        api.update_progression_policy.return_value = bff_error("cap below base xp", 400)
        self.assertIn("Policy update failed: cap below base xp", flash(self.client.post(url, POLICY_FORM)))

    def test_policy_update_authz(self):
        """[case:console.progression.progression_policy_update.authz]"""
        self.assert_action_authz(reverse("progression_policy_update", args=["daily_prompt_submitted"]), POLICY_FORM,
                                 "update_progression_policy", refused_roles=("trust_safety", "analyst"), allowed_roles=("ops_admin",))

    def test_experiment_update_rejects_mismatched_stage(self):
        """[case:console.progression.progression_experiment_update.performs]"""
        api = self.bff()
        url = reverse("progression_experiment_update", args=["xp_weighting_v1"])
        response = self.client.post(url, {**EXPERIMENT_FORM, "rollout_percent": "50"})
        self.assertIn("Choose a fixed rollout stage and its matching percentage.", flash(response))
        self.client.post(url, {**EXPERIMENT_FORM, "rollout_stage": "everyone"})
        api.update_progression_experiment.assert_not_called()
        response = self.client.post(url, EXPERIMENT_FORM)
        self.assertEqual(api.update_progression_experiment.call_args.kwargs["rollout_percent"], 25)
        self.assertIn("Experiment xp_weighting_v1 updated.", flash(response))
        api.update_progression_experiment.return_value = bff_error("safety stop owner required", 400)
        self.assertIn("Experiment update failed: safety stop owner required", flash(self.client.post(url, EXPERIMENT_FORM)))

    def test_experiment_update_authz(self):
        """[case:console.progression.progression_experiment_update.authz]"""
        self.assert_action_authz(reverse("progression_experiment_update", args=["xp_weighting_v1"]), EXPERIMENT_FORM,
                                 "update_progression_experiment", refused_roles=("moderator", "finance"), allowed_roles=("ops_admin",))

    def test_fraud_rule_update_validates(self):
        """[case:console.progression.progression_fraud_rule_update.performs]"""
        api = self.bff()
        url = reverse("progression_fraud_rule_update", args=["repeated_source_cap"])
        self.assertIn("Fraud policy limits must be whole numbers.",
                      flash(self.client.post(url, {**FRAUD_RULE_FORM, "window_seconds": "a day"})))
        api.update_progression_fraud_rule.assert_not_called()
        response = self.client.post(url, FRAUD_RULE_FORM)
        self.assertIn("Fraud rule repeated_source_cap updated for review-only enforcement.", flash(response))
        api.update_progression_fraud_rule.return_value = bff_error("tuning_note required", 400)
        self.assertIn("Fraud rule update failed: tuning_note required", flash(self.client.post(url, FRAUD_RULE_FORM)))

    def test_fraud_rule_update_authz(self):
        """[case:console.progression.progression_fraud_rule_update.authz]"""
        self.assert_action_authz(reverse("progression_fraud_rule_update", args=["repeated_source_cap"]), FRAUD_RULE_FORM,
                                 "update_progression_fraud_rule", refused_roles=("trust_safety", "support"), allowed_roles=("ops_admin",))

    def test_fraud_resolve_requires_final_status_and_resolution(self):
        """[case:console.progression.progression_fraud_resolve.performs]"""
        api = self.bff()
        url = reverse("progression_fraud_resolve", args=["case-1"])
        for bad in ({"status": "open", "resolution": "x"}, {"status": "dismissed", "resolution": " "}):
            self.assertIn("A final status and resolution are required.", flash(self.client.post(url, bad)))
        api.resolve_progression_fraud.assert_not_called()
        response = self.client.post(url, {"status": "dismissed", "resolution": " Legitimate streak "})
        api.resolve_progression_fraud.assert_called_once_with("case-1", "dismissed", "Legitimate streak")
        self.assertRedirects(response, reverse("progression_admin"), fetch_redirect_response=False)
        self.assertIn("Fraud case case-1 resolved.", flash(response))
        api.resolve_progression_fraud.return_value = bff_error("case already resolved", 409)
        self.assertIn("Fraud case update failed: case already resolved",
                      flash(self.client.post(url, {"status": "confirmed", "resolution": "Farm"})))

    def test_fraud_resolve_authz(self):
        """[case:console.progression.progression_fraud_resolve.authz]"""
        self.assert_action_authz(reverse("progression_fraud_resolve", args=["case-1"]), {"status": "dismissed", "resolution": "ok"},
                                 "resolve_progression_fraud", refused_roles=("trust_safety", "analyst"), allowed_roles=("ops_admin",))

    def test_user_adjust_posts_audited_amount(self):
        """[case:console.progression.progression_user_adjust.performs]"""
        api = self.bff()
        url = reverse("progression_user_adjust")
        for bad in ({"user_id": "", "amount": "10", "reason": "Restoring lost XP"}, {"user_id": "u1", "amount": "0", "reason": "Restoring lost XP"},
                    {"user_id": "u1", "amount": "x", "reason": "Restoring lost XP"}, {"user_id": "u1", "amount": "10", "reason": "short"}):
            self.assertIn("User ID, a non-zero amount, and a 10-character reason are required.", flash(self.client.post(url, bad)))
        api.adjust_user_xp.assert_not_called()
        response = self.client.post(url, {"user_id": " u1 ", "amount": "-40", "reason": "Reversing a farmed streak"})
        api.adjust_user_xp.assert_called_once_with("u1", -40, "Reversing a farmed streak")
        self.assertIn("Posted an audited -40 XP adjustment.", flash(response))
        api.adjust_user_xp.return_value = bff_error("member not found", 404)
        self.assertIn("XP adjustment failed: member not found",
                      flash(self.client.post(url, {"user_id": "u1", "amount": "5", "reason": "Restoring lost XP"})))

    def test_user_adjust_authz(self):
        """[case:console.progression.progression_user_adjust.authz]"""
        self.assert_action_authz(reverse("progression_user_adjust"), {"user_id": "u1", "amount": "5", "reason": "Restoring lost XP"},
                                 "adjust_user_xp", refused_roles=("trust_safety", "finance"), allowed_roles=("ops_admin",))

    def test_user_control_bounds_risk(self):
        """[case:console.progression.progression_user_control.performs]"""
        api = self.bff()
        url = reverse("progression_user_control")
        for bad in ({"user_id": "u1", "risk_multiplier": "1.5"}, {"user_id": "u1", "risk_multiplier": "0.2"},
                    {"user_id": "u1", "risk_multiplier": "high"}, {"user_id": "", "risk_multiplier": "1"}):
            self.assertIn("User ID and a risk multiplier from 0.5 to 1.0 are required.", flash(self.client.post(url, bad)))
        api.set_user_progression_control.assert_not_called()
        response = self.client.post(url, {"user_id": "u1", "risk_multiplier": "0.5", "reason": "Review"})
        api.set_user_progression_control.assert_called_once_with("u1", progression_frozen=False, risk_multiplier=0.5, reason="Review")
        self.assertIn("User progression control updated.", flash(response))
        api.set_user_progression_control.return_value = bff_error("reason required", 400)
        self.assertIn("Progression control failed: reason required",
                      flash(self.client.post(url, {"user_id": "u1", "risk_multiplier": "1"})))

    def test_user_control_authz(self):
        """[case:console.progression.progression_user_control.authz]"""
        self.assert_action_authz(reverse("progression_user_control"), {"user_id": "u1", "risk_multiplier": "1", "reason": "Review"},
                                 "set_user_progression_control", refused_roles=("trust_safety", "moderator"), allowed_roles=("ops_admin",))
