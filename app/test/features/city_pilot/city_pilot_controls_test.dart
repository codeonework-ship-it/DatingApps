import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/city_pilot/city_pilot_screen.dart';

import '../../support/qa_api.dart';

// City pilot controls: every test performs the real gesture and asserts the
// request the server receives, what the member sees afterwards and — for
// every command — what happens when the server refuses or the device is
// offline. The pilot is gated on the server (`city_pilot_enabled`): with the
// flag off the BFF still answers GET /city-pilot but reports the pilot as
// disabled, so the screen shows it paused and only leaving/cancelling stays
// reachable.

final _en = qaL10n(const Locale('en'));

Map<String, dynamic> _event(
  String id,
  String title, {
  String registration = 'none',
  bool canRegister = false,
  bool canFeedback = false,
  String status = 'published',
}) => {
  'id': id,
  'title': title,
  'summary': 'A relaxed hour with other pilot members.',
  'starts_at': '2026-10-10T10:00:00Z',
  'ends_at': '2026-10-10T11:00:00Z',
  'venue': 'Blue Door Café',
  'host': 'Asha from Connect',
  'accessibility': 'Step-free entrance',
  'safety_contact': 'Onsite host Ravi',
  'status': status,
  'registration': registration,
  'can_register': canRegister,
  'can_feedback': canFeedback,
  'feedback': null,
};

/// A stateful city-pilot BFF. Commands change the state like the server does
/// and the screen reloads GET /city-pilot after each one.
class _World {
  _World({
    this.membership = 'joined',
    this.canJoin = false,
    bool enabled = true,
    String status = 'experiences',
  }) : pilot = {
         'id': 'pilot-pune',
         'city': 'Pune',
         'country': 'India',
         'status': status,
         'enabled': enabled,
         'closes_at': '2027-01-01T12:00:00Z',
       } {
    api
      ..on(
        'GET /city-pilot',
        (_) => qaOk({
          'success': true,
          'pilot': pilot,
          'membership': membership,
          'can_join': canJoin,
          'experiences': membership == 'joined'
              ? events.values.toList()
              : <dynamic>[],
        }),
      )
      ..on('POST /city-pilot/membership', (_) {
        membership = 'joined';
        canJoin = false;
        return qaOk({'success': true});
      })
      ..on('DELETE /city-pilot/membership', (_) {
        membership = 'withdrawn';
        return qaOk({'success': true});
      })
      ..on('POST /city-pilot/events/*/registration', (c) {
        final event = events[c.path.split('/')[3]]!;
        event['registration'] = 'registered';
        event['can_register'] = false;
        return qaOk({'success': true});
      })
      ..on('DELETE /city-pilot/events/*/registration', (c) {
        final event = events[c.path.split('/')[3]]!;
        event['registration'] = 'cancelled';
        event['can_register'] = true;
        return qaOk({'success': true});
      })
      ..on('POST /city-pilot/events/*/feedback', (c) {
        final event = events[c.path.split('/')[3]]!;
        event['feedback'] = c.body;
        event['can_feedback'] = false;
        return qaOk({'success': true});
      });
  }

  final api = QaApi();
  final Map<String, dynamic> pilot;
  String membership;
  bool canJoin;
  final events = <String, Map<String, dynamic>>{
    'ev-open': _event('ev-open', 'Sunday coffee walk', canRegister: true),
    'ev-booked': _event(
      'ev-booked',
      'Board game evening',
      registration: 'registered',
    ),
    'ev-past': _event('ev-past', 'Picnic in the park', canFeedback: true),
  };

  int get loads => api.sent('GET', '/city-pilot').length;
}

Finder _key(String key) => find.byKey(ValueKey(key));

/// Lets a command finish and the reload it triggers reach the fake server
/// (Dio dispatches on a zero-length timer that pumpAndSettle alone skips).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pumpAndSettle();
    await tester.pump();
  }
}

