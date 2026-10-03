import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/chat_error_l10n.dart';
import 'package:verified_dating_app/features/messaging/gift_l10n.dart';
import 'package:verified_dating_app/features/messaging/widgets/message_bubble.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

const _goldenRoseToken =
    '[gift:id=rose_golden|icon=rose_gold|name=Golden Rose|price=3]';

Future<void> _pumpBubble(
  WidgetTester tester, {
  required String message,
  bool mine = false,
  bool isDeleted = false,
  String? receivedGiftFrom,
  Locale locale = const Locale('de'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MessageBubble(
            message: message,
            isFromCurrentUser: mine,
            timestamp: DateTime(2026, 10, 2, 9, 30),
            isDelivered: true,
            isRead: false,
            isDeleted: isDeleted,
            receivedGiftFrom: receivedGiftFrom,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  testWidgets('a deleted message shows the placeholder in the reader language '
      '[case:l10n.chat_bubbles.deleted_placeholder]', (tester) async {
    await _pumpBubble(tester, message: '', mine: true, isDeleted: true);
    expect(find.text('Nachricht gelöscht'), findsOneWidget);
    expect(find.text('Message deleted'), findsNothing);
  });

  testWidgets('a deleted message never shows its stored text '
      '[case:l10n.chat_bubbles.deleted_ignores_stored_text]', (tester) async {
    await _pumpBubble(
      tester,
      message: 'Message deleted',
      mine: true,
      isDeleted: true,
      locale: const Locale('fr'),
    );
    expect(find.text('Message supprimé'), findsOneWidget);
    expect(find.text('Message deleted'), findsNothing);
  });

  testWidgets('the sender sees their gift titled for them, named in German '
      '[case:l10n.chat_bubbles.gift_sender_view]', (tester) async {
    await _pumpBubble(tester, message: _goldenRoseToken, mine: true);
    expect(find.text(de.chatGiftYouSentHeading), findsOneWidget);
    expect(find.text('Du hast ein Geschenk gesendet'), findsOneWidget);
    expect(find.text('Goldene Rose'), findsOneWidget);
    expect(find.text('Golden Rose'), findsNothing);
    expect(find.text(de.chatGiftForYouHeading), findsNothing);
  });

  testWidgets('the recipient sees who sent the gift, named in German '
      '[case:l10n.chat_bubbles.gift_recipient_view]', (tester) async {
    await _pumpBubble(
      tester,
      message: _goldenRoseToken,
      receivedGiftFrom: 'Priya',
    );
    expect(find.text(de.chatGiftReceivedFrom('Priya')), findsOneWidget);
    expect(find.text('Goldene Rose'), findsOneWidget);
    expect(find.text(de.chatGiftYouSentHeading), findsNothing);
  });

  testWidgets('an English caption stored by older builds is not shown '
      '[case:l10n.chat_bubbles.gift_legacy_caption]', (tester) async {
    await _pumpBubble(
      tester,
      message: 'Sent Golden Rose 🌹\n$_goldenRoseToken',
      receivedGiftFrom: 'Priya',
    );
    expect(find.text('Sent Golden Rose 🌹'), findsNothing);
    expect(find.text('Goldene Rose'), findsOneWidget);

    await _pumpBubble(
      tester,
      message:
          'Send Free Rose 🌹\n'
          '[gift:id=rose_red_single|icon=rose_red|name=Single Red Rose|price=0]',
      mine: true,
    );
    expect(find.text('Send Free Rose 🌹'), findsNothing);
    expect(find.text('Eine rote Rose'), findsOneWidget);
  });

  testWidgets('a note the member wrote with the gift is kept as written '
      '[case:l10n.chat_bubbles.gift_note_kept]', (tester) async {
    await _pumpBubble(
      tester,
      message: 'For our first coffee ☕\n$_goldenRoseToken',
      mine: true,
    );
    expect(find.text('For our first coffee ☕'), findsOneWidget);
    expect(find.text('Goldene Rose'), findsOneWidget);
  });

  test('gift names resolve by id, by English name, or keep the server name '
      '[case:l10n.chat_bubbles.gift_name_helper]', () {
    expect(
      localizedGiftName(de, id: 'teddy_bear', serverName: 'Teddy Bear'),
      'Teddybär',
    );
    expect(
      localizedGiftName(de, serverName: 'Champagne Toast'),
      'Anstoßen mit Champagner',
    );
    expect(
      localizedGiftName(de, id: 'mystery_box', serverName: 'Mystery Box'),
      'Mystery Box',
    );
    expect(
      localizedGiftName(en, id: 'jewellery_box', serverName: 'Jewellery Box'),
      'Jewelry Box',
    );
  });

  test('gift errors name the gift in the reader language '
      '[case:l10n.chat_bubbles.gift_error_name]', () {
    expect(
      localizeChatError(de, 'Not enough coins to send Golden Rose.'),
      de.chatErrorNotEnoughCoins('Goldene Rose'),
    );
    expect(
      localizeChatError(de, 'Teddy Bear is not available right now.'),
      de.chatErrorGiftNotAvailable('Teddybär'),
    );
  });

  test('unknown chat errors: English shows readable server text, technical '
      'text and other languages get a translated generic message '
      '[case:l10n.chat_bubbles.unknown_server_error]', () {
    expect(localizeChatError(en, 'Server said no'), 'Server said no');
    expect(
      localizeChatError(en, 'pq: duplicate key value violates constraint'),
      en.commonSomethingWentWrongTryAgain,
    );
    expect(
      localizeChatError(de, 'Server said no'),
      de.commonSomethingWentWrongTryAgain,
    );
  });
}
