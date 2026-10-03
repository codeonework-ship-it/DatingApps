import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

// Shared chat (friend, room and group conversations): every control on the
// screen, its message actions and its mute sheet, asserting the request the
// server receives and what the member sees next — and what happens when the
// server refuses.

final _en = qaL10n(const Locale('en'));

Map<String, dynamic> _message(
  String id, {
  String sender = 'asha',
  String name = 'Asha',
  String body = 'Hello',
  String at = '2026-10-01T09:00:00Z',
  bool deleted = false,
  String? clientId,
}) => {
  'id': id,
  'channel_id': 'c1',
  'sender_id': sender,
  'sender_name': name,
  'sender_photo_url': '',
  'body': deleted ? '' : body,
  'client_message_id': clientId ?? 'client-$id',
  'created_at': at,
  'deleted': deleted,
  'mine': sender == 'me',
};

/// A stateful fake of `/social/channels/c1`: a group chat "Bookworms" with a
/// message from Asha and one of mine.
class _ChatWorld {
  _ChatWorld({String kind = 'group', bool moderator = false}) {
    channel = {
      'id': 'c1',
      'kind': kind,
      'title': 'Bookworms',
      'member_count': 12,
      'can_moderate': moderator,
      'unread_count': 0,
      'muted': false,
      'muted_until': null,
    };
    api
      ..on('GET /social/channels/c1', (_) => qaOk({'channel': channel}))
      ..on(
        'GET /social/channels/c1/messages',
        (_) => qaOk({
          'messages': messages,
          'has_more': false,
          'realtime_cursor': 1,
        }),
      )
      ..on('POST /social/channels/c1/read', (_) => qaOk({'read': true}))
      ..on('POST /social/channels/c1/messages', (c) {
        final m = _message(
          'm${messages.length + 1}',
          sender: 'me',
          name: 'Priya',
          body: c.body['body'] as String,
          clientId: c.body['client_message_id'] as String,
          at: DateTime.now().toUtc().toIso8601String(),
        );
        messages.add(m);
        return qaOk({'message': m});
      })
      ..on('DELETE /social/channels/c1/messages/*', (c) {
        final id = c.path.split('/').last;
        final i = messages.indexWhere((m) => m['id'] == id);
        messages[i] = {...messages[i], 'deleted': true, 'body': ''};
        return qaOk({'deleted': true});
      })
      ..on('PUT /social/channels/c1/mute', (c) {
        final forever = c.body['duration'] == 'forever';
        channel = {
          ...channel,
          'muted': true,
          'muted_until': forever ? null : '2099-01-01T08:00:00Z',
        };
        return qaOk({'channel': channel, 'muted': true});
      })
      ..on('DELETE /social/channels/c1/mute', (_) {
        channel = {...channel, 'muted': false, 'muted_until': null};
        return qaOk({'channel': channel, 'muted': false});
      })
      ..on(
        'POST /blog/reports/social_message/*',
        (_) => qaOk({
          'accepted': true,
          'report': {'id': 'case-7'},
        }),
      );
  }

  final api = QaApi();
  late Map<String, dynamic> channel;
  final messages = <Map<String, dynamic>>[
    _message('m1', body: 'Anyone reading Murakami?'),
    _message(
      'm2',
      sender: 'me',
      name: 'Priya',
      body: 'Yes, Kafka on the Shore!',
      at: '2026-10-01T09:01:00Z',
    ),
  ];
}

SocialChatScreen _screen({SocialSenderTap? onSenderTap}) => SocialChatScreen(
  channelId: 'c1',
  title: 'Bookworms',
  onSenderTap: onSenderTap,
);

Future<void> _open(
  WidgetTester tester,
  _ChatWorld world, {
  SocialSenderTap? onSenderTap,
  Locale? locale,
}) => pumpQa(
  tester,
  world.api,
  _screen(onSenderTap: onSenderTap),
  locale: locale,
).then((_) {});

Future<void> _longPress(WidgetTester tester, String text) async {
  await tester.longPress(find.text(text));
  await tester.pumpAndSettle();
}

