import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/club_discussion.dart';
import 'package:verified_dating_app/features/clubs/club_widgets.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';

import '../../support/qa_api.dart';
import 'clubs_qa_fixtures.dart';

// One club: header actions (join, leave, members, options), the weekly pick
// card, earlier picks, the members sheet and the set-the-pick sheet.

Future<ClubsWorld> _open(
  WidgetTester t, {
  String role = 'member',
  void Function(ClubsWorld w)? setup,
}) async {
  final w = ClubsWorld(role: role);
  setup?.call(w);
  await pumpQa(t, w.api, const ClubDetailScreen(clubId: 'club-1'));
  return w;
}

int _detailLoads(ClubsWorld w) => w.api.sent('GET', '/clubs/club-1').length;

/// The pick whose discussion is shown (scrolls down to it).
Future<String> _discussionFor(WidgetTester t) async {
  await scrollTo(t, find.byType(ClubDiscussion));
  return t.widget<ClubDiscussion>(find.byType(ClubDiscussion)).selection.id;
}

Future<void> _openMembers(WidgetTester t) async {
  await t.tap(find.text('Members'));
  await qaSettle(t);
  expect(inSheet(find.text('Members')), findsOneWidget);
}

Finder _roleOf(String name, String role) => find.descendant(
  of: find.widgetWithText(ListTile, name),
  matching: find.text(role),
);

Future<void> _openPickSheet(WidgetTester t) async {
  await t.tap(find.text('Set this week’s pick'));
  await qaSettle(t);
  expect(inSheet(find.text('Set the weekly pick')), findsOneWidget);
}

/// In the open pick sheet: Choose a book → search [query] → tap [title].
Future<void> _chooseTitle(
  WidgetTester t,
  String query,
  String title, {
  String button = 'Choose a book',
}) async {
  await t.tap(inSheet(find.text(button)));
  await qaSettle(t);
  await t.enterText(
    inSheet(find.widgetWithText(TextField, 'Search books')),
    query,
  );
  await qaSettle(t, frames: 6);
  await t.tap(inSheet(find.text(title)));
  await qaSettle(t);
  expect(inSheet(find.text('Set the weekly pick')), findsOneWidget);
}

