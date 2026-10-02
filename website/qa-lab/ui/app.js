// QA Lab UI. Plain ES module, no dependencies; every DOM node is built with
// textContent (no innerHTML with data) and the page runs under script-src 'self'.

const $ = sel => document.querySelector(sel);
const CHIP = {
  pass: 'pass', fail: 'fail', not_run: 'not run', skipped: 'skipped', not_automated: 'not automated',
  presence_only: 'presence-only', partial: 'partial', manual_pass: 'manual ✓', manual_fail: 'manual ✗', manual_unchecked: 'manual',
};
const CHIP_ORDER = ['pass', 'fail', 'not_run', 'skipped', 'manual_pass', 'manual_fail', 'manual_unchecked', 'presence_only', 'partial', 'not_automated'];
const SUITE_LABEL = {flutter: 'Flutter', playwright: 'Playwright', api_e2e: 'API e2e', appium: 'Appium', go: 'Go', django: 'Django', console_smoke: 'Console smoke', selftest: 'QA Lab self-test'};
const PAGE = 40;

const state = {
  operator: null, catalog: null, env: null, runs: [], current: null, manual: [],
  selected: new Set(), filters: {q: '', area: '', status: '', suite: '', type: ''}, shown: PAGE,
  tab: 'overview', es: null, runDetail: null, lastRun: null,
};

