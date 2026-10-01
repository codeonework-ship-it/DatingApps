import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';

class _Unauthorized implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    401,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(
    () => AuthSessionStore.instance.update(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    ),
  );
  tearDown(AuthSessionStore.instance.clear);
  for (final action in ['logout', 'new login', 'network outage', 'rejected']) {
    test('token refresh respects $action', () async {
      final entered = Completer<void>(), finish = Completer<void>();
      final refresh = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) async {
              entered.complete();
              await finish.future;
              if (action == 'network outage') {
                h.reject(
                  DioException(
                    requestOptions: o,
                    type: DioExceptionType.connectionError,
                  ),
                );
              } else if (action == 'rejected') {
                h.reject(
                  DioException(
                    requestOptions: o,
                    type: DioExceptionType.badResponse,
                    response: Response(requestOptions: o, statusCode: 401),
                  ),
                );
              } else {
                h.resolve(
                  Response(
                    requestOptions: o,
                    statusCode: 200,
                    data: {
                      'success': true,
                      'access_token': 'late-access',
                      'refresh_token': 'late-refresh',
                    },
                  ),
                );
              }
            },
          ),
        );
      final c = ProviderContainer(
        overrides: [authRefreshClientProvider.overrideWithValue(refresh)],
      );
      addTearDown(c.dispose);
      final dio = c.read(apiClientProvider)
        ..httpClientAdapter = _Unauthorized();
      final request = expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );
      await entered.future;
      if (action == 'logout') AuthSessionStore.instance.clear();
      if (action == 'new login')
        AuthSessionStore.instance.update(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );
      finish.complete();
      await request;
      expect(AuthSessionStore.instance.accessToken, switch (action) {
        'new login' => 'new-access',
        'network outage' => 'old-access',
        _ => null,
      });
    });
  }
}
