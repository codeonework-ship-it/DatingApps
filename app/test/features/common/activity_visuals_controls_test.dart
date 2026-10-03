// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/widgets/activity_visuals.dart';

import '../../support/qa_api.dart';

// Shared activity visuals (Photo Themes, Clubs, Lists): the hero header and
// the spoiler cover, which hides review text (from sight and from screen
// readers) until the member taps to reveal it.

const _spoilerText = 'The twist: the narrator was the detective all along.';

final _en = qaL10n(const Locale('en'));

Widget _screen({bool spoiler = true}) => Scaffold(
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const ActivityHero(
        icon: Icons.menu_book_outlined,
        title: 'Book Club',
        subtitle: 'Read together, talk kindly.',
      ),
      const SizedBox(height: 16),
      SpoilerReveal(
        key: const ValueKey('spoiler'),
        spoiler: spoiler,
        child: const Text(_spoilerText),
      ),
    ],
  ),
);

void main() {
  testWidgets('tapping the spoiler cover reveals the text, to sight and to '
      'screen readers, and the cover goes away '
      '[case:common.activity_visuals.spoiler_tap_to_reveal.action]', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpQa(tester, QaApi(), _screen());

    expect(find.text(_en.communitySpoiler), findsOneWidget);
    // Hidden behind the blur and kept out of the accessibility tree.
    expect(find.bySemanticsLabel(_spoilerText), findsNothing);
    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.tap(find.text(_en.communitySpoiler));
    await tester.pump();

    expect(find.text(_en.communitySpoiler), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.text(_spoilerText).hitTestable(), findsOneWidget);
    expect(find.bySemanticsLabel(_spoilerText), findsOneWidget);

    // Revealed stays revealed while the screen rebuilds.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_en.communitySpoiler), findsNothing);
    semantics.dispose();
  });

  testWidgets('text that is not a spoiler shows straight away '
      '[case:common.activity_visuals.spoiler_tap_to_reveal.action]', (
    tester,
  ) async {
    await pumpQa(tester, QaApi(), _screen(spoiler: false));
    expect(find.text(_en.communitySpoiler), findsNothing);
    expect(find.text(_spoilerText).hitTestable(), findsOneWidget);
  });

  testWidgets('the spoiler cover is translated in every shipped language and '
      'nothing overflows on a small phone '
      '[case:common.activity_visuals.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await pumpQa(
        tester,
        QaApi(),
        _screen(),
        locale: locale,
        size: const Size(320, 640),
      );
      expect(
        find.text(l10n.communitySpoiler),
        findsOneWidget,
        reason: '$locale',
      );
      if (locale.languageCode != 'en') {
        expect(
          find.text(_en.communitySpoiler),
          findsNothing,
          reason: '$locale',
        );
      }
      expect(tester.takeException(), isNull, reason: '$locale');

      await tester.tap(find.text(l10n.communitySpoiler));
      await tester.pump();
      expect(find.text(_spoilerText), findsOneWidget, reason: '$locale');
    }
  });
}
