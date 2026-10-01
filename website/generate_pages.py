"""Static site generator for the Connect website.

Emits every page once per locale (see `locales/__init__.py`): en-US at the
site root (`public/<page>.html`, unchanged paths) and each other locale
under `public/<prefix>/<page>.html`. Every page declares `<html lang>`,
`hreflang` alternates (plus `x-default`) and carries a language switcher in
the header. Page copy comes from `locales/<lang>.py`; the layout and the
feature list structure are shared.
"""
import importlib
import sys
from html import escape
from pathlib import Path

here = Path(__file__).resolve().parent
root = here / 'public'
sys.path.insert(0, str(here))
from locales import LOCALES  # noqa: E402

PAGES = ['index', 'features', 'safety', 'privacy', 'guidelines', 'membership']
EXPECTED_FEATURES = 31


def load_locales():
    """Return [(prefix, module)], validated against the en source."""
    source = importlib.import_module('locales.en')
    loaded = []
    for prefix, name in LOCALES:
        module = importlib.import_module(f'locales.{name}')
        missing = set(source.STRINGS) - set(module.STRINGS)
        extra = set(module.STRINGS) - set(source.STRINGS)
        if missing or extra:
            raise SystemExit(f'locales/{name}.py: missing {sorted(missing)}, extra {sorted(extra)}')
        if len(module.FEATURES) != EXPECTED_FEATURES:
            raise SystemExit(f'locales/{name}.py: {len(module.FEATURES)} features, expected {EXPECTED_FEATURES}')
        for (p1, _, _, i1, b1), (p2, _, _, i2, b2) in zip(source.FEATURES, module.FEATURES):
            if (p1, i1, b1) != (p2, i2, b2):
                raise SystemExit(f'locales/{name}.py: feature paths/icons/badges must match en')
        loaded.append((prefix, module))
    return loaded


def page_url(prefix, page, anchor=''):
    """Public URL of a page in a locale: '/features', '/de/features', '/de/'."""
    base = f'/{prefix}' if prefix else ''
    if page == 'index':
        return f'{base}/{anchor}'
    return f'{base}/{page}{anchor}'


def layout(loc, all_locales, page, title, description, content, active=''):
    prefix, mod = loc
    t = mod.STRINGS
    u = lambda p, anchor='': page_url(prefix, p, anchor)
    nav_items = [(t['nav_features'], u('features')), (t['nav_how'], u('index', '#how-it-works')), (t['nav_safety'], u('safety'))]
    nav = ''.join(f'<a href="{url}"' + (' aria-current="page"' if active == key else '') + f'>{label}</a>'
                  for (label, url), key in zip(nav_items, ['features', 'how', 'safety']))
    alternates = ''.join(f'<link rel="alternate" hreflang="{m.HREFLANG}" href="{page_url(p, page)}">' for p, m in all_locales)
    alternates += f'<link rel="alternate" hreflang="x-default" href="{page_url("", page)}">'
    options = ''.join(f'<option value="{page_url(p, page)}"' + (' selected' if p == prefix else '') + f' lang="{m.LANG}">{escape(m.NATIVE_NAME)}</option>'
                      for p, m in all_locales)
    switcher = f'<label class="lang-switch"><span class="visually-hidden">{escape(t["lang_label"])}</span><select aria-label="{escape(t["lang_label"])}" data-lang-switch>{options}</select></label>'
    return f'''<!doctype html><html lang="{mod.LANG}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#f6f7f2"><meta name="description" content="{escape(description)}"><meta property="og:title" content="{escape(title)} · Connect"><meta property="og:description" content="{escape(description)}"><meta property="og:type" content="website"><meta property="og:locale" content="{mod.HREFLANG.replace('-', '_')}"><title>{escape(title)} · Connect</title>{alternates}<link rel="icon" href="/assets/mark.svg" type="image/svg+xml"><link rel="preload" href="/assets/Figtree-Regular.ttf" as="font" type="font/ttf" crossorigin><link rel="stylesheet" href="/styles.css"><script src="/site.js" defer></script></head><body>
<a class="skip" href="#main">{t['skip']}</a><header class="site-header"><div class="container header-inner"><a class="brand" href="{u('index')}" aria-label="{escape(t['brand_home'])}"><img src="/assets/mark.svg" width="38" height="38" alt="">connect</a><nav class="navigation" id="main-navigation" aria-label="Main navigation">{nav}</nav><div class="nav-actions">{switcher}<a href="/app/#/signin">{t['sign_in']}</a><a class="button" href="/app/#/signup">{t['get_started']} <span aria-hidden="true">↗</span></a><button class="menu-toggle" aria-expanded="false" aria-controls="main-navigation" aria-label="{escape(t['open_menu'])}">☰</button></div></div></header>
<main id="main">{content}</main>
<footer class="site-footer"><div class="container"><div class="footer-top"><div><a class="brand" href="{u('index')}"><img src="/assets/mark.svg" width="38" height="38" alt="">connect</a><p>{t['footer_tagline']}</p></div><div class="footer-links"><div><strong>{t['footer_discover']}</strong><a href="{u('features')}">{t['footer_all_features']}</a><a href="{u('index', '#how-it-works')}">{t['footer_how']}</a><a href="{u('membership')}">{t['footer_membership']}</a><a href="/app/#/signin">{t['footer_open']}</a></div><div><strong>{t['footer_control']}</strong><a href="{u('safety')}">{t['footer_safety']}</a><a href="{u('privacy')}">{t['footer_privacy']}</a><a href="{u('guidelines')}">{t['footer_guidelines']}</a><a href="/app/#/help">{t['footer_help']}</a></div></div></div><div class="footer-bottom"><span>{t['footer_copy']}</span><span>{t['footer_promise']}</span></div></div></footer></body></html>'''


