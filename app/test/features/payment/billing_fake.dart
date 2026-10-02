// A stateful fake of the BFF billing routes used by the membership and
// wallet control tests. It records every request (through QaApi) and moves
// the member's subscription/wallet the way the backend would once the
// sandbox provider settles a checkout. No real card, key or provider page is
// involved: card entry on the hosted page stays a manual/emulator check.

import '../../support/qa_api.dart';

const kReturnUrl = 'http://bff.test/v1/billing/checkout/return';

/// The provider redirect for [checkoutId] with [status] (`success`/`cancel`).
String returnRedirect(String checkoutId, String status) =>
    '$kReturnUrl?checkout_id=$checkoutId&status=$status';

Map<String, dynamic> freeSubscription() => {
  'id': 'sub-free-me',
  'user_id': 'me',
  'plan_id': 'free',
  'plan_name': 'Free',
  'status': 'active',
  'billing_cycle': 'monthly',
  'start_date': '2026-09-01T00:00:00Z',
  'is_paid': false,
  'entitled': true,
};

Map<String, dynamic> paidSubscription({
  String planId = 'gold',
  String planName = 'Gold',
  String provider = 'sandbox',
  bool autoRenew = true,
  String status = 'active',
  int amountMinor = 1999,
  String billingCycle = 'monthly',
}) => {
  'id': 'sub-$planId-me',
  'user_id': 'me',
  'plan_id': planId,
  'plan_name': planName,
  'status': status,
  'billing_cycle': billingCycle,
  'start_date': '2026-09-01T00:00:00Z',
  'current_period_end': '2026-11-01T00:00:00Z',
  'provider': provider,
  'is_paid': true,
  'entitled': true,
  'auto_renew': autoRenew,
  'cancel_at_period_end': !autoRenew,
  'amount_minor': amountMinor,
  'currency': 'INR',
  'card_brand': 'visa',
  'card_last4': '4242',
};

const _plans = [
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
    'features': ['spotlight'],
    'is_active': true,
  },
];

Map<String, dynamic> checkoutJson(
  String id, {
  String status = 'open',
  String planCode = 'silver',
  String kind = 'subscription',
  String billingCycle = 'monthly',
}) => {
  'id': id,
  'status': status,
  'checkout_url': 'http://bff.test/v1/billing/sandbox/checkout/$id',
  'plan_code': planCode,
  'billing_cycle': billingCycle,
  'amount_minor': 999,
  'currency': 'INR',
  'kind': kind,
  'return_url': kReturnUrl,
};

class BillingServer {
  BillingServer({Map<String, dynamic>? subscription, this.mode = 'sandbox'})
    : subscription = subscription ?? freeSubscription() {
    _install();
  }

  final api = QaApi();
  String mode;
  Map<String, dynamic> subscription;
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> pendingCheckouts = [];

  /// What `GET /billing/checkout/{id}` reports for any checkout.
  String checkoutStatus = 'completed';

  /// The subscription the provider settles a completed checkout into.
  Map<String, dynamic>? subscriptionAfterCheckout;

  // Wallet.
  int coinBalance = 112;
  List<Map<String, dynamic>> walletAudit = [];
  int creditOnCompletion = 0;
  bool _credited = false;

  int _checkouts = 0;

  /// Bodies of `POST /billing/checkout` in order.
  List<Map<String, dynamic>> get checkoutRequests =>
      api.sent('POST', '/billing/checkout').map((c) => c.body).toList();

  void _install() {
    api
      ..on('GET /billing/plans', (_) => qaOk({'plans': _plans}))
      ..on(
        'GET /billing/subscription/me',
        (_) => qaOk({'subscription': subscription}),
      )
      ..on('GET /billing/payments/me', (_) => qaOk({'payments': payments}))
      ..on(
        'GET /billing/account',
        (_) => qaOk({
          'account': {
            'user_id': 'me',
            'name': 'Member One',
            'email': 'member@example.test',
            'mode': mode,
            'payment_methods': mode == 'disabled' ? <String>[] : ['card'],
            'pending_checkouts': pendingCheckouts,
          },
        }),
      )
      ..on('POST /billing/checkout', (call) {
        _checkouts++;
        final id = 'co-$_checkouts';
        final body = call.body;
        return qaOk({
          'checkout': checkoutJson(
            id,
            planCode: body['plan_id']?.toString() ?? '',
            kind: body['kind']?.toString() ?? 'subscription',
            billingCycle: body['billing_cycle']?.toString() ?? 'monthly',
          ),
          'return_url': kReturnUrl,
        });
      })
      ..on('GET /billing/checkout/*', (call) {
        final id = call.path.split('/').last;
        final completed = checkoutStatus == 'completed';
        if (completed && subscriptionAfterCheckout != null) {
          subscription = subscriptionAfterCheckout!;
        }
        if (completed && creditOnCompletion > 0 && !_credited) {
          _credited = true;
          coinBalance += creditOnCompletion;
          walletAudit = [
            {
              'id': 'audit-$id',
              'action': 'wallet.coins.purchase',
              'status': 'success',
              'details': {
                'coins': creditOnCompletion,
                'amount_minor': 99,
                'currency': 'USD',
                'provider': 'sandbox',
              },
              'created_at': '2026-10-02T10:00:00Z',
            },
            ...walletAudit,
          ];
        }
        pendingCheckouts = pendingCheckouts
            .where((c) => c['id'] != id || !completed)
            .toList();
        return qaOk({
          'checkout': checkoutJson(id, status: checkoutStatus),
          if (completed) 'subscription': subscription,
          if (completed)
            'wallet': {'user_id': 'me', 'coin_balance': coinBalance},
        });
      })
      ..on('POST /billing/subscription/me/cancel', (_) {
        subscription = {
          ...subscription,
          'auto_renew': false,
          'cancel_at_period_end': true,
        };
        return qaOk({'subscription': subscription});
      })
      ..on('POST /billing/subscription/me/resume', (_) {
        subscription = {
          ...subscription,
          'auto_renew': true,
          'cancel_at_period_end': false,
        };
        return qaOk({'subscription': subscription});
      })
      ..on('POST /billing/subscription/me/change-plan', (call) {
        final planId = call.body['plan_id'].toString();
        final plan = _plans.firstWhere((p) => p['id'] == planId);
        subscription = {
          ...subscription,
          'plan_id': planId,
          'plan_name': plan['name'],
          'billing_cycle': call.body['billing_cycle'],
          'amount_minor': ((plan['monthly_price']! as num) * 100).round(),
        };
        return qaOk({'subscription': subscription});
      })
      ..on('POST /billing/sandbox/subscriptions/me/simulate', (call) {
        payments = [
          {
            'id': 'pay-${payments.length + 1}',
            'amount': 19.99,
            'currency': 'INR',
            'status': 'success',
            'payment_method': 'card',
            'billing_reason': 'subscription_cycle',
            'card_brand': 'visa',
            'card_last4': '4242',
            'created_at': '2026-10-02T00:00:00Z',
          },
          ...payments,
        ];
        return qaOk({'subscription': subscription, 'payments': payments});
      })
      // Wallet.
      ..on(
        'GET /wallet/me/coins',
        (_) => qaOk({
          'wallet': {'user_id': 'me', 'coin_balance': coinBalance},
        }),
      )
      ..on('GET /wallet/me/coins/audit', (_) => qaOk({'audit': walletAudit}))
      ..on(
        'GET /billing/coin-packages',
        (_) => qaOk({
          'provider': 'sandbox',
          'mode': mode,
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
        }),
      );
  }
}
