// Control tests for GraduationCelebrationScreen against the recording fake
// BFF: the share toggle, "Confirm and go back" / "Back to Connect" (request,
// pop result, failure and retry), every opener acting on what the screen
// hands back, and the screen-quality checks (layout, a11y, back, languages).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/graduation/models/graduation.dart';
import 'package:verified_dating_app/features/graduation/screens/graduation_celebration_screen.dart';
import 'package:verified_dating_app/features/graduation/widgets/graduation_banner.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'graduation_qa_server.dart';

final en = lookupAppLocalizations(const Locale('en'));

Finder _key(String key) => find.byKey(ValueKey(key));

GraduationCelebrationScreen _pending() => const GraduationCelebrationScreen(
  matchId: gradMatchId,
  partnerName: gradPartner,
  pendingGraduationId: gradId,
);

GraduationCelebrationScreen _afterTheFact() =>
    const GraduationCelebrationScreen(
      matchId: gradMatchId,
      partnerName: gradPartner,
    );

const _banner = Scaffold(
  body: GraduationBanner(matchId: gradMatchId, partnerName: gradPartner),
);

SwitchListTile _share(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_key('qa.graduation.celebration.share'));

bool _doneEnabled(WidgetTester tester) =>
    tester
        .widget<ButtonStyleButton>(_key('qa.graduation.celebration.done'))
        .onPressed !=
    null;

