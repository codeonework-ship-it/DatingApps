import {test, expect} from '@playwright/test';
import {generatedPages, standalonePages} from './support/site.js';

// Lightweight accessibility smoke (no axe dependency): document language,
// landmarks, heading structure, image alternatives, accessible names for
// links/buttons/form controls, unique ids and keyboard-reachable skip link.
// It is a smoke test, not a WCAG audit.
function audit() {
  const problems = [];
  const describe = el => `${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}${el.getAttribute('href') ? `[href="${el.getAttribute('href')}"]` : ''}`;
  const hidden = el => !!el.closest('[hidden],[aria-hidden="true"]') || getComputedStyle(el).display === 'none';
  const textOf = el => {
    if (el.nodeType === Node.TEXT_NODE) return el.textContent;
    if (el.nodeType !== Node.ELEMENT_NODE || el.getAttribute('aria-hidden') === 'true') return '';
    if (el.tagName === 'IMG') return el.getAttribute('alt') || '';
    return [...el.childNodes].map(textOf).join(' ');
  };
  const name = el => {
    const labelledby = el.getAttribute('aria-labelledby');
    if (labelledby) return labelledby.split(/\s+/).map(id => document.getElementById(id)?.textContent || '').join(' ').trim();
    if (el.getAttribute('aria-label')?.trim()) return el.getAttribute('aria-label').trim();
    if (['INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)) {
      const labels = [...(el.labels || [])].map(l => l.textContent.trim()).join(' ');
      return (labels || el.getAttribute('title') || '').trim();
    }
    return (textOf(el).replace(/\s+/g, ' ').trim() || el.getAttribute('title') || '').trim();
  };

  const lang = document.documentElement.getAttribute('lang');
  if (!lang || !/^[a-z]{2,3}(-[A-Za-z]{2,4})?$/.test(lang)) problems.push(`html lang invalid: "${lang}"`);
  if (!document.title.trim()) problems.push('empty <title>');
  if (document.querySelectorAll('main').length !== 1) problems.push(`expected 1 <main>, found ${document.querySelectorAll('main').length}`);
  if (document.querySelectorAll('h1').length !== 1) problems.push(`expected 1 <h1>, found ${document.querySelectorAll('h1').length}`);
  if (!document.querySelector('meta[name=viewport]')?.content.includes('width=device-width')) problems.push('missing responsive viewport meta');
  if (/user-scalable\s*=\s*no|maximum-scale\s*=\s*1(\.0)?\b/.test(document.querySelector('meta[name=viewport]')?.content || '')) problems.push('viewport disables zoom');

  // Heading levels never skip downwards (h2 → h4).
  let previous = 0;
  for (const h of document.querySelectorAll('h1,h2,h3,h4,h5,h6')) {
    if (hidden(h)) continue;
    const level = Number(h.tagName[1]);
    if (previous && level > previous + 1) problems.push(`heading skips from h${previous} to h${level}: "${h.textContent.trim().slice(0, 40)}"`);
    if (!h.textContent.trim() && !h.id) problems.push(`empty ${h.tagName.toLowerCase()}`);
    previous = level;
  }
  for (const img of document.querySelectorAll('img')) {
    if (!img.hasAttribute('alt')) problems.push(`img without alt: ${img.getAttribute('src')}`);
  }
  for (const el of document.querySelectorAll('a[href], button, [role=button], summary')) {
    if (hidden(el)) continue;
    if (!name(el)) problems.push(`no accessible name: ${describe(el)}`);
  }
  for (const el of document.querySelectorAll('input:not([type=hidden]), select, textarea')) {
    if (hidden(el)) continue;
    if (!name(el)) problems.push(`unlabelled form control: ${describe(el)}`);
  }
  const ids = [...document.querySelectorAll('[id]')].map(e => e.id);
  for (const id of new Set(ids.filter((id, i) => ids.indexOf(id) !== i))) problems.push(`duplicate id: ${id}`);
  for (const el of document.querySelectorAll('[aria-labelledby],[aria-describedby],[aria-controls],label[for]')) {
    for (const attr of ['aria-labelledby', 'aria-describedby', 'aria-controls', 'for']) {
      for (const id of (el.getAttribute(attr) || '').split(/\s+/).filter(Boolean)) {
        if (!document.getElementById(id)) problems.push(`${attr} points at missing #${id}`);
      }
    }
  }
  for (const el of document.querySelectorAll('[tabindex]')) {
    if (Number(el.getAttribute('tabindex')) > 0) problems.push(`positive tabindex: ${describe(el)}`);
  }
  // Same visible link text should not lead to different places within one landmark.
  return problems;
}

// WEB-05 (fixed): features/safety/membership card titles are <h2>s under the
// page <h1>, so heading levels never skip.
test('WEB-05: heading levels never skip on generated pages [case:site.site_header.a11y]', async ({page}) => {
  const skips = [];
  for (const {url} of generatedPages.filter(p => p.locale.prefix === '')) {
    await page.goto(url);
    skips.push(...(await page.evaluate(audit)).filter(p => p.startsWith('heading skips')).map(p => `${url}: ${p}`));
  }
  expect(skips).toEqual([]);
});

for (const {locale, url} of generatedPages) {
  test(`a11y smoke ${url} [${locale.hreflang}] [case:site.site_header.a11y]`, async ({page}) => {
    await page.goto(url);
    expect(await page.evaluate(audit)).toEqual([]);
    // Landmarks: banner, navigation (labelled), main, contentinfo.
    await expect(page.getByRole('banner')).toHaveCount(1);
    await expect(page.getByRole('contentinfo')).toHaveCount(1);
    await expect(page.getByRole('main')).toHaveCount(1);
    await expect(page.locator('nav[aria-label]')).toHaveCount(1);
    // Skip link is the first focusable element and targets <main>.
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toHaveAttribute('href', '#main');
  });
}

for (const path of standalonePages) {
  test(`a11y smoke ${path} [case:site.site_header.a11y]`, async ({page}) => {
    await page.goto(path);
    await page.waitForLoadState('networkidle');
    expect(await page.evaluate(audit)).toEqual([]);
  });
}

test('focus is visible on interactive header controls [case:site.site_header.a11y]', async ({page}) => {
  await page.goto('/');
  for (let i = 0; i < 6; i++) {
    await page.keyboard.press('Tab');
    const outline = await page.evaluate(() => {
      const el = document.activeElement;
      const s = getComputedStyle(el);
      return {tag: el.tagName, outline: s.outlineStyle !== 'none' && parseFloat(s.outlineWidth) > 0, shadow: s.boxShadow !== 'none'};
    });
    expect(outline.outline || outline.shadow, `focus ring on ${outline.tag} #${i}`).toBe(true);
  }
});

// WEB-06 (fixed): the nav landmark label comes from each locale's `nav_label`.
test('WEB-06: the main navigation landmark label is localised [case:site.site_header.a11y]', async ({page}) => {
  const english = [];
  for (const {locale, url, page: name} of generatedPages) {
    if (name !== 'index') continue;
    await page.goto(url);
    await expect(page.locator('nav')).toHaveAttribute('aria-label', locale.navLabel);
    if (!locale.lang.startsWith('en') && locale.navLabel === 'Main navigation') english.push(url);
  }
  expect(english).toEqual([]);
});
