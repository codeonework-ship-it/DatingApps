import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/providers/support_ticket_provider.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';

class _FakeSupportTickets extends SupportTicketsNotifier {
  @override
  Future<List<SupportTicket>> build() async => const [];

  @override
  Future<void> create({
    required String category,
    required String priority,
    required String subject,
    required String body,
  }) async {
    final now = DateTime(2026, 9, 27);
    state = AsyncData([
      SupportTicket(
        id: 'ticket-1',
        category: category,
        priority: priority,
        subject: subject,
        status: 'open',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }
}

void main() {
  Widget app() => ProviderScope(
    overrides: [supportTicketsProvider.overrideWith(_FakeSupportTickets.new)],
    child: const MaterialApp(home: HelpSupportScreen()),
  );

  testWidgets('opens a tracked support conversation from the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('How can we help?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create_support_ticket')));
    await tester.pumpAndSettle();

    expect(find.text('Start a support conversation'), findsOneWidget);
    expect(find.textContaining('Never include a password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('support_subject')),
      'Cannot update my profile',
    );
    await tester.enterText(
      find.byKey(const Key('support_message')),
      'The save button keeps returning an error.',
    );
    await tester.ensureVisible(find.byKey(const Key('submit_support_ticket')));
    await tester.tap(find.byKey(const Key('submit_support_ticket')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Cannot update my profile'), findsOneWidget);
    expect(find.text('Support ticket created.'), findsOneWidget);
  });

  testWidgets('rejects an underspecified request before submission', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_support_ticket')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('support_subject')), 'Help');
    await tester.ensureVisible(find.byKey(const Key('submit_support_ticket')));
    await tester.tap(find.byKey(const Key('submit_support_ticket')));
    await tester.pump();

    expect(
      find.textContaining('subject of at least 5 characters'),
      findsOneWidget,
    );
  });
}
