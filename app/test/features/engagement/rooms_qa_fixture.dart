// A recording fake BFF for the Rooms list and a room's chat, on the shared
// QA harness: every request is kept so tests assert exactly what was sent.
// Not a test file: rooms_controls_test.dart and room_chat_controls_test.dart
// use it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';

import '../../support/qa_api.dart';

/// A room as `GET /rooms` lists it.
Map<String, dynamic> roomJson(
  String id,
  String title, {
  String category = 'talk',
  String state = 'active',
  String type = 'topic',
  bool alwaysOn = true,
  int here = 0,
  int members = 0,
  int friendsHere = 0,
  int capacity = 200,
  String role = '',
  bool host = false,
  String hostName = '',
  String startsAt = '2026-10-01T00:00:00Z',
  String channel = '',
}) => {
  'id': id,
  'slug': id,
  'title': title,
  'description': 'About $title',
  'category': category,
  'icon_key': 'night',
  'room_type': type,
  'always_on': alwaysOn,
  'lifecycle_state': state,
  'starts_at': startsAt,
  'ends_at': null,
  'capacity': capacity,
  'participant_count': members,
  'here_now': here,
  'friends_here': friendsHere,
  'is_participant': role.isNotEmpty,
  'my_role': role,
  'can_moderate': role == 'host' || role == 'moderator',
  'is_host': host,
  'host_name': hostName,
  if (channel.isNotEmpty) 'channel_id': channel,
};

/// The chat channel a joined room opens.
String channelOf(String roomId) => 'chan-$roomId';

/// The fake server. Three rooms: Late-night talks (r1, talk, 3 here of 5),
/// Bookworms' corner (r2, interests, a friend inside) and a member-hosted
/// room that starts later (r4). Joining a room makes the member a
/// [myRole] in it; [joinedExtra] tweaks the joined room (for example a
/// hosted room that is not always on). The room has Ravi (host), Asha and
/// the signed-in member; Asha has posted "Anyone else up?".
class RoomsServer {
  RoomsServer({
    this.myRole = 'participant',
    this.joinedExtra = const {},
    this.ashaMutedUntil,
  }) {
    rooms = [
      roomJson('r1', 'Late-night talks', here: 3, members: 5),
      roomJson(
        'r2',
        "Bookworms' corner",
        category: 'interests',
        members: 2,
        friendsHere: 1,
      ),
      roomJson(
        'r4',
        'Sunday book swap',
        state: 'scheduled',
        type: 'member',
        alwaysOn: false,
        hostName: 'Ravi',
        startsAt: '2030-06-01T18:00:00Z',
      ),
    ];
    members = [
      {
        'user_id': 'ravi',
        'name': 'Ravi',
        'role': 'host',
        'here_now': true,
        'friend_status': 'none',
      },
      {
        'user_id': 'asha',
        'name': 'Asha',
        'role': 'participant',
        'here_now': true,
        'friend_status': 'none',
        'muted_until': ?ashaMutedUntil,
      },
      {
        'user_id': 'me',
        'name': 'Me',
        'role': myRole,
        'here_now': true,
        'is_me': true,
        'friend_status': 'me',
      },
    ];
    api
      ..on('GET /rooms', (_) => qaOk({'rooms': rooms}))
      ..on('POST /rooms/*/join', join)
      ..on('POST /rooms/*/presence', (c) => qaOk({'room': joined(_id(c))}))
      ..on('POST /rooms/*/moderate', (c) => qaOk({'room': joined(_id(c))}))
      ..on('POST /rooms/*/leave', (c) {
        final id = _id(c);
        final left = {..._room(id), 'is_participant': false, 'my_role': ''};
        rooms = [for (final r in rooms) r['id'] == id ? left : r];
        return qaOk({'room': left});
      })
      ..on('GET /rooms/*/members', (_) => qaOk({'members': members}))
      ..on('POST /rooms', create)
      ..on('GET /social/channels/*', (c) => qaOk({'channel': _channel(c)}))
      ..on(
        'GET /social/channels/*/messages',
        (c) => qaOk({
          'messages': c.path.contains(channelOf('r1'))
              ? messages
              : const <Map<String, dynamic>>[],
          'has_more': false,
          'realtime_cursor': 0,
        }),
      )
      ..on('POST /social/channels/*/read', (_) => qaOk())
      ..on(
        'POST /social/channels/*/messages',
        (c) => qaOk({
          'message': {
            'id': 'm-${c.body['client_message_id']}',
            'channel_id': c.path.split('/')[3],
            'sender_id': 'me',
            'sender_name': 'Me',
            'body': c.body['body'],
            'client_message_id': c.body['client_message_id'],
            'created_at': '2026-10-01T22:05:00Z',
            'mine': true,
          },
        }),
      )
      ..on(
        'POST /safety/report',
        (_) => qaOk({
          'report': {'id': 'rep-1'},
        }),
      )
      ..on('POST /safety/block', (_) => qaOk())
      ..on('GET /friends/me', (_) => qaOk({'friends': friends}))
      ..on(
        'GET /friends/me/activities',
        (_) => qaOk({'activities': <Object>[]}),
      )
      ..on('POST /friends/me', (c) {
        final row = {
          'friend_user_id': c.body['friend_user_id'],
          'friend_name': 'Asha',
          'status': 'pending',
          'direction': 'outgoing',
        };
        friends = [...friends, row];
        return qaOk({'friend': row});
      });
  }

