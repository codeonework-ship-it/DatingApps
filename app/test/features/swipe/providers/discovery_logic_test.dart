import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'viewer');
}

void main() {
  test(
    'newest discovery request wins and successful retry clears error',
    () async {
      final pending =
          <({RequestOptions options, RequestInterceptorHandler handler})>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              pending.add((options: o, handler: h));
            },
          ),
        );
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(dio),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(swipeNotifierProvider, (_, _) {});
      addTearDown(sub.close);
      Future<void> until(int count) async {
        for (var i = 0; i < 100 && pending.length < count; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(pending.length, count);
      }

      void resolve(int i, String id) {
        final p = pending[i];
        p.handler.resolve(
          Response(
            requestOptions: p.options,
            statusCode: 200,
            data: {
              'candidates': [
                {'id': id, 'name': id, 'age': 26},
              ],
            },
          ),
        );
      }

      await until(1);
      final n = c.read(swipeNotifierProvider.notifier);
      n.setManualFilters({'city': 'new'});
      final refresh = n.refreshProfiles();
      await until(2);
      resolve(1, 'new');
      await refresh;
      resolve(0, 'stale');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(swipeNotifierProvider).profiles.single.id, 'new');
      final failed = n.refreshProfiles();
      await until(3);
      pending[2].handler.reject(
        DioException(requestOptions: pending[2].options),
      );
      await failed;
      expect(c.read(swipeNotifierProvider).error, isNotNull);
      final retry = n.refreshProfiles();
      await until(4);
      resolve(3, 'recovered');
      await retry;
      expect(c.read(swipeNotifierProvider).error, isNull);
      expect(c.read(swipeNotifierProvider).profiles.single.age, 26);
    },
  );
  for (final age in [null, 29]) {
    test('public age $age never invents a birthday', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'found': true,
                    'profile': {
                      'id': 'member',
                      'name': 'Member',
                      if (age != null) 'age': age,
                    },
                  },
                ),
              );
            },
          ),
        );
      final c = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(c.dispose);
      final p = await c.read(profileDetailsProvider('member').future);
      expect(p.dateOfBirth, isNull);
      expect(p.age, age);
      expect(p.displayName, age == null ? 'Member' : 'Member, 29');
    });
  }
  test(
    'draft load failure cannot fabricate editable default preferences',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.connectionError,
                ),
              );
            },
          ),
        );
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(dio),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(profileSetupNotifierProvider.future),
        throwsA(isA<DioException>()),
      );
      expect(c.read(profileSetupNotifierProvider).hasError, true);
    },
  );
}
