import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_data.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> messageJson(
  String id, {
  String sender = 'friend',
  String body = 'Hello',
  String clientId = '',
  String at = '2026-10-01T09:00:00Z',
  bool deleted = false,
}) => {
  'id': id,
  'channel_id': 'c1',
  'sender_id': sender,
  'sender_name': sender == 'me' ? 'Me' : 'Asha',
  'sender_photo_url': '',
  'body': deleted ? '' : body,
  'client_message_id': clientId.isEmpty ? 'client-$id' : clientId,
  'created_at': at,
  'deleted': deleted,
  'mine': sender == 'me',
};

Map<String, dynamic> channelJson({String kind = 'friend', bool mod = false}) =>
    {
      'id': 'c1',
      'kind': kind,
      'title': kind == 'friend' ? 'Asha' : 'Bookworms',
      'member_count': kind == 'friend' ? 2 : 12,
      'can_moderate': mod,
      'unread_count': 0,
    };

typedef _Handler = FutureOr<Object?> Function(RequestOptions r);

class _Api {
  _Api(this.handler);
  final _Handler handler;
  final requests = <RequestOptions>[];
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          requests.add(r);
          try {
            h.resolve(
              Response<dynamic>(
                requestOptions: r,
                statusCode: 200,
                data: await handler(r),
              ),
            );
          } on int catch (status) {
            h.reject(
              DioException(
                requestOptions: r,
                response: Response<dynamic>(
                  requestOptions: r,
                  statusCode: status,
                  data: {'error': 'Try again later.'},
                ),
              ),
            );
          }
        },
      ),
    );
}

void main() {
  group('mergeSocialMessages', () {
    test('orders by time and replaces a confirmed optimistic send', () {
      final optimistic = SocialMessage(
        id: 'local-x',
        channelId: 'c1',
        senderId: 'me',
        body: 'Hi',
        clientMessageId: 'x',
        createdAt: DateTime.utc(2026, 10, 1, 10),
        mine: true,
        pending: true,
      );
      final older = SocialMessage.fromJson(messageJson('m1'));
      final confirmed = SocialMessage.fromJson(
        messageJson(
          'm2',
          sender: 'me',
          body: 'Hi',
          clientId: 'x',
          at: '2026-10-01T10:00:01Z',
        ),
      );
      final merged = mergeSocialMessages([optimistic], [confirmed, older]);
      expect(merged.map((m) => m.id), ['m1', 'm2']);
      expect(merged.last.pending, isFalse);
    });
  });

  group('SocialChat', () {
    test('sends optimistically, marks failures and retries with the same '
        'client id', () async {
      var failSend = true;
      final api = _Api((r) {
        if (r.path == '/social/channels/c1') return {'channel': channelJson()};
        if (r.path == '/social/channels/c1/read') return {'read': true};
        if (r.method == 'POST' && r.path.endsWith('/messages')) {
          if (failSend) throw 503;
          final data = r.data as Map;
          return {
            'message': messageJson(
              'm9',
              sender: 'me',
              body: data['body'] as String,
              clientId: data['client_message_id'] as String,
              at: DateTime.now().toUtc().toIso8601String(),
            ),
          };
        }
        return {
          'messages': [messageJson('m1')],
          'has_more': false,
          'realtime_cursor': 7,
        };
      });
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(socialChatProvider('c1'), (_, _) {});
      addTearDown(sub.close);
      final chat = container.read(socialChatProvider('c1').notifier);
      await chat.refresh();
      expect(container.read(socialChatProvider('c1')).messages, hasLength(1));
      expect(container.read(socialChatProvider('c1')).channel?.title, 'Asha');

      await expectLater(chat.send('  Coffee?  '), throwsA(isA<DioException>()));
      final failed = container.read(socialChatProvider('c1')).messages.last;
      expect(failed.failed, isTrue);
      expect(failed.body, 'Coffee?');

      failSend = false;
      await chat.retry(failed);
      final messages = container.read(socialChatProvider('c1')).messages;
      expect(messages, hasLength(2));
      expect(messages.last.id, 'm9');
      expect(messages.last.failed, isFalse);
      final posts = api.requests
          .where((r) => r.method == 'POST' && r.path.endsWith('/messages'))
          .toList();
      expect(posts, hasLength(2));
      expect(
        (posts.first.data as Map)['client_message_id'],
        (posts.last.data as Map)['client_message_id'],
      );
    });
  });

  testWidgets('group chat shows sender names and the sender action', (
    tester,
  ) async {
    final api = _Api((r) {
      if (r.path == '/social/channels/c1') {
        return {'channel': channelJson(kind: 'room')};
      }
      if (r.path == '/social/channels/c1/read') return {'read': true};
      return {
        'messages': [
          messageJson('m1', body: 'Anyone reading Murakami?'),
          messageJson(
            'm2',
            sender: 'me',
            body: 'Yes!',
            at: '2026-10-01T09:01:00Z',
          ),
        ],
        'has_more': false,
        'realtime_cursor': 3,
      };
    });
    String? tapped;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
        child: MaterialApp(
          home: SocialChatScreen(
            channelId: 'c1',
            onSenderTap: (context, m) => tapped = m.senderId,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Bookworms'), findsOneWidget);
    expect(find.text('12 members'), findsOneWidget);
    expect(find.text('Anyone reading Murakami?'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    await tester.tap(find.text('Asha'));
    expect(tapped, 'friend');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
