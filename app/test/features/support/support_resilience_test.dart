import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/support/screens/support_contact_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/support_api.dart';

import 'support_fakes.dart';

// Support that survives real conditions: the signed-out email form, drafts
// kept across a failed send, the server's category list, oversized
// screenshots refused before upload, a reply retried offline with the same
// idempotency key, and an open thread reloading when the team replies.

/// A launcher page that opens [screen], so a test can leave and come back.
Widget _launcher(Widget Function() screen) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const Key('open_screen'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen())),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_screen')));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _fillGuest(
  WidgetTester tester, {
  String email = 'sam@x.io',
}) async {
  await tester.enterText(find.byKey(const Key('support_guest_email')), email);
  await tester.enterText(find.byKey(const Key('support_guest_name')), 'Sam');
  await _tapVisible(tester, const Key('support_guest_category_account_login'));
  await tester.enterText(
    find.byKey(const Key('support_guest_subject')),
    'Cannot finish sign up',
  );
  await tester.enterText(
    find.byKey(const Key('support_guest_description')),
    'The code screen never loads.',
  );
}

class _BigPicker extends SupportImagePicker {
  const _BigPicker();

  @override
  Future<List<XFile>> pick(int max) async {
    final bytes = Uint8List(9 * 1024 * 1024)
      ..setAll(0, const [0xFF, 0xD8, 0xFF, 0xE0]);
    return [XFile.fromData(bytes, name: 'huge.jpg')];
  }
}

