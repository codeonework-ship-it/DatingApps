/* Operator console shell: the menu button, Bootstrap toasts and
 * confirmation (window.ConsoleUI), and live updates.
 *
 * Menu: one button at every width. At 992px and up it folds the sidebar
 * into an icon rail and back (remembered per browser); below that it opens
 * the sidebar as a drawer.
 *
 * Live: one WebSocket per page (/ws/live/, control_panel/consumers.py).
 *   nav        queue counts on the sidebar links, the BFF badge, a toast
 *              when the queue on screen changes, a sticky toast for new SOS.
 *   dashboard  replaces [data-live-region="dashboard"] when it changes.
 * Reads pause while the tab is hidden. Reconnects with backoff; after
 * several failures the page says updates are off and offers a reload.
 */
(function () {
  'use strict';

  var root = document.documentElement;
  var sidebar = document.getElementById('sidebar');
  var toggle = document.getElementById('menu-toggle');
  var desktop = window.matchMedia('(min-width: 992px)');

  // ── Menu ─────────────────────────────────────────────────────────────
  function store(key, value) {
    try { if (value === null) localStorage.removeItem(key); else localStorage.setItem(key, value); } catch (e) { /* private mode */ }
  }
  // In the icon rail each link shows its name as a tooltip.
  function syncTooltips(rail) {
    if (!sidebar) return;
    sidebar.querySelectorAll('.nav-item-link').forEach(function (link) {
      var label = link.querySelector('.nav-label');
      if (rail && label) link.title = label.textContent.trim();
      else link.removeAttribute('title');
    });
  }
  function syncToggle() {
    if (!toggle) return;
    if (desktop.matches) {
      var open = root.dataset.sidebar !== 'collapsed';
      toggle.setAttribute('aria-expanded', String(open));
      toggle.setAttribute('aria-label', open ? 'Collapse menu' : 'Expand menu');
      toggle.title = open ? 'Collapse menu' : 'Expand menu';
      syncTooltips(!open);
    } else {
      syncTooltips(false);
      var shown = sidebar && sidebar.classList.contains('show');
      toggle.setAttribute('aria-expanded', String(Boolean(shown)));
      toggle.setAttribute('aria-label', 'Open menu');
      toggle.title = 'Menu';
    }
  }
  if (toggle && sidebar) {
    toggle.addEventListener('click', function () {
      if (desktop.matches) {
        var collapse = root.dataset.sidebar !== 'collapsed';
        if (collapse) root.dataset.sidebar = 'collapsed'; else delete root.dataset.sidebar;
        store('console.sidebar', collapse ? 'collapsed' : null);
      } else if (window.bootstrap) {
        window.bootstrap.Offcanvas.getOrCreateInstance(sidebar).toggle();
      }
      syncToggle();
    });
    sidebar.addEventListener('shown.bs.offcanvas', syncToggle);
    sidebar.addEventListener('hidden.bs.offcanvas', function () { syncToggle(); toggle.focus(); });
    desktop.addEventListener('change', syncToggle);
    syncToggle();
  }

  // ── Bootstrap UI: toasts, confirmation, modals ──────────────────────
  var toastBox = document.querySelector('[data-toasts]');
  var bs = window.bootstrap;

  // Modals declared inside cards or tables would be trapped by the card's
  // backdrop-filter (a containing block for position: fixed) and inherit
  // the cell's alignment; Bootstrap expects them as children of <body>.
  document.querySelectorAll('.page-body .modal').forEach(function (modal) {
    document.body.appendChild(modal);
  });

  // Flash messages rendered by Django.
  if (bs) {
    document.querySelectorAll('[data-toasts] .toast').forEach(function (el) {
      el.addEventListener('hidden.bs.toast', function () { el.remove(); });
      bs.Toast.getOrCreateInstance(el).show();
    });
  }

  var ICONS = {error: 'bi-x-circle-fill', warning: 'bi-exclamation-triangle-fill', success: 'bi-check-circle-fill', info: 'bi-info-circle-fill'};

  /** Shows a Bootstrap toast. options: tone (info|success|warning|error),
   *  key (replaces an earlier toast with the same key), action {label,
   *  href|onClick}, sticky (no auto-hide). Returns the toast element. */
  function toast(text, options) {
    options = options || {};
    if (!toastBox || !bs) return null;
    var tone = ICONS[options.tone] ? options.tone : 'info';
    var el = options.key ? toastBox.querySelector('[data-key="' + options.key + '"]') : null;
    if (el) { bs.Toast.getOrCreateInstance(el).dispose(); el.remove(); }
    el = document.createElement('div');
    el.className = 'toast console-toast ' + tone;
    el.setAttribute('role', tone === 'error' || tone === 'warning' ? 'alert' : 'status');
    if (options.key) el.dataset.key = options.key;
    var body = document.createElement('div');
    body.className = 'toast-body';
    var icon = document.createElement('i');
    icon.className = 'bi ' + ICONS[tone];
    icon.setAttribute('aria-hidden', 'true');
    var msg = document.createElement('span');
    msg.className = 'toast-text';
    msg.textContent = text;
    body.append(icon, msg);
    if (options.action) {
      var action = document.createElement(options.action.href ? 'a' : 'button');
      action.className = 'btn btn-sm btn-glass toast-action';
      action.textContent = options.action.label;
      if (options.action.href) action.href = options.action.href;
      else { action.type = 'button'; action.addEventListener('click', options.action.onClick); }
      body.appendChild(action);
    }
    var close = document.createElement('button');
    close.type = 'button';
    close.className = 'btn-close btn-close-white';
    close.setAttribute('data-bs-dismiss', 'toast');
    close.setAttribute('aria-label', 'Dismiss');
    body.appendChild(close);
    el.appendChild(body);
    toastBox.appendChild(el);
    el.addEventListener('hidden.bs.toast', function () { el.remove(); });
    bs.Toast.getOrCreateInstance(el, {autohide: !options.sticky, delay: options.delay || 6000}).show();
    return el;
  }

  /** Bootstrap confirmation dialog. Resolves true when confirmed. */
  var confirmEl = document.getElementById('confirm-modal');
  function confirmDialog(options) {
    if (!confirmEl || !bs) return Promise.resolve(window.confirm(options.body || options.title));
    return new Promise(function (resolve) {
      var modal = bs.Modal.getOrCreateInstance(confirmEl);
      var accept = confirmEl.querySelector('[data-confirm-accept]');
      confirmEl.querySelector('.modal-title').textContent = options.title || 'Are you sure?';
      confirmEl.querySelector('.modal-body').textContent = options.body || '';
      accept.textContent = options.confirmLabel || 'Confirm';
      accept.className = 'btn ' + (options.tone === 'primary' ? 'btn-glow' : 'btn-danger-glass');
      var accepted = false;
      function onAccept() { accepted = true; modal.hide(); }
      accept.addEventListener('click', onAccept, {once: true});
      confirmEl.addEventListener('hidden.bs.modal', function () {
        accept.removeEventListener('click', onAccept);
        resolve(accepted);
      }, {once: true});
      confirmEl.addEventListener('shown.bs.modal', function () { accept.focus(); }, {once: true});
      modal.show();
    });
  }

  // <form data-confirm="Body" data-confirm-title="…" data-confirm-label="Delete">
  // and <button type="submit" data-confirm="…"> ask before submitting.
  document.addEventListener('submit', function (event) {
    var form = event.target;
    var submitter = event.submitter;
    var source = submitter && submitter.hasAttribute('data-confirm') ? submitter : form;
    if (!source.hasAttribute('data-confirm') || form.dataset.confirmed === '1') return;
    event.preventDefault();
    confirmDialog({
      title: source.getAttribute('data-confirm-title'),
      body: source.getAttribute('data-confirm'),
      confirmLabel: source.getAttribute('data-confirm-label'),
      tone: source.getAttribute('data-confirm-tone'),
    }).then(function (ok) {
      if (!ok) return;
      form.dataset.confirmed = '1';
      if (form.requestSubmit) form.requestSubmit(submitter || undefined); else form.submit();
      delete form.dataset.confirmed;
    });
  });

  // <select data-autosubmit> submits its form on change (filters, periods).
  document.addEventListener('change', function (event) {
    var el = event.target;
    if (!el.matches || !el.matches('select[data-autosubmit]') || !el.form) return;
    if (el.form.requestSubmit) el.form.requestSubmit(); else el.form.submit();
  });

  document.addEventListener('click', function (event) {
    if (event.target.closest && event.target.closest('[data-print]')) window.print();
  });

  window.ConsoleUI = {toast: toast, confirm: confirmDialog};

  // ── Live updates ─────────────────────────────────────────────────────
  if (!('WebSocket' in window) || !document.querySelector('[data-live-status]')) return;

  var statusEl = document.querySelector('[data-live-status]');
  var tailToggle = document.querySelector('[data-live-tail]');
  var activityFilters = {};
  try {
    var filterScript = document.getElementById('activity-live-filters');
    if (filterScript) activityFilters = JSON.parse(filterScript.textContent) || {};
  } catch (e) { activityFilters = {}; }

  function wantedTopics() {
    var list = ['nav'];
    document.querySelectorAll('[data-live-topic]').forEach(function (el) {
      var t = el.getAttribute('data-live-topic');
      if (t === 'activity' && tailToggle && !tailToggle.checked) return;
      if (t && list.indexOf(t) < 0) list.push(t);
    });
    return list;
  }
  var topics = wantedTopics();

  var socket = null;
  var failures = 0;
  var retryTimer = null;
  var signingOut = false;
  var baseline = {};       // queue url name -> count when this page loaded
  var knownSos = null;     // open SOS ids already seen

  function setStatus(state, text) {
    if (!statusEl) return;
    statusEl.dataset.liveStatus = state;
    statusEl.title = text;
    var label = statusEl.querySelector('.live-status-text');
    if (label) label.textContent = text;
  }

  function send(message) {
    if (socket && socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message));
  }

  function connect() {
    clearTimeout(retryTimer);
    setStatus('connecting', failures ? 'Reconnecting' : 'Connecting');
    var scheme = location.protocol === 'https:' ? 'wss://' : 'ws://';
    socket = new WebSocket(scheme + location.host + '/ws/live/');
    socket.addEventListener('open', function () {
      failures = 0;
      setStatus('live', 'Live');
      send({type: 'subscribe', topics: topics, activity: activityFilters});
      if (document.hidden) send({type: 'pause'});
    });
    socket.addEventListener('message', function (event) {
      var msg;
      try { msg = JSON.parse(event.data); } catch (e) { return; }
      if (msg.type === 'topic') apply(msg.topic, msg.data || {});
      else if (msg.type === 'signed_out') signedOut();
    });
    socket.addEventListener('close', function (event) {
      socket = null;
      if (signingOut) return;
      if (event.code === 4401) { signedOut(); return; }
      failures += 1;
      if (failures >= 6) {
        setStatus('off', 'Updates off');
        toast('Live updates stopped. The page still works; reload to see the latest.', {tone: 'warning', key: 'live-off', sticky: true, action: {label: 'Reload', onClick: reload}});
        return;
      }
      setStatus('connecting', 'Reconnecting');
      // 1s, 2s, 4s, 8s, 16s (+ jitter) so a restarting server isn't stampeded.
      retryTimer = setTimeout(connect, Math.min(16000, 1000 * Math.pow(2, failures - 1)) + Math.random() * 500);
    });
  }

  function signedOut() {
    signingOut = true;
    setStatus('off', 'Signed out');
    window.location.assign('/login/?next=' + encodeURIComponent(location.pathname + location.search));
  }

  function apply(topic, data) {
    if (topic === 'nav') applyNav(data);
    else if (topic === 'dashboard') applyDashboard(data);
    else if (topic === 'activity') applyActivity(data);
  }

  function applyNav(data) {
    var queues = data.queues || {};
    document.querySelectorAll('[data-nav]').forEach(function (link) {
      var name = link.getAttribute('data-nav');
      var q = queues[name];
      var badge = link.querySelector('.nav-badge');
      var spoken = link.querySelector('.nav-badge-text');
      if (!q || !q.count) { if (badge) badge.remove(); if (spoken) spoken.remove(); return; }
      if (!badge) {
        badge = document.createElement('span');
        badge.className = 'nav-badge';
        badge.setAttribute('aria-hidden', 'true');
        spoken = document.createElement('span');
        spoken.className = 'visually-hidden nav-badge-text';
        link.append(badge, spoken);
      }
      var summary = q.count + (q.capped ? '+' : '') + ' open' + (q.overdue ? ', ' + q.overdue + ' past target' : '');
      badge.textContent = q.capped ? '99+' : String(q.count);
      badge.classList.toggle('danger', q.overdue > 0);
      badge.title = summary;
      spoken.textContent = ', ' + summary;

      // A toast on the queue page itself when it changes under the operator.
      if (link.classList.contains('active')) {
        if (!(name in baseline)) baseline[name] = q.count;
        else if (baseline[name] !== q.count) {
          toast('This queue changed: ' + q.count + ' open now (' + baseline[name] + ' when you opened it).', {tone: 'info', key: 'queue-' + name, sticky: true, action: {label: 'Reload', onClick: reload}});
        }
      }
    });

    var bff = document.querySelector('[data-live-bff]');
    if (bff && typeof data.bff_ok === 'boolean') {
      bff.classList.toggle('badge-active', data.bff_ok);
      bff.classList.toggle('badge-danger', !data.bff_ok);
      var text = data.bff_ok ? 'Go BFF Live' : 'BFF Unreachable';
      bff.title = text;
      bff.querySelectorAll('span').forEach(function (s) { s.textContent = text; });
    }

    var ids = data.sos_open_ids || [];
    if (knownSos !== null) {
      var fresh = ids.filter(function (id) { return knownSos.indexOf(id) < 0; });
      if (fresh.length) {
        toast(fresh.length === 1 ? 'New SOS alert.' : fresh.length + ' new SOS alerts.', {tone: 'error', key: 'sos', sticky: true, action: {label: 'Open SOS alerts', href: '/safety/sos/'}});
      }
    }
    knownSos = ids;
  }

  function applyDashboard(data) {
    var region = document.querySelector('[data-live-region="dashboard"]');
    if (region && typeof data.html === 'string') {
      region.innerHTML = data.html;
    }
    var stamp = document.querySelector('[data-live-stamp]');
    if (stamp && data.stamp) stamp.textContent = data.stamp;
  }

  // New member actions arrive oldest first; each goes on top, highlighted.
  var MAX_ACTIONS = 300;
  function applyActivity(data) {
    var body = document.querySelector('[data-activity-body]');
    if (!body || !Array.isArray(data.rows) || !data.rows.length) return;
    var empty = document.querySelector('[data-activity-empty]');
    if (empty) empty.remove();
    data.rows.forEach(function (html) {
      var tpl = document.createElement('template');
      tpl.innerHTML = html.trim();
      var rows = Array.prototype.slice.call(tpl.content.children);
      rows.slice().reverse().forEach(function (row) { body.insertBefore(row, body.firstChild); });
      if (rows[0]) {
        rows[0].classList.add('is-new');
        setTimeout(function () { rows[0].classList.remove('is-new'); }, 4000);
      }
    });
    while (body.querySelectorAll('tr.activity-row').length > MAX_ACTIONS) {
      body.removeChild(body.lastElementChild);  // detail row
      body.removeChild(body.lastElementChild);  // action row
    }
    var status = document.querySelector('[data-live-status]');
    if (status) status.title = data.rows.length + ' new action' + (data.rows.length === 1 ? '' : 's');
  }

  if (tailToggle) {
    tailToggle.addEventListener('change', function () {
      topics = wantedTopics();
      send({type: 'subscribe', topics: topics, activity: activityFilters});
    });
  }

  function reload() { location.reload(); }

  document.addEventListener('visibilitychange', function () {
    send({type: document.hidden ? 'pause' : 'resume'});
  });
  document.querySelectorAll('[data-sign-out]').forEach(function (button) {
    button.addEventListener('click', function () { signingOut = true; });
  });
  window.addEventListener('pagehide', function () { signingOut = true; if (socket) socket.close(1000); });
  window.addEventListener('pageshow', function (event) {
    if (event.persisted) { signingOut = false; failures = 0; connect(); } // back/forward cache
  });

  connect();
})();
