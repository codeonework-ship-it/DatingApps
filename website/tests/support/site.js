// Shared helpers for the public-website specs.
//
// The page × locale list is derived from the generator itself
// (generate_pages.PAGES + locales.LOCALES), never hard-coded, so a new page or
// locale is covered automatically. The manifest also records whether the
// committed public/ output still matches what the generator would emit.
import {execFileSync} from 'node:child_process';
import {readdirSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

export const websiteDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const artifactsDir = resolve(websiteDir, '..', 'qa', 'results', 'playwright');

const manifestScript = String.raw`
import filecmp, html, importlib, json, pathlib, re, sys, tempfile
sys.path.insert(0, '.')
import generate_pages as g
from locales import LOCALES
# Pages whose copy keys are known here. A page added later is listed in
# 'allPages' but only asserted once it is added below (public-pages.spec.js
# fails until it is).
h1_keys = {'index': 'hero_h1', 'features': 'features_h1', 'safety': 'safety_h1',
           'privacy': 'privacy_h1', 'guidelines': 'g_h1', 'membership': 'm_h1', 'contact': 'c_h1'}
title_keys = {'index': 'home_title', 'features': 'features_title', 'safety': 'safety_title',
              'privacy': 'privacy_title', 'guidelines': 'g_title', 'membership': 'm_title', 'contact': 'c_title'}
text = lambda s: re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'<br\s*/?>', ' ', s)))).strip()
pages = [p for p in g.PAGES if p in h1_keys]
out = {'pages': pages, 'allPages': g.PAGES, 'locales': []}
for prefix, name in LOCALES:
    mod = importlib.import_module(f'locales.{name}')
    t = mod.STRINGS
    out['locales'].append({
        'prefix': prefix, 'lang': mod.LANG, 'hreflang': mod.HREFLANG,
        'langLabel': t['lang_label'], 'openMenu': t['open_menu'], 'navLabel': t['nav_label'],
        'nav': [t['nav_features'], t['nav_how'], t['nav_safety']],
        'featureCount': len(mod.FEATURES),
        'urls': [g.page_url(prefix, p) for p in g.PAGES],
        'pages': {p: {'url': g.page_url(prefix, p), 'file': (prefix + '/' if prefix else '') + p + '.html',
                      'title': t[title_keys[p]] + ' · Connect', 'h1': text(t[h1_keys[p]])}
                  for p in pages},
    })
try:
    locales = g.load_locales()
    tmp = pathlib.Path(tempfile.mkdtemp())
    g.root = tmp
    for loc in locales:
        g.build(loc, locales)
    out['stale'] = sorted(str(f.relative_to(tmp)) for f in tmp.rglob('*.html')
                          if not (g.here / 'public' / f.relative_to(tmp)).is_file()
                          or not filecmp.cmp(f, g.here / 'public' / f.relative_to(tmp), shallow=False))
except BaseException as e:  # the generator refuses drifting locales with SystemExit
    out['stale'] = [f'generator failed: {e}']
print(json.dumps(out))
`;

export const manifest = JSON.parse(
  execFileSync('python3', ['-c', manifestScript], {cwd: websiteDir, encoding: 'utf8'}),
);

// Public pages left out of the page × locale crawl. The contact page joined the
// matrix on 2026-10-02 once its form shipped; nothing is excluded today.
export const excluded = /(?!)/;

/** Every generated page in every locale: {locale, page, url, title, h1}. */
export const generatedPages = manifest.locales.flatMap(locale =>
  manifest.pages
    .filter(page => !excluded.test(page))
    .map(page => ({locale, page, ...locale.pages[page]})),
);

/** Hand-written top-level pages in public/ that the generator does not emit. */
export const standalonePages = readdirSync(resolve(websiteDir, 'public'))
  .filter(name => name.endsWith('.html'))
  .filter(name => !manifest.allPages.includes(name.replace(/\.html$/, '')))
  .filter(name => !excluded.test(name))
  .map(name => `/${name}`);

/**
 * Collects uncaught exceptions, console errors and failed/4xx-5xx requests.
 * Call before page.goto; read `.problems()` after the page settles.
 */
export function watchPage(page) {
  const problems = [];
  page.on('pageerror', e => problems.push(`pageerror: ${e.message}`));
  page.on('console', m => { if (m.type() === 'error') problems.push(`console: ${m.text()}`); });
  page.on('requestfailed', r => {
    // Navigations away from the page abort in-flight requests; not a defect.
    if (r.failure()?.errorText === 'net::ERR_ABORTED') return;
    problems.push(`requestfailed: ${r.url()} ${r.failure()?.errorText}`);
  });
  page.on('response', r => { if (r.status() >= 400) problems.push(`http ${r.status()}: ${r.url()}`); });
  return {problems: () => [...problems], clear: () => problems.splice(0)};
}

/** Strict "no horizontal page scroll" check (1px tolerance for subpixel rounding). */
export async function horizontalOverflow(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const offenders = [];
    let onlyHeader = true; // becomes false when anything outside the site header overflows
    if (doc.scrollWidth > innerWidth + 1) {
      for (const el of document.body.querySelectorAll('*')) {
        const r = el.getBoundingClientRect();
        if (r.width && (r.right > innerWidth + 1 || r.left < -1) && getComputedStyle(el).position !== 'fixed') {
          if (!el.closest('.site-header')) onlyHeader = false;
          offenders.push(`${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}${el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).join('.') : ''} [${Math.round(r.left)}..${Math.round(r.right)}]`);
        }
      }
    }
    return {scrollWidth: doc.scrollWidth, innerWidth, headerOnly: onlyHeader && offenders.length > 0, offenders: offenders.slice(0, 8)};
  });
}
