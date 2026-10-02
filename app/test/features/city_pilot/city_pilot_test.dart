import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/city_pilot/city_pilot_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'member');
}

class _Api {
  bool fail = false;
  Map<String, dynamic> data = {'pilot': null};
  final writes = <RequestOptions>[];
  Dio client() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (fail) {
            h.reject(DioException(requestOptions: o));
            return;
          }
          if (o.method != 'GET') {
            writes.add(o);
            if (o.path.endsWith('/membership')) {
              data['membership'] = o.method == 'DELETE'
                  ? 'withdrawn'
                  : 'joined';
              data['can_join'] = false;
            }
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: o,
              statusCode: 200,
              data: o.method == 'GET' ? data : {'success': true},
            ),
          );
        },
      ),
    );
    return dio;
  }

  void recruit() {
    data = {
      'pilot': {
        'id': 'pilot',
        'city': 'Pilot City',
        'status': 'recruiting',
        'enabled': true,
        'closes_at': '2027-01-01T12:00:00Z',
      },
      'membership': 'none',
      'can_join': true,
      'experiences': <Map<String, dynamic>>[],
    };
  }
}

Future<void> _show(
  WidgetTester tester,
  _Api api, {
  double scale = 1,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(api.client()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const CityPilotScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unconfigured city remains honest at large text size', (t) async {
    final api = _Api();
    await _show(t, api, scale: 2);
    await _reveal(t, find.text('Coming to a city near you'));
    expect(find.text('Coming to a city near you'), findsOneWidget);
    expect(t.takeException(), isNull);
    expect(api.writes, isEmpty);
  });
  testWidgets('explicit unchecked consent is needed to join', (t) async {
    final api = _Api()..recruit();
    await _show(t, api);
    await _reveal(t, find.text('Join the city pilot'));
    expect(
      t
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Join the city pilot'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    await t.tap(find.text('Join the city pilot'));
    await t.pumpAndSettle();
    expect(api.writes.single.data['consent_version'], 'city-pilot-v1');
    expect(api.writes.single.data['pilot_id'], 'pilot');
  });
  testWidgets('leaving is reachable when paused and flag is off', (t) async {
    final api = _Api()..recruit();
    api.data['membership'] = 'joined';
    api.data['can_join'] = false;
    (api.data['pilot'] as Map)['status'] = 'paused';
    (api.data['pilot'] as Map)['enabled'] = false;
    await _show(t, api);
    await _reveal(t, find.text('Leave pilot'));
    await t.tap(find.text('Leave pilot'));
    await t.pumpAndSettle();
    expect(find.text('Leave the city pilot?'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Leave pilot'));
    await t.pumpAndSettle();
    expect(api.writes.single.method, 'DELETE');
  });
  testWidgets('offline page offers a retry without a fake success', (t) async {
    final api = _Api()..fail = true;
    await _show(t, api);
    await _reveal(t, find.text('Try again'));
    expect(find.text('Your pilot is unavailable'), findsOneWidget);
    api.fail = false;
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('Coming to a city near you'), findsOneWidget);
    expect(api.writes, isEmpty);
  });
  testWidgets('pilot speaks German with a German date', (t) async {
    final api = _Api()..recruit();
    await _show(t, api, locale: const Locale('de'));
    expect(find.text('Das Stadt-Pilotprojekt'), findsOneWidget);
    expect(find.text('Mit einem Gespräch beginnen'), findsOneWidget);
    await _reveal(t, find.text('Am Stadt-Pilotprojekt teilnehmen'));
    expect(find.text('Pilot City · Stadt-Pilotprojekt'), findsOneWidget);
    // Server city name stays as sent; the date uses German day/month names.
    // (Local time zone decides whether it is still 31 December.)
    expect(
      find.textContaining(
        RegExp(r'^Anmeldeschluss: \w+\., \d+\. (Jan|Dez)\. · \d'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Recruitment closes'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('cancelled experience offers no reservation', (t) async {
    final api = _Api()..recruit();
    api.data['membership'] = 'joined';
    api.data['can_join'] = false;
    api.data['experiences'] = [
      {
        'id': 'event',
        'title': 'Sunday coffee',
        'summary': 'A public coffee meetup',
        'venue': 'Public cafe',
        'host': 'Local host',
        'accessibility': 'Step-free entrance',
        'safety_contact': 'Onsite host',
        'status': 'cancelled',
        'registration': 'registered',
        'can_register': false,
      },
    ];
    await _show(t, api);
    await _reveal(
      t,
      find.text(
        'This experience has been cancelled. Please do not travel to the venue.',
      ),
    );
    expect(find.text('Reserve a free place'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
