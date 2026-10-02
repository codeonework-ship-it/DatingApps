import {test, expect} from '@playwright/test';
import fs from 'node:fs';
import {dismissRewards} from './support/app.js';
import {isolatedCast, retire, signInAs} from './support/journeys.js';
const out = [];
const snap = async (page, label) => { out.push('==== ' + label + '\n' + await page.locator('body').ariaSnapshot()); await page.screenshot({path: '/private/tmp/claude-501/-Users-anandsadasivan-Documents-Workspaces-Development-GitHub-Dating-apps/7eef4b8b-1760-4146-b3a7-21ecc3ad226e/scratchpad/dbg-' + label + '.png'}); };
test('debug lists', async ({page}) => {
  test.setTimeout(240000);
  const {viewer, candidates} = await isolatedCast(2);
  try {
    await page.setViewportSize({width: 1440, height: 900});
    await signInAs(page, viewer);
    await dismissRewards(page, 3000);
    await page.getByRole('button', {name: 'Explore more profiles', exact: true}).click({timeout: 20000});
    await page.getByRole('button', {name: /^qa\.discovery\.pass_button/}).click({timeout: 20000});
    await page.waitForTimeout(1500);
    await page.getByRole('button', {name: /^qa\.discovery\.like_button/}).click();
    await page.waitForTimeout(1500);
    await snap(page, 'afterdeck');
    await page.getByRole('button', {name: /^qa\.discovery\.passed_button/}).click();
    await page.waitForTimeout(2500);
    await snap(page, 'passed');
    await page.getByRole('button', {name: 'Back'}).first().click();
    await page.waitForTimeout(1500);
    await page.getByRole('button', {name: 'My profile', exact: true}).click(); await page.waitForTimeout(3000);
    for (let i = 0; i < 4; i++) { await page.mouse.move(800, 500); await page.mouse.wheel(0, 800); await page.waitForTimeout(400); }
    await page.getByRole('button', {name: /^Open You liked/}).click();
    await page.waitForTimeout(2500);
    await snap(page, 'liked');
  } finally { fs.writeFileSync('/private/tmp/claude-501/-Users-anandsadasivan-Documents-Workspaces-Development-GitHub-Dating-apps/7eef4b8b-1760-4146-b3a7-21ecc3ad226e/scratchpad/dbg.txt', out.join('\n')); await retire(viewer, ...candidates); }
});
