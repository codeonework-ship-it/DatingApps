from unittest.mock import patch
from uuid import uuid4

from django.test import Client, TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult, BinaryAPIResult

EMPTY_STATUS = {
    "empty": True,
    "release_note": "Billing is excluded from release 1 (PEN-25).",
    "billing_flag_enabled": False,
    "payments_provider": "",
    "payment_mode": "disabled",
}


def envelope(report, **extra):
    data = {
        "report": report,
        "mode": "live",
        "window": {"since": "2026-09-01T00:00:00Z", "until": "2026-10-01T00:00:00Z", "timezone": "UTC", "bucket": "day"},
        "suppression": {"threshold": 5},
        "data_status": EMPTY_STATUS,
        "tables": [],
    }
    data.update(extra)
    return APIResult(True, data)


class BusinessViewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access"
        session["operator_refresh_token"] = "refresh"
        session.save()
        health = patch("control_panel.views.GoBFFClient")
        self.addCleanup(health.stop)
        health.start().return_value.health.return_value = APIResult(True, {"status": "ok"})

    def test_login_required(self):
        self.assertEqual(Client().get(reverse("business_revenue")).status_code, 302)

    @patch("control_panel.views_business.GoBFFClient")
    def test_empty_revenue_explains_release_one(self, cls):
        """[case:console.business.business_revenue.renders]"""
        cls.return_value.business_report.return_value = envelope("revenue", totals=[], trend=[], by_product=[], by_city=[])
        response = self.client.get(reverse("business_revenue"))
        self.assertContains(response, "PEN-25")
        self.assertContains(response, "No live payments in this window")
        self.assertContains(response, "Reconciliation")
        for name in ("Subscriptions &amp; MRR", "Market readiness", "Investor KPI pack", "Marketing spend"):
            self.assertContains(response, name)

    @patch("control_panel.views_business.GoBFFClient")
    def test_revenue_forwards_validated_filters_and_renders_currencies(self, cls):
        """[case:console.business.business_revenue.renders]"""
        cls.return_value.business_report.return_value = envelope(
            "revenue",
            data_status={**EMPTY_STATUS, "empty": False, "sandbox_hint": "Sandbox payments exist in this window"},
            tables=["trend", "totals"],
            totals=[{"currency": "INR", "market": "India", "net": "193.00", "net_minor": 19300, "gross": "212.00", "paying_members": "<5", "arppu": None}],
            trend=[{"bucket": "2026-09-01", "currency": "INR", "net_minor": 19300, "refunded_minor": 0, "net": "193.00"}],
            by_product=[], by_city=[{"city": "<script>x</script>", "currency": "INR", "paying_members": 7, "net": "1.00"}],
        )
        response = self.client.get(reverse("business_revenue"), {"since": "2026-09-01", "until": "bad", "tz": "Asia/Kolkata", "mode": "all", "bucket": "week"})
        sent = cls.return_value.business_report.call_args.args
        self.assertEqual(sent[0], "revenue")
        self.assertEqual(sent[1], {"since": "2026-09-01", "tz": "Asia/Kolkata", "mode": "all", "bucket": "week"})
        self.assertContains(response, "193.00 INR")
        self.assertContains(response, "&lt;5")
        self.assertContains(response, "&lt;script&gt;")
        self.assertContains(response, "Sandbox payments exist")
        self.assertContains(response, "totals.csv")
        self.assertContains(response, 'id="biz-charts"')

    @patch("control_panel.views_business.GoBFFClient")
    def test_subscriptions_waterfall_uses_one_currency(self, cls):
        """[case:console.business.business_subscriptions.renders]"""
        moves = [
            {"bucket": "2026-08-01", "currency": "INR", "mrr_start_minor": 0, "new_minor": 2000, "expansion_minor": 0, "contraction_minor": 0, "churned_minor": 0, "mrr_end_minor": 2000},
            {"bucket": "2026-09-01", "currency": "INR", "mrr_start_minor": 2000, "new_minor": 0, "expansion_minor": 1000, "contraction_minor": 0, "churned_minor": 500, "mrr_end_minor": 2500},
            {"bucket": "2026-09-01", "currency": "GBP", "mrr_start_minor": 0, "new_minor": 999, "expansion_minor": 0, "contraction_minor": 0, "churned_minor": 0, "mrr_end_minor": 999},
        ]
        cls.return_value.business_report.return_value = envelope("subscriptions", movements=moves, mrr=[], churn={"reasons": [{"reason": "graduated", "subscribers": "<5", "healthy": True}]}, plan_mix=[], trials={"offered": False, "note": "No trials"})
        response = self.client.get(reverse("business_subscriptions"), {"currency": "INR"})
        waterfall = response.context["charts"]["waterfall"]
        self.assertEqual(waterfall["currency"], "INR")
        self.assertEqual(waterfall["data"][0], [0, 0.0])
        self.assertEqual(waterfall["data"][-1], [0, 25.0])
        self.assertContains(response, "Not offered")
        self.assertEqual(cls.return_value.business_report.call_args.args[1]["bucket"], "month")

    @patch("control_panel.views_business.GoBFFClient")
    def test_conversion_page_calls_conversion_and_funnel(self, cls):
        """[case:console.business.business_conversion.renders]"""
        cls.return_value.business_report.side_effect = [
            envelope("conversion", cohorts=[{"cohort": "2026-09", "members": 12, "paid_30d": "<5", "conversion_to_date": 0.25}], ltv=[], actives_conversion={"rate": 0.05}),
            envelope("funnel", totals={"created": 6, "completed": 5, "paid": 5, "refunded": "<5"}, detail=[], instrumentation={"paywall_views": "not instrumented", "platform": "not captured"}),
        ]
        response = self.client.get(reverse("business_conversion"))
        reports = [c.args[0] for c in cls.return_value.business_report.call_args_list]
        self.assertEqual(reports, ["conversion", "funnel"])
        self.assertEqual(response.context["funnel_chart"]["data"], [6, 5, 5, None])
        self.assertContains(response, "25.0%")
        self.assertContains(response, "not instrumented")

    @patch("control_panel.views_business.GoBFFClient")
    def test_markets_shows_status_and_saves_gates(self, cls):
        """[case:console.business.business_markets.renders] [case:console.business.business_market_save.performs]"""
        cls.return_value.business_report.return_value = envelope("markets", markets=[{
            "city": "Bengaluru", "city_key": "bengaluru", "configured": True, "status": "approaching", "members": 2000, "verified_members": 1600,
            "gates": {"verified_members": {"target": 3000, "progress": 0.5333, "met": False}, "gender_balance": {"largest_share": 0.58, "met": True}, "plans_kept_per_active": {"target": 0.08, "value": None}},
        }], default_gates={"verified_target": 3000})
        response = self.client.get(reverse("business_markets"))
        self.assertContains(response, "APPROACHING")
        self.assertContains(response, "53.3%")
        cls.return_value.save_launch_market.return_value = APIResult(True, {"created": True})
        response = self.client.post(reverse("business_market_save"), {"city_key": "Bengaluru", "display_name": "Bengaluru", "country": "India", "currency": "inr", "verified_target": "3000", "max_gender_share": "0.6", "aliases": "Bangalore, bengaluru urban"})
        self.assertEqual(response.status_code, 302)
        payload = cls.return_value.save_launch_market.call_args.args[0]
        self.assertEqual(payload["city_key"], "bengaluru")
        self.assertEqual(payload["currency"], "INR")
        self.assertEqual(payload["aliases"], ["bangalore", "bengaluru urban"])

    @patch("control_panel.views_business.GoBFFClient")
    def test_invalid_market_targets_do_not_call_api(self, cls):
        """[case:console.business.business_market_save.performs]"""
        self.client.post(reverse("business_market_save"), {"city_key": "x", "verified_target": "many"})
        cls.return_value.save_launch_market.assert_not_called()

    @patch("control_panel.views_business.GoBFFClient")
    def test_investor_pack_is_printable_and_flags_missing_spend(self, cls):
        """[case:console.business.business_investor_pack.renders]"""
        cls.return_value.business_report.return_value = envelope("investor-pack", months=[{
            "month": "2026-09", "members_total": 309, "new_members": 13, "mau": 38, "plans_kept": 0, "north_star": 0, "burn": "not available",
            "by_currency": [{"currency": "INR", "net": "0.00", "mrr": "19.99", "cac": "needs spend data", "marketing_spend": "needs spend data"}],
        }], inputs={"marketing_spend": {"recorded": False}, "burn": "not available from product data"}, definitions={"north_star": "weekly plans kept per active member"})
        response = self.client.get(reverse("business_investor_pack"), {"months": "6"})
        self.assertEqual(cls.return_value.business_report.call_args.args[1], {"months": "6"})
        self.assertContains(response, "window.print()")
        self.assertContains(response, "CAC and payback need spend data")
        self.assertContains(response, "needs spend data")
        self.assertContains(response, "not available")
        self.assertContains(response, "@media print")

    @patch("control_panel.views_business.GoBFFClient")
    def test_spend_form_records_and_deletes(self, cls):
        """[case:console.business.business_spend.renders] [case:console.business.business_spend_save.performs] [case:console.business.business_spend_delete.performs]"""
        cls.return_value.business_report.return_value = envelope("marketing-spend", entries=[], cac=[], channels=["paid_social", "search"], markets=["all", "bengaluru"], status="needs spend data", note="No marketing spend recorded")
        response = self.client.get(reverse("business_spend"))
        self.assertContains(response, "No marketing spend recorded")
        self.assertContains(response, "bengaluru")
        cls.return_value.save_marketing_spend.return_value = APIResult(True, {"created": True})
        response = self.client.post(reverse("business_spend_save"), {"month": "2026-09", "channel": "search", "market": "all", "currency": "inr", "amount": "25000.50", "attributed_members": "12"})
        self.assertEqual(response.status_code, 302)
        payload = cls.return_value.save_marketing_spend.call_args.args[0]
        self.assertEqual(payload["currency"], "INR")
        self.assertEqual(payload["amount"], "25000.50")
        self.assertEqual(payload["attributed_members"], 12)
        spend_id = str(uuid4())
        cls.return_value.delete_marketing_spend.return_value = APIResult(True, {"deleted": True})
        self.client.post(reverse("business_spend_delete", args=[spend_id]))
        cls.return_value.delete_marketing_spend.assert_called_once_with(spend_id)

    @patch("control_panel.views_business.GoBFFClient")
    def test_spend_rejects_bad_month_and_shows_api_errors(self, cls):
        """[case:console.business.business_spend_save.performs]"""
        self.client.post(reverse("business_spend_save"), {"month": "September", "channel": "search", "currency": "INR", "amount": "1"})
        cls.return_value.save_marketing_spend.assert_not_called()
        cls.return_value.save_marketing_spend.return_value = APIResult(False, {}, "this report requires one of the roles: admin, finance", 403)
        cls.return_value.business_report.return_value = envelope("marketing-spend", entries=[], cac=[], channels=[], markets=["all"])
        response = self.client.post(reverse("business_spend_save"), {"month": "2026-09", "channel": "search", "currency": "INR", "amount": "1"}, follow=True)
        self.assertContains(response, "requires one of the roles")

    @patch("control_panel.views_business.GoBFFClient")
    def test_csv_download_proxies_table_and_filters(self, cls):
        """[case:console.business.business_csv.renders]"""
        cls.return_value.business_csv.return_value = BinaryAPIResult(ok=True, content=b"currency,net\r\nINR,193.00\r\n", content_type="text/csv")
        response = self.client.get(reverse("business_csv", args=["revenue"]), {"table": "totals", "mode": "sandbox", "since": "2026-09-01"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "text/csv; charset=utf-8")
        self.assertIn("attachment", response["Content-Disposition"])
        self.assertEqual(response.content, b"currency,net\r\nINR,193.00\r\n")
        report, params = cls.return_value.business_csv.call_args.args
        self.assertEqual(report, "revenue")
        self.assertEqual(params, {"since": "2026-09-01", "mode": "sandbox", "table": "totals"})
        self.assertEqual(self.client.get(reverse("business_csv", args=["passwords"])).status_code, 404)

    def test_csrf_required_for_spend(self):
        """[case:console.business.business_spend_save.authz]"""
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session["operator_access_token"] = "a"
        session["operator_refresh_token"] = "r"
        session.save()
        self.assertEqual(client.post(reverse("business_spend_save"), {"month": "2026-09"}).status_code, 403)


class BillingRevenuePageTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access"
        session["operator_refresh_token"] = "refresh"
        session.save()

    @patch("control_panel.views.GoBFFClient")
    def test_revenue_page_uses_windowed_per_currency_api(self, cls):
        """[case:console.billing.billing_revenue_analytics.renders]"""
        client = cls.return_value
        client.health.return_value = APIResult(True, {"status": "ok"})
        client.get_revenue_analytics.return_value = APIResult(True, {
            "window": {"since": "2026-09-01T00:00:00Z", "until": "2026-10-01T00:00:00Z", "timezone": "UTC"},
            "mode": "live",
            "data_status": {"empty": False},
            "revenue": [{"currency": "INR", "market": "India", "gross": "212.00", "net": "193.00", "paying_members": "<5"},
                        {"currency": "GBP", "market": "United Kingdom", "gross": "9.99", "net": "9.99", "paying_members": "<5"}],
            "payments": {"by_status": [{"status": "success", "currency": "INR", "count": 3, "amount_minor": 19300, "refunded_minor": 0}]},
            "coin_purchases": {"purchased_coins": 300, "purchases": [], "non_revenue": {"admin_topup": {"count": 1, "coins": 1000}}, "note": "grants are never revenue"},
            "subscriptions": {"by_status": {"active": "<5"}, "started_in_window": 0},
            "local_activations": [{"currency": "INR", "payments": 1}],
        })
        response = self.client.get(reverse("billing_revenue_analytics"), {"since": "2026-09-01", "mode": "all", "tz": "Asia/Kolkata"})
        self.assertEqual(client.get_revenue_analytics.call_args.args[0], {"since": "2026-09-01", "tz": "Asia/Kolkata", "mode": "all"})
        self.assertContains(response, "193.00")
        self.assertContains(response, "9.99")
        self.assertContains(response, "admin_topup")
        self.assertContains(response, "Local activations excluded")
        self.assertNotContains(response, "Total Paid (paise)")

    @patch("control_panel.views.GoBFFClient")
    def test_revenue_page_empty_state(self, cls):
        """[case:console.billing.billing_revenue_analytics.renders]"""
        client = cls.return_value
        client.health.return_value = APIResult(True, {"status": "ok"})
        client.get_revenue_analytics.return_value = APIResult(True, {"mode": "live", "revenue": [], "data_status": {"empty": True, "release_note": "Billing is excluded from release 1 (PEN-25)."}})
        response = self.client.get(reverse("billing_revenue_analytics"))
        self.assertContains(response, "No live payments in this window")
        self.assertContains(response, "PEN-25")
