// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) {
  return _AdminUser.fromJson(json);
}

/// @nodoc
mixin _$AdminUser {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get role =>
      throw _privateConstructorUsedError; // admin, moderator, analyst
  List<String> get permissions => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get passwordHash => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get lastLogin => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminUserCopyWith<AdminUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminUserCopyWith<$Res> {
  factory $AdminUserCopyWith(AdminUser value, $Res Function(AdminUser) then) =
      _$AdminUserCopyWithImpl<$Res, AdminUser>;
  @useResult
  $Res call({
    String id,
    String userId,
    String role,
    List<String> permissions,
    String email,
    String passwordHash,
    bool isActive,
    DateTime? lastLogin,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$AdminUserCopyWithImpl<$Res, $Val extends AdminUser>
    implements $AdminUserCopyWith<$Res> {
  _$AdminUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? permissions = null,
    Object? email = null,
    Object? passwordHash = null,
    Object? isActive = null,
    Object? lastLogin = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
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
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            passwordHash: null == passwordHash
                ? _value.passwordHash
                : passwordHash // ignore: cast_nullable_to_non_nullable
                      as String,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastLogin: freezed == lastLogin
                ? _value.lastLogin
                : lastLogin // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$AdminUserImplCopyWith<$Res>
    implements $AdminUserCopyWith<$Res> {
  factory _$$AdminUserImplCopyWith(
    _$AdminUserImpl value,
    $Res Function(_$AdminUserImpl) then,
  ) = __$$AdminUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String role,
    List<String> permissions,
    String email,
    String passwordHash,
    bool isActive,
    DateTime? lastLogin,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$AdminUserImplCopyWithImpl<$Res>
    extends _$AdminUserCopyWithImpl<$Res, _$AdminUserImpl>
    implements _$$AdminUserImplCopyWith<$Res> {
  __$$AdminUserImplCopyWithImpl(
    _$AdminUserImpl _value,
    $Res Function(_$AdminUserImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? permissions = null,
    Object? email = null,
    Object? passwordHash = null,
    Object? isActive = null,
    Object? lastLogin = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$AdminUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        passwordHash: null == passwordHash
            ? _value.passwordHash
            : passwordHash // ignore: cast_nullable_to_non_nullable
                  as String,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastLogin: freezed == lastLogin
            ? _value.lastLogin
            : lastLogin // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
class _$AdminUserImpl implements _AdminUser {
  const _$AdminUserImpl({
    required this.id,
    required this.userId,
    this.role = 'moderator',
    final List<String> permissions = const [],
    required this.email,
    required this.passwordHash,
    this.isActive = true,
    this.lastLogin,
    this.notes,
    this.createdAt,
    this.updatedAt,
  }) : _permissions = permissions;

  factory _$AdminUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminUserImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String role;
  // admin, moderator, analyst
  final List<String> _permissions;
  // admin, moderator, analyst
  @override
  @JsonKey()
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  final String email;
  @override
  final String passwordHash;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? lastLogin;
  @override
  final String? notes;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AdminUser(id: $id, userId: $userId, role: $role, permissions: $permissions, email: $email, passwordHash: $passwordHash, isActive: $isActive, lastLogin: $lastLogin, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.passwordHash, passwordHash) ||
                other.passwordHash == passwordHash) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    role,
    const DeepCollectionEquality().hash(_permissions),
    email,
    passwordHash,
    isActive,
    lastLogin,
    notes,
    createdAt,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      __$$AdminUserImplCopyWithImpl<_$AdminUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminUserImplToJson(this);
  }
}

abstract class _AdminUser implements AdminUser {
  const factory _AdminUser({
    required final String id,
    required final String userId,
    final String role,
    final List<String> permissions,
    required final String email,
    required final String passwordHash,
    final bool isActive,
    final DateTime? lastLogin,
    final String? notes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$AdminUserImpl;

  factory _AdminUser.fromJson(Map<String, dynamic> json) =
      _$AdminUserImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get role;
  @override // admin, moderator, analyst
  List<String> get permissions;
  @override
  String get email;
  @override
  String get passwordHash;
  @override
  bool get isActive;
  @override
  DateTime? get lastLogin;
  @override
  String? get notes;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // info, warning, error, success
  String? get title => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;
  DateTime? get sentAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
    Notification value,
    $Res Function(Notification) then,
  ) = _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    String? title,
    String? body,
    Map<String, dynamic> data,
    bool isRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? title = freezed,
    Object? body = freezed,
    Object? data = null,
    Object? isRead = null,
    Object? readAt = freezed,
    Object? sentAt = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            body: freezed == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String?,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            isRead: null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                      as bool,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            sentAt: freezed == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
    _$NotificationImpl value,
    $Res Function(_$NotificationImpl) then,
  ) = __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    String? title,
    String? body,
    Map<String, dynamic> data,
    bool isRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
    _$NotificationImpl _value,
    $Res Function(_$NotificationImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? title = freezed,
    Object? body = freezed,
    Object? data = null,
    Object? isRead = null,
    Object? readAt = freezed,
    Object? sentAt = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$NotificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        body: freezed == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        isRead: null == isRead
            ? _value.isRead
            : isRead // ignore: cast_nullable_to_non_nullable
                  as bool,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        sentAt: freezed == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl implements _Notification {
  const _$NotificationImpl({
    required this.id,
    required this.userId,
    this.type = 'info',
    this.title,
    this.body,
    final Map<String, dynamic> data = const {},
    this.isRead = false,
    this.readAt,
    this.sentAt,
    this.expiresAt,
    this.createdAt,
  }) : _data = data;

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String type;
  // info, warning, error, success
  @override
  final String? title;
  @override
  final String? body;
  final Map<String, dynamic> _data;
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  @JsonKey()
  final bool isRead;
  @override
  final DateTime? readAt;
  @override
  final DateTime? sentAt;
  @override
  final DateTime? expiresAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Notification(id: $id, userId: $userId, type: $type, title: $title, body: $body, data: $data, isRead: $isRead, readAt: $readAt, sentAt: $sentAt, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    type,
    title,
    body,
    const DeepCollectionEquality().hash(_data),
    isRead,
    readAt,
    sentAt,
    expiresAt,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(this);
  }
}

abstract class _Notification implements Notification {
  const factory _Notification({
    required final String id,
    required final String userId,
    final String type,
    final String? title,
    final String? body,
    final Map<String, dynamic> data,
    final bool isRead,
    final DateTime? readAt,
    final DateTime? sentAt,
    final DateTime? expiresAt,
    final DateTime? createdAt,
  }) = _$NotificationImpl;

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  @override // info, warning, error, success
  String? get title;
  @override
  String? get body;
  @override
  Map<String, dynamic> get data;
  @override
  bool get isRead;
  @override
  DateTime? get readAt;
  @override
  DateTime? get sentAt;
  @override
  DateTime? get expiresAt;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) {
  return _ActivityLog.fromJson(json);
}

/// @nodoc
mixin _$ActivityLog {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get action =>
      throw _privateConstructorUsedError; // login, update_profile, send_message, etc
  String? get resourceType =>
      throw _privateConstructorUsedError; // user, match, message, etc
  String? get resourceId => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  String? get userAgent => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ActivityLogCopyWith<ActivityLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityLogCopyWith<$Res> {
  factory $ActivityLogCopyWith(
    ActivityLog value,
    $Res Function(ActivityLog) then,
  ) = _$ActivityLogCopyWithImpl<$Res, ActivityLog>;
  @useResult
  $Res call({
    String id,
    String userId,
    String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic> metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$ActivityLogCopyWithImpl<$Res, $Val extends ActivityLog>
    implements $ActivityLogCopyWith<$Res> {
  _$ActivityLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? action = null,
    Object? resourceType = freezed,
    Object? resourceId = freezed,
    Object? metadata = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = freezed,
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
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            resourceType: freezed == resourceType
                ? _value.resourceType
                : resourceType // ignore: cast_nullable_to_non_nullable
                      as String?,
            resourceId: freezed == resourceId
                ? _value.resourceId
                : resourceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            userAgent: freezed == userAgent
                ? _value.userAgent
                : userAgent // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActivityLogImplCopyWith<$Res>
    implements $ActivityLogCopyWith<$Res> {
  factory _$$ActivityLogImplCopyWith(
    _$ActivityLogImpl value,
    $Res Function(_$ActivityLogImpl) then,
  ) = __$$ActivityLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic> metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$ActivityLogImplCopyWithImpl<$Res>
    extends _$ActivityLogCopyWithImpl<$Res, _$ActivityLogImpl>
    implements _$$ActivityLogImplCopyWith<$Res> {
  __$$ActivityLogImplCopyWithImpl(
    _$ActivityLogImpl _value,
    $Res Function(_$ActivityLogImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? action = null,
    Object? resourceType = freezed,
    Object? resourceId = freezed,
    Object? metadata = null,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ActivityLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        resourceType: freezed == resourceType
            ? _value.resourceType
            : resourceType // ignore: cast_nullable_to_non_nullable
                  as String?,
        resourceId: freezed == resourceId
            ? _value.resourceId
            : resourceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        userAgent: freezed == userAgent
            ? _value.userAgent
            : userAgent // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActivityLogImpl implements _ActivityLog {
  const _$ActivityLogImpl({
    required this.id,
    required this.userId,
    required this.action,
    this.resourceType,
    this.resourceId,
    final Map<String, dynamic> metadata = const {},
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  }) : _metadata = metadata;

  factory _$ActivityLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActivityLogImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String action;
  // login, update_profile, send_message, etc
  @override
  final String? resourceType;
  // user, match, message, etc
  @override
  final String? resourceId;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final String? ipAddress;
  @override
  final String? userAgent;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ActivityLog(id: $id, userId: $userId, action: $action, resourceType: $resourceType, resourceId: $resourceId, metadata: $metadata, ipAddress: $ipAddress, userAgent: $userAgent, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.resourceType, resourceType) ||
                other.resourceType == resourceType) &&
            (identical(other.resourceId, resourceId) ||
                other.resourceId == resourceId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    action,
    resourceType,
    resourceId,
    const DeepCollectionEquality().hash(_metadata),
    ipAddress,
    userAgent,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityLogImplCopyWith<_$ActivityLogImpl> get copyWith =>
      __$$ActivityLogImplCopyWithImpl<_$ActivityLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActivityLogImplToJson(this);
  }
}

abstract class _ActivityLog implements ActivityLog {
  const factory _ActivityLog({
    required final String id,
    required final String userId,
    required final String action,
    final String? resourceType,
    final String? resourceId,
    final Map<String, dynamic> metadata,
    final String? ipAddress,
    final String? userAgent,
    final DateTime? createdAt,
  }) = _$ActivityLogImpl;

  factory _ActivityLog.fromJson(Map<String, dynamic> json) =
      _$ActivityLogImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get action;
  @override // login, update_profile, send_message, etc
  String? get resourceType;
  @override // user, match, message, etc
  String? get resourceId;
  @override
  Map<String, dynamic> get metadata;
  @override
  String? get ipAddress;
  @override
  String? get userAgent;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ActivityLogImplCopyWith<_$ActivityLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalyticsMetrics _$AnalyticsMetricsFromJson(Map<String, dynamic> json) {
  return _AnalyticsMetrics.fromJson(json);
}

/// @nodoc
mixin _$AnalyticsMetrics {
  String get id => throw _privateConstructorUsedError;
  DateTime get metricDate => throw _privateConstructorUsedError;
  String get metricType =>
      throw _privateConstructorUsedError; // daily, weekly, monthly
  int get totalUsers => throw _privateConstructorUsedError;
  int get activeUsers => throw _privateConstructorUsedError;
  int get newUsers => throw _privateConstructorUsedError;
  int get totalMatches => throw _privateConstructorUsedError;
  int get totalSwipes => throw _privateConstructorUsedError;
  int get totalMessages => throw _privateConstructorUsedError;
  double get verificationRate => throw _privateConstructorUsedError;
  double get premiumConversion => throw _privateConstructorUsedError;
  int get averageSessionTime => throw _privateConstructorUsedError;
  int get reportCount => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnalyticsMetricsCopyWith<AnalyticsMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsMetricsCopyWith<$Res> {
  factory $AnalyticsMetricsCopyWith(
    AnalyticsMetrics value,
    $Res Function(AnalyticsMetrics) then,
  ) = _$AnalyticsMetricsCopyWithImpl<$Res, AnalyticsMetrics>;
  @useResult
  $Res call({
    String id,
    DateTime metricDate,
    String metricType,
    int totalUsers,
    int activeUsers,
    int newUsers,
    int totalMatches,
    int totalSwipes,
    int totalMessages,
    double verificationRate,
    double premiumConversion,
    int averageSessionTime,
    int reportCount,
    Map<String, dynamic> metadata,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$AnalyticsMetricsCopyWithImpl<$Res, $Val extends AnalyticsMetrics>
    implements $AnalyticsMetricsCopyWith<$Res> {
  _$AnalyticsMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? metricDate = null,
    Object? metricType = null,
    Object? totalUsers = null,
    Object? activeUsers = null,
    Object? newUsers = null,
    Object? totalMatches = null,
    Object? totalSwipes = null,
    Object? totalMessages = null,
    Object? verificationRate = null,
    Object? premiumConversion = null,
    Object? averageSessionTime = null,
    Object? reportCount = null,
    Object? metadata = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            metricDate: null == metricDate
                ? _value.metricDate
                : metricDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            metricType: null == metricType
                ? _value.metricType
                : metricType // ignore: cast_nullable_to_non_nullable
                      as String,
            totalUsers: null == totalUsers
                ? _value.totalUsers
                : totalUsers // ignore: cast_nullable_to_non_nullable
                      as int,
            activeUsers: null == activeUsers
                ? _value.activeUsers
                : activeUsers // ignore: cast_nullable_to_non_nullable
                      as int,
            newUsers: null == newUsers
                ? _value.newUsers
                : newUsers // ignore: cast_nullable_to_non_nullable
                      as int,
            totalMatches: null == totalMatches
                ? _value.totalMatches
                : totalMatches // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSwipes: null == totalSwipes
                ? _value.totalSwipes
                : totalSwipes // ignore: cast_nullable_to_non_nullable
                      as int,
            totalMessages: null == totalMessages
                ? _value.totalMessages
                : totalMessages // ignore: cast_nullable_to_non_nullable
                      as int,
            verificationRate: null == verificationRate
                ? _value.verificationRate
                : verificationRate // ignore: cast_nullable_to_non_nullable
                      as double,
            premiumConversion: null == premiumConversion
                ? _value.premiumConversion
                : premiumConversion // ignore: cast_nullable_to_non_nullable
                      as double,
            averageSessionTime: null == averageSessionTime
                ? _value.averageSessionTime
                : averageSessionTime // ignore: cast_nullable_to_non_nullable
                      as int,
            reportCount: null == reportCount
                ? _value.reportCount
                : reportCount // ignore: cast_nullable_to_non_nullable
                      as int,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnalyticsMetricsImplCopyWith<$Res>
    implements $AnalyticsMetricsCopyWith<$Res> {
  factory _$$AnalyticsMetricsImplCopyWith(
    _$AnalyticsMetricsImpl value,
    $Res Function(_$AnalyticsMetricsImpl) then,
  ) = __$$AnalyticsMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DateTime metricDate,
    String metricType,
    int totalUsers,
    int activeUsers,
    int newUsers,
    int totalMatches,
    int totalSwipes,
    int totalMessages,
    double verificationRate,
    double premiumConversion,
    int averageSessionTime,
    int reportCount,
    Map<String, dynamic> metadata,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$AnalyticsMetricsImplCopyWithImpl<$Res>
    extends _$AnalyticsMetricsCopyWithImpl<$Res, _$AnalyticsMetricsImpl>
    implements _$$AnalyticsMetricsImplCopyWith<$Res> {
  __$$AnalyticsMetricsImplCopyWithImpl(
    _$AnalyticsMetricsImpl _value,
    $Res Function(_$AnalyticsMetricsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? metricDate = null,
    Object? metricType = null,
    Object? totalUsers = null,
    Object? activeUsers = null,
    Object? newUsers = null,
    Object? totalMatches = null,
    Object? totalSwipes = null,
    Object? totalMessages = null,
    Object? verificationRate = null,
    Object? premiumConversion = null,
    Object? averageSessionTime = null,
    Object? reportCount = null,
    Object? metadata = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$AnalyticsMetricsImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        metricDate: null == metricDate
            ? _value.metricDate
            : metricDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        metricType: null == metricType
            ? _value.metricType
            : metricType // ignore: cast_nullable_to_non_nullable
                  as String,
        totalUsers: null == totalUsers
            ? _value.totalUsers
            : totalUsers // ignore: cast_nullable_to_non_nullable
                  as int,
        activeUsers: null == activeUsers
            ? _value.activeUsers
            : activeUsers // ignore: cast_nullable_to_non_nullable
                  as int,
        newUsers: null == newUsers
            ? _value.newUsers
            : newUsers // ignore: cast_nullable_to_non_nullable
                  as int,
        totalMatches: null == totalMatches
            ? _value.totalMatches
            : totalMatches // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSwipes: null == totalSwipes
            ? _value.totalSwipes
            : totalSwipes // ignore: cast_nullable_to_non_nullable
                  as int,
        totalMessages: null == totalMessages
            ? _value.totalMessages
            : totalMessages // ignore: cast_nullable_to_non_nullable
                  as int,
        verificationRate: null == verificationRate
            ? _value.verificationRate
            : verificationRate // ignore: cast_nullable_to_non_nullable
                  as double,
        premiumConversion: null == premiumConversion
            ? _value.premiumConversion
            : premiumConversion // ignore: cast_nullable_to_non_nullable
                  as double,
        averageSessionTime: null == averageSessionTime
            ? _value.averageSessionTime
            : averageSessionTime // ignore: cast_nullable_to_non_nullable
                  as int,
        reportCount: null == reportCount
            ? _value.reportCount
            : reportCount // ignore: cast_nullable_to_non_nullable
                  as int,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalyticsMetricsImpl implements _AnalyticsMetrics {
  const _$AnalyticsMetricsImpl({
    required this.id,
    required this.metricDate,
    this.metricType = 'daily',
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.newUsers = 0,
    this.totalMatches = 0,
    this.totalSwipes = 0,
    this.totalMessages = 0,
    this.verificationRate = 0.0,
    this.premiumConversion = 0.0,
    this.averageSessionTime = 0,
    this.reportCount = 0,
    final Map<String, dynamic> metadata = const {},
    this.createdAt,
  }) : _metadata = metadata;

  factory _$AnalyticsMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalyticsMetricsImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime metricDate;
  @override
  @JsonKey()
  final String metricType;
  // daily, weekly, monthly
  @override
  @JsonKey()
  final int totalUsers;
  @override
  @JsonKey()
  final int activeUsers;
  @override
  @JsonKey()
  final int newUsers;
  @override
  @JsonKey()
  final int totalMatches;
  @override
  @JsonKey()
  final int totalSwipes;
  @override
  @JsonKey()
  final int totalMessages;
  @override
  @JsonKey()
  final double verificationRate;
  @override
  @JsonKey()
  final double premiumConversion;
  @override
  @JsonKey()
  final int averageSessionTime;
  @override
  @JsonKey()
  final int reportCount;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AnalyticsMetrics(id: $id, metricDate: $metricDate, metricType: $metricType, totalUsers: $totalUsers, activeUsers: $activeUsers, newUsers: $newUsers, totalMatches: $totalMatches, totalSwipes: $totalSwipes, totalMessages: $totalMessages, verificationRate: $verificationRate, premiumConversion: $premiumConversion, averageSessionTime: $averageSessionTime, reportCount: $reportCount, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsMetricsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.metricDate, metricDate) ||
                other.metricDate == metricDate) &&
            (identical(other.metricType, metricType) ||
                other.metricType == metricType) &&
            (identical(other.totalUsers, totalUsers) ||
                other.totalUsers == totalUsers) &&
            (identical(other.activeUsers, activeUsers) ||
                other.activeUsers == activeUsers) &&
            (identical(other.newUsers, newUsers) ||
                other.newUsers == newUsers) &&
            (identical(other.totalMatches, totalMatches) ||
                other.totalMatches == totalMatches) &&
            (identical(other.totalSwipes, totalSwipes) ||
                other.totalSwipes == totalSwipes) &&
            (identical(other.totalMessages, totalMessages) ||
                other.totalMessages == totalMessages) &&
            (identical(other.verificationRate, verificationRate) ||
                other.verificationRate == verificationRate) &&
            (identical(other.premiumConversion, premiumConversion) ||
                other.premiumConversion == premiumConversion) &&
            (identical(other.averageSessionTime, averageSessionTime) ||
                other.averageSessionTime == averageSessionTime) &&
            (identical(other.reportCount, reportCount) ||
                other.reportCount == reportCount) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    metricDate,
    metricType,
    totalUsers,
    activeUsers,
    newUsers,
    totalMatches,
    totalSwipes,
    totalMessages,
    verificationRate,
    premiumConversion,
    averageSessionTime,
    reportCount,
    const DeepCollectionEquality().hash(_metadata),
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsMetricsImplCopyWith<_$AnalyticsMetricsImpl> get copyWith =>
      __$$AnalyticsMetricsImplCopyWithImpl<_$AnalyticsMetricsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalyticsMetricsImplToJson(this);
  }
}

abstract class _AnalyticsMetrics implements AnalyticsMetrics {
  const factory _AnalyticsMetrics({
    required final String id,
    required final DateTime metricDate,
    final String metricType,
    final int totalUsers,
    final int activeUsers,
    final int newUsers,
    final int totalMatches,
    final int totalSwipes,
    final int totalMessages,
    final double verificationRate,
    final double premiumConversion,
    final int averageSessionTime,
    final int reportCount,
    final Map<String, dynamic> metadata,
    final DateTime? createdAt,
  }) = _$AnalyticsMetricsImpl;

  factory _AnalyticsMetrics.fromJson(Map<String, dynamic> json) =
      _$AnalyticsMetricsImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get metricDate;
  @override
  String get metricType;
  @override // daily, weekly, monthly
  int get totalUsers;
  @override
  int get activeUsers;
  @override
  int get newUsers;
  @override
  int get totalMatches;
  @override
  int get totalSwipes;
  @override
  int get totalMessages;
  @override
  double get verificationRate;
  @override
  double get premiumConversion;
  @override
  int get averageSessionTime;
  @override
  int get reportCount;
  @override
  Map<String, dynamic> get metadata;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AnalyticsMetricsImplCopyWith<_$AnalyticsMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
