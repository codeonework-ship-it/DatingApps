"""Pages whose filters are plain GET forms (not the shared list toolbar):
product analytics, server activity, business subscriptions, revenue
analytics, the command center and the activity feed. Each test sends every
filter, asserts exactly what reaches the patched GoBFFClient (invalid values
never do) and what the page renders.

Fixtures use the Go handlers' JSON keys: server_admin_analytics_reports.go,
admin_system.go, capacity_snapshot.go, business_subscriptions.go,
business_conversion.go and store.go (activityEvent).
"""
from __future__ import annotations

from django.urls import reverse

from control_panel.services.go_client import APIResult

from .case_support import ConsoleCaseTest, bff_error

MEMBER = "11111111-1111-4111-8111-111111111111"
SEGMENTS = {"gender": "female", "age_band": "25-29", "account_age_band": "days_30_89", "level_band": "L4-L7"}
BAD_SEGMENTS = {"gender": "robot", "age_band": "12-15", "account_age_band": "forever", "level_band": "L99", "city": "x" * 101}


def analytics(name: str, tables: dict, **meta) -> APIResult:
    return APIResult(True, {"success": True, "report": name, "from": "2026-09-01", "to": "2026-09-28", "segments": {},
                            "tables": tables, "meta": {"suppression": {"threshold": 5}, "latest_built_day": "2026-09-28", **meta}})


def col(key, label, kind="dimension", unit=""):
    return {"key": key, "label": label, "kind": kind, **({"unit": unit} if unit else {})}


def series(rows):
    return analytics("trends", {"series": {"columns": [col("period", "Period start"), col("value", "Members", "count")], "rows": rows}})


