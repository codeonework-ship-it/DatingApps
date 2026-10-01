from unittest.mock import Mock, patch

from django.test import Client, TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult, BinaryAPIResult, GoBFFClient

COVER = '11111111-1111-1111-1111-111111111111'
GROUP = '22222222-2222-2222-2222-222222222222'
OWNER = '33333333-3333-3333-3333-333333333333'


def _item(**overrides):
    item = {
        'cover_id': COVER, 'group_id': GROUP, 'group_name': '<b>Sunday hikers</b>', 'group_kind': 'community',
        'owner_id': OWNER, 'uploaded_by': OWNER, 'status': 'pending', 'reason': 'Needs a human look',
        'provider': 'sandbox', 'mime_type': 'image/jpeg', 'width_px': 1200, 'height_px': 675, 'size_bytes': 204800,
        'uploaded_at': '2026-10-01T09:00:00Z',
        'content_url': f'/v1/admin/moderation/group-covers/{COVER}/content',
    }
    item.update(overrides)
    return item


class GroupCoversViewTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_requires_login_and_csrf(self):
        self.assertEqual(Client().get(reverse('group_covers')).status_code, 302)
        self.assertEqual(Client().get(reverse('group_cover_content', args=[COVER])).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('group_cover_decision', args=[COVER]), {'decision': 'approved'}).status_code, 403)

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_pending_queue_lists_covers_with_actions(self, cls):
        cls.return_value.group_covers.return_value = APIResult(True, {'items': [_item()], 'count': 1, 'status': 'pending'})
        response = self.client.get(reverse('group_covers'))
        cls.return_value.group_covers.assert_called_with(status='pending')
        self.assertEqual(response.status_code, 200)
        self.assertIn('no-store', response['Cache-Control'])
        self.assertContains(response, '&lt;b&gt;Sunday hikers&lt;/b&gt;')
        self.assertContains(response, 'Community')
        self.assertContains(response, OWNER)
        self.assertContains(response, '2026-10-01T09:00:00Z')
        # The image goes through the console proxy, never the Go URL.
        self.assertContains(response, reverse('group_cover_content', args=[COVER]))
        self.assertNotContains(response, '/v1/admin/moderation/group-covers')
        self.assertContains(response, 'Approve</button>')
        self.assertContains(response, 'Reject</button>')
        self.assertContains(response, f'action="{reverse("group_cover_decision", args=[COVER])}"', count=2)
        self.assertContains(response, 'Group Covers')

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_approved_tab_is_read_only_and_unknown_status_falls_back(self, cls):
        cls.return_value.group_covers.return_value = APIResult(True, {'items': [_item(status='approved')]})
        response = self.client.get(reverse('group_covers'), {'status': 'approved'})
        cls.return_value.group_covers.assert_called_with(status='approved')
        self.assertNotContains(response, 'Approve</button>')
        self.assertNotContains(response, 'Reject</button>')
        self.assertContains(response, 'Status: Approved')
        self.client.get(reverse('group_covers'), {'status': 'rejected'})
        cls.return_value.group_covers.assert_called_with(status='pending')

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_api_errors_are_shown(self, cls):
        cls.return_value.group_covers.return_value = APIResult(False, {}, error='forbidden', status_code=403)
        response = self.client.get(reverse('group_covers'))
        self.assertContains(response, 'forbidden', status_code=403)

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_content_proxy_streams_images_only(self, cls):
        cls.return_value.group_cover_content.return_value = BinaryAPIResult(True, b'jpeg-bytes', 'image/jpeg', '', 200)
        response = self.client.get(reverse('group_cover_content', args=[COVER]))
        cls.return_value.group_cover_content.assert_called_with(COVER)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b'jpeg-bytes')
        self.assertEqual(response['Content-Type'], 'image/jpeg')
        self.assertIn('no-store', response['Cache-Control'])
        self.assertEqual(response['X-Content-Type-Options'], 'nosniff')
        cls.return_value.group_cover_content.return_value = BinaryAPIResult(True, b'<script>', 'text/html', '', 200)
        self.assertEqual(self.client.get(reverse('group_cover_content', args=[COVER])).status_code, 415)
        cls.return_value.group_cover_content.return_value = BinaryAPIResult(False, error='Cover unavailable', status_code=404)
        self.assertEqual(self.client.get(reverse('group_cover_content', args=[COVER])).status_code, 404)

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_decisions_validate_before_calling_api(self, cls):
        url = reverse('group_cover_decision', args=[COVER])
        self.client.post(url, {'decision': 'delete', 'reason': 'Not allowed here'})
        self.client.post(url, {'decision': 'rejected', 'reason': ''})
        self.client.post(url, {'decision': 'rejected', 'reason': 'no'})
        self.client.post(url, {'decision': 'rejected', 'reason': 'x' * 201})
        response = self.client.post(url, {'decision': 'rejected', 'reason': 'bad'}, follow=True)
        self.assertContains(response, 'A rejection needs a 5–200 character reason.')
        cls.return_value.group_cover_decision.assert_not_called()

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_approve_and_reject(self, cls):
        cls.return_value.group_covers.return_value = APIResult(True, {'items': []})
        cls.return_value.group_cover_decision.return_value = APIResult(True, {'cover_id': COVER, 'status': 'approved'})
        url = reverse('group_cover_decision', args=[COVER])
        response = self.client.post(url, {'decision': 'approved'}, follow=True)
        cls.return_value.group_cover_decision.assert_called_with(COVER, 'approved', '')
        self.assertContains(response, f'Cover {COVER} approved.')
        response = self.client.post(url, {'decision': 'rejected', 'reason': '  Shows a stranger  '}, follow=True)
        cls.return_value.group_cover_decision.assert_called_with(COVER, 'rejected', 'Shows a stranger')
        self.assertContains(response, 'the group owner has been notified')

    @patch('control_panel.views_group_covers.GoBFFClient')
    def test_decision_failure_is_reported(self, cls):
        cls.return_value.group_covers.return_value = APIResult(True, {'items': []})
        cls.return_value.group_cover_decision.return_value = APIResult(
            False, {}, error='This cover is no longer waiting for review.', status_code=409)
        response = self.client.post(reverse('group_cover_decision', args=[COVER]), {'decision': 'approved'}, follow=True)
        self.assertContains(response, 'Cover decision failed: This cover is no longer waiting for review.')


