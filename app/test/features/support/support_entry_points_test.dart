import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/common/widgets/report_user_sheet.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_contact_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/support_api.dart';
import 'package:verified_dating_app/features/support/widgets/support_entry_points.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../support/checkout_webview_fake.dart';
import '../../support/qa_api.dart';
import '../payment/billing_fake.dart';
import 'support_fakes.dart';

// Ways into support from the rest of the app (support_entry_points.dart):
// the Settings tile with its unread badge, contextual "Contact support"
// links (payments, the report sheet) that stay hidden while requests are
// switched off, the start-up error screen and the signed-out recovery page.

const _on = {supportFeatureFlag: true};
const _off = {supportFeatureFlag: false};

Map<String, dynamic> _list({int unread = 0, int open = 1}) => {
  'success': true,
  'tickets': [ticketJson(unread: unread)],
  'unread_total': unread,
  'open_total': open,
};

/// A page with [child] and nothing else, under the fake API and [flags].
/// Flags arrive on a stream, so a few timed frames let them land.
Future<void> _pumpHost(
  WidgetTester tester,
  FakeSupportApi api,
  Widget child, {
  Map<String, bool> flags = _on,
}) async {
  await pumpSupport(
    tester,
    api,
    Scaffold(body: Center(child: child)),
    extra: [qaFlags(flags)],
  );
  await qaSettle(tester);
}

