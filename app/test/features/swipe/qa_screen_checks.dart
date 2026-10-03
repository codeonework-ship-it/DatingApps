// Screen-level checks shared by the dating control tests (package D):
// accessibility guidelines over a populated screen, layout on phone and
// tablet sizes in both themes, and an English-leak scan for l10n cases.
//
// These run against screens fed by the recording fake BFF (QaApi), so what
// is checked is the screen with real content, not its empty/error state.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Phone and tablet sizes every layout case is checked at.
const qaLayoutSizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x780': Size(360, 780),
  'tablet portrait 768x1024': Size(768, 1024),
  'tablet landscape 1366x1024': Size(1366, 1024),
};

/// The two shipped themes.
final qaLayoutThemes = <String, ThemeData>{
  'light': AppTheme.lightTheme,
  'dark': AppTheme.darkTheme,
};

/// Wraps [child] in [theme] so a screen (and the sheets it opens, which
/// capture inherited themes) renders in that theme under pumpQa.
Widget qaThemed(ThemeData theme, Widget child) =>
    Theme(data: theme, child: child);

/// Runs [pump] at every size in [qaLayoutSizes] and theme in
/// [qaLayoutThemes] and fails on any layout exception (RenderFlex overflow,
/// unbounded constraints...). [check] runs after each pump to assert the
/// screen really rendered its content; [reset] tears the tree down between
/// rounds.
Future<void> qaExpectLayout(
  WidgetTester tester, {
  required Future<void> Function(Size size, ThemeData theme) pump,
  required void Function(String where) check,
  Future<void> Function()? reset,
  Map<String, Size> sizes = qaLayoutSizes,
}) async {
  for (final size in sizes.entries) {
    for (final theme in qaLayoutThemes.entries) {
      final where = '${size.key} [${theme.key}]';
      await pump(size.value, theme.value);
      expect(tester.takeException(), isNull, reason: where);
      check(where);
      if (reset != null) {
        await reset();
      } else {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
    }
  }
}

/// Runs Flutter's tap-target, label and (optionally) contrast guidelines
/// over the current frame. Call after the screen has settled.
Future<void> qaExpectA11y(WidgetTester tester, {bool contrast = true}) async {
  final handle = tester.ensureSemantics();
  await tester.pump();
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  if (contrast) {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }
  handle.dispose();
}

Map<String, String>? _arbCache;

Map<String, String> _arb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

/// English strings that have a different translation in [locale]: if one of
/// these is on screen while the app runs in [locale], it leaked.
Set<String> qaEnglishOnly(String locale) {
  final en = _arbCache ??= _arb('en');
  final other = _arb(locale);
  // "Message" can be one key's English and another key's translation
  // (fr): a value the locale itself uses is never a leak.
  final used = other.values.toSet();
  return {
    for (final e in en.entries)
      if (other[e.key] != null &&
          other[e.key] != e.value &&
          !used.contains(e.value) &&
          e.value.trim().length > 3 &&
          !e.value.contains('{'))
        e.value,
  };
}

/// ARB values that are the same in English and [locale] on purpose
/// (loanwords, brand terms): rendered identically, they are not hard-coded.
Set<String> qaKeptInLocale(String locale) {
  final en = _arbCache ??= _arb('en');
  final other = _arb(locale);
  return {
    for (final e in en.entries)
      if (other[e.key] == e.value) e.value,
  };
}

/// [qaKeptInLocale] as patterns: a kept value with placeholders
/// ("Round {number}" in Italian) matches its rendered form ("Round 1").
/// Plural/select messages contribute each branch ("{count} matches").
List<RegExp> qaKeptPatterns(String locale) {
  final branch = RegExp(r'(?:=\d+|\w+)\{((?:[^{}]|\{[^{}]*\})*)\}');
  final templates = <String>{};
  for (final v in qaKeptInLocale(locale)) {
    if (v.contains(', plural,') || v.contains(', select,')) {
      templates.addAll(branch.allMatches(v).map((m) => m.group(1)!));
    } else {
      templates.add(v);
    }
  }
  // A template that is all placeholders ("{name}", "{count}") would match
  // anything: only templates with real words count.
  bool hasWords(String t) =>
      t
          .replaceAll(RegExp(r'\{[^}]*\}'), '')
          .replaceAll(RegExp('[^A-Za-z]'), '')
          .length >=
      3;
  return [
    for (final t in templates.where(hasWords))
      RegExp(
        '^${t.split(RegExp(r'\{[^}]*\}')).map(RegExp.escape).join('.+')}\$',
      ),
  ];
}

