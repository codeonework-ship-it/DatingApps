import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/theme/app_theme.dart';
import '../common/widgets/community_actions.dart';
import 'social_chat_data.dart';
import 'social_chat_l10n.dart';

/// What a member can do with another member from a chat (rooms and groups
/// pass this so a name opens "Add friend", a profile, and so on).
typedef SocialSenderTap =
    void Function(BuildContext context, SocialMessage message);

/// Opens a conversation. [subtitle] sits under the title (for example
/// "Room · 12 here"); [actions] go in the app bar; [onSenderTap] runs when a
/// member taps someone else's name or photo; [header] is shown above the
/// messages (a room's topic, a group's description). Friend and group chats
/// get a bell to mute their notifications; a member muted in a room reads
/// along with the composer closed and the reason shown.
Future<void> openSocialChat(
  BuildContext context, {
  required String channelId,
  String title = '',
  String? subtitle,
  String Function(SocialChannel channel)? subtitleFor,
  List<Widget> actions = const [],
  SocialSenderTap? onSenderTap,
  Widget? header,
  String? emptyText,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => SocialChatScreen(
      channelId: channelId,
      title: title,
      subtitle: subtitle,
      subtitleFor: subtitleFor,
      actions: actions,
      onSenderTap: onSenderTap,
      header: header,
      emptyText: emptyText,
    ),
  ),
);

class SocialChatScreen extends ConsumerStatefulWidget {
  const SocialChatScreen({
    required this.channelId,
    super.key,
    this.title = '',
    this.subtitle,
    this.subtitleFor,
    this.actions = const [],
    this.onSenderTap,
    this.header,
    this.emptyText,
  });

  final String channelId;
  final String title;
  final String? subtitle;

  /// Builds the subtitle from the live channel (for example a member count
  /// that follows joins and leaves). Wins over [subtitle] once loaded.
  final String Function(SocialChannel channel)? subtitleFor;
  final List<Widget> actions;
  final SocialSenderTap? onSenderTap;
  final Widget? header;

  /// Shown while there are no messages; a friendly default when null.
  final String? emptyText;

  @override
  ConsumerState<SocialChatScreen> createState() => _SocialChatScreenState();
}

