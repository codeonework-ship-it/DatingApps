// Discover deck controls, end to end against a recording fake BFF: every
// button performs its action and the test asserts the request that reached
// the server, where the member ends up, and what they read — plus a failure
// path (server error, daily limit, offline) for each control that calls the
// API. Tagged with the QA catalog case ids.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/matching/screens/match_notification_screen.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/passed_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/spotlight_profiles_screen.dart';

import '../../support/qa_api.dart';
import 'discover_qa_fixtures.dart';

const _like = ValueKey('qa.discovery.like_button');
const _pass = ValueKey('qa.discovery.pass_button');
const _superLike = ValueKey('qa.discovery.superlike_button');
const _undo = ValueKey('qa.discovery.undo_button');
const _cardMessage = ValueKey('qa.discovery.card_message_button');
const _viewMore = ValueKey('qa.discovery.view_more_button');
const _love = ValueKey('qa.profile_detail.love_button');
const _profileMessage = ValueKey('qa.profile_detail.message_button');

final _anya = qaCandidate('anya', 'Anya');
final _bina = qaCandidate('bina', 'Bina', age: 31);

/// The deck as the Matches tab hosts it (browse mode), with [flags] on top
/// of the defaults. Today's rail is off unless a test turns it on.
Future<void> _openDeck(
  WidgetTester tester,
  QaApi api, {
  Map<String, bool> flags = const {},
  bool browseOnly = true,
}) async {
  await pumpQa(
    tester,
    api,
    HomeDiscoveryScreen(browseOnly: browseOnly),
    flags: {'curated_daily_set_enabled': false, ...flags},
    extra: qaDiscoverExtras(),
  );
  qaDropImageErrors(tester);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key).first);
  await tester.tap(find.byKey(key).first);
  await qaSettle(tester, frames: 12);
  qaDropImageErrors(tester);
}

Finder _name(String name) => find.textContaining(name);