def cta(t):
    return f'<section class="section"><div class="container"><div class="cta-panel"><div><h2>{t["cta_h2"]}</h2><p>{t["cta_p"]}</p></div><a class="button" href="/app/#/signup">{t["cta_button"]} <span aria-hidden="true">↗</span></a></div></div></section>'


def home(loc):
    prefix, mod = loc
    t = mod.STRINGS
    u = lambda p, anchor='': page_url(prefix, p, anchor)
    return f'''<div class="container hero"><div><div class="eyebrow">{t['hero_eyebrow']}</div><h1>{t['hero_h1']}</h1><p>{t['hero_p']}</p><div class="hero-actions"><a class="button" href="/app/#/signup">{t['hero_cta']} <span aria-hidden="true">↗</span></a><a class="text-link" href="#how-it-works">{t['hero_how']} <span aria-hidden="true">↓</span></a></div><div class="hero-note"><span>{t['hero_note_1']}</span><span>{t['hero_note_2']}</span><span>{t['hero_note_3']}</span></div></div><div class="hero-photo"><img src="/assets/cafe.png" width="1086" height="1448" fetchpriority="high" alt="{escape(t['hero_alt'])}"><div class="photo-note">{t['photo_note']}<span aria-hidden="true">↗</span></div></div></div>
<section class="section border" id="how-it-works"><div class="container"><div class="section-head"><div><div class="eyebrow">{t['how_eyebrow']}</div><h2>{t['how_h2']}</h2></div><p>{t['how_p']}</p></div><div class="grid"><article class="card"><span class="number">{t['how_1_num']}</span><h3>{t['how_1_h3']}</h3><p>{t['how_1_p']}</p><a class="text-link" href="/app/#/signup">{t['how_1_link']} ↗</a></article><article class="card"><span class="number">{t['how_2_num']}</span><h3>{t['how_2_h3']}</h3><p>{t['how_2_p']}</p><a class="text-link" href="/app/#/discover">{t['how_2_link']} ↗</a></article><article class="card"><span class="number">{t['how_3_num']}</span><h3>{t['how_3_h3']}</h3><p>{t['how_3_p']}</p><a class="text-link" href="/app/#/engagement">{t['how_3_link']} ↗</a></article></div></div></section>
<section class="section"><div class="container"><div class="feature-banner"><div><div class="eyebrow">{t['banner_eyebrow']}</div><h2>{t['banner_h2']}</h2><p>{t['banner_p']}</p><a class="button" href="{u('features')}">{t['banner_button']} <span aria-hidden="true">↗</span></a></div><ul class="feature-list"><li><span class="check" aria-hidden="true">✓</span><div><strong>{t['banner_1_strong']}</strong><p>{t['banner_1_p']}</p></div></li><li><span class="check" aria-hidden="true">✓</span><div><strong>{t['banner_2_strong']}</strong><p>{t['banner_2_p']}</p></div></li><li><span class="check" aria-hidden="true">✓</span><div><strong>{t['banner_3_strong']}</strong><p>{t['banner_3_p']}</p></div></li></ul></div></div></section>
<section class="section dark-section"><div class="container safety-layout"><div><div class="eyebrow">{t['safety_eyebrow']}</div><h2>{t['safety_h2']}</h2><p>{t['safety_p']}</p><a class="button lime" href="{u('safety')}">{t['safety_button']} <span aria-hidden="true">↗</span></a></div><div class="safety-links"><a href="/app/#/safety"><div>{t['safety_link_1']}<small>{t['safety_link_1_small']}</small></div><span aria-hidden="true">↗</span></a><a href="/app/#/trust"><div>{t['safety_link_2']}<small>{t['safety_link_2_small']}</small></div><span aria-hidden="true">↗</span></a><a href="{u('privacy')}"><div>{t['safety_link_3']}<small>{t['safety_link_3_small']}</small></div><span aria-hidden="true">↗</span></a></div></div></section>
<section class="section"><div class="container faq-layout"><div><div class="eyebrow">{t['faq_eyebrow']}</div><h2>{t['faq_h2']}</h2></div><div>''' + ''.join(
        f'<details><summary>{t[f"faq_{i}_q"]}</summary><p>{t[f"faq_{i}_a"]}</p></details>' for i in range(1, 6)
    ) + '</div></div></section>' + cta(t)


