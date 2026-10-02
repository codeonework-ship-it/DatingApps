import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../platform/checkout_launcher.dart';
import '../providers/subscription_provider.dart';
import '../providers/wallet_provider.dart';
import 'payment_l10n.dart';

/// Wallet: coin balance, coin packs bought by card through the provider's
/// hosted checkout, and the credit history. The balance shown always comes
/// from the backend; a purchase only counts once the provider settles it.
class WalletPaymentScreen extends ConsumerStatefulWidget {
  const WalletPaymentScreen({required this.walletCoins, super.key});

  /// Balance known by the caller, shown until the wallet loads.
  final int walletCoins;

  @override
  ConsumerState<WalletPaymentScreen> createState() =>
      _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends ConsumerState<WalletPaymentScreen> {
  late final AutoDisposeStateNotifierProvider<WalletNotifier, WalletState>
  _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = walletProvider(widget.walletCoins);
    Future<void>.microtask(() => ref.read(_wallet.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_wallet);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    final balance = state.balance ?? widget.walletCoins;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentWalletTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: ref.read(_wallet.notifier).load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (state.paymentMode == 'sandbox' ||
                    state.paymentMode == 'test') ...[
                  _InlineNote(message: l10n.paymentWalletTestNote),
                  const SizedBox(height: 16),
                ],
                _BalanceHero(balance: balance, isLoading: state.isLoading),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  _InlineNote(
                    message: paymentErrorText(
                      l10n,
                      state.errorCode,
                      state.error!,
                    ),
                    isError: true,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.paymentWalletPopularTopUps,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.paymentWalletTopUpsIntro,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 12),
                if (!state.paymentsAvailable)
                  _InlineNote(message: l10n.paymentWalletCardsDisabled)
                else if (state.isLoading && state.packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    ),
                  )
                else if (state.packages.isEmpty)
                  Text(
                    l10n.paymentWalletNoPacks,
                    style: TextStyle(color: muted),
                  )
                else
                  LayoutBuilder(
                    builder: (context, bounds) {
                      final columns = bounds.maxWidth >= 640 ? 3 : 2;
                      final width =
                          (bounds.maxWidth - 12 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var i = 0; i < state.packages.length; i++)
                            SizedBox(
                              width: width,
                              child: _PackageCard(
                                package: state.packages[i],
                                highlight: i == 1,
                                isBusy:
                                    state.buyingPackageId ==
                                    state.packages[i].id,
                                onBuy: () => _buy(state.packages[i]),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.paymentWalletActivity,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (state.purchases.isEmpty)
                  Text(
                    l10n.paymentWalletNoPurchases,
                    style: TextStyle(color: muted),
                  )
                else
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < state.purchases.length; i++) ...[
                          _PurchaseRow(purchase: state.purchases[i]),
                          if (i < state.purchases.length - 1)
                            Divider(height: 1, color: scheme.outlineVariant),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  l10n.paymentWalletFooter,
                  style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(CoinPackage package) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(_wallet.notifier);
    final checkout = await notifier.startCheckout(package);
    if (checkout == null || !mounted) {
      return;
    }
    final paid = await launchHostedCheckout(
      context,
      checkout: checkout,
      title: l10n.paymentCoinCount(package.totalCoins),
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
    final message = switch (outcome) {
      CheckoutOutcome.completed => l10n.paymentCoinsAdded(package.totalCoins),
      CheckoutOutcome.pending => l10n.paymentStillConfirming,
      _ => l10n.paymentWalletCheckoutEnded,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.balance, required this.isLoading});

  final int balance;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              // Coin badge: stays gold in every theme.
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold,
              ),
              child: const Icon(
                Icons.toll_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).paymentWalletBalanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GradientText(
                    AppLocalizations.of(context).paymentCoinCount(balance),
                    gradient: LinearGradient(
                      colors: [scheme.onSurface, scheme.onSurface],
                    ),
                    style:
                        theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ) ??
                        const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.highlight,
    required this.isBusy,
    required this.onBuy,
  });

  final CoinPackage package;
  final bool highlight;
  final bool isBusy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;
    final l10n = AppLocalizations.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      border: highlight ? Border.all(color: accent, width: 1.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.toll_rounded, color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  package.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${package.totalCoins}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          Text(
            package.bonusCoins > 0
                ? l10n.paymentPackCoinsUnitBonus(
                    package.totalCoins,
                    package.bonusCoins,
                  )
                : l10n.paymentPackCoinsUnit(package.totalCoins),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          GlassButton(
            key: ValueKey('qa.wallet.buy.${package.id}'),
            label: isBusy
                ? l10n.paymentOpening
                : paymentMoney(
                    context,
                    package.price,
                    package.currency,
                    alwaysDecimals: true,
                  ),
            icon: Icons.credit_card,
            isLoading: isBusy,
            onPressed: isBusy ? null : onBuy,
          ),
        ],
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.purchase});

  final WalletPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final label = switch (purchase.source) {
      'admin_topup' => l10n.paymentWalletSourceSupport,
      'promo' => l10n.paymentWalletSourcePromo,
      _ => l10n.paymentWalletSourcePurchase,
    };
    final amount = paymentMoney(
      context,
      purchase.amountMinor / 100,
      purchase.currency,
      alwaysDecimals: true,
    );
    final paid = purchase.amountMinor > 0 ? ' · $amount' : '';
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add_circle_outline,
          size: 18,
          color: AppTheme.gold,
        ),
      ),
      title: Text(
        '$label$paid',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: Text(
        paymentDate(context, purchase.createdAt),
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: Text(
        '+${purchase.coins}',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppTheme.successGreen,
        ),
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.secondary;
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
