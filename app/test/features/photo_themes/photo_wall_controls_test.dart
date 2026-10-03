// Control-level tests for the photo covers on the Today wall (photo_wall.dart):
// opening a cover (which counts a view) and the rail in every locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_wall.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'photo_qa_fixtures.dart';

Widget rail() => const Scaffold(
  body: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: PhotoWallRail(),
  ),
);

PhotoWorld wallWorld() => PhotoWorld(
  wall: [
    entryJson(),
    entryJson(id: 'e2', name: 'Sam Lee', caption: 'Long walk.'),
  ],
);

void main() {
  testWidgets(
    'Tapping a cover opens that photo with likes and comments and counts '
    'one view [case:photo_themes.photo_wall.inkwell_ontap.action]',
    (t) async {
      final w = wallWorld();
      await pumpQa(t, w.api, rail(), size: const Size(430, 1200));
      expect(key('photo.cover.e2'), findsOneWidget);
      await t.tap(find.text('Long walk.'));
      await qaSettle(t);

      expect(find.byType(ThemeEntrySheet), findsOneWidget);
      expect(
        inSheet(find.text(en.photoThemesSharedBy('Sam Lee'))),
        findsOneWidget,
      );
      expect(inSheet(key('photo.like.e2')), findsOneWidget);
      expect(w.views.single.body, {'kind': 'photo', 'id': 'e2'});
    },
  );

  testWidgets('When the view cannot be counted the cover still opens, quietly '
      '[case:photo_themes.photo_wall.inkwell_ontap.api_failure]', (t) async {
    final w = wallWorld();
    w.api.offline('POST /walls/views');
    await pumpQa(t, w.api, rail(), size: const Size(430, 1200));
    await t.tap(find.text('Pancakes, then nowhere to be.'));
    await qaSettle(t);

    expect(w.views, hasLength(1));
    expect(find.byType(ThemeEntrySheet), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(t.takeException(), isNull);
    // The wall itself is untouched behind the sheet.
    await t.tap(key('qa.photo_entry.close'));
    await qaSettle(t);
    expect(key('photo.cover.e1'), findsOneWidget);
    expect(key('photo.cover.e2'), findsOneWidget);
  });

  testWidgets('the covers render in every shipped locale with nothing left '
      'in English [case:photo_themes.photo_wall.l10n]', (t) async {
    await qaExpectRendersInAllLocales(
      t,
      wallWorld().api,
      rail,
      expected: [
        (l) => l.photoThemesWallTitle,
        (l) => l.photoThemesWallCaption,
        (l) => l.photoThemesByline('PRIYA'),
        (l) => l.photoThemesByline('SAM'),
      ],
      // Theme titles, captions and counts come from members and the server.
      allow: {
        'MY PERFECT SUNDAY',
        'Pancakes, then nowhere to be.',
        'Long walk.',
      },
    );
  });
}
