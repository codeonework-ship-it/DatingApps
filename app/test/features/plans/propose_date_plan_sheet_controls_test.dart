import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/propose_date_plan_sheet.dart';

import '../../support/qa_api.dart';
import '../swipe/qa_screen_checks.dart';
import 'plans_qa_world.dart';

// The propose / counter sheet and the accept-with-groups sheet, opened the
// way the app opens them (showProposeDatePlanSheet / showAcceptDatePlanSheet)
// from a launcher page. Every control is asserted by the request body the
// fake BFF receives, what the sheet shows, and what the sheet resolves to.

final _en = qaL10n(const Locale('en'));

const _propose = '/matches/match-1/plans';
const _counter = '/matches/match-1/plans/plan-1/counter';
const _connection = '/matches/match-1/connection';

Future<List<Object?>> _openSheet(
  WidgetTester tester,
  PlansWorld world, {
  DatePlan? counterTo,
  Locale? locale,
}) async {
  final results = <Object?>[];
  await pumpQa(
    tester,
    world.api,
    SheetLauncher(
      open: (context) => showProposeDatePlanSheet(
        context: context,
        matchId: matchId,
        partnerName: partnerName,
        counterTo: counterTo,
      ),
      results: results,
    ),
    locale: locale,
  );
  await tester.tap(byKey('qa.test.open_sheet'));
  await settle(tester);
  return results;
}

Map<String, dynamic> _lastBody(PlansWorld world, [String path = _propose]) =>
    world.api.sent('POST', path).last.body;

Duration _length(Map<String, dynamic> body) => DateTime.parse(
  body['window_end'] as String,
).difference(DateTime.parse(body['window_start'] as String));

DateTime _localStart(Map<String, dynamic> body) =>
    DateTime.parse(body['window_start'] as String).toLocal();

/// Tomorrow 18:00, the sheet's default start.
DateTime _defaultStart() {
  final t = DateTime.now().add(const Duration(days: 1));
  return DateTime(t.year, t.month, t.day, 18);
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(byKey(key));
  await tester.pumpAndSettle();
  await tester.enterText(byKey(key), text);
  await tester.pump();
}

int _counterValue(WidgetTester tester, String key) =>
    textOf(tester, key).runes.length;

