import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/messaging_models.dart' as models;
import '../models/rose_gift.dart';

part 'message_provider.g.dart';

const _noValue = Object();

class _PendingDeleteSnapshot {
  const _PendingDeleteSnapshot({
    required this.message,
    required this.originalIndex,
  });

  final models.Message message;
  final int originalIndex;
}

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
    this.giftCatalog = RoseGift.phaseOneCatalog,
    this.walletCoins = 12,
    this.isSendingGift = false,
    this.pendingDeleteIds = const <String>{},
  });
  final List<models.Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final bool isChatLocked;
  final String? unlockState;
  final String? unlockPolicyVariant;
  final List<RoseGift> giftCatalog;
  final int walletCoins;
  final bool isSendingGift;
  final Set<String> pendingDeleteIds;

  MessageState copyWith({
    List<models.Message>? messages,
    bool? isLoading,
    Object? error = _noValue,
    bool? isTyping,
    bool? isChatLocked,
    String? unlockState,
    String? unlockPolicyVariant,
    List<RoseGift>? giftCatalog,
    int? walletCoins,
    bool? isSendingGift,
    Set<String>? pendingDeleteIds,
  }) => MessageState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: identical(error, _noValue) ? this.error : error as String?,
    isTyping: isTyping ?? this.isTyping,
    isChatLocked: isChatLocked ?? this.isChatLocked,
    unlockState: unlockState ?? this.unlockState,
    unlockPolicyVariant: unlockPolicyVariant ?? this.unlockPolicyVariant,
    giftCatalog: giftCatalog ?? this.giftCatalog,
    walletCoins: walletCoins ?? this.walletCoins,
    isSendingGift: isSendingGift ?? this.isSendingGift,
    pendingDeleteIds: pendingDeleteIds ?? this.pendingDeleteIds,
  );
}

class GestureGiftBundleResult {
  const GestureGiftBundleResult({
    required this.gestureSent,
    required this.giftAttempted,
    required this.giftSent,
    this.giftError,
  });

  final bool gestureSent;
  final bool giftAttempted;
  final bool giftSent;
  final String? giftError;
}

/// Message Provider for specific match
@riverpod
class MessageNotifier extends _$MessageNotifier {
  String? _currentMatchId;
  Timer? _pollTimer;
  final Map<String, Timer> _pendingDeleteTimers = <String, Timer>{};
  final Map<String, _PendingDeleteSnapshot> _pendingDeleteSnapshots =
      <String, _PendingDeleteSnapshot>{};
  final Map<String, models.Message> _senderDeletedPlaceholders =
      <String, models.Message>{};

  bool get _isLocalTestConversation =>
      (_currentMatchId ?? '').startsWith('local-match-');

  bool get _isPendingConversation =>
      (_currentMatchId ?? '').startsWith('pending-');

  bool get _usesLocalConversationSandbox =>
      _isPendingConversation || _isLocalTestConversation;

