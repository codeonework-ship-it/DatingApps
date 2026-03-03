// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Verification _$VerificationFromJson(Map<String, dynamic> json) {
  return _Verification.fromJson(json);
}

/// @nodoc
mixin _$Verification {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // pending, verified, rejected
  String? get idPhotoPath => throw _privateConstructorUsedError;
  String? get selfiePhotoPath => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get verifiedAt => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  int get retryCount => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  String? get verifiedBy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VerificationCopyWith<Verification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationCopyWith<$Res> {
  factory $VerificationCopyWith(
    Verification value,
    $Res Function(Verification) then,
  ) = _$VerificationCopyWithImpl<$Res, Verification>;
  @useResult
  $Res call({
    String id,
    String userId,
    String status,
    String? idPhotoPath,
    String? selfiePhotoPath,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    int retryCount,
    DateTime? expiresAt,
    String? verifiedBy,
  });
}

/// @nodoc
class _$VerificationCopyWithImpl<$Res, $Val extends Verification>
    implements $VerificationCopyWith<$Res> {
  _$VerificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? status = null,
    Object? idPhotoPath = freezed,
    Object? selfiePhotoPath = freezed,
    Object? submittedAt = freezed,
    Object? verifiedAt = freezed,
    Object? rejectionReason = freezed,
    Object? retryCount = null,
    Object? expiresAt = freezed,
    Object? verifiedBy = freezed,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            idPhotoPath: freezed == idPhotoPath
                ? _value.idPhotoPath
                : idPhotoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            selfiePhotoPath: freezed == selfiePhotoPath
                ? _value.selfiePhotoPath
                : selfiePhotoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            verifiedAt: freezed == verifiedAt
                ? _value.verifiedAt
                : verifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            retryCount: null == retryCount
                ? _value.retryCount
                : retryCount // ignore: cast_nullable_to_non_nullable
                      as int,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            verifiedBy: freezed == verifiedBy
                ? _value.verifiedBy
                : verifiedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VerificationImplCopyWith<$Res>
    implements $VerificationCopyWith<$Res> {
  factory _$$VerificationImplCopyWith(
    _$VerificationImpl value,
    $Res Function(_$VerificationImpl) then,
  ) = __$$VerificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String status,
    String? idPhotoPath,
    String? selfiePhotoPath,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    int retryCount,
    DateTime? expiresAt,
    String? verifiedBy,
  });
}