def features(loc):
    prefix, mod = loc
    t = mod.STRINGS
    cards = ''.join(
        f'''<article class="card feature-card" data-feature><div class="card-icon" aria-hidden="true">{icon}</div><h3>{name}</h3>{f'<span class="badge">{t[badge]}</span>' if badge else ''}<p>{desc}</p><a class="text-link" href="/app/#/{path}">{escape(t['feature_open'].format(name=name.lower()))} ↗</a></article>'''
        for path, name, desc, icon, badge in mod.FEATURES)
    count = len(mod.FEATURES)
    return f'''<div class="container"><div class="page-hero"><div class="eyebrow">{t['features_eyebrow']}</div><h1>{t['features_h1']}</h1><p>{t['features_p']}</p></div><label class="search" for="feature-search"><input id="feature-search" type="search" placeholder="{escape(t['search_placeholder'])}" aria-label="{escape(t['search_label'])}"></label><p id="feature-status" class="status" aria-live="polite" data-count-label="{escape(t['features_count'])}" data-empty-label="{escape(t['features_empty'])}">{escape(t['features_count'].format(n=count))}</p><div class="grid">{cards}</div><div class="section"><p class="notice">{t['features_notice']}</p></div></div>''' + cta(t)


def safety(loc):
    prefix, mod = loc
    t = mod.STRINGS
    u = lambda p, anchor='': page_url(prefix, p, anchor)
    return f'''<div class="container"><div class="page-hero"><div class="eyebrow">{t['safety_page_eyebrow']}</div><h1>{t['safety_h1']}</h1><p>{t['safety_page_p']}</p></div><div class="grid"><article class="card"><div class="card-icon">⊘</div><h3>{t['s_card_1_h3']}</h3><p>{t['s_card_1_p']}</p><a class="text-link" href="/app/#/safety">{t['s_card_1_link']} ↗</a></article><article class="card"><div class="card-icon">✓</div><h3>{t['s_card_2_h3']}</h3><p>{t['s_card_2_p']}</p><a class="text-link" href="/app/#/trust">{t['s_card_2_link']} ↗</a></article><article class="card"><div class="card-icon">◎</div><h3>{t['s_card_3_h3']}</h3><p>{t['s_card_3_p']}</p><a class="text-link" href="/app/#/account">{t['s_card_3_link']} ↗</a></article></div><div class="section article"><h2>{t['s_h2_respect']}</h2><p>{t['s_p_respect']}</p><a class="button secondary" href="{u('guidelines')}">{t['s_button_guidelines']} ↗</a><h2>{t['s_h2_help']}</h2><p>{t['s_p_help']}</p><a class="text-link" href="/app/#/appeals">{t['s_link_appeals']} ↗</a><p class="notice" data-safety-disclaimer>{t['s_disclaimer']}</p></div></div>'''


