// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VerificationImpl _$$VerificationImplFromJson(Map<String, dynamic> json) =>
    _$VerificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String? ?? 'pending',
      idPhotoPath: json['idPhotoPath'] as String?,
      selfiePhotoPath: json['selfiePhotoPath'] as String?,
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      verifiedBy: json['verifiedBy'] as String?,
    );

Map<String, dynamic> _$$VerificationImplToJson(_$VerificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'status': instance.status,
      'idPhotoPath': instance.idPhotoPath,
      'selfiePhotoPath': instance.selfiePhotoPath,
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'rejectionReason': instance.rejectionReason,
      'retryCount': instance.retryCount,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
    };

_$ReportImpl _$$ReportImplFromJson(Map<String, dynamic> json) => _$ReportImpl(
  id: json['id'] as String,
  reporterId: json['reporterId'] as String,
  reportedUserId: json['reportedUserId'] as String,
  messageId: json['messageId'] as String?,
  reason: json['reason'] as String,
  description: json['description'] as String?,
  status: json['status'] as String? ?? 'pending',
  createdAt: DateTime.parse(json['createdAt'] as String),
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
  reviewedBy: json['reviewedBy'] as String?,
  action: json['action'] as String?,
);

Map<String, dynamic> _$$ReportImplToJson(_$ReportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'reportedUserId': instance.reportedUserId,
      'messageId': instance.messageId,
      'reason': instance.reason,
      'description': instance.description,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewedBy': instance.reviewedBy,
      'action': instance.action,
    };

_$SafetyFlagImpl _$$SafetyFlagImplFromJson(Map<String, dynamic> json) =>
    _$SafetyFlagImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      flagType: json['flagType'] as String? ?? 'suspicious',
      severity: json['severity'] as String? ?? 'medium',
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isResolved: json['isResolved'] as bool? ?? false,
      action: json['action'] as String?,
      actionedAt: json['actionedAt'] == null
          ? null
          : DateTime.parse(json['actionedAt'] as String),
    );

Map<String, dynamic> _$$SafetyFlagImplToJson(_$SafetyFlagImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'flagType': instance.flagType,
      'severity': instance.severity,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'isResolved': instance.isResolved,
      'action': instance.action,
      'actionedAt': instance.actionedAt?.toIso8601String(),
    };
