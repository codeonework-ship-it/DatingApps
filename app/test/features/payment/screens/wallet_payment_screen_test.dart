import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/payment/providers/wallet_provider.dart';
import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'user-1',
    username: 'user_one',
  );
}

Dio _api({bool paymentsEnabled = true}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        Object data;
        switch ('${options.method} ${options.path}') {
          case 'GET /wallet/user-1/coins':
            data = {
              'wallet': {'user_id': 'user-1', 'coin_balance': 112},
            };
          case 'GET /wallet/user-1/coins/audit':
            data = {
              'audit': [
                {
                  'id': 'a1',
                  'action': 'wallet.coins.purchase',
                  'status': 'success',
                  'details': {
                    'coins': 100,
                    'amount_minor': 99,
                    'currency': 'USD',
                    'provider': 'sandbox',
                  },
                  'created_at': '2026-09-27T00:00:00Z',
                },
                {
                  'id': 'a2',
                  'action': 'gift_send_succeeded',
                  'status': 'success',
                  'details': {'coins': 5},
                  'created_at': '2026-09-27T00:00:00Z',
                },
              ],
            };
          case 'GET /billing/coin-packages':
            if (!paymentsEnabled) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 501,
                    data: {'error': 'card payments are not enabled'},
                  ),
                ),
              );
              return;
            }
            data = {
              'provider': 'sandbox',
              'mode': 'sandbox',
              'packages': [
                {
                  'id': 'p1',
                  'label': 'Starter Pack',
                  'coin_amount': 100,
                  'bonus_percent': 0,
                  'total_coins': 100,
                  'price': 0.99,
                  'amount_minor': 99,
                  'currency': 'USD',
                },
                {
                  'id': 'p2',
                  'label': 'Popular',
                  'coin_amount': 500,
                  'bonus_percent': 10,
                  'total_coins': 550,
                  'price': 3.99,
                  'amount_minor': 399,
                  'currency': 'USD',
                },
              ],
            };
          default:
            data = <String, dynamic>{};
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return dio;
}

Future<void> _pump(WidgetTester tester, Dio dio) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_SignedIn.new),
        apiClientProvider.overrideWithValue(dio),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WalletPaymentScreen(walletCoins: 42),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  test('wallet audit rows map to purchases', () {
    final purchase = WalletPurchase.fromJson({
      'id': 'a1',
      'action': 'wallet.coins.purchase',
      'details': {'coins': 100, 'amount_minor': 99, 'currency': 'USD'},
      'created_at': '2026-09-27T00:00:00Z',
    });
    expect(purchase.coins, 100);
    expect(purchase.source, 'buy');
    expect(purchase.amountMinor, 99);
  });

  testWidgets('wallet shows the settled balance, packs and history', (
    tester,
  ) async {
    await _pump(tester, _api());
    expect(find.text('Wallet & Payments'), findsOneWidget);
    expect(find.text('Glow wallet balance'), findsOneWidget);
    // Backend balance replaces the caller-supplied 42.
    expect(find.text('112 coins'), findsOneWidget);
    expect(find.text('42 coins'), findsNothing);
    expect(find.text('Popular top-ups'), findsOneWidget);
    expect(find.text('Starter Pack'), findsOneWidget);
    expect(find.text('550'), findsOneWidget);
    expect(find.text('coins · +50 bonus'), findsOneWidget);
    expect(find.text(r'$3.99'), findsOneWidget);
    expect(find.text('Wallet activity'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('+5'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet explains when card payments are disabled', (
    tester,
  ) async {
    await _pump(tester, _api(paymentsEnabled: false));
    expect(
      find.text('Card payments are not enabled on this server yet.'),
      findsOneWidget,
    );
    expect(find.text('112 coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
