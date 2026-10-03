"""Every report in the report server (control_panel/reports/catalog.py):
it reads Go and renders its tables, its parameters reach Go validated, and
its Excel, CSV and PDF exports carry the same rows.

Fixtures are shaped like the Go handlers' real answers (exact JSON keys):
* business reports: backend/internal/bff/mobile/business_reports.go,
  business_subscriptions.go, business_conversion.go, business_market.go.
  Small counts arrive as the string "<5" in the value itself;
* product reports: server_admin_analytics_reports.go (tables with columns,
  rows and a per-row "suppressed" list);
* member, operations and server reports: the admin list endpoints
  (store.go, admin_list_endpoints.go, server_admin_extended.go,
  admin_member_activity.go, support_admin.go, admin_system.go,
  capacity_snapshot.go).
"""
from __future__ import annotations

from django.urls import reverse

from control_panel.services.go_client import APIResult

from .case_support import ConsoleCaseTest, bff_error, csv_rows, pdf_text, workbook

XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
MEMBER = "11111111-1111-4111-8111-111111111111"
OTHER = "22222222-2222-4222-8222-222222222222"
OPERATOR = "33333333-3333-4333-8333-333333333333"


def _major(minor: int) -> str:
    """Go's majorUnits for a two-decimal currency."""
    sign = "-" if minor < 0 else ""
    minor = abs(minor)
    return f"{sign}{minor // 100}.{minor % 100:02d}"


def money_row(currency: str, market: str, gross: int, refunded: int = 0, chargeback: int = 0, disputed: int = 0,
              settled: int = 1, **extra) -> dict:
    """moneyTotals.fields (business_reports.go): display strings and *_minor integers."""
    net = gross - refunded - chargeback
    row = {"currency": currency, "market": market}
    for key, minor in (("gross", gross), ("refunded", refunded), ("chargeback", chargeback), ("disputed", disputed), ("net", net)):
        row[key] = _major(minor)
        row[f"{key}_minor"] = minor
    row.update({"payments": settled + 1, "settled_payments": settled, "failed_payments": 1, "pending_payments": 0,
                "refund_rate": round(refunded / gross, 4) if gross else None, "refund_count_rate": 0.0,
                "chargeback_rate": round(chargeback / gross, 4) if gross else None, "chargeback_amount_rate": 0.0})
    row.update(extra)
    return row


def analytics(name: str, tables: dict, **meta) -> APIResult:
    """writeAnalyticsReport's envelope."""
    return APIResult(True, {"success": True, "report": name, "from": "2026-09-01", "to": "2026-09-28", "segments": {},
                            "tables": tables, "meta": {"suppression": {"threshold": 5}, "latest_built_day": "2026-09-28", **meta}})


def col(key: str, label: str, kind: str = "dimension", unit: str = "") -> dict:
    return {"key": key, "label": label, "kind": kind, **({"unit": unit} if unit else {})}


class ReportCase(ConsoleCaseTest):
    module = "control_panel.reports.engine"
    report_id = ""

    def open(self, **query):
        return self.client.get(reverse("report_view", args=[self.report_id]), query)

    def tables(self, response) -> dict[str, list[dict]]:
        """{dataset key: [{field label: shown text}]} for the data rows."""
        out = {}
        for ds in response.context["result"].datasets:
            labels = [f.label for f in ds.fields]
            out[ds.spec.key] = [dict(zip(labels, [c.text for c in r.cells])) for r in ds.rows if r.kind == "data"]
        return out

    def sheet(self, sheets: dict, title: str) -> list[dict]:
        """A dataset sheet (named from its title) as dicts by header, data rows
        up to the first blank row."""
        rows = sheets[title[:28].replace("/", "-").replace(":", " ")]  # Excel forbids : and / in sheet names
        header = rows[0]
        out = []
        for r in rows[1:]:
            if not any(v is not None for v in r):
                break
            out.append(dict(zip(header, r)))
        return out

    def assert_xlsx(self, response):
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], XLSX)
        self.assertIn(f'filename="report-{self.report_id}-', response["Content-Disposition"])
        sheets, about = workbook(response)
        self.assertEqual(next(iter(sheets)), "About")
        return sheets, about

    def assert_pdf(self, response) -> str:
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "application/pdf")
        self.assertIn(f'filename="report-{self.report_id}-', response["Content-Disposition"])
        return pdf_text(response)

    def assert_printed(self, text: str, *expected: str):
        """Each value is printed in the PDF (table cells wrap, so whitespace is ignored)."""
        flat = "".join(text.split())
        for value in expected:
            self.assertIn("".join(value.split()), flat)

    def assert_csv(self, response, dataset: str) -> list[list[str]]:
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response["Content-Type"].startswith("text/csv"))
        self.assertIn(f'filename="report-{self.report_id}-{dataset}-', response["Content-Disposition"])
        return csv_rows(response)


# ── Business ──────────────────────────────────────────────────────────────

def revenue_go() -> dict:
    return {
        "report": "revenue", "data_status": "ok",
        "totals": [
            money_row("INR", "IN", 100000, refunded=10000, settled=12, paying_members=12, charged_members=12,
                      arppu="75.00", arppu_minor=7500, arpu="10.00", arpu_minor=1000),
            money_row("EUR", "EU", 2000, settled=1, paying_members="<5", charged_members="<5",
                      arppu=None, arppu_minor=None, arpu="2.00", arpu_minor=200),
        ],
        "by_product": [money_row("INR", "IN", 80000, product_type="subscription", product_code="premium_monthly"),
                       money_row("INR", "IN", 20000, refunded=10000, product_type="coin_package", product_code="coins_500")],
        "by_city": [{"city": "Bengaluru", "currency": "INR", "paying_members": 9, "net": "300.00", "net_minor": 30000},
                    {"city": "other cities (each <5 paying members)", "currency": "INR", "paying_members": "<5",
                     "net": "50.00", "net_minor": 5000, "pooled": True}],
        "trend": [money_row("INR", "IN", 100000, refunded=10000, bucket="2026-09-28", subscription_net_minor=80000,
                            coin_package_net_minor=10000, other_net_minor=0)],
        "gifts": {"paid_gift_sends": 3, "coins_spent": 90, "note": ""},
    }


