import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/notifications/screens/notification_inbox_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';

import '../../support/qa_api.dart';

// Notification inbox controls: every action is asserted by the request the
// server receives and by what the member sees afterwards, including the
// failure paths (server error, offline) that used to fail silently.

class _Push extends PushNotificationService {
  _Push() : super(Dio());
  final starts = <String>[];

  @override
  Future<void> start({
    required String userId,
    required PushOpenHandler onOpened,
  }) async => starts.add(userId);
}

Map<String, dynamic> _note(
  String id,
  int sequence,
  String eventType,
  String title, {
  bool read = false,
  String? route,
}) => {
  'id': id,
  'sequence': sequence,
  'event_type': eventType,
  'category': 'like',
  'title': title,
  'body': 'Tap to see',
  'is_read': read,
  'action_route': route,
  'created_at': DateTime.now()
      .subtract(const Duration(minutes: 5))
      .toUtc()
      .toIso8601String(),
};

/// The member's inbox: two unread (a like and a support reply), one read
/// friend request.
QaApi _inbox({List<Map<String, dynamic>>? items}) {
  final rows =
      items ??
      [
        _note('n-like', 3, 'like.received', 'Someone liked you'),
        _note(
          'n-support',
          2,
          'support.reply',
          'Support replied',
          route: '/support/tickets/t-9',
        ),
        _note(
          'n-friend',
          1,
          'friend_request.received',
          'Ravi sent a friend request',
          read: true,
        ),
      ];
  return QaApi()
    ..json('GET /notifications/me', {'notifications': rows})
    ..json('GET /notifications/me/unread-count', {
      'unread_count': rows.where((r) => r['is_read'] != true).length,
    })
    ..json('GET /notifications/me/preferences', {
      'preferences': <String, dynamic>{},
    })
    ..json('POST /notifications/me/read-all', {'success': true})
    ..json('POST /notifications/me/*/read', {'success': true})
    ..json('DELETE /notifications/me/*', {'success': true});
}

Future<_Push> _pump(WidgetTester tester, QaApi api) async {
  final push = _Push();
  await pumpQa(
    tester,
    api,
    const NotificationInboxScreen(),
    extra: [pushNotificationServiceProvider.overrideWithValue(push)],
  );
  return push;
}

const _readAll = ValueKey('qa.notifications.read_all');

final _offlineText = qaL10n(const Locale('en')).networkCannotReachService;

/// Unread rows show a 5 px dot.
int _unreadDots(WidgetTester tester) => tester
    .widgetList<CircleAvatar>(find.byType(CircleAvatar))
    .where((a) => a.radius == 5)
    .length;

Future<void> _swipeAway(WidgetTester tester, String title) async {
  await tester.drag(find.text(title), const Offset(-600, 0));
  await qaSettle(tester);
}

