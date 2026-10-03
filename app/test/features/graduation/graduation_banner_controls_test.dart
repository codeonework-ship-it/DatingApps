// Control tests for the graduation banner at the top of a chat, against the
// recording fake BFF: every tap is checked for the exact request it sent and
// what the banner shows afterwards, including failures and recovery.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/graduation/screens/graduation_celebration_screen.dart';
import 'package:verified_dating_app/features/graduation/widgets/graduation_banner.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'graduation_qa_server.dart';

final en = lookupAppLocalizations(const Locale('en'));

const _banner = Scaffold(
  body: GraduationBanner(matchId: gradMatchId, partnerName: gradPartner),
);

Finder _key(String key) => find.byKey(ValueKey(key));

bool _enabled(WidgetTester tester, String key) {
  final widget = tester.widget(_key(key));
  return switch (widget) {
    ButtonStyleButton() => widget.onPressed != null,
    _ => throw StateError('$key is not a button'),
  };
}

void main() {
  group('Celebrate', () {
    testWidgets('Celebrate on a confirmed graduation opens the celebration '
        'with the recorded choice and sends nothing '
        '[case:graduation.graduation_banner.graduation_celebrate.action]', (
      tester,
    ) async {
      final server = GradServer(current: gradConfirmed());
      await pumpQa(tester, server.api, _banner);

      expect(find.text(en.graduationFoundEachOther), findsOneWidget);
      expect(find.text(en.graduationBodyConfirmed), findsOneWidget);
      await tester.tap(_key('qa.graduation.celebrate'));
      await qaSettle(tester);

      expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
      // Opened after the fact: the button just returns, the toggle shows
      // the recorded choice and friends were told.
      expect(find.text(en.graduationBackToConnect), findsOneWidget);
      expect(find.text(en.graduationFriendsHaveBeenTold), findsOneWidget);
      final share = tester.widget<SwitchListTile>(
        _key('qa.graduation.celebration.share'),
      );
      expect(share.value, isTrue);
      expect(share.onChanged, isNull);
      expect(server.api.writes, isEmpty);
    });
  });

  group('Confirm', () {
    testWidgets('Confirm opens the celebration that completes the decision; '
        'nothing is sent until the member confirms there '
        '[case:graduation.graduation_banner.graduation_confirm.action]', (
      tester,
    ) async {
      final server = GradServer(current: gradDecide());
      await pumpQa(tester, server.api, _banner);

      expect(
        find.text(en.graduationHeadlineDecide(gradPartner)),
        findsOneWidget,
      );
      expect(find.text(en.planQuotedNote(gradNote)), findsOneWidget);
      await tester.tap(_key('qa.graduation.confirm'));
      await qaSettle(tester);

      expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
      expect(find.text(en.graduationConfirmAndBack), findsOneWidget);
      expect(find.text(en.graduationTellFriendsBody), findsOneWidget);
      expect(server.api.writes, isEmpty);

      await tester.tap(_key('qa.graduation.celebration.done'));
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradDecisionPath']);
      expect(server.api.writes.single.body, {
        'decision': 'confirm',
        'share_with_friends': false,
      });
      // Back on the chat the banner celebrates.
      expect(find.byType(GraduationCelebrationScreen), findsNothing);
      expect(_key('qa.graduation.celebrate'), findsOneWidget);
      expect(_key('qa.graduation.confirm'), findsNothing);
    });
  });

  group('Not yet', () {
    testWidgets('Not yet sends the decline and the banner goes away '
        '[case:graduation.graduation_banner.graduation_decline.action]', (
      tester,
    ) async {
      final server = GradServer(current: gradDecide());
      await pumpQa(tester, server.api, _banner);
      final loadsBefore = server.api.sent('GET', gradSnapshotPath).length;

      await tester.tap(_key('qa.graduation.decline'));
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradDecisionPath']);
      expect(server.api.writes.single.body, {
        'decision': 'decline',
        'share_with_friends': false,
      });
      // The banner reloaded the snapshot and hides the declined proposal.
      expect(server.api.sent('GET', gradSnapshotPath).length, loadsBefore + 1);
      expect(_key('qa.graduation.banner.proposed'), findsNothing);
      expect(_key('qa.graduation.confirm'), findsNothing);
      expect(server.api.unhandled, isEmpty);
    });

    testWidgets('a failed Not yet shows a readable error, keeps the proposal '
        'and re-enables; the retry succeeds with one more request '
        '[case:graduation.graduation_banner.graduation_decline.api_failure]', (
      tester,
    ) async {
      final server = GradServer(current: gradDecide());
      await pumpQa(tester, server.api, _banner);
      // A 500 with no message of its own: the member sees the localized
      // fallback for this request.
      server.api.on(
        'POST $gradDecisionPath',
        (_) => const QaReply(
          500,
          <String, dynamic>{},
          delay: Duration(milliseconds: 300),
        ),
      );

      await tester.tap(_key('qa.graduation.decline'));
      await tester.pump(const Duration(milliseconds: 50));
      // Both choices are locked while the request is in flight.
      expect(_enabled(tester, 'qa.graduation.decline'), isFalse);
      expect(_enabled(tester, 'qa.graduation.confirm'), isFalse);
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradDecisionPath']);
      expect(
        tester.widget<Text>(_key('qa.graduation.banner_error')).data,
        en.graduationDeclineFailed,
      );
      // Nothing was lost: the proposal and its note are still there and
      // both choices are usable again.
      expect(
        find.text(en.graduationHeadlineDecide(gradPartner)),
        findsOneWidget,
      );
      expect(find.text(en.planQuotedNote(gradNote)), findsOneWidget);
      expect(_enabled(tester, 'qa.graduation.decline'), isTrue);
      expect(_enabled(tester, 'qa.graduation.confirm'), isTrue);

      server.install();
      await tester.tap(_key('qa.graduation.decline'));
      await qaSettle(tester);

      expect(server.api.writeLines, [
        'POST $gradDecisionPath',
        'POST $gradDecisionPath',
      ]);
      expect(server.api.writes.last.body['decision'], 'decline');
      expect(_key('qa.graduation.banner_error'), findsNothing);
      expect(_key('qa.graduation.banner.proposed'), findsNothing);
    });
  });

  group('Withdraw', () {
    testWidgets('Withdraw sends the withdrawal and the banner goes away '
        '[case:graduation.graduation_banner.graduation_withdraw.action]', (
      tester,
    ) async {
      final server = GradServer(current: gradWaiting());
      await pumpQa(tester, server.api, _banner);

      expect(
        find.text(en.graduationHeadlineWaiting(gradPartner)),
        findsOneWidget,
      );
      expect(find.text(en.graduationFriendsToldOnConfirm), findsOneWidget);
      await tester.tap(_key('qa.graduation.withdraw'));
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradWithdrawPath']);
      expect(server.api.writes.single.body, isEmpty);
      expect(
        find.text(en.graduationHeadlineWaiting(gradPartner)),
        findsNothing,
      );
      expect(_key('qa.graduation.withdraw'), findsNothing);
    });

    testWidgets('a Withdraw that cannot reach the server says so, keeps the '
        'proposal and re-enables; the retry withdraws '
        '[case:graduation.graduation_banner.graduation_withdraw.api_failure]', (
      tester,
    ) async {
      final server = GradServer(current: gradWaiting());
      await pumpQa(tester, server.api, _banner);
      server.api.offline('POST $gradWithdrawPath');

      await tester.tap(_key('qa.graduation.withdraw'));
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradWithdrawPath']);
      expect(
        tester.widget<Text>(_key('qa.graduation.banner_error')).data,
        en.networkOfflineTryAgain,
      );
      expect(
        find.text(en.graduationHeadlineWaiting(gradPartner)),
        findsOneWidget,
      );
      expect(_enabled(tester, 'qa.graduation.withdraw'), isTrue);

      // A server error with its own message shows that message.
      server.api.fail(
        'POST $gradWithdrawPath',
        message: 'This proposal was already answered.',
      );
      await tester.tap(_key('qa.graduation.withdraw'));
      await qaSettle(tester);
      expect(
        tester.widget<Text>(_key('qa.graduation.banner_error')).data,
        'This proposal was already answered.',
      );
      expect(_enabled(tester, 'qa.graduation.withdraw'), isTrue);

      server.install();
      await tester.tap(_key('qa.graduation.withdraw'));
      await qaSettle(tester);

      expect(server.api.writeLines, List.filled(3, 'POST $gradWithdrawPath'));
      expect(_key('qa.graduation.banner_error'), findsNothing);
      expect(
        find.text(en.graduationHeadlineWaiting(gradPartner)),
        findsNothing,
      );
    });
  });

  group('languages', () {
    // The partner's name and their own note are member data (the quoted
    // note is identical where a language uses the same quote marks).
    final allow = {gradPartner, gradNote, en.planQuotedNote(gradNote)};

    testWidgets('the banner renders in all 10 languages while deciding, '
        'waiting and once confirmed [case:graduation.graduation_banner.l10n]', (
      tester,
    ) async {
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer(current: gradDecide()).api,
        build: () => _banner,
        allow: allow,
        expected: [
          (l) => l.graduationHeadlineDecide(gradPartner),
          (l) => l.graduationBodyDecide,
          (l) => l.graduationNotYet,
          (l) => l.graduationConfirm,
        ],
      );
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer(current: gradWaiting()).api,
        build: () => _banner,
        allow: allow,
        expected: [
          (l) => l.graduationHeadlineWaiting(gradPartner),
          (l) => l.graduationBodyWaiting,
          (l) => l.graduationFriendsToldOnConfirm,
          (l) => l.graduationWithdraw,
        ],
      );
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer(current: gradConfirmed()).api,
        build: () => _banner,
        expected: [
          (l) => l.graduationFoundEachOther,
          (l) => l.graduationBodyConfirmed,
          (l) => l.graduationCelebrate,
        ],
      );
    });
  });
}
