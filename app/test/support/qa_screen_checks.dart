// Screen-level QA checks on top of the recording fake BFF in qa_api.dart:
// layout at every shipped device size and theme, Flutter's accessibility
// guidelines, a working way back, and rendering in every shipped locale with
// no English left over. Each check pumps the real screen against the fake
// server (so it is judged with its data loaded, not in an empty state) and
// fails on the first real problem.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import 'qa_api.dart';

/// The device sizes the app ships to (the same set as the screen matrix).
const qaDeviceSizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x780': Size(360, 780),
  'large phone 430x932': Size(430, 932),
  'tablet portrait 768x1024': Size(768, 1024),
  'tablet landscape 1366x1024': Size(1366, 1024),
};

/// Both shipped themes.
final qaThemes = <String, ThemeData>{
  'light': AppTheme.lightTheme,
  'dark': AppTheme.darkTheme,
};

/// Pumps [child] like [pumpQa] does, with a chosen [theme]. With
/// [launcher] the screen is pushed from a launcher page and what it pops
/// with is added to the returned list.
Future<List<Object?>> qaPumpScreen(
  WidgetTester tester,
  QaApi api,
  Widget child, {
  ThemeData? theme,
  Size size = const Size(430, 932),
  Locale? locale,
  List<Override> extra = const [],
  String userId = 'me',
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
      overrides: qaOverrides(api, userId: userId, flags: flags, extra: extra),
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
Future<void> qaUnmountScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

/// Pumps the screen at every [sizes] entry in both themes and fails on any
/// exception (a RenderFlex overflow is one). [loaded] must find something
/// that only shows once the screen's data has arrived, so the check is made
/// on the real layout rather than a spinner.
Future<void> qaExpectLaysOutEverywhere(
  WidgetTester tester,
  QaApi api,
  Widget Function() build, {
  required Finder loaded,
  List<Override> extra = const [],
  Map<String, Size> sizes = qaDeviceSizes,
  int frames = 10,
}) async {
  for (final theme in qaThemes.entries) {
    for (final device in sizes.entries) {
      final where = '${device.key} [${theme.key}]';
      await qaPumpScreen(
        tester,
        api,
        build(),
        theme: theme.value,
        size: device.value,
        extra: extra,
        frames: frames,
      );
      expect(tester.takeException(), isNull, reason: where);
      // On a small screen the loaded content may sit below the fold: scroll
      // to it, which lays out everything on the way too.
      await qaScrollUntilBuilt(tester, loaded);
      expect(tester.takeException(), isNull, reason: '$where (scrolled)');
      expect(loaded, findsWidgets, reason: 'content did not load on $where');
      await qaUnmountScreen(tester);
    }
  }
}

/// Drags the first vertical scrollable down (up to [steps] times) until
/// [finder] is built. Does nothing when it already is or nothing scrolls.
Future<void> qaScrollUntilBuilt(
  WidgetTester tester,
  Finder finder, {
  int steps = 20,
}) async {
  final scrollables = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  for (var i = 0; i < steps && finder.evaluate().isEmpty; i++) {
    if (scrollables.hitTestable().evaluate().isEmpty) {
      return;
    }
    await tester.drag(scrollables.hitTestable().first, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Runs Flutter's tap-target (48x48), labelled-tap-target and text-contrast
/// guidelines over the screen with its data loaded, on the reference phone,
/// in both themes.
Future<void> qaExpectMeetsA11yGuidelines(
  WidgetTester tester,
  QaApi api,
  Widget Function() build, {
  required Finder loaded,
  List<Override> extra = const [],
  Size size = const Size(360, 780),
  int frames = 10,
}) async {
  final semantics = tester.ensureSemantics();
  for (final theme in qaThemes.entries) {
    await qaPumpScreen(
      tester,
      api,
      build(),
      theme: theme.value,
      size: size,
      extra: extra,
      frames: frames,
    );
    expect(loaded, findsWidgets, reason: 'content did not load [${theme.key}]');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await qaUnmountScreen(tester);
  }
  semantics.dispose();
}

/// Pushes the screen from a launcher, checks a back (or close) control is
/// visible, taps it and asserts the screen closed and the launcher is back.
Future<void> qaExpectBackReturns(
  WidgetTester tester,
  QaApi api,
  Widget Function() build, {
  required Type screen,
  List<Override> extra = const [],
  int frames = 10,
}) async {
  final results = await qaPumpScreen(
    tester,
    api,
    build(),
    launcher: true,
    extra: extra,
    frames: frames,
  );
  expect(find.byType(screen), findsOneWidget);
  final context = tester.element(find.byType(screen));
  final strings = MaterialLocalizations.of(context);
  final back = find
      .byWidgetPredicate(
        (w) =>
            w is BackButton ||
            w is CloseButton ||
            (w is IconButton &&
                (w.tooltip == strings.backButtonTooltip ||
                    w.tooltip == strings.closeButtonTooltip)),
      )
      .hitTestable();
  expect(back, findsWidgets, reason: 'no visible back or close control');
  await tester.tap(back.first);
  await qaSettle(tester, frames: frames);
  expect(find.byType(screen), findsNothing, reason: 'Back did not close it');
  expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
  expect(results, hasLength(1), reason: 'the route popped once');
  await qaUnmountScreen(tester);
}

/// Every string the screen paints (Text and RichText), trimmed.
Set<String> qaRenderedStrings(WidgetTester tester) {
  final out = <String>{};
  for (final e in find.byType(Text).evaluate()) {
    final t = e.widget as Text;
    final s = t.data ?? t.textSpan?.toPlainText() ?? '';
    if (s.trim().isNotEmpty) {
      out.add(s.trim());
    }
  }
  for (final e in find.byType(RichText).evaluate()) {
    final s = (e.widget as RichText).text.toPlainText();
    if (s.trim().isNotEmpty) {
      out.add(s.trim());
    }
  }
  for (final e in find.byType(EditableText).evaluate()) {
    final s = (e.widget as EditableText).controller.text;
    if (s.trim().isNotEmpty) {
      out.add(s.trim());
    }
  }
  return out;
}

final _letters = RegExp(r'[A-Za-z]{2,}');

/// Renders the screen in every shipped locale. In each one the [expected]
/// strings (read from that locale's AppLocalizations) must be on screen, and
/// outside English no string the English render showed may appear unchanged
/// (a hard-coded or untranslated label), except the [allow]ed ones (member
/// data from the fixture, brand names, words that are spelt the same).
Future<void> qaExpectRendersInAllLocales(
  WidgetTester tester,
  QaApi api,
  Widget Function() build, {
  required List<String Function(AppLocalizations l)> expected,
  Set<String> allow = const {},
  List<Override> extra = const [],
  Size size = const Size(430, 1400),
  int frames = 10,
  Future<void> Function(WidgetTester tester, AppLocalizations l)? prepare,
}) async {
  Future<Set<String>> render(Locale locale) async {
    await qaPumpScreen(
      tester,
      api,
      build(),
      locale: locale,
      size: size,
      extra: extra,
      frames: frames,
    );
    final l = qaL10n(locale);
    if (prepare != null) {
      await prepare(tester, l);
    }
    expect(tester.takeException(), isNull, reason: '$locale');
    for (final s in expected) {
      expect(
        find.textContaining(s(l), findRichText: true),
        findsWidgets,
        reason: '"${s(l)}" is not on screen in $locale',
      );
    }
    final seen = qaRenderedStrings(tester);
    await qaUnmountScreen(tester);
    return seen;
  }

  final english = await render(const Locale('en'));
  for (final locale in qaLocales) {
    if (locale.languageCode == 'en') {
      if (locale.countryCode != null) {
        await render(locale);
      }
      continue;
    }
    final seen = await render(locale);
    final leaks =
        seen
            .intersection(english)
            .where((s) => _letters.hasMatch(s) && !allow.contains(s))
            .toList()
          ..sort();
    expect(leaks, isEmpty, reason: 'English left in $locale: $leaks');
  }
}
