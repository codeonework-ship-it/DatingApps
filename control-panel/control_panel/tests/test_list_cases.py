"""Every server-side list page: search, each filter, sort and paging reach
Go with the documented names (unknown values never do), and Export Excel
pages through Go with the same filters into a workbook of every row.

Rows are shaped like the Go handlers' answers (exact JSON keys and items
keys): store.go, admin_list_endpoints.go, server_admin_extended.go,
server_admin_events.go, server_media_moderation.go, account_recovery.go,
growth_portfolio.go, level_progression.go, server_coin_economy_fraud.go,
photo_themes.go, group_covers.go, blog_trust.go and admin_system.go.
"""
from __future__ import annotations

from django.urls import reverse

from control_panel.services.go_client import APIResult

from .case_support import ConsoleCaseTest, bff_error, workbook

XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
MEMBER = "11111111-1111-4111-8111-111111111111"
OTHER = "22222222-2222-4222-8222-222222222222"
OPERATOR = "33333333-3333-4333-8333-333333333333"
WINDOW = {"from": "2026-09-01", "to": "2026-09-30"}


def uid(i: int) -> str:
    return f"{i:08d}-0000-4000-8000-000000000000"


class ListCase(ConsoleCaseTest):
    url = ""
    method = ""
    items = ""

    def page(self, rows, total, *, limit=25, offset=0, **extra) -> APIResult:
        return APIResult(True, {self.items: rows, "total": total, "limit": limit, "offset": offset, **extra})

    def get(self, **query):
        return self.client.get(reverse(self.url), query)

    def go(self, api):
        return getattr(api, self.method)

    def assert_filters(self, row, query: dict, go_kwargs: dict, *, contains=(), keep=(), dropped=None, dropped_kwargs=None):
        """One page of ten rows (page 2 of 37): Go gets exactly ``go_kwargs``
        plus limit/offset, the rows render, the pager keeps the filters, and
        ``dropped`` values never reach Go."""
        api = self.bff()
        rows = [row(i) for i in range(10, 20)]
        self.go(api).return_value = self.page(rows, 37, limit=10, offset=10)
        response = self.get(page="2", page_size="10", **query)
        self.assertEqual(response.status_code, 200)
        self.go(api).assert_called_once_with(limit=10, offset=10, **go_kwargs)
        page = response.context["page"]
        self.assertEqual((page.start, page.end, page.total, page.pages), (11, 20, 37, 4))
        self.assertEqual(page.rows, rows)
        for text in contains:
            self.assertContains(response, text)
        for part in ("page=3", "page_size=10", *keep):
            self.assertIn(part, page.next_url)
        if dropped is not None:
            self.go(api).reset_mock()
            self.get(**dropped)
            self.go(api).assert_called_once_with(**dropped_kwargs)
        return response

    def assert_export(self, row, query: dict, go_kwargs: dict, header: tuple, first: dict, about: dict, filename: str):
        """205 matching rows read as two pages of 200 with the same filters;
        the sheet has the spec's columns and every row; About lists the filters."""
        api = self.bff()
        rows = [row(i) for i in range(205)]
        self.go(api).side_effect = [self.page(rows[:200], 205, limit=200), self.page(rows[200:], 205, limit=200, offset=200)]
        response = self.get(export="xlsx", page="3", **query)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], XLSX)
        self.assertIn(f'filename="{filename}-', response["Content-Disposition"])
        self.assertEqual([c.kwargs for c in self.go(api).call_args_list],
                         [{"limit": 200, "offset": 0, **go_kwargs}, {"limit": 200, "offset": 200, **go_kwargs}])
        sheets, info = workbook(response)
        sheet = next(v for k, v in sheets.items() if k != "About")
        self.assertEqual(sheet[0], header)
        self.assertEqual(len(sheet), 206)
        record = dict(zip(header, sheet[1]))
        for key, value in first.items():
            self.assertEqual(record[key], value, key)
        self.assertEqual(info["Rows"], 205)
        for key, value in about.items():
            self.assertEqual(info[f"Filter: {key}"], value)
        return sheets


# ── Safety ────────────────────────────────────────────────────────────────

def recovery_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "username": f"member_{i}", "member_message": f"Lost my phone {i}", "status": "declined",
            "created_at": "2026-09-20T10:00:00Z", "identity_verified": False, "account_recoverable": True, "identity_check": "",
            "resolved_by": OPERATOR, "resolved_at": "2026-09-21T10:00:00Z"}


class AccountRecoveryListTest(ListCase):
    url, method, items = "account_recovery_queue", "list_account_recovery", "requests"

    def test_filters_reach_go(self):
        """Status, window and search reach Go; no status reads the open queue. [case:console.account_recovery.account_recovery_queue.filters]"""
        self.assert_filters(recovery_row, {"status": "declined", "q": "lost", **WINDOW}, {"status": "declined", "q": "lost", **WINDOW},
                            contains=["member_10"], keep=("status=declined", "q=lost", "from=2026-09-01"),
                            dropped={"status": "approved", "from": "yesterday"}, dropped_kwargs={"limit": 25, "offset": 0, "status": "open"})

    def test_excel_export(self):
        """[case:console.account_recovery.account_recovery_queue.export]"""
        self.assert_export(recovery_row, {"status": "declined"}, {"status": "declined"},
                           ("Request ID", "Username", "Status", "Member message", "Requested (UTC)"),
                           {"Request ID": uid(0), "Username": "member_0", "Member message": "Lost my phone 0"}, {"status": "declined"}, "account-recovery")


def sos_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "match_id": "", "latitude": 18.52, "longitude": 73.85, "message": f"help {i}",
            "emergency_level": "high", "status": "resolved", "triggered_at": "2026-09-30T21:00:00Z", "resolved_at": "2026-09-30T21:10:00Z",
            "resolved_by": OPERATOR, "resolution_note": "safe"}


