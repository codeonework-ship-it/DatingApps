import {test, expect} from '@playwright/test';
const id='6bc90390-c430-4f41-b302-13dd67e78b75';
const photo='17000000-0000-4000-8000-000000000001';
const path=`/v1/blog/public/${id}`;
for(const width of [320,1440]){
 test(`approved story renders safely at ${width}px`,async({page})=>{
  await page.setViewportSize({width,height:900});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.route(`**${path}`,r=>r.fulfill({json:{title:'A little Sunday <script>bad()</script>',excerpt:'Coffee, a bookshop and a long walk.\nWhat would you add?',joint:true,photos:[]}}));
  await page.goto(`/story.html?id=${id}`);
  await expect(page.locator('#title')).toHaveText('A little Sunday <script>bad()</script>');
  await expect(page.locator('#kind')).toHaveText('TWO VOICES. ONE SHARED CHAPTER.');
  expect(await page.locator('#title script').count()).toBe(0);
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:`../qa/results/blogging-completion/public-${width}.png`,fullPage:true});
  expect(errors).toEqual([]);
 });
}
test('withdrawn link clears its previously displayed content',async({page})=>{
 let available=true;
 await page.route(`**${path}`,r=>available?r.fulfill({json:{title:'A shared memory',excerpt:'Approved prose',joint:false,photos:[]}}):r.fulfill({status:404,json:{error:'unavailable'}}));
 await page.goto(`/story.html?id=${id}`);await expect(page.locator('#excerpt')).toHaveText('Approved prose');
 available=false;
 await page.evaluate(()=>document.dispatchEvent(new Event('visibilitychange')));
 await expect(page.locator('#chapter')).toBeHidden();await expect(page.locator('#excerpt')).toHaveText('');await expect(page.locator('#status')).toContainText('no longer shared');
});
test('report retry preserves text and sends no member credentials',async({page})=>{
 let fail=true;let sent;
 await page.route(`**${path}`,r=>r.fulfill({json:{title:'Approved',excerpt:'Approved prose',joint:false,photos:[]}}));
 await page.route(`**${path}/report`,r=>{sent=r.request();return fail?r.fulfill({status:503,json:{error:'retry'}}):r.fulfill({json:{accepted:true}});});
 await page.goto(`/story.html?id=${id}`);await page.getByText('Report this shared Chapter',{exact:true}).click();
 await page.locator('#reason').selectOption('inappropriate');await page.locator('#description').fill('Review this test concern');await page.getByRole('button',{name:'Send report'}).click();
 await expect(page.locator('#report-status')).toContainText('try again');await expect(page.locator('#description')).toHaveValue('Review this test concern');
 fail=false;await page.getByRole('button',{name:'Send report'}).click();await expect(page.locator('#report-status')).toContainText('Report received');expect(sent.headers().authorization).toBeUndefined();expect(sent.postDataJSON()).toEqual({reason:'inappropriate',description:'Review this test concern'});
});
test('incomplete links never fetch a source',async({page})=>{
 const requests=[];page.on('request',r=>{if(r.url().includes('/v1/blog/'))requests.push(r.url());});
 await page.goto('/story.html?id=not-a-publication');await expect(page.locator('#status')).toHaveText('This Chapter link is incomplete.');expect(requests).toEqual([]);
});
