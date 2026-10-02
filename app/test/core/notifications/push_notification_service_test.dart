import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'background handler persists receipt evidence without UI access',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await pushNotificationBackgroundHandler(
        const RemoteMessage(
          messageId: 'message-1',
          data: <String, dynamic>{
            'event_type': 'call.incoming',
            'call_id': 'call-1',
          },
        ),
      );

      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('push.last_background_message');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['message_id'], 'message-1');
      expect((decoded['data'] as Map<String, dynamic>)['call_id'], 'call-1');
    },
  );

  group('signing out', () {
    const deviceKey = 'push.me.fcm.device_id';
    const tokenKey = 'push.me.fcm.token';

    /// A BFF that cannot be reached, recording what was attempted.
    Dio offlineApi(List<String> sent) => Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent.add('${options.method} ${options.path}');
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

    setUp(() {
      dotenv.testLoad(
        mergeWith: const {
          'FIREBASE_API_KEY': 'qa-key',
          'FIREBASE_APP_ID': 'qa-app',
          'FIREBASE_PROJECT_ID': 'qa-project',
          'FIREBASE_MESSAGING_SENDER_ID': 'qa-sender',
        },
      );
      SharedPreferences.setMockInitialValues({
        deviceKey: 'device-42',
        tokenKey: 'fcm-token-42',
      });
    });
    tearDown(dotenv.clean);

    test('an offline sign-out still deletes the device push token '
        '[case:core.push.unregister_offline_deletes_token]', () async {
      final sent = <String>[];
      var deletes = 0;
      final service = PushNotificationService(
        offlineApi(sent),
        deleteDeviceToken: () async => deletes++,
      );

      await service.unregister('me');

      expect(sent, ['DELETE /notifications/me/devices/device-42']);
      expect(deletes, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(deviceKey), isNull);
      expect(prefs.getString(tokenKey), isNull);
    });

    test('after every session was revoked only the token is deleted '
        '[case:core.push.forget_device_after_revoke]', () async {
      final sent = <String>[];
      var deletes = 0;
      final service = PushNotificationService(
        offlineApi(sent),
        deleteDeviceToken: () async => deletes++,
      );

      await service.forgetDevice('me');

      expect(sent, isEmpty);
      expect(deletes, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(deviceKey), isNull);
    });

    test('a failing token deletion never fails sign-out '
        '[case:core.push.unregister_token_delete_failure]', () async {
      final service = PushNotificationService(
        offlineApi(<String>[]),
        deleteDeviceToken: () async => throw StateError('Firebase is down'),
      );

      await expectLater(service.unregister('me'), completes);
    });

    test('sign-out without a Firebase plugin (tests, web, desktop) completes '
        '[case:core.push.unregister_without_firebase]', () async {
      final sent = <String>[];
      // The real Firebase path: no plugin answers in this environment.
      await expectLater(
        PushNotificationService(offlineApi(sent)).unregister('me'),
        completes,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(
        PushNotificationService(offlineApi(sent)).forgetDevice('me'),
        completes,
      );
    });
  });
}