  @override
  MessageState build(String matchId) {
    _currentMatchId = matchId;
    if (kFeatureRoseGiftTray) {
      Future<void>.microtask(_loadRoseEconomy);
    }
    if (_usesLocalConversationSandbox) {
      return const MessageState(isLoading: false);
    }
    Future<void>.microtask(() => _loadMessages(matchId));
    if (!kUseMockAuth) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _loadMessages(matchId, showLoader: false);
      });
    }
    ref.onDispose(() {
      _pollTimer?.cancel();
      for (final timer in _pendingDeleteTimers.values) {
        timer.cancel();
      }
      _pendingDeleteTimers.clear();
      _pendingDeleteSnapshots.clear();
    });
    return const MessageState(
      isLoading: true,
      giftCatalog: RoseGift.phaseOneCatalog,
      walletCoins: 12,
    );
  }

  Future<void> _loadRoseEconomy() async {
    try {
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null || kUseMockAuth) {
        return;
      }

      final dio = ref.read(apiClientProvider);

      final catalogResponse = await dio.get<Map<String, dynamic>>(
        '/chat/gifts',
      );
      final catalogBody =
          (catalogResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final giftsRaw = (catalogBody['gifts'] as List?) ?? const [];
      final mappedGifts = giftsRaw
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final id = item['id']?.toString() ?? '';
            return RoseGift(
              id: id,
              name: item['name']?.toString() ?? '',
              gifUrl: RoseGift.resolvePreferredGifPathById(
                id,
                fallbackUrl: item['gif_url']?.toString(),
              ),
              iconKey: item['icon_key']?.toString(),
              priceCoins: (item['price_coins'] as num?)?.toInt() ?? 0,
              tier: item['tier']?.toString() ?? 'free',
              isLimited: item['is_limited'] == true,
            );
          })
          .where((gift) => gift.id.isNotEmpty && gift.name.isNotEmpty)
          .toList();

      final walletResponse = await dio.get<Map<String, dynamic>>(
        '/wallet/$currentUserId/coins',
      );
      final walletBody =
          (walletResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final wallet =
          (walletBody['wallet'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final walletCoins =
          (wallet['coin_balance'] as num?)?.toInt() ?? state.walletCoins;

      state = state.copyWith(
        giftCatalog: mappedGifts.isEmpty ? state.giftCatalog : mappedGifts,
        walletCoins: walletCoins,
      );
    } on DioException {
      // Keep local fallback catalog/wallet for development resilience.
    } on Object {
      // Keep local fallback catalog/wallet for development resilience.
    }
  }

  /// Load messages from gateway API
  Future<void> _loadMessages(String matchId, {bool showLoader = true}) async {
    if (_usesLocalConversationSandbox) {
      state = state.copyWith(isLoading: false, error: null);
      return;
    }

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

      var mergedMessages = messages;
      if (kShowDeletedPlaceholderForSender &&
          _senderDeletedPlaceholders.isNotEmpty) {
        final merged = [...messages];
        final existingIds = messages.map((item) => item.id).toSet();
        for (final placeholder in _senderDeletedPlaceholders.values) {
          if (!existingIds.contains(placeholder.id)) {
            merged.add(placeholder);
          }
        }
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        mergedMessages = merged;
      }

      state = state.copyWith(
        messages: mergedMessages,
        isLoading: false,
        error: null,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load messages', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load messages. Please try again.',
        isLoading: false,
        isChatLocked: false,
      );
    } on Object catch (e, stackTrace) {
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
    if (text.isEmpty || _currentMatchId == null) {
      return;
    }

    try {
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null) {
        return;
      }

      if (_usesLocalConversationSandbox) {
        final message = models.Message(
          id: 'pending-msg-${DateTime.now().millisecondsSinceEpoch}',
          matchId: _currentMatchId!,
          senderId: currentUserId,
          text: text,
          createdAt: DateTime.now(),
          deliveredAt: DateTime.now(),
          readAt: null,
          isDeleted: false,
          deletedAt: null,
        );
        state = state.copyWith(
          messages: [message, ...state.messages],
          error: null,
          isChatLocked: false,
        );
        return;
      }

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
    } on Object catch (e, stackTrace) {
      log.error('Failed to send message', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to send message.',
        isChatLocked: false,
        unlockPolicyVariant: null,
      );
    }
  }

  Future<void> deleteMessageForEveryone(models.Message message) async {
    await requestDeleteMessageForEveryone(message, undoWindow: Duration.zero);
  }

  Future<bool> requestDeleteMessageForEveryone(
    models.Message message, {
    Duration undoWindow = const Duration(seconds: 4),
  }) async {
    if (_currentMatchId == null) {
      return false;
    }

    final currentUserId = ref.read(authNotifierProvider).userId;
    if (currentUserId == null || message.senderId != currentUserId) {
      return false;
    }

    if (_pendingDeleteSnapshots.containsKey(message.id)) {
      return false;
    }

    final originalIndex = state.messages.indexWhere((m) => m.id == message.id);
    if (originalIndex < 0) {
      return false;
    }

    _pendingDeleteSnapshots[message.id] = _PendingDeleteSnapshot(
      message: message,
      originalIndex: originalIndex,
    );
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != message.id).toList(),
      pendingDeleteIds: {...state.pendingDeleteIds, message.id},
      error: null,
    );

    if (undoWindow <= Duration.zero) {
      await _commitPendingDelete(message.id);
      return true;
    }

    _pendingDeleteTimers[message.id]?.cancel();
    _pendingDeleteTimers[message.id] = Timer(undoWindow, () {
      unawaited(_commitPendingDelete(message.id));
    });
    return true;
  }

  bool undoPendingDeleteMessage(String messageId) {
    final snapshot = _pendingDeleteSnapshots.remove(messageId);
    if (snapshot == null) {
      return false;
    }

    _senderDeletedPlaceholders.remove(messageId);

    _pendingDeleteTimers.remove(messageId)?.cancel();
    final restored = [...state.messages];
    final index = snapshot.originalIndex.clamp(0, restored.length);
    restored.insert(index, snapshot.message);

    final pendingIds = {...state.pendingDeleteIds}..remove(messageId);
    state = state.copyWith(messages: restored, pendingDeleteIds: pendingIds);
    return true;
  }

  Future<void> _commitPendingDelete(String messageId) async {
    final snapshot = _pendingDeleteSnapshots.remove(messageId);
    if (snapshot == null) {
      _pendingDeleteTimers.remove(messageId)?.cancel();
      return;
    }

    _pendingDeleteTimers.remove(messageId)?.cancel();
    if (_currentMatchId == null) {
      _restorePendingDelete(snapshot, error: 'Failed to delete message.');
      return;
    }

    final currentUserId = ref.read(authNotifierProvider).userId;
    if (currentUserId == null || snapshot.message.senderId != currentUserId) {
      _restorePendingDelete(snapshot, error: 'Failed to delete message.');
      return;
    }

    try {
      if (_usesLocalConversationSandbox || kUseMockAuth) {
        final pendingIds = {...state.pendingDeleteIds}..remove(messageId);
        state = state.copyWith(pendingDeleteIds: pendingIds, error: null);
        return;
      }

      final dio = ref.read(apiClientProvider);
      final response = await dio.delete<Map<String, dynamic>>(
        '/chat/${_currentMatchId!}/messages/$messageId',
        data: {'requester_user_id': currentUserId},
      );

      final pendingIds = {...state.pendingDeleteIds}..remove(messageId);
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final reasonCode = (body['reason_code'] ?? '').toString();
      if (kShowDeletedPlaceholderForSender) {
        final placeholder = snapshot.message.copyWith(
          text: 'Message deleted',
          isDeleted: true,
          deliveredAt: null,
          readAt: null,
          deletedAt: DateTime.now(),
        );
        _senderDeletedPlaceholders[messageId] = placeholder;
        final nextMessages = [...state.messages];
        final index = snapshot.originalIndex.clamp(0, nextMessages.length);
        nextMessages.insert(index, placeholder);
        state = state.copyWith(
          messages: nextMessages,
          pendingDeleteIds: pendingIds,
          error: null,
        );
        return;
      }

      final error = reasonCode == 'DELETE_WINDOW_EXPIRED'
          ? 'Delete window expired (24h).'
          : null;
      state = state.copyWith(pendingDeleteIds: pendingIds, error: error);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to delete message', e, stackTrace);
      final body = (e.response?.data as Map?)?.cast<String, dynamic>();
      final reasonCode = (body?['reason_code'] ?? '').toString();
      if (reasonCode == 'DELETE_WINDOW_EXPIRED') {
        _restorePendingDelete(snapshot, error: 'Delete window expired (24h).');
        return;
      }
      _restorePendingDelete(snapshot, error: 'Failed to delete message.');
    } on Object catch (e, stackTrace) {
      log.error('Failed to delete message', e, stackTrace);
      _restorePendingDelete(snapshot, error: 'Failed to delete message.');
    }
  }

  void _restorePendingDelete(
    _PendingDeleteSnapshot snapshot, {
    required String error,
  }) {
    final restored = [...state.messages];
    final index = snapshot.originalIndex.clamp(0, restored.length);
    restored.insert(index, snapshot.message);
    final pendingIds = {...state.pendingDeleteIds}..remove(snapshot.message.id);
    state = state.copyWith(
      messages: restored,
      pendingDeleteIds: pendingIds,
      error: error,
    );
  }

  Future<void> sendRoseGift({
    required RoseGift gift,
    required String receiverUserId,
  }) async {
    if (!kFeatureRoseGiftTray) {
      state = state.copyWith(error: 'Rose gifts are currently unavailable.');
      return;
    }

    if (_currentMatchId == null) {
      return;
    }

    final currentUserId = ref.read(authNotifierProvider).userId;
    if (currentUserId == null) {
      return;
    }
    final trimmedCurrentUserId = currentUserId.trim();
    if (trimmedCurrentUserId.isEmpty) {
      return;
    }

    if (!gift.isFree && state.walletCoins < gift.priceCoins) {
      _emitRoseGiftTelemetryStub(
        eventName: 'gift_send_failed_insufficient_coins',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'price_coins': gift.priceCoins,
          'wallet_coins': state.walletCoins,
          'error_code': 'INSUFFICIENT_COINS',
        },
      );
      state = state.copyWith(
        error: 'Not enough coins to send ${gift.name}.',
        isChatLocked: false,
      );
      return;
    }

    final payloadText = _encodeGiftMessage(gift);
    final idempotencyKey = _buildGiftSendIdempotencyKey(
      senderUserId: trimmedCurrentUserId,
      matchId: _currentMatchId!,
      giftId: gift.id,
    );
    _emitRoseGiftTelemetryStub(
      eventName: 'gift_send_attempted',
      attributes: {
        'match_id': _currentMatchId,
        'gift_id': gift.id,
        'tier': gift.tier,
        'price_coins': gift.priceCoins,
        'idempotency_key': idempotencyKey,
      },
    );
    state = state.copyWith(isSendingGift: true);

    try {
      if (_usesLocalConversationSandbox || kUseMockAuth) {
        final message = models.Message(
          id: 'gift-msg-${DateTime.now().millisecondsSinceEpoch}',
          matchId: _currentMatchId!,
          senderId: trimmedCurrentUserId,
          text: payloadText,
          createdAt: DateTime.now(),
          deliveredAt: DateTime.now(),
          readAt: null,
          isDeleted: false,
          deletedAt: null,
        );
        state = state.copyWith(
          messages: [message, ...state.messages],
          walletCoins: gift.isFree
              ? state.walletCoins
              : state.walletCoins - gift.priceCoins,
          isSendingGift: false,
          isChatLocked: false,
        );
        _emitRoseGiftTelemetryStub(
          eventName: 'gift_send_succeeded',
          attributes: {
            'match_id': _currentMatchId,
            'gift_id': gift.id,
            'delivery': 'local_fallback',
            'price_coins': gift.priceCoins,
            'remaining_coins': gift.isFree
                ? state.walletCoins
                : state.walletCoins - gift.priceCoins,
          },
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      var sentViaGiftEndpoint = false;
      var updatedWalletCoins = state.walletCoins;
      try {
        final giftSendResponse = await dio.post<Map<String, dynamic>>(
          '/chat/${_currentMatchId!}/gifts/send',
          options: Options(
            headers: {
              'Idempotency-Key': idempotencyKey,
              'X-User-ID': trimmedCurrentUserId,
            },
          ),
          data: {
            'sender_user_id': trimmedCurrentUserId,
            'receiver_user_id': receiverUserId,
            'gift_id': gift.id,
          },
        );
        final body =
            (giftSendResponse.data as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final wallet =
            (body['wallet'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final apiBalance = (wallet['coin_balance'] as num?)?.toInt();
        if (apiBalance != null && apiBalance >= 0) {
          updatedWalletCoins = apiBalance;
        }
        sentViaGiftEndpoint = true;
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status != 404 && status != 405 && status != 501) {
          rethrow;
        }
      }

      if (!sentViaGiftEndpoint) {
        await dio.post<Map<String, dynamic>>(
          '/chat/${_currentMatchId!}/messages',
          data: {'sender_id': trimmedCurrentUserId, 'text': payloadText},
        );
      }

      final finalWalletCoins = sentViaGiftEndpoint
          ? updatedWalletCoins
          : (gift.isFree
                ? state.walletCoins
                : state.walletCoins - gift.priceCoins);
      state = state.copyWith(
        walletCoins: finalWalletCoins,
        isSendingGift: false,
        isChatLocked: false,
        unlockState: null,
        unlockPolicyVariant: null,
      );
      _emitRoseGiftTelemetryStub(
        eventName: 'gift_send_succeeded',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'delivery': sentViaGiftEndpoint
              ? 'gift_endpoint'
              : 'message_endpoint_fallback',
          'price_coins': gift.priceCoins,
          'remaining_coins': finalWalletCoins,
          'idempotency_key': idempotencyKey,
        },
      );
      await _loadMessages(_currentMatchId!, showLoader: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to send rose gift', e, stackTrace);
      final body = (e.response?.data as Map?)?.cast<String, dynamic>();
      final errorCode = (body?['error_code'] ?? '').toString();
      if (errorCode == 'INSUFFICIENT_COINS' || e.response?.statusCode == 402) {
        _emitRoseGiftTelemetryStub(
          eventName: 'gift_send_failed_insufficient_coins',
          attributes: {
            'match_id': _currentMatchId,
            'gift_id': gift.id,
            'price_coins': gift.priceCoins,
            'wallet_coins': state.walletCoins,
            'error_code': 'INSUFFICIENT_COINS',
            'idempotency_key': idempotencyKey,
          },
        );
        state = state.copyWith(
          error: 'Not enough coins to send ${gift.name}.',
          isSendingGift: false,
          isChatLocked: false,
        );
        return;
      }
      if (errorCode == 'CHAT_LOCKED_REQUIREMENT_PENDING' ||
          e.response?.statusCode == 423) {
        _emitRoseGiftTelemetryStub(
          eventName: 'gift_send_failed_chat_locked',
          attributes: {
            'match_id': _currentMatchId,
            'gift_id': gift.id,
            'error_code': 'CHAT_LOCKED_REQUIREMENT_PENDING',
            'unlock_state': (body?['unlock_state'] ?? '').toString(),
            'unlock_policy_variant': (body?['unlock_policy_variant'] ?? '')
                .toString(),
            'idempotency_key': idempotencyKey,
          },
        );
        state = state.copyWith(
          error: 'Chat is locked until the quest is approved.',
          isSendingGift: false,
          isChatLocked: true,
          unlockState: (body?['unlock_state'] ?? '').toString(),
          unlockPolicyVariant: (body?['unlock_policy_variant'] ?? '')
              .toString(),
        );
        return;
      }
      _emitRoseGiftTelemetryStub(
        eventName: 'gift_send_failed',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'status_code': e.response?.statusCode,
          'idempotency_key': idempotencyKey,
        },
      );
      state = state.copyWith(
        error: 'Failed to send gift.',
        isSendingGift: false,
      );
    } on Object catch (e, stackTrace) {
      log.error('Failed to send rose gift', e, stackTrace);
      _emitRoseGiftTelemetryStub(
        eventName: 'gift_send_failed',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'status_code': null,
          'idempotency_key': idempotencyKey,
        },
      );
      state = state.copyWith(
        error: 'Failed to send gift.',
        isSendingGift: false,
      );
    }
  }

  Future<GestureGiftBundleResult> sendGestureGiftBundle({
    required String receiverUserId,
    required String gestureType,
    required String tone,
    required String gestureText,
    required RoseGift gift,
  }) async {
    trackGestureComposerEvent(
      eventName: 'gesture_gift_bundle_send_attempted',
      attributes: {
        'match_id': _currentMatchId,
        'gesture_type': gestureType,
        'tone': tone,
        'gift_id': gift.id,
        'gift_price': gift.priceCoins,
      },
    );

    if (_currentMatchId == null) {
      return const GestureGiftBundleResult(
        gestureSent: true,
        giftAttempted: true,
        giftSent: false,
        giftError: 'Conversation unavailable.',
      );
    }

    final currentUserId = ref.read(authNotifierProvider).userId?.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return const GestureGiftBundleResult(
        gestureSent: true,
        giftAttempted: true,
        giftSent: false,
        giftError: 'User session not available.',
      );
    }

    if (!gift.isFree && state.walletCoins < gift.priceCoins) {
      const error = 'Not enough coins to send selected gift.';
      state = state.copyWith(error: error, isChatLocked: false);
      trackGestureSendOutcome(
        eventName: 'gesture_gift_bundle_send_failed',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'failure_type': 'insufficient_coins',
        },
      );
      return const GestureGiftBundleResult(
        gestureSent: true,
        giftAttempted: true,
        giftSent: false,
        giftError: error,
      );
    }

    if (_usesLocalConversationSandbox || kUseMockAuth) {
      final message = models.Message(
        id: 'gesture-gift-msg-${DateTime.now().millisecondsSinceEpoch}',
        matchId: _currentMatchId!,
        senderId: currentUserId,
        text: _encodeGestureGiftMessage(
          gestureType: gestureType,
          tone: tone,
          gestureText: gestureText,
          gift: gift,
        ),
        createdAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        readAt: null,
        isDeleted: false,
        deletedAt: null,
      );
      state = state.copyWith(
        messages: [message, ...state.messages],
        walletCoins: gift.isFree
            ? state.walletCoins
            : state.walletCoins - gift.priceCoins,
        error: null,
        isChatLocked: false,
      );
      trackGestureSendOutcome(
        eventName: 'gesture_gift_bundle_send_succeeded',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'delivery': 'local_fallback',
        },
      );
      return const GestureGiftBundleResult(
        gestureSent: true,
        giftAttempted: true,
        giftSent: true,
      );
    }

    final previousError = state.error;
    await sendRoseGift(gift: gift, receiverUserId: receiverUserId);
    final giftSucceeded = state.error == null || state.error == previousError;
    if (giftSucceeded) {
      trackGestureSendOutcome(
        eventName: 'gesture_gift_bundle_send_succeeded',
        attributes: {
          'match_id': _currentMatchId,
          'gift_id': gift.id,
          'delivery': 'remote',
        },
      );
      return const GestureGiftBundleResult(
        gestureSent: true,
        giftAttempted: true,
        giftSent: true,
      );
    }

    trackGestureSendOutcome(
      eventName: 'gesture_gift_bundle_partial_failure',
      attributes: {
        'match_id': _currentMatchId,
        'gift_id': gift.id,
        'failure_type': 'gift_delivery_failed',
      },
    );
    return GestureGiftBundleResult(
      gestureSent: true,
      giftAttempted: true,
      giftSent: false,
      giftError: state.error ?? 'Failed to send gift.',
    );
  }

  void trackGestureComposerEvent({
    required String eventName,
    Map<String, Object?> attributes = const {},
  }) {
    log.info('gesture_composer_telemetry_stub', null, null, {
      'event_name': eventName,
      ...attributes,
    });
  }

  void trackGestureSendOutcome({
    required String eventName,
    Map<String, Object?> attributes = const {},
  }) {
    log.info('gesture_send_telemetry_stub', null, null, {
      'event_name': eventName,
      ...attributes,
    });
  }

  void _emitRoseGiftTelemetryStub({
    required String eventName,
    required Map<String, Object?> attributes,
  }) {
    log.info('rose_gift_telemetry_stub', null, null, {
      'event_name': eventName,
      ...attributes,
    });
  }

  Future<void> _postRoseGiftTelemetryEvent({
    required String eventName,
    required Map<String, Object?> attributes,
  }) async {
    if (_currentMatchId == null || _usesLocalConversationSandbox) {
      return;
    }

    final currentUserId = ref.read(authNotifierProvider).userId?.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    final payload = <String, Object?>{
      'event_name': eventName,
      'user_id': currentUserId,
      'match_id': _currentMatchId,
      ...attributes,
    }..removeWhere((_, value) => value == null);

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/chat/${_currentMatchId!}/gifts/events',
        data: payload,
      );
    } on DioException catch (e, stackTrace) {
      log.warning('rose_gift_telemetry_post_failed', e, stackTrace, {
        'event_name': eventName,
        'match_id': _currentMatchId,
        'status_code': e.response?.statusCode,
      });
    } on Object catch (e, stackTrace) {
      log.warning('rose_gift_telemetry_post_failed', e, stackTrace, {
        'event_name': eventName,
        'match_id': _currentMatchId,
      });
    }
  }

  void trackGiftPanelOpened() {
    final attributes = <String, Object?>{
      'match_id': _currentMatchId,
      'wallet_coins': state.walletCoins,
      'catalog_count': state.giftCatalog.length,
    };
    _emitRoseGiftTelemetryStub(
      eventName: 'gift_panel_opened',
      attributes: attributes,
    );
    unawaited(
      _postRoseGiftTelemetryEvent(
        eventName: 'gift_panel_opened',
        attributes: attributes,
      ),
    );
  }

  void trackGiftPreviewOpened(RoseGift gift) {
    final attributes = <String, Object?>{
      'match_id': _currentMatchId,
      'gift_id': gift.id,
      'tier': gift.tier,
      'price_coins': gift.priceCoins,
      'is_limited': gift.isLimited,
    };
    _emitRoseGiftTelemetryStub(
      eventName: 'gift_preview_opened',
      attributes: attributes,
    );
    unawaited(
      _postRoseGiftTelemetryEvent(
        eventName: 'gift_preview_opened',
        attributes: attributes,
      ),
    );
  }

  /// Update typing status
  void setTyping({required bool isTyping}) {
    state = state.copyWith(isTyping: isTyping);
  }
}

