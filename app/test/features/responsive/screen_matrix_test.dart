import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../support/layout_webview_platform.dart';
import 'screen_matrix_harness.dart';

/// Layout coverage for **every** screen in the app, at each device size it
/// ships to.
///
/// Golden files pin a couple of screens at a couple of sizes. They say nothing
/// about the widths where layouts actually break — the smallest phone still in
/// support, the tallest phone, a tablet in portrait — and nothing at all about
/// the screens they do not cover.
///
/// These assert the absence of *layout* errors rather than comparing pixels, so
/// they survive restyling and cost nothing to extend. Runtime noise a screen
/// produces without a backend (failed requests, absent plugins, missing files)
/// is deliberately tolerated: this is a layout harness, not an integration one.
///
/// Every screen must appear here. A screen absent from this map is a screen
/// nobody is checking at 320pt. The map itself lives in
/// `screen_matrix_harness.dart` so the accessibility guideline suite
/// (`screen_accessibility_test.dart`) walks exactly the same screens.
void main() {
  WebViewPlatform.instance = LayoutWebViewPlatform();
  const devices = screenMatrixDevices;
  final screens = buildScreenMatrix();

  // Every screen is exercised under both themes.
  //
  // The matrix used to pump the light theme only, which is why a dark-mode
  // regression — near-white labels drawn on a hardcoded light ground — passed
  // 281 green tests while the app was unreadable on device. A theme the
  // product ships and lets members select has to be covered like any other
  // configuration.
  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  };

  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    devices.forEach((deviceLabel, size) {
      screens.forEach((screenLabel, build) {
        testWidgets('$screenLabel lays out on $deviceLabel [$themeLabel]', (
          tester,
        ) async {
          final errors = await pumpAndCollectLayoutErrors(
            tester,
            build(),
            size,
            theme,
          );
          expect(
            errors,
            isEmpty,
            reason:
                '$screenLabel has ${errors.length} layout error(s) on '
                '$deviceLabel ($themeLabel):\n${errors.join('\n')}',
          );
        });
      });
    });
  }

  // Every shipped screen also runs with Android's large accessibility font
  // scale on the smallest supported phone, in both themes. This catches
  // clipped actions and unreadable fixed-height rows that ordinary responsive
  // coverage misses; the dark theme swaps surfaces and paddings on several
  // screens, so it gets its own large-text pass rather than inheriting light's.
  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    screens.forEach((screenLabel, build) {
      testWidgets(
        '$screenLabel supports large accessibility text [$themeLabel]',
        (tester) async {
          final errors = await pumpAndCollectLayoutErrors(
            tester,
            build(),
            devices['small phone 320x568']!,
            theme,
            textScaler: const TextScaler.linear(1.3),
          );
          expect(
            errors,
            isEmpty,
            reason:
                '$screenLabel has ${errors.length} accessibility layout '
                'error(s) ($themeLabel):\n${errors.join('\n')}',
          );
        },
      );
    });
  }

  test('every screen in the app is covered by this matrix', () {
    final declared = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_screen.dart'))
        .expand(
          (file) => RegExp(
            r'class (\w+Screen) extends',
          ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!),
        )
        .toSet();

    final missing = declared.difference(screens.keys.toSet()).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'These screens are not layout-tested at any device size:\n'
          '${missing.join('\n')}',
    );
  });
}
