from unittest.mock import patch

from django.test import Client, TestCase
from django.urls import reverse

from control_panel.services.go_client import APIResult

ALWAYS_ON = '11111111-1111-1111-1111-111111111111'
HOSTED = '22222222-2222-2222-2222-222222222222'
CLOSED = '33333333-3333-3333-3333-333333333333'
MEMBER = '44444444-4444-4444-4444-444444444444'
OTHER = '55555555-5555-5555-5555-555555555555'


def _rooms_payload():
    return APIResult(True, {
        'rooms': [
            {'id': ALWAYS_ON, 'title': '<b>Late-night talks</b>', 'emoji': '🌙', 'always_on': True, 'category': 'talk',
             'lifecycle_state': 'active', 'here_now': 3, 'participant_count': 9, 'capacity': 200},
            {'id': HOSTED, 'title': 'Sunday book swap', 'always_on': False, 'host_name': 'Asha',
             'lifecycle_state': 'scheduled', 'here_now': 0, 'participant_count': 2, 'capacity': 30,
             'starts_at': '2026-10-02T10:00:00Z', 'ends_at': '2026-10-02T11:00:00Z'},
            {'id': CLOSED, 'title': 'Old hangout', 'always_on': False, 'lifecycle_state': 'closed',
             'here_now': 0, 'participant_count': 0, 'capacity': 30},
        ],
        'recent_actions': [
            {'id': 'a1', 'room_id': ALWAYS_ON, 'moderator_user_id': OTHER, 'target_user_id': MEMBER,
             'action': 'warn_user', 'reason': 'Keep it kind', 'created_at': '2026-10-01T10:00:00Z'},
            {'id': 'a2', 'room_id': HOSTED, 'moderator_user_id': OTHER, 'target_user_id': OTHER,
             'action': 'remove_user', 'reason': 'Spam', 'created_at': '2026-10-01T09:00:00Z'},
        ],
    })


