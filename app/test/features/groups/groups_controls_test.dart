import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';

import '../../support/qa_api.dart';
import 'groups_world.dart';

// Groups home controls: each test performs the real gesture and asserts the
// request the server receives, where the member lands and what they see —
// and, for every command, what happens when the server refuses or the
// device is offline.

/// Your groups: "Sunday hikers" (a private group I'm in). Invitation:
/// "Trek planners" from Asha. Discover: "Koramangala readers" (Books).
GroupsWorld _world() => GroupsWorld()
  ..groups.addAll({
    'mine': qaGroup(
      id: 'mine',
      kind: 'private',
      name: 'Sunday hikers',
      role: 'member',
      channel: 'ch-mine',
    ),
    'p1': qaGroup(
      id: 'p1',
      kind: 'private',
      name: 'Trek planners',
      inviteId: 'inv-1',
      memberCount: 4,
    ),
    'g1': qaGroup(canJoin: true),
  });

Future<List<Object?>> _open(
  WidgetTester tester,
  GroupsWorld world, {
  bool launcher = false,
  Locale? locale,
  GroupsScreen screen = const GroupsScreen(),
}) => pumpQa(
  tester,
  world.api,
  screen,
  size: const Size(500, 3200),
  launcher: launcher,
  locale: locale,
);

final _en = qaL10n(const Locale('en'));

Finder _inviteCard() => find.ancestor(
  of: find.text('Trek planners'),
  matching: find.byType(InkWell),
);

Finder _button<T extends Widget>(String text) => find.widgetWithText(T, text);

Future<void> _pullToRefresh(WidgetTester tester) async {
  // The pull must pass a quarter of the (tall) viewport to arm.
  await tester.fling(
    find.text('Find your people.'),
    const Offset(0, 1400),
    1500,
  );
  await tester.pumpAndSettle();
  await tester.pump();
}

