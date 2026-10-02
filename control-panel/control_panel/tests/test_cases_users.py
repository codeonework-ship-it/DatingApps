"""Operator console: User Management (catalog feature console.users)."""
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

MEMBER = "54120969-404d-46e4-94b1-cb40fdb96bfb"
PROFILE = {
    "id": MEMBER, "username": "asha_k", "name": "Asha K", "phone_number": "+919800000000", "gender": "female",
    "bio": "Reads on Sundays", "education": "MA", "profession": "Teacher", "income_range": "", "city": "Pune",
    "state": "MH", "country": "India", "drinking": "never", "smoking": "never", "religion": "", "mother_tongue": "",
    "personality_type": "", "height_cm": 162,
}


class UserListAndDetailTest(ConsoleCaseTest):
    def test_user_list_renders_rows_and_escapes_member_text(self):
        """The user list shows each member and their KPIs; member text is escaped. [case:console.users.user_list.renders]"""
        api = self.bff()
        api.list_users.return_value = APIResult(True, {
            "users": [{"id": MEMBER, "username": "asha_k", "name": "<script>x()</script>", "gender": "female",
                       "created_at": "2026-09-01T10:00:00Z"}],
            "total": 1, "kpis": {"active": 1, "suspended": 0, "banned": 0, "verified_pct": 100, "scope": "all_users"},
        })
        response = self.client.get(reverse("user_list"), {"q": "asha", "status": "active", "offset": "50"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "User Management")
        self.assertContains(response, "asha_k")
        self.assertContains(response, "&lt;script&gt;x()&lt;/script&gt;")
        self.assertNotContains(response, "<script>x()</script>")
        self.assertContains(response, reverse("user_detail", args=[MEMBER]))
        api.list_users.assert_called_once_with(limit=50, offset=50, q="asha", status="active", gender="", verified="")

    def test_user_list_bff_failure_shows_banner_not_500(self):
        """A BFF outage renders the page with a readable banner, not a server error. [case:console.users.user_list.renders]"""
        self.bff().list_users.return_value = bff_error("The service couldn't complete that request.")
        response = self.client.get(reverse("user_list"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")
        self.assertContains(response, "couldn&#x27;t complete that request")


class UserCreateTest(ConsoleCaseTest):
    def test_create_forwards_profile_and_confirms(self):
        """Creating a member forwards the form to POST /admin/users and confirms. [case:console.users.user_create.performs]"""
        api = self.bff()
        api.create_user.return_value = APIResult(True, {"id": MEMBER})
        response = self.client.post(reverse("user_create"), {
            "username": "Asha_K", "password": "Password123!", "name": " Asha K ", "gender": "female",
            "city": "Pune", "height_cm": "162"})
        self.assertRedirects(response, reverse("user_list"), fetch_redirect_response=False)
        payload = api.create_user.call_args.args[0]
        self.assertEqual(payload["username"], "asha_k")
        self.assertEqual(payload["name"], "Asha K")
        self.assertEqual(payload["height_cm"], 162)
        self.assertIn("User '@asha_k' created successfully.", flash(response))

    def test_create_failure_keeps_the_form(self):
        """A refused create re-renders the form with the BFF's reason. [case:console.users.user_create.performs]"""
        self.bff().create_user.return_value = bff_error("username already taken", 409)
        response = self.client.post(reverse("user_create"), {"username": "asha", "password": "Password123!", "name": "Asha"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Failed to create user: username already taken")
        self.assertContains(response, 'value="asha"')

    def test_create_authz(self):
        """Anonymous, CSRF-less and wrong-role creates are refused; GET only shows the form. [case:console.users.user_create.authz]"""
        self.assert_action_authz(
            reverse("user_create"), {"username": "asha", "password": "Password123!", "name": "Asha"}, "create_user",
            refused_roles=("trust_safety", "ops_admin", "support", "analyst"), get_status=200)


class UserEditTest(ConsoleCaseTest):
    def test_edit_prefills_and_forwards_changes(self):
        """Editing loads the member, PUTs the changed profile and returns to their page. [case:console.users.user_edit.performs]"""
        api = self.bff()
        api.get_user.return_value = APIResult(True, {"user": PROFILE})
        page = self.client.get(reverse("user_edit", args=[MEMBER]))
        self.assertContains(page, "Edit User")
        self.assertContains(page, 'value="Asha K"')
        api.update_user.return_value = APIResult(True, {"updated": True})
        response = self.client.post(reverse("user_edit", args=[MEMBER]), {**PROFILE, "city": " Mumbai ", "height_cm": "165"})
        self.assertRedirects(response, reverse("user_detail", args=[MEMBER]), fetch_redirect_response=False)
        user_id, payload = api.update_user.call_args.args
        self.assertEqual(user_id, MEMBER)
        self.assertEqual(payload["city"], "Mumbai")
        self.assertEqual(payload["height_cm"], 165)
        self.assertNotIn("username", payload)
        self.assertIn("User updated successfully.", flash(response))

    def test_edit_unknown_member_is_404(self):
        """Regression: an unknown member id showed an empty edit form that would PUT blanks. [case:console.users.user_edit.performs]"""
        api = self.bff()
        api.get_user.return_value = bff_error("user not found", 404)
        self.assertEqual(self.client.get(reverse("user_edit", args=[MEMBER])).status_code, 404)
        api.update_user.assert_not_called()

    def test_edit_hides_form_when_member_cannot_be_read(self):
        """Regression: with the BFF down the form rendered empty, and saving it blanked every profile field. [case:console.users.user_edit.performs]"""
        self.bff().get_user.return_value = bff_error()
        response = self.client.get(reverse("user_edit", args=[MEMBER]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "form is hidden")
        self.assertNotContains(response, "Save Changes")

    def test_edit_requires_a_name(self):
        """A blank name is refused before the BFF is called. [case:console.users.user_edit.performs]"""
        api = self.bff()
        api.get_user.return_value = APIResult(True, {"user": PROFILE})
        response = self.client.post(reverse("user_edit", args=[MEMBER]), {**PROFILE, "name": "  "})
        self.assertContains(response, "Name is required.")
        api.update_user.assert_not_called()

    def test_edit_failure_is_reported(self):
        """A failed update stays on the form with the reason. [case:console.users.user_edit.performs]"""
        api = self.bff()
        api.get_user.return_value = APIResult(True, {"user": PROFILE})
        api.update_user.return_value = bff_error("phone number already in use", 409)
        response = self.client.post(reverse("user_edit", args=[MEMBER]), PROFILE)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Failed to update user: phone number already in use")

    def test_edit_authz(self):
        """Edit is refused for anonymous, CSRF-less and non-admin operators; GET only renders the form. [case:console.users.user_edit.authz]"""
        self.bff().get_user.return_value = APIResult(True, {"user": PROFILE})
        self.assert_action_authz(
            reverse("user_edit", args=[MEMBER]), PROFILE, "update_user",
            refused_roles=("trust_safety", "moderator", "ops_admin"), get_status=200)


class UserLifecycleActionsTest(ConsoleCaseTest):
    def test_delete_schedules_erasure(self):
        """Delete forwards DELETE /admin/users/{id}, explains the grace period and returns to the list. [case:console.users.user_delete.performs]"""
        api = self.bff()
        api.delete_user.return_value = APIResult(True, {"scheduled": True})
        response = self.client.post(reverse("user_delete", args=[MEMBER]))
        api.delete_user.assert_called_once_with(MEMBER)
        self.assertRedirects(response, reverse("user_list"), fetch_redirect_response=False)
        self.assertTrue(any("erasure is scheduled" in m for m in flash(response)))
        api.delete_user.return_value = bff_error("legal hold", 409)
        response = self.client.post(reverse("user_delete", args=[MEMBER]))
        self.assertIn("Failed to delete user: legal hold", flash(response))

    def test_delete_authz(self):
        """[case:console.users.user_delete.authz]"""
        self.assert_action_authz(reverse("user_delete", args=[MEMBER]), {}, "delete_user",
                                 refused_roles=("trust_safety", "ops_admin"))

    def test_suspend_forwards_reason_and_days(self):
        """Suspend needs a reason and forwards it with the day count. [case:console.users.user_suspend.performs]"""
        api = self.bff()
        url = reverse("user_suspend", args=[MEMBER])
        response = self.client.post(url, {"reason": "", "days": "7"})
        self.assertIn("Suspension reason is required.", flash(response))
        api.suspend_user.assert_not_called()
        api.suspend_user.return_value = APIResult(True, {"suspended": True})
        response = self.client.post(url, {"reason": " Harassment ", "days": "7"})
        api.suspend_user.assert_called_once_with(MEMBER, "Harassment", 7)
        self.assertRedirects(response, reverse("user_detail", args=[MEMBER]), fetch_redirect_response=False)
        self.assertIn(f"User {MEMBER} suspended.", flash(response))
        self.client.post(url, {"reason": "Spam", "days": "forever"})
        api.suspend_user.assert_called_with(MEMBER, "Spam", 0)

    def test_suspend_authz(self):
        """[case:console.users.user_suspend.authz]"""
        self.assert_action_authz(reverse("user_suspend", args=[MEMBER]), {"reason": "Spam", "days": "1"}, "suspend_user",
                                 refused_roles=("ops_admin", "support", "analyst"), allowed_roles=("trust_safety", "moderator"))

    def test_unsuspend(self):
        """[case:console.users.user_unsuspend.performs]"""
        api = self.bff()
        api.unsuspend_user.return_value = APIResult(True, {})
        response = self.client.post(reverse("user_unsuspend", args=[MEMBER]))
        api.unsuspend_user.assert_called_once_with(MEMBER)
        self.assertIn(f"User {MEMBER} unsuspended.", flash(response))
        api.unsuspend_user.return_value = bff_error("not suspended", 409)
        self.assertIn("Failed to unsuspend user: not suspended", flash(self.client.post(reverse("user_unsuspend", args=[MEMBER]))))

    def test_unsuspend_authz(self):
        """[case:console.users.user_unsuspend.authz]"""
        self.assert_action_authz(reverse("user_unsuspend", args=[MEMBER]), {}, "unsuspend_user",
                                 refused_roles=("ops_admin", "finance"), allowed_roles=("trust_safety",))

    def test_ban_requires_reason(self):
        """[case:console.users.user_ban.performs]"""
        api = self.bff()
        url = reverse("user_ban", args=[MEMBER])
        self.assertIn("Ban reason is required.", flash(self.client.post(url, {"reason": " "})))
        api.ban_user.assert_not_called()
        api.ban_user.return_value = APIResult(True, {"banned": True})
        response = self.client.post(url, {"reason": "Scam ring"})
        api.ban_user.assert_called_once_with(MEMBER, "Scam ring")
        self.assertRedirects(response, reverse("user_detail", args=[MEMBER]), fetch_redirect_response=False)
        self.assertIn(f"User {MEMBER} banned.", flash(response))
        api.ban_user.return_value = bff_error("operator role does not permit this administrative action", 403)
        self.assertIn("Failed to ban user: operator role does not permit this administrative action",
                      flash(self.client.post(url, {"reason": "Scam ring"})))

    def test_ban_authz(self):
        """[case:console.users.user_ban.authz]"""
        self.assert_action_authz(reverse("user_ban", args=[MEMBER]), {"reason": "Scam"}, "ban_user",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator",))

    def test_unban(self):
        """[case:console.users.user_unban.performs]"""
        api = self.bff()
        api.unban_user.return_value = APIResult(True, {})
        response = self.client.post(reverse("user_unban", args=[MEMBER]))
        api.unban_user.assert_called_once_with(MEMBER)
        self.assertIn(f"User {MEMBER} unbanned.", flash(response))

    def test_unban_authz(self):
        """[case:console.users.user_unban.authz]"""
        self.assert_action_authz(reverse("user_unban", args=[MEMBER]), {}, "unban_user",
                                 refused_roles=("ops_admin", "analyst"), allowed_roles=("trust_safety",))

    def test_force_verify(self):
        """[case:console.users.user_force_verify.performs]"""
        api = self.bff()
        api.force_verify_user.return_value = APIResult(True, {})
        response = self.client.post(reverse("user_force_verify", args=[MEMBER]))
        api.force_verify_user.assert_called_once_with(MEMBER)
        self.assertRedirects(response, reverse("user_detail", args=[MEMBER]), fetch_redirect_response=False)
        self.assertIn(f"User {MEMBER} force-verified.", flash(response))
        api.force_verify_user.return_value = bff_error("already verified", 409)
        self.assertIn("Failed to verify user: already verified", flash(self.client.post(reverse("user_force_verify", args=[MEMBER]))))

    def test_force_verify_authz(self):
        """[case:console.users.user_force_verify.authz]"""
        self.assert_action_authz(reverse("user_force_verify", args=[MEMBER]), {}, "force_verify_user",
                                 refused_roles=("ops_admin", "support"), allowed_roles=("moderator",))


class UserGrantCoinsTest(ConsoleCaseTest):
    def test_grant_uses_the_audited_admin_route(self):
        """Regression: the member page's grant posted {"coins"} to the member-owned /wallet/{id}/coins/top-up
        (403 for any operator, and outside the operator audit); it now uses POST /admin/billing/grant-coins.
        [case:console.users.user_grant_coins.renders]"""
        api = self.bff()
        api.admin_grant_coins.return_value = APIResult(True, {"user_id": MEMBER, "coins": 50, "new_balance": 75, "granted": True})
        response = self.client.post(reverse("user_grant_coins", args=[MEMBER]), {"coins": "50", "reason": " goodwill "})
        api.admin_grant_coins.assert_called_once_with(MEMBER, 50, "goodwill")
        self.assertRedirects(response, reverse("user_detail", args=[MEMBER]), fetch_redirect_response=False)
        self.assertIn(f"Granted 50 coins to {MEMBER}. New balance: 75.", flash(response))

    def test_grant_validates_amount_and_reports_failures(self):
        """[case:console.users.user_grant_coins.renders]"""
        api = self.bff()
        url = reverse("user_grant_coins", args=[MEMBER])
        self.assertIn("Coins must be at least 1.", flash(self.client.post(url, {"coins": "0"})))
        self.assertIn("Coins must be at least 1.", flash(self.client.post(url, {"coins": "lots"})))
        api.admin_grant_coins.assert_not_called()
        api.admin_grant_coins.return_value = bff_error("amount must be 1–100000", 400)
        self.assertIn("Failed to grant coins: amount must be 1–100000", flash(self.client.post(url, {"coins": "500000"})))
        self.assertEqual(self.client.get(url).status_code, 405)

    def test_grant_authz(self):
        """[case:console.users.user_grant_coins.authz]"""
        self.assert_action_authz(reverse("user_grant_coins", args=[MEMBER]), {"coins": "5"}, "admin_grant_coins",
                                 refused_roles=("trust_safety", "finance", "support"), allowed_roles=("ops_admin", "admin"))

    def test_go_client_has_no_member_wallet_mint_call(self):
        """The console client must not call the member-owned top-up route at all. [case:console.users.user_grant_coins.renders]"""
        from control_panel.services.go_client import GoBFFClient
        import inspect

        self.assertNotIn("coins/top-up", inspect.getsource(GoBFFClient))
