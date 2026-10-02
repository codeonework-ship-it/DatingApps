import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'payment_error.dart';
import 'subscription_provider.dart';

/// Coin packs are bought with a card through the provider's hosted checkout.
/// The wallet is credited by the backend only when the provider's signed
/// event says the charge settled; the app never posts a balance.
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.label,
    required this.coinAmount,
    required this.totalCoins,
    required this.price,
    required this.currency,
    this.bonusPercent = 0,
    this.description = '',
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) => CoinPackage(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? 'Coins',
    coinAmount: (json['coin_amount'] as num?)?.toInt() ?? 0,
    totalCoins:
        (json['total_coins'] as num?)?.toInt() ??
        (json['coin_amount'] as num?)?.toInt() ??
        0,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    currency: json['currency']?.toString() ?? 'USD',
    bonusPercent: (json['bonus_percent'] as num?)?.toDouble() ?? 0,
    description: json['description']?.toString() ?? '',
  );

  final String id;
  final String label;
  final int coinAmount;
  final int totalCoins;
  final double price;
  final String currency;
  final double bonusPercent;
  final String description;

  int get bonusCoins => totalCoins - coinAmount;
}

class WalletPurchase {
  const WalletPurchase({
    required this.id,
    required this.coins,
    required this.source,
    required this.provider,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
  });

  /// Accepts either a wallet audit activity (`action` + `details`) or a raw
  /// purchase row.
  factory WalletPurchase.fromJson(Map<String, dynamic> json) {
    final details = (json['details'] as Map?)?.cast<String, dynamic>() ?? json;
    final action = json['action']?.toString() ?? '';
    final source = switch (action) {
      'wallet.topup' => 'admin_topup',
      'wallet.coins.purchase' => 'buy',
      _ => json['source']?.toString() ?? details['source']?.toString() ?? '',
    };
    return WalletPurchase(
      id: json['id']?.toString() ?? '',
      coins:
          (details['coins'] as num?)?.toInt() ??
          (details['amount'] as num?)?.toInt() ??
          0,
      source: source,
      provider: details['provider']?.toString() ?? '',
      amountMinor: (details['amount_minor'] as num?)?.toInt() ?? 0,
      currency: details['currency']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final int coins;
  final String source;
  final String provider;
  final int amountMinor;
  final String currency;
  final DateTime createdAt;
}

class WalletState {
  const WalletState({
    this.balance,
    this.packages = const [],
    this.purchases = const [],
    this.isLoading = false,
    this.buyingPackageId,
    this.error,
    this.errorCode,
    this.paymentsAvailable = true,
    this.paymentMode = 'disabled',
  });

  final int? balance;
  final List<CoinPackage> packages;
  final List<WalletPurchase> purchases;
  final bool isLoading;
  final String? buyingPackageId;
  final String? error;

  /// Set when [error] is a client fallback the screen can translate; null
  /// when [error] is the server's own message.
  final PaymentErrorCode? errorCode;
  final bool paymentsAvailable;
  final String paymentMode;

  WalletState copyWith({
    Object? balance = _unset,
    List<CoinPackage>? packages,
    List<WalletPurchase>? purchases,
    bool? isLoading,
    Object? buyingPackageId = _unset,
    Object? error = _unset,
    Object? errorCode = _unset,
    PaymentFailure? failure,
    bool? paymentsAvailable,
    String? paymentMode,
  }) => WalletState(
    balance: identical(balance, _unset) ? this.balance : balance as int?,
    packages: packages ?? this.packages,
    purchases: purchases ?? this.purchases,
    isLoading: isLoading ?? this.isLoading,
    buyingPackageId: identical(buyingPackageId, _unset)
        ? this.buyingPackageId
        : buyingPackageId as String?,
    error:
        failure?.message ??
        (identical(error, _unset) ? this.error : error as String?),
    // A new error without a code is the server's wording.
    errorCode: failure != null
        ? failure.code
        : identical(errorCode, _unset)
        ? (identical(error, _unset) ? this.errorCode : null)
        : errorCode as PaymentErrorCode?,
    paymentsAvailable: paymentsAvailable ?? this.paymentsAvailable,
    paymentMode: paymentMode ?? this.paymentMode,
  );

  static const Object _unset = Object();
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this.ref, {int? initialBalance})
    : super(WalletState(balance: initialBalance));

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;
  Dio get _api => ref.read(apiClientProvider);

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(
        error: PaymentErrorCode.signInWallet.english,
        errorCode: PaymentErrorCode.signInWallet,
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final responses = await Future.wait([
        _api.get<dynamic>('/wallet/$userId/coins'),
        _api.get<dynamic>(
          '/wallet/$userId/coins/audit',
          queryParameters: const {'limit': 20},
        ),
      ]);
      final wallet =
          ((responses[0].data as Map?)?['wallet'] as Map?)
              ?.cast<String, dynamic>() ??
          const {};
      final audit = (responses[1].data as Map?)?.cast<String, dynamic>() ?? {};
      final purchases =
          (audit['audit'] as List?)
              ?.whereType<Map<Object?, Object?>>()
              .map((row) => row.cast<String, dynamic>())
              .where(
                (row) =>
                    row['action'] == 'wallet.coins.purchase' ||
                    row['action'] == 'wallet.topup',
              )
              .map(WalletPurchase.fromJson)
              .where((p) => p.coins > 0)
              .toList() ??
          const <WalletPurchase>[];
      var packages = state.packages;
      var paymentsAvailable = state.paymentsAvailable;
      var paymentMode = 'disabled';
      try {
        final response = await _api.get<dynamic>('/billing/coin-packages');
        paymentMode =
            (response.data as Map?)?['mode']?.toString() ?? 'disabled';
        packages =
            ((response.data as Map?)?['packages'] as List?)
                ?.whereType<Map<Object?, Object?>>()
                .map((row) => CoinPackage.fromJson(row.cast<String, dynamic>()))
                .where((p) => p.id.isNotEmpty && p.price > 0)
                .toList() ??
            const <CoinPackage>[];
        paymentsAvailable = true;
      } on DioException catch (error) {
        if (error.response?.statusCode == 501) {
          paymentsAvailable = false;
          packages = const [];
        } else {
          rethrow;
        }
      }
      state = state.copyWith(
        balance: (wallet['coin_balance'] as num?)?.toInt() ?? state.balance,
        purchases: purchases,
        packages: packages,
        paymentsAvailable: paymentsAvailable,
        paymentMode: paymentMode,
        isLoading: false,
        error: null,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        failure: paymentFailure(error, PaymentErrorCode.loadWallet),
      );
    }
  }

