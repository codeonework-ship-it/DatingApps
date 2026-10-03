// Control-level tests for "My tickets" (support_tickets_screen.dart): New
// request, Contact support on the empty list, pull to refresh, Try again
// after a failed load, and the screen-quality cases.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_tickets_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'support_qa_world.dart';

Future<void> pumpList(WidgetTester t, SupportWorld w) =>
    pumpQa(t, w.api, const SupportTicketsScreen(), size: const Size(900, 2400));

List<QaCall> listLoads(SupportWorld w) => w.api.sent('GET', '/support/tickets');

void main() {
  testWidgets('New request opens the request form '
      '[case:support.support_tickets.support_new_ticket.action]', (t) async {
    final w = SupportWorld();
    await pumpList(t, w);
    await tapIn(t, find.byKey(const Key('support_new_ticket')));
    expect(find.byType(SupportTicketFormScreen), findsOneWidget);
    expect(find.byKey(const Key('submit_support_ticket')), findsOneWidget);
    expect(w.api.writes, isEmpty);
  });

  testWidgets('With no requests yet, Contact support opens the request form '
      '[case:support.support_tickets.contact_support.action]', (t) async {
    final w = SupportWorld(tickets: []);
    await pumpList(t, w);
    expect(find.byKey(const Key('support_tickets_empty')), findsOneWidget);
    await tapIn(t, find.text(en.supportContactTitle));
    expect(find.byType(SupportTicketFormScreen), findsOneWidget);
  });

  testWidgets('Pull to refresh asks for the requests again and shows a new one '
      '[case:support.support_tickets.support_onrefresh.action]', (t) async {
    final w = SupportWorld();
    await pumpList(t, w);
    expect(find.text('Refund for double charge'), findsNothing);

    w.tickets = [
      ...w.tickets,
      ticketJson(
        id: 'ticket-2',
        reference: 'CN-2026-000124',
        status: 'pending_member',
        subject: 'Refund for double charge',
        unread: 1,
      ),
    ];
    await pullToRefresh(t);
    expect(listLoads(w), hasLength(2));
    expect(find.text('Refund for double charge'), findsOneWidget);
    expect(find.text(en.supportStatusWaitingForYou), findsOneWidget);
  });

  testWidgets('Requests that cannot load explain, and Try again loads them '
      '[case:support.support_tickets.try_again.action]', (t) async {
    final w = SupportWorld();
    w.api.on('GET /support/tickets', (_) => supportError(500, 'INTERNAL'));
    await pumpList(t, w);
    expect(find.text(en.supportTicketsLoadErrorTitle), findsOneWidget);
    expect(find.text('server says INTERNAL'), findsOneWidget);

    w.api.on(
      'GET /support/tickets',
      (_) => qaOk({'success': true, 'tickets': w.tickets}),
    );
    await tapIn(t, find.text(en.supportTryAgain));
    expect(listLoads(w), hasLength(2));
    expect(find.text(en.supportTicketsLoadErrorTitle), findsNothing);
    expect(find.text('App crashes on chat'), findsOneWidget);
  });

  group('screen quality', () {
    SupportWorld many() => SupportWorld(
      tickets: [
        ticketJson(status: 'pending_member', unread: 2),
        ticketJson(
          id: 'ticket-2',
          reference: 'CN-2026-000124',
          status: 'on_hold',
          category: 'payments_billing',
          subject: 'A very long subject about a refund for a double charge',
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
          status: 'closed',
          subject: 'Cannot verify',
          category: 'verification',
        ),
      ],
    );

    testWidgets('lays out with requests on phone and tablet, both themes '
        '[case:support.support_tickets.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        many().api,
        SupportTicketsScreen.new,
        loaded: find.text('Cannot verify'),
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:support.support_tickets.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        many().api,
        SupportTicketsScreen.new,
        size: const Size(430, 1600),
        loaded: find.text('Cannot verify'),
      );
    });

    testWidgets('pushed, Back returns to Help & Support '
        '[case:support.support_tickets.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        many().api,
        SupportTicketsScreen.new,
        screen: SupportTicketsScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:support.support_tickets.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        many().api,
        SupportTicketsScreen.new,
        size: const Size(430, 2000),
        expected: [
          (l) => l.supportTicketsTitle,
          (l) => l.supportTicketsActiveSection,
          (l) => l.supportTicketsClosedSection,
          (l) => l.supportStatusWaitingForYou,
          (l) => l.supportStatusOnHold,
          (l) => l.supportStatusResolved,
          (l) => l.supportStatusClosed,
          (l) => l.supportCategoryPaymentsBilling,
          (l) => '· ${l.supportUnreadReplies(2)}',
          (l) => l.supportNewTicket,
        ],
        // References, subjects and the last message are the member's and
        // the team's own words.
        allow: {
          'CN-2026-000123',
          'CN-2026-000124',
          'CN-2026-000125',
          'CN-2026-000126',
          'App crashes on chat',
          'A very long subject about a refund for a double charge',
          'Photo upload fails',
          'Cannot verify',
          'Thanks, could you send a screenshot?',
          // German and Dutch say "Support" too.
          'SUPPORT',
        },
      );
    });
  });
}
