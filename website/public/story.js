'use strict';
const $ = id => document.getElementById(id);
const id = new URL(location.href).searchParams.get('id') || '';
const validID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const endpoint = `/v1/blog/public/${encodeURIComponent(id)}`;
const shareURL = new URL(`/story.html?id=${encodeURIComponent(id)}`, location.origin).href;
let loading = false, available = false;
async function load() {
  if (loading) return;
  loading = true;
  try {
    if (!validID.test(id)) throw new Error('This Chapter link is incomplete.');
    const response = await fetch(endpoint, {cache:'no-store', credentials:'omit', referrerPolicy:'no-referrer'});
    if (!response.ok) throw new Error(response.status === 404 ? 'This Chapter is no longer shared, or the link is unavailable.' : 'We could not open this Chapter. Please try again.');
    const data = await response.json();
    $('title').textContent = data.title;
    $('excerpt').textContent = data.excerpt;
    $('kind').textContent = data.joint ? 'TWO VOICES. ONE SHARED CHAPTER.' : 'A SHARED CHAPTER';
    $('photos').replaceChildren();
    for (const photo of (data.photos || []).slice(0,6)) {
      if (!validID.test(photo.id)) continue;
      const figure = document.createElement('figure'), img = document.createElement('img'), caption = document.createElement('figcaption');
      img.src = `${endpoint}/photos/${photo.id}`; img.alt = photo.alt_text || 'Shared Chapter photo'; img.loading = 'lazy'; img.referrerPolicy = 'no-referrer'; caption.textContent = photo.alt_text || '';
      figure.append(img,caption); $('photos').append(figure);
    }
    $('chapter').hidden = false; $('status').textContent = ''; $('retry').hidden = true; available = true;
  } catch (error) {
    available = false; $('chapter').hidden = true; $('title').textContent = ''; $('excerpt').textContent = ''; $('photos').replaceChildren();
    $('status').textContent = error.message; $('retry').hidden = !validID.test(id);
  } finally { loading = false; }
}
async function copy() {
  if (!available) return;
  try { await navigator.clipboard.writeText(shareURL); $('status').textContent = 'Link copied.'; }
  catch { $('status').textContent = `Copy this link: ${shareURL}`; }
}
$('copy').addEventListener('click',copy);
$('share').addEventListener('click',async () => {
  if (!available) return;
  if (!navigator.share) { await copy(); return; }
  try { await navigator.share({title:'A shared Chapter',url:shareURL}); }
  catch(error) { if (error.name !== 'AbortError') await copy(); }
});
$('retry').addEventListener('click',load);
$('report').addEventListener('submit',async event => {
  event.preventDefault(); if (!available || $('report-submit').disabled) return;
  $('report-submit').disabled = true;
  try {
    const response = await fetch(`${endpoint}/report`,{method:'POST',credentials:'omit',referrerPolicy:'no-referrer',headers:{'Content-Type':'application/json'},body:JSON.stringify({reason:$('reason').value,description:$('description').value.trim()})});
    if (!response.ok) throw new Error('We could not send your report. Your text is still here; please try again.');
    $('report-status').textContent = 'Report received. Our trust team will review it.'; $('description').value = '';
  } catch(error) { $('report-status').textContent = error.message; }
  finally { $('report-submit').disabled = false; }
});
document.addEventListener('visibilitychange', () => { if (!document.hidden) load(); });
setInterval(() => { if (!document.hidden) load(); },60000);
load();