void main() {
  testWidgets('Back closes Groups and returns to the opener', (tester) async {
    final world = _world();
    final results = await _open(tester, world, launcher: true);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupsScreen), findsNothing);
    expect(results, [null]);
  });

  group('pull to refresh', () {
    testWidgets(
      'reloads my groups, invitations, lifestyles, discover and chats and '
      'shows what changed [case:groups.groups.join_onrefresh.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        int count(String path) => world.api.sent('GET', path).length;
        final paths = [
          '/engagement/groups',
          '/engagement/group-invites',
          '/engagement/group-categories',
          '/social/channels',
        ];
        final before = {for (final p in paths) p: count(p)};
        expect(find.text('Board games'), findsNothing);

        world.groups['bg'] = qaGroup(
          id: 'bg',
          kind: 'private',
          name: 'Board games',
          role: 'member',
          channel: 'ch-bg',
        );
        await _pullToRefresh(tester);

        for (final path in paths) {
          expect(count(path), greaterThan(before[path]!), reason: path);
        }
        final mine = world.api
            .sent('GET', '/engagement/groups')
            .where((c) => c.query['scope'] == 'mine');
        expect(mine.last.query, {'scope': 'mine'});
        expect(find.text('Board games'), findsOneWidget);
        expect(find.text('Sunday hikers'), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets(
      'a refresh while offline shows the retry notice without crashing, and '
      'Try again loads your groups '
      '[case:groups.groups.load_failed_retry.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        world.api.offline('GET /engagement/groups');
        await _pullToRefresh(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(_en.groupsYourGroupsFailed), findsOneWidget);
        expect(find.text(_en.groupsDiscoverFailed), findsOneWidget);
        expect(find.text(_en.networkOfflineTryAgain), findsNWidgets(2));

        // Back online: Try again on "Your groups" reloads that list.
        world.api.on(
          'GET /engagement/groups',
          (c) => qaOk({
            'groups': [if (c.query['scope'] == 'mine') world.groups['mine']],
          }),
        );
        final before = world.api.sent('GET', '/engagement/groups').length;
        await qaTap(
          tester,
          find.descendant(
            of: find
                .ancestor(
                  of: find.text(_en.groupsYourGroupsFailed),
                  matching: find.byType(Column),
                )
                .first,
            matching: _button<OutlinedButton>(_en.chatTryAgain),
          ),
        );
        expect(
          world.api.sent('GET', '/engagement/groups').length,
          greaterThan(before),
        );
        expect(find.text('Sunday hikers'), findsOneWidget);
        expect(find.text(_en.groupsYourGroupsFailed), findsNothing);
      },
    );

    testWidgets(
      'lifestyles that fail to load offer Try again, which brings the chips '
      'back [case:groups.groups.load_failed_retry.action]',
      (tester) async {
        final world = _world();
        world.api.fail(
          'GET /engagement/group-categories',
          message: 'Lifestyles are resting.',
        );
        await _open(tester, world);
        expect(find.text(_en.groupsLifestylesFailed), findsOneWidget);
        expect(find.text('Lifestyles are resting.'), findsOneWidget);
        expect(qaKey('groups.category.books'), findsNothing);

        world.api.on(
          'GET /engagement/group-categories',
          (_) => qaOk({'categories': world.categories}),
        );
        await qaTap(tester, _button<OutlinedButton>(_en.chatTryAgain));
        expect(qaKey('groups.category.books'), findsOneWidget);
        expect(find.text(_en.groupsLifestylesFailed), findsNothing);
      },
    );
  });

  testWidgets('Start a group opens the create flow as a community group '
      '[case:groups.groups.groups_start.action]', (tester) async {
    final world = _world();
    await _open(tester, world);
    await qaTap(tester, qaKey('groups.start'));
    final create = tester.widget<CreateGroupScreen>(
      find.byType(CreateGroupScreen),
    );
    expect(create.initialKind, isNull);
    expect(create.initialCategory, '');
    expect(create.invitees, isEmpty);
    // No friends preselected: it starts as a community group.
    expect(find.text(_en.groupsCreateLifestyleHeader), findsOneWidget);
    expect(find.text(_en.groupsCreateSubtitle), findsOneWidget);
    expect(world.api.writes, isEmpty);
  });

  group('invitations', () {
    testWidgets('tapping an invitation opens that group '
        '[case:groups.groups.invitation_declined_onopen.action]', (
      tester,
    ) async {
      final world = _world();
      await _open(tester, world);
      expect(find.text(_en.groupsInvitationsHeader), findsOneWidget);
      expect(
        find.text('Asha invited you · Private group · 4 members'),
        findsOneWidget,
      );
      await qaTap(tester, _inviteCard().first);
      final detail = tester.widget<GroupDetailScreen>(
        find.byType(GroupDetailScreen),
      );
      expect(detail.groupId, 'p1');
      expect(world.api.sent('GET', '/engagement/groups/p1'), hasLength(1));
      // Not a member yet: the detail offers the invitation answer.
      expect(
        find.text('You’re invited to join Trek planners.'),
        findsOneWidget,
      );
      expect(world.api.writes, isEmpty);
    });

    testWidgets('Decline answers the invitation, says so and removes the card '
        '[case:groups.groups.decline_onrespond.action]', (tester) async {
      final world = _world();
      await _open(tester, world);
      await qaTap(tester, find.bySemanticsLabel('Decline Trek planners'));

      expect(world.api.writeLines, [
        'POST /engagement/groups/p1/invites/respond',
      ]);
      expect(world.api.writes.single.body, {'decision': 'decline'});
      expect(find.text(_en.groupsInvitationDeclined), findsOneWidget);
      expect(find.text(_en.groupsInvitationsHeader), findsNothing);
      expect(find.text('Trek planners'), findsNothing);
    });

    testWidgets(
      'Join on an invitation accepts it, welcomes me and lists the group '
      'under Your groups [case:groups.groups.invite_join_onrespond.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        await qaTap(tester, find.bySemanticsLabel('Join Trek planners'));

        expect(world.api.writeLines, [
          'POST /engagement/groups/p1/invites/respond',
        ]);
        expect(world.api.writes.single.body, {'decision': 'accept'});
        expect(find.text('Welcome to Trek planners!'), findsOneWidget);
        expect(find.text(_en.groupsInvitationsHeader), findsNothing);
        // Now one of my groups (no Join button on it).
        expect(find.text('Trek planners'), findsOneWidget);
        expect(find.bySemanticsLabel('Join Trek planners'), findsNothing);
      },
    );

    testWidgets(
      'a refused Decline keeps the invitation, shows the server message and '
      'the retry goes through once '
      '[case:groups.groups.decline_onrespond.api_failure]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        world.api.fail(
          'POST /engagement/groups/*/invites/respond',
          status: 409,
          message: 'This invitation was withdrawn.',
        );
        await qaTap(tester, find.bySemanticsLabel('Decline Trek planners'));
        expect(find.text('This invitation was withdrawn.'), findsOneWidget);
        expect(find.text('Trek planners'), findsOneWidget);
        final decline = tester.widget<OutlinedButton>(
          _button<OutlinedButton>(_en.groupsDecline),
        );
        expect(decline.onPressed, isNotNull, reason: 're-enabled');
        expect(
          world.api.sent('POST', '/engagement/groups/p1/invites/respond'),
          hasLength(1),
        );

        // Offline: the local wording.
        world.api.offline('POST /engagement/groups/*/invites/respond');
        await qaSnackGone(tester);
        await qaTap(tester, find.bySemanticsLabel('Decline Trek planners'));
        expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);

        // A 500 without a message: the screen's own fallback.
        world.api.on(
          'POST /engagement/groups/*/invites/respond',
          (_) => const QaReply(500, null),
        );
        await qaSnackGone(tester);
        await qaTap(tester, find.bySemanticsLabel('Decline Trek planners'));
        expect(find.text(_en.groupsAnswerFailed), findsOneWidget);

        // Back online, a single retry succeeds.
        world.api.on('POST /engagement/groups/*/invites/respond', (c) {
          world.groups['p1']!['invite_id'] = '';
          return qaOk({'group': world.groups['p1']});
        });
        await qaSnackGone(tester);
        await qaTap(tester, find.bySemanticsLabel('Decline Trek planners'));
        expect(
          world.api.sent('POST', '/engagement/groups/p1/invites/respond'),
          hasLength(4),
        );
        expect(find.text('Trek planners'), findsNothing);
      },
    );
  });

  testWidgets('tapping one of my groups opens it '
      '[case:groups.groups.join_a_community_below_or_start.action]', (
    tester,
  ) async {
    final world = _world();
    await _open(tester, world);
    await qaTap(tester, find.text('Sunday hikers'));
    expect(
      tester.widget<GroupDetailScreen>(find.byType(GroupDetailScreen)).groupId,
      'mine',
    );
    expect(find.text(_en.groupsChatButton), findsOneWidget);
    expect(world.api.writes, isEmpty);
  });

  testWidgets('with no groups yet the empty note invites me to join or start '
      '[case:groups.groups.join_a_community_below_or_start.action]', (
    tester,
  ) async {
    final world = _world()..groups.remove('mine');
    await _open(tester, world);
    expect(find.text(_en.groupsEmptyTitle), findsOneWidget);
    expect(find.text(_en.groupsEmptyBody), findsOneWidget);
  });

  group('discover by lifestyle', () {
    testWidgets(
      'a lifestyle chip filters Discover on the server and tapping it again '
      'clears the filter [case:groups.groups.groups_category_x.action]',
      (tester) async {
        final world = _world()
          ..groups['m1'] = qaGroup(
            id: 'm1',
            name: 'Vinyl Sundays',
            category: 'music',
            canJoin: true,
          );
        await _open(tester, world);
        expect(find.text('Koramangala readers'), findsOneWidget);
        expect(find.text('Vinyl Sundays'), findsOneWidget);
        expect(find.text('📚  Books · 1'), findsOneWidget);
        expect(find.text('🎶  Music'), findsOneWidget);

        await qaTap(tester, qaKey('groups.category.books'));
        expect(world.api.sent('GET', '/engagement/groups').last.query, {
          'scope': 'discover',
          'category': 'books',
        });
        expect(
          tester.widget<ChoiceChip>(qaKey('groups.category.books')).selected,
          isTrue,
        );
        expect(find.text('Koramangala readers'), findsOneWidget);
        expect(find.text('Vinyl Sundays'), findsNothing);

        await qaTap(tester, qaKey('groups.category.books'));
        expect(
          tester.widget<ChoiceChip>(qaKey('groups.category.books')).selected,
          isFalse,
        );
        expect(find.text('Vinyl Sundays'), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets('All clears a lifestyle filter and shows every community '
        '[case:groups.groups.all.action]', (tester) async {
      final world = _world()
        ..groups['m1'] = qaGroup(
          id: 'm1',
          name: 'Vinyl Sundays',
          category: 'music',
          canJoin: true,
        );
      await _open(
        tester,
        world,
        screen: const GroupsScreen(initialCategory: 'music'),
      );
      expect(
        world.api.sent('GET', '/engagement/groups').map((c) => c.query),
        // A map is compared by value only through equals().
        contains(equals({'scope': 'discover', 'category': 'music'})),
      );
      expect(find.text('Koramangala readers'), findsNothing);
      final all = find.widgetWithText(ChoiceChip, _en.groupsCategoryAll);
      expect(tester.widget<ChoiceChip>(all).selected, isFalse);

      await qaTap(tester, all);
      expect(tester.widget<ChoiceChip>(all).selected, isTrue);
      expect(world.api.sent('GET', '/engagement/groups').last.query, {
        'scope': 'discover',
      });
      expect(find.text('Koramangala readers'), findsOneWidget);
      expect(find.text('Vinyl Sundays'), findsOneWidget);
    });

    testWidgets(
      'an empty lifestyle offers Start one, which opens a community group in '
      'that lifestyle '
      '[case:groups.groups.be_the_first_start_a_community_g_onaction.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        await qaTap(tester, qaKey('groups.category.music'));
        expect(find.text('No 🎶 Music groups yet'), findsOneWidget);
        expect(find.text(_en.groupsDiscoverEmptyBody), findsOneWidget);

        await qaTap(tester, _button<OutlinedButton>(_en.groupsStartOne));
        final create = tester.widget<CreateGroupScreen>(
          find.byType(CreateGroupScreen),
        );
        expect(create.initialKind, 'community');
        expect(create.initialCategory, 'music');
        // The lifestyle arrives chosen.
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '🎶  Music'))
              .selected,
          isTrue,
        );
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets('tapping a community card opens it '
        '[case:groups.groups.join.action]', (tester) async {
      final world = _world();
      await _open(tester, world);
      await qaTap(tester, find.text('Koramangala readers'));
      expect(
        tester
            .widget<GroupDetailScreen>(find.byType(GroupDetailScreen))
            .groupId,
        'g1',
      );
      expect(find.text(_en.groupsJoinGroup), findsOneWidget);
      expect(world.api.writes, isEmpty);
    });

    testWidgets(
      'Join on a community joins it, welcomes me and moves it to Your '
      'groups [case:groups.groups.groups_join_x.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        await qaTap(tester, qaKey('groups.join.g1'));

        expect(world.api.writeLines, ['POST /engagement/groups/g1/join']);
        expect(world.api.writes.single.data, isNull);
        expect(find.text('Welcome to Koramangala readers!'), findsOneWidget);
        expect(qaKey('groups.join.g1'), findsNothing);
        // Listed once, now under Your groups.
        expect(find.text('Koramangala readers'), findsOneWidget);
        expect(find.text(_en.groupsDiscoverEmptyTitle), findsOneWidget);
      },
    );

    testWidgets(
      'a refused Join explains, keeps the card offered and a retry joins once '
      '[case:groups.groups.groups_join_x.api_failure]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        world.api.fail(
          'POST /engagement/groups/*/join',
          status: 403,
          message: 'This group is full.',
        );
        await qaTap(tester, qaKey('groups.join.g1'));
        expect(find.text('This group is full.'), findsOneWidget);
        final join = tester.widget<FilledButton>(qaKey('groups.join.g1'));
        expect(join.onPressed, isNotNull, reason: 're-enabled');

        world.api.offline('POST /engagement/groups/*/join');
        await qaSnackGone(tester);
        await qaTap(tester, qaKey('groups.join.g1'));
        expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
        expect(qaKey('groups.join.g1'), findsOneWidget);

        world.api.on('POST /engagement/groups/*/join', (c) {
          world.groups['g1']!
            ..['my_role'] = 'member'
            ..['can_join'] = false;
          return qaOk({'group': world.groups['g1']});
        });
        await qaSnackGone(tester);
        await qaTap(tester, qaKey('groups.join.g1'));
        expect(
          world.api.sent('POST', '/engagement/groups/g1/join'),
          hasLength(3),
        );
        expect(qaKey('groups.join.g1'), findsNothing);
      },
    );

    testWidgets('one tap joins once: the button is disabled while joining '
        '[case:groups.groups.groups_join_x.api_failure]', (tester) async {
      final world = _world();
      await _open(tester, world);
      world.api.on('POST /engagement/groups/*/join', (c) {
        world.groups['g1']!
          ..['my_role'] = 'member'
          ..['can_join'] = false;
        return QaReply(200, {
          'group': world.groups['g1'],
        }, delay: const Duration(milliseconds: 300));
      });
      await tester.ensureVisible(qaKey('groups.join.g1'));
      await tester.tap(qaKey('groups.join.g1'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(qaKey('groups.join.g1')).onPressed,
        isNull,
      );
      await tester.tap(qaKey('groups.join.g1'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        world.api.sent('POST', '/engagement/groups/g1/join'),
        hasLength(1),
      );
    });
  });

  testWidgets(
    'Groups renders translated in every locale [case:groups.groups.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        final world = _world();
        await _open(tester, world, locale: locale);
        final l10n = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.groupsTitle), findsOneWidget, reason: '$locale');
        expect(find.text(l10n.groupsStartGroup), findsOneWidget);
        expect(find.text(l10n.groupsInvitationsHeader), findsOneWidget);
        expect(find.text(l10n.groupsDiscoverHeader), findsOneWidget);
        expect(find.text(l10n.groupsCategoryAll), findsOneWidget);
        expect(find.text(l10n.groupsDecline), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
