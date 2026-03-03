import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/verification_provider.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(verificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: verification.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.invalidate(verificationNotifierProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                    data: (v) {
                      final status = v.status;
                      if (status == 'verified') {
                        return _state(
                          context,
                          icon: Icons.verified,
                          title: 'Verified',
                          message: 'Your verification is complete.',
                        );
                      }
                      if (status == 'rejected') {
                        return _state(
                          context,
                          icon: Icons.error,
                          title: 'Rejected',
                          message: v.rejectionReason ?? 'Please try again.',
                        );
                      }
                      if (status == 'pending') {
                        return _state(
                          context,
                          icon: Icons.hourglass_top,
                          title: 'Pending',
                          message: 'Review in progress.',
                        );
                      }
                      return _state(
                        context,
                        icon: Icons.info,
                        title: 'Not Started',
                        message: 'Start verification from Settings.',
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
    required String title,
    required String message,
  }) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 72, color: AppTheme.primaryRed),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
    ],
  );
}
