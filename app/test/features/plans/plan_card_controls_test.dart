import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/plans/screens/plan_sharing_sheet.dart';
import 'package:verified_dating_app/features/plans/widgets/date_plan_card.dart';

import '../../support/qa_api.dart';
import 'plans_qa_world.dart';

// The pinned date-plan card in a conversation: every button is asserted by
// the request the BFF receives, what the card shows afterwards, and the
// failure paths (server message, no message, offline) with a retry.

final _en = qaL10n(const Locale('en'));

Future<void> _open(
  WidgetTester tester,
  PlansWorld world, {
  Locale? locale,
}) async {
  await pumpQa(
    tester,
    world.api,
    const Scaffold(
      body: DatePlanCard(matchId: matchId, partnerName: partnerName),
    ),
    locale: locale,
  );
  await settle(tester);
}

const _decision = '/matches/match-1/plans/plan-1/decision';
const _cancel = '/matches/match-1/plans/plan-1/cancel';
const _checkin = '/matches/match-1/plans/plan-1/checkin';
const _debrief = '/matches/match-1/plans/plan-1/debrief';

int _loads(PlansWorld world) =>
    world.api.sent('GET', '/matches/match-1/plans').length;

void main() {
  group('Accept / Decline', () {
    testWidgets('Accept sends the decision once, opens no sheet and shows the '
        'confirmed plan [case:plans.date_plan_card.plan_accept.action]', (
      tester,
    ) async {
      final world = PlansWorld(plan: planJson())
        ..commandDelay = const Duration(milliseconds: 300);
      await _open(tester, world);
      expect(find.text('Arjun proposed a date'), findsOneWidget);
      final loads = _loads(world);

      await tester.tap(byKey('qa.plan.accept'));
      await tester.pump();
      // Busy in the next frame: a second tap cannot send it twice.
      expect(isEnabled(tester, 'qa.plan.accept'), isFalse);
      expect(isEnabled(tester, 'qa.plan.decline'), isFalse);
      await tester.tap(byKey('qa.plan.accept'), warnIfMissed: false);
      await settle(tester);

      expect(world.api.writeLines, ['POST $_decision']);
      expect(world.api.sent('POST', _decision).single.body, {
        'expected_version': 4,
        'decision': 'accept',
        'group_ids': <String>[],
      });
      // The legacy group picker no longer opens: sharing is chosen later.
      expect(find.byType(BottomSheet), findsNothing);
      expect(_loads(world), loads + 1, reason: 'the card reloads');
      expect(find.text(_en.planHeadlineUpcoming), findsOneWidget);
      expect(find.text(_en.planStatusConfirmed), findsOneWidget);
      expect(byKey('qa.plan.cancel'), findsOneWidget);
      expect(byKey('qa.plan.accept'), findsNothing);
    });

    testWidgets(
      'a failed Accept explains (server message, fallback, offline), keeps '
      'the proposal and a retry confirms it '
      '[case:plans.date_plan_card.plan_accept.api_failure]',
      (tester) async {
        final world = PlansWorld(plan: planJson());
        await _open(tester, world);

        world.api.fail(
          'POST $_decision',
          status: 409,
          message: 'Arjun changed this plan.',
        );
        await tapKey(tester, 'qa.plan.accept');
        expect(tester.takeException(), isNull);
        expect(
          textOf(tester, 'qa.plan.card_error'),
          'Arjun changed this plan.',
        );
        expect(find.text('Arjun proposed a date'), findsOneWidget);
        expect(isEnabled(tester, 'qa.plan.accept'), isTrue);
        expect(world.api.sent('POST', _decision), hasLength(1));

        world.api.on('POST $_decision', (_) => const QaReply(500, ''));
        await tapKey(tester, 'qa.plan.accept');
        expect(textOf(tester, 'qa.plan.card_error'), _en.planAcceptFailed);

        world.api.offline('POST $_decision');
        await tapKey(tester, 'qa.plan.accept');
        expect(
          textOf(tester, 'qa.plan.card_error'),
          _en.networkOfflineTryAgain,
        );

        world.serve();
        await tapKey(tester, 'qa.plan.accept');
        expect(world.api.sent('POST', _decision), hasLength(4));
        expect(byKey('qa.plan.card_error'), findsNothing);
        expect(find.text(_en.planHeadlineUpcoming), findsOneWidget);
      },
    );

    testWidgets('Decline sends the decision and the card offers a new plan '
        '[case:plans.date_plan_card.plan_decline.action]', (tester) async {
      final world = PlansWorld(plan: planJson());
      await _open(tester, world);

      await tapKey(tester, 'qa.plan.decline');

      expect(world.api.writeLines, ['POST $_decision']);
      expect(world.api.sent('POST', _decision).single.body, {
        'expected_version': 4,
        'decision': 'decline',
        'group_ids': <String>[],
      });
      expect(find.text('Arjun proposed a date'), findsNothing);
      expect(find.text('Plan a date with Arjun'), findsOneWidget);
      expect(byKey('qa.plan.propose_cta'), findsOneWidget);
    });

    testWidgets('a failed Decline explains, keeps the proposal and retry works '
        '[case:plans.date_plan_card.plan_decline.api_failure]', (tester) async {
      final world = PlansWorld(plan: planJson());
      await _open(tester, world);
      world.api.on('POST $_decision', (_) => const QaReply(500, ''));

      await tapKey(tester, 'qa.plan.decline');
      expect(textOf(tester, 'qa.plan.card_error'), _en.planDeclineFailed);
      expect(find.text('Arjun proposed a date'), findsOneWidget);
      expect(isEnabled(tester, 'qa.plan.decline'), isTrue);
      expect(world.api.sent('POST', _decision), hasLength(1));

      world.serve();
      await tapKey(tester, 'qa.plan.decline');
      expect(world.api.sent('POST', _decision), hasLength(2));
      expect(byKey('qa.plan.propose_cta'), findsOneWidget);
    });
  });

  group('Cancel', () {
    PlansWorld upcoming() => PlansWorld(
      plan: planJson(
        status: 'accepted',
        nextAction: 'upcoming',
        viewerRole: 'proposer',
      ),
    );

    testWidgets('a plan whose partner has no name names "Dein Match" in German '
        '[case:l10n.fallback_names.plan_partner_name_german]', (tester) async {
      final de = qaL10n(const Locale('de'));
      final world = upcoming();
      world.plan!.remove('partner_name');
      await _open(tester, world, locale: const Locale('de'));
      await tapKey(tester, 'qa.plan.cancel');

      // The model holds no English stand-in; the dialog names the
      // partner with the German fallback.
      expect(
        find.text(de.planCancelDialogBody(de.matchesFallbackName)),
        findsOneWidget,
      );
      expect(find.textContaining('Your match'), findsNothing);
      await tapKey(tester, 'qa.plan.keep_it');
      await teardown(tester);
    });

    testWidgets(
      'Cancel plan asks first and says who will be told; nothing is sent '
      'yet [case:plans.date_plan_card.cancel_this_plan.action]',
      (tester) async {
        final world = upcoming();
        await _open(tester, world);

        await tapKey(tester, 'qa.plan.cancel');

        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(of: dialog, matching: find.text('Cancel this plan?')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(
              'Arjun and everyone you shared it with will be told.',
            ),
          ),
          findsOneWidget,
        );
        expect(byKey('qa.plan.keep_it'), findsOneWidget);
        expect(byKey('qa.plan.cancel_confirm'), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets('Keep it closes the question and keeps the plan, nothing sent '
        '[case:plans.date_plan_card.plan_keep_it.action]', (tester) async {
      final world = upcoming();
      await _open(tester, world);
      await tapKey(tester, 'qa.plan.cancel');

      await tapKey(tester, 'qa.plan.keep_it');

      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(find.text(_en.planHeadlineUpcoming), findsOneWidget);
      expect(isEnabled(tester, 'qa.plan.cancel'), isTrue);
    });

    testWidgets(
      'confirming cancels on the server and the card offers a new plan '
      '[case:plans.date_plan_card.plan_cancel.action] '
      '[case:plans.date_plan_card.plan_cancel_confirm.action]',
      (tester) async {
        final world = upcoming();
        await _open(tester, world);
        expect(find.text(_en.planFriendsKnowAccepted), findsOneWidget);
        await tapKey(tester, 'qa.plan.cancel');

        await tapKey(tester, 'qa.plan.cancel_confirm');

        expect(find.byType(AlertDialog), findsNothing);
        expect(world.api.writeLines, ['POST $_cancel']);
        expect(world.api.sent('POST', _cancel).single.body, isEmpty);
        expect(find.text(_en.planHeadlineUpcoming), findsNothing);
        expect(find.text('Plan a date with Arjun'), findsOneWidget);
      },
    );

    testWidgets('a failed cancel explains, keeps the plan and retry cancels '
        '[case:plans.date_plan_card.plan_cancel.api_failure]', (tester) async {
      final world = upcoming();
      await _open(tester, world);
      world.api.on('POST $_cancel', (_) => const QaReply(500, ''));

      await tapKey(tester, 'qa.plan.cancel');
      await tapKey(tester, 'qa.plan.cancel_confirm');
      expect(tester.takeException(), isNull);
      expect(textOf(tester, 'qa.plan.card_error'), _en.planCancelFailed);
      expect(find.text(_en.planHeadlineUpcoming), findsOneWidget);
      expect(isEnabled(tester, 'qa.plan.cancel'), isTrue);
      expect(world.api.sent('POST', _cancel), hasLength(1));

      world.api.fail('POST $_cancel', message: 'The plan already started.');
      await tapKey(tester, 'qa.plan.cancel');
      await tapKey(tester, 'qa.plan.cancel_confirm');
      expect(textOf(tester, 'qa.plan.card_error'), 'The plan already started.');

      world.serve();
      await tapKey(tester, 'qa.plan.cancel');
      await tapKey(tester, 'qa.plan.cancel_confirm');
      expect(world.api.sent('POST', _cancel), hasLength(3));
      expect(byKey('qa.plan.propose_cta'), findsOneWidget);
    });
  });

  group('Check-in', () {
    PlansWorld checkin() => PlansWorld(
      plan: planJson(status: 'accepted', nextAction: 'checkin'),
    );

    testWidgets("I'm safe records a safe check-in and the card says so "
        '[case:plans.date_plan_card.plan_safe.action]', (tester) async {
      final world = checkin();
      await _open(tester, world);
      expect(find.text(_en.planHeadlineCheckin), findsOneWidget);

      await tapKey(tester, 'qa.plan.safe');

      expect(world.api.writeLines, ['POST $_checkin']);
      expect(world.api.sent('POST', _checkin).single.body, {'status': 'safe'});
      expect(find.text(_en.planHeadlineCheckedInSafe), findsOneWidget);
      expect(byKey('qa.plan.safe'), findsNothing);
    });

    testWidgets(
      "a failed I'm safe explains, keeps both buttons and retry works "
      '[case:plans.date_plan_card.plan_safe.api_failure]',
      (tester) async {
        final world = checkin();
        await _open(tester, world);
        world.api.offline('POST $_checkin');

        await tapKey(tester, 'qa.plan.safe');
        expect(
          textOf(tester, 'qa.plan.card_error'),
          _en.networkOfflineTryAgain,
        );
        expect(find.text(_en.planHeadlineCheckin), findsOneWidget);
        expect(isEnabled(tester, 'qa.plan.safe'), isTrue);
        expect(isEnabled(tester, 'qa.plan.need_help'), isTrue);

        world.api.on('POST $_checkin', (_) => const QaReply(500, ''));
        await tapKey(tester, 'qa.plan.safe');
        expect(textOf(tester, 'qa.plan.card_error'), _en.planCheckinFailed);

        world.serve();
        await tapKey(tester, 'qa.plan.safe');
        expect(world.api.sent('POST', _checkin), hasLength(3));
        expect(find.text(_en.planHeadlineCheckedInSafe), findsOneWidget);
      },
    );

    testWidgets(
      'I need help records a help check-in and the card confirms friends '
      'are alerted [case:plans.date_plan_card.plan_need_help.action]',
      (tester) async {
        final world = checkin();
        await _open(tester, world);

        await tapKey(tester, 'qa.plan.need_help');

        expect(world.api.writeLines, ['POST $_checkin']);
        expect(world.api.sent('POST', _checkin).single.body, {
          'status': 'need_help',
        });
        expect(find.text(_en.planHeadlineFriendsAlerted), findsOneWidget);
      },
    );

    testWidgets(
      'a failed I need help explains with the server message, keeps the '
      'button and retry works '
      '[case:plans.date_plan_card.plan_need_help.api_failure]',
      (tester) async {
        final world = checkin();
        await _open(tester, world);
        world.api.fail('POST $_checkin', message: 'Check-in is closed.');

        await tapKey(tester, 'qa.plan.need_help');
        expect(textOf(tester, 'qa.plan.card_error'), 'Check-in is closed.');
        expect(isEnabled(tester, 'qa.plan.need_help'), isTrue);
        expect(world.api.sent('POST', _checkin), hasLength(1));

        world.serve();
        await tapKey(tester, 'qa.plan.need_help');
        expect(world.api.sent('POST', _checkin).last.body, {
          'status': 'need_help',
        });
        expect(find.text(_en.planHeadlineFriendsAlerted), findsOneWidget);
      },
    );
  });

  group('Propose, counter, second yes', () {
    testWidgets(
      'Propose opens the plan sheet; sending it shows the plan waiting for '
      'Arjun [case:plans.date_plan_card.plan_propose_cta.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _open(tester, world);
        expect(find.text('Plan a date with Arjun'), findsOneWidget);

        await tapKey(tester, 'qa.plan.propose_cta');

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(_en.planProposeHeadline), findsOneWidget);
        expect(find.text(_en.planProposeLead('Arjun')), findsOneWidget);
        expect(world.api.writes, isEmpty);

        await tapKey(tester, 'qa.plan.submit');
        expect(world.api.writeLines, ['POST /matches/match-1/plans']);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Waiting for Arjun'), findsOneWidget);
        await teardown(tester);
      },
    );

    testWidgets(
      'Suggest a change opens the counter sheet prefilled; sending posts a '
      'versioned counter [case:plans.date_plan_card.plan_counter.action]',
      (tester) async {
        final world = PlansWorld(
          plan: planJson(venueName: 'Third Wave', note: 'Window seat?'),
        );
        await _open(tester, world);

        await tapKey(tester, 'qa.plan.counter');

        expect(find.text(_en.planCounterHeadline), findsOneWidget);
        expect(textOf(tester, 'qa.plan.venue_name'), 'Third Wave');
        expect(textOf(tester, 'qa.plan.venue_area'), 'Indiranagar');
        expect(textOf(tester, 'qa.plan.note'), 'Window seat?');
        expect(find.text(_en.planSendSuggestion), findsOneWidget);

        await tapKey(tester, 'qa.plan.submit');
        final counter = world.api
            .sent('POST', '/matches/match-1/plans/plan-1/counter')
            .single;
        expect(counter.body['expected_version'], 4);
        expect(counter.body['venue_name'], 'Third Wave');
        expect(counter.body['note'], 'Window seat?');
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Waiting for Arjun'), findsOneWidget);
        await teardown(tester);
      },
    );

    testWidgets(
      'after a mutual second yes, Plan another hello opens a fresh plan '
      'sheet and sends a new plan '
      '[case:plans.date_plan_card.plan_another_hello.action]',
      (tester) async {
        final world = PlansWorld(
          canPropose: true,
          history: [
            planJson(
              status: 'completed',
              nextAction: 'none',
              mutualSecondYes: true,
            ),
          ],
        );
        await _open(tester, world);
        expect(find.text(_en.planSecondYesHeadline), findsOneWidget);
        expect(find.text(_en.planSecondYesCardBody), findsOneWidget);

        await tapKey(tester, 'qa.plan.another_hello');

        expect(find.text(_en.planProposeHeadline), findsOneWidget);
        expect(textOf(tester, 'qa.plan.note'), isEmpty);
        await tapKey(tester, 'qa.plan.submit');
        expect(world.api.writeLines, ['POST /matches/match-1/plans']);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Waiting for Arjun'), findsOneWidget);
        await teardown(tester);
      },
    );
  });

  testWidgets(
    'Choose who gets your updates opens contact sharing for this plan '
    '[case:plans.date_plan_card.plan_sharing.action]',
    (tester) async {
      final world = PlansWorld(
        plan: planJson(status: 'accepted', nextAction: 'upcoming'),
      );
      await _open(tester, world);

      await tapKey(tester, 'qa.plan.sharing');

      final sheet = tester.widget<PlanSharingSheet>(
        find.byType(PlanSharingSheet),
      );
      expect(sheet.plan.id, 'plan-1');
      expect(find.text(_en.planSharingTitle), findsOneWidget);
      expect(
        world.api.sent('GET', '/matches/match-1/plans/plan-1/sharing'),
        hasLength(1),
      );
      expect(byKey('qa.plan.contact.meera'), findsOneWidget);
      expect(world.api.writes, isEmpty);
    },
  );

  group('Debrief', () {
    PlansWorld debrief() => PlansWorld(
      plan: planJson(status: 'accepted', nextAction: 'debrief'),
    );

    testWidgets(
      'Ten-second debrief opens the private debrief, saves the answers and '
      'the card waits for Arjun; a safe date offers no report '
      '[case:plans.date_plan_card.plan_debrief.action]',
      (tester) async {
        final world = debrief();
        await _open(tester, world);
        expect(find.text(_en.planHeadlineDebrief), findsOneWidget);

        await tapKey(tester, 'qa.plan.debrief');
        expect(find.text('How was it with Arjun?'), findsOneWidget);

        await tapKey(tester, 'qa.debrief.happened.yes');
        await tapKey(tester, 'qa.debrief.again.yes');
        await tapKey(tester, 'qa.debrief.safe.yes');
        await tapKey(tester, 'qa.debrief.submit');

        expect(world.api.writeLines, ['POST $_debrief']);
        expect(world.api.sent('POST', _debrief).single.body, {
          'happened': true,
          'share_mutual_interest': false,
          'would_meet_again': true,
          'felt_safe': true,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text("Waiting for Arjun's debrief"), findsOneWidget);
        expect(world.api.sent('POST', '/safety/report'), isEmpty);
      },
    );

    testWidgets(
      'a failed debrief keeps the sheet and the answers, explains, and '
      'retry saves [case:plans.date_plan_card.plan_debrief.api_failure]',
      (tester) async {
        final world = debrief();
        await _open(tester, world);
        world.api.on('POST $_debrief', (_) => const QaReply(500, ''));

        await tapKey(tester, 'qa.plan.debrief');
        await tapKey(tester, 'qa.debrief.happened.no');
        await tapKey(tester, 'qa.debrief.submit');

        expect(textOf(tester, 'qa.debrief.error'), _en.debriefSaveFailed);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(
          tester.widget<ChoiceChip>(byKey('qa.debrief.happened.no')).selected,
          isTrue,
        );
        expect(isEnabled(tester, 'qa.debrief.submit'), isTrue);
        expect(find.text(_en.planHeadlineDebrief), findsOneWidget);

        world.serve();
        await tapKey(tester, 'qa.debrief.submit');
        expect(world.api.sent('POST', _debrief), hasLength(2));
        expect(world.api.sent('POST', _debrief).last.body, {
          'happened': false,
          'share_mutual_interest': false,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text("Waiting for Arjun's debrief"), findsOneWidget);
      },
    );
  });

  testWidgets('the plan card renders translated in every locale '
      '[case:plans.date_plan_card.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final world = PlansWorld(plan: planJson());
      await _open(tester, world, locale: locale);
      final l10n = qaL10n(locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(
        find.text(l10n.planHeadlineProposed('Arjun')),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.text(l10n.planAccept), findsOneWidget, reason: '$locale');
      expect(find.text(l10n.planDecline), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.planChooseUpdates),
        findsOneWidget,
        reason: '$locale',
      );
      await teardown(tester);
    }
  });
}
