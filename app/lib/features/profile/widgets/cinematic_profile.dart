import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cinematic_effects.dart';
import '../../../core/theme/cinematic_motion.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../l10n/app_localizations.dart';

/// The cinematic member profile, shared by a member's own profile and the
/// profile of someone else: a full-bleed hero photo that dissolves into the
/// page under the member's name (a title card for a person), a film-strip
/// reel of the other photos and a full-screen gallery.
///
/// Every colour comes from the active [ColorScheme], so the profile follows
/// the Today look and every cinematic preset in light and dark. Motion
/// (Ken Burns drift, parallax, gallery fades) goes through [CinematicLevel],
/// so reduced motion and the Calm look hold still frames.

/// Widest the profile's text column grows on tablets and the web.
const double kProfileContentMaxWidth = 720;

/// What the hero needs to introduce someone. Built from whatever is already
/// known (a Discover card, the full public profile, or the member's own
/// account), so the title card can show before the details arrive.
@immutable
class ProfileHeadline {
  const ProfileHeadline({
    required this.userId,
    required this.name,
    required this.photos,
    this.age,
    this.profession,
    this.place,
    this.isVerified = false,
    this.logline,
    this.badges = const <String>[],
  });

  final String userId;
  final String name;

  /// Photo URLs in display order. Empty means no photo yet: the hero then
  /// shows the member's initials over the look's own gradient.
  final List<String> photos;
  final int? age;
  final String? profession;
  final String? place;
  final bool isVerified;

  /// A one-line reason this person is being shown, when the server sends
  /// one (curated introductions).
  final String? logline;

  /// Short status pills (Spotlight, curated reasons).
  final List<String> badges;

  String get displayName => age == null ? name : '$name, $age';
}

/// Up to two initials for [name], for photo placeholders.
String profileInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return '·';
  }
  final first = words.first.characters.first;
  if (words.length == 1) {
    return first.toUpperCase();
  }
  return (first + words.last.characters.first).toUpperCase();
}

/// Height of the hero photo for a viewport: about 60–65% of a phone's
/// height, never taller than a 4:5 portrait of the width, and a widescreen
/// frame on tablets and the web.
double profileHeroPhotoHeight({
  required double width,
  required double viewportHeight,
}) {
  final tall = viewportHeight * 0.64;
  final portrait = width * 1.3;
  return math.max(300, math.min(tall, portrait));
}

/// How far the name block rises into the bottom of the hero photo.
double profileHeroOverlap(double photoHeight) =>
    math.min(136, photoHeight * 0.28);

/// A light ink taken from the scheme, for text and icons on the gallery's
/// dark scrim in both light and dark looks.
Color _lightInk(ColorScheme scheme) =>
    scheme.brightness == Brightness.light ? scheme.surface : scheme.onSurface;

/// A member photo with an intentional fallback: while it loads, or if it
/// cannot load (no network on the emulator, a removed file), the frame
/// shows the member's initials over a gradient from the look's palette
/// instead of a broken-image icon.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    required this.url,
    required this.name,
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -0.3),
    this.cacheWidth,
  });

  /// Null or empty: no photo, show the fallback.
  final String? url;
  final String name;
  final BoxFit fit;
  final Alignment alignment;

  /// Decode width in physical pixels for small frames (saves memory).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final fallback = ProfilePhotoFallback(name: name);
    final source = url?.trim() ?? '';
    if (source.isEmpty) {
      return fallback;
    }
    final still = CinematicLevel.of(context) == CinematicLevel.still;
    return Image.network(
      source,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, child, frame, synchronous) {
        if (synchronous) {
          return child;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            if (frame == null) fallback,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: CinematicMotion.enter,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, _, _) => fallback,
    );
  }
}

