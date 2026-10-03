// Shared fixture for the groups control tests: a stateful fake of the
// `/engagement/group*` BFF (plus the few social, friends and report routes a
// group screen touches) built on the recording QaApi, so a test can perform
// a gesture and assert the exact request, the state change and what the
// member sees next.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/groups/groups_data.dart';

import '../../support/qa_api.dart';

/// A 1×1 PNG.
final qaPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
    'hQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

/// One group as the server returns it.
Map<String, dynamic> qaGroup({
  String id = 'g1',
  String kind = 'community',
  String name = 'Koramangala readers',
  String category = 'books',
  String role = '',
  bool canJoin = false,
  bool canInvite = false,
  bool canManage = false,
  String channel = '',
  String inviteId = '',
  int memberCount = 3,
  String description = 'One book a month, long talks after.',
  String city = '',
  String coverEmoji = '',
  String coverColor = '',
  String coverId = '',
  String coverStatus = '',
  bool removed = false,
  int unread = 0,
}) => {
  'id': id,
  'kind': kind,
  'name': name,
  'category_slug': kind == 'community' ? category : '',
  'category_title': kind == 'community' && category == 'books'
      ? 'Books'
      : kind == 'community' && category == 'music'
      ? 'Music'
      : '',
  'category_emoji': kind == 'community' && category == 'books'
      ? '📚'
      : kind == 'community' && category == 'music'
      ? '🎶'
      : '',
  'description': description,
  'city': city,
  'cover_emoji': coverEmoji,
  'cover_color': coverColor,
  'member_count': memberCount,
  'member_cap': 200,
  'my_role': role,
  'invite_id': inviteId,
  'channel_id': channel,
  'unread_count': unread,
  'can_join': canJoin,
  'can_invite': canInvite,
  'can_manage': canManage,
  'removed': removed,
  if (coverId.isNotEmpty) ...{
    'cover_photo_id': coverId,
    'cover_photo_url': '/v1/engagement/groups/$id/cover?v=$coverId',
  },
  if (coverStatus.isNotEmpty) 'cover_photo_status': coverStatus,
  if (role.isNotEmpty)
    'members_preview': [
      {'user_id': 'me', 'name': 'Priya', 'role': role, 'is_me': true},
      {'user_id': 'asha', 'name': 'Asha', 'role': 'member', 'is_friend': true},
    ],
};

Map<String, dynamic> qaMember(
  String id,
  String name, {
  String role = 'member',
  bool me = false,
}) => {'user_id': id, 'name': name, 'role': role, 'is_me': me};

