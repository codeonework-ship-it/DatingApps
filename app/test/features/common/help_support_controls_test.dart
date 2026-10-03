// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_tickets_screen.dart';

import '../../support/qa_api.dart';

// Help & Support centre controls: Contact support and My tickets open their
// screens, pull-to-refresh asks the server again (GET /support/tickets) and
// shows what came back, and a failed load or refresh says so and recovers.

Map<String, dynamic> _summary({int unread = 0, int open = 0}) => {
  'success': true,
  'tickets': const <Object>[],
  'unread_total': unread,
  'open_total': open,
};

QaApi _server({int unread = 0, int open = 0}) => QaApi()
  ..json('GET /support/tickets', _summary(unread: unread, open: open))
  ..json('GET /support/categories', {
    'success': true,
    'categories': const <Object>[],
  });

const _contact = Key('create_support_ticket');
const _myTickets = Key('support_my_tickets');
const _badge = Key('support_unread_badge');
const _loadError = Key('support_tickets_load_error');
const _retry = Key('support_tickets_retry');

final _en = qaL10n(const Locale('en'));

/// Drags the centre down far enough to trigger the refresh on any view
/// height (the indicator arms at a quarter of the viewport).
Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(
    find.text(_en.supportCentreTitle),
    const Offset(0, 800),
    1000,
  );
  await tester.pumpAndSettle();
}

Finder _subtitleOfMyTickets(String text) =>
    find.descendant(of: find.byKey(_myTickets), matching: find.text(text));

