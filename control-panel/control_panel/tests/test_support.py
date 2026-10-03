import json
from unittest.mock import Mock, patch

from django.test import Client, TestCase, override_settings
from django.urls import reverse

from control_panel.services.go_client import APIResult, GoBFFClient, StreamAPIResult

TICKET = '11111111-1111-4111-8111-111111111111'
OTHER = '22222222-2222-4222-8222-222222222222'
MEMBER = '33333333-3333-4333-8333-333333333333'
AGENT = '44444444-4444-4444-8444-444444444444'
ME = '55555555-5555-4555-8555-555555555555'
CANNED = '66666666-6666-4666-8666-666666666666'
ATTACHMENT = '77777777-7777-4777-8777-777777777777'
ISSUE = '88888888-8888-4888-8888-888888888888'


def _ticket(**overrides):
    ticket = {
        'id': TICKET, 'reference': 'CN-2026-000123', 'category': 'technical',
        'subject': '<b>App crashes</b> on chat', 'status': 'open', 'priority': 'high',
        'team': 'technical', 'channel': 'app',
        'requester': {'kind': 'member', 'member_id': MEMBER, 'display_name': 'Priya',
                      'username': 'priya_k', 'email': None},
        'assignee': {'id': AGENT, 'name': 'Asha'}, 'tags': ['android', 'crash'],
        'app_version': '1.4.0', 'platform': 'android', 'os_version': '14', 'device_model': 'Pixel 7',
        'locale': 'en', 'client_error_issue_id': None,
        'first_response_due_at': '2026-10-01T10:00:00Z', 'resolution_due_at': '2026-10-02T09:00:00Z',
        'first_responded_at': None, 'resolved_at': None, 'closed_at': None,
        'sla': {'state': 'breached', 'first_response': 'breached', 'resolution': 'ok'},
        'awaiting_agent': True, 'satisfaction': None, 'merged_into': None, 'message_count': 3,
        'created_at': '2026-10-01T09:00:00Z', 'updated_at': '2026-10-01T09:30:00Z',
        'last_activity_at': '2026-10-01T09:30:00Z',
    }
    ticket.update(overrides)
    return ticket


def _detail(**ticket_overrides):
    return {
        'success': True,
        'ticket': _ticket(**ticket_overrides),
        'messages': [
            {'id': 'm1', 'author_kind': 'member', 'author_id': MEMBER, 'author_name': 'Priya',
             'visibility': 'public', 'body': 'It crashes <script>alert(1)</script>', 'created_at': '2026-10-01T09:00:00Z',
             'canned_response_id': None,
             'attachments': [
                 {'id': ATTACHMENT, 'filename': 'shot.png', 'content_type': 'image/png', 'size_bytes': 2048,
                  'url': f'/v1/admin/support/attachments/{ATTACHMENT}/content'},
                 {'id': OTHER, 'filename': 'log.pdf', 'content_type': 'application/pdf', 'size_bytes': 4096,
                  'url': f'/v1/admin/support/attachments/{OTHER}/content'},
             ]},
            {'id': 'm2', 'author_kind': 'agent', 'author_id': AGENT, 'author_name': 'Asha',
             'visibility': 'internal', 'body': 'Looks like the image cache bug', 'created_at': '2026-10-01T09:20:00Z',
             'attachments': []},
            {'id': 'm3', 'author_kind': 'agent', 'author_id': AGENT, 'author_name': 'Asha',
             'visibility': 'public', 'body': 'Could you update to 1.4.1?', 'created_at': '2026-10-01T09:30:00Z',
             'attachments': []},
        ],
        'events': [
            {'id': 1, 'event_type': 'created', 'actor_kind': 'member', 'actor_name': 'Priya',
             'from_value': None, 'to_value': None, 'created_at': '2026-10-01T09:00:00Z'},
            {'id': 2, 'event_type': 'status_changed', 'actor_kind': 'agent', 'actor_name': 'Asha',
             'from_value': 'new', 'to_value': 'open', 'created_at': '2026-10-01T09:10:00Z'},
            {'id': 3, 'event_type': 'agent_replied', 'actor_kind': 'agent', 'actor_name': 'Asha',
             'from_value': None, 'to_value': None, 'created_at': '2026-10-01T09:30:00Z'},
        ],
        'member_context': {
            'member_id': MEMBER, 'name': 'Priya', 'username': 'priya_k', 'account_status': 'suspended',
            'joined_at': '2025-01-10T00:00:00Z', 'verification_status': 'verified',
            'reports_against_90d': 2, 'open_reports_against': 1, 'reports_filed_90d': 0, 'tickets_total': 4,
        },
        'related_tickets': [{'id': OTHER, 'reference': 'CN-2026-000099', 'subject': 'Old crash',
                             'status': 'resolved', 'created_at': '2026-09-01T09:00:00Z'}],
    }


AGENTS = APIResult(True, {'success': True, 'agents': [
    {'id': AGENT, 'name': 'Asha', 'roles': ['support'], 'open_assigned': 3},
    {'id': ME, 'name': 'Me', 'roles': ['support'], 'open_assigned': 1},
]})
FORBIDDEN = APIResult(False, {'success': False, 'error': 'operator role does not permit this administrative action'},
                      'operator role does not permit this administrative action', 403)


