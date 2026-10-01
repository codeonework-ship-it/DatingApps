import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Subscriptions are sold through a hosted card checkout at the payment
/// provider. The app never handles card data and never marks a plan active
/// itself: it opens the checkout URL, then polls the checkout until the
/// provider's webhook has settled the first charge.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.likesPerDay,
    required this.messagesPerDay,
    required this.features,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Plan',
        monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 0,
        yearlyPrice: (json['yearly_price'] as num?)?.toDouble() ?? 0,
        likesPerDay: (json['likes_per_day'] as num?)?.toInt() ?? 0,
        messagesPerDay: (json['messages_per_day'] as num?)?.toInt() ?? 0,
        features: ((json['features'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),
        isActive: json['is_active'] != false,
      );

  final String id;
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final int likesPerDay;
  final int messagesPerDay;
  final List<String> features;
  final bool isActive;

  bool get isFree => monthlyPrice <= 0 && yearlyPrice <= 0;

  double priceFor(String billingCycle) =>
      billingCycle == 'yearly' ? yearlyPrice : monthlyPrice;
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.billingCycle,
    required this.startDate,
    this.nextBillingDate,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.provider = '',
    this.isPaid = false,
    this.entitled = true,
    this.autoRenew = false,
    this.cancelAtPeriodEnd = false,
    this.amountMinor = 0,
    this.currency = 'INR',
    this.cardBrand = '',
    this.cardLast4 = '',
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      UserSubscription(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        planId: json['plan_id']?.toString() ?? '',
        planName: json['plan_name']?.toString() ?? 'Subscription',
        status: json['status']?.toString() ?? 'active',
        billingCycle: json['billing_cycle']?.toString() ?? 'monthly',
        startDate:
            DateTime.tryParse(json['start_date']?.toString() ?? '') ??
            DateTime.now(),
        nextBillingDate: DateTime.tryParse(
          json['next_billing_date']?.toString() ?? '',
        ),
        currentPeriodEnd: DateTime.tryParse(
          json['current_period_end']?.toString() ?? '',
        ),
        cancelledAt: DateTime.tryParse(json['cancelled_at']?.toString() ?? ''),
        provider: json['provider']?.toString() ?? '',
        isPaid: json['is_paid'] == true,
        entitled: json['entitled'] != false,
        autoRenew: json['auto_renew'] == true,
        cancelAtPeriodEnd: json['cancel_at_period_end'] == true,
        amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
        currency: json['currency']?.toString() ?? 'INR',
        cardBrand: json['card_brand']?.toString() ?? '',
        cardLast4: json['card_last4']?.toString() ?? '',
      );

  final String id;
  final String userId;
  final String planId;
  final String planName;
  final String status;
  final String billingCycle;
  final DateTime startDate;
  final DateTime? nextBillingDate;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;
  final String provider;
  final bool isPaid;
  final bool entitled;
  final bool autoRenew;
  final bool cancelAtPeriodEnd;
  final int amountMinor;
  final String currency;
  final String cardBrand;
  final String cardLast4;

  bool get isPastDue => status == 'past_due';
  bool get isLive => status == 'active' || status == 'past_due';
  double get amount => amountMinor / 100;
  bool get hasCard => cardLast4.isNotEmpty;
}

class BillingPayment {
  const BillingPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.billingReason = '',
    this.cardBrand = '',
    this.cardLast4 = '',
    this.refundedAmount = 0,
    this.failureReason = '',
    this.periodEnd,
    this.disputeStatus = '',
  });

  factory BillingPayment.fromJson(Map<String, dynamic> json) => BillingPayment(
    id: json['id']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    currency: json['currency']?.toString() ?? 'INR',
    status: json['status']?.toString() ?? 'unknown',
    paymentMethod: json['payment_method']?.toString() ?? 'local',
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    billingReason: json['billing_reason']?.toString() ?? '',
    cardBrand: json['card_brand']?.toString() ?? '',
    cardLast4: json['card_last4']?.toString() ?? '',
    refundedAmount: (json['refunded_amount'] as num?)?.toDouble() ?? 0,
    failureReason: json['failure_reason']?.toString() ?? '',
    periodEnd: DateTime.tryParse(json['period_end']?.toString() ?? ''),
    disputeStatus: json['dispute_status']?.toString() ?? '',
  );

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final String billingReason;
  final String cardBrand;
  final String cardLast4;
  final double refundedAmount;
  final String failureReason;
  final DateTime? periodEnd;
  final String disputeStatus;

  bool get disputed => status == 'disputed';
  bool get chargedBack => status == 'chargeback';
  bool get succeeded => status == 'success';
  bool get failed => status == 'failed';
  bool get refunded => status == 'refunded' || status == 'partially_refunded';
}

