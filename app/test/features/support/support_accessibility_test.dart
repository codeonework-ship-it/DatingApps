import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_tickets_screen.dart';

import 'support_fakes.dart';

/// The layout matrix only sees these screens empty; this checks them with
/// real content: tap targets labelled and 48x48, and text legible.
void main() {
  final api = FakeSupportApi({
    'GET /support/tickets': (_) => ok({
      'success': true,
      'tickets': [
        ticketJson(status: 'pending_member', unread: 1),
        ticketJson(id: 'ticket-2', status: 'closed'),
      ],
      'unread_total': 1,
      'open_total': 1,
    }),
    'GET /support/tickets/ticket-1': (_) => ok({
      'success': true,
      'ticket': ticketJson(status: 'resolved', canRate: true),
      'messages': [
        messageJson(),
        messageJson(id: 'm-2', author: 'agent', body: 'Fixed in 1.4.1.'),
        messageJson(id: 'm-3', author: 'system', body: 'Marked resolved'),
      ],
    }),
  });

  final screens = <String, Widget>{
    'form': const SupportTicketFormScreen(),
    'list': const SupportTicketsScreen(),
    'thread': const SupportTicketThreadScreen(ticketId: 'ticket-1'),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name meets accessibility guidelines with content', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSupport(tester, api, screen);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}
