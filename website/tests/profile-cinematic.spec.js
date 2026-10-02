import {test, expect} from '@playwright/test';
import {createMember} from './support/member.js';
import {api, apiLogin, bringIntoView, dismissRewards, noOverflow, shots, signInWithToken, watchApp} from './support/app.js';

// Cinematic profile (2026-10-02): the owner's "STARRING" view with the
// "This is how you appear" console, and another member's "INTRODUCING" view
// opened from Liked you. Fresh members only; the one fixture mutation is a
// like from the profile owner to the viewer.

const ownName = /^Workflow QA, \d+$/; // verify_signup_workflow.sh names every member this
const starring = page => page.getByText('STARRING', {exact: true});
// A pushed screen's title (app bars repeat it: "Edit Profile Edit Profile").
const titled = (page, label) => {
  const title = new RegExp(`^${label}(?: ${label})?$`);
  return page.getByText(title).or(page.getByRole('heading', {name: title}));
};

/** Member B, signed in on `page`, has been liked by A and opens A's profile from Liked you. */
async function openLikerProfile(page, request, testInfo, width) {
  const a = createMember('qaprof');
  const b = createMember('qaprof');
  const ta = await apiLogin(request, a);
  expect((await api(request, ta, 'POST', '/swipe', {user_id: a.userId, target_user_id: b.userId, is_like: true})).status).toBe(200);
  await page.setViewportSize({width, height: 900});
  const tb = await signInWithToken(page, b);
  await dismissRewards(page);
  await page.goto('/app/#/likes');
  await expect(page.getByRole('heading', {name: 'Liked you · 1', exact: true})).toBeVisible({timeout: 20000});
  await page.getByRole('group', {name: /^Workflow QA, \d+ Liked you/}).click();
  await expect(page.getByText('INTRODUCING', {exact: true})).toBeVisible({timeout: 20000});
  return {a, b, tb};
}