/// @nodoc
class __$$VerificationImplCopyWithImpl<$Res>
    extends _$VerificationCopyWithImpl<$Res, _$VerificationImpl>
    implements _$$VerificationImplCopyWith<$Res> {
  __$$VerificationImplCopyWithImpl(
    _$VerificationImpl _value,
    $Res Function(_$VerificationImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? status = null,
    Object? idPhotoPath = freezed,
    Object? selfiePhotoPath = freezed,
    Object? submittedAt = freezed,
    Object? verifiedAt = freezed,
    Object? rejectionReason = freezed,
    Object? retryCount = null,
    Object? expiresAt = freezed,
    Object? verifiedBy = freezed,
  }) {
    return _then(
      _$VerificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        idPhotoPath: freezed == idPhotoPath
            ? _value.idPhotoPath
            : idPhotoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        selfiePhotoPath: freezed == selfiePhotoPath
            ? _value.selfiePhotoPath
            : selfiePhotoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        verifiedAt: freezed == verifiedAt
            ? _value.verifiedAt
            : verifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        retryCount: null == retryCount
            ? _value.retryCount
            : retryCount // ignore: cast_nullable_to_non_nullable
                  as int,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        verifiedBy: freezed == verifiedBy
            ? _value.verifiedBy
            : verifiedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VerificationImpl implements _Verification {
  const _$VerificationImpl({
    required this.id,
    required this.userId,
    this.status = 'pending',
    this.idPhotoPath,
    this.selfiePhotoPath,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.retryCount = 0,
    this.expiresAt,
    this.verifiedBy,
  });

  factory _$VerificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerificationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String status;
  // pending, verified, rejected
  @override
  final String? idPhotoPath;
  @override
  final String? selfiePhotoPath;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? verifiedAt;
  @override
  final String? rejectionReason;
  @override
  @JsonKey()
  final int retryCount;
  @override
  final DateTime? expiresAt;
  @override
  final String? verifiedBy;

  @override
  String toString() {
    return 'Verification(id: $id, userId: $userId, status: $status, idPhotoPath: $idPhotoPath, selfiePhotoPath: $selfiePhotoPath, submittedAt: $submittedAt, verifiedAt: $verifiedAt, rejectionReason: $rejectionReason, retryCount: $retryCount, expiresAt: $expiresAt, verifiedBy: $verifiedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.idPhotoPath, idPhotoPath) ||
                other.idPhotoPath == idPhotoPath) &&
            (identical(other.selfiePhotoPath, selfiePhotoPath) ||
                other.selfiePhotoPath == selfiePhotoPath) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.verifiedBy, verifiedBy) ||
                other.verifiedBy == verifiedBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    status,
    idPhotoPath,
    selfiePhotoPath,
    submittedAt,
    verifiedAt,
    rejectionReason,
    retryCount,
    expiresAt,
    verifiedBy,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationImplCopyWith<_$VerificationImpl> get copyWith =>
      __$$VerificationImplCopyWithImpl<_$VerificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VerificationImplToJson(this);
  }
}

abstract class _Verification implements Verification {
  const factory _Verification({
    required final String id,
    required final String userId,
    final String status,
    final String? idPhotoPath,
    final String? selfiePhotoPath,
    final DateTime? submittedAt,
    final DateTime? verifiedAt,
    final String? rejectionReason,
    final int retryCount,
    final DateTime? expiresAt,
    final String? verifiedBy,
  }) = _$VerificationImpl;

  factory _Verification.fromJson(Map<String, dynamic> json) =
      _$VerificationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get status;
  @override // pending, verified, rejected
  String? get idPhotoPath;
  @override
  String? get selfiePhotoPath;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get verifiedAt;
  @override
  String? get rejectionReason;
  @override
  int get retryCount;
  @override
  DateTime? get expiresAt;
  @override
  String? get verifiedBy;
  @override
  @JsonKey(ignore: true)
  _$$VerificationImplCopyWith<_$VerificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Report _$ReportFromJson(Map<String, dynamic> json) {
  return _Report.fromJson(json);
}

/// @nodoc
mixin _$Report {
  String get id => throw _privateConstructorUsedError;
  String get reporterId => throw _privateConstructorUsedError;
  String get reportedUserId => throw _privateConstructorUsedError;
  String? get messageId => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // pending, under_review, resolved
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  String? get reviewedBy => throw _privateConstructorUsedError;
  String? get action => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReportCopyWith<Report> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportCopyWith<$Res> {
  factory $ReportCopyWith(Report value, $Res Function(Report) then) =
      _$ReportCopyWithImpl<$Res, Report>;
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reportedUserId,
    String? messageId,
    String reason,
    String? description,
    String status,
    DateTime createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? action,
  });
}

/// @nodoc
class _$ReportCopyWithImpl<$Res, $Val extends Report>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reportedUserId = null,
    Object? messageId = freezed,
    Object? reason = null,
    Object? description = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
    Object? action = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            reporterId: null == reporterId
                ? _value.reporterId
                : reporterId // ignore: cast_nullable_to_non_nullable
                      as String,
            reportedUserId: null == reportedUserId
                ? _value.reportedUserId
                : reportedUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            messageId: freezed == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedBy: freezed == reviewedBy
                ? _value.reviewedBy
                : reviewedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            action: freezed == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportImplCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$$ReportImplCopyWith(
    _$ReportImpl value,
    $Res Function(_$ReportImpl) then,
  ) = __$$ReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reportedUserId,
    String? messageId,
    String reason,
    String? description,
    String status,
    DateTime createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? action,
  });
}

