import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_models.freezed.dart';
part 'payment_models.g.dart';

/// Subscription plan (pricing tier)
@freezed
class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String name, // Free, Premium, VIP
    required double monthlyPrice,
    required double yearlyPrice,
    @Default(10) int likesPerDay,
    @Default(20) int messagesPerDay,
    @Default(false) bool advancedFilters,
    @Default(false) bool verifiedBadge,
    @Default(false) bool prioritySupport,
    @Default({}) Map<String, dynamic> features,
    String? description,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}

/// User subscription
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String userId,
    required String planId,
    required DateTime startDate,
    @Default('active') String status, // active, expired, cancelled
    @Default('monthly') String billingCycle, // monthly, yearly
    DateTime? endDate,
    DateTime? nextBillingDate,
    @Default(true) bool autoRenew,
    String? razorpaySubscriptionId,
    String? razorpayCustomerId,
    DateTime? cancelledAt,
    String? cancelReason,
    DateTime? updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

/// Payment transaction
@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String userId,
    required double amount,
    required DateTime transactionDate,
    String? subscriptionId,
    @Default('INR') String currency,
    @Default('card') String paymentMethod, // card, upi, wallet
    @Default('completed') String status, // pending, completed, failed
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? orderId,
    String? receipt,
    String? failureReason,
    double? refundedAmount,
    DateTime? refundedAt,
    DateTime? createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