// ------------------------------------------------------------------ helpers
function h(tag, attrs = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === null || v === undefined || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'dataset') Object.assign(el.dataset, v);
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, String(v));
  }
  for (const kid of kids.flat()) {
    if (kid === null || kid === undefined || kid === false) continue;
    el.append(kid instanceof Node ? kid : document.createTextNode(String(kid)));
  }
  return el;
}
const chip = (status, label) => h('span', {class: `chip s-${status}`, text: label || CHIP[status] || status});
const pct = v => `${(Number(v) || 0).toFixed(1)}%`;
const when = iso => (iso ? new Date(iso).toLocaleString(undefined, {month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'}) : '—');
const dur = (a, b) => {
  if (!a) return '—';
  const s = Math.max(0, Math.round(((b ? new Date(b) : new Date()) - new Date(a)) / 1000));
  return s >= 3600 ? `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m` : s >= 60 ? `${Math.floor(s / 60)}m ${s % 60}s` : `${s}s`;
};
function setWidth(el, fraction) { el.style.width = `${Math.max(0, Math.min(100, fraction * 100)).toFixed(2)}%`; }
function toast(msg) {
  const t = $('#toast');
  t.textContent = msg; t.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => { t.hidden = true; }, 3500);
}
function store(key, value) { try { if (value === undefined) return localStorage.getItem(key); localStorage.setItem(key, value); } catch { /* storage unavailable */ } return null; }

async function api(path, opts = {}) {
  const init = {method: opts.method || 'GET', credentials: 'same-origin', headers: {Accept: 'application/json'}};
  if (init.method !== 'GET') { init.headers['X-QA-Lab'] = '1'; init.headers['Content-Type'] = 'application/json'; init.body = JSON.stringify(opts.body || {}); }
  const res = await fetch(`/qa-lab/api${path}`, init);
  let data = null;
  try { data = await res.json(); } catch { data = null; }
  if (res.status === 401 && path !== '/session') { showSignIn(); throw new Error('signed out'); }
  if (!res.ok) throw Object.assign(new Error(data?.error || `HTTP ${res.status}`), {status: res.status});
  return data;
}

// ------------------------------------------------------------------ theme
function applyTheme(t) {
  if (t === 'light' || t === 'dark') document.documentElement.dataset.theme = t;
  else delete document.documentElement.dataset.theme;
}
applyTheme(store('qaLabTheme'));
$('#themeToggle').addEventListener('click', () => {
  const dark = document.documentElement.dataset.theme ? document.documentElement.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  const next = dark ? 'light' : 'dark';
  applyTheme(next); store('qaLabTheme', next);
});

// ------------------------------------------------------------------ auth
function showSignIn() {
  state.operator = null;
  if (state.es) { state.es.close(); state.es = null; }
  for (const id of ['view-overview', 'view-cases', 'view-runs', 'view-manual']) $(`#${id}`).hidden = true;
  $('#tabs').hidden = true; $('#who').hidden = true; $('#signin').hidden = false;
  setTimeout(() => $('#username').focus(), 0);
}
$('#signinForm').addEventListener('submit', async e => {
  e.preventDefault();
  const err = $('#signinError');
  err.hidden = true;
  $('#signinButton').disabled = true;
  try {
    const r = await api('/session', {method: 'POST', body: {username: $('#username').value, password: $('#password').value}});
    $('#password').value = '';
    await enter(r.operator);
  } catch (ex) {
    err.textContent = ex.message; err.hidden = false;
  } finally {
    $('#signinButton').disabled = false;
  }
});
$('#signOut').addEventListener('click', async () => {
  try { await api('/session', {method: 'DELETE'}); } catch { /* ignore */ }
  showSignIn();
});

async function enter(operator) {
  state.operator = operator;
  $('#signin').hidden = true; $('#tabs').hidden = false; $('#who').hidden = false;
  $('#whoName').textContent = `${operator.name || operator.username} · ${operator.roles.join(', ')}`;
  selectTab(store('qaLabTab') || 'overview');
  connectEvents();
  await Promise.all([loadCatalog(), loadEnv(), loadRuns(), loadManual()]);
}

// ------------------------------------------------------------------ tabs
function selectTab(tab) {
  if (!['overview', 'cases', 'runs', 'manual'].includes(tab)) tab = 'overview';
  state.tab = tab; store('qaLabTab', tab);
  for (const b of document.querySelectorAll('#tabs [role=tab]')) b.setAttribute('aria-selected', String(b.dataset.tab === tab));
  for (const t of ['overview', 'cases', 'runs', 'manual']) $(`#view-${t}`).hidden = t !== tab;
  if (tab === 'cases') renderCases();
}
for (const b of document.querySelectorAll('#tabs [role=tab]')) b.addEventListener('click', () => selectTab(b.dataset.tab));

// ------------------------------------------------------------------ loading
async function loadCatalog() {
  state.catalog = await api('/catalog');
  renderOverview();
  fillFilterOptions();
  if (state.tab === 'cases') renderCases();
}
async function loadEnv() { state.env = await api('/env'); renderRunPanel(); renderSeed(); }
async function loadRuns() {
  const r = await api('/runs');
  state.runs = r.runs || [];
  state.current = r.current;
  renderRuns(); renderLive();
}
async function loadManual() {
  const r = await api('/manual');
  state.manual = r.cases || [];
  renderManual();
}

// ------------------------------------------------------------------ live events
function connectEvents() {
  if (state.es) state.es.close();
  const es = new EventSource('/qa-lab/api/events');
  state.es = es;
  es.addEventListener('hello', e => {
    const d = JSON.parse(e.data);
    state.current = d.run;
    if (d.run) state.lastRun = d.run;
    $('#log').textContent = (d.lines || []).join('\n');
    renderLive();
  });
  es.addEventListener('run', e => { state.current = JSON.parse(e.data); state.lastRun = state.current; renderLive(); });
  es.addEventListener('progress', e => {
    const d = JSON.parse(e.data);
    if (state.current && state.current.id === d.run) { state.current.progress = d.progress; renderLive(); }
  });
  es.addEventListener('log', e => {
    const d = JSON.parse(e.data);
    const log = $('#log');
    const atBottom = log.scrollHeight - log.scrollTop - log.clientHeight < 30;
    const lines = (log.textContent ? log.textContent.split('\n') : []).concat(d.lines || []);
    log.textContent = lines.slice(-400).join('\n');
    if (atBottom) log.scrollTop = log.scrollHeight;
  });
  es.addEventListener('done', async e => {
    const d = JSON.parse(e.data);
    toast(`Run ${d.run} ${d.status}`);
    state.current = null;
    await Promise.all([loadCatalog(), loadRuns()]);
    renderLive();
  });
  es.addEventListener('manual', () => { loadManual().catch(() => {}); });
  es.onerror = () => { /* EventSource reconnects by itself */ };
}

// ------------------------------------------------------------------ overview
function renderOverview() {
  const c = state.catalog;
  const a = c.coverage.all;
  const meters = $('#meters');
  meters.replaceChildren(
    meter('Automated', a.automatedPct, `${a.automated} of ${a.total} cases have a test that acts and asserts`),
    meter('Automated + manual checked', a.automatedOrManualPct, `${a.automated} automated + ${a.manualChecked} manual cases checked`),
    meter('Verified (gate)', a.verifiedPct, `${a.verified} of ${a.total}: passing in the latest run, or manual & checked`, 'gate'),
  );
  $('#catalogMeta').textContent = `catalog ${c.generated || ''} · ${a.total} cases · ${c.features.length} features`;
  const counts = {pass: a.passing, fail: a.failing, not_run: a.notRun, manual_pass: a.manualChecked, manual_fail: a.manualFailed,
    manual_unchecked: a.manual - a.manualChecked - a.manualFailed, presence_only: a.presenceOnly, partial: a.partial, not_automated: a.notAutomated};
  const stack = $('#statusStack');
  stack.replaceChildren();
  const legend = $('#statusLegend');
  legend.replaceChildren();
  for (const k of CHIP_ORDER) {
    const n = counts[k] || 0;
    if (!n) continue;
    const seg = h('span', {class: `s-${k}`, title: `${CHIP[k]}: ${n}`});
    setWidth(seg, n / a.total);
    stack.append(seg);
    legend.append(h('li', {}, h('span', {class: `dot s-${k}`}), h('button', {class: 'linkish', type: 'button', onclick: () => openCases({status: k.startsWith('manual') ? (k === 'manual_unchecked' ? 'manual_unchecked' : 'manual') : k})}, CHIP[k]), h('span', {class: 'n', text: n})));
  }
  // by suite
  const suiteRows = Object.entries(c.coverage.bySuite).sort((x, y) => y[1].total - x[1].total);
  $('#bySuite').replaceChildren(
    h('thead', {}, h('tr', {}, h('th', {text: 'Suite'}), h('th', {class: 'num', text: 'Cases'}), h('th', {class: 'num', text: 'Automated'}), h('th', {class: 'num', text: 'Passing'}), h('th', {class: 'num', text: 'Failing'}), h('th', {text: 'Passing'}))),
    h('tbody', {}, suiteRows.map(([k, v]) => h('tr', {},
      h('td', {}, h('button', {class: 'linkish', type: 'button', onclick: () => openCases({suite: k})}, SUITE_LABEL[k] || k)),
      h('td', {class: 'num', text: v.total}), h('td', {class: 'num', text: v.automated}), h('td', {class: 'num', text: v.passing}),
      h('td', {class: 'num', text: v.failing}), h('td', {class: 'mini'}, bar(v.automated ? v.passing / v.automated : 0, 'pass'))))),
  );
  const areaRows = Object.entries(c.coverage.byArea).sort((x, y) => x[1].verifiedPct - y[1].verifiedPct || y[1].total - x[1].total);
  $('#byArea').replaceChildren(
    h('thead', {}, h('tr', {}, h('th', {text: 'Area'}), h('th', {class: 'num', text: 'Cases'}), h('th', {class: 'num', text: 'Automated'}), h('th', {class: 'num', text: 'Verified'}), h('th', {class: 'num', text: 'Failing'}), h('th', {text: ''}))),
    h('tbody', {}, areaRows.map(([k, v]) => h('tr', {},
      h('td', {}, h('button', {class: 'linkish', type: 'button', onclick: () => openCases({area: k})}, k)),
      h('td', {class: 'num', text: v.total}), h('td', {class: 'num', text: pct(v.automatedPct)}), h('td', {class: 'num', text: pct(v.verifiedPct)}),
      h('td', {class: 'num', text: v.failing}),
      h('td', {}, h('button', {class: 'small', type: 'button', onclick: () => startRun({mode: 'area', areas: [k]}), 'aria-label': `Run area ${k}`}, 'Run'))))),
  );
}
function meter(label, value, sub, kind = '') {
  return h('div', {class: `card meter ${kind}`}, h('span', {class: 'label', text: label}), h('span', {class: 'value', text: pct(value)}), bar(value / 100), h('span', {class: 'sub', text: sub}));
}
function bar(fraction, kind = '') {
  const fill = h('span', {class: 'bar-fill'});
  setWidth(fill, fraction);
  return h('div', {class: `bar ${kind}`, role: 'img', 'aria-label': pct(fraction * 100)}, fill);
}

function renderRunPanel() {
  const env = state.env;
  if (!env) return;
  const picker = $('#suitePicker');
  const saved = (() => { try { return JSON.parse(store('qaLabSuites') || 'null'); } catch { return null; } })();
  picker.replaceChildren(h('legend', {text: 'Suites'}));
  for (const [k, v] of Object.entries(env.suites)) {
    const box = h('input', {type: 'checkbox', value: k, disabled: !v.available, checked: v.available && (saved ? saved.includes(k) : k !== 'selftest')});
    box.addEventListener('change', () => store('qaLabSuites', JSON.stringify(selectedSuites())));
    picker.append(h('label', {class: v.available ? '' : 'unavailable', title: v.reason || ''}, box, v.label, v.available ? null : h('span', {class: 'why', text: `(${v.reason})`})));
  }
  const s = env.stack;
  $('#stackHealth').textContent = `gateway ${s.gateway ? 'up' : 'down'} · website ${s.website ? 'up' : 'down'} · postgres ${s.postgres ? 'up' : 'down'}`;
}
const selectedSuites = () => [...document.querySelectorAll('#suitePicker input:checked')].map(i => i.value);

function renderSeed() {
  const body = $('#seedBody');
  const s = state.env?.seed;
  if (!s) { body.replaceChildren(h('p', {class: 'muted', text: 'No seed yet. A run seeds first (or run .venv/bin/python qa/seed/seed_dataset.py ensure).'})); return; }
  const roles = Object.entries(s.members);
  body.replaceChildren(
    h('p', {}, 'Prefix ', h('code', {text: s.prefix}), ` · updated ${when(s.updated_at)} · steps ${s.steps.ok} ok, ${s.steps.skipped} skipped, ${s.steps.failed} failed`),
    h('p', {}, `seed_needs covered: ${s.needs.seeded} of ${s.needs.total}`),
    h('div', {class: 'seed-members'}, roles.slice(0, 30).map(([role, user]) => h('code', {title: role, text: user}))),
    s.needs.missing.length ? h('details', {}, h('summary', {text: `${s.needs.missing.length} needs not seeded`}),
      h('ul', {}, s.needs.missing.map(m => h('li', {}, h('strong', {text: m.need}), ` — ${m.status}${m.why.length ? `: ${m.why.join('; ')}` : ''}`)))) : null,
    h('p', {class: 'muted', text: 'Passwords are never shown: members use the local test password from qa/api_e2e/client.py.'}),
  );
}

function renderLive() {
  const run = state.current || state.lastRun;
  const running = run && run.status === 'running';
  $('#cancelRun').hidden = !running;
  for (const id of ['runAll', 'runFailed', 'runSelected', 'runArea']) $(`#${id}`).disabled = Boolean(running) || (id === 'runSelected' && !state.selected.size) || (id === 'runArea' && !state.filters.area);
  const live = $('#live');
  if (!run) { live.hidden = true; return; }
  live.hidden = false;
  $('#liveStatus').className = `chip s-${run.status}`;
  $('#liveStatus').textContent = run.status;
  $('#liveTitle').textContent = `${run.id} · ${run.mode} · by ${run.by} · ${dur(run.startedAt, run.finishedAt)}`;
  $('#liveSteps').replaceChildren(...run.steps.map(s => h('li', {}, chip(s.status === 'passed' ? 'pass' : s.status === 'failed' ? 'fail' : s.status, `${SUITE_LABEL[s.name] || s.name}${s.counts ? ` ${s.counts.passed}/${s.counts.passed + s.counts.failed}` : ''}`))));
  const p = run.progress;
  const fill = $('#liveBar');
  if (p && p.total) setWidth(fill, p.done / p.total);
  else setWidth(fill, run.steps.filter(s => !['pending', 'running'].includes(s.status)).length / Math.max(1, run.steps.length));
  $('#liveCounts').textContent = p ? `${SUITE_LABEL[p.step] || p.step}: ${p.done}${p.total ? `/${p.total}` : ''} done · ${p.passed} passed · ${p.failed} failed · ${p.skipped} skipped`
    : (run.summary ? `tests ${run.summary.tests.passed} passed, ${run.summary.tests.failed} failed · cases pass ${run.summary.cases.pass}, fail ${run.summary.cases.fail}` : '');
}

async function startRun(body) {
  const suites = selectedSuites();
  if (!suites.length) { toast('Pick at least one available suite.'); return; }
  try {
    const r = await api('/runs', {method: 'POST', body: {...body, suites, seed: $('#optSeed').checked, rescan: $('#optRescan').value || undefined}});
    state.current = r.run;
    state.lastRun = r.run;
    renderLive();
    $('#logBox').open = true;
    toast(`Run ${r.run.id} started`);
    selectTab('overview');
  } catch (e) { toast(e.message); }
}
$('#runAll').addEventListener('click', () => startRun({mode: 'all'}));
$('#runFailed').addEventListener('click', () => startRun({mode: 'failed'}));
$('#cancelRun').addEventListener('click', async () => {
  if (!state.current) return;
  try { await api(`/runs/${state.current.id}/cancel`, {method: 'POST'}); toast('Cancelling…'); } catch (e) { toast(e.message); }
});

// ------------------------------------------------------------------ cases
function fillFilterOptions() {
  const c = state.catalog;
  const areas = [...new Set(c.features.map(f => f.area))].sort();
  const types = [...new Set(c.features.flatMap(f => f.cases.map(k => k.type)))].sort();
  const suites = Object.keys(c.coverage.bySuite).sort();
  const fill = (sel, values, label, fmt = v => v) => {
    const cur = sel.value;
    sel.replaceChildren(h('option', {value: '', text: label}), ...values.map(v => h('option', {value: v, text: fmt(v)})));
    sel.value = values.includes(cur) ? cur : '';
  };
  fill($('#fArea'), areas, 'All areas');
  fill($('#fType'), types, 'All types');
  fill($('#fSuite'), suites, 'All suites', v => SUITE_LABEL[v] || v);
  for (const [id, key] of [['#fArea', 'area'], ['#fSuite', 'suite'], ['#fType', 'type'], ['#fStatus', 'status']]) $(id).value = state.filters[key] || '';
}

function caseMatches(f, k) {
  const fl = state.filters;
  if (fl.area && f.area !== fl.area) return false;
  if (fl.type && k.type !== fl.type) return false;
  if (fl.status) {
    if (fl.status === 'manual') { if (!k.chip.startsWith('manual')) return false; }
    else if (fl.status === 'gap') { if (k.chip === 'pass' || k.chip === 'manual_pass') return false; }
    else if (k.chip !== fl.status) return false;
  }
  if (fl.suite && !k.automated_by.some(a => a.suite === fl.suite) && !(k.last?.tests || []).some(t => t.suite === fl.suite)) return false;
  if (fl.q) {
    const hay = `${k.title} ${k.id} ${f.screen} ${f.id} ${k.automated_by.map(a => `${a.file} ${a.test}`).join(' ')}`.toLowerCase();
    if (!fl.q.toLowerCase().split(/\s+/).filter(Boolean).every(w => hay.includes(w))) return false;
  }
  return true;
}
function filtered() {
  const out = [];
  for (const f of state.catalog.features) {
    const cases = f.cases.filter(k => caseMatches(f, k));
    if (cases.length) out.push({f, cases});
  }
  return out;
}

function openCases(filters) {
  Object.assign(state.filters, {q: '', area: '', status: '', suite: '', type: ''}, filters);
  $('#fSearch').value = '';
  fillFilterOptions();
  state.shown = PAGE;
  selectTab('cases');
}

function renderCases() {
  if (!state.catalog) return;
  const list = filtered();
  const n = list.reduce((s, x) => s + x.cases.length, 0);
  $('#caseCount').textContent = `${n} case${n === 1 ? '' : 's'} in ${list.length} feature${list.length === 1 ? '' : 's'}${state.selected.size ? ` · ${state.selected.size} selected` : ''}`;
  const root = $('#featureList');
  root.replaceChildren(...list.slice(0, state.shown).map(({f, cases}) => featureNode(f, cases)));
  if (!list.length) root.append(h('p', {class: 'empty', text: 'No cases match these filters.'}));
  $('#moreFeatures').hidden = list.length <= state.shown;
  $('#runSelected').textContent = `Run selected${state.selected.size ? ` (${state.selected.size})` : ''}`;
  renderLive();
}
$('#moreFeatures').addEventListener('click', () => { state.shown += PAGE; renderCases(); });

function featureNode(f, cases) {
  const counts = {};
  for (const k of cases) counts[k.chip] = (counts[k.chip] || 0) + 1;
  const all = h('input', {type: 'checkbox', 'aria-label': `Select all ${cases.length} cases of ${f.screen}`, checked: cases.every(k => state.selected.has(k.id))});
  all.addEventListener('click', e => e.stopPropagation());
  all.addEventListener('change', () => { for (const k of cases) all.checked ? state.selected.add(k.id) : state.selected.delete(k.id); renderCases(); });
  const det = h('details', {class: 'feature', dataset: {feature: f.id}},
    h('summary', {},
      all,
      h('span', {class: 'f-title', text: f.screen}),
      h('span', {class: 'f-chips'}, CHIP_ORDER.filter(s => counts[s]).map(s => chip(s, `${CHIP[s]} ${counts[s]}`))),
      h('span', {class: 'f-meta', text: `${f.area} · ${f.id} · ${f.route || ''}`})));
  det.addEventListener('toggle', () => {
    if (det.open && !det.dataset.rendered) { det.append(featureBody(f, cases)); det.dataset.rendered = '1'; }
  }, {once: false});
  return det;
}

function featureBody(f, cases) {
  const body = h('div', {class: 'f-body'});
  const used = new Set();
  for (const c of f.controls) {
    const mine = cases.filter(k => k.id.startsWith(`${c.id}.`));
    if (!mine.length) continue;
    mine.forEach(k => used.add(k.id));
    body.append(h('div', {class: 'control'},
      h('div', {class: 'control-head'}, h('strong', {text: c.label}), h('span', {class: 'suite-badge', text: c.type}),
        c.qa_key ? h('code', {text: c.qa_key}) : null, h('span', {class: 'muted', text: c.action || ''}), c.api ? h('code', {text: c.api}) : null),
      mine.map(caseNode)));
  }
  const rest = cases.filter(k => !used.has(k.id));
  if (rest.length) body.append(h('div', {class: 'control'}, h('div', {class: 'control-head'}, h('strong', {text: f.controls.length ? 'Screen-level cases' : 'Cases'})), rest.map(caseNode)));
  return body;
}

function caseNode(k) {
  const box = h('input', {type: 'checkbox', 'aria-label': `Select ${k.id}`, checked: state.selected.has(k.id)});
  box.addEventListener('change', () => { box.checked ? state.selected.add(k.id) : state.selected.delete(k.id); $('#runSelected').textContent = `Run selected${state.selected.size ? ` (${state.selected.size})` : ''}`; renderLive(); });
  const tests = k.automated_by.map(a => h('span', {class: 't'}, h('span', {class: 'suite-badge', text: SUITE_LABEL[a.suite] || a.suite}),
    h('span', {}, `${a.file.split('/').pop()} › ${a.test}`), a.via === 'tag' ? h('span', {class: 'via-tag', title: 'the test names this case', text: 'tag'}) : null));
  if (k.automated_by_total > k.automated_by.length) tests.push(h('span', {class: 't', text: `+${k.automated_by_total - k.automated_by.length} more`}));
  const last = k.last;
  const failMsg = last?.result === 'fail' ? (last.tests || []).find(t => t.status === 'failed')?.message : null;
  return h('div', {class: 'case', dataset: {case: k.id}},
    box, chip(k.chip),
    h('span', {class: 'c-title', text: k.title}),
    h('span', {class: 'c-meta'}, `${k.type} · `, h('code', {text: k.id}), k.mapped_by ? ` · mapped by ${k.mapped_by}` : '',
      last ? ` · last ${last.result} in ${last.run} (${when(last.at)})` : '', k.manual ? ` · manual ${k.manual.result} by ${k.manual.name || k.manual.by} ${when(k.manual.at)}` : ''),
    tests.length ? h('span', {class: 'c-tests'}, tests) : null,
    failMsg ? h('span', {class: 'c-meta fail-msg', text: failMsg.split('\n').slice(0, 4).join('\n')}) : null,
    h('details', {}, h('summary', {text: 'Steps & expected'}),
      h('ol', {}, (k.steps || []).map(s => h('li', {text: s}))),
      h('div', {}, h('strong', {text: 'Expected: '}), k.expected || ''),
      h('div', {}, h('strong', {text: 'Seed: '}), (k.seed_needs || []).join(' · ')),
      k.manual_reason ? h('div', {}, h('strong', {text: 'Manual because: '}), k.manual_reason) : null,
      k.notes ? h('div', {}, h('strong', {text: 'Notes: '}), k.notes) : null));
}

let searchTimer;
$('#fSearch').addEventListener('input', e => { clearTimeout(searchTimer); searchTimer = setTimeout(() => { state.filters.q = e.target.value.trim(); state.shown = PAGE; renderCases(); }, 160); });
for (const [id, key] of [['#fArea', 'area'], ['#fStatus', 'status'], ['#fSuite', 'suite'], ['#fType', 'type']]) {
  $(id).addEventListener('change', e => { state.filters[key] = e.target.value; state.shown = PAGE; renderCases(); });
}
$('#selectVisible').addEventListener('click', () => { for (const {cases} of filtered()) for (const k of cases) state.selected.add(k.id); renderCases(); });
$('#clearSelection').addEventListener('click', () => { state.selected.clear(); renderCases(); });
$('#runSelected').addEventListener('click', () => startRun({mode: 'cases', cases: [...state.selected]}));
$('#runArea').addEventListener('click', () => state.filters.area && startRun({mode: 'area', areas: [state.filters.area]}));

// ------------------------------------------------------------------ runs
function renderRuns() {
  const t = $('#runTable');
  if (!state.runs.length) { t.replaceChildren(h('tbody', {}, h('tr', {}, h('td', {class: 'empty', text: 'No runs yet. Start one from Overview.'})))); return; }
  t.replaceChildren(
    h('thead', {}, h('tr', {}, ['Started', 'By', 'Mode', 'Suites', 'Status', 'Tests', 'Cases pass/fail', 'Verified', 'Took'].map(x => h('th', {text: x})))),
    h('tbody', {}, state.runs.map(r => {
      const tr = h('tr', {tabindex: '0', dataset: {run: r.id}, class: state.runDetail === r.id ? 'selected' : ''},
        h('td', {text: when(r.startedAt)}), h('td', {text: r.by}), h('td', {text: r.mode}), h('td', {text: (r.suites || []).map(s => SUITE_LABEL[s] || s).join(', ')}),
        h('td', {}, chip(r.status === 'passed' ? 'pass' : r.status === 'failed' ? 'fail' : r.status, r.status)),
        h('td', {text: r.tests ? `${r.tests.passed} ✓ ${r.tests.failed} ✗` : '—'}),
        h('td', {text: r.cases ? `${r.cases.pass} / ${r.cases.fail}` : '—'}),
        h('td', {text: r.coverage ? pct(r.coverage.verifiedPct) : '—'}), h('td', {text: dur(r.startedAt, r.finishedAt)}));
      const open = () => showRun(r.id);
      tr.addEventListener('click', open);
      tr.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(); } });
      return tr;
    })),
  );
}

