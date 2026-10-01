import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../platform/checkout_launcher.dart';
import '../providers/subscription_provider.dart';
import 'payment_account_card.dart';

/// Membership: current plan, auto-renew control, plan catalog and payment
/// history. Plans are bought with a card on the provider's hosted checkout
/// and renew automatically until the member turns auto-renew off.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _billingCycle = 'monthly';
  bool _recoveringCheckout = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(subscriptionProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final subscription = state.subscription;
    final scheme = Theme.of(context).colorScheme;
    final paidPlans = state.plans.where((plan) => !plan.isFree).toList();
    final popularId = paidPlans.length >= 3
        ? paidPlans[paidPlans.length ~/ 2].id
        : (paidPlans.isNotEmpty ? paidPlans.last.id : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: ref.read(subscriptionProvider.notifier).load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (state.account != null) ...[
                  PaymentAccountCard(
                    account: state.account!,
                    busy:
                        _recoveringCheckout ||
                        state.isLoading ||
                        state.checkoutPlanId != null ||
                        state.isUpdatingCard,
                    onResume: (checkout) =>
                        _recoverCheckout(checkout, reopen: true),
                    onCheck: (checkout) =>
                        _recoverCheckout(checkout, reopen: false),
                  ),
                  const SizedBox(height: 16),
                ],
                _CurrentPlanHero(
                  subscription: subscription,
                  isBusy: state.isUpdatingAutoRenew,
                  isUpdatingCard: state.isUpdatingCard,
                  onAutoRenewChanged: _toggleAutoRenew,
                  onUpdateCard: _updateCard,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(message: state.error!),
                ],
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Choose your plan',
                  trailing: _CycleToggle(
                    value: _billingCycle,
                    onChanged: (value) => setState(() => _billingCycle = value),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay by card. Renews automatically every '
                  '${_billingCycle == 'yearly' ? 'year' : 'month'} until you '
                  'turn it off.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isLoading && state.plans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    ),
                  )
                else if (paidPlans.isEmpty)
                  const Text('No plans are on sale right now.')
                else
                  for (final plan in paidPlans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: plan,
                        billingCycle: _billingCycle,
                        isPopular: plan.id == popularId,
                        isCurrent:
                            subscription != null &&
                            subscription.isLive &&
                            subscription.planId == plan.id,
                        hasOtherLivePlan:
                            subscription != null &&
                            subscription.isPaid &&
                            subscription.isLive &&
                            subscription.planId != plan.id,
                        isBusy:
                            state.checkoutPlanId == plan.id ||
                            state.changingPlanId == plan.id,
                        canCheckout:
                            state.account?.cardAvailable == true &&
                            !state.isLoading &&
                            !_recoveringCheckout &&
                            state.checkoutPlanId == null &&
                            state.changingPlanId == null &&
                            !state.isUpdatingCard,
                        canSwitch:
                            subscription != null &&
                            subscription.isPaid &&
                            subscription.status == 'active' &&
                            subscription.provider != 'local',
                        onSubscribe: () => _subscribe(plan),
                        onSwitch: () => _switchPlan(plan),
                      ),
                    ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Payments'),
                const SizedBox(height: 8),
                if (state.payments.isEmpty)
                  Text(
                    'No card payments yet.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                else
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < state.payments.length; i++) ...[
                          _PaymentRow(payment: state.payments[i]),
                          if (i < state.payments.length - 1)
                            Divider(height: 1, color: scheme.outlineVariant),
                        ],
                      ],
                    ),
                  ),
                if (kDebugMode &&
                    subscription != null &&
                    subscription.isPaid &&
                    subscription.provider == 'sandbox') ...[
                  const SizedBox(height: 20),
                  _SandboxControls(
                    onEvent: (event) => ref
                        .read(subscriptionProvider.notifier)
                        .simulateSandbox(event),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Your plan renews automatically at the end of each billing '
                  'period. Turn off auto-renew at any time; you keep your '
                  'benefits until the period ends. Card details are handled '
                  'by the payment provider and never stored in the app.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switchPlan(SubscriptionPlan plan) async {
    final current = ref.read(subscriptionProvider).subscription;
    if (current == null) {
      return;
    }
    final newPrice = plan.priceFor(_billingCycle);
    final per = _billingCycle == 'yearly' ? 'year' : 'month';
    final perDayNew = newPrice / (_billingCycle == 'yearly' ? 365 : 30);
    final perDayOld =
        current.amount / (current.billingCycle == 'yearly' ? 365 : 30);
    final upgrade = perDayNew > perDayOld;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Switch to ${plan.name}?'),
        content: Text(
          upgrade
              ? 'Your card is charged now for the difference for the rest of '
                    'this period, then ${_money(newPrice, 'INR')} per $per '
                    'from the next renewal.'
              : 'Your plan changes now. Unused time on ${current.planName} is '
                    'credited against your next renewal, then you pay '
                    '${_money(newPrice, 'INR')} per $per.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(upgrade ? 'Upgrade' : 'Switch plan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final ok = await ref
        .read(subscriptionProvider.notifier)
        .changePlan(plan: plan, billingCycle: _billingCycle);
    if (!mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("You're on ${plan.name} now.")));
  }

  Future<void> _updateCard() async {
    final notifier = ref.read(subscriptionProvider.notifier);
    final checkout = await notifier.startCardUpdate();
    if (checkout == null || !mounted) {
      return;
    }
    final done = await launchHostedCheckout(
      context,
      checkout: checkout,
      title: 'your card',
    );
    if (!mounted) {
      return;
    }
    final outcome = await notifier.awaitCheckout(
      checkout,
      timeout: done == true
          ? const Duration(seconds: 45)
          : const Duration(seconds: 6),
    );
    notifier.finishCardUpdate();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome == CheckoutOutcome.completed
              ? 'Your card has been updated.'
              : outcome == CheckoutOutcome.pending
              ? 'Card update not confirmed yet. '
                    'Check its status before trying again.'
              : 'This card update session has ended. '
                    'Refresh to see your current card.',
        ),
      ),
    );
  }

  Future<void> _toggleAutoRenew(bool enabled) async {
    final subscription = ref.read(subscriptionProvider).subscription;
    if (subscription == null) {
      return;
    }
    if (!enabled) {
      final endLabel = subscription.currentPeriodEnd == null
          ? 'the end of the current period'
          : _dateLabel(subscription.currentPeriodEnd!);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Turn off auto-renew?'),
          content: Text(
            'Your ${subscription.planName} benefits stay active until '
            '$endLabel. After that you move to the Free plan and your card '
            'is not charged again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep renewing'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Turn off'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    final ok = await ref
        .read(subscriptionProvider.notifier)
        .setAutoRenew(enabled: enabled);
    if (!mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Auto-renew is back on.'
              : 'Auto-renew is off. Your benefits continue until the period '
                    'ends.',
        ),
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final testMode = ref.read(subscriptionProvider).account?.isTest == true;
    final price = _money(plan.priceFor(_billingCycle), 'INR');
    final per = _billingCycle == 'yearly' ? 'year' : 'month';
    final chargeLabel = testMode ? 'simulated' : 'charged to your card';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Subscribe to ${plan.name}'),
        content: Text(
          '${testMode ? 'Test checkout only — no real charge. ' : ''}'
          '$price per $per, $chargeLabel and renewed automatically '
          'until you turn auto-renew off. You will enter your card on the '
          "payment provider's secure page.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue to card'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final notifier = ref.read(subscriptionProvider.notifier);
    final checkout = await notifier.startCheckout(
      plan: plan,
      billingCycle: _billingCycle,
    );
    if (checkout == null || !mounted) {
      return;
    }

    final paid = await launchHostedCheckout(
      context,
      checkout: checkout,
      title: plan.name,
    );
    if (!mounted) {
      return;
    }
    final outcome = await notifier.awaitCheckout(
      checkout,
      timeout: paid == true
          ? const Duration(seconds: 45)
          : const Duration(seconds: 6),
    );
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case CheckoutOutcome.completed:
        await _celebrate(plan);
      case CheckoutOutcome.pending:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment is still being confirmed. Pull to refresh in a moment.',
            ),
          ),
        );
      case CheckoutOutcome.cancelled:
      case CheckoutOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This checkout session has ended. '
              'Refresh your payment history before trying again.',
            ),
          ),
        );
    }
  }

  Future<void> _recoverCheckout(
    BillingCheckout checkout, {
    required bool reopen,
  }) async {
    if (_recoveringCheckout) {
      return;
    }
    setState(() => _recoveringCheckout = true);
    final notifier = ref.read(subscriptionProvider.notifier);
    try {
      // Re-read the account before opening a stored session: another tab may
      // already have paid, replaced the card or allowed the session to expire.
      await notifier.load();
      if (!mounted) {
        return;
      }
      final account = ref.read(subscriptionProvider).account;
      final pending = account?.pendingCheckouts
          .where((item) => item.id == checkout.id)
          .firstOrNull;
      if (account == null || pending == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              account == null
                  ? 'Unable to check the payment account. Please retry.'
                  : 'Payment account refreshed. '
                        'This checkout is no longer open.',
            ),
          ),
        );
        return;
      }
      bool? returned;
      if (reopen) {
        returned = await launchHostedCheckout(
          context,
          checkout: pending,
          title: pending.kind == 'card_update' ? 'your card' : pending.planCode,
        );
        if (!mounted) {
          return;
        }
      }
      final outcome = await notifier.awaitCheckout(
        pending,
        timeout: Duration(seconds: returned == true ? 45 : 6),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outcome == CheckoutOutcome.completed
                ? 'Confirmed. Your payment account is up to date.'
                : outcome == CheckoutOutcome.pending
                ? 'Confirmation is still pending. You can check again here.'
                : 'This checkout session has ended. '
                      'Review your payment history before starting another.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _recoveringCheckout = false);
      }
    }
  }

  Future<void> _celebrate(SubscriptionPlan plan) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(sheetContext).colorScheme.primary,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 40,
                color: Theme.of(sheetContext).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're ${plan.name} now",
              textAlign: TextAlign.center,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              ref.read(subscriptionProvider).account?.isTest == true
                  ? 'Test payment confirmed; no real money was charged. '
                        'Your test plan renews automatically. '
                        'Manage auto-renew any time from this screen.'
                  : 'Payment confirmed. Your plan renews automatically. '
                        'Manage auto-renew any time from this screen.',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Start exploring',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _CurrentPlanHero extends StatelessWidget {
  const _CurrentPlanHero({
    required this.subscription,
    required this.isBusy,
    required this.isUpdatingCard,
    required this.onAutoRenewChanged,
    required this.onUpdateCard,
  });

  final UserSubscription? subscription;
  final bool isBusy;
  final bool isUpdatingCard;
  final ValueChanged<bool> onAutoRenewChanged;
  final VoidCallback onUpdateCard;

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final paid = sub != null && sub.isPaid && sub.isLive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    paid ? 'Your membership' : 'Your plan',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (sub != null) _StatusChip(subscription: sub),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GradientText(
                    sub?.planName ?? 'Free',
                    gradient: paid
                        ? LinearGradient(
                            colors: [scheme.primary, scheme.primary],
                          )
                        : LinearGradient(
                            colors: [scheme.onSurface, scheme.onSurface],
                          ),
                    style:
                        theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ) ??
                        const TextStyle(fontSize: 36),
                  ),
                ),
                if (paid)
                  Text(
                    '${_money(sub.amount, sub.currency)}'
                    '/${sub.billingCycle == 'yearly' ? 'yr' : 'mo'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (paid) ...[
              Row(
                children: [
                  Expanded(
                    child: _HeroLine(
                      icon: Icons.credit_card,
                      text: sub.hasCard
                          ? '${_brandLabel(sub.cardBrand)} •••• '
                                '${sub.cardLast4}'
                          : 'Card on file with the payment provider',
                    ),
                  ),
                  if (sub.provider != 'local')
                    TextButton(
                      onPressed: isUpdatingCard ? null : onUpdateCard,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        foregroundColor: scheme.primary,
                      ),
                      child: Text(isUpdatingCard ? 'Opening…' : 'Update card'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _HeroLine(
                icon: sub.autoRenew ? Icons.autorenew : Icons.event_busy,
                text: _renewalLine(sub),
                emphasis: sub.isPastDue,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outlineVariant),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Auto-renew',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  sub.autoRenew
                      ? 'Charged automatically each period.'
                      : 'Off. Benefits end with the current period.',
                  style: const TextStyle(fontSize: 12),
                ),
                activeThumbColor: scheme.primary,
                value: sub.autoRenew,
                onChanged: isBusy ? null : onAutoRenewChanged,
              ),
            ] else
              Text(
                'Unlock more likes, messages and spotlight with a plan below. '
                'Pay by card, cancel any time.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
          ],
        ),
      ),
    );
  }

  String _renewalLine(UserSubscription sub) {
    final end = sub.currentPeriodEnd ?? sub.nextBillingDate;
    final when = end == null ? 'soon' : _dateLabel(end);
    if (sub.isPastDue) {
      return 'Last payment failed. We will retry your card; benefits stay '
          'active for a few days.';
    }
    if (sub.autoRenew) {
      return 'Renews on $when';
    }
    return 'Ends on $when · auto-renew is off';
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({
    required this.icon,
    required this.text,
    this.emphasis = false,
  });

  final IconData icon;
  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasis ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    late final String label;
    late final Color color;
    if (!sub.isPaid) {
      label = 'Free';
      color = Theme.of(context).colorScheme.secondary;
    } else if (sub.isPastDue) {
      label = 'Payment due';
      color = AppTheme.warning;
    } else if (sub.cancelAtPeriodEnd) {
      label = 'Ending';
      color = AppTheme.warning;
    } else {
      label = 'Active';
      color = AppTheme.successGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

// ── Catalog ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      ?trailing,
    ],
  );
}

