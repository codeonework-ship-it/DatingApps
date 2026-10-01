import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/group_widgets.dart';
import 'package:verified_dating_app/features/groups/groups_data.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_data.dart';

/// Group cover photos: owner actions, the under-review badge, the emoji
/// fallback, uploads with progress, and the muted-notifications mark on
/// "Your groups".

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  _Api(this.handler);
  final FutureOr<Object?> Function(RequestOptions r) handler;
  final requests = <RequestOptions>[];
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          requests.add(r);
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: await handler(r),
            ),
          );
        },
      ),
    );

  Iterable<RequestOptions> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);
}

/// A 1×1 PNG.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
    'hQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

Map<String, Object?> _group({
  String id = 'g1',
  String role = 'owner',
  String coverId = '',
  String coverStatus = '',
  bool removed = false,
}) => {
  'id': id,
  'kind': 'community',
  'name': 'Koramangala readers',
  'category_slug': 'books',
  'category_title': 'Books',
  'category_emoji': '📚',
  'description': 'One book a month.',
  'member_count': 3,
  'member_cap': 200,
  'my_role': role,
  'channel_id': role.isEmpty ? '' : 'c1',
  'can_manage': role == 'owner',
  'can_invite': role.isNotEmpty,
  if (removed) 'moderation_state': 'removed',
  if (coverId.isNotEmpty) ...{
    'cover_photo_id': coverId,
    'cover_photo_url': '/v1/engagement/groups/$id/cover?v=$coverId',
  },
  if (coverStatus.isNotEmpty) 'cover_photo_status': coverStatus,
};

