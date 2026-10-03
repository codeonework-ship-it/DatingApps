"""Operator console: moderation queues — reports, media, appeals, verifications, rooms, group covers, blog
(catalog features console.moderation_*, console.verifications, console.appeals)."""
from uuid import uuid4

from django.urls import reverse

from control_panel.services.go_client import APIResult, BinaryAPIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

OPERATOR = "00000000-0000-0000-0000-0000000000aa"  # case_support.login's operator_user_id
# Field names exactly as Go's moderationReport (backend store.go) sends them.
REPORT = {"id": "rep-1", "reporter_user_id": "u-reporter", "reported_user_id": "u-reported", "reason": "harassment",
          "description": "<img src=x onerror=alert(1)>", "status": "pending", "created_at": "2026-09-30T08:00:00Z"}


class VerifiedStatusTest(ConsoleCaseTest):
    def test_verified_rows_show_as_verified_and_the_filter_uses_gos_value(self):
        """Go stores approvals as "verified". Regression: red badge, empty "Approved" filter. [case:console.verifications.status_value]"""
        api = self.bff()
        api.list_verifications.return_value = APIResult(True, {"verifications": [
            {"user_id": "u-1", "status": "verified", "submitted_at": "2026-09-30T08:00:00Z"}], "total": 1})
        response = self.client.get(reverse("verification_queue"), {"status": "verified"})
        self.assertContains(response, '<span class="badge badge-active">Verified</span>')
        self.assertEqual(api.list_verifications.call_args.kwargs["status"], "verified")


