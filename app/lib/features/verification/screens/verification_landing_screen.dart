import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class VerificationLandingScreen extends ConsumerWidget {
  const VerificationLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Government Verification')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Paused',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aadhaar/PAN verification is temporarily paused.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You can continue using the app without government ID verification for now.',
                    ),
                    const Spacer(),
                    GlassButton(
                      label: 'Got it',
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
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
