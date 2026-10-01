import {test, expect} from '@playwright/test';
import http from 'node:http';

for (const width of [360,1440]) {
  for (const path of ['/','/features','/safety','/privacy','/guidelines','/membership']) {
    test(`${path} has working content and fits ${width}px`,async({page})=>{
      await page.setViewportSize({width,height:900});
      const response=await page.goto(path); expect(response.status()).toBe(200);
      await expect(page.getByRole('heading',{level:1})).toBeVisible();
      await page.evaluate(()=>document.fonts.ready);
      expect(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      const broken=await page.locator('img').evaluateAll(images=>images.filter(i=>!i.complete||i.naturalWidth===0).length);
      expect(broken).toBe(0);
      if(path==='/')await page.screenshot({path:`../qa/results/2026-09-27-website/home-${width}.png`,fullPage:true});
    });
  }
}
test('feature search, empty results and recovery',async({page})=>{
  await page.goto('/features');
  const search=page.getByRole('searchbox',{name:'Find a feature'});
  await search.fill('chat');await expect(page.locator('[data-feature]:visible')).not.toHaveCount(0);
  await search.fill('zzzz-not-a-feature');await expect(page.locator('[data-feature]:visible')).toHaveCount(0);
  await expect(page.getByRole('status')).toHaveCount(0); // Results are announced by the polite live region.
  await expect(page.locator('#feature-status')).toContainText('No matches');
  await search.fill('');await expect(page.locator('[data-feature]:visible')).toHaveCount(31);
});
test('localised pages carry their language, the full feature list and alternates',async({page})=>{
  const response=await page.goto('/de/features.html'); expect(response.status()).toBe(200);
  await expect(page.locator('html')).toHaveAttribute('lang','de');
  await expect(page.locator('[data-feature]')).toHaveCount(31);
  await expect(page.getByRole('heading',{level:1})).toContainText('Alles');
  expect(await page.locator('link[rel=alternate][hreflang]').count()).toBe(11); // 10 locales + x-default
  await expect(page.locator('link[rel=alternate][hreflang=x-default]')).toHaveAttribute('href','/features');
  await expect(page.locator('link[rel=alternate][hreflang=de]')).toHaveAttribute('href','/de/features');
  const switcher=page.getByRole('combobox',{name:'Sprache'});
  await expect(switcher).toHaveValue('/de/features');
  await switcher.selectOption('/features');
  await expect(page).toHaveURL(/\/features$/);
  await expect(page.locator('html')).toHaveAttribute('lang','en');
  await expect(page.locator('[data-feature]')).toHaveCount(31);
  await page.goto('/ru/safety.html');
  await expect(page.locator('[data-safety-disclaimer]')).toContainText('не является экстренной службой');
});
test('mobile navigation and FAQ operate with keyboard and touch targets',async({page})=>{
  await page.setViewportSize({width:360,height:800});await page.goto('/');
  const menu=page.getByRole('button',{name:'Open menu'});
  await menu.click();await expect(menu).toHaveAttribute('aria-expanded','true');
  await page.getByRole('navigation').getByRole('link',{name:'Features',exact:true}).click();
  await expect(page).toHaveURL(/\/features$/);
  await page.goto('/');const faq=page.locator('summary').filter({hasText:'Can I use Connect in my browser?'});
  await faq.focus();await page.keyboard.press('Enter');
  await expect(faq.locator('..')).toHaveAttribute('open','');
});
test('all public links resolve and unknown paths return 404',async({page,request})=>{
  await page.goto('/features');
  const paths=await page.locator('a[href]').evaluateAll(links=>[...new Set(links.map(a=>new URL(a.href).pathname))]);
  for(const path of paths)expect((await request.get(path)).status(),path).toBe(200);
  expect((await request.get('/not-a-page')).status()).toBe(404);
  expect((await request.get('/app/assets/.env.local')).status()).toBe(403);
  expect((await request.get('/v1/settings/not-your-account')).status()).toBe(401);
});

test('every browser-facing response carries security headers', async ({request}) => {
  for (const path of ['/', '/not-a-page', '/healthz', '/v1/settings/not-your-account']) {
    const response = await request.get(path);
    const expectedDefaultSource = path.startsWith('/v1/')
      ? "default-src 'none'"
      : "default-src 'self'";
    expect(response.headers()['content-security-policy'], path).toContain(expectedDefaultSource);
    expect(response.headers()['x-content-type-options'], path).toBe('nosniff');
    expect(response.headers()['x-frame-options'], path).toBe('DENY');
    const expectedReferrerPolicy = path.startsWith('/v1/')
      ? 'no-referrer'
      : 'strict-origin-when-cross-origin';
    expect(response.headers()['referrer-policy'], path).toBe(expectedReferrerPolicy);
    expect(response.headers()['permissions-policy'], path).toContain('geolocation=()');
  }
  expect((await request.get('/v1/settings/not-your-account')).headers()['cache-control']).toBe('no-store');
});

test('website rejects untrusted hosts and oversized proxy bodies', async () => {
  const requestStatus = options => new Promise((resolve, reject) => {
    const req = http.request({host: '127.0.0.1', port: 4190, ...options}, res => {
      res.resume();
      res.on('end', () => resolve(res.statusCode));
    });
    req.on('error', reject);
    req.end();
  });
  expect(await requestStatus({path: '/', headers: {Host: 'evil.example'}})).toBe(421);
  expect(await requestStatus({
    path: '/v1/auth/login',
    method: 'POST',
    headers: {Host: '127.0.0.1:4190', 'Content-Length': 26 * 1024 * 1024},
  })).toBe(413);
});

test('browser login, live stream, deep links, preferences and reload recovery',async({page})=>{
  test.setTimeout(180000);
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const socketEvents=[];page.on('websocket',socket=>socket.on('framereceived',event=>socketEvents.push(String(event.payload))));
  await page.goto('/app/#/signin');
  const username = page.getByRole('textbox',{name:'username',exact:true});
  await username.click();
  await username.pressSequentially(process.env.QA_EXISTING_USERNAME || 'qa_full_20260926_isolated',{delay:15});
  await username.press('Tab');
  const password = page.getByRole('textbox',{name:'Password',exact:true});
  await password.click();
  await password.pressSequentially(process.env.QA_EXISTING_PASSWORD || 'Password123!',{delay:15});
  await password.press('Tab');
  await expect(username).toHaveValue(process.env.QA_EXISTING_USERNAME || 'qa_full_20260926_isolated');
  await page.getByRole('button',{name:'qa.signin.login_button',exact:true}).click();
  await expect(page.getByText('Your pace. Your choice.',{exact:true})).toBeVisible({timeout:30000});
  await expect.poll(()=>socketEvents.some(e=>e.includes('stream.connected')),{timeout:15000}).toBe(true);
  await page.getByText('Preferences',{exact:true}).click();
  await expect(page).toHaveURL(/#\/preferences$/);
  await expect(page.getByText('Edit Preferences',{exact:true})).toBeVisible();
  await page.getByText('Save Preferences',{exact:true}).click();
  await expect(page.getByText(/Preferences saved/).last()).toBeVisible({timeout:10000});
  await page.reload();await expect(page.getByText('Edit Preferences',{exact:true})).toBeVisible({timeout:30000});
  await expect(page.getByText('Your pace. Your choice.',{exact:true})).toBeVisible();
  await page.getByText('All features',{exact:true}).first().click();
  await expect(page.getByText('Make this space yours.',{exact:true})).toBeVisible();
  await page.screenshot({path:'../qa/results/2026-09-27-website/member-desktop.png'});
  await page.goBack();await expect(page.getByText('Edit Preferences',{exact:true})).toBeVisible();
  expect(errors).toEqual([]);
  await page.getByText('Sign out',{exact:true}).click();
  await expect(page.getByRole('textbox',{name:'username',exact:true})).toBeVisible();
  await page.reload();await expect(page.getByRole('textbox',{name:'username',exact:true})).toBeVisible();
});

 test('signup sign-in link preserves browser auth routing',async({page})=>{
  await page.goto('/app/#/signup');
  await page.getByRole('button',{name:'Sign in',exact:true}).click();
  await expect(page).toHaveURL(/#\/signin$/);
  await expect(page.getByRole('textbox',{name:'username',exact:true})).toBeVisible();
 });
