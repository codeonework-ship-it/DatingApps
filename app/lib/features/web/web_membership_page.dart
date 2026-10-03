import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../payment/providers/subscription_provider.dart';
import '../payment/screens/payment_l10n.dart';

/// Read-only browser surface while the separately owned native checkout is
/// integrated. Never instantiate a native WebView in a web build.
class WebMembershipPage extends ConsumerStatefulWidget {
  const WebMembershipPage({super.key});

  @override
  ConsumerState<WebMembershipPage> createState() => _WebMembershipPageState();
}

class _WebMembershipPageState extends ConsumerState<WebMembershipPage> {
  String _cycle = 'monthly';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(subscriptionProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.webDestMembership)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.webMembershipHeadline,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(l10n.webMembershipIntro),
              const SizedBox(height: 24),
              if (state.subscription != null) ...[
                Text(
                  l10n.webMembershipCurrent(
                    state.subscription!.planLabel(l10n),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  l10n.webMembershipStatus(
                    _statusLabel(l10n, state.subscription!),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'monthly',
                    label: Text(l10n.webMembershipMonthly),
                  ),
                  ButtonSegment(
                    value: 'yearly',
                    label: Text(l10n.webMembershipYearly),
                  ),
                ],
                selected: {_cycle},
                onSelectionChanged: (value) =>
                    setState(() => _cycle = value.first),
              ),
              const SizedBox(height: 24),
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                Text(paymentErrorText(l10n, state.errorCode, state.error!)),
                TextButton(
                  onPressed: () =>
                      ref.read(subscriptionProvider.notifier).load(),
                  child: Text(l10n.commonRetry),
                ),
              ],
              for (final plan in state.plans)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.nameLabel(l10n),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.isFree
                              ? l10n.webMembershipFree
                              : l10n.webMembershipPrice(
                                  paymentMoney(
                                    context,
                                    plan.priceFor(_cycle),
                                    'INR',
                                  ),
                                  _cycle,
                                ),
                        ),
                        const SizedBox(height: 16),
                        for (final feature in plan.features)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $feature'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(l10n.webMembershipFootnote),
            ],
          ),
        ),
      ),
    );
  }
}

/// The membership status in the member's words (same wording as the app's
/// status chip), never the raw server status code.
String _statusLabel(AppLocalizations l10n, UserSubscription sub) {
  if (!sub.isPaid) {
    return l10n.membershipStatusFree;
  }
  if (sub.isPastDue) {
    return l10n.membershipStatusPaymentDue;
  }
  if (sub.cancelAtPeriodEnd) {
    return l10n.membershipStatusEnding;
  }
  return l10n.membershipStatusActive;
}
