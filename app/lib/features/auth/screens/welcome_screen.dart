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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Trusted. Verified.\nReal Connections.',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Built for serious dating with identity checks, privacy '
                'controls, and safety-first messaging.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 24),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TrustChip(
                    icon: Icons.verified_rounded,
                    label: 'Verified Profiles',
                  ),
                  _TrustChip(
                    icon: Icons.shield_outlined,
                    label: 'Safety Controls',
                  ),
                  _TrustChip(
                    icon: Icons.favorite_rounded,
                    label: 'Serious Matches',
                  ),
                ],
              ),
              const Spacer(),
              GlassButton(
                label: 'Create Account',
                icon: Icons.person_add_alt_1_rounded,
                shinyEffect: true,
                textColor: AppTheme.textDark,
                fontWeight: FontWeight.w800,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 19),
                  label: const Text(
                    'I already have an account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.crystalAqua),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );
}
