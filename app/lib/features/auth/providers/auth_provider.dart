import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_session_store.dart';
import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';

part 'auth_provider.g.dart';

class SignupDraft {
  const SignupDraft({
    required this.username,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.accountKind = 'dating',
  });

  final String username;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String accountKind;
}

class AuthState {
  const AuthState({
    this.username,
    this.accountKind = 'dating',
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.isNewAccount = false,
    this.pendingSignup,
  });

  final String? username;
  final String accountKind;
  bool get isIntroducer => accountKind == 'introducer';
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final bool isNewAccount;
  final SignupDraft? pendingSignup;

  static const Object _unset = Object();

  AuthState copyWith({
    Object? username = _unset,
    Object? isLoading = _unset,
    Object? error = _unset,
    Object? isAuthenticated = _unset,
    Object? userId = _unset,
    Object? accessToken = _unset,
    Object? refreshToken = _unset,
    Object? isNewAccount = _unset,
    Object? pendingSignup = _unset,
  }) => AuthState(
    accountKind: accountKind,
    username: identical(username, _unset) ? this.username : username as String?,
    isLoading: identical(isLoading, _unset)
        ? this.isLoading
        : isLoading! as bool,
    error: identical(error, _unset) ? this.error : error as String?,
    isAuthenticated: identical(isAuthenticated, _unset)
        ? this.isAuthenticated
        : isAuthenticated! as bool,
    userId: identical(userId, _unset) ? this.userId : userId as String?,
    accessToken: identical(accessToken, _unset)
        ? this.accessToken
        : accessToken as String?,
    refreshToken: identical(refreshToken, _unset)
        ? this.refreshToken
        : refreshToken as String?,
    isNewAccount: identical(isNewAccount, _unset)
        ? this.isNewAccount
        : isNewAccount! as bool,
    pendingSignup: identical(pendingSignup, _unset)
        ? this.pendingSignup
        : pendingSignup as SignupDraft?,
  );
}

/// Shown on the sign-in screen after the server ended the session.
const kSessionExpiredMessage = 'You were signed out. Please sign in again.';

// The English texts below are the provider's message codes: screens show them
// through `localizedAuthMessage`, and tests and automation match on them.
const kAuthSignInFailedMessage = 'Unable to sign in. Try again.';
const kAuthCreateAccountFailedMessage = 'Unable to create account. Try again.';
const kAuthCreateAccountGenericMessage = 'Unable to create account.';
const kAuthInvalidCredentialsMessage = 'Invalid username or password.';
const kAuthUsernameFormatMessage =
    'Username must be 3–30 characters using letters, numbers, _ or .';
