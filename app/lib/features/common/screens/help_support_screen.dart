import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & Support')),
    body: PostLoginBackdrop(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _SupportHeader(),
                SizedBox(height: 12),
                _SupportCard(
                  icon: Icons.login_rounded,
                  title: 'Need help with login?',
                  body:
                      'Use a valid email address and request OTP again from the Auth screen.',
                ),
                SizedBox(height: 12),
                _SupportCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Government verification status',
                  body:
                      'Aadhaar/PAN verification is temporarily paused and not required right now. We will enable it in a later release.',
                ),
                SizedBox(height: 12),
                _SupportCard(
                  icon: Icons.report_gmailerrorred_rounded,
                  title: 'Report abuse or harassment',
                  body:
                      'Long press a match card and use Report. Safety reports are stored in Supabase (safety.reports).',
                ),
                SizedBox(height: 12),
                _SupportCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact support',
                  body:
                      'Email: support@verifieddating.app\nExpected response: within 24 hours.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Colors.white.withValues(alpha: 0.8),
    blur: 10,
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We are here to help',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find quick answers or reach out to support for account and safety issues.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
        ),
      ],
    ),
  );
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Colors.white.withValues(alpha: 0.88),
    blur: 10,
    borderRadius: const BorderRadius.all(Radius.circular(18)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.trustBlue.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: AppTheme.trustBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
        ),
      ],
    ),
  );
}
