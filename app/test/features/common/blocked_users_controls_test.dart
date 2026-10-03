// Control-level tests for Blocked users: unblock (confirm / cancel / server
// failure), the list re-read, and Retry after a failed load.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/blocked_users_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

class _BlockServer {
  _BlockServer() {
    api
      ..on('GET /blocked-users/me', (_) => qaOk({'blocked_users': blocked}))
      ..on('POST /safety/unblock', (call) {
        final id = call.body['blocked_user_id'];
        blocked = blocked.where((row) => row['id'] != id).toList();
        return qaOk({'success': true});
      });
  }

  final api = QaApi();
  List<Map<String, dynamic>> blocked = [
    {'id': 'u-ravi', 'name': 'Ravi'},
    {'id': 'u-anon'},
  ];

  List<QaCall> get unblocks => api.sent('POST', '/safety/unblock');
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _open(
  WidgetTester tester,
  _BlockServer server, {
  Locale? locale,
}) => pumpQa(
  tester,
  server.api,
  const BlockedUsersScreen(),
  launcher: true,
  locale: locale,
);

void main() {
  testWidgets(
    'Unblock → confirm unblocks on the server, re-reads the list and confirms '
    '[case:common.blocked_users.blocked_unblock_x.action] '
    '[case:common.blocked_users.unblock_user.action] '
    '[case:common.blocked_users.blocked_unblock_confirm.action]',
    (tester) async {
      final server = _BlockServer();
      await _open(tester, server);
      expect(find.text('Ravi'), findsOneWidget);
      // A member without a name is shown in the member's language.
      expect(find.text(en.blockedUnknownUser), findsOneWidget);

      await tester.tap(_key('qa.blocked.unblock.u-ravi'));
      await qaSettle(tester);
      expect(find.text(en.blockedUnblockTitle), findsOneWidget);
      expect(find.text(en.blockedUnblockBody('Ravi')), findsOneWidget);
      expect(server.unblocks, isEmpty);

      server.api.calls.clear();
      await tester.tap(_key('qa.blocked.unblock_confirm'));
      await qaSettle(tester);

      expect(server.unblocks.single.body, {
        'user_id': 'me',
        'blocked_user_id': 'u-ravi',
      });
      expect(server.api.sent('GET', '/blocked-users/me'), hasLength(1));
      expect(find.text(en.blockedUnblockTitle), findsNothing);
      // Still on Blocked users (the dialog closed, not the screen).
      expect(find.byType(BlockedUsersScreen), findsOneWidget);
      expect(find.text('Ravi'), findsNothing);
      expect(qaSnackText(tester), en.blockedUnblockedSnack('Ravi'));
      expect(find.text(en.blockedUnknownUser), findsOneWidget);
    },
  );

  testWidgets('Cancel keeps the member blocked and sends nothing '
      '[case:common.blocked_users.blocked_unblock_cancel.action]', (tester) async {
    final server = _BlockServer();
    await _open(tester, server);
    await tester.tap(_key('qa.blocked.unblock.u-ravi'));
    await qaSettle(tester);
    await tester.tap(_key('qa.blocked.unblock_cancel'));
    await qaSettle(tester);

    expect(find.text(en.blockedUnblockTitle), findsNothing);
    expect(find.byType(BlockedUsersScreen), findsOneWidget);
    expect(server.unblocks, isEmpty);
    expect(find.text('Ravi'), findsOneWidget);
    expect(qaSnackText(tester), isNull);
  });

  testWidgets(
    'a failed unblock explains and leaves the member blocked; the button '
    'still works [case:common.blocked_users.blocked_unblock_x.api_failure]',
    (tester) async {
      final server = _BlockServer();
      server.api.fail('POST /safety/unblock', status: 503);
      await _open(tester, server);
      await tester.tap(_key('qa.blocked.unblock.u-ravi'));
      await qaSettle(tester);
      await tester.tap(_key('qa.blocked.unblock_confirm'));
      await qaSettle(tester);

      expect(qaSnackText(tester), en.blockedUnblockFailed);
      expect(find.text('Ravi'), findsOneWidget);
      expect(server.unblocks, hasLength(1));

      // Offline is the same message, and the member can try again.
      server.api.offline('POST /safety/unblock');
      ScaffoldMessenger.of(
        tester.element(find.byType(BlockedUsersScreen)),
      ).clearSnackBars();
      await qaSettle(tester);
      await tester.tap(_key('qa.blocked.unblock.u-ravi'));
      await qaSettle(tester);
      expect(find.text(en.blockedUnblockTitle), findsOneWidget);
      await tester.tap(_key('qa.blocked.unblock_confirm'));
      await qaSettle(tester);
      expect(qaSnackText(tester), en.blockedUnblockFailed);
      expect(server.unblocks, hasLength(2));
    },
  );

  testWidgets(
    'if the list cannot be re-read after an unblock, the unblocked member '
    'still leaves the list (regression) '
    '[case:common.blocked_users.blocked_unblock_confirm.reload_failure]',
    (tester) async {
      final server = _BlockServer();
      await _open(tester, server);
      server.api.fail('GET /blocked-users/me', status: 503);
      await tester.tap(_key('qa.blocked.unblock.u-ravi'));
      await qaSettle(tester);
      await tester.tap(_key('qa.blocked.unblock_confirm'));
      await qaSettle(tester);

      expect(server.unblocks, hasLength(1));
      expect(qaSnackText(tester), en.blockedUnblockedSnack('Ravi'));
      expect(find.text('Ravi'), findsNothing);
      expect(find.text(en.blockedUnknownUser), findsOneWidget);
    },
  );

  testWidgets('a failed load is not shown as "no blocked users"; Retry reloads '
      '(regression) [case:common.blocked_users.blocked_retry.action]', (tester) async {
    final server = _BlockServer();
    server.api.offline('GET /blocked-users/me');
    await _open(tester, server);

    expect(find.text(en.blockedEmpty), findsNothing);
    expect(find.text(en.commonSomethingWentWrongTryAgain), findsOneWidget);
    expect(_key('qa.blocked.retry'), findsOneWidget);

    server.api.on(
      'GET /blocked-users/me',
      (_) => qaOk({'blocked_users': server.blocked}),
    );
    await tester.tap(_key('qa.blocked.retry'));
    await qaSettle(tester);
    expect(server.api.sent('GET', '/blocked-users/me'), hasLength(2));
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text(en.commonSomethingWentWrongTryAgain), findsNothing);
  });

  testWidgets('an empty list says so [case:common.blocked_users.empty_state]', (
    tester,
  ) async {
    final server = _BlockServer()..blocked = [];
    await _open(tester, server);
    expect(find.text(en.blockedEmpty), findsOneWidget);
  });

  testWidgets('Blocked users renders translated in all 10 languages '
      '[case:common.blocked_users.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final l10n = qaL10n(locale);
      await _open(tester, _BlockServer(), locale: locale);
      expect(find.text(l10n.privacyBlockedUsers), findsOneWidget);
      expect(find.text(l10n.blockedUnblock), findsNWidgets(2));
      expect(find.text(l10n.blockedUnknownUser), findsOneWidget);
      await tester.tap(_key('qa.blocked.unblock.u-ravi'));
      await qaSettle(tester);
      expect(find.text(l10n.blockedUnblockBody('Ravi')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