class AnalyticsFilterCasesTest(ConsoleCaseTest):
    module = "control_panel.views_analytics"

    def calls(self, api):
        return [(c.args[0], c.args[1]) for c in api.analytics_report.call_args_list]

    def test_overview_filters(self):
        """Window, grain and every segment reach the KPI read (as of the last day) and the three trend reads; invalid values are dropped. [case:console.analytics.analytics_overview.filters]"""
        api = self.bff()
        api.analytics_report.side_effect = lambda name, params: (
            analytics("kpis", {"tiles": {"columns": [col("key", "KPI"), col("value", "Value", "number")],
                                         "rows": [{"key": "dau", "label": "DAU", "value": 120, "previous": 100, "unit": "members",
                                                   "definition": "", "suppressed": []}]}}, as_of="2026-09-28")
            if name == "kpis" else series([{"period": "2026-09-27", "value": 110, "suppressed": []}]))
        response = self.client.get(reverse("analytics_overview"), {"from": "2026-09-01", "to": "2026-09-28", "grain": "week", "city": "Pune", **SEGMENTS})
        self.assertEqual(response.status_code, 200)
        segments = {**SEGMENTS, "city": "Pune"}
        self.assertEqual(self.calls(api), [
            ("kpis", {"to": "2026-09-28", **segments, "as_of": "2026-09-28"}),
            ("trends", {"from": "2026-09-01", "to": "2026-09-28", **segments, "grain": "week", "metric": "dau"}),
            ("trends", {"from": "2026-09-01", "to": "2026-09-28", **segments, "grain": "week", "metric": "wau"}),
            ("trends", {"from": "2026-09-01", "to": "2026-09-28", **segments, "grain": "week", "metric": "mau"}),
        ])
        self.assertContains(response, 'value="Pune"')
        self.assertContains(response, '<option value="25-29" selected>')
        api.analytics_report.reset_mock()
        self.client.get(reverse("analytics_overview"), {"from": "2026-02-30", "to": "28/09/2026", "grain": "year", **BAD_SEGMENTS})
        self.assertEqual(self.calls(api)[0], ("kpis", {}))
        self.assertEqual(self.calls(api)[1], ("trends", {"grain": "day", "metric": "dau"}))

    def test_funnel_filters(self):
        """Window, segments and 'steps within days' reach both funnel reads; the funnel has no grain. [case:console.analytics.analytics_funnel.filters]"""
        api = self.bff()
        api.analytics_report.return_value = analytics("funnel", {"steps": {"columns": [col("step_label", "Step"), col("members", "Members", "count")],
                                                                           "rows": [{"step_label": "Signed up", "members": 40, "suppressed": []}]}})
        response = self.client.get(reverse("analytics_funnel"), {"from": "2026-08-01", "to": "2026-09-28", "grain": "week", "within_days": "14",
                                                                 "city": "Goa", **SEGMENTS})
        base = {"from": "2026-08-01", "to": "2026-09-28", **SEGMENTS, "city": "Goa", "within_days": "14"}
        self.assertEqual(self.calls(api), [("funnel", {**base, "cohort": "all"}), ("funnel", {**base, "cohort": "week"})])
        self.assertNotContains(response, 'name="grain"')
        api.analytics_report.reset_mock()
        self.client.get(reverse("analytics_funnel"), {"within_days": "400", **BAD_SEGMENTS})
        self.assertEqual(self.calls(api), [("funnel", {"cohort": "all"}), ("funnel", {"cohort": "week"})])

    def test_retention_filters(self):
        """Weekly cohorts by default; window, grain, segments and an experiment key reach Go. [case:console.analytics.analytics_retention.filters]"""
        api = self.bff()
        api.analytics_report.return_value = analytics("retention", {"summary": {"columns": [col("cohort", "Signup cohort")], "rows": []},
                                                                    "triangle": {"columns": [col("cohort_week", "Signup week")], "rows": []}})
        self.client.get(reverse("analytics_retention"), {"from": "2026-06-01", "to": "2026-09-28", "grain": "month", "city": "Pune",
                                                         "experiment": "match_nudge_v1", **SEGMENTS})
        self.assertEqual(self.calls(api), [("retention", {"from": "2026-06-01", "to": "2026-09-28", **SEGMENTS, "city": "Pune", "grain": "month",
                                                          "experiment": "match_nudge_v1"})])
        api.analytics_report.reset_mock()
        self.client.get(reverse("analytics_retention"), {"grain": "fortnight", "experiment": "Bad Key!"})
        self.assertEqual(self.calls(api), [("retention", {"grain": "week"})])

    def test_engagement_filters(self):
        """Window and segments reach Go; engagement has no grain. [case:console.analytics.analytics_engagement.filters]"""
        api = self.bff()
        api.analytics_report.return_value = analytics("engagement", {"surfaces": {"columns": [col("surface_label", "Surface")],
                                                                                  "rows": [{"surface_label": "Chat", "suppressed": []}]}})
        response = self.client.get(reverse("analytics_engagement"), {"from": "2026-09-01", "to": "2026-09-28", "grain": "week", "city": "Pune", **SEGMENTS})
        self.assertEqual(self.calls(api), [("engagement", {"from": "2026-09-01", "to": "2026-09-28", **SEGMENTS, "city": "Pune"})])
        self.assertContains(response, "Chat")
        self.assertContains(response, "/analytics/export/engagement/?")

    def test_liquidity_filters(self):
        """Window and the age/account/level bands reach Go; gender, city and grain are not offered (the report splits by them). [case:console.analytics.analytics_liquidity.filters]"""
        api = self.bff()
        api.analytics_report.return_value = analytics("liquidity", {"cities": {"columns": [col("city", "City"), col("active_members", "Active", "count")],
                                                                               "rows": [{"city": "Pune", "active_members": 50, "suppressed": []}]}})
        response = self.client.get(reverse("analytics_liquidity"), {"from": "2026-09-22", "to": "2026-09-28", "grain": "week", "city": "Pune", **SEGMENTS})
        bands = {k: v for k, v in SEGMENTS.items() if k != "gender"}
        self.assertEqual(self.calls(api), [("liquidity", {"from": "2026-09-22", "to": "2026-09-28", **bands})])
        self.assertNotContains(response, 'name="city"')
        self.assertNotContains(response, 'name="gender"')
        self.assertContains(response, 'name="level_band"')

    def test_safety_filters(self):
        """Weekly by default; window, grain and every segment reach Go. [case:console.analytics.analytics_safety.filters]"""
        api = self.bff()
        api.analytics_report.return_value = analytics("safety", {
            "trend": {"columns": [col("period", "Week"), col("reports_per_1k_dau", "Per 1k", "ratio")], "rows": []},
            "queues": {"columns": [col("queue", "Queue")], "rows": []}, "by_surface": {"columns": [col("surface", "Surface")], "rows": []}})
        self.client.get(reverse("analytics_safety"), {"from": "2026-08-01", "to": "2026-09-28", "grain": "day", "city": "Pune", **SEGMENTS})
        self.assertEqual(self.calls(api), [("safety", {"from": "2026-08-01", "to": "2026-09-28", **SEGMENTS, "city": "Pune", "grain": "day"})])
        api.analytics_report.reset_mock()
        self.client.get(reverse("analytics_safety"))
        self.assertEqual(self.calls(api), [("safety", {"grain": "week"})])


