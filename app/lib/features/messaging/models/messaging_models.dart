import 'package:freezed_annotation/freezed_annotation.dart';

part 'messaging_models.freezed.dart';
part 'messaging_models.g.dart';

/// Chat message between matched users
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String matchId,
    required String senderId,
    required String text,
    required DateTime createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    @Default(false) bool isDeleted,
    DateTime? deletedAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
