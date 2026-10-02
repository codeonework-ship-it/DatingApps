import {test, expect} from '@playwright/test';
import {randomBytes, randomUUID} from 'node:crypto';
import {createMember} from './support/member.js';
import {api, apiLogin, bringIntoView, dismissRewards, focusedName, noOverflow, scrollUntil, shots, signInWithToken, tabTo, watchApp} from './support/app.js';

// Profile showcase consent (migration 130): "Show my public writing on my
// profile" (default off). Member A writes a community, a friends-only and a
// private chapter through the real API and likes member B; B opens A's
// profile from Liked you. "Writing & moments" appears for B only while A's
// consent is on, and only the community chapter ever appears.

const consentSwitch = page => page.getByRole('switch', {name: /^Show my public writing on my profile/});
const showcase = page => page.getByRole('heading', {name: 'WRITING & MOMENTS', exact: true});

async function openAsViewer(page, ownerId) {
  await page.goto('/app/#/likes');
  await expect(page.getByRole('heading', {name: 'Liked you · 1', exact: true})).toBeVisible({timeout: 20000});
  const loaded = page.waitForResponse(r => r.url().endsWith(`/v1/profile/${ownerId}/showcase`) && r.request().method() === 'GET');
  await page.getByRole('group', {name: /^Workflow QA, \d+ Liked you/}).click();
  await expect(page.getByText('INTRODUCING', {exact: true})).toBeVisible({timeout: 20000});
  const response = await loaded;
  expect(response.status()).toBe(200);
  // Scroll through the whole profile so every scene has been built.
  await scrollUntil(page, page.getByRole('heading', {name: 'LIFESTYLE', exact: true}));
  return response.json();
}

