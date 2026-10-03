// Screen-level quality checks for the account, profile, verification,
// payments, safety, calls, friends and graduation tests: layout on phone and
// tablet sizes in both shipped themes, Flutter's accessibility guidelines, a
// visible way back that really returns to the opener, and rendering in every
// shipped locale with no English left over.
//
// Every check pumps the real screen against the recording fake BFF
// (qa_api.dart) and must be told what only shows once the screen's data has
// arrived (`loaded`), so a screen is judged with its content, never on a
// spinner or an empty error state.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import 'qa_api.dart';

/// Phone and tablet sizes a layout case is checked at.
const qaQualitySizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 390x844': Size(390, 844),
  'tablet portrait 768x1024': Size(768, 1024),
  'tablet landscape 1366x1024': Size(1366, 1024),
};

/// Both shipped themes.
final qaQualityThemes = <String, ThemeData>{
  'light': AppTheme.lightTheme,
  'dark': AppTheme.darkTheme,
};

/// Pumps [child] like `pumpQa` does, in [theme]. With [launcher] the screen
/// is pushed from a launcher page and what it pops with is added to the
/// returned list.
Future<List<Object?>> qaQualityPump(
  WidgetTester tester,
  QaApi api,
  Widget child, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  Locale? locale,
  List<Override> extra = const [],
  String userId = 'me',
  String accountKind = 'dating',
  Map<String, bool> flags = const {},
  bool launcher = false,
  int frames = 10,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <Object?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: qaOverrides(
        api,
        userId: userId,
        accountKind: accountKind,
        flags: flags,
        extra: extra,
      ),
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: launcher
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      key: const ValueKey('qa.test.launcher'),
                      onPressed: () async => results.add(
                        await Navigator.of(context).push<Object?>(
                          MaterialPageRoute(builder: (_) => child),
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              )
            : child,
      ),
    ),
  );
  if (launcher) {
    await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
  }
  await qaSettle(tester, frames: frames);
  return results;
}

/// Unmounts the app and lets screen timers run out.
Future<void> qaQualityUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

/// Pumps the screen at every [sizes] entry in both themes and fails on any
/// exception (a RenderFlex overflow is one). A fresh fake server comes from
/// [api] for every pump; [loaded] must find something that only shows once
/// the screen's data has arrived.
Future<void> qaExpectLaysOutOnPhoneAndTablet(
  WidgetTester tester, {
  required QaApi Function() api,
  required Widget Function() build,
  required Finder Function() loaded,
  List<Override> Function()? extra,
  Map<String, Size> sizes = qaQualitySizes,
  String accountKind = 'dating',
  int frames = 10,
}) async {
  for (final theme in qaQualityThemes.entries) {
    for (final device in sizes.entries) {
      final where = '${device.key} [${theme.key}]';
      await qaQualityPump(
        tester,
        api(),
        build(),
        theme: theme.value,
        size: device.value,
        extra: extra?.call() ?? const [],
        accountKind: accountKind,
        frames: frames,
      );
      expect(tester.takeException(), isNull, reason: where);
      // Scroll the screen's main list to its end so rows below the fold are
      // laid out (and checked) too.
      var found = loaded().evaluate().isNotEmpty;
      await qaScrollThrough(tester, onStep: () {
        expect(tester.takeException(), isNull, reason: '$where (scrolled)');
        found = found || loaded().evaluate().isNotEmpty;
      });
      expect(found, isTrue, reason: 'content did not load on $where');
      await qaQualityUnmount(tester);
    }
  }
}

/// Jumps the tallest vertical scrollable on screen down to its end, a
/// viewport at a time, calling [onStep] after each frame.
Future<void> qaScrollThrough(
  WidgetTester tester, {
  required FutureOr<void> Function() onStep,
  int maxSteps = 30,
}) async {
  ScrollableState? main;
  var best = 0.0;
  for (final e in find.byType(Scrollable).evaluate()) {
    final state = (e as StatefulElement).state as ScrollableState;
    if (state.axisDirection != AxisDirection.down || !state.position.hasContentDimensions) {
      continue;
    }
    final extent = state.position.maxScrollExtent;
    if (extent > best) {
      best = extent;
      main = state;
    }
  }
  if (main == null) return;
  final position = main.position;
  for (var i = 0; i < maxSteps && position.pixels < position.maxScrollExtent; i++) {
    position.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await onStep();
  }
}

/// Runs Flutter's tap-target (48x48), labelled-tap-target and text-contrast
/// guidelines over the loaded screen on a phone, in both themes, on every
/// viewport of its main list (scrolled top to bottom).
Future<void> qaExpectMeetsA11yGuidelines(
  WidgetTester tester, {
  required QaApi Function() api,
  required Widget Function() build,
  required Finder Function() loaded,
  List<Override> Function()? extra,
  Size size = const Size(390, 844),
  String accountKind = 'dating',
  int frames = 10,
}) async {
  final semantics = tester.ensureSemantics();
  for (final theme in qaQualityThemes.entries) {
    await qaQualityPump(
      tester,
      api(),
      build(),
      theme: theme.value,
      size: size,
      extra: extra?.call() ?? const [],
      accountKind: accountKind,
      frames: frames,
    );
    final where = theme.key;
    Future<void> check(String part) async {
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrastGuideline,
      ]) {
        final result = await guideline.evaluate(tester);
        expect(
          result.passed,
          isTrue,
          reason: '${guideline.description} [$where$part]:\n${result.reason}',
        );
      }
    }

    // Judge every viewport of the screen's main list, top to bottom.
    var found = loaded().evaluate().isNotEmpty;
    await check('');
    var step = 0;
    await qaScrollThrough(tester, onStep: () async {
      step++;
      found = found || loaded().evaluate().isNotEmpty;
      await check(', scrolled x$step');
    });
    expect(found, isTrue, reason: 'content did not load [$where]');
    await qaQualityUnmount(tester);
  }
  semantics.dispose();
}

