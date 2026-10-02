import 'package:flutter/foundation.dart';

/// Support ticket data as the member API returns it (`/v1/support/...`).
///
/// Field names follow the server contract exactly; nothing here is invented
/// on the client.

/// The categories a member can choose, in display order.
const supportCategories = <String>[
  'account_login',
  'verification',
  'payments_billing',
  'safety_harassment',
  'matches_chat',
  'technical',
  'feature_request',
  'privacy_data',
  'other',
];

/// The category whose requests are prioritised by the safety team.
const supportSafetyCategory = 'safety_harassment';

/// Limits enforced by the server, mirrored so the form can explain them.
abstract final class SupportLimits {
  static const subjectMin = 4;
  static const subjectMax = 120;
  static const bodyMax = 5000;
  static const ratingCommentMax = 1000;
  static const attachmentsPerMessage = 5;
}

/// Member-facing status groups. `new` and `open` both read as "Open".
enum SupportStatus {
  open,
  pendingMember,
  onHold,
  resolved,
  closed;

  static SupportStatus parse(String raw) => switch (raw) {
    'pending_member' => SupportStatus.pendingMember,
    'on_hold' => SupportStatus.onHold,
    'resolved' => SupportStatus.resolved,
    'closed' => SupportStatus.closed,
    _ => SupportStatus.open,
  };

  bool get isActive =>
      this != SupportStatus.resolved && this != SupportStatus.closed;
}

DateTime? _date(Object? value) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
}

int _int(Object? value) => value is num ? value.toInt() : 0;

String _text(Object? value) => value?.toString() ?? '';

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : null;

@immutable
class SupportSatisfaction {
  const SupportSatisfaction({
    required this.rating,
    this.comment = '',
    this.ratedAt,
  });

  factory SupportSatisfaction.fromJson(Map<String, dynamic> json) =>
      SupportSatisfaction(
        rating: _int(json['rating']),
        comment: _text(json['comment']),
        ratedAt: _date(json['rated_at']),
      );

  final int rating;
  final String comment;
  final DateTime? ratedAt;
}

@immutable
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.category,
    required this.subject,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.lastActivityAt,
    this.resolvedAt,
    this.closedAt,
    this.reopenUntil,
    this.messageCount = 0,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageAuthor = '',
    this.canReply = false,
    this.canClose = false,
    this.canReopen = false,
    this.canRate = false,
    this.satisfaction,
    this.mergedIntoReference,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final satisfaction = _map(json['satisfaction']);
    final merged = _text(json['merged_into_reference']);
    return SupportTicket(
      id: _text(json['id']),
      reference: _text(json['reference']),
      category: _text(json['category']),
      subject: _text(json['subject']),
      status: _text(json['status']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      lastActivityAt: _date(json['last_activity_at']),
      resolvedAt: _date(json['resolved_at']),
      closedAt: _date(json['closed_at']),
      reopenUntil: _date(json['reopen_until']),
      messageCount: _int(json['message_count']),
      unreadCount: _int(json['unread_count']),
      lastMessagePreview: _text(json['last_message_preview']),
      lastMessageAuthor: _text(json['last_message_author']),
      canReply: json['can_reply'] == true,
      canClose: json['can_close'] == true,
      canReopen: json['can_reopen'] == true,
      canRate: json['can_rate'] == true,
      satisfaction: satisfaction == null
          ? null
          : SupportSatisfaction.fromJson(satisfaction),
      mergedIntoReference: merged.isEmpty ? null : merged,
    );
  }

  final String id;
  final String reference;
  final String category;
  final String subject;

  /// The raw server status: new, open, pending_member, on_hold, resolved,
  /// closed.
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActivityAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? reopenUntil;
  final int messageCount;
  final int unreadCount;
  final String lastMessagePreview;
  final String lastMessageAuthor;
  final bool canReply;
  final bool canClose;
  final bool canReopen;
  final bool canRate;
  final SupportSatisfaction? satisfaction;
  final String? mergedIntoReference;

  SupportStatus get memberStatus => SupportStatus.parse(status);

  DateTime? get activityAt => lastActivityAt ?? updatedAt ?? createdAt;
}

@immutable
class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    this.url = '',
  });

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      SupportAttachment(
        id: _text(json['id']),
        filename: _text(json['filename']),
        contentType: _text(json['content_type']),
        sizeBytes: _int(json['size_bytes']),
        url: _text(json['url']),
      );

  final String id;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String url;

  bool get isImage => contentType.startsWith('image/');
}

