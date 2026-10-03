import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/number_formats.dart';
import '../../core/providers/runtime_feature_flags_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/cinematic_effects.dart';
import '../../l10n/app_localizations.dart';
import '../blog/blog_data.dart';
import '../blog/blog_screen.dart';
import '../blog/blog_social.dart';
import '../photo_themes/photo_theme_widgets.dart';
import '../photo_themes/photo_themes_data.dart';
import '../photo_themes/photo_themes_screen.dart';
import '../photo_themes/photo_wall.dart';
import '../walls/today_wall_data.dart';
import 'today_section.dart';

/// Cover of the Week and Today's wall, the community half of Today.
///
/// Each part renders only when it has something to show, and brings its own
/// top gap so hidden parts never leave a hole in the page rhythm. From
/// [TodayMetrics.wideBreakpoint] up, the cover and the wall sit side by side.
class TodayCoverAndWall extends ConsumerWidget {
  const TodayCoverAndWall({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final chapters = flags.enabled('intentional_dating_enabled');
    final photos = flags.enabled('photo_themes_enabled');

    // The cover: a placeholder while loading, nothing on null or error.
    final coverState = photos
        ? ref.watch(coverOfWeekProvider)
        : const AsyncValue<CoverOfTheWeek?>.data(null);
    final cover = coverState.when<Widget?>(
      skipLoadingOnRefresh: false,
      loading: () => const CoverOfTheWeekPlaceholder(),
      error: (_, _) => null,
      data: (cover) =>
          cover == null ? null : CoverOfTheWeekCard(entry: cover.entry),
    );

    // The wall: nothing while loading or on error; a calm card when empty.
    final wallState = chapters || photos
        ? ref.watch(todayWallProvider)
        : const AsyncValue<TodayWall?>.data(null);
    final items = wallState.maybeWhen<List<TodayWallItem>?>(
      skipLoadingOnRefresh: false,
      data: (wall) => wall == null
          ? null
          : [
              for (final item in wall.items)
                if (item.isChapter ? chapters : photos) item,
            ],
      orElse: () => null,
    );
    final Widget? wall = items == null
        ? null
        : TodayWallSection(items: items, canWrite: chapters, canShare: photos);

    if (cover == null && wall == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: TodayMetrics.sectionGap),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          if (cover != null &&
              wall != null &&
              width >= TodayMetrics.wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cover),
                const SizedBox(width: 24),
                Expanded(child: wall),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Edge to edge within the page gutters.
              ?cover,
              if (cover != null && wall != null)
                const SizedBox(height: TodayMetrics.sectionGap),
              ?wall,
            ],
          );
        },
      ),
    );
  }
}

const _photoShadows = [
  Shadow(blurRadius: 16, color: Color(0x99000000)),
  Shadow(blurRadius: 2, offset: Offset(0, 1), color: Color(0x66000000)),
];

/// The gradient that stands in for the cover while it loads. Never a stock
/// or model image: only members' own photos are ever shown.
class CoverOfTheWeekPlaceholder extends StatelessWidget {
  const CoverOfTheWeekPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      key: const ValueKey('qa.today.cover.loading'),
      borderRadius: BorderRadius.circular(TodayMetrics.featureRadius),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryContainer,
                colors.tertiaryContainer,
                colors.secondaryContainer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// This week's cover: one member's photo, full bleed, styled as a fashion
/// magazine cover. Tapping opens the photo with its likes and comments.
class CoverOfTheWeekCard extends ConsumerWidget {
  const CoverOfTheWeekCard({required this.entry, super.key});
  final ThemeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final likes =
        ref.watch(photoLikesProvider)[entry.id]?.count ?? entry.likeCount;
    const ink = Colors.white;
    final l10n = AppLocalizations.of(context);
    final caption = entry.caption.trim();
    final kicker = entry.themeTitle.trim();
    final coverLine = caption.isNotEmpty
        ? caption
        : (kicker.isNotEmpty ? kicker : l10n.todayCoverFallbackLine);
    final small = theme.textTheme.labelMedium?.copyWith(
      color: ink,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w700,
      shadows: _photoShadows,
    );

