import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';

void main() {
  testWidgets('ChatScreen smoke renders without layout exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
}
