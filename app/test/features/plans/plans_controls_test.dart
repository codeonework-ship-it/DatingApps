import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/plans/screens/plan_sharing_sheet.dart';
import 'package:verified_dating_app/features/plans/screens/plans_screen.dart';

import '../../support/qa_api.dart';
import '../swipe/discover_qa_fixtures.dart';
import '../swipe/qa_screen_checks.dart';
import 'plans_qa_world.dart';

// The Date plans screen: the member's own plans across matches ("Mine")
// and the plans friends shared with them ("Friends"), both fed by the
// recording fake BFF. Pull to refresh, tab switching, the tile actions and
// the screen-level checks run against populated lists.

final _en = qaL10n(const Locale('en'));

const _mine = '/plans/me';
const _friends = '/friends/me/plans';

Map<String, dynamic> _myPlan() => planJson(
  status: 'accepted',
  nextAction: 'upcoming',
  viewerRole: 'proposer',
  venueArea: 'Indiranagar',
);

PlansWorld _populated() => PlansWorld(
  mine: [_myPlan()],
  friends: [
    friendPlanJson(),
    friendPlanJson(
      id: 'friend-plan-2',
      friendName: 'Dev',
      title: 'Dev has a date with Sam',
    ),
  ],
);

Future<List<Object?>> _open(
  WidgetTester tester,
  PlansWorld world, {
  int initialTab = 0,
  Locale? locale,
  Size size = const Size(430, 932),
  ThemeData? theme,
  bool launcher = false,
  List<Override> extra = const [],
}) async {
  Widget screen = PlansScreen(initialTab: initialTab);
  if (theme != null) {
    screen = qaThemed(theme, screen);
  }
  final results = await pumpQa(
    tester,
    world.api,
    screen,
    locale: locale,
    size: size,
    launcher: launcher,
    extra: extra,
  );
  await settle(tester);
  return results;
}

/// Pulls the visible list down past the refresh trigger and lets the
/// refresh finish.
Future<void> _pullToRefresh(WidgetTester tester, Finder onList) async {
  await tester.fling(onList, const Offset(0, 400), 1200);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await settle(tester);
}

Future<void> _showFriends(WidgetTester tester) async {
  await tester.tap(byKey('qa.plans.tab.friends'));
  await settle(tester);
}

