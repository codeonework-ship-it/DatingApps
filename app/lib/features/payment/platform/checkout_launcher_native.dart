import 'package:flutter/material.dart';

import '../providers/subscription_provider.dart';
import '../screens/checkout_webview_screen.dart';

/// Native: host the provider page in an in-app web view and return the
/// outcome the return URL reported (`true` paid, `false` cancelled, `null`
/// closed early).
Future<bool?> launchHostedCheckout(
  BuildContext context, {
  required BillingCheckout checkout,
  required String title,
}) => CheckoutWebViewScreen.open(context, checkout: checkout, planName: title);