async function showRun(id) {
  state.runDetail = id;
  renderRuns();
  const box = $('#runDetail');
  box.hidden = false;
  box.replaceChildren(h('p', {class: 'muted', text: 'Loading…'}));
  let d;
  try { d = await api(`/runs/${id}`); } catch (e) { box.replaceChildren(h('p', {class: 'error', text: e.message})); return; }
  const r = d.run;
  const diff = d.diff || {};
  const fileLink = f => h('a', {class: 'small button', href: `/qa-lab/api/runs/${id}/files/${f}`, target: '_blank', rel: 'noopener'}, f);
  box.replaceChildren(
    h('div', {class: 'run-detail-head'}, h('h2', {}, `Run ${r.id} `, chip(r.status === 'passed' ? 'pass' : r.status === 'failed' ? 'fail' : r.status, r.status)),
      h('span', {class: 'actions'}, h('a', {class: 'small button', href: `/qa-lab/api/runs/${id}/report.md`, download: true}, 'Report (Markdown)'),
        h('a', {class: 'small button', href: `/qa-lab/api/runs/${id}/report.json`, download: true}, 'Report (JSON)'))),
    h('p', {class: 'small muted', text: `${r.mode} · by ${r.by} · ${when(r.startedAt)} · ${dur(r.startedAt, r.finishedAt)}${r.request?.cases ? ` · ${r.request.cases.length} cases selected` : ''}`}),
    h('div', {class: 'table-wrap'}, h('table', {class: 'data'},
      h('thead', {}, h('tr', {}, ['Step', 'Status', 'Passed', 'Failed', 'Skipped', 'Detail'].map(x => h('th', {text: x})))),
      h('tbody', {}, r.steps.map(s => h('tr', {}, h('td', {text: SUITE_LABEL[s.name] || s.name}), h('td', {}, chip(s.status === 'passed' ? 'pass' : s.status === 'failed' ? 'fail' : s.status, s.status)),
        h('td', {class: 'num', text: s.counts?.passed ?? ''}), h('td', {class: 'num', text: s.counts?.failed ?? ''}), h('td', {class: 'num', text: s.counts?.skipped ?? ''}),
        h('td', {class: 'small', text: s.detail || ''})))))),
    h('h3', {text: `Diff vs previous run${diff.against ? ` (${diff.against})` : ''}`}),
    h('div', {class: 'diff'}, ['regressed', 'fixed', 'newlyFailing', 'newlyPassing', 'noLongerRun'].map(k => h('div', {class: 'k'}, h('strong', {text: (diff[k] || []).length}), k.replace(/([A-Z])/g, ' $1').toLowerCase()))),
    ...['regressed', 'newlyFailing', 'fixed', 'newlyPassing'].filter(k => (diff[k] || []).length).map(k => h('details', {}, h('summary', {text: `${k} (${diff[k].length})`}), h('div', {class: 'idlist', text: diff[k].join('\n')}))),
    h('h3', {text: `Failing cases (${Object.values(d.failing).filter(c => c.result === 'fail').length})`}),
    Object.keys(d.failing).length ? h('div', {class: 'idlist'}, Object.entries(d.failing).slice(0, 300).map(([cid, c]) => {
      const t = (c.tests || []).find(x => x.status === 'failed');
      return h('div', {}, `${cid}${c.unmatched ? ' (mapped test not found in this run)' : ''}${t ? `\n   ${t.suite}: ${t.file} › ${t.test}${t.message ? `\n   ${t.message.split('\n')[0].slice(0, 220)}` : ''}` : ''}`);
    })) : h('p', {class: 'muted small', text: 'None.'}),
    h('h3', {text: 'Raw output'}),
    h('div', {class: 'actions'}, (d.logs || []).map(fileLink)),
  );
}

