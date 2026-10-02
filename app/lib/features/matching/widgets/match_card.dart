import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../messaging/widgets/chat_chrome.dart';
import '../matching_l10n.dart';
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
    final l10n = AppLocalizations.of(context);
    final displayName = localizedMatchName(
      l10n,
      _cleanDisplayText(match.userName, fallback: l10n.matchesFallbackName),
    );
    final raw = localizedMatchPreview(
      l10n,
      _cleanDisplayText(
        match.lastMessage,
        fallback: l10n.matchesFallbackMessage,
      ),
    );
    final displayMessage =
        raw.contains('[gift:') || raw.contains('[gesture_gift:')
        ? l10n.matchesGiftPreview
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
                          _formatTime(context, l10n, match.lastMessageTime),
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
                  tooltip: l10n.matchesConversationOptionsTooltip(displayName),
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

  String _formatTime(
    BuildContext context,
    AppLocalizations l10n,
    DateTime time,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return l10n.matchesTimeNow;
    } else if (difference.inMinutes < 60) {
      return l10n.matchesTimeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.matchesTimeHoursAgo(difference.inHours);
    } else if (messageDate == today) {
      return l10n.matchesTimeToday;
    } else if (messageDate == yesterday) {
      return l10n.matchesTimeYesterday;
    } else {
      // en: "10/2" as before; other locales use their own month/day order.
      return DateFormat.Md(
        Localizations.localeOf(context).toString(),
      ).format(time);
    }
  }
}