/// Every non-empty string rendered by Text / RichText / EditableText.
List<String> qaVisibleStrings(WidgetTester tester) {
  final out = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    final s = w.data ?? w.textSpan?.toPlainText() ?? '';
    if (s.trim().isNotEmpty) {
      out.add(s.trim());
    }
  }
  for (final e in find.byType(EditableText).evaluate()) {
    final w = e.widget as EditableText;
    if (w.controller.text.trim().isNotEmpty) {
      out.add(w.controller.text.trim());
    }
  }
  return out;
}

/// Fails if any rendered string is an English UI string that has its own
/// translation in [locale] (an English leak). [allow] lists strings that are
/// legitimately the same (names, fixture content).
void qaExpectNoEnglishLeaks(
  WidgetTester tester,
  Locale locale, {
  Set<String> allow = const {},
}) {
  final tag = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
  final english = qaEnglishOnly(tag);
  final leaks = qaVisibleStrings(
    tester,
  ).where((s) => english.contains(s) && !allow.contains(s)).toSet();
  expect(leaks, isEmpty, reason: 'English strings rendered in $tag: $leaks');
}

/// Strings rendered identically in English ([en]) and another locale
/// ([other]) that are neither fixture data ([fixture], matched as a
/// substring either way) nor letter-free (numbers, emoji, punctuation):
/// these are hard-coded. Render the same screen in `en` and the other
/// locale, collect [qaVisibleStrings] each time, and expect this empty.
Set<String> qaUntranslated(
  List<String> en,
  List<String> other, {
  Set<String> fixture = const {},
}) {
  final letters = RegExp(r'[A-Za-z]{2,}');
  bool isFixture(String s) =>
      fixture.any((f) => s == f || s.contains(f) || f.contains(s));
  return en
      .toSet()
      .intersection(other.toSet())
      .where((s) => letters.hasMatch(s) && !isFixture(s))
      .toSet();
}

/// Renders a screen in English and then in every other shipped locale and,
/// per locale: runs [check] (assert the translated labels you expect), fails
/// on any layout exception, on an English leak ([qaExpectNoEnglishLeaks]),
/// and, for non-English languages, on any string identical to the English
/// render that is not fixture data ([qaUntranslated]: hard-coded text).
Future<void> qaExpectTranslated(
  WidgetTester tester, {
  required Future<void> Function(Locale locale) pump,
  required void Function(AppLocalizations l10n, String where) check,
  Set<String> fixture = const {},
  Future<void> Function()? reset,
}) async {
  Future<void> tearDownTree() async {
    if (reset != null) {
      await reset();
    } else {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }

  await pump(const Locale('en'));
  expect(tester.takeException(), isNull, reason: 'en');
  check(lookupAppLocalizations(const Locale('en')), 'en');
  final english = qaVisibleStrings(tester);
  await tearDownTree();
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale == const Locale('en')) {
      continue;
    }
    final where = locale.toString();
    await pump(locale);
    expect(tester.takeException(), isNull, reason: where);
    check(lookupAppLocalizations(locale), where);
    qaExpectNoEnglishLeaks(tester, locale, allow: fixture);
    if (locale.languageCode != 'en') {
      // Strings the translators deliberately kept (a loanword such as
      // "Spotlight" in German) are translations, not leaks.
      final kept = qaKeptPatterns(locale.languageCode);
      expect(
        qaUntranslated(
          english,
          qaVisibleStrings(tester),
          fixture: fixture,
        ).where((s) => !kept.any((k) => k.hasMatch(s))).toSet(),
        isEmpty,
        reason: 'strings not translated in $where',
      );
    }
    await tearDownTree();
  }
}
