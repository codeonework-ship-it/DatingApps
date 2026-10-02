import 'package:flutter/material.dart';
import '../../messaging/widgets/chat_chrome.dart';
import '../providers/match_provider.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onOptions,
  });
  final Match match;
  final VoidCallback onTap;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = _cleanDisplayText(
      match.userName,
      fallback: 'Your match',
    );
    final raw = _cleanDisplayText(
      match.lastMessage,
      fallback: 'Start your conversation',
    );
    final displayMessage =
        raw.contains('[gift:') || raw.contains('[gesture_gift:')
        ? 'A little gift in your conversation'
        : raw;
    final unread = match.unreadCount > 0;
    return Material(
      color: unread
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: .035),
              scheme.surface,
            )
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: unread
              ? scheme.primary.withValues(alpha: .22)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onOptions,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ChatAvatar(
                name: displayName,
                photoUrl: match.userPhoto,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(match.lastMessageTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: unread
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (unread)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Badge(
                              backgroundColor: scheme.primary,
                              textColor: scheme.onPrimary,
                              label: Text(
                                match.unreadCount > 99
                                    ? '99+'
                                    : '${match.unreadCount}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOptions != null)
                IconButton(
                  tooltip: 'Conversation options for $displayName',
                  onPressed: onOptions,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanDisplayText(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final lowered = trimmed.toLowerCase();
    if (lowered == 'nil' ||
        lowered == '<nil>' ||
        lowered == 'null' ||
        lowered == 'n/a') {
      return fallback;
    }
    return trimmed;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
