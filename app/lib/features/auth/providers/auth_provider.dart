import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
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

/// Ties the calling provider to the signed-in member and returns their id.
///
/// The provider is rebuilt from scratch whenever the member signs out, the
/// server ends the session, or someone else signs in on this device, so
/// nothing cached for one member is ever shown to the next. Every provider
/// that holds member data must call this (directly or through a provider
/// that does) instead of only `ref.read`-ing the auth state.
String? watchSignedInUserId(Ref ref) =>
    ref.watch(authNotifierProvider.select((s) => s.userId));

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
const kAuthUsernameTakenMessage = 'That username is already taken.';
const kAuthAccountSuspendedMessage = 'This account is suspended.';
const kAuthAccountLockedMessage = 'Too many sign-in attempts. Try again later.';
const kAuthTooManyRequestsMessage = 'Too many tries. Wait a moment.';
const kAuthAccountTypeUnavailableMessage =
    'This account type is not available right now.';
const kAuthAgeRangeMessage = 'Enter a name and a date of birth for ages 18–80.';
const kAuthNetworkMessage = 'Cannot reach the server.';

/// Every message code the provider can put in [AuthState.error].
/// `localizedAuthMessage` translates each of them.
const kAuthMessageCodes = <String>{
  kSessionExpiredMessage,
  kAuthSignInFailedMessage,
  kAuthCreateAccountFailedMessage,
  kAuthCreateAccountGenericMessage,
  kAuthInvalidCredentialsMessage,
  kAuthUsernameFormatMessage,
  kAuthEnterPasswordMessage,
  kAuthPasswordFormatMessage,
  kAuthUsernameTakenMessage,
  kAuthAccountSuspendedMessage,
  kAuthAccountLockedMessage,
  kAuthTooManyRequestsMessage,
  kAuthAccountTypeUnavailableMessage,
  kAuthAgeRangeMessage,
  kAuthNetworkMessage,
};