class SosListTest(ListCase):
    url, method, items = "safety_sos", "list_sos_alerts", "alerts"

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), delivery_metrics={"sms": {"sent": 3}}, **kw)

    def test_filters_reach_go(self):
        """[case:console.safety.safety_sos.filters]"""
        self.assert_filters(sos_row, {"status": "resolved", "q": "help", **WINDOW}, {"status": "resolved", "q": "help", **WINDOW},
                            contains=[uid(10)[:8] + "…"], keep=("status=resolved",),
                            dropped={"status": "panic", "to": "2026-02-31x"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """[case:console.safety.safety_sos.export]"""
        self.assert_export(sos_row, {"status": "resolved", **WINDOW}, {"status": "resolved", **WINDOW},
                           ("Alert ID", "Member ID", "Level", "Status", "Latitude", "Longitude", "Triggered (UTC)", "Resolved (UTC)"),
                           {"Alert ID": uid(0), "Level": "high", "Latitude": 18.52, "Triggered (UTC)": "2026-09-30T21:00:00Z"},
                           {"status": "resolved", "from": "2026-09-01"}, "sos-alerts")


# ── Moderation ────────────────────────────────────────────────────────────

def appeal_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "report_id": OTHER, "reason": f"Appeal reason {i}", "description": "", "status": "under_review",
            "resolution_reason": "", "reviewed_by": "", "reviewed_at": None, "sla_deadline_at": "2026-10-04T10:00:00Z",
            "notification_policy": "standard", "created_at": "2026-10-02T10:00:00Z", "updated_at": "2026-10-02T10:00:00Z"}


class AppealListTest(ListCase):
    url, method, items = "appeal_queue", "list_appeals", "appeals"

    def test_filters_reach_go(self):
        """[case:console.appeals.appeal_queue.filters]"""
        self.assert_filters(appeal_row, {"status": "under_review", "q": "reason", "sort": "sla_deadline_at", "dir": "asc", **WINDOW},
                            {"status": "under_review", "q": "reason", "sort": "sla_deadline_at", "order": "asc", **WINDOW},
                            contains=["Appeal reason 10"], keep=("sort=sla_deadline_at", "dir=asc", "status=under_review"),
                            dropped={"status": "won", "sort": "reason"}, dropped_kwargs={"limit": 25, "offset": 0, "sort": "created_at", "order": "desc"})

    def test_excel_export(self):
        """[case:console.appeals.appeal_queue.export]"""
        self.assert_export(appeal_row, {"status": "under_review"}, {"status": "under_review", "sort": "created_at", "order": "desc"},
                           ("Appeal ID", "Member ID", "Reason", "Status", "SLA deadline (UTC)", "Submitted (UTC)"),
                           {"Appeal ID": uid(0), "Reason": "Appeal reason 0", "SLA deadline (UTC)": "2026-10-04T10:00:00Z"},
                           {"status": "under_review"}, "appeals")


def report_row(i: int) -> dict:
    return {"id": uid(i), "reporter_user_id": OTHER, "reported_user_id": MEMBER, "reason": "harassment", "description": f"Rude message {i}",
            "status": "pending", "action": "", "reviewed_by": "", "reviewed_at": None, "created_at": "2026-09-30T10:00:00Z"}


class ModerationReportListTest(ListCase):
    url, method, items = "moderation_reports", "list_reports", "reports"

    def test_filters_reach_go(self):
        """[case:console.moderation_reports.moderation_reports.filters]"""
        self.assert_filters(report_row, {"status": "pending", "category": "harassment", "q": "rude", **WINDOW},
                            {"status": "pending", "category": "harassment", "q": "rude", **WINDOW},
                            contains=["Rude message 10"], keep=("category=harassment",),
                            dropped={"status": "escalated"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """[case:console.moderation_reports.moderation_reports.export]"""
        self.assert_export(report_row, {"category": "harassment"}, {"category": "harassment"},
                           ("Report ID", "Reporter ID", "Reported member ID", "Reason", "Description", "Status", "Reported (UTC)"),
                           {"Report ID": uid(0), "Reporter ID": OTHER, "Description": "Rude message 0"}, {"category": "harassment"},
                           "moderation-reports")


def media_row(i: int) -> dict:
    return {"photo_id": uid(i), "user_id": MEMBER, "username": f"member_{i}", "photo_url": f"/media/{i}.jpg", "mime_type": "image/jpeg",
            "width_px": 1080, "height_px": 1350, "size_bytes": 204800, "status": "provider_error", "reason": "provider timeout",
            "provider": "sightengine", "model_version": "2026-09", "max_confidence": 0.42, "labels": [], "uploaded_at": "2026-09-30T10:00:00Z"}


class MediaModerationListTest(ListCase):
    url, method, items = "media_moderation_queue", "list_media_moderation", "items"

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), **kw)

    def test_filters_reach_go(self):
        """[case:console.moderation_media.media_moderation_queue.filters]"""
        self.assert_filters(media_row, {"status": "provider_error", "q": "member", **WINDOW}, {"status": "provider_error", "q": "member", **WINDOW},
                            contains=["member_10"], keep=("status=provider_error",),
                            dropped={"status": "approved"}, dropped_kwargs={"limit": 25, "offset": 0, "status": "review_required"})

    def test_excel_export(self):
        """[case:console.moderation_media.media_moderation_queue.export]"""
        self.assert_export(media_row, {"status": "provider_error"}, {"status": "provider_error"},
                           ("Photo ID", "Username", "Status", "Reason", "Provider", "Model", "Max confidence", "Type", "Width", "Height",
                            "Bytes", "Uploaded (UTC)"),
                           {"Photo ID": uid(0), "Reason": "provider timeout", "Max confidence": 0.42, "Bytes": 204800},
                           {"status": "provider_error"}, "profile-media")


def verification_row(i: int) -> dict:
    return {"user_id": uid(i), "status": "rejected", "rejection_reason": "Photo too dark", "submitted_at": "2026-09-29T10:00:00Z",
            "reviewed_at": "2026-09-30T10:00:00Z", "reviewed_by": OPERATOR, "evidence_received": True}


class VerificationExportTest(ListCase):
    url, method, items = "verification_queue", "list_verifications", "verifications"

    def test_excel_export(self):
        """[case:console.verifications.verification_queue.export]"""
        self.assert_export(verification_row, {"status": "rejected", "q": "member", **WINDOW},
                           {"status": "rejected", "q": "member", "sort": "submitted_at", "order": "desc", **WINDOW},
                           ("Member ID", "Status", "Submitted (UTC)", "Reviewed (UTC)", "Rejection reason"),
                           {"Member ID": uid(0), "Status": "rejected", "Rejection reason": "Photo too dark"},
                           {"status": "rejected", "q": "member", "to": "2026-09-30"}, "verifications")


def blog_row(i: int) -> dict:
    return {"id": uid(i), "content_type": "comment", "content_id": OTHER, "subject_id": MEMBER, "reason": "harassment",
            "description": f"Report {i}", "snapshot": {"body": "Private body"}, "photo_ids": [], "status": "removed",
            "decision_note": "Removed", "appeal": "", "version": 2, "created_at": "2026-09-30T10:00:00Z",
            "review_due_at": "2026-10-01T10:00:00Z", "overdue": False, "evidence_purged": False}


class BlogReviewFiltersTest(ListCase):
    module = "control_panel.views_blog"
    url, method, items = "blog_reviews", "blog_reviews", "cases"

    def page(self, rows, total, **kw):
        return super().page(rows, total, metrics={"pending_reviews": 3}, has_more=True, **kw)

    def test_filters_reach_go(self):
        """Queue, content type, window, search and sort reach Go; an unknown queue reads pending. [case:console.moderation_blog.blog_reviews.filters]"""
        self.assert_filters(blog_row, {"status": "removed", "content_type": "comment", "q": "report", "sort": "created_at", "dir": "desc", **WINDOW},
                            {"status": "removed", "content_type": "comment", "q": "report", "sort": "created_at", "order": "desc", **WINDOW},
                            contains=["Report 10"], keep=("content_type=comment", "sort=created_at", "dir=desc", "to=2026-09-30"),
                            dropped={"status": "deleted", "content_type": "video"},
                            dropped_kwargs={"limit": 25, "offset": 0, "status": "pending", "sort": "review_due_at", "order": "asc"})


def cover_row(i: int) -> dict:
    return {"cover_id": uid(i), "group_id": OTHER, "group_name": f"Hikers {i}", "group_kind": "community", "owner_user_id": MEMBER,
            "uploaded_by": MEMBER, "status": "approved", "reason": "", "provider": "sandbox", "mime_type": "image/jpeg", "width_px": 1200,
            "height_px": 675, "size_bytes": 2048, "uploaded_at": "2026-10-01T09:00:00Z",
            "content_url": f"/v1/admin/moderation/group-covers/{uid(i)}/content"}


class GroupCoverFiltersTest(ListCase):
    module = "control_panel.views_group_covers"
    url, method, items = "group_covers", "group_covers", "items"

    def test_filters_reach_go(self):
        """[case:console.moderation_group_covers.group_covers.filters]"""
        self.assert_filters(cover_row, {"status": "approved", "q": "hikers", **WINDOW}, {"status": "approved", "q": "hikers", **WINDOW},
                            contains=["Hikers 10"], keep=("status=approved", "q=hikers"),
                            dropped={"status": "rejected"}, dropped_kwargs={"limit": 25, "offset": 0, "status": "pending"})


# ── Platform ──────────────────────────────────────────────────────────────

def audit_row(i: int) -> dict:
    return {"id": uid(i), "occurred_at": "2026-10-01T10:00:00Z", "txid": 5000 + i, "event_type": "user.suspended", "actor_user_id": OPERATOR,
            "actor_role": "trust_safety", "subject_user_id": MEMBER, "resource_type": "users", "resource_id": MEMBER,
            "correlation_id": f"corr-{i}", "payload": {"reason": "spam"}}


class AuditLogListTest(ListCase):
    url, method, items = "audit_log", "list_audit_events", "events"

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), source="audit.operator_action_log", append_only=True,
                            as_of="2026-10-03T00:00:00Z", **kw)

    def test_filters_reach_go(self):
        """[case:console.audit.audit_log.filters]"""
        query = {"event_type": "user.suspended", "actor_user_id": OPERATOR, "subject_user_id": MEMBER, "resource_type": "users", "q": "users", **WINDOW}
        self.assert_filters(audit_row, query, query, contains=["corr-10"], keep=("event_type=user.suspended", f"actor_user_id={OPERATOR}"),
                            dropped={"event_type": "x" * 120, "from": "2026/09/01"}, dropped_kwargs={"limit": 50, "offset": 0, "event_type": "x" * 80})

    def test_excel_export(self):
        """[case:console.audit.audit_log.export]"""
        self.assert_export(audit_row, {"event_type": "user.suspended"}, {"event_type": "user.suspended"},
                           ("Occurred (UTC)", "Event", "Actor ID", "Actor role", "Subject ID", "Resource", "Resource ID", "Correlation ID",
                            "Transaction", "Payload"),
                           {"Event": "user.suspended", "Actor role": "trust_safety", "Transaction": 5000, "Payload": "reason: spam"},
                           {"event_type": "user.suspended"}, "operator-audit")


