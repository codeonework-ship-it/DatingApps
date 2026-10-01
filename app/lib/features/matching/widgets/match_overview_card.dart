import 'package:flutter/material.dart';
import '../../messaging/widgets/chat_chrome.dart';
import '../providers/match_provider.dart';

/// The Matches destination represents people. Message previews belong in the
/// conversation view, reached through an explicit action.
class MatchOverviewCard extends StatelessWidget {
  const MatchOverviewCard({
    super.key,
    required this.match,
    required this.onChat,
    required this.onOptions,
    this.onPlan,
    this.onChapter,
  });
  final Match match;
  final VoidCallback onChat, onOptions;
  final VoidCallback? onPlan;
  final VoidCallback? onChapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChatAvatar(
                name: match.userName,
                photoUrl: match.userPhoto,
                size: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You both chose to connect',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Match options for ${match.userName}',
                onPressed: onOptions,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  match.unreadCount > 0
                      ? 'Chat · ${match.unreadCount} unread'
                      : 'Open chat',
                ),
              ),
              if (onPlan != null)
                OutlinedButton.icon(
                  onPressed: onPlan,
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: const Text('Plan a date'),
                ),
              if (onChapter != null)
                OutlinedButton.icon(
                  onPressed: onChapter,
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  label: const Text('First Chapter'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
