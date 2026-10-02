"""Conversation Rooms for operators: list rooms, read a room's members and
recent moderation actions, warn / mute / unmute / remove members, close a
room, and appoint or step down room moderators.

Everything goes through the Go admin API (/v1/admin/moderation/rooms...),
which accepts only the admin, moderator and trust_safety roles and records
every action in the room's moderation log and the member activity audit.
"""
import uuid

from django.contrib import messages
from django.http import Http404
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient, bff_failure_status

FILTERS = {
    'all': 'All rooms',
    'live': 'Live now',
    'always_on': 'Always-on',
    'member_hosted': 'Member-hosted',
    'closed': 'Closed',
}

# Per-member actions offered on each row of the members table.
MEMBER_ACTIONS = {
    'warn_user': 'Warn',
    'mute_user': 'Mute',
    'unmute_user': 'Unmute',
    'remove_user': 'Remove from room',
}

# Operator actions accepted by POST /v1/admin/moderation/rooms/{id}/actions.
ACTIONS = {
    'warn_user': 'Warn',
    'mute_user': 'Mute',
    'unmute_user': 'Unmute',
    'remove_user': 'Remove from room',
    'close_room': 'Close room',
}
MUTE_DURATIONS = {'10m': '10 minutes', '1h': '1 hour', 'session': 'Until the room ends (24 hours for always-on)'}
ROLES = {'moderator': 'Appoint as room moderator', 'participant': 'Step down to participant'}


def _matches(room, key):
    state = room.get('lifecycle_state') or ''
    if key == 'live':
        return state == 'active' and int(room.get('here_now') or 0) > 0
    if key == 'always_on':
        return bool(room.get('always_on')) and state != 'closed'
    if key == 'member_hosted':
        return not room.get('always_on') and state != 'closed'
    if key == 'closed':
        return state == 'closed'
    return True


def _valid_uuid(value):
    try:
        uuid.UUID(value)
    except (TypeError, ValueError):
        return False
    return True


def _load():
    result = GoBFFClient().admin_rooms()
    data = result.data if result.ok else {}
    return result, data.get('rooms') or [], data.get('recent_actions') or []


def _status(result):
    return 200 if result.ok else bff_failure_status(result.status_code)


def _members(room_id):
    """The room's members from GET /admin/moderation/rooms/{id}/members, each
    with a readable state and the role change it allows (none for hosts)."""
    result = GoBFFClient().room_members(str(room_id))
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    members = [m for m in data.get('members') or [] if isinstance(m, dict)]
    for m in members:
        if m.get('removed_until'):
            m['state'] = f"Removed until {m['removed_until']}"
        elif m.get('here_now'):
            m['state'] = 'Here now'
        elif m.get('in_room'):
            m['state'] = 'In the room'
        else:
            m['state'] = (m.get('status') or 'left').title()
        if m.get('muted_until'):
            m['state'] += f" · muted until {m['muted_until']}"
        role = m.get('role') or 'participant'
        m['role_change'] = {'participant': 'moderator', 'moderator': 'participant'}.get(role, '') \
            if not m.get('removed_until') else ''
    return members, (None if result.ok else result.error)


@never_cache
@require_GET
def rooms(request):
    key = request.GET.get('filter', 'all')
    if key not in FILTERS:
        key = 'all'
    result, all_rooms, actions = _load()
    titles = {r.get('id'): r.get('title') for r in all_rooms}
    for action in actions:
        action['room_title'] = titles.get(action.get('room_id'), '')
    counts = {k: sum(1 for r in all_rooms if _matches(r, k)) for k in FILTERS}
    return render(request, 'control_panel/rooms.html', {
        'rooms': [r for r in all_rooms if _matches(r, key)],
        'recent_actions': actions[:25],
        'filters': [(k, label, counts[k]) for k, label in FILTERS.items()],
        'active_filter': key,
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=_status(result))


@never_cache
@require_GET
def room_detail(request, room_id):
    result, all_rooms, actions = _load()
    room = next((r for r in all_rooms if r.get('id') == str(room_id)), None)
    if result.ok and room is None:
        raise Http404('Room not found')
    room_actions = [a for a in actions if a.get('room_id') == str(room_id)]
    members, members_error = _members(room_id) if result.ok else ([], None)
    # Member ids for the forms' suggestions: the members table, then anyone
    # named in the room's recent moderation actions.
    people = [m.get('user_id') for m in members if m.get('user_id')]
    for action in room_actions:
        target = action.get('target_user_id') or ''
        if target and target not in people:
            people.append(target)
    return render(request, 'control_panel/room_detail.html', {
        'room': room or {'id': str(room_id)},
        'recent_actions': room_actions,
        'people': people,
        'members': members,
        'members_error': members_error,
        'member_actions': MEMBER_ACTIONS.items(),
        'actions': ACTIONS.items(),
        'durations': MUTE_DURATIONS.items(),
        'roles': ROLES.items(),
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=_status(result))


@never_cache
@require_POST
def room_action(request, room_id):
    action = request.POST.get('action', '')
    target = request.POST.get('target_user_id', '').strip()
    reason = request.POST.get('reason', '').strip()
    duration = request.POST.get('duration', '10m')
    if action not in ACTIONS or not 5 <= len(reason) <= 280 \
            or (action != 'close_room' and not _valid_uuid(target)) \
            or (action == 'mute_user' and duration not in MUTE_DURATIONS):
        messages.error(request, 'Choose an action, a member id (except to close the room) and a 5–280 character reason.')
        return redirect('room_detail', room_id=room_id)
    payload = {'action': action, 'reason': reason}
    if action != 'close_room':
        payload['target_user_id'] = target
    if action == 'mute_user':
        payload['duration'] = duration
    result = GoBFFClient().admin_room_action(str(room_id), payload)
    if result.ok:
        who = 'the room' if action == 'close_room' else f'member {target}'
        messages.success(request, f'{ACTIONS[action]} recorded for {who}. The action is in the room\'s moderation log.')
    else:
        messages.error(request, f'Room action failed: {result.error}')
    return redirect('room_detail', room_id=room_id)


@never_cache
@require_POST
def room_role(request, room_id):
    member = request.POST.get('member_id', '').strip()
    role = request.POST.get('role', '')
    if role not in ROLES or not _valid_uuid(member):
        messages.error(request, 'Enter the member id and choose moderator or participant.')
        return redirect('room_detail', room_id=room_id)
    result = GoBFFClient().admin_room_role(str(room_id), member, role)
    if result.ok:
        done = 'appointed as a room moderator' if role == 'moderator' else 'stepped down to participant'
        messages.success(request, f'Member {member} {done}. The change is in the room\'s moderation log.')
    else:
        messages.error(request, f'Role change failed: {result.error}')
    return redirect('room_detail', room_id=room_id)