void main() {
  group('Settings: Help & Support tile', () {
    testWidgets(
      '[case:support.support_entry_points.help_support.action] shows unread '
      'replies as a badge and opens the support centre',
      (tester) async {
        final api = FakeSupportApi({
          'GET /support/tickets': (_) => ok(_list(unread: 2)),
        });
        await _pumpHost(tester, api, const SupportEntryTile());

        expect(
          find.byKey(const Key('settings_support_unread_badge')),
          findsOneWidget,
        );
        expect(find.text('2'), findsOneWidget);
        expect(find.text('2 new replies'), findsOneWidget);

        final before = api.sent('GET', '/support/tickets').length;
        await tester.tap(find.text('Help & Support'));
        await tester.pumpAndSettle();
        expect(find.byType(HelpSupportScreen), findsOneWidget);

        // Coming back refreshes the counts (the member may have read them).
        Navigator.of(tester.element(find.byType(HelpSupportScreen))).pop();
        await tester.pumpAndSettle();
        expect(api.sent('GET', '/support/tickets').length, greaterThan(before));
      },
    );

    testWidgets(
      '[case:support.support_entry_points.help_support.action] with requests '
      'off: no ticket call, plain subtitle, the FAQ still opens',
      (tester) async {
        final api = FakeSupportApi({
          'GET /support/tickets': (_) => ok(_list(unread: 3)),
        });
        await _pumpHost(tester, api, const SupportEntryTile(), flags: _off);

        expect(api.sent('GET', '/support/tickets'), isEmpty);
        expect(
          find.byKey(const Key('settings_support_unread_badge')),
          findsNothing,
        );
        expect(find.text('FAQ and contact support'), findsOneWidget);
        await tester.tap(find.text('Help & Support'));
        await tester.pumpAndSettle();
        expect(find.byType(HelpSupportScreen), findsOneWidget);
      },
    );

    testWidgets(
      '[case:common.settings.help_support.action] sits in the Account '
      'section of Settings, above Sign out, with the unread count',
      (tester) async {
        final api = QaApi();
        for (var depth = 1; depth <= 7; depth++) {
          api.json(
            'GET ${List.filled(depth, '/*').join()}',
            <String, dynamic>{},
          );
        }
        api.json('GET /support/tickets', _list(unread: 1));
        await pumpQa(tester, api, const SettingsScreen(), flags: _on);

        final help = find.byKey(const ValueKey('qa.settings.help_support'));
        final signOut = find.byKey(const ValueKey('qa.settings.logout'));
        expect(help, findsOneWidget);
        expect(
          tester.getTopLeft(help).dy,
          lessThan(tester.getTopLeft(signOut).dy),
        );
        expect(
          find.descendant(of: help, matching: find.text('1 new reply')),
          findsOneWidget,
        );
        await tester.tap(help);
        await qaSettle(tester);
        expect(find.byType(HelpSupportScreen), findsOneWidget);
      },
    );
  });

  group('Contact support links', () {
    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'opens a new request with the topic already chosen',
      (tester) async {
        final api = FakeSupportApi({});
        await _pumpHost(
          tester,
          api,
          const SupportContactLink(
            label: 'Payment problem? Contact support',
            category: 'payments_billing',
          ),
        );

        await tester.tap(find.text('Payment problem? Contact support'));
        await tester.pumpAndSettle();
        expect(find.byType(SupportTicketFormScreen), findsOneWidget);
        final chip = tester.widget<ChoiceChip>(
          find.byKey(const Key('support_category_payments_billing')),
        );
        expect(chip.selected, isTrue);
      },
    );

    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'is hidden while requests are switched off',
      (tester) async {
        await _pumpHost(
          tester,
          FakeSupportApi({}),
          const SupportContactLink(
            label: 'Payment problem? Contact support',
            category: 'payments_billing',
          ),
          flags: _off,
        );
        expect(find.text('Payment problem? Contact support'), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );

    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'the '
      'report sheet closes without reporting and opens a safety request',
      (tester) async {
        final api = FakeSupportApi({});
        String? sheetResult = 'not closed';
        var reported = false;
        await _pumpHost(
          tester,
          api,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                sheetResult = await showReportUserSheet(
                  context: context,
                  onSubmit: ({required reason, description}) async {
                    reported = true;
                    return 'report-1';
                  },
                );
              },
              child: const Text('report'),
            ),
          ),
        );
        await tester.tap(find.text('report'));
        await tester.pumpAndSettle();

        final link = find.byKey(const Key('report_contact_support'));
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();

        expect(reported, isFalse);
        expect(sheetResult, isNull);
        expect(find.byType(SupportTicketFormScreen), findsOneWidget);
        expect(find.byKey(const Key('support_safety_note')), findsOneWidget);
      },
    );
  });

  testWidgets(
    '[case:support.support_entry_points.support_centre_button.action] the '
    'start-up error button opens the support centre',
    (tester) async {
      final api = FakeSupportApi({'GET /support/tickets': (_) => ok(_list())});
      await _pumpHost(tester, api, const SupportCentreButton());
      await tester.tap(find.byKey(const Key('support_centre_button')));
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    },
  );

  testWidgets(
    '[case:auth.account_recovery.recovery_contact_support.action] signed out, '
    '"Can\'t sign in?" leads to the email support form',
    (tester) async {
      await pumpSupport(
        tester,
        FakeSupportApi({}),
        const AccountRecoveryScreen(),
      );
      final link = find.byKey(const ValueKey('qa.recovery.contact_support'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(SupportContactFormScreen), findsOneWidget);
      expect(find.byKey(const Key('support_guest_email')), findsOneWidget);
    },
  );

  group('payment errors offer support', () {
    setUp(() => WebViewPlatform.instance = ScriptedCheckoutWebView());

    Future<void> refresh(WidgetTester tester) async {
      await tester.fling(find.byType(ListView), const Offset(0, 1200), 1000);
      await qaSettle(tester, frames: 30);
    }

    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'Membership: a failed load shows "Contact support" for payments',
      (tester) async {
        final server = BillingServer();
        await pumpQa(
          tester,
          server.api,
          const SubscriptionScreen(),
          size: const Size(430, 2600),
          flags: _on,
        );
        expect(find.text('Payment problem? Contact support'), findsNothing);
        server.api.fail('GET /billing/plans', status: 503, message: 'Down.');
        await refresh(tester);

        final link = find.byKey(const Key('membership_contact_support'));
        expect(link, findsOneWidget);
        await tester.ensureVisible(link);
        await tester.tap(link);
        await qaSettle(tester);
        expect(find.byType(SupportTicketFormScreen), findsOneWidget);
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const Key('support_category_payments_billing')),
              )
              .selected,
          isTrue,
        );
      },
    );

    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'Wallet: a failed load offers support for payments',
      (tester) async {
        final server = BillingServer();
        await pumpQa(
          tester,
          server.api,
          const WalletPaymentScreen(walletCoins: 42),
          size: const Size(430, 2000),
          flags: _on,
        );
        server.api.fail('GET /wallet/me/coins', status: 503, message: '');
        await refresh(tester);
        final link = find.text('Payment problem? Contact support');
        expect(link, findsOneWidget);
        await tester.ensureVisible(link);
        await qaSettle(tester);
        await tester.tap(link);
        await qaSettle(tester);
        expect(find.byType(SupportTicketFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      '[case:support.support_entry_points.support_agent_rounded_icon_suppo.action] '
      'Wallet: no link while requests are switched off',
      (tester) async {
        final server = BillingServer();
        await pumpQa(
          tester,
          server.api,
          const WalletPaymentScreen(walletCoins: 42),
          size: const Size(430, 2000),
          flags: _off,
        );
        server.api.fail('GET /wallet/me/coins', status: 503, message: '');
        await refresh(tester);
        expect(find.text('Payment problem? Contact support'), findsNothing);
      },
    );
  });
}
