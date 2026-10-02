// Control-level tests for Emergency SOS: activating an alert (with and
// without location), the confirmation and success dialogs, cancelling, the
// message and level inputs, the history refresh, and the failure paths. The
// device location is faked through devicePermissionServiceProvider; real GPS
// and OS permission prompts are an emulator check.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/permissions/device_permission_service.dart';
import 'package:verified_dating_app/features/safety/screens/sos_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

class _Location extends DevicePermissionService {
  _Location(this.coordinates);
  final SosCoordinates? coordinates;
  int asked = 0;

  @override
  Future<SosCoordinates?> currentSosCoordinates() async {
    asked++;
    return coordinates;
  }
}

class _SosServer {
  _SosServer({List<Map<String, dynamic>>? alerts}) : alerts = alerts ?? [] {
    api
      ..on('GET /safety/sos/me', (_) => qaOk({'alerts': this.alerts}))
      ..on('POST /safety/sos', (call) {
        final body = call.body;
        final alert = {
          'id': 'sos-${this.alerts.length + 1}',
          'user_id': body['user_id'],
          'emergency_level': body['emergency_level'],
          'message': body['message'],
          'latitude': body['latitude'],
          'longitude': body['longitude'],
          'status': 'open',
          'triggered_at': '2026-10-02T21:15:00Z',
        };
        this.alerts = [alert, ...this.alerts];
        return qaOk({'alert': alert});
      });
  }

  final api = QaApi();
  List<Map<String, dynamic>> alerts;