class RevenueReportTest(ReportCase):
    report_id = "revenue"

    def go(self, data=None):
        api = self.bff()
        api.business_report.return_value = APIResult(True, data or revenue_go())
        return api

    def test_renders_every_table_from_go(self):
        """Totals, products, cities and trend render from Go's rows; '<5' stays suppressed; a pooled city is not a drill link; a failing source shows its reason. [case:console.reports.revenue.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual(response.status_code, 200)
        api.business_report.assert_called_once_with("revenue", {"tz": "UTC", "mode": "live", "bucket": "week"})
        t = self.tables(response)
        inr, eur = t["totals"]
        self.assertEqual((inr["Gross"], inr["Refunded"], inr["Net"], inr["ARPPU"], inr["Refund rate"], inr["Paying members"]),
                         ("1,000.00 INR", "100.00 INR", "900.00 INR", "75.00 INR", "10.0%", "12"))
        self.assertEqual((eur["Gross"], eur["Paying members"], eur["ARPPU"]), ("20.00 EUR", "<5", "—"))
        self.assertEqual([r["Product"] for r in t["by_product"]], ["premium_monthly", "coins_500"])
        self.assertEqual(t["trend"][0]["Subscriptions"], "800.00 INR")
        self.assertEqual(t["trend"][0]["Coin packages"], "100.00 INR")
        self.assertContains(response, "Totals across currencies are not added.")
        self.assertContains(response, reverse("report_view", args=["liquidity"]) + "?city=Bengaluru")
        self.assertNotContains(response, "city=other+cities")
        api.business_report.return_value = bff_error("revenue store unavailable", 502)
        failed = self.open()
        self.assertEqual(failed.status_code, 200)
        self.assertContains(failed, "revenue store unavailable")
        self.assertTrue(all(not rows for rows in self.tables(failed).values()))

    def test_parameters_reach_go_and_invalid_values_fall_back(self):
        """From, To, Time zone, Payments and Period reach Go as chosen; invalid values fall back to the defaults. [case:console.reports.revenue.filters]"""
        api = self.go()
        self.open(since="2026-09-01", until="2026-09-30", tz="Asia/Kolkata", mode="all", bucket="month")
        api.business_report.assert_called_once_with("revenue", {"since": "2026-09-01", "until": "2026-09-30", "tz": "Asia/Kolkata",
                                                                 "mode": "all", "bucket": "month"})
        api.business_report.reset_mock()
        response = self.open(since="01/09/2026", until="2026-13-45x", tz="Mars/Base", mode="free", bucket="year", evil="1")
        api.business_report.assert_called_once_with("revenue", {"tz": "UTC", "mode": "live", "bucket": "week"})
        self.assertEqual(response.context["result"].params, {"tz": "UTC", "mode": "live", "bucket": "week"})

    def test_excel_export(self):
        """Excel: About sheet with the parameters and source, one typed sheet per table with currency subtotals and '<5' kept. [case:console.reports.revenue.export_xlsx]"""
        api = self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", mode="all", since="2026-09-01"))
        api.business_report.assert_called_once_with("revenue", {"since": "2026-09-01", "tz": "UTC", "mode": "all", "bucket": "week"})
        self.assertEqual((about["Report"], about["Parameter: Payments"], about["Parameter: From"], about["Source"]),
                         ("Revenue", "all", "2026-09-01", "/v1/admin/business/revenue"))
        self.assertEqual(list(sheets)[1:], ["Totals by currency and marke", "By product", "By payer city", "Trend"])
        totals = self.sheet(sheets, "Totals by currency and market")
        self.assertEqual([r["Currency"] for r in totals], ["INR", "INR subtotal", "EUR", "EUR subtotal", "Total"])
        self.assertEqual((totals[0]["Gross"], totals[0]["Net"], totals[0]["Paying members"], totals[0]["Refund rate"]), (1000.0, 900.0, 12, 0.1))
        self.assertEqual((totals[2]["Paying members"], totals[2]["ARPPU"]), ("<5", None))
        self.assertEqual(totals[4]["Settled payments"], 13)
        self.assertIn("Amounts are per currency; totals across currencies are not added.", [r[0] for r in sheets["Totals by currency and marke"]])
        cities = self.sheet(sheets, "By payer city")
        self.assertEqual([(r["City"], r["Paying members"], r["Net"]) for r in cities[:2]],
                         [("Bengaluru", 9, 300.0), ("other cities (each <5 paying members)", "<5", 50.0)])

    def test_csv_export_of_one_table(self):
        """CSV of one table (By payer city): header, Go's rows and the total; an unknown table is 404. [case:console.reports.revenue.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="by_city"), "by_city")
        self.assertEqual(rows[0], ["City", "Currency", "Paying members", "Net"])
        self.assertEqual(rows[1], ["Bengaluru", "INR", "9", "300.0"])
        self.assertEqual(rows[2], ["other cities (each <5 paying members)", "INR", "<5", "50.0"])
        self.assertEqual(rows[3], ["Total", "", "9", "350.0"])
        self.assertEqual(self.open(export="csv", dataset="nope").status_code, 404)

    def test_pdf_export(self):
        """PDF: title, parameters, every table title and Go's values. [case:console.reports.revenue.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf", mode="sandbox"))
        self.assert_printed(text, "Revenue", "Payments: sandbox", "Totals by currency and market", "By product", "By payer city", "Trend",
                         "1,000.00 INR", "Bengaluru", "premium_monthly", "mixed currencies")


def subscriptions_go() -> dict:
    movement = {"bucket": "2026-09-01", "currency": "INR", "subscribers_start": 40, "new_subscribers": 8, "expanded_subscribers": 1,
                "contracted_subscribers": 0, "churned_subscribers": "<5", "subscribers_end": 45, "logo_churn_rate": 0.075,
                "revenue_churn_rate": 0.05, "net_mrr_retention": 1.02}
    for key, minor in (("mrr_start", 400000), ("new", 80000), ("expansion", 5000), ("contraction", 0), ("churned", 30000), ("mrr_end", 455000)):
        movement[key], movement[f"{key}_minor"] = _major(minor), minor
    return {"report": "subscriptions", "data_status": "ok",
            "mrr": [{"at": "2026-09-30", "label": "end", "currency": "INR", "mrr": "4550.00", "mrr_minor": 455000,
                     "arr": "54600.00", "arr_minor": 5460000, "active_subscribers": 45}],
            "movements": [movement],
            "churn": {"reasons": [{"reason": "too_expensive", "subscribers": 3, "healthy": False},
                                  {"reason": "graduated", "subscribers": 6, "healthy": True}],
                      "average_logo_churn_rate": 0.07, "average_logo_churn_rate_ex_graduation": 0.04, "note": ""},
            "plan_mix": [{"plan": "premium", "billing_cycle": "monthly", "currency": "INR", "active_subscribers": 30, "cancel_at_period_end": 2},
                         {"plan": "premium", "billing_cycle": "yearly", "currency": "INR", "active_subscribers": 15, "cancel_at_period_end": 0}]}


class SubscriptionsReportTest(ReportCase):
    report_id = "subscriptions"

    def go(self):
        api = self.bff()
        api.business_report.return_value = APIResult(True, subscriptions_go())
        return api

    def test_renders_movements_churn_and_plan_mix(self):
        """MRR movements, churn reasons and the plan mix render from Go; Go's failure is shown. [case:console.reports.subscriptions.renders]"""
        api = self.go()
        response = self.open()
        api.business_report.assert_called_once_with("subscriptions", {"tz": "UTC", "mode": "live", "bucket": "week", "months": "12"})
        t = self.tables(response)
        m = t["movements"][0]
        self.assertEqual((m["Start MRR"], m["New"], m["Churned"], m["End MRR"], m["Churned subs"], m["Logo churn"], m["Net MRR retention"]),
                         ("4,000.00 INR", "800.00 INR", "300.00 INR", "4,550.00 INR", "<5", "7.5%", "102.0%"))
        self.assertEqual([(r["Reason"], r["Subscribers"], r["Healthy"]) for r in t["churn_reasons"]],
                         [("too_expensive", "3", "No"), ("graduated", "6", "Yes")])
        self.assertEqual([r["Cycle"] for r in t["plan_mix"]], ["monthly", "yearly"])
        plan = response.context["result"].datasets[2]
        self.assertEqual([(g.label, g.count) for g in plan.groups], [("premium", 2)])
        api.business_report.return_value = bff_error("forbidden", 403)
        denied = self.open()
        self.assertContains(denied, "not available to your role", status_code=403)

    def test_parameters_reach_go(self):
        """Period, months, payments, window and time zone reach Go; months outside 1-36 fall back to 12. [case:console.reports.subscriptions.filters]"""
        api = self.go()
        self.open(since="2026-01-01", until="2026-09-30", tz="Europe/London", mode="sandbox", bucket="month", months="6")
        api.business_report.assert_called_once_with("subscriptions", {"since": "2026-01-01", "until": "2026-09-30", "tz": "Europe/London",
                                                                       "mode": "sandbox", "bucket": "month", "months": "6"})
        api.business_report.reset_mock()
        self.open(months="99", bucket="hour")
        api.business_report.assert_called_once_with("subscriptions", {"tz": "UTC", "mode": "live", "bucket": "week", "months": "12"})

    def test_excel_export(self):
        """Excel: movements typed (money as numbers, '<5' kept), churn reasons and the plan mix with plan subtotals. [case:console.reports.subscriptions.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", months="6"))
        self.assertEqual(about["Parameter: Months"], "6")
        self.assertEqual(list(sheets)[1:], ["MRR movements", "Churn reasons", "Active plan mix"])
        m = self.sheet(sheets, "MRR movements")[0]
        self.assertEqual((m["Start MRR"], m["New"], m["End MRR"], m["Churned subs"], m["Logo churn"]), (4000.0, 800.0, 4550.0, "<5", 0.075))
        reasons = self.sheet(sheets, "Churn reasons")
        self.assertEqual([(r["Reason"], r["Subscribers"], r["Healthy"]) for r in reasons[:2]], [("too_expensive", 3, "No"), ("graduated", 6, "Yes")])
        mix = self.sheet(sheets, "Active plan mix")
        self.assertEqual([r["Plan"] for r in mix], ["premium", "premium", "premium subtotal", "Total"])
        self.assertEqual(mix[2]["Active subscribers"], 45)

    def test_csv_export(self):
        """CSV of the churn reasons table. [case:console.reports.subscriptions.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="churn_reasons"), "churn_reasons")
        self.assertEqual(rows[:3], [["Reason", "Subscribers", "Healthy"], ["too_expensive", "3", "No"], ["graduated", "6", "Yes"]])
        self.assertEqual(rows[3], ["Total", "9", ""])

    def test_pdf_export(self):
        """[case:console.reports.subscriptions.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Subscriptions & MRR", "MRR movements", "Churn reasons", "Active plan mix", "4,550.00 INR", "too_expensive", "yearly")


def conversion_go() -> dict:
    return {"report": "conversion", "data_status": "ok",
            "cohorts": [{"cohort": "2026-07", "members": 120, "paid_7d": 6, "paid_30d": 15, "paid_90d": 18, "paid_to_date": 18,
                         "subscribed_to_date": 12, "conversion_7d": 0.05, "conversion_30d": 0.125, "conversion_90d": 0.15,
                         "conversion_to_date": 0.15, "mature_30d": True},
                        {"cohort": "2026-09", "members": "<5", "paid_7d": 0, "paid_30d": 0, "paid_90d": 0, "paid_to_date": 0,
                         "subscribed_to_date": 0, "conversion_7d": None, "conversion_30d": None, "conversion_90d": None,
                         "conversion_to_date": None, "mature_30d": False}],
            "ltv": [], "actives_conversion": {"rate": 0.1}}


def funnel_go() -> dict:
    row = {"kind": "subscription", "product": "premium_monthly", "platform": "android", "created": 40, "completed": 30, "open": 2,
           "abandoned_or_expired": 8, "paid": 28, "refunded": 1, "members": 35, "completion_rate": 0.75, "paid_rate": 0.7, "refund_rate": 0.0357}
    coin = dict(row, kind="coin_package", product="coins_500", platform="web", created=10, completed=9, paid=9, refunded=0,
                abandoned_or_expired=1, open=0, completion_rate=0.9, paid_rate=0.9, refund_rate=0.0)
    return {"report": "funnel", "data_status": "ok", "stages": [], "totals": {}, "by_kind": [], "detail": [row, coin]}


class ConversionReportTest(ReportCase):
    report_id = "conversion"

    def go(self, funnel=None):
        api = self.bff()
        api.business_report.side_effect = lambda name, query: (
            APIResult(True, conversion_go()) if name == "conversion" else (funnel or APIResult(True, funnel_go())))
        return api

    def test_renders_cohorts_and_the_checkout_funnel(self):
        """Cohorts come from the conversion report, the checkout funnel from Go's funnel report; a failing funnel leaves the cohorts on the page. [case:console.reports.conversion.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual([c.args for c in api.business_report.call_args_list],
                         [("conversion", {"tz": "UTC", "mode": "live"}), ("funnel", {"tz": "UTC", "mode": "live", "bucket": "month"})])
        t = self.tables(response)
        self.assertEqual((t["cohorts"][0]["Cohort"], t["cohorts"][0]["Conv. 30d"], t["cohorts"][0]["30d mature"]), ("2026-07", "12.5%", "Yes"))
        self.assertEqual((t["cohorts"][1]["Members"], t["cohorts"][1]["Conv. 30d"]), ("<5", "—"))
        self.assertEqual([(r["Kind"], r["Paid"], r["Completion"]) for r in t["funnel"]],
                         [("subscription", "28", "75.0%"), ("coin_package", "9", "90.0%")])
        api = self.bff()
        self.go(funnel=bff_error("window has 500 day buckets; choose a coarser bucket", 400))
        failed = self.open()
        self.assertEqual(failed.status_code, 200)
        self.assertContains(failed, "window has 500 day buckets")
        self.assertEqual(len(self.tables(failed)["cohorts"]), 2)

    def test_parameters_reach_both_go_reports(self):
        """The window, time zone and payment mode reach the conversion and funnel reads; the funnel asks for month buckets so a long window stays valid. [case:console.reports.conversion.filters]"""
        api = self.go()
        self.open(since="2024-01-01", until="2026-09-30", tz="Asia/Kolkata", mode="all", bucket="day")
        query = {"since": "2024-01-01", "until": "2026-09-30", "tz": "Asia/Kolkata", "mode": "all"}
        self.assertEqual([c.args for c in api.business_report.call_args_list],
                         [("conversion", query), ("funnel", {**query, "bucket": "month"})])

    def test_excel_export(self):
        """[case:console.reports.conversion.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", mode="sandbox"))
        self.assertEqual(about["Parameter: Payments"], "sandbox")
        cohorts = self.sheet(sheets, "Free → paid by signup cohort")
        self.assertEqual((cohorts[0]["Cohort"], cohorts[0]["Members"], cohorts[0]["Conv. 30d"], cohorts[1]["Members"]), ("2026-07", 120, 0.125, "<5"))
        funnel = self.sheet(sheets, "Checkout funnel")
        self.assertEqual([r["Kind"] for r in funnel], ["subscription", "subscription subtotal", "coin_package", "coin_package subtotal", "Total"])
        self.assertEqual(funnel[4]["Paid"], 37)

    def test_csv_export(self):
        """[case:console.reports.conversion.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="funnel"), "funnel")
        self.assertEqual(rows[0][:6], ["Kind", "Product", "Platform", "Created", "Completed", "Paid"])
        self.assertEqual(rows[1][:6], ["subscription", "premium_monthly", "android", "40", "30", "28"])

    def test_pdf_export(self):
        """[case:console.reports.conversion.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Conversion & checkout funnel", "Free -> paid by signup cohort", "Time zone: UTC · Payments: live",
                            "Paid <=7d", "Checkout funnel", "premium_monthly", "12.5%")
        self.assertNotIn("£", text)  # "≤" is spelled out, not printed as a wrong glyph


def coins_go() -> dict:
    return {"report": "coins", "data_status": "ok",
            "trend": [{"bucket": "2026-09-28", "purchased": 5000, "granted": 300, "returned": 20, "gift_spend": 2400,
                       "clawback_debits": 50, "net_flow": 2830}],
            "sources": {"purchased": {"coins": 5000, "by_currency": [
                {"currency": "INR", "mode": "live", "count": 9, "coins": 4500, "amount": "450.00", "amount_minor": 45000, "buyers": 7},
                {"currency": "EUR", "mode": "live", "count": "<5", "coins": 500, "amount": "5.00", "amount_minor": 500, "buyers": "<5"}]},
                        "non_revenue": {"daily_bonus": {"count": 30, "coins": 300, "revenue": False}}, "total_coins": 5300},
            "sinks": {"gifts": {"paid_sends": 40, "coins": 2400, "free_sends": 5, "senders": 12, "refunded_sends": 1, "refunded_coins": 20,
                                "top_gifts": [{"gift_id": "rose_bouquet", "sends": 25, "coins": 1500}, {"gift_id": "teddy", "sends": 15, "coins": 900}]},
                      "clawbacks": [{"source": "refund", "count": 2, "coins_debited": 50, "coins_shortfall": 10}],
                      "boosts": {}, "theme_packs": {}, "total_coins": 2450},
            "liability": {"outstanding_coins": 9000, "valuation": []}, "velocity": {}}


class CoinsReportTest(ReportCase):
    report_id = "coins"

    def go(self):
        api = self.bff()
        api.business_report.return_value = APIResult(True, coins_go())
        return api

    def test_renders_flows_purchases_gifts_and_clawbacks(self):
        """[case:console.reports.coins.renders]"""
        api = self.go()
        response = self.open()
        api.business_report.assert_called_once_with("coins", {"tz": "UTC", "mode": "live", "bucket": "week"})
        t = self.tables(response)
        self.assertEqual((t["trend"][0]["Purchased"], t["trend"][0]["Gift spend"], t["trend"][0]["Net flow"]), ("5,000", "2,400", "2,830"))
        self.assertEqual([(r["Currency"], r["Purchases"], r["Amount"]) for r in t["purchases"]],
                         [("INR", "9", "450.00 INR"), ("EUR", "<5", "5.00 EUR")])
        self.assertEqual([r["Gift"] for r in t["top_gifts"]], ["rose_bouquet", "teddy"])
        self.assertEqual(t["clawbacks"][0]["Shortfall"], "10")
        api.business_report.return_value = bff_error("analytics storage is unavailable", 503)
        self.assertContains(self.open(), "analytics storage is unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.coins.filters]"""
        api = self.go()
        self.open(since="2026-09-01", until="2026-09-07", tz="Europe/Berlin", mode="all", bucket="day")
        api.business_report.assert_called_once_with("coins", {"since": "2026-09-01", "until": "2026-09-07", "tz": "Europe/Berlin",
                                                               "mode": "all", "bucket": "day"})
        api.business_report.reset_mock()
        self.open(tz="Local", mode="LIVE")
        api.business_report.assert_called_once_with("coins", {"tz": "UTC", "mode": "live", "bucket": "week"})

    def test_excel_export(self):
        """[case:console.reports.coins.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Coin flows", "Purchases by currency", "Top gifts by coins", "Clawbacks"])
        self.assertEqual(self.sheet(sheets, "Coin flows")[0]["Purchased"], 5000)
        purchases = self.sheet(sheets, "Purchases by currency")
        self.assertEqual([(r["Currency"], r["Purchases"], r["Amount"]) for r in purchases[:2]], [("INR", 9, 450.0), ("EUR", "<5", 5.0)])
        self.assertEqual([(r["Gift"], r["Coins"]) for r in self.sheet(sheets, "Top gifts by coins")[:2]], [("rose_bouquet", 1500), ("teddy", 900)])

    def test_csv_export(self):
        """[case:console.reports.coins.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="top_gifts"), "top_gifts")
        self.assertEqual(rows, [["Gift", "Sends", "Coins"], ["rose_bouquet", "25", "1500"], ["teddy", "15", "900"], ["Total", "40", "2400"]])

    def test_pdf_export(self):
        """[case:console.reports.coins.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Coin economy", "Coin flows", "Purchases by currency", "Top gifts by coins", "Clawbacks", "rose_bouquet", "450.00 INR")


def referrals_go() -> dict:
    return {"referrals_enabled": True,
            "referrals": {"codes_issued": 40, "active_codes": 30, "invites_sent": 50},
            "k_factor": {"by_cohort": [{"cohort": "2026-08", "members": 200, "referral_signups_30d": 30, "introducer_invites_30d": 60,
                                        "introducer_accepted_30d": 24, "k_referral": 0.15, "k_introducer": 0.12, "k_total": 0.27,
                                        "introducer_invites_per_member": 0.3, "introducer_acceptance_rate": 0.4}],
                         "overall": {"k_total": 0.27}, "targets": {"healthy": 0.3, "redesign_below": 0.1}, "definition": ""},
            "introducers": {"intros": [{"introducer_kind": "friend", "intros": 20, "matched": 6, "declined": 8, "expired": 4, "open": 2, "match_rate": 0.3},
                                       {"introducer_kind": "matchmaker", "intros": 10, "matched": 4, "declined": 3, "expired": 2, "open": 1, "match_rate": 0.4}],
                            "invites_created": 60, "invites_accepted": 24}}


class ReferralsReportTest(ReportCase):
    report_id = "referrals"

    def go(self):
        api = self.bff()
        api.business_report.return_value = APIResult(True, referrals_go())
        return api

    def test_renders_k_factor_and_intros(self):
        """[case:console.reports.referrals.renders]"""
        api = self.go()
        response = self.open()
        api.business_report.assert_called_once_with("referrals", {"tz": "UTC", "mode": "live", "bucket": "week"})
        t = self.tables(response)
        k = t["k_factor"][0]
        self.assertEqual((k["Cohort"], k["K total"], k["Acceptance"], k["Referral signups ≤30d"]), ("2026-08", "0.27", "40.0%", "30"))
        self.assertEqual([(r["Introducer"], r["Matched"], r["Match rate"]) for r in t["intros"]], [("friend", "6", "30.0%"), ("matchmaker", "4", "40.0%")])
        self.assertIsNotNone(response.context["datasets"][0]["chart"])
        api.business_report.return_value = bff_error("referrals unavailable", 502)
        self.assertContains(self.open(), "referrals unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.referrals.filters]"""
        api = self.go()
        self.open(since="2026-03-01", until="2026-09-30", tz="Europe/Paris", mode="sandbox", bucket="month")
        api.business_report.assert_called_once_with("referrals", {"since": "2026-03-01", "until": "2026-09-30", "tz": "Europe/Paris",
                                                                   "mode": "sandbox", "bucket": "month"})

    def test_excel_export(self):
        """[case:console.reports.referrals.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        k = self.sheet(sheets, "Friend K-factor by signup cohort")[0]
        self.assertEqual((k["Cohort"], k["Members"], k["K total"], k["Acceptance"]), ("2026-08", 200, 0.27, 0.4))
        intros = self.sheet(sheets, "Intros")
        self.assertEqual([(r["Introducer"], r["Intros"]) for r in intros], [("friend", 20), ("matchmaker", 10), ("Total", 30)])

    def test_csv_export(self):
        """[case:console.reports.referrals.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="intros"), "intros")
        self.assertEqual(rows[0], ["Introducer", "Intros", "Matched", "Declined", "Expired", "Open", "Match rate"])
        self.assertEqual(rows[1], ["friend", "20", "6", "8", "4", "2", "0.3"])

    def test_pdf_export(self):
        """[case:console.reports.referrals.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Referrals & introducers", "Friend K-factor by signup cohort", "Intros", "matchmaker", "0.27")


def spend_go() -> dict:
    return {"entries": [{"id": "e1", "month": "2026-09-01", "channel": "meta", "market": "IN", "currency": "INR", "amount": "50000.00",
                         "amount_minor": 5000000, "attributed_members": 40, "note": "", "updated_at": "2026-09-30T10:00:00Z"}],
            "cac": [{"month": "2026-09", "market": "IN", "currency": "INR", "spend": "50000.00", "spend_minor": 5000000, "new_members": 250,
                     "cac": "200.00", "cac_minor": 20000, "attributed_members": 40, "attributed_cac": "1250.00", "attributed_cac_minor": 125000},
                    {"month": "2026-09", "market": "DE", "currency": "EUR", "spend": "300.00", "spend_minor": 30000, "new_members": "<5",
                     "cac": None, "cac_minor": None, "attributed_members": 0, "attributed_cac": None, "attributed_cac_minor": None}],
            "channels": ["meta"], "markets": ["IN", "DE"], "status": "ok"}


class MarketingSpendReportTest(ReportCase):
    report_id = "marketing-spend"

    def go(self):
        api = self.bff()
        api.business_report.return_value = APIResult(True, spend_go())
        return api

    def test_renders_cac_by_market(self):
        """[case:console.reports.marketing_spend.renders]"""
        api = self.go()
        response = self.open()
        api.business_report.assert_called_once_with("marketing-spend", {})
        rows = self.tables(response)["cac"]
        self.assertEqual([(r["Market"], r["Spend"], r["CAC"], r["New members"]) for r in rows],
                         [("IN", "50,000.00 INR", "200.00 INR", "250"), ("DE", "300.00 EUR", "—", "<5")])
        groups = response.context["result"].datasets[0].groups
        self.assertEqual([g.label for g in groups], ["IN", "DE"])
        api.business_report.return_value = bff_error("needs spend data", 502)
        self.assertContains(self.open(), "needs spend data")

    def test_parameters_reach_go(self):
        """Only From and To are offered and reach Go; a bad date is dropped. [case:console.reports.marketing_spend.filters]"""
        api = self.go()
        self.open(since="2026-01-01", until="2026-09-30", tz="Asia/Kolkata")
        api.business_report.assert_called_once_with("marketing-spend", {"since": "2026-01-01", "until": "2026-09-30"})
        api.business_report.reset_mock()
        self.open(since="2026-1-1")
        api.business_report.assert_called_once_with("marketing-spend", {})

    def test_excel_export(self):
        """[case:console.reports.marketing_spend.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", since="2026-01-01"))
        self.assertEqual(about["Parameter: From"], "2026-01-01")
        cac = self.sheet(sheets, "CAC by month, market and currency")
        self.assertEqual([r["Month"] for r in cac], ["2026-09", "IN subtotal", "2026-09", "DE subtotal", "Total"])
        self.assertEqual((cac[0]["Spend"], cac[0]["CAC"], cac[2]["New members"], cac[2]["CAC"]), (50000.0, 200.0, "<5", None))

    def test_csv_export(self):
        """[case:console.reports.marketing_spend.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="cac"), "cac")
        self.assertEqual(rows[0][:5], ["Month", "Market", "Currency", "Spend", "New members"])
        self.assertEqual(rows[1][:5], ["2026-09", "IN", "INR", "50000.0", "250"])

    def test_pdf_export(self):
        """[case:console.reports.marketing_spend.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Marketing spend & CAC", "CAC by month, market and currency", "50,000.00 INR", "200.00 INR")


# ── Product (durable analytics snapshots; Go describes its own tables) ────

KPI_TILES = {"columns": [col("key", "KPI"), col("label", "Label"), col("value", "Value", "number"),
                         col("previous", "Same day last week", "number"), col("unit", "Unit"), col("definition", "Definition")],
             "rows": [{"key": "dau", "label": "Daily active members", "value": 1234, "previous": 1100, "unit": "members",
                       "definition": "Members active that day", "suppressed": []},
                      {"key": "stickiness", "label": "Stickiness", "value": 21.5, "previous": 20.1, "unit": "%",
                       "definition": "DAU / MAU", "suppressed": []},
                      {"key": "reports_per_1k_dau", "label": "Reports per 1k DAU", "value": None, "previous": None, "unit": "per 1k",
                       "definition": "", "suppressed": ["value", "previous"]}]}


class KpisReportTest(ReportCase):
    report_id = "kpis"

    def go(self):
        api = self.bff()
        api.analytics_report.return_value = analytics("kpis", {"tiles": KPI_TILES}, as_of="2026-09-28", compare="2026-09-21")
        return api

    def test_renders_the_tiles_table(self):
        """[case:console.reports.kpis.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("kpis", {})
        rows = self.tables(response)["tiles"]
        self.assertEqual([(r["KPI"], r["Value"], r["Same day last week"], r["Unit"]) for r in rows],
                         [("dau", "1,234.00", "1,100.00", "members"), ("stickiness", "21.50", "20.10", "%"), ("reports_per_1k_dau", "<5", "<5", "per 1k")])
        api.analytics_report.return_value = bff_error("analytics storage is unavailable", 503)
        failed = self.open()
        self.assertContains(failed, "analytics storage is unavailable")
        self.assertEqual(self.tables(failed), {})

    def test_parameters_reach_go(self):
        """As of (to) and gender reach Go; an unknown gender is dropped. [case:console.reports.kpis.filters]"""
        api = self.go()
        self.open(to="2026-09-28", gender="female")
        api.analytics_report.assert_called_once_with("kpis", {"to": "2026-09-28", "gender": "female"})
        api.analytics_report.reset_mock()
        self.open(to="yesterday", gender="robot", grain="week")
        api.analytics_report.assert_called_once_with("kpis", {})

    def test_excel_export(self):
        """[case:console.reports.kpis.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", gender="male"))
        self.assertEqual((about["Parameter: Gender"], about["Source"]), ("male", "/v1/admin/analytics/kpis"))
        tiles = self.sheet(sheets, "Tiles")
        self.assertEqual([(r["KPI"], r["Value"], r["Same day last week"]) for r in tiles],
                         [("dau", 1234, 1100), ("stickiness", 21.5, 20.1), ("reports_per_1k_dau", "<5", "<5")])

    def test_csv_export(self):
        """[case:console.reports.kpis.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="tiles"), "tiles")
        self.assertEqual(rows[0], ["KPI", "Label", "Value", "Same day last week", "Unit", "Definition"])
        self.assertEqual(rows[1], ["dau", "Daily active members", "1234", "1100", "members", "Members active that day"])
        self.assertEqual(rows[3][2:4], ["<5", "<5"])

    def test_pdf_export(self):
        """[case:console.reports.kpis.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Headline KPIs", "Tiles", "Daily active members", "1,234.00", "Stickiness")


class TrendsReportTest(ReportCase):
    report_id = "trends"

    def go(self):
        api = self.bff()
        api.analytics_report.return_value = analytics("trends", {"series": {
            "columns": [col("period", "Period start"), col("value", "Daily active members", "count")],
            "rows": [{"period": "2026-09-01", "value": 1200, "suppressed": []}, {"period": "2026-09-02", "value": 1310, "suppressed": []},
                     {"period": "2026-09-03", "value": None, "suppressed": ["value"]}]}}, metric={"key": "dau"}, grain="day", group_by="none")
        return api

    def test_renders_the_series(self):
        """[case:console.reports.trends.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("trends", {"grain": "day", "metric": "dau"})
        rows = self.tables(response)["series"]
        self.assertEqual([(r["Period start"], r["Daily active members"]) for r in rows],
                         [("2026-09-01", "1,200"), ("2026-09-02", "1,310"), ("2026-09-03", "<5")])
        total = response.context["result"].datasets[0].total
        self.assertEqual(total.cells[1].value, 2510)
        api.analytics_report.return_value = bff_error("unknown metric; see /v1/admin/analytics/definitions", 400)
        self.assertContains(self.open(), "unknown metric")

    def test_parameters_reach_go(self):
        """Window, grain, gender and metric reach Go; invalid values fall back. [case:console.reports.trends.filters]"""
        api = self.go()
        self.open(**{"from": "2026-08-01", "to": "2026-09-28", "grain": "week", "gender": "male", "metric": "wau"})
        api.analytics_report.assert_called_once_with("trends", {"from": "2026-08-01", "to": "2026-09-28", "grain": "week",
                                                                 "gender": "male", "metric": "wau"})
        api.analytics_report.reset_mock()
        self.open(grain="year", metric="nope")
        api.analytics_report.assert_called_once_with("trends", {"grain": "day", "metric": "dau"})

    def test_excel_export(self):
        """[case:console.reports.trends.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", metric="mau"))
        self.assertEqual(about["Parameter: Metric"], "mau")
        self.assertEqual([(r["Period start"], r["Daily active members"]) for r in self.sheet(sheets, "Series")],
                         [("2026-09-01", 1200), ("2026-09-02", 1310), ("2026-09-03", "<5"), ("Total", 2510)])

    def test_csv_export(self):
        """[case:console.reports.trends.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="series"), "series")
        self.assertEqual(rows, [["Period start", "Daily active members"], ["2026-09-01", "1200"], ["2026-09-02", "1310"],
                                ["2026-09-03", "<5"], ["Total", "2510"]])

    def test_pdf_export(self):
        """[case:console.reports.trends.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Active members over time", "Series", "2026-09-02", "1,310", "Metric: dau")


FUNNEL_STEPS = {"columns": [col("cohort", "Signup cohort"), col("step_index", "#"), col("step", "Step"), col("step_label", "Step label"),
                            col("members", "Members", "count"), col("conversion_from_previous", "From previous step", "ratio", "%"),
                            col("conversion_from_signup", "From signup", "ratio", "%"),
                            col("median_hours_from_previous", "Median hours from previous step", "median", "hours"),
                            col("median_hours_from_signup", "Median hours from signup", "median", "hours")],
                "rows": [{"cohort": "2026-09-01", "step_index": 1, "step": "signup", "step_label": "Signed up", "members": 200,
                          "conversion_from_previous": 100.0, "conversion_from_signup": 100.0, "median_hours_from_previous": None,
                          "median_hours_from_signup": None, "suppressed": []},
                         {"cohort": "2026-09-01", "step_index": 2, "step": "first_match", "step_label": "First match", "members": 90,
                          "conversion_from_previous": 45.0, "conversion_from_signup": 45.0, "median_hours_from_previous": 30.5,
                          "median_hours_from_signup": 30.5, "suppressed": []}]}


class FunnelReportTest(ReportCase):
    report_id = "funnel"

    def go(self):
        api = self.bff()
        api.analytics_report.return_value = analytics("funnel", {"steps": FUNNEL_STEPS}, cohort="week", within_days=28)
        return api

    def test_renders_the_steps(self):
        """[case:console.reports.funnel.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("funnel", {"grain": "day"})
        rows = self.tables(response)["steps"]
        self.assertEqual([(r["Step label"], r["Members"], r["From signup (%)"], r["Median hours from signup"]) for r in rows],
                         [("Signed up", "200", "100.00", "—"), ("First match", "90", "45.00", "30.50")])
        api.analytics_report.return_value = bff_error("forbidden", 403)
        self.assertContains(self.open(), "not available to your role", status_code=403)

    def test_parameters_reach_go(self):
        """[case:console.reports.funnel.filters]"""
        api = self.go()
        self.open(**{"from": "2026-07-01", "to": "2026-09-28", "grain": "month", "gender": "other"})
        api.analytics_report.assert_called_once_with("funnel", {"from": "2026-07-01", "to": "2026-09-28", "grain": "month", "gender": "other"})

    def test_excel_export(self):
        """[case:console.reports.funnel.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        steps = self.sheet(sheets, "Steps")
        self.assertEqual([(r["Step"], r["Members"], r["From signup (%)"]) for r in steps], [("signup", 200, 100.0), ("first_match", 90, 45.0), (None, 290, None)])

    def test_csv_export(self):
        """[case:console.reports.funnel.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="steps"), "steps")
        self.assertEqual(rows[0][:5], ["Signup cohort", "#", "Step", "Step label", "Members"])
        self.assertEqual(rows[2][:7], ["2026-09-01", "2", "first_match", "First match", "90", "45.0", "45.0"])

    def test_pdf_export(self):
        """[case:console.reports.funnel.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Activation funnel", "Steps", "First match", "45.00")


class RetentionReportTest(ReportCase):
    report_id = "retention"

    def go(self):
        api = self.bff()
        summary = {"columns": [col("cohort", "Signup cohort"), col("variant", "Variant"), col("members", "Members", "count"),
                               col("d1", "D1 retention", "ratio", "%"), col("d7", "D7 retention", "ratio", "%"), col("d30", "D30 retention", "ratio", "%"),
                               col("d1_eligible", "D1 observed members", "count"), col("d7_eligible", "D7 observed members", "count"),
                               col("d30_eligible", "D30 observed members", "count")],
                   "rows": [{"cohort": "2026-08-31", "variant": "", "members": 140, "d1": 61.4, "d7": 40.0, "d30": None, "d1_eligible": 140,
                             "d7_eligible": 140, "d30_eligible": 0, "suppressed": []}]}
        triangle = {"columns": [col("cohort_week", "Signup week"), col("variant", "Variant"), col("members", "Members", "count"),
                                col("week_0", "Week 0", "ratio", "%"), col("week_1", "Week 1", "ratio", "%")],
                    "rows": [{"cohort_week": "2026-08-31", "variant": "", "members": 140, "week_0": 100.0, "week_1": 42.5, "suppressed": []},
                             {"cohort_week": "2026-09-07", "variant": "", "members": None, "week_0": None, "week_1": None,
                              "suppressed": ["members", "week_0", "week_1"]}]}
        api.analytics_report.return_value = analytics("retention", {"summary": summary, "triangle": triangle}, cohort_grain="week")
        return api

    def test_renders_summary_and_triangle(self):
        """Retention reads weekly cohorts by default (Go's own default), with the summary and the triangle. [case:console.reports.retention.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("retention", {"grain": "week"})
        t = self.tables(response)
        self.assertEqual((t["summary"][0]["D1 retention (%)"], t["summary"][0]["D30 retention (%)"]), ("61.40", "—"))
        self.assertEqual([(r["Signup week"], r["Week 1 (%)"]) for r in t["triangle"]], [("2026-08-31", "42.50"), ("2026-09-07", "<5")])
        api.analytics_report.return_value = bff_error("query timed out; narrow the date range", 503)
        self.assertContains(self.open(), "narrow the date range")

    def test_parameters_reach_go(self):
        """[case:console.reports.retention.filters]"""
        api = self.go()
        self.open(**{"from": "2026-06-01", "to": "2026-09-28", "grain": "month", "gender": "female"})
        api.analytics_report.assert_called_once_with("retention", {"from": "2026-06-01", "to": "2026-09-28", "grain": "month", "gender": "female"})
        api.analytics_report.reset_mock()
        self.open(grain="fortnight")
        api.analytics_report.assert_called_once_with("retention", {"grain": "week"})

    def test_excel_export(self):
        """[case:console.reports.retention.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Summary", "Triangle"])
        triangle = self.sheet(sheets, "Triangle")
        self.assertEqual([(r["Signup week"], r["Members"], r["Week 1 (%)"]) for r in triangle[:2]], [("2026-08-31", 140, 42.5), ("2026-09-07", "<5", "<5")])

    def test_csv_export(self):
        """[case:console.reports.retention.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="triangle"), "triangle")
        self.assertEqual(rows[0], ["Signup week", "Variant", "Members", "Week 0 (%)", "Week 1 (%)"])
        self.assertEqual(rows[1], ["2026-08-31", "", "140", "100.0", "42.5"])

    def test_pdf_export(self):
        """[case:console.reports.retention.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Retention cohorts", "Summary", "Triangle", "42.50", "Grain: week")


class EngagementReportTest(ReportCase):
    report_id = "engagement"

    def go(self):
        api = self.bff()
        surfaces = {"columns": [col("surface", "Surface"), col("surface_label", "Surface name"), col("users", "Members", "count"),
                                col("reach", "Reach", "ratio", "%"), col("dau_share", "Share of DAU", "ratio", "%"), col("actions", "Actions", "count"),
                                col("actions_per_user", "Actions per member", "ratio"), col("repeat_users", "Repeat members", "count"),
                                col("repeat_rate", "Repeat rate", "ratio", "%"), col("counted_actions", "Counted actions")],
                    "rows": [{"surface": "chat", "surface_label": "Chat", "users": 800, "reach": 64.8, "dau_share": 70.1, "actions": 9000,
                              "actions_per_user": 11.25, "repeat_users": 500, "repeat_rate": 62.5, "counted_actions": "messages_sent", "suppressed": []},
                             {"surface": "plans", "surface_label": "Date plans", "users": None, "reach": None, "dau_share": None, "actions": None,
                              "actions_per_user": None, "repeat_users": None, "repeat_rate": None, "counted_actions": "date_plans_proposed",
                              "suppressed": ["users", "reach", "dau_share", "actions", "actions_per_user", "repeat_users", "repeat_rate"]}]}
        api.analytics_report.return_value = analytics("engagement", {"surfaces": surfaces}, active_members=1234)
        return api

    def test_renders_the_surfaces(self):
        """[case:console.reports.engagement.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("engagement", {"grain": "day"})
        rows = self.tables(response)["surfaces"]
        self.assertEqual([(r["Surface name"], r["Members"], r["Reach (%)"], r["Actions per member"]) for r in rows],
                         [("Chat", "800", "64.80", "11.25"), ("Date plans", "<5", "<5", "<5")])
        api.analytics_report.return_value = bff_error("analytics storage is unavailable", 503)
        self.assertContains(self.open(), "analytics storage is unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.engagement.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-09-28", "grain": "week", "gender": "female"})
        api.analytics_report.assert_called_once_with("engagement", {"from": "2026-09-01", "to": "2026-09-28", "grain": "week", "gender": "female"})

    def test_excel_export(self):
        """[case:console.reports.engagement.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        rows = self.sheet(sheets, "Surfaces")
        self.assertEqual([(r["Surface"], r["Members"], r["Actions"]) for r in rows], [("chat", 800, 9000), ("plans", "<5", "<5"), ("Total", 800, 9000)])

    def test_csv_export(self):
        """[case:console.reports.engagement.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="surfaces"), "surfaces")
        self.assertEqual(rows[1][:5], ["chat", "Chat", "800", "64.8", "70.1"])

    def test_pdf_export(self):
        """[case:console.reports.engagement.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Engagement", "Surfaces", "Date plans", "64.80")


class LiquidityReportTest(ReportCase):
    report_id = "liquidity"

    def go(self):
        api = self.bff()
        cities = {"columns": [col("city", "City"), col("active_members", "Active members", "count"), col("women", "Women", "count"),
                              col("men", "Men", "count"), col("other_or_unknown", "Other or unknown", "count"), col("women_per_man", "Women per man", "ratio"),
                              col("female_share", "Female share", "ratio", "%"), col("new_members", "New members", "count"),
                              col("matches", "Matches", "count"), col("matches_per_active_member", "Matches per active member", "ratio"),
                              col("likes_per_active_member", "Likes per active member", "ratio"), col("dates_kept", "Dates kept", "count")],
                  "rows": [{"city": "Pune", "active_members": 300, "women": 120, "men": 170, "other_or_unknown": 10, "women_per_man": 0.71,
                            "female_share": 40.0, "new_members": 30, "matches": 90, "matches_per_active_member": 0.3,
                            "likes_per_active_member": 4.2, "dates_kept": 12, "suppressed": []}]}
        api.analytics_report.return_value = analytics("liquidity", {"cities": cities})
        return api

    def test_renders_cities(self):
        """[case:console.reports.liquidity.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("liquidity", {"grain": "day"})
        row = self.tables(response)["cities"][0]
        self.assertEqual((row["City"], row["Women"], row["Women per man"], row["Female share (%)"]), ("Pune", "120", "0.71", "40.00"))
        api.analytics_report.return_value = bff_error("analytics storage is unavailable", 503)
        self.assertContains(self.open(), "analytics storage is unavailable")

    def test_parameters_reach_go(self):
        """Window, grain and city reach Go; gender is not offered (Go's liquidity report has no gender filter). [case:console.reports.liquidity.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-09-07", "grain": "week", "city": "Pune", "gender": "female"})
        api.analytics_report.assert_called_once_with("liquidity", {"from": "2026-09-01", "to": "2026-09-07", "grain": "week", "city": "Pune"})

    def test_excel_export(self):
        """[case:console.reports.liquidity.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", city="Pune"))
        self.assertEqual(about["Parameter: City"], "Pune")
        row = self.sheet(sheets, "Cities")[0]
        self.assertEqual((row["City"], row["Active members"], row["Matches"], row["Female share (%)"]), ("Pune", 300, 90, 40.0))

    def test_csv_export(self):
        """[case:console.reports.liquidity.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="cities"), "cities")
        self.assertEqual(rows[1][:4], ["Pune", "300", "120", "170"])

    def test_pdf_export(self):
        """[case:console.reports.liquidity.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf", city="Pune")), "Liquidity by city", "Cities", "Pune", "City: Pune")


class SafetyReportTest(ReportCase):
    report_id = "safety"

    def go(self):
        api = self.bff()
        trend = {"columns": [col("period", "Week"), col("reports_filed", "Reports filed", "count"), col("blocks", "Blocks", "count"),
                             col("active_member_days", "Active member days", "count"), col("reports_per_1k_dau", "Reports per 1k DAU", "ratio"),
                             col("blocks_per_1k_dau", "Blocks per 1k DAU", "ratio")],
                 "rows": [{"period": "2026-09-21", "reports_filed": 12, "blocks": 30, "active_member_days": 8000, "reports_per_1k_dau": 1.5,
                           "blocks_per_1k_dau": 3.75, "suppressed": []}]}
        queues = {"columns": [col("period", "Week"), col("queue", "Queue"), col("reports", "Reports", "count"), col("actioned", "Actioned", "count"),
                              col("median_hours_to_action", "Median hours to action", "median", "hours"),
                              col("p90_hours_to_action", "p90 hours to action", "median", "hours"),
                              col("within_deadline", "Within deadline", "ratio", "%"), col("open_past_deadline", "Open past deadline", "count")],
                  "rows": [{"period": "2026-09-21", "queue": "reports", "reports": 12, "actioned": 10, "median_hours_to_action": 6.5,
                            "p90_hours_to_action": 20.0, "within_deadline": 83.3, "open_past_deadline": 1, "suppressed": []}]}
        by_surface = {"columns": [col("surface", "Surface"), col("surface_label", "Surface name"), col("reports", "Reports", "count"),
                                  col("interactions", "Interactions", "count"), col("reports_per_1k_interactions", "Reports per 1k interactions", "ratio")],
                      "rows": [{"surface": "chat", "surface_label": "Chat", "reports": None, "interactions": 9000,
                                "reports_per_1k_interactions": None, "suppressed": ["reports", "reports_per_1k_interactions"]}]}
        api.analytics_report.return_value = analytics("safety", {"trend": trend, "queues": queues, "by_surface": by_surface}, grain="week")
        return api

    def test_renders_trend_queues_and_surfaces(self):
        """Safety reads weekly by default (Go's default) and renders all three tables. [case:console.reports.safety.renders]"""
        api = self.go()
        response = self.open()
        api.analytics_report.assert_called_once_with("safety", {"grain": "week"})
        t = self.tables(response)
        self.assertEqual((t["trend"][0]["Reports filed"], t["trend"][0]["Reports per 1k DAU"]), ("12", "1.50"))
        self.assertEqual((t["queues"][0]["Queue"], t["queues"][0]["Within deadline (%)"]), ("reports", "83.30"))
        self.assertEqual((t["by_surface"][0]["Reports"], t["by_surface"][0]["Interactions"]), ("<5", "9,000"))
        api.analytics_report.return_value = bff_error("analytics storage is unavailable", 503)
        self.assertContains(self.open(), "analytics storage is unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.safety.filters]"""
        api = self.go()
        self.open(**{"from": "2026-08-01", "to": "2026-09-28", "grain": "day", "gender": "male"})
        api.analytics_report.assert_called_once_with("safety", {"from": "2026-08-01", "to": "2026-09-28", "grain": "day", "gender": "male"})

    def test_excel_export(self):
        """[case:console.reports.safety.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Trend", "Queues", "By surface"])
        self.assertEqual(self.sheet(sheets, "Queues")[0]["Open past deadline"], 1)
        self.assertEqual(self.sheet(sheets, "By surface")[0]["Reports"], "<5")

    def test_csv_export(self):
        """[case:console.reports.safety.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="queues"), "queues")
        self.assertEqual(rows[1][:4], ["2026-09-21", "reports", "12", "10"])

    def test_pdf_export(self):
        """[case:console.reports.safety.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Safety health", "Trend", "Queues", "By surface", "83.30")


# ── Members ───────────────────────────────────────────────────────────────

def page(items_key: str, rows: list[dict], total: int | None = None, **extra) -> APIResult:
    """The admin list contract: items, total, limit, offset (admin_list_query.go Page)."""
    return APIResult(True, {items_key: rows, "total": len(rows) if total is None else total, "limit": 500, "offset": 0, **extra})


def go_user(**overrides) -> dict:
    """GET /admin/users row keys (server_admin_extended.go)."""
    user = {"id": MEMBER, "username": "asha", "name": "Asha Rao", "phone_number": "+919800000001", "gender": "female", "bio": "",
            "height_cm": 165, "education": "", "profession": "", "city": "Pune", "state": "MH", "country": "IN", "profile_completion": 80,
            "is_verified": True, "last_login_at": "2026-10-01T09:00:00Z", "created_at": "2026-01-10T09:00:00Z", "suspended_at": None,
            "suspended_reason": "", "is_banned": False}
    user.update(overrides)
    return user


def go_report(i: int, **overrides) -> dict:
    """GET /admin/moderation/reports row keys (store.go)."""
    row = {"id": f"r{i}", "reporter_user_id": OTHER, "reported_user_id": MEMBER, "reason": "spam", "description": f"Report {i}",
           "status": "pending", "action": "", "reviewed_by": "", "reviewed_at": None, "created_at": f"2026-09-{10 + i:02d}T10:00:00Z"}
    row.update(overrides)
    return row


def member_360_go(api):
    api.list_users.return_value = page("users", [go_user()], kpis={"total": 1})
    api.get_user.return_value = APIResult(True, {"user": go_user(is_active=True, updated_at="2026-10-01T09:00:00Z", suspended_until=None)})
    api.get_wallet_balance.return_value = APIResult(True, {"wallet": {"user_id": MEMBER, "coin_balance": 250, "updated_at": "2026-10-01T09:00:00Z"}})
    api.member_activity.return_value = APIResult(True, {
        "member_id": MEMBER, "summary": {"by_category": {"Auth": 9, "Safety": 3, "Billing & coins": 0}, "total": 12, "distinct_devices": 2,
                                         "distinct_ips": 3, "first_seen": "2026-09-01T08:00:00Z", "last_seen": "2026-10-02T10:00:00Z"},
        "actions": [{"id": "a1", "at": "2026-10-02T10:00:00Z", "source": "request", "member_id": MEMBER, "actor_id": MEMBER, "actor_role": "member",
                     "category": "Auth", "action_key": "auth.login", "action_label": "Signed in", "method": "POST", "route": "/v1/auth/login",
                     "status_code": 200, "outcome": "success", "duration_ms": 41, "entity_type": "", "entity_id": "", "ip": "203.0.113.9",
                     "device_id": "d1", "platform": "android", "app_version": "1.4.0", "user_agent": "okhttp", "request_id": "q1",
                     "correlation_id": "c1", "session_id": "s1", "details": {}}],
        "total_capped": False, "total": 1, "limit": 50, "offset": 0})
    api.list_reports.side_effect = lambda **kw: page("reports", [go_report(1, reporter_user_id=MEMBER, reported_user_id=OTHER, reason="fake_profile")]
                                                     if "reporter_user_id" in kw else [go_report(2), go_report(3, status="resolved")])
    api.list_appeals.return_value = page("appeals", [{"id": "ap1", "user_id": MEMBER, "report_id": "r2", "reason": "It was a joke", "description": "",
                                                       "status": "submitted", "resolution_reason": "", "reviewed_by": "", "reviewed_at": None,
                                                       "sla_deadline_at": "2026-10-04T10:00:00Z", "notification_policy": "standard",
                                                       "created_at": "2026-10-02T10:00:00Z", "updated_at": "2026-10-02T10:00:00Z"}])
    api.list_verifications.return_value = page("verifications", [{"user_id": MEMBER, "status": "verified", "submitted_at": "2026-02-01T10:00:00Z",
                                                                   "reviewed_at": "2026-02-02T10:00:00Z", "reviewed_by": OPERATOR, "evidence_received": True}])
    api.list_subscriptions.return_value = page("subscriptions", [{"id": "s1", "user_id": MEMBER, "plan_code": "premium", "status": "active",
                                                                   "billing_cycle": "monthly", "start_date": "2026-08-01T00:00:00Z", "end_date": None,
                                                                   "next_billing_date": "2026-11-01T00:00:00Z", "auto_renew": True,
                                                                   "cancel_at_period_end": False, "current_period_end": "2026-11-01T00:00:00Z",
                                                                   "provider": "stripe", "provider_subscription_id": "sub_1", "payment_method_brand": "visa",
                                                                   "payment_method_last4": "4242", "amount_minor": 49900, "currency": "INR",
                                                                   "created_at": "2026-08-01T00:00:00Z", "updated_at": "2026-10-01T00:00:00Z"}])
    api.list_payments.return_value = page("payments", [{"id": "p1", "user_id": MEMBER, "subscription_id": "s1", "amount_paise": 49900, "currency": "INR",
                                                         "status": "captured", "provider": "stripe", "provider_order_id": "", "provider_payment_id": "pi_1",
                                                         "provider_invoice_id": "in_1", "billing_reason": "subscription_cycle", "payment_method_brand": "visa",
                                                         "payment_method_last4": "4242", "refunded_amount_paise": 0, "failure_reason": "", "paid_at": "2026-10-01T00:00:00Z",
                                                         "created_at": "2026-10-01T00:00:00Z", "metadata": {}}])
    api.list_billing_transactions.return_value = page("transactions", [{"id": "t1", "user_id": MEMBER, "package_id": "coins_500", "source": "purchase",
                                                                         "provider": "stripe", "coins": 500, "amount_minor": 9900, "currency": "INR",
                                                                         "purchase_ref": "cs_1", "created_at": "2026-09-20T00:00:00Z"}])
    api.list_support_tickets.return_value = page("tickets", [{"id": "k1", "reference": "SUP-1001", "category": "billing", "subject": "Refund please",
                                                               "status": "resolved", "priority": "normal", "team": "billing", "channel": "app",
                                                               "requester": {"kind": "member", "member_id": MEMBER, "display_name": "Asha Rao", "username": "asha", "email": None},
                                                               "assignee": None, "tags": [], "sla": {"state": "met"}, "awaiting_agent": False,
                                                               "satisfaction": None, "merged_into": None, "message_count": 3,
                                                               "created_at": "2026-09-25T00:00:00Z", "updated_at": "2026-09-26T00:00:00Z"}],
                                                 success=True, counts={})
    api.list_sos_alerts.return_value = page("alerts", [{"id": "sos1", "user_id": MEMBER, "match_id": "", "latitude": 18.5, "longitude": 73.8,
                                                         "message": "help", "emergency_level": "high", "status": "resolved",
                                                         "triggered_at": "2026-09-30T21:00:00Z", "resolved_at": "2026-09-30T21:10:00Z",
                                                         "resolved_by": OPERATOR, "resolution_note": "safe"}], count=1, delivery_metrics={})
    return api


class Member360ReportTest(ReportCase):
    report_id = "member-360"

    def test_member_and_date_range_are_validated_and_reach_go(self):
        """A member id goes straight to Go (no lookup); the date range reaches the dated sources only; an invalid member or date never reaches Go. [case:console.reports.member_360.filters]"""
        api = member_360_go(self.bff())
        response = self.open(member=MEMBER, **{"from": "2026-09-01", "to": "2026-09-30"})
        self.assertEqual(response.status_code, 200)
        api.list_users.assert_not_called()
        api.get_user.assert_called_once_with(MEMBER)
        api.get_wallet_balance.assert_called_once_with(MEMBER)
        self.assertEqual(api.member_activity.call_args_list[0].args, (MEMBER,))
        self.assertEqual(api.member_activity.call_args_list[0].kwargs, {"limit": 1, "from": "2026-09-01", "to": "2026-09-30"})
        self.assertEqual(api.list_appeals.call_args.kwargs, {"limit": 500, "offset": 0, "user_id": MEMBER, "from": "2026-09-01", "to": "2026-09-30"})
        self.assertEqual(api.list_support_tickets.call_args.kwargs, {"limit": 500, "offset": 0, "member": MEMBER, "status": "all"})
        self.assertEqual(api.list_sos_alerts.call_args.kwargs["user_id"], MEMBER)
        api.reset_mock()
        refused = self.open(member="bad member!", **{"from": "01-09-2026"})
        self.assertContains(refused, "Enter Member ID or @username")
        api.get_user.assert_not_called()
        self.assertEqual(refused.context["result"].params, {})

    def test_sos_alerts_show_when_they_were_triggered(self):
        """SOS rows carry triggered_at (Go sends no created_at for alerts); closed support tickets are listed too. [case:console.reports.member_360.renders]"""
        member_360_go(self.bff())
        t = self.tables(self.open(member=MEMBER))
        self.assertEqual((t["sos_alerts"][0]["Triggered (UTC)"], t["sos_alerts"][0]["Level"]), ("2026-09-30T21:00:00Z", "high"))
        self.assertEqual(t["support_tickets"][0]["Status"], "resolved")

    def test_excel_export(self):
        """One sheet per section: the profile as Field/Value, typed money and counts. [case:console.reports.member_360.export_xlsx]"""
        member_360_go(self.bff())
        sheets, about = self.assert_xlsx(self.open(export="xlsx", member="@asha"))
        self.assertEqual(about["Parameter: Member ID or @username"], "@asha")
        self.assertEqual(list(sheets)[1:], ["Profile", "Wallet", "Activity summary", "Actions by area", "Recent actions (latest 50)",
                                            "Reports filed by this member", "Reports against this member", "Appeals", "Verification",
                                            "Subscriptions", "Payments", "Coin purchases", "Support tickets", "SOS alerts"])
        profile = {r["Field"]: r["Value"] for r in self.sheet(sheets, "Profile")}
        self.assertEqual((profile["Username"], profile["Verified"], profile["Profile complete (%)"]), ("asha", "Yes", "80"))
        self.assertEqual(self.sheet(sheets, "Wallet")[0], {"Field": "Coin balance", "Value": "250"})
        self.assertEqual([(r["Area"], r["Actions"]) for r in self.sheet(sheets, "Actions by area")], [("Auth", 9), ("Safety", 3), ("Total", 12)])
        self.assertEqual(self.sheet(sheets, "Payments")[0]["Amount"], 499.0)
        self.assertEqual(self.sheet(sheets, "Coin purchases")[0]["Coins"], 500)
        self.assertEqual(self.sheet(sheets, "Reports against this member")[0]["Reporter"], OTHER)

    def test_csv_export(self):
        """[case:console.reports.member_360.export_csv]"""
        member_360_go(self.bff())
        rows = self.assert_csv(self.open(export="csv", member=MEMBER, dataset="payments"), "payments")
        self.assertEqual(rows[0], ["Created (UTC)", "Amount", "Currency", "Status", "Reason", "Provider reference"])
        self.assertEqual(rows[1], ["2026-10-01T00:00:00Z", "499.0", "INR", "captured", "subscription_cycle", "pi_1"])

    def test_pdf_export(self):
        """[case:console.reports.member_360.export_pdf]"""
        member_360_go(self.bff())
        text = self.assert_pdf(self.open(export="pdf", member=MEMBER))
        self.assert_printed(text, "Member 360", "Profile", "Asha Rao", "Signed in", "203.0.113.9", "SUP-1001", "fake_profile", "premium")


class MemberDirectoryReportTest(ReportCase):
    report_id = "member-directory"

    def go(self):
        api = self.bff()
        api.list_users.return_value = page("users", [go_user(), go_user(id=OTHER, username="ravi", name="Ravi K", gender="male", city="Goa",
                                                                         is_verified=False, profile_completion=40)], kpis={"total": 2})
        return api

    def test_filters_reach_go(self):
        """Search, status, gender and verified reach Go on every page read; unknown values are sent empty. [case:console.reports.member_directory.filters]"""
        api = self.go()
        self.open(q="asha", status="suspended", gender="female", verified="no")
        api.list_users.assert_called_once_with(limit=500, offset=0, q="asha", status="suspended", gender="female", verified="no")
        api.list_users.reset_mock()
        self.open(status="deleted", gender="robot", verified="maybe")
        api.list_users.assert_called_once_with(limit=500, offset=0, q="", status="", gender="", verified="")

    def test_excel_export(self):
        """[case:console.reports.member_directory.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", gender="female"))
        self.assertEqual(about["Parameter: Gender"], "female")
        members = self.sheet(sheets, "Members")
        self.assertEqual([(r["Username"], r["City"], r["Profile (%)"], r["Verified"], r["Member ID"]) for r in members],
                         [("asha", "Pune", 80, "Yes", MEMBER), ("ravi", "Goa", 40, "No", OTHER)])

    def test_csv_export(self):
        """[case:console.reports.member_directory.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="members"), "members")
        self.assertEqual(rows[0], ["Username", "Name", "Gender", "City", "Profile (%)", "Verified", "Joined (UTC)", "Last sign-in (UTC)", "Banned", "Member ID"])
        self.assertEqual(rows[1], ["asha", "Asha Rao", "female", "Pune", "80", "Yes", "2026-01-10T09:00:00Z", "2026-10-01T09:00:00Z", "No", MEMBER])

    def test_pdf_export(self):
        """The PDF prints the members; a search with markup in it is printed as text, not interpreted. [case:console.reports.member_directory.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf", q="<font a"))
        self.assert_printed(text, "Member directory", "Asha Rao", "Ravi K", "Name, username or phone: <font a")


class MostReportedReportTest(ReportCase):
    report_id = "most-reported-members"

    def go(self):
        api = self.bff()
        api.list_reports.return_value = page("reports", [go_report(1, reported_user_id=OTHER), go_report(2), go_report(3, reason="harassment")])
        return api

    def test_filters_reach_go(self):
        """[case:console.reports.most_reported_members.filters]"""
        api = self.go()
        self.open(status="under_review", **{"from": "2026-09-01", "to": "2026-09-30"})
        api.list_reports.assert_called_once_with(limit=500, offset=0, status="under_review", **{"from": "2026-09-01", "to": "2026-09-30"})
        api.list_reports.reset_mock()
        self.open(status="escalated")
        api.list_reports.assert_called_once_with(limit=500, offset=0)

    def test_excel_export(self):
        """[case:console.reports.most_reported_members.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        rows = sheets["Reports by reported member"]
        self.assertEqual([r[0] for r in rows[1:4]], [MEMBER, MEMBER, OTHER])  # largest group first
        self.assertEqual(rows[1][3], "spam")

    def test_csv_export(self):
        """[case:console.reports.most_reported_members.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="by_member"), "by_member")
        self.assertEqual(rows[0], ["Reported member", "Created (UTC)", "Reporter", "Reason", "Status", "Description"])
        self.assertEqual(rows[1], [MEMBER, "2026-09-12T10:00:00Z", OTHER, "spam", "pending", "Report 2"])

    def test_pdf_export(self):
        """[case:console.reports.most_reported_members.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Most-reported members", "Reports by reported member", MEMBER, "harassment")


def go_subscription(user: str, plan: str, cycle: str, ending: bool = False) -> dict:
    return {"id": f"s-{user[:4]}-{plan}", "user_id": user, "plan_code": plan, "status": "active", "billing_cycle": cycle,
            "start_date": "2026-08-01T00:00:00Z", "end_date": None, "next_billing_date": "2026-11-01T00:00:00Z", "auto_renew": not ending,
            "cancel_at_period_end": ending, "current_period_end": "2026-11-01T00:00:00Z", "provider": "stripe", "provider_subscription_id": "sub",
            "payment_method_brand": "visa", "payment_method_last4": "4242", "amount_minor": 49900, "currency": "INR",
            "created_at": "2026-08-01T00:00:00Z", "updated_at": "2026-10-01T00:00:00Z"}


class PayingMembersReportTest(ReportCase):
    report_id = "paying-members"

    def go(self):
        api = self.bff()
        api.list_subscriptions.return_value = page("subscriptions", [go_subscription(MEMBER, "premium", "monthly"),
                                                                     go_subscription(OTHER, "premium", "yearly", ending=True),
                                                                     go_subscription(OPERATOR, "plus", "monthly")])
        return api

    def test_renders_subscribers_grouped_by_plan(self):
        """[case:console.reports.paying_members.renders]"""
        api = self.go()
        response = self.open()
        api.list_subscriptions.assert_called_once_with(limit=500, offset=0, status="active")
        groups = response.context["result"].datasets[0].groups
        self.assertEqual([(g.label, g.count) for g in groups], [("premium", 2), ("plus", 1)])
        rows = self.tables(response)["subscribers"]
        self.assertEqual([(r["Plan"], r["Cycle"], r["Ending"]) for r in rows], [("premium", "monthly", "No"), ("premium", "yearly", "Yes"), ("plus", "monthly", "No")])
        self.assertContains(response, reverse("report_view", args=["member-360"]) + f"?member={MEMBER}")
        api.list_subscriptions.return_value = bff_error("billing store unavailable", 502)
        self.assertContains(self.open(), "Subscribers: billing store unavailable")

    def test_filters_reach_go(self):
        """[case:console.reports.paying_members.filters]"""
        api = self.go()
        self.open(status="past_due", **{"from": "2026-09-01", "to": "2026-09-30"})
        api.list_subscriptions.assert_called_once_with(limit=500, offset=0, status="past_due", **{"from": "2026-09-01", "to": "2026-09-30"})
        api.list_subscriptions.reset_mock()
        self.open(status="trialing")
        api.list_subscriptions.assert_called_once_with(limit=500, offset=0, status="active")

    def test_excel_export(self):
        """[case:console.reports.paying_members.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(about["Parameter: Subscription status"], "active")
        rows = sheets["Subscribers"]
        self.assertEqual([(r[0], r[1], r[6]) for r in rows[1:4]], [(MEMBER, "premium", "No"), (OTHER, "premium", "Yes"), (OPERATOR, "plus", "No")])

    def test_csv_export(self):
        """[case:console.reports.paying_members.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="subscribers"), "subscribers")
        self.assertEqual(rows[0], ["Member", "Plan", "Cycle", "Provider", "Started (UTC)", "Renews / ends (UTC)", "Ending"])
        self.assertEqual(rows[2], [OTHER, "premium", "yearly", "stripe", "2026-08-01T00:00:00Z", "2026-11-01T00:00:00Z", "Yes"])

    def test_pdf_export(self):
        """[case:console.reports.paying_members.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Paying members by plan", "Subscribers", "premium", "yearly", "plus")


class DormantMembersExportTest(ReportCase):
    report_id = "dormant-members"

    def go(self):
        api = self.bff()
        api.list_users.return_value = page("users", [go_user(id="a", username="recent", last_login_at="2099-01-01T00:00:00Z"),
                                                     go_user(id="b", username="old", last_login_at="2020-01-01T00:00:00Z", city="Goa"),
                                                     go_user(id="c", username="older", last_login_at="2019-01-01T00:00:00Z")])
        return api

    def test_excel_export(self):
        """[case:console.reports.dormant_members.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", days="60"))
        self.assertEqual(about["Parameter: Inactive for at least"], "60")
        rows = self.sheet(sheets, "Dormant members")
        self.assertEqual([r["Username"] for r in rows], ["older", "old"])
        self.assertGreater(rows[0]["Days inactive"], rows[1]["Days inactive"])

    def test_csv_export(self):
        """[case:console.reports.dormant_members.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="dormant"), "dormant")
        self.assertEqual(rows[0], ["Username", "Name", "City", "Last sign-in (UTC)", "Days inactive", "Verified", "Joined (UTC)", "Member ID"])
        self.assertEqual([r[0] for r in rows[1:]], ["older", "old"])
        self.assertEqual(rows[2][2], "Goa")

    def test_pdf_export(self):
        """[case:console.reports.dormant_members.export_pdf]"""
        self.go()
        text = self.assert_pdf(self.open(export="pdf"))
        self.assert_printed(text, "Dormant members", "older", "Goa")
        self.assertNotIn("recent", text)


def go_action(i: int, label: str, **overrides) -> dict:
    row = {"id": f"a{i}", "at": f"2026-10-0{i}T10:00:00Z", "source": "request", "member_id": MEMBER, "actor_id": MEMBER, "actor_role": "member",
           "category": "Auth", "action_key": "auth.login", "action_label": label, "method": "POST", "route": "/v1/auth/login", "status_code": 200,
           "outcome": "success", "duration_ms": 30, "entity_type": "", "entity_id": "", "ip": "203.0.113.9", "device_id": "d1", "platform": "android",
           "app_version": "1.4.0", "user_agent": "okhttp/4", "request_id": f"q{i}", "correlation_id": f"c{i}", "session_id": "s1", "details": {}}
    row.update(overrides)
    return row


class SigninSecurityReportTest(ReportCase):
    report_id = "signin-security"

    def go(self):
        api = self.bff()
        api.list_member_actions.return_value = page("actions", [go_action(1, "Signed in"), go_action(2, "Signed in", ip="198.51.100.4"),
                                                                go_action(3, "Signed out other sessions", route="/v1/auth/sessions/revoke")],
                                                    total_capped=False)
        return api

    def test_filters_reach_go(self):
        """The window reaches Go with the Auth category and request source fixed; a bad date is dropped. [case:console.reports.signin_security.filters]"""
        api = self.go()
        self.open(**{"from": "2026-10-01", "to": "2026-10-03"})
        api.list_member_actions.assert_called_once_with(limit=500, offset=0, category="Auth", source="request", **{"from": "2026-10-01", "to": "2026-10-03"})
        api.list_member_actions.reset_mock()
        self.open(**{"from": "last week"})
        api.list_member_actions.assert_called_once_with(limit=500, offset=0, category="Auth", source="request")

    def test_excel_export(self):
        """[case:console.reports.signin_security.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        rows = sheets["Account security actions"]
        self.assertEqual([r[1] for r in rows[1:4]], ["Signed in", "Signed in", "Signed out other sessions"])
        self.assertEqual((rows[2][4], rows[2][3]), ("198.51.100.4", 200))

    def test_csv_export(self):
        """[case:console.reports.signin_security.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="auth"), "auth")
        self.assertEqual(rows[0], ["When (UTC)", "Action", "Outcome", "Status", "IP address", "Platform", "Member", "User agent"])
        self.assertEqual(rows[1], ["2026-10-01T10:00:00Z", "Signed in", "success", "200", "203.0.113.9", "android", MEMBER, "okhttp/4"])

    def test_pdf_export(self):
        """[case:console.reports.signin_security.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Sign-in and account security", "Signed out other sessions", "198.51.100.4")


# ── Operations ────────────────────────────────────────────────────────────

def queues_go(api):
    """The six queues: list_* (limit=1, order=asc) for the snapshot, paged reads for the open items."""
    data = {
        "list_sos_alerts": ("alerts", [{"id": "sos1", "user_id": MEMBER, "emergency_level": "high", "status": "active",
                                        "triggered_at": "2020-01-01T00:00:00Z", "resolved_at": None}]),
        "list_reports": ("reports", [go_report(1, created_at="2099-01-01T00:00:00Z", reason="new"),
                                     go_report(2, created_at="2020-01-01T00:00:00Z", reason="old")]),
        "list_appeals": ("appeals", [{"id": "ap1", "user_id": OTHER, "reason": "joke", "status": "submitted", "created_at": "2099-01-01T00:00:00Z",
                                      "sla_deadline_at": "2099-01-03T00:00:00Z"}]),
        "list_verifications": ("verifications", []),
        "list_media_moderation": ("items", [{"photo_id": "ph1", "user_id": MEMBER, "username": "asha", "status": "review_required",
                                             "reason": "nudity_score", "uploaded_at": "2020-06-01T00:00:00Z"}]),
        "list_account_recovery": ("requests", [{"id": "rq1", "user_id": OTHER, "username": "ravi", "member_message": "lost phone",
                                                "status": "open", "created_at": "2020-06-01T00:00:00Z"}]),
    }
    for method, (key, rows) in data.items():
        def answer(rows=rows, key=key, **kw):
            if kw.get("limit") == 1:
                oldest = sorted(rows, key=lambda r: r.get("triggered_at") or r.get("created_at") or r.get("uploaded_at") or "")[:1]
                return APIResult(True, {key: oldest, "total": len(rows)})
            return APIResult(True, {key: rows, "total": len(rows)})
        getattr(api, method).side_effect = answer
    return api


class QueueSlaExportTest(ReportCase):
    report_id = "queue-sla"

    def test_excel_export(self):
        """The snapshot and every queue's open items, oldest first, with past-target flags. [case:console.reports.queue_sla.export_xlsx]"""
        queues_go(self.bff())
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Queues right now", "SOS  open items", "Reports  open items", "Appeals  open items",
                                            "Verifications  open items", "Profile media  open items", "Account recovery  open items"])
        snapshot = {r["Queue"]: r for r in self.sheet(sheets, "Queues right now") if r["Queue"] != "Total"}
        self.assertEqual((snapshot["Reports"]["Open items"], snapshot["Reports"]["Past target"]), (2, "Yes"))
        self.assertEqual((snapshot["Appeals"]["Open items"], snapshot["Appeals"]["Past target"]), (1, "No"))
        self.assertEqual(snapshot["Verifications"]["Open items"], 0)
        reports = self.sheet(sheets, "Reports: open items")
        self.assertEqual([(r["Reason"], r["Past target"]) for r in reports], [("old", "Yes"), ("new", "No")])

    def test_csv_export(self):
        """[case:console.reports.queue_sla.export_csv]"""
        queues_go(self.bff())
        rows = self.assert_csv(self.open(export="csv", dataset="requests_open"), "requests_open")
        self.assertEqual(rows[0], ["Opened (UTC)", "Age (hours)", "Past target", "Status", "Username"])
        self.assertEqual((rows[1][0], rows[1][2], rows[1][3], rows[1][4]), ("2020-06-01T00:00:00Z", "Yes", "open", "ravi"))

    def test_pdf_export(self):
        """[case:console.reports.queue_sla.export_pdf]"""
        queues_go(self.bff())
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Queue SLA", "Queues right now", "Profile media: open items", "nudity_score", "ravi")


def go_audit(i: int, actor: str, event: str, resource: str = "users", **overrides) -> dict:
    """GET /admin/audit-events row keys (server_admin_extended.go)."""
    row = {"id": f"ev{i}", "occurred_at": f"2026-10-0{i}T10:00:00Z", "txid": 1000 + i, "event_type": event, "actor_user_id": actor,
           "actor_role": "moderator", "subject_user_id": MEMBER, "resource_type": resource, "resource_id": f"res{i}", "correlation_id": f"c{i}",
           "payload": {"status": "resolved"}}
    row.update(overrides)
    return row


def audit_page(rows):
    return page("events", rows, count=len(rows), source="audit.operator_action_log", append_only=True, as_of="2026-10-03T00:00:00Z")


class OperatorProductivityReportTest(ReportCase):
    report_id = "operator-productivity"

    def go(self):
        api = self.bff()
        api.list_audit_events.return_value = audit_page([go_audit(1, OPERATOR, "report.resolved"), go_audit(2, OTHER, "appeal.resolved", actor_role="trust_safety"),
                                                         go_audit(3, OPERATOR, "user.suspended")])
        return api

    def test_renders_actions_grouped_by_operator(self):
        """[case:console.reports.operator_productivity.renders]"""
        api = self.go()
        response = self.open()
        api.list_audit_events.assert_called_once_with(limit=500, offset=0)
        groups = response.context["result"].datasets[0].groups
        self.assertEqual([(g.label, g.count) for g in groups], [(OPERATOR, 2), (OTHER, 1)])
        self.assertEqual([r["Action"] for r in self.tables(response)["by_operator"]], ["report.resolved", "user.suspended", "appeal.resolved"])
        api.list_audit_events.return_value = bff_error("forbidden", 403)
        self.assertContains(self.open(), "not available to your role", status_code=403)

    def test_filters_reach_go(self):
        """[case:console.reports.operator_productivity.filters]"""
        api = self.go()
        self.open(**{"from": "2026-10-01", "to": "2026-10-02"})
        api.list_audit_events.assert_called_once_with(limit=500, offset=0, **{"from": "2026-10-01", "to": "2026-10-02"})

    def test_excel_export(self):
        """[case:console.reports.operator_productivity.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        rows = sheets["Actions by operator"]
        self.assertEqual(rows[0], ("Operator", "Role", "When (UTC)", "Action", "Resource", "Resource ID"))
        self.assertEqual([r[3] for r in rows[1:4]], ["report.resolved", "user.suspended", "appeal.resolved"])

    def test_csv_export(self):
        """[case:console.reports.operator_productivity.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="by_operator"), "by_operator")
        self.assertEqual(rows[3], [OTHER, "trust_safety", "2026-10-02T10:00:00Z", "appeal.resolved", "users", "res2"])

    def test_pdf_export(self):
        """[case:console.reports.operator_productivity.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Operator productivity", "Actions by operator", "user.suspended", "trust_safety")


class ModerationOutcomesReportTest(ReportCase):
    report_id = "moderation-outcomes"

    def go(self):
        api = self.bff()
        api.list_reports.return_value = page("reports", [go_report(1, status="resolved"), go_report(2, reason="harassment", status="rejected"),
                                                         go_report(3, status="pending")])
        api.list_appeals.return_value = page("appeals", [{"id": "ap1", "user_id": MEMBER, "report_id": "r1", "reason": "It was a joke", "description": "",
                                                          "status": "resolved_upheld", "resolution_reason": "", "reviewed_by": OPERATOR,
                                                          "reviewed_at": "2026-10-02T00:00:00Z", "sla_deadline_at": "2026-10-03T00:00:00Z",
                                                          "notification_policy": "standard", "created_at": "2026-10-01T00:00:00Z",
                                                          "updated_at": "2026-10-02T00:00:00Z"}])
        return api

    def test_renders_reports_by_reason_and_appeals_by_outcome(self):
        """[case:console.reports.moderation_outcomes.renders]"""
        api = self.go()
        response = self.open()
        api.list_reports.assert_called_once_with(limit=500, offset=0)
        api.list_appeals.assert_called_once_with(limit=500, offset=0)
        by_key = {d.spec.key: d for d in response.context["result"].datasets}
        self.assertEqual([(g.label, g.count) for g in by_key["reports"].groups], [("spam", 2), ("harassment", 1)])
        self.assertEqual([g.label for g in by_key["appeals"].groups], ["resolved_upheld"])
        api.list_appeals.return_value = bff_error("appeals unavailable", 502)
        failed = self.open()
        self.assertContains(failed, "Appeals by outcome: appeals unavailable")
        self.assertEqual(len(self.tables(failed)["reports"]), 3)

    def test_filters_reach_go(self):
        """[case:console.reports.moderation_outcomes.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-09-30"})
        window = {"from": "2026-09-01", "to": "2026-09-30"}
        api.list_reports.assert_called_once_with(limit=500, offset=0, **window)
        api.list_appeals.assert_called_once_with(limit=500, offset=0, **window)

    def test_excel_export(self):
        """[case:console.reports.moderation_outcomes.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Reports by reason", "Appeals by outcome"])
        self.assertEqual([(r[0], r[1]) for r in sheets["Reports by reason"][1:4]], [("spam", "resolved"), ("spam", "pending"), ("harassment", "rejected")])
        self.assertEqual(sheets["Appeals by outcome"][1][:3], ("resolved_upheld", "2026-10-01T00:00:00Z", "It was a joke"))

    def test_csv_export(self):
        """[case:console.reports.moderation_outcomes.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="appeals"), "appeals")
        self.assertEqual(rows, [["Outcome", "Created (UTC)", "Reason", "Member"], ["resolved_upheld", "2026-10-01T00:00:00Z", "It was a joke", MEMBER]])

    def test_pdf_export(self):
        """[case:console.reports.moderation_outcomes.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Moderation outcomes", "Reports by reason", "Appeals by outcome", "harassment", "resolved_upheld")


class SosIncidentsReportTest(ReportCase):
    report_id = "sos-incidents"

    def go(self):
        api = self.bff()
        api.list_sos_alerts.return_value = page("alerts", [
            {"id": "sos1", "user_id": MEMBER, "match_id": "", "latitude": 18.5, "longitude": 73.8, "message": "help", "emergency_level": "high",
             "status": "resolved", "triggered_at": "2026-10-01T10:00:00Z", "resolved_at": "2026-10-01T10:12:30Z", "resolved_by": OPERATOR,
             "resolution_note": "Member safe"},
            {"id": "sos2", "user_id": OTHER, "match_id": "", "latitude": None, "longitude": None, "message": "", "emergency_level": "medium",
             "status": "active", "triggered_at": "2026-10-02T09:00:00Z", "resolved_at": None, "resolved_by": "", "resolution_note": ""}],
            count=2, delivery_metrics={})
        return api

    def test_filters_reach_go(self):
        """[case:console.reports.sos_incidents.filters]"""
        api = self.go()
        self.open(**{"from": "2026-10-01", "to": "2026-10-02"})
        api.list_sos_alerts.assert_called_once_with(limit=500, offset=0, **{"from": "2026-10-01", "to": "2026-10-02"})

    def test_excel_export(self):
        """[case:console.reports.sos_incidents.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        rows = self.sheet(sheets, "SOS alerts")
        self.assertEqual([(r["Level"], r["Minutes to resolve"], r["Resolution note"]) for r in rows], [("high", 12.5, "Member safe"), ("medium", None, None)])

    def test_csv_export(self):
        """[case:console.reports.sos_incidents.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="alerts"), "alerts")
        self.assertEqual(rows[0], ["Triggered (UTC)", "Level", "Status", "Resolved (UTC)", "Minutes to resolve", "Member", "Resolution note"])
        self.assertEqual(rows[1], ["2026-10-01T10:00:00Z", "high", "resolved", "2026-10-01T10:12:30Z", "12.5", MEMBER, "Member safe"])

    def test_pdf_export(self):
        """[case:console.reports.sos_incidents.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "SOS incident log", "Member safe", "12.50")


def go_payment(i: int, status: str, **overrides) -> dict:
    row = {"id": f"p{i}", "user_id": MEMBER, "subscription_id": "", "amount_paise": 49900, "currency": "INR", "status": status, "provider": "stripe",
           "provider_order_id": "", "provider_payment_id": f"pi_{i}", "provider_invoice_id": "", "billing_reason": "subscription_create",
           "payment_method_brand": "visa", "payment_method_last4": "4242", "refunded_amount_paise": 0, "failure_reason": "",
           "paid_at": None, "created_at": f"2026-10-0{i}T10:00:00Z", "metadata": {}}
    row.update(overrides)
    return row


class PaymentOperationsReportTest(ReportCase):
    report_id = "payment-operations"

    def go(self):
        api = self.bff()
        api.list_payments.side_effect = lambda **kw: page("payments", [go_payment(1, "failed", failure_reason="card_declined")]
                                                          if kw.get("status") == "failed" else
                                                          [go_payment(2, "refunded", refunded_amount_paise=20000, currency="EUR", amount_paise=2000)])
        api.list_billing_webhook_events.return_value = page("events", [{"id": "w1", "provider": "stripe", "event_id": "evt_1",
                                                                        "event_type": "invoice.payment_failed", "event_created_at": "2026-10-01T10:00:00Z",
                                                                        "received_at": "2026-10-01T10:00:05Z", "processed_at": None, "status": "failed",
                                                                        "error": "signature mismatch"}])
        return api

    def test_renders_failed_refunded_and_webhooks(self):
        """[case:console.reports.payment_operations.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual([c.kwargs for c in api.list_payments.call_args_list],
                         [{"limit": 500, "offset": 0, "status": "failed"}, {"limit": 500, "offset": 0, "status": "refunded"}])
        api.list_billing_webhook_events.assert_called_once_with(limit=500, offset=0, status="failed")
        t = self.tables(response)
        self.assertEqual((t["failed"][0]["Amount"], t["failed"][0]["Failure"]), ("499.00 INR", "card_declined"))
        self.assertEqual((t["refunded"][0]["Amount"], t["refunded"][0]["Refunded"]), ("20.00 EUR", "200.00 EUR"))
        self.assertEqual(t["webhooks"][0]["Error"], "signature mismatch")
        api.list_billing_webhook_events.return_value = bff_error("webhooks unavailable", 502)
        self.assertContains(self.open(), "Failed webhooks: webhooks unavailable")

    def test_filters_reach_go(self):
        """[case:console.reports.payment_operations.filters]"""
        api = self.go()
        self.open(**{"from": "2026-10-01", "to": "2026-10-03"})
        window = {"from": "2026-10-01", "to": "2026-10-03"}
        self.assertEqual([c.kwargs for c in api.list_payments.call_args_list],
                         [{"limit": 500, "offset": 0, "status": "failed", **window}, {"limit": 500, "offset": 0, "status": "refunded", **window}])
        api.list_billing_webhook_events.assert_called_once_with(limit=500, offset=0, status="failed", **window)

    def test_excel_export(self):
        """[case:console.reports.payment_operations.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Failed payments", "Refunded payments", "Failed webhooks"])
        self.assertEqual(self.sheet(sheets, "Failed payments")[0]["Amount"], 499.0)
        self.assertEqual(self.sheet(sheets, "Refunded payments")[0]["Refunded"], 200.0)
        self.assertEqual(self.sheet(sheets, "Failed webhooks")[0]["Event"], "invoice.payment_failed")

    def test_csv_export(self):
        """[case:console.reports.payment_operations.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="webhooks"), "webhooks")
        self.assertEqual(rows, [["Received (UTC)", "Provider", "Event", "Error", "Event ID"],
                                ["2026-10-01T10:00:05Z", "stripe", "invoice.payment_failed", "signature mismatch", "evt_1"]])

    def test_pdf_export(self):
        """[case:console.reports.payment_operations.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Payment operations", "card_declined", "200.00 EUR", "signature mismatch")


class ConfigChangesReportTest(ReportCase):
    report_id = "config-changes"

    def go(self):
        api = self.bff()
        api.list_audit_events.return_value = audit_page([go_audit(1, OPERATOR, "PATCH /v1/admin/config/flags", resource="config/flags",
                                                                  actor_role="admin", payload={"key": "support_ticketing_enabled", "value": True})])
        return api

    def test_renders_config_changes(self):
        """Only configuration resources are asked for (q=config/). [case:console.reports.config_changes.renders]"""
        api = self.go()
        response = self.open()
        api.list_audit_events.assert_called_once_with(limit=500, offset=0, q="config/")
        row = self.tables(response)["changes"][0]
        self.assertEqual((row["Resource"], row["Details"]), ("config/flags", "key: support_ticketing_enabled, value: True"))
        api.list_audit_events.return_value = bff_error("audit unavailable", 502)
        self.assertContains(self.open(), "Changes: audit unavailable")

    def test_filters_reach_go(self):
        """[case:console.reports.config_changes.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-09-30"})
        api.list_audit_events.assert_called_once_with(limit=500, offset=0, q="config/", **{"from": "2026-09-01", "to": "2026-09-30"})

    def test_excel_export(self):
        """[case:console.reports.config_changes.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(sheets["Changes"][1], ("2026-10-01T10:00:00Z", OPERATOR, "admin", "PATCH /v1/admin/config/flags", "config/flags",
                                                "key: support_ticketing_enabled, value: True"))

    def test_csv_export(self):
        """[case:console.reports.config_changes.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="changes"), "changes")
        self.assertEqual(rows[0], ["When (UTC)", "Operator", "Role", "Action", "Resource", "Details"])
        self.assertEqual(rows[1][4:], ["config/flags", "key: support_ticketing_enabled, value: True"])

    def test_pdf_export(self):
        """[case:console.reports.config_changes.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Configuration change log", "config/flags", "support_ticketing_enabled")


class DailyOperationsReportTest(ReportCase):
    report_id = "daily-operations"

    def go(self):
        api = queues_go(self.bff())
        api.analytics_report.return_value = analytics("kpis", {"tiles": KPI_TILES}, as_of="2026-10-02")
        api.system_requests.return_value = APIResult(True, {"rows": [], "totals": {"requests": 12000, "server_errors": 3, "refused": 40,
                                                                                   "avg_ms": 42.0, "p95_ms": 180.0},
                                                            "grain": "day", "group_by": "none", "limit": 500})
        api.system_jobs.return_value = APIResult(True, {"workers": [
            {"worker": "retention", "expected_interval_seconds": 3600.0, "last_run_at": "2026-10-03T00:00:00Z", "last_success_at": "2026-10-03T00:00:00Z",
             "last_status": "succeeded", "last_duration_ms": 900, "last_error": "", "runs_24h": 24, "failures_24h": 0, "items_24h": 100, "stale": False},
            {"worker": "push", "expected_interval_seconds": 60.0, "last_run_at": "2026-10-02T00:00:00Z", "last_success_at": "2026-10-01T00:00:00Z",
             "last_status": "failed", "last_duration_ms": 50, "last_error": "fcm 503", "runs_24h": 10, "failures_24h": 4, "items_24h": 0, "stale": True}]})
        return api

    def test_as_of_day_reaches_go(self):
        """As of reaches the KPI read as as_of; without it Go's latest built day is used; an invalid day is dropped. [case:console.reports.daily_operations.filters]"""
        api = self.go()
        self.open(to="2026-10-02")
        api.analytics_report.assert_called_once_with("kpis", {"as_of": "2026-10-02"})
        api.analytics_report.reset_mock()
        self.open(to="02/10/2026")
        api.analytics_report.assert_called_once_with("kpis", {})

    def test_excel_export(self):
        """KPIs, the queue snapshot and server health, one sheet each. [case:console.reports.daily_operations.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", to="2026-10-02"))
        self.assertEqual(about["Parameter: As of (UTC)"], "2026-10-02")
        self.assertEqual(list(sheets)[1:], ["Headline KPIs", "Queues right now", "Server health"])
        kpis = self.sheet(sheets, "Headline KPIs")
        self.assertEqual((kpis[0]["KPI"], kpis[0]["Value"], kpis[0]["Week before"]), ("Daily active members", 1234, 1100))
        health = {r["Signal"]: r["Value"] for r in self.sheet(sheets, "Server health")}
        self.assertEqual((health["Requests (last 24 h)"], health["Background workers stale"], health["Workers with failures (24 h)"]), ("12000", "1", "1"))

    def test_csv_export(self):
        """[case:console.reports.daily_operations.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="server"), "server")
        self.assertEqual(rows, [["Signal", "Value"], ["Requests (last 24 h)", "12000"], ["Server errors (5xx)", "3"], ["Refused requests", "40"],
                                ["Latency p95 (ms)", "180.0"], ["Background workers stale", "1"], ["Workers with failures (24 h)", "1"]])


# ── Server ────────────────────────────────────────────────────────────────

def traffic_row(bucket: str, requests: int, **group) -> dict:
    """admin_system.go request rollup rows: only the group_by column is filled."""
    row = {"bucket": bucket, "service": None, "method": None, "route": None, "status_class": None, "requests": requests,
           "server_errors": 2, "refused": 5, "avg_ms": 40.5, "p50_ms": 30.0, "p95_ms": 120.0, "p99_ms": 300.0}
    row.update(group)
    return row


def traffic_go(**kw) -> APIResult:
    group = kw.get("group_by")
    rows = {"none": [traffic_row("2026-10-01T00:00:00Z", 1000), traffic_row("2026-10-02T00:00:00Z", 1500)],
            "route": [traffic_row("2026-10-01T00:00:00Z", 700, route="/v1/swipe"), traffic_row("2026-10-01T00:00:00Z", 300, route="/v1/chat/{matchID}")],
            "status_class": [traffic_row("2026-10-01T00:00:00Z", 950, status_class="2xx"), traffic_row("2026-10-01T00:00:00Z", 50, status_class="4xx")]}[group]
    return APIResult(True, {"rows": rows, "totals": {"requests": 2500, "server_errors": 4, "refused": 10, "avg_ms": 40.5, "p95_ms": 120.0},
                            "from": "2026-10-01T00:00:00Z", "to": "2026-10-03T00:00:00Z", "grain": kw.get("grain", "hour"), "group_by": group,
                            "limit": kw.get("limit", 500)})


class ApiTrafficReportTest(ReportCase):
    report_id = "api-traffic"

    def go(self):
        api = self.bff()
        api.system_requests.side_effect = traffic_go
        return api

    def test_renders_overall_route_and_status_tables(self):
        """Three reads (overall, by route, by status class) asking Go for up to 5,000 rows each; route rows show the route only. [case:console.reports.api_traffic.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual([c.kwargs for c in api.system_requests.call_args_list],
                         [{"grain": "day", "group_by": "none", "limit": 5000}, {"grain": "day", "group_by": "route", "limit": 5000},
                          {"grain": "day", "group_by": "status_class", "limit": 5000}])
        t = self.tables(response)
        self.assertEqual([(r["Requests"], r["p95 ms"]) for r in t["overall"]], [("1,000", "120.00"), ("1,500", "120.00")])
        self.assertEqual([(r["Route"], r["Requests"]) for r in t["by_route"]], [("/v1/swipe", "700"), ("/v1/chat/{matchID}", "300")])
        self.assertNotIn("Method", t["by_route"][0])
        self.assertEqual([g.label for g in response.context["result"].datasets[2].groups], ["2xx", "4xx"])
        api.system_requests.side_effect = None
        api.system_requests.return_value = bff_error("forbidden", 403)
        self.assertContains(self.open(), "not available to your role", status_code=403)

    def test_parameters_reach_go(self):
        """[case:console.reports.api_traffic.filters]"""
        api = self.go()
        self.open(**{"from": "2026-10-01", "to": "2026-10-02", "grain": "hour"})
        window = {"from": "2026-10-01", "to": "2026-10-02", "grain": "hour", "limit": 5000}
        self.assertEqual([c.kwargs for c in api.system_requests.call_args_list],
                         [{**window, "group_by": "none"}, {**window, "group_by": "route"}, {**window, "group_by": "status_class"}])
        api.system_requests.reset_mock()
        self.open(grain="minute")
        self.assertEqual(api.system_requests.call_args_list[0].kwargs, {"grain": "day", "group_by": "none", "limit": 5000})

    def test_excel_export(self):
        """[case:console.reports.api_traffic.export_xlsx]"""
        self.go()
        sheets, about = self.assert_xlsx(self.open(export="xlsx", grain="hour"))
        self.assertEqual((about["Parameter: Per"], about["Source"]), ("hour", "/v1/admin/system/requests"))
        self.assertEqual(list(sheets)[1:], ["Overall", "By route", "By status class"])
        overall = self.sheet(sheets, "Overall")
        self.assertEqual([(r["Period"], r["Requests"]) for r in overall], [("2026-10-01T00:00:00Z", 1000), ("2026-10-02T00:00:00Z", 1500), ("Total", 2500)])
        self.assertEqual(self.sheet(sheets, "By route")[0]["Route"], "/v1/swipe")

    def test_csv_export(self):
        """[case:console.reports.api_traffic.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="by_status"), "by_status")
        self.assertEqual(rows[:3], [["Period", "Status class", "Requests"], ["2026-10-01T00:00:00Z", "2xx", "950"], ["2xx subtotal", "", "950"]])

    def test_pdf_export(self):
        """[case:console.reports.api_traffic.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "API traffic and latency", "Overall", "By route", "/v1/swipe", "1,500")


def go_run(i: int, worker: str, status: str, **overrides) -> dict:
    row = {"id": f"run{i}", "worker": worker, "instance": "bff-1", "build_commit": "abc123", "started_at": f"2026-10-0{i}T00:00:00Z",
           "finished_at": f"2026-10-0{i}T00:00:02Z", "duration_ms": 2000, "status": status, "items_processed": 40, "items_failed": 0,
           "backlog_after": 0, "error": "", "details": {}}
    row.update(overrides)
    return row


class BackgroundJobsReportTest(ReportCase):
    report_id = "background-jobs"

    def go(self):
        api = self.bff()
        api.system_job_runs.return_value = page("runs", [go_run(1, "retention", "succeeded"), go_run(2, "push", "failed", items_failed=3, error="fcm 503"),
                                                          go_run(3, "retention", "succeeded", items_processed=10)], total_capped=False)
        return api

    def test_renders_runs_grouped_by_worker(self):
        """[case:console.reports.background_jobs.renders]"""
        api = self.go()
        response = self.open()
        api.system_job_runs.assert_called_once_with(limit=500, offset=0)
        groups = response.context["result"].datasets[0].groups
        self.assertEqual([(g.label, g.count) for g in groups], [("retention", 2), ("push", 1)])
        self.assertEqual(groups[0].subtotal.cells[4].text, "50")
        self.assertEqual(self.tables(response)["runs"][2]["Error"], "fcm 503")
        api.system_job_runs.return_value = bff_error("forbidden", 403)
        self.assertContains(self.open(), "not available to your role", status_code=403)

    def test_parameters_reach_go(self):
        """[case:console.reports.background_jobs.filters]"""
        api = self.go()
        self.open(status="failed", **{"from": "2026-10-01", "to": "2026-10-02"})
        api.system_job_runs.assert_called_once_with(limit=500, offset=0, status="failed", **{"from": "2026-10-01", "to": "2026-10-02"})
        api.system_job_runs.reset_mock()
        self.open(status="crashed")
        api.system_job_runs.assert_called_once_with(limit=500, offset=0)

    def test_excel_export(self):
        """[case:console.reports.background_jobs.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx", status="failed"))
        rows = self.sheet(sheets, "Runs")
        self.assertEqual([r["Worker"] for r in rows], ["retention", "retention", "retention subtotal", "push", "push subtotal", "Total"])
        self.assertEqual((rows[3]["Failed items"], rows[3]["Error"], rows[5]["Items"]), (3, "fcm 503", 90))

    def test_csv_export(self):
        """[case:console.reports.background_jobs.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="runs"), "runs")
        self.assertEqual(rows[0], ["Worker", "Status", "Started (UTC)", "Duration (ms)", "Items", "Failed items", "Backlog after", "Error"])
        self.assertEqual(rows[1], ["retention", "succeeded", "2026-10-01T00:00:00Z", "2000", "40", "0", "0", ""])

    def test_pdf_export(self):
        """[case:console.reports.background_jobs.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Background job runs", "Runs", "fcm 503", "retention subtotal")


def capacity_go() -> APIResult:
    """admin_system.go /system/capacity: latest, tables and series."""
    return APIResult(True, {
        "latest": {"at": "2026-10-03T00:00:00Z", "db_size_bytes": 5368709120, "connections": 12, "max_connections": 100, "outbox_rows": 90000,
                   "activity_rows": 400000, "security_event_rows": 1200, "media_bytes": {"profile_photos": 2147483648, "chat_media": 1073741824, "voice": 0},
                   "media_bytes_total": 3221225472,
                   "disk": {"media": {"free_bytes": 53687091200, "total_bytes": 107374182400, "used_percent": 50.0},
                            "database": {"free_bytes": 10737418240, "total_bytes": 42949672960, "used_percent": 75.0}}},
        "tables": [{"table": "matching.activity_events", "total_bytes": 1073741824, "table_bytes": 805306368, "index_bytes": 268435456,
                    "live_rows": 400000, "dead_rows": 1200, "last_autovacuum": "2026-10-02T03:00:00Z", "seq_scan": 4, "idx_scan": 90000}],
        "series": [{"at": "2026-10-02T00:00:00Z", "db_size_bytes": 5000000000, "outbox_rows": 85000, "activity_rows": 390000, "media_bytes_total": 3000000000},
                   {"at": "2026-10-03T00:00:00Z", "db_size_bytes": 5368709120, "outbox_rows": 90000, "activity_rows": 400000, "media_bytes_total": 3221225472}]})


class DatabaseConsumptionReportTest(ReportCase):
    report_id = "database-consumption"

    def go(self):
        api = self.bff()
        api.system_capacity.return_value = capacity_go()
        return api

    def test_renders_size_tables_and_media(self):
        """[case:console.reports.database_consumption.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual([c.kwargs for c in api.system_capacity.call_args_list], [{}, {}, {}])
        t = self.tables(response)
        self.assertEqual([r["Database bytes"] for r in t["series"]], ["5,000,000,000", "5,368,709,120"])
        self.assertEqual((t["tables"][0]["Table"], t["tables"][0]["Dead rows"]), ("matching.activity_events", "1,200"))
        self.assertEqual([(r["Kind"], r["Bytes"]) for r in t["media"]], [("profile_photos", "2,147,483,648"), ("chat_media", "1,073,741,824")])
        api.system_capacity.return_value = bff_error("capacity unavailable", 503)
        self.assertContains(self.open(), "capacity unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.database_consumption.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-10-01", "grain": "hour"})
        self.assertEqual(api.system_capacity.call_args.kwargs, {"from": "2026-09-01", "to": "2026-10-01"})

    def test_excel_export(self):
        """[case:console.reports.database_consumption.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        self.assertEqual(list(sheets)[1:], ["Size over time", "Largest tables (latest snaps", "Media storage by kind"])
        self.assertEqual(self.sheet(sheets, "Size over time")[1]["Media bytes"], 3221225472)
        self.assertEqual(self.sheet(sheets, "Largest tables (latest snapshot)")[0]["Index scans"], 90000)
        self.assertEqual([(r["Kind"], r["Bytes"]) for r in self.sheet(sheets, "Media storage by kind")],
                         [("profile_photos", 2147483648), ("chat_media", 1073741824), ("Total", 3221225472)])

    def test_csv_export(self):
        """[case:console.reports.database_consumption.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="tables"), "tables")
        self.assertEqual(rows[0][:4], ["Table", "Total bytes", "Table bytes", "Index bytes"])
        self.assertEqual(rows[1][:6], ["matching.activity_events", "1073741824", "805306368", "268435456", "400000", "1200"])

    def test_pdf_export(self):
        """[case:console.reports.database_consumption.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Database and storage consumption", "Size over time", "matching.activity_events", "profile_photos")


class ThirdPartyUsageReportTest(ReportCase):
    report_id = "third-party-usage"

    def go(self):
        api = self.bff()
        api.system_third_party.return_value = APIResult(True, {
            "rows": [{"day": "2026-10-01", "provider": "fcm", "operation": "send", "calls": 900, "failures": 12, "units": 900, "unit_label": "messages"},
                     {"day": "2026-10-01", "provider": "anthropic", "operation": "copilot", "calls": 40, "failures": 0, "units": 52000.5, "unit_label": "tokens"}],
            "totals": [{"provider": "fcm", "operation": "send", "calls": 900, "failures": 12, "units": 900, "unit_label": "messages"},
                       {"provider": "anthropic", "operation": "copilot", "calls": 40, "failures": 0, "units": 52000.5, "unit_label": "tokens"}],
            "from": "2026-09-03", "to": "2026-10-03", "limit": 1000})
        return api

    def test_renders_totals_and_daily_usage(self):
        """[case:console.reports.third_party_usage.renders]"""
        api = self.go()
        response = self.open()
        self.assertEqual([c.kwargs for c in api.system_third_party.call_args_list], [{}, {}])
        t = self.tables(response)
        self.assertEqual([(r["Provider"], r["Calls"], r["Failures"]) for r in t["totals"]], [("fcm", "900", "12"), ("anthropic", "40", "0")])
        self.assertEqual((t["daily"][1]["Units"], t["daily"][1]["Unit"]), ("52,000.50", "tokens"))
        api.system_third_party.return_value = bff_error("usage unavailable", 503)
        self.assertContains(self.open(), "usage unavailable")

    def test_parameters_reach_go(self):
        """[case:console.reports.third_party_usage.filters]"""
        api = self.go()
        self.open(**{"from": "2026-09-01", "to": "2026-09-30"})
        self.assertEqual([c.kwargs for c in api.system_third_party.call_args_list], [{"from": "2026-09-01", "to": "2026-09-30"}] * 2)

    def test_excel_export(self):
        """[case:console.reports.third_party_usage.export_xlsx]"""
        self.go()
        sheets, _ = self.assert_xlsx(self.open(export="xlsx"))
        totals = self.sheet(sheets, "Totals")
        self.assertEqual([(r["Provider"], r["Calls"]) for r in totals], [("fcm", 900), ("fcm subtotal", 900), ("anthropic", 40), ("anthropic subtotal", 40), ("Total", 940)])
        self.assertEqual(self.sheet(sheets, "By day")[1]["Units"], 52000.5)

    def test_csv_export(self):
        """[case:console.reports.third_party_usage.export_csv]"""
        self.go()
        rows = self.assert_csv(self.open(export="csv", dataset="daily"), "daily")
        self.assertEqual(rows[:3], [["Day", "Provider", "Operation", "Calls", "Failures", "Units", "Unit"],
                                    ["2026-10-01", "fcm", "send", "900", "12", "900", "messages"],
                                    ["2026-10-01", "anthropic", "copilot", "40", "0", "52000.5", "tokens"]])

    def test_pdf_export(self):
        """[case:console.reports.third_party_usage.export_pdf]"""
        self.go()
        self.assert_printed(self.assert_pdf(self.open(export="pdf")), "Third-party usage", "Totals", "By day", "anthropic", "copilot")
