"""Operator console: Gift Catalog (catalog feature console.catalog)."""
import os
import tempfile

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

GIFT = {"id": "rose_midnight", "name": "Midnight Rose", "category": "experience", "tier": "epic", "price_coins": 40,
        "icon_emoji": "🌹", "description": "For late talks", "gif_url": "", "sort_order": 10, "is_active": True}
FORM = {"name": "Midnight Rose", "category": "roses", "tier": "rare", "price_coins": "45", "icon_emoji": "🌹",
        "description": "Updated", "gif_url": "https://cdn.example/rose.gif", "sort_order": "5"}


class CatalogListTest(ConsoleCaseTest):
    def test_catalog_renders_gifts_and_forwards_filters(self):
        """The catalog lists gifts with their controls and forwards the filters. [case:console.catalog.catalog_list.renders]"""
        api = self.bff()
        api.list_catalog_gifts.return_value = APIResult(True, {"gifts": [{**GIFT, "name": "<b>Midnight</b>"}], "count": 1, "total": 1})
        response = self.client.get(reverse("catalog_list"), {"category": "roses", "tier": "epic", "active": "yes", "q": "mid"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Gift Catalog")
        self.assertContains(response, "&lt;b&gt;Midnight&lt;/b&gt;")
        self.assertContains(response, reverse("catalog_edit", args=["rose_midnight"]))
        self.assertContains(response, reverse("catalog_toggle", args=["rose_midnight"]))
        self.assertContains(response, reverse("catalog_delete", args=["rose_midnight"]))
        api.list_catalog_gifts.assert_called_once_with(category="roses", tier="epic", active="yes", q="mid",
                                                       sort="sort_order", order="asc", limit=25, offset=0)

    def test_catalog_pages_past_the_first_fifty(self):
        """Go's total (not the page count) drives paging. Regression: Next never showed. [case:console.catalog.catalog_list.paging]"""
        api = self.bff()
        api.list_catalog_gifts.return_value = APIResult(True, {"gifts": [GIFT] * 25, "count": 25, "total": 120, "limit": 25, "offset": 0})
        response = self.client.get(reverse("catalog_list"))
        self.assertEqual(response.context["total"], 120)
        self.assertContains(response, 'href="?page=2"')
        self.assertContains(response, "Page 1 of 5")

    def test_catalog_bff_failure_shows_banner(self):
        """[case:console.catalog.catalog_list.renders]"""
        self.bff().list_catalog_gifts.return_value = bff_error()
        response = self.client.get(reverse("catalog_list"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "alert-glass warning")


class CatalogNewTest(ConsoleCaseTest):
    def test_form_offers_every_tier_and_category(self):
        """Regression: the tier select was empty (view passed `tiers`, template read `rarity_tiers`), and a
        required empty select blocks the browser from submitting the gift form. [case:console.catalog.catalog_new.performs]"""
        self.bff()
        response = self.client.get(reverse("catalog_new"))
        self.assertContains(response, "Add New Gift")
        for tier in ("free", "common", "uncommon", "rare", "epic", "legendary"):
            self.assertContains(response, f'<option value="{tier}"')
        for category in ("roses", "themed_pack", "experience", "exclusive"):
            self.assertContains(response, f'<option value="{category}"')

    def test_create_forwards_gift_and_confirms(self):
        """[case:console.catalog.catalog_new.performs]"""
        api = self.bff()
        api.create_catalog_gift.return_value = APIResult(True, {"id": "rose_new"})
        response = self.client.post(reverse("catalog_new"), {**FORM, "gift_id": " rose_new ", "price_coins": "abc"})
        payload = api.create_catalog_gift.call_args.args[0]
        self.assertEqual(payload["gift_id"], "rose_new")
        self.assertEqual(payload["tier"], "rare")
        self.assertEqual(payload["price_coins"], 0)
        self.assertEqual(payload["sort_order"], 5)
        self.assertTrue(payload["is_active"])
        self.assertRedirects(response, reverse("catalog_list"), fetch_redirect_response=False)
        self.assertIn("Gift 'Midnight Rose' created successfully.", flash(response))
        api.create_catalog_gift.return_value = bff_error("gift id already exists", 409)
        response = self.client.post(reverse("catalog_new"), {**FORM, "gift_id": "rose_new"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Failed to create gift: gift id already exists")

    def test_upload_accepts_images_only(self):
        """Regression: any uploaded file (e.g. .html) was written under /static/ and served from the console's
        origin, at a path relative to the process's working directory. [case:console.catalog.catalog_new.performs]"""
        api = self.bff()
        with tempfile.TemporaryDirectory() as root, override_settings(BASE_DIR=root):
            evil = SimpleUploadedFile("x.html", b"<script>alert(1)</script>", content_type="text/html")
            response = self.client.post(reverse("catalog_new"), {**FORM, "gift_id": "rose_x", "image_file": evil})
            self.assertContains(response, "Upload a PNG, JPEG, GIF or WebP image.")
            api.create_catalog_gift.assert_not_called()
            self.assertFalse(os.path.exists(os.path.join(root, "static", "uploads")))
            png = SimpleUploadedFile("rose.PNG", b"\x89PNG\r\n\x1a\n", content_type="image/png")
            api.create_catalog_gift.return_value = APIResult(True, {})
            self.client.post(reverse("catalog_new"), {**FORM, "gift_id": "rose_x", "image_file": png})
            gif_url = api.create_catalog_gift.call_args.args[0]["gif_url"]
            self.assertRegex(gif_url, r"^/static/uploads/gifts/[0-9a-f]{32}\.png$")
            self.assertTrue(os.path.exists(os.path.join(root, "static", gif_url.removeprefix("/static/"))))

    def test_new_authz(self):
        """[case:console.catalog.catalog_new.authz]"""
        self.assert_action_authz(reverse("catalog_new"), {**FORM, "gift_id": "rose_x"}, "create_catalog_gift",
                                 refused_roles=("finance", "trust_safety", "analyst"), allowed_roles=("ops_admin",),
                                 get_status=200)


class CatalogEditTest(ConsoleCaseTest):
    def test_edit_prefills_and_puts_changes(self):
        """Edit shows the gift (its own category and tier selected) and PUTs the changes. [case:console.catalog.catalog_edit.performs]"""
        api = self.bff()
        api.list_catalog_gifts.return_value = APIResult(True, {"gifts": [GIFT]})
        page = self.client.get(reverse("catalog_edit", args=["rose_midnight"]))
        self.assertContains(page, "Edit Gift")
        self.assertContains(page, '<option value="experience" selected>')
        self.assertContains(page, '<option value="epic" selected>')
        api.update_catalog_gift.return_value = APIResult(True, {"updated": True})
        response = self.client.post(reverse("catalog_edit", args=["rose_midnight"]), FORM)
        gift_id, payload = api.update_catalog_gift.call_args.args
        self.assertEqual(gift_id, "rose_midnight")
        self.assertEqual(payload["price_coins"], 45)
        self.assertEqual(payload["gif_url"], "https://cdn.example/rose.gif")
        self.assertNotIn("gift_id", payload)
        self.assertRedirects(response, reverse("catalog_list"), fetch_redirect_response=False)
        self.assertIn("Gift updated successfully.", flash(response))

    def test_edit_finds_gifts_past_the_first_page(self):
        """Regression: the edit page only searched the first 50 gifts, so later gifts opened as a blank "new" form. [case:console.catalog.catalog_edit.performs]"""
        api = self.bff()
        first = [{**GIFT, "id": f"g{i}"} for i in range(500)]
        api.list_catalog_gifts.side_effect = [APIResult(True, {"gifts": first}), APIResult(True, {"gifts": [GIFT]})]
        response = self.client.get(reverse("catalog_edit", args=["rose_midnight"]))
        self.assertContains(response, "Edit Gift")
        self.assertContains(response, 'value="Midnight Rose"')
        self.assertEqual([c.kwargs for c in api.list_catalog_gifts.call_args_list], [{"limit": 500, "offset": 0}, {"limit": 500, "offset": 500}])

    def test_edit_unknown_gift_is_404(self):
        """Regression: an unknown id showed the "Add New Gift" form posting to that id. [case:console.catalog.catalog_edit.performs]"""
        self.bff().list_catalog_gifts.return_value = APIResult(True, {"gifts": [GIFT]})
        self.assertEqual(self.client.get(reverse("catalog_edit", args=["no_such_gift"])).status_code, 404)

    def test_edit_failure_is_reported(self):
        """[case:console.catalog.catalog_edit.performs]"""
        api = self.bff()
        api.list_catalog_gifts.return_value = APIResult(True, {"gifts": [GIFT]})
        api.update_catalog_gift.return_value = bff_error("price must be positive", 400)
        response = self.client.post(reverse("catalog_edit", args=["rose_midnight"]), FORM)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Failed to update gift: price must be positive")

    def test_edit_authz(self):
        """[case:console.catalog.catalog_edit.authz]"""
        self.bff().list_catalog_gifts.return_value = APIResult(True, {"gifts": [GIFT]})
        self.assert_action_authz(reverse("catalog_edit", args=["rose_midnight"]), FORM, "update_catalog_gift",
                                 refused_roles=("finance", "moderator"), allowed_roles=("ops_admin",), get_status=200)


class CatalogToggleDeleteTest(ConsoleCaseTest):
    def test_toggle_activates_and_deactivates(self):
        """[case:console.catalog.catalog_toggle.performs]"""
        api = self.bff()
        api.toggle_catalog_gift.return_value = APIResult(True, {})
        response = self.client.post(reverse("catalog_toggle", args=["rose_midnight"]), {"is_active": "0"})
        api.toggle_catalog_gift.assert_called_once_with("rose_midnight", is_active=False)
        self.assertRedirects(response, reverse("catalog_list"), fetch_redirect_response=False)
        self.assertIn("Gift rose_midnight deactivated.", flash(response))
        response = self.client.post(reverse("catalog_toggle", args=["rose_midnight"]), {"is_active": "1"})
        api.toggle_catalog_gift.assert_called_with("rose_midnight", is_active=True)
        self.assertIn("Gift rose_midnight activated.", flash(response))
        api.toggle_catalog_gift.return_value = bff_error("gift not found", 404)
        self.assertIn("Failed to toggle gift: gift not found",
                      flash(self.client.post(reverse("catalog_toggle", args=["x"]), {"is_active": "1"})))

    def test_toggle_authz(self):
        """[case:console.catalog.catalog_toggle.authz]"""
        self.assert_action_authz(reverse("catalog_toggle", args=["rose_midnight"]), {"is_active": "1"}, "toggle_catalog_gift",
                                 refused_roles=("finance", "support"), allowed_roles=("ops_admin",))

    def test_delete(self):
        """[case:console.catalog.catalog_delete.performs]"""
        api = self.bff()
        api.delete_catalog_gift.return_value = APIResult(True, {"deleted": True})
        response = self.client.post(reverse("catalog_delete", args=["rose_midnight"]))
        api.delete_catalog_gift.assert_called_once_with("rose_midnight")
        self.assertRedirects(response, reverse("catalog_list"), fetch_redirect_response=False)
        self.assertIn("Gift rose_midnight deleted.", flash(response))
        api.delete_catalog_gift.return_value = bff_error("gift has been sent; deactivate it instead", 409)
        self.assertIn("Failed to delete gift: gift has been sent; deactivate it instead",
                      flash(self.client.post(reverse("catalog_delete", args=["rose_midnight"]))))

    def test_delete_authz(self):
        """[case:console.catalog.catalog_delete.authz]"""
        self.assert_action_authz(reverse("catalog_delete", args=["rose_midnight"]), {}, "delete_catalog_gift",
                                 refused_roles=("finance", "trust_safety", "analyst"), allowed_roles=("ops_admin",))
