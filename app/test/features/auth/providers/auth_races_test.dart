import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';

void main() {
  setUp(AuthSessionStore.instance.clear);
  tearDown(AuthSessionStore.instance.clear);
  for (final cancel in ['reset', 'logout']) {
    test('late login cannot resurrect session after $cancel', () async {
      final pending = Completer<void>();
      final entered = Completer<void>();
      var calls = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) async {
              calls++;
              entered.complete();
              await pending.future;
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'user_id': 'member',
                    'access_token': 'access',
                    'refresh_token': 'refresh',
                  },
                ),
              );
            },
          ),
        );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      final auth = container.read(authNotifierProvider.notifier);
      final login = auth.signIn(username: 'member', password: 'Password123');
      await entered.future;
      await auth.signIn(username: 'duplicate', password: 'Password123');
      expect(calls, 1);
      if (cancel == 'reset') {
        auth.resetAuthFlow();
      } else {
        await auth.logout();
      }
      pending.complete();
      await login;
      expect(container.read(authNotifierProvider).isAuthenticated, false);
      expect(AuthSessionStore.instance.accessToken, isNull);
    });
  }
  test('bootstrap failure clears temporary signup credentials', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.path == '/auth/signup') {
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'user_id': 'member',
                    'access_token': 'access',
                    'refresh_token': 'refresh',
                  },
                ),
              );
            } else {
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
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    await container
        .read(authNotifierProvider.notifier)
        .signUp(
          signup: const SignupDraft(
            username: 'member',
            name: 'Member',
            dateOfBirth: '1998-01-01',
            gender: 'F',
          ),
          password: 'Password123',
        );
    expect(container.read(authNotifierProvider).isAuthenticated, false);
    expect(container.read(authNotifierProvider).error, isNotNull);
    expect(AuthSessionStore.instance.accessToken, isNull);
  });
}