void main() {
  group('opening and sending', () {
    testWidgets(
      'showProposeDatePlanSheet opens the sheet for the match, asks for '
      'shared times and resolves to the created plan '
      '[case:plans.propose_date_plan_sheet.showmodalbottomsheet_open.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        final results = await _openSheet(tester, world);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(_en.planProposeHeadline), findsOneWidget);
        expect(find.text(_en.planProposeLead('Arjun')), findsOneWidget);
        expect(find.text(_en.planSendButton), findsOneWidget);
        expect(world.api.sent('GET', _connection), hasLength(1));
        expect(world.api.writes, isEmpty);

        await tapKey(tester, 'qa.plan.submit');
        expect(find.byType(BottomSheet), findsNothing);
        expect(results, hasLength(1));
        final plan = results.single! as DatePlan;
        expect(plan.id, 'plan-1');
        expect(plan.venueCategory, 'coffee');
        await teardown(tester);
      },
    );

    testWidgets(
      'Send the plan posts every choice once, closes and hands back the plan '
      '[case:plans.propose_date_plan_sheet.plan_submit.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true)
          ..commandDelay = const Duration(milliseconds: 300);
        final results = await _openSheet(tester, world);

        await tapKey(tester, 'qa.plan.venue.meal');
        await _type(tester, 'qa.plan.venue_name', 'Toit');
        await _type(tester, 'qa.plan.venue_area', 'Indiranagar');
        await tapKey(tester, 'qa.plan.budget.modest');
        await tapKey(tester, 'qa.plan.atmosphere.quiet');
        await tapKey(tester, 'qa.plan.accessibility.seating');
        await _type(tester, 'qa.plan.note', 'Window seat?');

        await tester.ensureVisible(byKey('qa.plan.submit'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('qa.plan.submit'));
        await tester.pump();
        // Busy: the button says so and a second tap cannot send twice.
        expect(find.text(_en.planSending), findsOneWidget);
        expect(isEnabled(tester, 'qa.plan.submit'), isFalse);
        expect(isEnabled(tester, 'qa.plan.note'), isFalse);
        await tester.tap(byKey('qa.plan.submit'), warnIfMissed: false);
        await settle(tester);

        expect(world.api.writeLines, ['POST $_propose']);
        final start = _defaultStart();
        expect(_lastBody(world), {
          'budget_preference': 'modest',
          'atmosphere_preferences': ['quiet'],
          'accessibility_preferences': ['seating'],
          'window_start': start.toUtc().toIso8601String(),
          'window_end': start
              .add(const Duration(hours: 2))
              .toUtc()
              .toIso8601String(),
          'venue_category': 'meal',
          'venue_name': 'Toit',
          'venue_area': 'Indiranagar',
          'note': 'Window seat?',
          'group_ids': <String>[],
        });
        expect(find.byType(BottomSheet), findsNothing);
        final plan = results.single! as DatePlan;
        expect(plan.venueName, 'Toit');
        expect(plan.note, 'Window seat?');
        await teardown(tester);
      },
    );

    testWidgets(
      'a failed send explains (server message, fallback, offline), keeps '
      'every choice and a retry sends it '
      '[case:plans.propose_date_plan_sheet.plan_submit.api_failure]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        final results = await _openSheet(tester, world);
        await tapKey(tester, 'qa.plan.venue.walk');
        await _type(tester, 'qa.plan.venue_area', 'Cubbon Park');
        await tapKey(tester, 'qa.plan.atmosphere.outdoors');
        await _type(tester, 'qa.plan.note', 'Bring a hat');

        world.api.fail(
          'POST $_propose',
          status: 409,
          message: 'Shared availability has changed.',
        );
        await tapKey(tester, 'qa.plan.submit');
        expect(tester.takeException(), isNull);
        expect(
          textOf(tester, 'qa.plan.error'),
          'Shared availability has changed.',
        );

        world.api.on('POST $_propose', (_) => const QaReply(500, ''));
        await tapKey(tester, 'qa.plan.submit');
        expect(textOf(tester, 'qa.plan.error'), _en.planProposeFailed);

        world.api.offline('POST $_propose');
        await tapKey(tester, 'qa.plan.submit');
        expect(textOf(tester, 'qa.plan.error'), _en.networkOfflineTryAgain);

        // Nothing was lost: the sheet is open with every choice in place.
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(results, isEmpty);
        expect(
          tester.widget<ChoiceChip>(byKey('qa.plan.venue.walk')).selected,
          isTrue,
        );
        expect(
          tester
              .widget<FilterChip>(byKey('qa.plan.atmosphere.outdoors'))
              .selected,
          isTrue,
        );
        expect(textOf(tester, 'qa.plan.venue_area'), 'Cubbon Park');
        expect(textOf(tester, 'qa.plan.note'), 'Bring a hat');
        expect(isEnabled(tester, 'qa.plan.submit'), isTrue);
        expect(world.api.sent('POST', _propose), hasLength(3));

        world.serve();
        await tapKey(tester, 'qa.plan.submit');
        expect(world.api.sent('POST', _propose), hasLength(4));
        expect(_lastBody(world)['venue_category'], 'walk');
        expect(_lastBody(world)['venue_area'], 'Cubbon Park');
        expect(_lastBody(world)['note'], 'Bring a hat');
        expect(_lastBody(world)['atmosphere_preferences'], ['outdoors']);
        expect(find.byType(BottomSheet), findsNothing);
        expect((results.single! as DatePlan).venueCategory, 'walk');
        await teardown(tester);
      },
    );
  });

  group('choices', () {
    testWidgets('a venue chip selects that kind of date and it is what is sent '
        '[case:plans.propose_date_plan_sheet.plan_venue_x.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      await _openSheet(tester, world);
      expect(
        tester.widget<ChoiceChip>(byKey('qa.plan.venue.coffee')).selected,
        isTrue,
      );

      await tapKey(tester, 'qa.plan.venue.video_call');
      expect(
        tester.widget<ChoiceChip>(byKey('qa.plan.venue.video_call')).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(byKey('qa.plan.venue.coffee')).selected,
        isFalse,
      );

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['venue_category'], 'video_call');
      await teardown(tester);
    });

    testWidgets(
      'a duration chip changes the end time, the note under the time and '
      'the window sent '
      '[case:plans.propose_date_plan_sheet.plan_duration_x.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);
        expect(
          tester.widget<ChoiceChip>(byKey('qa.plan.duration.120')).selected,
          isTrue,
        );

        await tapKey(tester, 'qa.plan.duration.90');
        expect(
          tester.widget<ChoiceChip>(byKey('qa.plan.duration.90')).selected,
          isTrue,
        );
        expect(find.text('18:00–19:30'), findsOneWidget);
        expect(find.textContaining('Duration: 90 minutes'), findsOneWidget);

        await tapKey(tester, 'qa.plan.submit');
        expect(_length(_lastBody(world)), const Duration(minutes: 90));
        expect(_localStart(_lastBody(world)).hour, 18);
        await teardown(tester);
      },
    );

    testWidgets('a budget chip sets the budget that is sent '
        '[case:plans.propose_date_plan_sheet.plan_budget_x.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      await _openSheet(tester, world);

      await tapKey(tester, 'qa.plan.budget.treat');
      expect(
        tester.widget<ChoiceChip>(byKey('qa.plan.budget.treat')).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(byKey('qa.plan.budget.flexible')).selected,
        isFalse,
      );

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['budget_preference'], 'treat');
      await teardown(tester);
    });

    testWidgets(
      'atmosphere chips toggle on and off and the chosen ones are sent '
      '[case:plans.propose_date_plan_sheet.plan_atmosphere_x.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);

        await tapKey(tester, 'qa.plan.atmosphere.quiet');
        await tapKey(tester, 'qa.plan.atmosphere.indoors');
        await tapKey(tester, 'qa.plan.atmosphere.lively');
        await tapKey(tester, 'qa.plan.atmosphere.lively');
        expect(
          tester
              .widget<FilterChip>(byKey('qa.plan.atmosphere.lively'))
              .selected,
          isFalse,
        );
        expect(
          tester.widget<FilterChip>(byKey('qa.plan.atmosphere.quiet')).selected,
          isTrue,
        );

        await tapKey(tester, 'qa.plan.submit');
        expect((_lastBody(world)['atmosphere_preferences'] as List).toSet(), {
          'quiet',
          'indoors',
        });
        await teardown(tester);
      },
    );

    testWidgets('comfort checkboxes toggle and the checked needs are sent '
        '[case:plans.propose_date_plan_sheet.plan_accessibility_x.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      await _openSheet(tester, world);

      await tapKey(tester, 'qa.plan.accessibility.step_free');
      await tapKey(tester, 'qa.plan.accessibility.captions');
      await tapKey(tester, 'qa.plan.accessibility.captions');
      expect(
        tester
            .widget<CheckboxListTile>(byKey('qa.plan.accessibility.step_free'))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(byKey('qa.plan.accessibility.captions'))
            .value,
        isFalse,
      );

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['accessibility_preferences'], ['step_free']);
      await teardown(tester);
    });
  });

  group('shared times', () {
    final from = planStart(days: 2, hour: 10);
    final to = from.add(const Duration(minutes: 90));
    final window = {'start': iso(from), 'end': iso(to)};

    testWidgets(
      'a shared time sets the window, marks it chosen and is sent as the '
      'shared window '
      '[case:plans.propose_date_plan_sheet.plan_overlap_x.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true, overlap: [window]);
        await _openSheet(tester, world);
        expect(find.text(_en.planTimeSourceManual), findsOneWidget);

        await tapKey(tester, 'qa.plan.overlap.0');
        expect(
          find.descendant(
            of: byKey('qa.plan.overlap.0'),
            matching: find.byIcon(Icons.check_circle_outline),
          ),
          findsOneWidget,
        );
        expect(textOf(tester, 'qa.plan.time_source'), _en.planTimeSourceShared);
        expect(find.text('10:00–11:30'), findsWidgets);

        await tapKey(tester, 'qa.plan.submit');
        final body = _lastBody(world);
        expect(body['shared_window'], window);
        expect(body['window_start'], iso(from));
        expect(body['window_end'], iso(to));
        await teardown(tester);
      },
    );

    testWidgets(
      'Refresh shared times asks the server again and shows the new times '
      '[case:plans.propose_date_plan_sheet.plan_refresh_shared_times.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);
        expect(find.text(_en.planSharedTimesEmpty), findsOneWidget);
        expect(byKey('qa.plan.overlap.0'), findsNothing);
        final asked = world.api.sent('GET', _connection).length;

        world.overlap = [window];
        await tapKey(tester, 'qa.plan.refresh_shared_times');

        expect(world.api.sent('GET', _connection).length, asked + 1);
        expect(find.text(_en.planSharedTimesEmpty), findsNothing);
        expect(byKey('qa.plan.overlap.0'), findsOneWidget);
        expect(world.api.writes, isEmpty);
        await teardown(tester);
      },
    );

    testWidgets(
      'Set my availability opens the dating rhythm and, back in the sheet, '
      'shared times are fetched again '
      '[case:plans.propose_date_plan_sheet.plan_set_availability.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);
        await _type(tester, 'qa.plan.note', 'Kept while away');
        final asked = world.api.sent('GET', _connection).length;

        await tapKey(tester, 'qa.plan.set_availability');
        expect(find.byType(DatingRhythmScreen), findsOneWidget);
        expect(find.text(_en.todayRhythmTitle), findsOneWidget);
        expect(
          world.api.sent('GET', '/account/me/dating-preferences'),
          hasLength(1),
        );

        world.overlap = [window];
        await tester.tap(find.byType(BackButton));
        await settle(tester);

        expect(find.byType(DatingRhythmScreen), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(textOf(tester, 'qa.plan.note'), 'Kept while away');
        expect(world.api.sent('GET', _connection).length, greaterThan(asked));
        expect(byKey('qa.plan.overlap.0'), findsOneWidget);
        await teardown(tester);
      },
    );
  });

  group('day and time pickers', () {
    testWidgets(
      'Pick day opens the date picker; the chosen day keeps the time and is '
      'the day sent [case:plans.propose_date_plan_sheet.plan_pick_day.action] '
      '[case:plans.propose_date_plan_sheet.showdatepicker_open.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);
        final start = _defaultStart();
        // A different day in the month the picker opens on (never before
        // today, which the picker does not offer).
        final next = start.add(const Duration(days: 1));
        final target = next.month == start.month
            ? next
            : start.subtract(const Duration(days: 1));

        await tapKey(tester, 'qa.plan.pick_day');
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('${target.day}'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await settle(tester);

        expect(find.byType(DatePickerDialog), findsNothing);
        expect(
          find.descendant(
            of: byKey('qa.plan.pick_day'),
            matching: find.text(describeDatePlanDay(target, locale: 'en')),
          ),
          findsOneWidget,
        );
        expect(find.text('18:00–20:00'), findsOneWidget);

        await tapKey(tester, 'qa.plan.submit');
        final sent = _localStart(_lastBody(world));
        expect(
          [sent.year, sent.month, sent.day, sent.hour, sent.minute],
          [target.year, target.month, target.day, 18, 0],
        );
        expect(_length(_lastBody(world)), const Duration(hours: 2));
        await teardown(tester);
      },
    );

    testWidgets(
      'the time chip opens the time picker; the chosen time moves the whole '
      'window and is the time sent '
      '[case:plans.propose_date_plan_sheet.plan_pick_time.action] '
      '[case:plans.propose_date_plan_sheet.showtimepicker_open.action]',
      (tester) async {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world);
        expect(find.text('18:00–20:00'), findsOneWidget);

        await tapKey(tester, 'qa.plan.pick_time');
        expect(find.byType(TimePickerDialog), findsOneWidget);
        // Type the time instead of dragging the dial: 7:30 (PM is kept from
        // the 18:00 start).
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();
        final fields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), '7');
        await tester.enterText(fields.at(1), '30');
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await settle(tester);

        expect(find.byType(TimePickerDialog), findsNothing);
        expect(find.text('19:30–21:30'), findsOneWidget);

        await tapKey(tester, 'qa.plan.submit');
        final sent = _localStart(_lastBody(world));
        expect([sent.hour, sent.minute], [19, 30]);
        expect(sent.day, _defaultStart().day);
        expect(_length(_lastBody(world)), const Duration(hours: 2));
        await teardown(tester);
      },
    );
  });

  group('text fields', () {
    testWidgets('what is typed as the place is sent, trimmed '
        '[case:plans.propose_date_plan_sheet.plan_venue_name_input.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      await _openSheet(tester, world);

      await _type(tester, 'qa.plan.venue_name', '  Third Wave Coffee  ');
      expect(textOf(tester, 'qa.plan.venue_name'), '  Third Wave Coffee  ');

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['venue_name'], 'Third Wave Coffee');
      expect(world.plan!['venue_name'], 'Third Wave Coffee');
      await teardown(tester);
    });

    testWidgets('what is typed as the area is sent, trimmed '
        '[case:plans.propose_date_plan_sheet.plan_venue_area_input.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      await _openSheet(tester, world);

      await _type(tester, 'qa.plan.venue_area', ' Koramangala 5th Block ');

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['venue_area'], 'Koramangala 5th Block');
      await teardown(tester);
    });

    testWidgets('the note for them is sent with the plan, trimmed '
        '[case:plans.propose_date_plan_sheet.plan_note_input.action]', (
      tester,
    ) async {
      final world = PlansWorld(canPropose: true);
      final results = await _openSheet(tester, world);

      await _type(tester, 'qa.plan.note', 'Shall we try the rooftop?\n');

      await tapKey(tester, 'qa.plan.submit');
      expect(_lastBody(world)['note'], 'Shall we try the rooftop?');
      expect((results.single! as DatePlan).note, 'Shall we try the rooftop?');
      await teardown(tester);
    });

    for (final (key, field, max, caseId) in [
      ('qa.plan.venue_name', 'venue_name', 120, 'plan_venue_name_input'),
      ('qa.plan.venue_area', 'venue_area', 120, 'plan_venue_area_input'),
      ('qa.plan.note', 'note', 280, 'plan_note_input'),
    ]) {
      testWidgets(
        '$field: empty and whitespace-only are not sent, the server limit '
        'of $max characters is enforced (also for emoji), unicode and RTL '
        'are sent exactly '
        '[case:plans.propose_date_plan_sheet.$caseId.validation]',
        (tester) async {
          final world = PlansWorld(canPropose: true);
          await _openSheet(tester, world);

          // Empty: the optional field is simply left out.
          await tapKey(tester, 'qa.plan.submit');
          expect(_lastBody(world).containsKey(field), isFalse);
          await teardown(tester);

          // Whitespace only: not sent either.
          final world2 = PlansWorld(canPropose: true);
          await _openSheet(tester, world2);
          await _type(tester, key, '   \n  ');
          await tapKey(tester, 'qa.plan.submit');
          expect(_lastBody(world2).containsKey(field), isFalse);
          await teardown(tester);

          // Max length: one character over is cut at the limit and the
          // counter shows it.
          final world3 = PlansWorld(canPropose: true);
          await _openSheet(tester, world3);
          await _type(tester, key, 'a' * (max + 1));
          expect(textOf(tester, key), 'a' * max);
          expect(find.text('$max/$max'), findsOneWidget);
          // Emoji count as the server counts them (code points): a
          // skin-toned thumbs-up is two, so only max/2 of them fit.
          await _type(tester, key, '');
          await _type(tester, key, '👍🏽' * max);
          expect(_counterValue(tester, key), lessThanOrEqualTo(max));
          expect(textOf(tester, key), '👍🏽' * (max ~/ 2));
          expect(find.text('$max/$max'), findsOneWidget);
          await tapKey(tester, 'qa.plan.submit');
          expect(
            (_lastBody(world3)[field] as String).runes.length,
            lessThanOrEqualTo(max),
          );
          await teardown(tester);

          // Unicode, emoji and right-to-left text arrive exactly as typed.
          final world4 = PlansWorld(canPropose: true);
          await _openSheet(tester, world4);
          const mixed = 'مقهى الروضة ☕️ Café Zoë 👩🏽‍🤝‍👨🏻';
          await _type(tester, key, mixed);
          await tapKey(tester, 'qa.plan.submit');
          expect(_lastBody(world4)[field], mixed);
          await teardown(tester);
        },
      );
    }
  });

  group('counter proposal reload', () {
    DatePlan shown() => DatePlan.fromJson(planJson(note: 'Window seat?'));

    testWidgets(
      'after a conflict, Reload latest plan loads the newest version into '
      'the sheet and the counter is sent against it '
      '[case:plans.propose_date_plan_sheet.plan_reload_latest.action]',
      (tester) async {
        final world = PlansWorld(plan: planJson(note: 'Window seat?'));
        final results = await _openSheet(tester, world, counterTo: shown());
        expect(find.text(_en.planCounterHeadline), findsOneWidget);
        expect(byKey('qa.plan.reload_latest'), findsNothing);

        world.api.fail(
          'POST $_counter',
          status: 409,
          message: 'Arjun changed this plan.',
        );
        await _type(tester, 'qa.plan.note', 'My edit');
        await tapKey(tester, 'qa.plan.submit');
        expect(textOf(tester, 'qa.plan.error'), 'Arjun changed this plan.');
        expect(byKey('qa.plan.reload_latest'), findsOneWidget);

        // Arjun's newer version is on the server.
        world
          ..plan = planJson(
            note: 'Rooftop instead?',
            venueName: 'Toit',
            venueArea: 'Koramangala',
            lockVersion: 5,
          )
          ..serve();
        final loads = world.api.sent('GET', _propose).length;
        await tapKey(tester, 'qa.plan.reload_latest');

        expect(world.api.sent('GET', _propose).length, loads + 1);
        expect(byKey('qa.plan.error'), findsNothing);
        expect(byKey('qa.plan.reload_latest'), findsNothing);
        expect(textOf(tester, 'qa.plan.note'), 'Rooftop instead?');
        expect(textOf(tester, 'qa.plan.venue_name'), 'Toit');
        expect(textOf(tester, 'qa.plan.venue_area'), 'Koramangala');

        await tapKey(tester, 'qa.plan.submit');
        final body = _lastBody(world, _counter);
        expect(body['expected_version'], 5);
        expect(body['note'], 'Rooftop instead?');
        expect(find.byType(BottomSheet), findsNothing);
        expect(results.single, isA<DatePlan>());
        await teardown(tester);
      },
    );

    testWidgets(
      'a failed reload explains, keeps the edits, says when the plan is no '
      'longer open, and a retry loads it '
      '[case:plans.propose_date_plan_sheet.plan_reload_latest.api_failure]',
      (tester) async {
        final world = PlansWorld(plan: planJson(note: 'Window seat?'));
        await _openSheet(tester, world, counterTo: shown());
        world.api.fail('POST $_counter', status: 409, message: 'Changed.');
        await _type(tester, 'qa.plan.note', 'My edit');
        await tapKey(tester, 'qa.plan.submit');

        world.api.fail('GET $_propose', message: 'Plans are resting.');
        await tapKey(tester, 'qa.plan.reload_latest');
        expect(tester.takeException(), isNull);
        expect(textOf(tester, 'qa.plan.error'), 'Plans are resting.');
        expect(textOf(tester, 'qa.plan.note'), 'My edit');
        expect(isEnabled(tester, 'qa.plan.reload_latest'), isTrue);

        world.api.on('GET $_propose', (_) => const QaReply(500, ''));
        await tapKey(tester, 'qa.plan.reload_latest');
        expect(textOf(tester, 'qa.plan.error'), _en.plansLoadFailed);
        expect(textOf(tester, 'qa.plan.note'), 'My edit');

        // The plan was accepted meanwhile: nothing to counter any more.
        world
          ..serve()
          ..plan = planJson(status: 'accepted', nextAction: 'upcoming');
        await tapKey(tester, 'qa.plan.reload_latest');
        expect(textOf(tester, 'qa.plan.error'), _en.planChangedError);
        expect(textOf(tester, 'qa.plan.note'), 'My edit');

        // Retry once the newest open version is there.
        world.plan = planJson(note: 'Fresh', lockVersion: 6);
        await tapKey(tester, 'qa.plan.reload_latest');
        expect(byKey('qa.plan.error'), findsNothing);
        expect(textOf(tester, 'qa.plan.note'), 'Fresh');
        await tapKey(tester, 'qa.plan.submit');
        expect(_lastBody(world, _counter)['expected_version'], 6);
        await teardown(tester);
      },
    );
  });

  group('accept with groups', () {
    final groups = [
      const DatePlanShareGroup(id: 'g-crew', name: 'Weekend crew'),
      const DatePlanShareGroup(id: 'g-books', name: 'Book club'),
    ];

    Future<List<Object?>> openAccept(WidgetTester tester, QaApi api) async {
      final results = <Object?>[];
      await pumpQa(
        tester,
        api,
        SheetLauncher(
          open: (context) => showAcceptDatePlanSheet(
            context: context,
            plan: DatePlan.fromJson(planJson()),
            groups: groups,
          ),
          results: results,
        ),
      );
      await tester.tap(byKey('qa.test.open_sheet'));
      await settle(tester);
      return results;
    }

    FilterChip chip(WidgetTester tester, String label) => tester.widget(
      find.ancestor(of: find.text(label), matching: find.byType(FilterChip)),
    );

    testWidgets('group chips toggle which groups hear about the plan '
        '[case:plans.propose_date_plan_sheet.filterchip_onselected.action]', (
      tester,
    ) async {
      final results = await openAccept(tester, PlansWorld().api);
      expect(find.text(_en.planAcceptTitle), findsOneWidget);
      expect(chip(tester, 'Book club').selected, isFalse);

      await tester.tap(find.text('Book club'));
      await settle(tester);
      await tester.tap(find.text('Weekend crew'));
      await settle(tester);
      expect(chip(tester, 'Book club').selected, isTrue);
      expect(chip(tester, 'Weekend crew').selected, isTrue);

      await tester.tap(find.text('Weekend crew'));
      await settle(tester);
      expect(chip(tester, 'Weekend crew').selected, isFalse);

      await tapKey(tester, 'qa.plan.accept_confirm');
      expect(results.single, ['g-books']);
    });

    testWidgets(
      'Accept plan closes the sheet and hands back the chosen groups (none '
      'when nothing was picked) '
      '[case:plans.propose_date_plan_sheet.plan_accept_confirm.action]',
      (tester) async {
        final results = await openAccept(tester, PlansWorld().api);
        await tapKey(tester, 'qa.plan.accept_confirm');
        expect(find.byType(BottomSheet), findsNothing);
        expect(results.single, isEmpty);
        expect(results.single, isA<List<String>>());

        await tester.tap(byKey('qa.test.open_sheet'));
        await settle(tester);
        await tester.tap(find.text('Weekend crew'));
        await settle(tester);
        await tapKey(tester, 'qa.plan.accept_confirm');
        expect(find.byType(BottomSheet), findsNothing);
        expect(results.last, ['g-crew']);
      },
    );
  });

  testWidgets(
    'the propose sheet renders translated in every locale with no English '
    'left [case:plans.propose_date_plan_sheet.l10n]',
    (tester) async {
      // The launcher button behind the sheet is test scaffolding; German
      // really says "Drinks" too (app_de.arb planVenueDrinks).
      const fixture = {'Arjun', 'open sheet', 'Drinks'};
      List<String>? english;
      for (final locale in [
        const Locale('en'),
        ...qaLocales.where((l) => l != const Locale('en')),
      ]) {
        final world = PlansWorld(canPropose: true);
        await _openSheet(tester, world, locale: locale);
        final l10n = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.planProposeHeadline), findsOneWidget);
        expect(find.text(l10n.planProposeLead('Arjun')), findsOneWidget);
        expect(find.text(l10n.planSendButton), findsOneWidget);
        expect(find.text(l10n.planBudgetTitle), findsOneWidget);
        expect(find.text(l10n.planVenueCoffee), findsOneWidget);
        expect(find.text(l10n.planDurationChip(90)), findsOneWidget);
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
            reason: 'hard-coded strings in the propose sheet',
          );
        }
        await teardown(tester);
      }
    },
  );
}
