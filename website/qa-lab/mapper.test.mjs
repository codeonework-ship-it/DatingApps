// Unit tests for the QA Lab result mapper and tag parser.
//   node --test website/qa-lab/mapper.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import * as M from './mapper.mjs';

const ROOT = '/repo';

test('tagsInName reads one or several [case:...] tags and ignores junk', () => {
  assert.deepEqual(M.tagsInName('sign in works [case:auth.signin.action]'), ['auth.signin.action']);
  assert.deepEqual(M.tagsInName('x [case:a.b] [case: c.d ] [case:a.b]'), ['a.b', 'c.d']);
  assert.deepEqual(M.tagsInName('shorthand [case:a.b, c.d e.f]'), ['a.b', 'c.d', 'e.f']);
  assert.deepEqual(M.tagsInName('no tags here [case:] [case:bad id!]'), ['bad']);
  assert.equal(M.stripTags('Love works [case:a.b] [case:c]'), 'Love works');
});

test('Flutter --machine events become results with group names and tags', () => {
  const lines = [
    '{"suite":{"id":0,"platform":"vm","path":"/repo/app/test/x_test.dart"},"type":"suite","time":0}',
    '{"test":{"id":1,"name":"loading /repo/app/test/x_test.dart","suiteID":0,"groupIDs":[]},"type":"testStart","time":1}',
    '[{"event":"test.startedProcess","params":{"vmServiceUri":null}}]',
    '{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":900}',
    '{"test":{"id":4,"name":"Dock Love sends one like [case:swipe.profile_details.love.action]","suiteID":0,"groupIDs":[2,3]},"type":"testStart","time":900}',
    '{"testID":4,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":950}',
    '{"test":{"id":5,"name":"Dock Message opens chat","suiteID":0,"groupIDs":[2,3]},"type":"testStart","time":950}',
    '{"testID":5,"error":"Expected: exactly one matching candidate","stackTrace":"at x_test.dart:20","isFailure":true,"type":"error","time":960}',
    '{"testID":5,"result":"failure","skipped":false,"hidden":false,"type":"testDone","time":961}',
    '{"test":{"id":6,"name":"Dock Undo is skipped","suiteID":0,"groupIDs":[2,3]},"type":"testStart","time":961}',
    '{"testID":6,"result":"success","skipped":true,"hidden":false,"type":"testDone","time":962}',
    '{"success":false,"type":"done","time":970}',
  ].join('\n');
  const r = M.parseFlutterMachine(lines, {root: ROOT});
  assert.equal(r.length, 3, 'hidden loading pseudo-test is dropped');
  assert.deepEqual(r.map(x => x.status), ['passed', 'failed', 'skipped']);
  assert.equal(r[0].file, 'app/test/x_test.dart');
  assert.deepEqual(r[0].cases, ['swipe.profile_details.love.action']);
  assert.equal(r[0].durationMs, 50);
  assert.match(r[1].message, /exactly one matching candidate/);
});

test('a Flutter file that fails to load is reported as a failure', () => {
  const lines = [
    '{"suite":{"id":0,"platform":"vm","path":"/repo/app/test/broken_test.dart"},"type":"suite","time":0}',
    '{"test":{"id":1,"name":"loading /repo/app/test/broken_test.dart","suiteID":0,"groupIDs":[]},"type":"testStart","time":1}',
    '{"testID":1,"error":"Compilation failed","isFailure":false,"type":"error","time":5}',
    '{"testID":1,"result":"error","skipped":false,"hidden":true,"type":"testDone","time":6}',
  ].join('\n');
  const [r] = M.parseFlutterMachine(lines, {root: ROOT});
  assert.equal(r.status, 'failed');
  assert.match(r.message, /Compilation failed/);
});

