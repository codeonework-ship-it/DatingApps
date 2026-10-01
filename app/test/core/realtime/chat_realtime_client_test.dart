import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/realtime/chat_realtime_client.dart';

void main() {
  test('builds resumable websocket URI from API base URL', () {
    expect(
      buildChatRealtimeUri('http://10.0.2.2:18080/v1', after: 41).toString(),
      'ws://10.0.2.2:18080/v1/realtime/chat?after=41',
    );
    expect(
      buildChatRealtimeUri('https://dating.example/v1/', after: 0).toString(),
      'wss://dating.example/v1/realtime/chat?after=0',
    );
  });

  test('parses match and message realtime envelopes', () {
    final event = ChatRealtimeEvent.tryParse(
      '{"sequence":42,"type":"message.created","match_id":"match-1",'
      '"payload":{"message_id":"message-1","match_id":"match-1"}}',
    );

    expect(event, isNotNull);
    expect(event!.sequence, 42);
    expect(event.type, 'message.created');
    expect(event.matchId, 'match-1');
    expect(event.payload['message_id'], 'message-1');
  });

  test('rejects malformed realtime envelopes', () {
    expect(ChatRealtimeEvent.tryParse('not-json'), isNull);
    expect(ChatRealtimeEvent.tryParse('{"sequence":-1,"type":"x"}'), isNull);
    expect(ChatRealtimeEvent.tryParse('{"sequence":1}'), isNull);
  });
}