test('showcase consent gates "Writing & moments" for other members', async ({browser, request}, testInfo) => {
  test.setTimeout(300000);
  const tag = randomBytes(3).toString('hex');
  const titles = {community: `Community walk ${tag}`, friends: `Friends only ${tag}`, private: `Private note ${tag}`};
  const a = createMember('qashow');
  const b = createMember('qashow');

  // Fixtures through the real API, before A's browser session exists.
  const ta = await apiLogin(request, a);
  expect((await api(request, ta, 'POST', '/swipe', {user_id: a.userId, target_user_id: b.userId, is_like: true})).status).toBe(200);
  for (const [audience, title] of Object.entries(titles)) {
    const saved = await api(request, ta, 'PUT', `/blog/posts/${randomUUID()}`, {
      expected_version: 0, title, body: `A slow ${audience} afternoon by the river, written for QA ${tag}.`, audience,
    });
    expect(saved.status, `${audience} chapter`).toBe(200);
    expect(saved.body.post.audience).toBe(audience);
  }
  expect((await api(request, ta, 'GET', `/profile/${a.userId}/showcase/consent`)).body.visible, 'default is off').toBe(false);

  const viewerContext = await browser.newContext({viewport: {width: 390, height: 900}});
  const ownerContext = await browser.newContext({viewport: {width: 1440, height: 900}});
  const viewer = await viewerContext.newPage();
  const owner = await ownerContext.newPage();
  const problems = [...[viewer, owner].map(p => watchApp(p, testInfo))];
  try {
    // B: consent off → no showcase, and the server sends nothing to hide.
    await signInWithToken(viewer, b);
    await dismissRewards(viewer);
    let data = await openAsViewer(viewer, a.userId);
    expect(data).toMatchObject({enabled: false, chapters: [], photos: []});
    await expect(showcase(viewer)).toHaveCount(0);
    for (const title of Object.values(titles)) await expect(viewer.getByText(title)).toHaveCount(0);
    await dismissRewards(viewer, 1500);
    await viewer.screenshot({path: `${shots}/showcase-hidden-viewer-390.png`});

    // A: own profile shows the private preview card with its switch.
    await signInWithToken(owner, a);
    // The app may refresh its session; read the consent with its current bearer.
    let bearerA;
    owner.on('request', r => { const auth = r.headers().authorization; if (auth && r.url().includes('/v1/')) bearerA = auth.replace(/^Bearer /, ''); });
    await dismissRewards(owner);
    await owner.goto('/app/#/profile');
    await expect(owner.getByText('STARRING', {exact: true})).toBeVisible({timeout: 20000});
    const preview = owner.getByRole('switch', {name: /^Only you can see this/});
    await expect(await scrollUntil(owner, preview)).toBeVisible();
    await expect(preview).not.toBeChecked();
    await expect(owner.getByRole('heading', {name: 'Your public writing & photos', exact: true})).toBeVisible();
    await expect(owner.getByRole('button', {name: new RegExp(`^${titles.community}`)})).toBeVisible();
    await expect(owner.getByText(new RegExp(titles.friends))).toHaveCount(0);
    await expect(owner.getByText(new RegExp(titles.private))).toHaveCount(0);
    await bringIntoView(owner, preview);
    await dismissRewards(owner, 1500);
    await owner.screenshot({path: `${shots}/showcase-owner-preview-off-1440.png`});

    // A: Privacy & safety switch, operated with the keyboard only.
    await owner.goto('/app/#/safety');
    const consent = consentSwitch(owner);
    await expect(consent).toBeVisible({timeout: 20000});
    await expect(consent).not.toBeChecked();
    expect(await tabTo(owner, consent), 'Tab reaches the showcase switch').toBe(true);
    const turnedOn = owner.waitForResponse(r => r.url().endsWith(`/v1/profile/${a.userId}/showcase/consent`) && r.request().method() === 'PUT');
    await owner.keyboard.press('Space');
    const on = await turnedOn;
    expect(on.status()).toBe(200);
    expect(on.request().postDataJSON()).toEqual({visible: true});
    await expect(consent).toBeChecked();
    const reloaded = owner.waitForResponse(r => r.url().endsWith(`/v1/profile/${a.userId}/showcase/consent`) && r.request().method() === 'GET');
    await owner.reload();
    expect((await (await reloaded).json()).visible, 'the app reads the saved consent after reload').toBe(true);
    await expect(consentSwitch(owner)).toBeChecked({timeout: 30000});
    expect((await api(request, bearerA, 'GET', `/profile/${a.userId}/showcase/consent`)).body.visible).toBe(true);
    await bringIntoView(owner, consentSwitch(owner));
    await dismissRewards(owner, 1500);
    await owner.screenshot({path: `${shots}/showcase-consent-on-1440.png`});

    // B: consent on → the community chapter only, with "Read all their chapters".
    await viewer.getByRole('button', {name: 'Back', exact: true}).first().click();
    data = await openAsViewer(viewer, a.userId);
    expect(data.enabled).toBe(true);
    expect(data.chapters.map(c => c.title)).toEqual([titles.community]);
    await expect(await scrollUntil(viewer, showcase(viewer), {delta: -300})).toBeVisible();
    const chapter = viewer.getByRole('button', {name: new RegExp(`^${titles.community}`)});
    await expect(chapter).toBeVisible();
    await expect(viewer.getByRole('heading', {name: 'In their own words', exact: true})).toBeVisible();
    const readAll = viewer.getByRole('button', {name: 'Read all their chapters', exact: true});
    await expect(readAll).toBeVisible();
    await expect(viewer.getByText(new RegExp(titles.friends))).toHaveCount(0);
    await expect(viewer.getByText(new RegExp(titles.private))).toHaveCount(0);
    expect(await noOverflow(viewer), 'profile with showcase overflows').toBe(true);
    await bringIntoView(viewer, chapter);
    await dismissRewards(viewer, 1500);
    await viewer.screenshot({path: `${shots}/showcase-visible-viewer-390.png`});
    await bringIntoView(viewer, readAll);
    await readAll.click();
    await expect(viewer.getByText(new RegExp(titles.community)).first()).toBeVisible({timeout: 20000});
    await expect(viewer.getByText(new RegExp(titles.private))).toHaveCount(0);
    await viewer.screenshot({path: `${shots}/showcase-read-all-390.png`});

    // A turns it off again from the profile preview card (pointer this time).
    await owner.goto('/app/#/profile');
    const shown = owner.getByRole('switch', {name: /^Show on my profile/});
    await expect(await scrollUntil(owner, shown)).toBeChecked();
    await bringIntoView(owner, shown);
    const turnedOff = owner.waitForResponse(r => r.url().endsWith(`/v1/profile/${a.userId}/showcase/consent`) && r.request().method() === 'PUT');
    await shown.click();
    expect((await turnedOff).request().postDataJSON()).toEqual({visible: false});
    await expect(owner.getByRole('switch', {name: /^Only you can see this/})).not.toBeChecked();
    expect((await api(request, bearerA, 'GET', `/profile/${a.userId}/showcase/consent`)).body.visible).toBe(false);

    // B: hidden again.
    await viewer.goto('/app/#/likes');
    data = await openAsViewer(viewer, a.userId);
    expect(data).toMatchObject({enabled: false, chapters: []});
    await expect(showcase(viewer)).toHaveCount(0);
    await expect(viewer.getByText(new RegExp(titles.community))).toHaveCount(0);
    expect(problems.flat()).toEqual([]);
  } finally {
    await viewerContext.close();
    await ownerContext.close();
  }
});

