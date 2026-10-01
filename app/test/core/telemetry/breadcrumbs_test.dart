import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/telemetry/breadcrumbs.dart';
import 'package:verified_dating_app/core/telemetry/client_error_navigator_observer.dart';
import 'package:verified_dating_app/core/telemetry/client_error_reporter.dart';

class _QaDetailScreen extends StatelessWidget {
  const _QaDetailScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('detail'));
}

/// Answers every request with an empty JSON object.
class _OkAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

final _uuidOrDigits = RegExp(r'\d{2,}|[0-9a-f]{8}-[0-9a-f]{4}');

ClientErrorReporter _enabledReporter() => ClientErrorReporter(
  store: MemoryClientErrorStore(),
  transport: (body, {bearerToken}) async =>
      const ClientErrorTransportResponse(statusCode: 202),
  enabled: true,
  observeLifecycle: false,
  context: () => const ClientErrorContext(
    platform: 'android',
    osVersion: '14',
    deviceClass: 'phone',
    locale: 'en_IN',
    appVersion: '1.4.2',
    buildNumber: '42',
  ),
);

void main() {
  test('ring buffer keeps the last 20 breadcrumbs', () {
    final buffer = BreadcrumbBuffer();
    for (var i = 0; i < 25; i++) {
      buffer.add(
        Breadcrumb(
          at: DateTime.utc(2026),
          category: BreadcrumbCategory.ui,
          message: 'tap $i',
        ),
      );
    }
    expect(buffer.length, 20);
    expect(buffer.snapshot().first.message, 'tap 5');
  });

  test('API breadcrumbs contain no ids or query strings', () {
    expect(
      apiBreadcrumbMessage(
        'get',
        '/profile/123e4567-e89b-12d3-a456-426614174000/photos'
            '?email=jane@example.com',
        200,
      ),
      'GET /profile/<id>/photos -> 200',
    );
    expect(
      apiBreadcrumbMessage(
        'POST',
        'https://api.example.com/v1/chat/98765/messages?draft=hi',
        null,
      ),
      'POST /v1/chat/<id>/messages -> ERR',
    );
    expect(
      apiBreadcrumbMessage('PATCH', 'settings/privacy', 409),
      'PATCH /settings/privacy -> 409',
    );
  });

  test('api client interceptor records templated API breadcrumbs', () async {
    final reporter = _enabledReporter();
    final previous = ClientErrorReporter.instance;
    ClientErrorReporter.instance = reporter;
    addTearDown(() {
      ClientErrorReporter.instance = previous;
      reporter.dispose();
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dio = container.read(apiClientProvider)
      ..httpClientAdapter = _OkAdapter();

    await dio.get<dynamic>(
      '/discovery/4821/liked-me',
      queryParameters: <String, dynamic>{'phone': '+919876543210'},
    );

    final crumb = reporter.breadcrumbs.snapshot().single;
    expect(crumb.category, BreadcrumbCategory.api);
    expect(crumb.message, 'GET /discovery/<id>/liked-me -> 200');
    expect(crumb.message, isNot(contains('?')));
    expect(crumb.message, isNot(contains('9876')));
  });

  test('API breadcrumbs are not recorded while reporting is off', () {
    final reporter = ClientErrorReporter(
      store: MemoryClientErrorStore(),
      observeLifecycle: false,
    )..recordApi('GET', '/profile/1', 200);
    expect(reporter.breadcrumbs.length, 0);
  });

  testWidgets('navigator observer records route templates only', (
    tester,
  ) async {
    final reporter = _enabledReporter();
    addTearDown(reporter.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [ClientErrorNavigatorObserver(reporter: reporter)],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text(settings.name ?? ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(
      navigatorKey.currentState!.pushNamed(
        '/profile/123e4567-e89b-12d3-a456-426614174000?tab=photos#top',
      ),
    );
    await tester.pumpAndSettle();
    expect(reporter.currentScreen, '/profile/<id>');

    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const _QaDetailScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(reporter.currentScreen, '_QaDetailScreen');

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(reporter.currentScreen, '/profile/<id>');

    final messages = reporter.breadcrumbs
        .snapshot()
        .where((b) => b.category == BreadcrumbCategory.navigation)
        .map((b) => b.message)
        .toList();
    expect(
      messages,
      containsAllInOrder(<String>[
        'push /profile/<id>',
        'push _QaDetailScreen',
        'pop _QaDetailScreen',
      ]),
    );
    for (final message in messages) {
      expect(message, isNot(contains('?')));
      expect(message, isNot(contains('#')));
      expect(message, isNot(matches(_uuidOrDigits)));
    }
  });
}
