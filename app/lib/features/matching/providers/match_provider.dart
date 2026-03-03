import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_setup_provider.dart';

part 'match_provider.g.dart';

/// Match Model
class Match {
  const Match({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
  });
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
}

/// Match State
class MatchState {
  const MatchState({
    this.matches = const [],
    this.isLoading = false,
    this.error,
    this.trustFilterActive = false,
    this.trustFilteredOutCount = 0,
  });
  final List<Match> matches;
  final bool isLoading;
  final String? error;
  final bool trustFilterActive;
  final int trustFilteredOutCount;

  MatchState copyWith({
    List<Match>? matches,
    bool? isLoading,
    String? error,
    bool? trustFilterActive,
    int? trustFilteredOutCount,
  }) => MatchState(
    matches: matches ?? this.matches,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    trustFilterActive: trustFilterActive ?? this.trustFilterActive,
    trustFilteredOutCount: trustFilteredOutCount ?? this.trustFilteredOutCount,
  );
}

/// Match Provider
@riverpod
class MatchNotifier extends _$MatchNotifier {
  @override
  MatchState build() {
    Future<void>.microtask(_loadMatches);
    return const MatchState(isLoading: true);
  }

  /// Load matches from gateway API
  Future<void> _loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        state = state.copyWith(
          matches: _mockMatches(),
          isLoading: false,
          trustFilterActive: false,
          trustFilteredOutCount: 0,
        );
        return;
      }

      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null) {
        state = state.copyWith(
          matches: const [],
          isLoading: false,
          error: 'Please login to see matches.',
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      final queryParameters = <String, dynamic>{};
      final draftValue = ref.read(profileSetupNotifierProvider);
      final draft = draftValue.valueOrNull;
      if (draft != null) {
        if (draft.intentTags.isNotEmpty) {
          queryParameters['intent_tags'] = draft.intentTags.join(',');
        }
        if (draft.languageTags.isNotEmpty) {
          queryParameters['language_tags'] = draft.languageTags.join(',');
        }
        if ((draft.petPreference ?? '').trim().isNotEmpty) {
          queryParameters['pet_preference'] = draft.petPreference;
        }
        if ((draft.workoutFrequency ?? '').trim().isNotEmpty) {
          queryParameters['workout_frequency'] = draft.workoutFrequency;
        }
        if ((draft.dietType ?? '').trim().isNotEmpty) {
          queryParameters['diet_type'] = draft.dietType;
        }
        if ((draft.sleepSchedule ?? '').trim().isNotEmpty) {
          queryParameters['sleep_schedule'] = draft.sleepSchedule;
        }
        if ((draft.travelStyle ?? '').trim().isNotEmpty) {
          queryParameters['travel_style'] = draft.travelStyle;
        }
        if ((draft.politicalComfortRange ?? '').trim().isNotEmpty) {
          queryParameters['political_comfort_range'] =
              draft.politicalComfortRange;
        }
        if (draft.dealBreakerTags.isNotEmpty) {
          queryParameters['deal_breaker_tags'] = draft.dealBreakerTags.join(
            ',',
          );
        }
        if ((draft.country ?? '').trim().isNotEmpty) {
          queryParameters['country'] = draft.country;
        }
        if ((draft.regionState ?? '').trim().isNotEmpty) {
          queryParameters['state'] = draft.regionState;
        }
        if ((draft.city ?? '').trim().isNotEmpty) {
          queryParameters['city'] = draft.city;
        }
      }
      final response = await dio.get<Map<String, dynamic>>(
        '/matches/$currentUserId',
        queryParameters: queryParameters,
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final raw = (body['matches'] as List?) ?? const [];
      final trustFilter =
          (body['trust_filter'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final mapped = raw
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final map = row;
            final lastMessageAt =
                DateTime.tryParse(map['lastMessageTime']?.toString() ?? '') ??
                DateTime.now();
            return Match(
              id: map['id']?.toString() ?? '',
              userId: map['userId']?.toString() ?? '',
              userName: map['userName']?.toString() ?? 'Unknown',
              userPhoto:
                  map['userPhoto']?.toString() ??
                  AppRuntimeConfig.placeholderAvatarImageUrl,
              lastMessage: map['lastMessage']?.toString() ?? 'Say hi 👋',
              lastMessageTime: lastMessageAt,
              unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
              isOnline: map['isOnline'] == true,
            );
          })
          .where((m) => m.id.isNotEmpty)
          .toList();

      state = state.copyWith(
        matches: mapped,
        isLoading: false,
        error: null,
        trustFilterActive: trustFilter['active'] == true,
        trustFilteredOutCount:
            (trustFilter['filtered_out_count'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load matches', e, stackTrace);
      final data = e.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Failed to load matches. Please try again.';
      state = state.copyWith(error: message, isLoading: false);
    } catch (e, stackTrace) {
      log.error('Failed to load matches', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load matches. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Unmatch
  Future<void> unmatch(String matchId) async {
    try {
      if (!kUseMockAuth) {
        final currentUserId = ref.read(authNotifierProvider).userId;
        if (currentUserId == null) return;

        final dio = ref.read(apiClientProvider);
        await dio.delete<void>(
          '/matches/$matchId',
          queryParameters: {'user_id': currentUserId},
        );
      }

      state = state.copyWith(
        matches: state.matches.where((m) => m.id != matchId).toList(),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to unmatch', e, stackTrace);
      state = state.copyWith(error: 'Failed to unmatch.');
    } catch (e, stackTrace) {
      log.error('Failed to unmatch', e, stackTrace);
      state = state.copyWith(error: 'Failed to unmatch.');
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String matchId) async {
    try {
      if (!kUseMockAuth) {
        final currentUserId = ref.read(authNotifierProvider).userId;
        if (currentUserId == null) return;

        final dio = ref.read(apiClientProvider);
        await dio.post<void>(
          '/matches/$matchId/read',
          data: {'user_id': currentUserId},
        );
      }

      final updated = state.matches.map((m) {
        if (m.id != matchId) return m;
        return Match(
          id: m.id,
          userId: m.userId,
          userName: m.userName,
          userPhoto: m.userPhoto,
          lastMessage: m.lastMessage,
          lastMessageTime: m.lastMessageTime,
          unreadCount: 0,
          isOnline: m.isOnline,
        );
      }).toList();
      state = state.copyWith(matches: updated);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to mark messages as read', e, stackTrace);
      state = state.copyWith(error: 'Failed to mark as read.');
    } catch (e, stackTrace) {
      log.error('Failed to mark messages as read', e, stackTrace);
      state = state.copyWith(error: 'Failed to mark as read.');
    }
  }

  /// Manual refresh for pull-to-refresh patterns.
  Future<void> refresh() async {
    await _loadMatches();
  }
}

List<Match> _mockMatches() {
  final now = DateTime.now();
  return <Match>[
    Match(
      id: 'mock-match-mock-user-002',
      userId: 'mock-user-002',
      userName: 'Anya',
      userPhoto:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
      lastMessage: 'Hey! How is your week going?',
      lastMessageTime: now.subtract(const Duration(minutes: 7)),
      unreadCount: 2,
      isOnline: true,
    ),
    Match(
      id: 'mock-match-mock-user-004',
      userId: 'mock-user-004',
      userName: 'Mira',
      userPhoto:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=500&q=80',
      lastMessage: 'Coffee this Sunday?',
      lastMessageTime: now.subtract(const Duration(hours: 3)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];
}
