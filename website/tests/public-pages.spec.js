import {test, expect} from '@playwright/test';
import {manifest, generatedPages, standalonePages, watchPage} from './support/site.js';

// Every generated page × every locale: status, document language, title, one
// h1, hreflang alternates, header/footer navigation and a clean console.
const pageUrl = (prefix, page) => manifest.locales.find(l => l.prefix === prefix).pages[page].url;

test('committed public/ pages match the generator output [case:site.generator.output_current]', () => {
  expect(manifest.locales.length).toBeGreaterThan(1);
  expect(generatedPages.length).toBe(manifest.pages.length * manifest.locales.length);
  expect(manifest.pages).toEqual(manifest.allPages);
  // Stale output means a locale/copy change was not regenerated (python3 generate_pages.py).
  expect(manifest.stale).toEqual([]);
});

for (const {locale, page, url, title, h1} of generatedPages) {
  test(`${url} [${locale.hreflang}] renders its locale [case:site.${page}.renders_all_locales] [case:site.site_header.nav_links.every_locale]`, async ({page: tab, request}) => {
    const watch = watchPage(tab);
    const response = await tab.goto(url);
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('text/html');
    await tab.waitForLoadState('networkidle');

    await expect(tab.locator('html')).toHaveAttribute('lang', locale.lang);
    await expect(tab).toHaveTitle(title);
    const h1s = tab.locator('h1');
    await expect(h1s).toHaveCount(1);
    expect((await h1s.innerText()).replace(/\s+/g, ' ').trim()).toBe(h1);
    await expect(tab.locator('meta[name=description]')).toHaveAttribute('content', /\S/);
    await expect(tab.locator('meta[property="og:locale"]')).toHaveAttribute('content', locale.hreflang.replace('-', '_'));

    // hreflang: one per locale + x-default, each pointing at this page in that locale.
    const alternates = await tab.locator('link[rel=alternate][hreflang]').evaluateAll(links =>
      links.map(l => [l.getAttribute('hreflang'), l.getAttribute('href')]));
    expect(alternates).toEqual([
      ...manifest.locales.map(l => [l.hreflang, l.pages[page].url]),
      ['x-default', pageUrl('', page)],
    ]);
    expect(alternates.some(([lang, href]) => lang === locale.hreflang && href === url)).toBe(true);
    for (const [, href] of alternates) expect((await request.head(href)).status(), href).toBe(200);

    // Language switcher: labelled in this locale, current page selected, one option per locale.
    const switcher = tab.getByRole('combobox', {name: locale.langLabel, exact: true});
    await expect(switcher).toHaveValue(url);
    expect(await switcher.locator('option').evaluateAll(o => o.map(x => x.value)))
      .toEqual(manifest.locales.map(l => l.pages[page].url));

    // Header navigation stays inside the locale; the active page is marked.
    const nav = tab.getByRole('navigation', {name: locale.navLabel, exact: true});
    const navLinks = await nav.locator('a').evaluateAll(a => a.map(x => [x.textContent.trim(), x.getAttribute('href'), x.getAttribute('aria-current')]));
    expect(navLinks.map(([label]) => label)).toEqual(locale.nav);
    expect(navLinks.map(([, href]) => href)).toEqual([
      locale.pages.features.url, `${locale.pages.index.url}#how-it-works`, locale.pages.safety.url,
    ]);
    const current = navLinks.filter(([, , c]) => c === 'page').map(([, href]) => href);
    expect(current).toEqual(['features', 'safety'].includes(page) ? [url] : []);
    await expect(tab.locator('header .brand')).toHaveAttribute('href', locale.pages.index.url);
    await expect(tab.locator(`header a[href="/app/?lang=${locale.hreflang}#/signin"]`)).toHaveCount(1);
    await expect(tab.locator(`header a[href="/app/?lang=${locale.hreflang}#/signup"]`)).toHaveCount(1);
    // Every link into the app carries this page's language (the app's wire tag),
    // so the loader and first frame match the page the visitor came from.
    const appLinks = await tab.locator('a[href^="/app"]').evaluateAll(a => a.map(x => x.getAttribute('href')));
    expect(appLinks.length).toBeGreaterThan(0);
    expect(appLinks.filter(href => !href.startsWith(`/app/?lang=${locale.hreflang}#/`))).toEqual([]);

    // Footer: same-locale public pages plus the app entry points.
    const footer = await tab.locator('footer.site-footer a').evaluateAll(a => a.map(x => x.getAttribute('href')));
    const local = locale.urls;
    for (const href of footer) {
      const path = href.split('#')[0];
      expect(path.startsWith('/app/') || local.includes(path), `footer link ${href} leaves ${locale.hreflang}`).toBe(true);
    }
    for (const p of ['features', 'membership', 'safety', 'privacy', 'guidelines']) {
      expect(footer, `footer links ${p}`).toContain(locale.pages[p].url);
    }

    // Same-page anchors resolve to an element on this page.
    const missingAnchors = await tab.locator('a[href^="#"]').evaluateAll(a =>
      a.map(x => x.getAttribute('href').slice(1)).filter(id => id && !document.getElementById(id)));
    expect(missingAnchors).toEqual([]);

    expect(watch.problems()).toEqual([]);
  });
}

