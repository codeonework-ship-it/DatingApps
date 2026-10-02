// Fresh, isolated test members for web-app specs.
//
// Never sign in as a shared QA account: a sign-in invalidates that account's
// other sessions (emulators, other people's browsers). Each call creates a new
// completed member through backend/scripts/verify_signup_workflow.sh with a
// random password that lives only in this process.
import {execFileSync} from 'node:child_process';
import {randomBytes} from 'node:crypto';
import {resolve} from 'node:path';
import {expect} from '@playwright/test';
import {websiteDir} from './site.js';

export function createMember(prefix = 'qaweb') {
  let username = `${prefix}_${Date.now().toString(36)}${randomBytes(2).toString('hex')}`.toLowerCase();
  const password = `Qa-${randomBytes(9).toString('base64url')}9a!`;
  const run = name => execFileSync('bash', [resolve(websiteDir, '..', 'backend', 'scripts', 'verify_signup_workflow.sh')], {
    env: {...process.env, SIGNUP_TEST_USERNAME: name, SIGNUP_TEST_PASSWORD: password},
    encoding: 'utf8',
    timeout: 60000,
  });
  let output;
  try {
    output = run(username);
  } catch {
    // Fixture setup only: one retry (new username) when the shared local stack
    // is mid-restart. Product assertions never retry.
    execFileSync('sleep', ['5']);
    username = `${username}r`;
    output = run(username);
  }
  const result = JSON.parse(output.slice(output.lastIndexOf('{\n')));
  return {username, password, userId: result.user_id};
}

/** Signs in through the real /app sign-in form and waits for the workspace. */
export async function signIn(page, member) {
  await page.goto('/app/#/signin');
  const username = page.getByRole('textbox', {name: 'username', exact: true});
  await expect(username).toBeVisible({timeout: 30000});
  await username.click();
  await page.waitForTimeout(200); // Flutter attaches its live editor on focus.
  await username.pressSequentially(member.username, {delay: 10});
  await username.press('Tab');
  const password = page.getByRole('textbox', {name: 'Password', exact: true});
  await password.click();
  await page.waitForTimeout(200);
  await password.pressSequentially(member.password, {delay: 10});
  await password.press('Tab');
  await expect(username).toHaveValue(member.username);
  const login = page.waitForResponse(r => r.url().endsWith('/v1/auth/login') && r.request().method() === 'POST');
  await page.getByRole('button', {name: 'qa.signin.login_button', exact: true}).click();
  expect((await login).status()).toBe(200);
  await expect(page).toHaveURL(/#\/discover$/, {timeout: 30000});
}

/**
 * A member for specs that just need "a signed-in member": QA_EXISTING_USERNAME
 * / QA_EXISTING_PASSWORD when explicitly provided, otherwise one fresh member
 * per spec file, created lazily on first use.
 */
export function qaMember(prefix = 'qaweb') {
  let member;
  const get = () => member ??= process.env.QA_EXISTING_USERNAME
    ? {username: process.env.QA_EXISTING_USERNAME, password: process.env.QA_EXISTING_PASSWORD}
    : createMember(prefix);
  return {get username() { return get().username; }, get password() { return get().password; }};
}
