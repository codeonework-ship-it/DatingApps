import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/discovery_profile.dart';

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    required this.profile,
    super.key,
    this.onTap,
    this.onPassTap,
    this.onLikeTap,
    this.onMessageTap,
    this.isActionLocked = false,
    this.maxHeight,
    this.flipToken = 0,
    this.qaScope = 'qa.discovery',
  });
  final DiscoveryProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onPassTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;
  final bool isActionLocked;
  final double? maxHeight;

  /// Bump to spin the card through a full turn.
  ///
  /// A token rather than a bool: the parent fires this on every like, and
  /// consecutive likes must each produce their own spin rather than the second
  /// one being swallowed because the flag was already set.
  final int flipToken;

  /// Prefix of the card's automation handles: `qa.discovery` on the deck,
  /// `qa.spotlight` on the full Spotlight screen.
  final String qaScope;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipToken != oldWidget.flipToken) {
      _spin();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _spin() {
    if (!mounted) {
      return;
    }
    // Honour the platform's reduce-motion setting and the Calm look: a full
    // 360 spin is exactly the kind of vestibular trigger they exist for.
    if (AppTheme.reduceMotionOf(context)) {
      return;
    }
    _flip.forward(from: 0);
  }

  DiscoveryProfile get profile => widget.profile;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onPassTap => widget.onPassTap;
  VoidCallback? get onLikeTap => widget.onLikeTap;
  VoidCallback? get onMessageTap => widget.onMessageTap;
  bool get isActionLocked => widget.isActionLocked;
  double? get maxHeight => widget.maxHeight;

  /// Width the card should occupy, given what the parent actually offers.
  ///
  /// This used to derive width from `MediaQuery.size.width - 52`, ignoring the
  /// constraints handed down by the deck. The deck already applies its own
  /// horizontal padding and a 680 max width, so the card came out narrower
  /// than the header and Spotlight row directly above it and the column looked
  /// visibly misaligned. Measuring the offered width keeps every section on
  /// the same edges.
  double _cardWidth(BuildContext context, BoxConstraints constraints) {
    if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
      return constraints.maxWidth;
    }
    final screenSize = MediaQuery.sizeOf(context);
    return (screenSize.width - 52).clamp(288.0, 436.0).toDouble();
  }

  double _cardHeight(BuildContext context, BoxConstraints constraints) {
    final screenSize = MediaQuery.sizeOf(context);
    final cardWidth = _cardWidth(context, constraints);
    final targetHeight = cardWidth * 1.72;
    final compactScreen = screenSize.height < 720;
    final desiredMinimum = compactScreen ? 300.0 : 364.0;
    final maxHeightByScreen = (maxHeight ?? screenSize.height * 0.72)
        .clamp(280.0, 760.0)
        .toDouble();
    final minimum = math.min(desiredMinimum, maxHeightByScreen);
    return targetHeight.clamp(minimum, maxHeightByScreen).toDouble();
  }

  String _formattedTierLabel(BuildContext context, String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return AppLocalizations.of(context).memberProfileSpotlight;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _buildCard(context, constraints),
  );

  Widget _buildCard(BuildContext context, BoxConstraints constraints) {
    final cardWidth = _cardWidth(context, constraints);
    final cardHeight = _cardHeight(context, constraints);
    final quickTags = profile.quickPreviewTags.take(3).toList();
    final reasonChips = profile.reasons.take(2).toList(growable: false);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${widget.qaScope}.card_root',
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, child) {
          final turn = Curves.easeInOutCubic.transform(_flip.value);
          final angle = turn * 2 * math.pi;
          // Perspective makes the spin read as a card turning in space rather
          // than a flat horizontal squash.
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateY(angle);
          // Between a quarter and three-quarters of the turn the card is
          // showing its reverse, which would mirror the photo and the name.
          // Counter-rotating the content keeps everything legible, so the card
          // reads as one solid object spinning rather than a flipped image.
          final showingBack = turn > 0.25 && turn < 0.75;
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: showingBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: child,
                  )
                : child,
          );
        },
        child: GlassContainer(
          key: ValueKey('${widget.qaScope}.card_root'),
          width: cardWidth,
          height: cardHeight,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          backgroundColor: scheme.surface,
          blur: 12,
          crystalEffect: true,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Stack(
            children: [
              // Profile Image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: _SwipeCardPrimaryImage(photoUrls: profile.photoUrls),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.56),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and Age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (profile.isSpotlight) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formattedTierLabel(
                                  context,
                                  profile.spotlightTier ?? '',
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          if (profile.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Location and Distance
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick bio
                      if (profile.quickBio.isNotEmpty)
                        Text(
                          profile.quickBio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                        ),

                      // Compact tags preview. Curated reasons ("Shares your
                      // intent") lead, then the profile's own tags.
                      if (quickTags.isNotEmpty || reasonChips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < reasonChips.length; i++)
                              Container(
                                key: ValueKey(
                                  'qa.discover.today.deck_reason.$i',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reasonChips[i],
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            for (final tag in quickTags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      if (onTap != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The card sits inside a fixed-width swipe deck, so
                            // this action has no room to negotiate for on a 320pt
                            // phone; letting it shrink is what keeps it on-card.
                            Flexible(
                              child: Semantics(
                                label: '${widget.qaScope}.view_more_button',
                                button: true,
                                child: GestureDetector(
                                  key: ValueKey(
                                    '${widget.qaScope}.view_more_button',
                                  ),
                                  onTap: onTap,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // The outer Flexible can only shrink this
                                      // row if something inside it will yield.
                                      Flexible(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).discoverViewMore,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (onMessageTap != null) ...[
                              const SizedBox(width: 12),
                              Semantics(
                                label: '${widget.qaScope}.card_message_button',
                                button: true,
                                child: GestureDetector(
                                  key: ValueKey(
                                    '${widget.qaScope}.card_message_button',
                                  ),
                                  onTap: onMessageTap,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.message_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).memberProfileMessage,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
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

class _SwipeCardPrimaryImage extends StatefulWidget {
  const _SwipeCardPrimaryImage({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_SwipeCardPrimaryImage> createState() => _SwipeCardPrimaryImageState();
}

class _SwipeCardPrimaryImageState extends State<_SwipeCardPrimaryImage> {
  int _activeIndex = 0;

  List<String> get _urls => widget.photoUrls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  @override
  void didUpdateWidget(covariant _SwipeCardPrimaryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrls != widget.photoUrls) {
      _activeIndex = 0;
    }
  }

  void _advanceOnError() {
    if (!mounted) {
      return;
    }
    final urls = _urls;
    if (_activeIndex + 1 < urls.length) {
      setState(() => _activeIndex += 1);
      return;
    }
    if (_activeIndex != urls.length) {
      setState(() => _activeIndex = urls.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    if (urls.isEmpty || _activeIndex >= urls.length) {
      return const _SwipeCardImageFallback();
    }

    return Image.network(
      urls[_activeIndex],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _advanceOnError());
        return const _SwipeCardImageFallback();
      },
    );
  }
}

class _SwipeCardImageFallback extends StatelessWidget {
  const _SwipeCardImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: AppTheme.groundGradientOf(context)),
    child: Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 68,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
