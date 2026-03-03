// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swipe_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Swipe _$SwipeFromJson(Map<String, dynamic> json) {
  return _Swipe.fromJson(json);
}

/// @nodoc
mixin _$Swipe {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get targetUserId => throw _privateConstructorUsedError;
  bool get isLike => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SwipeCopyWith<Swipe> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwipeCopyWith<$Res> {
  factory $SwipeCopyWith(Swipe value, $Res Function(Swipe) then) =
      _$SwipeCopyWithImpl<$Res, Swipe>;
  @useResult
  $Res call({
    String id,
    String userId,
    String targetUserId,
    bool isLike,
    DateTime createdAt,
  });
}

/// @nodoc
class _$SwipeCopyWithImpl<$Res, $Val extends Swipe>
    implements $SwipeCopyWith<$Res> {
  _$SwipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? targetUserId = null,
    Object? isLike = null,
    Object? createdAt = null,
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
            targetUserId: null == targetUserId
                ? _value.targetUserId
                : targetUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            isLike: null == isLike
                ? _value.isLike
                : isLike // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SwipeImplCopyWith<$Res> implements $SwipeCopyWith<$Res> {
  factory _$$SwipeImplCopyWith(
    _$SwipeImpl value,
    $Res Function(_$SwipeImpl) then,
  ) = __$$SwipeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String targetUserId,
    bool isLike,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$SwipeImplCopyWithImpl<$Res>
    extends _$SwipeCopyWithImpl<$Res, _$SwipeImpl>
    implements _$$SwipeImplCopyWith<$Res> {
  __$$SwipeImplCopyWithImpl(
    _$SwipeImpl _value,
    $Res Function(_$SwipeImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? targetUserId = null,
    Object? isLike = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$SwipeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        targetUserId: null == targetUserId
            ? _value.targetUserId
            : targetUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        isLike: null == isLike
            ? _value.isLike
            : isLike // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SwipeImpl implements _Swipe {
  const _$SwipeImpl({
    required this.id,
    required this.userId,
    required this.targetUserId,
    this.isLike = false,
    required this.createdAt,
  });

  factory _$SwipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwipeImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String targetUserId;
  @override
  @JsonKey()
  final bool isLike;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Swipe(id: $id, userId: $userId, targetUserId: $targetUserId, isLike: $isLike, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.targetUserId, targetUserId) ||
                other.targetUserId == targetUserId) &&
            (identical(other.isLike, isLike) || other.isLike == isLike) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, targetUserId, isLike, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SwipeImplCopyWith<_$SwipeImpl> get copyWith =>
      __$$SwipeImplCopyWithImpl<_$SwipeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwipeImplToJson(this);
  }
}

abstract class _Swipe implements Swipe {
  const factory _Swipe({
    required final String id,
    required final String userId,
    required final String targetUserId,
    final bool isLike,
    required final DateTime createdAt,
  }) = _$SwipeImpl;

  factory _Swipe.fromJson(Map<String, dynamic> json) = _$SwipeImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get targetUserId;
  @override
  bool get isLike;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$SwipeImplCopyWith<_$SwipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Match _$MatchFromJson(Map<String, dynamic> json) {
  return _Match.fromJson(json);
}

/// @nodoc
mixin _$Match {
  String get id => throw _privateConstructorUsedError;
  String get userId1 => throw _privateConstructorUsedError;
  String get userId2 => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get user1Status => throw _privateConstructorUsedError;
  String get user2Status => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  bool get user1Blocked => throw _privateConstructorUsedError;
  bool get user2Blocked => throw _privateConstructorUsedError;
  int get chatCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchCopyWith<Match> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchCopyWith<$Res> {
  factory $MatchCopyWith(Match value, $Res Function(Match) then) =
      _$MatchCopyWithImpl<$Res, Match>;
  @useResult
  $Res call({
    String id,
    String userId1,
    String userId2,
    DateTime createdAt,
    String user1Status,
    String user2Status,
    DateTime? lastMessageAt,
    bool user1Blocked,
    bool user2Blocked,
    int chatCount,
  });
}

/// @nodoc
class _$MatchCopyWithImpl<$Res, $Val extends Match>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId1 = null,
    Object? userId2 = null,
    Object? createdAt = null,
    Object? user1Status = null,
    Object? user2Status = null,
    Object? lastMessageAt = freezed,
    Object? user1Blocked = null,
    Object? user2Blocked = null,
    Object? chatCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId1: null == userId1
                ? _value.userId1
                : userId1 // ignore: cast_nullable_to_non_nullable
                      as String,
            userId2: null == userId2
                ? _value.userId2
                : userId2 // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            user1Status: null == user1Status
                ? _value.user1Status
                : user1Status // ignore: cast_nullable_to_non_nullable
                      as String,
            user2Status: null == user2Status
                ? _value.user2Status
                : user2Status // ignore: cast_nullable_to_non_nullable
                      as String,
            lastMessageAt: freezed == lastMessageAt
                ? _value.lastMessageAt
                : lastMessageAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            user1Blocked: null == user1Blocked
                ? _value.user1Blocked
                : user1Blocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            user2Blocked: null == user2Blocked
                ? _value.user2Blocked
                : user2Blocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            chatCount: null == chatCount
                ? _value.chatCount
                : chatCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatchImplCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$$MatchImplCopyWith(
    _$MatchImpl value,
    $Res Function(_$MatchImpl) then,
  ) = __$$MatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId1,
    String userId2,
    DateTime createdAt,
    String user1Status,
    String user2Status,
    DateTime? lastMessageAt,
    bool user1Blocked,
    bool user2Blocked,
    int chatCount,
  });
}

/// @nodoc
class __$$MatchImplCopyWithImpl<$Res>
    extends _$MatchCopyWithImpl<$Res, _$MatchImpl>
    implements _$$MatchImplCopyWith<$Res> {
  __$$MatchImplCopyWithImpl(
    _$MatchImpl _value,
    $Res Function(_$MatchImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId1 = null,
    Object? userId2 = null,
    Object? createdAt = null,
    Object? user1Status = null,
    Object? user2Status = null,
    Object? lastMessageAt = freezed,
    Object? user1Blocked = null,
    Object? user2Blocked = null,
    Object? chatCount = null,
  }) {
    return _then(
      _$MatchImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId1: null == userId1
            ? _value.userId1
            : userId1 // ignore: cast_nullable_to_non_nullable
                  as String,
        userId2: null == userId2
            ? _value.userId2
            : userId2 // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        user1Status: null == user1Status
            ? _value.user1Status
            : user1Status // ignore: cast_nullable_to_non_nullable
                  as String,
        user2Status: null == user2Status
            ? _value.user2Status
            : user2Status // ignore: cast_nullable_to_non_nullable
                  as String,
        lastMessageAt: freezed == lastMessageAt
            ? _value.lastMessageAt
            : lastMessageAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        user1Blocked: null == user1Blocked
            ? _value.user1Blocked
            : user1Blocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        user2Blocked: null == user2Blocked
            ? _value.user2Blocked
            : user2Blocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        chatCount: null == chatCount
            ? _value.chatCount
            : chatCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchImpl implements _Match {
  const _$MatchImpl({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    this.user1Status = 'active',
    this.user2Status = 'active',
    this.lastMessageAt,
    this.user1Blocked = false,
    this.user2Blocked = false,
    this.chatCount = 0,
  });

  factory _$MatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchImplFromJson(json);

  @override
  final String id;
  @override
  final String userId1;
  @override
  final String userId2;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final String user1Status;
  @override
  @JsonKey()
  final String user2Status;
  @override
  final DateTime? lastMessageAt;
  @override
  @JsonKey()
  final bool user1Blocked;
  @override
  @JsonKey()
  final bool user2Blocked;
  @override
  @JsonKey()
  final int chatCount;

  @override
  String toString() {
    return 'Match(id: $id, userId1: $userId1, userId2: $userId2, createdAt: $createdAt, user1Status: $user1Status, user2Status: $user2Status, lastMessageAt: $lastMessageAt, user1Blocked: $user1Blocked, user2Blocked: $user2Blocked, chatCount: $chatCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId1, userId1) || other.userId1 == userId1) &&
            (identical(other.userId2, userId2) || other.userId2 == userId2) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.user1Status, user1Status) ||
                other.user1Status == user1Status) &&
            (identical(other.user2Status, user2Status) ||
                other.user2Status == user2Status) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.user1Blocked, user1Blocked) ||
                other.user1Blocked == user1Blocked) &&
            (identical(other.user2Blocked, user2Blocked) ||
                other.user2Blocked == user2Blocked) &&
            (identical(other.chatCount, chatCount) ||
                other.chatCount == chatCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId1,
    userId2,
    createdAt,
    user1Status,
    user2Status,
    lastMessageAt,
    user1Blocked,
    user2Blocked,
    chatCount,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      __$$MatchImplCopyWithImpl<_$MatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchImplToJson(this);
  }
}

abstract class _Match implements Match {
  const factory _Match({
    required final String id,
    required final String userId1,
    required final String userId2,
    required final DateTime createdAt,
    final String user1Status,
    final String user2Status,
    final DateTime? lastMessageAt,
    final bool user1Blocked,
    final bool user2Blocked,
    final int chatCount,
  }) = _$MatchImpl;

  factory _Match.fromJson(Map<String, dynamic> json) = _$MatchImpl.fromJson;

  @override
  String get id;
  @override
  String get userId1;
  @override
  String get userId2;
  @override
  DateTime get createdAt;
  @override
  String get user1Status;
  @override
  String get user2Status;
  @override
  DateTime? get lastMessageAt;
  @override
  bool get user1Blocked;
  @override
  bool get user2Blocked;
  @override
  int get chatCount;
  @override
  @JsonKey(ignore: true)
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
