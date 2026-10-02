import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../responsive/screen_matrix_harness.dart' show isLayoutError;

/// The authenticated browser shell: sidebar, breadcrumb, feature directory and
/// runtime-flag gating.
///
/// Outside a browser `browser_context.dart` resolves to its stub, where
/// `currentWebRoute()` is always `/discover`, `setWebRoute` is a no-op and
/// `webRouteChanges` never fires. So every route here is reached the way a
/// member reaches it — by tapping the sidebar, a directory card or the phone
/// header — which drives the shell's own `_go` → `_applyRoute` path.
class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'web-member',
    username: 'web_member',
  );
}

// No push or socket bootstrap in a widget test.
class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}

/// Every request fails fast, as if the member were offline: the shell must
/// still lay out and route without a backend.
Dio _offlineApi() {
  final dio = Dio(BaseOptions(baseUrl: 'https://web-shell.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
    ),
  );
  return dio;
}

/// Flags the shell reads with `fallback: true`, so an empty map is "all on".
const _allOn = RuntimeFeatureFlags({});
const _billingOff = RuntimeFeatureFlags({'billing_enabled': false});

void main() {
  const desktop = Size(1440, 900);
  const phone = Size(390, 844);

  late StreamController<RuntimeFeatureFlags> flags;
  late List<String> layoutErrors;

  Finder sidebar() => find.byKey(const ValueKey<String>('qa.web.sidebar'));
  Finder inSidebar(String text) =>
      find.descendant(of: sidebar(), matching: find.text(text));
  Finder directoryCard(String label) => find.widgetWithText(ListTile, label);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> mount(
    WidgetTester tester, {
    required Size size,
    RuntimeFeatureFlags initialFlags = _allOn,
    ThemeData? theme,
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    flags = StreamController<RuntimeFeatureFlags>()..add(initialFlags);
    addTearDown(flags.close);

    // Layout errors are collected rather than thrown so one test can report
    // every overflow it hits; anything else still fails the test as usual.
    layoutErrors = [];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (isLayoutError(details.exception)) {
        layoutErrors.add(
          '${details.exceptionAsString()} '
          '[${details.context?.toDescription() ?? ''}]',
        );
      } else {
        previousOnError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(_offlineApi()),
          notificationProvider.overrideWith(_Notifications.new),
          runtimeFeatureFlagsProvider.overrideWith((ref) => flags.stream),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WebMemberWorkspace(),
        ),
      ),
    );
    await settle(tester);
  }

  void expectCleanLayout(WidgetTester tester) {
    expect(layoutErrors, isEmpty, reason: layoutErrors.join('\n'));
    expect(tester.takeException(), isNull);
  }

  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  };

  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    testWidgets('desktop sidebar renders every destination [$themeLabel]', (
      tester,
    ) async {
      await mount(tester, size: desktop, theme: theme);

      expect(sidebar(), findsOneWidget);
      for (final label in [
        'Discover',
        'Matches',
        'Explore',
        'My profile',
        'Settings',
        'MORE FOR YOU',
        'All features',
        'Preferences',
        'Notifications',
        'Membership',
        'Privacy & safety',
        'Help & support',
        'Connect website',
        'Sign out',
      ]) {
        expect(inSidebar(label), findsOneWidget, reason: label);
      }
      // Signed-in members land on Discover.
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('Your pace. Your choice.'), findsOneWidget);
      expectCleanLayout(tester);
    });
  }

  testWidgets('sidebar items route and update the breadcrumb', (tester) async {
    await mount(tester, size: desktop);

    await tapAndSettle(tester, inSidebar('Help & support'));
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    // Breadcrumb: "Connect > Help & support".
    expect(find.text('Help & support'), findsNWidgets(2));

    await tapAndSettle(tester, inSidebar('Explore'));
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WebMemberWorkspace)),
    );
    expect(container.read(mainNavigationIndexProvider), 2);
    expectCleanLayout(tester);
  });

  testWidgets('billing off hides Membership from the sidebar', (tester) async {
    await mount(tester, size: desktop, initialFlags: _billingOff);

    expect(inSidebar('Membership'), findsNothing);
    // Everything that is not flag-gated is still there.
    expect(inSidebar('Privacy & safety'), findsOneWidget);
    expect(inSidebar('Help & support'), findsOneWidget);
    expectCleanLayout(tester);
  });

  testWidgets('feature directory lists only destinations whose flag is on', (
    tester,
  ) async {
    const someOff = RuntimeFeatureFlags({
      'billing_enabled': false,
      'calls_enabled': false,
      'rooms_enabled': false,
      'identity_verification_enabled': false,
    });
    await mount(tester, size: desktop, initialFlags: someOff);

    await tapAndSettle(tester, inSidebar('All features'));
    expect(find.text('Make this space yours.'), findsOneWidget);

    for (final hidden in [
      'Membership',
      'Call history',
      'Conversation rooms',
      'Verification',
    ]) {
      expect(directoryCard(hidden), findsNothing, reason: hidden);
    }
    final visible = webDestinations.where((d) => d.availableWith(someOff));
    expect(visible.length, webDestinations.length - 4);
    for (final destination in visible) {
      expect(
        directoryCard(destination.label),
        findsOneWidget,
        reason: destination.label,
      );
    }
    expect(find.byType(ListTile), findsNWidgets(visible.length));

    // A card opens its destination.
    await tapAndSettle(tester, directoryCard('Help & support'));
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expectCleanLayout(tester);
  });

  testWidgets('a destination switched off while open is replaced, not shown', (
    tester,
  ) async {
    await mount(tester, size: desktop);

    await tapAndSettle(tester, inSidebar('Membership'));
    expect(find.byType(SubscriptionScreen), findsOneWidget);

    // The operator turns billing off; the next flag poll reaches the shell.
    flags.add(_billingOff);
    await settle(tester);

    expect(find.byType(SubscriptionScreen), findsNothing);
    expect(find.text("Membership isn't available yet."), findsOneWidget);
    expect(find.text("It isn't part of this release of Connect."), findsOne);
    expect(inSidebar('Membership'), findsNothing);

    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Back to Discover'),
    );
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text("Membership isn't available yet."), findsNothing);
    expectCleanLayout(tester);
  });

  // The Discover landing page is covered by screen_accessibility_test.dart;
  // the shell's own pages are only reachable by navigating, so check them here.
  for (final entry in {'desktop': desktop, 'phone': phone}.entries) {
    testWidgets('shell pages meet accessibility guidelines on ${entry.key}', (
      tester,
    ) async {
      // Disposed in the body: the framework checks for live handles before
      // tear-downs run.
      final semantics = tester.ensureSemantics();
      await mount(tester, size: desktop);
      await tapAndSettle(tester, inSidebar('Membership'));
      flags.add(_billingOff);
      await settle(tester);
      tester.view.physicalSize = entry.value;
      await settle(tester);
      expect(find.text("Membership isn't available yet."), findsOneWidget);

      Future<void> meetsAll() async {
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }

      await meetsAll();

      // The feature directory: from the sidebar on desktop, the header's
      // grid button on a phone.
      await tapAndSettle(
        tester,
        entry.value == desktop
            ? inSidebar('All features')
            : find.byTooltip('All features'),
      );
      expect(find.text('Make this space yours.'), findsOneWidget);
      await meetsAll();
      expectCleanLayout(tester);
      semantics.dispose();
    });
  }

  testWidgets('phone width drops the sidebar and shows Discover', (
    tester,
  ) async {
    await mount(tester, size: phone);

    expect(sidebar(), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    // Primary destinations carry their own navigation; no shell header.
    expect(find.byType(BackButton), findsNothing);
    expectCleanLayout(tester);
  });

  testWidgets('narrowing the window swaps the sidebar for a phone header', (
    tester,
  ) async {
    await mount(tester, size: desktop, initialFlags: _billingOff);
    await tapAndSettle(tester, inSidebar('All features'));

    tester.view.physicalSize = phone;
    await settle(tester);

    expect(sidebar(), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byTooltip('All features'), findsOneWidget);
    expect(directoryCard('Membership'), findsNothing);
    expect(directoryCard('Dating preferences'), findsOneWidget);
    // Directory copy must sit on a Material, or it renders in the framework's
    // red "missing Material" fallback style.
    final blurb = find.textContaining('Your profile, conversations');
    expect(Material.maybeOf(tester.element(blurb)), isNotNull);
    expectCleanLayout(tester);

    // Back from a secondary page returns to the page the member came from
    // (Discover here), not always to Explore.
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WebMemberWorkspace)),
    );
    expect(container.read(mainNavigationIndexProvider), 0);
    expectCleanLayout(tester);
  });

  // WEB-09: All features → a destination → Back used to land on Explore.
  testWidgets('phone Back walks back through the pages the member visited', (
    tester,
  ) async {
    await mount(tester, size: desktop);
    await tapAndSettle(tester, inSidebar('All features'));
    await tapAndSettle(tester, directoryCard('Help & support'));
    expect(find.byType(HelpSupportScreen), findsOneWidget);

    tester.view.physicalSize = phone;
    await settle(tester);

    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.byType(HelpSupportScreen), findsNothing);
    expect(find.text('Make this space yours.'), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);

    // A second Back keeps going back (to Discover) rather than bouncing
    // between the directory and Help & support.
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WebMemberWorkspace)),
    );
    expect(container.read(mainNavigationIndexProvider), 0);
    expectCleanLayout(tester);
  });

  testWidgets('sidebar and directory follow the member\'s language (German)', (
    tester,
  ) async {
    await mount(tester, size: desktop, locale: const Locale('de'));
    expect(inSidebar('Alle Funktionen'), findsOneWidget);
    expect(inSidebar('Privatsphäre & Sicherheit'), findsOneWidget);
    expect(inSidebar('Abmelden'), findsOneWidget);
    expect(find.text('Dein Tempo. Deine Wahl.'), findsOneWidget);
    expect(inSidebar('All features'), findsNothing);

    await tapAndSettle(tester, inSidebar('Alle Funktionen'));
    expect(find.text('Mach diesen Ort zu deinem.'), findsOneWidget);
    expect(directoryCard('Anrufverlauf'), findsOneWidget);
    expectCleanLayout(tester);
  });
}
