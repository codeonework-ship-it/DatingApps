/// Friend vouches and friend-made intros (BFF `/friends/{id}/vouches`,
/// `/friends/{id}/intros`, `/users/{id}/vouches`).
library;

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
    subjectName: json['subject_name']?.toString() ?? 'A member',
    voucherUserId: json['voucher_user_id']?.toString() ?? '',
    voucherName: json['voucher_name']?.toString() ?? 'A friend',
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
    voucherName: json['voucher_name']?.toString() ?? 'A friend',
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
    name: json['name']?.toString() ?? 'A member',
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
    introducerName: json['introducer_name']?.toString() ?? 'A friend',
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