void main() {
  group('signed-out contact form', () {
    testWidgets(
      '[case:support.support_contact_form.support_guest_submit.action] sends '
      'the contact payload and confirms with the reference and address',
      (tester) async {
        final api = FakeSupportApi({
          'POST /support/contact': (_) => ok({
            'success': true,
            'received': true,
            'reference': 'CN-2026-000400',
          }, status: 202),
        });
        await pumpSupport(tester, api, const SupportContactFormScreen());
        await _fillGuest(tester);
        await _tapVisible(tester, const Key('support_guest_submit'));

        final sent = api.sent('POST', '/support/contact').single;
        expect(sent.data, {
          'email': 'sam@x.io',
          'name': 'Sam',
          'category': 'account_login',
          'subject': 'Cannot finish sign up',
          'description': 'The code screen never loads.',
          'locale': 'en',
        });
        expect(find.byKey(const Key('support_guest_done')), findsOneWidget);
        expect(
          find.text(
            'Thanks. Your reference is CN-2026-000400. We’ll reply to sam@x.io.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '[case:support.support_contact_form.support_guest_email_input.validation] '
      'an invalid address is caught before anything is sent',
      (tester) async {
        final api = FakeSupportApi({});
        await pumpSupport(tester, api, const SupportContactFormScreen());
        await _fillGuest(tester, email: 'sam-at-example');
        await _tapVisible(tester, const Key('support_guest_submit'));

        expect(api.requests, isEmpty);
        expect(
          find.text('Enter a valid email address so we can reply.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '[case:support.support_contact_form.support_guest_submit.api_failure] '
      'switched off: explains it and keeps everything typed; offline says so',
      (tester) async {
        var reply = serverError(
          403,
          'FEATURE_DISABLED',
          extra: {'feature_flag': 'support_ticketing_enabled'},
        );
        final api = FakeSupportApi({'POST /support/contact': (_) => reply});
        await pumpSupport(tester, api, const SupportContactFormScreen());
        await _fillGuest(tester);
        await _tapVisible(tester, const Key('support_guest_submit'));

        expect(
          find.byKey(const Key('support_guest_unavailable')),
          findsOneWidget,
        );
        expect(find.text('Cannot finish sign up'), findsOneWidget);
        expect(find.text('The code screen never loads.'), findsOneWidget);

        reply = offline;
        await _tapVisible(tester, const Key('support_guest_submit'));
        expect(
          find.text(
            'Can’t reach Connect right now. Check your connection and try again.',
          ),
          findsOneWidget,
        );
        expect(api.sent('POST', '/support/contact'), hasLength(2));
      },
    );
  });

  group('new request draft', () {
    testWidgets(
      '[case:support.support_ticket_form.submit_support_ticket.api_failure] '
      'a send that fails offline keeps the request when the member leaves',
      (tester) async {
        var reply = offline;
        final api = FakeSupportApi({
          'POST /support/tickets': (_) => reply,
          'GET /support/tickets': (_) =>
              ok({'success': true, 'tickets': <Object>[]}),
          'GET /support/tickets/ticket-1': (_) => ok({
            'success': true,
            'ticket': ticketJson(status: 'new'),
            'messages': [messageJson()],
          }),
        });
        await pumpSupport(
          tester,
          api,
          _launcher(() => const SupportTicketFormScreen()),
        );
        await _open(tester);
        await _tapVisible(tester, const Key('support_category_technical'));
        await tester.enterText(
          find.byKey(const Key('support_subject')),
          'Chat freezes',
        );
        await tester.enterText(
          find.byKey(const Key('support_description')),
          'After sending a photo.',
        );
        await _tapVisible(tester, const Key('submit_support_ticket'));
        expect(find.byKey(const Key('support_form_error')), findsOneWidget);

        await _back(tester);
        await _open(tester);
        expect(find.byKey(const Key('support_draft_restored')), findsOneWidget);
        expect(find.text('Chat freezes'), findsOneWidget);
        expect(find.text('After sending a photo.'), findsOneWidget);
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const Key('support_category_technical')),
              )
              .selected,
          isTrue,
        );

        // Back online: it sends, and the draft is gone for next time.
        reply = ok({
          'success': true,
          'ticket': ticketJson(status: 'new'),
          'messages': [messageJson()],
        }, status: 201);
        await _tapVisible(tester, const Key('submit_support_ticket'));
        expect(find.byType(SupportTicketThreadScreen), findsOneWidget);
        await _back(tester);
        await _open(tester);
        expect(find.byKey(const Key('support_draft_restored')), findsNothing);
        expect(find.text('Chat freezes'), findsNothing);
      },
    );

    testWidgets(
      '[case:support.support_ticket_form.support_draft_discard.action] '
      'Discard draft empties the form and forgets it',
      (tester) async {
        final api = FakeSupportApi({});
        await pumpSupport(
          tester,
          api,
          _launcher(() => const SupportTicketFormScreen()),
        );
        await _open(tester);
        await tester.enterText(
          find.byKey(const Key('support_subject')),
          'Old idea',
        );
        await _back(tester);
        await _open(tester);
        expect(find.text('Old idea'), findsOneWidget);

        await _tapVisible(tester, const Key('support_draft_discard'));
        expect(find.text('Old idea'), findsNothing);
        expect(find.byKey(const Key('support_draft_restored')), findsNothing);
        await _back(tester);
        await _open(tester);
        expect(find.byKey(const Key('support_draft_restored')), findsNothing);
      },
    );
  });

  testWidgets(
    '[case:support.support_ticket_form.support_category_x.action] offers the '
    'categories the server lists, in its order',
    (tester) async {
      final api = FakeSupportApi({
        'GET /support/categories': (_) => ok({
          'success': true,
          'categories': [
            {'key': 'technical', 'label': 'Technical problem'},
            {'key': 'payments_billing', 'label': 'Payments & billing'},
            {'key': 'not_in_this_app', 'label': 'New thing'},
          ],
        }),
      });
      await pumpSupport(tester, api, const SupportTicketFormScreen());

      expect(api.sent('GET', '/support/categories'), hasLength(1));
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((c) => (c.key! as ValueKey<String>).value)
          .toList();
      expect(chips, [
        'support_category_technical',
        'support_category_payments_billing',
      ]);
    },
  );

  testWidgets(
    '[case:support.support_ticket_form.support_add_screenshot.api_failure] a '
    'screenshot over 8 MB is refused without uploading',
    (tester) async {
      final api = FakeSupportApi({});
      await pumpSupport(
        tester,
        api,
        const SupportTicketFormScreen(),
        extra: [
          supportImagePickerProvider.overrideWithValue(const _BigPicker()),
        ],
      );
      await _tapVisible(tester, const Key('support_add_screenshot'));

      expect(api.sent('POST', '/support/attachments'), isEmpty);
      expect(
        find.textContaining(
          'That file is too large. Images can be up to 8 MB.',
        ),
        findsOneWidget,
      );
    },
  );

  group('thread', () {
    testWidgets(
      '[case:support.support_ticket_thread.retry.action] '
      '[case:support.support_ticket_thread.retry.api_failure] an offline reply '
      'stays in the box and Retry resends it with the same key',
      (tester) async {
        var reply = offline;
        final api = FakeSupportApi({
          'GET /support/tickets/ticket-1': (_) => ok({
            'success': true,
            'ticket': ticketJson(status: 'pending_member'),
            'messages': [messageJson()],
          }),
          'GET /support/tickets': (_) =>
              ok({'success': true, 'tickets': <Object>[]}),
          'POST /support/tickets/ticket-1/messages': (_) => reply,
        });
        await pumpSupport(
          tester,
          api,
          const SupportTicketThreadScreen(ticketId: 'ticket-1'),
        );
        await tester.enterText(
          find.byKey(const Key('support_reply')),
          'Still broken.',
        );
        await tester.tap(find.byKey(const Key('support_reply_send')));
        await tester.pumpAndSettle();

        expect(find.text('Still broken.'), findsOneWidget);
        expect(find.byType(SnackBarAction), findsOneWidget);

        reply = ok({
          'success': true,
          'ticket': ticketJson(),
          'message': messageJson(id: 'm-9', body: 'Still broken.'),
        }, status: 201);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        final posts = api.sent('POST', '/support/tickets/ticket-1/messages');
        expect(posts, hasLength(2));
        expect(
          posts.last.headers['Idempotency-Key'],
          posts.first.headers['Idempotency-Key'],
        );
        // Sent: the box is empty and the message is in the thread.
        final box = tester.widget<TextField>(
          find.byKey(const Key('support_reply')),
        );
        expect(box.controller!.text, isEmpty);
        expect(find.text('Still broken.'), findsOneWidget);
      },
    );

    testWidgets(
      'a reply notification for this ticket reloads the open thread',
      (tester) async {
        var agentSaid = <Map<String, dynamic>>[];
        final api = FakeSupportApi({
          'GET /support/tickets/ticket-1': (_) => ok({
            'success': true,
            'ticket': ticketJson(status: 'pending_member'),
            'messages': [messageJson(), ...agentSaid],
          }),
          'GET /support/tickets': (_) =>
              ok({'success': true, 'tickets': <Object>[]}),
        });
        late WidgetRef ref;
        await pumpSupport(
          tester,
          api,
          Consumer(
            builder: (context, r, _) {
              ref = r;
              return const SupportTicketThreadScreen(ticketId: 'ticket-1');
            },
          ),
        );
        expect(api.sent('GET', '/support/tickets/ticket-1'), hasLength(1));

        // Another ticket's news leaves this thread alone.
        notifySupportActivity(ref, 'ticket-2');
        await tester.pumpAndSettle();
        expect(api.sent('GET', '/support/tickets/ticket-1'), hasLength(1));

        agentSaid = [
          messageJson(id: 'm-2', author: 'agent', body: 'Fixed in 1.4.1.'),
        ];
        notifySupportActivity(ref, 'ticket-1');
        await tester.pumpAndSettle();
        expect(api.sent('GET', '/support/tickets/ticket-1'), hasLength(2));
        expect(find.text('Fixed in 1.4.1.'), findsOneWidget);
      },
    );
  });
}
