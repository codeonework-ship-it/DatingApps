import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/common/screens/notification_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'qa-user');
}

// Skip push/socket bootstrap; retain the real save/rollback implementation.
class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}

class _Api {
  bool reject = false;
  Map<String, dynamic> saved = {};
  Map<String, dynamic> settings = {
    'show_age': true,
    'show_exact_distance': false,
    'show_online_status': true,
  };
  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (reject) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 503,
                  data: {'error': 'QA service unavailable'},
                ),
              ),
            );
            return;
          }
          if (options.method == 'PATCH') {
            saved = Map<String, dynamic>.from(options.data as Map);
            if (options.path.startsWith('/settings/')) {
              settings = saved;
            }
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: options.path.startsWith('/settings/')
                  ? {'settings': settings}
                  : {'preferences': saved},
            ),
          );
        },
      ),
    );
    return dio;
  }
}

void main() {
  late _Api api;
  Future<void> mount(WidgetTester tester, Widget screen) async {
    api = _Api();
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.build()),
          notificationProvider.overrideWith(_Notifications.new),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'appearance saves light dark and system themes '
    '[case:common.settings.settings_theme_selector_selectionchanged.action]',
    (tester) async {
      await mount(tester, const SettingsScreen());
      final picker = find.byKey(const ValueKey('qa.settings.theme_selector'));
      await tester.scrollUntilVisible(
        picker,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      for (final choice in [
        AppThemeChoice.dark,
        AppThemeChoice.light,
        AppThemeChoice.auto,
      ]) {
        await tester.tap(
          find.descendant(of: picker, matching: find.text(choice.label)),
        );
        await tester.pumpAndSettle();
        expect(api.saved['theme'], choice.wireValue);
        expect(
          tester.widget<SegmentedButton<AppThemeChoice>>(picker).selected,
          {choice},
        );
      }
    },
  );
  testWidgets('appearance saves and previews the Deep Field preset '
      '[case:common.settings.settings_theme_preset_x.action]', (tester) async {
    await mount(tester, const SettingsScreen());
    final preset = find.byKey(
      const ValueKey('qa.settings.theme_preset.deepfield'),
    );
    await tester.scrollUntilVisible(
      preset,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(preset);
    await tester.pumpAndSettle();

    expect(api.saved['theme'], endsWith(':deepfield'));
    expect(find.text('Deep Field'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  });
  testWidgets(
    'appearance failed save restores previous selection and shows error '
    // ignore: lines_longer_than_80_chars
    '[case:common.settings.settings_theme_selector_selectionchanged.api_failure]',
    (tester) async {
      await mount(tester, const SettingsScreen());
      final picker = find.byKey(const ValueKey('qa.settings.theme_selector'));
      await tester.scrollUntilVisible(
        picker,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      final previous = tester
          .widget<SegmentedButton<AppThemeChoice>>(picker)
          .selected
          .single;
      final next = previous == AppThemeChoice.dark
          ? AppThemeChoice.light
          : AppThemeChoice.dark;
      api.reject = true;
      await tester.tap(
        find.descendant(of: picker, matching: find.text(next.label)),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<AppThemeChoice>>(picker).selected, {
        previous,
      });
      expect(
        find.text('Could not save your theme. Please try again.'),
        findsOneWidget,
      );
    },
  );

  final notifications = {
    'In-app notifications': 'in_app_notifications_enabled',
    'Push notifications': 'push_notifications_enabled',
    'New matches': 'notify_new_match',
    'New messages': 'notify_new_message',
    'Likes': 'notify_likes',
    'Match nudges': 'notify_match_nudges',
    'Incoming calls': 'notify_incoming_calls',
    'Safety updates': 'notify_safety',
  };
  for (final entry in notifications.entries) {
    testWidgets(
      'notification ${entry.key} saves both directions without changing peers',
      (tester) async {
        await mount(tester, const NotificationSettingsScreen());
        final finder = find.widgetWithText(SwitchListTile, entry.key);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(api.saved[entry.value], false);
        expect(
          api.saved.entries
              .where((e) => e.key != entry.value)
              .every((e) => e.value == true),
          isTrue,
        );
        expect(tester.widget<SwitchListTile>(finder).value, false);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(api.saved.values.every((e) => e == true), isTrue);
      },
    );
  }
  testWidgets('notification save failure rolls back and shows error '
      '[case:common.notification_settings.push_notifications.api_failure]', (
    tester,
  ) async {
    await mount(tester, const NotificationSettingsScreen());
    api.reject = true;
    final finder = find.widgetWithText(SwitchListTile, 'Push notifications');
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(finder).value, isTrue);
    expect(find.text('QA service unavailable'), findsOneWidget);
  });
  for (final entry in {
    'Show age': 'show_age',
    'Show exact distance': 'show_exact_distance',
    'Show online status': 'show_online_status',
  }.entries) {
    testWidgets('privacy ${entry.key} saves both directions', (tester) async {
      await mount(tester, const PrivacySafetyScreen());
      final finder = find.widgetWithText(SwitchListTile, entry.key);
      final before = tester.widget<SwitchListTile>(finder).value;
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(api.saved[entry.value], !before);
      expect(tester.widget<SwitchListTile>(finder).value, !before);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(api.saved[entry.value], before);
    });
  }
  testWidgets('privacy save failure displays retry and reloads persisted value '
      '[case:common.privacy_safety.retry.action]', (tester) async {
    await mount(tester, const PrivacySafetyScreen());
    api.reject = true;
    await tester.tap(find.widgetWithText(SwitchListTile, 'Show age'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    api.reject = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Show age'),
          )
          .value,
      isTrue,
    );
  });
}