    return Semantics(
      container: true,
      button: true,
      label: l10n.todayCoverSemantics(entry.firstName),
      child: ClipRRect(
        key: const ValueKey('qa.today.cover'),
        borderRadius: BorderRadius.circular(TodayMetrics.featureRadius),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              const serif = TextStyle(
                fontFamily: AppTheme.displayFamily,
                color: ink,
                shadows: _photoShadows,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  // The photo sits a little deeper than the cover and
                  // drifts against the scroll.
                  CinematicParallax(child: PhotoCoverImage(entry: entry)),
                  // Deep scrims top and bottom: high contrast type on any
                  // photo, with the middle of the picture left clear.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.3, 0.45, 1],
                        colors: [
                          colors.scrim.withValues(alpha: 0.7),
                          colors.scrim.withValues(alpha: 0),
                          colors.scrim.withValues(alpha: 0),
                          colors.scrim.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.todayCoverTitle,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: serif.copyWith(
                              fontSize: (w * 0.08).clamp(22, 40).toDouble(),
                              height: 1,
                              letterSpacing: (w * 0.016).clamp(3, 8).toDouble(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(child: _Rule(color: ink)),
                            const SizedBox(width: 12),
                            _ThisWeekChip(colors: colors),
                            const SizedBox(width: 12),
                            const Expanded(child: _Rule(color: ink)),
                          ],
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (caption.isNotEmpty && kicker.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      kicker.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: small?.copyWith(letterSpacing: 3),
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    coverLine,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: serif.copyWith(
                                      fontSize: (w * 0.085)
                                          .clamp(24, 40)
                                          .toDouble(),
                                      height: 1.08,
                                      letterSpacing: -0.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _Rule(color: ink),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.todayCoverBy(
                                  entry.firstName.toUpperCase(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: small,
                              ),
                            ),
                            Icon(
                              Icons.favorite_rounded,
                              size: 16,
                              color: ink,
                              shadows: _photoShadows,
                              semanticLabel: l10n.todayLikes,
                            ),
                            const SizedBox(width: 4),
                            Text(formatCount(context, likes), style: small),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chat_bubble_rounded,
                              size: 16,
                              color: ink,
                              shadows: _photoShadows,
                              semanticLabel: l10n.todayComments,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatCount(context, entry.commentCount),
                              style: small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => showThemeEntrySheet(context, entry: entry),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: color.withValues(alpha: 0.6));
}

class _ThisWeekChip extends StatelessWidget {
  const _ThisWeekChip({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: colors.primary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        AppLocalizations.of(context).todayThisWeek,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );
}

/// "Today's wall": up to ten chapters and photos members loved, as a paged
/// carousel with a position indicator. When there is nothing yet, a calm card
/// invites the member to write or share.
class TodayWallSection extends StatefulWidget {
  const TodayWallSection({
    required this.items,
    super.key,
    this.canWrite = true,
    this.canShare = true,
  });
  final List<TodayWallItem> items;
  final bool canWrite, canShare;

  @override
  State<TodayWallSection> createState() => _TodayWallSectionState();
}

class _TodayWallSectionState extends State<TodayWallSection> {
  PageController? _controller;
  double? _fraction;
  int _page = 0;

  /// One full-width card with the next one peeking, so the wall is
  /// obviously swipeable. Only a very wide wall (a desktop with no cover
  /// beside it) shows two cards, each filling its half.
  static double fractionFor(double width) => width >= 840 ? 0.49 : 0.92;

  PageController _controllerFor(double fraction) {
    final current = _controller;
    if (current != null && _fraction == fraction) {
      return current;
    }
    if (current != null) {
      // Still attached to the PageView until this frame rebuilds it.
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    _fraction = fraction;
    return _controller = PageController(
      viewportFraction: fraction,
      initialPage: _page,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _go(int page) => _controller?.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final l10n = AppLocalizations.of(context);
    final header = TodaySectionHeader(
      label: l10n.todayWallLabel,
      title: l10n.todayWallTitle,
      caption: l10n.todayWallCaption,
    );
    if (items.isEmpty) {
      return Column(
        key: const ValueKey('qa.today.wall'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: TodayMetrics.cardGap),
          _WallEmpty(canWrite: widget.canWrite, canShare: widget.canShare),
        ],
      );
    }
    final page = math.min(_page, items.length - 1);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      key: const ValueKey('qa.today.wall'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: TodayMetrics.cardGap),
        LayoutBuilder(
          builder: (context, box) {
            final fraction = fractionFor(box.maxWidth);
            final cardWidth = box.maxWidth * fraction - TodayMetrics.cardGap;
            // Every card shares one height: the 4:5 cover ratio, grown when
            // large text needs more room for a chapter.
            final height = math.max(
              cardWidth * 5 / 4,
              120 + textScaler.scale(180),
            );
            return SizedBox(
              height: height,
              child: PageView.builder(
                key: const ValueKey('qa.today.wall.pages'),
                controller: _controllerFor(fraction),
                padEnds: false,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: TodayMetrics.cardGap),
                  child: _WallCard(item: items[i]),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: l10n.todayWallPrevious,
              onPressed: page > 0 ? () => _go(page - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == page ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == page
                                  ? colors.primary
                                  : colors.outlineVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${page + 1} / ${items.length}',
                    key: const ValueKey('qa.today.wall.position'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.todayWallNext,
              onPressed: page < items.length - 1 ? () => _go(page + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _WallCard extends StatelessWidget {
  const _WallCard({required this.item});
  final TodayWallItem item;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (post != null) {
      return _WallChapterCard(post: post);
    }
    return KeyedSubtree(
      key: ValueKey('qa.today.wall.photo.${item.id}'),
      child: PhotoCoverCard(
        entry: item.entry!,
        radius: TodayMetrics.cardRadius,
      ),
    );
  }
}

/// A chapter on the wall: title, a five-line excerpt and the byline, with
/// the counts anchored to the bottom so every card lines up.
class _WallChapterCard extends ConsumerWidget {
  const _WallChapterCard({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final likes =
        ref.watch(blogLikesProvider)[post.id]?.count ?? post.likeCount;
    final muted = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final excerpt = post.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(TodayMetrics.cardRadius);
    return Material(
      key: ValueKey('qa.today.wall.chapter.${post.id}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openBlogPost(context, post.id),
        child: Padding(
          padding: const EdgeInsets.all(TodayMetrics.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.todayWallChapter,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (post.featured) const BlogFeaturedChip(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title.isEmpty ? l10n.todayWallUntitled : post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              // Fills the middle so the footer always sits on the baseline, and
              // shows as many lines as fit so the card never looks half empty.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final style = theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    );
                    final lineHeight = MediaQuery.textScalerOf(
                      context,
                    ).scale((style?.fontSize ?? 16) * 1.5);
                    final lines = (box.maxHeight / lineHeight).floor().clamp(
                      1,
                      24,
                    );
                    return Text(
                      excerpt,
                      maxLines: lines,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.todayWallBy(post.authorName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: colors.primary,
                    semanticLabel: l10n.todayLikes,
                  ),
                  const SizedBox(width: 4),
                  Text(formatCount(context, likes), style: muted),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                    semanticLabel: l10n.todayComments,
                  ),
                  const SizedBox(width: 4),
                  Text(formatCount(context, post.commentCount), style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WallEmpty extends StatelessWidget {
  const _WallEmpty({required this.canWrite, required this.canShare});
  final bool canWrite, canShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return TodayPanel(
      key: const ValueKey('qa.today.wall.empty'),
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: colors.primary),
          const SizedBox(height: 12),
          Text(l10n.todayWallEmpty, style: theme.textTheme.titleMedium),
          if (canWrite || canShare) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (canWrite)
                  FilledButton.tonalIcon(
                    key: const ValueKey('qa.today.wall.write'),
                    onPressed: () => openBlog(context),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(l10n.todayWallWrite),
                  ),
                if (canShare)
                  OutlinedButton.icon(
                    key: const ValueKey('qa.today.wall.share'),
                    onPressed: () => openPhotoThemes(context),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.todayWallShare),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