/// @nodoc
class __$$ReportImplCopyWithImpl<$Res>
    extends _$ReportCopyWithImpl<$Res, _$ReportImpl>
    implements _$$ReportImplCopyWith<$Res> {
  __$$ReportImplCopyWithImpl(
    _$ReportImpl _value,
    $Res Function(_$ReportImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reportedUserId = null,
    Object? messageId = freezed,
    Object? reason = null,
    Object? description = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
    Object? action = freezed,
  }) {
    return _then(
      _$ReportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reporterId: null == reporterId
            ? _value.reporterId
            : reporterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reportedUserId: null == reportedUserId
            ? _value.reportedUserId
            : reportedUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        messageId: freezed == messageId
            ? _value.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedBy: freezed == reviewedBy
            ? _value.reviewedBy
            : reviewedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        action: freezed == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportImpl implements _Report {
  const _$ReportImpl({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.messageId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.action,
  });

  factory _$ReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportImplFromJson(json);

  @override
  final String id;
  @override
  final String reporterId;
  @override
  final String reportedUserId;
  @override
  final String? messageId;
  @override
  final String reason;
  @override
  final String? description;
  @override
  @JsonKey()
  final String status;
  // pending, under_review, resolved
  @override
  final DateTime createdAt;
  @override
  final DateTime? reviewedAt;
  @override
  final String? reviewedBy;
  @override
  final String? action;

  @override
  String toString() {
    return 'Report(id: $id, reporterId: $reporterId, reportedUserId: $reportedUserId, messageId: $messageId, reason: $reason, description: $description, status: $status, createdAt: $createdAt, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, action: $action)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reporterId, reporterId) ||
                other.reporterId == reporterId) &&
            (identical(other.reportedUserId, reportedUserId) ||
                other.reportedUserId == reportedUserId) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy) &&
            (identical(other.action, action) || other.action == action));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reporterId,
    reportedUserId,
    messageId,
    reason,
    description,
    status,
    createdAt,
    reviewedAt,
    reviewedBy,
    action,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      __$$ReportImplCopyWithImpl<_$ReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportImplToJson(this);
  }
}

abstract class _Report implements Report {
  const factory _Report({
    required final String id,
    required final String reporterId,
    required final String reportedUserId,
    final String? messageId,
    required final String reason,
    final String? description,
    final String status,
    required final DateTime createdAt,
    final DateTime? reviewedAt,
    final String? reviewedBy,
    final String? action,
  }) = _$ReportImpl;

  factory _Report.fromJson(Map<String, dynamic> json) = _$ReportImpl.fromJson;

