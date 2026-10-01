import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_data.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Chat mutes: a member muted in a room reads along with the composer closed
/// and the reason shown; any member can mute a friend or group chat's
/// notifications from the bell.

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  _Api(this.channel);

  /// The channel GET /social/channels/c1 returns; PUT/DELETE mute update it.
  Map<String, dynamic> channel;
  final requests = <RequestOptions>[];

  Iterable<RequestOptions> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          requests.add(r);
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: _answer(r),
            ),
          );
        },
      ),
    );

  Object? _answer(RequestOptions r) {
    switch ('${r.method} ${r.path}') {
      case 'GET /social/channels/c1':
        return {'channel': channel};
      case 'PUT /social/channels/c1/mute':
        final forever = (r.data as Map)['duration'] == 'forever';
        channel = {
          ...channel,
          'muted': true,
          'muted_until': forever ? null : '2099-01-01T08:00:00Z',
        };
        return {'channel': channel, 'muted': true};
      case 'DELETE /social/channels/c1/mute':
        channel = {...channel, 'muted': false, 'muted_until': null};
        return {'channel': channel, 'muted': false};
      case 'GET /social/channels/c1/messages':
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

Map<String, dynamic> _channel({
  String kind = 'friend',
  bool readOnly = false,
  String? readOnlyUntil,
}) => {
  'id': 'c1',
  'kind': kind,
  'title': kind == 'room' ? 'Late-night talks' : 'Asha',
  'member_count': kind == 'room' ? 5 : 2,
  'can_moderate': false,
  'unread_count': 0,
  'read_only': readOnly,
  'read_only_until': readOnlyUntil,
  'muted': false,
  'muted_until': null,
};

Future<void> _mount(WidgetTester tester, _Api api, {Locale? locale}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(api.dio),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SocialChatScreen(channelId: 'c1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Disposes the chat (socket retry and mute timers) before the test ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

TextField _input(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(const ValueKey('social.chat.input')));

IconButton _send(WidgetTester tester) =>
    tester.widget<IconButton>(find.byKey(const ValueKey('social.chat.send')));

void main() {
  testWidgets('a member muted in a room reads along with the composer closed', (
    tester,
  ) async {
    final until = DateTime.now().add(const Duration(minutes: 10));
    final api = _Api(
      _channel(
        kind: 'room',
        readOnly: true,
        readOnlyUntil: until.toUtc().toIso8601String(),
      ),
    );
    await _mount(tester, api);

    // Messages still show; the composer is closed and says why and until when.
    expect(find.text('Anyone else up?'), findsOneWidget);
    expect(find.byKey(const ValueKey('social.chat.read_only')), findsOneWidget);
    final time = TimeOfDay.fromDateTime(
      until,
    ).format(tester.element(find.byType(SocialChatScreen)));
    expect(
      find.text(
        'You’re muted in this room until $time. You can still read along.',
      ),
      findsOneWidget,
    );
    expect(_input(tester).enabled, isFalse);
    expect(_input(tester).decoration?.hintText, 'You can’t post right now');
    expect(_send(tester).onPressed, isNull);
    // Rooms never notify, so they have no notification bell.
    expect(find.byKey(const ValueKey('social.chat.mute')), findsNothing);

    // Unmuted (a realtime event or the mute ending triggers a refresh): the
    // composer opens again.
    api.channel = _channel(kind: 'room');
    await tester.runAsync(
      () => ProviderScope.containerOf(
        tester.element(find.byType(SocialChatScreen)),
      ).read(socialChatProvider('c1').notifier).refresh(quiet: true),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('social.chat.read_only')), findsNothing);
    expect(_input(tester).enabled, isTrue);
    expect(_input(tester).decoration?.hintText, 'Write a message');
    await _unmount(tester);
  });

  testWidgets('the bell mutes a friend chat’s notifications and turns them '
      'back on', (tester) async {
    final api = _Api(_channel());
    await _mount(tester, api);

    final bell = find.byKey(const ValueKey('social.chat.mute'));
    expect(bell, findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    await tester.tap(bell);
    await tester.pumpAndSettle();
    expect(find.text('Mute notifications'), findsWidgets);
    expect(find.text('For 1 hour'), findsOneWidget);
    expect(find.text('For 8 hours'), findsOneWidget);
    expect(find.text('For 1 week'), findsOneWidget);
    expect(find.text('Until I turn it back on'), findsOneWidget);
    expect(find.byKey(const ValueKey('social.mute.off')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('social.mute.8h')));
    await tester.pumpAndSettle();
    final put = api.calls('PUT', '/social/channels/c1/mute').single;
    expect((put.data as Map)['duration'], '8h');
    expect(find.text('Notifications muted.'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);

    // Muted: the sheet offers to turn notifications back on.
    await tester.tap(bell);
    await tester.pumpAndSettle();
    expect(find.textContaining('Muted until'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('social.mute.off')));
    await tester.pumpAndSettle();
    expect(api.calls('DELETE', '/social/channels/c1/mute'), hasLength(1));
    expect(find.text('Notifications are back on.'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Until I turn it back on.
    await tester.tap(bell);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social.mute.forever')));
    await tester.pumpAndSettle();
    expect(
      (api.calls('PUT', '/social/channels/c1/mute').last.data
          as Map)['duration'],
      'forever',
    );
    await _unmount(tester);
  });

  testWidgets('the chat and the mute sheet speak German', (tester) async {
    final api = _Api(_channel(kind: 'group'));
    await _mount(tester, api, locale: const Locale('de'));
    expect(find.text('5 Mitglieder'), findsNothing);
    expect(find.text('2 Mitglieder'), findsOneWidget);
    expect(_input(tester).decoration?.hintText, 'Schreib eine Nachricht');
    await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
    await tester.pumpAndSettle();
    expect(find.text('Benachrichtigungen stummschalten'), findsWidgets);
    expect(find.text('Bis ich sie wieder einschalte'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _unmount(tester);
  });

  test('channels parse mute and read-only state', () {
    final c = SocialChannel.fromJson({
      'id': 'c1',
      'kind': 'room',
      'title': 'Room',
      'read_only': true,
      'read_only_until': '2026-10-01T16:00:00Z',
      'read_only_message': 'You’re muted in this room',
      'muted': true,
      'muted_until': null,
    });
    expect(c.readOnly, isTrue);
    expect(c.readOnlyUntil, isNotNull);
    expect(c.muted, isTrue);
    expect(c.mutedUntil, isNull);
    expect(c.canMuteNotifications, isFalse);
    expect(c.withMute(muted: false).muted, isFalse);
    expect(SocialMuteDuration.untilTurnedOn.api, 'forever');
  });
}