void main() {
  group('club options', () {
    testWidgets('Club options → Members opens the member list; Report club '
        'files a report [case:clubs.club_detail.club_options.action]', (
      t,
    ) async {
      final w = await _open(t);
      await t.tap(find.byTooltip('Club options'));
      await qaSettle(t);
      expect(find.text('Report club'), findsOneWidget);
      await t.tap(find.text('Members').last);
      await qaSettle(t);
      expect(inSheet(find.text('Members')), findsOneWidget);
      expect(w.api.sent('GET', '/clubs/club-1/members'), hasLength(1));
      expect(find.text('Alex (you)'), findsOneWidget);
      expect(_roleOf('Rin', 'Moderator'), findsOneWidget);
      expect(_roleOf('Olive', 'Owner'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('qa.sheet.close')));
      await qaSettle(t);

      await chooseFromMenu(t, 'Club options', 'Report club');
      await submitReport(
        t,
        reason: 'Harassment',
        description: 'Spam links in the description',
      );
      final report = w.api.sent('POST', '/blog/reports/club/club-1');
      expect(report, hasLength(1));
      expect(report.single.body, {
        'reason': 'harassment',
        'description': 'Spam links in the description',
      });
      expect(find.text('Submit report'), findsNothing);
      expect(qaSnackText(t), 'Report submitted. Thank you.');
    });

    testWidgets('A visitor\'s club options only offer Report club', (t) async {
      await _open(t, role: '');
      await t.tap(find.byTooltip('Club options'));
      await qaSettle(t);
      expect(find.text('Report club'), findsOneWidget);
      expect(find.text('Members'), findsNothing);
    });

    testWidgets('Report club failure keeps the report sheet open and the '
        'retry succeeds [case:clubs.club_detail.club_options.api_failure]', (
      t,
    ) async {
      final w = await _open(t);
      w.api.fail('POST /blog/reports/*/*', message: 'Reports are paused.');
      await chooseFromMenu(t, 'Club options', 'Report club');
      await submitReport(t, description: 'Hate speech in the name');

      expect(qaSnackText(t), 'Failed to submit report. Please try again.');
      expect(find.text('Submit report'), findsOneWidget);
      expect(isEnabled(t, find.text('Submit report')), isTrue);
      expect(fieldText(t, 'Description (optional)'), 'Hate speech in the name');
      expect(w.api.sent('POST', '/blog/reports/club/club-1'), hasLength(1));

      w.heal('POST /blog/reports/*/*');
      await t.tap(find.text('Submit report'));
      await qaSettle(t, frames: 60); // let the failure snack expire
      expect(w.api.sent('POST', '/blog/reports/club/club-1'), hasLength(2));
      expect(find.text('Submit report'), findsNothing);
      expect(find.text('Report submitted. Thank you.'), findsOneWidget);
    });
  });

  testWidgets('Club could not load shows why; Try again reloads it '
      '[case:clubs.club_detail.this_club_could_not_load_onaction.action]', (
    t,
  ) async {
    final w = await _open(
      t,
      setup: (w) => w.api.fail(
        'GET /clubs/*',
        status: 404,
        message: 'This club is closed.',
      ),
    );
    expect(find.text('This club could not load'), findsOneWidget);
    expect(find.text('This club is closed.'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget, reason: 'fallback app bar title');

    // Without a server message the club's own wording is shown.
    w.api.on('GET /clubs/*', (_) => const QaReply(500, null));
    await t.tap(find.text('Try again'));
    await qaSettle(t);
    expect(find.text('It may have closed. Please try again.'), findsOneWidget);

    w.heal('GET /clubs/*');
    await t.tap(find.text('Try again'));
    await qaSettle(t);
    expect(_detailLoads(w), 3);
    expect(find.text('This club could not load'), findsNothing);
    expect(find.text('Sunday Slow Reads'), findsWidgets);
    expect(find.text('Leave club'), findsOneWidget);
  });

  testWidgets(
    'Pull to refresh reloads the club for a visitor '
    '[case:clubs.club_detail.members_talk_about_each_pick_tog_onrefresh.action]',
    (t) async {
      final w = await _open(t, role: '');
      await scrollTo(t, find.text(en.clubsJoinToSeeMessage));
      expect(find.text('Join to see the discussion'), findsOneWidget);
      expect(find.byType(ClubDiscussion), findsNothing);
      await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await qaSettle(t);

      w.memberCount = 9;
      final before = _detailLoads(w);
      await pullToRefresh(t);
      expect(_detailLoads(w), before + 1);
      expect(find.text('9 members'), findsOneWidget);
      expect(find.text('8 members'), findsNothing);
    },
  );

  testWidgets('Members opens the member list (no actions for a member) '
      '[case:clubs.club_detail.members_onmembers.action]', (t) async {
    final w = await _open(t);
    await _openMembers(t);
    expect(w.api.sent('GET', '/clubs/club-1/members'), hasLength(1));
    expect(find.text('Alex (you)'), findsOneWidget);
    expect(_roleOf('Sam', 'Member'), findsOneWidget);
    expect(_roleOf('Rin', 'Moderator'), findsOneWidget);
    expect(find.byTooltip('Actions for Sam'), findsNothing);
    expect(find.byTooltip('Actions for Rin'), findsNothing);

    await t.tap(find.byKey(const ValueKey('qa.sheet.close')));
    await qaSettle(t);
    expect(find.byType(BottomSheet), findsNothing);
    expect(w.api.writes, isEmpty);
  });

  testWidgets(
    'Open the discussion on an earlier pick, then Discuss this pick back '
    '[case:clubs.club_detail.open_the_discussion.action] '
    '[case:clubs.club_detail.discuss_this_pick_ondiscuss.action]',
    (t) async {
      final w = await _open(t);
      expect(await _discussionFor(t), 'sel-1');
      await scrollTo(t, find.text('Discussion · Piranesi'));
      expect(w.api.sent('GET', '/clubs/club-1/posts').single.query, {
        'selection_id': 'sel-1',
      });
      await scrollTo(t, find.text('The statues in the halls!'));

      await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await qaSettle(t);
      await scrollTo(t, find.byTooltip('Open the discussion'));
      await t.tap(find.byTooltip('Open the discussion'));
      await qaSettle(t);
      expect(
        t
            .widget<ListTile>(
              find.widgetWithText(ListTile, 'Klara and the Sun'),
            )
            .selected,
        isTrue,
      );
      expect(await _discussionFor(t), 'sel-0');
      expect(w.api.sent('GET', '/clubs/club-1/posts').last.query, {
        'selection_id': 'sel-0',
      });
      await scrollTo(t, find.text('Klara made me cry.'));
      expect(find.text('Discussion · Klara and the Sun'), findsOneWidget);
      expect(find.text('The statues in the halls!'), findsNothing);

      await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await qaSettle(t);
      await scrollTo(t, find.text('Discuss this pick'));
      await t.tap(find.text('Discuss this pick'));
      await qaSettle(t);
      expect(await _discussionFor(t), 'sel-1');
      await scrollTo(t, find.text('The statues in the halls!'));
      expect(find.text('Discussion · Piranesi'), findsOneWidget);
      expect(find.text('Klara made me cry.'), findsNothing);
      expect(w.api.writes, isEmpty);
    },
  );

  testWidgets('An earlier pick row opens that title '
      '[case:clubs.club_detail.week_count_plural_1_1_post_other.action]', (
    t,
  ) async {
    final w = await _open(t);
    await scrollTo(t, find.text('Week of 2026-01-05 · 1 post'));
    await t.tap(find.text('Klara and the Sun'));
    await qaSettle(t);

    expect(
      t.widget<TitleDetailScreen>(find.byType(TitleDetailScreen)).titleId,
      'title-2',
    );
    expect(w.api.sent('GET', '/clubs/titles/title-2'), hasLength(1));
    expect(find.text('Kazuo Ishiguro · 2021'), findsOneWidget);
    await t.pageBack();
    await qaSettle(t);
    expect(
      await _discussionFor(t),
      'sel-1',
      reason: 'row tap is not the forum',
    );
  });

  testWidgets('The pick title (with chevron) opens the title page '
      '[case:clubs.club_detail.chevron_right_icon_chevron_right.action]', (
    t,
  ) async {
    final w = await _open(t);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await t.tap(find.byIcon(Icons.chevron_right));
    await qaSettle(t);

    expect(
      t.widget<TitleDetailScreen>(find.byType(TitleDetailScreen)).titleId,
      'title-1',
    );
    expect(w.api.sent('GET', '/clubs/titles/title-1'), hasLength(1));
    expect(find.text('A labyrinth of kindness.'), findsOneWidget);
    await t.pageBack();
    await qaSettle(t);
    expect(find.byType(ClubDetailScreen), findsOneWidget);
  });

  group('membership', () {
    testWidgets('Join club joins, welcomes and opens the discussion '
        '[case:clubs.club_detail.join_club.action]', (t) async {
      final w = await _open(t, role: '');
      expect(find.text('Join club'), findsOneWidget);
      expect(find.text('Leave club'), findsNothing);
      final before = _detailLoads(w);

      w.slow('POST /clubs/*/membership');
      await t.tap(find.text('Join club'));
      await t.pump(const Duration(milliseconds: 100));
      expect(isEnabled(t, find.text('Join club')), isFalse);
      await t.tap(find.text('Join club'), warnIfMissed: false);
      await qaSettle(t, frames: 15);

      final joins = w.api.sent('POST', '/clubs/club-1/membership');
      expect(joins, hasLength(1));
      expect(joins.single.body, {'action': 'join'});
      expect(_detailLoads(w), before + 1);
      expect(qaSnackText(t), 'Welcome to Sunday Slow Reads!');
      expect(find.text('Leave club'), findsOneWidget);
      expect(find.text('9 members'), findsOneWidget);
      expect(await _discussionFor(t), 'sel-1');
    });

    testWidgets('Join club failure says why and lets the member retry '
        '[case:clubs.club_detail.join_club.api_failure]', (t) async {
      final w = await _open(t, role: '');
      w.api.fail(
        'POST /clubs/*/membership',
        status: 403,
        message: 'Complete your profile to join clubs.',
      );
      final before = _detailLoads(w);
      await t.tap(find.text('Join club'));
      await qaSettle(t);

      expect(qaSnackText(t), 'Complete your profile to join clubs.');
      expect(w.api.sent('POST', '/clubs/club-1/membership'), hasLength(1));
      expect(_detailLoads(w), before, reason: 'nothing changed, no reload');
      expect(isEnabled(t, find.text('Join club')), isTrue);
      expect(find.text('Leave club'), findsNothing);

      w.heal('POST /clubs/*/membership');
      await t.tap(find.text('Join club'));
      await qaSettle(t);
      expect(find.text('Leave club'), findsOneWidget);
    });

    testWidgets('Leave club asks first; Cancel keeps me in, Leave leaves '
        '[case:clubs.club_detail.leave_club.action]', (t) async {
      final w = await _open(t);
      await t.tap(find.text('Leave club'));
      await qaSettle(t);
      expect(inDialog(find.text('Leave Sunday Slow Reads?')), findsOneWidget);
      expect(inDialog(find.text(en.clubsLeaveMessage)), findsOneWidget);
      await t.tap(inDialog(find.text('Cancel')));
      await qaSettle(t);
      expect(find.byType(AlertDialog), findsNothing);
      expect(w.api.writes, isEmpty);

      await t.tap(find.text('Leave club'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Leave club')));
      await qaSettle(t);
      final leaves = w.api.sent('POST', '/clubs/club-1/membership');
      expect(leaves, hasLength(1));
      expect(leaves.single.body, {'action': 'leave'});
      expect(find.text('Join club'), findsOneWidget);
      expect(find.text('7 members'), findsOneWidget);
      await scrollTo(t, find.text('Join to see the discussion'));
      expect(find.byType(ClubDiscussion), findsNothing);
    });

    testWidgets('Leave club failure keeps the member in with a message '
        '[case:clubs.club_detail.leave_club.api_failure]', (t) async {
      final w = await _open(t);
      w.api.fail('POST /clubs/*/membership');
      await t.tap(find.text('Leave club'));
      await qaSettle(t);
      await t.tap(inDialog(find.text('Leave club')));
      await qaSettle(t);

      expect(qaSnackText(t), 'Something broke on our side.');
      expect(w.api.sent('POST', '/clubs/club-1/membership'), hasLength(1));
      expect(find.text('Leave club'), findsOneWidget);
      expect(isEnabled(t, find.text('Leave club')), isTrue);
      expect(find.text('Join club'), findsNothing);
    });
  });

  group('members sheet', () {
    testWidgets(
      'Owner promotes, demotes and (after confirming) removes members '
      '[case:clubs.club_members_sheet.actions_for_name.action]',
      (t) async {
        final w = await _open(t, role: 'owner');
        await _openMembers(t);
        expect(find.byTooltip('Actions for Alex'), findsNothing);

        w.slow('POST /clubs/*/members/*');
        await chooseFromMenu(t, 'Actions for Sam', 'Make moderator');
        await t.pump(const Duration(milliseconds: 50));
        await t.pump(const Duration(milliseconds: 50));
        await qaSettle(t, frames: 15);
        var posts = w.api.sent('POST', '/clubs/*/members/*');
        expect(posts.single.path, '/clubs/club-1/members/u-sam');
        expect(posts.single.body, {'action': 'make_moderator'});
        expect(_roleOf('Sam', 'Moderator'), findsOneWidget);
        expect(w.api.sent('GET', '/clubs/club-1/members'), hasLength(2));

        await chooseFromMenu(t, 'Actions for Rin', 'Make member');
        posts = w.api.sent('POST', '/clubs/*/members/*');
        expect(posts.last.path, '/clubs/club-1/members/u-rin');
        expect(posts.last.body, {'action': 'make_member'});
        expect(_roleOf('Rin', 'Member'), findsOneWidget);

        await chooseFromMenu(t, 'Actions for Sam', 'Remove from club');
        expect(inDialog(find.text('Remove Sam?')), findsOneWidget);
        await t.tap(inDialog(find.text('Cancel')));
        await qaSettle(t);
        expect(w.api.sent('POST', '/clubs/*/members/*'), hasLength(2));
        expect(find.text('Sam'), findsOneWidget);

        await chooseFromMenu(t, 'Actions for Sam', 'Remove from club');
        await t.tap(inDialog(find.text('Remove')));
        await qaSettle(t);
        posts = w.api.sent('POST', '/clubs/*/members/*');
        expect(posts, hasLength(3));
        expect(posts.last.body, {'action': 'remove'});
        expect(find.text('Sam'), findsNothing);
        expect(inSheet(find.text('Members')), findsOneWidget);
      },
    );

    testWidgets('The members sheet shows a progress bar and locks the menus '
        'while a change saves', (t) async {
      final w = await _open(t, role: 'owner');
      await _openMembers(t);
      w.slow('POST /clubs/*/members/*', delay: const Duration(seconds: 3));
      await chooseFromMenu(t, 'Actions for Sam', 'Make moderator');
      expect(inSheet(find.byType(LinearProgressIndicator)), findsOneWidget);
      final rin = t.widget<PopupMenuButton<String>>(
        find.ancestor(
          of: find.byTooltip('Actions for Rin'),
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      expect(rin.enabled, isFalse);
      await qaSettle(t, frames: 25);
      expect(inSheet(find.byType(LinearProgressIndicator)), findsNothing);
    });

    testWidgets('A moderator may only remove plain members', (t) async {
      await _open(t, role: 'moderator');
      await _openMembers(t);
      expect(find.byTooltip('Actions for Rin'), findsNothing);
      expect(find.byTooltip('Actions for Olive'), findsNothing);
      await t.tap(find.byTooltip('Actions for Sam'));
      await qaSettle(t);
      expect(find.text('Remove from club'), findsOneWidget);
      expect(find.text('Make moderator'), findsNothing);
    });

    testWidgets('A member change that fails says why and leaves the role '
        '[case:clubs.club_members_sheet.actions_for_name.api_failure]', (
      t,
    ) async {
      final w = await _open(t, role: 'owner');
      await _openMembers(t);
      w.api.fail(
        'POST /clubs/*/members/*',
        status: 409,
        message: 'Sam already left.',
      );
      await chooseFromMenu(t, 'Actions for Sam', 'Make moderator');

      expect(qaSnackText(t), 'Sam already left.');
      expect(w.api.sent('POST', '/clubs/*/members/*'), hasLength(1));
      expect(_roleOf('Sam', 'Member'), findsOneWidget);
      expect(inSheet(find.byType(LinearProgressIndicator)), findsNothing);

      w.heal('POST /clubs/*/members/*');
      await chooseFromMenu(t, 'Actions for Sam', 'Make moderator');
      expect(w.api.sent('POST', '/clubs/*/members/*'), hasLength(2));
      expect(_roleOf('Sam', 'Moderator'), findsOneWidget);
    });
  });

  group('weekly pick', () {
    testWidgets('Set this week’s pick: search, choose, add a note, save '
        '[case:clubs.club_detail.set_this_week_s_pick_onsetpick.action] '
        '[case:clubs.club_pick_sheet.search_icon_search.action] '
        '[case:clubs.club_pick_sheet.a_note_for_the_club_optional_input.action] '
        '[case:clubs.club_pick_sheet.save_pick.action]', (t) async {
      final w = await _open(t, role: 'owner', setup: (w) => w.current = null);
      expect(find.text(en.clubsNoPickModerator), findsOneWidget);
      await _openPickSheet(t);
      ChoiceChip chip(String label) =>
          t.widget<ChoiceChip>(inSheet(find.widgetWithText(ChoiceChip, label)));
      expect(chip('This week').selected, isTrue);
      expect(chip('Next week').selected, isFalse);

      // The search button opens the title picker for books.
      expect(inSheet(find.byIcon(Icons.search)), findsOneWidget);
      await _chooseTitle(t, 'pir', 'Piranesi');
      expect(w.api.sent('GET', '/clubs/titles').single.query, {
        'kind': 'book',
        'q': 'pir',
      });
      expect(inSheet(find.text('Piranesi')), findsOneWidget);
      expect(inSheet(find.text('Susanna Clarke · 2020')), findsOneWidget);
      expect(inSheet(find.text('Change')), findsOneWidget);

      await t.enterText(
        inSheet(find.widgetWithText(TextField, en.clubsPickNoteLabel)),
        '  Start with the first notebook.  ',
      );
      final before = _detailLoads(w);
      w.slow('PUT /clubs/*/selections/*');
      await t.tap(inSheet(find.text('Save pick')));
      await t.pump(const Duration(milliseconds: 100));
      expect(inSheet(find.text('Saving…')), findsOneWidget);
      expect(isEnabled(t, inSheet(find.text('Saving…'))), isFalse);
      await qaSettle(t, frames: 15);

      final put = w.api.sent('PUT', '/clubs/*/selections/*').single;
      expect(put.path, '/clubs/club-1/selections/$thisMonday');
      expect(put.body, {
        'title_id': 'title-1',
        'note': 'Start with the first notebook.',
      });
      expect(find.byType(BottomSheet), findsNothing);
      expect(_detailLoads(w), before + 1);
      expect(find.text('“Start with the first notebook.”'), findsOneWidget);
      expect(await _discussionFor(t), 'sel-$thisMonday');
      await scrollTo(t, find.text('Discussion · Piranesi'));
    });

    testWidgets('Next week saves the pick for next Monday '
        '[case:clubs.club_pick_sheet.next_week.action]', (t) async {
      final w = await _open(t, role: 'owner');
      await _openPickSheet(t);
      await t.tap(inSheet(find.text('Next week')));
      await qaSettle(t);
      expect(
        t
            .widget<ChoiceChip>(
              inSheet(find.widgetWithText(ChoiceChip, 'Next week')),
            )
            .selected,
        isTrue,
      );
      expect(
        t
            .widget<ChoiceChip>(
              inSheet(find.widgetWithText(ChoiceChip, 'This week')),
            )
            .selected,
        isFalse,
      );
      await _chooseTitle(t, 'kla', 'Klara and the Sun');
      await t.tap(inSheet(find.text('Save pick')));
      await qaSettle(t);

      final put = w.api.sent('PUT', '/clubs/*/selections/*').single;
      expect(put.path, '/clubs/club-1/selections/$nextMonday');
      expect(put.body, {'title_id': 'title-2', 'note': ''});
      expect(w.upcoming.single['week_start'], nextMonday);
      // This week's pick is unchanged on the card.
      expect(find.text('Piranesi'), findsOneWidget);
    });

    testWidgets('Change swaps the chosen title before saving '
        '[case:clubs.club_pick_sheet.change.action]', (t) async {
      final w = await _open(t, role: 'owner');
      await _openPickSheet(t);
      await _chooseTitle(t, 'pir', 'Piranesi');
      await _chooseTitle(t, 'kla', 'Klara and the Sun', button: 'Change');
      expect(inSheet(find.text('Klara and the Sun')), findsOneWidget);
      expect(inSheet(find.text('Piranesi')), findsNothing);
      expect(inSheet(find.text('Kazuo Ishiguro · 2021')), findsOneWidget);

      await t.tap(inSheet(find.text('Save pick')));
      await qaSettle(t);
      expect(
        w.api.sent('PUT', '/clubs/*/selections/*').single.body['title_id'],
        'title-2',
      );
      expect(find.text('Klara and the Sun'), findsWidgets);
    });

    testWidgets(
      'Save pick without a title asks for one; the note is cut at '
      '280, whitespace is dropped, emoji and RTL are kept '
      '[case:clubs.club_pick_sheet.a_note_for_the_club_optional_input.validation]',
      (t) async {
        final w = await _open(t, role: 'owner');
        await _openPickSheet(t);
        final note = inSheet(
          find.widgetWithText(TextField, en.clubsPickNoteLabel),
        );

        await t.enterText(note, 'Read slowly.');
        await t.tap(inSheet(find.text('Save pick')));
        await qaSettle(t);
        expect(inSheet(find.text('Choose a title first.')), findsOneWidget);
        expect(w.api.writes, isEmpty);

        await t.enterText(note, 'n' * 281);
        expect(fieldText(t, en.clubsPickNoteLabel), 'n' * 280);

        await _chooseTitle(t, 'pir', 'Piranesi');
        await t.enterText(note, '   \n ');
        await t.tap(inSheet(find.text('Save pick')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/*/selections/*').last.body['note'],
          '',
        );

        await _openPickSheet(t);
        await _chooseTitle(t, 'pir', 'Piranesi');
        const unicode = 'ابدأ بالدفتر الأول 📓 — לאט לאט';
        await t.enterText(note, unicode);
        await t.tap(inSheet(find.text('Save pick')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/*/selections/*').last.body['note'],
          unicode,
        );
        expect(find.text('“$unicode”'), findsOneWidget);
      },
    );

    testWidgets('Save pick failure keeps the sheet, title and note; retry '
        'saves [case:clubs.club_pick_sheet.save_pick.api_failure]', (t) async {
      final w = await _open(t, role: 'owner');
      await _openPickSheet(t);
      await _chooseTitle(t, 'kla', 'Klara and the Sun');
      await t.enterText(
        inSheet(find.widgetWithText(TextField, en.clubsPickNoteLabel)),
        'Bring tissues.',
      );
      w.api.fail(
        'PUT /clubs/*/selections/*',
        status: 403,
        message: 'Only moderators can set the pick.',
      );
      await t.tap(inSheet(find.text('Save pick')));
      await qaSettle(t);

      expect(
        inSheet(find.text('Only moderators can set the pick.')),
        findsOneWidget,
      );
      expect(inSheet(find.text('Klara and the Sun')), findsOneWidget);
      expect(fieldText(t, en.clubsPickNoteLabel), 'Bring tissues.');
      expect(isEnabled(t, inSheet(find.text('Save pick'))), isTrue);
      expect(w.api.sent('PUT', '/clubs/*/selections/*'), hasLength(1));

      w.api.on('PUT /clubs/*/selections/*', (_) => const QaReply(500, null));
      await t.tap(inSheet(find.text('Save pick')));
      await qaSettle(t);
      expect(inSheet(find.text(en.clubsPickNotSaved)), findsOneWidget);

      w.heal('PUT /clubs/*/selections/*');
      await t.tap(inSheet(find.text('Save pick')));
      await qaSettle(t);
      expect(w.api.sent('PUT', '/clubs/*/selections/*'), hasLength(3));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('“Bring tissues.”'), findsOneWidget);
    });
  });

  group('l10n', () {
    testWidgets('Club page renders in every locale '
        '[case:clubs.club_detail.l10n]', (t) async {
      await sweepLocales(
        t,
        world: () => ClubsWorld(role: 'owner'),
        screen: () => const ClubDetailScreen(clubId: 'club-1'),
        labels: (l10n) => [
          l10n.clubsLeaveClub,
          l10n.clubsMembers,
          l10n.clubsWeekThis,
          l10n.clubsSetThisWeeksPick,
          l10n.clubsDiscussThisPick,
          l10n.clubsYouRole(clubRoleLabel(l10n, 'owner')),
          l10n.clubsPostsInDiscussion(2),
        ],
      );
    });

    testWidgets('Members sheet renders in every locale '
        '[case:clubs.club_members_sheet.l10n]', (t) async {
      await sweepLocales(
        t,
        world: () => ClubsWorld(role: 'owner'),
        screen: () => const ClubDetailScreen(clubId: 'club-1'),
        open: (t, l10n) async {
          await t.tap(find.text(l10n.clubsMembers));
          await qaSettle(t);
          expect(
            find.byTooltip(l10n.clubsMemberActions('Sam')),
            findsOneWidget,
          );
        },
        labels: (l10n) => [
          l10n.clubsMemberYou('Alex'),
          l10n.clubsRoleOwner,
          l10n.clubsRoleMember,
          l10n.clubsRoleModerator,
        ],
      );
    });

    testWidgets('Pick sheet renders in every locale '
        '[case:clubs.club_pick_sheet.l10n]', (t) async {
      await sweepLocales(
        t,
        world: () => ClubsWorld(role: 'owner'),
        screen: () => const ClubDetailScreen(clubId: 'club-1'),
        open: (t, l10n) async {
          await t.tap(find.text(l10n.clubsSetThisWeeksPick));
          await qaSettle(t);
          await t.tap(find.text(l10n.clubsSavePick));
          await qaSettle(t);
        },
        labels: (l10n) => [
          l10n.clubsSetWeeklyPick,
          l10n.clubsWeekNext,
          l10n.clubsChooseBook,
          l10n.clubsPickNoteLabel,
          l10n.clubsChooseTitleFirst,
        ],
      );
    });
  });
}
