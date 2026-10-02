import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../platform/browser_context.dart';

/// Authentication session used by the API interceptor.
///
/// Access credentials remain memory-only. The rotating refresh credential is
/// persisted through the operating-system credential store so a cold restart
/// can establish a new session without storing a password.
class AuthSessionStore {
  AuthSessionStore._();

  static final AuthSessionStore instance = AuthSessionStore._();

  static const _nativeStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _refreshKey = 'connect.auth.refresh_token';
  static const _usernameKey = 'connect.auth.username';

  int _revision = 0;
  int get revision => _revision;

  String? userId;
  String accountKind = 'dating';
  String? username;
  bool isNewAccount = false;
  bool restored = false;
  String? accessToken;
  String? refreshToken;

  void update({required String accessToken, String? refreshToken}) {
    _revision++;
    this.accessToken = accessToken.trim();
    this.refreshToken = refreshToken?.trim();
    _persist();
  }

  void clear({bool persisted = true}) {
    _revision++;
    userId = null;
    accountKind = 'dating';
    username = null;
    restored = false;
    writeBrowserSession(null);
    accessToken = null;
    refreshToken = null;
    if (!kIsWeb && persisted) {
      unawaited(clearNative());
    }
  }

  final _expirations = StreamController<void>.broadcast();

  /// Fires after [expire] ends a session the server no longer accepts, so the
  /// app can return the member to sign-in instead of polling with a dead
  /// credential.
  Stream<void> get expirations => _expirations.stream;

  /// Clears a session the server rejected (revoked, expired or a refresh
  /// credential that can no longer be rotated) and announces it once.
  void expire() {
    final hadSession =
        accessToken?.isNotEmpty == true || refreshToken?.isNotEmpty == true;
    clear();
    if (hadSession) _expirations.add(null);
  }

  void identify({
    required String userId,
    required String username,
    required bool isNewAccount,
    String accountKind = 'dating',
  }) {
    this.userId = userId;
    this.accountKind = accountKind;
    this.username = username;
    this.isNewAccount = isNewAccount;
    _persist();
  }

  void _persist() {
    if (refreshToken?.isNotEmpty == true) {
      writeBrowserSession({
        'refresh_token': refreshToken,
        'username': username,
      });
      if (!kIsWeb) {
        unawaited(persistNative());
      }
    }
  }

  Future<Map<String, String>?> readNative() async {
    if (kIsWeb) {
      return null;
    }
    try {
      final refresh = (await _nativeStorage.read(key: _refreshKey))?.trim();
      if (refresh == null || refresh.isEmpty) {
        return null;
      }
      return {
        'refresh_token': refresh,
        'username':
            (await _nativeStorage.read(key: _usernameKey))?.trim() ?? '',
      };
    } on Object {
      return null;
    }
  }

  Future<void> persistNative() async {
    if (kIsWeb || refreshToken?.isNotEmpty != true) {
      return;
    }
    try {
      await _nativeStorage.write(key: _refreshKey, value: refreshToken);
      await _nativeStorage.write(key: _usernameKey, value: username ?? '');
    } on Object {
      // The current session still works if the platform credential store is
      // unavailable; the member will sign in again after a cold restart.
    }
  }

  Future<void> clearNative() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _nativeStorage.delete(key: _refreshKey);
      await _nativeStorage.delete(key: _usernameKey);
    } on Object {
      // Keep local logout deterministic if the platform store is unavailable.
    }
  }
}
