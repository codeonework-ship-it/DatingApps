from unittest.mock import patch

from django.test import TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult

MEMBER_ID = "54120969-404d-46e4-94b1-cb40fdb96bfb"


class UserDetailStatusTest(TestCase):
    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    def _client(self, client_cls, user_result):
        client = client_cls.return_value
        client.get_user.return_value = user_result
        client.get_wallet_balance.return_value = APIResult(ok=True, data={"wallet": {"coin_balance": 7}})
        client.list_billing_transactions.return_value = APIResult(ok=True, data={"transactions": []})
        return client

    @patch("control_panel.views.GoBFFClient")
    def test_known_member_renders_200(self, client_cls):
        """[case:console.users.user_detail.renders]"""
        self._client(
            client_cls,
            APIResult(ok=True, data={"user": {"id": MEMBER_ID, "name": "Workflow QA", "username": "qaweb1001_m4"}}, status_code=200),
        )
        response = self.client.get(reverse("user_detail", args=[MEMBER_ID]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Workflow QA")

    @patch("control_panel.views.GoBFFClient")
    def test_unknown_member_is_404_not_200(self, client_cls):
        """[case:console.users.user_detail.renders]"""
        # Regression (CON-02): the BFF says 404 but the console answered 200.
        self._client(client_cls, APIResult(ok=False, data={}, error="user not found", status_code=404))
        response = self.client.get(reverse("user_detail", args=["00000000-0000-4000-8000-000000000000"]))
        self.assertEqual(response.status_code, 404)
        self.assertContains(response, "user not found", status_code=404)

    @patch("control_panel.views.GoBFFClient")
    def test_bff_outage_still_renders_page_with_error(self, client_cls):
        """[case:console.users.user_detail.renders]"""
        self._client(client_cls, APIResult(ok=False, data={}, error="upstream timeout", status_code=503))
        response = self.client.get(reverse("user_detail", args=[MEMBER_ID]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "upstream timeout")


class UserDetailTransactionsTest(TestCase):
    """CON-04: the page lists the member's own transactions, not the member's
    share of the latest 20 platform-wide."""

    def setUp(self):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "console_admin"
        session.save()

    def _client(self, client_cls, transactions):
        client = client_cls.return_value
        client.get_user.return_value = APIResult(ok=True, data={"user": {"id": MEMBER_ID, "name": "Workflow QA", "username": "qaweb1001_m4"}}, status_code=200)
        client.get_wallet_balance.return_value = APIResult(ok=True, data={"wallet": {"coin_balance": 7}})
        client.list_billing_transactions.return_value = APIResult(ok=True, data={"transactions": transactions})
        return client

    @patch("control_panel.views.GoBFFClient")
    def test_transactions_are_requested_for_this_member(self, client_cls):
        """[case:console.users.user_detail.renders]"""
        client = self._client(client_cls, [
            {"user_id": MEMBER_ID, "coins": 120, "source": "purchase", "provider": "stripe"},
        ])

        response = self.client.get(reverse("user_detail", args=[MEMBER_ID]))

        self.assertEqual(response.status_code, 200)
        client.list_billing_transactions.assert_called_once_with(limit=20, user_id=MEMBER_ID)
        self.assertEqual(len(response.context["wallet_transactions"]), 1)
        self.assertFalse(response.context["wallet_transactions_partial"])
        self.assertContains(response, "+120")
        self.assertNotContains(response, "may be incomplete")

    @patch("control_panel.views.GoBFFClient")
    def test_other_members_rows_are_never_shown_and_partial_list_is_flagged(self, client_cls):
        """[case:console.users.user_detail.renders]"""
        # A BFF that ignores user_id answers with platform-wide rows.
        self._client(client_cls, [
            {"user_id": "11111111-1111-4111-8111-111111111111", "coins": 999, "source": "purchase"},
            {"user_id": MEMBER_ID, "coins": 50, "source": "admin_grant"},
        ])

        response = self.client.get(reverse("user_detail", args=[MEMBER_ID]))

        self.assertEqual([t["coins"] for t in response.context["wallet_transactions"]], [50])
        self.assertTrue(response.context["wallet_transactions_partial"])
        self.assertNotContains(response, "+999")
        self.assertContains(response, "may be incomplete")


class GoClientTransactionsFilterTest(TestCase):
    def test_user_id_is_sent_to_the_bff(self):
        from unittest.mock import Mock

        from control_panel.services.go_client import GoBFFClient

        client = GoBFFClient(access_token="a", refresh_token="r", use_operator_context=False)
        response = Mock(status_code=200, content=b"{}")
        response.json.return_value = {"transactions": []}
        client.session.request = Mock(return_value=response)

        client.list_billing_transactions(limit=20, user_id=MEMBER_ID)

        kwargs = client.session.request.call_args.kwargs
        self.assertTrue(kwargs["url"].endswith("/admin/billing/transactions"))
        self.assertEqual(kwargs["params"], {"limit": 20, "offset": 0, "user_id": MEMBER_ID})
