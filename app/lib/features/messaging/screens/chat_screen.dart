import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/main_navigation_screen.dart';
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
    '🤗',
    '🤩',
    '😘',
    '😇',
    '😌',
    '🙌',
    '👏',
    '🤝',
    '💫',
    '🔥',
    '✨',
    '💛',
    '❤️',
    '💖',
    '💯',
    '🌟',
    '🎶',
    '☕',
    '🍀',
    '🫶',
    '🌹',
    '👍',
    '🎉',
  ];
  bool _isGiftTrayOpen = false;
  String? _selectedGiftCategory;
  static const _deleteUndoWindow = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(messageNotifierProvider(widget.matchId).notifier)
          .refreshRoseEconomy();
    });
  }

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
    final currentUserId = ref.watch(authNotifierProvider).userId;
    final isPendingConversation = widget.matchId.startsWith('pending-');
    const roseGiftTrayEnabled = kFeatureRoseGiftTray;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFAF0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () {
            if (context.mounted) {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
                return;
              }
              navigator.pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const MainNavigationScreen(),
                ),
                (route) => false,
              );
            }
          },
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
                if (!context.mounted) {
                  return;
                }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFAF0), Color(0xFFFFFDF8), Color(0xFFFFF6E7)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
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
                      : messageState.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 46,
                                  color: AppTheme.textHint.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No messages yet',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isPendingConversation
                                      ? 'This conversation will be ready once '
                                            'the match is confirmed.'
                                      : 'Start with a warm opener, emoji, '
                                            'or rose gift.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textGrey),
                                ),
                              ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              for (int i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'typing...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textHint),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          AppTheme.pureGoldHighlight.withValues(alpha: 0.12),
                          AppTheme.crystalGoldSoft.withValues(alpha: 0.22),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.pureGoldBright.withValues(
                            alpha: 0.34,
                          ),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.pureGoldBright.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Gifts',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.pureGoldHighlight.withValues(
                                      alpha: 0.55,
                                    ),
                                    AppTheme.pureGoldBright.withValues(
                                      alpha: 0.24,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.pureGoldBright.withValues(
                                    alpha: 0.36,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: AppTheme.pureGoldInk,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Send a rose gift',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.pureGoldInk,
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
                                        color: AppTheme.pureGoldBright
                                            .withValues(alpha: 0.45),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppTheme.pureGoldHighlight
                                          .withValues(alpha: 0.85),
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
                        if (messageState.giftCategories.length > 1)
                          SizedBox(
                            height: 30,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: const Text('All'),
                                    selected: _selectedGiftCategory == null,
                                    onSelected: (_) => setState(() {
                                      _selectedGiftCategory = null;
                                    }),
                                    labelStyle: const TextStyle(fontSize: 11),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                ...messageState.giftCategories.map(
                                  (cat) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(
                                        cat[0].toUpperCase() +
                                            cat
                                                .substring(1)
                                                .replaceAll('_', ' '),
                                      ),
                                      selected: _selectedGiftCategory == cat,
                                      onSelected: (_) => setState(() {
                                        _selectedGiftCategory =
                                            _selectedGiftCategory == cat
                                            ? null
                                            : cat;
                                      }),
                                      labelStyle: const TextStyle(fontSize: 11),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 0,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: Builder(
                            builder: (context) {
                              final visibleGifts = _selectedGiftCategory == null
                                  ? messageState.giftCatalog
                                  : messageState.giftCatalog
                                        .where(
                                          (g) =>
                                              g.category ==
                                              _selectedGiftCategory,
                                        )
                                        .toList();
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: visibleGifts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final gift = visibleGifts[index];
                                  final isLocked =
                                      !gift.isFree &&
                                      messageState.walletCoins <
                                          gift.priceCoins;
                                  final giftCostLabel = isLocked
                                      ? 'Add coins'
                                      : gift.isFree
                                      ? 'One tap • Free'
                                      : 'One tap • ${gift.priceCoins} coins';
                                  return GestureDetector(
                                    onTap: messageState.isSendingGift
                                        ? null
                                        : () => _sendRoseGiftOneTap(
                                            gift,
                                            isLocked,
                                          ),
                                    child: Container(
                                      width: 110,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isLocked
                                              ? [
                                                  Colors.white.withValues(
                                                    alpha: 0.55,
                                                  ),
                                                  Colors.grey.shade100,
                                                ]
                                              : [
                                                  Colors.white,
                                                  AppTheme.pureGoldHighlight
                                                      .withValues(alpha: 0.15),
                                                  AppTheme.crystalGoldSoft
                                                      .withValues(alpha: 0.24),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isLocked
                                              ? AppTheme.textHint.withValues(
                                                  alpha: 0.22,
                                                )
                                              : AppTheme.pureGoldBright
                                                    .withValues(alpha: 0.5),
                                        ),
                                        boxShadow: isLocked
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: AppTheme.pureGoldBright
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 7),
                                                ),
                                              ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            giftCostLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isLocked
                                                      ? AppTheme.textGrey
                                                      : gift.isFree
                                                      ? AppTheme.successGreen
                                                      : AppTheme.pureGoldInk,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                                    ? 'Chat is temporarily locked. Complete '
                                          'the current unlock step to continue.'
                                    : 'Complete and get quest approval to '
                                          'unlock chat.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (messageState.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            messageState.error!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: GlassContainer(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 12,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.78),
                    border: Border.all(
                      color: AppTheme.pureGoldBright.withValues(alpha: 0.28),
                    ),
                    child: Row(
                      children: [
                        // Emoji/Attachment Button
                        IconButton(
                          icon: Icon(
                            _isGiftTrayOpen
                                ? Icons.close_rounded
                                : Icons.add_circle_outline,
                            color: AppTheme.pureGoldInk,
                          ),
                          onPressed:
                              messageState.isChatLocked || !roseGiftTrayEnabled
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
                                  color: AppTheme.pureGoldBright,
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
                                  color: AppTheme.pureGoldInk,
                                ),
                                onPressed: () => _showEmojiPicker(context),
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              messageNotifier.setTyping(
                                isTyping: value.isNotEmpty,
                              );
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
                            if (_messageController.text.trim().isNotEmpty) {
                              messageNotifier.sendMessage(
                                _messageController.text,
                              );
                              _messageController.clear();
                              messageNotifier.setTyping(isTyping: false);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.pureGoldHighlight,
                                  AppTheme.pureGoldBright,
                                  AppTheme.pureGoldCore,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: AppTheme.pureGoldInk,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (messageState.isSendingGift) _buildSendingGiftVeil(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSendingGiftVeil(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.8, sigmaY: 2.8),
          child: Container(
            alignment: Alignment.center,
            color: AppTheme.pureGoldHighlight.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.pureGoldBright.withValues(alpha: 0.42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.pureGoldBright.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.pureGoldInk.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sending your gift…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.pureGoldInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _sendRoseGiftOneTap(RoseGift gift, bool isLocked) async {
    if (isLocked) {
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalletPaymentScreen(
            walletCoins: ref
                .read(messageNotifierProvider(widget.matchId))
                .walletCoins,
          ),
        ),
      );
      return;
    }

    final note = _messageController.text.trim();
    final sent = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .sendRoseGift(
          gift: gift,
          receiverUserId: widget.otherUserId,
          messageText: note,
        );
    if (!mounted || !sent) {
      return;
    }
    _messageController.clear();
    ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .setTyping(isTyping: false);
    setState(() {
      _isGiftTrayOpen = false;
    });
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

  Widget _buildWalletHeaderChip(int walletCoins, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
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
      );
}
