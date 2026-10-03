import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_error_message.dart';

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

/// The appeal status in the reader's language: pass [l] from the widget
/// showing it (English when omitted). Unknown statuses are shown as sent.
String appealStatusLabel(String status, [AppLocalizations? l]) {
  final strings = l ?? lookupAppLocalizations(const Locale('en'));
  switch (status.trim()) {
    case 'submitted':
      return strings.engagementAppealStatusSubmitted;
    case 'under_review':
      return strings.engagementAppealStatusUnderReview;
    case 'resolved_upheld':
      return strings.engagementAppealStatusResolvedUpheld;
    case 'resolved_reversed':
      return strings.engagementAppealStatusResolvedReversed;
    default:
      return status;
  }
}

/// The member's appeals. Per member: signing out, or someone else signing in
/// on this device, drops the list instead of showing it to the next member.
final moderationAppealsProvider =
    AsyncNotifierProvider<
      ModerationAppealsNotifier,
      List<ModerationAppealItem>
    >(ModerationAppealsNotifier.new);

class ModerationAppealsNotifier
    extends AsyncNotifier<List<ModerationAppealItem>> {
  @override
  Future<List<ModerationAppealItem>> build() async {
    final userId = watchSignedInUserId(ref)?.trim() ?? '';
    if (userId.isEmpty) {
      return const <ModerationAppealItem>[];
    }
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

    final previous = state.valueOrNull ?? const <ModerationAppealItem>[];
    Response<Map<String, dynamic>> response;
    try {
      final dio = ref.read(apiClientProvider);
      response = await dio.post<Map<String, dynamic>>(
        '/moderation/appeals',
        data: {
          'user_id': userId,
          'report_id': reportId,
          'reason': trimmedReason,
          'description': description,
        },
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to submit moderation appeal', e, stackTrace);
      throw StateError(
        serverErrorMessage(e, fallback: 'Failed to submit moderation appeal'),
      );
    }
    // The appeal is filed. If the list cannot be re-read right now, show the
    // one the server returned instead of reporting a failure (which would
    // invite a duplicate appeal).
    try {
      state = AsyncData(await _fetchAppeals(userId));
    } on Object {
      final raw = (response.data?['appeal'] as Map?)?.cast<String, dynamic>();
      final filed = raw == null ? null : ModerationAppealItem.fromJson(raw);
      state = AsyncData([
        if (filed != null && filed.id.isNotEmpty) filed,
        ...previous.where((item) => item.id != filed?.id),
      ]);
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
    } catch (e, stackTrace) {
      // Surface the failure: an empty list would tell the member they have
      // no appeals, and a refresh would silently show stale statuses.
      log.error('Failed to load moderation appeals', e, stackTrace);
      rethrow;
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
