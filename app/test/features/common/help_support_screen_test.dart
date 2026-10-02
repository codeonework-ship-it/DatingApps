import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Answers the ticket summary with no tickets.
Dio _emptySupportApi() =>
    Dio(BaseOptions(baseUrl: 'https://support.invalid'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'tickets': <Object>[],
                'unread_total': 0,
                'open_total': 0,
              },
            ),
          ),
        ),
      );

void main() {
  Future<void> pump(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_emptySupportApi())],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HelpSupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('support centre offers contact and My tickets', (tester) async {
    await pump(tester, const Locale('en'));
    expect(find.text('How can we help?'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
    expect(find.text('My tickets'), findsOneWidget);
    expect(find.text('Follow your requests and our replies'), findsOneWidget);
  });

  testWidgets('support centre is translated', (tester) async {
    await pump(tester, const Locale('de'));
    expect(find.text('Wie können wir helfen?'), findsOneWidget);
    expect(find.text('Support kontaktieren'), findsOneWidget);
    expect(find.text('How can we help?'), findsNothing);
  });
}