void main() {
  qaSilenceNetworkImages();

  group('Like', () {
    testWidgets('saves one like for the top card and deals the next '
        '[case:swipe.home_discovery.discovery_like_button_like.action] '
        '[case:swipe.home_discovery.discovery_like_button_like.api_contract]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      expect(_name('Anya, 29'), findsOneWidget);

      await _tap(tester, _like);

      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
      expect(_name('Anya, 29'), findsNothing);
      expect(_name('Bina, 31'), findsOneWidget);
    });

    testWidgets('a mutual like opens the match screen, and Send Message '
        'opens the chat '
        '[case:swipe.home_discovery.discovery_like_button_like.action] '
        '[case:matching.match_notification.send_message.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [_anya, _bina],
        swipe: {'match_id': 'match-anya'},
      );
      await _openDeck(tester, api);
      await _tap(tester, _like);

      expect(find.byType(MatchNotificationScreen), findsOneWidget);
      expect(find.text("It's a match!"), findsOneWidget);
      expect(find.text('You and Anya liked each other'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.match_notification.send_message'));
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(MatchNotificationScreen), findsNothing);
      final chat = tester.widget<ChatScreen>(find.byType(ChatScreen));
      expect(chat.matchId, 'match-anya');
      expect(chat.otherUserId, 'anya');
      expect(api.sent('GET', '/chat/match-anya/messages'), isNotEmpty);
    });

    testWidgets('Keep Swiping closes the match screen back to the deck '
        '[case:matching.match_notification.keep_swiping.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [_anya, _bina],
        swipe: {'match_id': 'match-anya'},
      );
      await _openDeck(tester, api);
      await _tap(tester, _like);
      await _tap(tester, const ValueKey('qa.match_notification.keep_swiping'));

      expect(find.byType(MatchNotificationScreen), findsNothing);
      expect(_name('Bina, 31'), findsOneWidget);
    });

    testWidgets('a server error keeps the card and says so '
        '[case:swipe.home_discovery.discovery_like_button_like.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina])..fail('POST /swipe');
      await _openDeck(tester, api);
      await _tap(tester, _like);

      // One automatic retry for a 5xx, then the member is told.
      expect(qaSwipes(api), [
        qaSwipeBody('anya', like: true),
        qaSwipeBody('anya', like: true),
      ]);
      expect(_name('Anya, 29'), findsOneWidget);
      expect(
        qaSnackText(tester),
        'Unable to like right now. Please try again.',
      );
    });

    testWidgets('the daily like limit opens the limit sheet; Not now closes '
        'it and keeps the card '
        '[case:swipe.home_discovery.discovery_like_button_like.api_failure] '
        '[case:swipe.home_discovery.not_now.action] '
        '[case:swipe.home_discovery.not_now_2.action]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya, _bina])
        ..on('POST /swipe', (_) => qaDailyLikeLimit());
      await _openDeck(tester, api);
      await _tap(tester, _like);

      expect(qaSwipes(api), hasLength(1), reason: 'a 429 is not retried');
      expect(find.text("You've used today's 10 likes on Free"), findsOneWidget);
      expect(find.textContaining('Resets at'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.discovery.daily_limit.not_now'));
      expect(find.text("You've used today's 10 likes on Free"), findsNothing);
      expect(_name('Anya, 29'), findsOneWidget);
    });

    testWidgets('See plans on the limit sheet opens the plans '
        '[case:swipe.home_discovery.see_plans.action]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya])
        ..on('POST /swipe', (_) => qaDailyLikeLimit());
      await _openDeck(tester, api);
      await _tap(tester, _like);
      await _tap(tester, const ValueKey('qa.discovery.daily_limit.see_plans'));

      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });
  });

  group('Super like', () {
    testWidgets(
      'saves a like for the top card, confirms it and deals the '
      'next '
      '[case:swipe.home_discovery.discovery_superlike_button_superlike.action] '
      '[case:swipe.home_discovery.discovery_superlike_button_superlike.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina]);
        await _openDeck(tester, api);
        await _tap(tester, _superLike);

        expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
        expect(qaSnackText(tester), 'Super like sent to Anya');
        expect(_name('Bina, 31'), findsOneWidget);
      },
    );

    testWidgets(
      'offline: retried once, then explained; the card stays '
      '[case:swipe.home_discovery.discovery_superlike_button_superlike.api_failure]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina])..offline('POST /swipe');
        await _openDeck(tester, api);
        await _tap(tester, _superLike);

        expect(qaSwipes(api), hasLength(2));
        expect(
          qaSnackText(tester),
          'Unable to like right now. Please try again.',
        );
        expect(_name('Anya, 29'), findsOneWidget);
      },
    );
  });

  group('Pass and Undo', () {
    testWidgets('Pass saves a pass for the top card and deals the next '
        '[case:swipe.home_discovery.discovery_pass_button_pass.action] '
        '[case:swipe.home_discovery.discovery_pass_button_pass.api_contract]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      await _tap(tester, _pass);

      expect(qaSwipes(api), [qaSwipeBody('anya', like: false)]);
      expect(_name('Bina, 31'), findsOneWidget);
      expect(qaSnackText(tester), isNull);
    });

    // Regression (2026-10-02): a refused pass put the card back with no
    // word to the member.
    testWidgets('a refused pass puts the card back and says why '
        '[case:swipe.home_discovery.discovery_pass_button_pass.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina])
        ..fail('POST /swipe', status: 503);
      await _openDeck(tester, api);
      await _tap(tester, _pass);

      expect(qaSwipes(api), hasLength(2));
      expect(_name('Anya, 29'), findsOneWidget);
      expect(
        qaSnackText(tester),
        'Unable to pass right now. Please try again.',
      );
    });

    testWidgets('Undo brings the last card back without another request '
        '[case:swipe.home_discovery.discovery_undo_button_undo.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      await _tap(tester, _pass);
      expect(_name('Bina, 31'), findsOneWidget);

      await _tap(tester, _undo);

      expect(_name('Anya, 29'), findsOneWidget);
      expect(qaSwipes(api), hasLength(1));
    });
  });

  group('card Message', () {
    testWidgets(
      'without a match: one like for this member, explained, and '
      'the member leaves the deck '
      '[case:swipe.home_discovery.discovery_card_message_button_message.action] '
      '[case:swipe.home_discovery.discovery_card_message_button_message.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina]);
        await _openDeck(tester, api);
        final before = api.sent('GET', '/matches/me').length;

        await _tap(tester, _cardMessage);

        expect(
          api.sent('GET', '/matches/me').length,
          greaterThan(before),
          reason: 'looks for an existing match first',
        );
        expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
        expect(
          qaSnackText(tester),
          'Love sent to Anya. You can chat as soon as they like you back.',
        );
        expect(find.byType(ChatScreen), findsNothing);
        expect(_name('Bina, 31'), findsOneWidget);
      },
    );

    testWidgets(
      'with a match: opens that chat and sends no like '
      '[case:swipe.home_discovery.discovery_card_message_button_message.action]',
      (tester) async {
        final api = qaDiscoverApi(
          deck: [_anya, _bina],
          matches: [qaMatchRow('match-anya', 'anya', 'Anya')],
        );
        await _openDeck(tester, api);
        await _tap(tester, _cardMessage);

        expect(find.byType(ChatScreen), findsOneWidget);
        expect(
          tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
          'match-anya',
        );
        expect(qaSwipes(api), isEmpty);
      },
    );

    testWidgets(
      'a like that makes the match opens the chat straight away '
      '[case:swipe.home_discovery.discovery_card_message_button_message.action]',
      (tester) async {
        final api = qaDiscoverApi(
          deck: [_anya, _bina],
          swipe: {'match_id': 'match-new'},
        );
        await _openDeck(tester, api);
        await _tap(tester, _cardMessage);

        expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
        expect(find.byType(ChatScreen), findsOneWidget);
        expect(
          tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
          'match-new',
        );
      },
    );

    testWidgets(
      'the daily like limit is explained with a way to the plans '
      '[case:swipe.home_discovery.discovery_card_message_button_message.api_failure]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina])
          ..on('POST /swipe', (_) => qaDailyLikeLimit());
        await _openDeck(tester, api);
        await _tap(tester, _cardMessage);

        expect(find.byType(ChatScreen), findsNothing);
        expect(find.text("You've used today's 10 likes on Free"), findsWidgets);
        expect(find.text('See plans'), findsWidgets);
        expect(_name('Anya, 29'), findsOneWidget);
      },
    );
  });

  group('View more (profile from the deck)', () {
    testWidgets(
      'opens the profile and records the view '
      '[case:swipe.home_discovery.discovery_view_more_button_openprofile.action] '
      '[case:swipe.home_discovery.discovery_view_more_button_openprofile.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina]);
        await _openDeck(tester, api);
        await _tap(tester, _viewMore);

        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(
          tester
              .widget<ProfileDetailsScreen>(find.byType(ProfileDetailsScreen))
              .profile
              .id,
          'anya',
        );
        expect(api.sent('POST', '/profile/views').single.body, {
          'viewer_user_id': 'me',
          'viewed_user_id': 'anya',
        });
      },
    );

    testWidgets('Love there likes this member, closes, and the deck moves on '
        '[case:discover.profile_entry_points.discover_view_more.love]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      await _tap(tester, _viewMore);
      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(qaSnackText(tester), 'Super like sent to Anya');
      expect(_name('Bina, 31'), findsOneWidget);
    });

    testWidgets('Message there (no match) likes, explains and stays '
        '[case:discover.profile_entry_points.discover_view_more.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      await _tap(tester, _viewMore);
      await _tap(tester, _profileMessage);

      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
      expect(
        qaSnackText(tester),
        'Love sent to Anya. You can chat as soon as they like you back.',
      );
    });

    testWidgets(
      'a failed Love keeps the profile open and says so '
      '[case:swipe.home_discovery.discovery_view_more_button_openprofile.api_failure]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina])..fail('POST /swipe');
        await _openDeck(tester, api);
        await _tap(tester, _viewMore);
        await _tap(tester, _love);

        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(
          qaSnackText(tester),
          'Unable to like right now. Please try again.',
        );
      },
    );
  });

  group('error and empty states', () {
    testWidgets(
      'a failed load shows the error; Try Again reloads the deck '
      '[case:swipe.home_discovery.discovery_retry_state_retry.action] '
      '[case:swipe.home_discovery.discovery_retry_state_retry.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya])..fail('GET /discovery/me');
        await _openDeck(tester, api);
        expect(
          find.text('Something broke on our side.'),
          findsOneWidget,
          reason: 'the server message is shown as sent',
        );
        expect(api.sent('GET', '/discovery/me'), hasLength(1));

        api.json('GET /discovery/me', {
          'candidates': [_anya],
        });
        await _tap(tester, const ValueKey('qa.discovery.state_action_button'));

        expect(api.sent('GET', '/discovery/me'), hasLength(2));
        expect(api.sent('GET', '/discovery/me').last.query, {
          'limit': 50,
          'mode': 'all',
        });
        expect(_name('Anya, 29'), findsOneWidget);
      },
    );

    testWidgets('offline retry keeps the error state with the localized '
        'message '
        '[case:swipe.home_discovery.discovery_retry_state_retry.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi()..offline('GET /discovery/me');
      await _openDeck(tester, api);
      await _tap(tester, const ValueKey('qa.discovery.state_action_button'));

      expect(api.sent('GET', '/discovery/me'), hasLength(2));
      expect(
        find.text('Failed to load profiles. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'the empty deck refreshes on Refresh '
      '[case:swipe.home_discovery.discovery_empty_state_refresh.action] '
      '[case:swipe.home_discovery.discovery_empty_state_refresh.api_contract]',
      (tester) async {
        final api = qaDiscoverApi();
        await _openDeck(tester, api);
        expect(find.text('No profiles'), findsOneWidget);

        api.json('GET /discovery/me', {
          'candidates': [_bina],
        });
        await _tap(tester, const ValueKey('qa.discovery.state_action_button'));

        expect(api.sent('GET', '/discovery/me'), hasLength(2));
        expect(_name('Bina, 31'), findsOneWidget);
      },
    );

    testWidgets(
      'a refresh that fails turns the empty state into the error '
      '[case:swipe.home_discovery.discovery_empty_state_refresh.api_failure]',
      (tester) async {
        final api = qaDiscoverApi();
        await _openDeck(tester, api);
        api.fail('GET /discovery/me', message: 'Discovery is resting.');
        await _tap(tester, const ValueKey('qa.discovery.state_action_button'));

        expect(find.text('Discovery is resting.'), findsOneWidget);
        expect(find.text('No profiles'), findsNothing);
      },
    );
  });

  group('header', () {
    testWidgets(
      'the bell opens the notifications sheet; Who liked me opens '
      'the list and closes the sheet '
      '[case:swipe.home_discovery.notificationbell_ontap.action] '
      '[case:swipe.home_discovery.showmodalbottomsheet_open.action] '
      '[case:swipe.home_discovery.discovery_notification_who_liked_me.action]',
      (tester) async {
        final api = qaDiscoverApi(
          deck: [_anya],
          likedMe: [qaCandidate('cara', 'Cara')],
        );
        await _openDeck(tester, api);
        await _tap(tester, const ValueKey('qa.discovery.notifications_button'));

        expect(find.text('Latest unread notifications'), findsOneWidget);
        expect(find.text('Who has liked me'), findsOneWidget);
        expect(find.text('1 new like'), findsOneWidget);

        await _tap(
          tester,
          const ValueKey('qa.discovery.notification.who_liked_me'),
        );
        expect(find.byType(LikedMeScreen), findsOneWidget);
        expect(find.text('Latest unread notifications'), findsNothing);
        expect(find.text('Cara, 29'), findsOneWidget);
      },
    );

    testWidgets('with nothing unread the sheet says so '
        '[case:swipe.home_discovery.showmodalbottomsheet_open.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya]);
      await _openDeck(tester, api);
      await _tap(tester, const ValueKey('qa.discovery.notifications_button'));

      expect(find.text('No unread notifications'), findsOneWidget);
    });

    testWidgets('Passed opens the passed list with the member just passed '
        '[case:swipe.home_discovery.discovery_passed_button_2.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openDeck(tester, api);
      await _tap(tester, _pass);
      await _tap(tester, const ValueKey('qa.discovery.passed_button'));

      expect(find.byType(PassedProfilesScreen), findsOneWidget);
      expect(find.text('Anya, 29'), findsOneWidget);
    });
  });

  group('Spotlight rail', () {
    final spotlight = [
      qaCandidate('sami', 'Sami', spotlight: true),
      qaCandidate('tara', 'Tara', spotlight: true),
    ];

    testWidgets(
      'a card opens that member and records the view '
      '[case:swipe.home_discovery.open_profile_icon_person_onopenprofile.action] '
      '[case:swipe.home_discovery.open_profile_icon_person_onopenprofile.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya], spotlight: spotlight);
        await _openDeck(tester, api);
        await _tap(tester, const ValueKey('qa.spotlight.rail.card.1'));

        expect(
          tester
              .widget<ProfileDetailsScreen>(find.byType(ProfileDetailsScreen))
              .profile
              .id,
          'tara',
        );
        expect(api.sent('POST', '/profile/views').single.body, {
          'viewer_user_id': 'me',
          'viewed_user_id': 'tara',
        });
      },
    );

    testWidgets('Love from a rail profile likes that member, not the deck card '
        '[case:discover.profile_entry_points.spotlight_rail.love]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya], spotlight: spotlight);
      await _openDeck(tester, api);
      await _tap(tester, const ValueKey('qa.spotlight.rail.card.0'));
      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('sami', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(qaSnackText(tester), 'Super like sent to Sami');
      expect(_name('Anya, 29'), findsOneWidget, reason: 'deck untouched');
      expect(
        find.byKey(const ValueKey('qa.spotlight.rail.card.1')),
        findsNothing,
        reason: 'Sami left the rail',
      );
    });

    testWidgets('Message from a rail profile with a match opens the chat '
        '[case:discover.profile_entry_points.spotlight_rail.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [_anya],
        spotlight: spotlight,
        matches: [qaMatchRow('match-tara', 'tara', 'Tara')],
      );
      await _openDeck(tester, api);
      await _tap(tester, const ValueKey('qa.spotlight.rail.card.1'));
      await _tap(tester, _profileMessage);

      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'match-tara',
      );
      expect(qaSwipes(api), isEmpty);
    });

    testWidgets(
      'a failed Love from the rail is explained, profile stays '
      '[case:swipe.home_discovery.open_profile_icon_person_onopenprofile.api_failure]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya], spotlight: spotlight)
          ..on('POST /swipe', (_) => qaDailyLikeLimit());
        await _openDeck(tester, api);
        await _tap(tester, const ValueKey('qa.spotlight.rail.card.0'));
        await _tap(tester, _love);

        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(qaSnackText(tester), contains("You've used today's 10 likes"));
      },
    );

    testWidgets('View more opens the full Spotlight screen with the rail '
        '[case:swipe.home_discovery.view_more_onviewmore.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya], spotlight: spotlight);
      await _openDeck(tester, api);
      await _tap(tester, const ValueKey('qa.spotlight.rail.view_more'));

      final screen = tester.widget<SpotlightProfilesScreen>(
        find.byType(SpotlightProfilesScreen),
      );
      expect(screen.profiles.map((p) => p.id), ['sami', 'tara']);
      expect(find.text('Spotlight Matches'), findsOneWidget);
    });
  });

  group('Today rail', () {
    final today = [
      qaCandidate('asha', 'Asha', reasons: ['Shares your intent']),
      qaCandidate('dev', 'Dev', reasons: ['Shows up']),
    ];

    testWidgets(
      'a pick opens that member and records the view '
      '[case:swipe.home_discovery.discover_today_card_x_openprofile.action] '
      '[case:swipe.home_discovery.discover_today_card_x_openprofile.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya], today: today);
        await _openDeck(
          tester,
          api,
          flags: {'curated_daily_set_enabled': true},
        );
        expect(api.sent('GET', '/discovery/me/today'), hasLength(1));
        await _tap(tester, const ValueKey('qa.discover.today.card.1'));

        expect(
          tester
              .widget<ProfileDetailsScreen>(find.byType(ProfileDetailsScreen))
              .profile
              .id,
          'dev',
        );
        expect(api.sent('POST', '/profile/views').single.body, {
          'viewer_user_id': 'me',
          'viewed_user_id': 'dev',
        });
      },
    );

    testWidgets('Love from a Today pick likes that member and reloads Today '
        '[case:discover.profile_entry_points.today_rail.love]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya], today: today);
      await _openDeck(tester, api, flags: {'curated_daily_set_enabled': true});
      await _tap(tester, const ValueKey('qa.discover.today.card.0'));
      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('asha', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(qaSnackText(tester), 'Super like sent to Asha');
      expect(api.sent('GET', '/discovery/me/today'), hasLength(2));
    });

    testWidgets('Message from a Today pick without a match likes and explains '
        '[case:discover.profile_entry_points.today_rail.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya], today: today);
      await _openDeck(tester, api, flags: {'curated_daily_set_enabled': true});
      await _tap(tester, const ValueKey('qa.discover.today.card.1'));
      await _tap(tester, _profileMessage);

      expect(qaSwipes(api), [qaSwipeBody('dev', like: true)]);
      expect(
        qaSnackText(tester),
        'Love sent to Dev. You can chat as soon as they like you back.',
      );
      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
    });

    testWidgets(
      'a failed Love from Today is explained '
      '[case:swipe.home_discovery.discover_today_card_x_openprofile.api_failure]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya], today: today)
          ..offline('POST /swipe');
        await _openDeck(
          tester,
          api,
          flags: {'curated_daily_set_enabled': true},
        );
        await _tap(tester, const ValueKey('qa.discover.today.card.0'));
        await _tap(tester, _love);

        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(
          qaSnackText(tester),
          'Unable to like right now. Please try again.',
        );
      },
    );

    testWidgets('Fits your week opens the dating rhythm settings '
        '[case:swipe.home_discovery.fits_your_week.action]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya], today: today);
      await _openDeck(
        tester,
        api,
        flags: {
          'curated_daily_set_enabled': true,
          'intentional_dating_enabled': true,
        },
      );
      await _tap(tester, const ValueKey('qa.discover.today.fits_your_week'));

      expect(find.byType(DatingRhythmScreen), findsOneWidget);
    });
  });

  group('Today screen', () {
    testWidgets(
      'Meet <name> opens the pick; Love there likes that member '
      '[case:swipe.home_discovery.today_profile_x_openprofile.action] '
      '[case:swipe.home_discovery.today_profile_x_openprofile.api_contract]',
      (tester) async {
        final api = qaDiscoverApi(
          deck: [_anya],
          today: [
            qaCandidate('asha', 'Asha', reasons: ['Shares your intent']),
          ],
        );
        await _openDeck(
          tester,
          api,
          browseOnly: false,
          flags: {
            'curated_daily_set_enabled': true,
            'intentional_dating_enabled': true,
          },
        );
        await _tap(tester, const ValueKey('qa.today.profile.asha'));
        expect(api.sent('POST', '/profile/views').single.body, {
          'viewer_user_id': 'me',
          'viewed_user_id': 'asha',
        });
        await _tap(tester, _love);

        expect(qaSwipes(api), [qaSwipeBody('asha', like: true)]);
        expect(find.byType(ProfileDetailsScreen), findsNothing);
        expect(find.byKey(const ValueKey('qa.today.screen')), findsOneWidget);
      },
    );

    testWidgets('a Today pick whose like hits the daily limit says so '
        '[case:swipe.home_discovery.today_profile_x_openprofile.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [_anya],
        today: [qaCandidate('asha', 'Asha')],
      )..on('POST /swipe', (_) => qaDailyLikeLimit());
      await _openDeck(
        tester,
        api,
        browseOnly: false,
        flags: {
          'curated_daily_set_enabled': true,
          'intentional_dating_enabled': true,
        },
      );
      await _tap(tester, const ValueKey('qa.today.profile.asha'));
      await _tap(tester, _love);

      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
      expect(qaSnackText(tester), contains("You've used today's 10 likes"));
    });

    testWidgets('Explore profiles opens the deck; Back to Today returns '
        '[case:swipe.home_discovery.explore_profiles.action] '
        '[case:swipe.home_discovery.back_to_today.action]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya]);
      await _openDeck(
        tester,
        api,
        browseOnly: false,
        flags: {
          'curated_daily_set_enabled': true,
          'intentional_dating_enabled': true,
        },
      );
      expect(find.text('A little breathing room.'), findsOneWidget);

      await tester.ensureVisible(find.text('Explore profiles'));
      await tester.tap(find.text('Explore profiles'));
      await qaSettle(tester);
      qaDropImageErrors(tester);
      expect(find.text('Explore'), findsOneWidget);
      expect(_name('Anya, 29'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.discovery.back_to_today'));
      expect(find.byKey(const ValueKey('qa.today.screen')), findsOneWidget);
      expect(_name('Anya, 29'), findsNothing);
    });
  });
}