void main() {
  group('Tell my friends', () {
    testWidgets(
      'while confirming, Tell my friends toggles the choice the '
      'confirmation sends '
      '[case:graduation.graduation_celebration.graduation_celebration_share.action]',
      (tester) async {
        final server = GradServer(current: gradDecide());
        await pumpQa(tester, server.api, _pending(), launcher: true);

        expect(_share(tester).value, isFalse);
        expect(find.text(en.graduationTellFriendsBody), findsOneWidget);
        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);
        expect(_share(tester).value, isTrue);
        // Toggling is local: nothing is sent until the member confirms.
        expect(server.api.writes, isEmpty);
        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);
        expect(_share(tester).value, isFalse);
        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);

        await tester.tap(_key('qa.graduation.celebration.done'));
        await qaSettle(tester);
        expect(server.api.writeLines, ['POST $gradDecisionPath']);
        expect(server.api.writes.single.body['share_with_friends'], isTrue);
      },
    );

    testWidgets(
      'after the fact, Tell my friends shows the recorded choice '
      'and cannot be changed '
      '[case:graduation.graduation_celebration.graduation_celebration_share.action]',
      (tester) async {
        final server = GradServer(
          current: gradRow(
            status: 'confirmed',
            nextAction: 'celebrate',
            shareWithFriends: true,
          ),
        );
        await pumpQa(tester, server.api, _afterTheFact());

        expect(_share(tester).value, isTrue);
        expect(_share(tester).onChanged, isNull);
        expect(find.text(en.graduationFriendsAreTold), findsOneWidget);
        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);
        expect(_share(tester).value, isTrue);
        expect(server.api.writes, isEmpty);
      },
    );
  });

  group('Back to Connect', () {
    testWidgets(
      'Confirm and go back sends the confirmation, reloads and pops '
      'the confirmed graduation to the opener '
      '[case:graduation.graduation_celebration.graduation_celebration_done.action]',
      (tester) async {
        final server = GradServer(current: gradDecide());
        final results = await pumpQa(
          tester,
          server.api,
          _pending(),
          launcher: true,
        );
        final loadsBefore = server.api.sent('GET', gradSnapshotPath).length;

        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);
        await tester.tap(_key('qa.graduation.celebration.done'));
        await qaSettle(tester);

        expect(server.api.writeLines, ['POST $gradDecisionPath']);
        expect(server.api.writes.single.body, {
          'decision': 'confirm',
          'share_with_friends': true,
        });
        expect(
          server.api.sent('GET', gradSnapshotPath).length,
          loadsBefore + 1,
        );
        expect(find.byType(GraduationCelebrationScreen), findsNothing);
        expect(results, hasLength(1));
        final popped = results.single! as Graduation;
        expect(popped.id, gradId);
        expect(popped.isConfirmed, isTrue);
        expect(popped.shareWithFriends, isTrue);
        expect(server.api.unhandled, isEmpty);
      },
    );

    testWidgets(
      'Back to Connect after the fact just returns, with nothing '
      'sent and no result '
      '[case:graduation.graduation_celebration.graduation_celebration_done.action]',
      (tester) async {
        final server = GradServer(current: gradConfirmed());
        final results = await pumpQa(
          tester,
          server.api,
          _afterTheFact(),
          launcher: true,
        );
        expect(find.text(en.graduationFriendsHaveBeenTold), findsOneWidget);

        await tester.tap(_key('qa.graduation.celebration.done'));
        await qaSettle(tester);

        expect(find.byType(GraduationCelebrationScreen), findsNothing);
        expect(results, [null]);
        expect(server.api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed confirmation shows a readable error, keeps the '
      'screen and the share choice, re-enables, and the retry confirms '
      'with exactly one more request '
      '[case:graduation.graduation_celebration.graduation_celebration_done.api_failure]',
      (tester) async {
        final server = GradServer(current: gradDecide());
        final results = await pumpQa(
          tester,
          server.api,
          _pending(),
          launcher: true,
        );
        server.api.on(
          'POST $gradDecisionPath',
          (_) => const QaReply(
            500,
            <String, dynamic>{},
            delay: Duration(milliseconds: 300),
          ),
        );

        await tester.tap(_key('qa.graduation.celebration.share'));
        await qaSettle(tester);
        await tester.tap(_key('qa.graduation.celebration.done'));
        await tester.pump(const Duration(milliseconds: 50));
        // Locked while in flight: no double submit, no toggling.
        expect(_doneEnabled(tester), isFalse);
        expect(_share(tester).onChanged, isNull);
        await qaSettle(tester);

        expect(server.api.writeLines, ['POST $gradDecisionPath']);
        expect(
          tester.widget<Text>(_key('qa.graduation.celebration_error')).data,
          en.graduationConfirmFailed,
        );
        expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
        expect(results, isEmpty);
        expect(_doneEnabled(tester), isTrue);
        expect(_share(tester).value, isTrue, reason: 'share choice kept');
        expect(_share(tester).onChanged, isNotNull);

        // Offline: the member is told they are offline.
        server.api.offline('POST $gradDecisionPath');
        await tester.tap(_key('qa.graduation.celebration.done'));
        await qaSettle(tester);
        expect(
          tester.widget<Text>(_key('qa.graduation.celebration_error')).data,
          en.networkOfflineTryAgain,
        );
        expect(_doneEnabled(tester), isTrue);

        server.install();
        await tester.tap(_key('qa.graduation.celebration.done'));
        await qaSettle(tester);

        expect(server.api.writeLines, List.filled(3, 'POST $gradDecisionPath'));
        expect(server.api.writes.last.body, {
          'decision': 'confirm',
          'share_with_friends': true,
        });
        expect(find.byType(GraduationCelebrationScreen), findsNothing);
        expect((results.single! as Graduation).isConfirmed, isTrue);
      },
    );
  });

  group('openers', () {
    testWidgets('the banner Confirm opener acts on the confirmed graduation '
        'even when the reload after it fails: the chat shows the celebration, '
        'not a stale Confirm '
        '[case:graduation.graduation_celebration.openers_handle_result]', (
      tester,
    ) async {
      final server = GradServer(current: gradDecide());
      await pumpQa(tester, server.api, _banner);
      await tester.tap(_key('qa.graduation.confirm'));
      await qaSettle(tester);
      expect(find.byType(GraduationCelebrationScreen), findsOneWidget);

      // The confirmation lands, but the snapshot reload right after fails.
      server.api.fail('GET $gradSnapshotPath');
      await tester.tap(_key('qa.graduation.celebration.done'));
      await qaSettle(tester);

      expect(server.api.writeLines, ['POST $gradDecisionPath']);
      expect(find.byType(GraduationCelebrationScreen), findsNothing);
      expect(_key('qa.graduation.confirm'), findsNothing);
      expect(_key('qa.graduation.decline'), findsNothing);
      expect(_key('qa.graduation.celebrate'), findsOneWidget);
      expect(find.text(en.graduationFoundEachOther), findsOneWidget);
      expect(_key('qa.graduation.banner_error'), findsNothing);

      // The celebration it opens shows the member's confirmed choice.
      await tester.tap(_key('qa.graduation.celebrate'));
      await qaSettle(tester);
      expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
      expect(find.text(en.graduationBackToConnect), findsOneWidget);
    });

    testWidgets('the banner Celebrate opener returns to the chat with the '
        'banner intact after Back to Connect '
        '[case:graduation.graduation_celebration.openers_handle_result]', (
      tester,
    ) async {
      final server = GradServer(current: gradConfirmed());
      await pumpQa(tester, server.api, _banner);
      await tester.tap(_key('qa.graduation.celebrate'));
      await qaSettle(tester);
      expect(find.byType(GraduationCelebrationScreen), findsOneWidget);

      await tester.tap(_key('qa.graduation.celebration.done'));
      await qaSettle(tester);

      expect(find.byType(GraduationCelebrationScreen), findsNothing);
      expect(_key('qa.graduation.celebrate'), findsOneWidget);
      expect(find.text(en.graduationBodyConfirmed), findsOneWidget);
      expect(server.api.writes, isEmpty);
    });
  });

  group('screen quality', () {
    Finder loaded() =>
        find.text(en.graduationFriendsHaveBeenTold, skipOffstage: false);

    testWidgets('the celebration lays out on phone and tablet in both themes '
        '[case:graduation.graduation_celebration.layout_matrix]', (
      tester,
    ) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: () => GradServer(current: gradConfirmed()).api,
        build: _afterTheFact,
        loaded: loaded,
      );
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: () => GradServer(current: gradDecide()).api,
        build: _pending,
        loaded: () =>
            find.text(en.graduationConfirmAndBack, skipOffstage: false),
      );
    });

    testWidgets('the celebration meets tap-target, label and contrast '
        'guidelines [case:graduation.graduation_celebration.a11y_guidelines]', (
      tester,
    ) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: () => GradServer(current: gradConfirmed()).api,
        build: _afterTheFact,
        loaded: loaded,
      );
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: () => GradServer(current: gradDecide()).api,
        build: _pending,
        loaded: () => find.text(en.graduationConfirmAndBack),
      );
    });

    testWidgets('Back on the celebration returns to the screen that opened it '
        '[case:graduation.graduation_celebration.back_affordance]', (
      tester,
    ) async {
      final server = GradServer(current: gradConfirmed());
      await qaExpectBackReturnsToOpener(
        tester,
        api: server.api,
        build: _afterTheFact,
        screen: find.byType(GraduationCelebrationScreen),
        loaded: loaded(),
      );
      expect(server.api.writes, isEmpty);
    });

    testWidgets('the celebration renders in all 10 languages, confirming and '
        'after the fact [case:graduation.graduation_celebration.l10n]', (
      tester,
    ) async {
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer(current: gradDecide()).api,
        build: _pending,
        allow: {gradPartner},
        expected: [
          (l) => l.graduationTitle,
          (l) => l.graduationFoundEachOther,
          (l) => l.graduationCelebrationBody(gradPartner),
          (l) => l.graduationTellFriends,
          (l) => l.graduationTellFriendsBody,
          (l) => l.graduationConfirmAndBack,
        ],
      );
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer(current: gradConfirmed()).api,
        build: _afterTheFact,
        allow: {gradPartner},
        expected: [
          (l) => l.graduationTitle,
          (l) => l.graduationFoundEachOther,
          (l) => l.graduationFriendsHaveBeenTold,
          (l) => l.graduationBackToConnect,
        ],
      );
    });
  });
}
