import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/main.dart';

import '../../support/qa_api.dart';

// Logout from Settings: the device stops receiving this member's pushes
// (DELETE /notifications/{me}/devices/{deviceId}), the server session is
// revoked (POST /auth/logout), the local session (memory + the OS credential
// store) is wiped and the member lands on Welcome with nothing of the old
// session left behind. Signing out must never depend on the network: when
// the server cannot be reached the member is still signed out on this device,
// and the device's push token is deleted so the old device record cannot
// keep delivering this member's pushes. Both sign-outs ask first.

const _logout = ValueKey('qa.settings.logout');
const _logoutConfirm = ValueKey('qa.settings.logout.confirm');
const _logoutCancel = ValueKey('qa.settings.logout.cancel');
const _logoutAll = ValueKey('qa.settings.logout_all');
const _logoutAllConfirm = ValueKey('qa.settings.logout_all.confirm');
const _deviceKey = 'push.me.fcm.device_id';
const _tokenKey = 'push.me.fcm.token';
const _refreshKey = 'connect.auth.refresh_token';

QaApi _server() {
  final api = QaApi()
    ..json('DELETE /notifications/me/devices/device-42', <String, dynamic>{})
    ..json('POST /auth/logout', <String, dynamic>{'success': true});
  for (var depth = 1; depth <= 5; depth++) {
    api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
  }
  return api;
}

/// How many times the device's push token was deleted.
var _tokenDeletes = 0;

/// The real push service on the fake BFF, with token deletion recorded
/// instead of calling Firebase.
Override _recordingPush() => pushNotificationServiceProvider.overrideWith(
  (ref) => PushNotificationService(
    ref.read(apiClientProvider),
    deleteDeviceToken: () async => _tokenDeletes++,
  ),
);

Future<ProviderContainer> _openSettings(WidgetTester tester, QaApi api) async {
  await pumpQa(tester, api, const SettingsScreen(), extra: [_recordingPush()]);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SettingsScreen)),
  );
  // The member was on another tab before opening Settings.
  container.read(mainNavigationIndexProvider.notifier).state = 4;
  await tester.scrollUntilVisible(
    find.byKey(_logout),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  return container;
}

Future<void> _expectSignedOut(
  WidgetTester tester,
  ProviderContainer container,
) async {
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(find.byType(SettingsScreen), findsNothing);
  final auth = container.read(authNotifierProvider);
  expect(auth.isAuthenticated, isFalse);
  expect(auth.userId, isNull);
  expect(container.read(mainNavigationIndexProvider), 0);
  expect(AuthSessionStore.instance.accessToken, isNull);
  expect(AuthSessionStore.instance.refreshToken, isNull);
  expect(await const FlutterSecureStorage().read(key: _refreshKey), isNull);
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString(_deviceKey), isNull);
  expect(prefs.getString(_tokenKey), isNull);
}

/// Taps Sign out and confirms the dialog.
Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byKey(_logout));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_logoutConfirm));
  await qaSettle(tester);
}

