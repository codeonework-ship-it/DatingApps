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
    return const ProfileCompletion(
      hasUserRow: true,
      profileCompletion: 100,
      photoCount: 2,
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
    final response = await dio.get<dynamic>('/profile/$userId/summary');
    final body =
        (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final found = body['found'] == true;
    final user =
        (body['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final stats =
        (body['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final summaryCompletion =
        (user['profileCompletion'] as num?)?.toInt() ??
        (user['profile_completion'] as num?)?.toInt() ??
        0;
    final summaryPhotoCount =
        (stats['photo_count'] as num?)?.toInt() ??
        (stats['photoCount'] as num?)?.toInt() ??
        0;

    if (found &&
        user.isNotEmpty &&
        summaryCompletion >= 100 &&
        summaryPhotoCount >= 2) {
      return ProfileCompletion(
        hasUserRow: true,
        profileCompletion: summaryCompletion,
        photoCount: summaryPhotoCount,
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
    final resolvedCompletion = math.max(
      summaryCompletion,
      resolvedDraftCompletion,
    );
    final resolvedPhotoCount = math.max(summaryPhotoCount, draftPhotos.length);
    final resolvedHasUserRow = found || user.isNotEmpty || draft.isNotEmpty;

    return ProfileCompletion(
      hasUserRow: resolvedHasUserRow,
      profileCompletion: resolvedCompletion,
      photoCount: resolvedPhotoCount,
    );
  } on DioException {
    // Keep navigation usable when backend profile summary is temporarily unavailable.
    return const ProfileCompletion(
      hasUserRow: true,
      profileCompletion: 100,
      photoCount: 2,
    );
  }
}
