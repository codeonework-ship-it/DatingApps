import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class DailyPromptDefinition {
  const DailyPromptDefinition({
    required this.id,
    required this.promptDate,
    required this.domain,
    required this.promptText,
    required this.minChars,
    required this.maxChars,
    required this.responseMode,
  });

  factory DailyPromptDefinition.fromJson(Map<String, dynamic> json) =>
      DailyPromptDefinition(
        id: json['id']?.toString() ?? '',
        promptDate: json['prompt_date']?.toString() ?? '',
        domain: json['domain']?.toString() ?? 'values',
        promptText: json['prompt_text']?.toString() ?? '',
        minChars: (json['min_chars'] as num?)?.toInt() ?? 1,
        maxChars: (json['max_chars'] as num?)?.toInt() ?? 240,
        responseMode: json['response_mode']?.toString() ?? 'text',
      );

  final String id;
  final String promptDate;
  final String domain;
  final String promptText;
  final int minChars;
  final int maxChars;
  final String responseMode;
}

class DailyPromptAnswer {
  const DailyPromptAnswer({
    required this.userId,
    required this.promptId,
    required this.promptDate,
    required this.answerText,
    required this.answeredAt,
    required this.updatedAt,
    required this.editWindowUntil,
    required this.isEdited,
  });

  factory DailyPromptAnswer.fromJson(Map<String, dynamic> json) =>
      DailyPromptAnswer(
        userId: json['user_id']?.toString() ?? '',
        promptId: json['prompt_id']?.toString() ?? '',
        promptDate: json['prompt_date']?.toString() ?? '',
        answerText: json['answer_text']?.toString() ?? '',
        answeredAt: DateTime.tryParse(json['answered_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
        editWindowUntil: DateTime.tryParse(
          json['edit_window_until']?.toString() ?? '',
        ),
        isEdited: json['is_edited'] == true,
      );

  final String userId;
  final String promptId;
  final String promptDate;
  final String answerText;
  final DateTime? answeredAt;
  final DateTime? updatedAt;
  final DateTime? editWindowUntil;
  final bool isEdited;

  bool get canEdit {
    final window = editWindowUntil;
    if (window == null) {
      return false;
    }
    return DateTime.now().toUtc().isBefore(window.toUtc());
  }
}

class DailyPromptStreak {
  const DailyPromptStreak({
    required this.currentDays,
    required this.longestDays,
    required this.lastAnsweredDate,
    required this.nextMilestone,
    required this.milestoneReached,
  });

  factory DailyPromptStreak.fromJson(Map<String, dynamic> json) =>
      DailyPromptStreak(
        currentDays: (json['current_days'] as num?)?.toInt() ?? 0,
        longestDays: (json['longest_days'] as num?)?.toInt() ?? 0,
        lastAnsweredDate: json['last_answered_date']?.toString() ?? '',
        nextMilestone: (json['next_milestone'] as num?)?.toInt() ?? 0,
        milestoneReached: (json['milestone_reached'] as num?)?.toInt() ?? 0,
      );

  final int currentDays;
  final int longestDays;
  final String lastAnsweredDate;
  final int nextMilestone;
  final int milestoneReached;
}

class DailyPromptSpark {
  const DailyPromptSpark({
    required this.participantsToday,
    required this.similarAnswerCount,
    required this.similarUserIds,
  });

  factory DailyPromptSpark.fromJson(Map<String, dynamic> json) =>
      DailyPromptSpark(
        participantsToday: (json['participants_today'] as num?)?.toInt() ?? 0,
        similarAnswerCount:
            (json['similar_answer_count'] as num?)?.toInt() ?? 0,
        similarUserIds: ((json['similar_user_ids'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );

  final int participantsToday;
  final int similarAnswerCount;
  final List<String> similarUserIds;
}

class DailyPromptResponderPreview {
  const DailyPromptResponderPreview({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    this.answeredAt,
  });

  factory DailyPromptResponderPreview.fromJson(Map<String, dynamic> json) =>
      DailyPromptResponderPreview(
        userId: json['user_id']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString() ?? '',
        answeredAt: DateTime.tryParse(json['answered_at']?.toString() ?? ''),
      );

  final String userId;
  final String displayName;
  final String photoUrl;
  final DateTime? answeredAt;
}

class DailyPromptView {
  const DailyPromptView({
    required this.prompt,
    required this.answer,
    required this.streak,
    required this.spark,
  });

  factory DailyPromptView.fromJson(Map<String, dynamic> json) {
    final answerRaw = (json['answer'] as Map?)?.cast<String, dynamic>();
    return DailyPromptView(
      prompt: DailyPromptDefinition.fromJson(
        (json['prompt'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      answer: answerRaw == null ? null : DailyPromptAnswer.fromJson(answerRaw),
      streak: DailyPromptStreak.fromJson(
        (json['streak'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      spark: DailyPromptSpark.fromJson(
        (json['spark'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
    );
  }

  final DailyPromptDefinition prompt;
  final DailyPromptAnswer? answer;
  final DailyPromptStreak streak;
  final DailyPromptSpark spark;
}

class DailyPromptState {
  const DailyPromptState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isRespondersLoading = false,
    this.error,
    this.view,
    this.responders = const <DailyPromptResponderPreview>[],
    this.respondersHasMore = false,
    this.respondersNextOffset = 0,
  });

  final bool isLoading;
  final bool isSubmitting;
  final bool isRespondersLoading;
  final String? error;
  final DailyPromptView? view;
  final List<DailyPromptResponderPreview> responders;
  final bool respondersHasMore;
  final int respondersNextOffset;

  DailyPromptState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isRespondersLoading,
    String? error,
    bool clearError = false,
    DailyPromptView? view,
    List<DailyPromptResponderPreview>? responders,
    bool? respondersHasMore,
    int? respondersNextOffset,
  }) => DailyPromptState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isRespondersLoading: isRespondersLoading ?? this.isRespondersLoading,
    error: clearError ? null : (error ?? this.error),
    view: view ?? this.view,
    responders: responders ?? this.responders,
    respondersHasMore: respondersHasMore ?? this.respondersHasMore,
    respondersNextOffset: respondersNextOffset ?? this.respondersNextOffset,
  );
}

class DailyPromptNotifier extends StateNotifier<DailyPromptState> {
  DailyPromptNotifier(this._ref) : super(const DailyPromptState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'User session not available.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        isLoading: false,
        view: DailyPromptView(
          prompt: DailyPromptDefinition(
            id: 'daily-${now.toIso8601String()}',
            promptDate: now.toIso8601String().substring(0, 10),
            domain: 'values',
            promptText:
                'What is one boundary that helps you feel respected in a relationship?',
            minChars: 1,
            maxChars: 240,
            responseMode: 'text',
          ),
          answer: null,
          streak: const DailyPromptStreak(
            currentDays: 0,
            longestDays: 0,
            lastAnsweredDate: '',
            nextMilestone: 3,
            milestoneReached: 0,
          ),
          spark: const DailyPromptSpark(
            participantsToday: 18,
            similarAnswerCount: 0,
            similarUserIds: <String>[],
          ),
        ),
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/engagement/daily-prompt/$userId',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final view = DailyPromptView.fromJson(
        (body['daily_prompt'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      );
      state = state.copyWith(isLoading: false, view: view);
      if (view.answer != null) {
        await loadResponders();
      } else {
        state = state.copyWith(
          responders: const <DailyPromptResponderPreview>[],
          respondersHasMore: false,
          respondersNextOffset: 0,
        );
      }
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load daily prompt', e, stackTrace);
      if (e.response?.statusCode == 404) {
        state = state.copyWith(
          isLoading: false,
          view: null,
          responders: const <DailyPromptResponderPreview>[],
          respondersHasMore: false,
          respondersNextOffset: 0,
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to load daily prompt right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load daily prompt', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load daily prompt right now.',
      );
    }
  }

  Future<void> submitAnswer(String rawAnswer) async {
    final userId = _currentUserId();
    final view = state.view;
    final answerText = rawAnswer.trim();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }
    if (view == null) {
      state = state.copyWith(error: 'Daily prompt is not loaded yet.');
      return;
    }
    if (answerText.isEmpty) {
      state = state.copyWith(error: 'Please enter an answer first.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      final currentDays = view.answer == null
          ? view.streak.currentDays + 1
          : view.streak.currentDays;
      final nextMilestone = currentDays < 3 ? 3 : (currentDays < 7 ? 7 : 0);
      state = state.copyWith(
        isSubmitting: false,
        view: DailyPromptView(
          prompt: view.prompt,
          answer: DailyPromptAnswer(
            userId: userId,
            promptId: view.prompt.id,
            promptDate: view.prompt.promptDate,
            answerText: answerText,
            answeredAt: now,
            updatedAt: now,
            editWindowUntil: now.add(const Duration(minutes: 10)),
            isEdited: view.answer != null,
          ),
          streak: DailyPromptStreak(
            currentDays: currentDays,
            longestDays: currentDays > view.streak.longestDays
                ? currentDays
                : view.streak.longestDays,
            lastAnsweredDate: view.prompt.promptDate,
            nextMilestone: nextMilestone,
            milestoneReached: currentDays == 3 || currentDays == 7
                ? currentDays
                : 0,
          ),
          spark: DailyPromptSpark(
            participantsToday: view.spark.participantsToday + 1,
            similarAnswerCount: view.spark.similarAnswerCount,
            similarUserIds: view.spark.similarUserIds,
          ),
        ),
      );
      await loadResponders();
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/engagement/daily-prompt/$userId/answer',
        data: {'prompt_id': view.prompt.id, 'answer_text': answerText},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final nextView = DailyPromptView.fromJson(
        (body['daily_prompt'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      );
      state = state.copyWith(isSubmitting: false, view: nextView);
      await loadResponders();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to submit daily prompt answer', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to submit answer. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to submit daily prompt answer', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to submit answer. Please try again.',
      );
    }
  }

  Future<void> loadResponders({int limit = 6, int offset = 0}) async {
    final userId = _currentUserId();
    final view = state.view;
    if (userId == null || userId.isEmpty || view?.answer == null) {
      state = state.copyWith(
        responders: const <DailyPromptResponderPreview>[],
        respondersHasMore: false,
        respondersNextOffset: 0,
      );
      return;
    }

    state = state.copyWith(isRespondersLoading: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isRespondersLoading: false,
        responders: const <DailyPromptResponderPreview>[
          DailyPromptResponderPreview(
            userId: 'mock-responder-1',
            displayName: 'Aarav',
            photoUrl: '',
          ),
          DailyPromptResponderPreview(
            userId: 'mock-responder-2',
            displayName: 'Maya',
            photoUrl: '',
          ),
        ],
        respondersHasMore: false,
        respondersNextOffset: 2,
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/engagement/daily-prompt/$userId/responders',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final rawResponders = (body['responders'] as List?) ?? const [];
      final pagination =
          (body['pagination'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final responders = rawResponders
          .whereType<Map<String, dynamic>>()
          .map((item) => DailyPromptResponderPreview.fromJson(item))
          .where((item) => item.userId.isNotEmpty)
          .toList(growable: false);

      state = state.copyWith(
        isRespondersLoading: false,
        responders: responders,
        respondersHasMore: pagination['has_more'] == true,
        respondersNextOffset: (pagination['next_offset'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load daily prompt responders', e, stackTrace);
      state = state.copyWith(isRespondersLoading: false);
    } catch (e, stackTrace) {
      log.error('Failed to load daily prompt responders', e, stackTrace);
      state = state.copyWith(isRespondersLoading: false);
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

final dailyPromptProvider =
    StateNotifierProvider<DailyPromptNotifier, DailyPromptState>(
      (ref) => DailyPromptNotifier(ref),
    );
