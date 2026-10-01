import 'package:web_socket_channel/web_socket_channel.dart';
import 'socket_connector.dart';

Uri buildNotificationRealtimeUri(String apiBaseUrl, {required int after}) {
  final base = Uri.parse(apiBaseUrl.trim());
  final basePath = base.path.endsWith('/')
      ? base.path.substring(0, base.path.length - 1)
      : base.path;
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '$basePath/realtime/notifications',
    queryParameters: <String, String>{'after': after.toString()},
  );
}

class NotificationRealtimeClient {
  const NotificationRealtimeClient({required this.apiBaseUrl});

  final String apiBaseUrl;

  WebSocketChannel connect({required String accessToken, required int after}) =>
      connectAuthenticatedSocket(
        buildNotificationRealtimeUri(apiBaseUrl, after: after),
        accessToken,
      );
}
