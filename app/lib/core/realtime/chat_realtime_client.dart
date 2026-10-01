import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'socket_connector.dart';

class ChatRealtimeEvent {
  const ChatRealtimeEvent({
    required this.sequence,
    required this.type,
    required this.payload,
    this.matchId,
  });

  final int sequence;
  final String type;
  final String? matchId;
  final Map<String, dynamic> payload;

  static ChatRealtimeEvent? tryParse(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) {
        return null;
      }
      final map = decoded.cast<String, dynamic>();
      final payload =
          (map['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final sequence = (map['sequence'] as num?)?.toInt() ?? 0;
      final type = map['type']?.toString().trim() ?? '';
      if (sequence < 0 || type.isEmpty) {
        return null;
      }
      return ChatRealtimeEvent(
        sequence: sequence,
        type: type,
        matchId: map['match_id']?.toString().trim().isNotEmpty == true
            ? map['match_id'].toString().trim()
            : payload['match_id']?.toString().trim(),
        payload: payload,
      );
    } on Object {
      return null;
    }
  }
}

Uri buildChatRealtimeUri(String apiBaseUrl, {required int after}) {
  final base = Uri.parse(apiBaseUrl.trim());
  final basePath = base.path.endsWith('/')
      ? base.path.substring(0, base.path.length - 1)
      : base.path;
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '$basePath/realtime/chat',
    queryParameters: <String, String>{'after': after.toString()},
  );
}

class ChatRealtimeClient {
  const ChatRealtimeClient({required this.apiBaseUrl});

  final String apiBaseUrl;

  WebSocketChannel connect({required String accessToken, required int after}) =>
      connectAuthenticatedSocket(
        buildChatRealtimeUri(apiBaseUrl, after: after),
        accessToken,
      );
}
