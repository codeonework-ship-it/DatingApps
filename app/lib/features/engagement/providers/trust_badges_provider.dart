import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class TrustBadgeItem {
  const TrustBadgeItem({
    required this.code,
    required this.label,
    required this.status,
    required this.awardedAt,
  });
  final String code;
  final String label;
  final String status;
  final String awardedAt;
}

class TrustBadgeHistoryItem {
  const TrustBadgeHistoryItem({
    required this.code,
    required this.action,
    required this.reason,
    required this.happenedAt,
  });
  final String code;
  final String action;
  final String reason;
  final String happenedAt;
}

class TrustBadgesState {
  const TrustBadgesState({
    this.isLoading = false,
    this.error,
    this.milestones = const <String, dynamic>{},
    this.badges = const <TrustBadgeItem>[],
    this.history = const <TrustBadgeHistoryItem>[],
  });
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> milestones;
  final List<TrustBadgeItem> badges;
  final List<TrustBadgeHistoryItem> history;

  TrustBadgesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? milestones,
    List<TrustBadgeItem>? badges,
    List<TrustBadgeHistoryItem>? history,
  }) => TrustBadgesState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    milestones: milestones ?? this.milestones,
    badges: badges ?? this.badges,
    history: history ?? this.history,
  );
}

class TrustBadgesNotifier extends StateNotifier<TrustBadgesState> {
  TrustBadgesNotifier(this._ref) : super(const TrustBadgesState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        milestones: const <String, dynamic>{},
        badges: const <TrustBadgeItem>[],
        history: const <TrustBadgeHistoryItem>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        milestones: const <String, dynamic>{
          'profile_depth_score': 72,
          'communication_score': 81,
          'consistency_score': 76,
          'safety_score': 94,
        },
        badges: const <TrustBadgeItem>[
          TrustBadgeItem(
            code: 'respectful_communicator',
            label: 'Respectful Communicator',
            status: 'active',
            awardedAt: '2026-03-01T10:00:00Z',
          ),
        ],
        history: const <TrustBadgeHistoryItem>[
          TrustBadgeHistoryItem(
            code: 'respectful_communicator',
            action: 'awarded',
            reason: 'Maintained high communication quality.',
            happenedAt: '2026-03-01T10:00:00Z',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/trust-badges',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final milestones =
          (body['milestones'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final badgesRaw = (body['badges'] as List?) ?? const [];
      final historyRaw = (body['history'] as List?) ?? const [];

      state = state.copyWith(
        isLoading: false,
        milestones: milestones,
        badges: badgesRaw
            .whereType<Map>()
            .map((entry) {
              final map = entry.cast<String, dynamic>();
              return TrustBadgeItem(
                code: map['badge_code']?.toString() ?? '',
                label: map['badge_label']?.toString() ?? 'Unknown badge',
                status: map['status']?.toString() ?? 'inactive',
                awardedAt: map['awarded_at']?.toString() ?? '',
              );
            })
            .where((item) => item.code.isNotEmpty)
            .toList(growable: false),
        history: historyRaw
            .whereType<Map>()
            .map((entry) {
              final map = entry.cast<String, dynamic>();
              return TrustBadgeHistoryItem(
                code: map['badge_code']?.toString() ?? '',
                action: map['action']?.toString() ?? 'updated',
                reason: map['reason']?.toString() ?? '',
                happenedAt: map['happened_at']?.toString() ?? '',
              );
            })
            .where((item) => item.code.isNotEmpty)
            .toList(growable: false),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load trust badges', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to load trust badges. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load trust badges', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trust badges. Please try again.',
      );
    }
  }
}

final trustBadgesProvider =
    StateNotifierProvider<TrustBadgesNotifier, TrustBadgesState>(
      TrustBadgesNotifier.new,
    );

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
