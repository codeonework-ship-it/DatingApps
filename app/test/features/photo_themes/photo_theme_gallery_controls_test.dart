// Control-level tests for one theme's gallery (photo_theme_gallery_screen.dart):
// opening a photo, paging, the reload controls, pull to refresh and sharing
// the member's own photo. Every test performs the real gesture against the
// fake BFF (photo_qa_fixtures.dart) and asserts what was sent and shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'photo_qa_fixtures.dart';

Widget gallery() => const PhotoThemeGalleryScreen(themeId: 't1');

Future<void> pumpGallery(WidgetTester t, PhotoWorld w) =>
    pumpQa(t, w.api, gallery(), size: const Size(430, 1600));

late String photo;

void main() {
  setUpAll(() => photo = photoFile());

  group('photos', () {
    testWidgets(
      'Tapping a photo opens it with its caption and byline, and counts a view '
      '[case:photo_themes.photo_theme_gallery.themeentrytile_ontap.action]',
      (t) async {
        final w = PhotoWorld();
        await pumpGallery(t, w);
        await t.tap(find.text('Long walk.'));
        await qaSettle(t);

        expect(find.byType(ThemeEntrySheet), findsOneWidget);
        expect(inSheet(find.text('Long walk.')), findsOneWidget);
        expect(
          inSheet(find.text(en.photoThemesSharedBy('Sam Lee'))),
          findsOneWidget,
        );
        expect(w.views.single.body, {'kind': 'photo', 'id': 'e2'});
      },
    );

    testWidgets(
      'When counting the view fails the photo still opens and nothing '
      'complains '
      '[case:photo_themes.photo_theme_gallery.themeentrytile_ontap.api_failure]',
      (t) async {
        final w = PhotoWorld();
        w.api.fail('POST /walls/views');
        await pumpGallery(t, w);
        await t.tap(find.text('Long walk.'));
        await qaSettle(t);

        expect(w.views, hasLength(1));
        expect(find.byType(ThemeEntrySheet), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(t.takeException(), isNull);
        // Closing and opening again works as before.
        await t.tap(key('qa.photo_entry.close'));
        await qaSettle(t);
        await t.tap(find.text('Long walk.'));
        await qaSettle(t);
        expect(find.byType(ThemeEntrySheet), findsOneWidget);
      },
    );

    testWidgets(
      'Load more asks for the next page by cursor and adds its photos '
      '[case:photo_themes.photo_theme_gallery.load_more_onmore.action]',
      (t) async {
        final w = PhotoWorld(
          pages: {
            '': ([entryJson()], 'cursor-2'),
            'cursor-2': (
              [entryJson(id: 'e3', name: 'Ana Ruiz', caption: 'Beach run.')],
              '',
            ),
          },
        );
        await pumpGallery(t, w);
        expect(find.text('Beach run.'), findsNothing);
        await tapIn(t, find.text(en.photoThemesLoadMore));

        final pages = w.api.sent('GET', '/themes/t1/entries');
        expect(pages.last.query, {'before': 'cursor-2'});
        expect(find.text('Beach run.'), findsOneWidget);
        expect(find.text('Pancakes, then nowhere to be.'), findsOneWidget);
        expect(find.text(en.photoThemesLoadMore), findsNothing);
      },
    );

    testWidgets(
      'When more photos fail, Reload starts again from the first page and '
      'the paging works '
      '[case:photo_themes.photo_theme_gallery.more_photos_could_not_load_reloa_onretry.action]',
      (t) async {
        final w = PhotoWorld(
          pages: {
            '': ([entryJson()], 'cursor-2'),
            'cursor-2': ([entryJson(id: 'e3', caption: 'Beach run.')], ''),
          },
        );
        w.api.on('GET /themes/t1/entries', (c) {
          if (c.query['before'] == 'cursor-2') {
            return qaError(500);
          }
          return qaOk({
            'theme': w.themes.first,
            'entries': w.pages['']!.$1,
            'next_cursor': 'cursor-2',
          });
        });
        await pumpGallery(t, w);
        await tapIn(t, find.text(en.photoThemesLoadMore));
        expect(find.text(en.photoThemesMoreFailed), findsOneWidget);
        // The first page stays on screen.
        expect(find.text('Pancakes, then nowhere to be.'), findsOneWidget);

        final before = w.api.sent('GET', '/themes/t1/entries').length;
        await tapIn(t, find.text(en.photoThemesMoreFailed));
        final again = w.api.sent('GET', '/themes/t1/entries').skip(before);
        expect(
          again.where((c) => c.query.isEmpty),
          hasLength(1),
          reason: 'the first page is asked for again',
        );
        expect(find.text(en.photoThemesMoreFailed), findsNothing);
        expect(find.text(en.photoThemesLoadMore), findsOneWidget);
      },
    );

    testWidgets(
      'Pull to refresh reloads the theme and shows new photos '
      '[case:photo_themes.photo_theme_gallery.be_the_first_to_share_for_title_onrefresh.action]',
      (t) async {
        final w = PhotoWorld(pages: {'': (<Map<String, dynamic>>[], '')});
        await pumpGallery(t, w);
        expect(
          find.text(en.photoThemesBeFirstFor('My perfect Sunday')),
          findsOneWidget,
        );

        w.pages[''] = ([entryJson(caption: 'Fresh pancakes.')], '');
        await t.fling(find.byType(ListView).first, const Offset(0, 500), 1500);
        await t.pump();
        await qaSettle(t, frames: 20);

        expect(w.api.sent('GET', '/themes/t1/entries'), hasLength(2));
        expect(w.api.sent('GET', '/themes'), hasLength(2));
        expect(find.text('Fresh pancakes.'), findsOneWidget);
        expect(
          find.text(en.photoThemesBeFirstFor('My perfect Sunday')),
          findsNothing,
        );
      },
    );
  });

  group('sharing my photo', () {
    testWidgets(
      'Share your photo picks a photo, asks for a caption and description, '
      'uploads it under a new id and shows it as shared '
      '[case:photo_themes.photo_theme_gallery.share_a_photo_for_this_theme.action]',
      (t) async {
        final picks = mockPicker(t, photo);
        final w = PhotoWorld();
        await pumpGallery(t, w);
        expect(find.byTooltip(en.photoThemesShareTooltip), findsOneWidget);
        await t.tap(find.text(en.photoThemesShareYourPhoto));
        await qaSettle(t);
        expect(picks.single.method, 'pickImage');

        await t.enterText(
          inDialog(find.byType(TextField).at(0)),
          'Lazy brunch',
        );
        await t.enterText(
          inDialog(find.byType(TextField).at(1)),
          'Eggs on toast',
        );
        await t.pump();
        await t.tap(inDialog(find.text(en.photoThemesShare)));
        await settleIo(t);

        final put = w.api.writes.single;
        expect(put.method, 'PUT');
        expect(
          put.path,
          matches(RegExp(r'^/themes/t1/entries/[0-9a-f-]{36}$')),
        );
        expect(uploadFields(put), {
          'caption': 'Lazy brunch',
          'alt_text': 'Eggs on toast',
        });
        expect(qaSnackText(t), en.photoThemesSharedSnack);
        expect(find.text('Lazy brunch'), findsOneWidget);
        expect(find.text(en.photoThemesYouShared), findsWidgets);
        // One photo per theme: sharing is now off, with the reason.
        expect(find.text(en.photoThemesAlreadyShared), findsOneWidget);
      },
    );

    testWidgets(
      'A failed upload says why, keeps the gallery as it was and lets the '
      'member try again '
      '[case:photo_themes.photo_theme_gallery.share_a_photo_for_this_theme.api_failure]',
      (t) async {
        mockPicker(t, photo);
        final w = PhotoWorld();
        w.api.fail(
          'PUT /themes/t1/entries/*',
          status: 413,
          message: 'That photo is too large.',
        );
        await pumpGallery(t, w);
        await t.tap(find.text(en.photoThemesShareYourPhoto));
        await qaSettle(t);
        await t.enterText(
          inDialog(find.byType(TextField).at(0)),
          'Lazy brunch',
        );
        await t.enterText(inDialog(find.byType(TextField).at(1)), 'Eggs');
        await t.pump();
        await t.tap(inDialog(find.text(en.photoThemesShare)));
        await settleIo(t);

        expect(w.api.writes, hasLength(1));
        expect(qaSnackText(t), 'That photo is too large.');
        expect(find.text('Lazy brunch'), findsNothing);
        expect(find.text(en.photoThemesAlreadyShared), findsNothing);
        final fab = t.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.onPressed, isNotNull, reason: 'can try again');
      },
    );
  });

  group('screen quality', () {
    testWidgets('lays out with photos on phone and tablet, both themes '
        '[case:photo_themes.photo_theme_gallery.layout_matrix]', (t) async {
      final w = PhotoWorld(
        pages: {
          '': (
            [
              for (var i = 0; i < 5; i++)
                entryJson(
                  id: 'e$i',
                  caption:
                      'A long caption number $i that wraps over two lines at least',
                ),
            ],
            'cursor-2',
          ),
        },
      );
      await qaExpectLaysOutEverywhere(
        t,
        w.api,
        gallery,
        loaded: find.text(en.photoThemesLoadMore),
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:photo_themes.photo_theme_gallery.a11y_guidelines]', (t) async {
      final w = PhotoWorld();
      await qaExpectMeetsA11yGuidelines(
        t,
        w.api,
        gallery,
        size: const Size(430, 1600),
        loaded: find.text('Show us the Sunday you would repeat forever.'),
      );
    });

    testWidgets('pushed, Back returns to the themes '
        '[case:photo_themes.photo_theme_gallery.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        PhotoWorld().api,
        gallery,
        screen: PhotoThemeGalleryScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:photo_themes.photo_theme_gallery.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        PhotoWorld(
          pages: {
            '': ([entryJson()], 'cursor-2'),
          },
        ).api,
        gallery,
        expected: [
          (l) => l.photoThemesSharedCount(2),
          (l) => l.photoThemesShareYourPhoto,
          (l) => l.photoThemesLoadMore,
        ],
        // The theme and the photo come from members, as written.
        allow: {
          'My perfect Sunday',
          'Show us the Sunday you would repeat forever.',
          'Pancakes, then nowhere to be.',
          'Priya Sharma',
        },
      );
    });
  });
}