void main() {
  testWidgets('Contact support opens the new request form '
      '[case:common.help_support.create_support_ticket.action]', (
    tester,
  ) async {
    final api = _server();
    await pumpQa(tester, api, const HelpSupportScreen());
    expect(find.byType(SupportTicketFormScreen), findsNothing);

    await tester.tap(find.byKey(_contact));
    await tester.pumpAndSettle();

    expect(find.byType(SupportTicketFormScreen), findsOneWidget);
    // The form covers the centre.
    expect(find.byKey(_contact).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My tickets opens the ticket list and the centre reloads the '
      'unread count on the way back '
      '[case:common.help_support.support_my_tickets.action]', (tester) async {
    final api = _server(unread: 2, open: 2);
    await pumpQa(tester, api, const HelpSupportScreen(), launcher: true);
    expect(find.byKey(_badge), findsOneWidget);
    expect(_subtitleOfMyTickets(_en.supportUnreadReplies(2)), findsOneWidget);
    final before = api.sent('GET', '/support/tickets').length;

    await tester.tap(find.byKey(_myTickets));
    await tester.pumpAndSettle();
    expect(find.byType(SupportTicketsScreen), findsOneWidget);

    // The replies were read in the list; the server now has none unread.
    api.json('GET /support/tickets', _summary(open: 2));
    final listNavigator = Navigator.of(
      tester.element(find.byType(SupportTicketsScreen)),
    );
    listNavigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(SupportTicketsScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(
      api.sent('GET', '/support/tickets').length,
      greaterThan(before),
      reason: 'returning from My tickets reloads the summary',
    );
    expect(find.byKey(_badge), findsNothing);
    expect(_subtitleOfMyTickets(_en.supportOpenRequests(2)), findsOneWidget);
  });

  testWidgets(
    'pull to refresh asks the server again and shows the new counts '
    '[case:common.help_support.if_someone_is_in_immediate_dange_onrefresh.action]',
    (tester) async {
      final api = _server();
      await pumpQa(
        tester,
        api,
        const HelpSupportScreen(),
        size: const Size(430, 2000),
      );
      expect(api.sent('GET', '/support/tickets'), hasLength(1));
      expect(find.byKey(_badge), findsNothing);
      expect(
        _subtitleOfMyTickets(_en.supportMyTicketsSubtitle),
        findsOneWidget,
      );
      // The whole centre, down to the emergency note, is inside the pull area.
      expect(find.text(_en.supportEmergencyNote), findsOneWidget);

      api.json('GET /support/tickets', _summary(unread: 3, open: 1));
      await _pullToRefresh(tester);

      final calls = api.sent('GET', '/support/tickets');
      expect(calls, hasLength(2));
      expect(calls.last.query['status'], 'all');
      expect(find.byKey(_badge), findsOneWidget);
      expect(_subtitleOfMyTickets(_en.supportUnreadReplies(3)), findsOneWidget);
      expect(find.byKey(_loadError), findsNothing);
    },
  );

  testWidgets(
    'a failed refresh explains, keeps contact usable and Try again '
    'recovers with one request per tap (regression: the failure was silent) '
    '[case:common.help_support.if_someone_is_in_immediate_dange_onrefresh.api_failure] '
    '[case:common.help_support.support_tickets_retry.action]',
    (tester) async {
      final api = _server(unread: 1, open: 1);
      await pumpQa(tester, api, const HelpSupportScreen());
      expect(find.byKey(_loadError), findsNothing);

      api.offline('GET /support/tickets');
      await _pullToRefresh(tester);

      expect(api.sent('GET', '/support/tickets'), hasLength(2));
      expect(find.byKey(_loadError), findsOneWidget);
      expect(find.text(_en.supportTicketsLoadErrorTitle), findsOneWidget);
      expect(find.text(_en.supportErrorOffline), findsOneWidget);
      // Contacting the team does not depend on the list.
      expect(find.byKey(_contact).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // A server error shows the server's reason.
      api.fail('GET /support/tickets', message: 'Tickets are resting.');
      await tester.tap(find.byKey(_retry));
      await tester.pumpAndSettle();
      expect(api.sent('GET', '/support/tickets'), hasLength(3));
      expect(find.text('Tickets are resting.'), findsOneWidget);

      // Back up: Try again loads the summary and the notice goes away.
      api.json('GET /support/tickets', _summary(unread: 2, open: 2));
      await tester.tap(find.byKey(_retry));
      await tester.pump();
      // While it loads the button is gone, so a second tap cannot send twice.
      expect(find.byKey(_retry), findsNothing);
      await tester.pumpAndSettle();
      expect(api.sent('GET', '/support/tickets'), hasLength(4));
      expect(find.byKey(_loadError), findsNothing);
      expect(find.byKey(_badge), findsOneWidget);
      expect(_subtitleOfMyTickets(_en.supportUnreadReplies(2)), findsOneWidget);
    },
  );

  testWidgets(
    'a failed first load is not shown as "no requests"; pulling again recovers '
    '[case:common.help_support.if_someone_is_in_immediate_dange_onrefresh.api_failure]',
    (tester) async {
      final api = _server()..fail('GET /support/tickets', status: 503);
      await pumpQa(tester, api, const HelpSupportScreen());
      expect(find.byKey(_loadError), findsOneWidget);
      expect(find.text(_en.supportTicketsLoadErrorTitle), findsOneWidget);

      api.json('GET /support/tickets', _summary(open: 4));
      await _pullToRefresh(tester);
      expect(find.byKey(_loadError), findsNothing);
      expect(_subtitleOfMyTickets(_en.supportOpenRequests(4)), findsOneWidget);
    },
  );

  testWidgets('the support centre renders translated, with no English left '
      '[case:common.help_support.l10n]', (tester) async {
    for (final locale in const [Locale('de'), Locale('fr')]) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      final api = _server(unread: 2, open: 2);
      await pumpQa(tester, api, const HelpSupportScreen(), locale: locale);
      for (final text in [
        l10n.supportCentreTitle,
        l10n.supportContactTitle,
        l10n.supportMyTicketsTitle,
        l10n.supportUnreadReplies(2),
      ]) {
        expect(find.text(text), findsOneWidget, reason: '$locale: $text');
      }
      for (final english in [
        _en.supportCentreTitle,
        _en.supportContactTitle,
        _en.supportMyTicketsTitle,
        _en.supportUnreadReplies(2),
        _en.supportEmergencyNote,
      ]) {
        expect(find.text(english), findsNothing, reason: '$locale: $english');
      }

      // The failure notice is translated too.
      api.offline('GET /support/tickets');
      await tester.fling(
        find.text(l10n.supportCentreTitle),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.supportTicketsLoadErrorTitle), findsOneWidget);
      expect(find.text(l10n.supportErrorOffline), findsOneWidget);
      expect(find.text(l10n.supportTryAgain), findsOneWidget);
      expect(find.text(_en.supportTicketsLoadErrorTitle), findsNothing);
      expect(find.text(_en.supportTryAgain), findsNothing);

      // Further down: quick answers and the emergency note.
      await tester.scrollUntilVisible(
        find.text(l10n.supportEmergencyNote),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.supportFaqBillingTitle), findsOneWidget);
      expect(find.text(_en.supportEmergencyNote), findsNothing);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