Finder _action(String name) =>
    find.byKey(ValueKey('qa.social_chat.action.$name'));

Future<void> _done(WidgetTester tester) => qaUnmountScreen(tester);

void main() {
  group('message actions', () {
    testWidgets('long-press opens the actions for that message: copy, report '
        'and the sender for someone else\'s, delete for mine '
        '[case:social_chat.social_chat.social_message_x_longpress.action]', (
      tester,
    ) async {
      final world = _ChatWorld();
      await _open(tester, world, onSenderTap: (_, _) {});

      await _longPress(tester, 'Anyone reading Murakami?');
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_action('copy'), findsOneWidget);
      expect(_action('report'), findsOneWidget);
      expect(_action('sender'), findsOneWidget);
      expect(_action('delete'), findsNothing, reason: 'not a moderator');
      expect(_action('retry'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      await _longPress(tester, 'Yes, Kafka on the Shore!');
      expect(_action('copy'), findsOneWidget);
      expect(find.text(_en.chatDeleteMine), findsOneWidget);
      expect(_action('report'), findsNothing, reason: 'my own message');
      expect(_action('sender'), findsNothing);
      // Opening the sheet sends nothing.
      expect(world.api.writes.where((c) => !c.path.endsWith('/read')), isEmpty);
      await _done(tester);
    });

    testWidgets('Copy text puts the message on the clipboard and says so '
        '[case:social_chat.social_chat.social_chat_action_copy.action]', (
      tester,
    ) async {
      final copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final world = _ChatWorld();
      await _open(tester, world);
      await _longPress(tester, 'Anyone reading Murakami?');
      await tester.tap(_action('copy'));
      await tester.pumpAndSettle();
      expect(copied, [
        {'text': 'Anyone reading Murakami?'},
      ]);
      expect(qaSnackText(tester), _en.chatCopied);
      expect(find.byType(BottomSheet), findsNothing);
      await _done(tester);
    });

    testWidgets(
      'Delete my message deletes it on the server and shows it as '
      'removed [case:social_chat.social_chat.social_chat_action_delete.action]',
      (tester) async {
        final world = _ChatWorld();
        await _open(tester, world);
        await _longPress(tester, 'Yes, Kafka on the Shore!');
        await tester.tap(_action('delete'));
        await qaSettle(tester);
        expect(
          world.api.sent('DELETE', '/social/channels/c1/messages/m2'),
          hasLength(1),
        );
        expect(find.text('Yes, Kafka on the Shore!'), findsNothing);
        expect(find.text(_en.chatMessageRemoved), findsOneWidget);
        expect(find.text('Anyone reading Murakami?'), findsOneWidget);
        await _done(tester);
      },
    );

    testWidgets(
      'a moderator removes someone else\'s message with Remove '
      'message [case:social_chat.social_chat.social_chat_action_delete.action]',
      (tester) async {
        final world = _ChatWorld(moderator: true);
        await _open(tester, world);
        await _longPress(tester, 'Anyone reading Murakami?');
        expect(find.text(_en.chatRemoveMessage), findsOneWidget);
        await tester.tap(_action('delete'));
        await qaSettle(tester);
        expect(
          world.api.sent('DELETE', '/social/channels/c1/messages/m1'),
          hasLength(1),
        );
        expect(find.text('Anyone reading Murakami?'), findsNothing);
        expect(find.text(_en.chatMessageRemoved), findsOneWidget);
        await _done(tester);
      },
    );

    testWidgets(
      'a delete the server refuses says so and keeps the message '
      '[case:social_chat.social_chat.social_message_x_longpress.api_failure]',
      (tester) async {
        final world = _ChatWorld();
        await _open(tester, world);
        world.api.on(
          'DELETE /social/channels/c1/messages/*',
          (_) => const QaReply(500, <String, dynamic>{}),
        );
        await _longPress(tester, 'Yes, Kafka on the Shore!');
        await tester.tap(_action('delete'));
        await qaSettle(tester);
        expect(
          world.api.sent('DELETE', '/social/channels/c1/messages/m2'),
          hasLength(1),
        );
        expect(qaSnackText(tester), _en.chatDeleteFailed);
        expect(find.text('Yes, Kafka on the Shore!'), findsOneWidget);
        expect(find.text(_en.chatMessageRemoved), findsNothing);

        // Offline: the member is told they are offline, the message stays.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        world.api.offline('DELETE /social/channels/c1/messages/*');
        await _longPress(tester, 'Yes, Kafka on the Shore!');
        await tester.tap(_action('delete'));
        await qaSettle(tester);
        expect(qaSnackText(tester), _en.networkOfflineTryAgain);
        expect(find.text('Yes, Kafka on the Shore!'), findsOneWidget);
        await _done(tester);
      },
    );

    testWidgets('Report message sends the report for that message and '
        'confirms '
        '[case:social_chat.social_chat.social_chat_action_report.action]', (
      tester,
    ) async {
      final world = _ChatWorld();
      await _open(tester, world);
      await _longPress(tester, 'Anyone reading Murakami?');
      await tester.tap(_action('report'));
      await tester.pumpAndSettle();
      expect(find.text(_en.reportSheetTitle), findsWidgets);
      await tester.enterText(
        find.widgetWithText(TextField, _en.reportDescriptionLabel),
        'Spam link',
      );
      await tester.tap(find.text(_en.reportSubmit));
      await qaSettle(tester);
      final report = world.api.sent('POST', '/blog/reports/social_message/m1');
      expect(report, hasLength(1));
      expect(report.single.body, {
        'reason': 'inappropriate',
        'description': 'Spam link',
      });
      expect(qaSnackText(tester), _en.communityReportSubmitted);
      expect(find.text(_en.reportSheetTitle), findsNothing);
      await _done(tester);
    });

    testWidgets('the sender action hands the message to the opener (a name '
        'opens Add friend, a profile...) '
        '[case:social_chat.social_chat.social_chat_action_sender.action]', (
      tester,
    ) async {
      final world = _ChatWorld();
      final tapped = <String>[];
      await _open(
        tester,
        world,
        onSenderTap: (_, m) => tapped.add('${m.senderId}:${m.id}'),
      );
      await _longPress(tester, 'Anyone reading Murakami?');
      expect(
        find.descendant(of: _action('sender'), matching: find.text('Asha')),
        findsOneWidget,
      );
      await tester.tap(_action('sender'));
      await tester.pumpAndSettle();
      expect(tapped, ['asha:m1']);
      expect(find.byType(BottomSheet), findsNothing);
      await _done(tester);
    });

    testWidgets('a sender without a name is offered as This member, and '
        'choosing it still reaches the opener '
        '[case:social_chat.social_chat.this_member.action]', (tester) async {
      final world = _ChatWorld();
      world.messages[0] = _message('m1', name: '', body: 'Who is in?');
      final tapped = <String>[];
      await _open(tester, world, onSenderTap: (_, m) => tapped.add(m.senderId));
      await _longPress(tester, 'Who is in?');
      final tile = find.descendant(
        of: _action('sender'),
        matching: find.text(_en.chatThisMember),
      );
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(tapped, ['asha']);
      await _done(tester);
    });

    testWidgets('a failed send shows Not sent; Try sending again resends with '
        'the same client id and the message goes through '
        '[case:social_chat.social_chat.social_chat_action_retry.action]', (
      tester,
    ) async {
      final world = _ChatWorld();
      await _open(tester, world);
      world.api.offline('POST /social/channels/c1/messages');
      await tester.enterText(
        find.byKey(const ValueKey('social.chat.input')),
        'Coffee after?',
      );
      await tester.tap(find.byKey(const ValueKey('social.chat.send')));
      await qaSettle(tester);
      expect(find.text('Coffee after?'), findsOneWidget);
      expect(find.text(_en.chatStatusNotSent), findsOneWidget);
      final first = world.api.sent('POST', '/social/channels/c1/messages');
      expect(first, hasLength(1));
      final clientId = first.single.body['client_message_id'];

      // Back online.
      world.api.on('POST /social/channels/c1/messages', (c) {
        final m = _message(
          'm3',
          sender: 'me',
          name: 'Priya',
          body: c.body['body'] as String,
          clientId: c.body['client_message_id'] as String,
          at: DateTime.now().toUtc().toIso8601String(),
        );
        world.messages.add(m);
        return qaOk({'message': m});
      });
      await _longPress(tester, 'Coffee after?');
      expect(find.text(_en.chatRetrySend), findsOneWidget);
      await tester.tap(_action('retry'));
      await qaSettle(tester);
      final posts = world.api.sent('POST', '/social/channels/c1/messages');
      expect(posts, hasLength(2));
      expect(posts.last.body, {
        'body': 'Coffee after?',
        'client_message_id': clientId,
      });
      expect(find.text(_en.chatStatusNotSent), findsNothing);
      expect(find.text('Coffee after?'), findsOneWidget);
      await _done(tester);
    });
  });

  testWidgets(
    'a conversation that cannot be opened offers Try again, which '
    'loads it [case:social_chat.social_chat.social_chat_retry_retry.action]',
    (tester) async {
      final world = _ChatWorld();
      world.api.on(
        'GET /social/channels/c1',
        (_) => const QaReply(403, <String, dynamic>{}),
      );
      await _open(tester, world);
      expect(find.text(_en.chatUnavailable), findsOneWidget);
      final input = tester.widget<TextField>(
        find.byKey(const ValueKey('social.chat.input')),
      );
      expect(input.enabled, isFalse, reason: 'no composer without the chat');

      world.api.on(
        'GET /social/channels/c1',
        (_) => qaOk({'channel': world.channel}),
      );
      final before = world.api.sent('GET', '/social/channels/c1').length;
      await tester.tap(find.byKey(const ValueKey('qa.social_chat.retry')));
      await qaSettle(tester);
      expect(world.api.sent('GET', '/social/channels/c1').length, before + 1);
      expect(find.text(_en.chatUnavailable), findsNothing);
      expect(find.text('Anyone reading Murakami?'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('social.chat.input')))
            .enabled,
        isTrue,
      );
      await _done(tester);
    },
  );

  group('mute notifications', () {
    testWidgets('the bell opens the mute sheet and For 1 hour / 8 hours / 1 '
        'week each send that duration and mute the chat '
        '[case:social_chat.social_chat.social_chat_mute.action] '
        '[case:social_chat.social_chat.social_mute_x.action]', (tester) async {
      for (final (key, api) in const [
        ('1h', '1h'),
        ('8h', '8h'),
        ('1w', '1w'),
      ]) {
        final world = _ChatWorld();
        await _open(tester, world);
        expect(find.byTooltip(_en.chatMuteTooltip), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
        await tester.pumpAndSettle();
        expect(find.text(_en.chatMuteSheetTitle), findsOneWidget);
        expect(find.text(_en.chatMuteSheetBody), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('social.mute.$key')));
        await qaSettle(tester);
        final put = world.api.sent('PUT', '/social/channels/c1/mute');
        expect(put, hasLength(1), reason: key);
        expect(put.single.body, {'duration': api});
        expect(qaSnackText(tester), _en.chatMuteDone);
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
        expect(find.byTooltip(_en.chatMutedTooltip), findsOneWidget);
        await _done(tester);
      }
    });

    testWidgets('Until I turn it back on mutes with no end date '
        '[case:social_chat.social_chat.until_i_turn_it_back_on.action]', (
      tester,
    ) async {
      final world = _ChatWorld();
      await _open(tester, world);
      await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.chatMuteForever));
      await qaSettle(tester);
      expect(world.api.sent('PUT', '/social/channels/c1/mute').single.body, {
        'duration': 'forever',
      });
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      // The sheet now says it is muted with no end.
      await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
      await tester.pumpAndSettle();
      expect(find.text(_en.chatMutedIndefinitely), findsOneWidget);
      await _done(tester);
    });

    testWidgets('Turn notifications back on unmutes a muted chat '
        '[case:social_chat.social_chat.social_mute_off.action]', (
      tester,
    ) async {
      final world = _ChatWorld()
        ..channel['muted'] = true
        ..channel['muted_until'] = null;
      await _open(tester, world);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('social.mute.off')));
      await qaSettle(tester);
      expect(
        world.api.sent('DELETE', '/social/channels/c1/mute'),
        hasLength(1),
      );
      expect(world.api.sent('PUT', '/social/channels/c1/mute'), isEmpty);
      expect(qaSnackText(tester), _en.chatUnmuteDone);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      await _done(tester);
    });

    testWidgets('a mute the server refuses says so and leaves notifications '
        'on [case:social_chat.social_chat.social_chat_mute.api_failure]', (
      tester,
    ) async {
      final world = _ChatWorld();
      await _open(tester, world);
      world.api.on(
        'PUT /social/channels/c1/mute',
        (_) => const QaReply(500, <String, dynamic>{}),
      );
      await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('social.mute.1h')));
      await qaSettle(tester);
      expect(world.api.sent('PUT', '/social/channels/c1/mute'), hasLength(1));
      expect(qaSnackText(tester), _en.chatMuteFailed);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
      // The conversation is still there and usable.
      expect(find.text('Anyone reading Murakami?'), findsOneWidget);
      await _done(tester);
    });
  });

  group('screen checks', () {
    testWidgets('lays out on every device size in both themes '
        '[case:social_chat.social_chat.layout_matrix]', (tester) async {
      final world = _ChatWorld();
      await qaExpectLaysOutEverywhere(
        tester,
        world.api,
        () => _screen(onSenderTap: (_, _) {}),
        loaded: find.text('Anyone reading Murakami?'),
      );
    });

    testWidgets('meets the tap-target, label and contrast guidelines '
        '[case:social_chat.social_chat.a11y_guidelines]', (tester) async {
      final world = _ChatWorld();
      await qaExpectMeetsA11yGuidelines(
        tester,
        world.api,
        () => _screen(onSenderTap: (_, _) {}),
        loaded: find.text('Anyone reading Murakami?'),
      );
    });

    testWidgets('pushed from a room or group, Back closes it '
        '[case:social_chat.social_chat.back_affordance]', (tester) async {
      final world = _ChatWorld();
      await qaExpectBackReturns(
        tester,
        world.api,
        _screen,
        screen: SocialChatScreen,
      );
    });

    testWidgets('renders in every locale with no English left, including '
        'the message actions and the mute sheet '
        '[case:social_chat.social_chat.l10n]', (tester) async {
      final world = _ChatWorld();
      await qaExpectRendersInAllLocales(
        tester,
        world.api,
        () => _screen(onSenderTap: (_, _) {}),
        expected: [(l) => l.chatMemberCount(12), (l) => l.chatComposerHint],
        allow: {
          'Bookworms',
          'Asha',
          'Anyone reading Murakami?',
          'Yes, Kafka on the Shore!',
        },
      );
      // The sheets that open from the screen, in German.
      const de = Locale('de');
      final l = qaL10n(de);
      await _open(tester, world, onSenderTap: (_, _) {}, locale: de);
      await _longPress(tester, 'Anyone reading Murakami?');
      for (final s in [l.chatCopyText, l.chatReportMessage]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      for (final s in [_en.chatCopyText, _en.chatReportMessage]) {
        expect(find.text(s), findsNothing, reason: s);
      }
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('social.chat.mute')));
      await tester.pumpAndSettle();
      for (final s in _muteLabels(l)) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      for (final s in _muteLabels(_en)) {
        expect(find.text(s), findsNothing, reason: s);
      }
      await _done(tester);
    });
  });
}

List<String> _muteLabels(AppLocalizations l) => [
  l.chatMuteSheetTitle,
  l.chatMuteSheetBody,
  l.chatMuteOneHour,
  l.chatMuteEightHours,
  l.chatMuteOneWeek,
  l.chatMuteForever,
];
