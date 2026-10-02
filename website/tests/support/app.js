// Helpers for the signed-in Flutter web app specs (profile, Today, showcase).
//
// API calls go through the website server's /v1 proxy with Playwright's
// `request` fixture (Node's fetch refuses port 4190). A member's API token is
// taken from the browser's own sign-in response, never from a second login:
// a sign-in invalidates the member's other sessions.
import {expect, test} from '@playwright/test';
import {signIn} from './member.js';
import {artifactsDir} from './site.js';

export const shots = `${artifactsDir}/profile-2026-10-02`;

/** Signs in through the real form and returns that session's access token. */
export async function signInWithToken(page, member) {
  const login = page.waitForResponse(r => r.url().endsWith('/v1/auth/login') && r.request().method() === 'POST');
  await signIn(page, member);
  return (await (await login).json()).access_token;
}

/** API sign-in for fixture setup before the browser signs in as the member. */
export async function apiLogin(request, member) {
  const response = await request.post('/v1/auth/login', {data: {username: member.username, password: member.password}});
  expect(response.status(), 'fixture login').toBe(200);
  return (await response.json()).access_token;
}

export async function api(request, token, method, path, data) {
  const response = await request.fetch(`/v1${path}`, {method, headers: {authorization: `Bearer ${token}`}, data});
  return {status: response.status(), body: await response.json().catch(() => null)};
}

// WEB-12 (open, backend): POST /v1/profile/views is refused with 403 by the
// BFF ownership check, so opening another member's profile logs a console
// error and the view is never recorded. Tracked by its own test.fail() in
// profile-cinematic.spec.js; tolerated (and annotated) everywhere else.
const knownDefects = [{id: 'WEB-12', test: (status, method, url) => status === 403 && method === 'POST' && url.endsWith('/v1/profile/views')}];

/** Page errors, console errors and failed /v1 calls, minus annotated known defects. */
export function watchApp(page, testInfo) {
  const problems = [];
  const known = new Set();
  page.on('pageerror', e => problems.push(`pageerror: ${e.message}`));
  page.on('console', m => {
    // Resource failures are judged from the response itself below.
    if (m.type() !== 'error' || m.text().startsWith('Failed to load resource')) return;
    problems.push(`console: ${m.text()}`);
  });
  page.on('response', r => {
    const url = r.url();
    if (!url.includes('/v1/') || r.status() < 400) return;
    const defect = knownDefects.find(d => d.test(r.status(), r.request().method(), url));
    if (defect) {
      if (!known.has(defect.id)) testInfo.annotations.push({type: 'known defect', description: `${defect.id}: ${r.status()} ${url}`});
      known.add(defect.id);
      return;
    }
    // Shared community images are created/deleted by other suites concurrently.
    if (r.status() === 404 && /\/v1\/media\/approved\/|\/v1\/themes\/[^/]+\/entries\/[^/]+\/photo$/.test(url)) return;
    problems.push(`http ${r.status()}: ${r.request().method()} ${url}`);
  });
  return problems;
}

/** Flutter builds semantics lazily; wheel over the content until `locator` exists. */
export async function scrollUntil(page, locator, {x, y = 600, steps = 25, delta = 400} = {}) {
  const width = page.viewportSize().width;
  for (let i = 0; i < steps && await locator.count() === 0; i++) {
    await page.mouse.move(x ?? Math.round(width * 0.6), y);
    await page.mouse.wheel(0, delta);
    await page.waitForTimeout(150);
  }
  return locator;
}

/**
 * Semantics exist a little beyond the viewport, so "visible" does not mean on
 * screen: wheel until `locator` sits inside the viewport (for screenshots and
 * real clicks). Returns the final bounding box.
 */
export async function bringIntoView(page, locator, {x} = {}) {
  const {width, height} = page.viewportSize();
  let box;
  for (let i = 0; i < 30; i++) {
    box = await locator.boundingBox();
    if (box && box.y >= 70 && box.y + Math.min(box.height, height / 2) <= height - 110) return box;
    const delta = box ? Math.max(-450, Math.min(450, box.y - height / 3)) : 400;
    await page.mouse.move(x ?? Math.round(width * 0.6), height / 2);
    await page.mouse.wheel(0, delta);
    await page.waitForTimeout(200);
  }
  return box;
}

/** Closes the daily rewards toast, waiting briefly because it arrives after the page. */
export async function dismissRewards(page, wait = 0) {
  const toast = page.getByText(/^Your rewards today/);
  if (wait) await toast.waitFor({timeout: wait}).catch(() => {});
  if (await toast.count()) {
    await page.getByRole('button', {name: 'Close', exact: true}).first().click().catch(() => {});
    await expect(toast).toHaveCount(0, {timeout: 5000}).catch(() => {});
  }
}

/** Strict "no horizontal page scroll" (1px tolerance for subpixel rounding). */
export const noOverflow = page => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1);

/** The accessible name of the element that has keyboard focus (first line). */
export const focusedName = page => page.evaluate(() => {
  const e = document.activeElement;
  // Flutter puts a button's text in its content and a switch's in aria-label.
  return e ? `${e.getAttribute('role') ?? e.tagName.toLowerCase()}:${(e.getAttribute('aria-label') || e.textContent || '').split('\n')[0].trim()}` : 'none';
});

/**
 * Tabs until keyboard focus is on (or inside) `locator`; returns whether it
 * got there. Flutter moves focus on its next frame, so each press waits for
 * one: pressing faster leaves focus on the same node for several presses and
 * then skips ahead (a test artifact, not a product defect).
 */
export async function tabTo(page, locator, max = 60) {
  const trail = [];
  for (let i = 0; i < max; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(250);
    if (await locator.evaluate(e => e === document.activeElement || e.contains(document.activeElement))) return true;
    trail.push(await page.evaluate(() => {
      const e = document.activeElement;
      return e ? `${e.tagName.toLowerCase()}[${e.getAttribute('role') ?? ''}] ${(e.getAttribute('aria-label') ?? '').split('\n')[0].slice(0, 30)}` : 'none';
    }));
  }
  test.info().annotations.push({type: 'tab trail', description: trail.join(' → ')});
  return false;
}
