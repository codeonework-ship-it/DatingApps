import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/runtime_feature_flags_provider.dart';
import '../blog/blog_screen.dart';
import '../clubs/clubs_screen.dart';
import '../first_chapter/chapter_studio_screen.dart';
import '../photo_themes/photo_themes_screen.dart';
import 'today_section.dart';

/// "Something to talk about": the shared activities on Today. Blog leads as
/// a full-width feature card; clubs, photo themes and the studio follow in an
/// even grid (two columns on phones, four on wide screens) whose tiles in a
/// row always share one height.
class TodayActivities extends ConsumerWidget {
  const TodayActivities({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final colors = Theme.of(context).colorScheme;
    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    final tiles = <_ActivityTile>[
      if (flags.enabled('clubs_enabled')) ...[
        _ActivityTile(
          key: const ValueKey('qa.today.book_clubs'),
          icon: Icons.menu_book_rounded,
          title: 'Book clubs',
          subtitle: 'One book a week, talked over together.',
          tint: colors.primary,
          onTap: () => push(const ClubsScreen(initialKind: 'book')),
        ),
        _ActivityTile(
          key: const ValueKey('qa.today.film_clubs'),
          icon: Icons.movie_outlined,
          title: 'Film clubs',
          subtitle: 'Watch the pick, then swap takes.',
          tint: colors.secondary,
          onTap: () => push(const ClubsScreen(initialKind: 'film')),
        ),
      ],
      if (flags.enabled('photo_themes_enabled'))
        _ActivityTile(
          key: const ValueKey('qa.today.photo_themes'),
          icon: Icons.photo_library_outlined,
          title: 'Photo Themes',
          subtitle: 'One photo per prompt. See everyone’s.',
          tint: colors.tertiary,
          onTap: () => push(const PhotoThemesScreen()),
        ),
      _ActivityTile(
        key: const ValueKey('qa.today.chapter_studio'),
        icon: Icons.auto_stories_outlined,
        title: 'First Chapter Studio',
        subtitle: 'Begin a story together.',
        tint: colors.primary,
        onTap: () => openChapterStudio(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TodaySectionHeader(
          label: 'SOMETHING TO TALK ABOUT',
          caption: 'Stories, clubs and prompts that make a first hello easier.',
        ),
        const SizedBox(height: TodayMetrics.cardGap),
        _BlogFeature(onTap: () => openBlog(context)),
        const SizedBox(height: TodayMetrics.cardGap),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= TodayMetrics.wideBreakpoint ? 4 : 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var start = 0; start < tiles.length; start += columns) ...[
                  if (start > 0) const SizedBox(height: TodayMetrics.cardGap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var c = 0; c < columns; c++) ...[
                          if (c > 0)
                            const SizedBox(width: TodayMetrics.cardGap),
                          Expanded(
                            child: start + c < tiles.length
                                ? tiles[start + c]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BlogFeature extends StatelessWidget {
  const _BlogFeature({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(TodayMetrics.featureRadius);
    return Material(
      key: const ValueKey('qa.today.blog'),
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.outlineVariant),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.surface],
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TodayMetrics.paddingLarge),
            child: Row(
              children: [
                _IconBadge(icon: Icons.edit_note_rounded, tint: colors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blog · Open Chapters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read members’ stories and write your own.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One grid tile: icon, title and a short line, top-aligned so every tile in
/// a row starts its text on the same baseline.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(TodayMetrics.cardRadius);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 136),
              child: Padding(
                padding: const EdgeInsets.all(TodayMetrics.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconBadge(icon: icon, tint: tint),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.16),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: tint, size: 24),
  );
}
