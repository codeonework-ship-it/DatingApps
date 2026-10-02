import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/session_end_listener.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';

/// A session the server stops accepting (revoked or expired): the API client
/// refreshes once, replays the request, and only when renewal is impossible
/// ends the session and returns the member to sign-in.

/// Accepts only `Bearer fresh-access`; everything else is a 401.
class _Api implements HttpClientAdapter {
  final authorizations = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    authorizations.add(auth);
    return ResponseBody.fromString(
      auth == 'Bearer fresh-access'
          ? '{"ok":true}'
          : '{"error":"unauthorized"}',
      auth == 'Bearer fresh-access' ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

enum _Refresh { succeeds, rejected, offline }

/// `/auth/refresh`, held until [release] so concurrent failures can pile up.
class _RefreshServer {
  _RefreshServer(this.outcome);
  final _Refresh outcome;
  final release = Completer<void>();
  var calls = 0;

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          calls++;
          await release.future;
          switch (outcome) {
            case _Refresh.succeeds:
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'access_token': 'fresh-access',
                    'refresh_token': 'fresh-refresh',
                  },
                ),
              );
            case _Refresh.rejected:
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.badResponse,
                  response: Response(requestOptions: o, statusCode: 401),
                ),
              );
            case _Refresh.offline:
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.connectionError,
                ),
              );
          }
        },
      ),
    );
}

/// A signed-in member whose access token the server has stopped accepting.
void _signIn({String? refreshToken = 'old-refresh'}) {
  AuthSessionStore.instance
    ..update(accessToken: 'revoked-access', refreshToken: refreshToken)
    ..identify(userId: 'member-1', username: 'member', isNewAccount: false)
    ..restored = true;
}

({ProviderContainer container, _Api api, _RefreshServer refresh, Dio dio})
_setUp(_Refresh outcome) {
  final refresh = _RefreshServer(outcome);
  final container = ProviderContainer(
    overrides: [authRefreshClientProvider.overrideWithValue(refresh.dio)],
  );
  addTearDown(container.dispose);
  expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
  final api = _Api();
  final dio = container.read(apiClientProvider)..httpClientAdapter = api;
  return (container: container, api: api, refresh: refresh, dio: dio);
}

void main() {
  tearDown(AuthSessionStore.instance.clear);

  test('concurrent 401s share one refresh and recover transparently', () async {
    _signIn();
    final s = _setUp(_Refresh.succeeds);
    final requests = [
      for (final path in ['/config/flags', '/progression', '/notifications'])
        s.dio.get<dynamic>(path),
    ];
    // Let every request fail and join the in-flight refresh.
    await pumpEventQueue();
    s.refresh.release.complete();
    final responses = await Future.wait(requests);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(s.refresh.calls, 1);
    expect(AuthSessionStore.instance.accessToken, 'fresh-access');
    expect(AuthSessionStore.instance.refreshToken, 'fresh-refresh');
    expect(s.container.read(authNotifierProvider).isAuthenticated, isTrue);
  });

  test('a 401 for a credential already replaced replays without refreshing '
      'again', () async {
    _signIn();
    final s = _setUp(_Refresh.succeeds)..refresh.release.complete();
    // Another request already rotated the session while this one was out.
    s.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onResponse: (r, h) => h.next(r),
        onError: (e, h) {
          if (AuthSessionStore.instance.accessToken == 'revoked-access') {
            AuthSessionStore.instance.update(
              accessToken: 'fresh-access',
              refreshToken: 'fresh-refresh',
            );
          }
          h.next(e);
        },
      ),
    );
    final response = await s.dio.get<dynamic>('/config/flags');
    expect(response.statusCode, 200);
    expect(s.refresh.calls, 0);
  });

  test(
    'a rejected refresh signs the member out once and stops retrying',
    () async {
      _signIn();
      final s = _setUp(_Refresh.rejected);
      final requests = [
        for (final path in ['/config/flags', '/progression'])
          expectLater(s.dio.get<dynamic>(path), throwsA(isA<DioException>())),
      ];
      await pumpEventQueue();
      s.refresh.release.complete();
      await Future.wait(requests);
      await pumpEventQueue();

      expect(s.refresh.calls, 1);
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(AuthSessionStore.instance.refreshToken, isNull);
      final auth = s.container.read(authNotifierProvider);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.error, kSessionExpiredMessage);

      // A poll that fires afterwards carries no credential and does not try to
      // refresh again: no loop, no stampede.
      s.api.authorizations.clear();
      await expectLater(
        s.dio.get<dynamic>('/config/flags'),
        throwsA(isA<DioException>()),
      );
      expect(s.api.authorizations, [null]);
      expect(s.refresh.calls, 1);
    },
  );

  test('without a refresh credential a 401 ends the session', () async {
    _signIn(refreshToken: null);
    final s = _setUp(_Refresh.succeeds);
    await expectLater(
      s.dio.get<dynamic>('/config/flags'),
      throwsA(isA<DioException>()),
    );
    await pumpEventQueue();
    expect(s.refresh.calls, 0);
    expect(
      s.container.read(authNotifierProvider).error,
      kSessionExpiredMessage,
    );
    expect(s.container.read(authNotifierProvider).isAuthenticated, isFalse);
  });

  test('a network outage during refresh keeps the member signed in', () async {
    _signIn();
    final s = _setUp(_Refresh.offline)..refresh.release.complete();
    await expectLater(
      s.dio.get<dynamic>('/config/flags'),
      throwsA(isA<DioException>()),
    );
    await pumpEventQueue();
    expect(AuthSessionStore.instance.refreshToken, 'old-refresh');
    expect(s.container.read(authNotifierProvider).isAuthenticated, isTrue);
  });

  test('an explicit logout is not reported as an expired session', () async {
    _signIn();
    final s = _setUp(_Refresh.succeeds);
    var expirations = 0;
    final sub = AuthSessionStore.instance.expirations.listen(
      (_) => expirations++,
    );
    addTearDown(sub.cancel);
    AuthSessionStore.instance.clear();
    // Expiring a session that is already gone announces nothing either.
    AuthSessionStore.instance.expire();
    await pumpEventQueue();
    expect(expirations, 0);
    expect(s.container.read(authNotifierProvider).error, isNull);
  });

  testWidgets('an expired session closes pushed screens and tells the member', (
    t,
  ) async {
    _signIn();
    await t.pumpWidget(
      ProviderScope(
        overrides: [notificationProvider.overrideWith(_IdleNotifications.new)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              listenForSessionEnd(ref, context);
              final auth = ref.watch(authNotifierProvider);
              return Scaffold(
                body: Text(auth.isAuthenticated ? 'Workspace' : 'Welcome'),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Workspace'), findsOneWidget);
    final context = t.element(find.text('Workspace'));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Chat')),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Chat'), findsOneWidget);

    AuthSessionStore.instance.expire();
    await t.pumpAndSettle();

    expect(find.text('Chat'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text(kSessionExpiredMessage), findsOneWidget);
  });
}

class _IdleNotifications extends NotificationNotifier {
  _IdleNotifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}
