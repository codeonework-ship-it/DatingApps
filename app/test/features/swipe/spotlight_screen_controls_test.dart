// The full Spotlight screen: every button acts on the member on the card
// through the shared profile actions, with its own `qa.spotlight.*` handles
// (it used to share `qa.discovery.*` with the deck underneath). Each test
// asserts the request, the screen that follows and the visible text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/passed_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/spotlight_profiles_screen.dart';

import '../../support/qa_api.dart';
import 'discover_qa_fixtures.dart';

const _like = ValueKey('qa.spotlight.like_button');
const _pass = ValueKey('qa.spotlight.pass_button');
const _superLike = ValueKey('qa.spotlight.superlike_button');
const _undo = ValueKey('qa.spotlight.undo_button');
const _message = ValueKey('qa.spotlight.message_button');
const _cardMessage = ValueKey('qa.spotlight.card_message_button');
const _viewMore = ValueKey('qa.spotlight.view_more_button');
const _love = ValueKey('qa.profile_detail.love_button');
const _profileMessage = ValueKey('qa.profile_detail.message_button');

final _sami = qaMember('sami', 'Sami', age: 24);
final _tara = qaMember('tara', 'Tara', age: 35, verified: false);
final _uma = qaMember('uma', 'Uma', age: 41);

/// The Spotlight screen pushed from a launcher, over [profiles].
Future<List<Object?>> _openSpotlight(
  WidgetTester tester,
  QaApi api, {
  List<DiscoveryProfile>? profiles,
}) => pumpQa(
  tester,
  api,
  SpotlightProfilesScreen(profiles: profiles ?? [_sami, _tara, _uma]),
  launcher: true,
  flags: {'curated_daily_set_enabled': false},
  extra: qaDiscoverExtras(),
);

/// The real way in: Discover → Spotlight rail → View more.
Future<void> _openFromDiscover(WidgetTester tester, QaApi api) async {
  await pumpQa(
    tester,
    api,
    const HomeDiscoveryScreen(browseOnly: true),
    flags: {'curated_daily_set_enabled': false},
    extra: qaDiscoverExtras(),
  );
  await _tap(tester, const ValueKey('qa.spotlight.rail.view_more'));
  expect(find.byType(SpotlightProfilesScreen), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key).first);
  await tester.tap(find.byKey(key).first);
  await qaSettle(tester, frames: 14);
  qaDropImageErrors(tester);
}

Finder _card(String displayName) => find.descendant(
  of: find.byType(SpotlightProfilesScreen),
  matching: find.text(displayName),
);

