// Control-level tests for the shared support widgets (support_widgets.dart):
// opening and closing a sent screenshot, removing a screenshot from a draft,
// retrying a failed upload (and a retry that fails again), and the widgets
// in every shipped locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/support_api.dart';
import 'package:verified_dating_app/features/support/support_models.dart';
import 'package:verified_dating_app/features/support/widgets/support_widgets.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'support_qa_world.dart';

final addScreenshot = find.byKey(const Key('support_add_screenshot'));
final submit = find.byKey(const Key('submit_support_ticket'));

/// The request form with a topic, subject and description filled in.
Future<void> openFilledForm(WidgetTester t, SupportWorld w) async {
  await pumpQa(
    t,
    w.api,
    const SupportTicketFormScreen(),
    size: const Size(900, 2400),
    extra: [
      supportImagePickerProvider.overrideWithValue(const OneShotPicker()),
    ],
  );
  await tapIn(t, find.byKey(const Key('support_category_technical')));
  await t.enterText(find.byKey(const Key('support_subject')), 'App crashes');
  await t.enterText(
    find.byKey(const Key('support_description')),
    'When I open a chat the app closes.',
  );
}

/// The sent screenshot announced as "Screenshot [name]".
Finder thumbnail(String name) => find.byWidgetPredicate(
  (w) =>
      w is Semantics && w.properties.label == en.supportAttachmentImage(name),
);

List<QaCall> uploads(SupportWorld w) =>
    w.api.sent('POST', '/support/attachments');
List<QaCall> creates(SupportWorld w) => w.api.sent('POST', '/support/tickets');

void main() {
  group('a sent screenshot', () {
    SupportWorld withScreenshot() => SupportWorld(
      messages: [
        messageJson(
          attachments: [
            {
              'id': 'att-9',
              'filename': 'crash.png',
              'content_type': 'image/png',
              'size_bytes': 70,
            },
          ],
        ),
      ],
    );

    testWidgets(
      'Tapping a sent screenshot loads it with the member’s session and opens '
      'it full size '
      '[case:support.support_widgets.broken_image_outlined_icon_broke.action] '
      '[case:support.support_widgets.close_icon_close_rounded.action]',
      (t) async {
        final w = withScreenshot();
        await pumpQa(
          t,
          w.api,
          const SupportTicketThreadScreen(ticketId: 'ticket-1'),
          size: const Size(900, 2400),
        );
        expect(
          w.api.sent('GET', '/support/tickets/ticket-1/attachments/att-9'),
          hasLength(1),
        );
        await tapIn(t, thumbnail('crash.png'));
        expect(find.byType(Dialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(InteractiveViewer),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is Image && w.semanticLabel == 'crash.png',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Close on the full-size screenshot returns to the conversation '
        '[case:support.support_widgets.close_icon_close_rounded_2.action]', (
      t,
    ) async {
      final w = withScreenshot();
      await pumpQa(
        t,
        w.api,
        const SupportTicketThreadScreen(ticketId: 'ticket-1'),
        size: const Size(900, 2400),
      );
      await tapIn(t, thumbnail('crash.png'));
      await t.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byTooltip('Close'),
        ),
      );
      await qaSettle(t);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(SupportTicketThreadScreen), findsOneWidget);
      expect(find.text('When I open a chat the app closes.'), findsOneWidget);
    });
  });

  group('screenshots in a draft', () {
    testWidgets(
      'Remove takes a screenshot out of the draft and the request is sent '
      'without it [case:support.support_widgets.remove_name.action]',
      (t) async {
        final w = SupportWorld();
        await openFilledForm(t, w);
        await tapIn(t, addScreenshot);
        final remove = find.byTooltip(
          en.supportRemoveAttachment('screenshot-1.jpg'),
        );
        expect(remove, findsOneWidget);
        await tapIn(t, remove);
        expect(remove, findsNothing);
        await tapIn(t, submit);
        expect(creates(w).single.body['attachment_ids'], isEmpty);
      },
    );

    testWidgets(
      'Retry upload sends the failed screenshot again, and once it is up the '
      'request carries its id [case:support.support_widgets.retry_upload.action]',
      (t) async {
        final w = SupportWorld();
        w.api.fail('POST /support/attachments', message: 'Upload hiccup.');
        await openFilledForm(t, w);
        await tapIn(t, addScreenshot);
        expect(find.text('screenshot-1.jpg: Upload hiccup.'), findsOneWidget);

        w.api.on('POST /support/attachments', (_) {
          return QaReply(201, {
            'success': true,
            'attachment': {
              'id': 'att-7',
              'filename': 'screenshot-1.jpg',
              'content_type': 'image/jpeg',
              'size_bytes': 8,
            },
          });
        });
        await tapIn(t, find.byTooltip(en.supportRetryUpload));
        expect(uploads(w), hasLength(2));
        expect(find.byTooltip(en.supportRetryUpload), findsNothing);
        expect(find.text('screenshot-1.jpg: Upload hiccup.'), findsNothing);
        await tapIn(t, submit);
        expect(creates(w).single.body['attachment_ids'], ['att-7']);
      },
    );

    testWidgets(
      'A retry that fails again keeps the screenshot with its error and the '
      'retry button, and the request is not sent with it pending '
      '[case:support.support_widgets.retry_upload.api_failure]',
      (t) async {
        final w = SupportWorld();
        w.api.fail('POST /support/attachments', message: 'Upload hiccup.');
        await openFilledForm(t, w);
        await tapIn(t, addScreenshot);
        w.api.offline('POST /support/attachments');
        await tapIn(t, find.byTooltip(en.supportRetryUpload));

        expect(uploads(w), hasLength(2));
        expect(
          find.text('screenshot-1.jpg: ${en.supportErrorOffline}'),
          findsOneWidget,
        );
        expect(find.byTooltip(en.supportRetryUpload), findsOneWidget);
        await tapIn(t, submit);
        expect(find.text(en.supportErrorUploadsPending), findsOneWidget);
        expect(creates(w), isEmpty);
      },
    );
  });

  testWidgets('status chips, notices and attachments render in every shipped '
      'locale with nothing left in English '
      '[case:support.support_widgets.l10n]', (t) async {
    await qaExpectRendersInAllLocales(
      t,
      SupportWorld().api,
      () => Scaffold(
        body: ListView(
          children: [
            for (final status in SupportStatus.values)
              SupportStatusChip(status: status),
            const SupportUnavailablePanel(),
            const SupportAttachmentView(
              ticketId: 'ticket-1',
              attachment: SupportAttachment(
                id: 'att-1',
                filename: 'receipt.pdf',
                contentType: 'application/pdf',
                sizeBytes: 1572864,
              ),
            ),
          ],
        ),
      ),
      expected: [
        (l) => l.supportStatusOpen,
        (l) => l.supportStatusWaitingForYou,
        (l) => l.supportStatusOnHold,
        (l) => l.supportStatusResolved,
        (l) => l.supportStatusClosed,
        (l) => l.supportUnavailableTitle,
        (l) => l.supportUnavailableBody,
      ],
      // "Open" is the Dutch word too.
      allow: {'receipt.pdf', '1.5 MB', 'Open'},
    );
  });
}
