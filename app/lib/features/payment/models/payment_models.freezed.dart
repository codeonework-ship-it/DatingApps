// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) {
  return _SubscriptionPlan.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionPlan {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError; // Free, Premium, VIP
  double get monthlyPrice => throw _privateConstructorUsedError;
  double get yearlyPrice => throw _privateConstructorUsedError;
  int get likesPerDay => throw _privateConstructorUsedError;
  int get messagesPerDay => throw _privateConstructorUsedError;
  bool get advancedFilters => throw _privateConstructorUsedError;
  bool get verifiedBadge => throw _privateConstructorUsedError;
  bool get prioritySupport => throw _privateConstructorUsedError;
  Map<String, dynamic> get features => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubscriptionPlanCopyWith<SubscriptionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPlanCopyWith<$Res> {
  factory $SubscriptionPlanCopyWith(
    SubscriptionPlan value,
    $Res Function(SubscriptionPlan) then,
  ) = _$SubscriptionPlanCopyWithImpl<$Res, SubscriptionPlan>;
  @useResult
  $Res call({
    String id,
    String name,
    double monthlyPrice,
    double yearlyPrice,
    int likesPerDay,
    int messagesPerDay,
    bool advancedFilters,
    bool verifiedBadge,
    bool prioritySupport,
    Map<String, dynamic> features,
    String? description,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$SubscriptionPlanCopyWithImpl<$Res, $Val extends SubscriptionPlan>
    implements $SubscriptionPlanCopyWith<$Res> {
  _$SubscriptionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? monthlyPrice = null,
    Object? yearlyPrice = null,
    Object? likesPerDay = null,
    Object? messagesPerDay = null,
    Object? advancedFilters = null,
    Object? verifiedBadge = null,
    Object? prioritySupport = null,
    Object? features = null,
    Object? description = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            monthlyPrice: null == monthlyPrice
                ? _value.monthlyPrice
                : monthlyPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            yearlyPrice: null == yearlyPrice
                ? _value.yearlyPrice
                : yearlyPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            likesPerDay: null == likesPerDay
                ? _value.likesPerDay
                : likesPerDay // ignore: cast_nullable_to_non_nullable
                      as int,
            messagesPerDay: null == messagesPerDay
                ? _value.messagesPerDay
                : messagesPerDay // ignore: cast_nullable_to_non_nullable
                      as int,
            advancedFilters: null == advancedFilters
                ? _value.advancedFilters
                : advancedFilters // ignore: cast_nullable_to_non_nullable
                      as bool,
            verifiedBadge: null == verifiedBadge
                ? _value.verifiedBadge
                : verifiedBadge // ignore: cast_nullable_to_non_nullable
                      as bool,
            prioritySupport: null == prioritySupport
                ? _value.prioritySupport
                : prioritySupport // ignore: cast_nullable_to_non_nullable
                      as bool,
            features: null == features
                ? _value.features
                : features // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$SubscriptionPlanImplCopyWith<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  factory _$$SubscriptionPlanImplCopyWith(
    _$SubscriptionPlanImpl value,
    $Res Function(_$SubscriptionPlanImpl) then,
  ) = __$$SubscriptionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double monthlyPrice,
    double yearlyPrice,
    int likesPerDay,
    int messagesPerDay,
    bool advancedFilters,
    bool verifiedBadge,
    bool prioritySupport,
    Map<String, dynamic> features,
    String? description,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SubscriptionPlanImplCopyWithImpl<$Res>
    extends _$SubscriptionPlanCopyWithImpl<$Res, _$SubscriptionPlanImpl>
    implements _$$SubscriptionPlanImplCopyWith<$Res> {
  __$$SubscriptionPlanImplCopyWithImpl(
    _$SubscriptionPlanImpl _value,
    $Res Function(_$SubscriptionPlanImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? monthlyPrice = null,
    Object? yearlyPrice = null,
    Object? likesPerDay = null,
    Object? messagesPerDay = null,
    Object? advancedFilters = null,
    Object? verifiedBadge = null,
    Object? prioritySupport = null,
    Object? features = null,
    Object? description = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SubscriptionPlanImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        monthlyPrice: null == monthlyPrice
            ? _value.monthlyPrice
            : monthlyPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        yearlyPrice: null == yearlyPrice
            ? _value.yearlyPrice
            : yearlyPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        likesPerDay: null == likesPerDay
            ? _value.likesPerDay
            : likesPerDay // ignore: cast_nullable_to_non_nullable
                  as int,
        messagesPerDay: null == messagesPerDay
            ? _value.messagesPerDay
            : messagesPerDay // ignore: cast_nullable_to_non_nullable
                  as int,
        advancedFilters: null == advancedFilters
            ? _value.advancedFilters
            : advancedFilters // ignore: cast_nullable_to_non_nullable
                  as bool,
        verifiedBadge: null == verifiedBadge
            ? _value.verifiedBadge
            : verifiedBadge // ignore: cast_nullable_to_non_nullable
                  as bool,
        prioritySupport: null == prioritySupport
            ? _value.prioritySupport
            : prioritySupport // ignore: cast_nullable_to_non_nullable
                  as bool,
        features: null == features
            ? _value._features
            : features // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$SubscriptionPlanImpl implements _SubscriptionPlan {
  const _$SubscriptionPlanImpl({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.likesPerDay = 10,
    this.messagesPerDay = 20,
    this.advancedFilters = false,
    this.verifiedBadge = false,
    this.prioritySupport = false,
    final Map<String, dynamic> features = const {},
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : _features = features;

  factory _$SubscriptionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  // Free, Premium, VIP
  @override
  final double monthlyPrice;
  @override
  final double yearlyPrice;
  @override
  @JsonKey()
  final int likesPerDay;
  @override
  @JsonKey()
  final int messagesPerDay;
  @override
  @JsonKey()
  final bool advancedFilters;
  @override
  @JsonKey()
  final bool verifiedBadge;
  @override
  @JsonKey()
  final bool prioritySupport;
  final Map<String, dynamic> _features;
  @override
  @JsonKey()
  Map<String, dynamic> get features {
    if (_features is EqualUnmodifiableMapView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_features);
  }

  @override
  final String? description;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, monthlyPrice: $monthlyPrice, yearlyPrice: $yearlyPrice, likesPerDay: $likesPerDay, messagesPerDay: $messagesPerDay, advancedFilters: $advancedFilters, verifiedBadge: $verifiedBadge, prioritySupport: $prioritySupport, features: $features, description: $description, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.monthlyPrice, monthlyPrice) ||
                other.monthlyPrice == monthlyPrice) &&
            (identical(other.yearlyPrice, yearlyPrice) ||
                other.yearlyPrice == yearlyPrice) &&
            (identical(other.likesPerDay, likesPerDay) ||
                other.likesPerDay == likesPerDay) &&
            (identical(other.messagesPerDay, messagesPerDay) ||
                other.messagesPerDay == messagesPerDay) &&
            (identical(other.advancedFilters, advancedFilters) ||
                other.advancedFilters == advancedFilters) &&
            (identical(other.verifiedBadge, verifiedBadge) ||
                other.verifiedBadge == verifiedBadge) &&
            (identical(other.prioritySupport, prioritySupport) ||
                other.prioritySupport == prioritySupport) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
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
    name,
    monthlyPrice,
    yearlyPrice,
    likesPerDay,
    messagesPerDay,
    advancedFilters,
    verifiedBadge,
    prioritySupport,
    const DeepCollectionEquality().hash(_features),
    description,
    isActive,
    createdAt,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      __$$SubscriptionPlanImplCopyWithImpl<_$SubscriptionPlanImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionPlanImplToJson(this);
  }
}

abstract class _SubscriptionPlan implements SubscriptionPlan {
  const factory _SubscriptionPlan({
    required final String id,
    required final String name,
    required final double monthlyPrice,
    required final double yearlyPrice,
    final int likesPerDay,
    final int messagesPerDay,
    final bool advancedFilters,
    final bool verifiedBadge,
    final bool prioritySupport,
    final Map<String, dynamic> features,
    final String? description,
    final bool isActive,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$SubscriptionPlanImpl;

  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override // Free, Premium, VIP
  double get monthlyPrice;
  @override
  double get yearlyPrice;
  @override
  int get likesPerDay;
  @override
  int get messagesPerDay;
  @override
  bool get advancedFilters;
  @override
  bool get verifiedBadge;
  @override
  bool get prioritySupport;
  @override
  Map<String, dynamic> get features;
  @override
  String? get description;
  @override
  bool get isActive;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return _Subscription.fromJson(json);
}

/// @nodoc
mixin _$Subscription {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // active, expired, cancelled
  String get billingCycle =>
      throw _privateConstructorUsedError; // monthly, yearly
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  DateTime? get nextBillingDate => throw _privateConstructorUsedError;
  bool get autoRenew => throw _privateConstructorUsedError;
  String? get razorpaySubscriptionId => throw _privateConstructorUsedError;
  String? get razorpayCustomerId => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  String? get cancelReason => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubscriptionCopyWith<Subscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionCopyWith<$Res> {
  factory $SubscriptionCopyWith(
    Subscription value,
    $Res Function(Subscription) then,
  ) = _$SubscriptionCopyWithImpl<$Res, Subscription>;
  @useResult
  $Res call({
    String id,
    String userId,
    String planId,
    String status,
    String billingCycle,
    DateTime startDate,
    DateTime? endDate,
    DateTime? nextBillingDate,
    bool autoRenew,
    String? razorpaySubscriptionId,
    String? razorpayCustomerId,
    DateTime? cancelledAt,
    String? cancelReason,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$SubscriptionCopyWithImpl<$Res, $Val extends Subscription>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = null,
    Object? status = null,
    Object? billingCycle = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? nextBillingDate = freezed,
    Object? autoRenew = null,
    Object? razorpaySubscriptionId = freezed,
    Object? razorpayCustomerId = freezed,
    Object? cancelledAt = freezed,
    Object? cancelReason = freezed,
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
            planId: null == planId
                ? _value.planId
                : planId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            billingCycle: null == billingCycle
                ? _value.billingCycle
                : billingCycle // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            nextBillingDate: freezed == nextBillingDate
                ? _value.nextBillingDate
                : nextBillingDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            autoRenew: null == autoRenew
                ? _value.autoRenew
                : autoRenew // ignore: cast_nullable_to_non_nullable
                      as bool,
            razorpaySubscriptionId: freezed == razorpaySubscriptionId
                ? _value.razorpaySubscriptionId
                : razorpaySubscriptionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            razorpayCustomerId: freezed == razorpayCustomerId
                ? _value.razorpayCustomerId
                : razorpayCustomerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancelReason: freezed == cancelReason
                ? _value.cancelReason
                : cancelReason // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$SubscriptionImplCopyWith<$Res>
    implements $SubscriptionCopyWith<$Res> {
  factory _$$SubscriptionImplCopyWith(
    _$SubscriptionImpl value,
    $Res Function(_$SubscriptionImpl) then,
  ) = __$$SubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String planId,
    String status,
    String billingCycle,
    DateTime startDate,
    DateTime? endDate,
    DateTime? nextBillingDate,
    bool autoRenew,
    String? razorpaySubscriptionId,
    String? razorpayCustomerId,
    DateTime? cancelledAt,
    String? cancelReason,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SubscriptionImplCopyWithImpl<$Res>
    extends _$SubscriptionCopyWithImpl<$Res, _$SubscriptionImpl>
    implements _$$SubscriptionImplCopyWith<$Res> {
  __$$SubscriptionImplCopyWithImpl(
    _$SubscriptionImpl _value,
    $Res Function(_$SubscriptionImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = null,
    Object? status = null,
    Object? billingCycle = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? nextBillingDate = freezed,
    Object? autoRenew = null,
    Object? razorpaySubscriptionId = freezed,
    Object? razorpayCustomerId = freezed,
    Object? cancelledAt = freezed,
    Object? cancelReason = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SubscriptionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        planId: null == planId
            ? _value.planId
            : planId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        billingCycle: null == billingCycle
            ? _value.billingCycle
            : billingCycle // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        nextBillingDate: freezed == nextBillingDate
            ? _value.nextBillingDate
            : nextBillingDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        autoRenew: null == autoRenew
            ? _value.autoRenew
            : autoRenew // ignore: cast_nullable_to_non_nullable
                  as bool,
        razorpaySubscriptionId: freezed == razorpaySubscriptionId
            ? _value.razorpaySubscriptionId
            : razorpaySubscriptionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        razorpayCustomerId: freezed == razorpayCustomerId
            ? _value.razorpayCustomerId
            : razorpayCustomerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancelReason: freezed == cancelReason
            ? _value.cancelReason
            : cancelReason // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$SubscriptionImpl implements _Subscription {
  const _$SubscriptionImpl({
    required this.id,
    required this.userId,
    required this.planId,
    this.status = 'active',
    this.billingCycle = 'monthly',
    required this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.autoRenew = true,
    this.razorpaySubscriptionId,
    this.razorpayCustomerId,
    this.cancelledAt,
    this.cancelReason,
    this.updatedAt,
  });

  factory _$SubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String planId;
  @override
  @JsonKey()
  final String status;
  // active, expired, cancelled
  @override
  @JsonKey()
  final String billingCycle;
  // monthly, yearly
  @override
  final DateTime startDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime? nextBillingDate;
  @override
  @JsonKey()
  final bool autoRenew;
  @override
  final String? razorpaySubscriptionId;
  @override
  final String? razorpayCustomerId;
  @override
  final DateTime? cancelledAt;
  @override
  final String? cancelReason;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, planId: $planId, status: $status, billingCycle: $billingCycle, startDate: $startDate, endDate: $endDate, nextBillingDate: $nextBillingDate, autoRenew: $autoRenew, razorpaySubscriptionId: $razorpaySubscriptionId, razorpayCustomerId: $razorpayCustomerId, cancelledAt: $cancelledAt, cancelReason: $cancelReason, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.billingCycle, billingCycle) ||
                other.billingCycle == billingCycle) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.nextBillingDate, nextBillingDate) ||
                other.nextBillingDate == nextBillingDate) &&
            (identical(other.autoRenew, autoRenew) ||
                other.autoRenew == autoRenew) &&
            (identical(other.razorpaySubscriptionId, razorpaySubscriptionId) ||
                other.razorpaySubscriptionId == razorpaySubscriptionId) &&
            (identical(other.razorpayCustomerId, razorpayCustomerId) ||
                other.razorpayCustomerId == razorpayCustomerId) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.cancelReason, cancelReason) ||
                other.cancelReason == cancelReason) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    planId,
    status,
    billingCycle,
    startDate,
    endDate,
    nextBillingDate,
    autoRenew,
    razorpaySubscriptionId,
    razorpayCustomerId,
    cancelledAt,
    cancelReason,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      __$$SubscriptionImplCopyWithImpl<_$SubscriptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionImplToJson(this);
  }
}

abstract class _Subscription implements Subscription {
  const factory _Subscription({
    required final String id,
    required final String userId,
    required final String planId,
    final String status,
    final String billingCycle,
    required final DateTime startDate,
    final DateTime? endDate,
    final DateTime? nextBillingDate,
    final bool autoRenew,
    final String? razorpaySubscriptionId,
    final String? razorpayCustomerId,
    final DateTime? cancelledAt,
    final String? cancelReason,
    final DateTime? updatedAt,
  }) = _$SubscriptionImpl;

  factory _Subscription.fromJson(Map<String, dynamic> json) =
      _$SubscriptionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get planId;
  @override
  String get status;
  @override // active, expired, cancelled
  String get billingCycle;
  @override // monthly, yearly
  DateTime get startDate;
  @override
  DateTime? get endDate;
  @override
  DateTime? get nextBillingDate;
  @override
  bool get autoRenew;
  @override
  String? get razorpaySubscriptionId;
  @override
  String? get razorpayCustomerId;
  @override
  DateTime? get cancelledAt;
  @override
  String? get cancelReason;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get subscriptionId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get paymentMethod =>
      throw _privateConstructorUsedError; // card, upi, wallet
  String get status =>
      throw _privateConstructorUsedError; // pending, completed, failed
  String? get razorpayPaymentId => throw _privateConstructorUsedError;
  String? get razorpayOrderId => throw _privateConstructorUsedError;
  String? get orderId => throw _privateConstructorUsedError;
  String? get receipt => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;
  double? get refundedAmount => throw _privateConstructorUsedError;
  DateTime? get refundedAt => throw _privateConstructorUsedError;
  DateTime get transactionDate => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call({
    String id,
    String userId,
    String? subscriptionId,
    double amount,
    String currency,
    String paymentMethod,
    String status,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? orderId,
    String? receipt,
    String? failureReason,
    double? refundedAmount,
    DateTime? refundedAt,
    DateTime transactionDate,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subscriptionId = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? razorpayPaymentId = freezed,
    Object? razorpayOrderId = freezed,
    Object? orderId = freezed,
    Object? receipt = freezed,
    Object? failureReason = freezed,
    Object? refundedAmount = freezed,
    Object? refundedAt = freezed,
    Object? transactionDate = null,
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
            subscriptionId: freezed == subscriptionId
                ? _value.subscriptionId
                : subscriptionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            razorpayPaymentId: freezed == razorpayPaymentId
                ? _value.razorpayPaymentId
                : razorpayPaymentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            razorpayOrderId: freezed == razorpayOrderId
                ? _value.razorpayOrderId
                : razorpayOrderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            orderId: freezed == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            receipt: freezed == receipt
                ? _value.receipt
                : receipt // ignore: cast_nullable_to_non_nullable
                      as String?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            refundedAmount: freezed == refundedAmount
                ? _value.refundedAmount
                : refundedAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            refundedAt: freezed == refundedAt
                ? _value.refundedAt
                : refundedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            transactionDate: null == transactionDate
                ? _value.transactionDate
                : transactionDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
    _$PaymentImpl value,
    $Res Function(_$PaymentImpl) then,
  ) = __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String? subscriptionId,
    double amount,
    String currency,
    String paymentMethod,
    String status,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? orderId,
    String? receipt,
    String? failureReason,
    double? refundedAmount,
    DateTime? refundedAt,
    DateTime transactionDate,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
    _$PaymentImpl _value,
    $Res Function(_$PaymentImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? subscriptionId = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? razorpayPaymentId = freezed,
    Object? razorpayOrderId = freezed,
    Object? orderId = freezed,
    Object? receipt = freezed,
    Object? failureReason = freezed,
    Object? refundedAmount = freezed,
    Object? refundedAt = freezed,
    Object? transactionDate = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$PaymentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        subscriptionId: freezed == subscriptionId
            ? _value.subscriptionId
            : subscriptionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        razorpayPaymentId: freezed == razorpayPaymentId
            ? _value.razorpayPaymentId
            : razorpayPaymentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        razorpayOrderId: freezed == razorpayOrderId
            ? _value.razorpayOrderId
            : razorpayOrderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderId: freezed == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        receipt: freezed == receipt
            ? _value.receipt
            : receipt // ignore: cast_nullable_to_non_nullable
                  as String?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        refundedAmount: freezed == refundedAmount
            ? _value.refundedAmount
            : refundedAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        refundedAt: freezed == refundedAt
            ? _value.refundedAt
            : refundedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        transactionDate: null == transactionDate
            ? _value.transactionDate
            : transactionDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
class _$PaymentImpl implements _Payment {
  const _$PaymentImpl({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.amount,
    this.currency = 'INR',
    this.paymentMethod = 'card',
    this.status = 'completed',
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.orderId,
    this.receipt,
    this.failureReason,
    this.refundedAmount,
    this.refundedAt,
    required this.transactionDate,
    this.createdAt,
  });

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? subscriptionId;
  @override
  final double amount;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final String paymentMethod;
  // card, upi, wallet
  @override
  @JsonKey()
  final String status;
  // pending, completed, failed
  @override
  final String? razorpayPaymentId;
  @override
  final String? razorpayOrderId;
  @override
  final String? orderId;
  @override
  final String? receipt;
  @override
  final String? failureReason;
  @override
  final double? refundedAmount;
  @override
  final DateTime? refundedAt;
  @override
  final DateTime transactionDate;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Payment(id: $id, userId: $userId, subscriptionId: $subscriptionId, amount: $amount, currency: $currency, paymentMethod: $paymentMethod, status: $status, razorpayPaymentId: $razorpayPaymentId, razorpayOrderId: $razorpayOrderId, orderId: $orderId, receipt: $receipt, failureReason: $failureReason, refundedAmount: $refundedAmount, refundedAt: $refundedAt, transactionDate: $transactionDate, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.subscriptionId, subscriptionId) ||
                other.subscriptionId == subscriptionId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.razorpayPaymentId, razorpayPaymentId) ||
                other.razorpayPaymentId == razorpayPaymentId) &&
            (identical(other.razorpayOrderId, razorpayOrderId) ||
                other.razorpayOrderId == razorpayOrderId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.receipt, receipt) || other.receipt == receipt) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.refundedAmount, refundedAmount) ||
                other.refundedAmount == refundedAmount) &&
            (identical(other.refundedAt, refundedAt) ||
                other.refundedAt == refundedAt) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    subscriptionId,
    amount,
    currency,
    paymentMethod,
    status,
    razorpayPaymentId,
    razorpayOrderId,
    orderId,
    receipt,
    failureReason,
    refundedAmount,
    refundedAt,
    transactionDate,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(this);
  }
}

abstract class _Payment implements Payment {
  const factory _Payment({
    required final String id,
    required final String userId,
    final String? subscriptionId,
    required final double amount,
    final String currency,
    final String paymentMethod,
    final String status,
    final String? razorpayPaymentId,
    final String? razorpayOrderId,
    final String? orderId,
    final String? receipt,
    final String? failureReason,
    final double? refundedAmount,
    final DateTime? refundedAt,
    required final DateTime transactionDate,
    final DateTime? createdAt,
  }) = _$PaymentImpl;

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get subscriptionId;
  @override
  double get amount;
  @override
  String get currency;
  @override
  String get paymentMethod;
  @override // card, upi, wallet
  String get status;
  @override // pending, completed, failed
  String? get razorpayPaymentId;
  @override
  String? get razorpayOrderId;
  @override
  String? get orderId;
  @override
  String? get receipt;
  @override
  String? get failureReason;
  @override
  double? get refundedAmount;
  @override
  DateTime? get refundedAt;
  @override
  DateTime get transactionDate;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
