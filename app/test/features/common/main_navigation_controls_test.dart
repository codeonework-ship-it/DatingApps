// The app shell's own controls (MainNavigationScreen): the bottom navigation,
// Discover's Messages shortcut, the in-app notification banner and incoming
// call sheets (realtime and push), the automation-build shortcuts, and the
// shell rendered in German. Driven against the recording fake BFF so each
// test asserts the request the control sent (mark read:
// POST /notifications/{me}/{id}/read) and where the member ended up.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/config/feature_flags.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/notifications/screens/notification_inbox_screen.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final _en = qaL10n(const Locale('en'));

Finder _k(String id) => find.byKey(ValueKey(id));

/// The member's notifications, fed the way the realtime connection and the
/// push service feed them (no socket, no Firebase).
class _Inbox extends NotificationNotifier {
  _Inbox(super.ref);

  @override
  Future<void> bootstrap() async {}

  /// A notification arrives while the app is in the foreground.
  void arrive(AppNotification item) => state = state.copyWith(
    items: [item, ...state.items],
    unreadCount: state.unreadCount + 1,
    foregroundEvent: item,
  );

  /// [count] unread notifications are waiting.
  void unread(int count) => state = state.copyWith(
    items: [for (var i = 0; i < count; i++) _notification(id: 'n$i')],
    unreadCount: count,
  );

  /// The member opened a push notification.
  void opened(Map<String, dynamic> data) =>
      state = state.copyWith(pushAction: PushNotificationAction.fromData(data));
}

AppNotification _notification({
  String id = 'n1',
  String eventType = 'match.created',
  String category = 'match',
  String title = 'Priya',
  String body = 'You have a new match.',
  Map<String, dynamic> payload = const {},
  String? actionRoute,
}) => AppNotification(
  id: id,
  sequence: 1,
  eventType: eventType,
  category: category,
  title: title,
  body: body,
  payload: payload,
  isRead: false,
  actionRoute: actionRoute,
  createdAt: DateTime(2026, 10, 3, 9),
);

AppNotification _call() => _notification(
  id: 'call-1',
  eventType: 'call.incoming',
  category: 'call',
  title: 'Priya is calling',
  body: 'Voice call',
);

