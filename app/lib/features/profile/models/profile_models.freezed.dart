// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get dateOfBirth => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  int? get heightCm => throw _privateConstructorUsedError;
  String? get education => throw _privateConstructorUsedError;
  String? get profession => throw _privateConstructorUsedError;
  String? get incomeRange => throw _privateConstructorUsedError;
  String? get drinking => throw _privateConstructorUsedError;
  String? get smoking => throw _privateConstructorUsedError;
  String? get religion => throw _privateConstructorUsedError;
  int get profileCompletion => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  bool get verificationBadge => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastLogin => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get isBlocked => throw _privateConstructorUsedError;
  List<String> get blockedUsers => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    String id,
    String phoneNumber,
    String name,
    DateTime dateOfBirth,
    String gender,
    String? bio,
    int? heightCm,
    String? education,
    String? profession,
    String? incomeRange,
    String? drinking,
    String? smoking,
    String? religion,
    int profileCompletion,
    bool isVerified,
    bool verificationBadge,
    DateTime createdAt,
    DateTime? lastLogin,
    bool isActive,
    bool isBlocked,
    List<String> blockedUsers,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phoneNumber = null,
    Object? name = null,
    Object? dateOfBirth = null,
    Object? gender = null,
    Object? bio = freezed,
    Object? heightCm = freezed,
    Object? education = freezed,
    Object? profession = freezed,
    Object? incomeRange = freezed,
    Object? drinking = freezed,
    Object? smoking = freezed,
    Object? religion = freezed,
    Object? profileCompletion = null,
    Object? isVerified = null,
    Object? verificationBadge = null,
    Object? createdAt = null,
    Object? lastLogin = freezed,
    Object? isActive = null,
    Object? isBlocked = null,
    Object? blockedUsers = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            dateOfBirth: null == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            heightCm: freezed == heightCm
                ? _value.heightCm
                : heightCm // ignore: cast_nullable_to_non_nullable
                      as int?,
            education: freezed == education
                ? _value.education
                : education // ignore: cast_nullable_to_non_nullable
                      as String?,
            profession: freezed == profession
                ? _value.profession
                : profession // ignore: cast_nullable_to_non_nullable
                      as String?,
            incomeRange: freezed == incomeRange
                ? _value.incomeRange
                : incomeRange // ignore: cast_nullable_to_non_nullable
                      as String?,
            drinking: freezed == drinking
                ? _value.drinking
                : drinking // ignore: cast_nullable_to_non_nullable
                      as String?,
            smoking: freezed == smoking
                ? _value.smoking
                : smoking // ignore: cast_nullable_to_non_nullable
                      as String?,
            religion: freezed == religion
                ? _value.religion
                : religion // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileCompletion: null == profileCompletion
                ? _value.profileCompletion
                : profileCompletion // ignore: cast_nullable_to_non_nullable
                      as int,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            verificationBadge: null == verificationBadge
                ? _value.verificationBadge
                : verificationBadge // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastLogin: freezed == lastLogin
                ? _value.lastLogin
                : lastLogin // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isBlocked: null == isBlocked
                ? _value.isBlocked
                : isBlocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            blockedUsers: null == blockedUsers
                ? _value.blockedUsers
                : blockedUsers // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String phoneNumber,
    String name,
    DateTime dateOfBirth,
    String gender,
    String? bio,
    int? heightCm,
    String? education,
    String? profession,
    String? incomeRange,
    String? drinking,
    String? smoking,
    String? religion,
    int profileCompletion,
    bool isVerified,
    bool verificationBadge,
    DateTime createdAt,
    DateTime? lastLogin,
    bool isActive,
    bool isBlocked,
    List<String> blockedUsers,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phoneNumber = null,
    Object? name = null,
    Object? dateOfBirth = null,
    Object? gender = null,
    Object? bio = freezed,
    Object? heightCm = freezed,
    Object? education = freezed,
    Object? profession = freezed,
    Object? incomeRange = freezed,
    Object? drinking = freezed,
    Object? smoking = freezed,
    Object? religion = freezed,
    Object? profileCompletion = null,
    Object? isVerified = null,
    Object? verificationBadge = null,
    Object? createdAt = null,
    Object? lastLogin = freezed,
    Object? isActive = null,
    Object? isBlocked = null,
    Object? blockedUsers = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        dateOfBirth: null == dateOfBirth
            ? _value.dateOfBirth
            : dateOfBirth // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        heightCm: freezed == heightCm
            ? _value.heightCm
            : heightCm // ignore: cast_nullable_to_non_nullable
                  as int?,
        education: freezed == education
            ? _value.education
            : education // ignore: cast_nullable_to_non_nullable
                  as String?,
        profession: freezed == profession
            ? _value.profession
            : profession // ignore: cast_nullable_to_non_nullable
                  as String?,
        incomeRange: freezed == incomeRange
            ? _value.incomeRange
            : incomeRange // ignore: cast_nullable_to_non_nullable
                  as String?,
        drinking: freezed == drinking
            ? _value.drinking
            : drinking // ignore: cast_nullable_to_non_nullable
                  as String?,
        smoking: freezed == smoking
            ? _value.smoking
            : smoking // ignore: cast_nullable_to_non_nullable
                  as String?,
        religion: freezed == religion
            ? _value.religion
            : religion // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileCompletion: null == profileCompletion
            ? _value.profileCompletion
            : profileCompletion // ignore: cast_nullable_to_non_nullable
                  as int,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        verificationBadge: null == verificationBadge
            ? _value.verificationBadge
            : verificationBadge // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastLogin: freezed == lastLogin
            ? _value.lastLogin
            : lastLogin // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isBlocked: null == isBlocked
            ? _value.isBlocked
            : isBlocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        blockedUsers: null == blockedUsers
            ? _value._blockedUsers
            : blockedUsers // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.bio,
    this.heightCm,
    this.education,
    this.profession,
    this.incomeRange,
    this.drinking,
    this.smoking,
    this.religion,
    this.profileCompletion = 0,
    this.isVerified = false,
    this.verificationBadge = false,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.isBlocked = false,
    final List<String> blockedUsers = const [],
    this.updatedAt,
  }) : _blockedUsers = blockedUsers;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String phoneNumber;
  @override
  final String name;
  @override
  final DateTime dateOfBirth;
  @override
  final String gender;
  @override
  final String? bio;
  @override
  final int? heightCm;
  @override
  final String? education;
  @override
  final String? profession;
  @override
  final String? incomeRange;
  @override
  final String? drinking;
  @override
  final String? smoking;
  @override
  final String? religion;
  @override
  @JsonKey()
  final int profileCompletion;
  @override
  @JsonKey()
  final bool isVerified;
  @override
  @JsonKey()
  final bool verificationBadge;
  @override
  final DateTime createdAt;
  @override
  final DateTime? lastLogin;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool isBlocked;
  final List<String> _blockedUsers;
  @override
  @JsonKey()
  List<String> get blockedUsers {
    if (_blockedUsers is EqualUnmodifiableListView) return _blockedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blockedUsers);
  }

  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'User(id: $id, phoneNumber: $phoneNumber, name: $name, dateOfBirth: $dateOfBirth, gender: $gender, bio: $bio, heightCm: $heightCm, education: $education, profession: $profession, incomeRange: $incomeRange, drinking: $drinking, smoking: $smoking, religion: $religion, profileCompletion: $profileCompletion, isVerified: $isVerified, verificationBadge: $verificationBadge, createdAt: $createdAt, lastLogin: $lastLogin, isActive: $isActive, isBlocked: $isBlocked, blockedUsers: $blockedUsers, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.education, education) ||
                other.education == education) &&
            (identical(other.profession, profession) ||
                other.profession == profession) &&
            (identical(other.incomeRange, incomeRange) ||
                other.incomeRange == incomeRange) &&
            (identical(other.drinking, drinking) ||
                other.drinking == drinking) &&
            (identical(other.smoking, smoking) || other.smoking == smoking) &&
            (identical(other.religion, religion) ||
                other.religion == religion) &&
            (identical(other.profileCompletion, profileCompletion) ||
                other.profileCompletion == profileCompletion) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.verificationBadge, verificationBadge) ||
                other.verificationBadge == verificationBadge) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isBlocked, isBlocked) ||
                other.isBlocked == isBlocked) &&
            const DeepCollectionEquality().equals(
              other._blockedUsers,
              _blockedUsers,
            ) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    phoneNumber,
    name,
    dateOfBirth,
    gender,
    bio,
    heightCm,
    education,
    profession,
    incomeRange,
    drinking,
    smoking,
    religion,
    profileCompletion,
    isVerified,
    verificationBadge,
    createdAt,
    lastLogin,
    isActive,
    isBlocked,
    const DeepCollectionEquality().hash(_blockedUsers),
    updatedAt,
  ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    required final String id,
    required final String phoneNumber,
    required final String name,
    required final DateTime dateOfBirth,
    required final String gender,
    final String? bio,
    final int? heightCm,
    final String? education,
    final String? profession,
    final String? incomeRange,
    final String? drinking,
    final String? smoking,
    final String? religion,
    final int profileCompletion,
    final bool isVerified,
    final bool verificationBadge,
    required final DateTime createdAt,
    final DateTime? lastLogin,
    final bool isActive,
    final bool isBlocked,
    final List<String> blockedUsers,
    final DateTime? updatedAt,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get phoneNumber;
  @override
  String get name;
  @override
  DateTime get dateOfBirth;
  @override
  String get gender;
  @override
  String? get bio;
  @override
  int? get heightCm;
  @override
  String? get education;
  @override
  String? get profession;
  @override
  String? get incomeRange;
  @override
  String? get drinking;
  @override
  String? get smoking;
  @override
  String? get religion;
  @override
  int get profileCompletion;
  @override
  bool get isVerified;
  @override
  bool get verificationBadge;
  @override
  DateTime get createdAt;
  @override
  DateTime? get lastLogin;
  @override
  bool get isActive;
  @override
  bool get isBlocked;
  @override
  List<String> get blockedUsers;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Preferences _$PreferencesFromJson(Map<String, dynamic> json) {
  return _Preferences.fromJson(json);
}

