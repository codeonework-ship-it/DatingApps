import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../providers/profile_completion_provider.dart';
import 'setup_basic_info_screen.dart';

class ProfileSetupEntryScreen extends ConsumerWidget {
  const ProfileSetupEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    if (!auth.isAuthenticated || auth.userId == null) {
      return const SizedBox.shrink();
    }

    final completion = ref.watch(profileCompletionProvider);
    return completion.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileCompletionProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (_) => const SetupBasicInfoScreen(),
    );
  }
}
