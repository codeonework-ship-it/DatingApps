import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'profile_stories.dart';
import 'today_section.dart';

/// The most stories a profile can hold (the story editor's limit).
const maxProfileStories = 3;

/// Today's "Your story" card: explains what profile stories are, shows how
/// many of the three are written, suggests prompts, and opens the editor.
class ProfileStoryNudge extends ConsumerWidget {
  const ProfileStoryNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null) {
      return const SizedBox.shrink();
    }
    // Loading or failed: still offer the way in, without a count we can't
    // vouch for.
    final stories = ref
        .watch(profileStoriesProvider(user))
        .maybeWhen(
          data: (data) => (data['stories'] as List? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map((s) => s.cast<String, dynamic>())
              .toList(),
          orElse: () => null,
        );
    Future<void> open() async {
      await openProfileStories(context);
      ref.invalidate(profileStoriesProvider(user));
    }

    return _StoryNudgeCard(stories: stories, onOpen: open);
  }
}

class _StoryNudgeCard extends StatelessWidget {
  const _StoryNudgeCard({required this.stories, required this.onOpen});

  /// Null while unknown (loading or failed).
  final List<Map<String, dynamic>>? stories;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final count = stories?.length.clamp(0, maxProfileStories);
    final complete = count == maxProfileStories;
    final latest = (stories?.isNotEmpty ?? false)
        ? storyPromptLabel(l10n, stories!.last['prompt_id'])
        : null;

    final (title, body, action, icon) = switch (count) {
      null => (
        l10n.storiesNudgeTitle,
        l10n.storiesNudgeBodyUnknown,
        l10n.storiesNudgeActionOpen,
        Icons.edit_note_rounded,
      ),
      0 => (
        l10n.storiesNudgeTitle,
        l10n.storiesNudgeBodyEmpty,
        l10n.storiesNudgeActionFirst,
        Icons.edit_note_rounded,
      ),
      maxProfileStories => (
        l10n.storiesNudgeCompleteTitle,
        l10n.storiesNudgeCompleteBody,
        l10n.storiesNudgeActionEdit,
        Icons.edit_outlined,
      ),
      _ => (
        l10n.storiesNudgeSharedTitle(count, maxProfileStories),
        latest == null
            ? l10n.storiesNudgeBodyMore
            : l10n.storiesNudgeBodyLatest(latest),
        l10n.storiesNudgeActionAdd,
        Icons.add_rounded,
      ),
    };

    // Prompts not used yet, as a nudge for the first story.
    final used = {for (final s in stories ?? const []) s['prompt_id']};
    final ideas = localizedStoryPrompts(l10n).entries
        .where((e) => !used.contains(e.key))
        .map((e) => e.value)
        .take(3)
        .toList();

    final button = complete
        ? OutlinedButton.icon(
            key: const ValueKey('qa.today.stories'),
            onPressed: onOpen,
            icon: Icon(icon),
            label: Text(action),
          )
        : FilledButton.icon(
            key: const ValueKey('qa.today.stories'),
            onPressed: onOpen,
            icon: Icon(icon),
            label: Text(action),
          );

    return TodayPanel(
      radius: TodayMetrics.featureRadius,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.55),
              colors.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TodayMetrics.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        complete
                            ? Icons.auto_stories_rounded
                            : Icons.auto_stories_outlined,
                        color: colors.onPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (count != null) ...[
                const SizedBox(height: 16),
                _StoryProgress(count: count),
              ],
              if (count == 0 && ideas.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.storiesNudgeIdeas,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final idea in ideas)
                      ActionChip(
                        avatar: Icon(
                          Icons.format_quote_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        label: Text(idea),
                        onPressed: onOpen,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: button),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: AppLocalizations.of(
        context,
      ).storiesProgressSemantics(count, maxProfileStories),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < maxProfileStories; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < count ? colors.primary : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Text(
              '$count/$maxProfileStories',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
