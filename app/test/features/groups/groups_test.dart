import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/groups_data.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

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

  Iterable<RequestOptions> posts(String path) =>
      requests.where((r) => r.method == 'POST' && r.path == path);
}

const _categories = {
  'categories': [
    {'slug': 'books', 'title': 'Books', 'emoji': '📚', 'group_count': 1},
    {'slug': 'music', 'title': 'Music', 'emoji': '🎶', 'group_count': 0},
  ],
};

Map<String, Object?> groupJson({
  String id = 'g1',
  String kind = 'community',
  String name = 'Koramangala readers',
  String role = '',
  bool canJoin = false,
  bool canInvite = false,
  bool canManage = false,
  String channel = '',
  String inviteId = '',
}) => {
  'id': id,
  'kind': kind,
  'name': name,
  'category_slug': kind == 'community' ? 'books' : '',
  'category_title': kind == 'community' ? 'Books' : '',
  'category_emoji': kind == 'community' ? '📚' : '',
  'description': 'One book a month, long talks after.',
  'member_count': role.isEmpty ? 4 : 2,
  'member_cap': 200,
  'my_role': role,
  'invite_id': inviteId,
  'channel_id': channel,
  'unread_count': 0,
  'can_join': canJoin,
  'can_invite': canInvite,
  'can_manage': canManage,
  if (role.isNotEmpty)
    'members_preview': [
      {'user_id': 'me', 'name': 'Priya', 'role': role, 'is_me': true},
      {'user_id': 'f1', 'name': 'Asha', 'role': 'member', 'is_friend': true},
    ],
};