test('flutterLogLine counts passes and logs only failures and skips', () => {
  const st = {names: new Map(), done: 0, passed: 0, failed: 0, skipped: 0, total: 0};
  assert.equal(M.flutterLogLine(st, '{"count":2,"type":"allSuites"}'), 'flutter: 2 test files');
  M.flutterLogLine(st, '{"test":{"id":4,"name":"ok test"},"type":"testStart"}');
  assert.equal(M.flutterLogLine(st, '{"testID":4,"result":"success","skipped":false,"hidden":false,"type":"testDone"}'), null);
  M.flutterLogLine(st, '{"test":{"id":5,"name":"bad test"},"type":"testStart"}');
  assert.equal(M.flutterLogLine(st, '{"testID":5,"result":"failure","hidden":false,"type":"testDone"}'), '✗ bad test');
  assert.deepEqual([st.done, st.passed, st.failed], [2, 1, 1]);
});

test('Playwright JSON: describe titles, flaky = pass, skipped, failures, tags', () => {
  const json = {
    config: {rootDir: '/repo/website/tests'},
    suites: [{title: 'chat.spec.js', file: 'chat.spec.js', specs: [
      {title: 'sends a message [case:messaging.chat.send.action]', ok: true, tests: [{status: 'expected', results: [{status: 'passed', duration: 1200}]}]},
    ], suites: [{title: 'gifts', file: 'chat.spec.js', specs: [
      {title: 'free rose', ok: true, tests: [{status: 'flaky', results: [{status: 'failed', duration: 10}, {status: 'passed', duration: 20}]}]},
      {title: 'paid gift', ok: false, tests: [{status: 'unexpected', results: [{status: 'failed', duration: 5, error: {message: '\u001b[31mExpected 200\u001b[39m'}}]}]},
      {title: 'later', ok: true, tests: [{status: 'skipped', results: [{status: 'skipped'}]}]},
    ]}]}],
    errors: [],
  };
  const r = M.parsePlaywrightJson(json, {root: ROOT});
  assert.deepEqual(r.map(x => [x.test, x.status]), [
    ['sends a message [case:messaging.chat.send.action]', 'passed'],
    ['gifts > free rose', 'passed'],
    ['gifts > paid gift', 'failed'],
    ['gifts > later', 'skipped'],
  ]);
  assert.equal(r[0].file, 'website/tests/chat.spec.js');
  assert.deepEqual(r[0].cases, ['messaging.chat.send.action']);
  assert.equal(r[1].flaky, true);
  assert.equal(r[2].message, 'Expected 200', 'ANSI colour codes are stripped');
});

test('pytest JSONL (qalab_pytest plugin) maps markers and outcomes', () => {
  const text = [
    '{"nodeid":"tests/test_02.py::test_like","file":"tests/test_02.py","test":"test_like","outcome":"passed","duration":0.5,"cases":["swipe.like.api_contract"]}',
    '{"nodeid":"tests/test_02.py::test_x[a]","file":"tests/test_02.py","test":"test_x[a]","outcome":"error","duration":0.1,"cases":[],"message":"setup failed"}',
    '{"nodeid":"tests/test_02.py::TestK::test_y","file":"tests/test_02.py","test":"TestK::test_y","outcome":"skipped","duration":0,"cases":["a.b, c.d"]}',
    'garbage',
  ].join('\n');
  const r = M.parsePytestJsonl(text, {suite: 'api_e2e', suiteDir: 'qa/api_e2e'});
  assert.deepEqual(r.map(x => [x.func, x.status]), [['test_like', 'passed'], ['test_x', 'failed'], ['test_y', 'skipped']]);
  assert.equal(r[0].file, 'qa/api_e2e/tests/test_02.py');
  assert.deepEqual(r[2].cases, ['a.b', 'c.d']);
});

