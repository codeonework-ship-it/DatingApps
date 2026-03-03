import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

/// Admin/moderator user
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String userId,
    required String email,
    required String passwordHash,
    @Default('moderator') String role, // admin, moderator, analyst
    @Default([]) List<String> permissions,
    @Default(true) bool isActive,
    DateTime? lastLogin,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

/// Push notification
@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String userId,
    @Default('info') String type, // info, warning, error, success
    String? title,
    String? body,
    @Default({}) Map<String, dynamic> data,
    @Default(false) bool isRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}

/// User activity log for audit
@freezed
class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    required String userId,
    required String action, // login, update_profile, send_message, etc
    String? resourceType, // user, match, message, etc
    String? resourceId,
    @Default({}) Map<String, dynamic> metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  }) = _ActivityLog;

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
}

/// Analytics metrics (daily/weekly)
@freezed
class AnalyticsMetrics with _$AnalyticsMetrics {
  const factory AnalyticsMetrics({
    required String id,
    required DateTime metricDate,
    @Default('daily') String metricType, // daily, weekly, monthly
    @Default(0) int totalUsers,
    @Default(0) int activeUsers,
    @Default(0) int newUsers,
    @Default(0) int totalMatches,
    @Default(0) int totalSwipes,
    @Default(0) int totalMessages,
    @Default(0.0) double verificationRate,
    @Default(0.0) double premiumConversion,
    @Default(0) int averageSessionTime,
    @Default(0) int reportCount,
    @Default({}) Map<String, dynamic> metadata,
    DateTime? createdAt,
  }) = _AnalyticsMetrics;

  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsMetricsFromJson(json);
}