class SupportTestBase(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session['operator_user_id'] = ME
        session.save()


class SupportQueueViewTest(SupportTestBase):
    def test_requires_login_and_csrf(self):
        """[case:console.support.support_ticket_reply.authz] [case:console.support.support_ticket_claim.authz] [case:console.support.support_bulk.authz] [case:console.support.support_ticket_update.authz] [case:console.support.support_canned_save.authz] [case:console.support.support_canned_deactivate.authz]"""
        anonymous = Client()
        for url in (reverse('support_queue'), reverse('support_dashboard'), reverse('support_canned_responses'),
                    reverse('support_ticket_detail', args=[TICKET]), reverse('support_attachment', args=[ATTACHMENT]),
                    reverse('support_export')):
            self.assertEqual(anonymous.get(url).status_code, 302, url)
        self.assertEqual(anonymous.post(reverse('support_ticket_reply', args=[TICKET]), {'body': 'x'}).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        for url in (reverse('support_ticket_reply', args=[TICKET]), reverse('support_ticket_claim', args=[TICKET]),
                    reverse('support_bulk'), reverse('support_ticket_update', args=[TICKET]),
                    reverse('support_canned_save'), reverse('support_canned_deactivate', args=[CANNED])):
            self.assertEqual(client.post(url, {'body': 'hello', 'visibility': 'public'}).status_code, 403, url)

    @patch('control_panel.views_support.GoBFFClient')
    def test_queue_renders_filters_badges_and_controls(self, cls):
        """[case:console.support.support_queue.renders] [case:console.support.support_queue.filters]"""
        api = cls.return_value
        api.list_support_tickets.return_value = APIResult(True, {
            'success': True, 'tickets': [_ticket(), _ticket(id=OTHER, reference='CN-2026-000124', assignee=None,
                                                           sla={'state': 'at_risk'}, awaiting_agent=False,
                                                           status='pending_member', priority='low')],
            'total': 2, 'limit': 50, 'offset': 0, 'counts': {'new': 3, 'open': 5, 'pending_member': 1},
        })
        api.support_agents.return_value = AGENTS
        response = self.client.get(reverse('support_queue'), {
            'status': 'open', 'category': 'technical', 'priority': 'high', 'team': 'technical', 'channel': 'app',
            'assignee': 'unassigned', 'sla': 'breached', 'q': ' CN-2026 ', 'sort': 'updated', 'offset': '50',
        })
        api.list_support_tickets.assert_called_with(
            limit=50, offset=50, status='open', category='technical', priority='high', team='technical',
            channel='app', assignee='unassigned', sla='breached', q='CN-2026', sort='updated')
        self.assertEqual(response.status_code, 200)
        self.assertIn('no-store', response['Cache-Control'])
        self.assertContains(response, '&lt;b&gt;App crashes&lt;/b&gt; on chat')
        self.assertNotContains(response, '<b>App crashes</b>')
        self.assertContains(response, 'SLA breached')
        self.assertContains(response, 'SLA at risk')
        self.assertContains(response, 'Waiting on member')
        self.assertContains(response, 'Awaiting reply', count=1)
        self.assertContains(response, 'is-breached')
        self.assertContains(response, reverse('support_ticket_detail', args=[TICKET]))
        # Claim per row (formaction inside the CSRF-protected bulk form) and bulk controls.
        self.assertContains(response, 'csrfmiddlewaretoken')
        self.assertContains(response, f'formaction="{reverse("support_ticket_claim", args=[TICKET])}"')
        self.assertContains(response, f'formaction="{reverse("support_ticket_claim", args=[OTHER])}"')
        self.assertContains(response, f'action="{reverse("support_bulk")}"')
        self.assertContains(response, 'name="ticket_ids"', count=2)
        # CSV export keeps the filters.
        self.assertContains(response, reverse('support_export') + '?status=open&amp;category=technical')
        self.assertContains(response, 'Previous</a>')
        self.assertContains(response, 'Support agent')

    @patch('control_panel.views_support.GoBFFClient')
    def test_invalid_filters_fall_back_to_defaults(self, cls):
        """[case:console.support.support_queue.renders] [case:console.support.support_queue.filters]"""
        api = cls.return_value
        api.list_support_tickets.return_value = APIResult(True, {'tickets': [], 'total': 0})
        api.support_agents.return_value = AGENTS
        self.client.get(reverse('support_queue'), {'status': 'bogus', 'assignee': 'drop table', 'sort': 'x',
                                                   'team': 'nope', 'offset': '-5'})
        api.list_support_tickets.assert_called_with(
            limit=50, offset=0, status='active', category='', priority='', team='', channel='', assignee='',
            sla='', q='', sort='sla')
        self.client.get(reverse('support_queue'), {'assignee': AGENT})
        self.assertEqual(api.list_support_tickets.call_args.kwargs['assignee'], AGENT)

    @patch('control_panel.views_support.GoBFFClient')
    def test_analyst_sees_no_mutation_controls_and_posts_are_refused(self, cls):
        """[case:console.support.support_queue.renders] [case:console.support.support_ticket_claim.authz] [case:console.support.support_bulk.authz] [case:console.support.support_ticket_reply.authz] [case:console.support.support_ticket_update.authz] [case:console.support.support_canned_save.authz] [case:console.support.support_attachment.renders]"""
        api = cls.return_value
        api.list_support_tickets.return_value = FORBIDDEN
        api.support_agents.return_value = FORBIDDEN
        response = self.client.get(reverse('support_queue'))
        self.assertEqual(response.status_code, 403)
        self.assertContains(response, 'can read the support dashboard only', status_code=403)
        self.assertContains(response, 'Read only', status_code=403)
        self.assertNotContains(response, 'formaction=', status_code=403)
        self.assertNotContains(response, 'name="ticket_ids"', status_code=403)
        # The cached answer refuses mutations before Go is called.
        for url, data in ((reverse('support_ticket_claim', args=[TICKET]), {}),
                          (reverse('support_bulk'), {'ticket_ids': [TICKET], 'action': 'claim'}),
                          (reverse('support_ticket_reply', args=[TICKET]), {'body': 'hi', 'visibility': 'public'}),
                          (reverse('support_ticket_update', args=[TICKET]), {'status': 'resolved', 'orig_status': 'open'}),
                          (reverse('support_canned_save'), {'title': 't', 'body': 'b'})):
            response = self.client.post(url, data, follow=True)
            self.assertContains(response, 'can read the support dashboard only', status_code=response.status_code)
        api.claim_support_ticket.assert_not_called()
        api.bulk_support_tickets.assert_not_called()
        api.reply_support_ticket.assert_not_called()
        api.update_support_ticket.assert_not_called()
        api.create_support_canned_response.assert_not_called()
        # Attachments are refused too.
        self.assertEqual(self.client.get(reverse('support_attachment', args=[ATTACHMENT])).status_code, 403)
        api.support_attachment_content.assert_not_called()

    @patch('control_panel.views_support.GoBFFClient')
    def test_go_403_on_post_is_explained(self, cls):
        """[case:console.support.support_ticket_claim.performs]"""
        cls.return_value.claim_support_ticket.return_value = FORBIDDEN
        cls.return_value.get_support_ticket.return_value = FORBIDDEN
        cls.return_value.support_agents.return_value = FORBIDDEN
        response = self.client.post(reverse('support_ticket_claim', args=[TICKET]), follow=True)
        cls.return_value.claim_support_ticket.assert_called_with(TICKET)
        self.assertContains(response, 'Claim failed: Your operator role can read the support dashboard only',
                            status_code=403)

    @patch('control_panel.views_support.GoBFFClient')
    def test_bulk_actions_validate_and_forward(self, cls):
        """[case:console.support.support_bulk.performs]"""
        api = cls.return_value
        api.list_support_tickets.return_value = APIResult(True, {'tickets': [], 'total': 0})
        api.support_agents.return_value = AGENTS
        url = reverse('support_bulk')
        response = self.client.post(url, {'action': 'claim'}, follow=True)
        self.assertContains(response, 'Select at least one ticket.')
        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'delete'})
        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'status', 'status_value': 'bogus'})
        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'assign', 'assign_value': 'bob'})
        api.bulk_support_tickets.assert_not_called()

        api.bulk_support_tickets.return_value = APIResult(True, {
            'success': True, 'updated': [TICKET], 'failed': [{'id': OTHER, 'error': 'ticket is closed'}]})
        next_url = '/support/?status=open&team=technical'
        response = self.client.post(url, {'ticket_ids': [TICKET, OTHER, 'not-a-uuid'], 'action': 'priority',
                                          'priority_value': 'urgent', 'next': next_url})
        api.bulk_support_tickets.assert_called_with([TICKET, OTHER], 'priority', 'urgent')
        self.assertRedirects(response, next_url, fetch_redirect_response=False)
        response = self.client.get(next_url)
        self.assertContains(response, '1 ticket updated.')
        self.assertContains(response, '1 could not be updated: 22222222: ticket is closed')

        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'claim', 'assign_value': AGENT})
        api.bulk_support_tickets.assert_called_with([TICKET], 'claim', '')
        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'assign', 'assign_value': AGENT})
        api.bulk_support_tickets.assert_called_with([TICKET], 'assign', AGENT)
        self.client.post(url, {'ticket_ids': [TICKET], 'action': 'status', 'status_value': 'on_hold'})
        api.bulk_support_tickets.assert_called_with([TICKET], 'status', 'on_hold')
        # Open redirects are ignored.
        response = self.client.post(url, {'ticket_ids': [TICKET], 'action': 'claim', 'next': 'https://evil.example/'})
        self.assertRedirects(response, reverse('support_queue'), fetch_redirect_response=False)

    @patch('control_panel.views_support.GoBFFClient')
    def test_claim_from_queue_returns_to_filtered_queue(self, cls):
        """[case:console.support.support_ticket_claim.performs]"""
        cls.return_value.claim_support_ticket.return_value = APIResult(True, {'ticket': _ticket(assignee={'id': ME})})
        response = self.client.post(reverse('support_ticket_claim', args=[TICKET]),
                                    {'next': '/support/?assignee=unassigned', 'ticket_ids': [OTHER]})
        cls.return_value.claim_support_ticket.assert_called_once_with(TICKET)
        self.assertRedirects(response, '/support/?assignee=unassigned', fetch_redirect_response=False)
        response = self.client.post(reverse('support_ticket_claim', args=[TICKET]))
        self.assertRedirects(response, reverse('support_ticket_detail', args=[TICKET]), fetch_redirect_response=False)


