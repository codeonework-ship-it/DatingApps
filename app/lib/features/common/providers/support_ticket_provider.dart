import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.priority,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 1,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id']?.toString() ?? '',
    category: json['category']?.toString() ?? 'technical',
    priority: json['priority']?.toString() ?? 'normal',
    subject: json['subject']?.toString() ?? '',
    status: json['status']?.toString() ?? 'open',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    messageCount: (json['message_count'] as num?)?.toInt() ?? 1,
  );

  final String id;
  final String category;
  final String priority;
  final String subject;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messageCount;
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id']?.toString() ?? '',
    authorRole: json['author_role']?.toString() ?? 'member',
    body: json['body']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );

  final String id;
  final String authorRole;
  final String body;
  final DateTime? createdAt;
}

class SupportConversation {
  const SupportConversation({required this.ticket, required this.messages});

  final SupportTicket ticket;
  final List<SupportMessage> messages;
}

final supportTicketsProvider =
    AsyncNotifierProvider<SupportTicketsNotifier, List<SupportTicket>>(
      SupportTicketsNotifier.new,
    );

class SupportTicketsNotifier extends AsyncNotifier<List<SupportTicket>> {
  final Map<String, List<SupportMessage>> _mockMessages = {};

  @override
  Future<List<SupportTicket>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading<List<SupportTicket>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create({
    required String category,
    required String priority,
    required String subject,
    required String body,
  }) async {
    final current = state.valueOrNull ?? const <SupportTicket>[];
    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      state = AsyncData([
        SupportTicket(
          id: 'local-${now.microsecondsSinceEpoch}',
          category: category,
          priority: category == 'safety' ? 'high' : priority,
          subject: subject,
          status: 'open',
          createdAt: now,
          updatedAt: now,
        ),
        ...current,
      ]);
      _mockMessages[state.requireValue.first.id] = [
        SupportMessage(
          id: 'message-${now.microsecondsSinceEpoch}',
          authorRole: 'member',
          body: body,
          createdAt: now,
        ),
      ];
      return;
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            '/support/tickets',
            data: {
              'category': category,
              'priority': priority,
              'subject': subject.trim(),
              'body': body.trim(),
            },
          );
      final ticket = (response.data?['ticket'] as Map?)
          ?.cast<String, dynamic>();
      if (ticket != null) {
        state = AsyncData([SupportTicket.fromJson(ticket), ...current]);
      } else {
        state = AsyncData(await _fetch());
      }
    } on DioException catch (error, stackTrace) {
      log.error('Failed to create support ticket', error, stackTrace);
      throw StateError(_message(error, 'Unable to create the support ticket.'));
    }
  }

  Future<SupportConversation> loadConversation(SupportTicket ticket) async {
    if (kUseMockAuth) {
      return SupportConversation(
        ticket: ticket,
        messages: _mockMessages[ticket.id] ?? const <SupportMessage>[],
      );
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/support/tickets/${ticket.id}');
      final body = response.data ?? const <String, dynamic>{};
      final ticketJson = (body['ticket'] as Map?)?.cast<String, dynamic>();
      final rows = body['messages'] as List? ?? const <dynamic>[];
      return SupportConversation(
        ticket: ticketJson == null
            ? ticket
            : SupportTicket.fromJson(ticketJson),
        messages: rows
            .whereType<Map<dynamic, dynamic>>()
            .map((row) => SupportMessage.fromJson(row.cast<String, dynamic>()))
            .toList(growable: false),
      );
    } on DioException catch (error, stackTrace) {
      log.error('Failed to load support conversation', error, stackTrace);
      throw StateError(_message(error, 'Unable to load this conversation.'));
    }
  }

  Future<SupportConversation> reply(
    SupportConversation conversation,
    String body,
  ) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 4000) {
      throw StateError('Reply must contain 1-4000 characters.');
    }
    if (kUseMockAuth) {
      final now = DateTime.now().toUtc();
      final messages = [
        ...conversation.messages,
        SupportMessage(
          id: 'message-${now.microsecondsSinceEpoch}',
          authorRole: 'member',
          body: trimmed,
          createdAt: now,
        ),
      ];
      _mockMessages[conversation.ticket.id] = messages;
      return SupportConversation(
        ticket: conversation.ticket,
        messages: messages,
      );
    }
    try {
      await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            '/support/tickets/${conversation.ticket.id}/messages',
            data: {'body': trimmed},
          );
      await refresh();
      return loadConversation(conversation.ticket);
    } on DioException catch (error, stackTrace) {
      log.error('Failed to reply to support ticket', error, stackTrace);
      throw StateError(_message(error, 'Unable to send this reply.'));
    }
  }

  Future<List<SupportTicket>> _fetch() async {
    if (kUseMockAuth) {
      return state.valueOrNull ?? const <SupportTicket>[];
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/support/tickets');
      final rows = response.data?['tickets'] as List? ?? const <dynamic>[];
      return rows
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => SupportTicket.fromJson(row.cast<String, dynamic>()))
          .where((ticket) => ticket.id.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error, stackTrace) {
      log.error('Failed to load support tickets', error, stackTrace);
      if (error.response?.statusCode == 403) {
        return state.valueOrNull ?? const <SupportTicket>[];
      }
      throw StateError(_message(error, 'Unable to load support tickets.'));
    }
  }

  String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
