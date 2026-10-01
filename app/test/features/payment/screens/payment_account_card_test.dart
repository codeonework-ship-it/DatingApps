import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/payment/providers/subscription_provider.dart';
import 'package:verified_dating_app/features/payment/screens/payment_account_card.dart';

void main() {
  for (final mode in ['sandbox', 'test', 'live', 'disabled']) {
    testWidgets('$mode account remains readable at 320px and large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var resumed = 0;
      var checked = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: PaymentAccountCard(
                  account: BillingAccount(
                    userId: 'u1',
                    name: 'A real member account',
                    email: 'member.with.long.email@example.test',
                    mode: mode,
                    customerConnected: true,
                    cardAvailable: mode != 'disabled',
                    pendingCheckouts: const [
                      BillingCheckout(
                        id: 'pending',
                        status: 'open',
                        checkoutUrl: 'https://checkout.test',
                        planCode: 'gold',
                        billingCycle: 'monthly',
                        amountMinor: 1999,
                        currency: 'INR',
                      ),
                    ],
                  ),
                  busy: false,
                  onResume: (_) => resumed++,
                  onCheck: (_) => checked++,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('member.with.long.email@example.test'), findsOneWidget);
      expect(
        find.textContaining('4242 4242'),
        mode == 'sandbox' || mode == 'test' ? findsOneWidget : findsNothing,
      );
      await tester.ensureVisible(find.text('Check status'));
      await tester.tap(find.text('Check status'));
      expect(checked, 1);
      await tester.ensureVisible(find.text('Resume checkout'));
      await tester.tap(find.text('Resume checkout'));
      expect(resumed, mode == 'disabled' ? 0 : 1);
    });
  }
}
