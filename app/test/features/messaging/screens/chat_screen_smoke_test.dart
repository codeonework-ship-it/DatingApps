import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/messaging/models/messaging_models.dart';
import 'package:verified_dating_app/features/messaging/providers/message_provider.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _GiftReceiverAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'receiver-user');
}

class _GiftMessageNotifier extends MessageNotifier {
  @override
  MessageState build(String matchId) {
    super.build(matchId);
    return MessageState(
      messages: [
        Message(
          id: 'gift-message-1',
          matchId: matchId,
          senderId: 'sender-user',
          text: '[gift:id=rose_blue_rare|name=Blue Rose|price=3]',
          createdAt: DateTime(2026, 9, 27),
          deliveredAt: DateTime(2026, 9, 27),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('ChatScreen smoke renders without layout exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatScreen(
            matchId: 'pending-smoke-match',
            otherUserId: 'user-smoke-target',
            userName: 'Arya',
            userPhotoUrl: '',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Arya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('received gift offers hide and report controls', (tester) async {
    const matchId = 'pending-gift-controls';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_GiftReceiverAuthNotifier.new),
          messageNotifierProvider(
            matchId,
          ).overrideWith(_GiftMessageNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatScreen(
            matchId: matchId,
            otherUserId: 'sender-user',
            userName: 'Arya',
            userPhotoUrl: '',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Gift received from Arya'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('qa.chat.gift_receiver_actions')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hide gift'), findsOneWidget);
    expect(find.text('Report and hide'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.chat.gift_hide')));
    await tester.pumpAndSettle();

    expect(find.text('Gift received from Arya'), findsNothing);
    expect(find.text('Gift hidden from your chat.'), findsOneWidget);
  });
}