/// A stateful groups BFF. [groups] holds every group by id as this member
/// sees it; commands change it the way the server does.
class GroupsWorld {
  GroupsWorld() {
    _HealthyRoutes(api, _healthy)
      ..on(
        'GET /engagement/group-categories',
        (_) => qaOk({'categories': categories}),
      )
      ..on('GET /engagement/groups', (c) {
        final scope = c.query['scope'];
        final category = c.query['category'] as String? ?? '';
        return qaOk({
          'groups': [
            for (final g in groups.values)
              if (scope == 'mine' && (g['my_role'] as String).isNotEmpty)
                g
              else if (scope == 'discover' &&
                  g['kind'] == 'community' &&
                  (g['my_role'] as String).isEmpty &&
                  g['can_join'] == true &&
                  (category.isEmpty || g['category_slug'] == category))
                g,
          ],
        });
      })
      ..on(
        'GET /engagement/group-invites',
        (_) => qaOk({
          'invites': [
            for (final g in groups.values)
              if ((g['invite_id'] as String).isNotEmpty &&
                  (g['my_role'] as String).isEmpty)
                {
                  'id': g['invite_id'],
                  'group': g,
                  'inviter_user_id': 'asha',
                  'inviter_name': 'Asha',
                },
          ],
        }),
      )
      ..on('GET /engagement/groups/*', (c) {
        final g = groups[_id(c)];
        return g == null
            ? qaError(404, message: 'Group not found.')
            : qaOk({'group': g});
      })
      ..on('POST /engagement/groups', (c) {
        final b = c.body;
        const id = 'new';
        final g = qaGroup(
          id: id,
          kind: b['kind'] as String,
          name: b['name'] as String,
          category: (b['category_slug'] as String?) ?? '',
          role: 'owner',
          channel: 'ch-$id',
          canInvite: true,
          canManage: true,
          memberCount: 1,
          description: b['description'] as String,
          city: b['city'] as String,
          coverEmoji: (b['cover_emoji'] as String?) ?? '',
          coverColor: (b['cover_color'] as String?) ?? '',
        );
        groups[id] = g;
        return qaOk({'group': g});
      })
      ..on('PATCH /engagement/groups/*', (c) {
        final g = groups[_id(c)]!
          ..['name'] = c.body['name']
          ..['description'] = c.body['description']
          ..['city'] = c.body['city']
          ..['cover_color'] = c.body['cover_color'];
        if (c.body.containsKey('category_slug')) {
          g['category_slug'] = c.body['category_slug'];
          g['category_title'] = c.body['category_slug'] == 'music'
              ? 'Music'
              : 'Books';
          g['category_emoji'] = c.body['category_slug'] == 'music'
              ? '🎶'
              : '📚';
        }
        return qaOk({'group': g});
      })
      ..on('DELETE /engagement/groups/*', (c) {
        groups.remove(_id(c));
        return qaOk({'deleted': true});
      })
      ..on('POST /engagement/groups/*/join', (c) {
        final g = groups[_id(c)]!;
        g
          ..['my_role'] = 'member'
          ..['can_join'] = false
          ..['channel_id'] = 'ch-${g['id']}'
          ..['member_count'] = (g['member_count'] as int) + 1;
        return qaOk({'group': g});
      })
      ..on('POST /engagement/groups/*/leave', (c) {
        final g = groups[_id(c)]!;
        g
          ..['my_role'] = ''
          ..['channel_id'] = ''
          ..['can_join'] = g['kind'] == 'community'
          ..['member_count'] = (g['member_count'] as int) - 1;
        return qaOk({'deleted': false});
      })
      ..on('POST /engagement/groups/*/invites/respond', (c) {
        final g = groups[_id(c)]!;
        g['invite_id'] = '';
        if (c.body['decision'] == 'accept') {
          g
            ..['my_role'] = 'member'
            ..['channel_id'] = 'ch-${g['id']}';
        }
        return qaOk({'group': g});
      })
      ..on('POST /engagement/groups/*/invites', (c) {
        final ids = (c.body['invitee_user_ids'] as List).cast<String>();
        for (final f in friends) {
          if (ids.contains(f['user_id'])) {
            f['status'] = 'invited';
          }
        }
        return qaOk({'group_id': _id(c), 'invited_user_ids': ids});
      })
      ..on(
        'GET /engagement/groups/*/members',
        (c) => qaOk({'members': members[_id(c)] ?? const <dynamic>[]}),
      )
      ..on('POST /engagement/groups/*/members/*', (c) {
        final list = members[_id(c)]!;
        final user = c.path.split('/').last;
        switch (c.body['action']) {
          case 'remove':
            list.removeWhere((m) => m['user_id'] == user);
          case 'make_moderator':
            list.firstWhere((m) => m['user_id'] == user)['role'] = 'moderator';
          case 'make_member':
            list.firstWhere((m) => m['user_id'] == user)['role'] = 'member';
        }
        return qaOk({'success': true});
      })
      ..on('GET /engagement/group-friends', (_) => qaOk({'friends': friends}))
      ..on('PUT /engagement/groups/*/cover', (c) {
        final g = groups[_id(c)]!;
        g
          ..['cover_photo_id'] = 'cv-new'
          ..['cover_photo_url'] = '/v1/engagement/groups/${g['id']}/cover'
          ..['cover_photo_status'] = coverStatusAfterUpload;
        return qaOk({'group': g});
      })
      ..on('DELETE /engagement/groups/*/cover', (c) {
        final g = groups[_id(c)]!
          ..remove('cover_photo_id')
          ..remove('cover_photo_url')
          ..remove('cover_photo_status');
        return qaOk({'group': g, 'removed': true});
      })
      ..on('GET /engagement/groups/*/cover', (_) => qaOk(qaPng))
      ..on('GET /social/channels', (_) => qaOk({'channels': channels}))
      // A group's chat (`ch-<group id>`): the channel, its messages and the
      // read mark.
      ..on('GET /social/channels/*', (c) {
        final id = c.path.split('/')[3];
        final g = groups[id.replaceFirst('ch-', '')];
        return qaOk({
          'channel': {
            'id': id,
            'kind': 'group',
            'ref_id': g?['id'] ?? '',
            'title': g?['name'] ?? '',
            'member_count': g?['member_count'] ?? 0,
          },
        });
      })
      ..on(
        'GET /social/channels/*/messages',
        (c) => qaOk({
          'messages': [
            for (final m in chatMessages)
              {...m, 'channel_id': c.path.split('/')[3]},
          ],
          'has_more': false,
          'realtime_cursor': 0,
        }),
      )
      ..on('POST /social/channels/*/read', (_) => qaOk({'read': true}))
      // Friend links, for Add friend on a chat sender or a member.
      ..on('GET /friends/me', (_) => qaOk({'friends': friendLinks}))
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
        friendLinks.add(row);
        return qaOk({'friend': row});
      })
      ..on(
        'POST /blog/reports/group/*',
        (_) => qaOk({
          'accepted': true,
          'report': {'id': 'case-1'},
        }),
      );
  }

  static String _id(QaCall c) => c.path.split('/')[3];

  final api = QaApi();

  /// The fixture's own handler for every route, so a test that failed one
  /// route can bring it back with [heal].
  final _healthy = <String, QaHandler>{};

  /// Puts [route] (as registered by the fixture, e.g.
  /// `'POST /engagement/groups/*/join'`) back to its working handler.
  void heal(String route) => api.on(route, _healthy[route]!);

  /// What an upload leaves the cover as (`pending` or `approved`).
  String coverStatusAfterUpload = 'pending';

  final categories = <Map<String, dynamic>>[
    {'slug': 'books', 'title': 'Books', 'emoji': '📚', 'group_count': 1},
    {'slug': 'music', 'title': 'Music', 'emoji': '🎶', 'group_count': 0},
  ];

  final groups = <String, Map<String, dynamic>>{};
  final members = <String, List<Map<String, dynamic>>>{};
  final channels = <Map<String, dynamic>>[];

  /// Messages in every group chat: one from Asha.
  final chatMessages = <Map<String, dynamic>>[
    {
      'id': 'm1',
      'sender_id': 'asha',
      'sender_name': 'Asha',
      'sender_photo_url': '',
      'body': 'Who is bringing snacks?',
      'client_message_id': 'client-m1',
      'created_at': '2026-10-01T18:00:00Z',
      'deleted': false,
      'mine': false,
    },
  ];

  /// The member's friend links (`GET /friends/me`); none to start with.
  final friendLinks = <Map<String, dynamic>>[];

  final friends = <Map<String, dynamic>>[
    {'user_id': 'asha', 'name': 'Asha', 'status': 'member'},
    {'user_id': 'dev', 'name': 'Dev', 'status': 'available'},
    {'user_id': 'meera', 'name': 'Meera', 'status': 'invited'},
    {'user_id': 'kabir', 'name': 'Kabir', 'status': 'available'},
    {'user_id': 'zoe', 'name': 'Zoë', 'status': 'available'},
  ];
}