/// A hosted checkout created by the backend.
class BillingCheckout {
  const BillingCheckout({
    required this.id,
    required this.status,
    required this.checkoutUrl,
    required this.planCode,
    required this.billingCycle,
    required this.amountMinor,
    required this.currency,
    this.returnUrl = '',
    this.kind = 'subscription',
  });

  factory BillingCheckout.fromJson(
    Map<String, dynamic> json, {
    String returnUrl = '',
  }) => BillingCheckout(
    id: json['id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'open',
    checkoutUrl: json['checkout_url']?.toString() ?? '',
    planCode: json['plan_code']?.toString() ?? '',
    billingCycle: json['billing_cycle']?.toString() ?? 'monthly',
    amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
    currency: json['currency']?.toString() ?? 'INR',
    returnUrl: returnUrl.isNotEmpty
        ? returnUrl
        : json['return_url']?.toString() ?? '',
    kind: json['kind']?.toString() ?? 'subscription',
  );

  final String id;
  final String status;
  final String checkoutUrl;
  final String planCode;
  final String billingCycle;
  final int amountMinor;
  final String currency;
  final String kind;

  /// Prefix of the URL the hosted page redirects to when finished. The
  /// checkout view intercepts it and hands control back to the app.
  final String returnUrl;

  bool get isCompleted => status == 'completed';
  bool get isOpen => status == 'open';

  /// Whether [url] is the provider's return redirect for this checkout.
  bool isReturnUrl(String url) {
    final candidate = Uri.tryParse(url);
    final expected = Uri.tryParse(returnUrl);
    return candidate != null &&
        expected != null &&
        expected.hasAuthority &&
        candidate.scheme == expected.scheme &&
        candidate.host == expected.host &&
        candidate.port == expected.port &&
        candidate.path == expected.path &&
        candidate.queryParameters['checkout_id'] == id;
  }
}

class BillingAccount {
  const BillingAccount({
    required this.userId,
    required this.name,
    required this.email,
    required this.mode,
    required this.customerConnected,
    required this.cardAvailable,
    this.pendingCheckouts = const [],
  });

  factory BillingAccount.fromJson(Map<String, dynamic> json) => BillingAccount(
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    mode: json['mode']?.toString() ?? 'disabled',
    customerConnected: json['customer_connected'] == true,
    cardAvailable:
        (json['payment_methods'] as List?)?.contains('card') == true &&
        const ['sandbox', 'test', 'live'].contains(json['mode']),
    pendingCheckouts: ((json['pending_checkouts'] as List?) ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((row) => BillingCheckout.fromJson(row.cast<String, dynamic>()))
        .toList(),
  );

  final String userId;
  final String name;
  final String email;
  final String mode;
  final bool customerConnected;
  final bool cardAvailable;
  final List<BillingCheckout> pendingCheckouts;
  bool get isTest => mode == 'sandbox' || mode == 'test';
}

enum CheckoutOutcome { completed, cancelled, pending, failed }

class SubscriptionState {
  const SubscriptionState({
    this.plans = const [],
    this.subscription,
    this.payments = const [],
    this.isLoading = false,
    this.checkoutPlanId,
    this.isUpdatingAutoRenew = false,
    this.changingPlanId,
    this.isUpdatingCard = false,
    this.error,
    this.account,
  });

