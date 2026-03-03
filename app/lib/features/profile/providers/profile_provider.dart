import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_models.dart';

part 'profile_provider.g.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.preferences,
    this.isLoading = false,
    this.error,
    this.likesCount = 0,
    this.matchesCount = 0,
    this.messagesCount = 0,
  });
  final User? user;
  final Preferences? preferences;
  final bool isLoading;
  final String? error;
  final int likesCount;
  final int matchesCount;
  final int messagesCount;

  ProfileState copyWith({
    User? user,
    Preferences? preferences,
    bool? isLoading,
    String? error,
    int? likesCount,
    int? matchesCount,
    int? messagesCount,
  }) => ProfileState(
    user: user ?? this.user,
    preferences: preferences ?? this.preferences,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    likesCount: likesCount ?? this.likesCount,
    matchesCount: matchesCount ?? this.matchesCount,
    messagesCount: messagesCount ?? this.messagesCount,
  );
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    Future<void>.microtask(_load);
    return const ProfileState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authState = ref.read(authNotifierProvider);
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        final now = DateTime.now();
        final mockUserId =
            authState.userId ?? AppRuntimeConfig.mockFallbackUserId;
        final mockContact = authState.email ?? '+919900000000';
        state = state.copyWith(
          user: User(
            id: mockUserId,
            phoneNumber: mockContact,
            name: 'You',
            dateOfBirth: DateTime(1996, 5, 22),
            gender: 'F',
            bio: 'Mock profile for local app testing.',
            heightCm: 167,
            education: 'B.Tech',
            profession: 'Software Engineer',
            incomeRange: '15-25L',
            drinking: 'Occasionally',
            smoking: 'No',
            religion: 'Prefer not to say',
            profileCompletion: 100,
            isVerified: true,
            verificationBadge: true,
            createdAt: now.subtract(const Duration(days: 120)),
            lastLogin: now,
            isActive: true,
            isBlocked: false,
            blockedUsers: const <String>[],
            updatedAt: now,
          ),
          preferences: Preferences(
            id: 'mock-pref-001',
            userId: mockUserId,
            seekingGenders: const <String>['M', 'F'],
            minAgeYears: 24,
            maxAgeYears: 35,
            maxDistanceKm: 25,
            minHeightCm: 155,
            maxHeightCm: 190,
            educationFilter: const <String>['Bachelors', 'Masters'],
            seriousOnly: true,
            verifiedOnly: false,
            updatedAt: now,
          ),
          likesCount: 18,
          matchesCount: 2,
          messagesCount: 37,
          isLoading: false,
          error: null,
        );
        return;
      }

      final currentUserId = authState.userId;
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please login to view your profile.',
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      final response = await dio.get<dynamic>(
        '/profile/$currentUserId/summary',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final userRaw =
          (body['user'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final preferencesRaw =
          (body['preferences'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final stats =
          (body['stats'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      if (userRaw.isEmpty) {
        final draftResponse = await dio.get<dynamic>(
          '/profile/$currentUserId/draft',
        );
        final draftBody =
            (draftResponse.data as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final draft =
            (draftBody['draft'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        if (draft.isNotEmpty) {
          final now = DateTime.now();
          final fallbackUser = User(
            id: currentUserId,
            phoneNumber: (draft['phone_number'] ?? authState.email ?? '')
                .toString(),
            name: (draft['name'] ?? 'You').toString(),
            dateOfBirth:
                DateTime.tryParse((draft['date_of_birth'] ?? '').toString()) ??
                DateTime(1996, 1, 1),
            gender: (draft['gender'] ?? 'Prefer not to say').toString(),
            bio: (draft['bio'] ?? '').toString().trim().isEmpty
                ? null
                : draft['bio'].toString(),
            heightCm: _asNullableInt(draft['height_cm']),
            education: _asNullableString(draft['education']),
            profession: _asNullableString(draft['profession']),
            incomeRange: _asNullableString(draft['income_range']),
            drinking: _asNullableString(draft['drinking']),
            smoking: _asNullableString(draft['smoking']),
            religion: _asNullableString(draft['religion']),
            profileCompletion:
                (draft['profile_completion'] as num?)?.toInt() ??
                (draft['profileCompletion'] as num?)?.toInt() ??
                0,
            isVerified: false,
            verificationBadge: false,
            createdAt: now,
            lastLogin: now,
            isActive: true,
            isBlocked: false,
            blockedUsers: const <String>[],
            updatedAt: now,
          );

          final fallbackPrefs = Preferences(
            id: 'draft-pref-$currentUserId',
            userId: currentUserId,
            seekingGenders: ((draft['seeking_genders'] as List?) ?? const [])
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList(),
            minAgeYears: (draft['min_age_years'] as num?)?.toInt() ?? 18,
            maxAgeYears: (draft['max_age_years'] as num?)?.toInt() ?? 60,
            maxDistanceKm: (draft['max_distance_km'] as num?)?.toInt() ?? 50,
            educationFilter: ((draft['education_filter'] as List?) ?? const [])
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList(),
            seriousOnly: draft['serious_only'] == true,
            verifiedOnly: draft['verified_only'] == true,
            updatedAt: now,
          );

          state = state.copyWith(
            user: fallbackUser,
            preferences: fallbackPrefs,
            likesCount: (stats['likes_count'] as num?)?.toInt() ?? 0,
            matchesCount: (stats['matches_count'] as num?)?.toInt() ?? 0,
            messagesCount: (stats['messages_count'] as num?)?.toInt() ?? 0,
            isLoading: false,
            error: null,
          );
          return;
        }

        state = state.copyWith(
          isLoading: false,
          error: 'No profile data found.',
        );
        return;
      }

      state = state.copyWith(
        user: User.fromJson(userRaw),
        preferences: preferencesRaw.isEmpty
            ? null
            : Preferences.fromJson(preferencesRaw),
        likesCount: (stats['likes_count'] as num?)?.toInt() ?? 0,
        matchesCount: (stats['matches_count'] as num?)?.toInt() ?? 0,
        messagesCount: (stats['messages_count'] as num?)?.toInt() ?? 0,
        isLoading: false,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load profile', e, stackTrace);
      final data = e.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Failed to load profile. Please try again.';
      if (_isSupabaseBackedProfileFailure(e, message)) {
        final authState = ref.read(authNotifierProvider);
        final fallbackUserId = authState.userId;
        if (fallbackUserId != null) {
          final now = DateTime.now();
          final fallbackUser =
              state.user ??
              User(
                id: fallbackUserId,
                phoneNumber: authState.email ?? '+919900000000',
                name: 'You',
                dateOfBirth: DateTime(1996, 1, 1),
                gender: 'Prefer not to say',
                profileCompletion: 65,
                isVerified: false,
                verificationBadge: false,
                createdAt: now,
                lastLogin: now,
                isActive: true,
                isBlocked: false,
                blockedUsers: const <String>[],
                updatedAt: now,
              );

          state = state.copyWith(
            user: fallbackUser,
            preferences: state.preferences,
            likesCount: state.likesCount,
            matchesCount: state.matchesCount,
            messagesCount: state.messagesCount,
            isLoading: false,
            error: null,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e, stackTrace) {
      log.error('Failed to load profile', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile. Please try again.',
      );
    }
  }

  Future<void> refresh() async {
    await _load();
  }
}

bool _isSupabaseBackedProfileFailure(DioException error, String message) {
  final lowered = message.toLowerCase();
  if (lowered.contains('supabase') && lowered.contains('request failed')) {
    return true;
  }
  final payload = error.response?.data;
  final payloadText = payload?.toString().toLowerCase() ?? '';
  return payloadText.contains('supabase') &&
      payloadText.contains('request failed');
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asNullableInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value == null) {
    return null;
  }
  return int.tryParse(value.toString());
}
