// SheetCloseBar, the pinned close row on full-height bottom sheets: the
// close button dismisses the sheet (and only the sheet), and its label is the
// framework's own "Close", translated in every locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/sheet_close_bar.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

const _closeKey = ValueKey('qa.sheet.close');

/// A page that opens a full-height sheet with the bar at its top, recording
/// what the sheet handed back.
Widget _host(List<Object?> results, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async => results.add(
            await showModalBottomSheet<Object?>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SizedBox(
                height: 600,
                child: Column(
                  children: [
                    SheetCloseBar(closeKey: _closeKey, title: Text('Filters')),
                    Expanded(child: Center(child: Text('Sheet body'))),
                  ],
                ),
              ),
            ),
          ),
          child: const Text('open sheet'),
        ),
      ),
    ),
  ),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
  expect(find.text('Sheet body'), findsOneWidget);
}

void main() {
  testWidgets('the close button dismisses the sheet and returns to the page '
      '[case:core.sheet_close_bar.close_icon_close_rounded.action]', (
    tester,
  ) async {
    final results = <Object?>[];
    await tester.pumpWidget(_host(results));
    await _openSheet(tester);
    expect(find.text('Filters'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_closeKey),
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();

    expect(find.text('Sheet body'), findsNothing);
    expect(find.byType(SheetCloseBar), findsNothing);
    // Dismissed without a result, and the page underneath stays.
    expect(results, [null]);
    expect(find.text('open sheet'), findsOneWidget);

    // A second close tap has nothing left to pop: the page stays.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse);
  });

  for (final locale in const [Locale('de'), Locale('fr'), Locale('pl')]) {
    testWidgets('the close label is translated (${locale.languageCode}) '
        '[case:core.sheet_close_bar.l10n]', (tester) async {
      final semantics = tester.ensureSemantics();
      final results = <Object?>[];
      await tester.pumpWidget(_host(results, locale: locale));
      await _openSheet(tester);

      final context = tester.element(find.byType(SheetCloseBar));
      final label = MaterialLocalizations.of(context).closeButtonTooltip;
      expect(label, isNot('Close'));
      const expected = {'de': 'Schließen', 'fr': 'Fermer'};
      if (expected.containsKey(locale.languageCode)) {
        expect(label, expected[locale.languageCode]);
      }
      final button = tester.widget<IconButton>(find.byKey(_closeKey));
      expect(button.tooltip, label);
      expect(find.byTooltip(label), findsOneWidget);
      expect(find.byTooltip('Close'), findsNothing);
      // Screen readers announce the translated label.
      expect(tester.getSemantics(find.byKey(_closeKey)).tooltip, label);
      // The translated control still closes the sheet.
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
      semantics.dispose();
    });
  }
}
