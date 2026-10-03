// Fixtures for the end-to-end web-app journeys (app-journeys.spec.js).
//
// Members are created through the same public signup path as
// backend/scripts/verify_signup_workflow.sh, but with a chosen gender, name
// and age so a journey can control who appears in a viewer's Discover deck,
// Today rail and Spotlight. Isolation comes from age: the viewer's preferred
// age range is a single year that only this journey's candidates have, so
// shared seed members and other suites' members never enter the deck and are
// never liked by these tests. Every member is retired (deactivated and
// scheduled for deletion) when the journey ends.
import {randomBytes} from 'node:crypto';
import {crc32, deflateSync} from 'node:zlib';
import {expect} from '@playwright/test';
import {qaId} from './qa.js';

const BFF = 'http://127.0.0.1:18081/v1';

async function call(token, method, path, body, {form} = {}) {
  const headers = {accept: 'application/json'};
  if (token) headers.authorization = `Bearer ${token}`;
  if (body !== undefined && !form) headers['content-type'] = 'application/json';
  const response = await fetch(`${BFF}${path}`, {method, headers, body: form ?? (body === undefined ? undefined : JSON.stringify(body))});
  const text = await response.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { json = text; }
  return {status: response.status, body: json};
}

async function ok(promise, what) {
  const response = await promise;
  expect(response.status, `${what}: ${JSON.stringify(response.body)?.slice(0, 300)}`).toBeLessThan(300);
  return response.body;
}

/** A solid-colour 320×320 PNG, like the signup verification script uploads. */
function png(rgb) {
  const size = 320;
  const raw = Buffer.alloc((size * 3 + 1) * size);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) raw.set(rgb, y * (size * 3 + 1) + 1 + x * 3);
  const chunk = (kind, payload) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(payload.length);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([Buffer.from(kind), payload])) >>> 0);
    return Buffer.concat([len, Buffer.from(kind), payload, crc]);
  };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4); ihdr.set([8, 2, 0, 0, 0], 8);
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

/** Date of birth for someone who is `age` today (birthday a month ago). */
function dobFor(age) {
  const d = new Date();
  d.setUTCFullYear(d.getUTCFullYear() - age);
  d.setUTCMonth(d.getUTCMonth() - 1);
  return d.toISOString().slice(0, 10);
}

/**
 * Creates a completed member. `age` sets the date of birth; `band` (a year
 * of age) restricts whom this member sees. Returns {username, password,
 * userId, token, name}.
 */
export async function newMember({prefix = 'qaj', name, gender = 'F', seeking = 'M', age = 34, band} = {}) {
  const tag = `${Date.now().toString(36)}${randomBytes(2).toString('hex')}`;
  const username = `${prefix}_${tag}`.toLowerCase().slice(0, 30);
  const password = `Qa-${randomBytes(9).toString('base64url')}9a!`;
  name ??= `${prefix} ${tag.slice(-4)}`;
  const signup = await ok(call(null, 'POST', '/auth/signup', {username, password}), 'signup');
  const {user_id: userId, access_token: token} = signup;
  await ok(call(token, 'POST', '/auth/signup/bootstrap', {user_id: userId, username, name, date_of_birth: dobFor(age), gender}), 'bootstrap');
  await ok(call(token, 'PATCH', `/users/${userId}/agreements/terms`, {accepted: true, terms_version: 'v1'}), 'terms');
  await ok(call(token, 'PATCH', `/profile/${userId}/draft`, {
    bio: 'Curious architect who enjoys hiking and thoughtful conversations.',
    seeking_genders: [seeking], min_age_years: band ?? 21, max_age_years: band ?? 60,
    max_distance_km: 200, intent_tags: ['long_term'],
  }), 'draft');
  for (const rgb of [[0x31, 0x78, 0xc6], [0xc6, 0x55, 0x31]]) {
    const form = new FormData();
    form.append('image', new Blob([png(rgb)], {type: 'image/png'}), 'photo.png');
    await ok(call(token, 'POST', `/profile/${userId}/photos`, undefined, {form}), 'photo');
  }
  await ok(call(token, 'POST', `/profile/${userId}/complete`), 'complete');
  return {username, password, userId, token, name};
}

/** Deactivates and schedules deletion; never fails the test. */
export async function retire(...members) {
  for (const m of members.filter(Boolean)) {
    // The browser sign-in revoked the fixture token; take a fresh one.
    const login = await call(null, 'POST', '/auth/login', {username: m.username, password: m.password}).catch(() => null);
    const token = login?.body?.access_token ?? m.token;
    await call(token, 'POST', `/account/${m.userId}/deletion`, {reason: 'web journey cleanup'}).catch(() => {});
    await call(token, 'POST', `/account/${m.userId}/deactivate`, {reason: 'web journey cleanup'}).catch(() => {});
  }
}

/** A fresh API token for `member` (do not use while the browser is signed in as them). */
export async function tokenFor(member) {
  const login = await ok(call(null, 'POST', '/auth/login', {username: member.username, password: member.password}), 'login');
  return login.access_token;
}