// WEB-13: keyboard focus order on the desktop workspace. Tab should finish one
// region before moving to the next (sidebar, then the page), not zig-zag
// between sidebar links and page controls by their height on screen.
test('keyboard: Privacy & safety switches are reached in page order, not interleaved with the sidebar', async ({page}, testInfo) => {
  test.setTimeout(120000);
  const problems = watchApp(page, testInfo);
  await page.setViewportSize({width: 1440, height: 900});
  await signInWithToken(page, createMember('qashow'));
  await dismissRewards(page, 1500);
  await page.goto('/app/#/safety');
  await expect(consentSwitch(page)).toBeVisible({timeout: 20000});
  await page.waitForTimeout(1000);
  const sidebar = new Set(['Today', 'Matches', 'Explore', 'My profile', 'Settings', 'Blog', 'All features', 'Preferences',
    'Notifications', 'Membership', 'Privacy & safety', 'Help & support', 'Connect website', 'Sign out']);
  const order = [];
  for (let i = 0; i < 40; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(250);
    const name = (await focusedName(page)).replace(/^[^:]*:/, '');
    if (order.includes(name) && order.at(-1) !== name) break; // wrapped around
    if (name && order.at(-1) !== name) order.push(name);
  }
  testInfo.annotations.push({type: 'tab order', description: order.join(' → ')});
  const pageControls = order.filter(n => !sidebar.has(n));
  // Page controls in their on-screen order.
  const switches = ['Show age', 'Show exact distance', 'Show online status', 'Let people find me in friend search', 'Show my public writing on my profile'];
  expect(pageControls.filter(n => switches.includes(n))).toEqual(switches);
  // One contiguous run of sidebar entries, then one of page controls (or the reverse).
  const regions = order.map(n => sidebar.has(n) ? 'sidebar' : 'page').filter((r, i, all) => i === 0 || all[i - 1] !== r);
  expect(regions.length, `focus alternates between regions: ${order.join(' → ')}`).toBeLessThanOrEqual(2);
  expect(problems).toEqual([]);
});

test('the consent switch only changes your own setting', async ({request}) => {
  const a = createMember('qashow');
  const b = createMember('qashow');
  const tb = await apiLogin(request, b);
  expect((await api(request, tb, 'PUT', `/profile/${a.userId}/showcase/consent`, {visible: true})).status).toBe(403);
  expect((await api(request, tb, 'GET', `/profile/${a.userId}/showcase/consent`)).status).toBe(403);
  expect((await api(request, tb, 'PUT', `/profile/${b.userId}/showcase/consent`, {visible: 'yes'})).status).toBe(400);
  const ta = await apiLogin(request, a);
  expect((await api(request, ta, 'GET', `/profile/${a.userId}/showcase/consent`)).body.visible).toBe(false);
});
