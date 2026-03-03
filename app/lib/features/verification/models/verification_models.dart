import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_models.freezed.dart';
part 'verification_models.g.dart';

/// ID verification for user
@freezed
class Verification with _$Verification {
  const factory Verification({
    required String id,
    required String userId,
    @Default('pending') String status, // pending, verified, rejected
    String? idPhotoPath,
    String? selfiePhotoPath,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    @Default(0) int retryCount,
    DateTime? expiresAt,
    String? verifiedBy,
  }) = _Verification;

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);
}

/// User report/complaint
@freezed
class Report with _$Report {
  const factory Report({
    required String id,
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required DateTime createdAt,
    String? messageId,
    String? description,
    @Default('pending') String status, // pending, under_review, resolved
    DateTime? reviewedAt,
    String? reviewedBy,
    String? action,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
}

/// Safety flag on user
@freezed
class SafetyFlag with _$SafetyFlag {
  const factory SafetyFlag({
    required String id,
    required String userId,
    required DateTime createdAt,
    @Default('suspicious')
    String flagType, // suspicious, fake_profile, harassment
    @Default('medium') String severity, // low, medium, high
    String? description,
    @Default(false) bool isResolved,
    String? action,
    DateTime? actionedAt,
  }) = _SafetyFlag;

  factory SafetyFlag.fromJson(Map<String, dynamic> json) =>
      _$SafetyFlagFromJson(json);
}
