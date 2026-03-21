import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../matching/providers/gesture_timeline_provider.dart';
import '../../matching/screens/activity_session_screen.dart';
import '../../payment/screens/wallet_payment_screen.dart';
import '../models/messaging_models.dart' as models;
import '../models/rose_gift.dart';
import '../providers/message_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rose_gift_glyph.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.matchId,
    required this.otherUserId,
    required this.userName,
    required this.userPhotoUrl,
    super.key,
  });
  final String matchId;
  final String otherUserId;
  final String userName;
  final String userPhotoUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  static const _quickEmojis = <String>[
    '😊',
    '😂',
    '😍',
    '🥰',
    '😉',
    '😎',
    '🔥',
    '✨',
    '💛',
    '🌹',
    '👍',
    '🎉',
  ];
  bool _isGiftTrayOpen = false;
  static const _deleteUndoWindow = Duration(seconds: 4);
  static const _composerPaddingDuration = Duration(milliseconds: 220);
  static const _stepSwitchDuration = Duration(milliseconds: 320);
  static const _giftAttachSwitchDuration = Duration(milliseconds: 240);
  static const _errorFadeDuration = Duration(milliseconds: 200);
  static const _ctaSwitchDuration = Duration(milliseconds: 210);
  static const _stepScaleDuration = Duration(milliseconds: 230);
  static const _stepContainerDuration = Duration(milliseconds: 250);
  static const _stepTextDuration = Duration(milliseconds: 210);

  void _appendToController(
    TextEditingController controller,
    String value, {
    bool preferNewLine = false,
  }) {
    final nextValue = value.trim();
    if (nextValue.isEmpty) {
      return;
    }

    final current = controller.text;
    if (current.trim().isEmpty) {
      controller
        ..text = nextValue
        ..selection = TextSelection.collapsed(offset: nextValue.length);
      return;
    }

    final separator = preferNewLine
        ? (current.endsWith('\n') ? '' : '\n')
        : (current.endsWith(' ') || current.endsWith('\n') ? '' : ' ');
    final combined = '$current$separator$nextValue';

    controller
      ..text = combined
      ..selection = TextSelection.collapsed(offset: combined.length);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MessageState>(messageNotifierProvider(widget.matchId), (
      previous,
      next,
    ) {
      if (!mounted || next.error == null || next.error == previous?.error) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.error!)));
    });

    final messageState = ref.watch(messageNotifierProvider(widget.matchId));
    final messageNotifier = ref.read(
      messageNotifierProvider(widget.matchId).notifier,
    );
    final timelineState = ref.watch(gestureTimelineProvider(widget.matchId));
    final timelineNotifier = ref.read(
      gestureTimelineProvider(widget.matchId).notifier,
    );
    final currentUserId = ref.watch(authNotifierProvider).userId;
    final isPendingConversation = widget.matchId.startsWith('pending-');
    const roseGiftTrayEnabled = kFeatureRoseGiftTray;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.userName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Active now',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.successGreen),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildWalletHeaderChip(
              messageState.walletCoins,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletPaymentScreen(
                      walletCoins: messageState.walletCoins,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gesture Timeline',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isPendingConversation
                          ? null
                          : () => _showGestureComposer(
                              context,
                              timelineNotifier,
                              widget.otherUserId,
                            ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        isPendingConversation
                            ? 'Unlock after match'
                            : 'Send Gesture',
                      ),
                    ),
                  ],
                ),
                if (isPendingConversation) ...[
                  const SizedBox(height: 6),
                  Text(
                    'This conversation is still pending. Gestures become '
                    'available once the match is fully created.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _openActivitySession,
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('2-Min This-or-That'),
                  ),
                ),
                if (timelineState.isLoading)
                  const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.trustBlue,
                        ),
                      ),
                    ),
                  )
                else if (timelineState.items.isEmpty)
                  Text(
                    isPendingConversation
                        ? 'Gestures will appear here after the match is '
                              'confirmed.'
                        : 'No gestures yet. Send a thoughtful opener to start.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  )
                else
                  SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: timelineState.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = timelineState.items[index];
                        final canReview =
                            currentUserId != null &&
                            item.receiverUserId == currentUserId &&
                            item.status == 'sent';
                        return _buildGestureTimelineCard(
                          context: context,
                          item: item,
                          canReview: canReview,
                          isSender:
                              currentUserId != null &&
                              item.senderUserId == currentUserId,
                          timelineNotifier: timelineNotifier,
                        );
                      },
                    ),
                  ),
                if (timelineState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timelineState.error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                    ),
                  ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: messageState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryRed,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messageState.messages.length,
                    itemBuilder: (context, index) {
                      final message = messageState.messages[index];
                      final isCurrentUser =
                          currentUserId != null &&
                          message.senderId == currentUserId;

                      return Padding(
                        key: ValueKey<String>(message.id),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onLongPress: isCurrentUser && !message.isDeleted
                              ? () => _confirmDeleteMessage(message.id)
                              : null,
                          child: MessageBubble(
                            message: message.text,
                            isFromCurrentUser: isCurrentUser,
                            timestamp: message.createdAt,
                            isDelivered:
                                message.deliveredAt != null ||
                                message.readAt != null,
                            isRead: message.readAt != null,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Typing Indicator
          if (messageState.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.grey[100],
                    blur: 0,
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1).animate(
                                CurvedAnimation(
                                  parent: AlwaysStoppedAnimation<double>(
                                    (i * 0.1) % 1.0,
                                  ),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'typing...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),
            ),

          if (roseGiftTrayEnabled &&
              !messageState.isChatLocked &&
              _isGiftTrayOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rose Gifts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppTheme.primaryRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Send a rose gift',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isGiftTrayOpen = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.pureGoldHighlight,
                                  AppTheme.pureGoldBright,
                                  AppTheme.crystalGoldSoft,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.pureGoldBright.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.pureGoldHighlight.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppTheme.pureGoldInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: messageState.giftCatalog.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final gift = messageState.giftCatalog[index];
                        final isLocked =
                            !gift.isFree &&
                            messageState.walletCoins < gift.priceCoins;
                        return GestureDetector(
                          onTap: messageState.isSendingGift
                              ? null
                              : () => _showRoseGiftPreview(gift, isLocked),
                          child: Container(
                            width: 110,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.grey[100] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: gift.isFree
                                    ? AppTheme.successGreen.withValues(
                                        alpha: 0.45,
                                      )
                                    : AppTheme.primaryRed.withValues(
                                        alpha: 0.35,
                                      ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: RoseGiftVisual(
                                      iconKey: gift.iconKey,
                                      giftId: gift.id,
                                      giftName: gift.name,
                                      size: const Size(110, 76),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    RoseGiftGlyph(
                                      iconKey: gift.iconKey,
                                      giftId: gift.id,
                                      giftName: gift.name,
                                      size: 16,
                                      iconSize: 10,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        gift.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  gift.isFree
                                      ? 'Free'
                                      : '${gift.priceCoins} coins',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: gift.isFree
                                            ? AppTheme.successGreen
                                            : AppTheme.primaryRed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          if (messageState.isChatLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryRed.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          messageState.unlockPolicyVariant ==
                                  'allow_without_template'
                              ? 'Chat is temporarily locked. Complete the '
                                    'current unlock step to continue.'
                              : 'Complete and get quest approval to unlock '
                                    'chat.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openActivitySession,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Start 2-Min This-or-That'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openAppealsFromChatLock,
                      icon: const Icon(Icons.gavel_outlined),
                      label: const Text('Appeal this decision'),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Emoji/Attachment Button
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryRed,
                  ),
                  onPressed: messageState.isChatLocked || !roseGiftTrayEnabled
                      ? null
                      : () {
                          final nextValue = !_isGiftTrayOpen;
                          setState(() {
                            _isGiftTrayOpen = nextValue;
                          });
                          if (nextValue) {
                            messageNotifier.trackGiftPanelOpened();
                          }
                        },
                ),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !messageState.isChatLocked,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppTheme.primaryRed,
                        ),
                        onPressed: () => _showEmojiPicker(context),
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      messageNotifier.setTyping(isTyping: value.isNotEmpty);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Send Button
                GestureDetector(
                  onTap: () {
                    if (messageState.isChatLocked) {
                      return;
                    }
                    if (_messageController.text.isNotEmpty) {
                      messageNotifier.sendMessage(_messageController.text);
                      _messageController.clear();
                      messageNotifier.setTyping(isTyping: false);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoseGiftPreview(RoseGift gift, bool isLocked) {
    ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .trackGiftPreviewOpened(gift);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gift.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RoseGiftVisual(
                  iconKey: gift.iconKey,
                  giftId: gift.id,
                  giftName: gift.name,
                  size: const Size(320, 180),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              gift.isFree
                  ? 'This gift is free to send.'
                  : 'Price: ${gift.priceCoins} coins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: gift.isFree
                    ? AppTheme.successGreen
                    : AppTheme.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (gift.isLimited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Limited drop',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLocked
                    ? null
                    : () async {
                        await ref
                            .read(
                              messageNotifierProvider(widget.matchId).notifier,
                            )
                            .sendRoseGift(
                              gift: gift,
                              receiverUserId: widget.otherUserId,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.redeem_outlined),
                label: Text(
                  isLocked
                      ? 'Not enough coins'
                      : gift.isFree
                      ? 'Send Free Rose'
                      : 'Send for ${gift.priceCoins} coins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMessage(String messageId) async {
    final messages = ref.read(messageNotifierProvider(widget.matchId)).messages;
    models.Message? message;
    for (final item in messages) {
      if (item.id == messageId) {
        message = item;
        break;
      }
    }
    if (message == null) {
      return;
    }
    final targetMessage = message;

    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete message?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'This removes the message from both chat inboxes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete for everyone'),
                  style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.white.withValues(alpha: 0.7);
                      }
                      return Colors.white;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppTheme.errorRed.withValues(alpha: 0.55);
                      }
                      return AppTheme.errorRed;
                    }),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final didRequestDelete = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .requestDeleteMessageForEveryone(
          targetMessage,
          undoWindow: _deleteUndoWindow,
        );

    if (!mounted || !didRequestDelete) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Message deleted.'),
          duration: _deleteUndoWindow,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              final restored = ref
                  .read(messageNotifierProvider(widget.matchId).notifier)
                  .undoPendingDeleteMessage(targetMessage.id);
              if (!restored || !mounted) {
                return;
              }
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Delete undone.')));
            },
          ),
        ),
      );
  }

  Widget _decisionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _buildGestureTimelineCard({
    required BuildContext context,
    required GestureTimelineItem item,
    required bool canReview,
    required bool isSender,
    required GestureTimelineNotifier timelineNotifier,
  }) {
    final statusColor = _gestureStatusColor(item.status);
    final badgeText = _gestureStatusLabel(item.status);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            statusColor.withValues(alpha: 0.08),
            AppTheme.pureGoldHighlight.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _gestureTypeIcon(item.gestureType),
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCase(item.gestureType.replaceAll('_', ' ')),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tone: ${_titleCase(item.tone)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildGestureBadge(context, badgeText, statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.contentText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniFactChip(
                context,
                icon: Icons.bolt_rounded,
                label: 'Score ${item.effortScore}',
                color: AppTheme.trustBlue,
              ),
              _buildMiniFactChip(
                context,
                icon: item.minimumQualityPass
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                label: item.minimumQualityPass ? 'Quality pass' : 'Needs work',
                color: item.minimumQualityPass
                    ? AppTheme.successGreen
                    : AppTheme.warningOrange,
              ),
              if (item.giftDeliveryStatus == 'gift_sent')
                _buildMiniFactChip(
                  context,
                  icon: Icons.redeem_rounded,
                  label: 'Gift delivered',
                  color: AppTheme.successGreen,
                ),
              if (item.giftDeliveryStatus == 'gift_failed')
                _buildMiniFactChip(
                  context,
                  icon: Icons.error_outline_rounded,
                  label: 'Gift failed',
                  color: AppTheme.errorRed,
                ),
            ],
          ),
          if (item.giftDeliveryStatus == 'gift_failed') ...[
            const SizedBox(height: 8),
            Text(
              item.giftDeliveryMessage ?? 'Gesture was sent, but gift failed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          if (isSender && item.giftDeliveryStatus == 'gift_failed') ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _retryGiftForGesture(item, timelineNotifier),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Gift'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (canReview)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _decisionChip(
                  label: 'Appreciate',
                  color: AppTheme.successGreen,
                  onTap: () => timelineNotifier.decideGesture(
                    gestureId: item.id,
                    decision: 'appreciate',
                  ),
                ),
                _decisionChip(
                  label: 'Request Better',
                  color: AppTheme.warningOrange,
                  onTap: () => timelineNotifier.decideGesture(
                    gestureId: item.id,
                    decision: 'request_better',
                    reason: 'Please add clearer effort.',
                  ),
                ),
                _decisionChip(
                  label: 'Decline',
                  color: AppTheme.errorRed,
                  onTap: () => timelineNotifier.decideGesture(
                    gestureId: item.id,
                    decision: 'decline',
                    reason: 'Not aligned yet.',
                  ),
                ),
              ],
            )
          else
            Text(
              'Updated ${item.createdAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
            ),
        ],
      ),
    );
  }

  Widget _buildGestureBadge(BuildContext context, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _buildMiniFactChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Future<void> _showEmojiPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick emojis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickEmojis
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () {
                          _appendToController(_messageController, emoji);
                          ref
                              .read(
                                messageNotifierProvider(
                                  widget.matchId,
                                ).notifier,
                              )
                              .setTyping(
                                isTyping: _messageController.text.isNotEmpty,
                              );
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _gestureStatusColor(String status) {
    switch (status) {
      case 'sending':
        return AppTheme.warningOrange;
      case 'appreciate':
        return AppTheme.successGreen;
      case 'request_better':
        return AppTheme.warningOrange;
      case 'decline':
        return AppTheme.errorRed;
      default:
        return AppTheme.trustBlue;
    }
  }

  String _gestureStatusLabel(String status) {
    switch (status) {
      case 'sending':
        return 'Sending';
      case 'appreciate':
        return 'Loved it';
      case 'request_better':
        return 'Revision';
      case 'decline':
        return 'Passed';
      default:
        return 'Sent';
    }
  }

  IconData _gestureTypeIcon(String gestureType) {
    switch (gestureType) {
      case 'micro_card':
        return Icons.style_rounded;
      case 'challenge_token':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Future<void> _retryGiftForGesture(
    GestureTimelineItem item,
    GestureTimelineNotifier timelineNotifier,
  ) async {
    final gift = await _showGestureGiftPicker(context);
    if (!context.mounted || gift == null) {
      return;
    }

    final result = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .sendGestureGiftBundle(
          receiverUserId: widget.otherUserId,
          gestureType: item.gestureType,
          tone: item.tone,
          gestureText: item.contentText,
          gift: gift,
        );

    timelineNotifier.markGiftDeliveryOutcome(
      gestureId: item.id,
      success: result.giftSent,
      message: result.giftSent
          ? 'Gift sent successfully.'
          : (result.giftError ?? 'Gift retry failed.'),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.giftSent
                ? 'Gift sent successfully.'
                : (result.giftError ?? 'Gift retry failed.'),
          ),
        ),
      );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _openActivitySession() async {
    final sharedMessage = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ActivitySessionScreen(
          matchId: widget.matchId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.userName,
          enableShareToChat: true,
        ),
      ),
    );
    if (!mounted || sharedMessage == null || sharedMessage.trim().isEmpty) {
      return;
    }
    await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .sendMessage(sharedMessage.trim());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity result shared to chat.')),
    );
  }

  void _openAppealsFromChatLock() {
    final unlockState = ref
        .read(messageNotifierProvider(widget.matchId))
        .unlockState;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModerationAppealsScreen(
          initialReason:
              'Chat lock review request for match '
              '${widget.matchId} (state: ${unlockState ?? 'unknown'})',
        ),
      ),
    );
  }

  Future<void> _showGestureComposer(
    BuildContext context,
    GestureTimelineNotifier notifier,
    String receiverUserId,
  ) async {
    var activeStep = 0;
    var gestureType = 'thoughtful_opener';
    var tone = 'warm';
    var isSubmitting = false;
    RoseGift? selectedGift;
    String? localError;
    final messageController = TextEditingController();

    ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .trackGestureComposerEvent(
          eventName: 'gesture_composer_opened',
          attributes: {'match_id': widget.matchId},
        );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final walletCoins = ref
              .read(messageNotifierProvider(widget.matchId))
              .walletCoins;
          final availableHeight = MediaQuery.of(context).size.height * 0.84;
          final contentText = messageController.text.trim();
          final selectedGiftPriceLabel = selectedGift == null
              ? null
              : (selectedGift!.isFree
                    ? 'Free gift attached'
                    : '${selectedGift!.priceCoins} coins');
          final stepProgress = (activeStep + 1) / 4;
          final canAdvance = switch (activeStep) {
            0 => true,
            1 => contentText.isNotEmpty,
            2 => true,
            _ => contentText.isNotEmpty,
          };

          return SafeArea(
            child: AnimatedPadding(
              duration: _composerPaddingDuration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: availableHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Craft a Gesture',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type • Message • Gift • Review',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: stepProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildComposerStepChip(
                            context,
                            label: 'Type',
                            index: 0,
                            activeStep: activeStep,
                          ),
                          const SizedBox(width: 8),
                          _buildComposerStepChip(
                            context,
                            label: 'Message',
                            index: 1,
                            activeStep: activeStep,
                          ),
                          const SizedBox(width: 8),
                          _buildComposerStepChip(
                            context,
                            label: 'Gift',
                            index: 2,
                            activeStep: activeStep,
                          ),
                          const SizedBox(width: 8),
                          _buildComposerStepChip(
                            context,
                            label: 'Review',
                            index: 3,
                            activeStep: activeStep,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: _stepSwitchDuration,
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        transitionBuilder: (child, animation) {
                          final offsetTween = Tween<Offset>(
                            begin: const Offset(0.035, 0),
                            end: Offset.zero,
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetTween.animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(activeStep),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activeStep == 0) ...[
                              Text(
                                'Choose your style',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Thoughtful Opener',
                                    selected:
                                        gestureType == 'thoughtful_opener',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(
                                        () => gestureType = 'thoughtful_opener',
                                      );
                                    },
                                  ),
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Micro Card',
                                    selected: gestureType == 'micro_card',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(
                                        () => gestureType = 'micro_card',
                                      );
                                    },
                                  ),
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Challenge Token',
                                    selected: gestureType == 'challenge_token',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(
                                        () => gestureType = 'challenge_token',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Select tone',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Warm',
                                    selected: tone == 'warm',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => tone = 'warm');
                                    },
                                  ),
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Neutral',
                                    selected: tone == 'neutral',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => tone = 'neutral');
                                    },
                                  ),
                                  _buildComposerChoiceChip(
                                    context,
                                    label: 'Direct',
                                    selected: tone == 'direct',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => tone = 'direct');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _toneHint(tone),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                            if (activeStep == 1) ...[
                              Text(
                                'Write your message',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _messageStartersForType(gestureType)
                                    .map(
                                      (starter) => ActionChip(
                                        label: Text(starter),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          _appendToController(
                                            messageController,
                                            starter,
                                            preferNewLine: true,
                                          );
                                          setModalState(() {});
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: messageController,
                                maxLines: 5,
                                onChanged: (_) => setModalState(() {
                                  localError = null;
                                }),
                                decoration: const InputDecoration(
                                  hintText: 'Make it personal and memorable...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Aim for 12+ words for a stronger first '
                                'impression.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                            if (activeStep == 2) ...[
                              Text(
                                'Add a rose gift (optional)',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Wallet: $walletCoins coins',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSubmitting
                                          ? null
                                          : () async {
                                              final gift =
                                                  await _showGestureGiftPicker(
                                                    context,
                                                  );
                                              if (!context.mounted ||
                                                  gift == null) {
                                                return;
                                              }
                                              unawaited(
                                                HapticFeedback.selectionClick(),
                                              );
                                              setModalState(() {
                                                selectedGift = gift;
                                                localError = null;
                                              });
                                            },
                                      icon: const Icon(
                                        Icons.redeem_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        selectedGift == null
                                            ? 'Choose Gift'
                                            : 'Change Gift',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedSwitcher(
                                duration: _giftAttachSwitchDuration,
                                child: selectedGift == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryRed
                                                .withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryRed
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              RoseGiftGlyph(
                                                iconKey: selectedGift!.iconKey,
                                                giftId: selectedGift!.id,
                                                giftName: selectedGift!.name,
                                                size: 22,
                                                iconSize: 14,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      selectedGift!.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    Text(
                                                      selectedGiftPriceLabel!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppTheme
                                                                .textGrey,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: isSubmitting
                                                    ? null
                                                    : () {
                                                        _selHaptic();
                                                        setModalState(() {
                                                          selectedGift = null;
                                                        });
                                                      },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                            if (activeStep == 3) ...[
                              Text(
                                'Review before sending',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              _buildGestureReviewPreview(
                                context: context,
                                gestureType: gestureType,
                                tone: tone,
                                contentText: contentText,
                                selectedGift: selectedGift,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: localError == null ? 0 : 1,
                          duration: _errorFadeDuration,
                          child: Text(
                            localError!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (activeStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                        setModalState(() {
                                          activeStep -= 1;
                                          localError = null;
                                        });
                                      },
                                child: const Text('Back'),
                              ),
                            ),
                          if (activeStep > 0) const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting || !canAdvance
                                  ? null
                                  : () async {
                                      if (activeStep < 3) {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                        setModalState(() {
                                          activeStep += 1;
                                          localError = null;
                                        });
                                        ref
                                            .read(
                                              messageNotifierProvider(
                                                widget.matchId,
                                              ).notifier,
                                            )
                                            .trackGestureComposerEvent(
                                              eventName:
                                                  'gesture_composer_'
                                                  'step_advanced',
                                              attributes: {
                                                'match_id': widget.matchId,
                                                'step': activeStep,
                                              },
                                            );
                                        return;
                                      }

                                      if (contentText.isEmpty) {
                                        setModalState(() {
                                          localError =
                                              'Please add your gesture '
                                              'message.';
                                          activeStep = 1;
                                        });
                                        return;
                                      }
                                      if (selectedGift != null &&
                                          !selectedGift!.isFree &&
                                          walletCoins <
                                              selectedGift!.priceCoins) {
                                        setModalState(() {
                                          localError =
                                              'Not enough coins for this gift.';
                                          activeStep = 2;
                                        });
                                        return;
                                      }

                                      setModalState(() {
                                        isSubmitting = true;
                                        localError = null;
                                      });

                                      final createResult = await notifier
                                          .createGesture(
                                            receiverUserId: receiverUserId,
                                            gestureType: gestureType,
                                            contentText: contentText,
                                            tone: tone,
                                          );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (!createResult.success) {
                                        unawaited(
                                          HapticFeedback.mediumImpact(),
                                        );
                                        setModalState(() {
                                          isSubmitting = false;
                                          localError =
                                              createResult.error ??
                                              'Failed to send gesture.';
                                        });
                                        return;
                                      }

                                      if (selectedGift != null) {
                                        final bundleResult = await ref
                                            .read(
                                              messageNotifierProvider(
                                                widget.matchId,
                                              ).notifier,
                                            )
                                            .sendGestureGiftBundle(
                                              receiverUserId: receiverUserId,
                                              gestureType: gestureType,
                                              tone: tone,
                                              gestureText: contentText,
                                              gift: selectedGift!,
                                            );
                                        final gestureId =
                                            createResult.gestureId;
                                        if (gestureId != null &&
                                            gestureId.isNotEmpty) {
                                          notifier.markGiftDeliveryOutcome(
                                            gestureId: gestureId,
                                            success: bundleResult.giftSent,
                                            message: bundleResult.giftSent
                                                ? 'Gift delivered.'
                                                : (bundleResult.giftError ??
                                                      'Gift failed. Retry '
                                                          'from timeline.'),
                                          );
                                        }
                                        if (!bundleResult.giftSent) {
                                          unawaited(
                                            HapticFeedback.mediumImpact(),
                                          );
                                          setModalState(() {
                                            isSubmitting = false;
                                            localError =
                                                'Gesture sent successfully, '
                                                'but gift failed. '
                                                'You can retry from the '
                                                'timeline card.';
                                          });
                                          return;
                                        }
                                      }

                                      ref
                                          .read(
                                            messageNotifierProvider(
                                              widget.matchId,
                                            ).notifier,
                                          )
                                          .trackGestureComposerEvent(
                                            eventName:
                                                'gesture_composer_completed',
                                            attributes: {
                                              'match_id': widget.matchId,
                                              'gift_attached':
                                                  selectedGift != null,
                                              'gesture_type': gestureType,
                                              'tone': tone,
                                            },
                                          );
                                      unawaited(HapticFeedback.lightImpact());
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              child: AnimatedSwitcher(
                                duration: _ctaSwitchDuration,
                                child: isSubmitting
                                    ? const SizedBox(
                                        key: ValueKey('loading-cta'),
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        key: ValueKey(
                                          'cta-$activeStep-'
                                          '${selectedGift != null}',
                                        ),
                                        activeStep < 3
                                            ? 'Next'
                                            : (selectedGift == null
                                                  ? 'Send Gesture'
                                                  : 'Send Gesture + Gift'),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    messageController.dispose();
  }

  void _selHaptic() {
    unawaited(HapticFeedback.selectionClick());
  }

  Widget _buildComposerStepChip(
    BuildContext context, {
    required String label,
    required int index,
    required int activeStep,
  }) {
    final isActive = index == activeStep;
    final isComplete = index < activeStep;
    final background = isActive || isComplete
        ? AppTheme.primaryRed.withValues(alpha: 0.15)
        : Colors.grey.shade100;
    final foreground = isActive || isComplete
        ? AppTheme.primaryRed
        : AppTheme.textGrey;
    return Expanded(
      child: AnimatedScale(
        duration: _stepScaleDuration,
        scale: isActive ? 1.03 : 1,
        child: AnimatedContainer(
          duration: _stepContainerDuration,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryRed.withValues(alpha: 0.25)
                  : Colors.grey.shade300,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: _stepTextDuration,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerChoiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppTheme.primaryRed.withValues(alpha: 0.14),
    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: selected ? AppTheme.primaryRed : AppTheme.textGrey,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    ),
    side: BorderSide(
      color: selected
          ? AppTheme.primaryRed.withValues(alpha: 0.26)
          : Colors.grey.shade300,
    ),
  );

  Widget _buildGestureReviewPreview({
    required BuildContext context,
    required String gestureType,
    required String tone,
    required String contentText,
    required RoseGift? selectedGift,
  }) {
    final previewText = contentText.isEmpty
        ? 'Your message will appear here...'
        : contentText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryRed.withValues(alpha: 0.06),
            AppTheme.pureGoldHighlight.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppTheme.primaryRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _titleCase(gestureType.replaceAll('_', ' ')),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _titleCase(tone),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              previewText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
          if (selectedGift != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                RoseGiftGlyph(
                  iconKey: selectedGift.iconKey,
                  giftId: selectedGift.id,
                  giftName: selectedGift.name,
                  size: 20,
                  iconSize: 13,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedGift.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  selectedGift.isFree
                      ? 'Free'
                      : '${selectedGift.priceCoins} coins',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<String> _messageStartersForType(String gestureType) {
    switch (gestureType) {
      case 'micro_card':
        return const [
          'Quick card: One thing I admired in your profile is...',
          'Mini note: You seem like someone who values...',
          'Small but real: I’d love to know your take on...',
        ];
      case 'challenge_token':
        return const [
          'Tiny challenge: pick beach sunrise or mountain sunset, and why?',
          'Quick game: tell me your top 2 comfort foods.',
          'Challenge token: describe your perfect Sunday in 10 words.',
        ];
      default:
        return const [
          'I loved your profile energy, especially...',
          'You seem intentional and genuine — I’d like to know...',
          'Thoughtful opener: what’s one value you never compromise on?',
        ];
    }
  }

  String _toneHint(String tone) {
    switch (tone) {
      case 'direct':
        return 'Direct keeps it confident, concise, and clear.';
      case 'neutral':
        return 'Neutral feels balanced and easy to respond to.';
      default:
        return 'Warm feels inviting and emotionally expressive.';
    }
  }

  Future<RoseGift?> _showGestureGiftPicker(BuildContext context) async {
    final messageState = ref.read(messageNotifierProvider(widget.matchId));

    return showModalBottomSheet<RoseGift>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach a rose gift',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a gift to send together with your gesture.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 152,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: messageState.giftCatalog.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final gift = messageState.giftCatalog[index];
                    final isLocked =
                        !gift.isFree &&
                        messageState.walletCoins < gift.priceCoins;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(gift),
                      child: Container(
                        width: 118,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey[100] : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isLocked
                                ? Colors.grey.shade300
                                : AppTheme.primaryRed.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: RoseGiftVisual(
                                  iconKey: gift.iconKey,
                                  giftId: gift.id,
                                  giftName: gift.name,
                                  size: const Size(118, 82),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gift.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gift.isFree ? 'Free' : '${gift.priceCoins} coins',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: gift.isFree
                                        ? AppTheme.successGreen
                                        : isLocked
                                        ? AppTheme.textHint
                                        : AppTheme.primaryRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHeaderChip(int walletCoins, {VoidCallback? onTap}) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(width: 6),
                Text(
                  '$walletCoins coins',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
