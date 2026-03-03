import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class TrustBadgeOption {
  const TrustBadgeOption({required this.code, required this.label});
  final String code;
  final String label;
}

class TrustFilterState {
  const TrustFilterState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.enabled = false,
    this.minimumActiveBadges = 0,
    this.requiredBadgeCodes = const <String>[],
    this.availableBadges = const <TrustBadgeOption>[
      TrustBadgeOption(code: 'prompt_completer', label: 'Prompt Completer'),
      TrustBadgeOption(
        code: 'respectful_communicator',
        label: 'Respectful Communicator',
      ),
      TrustBadgeOption(code: 'consistent_profile', label: 'Consistent Profile'),
      TrustBadgeOption(code: 'verified_active', label: 'Verified & Active'),
    ],
  });
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool enabled;
  final int minimumActiveBadges;
  final List<String> requiredBadgeCodes;
  final List<TrustBadgeOption> availableBadges;

  bool get hasActiveFilter =>
      enabled && (minimumActiveBadges > 0 || requiredBadgeCodes.isNotEmpty);

  TrustFilterState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool? enabled,
    int? minimumActiveBadges,
    List<String>? requiredBadgeCodes,
    List<TrustBadgeOption>? availableBadges,
  }) => TrustFilterState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : (error ?? this.error),
    enabled: enabled ?? this.enabled,
    minimumActiveBadges: minimumActiveBadges ?? this.minimumActiveBadges,
    requiredBadgeCodes: requiredBadgeCodes ?? this.requiredBadgeCodes,
    availableBadges: availableBadges ?? this.availableBadges,
  );
}

class TrustFilterNotifier extends StateNotifier<TrustFilterState> {
  TrustFilterNotifier(this._ref) : super(const TrustFilterState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    final userID = _ref.read(authNotifierProvider).userId;
    if (userID == null || userID.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        enabled: false,
        minimumActiveBadges: 0,
        requiredBadgeCodes: const <String>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/discovery/$userID/filters/trust',
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final trustFilter =
          (body['trust_filter'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final availableRaw = (body['available_badges'] as List?) ?? const [];

      state = state.copyWith(
        isLoading: false,
        enabled: trustFilter['enabled'] == true,
        minimumActiveBadges:
            (trustFilter['minimum_active_badges'] as num?)?.toInt() ?? 0,
        requiredBadgeCodes: _asStringList(trustFilter['required_badge_codes']),
        availableBadges: availableRaw
            .whereType<Map<String, dynamic>>()
            .map((item) {
              final map = item;
              return TrustBadgeOption(
                code: map['badge_code']?.toString() ?? '',
                label: map['badge_label']?.toString() ?? '',
              );
            })
            .where((item) => item.code.isNotEmpty && item.label.isNotEmpty)
            .toList(growable: false),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load trust filter', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to load trust filters. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load trust filter', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trust filters. Please try again.',
      );
    }
  }

  Future<void> save({
    required bool enabled,
    required int minimumActiveBadges,
    required List<String> requiredBadgeCodes,
  }) async {
    final userID = _ref.read(authNotifierProvider).userId;
    if (userID == null || userID.trim().isEmpty) {
      return;
    }

    final normalized =
        requiredBadgeCodes
            .map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      enabled: enabled,
      minimumActiveBadges: minimumActiveBadges,
      requiredBadgeCodes: normalized,
    );

    if (kUseMockAuth) {
      state = state.copyWith(isSaving: false);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.patch<Map<String, dynamic>>(
        '/discovery/$userID/filters/trust',
        data: {
          'enabled': enabled,
          'minimum_active_badges': minimumActiveBadges,
          'required_badge_codes': normalized,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final trustFilter =
          (body['trust_filter'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isSaving: false,
        enabled: trustFilter['enabled'] == true,
        minimumActiveBadges:
            (trustFilter['minimum_active_badges'] as num?)?.toInt() ??
            minimumActiveBadges,
        requiredBadgeCodes: _asStringList(trustFilter['required_badge_codes']),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to save trust filter', e, stackTrace);
      state = state.copyWith(
        isSaving: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to save trust filters. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to save trust filter', e, stackTrace);
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save trust filters. Please try again.',
      );
    }
  }
}

final trustFilterNotifierProvider =
    StateNotifierProvider<TrustFilterNotifier, TrustFilterState>(
      TrustFilterNotifier.new,
    );

List<String> _asStringList(dynamic raw) {
  final list = (raw as List?) ?? const [];
  return list.map((entry) => entry.toString()).toList(growable: false);
}

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