Widget _app(
  _Api api,
  Widget home, {
  Future<XFile?> Function(ImageSource)? picker,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
    if (picker != null) groupCoverPickerProvider.overrideWithValue(picker),
  ],
  child: MaterialApp(home: home),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the owner sees the change-cover action; members do not', (
    tester,
  ) async {
    _tall(tester);
    var role = 'owner';
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {'group': _group(role: role)};
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('groups.cover.change')), findsOneWidget);
    expect(find.text('Add cover photo'), findsOneWidget);
    // No photo yet: the emoji cover, no remove action, no banner.
    expect(find.byKey(const ValueKey('groups.cover.remove')), findsNothing);
    expect(find.byKey(const ValueKey('groups.detail.cover')), findsNothing);
    expect(find.byType(GroupCover), findsOneWidget);

    role = 'member';
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.text('Koramangala readers'), findsWidgets);
    expect(find.byKey(const ValueKey('groups.cover.change')), findsNothing);
  });

  testWidgets('a pending cover shows the under-review badge to its owner', (
    tester,
  ) async {
    _tall(tester);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {'group': _group(coverId: 'cv1', coverStatus: 'pending')};
      }
      if (r.path == '/engagement/groups/g1/cover') {
        return _png;
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('groups.detail.cover')), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.cover.review')), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.cover.note')), findsOneWidget);
    expect(find.text('Change cover'), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.cover.remove')), findsOneWidget);
    // The photo is fetched through the authenticated API by cover id.
    final fetch = api.calls('GET', '/engagement/groups/g1/cover').first;
    expect(fetch.queryParameters['v'], 'cv1');
    expect(fetch.responseType, ResponseType.bytes);
  });

  testWidgets('cards fall back to the emoji when there is no photo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) => <String, Object?>{});
    await tester.pumpWidget(
      _app(
        api,
        Scaffold(
          body: Column(
            children: [
              GroupCard(group: Group.fromJson(_group()), onTap: () {}),
              // A photo that fails to load keeps the emoji too.
              GroupCard(
                group: Group.fromJson(_group(id: 'g2', coverId: 'cv2')),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('📚'), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
    expect(api.calls('GET', '/engagement/groups/g1/cover'), isEmpty);
    expect(api.calls('GET', '/engagement/groups/g2/cover'), hasLength(1));
  });

  testWidgets('the owner picks, previews and uploads a cover', (tester) async {
    _tall(tester);
    var uploaded = false;
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {
          'group': uploaded
              ? _group(coverId: 'cv9', coverStatus: 'pending')
              : _group(),
        };
      }
      if (r.method == 'PUT' && r.path == '/engagement/groups/g1/cover') {
        uploaded = true;
        r.onSendProgress?.call(50, 100);
        return {
          'group': _group(coverId: 'cv9', coverStatus: 'pending'),
          'cover': {'id': 'cv9', 'status': 'pending'},
        };
      }
      return <String, Object?>{};
    });
    final sources = <ImageSource>[];
    await tester.pumpWidget(
      _app(
        api,
        const GroupDetailScreen(groupId: 'g1'),
        picker: (source) async {
          sources.add(source);
          return XFile.fromData(_png, name: 'beach.png', path: 'beach.png');
        },
      ),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('groups.cover.change')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('groups.cover.gallery')));
    await _settle(tester);
    expect(sources, [ImageSource.gallery]);
    expect(find.text('Preview your cover'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('groups.cover.confirm')));
    await _settle(tester);

    final put = api.calls('PUT', '/engagement/groups/g1/cover').single;
    final form = put.data as FormData;
    expect(form.files.single.key, 'image');
    expect(form.files.single.value.filename, 'beach.png');
    expect(form.fields.any((f) => f.key == 'cover_id'), isTrue);
    expect(
      find.text(
        'Your cover is under review. Only you can see it until it’s approved.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('groups.cover.review')), findsOneWidget);
  });

  testWidgets('the owner removes the cover after confirming', (tester) async {
    _tall(tester);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1/cover' && r.method == 'GET') {
        return _png;
      }
      if (r.path == '/engagement/groups/g1/cover') {
        return {'group': _group(), 'removed': true};
      }
      if (r.path == '/engagement/groups/g1') {
        return {'group': _group(coverId: 'cv1', coverStatus: 'approved')};
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('groups.cover.review')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('groups.cover.remove')));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await _settle(tester);
    expect(api.calls('DELETE', '/engagement/groups/g1/cover'), hasLength(1));
  });

  testWidgets('a removed group offers no cover changes', (tester) async {
    _tall(tester);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {'group': _group(removed: true)};
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('groups.detail.removed')), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.cover.change')), findsNothing);
  });

  testWidgets('a cover chosen while creating is uploaded to the new group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.method == 'POST' && r.path == '/engagement/groups') {
        return {
          'group': {..._group(id: 'new'), 'kind': 'private', 'name': 'Crew'},
        };
      }
      if (r.method == 'PUT' && r.path == '/engagement/groups/new/cover') {
        return {
          'group': _group(id: 'new', coverId: 'cv1', coverStatus: 'approved'),
        };
      }
      if (r.path == '/engagement/groups/new') {
        return {'group': _group(id: 'new')};
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(
      _app(
        api,
        const CreateGroupScreen(initialKind: 'private'),
        picker: (_) async => XFile.fromData(_png, name: 'crew.png'),
      ),
    );
    await _settle(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('groups.create.cover')),
    );
    await tester.tap(find.byKey(const ValueKey('groups.create.cover')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('groups.cover.camera')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('groups.cover.confirm')));
    await _settle(tester);
    expect(
      find.byKey(const ValueKey('groups.create.coverPreview')),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'Crew',
    );
    await tester.ensureVisible(find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await _settle(tester);
    expect(api.calls('POST', '/engagement/groups'), hasLength(1));
    expect(api.calls('PUT', '/engagement/groups/new/cover'), hasLength(1));
    expect(find.byType(GroupDetailScreen), findsOneWidget);
  });

  testWidgets('your groups mark the ones whose chat is muted', (tester) async {
    _tall(tester);
    final api = _Api((r) {
      switch (r.path) {
        case '/engagement/groups':
          return {
            'groups': r.queryParameters['scope'] == 'mine'
                ? [
                    _group(),
                    {..._group(id: 'g2'), 'name': 'Sunday hikers'},
                  ]
                : <Object>[],
          };
        case '/social/channels':
          return {
            'channels': [
              {'id': 'c1', 'kind': 'group', 'ref_id': 'g1', 'muted': true},
              {'id': 'c2', 'kind': 'group', 'ref_id': 'g2', 'muted': false},
              {'id': 'c3', 'kind': 'friend', 'ref_id': '', 'muted': true},
            ],
          };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupsScreen()));
    await _settle(tester);
    expect(find.text('Sunday hikers'), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.muted.g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.muted.g2')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('notifications muted')),
      findsOneWidget,
    );
  });

  test('a mute that has run out is not shown', () {
    final now = DateTime(2026, 10, 1, 12);
    final ids = mutedGroupIds([
      const SocialChannel(
        id: 'c1',
        kind: 'group',
        title: 'A',
        refId: 'g1',
        muted: true,
      ),
      SocialChannel(
        id: 'c2',
        kind: 'group',
        title: 'B',
        refId: 'g2',
        muted: true,
        mutedUntil: now.subtract(const Duration(minutes: 1)),
      ),
      SocialChannel(
        id: 'c3',
        kind: 'group',
        title: 'C',
        refId: 'g3',
        muted: true,
        mutedUntil: now.add(const Duration(hours: 1)),
      ),
    ], now: now);
    expect(ids, {'g1', 'g3'});
  });

  test('Group parses the cover fields', () {
    final g = Group.fromJson(_group(coverId: 'cv1', coverStatus: 'pending'));
    expect(g.hasCoverPhoto, isTrue);
    expect(g.coverUnderReview, isTrue);
    expect(g.coverPhotoUrl, '/v1/engagement/groups/g1/cover?v=cv1');
    expect(g.canChangeCover, isTrue);
    final rejected = Group.fromJson(_group(coverStatus: 'rejected'));
    expect(rejected.hasCoverPhoto, isFalse);
    expect(rejected.coverRejected, isTrue);
    expect(Group.fromJson(_group(removed: true)).canChangeCover, isFalse);
  });
}
