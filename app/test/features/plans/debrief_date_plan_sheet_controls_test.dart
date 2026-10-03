import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/debrief_date_plan_sheet.dart';
import 'package:verified_dating_app/features/plans/widgets/date_plan_card.dart';

import '../../support/qa_api.dart';
import '../swipe/qa_screen_checks.dart';
import 'plans_qa_world.dart';

// The private post-date debrief, opened the way the app opens it
// (showDebriefDatePlanSheet) from a launcher page, plus the "did not feel
// safe" follow-up the plan card offers after the sheet closes (report or
// not now, then the report sheet). Each control is asserted by the request
// the fake BFF receives and what the member sees.

final _en = qaL10n(const Locale('en'));

const _debrief = '/matches/match-1/plans/plan-1/debrief';
const _report = '/safety/report';

PlansWorld _world() => PlansWorld(
  plan: planJson(status: 'accepted', nextAction: 'debrief'),
);

Future<List<Object?>> _openSheet(
  WidgetTester tester,
  PlansWorld world, {
  Locale? locale,
  Map<String, bool> flags = const {},
}) async {
  final results = <Object?>[];
  final plan = DatePlan.fromJson(world.plan!);
  await pumpQa(
    tester,
    world.api,
    SheetLauncher(
      open: (context) => showDebriefDatePlanSheet(
        context: context,
        matchId: matchId,
        plan: plan,
      ),
      results: results,
    ),
    locale: locale,
    flags: flags,
  );
  await tester.tap(byKey('qa.test.open_sheet'));
  await settle(tester);
  return results;
}

/// The plan card in a chat, at the debrief step: the app's own entry to the
/// sheet and to the unsafe follow-up.
Future<void> _openCard(WidgetTester tester, PlansWorld world) async {
  await pumpQa(
    tester,
    world.api,
    const Scaffold(
      body: DatePlanCard(matchId: matchId, partnerName: partnerName),
    ),
  );
  await settle(tester);
}

/// Card → debrief → "No, I did not feel safe" → save: the unsafe question.
Future<void> _unsafeDebrief(WidgetTester tester, PlansWorld world) async {
  await _openCard(tester, world);
  await tapKey(tester, 'qa.plan.debrief');
  await tapKey(tester, 'qa.debrief.happened.yes');
  await tapKey(tester, 'qa.debrief.safe.no');
  await tapKey(tester, 'qa.debrief.submit');
}

bool _chip(WidgetTester tester, String key) =>
    tester.widget<ChoiceChip>(byKey(key)).selected;

Map<String, dynamic> _sent(PlansWorld world) =>
    world.api.sent('POST', _debrief).last.body;

Future<void> _type(WidgetTester tester, String text) async {
  await tester.ensureVisible(byKey('qa.debrief.note'));
  await tester.pumpAndSettle();
  await tester.enterText(byKey('qa.debrief.note'), text);
  await tester.pump();
}

