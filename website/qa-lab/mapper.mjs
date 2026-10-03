// QA Lab result mapper: parses each suite's machine-readable output into one
// result shape, reads the test -> case contract, and rolls results up into
// per-case outcomes, coverage and run diffs. Pure functions (no I/O) except the
// source scanners at the bottom, so it is unit-tested in mapper.test.mjs.
//
// Result shape: {suite, file, test, status: passed|failed|skipped, durationMs,
//                cases: [caseId], message?, func?, pkgDir?}
//   file is repo-relative; test is the full display name (groups included).
//
// Contract (mirrors qa/catalog/tools/case_tags.py):
//   Flutter / Playwright  "[case:<id>]" in the test or group name ("[case:a, b]" ok)
//   pytest                @pytest.mark.case("<id>", ...)  (recorded by qa/lab/qalab_pytest.py)
//   Go                    "// case: <id>" lines directly above func TestX(t *testing.T)
//                         ("// cases:", several ids per line, "// [case:<id>]" also accepted)
//   Django                "[case:<id>]" in the test method docstring, or
//                         "# case: <id>" lines directly above def test_x (or its decorators)

import {readdirSync, readFileSync, statSync} from 'node:fs';
import {join, relative, dirname, sep} from 'node:path';

export const SUITES = ['flutter', 'playwright', 'api_e2e', 'appium', 'go', 'django', 'console_smoke'];
const ID_RE = /^[A-Za-z0-9_][A-Za-z0-9_.\-]*$/;
const TAG_RE = /\[case:\s*([^\]]+?)\s*\]/g;
const COMMENT_CASE_RE = /^\s*(?:\/\/|#)\s*cases?:\s*(.+?)\s*$/;

export function splitIds(text) {
  const out = [];
  for (let part of String(text || '').trim().split(/[\s,]+/)) {
    part = part.replace(/^['"`]+|['"`]+$/g, '');
    if (part && ID_RE.test(part) && !out.includes(part)) out.push(part);
  }
  return out;
}

/** Case ids named by [case:...] tags anywhere in a (full) test name. */
export function tagsInName(name) {
  const out = [];
  for (const m of String(name || '').matchAll(TAG_RE)) {
    for (const id of splitIds(m[1])) if (!out.includes(id)) out.push(id);
  }
  return out;
}

/** Test name with its [case:...] tags removed (for display). */
export function stripTags(name) {
  return String(name || '').replace(TAG_RE, '').replace(/\s{2,}/g, ' ').trim();
}

const toPosix = p => p.split(sep).join('/');
const relTo = (root, abs) => toPosix(relative(root, abs));

// ------------------------------------------------------------------ Flutter
/** `flutter test --machine` event lines -> results. */
export function parseFlutterMachine(text, {root, appDir = 'app'} = {}) {
  const suites = new Map();
  const tests = new Map();
  const errors = new Map();
  const results = [];
  for (const line of String(text).split('\n')) {
    const t = line.trim();
    if (!t.startsWith('{')) continue;
    let ev;
    try { ev = JSON.parse(t); } catch { continue; }
    if (ev.type === 'suite' && ev.suite) suites.set(ev.suite.id, ev.suite.path);
    else if (ev.type === 'testStart' && ev.test) tests.set(ev.test.id, {...ev.test, startTime: ev.time ?? 0});
    else if (ev.type === 'error' && ev.testID != null) {
      errors.set(ev.testID, `${errors.get(ev.testID) || ''}${ev.error || ''}\n${(ev.stackTrace || '').split('\n').slice(0, 8).join('\n')}`.trim());
    } else if (ev.type === 'testDone') {
      const test = tests.get(ev.testID);
      if (!test) continue;
      const failed = ev.result !== 'success';
      if (ev.hidden && !failed) continue; // "loading <file>" pseudo-tests
      const path = suites.get(test.suiteID) || (test.url ? test.url.replace(/^file:\/\//, '') : '');
      let file = path;
      if (root && path.startsWith('/')) file = relTo(root, path);
      else if (path && !path.startsWith(appDir + '/')) file = `${appDir}/${path}`;
      const status = failed ? 'failed' : (ev.skipped ? 'skipped' : 'passed');
      results.push({
        suite: 'flutter', file, test: test.name, status,
        durationMs: Math.max(0, (ev.time || 0) - (test.startTime ?? ev.time ?? 0)),
        cases: tagsInName(test.name),
        ...(failed ? {message: (errors.get(ev.testID) || ev.result).slice(0, 3000)} : {}),
      });
    }
  }
  return results;
}

/** Streaming helper: one machine line -> short human log line (or null). */
export function flutterLogLine(state, line) {
  const t = line.trim();
  if (!t.startsWith('{')) return t ? t : null;
  let ev;
  try { ev = JSON.parse(t); } catch { return null; }
  if (ev.type === 'testStart' && ev.test) { state.names.set(ev.test.id, ev.test.name); return null; }
  if (ev.type === 'allSuites') { state.total = ev.count; return `flutter: ${ev.count} test files`; }
  if (ev.type === 'testDone') {
    if (ev.hidden && ev.result === 'success') return null;
    const name = state.names.get(ev.testID) || `#${ev.testID}`;
    if (ev.result !== 'success') { state.failed += 1; state.done += 1; return `✗ ${name}`; }
    state.done += 1;
    if (ev.skipped) { state.skipped += 1; return `- ${name} (skipped)`; }
    state.passed += 1;
    return null; // passes are counted, not logged line by line
  }
  if (ev.type === 'done') return `flutter: done (success=${ev.success})`;
  return null;
}

// ------------------------------------------------------------------ Playwright
/** Playwright JSON reporter output -> results. */
export function parsePlaywrightJson(json, {root} = {}) {
  const data = typeof json === 'string' ? JSON.parse(json) : json;
  const rootDir = data?.config?.rootDir || '';
  const results = [];
  const walk = (suite, titles, file) => {
    const f = suite.file || file;
    for (const spec of suite.specs || []) {
      for (const t of spec.tests || [{status: spec.ok ? 'expected' : 'unexpected', results: []}]) {
        const runs = t.results || [];
        let status;
        if (t.status === 'skipped' || (runs.length && runs.every(r => r.status === 'skipped'))) status = 'skipped';
        else if (t.status === 'expected' || t.status === 'flaky') status = 'passed';
        else status = 'failed';
        const name = [...titles, spec.title].filter(Boolean).join(' > ');
        const abs = f ? join(rootDir, f) : '';
        const err = runs.map(r => r.error?.message || (r.errors || []).map(e => e.message).join('\n')).filter(Boolean).join('\n');
        results.push({
          suite: 'playwright', file: root && abs ? relTo(root, abs) : f, test: name, status,
          durationMs: runs.reduce((n, r) => n + (r.duration || 0), 0), cases: tagsInName(name),
          ...(t.status === 'flaky' ? {flaky: true} : {}),
          ...(status === 'failed' ? {message: stripAnsi(err).slice(0, 3000)} : {}),
        });
      }
    }
    for (const child of suite.suites || []) walk(child, [...titles, child.title], f);
  };
  for (const top of data?.suites || []) walk(top, [], top.file);
  for (const e of data?.errors || []) {
    results.push({suite: 'playwright', file: e.location?.file ? (root ? relTo(root, e.location.file) : e.location.file) : 'website/tests',
      test: '(global error)', status: 'failed', durationMs: 0, cases: [], message: stripAnsi(e.message || '').slice(0, 3000)});
  }
  return results;
}

export function stripAnsi(s) {
  // eslint-disable-next-line no-control-regex
  return String(s || '').replace(/\u001b\[[0-9;]*[A-Za-z]/g, '');
}

// ------------------------------------------------------------------ pytest
/** qa/lab/qalab_pytest.py JSON lines -> results. suiteDir is repo-relative. */
export function parsePytestJsonl(text, {suite, suiteDir}) {
  const results = [];
  for (const line of String(text).split('\n')) {
    if (!line.trim().startsWith('{')) continue;
    let r;
    try { r = JSON.parse(line); } catch { continue; }
    const status = r.outcome === 'passed' ? 'passed' : (r.outcome === 'skipped' ? 'skipped' : 'failed');
    const func = String(r.test || '').split('::').pop().replace(/\[.*$/, '');
    results.push({
      suite, file: `${suiteDir}/${r.file}`, test: r.test, nodeid: r.nodeid, func, status,
      durationMs: Math.round((r.duration || 0) * 1000), cases: splitIds((r.cases || []).join(' ')),
      ...(status === 'failed' ? {message: String(r.message || '').slice(0, 3000)} : {}),
    });
  }
  return results;
}

// ------------------------------------------------------------------ Go
/** `go test -json` lines -> top-level test results. caseIndex: "<pkgDir>::<Test>" -> {file, cases}. */
export function parseGoJson(text, {modulePath, moduleDir = 'backend', caseIndex = new Map()} = {}) {
  const out = new Map();
  const output = new Map();
  const pkgFail = new Map();
  const pkgDir = pkg => (modulePath && pkg.startsWith(modulePath) ? `${moduleDir}${pkg.slice(modulePath.length)}` : pkg);
  for (const line of String(text).split('\n')) {
    if (!line.startsWith('{')) continue;
    let ev;
    try { ev = JSON.parse(line); } catch { continue; }
    const top = ev.Test ? ev.Test.split('/')[0] : null;
    const key = `${ev.Package}::${top}`;
    if (ev.Action === 'output') {
      const k = top ? key : `${ev.Package}::`;
      const buf = output.get(k) || [];
      buf.push(ev.Output);
      if (buf.length > 60) buf.shift();
      output.set(k, buf);
      continue;
    }
    if (!['pass', 'fail', 'skip'].includes(ev.Action)) continue;
    if (!ev.Test) {
      if (ev.Action === 'fail') pkgFail.set(ev.Package, true);
      continue;
    }
    if (ev.Test.includes('/')) continue; // subtests roll up into their parent
    const dir = pkgDir(ev.Package);
    const idx = caseIndex.get(`${dir}::${ev.Test}`);
    out.set(key, {
      suite: 'go', file: idx?.file || dir, pkgDir: dir, test: ev.Test,
      status: ev.Action === 'pass' ? 'passed' : (ev.Action === 'skip' ? 'skipped' : 'failed'),
      durationMs: Math.round((ev.Elapsed || 0) * 1000), cases: idx?.cases || [],
      ...(ev.Action === 'fail' ? {message: (output.get(key) || []).join('').slice(-3000)} : {}),
    });
  }
  const results = [...out.values()];
  for (const [pkg] of pkgFail) {
    const dir = pkgDir(pkg);
    if (!results.some(r => r.pkgDir === dir && r.status === 'failed')) {
      results.push({suite: 'go', file: dir, pkgDir: dir, test: '(package)', status: 'failed', durationMs: 0, cases: [],
        message: (output.get(`${pkg}::`) || []).join('').slice(-3000)});
    }
  }
  return results;
}

// ------------------------------------------------------------------ Django
const DJ_HEAD = /^(test\w*) \(([\w.]+)\)(.*)$/;
const DJ_OUTCOME = /(?:^|\s)\.\.\. (ok|FAIL|ERROR|skipped\b.*|expected failure|unexpected success)\s*$/;

/** `manage.py test -v 2` output -> results. caseIndex: "<file>::<Class.method>" -> cases. */
export function parseDjangoVerbose(text, {projectDir = 'control-panel', caseIndex = new Map()} = {}) {
  const results = [];
  const byLabel = new Map();
  let pending = null;
  const lines = String(text).split('\n');
  const record = (method, label, outcome) => {
    let mod = label;
    let cls = '';
    const parts = label.split('.');
    if (parts[parts.length - 1] === method) parts.pop();
    cls = parts.pop() || '';
    mod = parts.join('.');
    const file = `${projectDir}/${mod.replace(/\./g, '/')}.py`;
    const test = cls ? `${cls}.${method}` : method;
    const status = outcome === 'ok' || outcome === 'unexpected success' ? 'passed'
      : (outcome.startsWith('skipped') || outcome === 'expected failure' ? 'skipped' : 'failed');
    const r = {suite: 'django', file, test, func: method, status, durationMs: 0, cases: caseIndex.get(`${file}::${test}`) || [], label: `${mod}.${test}`};
    results.push(r);
    byLabel.set(r.label, r);
  };
  for (const line of lines) {
    const h = line.match(DJ_HEAD);
    if (h) {
      const o = h[3].match(DJ_OUTCOME);
      if (o) { record(h[1], h[2], o[1]); pending = null; } else pending = [h[1], h[2]];
      continue;
    }
    if (pending) {
      const o = line.match(DJ_OUTCOME);
      if (o) { record(pending[0], pending[1], o[1]); pending = null; }
    }
  }
  // failure tracebacks: "FAIL: test_x (mod.Class.test_x)" ... until the next ===== / -----\nRan
  const blocks = String(text).split(/^={10,}$/m);
  for (const b of blocks) {
    const m = b.match(/^\s*(?:FAIL|ERROR): (test\w*) \(([\w.]+)\)/);
    if (!m) continue;
    const parts = m[2].split('.');
    if (parts[parts.length - 1] !== m[1]) parts.push(m[1]);
    const r = byLabel.get(parts.join('.'));
    if (r) r.message = b.split(/^-{10,}\s*\nRan /m)[0].trim().slice(-3000);
  }
  return results;
}

// ------------------------------------------------------------------ source scanners (Go / Django comments)
export function goCaseComments(src) {
  const lines = String(src).split('\n');
  const out = [];
  lines.forEach((line, i) => {
    const m = line.match(/^func\s+(Test\w*)\s*\(\s*\w+\s+\*testing\.T\s*\)/);
    if (!m) return;
    let ids = [];
    for (let j = i - 1; j >= 0 && lines[j].trimStart().startsWith('//'); j -= 1) {
      const c = lines[j].match(COMMENT_CASE_RE);
      ids = [...(c ? splitIds(c[1]) : tagsInName(lines[j])), ...ids];
    }
    out.push({test: m[1], cases: [...new Set(ids)], line: i + 1});
  });
  return out;
}

export function djangoCaseComments(src) {
  const lines = String(src).split('\n');
  const out = [];
  let classes = [];
  lines.forEach((line, i) => {
    const c = line.match(/^(\s*)class (\w+)\s*[(:]/);
    if (c) { classes = [...classes.filter(k => k.ind < c[1].length), {ind: c[1].length, name: c[2]}]; return; }
    const d = line.match(/^(\s*)(?:async\s+)?def (test\w*)\s*\(/);
    if (!d) return;
    const owner = classes.filter(k => k.ind < d[1].length);
    let ids = [];
    for (let j = i - 1; j >= 0 && /^\s*[#@]/.test(lines[j]); j -= 1) {
      const m = lines[j].match(COMMENT_CASE_RE);
      if (m) ids = [...splitIds(m[1]), ...ids];
    }
    ids = [...ids, ...tagsInName(docstringAfter(lines, i))];
    out.push({test: (owner.length ? `${owner[owner.length - 1].name}.` : '') + d[2], cases: [...new Set(ids)], line: i + 1});
  });
  return out;
}

/** The docstring of the def starting at line i ('' when there is none), whitespace-collapsed. */
function docstringAfter(lines, i) {
  let j = i;
  // signature may span lines: skip to the line that ends with ':' (outside the parens)
  let depth = 0;
  for (; j < lines.length; j += 1) {
    for (const ch of lines[j].replace(/#.*$/, '')) { if (ch === '(') depth += 1; else if (ch === ')') depth -= 1; }
    if (depth <= 0 && /:\s*(#.*)?$/.test(lines[j])) break;
  }
  for (j += 1; j < lines.length && !lines[j].trim(); j += 1);
  if (j >= lines.length) return '';
  const first = lines[j].trim().match(/^[rRuU]?("""|'''|"|')/);
  if (!first) return '';
  const q = first[1];
  let text = lines[j].trim().slice(first[0].length);
  if (text.includes(q)) return text.slice(0, text.indexOf(q)).replace(/\s+/g, ' ');
  if (q.length === 1) return '';
  for (j += 1; j < lines.length; j += 1) {
    const k = lines[j].indexOf(q);
    if (k >= 0) { text += ' ' + lines[j].slice(0, k); break; }
    text += ' ' + lines[j];
  }
  return text.replace(/\s+/g, ' ');
}

function walkFiles(dir, pred, out = [], skip = /(^|\/)(node_modules|\.venv|venv|vendor|\.git|\.dart_tool|build|site-packages|__pycache__)$/) {
  let entries;
  try { entries = readdirSync(dir, {withFileTypes: true}); } catch { return out; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) { if (!skip.test(p)) walkFiles(p, pred, out, skip); }
    else if (pred(p)) out.push(p);
  }
  return out;
}

/** "<pkgDir>::<TestName>" -> {file, cases} for every Go test (tagged or not). */
export function goCaseIndex(root, moduleDir = 'backend') {
  const idx = new Map();
  for (const f of walkFiles(join(root, moduleDir), p => p.endsWith('_test.go'))) {
    const rel = relTo(root, f);
    for (const t of goCaseComments(readFileSync(f, 'utf8'))) idx.set(`${toPosix(dirname(rel))}::${t.test}`, {file: rel, cases: t.cases});
  }
  return idx;
}

/** "<file>::<Class.method>" -> cases for Django tests that carry comment tags. */
export function djangoCaseIndex(root, projectDir = 'control-panel') {
  const idx = new Map();
  for (const f of walkFiles(join(root, projectDir), p => p.endsWith('.py') && (/\/tests?\//.test(p) || /\/test_[^/]*\.py$/.test(p)))) {
    const rel = relTo(root, f);
    for (const t of djangoCaseComments(readFileSync(f, 'utf8'))) if (t.cases.length) idx.set(`${rel}::${t.test}`, t.cases);
  }
  return idx;
}

export function goModulePath(root, moduleDir = 'backend') {
  try {
    const m = readFileSync(join(root, moduleDir, 'go.mod'), 'utf8').match(/^module\s+(\S+)/m);
    return m ? m[1] : null;
  } catch { return null; }
}

// ------------------------------------------------------------------ mapping
export function refSuite(ref) {
  if (String(ref.file || '').startsWith('qa/console_smoke/')) return 'console_smoke';
  return ref.suite;
}

function unescapeSource(s) { return String(s).replace(/\\(.)/g, '$1'); }

/** Static (source) test name -> RegExp source; $var / ${expr} become wildcards. */
export function namePattern(staticName) {
  const s = unescapeSource(staticName);
  let out = '';
  let i = 0;
  while (i < s.length) {
    if (s[i] === '$' && s[i + 1] === '{') {
      let depth = 0; let j = i + 1;
      for (; j < s.length; j += 1) { if (s[j] === '{') depth += 1; else if (s[j] === '}') { depth -= 1; if (!depth) break; } }
      out += '.+?'; i = j + 1; continue;
    }
    if (s[i] === '$' && /[A-Za-z_]/.test(s[i + 1] || '')) {
      let j = i + 1;
      while (j < s.length && /[\w]/.test(s[j])) j += 1;
      out += '.+?'; i = j; continue;
    }
    out += s[i].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    i += 1;
  }
  return out;
}

const patternCache = new Map();
function compiled(src, mode) {
  const k = `${mode}|${src}`;
  let re = patternCache.get(k);
  if (!re) {
    const body = namePattern(src);
    re = mode === 'full' ? new RegExp(`^${body}$`) : new RegExp(`(?:^|\\s|> )${body}$`);
    patternCache.set(k, re);
  }
  return re;
}

/** Does a catalog automated_by ref point at this runtime result? */
export function refMatches(ref, r) {
  const suite = refSuite(ref);
  if (suite !== r.suite) return false;
  const name = stripTags(r.test);
  switch (suite) {
    case 'flutter': {
      if (ref.file !== r.file) return false;
      const full = String(ref.test).split(' > ').join(' ');
      const last = String(ref.test).split(' > ').pop();
      return compiled(full, 'full').test(name) || compiled(last, 'end').test(name);
    }
    case 'playwright': {
      if (ref.file !== r.file) return false;
      return compiled(String(ref.test), 'full').test(name) || compiled(String(ref.test), 'end').test(name)
        || compiled(stripTags(ref.test), 'end').test(name);
    }
    case 'api_e2e': case 'appium': case 'console_smoke':
      return ref.file === r.file && (r.func === ref.test || r.test === ref.test);
    case 'go':
      return (r.pkgDir === dirname(ref.file) || r.file === ref.file) && r.test === ref.test;
    case 'django':
      return ref.file === r.file && (r.func === ref.test || r.test === ref.test || r.test.endsWith(`.${ref.test}`));
    default:
      return false;
  }
}

const brief = r => ({suite: r.suite, file: r.file, test: r.test, status: r.status, ...(r.message ? {message: r.message.slice(0, 600)} : {})});

/**
 * Per-case outcome for one run.
 *   result: pass | fail | skipped | not_run   (automated cases)
 *           manual                            (manual_cases.json)
 *           not_automated | presence_only | partial (catalog status, no tag seen)
 */
export function evaluateCases(catalog, results, {suitesRun = null} = {}) {
  const byFile = new Map();
  const tagIdx = new Map();
  for (const r of results) {
    const k = `${r.suite}|${r.suite === 'go' ? r.pkgDir : r.file}`;
    if (!byFile.has(k)) byFile.set(k, []);
    byFile.get(k).push(r);
    for (const id of r.cases || []) {
      if (!tagIdx.has(id)) tagIdx.set(id, []);
      tagIdx.get(id).push(r);
    }
  }
  const candidates = ref => {
    const suite = refSuite(ref);
    const k = `${suite}|${suite === 'go' ? dirname(ref.file) : ref.file}`;
    return byFile.get(k) || [];
  };
  const out = {};
  const known = new Set();
  for (const f of catalog.features || []) {
    for (const c of f.cases || []) {
      known.add(c.id);
      const tagged = tagIdx.get(c.id) || [];
      const staticAuto = c.status === 'automated';
      const refs = c.automated_by || [];
      const matched = new Set(tagged);
      for (const ref of refs) for (const r of candidates(ref)) if (refMatches(ref, r)) matched.add(r);
      const tests = [...matched];
      const entry = {feature: f.id, area: f.area};
      if (tagged.length || staticAuto) {
        entry.automated = true;
        entry.via = tagged.length ? 'tag' : (c.mapped_by || 'heuristic');
        if (!tests.length) {
          entry.result = 'not_run';
          const suites = new Set(refs.map(refSuite));
          if (suitesRun && [...suites].some(s => suitesRun.has(s))) entry.unmatched = true;
        } else if (tests.some(t => t.status === 'failed')) entry.result = 'fail';
        else if (tests.every(t => t.status === 'skipped')) entry.result = 'skipped';
        else entry.result = 'pass';
      } else if (c.status === 'manual') {
        entry.result = 'manual';
      } else {
        entry.result = c.status || 'not_automated';
      }
      entry.tests = tests.slice(0, 8).map(brief);
      if (tests.length > 8) entry.testsTotal = tests.length;
      out[c.id] = entry;
    }
  }
  const unknownTags = [...tagIdx.keys()].filter(id => !known.has(id)).sort();
  return {cases: out, unknownTags};
}

// ------------------------------------------------------------------ ledger + coverage
/** Latest executed result per case, carried across runs (partial runs only update what they ran). */
export function mergeLedger(ledger, runCases, {runId, at}) {
  const next = {...(ledger || {})};
  for (const [id, e] of Object.entries(runCases)) {
    if (!['pass', 'fail', 'skipped'].includes(e.result)) continue;
    next[id] = {result: e.result, via: e.via, run: runId, at, tests: (e.tests || []).slice(0, 4)};
  }
  return next;
}

/** Latest manual mark per case from the append-only history {id: [{result, by, at, note}]}. */
export function latestManual(history) {
  const out = {};
  for (const [id, marks] of Object.entries(history || {})) {
    if (Array.isArray(marks) && marks.length) out[id] = marks[marks.length - 1];
  }
  return out;
}

/** Effective chip for a case given catalog status, ledger entry and manual mark. */
export function effectiveStatus(c, led, mark) {
  const automated = c.status === 'automated' || led?.via === 'tag';
  if (automated) {
    if (!led) return 'not_run';
    return led.result === 'pass' ? 'pass' : (led.result === 'fail' ? 'fail' : 'skipped');
  }
  if (c.status === 'manual') {
    if (!mark || mark.result === 'unchecked') return 'manual_unchecked';
    return mark.result === 'pass' ? 'manual_pass' : 'manual_fail';
  }
  return c.status || 'not_automated';
}

function suitesOf(c, led) {
  const s = new Set((c.automated_by || []).map(refSuite));
  for (const t of led?.tests || []) s.add(t.suite);
  return s;
}

/**
 * Coverage over the whole catalog.
 *   automated            catalog says automated (tag or heuristic) or a run saw its tag
 *   automatedOrManual    automated + manual cases a person checked as pass
 *   verified (gate)      automated AND latest result pass, or manual AND checked pass
 */
export function coverage(catalog, ledger = {}, manualMarks = {}) {
  const blank = () => ({total: 0, automated: 0, passing: 0, failing: 0, notRun: 0, manual: 0, manualChecked: 0, manualFailed: 0,
    presenceOnly: 0, partial: 0, notAutomated: 0, verified: 0});
  const all = blank();
  const byArea = {};
  const bySuite = {};
  const chips = {};
  for (const f of catalog.features || []) {
    for (const c of f.cases || []) {
      const led = ledger[c.id];
      const chip = effectiveStatus(c, led, manualMarks[c.id]);
      chips[c.id] = chip;
      const buckets = [all, byArea[f.area] ||= blank()];
      for (const s of suitesOf(c, led)) buckets.push(bySuite[s] ||= blank());
      for (const b of buckets) {
        b.total += 1;
        if (['pass', 'fail', 'skipped', 'not_run'].includes(chip)) b.automated += 1;
        if (chip === 'pass') { b.passing += 1; b.verified += 1; }
        if (chip === 'fail') b.failing += 1;
        if (chip === 'not_run' || chip === 'skipped') b.notRun += 1;
        if (chip.startsWith('manual')) b.manual += 1;
        if (chip === 'manual_pass') { b.manualChecked += 1; b.verified += 1; }
        if (chip === 'manual_fail') b.manualFailed += 1;
        if (chip === 'presence_only') b.presenceOnly += 1;
        if (chip === 'partial') b.partial += 1;
        if (chip === 'not_automated') b.notAutomated += 1;
      }
    }
  }
  const pct = b => ({
    ...b,
    automatedPct: b.total ? round1(100 * b.automated / b.total) : 0,
    automatedOrManualPct: b.total ? round1(100 * (b.automated + b.manualChecked) / b.total) : 0,
    verifiedPct: b.total ? round1(100 * b.verified / b.total) : 0,
  });
  return {
    all: pct(all),
    byArea: Object.fromEntries(Object.entries(byArea).sort().map(([k, v]) => [k, pct(v)])),
    bySuite: Object.fromEntries(Object.entries(bySuite).sort().map(([k, v]) => [k, pct(v)])),
    chips,
  };
}

function round1(n) { return Math.round(n * 10) / 10; }

/** Case-level diff between two runs' case maps. */
export function diffRuns(prevCases = {}, curCases = {}) {
  const out = {fixed: [], regressed: [], newlyPassing: [], newlyFailing: [], noLongerRun: []};
  for (const [id, cur] of Object.entries(curCases)) {
    const prev = prevCases[id]?.result;
    const now = cur.result;
    if (prev === now) continue;
    if (prev === 'fail' && now === 'pass') out.fixed.push(id);
    else if (prev === 'pass' && now === 'fail') out.regressed.push(id);
    else if (now === 'pass') out.newlyPassing.push(id);
    else if (now === 'fail') out.newlyFailing.push(id);
    else if ((prev === 'pass' || prev === 'fail') && now === 'not_run') out.noLongerRun.push(id);
  }
  for (const k of Object.keys(out)) out[k].sort();
  return out;
}

/** Which tests to run for a set of case ids: {suite: {files:Set, names:Set, nodeids:Set, packages:Set, labels:Set}}. */
export function selectionForCases(catalog, caseIds, ledger = {}) {
  const want = new Set(caseIds);
  const sel = {};
  const add = (suite, k, v) => { ((sel[suite] ||= {files: new Set(), names: new Set(), nodeids: new Set(), packages: new Set(), labels: new Set()})[k]).add(v); };
  for (const f of catalog.features || []) {
    for (const c of f.cases || []) {
      if (!want.has(c.id)) continue;
      const refs = [...(c.automated_by || []), ...((ledger[c.id]?.tests) || [])];
      for (const ref of refs) {
        const s = refSuite(ref);
        if (s === 'flutter' || s === 'playwright') { add(s, 'files', ref.file); add(s, 'names', ref.test); }
        else if (s === 'api_e2e' || s === 'appium' || s === 'console_smoke') { add(s, 'files', ref.file); if (ref.nodeid) add(s, 'nodeids', ref.nodeid); add(s, 'names', ref.test); }
        else if (s === 'go') { add(s, 'packages', dirname(ref.file)); add(s, 'names', String(ref.test).split('/')[0]); }
        else if (s === 'django') { add(s, 'files', ref.file); add(s, 'names', ref.test); }
      }
    }
  }
  return sel;
}

export function isFile(p) { try { return statSync(p).isFile(); } catch { return false; } }
