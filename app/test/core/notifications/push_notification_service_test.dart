import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
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
}
