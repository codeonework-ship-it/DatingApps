import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_widgets.dart';
import 'package:verified_dating_app/features/groups/group_widgets.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

// Full-height sheets need a visible way out besides the drag handle.
void main() {
  final openers = <String, Future<void> Function(BuildContext, Widget)>{
    'club': (context, child) => showClubSheet<void>(context, child),
    'group': (context, child) => showGroupSheet<void>(context, child),
  };
  for (final entry in openers.entries) {
    testWidgets('${entry.key} sheets close from the close button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => entry.value(
                context,
                ListView(children: const [Text('sheet body')]),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('qa.sheet.close')));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsNothing);
    });
  }
}