void main() {
  group('the sheet', () {
    testWidgets(
      'showDebriefDatePlanSheet opens the private debrief for the plan and '
      'resolves to the updated plan '
      '[case:plans.debrief_date_plan_sheet.showmodalbottomsheet_open.action]',
      (tester) async {
        final world = _world();
        final results = await _openSheet(tester, world);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(_en.debriefTitle('Arjun')), findsOneWidget);
        expect(find.text(_en.debriefIntro), findsOneWidget);
        expect(find.text(_en.debriefHappened), findsOneWidget);
        // Follow-up questions wait for "it happened".
        expect(byKey('qa.debrief.again.yes'), findsNothing);
        expect(world.api.writes, isEmpty);

        await tapKey(tester, 'qa.debrief.happened.no');
        await tapKey(tester, 'qa.debrief.submit');
        expect(find.byType(BottomSheet), findsNothing);
        final plan = results.single! as DatePlan;
        expect(plan.id, 'plan-1');
        expect(plan.debrief?.happened, isFalse);
      },
    );

    testWidgets(
      'Did the date happen? Yes shows the follow-ups, No hides them and '
      'only "did not happen" is sent '
      '[case:plans.debrief_date_plan_sheet.debrief_happened.action]',
      (tester) async {
        final world = _world();
        await _openSheet(tester, world);

        await tapKey(tester, 'qa.debrief.happened.yes');
        expect(_chip(tester, 'qa.debrief.happened.yes'), isTrue);
        expect(find.text(_en.debriefMeetAgain), findsOneWidget);
        expect(find.text(_en.debriefFeltSafe), findsOneWidget);
        await tapKey(tester, 'qa.debrief.again.yes');

        await tapKey(tester, 'qa.debrief.happened.no');
        expect(_chip(tester, 'qa.debrief.happened.no'), isTrue);
        expect(_chip(tester, 'qa.debrief.happened.yes'), isFalse);
        expect(find.text(_en.debriefMeetAgain), findsNothing);
        expect(find.text(_en.debriefFeltSafe), findsNothing);

        await tapKey(tester, 'qa.debrief.submit');
        // The earlier "meet again" answer is not sent for a date that did
        // not happen.
        expect(_sent(world), {
          'happened': false,
          'share_mutual_interest': false,
        });
      },
    );

    testWidgets('Would you meet again? records the answer that is sent '
        '[case:plans.debrief_date_plan_sheet.debrief_again.action]', (
      tester,
    ) async {
      final world = _world();
      await _openSheet(tester, world);
      await tapKey(tester, 'qa.debrief.happened.yes');

      await tapKey(tester, 'qa.debrief.again.yes');
      expect(_chip(tester, 'qa.debrief.again.yes'), isTrue);
      await tapKey(tester, 'qa.debrief.again.no');
      expect(_chip(tester, 'qa.debrief.again.no'), isTrue);
      expect(_chip(tester, 'qa.debrief.again.yes'), isFalse);
      // "Share a second yes" only follows a yes.
      expect(byKey('qa.debrief.second_yes'), findsNothing);

      await tapKey(tester, 'qa.debrief.submit');
      expect(_sent(world), {
        'happened': true,
        'share_mutual_interest': false,
        'would_meet_again': false,
      });
    });

    testWidgets('Did you feel safe? records the answer that is sent '
        '[case:plans.debrief_date_plan_sheet.debrief_safe.action]', (
      tester,
    ) async {
      final world = _world();
      final results = await _openSheet(tester, world);
      await tapKey(tester, 'qa.debrief.happened.yes');

      await tapKey(tester, 'qa.debrief.safe.yes');
      await tapKey(tester, 'qa.debrief.safe.no');
      expect(_chip(tester, 'qa.debrief.safe.no'), isTrue);
      expect(_chip(tester, 'qa.debrief.safe.yes'), isFalse);

      await tapKey(tester, 'qa.debrief.submit');
      expect(_sent(world), {
        'happened': true,
        'share_mutual_interest': false,
        'felt_safe': false,
      });
      expect((results.single! as DatePlan).debrief?.feltSafe, isFalse);
    });

    testWidgets(
      'Share a second yes appears after a yes to meeting again and sends the '
      'mutual-interest choice '
      '[case:plans.debrief_date_plan_sheet.debrief_second_yes.action]',
      (tester) async {
        final world = _world();
        await _openSheet(
          tester,
          world,
          flags: const {'intentional_dating_enabled': true},
        );
        await tapKey(tester, 'qa.debrief.happened.yes');
        expect(byKey('qa.debrief.second_yes'), findsNothing);
        await tapKey(tester, 'qa.debrief.again.yes');
        expect(find.text(_en.planSecondYesTitle), findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(byKey('qa.debrief.second_yes')).value,
          isFalse,
        );

        await tapKey(tester, 'qa.debrief.second_yes');
        expect(
          tester.widget<SwitchListTile>(byKey('qa.debrief.second_yes')).value,
          isTrue,
        );
        await tapKey(tester, 'qa.debrief.safe.yes');
        await tapKey(tester, 'qa.debrief.submit');
        expect(_sent(world), {
          'happened': true,
          'share_mutual_interest': true,
          'would_meet_again': true,
          'felt_safe': true,
        });
      },
    );

    testWidgets(
      'with intentional dating off there is no second-yes switch and none is '
      'shared',
      (tester) async {
        final world = _world();
        await _openSheet(
          tester,
          world,
          flags: const {'intentional_dating_enabled': false},
        );
        await tapKey(tester, 'qa.debrief.happened.yes');
        await tapKey(tester, 'qa.debrief.again.yes');
        expect(byKey('qa.debrief.second_yes'), findsNothing);
        await tapKey(tester, 'qa.debrief.submit');
        expect(_sent(world)['share_mutual_interest'], isFalse);
      },
    );

    testWidgets('the note is sent with the debrief, trimmed '
        '[case:plans.debrief_date_plan_sheet.debrief_note_input.action]', (
      tester,
    ) async {
      final world = _world();
      await _openSheet(tester, world);
      await tapKey(tester, 'qa.debrief.happened.yes');

      await _type(tester, '  Lovely evening, a bit loud.  ');
      expect(
        textOf(tester, 'qa.debrief.note'),
        '  Lovely evening, a bit loud.  ',
      );

      await tapKey(tester, 'qa.debrief.submit');
      expect(_sent(world)['note'], 'Lovely evening, a bit loud.');
    });

    testWidgets(
      'note: empty and whitespace-only are not sent, the 280 limit is '
      'enforced (also for emoji), unicode and RTL are sent exactly '
      '[case:plans.debrief_date_plan_sheet.debrief_note_input.validation]',
      (tester) async {
        final world = _world();
        await _openSheet(tester, world);
        await tapKey(tester, 'qa.debrief.happened.no');

        // Empty.
        await tapKey(tester, 'qa.debrief.submit');
        expect(_sent(world).containsKey('note'), isFalse);

        // Whitespace only.
        final world2 = _world();
        await _openSheet(tester, world2);
        await tapKey(tester, 'qa.debrief.happened.no');
        await _type(tester, '  \n ');
        await tapKey(tester, 'qa.debrief.submit');
        expect(_sent(world2).containsKey('note'), isFalse);

        // One over the limit is cut and the counter shows the limit; emoji
        // count as code points, like the server counts them.
        final world3 = _world();
        await _openSheet(tester, world3);
        await tapKey(tester, 'qa.debrief.happened.no');
        await _type(tester, 'b' * 281);
        expect(textOf(tester, 'qa.debrief.note'), 'b' * 280);
        expect(find.text('280/280'), findsOneWidget);
        await _type(tester, '');
        await _type(tester, '🇮🇳' * 280);
        expect(textOf(tester, 'qa.debrief.note'), '🇮🇳' * 140);
        await tapKey(tester, 'qa.debrief.submit');
        expect((_sent(world3)['note'] as String).runes.length, 280);

        // Unicode and right-to-left text arrive exactly.
        final world4 = _world();
        await _openSheet(tester, world4);
        await tapKey(tester, 'qa.debrief.happened.no');
        const mixed = 'كان لطيفاً 😊 très bien, Zoë';
        await _type(tester, mixed);
        await tapKey(tester, 'qa.debrief.submit');
        expect(_sent(world4)['note'], mixed);
      },
    );

    testWidgets(
      'Save debrief asks whether the date happened first, then sends every '
      'answer once and closes '
      '[case:plans.debrief_date_plan_sheet.debrief_submit.action]',
      (tester) async {
        final world = _world()
          ..commandDelay = const Duration(milliseconds: 300);
        final results = await _openSheet(tester, world);

        await tapKey(tester, 'qa.debrief.submit');
        expect(textOf(tester, 'qa.debrief.error'), _en.debriefMissingHappened);
        expect(world.api.writes, isEmpty);
        expect(find.byType(BottomSheet), findsOneWidget);

        await tapKey(tester, 'qa.debrief.happened.yes');
        await tapKey(tester, 'qa.debrief.again.yes');
        await tapKey(tester, 'qa.debrief.safe.yes');
        await _type(tester, 'Great chat');
        await tester.ensureVisible(byKey('qa.debrief.submit'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('qa.debrief.submit'));
        await tester.pump();
        expect(isEnabled(tester, 'qa.debrief.submit'), isFalse);
        await tester.tap(byKey('qa.debrief.submit'), warnIfMissed: false);
        await settle(tester);

        expect(world.api.writeLines, ['POST $_debrief']);
        expect(_sent(world), {
          'happened': true,
          'share_mutual_interest': false,
          'would_meet_again': true,
          'felt_safe': true,
          'note': 'Great chat',
        });
        expect(find.byType(BottomSheet), findsNothing);
        final plan = results.single! as DatePlan;
        expect(plan.debrief?.wouldMeetAgain, isTrue);
        expect(plan.debrief?.feltSafe, isTrue);
      },
    );

    testWidgets(
      'a failed save explains (server message, fallback, offline), keeps '
      'the answers and the note, and a retry saves '
      '[case:plans.debrief_date_plan_sheet.debrief_submit.api_failure]',
      (tester) async {
        final world = _world();
        final results = await _openSheet(tester, world);
        await tapKey(tester, 'qa.debrief.happened.yes');
        await tapKey(tester, 'qa.debrief.again.no');
        await tapKey(tester, 'qa.debrief.safe.yes');
        await _type(tester, 'Kept note');

        world.api.fail('POST $_debrief', status: 409, message: 'Too late.');
        await tapKey(tester, 'qa.debrief.submit');
        expect(tester.takeException(), isNull);
        expect(textOf(tester, 'qa.debrief.error'), 'Too late.');

        world.api.on('POST $_debrief', (_) => const QaReply(500, ''));
        await tapKey(tester, 'qa.debrief.submit');
        expect(textOf(tester, 'qa.debrief.error'), _en.debriefSaveFailed);

        world.api.offline('POST $_debrief');
        await tapKey(tester, 'qa.debrief.submit');
        expect(textOf(tester, 'qa.debrief.error'), _en.networkOfflineTryAgain);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(results, isEmpty);
        expect(_chip(tester, 'qa.debrief.happened.yes'), isTrue);
        expect(_chip(tester, 'qa.debrief.again.no'), isTrue);
        expect(_chip(tester, 'qa.debrief.safe.yes'), isTrue);
        expect(textOf(tester, 'qa.debrief.note'), 'Kept note');
        expect(isEnabled(tester, 'qa.debrief.submit'), isTrue);

        world.serve();
        await tapKey(tester, 'qa.debrief.submit');
        expect(world.api.sent('POST', _debrief), hasLength(4));
        expect(_sent(world), {
          'happened': true,
          'share_mutual_interest': false,
          'would_meet_again': false,
          'felt_safe': true,
          'note': 'Kept note',
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(results.single, isA<DatePlan>());
      },
    );
  });

  group('after an unsafe date', () {
    testWidgets(
      'answering "did not feel safe" asks whether to report, naming the '
      'match '
      // ignore: lines_longer_than_80_chars
      '[case:plans.debrief_date_plan_sheet.sorry_that_did_not_feel_safe.action]',
      (tester) async {
        final world = _world();
        await _unsafeDebrief(tester, world);

        expect(_sent(world)['felt_safe'], isFalse);
        expect(find.byType(BottomSheet), findsNothing);
        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(_en.debriefUnsafeTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(_en.debriefUnsafeBody('Arjun')),
          ),
          findsOneWidget,
        );
        expect(world.api.sent('POST', _report), isEmpty);
      },
    );

    testWidgets(
      'Not now closes the question; no report sheet, nothing reported '
      '[case:plans.debrief_date_plan_sheet.debrief_not_now.action]',
      (tester) async {
        final world = _world();
        await _unsafeDebrief(tester, world);

        await tapKey(tester, 'qa.debrief.not_now');

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text(_en.reportSubmit), findsNothing);
        expect(world.api.sent('POST', _report), isEmpty);
        expect(find.text("Waiting for Arjun's debrief"), findsOneWidget);
      },
    );

    testWidgets(
      'Report opens the report sheet; nothing is sent until it is submitted '
      '[case:plans.debrief_date_plan_sheet.debrief_report.action]',
      (tester) async {
        final world = _world();
        await _unsafeDebrief(tester, world);

        await tapKey(tester, 'qa.debrief.report');

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(_en.reportSheetTitle), findsOneWidget);
        expect(find.text(_en.reportSubmit), findsOneWidget);
        expect(world.api.sent('POST', _report), isEmpty);
      },
    );

    testWidgets(
      'Submit report reports the match with the reason and description and '
      'closes '
      '[case:plans.debrief_date_plan_sheet.submit_report_onsubmit.action]',
      (tester) async {
        final world = _world();
        await _unsafeDebrief(tester, world);
        await tapKey(tester, 'qa.debrief.report');

        await tester.enterText(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
          'He would not let me leave.',
        );
        await tester.tap(find.text(_en.reportSubmit));
        await settle(tester);

        expect(world.api.sent('POST', _report).single.body, {
          'reporter_user_id': 'me',
          'reported_user_id': 'arjun',
          'reason': 'inappropriate',
          'description': 'He would not let me leave.',
          'message_id': null,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text(_en.reportSubmit), findsNothing);
      },
    );

    testWidgets(
      'a failed report says so, keeps the sheet and the description, and a '
      'retry reports '
      // ignore: lines_longer_than_80_chars
      '[case:plans.debrief_date_plan_sheet.submit_report_onsubmit.api_failure]',
      (tester) async {
        final world = _world();
        await _unsafeDebrief(tester, world);
        await tapKey(tester, 'qa.debrief.report');
        final description = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        );
        await tester.enterText(description, 'Felt pressured.');

        world.api.fail('POST $_report');
        await tester.tap(find.text(_en.reportSubmit));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(qaSnackText(tester), _en.reportSubmitFailed);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(
          tester.widget<TextField>(description).controller!.text,
          'Felt pressured.',
        );

        world.api.offline('POST $_report');
        await tester.tap(find.text(_en.reportSubmit));
        await settle(tester);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(world.api.sent('POST', _report), hasLength(2));

        world.serve();
        await tester.tap(find.text(_en.reportSubmit));
        await settle(tester);
        expect(world.api.sent('POST', _report), hasLength(3));
        expect(
          world.api.sent('POST', _report).last.body['description'],
          'Felt pressured.',
        );
        expect(find.byType(BottomSheet), findsNothing);
      },
    );
  });

  testWidgets(
    'the debrief renders translated in every locale with no English left '
    '[case:plans.debrief_date_plan_sheet.l10n]',
    (tester) async {
      const fixture = {'Arjun', 'open sheet'};
      List<String>? english;
      for (final locale in [
        const Locale('en'),
        ...qaLocales.where((l) => l != const Locale('en')),
      ]) {
        final world = _world();
        await _openSheet(
          tester,
          world,
          locale: locale,
          flags: const {'intentional_dating_enabled': true},
        );
        await tapKey(tester, 'qa.debrief.happened.yes');
        await tapKey(tester, 'qa.debrief.again.yes');
        final l10n = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.debriefTitle('Arjun')), findsOneWidget);
        expect(find.text(l10n.debriefHappened), findsOneWidget);
        expect(find.text(l10n.debriefMeetAgain), findsOneWidget);
        expect(find.text(l10n.debriefFeltSafe), findsOneWidget);
        expect(find.text(l10n.planSecondYesTitle), findsOneWidget);
        expect(find.text(l10n.debriefSave), findsOneWidget);
        if (locale.languageCode != 'en') {
          qaExpectNoEnglishLeaks(tester, locale, allow: fixture);
        }
        final strings = qaVisibleStrings(tester);
        if (locale == const Locale('en')) {
          english = strings;
        } else if (locale == const Locale('de')) {
          expect(
            qaUntranslated(english!, strings, fixture: fixture),
            isEmpty,
            reason: 'hard-coded strings in the debrief sheet',
          );
        }
        await teardown(tester);
      }
    },
  );
}
