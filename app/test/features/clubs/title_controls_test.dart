import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_widgets.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/title_picker.dart';

import '../../support/qa_api.dart';
import 'clubs_qa_fixtures.dart';

// A title's page (reviews, my review, report) and the shared title picker
// (search the catalogue or add a new book/film) used by the pick sheet and
// by "Add a title" on a list.

Future<ClubsWorld> _title(
  WidgetTester t, {
  void Function(ClubsWorld w)? setup,
}) async {
  final w = ClubsWorld();
  setup?.call(w);
  await pumpQa(t, w.api, const TitleDetailScreen(titleId: 'title-1'));
  return w;
}

int _titleLoads(ClubsWorld w) =>
    w.api.sent('GET', '/clubs/titles/title-1').length;

/// A caller of [pickTitle] that records what the picker hands back.
Widget _pickerHost(String kind, List<Title?> picked) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        key: const ValueKey('qa.test.pick'),
        onPressed: () async => picked.add(await pickTitle(context, kind: kind)),
        child: const Text('pick'),
      ),
    ),
  ),
);

Future<ClubsWorld> _picker(
  WidgetTester t,
  List<Title?> picked, {
  String kind = 'book',
}) async {
  final w = ClubsWorld();
  await pumpQa(t, w.api, _pickerHost(kind, picked));
  await t.tap(find.byKey(const ValueKey('qa.test.pick')));
  await qaSettle(t);
  expect(inSheet(find.text('Choose a title')), findsOneWidget);
  return w;
}

Finder _field(String label) => inSheet(find.widgetWithText(TextField, label));

Future<void> _search(
  WidgetTester t,
  String query, {
  String kind = 'books',
}) async {
  await t.enterText(_field('Search $kind'), query);
  await qaSettle(t, frames: 6);
}

List<Map<String, dynamic>> _searches(ClubsWorld w) => [
  for (final c in w.api.sent('GET', '/clubs/titles')) c.query,
];

Future<void> _startAdding(WidgetTester t, {String kind = 'book'}) async {
  await t.tap(inSheet(find.text('Add a new $kind')));
  await qaSettle(t);
  expect(inSheet(find.text('Add and choose')), findsOneWidget);
}