  @override
  String get id;
  @override
  String get reporterId;
  @override
  String get reportedUserId;
  @override
  String? get messageId;
  @override
  String get reason;
  @override
  String? get description;
  @override
  String get status;
  @override // pending, under_review, resolved
  DateTime get createdAt;
  @override
  DateTime? get reviewedAt;
  @override
  String? get reviewedBy;
  @override
  String? get action;
  @override
  @JsonKey(ignore: true)
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SafetyFlag _$SafetyFlagFromJson(Map<String, dynamic> json) {
  return _SafetyFlag.fromJson(json);
}

/// @nodoc
mixin _$SafetyFlag {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get flagType =>
      throw _privateConstructorUsedError; // suspicious, fake_profile, harassment
  String get severity =>
      throw _privateConstructorUsedError; // low, medium, high
  String? get description => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get isResolved => throw _privateConstructorUsedError;
  String? get action => throw _privateConstructorUsedError;
  DateTime? get actionedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SafetyFlagCopyWith<SafetyFlag> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SafetyFlagCopyWith<$Res> {
  factory $SafetyFlagCopyWith(
    SafetyFlag value,
    $Res Function(SafetyFlag) then,
  ) = _$SafetyFlagCopyWithImpl<$Res, SafetyFlag>;
  @useResult
  $Res call({
    String id,
    String userId,
    String flagType,
    String severity,
    String? description,
    DateTime createdAt,
    bool isResolved,
    String? action,
    DateTime? actionedAt,
  });
}

/// @nodoc
class _$SafetyFlagCopyWithImpl<$Res, $Val extends SafetyFlag>
    implements $SafetyFlagCopyWith<$Res> {
  _$SafetyFlagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? flagType = null,
    Object? severity = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? isResolved = null,
    Object? action = freezed,
    Object? actionedAt = freezed,
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
            flagType: null == flagType
                ? _value.flagType
                : flagType // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isResolved: null == isResolved
                ? _value.isResolved
                : isResolved // ignore: cast_nullable_to_non_nullable
                      as bool,
            action: freezed == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String?,
            actionedAt: freezed == actionedAt
                ? _value.actionedAt
                : actionedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SafetyFlagImplCopyWith<$Res>
    implements $SafetyFlagCopyWith<$Res> {
  factory _$$SafetyFlagImplCopyWith(
    _$SafetyFlagImpl value,
    $Res Function(_$SafetyFlagImpl) then,
  ) = __$$SafetyFlagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String flagType,
    String severity,
    String? description,
    DateTime createdAt,
    bool isResolved,
    String? action,
    DateTime? actionedAt,
  });
}

/// @nodoc
class __$$SafetyFlagImplCopyWithImpl<$Res>
    extends _$SafetyFlagCopyWithImpl<$Res, _$SafetyFlagImpl>
    implements _$$SafetyFlagImplCopyWith<$Res> {
  __$$SafetyFlagImplCopyWithImpl(
    _$SafetyFlagImpl _value,
    $Res Function(_$SafetyFlagImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? flagType = null,
    Object? severity = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? isResolved = null,
    Object? action = freezed,
    Object? actionedAt = freezed,
  }) {
    return _then(
      _$SafetyFlagImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        flagType: null == flagType
            ? _value.flagType
            : flagType // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isResolved: null == isResolved
            ? _value.isResolved
            : isResolved // ignore: cast_nullable_to_non_nullable
                  as bool,
        action: freezed == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String?,
        actionedAt: freezed == actionedAt
            ? _value.actionedAt
            : actionedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SafetyFlagImpl implements _SafetyFlag {
  const _$SafetyFlagImpl({
    required this.id,
    required this.userId,
    this.flagType = 'suspicious',
    this.severity = 'medium',
    this.description,
    required this.createdAt,
    this.isResolved = false,
    this.action,
    this.actionedAt,
  });

  factory _$SafetyFlagImpl.fromJson(Map<String, dynamic> json) =>
      _$$SafetyFlagImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String flagType;
  // suspicious, fake_profile, harassment
  @override
  @JsonKey()
  final String severity;
  // low, medium, high
  @override
  final String? description;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool isResolved;
  @override
  final String? action;
  @override
  final DateTime? actionedAt;

  @override
  String toString() {
    return 'SafetyFlag(id: $id, userId: $userId, flagType: $flagType, severity: $severity, description: $description, createdAt: $createdAt, isResolved: $isResolved, action: $action, actionedAt: $actionedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SafetyFlagImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.flagType, flagType) ||
                other.flagType == flagType) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isResolved, isResolved) ||
                other.isResolved == isResolved) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.actionedAt, actionedAt) ||
                other.actionedAt == actionedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    flagType,
    severity,
    description,
    createdAt,
    isResolved,
    action,
    actionedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SafetyFlagImplCopyWith<_$SafetyFlagImpl> get copyWith =>
      __$$SafetyFlagImplCopyWithImpl<_$SafetyFlagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SafetyFlagImplToJson(this);
  }
}

abstract class _SafetyFlag implements SafetyFlag {
  const factory _SafetyFlag({
    required final String id,
    required final String userId,
    final String flagType,
    final String severity,
    final String? description,
    required final DateTime createdAt,
    final bool isResolved,
    final String? action,
    final DateTime? actionedAt,
  }) = _$SafetyFlagImpl;

  factory _SafetyFlag.fromJson(Map<String, dynamic> json) =
      _$SafetyFlagImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get flagType;
  @override // suspicious, fake_profile, harassment
  String get severity;
  @override // low, medium, high
  String? get description;
  @override
  DateTime get createdAt;
  @override
  bool get isResolved;
  @override
  String? get action;
  @override
  DateTime? get actionedAt;
  @override
  @JsonKey(ignore: true)
  _$$SafetyFlagImplCopyWith<_$SafetyFlagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
