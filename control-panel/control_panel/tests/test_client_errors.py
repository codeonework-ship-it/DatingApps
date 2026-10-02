from unittest.mock import patch

from django.test import Client, TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult, GoBFFClient

ISSUE = '44444444-4444-4444-4444-444444444444'
OCCURRENCE = '55555555-5555-5555-5555-555555555555'
OPERATOR = '66666666-6666-6666-6666-666666666666'


def _issue(**overrides):
    issue = {
        'id': ISSUE, 'fingerprint': 'f00dfeed', 'error_type': 'StateError',
        'title': '<b>Bad state</b>: no element', 'culprit': 'lib/features/chat/chat_screen.dart',
        'status': 'open', 'fatal': True, 'regressed': True,
        'first_seen_at': '2026-09-20T08:00:00Z', 'last_seen_at': '2026-10-01T09:30:00Z',
        'occurrence_count': 128, 'affected_users': 37, 'platforms': ['android', 'ios'],
        'versions': ['1.4.2', '1.4.1', '1.4.0', '1.3.9'], 'resolved_at': None, 'resolved_in_version': None,
        'status_changed_by': None, 'status_note': None,
    }
    issue.update(overrides)
    return issue


def _detail(**issue_overrides):
    return {
        'success': True,
        'issue': _issue(**issue_overrides),
        'versions': [{'app_version': '1.4.2', 'platform': 'android', 'occurrences': 90,
                      'first_seen_at': '2026-09-28T10:00:00Z', 'last_seen_at': '2026-10-01T09:30:00Z'}],
        'occurrences': [{
            'id': OCCURRENCE, 'occurred_at': '2026-10-01T09:30:00Z', 'received_at': '2026-10-01T09:30:02Z',
            'app_version': '1.4.2', 'build_number': '57', 'platform': 'android', 'os_version': '15',
            'device_class': 'phone', 'locale': 'en-IN', 'screen': '/chat/thread',
            'message': 'Bad state: <img src=x onerror=alert(1)>',
            'stack': '#0 ChatScreen.build (<script>alert("x")</script>:12)\n#1 StatelessElement.build',
            'breadcrumbs': [{'at': '2026-10-01T09:29:58Z', 'category': 'navigation', 'message': 'opened <i>thread</i>'}],
            'fatal': True, 'handled': False, 'signed_in': True, 'source': 'flutter_error',
        }],
    }


class ClientErrorsViewTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_requires_login_and_csrf(self):
        """[case:console.client_errors.client_error_status.authz]"""
        self.assertEqual(Client().get(reverse('client_errors')).status_code, 302)
        self.assertEqual(Client().get(reverse('client_error_detail', args=[ISSUE])).status_code, 302)
        self.assertEqual(Client().post(reverse('client_error_status', args=[ISSUE]), {'status': 'resolved'}).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('client_error_status', args=[ISSUE]), {'status': 'resolved'}).status_code, 403)

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_list_renders_issues_summary_and_privacy_note(self, cls):
        """[case:console.client_errors.client_errors.renders]"""
        cls.return_value.list_client_errors.return_value = APIResult(True, {
            'success': True, 'issues': [_issue()], 'total': 1,
            'summary': {'open': 12, 'resolved': 40, 'ignored': 3, 'fatal_open': 5},
        })
        response = self.client.get(reverse('client_errors'))
        cls.return_value.list_client_errors.assert_called_with(
            status='open', platform='', version='', fatal='', sort='last_seen', limit=50, offset=0)
        self.assertEqual(response.status_code, 200)
        self.assertIn('no-store', response['Cache-Control'])
        self.assertContains(response, '&lt;b&gt;Bad state&lt;/b&gt;: no element')
        self.assertNotContains(response, '<b>Bad state</b>')
        self.assertContains(response, 'StateError')
        self.assertContains(response, 'lib/features/chat/chat_screen.dart')
        self.assertContains(response, 'Regressed</span>')
        self.assertContains(response, 'Fatal</span>')
        self.assertContains(response, '128')
        self.assertContains(response, '37')
        self.assertContains(response, 'android, ios')
        self.assertContains(response, '1.4.2, 1.4.1, 1.4.0 +1')
        self.assertContains(response, '2026-09-20T08:00:00Z')
        self.assertContains(response, reverse('client_error_detail', args=[ISSUE]))
        for count in ('12', '40', '5'):
            self.assertContains(response, f'>{count}</div>')
        self.assertContains(response, 'no account id')
        self.assertContains(response, 'kept for 90 days')
        self.assertContains(response, 'opt out in Privacy &amp; Safety')
        self.assertNotContains(response, 'Next <i')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_filters_and_pagination_pass_through(self, cls):
        """[case:console.client_errors.client_errors.renders]"""
        cls.return_value.list_client_errors.return_value = APIResult(True, {
            'issues': [_issue()], 'total': 120, 'summary': {}})
        response = self.client.get(reverse('client_errors'), {
            'status': 'resolved', 'platform': 'ios', 'version': ' 1.4.2 ', 'fatal': 'true',
            'sort': 'users', 'offset': '50'})
        cls.return_value.list_client_errors.assert_called_with(
            status='resolved', platform='ios', version='1.4.2', fatal='true', sort='users', limit=50, offset=50)
        self.assertContains(response, '<option value="resolved" selected>')
        self.assertContains(response, '<option value="ios" selected>')
        self.assertContains(response, 'value="1.4.2"')
        self.assertContains(response, 'href="?status=resolved&amp;platform=ios&amp;version=1.4.2&amp;fatal=true'
                                      '&amp;sort=users&amp;offset=0"')
        self.assertContains(response, 'sort=users&amp;offset=100"')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_unknown_filters_fall_back_to_defaults(self, cls):
        """[case:console.client_errors.client_errors.renders]"""
        cls.return_value.list_client_errors.return_value = APIResult(True, {'issues': [], 'total': 0})
        response = self.client.get(reverse('client_errors'), {
            'status': 'deleted', 'platform': 'symbian', 'fatal': 'maybe', 'sort': 'random', 'offset': '-5'})
        cls.return_value.list_client_errors.assert_called_with(
            status='open', platform='', version='', fatal='', sort='last_seen', limit=50, offset=0)
        self.assertContains(response, 'No issues match these filters.')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_list_api_error_is_shown(self, cls):
        """[case:console.client_errors.client_errors.renders]"""
        cls.return_value.list_client_errors.return_value = APIResult(
            False, {}, error='operator role is not allowed', status_code=403)
        response = self.client.get(reverse('client_errors'))
        self.assertContains(response, 'operator role is not allowed', status_code=403)
        self.assertContains(response, 'Issues could not be loaded.', status_code=403)
        cls.return_value.list_client_errors.return_value = APIResult(False, {}, error='connection refused')
        response = self.client.get(reverse('client_errors'))
        self.assertContains(response, 'connection refused', status_code=502)

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_detail_renders_and_escapes_report_text(self, cls):
        """[case:console.client_errors.client_error_detail.renders]"""
        cls.return_value.get_client_error.return_value = APIResult(True, _detail())
        response = self.client.get(reverse('client_error_detail', args=[ISSUE]))
        cls.return_value.get_client_error.assert_called_with(ISSUE)
        self.assertEqual(response.status_code, 200)
        self.assertIn('no-store', response['Cache-Control'])
        # Report text is escaped, never rendered as markup.
        self.assertContains(response, '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;')
        self.assertNotContains(response, '<script>alert("x")</script>')
        self.assertContains(response, '&lt;img src=x onerror=alert(1)&gt;')
        self.assertNotContains(response, '<img src=x')
        self.assertContains(response, 'opened &lt;i&gt;thread&lt;/i&gt;')
        self.assertContains(response, '&lt;b&gt;Bad state&lt;/b&gt;')
        self.assertContains(response, '<pre')
        self.assertContains(response, 'StatelessElement.build')
        self.assertContains(response, 'navigation')
        for text in ('1.4.2', '(57)', 'phone', 'en-IN', '/chat/thread', 'flutter_error', 'Unhandled', '90'):
            self.assertContains(response, text)
        # An open issue offers Resolve and Ignore, not Reopen.
        action = f'action="{reverse("client_error_status", args=[ISSUE])}"'
        self.assertContains(response, action, count=2)
        self.assertContains(response, 'name="resolved_in_version"')
        self.assertContains(response, 'Resolve</button>')
        self.assertContains(response, 'Ignore</button>')
        self.assertNotContains(response, 'Reopen</button>')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_resolved_issue_offers_reopen_and_shows_resolution(self, cls):
        """[case:console.client_errors.client_error_detail.renders]"""
        cls.return_value.get_client_error.return_value = APIResult(True, _detail(
            status='resolved', regressed=False, resolved_at='2026-10-01T10:00:00Z', resolved_in_version='1.4.3',
            status_changed_by=OPERATOR, status_note='Fixed <u>null</u> list'))
        response = self.client.get(reverse('client_error_detail', args=[ISSUE]))
        self.assertContains(response, 'Reopen</button>')
        self.assertContains(response, 'Ignore</button>')
        self.assertNotContains(response, 'Resolve</button>')
        self.assertContains(response, '1.4.3')
        self.assertContains(response, OPERATOR)
        self.assertContains(response, 'Fixed &lt;u&gt;null&lt;/u&gt; list')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_detail_missing_issue_shows_error(self, cls):
        """[case:console.client_errors.client_error_detail.renders]"""
        cls.return_value.get_client_error.return_value = APIResult(
            False, {'success': False, 'error': 'issue not found'}, error='issue not found', status_code=404)
        response = self.client.get(reverse('client_error_detail', args=[ISSUE]))
        self.assertContains(response, 'issue not found', status_code=404)
        self.assertNotContains(response, 'Resolve</button>', status_code=404)

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_status_post_calls_client_and_redirects(self, cls):
        """[case:console.client_errors.client_error_status.performs]"""
        cls.return_value.get_client_error.return_value = APIResult(True, _detail(status='resolved'))
        cls.return_value.set_client_error_status.return_value = APIResult(True, {'issue': _issue(status='resolved')})
        url = reverse('client_error_status', args=[ISSUE])
        response = self.client.post(url, {'status': 'resolved', 'resolved_in_version': ' 1.4.3+58 ',
                                          'note': '  Fixed by the image cache patch  '})
        self.assertRedirects(response, reverse('client_error_detail', args=[ISSUE]), fetch_redirect_response=False)
        cls.return_value.set_client_error_status.assert_called_with(
            ISSUE, 'resolved', resolved_in_version='1.4.3+58', note='Fixed by the image cache patch')
        response = self.client.post(url, {'status': 'ignored', 'resolved_in_version': '9.9.9'}, follow=True)
        cls.return_value.set_client_error_status.assert_called_with(
            ISSUE, 'ignored', resolved_in_version=None, note=None)
        self.assertContains(response, 'Issue ignored.')
        response = self.client.post(url, {'status': 'open', 'note': 'Seen again'}, follow=True)
        cls.return_value.set_client_error_status.assert_called_with(
            ISSUE, 'open', resolved_in_version=None, note='Seen again')
        self.assertContains(response, 'Issue reopened.')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_status_post_validates_before_calling_api(self, cls):
        """[case:console.client_errors.client_error_status.performs] [case:console.client_errors.client_error_status.authz]"""
        cls.return_value.get_client_error.return_value = APIResult(True, _detail())
        url = reverse('client_error_status', args=[ISSUE])
        self.client.post(url, {'status': 'deleted'})
        self.client.post(url, {'status': 'resolved', 'note': 'x' * 501})
        response = self.client.post(url, {'status': 'resolved', 'resolved_in_version': '1.4 <b>'}, follow=True)
        self.assertContains(response, 'Enter the fixed app version')
        cls.return_value.set_client_error_status.assert_not_called()
        self.assertEqual(self.client.get(url).status_code, 405)

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_status_failures_are_reported(self, cls):
        """[case:console.client_errors.client_error_status.performs]"""
        cls.return_value.get_client_error.return_value = APIResult(True, _detail())
        url = reverse('client_error_status', args=[ISSUE])
        cls.return_value.set_client_error_status.return_value = APIResult(
            False, {}, error='insufficient role', status_code=403)
        response = self.client.post(url, {'status': 'ignored'}, follow=True)
        self.assertContains(response, 'Status change failed: insufficient role')
        self.assertContains(response, 'only admin and ops_admin operators can change client error status')
        cls.return_value.set_client_error_status.return_value = APIResult(
            False, {}, error='issue not found', status_code=404)
        response = self.client.post(url, {'status': 'ignored'}, follow=True)
        self.assertContains(response, 'Status change failed: issue not found')

    @patch('control_panel.views_client_errors.GoBFFClient')
    def test_nav_link_exists(self, cls):
        cls.return_value.list_client_errors.return_value = APIResult(True, {'issues': [], 'total': 0})
        response = self.client.get(reverse('client_errors'))
        self.assertContains(response, f'href="{reverse("client_errors")}" class="nav-item-link active"')
        self.assertContains(response, '<span class="nav-label">Client errors</span></a>')


