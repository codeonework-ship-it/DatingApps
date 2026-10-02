from unittest.mock import patch

from django.test import TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult, BinaryAPIResult


class DashboardViewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    @patch("control_panel.views.GoBFFClient")
    def test_dashboard_renders(self, client_cls):
        """[case:console.dashboard.dashboard.renders]"""
        client = client_cls.return_value
        client.health.return_value = APIResult(ok=True, data={"status": "ok"})
        client.readiness.return_value = APIResult(ok=True, data={"status": "ready"})
        client.list_verifications.return_value = APIResult(ok=True, data={"verifications": []})
        client.list_activities.return_value = APIResult(ok=True, data={"activities": []})
        client.analytics_overview.return_value = APIResult(
            ok=True,
            data={"metrics": {"pending_reports": 3, "funnel_metrics": {"unlock_completion_rate": 75}}},
        )
        client.list_users.return_value = APIResult(
            ok=True,
            data={"users": [], "total": 47, "kpis": {"total": 47, "active": 41}},
        )
        client.list_reports.return_value = APIResult(ok=True, data={"reports": []})
        client.list_appeals.return_value = APIResult(ok=True, data={"appeals": []})
        client.list_media_moderation.return_value = APIResult(ok=True, data={"items": []})
        client.list_sos_alerts.return_value = APIResult(ok=True, data={"alerts": []})
        client.list_audit_events.return_value = APIResult(
            ok=True,
            data={"events": [{"id": 9, "event_type": "admin.request", "actor_role": "admin", "resource_type": "users"}]},
        )
        client.list_domain_events.return_value = APIResult(
            ok=True,
            data={"events": [{"sequence_id": 81, "event_name": "matching.messages.created", "aggregate_type": "matching.messages", "aggregate_id": "message-1"}]},
        )
        client.domain_event_metrics.return_value = APIResult(
            ok=True,
            data={"events_15m": 12, "registered_sources": 115, "unregistered_sources": 0, "coverage_complete": True, "pending_deliveries": 0, "dead_letters": 0},
        )

        response = self.client.get(reverse("dashboard"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "AegisConnect Control Panel")
        self.assertContains(response, "Operations command center")
        self.assertContains(response, "47")
        self.assertContains(response, "Recent operator actions")
        self.assertContains(response, "Canonical domain stream")
        self.assertContains(response, "115 SOURCES")

    @patch("control_panel.views.GoBFFClient")
    def test_activity_feed_filters_latest_events(self, client_cls):
        """[case:console.activities.activity_feed.renders]"""
        client_cls.return_value.list_activities.return_value = APIResult(
            ok=True,
            data={
                "activities": [
                    {"action": "match.created", "status": "success", "user_id": "user-1"},
                    {"action": "report.created", "status": "failed", "user_id": "user-2"},
                ]
            },
        )

        response = self.client.get(reverse("activity_feed"), {"action": "match", "status": "success"})

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "match.created")
        self.assertNotContains(response, "report.created")

    @patch("control_panel.views.GoBFFClient")
    def test_operator_audit_page_forwards_filters(self, client_cls):
        """[case:console.audit.audit_log.renders]"""
        client_cls.return_value.list_audit_events.return_value = APIResult(
            ok=True,
            data={
                "source": "audit.operator_action_log",
                "append_only": True,
                "events": [
                    {
                        "id": 12,
                        "txid": 44,
                        "event_type": "admin.request",
                        "actor_role": "trust_safety",
                        "actor_user_id": "operator-1",
                        "resource_type": "users",
                        "resource_id": "user-2",
                    }
                ],
            },
        )

        response = self.client.get(
            reverse("audit_log"),
            {"event_type": "admin.request", "resource_type": "users", "page_size": "25"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Operator Audit Log")
        self.assertContains(response, "trust_safety")
        client_cls.return_value.list_audit_events.assert_called_once_with(
            limit=25,
            offset=0,
            event_type="admin.request",
            resource_type="users",
        )

    @patch("control_panel.views.GoBFFClient")
    def test_domain_event_page_forwards_filters_and_renders_pipeline_health(self, client_cls):
        """[case:console.events.domain_events.renders]"""
        client = client_cls.return_value
        client.list_domain_events.return_value = APIResult(
            ok=True,
            data={
                "source": "platform.domain_event_outbox",
                "events": [
                    {
                        "sequence_id": 91,
                        "event_id": "event-1",
                        "event_name": "matching.messages.created",
                        "event_version": 1,
                        "aggregate_type": "matching.messages",
                        "aggregate_id": "message-1",
                        "producer": "matching",
                    }
                ],
            },
        )
        client.domain_event_metrics.return_value = APIResult(
            ok=True,
            data={"total_events": 91, "registered_sources": 115, "unregistered_sources": 0, "dead_letters": 0},
        )

        response = self.client.get(
            reverse("domain_events"),
            {"event_name": "matching.messages.created", "producer": "matching", "page_size": "25"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Domain Event Stream")
        self.assertContains(response, "matching.messages.created")
        self.assertContains(response, "115")
        client.list_domain_events.assert_called_once_with(
            limit=25,
            offset=0,
            event_name="matching.messages.created",
            producer="matching",
        )

    @patch("control_panel.views.GoBFFClient")
    def test_user_list_uses_global_kpis_from_api(self, client_cls):
        """[case:console.users.user_list.renders]"""
        client_cls.return_value.list_users.return_value = APIResult(
            ok=True,
            data={
                "users": [],
                "total": 1247,
                "kpis": {"active": 1198, "suspended": 32, "banned": 5, "verified_pct": 78.4, "scope": "all_users"},
            },
        )

        response = self.client.get(reverse("user_list"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "1247")
        self.assertContains(response, "1198")
        self.assertContains(response, "78%")

    @patch("control_panel.views.GoBFFClient")
    def test_approve_redirects_with_success(self, client_cls):
        """[case:console.verifications.approve_verification.renders]"""
        client = client_cls.return_value
        client.approve_verification.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(reverse("approve_verification", kwargs={"user_id": "user-1"}))

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("verification_queue"))

    @patch("control_panel.views.GoBFFClient")
    def test_reject_requires_reason(self, client_cls):
        """[case:console.verifications.reject_verification.renders]"""
        client = client_cls.return_value
        client.reject_verification.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(reverse("reject_verification", kwargs={"user_id": "user-1"}), {})

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("verification_queue"))
        client.reject_verification.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_appeal_queue_renders(self, client_cls):
        """[case:console.appeals.appeal_queue.renders]"""
        client = client_cls.return_value
        client.list_appeals.return_value = APIResult(ok=True, data={"appeals": []})

        response = self.client.get(reverse("appeal_queue"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Moderation Appeals")

    @patch("control_panel.views.GoBFFClient")
    def test_action_appeal_redirects(self, client_cls):
        """[case:console.appeals.action_appeal.renders]"""
        client = client_cls.return_value
        client.action_appeal.return_value = APIResult(ok=True, data={"success": True})

        response = self.client.post(
            reverse("action_appeal", kwargs={"appeal_id": "apl-1"}),
            {"status": "under_review", "resolution_reason": "triage started"},
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("appeal_queue"))

    @patch("control_panel.views.GoBFFClient")
    def test_media_moderation_queue_and_content_proxy(self, client_cls):
        """[case:console.moderation_media.media_moderation_queue.renders] [case:console.moderation_media.media_moderation_content.renders]"""
        client = client_cls.return_value
        client.health.return_value = APIResult(ok=True, data={"status": "ok"})
        client.list_media_moderation.return_value = APIResult(
            ok=True,
            data={"items": [{"photo_id": "photo-1", "username": "user_one"}]},
        )
        client.get_media_moderation_content.return_value = BinaryAPIResult(
            ok=True,
            content=b"image-bytes",
            content_type="image/jpeg",
            status_code=200,
        )

        queue_response = self.client.get(reverse("media_moderation_queue"))
        content_response = self.client.get(
            reverse("media_moderation_content", kwargs={"photo_id": "photo-1"})
        )

        self.assertEqual(queue_response.status_code, 200)
        self.assertContains(queue_response, "Profile Media Review")
        self.assertEqual(content_response.status_code, 200)
        self.assertEqual(content_response.content, b"image-bytes")
        self.assertEqual(content_response["Cache-Control"], "private, no-store")

    @patch("control_panel.views.GoBFFClient")
    def test_media_rejection_requires_reason(self, client_cls):
        """[case:console.moderation_media.media_moderation_decision.performs]"""
        client = client_cls.return_value
        response = self.client.post(
            reverse("media_moderation_decision", kwargs={"photo_id": "photo-1"}),
            {"decision": "rejected", "reason": ""},
        )

        self.assertEqual(response.status_code, 302)
        client.decide_media_moderation.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_user_create_forwards_username_credentials(self, client_cls):
        """[case:console.users.user_create.performs]"""
        client = client_cls.return_value
        client.create_user.return_value = APIResult(ok=True, data={"id": "user-1"})

        response = self.client.post(
            reverse("user_create"),
            {
                "username": "Person_One",
                "password": "Password123",
                "name": "Person One",
                "phone_number": "",
            },
        )

        self.assertRedirects(
            response,
            reverse("user_list"),
            fetch_redirect_response=False,
        )
        payload = client.create_user.call_args.args[0]
        self.assertEqual(payload["username"], "person_one")
        self.assertEqual(payload["password"], "Password123")
        self.assertEqual(payload["phone_number"], "")

    @patch("control_panel.views.GoBFFClient")
    def test_user_create_requires_username_and_password(self, client_cls):
        """[case:console.users.user_create.performs]"""
        response = self.client.post(
            reverse("user_create"),
            {"name": "Person One", "username": "", "password": ""},
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Name, username, and password are required.")
        client_cls.return_value.create_user.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_engagement_nudges_renders_durable_delivery_state(self, client_cls):
        """[case:console.engagement.engagement_nudges.renders]"""
        client_cls.return_value.list_engagement_nudges.return_value = APIResult(
            ok=True,
            data={
                "nudges": [
                    {
                        "id": "nudge-1",
                        "match_id": "match-1",
                        "user_id": "user-1",
                        "nudge_type": "stalled_24h",
                        "created_at": "2026-08-09T00:00:00Z",
                        "clicked_at": None,
                    }
                ],
                "count": 1,
                "clicked": 0,
                "enabled": True,
            },
        )

        response = self.client.get(reverse("engagement_nudges"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Latest persisted nudges")
        self.assertContains(response, "stalled_24h")
        self.assertNotContains(response, "Coming Soon")

    @patch("control_panel.views.GoBFFClient")
    def test_progression_console_renders_policies_experiments_and_fraud(self, client_cls):
        """[case:console.progression.progression_admin.renders]"""
        client = client_cls.return_value
        client.health.return_value = APIResult(ok=True, data={"status": "ok"})
        client.progression_overview.return_value = APIResult(
            ok=True,
            data={
                "metrics": {
                    "users": 12,
                    "total_xp": 900,
                    "avg_level": 2.5,
                    "queue_depth": 3,
                    "completion_p95_seconds": 0.8,
                    "dead_letters": 0,
                    "open_fraud_cases": 1,
                    "cap_denials_15m": 7,
                },
                "policies": [
                    {
                        "source": "daily_prompt_submitted",
                        "display_name": "Daily prompt submitted",
                        "base_xp": 20,
                        "daily_xp_cap": 20,
                        "daily_event_cap": 1,
                        "cooldown_seconds": 0,
                        "enabled": True,
                    }
                ],
                "experiments": [
                    {
                        "key": "xp_weighting_v1",
                        "name": "XP weighting fairness test",
                        "status": "draft",
                        "rollout_percent": 0,
                    }
                ],
            },
        )
        client.list_progression_fraud.return_value = APIResult(
            ok=True,
            data={
                "cases": [
                    {
                        "id": "case-1",
                        "user_id": "user-1",
                        "username": "member_one",
                        "rule_code": "repeated_source_cap",
                        "severity": "medium",
                        "status": "open",
                        "evidence": {"rejected_attempts": 5},
                    }
                ]
            },
        )

        response = self.client.get(reverse("progression_admin"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Level & XP Progression")
        self.assertContains(response, "daily_prompt_submitted")
        self.assertContains(response, "xp_weighting_v1")
        self.assertContains(response, "member_one")
        self.assertContains(response, "Production health")
        self.assertContains(response, "Cap denials · 15m")

    @patch("control_panel.views.GoBFFClient")
    def test_progression_adjustment_requires_auditable_reason(self, client_cls):
        """[case:console.progression.progression_user_adjust.performs]"""
        response = self.client.post(
            reverse("progression_user_adjust"),
            {"user_id": "user-1", "amount": "100", "reason": "short"},
        )

        self.assertEqual(response.status_code, 302)
        client_cls.return_value.adjust_user_xp.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_progression_control_forwards_freeze_and_risk(self, client_cls):
        """[case:console.progression.progression_user_control.performs]"""
        client_cls.return_value.set_user_progression_control.return_value = APIResult(
            ok=True, data={"success": True}
        )

        response = self.client.post(
            reverse("progression_user_control"),
            {
                "user_id": "user-1",
                "risk_multiplier": "0.75",
                "progression_frozen": "on",
                "reason": "automated safety review",
            },
        )

        self.assertEqual(response.status_code, 302)
        client_cls.return_value.set_user_progression_control.assert_called_once_with(
            "user-1",
            progression_frozen=True,
            risk_multiplier=0.75,
            reason="automated safety review",
        )

    @patch("control_panel.views.GoBFFClient")
    def test_progression_rollout_forwards_reviewed_fixed_stage(self, client_cls):
        """[case:console.progression.progression_experiment_update.performs]"""
        client_cls.return_value.update_progression_experiment.return_value = APIResult(
            ok=True, data={"success": True}
        )

        response = self.client.post(
            reverse("progression_experiment_update", args=["xp_weighting_v1"]),
            {
                "status": "active",
                "rollout_stage": "five_percent",
                "safety_stop_owner": "progression-oncall",
                "evidence_uri": "report://five-percent-review",
                "decision_note": "Safety and projection gates passed.",
            },
        )

        self.assertEqual(response.status_code, 302)
        client_cls.return_value.update_progression_experiment.assert_called_once_with(
            "xp_weighting_v1",
            status="active",
            rollout_stage="five_percent",
            rollout_percent=5,
            safety_stop_owner="progression-oncall",
            evidence_uri="report://five-percent-review",
            decision_note="Safety and projection gates passed.",
        )

    @patch("control_panel.views.GoBFFClient")
    def test_progression_fraud_tuning_forwards_bounded_review_policy(self, client_cls):
        """[case:console.progression.progression_fraud_rule_update.performs]"""
        client_cls.return_value.update_progression_fraud_rule.return_value = APIResult(
            ok=True, data={"success": True}
        )

        response = self.client.post(
            reverse("progression_fraud_rule_update", args=["repeated_source_cap"]),
            {
                "rejected_attempt_threshold": "4",
                "window_seconds": "86400",
                "review_sla_minutes": "240",
                "severity": "medium",
                "enabled": "on",
                "tuning_note": "Reviewed against resolved false positives.",
            },
        )

        self.assertEqual(response.status_code, 302)
        client_cls.return_value.update_progression_fraud_rule.assert_called_once_with(
            "repeated_source_cap",
            {
                "rejected_attempt_threshold": 4,
                "window_seconds": 86400,
                "review_sla_minutes": 240,
                "severity": "medium",
                "enabled": True,
                "tuning_note": "Reviewed against resolved false positives.",
            },
        )


class OperatorAuthenticationTest(TestCase):
    def test_console_redirects_anonymous_operator_to_login(self):
        """[case:console.login.operator_login.authz]"""
        response = self.client.get(reverse("dashboard"))

        self.assertEqual(response.status_code, 302)
        self.assertTrue(response.url.startswith(reverse("operator_login")))

    @patch("control_panel.views.GoBFFClient")
    def test_login_requires_bff_operator_authorization(self, client_cls):
        """[case:console.login.operator_login.authz]"""
        client = client_cls.return_value
        client.login.return_value = APIResult(
            ok=True,
            data={
                "access_token": "access-token",
                "refresh_token": "refresh-token",
                "user_id": "operator-1",
            },
            status_code=200,
        )
        client.analytics_overview.return_value = APIResult(
            ok=False,
            data={},
            error="operator role does not permit this administrative action",
            status_code=403,
        )

        response = self.client.post(
            reverse("operator_login"),
            {"username": "regular_user", "password": "Password123!"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "does not have permission")
        self.assertNotIn("operator_access_token", self.client.session)

    @patch("control_panel.views.GoBFFClient")
    def test_login_stores_bff_session_after_admin_probe(self, client_cls):
        """[case:console.login.operator_login.performs]"""
        client = client_cls.return_value
        client.login.return_value = APIResult(
            ok=True,
            data={
                "access_token": "access-token",
                "refresh_token": "refresh-token",
                "user_id": "operator-1",
            },
            status_code=200,
        )
        client.analytics_overview.return_value = APIResult(
            ok=True,
            data={"metrics": {}},
            status_code=200,
        )

        response = self.client.post(
            reverse("operator_login"),
            {"username": "console_admin", "password": "Password123!", "next": "/users/"},
        )

        self.assertRedirects(response, "/users/", fetch_redirect_response=False)
        self.assertEqual(self.client.session["operator_access_token"], "access-token")
        self.assertEqual(self.client.session["operator_username"], "console_admin")

    def test_logout_flushes_operator_session(self):
        """[case:console.logout.operator_logout.performs]"""
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session.save()

        with patch("control_panel.views.GoBFFClient") as client_cls:
            client_cls.return_value.logout.return_value = APIResult(ok=True, data={})
            response = self.client.post(reverse("operator_logout"))

        self.assertRedirects(response, reverse("operator_login"), fetch_redirect_response=False)
        self.assertNotIn("operator_access_token", self.client.session)


class AccountRecoveryViewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    @patch("control_panel.views.GoBFFClient")
    def test_queue_lists_open_requests(self, client_cls):
        """[case:console.account_recovery.account_recovery_queue.renders]"""
        client = client_cls.return_value
        client.list_account_recovery.return_value = APIResult(
            ok=True,
            data={"requests": [{
                "id": "req-1", "username": "member_one", "member_message": "Lost my phone",
                "status": "open", "created_at": "2026-09-27T10:00:00Z",
                "identity_verified": True, "account_recoverable": True,
            }]},
        )
        response = self.client.get(reverse("account_recovery_queue"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "member_one")
        self.assertContains(response, "Issue recovery code")
        client.list_account_recovery.assert_called_once_with(limit=25, offset=0, status="open")

    @patch("control_panel.views.GoBFFClient")
    def test_issued_code_is_shown_once_and_never_cached_or_flashed(self, client_cls):
        """[case:console.account_recovery.account_recovery_resolve.performs]"""
        client = client_cls.return_value
        client.resolve_account_recovery.return_value = APIResult(
            ok=True,
            data={"status": "code_issued", "recovery_code": "SECRET-CODE-123",
                  "code_expires_at": "2026-09-30T10:00:00Z", "display_once": True},
        )
        response = self.client.post(
            reverse("account_recovery_resolve", args=["req-1"]),
            {"action": "issue_recovery_code", "identity_check": "verified_identity_match",
             "resolution_note": "Selfie matched a live call."},
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "SECRET-CODE-123")
        self.assertIn("no-store", response["Cache-Control"])
        self.assertNotIn("SECRET-CODE-123", str(self.client.session.items()))
        follow_up = self.client.get(reverse("account_recovery_queue"))
        self.assertNotContains(follow_up, "SECRET-CODE-123")

    @patch("control_panel.views.GoBFFClient")
    def test_decline_redirects_back_to_queue(self, client_cls):
        """[case:console.account_recovery.account_recovery_resolve.performs]"""
        client = client_cls.return_value
        client.resolve_account_recovery.return_value = APIResult(ok=True, data={"status": "declined"})
        client.list_account_recovery.return_value = APIResult(ok=True, data={"requests": []})
        response = self.client.post(
            reverse("account_recovery_resolve", args=["req-1"]),
            {"action": "decline", "identity_check": "", "resolution_note": "Could not confirm identity."},
        )
        self.assertRedirects(response, reverse("account_recovery_queue"))


class BillingIntegrityViewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    @patch("control_panel.views.GoBFFClient")
    def test_reconciliation_renders_refund_controls_and_frozen_wallets(self, client_cls):
        """[case:console.billing.billing_reconciliation.renders]"""
        client = client_cls.return_value
        client.health.return_value = APIResult(ok=True, data={"status": "ok"})
        client.get_billing_reconciliation.return_value = APIResult(
            ok=True,
            data={
                "revenue": {},
                "anomalies": [],
                "payments_by_status": [],
                "wallet": {},
                "subscriptions": {},
                "webhooks": {},
                "checkouts": {},
            },
        )
        client.list_frozen_wallets.return_value = APIResult(
            ok=True,
            data={
                "wallets": [
                    {
                        "user_id": "11111111-1111-4111-8111-111111111111",
                        "coin_balance": 0,
                        "debt_coins": 40,
                        "frozen_at": "2026-09-27T10:00:00Z",
                        "frozen_reason": "coin_purchase_reversed",
                    }
                ]
            },
        )
        client.list_economy_fraud_cases.return_value = APIResult(
            ok=True,
            data={"cases": [{"id": "case-1", "user_id": "user-1", "rule_code": "gift_burst", "event_type": "gift_send", "severity": "high", "action_taken": "temporary_lock", "observed_value": 10, "trigger_value": 10, "occurrence_count": 1}]},
        )
        client.list_economy_fraud_rules.return_value = APIResult(ok=True, data={"rules": []})

        response = self.client.get(reverse("billing_reconciliation"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Refund and chargeback operations")
        self.assertContains(response, "Reverse a gift send")
        self.assertContains(response, "40 coin debt")
        self.assertContains(response, "Collect available, write off remainder")
        self.assertContains(response, "Coin economy fraud controls")
        self.assertContains(response, "gift_burst")

    @patch("control_panel.views.GoBFFClient")
    def test_gift_reversal_posts_reason_to_bff(self, client_cls):
        """[case:console.billing.billing_gift_reverse.performs]"""
        client_cls.return_value.reverse_gift_send.return_value = APIResult(
            ok=True,
            data={"coins_refunded": 3, "message_retracted": True},
        )

        response = self.client.post(
            reverse("billing_gift_reverse"),
            {"gift_send_id": "gift-1", "reason": "Member requested reversal"},
        )

        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        client_cls.return_value.reverse_gift_send.assert_called_once_with(
            "gift-1", "Member requested reversal"
        )

    @patch("control_panel.views.GoBFFClient")
    def test_wallet_review_posts_audited_resolution_to_bff(self, client_cls):
        """[case:console.billing.billing_wallet_review.performs]"""
        client_cls.return_value.review_frozen_wallet.return_value = APIResult(
            ok=True,
            data={"debt_collected": 10, "debt_written_off": 30},
        )

        response = self.client.post(
            reverse("billing_wallet_review", args=["user-1"]),
            {
                "action": "write_off_and_unfreeze",
                "note": "Approved after reviewing the dispute evidence.",
            },
        )

        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        client_cls.return_value.review_frozen_wallet.assert_called_once_with(
            "user-1",
            action="write_off_and_unfreeze",
            note="Approved after reviewing the dispute evidence.",
        )

    @patch("control_panel.views.GoBFFClient")
    def test_short_gift_reversal_reason_is_rejected_before_api_call(self, client_cls):
        """[case:console.billing.billing_gift_reverse.performs]"""
        response = self.client.post(
            reverse("billing_gift_reverse"),
            {"gift_send_id": "gift-1", "reason": "no"},
        )

        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        client_cls.return_value.reverse_gift_send.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_fraud_false_positive_posts_attributed_clear(self, client_cls):
        """[case:console.billing.billing_fraud_case_resolve.performs]"""
        client_cls.return_value.resolve_economy_fraud_case.return_value = APIResult(ok=True, data={"status": "cleared"})
        response = self.client.post(
            reverse("billing_fraud_case_resolve", args=["case-1"]),
            {"resolution": "cleared", "note": "Reviewed account history; this was legitimate."},
        )
        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        client_cls.return_value.resolve_economy_fraud_case.assert_called_once_with(
            "case-1", resolution="cleared", note="Reviewed account history; this was legitimate."
        )