def domain_event_row(i: int) -> dict:
    return {"sequence_id": 9000 + i, "event_id": uid(i), "event_name": "match.created", "event_version": 1, "aggregate_type": "match",
            "aggregate_id": OTHER, "producer": "bff", "subject_user_id": MEMBER, "actor_user_id": MEMBER, "correlation_id": f"corr-{i}",
            "causation_id": "", "payload": {}, "metadata": {}, "occurred_at": "2026-10-01T10:00:00Z"}


class DomainEventListTest(ListCase):
    url, method, items = "domain_events", "list_domain_events", "events"

    def setUp(self):
        super().setUp()
        self.bff().domain_event_metrics.return_value = APIResult(True, {"total_events": 9205, "events_15m": 4, "pending_deliveries": 0,
                                                                        "dead_letters": 0, "coverage_complete": True, "as_of": "2026-10-03T00:00:00Z"})

    def page(self, rows, total, **kw):
        return super().page(rows, total, source="platform.domain_event_outbox", append_only=True, delivery={}, count=len(rows), **kw)

    def test_filters_reach_go(self):
        """[case:console.events.domain_events.filters]"""
        query = {"event_name": "match.created", "aggregate_type": "match", "aggregate_id": OTHER, "producer": "bff", "correlation_id": "corr-1",
                 "subject_user_id": MEMBER, "actor_user_id": MEMBER, "q": "match", **WINDOW}
        self.assert_filters(domain_event_row, query, query, contains=["corr-10"], keep=("producer=bff", "event_name=match.created"),
                            dropped={"to": "soon"}, dropped_kwargs={"limit": 50, "offset": 0})

    def test_excel_export(self):
        """[case:console.events.domain_events.export]"""
        self.assert_export(domain_event_row, {"producer": "bff"}, {"producer": "bff"},
                           ("Sequence", "Occurred (UTC)", "Event", "Version", "Aggregate", "Aggregate ID", "Producer", "Actor ID",
                            "Correlation ID", "Event ID"),
                           {"Sequence": 9000, "Event": "match.created", "Version": 1, "Event ID": uid(0)}, {"producer": "bff"}, "domain-events")


