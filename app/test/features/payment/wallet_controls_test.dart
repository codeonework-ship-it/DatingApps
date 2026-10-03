// Control-level tests for the Wallet: buying a coin pack by card (sandbox
// provider via the scripted checkout web view — no real card or key),
// refreshing, and the credit history. The balance shown must always be the
// backend's, never a client-side sum.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/payment/screens/checkout_webview_screen.dart';
import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../support/checkout_webview_fake.dart';
import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'billing_fake.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

late ScriptedCheckoutWebView webView;

Finder _buy(String id) => find.byKey(ValueKey('qa.wallet.buy.$id'));

Future<void> _open(WidgetTester tester, BillingServer server) => pumpQa(
  tester,
  server.api,
  const WalletPaymentScreen(walletCoins: 42),
  size: const Size(430, 2000),
);

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(ListView), const Offset(0, 1200), 1000);
  await qaSettle(tester, frames: 30);
}

void main() {
  setUp(() {
    webView = ScriptedCheckoutWebView();
    WebViewPlatform.instance = webView;
  });

  testWidgets(
    'buying a pack opens the coin checkout, and the settled credit shows in '
    'the balance and the history [case:payment.wallet_payment.wallet_buy_x_buy.action] '
    '[case:payment.checkout_webview.openers_handle_result]',
    (tester) async {
      final server = BillingServer()..creditOnCompletion = 100;
      await _open(tester, server);
      expect(find.text(en.paymentCoinCount(112)), findsOneWidget);
      expect(find.text(en.paymentWalletNoPurchases), findsOneWidget);
      expect(find.text(en.paymentWalletTestNote), findsOneWidget);

      await tester.tap(_buy('p1'));
      await qaSettle(tester);

      final post = server.api.sent('POST', '/billing/checkout').single;
      expect(post.body, {'kind': 'coin_package', 'package_id': 'p1'});
      expect(
        post.options.headers['Idempotency-Key'],
        startsWith('coins-me-p1-'),
      );
      expect(find.byType(CheckoutWebViewScreen), findsOneWidget);
      expect(webView.loaded, [
        'http://bff.test/v1/billing/sandbox/checkout/co-1',
      ]);
      expect(
        find.text(en.paymentCheckoutPayFor(en.paymentCoinCount(100))),
        findsOneWidget,
      );

      await webView.navigate(returnRedirect('co-1', 'success'));
      await qaSettle(tester, frames: 15);

      expect(find.byType(CheckoutWebViewScreen), findsNothing);
      expect(server.api.sent('GET', '/billing/checkout/co-1'), isNotEmpty);
      expect(qaSnackText(tester), en.paymentCoinsAdded(100));
      // The balance is the server's settled value, re-read after the poll.
      expect(find.text(en.paymentCoinCount(212)), findsOneWidget);
      expect(find.text(en.paymentWalletNoPurchases), findsNothing);
      expect(find.text('+100'), findsOneWidget);
      // The button is ready for another purchase.
      expect(
        find.descendant(of: _buy('p1'), matching: find.text(r'$0.99')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a checkout that ends without paying adds nothing and says so '
      '[case:payment.wallet_payment.wallet_buy_x_buy.cancelled]', (tester) async {
    final server = BillingServer()..checkoutStatus = 'abandoned';
    await _open(tester, server);
    await tester.tap(_buy('p2'));
    await qaSettle(tester);
    await tester.tap(find.byTooltip(en.paymentCheckoutClose));
    await qaSettle(tester, frames: 15);

    expect(qaSnackText(tester), en.paymentWalletCheckoutEnded);
    expect(find.text(en.paymentCoinCount(112)), findsOneWidget);
    expect(find.text(en.paymentWalletNoPurchases), findsOneWidget);
  });

  testWidgets(
    'a refused checkout shows the reason and the pack can be bought again '
    '[case:payment.wallet_payment.wallet_buy_x_buy.api_failure]',
    (tester) async {
      final server = BillingServer();
      server.api.fail(
        'POST /billing/checkout',
        status: 409,
        message: 'Coin packs are not on sale in your region yet.',
      );
      await _open(tester, server);
      await tester.tap(_buy('p1'));
      await qaSettle(tester);

      expect(
        find.text('Coin packs are not on sale in your region yet.'),
        findsOneWidget,
      );
      expect(find.byType(CheckoutWebViewScreen), findsNothing);
      expect(server.api.sent('POST', '/billing/checkout'), hasLength(1));
      expect(
        find.descendant(of: _buy('p1'), matching: find.text(r'$0.99')),
        findsOneWidget,
      );

      // Offline: the translated client fallback.
      server.api.offline('POST /billing/checkout');
      await tester.tap(_buy('p1'));
      await qaSettle(tester);
      expect(find.text(en.networkOfflineTryAgain), findsOneWidget);
    },
  );

  testWidgets(
    'pull to refresh re-reads the balance and history from the server '
    '[case:payment.wallet_payment.coins_are_used_for_gifts_and_boo_onrefresh.action] '
    '[case:payment.wallet_payment.history.render]',
    (tester) async {
      final server = BillingServer();
      await _open(tester, server);
      expect(find.text(en.paymentCoinCount(112)), findsOneWidget);

      // A purchase settled on another device.
      server
        ..coinBalance = 662
        ..walletAudit = [
          {
            'id': 'a1',
            'action': 'wallet.coins.purchase',
            'status': 'success',
            'details': {'coins': 550, 'amount_minor': 399, 'currency': 'USD'},
            'created_at': '2026-10-01T09:00:00Z',
          },
          {
            'id': 'a2',
            'action': 'wallet.topup',
            'status': 'success',
            'details': {'coins': 25},
            'created_at': '2026-09-30T09:00:00Z',
          },
          // Spending is not a credit and is not listed.
          {
            'id': 'a3',
            'action': 'gift_send_succeeded',
            'status': 'success',
            'details': {'coins': 5},
            'created_at': '2026-09-30T10:00:00Z',
          },
        ];
      server.api.calls.clear();
      await _pullToRefresh(tester);

      expect(server.api.sent('GET', '/wallet/me/coins'), hasLength(1));
      expect(server.api.sent('GET', '/wallet/me/coins/audit'), hasLength(1));
      expect(server.api.sent('GET', '/billing/coin-packages'), hasLength(1));
      expect(find.text(en.paymentCoinCount(662)), findsOneWidget);
      expect(
        find.text('${en.paymentWalletSourcePurchase} · \$3.99'),
        findsOneWidget,
      );
      expect(find.text('+550'), findsOneWidget);
      expect(find.text(en.paymentWalletSourceSupport), findsOneWidget);
      expect(find.text('+25'), findsOneWidget);
      expect(find.text('+5'), findsNothing);
    },
  );

  testWidgets(
    'a failed refresh keeps the last balance and explains '
    '[case:payment.wallet_payment.coins_are_used_for_gifts_and_boo_onrefresh.api_failure]',
    (tester) async {
      final server = BillingServer();
      await _open(tester, server);
      server.api.fail('GET /wallet/me/coins', status: 503, message: '');
      await _pullToRefresh(tester);
      expect(find.text(en.paymentErrorLoadWallet), findsOneWidget);
      expect(find.text(en.paymentCoinCount(112)), findsOneWidget);
    },
  );

  testWidgets(
    'when card payments are switched off the packs are replaced by a note '
    '[case:payment.wallet_payment.cards_disabled]',
    (tester) async {
      final server = BillingServer();
      server.api.on(
        'GET /billing/coin-packages',
        (_) => qaError(501, message: 'card payments are not enabled'),
      );
      await _open(tester, server);
      expect(find.text(en.paymentWalletCardsDisabled), findsOneWidget);
      expect(_buy('p1'), findsNothing);
    },
  );

  testWidgets('Wallet renders translated in all 10 languages '
      '[case:payment.wallet_payment.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final server = BillingServer();
      final l10n = qaL10n(locale);
      await pumpQa(
        tester,
        server.api,
        WalletPaymentScreen(key: ValueKey(locale), walletCoins: 42),
        locale: locale,
        size: const Size(430, 2000),
      );
      expect(find.text(l10n.paymentWalletTitle), findsOneWidget);
      expect(find.text(l10n.paymentWalletPopularTopUps), findsOneWidget);
      expect(find.text(l10n.paymentWalletActivity), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });

  group('screen quality', () {
    // The screen opens with a stale 42; the server's 112 only shows once the
    // wallet arrived. Coin packs and a credit history are on screen too.
    BillingServer server() => BillingServer()
      ..walletAudit = [
        {
          'id': 'a1',
          'action': 'wallet.coins.purchase',
          'status': 'success',
          'details': {'coins': 550, 'amount_minor': 399, 'currency': 'USD'},
          'created_at': '2026-10-01T09:00:00Z',
        },
      ];
    Finder loaded() =>
        find.text(en.paymentCoinCount(112), skipOffstage: false);
    Widget build() => const WalletPaymentScreen(walletCoins: 42);

    testWidgets('Wallet with packs and history lays out on phone and tablet '
        'in both themes [case:payment.wallet_payment.layout_matrix]', (
      tester,
    ) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: () => server().api,
        build: build,
        loaded: loaded,
      );
    });

    testWidgets('Wallet meets tap-target, label and contrast guidelines, '
        'also with its error note showing '
        '[case:payment.wallet_payment.a11y_guidelines]', (tester) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: () => server().api,
        build: build,
        loaded: loaded,
      );
      // REGRESSION: the error note was error-red text on its own 12% red
      // tint, 3.8:1 in the light theme (under WCAG AA 4.5:1).
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: () => (server()..api.offline('GET /wallet/me/coins')).api,
        build: build,
        loaded: () => find.byKey(const Key('wallet_contact_support')),
      );
    });

    testWidgets('Back on the wallet returns to the screen that opened it '
        '[case:payment.wallet_payment.back_affordance]', (tester) async {
      await qaExpectBackReturnsToOpener(
        tester,
        api: server().api,
        build: build,
        screen: find.byType(WalletPaymentScreen),
        loaded: loaded(),
      );
    });
  });
}