class SystemPageCasesTest(ConsoleCaseTest):
    module = "control_panel.views_system"

    def traffic(self, group_by="none"):
        rows = [{"bucket": "2026-10-02T10:00:00Z", "service": None, "method": None, "route": None, "status_class": None, "requests": 1200,
                 "server_errors": 3, "refused": 7, "avg_ms": 41.2, "p50_ms": 30.0, "p95_ms": 150.0, "p99_ms": 400.0}]
        if group_by == "route":
            rows[0]["route"] = "/v1/chat/{matchID}/messages"
        return APIResult(True, {"rows": rows, "totals": {"requests": 1200, "server_errors": 3, "refused": 7, "avg_ms": 41.2, "p95_ms": 150.0},
                                "from": "2026-10-01T00:00:00Z", "to": "2026-10-03T00:00:00Z", "grain": "hour", "group_by": group_by, "limit": 500})

    def test_traffic_renders_totals_rows_and_chart(self):
        """[case:console.system.system_requests.renders]"""
        api = self.bff()
        api.system_requests.return_value = self.traffic()
        response = self.client.get(reverse("system_requests"))
        self.assertEqual(response.status_code, 200)
        api.system_requests.assert_called_once_with(grain="hour", group_by="none")
        self.assertContains(response, "1,200")
        self.assertContains(response, "150 ms")
        self.assertEqual(response.context["chart"]["datasets"][0]["data"], [1200])
        api.system_requests.return_value = bff_error("forbidden", 403)
        self.assertContains(self.client.get(reverse("system_requests")), "This view is not available to your role.")

    def test_traffic_filters(self):
        """Window, grain, breakdown, status class, route, method and service reach Go; a route row shows the route (Go sends no method with it); values Go would refuse never reach it. [case:console.system.system_requests.filters]"""
        api = self.bff()
        api.system_requests.return_value = self.traffic("route")
        response = self.client.get(reverse("system_requests"), {"from": "2026-10-01", "to": "2026-10-02", "grain": "day", "group_by": "route",
                                                                "status_class": "5xx", "route": "/v1/chat/{matchID}/messages", "method": "post",
                                                                "service": "bff"})
        api.system_requests.assert_called_once_with(**{"from": "2026-10-01", "to": "2026-10-02"}, grain="day", group_by="route",
                                                    route="/v1/chat/{matchID}/messages", method="POST", service="bff", status_class="5xx")
        self.assertContains(response, '<td class="font-monospace small">/v1/chat/{matchID}/messages</td>', html=False)
        self.assertContains(response, '<option value="5xx" selected>')
        api.system_requests.reset_mock()
        self.client.get(reverse("system_requests"), {"from": "yesterday", "grain": "minute", "group_by": "country", "status_class": "9xx",
                                                     "method": "BREW", "route": "/v1/" + "r" * 400})
        api.system_requests.assert_called_once_with(grain="hour", group_by="none", route=("/v1/" + "r" * 400)[:300])

    def capacity(self):
        return APIResult(True, {
            "latest": {"at": "2026-10-03T00:00:00Z", "db_size_bytes": 5368709120, "connections": 12, "max_connections": 100, "outbox_rows": 90000,
                       "activity_rows": 400000, "security_event_rows": 1200, "media_bytes": {"profile_photos": 2147483648, "voice": 0},
                       "media_bytes_total": 2147483648,
                       "disk": {"media": {"free_bytes": 53687091200, "total_bytes": 107374182400, "used_percent": 50.0}}},
            "tables": [{"table": "matching.activity_events", "total_bytes": 1073741824, "table_bytes": 805306368, "index_bytes": 268435456,
                        "live_rows": 400000, "dead_rows": 1200, "last_autovacuum": "2026-10-02T03:00:00Z", "seq_scan": 4, "idx_scan": 90000}],
            "series": [{"at": "2026-10-03T00:00:00Z", "db_size_bytes": 5368709120, "outbox_rows": 90000, "activity_rows": 400000,
                        "media_bytes_total": 2147483648}]})

    def test_capacity_renders_latest_tables_media_and_disk(self):
        """The latest snapshot, largest tables, media sizes and disk usage (Go sends disk as free/total/used) render. [case:console.system.system_capacity.renders]"""
        api = self.bff()
        api.system_capacity.return_value = self.capacity()
        response = self.client.get(reverse("system_capacity"))
        api.system_capacity.assert_called_once_with()
        self.assertContains(response, "5.0 GB")
        self.assertContains(response, "matching.activity_events")
        self.assertContains(response, "profile_photos")
        self.assertContains(response, "Media disk: 50.0% used, 50.0 GB free of 100.0 GB")
        self.assertNotContains(response, "free_bytes")
        self.assertEqual(response.context["chart"]["datasets"][0]["data"], [5120.0])
        api.system_capacity.return_value = bff_error("capacity unavailable", 503)
        self.assertContains(self.client.get(reverse("system_capacity")), "capacity unavailable")

    def test_capacity_filters(self):
        """[case:console.system.system_capacity.filters]"""
        api = self.bff()
        api.system_capacity.return_value = self.capacity()
        response = self.client.get(reverse("system_capacity"), {"from": "2026-09-01", "to": "2026-10-01"})
        api.system_capacity.assert_called_once_with(**{"from": "2026-09-01", "to": "2026-10-01"})
        self.assertContains(response, 'value="2026-09-01"')
        api.system_capacity.reset_mock()
        self.client.get(reverse("system_capacity"), {"from": "1/9/2026", "to": "never"})
        api.system_capacity.assert_called_once_with()

    def third_party(self):
        return APIResult(True, {
            "rows": [{"day": "2026-10-01", "provider": "fcm", "operation": "send", "calls": 900, "failures": 12, "units": 900, "unit_label": "messages"}],
            "totals": [{"provider": "fcm", "operation": "send", "calls": 900, "failures": 12, "units": 900, "unit_label": "messages"}],
            "from": "2026-09-03", "to": "2026-10-03", "limit": 1000})

    def test_third_party_renders_totals_and_days(self):
        """[case:console.system.system_third_party.renders]"""
        api = self.bff()
        api.system_third_party.return_value = self.third_party()
        response = self.client.get(reverse("system_third_party"))
        api.system_third_party.assert_called_once_with()
        self.assertContains(response, "Totals in window")
        self.assertContains(response, "900 messages")
        self.assertContains(response, "2026-10-01")
        api.system_third_party.return_value = bff_error("forbidden", 403)
        self.assertContains(self.client.get(reverse("system_third_party")), "This view is not available to your role.")

    def test_third_party_filters(self):
        """[case:console.system.system_third_party.filters]"""
        api = self.bff()
        api.system_third_party.return_value = self.third_party()
        response = self.client.get(reverse("system_third_party"), {"from": "2026-09-01", "to": "2026-09-30"})
        api.system_third_party.assert_called_once_with(**{"from": "2026-09-01", "to": "2026-09-30"})
        self.assertContains(response, 'value="2026-09-30"')
        api.system_third_party.reset_mock()
        self.client.get(reverse("system_third_party"), {"from": "2026-13-01"})
        api.system_third_party.assert_called_once_with()