void main() {
  qaSilenceNetworkImages();

  group('deck buttons', () {
    testWidgets(
      'Like saves a like for the member on the card and moves on '
      '[case:swipe.spotlight_profiles.like_icon_favorite_onlike.action] '
      '',
      (tester) async {
        final api = qaDiscoverApi();
        await _openSpotlight(tester, api);
        expect(_card('Sami, 24'), findsOneWidget);

        await _tap(tester, _like);

        expect(qaSwipes(api), [qaSwipeBody('sami', like: true)]);
        expect(qaSnackText(tester), 'Super like sent to Sami');
        expect(_card('Tara, 35'), findsOneWidget);
      },
    );

    testWidgets(
      'a refused Like keeps the card and explains '
      '[case:swipe.spotlight_profiles.like_icon_favorite_onlike.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()..fail('POST /swipe');
        await _openSpotlight(tester, api);
        await _tap(tester, _like);

        expect(_card('Sami, 24'), findsOneWidget);
        expect(
          qaSnackText(tester),
          'Unable to like right now. Please try again.',
        );
      },
    );

    testWidgets(
      'Super like saves a like and moves on '
      '[case:swipe.spotlight_profiles.super_like_icon_star_onsuperlike.action] '
      '',
      (tester) async {
        final api = qaDiscoverApi();
        await _openSpotlight(tester, api);
        await _tap(tester, _superLike);

        expect(qaSwipes(api), [qaSwipeBody('sami', like: true)]);
        expect(_card('Tara, 35'), findsOneWidget);
      },
    );

    testWidgets(
      'a Super like over the daily limit is explained '
      '[case:swipe.spotlight_profiles.super_like_icon_star_onsuperlike.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()
          ..on('POST /swipe', (_) => qaDailyLikeLimit());
        await _openSpotlight(tester, api);
        await _tap(tester, _superLike);

        expect(_card('Sami, 24'), findsOneWidget);
        expect(qaSnackText(tester), contains("You've used today's 10 likes"));
        expect(find.text('See plans'), findsOneWidget);
      },
    );

    testWidgets('Pass saves a pass, moves on and counts it '
        '[case:swipe.spotlight_profiles.pass_icon_close_onpass.action] '
        ''
        '[case:swipe.spotlight_profiles.passed_count.label]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api);
      expect(find.text('Passed (0)'), findsOneWidget);

      await _tap(tester, _pass);

      expect(qaSwipes(api), [qaSwipeBody('sami', like: false)]);
      expect(_card('Tara, 35'), findsOneWidget);
      expect(find.text('Passed (1)'), findsOneWidget);
    });

    // Regression (2026-10-02): "Passed (n)" had an empty callback.
    testWidgets('Passed (n) opens the members passed on, with the one just '
        'passed listed [case:swipe.spotlight_profiles.passed_count.action] '
        '[case:swipe.spotlight_profiles.passed_count.not_noop]', (
      tester,
    ) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api);

      // Nothing passed yet: it still opens the list, which says so.
      await _tap(tester, const ValueKey('qa.spotlight.passed_button'));
      expect(find.byType(PassedProfilesScreen), findsOneWidget);
      expect(find.text('Passed Profiles'), findsOneWidget);
      expect(find.text('No passed profiles yet'), findsOneWidget);
      await tester.pageBack();
      await qaSettle(tester);
      expect(find.byType(PassedProfilesScreen), findsNothing);

      await _tap(tester, _pass);
      expect(find.text('Passed (1)'), findsOneWidget);
      await _tap(tester, const ValueKey('qa.spotlight.passed_button'));

      expect(find.byType(PassedProfilesScreen), findsOneWidget);
      expect(find.text('No passed profiles yet'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PassedProfilesScreen),
          matching: find.textContaining('Sami'),
        ),
        findsOneWidget,
      );
      expect(qaSwipes(api), [qaSwipeBody('sami', like: false)]);
    });

    testWidgets(
      'an offline Pass keeps the card and says so '
      '[case:swipe.spotlight_profiles.pass_icon_close_onpass.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()..offline('POST /swipe');
        await _openSpotlight(tester, api);
        await _tap(tester, _pass);

        expect(qaSwipes(api), hasLength(2), reason: 'one automatic retry');
        expect(_card('Sami, 24'), findsOneWidget);
        expect(find.text('Passed (0)'), findsOneWidget);
        expect(
          qaSnackText(tester),
          'Unable to pass right now. Please try again.',
        );
      },
    );

    testWidgets('Undo shows the last card again (local only, no request) '
        '[case:swipe.spotlight_profiles.undo_icon_undo_onundo.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api);
      await _tap(tester, _pass);
      expect(find.text('Passed (1)'), findsOneWidget);

      await _tap(tester, _undo);

      expect(_card('Sami, 24'), findsOneWidget);
      expect(find.text('Passed (0)'), findsOneWidget);
      expect(qaSwipes(api), hasLength(1));
    });

    testWidgets('after the last card the screen says everyone was reviewed '
        '[case:swipe.spotlight_profiles.like_icon_favorite_onlike.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api, profiles: [_sami]);
      await _tap(tester, _like);

      expect(find.text('All spotlight profiles reviewed!'), findsOneWidget);
    });
  });

  group('Message', () {
    for (final (key, label) in [(_message, 'bar'), (_cardMessage, 'card')]) {
      testWidgets(
        '$label Message without a match likes, explains and stays '
        '[case:swipe.spotlight_profiles.x_card_message_button_message.action] '
        ''
        '[case:discover.profile_entry_points.spotlight_screen.message_2]',
        (tester) async {
          final api = qaDiscoverApi();
          await _openSpotlight(tester, api);
          await _tap(tester, key);

          expect(api.sent('GET', '/matches/me'), isNotEmpty);
          expect(qaSwipes(api), [qaSwipeBody('sami', like: true)]);
          expect(
            qaSnackText(tester),
            'Love sent to Sami. You can chat as soon as they like you back.',
          );
          expect(find.byType(ChatScreen), findsNothing);
        },
      );
    }

    testWidgets(
      'Message with a match opens that chat, no like '
      '[case:swipe.spotlight_profiles.x_card_message_button_message.action] '
      '[case:discover.profile_entry_points.spotlight_screen.message_2]',
      (tester) async {
        final api = qaDiscoverApi(
          matches: [qaMatchRow('match-sami', 'sami', 'Sami')],
        );
        await _openSpotlight(tester, api);
        await _tap(tester, _cardMessage);

        expect(
          tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
          'match-sami',
        );
        expect(qaSwipes(api), isEmpty);
      },
    );

    testWidgets(
      'Message over the daily limit is explained, no chat '
      '[case:swipe.spotlight_profiles.x_card_message_button_message.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()
          ..on('POST /swipe', (_) => qaDailyLikeLimit());
        await _openSpotlight(tester, api);
        await _tap(tester, _message);

        expect(find.byType(ChatScreen), findsNothing);
        expect(qaSnackText(tester), contains("You've used today's 10 likes"));
      },
    );
  });

  group('View more', () {
    // Regression (2026-10-02): the Spotlight screen opened profiles without
    // recording the view, unlike every other way into a profile.
    testWidgets(
      'opens the member on the card and records the view '
      '[case:swipe.spotlight_profiles.x_view_more_button_openprofile.action] '
      '',
      (tester) async {
        final api = qaDiscoverApi();
        await _openSpotlight(tester, api);
        await _tap(tester, _viewMore);

        expect(
          tester
              .widget<ProfileDetailsScreen>(find.byType(ProfileDetailsScreen))
              .profile
              .id,
          'sami',
        );
        expect(api.sent('POST', '/profile/views').single.body, {
          'viewer_user_id': 'me',
          'viewed_user_id': 'sami',
        });
      },
    );

    testWidgets('Love on a Spotlight profile (Discover → Spotlight → View '
        'more) likes that member and the screen moves on '
        '[case:discover.profile_entry_points.spotlight_screen.love]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [qaCandidate('anya', 'Anya')],
        spotlight: [
          qaCandidate('sami', 'Sami', age: 24, spotlight: true),
          qaCandidate('tara', 'Tara', age: 35, spotlight: true),
        ],
      );
      await _openFromDiscover(tester, api);
      await _tap(tester, _viewMore);
      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('sami', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(_card('Tara, 35'), findsOneWidget);
    });

    testWidgets('Message on a Spotlight profile with a match opens the chat '
        '[case:discover.profile_entry_points.spotlight_screen.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [qaCandidate('anya', 'Anya')],
        spotlight: [qaCandidate('sami', 'Sami', age: 24, spotlight: true)],
        matches: [qaMatchRow('match-sami', 'sami', 'Sami')],
      );
      await _openFromDiscover(tester, api);
      await _tap(tester, _viewMore);
      await _tap(tester, _profileMessage);

      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'match-sami',
      );
      expect(qaSwipes(api), isEmpty);
    });

    testWidgets(
      'a failed Love keeps the profile and the card '
      '[case:swipe.spotlight_profiles.x_view_more_button_openprofile.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()..fail('POST /swipe', status: 502);
        await _openSpotlight(tester, api);
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

  group('header and filters', () {
    testWidgets(
      'Back closes Spotlight '
      '[case:swipe.spotlight_profiles.spotlight_back_button_back.action]',
      (tester) async {
        final api = qaDiscoverApi();
        await _openSpotlight(tester, api);
        await _tap(tester, const ValueKey('qa.spotlight.back_button'));

        expect(find.byType(SpotlightProfilesScreen), findsNothing);
        expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
      },
    );

    testWidgets('Messages points the member to Discover '
        '[case:swipe.spotlight_profiles.messages.action]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api);
      await _tap(tester, const ValueKey('qa.spotlight.messages_button'));

      expect(qaSnackText(tester), 'Open chats from Discover');
    });

    testWidgets('the bell says there is nothing new '
        '[case:swipe.spotlight_profiles.spotlight_notifications_button.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api);
      await _tap(tester, const ValueKey('qa.spotlight.notifications_button'));

      expect(qaSnackText(tester), 'No new notifications');
    });

    testWidgets('Filters → Verified only → Apply hides unverified members '
        '[case:swipe.spotlight_profiles.filters_onfilters.action] '
        '[case:swipe.spotlight_profiles.apply.action] '
        '[case:swipe.spotlight_profiles.spotlight_filters_verified_only.action] '
        '[case:swipe.spotlight_profiles.spotlight_filters_apply.action]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api, profiles: [_tara, _uma]);
      expect(_card('Tara, 35'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.spotlight.filters_button'));
      expect(find.text('Verified only'), findsOneWidget);
      await _tap(tester, const ValueKey('qa.spotlight.filters.verified_only'));
      await _tap(tester, const ValueKey('qa.spotlight.filters.apply'));

      expect(
        find.byKey(const ValueKey('qa.spotlight.filters.apply')),
        findsNothing,
        reason: 'the sheet closed',
      );
      expect(_card('Tara, 35'), findsNothing);
      expect(_card('Uma, 41'), findsOneWidget);
      expect(find.text('Verified only'), findsOneWidget, reason: 'chip');
      expect(api.writes, isEmpty, reason: 'filtering is local');
    });

    testWidgets('the age range slider narrows the members shown '
        '[case:swipe.spotlight_profiles.spotlight_filters_age_range.action] '
        '[case:swipe.spotlight_profiles.spotlight_filters_apply.action]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api, profiles: [_sami, _uma]);
      await _tap(tester, const ValueKey('qa.spotlight.filters_button'));
      expect(find.text('Age range: 20 - 50'), findsOneWidget);

      // Drag the lower thumb from 20 to the upper half of the 18–60 track.
      final slider = tester.getRect(
        find.byKey(const ValueKey('qa.spotlight.filters.age_range')),
      );
      const pad = 24.0; // the slider's overlay padding on each side
      final track = slider.width - 2 * pad;
      final from = Offset(
        slider.left + pad + track * (20 - 18) / 42,
        slider.center.dy,
      );
      await tester.dragFrom(from, Offset(track * 12 / 42, 0));
      await qaSettle(tester);
      final label = find.textContaining('Age range: ');
      final text = tester.widget<Text>(label).data!;
      final min = int.parse(RegExp(r'(\d+) - ').firstMatch(text)!.group(1)!);
      expect(min, greaterThan(24), reason: text);

      await _tap(tester, const ValueKey('qa.spotlight.filters.apply'));
      expect(_card('Sami, 24'), findsNothing);
      expect(_card('Uma, 41'), findsOneWidget);
    });

    testWidgets('Reset puts the filters back before applying '
        '[case:swipe.spotlight_profiles.spotlight_filters_reset.action]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api, profiles: [_tara, _uma]);
      await _tap(tester, const ValueKey('qa.spotlight.filters_button'));
      bool resetEnabled() =>
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('qa.spotlight.filters.reset')),
              )
              .onPressed !=
          null;
      expect(
        resetEnabled(),
        isFalse,
        reason: 'the filters are the defaults: nothing to reset',
      );
      await _tap(tester, const ValueKey('qa.spotlight.filters.verified_only'));
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('qa.spotlight.filters.verified_only')),
            )
            .value,
        isTrue,
      );
      expect(resetEnabled(), isTrue);

      await _tap(tester, const ValueKey('qa.spotlight.filters.reset'));
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('qa.spotlight.filters.verified_only')),
            )
            .value,
        isFalse,
      );
      expect(find.text('Age range: 20 - 50'), findsOneWidget);
      expect(resetEnabled(), isFalse, reason: 'back at the defaults');

      await _tap(tester, const ValueKey('qa.spotlight.filters.apply'));
      expect(_card('Tara, 35'), findsOneWidget);
    });

    testWidgets('filters that match nobody say so '
        '[case:swipe.spotlight_profiles.spotlight_filters_apply.action]', (tester) async {
      final api = qaDiscoverApi();
      await _openSpotlight(tester, api, profiles: [_tara]);
      await _tap(tester, const ValueKey('qa.spotlight.filters_button'));
      await _tap(tester, const ValueKey('qa.spotlight.filters.verified_only'));
      await _tap(tester, const ValueKey('qa.spotlight.filters.apply'));

      expect(find.text('No spotlight profiles match filters'), findsOneWidget);
    });
  });
}
