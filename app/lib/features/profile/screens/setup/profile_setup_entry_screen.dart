import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_photos_screen.dart';
import 'setup_preferences_screen.dart';

/// Entry point for the profile setup flow.
///
/// Checks auth state, loads profile completion status from the Go BFF
/// (`/profile/{userId}/summary` then `/profile/{userId}/draft`), then
/// routes signup users through photos and preferences so account details
/// captured during signup are not requested again.
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
      data: (_) {
        final draft = ref.watch(profileSetupNotifierProvider);
        return draft.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const SetupPhotosScreen(isSetupFlow: true),
          data: _firstMissingSetupStep,
        );
      },
    );
  }

  Widget _firstMissingSetupStep(ProfileDraft draft) {
    if (draft.photos.length < ValidationConstants.minPhotos) {
      return const SetupPhotosScreen(isSetupFlow: true);
    }
    return const SetupPreferencesScreen(isSetupFlow: true);
  }
}