/// Initials over a soft gradient in the look's own colours: the photo
/// placeholder, designed to look deliberate rather than broken.
class ProfilePhotoFallback extends StatelessWidget {
  const ProfilePhotoFallback({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
            scheme.tertiaryContainer,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.6, -0.7),
            radius: 1.1,
            colors: [
              scheme.primary.withValues(alpha: 0.28),
              scheme.primary.withValues(alpha: 0),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final side = math.min(box.maxWidth, box.maxHeight);
            if (!side.isFinite || side < 24) {
              return const SizedBox.expand();
            }
            return Center(
              child: SizedBox.square(
                dimension: side * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(side * 0.1),
                    child: FittedBox(
                      child: Text(
                        profileInitials(name),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 64,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.86,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The hero tag for photo [index] of [userId], shared by the hero, the reel
/// and the gallery so a tapped photo flies to full screen.
Object profilePhotoHeroTag(String userId, int index) =>
    'profile-photo-$userId-$index';

/// The title sequence: the main photo full-bleed (drifting slowly, moving
/// against the scroll and stretching on overscroll), dissolving into the
/// page under the member's name.
///
/// Sits at the top of a [CustomScrollView] as a box sliver. [photoHeight]
/// is the photo frame; the name block rises into its bottom and the box
/// grows with large text instead of overflowing.
class CinematicProfileHero extends StatelessWidget {
  const CinematicProfileHero({
    required this.headline,
    required this.eyebrow,
    required this.photoHeight,
    super.key,
    this.onOpenPhoto,
    this.photoKey,
    this.photoQaId,
    this.footer,
  });

  final ProfileHeadline headline;

  /// Small tracked line above the name ("Introducing", "Starring").
  final String eyebrow;
  final double photoHeight;

  /// Opens the gallery on the main photo.
  final VoidCallback? onOpenPhoto;

  /// Automation key for the photo's tap target.
  final Key? photoKey;

  /// Automation id of the photo's tap target: a semantics identifier
  /// (Android resource-id, web `flt-semantics-identifier`), never part of the
  /// spoken label.
  final String? photoQaId;

  /// Shown under the title block (a loading indicator, for example).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overlap = profileHeroOverlap(photoHeight);
    final photos = headline.photos;
    final mainPhoto = photos.isEmpty ? null : photos.first;
    final photoLabel = mainPhoto == null
        ? l10n.memberProfileNoPhoto
        : l10n.memberProfilePhotoLabel(headline.name, 1, photos.length);
    return Stack(
      children: [
        SizedBox(height: photoHeight, width: double.infinity),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: photoHeight,
          child: Semantics(
            image: true,
            button: onOpenPhoto != null,
            identifier: photoQaId,
            label: photoLabel,
            onTapHint: onOpenPhoto == null
                ? null
                : l10n.memberProfileViewPhotoHint,
            child: GestureDetector(
              key: photoKey,
              behavior: HitTestBehavior.opaque,
              onTap: onOpenPhoto,
              child: _HeroPhoto(
                height: photoHeight,
                overlap: overlap,
                child: Hero(
                  tag: profilePhotoHeroTag(headline.userId, 0),
                  child: ProfilePhoto(url: mainPhoto, name: headline.name),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: photoHeight - overlap),
          child: ProfileContentColumn(
            child: _HeroTitle(
              headline: headline,
              eyebrow: eyebrow,
              footer: footer,
            ),
          ),
        ),
      ],
    );
  }
}

/// Centres profile content in a readable column with the page gutter.
class ProfileContentColumn extends StatelessWidget {
  const ProfileContentColumn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth.isFinite
          ? box.maxWidth
          : MediaQuery.sizeOf(context).width;
      final gutter = ConnectMetrics.gutterFor(width);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kProfileContentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// The photo frame: Ken Burns inside, parallax and stretch from the scroll
/// position, and a dissolve at the bottom so the photo melts into whatever
/// is behind the page (the flat Today ground or a cinematic scene).
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.height,
    required this.overlap,
    required this.child,
  });

  final double height;
  final double overlap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = CinematicLevel.of(context);
    final factor = switch (level) {
      CinematicLevel.still => 0.0,
      CinematicLevel.subtle => 0.3,
      CinematicLevel.full => 0.45,
    };
    // Mask colours only carry alpha (dstIn keeps the photo where the mask
    // is opaque); the scheme's scrim is used so no literal colour appears.
    final ink = scheme.scrim;
    final fadeTop = ((height - overlap * 1.9) / height).clamp(0.0, 1.0);
    final fadeMid = ((height - overlap) / height).clamp(fadeTop, 1.0);
    final fadeLow = ((height - overlap * 0.4) / height).clamp(fadeMid, 1.0);
    return ClipRect(
      clipper: const _OpenTopClipper(),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ink,
            ink,
            ink.withValues(alpha: 0.42),
            ink.withValues(alpha: 0.08),
            ink.withValues(alpha: 0),
          ],
          stops: [0, fadeTop, fadeMid, fadeLow, 1],
        ).createShader(rect),
        child: Flow(
          delegate: _HeroScrollDelegate(
            position: Scrollable.maybeOf(context)?.position,
            parallax: factor,
          ),
          children: [RepaintBoundary(child: CinematicKenBurns(child: child))],
        ),
      ),
    );
  }
}

/// Clips the bottom and sides of the hero but leaves the top open, so the
/// photo can stretch up into an overscroll.
class _OpenTopClipper extends CustomClipper<Rect> {
  const _OpenTopClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height * 4, size.width, size.height);

  @override
  bool shouldReclip(_OpenTopClipper oldClipper) => false;
}

/// Parallax while scrolling up (the photo sits deeper than the page) and a
/// stretch when pulled down past the top. Paint only: scrolling never
/// rebuilds the hero.
class _HeroScrollDelegate extends FlowDelegate {
  _HeroScrollDelegate({required this.parallax, this.position})
    : super(repaint: position);

