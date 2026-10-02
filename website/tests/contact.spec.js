import {test, expect} from '@playwright/test';

// Public support form. The API is mocked with page.route so these run without
// the Go backend; the contract is POST /v1/support/contact (no auth, JSON).
const API = '**/v1/support/contact';

/** Records CSP violations, console errors and page errors for a page. */
async function watch(page) {
  const problems = [];
  page.on('pageerror', e => problems.push(`pageerror: ${e.message}`));
  page.on('console', m => { if (m.type() === 'error') problems.push(`console: ${m.text()}`); });
  await page.addInitScript(() => {
    document.addEventListener('securitypolicyviolation', e => {
      console.error(`CSP violation: ${e.violatedDirective} ${e.blockedURI}`);
    });
  });
  return problems;
}

async function fillValid(page, overrides = {}) {
  const v = {email: 'member@example.com', name: 'Sam', category: 'account_login',
    subject: 'Cannot sign in', description: 'The code never arrives on my phone.', ...overrides};
  await page.getByLabel('Email address').fill(v.email);
  await page.getByLabel('Name (optional)').fill(v.name);
  await page.getByLabel('Topic').selectOption(v.category);
  await page.getByLabel('Subject').fill(v.subject);
  await page.locator('#contact-description').fill(v.description);
  return v;
}

const alert = page => page.locator('[data-contact-alert]');

for (const width of [360, 1440]) {
  test(`contact page renders the form without CSP violations at ${width}px`, async ({page}) => {
    const problems = await watch(page);
    await page.setViewportSize({width, height: 900});
    const response = await page.goto('/contact');
    expect(response.status()).toBe(200);
    expect(response.headers()['content-security-policy']).toContain("script-src 'self'");
    await expect(page.getByRole('heading', {level: 1})).toHaveText('How can we help?');
    await expect(page.locator('#contact-form')).toBeVisible(); // revealed by contact.js
    await expect(page.locator('[data-contact-emergency]')).toContainText('not an emergency service');
    await expect(page.getByRole('link', {name: /Open Help & support/})).toHaveAttribute('href', '/app/#/help');
    await expect(page.getByRole('link', {name: /Visit the safety center/})).toHaveAttribute('href', '/safety');
    const categories = await page.locator('#contact-category option').evaluateAll(o => o.map(x => x.value));
    expect(categories).toEqual(['', 'account_login', 'verification', 'payments_billing', 'safety_harassment',
      'matches_chat', 'technical', 'feature_request', 'privacy_data', 'other']);
    await expect(page.locator('#contact-category option[value=technical]')).toHaveText('Technical problem / bug');
    await page.evaluate(() => document.fonts.ready);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    // No inline script/style/handlers: everything is same-origin files.
    expect(await page.locator('script:not([src]), [style], [onclick], [onsubmit]').count()).toBe(0);
    await page.screenshot({path: `../qa/results/2026-09-27-website/contact-${width}.png`, fullPage: true});
    expect(problems).toEqual([]);
  });
}

test('footer links to the contact page in each locale', async ({page}) => {
  await page.goto('/');
  await expect(page.locator('footer a[href="/contact"]')).toHaveText('Contact support');
  await page.goto('/de/safety');
  await expect(page.locator('footer a[href="/de/contact"]')).toHaveText('Support kontaktieren');
});

test('honeypot is present, hidden from people and skipped by keyboard', async ({page}) => {
  await page.goto('/contact');
  const trap = page.locator('#contact-website');
  await expect(trap).toHaveCount(1);
  await expect(trap).toHaveAttribute('tabindex', '-1');
  await expect(trap).toHaveAttribute('autocomplete', 'off');
  await expect(page.locator('.contact-hp')).toHaveAttribute('aria-hidden', 'true');
  await expect(trap).not.toBeInViewport();
  await page.locator('#contact-description').focus();
  await page.keyboard.press('Tab');
  await expect(page.locator('#contact-submit')).toBeFocused();
});