class ClientErrorsClientTest(TestCase):
    @patch('control_panel.services.go_client.GoBFFClient._request')
    def test_client_paths(self, request):
        client = GoBFFClient(access_token='a', refresh_token='r', use_operator_context=False)
        client.list_client_errors(status='open', platform='', version=' 1.4.2 ', fatal='true', sort='count',
                                  limit=50, offset=100)
        request.assert_called_with('GET', '/admin/client-errors', params={
            'status': 'open', 'version': '1.4.2', 'fatal': 'true', 'sort': 'count', 'limit': 50, 'offset': 100})
        client.list_client_errors(fatal=False, unknown='x')
        request.assert_called_with('GET', '/admin/client-errors', params={'fatal': 'false'})
        client.get_client_error(ISSUE)
        request.assert_called_with('GET', f'/admin/client-errors/{ISSUE}')
        client.set_client_error_status(ISSUE, 'resolved', resolved_in_version='1.4.3', note='Fixed')
        request.assert_called_with('POST', f'/admin/client-errors/{ISSUE}/status',
                                   payload={'status': 'resolved', 'resolved_in_version': '1.4.3', 'note': 'Fixed'})
        client.set_client_error_status(ISSUE, 'ignored')
        request.assert_called_with('POST', f'/admin/client-errors/{ISSUE}/status', payload={'status': 'ignored'})