def movement(currency: str, start: int, new: int, churned: int) -> dict:
    row = {"bucket": "2026-09-01", "currency": currency, "subscribers_start": 10, "new_subscribers": 2, "expanded_subscribers": 0,
           "contracted_subscribers": 0, "churned_subscribers": "<5", "subscribers_end": 11, "logo_churn_rate": None, "revenue_churn_rate": 0.05,
           "net_mrr_retention": 1.01}
    for key, minor in (("mrr_start", start), ("new", new), ("expansion", 0), ("contraction", 0), ("churned", churned),
                       ("mrr_end", start + new - churned)):
        row[key], row[f"{key}_minor"] = f"{minor // 100}.{minor % 100:02d}", minor
    return row


class BusinessFilterCasesTest(ConsoleCaseTest):
    module = "control_panel.views_business"

    def test_subscriptions_window_and_currency(self):
        """The window, time zone, payments, period and months reach Go (monthly by default); the currency picker chooses the waterfall's currency from Go's movements. [case:console.business.business_subscriptions.filters]"""
        api = self.bff()
        api.business_report.return_value = APIResult(True, {"report": "subscriptions", "movements": [movement("EUR", 10000, 2000, 500),
                                                                                                      movement("INR", 400000, 80000, 30000)],
                                                            "churn": {"reasons": []}, "plan_mix": [], "mrr": []})
        response = self.client.get(reverse("business_subscriptions"), {"since": "2026-01-01", "until": "2026-09-30", "tz": "Asia/Kolkata",
                                                                       "mode": "all", "months": "6", "currency": "INR"})
        api.business_report.assert_called_once_with("subscriptions", {"since": "2026-01-01", "until": "2026-09-30", "tz": "Asia/Kolkata",
                                                                       "mode": "all", "bucket": "month", "months": "6"})
        waterfall = response.context["charts"]["waterfall"]
        self.assertEqual((waterfall["currency"], waterfall["data"][0], waterfall["data"][-1]), ("INR", [0, 4000.0], [0, 4500.0]))
        other = self.client.get(reverse("business_subscriptions"), {"currency": "JPY", "since": "bad", "months": "99"})
        self.assertEqual(other.context["charts"]["waterfall"]["currency"], "EUR")
        self.assertEqual(api.business_report.call_args.args, ("subscriptions", {"bucket": "month"}))

    def test_conversion_funnel_asks_for_month_buckets(self):
        """The conversion page's funnel read asks Go for month buckets, so a window longer than 400 days does not fail. [case:console.business.business_conversion.renders]"""
        api = self.bff()
        api.business_report.side_effect = lambda name, params: APIResult(True, {"report": name, "cohorts": [], "detail": [], "totals": {}})
        self.client.get(reverse("business_conversion"), {"since": "2024-01-01", "until": "2026-09-30", "mode": "live"})
        self.assertEqual([c.args for c in api.business_report.call_args_list],
                         [("conversion", {"since": "2024-01-01", "until": "2026-09-30", "mode": "live"}),
                          ("funnel", {"since": "2024-01-01", "until": "2026-09-30", "mode": "live", "bucket": "month"})])