class GroupCoversClientTest(TestCase):
    @patch('control_panel.services.go_client.GoBFFClient._request')
    def test_client_paths(self, request):
        client = GoBFFClient(access_token='a', refresh_token='r', use_operator_context=False)
        client.group_covers(status='approved')
        request.assert_called_with('GET', '/admin/moderation/group-covers', params={'status': 'approved', 'limit': 50})
        client.group_cover_decision(COVER, 'rejected', 'Shows a stranger')
        request.assert_called_with('POST', f'/admin/moderation/group-covers/{COVER}/decision',
                                   payload={'decision': 'rejected', 'reason': 'Shows a stranger'})

    def test_content_uses_operator_token_server_side(self):
        client = GoBFFClient(access_token='access-token', refresh_token='r', use_operator_context=False)
        client.session.get = Mock(return_value=Mock(status_code=200, content=b'\x89PNG', headers={'Content-Type': 'image/png'}))
        result = client.group_cover_content(COVER)
        self.assertTrue(result.ok)
        self.assertEqual(result.content, b'\x89PNG')
        self.assertEqual(result.content_type, 'image/png')
        self.assertTrue(client.session.get.call_args.args[0].endswith(f'/admin/moderation/group-covers/{COVER}/content'))
        self.assertEqual(client.session.get.call_args.kwargs['headers']['Authorization'], 'Bearer access-token')
