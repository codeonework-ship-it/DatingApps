// Control-level tests for one support request
// (support_ticket_thread_screen.dart) beyond support_ticket_thread_test:
// what happens when close, reopen, rating and reloads fail, the reply and
// rating-comment limits, Cancel in the close dialog, and the screen-quality
// cases. Each test performs the real gesture against the stateful fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'support_qa_world.dart';

final reply = find.byKey(const Key('support_reply'));
final send = find.byKey(const Key('support_reply_send'));
final close = find.byKey(const Key('support_close'));
final reopen = find.byKey(const Key('support_reopen'));

Widget thread() => const SupportTicketThreadScreen(ticketId: 'ticket-1');

Future<void> pumpThread(WidgetTester t, SupportWorld w) =>
    pumpQa(t, w.api, thread(), size: const Size(900, 2400));

List<QaCall> posts(SupportWorld w, String action) =>
    w.api.sent('POST', '/support/tickets/ticket-1/$action');

SupportWorld resolved() =>
    SupportWorld(ticket: ticketJson(status: 'resolved', canRate: true));

SupportWorld closed() => SupportWorld(
  ticket: ticketJson(
    status: 'closed',
    canReply: false,
    canClose: false,
    canReopen: true,
    reopenUntil: '2026-10-14T10:00:00Z',
  ),
);