  final ScrollPosition? position;
  final double parallax;

  @override
  void paintChildren(FlowPaintingContext context) {
    final position = this.position;
    final pixels = position == null || !position.hasPixels
        ? 0.0
        : position.pixels;
    final size = context.size;
    if (pixels < 0 && size.height > 0) {
      // Overscroll: grow upward from the bottom edge to fill the gap.
      final scale = (size.height - pixels) / size.height;
      final transform = Matrix4.identity()
        ..translateByDouble(size.width / 2, size.height, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-size.width / 2, -size.height, 0, 1);
      context.paintChild(0, transform: transform);
      return;
    }
    if (parallax == 0 || pixels == 0) {
      context.paintChild(0);
      return;
    }
    final shift = math.min(pixels, size.height) * parallax;
    context.paintChild(0, transform: Matrix4.translationValues(0, shift, 0));
  }

  @override
  bool shouldRepaint(_HeroScrollDelegate old) =>
      old.position != position || old.parallax != parallax;
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({
    required this.headline,
    required this.eyebrow,
    this.footer,
  });

  final ProfileHeadline headline;
  final String eyebrow;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final nameSize = wide ? 60.0 : 46.0;
    // A soft halo in the page's own tone keeps the title legible where the
    // photo has not fully dissolved.
    final halo = [
      Shadow(color: scheme.surface.withValues(alpha: 0.72), blurRadius: 18),
    ];
    final meta = [
      if ((headline.profession ?? '').trim().isNotEmpty)
        (Icons.work_outline_rounded, headline.profession!.trim()),
      if ((headline.place ?? '').trim().isNotEmpty)
        (Icons.place_outlined, headline.place!.trim()),
    ];
    final nameLabel = [
      headline.displayName,
      if (headline.isVerified) l10n.memberProfileVerified,
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 3.2,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
            shadows: halo,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          label: nameLabel,
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: headline.name),
                  if (headline.age != null)
                    TextSpan(
                      text: '  ${headline.age}',
                      style: TextStyle(
                        fontSize: nameSize * 0.62,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (headline.isVerified)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.verified_rounded,
                          size: nameSize * 0.5,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.displayMedium?.copyWith(
                fontFamily: AppTheme.displayFamily,
                fontSize: nameSize,
                fontWeight: FontWeight.w600,
                height: 1.04,
                letterSpacing: -1,
                color: scheme.onSurface,
                shadows: halo,
              ),
            ),
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final (icon, text) in meta)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: scheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          shadows: halo,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if ((headline.logline ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            headline.logline!.trim(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: AppTheme.displayFamily,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: scheme.onSurface,
            ),
          ),
        ],
        if (headline.badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in headline.badges)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (footer != null) ...[const SizedBox(height: 16), footer!],
      ],
    );
  }
}

