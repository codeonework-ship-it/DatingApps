// Calls: starting, ending, retrying and joining the live room from the call
// screen and the call history, against the recording fake BFF (and a fake
// URL launcher). The live audio/video room itself opens outside the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/permissions/device_permission_service.dart';
import 'package:verified_dating_app/features/calls/screens/call_history_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_session_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';

class _Permissions extends DevicePermissionService {
  const _Permissions(this.granted);
  final bool granted;
  @override
  Future<bool> requestCallPermissions() async => granted;
}

Map<String, dynamic> _call({
  String id = 'call-1',
  String status = 'active',
  String? joinUrl = 'https://rooms.test/call-1',
  int duration = 0,
}) => {
  'id': id,
  'match_id': 'match-12345678',
  'initiator_id': 'me',
  'recipient_id': 'maya',
  'status': status,
  'room_id': 'room-$id',
  'started_at': '2026-10-02T10:00:00Z',
  'duration_sec': duration,
  'join_url': ?joinUrl,
};

QaApi _api({String? joinUrl = 'https://rooms.test/call-1'}) => QaApi()
  ..json('POST /calls/start', {'session': _call(joinUrl: joinUrl)})
  ..json('POST /calls/call-1/end', {
    'session': _call(status: 'ended', duration: 245),
  })
  ..json('GET /calls/history/me', {
    'history': [
      _call(id: 'call-9'),
      _call(id: 'call-1', status: 'ended', duration: 245, joinUrl: null),
    ],
  });

/// URLs handed to the platform's launcher.
List<String> _fakeLauncher({bool opens = true}) {
  final launched = <String>[];
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'launch') {
      launched.add((call.arguments as Map)['url'] as String);
      return opens;
    }
    return true;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return launched;
}

Future<List<Object?>> _openCall(
  WidgetTester tester,
  QaApi api, {
  bool permissions = true,
}) => pumpQa(
  tester,
  api,
  const CallSessionScreen(
    matchId: 'match-12345678',
    recipientUserId: 'maya',
    recipientName: 'Maya',
  ),
  launcher: true,
  extra: [
    devicePermissionServiceProvider.overrideWithValue(
      _Permissions(permissions),
    ),
  ],
);

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await qaSettle(tester);
}

/// A failure with no server text of its own (the screen shows its own).
const _bare500 = QaReply(500, <String, dynamic>{});

