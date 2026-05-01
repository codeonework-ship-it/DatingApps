import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';

void main() {
  testWidgets('wallet screen renders balance and key sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WalletPaymentScreen(walletCoins: 42)),
    );

    expect(find.text('Wallet & Payments'), findsOneWidget);
    expect(find.text('Glow wallet balance'), findsOneWidget);
    expect(find.text('42 coins'), findsOneWidget);
    expect(find.text('Payment methods'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Popular top-ups'), findsOneWidget);
  });
}