void main() {
  setUp(() {
    _tokenDeletes = 0;
    // Push is configured for this build, and this device registered for the
    // member's pushes as device-42.
    dotenv.testLoad(
      mergeWith: const {
        'FIREBASE_API_KEY': 'qa-key',
        'FIREBASE_APP_ID': 'qa-app',
        'FIREBASE_PROJECT_ID': 'qa-project',
        'FIREBASE_MESSAGING_SENDER_ID': 'qa-sender',
      },
    );
    SharedPreferences.setMockInitialValues({
      _deviceKey: 'device-42',
      _tokenKey: 'fcm-token-42',
    });
    FlutterSecureStorage.setMockInitialValues({});
    AuthSessionStore.instance.update(
      accessToken: 'qa-access',
      refreshToken: 'qa-refresh',
    );
  });

  tearDown(() {
    dotenv.clean();
    AuthSessionStore.instance.clear();
  });

  testWidgets(
    'Logout unregisters this device, revokes the session and shows Welcome '
    '[case:common.settings.logout.action]',
    (tester) async {
      final api = _server();
      final container = await _openSettings(tester, api);
      expect(
        await const FlutterSecureStorage().read(key: _refreshKey),
        'qa-refresh',
      );

      await _signOut(tester);

      expect(api.writeLines, [
        'DELETE /notifications/me/devices/device-42',
        'POST /auth/logout',
      ]);
      await _expectSignedOut(tester, container);
      // Welcome is the only route: Back cannot return to the old session.
      expect(
        Navigator.of(tester.element(find.byType(WelcomeScreen))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('Logout while offline still signs the member out on this device '
      '[case:common.settings.logout.api_failure]', (tester) async {
    final api = _server()
      ..offline('DELETE /notifications/me/devices/device-42')
      ..offline('POST /auth/logout');
    final container = await _openSettings(tester, api);

    await _signOut(tester);

    // Each request is tried once; nothing is retried in a loop.
    expect(api.writeLines, [
      'DELETE /notifications/me/devices/device-42',
      'POST /auth/logout',
    ]);
    await _expectSignedOut(tester, container);
    expect(qaSnackText(tester), isNull);
  });

  testWidgets('Logout when the server rejects it still signs the member out '
      '[case:common.settings.logout.api_failure]', (tester) async {
    final api = _server()
      ..fail('DELETE /notifications/me/devices/device-42', status: 503)
      ..fail('POST /auth/logout', message: 'Session store unavailable.');
    final container = await _openSettings(tester, api);

    await _signOut(tester);

    expect(api.sent('POST', '/auth/logout'), hasLength(1));
    expect(
      api.sent('DELETE', '/notifications/me/devices/device-42'),
      hasLength(1),
    );
    await _expectSignedOut(tester, container);
  });

  testWidgets('a double tap on the confirm button sends each request once '
      '[case:common.settings.logout.action]', (tester) async {
    final api = _server();
    final container = await _openSettings(tester, api);

    await tester.tap(find.byKey(_logout));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_logoutConfirm));
    await tester.tap(find.byKey(_logoutConfirm), warnIfMissed: false);
    await qaSettle(tester);

    expect(api.sent('DELETE', '/notifications/me/devices/*'), hasLength(1));
    expect(api.sent('POST', '/auth/logout'), hasLength(1));
    await _expectSignedOut(tester, container);
  });

  testWidgets(
    'Logout on a device never registered for push only revokes the session '
    '[case:common.settings.logout.no_push_device]',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = _server();
      final container = await _openSettings(tester, api);

      await _signOut(tester);

      expect(api.writeLines, ['POST /auth/logout']);
      await _expectSignedOut(tester, container);
    },
  );

  testWidgets('Sign out asks first; Cancel keeps the member signed in '
      '[case:common.settings.logout.confirm_cancel]', (tester) async {
    final api = _server();
    final container = await _openSettings(tester, api);

    await tester.tap(find.byKey(_logout));
    await tester.pumpAndSettle();
    final l10n = qaL10n(const Locale('en'));
    expect(find.text(l10n.settingsSignOutConfirmTitle), findsOneWidget);
    expect(find.text(l10n.settingsSignOutConfirmBody), findsOneWidget);

    await tester.tap(find.byKey(_logoutCancel));
    await qaSettle(tester);

    expect(api.writeLines, isEmpty);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
    expect(AuthSessionStore.instance.refreshToken, 'qa-refresh');
  });

  testWidgets('an offline sign-out deletes the push token so the old device '
      'record cannot deliver this member\'s pushes '
      '[case:common.settings.logout.push_token_deleted]', (tester) async {
    final api = _server()
      ..offline('DELETE /notifications/me/devices/device-42')
      ..offline('POST /auth/logout');
    final container = await _openSettings(tester, api);

    await _signOut(tester);

    expect(
      api.sent('DELETE', '/notifications/me/devices/device-42'),
      hasLength(1),
    );
    expect(_tokenDeletes, 1);
    await _expectSignedOut(tester, container);
  });

  testWidgets('Sign out of all devices ends every session on the server, '
      'then signs out here [case:common.settings.logout_all.action]', (
    tester,
  ) async {
    final api = _server()
      ..json('POST /auth/sessions/revoke', <String, dynamic>{
        'success': true,
        'all_sessions': true,
      });
    final container = await _openSettings(tester, api);
    final l10n = qaL10n(const Locale('en'));

    await tester.tap(find.byKey(_logoutAll));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsSignOutAllConfirmTitle), findsOneWidget);
    // Nothing is sent before the member confirms.
    expect(api.writeLines, isEmpty);

    await tester.tap(find.byKey(_logoutAllConfirm));
    await qaSettle(tester);

    final revoke = api.sent('POST', '/auth/sessions/revoke').single;
    expect(revoke.body, {'all_sessions': true});
    // The revoked session can no longer call the server: no per-device
    // logout, no device DELETE; the push token is deleted instead.
    expect(api.writeLines, ['POST /auth/sessions/revoke']);
    expect(_tokenDeletes, 1);
    await _expectSignedOut(tester, container);
  });

  testWidgets(
    'when the server cannot sign out the other devices the member '
    'stays signed in and is told [case:common.settings.logout_all.api_failure]',
    (tester) async {
      final api = _server()..offline('POST /auth/sessions/revoke');
      final container = await _openSettings(tester, api);

      await tester.tap(find.byKey(_logoutAll));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_logoutAllConfirm));
      await qaSettle(tester);

      expect(api.writeLines, ['POST /auth/sessions/revoke']);
      expect(
        qaSnackText(tester),
        qaL10n(const Locale('en')).settingsSignOutAllFailed,
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
      expect(AuthSessionStore.instance.refreshToken, 'qa-refresh');
      expect(_tokenDeletes, 0);
    },
  );

  testWidgets('signing out from the Settings tab inside the real app gate '
      'shows Welcome without errors [case:common.settings.logout.app_gate]', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _server();
    for (var depth = 6; depth <= 7; depth++) {
      api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: qaOverrides(
          api,
          extra: [
            _recordingPush(),
            appThemeProvider.overrideWith(_PinnedTheme.new),
            appLocaleProvider.overrideWith(_PinnedLocale.new),
            notificationProvider.overrideWith(_QuietNotifications.new),
          ],
        ),
        child: const DatingApp(),
      ),
    );
    await qaSettle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DatingApp)),
    );
    // The member is on the Settings tab of the main navigation.
    container.read(mainNavigationIndexProvider.notifier).state = 4;
    await qaSettle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await _signOut(tester);
    await qaSettle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(api.writeLines, [
      'DELETE /notifications/me/devices/device-42',
      'POST /auth/logout',
    ]);
    expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    // The next member starts on Today.
    expect(container.read(mainNavigationIndexProvider), 0);
  });
}

/// The gate loads the account's theme and language on sign-in; this suite is
/// about signing out, so neither is fetched.
class _PinnedTheme extends AppThemeNotifier {
  _PinnedTheme(super.ref);

  @override
  Future<void> ensureLoaded() async {}
}

class _PinnedLocale extends AppLocaleNotifier {
  _PinnedLocale(super.ref);

  @override
  Future<void> ensureLoaded() async {}
}

/// No inbox fetch or real-time socket (its connect timer would outlive the
/// test).
class _QuietNotifications extends NotificationNotifier {
  _QuietNotifications(super.ref);

  @override
  Future<void> bootstrap() async {}
}