class _SocialChatScreenState extends ConsumerState<SocialChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    SocialChatFocus.open.add(widget.channelId);
    _scroll.addListener(() {
      // The list is reversed: the far end is the oldest message.
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
        ref
            .read(socialChatProvider(widget.channelId).notifier)
            .loadOlder()
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    SocialChatFocus.open.remove(widget.channelId);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text;
    if (body.trim().isEmpty) return;
    _text.clear();
    final l = chatL10n(context);
    try {
      await ref.read(socialChatProvider(widget.channelId).notifier).send(body);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l.chatNotSentRetry),
        );
      }
    }
  }

  Future<void> _muteNotifications(SocialChannel channel) async {
    final l = chatL10n(context);
    final choice = await showSocialMuteSheet(context, channel);
    if (!mounted || choice == null) {
      return;
    }
    try {
      await ref
          .read(socialChatProvider(widget.channelId).notifier)
          .setMute(choice.duration);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showCommunitySnack(
          context,
          choice.duration == null ? l.chatUnmuteDone : l.chatMuteDone,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l.chatMuteFailed),
        );
      }
    }
  }

  Future<void> _messageActions(SocialMessage m, SocialChannel? channel) async {
    final chat = ref.read(socialChatProvider(widget.channelId).notifier);
    final l = chatL10n(context);
    final canRemove = !m.deleted && (m.mine || (channel?.canModerate ?? false));
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.failed)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l.chatRetrySend),
                onTap: () => Navigator.pop(sheet, 'retry'),
              ),
            if (!m.deleted)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(l.chatCopyText),
                onTap: () => Navigator.pop(sheet, 'copy'),
              ),
            if (canRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(m.mine ? l.chatDeleteMine : l.chatRemoveMessage),
                onTap: () => Navigator.pop(sheet, 'delete'),
              ),
            if (!m.mine && !m.deleted && !m.failed && !m.pending)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l.chatReportMessage),
                onTap: () => Navigator.pop(sheet, 'report'),
              ),
            if (!m.mine && widget.onSenderTap != null)
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(
                  m.senderName.isEmpty ? l.chatThisMember : m.senderName,
                ),
                onTap: () => Navigator.pop(sheet, 'sender'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'retry':
        await chat.retry(m).catchError((Object _) {});
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.body));
        if (mounted) showCommunitySnack(context, l.chatCopied);
      case 'delete':
        try {
          await chat.delete(m);
        } on Object catch (e) {
          if (mounted) {
            showCommunitySnack(
              context,
              apiErrorMessage(e, fallback: l.chatDeleteFailed),
            );
          }
        }
      case 'report':
        await reportCommunityItem(
          context,
          ref,
          kind: 'social_message',
          id: m.id,
        );
      case 'sender':
        widget.onSenderTap?.call(context, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialChatProvider(widget.channelId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = chatL10n(context);
    final channel = state.channel;
    final title = widget.title.isNotEmpty ? widget.title : channel?.title ?? '';
    final group = channel != null && channel.kind != 'friend';
    final subtitle =
        (channel != null && widget.subtitleFor != null
            ? widget.subtitleFor!(channel)
            : null) ??
        widget.subtitle ??
        (channel == null
            ? null
            : channel.kind == 'friend'
            ? l.chatSubtitleFriends
            : l.chatMemberCount(channel.memberCount));
    final messages = state.messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.displayFamily,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (!state.live && !state.loading)
            Tooltip(
              message: l.chatReconnecting,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          if (channel != null && channel.canMuteNotifications)
            IconButton(
              key: const ValueKey('social.chat.mute'),
              tooltip: channel.muted ? l.chatMutedTooltip : l.chatMuteTooltip,
              onPressed: () => _muteNotifications(channel),
              icon: Icon(
                channel.muted
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_none_rounded,
              ),
            ),
          ...widget.actions,
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (widget.header != null) widget.header!,
            Expanded(
              child: state.loading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && messages.isEmpty
                  ? _ChatError(
                      message: apiErrorMessage(
                        state.error!,
                        fallback: l.chatUnavailable,
                      ),
                      onRetry: () => ref
                          .read(socialChatProvider(widget.channelId).notifier)
                          .refresh(),
                    )
                  : messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          widget.emptyText ?? l.chatEmptyDefault,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('social.chat.messages'),
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: messages.length + (state.loadingOlder ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final m = messages[i];
                        // Reversed: the next item is the previous message.
                        final previous = i + 1 < messages.length
                            ? messages[i + 1]
                            : null;
                        final showSender =
                            group &&
                            !m.mine &&
                            (previous == null ||
                                previous.senderId != m.senderId);
                        return SocialMessageBubble(
                          key: ValueKey('social.message.${m.clientMessageId}'),
                          message: m,
                          showSender: showSender,
                          onLongPress: () => _messageActions(m, channel),
                          onSenderTap: widget.onSenderTap == null || m.mine
                              ? null
                              : () => widget.onSenderTap!(context, m),
                        );
                      },
                    ),
            ),
            if (channel != null && channel.readOnly)
              _ReadOnlyNotice(text: socialReadOnlyText(context, channel)),
            _Composer(
              controller: _text,
              enabled:
                  (state.error == null || messages.isNotEmpty) &&
                  !(channel?.readOnly ?? false),
              readOnly: channel?.readOnly ?? false,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class SocialMessageBubble extends StatelessWidget {
  const SocialMessageBubble({
    required this.message,
    required this.showSender,
    required this.onLongPress,
    super.key,
    this.onSenderTap,
  });

  final SocialMessage message;
  final bool showSender;
  final VoidCallback onLongPress;
  final VoidCallback? onSenderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final m = message;
    final mine = m.mine;
    final background = m.deleted
        ? colors.surfaceContainerHighest
        : mine
        ? colors.primary
        : colors.surface;
    final foreground = m.deleted
        ? colors.onSurfaceVariant
        : mine
        ? colors.onPrimary
        : colors.onSurface;
    final l = chatL10n(context);
    final time = TimeOfDay.fromDateTime(m.createdAt).format(context);
    final status = m.failed
        ? l.chatStatusNotSent
        : m.pending
        ? l.chatStatusSending
        : time;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
        border: mine && !m.deleted
            ? null
            : Border.all(
                color: m.failed ? colors.error : colors.outlineVariant,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.deleted ? l.chatMessageRemoved : m.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: foreground,
              fontStyle: m.deleted ? FontStyle.italic : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: m.failed
                  ? (mine ? colors.onPrimary : colors.error)
                  : foreground.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: mine
          ? l.chatSemanticsYouAt(time)
          : l.chatSemanticsMemberAt(
              m.senderName.isEmpty ? l.chatMember : m.senderName,
              time,
            ),
      child: Padding(
        padding: EdgeInsets.only(top: showSender ? 12 : 4),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSender) _SenderLine(message: m, onTap: onSenderTap),
            GestureDetector(onLongPress: onLongPress, child: bubble),
          ],
        ),
      ),
    );
  }
}

