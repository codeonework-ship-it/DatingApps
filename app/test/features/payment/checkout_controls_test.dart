// The in-app checkout host (native) and the "complete in the new tab" sheet
// (web). The provider's own card form cannot render in a widget test — card
// entry is a manual/emulator check with the sandbox or Stripe test cards —
// so these tests drive the scripted web view: what URL is loaded and how
// each redirect is handled.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/payment/providers/subscription_provider.dart';
import 'package:verified_dating_app/features/payment/screens/checkout_waiting_sheet.dart';
import 'package:verified_dating_app/features/payment/screens/checkout_webview_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../support/checkout_webview_fake.dart';
import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'billing_fake.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

final _checkout = BillingCheckout.fromJson(checkoutJson('co-7'));

late ScriptedCheckoutWebView webView;

/// Opens the checkout from a launcher, as the membership and wallet screens
/// do, and returns what it popped.
Future<List<Object?>> _openCheckout(WidgetTester tester, {Locale? locale}) =>
    pumpQa(
      tester,
      QaApi(),
      CheckoutWebViewScreen(checkout: _checkout, planName: 'Silver'),
      launcher: true,
      locale: locale,
    );

void main() {
  setUp(() {
    webView = ScriptedCheckoutWebView();
    WebViewPlatform.instance = webView;
  });

  group('CheckoutWebViewScreen', () {
    testWidgets(
      'loads exactly the provider page for this checkout behind a spinner',
      (tester) async {
        await _openCheckout(tester);
        expect(webView.loaded, [_checkout.checkoutUrl]);
        expect(find.text(en.paymentCheckoutPayFor('Silver')), findsOneWidget);
        expect(find.text(en.paymentCheckoutSecureNote), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        webView.finishLoading();
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('Close checkout pops with no outcome (member left early) '
        '[case:payment.checkout_webview.checkout_close.action]', (
      tester,
    ) async {
      final results = await _openCheckout(tester);
      await tester.tap(find.byTooltip(en.paymentCheckoutClose));
      await qaSettle(tester);
      expect(find.byType(CheckoutWebViewScreen), findsNothing);
      expect(results, [null]);
    });

    testWidgets('the success redirect is intercepted and reported as paid '
        '[case:payment.checkout_webview.return_success]', (tester) async {
      final results = await _openCheckout(tester);
      final decision = await webView.navigate(
        returnRedirect('co-7', 'success'),
      );
      await qaSettle(tester);
      expect(decision, NavigationDecision.prevent);
      expect(find.byType(CheckoutWebViewScreen), findsNothing);
      expect(results, [true]);
    });

    testWidgets(
      'the cancelled redirect is intercepted and reported as not paid '
      '[case:payment.checkout_webview.return_cancel]',
      (tester) async {
        final results = await _openCheckout(tester);
        await webView.navigate(returnRedirect('co-7', 'cancelled'));
        await qaSettle(tester);
        expect(results, [false]);
      },
    );

    testWidgets(
      'provider pages and other checkouts\' redirects are not treated as '
      'the end of this checkout [case:payment.checkout_webview.foreign_redirect]',
      (tester) async {
        final results = await _openCheckout(tester);
        // 3-D Secure or a provider sub-page: allowed through.
        expect(
          await webView.navigate('https://hooks.stripe.test/3ds/authorize'),
          NavigationDecision.navigate,
        );
        // Same return path but a different checkout id: not ours.
        expect(
          await webView.navigate(returnRedirect('co-other', 'success')),
          NavigationDecision.navigate,
        );
        // Look-alike host with the right path and id.
        expect(
          await webView.navigate(
            'http://evil.test/v1/billing/checkout/return?checkout_id=co-7&status=success',
          ),
          NavigationDecision.navigate,
        );
        await qaSettle(tester);
        expect(find.byType(CheckoutWebViewScreen), findsOneWidget);
        expect(results, isEmpty);

        // A second success redirect after the first is ignored (one pop).
        await webView.navigate(returnRedirect('co-7', 'success'));
        await webView.navigate(returnRedirect('co-7', 'success'));
        await qaSettle(tester);
        expect(results, [true]);
      },
    );

    testWidgets('checkout chrome is translated in all 10 languages '
        '[case:payment.checkout_webview.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        webView = ScriptedCheckoutWebView();
        WebViewPlatform.instance = webView;
        await _openCheckout(tester, locale: locale);
        final l10n = qaL10n(locale);
        expect(
          find.text(l10n.paymentCheckoutPayFor('Silver')),
          findsOneWidget,
          reason: '$locale',
        );
        expect(find.byTooltip(l10n.paymentCheckoutClose), findsOneWidget);
        expect(find.text(l10n.paymentCheckoutSecureNote), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('web: complete in a new tab', () {
    Future<List<bool?>> openSheet(WidgetTester tester, {Locale? locale}) async {
      final results = <bool?>[];
      await pumpQa(
        tester,
        QaApi(),
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('qa.test.open_sheet'),
                onPressed: () async => results.add(
                  await showCheckoutWaitingSheet(context, title: 'Gold'),
                ),
                child: const Text('pay'),
              ),
            ),
          ),
        ),
        locale: locale,
      );
      await tester.tap(find.byKey(const ValueKey('qa.test.open_sheet')));
      await qaSettle(tester);
      return results;
    }

    testWidgets(
      'the waiting sheet tells the member to finish in the new tab and '
      'cannot be swiped away [case:payment.checkout_waiting_sheet.back_to_account.action]',
      (tester) async {
        final results = await openSheet(tester);
        expect(
          find.text(en.paymentCheckoutCompleteInNewTab('Gold')),
          findsOneWidget,
        );
        expect(find.text(en.paymentCheckoutWaitingBody), findsOneWidget);
        // Not dismissible: tapping the scrim keeps it open.
        await tester.tapAt(const Offset(20, 20));
        await qaSettle(tester);
        expect(
          find.text(en.paymentCheckoutCompleteInNewTab('Gold')),
          findsOneWidget,
        );
        expect(results, isEmpty);
      },
    );

    testWidgets(
      'Check confirmation closes the sheet and asks the app to confirm '
      '[case:payment.checkout_waiting_sheet.checkout_waiting_check_confirmation.action]',
      (tester) async {
        final results = await openSheet(tester);
        await tester.tap(
          find.byKey(const ValueKey('qa.checkout.waiting.check_confirmation')),
        );
        await qaSettle(tester);
        expect(
          find.text(en.paymentCheckoutCompleteInNewTab('Gold')),
          findsNothing,
        );
        expect(results, [true]);
      },
    );

    testWidgets('Back to account closes the sheet as not paid '
        '[case:payment.checkout_waiting_sheet.checkout_waiting_back_to_account.action]', (
      tester,
    ) async {
      final results = await openSheet(tester);
      expect(find.text(en.paymentCheckoutBackToAccount), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('qa.checkout.waiting.back_to_account')),
      );
      await qaSettle(tester);
      expect(results, [false]);
    });

    testWidgets(
      'the waiting sheet is translated in all 10 languages and fits a phone '
      '(regression: German overflowed the sheet) '
      '[case:payment.checkout_waiting_sheet.l10n]',
      (tester) async {
        for (final locale in qaLocales) {
          await tester.pumpWidget(const SizedBox());
          await openSheet(tester, locale: locale);
          final l10n = qaL10n(locale);
          expect(
            find.text(l10n.paymentCheckoutCompleteInNewTab('Gold')),
            findsOneWidget,
            reason: '$locale',
          );
          expect(
            find.text(l10n.paymentCheckoutCheckConfirmation),
            findsOneWidget,
          );
          expect(find.text(l10n.paymentCheckoutBackToAccount), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '$locale');
        }
      },
    );
  });

  group('screen quality', () {
    // The provider page is the scripted web view; what is judged is the
    // app's chrome around it (title, close, secure note) once the web view
    // has been created and asked to load this checkout.
    Finder loaded() => find.byKey(const ValueKey('qa.checkout.provider_page'));
    Widget build() =>
        CheckoutWebViewScreen(checkout: _checkout, planName: 'Silver');

    testWidgets('Checkout chrome lays out on phone and tablet in both themes '
        '[case:payment.checkout_webview.layout_matrix]', (tester) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: QaApi.new,
        build: build,
        loaded: () {
          expect(webView.loaded.last, _checkout.checkoutUrl);
          return loaded();
        },
      );
    });

    testWidgets('Checkout chrome meets tap-target, label and contrast '
        'guidelines [case:payment.checkout_webview.a11y_guidelines]', (
      tester,
    ) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: QaApi.new,
        build: build,
        loaded: () {
          expect(webView.loaded.last, _checkout.checkoutUrl);
          expect(find.text(en.paymentCheckoutSecureNote), findsOneWidget);
          return loaded();
        },
      );
    });
  });
}
