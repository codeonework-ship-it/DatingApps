/// Friend vouches and friend-made intros (BFF `/friends/{id}/vouches`,
/// `/friends/{id}/intros`, `/users/{id}/vouches`).
///
/// Names are empty when the server sent none; widgets show the localized
/// fallbacks from the `*Label(l10n)` extensions at the bottom of this file.
library;

import '../../../l10n/app_localizations.dart';

class FriendVouch {
  const FriendVouch({
    required this.id,
    required this.subjectUserId,
    required this.subjectName,
    required this.voucherUserId,
    required this.voucherName,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  factory FriendVouch.fromJson(Map<String, dynamic> json) => FriendVouch(
    id: json['id']?.toString() ?? '',
    subjectUserId: json['subject_user_id']?.toString() ?? '',
    subjectName: json['subject_name']?.toString() ?? '',
    voucherUserId: json['voucher_user_id']?.toString() ?? '',
    voucherName: json['voucher_name']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    createdAt: json['created_at']?.toString() ?? '',
  );

  final String id;
  final String subjectUserId;
  final String subjectName;
  final String voucherUserId;
  final String voucherName;
  final String text;
  final String status;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}

class PublicVouch {
  const PublicVouch({required this.text, required this.voucherName});

  factory PublicVouch.fromJson(Map<String, dynamic> json) => PublicVouch(
    text: json['text']?.toString() ?? '',
    voucherName: json['voucher_name']?.toString() ?? '',
  );

  final String text;
  final String voucherName;
}

class IntroPreview {
  const IntroPreview({
    required this.userId,
    required this.name,
    this.age,
    this.city = '',
    this.isVerified = false,
    this.photoUrls = const <String>[],
  });

  factory IntroPreview.fromJson(Map<String, dynamic> json) => IntroPreview(
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    age: (json['age'] as num?)?.toInt(),
    city: json['city']?.toString() ?? '',
    isVerified: json['is_verified'] as bool? ?? false,
    photoUrls: (json['photo_urls'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(),
  );

  final String userId;
  final String name;
  final int? age;
  final String city;
  final bool isVerified;
  final List<String> photoUrls;
}

class FriendIntro {
  const FriendIntro({
    required this.id,
    required this.introducerUserId,
    required this.introducerName,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.message = '',
    this.myDecision = '',
    this.other,
    this.firstName = '',
    this.secondName = '',
    this.matchId = '',
  });

  factory FriendIntro.fromJson(Map<String, dynamic> json) => FriendIntro(
    id: json['id']?.toString() ?? '',
    introducerUserId: json['introducer_user_id']?.toString() ?? '',
    introducerName: json['introducer_name']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    status: json['status']?.toString() ?? 'open',
    myDecision: json['my_decision']?.toString() ?? '',
    other: json['other'] is Map<dynamic, dynamic>
        ? IntroPreview.fromJson(
            (json['other'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
          )
        : null,
    firstName: json['first_name']?.toString() ?? '',
    secondName: json['second_name']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    expiresAt: json['expires_at']?.toString() ?? '',
    createdAt: json['created_at']?.toString() ?? '',
  );

  final String id;
  final String introducerUserId;
  final String introducerName;
  final String message;
  final String status;
  final String myDecision;
  final IntroPreview? other;
  final String firstName;
  final String secondName;
  final String matchId;
  final String expiresAt;
  final String createdAt;

  bool get isOpen => status == 'open';
  bool get awaitingMe => isOpen && myDecision == 'pending';
  bool get isMatched => status == 'matched';
}

extension FriendVouchLabels on FriendVouch {
  /// The voucher's name, or "A friend" in the member's language.
  String voucherLabel(AppLocalizations l10n) =>
      _nameOr(voucherName, l10n.planSharingFriendFallback);
}

extension PublicVouchLabels on PublicVouch {
  /// The voucher's name, or "A friend" in the member's language.
  String voucherLabel(AppLocalizations l10n) =>
      _nameOr(voucherName, l10n.planSharingFriendFallback);
}

extension IntroPreviewLabels on IntroPreview {
  /// The introduced member's name, or "A member" in the member's language.
  String nameLabel(AppLocalizations l10n) =>
      _nameOr(name, l10n.friendsMemberFallback);
}

extension FriendIntroLabels on FriendIntro {
  /// The introducer's name, or "A friend" in the member's language.
  String introducerLabel(AppLocalizations l10n) =>
      _nameOr(introducerName, l10n.planSharingFriendFallback);
}

String _nameOr(String name, String fallback) =>
    name.trim().isEmpty ? fallback : name;
