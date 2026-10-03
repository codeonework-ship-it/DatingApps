// Another member's profile, reached through every real entry point (the
// deck, the liked and passed lists, Liked you and its web /likes page), and
// each control on it: Love, Message, back, report, add friend, photos and
// the unavailable state. Every test asserts the request(s) sent, where the
// member ends up and the visible text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/moderation_appeals_screen.dart';
import 'package:verified_dating_app/features/matching/screens/match_notification_screen.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/profile/widgets/cinematic_profile.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/passed_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';

import '../../support/qa_api.dart';
import 'discover_qa_fixtures.dart';

const _love = ValueKey('qa.profile_detail.love_button');
const _message = ValueKey('qa.profile_detail.message_button');
const _back = ValueKey('qa.profile_detail.back_button');
const _report = ValueKey('qa.profile_detail.report_button');

final _anya = qaCandidate('anya', 'Anya');
final _bina = qaCandidate('bina', 'Bina', age: 31);

Future<void> _tap(WidgetTester tester, Key key, {int frames = 14}) async {
  await tester.ensureVisible(find.byKey(key).first);
  await tester.tap(find.byKey(key).first);
  await qaSettle(tester, frames: frames);
  qaDropImageErrors(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await qaSettle(tester, frames: 14);
}

/// The profile page pushed from a launcher (the pop results come back).
Future<List<Object?>> _openProfile(
  WidgetTester tester,
  QaApi api,
  DiscoveryProfile profile,
) => pumpQa(
  tester,
  api,
  ProfileDetailsScreen(profile: profile),
  launcher: true,
  flags: {'curated_daily_set_enabled': false},
  extra: qaDiscoverExtras(),
);

/// Discover's deck, the host every list below is reached from.
Future<void> _openDeck(WidgetTester tester, QaApi api) async {
  await pumpQa(
    tester,
    api,
    const HomeDiscoveryScreen(browseOnly: true),
    flags: {'curated_daily_set_enabled': false},
    extra: qaDiscoverExtras(),
  );
}

ProfileDetailsScreen _profilePage(WidgetTester tester) =>
    tester.widget<ProfileDetailsScreen>(find.byType(ProfileDetailsScreen));

/// Likes the top card on the deck, then opens "Liked profiles" (the profile
/// tab's button) over it.
Future<void> _openLikedList(WidgetTester tester, QaApi api) async {
  await _openDeck(tester, api);
  await _tap(tester, const ValueKey('qa.discovery.like_button'));
  Navigator.of(
    tester.element(find.byType(HomeDiscoveryScreen)),
  ).push(MaterialPageRoute<void>(builder: (_) => const LikedProfilesScreen()));
  await qaSettle(tester);
  expect(find.text('Liked Profiles (1)'), findsOneWidget);
}

/// Passes on the top card, then opens Discover's Passed list.
Future<void> _openPassedList(WidgetTester tester, QaApi api) async {
  await _openDeck(tester, api);
  await _tap(tester, const ValueKey('qa.discovery.pass_button'));
  await _tap(tester, const ValueKey('qa.discovery.passed_button'));
  expect(find.byType(PassedProfilesScreen), findsOneWidget);
}

void main() {
  qaSilenceNetworkImages();

  group('profile page controls', () {
    testWidgets('Back returns to the opener with no action '
        '[case:swipe.profile_details.back_icon_arrow_back_rounded.action] '
        '[case:swipe.profile_details.back_affordance]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya]);
      final results = await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, _back);

      expect(results, [ProfileDetailsAction.none]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(api.writes, isEmpty);
    });

    // Regression (2026-10-02): Love → "It's a match!" → Send Message opened
    // the chat and the profile page then popped the top route — the chat —
    // so the member landed back on the profile instead of in the chat.
    testWidgets('Love that makes a match → Send Message stays in the chat; '
        'the profile closes underneath '
        '[case:swipe.profile_details.profile_detail_love_button_love.action] '
        '[case:matching.match_notification.match_notification_send_message.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(swipe: {'match_id': 'match-anya'});
      final results = await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, _love);
      expect(find.byType(MatchNotificationScreen), findsOneWidget);

      await _tap(tester, const ValueKey('qa.match_notification.send_message'));

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'match-anya',
      );
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(results, [ProfileDetailsAction.love]);
      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
    });

    testWidgets('Love → match → Keep Swiping closes match and profile '
        '[case:swipe.profile_details.profile_detail_love_button_love.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(swipe: {'match_id': 'match-anya'});
      final results = await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, _love);
      await _tap(tester, const ValueKey('qa.match_notification.keep_swiping'));

      expect(find.byType(MatchNotificationScreen), findsNothing);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(results, [ProfileDetailsAction.love]);
    });

    testWidgets(
      'a failed Message is explained and nothing opens '
      '[case:swipe.profile_details.profile_detail_message_button_message.api_failure]',
      (tester) async {
        final api = qaDiscoverApi()..fail('POST /swipe');
        await _openProfile(tester, api, qaMember('anya', 'Anya'));
        await _tap(tester, _message);

        expect(find.byType(ChatScreen), findsNothing);
        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(
          qaSnackText(tester),
          'Unable to like right now. Please try again.',
        );
      },
    );

    testWidgets('Report sends the report; the confirmation offers Appeal '
        '[case:swipe.profile_details.report.action] '
        ''
        '[case:swipe.profile_details.submit_report_onsubmit.action] '
        '[case:swipe.profile_details.submit_report_onsubmit.api_contract] '
        '[case:swipe.profile_details.appeal.action]', (tester) async {
      final api = qaDiscoverApi()
        ..json('POST /safety/report', {
          'report': {'id': 'report-7'},
        });
      await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, _report);
      await tester.enterText(find.byType(TextField).last, 'Asked for money');
      await _tapText(tester, 'Submit report');

      expect(api.sent('POST', '/safety/report').single.body, {
        'reporter_user_id': 'me',
        'reported_user_id': 'anya',
        'reason': 'inappropriate',
        'description': 'Asked for money',
        'message_id': null,
      });
      expect(qaSnackText(tester), contains('Report submitted.'));

      await tester.tap(find.text('Appeal'));
      await qaSettle(tester);
      final appeal = tester.widget<ModerationAppealsScreen>(
        find.byType(ModerationAppealsScreen),
      );
      expect(appeal.initialReportId, 'report-7');
    });

    testWidgets('a failed report keeps the sheet open and says so '
        '[case:swipe.profile_details.report.api_failure] '
        '[case:swipe.profile_details.submit_report_onsubmit.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi()..fail('POST /safety/report', status: 500);
      await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, _report);
      await _tapText(tester, 'Submit report');

      expect(api.sent('POST', '/safety/report'), hasLength(1));
      expect(qaSnackText(tester), 'Failed to submit report. Please try again.');
      expect(find.text('Submit report'), findsOneWidget, reason: 'sheet open');
      expect(find.text('Report submitted.'), findsNothing);
    });

    testWidgets('Add friend sends a friend request for this member '
        '[case:swipe.profile_details.add_friend.action] '
        '', (tester) async {
      final api = qaDiscoverApi(deck: [_anya])
        ..json('POST /friends/me', {
          'friend': {'status': 'pending'},
        });
      await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, const ValueKey('qa.add_friend.anya'));

      expect(api.sent('POST', '/friends/me').single.body, {
        'friend_user_id': 'anya',
        'source': 'profile',
      });
      expect(qaSnackText(tester), 'Friend request sent to Anya.');
    });

    testWidgets('a failed friend request is explained '
        '[case:swipe.profile_details.add_friend.api_failure]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya])..offline('POST /friends/me');
      await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, const ValueKey('qa.add_friend.anya'));

      expect(api.sent('POST', '/friends/me'), hasLength(1));
      expect(
        qaSnackText(tester),
        "Can't connect right now. Check your internet connection and try again.",
      );
    });

    testWidgets('the main photo opens the full-screen gallery '
        '[case:swipe.profile_details.introducing_onopenphoto.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi();
      final anya = qaMember('anya', 'Anya');
      await _openProfile(
        tester,
        api,
        DiscoveryProfile(
          id: anya.id,
          name: anya.name,
          dateOfBirth: null,
          publicAge: 29,
          bio: anya.bio,
          additionalInfo: null,
          profession: anya.profession,
          education: null,
          instagramHandle: null,
          hobbies: const [],
          favoriteSongs: const [],
          extraCurriculars: const [],
          intentTags: const [],
          languageTags: const [],
          isVerified: true,
          photoUrls: const ['https://photos.test/anya-1.jpg'],
        ),
      );
      await _tap(tester, const ValueKey('qa.profile_detail.carousel'));

      final gallery = tester.widget<ProfileGalleryScreen>(
        find.byType(ProfileGalleryScreen),
      );
      expect(gallery.initialIndex, 0);
      expect(gallery.photos, ['https://photos.test/anya-1.jpg']);
    });

    testWidgets(
      'a photo in the strip opens the gallery on that photo '
      '[case:swipe.profile_details.name_photo_index_of_count_onopen.action]',
      (tester) async {
        final api = qaDiscoverApi();
        await _openProfile(
          tester,
          api,
          const DiscoveryProfile(
            id: 'anya',
            name: 'Anya',
            dateOfBirth: null,
            publicAge: 29,
            bio: 'Sketches strangers on trains.',
            additionalInfo: null,
            profession: 'Designer',
            education: null,
            instagramHandle: null,
            hobbies: [],
            favoriteSongs: [],
            extraCurriculars: [],
            intentTags: [],
            languageTags: [],
            isVerified: true,
            photoUrls: [
              'https://photos.test/anya-1.jpg',
              'https://photos.test/anya-2.jpg',
              'https://photos.test/anya-3.jpg',
            ],
          ),
        );
        await _tap(tester, const ValueKey('qa.profile_detail.thumbnail_2'));

        expect(
          tester
              .widget<ProfileGalleryScreen>(find.byType(ProfileGalleryScreen))
              .initialIndex,
          2,
        );
      },
    );

    testWidgets('an unavailable profile offers Retry, which reloads it '
        '[case:swipe.profile_details.profile_detail_retry_retry.action]', (tester) async {
      final api = qaDiscoverApi()..fail('GET /profile/anya', status: 404);
      await _openProfile(tester, api, qaMember('anya', 'Anya'));
      expect(
        find.text('This profile is unavailable right now.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.byKey(_love),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
        reason: 'Love and Message stay out of reach',
      );

      api.on(
        'GET /profile/anya',
        (_) => qaOk({
          'found': true,
          'profile': {'id': 'anya', 'name': 'Anya', 'age': 29},
        }),
      );
      await _tap(tester, const ValueKey('qa.profile_detail.retry'));

      expect(api.sent('GET', '/profile/anya'), hasLength(2));
      expect(find.text('This profile is unavailable right now.'), findsNothing);
    });

    testWidgets('Go back on an unavailable profile closes it '
        '[case:swipe.profile_details.profile_detail_go_back_back.action]', (tester) async {
      final api = qaDiscoverApi()..fail('GET /profile/anya', status: 404);
      final results = await _openProfile(tester, api, qaMember('anya', 'Anya'));
      await _tap(tester, const ValueKey('qa.profile_detail.go_back'));

      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(results, [null]);
    });
  });

  group('Liked profiles list', () {
    testWidgets('the chevron opens that member '
        '[case:swipe.liked_profiles.liked_profiles_open_x.action]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openLikedList(tester, api);
      await _tap(tester, const ValueKey('qa.liked_profiles.open.anya'));

      expect(_profilePage(tester).profile.id, 'anya');
    });

    testWidgets('Love from the liked list sends one like for that member '
        '(double tap safe) and closes the profile '
        '[case:discover.profile_entry_points.liked_list.love]', (tester) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openLikedList(tester, api);
      await _tap(tester, const ValueKey('qa.liked_profiles.open.anya'));
      final before = qaSwipes(api).length;

      await tester.tap(find.byKey(_love));
      await tester.tap(find.byKey(_love), warnIfMissed: false);
      await qaSettle(tester, frames: 14);

      expect(qaSwipes(api).skip(before), [qaSwipeBody('anya', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(find.byType(LikedProfilesScreen), findsOneWidget);
      expect(find.text('Liked Profiles (1)'), findsOneWidget);
    });

    testWidgets('Message from the liked list with a match opens the chat '
        '[case:discover.profile_entry_points.liked_list.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(
        deck: [_anya, _bina],
        matches: [qaMatchRow('match-anya', 'anya', 'Anya')],
      );
      await _openLikedList(tester, api);
      await _tap(tester, const ValueKey('qa.liked_profiles.open.anya'));
      final before = qaSwipes(api).length;
      await _tap(tester, _message);

      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'match-anya',
      );
      expect(qaSwipes(api).length, before, reason: 'no new like');
    });
  });

  group('Passed profiles list', () {
    testWidgets(
      'the chevron opens that member '
      '[case:swipe.passed_profiles.passed_profiles_open_x.action]',
      (tester) async {
        final api = qaDiscoverApi(deck: [_anya, _bina]);
        await _openPassedList(tester, api);
        await _tap(tester, const ValueKey('qa.passed_profiles.open.anya'));

        expect(_profilePage(tester).profile.id, 'anya');
      },
    );

    testWidgets('Love on a passed member likes them and they leave the list '
        '[case:discover.profile_entry_points.passed_list.love]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openPassedList(tester, api);
      await _tap(tester, const ValueKey('qa.passed_profiles.open.anya'));
      await _tap(tester, _love);

      expect(qaSwipes(api), [
        qaSwipeBody('anya', like: false),
        qaSwipeBody('anya', like: true),
      ]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('qa.passed_profiles.open.anya')),
        findsNothing,
      );
      expect(find.text('No passed profiles yet'), findsOneWidget);
    });

    testWidgets('Message on a passed member whose like makes the match opens '
        'the chat '
        '[case:discover.profile_entry_points.passed_list.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(deck: [_anya, _bina]);
      await _openPassedList(tester, api);
      await _tap(tester, const ValueKey('qa.passed_profiles.open.anya'));
      api.json('POST /swipe', {'match_id': 'match-anya'});
      await _tap(tester, _message);

      expect(qaSwipes(api).last, qaSwipeBody('anya', like: true));
      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'match-anya',
      );
    });
  });

  group('Liked you', () {
    final cara = qaCandidate(
      'cara',
      'Cara',
      likedAt: DateTime.now()
          .subtract(const Duration(hours: 2))
          .toUtc()
          .toIso8601String(),
    );

    Future<void> openLikedYou(WidgetTester tester, QaApi api) async {
      await pumpQa(
        tester,
        api,
        const LikedMeScreen(),
        flags: {'curated_daily_set_enabled': false},
        extra: qaDiscoverExtras(),
      );
    }

    testWidgets('Love on a liker likes back through the swipe API and the '
        'liker leaves the list '
        '[case:discover.profile_entry_points.liked_you.love] '
        '[case:discover.profile_entry_points.liked_you.own_rule] '
        '[case:swipe.liked_me.liked_me_open_x_open.action] '
        '', (
      tester,
    ) async {
      final api = qaDiscoverApi(likedMe: [cara]);
      await openLikedYou(tester, api);
      await _tap(tester, const ValueKey('qa.liked_me.open.cara'));
      expect(api.sent('POST', '/profile/views').single.body, {
        'viewer_user_id': 'me',
        'viewed_user_id': 'cara',
      });

      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('cara', like: true)]);
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(qaSnackText(tester), 'You liked Cara back');
      expect(find.byKey(const ValueKey('qa.liked_me.card.cara')), findsNothing);
    });

    testWidgets('Message on a liker likes back; the match screen leads to '
        'the chat '
        '[case:discover.profile_entry_points.liked_you.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(likedMe: [cara], swipe: {'match_id': 'm-cara'});
      await openLikedYou(tester, api);
      await _tap(tester, const ValueKey('qa.liked_me.open.cara'));
      await _tap(tester, _message);

      expect(qaSwipes(api), [qaSwipeBody('cara', like: true)]);
      expect(find.byType(MatchNotificationScreen), findsOneWidget);
      await _tap(tester, const ValueKey('qa.match_notification.send_message'));
      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId,
        'm-cara',
      );
    });

    testWidgets('a liker profile whose like back fails stays open '
        '[case:swipe.liked_me.liked_me_open_x_open.api_failure]', (
      tester,
    ) async {
      final api = qaDiscoverApi(likedMe: [cara])..fail('POST /swipe');
      await openLikedYou(tester, api);
      await _tap(tester, const ValueKey('qa.liked_me.open.cara'));
      await _tap(tester, _love);

      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
      expect(qaSnackText(tester), 'Something broke on our side.');
    });

    testWidgets('the web /likes page is Liked you: Love likes back there too '
        '[case:discover.profile_entry_points.web_likes.love]', (tester) async {
      final api = qaDiscoverApi(likedMe: [cara]);
      final likes = webDestinations.singleWhere((d) => d.path == '/likes');
      await pumpQa(
        tester,
        api,
        likes.build(),
        flags: {'curated_daily_set_enabled': false},
        extra: qaDiscoverExtras(),
      );
      await _tap(tester, const ValueKey('qa.liked_me.open.cara'));
      await _tap(tester, _love);

      expect(qaSwipes(api), [qaSwipeBody('cara', like: true)]);
      expect(find.byKey(const ValueKey('qa.liked_me.card.cara')), findsNothing);
    });

    testWidgets('the web /likes page: Message likes back and opens the match '
        '[case:discover.profile_entry_points.web_likes.message]', (
      tester,
    ) async {
      final api = qaDiscoverApi(likedMe: [cara], swipe: {'match_id': 'm-cara'});
      final likes = webDestinations.singleWhere((d) => d.path == '/likes');
      await pumpQa(
        tester,
        api,
        likes.build(),
        flags: {'curated_daily_set_enabled': false},
        extra: qaDiscoverExtras(),
      );
      await _tap(tester, const ValueKey('qa.liked_me.open.cara'));
      await _tap(tester, _message);

      expect(qaSwipes(api), [qaSwipeBody('cara', like: true)]);
      expect(find.byType(MatchNotificationScreen), findsOneWidget);
    });
  });
}
