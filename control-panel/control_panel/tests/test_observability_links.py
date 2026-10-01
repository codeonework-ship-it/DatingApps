from django.test import SimpleTestCase, override_settings

from control_panel.observability_links import observability_links

MEMBER = "8f0c1e2a-1111-2222-3333-444455556666"


class ObservabilityLinksTests(SimpleTestCase):
    @override_settings(LOGS_BACKEND="kibana", KIBANA_BASE_URL="http://kibana.local:5601")
    def test_kibana_is_the_local_default(self):
        links = observability_links(MEMBER)
        self.assertEqual(links["logs_backend"], "kibana")
        self.assertTrue(links["logs_url"].startswith("http://kibana.local:5601/app/discover"))
        self.assertIn(MEMBER, links["logs_query"])

    @override_settings(LOGS_BACKEND="loki", GRAFANA_BASE_URL="https://connect.example.com/grafana/")
    def test_loki_links_open_grafana_explore_and_api_dashboard(self):
        links = observability_links(MEMBER)
        self.assertEqual(links["logs_backend"], "loki")
        self.assertTrue(links["logs_url"].startswith("https://connect.example.com/grafana/explore?"))
        self.assertIn("verified-dating-loki", links["logs_url"])
        self.assertIn(MEMBER, links["logs_url"])
        self.assertEqual(links["dashboards_url"], "https://connect.example.com/grafana/d/connect-api-overview")

    @override_settings(LOGS_BACKEND="loki", GRAFANA_BASE_URL="https://connect.example.com/grafana")
    def test_unsafe_focus_ids_are_not_interpolated_into_queries(self):
        links = observability_links('x"} |= "injected')
        self.assertNotIn("injected", links["logs_url"])

    @override_settings(LOGS_BACKEND="loki", GRAFANA_BASE_URL="")
    def test_loki_without_grafana_url_falls_back_to_kibana(self):
        self.assertEqual(observability_links("")["logs_backend"], "kibana")
