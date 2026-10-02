import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
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

Dio _api() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final Object data = switch ('${options.method} ${options.path}') {
          'GET /billing/account' => {
            'account': {
              'user_id': 'user-1',
              'name': 'Member One',
              'email': 'member@example.test',
              'mode': 'test',
              'payment_methods': ['card'],
              'pending_checkouts': <Object>[],
            },
          },
          'GET /billing/plans' => {
            'plans': [
              {
                'id': 'silver',
                'name': 'Silver',
                'monthly_price': 9.99,
                'yearly_price': 99.99,
                'likes_per_day': 50,
                'messages_per_day': 30,
                'features': <String>[],
                'is_active': true,
              },
              {
                'id': 'gold',
                'name': 'Gold',
                'monthly_price': 19.99,
                'yearly_price': 199.99,
                'likes_per_day': -1,
                'messages_per_day': -1,
                'features': <String>[],
                'is_active': true,
              },
            ],
          },
          'GET /billing/subscription/user-1' => {
            'subscription': {
              'id': 's1',
              'user_id': 'user-1',
              'plan_id': 'gold',
              'plan_name': 'Gold',
              'status': 'active',
              'billing_cycle': 'monthly',
              'start_date': '2026-09-01T00:00:00Z',
              'current_period_end': '2026-10-15T12:00:00Z',
              'provider': 'stripe',
              'is_paid': true,
              'entitled': true,
              'auto_renew': true,
              'amount_minor': 1999,
              'currency': 'INR',
              'card_brand': 'visa',
              'card_last4': '4242',
            },
          },
          'GET /billing/payments/user-1' => {
            'payments': [
              {
                'id': 'p1',
                'amount': 19.99,
                'currency': 'INR',
                'status': 'success',
                'payment_method': 'card',
                'billing_reason': 'subscription_cycle',
                'created_at': '2026-09-15T12:00:00Z',
              },
            ],
          },
          'GET /wallet/user-1/coins' => {
            'wallet': {'coin_balance': 112},
          },
          'GET /wallet/user-1/coins/audit' => {'audit': <Object>[]},
          'GET /billing/coin-packages' => {
            'mode': 'test',
            'packages': [
              {
                'id': 'pack-1',
                'label': 'Starter Pack',
                'coin_amount': 500,
                'total_coins': 550,
                'bonus_coins': 50,
                'price': 3.99,
                'currency': 'USD',
              },
            ],
          },
          _ => <String, dynamic>{},
        };
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

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1080, 9000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_SignedIn.new),
        apiClientProvider.overrideWithValue(_api()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('membership screen renders in German', (tester) async {
    await _pump(tester, const SubscriptionScreen());

    expect(find.text('Mitgliedschaft'), findsOneWidget);
    expect(find.text('Deine Mitgliedschaft'), findsOneWidget);
    expect(find.text('Aktiv'), findsOneWidget);
    expect(find.text('Wähle deinen Plan'), findsOneWidget);
    expect(find.text('Monatlich'), findsOneWidget);
    expect(find.text('Jährlich'), findsOneWidget);
    expect(find.text('Automatische Verlängerung'), findsOneWidget);
    expect(find.text('Karte ändern'), findsOneWidget);
    expect(find.textContaining('Verlängert sich am'), findsOneWidget);
    expect(find.text('Dein aktueller Plan'), findsOneWidget);
    expect(find.text('Zu Silver wechseln'), findsOneWidget);
    expect(find.text('50 Likes/Tag'), findsOneWidget);
    expect(find.text('Unbegrenzte Likes'), findsOneWidget);
    expect(find.text('Zahlungen'), findsOneWidget);
    expect(find.text('Verlängerung'), findsOneWidget);
    expect(find.text('Bezahlt'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    // German number format: decimal comma, symbol after the amount.
    expect(find.textContaining('19,99'), findsWidgets);
    expect(find.textContaining('/Monat'), findsOneWidget);
    // Stripe test mode chip and the untranslated test card number.
    expect(find.text('Stripe-Test · keine echte Abbuchung'), findsOneWidget);
    expect(find.textContaining('4242 4242 4242 4242'), findsOneWidget);
    // No English copy leaks through.
    expect(find.text('Membership'), findsNothing);
    expect(find.text('Choose your plan'), findsNothing);
    expect(find.text('Auto-renew'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet screen renders in German with plurals', (tester) async {
    await _pump(tester, const WalletPaymentScreen(walletCoins: 1));

    expect(find.text('Wallet & Zahlungen'), findsOneWidget);
    expect(find.text('112 Münzen'), findsOneWidget);
    expect(find.text('Beliebte Aufladungen'), findsOneWidget);
    expect(find.text('Münzen · +50 Bonus'), findsOneWidget);
    expect(find.textContaining('3,99'), findsOneWidget);
    expect(find.text('Noch keine Münzkäufe.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
