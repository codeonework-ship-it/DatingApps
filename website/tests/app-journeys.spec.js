import {test, expect} from '@playwright/test';
import {dismissRewards, scrollUntil, watchApp} from './support/app.js';
import {qaField, qaId, qaIdPrefix} from './support/qa.js';
import {bff, isolatedCast, like, likedBy, nextSwipe, retire, signInAs, spotlightAge, tokenFor, typeInto} from './support/journeys.js';

// Critical web-app journeys end to end in a real browser, against the real
// stack: every entry point that opens another member's profile, and the
// profile's Love and Message (P0 2026-10-02: the buttons did nothing). Each
// test asserts the POST /v1/swipe the browser actually sends, the server's
// answer, what the member sees, and the server state afterwards.
//
// Isolation: each test signs in a fresh viewer whose deck holds only that
// test's fresh candidates (see support/journeys.js), so no shared or seeded
// member is ever liked. Everyone is retired at the end.

const introducing = page => page.getByText('INTRODUCING', {exact: true});
// The profile dock's buttons, by qa id (their spoken names are checked in
// profile-cinematic.spec.js).
const dockLove = page => qaId(page, 'qa.profile_detail.love_button');
const dockMessage = page => qaId(page, 'qa.profile_detail.message_button');
const composer = page => qaField(page, 'qa.chat.composer');
// The photo inside a swipe card (`qa.<scope>.card_root`); its name starts "Name, age".
const cardPhoto = (page, scope) => qaId(page, `qa.${scope}.card_root`).getByRole('img').first();
// A snack bar: the visible text (Flutter also announces it in a polite live region).
const escapeRe = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const snack = (page, text) => page.locator('flt-semantics').getByText(text, {exact: true}).last();

/** Love on an open profile: one like for this member, saved, and said so. */
async function loveFromProfile(page, viewer, candidate) {
  await expect(introducing(page)).toBeVisible({timeout: 20000});
  await expect(page.getByRole('heading', {name: new RegExp(`^${candidate.name}, \\d+$`)}).first()).toBeVisible();
  const swipe = await nextSwipe(page, candidate.userId, () => dockLove(page).click());
  expect(swipe.body).toEqual({user_id: viewer.userId, target_user_id: candidate.userId, is_like: true});
  expect(swipe.status).toBe(200);
  expect(swipe.response.accepted).toBe(true);
  return swipe;
}

/** Message on an open profile with no match yet: sends a like and explains. */
async function messageWithoutMatch(page, viewer, candidate) {
  await expect(introducing(page)).toBeVisible({timeout: 20000});
  const swipe = await nextSwipe(page, candidate.userId, () => dockMessage(page).click());
  expect(swipe.body).toEqual({user_id: viewer.userId, target_user_id: candidate.userId, is_like: true});
  expect(swipe.status).toBe(200);
  expect(swipe.response.mutual_match).toBe(false);
  await expect(snack(page, `Love sent to ${candidate.name}. You can chat as soon as they like you back.`)).toBeVisible({timeout: 10000});
  // No chat opens without a match.
  await expect(composer(page)).toHaveCount(0);
  expect(await likedBy(candidate, viewer), 'the like reached the candidate').toBe(true);
  return swipe;
}

/** Message on an open profile whose member already liked the viewer: match, then chat. */
async function messageMakesMatchAndChat(page, viewer, candidate, {viaMatchScreen = false} = {}) {
  await expect(introducing(page)).toBeVisible({timeout: 20000});
  const swipe = await nextSwipe(page, candidate.userId, () => dockMessage(page).click());
  expect(swipe.body).toEqual({user_id: viewer.userId, target_user_id: candidate.userId, is_like: true});
  expect(swipe.status).toBe(200);
  expect(swipe.response.mutual_match).toBe(true);
  expect(swipe.response.match_id).toBeTruthy();
  if (viaMatchScreen) {
    // Liked you answers Message with a like back: the match screen first.
    await expect(page.getByRole('heading', {name: 'New Match', exact: true})).toBeVisible({timeout: 15000});
    await expect(page.getByText(`You and ${candidate.name} liked each other`, {exact: true})).toBeVisible();
    await page.getByRole('button', {name: 'Send Message', exact: true}).last().click();
  }
  await expect(composer(page)).toBeVisible({timeout: 20000});
  await expect(page.getByText(candidate.name).first()).toBeVisible();
  return swipe.response.match_id;
}