void main() {
  group('title page', () {
    testWidgets('This title could not load: Try again reloads it '
        '[case:clubs.title_detail.this_title_could_not_load_onaction.action]', (
      t,
    ) async {
      final w = await _title(
        t,
        setup: (w) => w.api.fail(
          'GET /clubs/titles/*',
          status: 404,
          message: 'This title is gone.',
        ),
      );
      expect(find.text('This title could not load'), findsOneWidget);
      expect(find.text('This title is gone.'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget, reason: 'fallback app bar');

      w.heal('GET /clubs/titles/*');
      await t.tap(find.text('Try again'));
      await qaSettle(t);
      expect(_titleLoads(w), 2);
      expect(find.text('This title could not load'), findsNothing);
      expect(find.text('Piranesi'), findsWidgets);
      expect(find.text('4.5 · 2 reviews'), findsOneWidget);
    });

    testWidgets(
      'Pull to refresh brings in new reviews '
      '[case:clubs.title_detail.when_members_you_can_see_share_a_onrefresh.action]',
      (t) async {
        final w = await _title(t, setup: (w) => w.reviews.clear());
        expect(find.text('No other reviews yet'), findsOneWidget);
        expect(find.text(en.clubsNoOtherReviewsMessage), findsOneWidget);

        w.reviews.add({
          'id': 'r-rin',
          'title_id': 'title-1',
          'author_id': 'u-rin',
          'author_name': 'Rin',
          'rating': 5,
          'body': 'The twist is the statues are alive.',
          'has_spoilers': true,
          'audience': 'friends',
          'version': 1,
          'mine': false,
        });
        final loads = _titleLoads(w);
        await pullToRefresh(t);
        expect(_titleLoads(w), loads + 1);
        expect(find.text('No other reviews yet'), findsNothing);
        await scrollTo(t, find.text('Rin'));
        // Spoilers stay hidden until tapped.
        expect(find.text('Spoiler — tap to reveal'), findsOneWidget);
        await t.tap(find.text('Spoiler — tap to reveal'));
        await qaSettle(t);
        expect(
          find.text('The twist is the statues are alive.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Delete my review asks first, then removes it '
        '[case:clubs.title_detail.delete.action]', (t) async {
      final w = await _title(t, setup: (w) => w.giveMyReview());
      expect(find.text('Your review'), findsOneWidget);
      await t.tap(find.text('Delete'));
      await qaSettle(t);
      expect(inDialog(find.text('Delete your review?')), findsOneWidget);
      expect(inDialog(find.text(en.clubsDeleteReviewMessage)), findsOneWidget);
      await t.tap(inDialog(find.text('Cancel')));
      await qaSettle(t);
      expect(w.api.writes, isEmpty);
      expect(find.text('Slow start, then wonderful.'), findsOneWidget);

      final loads = _titleLoads(w);
      await t.tap(find.text('Delete'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Delete review')));
      await qaSettle(t);
      final delete = w.api.sent('DELETE', '/clubs/reviews/*').single;
      expect(delete.path, '/clubs/reviews/r-mine');
      expect(delete.data, {'expected_version': 2});
      expect(_titleLoads(w), greaterThan(loads));
      expect(find.text('Your review'), findsNothing);
      expect(find.text('Slow start, then wonderful.'), findsNothing);
      expect(find.text('Write a review'), findsOneWidget);
    });

    testWidgets('Delete review failure says why and keeps the review '
        '[case:clubs.title_detail.delete.api_failure]', (t) async {
      final w = await _title(t, setup: (w) => w.giveMyReview());
      w.api.fail(
        'DELETE /clubs/reviews/*',
        status: 409,
        message: 'Your review changed. Reload and retry.',
      );
      await t.tap(find.text('Delete'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Delete review')));
      await qaSettle(t);
      expect(qaSnackText(t), 'Your review changed. Reload and retry.');
      expect(w.api.sent('DELETE', '/clubs/reviews/*'), hasLength(1));
      expect(find.text('Slow start, then wonderful.'), findsOneWidget);
      expect(isEnabled(t, find.text('Delete')), isTrue);

      await qaSettle(t, frames: 50);
      w.api.on('DELETE /clubs/reviews/*', (_) => const QaReply(500, null));
      await t.tap(find.text('Delete'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Delete review')));
      await qaSettle(t);
      expect(qaSnackText(t), en.clubsReviewDeleteFailed);

      await qaSettle(t, frames: 50);
      w.heal('DELETE /clubs/reviews/*');
      await t.tap(find.text('Delete'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Delete review')));
      await qaSettle(t);
      expect(w.api.sent('DELETE', '/clubs/reviews/*'), hasLength(3));
      expect(find.text('Write a review'), findsOneWidget);
    });

    testWidgets('Report this review files a review report '
        '[case:clubs.title_detail.report_this_review.action]', (t) async {
      final w = await _title(t);
      expect(find.text('A labyrinth of kindness.'), findsOneWidget);
      await t.tap(find.byTooltip('Report this review'));
      await qaSettle(t);
      await submitReport(
        t,
        reason: 'Fraud / scam',
        description: 'Copied from a shop page',
      );
      final report = w.api.sent('POST', '/blog/reports/review/r-sam');
      expect(report.single.body, {
        'reason': 'fraud',
        'description': 'Copied from a shop page',
      });
      expect(find.text('Submit report'), findsNothing);
      expect(qaSnackText(t), 'Report submitted. Thank you.');
    });

    testWidgets('Report this review failure keeps the report sheet; retry '
        'sends it [case:clubs.title_detail.report_this_review.api_failure]', (
      t,
    ) async {
      final w = await _title(t);
      w.api.offline('POST /blog/reports/*/*');
      await t.tap(find.byTooltip('Report this review'));
      await qaSettle(t);
      await submitReport(t, description: 'Rude');
      expect(qaSnackText(t), 'Failed to submit report. Please try again.');
      expect(find.text('Submit report'), findsOneWidget);
      expect(isEnabled(t, find.text('Submit report')), isTrue);
      expect(fieldText(t, 'Description (optional)'), 'Rude');
      expect(w.api.sent('POST', '/blog/reports/review/r-sam'), hasLength(1));

      w.heal('POST /blog/reports/*/*');
      await t.tap(find.text('Submit report'));
      await qaSettle(t, frames: 60);
      expect(w.api.sent('POST', '/blog/reports/review/r-sam'), hasLength(2));
      expect(find.text('Submit report'), findsNothing);
      expect(find.text('Report submitted. Thank you.'), findsOneWidget);
    });

    testWidgets('Title page renders in every locale '
        '[case:clubs.title_detail.l10n]', (t) async {
      await sweepLocales(
        t,
        screen: () => const TitleDetailScreen(titleId: 'title-1'),
        open: (t, l10n) async {
          expect(find.byTooltip(l10n.clubsReportReview), findsOneWidget);
        },
        labels: (l10n) => [
          l10n.clubsBadgeBook,
          l10n.clubsRatingSummary(formatClubRating(l10n, 4.5), 2),
          l10n.clubsAddToAList,
          l10n.clubsWhatDidYouThink,
          l10n.clubsWriteReview,
          l10n.clubsReviews,
        ],
      );
    });
  });

  group('title picker', () {
    testWidgets('Search waits for typing to pause, then lists matches '
        '[case:clubs.title_picker.type_at_least_2_letters.action]', (t) async {
      final picked = <Title?>[];
      final w = await _picker(t, picked);
      expect(inSheet(find.text('Type at least 2 letters')), findsOneWidget);

      await t.enterText(_field('Search books'), 'kl');
      await t.pump(const Duration(milliseconds: 200));
      expect(_searches(w), isEmpty, reason: 'debounced');
      await qaSettle(t, frames: 4);
      expect(_searches(w), [
        {'kind': 'book', 'q': 'kl'},
      ]);
      expect(inSheet(find.text('Klara and the Sun')), findsOneWidget);
      expect(inSheet(find.text('Kazuo Ishiguro · 2021')), findsOneWidget);

      await _search(t, 'zzz');
      expect(
        inSheet(find.text('No books match. Add it below.')),
        findsOneWidget,
      );
      expect(inSheet(find.text('Klara and the Sun')), findsNothing);
      expect(picked, isEmpty);
    });

    testWidgets('A film picker searches films', (t) async {
      final picked = <Title?>[];
      final w = await _picker(t, picked, kind: 'film');
      await _search(t, 'por', kind: 'films');
      expect(_searches(w).single, {'kind': 'film', 'q': 'por'});
      expect(inSheet(find.text('Portrait of a Lady on Fire')), findsOneWidget);
      await _search(t, 'zzz', kind: 'films');
      expect(
        inSheet(find.text('No films match. Add it below.')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Search ignores one letter and blanks, sends one request for fast '
      'typing, and keeps RTL/emoji queries intact '
      '[case:clubs.title_picker.type_at_least_2_letters.validation]',
      (t) async {
        final picked = <Title?>[];
        final w = await _picker(t, picked);
        await _search(t, 'k');
        await _search(t, '  k  ');
        await _search(t, '     ');
        expect(_searches(w), isEmpty);
        expect(inSheet(find.byType(ListTile)), findsNothing);

        for (final q in ['p', 'pi', 'pir']) {
          await t.enterText(_field('Search books'), q);
          await t.pump(const Duration(milliseconds: 100));
        }
        await qaSettle(t, frames: 5);
        expect(_searches(w), [
          {'kind': 'book', 'q': 'pir'},
        ]);

        await _search(t, '  كلارا 🌞  ');
        expect(_searches(w).last, {'kind': 'book', 'q': 'كلارا 🌞'});
        expect(
          inSheet(find.text('No books match. Add it below.')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Search failure says why and still offers to add the title '
        '[case:clubs.title_picker.type_at_least_2_letters.api_failure]', (
      t,
    ) async {
      final picked = <Title?>[];
      final w = await _picker(t, picked);
      w.api.fail(
        'GET /clubs/titles',
        status: 503,
        message: 'Search is paused.',
      );
      await _search(t, 'kla');
      expect(inSheet(find.text('Search is paused.')), findsOneWidget);
      expect(inSheet(find.text('Add a new book')), findsOneWidget);

      w.api.on('GET /clubs/titles', (_) => const QaReply(500, null));
      await _search(t, 'klar');
      expect(inSheet(find.text('Search is unavailable.')), findsOneWidget);

      w.heal('GET /clubs/titles');
      await _search(t, 'klara');
      expect(inSheet(find.text('Klara and the Sun')), findsOneWidget);
      expect(picked, isEmpty);
    });

    testWidgets('Tapping a result closes the picker and hands the title back '
        '[case:clubs.title_picker.listtile_ontap.action]', (t) async {
      final picked = <Title?>[];
      final w = await _picker(t, picked);
      await _search(t, 'kla');
      await t.tap(inSheet(find.text('Klara and the Sun')));
      await qaSettle(t);
      expect(find.byType(BottomSheet), findsNothing);
      expect(picked, hasLength(1));
      expect(picked.single!.id, 'title-2');
      expect(picked.single!.title, 'Klara and the Sun');
      expect(w.api.writes, isEmpty);
    });

    testWidgets('Add a new book opens the form, prefilled from the search '
        '[case:clubs.title_picker.add_icon_add.action]', (t) async {
      final picked = <Title?>[];
      await _picker(t, picked);
      await t.enterText(_field('Search books'), '  The Buried Giant ');
      await _startAdding(t);
      expect(fieldText(t, 'Title'), 'The Buried Giant');
      expect(_field('Author'), findsOneWidget);
      expect(_field('Year (optional)'), findsOneWidget);
      expect(
        inSheet(find.widgetWithText(TextButton, 'Add a new book')),
        findsNothing,
      );
    });

    testWidgets('A film picker asks for the director', (t) async {
      final picked = <Title?>[];
      await _picker(t, picked, kind: 'film');
      await _startAdding(t, kind: 'film');
      expect(_field('Director'), findsOneWidget);
      expect(_field('Author'), findsNothing);
    });

    testWidgets(
      'Add and choose saves the new title and hands it back; an existing '
      'title comes back as the catalogue\'s copy '
      '[case:clubs.title_picker.add_and_choose.action] '
      '[case:clubs.title_picker.title_input.action] '
      '[case:clubs.title_picker.author_input.action] '
      '[case:clubs.title_picker.year_optional_input.action]',
      (t) async {
        final picked = <Title?>[];
        final w = await _picker(t, picked);
        await _startAdding(t);
        await t.enterText(_field('Title'), '  The Buried Giant  ');
        await t.enterText(_field('Author'), ' Kazuo Ishiguro ');
        await t.enterText(_field('Year (optional)'), '2015');

        w.slow('PUT /clubs/titles/*');
        await t.tap(inSheet(find.text('Add and choose')));
        await t.pump(const Duration(milliseconds: 100));
        expect(inSheet(find.text('Adding…')), findsOneWidget);
        expect(isEnabled(t, inSheet(find.text('Adding…'))), isFalse);
        await qaSettle(t, frames: 15);

        final put = w.api.sent('PUT', '/clubs/titles/*').single;
        expect(put.path, matches(uuidSegment));
        expect(put.body, {
          'kind': 'book',
          'title': 'The Buried Giant',
          'creator': 'Kazuo Ishiguro',
          'release_year': 2015,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(picked.single!.id, put.path.split('/').last);
        expect(picked.single!.byline, 'Kazuo Ishiguro · 2015');

        // Adding a title the catalogue already has returns that copy.
        await t.tap(find.byKey(const ValueKey('qa.test.pick')));
        await qaSettle(t);
        await _startAdding(t);
        await t.enterText(_field('Title'), 'piranesi');
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/titles/*').last.body, {
          'kind': 'book',
          'title': 'piranesi',
          'creator': '',
          'release_year': null,
        });
        expect(picked.last!.id, 'title-1');
        expect(picked.last!.title, 'Piranesi');
      },
    );

    testWidgets('Add and choose failure keeps the form; retry reuses the id '
        '[case:clubs.title_picker.add_and_choose.api_failure]', (t) async {
      final picked = <Title?>[];
      final w = await _picker(t, picked);
      await _startAdding(t);
      await t.enterText(_field('Title'), 'The Buried Giant');
      await t.enterText(_field('Year (optional)'), '2015');
      w.api.fail(
        'PUT /clubs/titles/*',
        status: 400,
        message: 'Titles are being tidied up.',
      );
      await t.tap(inSheet(find.text('Add and choose')));
      await qaSettle(t);
      expect(inSheet(find.text('Titles are being tidied up.')), findsOneWidget);
      expect(fieldText(t, 'Title'), 'The Buried Giant');
      expect(fieldText(t, 'Year (optional)'), '2015');
      expect(isEnabled(t, inSheet(find.text('Add and choose'))), isTrue);
      expect(picked, isEmpty);

      w.api.on('PUT /clubs/titles/*', (_) => const QaReply(500, null));
      await t.tap(inSheet(find.text('Add and choose')));
      await qaSettle(t);
      expect(inSheet(find.text(en.clubsTitleAddFailed)), findsOneWidget);

      w.heal('PUT /clubs/titles/*');
      await t.tap(inSheet(find.text('Add and choose')));
      await qaSettle(t);
      final puts = w.api.sent('PUT', '/clubs/titles/*');
      expect(puts, hasLength(3));
      expect(puts.map((c) => c.path).toSet(), hasLength(1));
      expect(picked.single!.title, 'The Buried Giant');
    });

    testWidgets(
      'Title: empty and blank are refused; over 200 is cut; RTL and emoji '
      'are kept [case:clubs.title_picker.title_input.validation]',
      (t) async {
        final picked = <Title?>[];
        final w = await _picker(t, picked);
        await _startAdding(t);
        for (final bad in ['', '   ']) {
          await t.enterText(_field('Title'), bad);
          await t.tap(inSheet(find.text('Add and choose')));
          await qaSettle(t);
          expect(inSheet(find.text('Enter the title.')), findsOneWidget);
        }
        expect(w.api.writes, isEmpty);

        await t.enterText(_field('Title'), 'T' * 201);
        expect(fieldText(t, 'Title'), 'T' * 200);

        const name = 'ألف ليلة وليلة 🧞';
        await t.enterText(_field('Title'), name);
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/titles/*').single.body['title'], name);
        expect(picked.single!.title, name);
      },
    );

    testWidgets(
      'Author: optional, blank is sent empty, over 120 is cut, RTL and emoji '
      'are kept [case:clubs.title_picker.author_input.validation]',
      (t) async {
        final picked = <Title?>[];
        final w = await _picker(t, picked);
        await _startAdding(t);
        await t.enterText(_field('Title'), 'Anonymous Tales');
        await t.enterText(_field('Author'), '    ');
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/titles/*').last.body['creator'], '');

        await t.tap(find.byKey(const ValueKey('qa.test.pick')));
        await qaSettle(t);
        await _startAdding(t);
        await t.enterText(_field('Author'), 'A' * 121);
        expect(fieldText(t, 'Author'), 'A' * 120);
        const author = 'עמוס עוז ✍️';
        await t.enterText(_field('Title'), 'A Tale of Love and Darkness');
        await t.enterText(_field('Author'), author);
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/titles/*').last.body['creator'],
          author,
        );
        expect(picked.last!.creator, author);
      },
    );

    testWidgets(
      'Year: letters and years outside 1450–2100 are refused with a message; '
      'empty is sent as null; at most 4 digits '
      '[case:clubs.title_picker.year_optional_input.validation]',
      (t) async {
        final picked = <Title?>[];
        final w = await _picker(t, picked);
        await _startAdding(t);
        await t.enterText(_field('Title'), 'Old Book');
        for (final bad in ['abcd', '1449', '2101', '20x5']) {
          await t.enterText(_field('Year (optional)'), bad);
          await t.tap(inSheet(find.text('Add and choose')));
          await qaSettle(t);
          expect(
            inSheet(find.text('Enter a year between 1450 and 2100.')),
            findsOneWidget,
            reason: bad,
          );
        }
        expect(w.api.writes, isEmpty);

        await t.enterText(_field('Year (optional)'), '');
        await t.enterText(_field('Year (optional)'), '14500');
        expect(fieldText(t, 'Year (optional)'), '1450');
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/titles/*').last.body['release_year'],
          1450,
        );

        await t.tap(find.byKey(const ValueKey('qa.test.pick')));
        await qaSettle(t);
        await _startAdding(t);
        await t.enterText(_field('Title'), 'Undated Zine');
        await t.enterText(_field('Year (optional)'), '');
        await t.tap(inSheet(find.text('Add and choose')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/titles/*').last.body,
          containsPair('release_year', null),
        );
        expect(picked.last!.releaseYear, isNull);
      },
    );

    testWidgets('Title picker renders in every locale '
        '[case:clubs.title_picker.l10n]', (t) async {
      await sweepLocales(
        t,
        screen: () => _pickerHost('book', []),
        open: (t, l10n) async {
          await t.tap(find.byKey(const ValueKey('qa.test.pick')));
          await qaSettle(t);
          await t.enterText(
            find.widgetWithText(TextField, l10n.clubsSearchBooks),
            'zzz',
          );
          await qaSettle(t, frames: 6);
          expect(find.text(l10n.clubsNoBooksMatch), findsOneWidget);
          await t.tap(find.text(l10n.clubsAddNewBook));
          await qaSettle(t);
          await t.enterText(
            find.widgetWithText(TextField, l10n.clubsTitleFieldLabel),
            '',
          );
          await t.tap(find.text(l10n.clubsAddAndChoose));
          await qaSettle(t);
        },
        labels: (l10n) => [
          l10n.clubsChooseTitle,
          l10n.clubsTypeTwoLetters,
          l10n.clubsAddNewBook,
          l10n.clubsTitleFieldLabel,
          l10n.clubsAuthor,
          l10n.clubsYearOptional,
          l10n.clubsEnterTitle,
        ],
      );
    });
  });
}
