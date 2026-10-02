// QA Lab (website/qa-lab): operator sign-in, coverage, case browser, a real
// run with live progress, run history, manual checklist, phone width, theme.
//
// The spec starts its own website server with QA_LAB=1 on a spare port and an
// isolated results directory, so it never touches the shared 4190 server or
// the real qa/results/qa_lab history; it stops the server afterwards. The run
// it starts uses the "selftest" suite (QA Lab's own node:test unit tests), so
// it is fast and needs no emulator. Operator sign-in goes through the real
// gateway (/v1/auth/login) and the BFF role list, as local_control_admin.
import {test, expect} from '@playwright/test';
import {spawn} from 'node:child_process';
import {mkdtempSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import net from 'node:net';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {websiteDir} from './support/site.js';

const repo = resolve(websiteDir, '..');
const operator = {
  username: process.env.LOCAL_OPERATOR_USERNAME || 'local_control_admin',
  // Local test credential: provisioning script default unless overridden.
  password: process.env.LOCAL_OPERATOR_PASSWORD
    || (readFileSync(join(repo, 'backend/scripts/provision_local_operator.sh'), 'utf8').match(/password="\$\{LOCAL_OPERATOR_PASSWORD:-([^}]*)\}"/) || [])[1],
};

function freePort() {
  return new Promise((res, rej) => {
    const s = net.createServer();
    s.listen(0, '127.0.0.1', () => { const {port} = s.address(); s.close(() => res(port)); });
    s.on('error', rej);
  });
}

async function startServer(extraEnv) {
  const port = await freePort();
  const child = spawn(process.execPath, [join(websiteDir, 'server.mjs')], {
    cwd: websiteDir, env: {...process.env, PORT: String(port), HOST: '127.0.0.1', ...extraEnv}, stdio: ['ignore', 'pipe', 'pipe'],
  });
  let out = '';
  child.stdout.on('data', d => { out += d; });
  child.stderr.on('data', d => { out += d; });
  const base = `http://127.0.0.1:${port}`;
  for (let i = 0; i < 100; i += 1) {
    try { if ((await fetch(`${base}/healthz`)).ok) return {child, base, port}; } catch { /* starting */ }
    await new Promise(r => setTimeout(r, 100));
  }
  child.kill();
  throw new Error(`QA Lab server did not start: ${out}`);
}

const catalog = JSON.parse(readFileSync(join(repo, 'qa/catalog/feature_catalog.json'), 'utf8'));
const manualCase = catalog.features.flatMap(f => f.cases.map(c => ({...c, feature: f}))).find(c => c.status === 'not_automated');

let lab;
let results;
test.describe.configure({mode: 'serial'});

test.beforeAll(async () => {
  results = mkdtempSync(join(tmpdir(), 'qa-lab-spec-'));
  const manual = join(results, 'manual_cases.json');
  writeFileSync(manual, JSON.stringify({[manualCase.id]: 'QA Lab spec: stands in for a case that needs a real device'}));
  lab = await startServer({QA_LAB: '1', QA_LAB_SELFTEST: '1', QA_LAB_RESULTS_DIR: results, QA_LAB_MANUAL_CASES: manual, NODE_ENV: 'development'});
});

test.afterAll(async () => {
  lab?.child.kill();
  if (results) rmSync(results, {recursive: true, force: true});
});

async function signIn(page) {
  await page.goto(`${lab.base}/qa-lab/`);
  await expect(page.getByRole('heading', {name: 'Operator sign-in'})).toBeVisible();
  await page.getByLabel('Username').fill(operator.username);
  await page.getByLabel('Password').fill(operator.password);
  const login = page.waitForResponse(r => r.url().endsWith('/qa-lab/api/session') && r.request().method() === 'POST');
  await page.getByRole('button', {name: 'Sign in'}).click();
  expect((await login).status()).toBe(200);
  await expect(page.getByRole('tab', {name: 'Overview'})).toBeVisible();
}

test('QA Lab is not mounted without QA_LAB=1 or in production', async () => {
  const prod = await startServer({QA_LAB: '1', NODE_ENV: 'production'});
  const off = await startServer({QA_LAB: '0'});
  try {
    for (const s of [prod, off]) {
      expect((await fetch(`${s.base}/qa-lab/`)).status).toBe(404);
      expect((await fetch(`${s.base}/qa-lab/api/catalog`)).status).toBe(404);
    }
  } finally {
    prod.child.kill();
    off.child.kill();
  }
});

test('API refuses anonymous calls, forged origins and non-operators', async () => {
  expect((await fetch(`${lab.base}/qa-lab/api/catalog`)).status).toBe(401);
  const noHeader = await fetch(`${lab.base}/qa-lab/api/runs`, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: '{}'});
  expect(noHeader.status).toBe(403);
  const forged = await fetch(`${lab.base}/qa-lab/api/session`, {method: 'POST', headers: {'Content-Type': 'application/json', 'X-QA-Lab': '1', Origin: 'http://evil.example'}, body: '{}'});
  expect(forged.status).toBe(403);
  const csp = (await fetch(`${lab.base}/qa-lab/`)).headers.get('content-security-policy');
  expect(csp).toContain("script-src 'self'");
  expect(csp).not.toContain('unsafe-inline');
});

test('wrong password is refused with a readable error', async ({page}) => {
  await page.goto(`${lab.base}/qa-lab/`);
  await page.getByLabel('Username').fill(operator.username);
  await page.getByLabel('Password').fill('definitely-not-the-password');
  await page.getByRole('button', {name: 'Sign in'}).click();
  await expect(page.getByRole('alert')).toHaveText('Sign-in failed.');
  await expect(page.getByRole('tab', {name: 'Overview'})).toBeHidden();
});

