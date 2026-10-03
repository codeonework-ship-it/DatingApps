import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/chat_error_l10n.dart';
import 'package:verified_dating_app/features/messaging/widgets/chat_chrome.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

Widget _app(Locale locale, Widget child) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('the empty match chat and composer speak German', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        Column(
          children: [
            Expanded(
              child: ChatWelcome(
                name: 'Maya',
                photoUrl: '',
                pending: false,
                onStarter: (_) {},
              ),
            ),
            ChatDateDivider(date: DateTime.now()),
            ChatComposer(
              controller: controller,
              focusNode: FocusNode(),
              enabled: true,
              sending: false,
              giftTrayOpen: false,
              onSend: () {},
              onChanged: (_) {},
              onEmoji: () {},
              onGift: () {},
              onCopilot: () {},
            ),
          ],
        ),
      ),
    );

    expect(
      find.text('Jede gute Geschichte\nbeginnt mit einem Hallo.'),
      findsOneWidget,
    );
    expect(
      find.text('Was hat dich heute zum Lächeln gebracht?'),
      findsOneWidget,
    );
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Hilf mir, es zu sagen'), findsOneWidget);
    expect(find.byTooltip('Geschenk senden'), findsOneWidget);
    expect(find.text('Every good story\nstarts with a hello.'), findsNothing);
  });

  testWidgets('English stays as it was', (tester) async {
    await tester.pumpWidget(
      _app(
        const Locale('en'),
        ChatWelcome(name: 'Maya', photoUrl: '', pending: true),
      ),
    );
    expect(find.text('Every good story\nstarts with a hello.'), findsOneWidget);
    expect(
      find.text('Your conversation will open when the match is confirmed.'),
      findsOneWidget,
    );
  });

  test('chat errors are translated, server text is left alone', () async {
    final de = await AppLocalizations.delegate.load(const Locale('de'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(
      localizeChatError(de, 'Failed to send message.'),
      'Nachricht konnte nicht gesendet werden.',
    );
    expect(
      localizeChatError(de, 'Not enough coins to send Golden Rose.'),
      'Nicht genug Coins für Goldene Rose.',
    );
    expect(
      localizeChatError(de, 'Golden Rose is not available right now.'),
      'Goldene Rose ist gerade nicht verfügbar.',
    );
    expect(
      localizeChatError(
        de,
        "You've sent today's free gift. A new one is available after "
        'midnight UTC.',
      ),
      de.chatErrorFreeGiftUsed,
    );
    // Unknown server text: never shown untranslated outside English.
    expect(
      localizeChatError(de, 'Server said no'),
      de.commonSomethingWentWrongTryAgain,
    );
    for (final english in [
      'This match has ended.',
      'Failed to delete message.',
      'Delete window expired (24h).',
      'Not enough coins to send Golden Rose.',
    ]) {
      expect(localizeChatError(en, english), english);
    }
  });
}