class SupportExportTest(SupportTestBase):
    @patch('control_panel.views_support.GoBFFClient')
    def test_csv_export_streams_with_filters(self, cls):
        """[case:console.support.support_export.renders]"""
        cls.return_value.export_support_tickets.return_value = StreamAPIResult(
            True, chunks=iter([b'reference,subject\r\n', b'CN-2026-000123,Crash\r\n']), content_type='text/csv; charset=utf-8')
        response = self.client.get(reverse('support_export'), {'status': 'all', 'team': 'trust_safety', 'q': 'crash'})
        cls.return_value.export_support_tickets.assert_called_with(
            status='all', category='', priority='', team='trust_safety', channel='', assignee='', sla='', q='crash',
            sort='sla')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.streaming)
        self.assertEqual(b''.join(response.streaming_content), b'reference,subject\r\nCN-2026-000123,Crash\r\n')
        self.assertEqual(response['Content-Type'], 'text/csv; charset=utf-8')
        self.assertTrue(response['Content-Disposition'].startswith('attachment; filename="support-tickets-'))
        self.assertIn('no-store', response['Cache-Control'])
        self.assertEqual(response['X-Content-Type-Options'], 'nosniff')

    @patch('control_panel.views_support.GoBFFClient')
    def test_export_failure_and_wrong_type(self, cls):
        """[case:console.support.support_export.renders]"""
        cls.return_value.export_support_tickets.return_value = StreamAPIResult(False, error='boom', status_code=500)
        response = self.client.get(reverse('support_export'), {'team': 'billing'})
        self.assertEqual(response.status_code, 302)
        self.assertIn('team=billing', response.url)
        closed = Mock()
        chunks = Mock(close=closed)
        cls.return_value.export_support_tickets.return_value = StreamAPIResult(True, chunks=chunks, content_type='text/html')
        self.assertEqual(self.client.get(reverse('support_export')).status_code, 502)
        closed.assert_called_once()