class RevenueAnalyticsFilterTest(ConsoleCaseTest):
    def test_window_time_zone_and_mode_reach_go(self):
        """[case:console.billing.billing_revenue_analytics.filters]"""
        api = self.bff()
        api.get_revenue_analytics.return_value = APIResult(True, {"revenue": [], "payments": {}, "window": {"since": "2026-09-01", "until": "2026-09-30"},
                                                                  "mode": "sandbox", "data_status": {}})
        response = self.client.get(reverse("billing_revenue_analytics"), {"since": "2026-09-01", "until": "2026-09-30", "tz": "Asia/Kolkata", "mode": "sandbox"})
        api.get_revenue_analytics.assert_called_once_with({"since": "2026-09-01", "until": "2026-09-30", "tz": "Asia/Kolkata", "mode": "sandbox"})
        self.assertEqual((response.context["filters"]["tz"], response.context["mode"]), ("Asia/Kolkata", "sandbox"))
        api.get_revenue_analytics.reset_mock()
        self.client.get(reverse("billing_revenue_analytics"), {"since": "2026/09/01", "tz": "Mars/Base", "mode": "free"})
        api.get_revenue_analytics.assert_called_once_with({})


class DashboardFilterTest(ConsoleCaseTest):
    def test_member_focus_and_live_updates(self):
        """A member id focuses the logs link on that member; refresh=0 turns live updates off; an unsafe id never reaches the query. [case:console.dashboard.dashboard.filters]"""
        self.bff()
        response = self.client.get(reverse("dashboard"), {"user_id": MEMBER, "refresh": "0"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.context["focus_user_id"], MEMBER)
        self.assertIn(f'user_id : "{MEMBER}"', response.context["kibana_kql"])
        self.assertFalse(response.context["live_updates"])
        self.assertNotContains(response, 'data-live-topic="dashboard"')
        self.assertContains(response, f'value="{MEMBER}"')
        live = self.client.get(reverse("dashboard"), {"user_id": '" or 1=1 --', "refresh": "30"})
        self.assertEqual(live.context["kibana_kql"], "*")
        self.assertTrue(live.context["live_updates"])
        self.assertContains(live, 'data-live-topic="dashboard"')


class ActivityFeedFilterTest(ConsoleCaseTest):
    def test_limit_reaches_go_and_filters_narrow_the_snapshot(self):
        """Limit reaches Go (capped at Go's 500); action, status and member narrow the snapshot Go returned. [case:console.activities.activity_feed.filters]"""
        api = self.bff()
        api.list_activities.return_value = APIResult(True, {"activities": [
            {"id": "e1", "user_id": MEMBER, "actor": "member", "action": "match.created", "status": "success", "resource": "matches",
             "created_at": "2026-10-02T10:00:00Z"},
            {"id": "e2", "user_id": MEMBER, "actor": "member", "action": "match.created", "status": "failed", "resource": "matches",
             "created_at": "2026-10-02T10:01:00Z"},
            {"id": "e3", "user_id": "22222222-2222-4222-8222-222222222222", "actor": "member", "action": "report.created", "status": "success",
             "resource": "reports", "created_at": "2026-10-02T10:02:00Z"}], "total": 3, "limit": 50, "offset": 0})
        response = self.client.get(reverse("activity_feed"), {"limit": "50", "action": "MATCH", "status": "success", "user_id": MEMBER[:8]})
        api.list_activities.assert_called_once_with(limit=50)
        self.assertEqual([a["id"] for a in response.context["activities"]], ["e1"])
        self.assertContains(response, "Latest 50 events")
        api.list_activities.reset_mock()
        self.client.get(reverse("activity_feed"), {"limit": "5000"})
        api.list_activities.assert_called_once_with(limit=500)
