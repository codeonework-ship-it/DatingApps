// Public support form (/contact and its locale copies). Posts JSON to the
// same-origin, unauthenticated POST /v1/support/contact. Every visible message
// comes from data-* attributes rendered by generate_pages.py, so this file has
// no copy of its own and works for every locale.
(() => {
  const form = document.getElementById('contact-form');
  if (!form) return;
  const feedback = document.getElementById('contact-feedback');
  const success = document.getElementById('contact-success');
  const reference = document.getElementById('contact-reference');
  const again = document.getElementById('contact-again');
  const submit = document.getElementById('contact-submit');
  const counter = document.getElementById('contact-description-count');
  const msg = form.dataset;
  const field = name => form.elements.namedItem(name);
  const FIELDS = ['email', 'name', 'category', 'subject', 'description'];
  // Mirrors the API's limits; the server remains the authority.
  const LIMITS = {email: 254, name: 120, subjectMin: 4, subject: 120, description: 5000};
  const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const CATEGORIES = new Set([...field('category').options].map(option => option.value).filter(Boolean));
  const TIMEOUT_MS = 20000;
  const submitLabel = submit.textContent;
  const length = value => [...value].length; // code points, not UTF-16 units

  form.hidden = false; // shown only when this script runs; <noscript> covers the rest

  const values = () => ({
    email: field('email').value.trim(),
    name: field('name').value.trim(),
    category: field('category').value,
    subject: field('subject').value.trim(),
    description: field('description').value.trim(),
  });

  function validate(v) {
    const errors = {};
    if (v.email.length > LIMITS.email || !EMAIL.test(v.email)) errors.email = msg.errEmail;
    if (length(v.name) > LIMITS.name) errors.name = msg.errName;
    if (!CATEGORIES.has(v.category)) errors.category = msg.errCategory;
    const subject = length(v.subject);
    if (subject < LIMITS.subjectMin || subject > LIMITS.subject) errors.subject = msg.errSubject;
    const description = length(v.description);
    if (description < 1 || description > LIMITS.description) errors.description = msg.errDescription;
    return errors;
  }

  function setFieldError(name, message) {
    const input = field(name);
    const error = document.getElementById(`contact-${name}-error`);
    if (message) input.setAttribute('aria-invalid', 'true'); else input.removeAttribute('aria-invalid');
    error.textContent = message || '';
    error.hidden = !message;
  }

  function clearFeedback() { feedback.replaceChildren(); }

  // One alert box: a title, plus (for validation) links that move focus to each field.
  function showFeedback(title, errors = {}) {
    const box = document.createElement('div');
    box.className = 'form-alert';
    box.tabIndex = -1;
    box.setAttribute('data-contact-alert', '');
    const heading = document.createElement('p');
    heading.className = 'form-alert-title';
    heading.textContent = title;
    box.append(heading);
    const names = FIELDS.filter(name => errors[name]);
    if (names.length) {
      const list = document.createElement('ul');
      for (const name of names) {
        const link = document.createElement('a');
        link.href = `#contact-${name}`;
        link.textContent = errors[name];
        link.addEventListener('click', event => { event.preventDefault(); field(name).focus(); });
        const item = document.createElement('li');
        item.append(link);
        list.append(item);
      }
      box.append(list);
    }
    feedback.replaceChildren(box);
    box.focus();
  }

  function updateCounter() {
    counter.textContent = (msg.counter || '{n} / {max}')
      .replace('{n}', String(length(field('description').value)))
      .replace('{max}', String(LIMITS.description));
  }

  function setSending(sending) {
    submit.disabled = sending;
    submit.setAttribute('aria-busy', String(sending));
    form.setAttribute('aria-busy', String(sending));
    submit.textContent = sending ? (msg.sending || submitLabel) : submitLabel;
  }

  function errorMessage(status, data) {
    const code = data && typeof data === 'object' ? data.error_code : undefined;
    if (status === 429 || code === 'SUPPORT_RATE_LIMITED') return msg.errRate;
    if (code === 'FEATURE_DISABLED') return msg.errDisabled;
    if (status === 400 || status === 422) {
      const text = data && typeof data.error === 'string' ? data.error.trim() : '';
      return text ? text.slice(0, 300) : msg.errInvalid;
    }
    return msg.errGeneric;
  }

  function showSuccess(ref) {
    clearFeedback();
    form.hidden = true;
    reference.replaceChildren();
    if (typeof ref === 'string' && ref.trim()) {
      // "Your reference is {ref}." with the reference emphasised.
      const [before, after = ''] = (success.dataset.refTemplate || '{ref}').split('{ref}');
      const strong = document.createElement('strong');
      strong.textContent = ref.trim();
      reference.append(before, strong, after);
      reference.hidden = false;
    } else {
      reference.hidden = true;
    }
    success.hidden = false;
    success.focus();
  }

  async function send(body) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const response = await fetch('/v1/support/contact', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', Accept: 'application/json'},
        body: JSON.stringify(body),
        credentials: 'omit', // public form: never attach member credentials
        cache: 'no-store',
        signal: controller.signal,
      });
      const data = await response.json().catch(() => ({}));
      return {ok: response.ok, status: response.status, data};
    } finally {
      clearTimeout(timer);
    }
  }

  let sending = false;
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (sending) return;
    const v = values();
    const errors = validate(v);
    FIELDS.forEach(name => setFieldError(name, errors[name]));
    if (Object.keys(errors).length) { showFeedback(msg.errorsTitle, errors); return; }

    const body = {email: v.email, category: v.category, subject: v.subject, description: v.description,
      locale: document.documentElement.lang || 'en', website: field('website').value};
    if (v.name) body.name = v.name;
    sending = true;
    setSending(true);
    clearFeedback();
    let result;
    try { result = await send(body); } catch { result = {ok: false, status: 0, data: {}}; }
    sending = false;
    setSending(false);
    if (result.ok) showSuccess(result.data && result.data.reference);
    else showFeedback(errorMessage(result.status, result.data));
  });

  // Re-check a flagged field as it is corrected, so stale errors disappear.
  FIELDS.forEach(name => {
    const input = field(name);
    const recheck = () => { if (input.getAttribute('aria-invalid') === 'true') setFieldError(name, validate(values())[name]); };
    input.addEventListener('input', recheck);
    input.addEventListener('change', recheck);
  });
  field('description').addEventListener('input', updateCounter);
  updateCounter();

  again.addEventListener('click', () => {
    // Keep who is writing; clear what they wrote.
    for (const name of ['category', 'subject', 'description']) field(name).value = '';
    FIELDS.forEach(name => setFieldError(name, ''));
    updateCounter();
    success.hidden = true;
    form.hidden = false;
    field('category').focus();
  });
})();
