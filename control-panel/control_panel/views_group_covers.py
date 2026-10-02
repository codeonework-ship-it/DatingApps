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
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient, bff_failure_status

STATUSES = {'pending': 'Needs review', 'approved': 'Approved'}
DECISIONS = {'approved': 'approved', 'rejected': 'rejected'}
IMAGE_TYPES = ('image/jpeg', 'image/png', 'image/webp')
# The Go decision endpoint keeps reasons under 200 characters.
REASON_MIN, REASON_MAX = 5, 200


@never_cache
@require_GET
def group_covers(request):
    status = request.GET.get('status', 'pending')
    if status not in STATUSES:
        status = 'pending'
    result = GoBFFClient().group_covers(status=status)
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    return render(request, 'control_panel/group_covers.html', {
        'covers': [c for c in data.get('items') or [] if isinstance(c, dict)],
        'statuses': STATUSES.items(),
        'queue_status': status,
        'reason_min': REASON_MIN,
        'reason_max': REASON_MAX,
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=200 if result.ok else bff_failure_status(result.status_code))


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
