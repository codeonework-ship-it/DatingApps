import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../config/feature_flags.dart';
import '../i18n/app_l10n.dart';
import 'api_client_provider.dart';
import '../network/api_error_message.dart';

final safetyActionsProvider = Provider<SafetyActions>(SafetyActions.new);

class SafetyActions {
  SafetyActions(this._ref);
  final Ref _ref;

  Future<String?> reportUser({
    required String reportedUserId,
    required String reason, // harassment|inappropriate|fraud|fake
    String? description,
    String? messageId,
  }) async {
    if (kUseMockAuth) return null;

    final currentUserId = _ref.read(authNotifierProvider).userId;
    if (currentUserId == null) {
      throw StateError(appL10nOf(_ref).safetyNotAuthenticated);
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/safety/report',
        data: {
          'reporter_user_id': currentUserId,
          'reported_user_id': reportedUserId,
          'reason': reason,
          'description': description,
          'message_id': messageId,
        },
      );
      final body = response.data ?? <String, dynamic>{};
      final report = (body['report'] as Map?)?.cast<String, dynamic>();
      final reportId = report?['id']?.toString();
      return reportId == null || reportId.trim().isEmpty ? null : reportId;
    } on DioException catch (e) {
      throw StateError(
        serverErrorMessage(e, fallback: appL10nOf(_ref).safetyReportFailed),
      );
    }
  }

  Future<void> blockUser({required String blockedUserId}) async {
    if (kUseMockAuth) return;

    final currentUserId = _ref.read(authNotifierProvider).userId;
    if (currentUserId == null) {
      throw StateError(appL10nOf(_ref).safetyNotAuthenticated);
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/safety/block',
        data: {'user_id': currentUserId, 'blocked_user_id': blockedUserId},
      );
    } on DioException {
      throw StateError(appL10nOf(_ref).safetyBlockFailed);
    }
  }

  Future<void> unblockUser({required String blockedUserId}) async {
    if (kUseMockAuth) return;

    final currentUserId = _ref.read(authNotifierProvider).userId;
    if (currentUserId == null) {
      throw StateError(appL10nOf(_ref).safetyNotAuthenticated);
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/safety/unblock',
        data: {'user_id': currentUserId, 'blocked_user_id': blockedUserId},
      );
    } on DioException {
      throw StateError(appL10nOf(_ref).safetyUnblockFailed);
    }
  }
}
