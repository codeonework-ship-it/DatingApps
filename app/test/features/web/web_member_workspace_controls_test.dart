// WebMemberWorkspace controls: sidebar items, the phone header's Back and
// All features buttons, feature-directory cards, "Back to Discover" from a
// switched-off destination, Sign out (device unregistered, server session
// revoked, local session wiped — even when the server cannot be reached) and
// the shell's language.
//
// Outside a browser `browser_context.dart` is its stub: `setWebRoute` and
// `openWebsiteHome` do nothing and `webRouteChanges` never fires, so every
// page here is reached by tapping, through the shell's own routing.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/common/screens/notification_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

const _desktop = Size(1440, 900);
const _phone = Size(390, 844);
const _allOn = RuntimeFeatureFlags({});
const _billingOff = RuntimeFeatureFlags({'billing_enabled': false});
const _deviceKey = 'push.me.fcm.device_id';
const _tokenKey = 'push.me.fcm.token';

class _Harness {
  _Harness(this.api, this.flags);
  final QaApi api;
  final StreamController<RuntimeFeatureFlags> flags;
  late ProviderContainer container;
}

Finder _sidebar() => find.byKey(const ValueKey<String>('qa.web.sidebar'));
Finder _inSidebar(String text) =>
    find.descendant(of: _sidebar(), matching: find.text(text));
Finder _card(String label) => find.widgetWithText(ListTile, label);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

Future<_Harness> _mount(
  WidgetTester tester, {
  Size size = _desktop,
  QaApi? api,
  RuntimeFeatureFlags initialFlags = _allOn,
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final flags = StreamController<RuntimeFeatureFlags>()..add(initialFlags);
  addTearDown(flags.close);
  final h = _Harness(api ?? QaApi(), flags);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qaAuth(),
        apiClientProvider.overrideWithValue(h.api.dio),
        idleNotificationsOverride(),
        runtimeFeatureFlagsProvider.overrideWith((ref) => flags.stream),
        // The real push service on the fake BFF; Firebase token deletion is
        // a no-op.
        pushNotificationServiceProvider.overrideWith(
          (ref) => PushNotificationService(
            ref.read(apiClientProvider),
            deleteDeviceToken: () async {},
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WebMemberWorkspace(),
      ),
    ),
  );
  await _settle(tester);
  h.container = ProviderScope.containerOf(
    tester.element(find.byType(WebMemberWorkspace)),
  );
  return h;
}

bool _selected(WidgetTester tester, String label) {
  final semantics = find.ancestor(
    of: _inSidebar(label),
    matching: find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.button == true,
    ),
  );
  return tester.widget<Semantics>(semantics.first).properties.selected ?? false;
}