def fraud_edge(i: int) -> dict:
    return {"id": uid(i), "left_member_id": MEMBER, "right_member_id": OTHER, "signal_type": "referral_velocity", "confidence": 0.8,
            "evidence": {"referrals_24h": 12}, "review_status": "confirmed", "action_mode": "review_only", "reviewed_by": OPERATOR,
            "reviewed_at": "2026-10-02T10:00:00Z", "created_at": "2026-10-01T10:00:00Z"}


class GrowthGovernanceListTest(ListCase):
    url, method, items = "growth_governance", "list_growth_fraud_graph", "edges"

    def setUp(self):
        super().setUp()
        self.bff().growth_portfolio.return_value = APIResult(True, {"modules": []})

    def page(self, rows, total, **kw):
        return super().page(rows, total, success=True, automatic_enforcement=False, **kw)

    def test_filters_reach_go(self):
        """[case:console.growth.growth_governance.filters]"""
        self.assert_filters(fraud_edge, {"status": "confirmed", "signal_type": "referral_velocity", "member": MEMBER, "q": "review",
                                         "sort": "created_at", "dir": "asc", **WINDOW},
                            {"status": "confirmed", "signal_type": "referral_velocity", "member": MEMBER, "q": "review", "sort": "created_at",
                             "order": "asc", **WINDOW},
                            contains=["referrals_24h: 12"], keep=("signal_type=referral_velocity", "status=confirmed"),
                            dropped={"status": "maybe", "signal_type": "bots"},
                            dropped_kwargs={"limit": 25, "offset": 0, "status": "open", "sort": "confidence", "order": "desc"})

    def test_excel_export(self):
        """[case:console.growth.growth_governance.export]"""
        self.assert_export(fraud_edge, {"status": "all"}, {"status": "", "sort": "confidence", "order": "desc"},
                           ("Signal ID", "Signal", "Member A", "Member B", "Confidence", "Review status", "Action mode", "Evidence",
                            "Reviewed by", "Reviewed (UTC)", "Detected (UTC)"),
                           {"Signal ID": uid(0), "Confidence": 0.8, "Evidence": "referrals_24h: 12", "Review status": "confirmed"},
                           {"status": "all"}, "growth-fraud-signals")


# ── Engagement ────────────────────────────────────────────────────────────

def prompt_row(i: int) -> dict:
    return {"id": uid(i), "question_text": f"What made you smile today {i}?", "category": "fun", "active_date": "2026-10-01",
            "is_active": True, "response_count": i, "created_by": OPERATOR, "created_at": "2026-09-01T10:00:00Z"}


class PromptListTest(ListCase):
    url, method, items = "engagement_prompts", "list_engagement_prompts", "prompts"

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), **kw)

    def test_filters_reach_go(self):
        """[case:console.engagement.engagement_prompts.filters]"""
        self.assert_filters(prompt_row, {"category": "fun", "active": "yes", "q": "smile", "sort": "active_date", "dir": "asc", **WINDOW},
                            {"category": "fun", "active": "yes", "q": "smile", "sort": "active_date", "order": "asc", **WINDOW},
                            contains=["What made you smile today 10?"], keep=("category=fun", "active=yes", "sort=active_date"),
                            dropped={"category": "politics", "active": "maybe"}, dropped_kwargs={"limit": 25, "offset": 0, "sort": "created_at", "order": "desc"})

    def test_excel_export(self):
        """[case:console.engagement.engagement_prompts.export]"""
        self.assert_export(prompt_row, {"category": "fun"}, {"category": "fun", "sort": "created_at", "order": "desc"},
                           ("Prompt ID", "Prompt", "Category", "Active", "Active date", "Responses", "Created by", "Created (UTC)"),
                           {"Prompt": "What made you smile today 0?", "Active": "Yes", "Responses": 0}, {"category": "fun"}, "daily-prompts")


