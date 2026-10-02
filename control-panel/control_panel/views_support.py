"""Support tickets: the operator side of member and website-visitor support.

Pages: the ticket queue (filters, SLA badges, claim, bulk actions, CSV
export), a ticket's detail (thread, internal notes, events, replies with
canned responses, triage changes, merge, member context), canned response
management and the SLA dashboard.

Everything goes through the Go admin API (/v1/admin/support/...). Go lets
admin, ops_admin, support, trust_safety and moderator operators work tickets
and analysts read the dashboard only. The console has no role store: it asks
GET /admin/support/agents (refused for read-only operators) once and caches
the answer in the session for a few minutes, purely to hide controls the
operator cannot use. Go still enforces every call. Attachments and the CSV
export are streamed through console views with the operator's own session,
so Go credentials and storage keys never reach the browser.
"""
import re
import time
import uuid
from datetime import datetime, timezone
from urllib.parse import quote, urlencode

from django.contrib import messages
from django.http import HttpResponse, JsonResponse, StreamingHttpResponse
from django.shortcuts import redirect, render
from django.urls import reverse
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from .operator_context import OPERATOR_ROLE_LABELS, USER_READ_ROLES
from .services.go_client import GoBFFClient, bff_failure_status

PROJECT_NAME = 'AegisConnect'

STATUSES = {
    'new': 'New', 'open': 'Open', 'pending_member': 'Waiting on member',
    'on_hold': 'On hold', 'resolved': 'Resolved', 'closed': 'Closed',
}
STATUS_FILTERS = {'active': 'Active (not resolved or closed)', 'all': 'All statuses', **STATUSES}
STATUS_CLASSES = {
    'new': 'badge-gold', 'open': 'badge-purple', 'pending_member': 'badge-inactive',
    'on_hold': 'badge-warning', 'resolved': 'badge-active', 'closed': 'badge-inactive',
}
CATEGORIES = {
    'account_login': 'Account & login', 'verification': 'Verification',
    'payments_billing': 'Payments & billing', 'safety_harassment': 'Safety & harassment',
    'matches_chat': 'Matches & chat', 'technical': 'Technical problem / bug',
    'feature_request': 'Feature request', 'privacy_data': 'Privacy & data request', 'other': 'Other',
}
PRIORITIES = {'urgent': 'Urgent', 'high': 'High', 'normal': 'Normal', 'low': 'Low'}
PRIORITY_CLASSES = {'urgent': 'badge-danger', 'high': 'badge-warning', 'normal': 'badge-purple', 'low': 'badge-inactive'}
TEAMS = {
    'general': 'General', 'trust_safety': 'Trust & Safety', 'billing': 'Billing',
    'privacy': 'Privacy', 'technical': 'Technical',
}
CHANNELS = {'app': 'App', 'website': 'Website', 'email': 'Email'}
SLA_FILTERS = {'breached': 'Breached', 'at_risk': 'At risk'}
SLA_BADGES = {
    'breached': {'cls': 'badge-danger', 'label': 'SLA breached'},
    'at_risk': {'cls': 'badge-warning', 'label': 'SLA at risk'},
    'paused': {'cls': 'badge-inactive', 'label': 'SLA paused'},
    'met': {'cls': 'badge-active', 'label': 'SLA met'},
    'ok': {'cls': 'badge-purple', 'label': 'On track'},
}
SORTS = {'sla': 'SLA due first', 'updated': 'Recently updated', 'created': 'Newest', 'priority': 'Priority'}
ASSIGNEE_FILTERS = {'': 'Anyone', 'me': 'Assigned to me', 'unassigned': 'Unassigned'}
VISIBILITIES = {'public': 'Public reply', 'internal': 'Internal note'}
# Statuses POST .../messages accepts alongside a reply.
REPLY_STATUSES = {
    'pending_member': 'Waiting on member', 'resolved': 'Resolved', 'on_hold': 'On hold', 'open': 'Open',
}
BULK_ACTIONS = {'claim': 'Claim', 'assign': 'Assign to', 'status': 'Set status', 'priority': 'Set priority'}
ACCOUNT_STATUS_CLASSES = {
    'active': 'badge-active', 'deactivated': 'badge-inactive', 'suspended': 'badge-warning',
    'banned': 'badge-danger', 'deletion_pending': 'badge-warning', 'erased': 'badge-inactive',
}
VERIFICATION_CLASSES = {
    'approved': 'badge-active', 'pending': 'badge-warning', 'rejected': 'badge-danger', 'unverified': 'badge-inactive',
}
EVENT_VERBS = {
    'created': 'raised the ticket',
    'status_changed': 'changed the status',
    'priority_changed': 'changed the priority',
    'category_changed': 'changed the category',
    'team_changed': 'moved the ticket to another team',
    'assigned': 'changed the assignee',
    'reopened': 'reopened the ticket',
    'auto_closed': 'closed the ticket automatically',
    'merged': 'merged another ticket into this one',
    'merged_into': 'merged this ticket into another',
    'rated': 'rated the support',
    'tags_changed': 'changed the tags',
    'closed_by_member': 'closed the ticket',
}
# Message events duplicate the thread itself, so the timeline leaves them out.
THREAD_EVENTS = {'member_replied', 'agent_replied', 'note_added'}
EVENT_VALUE_LABELS = {
    'status_changed': STATUSES, 'priority_changed': PRIORITIES,
    'category_changed': CATEGORIES, 'team_changed': TEAMS,
}
ACTOR_FALLBACK = {'member': 'Member', 'contact': 'Visitor', 'agent': 'An agent', 'system': 'System'}
# Attachment types Go accepts; images open inline, PDFs always download.
ATTACHMENT_TYPES = {'image/jpeg': 'inline', 'image/png': 'inline', 'application/pdf': 'attachment'}
ATTACHMENT_EXTENSIONS = {'image/jpeg': '.jpg', 'image/png': '.png', 'application/pdf': '.pdf'}
CSV_TYPES = ('text/csv', 'application/csv')
DASHBOARD_DAYS = (7, 30, 90)

