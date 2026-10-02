"""Operator console: product analytics, business reports and the city pilot
(catalog features console.analytics, console.business, console.city_pilot)."""
from uuid import uuid4

from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

MEMBER = "22222222-2222-4222-8222-222222222222"


class AnalyticsCasesTest(ConsoleCaseTest):
    module = "control_panel.views_analytics"

    def test_overview_bff_failure_shows_banner(self):
        """[case:console.analytics.analytics_overview.renders]"""
        self.bff().analytics_report.return_value = bff_error("The service couldn't complete that request.", 503)
        response = self.client.get(reverse("analytics_overview"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "couldn&#x27;t complete that request")

    def test_engagement_renders_report(self):
        """The surfaces table renders with small counts suppressed; grain is not forwarded for this report. [case:console.analytics.analytics_engagement.renders]"""
        surfaces = {"columns": [{"key": "surface_label", "label": "Surface", "kind": "dimension"},
                                {"key": "members", "label": "Members", "kind": "count"},
                                {"key": "reach", "label": "Reach", "kind": "ratio", "unit": "%"}],
                    "rows": [{"surface_label": "<b>Chat</b>", "members": 1234, "reach": 41.5, "suppressed": []},
                             {"surface_label": "Plans", "members": None, "reach": None, "suppressed": ["members", "reach"]}]}
        self.bff().analytics_report.return_value = APIResult(True, {"from": "2026-09-01", "to": "2026-09-28", "tables": {"surfaces": surfaces}, "meta": {}})
        response = self.client.get(reverse("analytics_engagement"), {"grain": "week", "gender": "female"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "1,234")
        self.assertContains(response, "41.5%")
        self.assertContains(response, "&lt;b&gt;Chat&lt;/b&gt;")
        self.assertContains(response, "&lt;5")
        name, params = self.bff().analytics_report.call_args.args
        self.assertEqual(name, "engagement")
        self.assertEqual(params, {"gender": "female"})

    def test_rebuild_refusal_and_failure_messages(self):
        """[case:console.analytics.analytics_rebuild.performs]"""
        api = self.bff()
        api.analytics_rebuild.return_value = APIResult(False, {}, "forbidden", 403)
        response = self.client.post(reverse("analytics_rebuild"), {"from": "2026-09-01", "to": "2026-09-02"})
        self.assertRedirects(response, reverse("analytics_data"), fetch_redirect_response=False)
        self.assertIn("Only an admin can rebuild snapshots.", flash(response))
        self.assertIn("Choose a from and to day (YYYY-MM-DD).",
                      flash(self.client.post(reverse("analytics_rebuild"), {"from": "2026-02-30", "to": "2026-03-01"})))
        self.assertEqual(api.analytics_rebuild.call_count, 1)

    def test_rebuild_authz(self):
        """[case:console.analytics.analytics_rebuild.authz]"""
        self.assert_action_authz(reverse("analytics_rebuild"), {"from": "2026-09-01", "to": "2026-09-02"}, "analytics_rebuild",
                                 refused_roles=("analyst", "ops_admin"), allowed_roles=("admin",), module=self.module)

    def test_exclude_confirms_and_reports_failure(self):
        """[case:console.analytics.analytics_exclude.performs]"""
        api = self.bff()
        response = self.client.post(reverse("analytics_exclude"), {"member_id": MEMBER, "reason": " QA device "})
        api.analytics_exclude_account.assert_called_once_with(MEMBER, "QA device")
        self.assertRedirects(response, reverse("analytics_data"), fetch_redirect_response=False)
        self.assertTrue(any("flagged as a test account" in m for m in flash(response)))
        self.assertIn("Provide the member's id and a reason of 3 to 200 characters.",
                      flash(self.client.post(reverse("analytics_exclude"), {"member_id": MEMBER, "reason": "x"})))
        api.analytics_exclude_account.return_value = bff_error("member not found", 404)
        self.assertIn("member not found", flash(self.client.post(reverse("analytics_exclude"), {"member_id": MEMBER, "reason": "QA device"})))

    def test_exclude_authz(self):
        """[case:console.analytics.analytics_exclude.authz]"""
        self.assert_action_authz(reverse("analytics_exclude"), {"member_id": MEMBER, "reason": "QA device"}, "analytics_exclude_account",
                                 refused_roles=("analyst", "ops_admin"), allowed_roles=("admin",), module=self.module)

    def test_include_confirms(self):
        """[case:console.analytics.analytics_include.performs]"""
        api = self.bff()
        response = self.client.post(reverse("analytics_include", args=[MEMBER]))
        api.analytics_include_account.assert_called_once_with(MEMBER)
        self.assertIn("Test-account flag removed.", flash(response))
        self.assertEqual(self.client.post(f"/analytics/data/exclusions/not-a-uuid/remove/").status_code, 404)

    def test_include_authz(self):
        """[case:console.analytics.analytics_include.authz]"""
        self.assert_action_authz(reverse("analytics_include", args=[MEMBER]), {}, "analytics_include_account",
                                 refused_roles=("analyst",), allowed_roles=("admin",), module=self.module)


class BusinessCasesTest(ConsoleCaseTest):
    module = "control_panel.views_business"

    def test_revenue_bff_failure_shows_banner(self):
        """[case:console.business.business_revenue.renders]"""
        self.bff().business_report.return_value = bff_error("this report requires one of the roles: admin, finance", 403)
        response = self.client.get(reverse("business_revenue"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "this report requires one of the roles: admin, finance")

    def test_coins_report(self):
        """[case:console.business.business_coins.renders]"""
        api = self.bff()
        api.business_report.return_value = APIResult(True, {
            "trend": [{"bucket": "2026-09-01", "purchased": 300, "granted": 50, "gift_spend": 120, "net_flow": 230}],
            "liability": {"outstanding_coins": 9876, "valuation": [{"currency": "INR", "estimated_liability": "98.76"}], "note": "Estimate"},
            "sources": {"non_revenue": {"admin_topup": {"count": 2, "coins": 50}}}, "sinks": {"gifts": {"top_gifts": [{"gift_id": "<b>rose</b>", "sends": 4, "coins": 120}]}},
            "data_status": {}, "tables": ["trend"]})
        response = self.client.get(reverse("business_coins"), {"bucket": "week", "mode": "sandbox"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "9876")
        self.assertContains(response, "98.76 INR")
        self.assertContains(response, "admin_topup")
        self.assertContains(response, "&lt;b&gt;rose&lt;/b&gt;")
        report, params = api.business_report.call_args.args
        self.assertEqual(report, "coins")
        self.assertEqual(params["bucket"], "week")
        self.assertEqual(params["mode"], "sandbox")
        api.business_report.return_value = bff_error()
        self.assertContains(self.client.get(reverse("business_coins")), "alert-glass warning")

    def test_referrals_report(self):
        """[case:console.business.business_referrals.renders]"""
        api = self.bff()
        api.business_report.return_value = APIResult(True, {
            "k_factor": {"by_cohort": [{"cohort": "2026-09", "members": 40, "k_total": 0.35}], "definition": "Signups per member"},
            "introducers": {"intros": [{"introducer_kind": "friend", "intros": 12, "matched": 3, "match_rate": 0.25}]},
            "referrals_enabled": False, "referrals_note": "Referrals are switched off.", "data_status": {}})
        response = self.client.get(reverse("business_referrals"), {"bucket": "week"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Referrals are switched off.")
        self.assertContains(response, "0.35")
        self.assertContains(response, "25.0%")
        self.assertNotIn("bucket", api.business_report.call_args.args[1])

    def test_market_save_confirms_and_reports_failure(self):
        """[case:console.business.business_market_save.performs]"""
        api = self.bff()
        form = {"city_key": "Pune", "display_name": "Pune", "country": "India", "currency": "inr", "verified_target": "2000"}
        response = self.client.post(reverse("business_market_save"), form)
        self.assertIn("Launch market saved.", flash(response))
        self.assertEqual(api.save_launch_market.call_args.args[0]["city_key"], "pune")
        api.save_launch_market.return_value = bff_error("currency must be ISO 4217", 400)
        self.assertIn("currency must be ISO 4217", flash(self.client.post(reverse("business_market_save"), form)))

    def test_market_save_authz(self):
        """[case:console.business.business_market_save.authz]"""
        self.assert_action_authz(reverse("business_market_save"), {"city_key": "pune", "verified_target": "2000"}, "save_launch_market",
                                 refused_roles=("analyst", "trust_safety"), allowed_roles=("finance", "ops_admin"), module=self.module)

    def test_spend_save_authz(self):
        """[case:console.business.business_spend_save.authz]"""
        self.assert_action_authz(reverse("business_spend_save"), {"month": "2026-09", "channel": "search", "currency": "INR", "amount": "1"},
                                 "save_marketing_spend", refused_roles=("ops_admin", "analyst"), allowed_roles=("finance",),
                                 module=self.module)

    def test_spend_delete_confirms_and_rejects_bad_ids(self):
        """[case:console.business.business_spend_delete.performs]"""
        api = self.bff()
        spend = str(uuid4())
        response = self.client.post(reverse("business_spend_delete", args=[spend]))
        api.delete_marketing_spend.assert_called_once_with(spend)
        self.assertRedirects(response, reverse("business_spend"), fetch_redirect_response=False)
        self.assertIn("Spend entry deleted.", flash(response))
        self.assertEqual(self.client.post(reverse("business_spend_delete", args=["not-a-uuid"])).status_code, 404)
        self.assertEqual(api.delete_marketing_spend.call_count, 1)

    def test_spend_delete_authz(self):
        """[case:console.business.business_spend_delete.authz]"""
        self.assert_action_authz(reverse("business_spend_delete", args=[str(uuid4())]), {}, "delete_marketing_spend",
                                 refused_roles=("ops_admin", "analyst"), allowed_roles=("finance",), module=self.module)


class CityPilotCasesTest(ConsoleCaseTest):
    module = "control_panel.views_city_pilot"
    EXPERIENCE = {"id": "", "title": "Board games night", "summary": "Small group", "venue": "Cafe Lumen", "host": "Asha",
                  "accessibility": "Step-free", "safety_contact": "+91 98000 00000", "capacity": "12", "host_vetted": "on",
                  "starts_at": "2027-01-10T18:00", "ends_at": "2027-01-10T20:00", "registration_closes_at": "2027-01-09T18:00"}

    def test_page_bff_failure_shows_error(self):
        """[case:console.city_pilot.city_pilot.renders]"""
        self.bff().city_pilot.return_value = bff_error("pilot store unavailable", 503)
        response = self.client.get(reverse("city_pilot"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "pilot store unavailable")

    def test_save_authz(self):
        """[case:console.city_pilot.city_pilot_save.authz]"""
        form = {"city": "Pune", "starts_at": "2027-01-01T10:00", "closes_at": "2027-01-15T10:00"}
        self.assert_action_authz(reverse("city_pilot_save"), form, "save_city_pilot",
                                 refused_roles=("trust_safety", "analyst"), allowed_roles=("ops_admin",), module=self.module)

    def test_stage_success(self):
        """[case:console.city_pilot.city_pilot_stage.performs]"""
        api = self.bff()
        pilot = uuid4()
        response = self.client.post(reverse("city_pilot_stage", args=[pilot]), {"status": "measuring", "version": "3", "note": " Go ", "safety_ready": "on"})
        api.transition_city_pilot.assert_called_once_with(pilot, {"status": "measuring", "version": 3, "note": "Go", "safety_ready": True})
        self.assertIn("Pilot stage updated.", flash(response))
        self.assertIn("Refresh the pilot before changing its stage.",
                      flash(self.client.post(reverse("city_pilot_stage", args=[pilot]), {"status": "paused", "version": "v3"})))
        self.assertEqual(api.transition_city_pilot.call_count, 1)

    def test_stage_authz(self):
        """trust_safety may pause/resume a pilot; analysts may not. [case:console.city_pilot.city_pilot_stage.authz]"""
        self.assert_action_authz(reverse("city_pilot_stage", args=[uuid4()]), {"status": "paused", "version": "1"}, "transition_city_pilot",
                                 refused_roles=("analyst", "support"), allowed_roles=("trust_safety", "ops_admin"), module=self.module)

    def test_experience_create_forwards_utc_times(self):
        """[case:console.city_pilot.city_pilot_experience_create.performs]"""
        api = self.bff()
        pilot = uuid4()
        event_id = str(uuid4())
        response = self.client.post(reverse("city_pilot_experience_create", args=[pilot]), {**self.EXPERIENCE, "id": event_id})
        sent_pilot, payload = api.create_city_pilot_experience.call_args.args
        self.assertEqual(sent_pilot, pilot)
        self.assertEqual(payload["id"], event_id)
        self.assertEqual(payload["capacity"], 12)
        self.assertTrue(payload["host_vetted"])
        self.assertEqual(payload["starts_at"], "2027-01-10T18:00:00+00:00")
        self.assertRedirects(response, reverse("city_pilot"), fetch_redirect_response=False)
        self.assertIn("Free experience published to pilot members.", flash(response))
        self.assertIn("Use valid UTC dates and a capacity from 2 to 30.",
                      flash(self.client.post(reverse("city_pilot_experience_create", args=[pilot]), {**self.EXPERIENCE, "starts_at": "soon"})))
        self.assertEqual(api.create_city_pilot_experience.call_count, 1)
        api.create_city_pilot_experience.return_value = bff_error("pilot is not in the experiences stage", 409)
        self.assertIn("pilot is not in the experiences stage",
                      flash(self.client.post(reverse("city_pilot_experience_create", args=[pilot]), self.EXPERIENCE)))

    def test_experience_create_authz(self):
        """trust_safety cannot publish experiences (Go allows them only stage changes and cancellations). [case:console.city_pilot.city_pilot_experience_create.authz]"""
        self.assert_action_authz(reverse("city_pilot_experience_create", args=[uuid4()]), self.EXPERIENCE, "create_city_pilot_experience",
                                 refused_roles=("trust_safety", "analyst"), allowed_roles=("ops_admin",), module=self.module)

    def test_experience_cancel(self):
        """[case:console.city_pilot.city_pilot_experience_cancel.performs]"""
        api = self.bff()
        pilot, event = uuid4(), uuid4()
        response = self.client.post(reverse("city_pilot_experience_cancel", args=[pilot, event]))
        api.cancel_city_pilot_experience.assert_called_once_with(pilot, event)
        self.assertIn("Experience cancelled.", flash(response))
        api.cancel_city_pilot_experience.return_value = bff_error("experience already cancelled", 409)
        self.assertIn("experience already cancelled", flash(self.client.post(reverse("city_pilot_experience_cancel", args=[pilot, event]))))

    def test_experience_cancel_authz(self):
        """[case:console.city_pilot.city_pilot_experience_cancel.authz]"""
        self.assert_action_authz(reverse("city_pilot_experience_cancel", args=[uuid4(), uuid4()]), {}, "cancel_city_pilot_experience",
                                 refused_roles=("analyst", "finance"), allowed_roles=("trust_safety",), module=self.module)
