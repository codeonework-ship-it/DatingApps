from unittest.mock import patch
from uuid import uuid4
from django.test import TestCase, Client
from django.urls import reverse
from control_panel.services.go_client import APIResult, BinaryAPIResult


class BlogReviewsTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_login_and_csrf(self):
        self.assertEqual(Client().get(reverse('blog_reviews')).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('blog_decision', args=[uuid4()]), {}).status_code, 403)

    @patch('control_panel.views_blog.GoBFFClient')
    def test_evidence_and_appeals_are_escaped(self, cls):
        cls.return_value.blog_reviews.return_value = APIResult(True, {'cases': [{'id': str(uuid4()), 'version': 1, 'snapshot': {'body': '<script>private</script>'}, 'appeal': '<img onerror=alert(1)>', 'photo_ids': [], 'status': 'pending'}], 'metrics': {'pending_reviews': 1}})
        response = self.client.get(reverse('blog_reviews'))
        self.assertContains(response, '&lt;script&gt;private&lt;/script&gt;')
        self.assertContains(response, '&lt;img onerror=alert(1)&gt;')
        self.assertNotContains(response, '<script>private')
        self.assertContains(response, 'Record review decision')
        self.assertIn('no-store', response['Cache-Control'])

    @patch('control_panel.views_blog.GoBFFClient')
    def test_denied_role_does_not_render_decisions(self, cls):
        cls.return_value.blog_reviews.return_value = APIResult(False, {}, 'Access denied', 403)
        response = self.client.get(reverse('blog_reviews'))
        self.assertEqual(response.status_code, 403)
        self.assertNotContains(response, 'Record review decision', status_code=403)

    @patch('control_panel.views_blog.GoBFFClient')
    def test_decision_uses_version_and_backend_error(self, cls):
        cls.return_value.blog_decision.return_value = APIResult(False, {}, 'Case changed; refresh', 409)
        cls.return_value.blog_reviews.return_value = APIResult(True, {'cases': []})
        case = uuid4()
        response = self.client.post(reverse('blog_decision', args=[case]), {'version': '2', 'note': 'A clear reason', 'decision': 'removed'}, follow=True)
        self.assertContains(response, 'Case changed; refresh')
        cls.return_value.blog_decision.assert_called_once_with(str(case), {'expected_version': 2, 'note': 'A clear reason', 'decision': 'removed'})

    @patch('control_panel.views_blog.GoBFFClient')
    def test_invalid_mutation_does_not_reach_api(self, cls):
        self.client.post(reverse('blog_decision', args=[uuid4()]), {'version':'1', 'note':'x', 'decision':'removed'})
        cls.return_value.blog_decision.assert_not_called()
        self.assertEqual(self.client.get(reverse('blog_reviews')+'?offset=-1').status_code,400)

    @patch('control_panel.views_blog.GoBFFClient')
    def test_evidence_never_cached_or_executed(self, cls):
        cls.return_value.blog_evidence.return_value = BinaryAPIResult(True, b'jpeg', 'image/jpeg', '', 200)
        url=reverse('blog_evidence',args=[uuid4(),uuid4()])
        response=self.client.get(url)
        self.assertEqual(response.status_code,200)
        self.assertIn('no-store',response['Cache-Control'])
        cls.return_value.blog_evidence.return_value = BinaryAPIResult(True, b'<script>', 'text/html', '', 200)
        self.assertEqual(self.client.get(url).status_code,415)