/// @nodoc
mixin _$Preferences {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  List<String> get seekingGenders => throw _privateConstructorUsedError;
  int get minAgeYears => throw _privateConstructorUsedError;
  int get maxAgeYears => throw _privateConstructorUsedError;
  int get maxDistanceKm => throw _privateConstructorUsedError;
  int? get minHeightCm => throw _privateConstructorUsedError;
  int? get maxHeightCm => throw _privateConstructorUsedError;
  List<String> get educationFilter => throw _privateConstructorUsedError;
  bool get seriousOnly => throw _privateConstructorUsedError;
  bool get verifiedOnly => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PreferencesCopyWith<Preferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PreferencesCopyWith<$Res> {
  factory $PreferencesCopyWith(
    Preferences value,
    $Res Function(Preferences) then,
  ) = _$PreferencesCopyWithImpl<$Res, Preferences>;
  @useResult
  $Res call({
    String id,
    String userId,
    List<String> seekingGenders,
    int minAgeYears,
    int maxAgeYears,
    int maxDistanceKm,
    int? minHeightCm,
    int? maxHeightCm,
    List<String> educationFilter,
    bool seriousOnly,
    bool verifiedOnly,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$PreferencesCopyWithImpl<$Res, $Val extends Preferences>
    implements $PreferencesCopyWith<$Res> {
  _$PreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? seekingGenders = null,
    Object? minAgeYears = null,
    Object? maxAgeYears = null,
    Object? maxDistanceKm = null,
    Object? minHeightCm = freezed,
    Object? maxHeightCm = freezed,
    Object? educationFilter = null,
    Object? seriousOnly = null,
    Object? verifiedOnly = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            seekingGenders: null == seekingGenders
                ? _value.seekingGenders
                : seekingGenders // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            minAgeYears: null == minAgeYears
                ? _value.minAgeYears
                : minAgeYears // ignore: cast_nullable_to_non_nullable
                      as int,
            maxAgeYears: null == maxAgeYears
                ? _value.maxAgeYears
                : maxAgeYears // ignore: cast_nullable_to_non_nullable
                      as int,
            maxDistanceKm: null == maxDistanceKm
                ? _value.maxDistanceKm
                : maxDistanceKm // ignore: cast_nullable_to_non_nullable
                      as int,
            minHeightCm: freezed == minHeightCm
                ? _value.minHeightCm
                : minHeightCm // ignore: cast_nullable_to_non_nullable
                      as int?,
            maxHeightCm: freezed == maxHeightCm
                ? _value.maxHeightCm
                : maxHeightCm // ignore: cast_nullable_to_non_nullable
                      as int?,
            educationFilter: null == educationFilter
                ? _value.educationFilter
                : educationFilter // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            seriousOnly: null == seriousOnly
                ? _value.seriousOnly
                : seriousOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            verifiedOnly: null == verifiedOnly
                ? _value.verifiedOnly
                : verifiedOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PreferencesImplCopyWith<$Res>
    implements $PreferencesCopyWith<$Res> {
  factory _$$PreferencesImplCopyWith(
    _$PreferencesImpl value,
    $Res Function(_$PreferencesImpl) then,
  ) = __$$PreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    List<String> seekingGenders,
    int minAgeYears,
    int maxAgeYears,
    int maxDistanceKm,
    int? minHeightCm,
    int? maxHeightCm,
    List<String> educationFilter,
    bool seriousOnly,
    bool verifiedOnly,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PreferencesImplCopyWithImpl<$Res>
    extends _$PreferencesCopyWithImpl<$Res, _$PreferencesImpl>
    implements _$$PreferencesImplCopyWith<$Res> {
  __$$PreferencesImplCopyWithImpl(
    _$PreferencesImpl _value,
    $Res Function(_$PreferencesImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? seekingGenders = null,
    Object? minAgeYears = null,
    Object? maxAgeYears = null,
    Object? maxDistanceKm = null,
    Object? minHeightCm = freezed,
    Object? maxHeightCm = freezed,
    Object? educationFilter = null,
    Object? seriousOnly = null,
    Object? verifiedOnly = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PreferencesImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        seekingGenders: null == seekingGenders
            ? _value._seekingGenders
            : seekingGenders // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        minAgeYears: null == minAgeYears
            ? _value.minAgeYears
            : minAgeYears // ignore: cast_nullable_to_non_nullable
                  as int,
        maxAgeYears: null == maxAgeYears
            ? _value.maxAgeYears
            : maxAgeYears // ignore: cast_nullable_to_non_nullable
                  as int,
        maxDistanceKm: null == maxDistanceKm
            ? _value.maxDistanceKm
            : maxDistanceKm // ignore: cast_nullable_to_non_nullable
                  as int,
        minHeightCm: freezed == minHeightCm
            ? _value.minHeightCm
            : minHeightCm // ignore: cast_nullable_to_non_nullable
                  as int?,
        maxHeightCm: freezed == maxHeightCm
            ? _value.maxHeightCm
            : maxHeightCm // ignore: cast_nullable_to_non_nullable
                  as int?,
        educationFilter: null == educationFilter
            ? _value._educationFilter
            : educationFilter // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        seriousOnly: null == seriousOnly
            ? _value.seriousOnly
            : seriousOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        verifiedOnly: null == verifiedOnly
            ? _value.verifiedOnly
            : verifiedOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PreferencesImpl implements _Preferences {
  const _$PreferencesImpl({
    required this.id,
    required this.userId,
    final List<String> seekingGenders = const ['F', 'M', 'NB'],
    this.minAgeYears = 18,
    this.maxAgeYears = 60,
    this.maxDistanceKm = 50,
    this.minHeightCm,
    this.maxHeightCm,
    final List<String> educationFilter = const [],
    this.seriousOnly = false,
    this.verifiedOnly = false,
    this.updatedAt,
  }) : _seekingGenders = seekingGenders,
       _educationFilter = educationFilter;

  factory _$PreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PreferencesImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  final List<String> _seekingGenders;
  @override
  @JsonKey()
  List<String> get seekingGenders {
    if (_seekingGenders is EqualUnmodifiableListView) return _seekingGenders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seekingGenders);
  }

  @override
  @JsonKey()
  final int minAgeYears;
  @override
  @JsonKey()
  final int maxAgeYears;
  @override
  @JsonKey()
  final int maxDistanceKm;
  @override
  final int? minHeightCm;
  @override
  final int? maxHeightCm;
  final List<String> _educationFilter;
  @override
  @JsonKey()
  List<String> get educationFilter {
    if (_educationFilter is EqualUnmodifiableListView) return _educationFilter;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_educationFilter);
  }

  @override
  @JsonKey()
  final bool seriousOnly;
  @override
  @JsonKey()
  final bool verifiedOnly;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Preferences(id: $id, userId: $userId, seekingGenders: $seekingGenders, minAgeYears: $minAgeYears, maxAgeYears: $maxAgeYears, maxDistanceKm: $maxDistanceKm, minHeightCm: $minHeightCm, maxHeightCm: $maxHeightCm, educationFilter: $educationFilter, seriousOnly: $seriousOnly, verifiedOnly: $verifiedOnly, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PreferencesImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(
              other._seekingGenders,
              _seekingGenders,
            ) &&
            (identical(other.minAgeYears, minAgeYears) ||
                other.minAgeYears == minAgeYears) &&
            (identical(other.maxAgeYears, maxAgeYears) ||
                other.maxAgeYears == maxAgeYears) &&
            (identical(other.maxDistanceKm, maxDistanceKm) ||
                other.maxDistanceKm == maxDistanceKm) &&
            (identical(other.minHeightCm, minHeightCm) ||
                other.minHeightCm == minHeightCm) &&
            (identical(other.maxHeightCm, maxHeightCm) ||
                other.maxHeightCm == maxHeightCm) &&
            const DeepCollectionEquality().equals(
              other._educationFilter,
              _educationFilter,
            ) &&
            (identical(other.seriousOnly, seriousOnly) ||
                other.seriousOnly == seriousOnly) &&
            (identical(other.verifiedOnly, verifiedOnly) ||
                other.verifiedOnly == verifiedOnly) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    const DeepCollectionEquality().hash(_seekingGenders),
    minAgeYears,
    maxAgeYears,
    maxDistanceKm,
    minHeightCm,
    maxHeightCm,
    const DeepCollectionEquality().hash(_educationFilter),
    seriousOnly,
    verifiedOnly,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PreferencesImplCopyWith<_$PreferencesImpl> get copyWith =>
      __$$PreferencesImplCopyWithImpl<_$PreferencesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PreferencesImplToJson(this);
  }
}

abstract class _Preferences implements Preferences {
  const factory _Preferences({
    required final String id,
    required final String userId,
    final List<String> seekingGenders,
    final int minAgeYears,
    final int maxAgeYears,
    final int maxDistanceKm,
    final int? minHeightCm,
    final int? maxHeightCm,
    final List<String> educationFilter,
    final bool seriousOnly,
    final bool verifiedOnly,
    final DateTime? updatedAt,
  }) = _$PreferencesImpl;

  factory _Preferences.fromJson(Map<String, dynamic> json) =
      _$PreferencesImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  List<String> get seekingGenders;
  @override
  int get minAgeYears;
  @override
  int get maxAgeYears;
  @override
  int get maxDistanceKm;
  @override
  int? get minHeightCm;
  @override
  int? get maxHeightCm;
  @override
  List<String> get educationFilter;
  @override
  bool get seriousOnly;
  @override
  bool get verifiedOnly;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PreferencesImplCopyWith<_$PreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Photo _$PhotoFromJson(Map<String, dynamic> json) {
  return _Photo.fromJson(json);
}

/// @nodoc
mixin _$Photo {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get photoUrl => throw _privateConstructorUsedError;
  String get storagePath => throw _privateConstructorUsedError;
  int get ordering => throw _privateConstructorUsedError;
  DateTime get uploadedAt => throw _privateConstructorUsedError;
  bool get isModerated => throw _privateConstructorUsedError;
  bool get isFlagged => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PhotoCopyWith<Photo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoCopyWith<$Res> {
  factory $PhotoCopyWith(Photo value, $Res Function(Photo) then) =
      _$PhotoCopyWithImpl<$Res, Photo>;
  @useResult
  $Res call({
    String id,
    String userId,
    String photoUrl,
    String storagePath,
    int ordering,
    DateTime uploadedAt,
    bool isModerated,
    bool isFlagged,
  });
}

/// @nodoc
class _$PhotoCopyWithImpl<$Res, $Val extends Photo>
    implements $PhotoCopyWith<$Res> {
  _$PhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? photoUrl = null,
    Object? storagePath = null,
    Object? ordering = null,
    Object? uploadedAt = null,
    Object? isModerated = null,
    Object? isFlagged = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            photoUrl: null == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            storagePath: null == storagePath
                ? _value.storagePath
                : storagePath // ignore: cast_nullable_to_non_nullable
                      as String,
            ordering: null == ordering
                ? _value.ordering
                : ordering // ignore: cast_nullable_to_non_nullable
                      as int,
            uploadedAt: null == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isModerated: null == isModerated
                ? _value.isModerated
                : isModerated // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFlagged: null == isFlagged
                ? _value.isFlagged
                : isFlagged // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PhotoImplCopyWith<$Res> implements $PhotoCopyWith<$Res> {
  factory _$$PhotoImplCopyWith(
    _$PhotoImpl value,
    $Res Function(_$PhotoImpl) then,
  ) = __$$PhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String photoUrl,
    String storagePath,
    int ordering,
    DateTime uploadedAt,
    bool isModerated,
    bool isFlagged,
  });
}

/// @nodoc
class __$$PhotoImplCopyWithImpl<$Res>
    extends _$PhotoCopyWithImpl<$Res, _$PhotoImpl>
    implements _$$PhotoImplCopyWith<$Res> {
  __$$PhotoImplCopyWithImpl(
    _$PhotoImpl _value,
    $Res Function(_$PhotoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? photoUrl = null,
    Object? storagePath = null,
    Object? ordering = null,
    Object? uploadedAt = null,
    Object? isModerated = null,
    Object? isFlagged = null,
  }) {
    return _then(
      _$PhotoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        photoUrl: null == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        storagePath: null == storagePath
            ? _value.storagePath
            : storagePath // ignore: cast_nullable_to_non_nullable
                  as String,
        ordering: null == ordering
            ? _value.ordering
            : ordering // ignore: cast_nullable_to_non_nullable
                  as int,
        uploadedAt: null == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isModerated: null == isModerated
            ? _value.isModerated
            : isModerated // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFlagged: null == isFlagged
            ? _value.isFlagged
            : isFlagged // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoImpl implements _Photo {
  const _$PhotoImpl({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.storagePath,
    this.ordering = 0,
    required this.uploadedAt,
    this.isModerated = false,
    this.isFlagged = false,
  });

  factory _$PhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String photoUrl;
  @override
  final String storagePath;
  @override
  @JsonKey()
  final int ordering;
  @override
  final DateTime uploadedAt;
  @override
  @JsonKey()
  final bool isModerated;
  @override
  @JsonKey()
  final bool isFlagged;

  @override
  String toString() {
    return 'Photo(id: $id, userId: $userId, photoUrl: $photoUrl, storagePath: $storagePath, ordering: $ordering, uploadedAt: $uploadedAt, isModerated: $isModerated, isFlagged: $isFlagged)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.ordering, ordering) ||
                other.ordering == ordering) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.isModerated, isModerated) ||
                other.isModerated == isModerated) &&
            (identical(other.isFlagged, isFlagged) ||
                other.isFlagged == isFlagged));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    photoUrl,
    storagePath,
    ordering,
    uploadedAt,
    isModerated,
    isFlagged,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      __$$PhotoImplCopyWithImpl<_$PhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoImplToJson(this);
  }
}

abstract class _Photo implements Photo {
  const factory _Photo({
    required final String id,
    required final String userId,
    required final String photoUrl,
    required final String storagePath,
    final int ordering,
    required final DateTime uploadedAt,
    final bool isModerated,
    final bool isFlagged,
  }) = _$PhotoImpl;

  factory _Photo.fromJson(Map<String, dynamic> json) = _$PhotoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get photoUrl;
  @override
  String get storagePath;
  @override
  int get ordering;
  @override
  DateTime get uploadedAt;
  @override
  bool get isModerated;
  @override
  bool get isFlagged;
  @override
  @JsonKey(ignore: true)
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  String get userId => throw _privateConstructorUsedError;
  bool get showAge => throw _privateConstructorUsedError;
  bool get showExactDistance => throw _privateConstructorUsedError;
  bool get showOnlineStatus => throw _privateConstructorUsedError;
  bool get notifyNewMatch => throw _privateConstructorUsedError;
  bool get notifyNewMessage => throw _privateConstructorUsedError;
  bool get notifyLikes => throw _privateConstructorUsedError;
  String get theme => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
    UserSettings value,
    $Res Function(UserSettings) then,
  ) = _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({
    String userId,
    bool showAge,
    bool showExactDistance,
    bool showOnlineStatus,
    bool notifyNewMatch,
    bool notifyNewMessage,
    bool notifyLikes,
    String theme,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? showAge = null,
    Object? showExactDistance = null,
    Object? showOnlineStatus = null,
    Object? notifyNewMatch = null,
    Object? notifyNewMessage = null,
    Object? notifyLikes = null,
    Object? theme = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            showAge: null == showAge
                ? _value.showAge
                : showAge // ignore: cast_nullable_to_non_nullable
                      as bool,
            showExactDistance: null == showExactDistance
                ? _value.showExactDistance
                : showExactDistance // ignore: cast_nullable_to_non_nullable
                      as bool,
            showOnlineStatus: null == showOnlineStatus
                ? _value.showOnlineStatus
                : showOnlineStatus // ignore: cast_nullable_to_non_nullable
                      as bool,
            notifyNewMatch: null == notifyNewMatch
                ? _value.notifyNewMatch
                : notifyNewMatch // ignore: cast_nullable_to_non_nullable
                      as bool,
            notifyNewMessage: null == notifyNewMessage
                ? _value.notifyNewMessage
                : notifyNewMessage // ignore: cast_nullable_to_non_nullable
                      as bool,
            notifyLikes: null == notifyLikes
                ? _value.notifyLikes
                : notifyLikes // ignore: cast_nullable_to_non_nullable
                      as bool,
            theme: null == theme
                ? _value.theme
                : theme // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
    _$UserSettingsImpl value,
    $Res Function(_$UserSettingsImpl) then,
  ) = __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    bool showAge,
    bool showExactDistance,
    bool showOnlineStatus,
    bool notifyNewMatch,
    bool notifyNewMessage,
    bool notifyLikes,
    String theme,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
    _$UserSettingsImpl _value,
    $Res Function(_$UserSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? showAge = null,
    Object? showExactDistance = null,
    Object? showOnlineStatus = null,
    Object? notifyNewMatch = null,
    Object? notifyNewMessage = null,
    Object? notifyLikes = null,
    Object? theme = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserSettingsImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        showAge: null == showAge
            ? _value.showAge
            : showAge // ignore: cast_nullable_to_non_nullable
                  as bool,
        showExactDistance: null == showExactDistance
            ? _value.showExactDistance
            : showExactDistance // ignore: cast_nullable_to_non_nullable
                  as bool,
        showOnlineStatus: null == showOnlineStatus
            ? _value.showOnlineStatus
            : showOnlineStatus // ignore: cast_nullable_to_non_nullable
                  as bool,
        notifyNewMatch: null == notifyNewMatch
            ? _value.notifyNewMatch
            : notifyNewMatch // ignore: cast_nullable_to_non_nullable
                  as bool,
        notifyNewMessage: null == notifyNewMessage
            ? _value.notifyNewMessage
            : notifyNewMessage // ignore: cast_nullable_to_non_nullable
                  as bool,
        notifyLikes: null == notifyLikes
            ? _value.notifyLikes
            : notifyLikes // ignore: cast_nullable_to_non_nullable
                  as bool,
        theme: null == theme
            ? _value.theme
            : theme // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl({
    required this.userId,
    this.showAge = true,
    this.showExactDistance = true,
    this.showOnlineStatus = true,
    this.notifyNewMatch = true,
    this.notifyNewMessage = true,
    this.notifyLikes = true,
    this.theme = 'light',
    this.updatedAt,
  });

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final bool showAge;
  @override
  @JsonKey()
  final bool showExactDistance;
  @override
  @JsonKey()
  final bool showOnlineStatus;
  @override
  @JsonKey()
  final bool notifyNewMatch;
  @override
  @JsonKey()
  final bool notifyNewMessage;
  @override
  @JsonKey()
  final bool notifyLikes;
  @override
  @JsonKey()
  final String theme;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserSettings(userId: $userId, showAge: $showAge, showExactDistance: $showExactDistance, showOnlineStatus: $showOnlineStatus, notifyNewMatch: $notifyNewMatch, notifyNewMessage: $notifyNewMessage, notifyLikes: $notifyLikes, theme: $theme, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.showAge, showAge) || other.showAge == showAge) &&
            (identical(other.showExactDistance, showExactDistance) ||
                other.showExactDistance == showExactDistance) &&
            (identical(other.showOnlineStatus, showOnlineStatus) ||
                other.showOnlineStatus == showOnlineStatus) &&
            (identical(other.notifyNewMatch, notifyNewMatch) ||
                other.notifyNewMatch == notifyNewMatch) &&
            (identical(other.notifyNewMessage, notifyNewMessage) ||
                other.notifyNewMessage == notifyNewMessage) &&
            (identical(other.notifyLikes, notifyLikes) ||
                other.notifyLikes == notifyLikes) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    showAge,
    showExactDistance,
    showOnlineStatus,
    notifyNewMatch,
    notifyNewMessage,
    notifyLikes,
    theme,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(this);
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings({
    required final String userId,
    final bool showAge,
    final bool showExactDistance,
    final bool showOnlineStatus,
    final bool notifyNewMatch,
    final bool notifyNewMessage,
    final bool notifyLikes,
    final String theme,
    final DateTime? updatedAt,
  }) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  String get userId;
  @override
  bool get showAge;
  @override
  bool get showExactDistance;
  @override
  bool get showOnlineStatus;
  @override
  bool get notifyNewMatch;
  @override
  bool get notifyNewMessage;
  @override
  bool get notifyLikes;
  @override
  String get theme;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) {
  return _EmergencyContact.fromJson(json);
}

/// @nodoc
mixin _$EmergencyContact {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  int get ordering => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EmergencyContactCopyWith<EmergencyContact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmergencyContactCopyWith<$Res> {
  factory $EmergencyContactCopyWith(
    EmergencyContact value,
    $Res Function(EmergencyContact) then,
  ) = _$EmergencyContactCopyWithImpl<$Res, EmergencyContact>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String phoneNumber,
    int ordering,
    DateTime addedAt,
  });
}

/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res, $Val extends EmergencyContact>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phoneNumber = null,
    Object? ordering = null,
    Object? addedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            ordering: null == ordering
                ? _value.ordering
                : ordering // ignore: cast_nullable_to_non_nullable
                      as int,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmergencyContactImplCopyWith<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  factory _$$EmergencyContactImplCopyWith(
    _$EmergencyContactImpl value,
    $Res Function(_$EmergencyContactImpl) then,
  ) = __$$EmergencyContactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String phoneNumber,
    int ordering,
    DateTime addedAt,
  });
}

