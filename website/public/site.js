const menu = document.querySelector('.menu-toggle');
const nav = document.querySelector('.navigation');
menu?.addEventListener('click', () => {
  const open = menu.getAttribute('aria-expanded') !== 'true';
  menu.setAttribute('aria-expanded', String(open)); nav.classList.toggle('open', open);
});
nav?.addEventListener('click', event => {if(event.target.closest('a')) {menu?.setAttribute('aria-expanded','false');nav.classList.remove('open');}});
document.addEventListener('keydown',event=>{if(event.key==='Escape'){menu?.setAttribute('aria-expanded','false');nav?.classList.remove('open');}});
const search = document.querySelector('#feature-search');
search?.addEventListener('input', () => {
  const query=search.value.trim().toLowerCase();let visible=0;
  document.querySelectorAll('[data-feature]').forEach(card=>{card.hidden=!card.textContent.toLowerCase().includes(query);if(!card.hidden)visible++;});
  // The page carries its own language's labels so this script stays locale-free.
  const status=document.querySelector('#feature-status');
  status.textContent=visible ? (status.dataset.countLabel || '{n} features').replace('{n}', visible) : (status.dataset.emptyLabel || 'No matches. Try “chat”, “profile” or “safety”.');
});
// Language switcher: each option's value is the same page in that locale.
document.querySelector('[data-lang-switch]')?.addEventListener('change', event => { location.href = event.target.value; });