Future<void> _open(WidgetTester tester, _World world, {Locale? locale}) async {
  await pumpQa(
    tester,
    world.api,
    const CityPilotScreen(),
    size: const Size(500, 3600),
    locale: locale,
  );
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _tapKey(WidgetTester tester, String key) =>
    _tap(tester, _key(key));

VoidCallback? _onPressed(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(_key(key)).onPressed;

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

ChoiceChip _chip(WidgetTester tester, String key) =>
    tester.widget<ChoiceChip>(_key(key));

void main() {
  group('joining', () {
    testWidgets(
      'the consent box arms Join; Join sends the pilot and consent version '
      'and shows me as part of the pilot '
      '[case:city_pilot.city_pilot.city_pilot_consent.action] '
      '[case:city_pilot.city_pilot.city_pilot_join.action]',
      (tester) async {
        final world = _World(membership: 'none', canJoin: true);
        await _open(tester, world);
        expect(find.text(_en.cityPilotPanelTitleOpen('Pune')), findsOneWidget);
        expect(_onPressed(tester, 'qa.city_pilot.join'), isNull);

        await _tapKey(tester, 'qa.city_pilot.consent');
        expect(
          tester.widget<CheckboxListTile>(_key('qa.city_pilot.consent')).value,
          isTrue,
        );
        expect(_onPressed(tester, 'qa.city_pilot.join'), isNotNull);
        // Unticking disarms Join again.
        await _tapKey(tester, 'qa.city_pilot.consent');
        expect(_onPressed(tester, 'qa.city_pilot.join'), isNull);
        expect(world.api.writes, isEmpty);

        await _tapKey(tester, 'qa.city_pilot.consent');
        final loads = world.loads;
        await _tapKey(tester, 'qa.city_pilot.join');

        expect(world.api.writeLines, ['POST /city-pilot/membership']);
        expect(world.api.writes.single.body, {
          'pilot_id': 'pilot-pune',
          'consent_version': 'city-pilot-v1',
        });
        expect(world.loads, loads + 1, reason: 'reloaded after joining');
        expect(find.text(_en.cityPilotJoinedNotice), findsOneWidget);
        expect(
          find.text(_en.cityPilotPanelTitleJoined('Pune')),
          findsOneWidget,
        );
        expect(find.text(_en.cityPilotExperiencesHeading), findsOneWidget);
        expect(_key('qa.city_pilot.consent'), findsNothing);
        expect(_key('qa.city_pilot.leave'), findsOneWidget);
      },
    );

    testWidgets(
      'a refused Join explains, keeps my consent, is disabled while saving '
      'and retries once [case:city_pilot.city_pilot.city_pilot_join.api_failure]',
      (tester) async {
        final world = _World(membership: 'none', canJoin: true);
        world.api.fail(
          'POST /city-pilot/membership',
          status: 403,
          message: 'A completed dating profile in the pilot city is required',
        );
        await _open(tester, world);
        await _tapKey(tester, 'qa.city_pilot.consent');
        await _tapKey(tester, 'qa.city_pilot.join');

        expect(
          find.text('A completed dating profile in the pilot city is required'),
          findsOneWidget,
        );
        expect(find.text(_en.cityPilotPanelTitleOpen('Pune')), findsOneWidget);
        expect(find.text(_en.cityPilotJoinedNotice), findsNothing);
        expect(
          tester.widget<CheckboxListTile>(_key('qa.city_pilot.consent')).value,
          isTrue,
          reason: 'consent is kept for the retry',
        );
        expect(_onPressed(tester, 'qa.city_pilot.join'), isNotNull);
        expect(world.api.sent('POST', '/city-pilot/membership'), hasLength(1));

        world.api.offline('POST /city-pilot/membership');
        await _tapKey(tester, 'qa.city_pilot.join');
        expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
        expect(world.api.sent('POST', '/city-pilot/membership'), hasLength(2));

        // A slow save disables Join; a second tap sends nothing.
        world.api.on('POST /city-pilot/membership', (_) {
          world.membership = 'joined';
          world.canJoin = false;
          return const QaReply(200, {
            'success': true,
          }, delay: Duration(milliseconds: 400));
        });
        await tester.ensureVisible(_key('qa.city_pilot.join'));
        await tester.tap(_key('qa.city_pilot.join'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(_onPressed(tester, 'qa.city_pilot.join'), isNull);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        await tester.tap(_key('qa.city_pilot.join'), warnIfMissed: false);
        await _settle(tester);
        expect(world.api.sent('POST', '/city-pilot/membership'), hasLength(3));
        expect(find.text(_en.networkOfflineTryAgain), findsNothing);
        expect(
          find.text(_en.cityPilotPanelTitleJoined('Pune')),
          findsOneWidget,
        );
      },
    );
  });

  group('leaving', () {
    testWidgets('Leave pilot asks first and spells out what leaving does '
        '[case:city_pilot.city_pilot.leave_the_city_pilot.action]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.leave');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_inDialog(_en.cityPilotLeaveTitle), findsOneWidget);
      expect(_inDialog(_en.cityPilotLeaveBody), findsOneWidget);
      expect(_inDialog(_en.cityPilotStay), findsOneWidget);
      expect(_inDialog(_en.cityPilotLeave), findsOneWidget);
      expect(world.api.writes, isEmpty);
    });

    testWidgets('Stay in pilot closes the question and keeps me in '
        '[case:city_pilot.city_pilot.city_pilot_leave_stay.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      await _tapKey(tester, 'qa.city_pilot.leave');
      await _tapKey(tester, 'qa.city_pilot.leave_stay');
      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(world.loads, loads);
      expect(find.text(_en.cityPilotPanelTitleJoined('Pune')), findsOneWidget);
      expect(_onPressed(tester, 'qa.city_pilot.leave'), isNotNull);
    });

    testWidgets('confirming Leave pilot withdraws me on the server and says so '
        '[case:city_pilot.city_pilot.city_pilot_leave_confirm.action] '
        '[case:city_pilot.city_pilot.city_pilot_leave.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      await _tapKey(tester, 'qa.city_pilot.leave');
      await _tapKey(tester, 'qa.city_pilot.leave_confirm');

      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writeLines, ['DELETE /city-pilot/membership']);
      expect(world.api.writes.single.body, {'pilot_id': 'pilot-pune'});
      expect(world.loads, loads + 1);
      expect(find.text(_en.cityPilotLeftNotice), findsOneWidget);
      expect(find.text(_en.cityPilotWithdrawn), findsOneWidget);
      expect(find.text(_en.cityPilotExperiencesHeading), findsNothing);
      expect(_key('qa.city_pilot.leave'), findsNothing);
    });

    testWidgets('a failed Leave keeps me in, explains, and retry works '
        '[case:city_pilot.city_pilot.city_pilot_leave.api_failure]', (
      tester,
    ) async {
      final world = _World();
      world.api.fail(
        'DELETE /city-pilot/membership',
        status: 503,
        message: 'Could not save participation. Refresh before retrying',
      );
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.leave');
      await _tapKey(tester, 'qa.city_pilot.leave_confirm');

      expect(
        find.text('Could not save participation. Refresh before retrying'),
        findsOneWidget,
      );
      expect(find.text(_en.cityPilotPanelTitleJoined('Pune')), findsOneWidget);
      expect(find.text(_en.cityPilotLeftNotice), findsNothing);
      expect(_onPressed(tester, 'qa.city_pilot.leave'), isNotNull);
      expect(world.api.sent('DELETE', '/city-pilot/membership'), hasLength(1));

      world.api.on('DELETE /city-pilot/membership', (_) {
        world.membership = 'withdrawn';
        return qaOk({'success': true});
      });
      await _tapKey(tester, 'qa.city_pilot.leave');
      await _tapKey(tester, 'qa.city_pilot.leave_confirm');
      expect(world.api.sent('DELETE', '/city-pilot/membership'), hasLength(2));
      expect(find.text(_en.cityPilotWithdrawn), findsOneWidget);
      expect(
        find.text('Could not save participation. Refresh before retrying'),
        findsNothing,
      );
    });
  });

  group('booking an experience', () {
    testWidgets(
      'Reserve a free place shows the event’s safety terms before booking '
      '[case:city_pilot.city_pilot.join_title.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await _tapKey(tester, 'qa.city_pilot.reserve.ev-open');
        expect(
          _inDialog(_en.cityPilotJoinEventTitle('Sunday coffee walk')),
          findsOneWidget,
        );
        expect(
          _inDialog(
            _en.cityPilotBookingTerms(
              'Asha from Connect',
              'Onsite host Ravi',
              'Step-free entrance',
            ),
          ),
          findsOneWidget,
        );
        expect(_key('qa.city_pilot.booking_not_now'), findsOneWidget);
        expect(_key('qa.city_pilot.booking_accept'), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets('Not now closes the terms without booking '
        '[case:city_pilot.city_pilot.city_pilot_booking_not_now.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.reserve.ev-open');
      await _tapKey(tester, 'qa.city_pilot.booking_not_now');
      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(_onPressed(tester, 'qa.city_pilot.reserve.ev-open'), isNotNull);
      expect(_key('qa.city_pilot.cancel.ev-open'), findsNothing);
    });

    testWidgets('Accept & reserve books my place and offers Cancel my place '
        '[case:city_pilot.city_pilot.city_pilot_booking_accept.action] '
        '[case:city_pilot.city_pilot.city_pilot_reserve_event.action]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      await _tapKey(tester, 'qa.city_pilot.reserve.ev-open');
      await _tapKey(tester, 'qa.city_pilot.booking_accept');

      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writeLines, [
        'POST /city-pilot/events/ev-open/registration',
      ]);
      expect(world.api.writes.single.body, {'safety_terms_accepted': true});
      expect(world.loads, loads + 1);
      expect(find.text(_en.cityPilotReservedNotice), findsOneWidget);
      expect(_key('qa.city_pilot.reserve.ev-open'), findsNothing);
      expect(_key('qa.city_pilot.cancel.ev-open'), findsOneWidget);
      // Both booked events now say so.
      expect(find.text(_en.cityPilotPlaceReserved), findsNWidgets(2));
    });

    testWidgets('a refused booking explains and keeps Reserve available '
        '[case:city_pilot.city_pilot.city_pilot_reserve_event.api_failure]', (
      tester,
    ) async {
      final world = _World();
      world.api.fail(
        'POST /city-pilot/events/*/registration',
        status: 409,
        message: 'This experience is full',
      );
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.reserve.ev-open');
      await _tapKey(tester, 'qa.city_pilot.booking_accept');

      expect(find.text('This experience is full'), findsOneWidget);
      expect(find.text(_en.cityPilotReservedNotice), findsNothing);
      expect(_onPressed(tester, 'qa.city_pilot.reserve.ev-open'), isNotNull);
      expect(_key('qa.city_pilot.cancel.ev-open'), findsNothing);
      expect(
        world.api.sent('POST', '/city-pilot/events/ev-open/registration'),
        hasLength(1),
      );

      world.api.offline('POST /city-pilot/events/*/registration');
      await _tapKey(tester, 'qa.city_pilot.reserve.ev-open');
      await _tapKey(tester, 'qa.city_pilot.booking_accept');
      expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
      expect(_key('qa.city_pilot.reserve.ev-open'), findsOneWidget);
    });

    testWidgets('Cancel my place cancels the booking and offers Reserve again '
        '[case:city_pilot.city_pilot.city_pilot_cancel_event.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      await _tapKey(tester, 'qa.city_pilot.cancel.ev-booked');

      expect(world.api.writeLines, [
        'DELETE /city-pilot/events/ev-booked/registration',
      ]);
      expect(world.api.writes.single.data, isNull);
      expect(world.loads, loads + 1);
      expect(find.text(_en.cityPilotBookingCancelled), findsOneWidget);
      expect(_key('qa.city_pilot.cancel.ev-booked'), findsNothing);
      expect(_key('qa.city_pilot.reserve.ev-booked'), findsOneWidget);
      expect(find.text(_en.cityPilotPlaceReserved), findsNothing);
    });

    testWidgets('a failed cancel keeps the booking and explains '
        '[case:city_pilot.city_pilot.city_pilot_cancel_event.api_failure]', (
      tester,
    ) async {
      final world = _World();
      world.api.fail(
        'DELETE /city-pilot/events/*/registration',
        message: 'Could not cancel. Refresh before retrying',
      );
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.cancel.ev-booked');
      expect(
        find.text('Could not cancel. Refresh before retrying'),
        findsOneWidget,
      );
      expect(find.text(_en.cityPilotPlaceReserved), findsOneWidget);
      expect(_onPressed(tester, 'qa.city_pilot.cancel.ev-booked'), isNotNull);
      expect(
        world.api.sent('DELETE', '/city-pilot/events/ev-booked/registration'),
        hasLength(1),
      );
    });
  });

  group('feedback', () {
    testWidgets(
      'Share optional feedback asks whether I went; Share feedback stays off '
      'until I answer, then sends my answers privately '
      '[case:city_pilot.city_pilot.city_pilot_feedback_event.action] '
      '[case:city_pilot.city_pilot.city_pilot_feedback_share.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        final loads = world.loads;
        await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
        expect(_inDialog(_en.cityPilotFeedbackTitle), findsOneWidget);
        expect(_inDialog(_en.cityPilotDidYouAttend), findsOneWidget);
        expect(_inDialog(_en.cityPilotWorthwhileQuestion), findsNothing);
        expect(_onPressed(tester, 'qa.city_pilot.feedback_share'), isNull);

        await _tapKey(tester, 'qa.city_pilot.attended.true');
        expect(_chip(tester, 'qa.city_pilot.attended.true').selected, isTrue);
        expect(_inDialog(_en.cityPilotWorthwhileQuestion), findsOneWidget);
        await _tapKey(tester, 'qa.city_pilot.worthwhile.true');
        expect(_chip(tester, 'qa.city_pilot.worthwhile.true').selected, isTrue);
        expect(_onPressed(tester, 'qa.city_pilot.feedback_share'), isNotNull);
        await _tapKey(tester, 'qa.city_pilot.feedback_share');

        expect(find.byType(AlertDialog), findsNothing);
        expect(world.api.writeLines, [
          'POST /city-pilot/events/ev-past/feedback',
        ]);
        expect(world.api.writes.single.body, {
          'attended': true,
          'worthwhile': true,
        });
        expect(world.loads, loads + 1);
        expect(find.text(_en.cityPilotFeedbackThanks), findsOneWidget);
        expect(find.text(_en.cityPilotFeedbackReceived), findsOneWidget);
        expect(_key('qa.city_pilot.feedback.ev-past'), findsNothing);
      },
    );

    testWidgets(
      'Not this time answers no, and tapping it again takes the answer back '
      '[case:city_pilot.city_pilot.city_pilot_worthwhile_x.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
        await _tapKey(tester, 'qa.city_pilot.attended.true');
        await _tapKey(tester, 'qa.city_pilot.worthwhile.false');
        expect(
          _chip(tester, 'qa.city_pilot.worthwhile.false').selected,
          isTrue,
        );
        expect(
          _chip(tester, 'qa.city_pilot.worthwhile.true').selected,
          isFalse,
        );
        await _tapKey(tester, 'qa.city_pilot.feedback_share');
        expect(world.api.writes.single.body, {
          'attended': true,
          'worthwhile': false,
        });

        // Optional: un-selecting sends no worth-it answer at all.
        world.events['ev-past']!['can_feedback'] = true;
        world.events['ev-past']!['feedback'] = null;
        await _tapKey(tester, 'qa.city_pilot.refresh');
        await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
        await _tapKey(tester, 'qa.city_pilot.attended.true');
        await _tapKey(tester, 'qa.city_pilot.worthwhile.false');
        await _tapKey(tester, 'qa.city_pilot.worthwhile.false');
        expect(
          _chip(tester, 'qa.city_pilot.worthwhile.false').selected,
          isFalse,
        );
        await _tapKey(tester, 'qa.city_pilot.feedback_share');
        expect(world.api.writes.last.body, {
          'attended': true,
          'worthwhile': null,
        });
      },
    );

    testWidgets(
      'I couldn’t make it hides the worth-it question and clears its answer '
      '[case:city_pilot.city_pilot.city_pilot_attended_x.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
        await _tapKey(tester, 'qa.city_pilot.attended.true');
        await _tapKey(tester, 'qa.city_pilot.worthwhile.true');
        await _tapKey(tester, 'qa.city_pilot.attended.false');

        expect(_chip(tester, 'qa.city_pilot.attended.false').selected, isTrue);
        expect(_chip(tester, 'qa.city_pilot.attended.true').selected, isFalse);
        expect(_inDialog(_en.cityPilotWorthwhileQuestion), findsNothing);
        await _tapKey(tester, 'qa.city_pilot.feedback_share');
        expect(world.api.writes.single.body, {
          'attended': false,
          'worthwhile': null,
        });
        expect(find.text(_en.cityPilotFeedbackThanks), findsOneWidget);
      },
    );

    testWidgets('Skip closes the questions and sends nothing '
        '[case:city_pilot.city_pilot.city_pilot_feedback_skip.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
      await _tapKey(tester, 'qa.city_pilot.attended.true');
      await _tapKey(tester, 'qa.city_pilot.feedback_skip');
      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(world.loads, loads);
      expect(_onPressed(tester, 'qa.city_pilot.feedback.ev-past'), isNotNull);
      expect(find.text(_en.cityPilotFeedbackThanks), findsNothing);
    });

    testWidgets('a failed feedback save explains and keeps the feedback button '
        '[case:city_pilot.city_pilot.city_pilot_feedback_event.api_failure]', (
      tester,
    ) async {
      final world = _World();
      world.api.fail(
        'POST /city-pilot/events/*/feedback',
        status: 409,
        message: 'Feedback is closed for this experience',
      );
      await _open(tester, world);
      await _tapKey(tester, 'qa.city_pilot.feedback.ev-past');
      await _tapKey(tester, 'qa.city_pilot.attended.false');
      await _tapKey(tester, 'qa.city_pilot.feedback_share');

      expect(
        find.text('Feedback is closed for this experience'),
        findsOneWidget,
      );
      expect(find.text(_en.cityPilotFeedbackThanks), findsNothing);
      expect(_onPressed(tester, 'qa.city_pilot.feedback.ev-past'), isNotNull);
      expect(
        world.api.sent('POST', '/city-pilot/events/ev-past/feedback'),
        hasLength(1),
      );
    });
  });

  group('loading', () {
    testWidgets('Refresh pilot reloads and shows what changed '
        '[case:city_pilot.city_pilot.city_pilot_refresh.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      final loads = world.loads;
      world.events['ev-new'] = _event(
        'ev-new',
        'Rooftop sketching',
        canRegister: true,
      );
      await _tapKey(tester, 'qa.city_pilot.refresh');
      expect(world.loads, loads + 1);
      expect(find.text('Rooftop sketching'), findsOneWidget);
      expect(_key('qa.city_pilot.reserve.ev-new'), findsOneWidget);
      expect(world.api.writes, isEmpty);
    });

    testWidgets(
      'an unreachable pilot says so; Try again reloads it (and a second '
      'failure keeps the honest message) '
      '[case:city_pilot.city_pilot.city_pilot_retry.action]',
      (tester) async {
        final world = _World()..api.offline('GET /city-pilot');
        await _open(tester, world);
        expect(find.text(_en.cityPilotUnavailableTitle), findsOneWidget);
        expect(find.text(_en.cityPilotUnavailableBody), findsOneWidget);

        world.api.fail('GET /city-pilot', status: 503);
        await _tapKey(tester, 'qa.city_pilot.retry');
        expect(world.loads, 2);
        expect(find.text(_en.cityPilotUnavailableTitle), findsOneWidget);

        world.api.on(
          'GET /city-pilot',
          (_) => qaOk({
            'success': true,
            'pilot': world.pilot,
            'membership': 'joined',
            'can_join': false,
            'experiences': world.events.values.toList(),
          }),
        );
        await _tapKey(tester, 'qa.city_pilot.retry');
        expect(world.loads, 3);
        expect(find.text(_en.cityPilotUnavailableTitle), findsNothing);
        expect(
          find.text(_en.cityPilotPanelTitleJoined('Pune')),
          findsOneWidget,
        );
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets(
      'with the pilot switched off on the server a member sees it paused, '
      'cannot join or book, and can still leave or cancel '
      '[case:city_pilot.city_pilot.flag_off.gated]',
      (tester) async {
        // Not joined: no consent, no Join.
        final outside = _World(membership: 'none', enabled: false);
        await _open(tester, outside);
        expect(find.text(_en.cityPilotPaused), findsOneWidget);
        expect(find.text(_en.cityPilotNotAccepting), findsOneWidget);
        expect(_key('qa.city_pilot.consent'), findsNothing);
        expect(_key('qa.city_pilot.join'), findsNothing);
        expect(find.text(_en.cityPilotExperiencesHeading), findsNothing);
        await tester.pumpWidget(const SizedBox());

        // Joined: bookings closed, leaving and cancelling still reachable.
        final inside = _World(enabled: false);
        inside.events['ev-open']!['can_register'] = false;
        inside.events['ev-past']!['can_feedback'] = false;
        await _open(tester, inside);
        expect(find.text(_en.cityPilotPaused), findsOneWidget);
        expect(_key('qa.city_pilot.reserve.ev-open'), findsNothing);
        expect(_key('qa.city_pilot.feedback.ev-past'), findsNothing);
        expect(_onPressed(tester, 'qa.city_pilot.cancel.ev-booked'), isNotNull);
        await _tapKey(tester, 'qa.city_pilot.leave');
        await _tapKey(tester, 'qa.city_pilot.leave_confirm');
        expect(inside.api.writeLines, ['DELETE /city-pilot/membership']);
        expect(find.text(_en.cityPilotWithdrawn), findsOneWidget);
      },
    );
  });

  testWidgets('the city pilot renders translated in every locale '
      '[case:city_pilot.city_pilot.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final world = _World();
      await _open(tester, world, locale: locale);
      final l10n = qaL10n(locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.cityPilotTitle), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.cityPilotPanelTitleJoined('Pune')),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.text(l10n.cityPilotLeave), findsOneWidget);
      expect(find.text(l10n.cityPilotReserveFree), findsOneWidget);
      expect(find.text(l10n.cityPilotShareOptionalFeedback), findsOneWidget);
      expect(find.text(l10n.cityPilotCancelPlace), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