/// @nodoc
class __$$EmergencyContactImplCopyWithImpl<$Res>
    extends _$EmergencyContactCopyWithImpl<$Res, _$EmergencyContactImpl>
    implements _$$EmergencyContactImplCopyWith<$Res> {
  __$$EmergencyContactImplCopyWithImpl(
    _$EmergencyContactImpl _value,
    $Res Function(_$EmergencyContactImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phoneNumber = null,
    Object? ordering = null,
    Object? addedAt = null,
  }) {
    return _then(
      _$EmergencyContactImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        ordering: null == ordering
            ? _value.ordering
            : ordering // ignore: cast_nullable_to_non_nullable
                  as int,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EmergencyContactImpl implements _EmergencyContact {
  const _$EmergencyContactImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.ordering = 1,
    required this.addedAt,
  });

  factory _$EmergencyContactImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmergencyContactImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String phoneNumber;
  @override
  @JsonKey()
  final int ordering;
  @override
  final DateTime addedAt;

  @override
  String toString() {
    return 'EmergencyContact(id: $id, userId: $userId, name: $name, phoneNumber: $phoneNumber, ordering: $ordering, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmergencyContactImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.ordering, ordering) ||
                other.ordering == ordering) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    phoneNumber,
    ordering,
    addedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      __$$EmergencyContactImplCopyWithImpl<_$EmergencyContactImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EmergencyContactImplToJson(this);
  }
}

abstract class _EmergencyContact implements EmergencyContact {
  const factory _EmergencyContact({
    required final String id,
    required final String userId,
    required final String name,
    required final String phoneNumber,
    final int ordering,
    required final DateTime addedAt,
  }) = _$EmergencyContactImpl;

  factory _EmergencyContact.fromJson(Map<String, dynamic> json) =
      _$EmergencyContactImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get phoneNumber;
  @override
  int get ordering;
  @override
  DateTime get addedAt;
  @override
  @JsonKey(ignore: true)
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
