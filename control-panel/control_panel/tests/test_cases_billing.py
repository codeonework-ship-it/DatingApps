"""Operator console: Billing (catalog feature console.billing)."""
from django.urls import reverse

from control_panel.services.go_client import APIResult
from control_panel.tests.case_support import ConsoleCaseTest, bff_error, flash

MEMBER = "11111111-4111-8111-1111-111111111111"
PACKAGE = {"id": "pkg-starter", "label": "Starter", "coin_amount": 100, "price_usd": 1.99, "bonus_percent": 0,
           "sort_order": 1, "is_active": True, "description": "First top-up"}
PACKAGE_FORM = {"label": "Starter", "coin_amount": "120", "price_usd": "2.49", "bonus_percent": "20", "sort_order": "2",
                "description": " Bigger "}
RULE_FORM = {"trigger_value": "12", "window_seconds": "600", "response_action": "temporary_lock", "lock_seconds": "3600",
             "severity": "high", "enabled": "on"}


class BillingDashboardTest(ConsoleCaseTest):
    def test_dashboard_renders_plans_packages_and_stats(self):
        """[case:console.billing.billing_dashboard.renders]"""
        api = self.bff()
        api.list_billing_plans.return_value = APIResult(True, {"plans": [{"name": "Connect Plus", "is_active": True, "monthly_price": 9.99}]})
        api.list_coin_packages.return_value = APIResult(True, {"packages": [PACKAGE, {**PACKAGE, "id": "pkg-2", "label": "<b>Mega</b>", "is_active": False}]})
        api.list_billing_transactions.return_value = APIResult(True, {"total": 42, "transactions": []})
        api.get_billing_stats.return_value = APIResult(True, {"total_coins_purchased": 3400, "unique_buyers": 17,
                                                             "revenue_by_currency": [{"currency": "INR", "net": "193.00"}]})
        response = self.client.get(reverse("billing_dashboard"))
        self.assertEqual(response.status_code, 200)
        for text in ("Billing & Monetisation", "Connect Plus", "Starter", "&lt;b&gt;Mega&lt;/b&gt;", "3400", "193.00 INR", "17", "42"):
            self.assertContains(response, text)
        self.assertContains(response, reverse("billing_package_edit", args=["pkg-starter"]))
        self.assertContains(response, reverse("billing_package_toggle", args=["pkg-starter"]))
        self.assertContains(response, f'action="{reverse("billing_grant_coins")}"')
        self.assertNotContains(response, "Revenue stats unavailable")

    def test_stats_outage_is_unavailable_not_zero(self):
        """Regression: with /admin/billing/stats down the tiles showed 0 coins, 0.00 revenue and 0 buyers. [case:console.billing.billing_dashboard.renders]"""
        api = self.bff()
        api.get_billing_stats.return_value = bff_error("The service couldn't complete that request.")
        api.list_billing_plans.return_value = bff_error("plans unavailable", 503)
        response = self.client.get(reverse("billing_dashboard"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Revenue stats unavailable")
        self.assertContains(response, "plans unavailable")
        self.assertNotContains(response, "0.00")


class CoinPackagesTest(ConsoleCaseTest):
    def test_toggle(self):
        """[case:console.billing.billing_package_toggle.performs]"""
        api = self.bff()
        response = self.client.post(reverse("billing_package_toggle", args=["pkg-starter"]), {"is_active": "0"})
        api.toggle_coin_package.assert_called_once_with("pkg-starter", is_active=False)
        self.assertRedirects(response, reverse("billing_dashboard"), fetch_redirect_response=False)
        self.assertIn("Coin package deactivated.", flash(response))
        self.assertIn("Coin package activated.", flash(self.client.post(reverse("billing_package_toggle", args=["pkg-starter"]), {"is_active": "1"})))
        api.toggle_coin_package.return_value = bff_error("package not found", 404)
        self.assertIn("Failed to toggle package: package not found",
                      flash(self.client.post(reverse("billing_package_toggle", args=["x"]), {"is_active": "1"})))

    def test_toggle_authz(self):
        """[case:console.billing.billing_package_toggle.authz]"""
        self.assert_action_authz(reverse("billing_package_toggle", args=["pkg-starter"]), {"is_active": "1"}, "toggle_coin_package",
                                 refused_roles=("finance", "analyst"), allowed_roles=("ops_admin",))

    def test_new_package_validates_and_creates(self):
        """[case:console.billing.billing_package_new.performs]"""
        api = self.bff()
        page = self.client.get(reverse("billing_package_new"))
        self.assertContains(page, "New Coin Package")
        for bad in ({**PACKAGE_FORM, "label": ""}, {**PACKAGE_FORM, "coin_amount": "0"}, {**PACKAGE_FORM, "price_usd": "free"}):
            self.assertContains(self.client.post(reverse("billing_package_new"), bad), "Label, coin amount (≥1), and price (&gt;0) are required.")
        api.create_coin_package.assert_not_called()
        response = self.client.post(reverse("billing_package_new"), PACKAGE_FORM)
        api.create_coin_package.assert_called_once_with({"label": "Starter", "coin_amount": 120, "price_usd": 2.49, "bonus_percent": 20.0,
                                                         "sort_order": 2, "description": "Bigger", "is_active": True})
        self.assertRedirects(response, reverse("billing_dashboard"), fetch_redirect_response=False)
        self.assertIn("Package 'Starter' created.", flash(response))
        api.create_coin_package.return_value = bff_error("label, coin_amount and price_usd are required", 400)
        self.assertContains(self.client.post(reverse("billing_package_new"), PACKAGE_FORM), "Failed to create package:")

    def test_new_package_authz(self):
        """[case:console.billing.billing_package_new.authz]"""
        self.assert_action_authz(reverse("billing_package_new"), PACKAGE_FORM, "create_coin_package",
                                 refused_roles=("finance", "support"), allowed_roles=("ops_admin",), get_status=200)

    def test_edit_package_prefills_and_updates(self):
        """[case:console.billing.billing_package_edit.performs]"""
        api = self.bff()
        api.list_coin_packages.return_value = APIResult(True, {"packages": [PACKAGE]})
        page = self.client.get(reverse("billing_package_edit", args=["pkg-starter"]))
        self.assertContains(page, "Edit Coin Package")
        self.assertContains(page, 'value="Starter"')
        response = self.client.post(reverse("billing_package_edit", args=["pkg-starter"]), PACKAGE_FORM)
        api.update_coin_package.assert_called_once_with("pkg-starter", {"label": "Starter", "coin_amount": 120, "price_usd": 2.49,
                                                                        "bonus_percent": 20.0, "sort_order": 2, "description": "Bigger"})
        self.assertRedirects(response, reverse("billing_dashboard"), fetch_redirect_response=False)
        self.assertIn("Package updated.", flash(response))

    def test_edit_unknown_package_is_404(self):
        """Regression: an unknown package id showed the "New Coin Package" form posting an update to it. [case:console.billing.billing_package_edit.performs]"""
        self.bff().list_coin_packages.return_value = APIResult(True, {"packages": [PACKAGE]})
        self.assertEqual(self.client.get(reverse("billing_package_edit", args=["nope"])).status_code, 404)

    def test_edit_package_authz(self):
        """[case:console.billing.billing_package_edit.authz]"""
        self.bff().list_coin_packages.return_value = APIResult(True, {"packages": [PACKAGE]})
        self.assert_action_authz(reverse("billing_package_edit", args=["pkg-starter"]), PACKAGE_FORM, "update_coin_package",
                                 refused_roles=("finance", "trust_safety"), allowed_roles=("ops_admin",), get_status=200)


class BillingListsTest(ConsoleCaseTest):
    def test_transactions_render_and_page(self):
        """[case:console.billing.billing_transactions.renders]"""
        api = self.bff()
        api.list_billing_transactions.return_value = APIResult(True, {"total": 51, "transactions": [
            {"user_id": MEMBER, "coins": 100, "amount_minor": 19900, "currency": "INR", "provider": "sandbox",
             "source": "purchase", "purchase_ref": "<ref>", "created_at": "2026-09-30T10:00:00Z"}]})
        response = self.client.get(reverse("billing_transactions"), {"page": "3"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Billing Transactions")
        self.assertContains(response, MEMBER)
        self.assertContains(response, "&lt;ref&gt;")
        api.list_billing_transactions.assert_called_once_with(limit=25, offset=50)
        self.assertContains(response, "of <strong>51</strong>")
        api.list_billing_transactions.return_value = bff_error()
        failed = self.client.get(reverse("billing_transactions"), {"page": "nope"})
        self.assertEqual(failed.status_code, 200)
        self.assertContains(failed, "alert-glass warning")
        api.list_billing_transactions.assert_called_with(limit=25, offset=0)

    def test_subscriptions_render_with_filters(self):
        """[case:console.billing.billing_subscriptions.renders]"""
        api = self.bff()
        api.list_subscriptions.return_value = APIResult(True, {"total": 1, "subscriptions": [
            {"user_id": MEMBER, "plan_code": "plus_monthly", "status": "active", "provider": "stripe", "payment_method_last4": "4242"}]})
        response = self.client.get(reverse("billing_subscriptions"), {"status": "active", "plan_code": "plus_monthly"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Subscriptions")
        self.assertContains(response, "plus_monthly")
        api.list_subscriptions.assert_called_once_with(limit=25, offset=0, status="active", plan_code="plus_monthly")
        api.list_subscriptions.return_value = bff_error()
        self.assertContains(self.client.get(reverse("billing_subscriptions")), "alert-glass warning")

    def test_payments_render_with_filters(self):
        """[case:console.billing.billing_payments.renders]"""
        api = self.bff()
        api.list_payments.return_value = APIResult(True, {"total": 1, "payments": [
            {"user_id": MEMBER, "amount_paise": 19900, "currency": "INR", "status": "captured", "provider_payment_id": "pay_123"}]})
        response = self.client.get(reverse("billing_payments"), {"status": "captured"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Payments")
        self.assertContains(response, "captured")
        api.list_payments.assert_called_once_with(limit=25, offset=0, status="captured")
        api.list_payments.return_value = bff_error()
        self.assertContains(self.client.get(reverse("billing_payments")), "alert-glass warning")

    def test_webhook_events_render_with_filters(self):
        """[case:console.billing.billing_webhook_events.renders]"""
        api = self.bff()
        api.list_billing_webhook_events.return_value = APIResult(True, {"total": 1, "events": [
            {"event_id": "evt_1", "event_type": "payment_intent.succeeded", "provider": "stripe", "status": "failed",
             "error": "<b>signature</b>", "received_at": "2026-09-30T10:00:00Z"}]})
        response = self.client.get(reverse("billing_webhook_events"), {"status": "failed", "event_type": "payment_intent.succeeded"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Payment webhooks")
        self.assertContains(response, "evt_1")
        self.assertContains(response, "&lt;b&gt;signature&lt;/b&gt;")
        api.list_billing_webhook_events.assert_called_once_with(limit=25, offset=0, status="failed", event_type="payment_intent.succeeded")
        api.list_billing_webhook_events.return_value = bff_error()
        self.assertContains(self.client.get(reverse("billing_webhook_events")), "alert-glass warning")

    def test_revenue_bff_failure_shows_banner(self):
        """[case:console.billing.billing_revenue_analytics.renders]"""
        self.bff().get_revenue_analytics.return_value = bff_error()
        response = self.client.get(reverse("billing_revenue_analytics"), {"since": "bad", "mode": "evil"})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Revenue Analytics")
        self.assertContains(response, "alert-glass warning")
        self.bff().get_revenue_analytics.assert_called_once_with({})

    def test_reconciliation_bff_failure_shows_banners(self):
        """[case:console.billing.billing_reconciliation.renders]"""
        api = self.bff()
        api.get_billing_reconciliation.return_value = bff_error("reconciliation unavailable", 503)
        api.list_frozen_wallets.return_value = bff_error("wallets unavailable", 503)
        api.list_economy_fraud_cases.return_value = bff_error("cases unavailable", 503)
        response = self.client.get(reverse("billing_reconciliation"), {"since": "2026-09-01", "until": "2026-09-30"})
        self.assertEqual(response.status_code, 200)
        for text in ("Settlement reconciliation", "reconciliation unavailable", "wallets unavailable", "cases unavailable"):
            self.assertContains(response, text)
        api.get_billing_reconciliation.assert_called_once_with(since="2026-09-01", until="2026-09-30")


class BillingGrantCoinsTest(ConsoleCaseTest):
    def test_quick_grant(self):
        """Quick grant forwards to POST /admin/billing/grant-coins and reports the new balance. [case:console.billing.billing_grant_coins.performs]"""
        api = self.bff()
        url = reverse("billing_grant_coins")
        self.assertIn("User ID is required.", flash(self.client.post(url, {"user_id": " ", "amount": "5"})))
        self.assertIn("Coin amount must be at least 1.", flash(self.client.post(url, {"user_id": MEMBER, "amount": "-5"})))
        api.admin_grant_coins.assert_not_called()
        api.admin_grant_coins.return_value = APIResult(True, {"new_balance": 150})
        response = self.client.post(url, {"user_id": f" {MEMBER} ", "amount": "100", "reason": ""})
        api.admin_grant_coins.assert_called_once_with(MEMBER, 100, "admin_grant")
        self.assertRedirects(response, reverse("billing_dashboard"), fetch_redirect_response=False)
        self.assertIn(f"Granted 100 coins to {MEMBER}. New balance: 150.", flash(response))
        api.admin_grant_coins.return_value = bff_error("amount must be 1–100000", 400)
        self.assertIn("Failed to grant coins: amount must be 1–100000", flash(self.client.post(url, {"user_id": MEMBER, "amount": "100001"})))
        self.assertEqual(self.client.get(url).status_code, 405)

    def test_quick_grant_authz(self):
        """[case:console.billing.billing_grant_coins.authz]"""
        self.assert_action_authz(reverse("billing_grant_coins"), {"user_id": MEMBER, "amount": "5"}, "admin_grant_coins",
                                 refused_roles=("finance", "trust_safety", "analyst"), allowed_roles=("ops_admin",))


class BillingIntegrityActionsTest(ConsoleCaseTest):
    def test_gift_reverse_reports_refund(self):
        """[case:console.billing.billing_gift_reverse.performs]"""
        api = self.bff()
        self.assertIn("Gift send ID is required.", flash(self.client.post(reverse("billing_gift_reverse"), {"reason": "Member asked"})))
        api.reverse_gift_send.assert_not_called()
        api.reverse_gift_send.return_value = APIResult(True, {"coins_refunded": 3, "message_retracted": True})
        response = self.client.post(reverse("billing_gift_reverse"), {"gift_send_id": "gift-1", "reason": "Member asked"})
        self.assertIn("Gift gift-1 refunded; 3 coins returned. Message retracted: yes.", flash(response))
        api.reverse_gift_send.return_value = bff_error("gift already reversed", 409)
        self.assertIn("Gift reversal failed: gift already reversed",
                      flash(self.client.post(reverse("billing_gift_reverse"), {"gift_send_id": "gift-1", "reason": "Member asked"})))

    def test_gift_reverse_authz(self):
        """[case:console.billing.billing_gift_reverse.authz]"""
        self.assert_action_authz(reverse("billing_gift_reverse"), {"gift_send_id": "gift-1", "reason": "Member asked"},
                                 "reverse_gift_send", refused_roles=("finance", "support"), allowed_roles=("ops_admin",))

    def test_wallet_review_validates_and_reports(self):
        """[case:console.billing.billing_wallet_review.performs]"""
        api = self.bff()
        url = reverse("billing_wallet_review", args=[MEMBER])
        self.assertIn("Choose a valid wallet review action.", flash(self.client.post(url, {"action": "delete", "note": "x" * 20})))
        self.assertIn("A review note between 10 and 1000 characters is required.",
                      flash(self.client.post(url, {"action": "collect_and_unfreeze", "note": "short"})))
        api.review_frozen_wallet.assert_not_called()
        api.review_frozen_wallet.return_value = APIResult(True, {"debt_collected": 10, "debt_written_off": 30})
        response = self.client.post(url, {"action": "collect_and_unfreeze", "note": "Reviewed the dispute evidence."})
        api.review_frozen_wallet.assert_called_once_with(MEMBER, action="collect_and_unfreeze", note="Reviewed the dispute evidence.")
        self.assertIn("Wallet reviewed: 10 coins collected and 30 written off.", flash(response))

    def test_wallet_review_authz(self):
        """[case:console.billing.billing_wallet_review.authz]"""
        self.assert_action_authz(reverse("billing_wallet_review", args=[MEMBER]),
                                 {"action": "collect_and_unfreeze", "note": "Reviewed the dispute evidence."},
                                 "review_frozen_wallet", refused_roles=("finance", "trust_safety"), allowed_roles=("ops_admin",))

    def test_fraud_case_resolve_validates_and_reports(self):
        """[case:console.billing.billing_fraud_case_resolve.performs]"""
        api = self.bff()
        url = reverse("billing_fraud_case_resolve", args=["case-1"])
        self.client.post(url, {"resolution": "deleted", "note": "x" * 20})
        self.client.post(url, {"resolution": "confirmed", "note": "short"})
        api.resolve_economy_fraud_case.assert_not_called()
        api.resolve_economy_fraud_case.return_value = APIResult(True, {"status": "confirmed"})
        response = self.client.post(url, {"resolution": "confirmed", "note": "Burst matched a known farm."})
        api.resolve_economy_fraud_case.assert_called_once_with("case-1", resolution="confirmed", note="Burst matched a known farm.")
        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        self.assertIn("Fraud case case-1 marked confirmed.", flash(response))

    def test_fraud_case_resolve_authz(self):
        """[case:console.billing.billing_fraud_case_resolve.authz]"""
        self.assert_action_authz(reverse("billing_fraud_case_resolve", args=["case-1"]),
                                 {"resolution": "cleared", "note": "Legitimate after review."}, "resolve_economy_fraud_case",
                                 refused_roles=("finance", "moderator"), allowed_roles=("trust_safety", "ops_admin"))

    def test_fraud_rule_update_forwards_policy(self):
        """[case:console.billing.billing_fraud_rule_update.performs]"""
        api = self.bff()
        url = reverse("billing_fraud_rule_update", args=["gift_burst"])
        self.assertIn("Fraud rule values must be valid numbers.", flash(self.client.post(url, {**RULE_FORM, "trigger_value": "ten"})))
        api.update_economy_fraud_rule.assert_not_called()
        response = self.client.post(url, RULE_FORM)
        api.update_economy_fraud_rule.assert_called_once_with("gift_burst", {
            "trigger_value": 12, "window_seconds": 600, "response_action": "temporary_lock", "lock_seconds": 3600,
            "severity": "high", "enabled": True})
        self.assertRedirects(response, reverse("billing_reconciliation"), fetch_redirect_response=False)
        self.assertIn("Fraud rule gift_burst updated.", flash(response))
        self.client.post(url, {**RULE_FORM, "enabled": ""})
        self.assertFalse(api.update_economy_fraud_rule.call_args.args[1]["enabled"])
        api.update_economy_fraud_rule.return_value = bff_error("lock_seconds must be positive", 400)
        self.assertIn("Fraud rule update failed: lock_seconds must be positive", flash(self.client.post(url, RULE_FORM)))

    def test_fraud_rule_update_authz(self):
        """[case:console.billing.billing_fraud_rule_update.authz]"""
        self.assert_action_authz(reverse("billing_fraud_rule_update", args=["gift_burst"]), RULE_FORM, "update_economy_fraud_rule",
                                 refused_roles=("trust_safety", "finance"), allowed_roles=("ops_admin",))
