import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// A scripted stand-in for the native web view that hosts the payment
/// provider's checkout page.
///
/// The real provider page (Stripe or the local sandbox card form) cannot
/// render in a widget test, so typing a card number stays a manual/emulator
/// check. What this fake drives is everything the app owns around it: which
/// URL the screen loads, and what the screen does when the hosted page
/// redirects to the backend's return URL (`status=success` / `cancel`) or
/// to any other address.
class ScriptedCheckoutWebView extends WebViewPlatform {
  /// URLs the screen asked the web view to load, in order.
  final loaded = <String>[];

  NavigationRequestCallback? _onNavigationRequest;
  PageEventCallback? _onPageStarted;
  PageEventCallback? _onPageFinished;

  /// True once the screen has wired its navigation delegate.
  bool get isReady => _onNavigationRequest != null;

  /// Simulates the hosted page navigating to [url]. Returns the decision the
  /// app made; a let-through navigation also reports page start/finish.
  Future<NavigationDecision> navigate(String url) async {
    final callback = _onNavigationRequest;
    if (callback == null) {
      throw StateError('The checkout screen has not wired its web view yet.');
    }
    final decision = await callback(
      NavigationRequest(url: url, isMainFrame: true),
    );
    if (decision == NavigationDecision.navigate) {
      _onPageStarted?.call(url);
      _onPageFinished?.call(url);
    }
    return decision;
  }

  /// Reports that the first page finished loading (clears the spinner).
  void finishLoading() => _onPageFinished?.call(loaded.last);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _Controller(params, this);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _Delegate(params, this);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _View(params);
}

class _Controller extends PlatformWebViewController {
  _Controller(super.params, this.host) : super.implementation();
  final ScriptedCheckoutWebView host;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    host.loaded.add(params.uri.toString());
  }
}

class _Delegate extends PlatformNavigationDelegate {
  _Delegate(super.params, this.host) : super.implementation();
  final ScriptedCheckoutWebView host;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback callback,
  ) async => host._onNavigationRequest = callback;
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async =>
      host._onPageStarted = callback;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async =>
      host._onPageFinished = callback;
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async {}
}

class _View extends PlatformWebViewWidget {
  _View(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('qa.checkout.provider_page'));
}