class SupportTicketDetailTest(SupportTestBase):
    def _api(self, cls, detail=None):
        api = cls.return_value
        api.get_support_ticket.return_value = APIResult(True, detail or _detail())
        api.support_agents.return_value = AGENTS
        api.list_support_canned_responses.return_value = APIResult(True, {'canned_responses': [
            {'id': CANNED, 'title': 'Update the app', 'body': 'Hi {{member_name}}', 'category': 'technical',
             'is_active': True, 'usage_count': 4, 'updated_at': '2026-09-01T00:00:00Z'},
            {'id': OTHER, 'title': 'Old one', 'body': 'x', 'category': None, 'is_active': False},
        ]})
        return api

    @patch('control_panel.views_support.GoBFFClient')
    def test_detail_renders_thread_notes_events_and_context(self, cls):
        """[case:console.support.support_ticket_detail.renders]"""
        api = self._api(cls)
        response = self.client.get(reverse('support_ticket_detail', args=[TICKET]))
        api.get_support_ticket.assert_called_with(TICKET)
        self.assertEqual(response.status_code, 200)
        self.assertIn('no-store', response['Cache-Control'])
        self.assertContains(response, 'CN-2026-000123')
        self.assertContains(response, '&lt;b&gt;App crashes&lt;/b&gt; on chat')
        self.assertContains(response, 'It crashes &lt;script&gt;alert(1)&lt;/script&gt;')
        self.assertNotContains(response, '<script>alert(1)</script>')
        # Internal notes and public replies look different.
        self.assertContains(response, 'support-msg is-internal')
        self.assertContains(response, 'Internal note</span>')
        self.assertContains(response, 'support-msg from-agent')
        self.assertContains(response, 'Public reply</span>')
        # Events timeline, without duplicating messages.
        self.assertContains(response, 'Asha changed the status: New → Open')
        self.assertContains(response, 'Priya raised the ticket')
        self.assertNotContains(response, 'agent replied')
        # SLA, chips and member context.
        self.assertContains(response, 'SLA breached')
        self.assertContains(response, 'High priority')
        self.assertContains(response, 'suspended')
        # A support-only agent cannot read /admin/users, so no profile link.
        self.assertNotContains(response, reverse('user_detail', args=[MEMBER]))
        self.assertContains(response, reverse('support_ticket_detail', args=[OTHER]))
        # Attachments go through the console proxy, never Go URLs.
        self.assertContains(response, reverse('support_attachment', args=[ATTACHMENT]))
        self.assertContains(response, reverse('support_attachment', args=[OTHER]))
        self.assertNotContains(response, '/v1/admin/support/attachments')
        # Controls: reply, canned picker (active only, preview URL), triage, claim, merge.
        self.assertContains(response, f'action="{reverse("support_ticket_reply", args=[TICKET])}"')
        self.assertContains(response, reverse('support_canned_preview', args=[TICKET, CANNED]))
        self.assertNotContains(response, 'Old one')
        self.assertContains(response, f'action="{reverse("support_ticket_update", args=[TICKET])}"')
        self.assertContains(response, f'action="{reverse("support_ticket_claim", args=[TICKET])}"')
        self.assertContains(response, f'action="{reverse("support_ticket_merge", args=[TICKET])}"')
        self.assertContains(response, 'value="android, crash"')
        for status in ('pending_member', 'resolved', 'on_hold', 'open'):
            self.assertContains(response, f'<option value="{status}"')

    @patch('control_panel.views_support.GoBFFClient')
    def test_support_only_role_hides_user_link_and_claim_when_mine(self, cls):
        """[case:console.support.support_ticket_detail.renders]"""
        api = self._api(cls, _detail(assignee={'id': ME, 'name': 'Me'}))
        response = self.client.get(reverse('support_ticket_detail', args=[TICKET]))
        self.assertNotContains(response, reverse('user_detail', args=[MEMBER]))
        self.assertNotContains(response, f'action="{reverse("support_ticket_claim", args=[TICKET])}"')
        api.support_agents.return_value = APIResult(True, {'agents': [{'id': ME, 'name': 'Me', 'roles': ['trust_safety']}]})
        response = self.client.get(reverse('support_ticket_detail', args=[TICKET]))
        self.assertContains(response, reverse('user_detail', args=[MEMBER]))

    @patch('control_panel.views_support.GoBFFClient')
    def test_website_contact_ticket_shows_email_note(self, cls):
        """[case:console.support.support_ticket_detail.renders]"""
        detail = _detail(channel='website', requester={'kind': 'contact', 'member_id': None, 'display_name': 'Visitor Vee',
                                                       'username': None, 'email': 'vee@example.com'})
        detail['member_context'] = None
        self._api(cls, detail)
        response = self.client.get(reverse('support_ticket_detail', args=[TICKET]))
        self.assertContains(response, 'Reply by email — this visitor has no account')
        self.assertContains(response, 'href="mailto:vee@example.com?subject=Re%3A%20%5BCN-2026-000123%5D')
        self.assertContains(response, 'Website visitor')

    @patch('control_panel.views_support.GoBFFClient')
    def test_read_only_detail_hides_controls(self, cls):
        """[case:console.support.support_ticket_detail.renders]"""
        api = self._api(cls)
        api.get_support_ticket.return_value = FORBIDDEN
        api.support_agents.return_value = FORBIDDEN
        response = self.client.get(reverse('support_ticket_detail', args=[TICKET]))
        self.assertEqual(response.status_code, 403)
        self.assertNotContains(response, reverse('support_ticket_reply', args=[TICKET]), status_code=403)
        api.list_support_canned_responses.assert_not_called()

    @patch('control_panel.views_support.GoBFFClient')
    def test_reply_posts_payload(self, cls):
        """[case:console.support.support_ticket_reply.performs]"""
        api = self._api(cls)
        api.reply_support_ticket.return_value = APIResult(True, {'ticket': _ticket(), 'message': {}}, status_code=201)
        url = reverse('support_ticket_reply', args=[TICKET])
        response = self.client.post(url, {'body': '  Please update.\r\nThanks  ', 'visibility': 'public',
                                          'status': 'resolved', 'canned_response_id': CANNED}, follow=True)
        api.reply_support_ticket.assert_called_with(TICKET, body='Please update.\nThanks', visibility='public',
                                                    canned_response_id=CANNED, status='resolved')
        self.assertContains(response, 'Reply sent to the requester. Status set to Resolved.')
        self.client.post(url, {'body': 'Checked logs', 'visibility': 'internal'})
        api.reply_support_ticket.assert_called_with(TICKET, body='Checked logs', visibility='internal',
                                                    canned_response_id='', status='')
        # Empty body is allowed only with a canned response (Go renders it).
        self.client.post(url, {'body': '', 'visibility': 'public', 'canned_response_id': CANNED})
        api.reply_support_ticket.assert_called_with(TICKET, body='', visibility='public',
                                                    canned_response_id=CANNED, status='')

    @patch('control_panel.views_support.GoBFFClient')
    def test_reply_validation_keeps_draft(self, cls):
        """[case:console.support.support_ticket_reply.performs]"""
        api = self._api(cls)
        url = reverse('support_ticket_reply', args=[TICKET])
        for data in ({'body': '', 'visibility': 'public'}, {'body': 'x', 'visibility': 'everyone'},
                     {'body': 'x', 'visibility': 'public', 'status': 'closed'},
                     {'body': 'x', 'visibility': 'public', 'canned_response_id': 'nope'},
                     {'body': 'x' * 5001, 'visibility': 'public'}):
            self.client.post(url, data)
        api.reply_support_ticket.assert_not_called()
        api.reply_support_ticket.return_value = APIResult(False, {}, 'ticket is merged', 409)
        response = self.client.post(url, {'body': 'Keep me', 'visibility': 'internal'}, follow=True)
        self.assertContains(response, 'Reply failed: Reply unavailable: ticket is merged')
        self.assertContains(response, '>Keep me</textarea>')

    @patch('control_panel.views_support.GoBFFClient')
    def test_update_sends_only_changed_fields(self, cls):
        """[case:console.support.support_ticket_update.performs]"""
        api = self._api(cls)
        api.update_support_ticket.return_value = APIResult(True, {'ticket': _ticket()})
        url = reverse('support_ticket_update', args=[TICKET])
        base = {'status': 'open', 'orig_status': 'open', 'priority': 'high', 'orig_priority': 'high',
                'category': 'technical', 'orig_category': 'technical', 'team': 'technical', 'orig_team': 'technical',
                'assignee_id': AGENT, 'orig_assignee_id': AGENT, 'tags': 'android, crash', 'orig_tags': 'android, crash',
                'client_error_issue_id': '', 'orig_client_error_issue_id': ''}
        response = self.client.post(url, base, follow=True)
        self.assertContains(response, 'Nothing changed.')
        api.update_support_ticket.assert_not_called()
        changed = dict(base, status='on_hold', team='trust_safety', assignee_id='', tags='android, crash, vip,  ',
                       client_error_issue_id=ISSUE)
        self.client.post(url, changed)
        api.update_support_ticket.assert_called_with(TICKET, {
            'status': 'on_hold', 'team': 'trust_safety', 'assignee_id': '', 'tags': ['android', 'crash', 'vip'],
            'client_error_issue_id': ISSUE})
        api.update_support_ticket.reset_mock()
        self.client.post(url, dict(base, priority='critical'))
        self.client.post(url, dict(base, client_error_issue_id='abc'))
        self.client.post(url, dict(base, assignee_id='bob'))
        api.update_support_ticket.assert_not_called()

    @patch('control_panel.views_support.GoBFFClient')
    def test_merge_by_reference_and_id(self, cls):
        """[case:console.support.support_ticket_merge.performs]"""
        api = self._api(cls)
        url = reverse('support_ticket_merge', args=[TICKET])
        self.client.post(url, {'into': 'CN-2026-000099'})
        api.merge_support_ticket.assert_not_called()
        api.list_support_tickets.return_value = APIResult(True, {'tickets': [
            _ticket(id=OTHER, reference='CN-2026-000099')]})
        api.merge_support_ticket.return_value = APIResult(True, {'ticket': _ticket(id=OTHER, reference='CN-2026-000099')})
        response = self.client.post(url, {'into': 'cn-2026-000099', 'confirm': 'on'})
        api.list_support_tickets.assert_called_with(limit=10, offset=0, status='all', q='cn-2026-000099')
        api.merge_support_ticket.assert_called_with(TICKET, OTHER)
        self.assertRedirects(response, reverse('support_ticket_detail', args=[OTHER]), fetch_redirect_response=False)
        api.list_support_tickets.reset_mock()
        self.client.post(url, {'into': OTHER, 'confirm': 'on'})
        api.list_support_tickets.assert_not_called()
        api.merge_support_ticket.assert_called_with(TICKET, OTHER)
        api.merge_support_ticket.reset_mock()
        response = self.client.post(url, {'into': TICKET, 'confirm': 'on'}, follow=True)
        self.assertContains(response, 'cannot be merged into itself')
        api.list_support_tickets.return_value = APIResult(True, {'tickets': []})
        response = self.client.post(url, {'into': 'CN-1', 'confirm': 'on'}, follow=True)
        self.assertContains(response, 'No ticket has the reference CN-1.')
        api.merge_support_ticket.assert_not_called()
        api.merge_support_ticket.return_value = APIResult(False, {}, 'requesters differ', 409)
        response = self.client.post(url, {'into': OTHER, 'confirm': 'on'}, follow=True)
        self.assertContains(response, 'Merge refused: requesters differ')

    @patch('control_panel.views_support.GoBFFClient')
    def test_canned_preview_proxy(self, cls):
        """[case:console.support.support_canned_preview.performs]"""
        cls.return_value.preview_support_canned_response.return_value = APIResult(True, {'success': True, 'body': 'Hi Priya'})
        response = self.client.get(reverse('support_canned_preview', args=[TICKET, CANNED]))
        cls.return_value.preview_support_canned_response.assert_called_with(TICKET, CANNED)
        self.assertEqual(json.loads(response.content), {'body': 'Hi Priya'})
        self.assertIn('no-store', response['Cache-Control'])
        cls.return_value.preview_support_canned_response.return_value = APIResult(False, {}, 'not found', 404)
        response = self.client.get(reverse('support_canned_preview', args=[TICKET, CANNED]))
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.content), {'error': 'not found'})


