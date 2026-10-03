// The match chat against the recording fake BFF, through the real message
// provider: history and read receipts, send, starters, emoji, long-press
// delete with undo, the gift tray and gift send (free, paid, locked),
// received-gift hide/report, "Help me say it", and the side controls. Each
// test asserts the exact request(s), what the member sees, and a failure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/voice_icebreakers_screen.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';

import '../../support/qa_api.dart';
import '../swipe/discover_qa_fixtures.dart';

Map<String, dynamic> _msg(
  String id,
  String sender,
  String text, {
  bool read = true,
  int minutesAgo = 5,
}) {
  final at = DateTime.now()
      .toUtc()
      .subtract(Duration(minutes: minutesAgo))
      .toIso8601String();
  return {
    'id': id,
    'match_id': 'm1',
    'sender_id': sender,
    'text': text,
    'created_at': at,
    'delivered_at': at,
    'read_at': read ? at : null,
  };
}

const _giftText =
    'A rose for you\n[gift:id=rose_red_single|icon=|name=Classic rose|'
    'url=|price=0]';

final _history = [
  _msg('msg-2', 'me', 'A walk sounds perfect.', minutesAgo: 1),
  _msg('msg-1', 'maya', 'Ideal Sunday?', read: false, minutesAgo: 3),
];

const _gifts = [
  {
    'id': 'rose_red_single',
    'name': 'Classic rose',
    'price_coins': 0,
    'tier': 'free',
    'category': 'roses',
  },
  {
    'id': 'rose_gold',
    'name': 'Golden rose',
    'price_coins': 5,
    'tier': 'premium',
    'category': 'luxury',
  },
  {
    'id': 'rose_diamond',
    'name': 'Diamond rose',
    'price_coins': 100,
    'tier': 'premium',
    'category': 'luxury',
  },
];

QaApi _api({List<Map<String, dynamic>>? messages, bool unlocked = true}) =>
    QaApi()
      ..json('GET /chat/m1/messages', {'messages': messages ?? _history})
      ..json('GET /matches/m1/unlock-state', {'chat_unlocked': unlocked})
      ..json('POST /matches/m1/read', <String, dynamic>{})
      ..json('GET /matches/m1/trust', <String, dynamic>{})
      ..json('GET /chat/gifts', {
        'gifts': _gifts,
        'categories': ['roses', 'luxury'],
      })
      ..json('GET /wallet/me/coins', {
        'wallet': {'coin_balance': 20},
      })
      ..json('POST /chat/m1/messages', {
        'message': {'id': 'msg-3'},
      })
      ..json('DELETE /chat/m1/messages/*', <String, dynamic>{})
      ..json('POST /chat/m1/gifts/events', <String, dynamic>{})
      ..json('POST /chat/m1/gifts/send', {
        'message': {'id': 'gift-9', 'sender_id': 'me'},
        'wallet': {'coin_balance': 15},
      })
      ..json('POST /chat/m1/messages/*/gift/*', <String, dynamic>{})
      ..json('POST /matches/m1/copilot/draft', {
        'draft': {
          'draft_id': 'draft-1',
          'kind': 'plan_idea',
          'tone': 'playful',
          'text': 'Coffee walk on Sunday?',
          'provider': 'template',
          'disclosure': 'Say it in your own words.',
          'drafts_remaining_today': 4,
        },
      });

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  Size size = const Size(430, 932),
}) => pumpQa(
  tester,
  api,
  const ChatScreen(
    matchId: 'm1',
    otherUserId: 'maya',
    userName: 'Maya',
    userPhotoUrl: '',
  ),
  launcher: true,
  size: size,
  flags: {
    'date_plans_enabled': false,
    'graduation_enabled': false,
    'intentional_dating_enabled': false,
  },
  extra: qaDiscoverExtras(),
);

Future<void> _tap(WidgetTester tester, Key key, {int frames = 10}) async {
  await tester.ensureVisible(find.byKey(key).first);
  await tester.tap(find.byKey(key).first);
  await qaSettle(tester, frames: frames);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('qa.chat.composer')), text);
  await tester.pump();
}

