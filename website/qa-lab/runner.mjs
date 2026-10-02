// QA Lab: runs the catalog's test cases against seeded data and reports
// coverage. Mounted by website/server.mjs only when QA_LAB=1 (and never when
// NODE_ENV=production); every request must come from loopback, and every API
// call except sign-in needs an operator session (admin / ops_admin, checked
// against the BFF's own role list).
//
// Layout on disk (QA_LAB_RESULTS_DIR, default qa/results/qa_lab):
//   runs/<id>/run.json          status, steps, per-suite counts, summary
//   runs/<id>/cases.json        per-case outcome for this run
//   runs/<id>/results.json      every test result (all suites, normalised)
//   runs/<id>/diff.json         case diff vs the previous run
//   runs/<id>/<suite>.log       raw output (flutter.jsonl / playwright.json / *.jsonl too)
//   runs/index.json             run history
//   ledger.json                 latest executed result per case (partial runs update what they ran)
//   manual_checks.json          append-only manual checklist marks {case: [{result, note, by, at}]}
//   seed_manifest.json          written by qa/seed/seed_dataset.py

import {spawn, execFileSync} from 'node:child_process';
import {randomBytes} from 'node:crypto';
import {createReadStream, existsSync, mkdirSync, readFileSync, readdirSync, renameSync, statSync, writeFileSync, appendFileSync} from 'node:fs';
import http from 'node:http';
import net from 'node:net';
import {dirname, extname, join, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import * as M from './mapper.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const LOOPBACK = new Set(['127.0.0.1', '::1', '::ffff:127.0.0.1']);
const MIME = {'.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png'};
const SUITE_LABELS = {flutter: 'Flutter', playwright: 'Playwright', api_e2e: 'API e2e', appium: 'Appium', go: 'Go', django: 'Django', console_smoke: 'Console smoke'};
const DEFAULT_TIMEOUT_MIN = {flutter: 60, playwright: 60, api_e2e: 30, appium: 120, go: 30, django: 20, console_smoke: 15, seed: 10, rescan: 5};

export function qaLabEnabled(env = process.env) {
  return env.QA_LAB === '1' && env.NODE_ENV !== 'production';
}

export function isLoopback(req) {
  return LOOPBACK.has(String(req.socket?.remoteAddress || ''));
}

const readJSON = (p, fallback) => { try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return fallback; } };
function writeJSON(p, data) {
  mkdirSync(dirname(p), {recursive: true});
  const tmp = `${p}.${process.pid}.tmp`;
  writeFileSync(tmp, JSON.stringify(data, null, 1));
  renameSync(tmp, p);
}
const nowIso = () => new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
const newRunId = () => `${new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, '').replace('T', '-')}-${randomBytes(2).toString('hex')}`;

function which(cmd) {
  for (const d of String(process.env.PATH || '').split(':')) {
    const p = join(d, cmd);
    try { if (statSync(p).isFile()) return p; } catch { /* keep looking */ }
  }
  return null;
}

function probeHttp(url, timeoutMs = 2500) {
  return new Promise(res => {
    let u;
    try { u = new URL(url); } catch { res(false); return; }
    const req = http.get({hostname: u.hostname, port: u.port, path: `${u.pathname}${u.search}`, timeout: timeoutMs}, r => { r.resume(); res(r.statusCode > 0 && r.statusCode < 500); });
    req.on('timeout', () => { req.destroy(); res(false); });
    req.on('error', () => res(false));
  });
}

function probeTcp(host, port, timeoutMs = 1500) {
  return new Promise(res => {
    const s = net.connect({host, port});
    const done = ok => { s.destroy(); res(ok); };
    s.setTimeout(timeoutMs, () => done(false));
    s.on('connect', () => done(true));
    s.on('error', () => done(false));
  });
}

function upstreamJSON(upstream, method, path, {body, token} = {}) {
  return new Promise(res => {
    const payload = body === undefined ? null : Buffer.from(JSON.stringify(body));
    const headers = {Accept: 'application/json', 'X-Client-Platform': 'qa-lab'};
    if (payload) { headers['Content-Type'] = 'application/json'; headers['Content-Length'] = payload.length; }
    if (token) headers.Authorization = `Bearer ${token}`;
    const req = http.request(upstream, {method, path, headers, timeout: 15000}, r => {
      const chunks = [];
      r.on('data', c => chunks.push(c));
      r.on('end', () => {
        let data = null;
        try { data = JSON.parse(Buffer.concat(chunks).toString('utf8') || 'null'); } catch { data = null; }
        res({status: r.statusCode, data});
      });
    });
    req.on('timeout', () => req.destroy(new Error('timeout')));
    req.on('error', () => res({status: 0, data: null}));
    if (payload) req.write(payload);
    req.end();
  });
}

