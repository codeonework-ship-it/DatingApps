"""Report server: parameters, groups and totals, suppression, drill-through,
roles, and the Excel, CSV and PDF exports."""
from __future__ import annotations

import csv
import io

from django.urls import reverse
from openpyxl import load_workbook

from control_panel.services.go_client import APIResult

from .case_support import ConsoleCaseTest, bff_error

REVENUE = {
    "totals": [
        {"currency": "INR", "market": "IN", "gross": "1000.00", "gross_minor": 100000, "net": "900.00", "net_minor": 90000,
         "paying_members": 12, "refund_rate": 0.05},
        {"currency": "INR", "market": "IN-KA", "gross": "500.00", "gross_minor": 50000, "net": "450.00", "net_minor": 45000,
         "paying_members": 3, "refund_rate": 0.0, "suppressed": ["paying_members"]},
        {"currency": "EUR", "market": "DE", "gross": "20.00", "gross_minor": 2000, "net": "20.00", "net_minor": 2000,
         "paying_members": 7, "refund_rate": 0.1},
    ],
    "by_city": [{"city": "Bengaluru", "currency": "INR", "paying_members": 9, "net": "300.00", "net_minor": 30000}],
    "trend": [{"bucket": "2026-09-28", "currency": "INR", "net_minor": 90000, "refunded_minor": 1000}],
}


