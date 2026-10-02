import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/verification_provider.dart';
import 'verification_status_screen.dart';
import 'verification_upload_id_screen.dart';

class VerificationLandingScreen extends ConsumerWidget {
  const VerificationLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(verificationNotifierProvider).valueOrNull;
    final submitted = verification?.status == 'pending';
    final verified = verification?.status == 'verified';
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsGovernmentVerificationTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.contentMaxWidth,
                ),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'qa.verification.landing_title',
                        child: Text(
                          l10n.verificationLandingTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.verificationLandingBody),
                      const SizedBox(height: 12),
                      Text(l10n.verificationLandingDisclaimer),
                      const SizedBox(height: 24),
                      if (submitted || verified)
                        GlassButton(
                          label: verified
                              ? l10n.verificationViewVerifiedStatus
                              : l10n.verificationViewReviewStatus,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const VerificationStatusScreen(),
                            ),
                          ),
                        )
                      else
                        Semantics(
                          label: 'qa.verification.landing.start_button',
                          button: true,
                          child: GlassButton(
                            label: l10n.verificationStartButton,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const VerificationUploadIdScreen(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
