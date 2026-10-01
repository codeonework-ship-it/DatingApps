import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/telemetry/client_error_reporter.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'qa-user');
}

Dio _api() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'settings': <String, dynamic>{
              'show_age': true,
              'show_exact_distance': false,
              'show_online_status': true,
            },
          },
        ),
      ),
    ),
  );
  return dio;
}

void main() {
  testWidgets('Share crash reports is on by default and persists toggles', (
    tester,
  ) async {
    final store = MemoryClientErrorStore();
    final reporter = ClientErrorReporter(
      store: store,
      transport: (body, {bearerToken}) async =>
          const ClientErrorTransportResponse(statusCode: 202),
      enabled: true,
      observeLifecycle: false,
    );
    addTearDown(reporter.dispose);
    await reporter.start();
    await store.write(ClientErrorReporter.queueKey, '[]');

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(_api()),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
          clientErrorReporterProvider.overrideWithValue(reporter),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacySafetyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(SwitchListTile, 'Share crash reports');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(find.textContaining('No messages, photos or account'), findsOne);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(store.values[ClientErrorReporter.optInKey], '0');
    expect(store.values.containsKey(ClientErrorReporter.queueKey), isFalse);
    expect(reporter.isCapturing, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(store.values[ClientErrorReporter.optInKey], '1');
  });
}