  Future<BillingCheckout?> startCheckout(CoinPackage package) async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }
    state = state.copyWith(buyingPackageId: package.id, error: null);
    try {
      final response = await _api.post<dynamic>(
        '/billing/checkout',
        data: {'kind': 'coin_package', 'package_id': package.id},
        options: Options(
          headers: {
            'Idempotency-Key':
                'coins-$userId-${package.id}-'
                '${DateTime.now().microsecondsSinceEpoch}',
          },
        ),
      );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
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
      state = state.copyWith(
        buyingPackageId: null,
        failure: paymentFailure(error, PaymentErrorCode.startCheckout),
      );
      return null;
    }
  }

  /// Polls until the provider settles the charge and the backend credits the
  /// wallet. Returns the new balance on success.
  Future<CheckoutOutcome> awaitCheckout(
    BillingCheckout checkout, {
    Duration timeout = const Duration(seconds: 45),
    Duration interval = const Duration(milliseconds: 900),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var outcome = CheckoutOutcome.pending;
    try {
      while (DateTime.now().isBefore(deadline)) {
        final response = await _api.get<dynamic>(
          '/billing/checkout/${checkout.id}',
        );
        final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
        final status =
            (body['checkout'] as Map?)?['status']?.toString() ?? 'open';
        if (status == 'completed') {
          final wallet = (body['wallet'] as Map?)?.cast<String, dynamic>();
          if (wallet != null) {
            state = state.copyWith(
              balance:
                  (wallet['coin_balance'] as num?)?.toInt() ?? state.balance,
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
      state = state.copyWith(
        failure: paymentFailure(error, PaymentErrorCode.confirmPayment),
      );
      outcome = CheckoutOutcome.pending;
    }
    state = state.copyWith(buyingPackageId: null);
    await load();
    return outcome;
  }

  void cancelCheckout() {
    state = state.copyWith(buyingPackageId: null);
  }
}

final walletProvider = StateNotifierProvider.autoDispose
    .family<WalletNotifier, WalletState, int?>(
      (ref, initialBalance) =>
          WalletNotifier(ref, initialBalance: initialBalance),
    );