class SupportAttachmentProxyTest(SupportTestBase):
    @patch('control_panel.views_support.GoBFFClient')
    def test_image_inline_pdf_attachment_and_private_headers(self, cls):
        """[case:console.support.support_attachment.renders]"""
        cls.return_value.support_attachment_content.return_value = StreamAPIResult(
            True, chunks=iter([b'\x89PNG', b'rest']), content_type='image/png',
            content_disposition='inline; filename="screen shot.png"', content_length='8')
        response = self.client.get(reverse('support_attachment', args=[ATTACHMENT]))
        cls.return_value.support_attachment_content.assert_called_with(ATTACHMENT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(b''.join(response.streaming_content), b'\x89PNGrest')
        self.assertEqual(response['Content-Type'], 'image/png')
        self.assertEqual(response['Content-Disposition'], 'inline; filename="screen_shot.png"')
        self.assertIn('no-store', response['Cache-Control'])
        self.assertIn('private', response['Cache-Control'])
        self.assertEqual(response['X-Content-Type-Options'], 'nosniff')
        self.assertEqual(response['Content-Length'], '8')

        cls.return_value.support_attachment_content.return_value = StreamAPIResult(
            True, chunks=iter([b'%PDF']), content_type='application/pdf', content_disposition='attachment; filename="../../etc/passwd"')
        response = self.client.get(reverse('support_attachment', args=[ATTACHMENT]))
        self.assertEqual(response['Content-Disposition'], 'attachment; filename="etc_passwd.pdf"')
        self.assertEqual(response['X-Content-Type-Options'], 'nosniff')

        cls.return_value.support_attachment_content.return_value = StreamAPIResult(
            True, chunks=iter([b'%PDF']), content_type='application/pdf')
        response = self.client.get(reverse('support_attachment', args=[ATTACHMENT]))
        self.assertEqual(response['Content-Disposition'], 'attachment; filename="support-attachment-77777777.pdf"')

    @patch('control_panel.views_support.GoBFFClient')
    def test_unsupported_and_missing(self, cls):
        """[case:console.support.support_attachment.renders]"""
        cls.return_value.support_attachment_content.return_value = StreamAPIResult(
            True, chunks=iter([b'<script>']), content_type='text/html')
        self.assertEqual(self.client.get(reverse('support_attachment', args=[ATTACHMENT])).status_code, 415)
        cls.return_value.support_attachment_content.return_value = StreamAPIResult(False, error='nope', status_code=404)
        self.assertEqual(self.client.get(reverse('support_attachment', args=[ATTACHMENT])).status_code, 404)
        cls.return_value.support_attachment_content.return_value = StreamAPIResult(False, error='nope', status_code=403)
        self.assertEqual(self.client.get(reverse('support_attachment', args=[ATTACHMENT])).status_code, 403)


class SupportCannedResponsesTest(SupportTestBase):
    @patch('control_panel.views_support.GoBFFClient')
    def test_list_includes_inactive_and_placeholder_help(self, cls):
        """[case:console.support.support_canned_responses.renders]"""
        api = cls.return_value
        api.support_agents.return_value = AGENTS
        api.list_support_canned_responses.return_value = APIResult(True, {'canned_responses': [
            {'id': CANNED, 'title': 'Update the app', 'body': 'Hi {{member_name}}, ref {{reference}}', 'category': 'technical',
             'is_active': True, 'usage_count': 4, 'updated_at': '2026-09-01T00:00:00Z'},
            {'id': OTHER, 'title': 'Retired <i>reply</i>', 'body': 'x', 'category': None, 'is_active': False, 'usage_count': 0},
        ]})
        response = self.client.get(reverse('support_canned_responses'))
        api.list_support_canned_responses.assert_called_with(include_inactive=True)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Update the app')
        self.assertContains(response, 'Retired &lt;i&gt;reply&lt;/i&gt;')
        self.assertContains(response, 'Inactive</span>')
        for token in ('{{member_name}}', '{{reference}}', '{{agent_name}}'):
            self.assertContains(response, token)
        self.assertContains(response, f'action="{reverse("support_canned_deactivate", args=[CANNED])}"')
        self.assertNotContains(response, f'action="{reverse("support_canned_deactivate", args=[OTHER])}"')

    @patch('control_panel.views_support.GoBFFClient')
    def test_create_edit_deactivate(self, cls):
        """[case:console.support.support_canned_save.performs] [case:console.support.support_canned_deactivate.performs]"""
        api = cls.return_value
        api.support_agents.return_value = AGENTS
        api.list_support_canned_responses.return_value = APIResult(True, {'canned_responses': []})
        api.create_support_canned_response.return_value = APIResult(True, {'canned_response': {}}, status_code=201)
        api.update_support_canned_response.return_value = APIResult(True, {'canned_response': {}})
        api.deactivate_support_canned_response.return_value = APIResult(True, {'success': True})
        save = reverse('support_canned_save')
        response = self.client.post(save, {'title': ' Refund ', 'body': 'Hi {{member_name}}\r\nDone', 'category': ''}, follow=True)
        api.create_support_canned_response.assert_called_with({'title': 'Refund', 'body': 'Hi {{member_name}}\nDone'})
        self.assertContains(response, 'created')
        self.client.post(save, {'title': 'Refund', 'body': 'x', 'category': 'payments_billing'})
        api.create_support_canned_response.assert_called_with({'title': 'Refund', 'body': 'x', 'category': 'payments_billing'})
        self.client.post(save, {'response_id': CANNED, 'title': 'Refund', 'body': 'y', 'category': '', 'is_active': 'on'})
        api.update_support_canned_response.assert_called_with(
            CANNED, {'title': 'Refund', 'body': 'y', 'category': None, 'is_active': True})
        self.client.post(save, {'response_id': CANNED, 'title': 'Refund', 'body': 'y', 'category': 'technical'})
        api.update_support_canned_response.assert_called_with(
            CANNED, {'title': 'Refund', 'body': 'y', 'category': 'technical', 'is_active': False})
        api.create_support_canned_response.reset_mock()
        for data in ({'title': '', 'body': 'x'}, {'title': 'x' * 121, 'body': 'x'}, {'title': 't', 'body': ''},
                     {'title': 't', 'body': 'x', 'category': 'bogus'}, {'response_id': 'nope', 'title': 't', 'body': 'x'}):
            self.client.post(save, data)
        api.create_support_canned_response.assert_not_called()
        response = self.client.post(reverse('support_canned_deactivate', args=[CANNED]), follow=True)
        api.deactivate_support_canned_response.assert_called_with(CANNED)
        self.assertContains(response, 'Canned response deactivated.')


class SupportDashboardTest(SupportTestBase):
    PAYLOAD = {
        'success': True, 'window_days': 30,
        'open_by_status': {'new': 2, 'open': 3, 'pending_member': 1, 'on_hold': 0},
        'open_by_priority': {'low': 0, 'normal': 4, 'high': 1, 'urgent': 1},
        'open_by_team': {'general': 2, 'trust_safety': 1, 'billing': 1, 'privacy': 0, 'technical': 2},
        'breaches': {'first_response': 1, 'resolution': 0, 'at_risk': 2},
        'median_first_response_minutes': 42.5, 'median_resolution_minutes': 610.0,
        'csat': {'average': 4.4, 'responses': 12, 'distribution': {'1': 0, '2': 1, '3': 1, '4': 3, '5': 7}},
        'daily': [{'day': '2026-09-30', 'created': 4, 'resolved': 3}],
        'by_category': [{'category': 'technical', 'open': 2, 'created': 9}],
        'safety': {'open': 1, 'breached': 0, 'at_risk': 1},
    }

    @patch('control_panel.views_support.GoBFFClient')
    def test_dashboard_renders_kpis_charts_and_safety(self, cls):
        """[case:console.support.support_dashboard.renders] [case:console.support.support_dashboard.filters]"""
        api = cls.return_value
        api.support_dashboard.return_value = APIResult(True, self.PAYLOAD)
        api.support_agents.return_value = AGENTS
        response = self.client.get(reverse('support_dashboard'), {'days': '7'})
        api.support_dashboard.assert_called_with(days=7)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Open tickets')
        self.assertContains(response, '>6<')  # open total
        self.assertContains(response, '42m')
        self.assertContains(response, '10h 10m')
        self.assertContains(response, '4.4')
        self.assertContains(response, '12 responses')
        self.assertContains(response, 'Trust &amp; Safety tickets')
        self.assertContains(response, '?team=trust_safety&amp;status=active')
        charts = response.context['charts']
        self.assertEqual(charts['support-daily']['datasets'][0]['data'], [4])
        self.assertEqual(charts['support-csat']['datasets'][0]['data'], [0, 1, 1, 3, 7])
        self.assertContains(response, 'id="support-charts"')
        self.assertContains(response, 'data-support-chart="support-team"')
        self.client.get(reverse('support_dashboard'), {'days': '365'})
        api.support_dashboard.assert_called_with(days=30)

    @patch('control_panel.views_support.GoBFFClient')
    def test_analyst_gets_dashboard_without_queue_links(self, cls):
        """[case:console.support.support_dashboard.renders]"""
        api = cls.return_value
        api.support_dashboard.return_value = APIResult(True, self.PAYLOAD)
        api.support_agents.return_value = FORBIDDEN
        response = self.client.get(reverse('support_dashboard'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Trust &amp; Safety tickets')
        self.assertNotContains(response, 'Open T&amp;S queue')
        self.assertContains(response, 'Read only')

    @patch('control_panel.views_support.GoBFFClient')
    def test_non_support_operator_is_denied(self, cls):
        """[case:console.support.support_dashboard.renders]"""
        cls.return_value.support_dashboard.return_value = FORBIDDEN
        cls.return_value.support_agents.return_value = FORBIDDEN
        response = self.client.get(reverse('support_dashboard'))
        self.assertEqual(response.status_code, 403)
        self.assertContains(response, 'needs a support, trust_safety, moderator, ops_admin, admin or analyst role',
                            status_code=403)
        self.assertNotContains(response, 'id="support-charts"', status_code=403)


@override_settings(GO_API_BASE_URL='http://127.0.0.1:18081/v1')
class SupportGoClientTest(TestCase):
    def _client(self):
        return GoBFFClient(access_token='access-token', refresh_token='r', use_operator_context=False)

    @patch('control_panel.services.go_client.GoBFFClient._request')
    def test_paths_methods_and_payloads(self, request):
        client = self._client()
        client.list_support_tickets(limit=50, offset=100, status='active', team='trust_safety', q='', sort='sla')
        request.assert_called_with('GET', '/admin/support/tickets',
                                   params={'status': 'active', 'team': 'trust_safety', 'sort': 'sla', 'limit': 50, 'offset': 100})
        client.get_support_ticket(TICKET)
        request.assert_called_with('GET', f'/admin/support/tickets/{TICKET}')
        client.update_support_ticket(TICKET, {'tags': ['a'], 'client_error_issue_id': ''})
        request.assert_called_with('PATCH', f'/admin/support/tickets/{TICKET}',
                                   payload={'tags': ['a'], 'client_error_issue_id': ''})
        client.claim_support_ticket(TICKET)
        request.assert_called_with('POST', f'/admin/support/tickets/{TICKET}/claim', payload={})
        client.reply_support_ticket(TICKET, body='', visibility='public', canned_response_id=CANNED)
        request.assert_called_with('POST', f'/admin/support/tickets/{TICKET}/messages',
                                   payload={'body': '', 'visibility': 'public', 'canned_response_id': CANNED})
        client.merge_support_ticket(TICKET, OTHER)
        request.assert_called_with('POST', f'/admin/support/tickets/{TICKET}/merge', payload={'into_ticket_id': OTHER})
        client.bulk_support_tickets([TICKET, OTHER], 'status', 'resolved')
        request.assert_called_with('POST', '/admin/support/tickets/bulk',
                                   payload={'ticket_ids': [TICKET, OTHER], 'action': 'status', 'value': 'resolved'})
        client.preview_support_canned_response(TICKET, CANNED)
        request.assert_called_with('GET', f'/admin/support/tickets/{TICKET}/canned-responses/{CANNED}/preview')
        client.support_dashboard(days=7)
        request.assert_called_with('GET', '/admin/support/dashboard', params={'days': 7})
        client.support_agents()
        request.assert_called_with('GET', '/admin/support/agents')
        client.list_support_canned_responses(include_inactive=True)
        request.assert_called_with('GET', '/admin/support/canned-responses', params={'include_inactive': 1})
        client.list_support_canned_responses()
        request.assert_called_with('GET', '/admin/support/canned-responses', params=None)
        client.create_support_canned_response({'title': 't', 'body': 'b'})
        request.assert_called_with('POST', '/admin/support/canned-responses', payload={'title': 't', 'body': 'b'})
        client.update_support_canned_response(CANNED, {'is_active': True})
        request.assert_called_with('PATCH', f'/admin/support/canned-responses/{CANNED}', payload={'is_active': True})
        client.deactivate_support_canned_response(CANNED)
        request.assert_called_with('DELETE', f'/admin/support/canned-responses/{CANNED}')

    def test_streams_use_operator_token_and_close(self):
        client = self._client()
        upstream = Mock(status_code=200, headers={'Content-Type': 'text/csv', 'Content-Disposition': 'attachment',
                                                  'Content-Length': '10'})
        upstream.iter_content.return_value = iter([b'a,b\n', b'', b'1,2\n'])
        client.session.get = Mock(return_value=upstream)
        result = client.export_support_tickets(status='all', team='billing', q='')
        self.assertTrue(result.ok)
        kwargs = client.session.get.call_args.kwargs
        self.assertEqual(client.session.get.call_args.args[0], 'http://127.0.0.1:18081/v1/admin/support/tickets/export')
        self.assertEqual(kwargs['params'], {'status': 'all', 'team': 'billing'})
        self.assertTrue(kwargs['stream'])
        self.assertEqual(kwargs['headers']['Authorization'], 'Bearer access-token')
        self.assertEqual(b''.join(result.chunks), b'a,b\n1,2\n')
        upstream.close.assert_called()
        self.assertEqual(result.content_type, 'text/csv')

        client.session.get = Mock(return_value=upstream)
        client.support_attachment_content(ATTACHMENT)
        self.assertTrue(client.session.get.call_args.args[0].endswith(f'/admin/support/attachments/{ATTACHMENT}/content'))

    def test_stream_errors_carry_go_message(self):
        client = self._client()
        upstream = Mock(status_code=403)
        upstream.json.return_value = {'success': False, 'error': 'operator role does not permit this administrative action'}
        client.session.get = Mock(return_value=upstream)
        result = client.support_attachment_content(ATTACHMENT)
        self.assertFalse(result.ok)
        self.assertEqual(result.status_code, 403)
        self.assertIn('operator role', result.error)
        upstream.close.assert_called()


class ConsoleDashboardSafetyCardTest(SupportTestBase):
    def test_safety_card_from_support_dashboard(self):
        from control_panel.views_support import dashboard_safety_card
        client = Mock()
        client.support_dashboard.return_value = APIResult(True, {'safety': {'open': 3, 'breached': 1, 'at_risk': 2}})
        card = dashboard_safety_card(client)
        client.support_dashboard.assert_called_with(days=30)
        self.assertEqual((card['count'], card['overdue'], card['at_risk'], card['tone']), (3, 1, 2, 'danger'))
        self.assertEqual(card['href'], '/support/?team=trust_safety&status=active')
        client.support_dashboard.return_value = FORBIDDEN
        self.assertIsNone(dashboard_safety_card(client))

    @patch('control_panel.views.GoBFFClient')
    def test_console_dashboard_shows_safety_ticket_card(self, cls):
        """[case:console.dashboard.dashboard.renders]"""
        api = cls.return_value
        ok = APIResult(True, {})
        for name in ('health', 'readiness', 'list_verifications', 'list_activities', 'analytics_overview', 'list_users',
                     'list_reports', 'list_appeals', 'list_media_moderation', 'list_sos_alerts', 'list_audit_events',
                     'list_domain_events', 'domain_event_metrics', 'analytics_report'):
            getattr(api, name).return_value = ok
        api.support_dashboard.return_value = APIResult(True, {'safety': {'open': 2, 'breached': 0, 'at_risk': 1}})
        response = self.client.get(reverse('dashboard'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Safety tickets')
        self.assertContains(response, 'href="/support/?team=trust_safety&amp;status=active"')
        self.assertContains(response, '1 at risk')