class ReportServerTest(ConsoleCaseTest):
    module = "control_panel.reports.engine"

    def _revenue(self, **query):
        api = self.bff()
        api.business_report.return_value = APIResult(True, REVENUE)
        return api, self.client.get(reverse("report_view", args=["revenue"]), query)

    def test_catalog_lists_reports_and_searches(self):
        """The catalog lists business and product reports and finds them by keyword. [case:console.reports.catalog.search]"""
        self.bff()
        response = self.client.get(reverse("report_catalog"))
        card = '<span class="report-card-title">'
        self.assertContains(response, card + "Revenue<")
        self.assertContains(response, card + "Retention cohorts<")
        found = self.client.get(reverse("report_catalog"), {"q": "churn"})
        self.assertContains(found, card + "Subscriptions &amp; MRR<")
        self.assertNotContains(found, card + "Coin economy<")

    def test_catalog_hides_reports_the_role_cannot_read(self):
        """A support agent sees no finance reports. [case:console.reports.catalog.role_scoped]"""
        self.bff()
        response = self.as_roles("support").get(reverse("report_catalog"))
        self.assertNotContains(response, '<span class="report-card-title">Revenue<')

    def test_parameters_are_validated_before_reaching_go(self):
        """Only listed parameter values reach Go; defaults fill the rest. [case:console.reports.params.validated]"""
        api, _ = self._revenue(since="2026-09-01", until="not-a-date", tz="Mars/Base", mode="sandbox", bucket="month", evil="1")
        api.business_report.assert_called_once_with("revenue", {"since": "2026-09-01", "tz": "UTC", "mode": "sandbox", "bucket": "month"})

    def test_groups_subtotals_and_mixed_currency_totals(self):
        """Grouped rows get subtotals; money is never added across currencies. [case:console.reports.view.groups_totals]"""
        _, response = self._revenue()
        self.assertEqual(response.status_code, 200)
        totals = response.context["result"].datasets[0]
        self.assertEqual(totals.group_by, ("currency",))
        self.assertEqual([g.label for g in totals.groups], ["INR", "EUR"])
        inr = totals.groups[0].subtotal
        gross = [c for c, f in zip(inr.cells, totals.fields) if f.key == "gross"][0]
        self.assertEqual(gross.value, 1500.0)
        self.assertEqual(gross.text, "1,500.00 INR")
        grand = [c for c, f in zip(totals.total.cells, totals.fields) if f.key == "gross"][0]
        self.assertEqual(grand.text, "mixed currencies")
        self.assertContains(response, "Totals across currencies are not added.")
        self.assertContains(response, "&lt;5")  # suppressed small count stays suppressed

    def test_group_by_can_be_changed_or_removed(self):
        """Operators regroup a table or show it flat. [case:console.reports.view.group_by]"""
        _, by_market = self._revenue(group_totals="market")
        self.assertEqual(by_market.context["result"].datasets[0].group_by, ("market",))
        _, flat = self._revenue(group_totals="")
        self.assertEqual(flat.context["result"].datasets[0].groups, [])
        _, refused = self._revenue(group_totals="gross")  # not a groupable field
        self.assertEqual(refused.context["result"].datasets[0].group_by, ())

    def test_city_drills_through_to_liquidity(self):
        """A city links to the liquidity report for that city. [case:console.reports.view.drill_through]"""
        _, response = self._revenue(since="2026-09-01")
        self.assertContains(response, reverse("report_view", args=["liquidity"]) + "?since=2026-09-01&amp;city=Bengaluru")

    def test_role_refusal_is_shown_not_crashed(self):
        """Go's 403 renders as not available to your role. [case:console.reports.view.denied]"""
        self.bff().business_report.return_value = bff_error("forbidden", status=403)
        response = self.client.get(reverse("report_view", args=["revenue"]))
        self.assertEqual(response.status_code, 403)
        self.assertContains(response, "not available to your role", status_code=403)

    def test_unknown_report_is_404(self):
        """[case:console.reports.view.unknown]"""
        self.bff()
        self.assertEqual(self.client.get(reverse("report_view", args=["nope"])).status_code, 404)

    def test_excel_export_has_typed_sheets_and_parameters(self):
        """Excel: one typed sheet per table, subtotal rows, and an About sheet. [case:console.reports.export.xlsx]"""
        _, response = self._revenue(export="xlsx", mode="all")
        self.assertEqual(response["Content-Type"], "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        wb = load_workbook(io.BytesIO(response.content))
        self.assertEqual(wb.sheetnames[0], "About")
        about = {r[0]: r[1] for r in wb["About"].iter_rows(values_only=True)}
        self.assertEqual(about["Parameter: Payments"], "all")
        sheet = wb[wb.sheetnames[1]]
        rows = list(sheet.iter_rows(values_only=True))
        self.assertEqual(rows[0][0], "Currency")
        gross_col = rows[0].index("Gross")
        self.assertEqual(rows[1][gross_col], 1000.0)  # a number, not text
        self.assertIn("INR subtotal", [r[0] for r in rows])

    def test_csv_export_of_one_table(self):
        """CSV exports one table, UTF-8 with BOM for Excel. [case:console.reports.export.csv]"""
        _, response = self._revenue(export="csv", dataset="by_city")
        self.assertTrue(response.content.startswith("﻿".encode()))
        rows = list(csv.reader(io.StringIO(response.content.decode("utf-8-sig"))))
        self.assertEqual(rows[0], ["City", "Currency", "Paying members", "Net"])
        self.assertEqual(rows[1][0], "Bengaluru")

    def test_pdf_export(self):
        """PDF export renders the whole report. [case:console.reports.export.pdf]"""
        _, response = self._revenue(export="pdf")
        self.assertEqual(response["Content-Type"], "application/pdf")
        self.assertTrue(response.content.startswith(b"%PDF"))

    def test_analytics_reports_use_go_column_metadata(self):
        """Product reports take their tables and units from Go. [case:console.reports.view.analytics_tables]"""
        api = self.bff()
        api.analytics_report.return_value = APIResult(True, {"tables": {"triangle": {
            "columns": [{"key": "cohort_week", "label": "Week", "kind": "dimension"},
                        {"key": "week_1", "label": "Week 1", "kind": "ratio", "unit": "%"}],
            "rows": [{"cohort_week": "2026-09-01", "week_1": 42.5, "suppressed": []},
                     {"cohort_week": "2026-09-08", "week_1": None, "suppressed": ["week_1"]}]}}})
        response = self.client.get(reverse("report_view", args=["retention"]), {"grain": "week"})
        self.assertContains(response, "Week 1 (%)")
        self.assertContains(response, "42.50")
        self.assertContains(response, "&lt;5")
        api.analytics_report.assert_called_once_with("retention", {"grain": "week"})