void main() {
  group('tabs', () {
    testWidgets(
      'Mine and Friends switch between the two feeds, by tapping and by '
      'swiping [case:plans.plans.mine_onswipe.action]',
      (tester) async {
        final world = _populated();
        await _open(tester, world, initialTab: 1);
        expect(find.text('Meera has a date with Dev'), findsOneWidget);
        expect(find.text('With Arjun'), findsNothing);

        await tester.tap(byKey('qa.plans.tab.mine'));
        await settle(tester);
        expect(find.text('With Arjun'), findsOneWidget);
        expect(find.text('Meera has a date with Dev'), findsNothing);
        expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);

        // Swipe left: the Friends feed.
        await tester.fling(
          find.byType(TabBarView),
          const Offset(-400, 0),
          1200,
        );
        await settle(tester);
        expect(find.text('Meera has a date with Dev'), findsOneWidget);
        expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
        // Both feeds came from one load; switching sends nothing new.
        expect(world.api.sent('GET', _mine), hasLength(1));
        expect(world.api.sent('GET', _friends), hasLength(1));
      },
    );
  });

  group('pull to refresh', () {
    testWidgets(
      'pulling the empty Mine list loads again and shows the new plan '
      '[case:plans.plans.no_plans_yet_onrefresh.action]',
      (tester) async {
        final world = PlansWorld();
        await _open(tester, world);
        expect(find.text(_en.plansEmptyMineTitle), findsOneWidget);
        expect(world.api.sent('GET', _mine), hasLength(1));
        expect(world.api.sent('GET', _mine).single.query, {
          'scope': 'all',
          'limit': 100,
        });

        world.mine = [_myPlan()];
        await _pullToRefresh(tester, find.text(_en.plansEmptyMineTitle));

        expect(world.api.sent('GET', _mine), hasLength(2));
        expect(world.api.sent('GET', _friends), hasLength(2));
        expect(find.text(_en.plansEmptyMineTitle), findsNothing);
        expect(find.text('With Arjun'), findsOneWidget);
        expect(find.text(_en.plansNextUpcoming), findsOneWidget);
      },
    );

    testWidgets(
      'a failed refresh of Mine explains, keeps the empty state and the next '
      'pull retries [case:plans.plans.no_plans_yet_onrefresh.api_failure]',
      (tester) async {
        final world = PlansWorld();
        await _open(tester, world);

        world.api.on('GET $_mine', (_) => const QaReply(500, ''));
        await _pullToRefresh(tester, find.text(_en.plansEmptyMineTitle));
        expect(tester.takeException(), isNull);
        expect(find.text(_en.plansFeedLoadFailed), findsOneWidget);
        expect(find.text(_en.plansEmptyMineTitle), findsOneWidget);

        world.api.offline('GET $_mine');
        await _pullToRefresh(tester, find.text(_en.plansEmptyMineTitle));
        expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
        expect(find.text(_en.plansEmptyMineTitle), findsOneWidget);

        world
          ..mine = [_myPlan()]
          ..serve();
        await _pullToRefresh(tester, find.text(_en.plansEmptyMineTitle));
        expect(world.api.sent('GET', _mine), hasLength(4));
        expect(find.text(_en.networkOfflineTryAgain), findsNothing);
        expect(find.text('With Arjun'), findsOneWidget);
      },
    );

    testWidgets('a failed refresh keeps plans already on screen', (
      tester,
    ) async {
      final world = _populated();
      await _open(tester, world);
      world.api.fail('GET $_mine', message: 'Plans are resting.');

      await _pullToRefresh(tester, find.text('With Arjun'));

      expect(find.text('Plans are resting.'), findsOneWidget);
      expect(find.text('With Arjun'), findsOneWidget);
    });

    testWidgets(
      'pulling the empty Friends list loads again and shows what a friend '
      'just shared [case:plans.plans.nothing_shared_yet_onrefresh.action]',
      (tester) async {
        final world = PlansWorld();
        await _open(tester, world, initialTab: 1);
        expect(find.text(_en.plansEmptyFriendsTitle), findsOneWidget);

        world.friends = [friendPlanJson()];
        await _pullToRefresh(tester, find.text(_en.plansEmptyFriendsTitle));

        expect(world.api.sent('GET', _friends), hasLength(2));
        expect(find.text(_en.plansEmptyFriendsTitle), findsNothing);
        expect(find.text('Meera has a date with Dev'), findsOneWidget);
        expect(
          find.text(
            _en.plansFriendStatusLine(
              _en.plansViaFriend,
              _en.plansStatusWordConfirmed,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a failed refresh of Friends explains, keeps the empty state and the '
      'next pull retries '
      '[case:plans.plans.nothing_shared_yet_onrefresh.api_failure]',
      (tester) async {
        final world = PlansWorld();
        await _open(tester, world, initialTab: 1);

        world.api.fail('GET $_friends', message: 'Friends feed is resting.');
        await _pullToRefresh(tester, find.text(_en.plansEmptyFriendsTitle));
        expect(tester.takeException(), isNull);
        expect(find.text('Friends feed is resting.'), findsOneWidget);
        expect(find.text(_en.plansEmptyFriendsTitle), findsOneWidget);

        world.api.on('GET $_friends', (_) => const QaReply(500, ''));
        await _pullToRefresh(tester, find.text(_en.plansEmptyFriendsTitle));
        expect(find.text(_en.plansFeedLoadFailed), findsOneWidget);
        expect(find.text(_en.plansEmptyFriendsTitle), findsOneWidget);

        world
          ..friends = [friendPlanJson()]
          ..serve();
        await _pullToRefresh(tester, find.text(_en.plansEmptyFriendsTitle));
        expect(world.api.sent('GET', _friends), hasLength(4));
        expect(find.text(_en.plansFeedLoadFailed), findsNothing);
        expect(find.text('Meera has a date with Dev'), findsOneWidget);
      },
    );
  });

  group('my plan tiles', () {
    testWidgets(
      'tapping one of my plans opens the conversation with that match '
      '[case:plans.plans.plans_mine_x.action]',
      (tester) async {
        final world = _populated();
        await _open(tester, world, extra: qaDiscoverExtras());

        await tester.tap(find.text('With Arjun'));
        await qaSettle(tester, frames: 12);

        final chat = tester.widget<ChatScreen>(find.byType(ChatScreen));
        expect(chat.matchId, 'match-1');
        expect(chat.otherUserId, 'arjun');
        expect(chat.userName, 'Arjun');
        expect(world.api.writes, isEmpty);
        await teardown(tester);
      },
    );

    testWidgets(
      'Manage your contact sharing opens contact sharing for that plan '
      '[case:plans.plans.plans_sharing_x.action]',
      (tester) async {
        final world = _populated();
        await _open(tester, world);

        await tapKey(tester, 'qa.plans.sharing.plan-1');

        final sheet = tester.widget<PlanSharingSheet>(
          find.byType(PlanSharingSheet),
        );
        expect(sheet.plan.id, 'plan-1');
        expect(sheet.plan.matchId, 'match-1');
        expect(find.text(_en.planSharingTitle), findsOneWidget);
        expect(
          world.api.sent('GET', '/matches/match-1/plans/plan-1/sharing'),
          hasLength(1),
        );
        expect(find.byType(ChatScreen), findsNothing);
        expect(world.api.writes, isEmpty);
      },
    );
  });

  group('screen checks', () {
    testWidgets(
      'pushed from another screen it shows a back button that returns '
      '[case:plans.plans.back_affordance]',
      (tester) async {
        final world = _populated();
        final results = await _open(tester, world, launcher: true);
        expect(find.byType(PlansScreen), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await settle(tester);

        expect(find.byType(PlansScreen), findsNothing);
        expect(byKey('qa.test.launcher'), findsOneWidget);
        expect(results, [null]);
      },
    );

    testWidgets('both populated feeds meet the tap-target, label and contrast '
        'guidelines [case:plans.plans.a11y_guidelines]', (tester) async {
      for (final theme in qaLayoutThemes.entries) {
        final world = _populated();
        await _open(tester, world, theme: theme.value);
        expect(find.text('With Arjun'), findsOneWidget, reason: theme.key);
        await qaExpectA11y(tester);

        await _showFriends(tester);
        expect(
          find.text('Meera has a date with Dev'),
          findsOneWidget,
          reason: theme.key,
        );
        await qaExpectA11y(tester);
        await teardown(tester);
      }
    });

    testWidgets(
      'both populated feeds lay out on phones and tablets in both themes '
      '[case:plans.plans.layout_matrix]',
      (tester) async {
        await qaExpectLayout(
          tester,
          pump: (size, theme) async {
            await _open(tester, _populated(), size: size, theme: theme);
          },
          check: (where) {
            expect(find.text('With Arjun'), findsOneWidget, reason: where);
            expect(
              find.text(_en.plansManageSharing),
              findsOneWidget,
              reason: where,
            );
          },
        );
        await qaExpectLayout(
          tester,
          pump: (size, theme) async {
            await _open(
              tester,
              _populated(),
              size: size,
              theme: theme,
              initialTab: 1,
            );
          },
          check: (where) {
            expect(
              find.text('Meera has a date with Dev'),
              findsOneWidget,
              reason: where,
            );
            expect(
              find.text('Dev has a date with Sam'),
              findsOneWidget,
              reason: where,
            );
          },
        );
      },
    );

    testWidgets(
      'both feeds render translated in every locale with no English left '
      '[case:plans.plans.l10n]',
      (tester) async {
        const fixture = {
          'Arjun',
          'Meera has a date with Dev',
          'Dev has a date with Sam',
          'Indiranagar',
          'Koramangala',
        };
        final english = <String>[];
        for (final locale in [
          const Locale('en'),
          ...qaLocales.where((l) => l != const Locale('en')),
        ]) {
          final world = _populated();
          await _open(tester, world, locale: locale);
          final l10n = qaL10n(locale);
          expect(tester.takeException(), isNull, reason: '$locale');
          expect(find.text(l10n.plansTitle), findsOneWidget);
          expect(find.text(l10n.plansTabMine), findsOneWidget);
          expect(find.text(l10n.plansTabFriends), findsOneWidget);
          expect(find.text(l10n.plansWith('Arjun')), findsOneWidget);
          expect(find.text(l10n.plansNextUpcoming), findsOneWidget);
          expect(find.text(l10n.plansManageSharing), findsOneWidget);
          final strings = qaVisibleStrings(tester);
          if (locale.languageCode != 'en') {
            qaExpectNoEnglishLeaks(tester, locale, allow: fixture);
          }

          await _showFriends(tester);
          expect(
            find.text(
              l10n.plansFriendStatusLine(
                l10n.plansViaFriend,
                l10n.plansStatusWordConfirmed,
              ),
            ),
            findsWidgets,
          );
          if (locale.languageCode != 'en') {
            qaExpectNoEnglishLeaks(tester, locale, allow: fixture);
          }
          strings.addAll(qaVisibleStrings(tester));
          if (locale == const Locale('en')) {
            english.addAll(strings);
          } else if (locale == const Locale('de')) {
            expect(
              qaUntranslated(english, strings, fixture: fixture),
              isEmpty,
              reason: 'hard-coded strings on the plans screen',
            );
          }
          await teardown(tester);
        }
      },
    );
  });
}
