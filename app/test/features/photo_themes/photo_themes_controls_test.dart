// Control-level tests for the Photo Themes list (photo_themes_screen.dart):
// opening a theme, pull to refresh and the reload after a failure, plus the
// screen-quality cases. Every test performs the real gesture against the
// fake BFF (photo_qa_fixtures.dart) and asserts what was sent and shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'photo_qa_fixtures.dart';

Future<void> pumpThemes(WidgetTester t, PhotoWorld w) =>
    pumpQa(t, w.api, const PhotoThemesScreen(), size: const Size(430, 1600));

void main() {
  testWidgets(
    'See everyone’s photos opens that theme’s gallery with its photos '
    '[case:photo_themes.photo_themes.see_everyone_s_photos.action]',
    (t) async {
      final w = PhotoWorld();
      await pumpThemes(t, w);
      expect(w.api.sent('GET', '/themes/t1/entries'), isEmpty);
      await tapIn(t, find.text(en.photoThemesSeeEveryone));

      expect(find.byType(PhotoThemeGalleryScreen), findsOneWidget);
      expect(w.api.sent('GET', '/themes/t1/entries'), hasLength(1));
      expect(find.text('Pancakes, then nowhere to be.'), findsOneWidget);
      expect(find.text('Long walk.'), findsOneWidget);
    },
  );

  testWidgets(
    'Pull to refresh asks for the themes again and shows a new prompt '
    '[case:photo_themes.photo_themes.show_a_little_of_your_world_onrefresh.action]',
    (t) async {
      final w = PhotoWorld();
      await pumpThemes(t, w);
      expect(find.text('Comfort food'), findsNothing);

      w.themes.add(themeJson(id: 't2', title: 'Comfort food', count: 0));
      await t.fling(find.byType(ListView).first, const Offset(0, 500), 1500);
      await t.pump();
      await qaSettle(t, frames: 20);

      expect(w.api.sent('GET', '/themes'), hasLength(2));
      expect(find.text('Comfort food'), findsOneWidget);
      expect(find.text(en.photoThemesBeFirst), findsOneWidget);
    },
  );

  testWidgets(
    'When themes cannot load the screen says so, and Try again loads them '
    '[case:photo_themes.photo_themes.themes_could_not_load_onaction.action]',
    (t) async {
      final w = PhotoWorld();
      w.api.fail('GET /themes', message: 'The server is resting.');
      await pumpThemes(t, w);
      expect(find.text(en.photoThemesLoadFailed), findsOneWidget);
      expect(find.text('The server is resting.'), findsOneWidget);

      w.api.on(
        'GET /themes',
        (_) => qaOk({'themes': w.themes, 'eligible': true}),
      );
      await tapIn(t, find.text(en.photoThemesTryAgain));
      expect(w.api.sent('GET', '/themes'), hasLength(2));
      expect(find.text(en.photoThemesLoadFailed), findsNothing);
      expect(find.text('My perfect Sunday'), findsOneWidget);
    },
  );

  group('screen quality', () {
    PhotoWorld world() => PhotoWorld(
      themes: [
        themeJson(myEntry: 'mine'),
        themeJson(
          id: 't2',
          title: 'Something I made with my own two hands',
          count: 0,
        ),
        themeJson(id: 't3', title: 'The view I love', count: 12),
      ],
      eligible: false,
    );

    testWidgets('lays out with themes on phone and tablet, both themes '
        '[case:photo_themes.photo_themes.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        world().api,
        PhotoThemesScreen.new,
        loaded: find.text('The view I love'),
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:photo_themes.photo_themes.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        world().api,
        PhotoThemesScreen.new,
        size: const Size(430, 1600),
        loaded: find.text(en.photoThemesHeroTitle),
      );
    });

    testWidgets('pushed, Back returns to where the member came from '
        '[case:photo_themes.photo_themes.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        world().api,
        PhotoThemesScreen.new,
        screen: PhotoThemesScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:photo_themes.photo_themes.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        world().api,
        PhotoThemesScreen.new,
        size: const Size(430, 2400),
        expected: [
          (l) => l.photoThemesTitle,
          (l) => l.photoThemesHeroTitle,
          (l) => l.photoThemesLookAround,
          (l) => l.photoThemesEligibilityShareOwn,
          (l) => l.photoThemesYouShared,
          (l) => l.photoThemesBeFirst,
          (l) => l.photoThemesSeeEveryone,
          (l) => l.photoThemesSharedCount(12),
        ],
        // Prompt titles and text come from the server as written.
        allow: {
          'My perfect Sunday',
          'Something I made with my own two hands',
          'The view I love',
          'Show us the Sunday you would repeat forever.',
        },
      );
    });
  });
}
