import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/support_routes.dart';

import 'support_fakes.dart';

Map<String, dynamic> _thread(Map<String, dynamic> ticket) => {
  'success': true,
  'ticket': ticket,
  'messages': [
    messageJson(),
    messageJson(
      id: 'm-2',
      author: 'agent',
      body: 'Thanks, could you send a screenshot?',
    ),
    messageJson(id: 'm-3', author: 'system', body: 'Status changed'),
  ],
};

void main() {
  testWidgets('loads the thread and shows member, agent and system messages', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'GET /support/tickets/ticket-1': (_) =>
          ok(_thread(ticketJson(status: 'pending_member'))),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
    });
    await pumpSupport(
      tester,
      api,
      const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    );

    expect(find.text('CN-2026-000123'), findsOneWidget);
    expect(find.text('When I open a chat the app closes.'), findsOneWidget);
    expect(find.text('Thanks, could you send a screenshot?'), findsOneWidget);
    expect(find.textContaining('Connect Support'), findsOneWidget);
    expect(find.textContaining('Status changed'), findsOneWidget);
    // Waiting on the member: chip and banner say so.
    expect(find.text('Waiting for you'), findsOneWidget);
    expect(
      find.text('Support replied and is waiting for your answer.'),
      findsOneWidget,
    );
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Status: Waiting for you'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a reply is posted and appears in the thread '
      '[case:support.support_ticket_thread.support_reply_input.action]', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'GET /support/tickets/ticket-1': (_) =>
          ok(_thread(ticketJson(status: 'pending_member'))),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
      'POST /support/tickets/ticket-1/messages': (request) => ok({
        'success': true,
        'ticket': ticketJson(),
        'message': messageJson(
          id: 'm-4',
          body: (request.data as Map)['body'] as String,
        ),
      }, status: 201),
    });
    await pumpSupport(
      tester,
      api,
      const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    );

    await tester.enterText(
      find.byKey(const Key('support_reply')),
      'Here is what I see.',
    );
    await tester.tap(find.byKey(const Key('support_reply_send')));
    await tester.pumpAndSettle();

    final post = api.sent('POST', '/support/tickets/ticket-1/messages').single;
    expect(post.data, {
      'body': 'Here is what I see.',
      'attachment_ids': <Object>[],
    });
    expect(post.headers['Idempotency-Key'], isNotEmpty);
    expect(find.text('Here is what I see.'), findsOneWidget);
    // The ticket moved back to open.
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'resolved: explains reopening by reply and offers a rating '
    '[case:support.support_ticket_thread.support_rate_x_ratingchanged.action] '
    '[case:support.support_ticket_thread.support_rating_comment_input.action] '
    '[case:support.support_ticket_thread.support_rating_submit_rate.action]',
    (tester) async {
      final api = FakeSupportApi({
        'GET /support/tickets/ticket-1': (_) =>
            ok(_thread(ticketJson(status: 'resolved', canRate: true))),
        'GET /support/tickets': (_) =>
            ok({'success': true, 'tickets': <Object>[]}),
        'POST /support/tickets/ticket-1/rating': (request) => ok({
          'success': true,
          'ticket': ticketJson(
            status: 'resolved',
            satisfaction: {
              'rating': (request.data as Map)['rating'],
              'comment': 'Quick fix',
              'rated_at': '2026-09-30T12:00:00Z',
            },
          ),
        }),
      });
      await pumpSupport(
        tester,
        api,
        const SupportTicketThreadScreen(ticketId: 'ticket-1'),
      );

      expect(find.text('Resolved'), findsOneWidget);
      expect(find.textContaining('Reply to reopen it'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('support_rate_4')));
      await tester.tap(find.byKey(const Key('support_rate_4')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support_rating_comment')),
        'Quick fix',
      );
      await tester.ensureVisible(
        find.byKey(const Key('support_rating_submit')),
      );
      await tester.tap(find.byKey(const Key('support_rating_submit')));
      await tester.pumpAndSettle();

      final post = api.sent('POST', '/support/tickets/ticket-1/rating').single;
      expect(post.data, {'rating': 4, 'comment': 'Quick fix'});
      expect(find.byKey(const Key('support_rating_given')), findsOneWidget);
      expect(find.text('You rated this 4 out of 5.'), findsOneWidget);
    },
  );

  testWidgets('closed: reply disabled, reopen offered until the date '
      '[case:support.support_ticket_thread.support_reopen_reopen.action]', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'GET /support/tickets/ticket-1': (_) => ok(
        _thread(
          ticketJson(
            status: 'closed',
            canReply: false,
            canClose: false,
            canReopen: true,
            reopenUntil: '2026-10-14T10:00:00Z',
          ),
        ),
      ),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
      'POST /support/tickets/ticket-1/reopen': (_) =>
          ok({'success': true, 'ticket': ticketJson()}),
    });
    await pumpSupport(
      tester,
      api,
      const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    );

    expect(find.text('Closed'), findsOneWidget);
    expect(
      find.textContaining('This request is closed. You can reopen it until'),
      findsOneWidget,
    );
    final send = tester.widget<IconButton>(
      find.byKey(const Key('support_reply_send')),
    );
    expect(send.onPressed, isNull);
    final attach = tester.widget<IconButton>(
      find.byKey(const Key('support_reply_attach')),
    );
    expect(attach.onPressed, isNull);
    expect(find.byKey(const Key('support_close')), findsNothing);

    await tester.tap(find.byKey(const Key('support_reopen')));
    await tester.pumpAndSettle();
    expect(api.sent('POST', '/support/tickets/ticket-1/reopen'), hasLength(1));
    expect(find.text('Request reopened.'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('close asks for confirmation first '
      '[case:support.support_ticket_thread.support_close_close.action] '
      '[case:support.support_ticket_thread.close_this_request.action] '
      '[case:support.support_ticket_thread.support_close_confirm.action]', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'GET /support/tickets/ticket-1': (_) => ok(_thread(ticketJson())),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
      'POST /support/tickets/ticket-1/close': (_) => ok({
        'success': true,
        'ticket': ticketJson(
          status: 'closed',
          canReply: false,
          canClose: false,
        ),
      }),
    });
    await pumpSupport(
      tester,
      api,
      const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    );

    await tester.tap(find.byKey(const Key('support_close')));
    await tester.pumpAndSettle();
    expect(find.text('Close this request?'), findsOneWidget);
    expect(api.sent('POST', '/support/tickets/ticket-1/close'), isEmpty);

    await tester.tap(find.byKey(const Key('support_close_confirm')));
    await tester.pumpAndSettle();
    expect(api.sent('POST', '/support/tickets/ticket-1/close'), hasLength(1));
    expect(find.text('This request is closed.'), findsOneWidget);
  });

  testWidgets('a missing ticket shows the real error, not a fake thread', (
    tester,
  ) async {
    final api = FakeSupportApi({});
    await pumpSupport(
      tester,
      api,
      const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    );
    expect(find.text('This request couldn’t load'), findsOneWidget);
    expect(find.text('We couldn’t find this request.'), findsOneWidget);
  });

  test('notification routes map to support screens', () {
    expect(
      supportScreenForRoute('/support/tickets/abc'),
      isA<SupportTicketThreadScreen>().having(
        (s) => s.ticketId,
        'ticketId',
        'abc',
      ),
    );
    expect(supportScreenForRoute('/support'), isNotNull);
    expect(supportScreenForRoute('/support/tickets'), isNotNull);
    expect(supportScreenForRoute('/matches/abc'), isNull);
    expect(supportScreenForRoute(null), isNull);
  });
}