def nudge_row(i: int) -> dict:
    return {"id": uid(i), "match_id": OTHER, "user_id": MEMBER, "counterparty_user_id": OTHER, "nudge_type": "stalled_24h",
            "created_at": "2026-09-10T08:00:00Z", "clicked_at": "2026-09-10T09:00:00Z"}


class NudgeListTest(ListCase):
    url, method, items = "engagement_nudges", "list_engagement_nudges", "nudges"

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), clicked=len(rows), by_type={"stalled_24h": len(rows)}, enabled=True, **kw)

    def test_filters_reach_go(self):
        """[case:console.engagement.engagement_nudges.filters]"""
        query = {"nudge_type": "stalled_24h", "status": "clicked", "clicked": "yes", "user_id": MEMBER, "match_id": OTHER, "q": "stalled", **WINDOW}
        self.assert_filters(nudge_row, {**query, "sort": "clicked_at", "dir": "asc"}, {**query, "sort": "clicked_at", "order": "asc"},
                            contains=["stalled_24h · 10"], keep=("clicked=yes", f"match_id={OTHER}", "sort=clicked_at"),
                            dropped={"status": "opened", "clicked": "sometimes"}, dropped_kwargs={"limit": 25, "offset": 0, "sort": "created_at", "order": "desc"})

    def test_excel_export(self):
        """[case:console.engagement.engagement_nudges.export]"""
        self.assert_export(nudge_row, {"clicked": "yes"}, {"clicked": "yes", "sort": "created_at", "order": "desc"},
                           ("Nudge ID", "Type", "Match ID", "Recipient ID", "Counterparty ID", "Sent (UTC)", "Clicked (UTC)"),
                           {"Nudge ID": uid(0), "Type": "stalled_24h", "Clicked (UTC)": "2026-09-10T09:00:00Z"}, {"clicked": "yes"}, "match-nudges")


def theme_row(i: int) -> dict:
    return {"id": uid(i), "slug": f"theme-{i}", "title": f"Theme {i}", "prompt": "Show us your Sunday", "status": "active", "sort_order": i,
            "entry_count": 2, "my_entry_id": ""}


class PhotoThemeListTest(ListCase):
    module = "control_panel.views_photo_themes"
    url, method, items = "photo_themes", "photo_themes", "themes"

    def test_filters_reach_go(self):
        """[case:console.engagement.photo_themes.filters]"""
        self.assert_filters(theme_row, {"status": "active", "q": "sunday", "sort": "title", "dir": "desc"},
                            {"status": "active", "q": "sunday", "sort": "title", "order": "desc"},
                            contains=["theme-10"], keep=("sort=title", "dir=desc", "status=active"),
                            dropped={"status": "deleted", "sort": "entry_count"}, dropped_kwargs={"limit": 50, "offset": 0, "sort": "sort_order", "order": "asc"})

    def test_excel_export(self):
        """[case:console.engagement.photo_themes.export]"""
        self.assert_export(theme_row, {"status": "active"}, {"status": "active", "sort": "sort_order", "order": "asc"},
                           ("Theme ID", "Slug", "Title", "Prompt", "Status", "Display order", "Live photos"),
                           {"Slug": "theme-0", "Prompt": "Show us your Sunday", "Display order": 0, "Live photos": 2}, {"status": "active"}, "photo-themes")


def xp_case(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "username": f"member_{i}", "rule_code": "repeated_source_cap", "severity": "high",
            "status": "confirmed", "evidence": {"rejected_attempts": 5}, "created_at": "2026-09-30T10:00:00Z"}


class ProgressionFraudListTest(ListCase):
    url, method, items = "progression_admin", "list_progression_fraud", "cases"

    def setUp(self):
        super().setUp()
        self.bff().progression_overview.return_value = APIResult(True, {"metrics": {}, "policies": [], "experiments": [], "fraud_rules": []})

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), **kw)

    def test_filters_reach_go(self):
        """[case:console.progression.progression_admin.filters]"""
        query = {"status": "confirmed", "severity": "high", "rule_code": "repeated_source_cap", "user_id": MEMBER, "q": "member", **WINDOW}
        self.assert_filters(xp_case, query, {**query, "sort": "created_at", "order": "desc"},
                            contains=["@member_10"], keep=("severity=high", "rule_code=repeated_source_cap"),
                            dropped={"status": "all", "severity": "extreme"}, dropped_kwargs={"limit": 25, "offset": 0, "status": "", "sort": "created_at", "order": "desc"})

    def test_excel_export(self):
        """[case:console.progression.progression_admin.export]"""
        self.assert_export(xp_case, {"severity": "high"}, {"status": "open", "severity": "high", "sort": "created_at", "order": "desc"},
                           ("Case ID", "Member ID", "Username", "Rule", "Severity", "Status", "Evidence", "Opened (UTC)"),
                           {"Username": "member_0", "Rule": "repeated_source_cap", "Evidence": "rejected_attempts: 5"}, {"severity": "high"}, "xp-fraud-cases")


# ── Billing ───────────────────────────────────────────────────────────────

def payment_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "subscription_id": "", "amount_paise": 19900, "currency": "INR", "status": "captured",
            "provider": "stripe", "provider_order_id": f"order_{i}", "provider_payment_id": f"pi_{i}", "provider_invoice_id": "",
            "billing_reason": "subscription_create", "payment_method_brand": "visa", "payment_method_last4": "4242",
            "refunded_amount_paise": 0, "failure_reason": "", "paid_at": "2026-09-30T10:00:01Z", "created_at": "2026-09-30T10:00:00Z", "metadata": {}}


