import {test, expect} from '@playwright/test';
import {manifest, standalonePages, horizontalOverflow, artifactsDir} from './support/site.js';

// Every page in every locale at phone, tablet and desktop widths: no
// horizontal page scroll, header controls never overlap, and the right
// navigation affordance (menu button vs inline nav) is shown.
const viewports = [
  {name: 'phone-360', width: 360, height: 780},
  {name: 'mobile-375', width: 375, height: 812},
  {name: 'tablet-768', width: 768, height: 1024},
  {name: 'desktop-1440', width: 1440, height: 900},
];

async function headerOverlaps(page) {
  return page.evaluate(() => {
    const visible = el => { const r = el.getBoundingClientRect(); const s = getComputedStyle(el); return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none'; };
    const items = [
      ['brand', document.querySelector('.site-header .brand')],
      ['language', document.querySelector('.site-header .lang-switch select')],
      ...[...document.querySelectorAll('.site-header .nav-actions > a')].map((a, i) => [`action${i}:${a.textContent.trim()}`, a]),
      ['menu', document.querySelector('.site-header .menu-toggle')],
      ...[...document.querySelectorAll('.site-header .navigation > a')].map((a, i) => [`nav${i}:${a.textContent.trim()}`, a]),
    ].filter(([, el]) => el && visible(el));
    const header = document.querySelector('.site-header').getBoundingClientRect();
    const overlaps = [];
    for (let i = 0; i < items.length; i++) {
      const a = items[i][1].getBoundingClientRect();
      if (a.left < header.left - 1 || a.right > header.right + 1) overlaps.push(`${items[i][0]} outside header`);
      for (let j = i + 1; j < items.length; j++) {
        const b = items[j][1].getBoundingClientRect();
        const x = Math.min(a.right, b.right) - Math.max(a.left, b.left);
        const y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
        if (x > 1 && y > 1) overlaps.push(`${items[i][0]} × ${items[j][0]}`);
      }
    }
    return overlaps;
  });
}

// WEB-04 (fixed): between 761px and 1000px the inline header (nav + language
// picker + Sign in + Get started) was wider than the viewport in long-label
// locales. Up to 1000px the nav now collapses behind the menu button.
const tabletHeaderLocales = ['de', 'fr', 'ru', 'pt'];

test('WEB-04: tablet header fits at 768px in long-label locales', async ({page}) => {
  await page.setViewportSize({width: 768, height: 1024});
  const failures = [];
  for (const locale of manifest.locales.filter(l => tabletHeaderLocales.includes(l.hreflang))) {
    await page.goto(locale.pages.index.url);
    await page.evaluate(() => document.fonts.ready);
    const overflow = await horizontalOverflow(page);
    if (overflow.scrollWidth > 769) failures.push(`${locale.hreflang}: ${overflow.scrollWidth}px ${overflow.offenders.join(', ')}`);
  }
  expect(failures).toEqual([]);
});

test('WEB-04: menu button drives the nav up to 1000px, inline nav from 1001px', async ({page}) => {
  for (const locale of manifest.locales.filter(l => tabletHeaderLocales.includes(l.hreflang))) {
    const menu = page.getByRole('button', {name: locale.openMenu, exact: true});
    const firstLink = page.getByRole('navigation', {name: locale.navLabel, exact: true}).getByRole('link', {name: locale.nav[0], exact: true});
    for (const width of [761, 1000]) {
      await page.setViewportSize({width, height: 900});
      await page.goto(locale.pages.index.url);
      await expect(menu).toBeVisible();
      await expect(firstLink).toBeHidden();
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'true');
      await expect(firstLink).toBeVisible();
      expect((await horizontalOverflow(page)).scrollWidth, `${locale.hreflang} @${width} open menu`).toBeLessThanOrEqual(width + 1);
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'false');
      await expect(firstLink).toBeHidden();
    }
    await page.setViewportSize({width: 1001, height: 900});
    await page.goto(locale.pages.index.url);
    await page.evaluate(() => document.fonts.ready);
    await expect(menu).toBeHidden();
    await expect(firstLink).toBeVisible();
    expect((await horizontalOverflow(page)).scrollWidth, `${locale.hreflang} @1001`).toBeLessThanOrEqual(1002);
  }
});

