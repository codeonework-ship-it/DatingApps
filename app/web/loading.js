// Pre-boot loader: shown until Flutter paints its first frame.
//
// This file is loaded synchronously right after #loading in index.html, so the
// loader text below is already parsed and is swapped before Flutter boots. It
// is a separate same-origin file rather than an inline <script> because the
// website serves /app/ with `script-src 'self'` (no inline scripts).

// Loader language. The order mirrors how the app itself picks a language:
//  1. The member's saved choice. The app caches it with shared_preferences;
//     on the web that is localStorage key `flutter.connect.locale` holding a
//     JSON-encoded string such as "de" or "en-GB" (shared_preferences_web
//     prefixes keys with `flutter.` and stores json.encode(value)). An explicit
//     choice in the app beats everything, including a link from the website.
//  2. `?lang=<tag>` on the URL (e.g. /app/?lang=de#/signin), which the website
//     adds to every link into the app so the loader matches the page the
//     visitor came from.
//  3. The browser's languages (navigator.languages / navigator.language).
//  4. US English.
// Tags 1 and 2 must be one of the app's exact wire tags (as appLocaleFromTag in
// lib/core/i18n/app_locale_provider.dart accepts); browser tags are matched by
// language, with en-GB kept apart from the other English variants.
(() => {
  const STRINGS = {
    'en-US': {title: 'Connect — Your space', loading: 'Making room for your next hello…', site: '/',
      slow: ['Taking longer than expected. ', 'Try again', ' or ', 'return to the website', '.']},
    'en-GB': {title: 'Connect — Your space', loading: 'Making room for your next hello…', site: '/en-gb/',
      slow: ['Taking longer than expected. ', 'Try again', ' or ', 'return to the website', '.']},
    de: {title: 'Connect — Dein Bereich', loading: 'Wir machen Platz für dein nächstes Hallo…', site: '/de/',
      slow: ['Das dauert länger als gedacht. ', 'Versuch es noch mal', ' oder ', 'geh zurück zur Website', '.']},
    fr: {title: 'Connect — Ton espace', loading: 'On fait de la place pour ton prochain bonjour…', site: '/fr/',
      slow: ['Ça prend plus de temps que prévu. ', 'Réessaie', ' ou ', 'retourne sur le site', '.']},
    ru: {title: 'Connect — Твоё пространство', loading: 'Готовим место для твоего следующего «привет»…', site: '/ru/',
      slow: ['Загрузка идёт дольше, чем обычно. ', 'Попробуй ещё раз', ' или ', 'вернись на сайт', '.']},
    es: {title: 'Connect — Tu espacio', loading: 'Haciendo sitio para tu próximo hola…', site: '/es/',
      slow: ['Está tardando más de lo esperado. ', 'Vuelve a intentarlo', ' o ', 'regresa al sitio web', '.']},
    it: {title: 'Connect — Il tuo spazio', loading: 'Stiamo facendo spazio al tuo prossimo ciao…', site: '/it/',
      slow: ['Ci sta mettendo più del previsto. ', 'Riprova', ' oppure ', 'torna al sito', '.']},
    pt: {title: 'Connect — O teu espaço', loading: 'A preparar espaço para o teu próximo olá…', site: '/pt/',
      slow: ['Está a demorar mais do que o esperado. ', 'Tenta novamente', ' ou ', 'volta ao site', '.']},
    nl: {title: 'Connect — Jouw plek', loading: 'We maken ruimte voor je volgende hallo…', site: '/nl/',
      slow: ['Dit duurt langer dan verwacht. ', 'Probeer het opnieuw', ' of ', 'ga terug naar de website', '.']},
    pl: {title: 'Connect — Twoja przestrzeń', loading: 'Robimy miejsce na twoje kolejne „cześć”…', site: '/pl/',
      slow: ['To trwa dłużej, niż się spodziewaliśmy. ', 'Spróbuj ponownie', ' albo ', 'wróć na stronę', '.']},
  };
  const exact = tag => (typeof tag === 'string' && Object.prototype.hasOwnProperty.call(STRINGS, tag) ? tag : null);

  const cached = () => {
    try {
      const raw = window.localStorage.getItem('flutter.connect.locale');
      return raw == null ? null : exact(JSON.parse(raw));
    } catch (_) {
      return null; // storage blocked (private mode, policy) or not JSON
    }
  };

  const fromQuery = () => {
    try {
      return exact(new URLSearchParams(window.location.search).get('lang'));
    } catch (_) {
      return null;
    }
  };

  const fromBrowser = () => {
    const wanted = (navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language]);
    for (const raw of wanted) {
      const [language = '', region = ''] = String(raw || '').replace('_', '-').toLowerCase().split('-');
      if (language === 'en') return region === 'gb' ? 'en-GB' : 'en-US';
      if (exact(language)) return language;
    }
    return null;
  };

  const tag = cached() || fromQuery() || fromBrowser() || 'en-US';
  const text = STRINGS[tag];
  document.documentElement.lang = tag;
  document.title = text.title;
  const loading = document.querySelector('#loading p:not(#slow)');
  if (loading) loading.textContent = text.loading;
  const slow = document.querySelector('#slow');
  if (slow) {
    const [lead, retry, joiner, back, end] = text.slow;
    const retryLink = document.createElement('a');
    retryLink.href = '';
    retryLink.textContent = retry;
    const siteLink = document.createElement('a');
    siteLink.href = text.site;
    siteLink.textContent = back;
    slow.replaceChildren(lead, retryLink, joiner, siteLink, end);
  }
})();

window.addEventListener('flutter-first-frame', () => {
  document.querySelector('#loading')?.remove();
});

window.setTimeout(() => {
  const note = document.querySelector('#slow');
  if (note) note.style.display = 'block';
}, 15000);
