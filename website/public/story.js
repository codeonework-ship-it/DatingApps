'use strict';
const $ = id => document.getElementById(id);
const id = new URL(location.href).searchParams.get('id') || '';
const validID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const endpoint = `/v1/blog/public/${encodeURIComponent(id)}`;
const shareURL = new URL(`/story.html?id=${encodeURIComponent(id)}`, location.origin).href;
let loading = false, available = false;
// Rich chapters: a closed block model (never HTML). Built with DOM nodes and
// textContent only, so member text can never become markup. Unknown types and
// marks degrade to plain text; links must be https and open with nofollow.
const STYLES = new Set(['classic','modern','journal','typewriter','poetic']);
const BLOCKS = {paragraph:'p',heading:'h3',subheading:'h4',quote:'blockquote',callout:'div',divider:'hr',bullet:'li',numbered:'li'};
const MARKS = [['bold','strong'],['italic','em'],['underline','u'],['strikethrough','s'],['highlight','mark']];
function safeHref(raw) {
  try { const u = new URL(String(raw)); return u.protocol === 'https:' && u.hostname && !u.username && !u.password ? u.href : null; }
  catch { return null; }
}
function renderRich(content) {
  if (!content || content.version !== 1 || !Array.isArray(content.blocks) || !content.blocks.length) return null;
  const root = document.createElement('div');
  root.className = `rich style-${STYLES.has(content.style) ? content.style : 'modern'}`;
  let list = null, listType = '';
  for (const block of content.blocks.slice(0,400)) {
    const type = Object.hasOwn(BLOCKS, block && block.type) ? block.type : 'paragraph';
    const el = document.createElement(BLOCKS[type]);
    if (type === 'bullet' || type === 'numbered') {
      if (listType !== type) { list = document.createElement(type === 'bullet' ? 'ul' : 'ol'); root.append(list); listType = type; }
      list.append(el);
    } else { list = null; listType = ''; root.append(el); }
    if (type === 'callout') { el.className = 'callout'; el.setAttribute('role','note'); }
    if (type === 'divider') { el.setAttribute('aria-label','Section break'); continue; }
    if (block.align === 'center' || block.align === 'end') el.classList.add(`align-${block.align}`);
    const spans = Array.isArray(block.spans) ? block.spans.slice(0,200) : [];
    if (!spans.length) el.classList.add('blank');
    for (const span of spans) {
      if (!span || typeof span.text !== 'string') continue;
      const marks = Array.isArray(span.marks) ? span.marks : [];
      let node = document.createTextNode(span.text);
      for (const [mark, tag] of MARKS) {
        if (!marks.includes(mark)) continue;
        const wrap = document.createElement(tag); wrap.append(node); node = wrap;
      }
      const href = marks.includes('link') ? safeHref(span.href) : null;
      if (href) {
        const a = document.createElement('a');
        a.href = href; a.rel = 'nofollow ugc noopener noreferrer'; a.target = '_blank'; a.referrerPolicy = 'no-referrer';
        a.append(node); node = a;
      }
      el.append(node);
    }
  }
  return root;
}
async function load() {
  if (loading) return;
  loading = true;
  try {
    if (!validID.test(id)) throw new Error('This Chapter link is incomplete.');
    const response = await fetch(endpoint, {cache:'no-store', credentials:'omit', referrerPolicy:'no-referrer'});
    if (!response.ok) throw new Error(response.status === 404 ? 'This Chapter is no longer shared, or the link is unavailable.' : 'We could not open this Chapter. Please try again.');
    const data = await response.json();
    $('title').textContent = data.title;
    // Formatting (if any) covers exactly the approved excerpt; otherwise plain text.
    const rich = renderRich(data.content);
    if (rich) $('excerpt').replaceChildren(rich); else $('excerpt').textContent = data.excerpt;
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
