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
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'member');
}

class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
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

void main() {
  for (final desktop in [false, true]) {
    testWidgets(
      '${desktop ? 'desktop sidebar' : 'phone navigation'} returns to the actual Today screen after browsing',
      (tester) async {
        tester.view.physicalSize = Size(desktop ? 1440 : 390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
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
              home: desktop
                  ? const WebMemberWorkspace()
                  : const MainNavigationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MainNavigationScreen)),
        );
        final today = find.byKey(const ValueKey('qa.today.screen'));
        expect(today, findsOneWidget);

        // Previously this replaced Today with the deck while keeping Today
        // selected. Tapping Today again then did nothing.
        await tester.ensureVisible(find.text('Explore profiles'));
        await tester.tap(find.text('Explore profiles'));
        await tester.pumpAndSettle();
        expect(container.read(mainNavigationIndexProvider), 1);
        expect(container.read(matchesViewProvider), MatchesView.discover);
        expect(find.text('Discover Matches'), findsOneWidget);
        expect(today, findsNothing);

        final navigation = desktop
            ? find.byKey(const ValueKey('qa.web.sidebar'))
            : find.byType(BottomNavigationBar);
        final todayButton = find.descendant(
          of: navigation,
          matching: find.text('Today'),
        );
        await tester.tap(todayButton);
        await tester.pumpAndSettle();
        expect(container.read(mainNavigationIndexProvider), 0);
        expect(today, findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.date')), findsOneWidget);
        expect(find.text('Discover Matches'), findsNothing);
        await tester.tap(todayButton);
        await tester.pumpAndSettle();
        expect(today, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Android back on another tab returns to Today, not out of the app',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
            home: const MainNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MainNavigationScreen)),
      );
      for (final tab in [1, 2, 3, 4]) {
        container.read(mainNavigationIndexProvider.notifier).state = tab;
        await tester.pumpAndSettle();
        // The system back button / gesture.
        final handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(handled, isTrue, reason: 'back on tab $tab left the app');
        expect(container.read(mainNavigationIndexProvider), 0);
        expect(find.byKey(const ValueKey('qa.today.screen')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
