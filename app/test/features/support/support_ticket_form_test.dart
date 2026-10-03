import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/support_api.dart';

import 'support_fakes.dart';

class _FakePicker extends SupportImagePicker {
  const _FakePicker();

  @override
  Future<List<XFile>> pick(int max) async => [
    XFile.fromData(
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46]),
      name: 'IMG_0001.jpg',
    ),
  ];
}

Map<String, dynamic> _created({bool duplicate = false}) => {
  'success': true,
  'ticket': ticketJson(status: 'new'),
  'messages': [messageJson()],
  if (duplicate) 'duplicate': true,
};

Future<void> _fillForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('support_category_technical')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const Key('support_subject')),
    'App crashes on chat',
  );
  await tester.enterText(
    find.byKey(const Key('support_description')),
    'When I open a chat the app closes.',
  );
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('submit_support_ticket')));
  await tester.tap(find.byKey(const Key('submit_support_ticket')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a ticket with the contract payload and opens it '
      '[case:support.support_ticket_form.submit_support_ticket.action] '
      '[case:support.support_ticket_form.support_subject_input.action] '
      '[case:support.support_ticket_form.support_description_input.action]', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'POST /support/tickets': (_) => ok(_created(), status: 201),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[], 'unread_total': 0}),
    });
    await pumpSupport(tester, api, const SupportTicketFormScreen());

    await _fillForm(tester);
    await _submit(tester);

    final posts = api.sent('POST', '/support/tickets');
    expect(posts, hasLength(1));
    final body = posts.single.data as Map<String, dynamic>;
    expect(body['category'], 'technical');
    expect(body['subject'], 'App crashes on chat');
    expect(body['description'], 'When I open a chat the app closes.');
    expect(body['attachment_ids'], isEmpty);
    expect(body['platform'], isNotEmpty);
    expect(body['app_version'], isNotEmpty);
    expect(body['locale'], 'en');
    expect(body.containsKey('device_model'), isFalse);
    expect(posts.single.headers['Idempotency-Key'], isNotEmpty);

    // Navigated to the new thread, which shows the reference.
    expect(find.byType(SupportTicketThreadScreen), findsOneWidget);
    expect(find.text('CN-2026-000123'), findsOneWidget);
    expect(
      find.text('Request CN-2026-000123 sent. We’ll reply here.'),
      findsOneWidget,
    );
  });

  testWidgets('uploads screenshots first and sends their ids '
      '[case:support.support_ticket_form.support_add_screenshot.action]', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'POST /support/attachments': (_) => ok({
        'success': true,
        'attachment': {
          'id': 'att-1',
          'filename': 'screenshot-1.jpg',
          'content_type': 'image/jpeg',
          'size_bytes': 8,
        },
      }, status: 201),
      'POST /support/tickets': (_) => ok(_created(), status: 201),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
    });
    await pumpSupport(
      tester,
      api,
      const SupportTicketFormScreen(),
      extra: [
        supportImagePickerProvider.overrideWithValue(const _FakePicker()),
      ],
    );

    await _fillForm(tester);
    await tester.ensureVisible(find.byKey(const Key('support_add_screenshot')));
    await tester.tap(find.byKey(const Key('support_add_screenshot')));
    await tester.pumpAndSettle();

    final upload = api.sent('POST', '/support/attachments').single;
    final form = upload.data as FormData;
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'screenshot-1.jpg');
    expect(form.files.single.value.contentType.toString(), 'image/jpeg');

    await _submit(tester);
    final body =
        api.sent('POST', '/support/tickets').single.data
            as Map<String, dynamic>;
    expect(body['attachment_ids'], ['att-1']);
  });

  testWidgets('says so when the same request was already raised', (
    tester,
  ) async {
    final api = FakeSupportApi({
      'POST /support/tickets': (_) => ok(_created(duplicate: true)),
      'GET /support/tickets': (_) =>
          ok({'success': true, 'tickets': <Object>[]}),
    });
    await pumpSupport(tester, api, const SupportTicketFormScreen());
    await _fillForm(tester);
    await _submit(tester);

    expect(
      find.text(
        'You already sent this request, so we opened it: CN-2026-000123.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows rate limits and the open-ticket cap as real errors', (
    tester,
  ) async {
    var reply = serverError(
      429,
      'SUPPORT_RATE_LIMITED',
      extra: {'retry_after_seconds': 120},
    );
    final api = FakeSupportApi({'POST /support/tickets': (_) => reply});
    await pumpSupport(tester, api, const SupportTicketFormScreen());
    await _fillForm(tester);
    await _submit(tester);

    expect(
      find.text(
        'You’ve sent several requests in a short time. Try again in 2 '
        'minutes.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SupportTicketThreadScreen), findsNothing);

    reply = serverError(409, 'SUPPORT_TOO_MANY_OPEN');
    await _submit(tester);
    expect(
      find.textContaining('You already have 10 open requests.'),
      findsOneWidget,
    );

    // Each server answer gets a fresh idempotency key for the next attempt.
    final keys = api
        .sent('POST', '/support/tickets')
        .map((r) => r.headers['Idempotency-Key'])
        .toSet();
    expect(keys, hasLength(2));
  });

  testWidgets('validates the subject before calling the server: a topic '
      'first, 4 to 120 characters, spaces do not count '
      '[case:support.support_ticket_form.support_subject_input.validation]', (
    tester,
  ) async {
    final api = FakeSupportApi({});
    await pumpSupport(tester, api, const SupportTicketFormScreen());

    await _submit(tester);
    expect(find.text('Choose a topic.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('support_category_other')));
    await tester.enterText(find.byKey(const Key('support_subject')), 'Hi');
    await _submit(tester);
    expect(
      find.text('Use 4 to 120 characters for the subject.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('support_subject')), '       ');
    await _submit(tester);
    expect(
      find.text('Use 4 to 120 characters for the subject.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('support_subject')), 's' * 150);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('support_subject')))
          .controller!
          .text,
      hasLength(120),
    );
    // Only the category list was read; nothing was sent.
    expect(api.requests.where((r) => r.method != 'GET'), isEmpty);
  });

  testWidgets('safety topic points to SOS and emergency services', (
    tester,
  ) async {
    final api = FakeSupportApi({});
    await pumpSupport(tester, api, const SupportTicketFormScreen());

    expect(find.byKey(const Key('support_safety_note')), findsNothing);
    await tester.tap(
      find.byKey(const Key('support_category_safety_harassment')),
    );
    await tester.pump();
    expect(find.byKey(const Key('support_safety_note')), findsOneWidget);
    expect(find.text('Open SOS'), findsOneWidget);
  });

  testWidgets('feature disabled shows the unavailable state', (tester) async {
    final api = FakeSupportApi({
      'POST /support/tickets': (_) => serverError(
        403,
        'FEATURE_DISABLED',
        extra: {'feature_flag': 'support_ticketing_enabled'},
      ),
    });
    await pumpSupport(tester, api, const SupportTicketFormScreen());
    await _fillForm(tester);
    await _submit(tester);

    expect(find.byKey(const Key('support_unavailable')), findsOneWidget);
    expect(
      find.text('Support requests are not available right now'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('submit_support_ticket')), findsNothing);
  });
}
