import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

enum ActivityQuestionType { thisOrThat, valueMatch, scenarioChoice }

class ActivityQuestion {
  const ActivityQuestion({
    required this.id,
    required this.title,
    required this.prompt,
    required this.type,
    required this.options,
  });
  final String id;
  final String title;
  final String prompt;
  final ActivityQuestionType type;
  final List<String> options;
}

class ActivitySummary {
  const ActivitySummary({
    required this.sessionId,
    required this.matchId,
    required this.status,
    required this.totalParticipants,
    required this.responsesSubmitted,
    required this.participantsCompleted,
    required this.participantsPending,
    required this.insight,
    this.generatedAt,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      sessionId: json['session_id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalParticipants: _intValue(json['total_participants']),
      responsesSubmitted: _intValue(json['responses_submitted']),
      participantsCompleted: _stringList(json['participants_completed']),
      participantsPending: _stringList(json['participants_pending']),
      insight: json['insight']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
    );
  }
  final String sessionId;
  final String matchId;
  final String status;
  final int totalParticipants;
  final int responsesSubmitted;
  final List<String> participantsCompleted;
  final List<String> participantsPending;
  final String insight;
  final DateTime? generatedAt;
}

class ActivitySessionState {
  const ActivitySessionState({
    this.sessionId,
    this.status = '',
    this.activityType = 'this_or_that',
    this.expiresAt,
    this.startedAt,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSummaryLoading = false,
    this.error,
    this.summary,
    this.questions = const [],
    this.selectedAnswers = const {},
  });
  final String? sessionId;
  final String status;
  final String activityType;
  final DateTime? expiresAt;
  final DateTime? startedAt;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSummaryLoading;
  final String? error;
  final ActivitySummary? summary;
  final List<ActivityQuestion> questions;
  final Map<String, String> selectedAnswers;

  bool get isTerminal =>
      status == 'completed' ||
      status == 'timed_out' ||
      status == 'partial_timeout';

  bool get allQuestionsAnswered =>
      questions.isNotEmpty && selectedAnswers.length >= questions.length;

  ActivitySessionState copyWith({
    String? sessionId,
    String? status,
    String? activityType,
    DateTime? expiresAt,
    DateTime? startedAt,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSummaryLoading,
    String? error,
    bool clearError = false,
    ActivitySummary? summary,
    bool clearSummary = false,
    List<ActivityQuestion>? questions,
    Map<String, String>? selectedAnswers,
  }) => ActivitySessionState(
    sessionId: sessionId ?? this.sessionId,
    status: status ?? this.status,
    activityType: activityType ?? this.activityType,
    expiresAt: expiresAt ?? this.expiresAt,
    startedAt: startedAt ?? this.startedAt,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
    error: clearError ? null : (error ?? this.error),
    summary: clearSummary ? null : (summary ?? this.summary),
    questions: questions ?? this.questions,
    selectedAnswers: selectedAnswers ?? this.selectedAnswers,
  );
}

class ActivitySessionNotifier extends StateNotifier<ActivitySessionState> {
  ActivitySessionNotifier(this._ref, this._matchId, this._otherUserId)
    : super(ActivitySessionState(questions: buildDefaultActivityQuestions()));

  final Ref _ref;
  final String _matchId;
  final String _otherUserId;