String _normalizeServerText(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Known server texts (normalized: lower case, punctuation removed) and the
/// message code each maps to. Sources: backend/internal/services/auth
/// (service.go, postgres_repository.go), internal/modules/auth/application
/// (validation errors, sent as "validation error: …"), the mobile BFF
/// (internal/bff/mobile/server.go login/signup) and the Supabase auth texts
/// the service passes through (upstreamAuthError).
const _serverAuthPhrases = <(String, String)>[
  ('invalid username or password', kAuthInvalidCredentialsMessage),
  ('invalid login credentials', kAuthInvalidCredentialsMessage),
  ('username is already taken', kAuthUsernameTakenMessage),
  ('user already registered', kAuthUsernameTakenMessage),
  ('already been registered', kAuthUsernameTakenMessage),
  ('already exists', kAuthUsernameTakenMessage),
  ('account is suspended or banned', kAuthAccountSuspendedMessage),
  ('banned', kAuthAccountSuspendedMessage),
  ('account temporarily locked', kAuthAccountLockedMessage),
  ('rate limit', kAuthTooManyRequestsMessage),
  ('too many', kAuthTooManyRequestsMessage),
  ('account type is unavailable', kAuthAccountTypeUnavailableMessage),
  ('friend introductions are unavailable', kAuthAccountTypeUnavailableMessage),
  ('provide a name and date of birth', kAuthAgeRangeMessage),
  ('username must be', kAuthUsernameFormatMessage),
  ('password must be', kAuthPasswordFormatMessage),
  ('password should be', kAuthPasswordFormatMessage),
  ('password is required', kAuthEnterPasswordMessage),
  ('username and password are required', kAuthEnterPasswordMessage),
  ('signup request was rejected', kAuthCreateAccountGenericMessage),
  (
    'account created without an active session',
    kAuthCreateAccountGenericMessage,
  ),
];

/// Maps what the server said about a failed sign-in or sign-up to one of the
/// provider's message codes ([kAuthMessageCodes]), never to raw server text.
///
/// Error codes win when they are specific (`TOO_MANY_REQUESTS`); the BFF's
/// other auth codes only repeat the HTTP status, so the text is matched next,
/// ignoring case and punctuation. Anything unknown becomes [fallback].
String authMessageCodeForServerError({
  Object? message,
  Object? errorCode,
  int? statusCode,
  required String fallback,
}) {
  final code = errorCode?.toString().trim().toUpperCase() ?? '';
  if (code == 'TOO_MANY_REQUESTS' ||
      code == 'RATE_LIMITED' ||
      statusCode == 429) {
    return kAuthTooManyRequestsMessage;
  }
  final text = _normalizeServerText(message?.toString() ?? '');
  if (text.isNotEmpty) {
    // Already one of ours (e.g. a test double replying with the code).
    for (final known in kAuthMessageCodes) {
      if (_normalizeServerText(known) == text) {
        return known;
      }
    }
    for (final (phrase, mapped) in _serverAuthPhrases) {
      if (text.contains(phrase)) {
        return mapped;
      }
    }
  }
  if (code == 'UNAUTHORIZED' || statusCode == 401) {
    return kAuthInvalidCredentialsMessage;
  }
  if (code == 'CONFLICT' || statusCode == 409) {
    return kAuthUsernameTakenMessage;
  }
  return fallback;
}

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
        log.warning('Signup rejected: ${data['error']}');
        state = state.copyWith(
          isLoading: false,
          error: authMessageCodeForServerError(
            message: data['error'],
            errorCode: data['error_code'],
            fallback: kAuthCreateAccountGenericMessage,
          ),
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

  /// Signs the member out on this device. Never depends on the network: when
  /// the server cannot be reached the local session is still cleared.
  ///
  /// Every sign-out path (Settings, the introducer menu, the terms screen,
  /// the web workspace) goes through here. Member data is not reset by the
  /// caller: providers that hold it are tied to the signed-in member through
  /// [watchSignedInUserId] and rebuild as soon as the member id changes, so
  /// callers need no `ref` after this returns (the gate has usually unmounted
  /// them by then).
  Future<void> logout() => _signOut(serverSessionEnded: false);

  /// Sign out of all devices: ends every session of this member on the
  /// server (phones, tablets, browsers, this device too), then signs out
  /// here.
  ///
  /// Returns false and leaves the member signed in when the server could not
  /// end the sessions, so this device never claims the others were signed
  /// out when they were not.
  Future<bool> logoutAllDevices() async {
    if (state.isLoading || !state.isAuthenticated) return false;
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/auth/sessions/revoke',
            data: const <String, dynamic>{'all_sessions': true},
          );
    } on Object catch (error, stackTrace) {
      log.warning('Signing out of all devices failed', error, stackTrace);
      return false;
    }
    await _signOut(serverSessionEnded: true);
    return true;
  }

  Future<void> _signOut({required bool serverSessionEnded}) async {
    final attempt =
        ++_attempt; // Invalidate pending login/signup responses before any await.
    final userId = state.userId;
    state = const AuthState(isLoading: true);
    try {
      if (userId != null && userId.isNotEmpty) {
        final push = ref.read(pushNotificationServiceProvider);
        // A revoked session cannot delete the device record any more.
        await (serverSessionEnded
            ? push.forgetDevice(userId)
            : push.unregister(userId));
      }
    } on Object catch (error, stackTrace) {
      log.warning('Push unregister failed during logout', error, stackTrace);
    }
    if (attempt != _attempt) return;
    try {
      if (!serverSessionEnded &&
          (AuthSessionStore.instance.accessToken?.isNotEmpty ?? false)) {
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
      log.warning('Sign-in rejected: ${data['error']}');
      state = state.copyWith(
        isLoading: false,
        error: authMessageCodeForServerError(
          message: data['error'],
          errorCode: data['error_code'],
          fallback: kAuthInvalidCredentialsMessage,
        ),
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

/// The message code for a failed credential request. The server's own text
/// stays in the log; the member reads a translated message.
String _extractApiError(DioException error, {required String fallback}) {
  final response = error.response;
  if (response == null) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => kAuthNetworkMessage,
      _ => fallback,
    };
  }
  final data = response.data;
  return authMessageCodeForServerError(
    message: data is Map ? (data['error'] ?? data['message']) : null,
    errorCode: data is Map ? data['error_code'] : null,
    statusCode: response.statusCode,
    fallback: fallback,
  );
}