String _composerText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const ValueKey('qa.chat.composer')))
    .controller!
    .text;

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  qaSilenceNetworkImages();

  group('history, read and send', () {
    testWidgets('opening loads the history and marks incoming as read '
        '[case:messaging.chat.history.action] '
        '[case:messaging.chat.read_receipt.action]', (tester) async {
      final api = _api();
      await _open(tester, api);

      final load = api.sent('GET', '/chat/m1/messages').single;
      expect(load.query, {'limit': 100});
      expect(load.options.headers['X-User-ID'], 'me');
      expect(api.sent('GET', '/matches/m1/unlock-state'), hasLength(1));
      expect(api.sent('POST', '/matches/m1/read').single.body, {
        'user_id': 'me',
      });
      expect(find.text('A walk sounds perfect.'), findsOneWidget);
      expect(find.text('Ideal Sunday?'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('Send posts the message, clears the composer and reloads '
        '[case:messaging.chat.chat_send_button_send.action] '
        '[case:messaging.chat.chat_send_button_send.api_contract] '
        '[case:messaging.chat.chat_composer.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _type(tester, '  See you at ten 🙂  ');
      await _tap(tester, const ValueKey('qa.chat.send_button'));

      final send = api.sent('POST', '/chat/m1/messages').single;
      expect(send.body, {'sender_id': 'me', 'text': 'See you at ten 🙂'});
      expect(send.options.headers['X-User-ID'], 'me');
      expect(api.sent('GET', '/chat/m1/messages'), hasLength(2));
      expect(_composerText(tester), isEmpty);
      await _close(tester);
    });

    testWidgets('an empty or blank message cannot be sent '
        '[case:messaging.chat.chat_composer.validation]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _type(tester, '    ');

      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('qa.chat.send_button')),
            )
            .onPressed,
        isNull,
      );
      expect(api.sent('POST', '/chat/m1/messages'), isEmpty);
      await _close(tester);
    });

    testWidgets('a failed send keeps the text and says so '
        '[case:messaging.chat.chat_send_button_send.api_failure]', (
      tester,
    ) async {
      final api = _api()..fail('POST /chat/m1/messages');
      await _open(tester, api);
      await _type(tester, 'Hello?');
      await _tap(tester, const ValueKey('qa.chat.send_button'));

      expect(api.sent('POST', '/chat/m1/messages'), hasLength(1));
      expect(qaSnackText(tester), 'Failed to send message.');
      expect(_composerText(tester), 'Hello?');
      await _close(tester);
    });

    testWidgets('the daily message limit shows a banner; See plans opens the '
        'plans '
        '[case:messaging.chat.chat_daily_limit_see_plans_seeplans.action] '
        '[case:messaging.chat.daily_limit_banner]', (tester) async {
      final api = _api()
        ..on(
          'POST /chat/m1/messages',
          (_) => const QaReply(429, {
            'error': 'Daily message limit reached',
            'error_code': 'DAILY_MESSAGE_LIMIT_REACHED',
            'kind': 'message',
            'limit': 20,
            'plan_name': 'Free',
            'resets_at': '2026-10-03T00:00:00Z',
          }),
        );
      await _open(tester, api);
      await _type(tester, 'One more');
      await _tap(tester, const ValueKey('qa.chat.send_button'));

      expect(find.text("You've used today's 20 messages on Free"), findsOne);
      await _tap(tester, const ValueKey('qa.chat.daily_limit.see_plans'));
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await _close(tester);
    });

    testWidgets('a locked conversation pauses the composer '
        '[case:messaging.chat.chat_composer.locked]', (tester) async {
      final api = _api(unlocked: false);
      await _open(tester, api);

      expect(find.byKey(const ValueKey('qa.chat.locked_banner')), findsOne);
      expect(
        find.text(
          'Complete the current unlock step to continue this conversation.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('qa.chat.composer')))
            .enabled,
        isFalse,
      );
      await _close(tester);
    });

    testWidgets('a failed load offers Retry, which loads the history '
        '[case:messaging.chat.chat_retry.action]', (tester) async {
      final api = _api()..fail('GET /chat/m1/messages');
      await _open(tester, api);
      expect(find.text('Let’s reconnect.'), findsOneWidget);

      api.json('GET /chat/m1/messages', {'messages': _history});
      await _tap(tester, const ValueKey('qa.chat.retry'));

      expect(api.sent('GET', '/chat/m1/messages'), hasLength(2));
      expect(find.text('Ideal Sunday?'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('a starter fills the composer in an empty chat '
        '[case:messaging.chat.chat_starter_x_starter.action]', (
      tester,
    ) async {
      final api = _api(messages: []);
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.starter.0'));

      expect(_composerText(tester), 'What made you smile today?');
      expect(api.sent('POST', '/chat/m1/messages'), isEmpty);
      await _close(tester);
    });

    testWidgets('the emoji sheet adds the chosen emoji and closes '
        '[case:messaging.chat.chat_emoji_button_emoji.action] '
        '[case:messaging.chat.showmodalbottomsheet_open.action] '
        '[case:messaging.chat.chat_emoji_x.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _type(tester, 'Sounds good');
      await _tap(tester, const ValueKey('qa.chat.emoji_button'));
      expect(find.text('Quick emojis'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.chat.emoji.🔥'));

      expect(find.text('Quick emojis'), findsNothing);
      expect(_composerText(tester), 'Sounds good 🔥');
      await _close(tester);
    });

    testWidgets('back returns to the conversations '
        '[case:messaging.chat.chat_back_button.action] '
        '[case:messaging.chat.back_affordance]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.back_button'));

      expect(find.byType(ChatScreen), findsNothing);
      await _close(tester);
    });

    testWidgets('Share a voice hello opens voice hellos for this match '
        '[case:messaging.chat.chat_voice_hello.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.voice_hello'));

      final voice = tester.widget<VoiceIcebreakersScreen>(
        find.byType(VoiceIcebreakersScreen),
      );
      expect(voice.matchId, 'm1');
      expect(voice.receiverUserId, 'maya');
      await _close(tester);
    });

    testWidgets('the wallet chip opens the wallet and re-reads the balance '
        '[case:messaging.chat.chat_wallet_button.action] '
        '', (tester) async {
      final api = _api();
      await _open(tester, api);
      expect(find.text('20'), findsOneWidget);
      await _tap(tester, const ValueKey('qa.chat.wallet_button'));
      expect(
        tester
            .widget<WalletPaymentScreen>(find.byType(WalletPaymentScreen))
            .walletCoins,
        20,
      );

      api.json('GET /wallet/me/coins', {
        'wallet': {'coin_balance': 70},
      });
      Navigator.of(tester.element(find.byType(WalletPaymentScreen))).pop();
      await qaSettle(tester);

      expect(api.sent('GET', '/wallet/me/coins').length, greaterThan(1));
      expect(find.text('70'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('a failed wallet read keeps the last balance '
        '[case:messaging.chat.chat_wallet_button.api_failure]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.wallet_button'));
      api.offline('GET /wallet/me/coins');
      Navigator.of(tester.element(find.byType(WalletPaymentScreen))).pop();
      await qaSettle(tester);

      expect(find.text('20'), findsOneWidget);
      expect(find.byType(ChatScreen), findsOneWidget);
      await _close(tester);
    });
  });

  group('long-press delete', () {
    testWidgets('Delete for everyone removes the message; the server delete '
        'follows the undo window '
        '[case:messaging.chat.chat_message_x_longpress.action] '
        '[case:messaging.chat.chat_message_x_longpress.api_contract] '
        '[case:messaging.chat.delete_icon_delete_outline.action] '
        '[case:messaging.chat.chat_delete_message_action.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await tester.longPress(
        find.byKey(const ValueKey('qa.chat.message.msg-2')),
      );
      await qaSettle(tester);
      expect(find.text('Delete message?'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.chat.delete_message_action'));
      expect(find.text('A walk sounds perfect.'), findsNothing);
      expect(qaSnackText(tester), contains('Message deleted.'));
      expect(api.sent('DELETE', '/chat/m1/messages/msg-2'), isEmpty);

      await qaSettle(tester, frames: 45);
      expect(api.sent('DELETE', '/chat/m1/messages/msg-2').single.body, {
        'requester_user_id': 'me',
      });
      await _close(tester);
    });

    testWidgets('Undo restores the message and nothing is deleted '
        '[case:messaging.chat.snackbaraction_onpressed.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await tester.longPress(
        find.byKey(const ValueKey('qa.chat.message.msg-2')),
      );
      await qaSettle(tester);
      await _tap(tester, const ValueKey('qa.chat.delete_message_action'));
      await tester.tap(find.text('Undo'));
      await qaSettle(tester, frames: 45);

      expect(find.text('A walk sounds perfect.'), findsOneWidget);
      expect(api.sent('DELETE', '/chat/m1/messages/msg-2'), isEmpty);
      await _close(tester);
    });

    testWidgets('Cancel keeps the message '
        '[case:messaging.chat.chat_delete_message_cancel.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await tester.longPress(
        find.byKey(const ValueKey('qa.chat.message.msg-2')),
      );
      await qaSettle(tester);
      await _tap(tester, const ValueKey('qa.chat.delete_message_cancel'));

      expect(find.text('Delete message?'), findsNothing);
      expect(find.text('A walk sounds perfect.'), findsOneWidget);
      await qaSettle(tester, frames: 45);
      expect(api.sent('DELETE', '/chat/m1/messages/msg-2'), isEmpty);
      await _close(tester);
    });

    testWidgets('a refused delete puts the message back and says so '
        '[case:messaging.chat.chat_message_x_longpress.api_failure]', (
      tester,
    ) async {
      final api = _api()..fail('DELETE /chat/m1/messages/msg-2');
      await _open(tester, api);
      await tester.longPress(
        find.byKey(const ValueKey('qa.chat.message.msg-2')),
      );
      await qaSettle(tester);
      await _tap(tester, const ValueKey('qa.chat.delete_message_action'));
      await qaSettle(tester, frames: 45);

      expect(api.sent('DELETE', '/chat/m1/messages/msg-2'), hasLength(1));
      expect(find.text('A walk sounds perfect.'), findsOneWidget);
      expect(qaSnackText(tester), 'Failed to delete message.');
      await _close(tester);
    });
  });

  group('gift tray and gift send', () {
    testWidgets('the gift button opens the tray and records the open '
        '[case:messaging.chat.chat_gift_tray_button_gift.action] '
        '[case:messaging.chat.chat_gift_tray_button_gift.api_contract]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));

      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOne);
      final event = api.sent('POST', '/chat/m1/gifts/events').single.body;
      expect(event['event_name'], 'gift_panel_opened');
      expect(event['user_id'], 'me');
      expect(event['wallet_coins'], 20);
      expect(event['catalog_count'], 3);
      await _close(tester);
    });

    testWidgets('the tray still opens when the open cannot be recorded '
        '[case:messaging.chat.chat_gift_tray_button_gift.api_failure] '
        '[case:messaging.chat.chat_gift_tray_close.api_failure]', (tester) async {
      final api = _api()..offline('POST /chat/m1/gifts/events');
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));

      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOne);
      expect(qaSnackText(tester), isNull);
      await _close(tester);
    });

    testWidgets('Close gifts closes the tray '
        '[case:messaging.chat.chat_gift_tray_close.action] '
        '', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(tester, const ValueKey('qa.chat.gift_tray_close'));

      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsNothing);
      expect(api.sent('POST', '/chat/m1/gifts/events'), hasLength(1));
      await _close(tester);
    });

    testWidgets('a collection chip filters the gifts; All gifts shows all '
        '[case:messaging.chat.chat_gift_category_category.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(tester, const ValueKey('qa.chat.gift_category.luxury'));

      expect(
        find.byKey(const ValueKey('qa.chat.gift_item.rose_red_single')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('qa.chat.gift_item.rose_gold')),
        findsOne,
      );

      await _tap(tester, const ValueKey('qa.chat.gift_category.all'));
      expect(
        find.byKey(const ValueKey('qa.chat.gift_item.rose_red_single')),
        findsOne,
      );
      await _close(tester);
    });

    testWidgets('a free gift is sent in one tap with the note, then the tray '
        'closes '
        '[case:messaging.chat.chat_gift_item_x.action] '
        '[case:messaging.chat.chat_gift_item_x.api_contract]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _type(tester, 'For Sunday');
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(
        tester,
        const ValueKey('qa.chat.gift_item.rose_red_single'),
        frames: 14,
      );

      final send = api.sent('POST', '/chat/m1/gifts/send').single;
      expect(send.body, {
        'sender_user_id': 'me',
        'receiver_user_id': 'maya',
        'gift_id': 'rose_red_single',
        'message_text': 'For Sunday',
      });
      expect(send.options.headers['Idempotency-Key'], isNotEmpty);
      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsNothing);
      expect(_composerText(tester), isEmpty);
      expect(api.sent('GET', '/chat/m1/messages'), hasLength(2));
      await _close(tester);
    });

    testWidgets('a paid gift is confirmed with its price and balance first '
        '[case:messaging.chat.not_now.action] '
        '[case:messaging.chat.chat_gift_confirm_send.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(tester, const ValueKey('qa.chat.gift_item.rose_gold'));

      expect(find.text('Send Golden Rose to Maya?'), findsOneWidget);
      expect(find.text('·  20 → 15 left'), findsOneWidget);
      expect(api.sent('POST', '/chat/m1/gifts/send'), isEmpty);

      await _tap(
        tester,
        const ValueKey('qa.chat.gift_confirm.send'),
        frames: 14,
      );
      expect(
        api.sent('POST', '/chat/m1/gifts/send').single.body['gift_id'],
        'rose_gold',
      );
      expect(find.text('15'), findsOneWidget, reason: 'new balance');
      await _close(tester);
    });

    testWidgets('Not now sends nothing and keeps the note '
        '[case:messaging.chat.chat_gift_confirm_not_now.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _type(tester, 'Just because');
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(tester, const ValueKey('qa.chat.gift_item.rose_gold'));
      await _tap(tester, const ValueKey('qa.chat.gift_confirm.not_now'));

      expect(find.text('Send Golden Rose to Maya?'), findsNothing);
      expect(api.sent('POST', '/chat/m1/gifts/send'), isEmpty);
      expect(_composerText(tester), 'Just because');
      await _close(tester);
    });

    testWidgets('a gift the wallet cannot cover opens the wallet instead '
        '[case:messaging.chat.chat_gift_item_x.locked]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      expect(find.text('Add coins'), findsOneWidget);
      await _tap(tester, const ValueKey('qa.chat.gift_item.rose_diamond'));

      expect(find.byType(WalletPaymentScreen), findsOneWidget);
      expect(api.sent('POST', '/chat/m1/gifts/send'), isEmpty);
      await _close(tester);
    });

    testWidgets("today's free gift already sent is explained "
        '[case:messaging.chat.chat_gift_item_x.api_failure]', (tester) async {
      final api = _api()
        ..fail(
          'POST /chat/m1/gifts/send',
          status: 429,
          code: 'FREE_GIFT_DAILY_LIMIT_REACHED',
        );
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_tray_button'));
      await _tap(
        tester,
        const ValueKey('qa.chat.gift_item.rose_red_single'),
        frames: 14,
      );

      expect(
        qaSnackText(tester),
        "You've sent today's free gift. A new one is available after "
        'midnight UTC.',
      );
      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOne);
      await _close(tester);
    });

    testWidgets('the wide layout: Send a little joy opens the tray, Find the '
        'words opens the copilot, All conversations goes back '
        '[case:messaging.chat.chat_sidebar_gift_gift.action] '
        ''
        '[case:messaging.chat.chat_sidebar_gift_gift.api_failure] '
        '[case:messaging.chat.chat_sidebar_copilot_copilot.action] '
        '[case:messaging.chat.chat_sidebar_back_back.action]', (
      tester,
    ) async {
      final api = _api()..offline('POST /chat/m1/gifts/events');
      await _open(tester, api, size: const Size(1200, 900));
      await _tap(tester, const ValueKey('qa.chat.sidebar.gift'));
      expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOne);
      expect(api.sent('POST', '/chat/m1/gifts/events'), hasLength(1));

      await _tap(tester, const ValueKey('qa.chat.sidebar.copilot'));
      expect(find.text('Help me say it'), findsWidgets);
      expect(find.byKey(const ValueKey('qa.copilot.generate')), findsOne);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('qa.copilot.generate'))),
      ).pop();
      await qaSettle(tester);

      // Reaching the gift and copilot buttons scrolled the sidebar, and
      // "All conversations" sits at its top: scroll back up to it.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('qa.chat.sidebar.back')),
        -200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('qa.chat.desktop_sidebar')),
          matching: find.byType(Scrollable),
        ),
      );
      await _tap(tester, const ValueKey('qa.chat.sidebar.back'));
      expect(find.byType(ChatScreen), findsNothing);
      await _close(tester);
    });
  });

  group('received gifts', () {
    final received = [_msg('g1', 'maya', _giftText), ..._history];

    testWidgets('Hide gift hides it from this chat only '
        '[case:messaging.chat.chat_gift_receiver_actions_giftactions.action] '
        '[case:messaging.chat.chat_gift_receiver_actions_giftactions.api_contract] '
        '[case:messaging.chat.hide_icon_visibility_off_outline.action] '
        '[case:messaging.chat.chat_gift_hide.action]', (tester) async {
      final api = _api(messages: received);
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_receiver_actions'));
      expect(find.text('Gift received from Maya'), findsWidgets);

      await _tap(tester, const ValueKey('qa.chat.gift_hide'));

      final hide = api.sent('POST', '/chat/m1/messages/g1/gift/hide').single;
      expect(hide.options.headers['X-User-ID'], 'me');
      expect(hide.options.headers['Idempotency-Key'], 'gift-hide-me-g1');
      expect(qaSnackText(tester), 'Gift hidden from your chat.');
      expect(find.byKey(const ValueKey('qa.chat.message.g1')), findsNothing);
      await _close(tester);
    });

    testWidgets('long-pressing a received gift opens the same choices; '
        'Cancel keeps it '
        '[case:messaging.chat.chat_gift_receiver_cancel.action]', (tester) async {
      final api = _api(messages: received);
      await _open(tester, api);
      await tester.longPress(find.byKey(const ValueKey('qa.chat.message.g1')));
      await qaSettle(tester);
      expect(find.byKey(const ValueKey('qa.chat.gift_hide')), findsOne);

      await _tap(tester, const ValueKey('qa.chat.gift_receiver_cancel'));
      expect(find.byKey(const ValueKey('qa.chat.gift_hide')), findsNothing);
      expect(api.writes.where((c) => c.path.contains('/gift/')), isEmpty);
      await _close(tester);
    });

    testWidgets('Report and hide sends the reason and details '
        '[case:messaging.chat.chat_gift_report.action] '
        '[case:messaging.chat.chat_gift_report_reason.action] '
        '[case:messaging.chat.chat_gift_report_details.action] '
        '[case:messaging.chat.chat_gift_report_submit.action]', (tester) async {
      final api = _api(messages: received);
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_receiver_actions'));
      await _tap(tester, const ValueKey('qa.chat.gift_report'));
      expect(find.text('Report this gift'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.chat.gift_report_reason'));
      await tester.tap(find.text('Harassment').last);
      await qaSettle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('qa.chat.gift_report_details')),
        '  Sent after I said no  ',
      );
      await _tap(tester, const ValueKey('qa.chat.gift_report_submit'));

      expect(api.sent('POST', '/chat/m1/messages/g1/gift/report').single.body, {
        'reason': 'harassment',
        'details': 'Sent after I said no',
      });
      expect(
        qaSnackText(tester),
        'Gift reported and hidden. Our safety team will review it.',
      );
      expect(find.byKey(const ValueKey('qa.chat.message.g1')), findsNothing);
      await _close(tester);
    });

    testWidgets('report details are capped at 500 characters '
        '[case:messaging.chat.chat_gift_report_details.validation]', (
      tester,
    ) async {
      final api = _api(messages: received);
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_receiver_actions'));
      await _tap(tester, const ValueKey('qa.chat.gift_report'));
      await tester.enterText(
        find.byKey(const ValueKey('qa.chat.gift_report_details')),
        'x' * 600,
      );
      await tester.pump();
      await _tap(tester, const ValueKey('qa.chat.gift_report_submit'));

      final details = api
          .sent('POST', '/chat/m1/messages/g1/gift/report')
          .single
          .body;
      expect((details['details'] as String).length, 500);
      expect(details['reason'], 'unwanted');
      await _close(tester);
    });

    testWidgets('Cancel on the report sheet sends nothing '
        '[case:messaging.chat.chat_gift_report_cancel.action]', (tester) async {
      final api = _api(messages: received);
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.gift_receiver_actions'));
      await _tap(tester, const ValueKey('qa.chat.gift_report'));
      await _tap(tester, const ValueKey('qa.chat.gift_report_cancel'));

      expect(find.text('Report this gift'), findsNothing);
      expect(api.writes.where((c) => c.path.contains('/gift/')), isEmpty);
      expect(find.byKey(const ValueKey('qa.chat.message.g1')), findsOne);
      await _close(tester);
    });

    testWidgets(
      'a failed report keeps the gift and says so '
      '[case:messaging.chat.chat_gift_receiver_actions_giftactions.api_failure]',
      (tester) async {
        final api = _api(messages: received)
          ..fail('POST /chat/m1/messages/g1/gift/report');
        await _open(tester, api);
        await _tap(tester, const ValueKey('qa.chat.gift_receiver_actions'));
        await _tap(tester, const ValueKey('qa.chat.gift_report'));
        await _tap(tester, const ValueKey('qa.chat.gift_report_submit'));

        expect(
          qaSnackText(tester),
          'Could not report this gift. Please try again.',
        );
        expect(find.byKey(const ValueKey('qa.chat.message.g1')), findsOne);
        await _close(tester);
      },
    );
  });

  group('Help me say it', () {
    testWidgets('drafts in the chosen kind and tone; Use and edit fills the '
        'composer and the send carries the draft id '
        '[case:messaging.chat.chat_copilot_button_copilot.action] '
        '[case:messaging.chat.chat_copilot_button_copilot.api_contract] '
        '[case:messaging.copilot_sheet.showmodalbottomsheet_open.action] '
        '[case:messaging.copilot_sheet.copilot_kind_x.action] '
        '[case:messaging.copilot_sheet.copilot_tone_x.action] '
        '[case:messaging.copilot_sheet.copilot_generate.action] '
        '[case:messaging.copilot_sheet.copilot_generate.api_contract] '
        '[case:messaging.copilot_sheet.copilot_use.action] '
        '[case:messaging.copilot_sheet.copilot_use.api_contract]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.copilot_button'));
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('qa.copilot.kind.reply')),
            )
            .selected,
        isTrue,
        reason: 'a started conversation defaults to a reply',
      );

      await _tap(tester, const ValueKey('qa.copilot.kind.plan_idea'));
      await _tap(tester, const ValueKey('qa.copilot.tone.playful'));
      await _tap(tester, const ValueKey('qa.copilot.generate'));

      expect(api.sent('POST', '/matches/m1/copilot/draft').single.body, {
        'kind': 'plan_idea',
        'tone': 'playful',
      });
      expect(find.text('Coffee walk on Sunday?'), findsOneWidget);
      expect(
        find.text('Say it in your own words. 4 drafts left today.'),
        findsOneWidget,
      );

      await _tap(tester, const ValueKey('qa.copilot.use'));
      expect(find.byKey(const ValueKey('qa.copilot.use')), findsNothing);
      expect(_composerText(tester), 'Coffee walk on Sunday?');
      expect(find.text('Drafted with help'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.chat.send_button'));
      expect(api.sent('POST', '/chat/m1/messages').single.body, {
        'sender_id': 'me',
        'text': 'Coffee walk on Sunday?',
        'assist_draft_id': 'draft-1',
      });
      await _close(tester);
    });

    testWidgets('Try another asks for a fresh draft '
        '[case:messaging.copilot_sheet.copilot_generate.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.copilot_button'));
      await _tap(tester, const ValueKey('qa.copilot.generate'));
      expect(find.text('Try another'), findsOneWidget);
      await _tap(tester, const ValueKey('qa.copilot.generate'));

      expect(api.sent('POST', '/matches/m1/copilot/draft'), hasLength(2));
      await _close(tester);
    });

    testWidgets('an unavailable copilot is explained in the sheet '
        '[case:messaging.chat.chat_copilot_button_copilot.api_failure] '
        '[case:messaging.chat.chat_sidebar_copilot_copilot.api_failure] '
        '[case:messaging.copilot_sheet.copilot_generate.api_failure]', (
      tester,
    ) async {
      final api = _api()
        ..on(
          'POST /matches/m1/copilot/draft',
          (_) => const QaReply(503, <String, dynamic>{}),
        );
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.copilot_button'));
      await _tap(tester, const ValueKey('qa.copilot.generate'));

      expect(find.byKey(const ValueKey('qa.copilot.error')), findsOne);
      expect(find.text('The copilot is unavailable.'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.copilot.use')), findsNothing);
      await _close(tester);
    });

    testWidgets("the server's own reason is shown as sent "
        '[case:messaging.copilot_sheet.copilot_use.api_failure]', (
      tester,
    ) async {
      final api = _api()
        ..fail(
          'POST /matches/m1/copilot/draft',
          status: 429,
          message: 'You have used today’s drafts.',
        );
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.chat.copilot_button'));
      await _tap(tester, const ValueKey('qa.copilot.generate'));

      expect(find.text('You have used today’s drafts.'), findsOneWidget);
      expect(_composerText(tester), isEmpty);
      await _close(tester);
    });
  });
}
