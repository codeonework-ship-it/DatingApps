import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/payment/providers/subscription_provider.dart';

class _SignedIn extends AuthNotifier {
  void switchMember() {
    state = const AuthState(
      isAuthenticated: true,
      userId: 'other',
      username: 'other',
    );
  }

  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'user-1',
    username: 'user_one',
  );
}

Dio _api(Map<String, Object Function(RequestOptions)> routes) {
  routes = {
    'GET /billing/account': (_) => {
      'account': {
        'user_id': 'user-1',
        'name': 'Member One',
        'email': 'member@example.test',
        'mode': 'sandbox',
        'payment_methods': ['card'],
        'pending_checkouts': <Object>[],
      },
    },
    ...routes,
  };
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final route = routes['${options.method} ${options.path}'];
        if (route == null) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
                data: {'error': 'no route ${options.method} ${options.path}'},
              ),
            ),
          );
          return;
        }
        final result = route(options);
        if (result is DioException) {
          handler.reject(result);
          return;
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: result,
          ),
        );
      },
    ),
  );
  return dio;
}

ProviderContainer _container(Dio dio) => ProviderContainer(
  overrides: [
    authNotifierProvider.overrideWith(_SignedIn.new),
    apiClientProvider.overrideWithValue(dio),
  ],
);

