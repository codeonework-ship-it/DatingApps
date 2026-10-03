import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';

Dio _authClient({bool success = true}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final payload = (options.data as Map?)?.cast<String, dynamic>() ?? {};
        if (options.path == '/auth/login' || options.path == '/auth/signup') {
          expect(payload['username'], 'person_one');
          expect(payload['password'], 'Password123');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: success
                  ? <String, dynamic>{
                      'success': true,
                      'user_id': 'user-1',
                      'access_token': 'access-1',
                      'refresh_token': 'refresh-1',
                    }
                  : <String, dynamic>{
                      'success': false,
                      'error': 'invalid username or password',
                    },
            ),
          );
          return;
        }
        if (options.path == '/auth/signup/bootstrap') {
          expect(payload['username'], 'person_one');
          expect(payload['user_id'], 'user-1');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'success': true},
            ),
          );
          return;
        }
        if (options.path == '/auth/logout') {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'success': true},
            ),
          );
          return;
        }
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'unexpected request: ${options.method} ${options.path}',
          ),
        );
      },
    ),
  );
  return dio;
}

ProviderContainer _container(Dio dio) =>
    ProviderContainer(overrides: [apiClientProvider.overrideWithValue(dio)])
      ..listen<AuthState>(authNotifierProvider, (_, _) {});

void main() {
  setUp(AuthSessionStore.instance.clear);
  tearDown(AuthSessionStore.instance.clear);

  test('signIn uses normalized username and retains no password', () async {
    final container = _container(_authClient());
    addTearDown(container.dispose);

    await container
        .read(authNotifierProvider.notifier)
        .signIn(username: ' Person_One ', password: 'Password123');

    final state = container.read(authNotifierProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.username, 'person_one');
    expect(state.userId, 'user-1');
    expect(state.accessToken, 'access-1');
    expect(AuthSessionStore.instance.accessToken, 'access-1');
    expect(state.toString(), isNot(contains('Password123')));
  });

  test(
    'signUp creates credentials and bootstraps the username profile',
    () async {
      final container = _container(_authClient());
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .signUp(
            signup: const SignupDraft(
              username: 'Person_One',
              name: 'Person One',
              dateOfBirth: '1998-03-10',
              gender: 'F',
            ),
            password: 'Password123',
          );

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isNewAccount, isTrue);
      expect(state.pendingSignup?.username, 'person_one');
    },
  );

  test('signUp rejects passwords beyond the bcrypt byte boundary', () async {
    final container = _container(_authClient());
    addTearDown(container.dispose);

    await container
        .read(authNotifierProvider.notifier)
        .signUp(
          signup: const SignupDraft(
            username: 'Person_One',
            name: 'Person One',
            dateOfBirth: '1998-03-10',
            gender: 'Other',
          ),
          password: 'A1${List.filled(71, 'x').join()}',
        );

    final state = container.read(authNotifierProvider);
    expect(state.isAuthenticated, isFalse);
    expect(
      state.error,
      'Password must be 8–72 bytes with letters and numbers.',
    );
  });

  test('signIn exposes invalid username credential errors', () async {
    final container = _container(_authClient(success: false));
    addTearDown(container.dispose);

    await container
        .read(authNotifierProvider.notifier)
        .signIn(username: 'person_one', password: 'Password123');

    // The server's text maps to the provider's message code.
    expect(
      container.read(authNotifierProvider).error,
      kAuthInvalidCredentialsMessage,
    );
    expect(AuthSessionStore.instance.accessToken, isNull);
  });

  test(
    'logout revokes the server session before clearing local state',
    () async {
      final container = _container(_authClient());
      addTearDown(container.dispose);
      await container
          .read(authNotifierProvider.notifier)
          .signIn(username: 'person_one', password: 'Password123');

      await container.read(authNotifierProvider.notifier).logout();

      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
      expect(AuthSessionStore.instance.accessToken, isNull);
    },
  );
}
