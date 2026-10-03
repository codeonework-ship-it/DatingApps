import {test, expect} from '@playwright/test';
import {qaMember} from './support/member.js';
import {qaId, qaIdPrefix} from './support/qa.js';

// Never the shared QA account: signing in invalidates its other sessions.
const member = qaMember();

// Non-destructive checks against a fresh local QA member (see support/member.js).
// Groups, rooms and friends were redesigned (2026-10-01): their labels are the
// new section headings. Route/render
// coverage is distinct from business mutations and provider acceptance.
const routes = [
 ['preferences','Edit Preferences'], ['edit-profile','Edit Profile'],
 ['photos','Save Photos'], ['notifications','(?:Read all|You are all caught up)'],
 ['daily-prompt','Daily Prompt Streak'], ['progression','Level & XP'],
 ['trust','Trust Badges'], ['trust-filters','Trust Filters'],
 ['icebreakers','Icebreakers'], ['challenges','Local Circle Challenges'],
 ['coffee','Group Coffee Polls'], ['groups','GROUPS Find your people.*'],
 ['rooms','LIVE CHAT Rooms.*'], ['nudges','Match nudges'],
 ['friends','FRIENDS Your people.*'], ['calls','Call History'],
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
  // Flutter web attaches its text-editing host a moment after the click;
  // typing before the field is focused drops the first characters.
  const typeInto = async(field,value)=>{
    await field.click();
    await expect(field).toBeFocused();
    await field.fill('');
    await field.pressSequentially(value,{delay:15});
    await expect(field).toHaveValue(value);
  };
  const username = page.getByRole('textbox',{name:'username',exact:true});
  await typeInto(username,member.username);
  await username.press('Tab');
  const password = page.getByRole('textbox',{name:'Password',exact:true});
  await typeInto(password,member.password);
  await password.press('Tab');
  await expect(username).toHaveValue(member.username);
  await qaId(page,'qa.signin.login_button').click();
  await expect(page).toHaveURL(/#\/discover$/,{timeout:30000});
  await page.goto('/app/#/features');
  await expect(page.getByText('Make this space yours.',{exact:true})).toBeVisible({timeout:30000});
  for(const [route,label] of routes) {
   await test.step(route,async()=>{
    await page.goto(`/app/#/${route}`);
    const title = new RegExp('^' + label + '(?: ' + label + ')?$','i');
    await expect(page.getByText(title).or(page.getByRole('heading',{name:title})).last()).toBeVisible({timeout:15000});
    await expect(page.getByText('This page wandered off.',{exact:true})).toHaveCount(0);
    // The workspace's own not-found state (the line above is the server's 404 copy).
    await expect(page.getByText('This page could not be found.',{exact:true})).toHaveCount(0);
    expect(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await expect(page.getByText('Loading your saved profile',{exact:true})).toHaveCount(0,{timeout:10000});
    if(route === 'icebreakers') {
     // The recorder appears after choosing a match; a member without matches sees a calm note.
     // The recorder carries only a widget key (no web qa id), so it is found by its label.
     await expect(page.getByRole('button',{name:'Record your hello',exact:true})
      .or(page.getByRole('button',{name:'Who would you like to say hello to?'}))
      .or(page.getByText('When you have a match, you can share a voice introduction here. No rush.',{exact:true})).first()).toBeVisible();
    }
    if(route === 'membership') {
     await expect(page.getByRole('button',{name:'Subscribe with card',exact:true}).first()).toBeVisible();
    }
    if(route === 'verification') {
     await expect(qaId(page,'qa.verification.landing.start_button').or(qaId(page,'qa.verification.landing.status_button')).first()).toBeVisible();
    }
    if(route === 'settings') {
     await expect(qaIdPrefix(page,'qa.settings.theme_preset')).toHaveCount(0);
    }
    await page.screenshot({path:`../qa/results/2026-09-27-website/route-${route}-${width}.png`});
   });
  }
  expect(errors).toEqual([]);
 });
}
