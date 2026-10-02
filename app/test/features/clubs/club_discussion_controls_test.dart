import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/club_discussion.dart';

import '../../support/qa_api.dart';
import 'clubs_qa_fixtures.dart';

// The weekly pick's discussion on the club page: the composer, the spoiler
// switch, paging, and the per-post actions (delete, hide/show, report).

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

Finder get _composer => find.widgetWithText(TextField, 'Add to the discussion');

String _typed(WidgetTester t) =>
    t.widget<TextField>(_composer).controller!.text;

Future<void> _toComposer(WidgetTester t) async {
  await scrollTo(t, find.text('Post'));
  await scrollTo(t, _composer);
}

Future<void> _post(WidgetTester t, String text) async {
  await _toComposer(t);
  await t.enterText(_composer, text);
  await t.tap(find.text('Post'));
  await qaSettle(t);
}

SwitchListTile _spoilerSwitch(WidgetTester t) => t.widget<SwitchListTile>(
  find.widgetWithText(SwitchListTile, 'Contains spoilers'),
);

/// The "Post actions" menu on the post that reads [body].
Finder _menuOf(String body) => find.descendant(
  of: find.ancestor(of: find.text(body), matching: find.byType(ClubPostTile)),
  matching: find.byTooltip('Post actions'),
);

Future<void> _act(WidgetTester t, String body, String action) async {
  await scrollTo(t, find.text(body));
  await t.tap(_menuOf(body));
  await qaSettle(t);
  await t.tap(find.text(action).last);
  await qaSettle(t);
}

List<String> _menuItems(WidgetTester t) => [
  for (final item in t.widgetList<PopupMenuItem<String>>(
    find.byType(PopupMenuItem<String>),
  ))
    item.value!,
];

int _postLoads(ClubsWorld w) => w.api.sent('GET', '/clubs/club-1/posts').length;