/// A cover picker that records the source and hands back [file].
class QaCoverPicker {
  QaCoverPicker([this.file]);
  XFile? file;
  final sources = <ImageSource>[];

  Future<XFile?> call(ImageSource source) async {
    sources.add(source);
    return file;
  }
}

XFile qaCoverFile([String name = 'beach.png']) =>
    XFile.fromData(qaPng, name: name, path: name);

/// The cover form a PUT carried: its file name and its retry id.
({String filename, String coverId, int bytes}) qaCoverForm(QaCall call) {
  final form = call.data! as FormData;
  return (
    filename: form.files.single.value.filename ?? '',
    coverId: form.fields.firstWhere((f) => f.key == 'cover_id').value,
    bytes: form.files.single.value.length,
  );
}

Finder qaKey(String key) => find.byKey(ValueKey(key));

/// Scrolls [finder] into view and taps it, then settles.
Future<void> qaTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await qaSettleRequests(tester);
}

/// Settles frames and lets requests finish. A provider rebuilt inside the
/// last frame hands its request to Dio on a zero-length timer, which
/// pumpAndSettle (it stops once no frame is scheduled) and pump() (it never
/// advances the clock) both leave pending, so the clock is moved on until
/// nothing new is scheduled.
Future<void> qaSettleRequests(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
  }
}

/// Lets the snackbar on screen time out so the next one can show.
Future<void> qaSnackGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Disposes screens with chat polling or reconnect timers.
Future<void> qaTeardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

/// Overrides the gallery/camera picker (the real one is an OS sheet).
Override qaPickerOverride(QaCoverPicker picker) =>
    groupCoverPickerProvider.overrideWithValue(picker.call);

/// Registers routes on [api] and remembers each handler in [healthy].
class _HealthyRoutes {
  _HealthyRoutes(this.api, this.healthy);
  final QaApi api;
  final Map<String, QaHandler> healthy;

  void on(String route, QaHandler handler) {
    healthy[route] = handler;
    api.on(route, handler);
  }
}
