import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class ModerationAppealItem {

  factory ModerationAppealItem.fromJson(Map<String, dynamic> json) {
    return ModerationAppealItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'submitted',
      slaDeadlineAt: json['sla_deadline_at']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      reportId: json['report_id']?.toString(),
      description: json['description']?.toString(),
      resolutionReason: json['resolution_reason']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: json['reviewed_at']?.toString(),
    );
  }
  const ModerationAppealItem({
    required this.id,
    required this.userId,
    required this.reason,
    required this.status,
    required this.slaDeadlineAt,
    required this.createdAt,
    this.reportId,
    this.description,
    this.resolutionReason,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String reason;
  final String status;
  final String slaDeadlineAt;
  final String createdAt;
  final String? reportId;
  final String? description;
  final String? resolutionReason;
  final String? reviewedBy;
  final String? reviewedAt;
}

String appealStatusLabel(String status) {
  switch (status.trim()) {
    case 'submitted':
      return 'Submitted';
    case 'under_review':
      return 'Under review';
    case 'resolved_upheld':
      return 'Resolved (upheld)';
    case 'resolved_reversed':
      return 'Resolved (reversed)';
    default:
      return status;
  }
}

final moderationAppealsProvider =
    AsyncNotifierProvider<
      ModerationAppealsNotifier,
      List<ModerationAppealItem>
    >(ModerationAppealsNotifier.new);

class ModerationAppealsNotifier
    extends AsyncNotifier<List<ModerationAppealItem>> {
  @override
  Future<List<ModerationAppealItem>> build() async {
    final userId = _requireUserId();
    return _fetchAppeals(userId);
  }

  Future<void> refresh() async {
    final userId = _requireUserId();
    state = AsyncData(await _fetchAppeals(userId));
  }

  Future<void> submitAppeal({
    required String reason,
    String? description,
    String? reportId,
  }) async {
    final userId = _requireUserId();
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Reason is required');
    }

    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      final existing = state.valueOrNull ?? const <ModerationAppealItem>[];
      state = AsyncData([
        ModerationAppealItem(
          id: 'apl-local-${now.millisecondsSinceEpoch}',
          userId: userId,
          reason: trimmedReason,
          status: 'submitted',
          slaDeadlineAt: now.add(const Duration(hours: 48)).toIso8601String(),
          createdAt: now.toIso8601String(),
          reportId: reportId?.trim().isEmpty == true ? null : reportId?.trim(),
          description: description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        ),
        ...existing,
      ]);
      return;
    }

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/moderation/appeals',
        data: {
          'user_id': userId,
          'report_id': reportId,
          'reason': trimmedReason,
          'description': description,
        },
      );
      state = AsyncData(await _fetchAppeals(userId));
    } on DioException catch (e, stackTrace) {
      log.error('Failed to submit moderation appeal', e, stackTrace);
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        throw StateError(data['error'].toString());
      }
      throw StateError('Failed to submit moderation appeal');
    }
  }

  Future<List<ModerationAppealItem>> _fetchAppeals(String userId) async {
    if (kUseMockAuth) {
      return state.valueOrNull ?? const <ModerationAppealItem>[];
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/moderation/appeals',
        queryParameters: {'user_id': userId, 'limit': 50},
      );
      final body = response.data ?? <String, dynamic>{};
      final rows = (body['appeals'] as List?) ?? const <dynamic>[];
      return rows
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => row.cast<String, dynamic>())
          .map(ModerationAppealItem.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load moderation appeals', e, stackTrace);
      return state.valueOrNull ?? const <ModerationAppealItem>[];
    } catch (e, stackTrace) {
      log.error('Failed to load moderation appeals', e, stackTrace);
      return state.valueOrNull ?? const <ModerationAppealItem>[];
    }
  }

  String _requireUserId() {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Not authenticated');
    }
    return userId;
  }
}
