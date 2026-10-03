// The shared member actions (Love, Message) in app/lib/features/swipe/
// profile_actions.dart, driven from another member's profile page against
// the recording fake BFF: the daily-limit message's "See plans", and every
// message the actions show, rendered in each shipped language.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';

import '../../support/qa_api.dart';
import 'discover_qa_fixtures.dart';
import 'qa_screen_checks.dart';

const _love = ValueKey('qa.profile_detail.love_button');
const _message = ValueKey('qa.profile_detail.message_button');

Future<void> _openProfile(
  WidgetTester tester,
  QaApi api, {
  Locale? locale,
}) async {
  await pumpQa(
    tester,
    api,
    ProfileDetailsScreen(profile: qaMember('anya', 'Anya')),
    launcher: true,
    locale: locale,
    flags: {'curated_daily_set_enabled': false},
    extra: qaDiscoverExtras(),
  );
  qaDropImageErrors(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await qaSettle(tester, frames: 14);
  qaDropImageErrors(tester);
}

void main() {
  qaSilenceNetworkImages();

  testWidgets('a Love refused by the daily limit explains it; See plans on '
      'the message opens the plans '
      '[case:swipe.profile_actions.see_plans.action]', (tester) async {
    final api = qaDiscoverApi()..on('POST /swipe', (_) => qaDailyLikeLimit());
    await _openProfile(tester, api);
    await _tap(tester, find.byKey(_love));

    expect(qaSwipes(api), [qaSwipeBody('anya', like: true)]);
    expect(qaSnackText(tester), contains("You've used today's 10 likes"));
    expect(
      find.byType(ProfileDetailsScreen),
      findsOneWidget,
      reason: 'nothing was saved, the profile stays',
    );

    await _tap(
      tester,
      find.descendant(
        of: find.byType(SnackBarAction),
        matching: find.text('See plans'),
      ),
    );

    expect(find.byType(SubscriptionScreen), findsOneWidget);
  });

  testWidgets('every message the member actions show is translated '
      '[case:swipe.profile_actions.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      final where = locale.toString();

      // Love that is saved.
      var api = qaDiscoverApi();
      await _openProfile(tester, api, locale: locale);
      await _tap(tester, find.byKey(_love));
      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)], reason: where);
      expect(
        find.text(l10n.discoverSuperLikeSent('Anya')),
        findsOneWidget,
        reason: where,
      );
      // 'open' is the test launcher's own button.
      qaExpectNoEnglishLeaks(tester, locale, allow: {'Anya', 'open'});
      await tester.pumpWidget(const SizedBox());

      // Message without a match: the like is sent and explained.
      api = qaDiscoverApi();
      await _openProfile(tester, api, locale: locale);
      await _tap(tester, find.byKey(_message));
      expect(qaSwipes(api), [qaSwipeBody('anya', like: true)], reason: where);
      expect(
        find.text(l10n.discoverMessageLikeSent('Anya')),
        findsOneWidget,
        reason: where,
      );
      // 'open' is the test launcher's own button.
      qaExpectNoEnglishLeaks(tester, locale, allow: {'Anya', 'open'});
      await tester.pumpWidget(const SizedBox());

      // The daily limit, with its See plans action.
      api = qaDiscoverApi()..on('POST /swipe', (_) => qaDailyLikeLimit());
      await _openProfile(tester, api, locale: locale);
      await _tap(tester, find.byKey(_love));
      expect(
        find.descendant(
          of: find.byType(SnackBarAction),
          matching: find.text(l10n.discoverSeePlans),
        ),
        findsOneWidget,
        reason: where,
      );
      if (locale.languageCode != 'en') {
        expect(
          qaSnackText(tester),
          isNot(contains("You've used today's")),
          reason: where,
        );
      }
      // 'open' is the test launcher's own button.
      qaExpectNoEnglishLeaks(tester, locale, allow: {'Anya', 'open'});
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
