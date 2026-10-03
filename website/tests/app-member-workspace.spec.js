import {test, expect} from '@playwright/test';
import {createMember, signIn} from './support/member.js';
import {qaField, qaId, qaIdPrefix} from './support/qa.js';
import {artifactsDir} from './support/site.js';

// The signed-in Flutter web workspace with fresh members (never the shared QA
// account). Flutter renders to canvas; these assertions read its semantics
// tree (flt-semantics), as the other /app specs do. Read-only except for the
// member's own privacy toggle (restored) and a mutual like between two fresh
// test members. Not covered here by design: help & support, contact, and the
// chapter/story editor (in progress in other sessions).
const api = 'http://127.0.0.1:18081/v1';
const shots = `${artifactsDir}/app`;

async function apiLogin(member) {
  const response = await fetch(`${api}/auth/login`, {
    method: 'POST', headers: {'content-type': 'application/json'},
    body: JSON.stringify({username: member.username, password: member.password}),
  });
  expect(response.status).toBe(200);
  return (await response.json()).access_token;
}

async function apiCall(token, method, path, body) {
  const response = await fetch(`${api}${path}`, {
    method, headers: {'content-type': 'application/json', authorization: `Bearer ${token}`},
    body: body && JSON.stringify(body),
  });
  return {status: response.status, body: await response.json().catch(() => null)};
}

/** Two fresh members who liked each other: returns {a, b, matchId}. */
async function matchedPair() {
  const a = createMember('qawebm');
  const b = createMember('qawebm');
  const [ta, tb] = [await apiLogin(a), await apiLogin(b)];
  expect((await apiCall(ta, 'POST', '/swipe', {user_id: a.userId, target_user_id: b.userId, is_like: true})).status).toBe(200);
  const second = await apiCall(tb, 'POST', '/swipe', {user_id: b.userId, target_user_id: a.userId, is_like: true});
  expect(second.body.mutual_match).toBe(true);
  return {a, b, matchId: second.body.match_id};
}

// Any 5xx fails the test. On the shared local stack, sporadic 502/503s have
// so far traced to the database (ENV-01: Postgres "could not open file
// base/16384/…: Interrupted system call", SQLSTATE XX000), not the web app;
// check mobile-bff.log for unexpected_handler_error before filing a defect.
// Shared community photos (Today wall, Cover of the Week) belong to other
// members/sessions and are created and deleted concurrently by other suites;
// a missing image there is annotated, not failed (photo rendering on web is a
// known open issue owned by another session).
const communityImage = url => /\/v1\/media\/approved\/|\/v1\/themes\/[^/]+\/entries\/[^/]+\/photo$/.test(url);

function watchApp(page) {
  const problems = [];
  const note = (type, description) => test.info().annotations.push({type, description});
  page.on('pageerror', e => problems.push(`pageerror: ${e.message}`));
  page.on('console', m => {
    // Resource failures are judged from the response itself below.
    if (m.type() !== 'error' || m.text().startsWith('Failed to load resource')) return;
    problems.push(`console: ${m.text()} ${m.location()?.url ?? ''}`);
  });
  page.on('response', r => {
    const url = r.url();
    if (!url.includes('/v1/') || r.status() < 400) return;
    if (r.status() === 404 && communityImage(url)) return note('community image missing', url);
    problems.push(`http ${r.status()}: ${r.request().method()} ${url}`);
  });
  return problems;
}

/** Flutter builds semantics lazily; scroll the main pane until `locator` exists. */
async function scrollTo(page, locator, x = 900) {
  for (let i = 0; i < 20 && await locator.count() === 0; i++) {
    await page.mouse.move(x, 600);
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(150);
  }
  return locator;
}

async function dismissRewards(page) {
  const toast = page.getByText(/^Your rewards today/);
  if (await toast.count()) await page.getByRole('button', {name: 'Close', exact: true}).first().click().catch(() => {});
}

const notFound = page => page.getByText('This page could not be found.', {exact: true});
const noOverflow = page => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1);

// Route → something that only renders when the real screen (and its data) loaded.
const desktopRoutes = [
  ['discover', page => page.getByRole('button', {name: 'Refresh Today', exact: true})],
  ['engagement', page => page.getByRole('heading', {name: /^ENGAGE /})],
  // Cinematic profile (2026-10-02): the owner sees "STARRING" and the owner console.
  ['profile', page => page.getByRole('button', {name: 'Edit profile', exact: true})],
  ['settings', page => page.getByRole('heading', {name: 'Settings', exact: true})],
  ['blog', page => page.getByRole('heading', {name: 'Open Chapters', exact: true})],
  ['groups', page => page.getByRole('heading', {name: /^YOUR GROUPS/})],
  ['rooms', page => page.getByRole('heading', {name: /^BROWSE Find your room/})],
  ['friends', page => page.getByRole('heading', {name: /^FRIENDS Your people/})],
  ['safety', page => page.getByRole('switch', {name: /^Show age/})],
  ['likes', page => page.getByRole('heading', {name: 'Liked you', exact: true})],
  ['plans', page => page.getByRole('heading', {name: 'Date plans', exact: true})],
  ['notifications', page => page.getByText(/^Read all$|^Notifications$/).first()],
  ['features', page => page.getByText('Make this space yours.', {exact: true})],
];

