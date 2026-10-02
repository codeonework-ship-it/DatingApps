import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../social_chat/social_chat_l10n.dart';

/// Shared conversation chrome for the mobile app and browser workspace.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    required this.name,
    required this.photoUrl,
    this.size = 44,
    super.key,
  });
  final String name;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * .36,
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(size * .36),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl.trim().isEmpty
          ? fallback
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({
    required this.name,
    required this.photoUrl,
    required this.pending,
    this.onStarter,
    super.key,
  });
  final String name;
  final String photoUrl;
  final bool pending;
  final ValueChanged<String>? onStarter;

  /// The English starters; the screen shows them in the reader's language.
  static const starters = [
    'What made you smile today?',
    'Your ideal Sunday: go.',
    'Coffee, a walk, or a little adventure?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = chatL10n(context);
    final localizedStarters = [
      l.chatStarterSmile,
      l.chatStarterSunday,
      l.chatStarterCoffee,
    ];
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: ChatAvatar(name: name, photoUrl: photoUrl, size: 76),
                ),
                const SizedBox(height: 24),
                Text(
                  l.chatWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    height: 1.12,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pending ? l.chatWelcomePending : l.chatWelcomeBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (onStarter != null && !pending) ...[
                  const SizedBox(height: 24),
                  Text(
                    l.chatInspirationEyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (i, starter) in localizedStarters.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: ValueKey('qa.chat.starter.$i'),
                        onPressed: () => onStarter!(starter),
                        child: Text(starter, textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatConversationSidebar extends StatelessWidget {
  const ChatConversationSidebar({
    required this.name,
    required this.photoUrl,
    required this.trustLine,
    required this.onBack,
    this.onGift,
    this.onCopilot,
    super.key,
  });
  final String name;
  final String photoUrl;
  final Widget trustLine;
  final VoidCallback onBack;
  final VoidCallback? onGift;
  final VoidCallback? onCopilot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = chatL10n(context);
    return Container(
      key: const ValueKey('qa.chat.desktop_sidebar'),
      width: 280,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('qa.chat.sidebar.back'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l.chatAllConversations),
            ),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: ChatAvatar(name: name, photoUrl: photoUrl, size: 88),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 8),
          trustLine,
          const SizedBox(height: 32),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 24),
          Text(
            l.chatMakeConnectionEyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.chatLessSmallTalk, style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            l.chatLessSmallTalkBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (onCopilot != null)
            OutlinedButton.icon(
              key: const ValueKey('qa.chat.sidebar.copilot'),
              onPressed: onCopilot,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(l.chatFindTheWords),
            ),
          if (onGift != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                key: const ValueKey('qa.chat.sidebar.gift'),
                onPressed: onGift,
                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                label: Text(l.chatSendJoy),
              ),
            ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(height: 12),
                Text(l.chatPaceTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  l.chatPaceBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.sending,
    required this.giftTrayOpen,
    required this.onSend,
    required this.onChanged,
    required this.onEmoji,
    this.onGift,
    this.onCopilot,
    this.assisted = false,
    super.key,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool sending;
  final bool giftTrayOpen;
  final bool assisted;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onEmoji;
  final VoidCallback? onGift;
  final VoidCallback? onCopilot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = chatL10n(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: .04),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        if (kIsWeb)
                          const SingleActivator(LogicalKeyboardKey.enter):
                              onSend,
                        const SingleActivator(
                          LogicalKeyboardKey.enter,
                          control: true,
                        ): onSend,
                        const SingleActivator(
                          LogicalKeyboardKey.enter,
                          meta: true,
                        ): onSend,
                      },
                      child: Semantics(
                        label: 'qa.chat.composer',
                        child: TextField(
                          key: const ValueKey('qa.chat.composer'),
                          controller: controller,
                          focusNode: focusNode,
                          enabled: enabled,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onChanged: onChanged,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.45),
                          decoration: InputDecoration(
                            hintText: enabled
                                ? l.chatWriteMessageHint
                                : l.chatConversationPaused,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final canSend =
                          enabled && !sending && value.text.trim().isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: IconButton.filled(
                          key: const ValueKey('qa.chat.send_button'),
                          tooltip: sending
                              ? l.chatSendingMessageTooltip
                              : l.chatSendMessageTooltip,
                          onPressed: canSend ? onSend : null,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          icon: sending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  if (onGift != null)
                    IconButton(
                      key: const ValueKey('qa.chat.gift_tray_button'),
                      tooltip: giftTrayOpen
                          ? l.chatCloseGifts
                          : l.chatSendGiftTooltip,
                      onPressed: enabled && !sending ? onGift : null,
                      isSelected: giftTrayOpen,
                      icon: Icon(
                        giftTrayOpen
                            ? Icons.close_rounded
                            : Icons.card_giftcard_outlined,
                      ),
                    ),
                  IconButton(
                    key: const ValueKey('qa.chat.emoji_button'),
                    tooltip: l.chatAddEmojiTooltip,
                    onPressed: enabled && !sending ? onEmoji : null,
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                  ),
                  if (onCopilot != null)
                    Flexible(
                      child: TextButton.icon(
                        key: const ValueKey('qa.chat.copilot_button'),
                        onPressed: enabled && !sending ? onCopilot : null,
                        icon: Icon(
                          assisted
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined,
                          size: 18,
                        ),
                        label: Text(
                          assisted ? l.chatDraftedWithHelp : l.chatHelpMeSayIt,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  if (kIsWeb &&
                      MediaQuery.sizeOf(context).width > 900 &&
                      MediaQuery.textScalerOf(context).scale(12) < 16) ...[
                    const Spacer(),
                    Text(
                      l.chatEnterToSendHint,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({required this.date, super.key});
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final day = DateUtils.dateOnly(local);
    final l = chatL10n(context);
    final label = day == today
        ? l.chatToday
        : day == today.subtract(const Duration(days: 1))
        ? l.chatYesterday
        : MaterialLocalizations.of(context).formatMediumDate(local);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: scheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }
}