for (const width of [320, 390, 1440]) {
  test(`own profile: STARRING, owner console and its tools at ${width}px`, async ({page}, testInfo) => {
    test.setTimeout(150000);
    const problems = watchApp(page, testInfo);
    await page.setViewportSize({width, height: 900});
    await signInWithToken(page, createMember('qaprof'));
    await dismissRewards(page);
    await page.goto('/app/#/profile');
    await expect(starring(page)).toBeVisible({timeout: 20000});
    await expect(page.getByRole('heading', {name: ownName})).toBeVisible();
    await expect(page.getByRole('button', {name: /^Workflow QA, photo 1 of 2$/})).toBeVisible();
    await expect(page.getByText(/^THIS IS HOW YOU APPEAR/)).toBeVisible();
    await expect(page.getByText(/Profile \d+% complete/).first()).toBeVisible();
    const tools = {
      // Case matters: the console's own buttons read "Edit profile"/"Edit photos".
      'Edit profile': titled(page, 'Edit Profile'),
      'Edit photos': titled(page, 'Save Photos'),
      'Your stories': page.getByText('A little more you', {exact: true}),
      'Who viewed you': page.getByText('Viewed My Profile', {exact: true}),
    };
    for (const name of Object.keys(tools)) await expect(page.getByRole('button', {name, exact: true})).toBeVisible();
    // Another member's actions never appear on your own profile.
    await expect(page.getByRole('button', {name: /qa\.profile_detail\.(message|love|report)_button/})).toHaveCount(0);
    await expect(page.getByText('INTRODUCING', {exact: true})).toHaveCount(0);
    expect(await noOverflow(page), 'profile overflows').toBe(true);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/own-profile-${width}.png`});

    for (const [name, landed] of Object.entries(tools)) {
      await test.step(name, async () => {
        const button = page.getByRole('button', {name, exact: true});
        await bringIntoView(page, button);
        await button.click();
        await expect(landed.first()).toBeVisible({timeout: 15000});
        expect(await noOverflow(page), `${name} overflows`).toBe(true);
        await page.getByRole('button', {name: 'Back'}).first().click();
        await expect(starring(page)).toBeVisible({timeout: 15000});
        await expect(landed).toHaveCount(0);
      });
    }
    expect(problems).toEqual([]);
  });
}

for (const width of [320, 390, 1440]) {
  test(`another member's profile from Liked you: INTRODUCING, photos, dock and top bar at ${width}px`, async ({page, request}, testInfo) => {
    test.setTimeout(180000);
    const problems = watchApp(page, testInfo);
    await openLikerProfile(page, request, testInfo, width);
    await expect(page.getByRole('heading', {name: ownName}).first()).toBeVisible();
    await expect(page.getByText('STARRING', {exact: true})).toHaveCount(0);
    await expect(page.getByText(/^THIS IS HOW YOU APPEAR/)).toHaveCount(0);
    // Photo strip: the hero photo plus the carousel of the rest.
    await expect(page.getByRole('button', {name: /photo 1 of 2$/})).toBeVisible();
    await expect(page.getByRole('group', {name: 'qa.profile_detail.carousel'})).toBeVisible();
    await expect(page.getByRole('button', {name: /photo 2 of 2$/})).toBeVisible();
    // Floating dock and top bar.
    const message = page.getByRole('button', {name: 'Message', exact: true}).last();
    const love = page.getByRole('button', {name: 'Love', exact: true}).last();
    const report = page.getByRole('button', {name: 'Report', exact: true}).last();
    const addFriend = page.getByRole('button', {name: 'Add friend', exact: true});
    for (const control of [message, love, report, addFriend]) await expect(control).toBeVisible();
    const {height} = page.viewportSize();
    for (const [label, control] of [['Report', report], ['Add friend', addFriend]]) {
      const box = await control.boundingBox();
      expect(box.y, `${label} sits in the top bar`).toBeLessThan(120);
      expect(box.x + box.width, `${label} is on screen`).toBeLessThanOrEqual(width + 1);
    }
    for (const [label, control] of [['Message', message], ['Love', love]]) {
      const box = await control.boundingBox();
      expect(box.y + box.height, `${label} sits in the bottom dock`).toBeGreaterThan(height - 160);
      expect(box.y + box.height, `${label} is on screen`).toBeLessThanOrEqual(height + 1);
      expect(box.x >= -1 && box.x + box.width <= width + 1, `${label} is within the width`).toBe(true);
    }
    expect(await noOverflow(page), 'profile overflows').toBe(true);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/member-profile-${width}.png`});
    // The top-bar Back returns to Liked you; nothing was sent.
    await page.getByRole('button', {name: 'Back', exact: true}).first().click();
    await expect(page.getByRole('heading', {name: 'Liked you · 1', exact: true})).toBeVisible({timeout: 15000});
    expect(problems).toEqual([]);
  });
}

// WEB-12 (open, backend): the app records a profile view with
// POST /v1/profile/views {viewer_user_id, viewed_user_id}; the BFF's
// pathOwnedByPrincipal treats "views" as a profile owner id and answers 403,
// so "Who viewed you" never fills and every profile open logs a console error.
test('WEB-12: opening another member\'s profile records the view', async ({page, request}, testInfo) => {
  test.fail(true, 'WEB-12 open: POST /v1/profile/views → 403 "resource does not belong to the authenticated user"');
  test.setTimeout(120000);
  const recorded = page.waitForResponse(r => r.url().endsWith('/v1/profile/views') && r.request().method() === 'POST', {timeout: 30000});
  await openLikerProfile(page, request, testInfo, 1440);
  expect((await recorded).status()).toBe(200);
});

test.describe('edge cases', () => {
  // The workspace gates a signed-out deep link with the sign-in form in place
  // (the address keeps #/profile); no profile data is requested or shown.
  test('signed-out deep link to /app/#/profile shows sign-in, then signs in', async ({page}, testInfo) => {
    test.setTimeout(120000);
    const problems = watchApp(page, testInfo);
    const profileCalls = [];
    page.on('request', r => { if (/\/v1\/profile\//.test(r.url())) profileCalls.push(r.url()); });
    await page.goto('/app/#/profile');
    const username = page.getByRole('textbox', {name: 'username', exact: true});
    await expect(username).toBeVisible({timeout: 30000});
    await expect(page).toHaveURL(/#\/(signin|profile)$/);
    await expect(starring(page)).toHaveCount(0);
    await expect(page.getByRole('button', {name: 'Edit profile', exact: true})).toHaveCount(0);
    expect(profileCalls).toEqual([]);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/signed-out-profile-deep-link.png`});
    // Signing in from the gate opens the workspace (Discover by design).
    const member = createMember('qaprof');
    const typeInto = async (field, value) => {
      await field.click();
      await expect(field).toBeFocused();
      await field.fill('');
      await field.pressSequentially(value, {delay: 15});
      await expect(field).toHaveValue(value);
    };
    await typeInto(username, member.username);
    await username.press('Tab');
    const password = page.getByRole('textbox', {name: 'Password', exact: true});
    await typeInto(password, member.password);
    await password.press('Tab');
    await page.getByRole('button', {name: 'qa.signin.login_button', exact: true}).click();
    await expect(page).toHaveURL(/#\/(discover|profile)$/, {timeout: 30000});
    testInfo.annotations.push({type: 'landing after deep-link sign-in', description: page.url()});
    await expect(page.getByRole('button', {name: 'My profile', exact: true}).first()).toBeVisible({timeout: 30000});
    expect(problems).toEqual([]);
  });

  test('back, forward and reload across profile and privacy keep the member signed in', async ({page}, testInfo) => {
    test.setTimeout(120000);
    const problems = watchApp(page, testInfo);
    await page.setViewportSize({width: 1440, height: 900});
    await signInWithToken(page, createMember('qaprof'));
    await dismissRewards(page);
    const consent = page.getByRole('switch', {name: /^Show my public writing on my profile/});
    await page.goto('/app/#/profile');
    await expect(starring(page)).toBeVisible({timeout: 20000});
    await page.getByRole('button', {name: 'Privacy & safety', exact: true}).click();
    await expect(page).toHaveURL(/#\/safety$/);
    await expect(consent).toBeVisible({timeout: 15000});
    await page.goBack();
    await expect(page).toHaveURL(/#\/profile$/);
    await expect(starring(page)).toBeVisible({timeout: 15000});
    await page.goForward();
    await expect(page).toHaveURL(/#\/safety$/);
    await expect(consent).toBeVisible({timeout: 15000});
    await page.reload();
    await expect(consent).toBeVisible({timeout: 30000});
    await expect(consent).not.toBeChecked();
    await page.goBack();
    await expect(page).toHaveURL(/#\/profile$/);
    await expect(starring(page)).toBeVisible({timeout: 30000});
    await page.reload();
    await expect(starring(page)).toBeVisible({timeout: 30000});
    await expect(page.getByRole('button', {name: 'Edit profile', exact: true})).toBeVisible();
    expect(problems).toEqual([]);
  });

  test('browser Back from another member\'s profile stays signed in and recovers', async ({page, request}, testInfo) => {
    test.setTimeout(150000);
    const problems = watchApp(page, testInfo);
    await openLikerProfile(page, request, testInfo, 390);
    await page.goBack();
    // The pushed profile has no URL of its own; Back leaves it for a workspace page.
    await expect(page.getByText('INTRODUCING', {exact: true})).toHaveCount(0, {timeout: 15000});
    await expect(page).toHaveURL(/#\/(likes|discover)$/);
    await expect(page.getByRole('textbox', {name: 'username', exact: true})).toHaveCount(0);
    await page.goto('/app/#/likes');
    await expect(page.getByRole('heading', {name: 'Liked you · 1', exact: true})).toBeVisible({timeout: 20000});
    expect(problems).toEqual([]);
  });

  test('large text (200%) keeps the profile and its tools usable at 390px', async ({page}, testInfo) => {
    test.setTimeout(120000);
    const problems = watchApp(page, testInfo);
    // Flutter web follows the root font size for its text scale.
    await page.addInitScript(() => {
      document.addEventListener('DOMContentLoaded', () => { document.documentElement.style.fontSize = '32px'; });
    });
    await page.setViewportSize({width: 390, height: 844});
    await signInWithToken(page, createMember('qaprof'));
    await dismissRewards(page);
    expect(await page.evaluate(() => getComputedStyle(document.documentElement).fontSize)).toBe('32px');
    await page.goto('/app/#/profile');
    await expect(starring(page)).toBeVisible({timeout: 20000});
    for (const name of ['Edit profile', 'Edit photos', 'Your stories', 'Who viewed you']) {
      const button = page.getByRole('button', {name, exact: true});
      await bringIntoView(page, button);
      await expect(button).toBeVisible();
      const box = await button.boundingBox();
      expect(box.x >= -1 && box.x + box.width <= 391, `${name} fits the width`).toBe(true);
    }
    expect(await noOverflow(page), 'profile overflows at 200% text').toBe(true);
    await bringIntoView(page, page.getByRole('button', {name: 'Edit profile', exact: true}));
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/own-profile-large-text-390.png`});
    await page.goto('/app/#/safety');
    const consent = page.getByRole('switch', {name: /^Show my public writing on my profile/});
    await expect(consent).toBeVisible({timeout: 20000});
    expect(await noOverflow(page), 'privacy overflows at 200% text').toBe(true);
    await bringIntoView(page, consent);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/privacy-large-text-390.png`});
    expect(problems).toEqual([]);
  });
});
