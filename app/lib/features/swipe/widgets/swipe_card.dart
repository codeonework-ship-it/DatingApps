import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/discovery_profile.dart';

class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onPassTap,
    this.onLikeTap,
    this.onMessageTap,
    this.isActionLocked = false,
  });
  final DiscoveryProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onPassTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;
  final bool isActionLocked;

  double _cardWidth(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return (screenSize.width - 40).clamp(300.0, 460.0).toDouble();
  }

  double _cardHeight(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final cardWidth = _cardWidth(context);
    final targetHeight = cardWidth * 1.54;
    final maxHeightByScreen = (screenSize.height * 0.69)
        .clamp(380.0, 710.0)
        .toDouble();
    return targetHeight > maxHeightByScreen ? maxHeightByScreen : targetHeight;
  }

  String _formattedTierLabel(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return 'Spotlight';
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = _cardWidth(context);
    final cardHeight = _cardHeight(context);
    final quickTags = profile.quickPreviewTags.take(3).toList();

    return GlassContainer(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white.withValues(alpha: 0.84),
      blur: 12,
      crystalEffect: true,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      shadows: [
        BoxShadow(
          color: AppTheme.trustBlue.withValues(alpha: 0.14),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
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
                          '${profile.name}, ${profile.age}',
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
                            color: AppTheme.trustBlue.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formattedTierLabel(profile.spotlightTier ?? ''),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (profile.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),

                  // Compact tags preview
                  if (quickTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickTags
                          .map(
                            (tag) => Container(
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
                          )
                          .toList(),
                    ),
                  ],

                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View more',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        if (onMessageTap != null) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
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
                                  'Message',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
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
    decoration: const BoxDecoration(gradient: AppTheme.postLoginGradient),
    child: const Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 68,
        color: AppTheme.textHint,
      ),
    ),
  );
}