/// The bar floating over the hero: a soft scrim behind round buttons while
/// the photo is showing, then a quiet surface with the member's name once
/// the photo has scrolled away. Only the fill and the title listen to the
/// scroll; the buttons are built once.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({
    required this.controller,
    required this.collapseAt,
    required this.title,
    super.key,
    this.leading,
    this.actions = const <Widget>[],
  });

  final ScrollController controller;

  /// Scroll offset at which the photo has left the screen.
  final double collapseAt;
  final String title;
  final Widget? leading;
  final List<Widget> actions;

  double _progress() {
    if (!controller.hasClients) {
      return 0;
    }
    final offset = controller.offset;
    return ((offset - (collapseAt - 96)) / 96).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final dark = theme.brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, buttons) {
        final t = _progress();
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: t > 0.5 && !dark
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    scheme.scrim.withValues(alpha: 0.42),
                    scheme.surface,
                    t,
                  )!,
                  Color.lerp(
                    scheme.scrim.withValues(alpha: 0),
                    scheme.surface,
                    t,
                  )!,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: t),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 72),
                    child: Opacity(
                      opacity: t,
                      child: ExcludeSemantics(
                        excluding: t < 0.5,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: AppTheme.displayFamily,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  buttons!,
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            ?leading,
            const Spacer(),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A round frosted button for the profile's top bar: legible over any photo
/// because it carries its own surface.
class ProfileBarButton extends StatelessWidget {
  const ProfileBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.buttonKey,
    this.qaId,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Key for the inner [IconButton] (automation).
  final Key? buttonKey;

  /// Automation id (a semantics identifier; the button is announced by its
  /// localized [tooltip]).
  final String? qaId;

  @override
  Widget build(BuildContext context) {
    final button = ProfileBarDisc(
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
    if (qaId == null) {
      return button;
    }
    return MergeSemantics(
      child: Semantics(identifier: qaId, child: button),
    );
  }
}

/// The frosted disc behind a top-bar control; also wraps controls built
/// elsewhere (the add-friend button).
class ProfileBarDisc extends StatelessWidget {
  const ProfileBarDisc({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface.withValues(alpha: 0.84),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: scheme.onSurface,
            minimumSize: const Size.square(48),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// The other photos as a strip of film: frames snap one at a time, carry a
/// frame number on the perforated edge, and open the full-screen gallery.
class ProfilePhotoReel extends StatefulWidget {
  const ProfilePhotoReel({
    required this.userId,
    required this.name,
    required this.photos,
    required this.onOpen,
    super.key,
    this.firstIndex = 1,
    this.carouselKey,
    this.carouselQaId,
    this.frameKeyPrefix,
  });

  final String userId;
  final String name;

  /// Every photo; the reel shows those from [firstIndex] on.
  final List<String> photos;
  final int firstIndex;

  /// Opens the gallery on a photo index; resolves to the index the member
  /// was looking at when they closed it.
  final Future<int?> Function(int index) onOpen;

  /// Automation key and id (semantics identifier) for the strip.
  final Key? carouselKey;
  final String? carouselQaId;

  /// Frame keys and automation ids are `<prefix><photo index>`.
  final String? frameKeyPrefix;

  @override
  State<ProfilePhotoReel> createState() => _ProfilePhotoReelState();
}

class _ProfilePhotoReelState extends State<ProfilePhotoReel> {
  PageController? _controller;
  double _fraction = 0;
  int _page = 0;

  int get _count => math.max(0, widget.photos.length - widget.firstIndex);

  PageController _controllerFor(double fraction) {
    final current = _controller;
    if (current != null && (fraction - _fraction).abs() < 0.001) {
      return current;
    }
    // Disposed after the frame: the old PageView may still be attached.
    WidgetsBinding.instance.addPostFrameCallback((_) => current?.dispose());
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

  Future<void> _open(int photoIndex) async {
    final landed = await widget.onOpen(photoIndex);
    final controller = _controller;
    if (!mounted || landed == null || controller == null) {
      return;
    }
    final page = landed - widget.firstIndex;
    if (page >= 0 && page < _count && controller.hasClients) {
      controller.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final count = _count;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final total = widget.photos.length;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final gutter = ConnectMetrics.gutterFor(width);
        final frameWidth = math.min<double>(232, (width - gutter) * 0.58);
        const gap = 12.0;
        const edge = 20.0;
        final frameHeight = frameWidth * 5 / 4;
        final fraction = ((frameWidth + gap) / (width - gutter)).clamp(
          0.1,
          1.0,
        );
        final controller = _controllerFor(fraction);
        final strip = SizedBox(
          height: frameHeight + edge * 2,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: EdgeInsets.only(left: gutter),
              child: PageView.builder(
                key: widget.carouselKey,
                controller: controller,
                padEnds: false,
                clipBehavior: Clip.none,
                itemCount: count,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, page) {
                  final index = widget.firstIndex + page;
                  return _ReelFrame(
                    key: widget.frameKeyPrefix == null
                        ? null
                        : ValueKey<String>('${widget.frameKeyPrefix}$index'),
                    qaId: widget.frameKeyPrefix == null
                        ? null
                        : '${widget.frameKeyPrefix}$index',
                    semanticsLabel: l10n.memberProfilePhotoLabel(
                      widget.name,
                      index + 1,
                      total,
                    ),
                    hint: l10n.memberProfileViewPhotoHint,
                    number: index + 1,
                    gap: gap,
                    edge: edge,
                    selected: page == _page,
                    onTap: () => _open(index),
                    child: Hero(
                      tag: profilePhotoHeroTag(widget.userId, index),
                      child: ProfilePhoto(
                        url: widget.photos[index],
                        name: widget.name,
                        cacheWidth: (frameWidth * dpr).round(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileContentColumn(
              child: ConnectSectionHeader(
                label: l10n.memberProfilePhotos.toUpperCase(),
                // Bounded so very large text wraps instead of overflowing.
                trailing: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.4),
                  child: Text(
                    l10n.memberProfileMorePhotos(count),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ConnectMetrics.cardGap),
            if (widget.carouselQaId == null)
              strip
            else
              Semantics(
                container: true,
                identifier: widget.carouselQaId,
                child: strip,
              ),
            const SizedBox(height: 12),
            ProfileContentColumn(
              child: _ReelIndicator(
                count: count,
                page: _page,
                photoNumber: widget.firstIndex + _page + 1,
                total: total,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReelFrame extends StatelessWidget {
  const _ReelFrame({
    required this.semanticsLabel,
    this.qaId,
    required this.hint,
    required this.number,
    required this.gap,
    required this.edge,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String semanticsLabel;

  /// Automation id for the frame (a semantics identifier, never spoken).
  final String? qaId;
  final String hint;
  final int number;
  final double gap;
  final double edge;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final perforation = scheme.surface;
    return Semantics(
      identifier: qaId,
      button: true,
      image: true,
      selected: selected,
      label: semanticsLabel,
      onTapHint: hint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            children: [
              SizedBox(
                height: edge,
                child: CustomPaint(
                  painter: _PerforationPainter(color: perforation),
                  size: Size.infinite,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: gap),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  ),
                ),
              ),
              SizedBox(
                height: edge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PerforationPainter(color: perforation),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              number.toString().padLeft(2, '0'),
                              textScaler: TextScaler.noScaling,
                              style: AppTheme.technical(
                                10,
                                selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sprocket holes along a film edge, in the page's own tone.
class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    const hole = Size(8, 6);
    const pitch = 16.0;
    final paint = Paint()..color = color;
    final y = (size.height - hole.height) / 2;
    for (var x = 4.0; x + hole.width <= size.width; x += pitch) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, hole.width, hole.height),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.color != color;
}

class _ReelIndicator extends StatelessWidget {
  const _ReelIndicator({
    required this.count,
    required this.page,
    required this.photoNumber,
    required this.total,
  });

  final int count;
  final int page;

  /// The photo showing first in the strip, and how many photos in all, so
  /// the counter matches the frame numbers on the film edge.
  final int photoNumber;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final still = CinematicLevel.of(context) == CinematicLevel.still;
    return ExcludeSemantics(
      child: Row(
        children: [
          if (count <= 8)
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: CinematicMotion.settle,
                margin: const EdgeInsets.only(right: 4),
                width: i == page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == page ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          const Spacer(),
          Text(
            '${photoNumber.toString().padLeft(2, '0')} / '
            '${total.toString().padLeft(2, '0')}',
            style: AppTheme.technical(12, scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Opens the full-screen gallery on [initialIndex]. Resolves to the index
/// showing when it was closed.
Future<int?> openProfileGallery(
  BuildContext context, {
  required String userId,
  required String name,
  required List<String> photos,
  required int initialIndex,
}) {
  final still = CinematicLevel.of(context) == CinematicLevel.still;
  final duration = still ? Duration.zero : const Duration(milliseconds: 360);
  return Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => ProfileGalleryScreen(
        userId: userId,
        name: name,
        photos: photos,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: CinematicMotion.enter,
        ),
        child: child,
      ),
    ),
  );
}

/// Full-screen photos: swipe between them, pinch to look closer.
class ProfileGalleryScreen extends StatefulWidget {
  const ProfileGalleryScreen({
    required this.userId,
    required this.name,
    required this.photos,
    required this.initialIndex,
    super.key,
  });

  final String userId;
  final String name;
  final List<String> photos;
  final int initialIndex;

  @override
  State<ProfileGalleryScreen> createState() => _ProfileGalleryScreenState();
}

class _ProfileGalleryScreenState extends State<ProfileGalleryScreen> {
  late final PageController _controller = PageController(initialPage: _index);
  late int _index = widget.photos.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.photos.length - 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = _lightInk(scheme);
    final l10n = AppLocalizations.of(context);
    final count = math.max(1, widget.photos.length);
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: scheme.scrim,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                key: const ValueKey('qa.profile.gallery'),
                controller: _controller,
                itemCount: count,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final url = widget.photos.isEmpty
                      ? null
                      : widget.photos[index];
                  return Semantics(
                    image: true,
                    label: url == null
                        ? l10n.memberProfileNoPhoto
                        : l10n.memberProfilePhotoLabel(
                            widget.name,
                            index + 1,
                            count,
                          ),
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: Hero(
                          tag: profilePhotoHeroTag(widget.userId, index),
                          child: url == null
                              ? AspectRatio(
                                  aspectRatio: 4 / 5,
                                  child: ProfilePhotoFallback(
                                    name: widget.name,
                                  ),
                                )
                              : ProfilePhoto(
                                  url: url,
                                  name: widget.name,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.scrim.withValues(alpha: 0.7),
                        scheme.scrim.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                      child: Row(
                        children: [
                          IconButton(
                            key: const ValueKey('qa.profile.gallery.close'),
                            tooltip: l10n.memberProfileCloseGallery,
                            onPressed: _close,
                            color: ink,
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: AppTheme.displayFamily,
                                color: ink,
                              ),
                            ),
                          ),
                          Text(
                            '${_index + 1} / $count',
                            style: AppTheme.technical(14, ink),
                          ),
                        ],
                      ),
                    ),
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