void main() {
  group('closing', () {
    testWidgets('Cancel in Close this request? keeps the request open and '
        'sends nothing [case:support.support_ticket_thread.cancel.action]', (
      t,
    ) async {
      final w = SupportWorld();
      await pumpThread(t, w);
      await tapIn(t, close);
      expect(find.text(en.supportCloseConfirmTitle), findsOneWidget);
      await t.tap(find.text(en.supportCancel));
      await qaSettle(t);

      expect(find.text(en.supportCloseConfirmTitle), findsNothing);
      expect(posts(w, 'close'), isEmpty);
      expect(close, findsOneWidget);
      expect(find.text(en.supportStatusOpen), findsOneWidget);
    });

    testWidgets(
      'A close the server refuses says why and leaves the request open with '
      'Close still available '
      '[case:support.support_ticket_thread.support_close_close.api_failure]',
      (t) async {
        final w = SupportWorld();
        w.api.on(
          'POST /support/tickets/ticket-1/close',
          (_) => supportError(409, 'SUPPORT_TICKET_CLOSED'),
        );
        await pumpThread(t, w);
        await tapIn(t, close);
        await t.tap(find.byKey(const Key('support_close_confirm')));
        await qaSettle(t);

        expect(posts(w, 'close'), hasLength(1));
        expect(qaSnackText(t), en.supportErrorTicketClosed);
        expect(find.text(en.supportStatusOpen), findsOneWidget);
        expect(t.widget<ButtonStyleButton>(close).onPressed, isNotNull);
      },
    );
  });

  group('reopening and rating', () {
    testWidgets(
      'A reopen after the window has passed says so and the request stays '
      'closed with Reopen available '
      '[case:support.support_ticket_thread.support_reopen_reopen.api_failure]',
      (t) async {
        final w = closed();
        w.api.on(
          'POST /support/tickets/ticket-1/reopen',
          (_) => supportError(409, 'SUPPORT_REOPEN_WINDOW_PASSED'),
        );
        await pumpThread(t, w);
        await tapIn(t, reopen);

        expect(posts(w, 'reopen'), hasLength(1));
        expect(qaSnackText(t), en.supportErrorReopenWindowPassed);
        expect(find.text(en.supportStatusClosed), findsOneWidget);
        expect(t.widget<ButtonStyleButton>(reopen).onPressed, isNotNull);
      },
    );

    testWidgets(
      'Anything to add?: optional (empty sends no comment), trimmed, 1000 '
      'characters is the limit, emoji kept '
      '[case:support.support_ticket_thread.support_rating_comment_input.validation]',
      (t) async {
        final w = resolved();
        await pumpThread(t, w);
        await tapIn(t, find.byKey(const Key('support_rate_5')));
        final comment = find.byKey(const Key('support_rating_comment'));
        await t.enterText(comment, 'c' * 1200);
        expect(fieldText(t, comment), hasLength(1000));
        await t.enterText(comment, '   ');
        await tapIn(t, find.byKey(const Key('support_rating_submit')));
        expect(posts(w, 'rating').single.body, {'rating': 5});

        final again = resolved();
        await t.pumpWidget(const SizedBox());
        await pumpThread(t, again);
        await tapIn(t, find.byKey(const Key('support_rate_3')));
        await t.enterText(
          find.byKey(const Key('support_rating_comment')),
          '  Quick and kind 🙏  ',
        );
        await tapIn(t, find.byKey(const Key('support_rating_submit')));
        expect(posts(again, 'rating').single.body, {
          'rating': 3,
          'comment': 'Quick and kind 🙏',
        });
      },
    );

    testWidgets(
      'A rating the server refuses says why and keeps the stars and comment '
      'to send again '
      '[case:support.support_ticket_thread.support_rating_submit_rate.api_failure]',
      (t) async {
        final w = resolved();
        w.api.on(
          'POST /support/tickets/ticket-1/rating',
          (_) => supportError(409, 'SUPPORT_ALREADY_RATED'),
        );
        await pumpThread(t, w);
        await tapIn(t, find.byKey(const Key('support_rate_4')));
        await t.enterText(
          find.byKey(const Key('support_rating_comment')),
          'Thanks',
        );
        await tapIn(t, find.byKey(const Key('support_rating_submit')));

        expect(posts(w, 'rating'), hasLength(1));
        expect(qaSnackText(t), en.supportErrorAlreadyRated);
        expect(find.byKey(const Key('support_rating_form')), findsOneWidget);
        expect(
          t
              .widget<IconButton>(find.byKey(const Key('support_rate_4')))
              .isSelected,
          isTrue,
        );
        expect(
          fieldText(t, find.byKey(const Key('support_rating_comment'))),
          'Thanks',
        );
        expect(
          t
              .widget<ButtonStyleButton>(
                find.byKey(const Key('support_rating_submit')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  testWidgets(
    'The reply box: empty or spaces sends nothing, 5000 characters is the '
    'limit, emoji and right-to-left text are sent trimmed '
    '[case:support.support_ticket_thread.support_reply_input.validation]',
    (t) async {
      final w = SupportWorld();
      await pumpThread(t, w);
      await t.tap(send);
      await qaSettle(t);
      await t.enterText(reply, '    ');
      await t.tap(send);
      await qaSettle(t);
      expect(posts(w, 'messages'), isEmpty);

      await t.enterText(reply, 'r' * 5100);
      expect(fieldText(t, reply), hasLength(5000));
      await t.enterText(reply, '  مرحبا, still broken 😩  ');
      await t.tap(send);
      await qaSettle(t);
      expect(
        posts(w, 'messages').single.body['body'],
        'مرحبا, still broken 😩',
      );
      expect(find.text('مرحبا, still broken 😩'), findsOneWidget);
      expect(fieldText(t, reply), isEmpty);
    },
  );

  group('loading', () {
    testWidgets('A request that cannot load explains, and Try again loads it '
        '[case:support.support_ticket_thread.try_again.action]', (t) async {
      final w = SupportWorld();
      w.api.fail('GET /support/tickets/ticket-1', message: 'Server busy.');
      await pumpThread(t, w);
      expect(find.text(en.supportThreadLoadErrorTitle), findsOneWidget);
      expect(find.text('Server busy.'), findsOneWidget);

      w.api.on(
        'GET /support/tickets/ticket-1',
        (_) =>
            qaOk({'success': true, 'ticket': w.ticket, 'messages': w.messages}),
      );
      await tapIn(t, find.text(en.supportTryAgain));
      expect(w.api.sent('GET', '/support/tickets/ticket-1'), hasLength(2));
      expect(find.text(en.supportThreadLoadErrorTitle), findsNothing);
      expect(find.text('Thanks, could you send a screenshot?'), findsOneWidget);
    });

    testWidgets(
      'A Try again that fails again keeps the explanation and the button, '
      'and the next one works '
      '[case:support.support_ticket_thread.try_again.api_failure]',
      (t) async {
        final w = SupportWorld();
        w.api.offline('GET /support/tickets/ticket-1');
        await pumpThread(t, w);
        await tapIn(t, find.text(en.supportTryAgain));
        expect(w.api.sent('GET', '/support/tickets/ticket-1'), hasLength(2));
        expect(find.text(en.supportThreadLoadErrorTitle), findsOneWidget);
        expect(find.text(en.supportErrorOffline), findsOneWidget);
        final retry = find.widgetWithText(TextButton, en.supportTryAgain);
        expect(t.widget<TextButton>(retry).onPressed, isNotNull);

        w.api.on(
          'GET /support/tickets/ticket-1',
          (_) => qaOk({
            'success': true,
            'ticket': w.ticket,
            'messages': w.messages,
          }),
        );
        await tapIn(t, retry);
        expect(
          find.text('Thanks, could you send a screenshot?'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Pull to refresh loads the team’s new reply '
        '[case:support.support_ticket_thread.try_again_onrefresh.action]', (
      t,
    ) async {
      final w = SupportWorld();
      await pumpThread(t, w);
      w.messages.add(
        messageJson(id: 'm-3', author: 'agent', body: 'Fixed in 1.4.1.'),
      );
      await pullToRefresh(t);
      expect(w.api.sent('GET', '/support/tickets/ticket-1'), hasLength(2));
      expect(find.text('Fixed in 1.4.1.'), findsOneWidget);
    });

    testWidgets(
      'A refresh that fails keeps the thread on screen and says the update '
      'did not come through '
      '[case:support.support_ticket_thread.try_again_onrefresh.api_failure]',
      (t) async {
        final w = SupportWorld();
        await pumpThread(t, w);
        w.api.offline('GET /support/tickets/ticket-1');
        await pullToRefresh(t);

        expect(w.api.sent('GET', '/support/tickets/ticket-1'), hasLength(2));
        expect(qaSnackText(t), en.supportErrorOffline);
        expect(
          find.text('Thanks, could you send a screenshot?'),
          findsOneWidget,
        );
        expect(find.text(en.supportThreadLoadErrorTitle), findsNothing);
        expect(t.widget<TextField>(reply).enabled, isTrue);
      },
    );
  });

  group('screen quality', () {
    SupportWorld rich() => SupportWorld(
      ticket: ticketJson(status: 'resolved', canRate: true, canReopen: true),
      messages: [
        messageJson(body: 'When I open a chat the app closes. ' * 6),
        messageJson(id: 'm-2', author: 'agent', body: 'Fixed in 1.4.1.'),
        messageJson(id: 'm-3', author: 'system', body: 'Marked resolved'),
      ],
    );

    testWidgets('lays out with a conversation on phone and tablet, both '
        'themes [case:support.support_ticket_thread.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        rich().api,
        thread,
        loaded: find.text('Fixed in 1.4.1.'),
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:support.support_ticket_thread.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        rich().api,
        thread,
        size: const Size(430, 2000),
        loaded: find.byKey(const Key('support_rating_form')),
      );
    });

    testWidgets('pushed, Back returns to My tickets '
        '[case:support.support_ticket_thread.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        rich().api,
        thread,
        screen: SupportTicketThreadScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:support.support_ticket_thread.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        rich().api,
        thread,
        size: const Size(430, 2200),
        expected: [
          (l) => l.supportStatusResolved,
          (l) => l.supportBannerResolved,
          (l) => l.supportReopen,
          (l) => l.supportCloseTicket,
          (l) => l.supportThreadAgentName,
          (l) => l.supportRateTitle.toUpperCase(),
          (l) => l.supportRateCaption,
          (l) => l.supportReplyHint,
        ],
        // The reference, subject and messages are the member's and the
        // team's own words.
        allow: {
          'CN-2026-000123',
          'App crashes on chat',
          ('When I open a chat the app closes. ' * 6).trim(),
          'Fixed in 1.4.1.',
          'Marked resolved',
        },
      );
    });
  });
}
