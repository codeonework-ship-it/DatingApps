import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectAuthenticatedSocket(Uri uri, String token) =>
    IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': 'Bearer ${token.trim()}'},
      pingInterval: const Duration(seconds: 20),
      connectTimeout: const Duration(seconds: 8),
    );
