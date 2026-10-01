from unittest.mock import patch
from uuid import uuid4
from django.test import TestCase, Client
from django.urls import reverse
from control_panel.services.go_client import APIResult


class CityPilotViewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_operator_login_required(self):
        self.assertEqual(Client().get(reverse('city_pilot')).status_code, 302)

    @patch('control_panel.views_city_pilot.GoBFFClient')
    def test_empty_pilot_shows_configuration(self, cls):
        cls.return_value.city_pilot.return_value = APIResult(True, {'pilot': None, 'can_edit': True})
        response = self.client.get(reverse('city_pilot'))
        self.assertContains(response, 'Choose the first city')
        self.assertContains(response, 'Save draft')
        self.assertContains(response, 'Targets are hypotheses')

    @patch('control_panel.views_city_pilot.GoBFFClient')
    def test_analyst_has_no_mutation_forms_and_notes_are_escaped(self, cls):
        pilot_id = str(uuid4())
        cls.return_value.city_pilot.return_value = APIResult(True, {'pilot': {'id': pilot_id, 'city': 'Test City', 'status': 'measuring', 'review_note': '<script>bad()</script>'}, 'can_edit': False, 'can_pause': False, 'metrics': [{'label': 'Conversations', 'value': '<5', 'note': 'No content'}]})
        cls.return_value.city_pilot_experiences.return_value = APIResult(True, {'experiences': []})
        response = self.client.get(reverse('city_pilot'))
        self.assertContains(response, '&lt;5')
        self.assertContains(response, '&lt;script&gt;')
        self.assertNotContains(response, 'Apply stage decision')
        self.assertNotContains(response, 'Save draft')
        self.assertNotContains(response, 'Publish free experience')

    @patch('control_panel.views_city_pilot.GoBFFClient')
    def test_save_forwards_utc_dates_and_declared_targets(self, cls):
        cls.return_value.save_city_pilot.return_value = APIResult(True, {})
        response = self.client.post(reverse('city_pilot_save'), {'city': 'Test City', 'country': 'Test Country', 'owner': 'Ops', 'safety_owner': 'Safety', 'starts_at': '2027-01-01T10:00', 'closes_at': '2027-01-15T10:00', 'capacity': '200', 'minimum_pairs': '25', 'conversation_target': '40', 'plan_target': '20', 'date_target': '10'})
        self.assertEqual(response.status_code, 302)
        sent = cls.return_value.save_city_pilot.call_args.args[0]
        self.assertEqual(sent['starts_at'], '2027-01-01T10:00:00+00:00')
        self.assertEqual(sent['minimum_pairs'], 25)

    @patch('control_panel.views_city_pilot.GoBFFClient')
    def test_invalid_dates_do_not_call_api(self, cls):
        self.client.post(reverse('city_pilot_save'), {'starts_at': 'invalid'})
        cls.return_value.save_city_pilot.assert_not_called()

    @patch('control_panel.views_city_pilot.GoBFFClient')
    def test_failed_gate_error_is_displayed(self, cls):
        cls.return_value.transition_city_pilot.return_value = APIResult(False, {}, 'Complete 28-day follow-up', 409)
        cls.return_value.city_pilot.return_value = APIResult(True, {'pilot': None})
        response = self.client.post(reverse('city_pilot_stage', args=[uuid4()]), {'status': 'experiences', 'version': '1', 'note': 'Review evidence', 'safety_ready': 'on'}, follow=True)
        self.assertContains(response, 'Complete 28-day follow-up')

    def test_csrf_required_for_stage_changes(self):
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('city_pilot_stage', args=[uuid4()]), {}).status_code, 403)
