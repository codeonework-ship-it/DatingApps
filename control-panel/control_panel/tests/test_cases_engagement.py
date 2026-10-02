"""Operator console: Engagement — daily prompts, nudges, photo themes (catalog feature console.engagement)."""
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

PROMPT_ID = "7d1c0b8e-1111-4c4c-9a9a-000000000001"
# Go's admin_daily_prompts rows carry the text as question_text.
PROMPT = {"id": PROMPT_ID, "question_text": "What made you laugh this week?", "category": "fun", "is_active": False}


class EngagementPromptsTest(ConsoleCaseTest):
    def test_prompts_page_shows_go_question_text(self):
        """Regression: the list read prompt_text, which Go never sends, so every card was an empty quote. [case:console.engagement.engagement_prompts.renders]"""
        self.bff().list_engagement_prompts.return_value = APIResult(True, {"prompts": [
            PROMPT, {"id": "p2", "question_text": "<i>Best trip?</i>", "category": "icebreaker", "is_active": True}]})
        response = self.client.get(reverse("engagement_prompts"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Daily Prompts")
        self.assertContains(response, "What made you laugh this week?")
        self.assertContains(response, "&lt;i&gt;Best trip?&lt;/i&gt;")
        self.assertContains(response, reverse("engagement_prompt_activate", args=[PROMPT_ID]))
        self.assertContains(response, "Today's Prompt")

    def test_prompts_bff_failure_shows_banner(self):
        """[case:console.engagement.engagement_prompts.renders]"""
        self.bff().list_engagement_prompts.return_value = bff_error()
        response = self.client.get(reverse("engagement_prompts"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")

    def test_new_prompt_sends_question_text(self):
        """Regression: create sent prompt_text but Go requires question_text, so every create failed with 400. [case:console.engagement.engagement_prompt_new.performs]"""
        api = self.bff()
        api.create_engagement_prompt.return_value = APIResult(True, {"id": PROMPT_ID})
        response = self.client.post(reverse("engagement_prompt_new"), {"prompt_text": "  What made you laugh?  ", "category": "fun"})
        api.create_engagement_prompt.assert_called_once_with({"question_text": "What made you laugh?", "category": "fun", "is_active": True})
        self.assertRedirects(response, reverse("engagement_prompts"), fetch_redirect_response=False)
        self.assertIn("Prompt created successfully.", flash(response))

    def test_new_prompt_validation_and_failure(self):
        """[case:console.engagement.engagement_prompt_new.performs]"""
        api = self.bff()
        response = self.client.post(reverse("engagement_prompt_new"), {"prompt_text": "   ", "category": "fun"})
        self.assertContains(response, "Prompt text is required.")
        api.create_engagement_prompt.assert_not_called()
        api.create_engagement_prompt.return_value = bff_error("question_text is required", 400)
        response = self.client.post(reverse("engagement_prompt_new"), {"prompt_text": "Hi", "category": "fun"})
        self.assertContains(response, "Failed to create prompt: question_text is required")

    def test_new_prompt_authz(self):
        """[case:console.engagement.engagement_prompt_new.authz]"""
        self.assert_action_authz(reverse("engagement_prompt_new"), {"prompt_text": "Hi", "category": "fun"},
                                 "create_engagement_prompt", refused_roles=("moderator", "finance"),
                                 allowed_roles=("ops_admin",), get_status=200)

    def test_edit_prompt_prefills_and_sends_question_text(self):
        """Regression: edits sent prompt_text, which Go ignores, so text changes were lost while the console said "updated". [case:console.engagement.engagement_prompt_edit.performs]"""
        api = self.bff()
        api.list_engagement_prompts.return_value = APIResult(True, {"prompts": [PROMPT]})
        page = self.client.get(reverse("engagement_prompt_edit", args=[PROMPT_ID]))
        self.assertContains(page, "Edit Prompt")
        self.assertContains(page, "What made you laugh this week?")
        api.update_engagement_prompt.return_value = APIResult(True, {"updated": True})
        response = self.client.post(reverse("engagement_prompt_edit", args=[PROMPT_ID]), {"prompt_text": "New text", "category": "values"})
        api.update_engagement_prompt.assert_called_once_with(PROMPT_ID, {"question_text": "New text", "category": "values"})
        self.assertRedirects(response, reverse("engagement_prompts"), fetch_redirect_response=False)
        self.assertIn("Prompt updated successfully.", flash(response))

    def test_edit_unknown_prompt_is_404_and_blank_text_refused(self):
        """[case:console.engagement.engagement_prompt_edit.performs]"""
        api = self.bff()
        api.list_engagement_prompts.return_value = APIResult(True, {"prompts": [PROMPT]})
        self.assertEqual(self.client.get(reverse("engagement_prompt_edit", args=["nope"])).status_code, 404)
        response = self.client.post(reverse("engagement_prompt_edit", args=[PROMPT_ID]), {"prompt_text": " ", "category": "fun"})
        self.assertContains(response, "Prompt text is required.")
        api.update_engagement_prompt.assert_not_called()
        api.update_engagement_prompt.return_value = bff_error("admin repository unavailable", 503)
        response = self.client.post(reverse("engagement_prompt_edit", args=[PROMPT_ID]), {"prompt_text": "x", "category": "fun"})
        self.assertContains(response, "Failed to update prompt:")

    def test_edit_prompt_authz(self):
        """[case:console.engagement.engagement_prompt_edit.authz]"""
        self.bff().list_engagement_prompts.return_value = APIResult(True, {"prompts": [PROMPT]})
        self.assert_action_authz(reverse("engagement_prompt_edit", args=[PROMPT_ID]), {"prompt_text": "x", "category": "fun"},
                                 "update_engagement_prompt", refused_roles=("moderator", "analyst"),
                                 allowed_roles=("ops_admin",), get_status=200)

    def test_activate_sets_todays_prompt(self):
        """[case:console.engagement.engagement_prompt_activate.performs]"""
        api = self.bff()
        api.activate_engagement_prompt.return_value = APIResult(True, {})
        response = self.client.post(reverse("engagement_prompt_activate", args=[PROMPT_ID]))
        api.activate_engagement_prompt.assert_called_once_with(PROMPT_ID)
        self.assertRedirects(response, reverse("engagement_prompts"), fetch_redirect_response=False)
        self.assertIn("Prompt activated as today's daily prompt.", flash(response))
        api.activate_engagement_prompt.return_value = bff_error("prompt not found", 404)
        self.assertIn("Failed to activate prompt: prompt not found",
                      flash(self.client.post(reverse("engagement_prompt_activate", args=[PROMPT_ID]))))

    def test_activate_authz(self):
        """[case:console.engagement.engagement_prompt_activate.authz]"""
        self.assert_action_authz(reverse("engagement_prompt_activate", args=[PROMPT_ID]), {}, "activate_engagement_prompt",
                                 refused_roles=("moderator", "support"), allowed_roles=("ops_admin",))


class EngagementNudgesTest(ConsoleCaseTest):
    def test_nudges_unavailable_is_not_shown_as_disabled(self):
        """Regression: a BFF failure showed delivery as "Disabled"; it is now "Unknown" with the error. [case:console.engagement.engagement_nudges.renders]"""
        self.bff().list_engagement_nudges.return_value = bff_error("The service couldn't complete that request.")
        response = self.client.get(reverse("engagement_nudges"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Unknown")
        self.assertNotContains(response, ">Disabled<")
        self.assertContains(response, "couldn&#x27;t complete that request")


class PhotoThemesTest(ConsoleCaseTest):
    module = "control_panel.views_photo_themes"

    def test_bff_server_error_is_502_with_banner(self):
        """Regression: a Go 500 was passed through as a console 500; it is a 502 with the banner. [case:console.engagement.photo_themes.renders]"""
        self.bff().photo_themes.return_value = bff_error("The service couldn't complete that request.", 500)
        response = self.client.get(reverse("photo_themes"))
        self.assertEqual(response.status_code, 502)
        self.assertContains(response, "couldn&#x27;t complete that request", status_code=502)
        self.assertNotContains(response, "Traceback", status_code=502)

    def test_save_failure_is_reported(self):
        """[case:console.engagement.photo_theme_save.performs]"""
        api = self.bff()
        api.save_photo_theme.return_value = bff_error("slug is reserved", 409)
        response = self.client.post(reverse("photo_theme_save"), {
            "slug": "rainy-day", "title": "Rainy day", "prompt": "Your rainy afternoon", "status": "archived", "sort_order": "1"})
        self.assertRedirects(response, reverse("photo_themes"), fetch_redirect_response=False)
        self.assertIn("slug is reserved", flash(response))
        self.assertEqual(api.save_photo_theme.call_args.args[0]["status"], "archived")

    def test_save_authz(self):
        """[case:console.engagement.photo_theme_save.authz]"""
        self.assert_action_authz(reverse("photo_theme_save"), {
            "slug": "rainy-day", "title": "Rainy day", "prompt": "Your rainy afternoon", "status": "active", "sort_order": "1"},
            "save_photo_theme", refused_roles=("moderator", "trust_safety"), allowed_roles=("ops_admin",),
            module=self.module)