  Future<void> startSession({String activityType = 'this_or_that'}) async {
    final currentUserId = _currentUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSummary: true,
      selectedAnswers: const {},
      status: '',
      sessionId: null,
    );

    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        isLoading: false,
        sessionId: 'mock-activity-${now.millisecondsSinceEpoch}',
        status: 'active',
        activityType: activityType,
        startedAt: now,
        expiresAt: now.add(const Duration(seconds: 180)),
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/activities/sessions/start',
        data: {
          'match_id': _matchId,
          'initiator_user_id': currentUserId,
          'participant_user_id': _otherUserId,
          'activity_type': activityType,
          'metadata': {
            'ui_variant': 'story_4_2',
            'question_set': 'this_or_that_eight_cards_v1',
          },
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final session =
          (body['session'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isLoading: false,
        sessionId: session['id']?.toString(),
        status: session['status']?.toString() ?? 'active',
        activityType: session['activity_type']?.toString() ?? activityType,
        startedAt: DateTime.tryParse(session['started_at']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(session['expires_at']?.toString() ?? ''),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to start activity session', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractError(
          e,
          fallback: 'Unable to start activity right now. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to start activity session', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to start activity right now. Please try again.',
      );
    }
  }

  void selectAnswer(String questionId, String answer) {
    final next = Map<String, String>.from(state.selectedAnswers)
      ..[questionId] = answer;
    state = state.copyWith(selectedAnswers: next, clearError: true);
  }

  Future<void> submitCurrentUserResponses() async {
    final sessionId = state.sessionId;
    final currentUserId = _currentUserId();
    if (sessionId == null || sessionId.isEmpty || currentUserId == null) {
      state = state.copyWith(error: 'Session is not ready yet.');
      return;
    }

    if (!state.allQuestionsAnswered) {
      state = state.copyWith(
        error: 'Please answer all prompts before submitting.',
      );
      return;
    }

    if (computeActivityRemainingSeconds(
          state.expiresAt,
          DateTime.now().toUtc(),
        ) <=
        0) {
      state = state.copyWith(error: 'Time is up. Loading activity summary...');
      await loadSummary();
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final responses = _orderedResponses();

    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        isSubmitting: false,
        status: 'completed',
        summary: ActivitySummary(
          sessionId: sessionId,
          matchId: _matchId,
          status: 'completed',
          totalParticipants: 2,
          responsesSubmitted: 2,
          participantsCompleted: <String>[currentUserId, _otherUserId],
          participantsPending: const <String>[],
          insight: 'Both participants completed the activity session.',
          generatedAt: now,
        ),
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/activities/sessions/$sessionId/submit',
        data: {'user_id': currentUserId, 'responses': responses},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final session =
          (body['session'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final status = session['status']?.toString() ?? 'active';

      state = state.copyWith(isSubmitting: false, status: status);

      if (status == 'completed' ||
          status == 'timed_out' ||
          status == 'partial_timeout') {
        await loadSummary();
      }
    } on DioException catch (e, stackTrace) {
      log.error('Failed to submit activity responses', e, stackTrace);
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 408) {
        state = state.copyWith(isSubmitting: false, status: 'timed_out');
        await loadSummary();
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        error: _extractError(
          e,
          fallback: 'Failed to submit activity responses. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to submit activity responses', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to submit activity responses. Please try again.',
      );
    }
  }

  Future<void> loadSummary() async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    if (kUseMockAuth) {
      if (state.summary == null) {
        final currentUserId = _currentUserId() ?? 'mock-user';
        state = state.copyWith(
          status: state.status.isEmpty ? 'partial_timeout' : state.status,
          summary: ActivitySummary(
            sessionId: sessionId,
            matchId: _matchId,
            status: state.status.isEmpty ? 'partial_timeout' : state.status,
            totalParticipants: 2,
            responsesSubmitted: min(state.selectedAnswers.isEmpty ? 0 : 1, 2),
            participantsCompleted: state.selectedAnswers.isEmpty
                ? const <String>[]
                : <String>[currentUserId],
            participantsPending: state.selectedAnswers.isEmpty
                ? <String>[currentUserId, _otherUserId]
                : <String>[_otherUserId],
            insight: state.selectedAnswers.isEmpty
                ? 'No responses were submitted.'
                : 'Partial completion captured before the session closed.',
            generatedAt: DateTime.now().toUtc(),
          ),
        );
      }
      return;
    }

    state = state.copyWith(isSummaryLoading: true, clearError: true);

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/activities/sessions/$sessionId/summary',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final summaryJson =
          (body['summary'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final sessionJson =
          (body['session'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isSummaryLoading: false,
        summary: ActivitySummary.fromJson(summaryJson),
        status: sessionJson['status']?.toString() ?? state.status,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to fetch activity summary', e, stackTrace);
      state = state.copyWith(
        isSummaryLoading: false,
        error: _extractError(
          e,
          fallback: 'Unable to fetch summary yet. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to fetch activity summary', e, stackTrace);
      state = state.copyWith(
        isSummaryLoading: false,
        error: 'Unable to fetch summary yet. Please try again.',
      );
    }
  }

  String? _currentUserId() {
    final userId = _ref.read(authNotifierProvider).userId;
    return userId?.trim().isEmpty == true ? null : userId;
  }

  List<String> _orderedResponses() => state.questions
      .map((question) {
        final answer = state.selectedAnswers[question.id];
        if (answer == null || answer.isEmpty) {
          return '';
        }
        return '${question.id}:$answer';
      })
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

List<ActivityQuestion> buildDefaultActivityQuestions() =>
    const <ActivityQuestion>[
      ActivityQuestion(
        id: 'this_or_that_01',
        title: 'Round 1',
        prompt: 'Ideal first meetup?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Coffee walk', 'Bookstore browse'],
      ),
      ActivityQuestion(
        id: 'this_or_that_02',
        title: 'Round 2',
        prompt: 'Preferred weekend mood?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Stay in and recharge', 'Explore the city'],
      ),
      ActivityQuestion(
        id: 'this_or_that_03',
        title: 'Round 3',
        prompt: 'Best conversation setting?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Long walk', 'Cozy cafe corner'],
      ),
      ActivityQuestion(
        id: 'this_or_that_04',
        title: 'Round 4',
        prompt: 'How do you plan dates?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Spontaneous', 'Planned in advance'],
      ),
      ActivityQuestion(
        id: 'this_or_that_05',
        title: 'Round 5',
        prompt: 'Which matters more right now?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Consistency', 'Excitement'],
      ),
      ActivityQuestion(
        id: 'this_or_that_06',
        title: 'Round 6',
        prompt: 'Conflict style preference?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Resolve same day', 'Take space then revisit'],
      ),
      ActivityQuestion(
        id: 'this_or_that_07',
        title: 'Round 7',
        prompt: 'Shared activity pick?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Cook together', 'Workout together'],
      ),
      ActivityQuestion(
        id: 'this_or_that_08',
        title: 'Round 8',
        prompt: 'Pace preference?',
        type: ActivityQuestionType.thisOrThat,
        options: <String>['Steady and intentional', 'Fast and energetic'],
      ),
    ];

int computeActivityRemainingSeconds(DateTime? expiresAt, DateTime nowUtc) {
  if (expiresAt == null) {
    return 0;
  }
  final remaining = expiresAt.toUtc().difference(nowUtc.toUtc()).inSeconds;
  return max(0, remaining);
}

String _extractError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}

List<String> _stringList(dynamic raw) {
  final list = (raw as List?) ?? const [];
  return list.map((item) => item.toString()).toList(growable: false);
}

int _intValue(dynamic raw) {
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw.trim()) ?? 0;
  }
  return 0;
}

final activitySessionProvider =
    StateNotifierProvider.family<
      ActivitySessionNotifier,
      ActivitySessionState,
      ({String matchId, String otherUserId})
    >(
      (ref, args) =>
          ActivitySessionNotifier(ref, args.matchId, args.otherUserId),
    );
