// Control-level tests for the Membership screen: every button and switch
// performs its action against a recording fake BFF and the member sees the
// result. Card entry happens on the payment provider's hosted page, which a
// widget test cannot render; the scripted web view stands in for it and
// reports the provider's return redirect (sandbox/Stripe test flow only, no
// real card or key anywhere).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/payment/screens/checkout_webview_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../support/checkout_webview_fake.dart';
import '../../support/qa_api.dart';
import 'billing_fake.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

late ScriptedCheckoutWebView webView;

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _open(WidgetTester tester, BillingServer server) async {
  await pumpQa(
    tester,
    server.api,
    const SubscriptionScreen(),
    size: const Size(430, 2600),
  );
}

/// Taps a GlassButton / button by key and lets the async work run.
Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.hitTestable().evaluate().isEmpty) {
    // Off screen or not built yet: scroll the membership list to it.
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }
  await tester.tap(target);
  await qaSettle(tester);
}

bool _enabled(WidgetTester tester, String key) {
  final widget = tester.widget(_key(key));
  final onPressed = (widget as dynamic).onPressed;
  return onPressed != null;
}

/// Drags the list down from the top like a member refreshing.
Future<void> _pullToRefresh(WidgetTester tester) async {
  // The indicator arms after a quarter of the (tall) viewport.
  await tester.fling(find.byType(ListView), const Offset(0, 1400), 1000);
  await qaSettle(tester, frames: 30);
}

/// The provider page redirects back to the app with [status].
Future<void> _providerReturns(
  WidgetTester tester,
  String checkoutId,
  String status,
) async {
  expect(find.byType(CheckoutWebViewScreen), findsOneWidget);
  final decision = await webView.navigate(returnRedirect(checkoutId, status));
  expect(decision, NavigationDecision.prevent);
  await qaSettle(tester, frames: 15);
}

