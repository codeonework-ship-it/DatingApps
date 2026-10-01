import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_runtime_config.dart';
import '../providers/api_client_provider.dart';
import '../utils/logger.dart';

typedef PushOpenHandler = void Function(Map<String, dynamic> data);

@pragma('vm:entry-point')
Future<void> pushNotificationBackgroundHandler(RemoteMessage message) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    'push.last_background_message',
    jsonEncode(<String, dynamic>{
      'message_id': message.messageId,
      'received_at': DateTime.now().toUtc().toIso8601String(),
      'data': message.data,
    }),
  );
}

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(ref.read(apiClientProvider)),
);

class PushNotificationService {
  PushNotificationService(this._api);

  final Dio _api;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _opened;
  String? _activeUserId;
  PushOpenHandler? _onOpened;
  bool _firebaseReady = false;

  Future<void> start({
    required String userId,
    required PushOpenHandler onOpened,
  }) async {
    _onOpened = onOpened;
    if (!_supported || !AppRuntimeConfig.pushNotificationsConfigured) {
      return;
    }
    try {
      if (!_firebaseReady) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: AppRuntimeConfig.firebaseOptions,
          );
        }
        _firebaseReady = true;
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: false,
              badge: true,
              sound: false,
            );
        _opened = FirebaseMessaging.onMessageOpenedApp.listen(
          (message) => _onOpened?.call(message.data),
        );
        _tokenRefresh = FirebaseMessaging.instance.onTokenRefresh.listen((
          token,
        ) async {
          final currentUser = _activeUserId;
          if (currentUser != null && _provider == 'fcm') {
            await _register(currentUser, token);
          }
        });
      }
      _activeUserId = userId;
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await _deviceToken();
      if (token != null && token.isNotEmpty) {
        await _register(userId, token);
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _onOpened?.call(initial.data);
      }
    } on Object catch (error, stackTrace) {
      log.warning(
        'push_registration_failed',
        error,
        stackTrace,
        <String, dynamic>{'provider': _provider},
      );
    }
  }

  Future<void> unregister(String userId) async {
    if (!AppRuntimeConfig.pushNotificationsConfigured) {
      if (_activeUserId == userId) {
        _activeUserId = null;
      }
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final deviceId = preferences.getString(_deviceIdKey(userId));
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await _api.delete<dynamic>('/notifications/$userId/devices/$deviceId');
      } on Object catch (error, stackTrace) {
        log.warning('push_unregister_failed', error, stackTrace);
      }
    }
    await preferences.remove(_deviceIdKey(userId));
    await preferences.remove(_tokenKey(userId));
    if (_activeUserId == userId) {
      _activeUserId = null;
    }
  }

  Future<String?> _deviceToken() async {
    if (_provider == 'apns' && defaultTargetPlatform == TargetPlatform.iOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> _register(String userId, String token) async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    final response = await _api.post<dynamic>(
      '/notifications/$userId/devices',
      data: <String, dynamic>{
        'provider': _provider,
        'platform': platform,
        'token': token,
      },
    );
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};
    final deviceId = data['device_id']?.toString() ?? '';
    if (deviceId.isEmpty) {
      throw StateError('Push registration returned no device_id.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceIdKey(userId), deviceId);
    await preferences.setString(_tokenKey(userId), token);
  }

  String get _provider =>
      AppRuntimeConfig.pushTokenProvider == 'apns' &&
          defaultTargetPlatform == TargetPlatform.iOS
      ? 'apns'
      : 'fcm';

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String _deviceIdKey(String userId) => 'push.$userId.$_provider.device_id';
  String _tokenKey(String userId) => 'push.$userId.$_provider.token';

  Future<void> dispose() async {
    await _tokenRefresh?.cancel();
    await _opened?.cancel();
  }
}
