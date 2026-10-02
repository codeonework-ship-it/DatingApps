import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/subscription_provider.dart';

/// Hosts the provider's card checkout page.
///
/// The app never sees card details: the page belongs to the payment provider
/// (or the local sandbox). When the page redirects to the backend's return
/// URL this screen pops with the reported outcome so the caller can confirm
/// the subscription through the API rather than trusting the redirect.
class CheckoutWebViewScreen extends StatefulWidget {
  const CheckoutWebViewScreen({
    required this.checkout,
    required this.planName,
    super.key,
  });

  final BillingCheckout checkout;
  final String planName;

  /// Opens the checkout and resolves with `true` when the page reported
  /// success, `false` when the member cancelled, or `null` when they left
  /// without finishing.
  static Future<bool?> open(
    BuildContext context, {
    required BillingCheckout checkout,
    required String planName,
  }) => Navigator.of(context).push<bool?>(
    MaterialPageRoute<bool?>(
      fullscreenDialog: true,
      builder: (_) =>
          CheckoutWebViewScreen(checkout: checkout, planName: planName),
    ),
  );

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => _intercept(request.url)
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
          onPageStarted: (url) {
            if (_intercept(url)) {
              return;
            }
            if (mounted) {
              setState(() => _loading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkout.checkoutUrl));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setBackgroundColor(Theme.of(context).scaffoldBackgroundColor);
  }

  bool _intercept(String url) {
    if (_finished || !widget.checkout.isReturnUrl(url)) {
      return false;
    }
    _finished = true;
    final status = Uri.tryParse(url)?.queryParameters['status'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(status == 'success');
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ground = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ground,
      appBar: AppBar(
        title: Text(l10n.paymentCheckoutPayFor(widget.planName)),
        leading: IconButton(
          key: const ValueKey('qa.checkout.close'),
          icon: const Icon(Icons.close),
          tooltip: l10n.paymentCheckoutClose,
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: ground,
                  child: Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.paymentCheckoutSecureNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