/// The visible back or close control of the screen [screen] (a BackButton,
/// CloseButton, the design system's GoldBackButton, or an IconButton with the
/// back/close tooltip or icon).
Finder qaBackControl(WidgetTester tester, Finder screen) {
  final strings = MaterialLocalizations.of(tester.element(screen));
  final icons = <IconData>{
    Icons.arrow_back,
    Icons.arrow_back_rounded,
    Icons.arrow_back_ios,
    Icons.arrow_back_ios_new,
    Icons.arrow_back_ios_new_rounded,
    Icons.close,
    Icons.close_rounded,
    Icons.chevron_left,
    Icons.chevron_left_rounded,
  };
  return find
      .descendant(
        of: screen,
        matching: find.byWidgetPredicate(
          (w) =>
              w is BackButton ||
              w is CloseButton ||
              w is GoldBackButton ||
              (w is IconButton &&
                  (w.tooltip == strings.backButtonTooltip ||
                      w.tooltip == strings.closeButtonTooltip ||
                      (w.icon is Icon && icons.contains((w.icon as Icon).icon)))),
        ),
      )
      .hitTestable();
}

/// Pushes the screen from a launcher, checks a back (or close) control is
/// visible, taps it and asserts the screen closed, the opener is showing
/// again and the route popped exactly once. Pass [back] when the screen's
/// way back is a custom control (it must still be visible and tappable).
Future<void> qaExpectBackReturnsToOpener(
  WidgetTester tester, {
  required QaApi api,
  required Widget Function() build,
  required Finder screen,
  Finder? back,
  Finder? loaded,
  List<Override> extra = const [],
  String accountKind = 'dating',
  int frames = 10,
}) async {
  final results = await qaQualityPump(
    tester,
    api,
    build(),
    launcher: true,
    extra: extra,
    accountKind: accountKind,
    frames: frames,
  );
  expect(screen, findsOneWidget);
  if (loaded != null) {
    expect(loaded, findsWidgets, reason: 'content did not load');
  }
  final control = (back ?? qaBackControl(tester, screen)).hitTestable();
  expect(control, findsWidgets, reason: 'no visible back or close control');
  await tester.tap(control.first);
  await qaSettle(tester, frames: frames);
  expect(screen, findsNothing, reason: 'Back did not close the screen');
  expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
  expect(results, hasLength(1), reason: 'the route popped once');
  await qaQualityUnmount(tester);
}

/// Every string the screen paints (Text, RichText and text fields), trimmed.
Set<String> qaPaintedStrings(WidgetTester tester) {
  final out = <String>{};
  for (final e in find.byType(Text).evaluate()) {
    final t = e.widget as Text;
    final s = t.data ?? t.textSpan?.toPlainText() ?? '';
    if (s.trim().isNotEmpty) out.add(s.trim());
  }
  for (final e in find.byType(RichText).evaluate()) {
    final s = (e.widget as RichText).text.toPlainText();
    if (s.trim().isNotEmpty) out.add(s.trim());
  }
  for (final e in find.byType(EditableText).evaluate()) {
    final s = (e.widget as EditableText).controller.text;
    if (s.trim().isNotEmpty) out.add(s.trim());
  }
  return out;
}

final _words = RegExp(r'[A-Za-z]{2,}');

/// Renders the screen in every shipped locale. In each one the [expected]
/// strings (from that locale's AppLocalizations) must be on screen with no
/// exception, and outside English no string the English render painted may
/// appear unchanged (a hard-coded or untranslated label), except the
/// [allow]ed ones (member data from the fixture, brand names, words spelt
/// the same in that language). [prepare] runs after the pump (open a sheet,
/// scroll) and before anything is checked.
Future<void> qaExpectRendersInAllLocales(
  WidgetTester tester, {
  required QaApi Function() api,
  required Widget Function() build,
  required List<String Function(AppLocalizations l)> expected,
  Set<String> allow = const {},
  Map<String, Set<String>> allowIn = const {},
  List<Override> Function()? extra,
  Size size = const Size(430, 1400),
  String accountKind = 'dating',
  int frames = 10,
  Future<void> Function(WidgetTester tester, AppLocalizations l)? prepare,
}) async {
  Future<Set<String>> render(Locale locale) async {
    await qaQualityPump(
      tester,
      api(),
      build(),
      locale: locale,
      size: size,
      extra: extra?.call() ?? const [],
      accountKind: accountKind,
      frames: frames,
    );
    final l = qaL10n(locale);
    if (prepare != null) await prepare(tester, l);
    expect(tester.takeException(), isNull, reason: '$locale');
    for (final s in expected) {
      expect(
        find.textContaining(s(l), findRichText: true),
        findsWidgets,
        reason: '"${s(l)}" is not on screen in $locale',
      );
    }
    final seen = qaPaintedStrings(tester);
    await qaQualityUnmount(tester);
    return seen;
  }

  final english = await render(const Locale('en'));
  for (final locale in qaLocales) {
    if (locale.languageCode == 'en') {
      if (locale.countryCode != null) await render(locale);
      continue;
    }
    final seen = await render(locale);
    final permitted = {...allow, ...?allowIn[locale.languageCode]};
    final leaks =
        seen
            .intersection(english)
            .where((s) => _words.hasMatch(s) && !permitted.contains(s))
            .toList()
          ..sort();
    expect(leaks, isEmpty, reason: 'English left in $locale: $leaks');
  }
}
