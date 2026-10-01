"""Client errors: the app's self-hosted crash and error reports, grouped into
issues by fingerprint. Operators can filter the issue list, read an issue's
versions and recent occurrences, and resolve, ignore or reopen it.

Everything goes through the Go admin API (/v1/admin/client-errors...). Go
lets admin and ops_admin read and change status and analyst read only; the
console has no role model of its own, so a refused change shows Go's 403
message. Reports are anonymous (a random per-install id, never an account
id) and PII-scrubbed on device and server before they reach these pages.
"""
import re
import uuid
from urllib.parse import urlencode

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient

STATUSES = {'open': 'Open', 'resolved': 'Resolved', 'ignored': 'Ignored', 'all': 'All'}
PLATFORMS = {
    'android': 'Android', 'ios': 'iOS', 'web': 'Web',
    'macos': 'macOS', 'windows': 'Windows', 'linux': 'Linux',
}
FATAL = {'': 'Fatal and non-fatal', 'true': 'Fatal only', 'false': 'Non-fatal only'}
SORTS = {'last_seen': 'Last seen', 'count': 'Occurrences', 'users': 'Affected installs'}
# Statuses POST /v1/admin/client-errors/{id}/status accepts.
STATUS_CHANGES = {'resolved': 'resolved', 'ignored': 'ignored', 'open': 'reopened'}
PAGE_SIZE = 50
MAX_OFFSET = 100000
NOTE_MAX = 500
VERSION_MAX = 64
VERSION_RE = re.compile(r'^[0-9A-Za-z][0-9A-Za-z.+_-]*$')


def _status(result):
    return 200 if result.ok else (result.status_code or 502)


def _dicts(value):
    return [v for v in value or [] if isinstance(v, dict)]


def _valid_uuid(value):
    try:
        uuid.UUID(str(value))
    except (TypeError, ValueError):
        return False
    return True


@never_cache
@require_GET
def client_errors(request):
    status = request.GET.get('status', 'open')
    if status not in STATUSES:
        status = 'open'
    platform = request.GET.get('platform', '')
    if platform not in PLATFORMS:
        platform = ''
    version = request.GET.get('version', '').strip()[:VERSION_MAX]
    fatal = request.GET.get('fatal', '')
    if fatal not in FATAL:
        fatal = ''
    sort = request.GET.get('sort', 'last_seen')
    if sort not in SORTS:
        sort = 'last_seen'
    try:
        offset = int(request.GET.get('offset', '0'))
        if not 0 <= offset <= MAX_OFFSET:
            raise ValueError()
    except ValueError:
        offset = 0

    result = GoBFFClient().list_client_errors(
        status=status, platform=platform, version=version, fatal=fatal,
        sort=sort, limit=PAGE_SIZE, offset=offset,
    )
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    # Rows link to the detail page, whose URL takes a UUID.
    issues = [i for i in _dicts(data.get('issues')) if _valid_uuid(i.get('id'))]
    try:
        total = int(data.get('total') or 0)
    except (TypeError, ValueError):
        total = len(issues)
    summary = data.get('summary') if isinstance(data.get('summary'), dict) else {}
    filters = {'status': status, 'platform': platform, 'version': version, 'fatal': fatal, 'sort': sort}
    return render(request, 'control_panel/client_errors.html', {
        'issues': issues,
        'total': total,
        'summary': summary,
        'filters': filters,
        'filter_query': urlencode({k: v for k, v in filters.items() if v}),
        'statuses': STATUSES.items(),
        'platforms': PLATFORMS.items(),
        'fatal_options': FATAL.items(),
        'sorts': SORTS.items(),
        'offset': offset,
        'limit': PAGE_SIZE,
        'prev_offset': max(0, offset - PAGE_SIZE),
        'next_offset': offset + PAGE_SIZE,
        'has_more': offset + len(issues) < total,
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=_status(result))


@never_cache
@require_GET
def client_error_detail(request, issue_id):
    result = GoBFFClient().get_client_error(str(issue_id))
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    issue = data.get('issue') if isinstance(data.get('issue'), dict) else {}
    occurrences = _dicts(data.get('occurrences'))
    for occurrence in occurrences:
        occurrence['breadcrumbs'] = _dicts(occurrence.get('breadcrumbs'))
    return render(request, 'control_panel/client_error_detail.html', {
        'issue_id': str(issue_id),
        'issue': issue,
        'versions': _dicts(data.get('versions')),
        'occurrences': occurrences,
        'platform_labels': PLATFORMS,
        'note_max': NOTE_MAX,
        'version_max': VERSION_MAX,
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=_status(result))


@never_cache
@require_POST
def client_error_status(request, issue_id):
    status = request.POST.get('status', '').strip().lower()
    note = request.POST.get('note', '').strip()
    version = request.POST.get('resolved_in_version', '').strip()
    if status not in STATUS_CHANGES:
        messages.error(request, 'Choose resolve, ignore or reopen.')
        return redirect('client_error_detail', issue_id=issue_id)
    if len(note) > NOTE_MAX:
        messages.error(request, f'Keep the note under {NOTE_MAX} characters.')
        return redirect('client_error_detail', issue_id=issue_id)
    if status != 'resolved':
        version = ''
    if version and (len(version) > VERSION_MAX or not VERSION_RE.match(version)):
        messages.error(request, 'Enter the fixed app version like 1.4.2 or 1.4.2+57.')
        return redirect('client_error_detail', issue_id=issue_id)
    result = GoBFFClient().set_client_error_status(
        str(issue_id), status, resolved_in_version=version or None, note=note or None,
    )
    if result.ok:
        done = STATUS_CHANGES[status]
        if version:
            done += f' in version {version}'
        messages.success(request, f'Issue {done}.')
    elif result.status_code == 403:
        messages.error(request, f'Status change failed: {result.error} '
                                '(only admin and ops_admin operators can change client error status).')
    else:
        messages.error(request, f'Status change failed: {result.error}')
    return redirect('client_error_detail', issue_id=issue_id)