class _SenderLine extends StatelessWidget {
  const _SenderLine({required this.message, this.onTap});
  final SocialMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = chatL10n(context);
    final name = message.senderName.isEmpty ? l.chatMember : message.senderName;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: colors.primaryContainer,
          foregroundImage: message.senderPhotoUrl.startsWith('http')
              ? NetworkImage(message.senderPhotoUrl)
              : null,
          child: Text(
            name.characters.first.toUpperCase(),
            style: TextStyle(fontSize: 12, color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 4), child: row);
    }
    return Semantics(
      button: true,
      label: l.chatAboutMember(name),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: row,
          ),
        ),
      ),
    );
  }
}

/// Why the member can read but not post, in their language.
String socialReadOnlyText(BuildContext context, SocialChannel channel) {
  final l = chatL10n(context);
  final until = channel.readOnlyUntil;
  if (channel.kind == 'room') {
    return until == null
        ? l.chatRoomMuted
        : l.chatRoomMutedUntil(chatWhen(context, until));
  }
  return until == null
      ? l.chatReadOnly
      : l.chatReadOnlyUntil(chatWhen(context, until));
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        key: const ValueKey('social.chat.read_only'),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Icon(
                Icons.volume_off_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A choice from [showSocialMuteSheet]: a duration, or null to turn
/// notifications back on.
class SocialMuteChoice {
  const SocialMuteChoice(this.duration);
  final SocialMuteDuration? duration;
}

/// Asks how long to mute [channel]'s notifications (1 hour, 8 hours, 1 week,
/// until turned back on), or offers to turn them back on when muted.
Future<SocialMuteChoice?> showSocialMuteSheet(
  BuildContext context,
  SocialChannel channel,
) {
  final l = chatL10n(context);
  final until = channel.mutedUntil;
  return showModalBottomSheet<SocialMuteChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      ListTile option(String key, String label, SocialMuteDuration d) =>
          ListTile(
            key: ValueKey('social.mute.$key'),
            leading: const Icon(Icons.notifications_paused_outlined),
            title: Text(label),
            onTap: () => Navigator.pop(sheet, SocialMuteChoice(d)),
          );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l.chatMuteSheetTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel.muted
                          ? (until == null
                                ? l.chatMutedIndefinitely
                                : l.chatMutedUntilLabel(chatWhen(sheet, until)))
                          : l.chatMuteSheetBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (channel.muted)
                ListTile(
                  key: const ValueKey('social.mute.off'),
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(l.chatUnmute),
                  onTap: () =>
                      Navigator.pop(sheet, const SocialMuteChoice(null)),
                ),
              option('1h', l.chatMuteOneHour, SocialMuteDuration.oneHour),
              option('8h', l.chatMuteEightHours, SocialMuteDuration.eightHours),
              option('1w', l.chatMuteOneWeek, SocialMuteDuration.oneWeek),
              option(
                'forever',
                l.chatMuteForever,
                SocialMuteDuration.untilTurnedOn,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.readOnly = false,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  /// Muted: the field says why instead of inviting a message.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = chatL10n(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('social.chat.input'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: readOnly
                      ? l.chatMutedComposerHint
                      : l.chatComposerHint,
                  counterText: '',
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const ValueKey('social.chat.send'),
              tooltip: l.chatSend,
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(chatL10n(context).chatTryAgain),
          ),
        ],
      ),
    ),
  );
}
