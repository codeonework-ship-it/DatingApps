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
        user: User.fromJson(
          _normalizeUserJson(
            userRaw,
            currentUserId: currentUserId,
            fallbackPhone: authState.email ?? '+919900000000',
          ),
        ),
        preferences: preferencesRaw.isEmpty
            ? null
            : Preferences.fromJson(
                _normalizePreferencesJson(
                  preferencesRaw,
                  currentUserId: currentUserId,
                ),
              ),
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
          isLoading: false,
          error: null,
        );
        return;
      }

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

Map<String, dynamic> _normalizeUserJson(
  Map<String, dynamic> raw, {
  required String currentUserId,
  required String fallbackPhone,
}) {
  final now = DateTime.now().toIso8601String();
  final dateOfBirth = _pickString(raw, const ['dateOfBirth', 'date_of_birth']);
  final createdAt = _pickString(raw, const ['createdAt', 'created_at']);
  final lastLogin = _pickString(raw, const ['lastLogin', 'last_login']);
  final updatedAt = _pickString(raw, const ['updatedAt', 'updated_at']);

  return <String, dynamic>{
    'id': _pickString(raw, const ['id']).isEmpty
        ? currentUserId
        : _pickString(raw, const ['id']),
    'phoneNumber':
        _pickString(raw, const ['phoneNumber', 'phone_number', 'email']).isEmpty
        ? fallbackPhone
        : _pickString(raw, const ['phoneNumber', 'phone_number', 'email']),
    'name': _pickString(raw, const ['name']).isEmpty
        ? 'You'
        : _pickString(raw, const ['name']),
    'dateOfBirth': dateOfBirth.isEmpty
        ? '1996-01-01T00:00:00.000Z'
        : dateOfBirth,
    'gender': _pickString(raw, const ['gender']).isEmpty
        ? 'Prefer not to say'
        : _pickString(raw, const ['gender']),
    'createdAt': createdAt.isEmpty ? now : createdAt,
    'bio': _pickNullable(raw, const ['bio']),
    'heightCm': _pickInt(raw, const ['heightCm', 'height_cm']),
    'education': _pickNullable(raw, const ['education']),
    'profession': _pickNullable(raw, const ['profession']),
    'incomeRange': _pickNullable(raw, const ['incomeRange', 'income_range']),
    'drinking': _pickNullable(raw, const ['drinking']),
    'smoking': _pickNullable(raw, const ['smoking']),
    'religion': _pickNullable(raw, const ['religion']),
    'profileCompletion': _pickInt(raw, const [
      'profileCompletion',
      'profile_completion',
    ]),
    'isVerified': _pickBool(raw, const ['isVerified', 'is_verified']),
    'verificationBadge': _pickBool(raw, const [
      'verificationBadge',
      'verification_badge',
    ]),
    'lastLogin': lastLogin.isEmpty ? now : lastLogin,
    'isActive': _pickBool(raw, const ['isActive', 'is_active'], fallback: true),
    'isBlocked': _pickBool(raw, const ['isBlocked', 'is_blocked']),
    'blockedUsers': _pickStringList(raw, const [
      'blockedUsers',
      'blocked_users',
    ]),
    'updatedAt': updatedAt.isEmpty ? now : updatedAt,
  };
}

Map<String, dynamic> _normalizePreferencesJson(
  Map<String, dynamic> raw, {
  required String currentUserId,
}) => <String, dynamic>{
  'id': _pickString(raw, const ['id']).isEmpty
      ? 'pref-$currentUserId'
      : _pickString(raw, const ['id']),
  'userId': _pickString(raw, const ['userId', 'user_id']).isEmpty
      ? currentUserId
      : _pickString(raw, const ['userId', 'user_id']),
  'seekingGenders': _pickStringList(raw, const [
    'seekingGenders',
    'seeking_genders',
  ]),
  'minAgeYears': _pickInt(raw, const [
    'minAgeYears',
    'min_age_years',
  ], fallback: 18),
  'maxAgeYears': _pickInt(raw, const [
    'maxAgeYears',
    'max_age_years',
  ], fallback: 60),
  'maxDistanceKm': _pickInt(raw, const [
    'maxDistanceKm',
    'max_distance_km',
  ], fallback: 50),
  'minHeightCm': _pickNullableInt(raw, const ['minHeightCm', 'min_height_cm']),
  'maxHeightCm': _pickNullableInt(raw, const ['maxHeightCm', 'max_height_cm']),
  'educationFilter': _pickStringList(raw, const [
    'educationFilter',
    'education_filter',
  ]),
  'seriousOnly': _pickBool(raw, const ['seriousOnly', 'serious_only']),
  'verifiedOnly': _pickBool(raw, const ['verifiedOnly', 'verified_only']),
  'updatedAt': _pickString(raw, const ['updatedAt', 'updated_at']).isEmpty
      ? DateTime.now().toIso8601String()
      : _pickString(raw, const ['updatedAt', 'updated_at']),
};

String _pickString(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String? _pickNullable(Map<String, dynamic> raw, List<String> keys) {
  final value = _pickString(raw, keys);
  return value.isEmpty ? null : value;
}

int _pickInt(Map<String, dynamic> raw, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = raw[key];
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      continue;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

int? _pickNullableInt(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      continue;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

bool _pickBool(
  Map<String, dynamic> raw,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = raw[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final lowered = value.trim().toLowerCase();
      if (lowered == 'true') {
        return true;
      }
      if (lowered == 'false') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
  }
  return fallback;
}

List<String> _pickStringList(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }
  return const <String>[];
}