  final List<SubscriptionPlan> plans;
  final UserSubscription? subscription;
  final List<BillingPayment> payments;
  final bool isLoading;

  /// Plan for which a checkout is being created or awaited.
  final String? checkoutPlanId;
  final bool isUpdatingAutoRenew;

  /// Plan a switch is in flight for.
  final String? changingPlanId;
  final bool isUpdatingCard;
  final String? error;
  final BillingAccount? account;

  SubscriptionPlan? get currentPlan {
    final id = subscription?.planId;
    if (id == null) {
      return null;
    }
    for (final plan in plans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }

  SubscriptionState copyWith({
    List<SubscriptionPlan>? plans,
    Object? subscription = _unset,
    List<BillingPayment>? payments,
    bool? isLoading,
    Object? checkoutPlanId = _unset,
    bool? isUpdatingAutoRenew,
    Object? changingPlanId = _unset,
    bool? isUpdatingCard,
    Object? error = _unset,
    Object? account = _unset,
  }) => SubscriptionState(
    plans: plans ?? this.plans,
    subscription: identical(subscription, _unset)
        ? this.subscription
        : subscription as UserSubscription?,
    payments: payments ?? this.payments,
    isLoading: isLoading ?? this.isLoading,
    checkoutPlanId: identical(checkoutPlanId, _unset)
        ? this.checkoutPlanId
        : checkoutPlanId as String?,
    isUpdatingAutoRenew: isUpdatingAutoRenew ?? this.isUpdatingAutoRenew,
    changingPlanId: identical(changingPlanId, _unset)
        ? this.changingPlanId
        : changingPlanId as String?,
    isUpdatingCard: isUpdatingCard ?? this.isUpdatingCard,
    error: identical(error, _unset) ? this.error : error as String?,
    account: identical(account, _unset)
        ? this.account
        : account as BillingAccount?,
  );

  static const Object _unset = Object();
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this.ref) : super(const SubscriptionState());

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;
  Dio get _api => ref.read(apiClientProvider);

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(error: 'Please sign in to manage subscriptions.');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final responses = await Future.wait([
        _api.get<dynamic>('/billing/plans'),
        _api.get<dynamic>('/billing/subscription/$userId'),
        _api.get<dynamic>(
          '/billing/payments/$userId',
          queryParameters: const {'limit': 100},
        ),
        _api.get<dynamic>('/billing/account'),
      ]);
      if (!mounted || _userId != userId) {
        return;
      }
      final accountRaw = (_asMap(responses[3].data)['account'] as Map?)
          ?.cast<String, dynamic>();
      if (accountRaw == null || accountRaw['user_id'] != userId) {
        throw const FormatException('Payment account could not be verified');
      }
      final plansBody = _asMap(responses[0].data);
      final subscriptionBody = _asMap(responses[1].data);
      final paymentsBody = _asMap(responses[2].data);
      final plans = ((plansBody['plans'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((row) => SubscriptionPlan.fromJson(row.cast<String, dynamic>()))
          .where((plan) => plan.isActive && plan.id.isNotEmpty)
          .toList();
      final subscriptionRaw = (subscriptionBody['subscription'] as Map?)
          ?.cast<String, dynamic>();
      state = state.copyWith(
        plans: plans,
        subscription: subscriptionRaw == null
            ? null
            : UserSubscription.fromJson(subscriptionRaw),
        payments: _parsePayments(paymentsBody),
        isLoading: false,
        error: null,
        account: BillingAccount.fromJson(accountRaw),
      );
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        account: null,
        error: apiErrorMessage(
          error,
          fallback: 'Unable to load subscription details.',
        ),
      );
    }
  }

