"""Private Chapter evidence is available only through the operator-authenticated BFF."""
from django.contrib import messages
from django.http import HttpResponse
from django.shortcuts import redirect
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST
from . import listing
from .services.go_client import GoBFFClient, bff_failure_status
from .views import paged_list


QUEUE_STATUSES = (('pending', 'Needs review'), ('removed', 'Removed'), ('dismissed', 'Dismissed'), ('restored', 'Restored'))
# The kinds of content a member can report (matching.blog_cases.content_type).
CONTENT_TYPES = (('post', 'Chapter'), ('response', 'Response'), ('publication', 'Publication'), ('theme_entry', 'Theme photo'),
                 ('club', 'Club'), ('club_post', 'Club post'), ('review', 'Review'), ('list', 'List'), ('comment', 'Comment'),
                 ('photo_comment', 'Photo comment'), ('social_message', 'Chat message'), ('group', 'Group'))

# Evidence (snapshots and photos) stays on screen only: the export carries
# the case record, never the reported content.
BLOG_LIST = listing.ListSpec(
    name='blog-review-cases', search_label='Search report reason or description',
    filters=(listing.Filter('status', 'Queue', QUEUE_STATUSES, allow_all=False),
             listing.Filter('content_type', 'Content', CONTENT_TYPES),
             listing.Filter('from', 'Reported from (UTC)', kind='date'), listing.Filter('to', 'Reported to (UTC)', kind='date')),
    sorts=(('review_due_at', 'Review due'), ('created_at', 'Reported')),
    columns=(listing.Column('id', 'Case ID', width=38), listing.Column('content_type', 'Content', width=14),
             listing.Column('content_id', 'Content ID', width=38), listing.Column('subject_id', 'Subject member ID', width=38),
             listing.Column('reason', 'Reason', width=20), listing.Column('description', 'Report description', width=50),
             listing.Column('status', 'Status', width=12), listing.Column('overdue', 'Overdue', width=8),
             listing.Column('decision_note', 'Latest decision note', width=40), listing.Column('appeal', 'Appeal', width=40),
             listing.Column('version', 'Version', width=8), listing.Column('evidence_purged', 'Evidence purged', width=10),
             listing.Column('created_at', 'Reported (UTC)', width=22), listing.Column('review_due_at', 'Review due (UTC)', width=22)),
)


@never_cache
@require_GET
def blog_reviews(request):
    """The report queue, due soonest first, paged by Go."""
    def go(query):
        params = query.go_params()
        params['status'] = params.get('status') or 'pending'
        return params

    def extra(page, data):
        return {'metrics': data.get('metrics') or {} if not page.error else {},
                'queue_status': page.query.filters.get('status') or 'pending',
                'queue_label': dict(QUEUE_STATUSES).get(page.query.filters.get('status') or 'pending')}

    return paged_list(request, BLOG_LIST, GoBFFClient().blog_reviews, items_key='cases',
                      template='control_panel/blog_reviews.html', title='Blog review cases', context_name='cases',
                      base_context=lambda: {'project_name': 'AegisConnect'}, map_filters=go, extra=extra,
                      ascending=True, failure_status=True)


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
