import {test, expect} from '@playwright/test';
import {watchPage} from './support/site.js';

// Public, account-free interactive pages other than the contact/support form
// (owned by another session) and the shared-story report form (blog-public.spec.js).

test('Pass the Chapter: choose, copy a remix link, reopen it and reset', async ({page, context}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  const watch = watchPage(page);
  const catalogue = page.waitForResponse(r => r.url().endsWith('/v1/chapters/catalogue'));
  await page.goto('/chapter.html');
  const scenes = (await (await catalogue).json()).scenes;
  expect(scenes.length).toBeGreaterThan(0);
  const [first] = scenes;
  await expect(page.locator('#studio')).toBeVisible();
  await expect(page.locator('#title')).toHaveText(first.title);
  const copy = page.getByRole('button', {name: 'Copy remix link'});
  await expect(copy).toBeDisabled();
  await expect(page.getByRole('button', {name: 'Pass this chapter'})).toBeDisabled();

  const beginning = page.locator('#beginnings').getByRole('button', {name: first.beginnings[1], exact: true});
  await beginning.click();
  await expect(beginning).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('#beginning')).toHaveText(first.beginnings[1]);
  await expect(copy).toBeDisabled();
  await page.locator('#surprises').getByRole('button', {name: first.surprises[2], exact: true}).click();
  await expect(page.locator('#result')).toHaveText(`${first.beginnings[1]}. Then… ${first.surprises[2]}.`);
  await expect(copy).toBeEnabled();
  // Keyboard users keep their place after a choice re-renders the options.
  await expect(page.locator('#surprises').getByRole('button', {name: first.surprises[2], exact: true})).toBeFocused();

  await copy.click();
  await expect(page.locator('#status')).toContainText('Remix link copied');
  const link = await page.evaluate(() => navigator.clipboard.readText());
  const url = new URL(link);
  expect(url.pathname).toBe('/chapter.html');
  expect(Object.fromEntries(url.searchParams)).toEqual({scene: first.id, beginning: '1', surprise: '2'});

  await page.goto(url.pathname + url.search);
  await expect(page.locator('#result')).toHaveText(`${first.beginnings[1]}. Then… ${first.surprises[2]}.`);
  await page.getByRole('button', {name: 'Start another'}).click();
  await expect(page.locator('#status')).toContainText('A fresh page');
  await expect(copy).toBeDisabled();
  await expect(page.locator('#beginnings [aria-pressed=true]')).toHaveCount(0);

  if (scenes.length > 1) {
    await page.locator('#scenes').getByRole('button', {name: scenes[1].title, exact: true}).click();
    await expect(page.locator('#title')).toHaveText(scenes[1].title);
  }
  expect(watch.problems()).toEqual([]);
});

test('Pass the Chapter: tampered remix links degrade safely', async ({page}) => {
  const watch = watchPage(page);
  await page.goto('/chapter.html?scene=<img src=x onerror=alert(1)>&beginning=99&surprise=-1');
  await expect(page.locator('#studio')).toBeVisible();
  await expect(page.locator('#result')).toHaveText('One small choice can lead somewhere lovely.');
  await expect(page.getByRole('button', {name: 'Copy remix link'})).toBeDisabled();
  expect(await page.locator('#studio img').count()).toBe(0);
  expect(watch.problems()).toEqual([]);
});

test('Pass the Chapter: a missing shared card shows a calm error, no studio', async ({page}) => {
  await page.goto('/chapter.html?share=00000000-0000-4000-8000-000000000000');
  await expect(page.locator('#status')).toContainText(/unavailable|withdrawn/);
  await expect(page.locator('#studio')).toBeHidden();
});

test('feature search is keyboard operable and announces results politely', async ({page}) => {
  await page.goto('/features');
  const total = await page.locator('[data-feature]').count();
  await page.locator('#feature-search').focus();
  await page.keyboard.type('safety');
  const visible = await page.locator('[data-feature]:visible').count();
  expect(visible).toBeGreaterThan(0);
  expect(visible).toBeLessThan(total);
  await expect(page.locator('#feature-status')).toHaveAttribute('aria-live', 'polite');
  await expect(page.locator('#feature-status')).toContainText(String(visible));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.press('Backspace');
  await expect(page.locator('[data-feature]:visible')).toHaveCount(total);
  // Markup typed into the search is treated as text.
  await page.locator('#feature-search').fill('<b>chat</b>');
  await expect(page.locator('#feature-status b')).toHaveCount(0);
});