export function createQaLab({root, upstream, env = process.env, log = console} = {}) {
  if (!qaLabEnabled(env)) throw new Error('QA Lab is disabled (QA_LAB=1 required, never in production)');
  root = resolve(root || join(here, '..', '..'));
  const cfg = {
    root,
    upstream: upstream instanceof URL ? upstream : new URL(upstream || env.CONNECT_API_UPSTREAM || 'http://127.0.0.1:18080'),
    results: resolve(env.QA_LAB_RESULTS_DIR || join(root, 'qa', 'results', 'qa_lab')),
    catalog: resolve(env.QA_LAB_CATALOG || join(root, 'qa', 'catalog', 'feature_catalog.json')),
    manualCases: resolve(env.QA_LAB_MANUAL_CASES || join(root, 'qa', 'catalog', 'manual_cases.json')),
    python: existsSync(join(root, '.venv', 'bin', 'python')) ? join(root, '.venv', 'bin', 'python') : 'python3',
    djangoPython: join(root, 'control-panel', '.venv', 'bin', 'python'),
    roles: new Set(String(env.QA_LAB_ROLES || 'admin,ops_admin').split(',').map(s => s.trim()).filter(Boolean)),
    goDb: env.PROFILE_TEST_DATABASE_URL || 'postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable',
    appiumDevice: env.QA_LAB_APPIUM_DEVICE || 'emulator-5556',
    appiumUrl: env.APPIUM_SERVER_URL || 'http://127.0.0.1:4723',
    consoleUrl: env.CONSOLE_BASE_URL || 'http://127.0.0.1:8765',
    websiteUrl: env.QA_LAB_WEBSITE_URL || 'http://127.0.0.1:4190',
    selftest: env.QA_LAB_SELFTEST === '1',
  };
  if (/:55432\b/.test(cfg.goDb)) throw new Error('refusing PROFILE_TEST_DATABASE_URL on port 55432 (another project\'s database)');
  const runsDir = join(cfg.results, 'runs');
  const ledgerPath = join(cfg.results, 'ledger.json');
  const manualPath = join(cfg.results, 'manual_checks.json');
  const indexPath = join(runsDir, 'index.json');
  mkdirSync(runsDir, {recursive: true});

  const sessions = new Map();
  const failedLogins = [];
  const clients = new Set();
  let current = null; // {run, child, cancelled, logTail}
  let catalogCache = {mtime: 0, data: null};

  // ---------------------------------------------------------------- data
  function catalog() {
    let mtime = 0;
    try { mtime = statSync(cfg.catalog).mtimeMs; } catch { return {features: [], stats: {}}; }
    if (mtime !== catalogCache.mtime) catalogCache = {mtime, data: readJSON(cfg.catalog, {features: [], stats: {}})};
    return catalogCache.data;
  }
  const ledger = () => readJSON(ledgerPath, {});
  const manualHistory = () => readJSON(manualPath, {});
  const runIndex = () => readJSON(indexPath, []);
  function manualCaseMap() {
    const raw = readJSON(cfg.manualCases, {});
    const out = {};
    for (const [k, v] of Object.entries(raw || {})) if (!k.startsWith('_')) out[k] = typeof v === 'string' ? v : (v?.reason || '');
    for (const f of catalog().features || []) for (const c of f.cases || []) if (c.status === 'manual' && !(c.id in out)) out[c.id] = c.manual_reason || '';
    return out;
  }
  /** Catalog with manual_cases.json applied even before the catalog is regenerated. */
  function effectiveCatalog() {
    const cat = catalog();
    const manual = manualCaseMap();
    const features = (cat.features || []).map(f => ({...f, cases: (f.cases || []).map(c => (
      c.id in manual && c.status !== 'automated' && c.status !== 'manual' ? {...c, status: 'manual', manual_reason: manual[c.id]} : c))}));
    return {...cat, features};
  }

  // ---------------------------------------------------------------- broadcast
  function send(type, data) {
    const msg = `event: ${type}\ndata: ${JSON.stringify(data)}\n\n`;
    for (const res of clients) { try { res.write(msg); } catch { clients.delete(res); } }
  }
  let pendingLines = [];
  let flushTimer = null;
  function logLine(line) {
    if (!current) return;
    const t = M.stripAnsi(String(line)).replace(/\s+$/, '');
    if (!t) return;
    current.logTail.push(t);
    if (current.logTail.length > 400) current.logTail.splice(0, current.logTail.length - 400);
    pendingLines.push(t);
    if (!flushTimer) flushTimer = setTimeout(() => { flushTimer = null; const lines = pendingLines; pendingLines = []; send('log', {run: current?.run.id, lines}); }, 250);
  }
  function publish() {
    if (!current) return;
    writeJSON(join(runsDir, current.run.id, 'run.json'), current.run);
    send('run', current.run);
  }

  // ---------------------------------------------------------------- environment
  async function environment() {
    const adbDevices = (() => {
      const adb = which('adb') || join(env.HOME || '', 'Library/Android/sdk/platform-tools/adb');
      try { return execFileSync(adb, ['devices'], {encoding: 'utf8', timeout: 4000}); } catch { return ''; }
    })();
    const [gateway, website, pg, appium, consoleUp] = await Promise.all([
      probeHttp(new URL('/healthz', cfg.upstream).href), probeHttp(`${cfg.websiteUrl}/healthz`),
      probeTcp('127.0.0.1', Number(new URL(cfg.goDb.replace(/^postgresql:/, 'http:')).port || 5432)),
      probeHttp(`${cfg.appiumUrl}/status`), probeHttp(`${cfg.consoleUrl}/login/`)]);
    const has = p => existsSync(join(root, p));
    const suites = {
      flutter: which('flutter') && has('app/pubspec.yaml') ? null : 'flutter is not on PATH',
      playwright: !has('website/node_modules/@playwright/test') ? 'run npm install in website/' : (!website ? `website not answering at ${cfg.websiteUrl}` : null),
      api_e2e: !gateway ? `API gateway not answering at ${cfg.upstream.origin}` : (existsSync(cfg.python) || cfg.python === 'python3' ? null : 'no .venv python'),
      appium: !new RegExp(`^${cfg.appiumDevice}\\s+device`, 'm').test(adbDevices) ? `${cfg.appiumDevice} is not attached (adb devices)` : (!appium ? `Appium not answering at ${cfg.appiumUrl}` : null),
      go: !which('go') ? 'go is not on PATH' : (!pg ? 'Postgres on 127.0.0.1:55433 is not accepting connections' : null),
      django: existsSync(cfg.djangoPython) ? null : 'control-panel/.venv is missing',
      console_smoke: consoleUp ? null : `operator console not answering at ${cfg.consoleUrl}`,
    };
    if (cfg.selftest) suites.selftest = null;
    return {
      suites: Object.fromEntries(Object.entries(suites).map(([k, why]) => [k, {label: SUITE_LABELS[k] || k, available: !why, reason: why || null}])),
      stack: {gateway, website, postgres: pg},
      seed: readJSON(join(cfg.results, 'seed_manifest.json'), null) ? summarizeSeed(readJSON(join(cfg.results, 'seed_manifest.json'), null)) : null,
    };
  }
  function summarizeSeed(m) {
    if (!m) return null;
    const steps = Object.values(m.steps || {});
    const needs = Object.values(m.seed_needs || {});
    return {prefix: m.prefix, updated_at: m.updated_at, members: Object.fromEntries(Object.entries(m.members || {}).map(([k, v]) => [k, v.username])),
      steps: {ok: steps.filter(s => s.status === 'ok').length, skipped: steps.filter(s => s.status === 'skipped').length, failed: steps.filter(s => s.status === 'failed').length},
      needs: {seeded: needs.filter(n => n.status === 'seeded').length, total: needs.length,
        missing: Object.entries(m.seed_needs || {}).filter(([, v]) => !['seeded', 'n/a'].includes(v.status)).map(([k, v]) => ({need: k, status: v.status, why: v.why || []}))}};
  }

  // ---------------------------------------------------------------- suite commands
  function suiteCommand(suite, sel, runDir) {
    const rel = (prefix, f) => (f.startsWith(`${prefix}/`) ? f.slice(prefix.length + 1) : f);
    const files = sel ? [...sel.files] : [];
    const names = sel ? [...sel.names] : [];
    const baseEnv = {...process.env, QA_LAB_RUN_ID: current.run.id, QA_SEED_MANIFEST: join(cfg.results, 'seed_manifest.json')};
    delete baseEnv.QA_LAB; // a nested website server started by a spec must opt in itself
    switch (suite) {
      case 'flutter':
        return {cmd: 'flutter', args: ['test', '--machine', '--no-pub', ...files.filter(f => f.startsWith('app/')).map(f => rel('app', f))], cwd: join(root, 'app'), env: baseEnv, raw: 'flutter.jsonl'};
      case 'playwright': {
        const out = join(runDir, 'playwright.json');
        return {cmd: 'npx', args: ['playwright', 'test', '--reporter=line,json', `--output=${join(runDir, 'playwright-artifacts')}`, ...files.filter(f => f.startsWith('website/')).map(f => rel('website', f))],
          cwd: join(root, 'website'), env: {...baseEnv, PLAYWRIGHT_JSON_OUTPUT_NAME: out, PLAYWRIGHT_JSON_OUTPUT_FILE: out, FORCE_COLOR: '0'}, jsonFile: out};
      }
      case 'api_e2e': case 'appium': case 'console_smoke': {
        const dir = {api_e2e: 'qa/api_e2e', appium: 'qa/appium', console_smoke: 'qa/console_smoke'}[suite];
        const jsonl = join(runDir, `${suite}.jsonl`);
        const args = ['-m', 'pytest', '-p', 'qalab_pytest', '-v', '-rA', '-p', 'no:cacheprovider'];
        const fs = files.filter(f => f.startsWith(`${dir}/`)).map(f => rel(dir, f));
        if (fs.length) args.push(...[...new Set(fs)]);
        const funcs = names.filter(n => /^test\w*$/.test(n));
        if (sel && funcs.length && funcs.length <= 60) args.push('-k', [...new Set(funcs)].join(' or '));
        const e = {...baseEnv, PYTHONPATH: [join(root, 'qa', 'lab'), process.env.PYTHONPATH].filter(Boolean).join(':'), QA_LAB_PYTEST_JSON: jsonl, PYTHONUNBUFFERED: '1'};
        if (suite === 'appium') {
          Object.assign(e, {ANDROID_DEVICE_NAME: cfg.appiumDevice, APPIUM_SERVER_URL: cfg.appiumUrl});
          if (!e.ANDROID_HOME) { const adb = which('adb'); if (adb) e.ANDROID_HOME = resolve(dirname(adb), '..'); }
          e.ANDROID_SDK_ROOT ||= e.ANDROID_HOME;
        }
        if (suite === 'console_smoke') e.CONSOLE_BASE_URL = cfg.consoleUrl;
        return {cmd: cfg.python, args, cwd: join(root, dir), env: e, jsonl};
      }
      case 'go': {
        const pkgs = sel ? [...sel.packages].filter(p => p.startsWith('backend/')).map(p => `./${rel('backend', p)}`) : ['./...'];
        const funcs = names.filter(n => /^Test\w+$/.test(n));
        const args = ['test', '-json', '-count=1', ...new Set(pkgs.length ? pkgs : ['./...'])];
        if (sel && funcs.length && funcs.length <= 80) args.push('-run', `^(${[...new Set(funcs)].join('|')})$`);
        return {cmd: 'go', args, cwd: join(root, 'backend'), env: {...baseEnv, PROFILE_TEST_DATABASE_URL: cfg.goDb}, raw: 'go.jsonl'};
      }
      case 'django': {
        const labels = sel ? [...new Set(files.filter(f => f.startsWith('control-panel/') && f.endsWith('.py')).map(f => rel('control-panel', f).replace(/\.py$/, '').replace(/\//g, '.')))] : [];
        return {cmd: cfg.djangoPython, args: ['manage.py', 'test', '-v', '2', '--noinput', ...labels], cwd: join(root, 'control-panel'), env: {...baseEnv, PYTHONUNBUFFERED: '1'}};
      }
      case 'selftest':
        return {cmd: process.execPath, args: ['--test', `--test-reporter=${join(here, 'node-test-jsonl.mjs')}`, `--test-reporter-destination=${join(runDir, 'selftest.jsonl')}`,
          '--test-reporter=spec', '--test-reporter-destination=stdout', join(here, 'mapper.test.mjs')], cwd: root, env: baseEnv, jsonl: join(runDir, 'selftest.jsonl')};
      default:
        return null;
    }
  }

  function parseSuite(suite, spec, runDir, logText) {
    try {
      switch (suite) {
        case 'flutter': return M.parseFlutterMachine(readFileSync(join(runDir, 'flutter.jsonl'), 'utf8'), {root});
        case 'playwright': return existsSync(spec.jsonFile) ? M.parsePlaywrightJson(readFileSync(spec.jsonFile, 'utf8'), {root}) : [];
        case 'api_e2e': case 'appium': case 'console_smoke':
          return existsSync(spec.jsonl) ? M.parsePytestJsonl(readFileSync(spec.jsonl, 'utf8'), {suite, suiteDir: {api_e2e: 'qa/api_e2e', appium: 'qa/appium', console_smoke: 'qa/console_smoke'}[suite]}) : [];
        case 'go': return M.parseGoJson(readFileSync(join(runDir, 'go.jsonl'), 'utf8'), {modulePath: M.goModulePath(root), caseIndex: M.goCaseIndex(root)});
        case 'django': return M.parseDjangoVerbose(logText, {caseIndex: M.djangoCaseIndex(root)});
        case 'selftest': return existsSync(spec.jsonl) ? M.parsePytestJsonl(readFileSync(spec.jsonl, 'utf8'), {suite: 'selftest', suiteDir: 'website/qa-lab'}) : [];
        default: return [];
      }
    } catch (e) {
      logLine(`[qa-lab] could not parse ${suite} results: ${e.message}`);
      return [];
    }
  }

  function liveParser(suite) {
    const st = {names: new Map(), done: 0, passed: 0, failed: 0, skipped: 0, total: 0};
    const goSeen = new Set();
    const line = raw => {
      if (suite === 'flutter') return M.flutterLogLine(st, raw);
      if (suite === 'go') {
        if (!raw.startsWith('{')) return raw;
        let ev; try { ev = JSON.parse(raw); } catch { return null; }
        if (ev.Test && !ev.Test.includes('/') && ['pass', 'fail', 'skip'].includes(ev.Action)) {
          const k = `${ev.Package}::${ev.Test}`;
          if (goSeen.has(k)) return null;
          goSeen.add(k);
          st.done += 1;
          if (ev.Action === 'pass') st.passed += 1; else if (ev.Action === 'fail') st.failed += 1; else st.skipped += 1;
          return ev.Action === 'fail' ? `✗ ${ev.Test} (${ev.Package.split('/').slice(-2).join('/')})` : null;
        }
        if (!ev.Test && ['pass', 'fail', 'skip'].includes(ev.Action)) return `${ev.Action === 'fail' ? 'FAIL' : 'ok  '} ${ev.Package} ${ev.Elapsed ?? ''}s`;
        return null;
      }
      const t = M.stripAnsi(raw);
      let m;
      if ((m = t.match(/::\S+ (PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS)\b/))) {
        st.done += 1;
        if (m[1] === 'PASSED' || m[1] === 'XPASS') st.passed += 1; else if (m[1] === 'FAILED' || m[1] === 'ERROR') st.failed += 1; else st.skipped += 1;
      } else if (suite === 'django' && (m = t.match(/ \.\.\. (ok|FAIL|ERROR|skipped|expected failure|unexpected success)/))) {
        st.done += 1;
        if (m[1] === 'ok' || m[1] === 'unexpected success') st.passed += 1; else if (m[1] === 'FAIL' || m[1] === 'ERROR') st.failed += 1; else st.skipped += 1;
      } else if (suite === 'playwright' && (m = t.match(/^\[(\d+)\/(\d+)\]/))) {
        st.done = Number(m[1]); st.total = Number(m[2]);
        if (/✘|failed/.test(t)) st.failed += 1;
      } else if (suite === 'selftest' && (m = t.match(/^\s*(✔|✖)/))) {
        st.done += 1; if (m[1] === '✔') st.passed += 1; else st.failed += 1;
      }
      return t;
    };
    return {st, line};
  }

  function spawnStep(name, spec, runDir, timeoutMin) {
    return new Promise(resolveStep => {
      const logPath = join(runDir, `${name}.log`);
      const rawPath = spec.raw ? join(runDir, spec.raw) : null;
      writeFileSync(logPath, `$ (cd ${spec.cwd.replace(root, '.')} && ${[spec.cmd === cfg.python ? '.venv/bin/python' : spec.cmd, ...spec.args].join(' ')})\n`);
      if (rawPath) writeFileSync(rawPath, '');
      logLine(`▶ ${name}: ${[spec.cmd.split('/').pop(), ...spec.args].join(' ').slice(0, 400)}`);
      let child;
      try {
        child = spawn(spec.cmd, spec.args, {cwd: spec.cwd, env: spec.env, detached: true, stdio: ['ignore', 'pipe', 'pipe']});
      } catch (e) {
        resolveStep({exitCode: -1, error: e.message, text: ''});
        return;
      }
      current.child = child;
      const parser = liveParser(name);
      const progress = current.run.progress = {step: name, done: 0, passed: 0, failed: 0, skipped: 0, total: 0};
      let textBuf = '';
      const keepText = name === 'django' || name === 'seed' || name === 'rescan';
      const onData = isErr => {
        let partial = '';
        return chunk => {
          const s = partial + chunk.toString('utf8');
          const lines = s.split('\n');
          partial = lines.pop();
          for (const l of lines) {
            if (rawPath && !isErr && l.startsWith('{')) appendFileSync(rawPath, `${l}\n`);
            else appendFileSync(logPath, `${l}\n`);
            if (keepText) textBuf += `${l}\n`;
            const shown = parser.line(l);
            if (shown) { logLine(shown); if (rawPath) appendFileSync(logPath, `${shown}\n`); }
          }
          Object.assign(progress, {done: parser.st.done, passed: parser.st.passed, failed: parser.st.failed, skipped: parser.st.skipped, total: parser.st.total});
        };
      };
      child.stdout.on('data', onData(false));
      child.stderr.on('data', onData(true));
      const ticker = setInterval(() => send('progress', {run: current?.run.id, progress}), 1000);
      const timer = setTimeout(() => {
        logLine(`[qa-lab] ${name} exceeded ${timeoutMin} min; stopping it`);
        current.timedOut = true;
        killGroup(child);
      }, timeoutMin * 60_000);
      child.on('error', e => { logLine(`[qa-lab] ${name}: ${e.message}`); });
      child.on('close', code => {
        clearInterval(ticker); clearTimeout(timer);
        current.child = null;
        resolveStep({exitCode: code, text: textBuf, timedOut: current.timedOut});
        current.timedOut = false;
      });
    });
  }

  function killGroup(child) {
    if (!child || child.exitCode !== null) return;
    try { process.kill(-child.pid, 'SIGTERM'); } catch { try { child.kill('SIGTERM'); } catch { /* gone */ } }
    setTimeout(() => { try { process.kill(-child.pid, 'SIGKILL'); } catch { /* gone */ } }, 8000).unref();
  }

  // ---------------------------------------------------------------- runs
  function resolveSelection(req, cat, led) {
    const mode = ['all', 'area', 'features', 'cases', 'failed'].includes(req.mode) ? req.mode : 'all';
    let caseIds = null;
    if (mode === 'area') {
      const areas = new Set([].concat(req.areas || []));
      caseIds = cat.features.filter(f => areas.has(f.area)).flatMap(f => f.cases.map(c => c.id));
    } else if (mode === 'features') {
      const fs = new Set([].concat(req.features || []));
      caseIds = cat.features.filter(f => fs.has(f.id)).flatMap(f => f.cases.map(c => c.id));
    } else if (mode === 'cases') {
      const known = new Set(cat.features.flatMap(f => f.cases.map(c => c.id)));
      caseIds = [].concat(req.cases || []).filter(id => known.has(id));
    } else if (mode === 'failed') {
      caseIds = Object.entries(led).filter(([, v]) => v.result === 'fail').map(([k]) => k);
    }
    return {mode, caseIds};
  }

  async function startRun(req, operator) {
    if (current) return {error: 'A run is already in progress.', status: 409};
    const lock = join(cfg.results, 'run.lock');
    const held = readJSON(lock, null);
    if (held && held.pid !== process.pid) {
      try { process.kill(held.pid, 0); return {error: `Another QA Lab process (pid ${held.pid}) is running a run.`, status: 409}; } catch { /* stale lock */ }
    }
    const cat = effectiveCatalog();
    const led = ledger();
    const {mode, caseIds} = resolveSelection(req, cat, led);
    if (caseIds && !caseIds.length) return {error: mode === 'failed' ? 'No failing cases in the latest results.' : 'The selection contains no cases.', status: 400};
    const env = await environment();
    const allSuites = Object.keys(env.suites).filter(s => s !== 'selftest' || cfg.selftest);
    let suites = Array.isArray(req.suites) && req.suites.length ? req.suites.filter(s => allSuites.includes(s)) : allSuites.filter(s => env.suites[s].available && s !== 'selftest');
    const selection = caseIds ? M.selectionForCases(cat, caseIds, led) : null;
    if (selection) suites = suites.filter(s => selection[s] || s === 'selftest');
    if (!suites.length) return {error: 'None of the selected cases has an automated test in an available suite.', status: 400};
    const id = newRunId();
    const runDir = join(runsDir, id);
    mkdirSync(runDir, {recursive: true});
    const rescan = ['full', 'tags', 'none'].includes(req.rescan) ? req.rescan : (mode === 'all' ? 'full' : 'tags');
    const run = {
      id, status: 'running', mode, by: operator.username, startedAt: nowIso(), finishedAt: null,
      request: {suites, areas: req.areas || [], features: req.features || [], cases: caseIds ? caseIds.slice(0, 5000) : null, seed: req.seed !== false, rescan},
      steps: [
        ...(rescan !== 'none' ? [{name: 'rescan', status: 'pending'}] : []),
        ...(req.seed !== false ? [{name: 'seed', status: 'pending'}] : []),
        ...suites.map(s => ({name: s, status: 'pending', ...(env.suites[s] && !env.suites[s].available ? {skipReason: env.suites[s].reason} : {})})),
      ],
      progress: null, summary: null,
    };
    current = {run, child: null, cancelled: false, logTail: [], timedOut: false};
    writeJSON(lock, {pid: process.pid, run: id, at: nowIso()});
    publish();
    execute(run, runDir, {cat, caseIds, selection}).catch(e => {
      logLine(`[qa-lab] run crashed: ${e.stack || e.message}`);
      run.status = 'error'; run.finishedAt = nowIso(); publish(); finish(lock);
    });
    return {run};
  }

  function finish(lock) {
    try { writeFileSync(lock, '{}'); } catch { /* ignore */ }
    if (flushTimer) { clearTimeout(flushTimer); flushTimer = null; send('log', {run: current?.run.id, lines: pendingLines}); pendingLines = []; }
    if (current) writeFileSync(join(runsDir, current.run.id, 'qa-lab.log'), `${current.logTail.join('\n')}\n`);
    current = null;
  }

  async function execute(run, runDir, {caseIds, selection}) {
    const lock = join(cfg.results, 'run.lock');
    const results = [];
    const suitesRun = new Set();
    for (const step of run.steps) {
      if (current.cancelled) { step.status = 'cancelled'; continue; }
      if (step.skipReason) { step.status = 'skipped'; step.detail = step.skipReason; logLine(`- ${step.name}: skipped (${step.skipReason})`); publish(); continue; }
      step.status = 'running'; step.startedAt = nowIso(); publish();
      const timeoutMin = Number(env[`QA_LAB_TIMEOUT_${step.name.toUpperCase()}_MIN`]) || DEFAULT_TIMEOUT_MIN[step.name] || 30;
      if (step.name === 'rescan') {
        const r = await spawnStep('rescan', {cmd: cfg.python, args: [join(root, 'qa/catalog/tools/regenerate.py'), '--no-md', '--quiet', ...(run.request.rescan === 'tags' ? ['--tags-only'] : [])], cwd: root, env: process.env}, runDir, timeoutMin);
        step.status = r.exitCode === 0 ? 'passed' : 'failed';
        step.detail = r.exitCode === 0 ? (r.text.trim().split('\n').pop() || '').slice(0, 400) : `regenerate.py exited ${r.exitCode}; using the existing catalog`;
      } else if (step.name === 'seed') {
        const r = await spawnStep('seed', {cmd: cfg.python, args: [join(root, 'qa/seed/seed_dataset.py'), 'ensure', '--json'], cwd: root, env: {...process.env, QA_LAB_RESULTS_DIR: cfg.results, PYTHONUNBUFFERED: '1'}}, runDir, timeoutMin);
        const summaryLine = r.text.split('\n').reverse().find(l => l.startsWith('{"prefix"'));
        const s = summaryLine ? JSON.parse(summaryLine) : null;
        step.status = r.exitCode === 0 ? 'passed' : 'failed';
        step.detail = s ? `prefix ${s.prefix}: ${Object.values(s.steps).filter(v => v === 'ok').length} steps ok, ${Object.values(s.steps).filter(v => v === 'failed').length} failed` : `seed exited ${r.exitCode}`;
      } else {
        const spec = suiteCommand(step.name, selection ? selection[step.name] : null, runDir);
        const r = await spawnStep(step.name, spec, runDir, timeoutMin);
        const res = parseSuite(step.name, spec, runDir, r.text);
        results.push(...res);
        suitesRun.add(step.name);
        writeJSON(join(runDir, `${step.name}.results.json`), res);
        const counts = {passed: res.filter(x => x.status === 'passed').length, failed: res.filter(x => x.status === 'failed').length, skipped: res.filter(x => x.status === 'skipped').length};
        step.counts = counts;
        step.exitCode = r.exitCode;
        if (current.cancelled) step.status = 'cancelled';
        else if (r.timedOut) { step.status = 'failed'; step.detail = `timed out after ${timeoutMin} min`; }
        else if (counts.failed || (r.exitCode !== 0 && !res.length)) step.status = 'failed';
        else step.status = 'passed';
        if (!res.length && !current.cancelled) step.detail = (step.detail ? `${step.detail}; ` : '') + `no test results parsed (exit ${r.exitCode}); see ${step.name}.log`;
        logLine(`■ ${step.name}: ${counts.passed} passed, ${counts.failed} failed, ${counts.skipped} skipped (exit ${r.exitCode})`);
      }
      step.finishedAt = nowIso();
      publish();
    }
    // ---- map results to cases
    const cat = effectiveCatalog(); // re-read: rescan may have updated it
    writeJSON(join(runDir, 'results.json'), results);
    const {cases, unknownTags} = M.evaluateCases(cat, results, {suitesRun});
    const inScope = caseIds ? new Set(caseIds) : null;
    const scoped = inScope ? Object.fromEntries(Object.entries(cases).filter(([k, c]) => inScope.has(k) || ['pass', 'fail', 'skipped'].includes(c.result))) : cases;
    writeJSON(join(runDir, 'cases.json'), scoped);
    const at = nowIso();
    const nextLedger = M.mergeLedger(ledger(), scoped, {runId: run.id, at});
    writeJSON(ledgerPath, nextLedger);
    const prev = runIndex().find(r => r.status !== 'running' && r.id !== run.id);
    const prevCases = prev ? readJSON(join(runsDir, prev.id, 'cases.json'), {}) : {};
    const diff = {against: prev?.id || null, ...M.diffRuns(prevCases, scoped)};
    writeJSON(join(runDir, 'diff.json'), diff);
    const tally = r => Object.values(scoped).filter(c => c.result === r).length;
    const cov = M.coverage(cat, nextLedger, M.latestManual(manualHistory()));
    run.summary = {
      tests: {total: results.length, passed: results.filter(r => r.status === 'passed').length, failed: results.filter(r => r.status === 'failed').length, skipped: results.filter(r => r.status === 'skipped').length},
      cases: {inScope: Object.keys(scoped).length, pass: tally('pass'), fail: tally('fail'), skipped: tally('skipped'), notRun: tally('not_run'),
        unmatched: Object.values(scoped).filter(c => c.unmatched).length},
      unknownTags, diff: Object.fromEntries(Object.entries(diff).map(([k, v]) => [k, Array.isArray(v) ? v.length : v])),
      coverage: {automatedPct: cov.all.automatedPct, automatedOrManualPct: cov.all.automatedOrManualPct, verifiedPct: cov.all.verifiedPct},
    };
    const anyFailed = run.steps.some(s => s.status === 'failed' && s.name !== 'rescan');
    run.status = current.cancelled ? 'cancelled' : (anyFailed || run.summary.tests.failed ? 'failed' : 'passed');
    run.finishedAt = nowIso();
    run.progress = null;
    const idx = runIndex().filter(r => r.id !== run.id);
    idx.unshift({id: run.id, status: run.status, mode: run.mode, by: run.by, startedAt: run.startedAt, finishedAt: run.finishedAt,
      suites: run.request.suites, tests: run.summary.tests, cases: run.summary.cases, coverage: run.summary.coverage});
    writeJSON(indexPath, idx.slice(0, 500));
    logLine(`■ run ${run.status}: ${run.summary.tests.passed} passed, ${run.summary.tests.failed} failed; cases pass ${run.summary.cases.pass}, fail ${run.summary.cases.fail}; verified ${cov.all.verifiedPct}%`);
    publish();
    send('done', {run: run.id, status: run.status});
    finish(lock);
  }

  function cancelRun(id) {
    if (!current || current.run.id !== id) return false;
    current.cancelled = true;
    logLine('[qa-lab] cancel requested');
    killGroup(current.child);
    return true;
  }

  // ---------------------------------------------------------------- views
  function compactCatalog() {
    const cat = effectiveCatalog();
    const led = ledger();
    const marks = M.latestManual(manualHistory());
    const cov = M.coverage(cat, led, marks);
    const features = cat.features.map(f => ({
      id: f.id, area: f.area, screen: f.screen, route: f.route,
      controls: (f.controls || []).map(c => ({id: c.id, label: c.label, type: c.type, qa_key: c.qa_key || null, action: c.action || null, api: c.api || null})),
      cases: f.cases.map(c => ({
        id: c.id, title: c.title, type: c.type, status: c.status, mapped_by: c.mapped_by || null, steps: c.steps, expected: c.expected,
        seed_needs: c.seed_needs, notes: c.notes || null, manual_reason: c.manual_reason || null,
        automated_by: (c.automated_by || []).slice(0, 6).map(a => ({suite: M.refSuite(a), file: a.file, test: a.test, via: a.via || null})),
        automated_by_total: (c.automated_by || []).length,
        chip: cov.chips[c.id], last: led[c.id] || null, manual: marks[c.id] || null,
      })),
    }));
    return {generated: cat.generated, stats: cat.stats, conventions: cat.conventions, features, coverage: {all: cov.all, byArea: cov.byArea, bySuite: cov.bySuite}};
  }

  function manualList() {
    const cat = effectiveCatalog();
    const hist = manualHistory();
    const out = [];
    for (const f of cat.features) {
      for (const c of f.cases) {
        if (c.status !== 'manual') continue;
        const marks = hist[c.id] || [];
        out.push({id: c.id, title: c.title, type: c.type, feature: f.id, screen: f.screen, area: f.area, steps: c.steps, expected: c.expected,
          seed_needs: c.seed_needs, reason: c.manual_reason || '', latest: marks[marks.length - 1] || null, history: marks.slice(-5)});
      }
    }
    return out;
  }

  function reportMarkdown(runId) {
    const cat = effectiveCatalog();
    const led = ledger();
    const marks = M.latestManual(manualHistory());
    const cov = M.coverage(cat, led, marks);
    const run = runId ? readJSON(join(runsDir, runId, 'run.json'), null) : null;
    const cases = runId ? readJSON(join(runsDir, runId, 'cases.json'), {}) : null;
    const diff = runId ? readJSON(join(runsDir, runId, 'diff.json'), null) : null;
    const L = [];
    const pct = (a, b) => (b ? `${(100 * a / b).toFixed(1)}%` : '—');
    L.push(`# QA Lab report${run ? ` — run ${run.id}` : ' — current coverage'}`, '');
    L.push(`Generated ${nowIso()} from \`qa/catalog/feature_catalog.json\` (catalog ${cat.generated || '?'}).`, '');
    if (run) {
      L.push(`**Run** ${run.id} · mode \`${run.mode}\` · by ${run.by} · ${run.startedAt} → ${run.finishedAt || 'running'} · **${run.status}**`, '');
      L.push('| Step | Status | Passed | Failed | Skipped | Detail |', '|---|---|---|---|---|---|');
      for (const s of run.steps) L.push(`| ${s.name} | ${s.status} | ${s.counts?.passed ?? ''} | ${s.counts?.failed ?? ''} | ${s.counts?.skipped ?? ''} | ${(s.detail || '').replace(/\|/g, '/')} |`);
      L.push('');
    }
    const a = cov.all;
    L.push('## Coverage', '', '| Metric | Cases | % |', '|---|---|---|');
    L.push(`| Catalog cases | ${a.total} | |`, `| Automated (tag or heuristic) | ${a.automated} | ${a.automatedPct}% |`,
      `| Automated + manual checked | ${a.automated + a.manualChecked} | ${a.automatedOrManualPct}% |`,
      `| **Verified** (automated & passing, or manual & checked pass) — the gate | ${a.verified} | **${a.verifiedPct}%** |`,
      `| Failing | ${a.failing} | ${pct(a.failing, a.total)} |`, `| Automated but not run / skipped | ${a.notRun} | ${pct(a.notRun, a.total)} |`,
      `| Manual (unchecked or failed) | ${a.manual - a.manualChecked} | ${pct(a.manual - a.manualChecked, a.total)} |`,
      `| Presence-only / partial / not automated | ${a.presenceOnly} / ${a.partial} / ${a.notAutomated} | ${pct(a.presenceOnly + a.partial + a.notAutomated, a.total)} |`, '');
    L.push('### By suite', '', '| Suite | Cases | Automated | Passing | Failing |', '|---|---|---|---|---|');
    for (const [k, v] of Object.entries(cov.bySuite)) L.push(`| ${k} | ${v.total} | ${v.automated} | ${v.passing} | ${v.failing} |`);
    L.push('', '### By area', '', '| Area | Cases | Automated % | Verified % | Failing |', '|---|---|---|---|---|');
    for (const [k, v] of Object.entries(cov.byArea)) L.push(`| ${k} | ${v.total} | ${v.automatedPct}% | ${v.verifiedPct}% | ${v.failing} |`);
    if (diff) {
      L.push('', `## Diff vs previous run (${diff.against || 'none'})`, '');
      for (const k of ['regressed', 'fixed', 'newlyFailing', 'newlyPassing', 'noLongerRun']) {
        L.push(`* **${k}**: ${diff[k]?.length || 0}${diff[k]?.length ? ` — ${diff[k].slice(0, 25).map(x => `\`${x}\``).join(', ')}${diff[k].length > 25 ? ' …' : ''}` : ''}`);
      }
    }
    const failing = cases ? Object.entries(cases).filter(([, c]) => c.result === 'fail') : Object.entries(led).filter(([, c]) => c.result === 'fail');
    L.push('', `## Failing cases (${failing.length})`, '');
    for (const [id, c] of failing.slice(0, 300)) {
      const t = (c.tests || []).find(x => x.status === 'failed') || (c.tests || [])[0];
      L.push(`* \`${id}\` — ${t ? `${t.suite}: ${t.file} › ${M.stripTags(t.test)}` : ''}${t?.message ? `\n  > ${t.message.split('\n')[0].slice(0, 200)}` : ''}`);
    }
    const gaps = [];
    for (const f of cat.features) for (const c of f.cases) if (!['pass', 'manual_pass'].includes(cov.chips[c.id])) gaps.push([f.area, c.id, cov.chips[c.id]]);
    L.push('', `## Gaps to 100% (${gaps.length})`, '', 'Grouped by area and status; the full list is in the JSON export.', '');
    const g = {};
    for (const [area, , chip] of gaps) { g[area] ||= {}; g[area][chip] = (g[area][chip] || 0) + 1; }
    L.push('| Area | ' + ['fail', 'not_run', 'skipped', 'manual_unchecked', 'manual_fail', 'presence_only', 'partial', 'not_automated'].join(' | ') + ' |', '|---|---|---|---|---|---|---|---|---|');
    for (const [area, v] of Object.entries(g).sort()) L.push(`| ${area} | ${['fail', 'not_run', 'skipped', 'manual_unchecked', 'manual_fail', 'presence_only', 'partial', 'not_automated'].map(k => v[k] || 0).join(' | ')} |`);
    return `${L.join('\n')}\n`;
  }

  function reportJSON(runId) {
    const cat = effectiveCatalog();
    const led = ledger();
    const marks = M.latestManual(manualHistory());
    const cov = M.coverage(cat, led, marks);
    const out = {generated: nowIso(), catalog: {generated: cat.generated, cases: cov.all.total}, coverage: {all: cov.all, byArea: cov.byArea, bySuite: cov.bySuite}};
    if (runId) {
      out.run = readJSON(join(runsDir, runId, 'run.json'), null);
      out.cases = readJSON(join(runsDir, runId, 'cases.json'), {});
      out.diff = readJSON(join(runsDir, runId, 'diff.json'), null);
    }
    out.status = Object.fromEntries(Object.entries(cov.chips));
    out.manual = marks;
    return out;
  }

  // ---------------------------------------------------------------- HTTP
  function json(res, status, body) {
    res.writeHead(status, {'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store'});
    res.end(JSON.stringify(body));
  }
  function readBody(req, limit = 64 * 1024) {
    return new Promise((res, rej) => {
      let size = 0; const chunks = [];
      req.on('data', c => { size += c.length; if (size > limit) { rej(new Error('too large')); req.destroy(); } else chunks.push(c); });
      req.on('end', () => { try { res(chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : {}); } catch { rej(new Error('bad json')); } });
      req.on('error', rej);
    });
  }
  function cookie(req, name) {
    for (const part of String(req.headers.cookie || '').split(';')) {
      const [k, ...v] = part.trim().split('=');
      if (k === name) return v.join('=');
    }
    return null;
  }
  function session(req) {
    const tok = cookie(req, 'qa_lab_session');
    const s = tok ? sessions.get(tok) : null;
    if (!s) return null;
    if (s.expires < Date.now()) { sessions.delete(tok); return null; }
    return s;
  }
  function sameOrigin(req) {
    const origin = req.headers.origin;
    if (!origin) return true;
    try { return new URL(origin).host.toLowerCase() === String(req.headers.host || '').toLowerCase(); } catch { return false; }
  }

  async function signIn(req, res) {
    const nowMs = Date.now();
    while (failedLogins.length && failedLogins[0] < nowMs - 5 * 60_000) failedLogins.shift();
    if (failedLogins.length >= 10) return json(res, 429, {error: 'Too many failed sign-ins. Wait a few minutes.'});
    let body;
    try { body = await readBody(req, 4096); } catch { return json(res, 400, {error: 'Invalid request.'}); }
    const username = typeof body.username === 'string' ? body.username.trim() : '';
    const password = typeof body.password === 'string' ? body.password : '';
    if (!username || !password || username.length > 64 || password.length > 256) return json(res, 400, {error: 'Enter your operator username and password.'});
    const login = await upstreamJSON(cfg.upstream, 'POST', '/v1/auth/login', {body: {username, password}});
    if (login.status !== 200 || !login.data?.access_token) {
      failedLogins.push(nowMs);
      return json(res, login.status === 0 ? 502 : 401, {error: login.status === 0 ? 'The API gateway is not reachable.' : 'Sign-in failed.'});
    }
    const token = login.data.access_token;
    const userId = login.data.user_id;
    const agents = await upstreamJSON(cfg.upstream, 'GET', '/v1/admin/support/agents', {token});
    // Never keep the gateway session: the operator's role is all QA Lab needs.
    upstreamJSON(cfg.upstream, 'POST', '/v1/auth/logout', {token, body: {}}).catch(() => {});
    const me = (agents.data?.agents || []).find(a => a && a.id === userId);
    const roles = (me?.roles || []).filter(r => typeof r === 'string');
    if (agents.status !== 200 || !roles.some(r => cfg.roles.has(r))) {
      failedLogins.push(nowMs);
      return json(res, 403, {error: `This account is not a QA operator (needs one of: ${[...cfg.roles].join(', ')}).`});
    }
    const sid = randomBytes(32).toString('base64url');
    const s = {username, userId, name: me?.name || username, roles, created: nowMs, expires: nowMs + 8 * 3600_000};
    sessions.set(sid, s);
    res.setHeader('Set-Cookie', `qa_lab_session=${sid}; HttpOnly; SameSite=Strict; Path=/qa-lab; Max-Age=28800`);
    return json(res, 200, {operator: {username, name: s.name, roles}});
  }

  function serveStatic(res, rel) {
    const uiRoot = join(here, 'ui');
    const file = resolve(uiRoot, rel || 'index.html');
    if (!file.startsWith(uiRoot + sep) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, {'Content-Type': MIME[extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store'});
    createReadStream(file).pipe(res);
  }

  function runFile(id, name) {
    if (!/^[0-9]{8}-[0-9]{6}-[0-9a-f]{4}$/.test(id) || !/^[\w.-]+$/.test(name)) return null;
    const p = join(runsDir, id, name);
    return existsSync(p) ? p : null;
  }

  async function handle(req, res, url) {
    const path = url.pathname;
    if (!(path === '/qa-lab' || path.startsWith('/qa-lab/'))) return false;
    if (!isLoopback(req)) { res.writeHead(404, {'Content-Type': 'text/plain'}); res.end('Not found'); return true; }
    if (path === '/qa-lab') { res.writeHead(302, {Location: '/qa-lab/'}); res.end(); return true; }
    if (!path.startsWith('/qa-lab/api/')) {
      if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405); res.end(); return true; }
      serveStatic(res, path === '/qa-lab/' ? 'index.html' : path.slice('/qa-lab/'.length));
      return true;
    }
    const api = path.slice('/qa-lab/api'.length);
    const mutating = req.method !== 'GET' && req.method !== 'HEAD';
    if (mutating && (req.headers['x-qa-lab'] !== '1' || !sameOrigin(req))) return json(res, 403, {error: 'Missing QA Lab request header.'}), true;
    if (api === '/session' && req.method === 'POST') { await signIn(req, res); return true; }
    const op = session(req);
    // 200 either way, so the sign-in page's probe does not log a console error.
    if (api === '/session' && req.method === 'GET') return json(res, 200, {operator: op ? {username: op.username, name: op.name, roles: op.roles} : null}), true;
    if (!op) return json(res, 401, {error: 'Sign in as a QA operator.'}), true;
    if (api === '/session' && req.method === 'DELETE') {
      sessions.delete(cookie(req, 'qa_lab_session'));
      res.setHeader('Set-Cookie', 'qa_lab_session=; HttpOnly; SameSite=Strict; Path=/qa-lab; Max-Age=0');
      return json(res, 200, {ok: true}), true;
    }
    if (api === '/catalog' && req.method === 'GET') return json(res, 200, compactCatalog()), true;
    if (api === '/env' && req.method === 'GET') return json(res, 200, await environment()), true;
    if (api === '/runs' && req.method === 'GET') return json(res, 200, {current: current ? current.run : null, runs: runIndex()}), true;
    if (api === '/runs' && req.method === 'POST') {
      let body;
      try { body = await readBody(req); } catch { return json(res, 400, {error: 'Invalid request.'}), true; }
      const r = await startRun(body || {}, op);
      return json(res, r.error ? r.status : 202, r.error ? {error: r.error} : {run: r.run}), true;
    }
    if (api === '/events' && req.method === 'GET') {
      res.writeHead(200, {'Content-Type': 'text/event-stream; charset=utf-8', 'Cache-Control': 'no-store', Connection: 'keep-alive', 'X-Accel-Buffering': 'no'});
      res.write(`event: hello\ndata: ${JSON.stringify({run: current ? current.run : null, lines: current ? current.logTail.slice(-200) : []})}\n\n`);
      clients.add(res);
      const hb = setInterval(() => { try { res.write(': hb\n\n'); } catch { /* closed */ } }, 15000);
      req.on('close', () => { clearInterval(hb); clients.delete(res); });
      return true;
    }
    if (api === '/manual' && req.method === 'GET') return json(res, 200, {cases: manualList()}), true;
    if (api === '/report.md' && req.method === 'GET') { res.writeHead(200, {'Content-Type': 'text/markdown; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Disposition': 'attachment; filename="qa-lab-coverage.md"'}); res.end(reportMarkdown(null)); return true; }
    if (api === '/report.json' && req.method === 'GET') { res.writeHead(200, {'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Disposition': 'attachment; filename="qa-lab-coverage.json"'}); res.end(JSON.stringify(reportJSON(null), null, 1)); return true; }
    let m;
    if ((m = api.match(/^\/manual\/([A-Za-z0-9_.\-]+)$/)) && req.method === 'POST') {
      let body;
      try { body = await readBody(req, 8192); } catch { return json(res, 400, {error: 'Invalid request.'}), true; }
      const id = m[1];
      if (!manualList().some(c => c.id === id)) return json(res, 404, {error: 'Not a manual case.'}), true;
      if (!['pass', 'fail', 'unchecked'].includes(body.result)) return json(res, 400, {error: 'result must be pass, fail or unchecked.'}), true;
      const note = typeof body.note === 'string' ? body.note.slice(0, 1000) : '';
      const hist = manualHistory();
      (hist[id] ||= []).push({result: body.result, note, by: op.username, name: op.name, at: nowIso()});
      writeJSON(manualPath, hist);
      send('manual', {id, latest: hist[id][hist[id].length - 1]});
      return json(res, 200, {id, latest: hist[id][hist[id].length - 1]}), true;
    }
    if ((m = api.match(/^\/runs\/([\w-]+)$/)) && req.method === 'GET') {
      const id = m[1];
      const run = current && current.run.id === id ? current.run : (runFile(id, 'run.json') ? readJSON(runFile(id, 'run.json'), null) : null);
      if (!run) return json(res, 404, {error: 'No such run.'}), true;
      const cases = runFile(id, 'cases.json') ? readJSON(runFile(id, 'cases.json'), {}) : {};
      const notable = Object.fromEntries(Object.entries(cases).filter(([, c]) => c.result === 'fail' || c.unmatched));
      const logs = existsSync(join(runsDir, id)) ? readdirSync(join(runsDir, id)).filter(f => /\.(log|jsonl|json)$/.test(f) && !['run.json', 'cases.json'].includes(f)) : [];
      return json(res, 200, {run, diff: runFile(id, 'diff.json') ? readJSON(runFile(id, 'diff.json'), null) : null, failing: notable, logs,
        caseCounts: Object.values(cases).reduce((a, c) => { a[c.result] = (a[c.result] || 0) + 1; return a; }, {})}), true;
    }
    if ((m = api.match(/^\/runs\/([\w-]+)\/cancel$/)) && req.method === 'POST') return json(res, cancelRun(m[1]) ? 202 : 409, {ok: true}), true;
    if ((m = api.match(/^\/runs\/([\w-]+)\/files\/([\w.-]+)$/)) && req.method === 'GET') {
      const p = runFile(m[1], m[2]);
      if (!p) return json(res, 404, {error: 'No such file.'}), true;
      res.writeHead(200, {'Content-Type': `${m[2].endsWith('.json') ? 'application/json' : 'text/plain'}; charset=utf-8`, 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff'});
      createReadStream(p).pipe(res);
      return true;
    }
    if ((m = api.match(/^\/runs\/([\w-]+)\/report\.(md|json)$/)) && req.method === 'GET') {
      if (!runFile(m[1], 'run.json')) return json(res, 404, {error: 'No such run.'}), true;
      if (m[2] === 'md') { res.writeHead(200, {'Content-Type': 'text/markdown; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Disposition': `attachment; filename="qa-lab-${m[1]}.md"`}); res.end(reportMarkdown(m[1])); }
      else { res.writeHead(200, {'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Disposition': `attachment; filename="qa-lab-${m[1]}.json"`}); res.end(JSON.stringify(reportJSON(m[1]), null, 1)); }
      return true;
    }
    return json(res, 404, {error: 'Unknown QA Lab endpoint.'}), true;
  }

  function close() {
    if (current?.child) killGroup(current.child);
    for (const res of clients) { try { res.end(); } catch { /* closed */ } }
  }
  process.once('exit', close);

  return {handle, close, startRun, cfg, _internals: {compactCatalog, reportMarkdown, environment}};
}