const kAuthEnterPasswordMessage = 'Please enter your password.';
const kAuthPasswordFormatMessage =
    'Password must be 8–72 bytes with letters and numbers.';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  int _attempt = 0;
  @override
  AuthState build() {
    final session = AuthSessionStore.instance;
    final expirations = session.expirations.listen((_) => _sessionExpired());
    ref.onDispose(expirations.cancel);
    if (session.restored && session.userId != null) {
      return AuthState(
        isAuthenticated: true,
        userId: session.userId,
        username: session.username,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        isNewAccount: session.isNewAccount,
        accountKind: session.accountKind,
      );
    }
    return const AuthState();
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (state.isLoading || state.isAuthenticated) return;
    final attempt = ++_attempt;
    final normalized = _normalizeUsername(username);
    if (!_validateCredentials(
      normalized,
      password,
      requireStrongPassword: false,
    )) {
      return;
    }

    _beginAuth(normalized);
    try {
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (attempt != _attempt) return;
        _completeAuth(
          username: normalized,
          userId: _mockUserId(normalized),
          isNewAccount: false,
        );
        return;
      }

      final data = await _credentialRequest(
        '/auth/login',
        username: normalized,
        password: password,
      );
      if (attempt != _attempt) return;
      _completeFromResponse(data, username: normalized, isNewAccount: false);
    } on DioException catch (e, stackTrace) {
      if (attempt != _attempt) return;
      AuthSessionStore.instance.clear();
      _fail(e, stackTrace, fallback: kAuthSignInFailedMessage);
    } on Object catch (e, stackTrace) {
      if (attempt != _attempt) return;
      AuthSessionStore.instance.clear();
      log.error('Username login failed', e, stackTrace);
      state = state.copyWith(isLoading: false, error: kAuthSignInFailedMessage);
    }
  }

  Future<void> signUp({
    required SignupDraft signup,
    required String password,
  }) async {
    if (state.isLoading || state.isAuthenticated) return;
    final attempt = ++_attempt;
    final normalized = _normalizeUsername(signup.username);
    if (!_validateCredentials(
      normalized,
      password,
      requireStrongPassword: true,
    )) {
      return;
    }
    final normalizedDraft = SignupDraft(
      username: normalized,
      name: signup.name.trim(),
      dateOfBirth: signup.dateOfBirth.trim(),
      gender: signup.gender.trim(),
      accountKind: signup.accountKind,
    );
    _beginAuth(normalized, pendingSignup: normalizedDraft);

    try {
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (attempt != _attempt) return;
        _completeAuth(
          username: normalized,
          userId: _mockUserId(normalized),
          isNewAccount: true,
          pendingSignup: normalizedDraft,
        );
        return;
      }

      final data = await _credentialRequest(
        '/auth/signup',
        username: normalized,
        password: password,
        signup: normalizedDraft,
      );
      if (attempt != _attempt) return;
      final session = _sessionFrom(data);
      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          error: data['error']?.toString() ?? kAuthCreateAccountGenericMessage,
        );
        return;
      }

      AuthSessionStore.instance.update(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      if (normalizedDraft.accountKind != 'introducer') {
        await _bootstrapProfile(session.userId, normalizedDraft);
      }
      if (attempt != _attempt) return;
      _completeAuth(
        username: normalized,
        userId: session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        accountKind: data['account_kind']?.toString() ?? 'dating',
        isNewAccount: true,
        pendingSignup: normalizedDraft,
      );
    } on DioException catch (e, stackTrace) {
      if (attempt != _attempt) return;
      AuthSessionStore.instance.clear();
      _fail(e, stackTrace, fallback: kAuthCreateAccountFailedMessage);
    } on Object catch (e, stackTrace) {
      if (attempt != _attempt) return;
      AuthSessionStore.instance.clear();
      log.error('Username signup failed', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: kAuthCreateAccountFailedMessage,
      );
    }
  }

  Future<void> logout() async {
    final attempt =
        ++_attempt; // Invalidate pending login/signup responses before any await.
    final userId = state.userId;
    state = const AuthState(isLoading: true);
    try {
      if (userId != null && userId.isNotEmpty) {
        await ref.read(pushNotificationServiceProvider).unregister(userId);
      }
    } on Object catch (error, stackTrace) {
      log.warning('Push unregister failed during logout', error, stackTrace);
    }
    if (attempt != _attempt) return;
    try {
      if (AuthSessionStore.instance.accessToken?.isNotEmpty ?? false) {
        await ref.read(apiClientProvider).post<dynamic>('/auth/logout');
      }
    } on Object catch (error, stackTrace) {
      log.warning(
        'Server-side logout failed; clearing local session',
        error,
        stackTrace,
      );
    } finally {
      if (attempt == _attempt) {
        AuthSessionStore.instance.clear();
        state = const AuthState();
      }
    }
  }

  /// The API client could not renew a credential the server rejected (the
  /// session was revoked or expired). Return to sign-in with a short notice;
  /// pending sign-in work from the old session is abandoned.
  void _sessionExpired() {
    if (!state.isAuthenticated) return;
    ++_attempt;
    log.warning('Session ended by the server; returning to sign-in');
    state = const AuthState(error: kSessionExpiredMessage);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetAuthFlow() {
    if (!state.isAuthenticated) {
      ++_attempt;
      AuthSessionStore.instance.clear();
      state = const AuthState();
    }
  }

  bool _validateCredentials(
    String username,
    String password, {
    required bool requireStrongPassword,
  }) {
    if (!_isValidUsername(username)) {
      state = state.copyWith(
        isLoading: false,
        error: kAuthUsernameFormatMessage,
      );
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: kAuthEnterPasswordMessage,
      );
      return false;
    }
    if (requireStrongPassword && !_isStrongPassword(password)) {
      state = state.copyWith(
        isLoading: false,
        error: kAuthPasswordFormatMessage,
      );
      return false;
    }
    return true;
  }

  void _beginAuth(String username, {SignupDraft? pendingSignup}) {
    AuthSessionStore.instance.clear(persisted: false);
    state = AuthState(
      username: username,
      isLoading: true,
      pendingSignup: pendingSignup,
    );
  }

  Future<Map<String, dynamic>> _credentialRequest(
    String path, {
    required String username,
    required String password,
    SignupDraft? signup,
  }) async {
    final response = await ref
        .read(apiClientProvider)
        .post<dynamic>(
          path,
          data: {
            'username': username,
            'password': password,
            if (signup?.accountKind == 'introducer') ...{
              'account_kind': 'introducer',
              'name': signup!.name,
              'date_of_birth': signup.dateOfBirth,
            },
          },
        );
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  void _completeFromResponse(
    Map<String, dynamic> data, {
    required String username,
    required bool isNewAccount,
  }) {
    final session = _sessionFrom(data);
    if (session == null) {
      state = state.copyWith(
        isLoading: false,
        error: data['error']?.toString() ?? kAuthInvalidCredentialsMessage,
      );
      return;
    }
    AuthSessionStore.instance.update(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    _completeAuth(
      username: username,
      userId: session.userId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      accountKind: data['account_kind']?.toString() ?? 'dating',
      isNewAccount: data['signup_required'] is bool
          ? data['signup_required'] as bool
          : isNewAccount,
    );
  }

  void _completeAuth({
    required String username,
    required String userId,
    required bool isNewAccount,
    String? accessToken,
    String? refreshToken,
    SignupDraft? pendingSignup,
    String accountKind = 'dating',
  }) {
    AuthSessionStore.instance.identify(
      userId: userId,
      username: username,
      accountKind: accountKind,
      isNewAccount: isNewAccount,
    );
    state = AuthState(
      accountKind: accountKind,
      username: username,
      isAuthenticated: true,
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      isNewAccount: isNewAccount,
      pendingSignup: pendingSignup,
    );
  }

  _AuthSession? _sessionFrom(Map<String, dynamic> data) {
    final userId = data['user_id']?.toString().trim() ?? '';
    final accessToken = data['access_token']?.toString().trim() ?? '';
    if (data['success'] != true || userId.isEmpty || accessToken.isEmpty) {
      return null;
    }
    return _AuthSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: data['refresh_token']?.toString().trim(),
    );
  }

  Future<void> _bootstrapProfile(String userId, SignupDraft signup) async {
    await ref
        .read(apiClientProvider)
        .post<dynamic>(
          '/auth/signup/bootstrap',
          data: {
            'user_id': userId,
            'username': signup.username,
            'name': signup.name,
            'date_of_birth': signup.dateOfBirth,
            'gender': signup.gender,
          },
        );
  }

  void _fail(
    DioException error,
    StackTrace stackTrace, {
    required String fallback,
  }) {
    log.error('Credential authentication failed', error, stackTrace);
    state = state.copyWith(
      isLoading: false,
      error: _extractApiError(error, fallback: fallback),
    );
  }

  String _mockUserId(String username) {
    final forced = AppRuntimeConfig.qaForcedUserId;
    return forced.isNotEmpty
        ? forced
        : AppRuntimeConfig.mockUserIdForIdentifier(username);
  }
}

class _AuthSession {
  const _AuthSession({
    required this.userId,
    required this.accessToken,
    this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String? refreshToken;
}

String _normalizeUsername(String input) => input.trim().toLowerCase();

// Matches release_contract.v1.json and the backend: 3–30 characters.
bool _isValidUsername(String input) =>
    RegExp(r'^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$').hasMatch(input);

bool _isStrongPassword(String password) =>
    utf8.encode(password).length >= 8 &&
    utf8.encode(password).length <= 72 &&
    RegExp('[A-Za-z]').hasMatch(password) &&
    RegExp('[0-9]').hasMatch(password);

String _extractApiError(DioException error, {required String fallback}) {
  final data = error.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  return fallback;
}
