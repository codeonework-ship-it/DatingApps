import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/conversation_rooms_provider.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> roomJson(
  String id,
  String title, {
  String category = 'talk',
  int here = 0,
  int members = 0,
  String role = '',
  String channel = '',
}) => {
  'id': id,
  'slug': id,
  'title': title,
  'theme': title,
  'description': 'About $title',
  'category': category,
  'icon_key': 'night',
  'room_type': 'topic',
  'always_on': true,
  'lifecycle_state': 'active',
  'starts_at': '2026-10-01T00:00:00Z',
  'ends_at': null,
  'capacity': 200,
  'participant_count': members,
  'here_now': here,
  'friends_here': 0,
  'is_participant': role.isNotEmpty,
  'my_role': role,
  'can_moderate': role == 'host' || role == 'moderator',
  'is_host': false,
  'host_name': '',
  if (channel.isNotEmpty) 'channel_id': channel,
};

/// A fake API: two always-on rooms; joining Late-night talks opens chat c1
/// with one message from Asha; the room has Asha and a host, Ravi.
class _Api {
  _Api({this.myRole = 'participant', this.ashaMutedUntil}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          h.resolve(
            Response<dynamic>(
              requestOptions: o,
              statusCode: 200,
              data: _answer(o),
            ),
          );
        },
      ),
    );
  }

  final String myRole;

  /// Asha's mute, as hosts and moderators see it.
  final String? ashaMutedUntil;
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  final requests = <RequestOptions>[];

  Iterable<RequestOptions> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);

  Object _answer(RequestOptions o) {
    final joined = roomJson(
      'r1',
      'Late-night talks',
      here: 3,
      members: 5,
      role: myRole,
      channel: 'c1',
    );
    switch (o.path) {
      case '/rooms':
        return {
          'rooms': [
            roomJson('r1', 'Late-night talks', here: 3, members: 5),
            roomJson('r2', "Bookworms' corner", category: 'interests'),
          ],
        };
      case '/rooms/r1/join':
      case '/rooms/r1/presence':
      case '/rooms/r1/moderate':
        return {'room': joined, 'channel_id': 'c1', 'here_now': 3};
      case '/rooms/r1/members':
        return {
          'members': [
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
              if (ashaMutedUntil != null) 'muted_until': ashaMutedUntil,
            },
            {
              'user_id': 'me',
              'name': 'Me',
              'role': myRole,
              'here_now': true,
              'is_me': true,
              'friend_status': 'me',
            },
          ],
        };
      case '/social/channels/c1':
        return {
          'channel': {
            'id': 'c1',
            'kind': 'room',
            'ref_id': 'r1',
            'title': 'Late-night talks',
            'member_count': 3,
            'can_moderate': myRole == 'host',
          },
        };
      case '/social/channels/c1/messages':
        return {
          'messages': [
            {
              'id': 'm1',
              'channel_id': 'c1',
              'sender_id': 'asha',
              'sender_name': 'Asha',
              'sender_photo_url': '',
              'body': 'Anyone else up?',
              'client_message_id': 'client-m1',
              'created_at': '2026-10-01T22:00:00Z',
              'deleted': false,
              'mine': false,
            },
          ],
          'has_more': false,
          'realtime_cursor': 0,
        };
    }
    return <String, dynamic>{};
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Api api, {
  ThemeData? theme,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api.dio),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
      child: MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: locale == null
            ? null
            : AppLocalizations.localizationsDelegates,
        supportedLocales: locale == null
            ? const [Locale('en', 'US')]
            : AppLocalizations.supportedLocales,
        home: const ConversationRoomsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterLateNight(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('rooms.tile.r1')).first);
  await tester.pumpAndSettle();
}