void main() {
  group('Read all', () {
    testWidgets('marks every notification read on the server and in the list '
        '[case:notifications.notification_inbox.read_all.action]', (
      tester,
    ) async {
      final api = _inbox();
      await _pump(tester, api);
      expect(_unreadDots(tester), 2);

      await tester.tap(find.byKey(_readAll));
      await tester.pump();
      // Gone in the next frame: a second tap cannot send it twice.
      expect(find.byKey(_readAll), findsNothing);
      await qaSettle(tester);

      expect(api.writeLines, ['POST /notifications/me/read-all']);
      expect(_unreadDots(tester), 0);
      expect(find.byKey(_readAll), findsNothing);
      expect(find.text('Someone liked you'), findsOneWidget);
    });

    testWidgets(
      'a failure explains, puts the unread state back and retry works '
      '(regression: the error was swallowed) '
      '[case:notifications.notification_inbox.read_all.api_failure]',
      (tester) async {
        final api = _inbox()
          ..on(
            'POST /notifications/me/read-all',
            (_) => const QaReply(500, ''),
          );
        await _pump(tester, api);

        await tester.tap(find.byKey(_readAll));
        await qaSettle(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.text("Couldn't mark them all as read. Try again."),
          findsOneWidget,
        );
        expect(_unreadDots(tester), 2);
        expect(find.byKey(_readAll), findsOneWidget);
        expect(api.sent('POST', '/notifications/me/read-all'), hasLength(1));

        api.offline('POST /notifications/me/read-all');
        await tester.tap(find.byKey(_readAll));
        await qaSettle(tester);
        expect(find.text(_offlineText), findsOneWidget);

        api.json('POST /notifications/me/read-all', {'success': true});
        await tester.tap(find.byKey(_readAll));
        await qaSettle(tester);
        expect(api.sent('POST', '/notifications/me/read-all'), hasLength(3));
        expect(_unreadDots(tester), 0);
      },
    );
  });

  group('Pull to refresh', () {
    testWidgets(
      'reloads the inbox, the unread count and preferences and restarts '
      'push registration [case:notifications.notification_inbox.you_are_all_caught_up_onrefresh.action]',
      (tester) async {
        final api = _inbox(items: const []);
        final push = await _pump(tester, api);
        expect(find.text('You are all caught up'), findsOneWidget);
        expect(push.starts, ['me']);

        api.json('GET /notifications/me', {
          'notifications': [_note('n-new', 9, 'like.received', 'New like')],
        });
        api.json('GET /notifications/me/unread-count', {'unread_count': 1});
        await tester.fling(
          find.text('You are all caught up'),
          const Offset(0, 400),
          1000,
        );
        await tester.pumpAndSettle();

        expect(api.sent('GET', '/notifications/me'), hasLength(2));
        expect(api.sent('GET', '/notifications/me/unread-count'), hasLength(2));
        expect(api.sent('GET', '/notifications/me/preferences'), hasLength(2));
        expect(push.starts, ['me', 'me']);
        expect(find.text('New like'), findsOneWidget);
        expect(find.byKey(_readAll), findsOneWidget);
      },
    );

    testWidgets(
      'a failed refresh keeps the list and says why; a failed first load is '
      'not "all caught up" and Retry recovers (regression) '
      '[case:notifications.notification_inbox.you_are_all_caught_up_onrefresh.api_failure]',
      (tester) async {
        final api = _inbox();
        await _pump(tester, api);
        api.fail('GET /notifications/me', message: 'Inbox is resting.');
        await tester.fling(
          find.text('Someone liked you'),
          const Offset(0, 400),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('Inbox is resting.'), findsOneWidget);
        expect(find.text('Someone liked you'), findsOneWidget);

        // Cold start while the inbox is down.
        final down = _inbox()..offline('GET /notifications/me');
        await _pump(tester, down);
        await tester.pumpWidget(const SizedBox());
        await _pump(tester, down);
        expect(find.text('You are all caught up'), findsNothing);
        expect(find.text(_offlineText), findsOneWidget);
        down.json('GET /notifications/me', {
          'notifications': [_note('n-back', 4, 'like.received', 'Back again')],
        });
        await tester.tap(find.byKey(const ValueKey('qa.notifications.retry')));
        await qaSettle(tester);
        expect(find.text('Back again'), findsOneWidget);
      },
    );
  });

  group('Swipe to dismiss', () {
    testWidgets(
      'deletes the notification on the server and removes the row '
      '[case:notifications.notification_inbox.someone_liked_you_ondismissed.action]',
      (tester) async {
        final api = _inbox();
        await _pump(tester, api);
        await _swipeAway(tester, 'Someone liked you');

        expect(api.writeLines, ['DELETE /notifications/me/n-like']);
        expect(find.text('Someone liked you'), findsNothing);
        expect(_unreadDots(tester), 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a failed delete puts the row back and explains (regression: the row '
      'vanished, stayed on the server and the error was swallowed) '
      '[case:notifications.notification_inbox.someone_liked_you_ondismissed.api_failure]',
      (tester) async {
        final api = _inbox()
          ..on('DELETE /notifications/me/*', (_) => const QaReply(500, ''));
        await _pump(tester, api);
        await _swipeAway(tester, 'Someone liked you');

        expect(tester.takeException(), isNull);
        expect(
          find.text("Couldn't remove that notification. Try again."),
          findsOneWidget,
        );
        expect(find.text('Someone liked you'), findsOneWidget);
        expect(_unreadDots(tester), 2);
        expect(api.sent('DELETE', '/notifications/me/n-like'), hasLength(1));

        api.json('DELETE /notifications/me/*', {'success': true});
        await _swipeAway(tester, 'Someone liked you');
        expect(find.text('Someone liked you'), findsNothing);
        expect(api.sent('DELETE', '/notifications/me/n-like'), hasLength(2));
      },
    );
  });

  testWidgets(
    'regression: a failed delete of the only notification still explains '
    'and brings it back [case:notifications.notification_inbox.someone_liked_you_ondismissed.api_failure]',
    (tester) async {
      final api =
          _inbox(items: [_note('n-only', 1, 'like.received', 'Only one')])..on(
            'DELETE /notifications/me/*',
            // A real network answers after the list has re-rendered.
            (_) => const QaReply(
              0,
              null,
              offline: true,
              delay: Duration(milliseconds: 300),
            ),
          );
      await _pump(tester, api);
      await _swipeAway(tester, 'Only one');
      expect(tester.takeException(), isNull);
      expect(find.text(_offlineText), findsOneWidget);
      expect(find.text('Only one'), findsOneWidget);
      expect(find.text('You are all caught up'), findsNothing);
    },
  );

  group('Open a notification', () {
    testWidgets('a like marks it read and opens who liked me '
        '[case:notifications.notification_inbox.inkwell_ontap.action]', (
      tester,
    ) async {
      final api = _inbox();
      await _pump(tester, api);
      await tester.tap(find.text('Someone liked you'));
      await qaSettle(tester);
      tester.takeException(); // network avatars cannot load in tests

      expect(api.sent('POST', '/notifications/me/n-like/read'), hasLength(1));
      expect(find.byType(LikedMeScreen), findsOneWidget);
    });

    testWidgets('a support reply opens that ticket thread '
        '[case:notifications.notification_inbox.inkwell_ontap.support_route]', (
      tester,
    ) async {
      final api = _inbox();
      await _pump(tester, api);
      await tester.tap(find.text('Support replied'));
      await qaSettle(tester);

      expect(
        api.sent('POST', '/notifications/me/n-support/read'),
        hasLength(1),
      );
      final thread = tester.widget<SupportTicketThreadScreen>(
        find.byType(SupportTicketThreadScreen),
      );
      expect(thread.ticketId, 't-9');
    });

    testWidgets('a read friend request opens Friends without re-marking it '
        '[case:notifications.notification_inbox.inkwell_ontap.friend_route]', (
      tester,
    ) async {
      final api = _inbox();
      await _pump(tester, api);
      await tester.tap(find.text('Ravi sent a friend request'));
      await qaSettle(tester);

      expect(api.writes, isEmpty);
      expect(find.byType(FriendsScreen), findsOneWidget);
    });

    testWidgets(
      'if marking read fails the destination still opens and the row stays '
      'unread [case:notifications.notification_inbox.inkwell_ontap.api_failure]',
      (tester) async {
        final api = _inbox()..offline('POST /notifications/me/*/read');
        await _pump(tester, api);
        await tester.tap(find.text('Someone liked you'));
        await qaSettle(tester);
        expect(find.byType(LikedMeScreen), findsOneWidget);
        await tester.pageBack();
        await qaSettle(tester);
        tester.takeException();
        expect(find.byType(NotificationInboxScreen), findsOneWidget);
        expect(_unreadDots(tester), 2);
      },
    );
  });

  testWidgets('the inbox renders translated in every locale '
      '[case:notifications.notification_inbox.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final push = _Push();
      await pumpQa(
        tester,
        _inbox(),
        const NotificationInboxScreen(),
        locale: locale,
        extra: [pushNotificationServiceProvider.overrideWithValue(push)],
      );
      final l10n = qaL10n(locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.notificationsTitle), findsOneWidget);
      expect(find.text(l10n.notificationsReadAll), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