void main() {
  setUp(() {
    webView = ScriptedCheckoutWebView();
    WebViewPlatform.instance = webView;
  });

  group('plan catalog', () {
    testWidgets(
      'Monthly/Yearly toggle switches every price and the checkout cycle '
      '[case:payment.subscription.monthly.action]',
      (tester) async {
        final server = BillingServer()..checkoutStatus = 'expired';
        await _open(tester, server);
        expect(find.text('₹9.99'), findsOneWidget);
        expect(find.text(en.membershipCycleNoteMonthly), findsOneWidget);

        await _tap(tester, 'qa.membership.cycle.yearly');
        expect(find.text('₹99.99'), findsOneWidget);
        expect(find.text('₹199.99'), findsOneWidget);
        expect(find.text('₹9.99'), findsNothing);
        expect(find.text(en.membershipCycleNoteYearly), findsOneWidget);

        // The chosen cycle is what the checkout is created for.
        await _tap(tester, 'qa.membership.plan.silver');
        await _tap(tester, 'qa.membership.subscribe.continue');
        expect(server.checkoutRequests.single, {
          'plan_id': 'silver',
          'billing_cycle': 'yearly',
        });

        await tester.tap(_key('qa.checkout.close'));
        await qaSettle(tester);
        await _tap(tester, 'qa.membership.cycle.monthly');
        expect(find.text('₹9.99'), findsOneWidget);
        expect(find.text('₹99.99'), findsNothing);
      },
    );

    testWidgets(
      'pull to refresh reloads plans, subscription, payments and account '
      '[case:payment.subscription.your_plan_renews_automatically_a_onrefresh.action]',
      (tester) async {
        final server = BillingServer();
        await _open(tester, server);
        server.api.calls.clear();
        server.subscription = paidSubscription(
          planId: 'silver',
          planName: 'Silver',
        );

        await _pullToRefresh(tester);

        expect(server.api.calls.map((c) => '${c.method} ${c.path}').toSet(), {
          'GET /billing/plans',
          'GET /billing/subscription/me',
          'GET /billing/payments/me',
          'GET /billing/account',
        });
        // The refreshed subscription is what the member now sees.
        expect(find.text(en.membershipYourMembership), findsOneWidget);
        expect(find.text(en.membershipYourCurrentPlan), findsOneWidget);
      },
    );

    testWidgets(
      'a failed refresh shows the server message inline and keeps the screen '
      '[case:payment.subscription.your_plan_renews_automatically_a_onrefresh.api_failure]',
      (tester) async {
        final server = BillingServer();
        await _open(tester, server);
        server.api.fail(
          'GET /billing/plans',
          status: 503,
          message: 'Billing is under maintenance.',
        );
        await _pullToRefresh(tester);
        expect(find.text('Billing is under maintenance.'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Offline: the translated fallback, not a raw exception.
        server.api.offline('GET /billing/plans');
        await _pullToRefresh(tester);
        expect(find.text(en.networkOfflineTryAgain), findsOneWidget);
      },
    );
  });

  group('subscribe with card', () {
    testWidgets(
      'Subscribe → Continue to card → provider success → celebration → '
      'Start exploring, and the plan is now current '
      '[case:payment.subscription.subscribe_with_card_onsubscribe.action] '
      '[case:payment.subscription.subscribe_to_plan.action] '
      '[case:payment.subscription.continue_to_card.action] '
      '[case:payment.subscription.start_exploring.action] '
      '[case:payment.subscription.start_exploring_2.action] '
      '[case:payment.checkout_webview.openers_handle_result]',
      (tester) async {
        final server = BillingServer()
          ..subscriptionAfterCheckout = paidSubscription(
            planId: 'silver',
            planName: 'Silver',
            amountMinor: 999,
          );
        await _open(tester, server);

        await _tap(tester, 'qa.membership.plan.silver');
        expect(
          find.text(en.membershipSubscribeTitle('Silver')),
          findsOneWidget,
        );
        // Sandbox account: the dialog tells the member no real card is charged.
        expect(
          find.text(en.membershipSubscribeBodyTestMonthly('₹9.99')),
          findsOneWidget,
        );

        await _tap(tester, 'qa.membership.subscribe.continue');
        final post = server.api.sent('POST', '/billing/checkout').single;
        expect(post.body, {'plan_id': 'silver', 'billing_cycle': 'monthly'});
        expect(
          post.options.headers['Idempotency-Key'],
          startsWith('checkout-me-silver-monthly-'),
        );
        // The hosted page for exactly this checkout is opened in-app.
        expect(webView.loaded, [
          'http://bff.test/v1/billing/sandbox/checkout/co-1',
        ]);
        expect(find.text(en.paymentCheckoutPayFor('Silver')), findsOneWidget);

        await _providerReturns(tester, 'co-1', 'success');

        // The app confirms through the API instead of trusting the redirect.
        expect(server.api.sent('GET', '/billing/checkout/co-1'), isNotEmpty);
        expect(find.byType(CheckoutWebViewScreen), findsNothing);
        expect(
          find.text(en.membershipCelebrateTitle('Silver')),
          findsOneWidget,
        );
        expect(find.text(en.membershipCelebrateBodyTest), findsOneWidget);

        await _tap(tester, 'qa.membership.start_exploring');
        expect(find.text(en.membershipCelebrateTitle('Silver')), findsNothing);
        expect(find.text(en.membershipYourMembership), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: _key('qa.membership.plan.silver'),
                  matching: find.byType(Text),
                ),
              )
              .data,
          en.membershipYourCurrentPlan,
        );
      },
    );

    testWidgets(
      'Not now closes the subscribe dialog without creating a checkout '
      '[case:payment.subscription.not_now_2.action]',
      (tester) async {
        final server = BillingServer();
        await _open(tester, server);
        await _tap(tester, 'qa.membership.plan.gold');
        expect(find.text(en.membershipSubscribeTitle('Gold')), findsOneWidget);
        await _tap(tester, 'qa.membership.subscribe.not_now');
        expect(find.text(en.membershipSubscribeTitle('Gold')), findsNothing);
        expect(server.api.sent('POST', '/billing/checkout'), isEmpty);
        expect(find.byType(CheckoutWebViewScreen), findsNothing);
      },
    );

    testWidgets(
      'checkout creation failure shows the reason and re-enables Subscribe '
      '[case:payment.subscription.subscribe_with_card_onsubscribe.api_failure]',
      (tester) async {
        final server = BillingServer();
        server.api.fail(
          'POST /billing/checkout',
          status: 409,
          message: 'Card checkout is paused for maintenance.',
        );
        await _open(tester, server);
        await _tap(tester, 'qa.membership.plan.silver');
        await _tap(tester, 'qa.membership.subscribe.continue');

        expect(
          find.text('Card checkout is paused for maintenance.'),
          findsOneWidget,
        );
        expect(find.byType(CheckoutWebViewScreen), findsNothing);
        expect(server.api.sent('POST', '/billing/checkout'), hasLength(1));
        expect(_enabled(tester, 'qa.membership.plan.silver'), isTrue);
        expect(find.text(en.membershipSubscribeWithCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'cancelling on the provider page ends the session with a clear message '
      '[case:payment.subscription.subscribe_with_card_onsubscribe.cancelled] '
      '[case:payment.checkout_webview.return_cancel]',
      (tester) async {
        final server = BillingServer()..checkoutStatus = 'abandoned';
        await _open(tester, server);
        await _tap(tester, 'qa.membership.plan.silver');
        await _tap(tester, 'qa.membership.subscribe.continue');
        await _providerReturns(tester, 'co-1', 'cancel');

        expect(qaSnackText(tester), en.membershipCheckoutEnded);
        expect(find.text(en.membershipCelebrateTitle('Silver')), findsNothing);
        expect(find.text(en.membershipYourPlan), findsOneWidget);
        expect(_enabled(tester, 'qa.membership.plan.silver'), isTrue);
      },
    );

    testWidgets(
      'closing the checkout early leaves the member on Free and says so '
      '[case:payment.checkout_webview.close_checkout.action]',
      (tester) async {
        final server = BillingServer()..checkoutStatus = 'expired';
        await _open(tester, server);
        await _tap(tester, 'qa.membership.plan.silver');
        await _tap(tester, 'qa.membership.subscribe.continue');
        expect(find.byType(CheckoutWebViewScreen), findsOneWidget);
        expect(
          tester.widget<IconButton>(_key('qa.checkout.close')).tooltip,
          en.paymentCheckoutClose,
        );

        await tester.tap(_key('qa.checkout.close'));
        await qaSettle(tester, frames: 15);

        expect(find.byType(CheckoutWebViewScreen), findsNothing);
        expect(server.api.sent('GET', '/billing/checkout/co-1'), isNotEmpty);
        expect(qaSnackText(tester), en.membershipCheckoutEnded);
      },
    );
  });

  group('auto-renew', () {
    testWidgets(
      'turning auto-renew off asks first; Keep renewing changes nothing '
      '[case:payment.subscription.turn_off.action] '
      '[case:payment.subscription.keep_renewing.action]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        await _open(tester, server);
        await _tap(tester, 'qa.membership.auto_renew');
        expect(find.text(en.membershipAutoRenewOffTitle), findsOneWidget);
        expect(
          find.textContaining('Your Gold benefits stay active until'),
          findsOneWidget,
        );

        await _tap(tester, 'qa.membership.auto_renew_off.keep');
        expect(find.text(en.membershipAutoRenewOffTitle), findsNothing);
        expect(server.api.writes, isEmpty);
        expect(
          tester.widget<SwitchListTile>(_key('qa.membership.auto_renew')).value,
          isTrue,
        );
      },
    );

    testWidgets(
      'Turn off sends cancel-at-period-end and the switch, chip and line follow '
      '[case:payment.subscription.auto_renew_onautorenewchanged.action] '
      '[case:payment.subscription.turn_off_2.action]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        await _open(tester, server);
        await _tap(tester, 'qa.membership.auto_renew');
        await _tap(tester, 'qa.membership.auto_renew_off.confirm');

        expect(server.api.writeLines, ['POST /billing/subscription/me/cancel']);
        expect(server.api.writes.single.body, isEmpty);
        expect(
          tester.widget<SwitchListTile>(_key('qa.membership.auto_renew')).value,
          isFalse,
        );
        expect(qaSnackText(tester), en.membershipAutoRenewNowOff);
        expect(find.text(en.membershipStatusEnding), findsOneWidget);
        expect(find.text(en.membershipAutoRenewOffSubtitle), findsOneWidget);
      },
    );

    testWidgets('turning auto-renew back on resumes without a confirmation '
        '[case:payment.subscription.auto_renew_onautorenewchanged.resume]', (
      tester,
    ) async {
      final server = BillingServer(
        subscription: paidSubscription(autoRenew: false),
      );
      await _open(tester, server);
      await _tap(tester, 'qa.membership.auto_renew');

      expect(find.text(en.membershipAutoRenewOffTitle), findsNothing);
      expect(server.api.writeLines, ['POST /billing/subscription/me/resume']);
      expect(
        tester.widget<SwitchListTile>(_key('qa.membership.auto_renew')).value,
        isTrue,
      );
      expect(qaSnackText(tester), en.membershipAutoRenewBackOn);
    });

    testWidgets(
      'a failed auto-renew change keeps the switch, explains and re-enables it '
      '[case:payment.subscription.auto_renew_onautorenewchanged.api_failure]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        server.api.fail(
          'POST /billing/subscription/me/cancel',
          status: 502,
          message: 'The payment provider did not answer.',
        );
        await _open(tester, server);
        await _tap(tester, 'qa.membership.auto_renew');
        await _tap(tester, 'qa.membership.auto_renew_off.confirm');

        expect(
          find.text('The payment provider did not answer.'),
          findsOneWidget,
        );
        expect(qaSnackText(tester), isNull);
        final toggle = tester.widget<SwitchListTile>(
          _key('qa.membership.auto_renew'),
        );
        expect(toggle.value, isTrue);
        expect(toggle.onChanged, isNotNull);
        expect(server.api.writes, hasLength(1));

        // Offline: the translated client fallback.
        server.api.offline('POST /billing/subscription/me/cancel');
        await _tap(tester, 'qa.membership.auto_renew');
        await _tap(tester, 'qa.membership.auto_renew_off.confirm');
        expect(find.text(en.networkOfflineTryAgain), findsOneWidget);
      },
    );
  });

  group('switch plan', () {
    testWidgets('switching asks first; Not now sends nothing '
        '[case:payment.subscription.switch_plan.action] '
        '[case:payment.subscription.not_now.action]', (tester) async {
      final server = BillingServer(subscription: paidSubscription());
      await _open(tester, server);
      expect(find.text(en.membershipSwitchToPlan('Silver')), findsOneWidget);

      await _tap(tester, 'qa.membership.plan.silver');
      expect(find.text(en.membershipSwitchTitle('Silver')), findsOneWidget);
      // Gold → Silver is a downgrade: credit, not a charge.
      expect(
        find.text(en.membershipSwitchDowngradeBodyMonthly('Gold', '₹9.99')),
        findsOneWidget,
      );
      await _tap(tester, 'qa.membership.switch.not_now');
      expect(find.text(en.membershipSwitchTitle('Silver')), findsNothing);
      expect(server.api.writes, isEmpty);
    });

    testWidgets('Switch plan changes the live subscription and confirms '
        '[case:payment.subscription.subscribe_with_card_onswitch.action] '
        '[case:payment.subscription.switch_plan_2.action]', (tester) async {
      final server = BillingServer(subscription: paidSubscription());
      await _open(tester, server);
      await _tap(tester, 'qa.membership.plan.silver');
      await _tap(tester, 'qa.membership.switch.confirm');

      final change = server.api
          .sent('POST', '/billing/subscription/me/change-plan')
          .single;
      expect(change.body, {'plan_id': 'silver', 'billing_cycle': 'monthly'});
      expect(qaSnackText(tester), en.membershipSwitchedSnack('Silver'));
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: _key('qa.membership.plan.silver'),
                matching: find.byType(Text),
              ),
            )
            .data,
        en.membershipYourCurrentPlan,
      );
      expect(find.text(en.membershipSwitchToPlan('Gold')), findsOneWidget);
    });

    testWidgets(
      'a refused switch explains why and leaves the member on their plan '
      '[case:payment.subscription.subscribe_with_card_onswitch.api_failure]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        server.api.fail(
          'POST /billing/subscription/me/change-plan',
          status: 409,
          message: 'A payment is still settling. Try again shortly.',
        );
        await _open(tester, server);
        await _tap(tester, 'qa.membership.plan.silver');
        await _tap(tester, 'qa.membership.switch.confirm');

        expect(
          find.text('A payment is still settling. Try again shortly.'),
          findsOneWidget,
        );
        expect(qaSnackText(tester), isNull);
        expect(_enabled(tester, 'qa.membership.plan.silver'), isTrue);
        expect(find.text(en.membershipSwitchToPlan('Silver')), findsOneWidget);
        expect(server.api.writes, hasLength(1));
      },
    );
  });

  group('update card', () {
    testWidgets(
      'Update card opens a card-update checkout and confirms the new card '
      '[case:payment.subscription.update_card_onupdatecard.action]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        await _open(tester, server);
        await _tap(tester, 'qa.membership.update_card');

        final post = server.api.sent('POST', '/billing/checkout').single;
        expect(post.body, {'kind': 'card_update'});
        expect(post.options.headers['Idempotency-Key'], startsWith('card-me-'));
        expect(
          find.text(en.paymentCheckoutPayFor(en.membershipCheckoutTitleCard)),
          findsOneWidget,
        );

        await _providerReturns(tester, 'co-1', 'success');
        expect(server.api.sent('GET', '/billing/checkout/co-1'), isNotEmpty);
        expect(qaSnackText(tester), en.membershipCardUpdated);
        expect(_enabled(tester, 'qa.membership.update_card'), isTrue);
        expect(find.text(en.membershipUpdateCard), findsOneWidget);
      },
    );

    testWidgets('a failed card update explains and re-enables the button '
        '[case:payment.subscription.update_card_onupdatecard.api_failure]', (
      tester,
    ) async {
      final server = BillingServer(subscription: paidSubscription());
      server.api.fail('POST /billing/checkout', status: 500, message: '');
      await _open(tester, server);
      await _tap(tester, 'qa.membership.update_card');

      // No server wording: the translated client fallback.
      expect(find.text(en.paymentErrorUpdateCard), findsOneWidget);
      expect(find.byType(CheckoutWebViewScreen), findsNothing);
      expect(_enabled(tester, 'qa.membership.update_card'), isTrue);
      expect(server.api.sent('POST', '/billing/checkout'), hasLength(1));
    });
  });

  group('unfinished checkouts on the payment account', () {
    BillingServer pending() =>
        BillingServer()
          ..pendingCheckouts = [checkoutJson('co-9', planCode: 'silver')];

    testWidgets(
      'Check status re-reads the account and confirms a settled checkout '
      '[case:payment.subscription.check_status_oncheck.action]',
      (tester) async {
        final server = pending()
          ..subscriptionAfterCheckout = paidSubscription(
            planId: 'silver',
            planName: 'Silver',
          );
        await _open(tester, server);
        expect(
          find.text(en.paymentAccountUnfinishedCheckout('silver')),
          findsOneWidget,
        );
        server.api.calls.clear();

        await _tap(tester, 'qa.payment.check_status.co-9');

        final lines = server.api.calls.map((c) => '${c.method} ${c.path}');
        expect(lines, contains('GET /billing/account'));
        expect(lines, contains('GET /billing/checkout/co-9'));
        expect(find.byType(CheckoutWebViewScreen), findsNothing);
        expect(qaSnackText(tester), en.membershipRecoverConfirmed);
        expect(find.text(en.membershipYourMembership), findsOneWidget);
      },
    );

    testWidgets('Check status when the account cannot be read says so '
        '[case:payment.subscription.check_status_oncheck.api_failure]', (
      tester,
    ) async {
      final server = pending();
      await _open(tester, server);
      server.api.fail('GET /billing/account', status: 503);
      await _tap(tester, 'qa.payment.check_status.co-9');
      expect(qaSnackText(tester), en.membershipRecoverAccountUnavailable);
      expect(server.api.sent('GET', '/billing/checkout/co-9'), isEmpty);
    });

    testWidgets('Resume checkout reopens the same hosted page and confirms it '
        '[case:payment.subscription.resume_checkout_onresume.action]', (
      tester,
    ) async {
      final server = pending();
      await _open(tester, server);
      await _tap(tester, 'qa.payment.resume_checkout.co-9');

      expect(webView.loaded, [
        'http://bff.test/v1/billing/sandbox/checkout/co-9',
      ]);
      expect(server.api.sent('POST', '/billing/checkout'), isEmpty);
      await _providerReturns(tester, 'co-9', 'success');
      expect(qaSnackText(tester), en.membershipRecoverConfirmed);
      expect(
        find.text(en.paymentAccountUnfinishedCheckout('silver')),
        findsNothing,
      );
    });

    testWidgets(
      'Resume checkout on a session that closed meanwhile does not reopen it '
      '[case:payment.subscription.resume_checkout_onresume.api_failure]',
      (tester) async {
        final server = pending();
        await _open(tester, server);
        // Another device finished or expired it.
        server.pendingCheckouts = [];
        await _tap(tester, 'qa.payment.resume_checkout.co-9');
        expect(find.byType(CheckoutWebViewScreen), findsNothing);
        expect(webView.loaded, isEmpty);
        expect(qaSnackText(tester), en.membershipRecoverCheckoutClosed);
      },
    );
  });

  group('sandbox renewal clock (debug builds only)', () {
    testWidgets(
      'Renewal paid advances the sandbox and the payment history shows it '
      '[case:payment.subscription.sandboxcontrols_onevent_onevent.action] '
      '[case:payment.subscription.payment_history.render]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        await _open(tester, server);
        expect(find.text(en.membershipNoCardPayments), findsOneWidget);

        await _tap(tester, 'qa.membership.sandbox.renewal_paid');

        final simulate = server.api
            .sent('POST', '/billing/sandbox/subscriptions/me/simulate')
            .single;
        expect(simulate.body, {'event': 'renewal_paid'});
        expect(find.text(en.membershipNoCardPayments), findsNothing);
        expect(
          find.text('${en.membershipPaymentReasonRenewal} · Visa •••• 4242'),
          findsOneWidget,
        );
        expect(find.text(en.membershipPaymentPaid), findsOneWidget);
      },
    );

    testWidgets(
      'a failed sandbox event is reported inline '
      '[case:payment.subscription.sandboxcontrols_onevent_onevent.api_failure]',
      (tester) async {
        final server = BillingServer(subscription: paidSubscription());
        server.api.fail(
          'POST /billing/sandbox/subscriptions/me/simulate',
          message: '',
        );
        await _open(tester, server);
        await _tap(tester, 'qa.membership.sandbox.refund');
        expect(find.text(en.paymentErrorSandboxFailed), findsOneWidget);
        expect(find.text(en.membershipNoCardPayments), findsOneWidget);
      },
    );

    testWidgets(
      'a Stripe (non-sandbox) membership never shows the sandbox controls '
      '[case:payment.subscription.sandboxcontrols_onevent_onevent.hidden_live]',
      (tester) async {
        final server = BillingServer(
          subscription: paidSubscription(provider: 'stripe'),
          mode: 'test',
        );
        await _open(tester, server);
        expect(_key('qa.membership.sandbox.renewal_paid'), findsNothing);
      },
    );
  });

  testWidgets(
    'subscribe, auto-renew and switch dialogs and the celebration fit a phone '
    'in all 10 languages (regression: the German celebration overflowed) '
    '[case:payment.subscription.l10n_dialogs]',
    (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final l10n = qaL10n(locale);
        // Free member: subscribe → celebration.
        final free = BillingServer()
          ..subscriptionAfterCheckout = paidSubscription(
            planId: 'silver',
            planName: 'Silver',
          );
        await pumpQa(
          tester,
          free.api,
          const SubscriptionScreen(),
          locale: locale,
        );
        await _tap(tester, 'qa.membership.plan.silver');
        expect(
          find.text(l10n.membershipSubscribeTitle('Silver')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$locale subscribe');
        await _tap(tester, 'qa.membership.subscribe.continue');
        await _providerReturns(tester, 'co-1', 'success');
        expect(
          find.text(l10n.membershipCelebrateTitle('Silver')),
          findsOneWidget,
          reason: '$locale',
        );
        expect(tester.takeException(), isNull, reason: '$locale celebrate');
        await _tap(tester, 'qa.membership.start_exploring');

        // Paid member: auto-renew off and switch dialogs.
        await tester.pumpWidget(const SizedBox());
        final paid = BillingServer(subscription: paidSubscription());
        await pumpQa(
          tester,
          paid.api,
          const SubscriptionScreen(),
          locale: locale,
        );
        await _tap(tester, 'qa.membership.auto_renew');
        expect(find.text(l10n.membershipAutoRenewOffTitle), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale auto-renew');
        await _tap(tester, 'qa.membership.auto_renew_off.keep');
        await _tap(tester, 'qa.membership.plan.silver');
        expect(find.text(l10n.membershipSwitchTitle('Silver')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale switch');
        await _tap(tester, 'qa.membership.switch.not_now');
      }
    },
  );

  testWidgets('Membership renders translated in all 10 languages '
      '[case:payment.subscription.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final server = BillingServer(subscription: paidSubscription());
      final l10n = qaL10n(locale);
      await pumpQa(
        tester,
        server.api,
        SubscriptionScreen(key: ValueKey(locale)),
        locale: locale,
        size: const Size(430, 2600),
      );
      expect(
        find.text(l10n.membershipTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.membershipChooseYourPlan),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.text(l10n.membershipAutoRenew), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