test('valid submission posts JSON and shows the reference', async ({page}) => {
  const problems = await watch(page);
  let request;
  let release;
  const held = new Promise(resolve => { release = resolve; });
  await page.route(API, async route => {
    request = route.request();
    await held;
    await route.fulfill({status: 202, json: {success: true, received: true, reference: 'CN-2026-000124'}});
  });
  await page.goto('/contact');
  const v = await fillValid(page);
  await expect(page.locator('#contact-description-count')).toHaveText(`${v.description.length} of 5000 characters`);
  const submit = page.locator('#contact-submit');
  await submit.click();
  // Loading state while the request is in flight.
  await expect(submit).toBeDisabled();
  await expect(submit).toHaveText('Sending…');
  await expect(submit).toHaveAttribute('aria-busy', 'true');
  release();

  const success = page.locator('#contact-success');
  await expect(success).toBeVisible();
  await expect(success).toBeFocused();
  await expect(success).toContainText('Message received');
  await expect(success).toContainText('reply by email');
  await expect(page.locator('#contact-reference strong')).toHaveText('CN-2026-000124');
  await expect(page.locator('#contact-form')).toBeHidden();

  expect(request.method()).toBe('POST');
  expect(request.headers()['content-type']).toBe('application/json');
  expect(request.headers().authorization).toBeUndefined();
  expect(request.postDataJSON()).toEqual({email: v.email, name: v.name, category: v.category,
    subject: v.subject, description: v.description, locale: 'en', website: ''});

  // "Send another" keeps the sender and clears the message.
  await page.getByRole('button', {name: 'Send another message'}).click();
  await expect(page.locator('#contact-form')).toBeVisible();
  await expect(page.getByLabel('Email address')).toHaveValue(v.email);
  await expect(page.getByLabel('Subject')).toHaveValue('');
  await expect(page.getByLabel('Topic')).toBeFocused();
  expect(problems).toEqual([]);
});

test('success without a reference still confirms; optional name is omitted', async ({page}) => {
  let body;
  await page.route(API, route => { body = route.request().postDataJSON(); return route.fulfill({status: 202, json: {success: true, received: true}}); });
  await page.goto('/contact');
  await fillValid(page, {name: ''});
  await page.locator('#contact-submit').click();
  await expect(page.locator('#contact-success')).toBeVisible();
  await expect(page.locator('#contact-reference')).toBeHidden();
  expect(body).not.toHaveProperty('name');
  expect(body.website).toBe('');
});

test('client validation lists errors, focuses the summary and sends nothing', async ({page}) => {
  let calls = 0;
  await page.route(API, route => { calls++; return route.fulfill({status: 202, json: {success: true}}); });
  await page.goto('/contact');
  await page.getByLabel('Email address').fill('not-an-email');
  await page.getByLabel('Subject').fill('Hi');
  await page.locator('#contact-submit').click();

  const summary = alert(page);
  await expect(summary).toBeFocused();
  await expect(summary).toContainText('Please check the following:');
  await expect(summary.locator('li')).toHaveText([
    'Enter a valid email address, like name@example.com.',
    'Choose a topic.',
    'Enter a subject between 4 and 120 characters.',
    'Enter a message of up to 5,000 characters.',
  ]);
  await expect(page.locator('#contact-feedback')).toHaveAttribute('aria-live', 'polite');
  await expect(page.getByLabel('Email address')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.locator('#contact-email-error')).toHaveText('Enter a valid email address, like name@example.com.');

  await summary.getByRole('link', {name: 'Choose a topic.'}).click();
  await expect(page.getByLabel('Topic')).toBeFocused();
  // Fixing a field clears its inline error.
  await page.getByLabel('Email address').fill('member@example.com');
  await expect(page.getByLabel('Email address')).not.toHaveAttribute('aria-invalid', 'true');
  await expect(page.locator('#contact-email-error')).toBeHidden();
  // Whitespace-only subject/message do not count.
  await page.getByLabel('Topic').selectOption('other');
  await page.getByLabel('Subject').fill('     ');
  await page.locator('#contact-description').fill('   ');
  await page.locator('#contact-submit').click();
  await expect(alert(page).locator('li')).toHaveCount(2);
  expect(calls).toBe(0);
});

