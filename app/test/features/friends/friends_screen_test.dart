import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/friends/friend_actions.dart';
import 'package:verified_dating_app/features/friends/providers/friends_provider.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/groups/group_launch.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> _row(
  String id,
  String name,
  String status,
  String direction, {
  String source = '',
}) => {
  'friend_user_id': id,
  'friend_name': name,
  'friend_username': id,
  'friend_city': 'Pune',
  'friend_photo_url': '',
  'status': status,
  'direction': direction,
  'source': source,
  'created_at': '2026-09-30T00:00:00Z',
  'updated_at': '2026-09-30T00:00:00Z',
};

/// In-memory friends BFF: two friends, one incoming and one outgoing
/// request, one friend conversation with unread messages, and a member
/// search. Records every command.
class _FakeFriendsApi {
  final commands = <({String method, String path, Object? body})>[];
  final rows = <String, Map<String, dynamic>>{
    'meera': _row('meera', 'Meera', 'accepted', ''),
    'dev': _row('dev', 'Dev', 'accepted', ''),
    'ravi': _row('ravi', 'Ravi', 'pending', 'incoming', source: 'room'),
    'tara': _row('tara', 'Tara', 'pending', 'outgoing', source: 'match'),
  };

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          Object? data;
          if (options.method == 'GET') {
            data = switch (path) {
              '/friends/me' => {'friends': rows.values.toList()},
              '/friends/me/activities' => {'activities': <dynamic>[]},
              '/friends/me/vouches' => {
                'about_me': <dynamic>[],
                'written': <dynamic>[],
              },
              '/friends/me/intros' => {
                'received': <dynamic>[],
                'made': <dynamic>[],
              },
              '/friends/me/search' => {
                'results': [
                  {
                    'user_id': 'asha',
                    'name': 'Asha',
                    'username': 'asha.k',
                    'city': 'Goa',
                    'photo_url': '',
                    'relationship': 'none',
                  },
                ],
              },
              '/social/channels' => {
                'channels': [
                  {
                    'id': 'ch-meera',
                    'kind': 'friend',
                    'title': 'Meera',
                    'peer_id': 'meera',
                    'member_count': 2,
                    'last_message': 'See you Sunday?',
                    'unread_count': 2,
                  },
                ],
              },
              '/social/channels/ch-meera' => {
                'channel': {
                  'id': 'ch-meera',
                  'kind': 'friend',
                  'title': 'Meera',
                  'peer_id': 'meera',
                },
              },
              '/social/channels/ch-meera/messages' => {
                'messages': <dynamic>[],
                'has_more': false,
              },
              _ => null,
            };
          } else {
            commands.add((
              method: options.method,
              path: path,
              body: options.data,
            ));
            final body = options.data is Map
                ? (options.data as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            if (options.method == 'POST' && path == '/friends/me') {
              final id = body['friend_user_id'] as String;
              rows[id] = _row(
                id,
                'Asha',
                'pending',
                'outgoing',
                source: body['source'] as String? ?? '',
              );
              data = {'friend': rows[id]};
            } else if (path.endsWith('/decision')) {
              final id = path.split('/')[3];
              if (body['decision'] == 'accept') {
                rows[id] = _row(
                  id,
                  rows[id]!['friend_name'] as String,
                  'accepted',
                  '',
                );
              } else {
                rows.remove(id);
              }
              data = {'success': true, 'friend': rows[id] ?? {}};
            } else if (options.method == 'DELETE') {
              rows.remove(path.split('/').last);
              data = {'success': true};
            } else if (path == '/social/friends/meera/channel') {
              data = {
                'channel': {
                  'id': 'ch-meera',
                  'kind': 'friend',
                  'title': 'Meera',
                  'peer_id': 'meera',
                },
              };
            } else {
              data = {'success': true};
            }
          }
          if (data == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'error': 'unexpected ${options.method} $path'},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
    return dio;
  }
}

