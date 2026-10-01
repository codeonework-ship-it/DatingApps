import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/constants/app_constants.dart';
import 'package:verified_dating_app/core/telemetry/breadcrumbs.dart';
import 'package:verified_dating_app/core/telemetry/client_error_reporter.dart';
import 'package:verified_dating_app/core/utils/logger.dart';

/// Records every upload and answers with the queued responses (202 when the
/// queue is empty).
class FakeTransport {
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];
  final List<String?> tokens = <String?>[];
  final List<ClientErrorTransportResponse> responses =
      <ClientErrorTransportResponse>[];

  Future<ClientErrorTransportResponse> call(
    String jsonBody, {
    String? bearerToken,
  }) async {
    bodies.add((jsonDecode(jsonBody) as Map).cast<String, Object?>());
    tokens.add(bearerToken);
    if (responses.isEmpty) {
      return const ClientErrorTransportResponse(statusCode: 202);
    }
    return responses.removeAt(0);
  }

  List<Map<String, Object?>> eventsOf(int request) =>
      (bodies[request]['events']! as List)
          .cast<Map<dynamic, dynamic>>()
          .map((e) => e.cast<String, Object?>())
          .toList();
}

const _context = ClientErrorContext(
  platform: 'android',
  osVersion: '14',
  deviceClass: 'phone',
  locale: 'en_IN',
  appVersion: '1.4.2',
  buildNumber: '42',
);

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryClientErrorStore store;
  late FakeTransport transport;
  late DateTime now;
  final reporters = <ClientErrorReporter>[];

  ClientErrorReporter make({String? token}) {
    final reporter = ClientErrorReporter(
      store: store,
      transport: transport.call,
      clock: () => now,
      enabled: true,
      context: () => _context,
      bearerToken: () => token,
      observeLifecycle: false,
      flushDebounce: const Duration(hours: 1),
    );
    reporters.add(reporter);
    return reporter;
  }

  void fail(Object error, ClientErrorReporter reporter) => reporter.recordError(
    error,
    StackTrace.current,
    source: ClientErrorSource.zone,
    fatal: true,
  );

  setUp(() {
    store = MemoryClientErrorStore();
    transport = FakeTransport();
    now = DateTime.utc(2026, 10, 1, 12);
  });

  tearDown(() {
    for (final reporter in reporters) {
      reporter.dispose();
    }
    reporters.clear();
  });

  test('disabled by default under flutter test', () async {
    expect(FeatureFlags.enableClientErrorReporting, isFalse);
    final reporter = ClientErrorReporter(
      store: store,
      transport: transport.call,
      observeLifecycle: false,
    );
    reporters.add(reporter);
    await reporter.start();
    reporter.recordError(
      StateError('boom'),
      StackTrace.current,
      source: ClientErrorSource.zone,
    );
    await reporter.flush();
    expect(reporter.buildEnabled, isFalse);
    expect(reporter.pendingEvents, isEmpty);
    expect(transport.bodies, isEmpty);
    expect(store.values.containsKey(ClientErrorReporter.queueKey), isFalse);
  });

  test('captures a FlutterError through the installed handler', () async {
    final previousFlutter = FlutterError.onError;
    final previousPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousPlatform;
    });
    var forwarded = 0;
    FlutterError.onError = (_) => forwarded++;
    PlatformDispatcher.instance.onError = (_, _) => false;

    final reporter = make();
    await reporter.start();
    reporter
      ..installErrorHooks()
      ..currentScreen = '/settings';
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('render failed for jane@example.com'),
        stack: StackTrace.current,
        library: 'widgets library',
      ),
    );
    expect(forwarded, 1, reason: 'the app handler still runs');

    final handled = PlatformDispatcher.instance.onError!(
      ArgumentError('uncaught'),
      StackTrace.current,
    );
    expect(handled, isFalse, reason: 'previous handler result is kept');

    final events = reporter.pendingEvents;
    expect(events, hasLength(2));
    final flutter = events.first;
    expect(flutter.source, ClientErrorSource.flutter);
    expect(flutter.fatal, isFalse);
    expect(flutter.handled, isFalse);
    expect(flutter.errorType, 'StateError');
    expect(flutter.message, contains('<email>'));
    expect(flutter.message, isNot(contains('jane')));
    expect(flutter.screen, '/settings');
    expect(events.last.source, ClientErrorSource.platform);
    expect(events.last.fatal, isTrue);
  });

  test('events match the backend contract', () async {
    final reporter = make(token: 'session-token');
    await reporter.start();
    reporter.addBreadcrumb(BreadcrumbCategory.navigation, 'push /settings');
    fail(StateError('boom'), reporter);
    await reporter.flush();

    expect(transport.bodies, hasLength(1));
    expect(transport.tokens.single, 'session-token');
    final body = transport.bodies.single;
    expect(body.keys, unorderedEquals(<String>['install_id', 'events']));
    expect(body['install_id'], matches(RegExp(r'^[A-Za-z0-9_-]{32}$')));
    final event = transport.eventsOf(0).single;
    expect(
      event.keys,
      unorderedEquals(<String>[
        'fingerprint',
        'error_type',
        'message',
        'stack',
        'fatal',
        'handled',
        'source',
        'app_version',
        'build_number',
        'platform',
        'os_version',
        'device_class',
        'locale',
        'breadcrumbs',
        'occurred_at',
      ]),
    );
    expect(event['source'], 'zone');
    expect(event['fatal'], isTrue);
    expect(event['device_class'], 'phone');
    expect(event['occurred_at'], '2026-10-01T12:00:00.000Z');
    expect((event['fingerprint']! as String).length, lessThanOrEqualTo(128));
    final crumbs = (event['breadcrumbs']! as List)
        .cast<Map<dynamic, dynamic>>();
    expect(crumbs.single['category'], 'navigation');
    expect(crumbs.single['message'], 'push /settings');
    expect(reporter.pendingEvents, isEmpty);
  });

  test('unsent events survive a restart and are flushed', () async {
    transport.responses.add(const ClientErrorTransportResponse());
    final first = make();
    await first.start();
    fail(StateError('crash before upload'), first);
    await first.flush();
    expect(first.pendingEvents, hasLength(1), reason: 'network error keeps');
    final installId = first.installId;
    first.dispose();
    expect(store.values[ClientErrorReporter.queueKey], isNotNull);

    final second = make();
    await second.start();
    await settle();

    expect(transport.bodies, hasLength(2));
    expect(transport.bodies.last['install_id'], installId);
    expect(transport.eventsOf(1).single['message'], contains('crash before'));
    expect(second.pendingEvents, isEmpty);
    expect(store.values.containsKey(ClientErrorReporter.queueKey), isFalse);
  });

  test('429 keeps events and waits for Retry-After', () async {
    final reporter = make();
    await reporter.start();
    transport.responses.add(
      const ClientErrorTransportResponse(
        statusCode: 429,
        retryAfter: Duration(seconds: 120),
      ),
    );
    fail(StateError('rate limited'), reporter);
    await reporter.flush();
    expect(reporter.pendingEvents, hasLength(1));
    expect(store.values[ClientErrorReporter.queueKey], isNotNull);

    now = now.add(const Duration(seconds: 60));
    await reporter.flush();
    expect(transport.bodies, hasLength(1), reason: 'still backing off');

    now = now.add(const Duration(seconds: 61));
    await reporter.flush();
    expect(transport.bodies, hasLength(2));
    expect(reporter.pendingEvents, isEmpty);
  });

  test('400 and 413 drop the batch instead of retrying', () async {
    final reporter = make();
    await reporter.start();
    transport.responses.add(
      const ClientErrorTransportResponse(statusCode: 400),
    );
    fail(StateError('invalid'), reporter);
    await reporter.flush();
    expect(reporter.pendingEvents, isEmpty);

    transport.responses.add(
      const ClientErrorTransportResponse(statusCode: 413),
    );
    fail(ArgumentError('too large'), reporter);
    await reporter.flush();
    expect(reporter.pendingEvents, isEmpty);
    expect(transport.bodies, hasLength(2));
  });

  test('network errors back off exponentially', () async {
    final reporter = make();
    await reporter.start();
    transport.responses
      ..add(const ClientErrorTransportResponse())
      ..add(const ClientErrorTransportResponse(statusCode: 503));
    fail(StateError('offline'), reporter);
    await reporter.flush();
    now = now.add(const Duration(seconds: 31));
    await reporter.flush();
    expect(transport.bodies, hasLength(2));
    now = now.add(const Duration(seconds: 31));
    await reporter.flush();
    expect(transport.bodies, hasLength(2), reason: 'second wait is 60s');
    now = now.add(const Duration(seconds: 30));
    await reporter.flush();
    expect(transport.bodies, hasLength(3));
    expect(reporter.pendingEvents, isEmpty);
  });

  test('same error within 60s is dropped', () async {
    final reporter = make();
    await reporter.start();
    fail(StateError('loop 1'), reporter);
    fail(StateError('loop 2'), reporter);
    expect(reporter.pendingEvents, hasLength(1));
    now = now.add(const Duration(seconds: 61));
    fail(StateError('loop 3'), reporter);
    expect(reporter.pendingEvents, hasLength(2));
  });

  test('queue holds 100 events and batches carry at most 20', () async {
    final reporter = make();
    await reporter.start();
    transport.responses.addAll(
      List<ClientErrorTransportResponse>.filled(
        200,
        const ClientErrorTransportResponse(),
      ),
    );
    for (var i = 0; i < 120; i++) {
      // Distinct types so the fingerprint differs (digits are normalised).
      fail(
        UnsupportedError(
          'case ${String.fromCharCode(65 + i % 26)}'
          '${String.fromCharCode(65 + i ~/ 26)}',
        ),
        reporter,
      );
    }
    await settle();
    expect(reporter.pendingEvents, hasLength(100));

    transport.responses.clear();
    now = now.add(const Duration(hours: 2));
    await reporter.flush();
    expect(reporter.pendingEvents, isEmpty);
    final sizes = <int>[
      for (var i = 0; i < transport.bodies.length; i++)
        transport.eventsOf(i).length,
    ];
    expect(sizes.every((n) => n <= 20), isTrue);
    expect(sizes.reduce((a, b) => a + b), greaterThanOrEqualTo(100));
  });

  test('events older than 7 days are dropped', () async {
    final first = make();
    await first.start();
    transport.responses.add(const ClientErrorTransportResponse());
    fail(StateError('old'), first);
    await first.flush();
    first.dispose();

    now = now.add(const Duration(days: 8));
    final second = make();
    await second.start();
    await settle();
    expect(second.pendingEvents, isEmpty);
    expect(transport.bodies, hasLength(1));
  });

  test('opt-out stops capture and clears storage', () async {
    final reporter = make();
    await reporter.start();
    transport.responses.add(const ClientErrorTransportResponse());
    reporter.addBreadcrumb(BreadcrumbCategory.lifecycle, 'resumed');
    fail(StateError('queued'), reporter);
    await reporter.flush();
    expect(store.values[ClientErrorReporter.queueKey], isNotNull);

    await reporter.setOptIn(enabled: false);
    expect(reporter.pendingEvents, isEmpty);
    expect(reporter.breadcrumbs.length, 0);
    expect(store.values.containsKey(ClientErrorReporter.queueKey), isFalse);
    expect(store.values.containsKey(ClientErrorReporter.installIdKey), isFalse);
    expect(store.values[ClientErrorReporter.optInKey], '0');

    fail(StateError('after opt-out'), reporter);
    reporter.addBreadcrumb(BreadcrumbCategory.lifecycle, 'paused');
    expect(reporter.pendingEvents, isEmpty);
    expect(reporter.breadcrumbs.length, 0);

    final restarted = make();
    await restarted.start();
    expect(restarted.optIn.value, isFalse);
    fail(StateError('still off'), restarted);
    expect(restarted.pendingEvents, isEmpty);
  });

  test(
    'handled errors from log.error are reported, HTTP failures are not',
    () async {
      final reporter = make();
      await reporter.start();
      log
        ..error('profile_parse_failed', StateError('bad'), StackTrace.current)
        ..error(
          'api_error',
          DioException(requestOptions: RequestOptions(path: '/x')),
          StackTrace.current,
        );
      final event = reporter.pendingEvents.single;
      expect(event.source, ClientErrorSource.logger);
      expect(event.handled, isTrue);
      expect(event.fatal, isFalse);
      expect(event.message, startsWith('profile_parse_failed: '));
      reporter.dispose();
      expect(AppLogger.errorSink, isNull);
    },
  );

  test('FormatException source text is not reported', () async {
    final reporter = make();
    await reporter.start();
    fail(
      const FormatException('Unexpected token', 'my private message'),
      reporter,
    );
    expect(
      reporter.pendingEvents.single.message,
      'FormatException: Unexpected token',
    );
  });

  test('resume adds a lifecycle breadcrumb and flushes', () async {
    final reporter = make();
    await reporter.start();
    fail(StateError('pending'), reporter);
    reporter.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();
    expect(transport.bodies, hasLength(1));
    expect(reporter.breadcrumbs.snapshot().single.message, 'resumed');
  });
}