void main() {
  group('composer', () {
    testWidgets(
      'Post sends the trimmed text to this pick, shows it and clears the box '
      '[case:clubs.club_discussion.post_onsend.action] '
      '[case:clubs.club_discussion.add_to_the_discussion_input.action]',
      (t) async {
        final w = await _open(t);
        await _toComposer(t);
        final loads = _postLoads(w);
        await t.enterText(_composer, '  The house has tides.  ');

        w.slow('PUT /clubs/*/posts/*');
        await t.tap(find.text('Post'));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('Posting…'), findsOneWidget);
        expect(isEnabled(t, find.text('Posting…')), isFalse);
        expect(_spoilerSwitch(t).onChanged, isNull);
        await t.tap(find.text('Posting…'), warnIfMissed: false);
        await qaSettle(t, frames: 15);

        final puts = w.api.sent('PUT', '/clubs/*/posts/*');
        expect(puts, hasLength(1));
        expect(puts.single.path, startsWith('/clubs/club-1/posts/'));
        expect(puts.single.path, matches(uuidSegment));
        expect(puts.single.body, {
          'selection_id': 'sel-1',
          'body': 'The house has tides.',
          'has_spoilers': false,
        });
        expect(_postLoads(w), greaterThan(loads));
        await scrollTo(t, find.text('The house has tides.'));
        final mine = find.ancestor(
          of: find.text('The house has tides.'),
          matching: find.byType(ClubPostTile),
        );
        expect(
          find.descendant(of: mine, matching: find.text('You')),
          findsOneWidget,
        );
        await _toComposer(t);
        expect(_typed(t), isEmpty);
        expect(isEnabled(t, find.text('Post')), isTrue);

        // A second post gets its own id.
        await _post(t, 'Second thought.');
        final again = w.api.sent('PUT', '/clubs/*/posts/*');
        expect(again, hasLength(2));
        expect(again.last.path, isNot(again.first.path));
        expect(again.last.body['body'], 'Second thought.');
      },
    );

    testWidgets(
      'regression: posting keeps the member at the discussion instead of '
      'reloading the whole club page back to the top',
      (t) async {
        final w = await _open(t);
        await _toComposer(t);
        final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
        final offset = scroll.position.pixels;
        expect(offset, greaterThan(0));

        await t.enterText(_composer, 'Still here?');
        await t.tap(find.text('Post'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        // While it reloads the page stays (no full-screen spinner).
        expect(find.byType(ClubDiscussion), findsOneWidget);
        await qaSettle(t);

        expect(w.api.sent('PUT', '/clubs/*/posts/*'), hasLength(1));
        expect(
          t.state<ScrollableState>(find.byType(Scrollable).first),
          same(scroll),
          reason: 'the club page was not rebuilt from scratch',
        );
        expect(scroll.position.pixels, greaterThan(0));
        expect(find.text('Still here?'), findsOneWidget);
        expect(_typed(t), isEmpty);
        await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await qaSettle(t);
        expect(find.text('3 posts in the discussion'), findsOneWidget);
      },
    );

    testWidgets('Contains spoilers marks the post and resets after sending '
        '[case:clubs.club_discussion.contains_spoilers_onspoilers.action]', (
      t,
    ) async {
      final w = await _open(t);
      await _toComposer(t);
      expect(_spoilerSwitch(t).value, isFalse);
      await t.tap(find.text('Contains spoilers'));
      await qaSettle(t);
      expect(_spoilerSwitch(t).value, isTrue);

      await t.enterText(_composer, 'The ending reveals who the Other is.');
      await t.tap(find.text('Post'));
      await qaSettle(t);
      expect(w.api.sent('PUT', '/clubs/*/posts/*').single.body, {
        'selection_id': 'sel-1',
        'body': 'The ending reveals who the Other is.',
        'has_spoilers': true,
      });
      await _toComposer(t);
      expect(_spoilerSwitch(t).value, isFalse);
      // My own spoiler post is shown to me in full.
      await scrollTo(t, find.text('The ending reveals who the Other is.'));
    });

    testWidgets(
      'Post failure keeps the text and spoiler flag; the retry reuses the '
      'same post id [case:clubs.club_discussion.post_onsend.api_failure]',
      (t) async {
        final w = await _open(t);
        await _toComposer(t);
        await t.tap(find.text('Contains spoilers'));
        await qaSettle(t);
        await t.enterText(_composer, 'Matthew Rose Sorensen!');
        w.api.fail('PUT /clubs/*/posts/*', message: 'Posting is paused.');
        await t.tap(find.text('Post'));
        await qaSettle(t);

        expect(qaSnackText(t), 'Posting is paused.');
        expect(_typed(t), 'Matthew Rose Sorensen!');
        expect(_spoilerSwitch(t).value, isTrue);
        expect(isEnabled(t, find.text('Post')), isTrue);
        expect(w.api.sent('PUT', '/clubs/*/posts/*'), hasLength(1));
        expect(
          find.descendant(
            of: find.byType(ClubPostTile),
            matching: find.text('Matthew Rose Sorensen!'),
          ),
          findsNothing,
          reason: 'only in the text box, not as a post',
        );

        w.api.offline('PUT /clubs/*/posts/*');
        await t.tap(find.text('Post'));
        await qaSettle(t, frames: 50);
        expect(qaSnackText(t), en.networkCannotReachService);
        expect(_typed(t), 'Matthew Rose Sorensen!');

        w.heal('PUT /clubs/*/posts/*');
        await qaSettle(t, frames: 50); // the snack no longer covers Post
        await t.tap(find.text('Post'));
        await qaSettle(t);
        final puts = w.api.sent('PUT', '/clubs/*/posts/*');
        expect(puts, hasLength(3));
        expect(
          puts.map((c) => c.path).toSet(),
          hasLength(1),
          reason: 'retries reuse the post id: no duplicate post',
        );
        expect(puts.last.body['has_spoilers'], isTrue);
        expect(_typed(t), isEmpty);
        expect(w.posts['sel-1']!.where((p) => p['mine'] == true), hasLength(2));
      },
    );

    testWidgets(
      'Empty and blank posts are not sent; over 2000 is cut; emoji and RTL '
      'arrive unchanged '
      '[case:clubs.club_discussion.add_to_the_discussion_input.validation]',
      (t) async {
        final w = await _open(t);
        await _toComposer(t);
        await t.tap(find.text('Post'));
        await qaSettle(t);
        await t.enterText(_composer, '   \n\n  ');
        await t.tap(find.text('Post'));
        await qaSettle(t);
        expect(w.api.writes, isEmpty);
        expect(_typed(t), '   \n\n  ');

        await t.enterText(_composer, 'z' * 2001);
        expect(_typed(t), 'z' * 2000);

        const text = 'مرحبا 👋🏽 שלום — 読書会 🇵🇹';
        await t.enterText(_composer, text);
        await t.tap(find.text('Post'));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/*/posts/*').single.body['body'], text);
        await scrollTo(t, find.text(text));
      },
    );
  });

  testWidgets('Load more posts fetches the older page and shows it first '
      '[case:clubs.club_discussion.load_more_posts.action]', (t) async {
    final w = await _open(
      t,
      setup: (w) {
        w.nextCursor = 'p-sam';
        w.older.add(w.post('p-old', 'An older thought.', minute: 0));
      },
    );
    await scrollTo(t, find.text('Load more posts'));
    expect(find.text('An older thought.'), findsNothing);
    await t.tap(find.text('Load more posts'));
    await qaSettle(t);

    expect(w.api.sent('GET', '/clubs/club-1/posts').last.query, {
      'selection_id': 'sel-1',
      'before': 'p-sam',
    });
    await scrollTo(t, find.text('An older thought.'));
    expect(
      t.getTopLeft(find.text('An older thought.')).dy,
      lessThan(t.getTopLeft(find.text('The statues in the halls!')).dy),
      reason: 'oldest first',
    );
    expect(find.text('Load more posts'), findsNothing);
  });

  testWidgets(
    'The discussion could not load: Try again reloads it '
    '[case:clubs.club_discussion.the_discussion_could_not_load_onaction.action]',
    (t) async {
      final w = await _open(
        t,
        setup: (w) =>
            w.api.fail('GET /clubs/*/posts', message: 'Discussion is resting.'),
      );
      await scrollTo(t, find.text('Discussion is resting.'));
      expect(find.text('The discussion could not load'), findsOneWidget);
      expect(find.text('The statues in the halls!'), findsNothing);

      w.heal('GET /clubs/*/posts');
      final loads = _postLoads(w);
      await scrollTo(t, find.text('Try again'));
      await t.tap(find.text('Try again'));
      await qaSettle(t);
      expect(_postLoads(w), loads + 1);
      await scrollTo(t, find.text('The statues in the halls!'));
      expect(find.text('The discussion could not load'), findsNothing);
    },
  );

  group('post actions', () {
    testWidgets(
      'Delete (my post, after confirming), Hide/Show (moderator) and Report '
      '(others\' posts) [case:clubs.club_discussion.post_actions.action]',
      (t) async {
        final w = await _open(t, role: 'owner');

        // My post: Delete only (no report of my own post).
        await scrollTo(t, find.text('I loved the tides.'));
        await t.tap(_menuOf('I loved the tides.'));
        await qaSettle(t);
        // Delete, and (as a moderator) hide; never report my own post.
        expect(_menuItems(t), ['delete', 'hide']);
        await t.tap(find.text('Delete'));
        await qaSettle(t);
        expect(inDialog(find.text('Delete your post?')), findsOneWidget);
        await t.tap(inDialog(find.text('Cancel')));
        await qaSettle(t);
        expect(w.api.writes, isEmpty);
        expect(find.text('I loved the tides.'), findsOneWidget);

        await _act(t, 'I loved the tides.', 'Delete');
        await t.tap(inDialog(find.text('Delete')));
        await qaSettle(t);
        expect(w.api.writeLines, ['DELETE /clubs/club-1/posts/p-me']);
        expect(find.text('I loved the tides.'), findsNothing);

        // Someone else's post: a moderator can hide it, then show it again.
        await scrollTo(t, find.text('The statues in the halls!'));
        await t.tap(_menuOf('The statues in the halls!'));
        await qaSettle(t);
        expect(_menuItems(t), ['hide', 'report']);
        await t.tap(find.text('Hide from members'));
        await qaSettle(t);
        var visibility = w.api.sent('POST', '/clubs/*/posts/*/visibility');
        expect(visibility.single.path, '/clubs/club-1/posts/p-sam/visibility');
        expect(visibility.single.body, {'hidden': true});
        await scrollTo(t, find.text('Hidden'));

        await _act(t, 'The statues in the halls!', 'Show to members');
        visibility = w.api.sent('POST', '/clubs/*/posts/*/visibility');
        expect(visibility.last.body, {'hidden': false});
        await scrollTo(t, find.text('The statues in the halls!'));
        expect(find.text('Hidden'), findsNothing);

        await _act(t, 'The statues in the halls!', 'Report');
        await submitReport(t, reason: 'Harassment');
        final report = w.api.sent('POST', '/blog/reports/club_post/p-sam');
        expect(report.single.body, {'reason': 'harassment', 'description': ''});
        expect(qaSnackText(t), 'Report submitted. Thank you.');
      },
    );

    testWidgets('A plain member can only report someone else\'s post', (
      t,
    ) async {
      await _open(t);
      await scrollTo(t, find.text('The statues in the halls!'));
      await t.tap(_menuOf('The statues in the halls!'));
      await qaSettle(t);
      expect(_menuItems(t), ['report']);
    });

    testWidgets('Delete, hide and report failures say why and change nothing '
        '[case:clubs.club_discussion.post_actions.api_failure]', (t) async {
      final w = await _open(t, role: 'owner');
      w.api.fail('DELETE /clubs/*/posts/*', message: 'Deleting is paused.');
      await _act(t, 'I loved the tides.', 'Delete');
      await t.tap(inDialog(find.text('Delete')));
      await qaSettle(t);
      expect(qaSnackText(t), 'Deleting is paused.');
      expect(w.api.sent('DELETE', '/clubs/*/posts/*'), hasLength(1));
      expect(find.text('I loved the tides.'), findsOneWidget);

      w.api.on(
        'POST /clubs/*/posts/*/visibility',
        (_) => const QaReply(500, null),
      );
      await qaSettle(t, frames: 50); // let the first snack go
      await _act(t, 'The statues in the halls!', 'Hide from members');
      expect(qaSnackText(t), en.clubsActionFailed);
      expect(w.api.sent('POST', '/clubs/*/posts/*/visibility'), hasLength(1));
      expect(find.text('Hidden'), findsNothing);

      w.api.fail('POST /blog/reports/*/*');
      await qaSettle(t, frames: 50);
      await _act(t, 'The statues in the halls!', 'Report');
      await submitReport(t, description: 'Spoils the ending');
      expect(qaSnackText(t), 'Failed to submit report. Please try again.');
      expect(find.text('Submit report'), findsOneWidget);
      expect(fieldText(t, 'Description (optional)'), 'Spoils the ending');

      // Retry: the delete now goes through.
      await t.tapAt(const Offset(20, 40)); // dismiss the report sheet
      await qaSettle(t);
      w.heal('DELETE /clubs/*/posts/*');
      await _act(t, 'I loved the tides.', 'Delete');
      await t.tap(inDialog(find.text('Delete')));
      await qaSettle(t);
      expect(w.api.sent('DELETE', '/clubs/*/posts/*'), hasLength(2));
      expect(find.text('I loved the tides.'), findsNothing);
    });
  });

  testWidgets('The discussion renders in every locale '
      '[case:clubs.club_discussion.l10n]', (t) async {
    await sweepLocales(
      t,
      world: () => ClubsWorld(role: 'owner')
        ..nextCursor = 'p-sam'
        ..posts['sel-1']!.add(
          ClubsWorld(role: 'owner').post('p-h', 'Hidden one', hidden: true),
        ),
      screen: () => const ClubDetailScreen(clubId: 'club-1'),
      open: (t, l10n) async {
        await scrollTo(t, find.text(l10n.clubsPost));
      },
      labels: (l10n) => [
        l10n.clubsDiscussionHeading('Piranesi'),
        l10n.clubsYou,
        l10n.clubsHidden,
        l10n.clubsLoadMorePosts,
        l10n.clubsComposerLabel,
        l10n.clubsContainsSpoilers,
        l10n.clubsSpoilersSubtitle,
        l10n.clubsPost,
      ],
    );
  });
}
