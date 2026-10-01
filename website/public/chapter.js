'use strict';
(() => {
 const $=id=>document.getElementById(id);
 const params=new URLSearchParams(location.search);
 let scenes=[],scene=null,beginning='',surprise='';
 function button(label,selected,action){const b=document.createElement('button');b.textContent=label;b.setAttribute('aria-pressed',String(selected));b.addEventListener('click',()=>{action();[...document.querySelectorAll('button')].find(el=>el.textContent===label)?.focus();});return b;}
 function render(){
  $('title').textContent=scene.title;$('prompt').textContent=scene.prompt;
  $('beginning').textContent=beginning||'Choose a starting point.';
  $('beginnings').replaceChildren(...scene.beginnings.map(v=>button(v,v===beginning,()=>{beginning=v;render();})));
  $('surprises').replaceChildren(...scene.surprises.map(v=>button(v,v===surprise,()=>{surprise=v;render();})));
  $('scenes').replaceChildren(...scenes.map(s=>button(s.title,s.id===scene.id,()=>{scene=s;beginning='';surprise='';render();})));
  $('result').textContent=beginning&&surprise?`${beginning}. Then… ${surprise}.`: 'One small choice can lead somewhere lovely.';
  $('copy').disabled=$('share').disabled=!(beginning&&surprise);
 }
 function remixURL(){const u=new URL('/chapter.html',location.origin);u.searchParams.set('scene',scene.id);u.searchParams.set('beginning',String(scene.beginnings.indexOf(beginning)));u.searchParams.set('surprise',String(scene.surprises.indexOf(surprise)));return u.toString();}
 async function copy(){try{await navigator.clipboard.writeText(remixURL());$('status').textContent='Remix link copied. Share it wherever you choose.';}catch{$('status').textContent=`Copy this remix link: ${remixURL()}`;}}
 $('copy').addEventListener('click',copy);
 $('share').addEventListener('click',async()=>{if(!navigator.share){await copy();return;}try{await navigator.share({title:'What would you add? · First Chapter',text:'Make a tiny adventure your own.',url:remixURL()});}catch(e){if(e.name!=='AbortError')await copy();}});
 $('reset').addEventListener('click',()=>{beginning='';surprise='';render();$('status').textContent='A fresh page. Choose what feels like you.';});
 async function json(path){const response=await fetch(path,{credentials:'omit',cache:'no-store'});if(!response.ok)throw Error('This chapter is unavailable or its sharing permission has been withdrawn.');return response.json();}
 async function open(){try{
  const catalogue=await json('/v1/chapters/catalogue');scenes=catalogue.scenes;
  if(params.has('share')){const card=await json('/v1/chapters/public/'+encodeURIComponent(params.get('share')));scene=scenes.find(s=>s.id===card.scene.id);if(!scene)throw Error('This scene is unavailable.');beginning=card.beginning;surprise=card.surprise;$('kind').textContent=card.joint_story?'AN ANONYMOUS IDEA, APPROVED BY BOTH AUTHORS':'A BEGINNING SOMEONE PASSED TO YOU';}
  else{scene=scenes.find(s=>s.id===params.get('scene'))||scenes[0];const b=params.get('beginning'),s=params.get('surprise');beginning=b!==null?scene.beginnings[Number(b)]||'':'';surprise=s!==null?scene.surprises[Number(s)]||'':'';}
  render();$('studio').hidden=false;$('status').textContent='Try a different turn. There are no wrong answers.';
 }catch(e){$('status').textContent=e.message;}}
 open();
})();