test('Go test2json: top-level tests, subtests roll up, build failures surface', () => {
  const mod = 'github.com/acme/backend';
  const ev = o => JSON.stringify(o);
  const text = [
    ev({Action: 'run', Package: `${mod}/internal/bff/mobile`, Test: 'TestSwipe'}),
    ev({Action: 'output', Package: `${mod}/internal/bff/mobile`, Test: 'TestSwipe/sub', Output: '    swipe_test.go:9: boom\n'}),
    ev({Action: 'fail', Package: `${mod}/internal/bff/mobile`, Test: 'TestSwipe/sub', Elapsed: 0.1}),
    ev({Action: 'fail', Package: `${mod}/internal/bff/mobile`, Test: 'TestSwipe', Elapsed: 0.2}),
    ev({Action: 'pass', Package: `${mod}/internal/bff/mobile`, Test: 'TestLogin', Elapsed: 0}),
    ev({Action: 'output', Package: `${mod}/internal/broken`, Output: 'syntax error\n'}),
    ev({Action: 'fail', Package: `${mod}/internal/broken`, Elapsed: 0}),
  ].join('\n');
  const idx = new Map([['backend/internal/bff/mobile::TestLogin', {file: 'backend/internal/bff/mobile/auth_test.go', cases: ['auth.signin.api_contract']}]]);
  const r = M.parseGoJson(text, {modulePath: mod, caseIndex: idx});
  const by = Object.fromEntries(r.map(x => [`${x.pkgDir}::${x.test}`, x]));
  assert.equal(by['backend/internal/bff/mobile::TestSwipe'].status, 'failed');
  assert.match(by['backend/internal/bff/mobile::TestSwipe'].message, /boom/);
  assert.deepEqual(by['backend/internal/bff/mobile::TestLogin'].cases, ['auth.signin.api_contract']);
  assert.equal(by['backend/internal/bff/mobile::TestLogin'].file, 'backend/internal/bff/mobile/auth_test.go');
  assert.equal(by['backend/internal/broken::(package)'].status, 'failed');
  assert.equal(r.filter(x => x.test.includes('/')).length, 0);
});

test('Go and Django comment tags directly above the test', () => {
  const go = [
    'package mobile', '', '// case: auth.signin.api_contract', '// case: auth.signin.negative, auth.x', 'func TestLogin(t *testing.T) {', '}',
    '', '// unrelated', 'func helper() {}', '// case: not.this.one', '', 'func TestNoTag(t *testing.T) {}',
  ].join('\n');
  assert.deepEqual(M.goCaseComments(go), [
    {test: 'TestLogin', cases: ['auth.signin.api_contract', 'auth.signin.negative', 'auth.x'], line: 5},
    {test: 'TestNoTag', cases: [], line: 12},
  ]);
  const py = [
    'class LoginTest(TestCase):', '    # case: console.auth.login.renders', '    @override_settings(X=1)', '    def test_login_page(self):', '        pass',
    '', '    def test_other(self):', '        pass', '', 'class Other(TestCase):', '    # case: console.x.y', '    def test_z(self):', '        pass',
  ].join('\n');
  assert.deepEqual(M.djangoCaseComments(py), [
    {test: 'LoginTest.test_login_page', cases: ['console.auth.login.renders'], line: 4},
    {test: 'LoginTest.test_other', cases: [], line: 7},
    {test: 'Other.test_z', cases: ['console.x.y'], line: 12},
  ]);
});

test('Django -v 2 output, including docstring lines and failure tracebacks', () => {
  const text = [
    'Creating test database for alias \'default\'...',
    'test_login_page (control_panel.tests.test_auth.LoginTest.test_login_page) ... ok',
    'test_save (control_panel.tests.test_auth.LoginTest.test_save)',
    'Saving keeps the audit row. ... FAIL',
    'test_skip (control_panel.tests.test_auth.LoginTest.test_skip) ... skipped \'later\'',
    '======================================================================',
    'FAIL: test_save (control_panel.tests.test_auth.LoginTest.test_save)',
    '----------------------------------------------------------------------',
    'AssertionError: 302 != 200',
    '----------------------------------------------------------------------',
    'Ran 3 tests in 0.1s',
  ].join('\n');
  const idx = new Map([['control-panel/control_panel/tests/test_auth.py::LoginTest.test_login_page', ['console.auth.login.renders']]]);
  const r = M.parseDjangoVerbose(text, {caseIndex: idx});
  assert.deepEqual(r.map(x => [x.test, x.status]), [['LoginTest.test_login_page', 'passed'], ['LoginTest.test_save', 'failed'], ['LoginTest.test_skip', 'skipped']]);
  assert.equal(r[0].file, 'control-panel/control_panel/tests/test_auth.py');
  assert.deepEqual(r[0].cases, ['console.auth.login.renders']);
  assert.match(r[1].message, /302 != 200/);
});

