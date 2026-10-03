// Control-level tests for the photo widgets (photo_theme_widgets.dart): the
// entry sheet (like, reach, remove, report, block, photo retry) and the
// "Tell us about it" dialog the gallery shows before an upload (caption,
// description, reach switch, Cancel and Share). Every test performs the real
// gesture against the fake BFF (photo_qa_fixtures.dart) and asserts what was
// sent and shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'photo_qa_fixtures.dart';

late String photo;

Finder likeButton() => key('photo.like.e1');

String likeCount(WidgetTester t) {
  final label = find.descendant(of: likeButton(), matching: find.byType(Text));
  return (t.widget<Text>(label.first)).data!;
}

/// Opens the gallery, taps Share your photo and waits for the details
/// dialog (the picker answers with a real file).
Future<PhotoWorld> openDetails(WidgetTester t) async {
  mockPicker(t, photo);
  final w = PhotoWorld();
  await pumpQa(
    t,
    w.api,
    const PhotoThemeGalleryScreen(themeId: 't1'),
    size: const Size(430, 1600),
  );
  await t.tap(find.text(en.photoThemesShareYourPhoto));
  await qaSettle(t);
  return w;
}

Finder captionField() => inDialog(find.byType(TextField).at(0));
Finder describeField() => inDialog(find.byType(TextField).at(1));
Finder shareButton() => find.ancestor(
  of: inDialog(find.text(en.photoThemesShare)),
  matching: find.byType(FilledButton),
);

bool shareEnabled(WidgetTester t) =>
    t.widget<FilledButton>(shareButton()).onPressed != null;

String text(WidgetTester t, Finder field) =>
    t.widget<TextField>(field).controller!.text;

