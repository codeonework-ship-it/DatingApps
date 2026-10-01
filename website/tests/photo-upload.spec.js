import {test, expect} from '@playwright/test';
import {resolve} from 'node:path';

test('browser upload, reload and onboarding completion preserve the auth gate',async({page,request})=>{
 test.setTimeout(90000);
 const username=`web_photo_${Date.now()}`;
 const password='TestPhotos2026!';
 const signup=await request.post('/v1/auth/signup',{data:{username,password}});
 expect(signup.ok()).toBe(true);
 const session=await signup.json();
 const headers={Authorization:`Bearer ${session.access_token}`};
 const userId=session.user_id;
 // Only synthetic test data is created. An incomplete test member is never
 // published to discovery; agreement state is a fixture, not a real signature.
 const bootstrap=await request.post('/v1/auth/signup/bootstrap',{headers,data:{user_id:userId,username,name:'Browser Photo QA',date_of_birth:'1995-06-15',gender:'female'}});
 expect(bootstrap.ok()).toBe(true);
 expect((await request.patch(`/v1/users/${userId}/agreements/terms`,{headers,data:{accepted:true,terms_version:'v1'}})).ok()).toBe(true);
 let photos=[];
 try {
 await page.goto('/app/#/signin');
 const userInput=page.getByRole('textbox',{name:'username',exact:true});
 await expect(userInput).toBeVisible({timeout:30000});
 // Session restoration can rebuild the sign-in form once. Wait for that
 // deterministic initialization before entering this newly created account.
 await page.waitForTimeout(500);
 await userInput.fill(username);
 await expect(userInput).toHaveValue(username);
 const passwordInput=page.getByRole('textbox',{name:'Password',exact:true});
 await passwordInput.fill(password);
 await expect(passwordInput).toHaveValue(password);
 await page.getByRole('button',{name:'qa.signin.login_button',exact:true}).click();
 await expect(page.getByRole('button',{name:'qa.setup.photos.gallery_button',exact:true})).toBeVisible({timeout:30000});
 const uploadResponse=page.waitForResponse(r=>r.url().includes(`/profile/${userId}/photos`)&&r.request().method()==='POST');
 const picker=page.waitForEvent('filechooser');
 await page.getByRole('button',{name:'qa.setup.photos.gallery_button',exact:true}).click();
 await (await picker).setFiles(resolve('public/assets/cafe.png'));
 const uploaded=await uploadResponse;expect(uploaded.ok()).toBe(true);
 const body=await uploaded.json(); photos=body.draft.photos;
 expect(photos).toHaveLength(1);
 expect(photos[0].photo_url).not.toContain('blob:');
  const draftResponse = page.waitForResponse(r=>r.url().includes(`/profile/${userId}/draft`)&&r.request().method()==='GET');
  await page.reload();
  const restored = await (await draftResponse).json();
  expect(restored.draft.photos[0].id).toBe(photos[0].id);
  await expect(page.getByRole('button',{name:'qa.setup.photos.gallery_button',exact:true})).toBeVisible({timeout:30000});
  await page.screenshot({path:'../qa/results/2026-09-27-website/browser-photo-upload.png'});
  const secondResponse=page.waitForResponse(r=>r.url().includes(`/profile/${userId}/photos`)&&r.request().method()==='POST');
  const secondPicker=page.waitForEvent('filechooser');
  await page.getByRole('button',{name:'qa.setup.photos.gallery_button',exact:true}).click();
  await (await secondPicker).setFiles(resolve('public/assets/cafe.png'));
  const second=await secondResponse;expect(second.ok()).toBe(true);
  photos=(await second.json()).draft.photos;expect(photos).toHaveLength(2);
  // The resumable root gate advances to About when the second photo persists.
  const bio=page.getByRole('textbox',{name:/Tell people about you/});
  await bio.click();await bio.pressSequentially('An isolated browser QA profile for testing onboarding.',{delay:5});await bio.press('Tab');
  await page.getByRole('button',{name:'qa.setup.about.continue_button',exact:true}).click();
  await page.getByRole('button',{name:'qa.setup.preview.complete_button',exact:true}).click();
  await expect(page.getByText('Your pace. Your choice.',{exact:true})).toBeVisible({timeout:30000});
  await expect(page).toHaveURL(/#\/discover$/);
  await page.getByText('Sign out',{exact:true}).click();
  await expect(page.getByRole('textbox',{name:'username',exact:true})).toBeVisible();
 } finally {
  for(const photo of photos) expect((await request.delete(`/v1/profile/${userId}/photos/${photo.id}`,{headers})).ok()).toBe(true);
  expect((await request.post(`/v1/account/${userId}/deactivate`,{headers,data:{reason:'Isolated browser QA fixture'}})).ok()).toBe(true);
 }
});