class PaymentListTest(ListCase):
    url, method, items = "billing_payments", "list_payments", "payments"

    def test_filters_reach_go(self):
        """[case:console.billing.billing_payments.filters]"""
        self.assert_filters(payment_row, {"status": "captured", "q": "pi_1", **WINDOW}, {"status": "captured", "q": "pi_1", **WINDOW},
                            contains=["pi_10"], keep=("status=captured", "q=pi_1"),
                            dropped={"status": "chargeback"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """Amounts are written in major units from Go's amount_paise. [case:console.billing.billing_payments.export]"""
        self.assert_export(payment_row, {"status": "captured"}, {"status": "captured"},
                           ("Member ID", "Amount", "Currency", "Status", "Provider order", "Provider payment", "Created (UTC)", "Paid (UTC)"),
                           {"Amount": 199.0, "Currency": "INR", "Provider payment": "pi_0", "Paid (UTC)": "2026-09-30T10:00:01Z"},
                           {"status": "captured"}, "payments")


def subscription_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "plan_code": "premium", "status": "past_due", "billing_cycle": "monthly",
            "start_date": "2026-08-01T00:00:00Z", "end_date": None, "next_billing_date": "2026-10-01T00:00:00Z", "auto_renew": True,
            "cancel_at_period_end": False, "current_period_end": "2026-10-01T00:00:00Z", "provider": "stripe",
            "provider_subscription_id": f"sub_{i}", "payment_method_brand": "visa", "payment_method_last4": "4242", "amount_minor": 49900,
            "currency": "INR", "created_at": "2026-08-01T00:00:00Z", "updated_at": "2026-10-01T00:00:00Z"}


class SubscriptionListTest(ListCase):
    url, method, items = "billing_subscriptions", "list_subscriptions", "subscriptions"

    def test_filters_reach_go(self):
        """[case:console.billing.billing_subscriptions.filters]"""
        self.assert_filters(subscription_row, {"status": "past_due", "plan_code": "premium", "q": "sub_", **WINDOW},
                            {"status": "past_due", "plan_code": "premium", "q": "sub_", **WINDOW},
                            contains=["sub_10"], keep=("plan_code=premium",),
                            dropped={"status": "trialing"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """[case:console.billing.billing_subscriptions.export]"""
        self.assert_export(subscription_row, {"plan_code": "premium"}, {"plan_code": "premium"},
                           ("Member ID", "Plan", "Cycle", "Status", "Provider", "Provider reference", "Started (UTC)", "Period end (UTC)",
                            "Ended (UTC)", "Auto-renew", "Ending"),
                           {"Plan": "premium", "Provider reference": "sub_0", "Auto-renew": "Yes", "Ending": "No", "Ended (UTC)": None},
                           {"plan_code": "premium"}, "subscriptions")


def transaction_row(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "package_id": "coins_500", "source": "purchase", "provider": "stripe", "coins": 500,
            "amount_minor": 9900, "currency": "INR", "purchase_ref": f"cs_{i}", "created_at": "2026-09-20T00:00:00Z"}


class TransactionListTest(ListCase):
    url, method, items = "billing_transactions", "list_billing_transactions", "transactions"

    def test_filters_reach_go(self):
        """[case:console.billing.billing_transactions.filters]"""
        self.assert_filters(transaction_row, {"source": "purchase", "provider": "stripe", "q": "cs_", **WINDOW},
                            {"source": "purchase", "provider": "stripe", "q": "cs_", **WINDOW},
                            contains=["cs_10"], keep=("source=purchase", "provider=stripe"),
                            dropped={"from": "2026-9-1"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """[case:console.billing.billing_transactions.export]"""
        self.assert_export(transaction_row, {"provider": "stripe"}, {"provider": "stripe"},
                           ("Purchase reference", "Member ID", "Coins", "Amount", "Currency", "Source", "Provider", "Created (UTC)"),
                           {"Purchase reference": "cs_0", "Coins": 500, "Amount": 99.0}, {"provider": "stripe"}, "coin-purchases")


def webhook_row(i: int) -> dict:
    return {"id": uid(i), "provider": "stripe", "event_id": f"evt_{i}", "event_type": "invoice.paid", "event_created_at": "2026-09-30T10:00:00Z",
            "received_at": "2026-09-30T10:00:02Z", "processed_at": None, "status": "failed", "error": "signature mismatch"}


class WebhookListTest(ListCase):
    url, method, items = "billing_webhook_events", "list_billing_webhook_events", "events"

    def test_filters_reach_go(self):
        """[case:console.billing.billing_webhook_events.filters]"""
        self.assert_filters(webhook_row, {"status": "failed", "event_type": "invoice.paid", "q": "evt_", **WINDOW},
                            {"status": "failed", "event_type": "invoice.paid", "q": "evt_", **WINDOW},
                            contains=["evt_10"], keep=("event_type=invoice.paid",),
                            dropped={"status": "lost"}, dropped_kwargs={"limit": 25, "offset": 0})

    def test_excel_export(self):
        """[case:console.billing.billing_webhook_events.export]"""
        self.assert_export(webhook_row, {"status": "failed"}, {"status": "failed"},
                           ("Event ID", "Provider", "Event type", "Status", "Error", "Received (UTC)"),
                           {"Event ID": "evt_0", "Error": "signature mismatch", "Received (UTC)": "2026-09-30T10:00:02Z"}, {"status": "failed"},
                           "webhook-events")


def coin_fraud_case(i: int) -> dict:
    return {"id": uid(i), "user_id": MEMBER, "rule_code": "gift_burst", "event_type": "gift_send", "status": "confirmed", "severity": "critical",
            "recommended_action": "temporary_lock", "action_taken": "temporary_lock", "observed_value": 12, "trigger_value": 10,
            "window_seconds": 300, "occurrence_count": 2, "match_id": "", "receiver_user_id": OTHER, "first_detected_at": "2026-09-29T10:00:00Z",
            "last_detected_at": "2026-09-30T10:00:00Z", "resolution_note": "", "lock_until": "2026-09-30T11:00:00Z"}


class ReconciliationListTest(ListCase):
    url, method, items = "billing_reconciliation", "list_economy_fraud_cases", "cases"

    def setUp(self):
        super().setUp()
        api = self.bff()
        # billing_repository_postgres.go: revenue holds *_minor integers.
        api.get_billing_reconciliation.return_value = APIResult(True, {"currency": "INR", "revenue": {
            "gross_minor": 100000, "refunded_minor": 0, "chargeback_minor": 0, "disputed_at_risk_minor": 0, "net_minor": 100000,
            "local_activation_minor": 0, "note": "net = settled provider payments minus refunds"}})
        api.list_frozen_wallets.return_value = APIResult(True, {"wallets": []})
        api.list_economy_fraud_rules.return_value = APIResult(True, {"rules": []})

    def page(self, rows, total, **kw):
        return super().page(rows, total, count=len(rows), status="confirmed", **kw)

    def test_filters_reach_go(self):
        """The fraud-case filters reach Go's case list; the settlement window (since/until) reaches the reconciliation read. [case:console.billing.billing_reconciliation.filters]"""
        query = {"status": "confirmed", "severity": "critical", "rule_code": "gift_burst", "user_id": MEMBER, "q": "gift", **WINDOW}
        response = self.assert_filters(coin_fraud_case, {**query, "sort": "first_detected_at", "dir": "asc", "since": "2026-09-01", "until": "2026-09-30"},
                                       {**query, "sort": "first_detected_at", "order": "asc"},
                                       contains=["gift_burst"], keep=("severity=critical", "sort=first_detected_at"),
                                       dropped={"status": "frozen", "severity": "huge"},
                                       dropped_kwargs={"limit": 25, "offset": 0, "status": "open", "sort": "severity", "order": "desc"})
        self.bff().get_billing_reconciliation.assert_any_call(since="2026-09-01", until="2026-09-30")
        self.assertContains(response, "1,000.00")

    def test_excel_export(self):
        """[case:console.billing.billing_reconciliation.export]"""
        self.assert_export(coin_fraud_case, {"severity": "critical"}, {"status": "open", "severity": "critical", "sort": "severity", "order": "desc"},
                           ("Case ID", "Member ID", "Rule", "Event", "Status", "Severity", "Recommended action", "Action taken", "Observed",
                            "Trigger", "Window (s)", "Occurrences", "Match ID", "Receiver ID", "First detected (UTC)", "Last detected (UTC)",
                            "Locked until (UTC)", "Resolution note"),
                           {"Rule": "gift_burst", "Observed": 12, "Window (s)": 300, "Locked until (UTC)": "2026-09-30T11:00:00Z"},
                           {"severity": "critical"}, "coin-fraud-cases")


# ── Members ───────────────────────────────────────────────────────────────

def user_row(i: int) -> dict:
    return {"id": uid(i), "username": f"member_{i}", "name": f"Member {i}", "phone_number": f"+9198000{i:05d}", "gender": "female", "bio": "",
            "height_cm": 160, "education": "", "profession": "", "city": "Pune", "state": "MH", "country": "IN", "profile_completion": 70,
            "is_verified": True, "last_login_at": "2026-10-01T09:00:00Z", "created_at": "2026-01-10T09:00:00Z",
            "suspended_at": "2026-09-01T00:00:00Z", "suspended_reason": "spam", "is_banned": False}


class UserListTest(ListCase):
    url, method, items = "user_list", "list_users", "users"

    def page(self, rows, total, **kw):
        kw.pop("limit", None), kw.pop("offset", None)  # GET /admin/users has no limit/offset keys
        return APIResult(True, {"users": rows, "total": total, "kpis": {"total": total, "active": 1, "suspended": total - 1, "banned": 0,
                                                                        "verified": total, "verified_pct": 100.0}})

    def test_filters_reach_go(self):
        """[case:console.users.user_list.filters]"""
        self.assert_filters(user_row, {"q": "member", "status": "suspended", "gender": "female", "verified": "yes"},
                            {"q": "member", "status": "suspended", "gender": "female", "verified": "yes"},
                            contains=["member_10"], keep=("status=suspended", "gender=female", "verified=yes"),
                            dropped={"status": "deleted", "gender": "robot", "verified": "maybe"},
                            dropped_kwargs={"limit": 25, "offset": 0, "q": "", "status": "", "gender": "", "verified": ""})

    def test_excel_export(self):
        """Every matching member in the workbook, with the status worked out from Go's suspended_at/is_banned. [case:console.users.user_list.export]"""
        self.assert_export(user_row, {"status": "suspended"}, {"q": "", "status": "suspended", "gender": "", "verified": ""},
                           ("User ID", "Name", "Username", "Phone", "Gender", "Joined (UTC)", "Status", "Verified"),
                           {"User ID": uid(0), "Username": "member_0", "Status": "Suspended", "Verified": "Yes"}, {"status": "suspended"}, "users")


# ── Server activity ───────────────────────────────────────────────────────

def server_event(i: int) -> dict:
    return {"id": 700 + i, "at": "2026-10-02T10:00:00Z", "kind": "server_error", "severity": "error", "service": "bff", "instance": "bff-1",
            "message": f"panic in handler {i}", "route": "/v1/swipe", "correlation_id": f"corr-{i}", "count": 3,
            "first_at": "2026-10-02T09:58:00Z", "last_at": "2026-10-02T10:00:00Z", "details": {"status": 500}}


class SystemEventsListTest(ListCase):
    module = "control_panel.views_system"
    url, method, items = "system_events", "system_events", "events"

    def page(self, rows, total, **kw):
        return super().page(rows, total, total_capped=False, **kw)

    def test_renders_events_and_a_failure(self):
        """[case:console.system.system_events.renders]"""
        api = self.bff()
        api.system_events.return_value = self.page([server_event(1)], 1)
        response = self.get()
        self.assertEqual(response.status_code, 200)
        api.system_events.assert_called_once_with(limit=50, offset=0)
        self.assertContains(response, "panic in handler 1")
        self.assertContains(response, "/v1/swipe")
        api.system_events.return_value = bff_error("forbidden", 403)
        self.assertContains(self.get(), "forbidden")

    def test_filters_reach_go(self):
        """[case:console.system.system_events.filters]"""
        query = {"kind": "server_error", "severity": "error", "service": "bff", "q": "panic", **WINDOW}
        self.assert_filters(server_event, query, query, contains=["panic in handler 10"], keep=("kind=server_error", "severity=error", "service=bff"),
                            dropped={"kind": "meteor", "severity": "doom"}, dropped_kwargs={"limit": 50, "offset": 0})

    def test_excel_export(self):
        """[case:console.system.system_events.export]"""
        self.assert_export(server_event, {"severity": "error"}, {"severity": "error"},
                           ("Time (UTC)", "Kind", "Severity", "Service", "Instance", "Message", "Route", "Count", "First (UTC)", "Last (UTC)",
                            "Correlation ID", "Details"),
                           {"Kind": "server_error", "Message": "panic in handler 0", "Count": 3, "Details": "status: 500"}, {"severity": "error"},
                           "server-events")


def job_run(i: int) -> dict:
    return {"id": 900 + i, "worker": "push_outbox", "instance": "bff-1", "build_commit": "abc123", "started_at": "2026-10-02T10:00:00Z",
            "finished_at": "2026-10-02T10:00:02Z", "duration_ms": 2000, "status": "failed", "items_processed": 40, "items_failed": 2,
            "backlog_after": 7, "error": f"fcm 503 #{i}", "details": {"retry": True}}


WORKERS = {"workers": [
    {"worker": "push_outbox", "expected_interval_seconds": 60.0, "last_run_at": "2026-10-02T10:00:00Z", "last_success_at": "2026-10-02T09:00:00Z",
     "last_status": "failed", "last_duration_ms": 2000, "last_error": "fcm 503", "runs_24h": 1400, "failures_24h": 12, "items_24h": 5000, "stale": True},
    {"worker": "retention", "expected_interval_seconds": 3600.0, "last_run_at": "2026-10-02T10:00:00Z", "last_success_at": "2026-10-02T10:00:00Z",
     "last_status": "succeeded", "last_duration_ms": 900, "last_error": "", "runs_24h": 24, "failures_24h": 0, "items_24h": 100, "stale": False}]}


class SystemJobsListTest(ListCase):
    module = "control_panel.views_system"
    url, method, items = "system_jobs", "system_job_runs", "runs"

    def setUp(self):
        super().setUp()
        self.bff().system_jobs.return_value = APIResult(True, WORKERS)

    def page(self, rows, total, **kw):
        return super().page(rows, total, total_capped=False, **kw)

    def test_renders_workers_and_runs(self):
        """The worker summary counts stale and failing workers; runs render; Go's refusal is shown. [case:console.system.system_jobs.renders]"""
        api = self.bff()
        api.system_job_runs.return_value = self.page([job_run(1)], 1)
        response = self.get()
        api.system_job_runs.assert_called_once_with(limit=50, offset=0)
        self.assertEqual((response.context["stale_count"], response.context["failing_count"]), (1, 1))
        self.assertContains(response, "push_outbox")
        self.assertContains(response, "fcm 503 #1")
        api.system_jobs.return_value = bff_error("forbidden", 403)
        api.system_job_runs.return_value = bff_error("forbidden", 403)
        self.assertEqual(self.get().context["jobs_error"], "forbidden")

    def test_details_with_an_items_key_render(self):
        """Regression: a run whose details record "items" (the retention worker's
        per-policy list) crashed the page, as the template's ``details.items``
        read that key instead of the dict's pairs. [case:console.system.system_jobs.renders]"""
        run = {**job_run(1), "status": "succeeded", "error": "",
               "details": {"policy": "domain_event_outbox", "items": ["a", "b", "c"]}}
        self.bff().system_job_runs.return_value = self.page([run], 1)
        response = self.get()
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "items: [&#x27;a&#x27;, &#x27;b&#x27;, &#x27;c&#x27;] · policy: domain_event_outbox")

    def test_filters_reach_go(self):
        """[case:console.system.system_jobs.filters]"""
        query = {"worker": "push_outbox", "status": "failed", "q": "fcm", **WINDOW}
        self.assert_filters(job_run, query, query, contains=["fcm 503 #10"], keep=("worker=push_outbox", "status=failed"),
                            dropped={"status": "crashed"}, dropped_kwargs={"limit": 50, "offset": 0})

    def test_excel_export(self):
        """[case:console.system.system_jobs.export]"""
        self.assert_export(job_run, {"status": "failed"}, {"status": "failed"},
                           ("Worker", "Status", "Started (UTC)", "Finished (UTC)", "Duration (ms)", "Items", "Failed items", "Backlog after",
                            "Instance", "Error", "Details"),
                           {"Worker": "push_outbox", "Duration (ms)": 2000, "Failed items": 2, "Error": "fcm 503 #0", "Details": "retry: True"},
                           {"status": "failed"}, "job-runs")
