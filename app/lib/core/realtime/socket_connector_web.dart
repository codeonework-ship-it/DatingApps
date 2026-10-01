import 'package:web_socket_channel/web_socket_channel.dart';

// Browser WebSockets cannot set Authorization. Carry the credential in an
// upgrade-only subprotocol, never in URLs; the server echoes only connect.v1.
WebSocketChannel connectAuthenticatedSocket(Uri uri, String token) =>
    WebSocketChannel.connect(
      uri,
      protocols: ['connect.v1', 'bearer.${token.trim()}'],
    );
