import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../engagement_l10n.dart';

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
    required this.moderationStatus,
    required this.playCount,
    this.audioUrl,
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
        moderationStatus: json['moderation_status']?.toString() ?? '',
        playCount: (json['play_count'] as num?)?.toInt() ?? 0,
        audioUrl: json['audio_url']?.toString(),
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
  final String moderationStatus;
  final int playCount;
  final String? audioUrl;
}

class VoiceIcebreakerState {
  const VoiceIcebreakerState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isPlaying = false,
    this.prompts = const <VoiceIcebreakerPrompt>[],
    this.lastItem,
    this.error,
  });

  final bool isLoading;
  final bool isSubmitting;
  final bool isPlaying;
  final List<VoiceIcebreakerPrompt> prompts;
  final VoiceIcebreakerItem? lastItem;
  final String? error;

  VoiceIcebreakerState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isPlaying,
    List<VoiceIcebreakerPrompt>? prompts,
    VoiceIcebreakerItem? lastItem,
    bool clearLastItem = false,
    String? error,
    bool clearError = false,
  }) => VoiceIcebreakerState(
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isPlaying: isPlaying ?? this.isPlaying,
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
  AudioPlayer? _player;

  AppLocalizations get _l => engagementL10nFor(_ref);

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
      if (!mounted) return;
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
      if (!mounted) return;
      log.error('Failed to load voice icebreaker prompts', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: _l.engagementVoicePromptsLoadFailed,
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      log.error('Failed to load voice icebreaker prompts', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _l.engagementVoicePromptsLoadFailed,
      );
    }
  }

  Future<void> startAndSend({
    required String matchId,
    required String receiverUserId,
    required String promptId,
    required String transcript,
    required int durationSeconds,
    required XFile audioFile,
  }) async {
    final senderUserId = _currentUserId();
    final trimmedMatchId = matchId.trim();
    final trimmedReceiver = receiverUserId.trim();
    final trimmedPromptId = promptId.trim();
    final trimmedTranscript = transcript.trim();

    if (senderUserId == null || senderUserId.isEmpty) {
      state = state.copyWith(error: _l.engagementSessionUnavailable);
      return;
    }
    if (trimmedMatchId.isEmpty || trimmedReceiver.isEmpty) {
      state = state.copyWith(error: _l.engagementVoiceChooseConversation);
      return;
    }
    if (trimmedPromptId.isEmpty) {
      state = state.copyWith(error: _l.engagementVoiceSelectPrompt);
      return;
    }
    if (trimmedTranscript.isEmpty) {
      state = state.copyWith(error: _l.engagementVoiceEnterTranscript);
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearLastItem: true,
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
          moderationStatus: 'approved',
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
      if (!mounted) return;
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
          error: _l.engagementVoiceSessionFailed,
        );
        return;
      }

      final sendResponse = await dio.post<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/$icebreakerId/send',
        data: FormData.fromMap(<String, dynamic>{
          'sender_user_id': senderUserId,
          'duration_seconds': durationSeconds,
          'transcript': trimmedTranscript,
          'audio': MultipartFile.fromBytes(
            await audioFile.readAsBytes(),
            filename: audioFile.name.trim().isEmpty
                ? 'voice-message.webm'
                : audioFile.name,
          ),
        }),
      );
      if (!mounted) return;
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
      if (!mounted) return;
      log.error('Failed to send voice icebreaker', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _extractApiError(e, fallback: _l.engagementVoiceSendFailed),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      log.error('Failed to send voice icebreaker', e, stackTrace);
      state = state.copyWith(
        isSubmitting: false,
        error: _l.engagementVoiceSendFailed,
      );
    }
  }

  Future<void> playLatest() => play(state.lastItem);

  Future<void> play(VoiceIcebreakerItem? item) async {
    if (state.isPlaying || item == null || item.id.isEmpty) {
      return;
    }

    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: _l.engagementVoicePlaybackUserRequired);
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
          moderationStatus: item.moderationStatus,
          playCount: item.playCount + 1,
          audioUrl: item.audioUrl,
        ),
      );
      return;
    }

    state = state.copyWith(isPlaying: true, clearError: true);
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/engagement/voice-icebreakers/${item.id}/play',
        data: <String, dynamic>{'user_id': userId},
      );
      if (!mounted) return;
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final itemJson =
          (body['voice_icebreaker'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final updated = VoiceIcebreakerItem.fromJson(itemJson);
      final audioUrl = updated.audioUrl?.trim() ?? '';
      if (audioUrl.isEmpty) {
        throw StateError('Playback URL was not returned.');
      }
      state = state.copyWith(lastItem: updated, isPlaying: true);
      final player = _player ??= AudioPlayer();
      await player.setUrl(audioUrl);
      if (!mounted) return;
      await player.play();
      if (!mounted) return;
      state = state.copyWith(isPlaying: false);
    } on DioException catch (e, stackTrace) {
      if (!mounted) return;
      log.error('Failed to mark voice icebreaker play', e, stackTrace);
      state = state.copyWith(
        isPlaying: false,
        error: _extractApiError(
          e,
          fallback: _l.engagementVoiceMarkPlaybackFailed,
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      log.error('Failed to mark voice icebreaker play', e, stackTrace);
      state = state.copyWith(
        isPlaying: false,
        error: _l.engagementVoicePlayFailed,
      );
    }
  }

  Future<void> stopPlaying() async {
    await _player?.stop();
    if (mounted) state = state.copyWith(isPlaying: false);
  }

  String? _currentUserId() {
    final userId = _ref.read(authNotifierProvider).userId;
    return userId?.trim().isEmpty == true ? null : userId;
  }

  @override
  void dispose() {
    if (_player != null) unawaited(_player!.dispose());
    super.dispose();
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
    StateNotifierProvider.autoDispose<
      VoiceIcebreakerNotifier,
      VoiceIcebreakerState
    >((ref) {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      return VoiceIcebreakerNotifier(ref);
    });

final voiceIntroductionsProvider = FutureProvider.autoDispose
    .family<List<VoiceIcebreakerItem>, String>((ref, matchId) async {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/matches/$matchId/voice-introductions');
      return ((response.data as Map)['introductions'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((v) => VoiceIcebreakerItem.fromJson(v.cast<String, dynamic>()))
          .toList();
    });
