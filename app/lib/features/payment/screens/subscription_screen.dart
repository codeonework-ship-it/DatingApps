import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../platform/checkout_launcher.dart';
import '../providers/subscription_provider.dart';
import 'payment_account_card.dart';
import 'payment_l10n.dart';

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
    final l10n = AppLocalizations.of(context);
    final paidPlans = state.plans.where((plan) => !plan.isFree).toList();
    final popularId = paidPlans.length >= 3
        ? paidPlans[paidPlans.length ~/ 2].id
        : (paidPlans.isNotEmpty ? paidPlans.last.id : null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membershipTitle)),
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
                  _InlineError(
                    message: paymentErrorText(
                      l10n,
                      state.errorCode,
                      state.error!,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _SectionTitle(
                  title: l10n.membershipChooseYourPlan,
                  trailing: _CycleToggle(
                    value: _billingCycle,
                    onChanged: (value) => setState(() => _billingCycle = value),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _billingCycle == 'yearly'
                      ? l10n.membershipCycleNoteYearly
                      : l10n.membershipCycleNoteMonthly,
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
                  Text(l10n.membershipNoPlansOnSale)
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
                _SectionTitle(title: l10n.membershipPaymentsTitle),
                const SizedBox(height: 8),
                if (state.payments.isEmpty)
                  Text(
                    l10n.membershipNoCardPayments,
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
                  l10n.membershipFooterNote,
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
    final l10n = AppLocalizations.of(context);
    final newPrice = plan.priceFor(_billingCycle);
    final yearly = _billingCycle == 'yearly';
    final price = paymentMoney(context, newPrice, 'INR');
    final perDayNew = newPrice / (_billingCycle == 'yearly' ? 365 : 30);
    final perDayOld =
        current.amount / (current.billingCycle == 'yearly' ? 365 : 30);
    final upgrade = perDayNew > perDayOld;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.membershipSwitchTitle(plan.name)),
        content: Text(
          upgrade
              ? (yearly
                    ? l10n.membershipSwitchUpgradeBodyYearly(price)
                    : l10n.membershipSwitchUpgradeBodyMonthly(price))
              : (yearly
                    ? l10n.membershipSwitchDowngradeBodyYearly(
                        current.planName,
                        price,
                      )
                    : l10n.membershipSwitchDowngradeBodyMonthly(
                        current.planName,
                        price,
                      )),
        ),
        actions: [
          TextButton(
            key: const ValueKey('qa.membership.switch.not_now'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.membershipNotNow),
          ),
          FilledButton(
            key: const ValueKey('qa.membership.switch.confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              upgrade ? l10n.membershipUpgrade : l10n.membershipSwitchPlan,
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.membershipSwitchedSnack(plan.name))),
    );
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
      title: AppLocalizations.of(context).membershipCheckoutTitleCard,
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome == CheckoutOutcome.completed
              ? l10n.membershipCardUpdated
              : outcome == CheckoutOutcome.pending
              ? l10n.membershipCardUpdatePending
              : l10n.membershipCardUpdateEnded,
        ),
      ),
    );
  }

  Future<void> _toggleAutoRenew(bool enabled) async {
    final subscription = ref.read(subscriptionProvider).subscription;
    if (subscription == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      final periodEnd = subscription.currentPeriodEnd;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.membershipAutoRenewOffTitle),
          content: Text(
            periodEnd == null
                ? l10n.membershipAutoRenewOffBodyPeriodEnd(
                    subscription.planName,
                  )
                : l10n.membershipAutoRenewOffBodyDate(
                    subscription.planName,
                    paymentDate(context, periodEnd),
                  ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('qa.membership.auto_renew_off.keep'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.membershipKeepRenewing),
            ),
            FilledButton(
              key: const ValueKey('qa.membership.auto_renew_off.confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.membershipTurnOff),
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
              ? l10n.membershipAutoRenewBackOn
              : l10n.membershipAutoRenewNowOff,
        ),
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final l10n = AppLocalizations.of(context);
    final testMode = ref.read(subscriptionProvider).account?.isTest == true;
    final price = paymentMoney(context, plan.priceFor(_billingCycle), 'INR');
    final yearly = _billingCycle == 'yearly';
    final body = testMode
        ? (yearly
              ? l10n.membershipSubscribeBodyTestYearly(price)
              : l10n.membershipSubscribeBodyTestMonthly(price))
        : (yearly
              ? l10n.membershipSubscribeBodyYearly(price)
              : l10n.membershipSubscribeBodyMonthly(price));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.membershipSubscribeTitle(plan.name)),
        content: Text(body),
        actions: [
          TextButton(
            key: const ValueKey('qa.membership.subscribe.not_now'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.membershipNotNow),
          ),
          FilledButton(
            key: const ValueKey('qa.membership.subscribe.continue'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.membershipContinueToCard),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.paymentStillConfirming)));
      case CheckoutOutcome.cancelled:
      case CheckoutOutcome.failed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.membershipCheckoutEnded)));
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
      final l10n = AppLocalizations.of(context);
      final account = ref.read(subscriptionProvider).account;
      final pending = account?.pendingCheckouts
          .where((item) => item.id == checkout.id)
          .firstOrNull;
      if (account == null || pending == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              account == null
                  ? l10n.membershipRecoverAccountUnavailable
                  : l10n.membershipRecoverCheckoutClosed,
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
          title: pending.kind == 'card_update'
              ? l10n.membershipCheckoutTitleCard
              : pending.planCode,
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
                ? l10n.membershipRecoverConfirmed
                : outcome == CheckoutOutcome.pending
                ? l10n.membershipRecoverPending
                : l10n.membershipRecoverEnded,
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
    // Longer languages (German) need more than the default 9/16 height on a
    // phone; size to the content and scroll if it must.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SingleChildScrollView(
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
              AppLocalizations.of(
                sheetContext,
              ).membershipCelebrateTitle(plan.name),
              textAlign: TextAlign.center,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              ref.read(subscriptionProvider).account?.isTest == true
                  ? AppLocalizations.of(
                      sheetContext,
                    ).membershipCelebrateBodyTest
                  : AppLocalizations.of(sheetContext).membershipCelebrateBody,
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GlassButton(
              key: const ValueKey('qa.membership.start_exploring'),
              label: AppLocalizations.of(sheetContext).membershipStartExploring,
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
    final l10n = AppLocalizations.of(context);

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
                    paid
                        ? l10n.membershipYourMembership
                        : l10n.membershipYourPlan,
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
                    sub?.planName ?? l10n.membershipFreePlanName,
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
                    sub.billingCycle == 'yearly'
                        ? l10n.membershipPricePerYearShort(
                            paymentMoney(context, sub.amount, sub.currency),
                          )
                        : l10n.membershipPricePerMonthShort(
                            paymentMoney(context, sub.amount, sub.currency),
                          ),
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
                          ? '${_brandLabel(l10n, sub.cardBrand)} •••• '
                                '${sub.cardLast4}'
                          : l10n.membershipCardOnFile,
                    ),
                  ),
                  if (sub.provider != 'local')
                    TextButton(
                      key: const ValueKey('qa.membership.update_card'),
                      onPressed: isUpdatingCard ? null : onUpdateCard,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        foregroundColor: scheme.primary,
                      ),
                      child: Text(
                        isUpdatingCard
                            ? l10n.paymentOpening
                            : l10n.membershipUpdateCard,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _HeroLine(
                icon: sub.autoRenew ? Icons.autorenew : Icons.event_busy,
                text: _renewalLine(context, l10n, sub),
                emphasis: sub.isPastDue,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outlineVariant),
              SwitchListTile.adaptive(
                key: const ValueKey('qa.membership.auto_renew'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.membershipAutoRenew,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  sub.autoRenew
                      ? l10n.membershipAutoRenewOnSubtitle
                      : l10n.membershipAutoRenewOffSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                activeThumbColor: scheme.primary,
                value: sub.autoRenew,
                onChanged: isBusy ? null : onAutoRenewChanged,
              ),
            ] else
              Text(
                l10n.membershipFreeHeroBody,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
          ],
        ),
      ),
    );
  }

  String _renewalLine(
    BuildContext context,
    AppLocalizations l10n,
    UserSubscription sub,
  ) {
    final end = sub.currentPeriodEnd ?? sub.nextBillingDate;
    if (sub.isPastDue) {
      return l10n.membershipLastPaymentFailed;
    }
    if (end == null) {
      return sub.autoRenew
          ? l10n.membershipRenewsSoon
          : l10n.membershipEndsSoon;
    }
    final when = paymentDate(context, end);
    return sub.autoRenew
        ? l10n.membershipRenewsOn(when)
        : l10n.membershipEndsOn(when);
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
    final l10n = AppLocalizations.of(context);
    late final String label;
    late final Color color;
    if (!sub.isPaid) {
      label = l10n.membershipStatusFree;
      color = Theme.of(context).colorScheme.secondary;
    } else if (sub.isPastDue) {
      label = l10n.membershipStatusPaymentDue;
      color = AppTheme.warning;
    } else if (sub.cancelAtPeriodEnd) {
      label = l10n.membershipStatusEnding;
      color = AppTheme.warning;
    } else {
      label = l10n.membershipStatusActive;
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
              key: ValueKey('qa.membership.cycle.$cycle'),
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
                  cycle == 'yearly'
                      ? AppLocalizations.of(context).membershipCycleYearly
                      : AppLocalizations.of(context).membershipCycleMonthly,
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
    final l10n = AppLocalizations.of(context);
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
                            isCurrent
                                ? l10n.membershipBadgeYourPlan
                                : l10n.membershipBadgeMostPopular,
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
                    paymentMoney(context, price, 'INR'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    billingCycle == 'yearly'
                        ? l10n.membershipPerYear
                        : l10n.membershipPerMonth,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (billingCycle == 'yearly' && yearlySaving >= 1)
                    Text(
                      l10n.membershipSavePercent(yearlySaving.round()),
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
                label: plan.likesPerDay < 0
                    ? l10n.membershipQuotaUnlimitedLikes
                    : l10n.membershipQuotaLikesPerDay(plan.likesPerDay),
              ),
              _QuotaPill(
                icon: Icons.chat_bubble,
                label: plan.messagesPerDay < 0
                    ? l10n.membershipQuotaUnlimitedMessages
                    : l10n.membershipQuotaMessagesPerDay(plan.messagesPerDay),
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
            key: ValueKey('qa.membership.plan.${plan.id}'),
            label: isCurrent
                ? l10n.membershipYourCurrentPlan
                : isBusy
                ? (hasOtherLivePlan
                      ? l10n.membershipSwitching
                      : l10n.membershipOpeningSecureCheckout)
                : hasOtherLivePlan
                ? l10n.membershipSwitchToPlan(plan.name)
                : l10n.membershipSubscribeWithCard,
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
                l10n.membershipSettleBeforeSwitch,
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
    final l10n = AppLocalizations.of(context);
    final muted = scheme.onSurfaceVariant;
    late final Color color;
    late final IconData icon;
    late final String label;
    if (payment.chargedBack) {
      color = scheme.error;
      icon = Icons.gavel;
      label = l10n.membershipPaymentChargeback;
    } else if (payment.disputed) {
      color = AppTheme.warning;
      icon = Icons.gavel;
      label = l10n.membershipPaymentDisputed;
    } else if (payment.refunded) {
      color = scheme.secondary;
      icon = Icons.undo;
      label = payment.status == 'refunded'
          ? l10n.membershipPaymentRefunded
          : l10n.membershipPaymentPartlyRefunded;
    } else if (payment.failed) {
      color = scheme.error;
      icon = Icons.error_outline;
      label = l10n.membershipPaymentFailed;
    } else if (payment.succeeded) {
      color = AppTheme.successGreen;
      icon = Icons.check_circle_outline;
      label = l10n.membershipPaymentPaid;
    } else {
      color = AppTheme.warning;
      icon = Icons.hourglass_bottom;
      label = l10n.membershipPaymentPending;
    }
    final reason = switch (payment.billingReason) {
      'subscription_create' => l10n.membershipPaymentReasonFirstCharge,
      'subscription_cycle' => l10n.membershipPaymentReasonRenewal,
      'subscription_update' => l10n.membershipPaymentReasonPlanChange,
      'coin_purchase' => l10n.membershipPaymentReasonCoins,
      'local_activation' => l10n.membershipPaymentReasonLocalActivation,
      _ =>
        payment.paymentMethod == 'card'
            ? l10n.membershipPaymentReasonCard
            : l10n.membershipPaymentReasonOther,
    };
    final card = payment.cardLast4.isNotEmpty
        ? ' · ${_brandLabel(l10n, payment.cardBrand)} •••• ${payment.cardLast4}'
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
            ? '${paymentDate(context, payment.createdAt)} · '
                  '${payment.failureReason}'
            : paymentDate(context, payment.createdAt),
        style: TextStyle(fontSize: 12, color: muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            paymentMoney(context, payment.amount, payment.currency),
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
                key: ValueKey('qa.membership.sandbox.${entry.key}'),
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

String _brandLabel(AppLocalizations l10n, String brand) {
  final value = brand.trim();
  if (value.isEmpty) {
    return l10n.membershipCardBrandFallback;
  }
  return value[0].toUpperCase() + value.substring(1);
}

/// Feature codes come from the server (`profile_boost`) and are shown as-is
/// in title case; they are catalog content, not app copy.
String _featureLabel(String feature) => feature
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join(' ');