Widget _app(_Api api, Widget home, {Locale? locale}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('create flow starts private with the preselected friends', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.path == '/engagement/group-categories') {
        return _categories;
      }
      if (r.method == 'POST' && r.path == '/engagement/groups') {
        return {
          'group': groupJson(
            id: 'new',
            kind: 'private',
            name: 'Brunch crew',
            role: 'owner',
            channel: 'c9',
          ),
        };
      }
      if (r.path == '/engagement/groups/new') {
        return {
          'group': groupJson(
            id: 'new',
            kind: 'private',
            name: 'Brunch crew',
            role: 'owner',
            channel: 'c9',
            canInvite: true,
            canManage: true,
          ),
        };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(
      _app(
        api,
        const CreateGroupScreen(
          invitees: [
            (userId: 'f1', name: 'Asha', photoUrl: ''),
            (userId: 'f2', name: 'Dev', photoUrl: ''),
          ],
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Turn your friends into a group.'), findsOneWidget);
    // A friends-first flow defaults to a private group, so no category grid.
    expect(find.text('LIFESTYLE'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Asha'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Dev'), findsOneWidget);

    // Remove one friend, name the group and create it.
    await tester.tap(find.byTooltip('Remove Dev'));
    await tester.pump();
    expect(find.widgetWithText(InputChip, 'Dev'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'Brunch crew',
    );
    await tester.ensureVisible(find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await _settle(tester);

    final create = api.posts('/engagement/groups').single;
    final body = create.data as Map;
    expect(body['kind'], 'private');
    expect(body['name'], 'Brunch crew');
    expect(body['invitee_user_ids'], ['f1']);
    expect(body.containsKey('category_slug'), isFalse);
    expect(body['group_id'], isNotEmpty);
    // The new group opens.
    expect(find.byType(GroupDetailScreen), findsOneWidget);
  });

  testWidgets('community groups need a lifestyle before they are created', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.path == '/engagement/group-categories') {
        return _categories;
      }
      return {'group': groupJson(role: 'owner', channel: 'c1')};
    });
    await tester.pumpWidget(_app(api, const CreateGroupScreen()));
    await _settle(tester);
    expect(find.text('LIFESTYLE'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'Readers',
    );
    await tester.ensureVisible(find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await tester.pump();
    expect(
      find.text('Pick a lifestyle for your community group.'),
      findsOneWidget,
    );
    expect(api.posts('/engagement/groups'), isEmpty);

    await tester.ensureVisible(find.text('📚  Books'));
    await tester.tap(find.text('📚  Books'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create group'));
    await tester.tap(find.text('Create group'));
    await _settle(tester);
    final body = api.posts('/engagement/groups').single.data as Map;
    expect(body['kind'], 'community');
    expect(body['category_slug'], 'books');
  });

  testWidgets('discover filters by lifestyle and joins a group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var joined = false;
    final api = _Api((r) {
      switch (r.path) {
        case '/engagement/group-categories':
          return _categories;
        case '/engagement/group-invites':
          return {
            'invites': [
              {
                'id': 'i1',
                'group_id': 'p1',
                'inviter_name': 'Asha',
                'group': groupJson(
                  id: 'p1',
                  kind: 'private',
                  name: 'Trek planners',
                  inviteId: 'i1',
                ),
              },
            ],
          };
        case '/engagement/groups/g1/join':
          joined = true;
          return {'group': groupJson(role: 'member', channel: 'c1')};
        case '/engagement/groups':
          final query = r.queryParameters;
          if (query['scope'] == 'mine') {
            return {
              'groups': [if (joined) groupJson(role: 'member', channel: 'c1')],
            };
          }
          return {
            'groups': [
              if (query['category'] == 'books' && !joined)
                groupJson(canJoin: true),
            ],
          };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupsScreen()));
    await _settle(tester);

    expect(find.text('Find your people.'), findsOneWidget);
    expect(find.text('INVITATIONS'), findsOneWidget);
    expect(find.text('Trek planners'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Koramangala readers'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('groups.category.books')),
    );
    await tester.tap(find.byKey(const ValueKey('groups.category.books')));
    await _settle(tester);
    expect(
      api.requests.any(
        (r) =>
            r.path == '/engagement/groups' &&
            r.queryParameters['category'] == 'books',
      ),
      isTrue,
    );
    expect(find.text('Koramangala readers'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('groups.join.g1')));
    await tester.tap(find.byKey(const ValueKey('groups.join.g1')));
    await _settle(tester);
    expect(api.posts('/engagement/groups/g1/join'), hasLength(1));
    // Now listed under Your groups and no longer offered.
    expect(find.text('No groups yet'), findsNothing);
    expect(find.text('Koramangala readers'), findsOneWidget);
    expect(find.byKey(const ValueKey('groups.join.g1')), findsNothing);
  });

  testWidgets('groups home and detail follow the German locale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      switch (r.path) {
        case '/engagement/group-categories':
          return _categories;
        case '/engagement/group-invites':
          return {
            'invites': [
              {
                'id': 'i1',
                'group_id': 'p1',
                'inviter_name': 'Asha',
                'group': groupJson(
                  id: 'p1',
                  kind: 'private',
                  name: 'Trek planners',
                  inviteId: 'i1',
                ),
              },
            ],
          };
        case '/engagement/groups':
          return {'groups': <Object>[]};
        case '/engagement/groups/g1':
          return {
            'group': groupJson(role: 'owner', channel: 'c1', canManage: true),
          };
      }
      return <String, Object?>{};
    });
    const de = Locale('de');
    await tester.pumpWidget(_app(api, const GroupsScreen(), locale: de));
    await _settle(tester);
    expect(find.text('Finde deine Leute.'), findsOneWidget);
    expect(find.text('Gruppe gründen'), findsOneWidget);
    expect(find.text('EINLADUNGEN'), findsOneWidget);
    expect(
      find.text('Asha hat dich eingeladen · Private Gruppe · 4 Mitglieder'),
      findsOneWidget,
    );
    expect(find.text('Noch keine Gruppen'), findsOneWidget);
    // Group names stay as their members wrote them.
    expect(find.text('Trek planners'), findsOneWidget);
    expect(find.text('Find your people.'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _app(api, const GroupDetailScreen(groupId: 'g1'), locale: de),
    );
    await _settle(tester);
    expect(find.text('COMMUNITY-GRUPPE'), findsOneWidget);
    expect(find.text('Offen für alle'), findsOneWidget);
    expect(find.text('2 Mitglieder'), findsOneWidget);
    expect(find.text('Du leitest sie'), findsOneWidget);
    expect(find.text('WER DABEI IST'), findsOneWidget);
    expect(find.text('Leitung'), findsOneWidget);
    expect(find.text('Du'), findsOneWidget);
    expect(find.byTooltip('Verwaltung'), findsOneWidget);
  });

  testWidgets('a member opens the group chat from the detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {'group': groupJson(role: 'member', channel: 'c1')};
      }
      if (r.path == '/social/channels/c1') {
        return {
          'channel': {
            'id': 'c1',
            'kind': 'group',
            'ref_id': 'g1',
            'title': 'Koramangala readers',
            'member_count': 2,
          },
        };
      }
      if (r.path == '/social/channels/c1/read') {
        return {'read': true};
      }
      if (r.path == '/social/channels/c1/messages') {
        return {
          'messages': <Object>[],
          'has_more': false,
          'realtime_cursor': 0,
        };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.text('Koramangala readers'), findsOneWidget);
    expect(find.text('📚 Books'), findsOneWidget);
    expect(find.text('WHO’S HERE'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    // Invite is offered only when the server says the member may invite.
    expect(find.text('Invite friends'), findsNothing);

    await tester.tap(find.text('Group chat'));
    await _settle(tester);
    expect(find.byType(SocialChatScreen), findsOneWidget);
    expect(find.textContaining('Say hello to the group.'), findsOneWidget);
  });

  testWidgets('the invite picker sends invitations to chosen friends only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      switch (r.path) {
        case '/engagement/groups/g1':
          return {
            'group': groupJson(
              kind: 'private',
              name: 'Board game night',
              role: 'owner',
              channel: 'c1',
              canInvite: true,
              canManage: true,
            ),
          };
        case '/engagement/group-friends':
          expect(r.queryParameters['group_id'], 'g1');
          return {
            'friends': [
              {'user_id': 'f1', 'name': 'Asha', 'status': 'member'},
              {'user_id': 'f2', 'name': 'Dev', 'status': 'available'},
              {'user_id': 'f3', 'name': 'Meera', 'status': 'invited'},
              {'user_id': 'f4', 'name': 'Kabir', 'status': 'available'},
            ],
          };
        case '/engagement/groups/g1/invites':
          return {
            'group_id': 'g1',
            'invited_user_ids': ['f2'],
          };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    await tester.tap(find.text('Invite friends'));
    await _settle(tester);

    expect(find.text('Already in this group'), findsOneWidget);
    expect(find.text('Invitation sent'), findsOneWidget);
    // Members and pending invitees cannot be picked.
    final asha = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Asha'),
    );
    expect(asha.onChanged, isNull);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Dev'));
    await tester.pump();
    await tester.tap(find.text('Send invitations (1)'));
    await _settle(tester);

    final invite = api.posts('/engagement/groups/g1/invites').single;
    expect((invite.data as Map)['invitee_user_ids'], ['f2']);
    expect(find.text('Invitation sent to Dev.'), findsOneWidget);
  });

  testWidgets('a member who does not run the group can report it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {'group': groupJson(canJoin: true)};
      }
      if (r.path == '/blog/reports/group/g1') {
        return {
          'accepted': true,
          'report': {'id': 'case1'},
        };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byTooltip('Owner tools'), findsNothing);
    await tester.tap(find.byTooltip('More options'));
    await _settle(tester);
    await tester.tap(find.text('Report group'));
    await _settle(tester);
    await tester.tap(find.text('Submit report'));
    await _settle(tester);
    final report = api.posts('/blog/reports/group/g1').single;
    expect((report.data as Map)['reason'], 'inappropriate');
    // Android QA AND-07: the sheet used to close with no confirmation.
    expect(find.text('Report submitted. Thank you.'), findsOneWidget);
  });

  // Android QA AND-06: an owner's group was loaded alone, a friend then
  // accepted the invitation; Leave still warned that the group would be
  // deleted although the server hands it to the new member.
  testWidgets('leave warns from the current member count, not the loaded one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var members = 1;
    final api = _Api(
      (r) => {
        'group': {
          ...groupJson(
            kind: 'private',
            role: 'owner',
            channel: 'c1',
            canInvite: true,
            canManage: true,
          ),
          'member_count': members,
        },
      },
    );
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);

    members = 2; // A friend joined after the screen loaded.
    await tester.ensureVisible(find.text('Leave'));
    await tester.tap(find.text('Leave'));
    await _settle(tester);

    expect(find.textContaining('Ownership passes'), findsOneWidget);
    expect(find.textContaining('will be deleted'), findsNothing);
  });

  testWidgets('owners get owner tools instead of Report', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api(
      (r) => {
        'group': groupJson(
          role: 'owner',
          channel: 'c1',
          canInvite: true,
          canManage: true,
        ),
      },
    );
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.byTooltip('More options'), findsNothing);
    await tester.tap(find.byTooltip('Owner tools'));
    await _settle(tester);
    expect(find.text('Edit group'), findsOneWidget);
    expect(find.text('Report group'), findsNothing);
  });

  testWidgets('members of a removed group see the notice and no chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api((r) {
      if (r.path == '/engagement/groups/g1') {
        return {
          'group': {
            ...groupJson(role: 'owner', canManage: true),
            'moderation_state': 'removed',
            'removed': true,
          },
        };
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(_app(api, const GroupDetailScreen(groupId: 'g1')));
    await _settle(tester);
    expect(find.text('This group was removed after a review'), findsOneWidget);
    expect(find.textContaining('appeal'), findsOneWidget);
    expect(find.text('Group chat'), findsNothing);
    expect(find.text('Invite friends'), findsNothing);
    expect(find.text('Leave'), findsOneWidget);
    // The reviewed content cannot be edited, but the owner may delete it.
    await tester.tap(find.byTooltip('Owner tools'));
    await _settle(tester);
    expect(find.text('Edit group'), findsNothing);
    expect(find.text('Delete group'), findsOneWidget);
  });

  test('Group parses the server shape', () {
    final g = Group.fromJson(groupJson(role: 'owner', channel: 'c1'));
    expect(g.isCommunity, isTrue);
    expect(g.isMember, isTrue);
    expect(g.canModerate, isTrue);
    expect(g.emoji, '📚');
    expect(g.members, hasLength(2));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(g.memberLabel(en), '2 members');
    final p = Group.fromJson(groupJson(kind: 'private'));
    expect(p.kindLabel(en), 'Private group');
    expect(g.kindLabel(en), 'Community group');
    expect(
      Group.fromJson({...groupJson(), 'member_count': 1}).memberLabel(en),
      '1 member',
    );
    expect(groupRoleLabel(en, 'owner'), 'Owner');
    expect(groupRoleLabel(en, 'moderator'), 'Moderator');
    expect(groupRoleLabel(en, 'member'), 'Member');
    expect(groupRoleLabel(en, 'unknown'), isNull);
    expect(p.emoji, '🫶');
    expect(p.isMember, isFalse);
    expect(p.removed, isFalse);
    expect(
      Group.fromJson({...groupJson(), 'moderation_state': 'removed'}).removed,
      isTrue,
    );
  });
}
