"""Operator-authored Photo Theme prompts. Member photos are moderated in the Go BFF;
reported entries appear in the Blog Moderation queue as theme_entry cases."""
import re

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient, bff_failure_status

SLUG = re.compile(r'^[a-z0-9][a-z0-9-]{2,47}$')


@never_cache
@require_GET
def photo_themes(request):
    result = GoBFFClient().photo_themes()
    return render(request, 'control_panel/photo_themes.html', {
        'themes': (result.data or {}).get('themes', []) if result.ok else [],
        'error': None if result.ok else result.error,
        'project_name': 'AegisConnect',
    }, status=200 if result.ok else bff_failure_status(result.status_code))


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