  List<QaCall> get posts => api.sent('POST', '/safety/sos');
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<_Location> _open(
  WidgetTester tester,
  _SosServer server, {
  SosCoordinates? coordinates = const SosCoordinates(
    latitude: 19.07,
    longitude: 72.87,
  ),
  Locale? locale,
}) async {
  final location = _Location(coordinates);
  await pumpQa(
    tester,
    server.api,
    const SosScreen(),
    size: const Size(430, 1400),
    locale: locale,
    extra: [devicePermissionServiceProvider.overrideWithValue(location)],
  );
  return location;
}

Future<void> _activate(WidgetTester tester) async {
  await tester.tap(_key('qa.safety.activate_sos'));
  await qaSettle(tester);
}

void main() {
  testWidgets(
    'Activate SOS → confirm → alert sent with level, message and location → '
    'Done; the alert tops the history '
    '[case:safety.sos.safety_activate_sos.action] '
    '[case:safety.sos.activate_sos_now.action] '
    '[case:safety.sos.activate.action] [case:safety.sos.done.action] '
    '[case:safety.sos.done_2.action]',
    (tester) async {
      final server = _SosServer();
      final location = await _open(tester, server);
      expect(find.text(en.safetySosHistoryEmpty), findsOneWidget);

      await _activate(tester);
      expect(find.text(en.safetySosConfirmTitle), findsOneWidget);
      expect(find.text(en.safetySosConfirmBody), findsOneWidget);
      // Nothing is sent before the member confirms.
      expect(server.posts, isEmpty);

      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);

      expect(location.asked, 1);
      expect(server.posts.single.body, {
        'user_id': 'me',
        'emergency_level': 'high',
        'message': en.safetySosDefaultMessage,
        'latitude': 19.07,
        'longitude': 72.87,
      });
      expect(find.text(en.safetySosActivatedTitle), findsOneWidget);
      expect(find.text(en.safetySosActivatedWithLocation), findsOneWidget);

      await tester.tap(_key('qa.safety.sos_done'));
      await qaSettle(tester);
      expect(find.text(en.safetySosActivatedTitle), findsNothing);
      expect(find.text(en.safetySosHistoryEmpty), findsNothing);
      expect(
        find.text(
          en.safetySosHistoryHeading(
            en.safetySosAlertLevelHigh,
            en.safetySosAlertStatusOpen,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('· location included'), findsOneWidget);
      // Ready for another alert.
      expect(
        tester.widget<FilledButton>(_key('qa.safety.activate_sos')).onPressed,
        isNotNull,
      );
      expect(find.text(en.safetySosActivate), findsOneWidget);
    },
  );

  testWidgets(
    'location unavailable still sends the alert and says it went without '
    'location [case:safety.sos.safety_activate_sos.no_location]',
    (tester) async {
      final server = _SosServer();
      await _open(tester, server, coordinates: null);
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);

      expect(server.posts.single.body['latitude'], 0);
      expect(server.posts.single.body['longitude'], 0);
      expect(find.text(en.safetySosActivatedWithoutLocation), findsOneWidget);
      await tester.tap(_key('qa.safety.sos_done'));
      await qaSettle(tester);
      expect(find.textContaining('· no location'), findsOneWidget);
    },
  );

  testWidgets(
    'Cancel in the confirmation sends nothing [case:safety.sos.cancel.action]',
    (tester) async {
      final server = _SosServer();
      final location = await _open(tester, server);
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.cancel'));
      await qaSettle(tester);

      expect(find.text(en.safetySosConfirmTitle), findsNothing);
      expect(server.posts, isEmpty);
      expect(location.asked, 0);
      expect(find.text(en.safetySosHistoryEmpty), findsOneWidget);
    },
  );

  testWidgets('Critical level is what the alert is sent with '
      '[case:safety.sos.urgent_onselectionchanged.action]', (tester) async {
    final server = _SosServer();
    await _open(tester, server);
    expect(
      tester
          .widget<SegmentedButton<String>>(_key('qa.safety.sos_level'))
          .selected,
      {'high'},
    );
    await tester.tap(find.text(en.safetySosLevelCritical));
    await qaSettle(tester);
    expect(
      tester
          .widget<SegmentedButton<String>>(_key('qa.safety.sos_level'))
          .selected,
      {'critical'},
    );

    await _activate(tester);
    await tester.tap(_key('qa.safety.sos_confirm.activate'));
    await qaSettle(tester);
    expect(server.posts.single.body['emergency_level'], 'critical');
    await tester.tap(_key('qa.safety.sos_done'));
    await qaSettle(tester);
    expect(
      find.text(
        en.safetySosHistoryHeading(
          en.safetySosAlertLevelCritical,
          en.safetySosAlertStatusOpen,
        ),
      ),
      findsOneWidget,
    );

    // Back to Urgent.
    await tester.tap(find.text(en.safetySosLevelUrgent));
    await qaSettle(tester);
    await _activate(tester);
    await tester.tap(_key('qa.safety.sos_confirm.activate'));
    await qaSettle(tester);
    expect(server.posts.last.body['emergency_level'], 'high');
  });

  testWidgets('the message is prefilled, editable and sent as typed (trimmed) '
      '[case:safety.sos.message_for_the_safety_team_input.action]', (
    tester,
  ) async {
    final server = _SosServer();
    await _open(tester, server);
    expect(
      tester.widget<TextField>(_key('qa.safety.sos_message')).controller!.text,
      en.safetySosDefaultMessage,
    );
    await tester.enterText(
      _key('qa.safety.sos_message'),
      '  At Blue Tokai, Bandra. He will not let me leave.  ',
    );
    await _activate(tester);
    await tester.tap(_key('qa.safety.sos_confirm.activate'));
    await qaSettle(tester);
    expect(
      server.posts.single.body['message'],
      'At Blue Tokai, Bandra. He will not let me leave.',
    );
    await tester.tap(_key('qa.safety.sos_done'));
    await qaSettle(tester);
    expect(
      find.text('At Blue Tokai, Bandra. He will not let me leave.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'the message is capped at 500 characters, keeps emoji and RTL text, and '
    'an empty message never blocks an emergency '
    '[case:safety.sos.message_for_the_safety_team_input.validation]',
    (tester) async {
      final server = _SosServer();
      await _open(tester, server);
      final field = _key('qa.safety.sos_message');

      await tester.enterText(field, 'x' * 600);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text.length, 500);
      expect(find.text('500/500'), findsOneWidget);

      const unicode = 'مساعدة 🚨 Hilfe — नमस्ते';
      await tester.enterText(field, unicode);
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);
      expect(server.posts.last.body['message'], unicode);
      await tester.tap(_key('qa.safety.sos_done'));
      await qaSettle(tester);

      await tester.enterText(field, '   ');
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);
      expect(server.posts, hasLength(2));
      expect(server.posts.last.body['message'], '');
      expect(find.text(en.safetySosActivatedTitle), findsOneWidget);
    },
  );

  testWidgets(
    'a failed activation explains, re-enables the button and shows no '
    'success [case:safety.sos.safety_activate_sos.api_failure]',
    (tester) async {
      final server = _SosServer();
      server.api.fail(
        'POST /safety/sos',
        status: 503,
        message: 'Safety service is temporarily unavailable.',
      );
      await _open(tester, server);
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);

      expect(
        find.text('Safety service is temporarily unavailable.'),
        findsOneWidget,
      );
      expect(find.text(en.safetySosActivatedTitle), findsNothing);
      expect(server.posts, hasLength(1));
      expect(
        tester.widget<FilledButton>(_key('qa.safety.activate_sos')).onPressed,
        isNotNull,
      );

      // No server wording: the translated fallback.
      server.api.fail('POST /safety/sos', status: 500, message: '');
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);
      expect(find.text(en.safetySosActivateFailed), findsOneWidget);

      // Recovers once the service is back.
      server.api.on(
        'POST /safety/sos',
        (call) => qaOk({
          'alert': {
            'id': 'sos-9',
            'user_id': 'me',
            'emergency_level': 'high',
            'status': 'open',
            'triggered_at': '2026-10-02T21:15:00Z',
          },
        }),
      );
      await _activate(tester);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);
      expect(find.text(en.safetySosActivatedTitle), findsOneWidget);
      expect(find.text(en.safetySosActivateFailed), findsNothing);
    },
  );

  testWidgets(
    'pull to refresh reloads the history with the safety team\'s resolution '
    '[case:safety.sos.resolution_note_onrefresh.action]',
    (tester) async {
      final server = _SosServer(
        alerts: [
          {
            'id': 'sos-1',
            'user_id': 'me',
            'emergency_level': 'high',
            'status': 'open',
            'triggered_at': '2026-10-01T20:00:00Z',
          },
        ],
      );
      await _open(tester, server);
      expect(find.textContaining('Resolution:'), findsNothing);

      server.alerts = [
        {
          ...server.alerts.single,
          'status': 'resolved',
          'resolution_note': 'Called the member; they are safe.',
        },
      ];
      server.api.calls.clear();
      await tester.fling(find.byType(ListView), const Offset(0, 700), 1000);
      await qaSettle(tester, frames: 30);

      expect(server.api.sent('GET', '/safety/sos/me'), hasLength(1));
      expect(
        find.text(en.safetySosResolution('Called the member; they are safe.')),
        findsOneWidget,
      );
      expect(
        find.text(
          en.safetySosHistoryHeading(
            en.safetySosAlertLevelHigh,
            en.safetySosAlertStatusResolved,
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a failed history load says so (translated) and keeps SOS usable '
      '[case:safety.sos.resolution_note_onrefresh.api_failure]', (
    tester,
  ) async {
    final server = _SosServer();
    server.api.fail('GET /safety/sos/me', status: 500, message: '');
    await _open(tester, server);
    expect(find.text(en.safetySosLoadFailed), findsOneWidget);
    expect(
      tester.widget<FilledButton>(_key('qa.safety.activate_sos')).onPressed,
      isNotNull,
    );

    // Pull again once the service recovers.
    server.api.on('GET /safety/sos/me', (_) => qaOk({'alerts': <Object>[]}));
    await tester.fling(find.byType(ListView), const Offset(0, 700), 1000);
    await qaSettle(tester, frames: 30);
    expect(find.text(en.safetySosLoadFailed), findsNothing);
    expect(find.text(en.safetySosHistoryEmpty), findsOneWidget);
  });

  testWidgets('SOS renders translated in all 10 languages, dialogs included '
      '[case:safety.sos.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final l10n = qaL10n(locale);
      final server = _SosServer();
      await _open(tester, server, locale: locale);
      expect(find.text(l10n.safetySosTitle), findsOneWidget);
      expect(find.text(l10n.safetySosActivate), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_key('qa.safety.sos_message'))
            .controller!
            .text,
        l10n.safetySosDefaultMessage,
      );
      await _activate(tester);
      expect(find.text(l10n.safetySosConfirmTitle), findsOneWidget);
      await tester.tap(_key('qa.safety.sos_confirm.activate'));
      await qaSettle(tester);
      expect(find.text(l10n.safetySosActivatedTitle), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
