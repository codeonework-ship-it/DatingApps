import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

// Regression (2026-10-02): the Settings tab's unread badge showed "53" past
// the icon's corner and was clipped by the screen edge on the last tab.
Future<void> _pump(WidgetTester tester, int count) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            key: const ValueKey('tab'),
            width: 72,
            height: 48,
            child: Center(
              child: UnreadNavBadge(
                count: count,
                child: const Icon(
                  Icons.settings_rounded,
                  key: ValueKey('icon'),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final (count, text) in [(3, '3'), (53, '53'), (120, '99+')]) {
    testWidgets('unread badge "$text" stays inside the tab at the screen edge '
        '[case:common.main_navigation.settings_badge.contained]', (
      tester,
    ) async {
      await _pump(tester, count);
      final label = find.byKey(const ValueKey('qa.nav.unread_badge'));
      expect(find.text(text), findsOneWidget);
      final tab = tester.getRect(find.byKey(const ValueKey('tab')));
      final screen = tester.getRect(find.byType(Scaffold));
      final icon = tester.getRect(find.byKey(const ValueKey('icon')));
      // The painted badge (not just its text) lies within the tab and the
      // screen, and its end edge is pinned past the glyph's centre whatever
      // the count, so a longer count grows back over the glyph.
      final pill = tester.getRect(
        find.byKey(const ValueKey('qa.nav.unread_badge_pill')),
      );
      expect(tester.getRect(label).right, lessThanOrEqualTo(pill.right));
      expect(
        pill.right,
        lessThanOrEqualTo(tab.right + 0.5),
        reason: 'badge overflows the tab',
      );
      expect(
        pill.right,
        lessThanOrEqualTo(screen.right),
        reason: 'badge clipped by the screen edge',
      );
      expect(pill.top, greaterThanOrEqualTo(tab.top - 0.5));
      expect(
        pill.right,
        moreOrLessEquals(
          icon.center.dx + UnreadNavBadge.endPastCentre,
          epsilon: 0.5,
        ),
      );
    });
  }

  testWidgets(
    'no badge when there is nothing unread, and it is announced when there is '
    '[case:common.main_navigation.settings_badge.semantics]',
    (tester) async {
      await _pump(tester, 0);
      expect(find.byKey(const ValueKey('qa.nav.unread_badge')), findsNothing);
      await _pump(tester, 53);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp('53 unread')),
        findsNothing,
      ); // value, not label
      final node = tester.getSemantics(find.byType(UnreadNavBadge));
      expect(node.value, '53 unread');
      handle.dispose();
    },
  );
}
