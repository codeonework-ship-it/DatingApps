import {test, expect} from '@playwright/test';
import {createMember} from './support/member.js';
import {api, bringIntoView, dismissRewards, noOverflow, scrollUntil, shots, signInWithToken, watchApp} from './support/app.js';

// Today's "YOUR STORY" card (profile_story_nudge.dart) with a fresh member:
// 0/3 with prompt ideas, opens the story editor, then reflects a story
// published through the real API (PUT /v1/profile/{id}/stories).
for (const width of [320, 390, 1440]) {
  test(`Today story card: empty, opens the editor, then counts a published story at ${width}px`, async ({page, request}, testInfo) => {
    test.setTimeout(150000);
    const problems = watchApp(page, testInfo);
    const member = createMember('qastory');
    await page.setViewportSize({width, height: 900});
    const token = await signInWithToken(page, member);
    await dismissRewards(page);

    const card = page.getByRole('heading', {name: 'YOUR STORY', exact: true});
    await expect(page.getByRole('button', {name: 'Refresh Today', exact: true})).toBeVisible({timeout: 30000});
    await expect(await scrollUntil(page, page.getByRole('button', {name: 'Write your first story', exact: true}))).toBeVisible();
    await expect(card).toBeVisible();
    await expect(page.getByRole('heading', {name: 'Tell a little more of your story', exact: true})).toBeVisible();
    // The bar's "0/3" is decorative; its semantics carry the count.
    await expect(page.getByText(/0 of 3 stories written/)).toBeVisible();
    await expect(page.getByText(/Ideas to start with/)).toBeVisible();
    for (const idea of ['A small thing I always make time for', 'A weekend worth sharing', 'A first hello I would love']) {
      await expect(page.getByRole('checkbox', {name: idea, exact: true})).toBeVisible();
    }
    expect(await noOverflow(page), 'Today overflows').toBe(true);
    await bringIntoView(page, card);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/today-story-empty-${width}.png`});

    await page.getByRole('button', {name: 'Write your first story', exact: true}).click();
    await expect(page.getByText('A little more you', {exact: true}).first()).toBeVisible({timeout: 15000});
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/today-story-editor-${width}.png`});
    await page.getByRole('button', {name: 'Back'}).first().click();
    await expect(page.getByText('A little more you', {exact: true})).toHaveCount(0);

    // An idea chip opens the same editor.
    await page.getByRole('checkbox', {name: 'A weekend worth sharing', exact: true}).click();
    await expect(page.getByText('A little more you', {exact: true}).first()).toBeVisible({timeout: 15000});
    await page.getByRole('button', {name: 'Back'}).first().click();

    const saved = await api(request, token, 'PUT', `/profile/${member.userId}/stories`, {
      expected_version: 0, published: true,
      stories: [{prompt_id: 'weekend', text: 'A long walk, a second-hand bookshop and soup after.'}],
    });
    expect(saved.status).toBe(200);
    expect(saved.body.stories).toHaveLength(1);

    await page.reload();
    await expect(page.getByRole('button', {name: 'Refresh Today', exact: true})).toBeVisible({timeout: 30000});
    await dismissRewards(page);
    await expect(await scrollUntil(page, page.getByRole('button', {name: 'Add another story', exact: true}))).toBeVisible();
    await expect(page.getByRole('heading', {name: '1 of 3 stories shared', exact: true})).toBeVisible();
    await expect(page.getByText(/1 of 3 stories written/)).toBeVisible();
    await expect(page.getByText(/Latest: “A weekend worth sharing”/)).toBeVisible();
    // Ideas only nudge the first story.
    await expect(page.getByText(/Ideas to start with/)).toHaveCount(0);
    await expect(page.getByRole('button', {name: 'Write your first story', exact: true})).toHaveCount(0);
    await bringIntoView(page, card);
    await dismissRewards(page, 1500);
    await page.screenshot({path: `${shots}/today-story-one-${width}.png`});

    await page.getByRole('button', {name: 'Add another story', exact: true}).click();
    await expect(page.getByText('A little more you', {exact: true}).first()).toBeVisible({timeout: 15000});
    expect(problems).toEqual([]);
  });
}