QaApi _server() {
  final api = QaApi()
    ..json('POST /notifications/*/*/read', <String, dynamic>{'success': true});
  for (var depth = 1; depth <= 6; depth++) {
    api
      ..json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{})
      ..json('POST ${List.filled(depth, '/*').join()}', <String, dynamic>{});
  }
  return api;
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  QaApi api, {
  Map<String, bool> flags = const {},
  Locale? locale,
  ThemeData? theme,
  Size size = const Size(430, 932),
}) async {
  SharedPreferences.setMockInitialValues({});
  await pumpQa(
    tester,
    api,
    const MainNavigationScreen(),
    flags: flags,
    locale: locale,
    theme: theme,
    size: size,
    extra: [notificationProvider.overrideWith(_Inbox.new)],
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(MainNavigationScreen)),
  );
}

_Inbox _inbox(ProviderContainer c) =>
    c.read(notificationProvider.notifier) as _Inbox;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the open filter sheet until [finder] is built and on screen.
Future<void> _revealInSheet(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Finder _navLabel(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

Finder get _badge => _k('qa.nav.unread_badge');

List<String> _reads(QaApi api) => [
  for (final c in api.sent('POST', '/notifications/*/*/read')) c.path,
];

/// The Settings tab's badge shows [count] (or nothing at 0).
void _expectBadge(WidgetTester tester, int count) {
  if (count == 0) {
    expect(_badge, findsNothing);
  } else {
    expect(_badge, findsWidgets);
    expect(tester.widget<Text>(_badge.first).data, '$count');
  }
}

void main() {
  group('navigation', () {
    testWidgets('the Settings tab shows Settings '
        '[case:common.main_navigation.settings.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);
      expect(find.byType(SettingsScreen).hitTestable(), findsNothing);

      await _tap(tester, _navLabel(_en.navSettings));

      expect(container.read(mainNavigationIndexProvider), 4);
      expect(find.byType(SettingsScreen).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.today.screen')).hitTestable(),
        findsNothing,
      );

      // And back to Today from the same bar.
      await _tap(tester, _navLabel(_en.navToday));
      expect(container.read(mainNavigationIndexProvider), 0);
      expect(find.byType(SettingsScreen).hitTestable(), findsNothing);
    });

    testWidgets("Discover's Messages opens the Matches tab on conversations "
        '[case:common.main_navigation.messages_onopenmessages.action]', (
      tester,
    ) async {
      final api = _server();
      // Without intentional dating, Today is the Discover deck.
      final container = await _mount(
        tester,
        api,
        flags: const {'intentional_dating_enabled': false},
      );
      expect(container.read(mainNavigationIndexProvider), 0);

      await _tap(tester, _k('qa.discovery.messages_button').hitTestable());

      expect(container.read(mainNavigationIndexProvider), 1);
      expect(container.read(matchesViewProvider), MatchesView.conversations);
      expect(find.byType(MatchesListScreen).hitTestable(), findsOneWidget);
      // The conversations view, not the Matches deck.
      expect(_k('qa.discovery.messages_button').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('incoming call sheet (realtime)', () {
    testWidgets('an incoming call presents a sheet with the caller and '
        'Dismiss / View '
        '[case:common.main_navigation.view.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);

      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Priya is calling'), findsOneWidget);
      expect(find.text('Voice call'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, _en.commonDismiss),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, _en.commonView), findsOneWidget);
      expect(api.writes, isEmpty, reason: 'presenting marks nothing read');
      _expectBadge(tester, 1);
    });

    testWidgets('Dismiss marks the call read and closes the sheet '
        '[case:common.main_navigation.dismiss.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);
      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();

      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, _en.commonDismiss),
      );

      expect(_reads(api), ['/notifications/me/call-1/read']);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(NotificationInboxScreen), findsNothing);
      _expectBadge(tester, 0);
      expect(container.read(notificationProvider).items.single.isRead, isTrue);
    });

    testWidgets('a failed Dismiss still closes the sheet, keeps the call '
        'unread (badge back) and it can be read from the inbox once the '
        'server is back '
        '[case:common.main_navigation.dismiss.api_failure]', (tester) async {
      final api = _server()..fail('POST /notifications/me/call-1/read');
      final container = await _mount(tester, api);
      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();

      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, _en.commonDismiss),
      );

      expect(_reads(api), [
        '/notifications/me/call-1/read',
      ], reason: 'no retry loop');
      expect(find.byType(BottomSheet), findsNothing);
      // Rolled back: nothing claims it was read.
      expect(container.read(notificationProvider).items.single.isRead, isFalse);
      expect(container.read(notificationProvider).unreadCount, 1);
      _expectBadge(tester, 1);
      expect(tester.takeException(), isNull);

      // Recovery: Settings -> inbox -> the call, with the server back.
      api.json('POST /notifications/me/call-1/read', {'success': true});
      await _tap(tester, _navLabel(_en.navSettings));
      // The inbox is Settings' first row, on screen as the tab opens.
      await tester.tap(_k('qa.settings.notification_inbox'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      await _tap(tester, find.text('Priya is calling'));
      expect(_reads(api), hasLength(2));
      expect(container.read(notificationProvider).items.single.isRead, isTrue);
      expect(container.read(notificationProvider).unreadCount, 0);
    });

    testWidgets('View marks the call read and opens the notification inbox '
        '[case:common.main_navigation.view_2.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);
      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();

      await _tap(tester, find.widgetWithText(FilledButton, _en.commonView));

      expect(_reads(api), ['/notifications/me/call-1/read']);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      expect(find.text('Priya is calling'), findsOneWidget);
      expect(container.read(notificationProvider).unreadCount, 0);
    });

    testWidgets('a failed View still opens the inbox with the call unread, '
        'and tapping it there reads it once the server is back '
        '[case:common.main_navigation.view_2.api_failure]', (tester) async {
      final api = _server()..offline('POST /notifications/me/call-1/read');
      final container = await _mount(tester, api);
      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();

      await _tap(tester, find.widgetWithText(FilledButton, _en.commonView));

      expect(_reads(api), hasLength(1));
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      expect(container.read(notificationProvider).items.single.isRead, isFalse);
      expect(container.read(notificationProvider).unreadCount, 1);
      expect(tester.takeException(), isNull);

      api.json('POST /notifications/me/call-1/read', {'success': true});
      await _tap(tester, find.text('Priya is calling'));
      expect(_reads(api), hasLength(2));
      expect(container.read(notificationProvider).items.single.isRead, isTrue);
    });
  });

  group('notification banner', () {
    testWidgets('a notification shows a banner whose Open marks it read and '
        'opens the inbox '
        '[case:common.main_navigation.open.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);

      _inbox(container).arrive(_notification());
      await tester.pumpAndSettle();
      expect(qaSnackText(tester), contains('Priya: You have a new match.'));
      _expectBadge(tester, 1);

      await _tap(tester, find.widgetWithText(SnackBarAction, _en.commonOpen));

      expect(_reads(api), ['/notifications/me/n1/read']);
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      expect(container.read(notificationProvider).unreadCount, 0);
    });

    testWidgets("a support reply's Open goes straight to the ticket thread "
        '[case:common.main_navigation.open.action]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api);

      _inbox(container).arrive(
        _notification(
          id: 's1',
          eventType: 'support.ticket.replied',
          category: 'support',
          title: 'Support',
          body: 'We replied to your ticket.',
          payload: const {'ticket_id': 't-42'},
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.widgetWithText(SnackBarAction, _en.commonOpen));

      expect(_reads(api), ['/notifications/me/s1/read']);
      final thread = tester.widget<SupportTicketThreadScreen>(
        find.byType(SupportTicketThreadScreen),
      );
      expect(thread.ticketId, 't-42');
      expect(find.byType(NotificationInboxScreen), findsNothing);
    });

    testWidgets('a failed Open still opens the inbox with the notification '
        'unread, and it can be read there once the server is back '
        '[case:common.main_navigation.open.api_failure]', (tester) async {
      final api = _server()
        ..fail('POST /notifications/me/n1/read', status: 503);
      final container = await _mount(tester, api);
      _inbox(container).arrive(_notification());
      await tester.pumpAndSettle();

      await _tap(tester, find.widgetWithText(SnackBarAction, _en.commonOpen));

      expect(_reads(api), hasLength(1));
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      expect(container.read(notificationProvider).items.single.isRead, isFalse);
      expect(container.read(notificationProvider).unreadCount, 1);
      expect(tester.takeException(), isNull);

      api.json('POST /notifications/me/n1/read', {'success': true});
      await _tap(tester, find.text('You have a new match.'));
      expect(_reads(api), hasLength(2));
      expect(container.read(notificationProvider).unreadCount, 0);
    });
  });

  group('incoming call push', () {
    testWidgets('opening a call push presents the incoming call sheet '
        '[case:common.main_navigation.view_call_details.action]', (
      tester,
    ) async {
      final api = _server();
      final container = await _mount(tester, api);

      _inbox(
        container,
      ).opened(const {'event_type': 'call.incoming', 'category': 'call'});
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(_en.navIncomingCallTitle), findsOneWidget);
      expect(find.text(_en.navIncomingCallBody), findsOneWidget);
      expect(find.text(_en.navViewCallDetails), findsOneWidget);
      // The push is handled once.
      expect(container.read(notificationProvider).pushAction, isNull);
      expect(find.byType(NotificationInboxScreen), findsNothing);
    });

    testWidgets('View call details closes the sheet and opens the inbox '
        '[case:common.main_navigation.view_call_details_2.action]', (
      tester,
    ) async {
      final api = _server();
      final container = await _mount(tester, api);
      _inbox(
        container,
      ).opened(const {'event_type': 'call.incoming', 'category': 'call'});
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_en.navViewCallDetails));

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(NotificationInboxScreen), findsOneWidget);
      // Back returns to the shell.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationInboxScreen), findsNothing);
      expect(find.byType(MainNavigationScreen).hitTestable(), findsOneWidget);
    });
  });

  // These shortcuts exist only in builds made with
  // --dart-define=ENABLE_QA_AUTOMATION=true (the Appium runner); a shipped
  // build must not show them (feature_flags_test). Run with that define to
  // exercise them.
  group('automation-build shortcuts', () {
    testWidgets('Filters opens the Discover filter sheet '
        '[case:common.main_navigation.filters.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);

      await _tap(tester, find.widgetWithText(TextButton, _en.discoverFilters));

      expect(find.text(_en.filterSheetTitle), findsOneWidget);
      expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(1));
      await _tap(tester, _k('qa.filters.close'));
      expect(find.text(_en.filterSheetTitle), findsNothing);
    }, skip: !kEnableQaAutomation);

    testWidgets(
      'a failed save from the Filters shortcut explains and keeps the sheet '
      '[case:common.main_navigation.filters.api_failure]',
      (tester) async {
        final api = _server()
          ..json('GET /discovery/*/filters/trust', <String, dynamic>{})
          ..fail(
            'PATCH /discovery/me/filters/trust',
            message: 'Trust filters are taking a break.',
          );
        await _mount(tester, api);
        await _tap(
          tester,
          find.widgetWithText(TextButton, _en.discoverFilters),
        );
        await _revealInSheet(tester, _k('qa.filters.apply_button'));

        await _tap(tester, _k('qa.filters.apply_button'));

        expect(qaSnackText(tester), 'Trust filters are taking a break.');
        expect(_k('qa.filters.apply_button'), findsOneWidget);
        api.on(
          'PATCH /discovery/me/filters/trust',
          (call) => qaOk({'trust_filter': call.body}),
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await _tap(tester, _k('qa.filters.apply_button'));
        expect(api.sent('PATCH', '/discovery/me/filters/trust'), hasLength(2));
        expect(_k('qa.filters.apply_button'), findsNothing);
      },
      skip: !kEnableQaAutomation,
    );

    testWidgets('Verify opens the ID upload '
        '[case:common.main_navigation.verify.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _tap(tester, _navLabel(_en.navProfile));

      await _tap(
        tester,
        find.widgetWithText(TextButton, _en.navQaVerifyShortcut).hitTestable(),
      );

      expect(find.byType(VerificationUploadIdScreen), findsOneWidget);
    }, skip: !kEnableQaAutomation);

    testWidgets('Edit Profile opens the profile editor '
        '[case:common.main_navigation.edit_profile.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _tap(tester, _navLabel(_en.navSettings));

      await _tap(
        tester,
        find.widgetWithText(TextButton, _en.profileEditTitle).hitTestable(),
      );

      expect(find.byType(EditProfileScreen), findsOneWidget);
    }, skip: !kEnableQaAutomation);
  });

  group('German', () {
    const de = Locale('de');
    final l = qaL10n(de);

    testWidgets('the shell, its filter sheet and the call sheet speak German '
        '[case:common.main_navigation.l10n]', (tester) async {
      final api = _server();
      final container = await _mount(tester, api, locale: de);

      // Bottom navigation.
      for (final label in [
        l.navToday,
        l.navMatches,
        l.navEngage,
        l.navProfile,
        l.navSettings,
      ]) {
        expect(_navLabel(label), findsOneWidget, reason: label);
      }
      for (final english in ['Today', 'Engage', 'Profile', 'Settings']) {
        expect(_navLabel(english), findsNothing, reason: english);
      }

      // The filter sheet (from Today's Discovery preferences).
      await _tap(tester, find.byTooltip(l.todayDiscoveryPreferences));
      expect(find.text(l.filterSheetTitle), findsOneWidget);
      for (final text in [
        l.filterAgeRange,
        l.filterCountry,
        l.filterPartyLoverOnly,
        l.filterHookupsOnly,
        l.filterVerifiedOnlyBody,
        l.filterEnableTrust,
        l.commonApply,
      ]) {
        await _revealInSheet(tester, find.text(text));
        expect(find.text(text), findsWidgets, reason: text);
        // Long German labels wrap; nothing overflows on a phone.
        expect(tester.takeException(), isNull, reason: text);
      }
      for (final english in [
        _en.filterSheetTitle,
        _en.filterAgeRange,
        _en.filterProfileLifestyle,
        _en.filterPartyLoverOnly,
        _en.filterVerifiedOnlyBody,
        _en.filterEnableTrust,
        _en.commonApply,
        _en.commonReset,
      ]) {
        expect(find.text(english), findsNothing, reason: english);
      }
      // The labels fit: nothing overflowed on a phone in German.
      expect(tester.takeException(), isNull);
      await _tap(tester, _k('qa.filters.close'));

      // The incoming call sheet.
      _inbox(container).arrive(_call());
      await tester.pumpAndSettle();
      expect(find.text(l.commonDismiss), findsOneWidget);
      expect(find.text(l.commonView), findsOneWidget);
      expect(find.text(_en.commonDismiss), findsNothing);
      expect(find.text(_en.commonView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the shell speaks French too '
        '[case:common.main_navigation.l10n]', (tester) async {
      const fr = Locale('fr');
      final f = qaL10n(fr);
      await _mount(tester, _server(), locale: fr);
      expect(_navLabel(f.navToday), findsOneWidget);
      expect(_navLabel(f.navSettings), findsOneWidget);
      expect(_navLabel(_en.navSettings), findsNothing);
      expect(
        Localizations.localeOf(
          tester.element(find.byType(MainNavigationScreen)),
        ),
        fr,
      );
      expect(
        AppLocalizations.of(
          tester.element(find.byType(MainNavigationScreen)),
        ).navToday,
        f.navToday,
      );
    });
  });

  // Regression (2026-10-03, screenshot): with a look applied the selected
  // Settings icon is a wide pill at the bar's far end, and the "53" badge at
  // its corner was cut off by the bar's rounded edge. The painted badge must
  // lie inside the bar's rounded shape on every look, phone width and count,
  // selected or not.
  group('Settings unread badge stays inside the bar', () {
    final looks = <String, ThemeData?>{
      'no look': null,
      for (final p in ThemePresets.all) p.id: ThemePresets.themeFor(p),
    };
    for (final MapEntry(key: look, value: theme) in looks.entries) {
      testWidgets(
        '$look: "53" and "99+" fit, selected and not, at any text size '
        '[case:common.main_navigation.settings_badge.contained]',
        (tester) async {
          // Phones with a large system font size (Android goes up to 2x).
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          for (final (width, scale) in [
            (430.0, 1.0),
            (360.0, 1.0),
            (430.0, 2.0),
            (360.0, 2.0),
          ]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            final container = await _mount(
              tester,
              _server(),
              theme: theme,
              size: Size(width, 900),
            );
            for (final (count, text) in [(53, '53'), (120, '99+')]) {
              _inbox(container).unread(count);
              for (final selected in [false, true]) {
                container.read(mainNavigationIndexProvider.notifier).state =
                    selected ? 4 : 0;
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 400));
                final where =
                    '$look, ${width.toInt()}dp, text x$scale, "$text", '
                    '${selected ? 'selected' : 'not selected'}';
                expect(find.text(text), findsWidgets, reason: where);
                final bar = tester.getRect(
                  find
                      .ancestor(
                        of: find.byType(BottomNavigationBar),
                        matching: find.byType(GlassContainer),
                      )
                      .first,
                );
                final shape = RRect.fromRectAndRadius(
                  bar,
                  const Radius.circular(30),
                );
                final pill = tester.getRect(
                  find.byKey(const ValueKey('qa.nav.unread_badge_pill')).first,
                );
                // The badge is a stadium: its outline is inside the bar if its
                // flat edges and the outer points of its round ends are.
                final r = pill.height / 2;
                final d = r * (1 - 0.7071);
                final outline = [
                  Offset(pill.left + r, pill.top),
                  Offset(pill.right - r, pill.top),
                  Offset(pill.left + r, pill.bottom),
                  Offset(pill.right - r, pill.bottom),
                  Offset(pill.left, pill.center.dy),
                  Offset(pill.right, pill.center.dy),
                  Offset(pill.left + d, pill.top + d),
                  Offset(pill.right - d, pill.top + d),
                ];
                for (final point in outline) {
                  expect(
                    shape.contains(point),
                    isTrue,
                    reason:
                        '$where: badge point $point is outside the bar $bar',
                  );
                }
                expect(
                  pill.right,
                  lessThanOrEqualTo(bar.right - 2),
                  reason: where,
                );
              }
            }
          }
        },
      );
    }
  });
}
