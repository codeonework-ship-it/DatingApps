import {test, expect} from '@playwright/test';

// Non-destructive checks against the isolated local QA member. Route/render
// coverage is distinct from business mutations and provider acceptance.
const routes = [
 ['preferences','Edit Preferences'], ['edit-profile','Edit Profile'],
 ['photos','Save Photos'], ['notifications','Read all'],
 ['daily-prompt','Daily Prompt Streak'], ['progression','Level & XP'],
 ['trust','Trust Badges'], ['trust-filters','Trust Filters'],
 ['icebreakers','Icebreakers'], ['challenges','Local Circle Challenges'],
 ['coffee','Group Coffee Polls'], ['groups','Community Groups'],
 ['rooms','Conversation Rooms'], ['nudges','Match nudges'],
 ['friends','Friends & Connections'], ['calls','Call History'],
 ['membership','Membership'], ['verification','Government Verification'], ['safety','Privacy & Safety'],
 ['account','Account & Data'], ['blocked','Blocked Users'],
 ['emergency-contacts','Emergency Contacts'], ['appeals','Moderation Appeals'],
 ['notification-settings','Notifications'], ['help','Help & Support'],
 ['settings','Settings'],
];
for(const width of [390,1440]) {
 test(`member feature routes render at ${width}px`,async({page})=>{
  test.setTimeout(180000);
  await page.setViewportSize({width,height:900});
  const errors=[]; page.on('pageerror',e=>errors.push(e.message));
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
  await expect(page).toHaveURL(/#\/discover$/,{timeout:30000});
  await page.goto('/app/#/features');
  await expect(page.getByText('Make this space yours.',{exact:true})).toBeVisible({timeout:30000});
  for(const [route,label] of routes) {
   await test.step(route,async()=>{
    await page.goto(`/app/#/${route}`);
    const title = new RegExp('^' + label + '(?: ' + label + ')?$','i');
    await expect(page.getByText(title).or(page.getByRole('heading',{name:title})).last()).toBeVisible({timeout:15000});
    await expect(page.getByText('This page wandered off.',{exact:true})).toHaveCount(0);
    expect(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await expect(page.getByText('Loading your saved profile',{exact:true})).toHaveCount(0,{timeout:10000});
    if(route === 'icebreakers') {
     await expect(page.getByRole('button',{name:'qa.voice.recording_button',exact:true})).toBeVisible();
    }
    if(route === 'membership') {
     await expect(page.getByText('Subscribe with card',{exact:true}).first()).toBeVisible();
    }
    if(route === 'verification') {
     await expect(page.getByText(/^(Start secure verification|View review status|View verified status)$/).first()).toBeVisible();
    }
    if(route === 'settings') {
     await expect(page.getByRole('button',{name:/qa\.settings\.theme_preset\./})).toHaveCount(0);
    }
    await page.screenshot({path:`../qa/results/2026-09-27-website/route-${route}-${width}.png`});
   });
  }
  expect(errors).toEqual([]);
 });
}