test.describe('web member workspace', () => {
  test('core routes render real content at 1440px', async ({page}) => {
    test.setTimeout(240000);
    const problems = watchApp(page);
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    for (const [route, ready] of desktopRoutes) {
      await test.step(route, async () => {
        await page.goto(`/app/#/${route}`);
        await expect(ready(page)).toBeVisible({timeout: 20000});
        await expect(notFound(page)).toHaveCount(0);
        expect(await noOverflow(page), `${route} overflows`).toBe(true);
        await page.screenshot({path: `${shots}/${route}-1440.png`});
      });
    }
    // Discover: today's set or an honest empty state, never a spinner forever.
    await page.goto('/app/#/discover');
    await expect(page.getByRole('heading', {name: 'A few people to get to know'})
      .or(page.getByText(/^(A little breathing room\.|Take the time you need\.)$/))
      .or(page.getByText(/No profiles|Check back/i)).first()).toBeVisible({timeout: 20000});
    // Blog feed (read only): filters plus chapters or an empty state.
    await page.goto('/app/#/blog');
    await expect(page.getByRole('checkbox', {name: 'For you', exact: true})).toBeChecked();
    await expect(page.getByRole('group', {name: /Read chapter/}).first()
      .or(page.getByText(/No chapters|Nothing here yet|Be the first/i)).first()).toBeVisible({timeout: 20000});
    // Settings: the web app stays on Daylight (no theme strip), core entries exist.
    // Account comes first and the (mobile-only) theme section would follow it,
    // so check for it before scrolling down to Language and Privacy.
    await page.goto('/app/#/settings');
    await expect(page.getByRole('button', {name: /^Sign out of all devices/})).toBeVisible({timeout: 15000});
    await expect(qaIdPrefix(page, 'qa.settings.theme_preset')).toHaveCount(0);
    await expect(page.getByText('Appearance', {exact: true})).toHaveCount(0);
    await expect((await scrollTo(page, page.getByRole('button', {name: /^Language/}))).first()).toBeVisible();
    await expect(await scrollTo(page, page.getByRole('button', {name: /^Privacy & Safety/}))).toBeVisible();
    expect(problems).toEqual([]);
  });

  test('unknown routes show a recoverable not-found page [case:web.web_member_workspace.back_to_discover.action]', async ({page}) => {
    const problems = watchApp(page);
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, createMember('qaweb'));
    await page.goto('/app/#/definitely-not-a-page');
    await expect(notFound(page)).toBeVisible({timeout: 15000});
    await page.getByRole('button', {name: 'Back to Discover', exact: true}).click();
    await expect(page).toHaveURL(/#\/discover$/);
    await expect(page.getByRole('button', {name: 'Refresh Today', exact: true})).toBeVisible({timeout: 15000});
    expect(problems).toEqual([]);
  });

  test('Connect website in the sidebar leaves the app for the website home [case:web.web_member_workspace.connect_website.action]', async ({page}) => {
    const problems = watchApp(page);
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    await expect(page).toHaveURL(/\/app\//);
    await page.getByRole('button', {name: 'Connect website', exact: true}).click();
    await expect(page).toHaveURL(url => new URL(url).pathname === '/', {timeout: 15000});
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page.locator('html')).toHaveAttribute('lang', 'en');
    expect(problems).toEqual([]);
  });

  test('sidebar navigation and browser back/forward stay in sync', async ({page}) => {
    test.setTimeout(120000);
    const problems = watchApp(page);
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    const sidebar = name => page.getByRole('button', {name, exact: true});
    await sidebar('Matches').click();
    await expect(page).toHaveURL(/#\/matches$/);
    await expect(page.getByRole('checkbox', {name: 'Your matches'})).toBeVisible();
    await sidebar('Settings').click();
    await expect(page).toHaveURL(/#\/settings$/);
    await expect(page.getByRole('heading', {name: 'Settings', exact: true})).toBeVisible();
    await sidebar('Privacy & safety').click();
    await expect(page).toHaveURL(/#\/safety$/);
    await expect(page.getByRole('switch', {name: /^Show age/})).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(/#\/settings$/);
    await expect(page.getByRole('heading', {name: 'Settings', exact: true})).toBeVisible();
    await page.goBack();
    await expect(page).toHaveURL(/#\/matches$/);
    await expect(page.getByRole('checkbox', {name: 'Your matches'})).toBeVisible();
    await page.goForward();
    await expect(page).toHaveURL(/#\/settings$/);
    await expect(page.getByRole('heading', {name: 'Settings', exact: true})).toBeVisible();
    // A reload keeps the member signed in on the same page.
    await page.reload();
    await expect(page.getByRole('heading', {name: 'Settings', exact: true})).toBeVisible({timeout: 30000});
    expect(problems).toEqual([]);
  });

  test('privacy toggle persists and keeps the stored theme and language', async ({page}) => {
    test.setTimeout(120000);
    const problems = watchApp(page);
    const member = createMember('qaweb');
    let stored = null;
    page.on('response', async r => {
      if (r.request().method() === 'GET' && r.url().endsWith(`/v1/settings/${member.userId}`) && r.ok()) {
        stored = (await r.json().catch(() => ({}))).settings ?? stored;
      }
    });
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, member);
    await dismissRewards(page);
    await page.goto('/app/#/safety');
    const distance = page.getByRole('switch', {name: /^Show exact distance/});
    await expect(distance).toBeVisible({timeout: 15000});
    const before = await distance.isChecked();
    const patch = page.waitForRequest(r => r.url().includes(`/v1/settings/${member.userId}`) && r.method() === 'PATCH');
    const saved = page.waitForResponse(r => r.url().includes(`/v1/settings/${member.userId}`) && r.request().method() === 'PATCH');
    const storedBefore = stored;
    await distance.click();
    const body = (await patch).postDataJSON();
    expect((await saved).status()).toBe(200);
    expect(body.show_exact_distance).toBe(!before);
    await expect(distance).toBeChecked({checked: !before});

    await page.reload();
    await expect(page.getByRole('switch', {name: /^Show exact distance/})).toBeChecked({checked: !before, timeout: 30000});
    // The PATCH carries only the changed switch, so it cannot reset the stored
    // theme/locale (user_settings_provider.dart); they survive the round trip.
    expect(storedBefore, 'app loaded the stored settings').not.toBeNull();
    expect(Object.keys(body)).toEqual(['show_exact_distance']);
    expect(stored.theme).toBe(storedBefore.theme);
    expect(stored.locale).toBe(storedBefore.locale);
    await page.getByRole('switch', {name: /^Show exact distance/}).click();
    await expect(page.getByRole('switch', {name: /^Show exact distance/})).toBeChecked({checked: before});
    expect(problems).toEqual([]);
  });

  test('matches, conversations and a chat with a real match', async ({page}) => {
    test.setTimeout(180000);
    const problems = watchApp(page);
    const {a, matchId} = await matchedPair();
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, a);
    await dismissRewards(page);
    await page.goto('/app/#/matches');
    // The Matches tab opens on its Discover sub-view by design.
    await expect(page.getByRole('checkbox', {name: 'Discover'})).toBeChecked({timeout: 20000});
    await page.getByRole('checkbox', {name: 'Your matches'}).click();
    await expect(page.getByText('1 match', {exact: true})).toBeVisible({timeout: 15000});
    await expect(page.getByRole('button', {name: 'Open chat', exact: true})).toBeVisible();
    await page.getByRole('checkbox', {name: 'Conversations', exact: true}).click();
    const row = qaId(page, `qa.matches.match_row.${matchId}`);
    await expect(row).toBeVisible({timeout: 15000});
    await page.screenshot({path: `${shots}/conversations-1440.png`});
    await row.click();
    await expect(page.getByText('Every good story starts with a hello.', {exact: false}).first()).toBeVisible({timeout: 15000});
    await expect(qaField(page, 'qa.chat.composer')).toBeVisible();
    await page.screenshot({path: `${shots}/chat-1440.png`});
    // Browser back closes the conversation and keeps the Conversations view.
    await page.goBack();
    await expect(row).toBeVisible({timeout: 15000});
    await expect(page.getByRole('checkbox', {name: 'Conversations', exact: true})).toBeChecked();
    // In-app "All conversations" also returns to the list.
    await row.click();
    await page.getByRole('button', {name: 'All conversations', exact: true}).click();
    await expect(row).toBeVisible({timeout: 15000});
    expect(problems).toEqual([]);
  });

  // WEB-08 (fixed 2026-10-02): the quest gate is opt-in
  // (DEFAULT_UNLOCK_POLICY_VARIANT now defaults to allow_without_template)
  // because neither app can set or complete a quest, so a new match can say hello.
  test('WEB-08: a new match can send a first message', async ({page}) => {
    test.setTimeout(180000);
    const {a, matchId} = await matchedPair();
    await page.setViewportSize({width: 1440, height: 900});
    await signIn(page, a);
    await dismissRewards(page);
    await page.goto('/app/#/matches');
    await page.getByRole('checkbox', {name: 'Conversations', exact: true}).click({timeout: 20000});
    // The composer starts enabled and locks once /unlock-state answers, so
    // wait for that answer before judging it.
    const unlock = page.waitForResponse(r => r.url().endsWith(`/v1/matches/${matchId}/unlock-state`));
    await qaId(page, `qa.matches.match_row.${matchId}`).click();
    expect((await (await unlock).json()).chat_unlocked).toBe(true);
    await page.waitForTimeout(500);
    const composer = qaField(page, 'qa.chat.composer');
    await expect(composer).toBeEnabled();
    await expect(page.getByText('Complete the current unlock step to continue this conversation.')).toHaveCount(0);
  });

  test('phone layout: bottom tabs, feature pages and no overflow at 390px', async ({page}) => {
    test.setTimeout(180000);
    const problems = watchApp(page);
    await page.setViewportSize({width: 390, height: 844});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    const tabs = [
      ['Today Tab 1 of 5', /#\/discover$/, page.getByRole('button', {name: 'Refresh Today', exact: true})],
      ['Matches Tab 2 of 5', /#\/matches$/, page.getByRole('checkbox', {name: 'Your matches'})],
      ['Engage Tab 3 of 5', /#\/engagement$/, page.getByRole('heading', {name: /^ENGAGE /})],
      ['Profile Tab 4 of 5', /#\/profile$/, page.getByText('STARRING', {exact: true})],
      ['Settings Tab 5 of 5', /#\/settings$/, page.getByRole('heading', {name: 'Settings', exact: true})],
    ];
    for (const [tab, url, ready] of tabs) {
      await page.getByRole('button', {name: tab, exact: true}).click();
      await expect(page).toHaveURL(url);
      await expect(ready).toBeVisible({timeout: 20000});
      expect(await noOverflow(page), `${tab} overflows`).toBe(true);
      await page.screenshot({path: `${shots}/${tab.replace(/^\S+ /, '').replace(/\s/g, '-')}-390.png`});
    }
    for (const route of ['groups', 'rooms', 'friends', 'safety', 'blog']) {
      await page.goto(`/app/#/${route}`);
      await expect(page.getByRole('button', {name: 'Back'}).first()).toBeVisible({timeout: 20000});
      await expect(notFound(page)).toHaveCount(0);
      expect(await noOverflow(page), `${route} overflows`).toBe(true);
    }
    expect(problems).toEqual([]);
  });

  // WEB-09 (fixed): on the narrow layout the header Back arrow returns to the
  // page the member came from (browser history), not always to Explore —
  // e.g. All features → Groups → Back lands on All features again.
  // (Screens pushed from Settings use their own back.)
  test('WEB-09: phone Back arrow returns to the previous page', async ({page}) => {
    test.setTimeout(120000);
    await page.setViewportSize({width: 390, height: 844});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    await page.goto('/app/#/features');
    await expect(page.getByText('Make this space yours.', {exact: true})).toBeVisible({timeout: 20000});
    await (await scrollTo(page, page.getByRole('button', {name: 'Groups', exact: true}), 195)).click();
    await expect(page).toHaveURL(/#\/groups$/);
    await expect(page.getByRole('heading', {name: /^YOUR GROUPS/})).toBeVisible({timeout: 20000});
    await page.getByRole('button', {name: 'Back'}).first().click();
    await expect(page).toHaveURL(/#\/features$/, {timeout: 10000});
  });

  test('phone: a screen opened from Settings goes back to Settings', async ({page}) => {
    test.setTimeout(120000);
    const problems = watchApp(page);
    await page.setViewportSize({width: 390, height: 844});
    await signIn(page, createMember('qaweb'));
    await dismissRewards(page);
    await page.getByRole('button', {name: 'Settings Tab 5 of 5', exact: true}).click();
    await expect(page.getByRole('heading', {name: 'Settings', exact: true})).toBeVisible({timeout: 20000});
    await (await scrollTo(page, page.getByRole('button', {name: /^Privacy & Safety/}), 195)).click();
    await expect(page.getByRole('switch', {name: /^Show age/})).toBeVisible({timeout: 20000});
    await page.getByRole('button', {name: 'Back'}).first().click();
    await expect(page.getByRole('button', {name: /^Privacy & Safety/})).toBeVisible({timeout: 10000});
    await expect(page.getByRole('switch', {name: /^Show age/})).toHaveCount(0);
    await expect(page).toHaveURL(/#\/settings$/);
    expect(problems).toEqual([]);
  });
});
