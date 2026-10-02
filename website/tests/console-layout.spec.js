// Operator console layout guard (2026-10-02).
//
// Signs in to the Django console (default http://127.0.0.1:8000) as the
// local operator and checks every page at phone, tablet and desktop widths:
//   - nothing is wider than the screen (no horizontal page scroll);
//   - in each form row, controls share one height and their tops line up;
//   - buttons in a form's action row share one height;
//   - KPI values fit their tiles and line up across a row;
//   - templates carry no inline style="" attributes (CSS custom
//     properties for data-driven values, e.g. style="--pct: 40%", are fine).
// Skips when the console isn't running. Credentials: CONSOLE_USER /
// CONSOLE_PASSWORD, defaulting to the local development operator documented
// in control-panel/README.md.
import {test, expect} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const base = process.env.CONSOLE_URL || 'http://127.0.0.1:8000';
const readme = fs.readFileSync(path.resolve('..', 'control-panel', 'README.md'), 'utf8');
const user = process.env.CONSOLE_USER || readme.match(/Username: `([^`]+)`/)[1];
const pass = process.env.CONSOLE_PASSWORD || readme.match(/Password: `([^`]+)`/)[1];

const pages = [
  '', 'users/', 'users/new/', 'verifications/', 'activities/', 'audit/', 'events/',
  'client-errors/', 'appeals/', 'moderation/reports/', 'moderation/media/',
  'moderation/rooms/', 'moderation/group-covers/', 'moderation/blog/', 'catalog/',
  'catalog/new/', 'config/flags/', 'engagement/prompts/', 'engagement/prompts/new/',
  'engagement/nudges/', 'engagement/photo-themes/', 'progression/', 'billing/',
  'billing/packages/new/', 'billing/subscriptions/', 'billing/payments/',
  'billing/revenue/', 'billing/reconciliation/', 'safety/sos/', 'account-recovery/',
  'support/', 'support/dashboard/', 'support/canned/', 'growth/governance/',
  'city-pilot/', 'analytics/', 'analytics/funnel/', 'analytics/retention/',
  'analytics/engagement/', 'analytics/liquidity/', 'analytics/safety/',
  'analytics/data/', 'business/', 'business/subscriptions/', 'business/conversion/',
  'business/coins/', 'business/referrals/', 'business/markets/',
  'business/investor-pack/', 'business/spend/', 'reports/', 'reports/revenue/?mode=all', 'reports/retention/',
  'billing/transactions/',
];

async function consoleUp() {
  try {
    const r = await fetch(`${base}/login/`);
    return r.ok;
  } catch {
    return false;
  }
}

async function signIn(page) {
  await page.goto(`${base}/login/`);
  await page.fill('input[name=username]', user);
  await page.fill('input[name=password]', pass);
  await Promise.all([page.waitForURL((u) => !u.pathname.startsWith('/login')), page.click('button[type=submit]')]);
}

/** Layout problems on the current page, as readable strings. */
async function layoutProblems(page) {
  return page.evaluate(() => {
    const problems = [];
    const W = document.documentElement.clientWidth;
    if (document.documentElement.scrollWidth > W + 1) {
      const culprits = [];
      for (const el of document.querySelectorAll('.page-body *, .topbar *')) {
        const r = el.getBoundingClientRect();
        if (r.width && r.right > W + 1 && ![...el.children].some((c) => c.getBoundingClientRect().right > W + 1)) {
          culprits.push(`${el.tagName.toLowerCase()}.${String(el.className).trim().split(/\s+/).slice(0, 2).join('.')}`);
        }
      }
      problems.push(`page is ${document.documentElement.scrollWidth - W}px wider than the screen: ${[...new Set(culprits)].slice(0, 4).join(', ')}`);
    }
    const visible = (el) => el.offsetParent !== null && el.getBoundingClientRect().height > 0;
    // Controls that sit side by side in a Bootstrap form row.
    for (const row of document.querySelectorAll('form .row, form.row')) {
      const controls = [...row.querySelectorAll(':scope > [class*="col"] > .form-control:not(textarea), :scope > [class*="col"] > .form-select, :scope > [class*="col"] > .glass-input:not(textarea), :scope > [class*="col"] > .glass-select')].filter(visible);
      const lines = new Map();
      for (const c of controls) {
        const r = c.getBoundingClientRect();
        const key = Math.round(r.top / 8);
        if (!lines.has(key)) lines.set(key, []);
        lines.get(key).push(r);
      }
      for (const rects of lines.values()) {
        const heights = new Set(rects.map((r) => Math.round(r.height)));
        if (heights.size > 1) problems.push(`form row controls have different heights: ${[...heights].join('/')}px`);
        const tops = rects.map((r) => r.top);
        if (Math.max(...tops) - Math.min(...tops) > 2) problems.push('form row controls are not top-aligned');
      }
    }
    // KPI tiles: a value never spills out of its tile, and tiles on one
    // line keep their values on one baseline.
    const rows = new Map();
    for (const num of [...document.querySelectorAll('.metric-number')].filter(visible)) {
      if (num.scrollWidth > num.clientWidth + 1) problems.push(`KPI value "${num.textContent.trim()}" is wider than its tile`);
      const tile = num.closest('.metric-tile').getBoundingClientRect();
      const key = `${num.closest('.metric-grid') ? [...document.querySelectorAll('.metric-grid')].indexOf(num.closest('.metric-grid')) : 0}:${Math.round(tile.top)}`;
      if (!rows.has(key)) rows.set(key, []);
      rows.get(key).push(num.getBoundingClientRect().top);
    }
    for (const tops of rows.values()) {
      if (Math.max(...tops) - Math.min(...tops) > 2) problems.push('KPI values in one row are not aligned');
    }
    for (const actions of document.querySelectorAll('.form-actions, .filter-actions')) {
      const heights = new Set([...actions.querySelectorAll('.btn')].filter(visible).map((b) => Math.round(b.getBoundingClientRect().height)));
      if (heights.size > 1) problems.push(`form action buttons have different heights: ${[...heights].join('/')}px`);
    }
    return problems;
  });
}

test.describe('operator console layout', () => {
  test.beforeAll(async () => {
    test.skip(!(await consoleUp()), 'console not running');
  });

  for (const [width, height, label] of [[390, 844, 'phone'], [768, 1024, 'tablet'], [1440, 900, 'desktop']]) {
    test(`every page fits and aligns at ${label} width [case:console.layout.${label}]`, async ({page}) => {
      test.setTimeout(240000);
      await page.setViewportSize({width, height});
      await signIn(page);
      const failures = [];
      for (const p of pages) {
        const response = await page.goto(`${base}/${p}`, {waitUntil: 'networkidle'});
        expect(response?.status(), `${p} status`).toBeLessThan(400);
        for (const problem of await layoutProblems(page)) failures.push(`/${p}: ${problem}`);
      }
      expect(failures).toEqual([]);
    });
  }

  test('phone menu opens and closes [case:console.layout.mobile_menu]', async ({page}) => {
    await page.setViewportSize({width: 390, height: 844});
    await signIn(page);
    const sidebar = page.locator('#sidebar');
    await expect(sidebar).not.toBeInViewport();
    await page.getByRole('button', {name: 'Open menu'}).click();
    await expect(sidebar).toBeInViewport();
    await expect(page.getByRole('link', {name: /User Management/})).toBeVisible();
    await page.getByRole('button', {name: 'Close menu'}).click();
    await expect(sidebar).not.toBeInViewport();
  });

  test('desktop menu folds the sidebar into an icon rail, never hides it [case:console.layout.sidebar_rail]', async ({page}) => {
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page);
    await page.evaluate(() => localStorage.removeItem('console.sidebar'));
    await page.reload();
    const sidebar = page.locator('#sidebar');
    const width = async () => (await sidebar.boundingBox()).width;
    expect(await width()).toBeGreaterThan(200);
    await page.getByRole('button', {name: 'Collapse menu'}).click();
    await expect(page.getByRole('button', {name: 'Expand menu'})).toHaveAttribute('aria-expanded', 'false');
    await expect.poll(width).toBeLessThan(90);
    await expect.poll(width).toBeGreaterThan(56);
    // Every link stays usable: visible icon, an accessible name, a tooltip.
    const reports = page.locator('#sidebar a[href="/moderation/reports/"]');
    await expect(reports).toHaveAccessibleName(/Reports/);
    await expect(reports).toBeVisible();
    await expect(reports).toHaveAttribute('title', 'Reports');
    await expect(page.locator('.sidebar-sign-out')).toBeVisible();
    await page.reload();
    await expect.poll(width).toBeLessThan(90);
    await page.getByRole('button', {name: 'Expand menu'}).click();
    await expect.poll(width).toBeGreaterThan(200);
  });

  test('report actions open in a centred, opaque Bootstrap modal [case:console.layout.report_modal]', async ({page}) => {
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page);
    await page.goto(`${base}/moderation/reports/?status=pending`);
    const action = page.getByRole('button', {name: 'Action', exact: true}).first();
    test.skip(!(await action.count()), 'no pending reports seeded');
    await action.click();
    const dialog = page.getByRole('dialog', {name: 'Action report'});
    await expect(dialog).toBeVisible();
    const box = await dialog.locator('.modal-content').boundingBox();
    expect(Math.abs(box.x + box.width / 2 - 720)).toBeLessThan(4);
    expect(box.y).toBeGreaterThan(0);
    expect(box.y + box.height).toBeLessThan(900);
    const look = await dialog.locator('.modal-content').evaluate((el) => ({
      bg: getComputedStyle(el).backgroundColor, align: getComputedStyle(el.querySelector('label')).textAlign,
      parent: el.closest('.modal').parentElement.tagName,
    }));
    expect(look.bg).toMatch(/^rgb\(/); // opaque, not rgba(…, 0.03)
    expect(look.align).toMatch(/start|left/);
    expect(look.parent).toBe('BODY');
    await dialog.getByRole('button', {name: 'Cancel'}).click();
    await expect(dialog).toBeHidden();
  });

  test('destructive actions confirm in the Bootstrap dialog, not window.confirm [case:console.layout.confirm_dialog]', async ({page}) => {
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page);
    page.on('dialog', () => { throw new Error('a native browser dialog was shown'); });
    await page.goto(`${base}/users/`);
    const del = page.locator('form[data-confirm] button[type=submit]').first();
    test.skip(!(await del.count()), 'no users seeded');
    const url = page.url();
    await del.click();
    const dialog = page.getByRole('dialog', {name: 'Delete this user?'});
    await expect(dialog).toBeVisible();
    await expect(dialog).toContainText('cannot be undone');
    await dialog.getByRole('button', {name: 'Cancel'}).click();
    await expect(dialog).toBeHidden();
    expect(page.url()).toBe(url);
  });

  test('templates carry no inline styles [case:console.layout.no_inline_styles]', () => {
    const dir = path.resolve('..', 'control-panel', 'templates', 'control_panel');
    const offenders = [];
    const walk = (d) => {
      for (const f of fs.readdirSync(d, {withFileTypes: true})) {
        const full = path.join(d, f.name);
        if (f.isDirectory()) walk(full);
        else if (f.name.endsWith('.html')) {
          // Data-driven values may be passed as CSS custom properties only.
          const count = (fs.readFileSync(full, 'utf8').match(/\sstyle="(?!--)/g) || []).length;
          if (count) offenders.push(`${path.relative(dir, full)}: ${count}`);
        }
      }
    };
    walk(dir);
    expect(offenders).toEqual([]);
  });
});
