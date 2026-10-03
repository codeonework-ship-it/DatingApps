// A stateful support BFF on the shared recording fake (qa_api.dart) for the
// support control tests: the ticket list, one ticket thread, replies, close,
// reopen, rating, uploads and the signed-out contact form. Commands change
// the state the way the server does, so the screen's next read shows it.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/support/support_api.dart';

import '../../support/qa_api.dart';
import 'support_fakes.dart' show messageJson, ticketJson;

export 'support_fakes.dart' show messageJson, ticketJson;

final en = qaL10n(const Locale('en'));

/// The smallest JPEG header the tray recognises as an image.
final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46]);

/// A 1x1 transparent PNG, for attachment thumbnails that really decode.
final png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Answers the screenshot picker with one small JPEG per pick.
class OneShotPicker extends SupportImagePicker {
  const OneShotPicker();

  @override
  Future<List<XFile>> pick(int max) async => [
    XFile.fromData(jpeg, name: 'IMG_0001.jpg'),
  ];
}

class SupportWorld {
  SupportWorld({
    Map<String, dynamic>? ticket,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? tickets,
  }) : ticket = ticket ?? ticketJson(),
       messages =
           messages ??
           [
             messageJson(),
             messageJson(
               id: 'm-2',
               author: 'agent',
               body: 'Thanks, could you send a screenshot?',
             ),
           ],
       tickets = tickets ?? [ticketJson()] {
    api
      ..on(
        'GET /support/tickets',
        (_) => qaOk({
          'success': true,
          'tickets': this.tickets,
          'unread_total': 0,
          'open_total': this.tickets.length,
        }),
      )
      ..on(
        'GET /support/tickets/ticket-1',
        (_) => qaOk({
          'success': true,
          'ticket': this.ticket,
          'messages': this.messages,
        }),
      )
      ..on('POST /support/tickets/ticket-1/messages', (c) {
        final message = messageJson(
          id: 'm-${this.messages.length + 1}',
          body: c.body['body'] as String,
        );
        this.messages.add(message);
        this.ticket = ticketJson();
        return QaReply(201, {
          'success': true,
          'ticket': this.ticket,
          'message': message,
        });
      })
      ..on('POST /support/tickets/ticket-1/close', (_) {
        this.ticket = ticketJson(
          status: 'closed',
          canReply: false,
          canClose: false,
        );
        return qaOk({'success': true, 'ticket': this.ticket});
      })
      ..on('POST /support/tickets/ticket-1/reopen', (_) {
        this.ticket = ticketJson();
        return qaOk({'success': true, 'ticket': this.ticket});
      })
      ..on('POST /support/tickets/ticket-1/rating', (c) {
        this.ticket = ticketJson(
          status: 'resolved',
          satisfaction: {
            'rating': c.body['rating'],
            'comment': c.body['comment'] ?? '',
            'rated_at': '2026-09-30T12:00:00Z',
          },
        );
        return qaOk({'success': true, 'ticket': this.ticket});
      })
      ..on('POST /support/attachments', (_) {
        uploads++;
        return QaReply(201, {
          'success': true,
          'attachment': {
            'id': 'att-$uploads',
            'filename': 'screenshot-$uploads.jpg',
            'content_type': 'image/jpeg',
            'size_bytes': 8,
          },
        });
      })
      ..on(
        'POST /support/tickets',
        (_) => QaReply(201, {
          'success': true,
          'ticket': ticketJson(status: 'new'),
          'messages': [messageJson()],
        }),
      )
      ..on(
        'POST /support/contact',
        (_) => const QaReply(202, {
          'success': true,
          'received': true,
          'reference': 'CN-2026-000400',
        }),
      )
      ..on(
        'GET /support/tickets/ticket-1/attachments/*',
        (_) => QaReply(200, png),
      )
      ..on(
        'GET /support/categories',
        (_) => qaOk({
          'success': true,
          'categories': [
            for (final key in [
              'account_login',
              'verification',
              'payments_billing',
              'safety_harassment',
              'matches_chat',
              'technical',
              'feature_request',
              'privacy_data',
              'other',
            ])
              {'key': key},
          ],
        }),
      );
  }

  final api = QaApi();
  Map<String, dynamic> ticket;
  final List<Map<String, dynamic>> messages;
  List<Map<String, dynamic>> tickets;
  int uploads = 0;
}

/// A server error with the BFF's support error envelope.
QaReply supportError(int status, String code) => QaReply(status, {
  'success': false,
  'error': 'server says $code',
  'error_code': code,
});

Future<void> tapIn(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await qaSettle(t);
}

/// Pulls the refreshable list down far enough to arm its RefreshIndicator
/// (a quarter of the list's height, which is large on a tall test view) and
/// lets the refresh run.
Future<void> pullToRefresh(WidgetTester t) async {
  final list = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
  final height = t.getSize(list).height;
  final gesture = await t.startGesture(
    t.getTopLeft(list) + const Offset(40, 40),
  );
  for (var i = 0; i < 20; i++) {
    await gesture.moveBy(Offset(0, height / 20));
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await t.pump();
  await qaSettle(t, frames: 20);
}

String fieldText(WidgetTester t, Finder field) =>
    t.widget<TextField>(field).controller!.text;