  /// Creates a hosted card checkout for [plan]. Returns the checkout to open,
  /// or null with [SubscriptionState.error] set.
  Future<BillingCheckout?> startCheckout({
    required SubscriptionPlan plan,
    required String billingCycle,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }
    state = state.copyWith(checkoutPlanId: plan.id, error: null);
    try {
      final idempotencyKey =
          'checkout-$userId-${plan.id}-$billingCycle-'
          '${DateTime.now().microsecondsSinceEpoch}';
      final response = await _api.post<dynamic>(
        '/billing/checkout',
        data: {'plan_id': plan.id, 'billing_cycle': billingCycle},
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      if (!mounted || _userId != userId) {
        return null;
      }
      final body = _asMap(response.data);
      final checkoutRaw = (body['checkout'] as Map?)?.cast<String, dynamic>();
      if (checkoutRaw == null) {
        throw const FormatException('Missing checkout');
      }
      final checkout = BillingCheckout.fromJson(
        checkoutRaw,
        returnUrl: body['return_url']?.toString() ?? '',
      );
      if (checkout.checkoutUrl.isEmpty) {
        throw const FormatException('Checkout has no URL');
      }
      return checkout;
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return null;
      }
      state = state.copyWith(
        checkoutPlanId: null,
        error: apiErrorMessage(
          error,
          fallback: 'Unable to start checkout right now.',
        ),
      );
      return null;
    }
  }

  /// Polls the checkout until the provider webhook has settled it. The
  /// hosted page redirects before the webhook is necessarily processed, so a
  /// short wait is normal.
  Future<CheckoutOutcome> awaitCheckout(
    BillingCheckout checkout, {
    Duration timeout = const Duration(seconds: 45),
    Duration interval = const Duration(milliseconds: 900),
  }) async {
    final deadline = DateTime.now().add(timeout);
    final userId = _userId;
    var outcome = CheckoutOutcome.pending;
    try {
      while (DateTime.now().isBefore(deadline)) {
        if (!mounted || _userId != userId) {
          return CheckoutOutcome.pending;
        }
        final response = await _api.get<dynamic>(
          '/billing/checkout/${checkout.id}',
        );
        if (!mounted || _userId != userId) {
          return CheckoutOutcome.pending;
        }
        final body = _asMap(response.data);
        final status =
            (body['checkout'] as Map?)?['status']?.toString() ?? 'open';
        if (status == 'completed') {
          final subscriptionRaw = (body['subscription'] as Map?)
              ?.cast<String, dynamic>();
          if (subscriptionRaw != null) {
            state = state.copyWith(
              subscription: UserSubscription.fromJson(subscriptionRaw),
            );
          }
          outcome = CheckoutOutcome.completed;
          break;
        }
        if (status == 'expired' || status == 'abandoned') {
          outcome = CheckoutOutcome.failed;
          break;
        }
        await Future<void>.delayed(interval);
      }
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return CheckoutOutcome.pending;
      }
      state = state.copyWith(
        error: apiErrorMessage(
          error,
          fallback: 'Unable to confirm the payment yet.',
        ),
      );
      // A lost response is not proof that the card was not charged.
      outcome = CheckoutOutcome.pending;
    }
    if (!mounted || _userId != userId) {
      return CheckoutOutcome.pending;
    }
    state = state.copyWith(checkoutPlanId: null);
    await load();
    return outcome;
  }

  void cancelCheckout() {
    if (!mounted) {
      return;
    }
    state = state.copyWith(checkoutPlanId: null);
  }

