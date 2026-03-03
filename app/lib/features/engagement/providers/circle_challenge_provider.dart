import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class CircleChallengeItem {
  const CircleChallengeItem({
    required this.id,
    required this.city,
    required this.topic,
    required this.promptText,
    required this.participationCount,
    required this.isJoined,
    required this.challengeId,
    this.userEntryText,
  });

  final String id;
  final String city;
  final String topic;
  final String promptText;
  final int participationCount;
  final bool isJoined;
  final String challengeId;
  final String? userEntryText;

  CircleChallengeItem copyWith({
    String? id,
    String? city,
    String? topic,
    String? promptText,
    int? participationCount,
    bool? isJoined,
    String? challengeId,
    String? userEntryText,
  }) => CircleChallengeItem(
    id: id ?? this.id,
    city: city ?? this.city,
    topic: topic ?? this.topic,
    promptText: promptText ?? this.promptText,
    participationCount: participationCount ?? this.participationCount,
    isJoined: isJoined ?? this.isJoined,
    challengeId: challengeId ?? this.challengeId,
    userEntryText: userEntryText ?? this.userEntryText,
  );
}

class CircleChallengeState {
  const CircleChallengeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.items = const <CircleChallengeItem>[],
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<CircleChallengeItem> items;

  CircleChallengeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    List<CircleChallengeItem>? items,
  }) => CircleChallengeState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : (error ?? this.error),
    items: items ?? this.items,
  );
}

class CircleChallengeNotifier extends StateNotifier<CircleChallengeState> {
  CircleChallengeNotifier(this._ref) : super(const CircleChallengeState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  static const List<String> _defaultCircleIds = <String>[
    'circle-blr-books',
    'circle-blr-fitness',
    'circle-blr-music',
  ];

  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        items: const <CircleChallengeItem>[
          CircleChallengeItem(
            id: 'circle-blr-books',
            city: 'Bengaluru',
            topic: 'Books',
            promptText: 'One quote that changed your week.',
            participationCount: 12,
            isJoined: false,
            challengeId: 'circle-blr-books-2026-W10',
          ),
          CircleChallengeItem(
            id: 'circle-blr-fitness',
            city: 'Bengaluru',
            topic: 'Fitness',
            promptText: "This week's 20-min routine.",
            participationCount: 8,
            isJoined: false,
            challengeId: 'circle-blr-fitness-2026-W10',
          ),
          CircleChallengeItem(
            id: 'circle-blr-music',
            city: 'Bengaluru',
            topic: 'Music',
            promptText: 'Song currently on repeat + why.',
            participationCount: 10,
            isJoined: false,
            challengeId: 'circle-blr-music-2026-W10',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final loaded = <CircleChallengeItem>[];
      for (final circleId in _defaultCircleIds) {
        final response = await dio.get<Map<String, dynamic>>(
          '/engagement/circles/$circleId/challenge',
          queryParameters: <String, dynamic>{'user_id': userId},
        );
        final body =
            (response.data as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final view =
            (body['circle_challenge'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final challenge =
            (view['challenge'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final userEntry =
            (view['user_entry'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        loaded.add(
          CircleChallengeItem(
            id: view['circle_id']?.toString() ?? circleId,
            city: challenge['city']?.toString() ?? 'Bengaluru',
            topic: challenge['topic']?.toString() ?? 'Circle',
            promptText: challenge['prompt_text']?.toString() ?? '',
            participationCount:
                (view['participation_count'] as num?)?.toInt() ?? 0,
            isJoined: view['is_joined'] == true,
            challengeId: challenge['id']?.toString() ?? '',
            userEntryText: userEntry['entry_text']?.toString(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, items: loaded);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load circles', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to load circles right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load circles', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load circles right now.',
      );
    }
  }

  Future<void> joinCircle(String circleId) async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    if (kUseMockAuth) {
      final next = state.items
          .map(
            (item) =>
                item.id == circleId ? item.copyWith(isJoined: true) : item,
          )
          .toList(growable: false);
      state = state.copyWith(isSubmitting: false, items: next);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/circles/$circleId/join',
        data: <String, dynamic>{'user_id': userId},
      );
      final next = state.items
          .map(
            (item) =>
                item.id == circleId ? item.copyWith(isJoined: true) : item,
          )
          .toList(growable: false);
      state = state.copyWith(isSubmitting: false, items: next);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to join circle', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to join circle right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to join circle', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to join circle right now.',
      );
    }
  }

  Future<void> submitEntry({
    required String circleId,
    required String challengeId,
    required String entryText,
  }) async {
    final userId = _currentUserId();
    final trimmedEntry = entryText.trim();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }
    if (trimmedEntry.isEmpty) {
      state = state.copyWith(error: 'Please enter your challenge response.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    if (kUseMockAuth) {
      final next = state.items
          .map(
            (item) => item.id == circleId
                ? item.copyWith(
                    isJoined: true,
                    userEntryText: trimmedEntry,
                    participationCount: item.participationCount + 1,
                  )
                : item,
          )
          .toList(growable: false);
      state = state.copyWith(isSubmitting: false, items: next);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/engagement/circles/$circleId/challenge/entries',
        data: <String, dynamic>{
          'challenge_id': challengeId,
          'user_id': userId,
          'entry_text': trimmedEntry,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final view =
          (body['circle_challenge'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final entry =
          (body['entry'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final next = state.items
          .map(
            (item) => item.id == circleId
                ? item.copyWith(
                    isJoined: true,
                    userEntryText:
                        entry['entry_text']?.toString() ?? trimmedEntry,
                    participationCount:
                        (view['participation_count'] as num?)?.toInt() ??
                        item.participationCount,
                  )
                : item,
          )
          .toList(growable: false);
      state = state.copyWith(isSubmitting: false, items: next);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to submit circle challenge entry', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to submit challenge entry right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to submit circle challenge entry', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to submit challenge entry right now.',
      );
    }
  }

  String? _currentUserId() {
    final userId = _ref.read(authNotifierProvider).userId;
    return userId?.trim().isEmpty == true ? null : userId;
  }
}

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}

final circleChallengeProvider =
    StateNotifierProvider<CircleChallengeNotifier, CircleChallengeState>(
      (ref) => CircleChallengeNotifier(ref),
    );
