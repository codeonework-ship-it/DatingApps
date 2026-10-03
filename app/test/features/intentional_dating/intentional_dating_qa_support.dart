// Shared helpers for the Today / Intentional Dating control tests: tearing a
// screen down (so periodic timers and providers are disposed) and a
// per-locale render sweep for the l10n cases.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../swipe/qa_screen_checks.dart';

/// Unmounts the screen so providers with periodic timers dispose.
Future<void> idTeardown(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
}

/// Renders a screen with [pump] in every shipped locale and asserts that
/// the translated [labels] show, that no English UI string leaks, and that
/// nothing renders identically in English and German except [fixture]
/// (member/server content) and [sameInGerman] (translations that really are
/// spelled the same in German, checked against the ARB). [pump] must leave
/// the screen settled.
Future<void> idSweepLocales(
  WidgetTester t, {
  required Future<void> Function(Locale locale) pump,
  required List<String> Function(AppLocalizations l10n) labels,
  Set<String> fixture = const {},
  Set<String> sameInGerman = const {},
}) async {
  List<String>? en;
  List<String>? de;
  for (final locale in qaLocales) {
    await pump(locale);
    expect(t.takeException(), isNull, reason: '$locale');
    final l10n = qaL10n(locale);
    for (final label in labels(l10n)) {
      expect(find.text(label), findsWidgets, reason: '$locale: "$label"');
    }
    qaExpectNoEnglishLeaks(t, locale, allow: fixture);
    if (locale == const Locale('en')) {
      en = qaVisibleStrings(t);
    } else if (locale == const Locale('de')) {
      de = qaVisibleStrings(t);
    }
    await idTeardown(t);
  }
  expect(
    qaUntranslated(en!, de!, fixture: {...fixture, ...sameInGerman}),
    isEmpty,
    reason: 'rendered the same in English and German (hard-coded?)',
  );
}
