import {test, expect} from '@playwright/test';

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
    process.env.QA_EXISTING_USERNAME || 'qa_full_20260926_isolated',
  );
  const password = page.getByRole('textbox', {name: 'Password', exact: true});
  await password.fill(process.env.QA_EXISTING_PASSWORD || 'Password123!');
  await expect(password).toHaveValue(
    process.env.QA_EXISTING_PASSWORD || 'Password123!',
  );
  await page
    .getByRole('button', {name: 'qa.signin.login_button', exact: true})
    .click();
  await expect(page).toHaveURL(/#\/discover$/, {timeout: 30000});

  await page.goto('/app/#/settings');
  await expect(page.getByRole('button', {name: /^Dating Preferences/})).toBeVisible({
    timeout: 15000,
  });
  await expect(
    page.getByRole('button', {name: /qa\.settings\.theme_preset\./}),
  ).toHaveCount(0);
  await expect(page.getByText('Appearance', {exact: true})).toHaveCount(0);
});