// ------------------------------------------------------------------ manual
function renderManual() {
  const list = state.manual;
  const pass = list.filter(c => c.latest?.result === 'pass').length;
  const fail = list.filter(c => c.latest?.result === 'fail').length;
  $('#manualCount').textContent = list.length ? String(list.length - pass) : '';
  $('#manualSummary').textContent = `${list.length} manual cases · ${pass} passed · ${fail} failed · ${list.length - pass - fail} unchecked`;
  const q = $('#mSearch').value.trim().toLowerCase();
  const st = $('#mState').value;
  const shown = list.filter(c => (!q || `${c.title} ${c.id} ${c.screen} ${c.reason}`.toLowerCase().includes(q))
    && (!st || (st === 'unchecked' ? !c.latest || c.latest.result === 'unchecked' : c.latest?.result === st)));
  const root = $('#manualList');
  if (!list.length) {
    root.replaceChildren(h('div', {class: 'card empty'}, h('p', {text: 'No manual cases yet.'}),
      h('p', {class: 'small', text: 'Add {"<case_id>": "<why it cannot be automated locally>"} entries to qa/catalog/manual_cases.json; they appear here as a checklist.'})));
    return;
  }
  root.replaceChildren(...shown.slice(0, 200).map(c => {
    const note = h('input', {type: 'text', placeholder: 'Note (optional): device, build, what you saw', maxlength: '1000', 'aria-label': `Note for ${c.id}`});
    const mark = async result => {
      try {
        const r = await api(`/manual/${encodeURIComponent(c.id)}`, {method: 'POST', body: {result, note: note.value}});
        c.latest = r.latest;
        toast(`${c.id}: ${result}`);
        renderManual();
        loadCatalog().catch(() => {});
      } catch (e) { toast(e.message); }
    };
    const status = c.latest ? (c.latest.result === 'pass' ? 'manual_pass' : c.latest.result === 'fail' ? 'manual_fail' : 'manual_unchecked') : 'manual_unchecked';
    return h('div', {class: 'card manual-item', dataset: {case: c.id}},
      h('div', {class: 'head'}, chip(status), h('strong', {text: c.title})),
      h('div', {class: 'small muted'}, `${c.area} · ${c.screen} · `, h('code', {text: c.id})),
      c.reason ? h('div', {class: 'reason', text: `Manual because: ${c.reason}`}) : null,
      h('ol', {}, (c.steps || []).map(s => h('li', {text: s}))),
      h('div', {class: 'small'}, h('strong', {text: 'Expected: '}), c.expected || ''),
      c.latest ? h('div', {class: 'small muted', text: `Last: ${c.latest.result} by ${c.latest.name || c.latest.by} · ${when(c.latest.at)}${c.latest.note ? ` · “${c.latest.note}”` : ''}`}) : null,
      h('div', {class: 'marks'}, note,
        h('button', {type: 'button', class: 'small', onclick: () => mark('pass')}, 'Pass'),
        h('button', {type: 'button', class: 'small danger', onclick: () => mark('fail')}, 'Fail'),
        h('button', {type: 'button', class: 'small ghost', onclick: () => mark('unchecked')}, 'Reset')));
  }));
}
$('#mSearch').addEventListener('input', () => renderManual());
$('#mState').addEventListener('change', () => renderManual());

// ------------------------------------------------------------------ boot
(async () => {
  try {
    const r = await api('/session');
    if (!r.operator) throw new Error('signed out');
    await enter(r.operator);
  } catch {
    showSignIn();
  }
  setInterval(() => { if (state.operator && state.current?.status === 'running') renderLive(); }, 1000);
  setInterval(() => { if (state.operator) loadEnv().catch(() => {}); }, 60_000);
})();