@immutable
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.author,
    required this.body,
    this.authorName,
    this.createdAt,
    this.attachments = const [],
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final rows = json['attachments'];
    return SupportMessage(
      id: _text(json['id']),
      author: _text(json['author']),
      authorName: json['author_name']?.toString(),
      body: _text(json['body']),
      createdAt: _date(json['created_at']),
      attachments: rows is List
          ? rows
                .whereType<Map<dynamic, dynamic>>()
                .map((row) => SupportAttachment.fromJson(row.cast()))
                .toList(growable: false)
          : const [],
    );
  }

  /// `member`, `agent` or `system`.
  final String author;
  final String id;
  final String? authorName;
  final String body;
  final DateTime? createdAt;
  final List<SupportAttachment> attachments;

  bool get fromMember => author == 'member';
  bool get fromSystem => author == 'system';
}

/// A ticket and its public messages.
@immutable
class SupportThread {
  const SupportThread({required this.ticket, required this.messages});

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final rows = json['messages'];
    return SupportThread(
      ticket: SupportTicket.fromJson(_map(json['ticket']) ?? const {}),
      messages: rows is List
          ? rows
                .whereType<Map<dynamic, dynamic>>()
                .map((row) => SupportMessage.fromJson(row.cast()))
                .toList(growable: false)
          : const [],
    );
  }

  final SupportTicket ticket;
  final List<SupportMessage> messages;

  SupportThread copyWith({
    SupportTicket? ticket,
    List<SupportMessage>? messages,
  }) => SupportThread(
    ticket: ticket ?? this.ticket,
    messages: messages ?? this.messages,
  );
}

/// The result of raising a ticket. [duplicate] is true when the server
/// recognised the same request from the last ten minutes and returned it
/// instead of opening a second one.
@immutable
class SupportCreateResult {
  const SupportCreateResult({required this.thread, required this.duplicate});

  final SupportThread thread;
  final bool duplicate;
}

/// The member's tickets with the counts used for badges.
@immutable
class SupportTicketList {
  const SupportTicketList({
    required this.tickets,
    this.unreadTotal = 0,
    this.openTotal = 0,
  });

  factory SupportTicketList.fromJson(Map<String, dynamic> json) {
    final rows = json['tickets'];
    return SupportTicketList(
      tickets: rows is List
          ? rows
                .whereType<Map<dynamic, dynamic>>()
                .map((row) => SupportTicket.fromJson(row.cast()))
                .where((ticket) => ticket.id.isNotEmpty)
                .toList(growable: false)
          : const [],
      unreadTotal: _int(json['unread_total']),
      openTotal: _int(json['open_total']),
    );
  }

  final List<SupportTicket> tickets;
  final int unreadTotal;
  final int openTotal;
}

/// A file the server accepted for a ticket or reply.
@immutable
class SupportUpload {
  const SupportUpload({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
  });

  factory SupportUpload.fromJson(Map<String, dynamic> json) => SupportUpload(
    id: _text(json['id']),
    filename: _text(json['filename']),
    contentType: _text(json['content_type']),
    sizeBytes: _int(json['size_bytes']),
  );

  final String id;
  final String filename;
  final String contentType;
  final int sizeBytes;
}

/// What the app attaches to a new ticket so support can reproduce problems.
@immutable
class SupportDeviceContext {
  const SupportDeviceContext({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.locale,
    this.deviceModel = '',
  });

  final String appVersion;
  final String platform;
  final String osVersion;
  final String locale;

  /// Left empty: the app deliberately does not read a device model name.
  final String deviceModel;

  Map<String, dynamic> toJson() => {
    if (appVersion.isNotEmpty) 'app_version': appVersion,
    if (platform.isNotEmpty) 'platform': platform,
    if (osVersion.isNotEmpty) 'os_version': osVersion,
    if (deviceModel.isNotEmpty) 'device_model': deviceModel,
    if (locale.isNotEmpty) 'locale': locale,
  };
}

/// A failed support call, carrying the server's `error_code` so screens can
/// explain it. Never swallowed into fake success.
class SupportException implements Exception {
  const SupportException({
    this.code = '',
    this.message = '',
    this.statusCode,
    this.retryAfterSeconds,
    this.offline = false,
  });

  final String code;

  /// The server's own (English) message, shown when the code is unknown.
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  /// True when the server could not be reached at all.
  final bool offline;

  bool get featureDisabled => code == 'FEATURE_DISABLED';

  @override
  String toString() =>
      'SupportException($statusCode${code.isEmpty ? '' : ' $code'}'
      '${message.isEmpty ? '' : ': $message'})';
}
