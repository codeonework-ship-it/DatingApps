import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class WalletPaymentScreen extends StatelessWidget {
  const WalletPaymentScreen({required this.walletCoins, super.key});

  final int walletCoins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Wallet & Payments'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF4D2),
                    AppTheme.pureGoldBright,
                    AppTheme.crystalGoldSoft,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.crystalGoldSoft.withValues(alpha: 0.34),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.pureGoldHighlight.withValues(alpha: 0.92),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.pureGoldInk,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Glow wallet balance',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.pureGoldInk.withValues(
                                  alpha: 0.76,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$walletCoins coins',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.pureGoldInk,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Instant top-up',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.pureGoldInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Top up once and keep roses, gestures, and premium '
                    'actions ready for every match.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.pureGoldInk.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _HeroStatChip(
                          icon: Icons.flash_on_rounded,
                          label: 'Instant credit',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _HeroStatChip(
                          icon: Icons.verified_user_rounded,
                          label: 'Secure payments',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Payment methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              title: 'Credit Card',
              subtitle: 'Visa, Mastercard, Amex',
              accentColor: AppTheme.trustBlue,
              tag: 'Fastest',
            ),
            const SizedBox(height: 12),
            const _PaymentMethodTile(
              icon: Icons.payment_rounded,
              title: 'Debit Card',
              subtitle: 'Direct bank card payments',
              accentColor: AppTheme.primaryRed,
              tag: 'Reliable',
            ),
            const SizedBox(height: 12),
            const _PaymentMethodTile(
              icon: Icons.qr_code_2_rounded,
              title: 'UPI',
              subtitle: 'Pay using any UPI app',
              accentColor: AppTheme.successGreen,
              tag: 'Popular',
            ),
            const SizedBox(height: 18),
            Text(
              'Popular top-ups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Designed for quick gifting, better intros, '
              'and last-minute boosts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrey,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _CoinPackCard(
                    coins: 25,
                    price: '₹99',
                    label: 'Starter',
                    bonus: 'Perfect for first chats',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _CoinPackCard(
                    coins: 75,
                    price: '₹249',
                    label: 'Most Loved',
                    bonus: '+10 bonus glow coins',
                    isFeatured: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _CoinPackCard(
                    coins: 150,
                    price: '₹449',
                    label: 'Date Night',
                    bonus: 'Best for gifting streaks',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _CoinPackCard(
                    coins: 400,
                    price: '₹999',
                    label: 'VIP Vault',
                    bonus: '+65 bonus glow coins',
                    isFeatured: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String tag;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Colors.white.withValues(alpha: 0.9),
    blur: 12,
    crystalEffect: true,
    borderRadius: BorderRadius.circular(20),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    ),
  );
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.26),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.pureGoldInk, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.pureGoldInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({
    required this.coins,
    required this.price,
    required this.label,
    required this.bonus,
    this.isFeatured = false,
  });

  final int coins;
  final String price;
  final String label;
  final String bonus;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final gradient = isFeatured
        ? const [Color(0xFFFFF0C4), AppTheme.pureGoldBright, Color(0xFFF2B945)]
        : const [Colors.white, Color(0xFFFFF8EB), Color(0xFFF9E0A8)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crystalGoldSoft.withValues(
              alpha: isFeatured ? 0.32 : 0.18,
            ),
            blurRadius: isFeatured ? 20 : 14,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isFeatured
              ? AppTheme.pureGoldHighlight.withValues(alpha: 0.94)
              : AppTheme.crystalGoldSoft.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isFeatured
                      ? Icons.auto_awesome_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppTheme.pureGoldInk,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.pureGoldInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$coins coins',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.pureGoldInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bonus,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.pureGoldInk.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.pureGoldInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Top up',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.pureGoldInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