const _plans = {
  'plans': [
    {
      'id': 'free',
      'name': 'Free',
      'monthly_price': 0,
      'yearly_price': 0,
      'likes_per_day': 10,
      'messages_per_day': 5,
      'features': ['basic_matching'],
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

void main() {
  test(
    'an in-flight checkout cannot open after the signed-in account changes',
    () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await release.future;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'checkout': {
                    'id': 'old-account-checkout',
                    'checkout_url': 'https://pay.test',
                    'status': 'open',
                  },
                },
              ),
            );
          },
        ),
      );
      final container = _container(dio);
      addTearDown(container.dispose);
      final pending = container
          .read(subscriptionProvider.notifier)
          .startCheckout(
            plan: SubscriptionPlan.fromJson(
              (_plans['plans']! as List)[1] as Map<String, dynamic>,
            ),
            billingCycle: 'monthly',
          );
      await started.future;
      (container.read(authNotifierProvider.notifier) as _SignedIn)
          .switchMember();
      expect(container.read(subscriptionProvider).account, isNull);
      release.complete();
      expect(await pending, isNull);
      expect(container.read(subscriptionProvider).checkoutPlanId, isNull);
    },
  );

  test('only accepts the exact checkout return origin, path and session', () {
    const checkout = BillingCheckout(
      id: 'chk-1',
      status: 'open',
      checkoutUrl: 'https://checkout.stripe.com/test',
      planCode: 'gold',
      billingCycle: 'monthly',
      amountMinor: 1999,
      currency: 'INR',
      returnUrl: 'https://api.example.test/v1/billing/checkout/return',
    );
    expect(
      checkout.isReturnUrl(
        'https://api.example.test/v1/billing/checkout/return?checkout_id=chk-1&status=success',
      ),
      isTrue,
    );
    for (final url in [
      'https://evil.test/v1/billing/checkout/return?checkout_id=chk-1',
      'https://api.example.test/v1/billing/checkout/return-extra?checkout_id=chk-1',
      'https://api.example.test/v1/billing/checkout/return?checkout_id=another',
      'http://api.example.test/v1/billing/checkout/return?checkout_id=chk-1',
      'https://api.example.test/v1/billing/checkout/return?status=success',
    ]) {
      expect(checkout.isReturnUrl(url), isFalse, reason: url);
    }
  });

  test(
    'network loss leaves payment pending, never reports a failed charge',
    () async {
      final container = _container(
        _api({
          'GET /billing/checkout/chk-1': (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
          'GET /billing/plans': (_) => _plans,
          'GET /billing/subscription/user-1': (_) => {'subscription': null},
          'GET /billing/payments/user-1': (_) => {'payments': <Object>[]},
        }),
      );
      addTearDown(container.dispose);
      final outcome = await container
          .read(subscriptionProvider.notifier)
          .awaitCheckout(
            const BillingCheckout(
              id: 'chk-1',
              status: 'open',
              checkoutUrl: 'https://pay.test',
              planCode: 'gold',
              billingCycle: 'monthly',
              amountMinor: 1999,
              currency: 'INR',
            ),
          );
      expect(outcome, CheckoutOutcome.pending);
      expect(container.read(subscriptionProvider).subscription, isNull);
    },
  );

  test('rejects a billing account for a different signed-in member', () async {
    final container = _container(
      _api({
        'GET /billing/account': (_) => {
          'account': {'user_id': 'other', 'mode': 'live'},
        },
        'GET /billing/plans': (_) => _plans,
        'GET /billing/subscription/user-1': (_) => {'subscription': null},
        'GET /billing/payments/user-1': (_) => {'payments': <Object>[]},
      }),
    );
    addTearDown(container.dispose);
    await container.read(subscriptionProvider.notifier).load();
    expect(container.read(subscriptionProvider).account, isNull);
    expect(container.read(subscriptionProvider).error, isNotNull);
  });

  test(
    'recovers hosted session including return URL from account readback',
    () async {
      final container = _container(
        _api({
          'GET /billing/account': (_) => {
            'account': {
              'user_id': 'user-1',
              'mode': 'test',
              'payment_methods': ['card'],
              'pending_checkouts': [
                {
                  'id': 'chk-existing',
                  'kind': 'card_update',
                  'return_url': 'https://api.test/v1/billing/checkout/return',
                  'checkout_url': 'https://pay.test/existing',
                  'status': 'open',
                },
              ],
            },
          },
          'GET /billing/plans': (_) => _plans,
          'GET /billing/subscription/user-1': (_) => {'subscription': null},
          'GET /billing/payments/user-1': (_) => {'payments': <Object>[]},
        }),
      );
      addTearDown(container.dispose);
      await container.read(subscriptionProvider.notifier).load();
      final account = container.read(subscriptionProvider).account!;
      expect(account.isTest, isTrue);
      expect(account.cardAvailable, isTrue);
      expect(account.pendingCheckouts.single.kind, 'card_update');
      expect(
        account.pendingCheckouts.single.returnUrl,
        'https://api.test/v1/billing/checkout/return',
      );
    },
  );

  test('parses the provider-driven subscription contract', () {
    final sub = UserSubscription.fromJson({
      'id': 's1',
      'user_id': 'user-1',
      'plan_id': 'gold',
      'plan_name': 'Gold',
      'status': 'past_due',
      'billing_cycle': 'yearly',
      'start_date': '2026-09-01T00:00:00Z',
      'current_period_end': '2027-09-01T00:00:00Z',
      'provider': 'stripe',
      'is_paid': true,
      'entitled': true,
      'auto_renew': false,
      'cancel_at_period_end': true,
      'amount_minor': 19999,
      'currency': 'INR',
      'card_brand': 'visa',
      'card_last4': '4242',
    });
    expect(sub.isPaid, isTrue);
    expect(sub.isPastDue, isTrue);
    expect(sub.isLive, isTrue);
    expect(sub.autoRenew, isFalse);
    expect(sub.cancelAtPeriodEnd, isTrue);
    expect(sub.amount, 199.99);
    expect(sub.hasCard, isTrue);
    expect(sub.currentPeriodEnd?.year, 2027);

    final payment = BillingPayment.fromJson({
      'id': 'p1',
      'amount': 19.99,
      'currency': 'INR',
      'status': 'partially_refunded',
      'payment_method': 'card',
      'created_at': '2026-09-01T00:00:00Z',
      'billing_reason': 'subscription_cycle',
      'refunded_amount': 5,
      'card_last4': '4242',
    });
    expect(payment.refunded, isTrue);
    expect(payment.succeeded, isFalse);
    expect(payment.refundedAmount, 5);
  });

  test(
    'free tier is reported as not paid and plans hide the free plan price',
    () async {
      final container = _container(
        _api({
          'GET /billing/plans': (_) => _plans,
          'GET /billing/subscription/user-1': (_) => {
            'subscription': {
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
          },
          'GET /billing/payments/user-1': (_) => {'payments': <Object>[]},
        }),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionProvider.notifier).load();
      final state = container.read(subscriptionProvider);
      expect(state.error, isNull);
      expect(state.subscription?.isPaid, isFalse);
      expect(state.plans.where((p) => p.isFree), hasLength(1));
      expect(
        state.plans.firstWhere((p) => p.id == 'gold').priceFor('yearly'),
        199.99,
      );
    },
  );

  test(
    'a 409 from checkout surfaces the backend message and clears the busy plan',
    () async {
      final container = _container(
        _api({
          'POST /billing/checkout': (options) => DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 409,
              data: {
                'error': 'a paid subscription is already live for this member',
                'error_code': 'CONFLICT',
              },
            ),
          ),
        }),
      );
      addTearDown(container.dispose);

      final notifier = container.read(subscriptionProvider.notifier);
      final checkout = await notifier.startCheckout(
        plan: SubscriptionPlan.fromJson(
          (_plans['plans']! as List)[1] as Map<String, dynamic>,
        ),
        billingCycle: 'monthly',
      );
      expect(checkout, isNull);
      final state = container.read(subscriptionProvider);
      expect(state.checkoutPlanId, isNull);
      expect(state.error, contains('already live'));
    },
  );

  test('awaitCheckout reports failure when the checkout expires', () async {
    final container = _container(
      _api({
        'GET /billing/checkout/chk-1': (_) => {
          'checkout': {'id': 'chk-1', 'status': 'expired'},
        },
        'GET /billing/plans': (_) => _plans,
        'GET /billing/subscription/user-1': (_) => {'subscription': null},
        'GET /billing/payments/user-1': (_) => {'payments': <Object>[]},
      }),
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(subscriptionProvider.notifier)
        .awaitCheckout(
          const BillingCheckout(
            id: 'chk-1',
            status: 'open',
            checkoutUrl: 'https://pay.test/c/1',
            planCode: 'gold',
            billingCycle: 'monthly',
            amountMinor: 1999,
            currency: 'INR',
          ),
          interval: Duration.zero,
        );
    expect(outcome, CheckoutOutcome.failed);
  });
}
