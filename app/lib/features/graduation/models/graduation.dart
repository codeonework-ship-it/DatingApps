/// Graduation: a matched pair leaves Connect together and the product
/// celebrates it. Mirrors `matching.match_graduations` and
/// `user_management.discovery_pauses`.
library;

/// Which graduation or discovery-pause request failed. Providers set it when
/// the server sent no message of its own, so widgets can show the fallback in
/// the member's language (see `graduation_labels.dart`).
enum GraduationFailure {
  load,
  propose,
  confirm,
  decline,
  withdraw,
  pauseLoad,
  pause,
  resume,
}

class GraduationReward {
  const GraduationReward({
    required this.userId,
    required this.kind,
    required this.status,
  });

  factory GraduationReward.fromJson(Map<String, dynamic> json) =>
      GraduationReward(
        userId: json['user_id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
      );

  final String userId;
  final String kind;
  final String status;
}

class Graduation {
  const Graduation({
    required this.id,
    required this.matchId,
    required this.proposerUserId,
    required this.partnerUserId,
    required this.status,
    required this.viewerRole,
    required this.otherUserId,
    required this.otherName,
    required this.nextAction,
    this.note = '',
    this.proposerShareWithFriends = false,
    this.partnerShareWithFriends = false,
    this.shareWithFriends = false,
    this.decidedAt,
    this.createdAt,
    this.friendRecipients = 0,
    this.rewards = const <GraduationReward>[],
  });

  factory Graduation.fromJson(Map<String, dynamic> json) => Graduation(
    id: json['id']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    proposerUserId: json['proposer_user_id']?.toString() ?? '',
    partnerUserId: json['partner_user_id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'proposed',
    note: json['note']?.toString() ?? '',
    proposerShareWithFriends:
        json['proposer_share_with_friends'] as bool? ?? false,
    partnerShareWithFriends:
        json['partner_share_with_friends'] as bool? ?? false,
    shareWithFriends: json['share_with_friends'] as bool? ?? false,
    decidedAt: _parseTime(json['decided_at']),
    createdAt: _parseTime(json['created_at']),
    viewerRole: json['viewer_role']?.toString() ?? 'observer',
    otherUserId: json['other_user_id']?.toString() ?? '',
    otherName: json['other_name']?.toString() ?? '',
    nextAction: json['next_action']?.toString() ?? 'none',
    friendRecipients: (json['friend_recipients'] as num?)?.toInt() ?? 0,
    rewards: (json['rewards'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => GraduationReward.fromJson(row.cast<String, dynamic>()))
        .toList(),
  );

  final String id;
  final String matchId;
  final String proposerUserId;
  final String partnerUserId;
  final String status;
  final String note;
  final bool proposerShareWithFriends;
  final bool partnerShareWithFriends;

  /// The viewer's own share choice.
  final bool shareWithFriends;
  final DateTime? decidedAt;
  final DateTime? createdAt;
  final String viewerRole;
  final String otherUserId;
  final String otherName;
  final String nextAction;
  final int friendRecipients;
  final List<GraduationReward> rewards;

  bool get isOpen => status == 'proposed';
  bool get isConfirmed => status == 'confirmed';
  bool get viewerIsProposer => viewerRole == 'proposer';
  bool get viewerIsPartner => viewerRole == 'partner';
  bool get viewerDecides => nextAction == 'decide';
}

/// What `GET /matches/{id}/graduation` returns.
class MatchGraduationSnapshot {
  const MatchGraduationSnapshot({
    this.graduation,
    this.history = const <Graduation>[],
    this.canPropose = false,
    this.graduated = false,
    this.unlockState = '',
    this.discoveryPaused = false,
  });

  factory MatchGraduationSnapshot.fromJson(Map<String, dynamic> json) {
    final current = json['graduation'];
    return MatchGraduationSnapshot(
      graduation: current is Map<dynamic, dynamic>
          ? Graduation.fromJson(current.cast<String, dynamic>())
          : null,
      history: (json['history'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => Graduation.fromJson(row.cast<String, dynamic>()))
          .toList(),
      canPropose: json['can_propose'] as bool? ?? false,
      graduated: json['graduated'] as bool? ?? false,
      unlockState: json['unlock_state']?.toString() ?? '',
      discoveryPaused: json['discovery_paused'] as bool? ?? false,
    );
  }

  final Graduation? graduation;
  final List<Graduation> history;
  final bool canPropose;
  final bool graduated;
  final String unlockState;
  final bool discoveryPaused;
}

/// The member's own discovery pause, from the account routes.
class DiscoveryPause {
  const DiscoveryPause({
    required this.reason,
    required this.pausedAt,
    this.resumedAt,
  });

  factory DiscoveryPause.fromJson(Map<String, dynamic> json) => DiscoveryPause(
    reason: json['reason']?.toString() ?? 'manual',
    pausedAt:
        _parseTime(json['paused_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    resumedAt: _parseTime(json['resumed_at']),
  );

  final String reason;
  final DateTime pausedAt;
  final DateTime? resumedAt;

  bool get isActive => resumedAt == null;
  bool get isGraduation => reason == 'graduated';
}

DateTime? _parseTime(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toUtc();
}