/// Disposes the chat (its socket retry and heartbeat timers) before the test
/// ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('lists the always-on rooms with live presence', (tester) async {
    final api = _Api();
    await _mount(tester, api);

    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('LIVE NOW'), findsOneWidget);
    expect(find.text('Late-night talks'), findsWidgets);
    expect(find.text("Bookworms' corner"), findsOneWidget);
    expect(find.textContaining('3 here now'), findsWidgets);
    expect(find.text('3 people chatting in 1 room'), findsOneWidget);
    expect(api.calls('GET', '/rooms'), isNotEmpty);

    // Topic chips filter the browse list.
    await tester.tap(find.byKey(const ValueKey('rooms.category.interests')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rooms.tile.r2')), findsOneWidget);
    // Late-night talks stays in Live now, but leaves the browse list.
    expect(find.byKey(const ValueKey('rooms.tile.r1')), findsOneWidget);
  });

  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  }.entries) {
    testWidgets('the populated rooms list meets accessibility guidelines '
        '[${entry.key}]', (tester) async {
      final handle = tester.ensureSemantics();
      await _mount(tester, _Api(), theme: entry.value);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('tapping a room joins it and opens its chat', (tester) async {
    final api = _Api();
    await _mount(tester, api);
    await _enterLateNight(tester);

    expect(api.calls('POST', '/rooms/r1/join'), hasLength(1));
    expect(find.byType(SocialChatScreen), findsOneWidget);
    expect(find.text('Anyone else up?'), findsOneWidget);
    expect(api.calls('POST', '/rooms/r1/presence'), isNotEmpty);
    expect(find.byKey(const ValueKey('room.chat.presence')), findsOneWidget);
    expect(find.text('3 here now · 5 in the room'), findsOneWidget);

    // Leaving the chat screen tells the server the member is away.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      api
          .calls('POST', '/rooms/r1/presence')
          .where((r) => (r.data as Map)['state'] == 'away'),
      isNotEmpty,
    );
    await _unmount(tester);
  });

  testWidgets('members sheet offers Add friend and hides moderation', (
    tester,
  ) async {
    final api = _Api();
    await _mount(tester, api);
    await _enterLateNight(tester);

    await tester.tap(find.byKey(const ValueKey('room.chat.people')));
    await tester.pumpAndSettle();
    expect(api.calls('GET', '/rooms/r1/members'), isNotEmpty);
    expect(find.text('People here'), findsOneWidget);
    expect(find.text('Asha'), findsWidgets);
    expect(find.text('Host · Here now'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.add_friend.asha')), findsOneWidget);
    // No Add friend for yourself.
    expect(find.byKey(const ValueKey('qa.add_friend.me')), findsNothing);

    // Asha's card: Add friend, report and block; no moderation.
    await tester.tap(find.byKey(const ValueKey('room.member.asha')));
    await tester.pumpAndSettle();
    expect(find.text('Add friend'), findsOneWidget);
    expect(find.byKey(const ValueKey('room.member.report')), findsOneWidget);
    expect(find.byKey(const ValueKey('room.member.block')), findsOneWidget);
    expect(find.byKey(const ValueKey('room.member.warn')), findsNothing);
    expect(find.byKey(const ValueKey('room.member.remove')), findsNothing);

    // Adding a friend sends a request that says it started in a room.
    await tester.tap(find.text('Add friend'));
    await tester.pumpAndSettle();
    final request = api.calls('POST', '/friends/me').single;
    expect((request.data as Map)['source'], 'room');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // A participant's menu has no Moderate.
    await tester.tap(find.byKey(const ValueKey('room.chat.menu')));
    await tester.pumpAndSettle();
    expect(find.text('Leave room'), findsOneWidget);
    expect(find.text('Moderate'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('a host can warn a participant with warn_user', (tester) async {
    final api = _Api(myRole: 'host');
    await _mount(tester, api);
    await _enterLateNight(tester);

    await tester.tap(find.byKey(const ValueKey('room.chat.menu')));
    await tester.pumpAndSettle();
    expect(find.text('Moderate'), findsOneWidget);
    await tester.tap(find.text('Moderate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room.member.asha')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room.member.warn')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room.member.warn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send warning'));
    await tester.pumpAndSettle();

    final body = api.calls('POST', '/rooms/r1/moderate').single.data as Map;
    expect(body['action'], 'warn_user');
    expect(body['target_user_id'], 'asha');
    expect(body.containsKey('moderator_user_id'), isFalse);
    expect(find.text('Warning sent to Asha.'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a host mutes a participant for an hour with mute_user', (
    tester,
  ) async {
    final api = _Api(myRole: 'host');
    await _mount(tester, api);
    await _enterLateNight(tester);

    await tester.tap(find.byKey(const ValueKey('room.chat.menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moderate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('room.member.asha')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room.member.unmute')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('room.member.mute')));
    await tester.pumpAndSettle();
    expect(find.text('Mute Asha?'), findsOneWidget);
    expect(find.text('For 10 minutes'), findsOneWidget);
    // An always-on room's longest mute is a day.
    expect(find.text('For 24 hours'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room.mute.1h')));
    await tester.pumpAndSettle();

    final body = api.calls('POST', '/rooms/r1/moderate').single.data as Map;
    expect(body['action'], 'mute_user');
    expect(body['duration'], '1h');
    expect(body['target_user_id'], 'asha');
    expect(find.text('Asha is muted.'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a muted member shows as muted with Unmute for the host', (
    tester,
  ) async {
    final until = DateTime.now().add(const Duration(minutes: 30));
    final api = _Api(
      myRole: 'host',
      ashaMutedUntil: until.toUtc().toIso8601String(),
    );
    await _mount(tester, api);
    await _enterLateNight(tester);
    await tester.tap(find.byKey(const ValueKey('room.chat.people')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Muted until'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('room.member.asha')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('room.member.mute')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('room.member.unmute')));
    await tester.pumpAndSettle();
    final body = api.calls('POST', '/rooms/r1/moderate').single.data as Map;
    expect(body['action'], 'unmute_user');
    expect(find.text('Asha can post again.'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('rooms render in German', (tester) async {
    final api = _Api();
    await _mount(tester, api, locale: const Locale('de'));

    expect(find.text('Räume'), findsOneWidget);
    expect(find.text('LIVE-CHAT'), findsOneWidget);
    expect(find.text('GERADE LIVE'), findsOneWidget);
    expect(find.text('3 Personen chatten in 1 Raum'), findsOneWidget);
    expect(find.text('Raum starten'), findsOneWidget);
    expect(find.text('Interessen'), findsOneWidget);
    expect(find.text('Freunde da'), findsOneWidget);
    expect(find.textContaining('3 gerade da'), findsWidgets);
    expect(find.text('Rooms'), findsNothing);
    expect(find.text('Start a room'), findsNothing);

    // The room chat: presence band, composer and menu in German too.
    await _enterLateNight(tester);
    expect(find.text('3 gerade da · 5 im Raum'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('social.chat.input')))
          .decoration
          ?.hintText,
      'Schreib eine Nachricht',
    );
    await tester.tap(find.byKey(const ValueKey('room.chat.menu')));
    await tester.pumpAndSettle();
    expect(find.text('Wer da ist'), findsOneWidget);
    expect(find.text('Raum verlassen'), findsOneWidget);
    await _unmount(tester);
  });

  test('room errors carry the server code', () {
    const removed = RoomActionException(
      'Removed',
      code: 'ROOM_BLOCKED_ACTIVE_SESSION',
    );
    expect(removed.endsVisit, isTrue);
    expect(
      const RoomActionException(
        'Full',
        code: 'ROOM_CAPACITY_REACHED',
      ).endsVisit,
      isFalse,
    );
  });
}
