import {test, expect} from '@playwright/test';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {generatedPages, standalonePages, websiteDir, excluded} from './support/site.js';
import {createMember, signIn} from './support/member.js';

// Crawls every internal href/src (and CSS url() assets) reachable from every
// public page and checks each resolves. Deep links into the web app
// (/app/#/<route>) are checked against the routes the Flutter web workspace
// actually registers, because the server answers 200 for any hash.
const appSource = file => readFileSync(resolve(websiteDir, '..', 'app', 'lib', file), 'utf8');
const workspace = appSource('features/web/web_member_workspace.dart');
const registeredAppRoutes = new Set([
  // WebEntryScreen (signed out) and the workspace's own pages.
  '/', '/signin', '/signup', '/welcome', '/features', '/introducer',
  ...[...workspace.matchAll(/WebDestination\(\s*'(\/[^']*)'/g)].map(m => m[1]),
  ...[...workspace.slice(workspace.indexOf('_primaryPaths')).matchAll(/'(\/[a-z-]+)'/g)].slice(0, 5).map(m => m[1]),
]);

const sources = [...generatedPages.map(p => p.url), ...standalonePages];

test('every internal link, asset and app deep link resolves [case:site.site_header.links_resolve]', async ({page, request}) => {
  test.setTimeout(240000);
  expect(registeredAppRoutes.has('/discover')).toBe(true);
  expect(registeredAppRoutes.has('/settings')).toBe(true);
  const found = new Map(); // url -> first page that referenced it
  const external = new Set();
  for (const source of sources) {
    await page.goto(source);
    const refs = await page.evaluate(() => [
      ...[...document.querySelectorAll('a[href], link[href]')].map(e => e.getAttribute('href')),
      ...[...document.querySelectorAll('[src]')].map(e => e.getAttribute('src')),
      ...[...document.querySelectorAll('[srcset]')].flatMap(e => e.getAttribute('srcset').split(',').map(s => s.trim().split(/\s+/)[0])),
    ]);
    for (const ref of refs) {
      if (!ref || ref.startsWith('mailto:') || ref.startsWith('tel:') || ref.startsWith('data:')) continue;
      const url = new URL(ref, page.url());
      if (url.origin !== new URL(page.url()).origin) { external.add(url.href); continue; }
      const key = url.pathname + url.hash;
      // Pages deliberately left out of the crawl (support/site.js `excluded`; none today).
      if (excluded.test(url.pathname)) continue;
      if (!found.has(key)) found.set(key, source);
    }
  }
  // Stylesheets reference fonts/images by url().
  for (const css of [...found.keys()].filter(k => k.endsWith('.css'))) {
    const body = await (await request.get(css)).text();
    for (const [, ref] of body.matchAll(/url\(\s*["']?([^"')]+)["']?\s*\)/g)) {
      if (ref.startsWith('data:')) continue;
      const key = new URL(ref, `http://127.0.0.1:4190${css}`).pathname;
      if (!found.has(key)) found.set(key, css);
    }
  }

  const broken = [];
  for (const [key, source] of found) {
    const [path, hash = ''] = key.split('#');
    const response = await request.get(path || '/');
    if (response.status() !== 200) broken.push(`${key} (from ${source}) → ${response.status()}`);
    if (path === '/app/' && hash) {
      const route = hash.split('?')[0];
      if (!registeredAppRoutes.has(route)) broken.push(`${key} (from ${source}) → unknown web-app route`);
    }
  }
  expect(found.size).toBeGreaterThan(20);
  expect(broken).toEqual([]);
  // The site is self-contained; any third-party URL needs a CSP change first.
  expect([...external]).toEqual([]);
});

test('same-page and cross-page anchors land on an element [case:site.site_header.links_resolve]', async ({page}) => {
  const anchors = new Set();
  for (const source of sources) {
    await page.goto(source);
    for (const href of await page.locator('a[href*="#"]').evaluateAll(a => a.map(x => x.href))) {
      const url = new URL(href);
      if (!url.pathname.startsWith('/app/') && !excluded.test(url.pathname) && url.hash.length > 1) anchors.add(url.pathname + url.hash);
    }
  }
  expect(anchors.size).toBeGreaterThan(0);
  const missing = [];
  for (const target of anchors) {
    await page.goto(target);
    const id = decodeURIComponent(target.split('#')[1]);
    if (await page.locator(`[id="${id}"]`).count() !== 1) missing.push(target);
  }
  expect(missing).toEqual([]);
});

// The feature cards on /features hand a signed-in member to the web app: each
// link must land on its own workspace page (address kept, real page shown),
// never on "page not found". A card whose capability is switched off by a
// runtime flag shows the app's honest "isn't available yet" page; that is
// recorded as an annotation (the website then advertises a switched-off
// feature), not as a failure.
test('every feature card opens its own page in the signed-in web app [case:site.features.feature_links.deep_links]', async ({page}) => {
  test.setTimeout(300000);
  await page.setViewportSize({width: 1440, height: 900});
  await signIn(page, createMember('qalinks'));
  await page.goto('/features');
  const cards = await page.locator('[data-feature]').evaluateAll(list => list.map(c => ({
    name: c.querySelector('h2').textContent.trim(), href: c.querySelector('a').getAttribute('href'),
  })));
  expect(cards.length).toBeGreaterThan(20);
  const problems = [];
  page.on('pageerror', e => problems.push(`pageerror: ${e.message}`));
  for (const [index, card] of cards.entries()) {
    await test.step(`${card.name} → ${card.href}`, async () => {
      await page.goto('/features');
      await page.locator('[data-feature] a').nth(index).click();
      const route = card.href.split('#')[1];
      await expect(page).toHaveURL(new RegExp(`/app/#${route}$`));
      // Signed in after the reload: the workspace sidebar, not the sign-in form.
      await expect(page.getByRole('button', {name: 'Sign out', exact: true})).toBeVisible({timeout: 30000});
      await expect(page.getByRole('textbox', {name: 'username', exact: true})).toHaveCount(0);
      await expect(page.getByText('This page could not be found.', {exact: true})).toHaveCount(0);
      const unavailable = page.getByText(/ isn't available yet\.$/);
      if (await unavailable.count()) {
        test.info().annotations.push({type: 'feature switched off', description: `${card.name} (${card.href}): ${await unavailable.first().textContent()}`});
        await expect(page.getByRole('button', {name: 'Back to Discover', exact: true})).toBeVisible();
      }
      await expect(page).toHaveURL(new RegExp(`/app/#${route}$`));
    });
  }
  expect(problems).toEqual([]);
});