  /// Turns auto-renew off (cancel at period end) or back on.
  Future<bool> setAutoRenew({required bool enabled}) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    state = state.copyWith(isUpdatingAutoRenew: true, error: null);
    try {
      final response = await _api.post<dynamic>(
        '/billing/subscription/$userId/${enabled ? 'resume' : 'cancel'}',
        data: const <String, dynamic>{},
      );
      if (!mounted || _userId != userId) {
        return false;
      }
      final subscriptionRaw = (_asMap(response.data)['subscription'] as Map?)
          ?.cast<String, dynamic>();
      state = state.copyWith(
        isUpdatingAutoRenew: false,
        subscription: subscriptionRaw == null
            ? state.subscription
            : UserSubscription.fromJson(subscriptionRaw),
      );
      return true;
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return false;
      }
      state = state.copyWith(
        isUpdatingAutoRenew: false,
        error: apiErrorMessage(
          error,
          fallback: enabled
              ? 'Unable to turn auto-renew back on.'
              : 'Unable to turn off auto-renew.',
        ),
      );
      return false;
    }
  }

  /// Switches the live paid subscription to [plan] on [billingCycle]. The
  /// provider prorates: upgrades charge the difference now, downgrades credit
  /// the unused time.
  Future<bool> changePlan({
    required SubscriptionPlan plan,
    required String billingCycle,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    state = state.copyWith(changingPlanId: plan.id, error: null);
    try {
      final response = await _api.post<dynamic>(
        '/billing/subscription/$userId/change-plan',
        data: {'plan_id': plan.id, 'billing_cycle': billingCycle},
      );
      if (!mounted || _userId != userId) {
        return false;
      }
      final subscriptionRaw = (_asMap(response.data)['subscription'] as Map?)
          ?.cast<String, dynamic>();
      state = state.copyWith(
        changingPlanId: null,
        subscription: subscriptionRaw == null
            ? state.subscription
            : UserSubscription.fromJson(subscriptionRaw),
      );
      await load();
      return true;
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return false;
      }
      state = state.copyWith(
        changingPlanId: null,
        error: apiErrorMessage(error, fallback: 'Unable to change plan.'),
      );
      return false;
    }
  }

  /// Opens a card-replacement checkout for the live subscription.
  Future<BillingCheckout?> startCardUpdate() async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }
    state = state.copyWith(isUpdatingCard: true, error: null);
    try {
      final response = await _api.post<dynamic>(
        '/billing/checkout',
        data: const {'kind': 'card_update'},
        options: Options(
          headers: {
            'Idempotency-Key':
                'card-$userId-${DateTime.now().microsecondsSinceEpoch}',
          },
        ),
      );
      if (!mounted || _userId != userId) {
        return null;
      }
      final body = _asMap(response.data);
      final raw = (body['checkout'] as Map?)?.cast<String, dynamic>();
      if (raw == null) {
        throw const FormatException('Missing checkout');
      }
      final checkout = BillingCheckout.fromJson(
        raw,
        returnUrl: body['return_url']?.toString() ?? '',
      );
      if (checkout.checkoutUrl.isEmpty) {
        throw const FormatException('Checkout has no URL');
      }
      return checkout;
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return null;
      }
      state = state.copyWith(
        isUpdatingCard: false,
        error: apiErrorMessage(error, fallback: 'Unable to update the card.'),
      );
      return null;
    }
  }

  void finishCardUpdate() {
    if (!mounted) {
      return;
    }
    state = state.copyWith(isUpdatingCard: false);
  }

  /// Sandbox-only QA control: advances the provider's renewal clock. Only
  /// meaningful in debug builds against a sandbox backend.
  Future<bool> simulateSandbox(String event) async {
    final userId = _userId;
    if (userId == null || !kDebugMode) {
      return false;
    }
    try {
      final response = await _api.post<dynamic>(
        '/billing/sandbox/subscriptions/$userId/simulate',
        data: {'event': event},
      );
      if (!mounted || _userId != userId) {
        return false;
      }
      final body = _asMap(response.data);
      final subscriptionRaw = (body['subscription'] as Map?)
          ?.cast<String, dynamic>();
      state = state.copyWith(
        subscription: subscriptionRaw == null
            ? state.subscription
            : UserSubscription.fromJson(subscriptionRaw),
        payments: body.containsKey('payments')
            ? _parsePayments(body)
            : state.payments,
      );
      return true;
    } on Object catch (error) {
      if (!mounted || _userId != userId) {
        return false;
      }
      state = state.copyWith(
        error: apiErrorMessage(error, fallback: 'Sandbox simulation failed.'),
      );
      return false;
    }
  }

  static Map<String, dynamic> _asMap(Object? data) =>
      (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  static List<BillingPayment> _parsePayments(Map<String, dynamic> body) =>
      ((body['payments'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((row) => BillingPayment.fromJson(row.cast<String, dynamic>()))
          .toList();
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      ref.watch(authNotifierProvider.select((auth) => auth.userId));
      return SubscriptionNotifier(ref);
    });
