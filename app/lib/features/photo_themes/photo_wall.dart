import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/number_formats.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'photo_theme_widgets.dart';
import 'photo_themes_data.dart';

/// "Covers on your wall": Photo Theme photos other members loved, delivered
/// to this member's Today wall and laid out like magazine covers.
///
/// Renders nothing while loading, when the wall is empty, or when the request
/// fails, so Today never shows an error for this optional extra.
class PhotoWallRail extends ConsumerWidget {
  const PhotoWallRail({
    super.key,
    this.title,
    this.caption,
    this.padding = EdgeInsets.zero,
  });

  /// Rail title and caption; null uses "Covers on your wall" and
  /// "Photos other members loved" in the app's language.
  final String? title, caption;
  final EdgeInsetsGeometry padding;

  /// Cover width; the height follows the 4:5 portrait ratio.
  static const coverWidth = 208.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(photoWallProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <ThemeEntry>[]);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('photo.wall_rail'),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? l10n.photoThemesWallTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption ?? l10n.photoThemesWallCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: coverWidth * 5 / 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: coverWidth,
                child: PhotoCoverCard(entry: entries[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One wall photo as an editorial fashion cover: the member's own photo full
/// bleed, a serif masthead with the theme title, the caption as the cover
/// line and a small byline. Tapping opens the photo with likes and comments.
class PhotoCoverCard extends ConsumerWidget {
  const PhotoCoverCard({required this.entry, super.key, this.radius = 12});
  final ThemeEntry entry;

  /// Corner radius; Today's wall uses its card radius.
  final double radius;

  static const _shadows = [
    Shadow(blurRadius: 12, color: Color(0x99000000)),
    Shadow(blurRadius: 2, offset: Offset(0, 1), color: Color(0x66000000)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scrim = theme.colorScheme.scrim;
    final display = theme.textTheme.displaySmall;
    final serif = TextStyle(
      fontFamily: display?.fontFamily,
      fontFamilyFallback: display?.fontFamilyFallback,
      color: Colors.white,
      shadows: _shadows,
    );
    final likes =
        ref.watch(photoLikesProvider)[entry.id]?.count ?? entry.likeCount;
    final masthead = entry.themeTitle.isEmpty
        ? l10n.photoThemesMasthead
        : entry.themeTitle.toUpperCase();
    final small = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      shadows: _shadows,
    );

    return Semantics(
      button: true,
      label: l10n.photoThemesOpenPhoto(entry.firstName),
      child: ClipRRect(
        key: ValueKey('photo.cover.${entry.id}'),
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoCoverImage(entry: entry),
              // Top and bottom scrims keep white type legible on any photo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.32, 0.5, 1],
                    colors: [
                      scrim.withValues(alpha: 0.62),
                      scrim.withValues(alpha: 0),
                      scrim.withValues(alpha: 0),
                      scrim.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The masthead fills the width like a magazine title.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        masthead,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: serif.copyWith(
                          fontSize: 24,
                          height: 1,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 32,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    // The cover line sits low, over the bottom scrim, and
                    // gives way gracefully at large text sizes.
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          entry.caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: serif.copyWith(
                            fontSize: 20,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.photoThemesByline(
                              entry.firstName.toUpperCase(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small,
                          ),
                        ),
                        Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Colors.white,
                          shadows: _shadows,
                          semanticLabel: l10n.photoThemesLikes,
                        ),
                        const SizedBox(width: 4),
                        Text(formatCount(context, likes), style: small),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_rounded,
                          size: 14,
                          color: Colors.white,
                          shadows: _shadows,
                          semanticLabel: l10n.photoThemesComments,
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
          ),
        ),
      ),
    );
  }
}

/// The member's own photo, full bleed. A soft gradient in the theme's colours
/// stands in while it loads or if it cannot load; never a stock image.
class PhotoCoverImage extends ConsumerWidget {
  const PhotoCoverImage({required this.entry, super.key});
  final ThemeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = DecoratedBox(
      key: ValueKey('photo.cover.placeholder.${entry.id}'),
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
    );
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null) {
      return placeholder;
    }
    return ref
        .watch(
          themeEntryPhotoProvider((
            user: user,
            theme: entry.themeId,
            entry: entry.id,
          )),
        )
        .maybeWhen(
          data: (bytes) => Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: entry.altText,
            errorBuilder: (_, _, _) => placeholder,
          ),
          orElse: () => placeholder,
        );
  }
}
