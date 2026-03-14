import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class GroupCoffeePollOption {
  const GroupCoffeePollOption({
    required this.id,
    required this.day,
    required this.timeWindow,
    required this.neighborhood,
    required this.votesCount,
  });

  factory GroupCoffeePollOption.fromJson(Map<String, dynamic> json) =>
      GroupCoffeePollOption(
        id: json['id']?.toString() ?? '',
        day: json['day']?.toString() ?? '',
        timeWindow: json['time_window']?.toString() ?? '',
        neighborhood: json['neighborhood']?.toString() ?? '',
        votesCount: (json['votes_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String day;
  final String timeWindow;
  final String neighborhood;
  final int votesCount;
}

class GroupCoffeePoll {
  const GroupCoffeePoll({
    required this.id,
    required this.creatorUserId,
    required this.participantUserIds,
    required this.options,
    required this.status,
    required this.deadlineAt,
    required this.finalizedOptionId,
  });

  factory GroupCoffeePoll.fromJson(Map<String, dynamic> json) =>
      GroupCoffeePoll(
        id: json['id']?.toString() ?? '',
        creatorUserId: json['creator_user_id']?.toString() ?? '',
        participantUserIds:
            ((json['participant_user_ids'] as List?) ?? const [])
                .map((item) => item.toString())
                .toList(growable: false),
        options: ((json['options'] as List?) ?? const <dynamic>[])
            .map(
              (item) => GroupCoffeePollOption.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false),
        status: json['status']?.toString() ?? '',
        deadlineAt: json['deadline_at']?.toString() ?? '',
        finalizedOptionId: json['finalized_option_id']?.toString() ?? '',
      );

  final String id;
  final String creatorUserId;
  final List<String> participantUserIds;
  final List<GroupCoffeePollOption> options;
  final String status;
  final String deadlineAt;
  final String finalizedOptionId;
}

class GroupCoffeePollState {
  const GroupCoffeePollState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.polls = const <GroupCoffeePoll>[],
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<GroupCoffeePoll> polls;

  GroupCoffeePollState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    List<GroupCoffeePoll>? polls,
  }) => GroupCoffeePollState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : (error ?? this.error),
    polls: polls ?? this.polls,
  );
}

class GroupCoffeePollNotifier extends StateNotifier<GroupCoffeePollState> {
  GroupCoffeePollNotifier(this._ref) : super(const GroupCoffeePollState()) {
    load();
  }

  final Ref _ref;

  Future<void> load({String status = ''}) async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        polls: <GroupCoffeePoll>[
          GroupCoffeePoll(
            id: 'poll-mock-1',
            creatorUserId: userId,
            participantUserIds: <String>[userId, 'mock-friend-1'],
            options: const <GroupCoffeePollOption>[
              GroupCoffeePollOption(
                id: 'opt-1',
                day: 'Saturday',
                timeWindow: '10:00-12:00',
                neighborhood: 'Indiranagar',
                votesCount: 1,
              ),
              GroupCoffeePollOption(
                id: 'opt-2',
                day: 'Sunday',
                timeWindow: '11:00-13:00',
                neighborhood: 'Koramangala',
                votesCount: 0,
              ),
            ],
            status: 'open',
            deadlineAt: DateTime.now()
                .toUtc()
                .add(const Duration(hours: 24))
                .toIso8601String(),
            finalizedOptionId: '',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/engagement/group-coffee-polls',
        queryParameters: <String, dynamic>{
          'user_id': userId,
          if (status.trim().isNotEmpty) 'status': status.trim(),
          'limit': 50,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final polls = ((body['polls'] as List?) ?? const <dynamic>[])
          .map(
            (item) =>
                GroupCoffeePoll.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(growable: false);
      state = state.copyWith(isLoading: false, polls: polls);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load group coffee polls', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to load group polls right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load group coffee polls', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load group polls right now.',
      );
    }
  }

  Future<void> createPoll({
    required List<String> participantUserIds,
    required List<Map<String, String>> options,
    String? deadlineAt,
  }) async {
    final creatorUserId = _currentUserId();
    if (creatorUserId == null || creatorUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      if (kUseMockAuth) {
        await load();
        state = state.copyWith(isSubmitting: false);
        return;
      }

      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/group-coffee-polls',
        data: <String, dynamic>{
          'creator_user_id': creatorUserId,
          'participant_user_ids': participantUserIds,
          'options': options,
          if ((deadlineAt ?? '').trim().isNotEmpty) 'deadline_at': deadlineAt,
        },
      );
      await load();
      state = state.copyWith(isSubmitting: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to create group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to create group poll right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to create group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to create group poll right now.',
      );
    }
  }

  Future<void> vote({
    required String pollId,
    required String optionId,
    String? userId,
  }) async {
    final actorId = (userId ?? '').trim().isNotEmpty
        ? userId!.trim()
        : _currentUserId();
    if (actorId == null || actorId.isEmpty) {
      state = state.copyWith(error: 'User ID is required to vote.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      if (kUseMockAuth) {
        await load();
        state = state.copyWith(isSubmitting: false);
        return;
      }

      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/group-coffee-polls/$pollId/votes',
        data: <String, dynamic>{'user_id': actorId, 'option_id': optionId},
      );
      await load();
      state = state.copyWith(isSubmitting: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to vote on group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(e, fallback: 'Unable to vote right now.'),
      );
    } catch (e, stackTrace) {
      log.error('Failed to vote on group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to vote right now.',
      );
    }
  }

  Future<void> finalize({required String pollId, String? userId}) async {
    final actorId = (userId ?? '').trim().isNotEmpty
        ? userId!.trim()
        : _currentUserId();
    if (actorId == null || actorId.isEmpty) {
      state = state.copyWith(error: 'User ID is required to finalize.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      if (kUseMockAuth) {
        await load();
        state = state.copyWith(isSubmitting: false);
        return;
      }

      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/group-coffee-polls/$pollId/finalize',
        data: <String, dynamic>{'user_id': actorId},
      );
      await load();
      state = state.copyWith(isSubmitting: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to finalize group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to finalize poll right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to finalize group coffee poll', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to finalize poll right now.',
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

final groupCoffeePollProvider =
    StateNotifierProvider<GroupCoffeePollNotifier, GroupCoffeePollState>(
      GroupCoffeePollNotifier.new,
    );
