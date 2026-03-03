// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwipeImpl _$$SwipeImplFromJson(Map<String, dynamic> json) => _$SwipeImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  targetUserId: json['targetUserId'] as String,
  isLike: json['isLike'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$SwipeImplToJson(_$SwipeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'targetUserId': instance.targetUserId,
      'isLike': instance.isLike,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$MatchImpl _$$MatchImplFromJson(Map<String, dynamic> json) => _$MatchImpl(
  id: json['id'] as String,
  userId1: json['userId1'] as String,
  userId2: json['userId2'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  user1Status: json['user1Status'] as String? ?? 'active',
  user2Status: json['user2Status'] as String? ?? 'active',
  lastMessageAt: json['lastMessageAt'] == null
      ? null
      : DateTime.parse(json['lastMessageAt'] as String),
  user1Blocked: json['user1Blocked'] as bool? ?? false,
  user2Blocked: json['user2Blocked'] as bool? ?? false,
  chatCount: (json['chatCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$MatchImplToJson(_$MatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId1': instance.userId1,
      'userId2': instance.userId2,
      'createdAt': instance.createdAt.toIso8601String(),
      'user1Status': instance.user1Status,
      'user2Status': instance.user2Status,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'user1Blocked': instance.user1Blocked,
      'user2Blocked': instance.user2Blocked,
      'chatCount': instance.chatCount,
    };
