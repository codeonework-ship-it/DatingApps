// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionPlanImpl _$$SubscriptionPlanImplFromJson(
  Map<String, dynamic> json,
) => _$SubscriptionPlanImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
  yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
  likesPerDay: (json['likesPerDay'] as num?)?.toInt() ?? 10,
  messagesPerDay: (json['messagesPerDay'] as num?)?.toInt() ?? 20,
  advancedFilters: json['advancedFilters'] as bool? ?? false,
  verifiedBadge: json['verifiedBadge'] as bool? ?? false,
  prioritySupport: json['prioritySupport'] as bool? ?? false,
  features: json['features'] as Map<String, dynamic>? ?? const {},
  description: json['description'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$SubscriptionPlanImplToJson(
  _$SubscriptionPlanImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'monthlyPrice': instance.monthlyPrice,
  'yearlyPrice': instance.yearlyPrice,
  'likesPerDay': instance.likesPerDay,
  'messagesPerDay': instance.messagesPerDay,
  'advancedFilters': instance.advancedFilters,
  'verifiedBadge': instance.verifiedBadge,
  'prioritySupport': instance.prioritySupport,
  'features': instance.features,
  'description': instance.description,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      status: json['status'] as String? ?? 'active',
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      nextBillingDate: json['nextBillingDate'] == null
          ? null
          : DateTime.parse(json['nextBillingDate'] as String),
      autoRenew: json['autoRenew'] as bool? ?? true,
      razorpaySubscriptionId: json['razorpaySubscriptionId'] as String?,
      razorpayCustomerId: json['razorpayCustomerId'] as String?,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      cancelReason: json['cancelReason'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'planId': instance.planId,
      'status': instance.status,
      'billingCycle': instance.billingCycle,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'nextBillingDate': instance.nextBillingDate?.toIso8601String(),
      'autoRenew': instance.autoRenew,
      'razorpaySubscriptionId': instance.razorpaySubscriptionId,
      'razorpayCustomerId': instance.razorpayCustomerId,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'cancelReason': instance.cancelReason,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      paymentMethod: json['paymentMethod'] as String? ?? 'card',
      status: json['status'] as String? ?? 'completed',
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      orderId: json['orderId'] as String?,
      receipt: json['receipt'] as String?,
      failureReason: json['failureReason'] as String?,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble(),
      refundedAt: json['refundedAt'] == null
          ? null
          : DateTime.parse(json['refundedAt'] as String),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subscriptionId': instance.subscriptionId,
      'amount': instance.amount,
      'currency': instance.currency,
      'paymentMethod': instance.paymentMethod,
      'status': instance.status,
      'razorpayPaymentId': instance.razorpayPaymentId,
      'razorpayOrderId': instance.razorpayOrderId,
      'orderId': instance.orderId,
      'receipt': instance.receipt,
      'failureReason': instance.failureReason,
      'refundedAmount': instance.refundedAmount,
      'refundedAt': instance.refundedAt?.toIso8601String(),
      'transactionDate': instance.transactionDate.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
