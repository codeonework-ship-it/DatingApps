import {test, expect} from '@playwright/test';
import {qaMember} from './support/member.js';
import {qaField, qaId} from './support/qa.js';

// Never the shared QA account: signing in invalidates its other sessions.
const member = qaMember();

async function enterText(field, text, page) {
  await field.click();
  await field.press('ControlOrMeta+A');
  await field.press('Backspace');
  // Flutter replaces its semantic input with the live editor on focus.
  await page.waitForTimeout(150);
  if (text) await field.pressSequentially(text, {delay: 15});
}

// UI acceptance uses a real QA login and isolated conversation API fixtures.
// Every fixture conversation mutation is intercepted; no member is messaged.
for (const width of [390, 1440]) {
  test(`conversation redesign at ${width}px`, async ({page}) => {
    test.setTimeout(90000);
    await page.setViewportSize({width, height: 900});
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    let self = 'self';
    let refused = false;
    const messages = [
      {id:'chat-ui-4',sender_id:'maya',text:'Then it’s a plan. I know a little place with the best cinnamon rolls ☕',created_at:new Date(Date.now()-60000).toISOString(),read_at:new Date().toISOString()},
      {id:'chat-ui-3',sender_id:'self',text:'A slow Sunday, good coffee, and absolutely no alarm. You?',created_at:new Date(Date.now()-120000).toISOString(),read_at:new Date().toISOString()},
      {id:'chat-ui-2',sender_id:'maya',text:'Important question: what does your perfect weekend look like?',created_at:new Date(Date.now()-180000).toISOString(),read_at:new Date().toISOString()},
      {id:'chat-ui-1',sender_id:'maya',text:'Hey! Your answer about spontaneous road trips made me smile.',created_at:new Date(Date.now()-86400000).toISOString(),read_at:new Date().toISOString()},
    ];
    const json = (route, data, status=200) => route.fulfill({status,contentType:'application/json',body:JSON.stringify(data)});
    await page.route('**/v1/config/flags', route => json(route, {flags:[
      ...['gifts_enabled','billing_enabled','copilot_enabled'].map(key=>({key,value_bool:true})),
      ...['date_plans_enabled','graduation_enabled'].map(key=>({key,value_bool:false})),
    ]}));
    await page.route('**/v1/matches/**', async route => {
      const path = new URL(route.request().url()).pathname;
      if (path.endsWith('/trust')) return json(route,{trust:{human_verified:true,partner_verified:true,viewer_verified:true}});
      if (path.endsWith('/unlock-state')) return json(route,{chat_unlocked:true,unlock_state:'conversation_unlocked'});
      if (route.request().method() !== 'GET') return json(route,{success:true});
      return json(route,{matches:[
        {id:'chat-ui-maya',user_id:'maya',userName:'Maya',userPhoto:'',lastMessage:messages[0].text,lastMessageTime:messages[0].created_at,unreadCount:2},
        {id:'chat-ui-arjun',user_id:'arjun',userName:'Arjun',userPhoto:'',lastMessage:'That book has been on my list for ages.',lastMessageTime:new Date(Date.now()-3600000).toISOString(),unreadCount:0},
      ]});
    });
    await page.route('**/v1/chat/chat-ui-*/**', async route => {
      const path = new URL(route.request().url()).pathname;
      if (route.request().method() === 'GET' && path.endsWith('/messages')) {
        return json(route,{messages:messages.map(m=>({...m,sender_id:m.sender_id==='self'?self:m.sender_id}))});
      }
      if (route.request().method()==='POST' && path.endsWith('/messages')) {
        if (refused) return json(route,{error:'Try again',error_code:'DAILY_MESSAGE_LIMIT_REACHED',plan_name:'Free',limit:20,used:20,resets_at:new Date(Date.now()+3600000).toISOString()},429);
        messages.unshift({id:`chat-ui-${messages.length+1}`,sender_id:'self',text:route.request().postDataJSON().text,created_at:new Date().toISOString()});
      }
      return json(route,{success:true});
    });
    await page.goto('/app/#/signin');
    const username = page.getByRole('textbox',{name:'username',exact:true});
    await expect(username).toBeVisible({timeout:30000});
    await username.click();
    await page.waitForTimeout(200); // Wait for Flutter to attach its live editor.
    await username.pressSequentially(member.username, {delay: 15});
    await username.press('Tab');
    const password = page.getByRole('textbox',{name:'Password',exact:true});
    await password.click();
    await page.waitForTimeout(200);
    await password.pressSequentially(member.password, {delay:15});
    await password.press('Tab');
    await expect(username).toHaveValue(member.username);
    const loginResponse = page.waitForResponse(r=>r.url().endsWith('/v1/auth/login')&&r.request().method()==='POST');
    await qaId(page,'qa.signin.login_button').click();
    self = (await (await loginResponse).json()).user_id;
    await expect(page).toHaveURL(/#\/discover$/,{timeout:30000});
    await page.goto('/app/#/matches');
    // The Matches tab opens on its Discover sub-view; conversations are one chip away.
    await page.getByRole('checkbox',{name:'Conversations',exact:true}).click({timeout:30000});
    await expect(page.getByRole('checkbox',{name:'Conversations',exact:true})).toBeChecked();
    const search = page.getByRole('textbox',{name:/Search conversations/});
    await enterText(search, 'Maya', page);
    await expect(qaId(page,'qa.matches.match_row.chat-ui-maya')).toBeVisible();
    await expect(qaId(page,'qa.matches.match_row.chat-ui-arjun')).toHaveCount(0);
    await enterText(search, '', page);
    await page.screenshot({path:`../qa/results/chat-redesign/inbox-${width}.png`});
    await qaId(page,'qa.matches.match_row.chat-ui-maya').click();
    const composer = qaField(page,'qa.chat.composer');
    await expect(composer).toBeVisible();
    await expect(page.getByText('Active now',{exact:true})).toHaveCount(0);
    await expect(page.getByText(messages[0].text,{exact:false})).toBeVisible();
    // Allow Flutter's route transition to finish before visual evidence.
    await page.waitForTimeout(500);
    await page.screenshot({path:`../qa/results/chat-redesign/conversation-${width}.png`});
    await enterText(composer, 'Coffee and a cinnamon roll? I’m in.', page);
    await expect(page.getByText('Maya is typing…',{exact:true})).toHaveCount(0);
    const sentRequest = page.waitForRequest(r => r.url().endsWith('/chat/chat-ui-maya/messages') && r.method() === 'POST');
    await composer.press('Enter');
    expect((await sentRequest).postDataJSON().text).toBe('Coffee and a cinnamon roll? I’m in.');
    await expect(qaId(page,'qa.chat.message.chat-ui-5').and(page.getByRole('button'))).toBeVisible();
    // Flutter's inactive semantic textarea can retain its old DOM value;
    // the send control reflects the live controller's empty draft.
    await expect(page.getByRole('button',{name:'Send message',exact:true})).toBeDisabled();
    refused=true;
    await enterText(composer, 'Please keep this draft', page);
    await composer.press('Enter');
    const quota = qaId(page,'qa.chat.daily_limit_banner');
    await expect(quota).toBeVisible();
    await expect(composer).toHaveValue('Please keep this draft');
    refused=false;
    await page.getByRole('button',{name:'Send message',exact:true}).click();
    await expect(qaId(page,'qa.chat.message.chat-ui-6').and(page.getByRole('button',{name:/Please keep this draft/}))).toBeVisible();
    await expect(quota).toHaveCount(0);
    await page.getByRole('button',{name:'Send a gift',exact:true}).click();
    await expect(page.getByText('A little something for them',{exact:true})).toBeVisible();
    await page.waitForTimeout(500);
    await page.screenshot({path:`../qa/results/chat-redesign/gifts-${width}.png`});
    expect(errors).toEqual([]);
  });
}