String _encodeGiftMessage(RoseGift gift) {
  final safeName = gift.name.replaceAll('|', '/');
  final safeURL = RoseGift.resolvePreferredGifPathById(
    gift.id,
    fallbackUrl: gift.gifUrl,
  ).replaceAll('|', '%7C');
  final safeIcon = (gift.iconKey ?? '').replaceAll('|', '');
  return '[gift:id=${gift.id}|icon=$safeIcon|name=$safeName|url=$safeURL|'
      'price=${gift.priceCoins}]';
}

String _encodeGestureGiftMessage({
  required String gestureType,
  required String tone,
  required String gestureText,
  required RoseGift gift,
}) {
  final safeGestureType = gestureType.replaceAll('|', '_');
  final safeTone = tone.replaceAll('|', '_');
  final safeGestureText = gestureText
      .replaceAll('|', '/')
      .replaceAll('[', '(')
      .replaceAll(']', ')');
  final safeGiftName = gift.name.replaceAll('|', '/');
  final safeGiftUrl = RoseGift.resolvePreferredGifPathById(
    gift.id,
    fallbackUrl: gift.gifUrl,
  ).replaceAll('|', '%7C');
  final safeIcon = (gift.iconKey ?? '').replaceAll('|', '');

  return '[gesture_gift:'
      'gesture_type=$safeGestureType|'
      'tone=$safeTone|'
      'gesture_text=$safeGestureText|'
      'gift_id=${gift.id}|'
      'gift_icon=$safeIcon|'
      'gift_name=$safeGiftName|'
      'gift_url=$safeGiftUrl|'
      'gift_price=${gift.priceCoins}]';
}

String _buildGiftSendIdempotencyKey({
  required String senderUserId,
  required String matchId,
  required String giftId,
}) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return 'gift-$senderUserId-$matchId-$giftId-$timestamp';
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
