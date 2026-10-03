import {test, expect} from '@playwright/test';
const id='6bc90390-c430-4f41-b302-13dd67e78b75';
const photo='17000000-0000-4000-8000-000000000001';
const path=`/v1/blog/public/${id}`;
for(const width of [320,1440]){
 test(`approved story renders safely at ${width}px [case:site.story.renders_safely]`,async({page})=>{
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
test('withdrawn link clears its previously displayed content [case:site.story.withdrawn]',async({page})=>{
 let available=true;
 await page.route(`**${path}`,r=>available?r.fulfill({json:{title:'A shared memory',excerpt:'Approved prose',joint:false,photos:[]}}):r.fulfill({status:404,json:{error:'unavailable'}}));
 await page.goto(`/story.html?id=${id}`);await expect(page.locator('#excerpt')).toHaveText('Approved prose');
 available=false;
 await page.evaluate(()=>document.dispatchEvent(new Event('visibilitychange')));
 await expect(page.locator('#chapter')).toBeHidden();await expect(page.locator('#excerpt')).toHaveText('');await expect(page.locator('#status')).toContainText('no longer shared');
});
test('report retry preserves text and sends no member credentials [case:site.story.report_submit.retry]',async({page})=>{
 let fail=true;let sent;
 await page.route(`**${path}`,r=>r.fulfill({json:{title:'Approved',excerpt:'Approved prose',joint:false,photos:[]}}));
 await page.route(`**${path}/report`,r=>{sent=r.request();return fail?r.fulfill({status:503,json:{error:'retry'}}):r.fulfill({json:{accepted:true}});});
 await page.goto(`/story.html?id=${id}`);await page.getByText('Report this shared Chapter',{exact:true}).click();
 await page.locator('#reason').selectOption('inappropriate');await page.locator('#description').fill('Review this test concern');await page.getByRole('button',{name:'Send report'}).click();
 await expect(page.locator('#report-status')).toContainText('try again');await expect(page.locator('#description')).toHaveValue('Review this test concern');
 fail=false;await page.getByRole('button',{name:'Send report'}).click();await expect(page.locator('#report-status')).toContainText('Report received');expect(sent.headers().authorization).toBeUndefined();expect(sent.postDataJSON()).toEqual({reason:'inappropriate',description:'Review this test concern'});
});
test('incomplete links never fetch a source [case:site.story.withdrawn]',async({page})=>{
 const requests=[];page.on('request',r=>{if(r.url().includes('/v1/blog/'))requests.push(r.url());});
 await page.goto('/story.html?id=not-a-publication');await expect(page.locator('#status')).toHaveText('This Chapter link is incomplete.');expect(requests).toEqual([]);
});
test('formatted excerpt renders as safe DOM in the chosen writing style [case:site.story.renders_safely]',async({page})=>{
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 const content={version:1,style:'journal',blocks:[
  {type:'heading',spans:[{text:'Sunday <img src=x onerror=alert(1)>'}]},
  {type:'paragraph',align:'center',spans:[{text:'Coffee, '},{text:'a bookshop',marks:['bold','italic']},{text:' and ',marks:['highlight']},{text:'a shop',marks:['link'],href:'https://books.example/shop'},{text:' trap',marks:['link'],href:'javascript:alert(1)'}]},
  {type:'paragraph'},
  {type:'bullet',spans:[{text:'Oat latte'}]},
  {type:'numbered',spans:[{text:'Wake'}]},{type:'numbered',spans:[{text:'Read'}]},
  {type:'divider'},
  {type:'iframe',spans:[{text:'Unknown block stays text'}]},
  {type:'callout',spans:[{text:'Slow is fine.'}]}]};
 await page.route(`**${path}`,r=>r.fulfill({json:{title:'Formatted',excerpt:'plain fallback',joint:false,photos:[],content}}));
 await page.goto(`/story.html?id=${id}`);
 const rich=page.locator('#excerpt .rich.style-journal');
 await expect(rich).toBeVisible();
 await expect(rich.locator('h3')).toHaveText('Sunday <img src=x onerror=alert(1)>');
 expect(await page.locator('#excerpt img, #excerpt script, #excerpt iframe').count()).toBe(0);
 await expect(rich.locator('em > strong')).toHaveText('a bookshop');
 await expect(rich.locator('mark')).toHaveText(' and ');
 await expect(rich.locator('p.align-center')).toHaveCount(1);
 const links=rich.locator('a');
 await expect(links).toHaveCount(1);
 await expect(links).toHaveAttribute('href','https://books.example/shop');
 await expect(links).toHaveAttribute('rel','nofollow ugc noopener noreferrer');
 await expect(rich.locator('ul li')).toHaveText(['Oat latte']);
 await expect(rich.locator('ol li')).toHaveText(['Wake','Read']);
 await expect(rich.locator('hr')).toHaveCount(1);
 await expect(rich.locator('[role=note]')).toHaveText('Slow is fine.');
 await expect(rich).toContainText('Unknown block stays text');
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 expect(errors).toEqual([]);
});
test('chapters without formatting keep the plain excerpt [case:site.story.renders_safely]',async({page})=>{
 await page.route(`**${path}`,r=>r.fulfill({json:{title:'Plain',excerpt:'Line one\nLine two',joint:false,photos:[],content:null}}));
 await page.goto(`/story.html?id=${id}`);
 await expect(page.locator('#excerpt')).toHaveText('Line one\nLine two');
 expect(await page.locator('#excerpt .rich').count()).toBe(0);
});

// Copy and Share on a shared story always hand out the canonical story URL
// (origin + /story.html?id=<publication>), never the address the reader
// happened to open (tracking params, fragments).
test('Copy link and Pass this Chapter share the canonical story URL [case:site.story.copy_share]',async({page,context})=>{
 await context.grantPermissions(['clipboard-read','clipboard-write']);
 await page.addInitScript(()=>{window.__shares=[];window.__shareMode='ok';navigator.share=async data=>{window.__shares.push(data);if(window.__shareMode==='abort')throw new DOMException('cancelled','AbortError');if(window.__shareMode==='fail')throw new DOMException('denied','NotAllowedError');};});
 await page.route(`**${path}`,r=>r.fulfill({json:{title:'Approved',excerpt:'Approved prose',joint:false,photos:[]}}));
 await page.goto(`/story.html?id=${id}&utm_source=elsewhere#top`);
 await expect(page.locator('#excerpt')).toHaveText('Approved prose');
 const canonical=`http://127.0.0.1:4190/story.html?id=${id}`;
 await page.getByRole('button',{name:'Copy link'}).click();
 await expect(page.locator('#status')).toHaveText('Link copied.');
 expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe(canonical);
 // Native share sheet: title + canonical URL; nothing else copied.
 await page.evaluate(()=>navigator.clipboard.writeText('untouched'));
 await page.getByRole('button',{name:'Pass this Chapter'}).click();
 await expect.poll(()=>page.evaluate(()=>window.__shares.length)).toBe(1);
 expect(await page.evaluate(()=>window.__shares[0])).toEqual({title:'A shared Chapter',url:canonical});
 expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe('untouched');
 // Dismissing the share sheet is not an error and does not copy.
 await page.evaluate(()=>{window.__shareMode='abort';});
 await page.getByRole('button',{name:'Pass this Chapter'}).click();
 await expect.poll(()=>page.evaluate(()=>window.__shares.length)).toBe(2);
 expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe('untouched');
 // A refused share falls back to copying the link.
 await page.evaluate(()=>{window.__shareMode='fail';});
 await page.getByRole('button',{name:'Pass this Chapter'}).click();
 await expect(page.locator('#status')).toHaveText('Link copied.');
 expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe(canonical);
});
test('Share without a share sheet copies, and a withdrawn story hands out nothing [case:site.story.copy_share] [case:site.story.share_fallback]',async({page,context})=>{
 await context.grantPermissions(['clipboard-read','clipboard-write']);
 await page.addInitScript(()=>{delete Navigator.prototype.share;});
 let available=true;
 await page.route(`**${path}`,r=>available?r.fulfill({json:{title:'Approved',excerpt:'Approved prose',joint:false,photos:[]}}):r.fulfill({status:404,json:{error:'unavailable'}}));
 await page.goto(`/story.html?id=${id}`);
 await expect(page.locator('#excerpt')).toHaveText('Approved prose');
 expect(await page.evaluate(()=>typeof navigator.share)).toBe('undefined');
 await page.getByRole('button',{name:'Pass this Chapter'}).click();
 await expect(page.locator('#status')).toHaveText('Link copied.');
 expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe(`http://127.0.0.1:4190/story.html?id=${id}`);
 // Clipboard refused: the link is shown for manual copying instead.
 await page.evaluate(()=>{navigator.clipboard.writeText=()=>Promise.reject(new Error('denied'));});
 await page.getByRole('button',{name:'Copy link'}).click();
 await expect(page.locator('#status')).toHaveText(`Copy this link: http://127.0.0.1:4190/story.html?id=${id}`);
 // Once withdrawn, neither button hands out the link.
 available=false;
 await page.evaluate(()=>document.dispatchEvent(new Event('visibilitychange')));
 await expect(page.locator('#status')).toContainText('no longer shared');
 await page.evaluate(()=>{navigator.clipboard.writeText=t=>{window.__copied=t;return Promise.resolve();};});
 await page.locator('#copy').dispatchEvent('click');
 await page.locator('#share').dispatchEvent('click');
 await expect(page.locator('#status')).toContainText('no longer shared');
 expect(await page.evaluate(()=>window.__copied)).toBeUndefined();
});
test('the story page loads with a language and one h1 before any id is resolved [case:site.story.idle_state]',async({page})=>{
 const requests=[];page.on('request',r=>{if(r.url().includes('/v1/blog/'))requests.push(r.url());});
 await page.goto('/story.html');
 await expect(page.locator('html')).toHaveAttribute('lang','en');
 await expect(page.locator('h1')).toHaveCount(1);
 await expect(page.locator('h1')).toHaveText(/There’s a story\s*behind every spark\./);
 await expect(page.locator('#status')).toHaveText('This Chapter link is incomplete.');
 await expect(page.locator('#chapter')).toBeHidden();
 await expect(page.locator('#retry')).toBeHidden();
 expect(requests).toEqual([]);
});