class ModerationReportsTest(ConsoleCaseTest):
    def test_reports_render_with_dates_and_filters(self):
        """Reports list with escaped member text, the reported date and the action form; the status filter is forwarded.
        Regression: dates rendered "—" (|date on an ISO string). [case:console.moderation_reports.moderation_reports.renders]"""
        api = self.bff()
        api.list_reports.return_value = APIResult(True, {"reports": [REPORT]})
        response = self.client.get(reverse("moderation_reports"), {"status": "pending", "limit": "abc"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Moderation Reports")
        self.assertContains(response, "&lt;img src=x onerror=alert(1)&gt;")
        self.assertContains(response, "Sep 30, 2026")
        self.assertContains(response, "u-report…")  # reporter shown (was blank: wrong key)
        self.assertContains(response, "Harassment")  # reason shown (was always "General")
        self.assertContains(response, reverse("action_report", args=["rep-1"]))
        api.list_reports.assert_called_once_with(limit=25, offset=0, status="pending")

    def test_reports_bff_failure_shows_banner(self):
        """[case:console.moderation_reports.moderation_reports.renders]"""
        self.bff().list_reports.return_value = bff_error()
        response = self.client.get(reverse("moderation_reports"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")

    def test_action_report_sends_the_status_go_requires(self):
        """Regression: the action form sent no status and Go answered "status is required" for every report action.
        Now each action maps to a status and the operator is named as reviewer. [case:console.moderation_reports.action_report.renders]"""
        api = self.bff()
        url = reverse("action_report", args=["rep-1"])
        expected = {"dismiss": "rejected", "warn": "resolved", "ban_reported": "resolved", "under_review": "under_review"}
        for action, status in expected.items():
            api.action_report.reset_mock()
            response = self.client.post(url, {"action": action, "reason": " Reviewed chat logs "})
            api.action_report.assert_called_once_with("rep-1", action, "Reviewed chat logs", status=status, reviewed_by=OPERATOR)
            self.assertRedirects(response, reverse("moderation_reports"), fetch_redirect_response=False)
        self.assertIn("Report rep-1 dismissed.", flash(self.client.post(url, {"action": "dismiss"})))
        ban = flash(self.client.post(url, {"action": "ban_reported"}))
        self.assertTrue(any("suspend or ban the member from their user page" in m for m in ban), ban)

    def test_action_report_validation_and_failure(self):
        """[case:console.moderation_reports.action_report.renders]"""
        api = self.bff()
        url = reverse("action_report", args=["rep-1"])
        self.assertIn("Choose a report action.", flash(self.client.post(url, {"action": ""})))
        self.assertIn("Choose a report action.", flash(self.client.post(url, {"action": "delete_account"})))
        api.action_report.assert_not_called()
        api.action_report.return_value = bff_error("action report failed: report is already resolved", 400)
        self.assertIn("Failed to action report rep-1: action report failed: report is already resolved",
                      flash(self.client.post(url, {"action": "dismiss"})))
        self.assertEqual(self.client.get(url).status_code, 405)

    def test_action_report_authz(self):
        """[case:console.moderation_reports.action_report.authz]"""
        self.assert_action_authz(reverse("action_report", args=["rep-1"]), {"action": "dismiss"}, "action_report",
                                 refused_roles=("ops_admin", "support", "analyst"), allowed_roles=("moderator", "trust_safety"))


class MediaModerationTest(ConsoleCaseTest):
    def test_queue_filters_and_failure(self):
        """[case:console.moderation_media.media_moderation_queue.renders]"""
        api = self.bff()
        api.list_media_moderation.return_value = APIResult(True, {"items": [{"photo_id": "photo-1", "username": "<b>u</b>"}]})
        response = self.client.get(reverse("media_moderation_queue"), {"status": "provider_error", "page_size": "999"})
        self.assertContains(response, "&lt;b&gt;u&lt;/b&gt;")
        self.assertContains(response, reverse("media_moderation_content", args=["photo-1"]))
        api.list_media_moderation.assert_called_once_with(limit=25, offset=0, status="provider_error")
        api.list_media_moderation.return_value = bff_error()
        self.assertContains(self.client.get(reverse("media_moderation_queue")), "alert-glass warning")

    def test_content_failures_are_plain_text_and_never_500(self):
        """Regression: a failed fetch echoed the BFF's error as text/html and passed a Go 500 through as a console 500. [case:console.moderation_media.media_moderation_content.renders]"""
        api = self.bff()
        api.get_media_moderation_content.return_value = BinaryAPIResult(False, error="<script>x</script>", status_code=500)
        response = self.client.get(reverse("media_moderation_content", args=["photo-1"]))
        self.assertEqual(response.status_code, 502)
        self.assertTrue(response["Content-Type"].startswith("text/plain"))
        api.get_media_moderation_content.return_value = BinaryAPIResult(False, error="photo not found", status_code=404)
        self.assertEqual(self.client.get(reverse("media_moderation_content", args=["photo-1"])).status_code, 404)

    def test_decision_approve_and_reject(self):
        """[case:console.moderation_media.media_moderation_decision.performs]"""
        api = self.bff()
        url = reverse("media_moderation_decision", args=["photo-1"])
        self.assertIn("Choose approve or reject.", flash(self.client.post(url, {"decision": "delete"})))
        api.decide_media_moderation.assert_not_called()
        response = self.client.post(url, {"decision": "APPROVED"})
        api.decide_media_moderation.assert_called_once_with("photo-1", "approved", "")
        self.assertRedirects(response, reverse("media_moderation_queue"), fetch_redirect_response=False)
        self.assertIn("Media photo-1 marked approved.", flash(response))
        self.client.post(url, {"decision": "rejected", "reason": " Nudity "})
        api.decide_media_moderation.assert_called_with("photo-1", "rejected", "Nudity")
        api.decide_media_moderation.return_value = bff_error("photo already decided", 409)
        self.assertIn("Media decision failed: photo already decided", flash(self.client.post(url, {"decision": "approved"})))

    def test_decision_authz(self):
        """[case:console.moderation_media.media_moderation_decision.authz]"""
        self.assert_action_authz(reverse("media_moderation_decision", args=["photo-1"]), {"decision": "approved"},
                                 "decide_media_moderation", refused_roles=("ops_admin", "support", "finance"),
                                 allowed_roles=("moderator",))


class VerificationsTest(ConsoleCaseTest):
    def test_queue_renders_with_dates_and_filters(self):
        """Regression: submitted/reviewed dates rendered "—". [case:console.verifications.verification_queue.renders]"""
        api = self.bff()
        api.list_verifications.return_value = APIResult(True, {"verifications": [
            {"user_id": "u-1", "status": "pending", "submitted_at": "2026-09-29T10:00:00Z"}]})
        response = self.client.get(reverse("verification_queue"), {"status": "pending", "page_size": "10"})
        self.assertContains(response, "Verification Queue")
        self.assertContains(response, "Sep 29, 2026")
        self.assertContains(response, reverse("approve_verification", args=["u-1"]))
        self.assertContains(response, reverse("reject_verification", args=["u-1"]))
        api.list_verifications.assert_called_once_with(limit=10, offset=0, status="pending", sort="submitted_at", order="desc")
        api.list_verifications.return_value = bff_error()
        self.assertContains(self.client.get(reverse("verification_queue")), "alert-glass warning")

    def test_approve(self):
        """[case:console.verifications.approve_verification.renders]"""
        api = self.bff()
        response = self.client.post(reverse("approve_verification", args=["u-1"]))
        api.approve_verification.assert_called_once_with("u-1")
        self.assertRedirects(response, reverse("verification_queue"), fetch_redirect_response=False)
        self.assertIn("Verification approved for u-1.", flash(response))
        api.approve_verification.return_value = bff_error("verification not pending", 409)
        self.assertIn("Failed to approve u-1: verification not pending", flash(self.client.post(reverse("approve_verification", args=["u-1"]))))
        self.assertEqual(self.client.get(reverse("approve_verification", args=["u-1"])).status_code, 405)

    def test_approve_authz(self):
        """[case:console.verifications.approve_verification.authz]"""
        self.assert_action_authz(reverse("approve_verification", args=["u-1"]), {}, "approve_verification",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator",))

    def test_reject(self):
        """[case:console.verifications.reject_verification.renders]"""
        api = self.bff()
        response = self.client.post(reverse("reject_verification", args=["u-1"]), {"rejection_reason": " Blurry selfie "})
        api.reject_verification.assert_called_once_with("u-1", "Blurry selfie")
        self.assertIn("Verification rejected for u-1.", flash(response))
        api.reject_verification.return_value = bff_error("verification not pending", 409)
        self.assertIn("Failed to reject u-1: verification not pending",
                      flash(self.client.post(reverse("reject_verification", args=["u-1"]), {"rejection_reason": "Blurry"})))

    def test_reject_authz(self):
        """[case:console.verifications.reject_verification.authz]"""
        self.assert_action_authz(reverse("reject_verification", args=["u-1"]), {"rejection_reason": "Blurry"}, "reject_verification",
                                 refused_roles=("ops_admin", "finance"), allowed_roles=("trust_safety",))


class AppealsTest(ConsoleCaseTest):
    def test_queue_renders_rows_and_deadline(self):
        """[case:console.appeals.appeal_queue.renders]"""
        api = self.bff()
        api.list_appeals.return_value = APIResult(True, {"appeals": [
            {"id": "apl-1", "user_id": "u-1", "reason": "<i>I was hacked</i>", "status": "submitted", "sla_deadline_at": "2026-10-04T10:00:00Z"}]})
        response = self.client.get(reverse("appeal_queue"), {"status": "submitted"})
        self.assertContains(response, "&lt;i&gt;I was hacked&lt;/i&gt;")
        self.assertContains(response, "Oct 04")
        self.assertContains(response, reverse("action_appeal", args=["apl-1"]))
        api.list_appeals.assert_called_once_with(limit=25, offset=0, status="submitted", sort="created_at", order="desc")
        api.list_appeals.return_value = bff_error()
        self.assertContains(self.client.get(reverse("appeal_queue")), "alert-glass warning")

    def test_action_appeal(self):
        """The decision is forwarded with the signed-in operator as reviewer. [case:console.appeals.action_appeal.renders]"""
        api = self.bff()
        url = reverse("action_appeal", args=["apl-1"])
        self.assertIn("Appeal status is required.", flash(self.client.post(url, {"status": ""})))
        api.action_appeal.assert_not_called()
        response = self.client.post(url, {"status": "resolved_reversed", "resolution_reason": " Account was compromised "})
        api.action_appeal.assert_called_once_with("apl-1", "resolved_reversed", "Account was compromised", reviewed_by=OPERATOR)
        self.assertIn("Appeal apl-1 updated to resolved_reversed.", flash(response))
        api.action_appeal.return_value = bff_error("appeal already resolved", 409)
        self.assertIn("Failed to update appeal apl-1: appeal already resolved",
                      flash(self.client.post(url, {"status": "resolved_upheld"})))

    def test_action_appeal_authz(self):
        """[case:console.appeals.action_appeal.authz]"""
        self.assert_action_authz(reverse("action_appeal", args=["apl-1"]), {"status": "under_review"}, "action_appeal",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator",))


ROOM = "11111111-1111-1111-1111-111111111111"
MEMBER = "44444444-4444-4444-4444-444444444444"


class RoomsCasesTest(ConsoleCaseTest):
    module = "control_panel.views_rooms"

    def test_rooms_bff_server_error_is_502_with_banner(self):
        """[case:console.moderation_rooms.rooms.renders] [case:console.moderation_rooms.room_detail.renders]"""
        api = self.bff()
        api.admin_rooms.return_value = bff_error("The service couldn't complete that request.", 500)
        response = self.client.get(reverse("rooms"))
        self.assertEqual(response.status_code, 502)
        self.assertContains(response, "couldn&#x27;t complete that request", status_code=502)
        detail = self.client.get(reverse("room_detail", args=[ROOM]))
        self.assertEqual(detail.status_code, 502)

    def test_room_action_authz(self):
        """[case:console.moderation_rooms.room_action.authz]"""
        self.assert_action_authz(reverse("room_action", args=[ROOM]),
                                 {"action": "warn_user", "target_user_id": MEMBER, "reason": "Keep it kind"}, "admin_room_action",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator", "trust_safety"),
                                 module=self.module)

    def test_room_role_authz(self):
        """[case:console.moderation_rooms.room_role.authz]"""
        self.assert_action_authz(reverse("room_role", args=[ROOM]), {"member_id": MEMBER, "role": "moderator"}, "admin_room_role",
                                 refused_roles=("ops_admin", "analyst"), allowed_roles=("moderator",), module=self.module)


class GroupCoverCasesTest(ConsoleCaseTest):
    module = "control_panel.views_group_covers"

    def test_queue_and_content_upstream_5xx_is_502(self):
        """[case:console.moderation_group_covers.group_covers.renders] [case:console.moderation_group_covers.group_cover_content.renders]"""
        api = self.bff()
        api.group_covers.return_value = bff_error("The service couldn't complete that request.", 500)
        self.assertEqual(self.client.get(reverse("group_covers")).status_code, 502)
        api.group_cover_content.return_value = BinaryAPIResult(False, error="boom", status_code=503)
        response = self.client.get(reverse("group_cover_content", args=[ROOM]))
        self.assertEqual(response.status_code, 502)
        self.assertTrue(response["Content-Type"].startswith("text/plain"))

    def test_decision_authz(self):
        """[case:console.moderation_group_covers.group_cover_decision.authz]"""
        self.assert_action_authz(reverse("group_cover_decision", args=[ROOM]), {"decision": "approved"}, "group_cover_decision",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator",), module=self.module)


class BlogCasesTest(ConsoleCaseTest):
    module = "control_panel.views_blog"

    def test_decision_success(self):
        """[case:console.moderation_blog.blog_decision.performs]"""
        api = self.bff()
        case = uuid4()
        response = self.client.post(reverse("blog_decision", args=[case]), {"version": "3", "decision": "restored", "note": " Context checked "})
        api.blog_decision.assert_called_once_with(str(case), {"expected_version": 3, "decision": "restored", "note": "Context checked"})
        self.assertRedirects(response, reverse("blog_reviews"), fetch_redirect_response=False)
        self.assertIn("Review decision recorded.", flash(response))

    def test_reviews_upstream_5xx_is_502(self):
        """[case:console.moderation_blog.blog_reviews.renders] [case:console.moderation_blog.blog_evidence.renders]"""
        api = self.bff()
        api.blog_reviews.return_value = bff_error("The service couldn't complete that request.", 500)
        response = self.client.get(reverse("blog_reviews"))
        self.assertEqual(response.status_code, 502)
        self.assertContains(response, "couldn&#x27;t complete that request", status_code=502)
        # An unknown queue is never forwarded: the page falls back to the pending queue.
        api.blog_reviews.reset_mock()
        api.blog_reviews.return_value = APIResult(True, {"cases": [], "metrics": {}, "total": 0, "limit": 25, "offset": 0})
        self.assertEqual(self.client.get(reverse("blog_reviews"), {"status": "everything"}).status_code, 200)
        self.assertEqual(api.blog_reviews.call_args.kwargs["status"], "pending")
        api.blog_evidence.return_value = BinaryAPIResult(False, error="boom", status_code=500)
        self.assertEqual(self.client.get(reverse("blog_evidence", args=[uuid4(), uuid4()])).status_code, 502)
        api.blog_evidence.return_value = BinaryAPIResult(False, error="gone", status_code=404)
        self.assertEqual(self.client.get(reverse("blog_evidence", args=[uuid4(), uuid4()])).status_code, 404)

    def test_decision_authz(self):
        """[case:console.moderation_blog.blog_decision.authz]"""
        self.assert_action_authz(reverse("blog_decision", args=[uuid4()]), {"version": "1", "decision": "removed", "note": "Clear reason"},
                                 "blog_decision", refused_roles=("ops_admin", "support"), allowed_roles=("moderator",),
                                 module=self.module)