for (const path of standalonePages) {
  test(`standalone page ${path} loads with a language and one h1 [case:site.${path.slice(1, -5)}.idle_state]`, async ({page}) => {
    const watch = watchPage(page);
    // These pages fetch member content by query id; with none they show their idle state.
    expect((await page.goto(path)).status()).toBe(200);
    await page.waitForLoadState('networkidle');
    await expect(page.locator('html')).toHaveAttribute('lang', /^[a-z]{2}(-[A-Z]{2})?$/);
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page).toHaveTitle(/· Connect$/);
    expect(watch.problems()).toEqual([]);
  });
}

test('locale switcher moves between every locale on the same page [case:site.site_header.language_switch.moves_locale]', async ({page}) => {
  const order = manifest.locales;
  for (const [i, locale] of order.entries()) {
    const next = order[(i + 1) % order.length];
    for (const p of ['index', 'features']) {
      await page.goto(locale.pages[p].url);
      await page.getByRole('combobox', {name: locale.langLabel, exact: true}).selectOption(next.pages[p].url);
      await expect(page).toHaveURL(new URL(next.pages[p].url, 'http://127.0.0.1:4190').href);
      await expect(page.locator('html')).toHaveAttribute('lang', next.lang);
      await expect(page).toHaveTitle(next.pages[p].title);
    }
  }
});

test('locale homes and .html aliases resolve; unknown locale is a 404 [case:site.site_header.links_resolve]', async ({request}) => {
  for (const locale of manifest.locales) {
    for (const p of manifest.pages) {
      const {url, file} = locale.pages[p];
      expect((await request.get(url)).status(), url).toBe(200);
      expect((await request.get(`/${file}`)).status(), file).toBe(200);
    }
    if (locale.prefix) expect((await request.get(`/${locale.prefix}`)).status(), `/${locale.prefix} (no slash)`).not.toBe(500);
  }
  expect((await request.get('/xx/features')).status()).toBe(404);
});

test('features page lists every feature in every locale and search works [case:site.features.search.filters] [case:site.features.renders_all_locales]', async ({page}) => {
  for (const locale of manifest.locales) {
    await page.goto(locale.pages.features.url);
    await expect(page.locator('[data-feature]')).toHaveCount(locale.featureCount);
    const search = page.locator('#feature-search');
    await expect(search).toHaveAccessibleName(/\S/);
    await search.fill('zzzz-no-such-feature');
    await expect(page.locator('[data-feature]:visible')).toHaveCount(0);
    await expect(page.locator('#feature-status')).not.toHaveText('');
    await expect(page.locator('#feature-status')).not.toContainText('{n}');
    await search.fill('');
    await expect(page.locator('[data-feature]:visible')).toHaveCount(locale.featureCount);
    await expect(page.locator('#feature-status')).toContainText(String(locale.featureCount));
  }
});

test('header navigation, skip link and mobile menu work in every locale [case:site.site_header.nav_links.every_locale] [case:site.site_header.menu_toggle.mobile]', async ({page}) => {
  for (const locale of manifest.locales) {
    await page.setViewportSize({width: 1440, height: 900});
    await page.goto(locale.pages.index.url);
    const nav = page.getByRole('navigation', {name: locale.navLabel, exact: true});
    await nav.getByRole('link', {name: locale.nav[0], exact: true}).click();
    await expect(page).toHaveURL(new RegExp(`${locale.pages.features.url}$`));
    await nav.getByRole('link', {name: locale.nav[2], exact: true}).click();
    await expect(page).toHaveURL(new RegExp(`${locale.pages.safety.url}$`));
    await nav.getByRole('link', {name: locale.nav[1], exact: true}).click();
    await expect(page).toHaveURL(new RegExp(`${locale.pages.index.url}#how-it-works$`));
    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${locale.pages.safety.url}$`));
    await page.locator('footer .brand').click();
    await expect(page).toHaveURL(new RegExp(`${locale.pages.index.url}$`));

    await page.keyboard.press('Tab');
    const skip = page.locator('a.skip');
    await expect(skip).toBeFocused();
    await expect(skip).toBeVisible();
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL(/#main$/);

    await page.setViewportSize({width: 375, height: 800});
    await page.goto(locale.pages.index.url);
    const menu = page.getByRole('button', {name: locale.openMenu, exact: true});
    await expect(menu).toBeVisible();
    await expect(nav.getByRole('link', {name: locale.nav[0], exact: true})).toBeHidden();
    await menu.click();
    await expect(menu).toHaveAttribute('aria-expanded', 'true');
    await expect(nav.getByRole('link', {name: locale.nav[0], exact: true})).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
    await expect(nav.getByRole('link', {name: locale.nav[0], exact: true})).toBeHidden();
  }
});

// WEB-07 (fixed): German nouns keep their capital inside "{name} öffnen".
test('WEB-07: German feature links keep noun capitalisation [case:site.features.renders_all_locales]', async ({page}) => {
  await page.goto('/de/features');
  const links = await page.locator('[data-feature]').evaluateAll(cards => cards.map(c => [c.querySelector('h2').textContent, c.querySelector('a').textContent]));
  const lowered = links.filter(([name, link]) => !link.includes(name)).map(([, link]) => link.trim());
  expect(lowered).toEqual([]);
});
