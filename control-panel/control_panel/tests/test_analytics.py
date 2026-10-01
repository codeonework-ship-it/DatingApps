from unittest.mock import MagicMock, patch
from uuid import uuid4

from django.test import Client, TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult, GoBFFClient


def report(tables, **extra):
    return APIResult(True, {"success": True, "from": "2026-09-01", "to": "2026-09-28",
                            "tables": tables, "meta": {"latest_built_day": "2026-09-30", **extra}})


def table(columns, rows):
    return {"columns": [{"key": k, "label": label, "kind": kind, **({"unit": unit} if unit else {})} for k, label, kind, unit in columns], "rows": rows}


KPI_TILES = report({"tiles": table(
    [("key", "KPI", "dimension", ""), ("value", "Value", "number", ""), ("previous", "Prev", "number", "")],
    [
        {"key": "dau", "label": "DAU", "unit": "members", "definition": "Active on the day.", "value": 120, "previous": 100, "suppressed": []},
        {"key": "mau", "label": "MAU", "unit": "members", "definition": "Active in 30 days.", "value": 900, "previous": 850, "suppressed": []},
        {"key": "plans_kept_per_active_member", "label": "Weekly plans kept per active member", "unit": "per member", "definition": "North star.", "value": 0.0812, "previous": None, "suppressed": ["previous"]},
        {"key": "womens_good_day_rate", "label": "Women's weekly good-day rate", "unit": "%", "definition": "Good days.", "value": 41.5, "previous": 39.0, "suppressed": []},
    ])}, as_of="2026-09-30")


def series(rows):
    return report({"series": table([("period", "Period", "dimension", ""), ("value", "Value", "count", "")], rows)})


class AnalyticsPagesTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access"
        session["operator_refresh_token"] = "refresh"
        session.save()

    def test_login_required(self):
        self.assertEqual(Client().get(reverse("analytics_overview")).status_code, 302)

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_overview_renders_tiles_chart_and_table_with_suppression(self, cls):
        def fake(name, params):
            if name == "kpis":
                return KPI_TILES
            return series([
                {"period": "2026-09-27", "value": 110, "suppressed": []},
                {"period": "2026-09-28", "value": None, "suppressed": ["value"]},
            ])
        cls.return_value.analytics_report.side_effect = fake
        response = self.client.get(reverse("analytics_overview"), {"from": "2026-09-01", "to": "2026-09-28", "gender": "female", "city": "Pune", "grain": "week"})
        self.assertContains(response, "Weekly plans kept per active member")
        self.assertContains(response, "0.0812")
        self.assertContains(response, "41.5%")
        self.assertContains(response, "&lt;5")  # suppressed previous value and table cell
        self.assertContains(response, 'data-analytics-chart="chart-active"')
        self.assertContains(response, '<table class="glass-table')
        self.assertContains(response, "/analytics/export/trends/?")
        trends_calls = [c for c in cls.return_value.analytics_report.call_args_list if c.args[0] == "trends"]
        self.assertEqual({c.args[1]["metric"] for c in trends_calls}, {"dau", "wau", "mau"})
        self.assertEqual(trends_calls[0].args[1]["gender"], "female")
        self.assertEqual(trends_calls[0].args[1]["city"], "Pune")
        self.assertEqual(trends_calls[0].args[1]["grain"], "week")
        kpi_call = [c for c in cls.return_value.analytics_report.call_args_list if c.args[0] == "kpis"][0]
        self.assertEqual(kpi_call.args[1]["as_of"], "2026-09-28")

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_invalid_filters_are_not_forwarded(self, cls):
        cls.return_value.analytics_report.return_value = series([])
        self.client.get(reverse("analytics_engagement"), {"from": "2026-13-45", "gender": "robot", "level_band": "L9", "city": "x" * 200})
        params = cls.return_value.analytics_report.call_args.args[1]
        for key in ("from", "gender", "level_band", "city"):
            self.assertNotIn(key, params)

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_member_role_sees_role_message(self, cls):
        cls.return_value.analytics_report.return_value = APIResult(False, {}, "operator role does not permit this administrative action", 403)
        response = self.client.get(reverse("analytics_funnel"))
        self.assertContains(response, "require the analyst or admin role")

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_funnel_forwards_window_and_renders_both_tables(self, cls):
        steps = table([("cohort", "Cohort", "dimension", ""), ("step_label", "Step", "dimension", ""), ("members", "Members", "count", ""),
                       ("conversion_from_previous", "From previous", "ratio", "%")],
                      [{"cohort": "2026-09-01", "step_label": "Signed up", "members": 40, "conversion_from_previous": 100, "suppressed": []},
                       {"cohort": "2026-09-01", "step_label": "Date kept", "members": None, "conversion_from_previous": None, "suppressed": ["members", "conversion_from_previous"]}])
        cls.return_value.analytics_report.return_value = report({"steps": steps})
        response = self.client.get(reverse("analytics_funnel"), {"within_days": "14"})
        self.assertContains(response, "Signed up")
        self.assertContains(response, "100%")
        self.assertContains(response, "within 14 days")
        cohorts = {c.args[1]["cohort"] for c in cls.return_value.analytics_report.call_args_list}
        self.assertEqual(cohorts, {"all", "week"})
        self.assertTrue(all(c.args[1]["within_days"] == "14" for c in cls.return_value.analytics_report.call_args_list))

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_retention_heatmap_and_experiment(self, cls):
        summary = table([("cohort", "Cohort", "dimension", ""), ("d7", "D7", "ratio", "%")], [{"cohort": "2026-09-01", "d7": 25.5, "suppressed": []}])
        triangle = table([("cohort_week", "Week", "dimension", ""), ("week_0", "Week 0", "ratio", "%"), ("week_1", "Week 1", "ratio", "%")],
                         [{"cohort_week": "2026-09-01", "week_0": 100, "week_1": None, "suppressed": []}])
        cls.return_value.analytics_report.return_value = report({"summary": summary, "triangle": triangle})
        response = self.client.get(reverse("analytics_retention"), {"experiment": "match_nudge_v1"})
        self.assertContains(response, "25.5%")
        self.assertContains(response, "rgba(57,135,229,1.0)")
        self.assertEqual(cls.return_value.analytics_report.call_args.args[1]["experiment"], "match_nudge_v1")
        self.client.get(reverse("analytics_retention"), {"experiment": "bad key;"})
        self.assertNotIn("experiment", cls.return_value.analytics_report.call_args.args[1])

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_liquidity_and_safety_escape_member_text(self, cls):
        cities = table([("city", "City", "dimension", ""), ("active_members", "Active", "count", ""), ("women", "Women", "count", ""), ("men", "Men", "count", "")],
                       [{"city": "<script>x()</script>", "active_members": 50, "women": 20, "men": None, "suppressed": ["men"]}])
        cls.return_value.analytics_report.return_value = report({"cities": cities})
        response = self.client.get(reverse("analytics_liquidity"))
        self.assertContains(response, "&lt;script&gt;x()&lt;/script&gt;")
        self.assertNotContains(response, "<script>x()</script>")
        cls.return_value.analytics_report.return_value = report({
            "trend": table([("period", "Period", "dimension", ""), ("reports_per_1k_dau", "Per 1k", "ratio", "")], [{"period": "2026-09-01", "reports_per_1k_dau": 1.25, "suppressed": []}]),
            "queues": table([("queue", "Queue", "dimension", "")], []),
            "by_surface": table([("surface", "Surface", "dimension", "")], []),
        })
        response = self.client.get(reverse("analytics_safety"))
        self.assertContains(response, "1.25")
        self.assertContains(response, "Time to action")

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_data_page_rebuild_and_flags(self, cls):
        cls.return_value.analytics_snapshots.return_value = APIResult(True, {"built_days": 30, "final_days": 28, "missing_days": ["2026-09-12"],
                                                                             "exclusions": {"operator_account": 3}, "settings": [], "runs": [], "window_days": 35})
        cls.return_value.analytics_excluded_accounts.return_value = APIResult(False, {}, "forbidden", 403)
        response = self.client.get(reverse("analytics_data"))
        self.assertContains(response, "2026-09-12")
        self.assertContains(response, "operator_account")
        self.assertContains(response, "admin-only")

        cls.return_value.analytics_rebuild.return_value = APIResult(True, {"run_id": "run-1"}, status_code=202)
        response = self.client.post(reverse("analytics_rebuild"), {"from": "2026-09-01", "to": "2026-09-03"}, follow=True)
        cls.return_value.analytics_rebuild.assert_called_once_with("2026-09-01", "2026-09-03")
        self.assertContains(response, "run-1")
        cls.return_value.analytics_rebuild.reset_mock()
        self.client.post(reverse("analytics_rebuild"), {"from": "nope", "to": "2026-09-03"})
        cls.return_value.analytics_rebuild.assert_not_called()

        member = str(uuid4())
        cls.return_value.analytics_exclude_account.return_value = APIResult(True, {})
        self.client.post(reverse("analytics_exclude"), {"member_id": member, "reason": "QA phone"})
        cls.return_value.analytics_exclude_account.assert_called_once_with(member, "QA phone")
        self.client.post(reverse("analytics_exclude"), {"member_id": "not-a-uuid", "reason": "QA phone"})
        self.assertEqual(cls.return_value.analytics_exclude_account.call_count, 1)
        cls.return_value.analytics_include_account.return_value = APIResult(True, {})
        self.client.post(reverse("analytics_include", args=[member]))
        cls.return_value.analytics_include_account.assert_called_once_with(member)

    def test_mutations_require_csrf(self):
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session["operator_access_token"] = "access"
        session["operator_refresh_token"] = "refresh"
        session.save()
        self.assertEqual(client.post(reverse("analytics_rebuild"), {"from": "2026-09-01", "to": "2026-09-02"}).status_code, 403)

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_csv_export_streams_and_whitelists_params(self, cls):
        upstream = MagicMock()
        upstream.iter_content.return_value = [b"period,value\n", b"2026-09-01,<5\n"]
        upstream.headers = {"Content-Disposition": 'attachment; filename="connect_trends_series.csv"'}
        cls.return_value.analytics_report_csv.return_value = (upstream, "")
        cls.ANALYTICS_REPORTS = GoBFFClient.ANALYTICS_REPORTS
        response = self.client.get(reverse("analytics_export", args=["trends"]), {"metric": "dau", "gender": "female", "evil": "1"})
        self.assertEqual(response["Content-Type"], "text/csv; charset=utf-8")
        self.assertIn("connect_trends_series.csv", response["Content-Disposition"])
        self.assertEqual(b"".join(response.streaming_content), b"period,value\n2026-09-01,<5\n")
        upstream.close.assert_called_once()
        name, params = cls.return_value.analytics_report_csv.call_args.args
        self.assertEqual(name, "trends")
        self.assertEqual(params, {"metric": "dau", "gender": "female"})
        self.assertEqual(self.client.get(reverse("analytics_export", args=["users"])).status_code, 404)

    @patch("control_panel.views_analytics.GoBFFClient")
    def test_csv_export_error_redirects(self, cls):
        cls.return_value.analytics_report_csv.return_value = (None, "operator role does not permit this administrative action")
        cls.ANALYTICS_REPORTS = GoBFFClient.ANALYTICS_REPORTS
        response = self.client.get(reverse("analytics_export", args=["kpis"]))
        self.assertEqual(response.status_code, 302)


class DashboardDurableKpiTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access"
        session["operator_refresh_token"] = "refresh"
        session.save()

    def _client(self, cls):
        client = cls.return_value
        for method in ("health", "readiness", "list_verifications", "list_activities", "list_users", "list_reports",
                       "list_appeals", "list_media_moderation", "list_sos_alerts", "list_audit_events",
                       "list_domain_events", "domain_event_metrics"):
            getattr(client, method).return_value = APIResult(True, {})
        client.analytics_overview.return_value = APIResult(True, {"metrics": {"member_activity": {"available": True, "dau": 7, "mau": 70}}})
        return client

    @patch("control_panel.views.GoBFFClient")
    def test_dashboard_uses_durable_snapshot_kpis(self, cls):
        self._client(cls).analytics_report.return_value = KPI_TILES
        response = self.client.get(reverse("dashboard"))
        self.assertContains(response, "UTC day 2026-09-30")
        self.assertContains(response, "analytics snapshots")
        self.assertContains(response, "Weekly plans kept per active member")
        self.assertContains(response, "0.0812")
        self.assertNotContains(response, "Unlock completion")

    @patch("control_panel.views.GoBFFClient")
    def test_dashboard_falls_back_to_live_activity_without_analyst_role(self, cls):
        self._client(cls).analytics_report.return_value = APIResult(False, {}, "forbidden", 403)
        response = self.client.get(reverse("dashboard"))
        self.assertContains(response, "Trailing 24 hours")
        self.assertContains(response, "Requires the analyst or admin role")
