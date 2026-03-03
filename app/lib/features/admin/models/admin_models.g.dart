// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminUserImpl _$$AdminUserImplFromJson(Map<String, dynamic> json) =>
    _$AdminUserImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String? ?? 'moderator',
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      isActive: json['isActive'] as bool? ?? true,
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AdminUserImplToJson(_$AdminUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'role': instance.role,
      'permissions': instance.permissions,
      'email': instance.email,
      'passwordHash': instance.passwordHash,
      'isActive': instance.isActive,
      'lastLogin': instance.lastLogin?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String?,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'isRead': instance.isRead,
      'readAt': instance.readAt?.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ActivityLogImpl _$$ActivityLogImplFromJson(Map<String, dynamic> json) =>
    _$ActivityLogImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      action: json['action'] as String,
      resourceType: json['resourceType'] as String?,
      resourceId: json['resourceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ActivityLogImplToJson(_$ActivityLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'action': instance.action,
      'resourceType': instance.resourceType,
      'resourceId': instance.resourceId,
      'metadata': instance.metadata,
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$AnalyticsMetricsImpl _$$AnalyticsMetricsImplFromJson(
  Map<String, dynamic> json,
) => _$AnalyticsMetricsImpl(
  id: json['id'] as String,
  metricDate: DateTime.parse(json['metricDate'] as String),
  metricType: json['metricType'] as String? ?? 'daily',
  totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
  activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
  newUsers: (json['newUsers'] as num?)?.toInt() ?? 0,
  totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
  totalSwipes: (json['totalSwipes'] as num?)?.toInt() ?? 0,
  totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
  verificationRate: (json['verificationRate'] as num?)?.toDouble() ?? 0.0,
  premiumConversion: (json['premiumConversion'] as num?)?.toDouble() ?? 0.0,
  averageSessionTime: (json['averageSessionTime'] as num?)?.toInt() ?? 0,
  reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$AnalyticsMetricsImplToJson(
  _$AnalyticsMetricsImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'metricDate': instance.metricDate.toIso8601String(),
  'metricType': instance.metricType,
  'totalUsers': instance.totalUsers,
  'activeUsers': instance.activeUsers,
  'newUsers': instance.newUsers,
  'totalMatches': instance.totalMatches,
  'totalSwipes': instance.totalSwipes,
  'totalMessages': instance.totalMessages,
  'verificationRate': instance.verificationRate,
  'premiumConversion': instance.premiumConversion,
  'averageSessionTime': instance.averageSessionTime,
  'reportCount': instance.reportCount,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
};