class RoomsViewTest(TestCase):
    def setUp(self):
        session = self.client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()

    def test_requires_login_and_csrf(self):
        """[case:console.moderation_rooms.room_action.authz] [case:console.moderation_rooms.room_role.authz]"""
        self.assertEqual(Client().get(reverse('rooms')).status_code, 302)
        client = Client(enforce_csrf_checks=True)
        session = client.session
        session['operator_access_token'] = 'access'
        session['operator_refresh_token'] = 'refresh'
        session.save()
        self.assertEqual(client.post(reverse('room_action', args=[ALWAYS_ON]), {}).status_code, 403)
        self.assertEqual(client.post(reverse('room_role', args=[ALWAYS_ON]), {}).status_code, 403)

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_lists_and_filters_rooms_escaped(self, cls):
        """[case:console.moderation_rooms.rooms.renders]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        response = self.client.get(reverse('rooms'))
        self.assertContains(response, '&lt;b&gt;Late-night talks&lt;/b&gt;')
        self.assertContains(response, 'Sunday book swap')
        self.assertContains(response, 'Old hangout')
        self.assertContains(response, 'Keep it kind')
        self.assertContains(response, 'Live now (1)')
        self.assertContains(response, 'Conversation Rooms')
        self.assertIn('no-store', response['Cache-Control'])

        # Recent actions name rooms too, so filters are checked on what only
        # the rooms table shows (host line, type column, closed room).
        live = self.client.get(reverse('rooms'), {'filter': 'live'})
        self.assertContains(live, 'Always-on · Talk')
        self.assertNotContains(live, 'Hosted by Asha')
        self.assertNotContains(live, 'Old hangout')
        hosted = self.client.get(reverse('rooms'), {'filter': 'member_hosted'})
        self.assertContains(hosted, 'Hosted by Asha')
        self.assertNotContains(hosted, 'Old hangout')
        self.assertNotContains(hosted, 'Always-on · Talk')
        closed = self.client.get(reverse('rooms'), {'filter': 'closed'})
        self.assertContains(closed, 'Old hangout')
        self.assertNotContains(closed, 'Hosted by Asha')
        always_on = self.client.get(reverse('rooms'), {'filter': 'always_on'})
        self.assertContains(always_on, 'Always-on · Talk')
        self.assertNotContains(always_on, 'Old hangout')
        self.assertNotContains(always_on, 'Hosted by Asha')
        # Unknown filters fall back to all rooms.
        self.assertContains(self.client.get(reverse('rooms'), {'filter': 'nope'}), 'Old hangout')

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_api_errors_are_shown(self, cls):
        """[case:console.moderation_rooms.rooms.renders]"""
        cls.return_value.admin_rooms.return_value = APIResult(False, {}, error='forbidden', status_code=403)
        response = self.client.get(reverse('rooms'))
        self.assertEqual(response.status_code, 403)
        self.assertContains(response, 'forbidden', status_code=403)

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_detail_shows_room_actions_and_people(self, cls):
        """[case:console.moderation_rooms.room_detail.renders]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        response = self.client.get(reverse('room_detail', args=[ALWAYS_ON]))
        self.assertContains(response, 'Keep it kind')
        self.assertNotContains(response, 'Spam')
        self.assertContains(response, MEMBER)
        self.assertContains(response, 'Mute')
        self.assertContains(response, 'Appoint as room moderator')
        missing = self.client.get(reverse('room_detail', args=['66666666-6666-6666-6666-666666666666']))
        self.assertEqual(missing.status_code, 404)

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_detail_lists_members_with_per_member_actions(self, cls):
        """[case:console.moderation_rooms.room_detail.renders]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.room_members.return_value = APIResult(True, {'members': [
            {'user_id': OTHER, 'name': '<i>Ravi</i>', 'role': 'moderator', 'status': 'joined', 'in_room': True,
             'here_now': True, 'joined_at': '2026-10-01T09:00:00Z', 'last_seen_at': '2026-10-01T10:00:00Z'},
            {'user_id': MEMBER, 'name': 'Asha', 'role': 'participant', 'status': 'joined', 'in_room': True,
             'here_now': False, 'joined_at': '2026-10-01T09:30:00Z', 'last_seen_at': '2026-10-01T09:45:00Z',
             'muted_until': '2026-10-01T11:00:00Z'},
            {'user_id': HOSTED, 'name': 'Kiran', 'role': 'participant', 'status': 'removed', 'in_room': False,
             'here_now': False, 'joined_at': '2026-10-01T08:00:00Z', 'removed_until': '2026-10-02T08:00:00Z'},
        ], 'count': 3})
        response = self.client.get(reverse('room_detail', args=[ALWAYS_ON]))
        cls.return_value.room_members.assert_called_with(ALWAYS_ON)
        self.assertContains(response, '<h2 class="h5">Members</h2>', html=False)
        self.assertContains(response, '&lt;i&gt;Ravi&lt;/i&gt;')
        self.assertContains(response, 'Here now')
        self.assertContains(response, 'In the room · muted until 2026-10-01T11:00:00Z')
        self.assertContains(response, 'Removed until 2026-10-02T08:00:00Z')
        # One action form per member, posting to the shared action flow.
        self.assertContains(response, f'name="target_user_id" value="{MEMBER}"')
        self.assertContains(response, f'name="target_user_id" value="{OTHER}"')
        self.assertContains(response, 'Apply', count=3)
        # Unmute only for the muted member; Mute for the other two (each count
        # includes the room-wide action form above the table).
        self.assertContains(response, '<option value="unmute_user">Unmute</option>', count=2, html=False)
        self.assertContains(response, '<option value="mute_user">Mute</option>', count=3, html=False)
        # Role changes: step the moderator down, appoint the participant; none
        # for someone removed.
        self.assertContains(response, 'Step down</button>', count=1)
        self.assertContains(response, 'Appoint moderator</button>', count=1)

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_member_list_failure_keeps_the_page(self, cls):
        """[case:console.moderation_rooms.room_detail.renders]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.room_members.return_value = APIResult(False, {}, error='members unavailable', status_code=503)
        response = self.client.get(reverse('room_detail', args=[ALWAYS_ON]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Could not load members: members unavailable')
        self.assertContains(response, 'No one is in this room right now.')
        self.assertContains(response, 'Keep it kind')

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_member_row_unmute_uses_the_action_flow(self, cls):
        """[case:console.moderation_rooms.room_action.performs]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.room_members.return_value = APIResult(True, {'members': []})
        cls.return_value.admin_room_action.return_value = APIResult(True, {'room': {}, 'moderation_action': {}})
        response = self.client.post(reverse('room_action', args=[ALWAYS_ON]), {
            'action': 'unmute_user', 'target_user_id': MEMBER, 'reason': 'Served their time', 'duration': '10m'}, follow=True)
        cls.return_value.admin_room_action.assert_called_with(ALWAYS_ON, {
            'action': 'unmute_user', 'reason': 'Served their time', 'target_user_id': MEMBER})
        self.assertContains(response, 'Unmute recorded for member ' + MEMBER)

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_actions_validate_before_calling_api(self, cls):
        """[case:console.moderation_rooms.room_action.performs]"""
        url = reverse('room_action', args=[ALWAYS_ON])
        self.client.post(url, {'action': 'warn_user', 'target_user_id': 'not-a-uuid', 'reason': 'Keep it kind'})
        self.client.post(url, {'action': 'warn_user', 'target_user_id': MEMBER, 'reason': 'no'})
        self.client.post(url, {'action': 'ban_user', 'target_user_id': MEMBER, 'reason': 'Keep it kind'})
        self.client.post(url, {'action': 'mute_user', 'target_user_id': MEMBER, 'reason': 'Cool off', 'duration': '1y'})
        cls.return_value.admin_room_action.assert_not_called()

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_warn_mute_remove_and_close(self, cls):
        """[case:console.moderation_rooms.room_action.performs]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.admin_room_action.return_value = APIResult(True, {'room': {}, 'moderation_action': {}})
        url = reverse('room_action', args=[ALWAYS_ON])
        response = self.client.post(url, {'action': 'mute_user', 'target_user_id': MEMBER, 'reason': 'Cool off please', 'duration': '1h'}, follow=True)
        self.assertContains(response, 'Mute recorded for member ' + MEMBER)
        cls.return_value.admin_room_action.assert_called_with(ALWAYS_ON, {
            'action': 'mute_user', 'reason': 'Cool off please', 'target_user_id': MEMBER, 'duration': '1h'})
        self.client.post(url, {'action': 'remove_user', 'target_user_id': MEMBER, 'reason': 'Repeated harassment'})
        cls.return_value.admin_room_action.assert_called_with(ALWAYS_ON, {
            'action': 'remove_user', 'reason': 'Repeated harassment', 'target_user_id': MEMBER})
        response = self.client.post(url, {'action': 'close_room', 'reason': 'Room retired by trust team'}, follow=True)
        cls.return_value.admin_room_action.assert_called_with(ALWAYS_ON, {
            'action': 'close_room', 'reason': 'Room retired by trust team'})
        self.assertContains(response, 'Close room recorded for the room')

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_action_failure_is_reported(self, cls):
        """[case:console.moderation_rooms.room_action.performs]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.admin_room_action.return_value = APIResult(False, {}, error='member is not in this room', status_code=409)
        response = self.client.post(reverse('room_action', args=[ALWAYS_ON]),
                                    {'action': 'warn_user', 'target_user_id': MEMBER, 'reason': 'Keep it kind'}, follow=True)
        self.assertContains(response, 'Room action failed: member is not in this room')

    @patch('control_panel.views_rooms.GoBFFClient')
    def test_appoint_and_revoke_moderators(self, cls):
        """[case:console.moderation_rooms.room_role.performs]"""
        cls.return_value.admin_rooms.return_value = _rooms_payload()
        cls.return_value.admin_room_role.return_value = APIResult(True, {'member_id': MEMBER, 'role': 'moderator'})
        url = reverse('room_role', args=[ALWAYS_ON])
        self.client.post(url, {'member_id': 'nope', 'role': 'moderator'})
        self.client.post(url, {'member_id': MEMBER, 'role': 'host'})
        cls.return_value.admin_room_role.assert_not_called()
        response = self.client.post(url, {'member_id': MEMBER, 'role': 'moderator'}, follow=True)
        self.assertContains(response, 'appointed as a room moderator')
        cls.return_value.admin_room_role.assert_called_with(ALWAYS_ON, MEMBER, 'moderator')
        self.client.post(url, {'member_id': MEMBER, 'role': 'participant'})
        cls.return_value.admin_room_role.assert_called_with(ALWAYS_ON, MEMBER, 'participant')


class RoomsClientTest(TestCase):
    @patch('control_panel.services.go_client.GoBFFClient._request')
    def test_client_paths(self, request):
        from control_panel.services.go_client import GoBFFClient
        client = GoBFFClient(access_token='a', refresh_token='r', use_operator_context=False)
        client.admin_rooms()
        request.assert_called_with('GET', '/admin/moderation/rooms')
        client.admin_room_action(ALWAYS_ON, {'action': 'close_room', 'reason': 'Retired'})
        request.assert_called_with('POST', f'/admin/moderation/rooms/{ALWAYS_ON}/actions', payload={'action': 'close_room', 'reason': 'Retired'})
        client.room_members(ALWAYS_ON)
        request.assert_called_with('GET', f'/admin/moderation/rooms/{ALWAYS_ON}/members')
        client.admin_room_role(ALWAYS_ON, MEMBER, 'moderator')
        request.assert_called_with('POST', f'/admin/moderation/rooms/{ALWAYS_ON}/roles', payload={'member_id': MEMBER, 'role': 'moderator'})