PAGE_SIZE = 50
MAX_OFFSET = 100000
BODY_MAX = 5000
Q_MAX = 120
TITLE_MAX = 120
TAG_MAX = 40
TAGS_MAX = 20
BULK_MAX = 100
ACCESS_SESSION_KEY = 'support_access'
DRAFT_SESSION_KEY = 'support_reply_draft'
ACCESS_TTL_SECONDS = 300
READ_ONLY_MESSAGE = ('Your operator role can read the support dashboard only. Working tickets needs the '
                     'support, trust_safety, moderator, ops_admin or admin role.')
_FILENAME_RE = re.compile(r'filename\*?=(?:UTF-8\'\')?"?([^";]+)"?', re.IGNORECASE)
_UNSAFE_FILENAME_CHARS = re.compile(r'[^A-Za-z0-9._-]+')
_EMAIL_RE = re.compile(r'^[^@\s<>"]+@[^@\s<>"]+\.[^@\s<>"]+$')


# ── helpers ──────────────────────────────────────────────────────────────────

def _valid_uuid(value):
    try:
        uuid.UUID(str(value))
    except (TypeError, ValueError):
        return False
    return True


def _data(result):
    return result.data if result.ok and isinstance(result.data, dict) else {}


def _dicts(value):
    return [v for v in value or [] if isinstance(v, dict)] if isinstance(value, list) else []


def _dict(value):
    return value if isinstance(value, dict) else {}