test('namePattern turns Dart interpolation into wildcards and escapes the rest', () => {
  const re = new RegExp(`^${M.namePattern('$screenLabel lays out on ${device.label} [$themeLabel]')}$`);
  assert.ok(re.test('HomeDiscoveryScreen lays out on phone 375x812 [Ember]'));
  assert.ok(!re.test('HomeDiscoveryScreen lays out on phone'));
  assert.ok(new RegExp(`^${M.namePattern("can\\'t (really) do it?")}$`).test("can't (really) do it?"));
});

test('refMatches per suite', () => {
  const fl = {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock > Love sends one like'};
  assert.ok(M.refMatches(fl, {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock Love sends one like'}));
  assert.ok(M.refMatches(fl, {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Outer Dock Love sends one like'}));
  assert.ok(!M.refMatches(fl, {suite: 'flutter', file: 'app/test/b_test.dart', test: 'Dock Love sends one like'}));
  const pw = {suite: 'playwright', file: 'website/tests/c.spec.js', test: 'free rose'};
  assert.ok(M.refMatches(pw, {suite: 'playwright', file: 'website/tests/c.spec.js', test: 'gifts > free rose'}));
  const py = {suite: 'api_e2e', file: 'qa/api_e2e/tests/t.py', test: 'test_like'};
  assert.ok(M.refMatches(py, {suite: 'api_e2e', file: 'qa/api_e2e/tests/t.py', test: 'test_like[x]', func: 'test_like'}));
  const go = {suite: 'go', file: 'backend/internal/bff/mobile/swipe_test.go', test: 'TestSwipe'};
  assert.ok(M.refMatches(go, {suite: 'go', file: 'backend/internal/bff/mobile', pkgDir: 'backend/internal/bff/mobile', test: 'TestSwipe'}));
  const smoke = {suite: 'django', file: 'qa/console_smoke/test_console_smoke.py', test: 'test_nav_page_loads_cleanly'};
  assert.equal(M.refSuite(smoke), 'console_smoke');
  assert.ok(M.refMatches(smoke, {suite: 'console_smoke', file: 'qa/console_smoke/test_console_smoke.py', func: 'test_nav_page_loads_cleanly', test: 'test_nav_page_loads_cleanly[/users/]'}));
});

function sampleCatalog() {
  return {features: [
    {id: 'swipe.profile_details', area: 'Discover', cases: [
      {id: 'swipe.profile_details.love.action', status: 'not_automated', automated_by: []},
      {id: 'swipe.profile_details.message.action', status: 'automated', mapped_by: 'heuristic', automated_by: [{suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock > Message opens chat'}]},
      {id: 'swipe.profile_details.undo.action', status: 'automated', automated_by: [{suite: 'go', file: 'backend/x/undo_test.go', test: 'TestUndo'}]},
      {id: 'swipe.profile_details.layout', status: 'presence_only', automated_by: []},
    ]},
    {id: 'calls.call', area: 'Calls', cases: [
      {id: 'calls.call.audio', status: 'manual', manual_reason: 'needs two devices', automated_by: []},
      {id: 'calls.call.video', status: 'manual', automated_by: []},
    ]},
  ]};
}

test('evaluateCases: tags upgrade status, heuristics match, not_run vs unmatched', () => {
  const results = [
    {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock Love sends one like [case:swipe.profile_details.love.action]', status: 'passed', cases: ['swipe.profile_details.love.action']},
    {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock Message opens chat', status: 'failed', cases: [], message: 'nope'},
    {suite: 'flutter', file: 'app/test/z_test.dart', test: 'orphan [case:does.not.exist]', status: 'passed', cases: ['does.not.exist']},
  ];
  const {cases, unknownTags} = M.evaluateCases(sampleCatalog(), results, {suitesRun: new Set(['flutter'])});
  assert.equal(cases['swipe.profile_details.love.action'].result, 'pass');
  assert.equal(cases['swipe.profile_details.love.action'].via, 'tag');
  assert.equal(cases['swipe.profile_details.message.action'].result, 'fail');
  assert.equal(cases['swipe.profile_details.undo.action'].result, 'not_run');
  assert.equal(cases['swipe.profile_details.undo.action'].unmatched, undefined, 'go did not run, so not a mapping problem');
  assert.equal(cases['swipe.profile_details.layout'].result, 'presence_only');
  assert.equal(cases['calls.call.audio'].result, 'manual');
  assert.deepEqual(unknownTags, ['does.not.exist']);
  const again = M.evaluateCases(sampleCatalog(), [], {suitesRun: new Set(['go'])});
  assert.equal(again.cases['swipe.profile_details.undo.action'].unmatched, true, 'go ran but the mapped test was not found');
});

test('ledger keeps the latest executed result; coverage and gate metric', () => {
  const cat = sampleCatalog();
  const run1 = M.evaluateCases(cat, [
    {suite: 'flutter', file: 'app/test/a_test.dart', test: 'Dock Message opens chat', status: 'passed', cases: []},
    {suite: 'go', file: 'backend/x', pkgDir: 'backend/x', test: 'TestUndo', status: 'failed', cases: []},
  ]).cases;
  let led = M.mergeLedger({}, run1, {runId: 'r1', at: 't1'});
  assert.equal(led['swipe.profile_details.message.action'].result, 'pass');
  assert.equal(led['swipe.profile_details.undo.action'].result, 'fail');
  const run2 = M.evaluateCases(cat, [{suite: 'go', file: 'backend/x', pkgDir: 'backend/x', test: 'TestUndo', status: 'passed', cases: []}]).cases;
  led = M.mergeLedger(led, run2, {runId: 'r2', at: 't2'});
  assert.equal(led['swipe.profile_details.message.action'].run, 'r1', 'a partial run keeps earlier results');
  assert.equal(led['swipe.profile_details.undo.action'].run, 'r2');
  const marks = M.latestManual({'calls.call.audio': [{result: 'fail'}, {result: 'pass', by: 'op'}]});
  const cov = M.coverage(cat, led, marks);
  assert.equal(cov.all.total, 6);
  assert.equal(cov.all.automated, 2);
  assert.equal(cov.all.passing, 2);
  assert.equal(cov.all.manualChecked, 1);
  assert.equal(cov.all.verified, 3);
  assert.equal(cov.all.verifiedPct, 50);
  assert.equal(cov.chips['calls.call.video'], 'manual_unchecked');
  assert.equal(cov.chips['swipe.profile_details.love.action'], 'not_automated');
  assert.equal(cov.byArea.Calls.manual, 2);
  assert.equal(cov.bySuite.go.passing, 1);
});

test('diffRuns classifies fixed, regressed, new and dropped cases', () => {
  const d = M.diffRuns(
    {a: {result: 'fail'}, b: {result: 'pass'}, c: {result: 'not_run'}, e: {result: 'pass'}},
    {a: {result: 'pass'}, b: {result: 'fail'}, c: {result: 'pass'}, d: {result: 'fail'}, e: {result: 'not_run'}},
  );
  assert.deepEqual(d, {fixed: ['a'], regressed: ['b'], newlyPassing: ['c'], newlyFailing: ['d'], noLongerRun: ['e']});
});

test('selectionForCases groups the tests to run per suite', () => {
  const sel = M.selectionForCases(sampleCatalog(), ['swipe.profile_details.message.action', 'swipe.profile_details.undo.action']);
  assert.deepEqual([...sel.flutter.files], ['app/test/a_test.dart']);
  assert.deepEqual([...sel.go.packages], ['backend/x']);
  assert.deepEqual([...sel.go.names], ['TestUndo']);
});