void main() {
  testWidgets('sidebar items open their page and mark it selected '
      '[case:web.web_member_workspace.sidebaritem_ontap.action]', (
    tester,
  ) async {
    final h = await _mount(tester);
    expect(_selected(tester, 'Discover'), isTrue);

    await _tap(tester, _inSidebar('Privacy & safety'));
    expect(find.byType(PrivacySafetyScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(_selected(tester, 'Privacy & safety'), isTrue);
    expect(_selected(tester, 'Discover'), isFalse);

    await _tap(tester, _inSidebar('Membership'));
    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(find.byType(PrivacySafetyScreen), findsNothing);
    expect(_selected(tester, 'Membership'), isTrue);

    await _tap(tester, _inSidebar('Matches'));
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(h.container.read(mainNavigationIndexProvider), 1);
    expect(_selected(tester, 'Matches'), isTrue);

    await _tap(tester, _inSidebar('Settings'));
    expect(h.container.read(mainNavigationIndexProvider), 4);
    expect(_selected(tester, 'Settings'), isTrue);
  });

  testWidgets(
    'a directory card opens its destination '
    '[case:web.web_member_workspace.north_east_rounded_icon_north_ea_onopen.action]',
    (tester) async {
      await _mount(tester);
      await _tap(tester, _inSidebar('All features'));
      expect(find.text('Make this space yours.'), findsOneWidget);
      final card = _card('Notification preferences');
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.north_east_rounded),
        ),
        findsOneWidget,
      );

      await _tap(tester, card);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Make this space yours.'), findsNothing);
      // Breadcrumb names the page that opened.
      expect(find.text('Notification preferences'), findsWidgets);
    },
  );

  testWidgets('the phone header\'s All features opens the directory '
      '[case:web.web_member_workspace.all_features.action]', (tester) async {
    await _mount(tester);
    await _tap(tester, _inSidebar('Help & support'));
    tester.view.physicalSize = _phone;
    await _settle(tester);
    expect(find.byType(HelpSupportScreen), findsOneWidget);

    await _tap(tester, find.byTooltip('All features'));
    expect(find.byType(HelpSupportScreen), findsNothing);
    expect(find.text('Make this space yours.'), findsOneWidget);
    expect(_card('Help & support'), findsOneWidget);
    // The header now titles the directory.
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('the phone header\'s Back returns to the previous page '
      '[case:web.web_member_workspace.backbutton_onpressed.action]', (
    tester,
  ) async {
    final h = await _mount(tester);
    await _tap(tester, _inSidebar('Privacy & safety'));
    await _tap(tester, _inSidebar('Help & support'));
    tester.view.physicalSize = _phone;
    await _settle(tester);

    await _tap(tester, find.byType(BackButton));
    expect(find.byType(HelpSupportScreen), findsNothing);
    expect(find.byType(PrivacySafetyScreen), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(find.byType(PrivacySafetyScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(h.container.read(mainNavigationIndexProvider), 0);
    // Discover carries its own navigation: no shell Back any more.
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Back to Discover leaves a destination that was switched off '
      '[case:web.web_member_workspace.back_to_discover_onback.action]', (
    tester,
  ) async {
    final h = await _mount(tester);
    await _tap(tester, _inSidebar('Help & support'));
    await _tap(tester, _inSidebar('Membership'));
    expect(find.byType(SubscriptionScreen), findsOneWidget);

    h.flags.add(_billingOff);
    await _settle(tester);
    expect(find.text("Membership isn't available yet."), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Back to Discover'));
    expect(find.text("Membership isn't available yet."), findsNothing);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(h.container.read(mainNavigationIndexProvider), 0);
    expect(_selected(tester, 'Discover'), isTrue);
  });

  group('Sign out', () {
    setUp(() {
      // Push is configured and this device registered as device-42.
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

    Future<void> expectSignedOut(_Harness h) async {
      final auth = h.container.read(authNotifierProvider);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.userId, isNull);
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(AuthSessionStore.instance.refreshToken, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_deviceKey), isNull);
    }

    testWidgets('unregisters this device, revokes the session and signs out '
        '[case:web.web_member_workspace.sign_out.action]', (tester) async {
      final api = QaApi()
        ..json('DELETE /notifications/me/devices/device-42', {})
        ..json('POST /auth/logout', {'success': true});
      final h = await _mount(tester, api: api);
      expect(h.container.read(authNotifierProvider).isAuthenticated, isTrue);

      await _tap(tester, _inSidebar('Sign out'));
      await qaSettle(tester);

      final lines = api.writeLines;
      expect(
        lines.where((l) => l.contains('/auth/') || l.contains('/devices/')),
        ['DELETE /notifications/me/devices/device-42', 'POST /auth/logout'],
      );
      await expectSignedOut(h);
      expect(tester.takeException(), isNull);
    });

    for (final failure in ['offline', 'server error']) {
      testWidgets(
        'still signs out on this device when the server fails ($failure) '
        '[case:web.web_member_workspace.sign_out.api_failure]',
        (tester) async {
          final api = QaApi();
          if (failure == 'offline') {
            api
              ..offline('DELETE /notifications/me/devices/device-42')
              ..offline('POST /auth/logout');
          } else {
            api
              ..fail('DELETE /notifications/me/devices/device-42', status: 503)
              ..fail('POST /auth/logout', message: 'Session store down.');
          }
          final h = await _mount(tester, api: api);

          await _tap(tester, _inSidebar('Sign out'));
          await qaSettle(tester);

          // Each request is tried exactly once; signing out never depends on
          // the network, so the local session is gone regardless.
          expect(api.sent('POST', '/auth/logout'), hasLength(1));
          expect(
            api.sent('DELETE', '/notifications/me/devices/device-42'),
            hasLength(1),
          );
          await expectSignedOut(h);
          expect(tester.takeException(), isNull);
          // Nothing claims the member is still signed in.
          expect(find.text('Session store down.'), findsNothing);
        },
      );
    }
  });

  for (final locale in const [Locale('de'), Locale('fr'), Locale('pl')]) {
    testWidgets(
      'sidebar, breadcrumb, directory and phone header follow the language '
      '(${locale.languageCode}) [case:web.web_member_workspace.l10n]',
      (tester) async {
        final l = qaL10n(locale);
        await _mount(tester, locale: locale);

        // Every sidebar entry has its own name: Discover and Explore used to
        // share one word in German and Polish.
        final primary = [
          l.navDiscover,
          l.navMatches,
          l.webNavExplore,
          l.webNavMyProfile,
          l.navSettings,
        ];
        expect(primary.toSet(), hasLength(primary.length));
        for (final label in [
          l.navDiscover,
          l.navMatches,
          l.webNavExplore,
          l.webNavMyProfile,
          l.navSettings,
          l.webNavAllFeatures,
          l.webNavPreferences,
          l.webDestPrivacySafety,
          l.webDestHelpSupport,
          l.webNavWebsite,
          l.webNavSignOut,
          l.webNavMoreForYou.toUpperCase(),
        ]) {
          expect(_inSidebar(label), findsOneWidget, reason: label);
        }
        expect(find.text(l.webTagline), findsOneWidget);
        for (final english in [
          'All features',
          'Preferences',
          'Privacy & safety',
          'Help & support',
          'Connect website',
          'Sign out',
          'MORE FOR YOU',
        ]) {
          expect(_inSidebar(english), findsNothing, reason: english);
        }
        expect(find.text('Your pace. Your choice.'), findsNothing);

        await _tap(tester, _inSidebar(l.webNavAllFeatures));
        expect(find.text(l.webDirectoryTitle), findsOneWidget);
        expect(find.text(l.webDirectorySubtitle), findsOneWidget);
        expect(_card(l.webDestCallHistory), findsOneWidget);
        expect(find.text('Make this space yours.'), findsNothing);
        expect(_card('Call history'), findsNothing);

        tester.view.physicalSize = _phone;
        await _settle(tester);
        expect(find.byTooltip(l.webNavAllFeatures), findsOneWidget);
        expect(find.byTooltip('All features'), findsNothing);
      },
    );
  }
}
