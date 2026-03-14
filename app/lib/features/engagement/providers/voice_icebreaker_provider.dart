import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class VoiceIcebreakerPrompt {
  const VoiceIcebreakerPrompt({required this.id, required this.promptText});

  factory VoiceIcebreakerPrompt.fromJson(Map<String, dynamic> json) =>
      VoiceIcebreakerPrompt(
        id: json['id']?.toString() ?? '',
        promptText: json['prompt_text']?.toString() ?? '',
      );

  final String id;
  final String promptText;
}

class VoiceIcebreakerItem {
  const VoiceIcebreakerItem({
    required this.id,
    required this.matchId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.promptId,
    required this.promptText,
    required this.transcript,
    required this.durationSeconds,
    required this.status,
    required this.playCount,
  });

  factory VoiceIcebreakerItem.fromJson(Map<String, dynamic> json) =>
      VoiceIcebreakerItem(
        id: json['id']?.toString() ?? '',
        matchId: json['match_id']?.toString() ?? '',
        senderUserId: json['sender_user_id']?.toString() ?? '',
        receiverUserId: json['receiver_user_id']?.toString() ?? '',
        promptId: json['prompt_id']?.toString() ?? '',
        promptText: json['prompt_text']?.toString() ?? '',
        transcript: json['transcript']?.toString() ?? '',
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? '',
        playCount: (json['play_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String matchId;
  final String senderUserId;
  final String receiverUserId;
  final String promptId;
  final String promptText;
  final String transcript;
  final int durationSeconds;
  final String status;
  final int playCount;
}

class VoiceIcebreakerState {
  const VoiceIcebreakerState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.prompts = const <VoiceIcebreakerPrompt>[],
    this.lastItem,
    this.error,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<VoiceIcebreakerPrompt> prompts;
  final VoiceIcebreakerItem? lastItem;
  final String? error;

  VoiceIcebreakerState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<VoiceIcebreakerPrompt>? prompts,
    VoiceIcebreakerItem? lastItem,
    bool clearLastItem = false,
    String? error,
    bool clearError = false,
  }) => VoiceIcebreakerState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    prompts: prompts ?? this.prompts,
    lastItem: clearLastItem ? null : (lastItem ?? this.lastItem),
    error: clearError ? null : (error ?? this.error),
  );
}

class VoiceIcebreakerNotifier extends StateNotifier<VoiceIcebreakerState> {
  VoiceIcebreakerNotifier(this._ref) : super(const VoiceIcebreakerState()) {
    loadPrompts();
  }

  final Ref _ref;

  Future<void> loadPrompts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        prompts: const <VoiceIcebreakerPrompt>[
          VoiceIcebreakerPrompt(
            id: 'voice-prompt-1',
            promptText: 'What does a calm Sunday look like for you?',
          ),
          VoiceIcebreakerPrompt(
            id: 'voice-prompt-2',
            promptText: 'What is one small ritual you never skip?',
          ),
          VoiceIcebreakerPrompt(
            id: 'voice-prompt-3',
            promptText: 'Tell me about a hobby that grounds you.',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/prompts',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final prompts = ((body['prompts'] as List?) ?? const <dynamic>[])
          .map(
            (item) => VoiceIcebreakerPrompt.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      state = state.copyWith(isLoading: false, prompts: prompts);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load voice icebreaker prompts', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to load voice prompts right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load voice icebreaker prompts', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load voice prompts right now.',
      );
    }
  }

  Future<void> startAndSend({
    required String matchId,
    required String receiverUserId,
    required String promptId,
    required String transcript,
    required int durationSeconds,
  }) async {
    final senderUserId = _currentUserId();
    final trimmedMatchId = matchId.trim();
    final trimmedReceiver = receiverUserId.trim();
    final trimmedPromptId = promptId.trim();
    final trimmedTranscript = transcript.trim();

    if (senderUserId == null || senderUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }
    if (trimmedMatchId.isEmpty || trimmedReceiver.isEmpty) {
      state = state.copyWith(
        error: 'Match ID and receiver user ID are required.',
      );
      return;
    }
    if (trimmedPromptId.isEmpty) {
      state = state.copyWith(error: 'Please select a voice prompt.');
      return;
    }
    if (trimmedTranscript.isEmpty) {
      state = state.copyWith(error: 'Please enter a transcript.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearLastItem: false,
    );

    if (kUseMockAuth) {
      VoiceIcebreakerPrompt? selectedPrompt;
      for (final item in state.prompts) {
        if (item.id == trimmedPromptId) {
          selectedPrompt = item;
          break;
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        lastItem: VoiceIcebreakerItem(
          id: 'voice-${DateTime.now().millisecondsSinceEpoch}',
          matchId: trimmedMatchId,
          senderUserId: senderUserId,
          receiverUserId: trimmedReceiver,
          promptId: trimmedPromptId,
          promptText: selectedPrompt?.promptText ?? 'Guided prompt',
          transcript: trimmedTranscript,
          durationSeconds: durationSeconds,
          status: 'sent',
          playCount: 0,
        ),
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final startResponse = await dio.post<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/start',
        data: <String, dynamic>{
          'match_id': trimmedMatchId,
          'sender_user_id': senderUserId,
          'receiver_user_id': trimmedReceiver,
          'prompt_id': trimmedPromptId,
        },
      );
      final startBody =
          (startResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final started =
          (startBody['voice_icebreaker'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final icebreakerId = started['id']?.toString() ?? '';
      if (icebreakerId.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Unable to create voice icebreaker session.',
        );
        return;
      }

      final sendResponse = await dio.post<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/$icebreakerId/send',
        data: <String, dynamic>{
          'sender_user_id': senderUserId,
          'duration_seconds': durationSeconds,
          'transcript': trimmedTranscript,
        },
      );
      final sendBody =
          (sendResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final itemJson =
          (sendBody['voice_icebreaker'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isSubmitting: false,
        lastItem: VoiceIcebreakerItem.fromJson(itemJson),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to send voice icebreaker', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(
          e,
          fallback: 'Unable to send voice icebreaker right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to send voice icebreaker', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to send voice icebreaker right now.',
      );
    }
  }

  Future<void> markPlayed(String userIdOverride) async {
    final item = state.lastItem;
    if (item == null || item.id.isEmpty) {
      return;
    }

    final userId = userIdOverride.trim().isNotEmpty
        ? userIdOverride.trim()
        : _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'User ID is required to mark playback.');
      return;
    }

    if (kUseMockAuth) {
      state = state.copyWith(
        lastItem: VoiceIcebreakerItem(
          id: item.id,
          matchId: item.matchId,
          senderUserId: item.senderUserId,
          receiverUserId: item.receiverUserId,
          promptId: item.promptId,
          promptText: item.promptText,
          transcript: item.transcript,
          durationSeconds: item.durationSeconds,
          status: item.status,
          playCount: item.playCount + 1,
        ),
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/${item.id}/play',
        data: <String, dynamic>{'user_id': userId},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final itemJson =
          (body['voice_icebreaker'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      state = state.copyWith(lastItem: VoiceIcebreakerItem.fromJson(itemJson));
    } on DioException catch (e, stackTrace) {
      log.error('Failed to mark voice icebreaker play', e, stackTrace);
      state = state.copyWith(
        error: _extractApiError(
          e,
          fallback: 'Unable to mark playback right now.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to mark voice icebreaker play', e, stackTrace);
      state = state.copyWith(error: 'Unable to mark playback right now.');
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

final voiceIcebreakerProvider =
    StateNotifierProvider<VoiceIcebreakerNotifier, VoiceIcebreakerState>(
      VoiceIcebreakerNotifier.new,
    );
