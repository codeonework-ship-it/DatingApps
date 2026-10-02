// Local helpers for the engagement control tests (on top of the shared
// harness in test/support/qa_api.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

/// English strings (the default locale of [pumpQa]).
AppLocalizations get en => qaL10n(const Locale('en'));

/// Pulls the first scrollable down past the refresh trigger and lets the
/// refresh finish.
Future<void> qaPullToRefresh(WidgetTester tester, {Finder? scrollable}) async {
  await tester.fling(
    scrollable ?? find.byType(Scrollable).first,
    const Offset(0, 500),
    1200,
  );
  await tester.pump();
  await qaSettle(tester, frames: 20);
}

/// Whether the Material button [finder] can be pressed.
bool qaEnabled(WidgetTester tester, Finder finder) {
  final element = finder.evaluate().single;
  final widget = element.widget;
  if (widget is ButtonStyleButton) return widget.onPressed != null;
  final button = find.descendant(
    of: finder,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  if (button.evaluate().isNotEmpty) {
    return (tester.widget(button.first) as ButtonStyleButton).onPressed != null;
  }
  final ancestor = find.ancestor(
    of: finder,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return (tester.widget(ancestor.first) as ButtonStyleButton).onPressed != null;
}

/// The text currently in the [TextField] found by [finder].
String qaFieldText(WidgetTester tester, Finder finder) {
  final field = finder.evaluate().single.widget;
  if (field is TextField) return field.controller!.text;
  return tester
      .widget<TextField>(
        find.descendant(of: finder, matching: find.byType(TextField)),
      )
      .controller!
      .text;
}

/// Unmounts the app so screen timers and providers are disposed.
Future<void> qaUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await qaSettle(tester, frames: 2);
}

/// Scrolls the first scrollable (down, then up) until [finder] is built,
/// then brings it into view.
Future<void> qaScrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  for (final step in const [-250.0, 250.0]) {
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, Offset(0, step));
      await tester.pump();
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
}