test.describe('profile Love and Message from every entry point', () => {
  test('Today rail: Meet → Love saves a like and says so [case:discover.profile_entry_points.today_rail.love] [case:swipe.profile_details.profile_detail_love_button_love.action]', async ({page}, testInfo) => {
    test.setTimeout(180000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates: [c]} = await isolatedCast(1);
    try {
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      const meet = page.getByRole('button', {name: `Meet ${c.name}`, exact: true});
      await expect(meet).toBeVisible({timeout: 20000});
      await meet.click();
      await loveFromProfile(page, viewer, c);
      await expect(snack(page, `Super like sent to ${c.name}`)).toBeVisible({timeout: 10000});
      // The saved Love closes the profile and the pick leaves Today.
      await expect(introducing(page)).toHaveCount(0, {timeout: 10000});
      await expect(meet).toHaveCount(0, {timeout: 15000});
      expect(await likedBy(c, viewer), 'the like reached the candidate').toBe(true);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, c);
    }
  });

  test('Today rail: Meet → Message with someone who liked you makes the match, opens chat and a first message arrives [case:discover.profile_entry_points.today_rail.message] [case:swipe.profile_details.profile_detail_message_button_message.action] [case:messaging.chat.chat_send_button_send.action] [case:journeys.e2e.like_to_match_to_chat]', async ({page}, testInfo) => {
    test.setTimeout(180000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates: [c]} = await isolatedCast(1);
    try {
      await like(c, viewer);
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      await page.getByRole('button', {name: `Meet ${c.name}`, exact: true}).click({timeout: 20000});
      const matchId = await messageMakesMatchAndChat(page, viewer, c);
      // First message: the composer sends it, the bubble shows, the other member has it.
      const text = `Hello ${c.name.split(' ')[0]}, lovely to match! ${Date.now()}`;
      await typeInto(page, composer(page), text);
      const sent = page.waitForResponse(r => r.url().endsWith(`/v1/chat/${matchId}/messages`) && r.request().method() === 'POST');
      await page.getByRole('button', {name: 'Send message', exact: true}).first().click();
      const response = await sent;
      expect(response.status()).toBeLessThan(300);
      expect(response.request().postDataJSON()).toEqual({sender_id: viewer.userId, text});
      // The bubble is a message button (qa id `qa.chat.message.<id>`) named "<text> <time> Sent".
      const bubble = qaIdPrefix(page, 'qa.chat.message.').and(page.getByRole('button', {name: new RegExp(`^${escapeRe(text)} .*Sent$`)}));
      await expect(bubble).toBeVisible({timeout: 10000});
      // The composer is empty and ready for the next message. (The browser's
      // textarea keeps stale text until Flutter re-attaches its editor on
      // focus, so judge the framework's value after focusing it.)
      await composer(page).click();
      await page.waitForTimeout(200);
      await expect(composer(page)).toHaveValue('');
      const thread = await bff(await tokenFor(c), 'GET', `/chat/${matchId}/messages`);
      expect(thread.status).toBe(200);
      expect(JSON.stringify(thread.body)).toContain(text);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, c);
    }
  });

  test('Discover deck: View more → Love, then the next card → Message without a match [case:discover.profile_entry_points.discover_view_more.love] [case:discover.profile_entry_points.discover_view_more.message] [case:common.main_navigation.explore_more_profiles_onbrowse.action] [case:swipe.home_discovery.x_view_more_button_openprofile.action]', async ({page}, testInfo) => {
    test.setTimeout(180000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates} = await isolatedCast(2);
    try {
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      await openDeck(page);
      const viewMore = qaId(page, 'qa.discovery.view_more_button');
      await expect(viewMore).toBeVisible({timeout: 20000});
      await viewMore.click();
      const first = await openedProfile(page, candidates);
      await loveFromProfile(page, viewer, first);
      await expect(snack(page, `Super like sent to ${first.name}`)).toBeVisible({timeout: 10000});
      await expect(introducing(page)).toHaveCount(0, {timeout: 10000});
      // The loved member left the deck; the other is on top now.
      const second = candidates.find(c => c !== first);
      await viewMore.click();
      expect(await openedProfile(page, candidates), 'the next card is the other candidate').toBe(second);
      await messageWithoutMatch(page, viewer, second);
      expect(await likedBy(first, viewer)).toBe(true);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, ...candidates);
    }
  });

  test('Spotlight rail: avatar → Love, and → Message with someone who liked you opens chat [case:discover.profile_entry_points.spotlight_rail.love] [case:discover.profile_entry_points.spotlight_rail.message]', async ({page}, testInfo) => {
    test.setTimeout(180000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates: [c0, c1]} = await isolatedCast(2);
    try {
      await like(c1, viewer);
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      await openDeck(page);
      const rail = name => page.getByRole('button', {name, exact: true});
      await rail(c0.name).click({timeout: 20000});
      expect(await openedProfile(page, [c0, c1])).toBe(c0);
      await loveFromProfile(page, viewer, c0);
      await expect(snack(page, `Super like sent to ${c0.name}`)).toBeVisible({timeout: 10000});
      await expect(introducing(page)).toHaveCount(0, {timeout: 10000});
      await expect(rail(c0.name)).toHaveCount(0, {timeout: 15000});
      await rail(c1.name).click();
      expect(await openedProfile(page, [c0, c1])).toBe(c1);
      await messageMakesMatchAndChat(page, viewer, c1);
      expect(await likedBy(c0, viewer)).toBe(true);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, c0, c1);
    }
  });

  test('Spotlight screen: View more → Love, card Message without a match, View more → Message opens chat [case:discover.profile_entry_points.spotlight_screen.love] [case:discover.profile_entry_points.spotlight_screen.message] [case:discover.profile_entry_points.spotlight_screen.message_2] [case:swipe.spotlight_profiles.x_view_more_button_openprofile.action] [case:swipe.spotlight_profiles.x_card_message_button_message.action]', async ({page}, testInfo) => {
    test.setTimeout(240000);
    const problems = watchApp(page, testInfo);
    // The full Spotlight screen keeps its own 20–50 age window (see the
    // known-defect test below), so this cast is aged inside it.
    const {viewer, candidates} = await isolatedCast(3, 'qaj', spotlightAge());
    try {
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      await openDeck(page);
      await page.getByRole('button', {name: 'View all', exact: true}).click({timeout: 20000});
      const viewMore = qaId(page, 'qa.spotlight.view_more_button');
      const card = cardPhoto(page, 'spotlight');
      const current = async () => {
        await expect(card).toBeVisible({timeout: 15000});
        const label = await card.getAttribute('aria-label');
        return candidates.find(c => label.includes(`${c.name},`)) ?? null;
      };
      // Card 1: View more → Love. The profile closes and the screen moves on.
      const first = await current();
      expect(first, 'card 1 is one of this test\'s candidates').toBeTruthy();
      await viewMore.click();
      expect(await openedProfile(page, candidates)).toBe(first);
      await loveFromProfile(page, viewer, first);
      await expect(introducing(page)).toHaveCount(0, {timeout: 10000});
      await expect.poll(current, {timeout: 10000}).not.toBe(first);
      // Card 2: the card's own Message — no match yet, so it sends a like and explains.
      const second = await current();
      expect(second).toBeTruthy();
      const swipe = await nextSwipe(page, second.userId, () => qaId(page, 'qa.spotlight.card_message_button').click());
      expect(swipe.body).toEqual({user_id: viewer.userId, target_user_id: second.userId, is_like: true});
      expect(swipe.status).toBe(200);
      expect(swipe.response.mutual_match).toBe(false);
      await expect(snack(page, `Love sent to ${second.name}. You can chat as soon as they like you back.`)).toBeVisible({timeout: 10000});
      await expect(composer(page)).toHaveCount(0);
      expect(await likedBy(second, viewer)).toBe(true);
      // Message keeps the card; Like moves on (a repeated like is accepted).
      const again = await nextSwipe(page, second.userId, () => qaId(page, 'qa.spotlight.like_button').click());
      expect(again.status).toBe(200);
      await expect.poll(current, {timeout: 10000}).not.toBe(second);
      // Card 3 likes the viewer first: View more → Message makes the match and opens chat.
      const third = await current();
      expect(third).toBeTruthy();
      await like(third, viewer);
      await viewMore.click();
      expect(await openedProfile(page, candidates)).toBe(third);
      await messageMakesMatchAndChat(page, viewer, third);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, ...candidates);
    }
  });

  test('Spotlight screen: Like, Pass and Super like reach the server and move on; Undo steps back [case:discover.profile_entry_points.spotlight_screen.buttons_reach_server] [case:swipe.spotlight_profiles.like_icon_favorite_onlike.action] [case:swipe.spotlight_profiles.pass_icon_close_onpass.action] [case:swipe.spotlight_profiles.super_like_icon_star_onsuperlike.action] [case:swipe.spotlight_profiles.undo_icon_undo_onundo.action]', async ({page}, testInfo) => {
    test.setTimeout(240000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates} = await isolatedCast(3, 'qaj', spotlightAge());
    try {
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      await openDeck(page);
      await page.getByRole('button', {name: 'View all', exact: true}).click({timeout: 20000});
      const card = cardPhoto(page, 'spotlight');
      const current = async () => {
        await expect(card).toBeVisible({timeout: 15000});
        const label = await card.getAttribute('aria-label');
        return candidates.find(c => label.includes(`${c.name},`));
      };
      const decisions = [];
      for (const [button, isLike] of [['like', true], ['pass', false], ['superlike', true]]) {
        const who = await current();
        expect(who, `card ${decisions.length + 1} is one of this test's candidates`).toBeTruthy();
        const swipe = await nextSwipe(page, who.userId, () => qaId(page, `qa.spotlight.${button}_button`).click());
        expect(swipe.body).toEqual({user_id: viewer.userId, target_user_id: who.userId, is_like: isLike});
        expect(swipe.status).toBe(200);
        decisions.push([button, who]);
        if (button !== 'superlike') await expect.poll(current, {timeout: 10000}).not.toBe(who);
        if (button === 'pass') {
          await expect(page.getByRole('button', {name: 'Passed (1)', exact: true})).toBeVisible();
          // Undo steps back to the passed card (on this screen only).
          await qaId(page, 'qa.spotlight.undo_button').click();
          await expect.poll(current).toBe(who);
          await expect(page.getByRole('button', {name: 'Passed (0)', exact: true})).toBeVisible();
          const again = await nextSwipe(page, who.userId, () => qaId(page, 'qa.spotlight.pass_button').click());
          expect(again.status).toBe(200);
          await expect.poll(current, {timeout: 10000}).not.toBe(who);
        }
      }
      await expect(page.getByText('No spotlight profiles match filters').or(page.getByText(/Check back later/)).first()).toBeVisible({timeout: 10000});
      // Server truth: likes and the super like arrived; the pass did not.
      expect(await likedBy(decisions[0][1], viewer)).toBe(true);
      expect(await likedBy(decisions[1][1], viewer)).toBe(false);
      expect(await likedBy(decisions[2][1], viewer)).toBe(true);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, ...candidates);
    }
  });

  test('Liked you (from My profile): Love likes back and makes the match; Message opens chat [case:discover.profile_entry_points.liked_you.love] [case:discover.profile_entry_points.liked_you.message] [case:discover.profile_entry_points.liked_you.own_rule] [case:swipe.liked_me.liked_me_open_x_open.action]', async ({page}, testInfo) => {
    test.setTimeout(240000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates: [c0, c1]} = await isolatedCast(2);
    try {
      await like(c0, viewer);
      await like(c1, viewer);
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      const openLikedYou = async () => {
        await page.getByRole('button', {name: 'My profile', exact: true}).click();
        const entry = page.getByRole('button', {name: /^Who Liked Me/});
        await scrollUntil(page, entry);
        await entry.click();
      };
      await openLikedYou();
      await expect(page.getByRole('heading', {name: 'Liked you · 2', exact: true})).toBeVisible({timeout: 20000});
      await page.getByRole('group', {name: new RegExp(`^${escapeRe(c0.name)}, \\d+ Liked you`)}).click();
      expect(await openedProfile(page, [c0, c1])).toBe(c0);
      const swipe = await loveFromProfile(page, viewer, c0);
      expect(swipe.response.mutual_match).toBe(true);
      await expect(page.getByRole('heading', {name: 'New Match', exact: true})).toBeVisible({timeout: 15000});
      // Back to Liked you: only the other member is left.
      await page.getByRole('button', {name: 'Keep Swiping', exact: true}).click();
      await expect(page.getByRole('heading', {name: 'Liked you · 1', exact: true})).toBeVisible({timeout: 20000});
      await page.getByRole('group', {name: new RegExp(`^${escapeRe(c1.name)}, \\d+ Liked you`)}).click();
      expect(await openedProfile(page, [c0, c1])).toBe(c1);
      await messageMakesMatchAndChat(page, viewer, c1, {viaMatchScreen: true});
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, c0, c1);
    }
  });

  test('web #/likes: Love and Message on a liker\'s profile; Like back and Pass on the list [case:discover.profile_entry_points.web_likes.love] [case:discover.profile_entry_points.web_likes.message] [case:swipe.liked_me.liked_me_like_back_x_likeback.action] [case:swipe.liked_me.liked_me_pass_x_pass.action]', async ({page}, testInfo) => {
    test.setTimeout(240000);
    const problems = watchApp(page, testInfo);
    const {viewer, candidates} = await isolatedCast(4);
    const [c0, c1, c2, c3] = candidates;
    try {
      for (const c of candidates) await like(c, viewer);
      await page.setViewportSize({width: 1440, height: 900});
      await signInAs(page, viewer);
      await dismissRewards(page, 3000);
      const likes = async n => {
        // A fresh load of #/likes (a pushed match/chat screen has no URL of its own).
        await page.goto('/app/#/likes');
        await page.reload();
        await expect(page.getByRole('heading', {name: `Liked you · ${n}`, exact: true})).toBeVisible({timeout: 20000});
      };
      const row = c => page.getByRole('group', {name: new RegExp(`^${escapeRe(c.name)}, \\d+ Liked you`)});
      await likes(4);
      await row(c0).click();
      expect(await openedProfile(page, candidates)).toBe(c0);
      const love = await loveFromProfile(page, viewer, c0);
      expect(love.response.mutual_match).toBe(true);
      await expect(page.getByRole('heading', {name: 'New Match', exact: true})).toBeVisible({timeout: 15000});
      await likes(3);
      await row(c1).click();
      expect(await openedProfile(page, candidates)).toBe(c1);
      await messageMakesMatchAndChat(page, viewer, c1, {viaMatchScreen: true});
      // The list's own buttons.
      await likes(2);
      const back = await nextSwipe(page, c2.userId, () => row(c2).getByRole('button', {name: 'Like back', exact: true}).click());
      expect(back.body).toEqual({user_id: viewer.userId, target_user_id: c2.userId, is_like: true});
      expect(back.response.mutual_match).toBe(true);
      await expect(page.getByRole('heading', {name: 'New Match', exact: true})).toBeVisible({timeout: 15000});
      await likes(1);
      const pass = await nextSwipe(page, c3.userId, () => row(c3).getByRole('button', {name: 'Pass', exact: true}).click());
      expect(pass.body).toEqual({user_id: viewer.userId, target_user_id: c3.userId, is_like: false});
      expect(pass.status).toBe(200);
      await expect(row(c3)).toHaveCount(0, {timeout: 10000});
      expect(await likedBy(c3, viewer)).toBe(false);
      expect(problems).toEqual([]);
    } finally {
      await retire(viewer, ...candidates);
    }
  });
});

/** Today → "Explore more profiles" → the Discover deck (Matches tab, Discover view). */
async function openDeck(page) {
  await page.getByRole('button', {name: 'Explore more profiles', exact: true}).click({timeout: 20000});
  await expect(page).toHaveURL(/#\/matches$/);
  await expect(page.getByRole('checkbox', {name: 'Discover'})).toBeChecked({timeout: 20000});
}

/** Which candidate's profile is open (by its "Name, age" heading). */
async function openedProfile(page, candidates) {
  await expect(introducing(page)).toBeVisible({timeout: 20000});
  const heading = page.getByRole('heading', {name: /^.+, \d+$/}).first();
  await expect(heading).toBeVisible();
  const text = (await heading.textContent()) ?? (await heading.getAttribute('aria-label')) ?? '';
  return candidates.find(c => text.startsWith(`${c.name},`)) ?? null;
}
