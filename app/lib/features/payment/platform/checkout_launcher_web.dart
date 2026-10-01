import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../providers/subscription_provider.dart';
import '../screens/checkout_waiting_sheet.dart';

/// Browser: never instantiate a native web view. Open the provider's hosted
/// page in a new tab and let the member tell us when they are back; the
/// caller then confirms through the API by polling the checkout.
Future<bool?> launchHostedCheckout(
  BuildContext context, {
  required BillingCheckout checkout,
  required String title,
}) async {
  final opened = web.window.open(checkout.checkoutUrl, '_blank');
  if (opened == null) {
    // Popup blocked: navigate the current tab instead. The return page tells
    // the member to come back to the app.
    web.window.location.assign(checkout.checkoutUrl);
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  return showCheckoutWaitingSheet(context, title: title);
}
