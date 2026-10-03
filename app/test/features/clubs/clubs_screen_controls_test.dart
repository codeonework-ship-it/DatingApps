import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/club_widgets.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/clubs/my_lists_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import 'clubs_qa_fixtures.dart';

// Book & Film Clubs list: every control on the screen and in the "Start a
// club" sheet, asserting the request that reaches the server and what the
// member sees next.

Future<ClubsWorld> _open(WidgetTester t, {String role = 'owner'}) async {
  final w = ClubsWorld(role: role);
  await pumpQa(t, w.api, const ClubsScreen());
  return w;
}

List<Map<String, dynamic>> _clubQueries(ClubsWorld w) => [
  for (final c in w.api.sent('GET', '/clubs')) c.query,
];

Future<void> _openStartSheet(WidgetTester t) async {
  await t.tap(find.byTooltip(en.clubsStartClubTooltip));
  await qaSettle(t);
  expect(inSheet(find.text(en.clubsStartClub)), findsOneWidget);
}

Finder get _nameField => inSheet(find.widgetWithText(TextField, 'Club name'));
Finder get _aboutField => inSheet(
  find.widgetWithText(TextField, 'What is your club about? (optional)'),
);

void main() {
  testWidgets('My lists opens the member\'s shelf with their lists '
      '[case:clubs.clubs.my_lists.action]', (t) async {
    final w = await _open(t);
    await t.tap(find.byTooltip('My lists'));
    await qaSettle(t);

    expect(find.byType(MyListsScreen), findsOneWidget);
    expect(w.api.sent('GET', '/clubs/lists'), hasLength(1));
    expect(find.text('Your shelf'), findsOneWidget);
    expect(find.text('Read next'), findsOneWidget);
    expect(w.api.writes, isEmpty);

    await t.pageBack();
    await qaSettle(t);
    expect(find.byType(MyListsScreen), findsNothing);
    expect(find.text('Book & Film Clubs'), findsOneWidget);
  });

  testWidgets('Start a club: name, about and Books create the club and open it '
      '[case:clubs.clubs.start_a_book_or_film_club.action] '
      '[case:clubs.clubs.create_club.action] '
      '[case:clubs.clubs.club_name_input.action] '
      '[case:clubs.clubs.what_is_your_club_about_optional_input.action]', (
    t,
  ) async {
    final w = await _open(t);
    final listLoads = w.api.sent('GET', '/clubs').length;
    await _openStartSheet(t);

    // Books is preselected; the fields start empty.
    final segments = t.widget<SegmentedButton<String>>(
      inSheet(find.byType(SegmentedButton<String>)),
    );
    expect(segments.selected, {'book'});
    await t.enterText(_nameField, '  Moonlit Pages  ');
    await t.enterText(_aboutField, 'Ghost stories by lamplight.\nBYO tea.');
    expect(fieldText(t, 'Club name'), '  Moonlit Pages  ');

    w.slow('PUT /clubs/*');
    await t.tap(inSheet(find.text('Create club')));
    await t.pump(const Duration(milliseconds: 100));
    // Busy: the button says so and ignores a second tap.
    expect(inSheet(find.text('Creating…')), findsOneWidget);
    expect(isEnabled(t, inSheet(find.text('Creating…'))), isFalse);
    await t.tap(inSheet(find.text('Creating…')), warnIfMissed: false);
    await qaSettle(t, frames: 15);

    final puts = w.api.sent('PUT', '/clubs/*');
    expect(puts, hasLength(1));
    expect(puts.single.path, matches(uuidSegment));
    expect(puts.single.body, {
      'kind': 'book',
      'name': 'Moonlit Pages',
      'description': 'Ghost stories by lamplight.\nBYO tea.',
      'expected_version': 0,
    });
    // The sheet closed and the new club opened.
    expect(find.byType(BottomSheet), findsNothing);
    final detail = t.widget<ClubDetailScreen>(find.byType(ClubDetailScreen));
    final id = puts.single.path.split('/').last;
    expect(detail.clubId, id);
    expect(w.api.sent('GET', '/clubs/$id'), hasLength(1));
    expect(find.text('Moonlit Pages'), findsWidgets);
    expect(find.text('You: Owner'), findsOneWidget);
    expect(find.text(en.clubsNoPickModerator), findsOneWidget);
    // The list behind it reloaded and now shows the club.
    expect(w.api.sent('GET', '/clubs').length, greaterThan(listLoads));
    await t.pageBack();
    await qaSettle(t);
    await scrollTo(t, find.text('Moonlit Pages'));
    expect(find.text('Moonlit Pages'), findsOneWidget);
  });

  testWidgets(
    'Start a club: the Films segment makes a film club '
    '[case:clubs.clubs.segmentedbutton_onselectionchang_onselectionchanged.action]',
    (t) async {
      final w = await _open(t);
      await _openStartSheet(t);
      await t.tap(inSheet(find.text('Films')));
      await qaSettle(t);
      expect(
        t
            .widget<SegmentedButton<String>>(
              inSheet(find.byType(SegmentedButton<String>)),
            )
            .selected,
        {'film'},
      );
      await t.enterText(_nameField, 'Reel Talk');
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);

      expect(w.api.sent('PUT', '/clubs/*').single.body['kind'], 'film');
      expect(find.byType(ClubDetailScreen), findsOneWidget);
      expect(find.text('Film club'), findsOneWidget);
    },
  );

  testWidgets(
    'Create club failure keeps the sheet and typed text; the retry reuses '
    'the same club id [case:clubs.clubs.create_club.api_failure]',
    (t) async {
      final w = await _open(t);
      await _openStartSheet(t);
      await t.enterText(_nameField, 'Moonlit Pages');
      await t.enterText(_aboutField, 'Ghost stories.');

      w.api.fail(
        'PUT /clubs/*',
        status: 409,
        message: 'A club with that name already exists.',
      );
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(
        inSheet(find.text('A club with that name already exists.')),
        findsOneWidget,
      );
      expect(find.byType(ClubDetailScreen), findsNothing);
      expect(fieldText(t, 'Club name'), 'Moonlit Pages');
      expect(
        fieldText(t, 'What is your club about? (optional)'),
        'Ghost stories.',
      );
      expect(isEnabled(t, inSheet(find.text('Create club'))), isTrue);
      expect(w.api.sent('PUT', '/clubs/*'), hasLength(1));

      // Offline: a readable connection message, still nothing lost.
      w.api.offline('PUT /clubs/*');
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(inSheet(find.text(en.networkOfflineTryAgain)), findsOneWidget);
      expect(fieldText(t, 'Club name'), 'Moonlit Pages');

      // A 500 without a message falls back to the club's own wording.
      w.api.on('PUT /clubs/*', (_) => const QaReply(500, null));
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(inSheet(find.text(en.clubsCreateFailed)), findsOneWidget);

      w.heal('PUT /clubs/*');
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      final puts = w.api.sent('PUT', '/clubs/*');
      expect(puts, hasLength(4));
      expect(
        puts.map((c) => c.path).toSet(),
        hasLength(1),
        reason: 'retries reuse one id, so no duplicate club',
      );
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(ClubDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Club name: empty, whitespace and 2 letters are refused with a message; '
    'over 60 is cut; RTL and emoji arrive byte-for-byte '
    '[case:clubs.clubs.club_name_input.validation]',
    (t) async {
      final w = await _open(t);
      await _openStartSheet(t);

      for (final bad in ['', '     ', ' ab ']) {
        await t.enterText(_nameField, bad);
        await t.tap(inSheet(find.text('Create club')));
        await qaSettle(t);
        expect(inSheet(find.text(en.clubsNameTooShort)), findsOneWidget);
      }
      expect(w.api.writes, isEmpty);

      await t.enterText(_nameField, 'x' * 61);
      expect(fieldText(t, 'Club name'), 'x' * 60);

      const name = 'نادي الكتب 📚 Café';
      await t.enterText(_nameField, name);
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(w.api.sent('PUT', '/clubs/*').single.body['name'], name);
      expect(find.text(name), findsWidgets);
    },
  );

  testWidgets(
    'Club description: optional, whitespace-only is sent empty, over 500 is '
    'cut, emoji and RTL are preserved '
    '[case:clubs.clubs.what_is_your_club_about_optional_input.validation]',
    (t) async {
      final w = await _open(t);
      await _openStartSheet(t);
      await t.enterText(_nameField, 'Moonlit Pages');

      await t.enterText(_aboutField, 'y' * 501);
      expect(fieldText(t, 'What is your club about? (optional)'), 'y' * 500);

      await t.enterText(_aboutField, '   \n  ');
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(w.api.sent('PUT', '/clubs/*').last.body['description'], '');

      // Second club: unicode description.
      await t.pageBack();
      await qaSettle(t);
      await _openStartSheet(t);
      const about = 'קוראים יחד 🌙 — חמישי בערב';
      await t.enterText(_nameField, 'Night Readers');
      await t.enterText(_aboutField, about);
      await t.tap(inSheet(find.text('Create club')));
      await qaSettle(t);
      expect(w.api.sent('PUT', '/clubs/*').last.body['description'], about);
      expect(find.text(about), findsOneWidget);
    },
  );

  testWidgets('showClubSheet opens with a drag handle and a Close button that '
      'dismisses without saving '
      '[case:clubs.club_widgets.showmodalbottomsheet_open.action]', (t) async {
    final w = await _open(t);
    await _openStartSheet(t);
    final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.showDragHandle, isTrue);
    final close = find.byKey(const ValueKey('qa.sheet.close'));
    expect(close, findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await t.enterText(_nameField, 'Half-typed');
    await t.tap(close);
    await qaSettle(t);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(ClubDetailScreen), findsNothing);
    expect(w.api.writes, isEmpty);
  });

  testWidgets('No Start a club button for members who are not eligible yet', (
    t,
  ) async {
    final w = ClubsWorld(role: 'owner')..eligible = false;
    await pumpQa(t, w.api, const ClubsScreen());
    expect(find.byTooltip(en.clubsStartClubTooltip), findsNothing);
    expect(find.text(en.clubsLookAroundTitle), findsOneWidget);
  });

  testWidgets('Pull to refresh reloads the clubs '
      '[case:clubs.clubs.try_again_onrefresh.action]', (t) async {
    final w = await _open(t);
    expect(find.text('Sunday Slow Reads'), findsOneWidget);
    final loads = w.api.sent('GET', '/clubs').length;

    w.memberCount = 9;
    await pullToRefresh(t);

    expect(w.api.sent('GET', '/clubs').length, loads + 1);
    expect(_clubQueries(w).last, {'scope': 'mine'});
    await scrollTo(t, find.text('9 members'));
    expect(find.text('9 members'), findsOneWidget);
    expect(find.text('8 members'), findsNothing);
  });

  testWidgets('My clubs / Discover switches the list '
      '[case:clubs.clubs.my_clubs_onselectionchanged.action]', (t) async {
    final w = await _open(t);
    expect(_clubQueries(w), [
      {'scope': 'mine'},
    ]);
    expect(find.text('Sunday Slow Reads'), findsOneWidget);

    await t.tap(find.text('Discover'));
    await qaSettle(t);
    expect(_clubQueries(w).last, {'scope': 'discover'});
    await scrollTo(t, find.text('Night Owls Read'));
    expect(find.text('Night Owls Read'), findsOneWidget);
    expect(find.text('Sunday Slow Reads'), findsNothing);

    await t.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await qaSettle(t);
    await t.tap(find.text('My clubs'));
    await qaSettle(t);
    expect(find.text('Sunday Slow Reads'), findsOneWidget);
    expect(find.text('Night Owls Read'), findsNothing);
  });

  testWidgets('Kind chips filter the clubs by Books / Films / All '
      '[case:clubs.clubs.choicechip_onselected.action]', (t) async {
    final w = await _open(t);
    ChoiceChip chip(String label) =>
        t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
    expect(chip('All').selected, isTrue);

    await t.tap(find.widgetWithText(ChoiceChip, 'Films'));
    await qaSettle(t);
    expect(_clubQueries(w).last, {'scope': 'mine', 'kind': 'film'});
    expect(chip('Films').selected, isTrue);
    expect(chip('All').selected, isFalse);
    await scrollTo(t, find.text('Midnight Movies'));
    expect(find.text('Sunday Slow Reads'), findsNothing);

    await t.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await qaSettle(t);
    await t.tap(find.widgetWithText(ChoiceChip, 'Books'));
    await qaSettle(t);
    expect(_clubQueries(w).last, {'scope': 'mine', 'kind': 'book'});
    expect(find.text('Midnight Movies'), findsNothing);

    await t.tap(find.widgetWithText(ChoiceChip, 'All'));
    await qaSettle(t);
    expect(_clubQueries(w).last, {'scope': 'mine'});
  });

  testWidgets('Clubs could not load shows the reason; Try again reloads '
      '[case:clubs.clubs.clubs_could_not_load_onaction.action]', (t) async {
    final w = ClubsWorld(role: 'owner');
    w.api.fail('GET /clubs', status: 503, message: 'Clubs are resting.');
    await pumpQa(t, w.api, const ClubsScreen());

    expect(find.text('Clubs could not load'), findsOneWidget);
    expect(find.text('Clubs are resting.'), findsOneWidget);
    expect(find.text('Sunday Slow Reads'), findsNothing);

    w.heal('GET /clubs');
    await t.tap(find.text('Try again'));
    await qaSettle(t);
    expect(w.api.sent('GET', '/clubs'), hasLength(2));
    expect(find.text('Clubs could not load'), findsNothing);
    expect(find.text('Sunday Slow Reads'), findsOneWidget);
  });

  testWidgets('No clubs of my own: Discover clubs switches to Discover '
      '[case:clubs.clubs.no_clubs_here_yet_ondiscover.action]', (t) async {
    final w = ClubsWorld(role: '');
    w.api.on(
      'GET /clubs',
      (call) => qaOk({
        'clubs': call.query['scope'] == 'mine'
            ? const <Object>[]
            : [w.nightOwls],
        'eligible': true,
      }),
    );
    await pumpQa(t, w.api, const ClubsScreen());
    await scrollTo(t, find.text('Discover clubs'));
    expect(find.text(en.clubsEmptyMineTitle), findsOneWidget);

    await t.tap(find.text('Discover clubs'));
    await qaSettle(t);
    expect(_clubQueries(w).last, {'scope': 'discover'});
    expect(
      t
          .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>))
          .selected,
      {'discover'},
    );
    await scrollTo(t, find.text('Night Owls Read'));
    expect(find.text('Night Owls Read'), findsOneWidget);

    // Nothing to discover either: the empty notice has no button.
    w.api.json('GET /clubs', {'clubs': const <Object>[], 'eligible': true});
    await pullToRefresh(t);
    expect(find.text('No clubs here yet'), findsOneWidget);
    expect(find.text('Discover clubs'), findsNothing);
  });

  testWidgets('Tapping a club card opens that club '
      '[case:clubs.clubs.no_pick_yet_this_week.action]', (t) async {
    final w = await _open(t);
    await scrollTo(t, find.text('No pick yet this week'));
    expect(find.text('Midnight Movies'), findsOneWidget);
    await t.tap(find.text('No pick yet this week'));
    await qaSettle(t);

    expect(
      t.widget<ClubDetailScreen>(find.byType(ClubDetailScreen)).clubId,
      'club-4',
    );
    expect(w.api.sent('GET', '/clubs/club-4'), hasLength(1));
    expect(find.text('Midnight Movies'), findsWidgets);
    expect(find.text('Film club'), findsOneWidget);
    expect(w.api.writes, isEmpty);
  });

  testWidgets('Clubs screen and Start a club sheet render in every locale '
      '[case:clubs.clubs.l10n]', (t) async {
    await sweepLocales(
      t,
      world: () => ClubsWorld(role: 'owner'),
      screen: () => const ClubsScreen(),
      open: (t, l10n) async {
        expect(find.text(l10n.clubsHeroTitle), findsOneWidget);
        expect(find.text(l10n.clubsMemberCount(8)), findsOneWidget);
        await t.tap(find.byType(FloatingActionButton));
        await qaSettle(t);
      },
      labels: (l10n) => [
        l10n.clubsTitle,
        l10n.clubsScopeMine,
        l10n.clubsScopeDiscover,
        l10n.clubsFilterAll,
        l10n.clubsCreateClub,
        l10n.clubsNameLabel,
        l10n.clubsDescriptionLabel,
      ],
    );
  });

  testWidgets('Club badges, ratings and week pills render in every locale '
      '[case:clubs.club_widgets.l10n]', (t) async {
    final rated = Title.fromJson(
      titleJson(
        't',
        'book',
        'Piranesi',
        'Susanna Clarke',
        average: 4.5,
        reviews: 2,
      ),
    );
    final unrated = Title.fromJson(titleJson('u', 'film', 'X', ''));
    await sweepLocales(
      t,
      screen: () => Scaffold(
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Wrap(
              children: [
                const KindBadge(kind: 'book'),
                const KindBadge(kind: 'film', suffix: 'list'),
                const KindBadge(kind: 'film', suffix: ''),
                RatingSummary(title: rated),
                RatingSummary(title: unrated),
                WeekPill(label: weekLabel(l10n, thisMonday)),
                WeekPill(label: weekLabel(l10n, nextMonday)),
                StarRating(rating: 3, onChanged: (_) {}),
              ],
            );
          },
        ),
      ),
      open: (t, l10n) async {
        expect(find.byTooltip(l10n.clubsStarCount(1)), findsOneWidget);
        expect(find.byTooltip(l10n.clubsStarCount(5)), findsOneWidget);
      },
      labels: (l10n) => [
        l10n.clubsBadgeBookClub,
        l10n.clubsBadgeFilmList,
        l10n.clubsBadgeFilm,
        l10n.clubsRatingSummary(formatClubRating(l10n, 4.5), 2),
        l10n.clubsNoRatingsYet,
        l10n.clubsWeekThis,
        l10n.clubsWeekNext,
      ],
    );
  });
}
