import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';

part 'profile_completion_provider.g.dart';

class ProfileCompletion {
  const ProfileCompletion({
    required this.hasUserRow,
    required this.profileCompletion,
    required this.photoCount,
  });
  final bool hasUserRow;
  final int profileCompletion;
  final int photoCount;

  bool get isComplete =>
      hasUserRow && profileCompletion >= 100 && photoCount >= 2;
}

@riverpod
Future<ProfileCompletion> profileCompletion(ProfileCompletionRef ref) async {
  if (kUseMockAuth) {
    // Return an incomplete profile so the setup wizard is shown for testing.
    return const ProfileCompletion(
      hasUserRow: true,
      profileCompletion: 0,
      photoCount: 0,
    );
  }

  final auth = ref.watch(authNotifierProvider);
  final userId = auth.userId;
  if (userId == null) {
    return const ProfileCompletion(
      hasUserRow: false,
      profileCompletion: 0,
      photoCount: 0,
    );
  }

  try {
    final dio = ref.read(apiClientProvider);
    final workflowResponse = await dio.get<dynamic>(
      '/auth/signup/workflow/$userId',
    );
    final workflow =
        (workflowResponse.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    if (workflow['state'] == 'completed' &&
        workflow['current_activity'] == 'done') {
      return const ProfileCompletion(
        hasUserRow: true,
        profileCompletion: 100,
        photoCount: ValidationConstants.minPhotos,
      );
    }

    final draftResponse = await dio.get<dynamic>('/profile/$userId/draft');
    final draftBody =
        (draftResponse.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final draft =
        (draftBody['draft'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final draftName = (draft['name'] ?? '').toString().trim();
    final draftBio = (draft['bio'] ?? '').toString().trim();
    final draftDob = (draft['date_of_birth'] ?? '').toString().trim();
    final draftPhotos = (draft['photos'] as List?)?.cast<dynamic>() ?? const [];
    final draftCompletionFromServer =
        (draft['profile_completion'] as num?)?.toInt() ??
        (draft['profileCompletion'] as num?)?.toInt() ??
        0;

    var completedSections = 0;
    if (draftName.length >= ValidationConstants.minNameLength) {
      completedSections++;
    }
    if (draftDob.isNotEmpty) {
      completedSections++;
    }
    if (draftBio.length >= ValidationConstants.minBioLength) {
      completedSections++;
    }
    if (draftPhotos.length >= ValidationConstants.minPhotos) {
      completedSections++;
    }

    final fallbackCompletion = ((completedSections / 4) * 100).round();
    final resolvedDraftCompletion = math.max(
      fallbackCompletion,
      draftCompletionFromServer,
    );
    return ProfileCompletion(
      hasUserRow: draft.isNotEmpty,
      profileCompletion: resolvedDraftCompletion,
      photoCount: draftPhotos.length,
    );
  } on DioException {
    rethrow;
  }
}
