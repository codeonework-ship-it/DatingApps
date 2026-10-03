import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/notification_settings_screen.dart';
import 'package:verified_dating_app/features/notifications/screens/notification_inbox_screen.dart';

import '../../support/qa_api.dart';

// Notification settings: every switch saves the member's preferences
// (PATCH /notifications/{me}/preferences), both ways, and a failed save puts
// the switch back with the reason under the list (server text as sent, by
// product decision; the app's own fallbacks are translated).

const _error = ValueKey('qa.notifications.error');

class _Account {
  _Account() {
    api
      ..json('GET /notifications/me', {'notifications': <Object>[]})
      ..json('GET /notifications/me/unread-count', {'unread_count': 3})
      ..on(
        'GET /notifications/me/preferences',
        (_) => qaOk({
          'preferences': {...prefs},
        }),
      );
    healthy();
  }

  final api = QaApi();
  final prefs = <String, dynamic>{
    'notify_new_match': true,
    'notify_new_message': true,
    'notify_likes': true,
    'notify_match_nudges': true,
    'notify_incoming_calls': true,
    'notify_safety': true,
    'notify_friend_plans': true,
    'in_app_notifications_enabled': true,
    'push_notifications_enabled': true,
  };

  void healthy() => api.on('PATCH /notifications/me/preferences', (c) {
    prefs.addAll(c.body);
    return qaOk({
      'preferences': {...prefs},
    });
  });

  List<Map<String, dynamic>> get saves => api
      .sent('PATCH', '/notifications/me/preferences')
      .map((c) => c.body)
      .toList();
}

Future<void> _open(WidgetTester tester, _Account account, {Locale? locale}) =>
    pumpQa(
      tester,
      account.api,
      const NotificationSettingsScreen(),
      locale: locale,
    );

SwitchListTile _switch(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey(key)));
  await qaSettle(tester, frames: 4);
}

String? _errorText(WidgetTester tester) {
  final found = find.byKey(_error);
  return found.evaluate().isEmpty ? null : tester.widget<Text>(found).data;
}

void main() {
  final en = qaL10n(const Locale('en'));

  const toggles = [
    (
      'notifications_in_app',
      'qa.notifications.in_app',
      'in_app_notifications_enabled',
    ),
    (
      'notifications_push',
      'qa.notifications.push',
      'push_notifications_enabled',
    ),
    (
      'notifications_new_matches',
      'qa.notifications.new_matches',
      'notify_new_match',
    ),
    (
      'notifications_new_messages',
      'qa.notifications.new_messages',
      'notify_new_message',
    ),
    ('notifications_likes', 'qa.notifications.likes', 'notify_likes'),
    (
      'notifications_match_nudges',
      'qa.notifications.match_nudges',
      'notify_match_nudges',
    ),
    (
      'notifications_incoming_calls',
      'qa.notifications.incoming_calls',
      'notify_incoming_calls',
    ),
    ('notifications_safety', 'qa.notifications.safety', 'notify_safety'),
    (
      'notifications_friend_plans',
      'qa.notifications.friend_plans',
      'notify_friend_plans',
    ),
  ];

  for (final (name, key, field) in toggles) {
    testWidgets('$key turns $field off and back on '
        '[case:common.notification_settings.$name.action]', (tester) async {
      final account = _Account();
      await _open(tester, account);
      expect(_switch(tester, key).value, isTrue);

      await _tap(tester, key);
      expect(_switch(tester, key).value, isFalse);
      expect(account.prefs[field], isFalse);

      await _tap(tester, key);
      expect(_switch(tester, key).value, isTrue);

      final saves = account.saves;
      expect(saves, hasLength(2));
      // Off: only this preference changes.
      expect(saves.first, {
        for (final entry in account.prefs.entries)
          entry.key: entry.key != field,
      });
      // Back on: everything on again.
      expect(saves.last.values.every((v) => v == true), isTrue);
      expect(saves.last.keys.toSet(), account.prefs.keys.toSet());
      expect(_errorText(tester), isNull);
    });

    testWidgets('$key refused: the switch goes back and the reason shows '
        '[case:common.notification_settings.$name.api_failure]', (
      tester,
    ) async {
      final account = _Account();
      account.api.fail(
        'PATCH /notifications/me/preferences',
        status: 500,
        message: 'Preferences are locked during maintenance.',
      );
      await _open(tester, account);

      await _tap(tester, key);

      expect(account.saves, hasLength(1));
      expect(account.saves.single[field], isFalse);
      expect(_switch(tester, key).value, isTrue);
      expect(_switch(tester, key).onChanged, isNotNull);
      expect(_errorText(tester), 'Preferences are locked during maintenance.');
      expect(account.prefs[field], isTrue);

      // Saving again once the server is back clears the message.
      account.healthy();
      await _tap(tester, key);
      expect(account.saves, hasLength(2));
      expect(_switch(tester, key).value, isFalse);
      expect(_errorText(tester), isNull);
    });
  }

  testWidgets('offline: the switch goes back with a translated reason '
      '[case:common.notification_settings.notifications_push.api_failure]', (
    tester,
  ) async {
    final account = _Account();
    account.api.offline('PATCH /notifications/me/preferences');
    await _open(tester, account);

    await _tap(tester, 'qa.notifications.push');

    expect(_switch(tester, 'qa.notifications.push').value, isTrue);
    expect(_errorText(tester), en.networkOfflineTryAgain);
  });

  testWidgets(
    'a failure with no server message shows the app\'s own translated text '
    '[case:common.notification_settings.notifications_new_matches.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.on(
        'PATCH /notifications/me/preferences',
        (_) => const QaReply(502, null),
      );
      await _open(tester, account);

      await _tap(tester, 'qa.notifications.new_matches');

      expect(_switch(tester, 'qa.notifications.new_matches').value, isTrue);
      expect(_errorText(tester), en.notificationsPrefsUpdateFailed);
    },
  );

  testWidgets('the inbox row shows the unread count and opens the inbox '
      '[case:common.notification_settings.notifications_inbox.action]', (
    tester,
  ) async {
    final account = _Account();
    await _open(tester, account);
    expect(find.text(en.notificationsInboxUnread(3)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qa.notifications.inbox')));
    await qaSettle(tester, frames: 5);

    expect(find.byType(NotificationInboxScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(account.api.writes, isEmpty);
  });

  testWidgets('Notifications renders in every shipped language '
      '[case:common.notification_settings.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await _open(tester, _Account(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(
        find.text(l10n.notificationsTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.notificationsPushTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.notificationsInboxUnread(3)),
        findsOneWidget,
        reason: '$locale',
      );
    }
  });
}
