"""Private Chapter evidence is available only through the operator-authenticated BFF."""
from django.contrib import messages
from django.http import HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST
from .services.go_client import GoBFFClient, bff_failure_status


@never_cache
@require_GET
def blog_reviews(request):
    status = request.GET.get('status', 'pending')
    if status not in ('pending', 'removed', 'dismissed', 'restored'):
        return HttpResponse('Unknown review status', status=400)
    try:
        offset = int(request.GET.get('offset', '0'))
        if not 0 <= offset <= 100000:
            raise ValueError()
    except ValueError:
        return HttpResponse('Invalid page', status=400)
    result = GoBFFClient().blog_reviews(status=status, offset=offset)
    return render(request, 'control_panel/blog_reviews.html', {
        **(result.data if result.ok else {}), 'error': result.error,
        'queue_status': status, 'previous': max(0, offset - 100),
        'next': offset + 100, 'offset': offset,
        'project_name': 'AegisConnect',
    }, status=200 if result.ok else bff_failure_status(result.status_code))


@never_cache
@require_POST
def blog_decision(request, case_id):
    note = request.POST.get('note', '').strip()
    decision = request.POST.get('decision', '')
    try:
        version = int(request.POST.get('version', '0'))
        if version < 1 or decision not in ('removed', 'dismissed', 'restored') or not 5 <= len(note) <= 1000:
            raise ValueError()
    except ValueError:
        messages.error(request, 'Choose a decision, record a reason and refresh the case version.')
        return redirect('blog_reviews')
    result = GoBFFClient().blog_decision(str(case_id), {
        'expected_version': version, 'decision': decision, 'note': note,
    })
    (messages.success if result.ok else messages.error)(request, 'Review decision recorded.' if result.ok else result.error)
    return redirect('blog_reviews')


@never_cache
@require_GET
def blog_evidence(request, case_id, photo_id):
    result = GoBFFClient().blog_evidence(str(case_id), str(photo_id))
    if not result.ok:
        return HttpResponse('Evidence unavailable', status=bff_failure_status(result.status_code), content_type='text/plain')
    if result.content_type not in ('image/jpeg', 'image/png', 'image/webp'):
        return HttpResponse('Unsupported evidence type', status=415)
    response = HttpResponse(result.content, content_type=result.content_type)
    response['X-Content-Type-Options'] = 'nosniff'
    response['Cache-Control'] = 'private, no-store'
    return response