def privacy(loc):
    prefix, mod = loc
    t = mod.STRINGS
    return f'''<div class="container"><div class="page-hero"><div class="eyebrow">{t['privacy_eyebrow']}</div><h1>{t['privacy_h1']}</h1><p>{t['privacy_p']}</p></div><div class="article"><h2>{t['p_1_h2']}</h2><p>{t['p_1_p']}</p><a class="text-link" href="/app/#/edit-profile">{t['p_1_link']} ↗</a><h2>{t['p_2_h2']}</h2><p>{t['p_2_p']}</p><a class="text-link" href="/app/#/account">{t['p_2_link']} ↗</a><h2>{t['p_3_h2']}</h2><p>{t['p_3_p']}</p><a class="text-link" href="/app/#/notification-settings">{t['p_3_link']} ↗</a><h2>{t['p_4_h2']}</h2><p>{t['p_4_p']}</p><p class="notice">{t['privacy_notice']}</p></div></div>''' + cta(t)


def guidelines(loc):
    prefix, mod = loc
    t = mod.STRINGS
    return f'''<div class="container"><div class="page-hero"><div class="eyebrow">{t['g_eyebrow']}</div><h1>{t['g_h1']}</h1><p>{t['g_p']}</p></div><div class="article"><h2>{t['g_1_h2']}</h2><p>{t['g_1_p']}</p><h2>{t['g_2_h2']}</h2><p>{t['g_2_p']}</p><h2>{t['g_3_h2']}</h2><p>{t['g_3_p']}</p><h2>{t['g_4_h2']}</h2><p>{t['g_4_p']}</p><a class="button" href="/app/#/safety">{t['g_button']} <span>↗</span></a><h2>{t['g_5_h2']}</h2><p>{t['g_5_p']}</p></div></div>''' + cta(t)


def membership(loc):
    prefix, mod = loc
    t = mod.STRINGS
    u = lambda p, anchor='': page_url(prefix, p, anchor)
    return f'''<div class="container"><div class="page-hero"><div class="eyebrow">{t['m_eyebrow']}</div><h1>{t['m_h1']}</h1><p>{t['m_p']}</p></div><div class="grid"><article class="card"><div class="number">{t['m_1_num']}</div><h3>{t['m_1_h3']}</h3><p>{t['m_1_p']}</p><a class="text-link" href="/app/#/signup">{t['m_1_link']} ↗</a></article><article class="card"><div class="number">{t['m_2_num']}</div><h3>{t['m_2_h3']}</h3><p>{t['m_2_p']}</p><a class="text-link" href="/app/#/membership">{t['m_2_link']} ↗</a></article><article class="card"><div class="number">{t['m_3_num']}</div><h3>{t['m_3_h3']}</h3><p>{t['m_3_p']}</p><a class="text-link" href="{u('safety')}">{t['m_3_link']} ↗</a></article></div><div class="section"><p class="notice">{t['m_notice']}</p></div></div>'''


def build(loc, all_locales):
    prefix, mod = loc
    t = mod.STRINGS
    out = root / prefix if prefix else root
    out.mkdir(parents=True, exist_ok=True)
    pages = {
        'index': (t['home_title'], t['home_desc'], home(loc), ''),
        'features': (t['features_title'], t['features_desc'], features(loc), 'features'),
        'safety': (t['safety_title'], t['safety_desc'], safety(loc), 'safety'),
        'privacy': (t['privacy_title'], t['privacy_desc'], privacy(loc), ''),
        'guidelines': (t['g_title'], t['g_desc'], guidelines(loc), ''),
        'membership': (t['m_title'], t['m_desc'], membership(loc), ''),
    }
    assert set(pages) == set(PAGES)
    for page, (title, description, content, active) in pages.items():
        (out / f'{page}.html').write_text(layout(loc, all_locales, page, title, description, content, active), encoding='utf-8')
    return len(mod.FEATURES)


if __name__ == '__main__':
    locales = load_locales()
    for loc in locales:
        count = build(loc, locales)
        prefix = loc[0] or 'root'
        print(f'Generated {len(PAGES)} public pages ({prefix}, lang={loc[1].LANG}) with {count} linked feature entries.')
    print(f'Generated {len(PAGES) * len(locales)} public pages across {len(locales)} locales.')
