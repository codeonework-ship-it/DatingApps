import {test, expect} from '@playwright/test';
import {qaMember} from './support/member.js';

// Never the shared QA account: signing in invalidates its other sessions.
const member = qaMember();

// A real local QA login with isolated feature fixtures. No real match is changed.
for (const width of [390, 1440]) for (const part of ['rhythm', 'chemistry']) {
 test(`intentional dating ${part} at ${width}px`, async ({page}) => {
  // WEB-11 (fixed): the chat's connection card opens First Chapter Studio and
  // keeps a secondary "A little chemistry?" action that opens ChemistrySheet.
  test.setTimeout(120000);
  await page.setViewportSize({width,height:900});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const json=(route,data,status=200)=>route.fulfill({status,contentType:'application/json',body:JSON.stringify(data)});
  const match='67000000-0000-4000-8000-000000000001';
  let preferences={version:0,intent:'',pace:'',activities:[],availability:[],share_availability:false,allow_friend_intros:false};
  let moment=null;
  let saved;
  await page.route('**/v1/config/flags',r=>json(r,{flags:['intentional_dating_enabled','date_plans_enabled'].map(key=>({key,value_bool:true})).concat([{key:'graduation_enabled',value_bool:false}])}));
  await page.route('**/v1/account/*/dating-preferences',r=>{
   if(r.request().method()==='PUT'){saved=r.request().postDataJSON();preferences={...saved,version:saved.version+1};}
   return json(r,{preferences});
  });
  await page.route('**/v1/matches/**',async r=>{
   const path=new URL(r.request().url()).pathname;
   if(path.endsWith('/connection'))return json(r,{reasons:['You both enjoy coffee'],overlap:[],moment,plan_revision:'one'});
   if(path.endsWith('/moments')){moment={id:r.request().postDataJSON().id,prompt:'sunday',status:'open',options:{food:'Brunch and a good chat',bookstore:'A bookstore and coffee',outdoors:'Fresh air and a long walk'}};return json(r,{moment});}
   if(path.endsWith('/answer')){moment={...moment,status:'waiting',my_answer:r.request().postDataJSON().answer};return json(r,{moment});}
   if(path.endsWith('/plans'))return json(r,{plan:null,history:[],share_groups:[],can_propose:true});
   if(path.endsWith('/trust'))return json(r,{trust:{human_verified:true,partner_verified:true,viewer_verified:true}});
   if(path.endsWith('/unlock-state'))return json(r,{chat_unlocked:true,unlock_state:'conversation_unlocked'});
   if(r.request().method()!=='GET')return json(r,{success:true});
   return json(r,{matches:[{id:match,user_id:'maya',userName:'Maya',userPhoto:'',lastMessage:'Coffee sounds good.',lastMessageTime:new Date().toISOString(),unreadCount:0}]});
  });
  await page.route(`**/v1/chat/${match}/**`,r=>json(r,r.request().method()==='GET'?{messages:[]}:{success:true}));
  await page.goto('/app/#/signin');
  const user=page.getByRole('textbox',{name:'username',exact:true});await expect(user).toBeVisible({timeout:30000});
  await user.click();await page.waitForTimeout(200);await user.pressSequentially(member.username,{delay:10});await user.press('Tab');
  const pass=page.getByRole('textbox',{name:'Password',exact:true});await pass.click();await page.waitForTimeout(200);await pass.pressSequentially(member.password,{delay:10});await pass.press('Tab');
  await page.getByRole('button',{name:'qa.signin.login_button',exact:true}).click();await expect(page).toHaveURL(/#\/discover$/,{timeout:30000});
  if (part === 'rhythm') {
  await page.goto('/app/#/settings');
  await page.getByRole('button',{name:/^Your dating rhythm /}).click();
  await expect(page.getByText('Make room for the way you date.',{exact:true})).toBeVisible();
  await page.getByRole('checkbox',{name:'A relationship',exact:true}).click();
  await page.screenshot({path:`../qa/results/intentional-dating/rhythm-${width}.png`});
  const save=page.getByRole('button',{name:'Save my rhythm',exact:true});
  // Flutter creates semantics lazily as content enters its viewport.
  for(let i=0;i<15&&await save.count()===0;i++){await page.mouse.move(width/2,700);await page.mouse.wheel(0,480);await page.waitForTimeout(150);}
  await save.click();await expect(page.getByText('Your dating rhythm is saved.',{exact:true}).last()).toBeVisible();
  expect(saved.intent).toBe('relationship');expect(saved.share_availability).toBe(false);expect(saved.allow_friend_intros).toBe(false);expect(saved.availability).toEqual([]);
  await page.getByRole('button',{name:'Back',exact:true}).click();
  }
  if (part === 'chemistry') {
  await page.goto('/app/#/matches');
  // The Matches tab opens on its Discover sub-view; conversations are one chip away.
  await page.getByRole('checkbox',{name:'Conversations',exact:true}).click({timeout:30000});
  await page.getByRole('button',{name:new RegExp(`^qa.matches.match_row.${match}`)}).click();
  await expect(page.getByRole('textbox',{name:/Write a message|qa.chat.composer/})).toBeVisible();
  await page.getByRole('button',{name:/^A little chemistry\?/}).click();
  await expect(page.getByRole('checkbox',{name:'You both enjoy coffee',exact:true})).toBeVisible();
  await page.getByRole('button',{name:'Build a Sunday',exact:true}).click();
  await page.getByRole('button',{name:'Brunch and a good chat',exact:true}).click();
  await expect(page.getByText(/Your answer is saved privately\./)).toBeVisible();
  await expect(page.getByText('A bookstore and coffee',{exact:false})).toHaveCount(0);
  await page.screenshot({path:`../qa/results/intentional-dating/private-answer-${width}.png`});
  moment={...moment,status:'revealed',partner_answer:'bookstore'};
  await expect(page.getByText('Both answers, together',{exact:false})).toBeVisible({timeout:25000});
  await expect(page.getByText('A bookstore and coffee',{exact:false})).toBeVisible();
  await page.screenshot({path:`../qa/results/intentional-dating/revealed-${width}.png`});
  }
  expect(errors).toEqual([]);
 });
}