  final api = QaApi();
  final String myRole;
  final Map<String, dynamic> joinedExtra;
  final String? ashaMutedUntil;

  /// What `GET /rooms` answers; tests may change it.
  late List<Map<String, dynamic>> rooms;

  /// What `GET /rooms/{id}/members` answers; tests may change it.
  late List<Map<String, dynamic>> members;

  /// The member's friend connections (`GET /friends/me`).
  List<Map<String, dynamic>> friends = [];

  /// Presence heartbeats answer with this many people here now.
  int hereNow = 3;

  /// The room chat's channel is read-only (the member is muted) until this.
  String? readOnlyUntil;

  final messages = <Map<String, dynamic>>[
    {
      'id': 'm1',
      'channel_id': channelOf('r1'),
      'sender_id': 'asha',
      'sender_name': 'Asha',
      'sender_photo_url': '',
      'body': 'Anyone else up?',
      'client_message_id': 'client-m1',
      'created_at': '2026-10-01T22:00:00Z',
      'deleted': false,
      'mine': false,
    },
  ];

  static String _id(QaCall c) => c.path.split('/')[2];

  /// `POST /rooms/{id}/join`: the member is now in the room (the directory
  /// says so too) and it carries its chat channel.
  QaReply join(QaCall c) {
    final room = joined(_id(c));
    rooms = [for (final r in rooms) r['id'] == room['id'] ? room : r];
    return qaOk({'room': room});
  }

  /// `POST /rooms`: the member hosts a new room, r9, live with its chat.
  QaReply create(QaCall c) {
    final created = roomJson(
      'r9',
      (c.body['title'] as String?) ?? '',
      category: (c.body['category'] as String?) ?? 'talk',
      type: 'member',
      alwaysOn: false,
      here: 1,
      members: 1,
      role: 'host',
      host: true,
      hostName: 'Me',
      channel: channelOf('r9'),
    );
    rooms = [created, ...rooms];
    return qaOk({'room': created});
  }

  Map<String, dynamic> _room(String id) => rooms.firstWhere(
    (r) => r['id'] == id,
    orElse: () => roomJson(id, 'Room $id'),
  );

  /// The room after the member joined it: their role and its chat channel.
  Map<String, dynamic> joined(String id) => {
    ..._room(id),
    'is_participant': true,
    'my_role': myRole,
    'can_moderate': myRole == 'host' || myRole == 'moderator',
    'here_now': hereNow,
    'channel_id': channelOf(id),
    ...joinedExtra,
  };

  Map<String, dynamic> _channel(QaCall c) {
    final id = c.path.split('/')[3];
    final room = id.replaceFirst('chan-', '');
    return {
      'id': id,
      'kind': 'room',
      'ref_id': room,
      'title': _room(room)['title'],
      'member_count': 3,
      'can_moderate': myRole == 'host',
      if (readOnlyUntil != null) ...{
        'read_only': true,
        'read_only_until': readOnlyUntil,
      },
    };
  }

  /// Requests to [method] [path] (a `*` segment matches any one).
  List<QaCall> sent(String method, String path) => api.sent(method, path);
}

/// [handler], answered after [by] (to see the busy state and double taps).
QaHandler slow(
  QaHandler handler, {
  Duration by = const Duration(milliseconds: 400),
}) => (c) {
  final reply = handler(c);
  return QaReply(reply.status, reply.body, offline: reply.offline, delay: by);
};

/// Pumps the Rooms screen on the fake server, on a phone-wide view tall
/// enough that every section of the list is built. [launcher] pushes it from
/// a launcher page (so it has a back button) and returns the pop results.
Future<List<Object?>> openRooms(
  WidgetTester tester,
  RoomsServer server, {
  Locale? locale,
  bool launcher = false,
  Size size = const Size(430, 1800),
}) => pumpQa(
  tester,
  server.api,
  const ConversationRoomsScreen(),
  locale: locale,
  launcher: launcher,
  size: size,
);

/// Taps a room's tile (the first, when it is listed twice) and lets its chat
/// open.
Future<void> tapRoom(WidgetTester tester, String id) async {
  final tile = find.byKey(ValueKey('rooms.tile.$id')).first;
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

/// Disposes the chat (its socket retry, poll and heartbeat timers) before
/// the test ends.
Future<void> unmountRooms(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
