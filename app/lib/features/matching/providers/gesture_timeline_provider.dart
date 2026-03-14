import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class GestureTimelineItem {
  const GestureTimelineItem({
    required this.id,
    required this.matchId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.gestureType,
    required this.contentText,
    required this.tone,
    required this.status,
    required this.effortScore,
    required this.minimumQualityPass,
    required this.originalityPass,
    required this.profanityFlagged,
    required this.safetyFlagged,
    required this.createdAt,
  });

  factory GestureTimelineItem.fromJson(Map<String, dynamic> json) => GestureTimelineItem(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      senderUserId: json['sender_user_id']?.toString() ?? '',
      receiverUserId: json['receiver_user_id']?.toString() ?? '',
      gestureType: json['gesture_type']?.toString() ?? '',
      contentText: json['content_text']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'neutral',
      status: json['status']?.toString() ?? 'sent',
      effortScore: (json['effort_score'] as num?)?.toInt() ?? 0,
      minimumQualityPass: json['minimum_quality_pass'] == true,
      originalityPass: json['originality_pass'] == true,
      profanityFlagged: json['profanity_flagged'] == true,
      safetyFlagged: json['safety_flagged'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  final String id;
  final String matchId;
  final String senderUserId;
  final String receiverUserId;
  final String gestureType;
  final String contentText;
  final String tone;
  final String status;
  final int effortScore;
  final bool minimumQualityPass;
  final bool originalityPass;
  final bool profanityFlagged;
  final bool safetyFlagged;
  final DateTime createdAt;
}

class GestureTimelineState {
  const GestureTimelineState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  final List<GestureTimelineItem> items;
  final bool isLoading;
  final String? error;

  GestureTimelineState copyWith({
    List<GestureTimelineItem>? items,
    bool? isLoading,
    String? error,
  }) => GestureTimelineState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class GestureTimelineNotifier extends StateNotifier<GestureTimelineState> {
  GestureTimelineNotifier(this._ref, this._matchId)
    : super(const GestureTimelineState(isLoading: true)) {
    Future<void>.microtask(loadTimeline);
  }

  final Ref _ref;
  final String _matchId;

  Future<void> loadTimeline() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kUseMockAuth) {
        state = state.copyWith(isLoading: false, items: const []);
        return;
      }

      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/matches/$_matchId/timeline',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final raw = (body['timeline'] as List?) ?? const [];
      final items = raw
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                GestureTimelineItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList();

      state = state.copyWith(isLoading: false, items: items, error: null);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load gesture timeline', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load timeline',
      );
    } catch (e, stackTrace) {
      log.error('Failed to load gesture timeline', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load timeline',
      );
    }
  }

  Future<void> createGesture({
    required String receiverUserId,
    required String gestureType,
    required String contentText,
    required String tone,
  }) async {
    final senderUserId = _ref.read(authNotifierProvider).userId;
    if (senderUserId == null || senderUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/matches/$_matchId/gestures',
        data: {
          'sender_user_id': senderUserId,
          'receiver_user_id': receiverUserId,
          'gesture_type': gestureType,
          'content_text': contentText,
          'tone': tone,
        },
      );
      await loadTimeline();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to create gesture', e, stackTrace);
      state = state.copyWith(error: 'Failed to send gesture.');
    } catch (e, stackTrace) {
      log.error('Failed to create gesture', e, stackTrace);
      state = state.copyWith(error: 'Failed to send gesture.');
    }
  }

  Future<void> decideGesture({
    required String gestureId,
    required String decision,
    String reason = '',
  }) async {
    final reviewerUserId = _ref.read(authNotifierProvider).userId;
    if (reviewerUserId == null || reviewerUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/matches/$_matchId/gestures/$gestureId/decision',
        data: {
          'reviewer_user_id': reviewerUserId,
          'decision': decision,
          if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      await loadTimeline();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to decide gesture', e, stackTrace);
      state = state.copyWith(error: 'Failed to update gesture status.');
    } catch (e, stackTrace) {
      log.error('Failed to decide gesture', e, stackTrace);
      state = state.copyWith(error: 'Failed to update gesture status.');
    }
  }
}

final gestureTimelineProvider =
    StateNotifierProvider.family<
      GestureTimelineNotifier,
      GestureTimelineState,
      String
    >(GestureTimelineNotifier.new);
