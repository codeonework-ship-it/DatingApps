import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_tickets_screen.dart';

import 'support_fakes.dart';

Map<String, dynamic> _list(
  List<Map<String, dynamic>> tickets, {
  int unread = 0,
}) => {
  'success': true,
  'tickets': tickets,
  'unread_total': unread,
  'open_total': tickets.length,
};

void main() {
  group('Help & Support centre', () {
    testWidgets('keeps the FAQ and shows contact and My tickets with badge', (
      tester,
    ) async {
      final api = FakeSupportApi({
        'GET /support/tickets': (_) =>
            ok(_list([ticketJson(unread: 2)], unread: 2)),
      });
      await pumpSupport(tester, api, const HelpSupportScreen());

      expect(find.text('How can we help?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.textContaining('immediate danger'), findsOneWidget);
      expect(find.byKey(const Key('create_support_ticket')), findsOneWidget);
      expect(find.byKey(const Key('support_unread_badge')), findsOneWidget);
      expect(find.text('2 new replies'), findsOneWidget);

      final request = api.sent('GET', '/support/tickets').single;
      expect(request.queryParameters['status'], 'all');

      await tester.tap(find.byKey(const Key('create_support_ticket')));
      await tester.pumpAndSettle();
      expect(find.byType(SupportTicketFormScreen), findsOneWidget);
    });

    testWidgets('feature disabled: friendly state, FAQ still usable', (
      tester,
    ) async {
      final api = FakeSupportApi({
        'GET /support/tickets': (_) => serverError(
          403,
          'FEATURE_DISABLED',
          extra: {'feature_flag': 'support_ticketing_enabled'},
        ),
      });
      await pumpSupport(tester, api, const HelpSupportScreen());

      expect(find.byKey(const Key('support_unavailable')), findsOneWidget);
      expect(
        find.text('Support requests are not available right now'),
        findsOneWidget,
      );
      expect(find.textContaining('support@connect.example'), findsOneWidget);
      expect(find.byKey(const Key('create_support_ticket')), findsNothing);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
    });
  });

  group('My tickets', () {
    testWidgets('lists reference, subject, status chips and unread replies, '
        'and a request opens its thread '
        '[case:support.support_tickets.support_ticket_x.action]', (
      tester,
    ) async {
      final api = FakeSupportApi({
        'GET /support/tickets': (_) => ok(
          _list([
            ticketJson(status: 'pending_member', unread: 1),
            ticketJson(
              id: 'ticket-2',
              reference: 'CN-2026-000124',
              status: 'on_hold',
              category: 'payments_billing',
              subject: 'Refund for double charge',
            ),
            ticketJson(
              id: 'ticket-3',
              reference: 'CN-2026-000125',
              status: 'resolved',
              subject: 'Photo upload fails',
            ),
            ticketJson(
              id: 'ticket-4',
              reference: 'CN-2026-000126',
              status: 'new',
              subject: 'Cannot verify',
              category: 'verification',
            ),
          ], unread: 1),
        ),
        'GET /support/tickets/ticket-1': (_) => ok({
          'success': true,
          'ticket': ticketJson(status: 'pending_member'),
          'messages': [messageJson()],
        }),
      });
      await pumpSupport(tester, api, const SupportTicketsScreen());

      expect(find.text('CN-2026-000123'), findsOneWidget);
      expect(find.text('App crashes on chat'), findsOneWidget);
      expect(find.text('Waiting for you'), findsOneWidget);
      expect(find.text('On hold'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Payments & billing'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('RESOLVED & CLOSED'), findsOneWidget);
      expect(find.byKey(const Key('support_ticket_unread')), findsOneWidget);
      expect(find.text('· 1 new reply'), findsOneWidget);

      // Opening a ticket loads it (which marks it read) and refreshes the
      // list for the badge.
      await tester.tap(find.byKey(const Key('support_ticket_ticket-1')));
      await tester.pumpAndSettle();
      expect(find.byType(SupportTicketThreadScreen), findsOneWidget);
      expect(api.sent('GET', '/support/tickets/ticket-1'), hasLength(1));
      expect(api.sent('GET', '/support/tickets').length, greaterThan(1));
    });

    testWidgets('empty state offers to contact support', (tester) async {
      final api = FakeSupportApi({
        'GET /support/tickets': (_) => ok(_list(const [])),
      });
      await pumpSupport(tester, api, const SupportTicketsScreen());

      expect(find.byKey(const Key('support_tickets_empty')), findsOneWidget);
      expect(find.text('No requests yet'), findsOneWidget);
    });

    testWidgets('a failed load shows the real error with retry', (
      tester,
    ) async {
      final api = FakeSupportApi({
        'GET /support/tickets': (_) => serverError(500, 'INTERNAL'),
      });
      await pumpSupport(tester, api, const SupportTicketsScreen());

      expect(find.text('Your requests couldn’t load'), findsOneWidget);
      expect(find.text('server says INTERNAL'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
