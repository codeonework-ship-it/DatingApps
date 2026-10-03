"""Group cover review queue. Members' group cover photos that the automatic
check could not clear wait here as pending; operators approve or reject them.

Everything goes through the Go admin API (/v1/admin/moderation/group-covers...),
which accepts only the admin, moderator and trust_safety roles. Images are
proxied through group_cover_content with the operator's own session, so Go
credentials and storage keys never reach the browser. A rejection hides the
cover at once, releases the stored photo and sends the group owner a notice.
"""
from django.contrib import messages
from django.http import HttpResponse
from django.shortcuts import redirect
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from . import listing
from .services.go_client import GoBFFClient, bff_failure_status
from .views import paged_list

STATUSES = {'pending': 'Needs review', 'approved': 'Approved'}
DECISIONS = {'approved': 'approved', 'rejected': 'rejected'}
IMAGE_TYPES = ('image/jpeg', 'image/png', 'image/webp')
# The Go decision endpoint keeps reasons under 200 characters.
REASON_MIN, REASON_MAX = 5, 200


GROUP_COVER_LIST = listing.ListSpec(
    name='group-covers', search_label='Search group name',
    filters=(listing.Filter('status', 'Queue', tuple(STATUSES.items()), allow_all=False),
             listing.Filter('from', 'Uploaded from (UTC)', kind='date'), listing.Filter('to', 'Uploaded to (UTC)', kind='date')),
    # No sort choice: Go reads the pending queue oldest first and the
    # approved history newest first.
    columns=(listing.Column('cover_id', 'Cover ID', width=38), listing.Column('group_id', 'Group ID', width=38),
             listing.Column('group_name', 'Group', width=28), listing.Column('group_kind', 'Kind', width=12),
             listing.Column('owner_user_id', 'Owner ID', width=38), listing.Column('uploaded_by', 'Uploaded by', width=38),
             listing.Column('status', 'Status', width=12), listing.Column('reason', 'Check note', width=40),
             listing.Column('provider', 'Checked by', width=14), listing.Column('mime_type', 'Type', width=12),
             listing.Column('width_px', 'Width', width=8), listing.Column('height_px', 'Height', width=8),
             listing.Column('size_bytes', 'Bytes', width=10), listing.Column('uploaded_at', 'Uploaded (UTC)', width=22)),
)


@never_cache
@require_GET
def group_covers(request):
    def go(query):
        params = query.go_params()
        params['status'] = params.get('status') or 'pending'
        return params

    def extra(page, data):
        return {'covers': page.rows, 'queue_status': page.query.filters.get('status') or 'pending',
                'reason_min': REASON_MIN, 'reason_max': REASON_MAX}

    return paged_list(request, GROUP_COVER_LIST, GoBFFClient().group_covers, items_key='items',
                      template='control_panel/group_covers.html', title='Group covers', context_name='covers',
                      base_context=lambda: {'project_name': 'AegisConnect'}, map_filters=go, extra=extra,
                      failure_status=True)


@never_cache
@require_GET
def group_cover_content(request, cover_id):
    result = GoBFFClient().group_cover_content(str(cover_id))
    if not result.ok:
        return HttpResponse('Cover unavailable', status=bff_failure_status(result.status_code), content_type='text/plain')
    content_type = (result.content_type or '').split(';')[0].strip().lower()
    if content_type not in IMAGE_TYPES:
        return HttpResponse('Unsupported cover type', status=415)
    response = HttpResponse(result.content, content_type=content_type)
    response['X-Content-Type-Options'] = 'nosniff'
    response['Cache-Control'] = 'private, no-store'
    return response


@never_cache
@require_POST
def group_cover_decision(request, cover_id):
    decision = request.POST.get('decision', '').strip().lower()
    reason = request.POST.get('reason', '').strip()
    if decision not in DECISIONS:
        messages.error(request, 'Choose approve or reject.')
        return redirect('group_covers')
    if decision == 'rejected' and not REASON_MIN <= len(reason) <= REASON_MAX:
        messages.error(request, f'A rejection needs a {REASON_MIN}–{REASON_MAX} character reason.')
        return redirect('group_covers')
    if len(reason) > REASON_MAX:
        messages.error(request, f'Keep the note under {REASON_MAX} characters.')
        return redirect('group_covers')
    result = GoBFFClient().group_cover_decision(str(cover_id), DECISIONS[decision], reason)
    if result.ok:
        if decision == 'approved':
            messages.success(request, f'Cover {cover_id} approved. It now shows on the group.')
        else:
            messages.success(request, f'Cover {cover_id} rejected. It is hidden, the stored photo is released and '
                                      'the group owner has been notified.')
    else:
        messages.error(request, f'Cover decision failed: {result.error}')
    return redirect('group_covers')