for (const viewport of viewports) {
  for (const locale of manifest.locales) {
    test(`${locale.hreflang} pages fit ${viewport.name}`, async ({page}) => {
      await page.setViewportSize(viewport);
      const failures = [];
      for (const p of manifest.pages) {
        const {url} = locale.pages[p];
        await page.goto(url);
        await page.evaluate(() => document.fonts.ready);
        const overflow = await horizontalOverflow(page);
        if (overflow.scrollWidth > overflow.innerWidth + 1) failures.push(`${url}: scrollWidth ${overflow.scrollWidth} > ${overflow.innerWidth} ${overflow.offenders.join(', ')}`);
        const overlaps = await headerOverlaps(page);
        if (overlaps.length) failures.push(`${url}: header overlap ${overlaps.join('; ')}`);
        const broken = await page.locator('img').evaluateAll(imgs => imgs.filter(i => !i.complete || i.naturalWidth === 0).map(i => i.src));
        if (broken.length) failures.push(`${url}: broken images ${broken.join(', ')}`);
        const menuVisible = await page.locator('.menu-toggle').isVisible();
        const navInline = await page.locator('.navigation > a').first().isVisible();
        if (viewport.width <= 1000 && (!menuVisible || navInline)) failures.push(`${url}: phone/tablet should collapse nav behind the menu button`);
        if (viewport.width >= 1024 && (menuVisible || !navInline)) failures.push(`${url}: desktop should show inline nav`);
        if (p === 'index' && (locale.prefix === '' || locale.prefix === 'de')) {
          await page.screenshot({path: `${artifactsDir}/responsive/${locale.hreflang}-${p}-${viewport.name}.png`, fullPage: true});
        }
      }
      expect(failures).toEqual([]);
    });
  }
  test(`standalone pages fit ${viewport.name}`, async ({page}) => {
    await page.setViewportSize(viewport);
    for (const path of standalonePages) {
      await page.goto(path);
      const overflow = await horizontalOverflow(page);
      expect(overflow.scrollWidth, `${path} ${overflow.offenders.join(', ')}`).toBeLessThanOrEqual(overflow.innerWidth + 1);
    }
  });
}

test('open phone menu stays within the viewport and does not cover the header', async ({page}) => {
  for (const width of [360, 375]) {
    await page.setViewportSize({width, height: 780});
    for (const locale of manifest.locales) {
      await page.goto(locale.pages.index.url);
      await page.getByRole('button', {name: locale.openMenu, exact: true}).click();
      const nav = page.locator('.navigation');
      await expect(nav).toBeVisible();
      const box = await nav.boundingBox();
      expect(box.x, `${locale.hreflang}@${width}`).toBeGreaterThanOrEqual(0);
      expect(box.x + box.width, `${locale.hreflang}@${width}`).toBeLessThanOrEqual(width + 1);
      // WCAG 2.5.8 target size: each link is >= 24px tall, or (spacing
      // exception) consecutive link centres are >= 24px apart.
      const boxes = [];
      for (const link of await nav.locator('a').all()) boxes.push(await link.boundingBox());
      boxes.forEach((r, i) => {
        const next = boxes[i + 1];
        const spaced = !next || (next.y + next.height / 2) - (r.y + r.height / 2) >= 24;
        expect(r.height >= 24 || spaced, `${locale.hreflang}@${width} link ${i} target`).toBe(true);
      });
      expect((await horizontalOverflow(page)).scrollWidth).toBeLessThanOrEqual(width + 1);
    }
  }
});
