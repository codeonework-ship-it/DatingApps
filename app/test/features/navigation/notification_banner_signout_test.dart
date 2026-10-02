// Regression test for Android QA AND-08 (2026-10-02): the in-app banner for
// a member's notification ("Olu Owner invited you to ...: Open") stayed on
// screen after that member signed out. With an accessibility service on,
// action banners never time out, so it sat over the welcome and sign-in
// screens, showing the previous member's notification and covering the
// "Sign in" button.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/graduation/providers/graduation_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'member');
}

class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}

  void arrive(AppNotification item) =>
      state = state.copyWith(foregroundEvent: item);
}

class _Daily extends CuratedDailySetNotifier {
  _Daily(super.ref);
  @override
  Future<void> load() async => state = const CuratedDailySetState();
}

class _Pause extends DiscoveryPauseNotifier {
  _Pause(super.ref);
  @override
  Future<void> load() async => state = const DiscoveryPauseState(loaded: true);
}

final _signedIn = StateProvider<bool>((ref) => true);

void main() {
  testWidgets('a notification banner does not outlive the signed-in shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // As on the QA emulator (UiAutomator2) or with TalkBack: action
    // banners stay until used.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(dio),
          notificationProvider.overrideWith(_Notifications.new),
          curatedDailySetProvider.overrideWith(_Daily.new),
          discoveryPauseProvider.overrideWith(_Pause.new),
          datingRhythmProvider.overrideWith((ref) async => {}),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => ref.watch(_signedIn)
                ? const MainNavigationScreen()
                : const Scaffold(body: Center(child: Text('Welcome'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainNavigationScreen)),
    );

    (container.read(notificationProvider.notifier) as _Notifications).arrive(
      AppNotification(
        id: 'n1',
        sequence: 1,
        eventType: 'group.invitation.received',
        category: 'social',
        title: 'Olu Owner invited you to QA Group',
        body: 'Open Groups to join them, or decline.',
        payload: const {},
        isRead: false,
        createdAt: DateTime(2026, 10, 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Olu Owner invited you'), findsOneWidget);

    // Sign out: the gate swaps the shell for the welcome screen.
    container.read(_signedIn.notifier).state = false;
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.textContaining('Olu Owner invited you'), findsNothing);
    expect(find.text('Open'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
