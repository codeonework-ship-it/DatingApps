import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/subscription_provider.dart';

/// Stripe's published test card number; shown verbatim in every language.
const _stripeTestCard = '4242 4242 4242 4242';

class PaymentAccountCard extends StatelessWidget {
  const PaymentAccountCard({
    required this.account,
    required this.busy,
    required this.onResume,
    required this.onCheck,
    super.key,
  });

  final BillingAccount account;
  final bool busy;
  final ValueChanged<BillingCheckout> onResume;
  final ValueChanged<BillingCheckout> onCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final modeLabel = switch (account.mode) {
      'sandbox' => l10n.paymentModeSandbox,
      'test' => l10n.paymentModeStripeTest,
      'live' => l10n.paymentModeLive,
      _ => l10n.paymentModeUnavailable,
    };
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                Text(
                  l10n.paymentAccountTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    modeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              account.name.isEmpty
                  ? l10n.paymentAccountSignedInMember
                  : account.name,
              style: theme.textTheme.titleLarge,
            ),
            if (account.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(account.email, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Text(
              account.cardAvailable
                  ? l10n.paymentAccountCardTitle
                  : l10n.paymentAccountCardUnavailableTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              account.cardAvailable
                  ? l10n.paymentAccountCardBody
                  : l10n.paymentAccountCardUnavailableBody,
              style: theme.textTheme.bodyMedium,
            ),
            if (account.isTest) ...[
              const SizedBox(height: 12),
              Text(
                l10n.paymentAccountTestCardHint(_stripeTestCard),
                style: theme.textTheme.bodySmall,
              ),
            ],
            for (final checkout in account.pendingCheckouts) ...[
              const Divider(height: 32),
              Text(
                checkout.kind == 'card_update'
                    ? l10n.paymentAccountUnfinishedCardUpdate
                    : l10n.paymentAccountUnfinishedCheckout(checkout.planCode),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(l10n.paymentAccountPendingHint),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: ValueKey('qa.payment.check_status.${checkout.id}'),
                    onPressed: busy ? null : () => onCheck(checkout),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.paymentAccountCheckStatus),
                  ),
                  FilledButton.icon(
                    key: ValueKey('qa.payment.resume_checkout.${checkout.id}'),
                    onPressed: busy || !account.cardAvailable
                        ? null
                        : () => onResume(checkout),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.paymentAccountResumeCheckout),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