void main() {
  setUpAll(() => photo = photoFile());

  group('details dialog', () {
    testWidgets(
      'Picking a photo opens Tell us about it with both fields empty and '
      'the reach switch off '
      '[case:photo_themes.photo_theme_widgets.showdialog_open.action]',
      (t) async {
        final w = await openDetails(t);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(inDialog(find.text(en.photoThemesDetailsTitle)), findsOneWidget);
        expect(inDialog(find.text(en.photoThemesCaption)), findsOneWidget);
        expect(inDialog(find.text(en.photoThemesDescribe)), findsOneWidget);
        expect(
          t.widget<SwitchListTile>(key('photo.upload.allow_featuring')).value,
          isFalse,
        );
        expect(shareEnabled(t), isFalse);
        expect(w.api.writes, isEmpty);
      },
    );

    testWidgets('Cancel closes the dialog and nothing is uploaded '
        '[case:photo_themes.photo_theme_widgets.cancel.action]', (t) async {
      final w = await openDetails(t);
      await t.enterText(captionField(), 'Lazy brunch');
      await t.tap(inDialog(find.text(en.photoThemesCancel)));
      await settleIo(t);
      expect(find.byType(AlertDialog), findsNothing);
      expect(w.api.writes, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'Caption is what members read under the photo: typed, trimmed and '
      'uploaded '
      '[case:photo_themes.photo_theme_widgets.caption.action]',
      (t) async {
        final w = await openDetails(t);
        await t.enterText(captionField(), '  Lazy brunch  ');
        await t.enterText(describeField(), 'Eggs on toast');
        await t.pump();
        await t.tap(shareButton());
        await settleIo(t);
        expect(uploadFields(w.api.writes.single)['caption'], 'Lazy brunch');
        expect(find.text('Lazy brunch'), findsOneWidget);
      },
    );

    testWidgets(
      'Caption: Share stays off while it is empty or spaces, 280 characters '
      'is the limit, and emoji and right-to-left text upload unchanged '
      '[case:photo_themes.photo_theme_widgets.caption.validation]',
      (t) async {
        final w = await openDetails(t);
        await t.enterText(describeField(), 'Eggs on toast');
        await t.pump();
        expect(shareEnabled(t), isFalse);
        await t.enterText(captionField(), '    ');
        await t.pump();
        expect(shareEnabled(t), isFalse);
        await t.enterText(captionField(), 'c' * 300);
        expect(text(t, captionField()), hasLength(280));
        await t.enterText(captionField(), 'صباح الأحد ☀️ brunch');
        await t.pump();
        expect(shareEnabled(t), isTrue);
        await t.tap(shareButton());
        await settleIo(t);
        expect(
          uploadFields(w.api.writes.single)['caption'],
          'صباح الأحد ☀️ brunch',
        );
      },
    );

    testWidgets(
      'Describe the photo is uploaded as the photo’s description for screen '
      'readers '
      '[case:photo_themes.photo_theme_widgets.describe_the_photo.action]',
      (t) async {
        final w = await openDetails(t);
        expect(
          inDialog(find.text(en.photoThemesDescribeHelper)),
          findsOneWidget,
        );
        await t.enterText(captionField(), 'Lazy brunch');
        await t.enterText(describeField(), ' Eggs on toast by a window ');
        await t.pump();
        await t.tap(shareButton());
        await settleIo(t);
        expect(
          uploadFields(w.api.writes.single)['alt_text'],
          'Eggs on toast by a window',
        );
      },
    );

    testWidgets(
      'Describe the photo: required (spaces do not count), 160 characters is '
      'the limit, emoji are kept '
      '[case:photo_themes.photo_theme_widgets.describe_the_photo.validation]',
      (t) async {
        final w = await openDetails(t);
        await t.enterText(captionField(), 'Lazy brunch');
        await t.pump();
        expect(shareEnabled(t), isFalse);
        await t.enterText(describeField(), '   ');
        await t.pump();
        expect(shareEnabled(t), isFalse);
        await t.enterText(describeField(), 'd' * 200);
        expect(text(t, describeField()), hasLength(160));
        await t.enterText(describeField(), 'Pancakes 🥞 and coffee');
        await t.pump();
        await t.tap(shareButton());
        await settleIo(t);
        expect(
          uploadFields(w.api.writes.single)['alt_text'],
          'Pancakes 🥞 and coffee',
        );
      },
    );

    testWidgets(
      'Let it reach other members’ walls in the dialog sends '
      'allow_featuring only when switched on '
      '[case:photo_themes.photo_theme_widgets.photo_upload_allow_featuring.action]',
      (t) async {
        final w = await openDetails(t);
        await t.enterText(captionField(), 'Lazy brunch');
        await t.enterText(describeField(), 'Eggs');
        final reach = key('photo.upload.allow_featuring');
        await t.tap(reach);
        await t.pump();
        expect(t.widget<SwitchListTile>(reach).value, isTrue);
        await t.tap(shareButton());
        await settleIo(t);
        expect(uploadFields(w.api.writes.single), {
          'caption': 'Lazy brunch',
          'alt_text': 'Eggs',
          'allow_featuring': 'true',
        });
      },
    );

    testWidgets(
      'Share closes the dialog and uploads the photo with what was written '
      '[case:photo_themes.photo_theme_widgets.share.action]',
      (t) async {
        final w = await openDetails(t);
        await t.enterText(captionField(), 'Lazy brunch');
        await t.enterText(describeField(), 'Eggs');
        await t.pump();
        await t.tap(shareButton());
        await settleIo(t);
        expect(find.byType(AlertDialog), findsNothing);
        final put = w.api.writes.single;
        expect(put.method, 'PUT');
        expect(uploadFields(put), {
          'caption': 'Lazy brunch',
          'alt_text': 'Eggs',
        });
        expect(qaSnackText(t), en.photoThemesSharedSnack);
      },
    );
  });

  group('entry sheet', () {
    testWidgets(
      'Opening a photo shows the larger photo sheet and counts one view '
      '[case:photo_themes.photo_theme_widgets.showmodalbottomsheet_open.action]',
      (t) async {
        final w = PhotoWorld();
        await openSheet(t, w, entry());
        expect(
          inSheet(find.text('Pancakes, then nowhere to be.')),
          findsOneWidget,
        );
        expect(
          inSheet(find.text(en.photoThemesSharedBy('Priya Sharma'))),
          findsOneWidget,
        );
        expect(
          inSheet(
            find.text(
              en.photoThemesPhotoDescription(
                'A stack of pancakes on a balcony table',
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(w.views.single.body, {'kind': 'photo', 'id': 'e1'});
        expect(w.api.sent('GET', '/themes/t1/entries/e1/photo'), hasLength(1));
        await t.tap(key('qa.photo_entry.close'));
        await qaSettle(t);
        expect(find.byType(ThemeEntrySheet), findsNothing);
      },
    );

    testWidgets(
      'The heart likes the photo at once and the server’s count stays '
      '[case:photo_themes.photo_theme_widgets.love_icon_favorite_rounded_ontoggle.action]',
      (t) async {
        final w = PhotoWorld();
        await openSheet(t, w, entry());
        expect(likeCount(t), '3');
        await tapIn(t, likeButton());
        expect(w.api.writeLines, contains('PUT /themes/t1/entries/e1/like'));
        expect(likeCount(t), '4');
        expect(
          find.descendant(
            of: likeButton(),
            matching: find.byIcon(Icons.favorite_rounded),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'A like the server refuses rolls back and says so '
      '[case:photo_themes.photo_theme_widgets.love_icon_favorite_rounded_ontoggle.api_failure]',
      (t) async {
        final w = PhotoWorld();
        w.api.on(
          'PUT /themes/t1/entries/*/like',
          (_) => const QaReply(500, null),
        );
        await openSheet(t, w, entry());
        await tapIn(t, likeButton());
        expect(w.api.sent('PUT', '/themes/t1/entries/e1/like'), hasLength(1));
        expect(likeCount(t), '3');
        expect(
          find.descendant(
            of: likeButton(),
            matching: find.byIcon(Icons.favorite_border_rounded),
          ),
          findsOneWidget,
        );
        expect(qaSnackText(t), en.blogReactionFailed);
        expect(t.widget<TextButton>(likeButton()).onPressed, isNotNull);
      },
    );

    testWidgets(
      'The author’s reach switch saves the choice and says the photo can '
      'reach walls now '
      '[case:photo_themes.photo_theme_widgets.photo_featuring_x.action]',
      (t) async {
        final w = PhotoWorld();
        await openSheet(t, w, entry(mine: true));
        final reach = key('photo.featuring.e1');
        expect(t.widget<SwitchListTile>(reach).value, isFalse);
        await tapIn(t, reach);
        expect(
          w.api.sent('POST', '/themes/t1/entries/e1/featuring').single.body,
          {'allow': true},
        );
        expect(t.widget<SwitchListTile>(reach).value, isTrue);
        expect(qaSnackText(t), en.photoThemesReachOn);
      },
    );

    testWidgets(
      'A reach change that fails says so, keeps the switch where it was and '
      'lets the author try again '
      '[case:photo_themes.photo_theme_widgets.photo_featuring_x.api_failure]',
      (t) async {
        final w = PhotoWorld();
        w.api.on(
          'POST /themes/t1/entries/*/featuring',
          (_) => const QaReply(500, null),
        );
        await openSheet(t, w, entry(mine: true));
        final reach = key('photo.featuring.e1');
        await tapIn(t, reach);
        expect(qaSnackText(t), en.photoThemesSaveFailed);
        expect(t.widget<SwitchListTile>(reach).value, isFalse);
        expect(t.widget<SwitchListTile>(reach).onChanged, isNotNull);
      },
    );

    testWidgets(
      'A photo that cannot load shows Photo unavailable. Retry, which loads '
      'it again '
      '[case:photo_themes.photo_theme_widgets.photo_unavailable_retry.action]',
      (t) async {
        final w = PhotoWorld();
        w.api.fail('GET /themes/t1/entries/*/photo', status: 404);
        await openSheet(t, w, entry());
        final retry = inSheet(find.byTooltip(en.photoThemesPhotoUnavailable));
        expect(retry, findsOneWidget);

        w.api.on('GET /themes/t1/entries/*/photo', (_) => QaReply(200, png));
        await tapIn(t, retry);
        expect(w.api.sent('GET', '/themes/t1/entries/e1/photo'), hasLength(2));
        expect(
          inSheet(find.byTooltip(en.photoThemesPhotoUnavailable)),
          findsNothing,
        );
        expect(
          inSheet(
            find.bySemanticsLabel('A stack of pancakes on a balcony table'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Remove my photo asks first, then deletes it and closes the sheet '
      '[case:photo_themes.photo_theme_widgets.remove_my_photo.action]',
      (t) async {
        final w = PhotoWorld();
        await openSheet(t, w, entry(mine: true));
        expect(inSheet(find.text(en.photoThemesReport)), findsNothing);
        await tapIn(t, inSheet(find.text(en.photoThemesRemoveMine)));
        expect(inDialog(find.text(en.photoThemesRemoveTitle)), findsOneWidget);
        expect(w.api.writes.where((c) => c.method == 'DELETE'), isEmpty);

        await t.tap(inDialog(find.text(en.photoThemesRemoveAction)));
        await qaSettle(t);
        expect(
          w.api.writes.where((c) => c.method == 'DELETE').map((c) => c.path),
          ['/themes/t1/entries/e1'],
        );
        expect(find.byType(ThemeEntrySheet), findsNothing);
      },
    );

    testWidgets('Report sends the reason for this photo and thanks the member '
        '[case:photo_themes.photo_theme_widgets.report.action]', (t) async {
      final w = PhotoWorld();
      await openSheet(t, w, entry());
      await tapIn(t, inSheet(find.text(en.photoThemesReport)));
      await t.enterText(
        find.widgetWithText(TextField, en.reportDescriptionLabel),
        'Not a Sunday photo.',
      );
      await t.tap(find.text(en.reportSubmit));
      await qaSettle(t);

      final report = w.api.sent('POST', '/blog/reports/theme_entry/e1');
      expect(report.single.body['description'], 'Not a Sunday photo.');
      expect(report.single.body['reason'], isNotEmpty);
      expect(qaSnackText(t), en.communityReportSubmitted);
      expect(find.text(en.reportSubmit), findsNothing);
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
    });

    testWidgets(
      'A report that fails keeps the report open with what was written and '
      'says so '
      '[case:photo_themes.photo_theme_widgets.report.api_failure]',
      (t) async {
        final w = PhotoWorld();
        w.api.fail('POST /blog/reports/theme_entry/*');
        await openSheet(t, w, entry());
        await tapIn(t, inSheet(find.text(en.photoThemesReport)));
        await t.enterText(
          find.widgetWithText(TextField, en.reportDescriptionLabel),
          'Not a Sunday photo.',
        );
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);

        expect(
          w.api.sent('POST', '/blog/reports/theme_entry/e1'),
          hasLength(1),
        );
        expect(qaSnackText(t), en.reportSubmitFailed);
        expect(find.text(en.reportSubmit), findsOneWidget);
        expect(find.text('Not a Sunday photo.'), findsOneWidget);
      },
    );

    testWidgets('Block asks first, blocks the author and closes the sheet '
        '[case:photo_themes.photo_theme_widgets.block_name.action]', (t) async {
      final w = PhotoWorld();
      await openSheet(t, w, entry());
      await tapIn(t, inSheet(find.text(en.photoThemesBlock('Priya Sharma'))));
      expect(
        inDialog(find.text(en.communityBlockTitle('Priya Sharma'))),
        findsOneWidget,
      );
      expect(w.api.sent('POST', '/safety/block'), isEmpty);

      await t.tap(inDialog(find.text(en.communityBlockAction)));
      await qaSettle(t);
      expect(w.api.sent('POST', '/safety/block').single.body, {
        'user_id': 'me',
        'blocked_user_id': 'priya',
      });
      expect(find.byType(ThemeEntrySheet), findsNothing);
    });

    testWidgets('A block that fails says so and keeps the photo open '
        '[case:photo_themes.photo_theme_widgets.block_name.api_failure]', (
      t,
    ) async {
      final w = PhotoWorld();
      w.api.on('POST /safety/block', (_) => const QaReply(500, null));
      await openSheet(t, w, entry());
      await tapIn(t, inSheet(find.text(en.photoThemesBlock('Priya Sharma'))));
      await t.tap(inDialog(find.text(en.communityBlockAction)));
      await qaSettle(t);
      expect(w.api.sent('POST', '/safety/block'), hasLength(1));
      expect(qaSnackText(t), en.communityBlockFailed);
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
      expect(
        inSheet(find.text(en.photoThemesBlock('Priya Sharma'))),
        findsOneWidget,
      );
    });

    testWidgets('the sheet renders in every shipped locale with nothing left '
        'in English [case:photo_themes.photo_theme_widgets.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        PhotoWorld().api,
        () => Scaffold(body: ThemeEntrySheet(entry: entry())),
        expected: [
          (l) => l.photoThemesSharedBy('Priya Sharma'),
          (l) => l.photoThemesPhotoDescription(
            'A stack of pancakes on a balcony table',
          ),
          (l) => l.photoThemesReport,
          (l) => l.photoThemesBlock('Priya Sharma'),
        ],
        allow: {'My perfect Sunday', 'Pancakes, then nowhere to be.'},
      );
      // The author's view: reach switch and Remove.
      await qaExpectRendersInAllLocales(
        t,
        PhotoWorld().api,
        () => Scaffold(body: ThemeEntrySheet(entry: entry(mine: true))),
        expected: [
          (l) => l.photoThemesSharedByYou,
          (l) => l.photoThemesReachSwitch,
          (l) => l.photoThemesRemoveMine,
        ],
        allow: {'My perfect Sunday', 'Pancakes, then nowhere to be.'},
      );
    });
  });
}
