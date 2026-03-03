// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  phoneNumber: json['phoneNumber'] as String,
  name: json['name'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  gender: json['gender'] as String,
  bio: json['bio'] as String?,
  heightCm: (json['heightCm'] as num?)?.toInt(),
  education: json['education'] as String?,
  profession: json['profession'] as String?,
  incomeRange: json['incomeRange'] as String?,
  drinking: json['drinking'] as String?,
  smoking: json['smoking'] as String?,
  religion: json['religion'] as String?,
  profileCompletion: (json['profileCompletion'] as num?)?.toInt() ?? 0,
  isVerified: json['isVerified'] as bool? ?? false,
  verificationBadge: json['verificationBadge'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastLogin: json['lastLogin'] == null
      ? null
      : DateTime.parse(json['lastLogin'] as String),
  isActive: json['isActive'] as bool? ?? true,
  isBlocked: json['isBlocked'] as bool? ?? false,
  blockedUsers:
      (json['blockedUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'name': instance.name,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'gender': instance.gender,
      'bio': instance.bio,
      'heightCm': instance.heightCm,
      'education': instance.education,
      'profession': instance.profession,
      'incomeRange': instance.incomeRange,
      'drinking': instance.drinking,
      'smoking': instance.smoking,
      'religion': instance.religion,
      'profileCompletion': instance.profileCompletion,
      'isVerified': instance.isVerified,
      'verificationBadge': instance.verificationBadge,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLogin': instance.lastLogin?.toIso8601String(),
      'isActive': instance.isActive,
      'isBlocked': instance.isBlocked,
      'blockedUsers': instance.blockedUsers,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$PreferencesImpl _$$PreferencesImplFromJson(Map<String, dynamic> json) =>
    _$PreferencesImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      seekingGenders:
          (json['seekingGenders'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['F', 'M', 'NB'],
      minAgeYears: (json['minAgeYears'] as num?)?.toInt() ?? 18,
      maxAgeYears: (json['maxAgeYears'] as num?)?.toInt() ?? 60,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toInt() ?? 50,
      minHeightCm: (json['minHeightCm'] as num?)?.toInt(),
      maxHeightCm: (json['maxHeightCm'] as num?)?.toInt(),
      educationFilter:
          (json['educationFilter'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      seriousOnly: json['seriousOnly'] as bool? ?? false,
      verifiedOnly: json['verifiedOnly'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PreferencesImplToJson(_$PreferencesImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'seekingGenders': instance.seekingGenders,
      'minAgeYears': instance.minAgeYears,
      'maxAgeYears': instance.maxAgeYears,
      'maxDistanceKm': instance.maxDistanceKm,
      'minHeightCm': instance.minHeightCm,
      'maxHeightCm': instance.maxHeightCm,
      'educationFilter': instance.educationFilter,
      'seriousOnly': instance.seriousOnly,
      'verifiedOnly': instance.verifiedOnly,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$PhotoImpl _$$PhotoImplFromJson(Map<String, dynamic> json) => _$PhotoImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  photoUrl: json['photoUrl'] as String,
  storagePath: json['storagePath'] as String,
  ordering: (json['ordering'] as num?)?.toInt() ?? 0,
  uploadedAt: DateTime.parse(json['uploadedAt'] as String),
  isModerated: json['isModerated'] as bool? ?? false,
  isFlagged: json['isFlagged'] as bool? ?? false,
);

Map<String, dynamic> _$$PhotoImplToJson(_$PhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'photoUrl': instance.photoUrl,
      'storagePath': instance.storagePath,
      'ordering': instance.ordering,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'isModerated': instance.isModerated,
      'isFlagged': instance.isFlagged,
    };

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      userId: json['userId'] as String,
      showAge: json['showAge'] as bool? ?? true,
      showExactDistance: json['showExactDistance'] as bool? ?? true,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      notifyNewMatch: json['notifyNewMatch'] as bool? ?? true,
      notifyNewMessage: json['notifyNewMessage'] as bool? ?? true,
      notifyLikes: json['notifyLikes'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'light',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'showAge': instance.showAge,
      'showExactDistance': instance.showExactDistance,
      'showOnlineStatus': instance.showOnlineStatus,
      'notifyNewMatch': instance.notifyNewMatch,
      'notifyNewMessage': instance.notifyNewMessage,
      'notifyLikes': instance.notifyLikes,
      'theme': instance.theme,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$EmergencyContactImpl _$$EmergencyContactImplFromJson(
  Map<String, dynamic> json,
) => _$EmergencyContactImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  phoneNumber: json['phoneNumber'] as String,
  ordering: (json['ordering'] as num?)?.toInt() ?? 1,
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$$EmergencyContactImplToJson(
  _$EmergencyContactImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'phoneNumber': instance.phoneNumber,
  'ordering': instance.ordering,
  'addedAt': instance.addedAt.toIso8601String(),
};
