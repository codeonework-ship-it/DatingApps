import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/realtime/notification_realtime_client.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';

void main() {
  test('builds resumable notification websocket URI', () {
    expect(
      buildNotificationRealtimeUri(
        'http://10.0.2.2:18080/v1',
        after: 17,
      ).toString(),
      'ws://10.0.2.2:18080/v1/realtime/notifications?after=17',
    );
    expect(
      buildNotificationRealtimeUri(
        'https://dating.example/v1/',
        after: 0,
      ).toString(),
      'wss://dating.example/v1/realtime/notifications?after=0',
    );
  });

  test('parses incoming-call notification payload', () {
    final notification = AppNotification.fromJson(<String, dynamic>{
      'id': 'notification-1',
      'sequence': 42,
      'event_type': 'call.incoming',
      'category': 'call',
      'title': 'Incoming call',
      'body': 'A match is calling you.',
      'payload': <String, dynamic>{'call_id': 'call-1', 'match_id': 'match-1'},
      'is_read': false,
      'created_at': '2026-08-09T09:00:00Z',
    });

    expect(notification.sequence, 42);
    expect(notification.eventType, 'call.incoming');
    expect(notification.payload['call_id'], 'call-1');
    expect(notification.isRead, isFalse);
  });

  test('notification preference patch serializes every delivery switch', () {
    final preferences = const NotificationPreferences().copyWith(
      matchNudges: false,
      incomingCalls: false,
      push: false,
    );

    expect(preferences.toJson(), <String, dynamic>{
      'notify_new_match': true,
      'notify_new_message': true,
      'notify_likes': true,
      'notify_match_nudges': false,
      'notify_incoming_calls': false,
      'notify_safety': true,
      'notify_friend_plans': true,
      'in_app_notifications_enabled': true,
      'push_notifications_enabled': false,
    });
  });
}
