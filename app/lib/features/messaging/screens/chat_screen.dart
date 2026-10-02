import '../../engagement/screens/voice_icebreakers_screen.dart';
import '../../intentional_dating/connection_card.dart';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/platform/browser_context.dart';
import '../../../core/providers/network_quality_provider.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../graduation/widgets/graduation_banner.dart';
import '../../payment/providers/entitlements_provider.dart';
import '../../payment/screens/subscription_screen.dart';
import '../../payment/screens/wallet_payment_screen.dart';
import '../../plans/widgets/date_plan_card.dart';
import '../../social_chat/social_chat_l10n.dart';
import '../chat_error_l10n.dart';
import '../models/messaging_models.dart' as models;
import '../models/rose_gift.dart';
import '../providers/copilot_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/chat_chrome.dart';
import '../widgets/copilot_sheet.dart';
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
  final _composerFocus = FocusNode();
  bool _isSendingMessage = false;

  /// The copilot draft currently in the composer, if any. Cleared when the
  /// field is emptied, so a member who rewrites from scratch is not marked.
  String? _assistDraftId;
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
    _composerFocus.addListener(() {
      if (_composerFocus.hasFocus && _isGiftTrayOpen) {
        setState(() => _isGiftTrayOpen = false);
      }
    });
    _messageController.addListener(() {
      if (_assistDraftId != null && _messageController.text.trim().isEmpty) {
        setState(() => _assistDraftId = null);
      }
    });
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

  Future<void> _openCopilot(MessageState messageState) async {
    final draft = await showCopilotSheet(
      context: context,
      matchId: widget.matchId,
      partnerName: widget.userName,
      conversationStarted: messageState.messages.isNotEmpty,
    );
    if (draft == null || !mounted) {
      return;
    }
    setState(() {
      _messageController.text = draft.text;
      _messageController.selection = TextSelection.collapsed(
        offset: draft.text.length,
      );
      _assistDraftId = draft.id;
    });
  }

  @override
  void dispose() {
    _composerFocus.dispose();
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
      if (!mounted || next.error == null || next.error == previous?.error)
        return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(localizeChatError(chatL10n(context), next.error!)),
          ),
        );
    });
    final state = ref.watch(messageNotifierProvider(widget.matchId));
    final currentUserId = ref.watch(authNotifierProvider).userId;
    final pending = widget.matchId.startsWith('pending-');
    final flags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final giftsEnabled = kFeatureRoseGiftTray && flags.enabled('gifts_enabled');
    final copilotEnabled =
        flags.enabled('copilot_enabled', fallback: true) && !pending;
    final plansEnabled =
        flags.enabled('date_plans_enabled', fallback: true) && !pending;
    final graduationEnabled =
        flags.enabled('graduation_enabled', fallback: true) && !pending;
    final offline =
        ref.watch(networkQualityProvider).status ==
        NetworkQualityStatus.offline;
    final intentionalEnabled =
        flags.enabled('intentional_dating_enabled', fallback: false) &&
        !pending &&
        state.isMatchActive;
    final canCompose = !state.isChatLocked && state.isMatchActive;
    final voiceEnabled =
        flags.enabled('voice_icebreakers_enabled') && canCompose && !pending;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = chatL10n(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final wide = viewport.maxWidth >= 1050;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.all(wide ? 24 : 0),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(wide ? 28 : 0),
                      border: wide
                          ? Border.all(color: scheme.outlineVariant)
                          : null,
                    ),
                    child: Row(
                      children: [
                        if (wide)
                          ChatConversationSidebar(
                            name: widget.userName,
                            photoUrl: widget.userPhotoUrl,
                            trustLine: _ConversationTrustLine(
                              matchId: widget.matchId,
                            ),
                            onBack: _goBack,
                            onGift:
                                giftsEnabled &&
                                    canCompose &&
                                    !_isSendingMessage &&
                                    !state.isSendingGift
                                ? _toggleGiftTray
                                : null,
                            onCopilot:
                                copilotEnabled &&
                                    canCompose &&
                                    !_isSendingMessage &&
                                    !state.isSendingGift
                                ? () => _openCopilot(state)
                                : null,
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.fromLTRB(
                                      wide ? 24 : 4,
                                      12,
                                      12,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: scheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (!wide)
                                          IconButton(
                                            tooltip: l.chatBackToConversations,
                                            onPressed: _goBack,
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                            ),
                                          ),
                                        ChatAvatar(
                                          name: widget.userName,
                                          photoUrl: widget.userPhotoUrl,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.userName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 3),
                                              _ConversationTrustLine(
                                                matchId: widget.matchId,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (flags.enabled('billing_enabled'))
                                          _buildWalletHeaderChip(
                                            state.walletCoins,
                                            onTap: () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      WalletPaymentScreen(
                                                        walletCoins:
                                                            state.walletCoins,
                                                      ),
                                                ),
                                              );
                                              if (mounted)
                                                await ref
                                                    .read(
                                                      messageNotifierProvider(
                                                        widget.matchId,
                                                      ).notifier,
                                                    )
                                                    .refreshWallet();
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (offline)
                                    Container(
                                      width: double.infinity,
                                      color: scheme.tertiaryContainer,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        l.chatOfflineBanner,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onTertiaryContainer,
                                            ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            scheme.surfaceContainerLow,
                                            Color.alphaBlend(
                                              scheme.secondary.withValues(
                                                alpha: .035,
                                              ),
                                              scheme.surface,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, area) => Column(
                                          children: [
                                            if (voiceEnabled ||
                                                plansEnabled ||
                                                intentionalEnabled ||
                                                graduationEnabled)
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxHeight:
                                                      area.maxHeight * .30,
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      if (voiceEnabled)
                                                        TextButton.icon(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).push<void>(
                                                                MaterialPageRoute(
                                                                  builder: (_) => VoiceIcebreakersScreen(
                                                                    matchId: widget
                                                                        .matchId,
                                                                    receiverUserId:
                                                                        widget
                                                                            .otherUserId,
                                                                    partnerName:
                                                                        widget
                                                                            .userName,
                                                                  ),
                                                                ),
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .mic_none_rounded,
                                                          ),
                                                          label: Text(
                                                            l.chatVoiceHello,
                                                          ),
                                                        ),
                                                      if (intentionalEnabled)
                                                        DatingConnectionCard(
                                                          matchId:
                                                              widget.matchId,
                                                        ),
                                                      if (plansEnabled)
                                                        DatePlanCard(
                                                          matchId:
                                                              widget.matchId,
                                                          partnerName:
                                                              widget.userName,
                                                        ),
                                                      if (graduationEnabled)
                                                        GraduationBanner(
                                                          matchId:
                                                              widget.matchId,
                                                          partnerName:
                                                              widget.userName,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              child: state.isLoading
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : state.messages.isEmpty &&
                                                        state.error != null
                                                  ? Center(
                                                      // Scrolls so Retry stays reachable on small
                                                      // phones and at large text sizes.
                                                      child: SingleChildScrollView(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              24,
                                                            ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .cloud_off_outlined,
                                                              size: 36,
                                                              color: scheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                            const SizedBox(
                                                              height: 16,
                                                            ),
                                                            Text(
                                                              l.chatLoadFailedTitle,
                                                              style: theme
                                                                  .textTheme
                                                                  .titleLarge,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              l.chatLoadFailedBody,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            const SizedBox(
                                                              height: 16,
                                                            ),
                                                            OutlinedButton.icon(
                                                              onPressed: () =>
                                                                  ref.invalidate(
                                                                    messageNotifierProvider(
                                                                      widget
                                                                          .matchId,
                                                                    ),
                                                                  ),
                                                              icon: const Icon(
                                                                Icons.refresh,
                                                              ),
                                                              label: Text(
                                                                l.commonRetry,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  : state.messages.isEmpty
                                                  ? ChatWelcome(
                                                      name: widget.userName,
                                                      photoUrl:
                                                          widget.userPhotoUrl,
                                                      pending: pending,
                                                      onStarter: canCompose
                                                          ? (text) {
                                                              _messageController
                                                                      .text =
                                                                  text;
                                                              _messageController
                                                                      .selection =
                                                                  TextSelection.collapsed(
                                                                    offset: text
                                                                        .length,
                                                                  );
                                                              _composerFocus
                                                                  .requestFocus();
                                                            }
                                                          : null,
                                                    )
                                                  : ListView.builder(
                                                      controller:
                                                          _scrollController,
                                                      reverse: true,
                                                      keyboardDismissBehavior:
                                                          ScrollViewKeyboardDismissBehavior
                                                              .onDrag,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: wide
                                                                ? 28
                                                                : 18,
                                                            vertical: 12,
                                                          ),
                                                      itemCount:
                                                          state.messages.length,
                                                      itemBuilder: (context, index) {
                                                        final message = state
                                                            .messages[index];
                                                        final mine =
                                                            currentUserId !=
                                                                null &&
                                                            message.senderId ==
                                                                currentUserId;
                                                        final incomingGift =
                                                            !mine &&
                                                            !message
                                                                .isDeleted &&
                                                            containsGiftPayload(
                                                              message.text,
                                                            );
                                                        final older =
                                                            index + 1 <
                                                                state
                                                                    .messages
                                                                    .length
                                                            ? state
                                                                  .messages[index +
                                                                  1]
                                                            : null;
                                                        final newDay =
                                                            older == null ||
                                                            !DateUtils.isSameDay(
                                                              message.createdAt
                                                                  .toLocal(),
                                                              older.createdAt
                                                                  .toLocal(),
                                                            );
                                                        return Column(
                                                          key: ValueKey(
                                                            message.id,
                                                          ),
                                                          children: [
                                                            if (newDay)
                                                              ChatDateDivider(
                                                                date: message
                                                                    .createdAt,
                                                              ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 5,
                                                                  ),
                                                              child: Semantics(
                                                                label:
                                                                    'qa.chat.message.${message.id}',
                                                                button:
                                                                    (mine &&
                                                                        !message
                                                                            .isDeleted) ||
                                                                    incomingGift,
                                                                child: GestureDetector(
                                                                  key: ValueKey(
                                                                    'qa.chat.message.${message.id}',
                                                                  ),
                                                                  onLongPress:
                                                                      mine &&
                                                                          !message
                                                                              .isDeleted
                                                                      ? () => _confirmDeleteMessage(
                                                                          message
                                                                              .id,
                                                                        )
                                                                      : incomingGift
                                                                      ? () => _showGiftReceiverActions(
                                                                          message,
                                                                        )
                                                                      : null,
                                                                  child: MessageBubble(
                                                                    message:
                                                                        message
                                                                            .text,
                                                                    isFromCurrentUser:
                                                                        mine,
                                                                    assisted: state
                                                                        .assistedMessageIds
                                                                        .contains(
                                                                          message
                                                                              .id,
                                                                        ),
                                                                    timestamp:
                                                                        message
                                                                            .createdAt,
                                                                    isDelivered:
                                                                        message.deliveredAt !=
                                                                            null ||
                                                                        message.readAt !=
                                                                            null,
                                                                    isRead:
                                                                        message
                                                                            .readAt !=
                                                                        null,
                                                                    receivedGiftFrom:
                                                                        incomingGift
                                                                        ? widget
                                                                              .userName
                                                                        : null,
                                                                    onGiftActions:
                                                                        incomingGift
                                                                        ? () => _showGiftReceiverActions(
                                                                            message,
                                                                          )
                                                                        : null,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (giftsEnabled &&
                                      canCompose &&
                                      _isGiftTrayOpen)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: viewport.maxHeight * .32,
                                      ),
                                      child: _buildGiftTray(state),
                                    ),
                                  if (!canCompose)
                                    Container(
                                      key: const ValueKey(
                                        'qa.chat.locked_banner',
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      color: scheme.secondaryContainer,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 20,
                                            color: scheme.onSecondaryContainer,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              !state.isMatchActive
                                                  ? l.chatConversationEnded
                                                  : l.chatUnlockStepRequired,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSecondaryContainer,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (state.dailyLimit != null)
                                    _DailyLimitBanner(
                                      limit: DailyLimit.fromRefusal(
                                        state.dailyLimit,
                                      ),
                                      onSeePlans: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const SubscriptionScreen(),
                                            ),
                                          ),
                                    ),
                                  _QuotaHint(),
                                  ChatComposer(
                                    controller: _messageController,
                                    focusNode: _composerFocus,
                                    enabled: canCompose && !offline,
                                    sending:
                                        _isSendingMessage ||
                                        state.isSendingGift,
                                    giftTrayOpen: _isGiftTrayOpen,
                                    onSend: _sendMessage,
                                    onChanged: (value) => ref
                                        .read(
                                          messageNotifierProvider(
                                            widget.matchId,
                                          ).notifier,
                                        )
                                        .setTyping(isTyping: value.isNotEmpty),
                                    onEmoji: () => _showEmojiPicker(context),
                                    onGift: giftsEnabled
                                        ? _toggleGiftTray
                                        : null,
                                    onCopilot: copilotEnabled
                                        ? () => _openCopilot(state)
                                        : null,
                                    assisted: _assistDraftId != null,
                                  ),
                                ],
                              ),
                              if (state.isSendingGift)
                                _buildSendingGiftVeil(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (kIsWeb) {
      setWebRoute('/matches');
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  void _toggleGiftTray() {
    setState(() => _isGiftTrayOpen = !_isGiftTrayOpen);
    if (_isGiftTrayOpen) {
      _composerFocus.unfocus();
      ref
          .read(messageNotifierProvider(widget.matchId).notifier)
          .trackGiftPanelOpened();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final state = ref.read(messageNotifierProvider(widget.matchId));
    if (text.isEmpty ||
        _isSendingMessage ||
        state.isSendingGift ||
        state.isChatLocked ||
        !state.isMatchActive ||
        ref.read(networkQualityProvider).status == NetworkQualityStatus.offline)
      return;
    setState(() => _isSendingMessage = true);
    try {
      final sent = await ref
          .read(messageNotifierProvider(widget.matchId).notifier)
          .sendMessage(text, assistDraftId: _assistDraftId);
      if (!mounted) return;
      if (sent && _messageController.text.trim() == text) {
        _messageController.clear();
        _assistDraftId = null;
        ref
            .read(messageNotifierProvider(widget.matchId).notifier)
            .setTyping(isTyping: false);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      }
      ref.invalidate(entitlementsProvider);
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  Widget _buildGiftTray(MessageState state) {
    final scheme = Theme.of(context).colorScheme;
    final l = chatL10n(context);
    final visible = state.giftCatalog
        .where(
          (gift) =>
              _selectedGiftCategory == null ||
              gift.category == _selectedGiftCategory,
        )
        .toList();
    return Container(
      key: const ValueKey('qa.chat.gift_tray'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    color: scheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.chatGiftTrayTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: l.chatCloseGifts,
                    onPressed: _toggleGiftTray,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (state.giftCategories.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in <String?>[
                        null,
                        ...state.giftCategories,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              category == null
                                  ? l.chatAllGifts
                                  : category.replaceAll('_', ' '),
                            ),
                            selected: _selectedGiftCategory == category,
                            onSelected: (_) => setState(
                              () => _selectedGiftCategory = category,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.chatNoGiftsInCollection),
                )
              else
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final gift = visible[index];
                      final locked =
                          !gift.isFree && state.walletCoins < gift.priceCoins;
                      return Material(
                        color: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('qa.chat.gift_item.${gift.id}'),
                          onTap: state.isSendingGift
                              ? null
                              : () => _sendRoseGiftOneTap(gift, locked),
                          child: SizedBox(
                            width: 126,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: RoseGiftVisual(
                                        iconKey: gift.iconKey,
                                        giftId: gift.id,
                                        giftName: gift.name,
                                        size: const Size(104, 78),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    gift.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locked
                                        ? l.chatAddCoins
                                        : gift.isFree
                                        ? l.chatFreeGiftDaily
                                        : l.chatCoinCount(gift.priceCoins),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: scheme.primary),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildSendingGiftVeil(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.8, sigmaY: 2.8),
          child: Container(
            alignment: Alignment.center,
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    chatL10n(context).chatSendingGift,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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

  /// Key for the gift send the member last confirmed. A retry of the same
  /// gift and note reuses it, so a send that reached the server before the
  /// connection dropped is replayed rather than charged again.
  String? _pendingGiftKey;
  String? _pendingGiftSignature;

  Future<void> _sendRoseGiftOneTap(RoseGift gift, bool isLocked) async {
    if (ref.read(networkQualityProvider).status ==
        NetworkQualityStatus.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatL10n(context).chatOfflineGifts)),
      );
      return;
    }
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
      await ref
          .read(messageNotifierProvider(widget.matchId).notifier)
          .refreshWallet();
      return;
    }

    final note = _messageController.text.trim();
    if (!gift.isFree) {
      final balance = ref
          .read(messageNotifierProvider(widget.matchId))
          .walletCoins;
      final confirmed = await _confirmPaidGift(gift, note, balance);
      if (!mounted || confirmed != true) {
        return;
      }
    }

    final signature = '${gift.id}\u0000$note';
    if (_pendingGiftSignature != signature || _pendingGiftKey == null) {
      _pendingGiftSignature = signature;
      _pendingGiftKey = buildGiftSendIdempotencyKey(
        senderUserId: ref.read(authNotifierProvider).userId ?? '',
        matchId: widget.matchId,
        giftId: gift.id,
      );
    }
    final sent = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .sendRoseGift(
          gift: gift,
          receiverUserId: widget.otherUserId,
          messageText: note,
          idempotencyKey: _pendingGiftKey,
        );
    if (!mounted || !sent) {
      return;
    }
    _pendingGiftKey = null;
    _pendingGiftSignature = null;
    _messageController.clear();
    ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .setTyping(isTyping: false);
    setState(() {
      _isGiftTrayOpen = false;
    });
  }

  /// GIFT-002 / RG-103: a paid gift is only sent after the member sees what
  /// it costs and what their balance will be. The composed note is shown and
  /// kept; cancelling leaves it in the composer.
  Future<bool?> _confirmPaidGift(RoseGift gift, String note, int balance) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        final l = chatL10n(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: RoseGiftGlyph(
                    giftName: gift.name,
                    iconKey: gift.iconKey,
                    giftId: gift.id,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.chatGiftConfirmTitle(gift.name, widget.userName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      l.chatGiftNoteQuote(note),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Semantics(
                  label: 'qa.chat.gift_confirm.summary',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.chatCoinCount(gift.priceCoins),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.chatGiftBalanceAfter(
                          balance,
                          balance - gift.priceCoins,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.chatGiftNoObligation,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  label: 'qa.chat.gift_confirm.send',
                  button: true,
                  child: FilledButton(
                    key: const ValueKey('qa.chat.gift_confirm.send'),
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: Text(
                      l.chatGiftSendFor(l.chatCoinCount(gift.priceCoins)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(l.chatNotNow),
                ),
              ],
            ),
          ),
        );
      },
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatL10n(context).chatDeleteMessageTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                chatL10n(context).chatDeleteMessageBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'qa.chat.delete_message_action',
                  button: true,
                  child: ElevatedButton.icon(
                    key: const ValueKey('qa.chat.delete_message_action'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(chatL10n(context).chatDeleteForEveryone),
                    style: Theme.of(context).elevatedButtonTheme.style
                        ?.copyWith(
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.onError.withValues(alpha: 0.7);
                                }
                                return Theme.of(context).colorScheme.onError;
                              }),
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.55);
                                }
                                return Theme.of(context).colorScheme.error;
                              }),
                        ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(chatL10n(context).commonCancel),
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
          content: Text(chatL10n(context).chatMessageDeletedSnack),
          duration: _deleteUndoWindow,
          action: SnackBarAction(
            label: chatL10n(context).chatUndo,
            onPressed: () {
              final restored = ref
                  .read(messageNotifierProvider(widget.matchId).notifier)
                  .undoPendingDeleteMessage(targetMessage.id);
              if (!restored || !mounted) {
                return;
              }
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(chatL10n(context).chatDeleteUndone)),
                );
            },
          ),
        ),
      );
  }

  Future<void> _showGiftReceiverActions(models.Message message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  chatL10n(sheetContext).chatGiftReceivedFrom(widget.userName),
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  chatL10n(sheetContext).chatGiftReceiverIntro,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  key: const ValueKey('qa.chat.gift_hide'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: Text(chatL10n(sheetContext).chatHideGift),
                  subtitle: Text(chatL10n(sheetContext).chatHideGiftSubtitle),
                  onTap: () => Navigator.of(sheetContext).pop('hide'),
                ),
                ListTile(
                  key: const ValueKey('qa.chat.gift_report'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.flag_outlined,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(chatL10n(sheetContext).chatReportAndHide),
                  subtitle: Text(
                    chatL10n(sheetContext).chatReportAndHideSubtitle,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop('report'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(chatL10n(sheetContext).commonCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'report') {
      await _showReportGiftSheet(message);
      return;
    }
    final hidden = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .hideReceivedGift(message);
    if (mounted && hidden) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(chatL10n(context).chatGiftHidden)),
        );
    }
  }

  Future<void> _showReportGiftSheet(models.Message message) async {
    var selectedReason = 'unwanted';
    var details = '';
    final report = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    chatL10n(context).chatReportGiftTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(chatL10n(context).chatReportGiftIntro),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('qa.chat.gift_report_reason'),
                    initialValue: selectedReason,
                    decoration: InputDecoration(
                      labelText: chatL10n(context).chatReportReasonLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'unwanted',
                        child: Text(chatL10n(context).chatReportReasonUnwanted),
                      ),
                      DropdownMenuItem(
                        value: 'harassment',
                        child: Text(
                          chatL10n(context).chatReportReasonHarassment,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'sexual_content',
                        child: Text(chatL10n(context).chatReportReasonSexual),
                      ),
                      DropdownMenuItem(
                        value: 'scam',
                        child: Text(chatL10n(context).chatReportReasonScam),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(chatL10n(context).chatReportReasonOther),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedReason = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('qa.chat.gift_report_details'),
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: chatL10n(context).chatReportDetailsLabel,
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) => details = value,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('qa.chat.gift_report_submit'),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop({'reason': selectedReason, 'details': details}),
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(chatL10n(context).chatReportSubmit),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(chatL10n(context).commonCancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || report == null) {
      return;
    }
    final reported = await ref
        .read(messageNotifierProvider(widget.matchId).notifier)
        .reportReceivedGift(
          message,
          reason: report['reason'] ?? 'other',
          details: report['details'] ?? '',
        );
    if (mounted && reported) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(chatL10n(context).chatGiftReported)),
        );
    }
  }

  Future<void> _showEmojiPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatL10n(context).chatQuickEmojis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
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
      Tooltip(
        message: chatL10n(context).chatWalletTooltip(walletCoins),
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.toll_outlined, size: 18),
          label: Text('$walletCoins'),
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
        ),
      );
}

/// Shown when the backend refused a message because today's allowance on the
/// member's plan is used up. Reset time and a path to a bigger plan.
class _DailyLimitBanner extends StatelessWidget {
  const _DailyLimitBanner({required this.limit, required this.onSeePlans});

  final DailyLimit? limit;
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refusal = limit;
    final l = chatL10n(context);
    return Semantics(
      label: 'qa.chat.daily_limit_banner',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
        child: Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, color: scheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    refusal?.localizedHeadline(l) ?? l.chatDailyLimitReached,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    refusal == null
                        ? l.chatDailyLimitFallback
                        : l.chatDailyLimitReset(
                            refusal.localizedResetLabel(l, l.localeName),
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onSeePlans, child: Text(l.chatSeePlans)),
          ],
        ),
      ),
    );
  }
}

/// Remaining-messages hint under the composer for capped plans.
class _QuotaHint extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    if (entitlements == null ||
        !entitlements.enforced ||
        entitlements.messages.unlimited) {
      return const SizedBox.shrink();
    }
    final quota = entitlements.messages;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              chatL10n(context).chatQuotaOnPlan(
                quota.messagesLabel(chatL10n(context)),
                entitlements.planName,
              ),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Verified humans" when both members are verified, otherwise the usual
/// presence line. Reads GET /matches/{id}/trust.
class _ConversationTrustLine extends ConsumerWidget {
  const _ConversationTrustLine({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trust = ref
        .watch(conversationTrustProvider(matchId))
        .maybeWhen(data: (value) => value, orElse: () => null);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.successGreen);
    if (trust == null || !trust.humanVerified) {
      return Text(
        chatL10n(context).chatYourConversation,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Row(
      key: const ValueKey('qa.chat.verified_humans'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          size: 14,
          color: AppTheme.successGreen,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            trust.partnerShowsUp
                ? chatL10n(context).chatVerifiedHumansShowsUp
                : chatL10n(context).chatVerifiedHumans,
            // Small text takes the surface's secondary ink (4.5:1); the green
            // stays on the icon only.
            style: style?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
