import {test, expect} from '@playwright/test';
import {qaMember} from './support/member.js';
import {qaId, qaIdPrefix} from './support/qa.js';

// Never the shared QA account: signing in invalidates its other sessions.
const member = qaMember();

// Product decision (2026-09-27, reconfirmed the same day): the signed-in
// browser app always uses the website's Daylight look. Member presets (Star
// Wars, Tron, …) are a mobile choice; the lock lives in
// app/lib/features/common/providers/app_theme_provider.dart and is guarded by
// app/test/features/theme/web_theme_lock_test.dart.
test('browser app keeps Daylight and hides the theme picker', async ({page}) => {
  test.setTimeout(60000);
  await page.setViewportSize({width: 1440, height: 900});
  await page.goto('/app/#/signin');

  const username = page.getByRole('textbox', {name: 'username', exact: true});
  await expect(username).toBeVisible({timeout: 30000});
  await page.waitForTimeout(500);
  await username.fill(
    member.username,
  );
  const password = page.getByRole('textbox', {name: 'Password', exact: true});
  await password.fill(member.password);
  await expect(password).toHaveValue(
    member.password,
  );
  await qaId(page, 'qa.signin.login_button').click();
  await expect(page).toHaveURL(/#\/discover$/, {timeout: 30000});

  await page.goto('/app/#/settings');
  // Account comes first; the theme picker (mobile only) would follow it, so
  // it would be on screen here if it were shown.
  await expect(page.getByRole('button', {name: /^Sign out of all devices/})).toBeVisible({
    timeout: 15000,
  });
  // Neither the strip (qa.settings.theme_presets) nor any preset tile.
  await expect(qaIdPrefix(page, 'qa.settings.theme_preset')).toHaveCount(0);
  await expect(page.getByText('Appearance', {exact: true})).toHaveCount(0);
});
