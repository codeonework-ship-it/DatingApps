import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/discovery_profile.dart';

class PremiumSpotlightCard extends StatefulWidget {
  const PremiumSpotlightCard({
    super.key,
    required this.profile,
    this.onTap,
    this.height,
  });

  final DiscoveryProfile profile;
  final VoidCallback? onTap;
  final double? height;

  @override
  State<PremiumSpotlightCard> createState() => _PremiumSpotlightCardState();
}

class _PremiumSpotlightCardState extends State<PremiumSpotlightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  String _tierLabel(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return 'Premium';
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.height ?? 260;

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassContainer(
        width: double.infinity,
        height: cardHeight,
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
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: widget.profile.photoUrls.isNotEmpty
                    ? Image.network(
                        widget.profile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 56,
                            color: AppTheme.textHint,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 56,
                          color: AppTheme.textHint,
                        ),
                      ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: AppTheme.trustBlue.withValues(alpha: 0.82),
                blur: 8,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _tierLabel(widget.profile.spotlightTier ?? 'premium'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.profile.name}, ${widget.profile.age}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.profile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PremiumShineButton(controller: _shineController),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumShineButton extends StatelessWidget {
  const _PremiumShineButton({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: SizedBox(
      height: 28,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.crystalGoldDeep,
                  AppTheme.crystalGoldSoft,
                  AppTheme.crystalGoldDeep,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Premium view',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final shimmerWidth = width * 0.38;
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) {
                      final left =
                          (width + shimmerWidth) * controller.value -
                          shimmerWidth;
                      return Stack(
                        children: [
                          Positioned(
                            left: left,
                            top: -2,
                            bottom: -2,
                            child: Transform.rotate(
                              angle: -0.22,
                              child: Container(
                                width: shimmerWidth,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
