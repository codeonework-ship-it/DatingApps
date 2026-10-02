import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/constants/app_constants.dart';
import 'package:verified_dating_app/features/common/screens/about_app_screen.dart';

import '../../support/qa_api.dart';

// About: the version line, the description and the stack, in every language.

void main() {
  // Regression (2026-10-02): About said "Version 1.0.0" whatever the build
  // was (pubspec 0.1.0); crash reports carry AppVersion.name, so support and
  // the member read different versions.
  testWidgets('About shows the build\'s own version '
      '[case:common.about_app.version]', (tester) async {
    final results = await pumpQa(
      tester,
      QaApi(),
      const AboutAppScreen(),
      launcher: true,
    );
    final en = qaL10n(const Locale('en'));

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('qa.about.version'))).data,
      en.aboutVersion(AppVersion.name),
    );
    expect(find.text(en.aboutVersion('1.0.0')), findsNothing);
    expect(find.text(en.aboutDescription), findsOneWidget);
    expect(find.text(en.aboutStackFlutter), findsOneWidget);

    // A plain page: Back returns to the opener with nothing handed back.
    await tester.tap(find.byType(BackButton));
    await qaSettle(tester);
    expect(find.byType(AboutAppScreen), findsNothing);
    expect(results, [null]);
  });

  testWidgets('About renders in every shipped language '
      '[case:common.about_app.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await pumpQa(tester, QaApi(), const AboutAppScreen(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(
        find.text(l10n.settingsAboutTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.aboutVersion(AppVersion.name)),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.text(l10n.aboutStack), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.aboutDescription),
        findsOneWidget,
        reason: '$locale',
      );
    }
  });
}
