import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../engagement/screens/level_progression_screen.dart';
import 'blog_data.dart';

/// "12 followers", "1 follower".
String blogFollowerText(AppLocalizations l10n, int n) =>
    l10n.blogFollowerCount(n);

/// Opens the member's Level & XP screen.
Future<void> openMyLevel(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const LevelProgressionScreen()));

/// Follow or stop following a writer's chapters. Optimistic: the button
/// flips at once and rolls back with an explanation if the server does not
/// confirm. Hidden on the member's own chapters.
class BlogFollowButton extends ConsumerWidget {
  const BlogFollowButton({
    super.key,
    required this.authorId,
    required this.server,
  });
  final String authorId;

  /// The follow state the server last sent for this writer.
  final BlogFollowState server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null || user == authorId || authorId.isEmpty) {
      return const SizedBox.shrink();
    }
    final follows = ref.watch(blogFollowsProvider);
    final following = (follows[authorId] ?? server).subscribed;
    final l10n = AppLocalizations.of(context);
    Future<void> toggle() async {
      try {
        await ref.read(blogFollowsProvider.notifier).toggle(authorId, server);
      } on Object catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  apiErrorMessage(
                    e,
                    fallback: following
                        ? l10n.blogUnfollowFailed
                        : l10n.blogFollowFailed,
                  ),
                ),
              ),
            );
        }
      }
    }

    const size = Size(48, 48);
    final key = ValueKey('blog.follow.$authorId');
    return following
        ? OutlinedButton.icon(
            key: key,
            style: OutlinedButton.styleFrom(minimumSize: size),
            onPressed: toggle,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.blogFollowingButton),
          )
        : FilledButton.tonalIcon(
            key: key,
            style: FilledButton.styleFrom(minimumSize: size),
            onPressed: toggle,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.blogFollowTheirChapters),
          );
  }
}

/// The writer of a chapter: name, how many members follow them, and a
/// Follow button for everyone but the writer.
class BlogAuthorRow extends ConsumerWidget {
  const BlogAuthorRow({super.key, required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final server = (
      subscribed: post.authorSubscribed,
      count: post.authorSubscriberCount,
    );
    final state = ref.watch(blogFollowsProvider)[post.authorId] ?? server;
    return Wrap(
      key: const ValueKey('blog.author_row'),
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.authorName, style: theme.textTheme.titleMedium),
            Text(
              blogFollowerText(AppLocalizations.of(context), state.count),
              key: ValueKey('blog.followers.${post.authorId}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        BlogFollowButton(authorId: post.authorId, server: server),
      ],
    );
  }
}

/// A chapter's topic as a small chip.
class BlogTopicChip extends StatelessWidget {
  const BlogTopicChip({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        Icons.tag_rounded,
        size: 16,
        color: colors.onSecondaryContainer,
      ),
      label: Text(title),
      labelStyle: TextStyle(color: colors.onSecondaryContainer),
      backgroundColor: colors.secondaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Explains the creator rewards, with the values the server awards.
Future<void> showBlogRewardsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final l10n = AppLocalizations.of(sheetContext);
        return FractionallySizedBox(
          heightFactor: .85,
          child: ListView(
            key: const ValueKey('blog.rewards_sheet'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Text(l10n.blogRewardsTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.blogRewardsIntro),
              const SizedBox(height: 16),
              for (final reward in blogRewards)
                Padding(
                  key: ValueKey('blog.reward.${reward.source}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blogRewardTitle(l10n, reward.source),
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(blogRewardWho(l10n, reward.source)),
                            Text(
                              l10n.blogRewardDailyCap(reward.dailyCap),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.blogRewardXp(reward.xp),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    openMyLevel(context);
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(l10n.blogSeeMyLevel),
                ),
              ),
            ],
          ),
        );
      },
    );
