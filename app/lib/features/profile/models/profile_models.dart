import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// User profile model
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required DateTime createdAt,
    String? bio,
    int? heightCm,
    String? education,
    String? profession,
    String? incomeRange,
    String? drinking,
    String? smoking,
    String? religion,
    @Default(0) int profileCompletion,
    @Default(false) bool isVerified,
    @Default(false) bool verificationBadge,
    DateTime? lastLogin,
    @Default(true) bool isActive,
    @Default(false) bool isBlocked,
    @Default([]) List<String> blockedUsers,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// User dating preferences
@freezed
class Preferences with _$Preferences {
  const factory Preferences({
    required String id,
    required String userId,
    @Default(['F', 'M', 'NB']) List<String> seekingGenders,
    @Default(18) int minAgeYears,
    @Default(60) int maxAgeYears,
    @Default(50) int maxDistanceKm,
    int? minHeightCm,
    int? maxHeightCm,
    @Default([]) List<String> educationFilter,
    @Default(false) bool seriousOnly,
    @Default(false) bool verifiedOnly,
    DateTime? updatedAt,
  }) = _Preferences;

  factory Preferences.fromJson(Map<String, dynamic> json) =>
      _$PreferencesFromJson(json);
}

/// User profile photo
@freezed
class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String userId,
    required String photoUrl,
    required String storagePath,
    required DateTime uploadedAt,
    @Default(0) int ordering,
    @Default(false) bool isModerated,
    @Default(false) bool isFlagged,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}

/// User app settings
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    required String userId,
    @Default(true) bool showAge,
    @Default(true) bool showExactDistance,
    @Default(true) bool showOnlineStatus,
    @Default(true) bool notifyNewMatch,
    @Default(true) bool notifyNewMessage,
    @Default(true) bool notifyLikes,
    @Default('light') String theme,
    DateTime? updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

/// Emergency contact for user
@freezed
class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String id,
    required String userId,
    required String name,
    required String phoneNumber,
    required DateTime addedAt,
    @Default(1) int ordering,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}
