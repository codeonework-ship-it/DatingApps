"""CON-05: the sidebar only links to pages the operator's roles can use."""
import re
from unittest.mock import patch

from django.test import SimpleTestCase, TestCase
from django.urls import reverse

from control_panel.operator_access import NAV_ITEMS, can_access_admin_route
from control_panel.services.go_client import APIResult

# Written out by hand (not derived from NAV_ITEMS) so a drift in either the
# Go-rule mirror or the nav map shows up here.
ANALYST_LINKS = {
    "dashboard", "city_pilot", "user_list", "support_dashboard",
    "report_catalog", "analytics_overview", "analytics_funnel", "analytics_retention", "analytics_engagement",
    "analytics_liquidity", "analytics_safety", "analytics_data",
    "business_revenue", "business_subscriptions", "business_conversion", "business_coins",
    "business_referrals", "business_markets", "business_investor_pack", "business_spend",
    "billing_dashboard", "activity_feed", "audit_log", "domain_events", "client_errors",
}
ALL_LINKS = {name for name, _, _ in NAV_ITEMS}


class SidebarRoleFilteringTest(TestCase):
    def _login(self, roles):
        session = self.client.session
        session["operator_access_token"] = "access-token"
        session["operator_refresh_token"] = "refresh-token"
        session["operator_username"] = "operator"
        if roles is not None:
            session["operator_roles"] = roles
        session.save()

    def _sidebar_links(self):
        with patch("control_panel.views.GoBFFClient") as client_cls:
            client_cls.return_value.list_activities.return_value = APIResult(ok=True, data={"activities": []})
            response = self.client.get(reverse("activity_feed"))
        self.assertEqual(response.status_code, 200)
        html = response.content.decode()
        sidebar = html[html.index('<aside class="sidebar'):html.index("</aside>")]
        hrefs = set(re.findall(r'<a href="([^"]+)"[^>]*class="nav-item-link', sidebar))
        by_path = {reverse(name): name for name in ALL_LINKS}
        return {by_path[h] for h in hrefs}, sidebar

    def test_analyst_sees_only_links_go_lets_analysts_read(self):
        self._login(["analyst"])
        links, sidebar = self._sidebar_links()
        self.assertEqual(links, ANALYST_LINKS)
        for hidden in ("Gift Catalog", "Feature Flags", "Ticket queue", "Profile Media", "SOS Alerts"):
            self.assertNotIn(hidden, sidebar)
        # Sections with nothing left in them disappear too.
        self.assertNotIn('<div class="sidebar-section-label">Moderation</div>', sidebar)
        self.assertNotIn('<div class="sidebar-section-label">Safety</div>', sidebar)
        self.assertIn('<div class="sidebar-section-label">Analytics</div>', sidebar)

    def test_admin_sees_every_link(self):
        self._login(["admin"])
        links, _ = self._sidebar_links()
        self.assertEqual(links, ALL_LINKS)

    def test_unknown_roles_show_every_link(self):
        self._login(None)
        links, _ = self._sidebar_links()
        self.assertEqual(links, ALL_LINKS)


class LoginResolvesOperatorRolesTest(TestCase):
    def _post_login(self, client_cls, *, agents, analyst, finance):
        client = client_cls.return_value
        client.login.return_value = APIResult(
            ok=True,
            data={"access_token": "access-token", "refresh_token": "refresh-token", "user_id": "operator-1"},
            status_code=200,
        )
        client.analytics_overview.return_value = APIResult(ok=True, data={"metrics": {}}, status_code=200)
        client.support_agents.return_value = agents
        client.analytics_definitions.return_value = analyst
        client.list_coin_packages.return_value = finance
        return self.client.post(reverse("operator_login"), {"username": "op", "password": "Password123!"})

    @patch("control_panel.views.GoBFFClient")
    def test_analyst_login_stores_analyst_role(self, client_cls):
        denied = APIResult(ok=False, data={}, error="forbidden", status_code=403)
        self._post_login(
            client_cls,
            agents=denied,
            analyst=APIResult(ok=True, data={"definitions": []}, status_code=200),
            finance=denied,
        )
        self.assertEqual(self.client.session["operator_roles"], ["analyst"])

    @patch("control_panel.views.GoBFFClient")
    def test_admin_login_stores_admin_role(self, client_cls):
        agents = APIResult(ok=True, data={"agents": [
            {"id": "someone-else", "roles": ["support"]},
            {"id": "operator-1", "roles": ["admin"]},
        ]}, status_code=200)
        self._post_login(client_cls, agents=agents, analyst=None, finance=None)
        self.assertEqual(self.client.session["operator_roles"], ["admin"])
        client_cls.return_value.analytics_definitions.assert_not_called()

    @patch("control_panel.views.GoBFFClient")
    def test_unclear_answer_leaves_roles_unknown(self, client_cls):
        outage = APIResult(ok=False, data={}, error="unavailable", status_code=503)
        self._post_login(client_cls, agents=outage, analyst=outage, finance=outage)
        self.assertIn("operator_access_token", self.client.session)
        self.assertNotIn("operator_roles", self.client.session)


class GoRouteRuleMirrorTest(SimpleTestCase):
    """Spot checks against principalCanAccessAdminRoute (server_security.go)."""

    def test_rules(self):
        cases = [
            (["analyst"], "GET", "analytics/funnel", True),
            (["analyst"], "POST", "analytics/snapshots/rebuild", False),
            (["analyst"], "GET", "analytics/excluded-accounts", False),
            (["analyst"], "GET", "support/dashboard", True),
            (["analyst"], "GET", "support/tickets", False),
            (["analyst"], "GET", "catalog/gifts", False),
            (["ops_admin"], "GET", "analytics/funnel", False),
            (["ops_admin"], "GET", "analytics/overview", True),
            (["finance"], "GET", "billing/plans", True),
            (["finance"], "POST", "business/marketing-spend", True),
            (["moderator"], "POST", "users/x/ban", True),
            (["moderator"], "DELETE", "users/x", False),
            (["trust_safety"], "POST", "growth/city-pilot/p/stage", True),
            (["support"], "GET", "analytics/overview", True),
            (["support"], "GET", "users", False),
            (["admin"], "DELETE", "anything/at/all", True),
        ]
        for roles, method, path, expected in cases:
            with self.subTest(roles=roles, method=method, path=path):
                self.assertIs(can_access_admin_route(roles, method, path), expected)
