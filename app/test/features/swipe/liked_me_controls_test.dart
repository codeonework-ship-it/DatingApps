// Liked you: Like back, Pass, Retry and pull to refresh against the
// recording fake BFF — the exact /swipe body, the list after the answer,
// the visible confirmation, and what the member reads when it fails.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/matching/screens/match_notification_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';

import '../../support/qa_api.dart';
import 'discover_qa_fixtures.dart';
import 'qa_screen_checks.dart';

final _ago = DateTime.now()
    .subtract(const Duration(hours: 2))
    .toUtc()
    .toIso8601String();
final _cara = qaCandidate('cara', 'Cara', likedAt: _ago);
final _devi = qaCandidate('devi', 'Devi', age: 33, likedAt: _ago);

Future<void> _open(WidgetTester tester, QaApi api) => pumpQa(
  tester,
  api,
  const LikedMeScreen(),
  flags: {'curated_daily_set_enabled': false},
  extra: qaDiscoverExtras(),
);

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await qaSettle(tester, frames: 12);
}

Finder _card(String id) => find.byKey(ValueKey('qa.liked_me.card.$id'));

void main() {
  qaSilenceNetworkImages();

  testWidgets('lists who liked the member with the count '
      '', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara, _devi]);
    await _open(tester, api);

    expect(api.sent('GET', '/discovery/me/liked-me').last.query, {
      'limit': 100,
    });
    expect(find.text('Liked you · 2'), findsOneWidget);
    expect(_card('cara'), findsOneWidget);
    expect(find.text('Liked you 2 hours ago'), findsNWidgets(2));
  });

  testWidgets('Like back sends a like; the liker leaves the list '
      '[case:swipe.liked_me.liked_me_like_back_x_likeback.action]', (
    tester,
  ) async {
    final api = qaDiscoverApi(likedMe: [_cara, _devi]);
    await _open(tester, api);
    await _tap(tester, const ValueKey('qa.liked_me.like_back.cara'));

    expect(qaSwipes(api), [qaSwipeBody('cara', like: true)]);
    expect(qaSnackText(tester), 'You liked Cara back');
    expect(_card('cara'), findsNothing);
    expect(find.text('Liked you · 1'), findsOneWidget);
  });

  testWidgets('a like back that makes the match opens the match screen and '
      'reloads the matches '
      '[case:swipe.liked_me.liked_me_like_back_x_likeback.action]', (
    tester,
  ) async {
    final api = qaDiscoverApi(likedMe: [_cara], swipe: {'match_id': 'm-cara'});
    await _open(tester, api);
    final matchLoads = api.sent('GET', '/matches/me').length;
    await _tap(tester, const ValueKey('qa.liked_me.like_back.cara'));

    expect(find.byType(MatchNotificationScreen), findsOneWidget);
    expect(find.text('You and Cara liked each other'), findsOneWidget);
    expect(api.sent('GET', '/matches/me').length, greaterThan(matchLoads));
  });

  testWidgets('the daily like limit is explained; See plans opens the plans '
      '[case:swipe.liked_me.liked_me_like_back_x_likeback.api_failure] '
      '[case:swipe.liked_me.see_plans.action]', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara])
      ..on('POST /swipe', (_) => qaDailyLikeLimit());
    await _open(tester, api);
    await _tap(tester, const ValueKey('qa.liked_me.like_back.cara'));

    expect(qaSnackText(tester), contains("You've used today's 10 likes"));
    expect(_card('cara'), findsOneWidget, reason: 'nothing was answered');

    await tester.tap(find.text('See plans'));
    await qaSettle(tester);
    expect(find.byType(SubscriptionScreen), findsOneWidget);
  });

  testWidgets('Pass sends a pass, says so privately, and removes the liker '
      '[case:swipe.liked_me.liked_me_pass_x_pass.action]', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara, _devi]);
    await _open(tester, api);
    await _tap(tester, const ValueKey('qa.liked_me.pass.devi'));

    expect(qaSwipes(api), [qaSwipeBody('devi', like: false)]);
    expect(qaSnackText(tester), 'Passed on Devi');
    expect(_card('devi'), findsNothing);
    expect(_card('cara'), findsOneWidget);
  });

  testWidgets('an offline Pass keeps the liker and says why '
      '[case:swipe.liked_me.liked_me_pass_x_pass.api_failure]', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara])..offline('POST /swipe');
    await _open(tester, api);
    await _tap(tester, const ValueKey('qa.liked_me.pass.cara'));

    expect(qaSwipes(api), hasLength(1));
    expect(_card('cara'), findsOneWidget);
    expect(
      qaSnackText(tester),
      "Can't connect right now. Check your internet connection and try again.",
    );
  });

  testWidgets('a failed load offers Retry, which loads the list '
      '[case:swipe.liked_me.liked_me_retry.action] '
      '', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara])
      ..fail('GET /discovery/me/liked-me', message: 'Likes are resting.');
    await _open(tester, api);
    expect(find.text('Could not load your likes'), findsOneWidget);
    expect(find.text('Likes are resting.'), findsOneWidget);

    api.json('GET /discovery/me/liked-me', {
      'profiles': [_cara],
      'count': 1,
    });
    await _tap(tester, const ValueKey('qa.liked_me.retry'));

    expect(api.sent('GET', '/discovery/me/liked-me').length, greaterThan(1));
    expect(_card('cara'), findsOneWidget);
  });

  testWidgets('a Retry that fails again keeps the explanation '
      '[case:swipe.liked_me.liked_me_retry.api_failure]', (tester) async {
    final api = qaDiscoverApi()..offline('GET /discovery/me/liked-me');
    await _open(tester, api);
    final before = api.sent('GET', '/discovery/me/liked-me').length;
    await _tap(tester, const ValueKey('qa.liked_me.retry'));

    expect(api.sent('GET', '/discovery/me/liked-me').length, before + 1);
    expect(find.text('Could not load your likes'), findsOneWidget);
    expect(
      find.text(
        "Can't connect right now. Check your internet connection and try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('pull to refresh reloads the list '
      '[case:swipe.liked_me.liked_me_refresh_refresh.action] '
      '', (tester) async {
    final api = qaDiscoverApi(likedMe: [_cara]);
    await _open(tester, api);
    final before = api.sent('GET', '/discovery/me/liked-me').length;
    api.json('GET /discovery/me/liked-me', {
      'profiles': [_cara, _devi],
      'count': 2,
    });

    await tester.fling(_card('cara'), const Offset(0, 400), 1000);
    await qaSettle(tester, frames: 20);

    expect(api.sent('GET', '/discovery/me/liked-me').length, before + 1);
    expect(_card('devi'), findsOneWidget);
    expect(find.text('Liked you · 2'), findsOneWidget);
  });

  // Regression (2026-10-02): a failed pull to refresh ended the spinner
  // with no word, leaving a possibly stale list.
  testWidgets('a failed pull to refresh keeps the list and says so '
      '[case:swipe.liked_me.liked_me_refresh_refresh.api_failure]', (
    tester,
  ) async {
    final api = qaDiscoverApi(likedMe: [_cara]);
    await _open(tester, api);
    api.fail('GET /discovery/me/liked-me', message: 'Likes are resting.');

    await tester.fling(_card('cara'), const Offset(0, 400), 1000);
    await qaSettle(tester, frames: 20);

    expect(_card('cara'), findsOneWidget);
    expect(qaSnackText(tester), 'Likes are resting.');
  });

  group('screen checks', () {
    Future<void> pumpLiked(
      WidgetTester tester, {
      Size size = const Size(430, 932),
      ThemeData? theme,
      Locale? locale,
      bool launcher = false,
    }) => pumpQa(
      tester,
      qaDiscoverApi(likedMe: [_cara, _devi]),
      theme == null
          ? const LikedMeScreen()
          : qaThemed(theme, const LikedMeScreen()),
      size: size,
      locale: locale,
      launcher: launcher,
      flags: {'curated_daily_set_enabled': false},
      extra: qaDiscoverExtras(),
    );

    testWidgets('the populated list meets the tap-target, label and contrast '
        'guidelines [case:swipe.liked_me.a11y_guidelines]', (tester) async {
      await pumpLiked(tester, launcher: true);
      expect(_card('cara'), findsOneWidget);
      await qaExpectA11y(tester);
    });

    testWidgets('pushed, it shows a back button that returns to the opener '
        '[case:swipe.liked_me.back_affordance]', (tester) async {
      await pumpLiked(tester, launcher: true);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await qaSettle(tester);

      expect(find.byType(LikedMeScreen), findsNothing);
      expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
    });

    testWidgets('lays out on phones and tablets in both themes '
        '[case:swipe.liked_me.layout_matrix]', (tester) async {
      await qaExpectLayout(
        tester,
        pump: (size, theme) => pumpLiked(tester, size: size, theme: theme),
        check: (where) {
          expect(_card('cara'), findsOneWidget, reason: where);
          expect(
            find.byKey(const ValueKey('qa.liked_me.like_back.devi')),
            findsOneWidget,
            reason: where,
          );
        },
      );
    });

    testWidgets('renders translated in every language with no English left '
        '[case:swipe.liked_me.l10n]', (tester) async {
      await qaExpectTranslated(
        tester,
        pump: (locale) => pumpLiked(tester, locale: locale),
        fixture: {'Cara', 'Devi', 'Designer', 'sketches strangers'},
        check: (l10n, where) {
          expect(
            find.text(l10n.discoverLikedMeTitleCount(2)),
            findsOneWidget,
            reason: where,
          );
          expect(
            find.text(l10n.discoverLikedMeIntro),
            findsOneWidget,
            reason: where,
          );
          expect(
            find.text(l10n.discoverLikeBack),
            findsNWidgets(2),
            reason: where,
          );
          expect(find.text(l10n.discoverPass), findsNWidgets(2), reason: where);
          expect(
            find.text(l10n.discoverLikedHoursAgo(2)),
            findsNWidgets(2),
            reason: where,
          );
        },
      );
    });
  });
}
