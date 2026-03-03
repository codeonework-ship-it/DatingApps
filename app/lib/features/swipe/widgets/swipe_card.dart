import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/discovery_profile.dart';

class SwipeCard extends StatelessWidget {
  const SwipeCard({Key? key, required this.profile, this.onTap})
    : super(key: key);
  final DiscoveryProfile profile;
  final VoidCallback? onTap;

  double _cardHeight(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final cardWidth = (screenSize.width - 40).clamp(280.0, 420.0).toDouble();
    final targetHeight = cardWidth * 1.35;
    final maxHeightByScreen = (screenSize.height * 0.62)
        .clamp(360.0, 620.0)
        .toDouble();
    return targetHeight > maxHeightByScreen ? maxHeightByScreen : targetHeight;
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = _cardHeight(context);
    final primaryPhotoUrl = profile.photoUrls.isNotEmpty
        ? profile.photoUrls.first
        : '';
    final quickTags = profile.quickPreviewTags.take(3).toList();

    return GlassContainer(
      width: double.infinity,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: primaryPhotoUrl.isEmpty
                ? Container(
                    height: cardHeight,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.postLoginGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 68,
                        color: AppTheme.textHint,
                      ),
                    ),
                  )
                : Image.network(
                    primaryPhotoUrl,
                    fit: BoxFit.cover,
                    height: cardHeight,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: cardHeight,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.postLoginGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 68,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
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
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
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
                      Text(
                        profile.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
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
                  ],
                ],
              ),
            ),
          ),

          // Swipe Hint Badges
          Positioned(
            top: 16,
            left: 16,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              blur: 10,
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'PASS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              blur: 10,
              child: const Row(
                children: [
                  Text(
                    'LIKE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
