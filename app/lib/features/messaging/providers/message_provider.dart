import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/messaging_models.dart' as models;

part 'message_provider.g.dart';

/// Message State
class MessageState {
  const MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.isChatLocked = false,
    this.unlockState,
    this.unlockPolicyVariant,
  });
  final List<models.Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final bool isChatLocked;
  final String? unlockState;
  final String? unlockPolicyVariant;

  MessageState copyWith({
    List<models.Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    bool? isChatLocked,
    String? unlockState,
    String? unlockPolicyVariant,
  }) => MessageState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    isTyping: isTyping ?? this.isTyping,
    isChatLocked: isChatLocked ?? this.isChatLocked,
    unlockState: unlockState ?? this.unlockState,
    unlockPolicyVariant: unlockPolicyVariant ?? this.unlockPolicyVariant,
  );
}

/// Message Provider for specific match
@riverpod
class MessageNotifier extends _$MessageNotifier {
  String? _currentMatchId;
  Timer? _pollTimer;

  @override
  MessageState build(String matchId) {
    _currentMatchId = matchId;
    Future<void>.microtask(() => _loadMessages(matchId));
    if (!kUseMockAuth) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _loadMessages(matchId, showLoader: false);
      });
    }
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const MessageState(isLoading: true);
  }

  /// Load messages from gateway API
  Future<void> _loadMessages(String matchId, {bool showLoader = true}) async {
    if (showLoader) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 160));
        final currentUserId =
            ref.read(authNotifierProvider).userId ??
            AppRuntimeConfig.mockFallbackUserId;
        state = state.copyWith(
          messages: _mockMessages(matchId, currentUserId),
          isLoading: false,
          error: null,
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/chat/$matchId/messages',
        queryParameters: {'limit': 100},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final raw = (body['messages'] as List?) ?? const [];

      final messages = raw
          .whereType<Map<String, dynamic>>()
          .map(
            (map) => models.Message.fromJson({
              'id': map['id']?.toString() ?? '',
              'matchId': map['matchId']?.toString() ?? matchId,
              'senderId': map['senderId']?.toString() ?? '',
              'text': map['text']?.toString() ?? '',
              'createdAt':
                  map['createdAt']?.toString() ??
                  DateTime.now().toIso8601String(),
              'deliveredAt': map['deliveredAt']?.toString(),
              'readAt': map['readAt']?.toString(),
              'isDeleted': map['isDeleted'] == true,
              'deletedAt': map['deletedAt']?.toString(),
            }),
          )
          .toList();

      state = state.copyWith(messages: messages, isLoading: false, error: null);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load messages', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load messages. Please try again.',
        isLoading: false,
        isChatLocked: false,
      );
    } catch (e, stackTrace) {
      log.error('Failed to load messages', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load messages. Please try again.',
        isLoading: false,
        isChatLocked: false,
      );
    }
  }

  /// Send message
  Future<void> sendMessage(String text) async {
    if (text.isEmpty || _currentMatchId == null) return;

    try {
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null) return;

      if (kUseMockAuth) {
        final message = models.Message(
          id: 'mock-msg-${DateTime.now().millisecondsSinceEpoch}',
          matchId: _currentMatchId!,
          senderId: currentUserId,
          text: text,
          createdAt: DateTime.now(),
          deliveredAt: DateTime.now(),
          readAt: null,
          isDeleted: false,
          deletedAt: null,
        );
        state = state.copyWith(messages: [message, ...state.messages]);
        return;
      }

      final dio = ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/chat/${_currentMatchId!}/messages',
        data: {'sender_id': currentUserId, 'text': text},
      );
      state = state.copyWith(
        error: null,
        isChatLocked: false,
        unlockState: null,
        unlockPolicyVariant: null,
      );
      await _loadMessages(_currentMatchId!, showLoader: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to send message', e, stackTrace);
      final body = (e.response?.data as Map?)?.cast<String, dynamic>();
      final errorCode = (body?['error_code'] ?? '').toString();
      if (errorCode == 'CHAT_LOCKED_REQUIREMENT_PENDING') {
        state = state.copyWith(
          error: 'Chat is locked until the quest is approved.',
          isChatLocked: true,
          unlockState: (body?['unlock_state'] ?? '').toString(),
          unlockPolicyVariant: (body?['unlock_policy_variant'] ?? '')
              .toString(),
        );
        return;
      }
      state = state.copyWith(
        error: 'Failed to send message.',
        isChatLocked: false,
        unlockPolicyVariant: null,
      );
    } catch (e, stackTrace) {
      log.error('Failed to send message', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to send message.',
        isChatLocked: false,
        unlockPolicyVariant: null,
      );
    }
  }

  /// Update typing status
  void setTyping(bool isTyping) {
    state = state.copyWith(isTyping: isTyping);
  }
}

List<models.Message> _mockMessages(String matchId, String currentUserId) {
  final otherUserId = _mockOtherUserForMatch(matchId);
  final now = DateTime.now();

  return <models.Message>[
    models.Message(
      id: 'mock-msg-001-$matchId',
      matchId: matchId,
      senderId: otherUserId,
      text: 'Hey! Great to match with you.',
      createdAt: now.subtract(const Duration(minutes: 30)),
      deliveredAt: now.subtract(const Duration(minutes: 30)),
      readAt: now.subtract(const Duration(minutes: 20)),
      isDeleted: false,
      deletedAt: null,
    ),
    models.Message(
      id: 'mock-msg-002-$matchId',
      matchId: matchId,
      senderId: currentUserId,
      text: 'Nice to meet you too!',
      createdAt: now.subtract(const Duration(minutes: 25)),
      deliveredAt: now.subtract(const Duration(minutes: 25)),
      readAt: now.subtract(const Duration(minutes: 20)),
      isDeleted: false,
      deletedAt: null,
    ),
    models.Message(
      id: 'mock-msg-003-$matchId',
      matchId: matchId,
      senderId: otherUserId,
      text: 'How was your weekend?',
      createdAt: now.subtract(const Duration(minutes: 10)),
      deliveredAt: now.subtract(const Duration(minutes: 10)),
      readAt: null,
      isDeleted: false,
      deletedAt: null,
    ),
  ];
}

String _mockOtherUserForMatch(String matchId) {
  if (matchId.contains('mock-user-004')) {
    return 'mock-user-004';
  }
  if (matchId.contains('mock-user-002')) {
    return 'mock-user-002';
  }
  return 'mock-user-002';
}
