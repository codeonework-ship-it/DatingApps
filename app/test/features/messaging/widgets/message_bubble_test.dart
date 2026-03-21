import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/messaging/widgets/message_bubble.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('renders plain text message when payload is not a gift', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: 'Hello there',
              isFromCurrentUser: true,
              timestamp: DateTime(2026, 3, 19, 10, 30),
              isDelivered: false,
              isRead: true,
            ),
          ),
        ),
      );

      expect(find.text('Hello there'), findsOneWidget);
      expect(find.textContaining('coins'), findsNothing);
      expect(find.text('Free gift'), findsNothing);
    });

    testWidgets('renders gift card details for encoded gift payload', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message:
                  '[gift:id=rose_blue_rare|name=Blue Rose|url=https://example.com/blue.gif|price=3]',
              isFromCurrentUser: false,
              timestamp: DateTime(2026, 3, 19, 10, 30),
              isDelivered: true,
              isRead: false,
            ),
          ),
        ),
      );

      expect(find.text('Blue Rose'), findsOneWidget);
      expect(find.text('3 coins'), findsOneWidget);
    });

    testWidgets(
      'preserves plain text and renders gift card when gift payload is appended',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message:
                    'Keep this note.\n'
                    '[gift:id=rose_blue_rare|name=Blue Rose|url=https://example.com/blue.gif|price=3]',
                isFromCurrentUser: true,
                timestamp: DateTime(2026, 3, 19, 10, 30),
                isDelivered: true,
                isRead: false,
              ),
            ),
          ),
        );

        expect(find.text('Keep this note.'), findsOneWidget);
        expect(find.text('Blue Rose'), findsOneWidget);
        expect(find.text('3 coins'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves plain text and renders gesture gift when payload is appended',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message:
                    'Existing body text.\n'
                    '[gesture_gift:gesture_type=thoughtful_opener|tone=warm|'
                    'gesture_text=Gesture line here.|gift_id=rose_blue_rare|'
                    'gift_icon=rose_blue|gift_name=Blue Rose|'
                    'gift_url=https://example.com/blue.gif|gift_price=3]',
                isFromCurrentUser: false,
                timestamp: DateTime(2026, 3, 19, 10, 30),
                isDelivered: true,
                isRead: false,
              ),
            ),
          ),
        );

        expect(find.text('Existing body text.'), findsOneWidget);
        expect(find.text('Gesture line here.'), findsOneWidget);
        expect(find.text('Blue Rose'), findsOneWidget);
        expect(find.text('3 coins'), findsOneWidget);
      },
    );

    testWidgets('uses single tick for sent-only state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: 'sent-only',
              isFromCurrentUser: true,
              timestamp: DateTime(2026, 3, 19, 10, 30),
              isDelivered: false,
              isRead: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('uses double tick for delivered state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: 'delivered',
              isFromCurrentUser: true,
              timestamp: DateTime(2026, 3, 19, 10, 30),
              isDelivered: true,
              isRead: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done), findsNothing);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });
  });
}
