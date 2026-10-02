import 'package:dio/dio.dart';

import '../../../core/network/api_error_message.dart';

/// Which client-side fallback a payment error is. Screens translate these;
/// a message the server sent is shown as sent and has no code.
enum PaymentErrorCode {
  signInSubscriptions('Please sign in to manage subscriptions.'),
  signInWallet('Please sign in to manage your wallet.'),
  loadSubscription('Unable to load subscription details.'),
  loadWallet('Unable to load your wallet.'),
  startCheckoutNow('Unable to start checkout right now.'),
  startCheckout('Unable to start checkout.'),
  confirmPayment('Unable to confirm the payment yet.'),
  autoRenewOn('Unable to turn auto-renew back on.'),
  autoRenewOff('Unable to turn off auto-renew.'),
  changePlan('Unable to change plan.'),
  updateCard('Unable to update the card.'),
  sandboxFailed('Sandbox simulation failed.'),
  unreachable('Cannot reach the local service. Check that the API is running.');

  const PaymentErrorCode(this.english);

  /// English text kept in state for callers that read the raw message.
  final String english;
}

/// An error message plus, when it is not the server's own wording, the
/// [PaymentErrorCode] a screen can translate.
typedef PaymentFailure = ({String message, PaymentErrorCode? code});

/// The English message for [error] and its translatable code, if any.
PaymentFailure paymentFailure(Object error, PaymentErrorCode fallback) {
  final message = apiErrorMessage(error, fallback: fallback.english);
  if (_hasServerMessage(error)) {
    return (message: message, code: null);
  }
  if (message == fallback.english) {
    return (message: message, code: fallback);
  }
  return (message: message, code: PaymentErrorCode.unreachable);
}

bool _hasServerMessage(Object error) {
  if (error is! DioException) {
    return false;
  }
  final data = error.response?.data;
  if (data is! Map) {
    return false;
  }
  final message = data['error'] ?? data['message'];
  return message != null && message.toString().trim().isNotEmpty;
}