Widget _host(
  _FakeFriendsApi api, {
  Future<void> Function(BuildContext, {List<GroupInvitee> invitees})?
  createGroup,
  Locale? locale,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.build()),
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: createGroup == null
        ? const FriendsScreen()
        : FriendsScreen(createGroup: createGroup),
  ),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the friends screen in German', (tester) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api, locale: const Locale('de')));
    await tester.pumpAndSettle();

    expect(find.text('Deine Leute'), findsOneWidget);
    expect(find.text('Freund hinzufügen'), findsOneWidget);
    expect(find.text('Warten auf dich'), findsOneWidget);
    expect(find.textContaining('In einem Raum kennengelernt'), findsOneWidget);
    expect(find.text('Your people'), findsNothing);
    await tester.dragUntilVisible(
      find.text('2 Freunde'),
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    expect(find.text('2 Freunde'), findsOneWidget);
  });

  testWidgets('shows requests, chats and friends with names, not ids', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('Your people'), findsOneWidget);
    expect(find.text('Waiting on you'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.textContaining('Met in a room'), findsOneWidget);
    expect(find.text('Tara'), findsOneWidget);
    await _scrollTo(tester, find.text('See you Sunday?'));
    expect(
      find.byKey(const ValueKey('qa.friends.unread.ch-meera')),
      findsOneWidget,
    );
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('qa.friends.friend.dev')),
    );
    await tester.dragUntilVisible(
      find.text('2 friends'),
      find.byType(Scrollable).first,
      const Offset(0, 120),
    );
    expect(find.text('2 friends'), findsOneWidget);
    expect(find.text('@dev · Pune'), findsOneWidget);
    expect(find.textContaining('ID:'), findsNothing);
  });

  testWidgets('accepting and declining requests call the decision API', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    api.rows['kiran'] = _row('kiran', 'Kiran', 'pending', 'incoming');
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qa.friends.accept.ravi')));
    await tester.pumpAndSettle();
    expect(api.commands.single.path, '/friends/me/ravi/decision');
    expect((api.commands.single.body! as Map)['decision'], 'accept');
    expect(find.byKey(const ValueKey('qa.friends.accept.ravi')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('qa.friends.decline.kiran')));
    await tester.pumpAndSettle();
    final decline = api.commands.last;
    expect(decline.path, '/friends/me/kiran/decision');
    expect((decline.body! as Map)['decision'], 'decline');
    expect(find.text('Kiran'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('qa.friends.cancel.tara')));
    await tester.pumpAndSettle();
    expect(api.commands.last.method, 'DELETE');
    expect(api.commands.last.path, '/friends/me/tara');
  });

  testWidgets('Add friend searches by name and sends a request', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qa.friends.add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('qa.friends.search_field')),
      'as',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Asha'), findsNothing, reason: 'needs 3 letters');

    await tester.enterText(
      find.byKey(const ValueKey('qa.friends.search_field')),
      'ash',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('@asha.k · Goa'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qa.add_friend.asha')));
    await tester.pumpAndSettle();
    final sent = api.commands.single;
    expect(sent.path, '/friends/me');
    expect(sent.body, {'friend_user_id': 'asha', 'source': 'search'});
    expect(find.text('Friend request sent to Asha.'), findsOneWidget);
    // The row now says Requested.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('qa.add_friend.asha')),
        matching: find.text('Requested'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Message opens the friend chat', (tester) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await _scrollTo(
      tester,
      find.byKey(const ValueKey('qa.friends.message.meera')),
    );
    await tester.tap(find.byKey(const ValueKey('qa.friends.message.meera')));
    await tester.pumpAndSettle();
    expect(
      api.commands.any((c) => c.path == '/social/friends/meera/channel'),
      isTrue,
    );
    expect(find.byType(SocialChatScreen), findsOneWidget);

    // Dispose the chat so its reconnect and poll timers stop.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Create a group passes the chosen friends to Groups', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    List<GroupInvitee>? invited;
    await tester.pumpWidget(
      _host(
        api,
        createGroup: (context, {invitees = const []}) async {
          invited = invitees;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qa.friends.create_group')));
    await tester.pumpAndSettle();
    expect(find.text('Who’s in?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.friends.group_pick.dev')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.friends.group_continue')));
    await tester.pumpAndSettle();

    expect(invited, isNotNull);
    expect(invited!.map((i) => i.userId), ['dev']);
    expect(invited!.single.name, 'Dev');
  });

  testWidgets('filled screen meets tap target, label and contrast checks', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('friend rows parse the card and the request source', () {
    final f = FriendConnection.fromJson(
      _row('ravi', 'Ravi', 'pending', 'incoming', source: 'group'),
    );
    expect(f.isIncoming, isTrue);
    expect(f.isOutgoing, isFalse);
    expect(f.username, 'ravi');
    expect(f.source, 'group');
    expect(FriendRequestSource.values.map((s) => s.name), [
      'search',
      'match',
      'profile',
      'room',
      'group',
    ]);
  });
}
