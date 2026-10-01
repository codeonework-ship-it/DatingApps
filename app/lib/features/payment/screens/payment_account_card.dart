import 'package:flutter/material.dart';

import '../providers/subscription_provider.dart';

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
    final modeLabel = switch (account.mode) {
      'sandbox' => 'Local test · no real charge',
      'test' => 'Stripe test · no real charge',
      'live' => 'Live payments',
      _ => 'Payments unavailable',
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
                  'Your payment account',
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
              account.name.isEmpty ? 'Signed-in member' : account.name,
              style: theme.textTheme.titleLarge,
            ),
            if (account.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(account.email, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Text(
              account.cardAvailable
                  ? 'Credit or debit card'
                  : 'Card checkout is unavailable',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              account.cardAvailable
                  ? 'Use the hosted checkout to enter your card. Membership '
                        'and payment history belong to this account.'
                  : 'You can keep using your existing account. '
                        'New card payments are not enabled.',
              style: theme.textTheme.bodyMedium,
            ),
            if (account.isTest) ...[
              const SizedBox(height: 12),
              Text(
                'For testing, use 4242 4242 4242 4242, a future expiry '
                'and any three-digit CVC. Use test details only.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            for (final checkout in account.pendingCheckouts) ...[
              const Divider(height: 32),
              Text(
                checkout.kind == 'card_update'
                    ? 'Unfinished card update'
                    : 'Unfinished ${checkout.planCode} checkout',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Check the latest status or continue the same checkout.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => onCheck(checkout),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check status'),
                  ),
                  FilledButton.icon(
                    onPressed: busy || !account.cardAvailable
                        ? null
                        : () => onResume(checkout),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Resume checkout'),
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
