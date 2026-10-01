from unittest.mock import patch
from django.test import TestCase, Client
from django.urls import reverse
from control_panel.services.go_client import APIResult


class PhotoThemesViewTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_requires_login_and_csrf(self):
        self.assertEqual(Client().get(reverse('photo_themes')).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('photo_theme_save'), {}).status_code, 403)

    @patch('control_panel.views_photo_themes.GoBFFClient')
    def test_lists_themes_escaped(self, cls):
        cls.return_value.photo_themes.return_value = APIResult(True, {'themes': [
            {'slug': 'perfect-sunday', 'title': '<b>Sunday</b>', 'prompt': 'Show us', 'status': 'active', 'sort_order': 10, 'entry_count': 3}]})
        response = self.client.get(reverse('photo_themes'))
        self.assertContains(response, '&lt;b&gt;Sunday&lt;/b&gt;')
        self.assertContains(response, 'perfect-sunday')
        self.assertIn('no-store', response['Cache-Control'])

    @patch('control_panel.views_photo_themes.GoBFFClient')
    def test_save_validates_before_calling_api(self, cls):
        self.client.post(reverse('photo_theme_save'), {'slug': 'Bad Slug', 'title': 'Ok title', 'prompt': 'A prompt'})
        cls.return_value.save_photo_theme.assert_not_called()
        cls.return_value.save_photo_theme.return_value = APIResult(True, {'themes': []})
        cls.return_value.photo_themes.return_value = APIResult(True, {'themes': []})
        response = self.client.post(reverse('photo_theme_save'), {
            'slug': 'rainy-day', 'title': 'Rainy day', 'prompt': 'Your perfect rainy afternoon', 'status': 'active', 'sort_order': '70'}, follow=True)
        self.assertContains(response, 'Theme saved.')
        cls.return_value.save_photo_theme.assert_called_once_with({
            'slug': 'rainy-day', 'title': 'Rainy day', 'prompt': 'Your perfect rainy afternoon', 'status': 'active', 'sort_order': 70})
