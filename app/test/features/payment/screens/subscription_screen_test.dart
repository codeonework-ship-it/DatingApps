import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'user-1',
    username: 'user_one',
  );
}

Dio _api({
  required Map<String, dynamic> subscription,
  List<Object> payments = const [],
  String paymentMode = 'sandbox',
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        Object data;
        switch ('${options.method} ${options.path}') {
          case 'GET /billing/account':
            data = {
              'account': {
                'user_id': 'user-1',
                'name': 'Member One',
                'email': 'member@example.test',
                'mode': paymentMode,
                'payment_methods': paymentMode == 'disabled'
                    ? <String>[]
                    : ['card'],
                'pending_checkouts': <Object>[],
              },
            };
          case 'GET /billing/plans':
            data = {
              'plans': [
                {
                  'id': 'free',
                  'name': 'Free',
                  'monthly_price': 0,
                  'yearly_price': 0,
                  'likes_per_day': 10,
                  'messages_per_day': 5,
                  'features': <String>[],
                  'is_active': true,
                },
                {
                  'id': 'silver',
                  'name': 'Silver',
                  'monthly_price': 9.99,
                  'yearly_price': 99.99,
                  'likes_per_day': 50,
                  'messages_per_day': 30,
                  'features': ['profile_boost'],
                  'is_active': true,
                },
                {
                  'id': 'gold',
                  'name': 'Gold',
                  'monthly_price': 19.99,
                  'yearly_price': 199.99,
                  'likes_per_day': -1,
                  'messages_per_day': -1,
                  'features': ['spotlight', 'unlimited_likes'],
                  'is_active': true,
                },
              ],
            };
          case 'GET /billing/subscription/user-1':
            data = {'subscription': subscription};
          case 'GET /billing/payments/user-1':
            data = {'payments': payments};
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
        home: const SubscriptionScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('free member sees the catalog with card subscribe buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _api(
        subscription: {
          'id': 'sub-free-user-1',
          'user_id': 'user-1',
          'plan_id': 'free',
          'plan_name': 'Free',
          'status': 'active',
          'billing_cycle': 'monthly',
          'start_date': '2026-09-01T00:00:00Z',
          'is_paid': false,
          'entitled': true,
        },
      ),
    );

    expect(find.text('Membership'), findsOneWidget);
    expect(find.text('Choose your plan'), findsOneWidget);
    // Free plan is not sold; the two paid plans are.
    expect(find.text('Subscribe with card'), findsNWidgets(2));
    expect(find.text('₹9.99'), findsOneWidget);
    expect(find.text('MOST POPULAR'), findsOneWidget);
    expect(find.text('Auto-renew'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Yearly'));
    await tester.pump();
    expect(find.text('₹199.99'), findsOneWidget);
    expect(find.textContaining('Save '), findsWidgets);
  });

  testWidgets('paid member sees card, renewal date and the auto-renew switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _api(
        subscription: {
          'id': 's1',
          'user_id': 'user-1',
          'plan_id': 'gold',
          'plan_name': 'Gold',
          'status': 'active',
          'billing_cycle': 'monthly',
          'start_date': '2026-09-01T00:00:00Z',
          'current_period_end': '2026-10-01T00:00:00Z',
          'provider': 'stripe',
          'is_paid': true,
          'entitled': true,
          'auto_renew': true,
          'amount_minor': 1999,
          'currency': 'INR',
          'card_brand': 'visa',
          'card_last4': '4242',
        },
        payments: [
          {
            'id': 'p1',
            'amount': 19.99,
            'currency': 'INR',
            'status': 'success',
            'payment_method': 'card',
            'billing_reason': 'subscription_create',
            'card_brand': 'visa',
            'card_last4': '4242',
            'created_at': '2026-09-01T00:00:00Z',
          },
          {
            'id': 'p2',
            'amount': 19.99,
            'currency': 'INR',
            'status': 'failed',
            'payment_method': 'card',
            'billing_reason': 'subscription_cycle',
            'failure_reason': 'Your card was declined.',
            'created_at': '2026-10-01T00:00:00Z',
          },
        ],
      ),
    );

    expect(find.text('Auto-renew'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.textContaining('Renews on'), findsOneWidget);
    expect(find.text('Your current plan'), findsOneWidget);
    // Another paid plan is a switch, not a second purchase.
    expect(find.text('Subscribe with card'), findsNothing);
    expect(find.text('Switch to Silver'), findsOneWidget);
    expect(find.text('Update card'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.textContaining('declined'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
