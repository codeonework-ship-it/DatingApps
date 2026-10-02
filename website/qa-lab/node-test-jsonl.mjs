// node:test reporter that writes one JSON object per finished test, in the
// same shape as qa/lab/qalab_pytest.py, so QA Lab can parse its own
// self-tests (suite "selftest", enabled with QA_LAB_SELFTEST=1).
import {relative} from 'node:path';

export default async function* jsonl(source) {
  for await (const event of source) {
    if (event.type !== 'test:pass' && event.type !== 'test:fail') continue;
    const d = event.data || {};
    if (d.details?.type === 'suite') continue;
    const skipped = Boolean(d.skip || d.todo);
    const outcome = event.type === 'test:fail' ? 'failed' : (skipped ? 'skipped' : 'passed');
    const file = d.file ? relative(process.cwd(), d.file.replace(/^file:\/\//, '')) : '';
    const err = d.details?.error;
    yield `${JSON.stringify({
      nodeid: `${file}::${d.name}`, file: file.split('/').pop(), test: d.name, outcome,
      duration: (d.details?.duration_ms || 0) / 1000, cases: [],
      message: err ? String(err.cause?.message || err.message || err).slice(0, 2000) : '',
    })}\n`;
  }
}