test('server validation message is shown and the form is kept', async ({page}) => {
  await page.route(API, route => route.fulfill({status: 400, json: {success: false, error: 'subject must be between 4 and 120 characters'}}));
  await page.goto('/contact');
  const v = await fillValid(page);
  await page.locator('#contact-submit').click();
  await expect(alert(page)).toBeFocused();
  await expect(alert(page)).toHaveText('subject must be between 4 and 120 characters');
  await expect(page.getByLabel('Subject')).toHaveValue(v.subject);
  await expect(page.locator('#contact-submit')).toBeEnabled();
  await expect(page.locator('#contact-submit')).toHaveText('Send message');
});

test('rate limit, disabled feature and outages show their messages', async ({page}) => {
  let reply = route => route.fulfill({status: 429, json: {error_code: 'SUPPORT_RATE_LIMITED', retry_after_seconds: 600}});
  await page.route(API, route => reply(route));
  await page.goto('/contact');
  const v = await fillValid(page);
  const submit = page.locator('#contact-submit');

  await submit.click();
  await expect(alert(page)).toHaveText('Too many requests. Please wait a while and try again later.');
  await expect(alert(page)).toBeFocused();
  await expect(page.locator('#contact-description')).toHaveValue(v.description);

  reply = route => route.fulfill({status: 403, json: {success: false, error_code: 'FEATURE_DISABLED'}});
  await submit.click();
  await expect(alert(page)).toContainText('The contact form isn’t available right now.');

  reply = route => route.fulfill({status: 503, body: 'upstream down'});
  await submit.click();
  await expect(alert(page)).toHaveText('We couldn’t send your message. Check your connection and try again.');

  reply = route => route.abort('failed');
  await submit.click();
  await expect(alert(page)).toHaveText('We couldn’t send your message. Check your connection and try again.');
  await expect(submit).toBeEnabled();

  reply = route => route.fulfill({status: 202, json: {success: true, received: true, reference: 'CN-2026-000125'}});
  await submit.click();
  await expect(page.locator('#contact-reference')).toContainText('CN-2026-000125');
});

test('localised contact page sends its locale and shows translated copy', async ({page}) => {
  const problems = await watch(page);
  let body;
  await page.route(API, route => { body = route.request().postDataJSON(); return route.fulfill({status: 202, json: {success: true, received: true, reference: 'CN-2026-000126'}}); });
  const response = await page.goto('/de/contact');
  expect(response.status()).toBe(200);
  await expect(page.locator('html')).toHaveAttribute('lang', 'de');
  await expect(page.getByRole('heading', {level: 1})).toHaveText('Wie können wir helfen?');
  await expect(page.locator('#contact-category option[value=payments_billing]')).toHaveText('Zahlungen & Abrechnung');
  await page.locator('#contact-submit').click();
  await expect(alert(page)).toContainText('Bitte prüfe Folgendes:');
  await page.getByLabel('E-Mail-Adresse').fill('mitglied@example.com');
  await page.getByLabel('Thema').selectOption('payments_billing');
  await page.getByLabel('Betreff').fill('Doppelte Abbuchung');
  await page.locator('#contact-description').fill('Mein Abo wurde zweimal abgebucht.');
  await expect(page.locator('#contact-description-count')).toHaveText('33 von 5000 Zeichen');
  await page.locator('#contact-submit').click();
  await expect(page.locator('#contact-success')).toContainText('Nachricht erhalten');
  await expect(page.locator('#contact-reference')).toContainText('CN-2026-000126');
  expect(body.locale).toBe('de');
  expect(body.category).toBe('payments_billing');
  // Every locale's page exists and declares its language.
  for (const [prefix, lang] of [['en-gb', 'en-GB'], ['fr', 'fr'], ['ru', 'ru'], ['es', 'es'], ['it', 'it'], ['pt', 'pt'], ['nl', 'nl'], ['pl', 'pl']]) {
    expect((await page.goto(`/${prefix}/contact`)).status(), prefix).toBe(200);
    await expect(page.locator('html')).toHaveAttribute('lang', lang);
    await expect(page.locator('#contact-form')).toBeVisible();
  }
  expect(problems).toEqual([]);
});
