import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../messaging/widgets/chat_chrome.dart';
import '../matching_l10n.dart';
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
    final l10n = AppLocalizations.of(context);
    final name = localizedMatchName(l10n, match.userName);
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
              ChatAvatar(name: name, photoUrl: match.userPhoto, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.matchesBothChose,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('qa.matches.person.${match.id}.options'),
                tooltip: l10n.matchesOptionsTooltip(name),
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
                key: ValueKey('qa.matches.person.${match.id}.chat'),
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  match.unreadCount > 0
                      ? l10n.matchesChatUnread(match.unreadCount)
                      : l10n.matchesOpenChat,
                ),
              ),
              if (onPlan != null)
                OutlinedButton.icon(
                  key: ValueKey('qa.matches.person.${match.id}.plan'),
                  onPressed: onPlan,
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: Text(l10n.matchesActionPlanDate),
                ),
              if (onChapter != null)
                OutlinedButton.icon(
                  key: ValueKey('qa.matches.person.${match.id}.chapter'),
                  onPressed: onChapter,
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  label: Text(l10n.matchesFirstChapter),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
