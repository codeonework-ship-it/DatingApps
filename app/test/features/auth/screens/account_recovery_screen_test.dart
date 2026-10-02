import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

void main() {
  late List<RequestOptions> requests;
  late int recoverStatus;

  Dio fakeClient() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path == '/auth/recovery/assistance') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 202,
                data: const {
                  'accepted': true,
                  'message':
                      'If this username belongs to a Connect account, '
                      'our safety team will review the request.',
                },
              ),
            );
            return;
          }
          if (options.path == '/auth/password/recover') {
            if (recoverStatus == 200) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const {'success': true},
                ),
              );
            } else {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: recoverStatus,
                    data: const {'error': 'invalid or expired recovery code'},
                  ),
                ),
              );
            }
            return;
          }
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    return dio;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(fakeClient())],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountRecoveryScreen(initialUsername: 'Member_One'),
        ),
      ),
    );
  }

  setUp(() {
    requests = [];
    recoverStatus = 200;
  });

  testWidgets('lost code sends a help request and shows the neutral answer', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('I lost my code'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pumpAndSettle();

    expect(requests.single.path, '/auth/recovery/assistance');
    expect((requests.single.data as Map)['username'], 'member_one');
    expect(find.textContaining('our safety team will review'), findsOneWidget);
  });

  testWidgets('recovery code resets the password with a strong password', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.code')),
      'code-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.new_password')),
      'short',
    );
    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pumpAndSettle();
    expect(requests, isEmpty, reason: 'weak password is rejected locally');
    expect(find.textContaining('8–72 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.new_password')),
      'NewPassw0rd',
    );
    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pumpAndSettle();
    expect(requests.single.path, '/auth/password/recover');
    expect(
      find.textContaining('every device has been signed out'),
      findsOneWidget,
    );
  });

  testWidgets('an invalid code shows a clear error', (tester) async {
    recoverStatus = 400;
    await pump(tester);
    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.code')),
      'wrong',
    );
    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.new_password')),
      'NewPassw0rd',
    );
    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('That recovery code is not valid or has expired.'),
      findsOneWidget,
    );
  });
}
