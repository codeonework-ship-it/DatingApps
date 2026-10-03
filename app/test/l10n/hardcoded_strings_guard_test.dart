import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_strings_baseline.dart';
import 'ui_literal_scanner.dart';

// Guards the app's localisation: user-facing text lives in lib/l10n/*.arb,
// not in widgets or providers.
//
// ui_literal_scanner.dart finds, in every file under lib/:
//  * string literals shown as text: `Text('…')`, a UI argument such as
//    `title:` / `hint:` / `helpText:` / `cancelText:` / `barrierLabel:`, and
//    either branch of a ternary or a `??` fallback in those places. Lower-case
//    sentences and words with apostrophes count too;
//  * automation ids used as spoken labels (`label: 'qa.…'`, `label: qaId`);
//  * raw exception text in UI (`Text(e.toString())`, `content: Text('$e')`);
//  * dropdown items shown as their raw stored value.
//
// The baseline (hardcoded_strings_baseline.dart) lists every remaining literal
// one by one, file and exact text, each with the reason it may stay: a brand
// name, mock/demo data, a debug or sandbox-only surface, or an English
// message code that a screen translates when it shows it. The match is exact
// per string, so removing one literal and adding another cannot cancel out,
// and an entry that no longer matches must be deleted.
//
// New user-facing text: add it with
// `python3 app/tool/l10n_add.py <batch.json>` (all 10 locales).

String _key(String file, UiLiteral literal) =>
    '$file\u0000${literal.kind}\u0000${literal.text}';

void main() {
  test('no hard-coded user-facing strings outside the baseline', () {
    final found = <String, int>{};
    final where = <String, List<int>>{};
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.startsWith('lib/l10n') &&
                  !f.path.endsWith('.g.dart') &&
                  !f.path.endsWith('.freezed.dart'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      for (final literal in scanUiLiterals(file.readAsStringSync())) {
        final key = _key(file.path, literal);
        found[key] = (found[key] ?? 0) + 1;
        (where[key] ??= []).add(literal.line);
      }
    }

    final allowed = <String, int>{};
    for (final entry in hardcodedStringsBaseline) {
      expect(entry.reason.trim(), isNotEmpty, reason: entry.text);
      expect(
        entry.kind,
        'text',
        reason:
            'qa ids as labels, raw errors and raw dropdown items are never '
            'baselined: ${entry.file} ${entry.text}',
      );
      final key = '${entry.file}\u0000${entry.kind}\u0000${entry.text}';
      allowed[key] = (allowed[key] ?? 0) + 1;
    }

    String show(String key) {
      final parts = key.split('\u0000');
      return '${parts[0]}:${where[key]?.join(',') ?? '-'} [${parts[1]}] '
          '${jsonEncode(parts[2])}';
    }

    final unexpected = [
      for (final key in found.keys)
        if ((found[key] ?? 0) > (allowed[key] ?? 0))
          '${show(key)} (found ${found[key]}, allowed ${allowed[key] ?? 0})',
    ];
    final stale = [
      for (final key in allowed.keys)
        if ((found[key] ?? 0) < allowed[key]!)
          '${show(key)} (found ${found[key] ?? 0}, baseline ${allowed[key]})',
    ];
    expect(
      unexpected,
      isEmpty,
      reason:
          'Move these strings into lib/l10n/*.arb (python3 app/tool/'
          'l10n_add.py), or baseline a true exception with its reason',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'These baseline entries no longer match the source; delete them '
          'from hardcoded_strings_baseline.dart',
    );
  });

  group('the scanner catches', () {
    List<String> scan(String source) =>
        scanUiLiterals(source).map((l) => '${l.kind}:${l.text}').toList();

    test('Text and UI arguments, lower-case and apostrophes', () {
      expect(
        scan('''
Widget a() => Column(children: [
  Text('Hello there'),
  const Text("Save"),
  Text('sign in to continue'),
  TextField(decoration: InputDecoration(hintText: "don't share this")),
  showDatePicker(helpText: 'Pick a day', cancelText: 'Not now'),
  showGeneralDialog(barrierLabel: 'Dismiss'),
  Tooltip(message: 'More options'),
]);
'''),
        [
          'text:Hello there',
          'text:Save',
          'text:sign in to continue',
          "text:don't share this",
          'text:Pick a day',
          'text:Not now',
          'text:Dismiss',
          'text:More options',
        ],
      );
    });

    test('ternary branches and ?? fallbacks', () {
      expect(
        scan('''
Widget a(bool busy, String? name) => ListTile(
  title: Text(busy ? 'Saving' : 'Save changes'),
  subtitle: Text(name ?? 'Your match'),
  trailing: Text(busy ? l.wait : 'Ready now'),
);
'''),
        [
          'text:Saving',
          'text:Save changes',
          'text:Your match',
          'text:Ready now',
        ],
      );
    });

    test('qa ids as spoken labels', () {
      expect(
        scan('''
Widget a(String qaId) => Column(children: [
  Semantics(label: 'qa.welcome.signup_button', child: b),
  Icon(Icons.add, semanticLabel: 'qa.icon'),
  Semantics(label: qaId, child: b),
  Semantics(identifier: 'qa.fine', label: l.save, child: b),
]);
'''),
        [
          'qa-label:qa.welcome.signup_button',
          'qa-label:qa.icon',
          'qa-label:label: qaId',
        ],
      );
    });

    test('raw exception text and raw dropdown items', () {
      expect(
        scan(r'''
Widget a(Object e) => Column(children: [
  Text(e.toString()),
  SnackBar(content: Text('$e')),
  ErrorState(message: error.toString()),
  DropdownMenuItem<String>(value: item, child: Text(item)),
  GlassDropdown(labelBuilder: (v) => v, items: xs),
]);
'''),
        [
          'raw-error:Text(e.toString()',
          'raw-error:message: error.toString()',
          r'raw-error:$e',
          'raw-dropdown:DropdownMenuItem<String>(value: item, child: Text(item)',
          'raw-dropdown:labelBuilder: (v) => v,',
        ],
      );
    });

    test('but not codes, keys, comparisons, comments or logs', () {
      expect(
        scan(r'''
// Text('Commented out')
Widget a(String v) => Column(children: [
  Text(v == 'Never' ? l.never : l.other),
  Container(key: ValueKey('qa.screen.button')),
  Text(l.title),
  Text('$count'),
  Text('${a.name} · ${b.name}'),
  Image.asset('assets/images/a.png'),
  Chip(label: Text(code)),
  Tag(label: 'long_term'),
]);
void b() { log.error('Failed to load the thing', e); }
final m = {'title': 'Map value'};
'''),
        isEmpty,
      );
    });
  });

  test('every locale has every key', () {
    Set<String> keys(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((k) => !k.startsWith('@'))
            .toSet();
    final english = keys('en');
    for (final locale in const [
      'en_GB',
      'de',
      'fr',
      'ru',
      'es',
      'it',
      'pt',
      'nl',
      'pl',
    ]) {
      expect(english.difference(keys(locale)), isEmpty, reason: locale);
    }
  });
}
