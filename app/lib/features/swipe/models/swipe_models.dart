import 'package:freezed_annotation/freezed_annotation.dart';

part 'swipe_models.freezed.dart';
part 'swipe_models.g.dart';

/// User swipe action (like or pass)
@freezed
class Swipe with _$Swipe {
  const factory Swipe({
    required String id,
    required String userId,
    required String targetUserId,
    required DateTime createdAt,
    @Default(false) bool isLike,
  }) = _Swipe;

  factory Swipe.fromJson(Map<String, dynamic> json) => _$SwipeFromJson(json);
}

/// Mutual match between two users
@freezed
class Match with _$Match {
  const factory Match({
    required String id,
    required String userId1,
    required String userId2,
    required DateTime createdAt,
    @Default('active') String user1Status,
    @Default('active') String user2Status,
    DateTime? lastMessageAt,
    @Default(false) bool user1Blocked,
    @Default(false) bool user2Blocked,
    @Default(0) int chatCount,
  }) = _Match;

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);
}