/** Raw BFF call as `member` with an explicit token. */
export const bff = (token, method, path, body) => call(token, method, path, body);

/** `liker` likes `target` through the API (fixture setup only). */
export async function like(liker, target) {
  const token = liker.apiToken ??= await tokenFor(liker);
  return ok(call(token, 'POST', '/swipe', {user_id: liker.userId, target_user_id: target.userId, is_like: true}), 'fixture like');
}

// One age per journey, far from seed members (21–45) and the api_e2e suite
// (≈32), so the viewer's deck holds only this journey's people. The BFF
// accepts members up to 80; ages rotate through 61–80 from a random start.
let nextAge = 61 + Math.floor(Math.random() * 20);
export function freshAge() {
  nextAge = nextAge >= 80 ? 61 : nextAge + 1;
  return nextAge;
}

// The full Spotlight screen filters to ages 20–50 on its own; journeys that
// use it take an age from the top of that window (above seed members).
let nextSpotlightAge = 46 + Math.floor(Math.random() * 5);
export function spotlightAge() {
  nextSpotlightAge = nextSpotlightAge >= 50 ? 46 : nextSpotlightAge + 1;
  return nextSpotlightAge;
}

/**
 * A viewer (woman, sees only men aged `age`) and `count` candidates (men of
 * that age seeking women). Candidates get distinct readable names.
 */
export async function isolatedCast(count = 1, prefix = 'qaj', age = freshAge()) {
  const viewer = await newMember({prefix: `${prefix}v`, gender: 'F', seeking: 'M', age: 33, band: age});
  const names = ['Arlo', 'Bram', 'Cyrus', 'Dario'];
  const candidates = [];
  for (let i = 0; i < count; i++) {
    const tag = randomBytes(2).toString('hex');
    candidates.push(await newMember({prefix: `${prefix}c`, name: `${names[i]} ${tag}`, gender: 'M', seeking: 'F', age}));
  }
  return {viewer, candidates, age};
}

/**
 * Types into a Flutter text field the way a person does: click, wait for
 * focus (Flutter attaches its live editor on focus), clear, type, and check
 * the framework's own value.
 */
export async function typeInto(page, field, value) {
  await expect(field).toBeVisible({timeout: 30000});
  await field.click();
  await expect(field).toBeFocused();
  await page.waitForTimeout(200);
  await field.fill('');
  await field.pressSequentially(value, {delay: 10});
  await expect(field).toHaveValue(value);
}

/** Signs in through the real /app form; returns the session's access token. */
export async function signInAs(page, member) {
  const login = page.waitForResponse(r => r.url().endsWith('/v1/auth/login') && r.request().method() === 'POST');
  await page.goto('/app/#/signin');
  const username = page.getByRole('textbox', {name: 'username', exact: true});
  await typeInto(page, username, member.username);
  await username.press('Tab');
  const password = page.getByRole('textbox', {name: 'Password', exact: true});
  await typeInto(page, password, member.password);
  await password.press('Tab');
  await qaId(page, 'qa.signin.login_button').click();
  const response = await login;
  expect(response.status()).toBe(200);
  await expect(page).toHaveURL(/#\/discover$/, {timeout: 30000});
  return (await response.json()).access_token;
}

/**
 * Records POST /v1/swipe calls the browser makes: {body, status, response}.
 * Assertions read the real request and the server's answer.
 */
export function recordSwipes(page) {
  const swipes = [];
  page.on('response', async r => {
    if (!r.url().endsWith('/v1/swipe') || r.request().method() !== 'POST') return;
    swipes.push({body: r.request().postDataJSON(), status: r.status(), response: await r.json().catch(() => null)});
  });
  return swipes;
}

/** Waits for the next POST /v1/swipe for `targetId` and returns {body, status, response}. */
export async function nextSwipe(page, targetId, action) {
  const req = page.waitForRequest(r => r.url().endsWith('/v1/swipe') && r.method() === 'POST' && r.postDataJSON()?.target_user_id === targetId, {timeout: 20000});
  const res = page.waitForResponse(r => r.url().endsWith('/v1/swipe') && r.request().method() === 'POST' && r.request().postDataJSON()?.target_user_id === targetId, {timeout: 20000});
  await action();
  const [request, response] = await Promise.all([req, res]);
  return {body: request.postDataJSON(), status: response.status(), response: await response.json().catch(() => null)};
}

/** Whether `liker` appears in `target`'s Liked you list (server truth). */
export async function likedBy(target, liker) {
  const token = target.apiToken ??= await tokenFor(target);
  const res = await call(token, 'GET', `/discovery/${target.userId}/liked-me`);
  expect(res.status).toBe(200);
  const list = res.body?.profiles ?? res.body?.candidates ?? res.body?.items ?? res.body?.liked_me ?? [];
  return list.some(p => (p.id ?? p.user_id) === liker.userId);
}