class _CycleToggle extends StatelessWidget {
  const _CycleToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final cycle in const ['monthly', 'yearly'])
            GestureDetector(
              onTap: () => onChanged(cycle),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                // Each segment is a full 48pt tap target.
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  color: value == cycle ? scheme.primary : null,
                ),
                child: Text(
                  cycle == 'yearly' ? 'Yearly' : 'Monthly',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: value == cycle
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isPopular,
    required this.isCurrent,
    required this.hasOtherLivePlan,
    required this.isBusy,
    required this.canSwitch,
    required this.canCheckout,
    required this.onSubscribe,
    required this.onSwitch,
  });

  final SubscriptionPlan plan;
  final String billingCycle;
  final bool isPopular;
  final bool isCurrent;
  final bool hasOtherLivePlan;
  final bool isBusy;
  final bool canSwitch;
  final bool canCheckout;
  final VoidCallback onSubscribe;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final price = plan.priceFor(billingCycle);
    final yearlySaving = plan.monthlyPrice > 0 && plan.yearlyPrice > 0
        ? (1 - plan.yearlyPrice / (plan.monthlyPrice * 12)) * 100
        : 0.0;
    final accent = scheme.primary;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      border: isPopular || isCurrent
          ? Border.all(color: accent, width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular || isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.successGreen
                                : scheme.primary,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          child: Text(
                            isCurrent ? 'YOUR PLAN' : 'MOST POPULAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: isCurrent
                                  ? Colors.white
                                  : scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      plan.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(price, 'INR'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    billingCycle == 'yearly' ? 'per year' : 'per month',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (billingCycle == 'yearly' && yearlySaving >= 1)
                    Text(
                      'Save ${yearlySaving.round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.successGreen,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuotaPill(
                icon: Icons.favorite,
                label: _quotaLabel(plan.likesPerDay, 'likes'),
              ),
              _QuotaPill(
                icon: Icons.chat_bubble,
                label: _quotaLabel(plan.messagesPerDay, 'messages'),
              ),
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _featureLabel(feature),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          GlassButton(
            label: isCurrent
                ? 'Your current plan'
                : isBusy
                ? (hasOtherLivePlan ? 'Switching…' : 'Opening secure checkout…')
                : hasOtherLivePlan
                ? 'Switch to ${plan.name}'
                : 'Subscribe with card',
            icon: isCurrent
                ? Icons.check
                : hasOtherLivePlan
                ? Icons.swap_horiz
                : Icons.credit_card,
            isLoading: isBusy,
            onPressed: isCurrent || isBusy || !canCheckout
                ? null
                : hasOtherLivePlan
                ? (canSwitch ? onSwitch : null)
                : onSubscribe,
          ),
          if (hasOtherLivePlan && !isCurrent && !canSwitch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Settle the outstanding payment on your current plan before '
                'switching.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuotaPill extends StatelessWidget {
  const _QuotaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payments ─────────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final BillingPayment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    late final Color color;
    late final IconData icon;
    late final String label;
    if (payment.chargedBack) {
      color = scheme.error;
      icon = Icons.gavel;
      label = 'Chargeback';
    } else if (payment.disputed) {
      color = AppTheme.warning;
      icon = Icons.gavel;
      label = 'Disputed';
    } else if (payment.refunded) {
      color = scheme.secondary;
      icon = Icons.undo;
      label = payment.status == 'refunded' ? 'Refunded' : 'Partly refunded';
    } else if (payment.failed) {
      color = scheme.error;
      icon = Icons.error_outline;
      label = 'Failed';
    } else if (payment.succeeded) {
      color = AppTheme.successGreen;
      icon = Icons.check_circle_outline;
      label = 'Paid';
    } else {
      color = AppTheme.warning;
      icon = Icons.hourglass_bottom;
      label = 'Pending';
    }
    final reason = switch (payment.billingReason) {
      'subscription_create' => 'First charge',
      'subscription_cycle' => 'Renewal',
      'subscription_update' => 'Plan change',
      'coin_purchase' => 'Coins',
      'local_activation' => 'Local activation',
      _ => payment.paymentMethod == 'card' ? 'Card payment' : 'Payment',
    };
    final card = payment.cardLast4.isNotEmpty
        ? ' · ${_brandLabel(payment.cardBrand)} •••• ${payment.cardLast4}'
        : '';
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        '$reason$card',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: Text(
        payment.failed && payment.failureReason.isNotEmpty
            ? '${_dateLabel(payment.createdAt)} · ${payment.failureReason}'
            : _dateLabel(payment.createdAt),
        style: TextStyle(fontSize: 12, color: muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(payment.amount, payment.currency),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: payment.refunded ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SandboxControls extends StatelessWidget {
  const _SandboxControls({required this.onEvent});

  final Future<bool> Function(String event) onEvent;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SANDBOX · advance the renewal clock',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const {
              'renewal_paid': 'Renewal paid',
              'renewal_failed': 'Renewal fails',
              'period_end': 'Reach period end',
              'refund': 'Refund last charge',
            }.entries)
              OutlinedButton(
                onPressed: () => onEvent(entry.key),
                child: Text(entry.value),
              ),
          ],
        ),
      ],
    ),
  );
}

// ── Formatting ───────────────────────────────────────────────────────────────

String _money(double amount, String currency) {
  final symbol = switch (currency.toUpperCase()) {
    'INR' => '₹',
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    _ => '${currency.toUpperCase()} ',
  };
  final text = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return '$symbol$text';
}

String _brandLabel(String brand) {
  final value = brand.trim();
  if (value.isEmpty) {
    return 'Card';
  }
  return value[0].toUpperCase() + value.substring(1);
}

String _featureLabel(String feature) => feature
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join(' ');

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _quotaLabel(int value, String noun) =>
    value < 0 ? 'Unlimited $noun' : '$value $noun/day';
