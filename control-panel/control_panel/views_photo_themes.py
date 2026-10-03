"""Operator-authored Photo Theme prompts. Member photos are moderated in the Go BFF;
reported entries appear in the Blog Moderation queue as theme_entry cases."""
import re

from django.contrib import messages
from django.shortcuts import redirect
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from . import listing
from .services.go_client import GoBFFClient
from .views import paged_list

SLUG = re.compile(r'^[a-z0-9][a-z0-9-]{2,47}$')


THEME_LIST = listing.ListSpec(
    name='photo-themes', search_label='Search slug, title or prompt', default_page_size=50,
    filters=(listing.Filter('status', 'Status', (('active', 'Active'), ('archived', 'Archived'))),),
    sorts=(('sort_order', 'Display order'), ('title', 'Title'), ('created_at', 'Created')),
    columns=(listing.Column('id', 'Theme ID', width=38), listing.Column('slug', 'Slug', width=24),
             listing.Column('title', 'Title', width=28), listing.Column('prompt', 'Prompt', width=60),
             listing.Column('status', 'Status', width=10), listing.Column('sort_order', 'Display order', width=12),
             listing.Column('entry_count', 'Live photos', width=12)),
)


@never_cache
@require_GET
def photo_themes(request):
    """Themes in display order (active first), paged by Go."""
    return paged_list(request, THEME_LIST, GoBFFClient().photo_themes, items_key='themes',
                      template='control_panel/photo_themes.html', title='Photo themes', context_name='themes',
                      base_context=lambda: {'project_name': 'AegisConnect'}, ascending=True, failure_status=True)


@never_cache
@require_POST
def photo_theme_save(request):
    slug = request.POST.get('slug', '').strip()
    title = request.POST.get('title', '').strip()
    prompt = request.POST.get('prompt', '').strip()
    status = request.POST.get('status', 'active')
    try:
        sort_order = int(request.POST.get('sort_order', '0'))
        if not SLUG.match(slug) or not 3 <= len(title) <= 60 or not 3 <= len(prompt) <= 200 \
                or status not in ('active', 'archived') or not -10000 <= sort_order <= 10000:
            raise ValueError()
    except ValueError:
        messages.error(request, 'Use a lowercase slug, a 3–60 character title and a 3–200 character prompt.')
        return redirect('photo_themes')
    result = GoBFFClient().save_photo_theme({
        'slug': slug, 'title': title, 'prompt': prompt, 'status': status, 'sort_order': sort_order,
    })
    (messages.success if result.ok else messages.error)(request, 'Theme saved.' if result.ok else result.error)
    return redirect('photo_themes')
