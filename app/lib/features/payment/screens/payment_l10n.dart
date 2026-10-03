import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/payment_error.dart';

/// Locale-aware formatting shared by the payment screens.
///
/// English output matches the app's long-standing format (`₹199`, `₹9.99`,
/// `2 Oct 2026`) so existing UI tests keep matching.
String paymentLocaleName(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// [amount] in [currency]. Whole amounts drop the decimals unless
/// [alwaysDecimals] is set (coin pack prices always show cents).
String paymentMoney(
  BuildContext context,
  double amount,
  String currency, {
  bool alwaysDecimals = false,
}) {
  final code = currency.toUpperCase();
  final symbol = switch (code) {
    'INR' => '₹',
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    _ => '$code ',
  };
  final whole = amount == amount.roundToDouble();
  return NumberFormat.currency(
    locale: paymentLocaleName(context),
    name: code,
    symbol: symbol,
    decimalDigits: whole && !alwaysDecimals ? 0 : 2,
  ).format(amount);
}

/// Day, short month and year in the member's local time.
String paymentDate(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context);
  final local = value.toLocal();
  if (locale.languageCode == 'en' && locale.countryCode == null) {
    return DateFormat('d MMM y', 'en').format(local);
  }
  return DateFormat.yMMMd(locale.toString()).format(local);
}

/// Translated fallback for [code], or the server's own [message].
String paymentErrorText(
  AppLocalizations l10n,
  PaymentErrorCode? code,
  String message,
) => switch (code) {
  null => message,
  PaymentErrorCode.signInSubscriptions => l10n.paymentErrorSignInSubscriptions,
  PaymentErrorCode.signInWallet => l10n.paymentErrorSignInWallet,
  PaymentErrorCode.loadSubscription => l10n.paymentErrorLoadSubscription,
  PaymentErrorCode.loadWallet => l10n.paymentErrorLoadWallet,
  PaymentErrorCode.startCheckoutNow => l10n.paymentErrorStartCheckoutNow,
  PaymentErrorCode.startCheckout => l10n.paymentErrorStartCheckout,
  PaymentErrorCode.confirmPayment => l10n.paymentErrorConfirmPayment,
  PaymentErrorCode.autoRenewOn => l10n.paymentErrorAutoRenewOn,
  PaymentErrorCode.autoRenewOff => l10n.paymentErrorAutoRenewOff,
  PaymentErrorCode.changePlan => l10n.paymentErrorChangePlan,
  PaymentErrorCode.updateCard => l10n.paymentErrorUpdateCard,
  PaymentErrorCode.sandboxFailed => l10n.paymentErrorSandboxFailed,
  PaymentErrorCode.unreachable => l10n.networkOfflineTryAgain,
};