test('operator sees coverage meters, status breakdown, suites and areas', async ({page}) => {
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await signIn(page);
  await expect(page.locator('.meter .label')).toHaveText(['Automated', 'Automated + manual checked', 'Verified (gate)']);
  await expect(page.locator('.meter .value').first()).toHaveText(/^\d+(\.\d)?%$/);
  await expect(page.locator('#catalogMeta')).toContainText(`${catalog.stats.cases} cases`);
  await expect(page.locator('#statusLegend li').first()).toBeVisible();
  await expect(page.locator('#suitePicker label', {hasText: 'Flutter'})).toBeVisible();
  await expect(page.locator('#byArea tbody tr')).toHaveCount(new Set(catalog.features.map(f => f.area)).size);
  expect(errors, 'no CSP or script errors').toEqual([]);
});

test('case browser filters by area and status and selects cases', async ({page}) => {
  await signIn(page);
  await page.getByRole('tab', {name: 'Cases'}).click();
  const area = manualCase.feature.area;
  await page.getByLabel('Area').selectOption(area);
  const expected = catalog.features.filter(f => f.area === area).reduce((n, f) => n + f.cases.length, 0);
  await expect(page.locator('#caseCount')).toContainText(`${expected} case`);
  await page.getByLabel('Search cases').fill(manualCase.id);
  const feature = page.locator(`details.feature[data-feature="${manualCase.feature.id}"]`);
  await expect(feature).toBeVisible();
  await feature.locator('summary .f-title').click();
  const row = feature.locator(`.case[data-case="${manualCase.id}"]`);
  await expect(row).toBeVisible();
  await expect(row.locator('.chip')).toHaveText('manual');
  await row.getByRole('checkbox').check();
  await expect(page.getByRole('button', {name: 'Run selected (1)'})).toBeEnabled();
  await expect(page.getByRole('button', {name: 'Run area'})).toBeEnabled();
});

test('a run streams live progress, lands in history and exports reports', async ({page}) => {
  await signIn(page);
  for (const box of await page.locator('#suitePicker input[type=checkbox]:not([disabled])').all()) await box.uncheck();
  await page.locator('#suitePicker label', {hasText: 'selftest'}).getByRole('checkbox').check();
  await page.getByLabel('Seed data first').uncheck();
  await page.getByLabel('Catalog rescan').selectOption('none');
  const started = page.waitForResponse(r => r.url().endsWith('/qa-lab/api/runs') && r.request().method() === 'POST');
  await page.getByRole('button', {name: 'Run all'}).click();
  expect((await started).status()).toBe(202);
  await expect(page.locator('#live')).toBeVisible();
  await expect(page.locator('#liveStatus')).toHaveText('passed', {timeout: 60000});
  await page.locator('#logBox summary').click();
  await expect(page.locator('#log')).toContainText(/selftest: \d+ passed, 0 failed/, {timeout: 10000});

  await page.getByRole('tab', {name: 'Runs'}).click();
  const row = page.locator('#runTable tbody tr').first();
  await expect(row).toContainText('passed');
  await row.click();
  await expect(page.locator('#runDetail')).toContainText('selftest');
  await expect(page.locator('#runDetail')).toContainText('Diff vs previous run');
  const md = page.locator('#runDetail a', {hasText: 'Report (Markdown)'});
  const href = await md.getAttribute('href');
  const report = await page.request.get(`${lab.base}${href}`);
  expect(report.status()).toBe(200);
  expect(await report.text()).toContain('## Coverage');
  const json = await page.request.get(`${lab.base}${href.replace('.md', '.json')}`);
  expect((await json.json()).run.status).toBe('passed');
});

test('manual checklist records a pass with the operator name', async ({page}) => {
  await signIn(page);
  await page.getByRole('tab', {name: /Manual/}).click();
  const item = page.locator(`.manual-item[data-case="${manualCase.id}"]`);
  await expect(item).toContainText('needs a real device');
  await item.getByLabel(`Note for ${manualCase.id}`).fill('Checked on a Pixel 8, build 42');
  const saved = page.waitForResponse(r => r.url().includes('/qa-lab/api/manual/') && r.request().method() === 'POST');
  await item.getByRole('button', {name: 'Pass'}).click();
  expect((await saved).status()).toBe(200);
  await expect(page.locator(`.manual-item[data-case="${manualCase.id}"]`)).toContainText('Last: pass by Local Control Operator');
  const history = JSON.parse(readFileSync(join(results, 'manual_checks.json'), 'utf8'));
  expect(history[manualCase.id].at(-1)).toMatchObject({result: 'pass', by: operator.username, note: 'Checked on a Pixel 8, build 42'});
});

test('phone width has no horizontal scroll; theme toggles; sign out', async ({page}) => {
  await page.setViewportSize({width: 390, height: 844});
  await signIn(page);
  for (const tab of ['Overview', 'Cases', 'Runs', /Manual/]) {
    await page.getByRole('tab', {name: tab}).click();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, `horizontal overflow on ${tab}`).toBeLessThanOrEqual(0);
  }
  const before = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
  await page.getByRole('button', {name: 'Switch light or dark theme'}).click();
  await expect.poll(() => page.evaluate(() => getComputedStyle(document.body).backgroundColor)).not.toBe(before);
  await page.getByRole('button', {name: 'Sign out'}).click();
  await expect(page.getByRole('heading', {name: 'Operator sign-in'})).toBeVisible();
  expect((await page.request.get(`${lab.base}/qa-lab/api/catalog`)).status()).toBe(401);
});
