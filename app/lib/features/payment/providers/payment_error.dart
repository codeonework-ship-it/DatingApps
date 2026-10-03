import 'package:dio/dio.dart';

import '../../../core/network/api_error_message.dart';

/// Which client-side fallback a payment error is. Screens translate these;
/// a message [apiErrorMessage] already resolved has no code.
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
  unreachable(
    "Can't connect right now. Check your internet connection and try again.",
  );

  const PaymentErrorCode(this.english);

  /// English text kept in state for callers that read the raw message.
  final String english;
}

/// An error message plus, when it is not the server's own wording, the
/// [PaymentErrorCode] a screen can translate.
typedef PaymentFailure = ({String message, PaymentErrorCode? code});

/// The message for [error] and its translatable code, if any.
///
/// [apiErrorMessage] decides what the member may see: a known server
/// `error_code` (already translated), the server's own English text (English
/// only), or the fallback. A fallback keeps its English text plus a code the
/// screen translates; anything else is final text and has no code.
PaymentFailure paymentFailure(Object error, PaymentErrorCode fallback) {
  final message = apiErrorMessage(error, fallback: fallback.english);
  if (message == fallback.english) {
    return (message: message, code: fallback);
  }
  if (_isUnreachable(error)) {
    return (
      message: PaymentErrorCode.unreachable.english,
      code: PaymentErrorCode.unreachable,
    );
  }
  return (message: message, code: null);
}

bool _isUnreachable(Object error) =>
    error is DioException &&
    error.response == null &&
    (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout);