void main() {
  group('call screen', () {
    testWidgets('opening starts a session with this match '
        '', (tester) async {
      final api = _api();
      await _openCall(tester, api);

      expect(api.sent('POST', '/calls/start').single.body, {
        'match_id': 'match-12345678',
        'initiator_user_id': 'me',
        'recipient_user_id': 'maya',
      });
      expect(find.text('Session active'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.calls.end')), findsOneWidget);
    });

    testWidgets('without camera and microphone nothing is started '
        '[case:calls.call_session.permissions_denied]', (tester) async {
      final api = _api();
      await _openCall(tester, api, permissions: false);

      expect(api.sent('POST', '/calls/start'), isEmpty);
      expect(
        find.text('Camera and microphone permissions are required for calls.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('qa.calls.try_again')), findsOneWidget);
    });

    testWidgets('End ends the session and closes the screen '
        '[case:calls.call_session.calls_end.action] '
        '', (tester) async {
      final api = _api();
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.end'));

      expect(api.sent('POST', '/calls/call-1/end').single.body, {
        'ended_by_user_id': 'me',
      });
      expect(find.byType(CallSessionScreen), findsNothing);
    });

    testWidgets('back during a call ends it before leaving '
        '[case:calls.call_session.back_affordance] '
        '[case:calls.call_session.back_ends_call]', (tester) async {
      final api = _api();
      await _openCall(tester, api);
      await tester.tap(find.byType(BackButton));
      await qaSettle(tester);

      expect(api.sent('POST', '/calls/call-1/end'), hasLength(1));
      expect(find.byType(CallSessionScreen), findsNothing);
    });

    testWidgets('a failed End keeps the call open and says so '
        '[case:calls.call_session.calls_end.api_failure]', (tester) async {
      final api = _api()..on('POST /calls/call-1/end', (_) => _bare500);
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.end'));

      expect(find.byType(CallSessionScreen), findsOneWidget);
      expect(find.text('Unable to end the call.'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.calls.end')), findsOneWidget);
    });

    testWidgets('a session that failed to start can be tried again '
        '[case:calls.call_session.calls_try_again.action] '
        '', (tester) async {
      final api = _api()..on('POST /calls/start', (_) => _bare500);
      await _openCall(tester, api);
      expect(find.text('Unable to start the call session.'), findsOneWidget);
      expect(find.text('Session unavailable'), findsOneWidget);

      api.json('POST /calls/start', {'session': _call()});
      await _tap(tester, const ValueKey('qa.calls.try_again'));

      expect(api.sent('POST', '/calls/start'), hasLength(2));
      expect(find.text('Session active'), findsOneWidget);
      expect(find.text('Unable to start the call session.'), findsNothing);
    });

    testWidgets('a Try again that fails keeps the explanation '
        '[case:calls.call_session.calls_try_again.api_failure]', (tester) async {
      final api = _api()
        ..fail('POST /calls/start', status: 409, message: 'Maya is busy.');
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.try_again'));

      expect(api.sent('POST', '/calls/start'), hasLength(2));
      expect(find.text('Maya is busy.'), findsOneWidget);
    });

    testWidgets('Join live room opens the room link outside the app '
        '[case:calls.call_session.calls_join_live_room.action]', (tester) async {
      final launched = _fakeLauncher();
      final api = _api();
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.join_live_room'));

      expect(launched, ['https://rooms.test/call-1']);
    });

    testWidgets('a room link that is not https is refused with a reason '
        '[case:calls.call_session.calls_join_live_room.not_configured]', (
      tester,
    ) async {
      final launched = _fakeLauncher();
      final api = _api(joinUrl: 'http://rooms.test/call-1');
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.join_live_room'));

      expect(launched, isEmpty);
      expect(
        find.text('Live call rooms are not configured for this environment.'),
        findsOneWidget,
      );
    });

    testWidgets('a room the device cannot open is explained '
        '[case:calls.call_session.calls_join_live_room.open_failed]', (tester) async {
      final launched = _fakeLauncher(opens: false);
      final api = _api();
      await _openCall(tester, api);
      await _tap(tester, const ValueKey('qa.calls.join_live_room'));

      expect(launched, hasLength(1));
      expect(find.text('Unable to open the live call room.'), findsOneWidget);
    });
  });

  group('call history', () {
    Future<void> openHistory(WidgetTester tester, QaApi api) =>
        pumpQa(tester, api, const CallHistoryScreen());

    // The API contract behind the history is proven against the real BFF in
    // qa/api_e2e; this checks what the screen asks for and shows.
    testWidgets('loads the member\'s calls', (
      tester,
    ) async {
      final api = _api();
      await openHistory(tester, api);

      expect(api.sent('GET', '/calls/history/me').single.query, {'limit': 100});
      expect(find.text('Active call session'), findsOneWidget);
      expect(find.text('Ended · 4:05'), findsOneWidget);
    });

    testWidgets('pull to refresh reloads the history '
        '[case:calls.call_history.join_live_room_onrefresh.action]', (
      tester,
    ) async {
      final api = _api();
      await openHistory(tester, api);
      api.json('GET /calls/history/me', {
        'history': [_call(id: 'call-9', status: 'ended', duration: 61)],
      });

      await tester.fling(
        find.text('Active call session'),
        const Offset(0, 400),
        1000,
      );
      await qaSettle(tester, frames: 20);

      expect(api.sent('GET', '/calls/history/me'), hasLength(2));
      expect(find.text('Ended · 1:01'), findsOneWidget);
      expect(find.text('Active call session'), findsNothing);
    });

    testWidgets('a failed refresh shows why and keeps the list '
        '[case:calls.call_history.join_live_room_onrefresh.api_failure]', (
      tester,
    ) async {
      final api = _api();
      await openHistory(tester, api);
      api.on('GET /calls/history/me', (_) => _bare500);

      await tester.fling(
        find.text('Active call session'),
        const Offset(0, 400),
        1000,
      );
      await qaSettle(tester, frames: 20);

      expect(find.text('Unable to load call history.'), findsOneWidget);
      expect(find.text('Active call session'), findsOneWidget);
    });

    testWidgets('Join live room on an active call opens its room '
        '[case:calls.call_history.calls_history_join_x.action]', (tester) async {
      final launched = _fakeLauncher();
      final api = _api();
      await openHistory(tester, api);
      await _tap(tester, const ValueKey('qa.calls.history.join.call-9'));

      expect(launched, ['https://rooms.test/call-1']);
      expect(
        find.byKey(const ValueKey('qa.calls.history.join.call-1')),
        findsNothing,
        reason: 'an ended call has no room to join',
      );
    });
  });

  group('screen quality', () {
    List<Override> permitted() => [
      devicePermissionServiceProvider.overrideWithValue(
        const _Permissions(true),
      ),
    ];
    Widget session() => const CallSessionScreen(
      matchId: 'match-12345678',
      recipientUserId: 'maya',
      recipientName: 'Maya',
    );

    testWidgets('Call history with calls lays out on phone and tablet in '
        'both themes [case:calls.call_history.layout_matrix]', (tester) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: _api,
        build: () => const CallHistoryScreen(),
        loaded: () => find.text('Ended · 4:05'),
      );
    });

    testWidgets('Call history meets tap-target, label and contrast guidelines '
        '[case:calls.call_history.a11y_guidelines]', (tester) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: _api,
        build: () => const CallHistoryScreen(),
        loaded: () => find.text('Ended · 4:05'),
      );
    });

    testWidgets('Back on call history returns to the opener '
        '[case:calls.call_history.back_affordance]', (tester) async {
      await qaExpectBackReturnsToOpener(
        tester,
        api: _api(),
        build: () => const CallHistoryScreen(),
        screen: find.byType(CallHistoryScreen),
        loaded: find.text('Ended · 4:05'),
      );
    });

    testWidgets('An active call lays out on phone and tablet in both themes '
        '[case:calls.call_session.layout_matrix]', (tester) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: _api,
        build: session,
        extra: permitted,
        loaded: () => find.byKey(const ValueKey('qa.calls.end')),
      );
    });

    testWidgets('An active call meets tap-target, label and contrast '
        'guidelines [case:calls.call_session.a11y_guidelines]', (tester) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: _api,
        build: session,
        extra: permitted,
        loaded: () => find.byKey(const ValueKey('qa.calls.end')),
      );
    });

    testWidgets('Call history renders in all 10 languages with no English '
        'left [case:calls.call_history.l10n]', (tester) async {
      await qaExpectRendersInAllLocales(
        tester,
        api: _api,
        build: () => const CallHistoryScreen(),
        expected: [
          (l) => l.callsHistoryTitle,
          (l) => l.callsActiveSession,
          (l) => l.callsHistoryMatch('match-12'),
        ],
        // "Match" is the word these languages use too.
        allow: {'Match match-12'},
        prepare: (tester, l) async {
          // The join control is an icon; its tooltip is the spoken label.
          expect(find.byTooltip(l.callsJoinLiveRoom), findsOneWidget);
        },
      );
    });

    testWidgets('An active call and a failed one render in all 10 languages '
        'with no English left [case:calls.call_session.l10n]', (tester) async {
      await qaExpectRendersInAllLocales(
        tester,
        api: _api,
        build: session,
        extra: permitted,
        expected: [(l) => l.callsSessionTitle, (l) => l.callsSessionActive],
        allow: {'Maya'},
      );
      await qaExpectRendersInAllLocales(
        tester,
        api: () => _api()..on('POST /calls/start', (_) => _bare500),
        build: session,
        extra: permitted,
        expected: [(l) => l.chatTryAgain, (l) => l.callsSessionUnavailable],
        allow: {'Maya'},
      );
    });
  });
}