def _int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _number(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _status(result):
    return 200 if result.ok else bff_failure_status(result.status_code)


def _parse_time(value):
    raw = str(value or '').strip()
    if not raw:
        return None
    try:
        parsed = datetime.fromisoformat(raw.replace('Z', '+00:00'))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _duration(minutes):
    minutes = int(round(abs(minutes)))
    if minutes < 60:
        return f'{minutes}m'
    hours, mins = divmod(minutes, 60)
    if hours < 24:
        return f'{hours}h {mins}m' if mins else f'{hours}h'
    days, hours = divmod(hours, 24)
    return f'{days}d {hours}h' if hours else f'{days}d'


def _due(value):
    at = _parse_time(value)
    if at is None:
        return None
    minutes = (at - datetime.now(timezone.utc)).total_seconds() / 60
    if minutes >= 0:
        return {'at': at, 'relative': f'in {_duration(minutes)}', 'overdue': False}
    return {'at': at, 'relative': f'{_duration(minutes)} overdue', 'overdue': True}


def _api_error(result, what='Support'):
    if result.status_code == 403:
        return READ_ONLY_MESSAGE
    return f'{what} unavailable: {result.error}' if result.error else f'{what} unavailable.'


def _filters(source):
    """Validated queue filters, in the order Go names them."""
    def pick(key, allowed, default=''):
        value = str(source.get(key, default) or '').strip()
        return value if value in allowed else default

    assignee = str(source.get('assignee') or '').strip()
    if assignee not in ASSIGNEE_FILTERS and not _valid_uuid(assignee):
        assignee = ''
    return {
        'status': pick('status', STATUS_FILTERS, 'active'),
        'category': pick('category', CATEGORIES),
        'priority': pick('priority', PRIORITIES),
        'team': pick('team', TEAMS),
        'channel': pick('channel', CHANNELS),
        'assignee': assignee,
        'sla': pick('sla', SLA_FILTERS),
        'q': str(source.get('q') or '').strip()[:Q_MAX],
        'sort': pick('sort', SORTS, 'sla'),
    }


def _query(filters):
    return urlencode({k: v for k, v in filters.items() if v})


def _cached_access(request):
    cached = request.session.get(ACCESS_SESSION_KEY)
    uid = str(request.session.get('operator_user_id') or '')
    if (isinstance(cached, dict) and cached.get('uid') == uid
            and time.time() - float(cached.get('at') or 0) < ACCESS_TTL_SECONDS):
        return cached
    return None


def _support_access(request, agents_result=None, client=None):
    """What this operator may do here: manage True (work tickets), False
    (dashboard only) or None (unknown, Go decides), plus their roles when Go
    lists them among the agents."""
    uid = str(request.session.get('operator_user_id') or '')
    if agents_result is None:
        cached = _cached_access(request)
        if cached is not None:
            return cached
        agents_result = (client or GoBFFClient()).support_agents()
    roles = None
    if agents_result.ok:
        manage = True
        for agent in _dicts(_data(agents_result).get('agents')):
            if uid and str(agent.get('id') or '') == uid:
                roles = sorted({str(r) for r in agent.get('roles') or [] if isinstance(r, str)})
    elif agents_result.status_code == 403:
        manage = False
    else:
        return {'uid': uid, 'manage': None, 'roles': None}
    access = {'uid': uid, 'manage': manage, 'roles': roles, 'at': time.time()}
    request.session[ACCESS_SESSION_KEY] = access
    return access


def _access_context(access):
    roles = access.get('roles')
    return {
        'can_manage': access.get('manage') is not False,
        'operator_roles': [OPERATOR_ROLE_LABELS.get(r, r) for r in roles or []],
        # Unknown roles: show the link and let the user page answer.
        'can_view_users': not roles or bool(set(roles) & USER_READ_ROLES),
        'operator_user_id': access.get('uid') or '',
    }


def _refuse_read_only(request, fallback, **kwargs):
    access = _cached_access(request)
    if access is not None and access.get('manage') is False:
        messages.error(request, READ_ONLY_MESSAGE)
        return redirect(fallback, **kwargs)
    return None


def _safe_next(request, fallback, **kwargs):
    target = str(request.POST.get('next') or '').strip()
    if (target.startswith('/support/')
            and url_has_allowed_host_and_scheme(target, allowed_hosts={request.get_host()},
                                                require_https=request.is_secure())):
        return redirect(target)
    return redirect(fallback, **kwargs)


def _badge(labels, classes, value, default_cls='badge-inactive'):
    value = str(value or '')
    return {'value': value, 'label': labels.get(value, value.replace('_', ' ') or '—'),
            'cls': classes.get(value, default_cls) if isinstance(classes, dict) else default_cls}


def _decorate_ticket(ticket):
    sla = _dict(ticket.get('sla'))
    ticket['sla'] = sla
    ticket['sla_badge'] = SLA_BADGES.get(str(sla.get('state') or ''))
    ticket['first_response_badge'] = SLA_BADGES.get(str(sla.get('first_response') or ''))
    ticket['resolution_badge'] = SLA_BADGES.get(str(sla.get('resolution') or ''))
    ticket['status_badge'] = _badge(STATUSES, STATUS_CLASSES, ticket.get('status'))
    ticket['priority_badge'] = _badge(PRIORITIES, PRIORITY_CLASSES, ticket.get('priority'))
    ticket['category_label'] = CATEGORIES.get(str(ticket.get('category') or ''), ticket.get('category') or '—')
    ticket['team_label'] = TEAMS.get(str(ticket.get('team') or ''), ticket.get('team') or '—')
    ticket['channel_label'] = CHANNELS.get(str(ticket.get('channel') or ''), ticket.get('channel') or '—')
    ticket['requester'] = _dict(ticket.get('requester'))
    assignee = _dict(ticket.get('assignee'))
    ticket['assignee'] = assignee if assignee.get('id') else None
    ticket['tags'] = [str(t) for t in ticket.get('tags') or [] if isinstance(t, (str, int))]
    merged_into = _dict(ticket.get('merged_into'))
    if merged_into and not _valid_uuid(merged_into.get('id')):
        merged_into['id'] = ''
    ticket['merged_into'] = merged_into or None
    issue_id = str(ticket.get('client_error_issue_id') or '')
    ticket['client_error_link'] = issue_id if _valid_uuid(issue_id) else ''
    ticket['satisfaction'] = _dict(ticket.get('satisfaction')) or None
    ticket['first_response_due'] = _due(ticket.get('first_response_due_at'))
    ticket['resolution_due'] = _due(ticket.get('resolution_due_at'))
    for key in ('created_at', 'updated_at', 'last_activity_at', 'first_responded_at', 'resolved_at', 'closed_at'):
        ticket[key.replace('_at', '_time')] = _parse_time(ticket.get(key))
    return ticket


def _mailto(ticket):
    email = str(ticket['requester'].get('email') or '').strip()
    if not _EMAIL_RE.match(email):
        return '', ''
    subject = f"Re: [{ticket.get('reference') or 'Connect support'}] {ticket.get('subject') or ''}".strip()
    return email, f"mailto:{quote(email, safe='@')}?subject={quote(subject)}"


def _decorate_message(message):
    message['is_internal'] = message.get('visibility') == 'internal'
    message['author_kind'] = str(message.get('author_kind') or '')
    message['author_label'] = message.get('author_name') or ACTOR_FALLBACK.get(message['author_kind'], 'Unknown')
    attachments = []
    for attachment in _dicts(message.get('attachments')):
        if not _valid_uuid(attachment.get('id')):
            continue
        content_type = str(attachment.get('content_type') or '').lower()
        attachment['proxy_url'] = reverse('support_attachment', args=[attachment['id']])
        attachment['is_image'] = content_type in ('image/jpeg', 'image/png')
        attachments.append(attachment)
    message['attachments'] = attachments
    return message


def _event_text(event):
    event_type = str(event.get('event_type') or '')
    actor = event.get('actor_name') or ACTOR_FALLBACK.get(str(event.get('actor_kind') or ''), 'Someone')
    verb = EVENT_VERBS.get(event_type, event_type.replace('_', ' ') or 'updated the ticket')
    labels = EVENT_VALUE_LABELS.get(event_type, {})

    def label(value):
        value = '' if value is None else str(value)
        return labels.get(value, value)

    before, after = label(event.get('from_value')), label(event.get('to_value'))
    if before and after:
        return f'{actor} {verb}: {before} → {after}'
    if after:
        return f'{actor} {verb}: {after}'
    if before:
        return f'{actor} {verb} (was {before})'
    return f'{actor} {verb}'


def _timeline(messages_, events):
    epoch = datetime.min.replace(tzinfo=timezone.utc)
    entries = []
    for index, message in enumerate(messages_):
        at = _parse_time(message.get('created_at'))
        entries.append({'kind': 'message', 'at': at, 'order': (at or epoch, 1, index), 'message': message})
    for index, event in enumerate(events):
        if str(event.get('event_type') or '') in THREAD_EVENTS:
            continue
        at = _parse_time(event.get('created_at'))
        entries.append({'kind': 'event', 'at': at, 'order': (at or epoch, 0, index), 'text': _event_text(event)})
    entries.sort(key=lambda e: e['order'])
    return entries


def _tags(raw):
    tags = []
    for part in str(raw or '').split(','):
        tag = part.strip()
        if tag and tag not in tags:
            tags.append(tag)
    return tags


# ── queue ────────────────────────────────────────────────────────────────────

@never_cache
@require_GET
def support_queue(request):
    filters = _filters(request.GET)
    offset = _int(request.GET.get('offset'), 0)
    if not 0 <= offset <= MAX_OFFSET:
        offset = 0
    client = GoBFFClient()
    result = client.list_support_tickets(limit=PAGE_SIZE, offset=offset, **filters)
    agents_result = client.support_agents()
    access = _support_access(request, agents_result)
    data = _data(result)
    tickets = [_decorate_ticket(t) for t in _dicts(data.get('tickets')) if _valid_uuid(t.get('id'))]
    total = _int(data.get('total'), len(tickets))
    counts = {k: _int(v) for k, v in _dict(data.get('counts')).items()}
    context = {
        'tickets': tickets,
        'total': total,
        'counts': [(key, label, counts.get(key, 0)) for key, label in STATUSES.items()],
        'filters': filters,
        'filter_query': _query(filters),
        'statuses': STATUS_FILTERS.items(),
        'ticket_statuses': STATUSES.items(),
        'categories': CATEGORIES.items(),
        'priorities': PRIORITIES.items(),
        'teams': TEAMS.items(),
        'channels': CHANNELS.items(),
        'assignee_filters': ASSIGNEE_FILTERS.items(),
        'sla_filters': SLA_FILTERS.items(),
        'sorts': SORTS.items(),
        'bulk_actions': BULK_ACTIONS.items(),
        'agents': _dicts(_data(agents_result).get('agents')),
        'offset': offset,
        'limit': PAGE_SIZE,
        'prev_offset': max(0, offset - PAGE_SIZE),
        'next_offset': offset + PAGE_SIZE,
        'has_more': offset + len(tickets) < total,
        'current_path': request.get_full_path(),
        'error': None if result.ok else _api_error(result, 'Ticket queue'),
        'project_name': PROJECT_NAME,
    }
    context.update(_access_context(access))
    if result.status_code == 403:
        context['can_manage'] = False
    return render(request, 'control_panel/support/queue.html', context, status=_status(result))


@never_cache
@require_GET
def support_export(request):
    filters = _filters(request.GET)
    result = GoBFFClient().export_support_tickets(**filters)
    if not result.ok:
        messages.error(request, f'CSV export failed: {_api_error(result, "Export")}')
        return redirect(f"{reverse('support_queue')}?{_query(filters)}")
    content_type = (result.content_type or '').split(';')[0].strip().lower()
    if content_type not in CSV_TYPES:
        close = getattr(result.chunks, 'close', None)
        if close:
            close()
        return HttpResponse('Unexpected export format', status=502, content_type='text/plain')
    response = StreamingHttpResponse(result.chunks, content_type='text/csv; charset=utf-8')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M')
    response['Content-Disposition'] = f'attachment; filename="support-tickets-{stamp}.csv"'
    response['Cache-Control'] = 'private, no-store'
    response['X-Content-Type-Options'] = 'nosniff'
    return response


@never_cache
@require_POST
def support_bulk(request):
    refused = _refuse_read_only(request, 'support_queue')
    if refused:
        return refused
    ids = []
    for value in request.POST.getlist('ticket_ids'):
        if _valid_uuid(value) and value not in ids:
            ids.append(value)
    action = request.POST.get('action', '').strip()
    if not ids:
        messages.error(request, 'Select at least one ticket.')
        return _safe_next(request, 'support_queue')
    if len(ids) > BULK_MAX:
        messages.error(request, f'Bulk actions take at most {BULK_MAX} tickets at a time.')
        return _safe_next(request, 'support_queue')
    if action not in BULK_ACTIONS:
        messages.error(request, 'Choose a bulk action.')
        return _safe_next(request, 'support_queue')
    value = ''
    if action == 'assign':
        value = request.POST.get('assign_value', '').strip()
        if value and not _valid_uuid(value):
            messages.error(request, 'Choose an agent to assign.')
            return _safe_next(request, 'support_queue')
    elif action == 'status':
        value = request.POST.get('status_value', '').strip()
        if value not in STATUSES:
            messages.error(request, 'Choose a status.')
            return _safe_next(request, 'support_queue')
    elif action == 'priority':
        value = request.POST.get('priority_value', '').strip()
        if value not in PRIORITIES:
            messages.error(request, 'Choose a priority.')
            return _safe_next(request, 'support_queue')
    result = GoBFFClient().bulk_support_tickets(ids, action, value)
    if not result.ok:
        messages.error(request, f'Bulk {BULK_ACTIONS[action].lower()} failed: {_api_error(result, "Bulk update")}')
        return _safe_next(request, 'support_queue')
    data = _data(result)
    updated = data.get('updated') if isinstance(data.get('updated'), list) else []
    failed = _dicts(data.get('failed'))
    if updated:
        messages.success(request, f'{len(updated)} ticket{"s" if len(updated) != 1 else ""} updated.')
    if failed:
        detail = '; '.join(f"{str(f.get('id') or '')[:8]}: {f.get('error') or 'failed'}" for f in failed[:5])
        more = f' (+{len(failed) - 5} more)' if len(failed) > 5 else ''
        messages.warning(request, f'{len(failed)} could not be updated: {detail}{more}')
    if not updated and not failed:
        messages.info(request, 'Nothing was changed.')
    return _safe_next(request, 'support_queue')


# ── ticket detail ────────────────────────────────────────────────────────────

@never_cache
@require_GET
def support_ticket_detail(request, ticket_id):
    ticket_id = str(ticket_id)
    client = GoBFFClient()
    result = client.get_support_ticket(ticket_id)
    agents_result = client.support_agents()
    access = _support_access(request, agents_result)
    data = _data(result)
    ticket = _decorate_ticket(dict(data['ticket'])) if isinstance(data.get('ticket'), dict) else {}
    thread = [_decorate_message(m) for m in _dicts(data.get('messages'))]
    events = _dicts(data.get('events'))
    access_context = _access_context(access)
    if result.status_code == 403:
        access_context['can_manage'] = False

    canned = []
    if ticket and access_context['can_manage']:
        canned_result = client.list_support_canned_responses()
        for item in _dicts(_data(canned_result).get('canned_responses')):
            if _valid_uuid(item.get('id')) and item.get('is_active', True):
                item['preview_url'] = reverse('support_canned_preview', args=[ticket_id, item['id']])
                item['category_label'] = CATEGORIES.get(str(item.get('category') or ''), '')
                canned.append(item)

    agents = _dicts(_data(agents_result).get('agents'))
    assignee = ticket.get('assignee') if ticket else None
    if assignee and not any(str(a.get('id')) == str(assignee.get('id')) for a in agents):
        agents = [{'id': assignee.get('id'), 'name': assignee.get('name'), 'open_assigned': None}] + agents

    member = _dict(data.get('member_context')) or None
    if member:
        member['account_badge'] = _badge({}, ACCOUNT_STATUS_CLASSES, member.get('account_status'))
        member['verification_badge'] = _badge({}, VERIFICATION_CLASSES, member.get('verification_status'))
        member['joined_time'] = _parse_time(member.get('joined_at'))
        member['valid_id'] = _valid_uuid(member.get('member_id'))
    related = []
    for item in _dicts(data.get('related_tickets')):
        if _valid_uuid(item.get('id')) and str(item.get('id')) != ticket_id:
            item['status_badge'] = _badge(STATUSES, STATUS_CLASSES, item.get('status'))
            item['created_time'] = _parse_time(item.get('created_at'))
            related.append(item)

    requester_email, mailto = _mailto(ticket) if ticket else ('', '')
    drafts = request.session.get(DRAFT_SESSION_KEY)
    draft = {}
    if isinstance(drafts, dict) and ticket_id in drafts:
        draft = _dict(drafts.pop(ticket_id))
        request.session[DRAFT_SESSION_KEY] = drafts

    context = {
        'ticket_id': ticket_id,
        'ticket': ticket,
        'timeline': _timeline(thread, events),
        'message_total': len(thread),
        'member': member,
        'related': related,
        'requester_email': requester_email,
        'mailto': mailto,
        'is_contact': bool(ticket) and ticket['requester'].get('kind') == 'contact',
        'canned_responses': canned,
        'agents': agents,
        'is_mine': bool(assignee) and str(assignee.get('id')) == access_context['operator_user_id'],
        'statuses': STATUSES.items(),
        'reply_statuses': REPLY_STATUSES.items(),
        'visibilities': VISIBILITIES.items(),
        'categories': CATEGORIES.items(),
        'priorities': PRIORITIES.items(),
        'teams': TEAMS.items(),
        'tags_value': ', '.join(ticket.get('tags') or []) if ticket else '',
        'draft': draft,
        'body_max': BODY_MAX,
        'error': None if result.ok else _api_error(result, 'Ticket'),
        'project_name': PROJECT_NAME,
    }
    context.update(access_context)
    if result.status_code == 403:
        context['can_manage'] = False
    return render(request, 'control_panel/support/ticket_detail.html', context, status=_status(result))


@never_cache
@require_POST
def support_ticket_reply(request, ticket_id):
    ticket_id = str(ticket_id)
    refused = _refuse_read_only(request, 'support_ticket_detail', ticket_id=ticket_id)
    if refused:
        return refused
    body = request.POST.get('body', '').replace('\r\n', '\n').strip()
    visibility = request.POST.get('visibility', 'public').strip()
    canned_id = request.POST.get('canned_response_id', '').strip()
    status = request.POST.get('status', '').strip()
    problem = ''
    if visibility not in VISIBILITIES:
        problem = 'Choose a public reply or an internal note.'
    elif status and status not in REPLY_STATUSES:
        problem = 'Choose a valid status to set with the reply.'
    elif canned_id and not _valid_uuid(canned_id):
        problem = 'That canned response is not valid.'
    elif not body and not canned_id:
        problem = 'Write a reply or pick a canned response.'
    elif len(body) > BODY_MAX:
        problem = f'Keep the reply under {BODY_MAX} characters.'
    if not problem:
        result = GoBFFClient().reply_support_ticket(
            ticket_id, body=body, visibility=visibility, canned_response_id=canned_id, status=status,
        )
        if result.ok:
            done = 'Reply sent to the requester.' if visibility == 'public' else 'Internal note added.'
            if status:
                done += f' Status set to {REPLY_STATUSES[status]}.'
            messages.success(request, done)
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        problem = f'Reply failed: {_api_error(result, "Reply")}'
    messages.error(request, problem)
    drafts = request.session.get(DRAFT_SESSION_KEY)
    drafts = drafts if isinstance(drafts, dict) else {}
    drafts[ticket_id] = {'body': body[:BODY_MAX], 'visibility': visibility, 'status': status}
    request.session[DRAFT_SESSION_KEY] = drafts
    return redirect('support_ticket_detail', ticket_id=ticket_id)


@never_cache
@require_POST
def support_ticket_update(request, ticket_id):
    ticket_id = str(ticket_id)
    refused = _refuse_read_only(request, 'support_ticket_detail', ticket_id=ticket_id)
    if refused:
        return refused
    post = request.POST
    changes = {}
    for field, allowed in (('status', STATUSES), ('priority', PRIORITIES), ('category', CATEGORIES), ('team', TEAMS)):
        value = post.get(field, '').strip()
        if value == post.get(f'orig_{field}', '').strip():
            continue
        if value not in allowed:
            messages.error(request, f'Choose a valid {field}.')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        changes[field] = value
    assignee = post.get('assignee_id', '').strip()
    if assignee != post.get('orig_assignee_id', '').strip():
        if assignee and not _valid_uuid(assignee):
            messages.error(request, 'Choose an agent to assign.')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        changes['assignee_id'] = assignee
    tags = _tags(post.get('tags'))
    if tags != _tags(post.get('orig_tags')):
        if len(tags) > TAGS_MAX or any(len(t) > TAG_MAX for t in tags):
            messages.error(request, f'Use at most {TAGS_MAX} tags of up to {TAG_MAX} characters.')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        changes['tags'] = tags
    issue = post.get('client_error_issue_id', '').strip()
    if issue != post.get('orig_client_error_issue_id', '').strip():
        if issue and not _valid_uuid(issue):
            messages.error(request, 'Link a client error by its issue id (a UUID from the Client errors page).')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        changes['client_error_issue_id'] = issue
    if not changes:
        messages.info(request, 'Nothing changed.')
        return redirect('support_ticket_detail', ticket_id=ticket_id)
    result = GoBFFClient().update_support_ticket(ticket_id, changes)
    if result.ok:
        messages.success(request, 'Ticket updated: ' + ', '.join(k.replace('_id', '').replace('_', ' ') for k in changes) + '.')
    else:
        messages.error(request, f'Update failed: {_api_error(result, "Update")}')
    return redirect('support_ticket_detail', ticket_id=ticket_id)


@never_cache
@require_POST
def support_ticket_claim(request, ticket_id):
    ticket_id = str(ticket_id)
    refused = _refuse_read_only(request, 'support_ticket_detail', ticket_id=ticket_id)
    if refused:
        return refused
    result = GoBFFClient().claim_support_ticket(ticket_id)
    ticket = _dict(_data(result).get('ticket'))
    if result.ok:
        messages.success(request, f"Ticket {ticket.get('reference') or ticket_id[:8]} is now assigned to you.")
    else:
        messages.error(request, f'Claim failed: {_api_error(result, "Claim")}')
    return _safe_next(request, 'support_ticket_detail', ticket_id=ticket_id)


@never_cache
@require_POST
def support_ticket_merge(request, ticket_id):
    ticket_id = str(ticket_id)
    refused = _refuse_read_only(request, 'support_ticket_detail', ticket_id=ticket_id)
    if refused:
        return refused
    target = request.POST.get('into', '').strip()[:Q_MAX]
    if request.POST.get('confirm') != 'on':
        messages.error(request, 'Tick the confirmation box to merge. Merging cannot be undone.')
        return redirect('support_ticket_detail', ticket_id=ticket_id)
    if not target:
        messages.error(request, 'Enter the reference (e.g. CN-2026-000123) or id of the ticket to merge into.')
        return redirect('support_ticket_detail', ticket_id=ticket_id)
    client = GoBFFClient()
    if _valid_uuid(target):
        into_id = str(uuid.UUID(target))
    else:
        found = client.list_support_tickets(limit=10, offset=0, status='all', q=target)
        if not found.ok:
            messages.error(request, f'Could not look up {target}: {_api_error(found, "Search")}')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        matches = [t for t in _dicts(_data(found).get('tickets'))
                   if str(t.get('reference') or '').lower() == target.lower() and _valid_uuid(t.get('id'))]
        if not matches:
            messages.error(request, f'No ticket has the reference {target}.')
            return redirect('support_ticket_detail', ticket_id=ticket_id)
        into_id = str(matches[0]['id'])
    if into_id == ticket_id:
        messages.error(request, 'A ticket cannot be merged into itself.')
        return redirect('support_ticket_detail', ticket_id=ticket_id)
    result = client.merge_support_ticket(ticket_id, into_id)
    if result.ok:
        merged = _dict(_data(result).get('ticket'))
        messages.success(request, f"Merged into {merged.get('reference') or into_id[:8]}.")
        return redirect('support_ticket_detail', ticket_id=str(merged.get('id') or into_id))
    if result.status_code == 409:
        messages.error(request, f'Merge refused: {result.error or "the tickets belong to different requesters."}')
    else:
        messages.error(request, f'Merge failed: {_api_error(result, "Merge")}')
    return redirect('support_ticket_detail', ticket_id=ticket_id)


@never_cache
@require_GET
def support_canned_preview(request, ticket_id, response_id):
    """Same-origin JSON for the reply box: the canned response with this
    ticket's placeholders rendered by Go."""
    result = GoBFFClient().preview_support_canned_response(str(ticket_id), str(response_id))
    if result.ok:
        return JsonResponse({'body': str(_data(result).get('body') or '')})
    return JsonResponse({'error': result.error or 'Preview unavailable.'}, status=bff_failure_status(result.status_code))


@never_cache
@require_GET
def support_attachment(request, attachment_id):
    access = _cached_access(request)
    if access is not None and access.get('manage') is False:
        return HttpResponse('Forbidden', status=403, content_type='text/plain')
    result = GoBFFClient().support_attachment_content(str(attachment_id))
    if not result.ok:
        return HttpResponse('Attachment unavailable', status=bff_failure_status(result.status_code), content_type='text/plain')
    content_type = (result.content_type or '').split(';')[0].strip().lower()
    if content_type not in ATTACHMENT_TYPES:
        close = getattr(result.chunks, 'close', None)
        if close:
            close()
        return HttpResponse('Unsupported attachment type', status=415, content_type='text/plain')
    extension = ATTACHMENT_EXTENSIONS[content_type]
    match = _FILENAME_RE.search(result.content_disposition or '')
    filename = _UNSAFE_FILENAME_CHARS.sub('_', match.group(1)).strip('._')[:100] if match else ''
    if not filename:
        filename = f'support-attachment-{str(attachment_id)[:8]}{extension}'
    elif not filename.lower().endswith(extension) and not (extension == '.jpg' and filename.lower().endswith('.jpeg')):
        filename += extension
    response = StreamingHttpResponse(result.chunks, content_type=content_type)
    response['Content-Disposition'] = f'{ATTACHMENT_TYPES[content_type]}; filename="{filename}"'
    response['Cache-Control'] = 'private, no-store'
    response['X-Content-Type-Options'] = 'nosniff'
    response['Content-Security-Policy'] = "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; sandbox"
    if str(result.content_length or '').isdigit():
        response['Content-Length'] = result.content_length
    return response


# ── canned responses ─────────────────────────────────────────────────────────

@never_cache
@require_GET
def support_canned_responses(request):
    client = GoBFFClient()
    result = client.list_support_canned_responses(include_inactive=True)
    access = _support_access(request, client=client)
    items = []
    for item in _dicts(_data(result).get('canned_responses')):
        if not _valid_uuid(item.get('id')):
            continue
        item['category_label'] = CATEGORIES.get(str(item.get('category') or ''), '')
        item['is_active'] = bool(item.get('is_active', True))
        item['updated_time'] = _parse_time(item.get('updated_at'))
        items.append(item)
    items.sort(key=lambda i: (not i['is_active'], str(i.get('title') or '').lower()))
    context = {
        'items': items,
        'active_total': sum(1 for i in items if i['is_active']),
        'categories': CATEGORIES.items(),
        'placeholders': (
            ('{{member_name}}', "The requester's first name, or the visitor's name on website tickets"),
            ('{{reference}}', 'The ticket reference, e.g. CN-2026-000123'),
            ('{{agent_name}}', 'The name of the agent sending the reply'),
        ),
        'title_max': TITLE_MAX,
        'body_max': BODY_MAX,
        'error': None if result.ok else _api_error(result, 'Canned responses'),
        'project_name': PROJECT_NAME,
    }
    context.update(_access_context(access))
    if result.status_code == 403:
        context['can_manage'] = False
    return render(request, 'control_panel/support/canned_responses.html', context, status=_status(result))


@never_cache
@require_POST
def support_canned_save(request):
    refused = _refuse_read_only(request, 'support_canned_responses')
    if refused:
        return refused
    response_id = request.POST.get('response_id', '').strip()
    title = request.POST.get('title', '').strip()
    body = request.POST.get('body', '').replace('\r\n', '\n').strip()
    category = request.POST.get('category', '').strip()
    if response_id and not _valid_uuid(response_id):
        messages.error(request, 'That canned response is not valid.')
        return redirect('support_canned_responses')
    if not 1 <= len(title) <= TITLE_MAX:
        messages.error(request, f'Give the canned response a title of up to {TITLE_MAX} characters.')
        return redirect('support_canned_responses')
    if not 1 <= len(body) <= BODY_MAX:
        messages.error(request, f'The text must be 1–{BODY_MAX} characters.')
        return redirect('support_canned_responses')
    if category and category not in CATEGORIES:
        messages.error(request, 'Choose a valid category.')
        return redirect('support_canned_responses')
    client = GoBFFClient()
    if response_id:
        changes = {'title': title, 'body': body, 'category': category or None,
                   'is_active': request.POST.get('is_active') == 'on'}
        result = client.update_support_canned_response(response_id, changes)
        done = f'Canned response “{title}” saved.'
    else:
        payload = {'title': title, 'body': body}
        if category:
            payload['category'] = category
        result = client.create_support_canned_response(payload)
        done = f'Canned response “{title}” created.'
    if result.ok:
        messages.success(request, done)
    else:
        messages.error(request, f'Saving failed: {_api_error(result, "Canned responses")}')
    return redirect('support_canned_responses')


@never_cache
@require_POST
def support_canned_deactivate(request, response_id):
    refused = _refuse_read_only(request, 'support_canned_responses')
    if refused:
        return refused
    result = GoBFFClient().deactivate_support_canned_response(str(response_id))
    if result.ok:
        messages.success(request, 'Canned response deactivated. Agents no longer see it in the reply box.')
    else:
        messages.error(request, f'Deactivating failed: {_api_error(result, "Canned responses")}')
    return redirect('support_canned_responses')


# ── SLA dashboard ────────────────────────────────────────────────────────────

def _counts(source, labels):
    source = _dict(source)
    return [(labels.get(key, key), _int(source.get(key))) for key in labels]


@never_cache
@require_GET
def support_dashboard(request):
    days = _int(request.GET.get('days'), 30)
    if days not in DASHBOARD_DAYS:
        days = 30
    client = GoBFFClient()
    result = client.support_dashboard(days=days)
    access = _support_access(request, client=client)
    data = _data(result)

    open_by_status = _counts(data.get('open_by_status'), {k: STATUSES[k] for k in ('new', 'open', 'pending_member', 'on_hold')})
    open_by_priority = _counts(data.get('open_by_priority'), PRIORITIES)
    open_by_team = _counts(data.get('open_by_team'), TEAMS)
    breaches = _dict(data.get('breaches'))
    csat = _dict(data.get('csat'))
    distribution = _dict(csat.get('distribution'))
    daily = _dicts(data.get('daily'))
    by_category = []
    for row in _dicts(data.get('by_category')):
        by_category.append({'label': CATEGORIES.get(str(row.get('category') or ''), row.get('category') or '—'),
                            'open': _int(row.get('open')), 'created': _int(row.get('created'))})
    safety = _dict(data.get('safety'))
    first_response = _number(data.get('median_first_response_minutes'))
    resolution = _number(data.get('median_resolution_minutes'))
    csat_average = _number(csat.get('average'))

    charts = {
        'support-daily': {'type': 'line', 'labels': [str(d.get('day') or '') for d in daily], 'datasets': [
            {'label': 'Created', 'data': [_int(d.get('created')) for d in daily]},
            {'label': 'Resolved', 'data': [_int(d.get('resolved')) for d in daily]},
        ]},
        'support-priority': {'type': 'bar', 'labels': [l for l, _ in open_by_priority],
                             'datasets': [{'label': 'Open tickets', 'data': [v for _, v in open_by_priority]}]},
        'support-team': {'type': 'bar', 'horizontal': True, 'labels': [l for l, _ in open_by_team],
                         'datasets': [{'label': 'Open tickets', 'data': [v for _, v in open_by_team]}]},
        'support-csat': {'type': 'bar', 'labels': ['1 ★', '2 ★', '3 ★', '4 ★', '5 ★'],
                         'datasets': [{'label': 'Ratings', 'data': [_int(distribution.get(str(n))) for n in range(1, 6)]}]},
        'support-category': {'type': 'bar', 'horizontal': True, 'labels': [r['label'] for r in by_category], 'datasets': [
            {'label': 'Open', 'data': [r['open'] for r in by_category]},
            {'label': f'Created ({days} days)', 'data': [r['created'] for r in by_category]},
        ]},
    }
    context = {
        'days': days,
        'day_options': DASHBOARD_DAYS,
        'window_days': _int(data.get('window_days'), days),
        'open_by_status': open_by_status,
        'open_total': sum(v for _, v in open_by_status),
        'open_by_priority': open_by_priority,
        'open_by_team': open_by_team,
        'breaches': {'first_response': _int(breaches.get('first_response')),
                     'resolution': _int(breaches.get('resolution')),
                     'at_risk': _int(breaches.get('at_risk'))},
        'breach_total': _int(breaches.get('first_response')) + _int(breaches.get('resolution')),
        'median_first_response': _duration(first_response) if first_response is not None else None,
        'median_resolution': _duration(resolution) if resolution is not None else None,
        'csat_average': f'{csat_average:.1f}' if csat_average is not None else None,
        'csat_responses': _int(csat.get('responses')),
        'csat_distribution': [(n, _int(distribution.get(str(n)))) for n in range(5, 0, -1)],
        'daily': daily,
        'by_category': by_category,
        'safety': {'open': _int(safety.get('open')), 'breached': _int(safety.get('breached')),
                   'at_risk': _int(safety.get('at_risk'))},
        'safety_query': urlencode({'team': 'trust_safety', 'status': 'active'}),
        'charts': charts,
        'error': None if result.ok else (
            'The support dashboard needs a support, trust_safety, moderator, ops_admin, admin or analyst role.'
            if result.status_code == 403 else _api_error(result, 'Dashboard')),
        'project_name': PROJECT_NAME,
    }
    context.update(_access_context(access))
    return render(request, 'control_panel/support/dashboard.html', context, status=_status(result))


def dashboard_safety_card(client):
    """The Trust & Safety ticket tile for the console's queue grid, or None
    when the operator cannot read the support dashboard."""
    result = client.support_dashboard(days=30)
    safety = _dict(_data(result).get('safety'))
    if not result.ok or not safety:
        return None
    breached, at_risk, open_ = _int(safety.get('breached')), _int(safety.get('at_risk')), _int(safety.get('open'))
    return {
        'label': 'Safety tickets',
        'count': open_,
        'overdue': breached,
        'at_risk': at_risk,
        'target': '1h',
        'href': f"{reverse('support_queue')}?{urlencode({'team': 'trust_safety', 'status': 'active'})}",
        'tone': 'danger' if breached else ('warning' if open_ else 'green'),
    }
