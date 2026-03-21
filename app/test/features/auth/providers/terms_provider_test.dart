import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._userId);

  final String _userId;

  @override
  AuthState build() => AuthState(isAuthenticated: true, userId: _userId);
}

final RegExp _termsPathPattern = RegExp(r'^/users/([^/]+)/agreements/terms$');

Dio _buildTermsApiClient({bool failGet = false, bool failPatch = false}) {
  final acceptedUsers = <String>{};
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final pathMatch = _termsPathPattern.firstMatch(options.path);
        if (pathMatch == null) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'unexpected path: ${options.path}',
            ),
          );
          return;
        }
        final userId = pathMatch.group(1)!;

        if (options.method == 'GET') {
          if (failGet) {
            handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: 'test-get-failure',
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'agreement': <String, dynamic>{
                  'accepted': acceptedUsers.contains(userId),
                },
              },
            ),
          );
          return;
        }

        if (options.method == 'PATCH') {
          if (failPatch) {
            handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: 'test-patch-failure',
              ),
            );
            return;
          }

          final payload =
              (options.data as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          if (payload['accepted'] == true) {
            acceptedUsers.add(userId);
          } else {
            acceptedUsers.remove(userId);
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'agreement': <String, dynamic>{
                  'accepted': acceptedUsers.contains(userId),
                },
              },
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            error: 'unsupported method: ${options.method}',
          ),
        );
      },
    ),
  );
  return dio;
}

ProviderContainer _containerFor({required String userId, required Dio dio}) =>
    ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _TestAuthNotifier(userId)),
        apiClientProvider.overrideWithValue(dio),
      ],
    );

void main() {
  group('TermsAcceptance', () {
    test('migrates legacy local key once and isolates cache by user', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'termsAccepted_v1': true,
      });
      final dio = _buildTermsApiClient(failGet: true);

      final firstUserContainer = _containerFor(userId: 'userA', dio: dio);
      addTearDown(firstUserContainer.dispose);
      final firstUserAccepted = await firstUserContainer.read(
        termsAcceptanceProvider.future,
      );
      expect(firstUserAccepted, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('termsAccepted_v1_userA'), isTrue);
      expect(prefs.getBool('termsAccepted_v1'), isNull);

      final secondUserContainer = _containerFor(userId: 'userB', dio: dio);
      addTearDown(secondUserContainer.dispose);
      final secondUserAccepted = await secondUserContainer.read(
        termsAcceptanceProvider.future,
      );
      expect(secondUserAccepted, isFalse);
      expect(prefs.getBool('termsAccepted_v1_userB'), isNull);
    });

    test('does not mark accepted when remote persistence fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final dio = _buildTermsApiClient(failGet: true, failPatch: true);
      final container = _containerFor(userId: 'userC', dio: dio);
      addTearDown(container.dispose);

      expect(await container.read(termsAcceptanceProvider.future), isFalse);
      await container.read(termsAcceptanceProvider.notifier).accept();
      expect(await container.read(termsAcceptanceProvider.future), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('termsAccepted_v1_userC'), isNull);
      expect(prefs.getBool('termsAccepted_v1'), isNull);
    });

    test('persists acceptance on success using user-scoped key', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final dio = _buildTermsApiClient();
      final userContainer = _containerFor(userId: 'userD', dio: dio);
      addTearDown(userContainer.dispose);

      expect(await userContainer.read(termsAcceptanceProvider.future), isFalse);
      await userContainer.read(termsAcceptanceProvider.notifier).accept();
      expect(await userContainer.read(termsAcceptanceProvider.future), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('termsAccepted_v1_userD'), isTrue);
      expect(prefs.getBool('termsAccepted_v1'), isNull);

      final sameUserReloaded = _containerFor(userId: 'userD', dio: dio);
      addTearDown(sameUserReloaded.dispose);
      expect(
        await sameUserReloaded.read(termsAcceptanceProvider.future),
        isTrue,
      );

      final otherUser = _containerFor(userId: 'userE', dio: dio);
      addTearDown(otherUser.dispose);
      expect(await otherUser.read(termsAcceptanceProvider.future), isFalse);
    });
  });
}
