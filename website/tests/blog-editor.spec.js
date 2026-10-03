import {test, expect} from '@playwright/test';
import {createMember, qaMember, signIn} from './support/member.js';
import {dismissRewards} from './support/app.js';
import {qaId} from './support/qa.js';

const member = qaMember();

// The story toolbar must not take focus from the story on web: pressing Bold
// and typing straight away should land formatted text in the story.
test('story toolbar keeps the cursor in the story',async({page})=>{
 test.setTimeout(120000);
 await page.setViewportSize({width:390,height:900});
 const errors=[]; page.on('pageerror',e=>errors.push(e.message));
 const typeInto = async(field,value)=>{
  await field.click();
  await expect(field).toBeFocused();
  await field.fill('');
  await field.pressSequentially(value,{delay:15});
  await expect(field).toHaveValue(value);
 };
 await page.goto('/app/#/signin');
 const username = page.getByRole('textbox',{name:'username',exact:true});
 await typeInto(username,member.username);
 await username.press('Tab');
 const password = page.getByRole('textbox',{name:'Password',exact:true});
 await typeInto(password,member.password);
 await password.press('Tab');
 await qaId(page,'qa.signin.login_button').click();
 await expect(page).toHaveURL(/#\/discover$/,{timeout:30000});

 await page.goto('/app/#/blog');
 await page.getByText('Write a chapter',{exact:true}).first().click();
 const story = page.getByRole('textbox',{name:/^Your story/});
 await typeInto(story,'Plain ');
 await page.getByRole('button',{name:'Bold',exact:true}).click();
 await expect(story).toBeFocused();
 await page.keyboard.type('Sunday mornings',{delay:15});
 await expect(story).toHaveValue('Plain Sunday mornings');
 await expect(story).toHaveAccessibleName(/^Your story 3 words ·/);
 await page.screenshot({path:'../qa/results/2026-09-27-website/blog-editor-bold.png'});
 expect(errors).toEqual([]);
});

// Several formatting toggles in a row, then typing, must land formatted text
// in the story (WEB-14: the second toolbar press used to keep the browser's
// focus on the button, so the typed words were lost). A writing style chip
// changes the story's style. Saved as "Only me": the saved document is the
// evidence, not just the DOM value.
for (const width of [390, 1440]) {
 test(`bold, italic and underline then typing lands formatted; writing style chip at ${width}px`, async ({page}) => {
  test.setTimeout(120000);
  await page.setViewportSize({width, height: 900});
  const errors = []; page.on('pageerror', e => errors.push(e.message));
  const typeInto = async (field, value) => {
   await field.click();
   await expect(field).toBeFocused();
   await field.fill('');
   await field.pressSequentially(value, {delay: 15});
   await expect(field).toHaveValue(value);
  };
  await signIn(page, createMember('qaedit'));
  await page.goto('/app/#/blog');
  await page.getByText('Write a chapter', {exact: true}).first().click();
  const story = page.getByRole('textbox', {name: /^Your story/});
  await typeInto(story, 'Plain ');
  for (const mark of ['Bold', 'Italic', 'Underline']) {
   await page.getByRole('button', {name: mark, exact: true}).click();
   await expect(page.getByRole('switch', {name: new RegExp(`^${mark}`)})).toBeChecked();
   await expect(story, `story keeps focus after ${mark}`).toBeFocused();
  }
  await page.keyboard.type('Sunday mornings', {delay: 15});
  await expect(story).toHaveValue('Plain Sunday mornings');
  await expect(story).toHaveAccessibleName(/^Your story 3 words ·/);

  // Writing style: Modern by default, Journal once chosen.
  const chip = name => page.getByRole('checkbox', {name: new RegExp(` ${name}$`)});
  await expect(chip('Modern')).toBeChecked();
  await chip('Journal').click();
  await expect(chip('Journal')).toBeChecked();
  await expect(chip('Modern')).not.toBeChecked();
  await expect(story).toHaveAccessibleName(/Warm italic, like a diary entry/);
  await dismissRewards(page, 1500);
  await page.mouse.move(1, 1); // no tooltip over the story
  await page.screenshot({path: `../qa/results/playwright/profile-2026-10-02/blog-editor-formatted-${width}.png`});

  const put = page.waitForRequest(r => r.method() === 'PUT' && /\/v1\/blog\/posts\/[^/]+$/.test(r.url()));
  const save = page.getByRole('button', {name: 'Save only for me', exact: true});
  for (let i = 0; i < 15 && await save.count() === 0; i++) { await page.mouse.move(width / 2, 600); await page.mouse.wheel(0, 400); await page.waitForTimeout(150); }
  await save.click();
  const request = await put;
  const body = request.postDataJSON();
  expect(body.audience).toBe('private');
  expect(body.content.style).toBe('journal');
  const spans = body.content.blocks.flatMap(b => b.spans ?? []);
  const formatted = spans.find(s => s.text.includes('Sunday mornings'));
  expect(formatted, JSON.stringify(spans)).toBeTruthy();
  expect([...formatted.marks].sort()).toEqual(['bold', 'italic', 'underline']);
  expect(spans.find(s => s.text.startsWith('Plain')).marks ?? []).toEqual([]);
  expect((await request.response()).status()).toBe(200);
  expect(errors).toEqual([]);
 });
}
