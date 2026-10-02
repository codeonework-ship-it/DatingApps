import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/verification_provider.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(verificationNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationStatusTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: verification.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: TextButton(
                        key: const ValueKey('qa.verification.status.retry'),
                        onPressed: () =>
                            ref.invalidate(verificationNotifierProvider),
                        child: Text(l10n.verificationRetry),
                      ),
                    ),
                    data: (v) {
                      final status = v.status;
                      if (status == 'verified') {
                        return _state(
                          context,
                          icon: Icons.verified,
                          qaId: 'Verified',
                          title: l10n.verificationStatusVerified,
                          message: l10n.verificationStatusVerifiedMessage,
                        );
                      }
                      if (status == 'rejected') {
                        return _state(
                          context,
                          icon: Icons.error,
                          qaId: 'Rejected',
                          title: l10n.verificationStatusRejected,
                          message:
                              v.rejectionReason ??
                              l10n.verificationStatusRejectedFallback,
                        );
                      }
                      if (status == 'pending') {
                        return _state(
                          context,
                          icon: Icons.hourglass_top,
                          qaId: 'Pending',
                          title: l10n.verificationStatusPending,
                          message: l10n.verificationStatusPendingMessage,
                        );
                      }
                      return _state(
                        context,
                        icon: Icons.info,
                        qaId: 'Not Started',
                        title: l10n.verificationStatusNotStarted,
                        message: l10n.verificationStatusNotStartedMessage,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _state(
    BuildContext context, {
    required IconData icon,
    required String qaId,
    required String title,
    required String message,
  }) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      Semantics(
        label: 'qa.verification.status.$qaId',
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
    ],
  );
}
