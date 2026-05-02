import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import 'auth_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CrystalScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight - 24;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minHeight < 0 ? 0 : minHeight,
                    maxWidth: AppTheme.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PremiumBadge(),
                            const SizedBox(height: 18),
                            Text(
                              'Verified people.\nReal chemistry.',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1.02,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Skip the guessing. Meet safety-checked singles '
                              'who are ready for intentional dating.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.32,
                                    letterSpacing: 0.05,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: _VerifiedMembersCard(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 86),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassButton(
                              label: 'Create Account — It’s Free',
                              icon: Icons.person_add_alt_1_rounded,
                              shinyEffect: true,
                              textColor: AppTheme.textDark,
                              fontWeight: FontWeight.w900,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            _SignInMagnetButton(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                'By continuing, you agree to our Terms and '
                                'Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      height: 1.35,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF1D1302).withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: AppTheme.pureGoldHighlight.withValues(alpha: 0.44),
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.pureGoldBright.withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 18,
          color: AppTheme.pureGoldBright,
        ),
        const SizedBox(width: 7),
        Text(
          'Most loved premium dating app',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.12,
          ),
        ),
      ],
    ),
  );
}

class _VerifiedMembersCard extends StatelessWidget {
  const _VerifiedMembersCard();

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(24),
    backgroundColor: const Color(0xFF1A1204).withValues(alpha: 0.24),
    border: Border.all(
      color: AppTheme.pureGoldHighlight.withValues(alpha: 0.34),
    ),
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: AppTheme.pureGoldBright.withValues(alpha: 0.14),
        blurRadius: 24,
        offset: const Offset(0, 4),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.pureGoldHighlight.withValues(alpha: 0.96),
                    AppTheme.pureGoldBright.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                color: AppTheme.pureGoldInk,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '120k+ verified members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nearby, active, and safety checked',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const _LivePulseBadge(),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _TrustChip(
                icon: Icons.verified_rounded,
                label: 'Verified',
              ),
            ),
            SizedBox(width: 9),
            Expanded(
              child: _TrustChip(icon: Icons.shield_rounded, label: 'Protected'),
            ),
            SizedBox(width: 9),
            Expanded(
              child: _TrustChip(icon: Icons.favorite_rounded, label: 'Serious'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LivePulseBadge extends StatelessWidget {
  const _LivePulseBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.safetyGreen.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppTheme.safetyGreen.withValues(alpha: 0.42)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 7,
          width: 7,
          decoration: const BoxDecoration(
            color: AppTheme.safetyGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'LIVE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _SignInMagnetButton extends StatelessWidget {
  const _SignInMagnetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 62,
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.72),
            AppTheme.pureGoldHighlight.withValues(alpha: 0.88),
            AppTheme.pureGoldBright.withValues(alpha: 0.52),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pureGoldBright.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3A2707).withValues(alpha: 0.94),
              const Color(0xFF7E570C).withValues(alpha: 0.9),
              const Color(0xFF2B1A03).withValues(alpha: 0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: AppTheme.pureGoldHighlight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Already a member?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Sign in and continue your story',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.pureGoldHighlight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: AppTheme.pureGoldBright),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    ),
  );
}
