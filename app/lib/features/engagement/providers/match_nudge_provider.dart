import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../engagement_l10n.dart';

class MatchNudge {
  const MatchNudge({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.counterpartyUserId,
    required this.nudgeType,
    required this.sentAt,
    this.clickedAt,
  });

  factory MatchNudge.fromJson(Map<String, dynamic> json) => MatchNudge(
    id: json['id']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    counterpartyUserId: json['counterparty_user_id']?.toString() ?? '',
    nudgeType: json['nudge_type']?.toString() ?? 'stalled_24h',
    sentAt:
        DateTime.tryParse(
          (json['sent_at'] ?? json['created_at'])?.toString() ?? '',
        ) ??
        DateTime.now(),
    clickedAt: DateTime.tryParse(json['clicked_at']?.toString() ?? ''),
  );

  final String id;
  final String matchId;
  final String userId;
  final String counterpartyUserId;
  final String nudgeType;
  final DateTime sentAt;
  final DateTime? clickedAt;
}

class MatchNudgeState {
  const MatchNudgeState({
    this.sendingMatchIds = const {},
    this.sentByMatchId = const {},
    this.errorByMatchId = const {},
  });

  final Set<String> sendingMatchIds;
  final Map<String, MatchNudge> sentByMatchId;
  final Map<String, String> errorByMatchId;

  MatchNudgeState copyWith({
    Set<String>? sendingMatchIds,
    Map<String, MatchNudge>? sentByMatchId,
    Map<String, String>? errorByMatchId,
  }) => MatchNudgeState(
    sendingMatchIds: sendingMatchIds ?? this.sendingMatchIds,
    sentByMatchId: sentByMatchId ?? this.sentByMatchId,
    errorByMatchId: errorByMatchId ?? this.errorByMatchId,
  );
}

class MatchNudgeNotifier extends StateNotifier<MatchNudgeState> {
  MatchNudgeNotifier(this.ref) : super(const MatchNudgeState());

  final Ref ref;

  Future<MatchNudge?> send({
    required String matchId,
    required String counterpartyUserId,
    String nudgeType = 'stalled_24h',
  }) async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return null;
    state = state.copyWith(
      sendingMatchIds: {...state.sendingMatchIds, matchId},
      errorByMatchId: {...state.errorByMatchId}..remove(matchId),
    );
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/engagement/match-nudges/send',
            data: {
              'match_id': matchId,
              'user_id': userId,
              'counterparty_user_id': counterpartyUserId,
              'nudge_type': nudgeType,
            },
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final raw = (body['nudge'] as Map?)?.cast<String, dynamic>();
      if (raw == null) throw const FormatException('Missing nudge');
      final nudge = MatchNudge.fromJson(raw);
      state = state.copyWith(
        sendingMatchIds: {...state.sendingMatchIds}..remove(matchId),
        sentByMatchId: {...state.sentByMatchId, matchId: nudge},
      );
      return nudge;
    } on Object catch (error) {
      final message = apiErrorMessage(
        error,
        fallback: engagementL10nFor(ref).engagementNudgesSendFailed,
      );
      state = state.copyWith(
        sendingMatchIds: {...state.sendingMatchIds}..remove(matchId),
        errorByMatchId: {...state.errorByMatchId, matchId: message},
      );
      return null;
    }
  }

  Future<MatchNudge?> markClicked(String nudgeId) async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return null;
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/engagement/match-nudges/$nudgeId/click',
            data: {'user_id': userId},
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final raw = (body['nudge'] as Map?)?.cast<String, dynamic>();
      return raw == null ? null : MatchNudge.fromJson(raw);
    } on Object {
      return null;
    }
  }

  Future<bool> markConversationResumed({
    required String matchId,
    required String triggerNudgeId,
  }) async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) return false;
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/engagement/matches/$matchId/resume',
            data: {'user_id': userId, 'trigger_nudge_id': triggerNudgeId},
          );
      return true;
    } on Object {
      return false;
    }
  }
}

final matchNudgeProvider =
    StateNotifierProvider<MatchNudgeNotifier, MatchNudgeState>(
      (ref) => MatchNudgeNotifier(ref),
    );
