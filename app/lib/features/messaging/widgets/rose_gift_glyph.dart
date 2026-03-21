import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class RoseGiftGlyph extends StatelessWidget {
  const RoseGiftGlyph({
    required this.giftName,
    this.iconKey,
    this.giftId,
    this.size = 28,
    this.iconSize,
    super.key,
  });

  final String? iconKey;
  final String? giftId;
  final String giftName;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final glyph = resolveRoseGiftGlyph(
      iconKey: iconKey,
      giftId: giftId,
      giftName: giftName,
    );
    final accentGlyph = resolveRoseGiftAccentGlyph(
      iconKey: iconKey,
      giftId: giftId,
      giftName: giftName,
    );
    final tint = resolveRoseGiftTint(
      iconKey: iconKey,
      giftId: giftId,
      giftName: giftName,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            tint.withValues(alpha: 0.28),
            tint.withValues(alpha: 0.12),
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(glyph, size: iconSize ?? size * 0.62, color: tint),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Icon(
              accentGlyph,
              size: (iconSize ?? size * 0.62) * 0.34,
              color: tint.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class RoseGiftVisual extends StatelessWidget {
  const RoseGiftVisual({
    required this.giftName,
    this.iconKey,
    this.giftId,
    this.size,
    super.key,
  });

  final String? iconKey;
  final String? giftId;
  final String giftName;
  final Size? size;

  @override
  Widget build(BuildContext context) {
    final tint = resolveRoseGiftTint(
      iconKey: iconKey,
      giftId: giftId,
      giftName: giftName,
    );
    final accent = resolveRoseGiftAccentColor(
      iconKey: iconKey,
      giftId: giftId,
      giftName: giftName,
    );
    final boxSize = size ?? const Size(160, 96);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            tint.withValues(alpha: 0.24),
            accent.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 12,
            child: RoseGiftGlyph(
              iconKey: iconKey,
              giftId: giftId,
              giftName: giftName,
              size: boxSize.height * 0.66,
            ),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: RoseGiftGlyph(
              iconKey: iconKey,
              giftId: giftId,
              giftName: giftName,
              size: boxSize.height * 0.38,
              iconSize: boxSize.height * 0.2,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 14,
            child: Icon(
              resolveRoseGiftAccentGlyph(
                iconKey: iconKey,
                giftId: giftId,
                giftName: giftName,
              ),
              color: accent.withValues(alpha: 0.9),
              size: boxSize.height * 0.18,
            ),
          ),
        ],
      ),
    );
  }
}

IconData resolveRoseGiftGlyph({
  required String giftName,
  String? iconKey,
  String? giftId,
}) {
  final normalizedIcon = (iconKey ?? '').trim().toLowerCase();
  if (normalizedIcon.isNotEmpty) {
    switch (normalizedIcon) {
      case 'rose_gold':
        return Icons.local_florist_rounded;
      case 'rose_crystal':
        return Icons.local_florist_rounded;
      case 'rose_black':
        return Icons.local_florist_rounded;
      case 'rose_blue':
        return Icons.local_florist_rounded;
      case 'rose_white':
        return Icons.local_florist_rounded;
      case 'rose_yellow':
        return Icons.local_florist_rounded;
      case 'rose_pink':
      case 'rose_heart':
        return Icons.local_florist_rounded;
      case 'rose_lavender':
      case 'rose_sparkle':
        return Icons.local_florist_rounded;
      case 'rose_neon':
      case 'rose_burning':
      case 'rose_bouquet':
      case 'rose_seasonal':
        return Icons.local_florist_rounded;
      case 'rose_rain':
        return Icons.local_florist_rounded;
      case 'rose_red':
        return Icons.local_florist_rounded;
    }
  }

  final key = '${giftId ?? ''}|$giftName'.toLowerCase();
  if (key.contains('golden')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('crystal')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('black')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('blue')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('white')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('yellow')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('pink') || key.contains('heart')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('lavender') || key.contains('sparkle')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('neon') ||
      key.contains('burning') ||
      key.contains('bouquet') ||
      key.contains('seasonal')) {
    return Icons.local_florist_rounded;
  }
  if (key.contains('rain')) {
    return Icons.local_florist_rounded;
  }
  return Icons.local_florist_rounded;
}

IconData resolveRoseGiftAccentGlyph({
  required String giftName,
  String? iconKey,
  String? giftId,
}) {
  final key = '${iconKey ?? ''}|${giftId ?? ''}|$giftName'.toLowerCase();
  if (key.contains('gold')) {
    return Icons.workspace_premium_rounded;
  }
  if (key.contains('crystal')) {
    return Icons.diamond_rounded;
  }
  if (key.contains('black')) {
    return Icons.brightness_2_rounded;
  }
  if (key.contains('blue') || key.contains('rain')) {
    return Icons.water_drop_rounded;
  }
  if (key.contains('white')) {
    return Icons.auto_awesome_rounded;
  }
  if (key.contains('yellow')) {
    return Icons.wb_sunny_rounded;
  }
  if (key.contains('pink') || key.contains('heart')) {
    return Icons.favorite_rounded;
  }
  if (key.contains('lavender') || key.contains('sparkle')) {
    return Icons.auto_awesome_rounded;
  }
  if (key.contains('neon')) {
    return Icons.bolt_rounded;
  }
  if (key.contains('burning')) {
    return Icons.local_fire_department_rounded;
  }
  if (key.contains('bouquet')) {
    return Icons.filter_vintage_rounded;
  }
  if (key.contains('seasonal')) {
    return Icons.stars_rounded;
  }
  return Icons.spa_rounded;
}

Color resolveRoseGiftTint({
  required String giftName,
  String? iconKey,
  String? giftId,
}) {
  final normalizedIcon = (iconKey ?? '').trim().toLowerCase();
  if (normalizedIcon.isNotEmpty) {
    switch (normalizedIcon) {
      case 'rose_gold':
        return AppTheme.crystalGoldDeep;
      case 'rose_crystal':
        return AppTheme.crystalBlue;
      case 'rose_black':
        return AppTheme.textDark;
      case 'rose_blue':
        return AppTheme.infoBlue;
      case 'rose_white':
        return AppTheme.textHint;
      case 'rose_yellow':
        return AppTheme.warningOrange;
      case 'rose_pink':
      case 'rose_heart':
        return AppTheme.primaryRed;
      case 'rose_lavender':
      case 'rose_sparkle':
        return AppTheme.crystalRose;
      case 'rose_neon':
        return AppTheme.infoBlue;
      case 'rose_burning':
        return AppTheme.warningOrange;
      case 'rose_bouquet':
        return AppTheme.primaryRed;
      case 'rose_seasonal':
        return AppTheme.accentCyan;
      case 'rose_rain':
        return AppTheme.accentCyan;
      case 'rose_red':
        return AppTheme.primaryRed;
    }
  }

  final key = '${giftId ?? ''}|$giftName'.toLowerCase();
  if (key.contains('golden')) {
    return AppTheme.crystalGoldDeep;
  }
  if (key.contains('crystal')) {
    return AppTheme.crystalBlue;
  }
  if (key.contains('black')) {
    return AppTheme.textDark;
  }
  if (key.contains('blue')) {
    return AppTheme.infoBlue;
  }
  if (key.contains('white')) {
    return AppTheme.textHint;
  }
  if (key.contains('yellow')) {
    return AppTheme.warningOrange;
  }
  if (key.contains('pink') || key.contains('heart')) {
    return AppTheme.primaryRed;
  }
  if (key.contains('lavender') || key.contains('sparkle')) {
    return AppTheme.crystalRose;
  }
  if (key.contains('neon')) {
    return AppTheme.infoBlue;
  }
  if (key.contains('burning')) {
    return AppTheme.warningOrange;
  }
  if (key.contains('bouquet')) {
    return AppTheme.primaryRed;
  }
  if (key.contains('seasonal')) {
    return AppTheme.accentCyan;
  }
  if (key.contains('rain')) {
    return AppTheme.accentCyan;
  }
  return AppTheme.primaryRed;
}

Color resolveRoseGiftAccentColor({
  required String giftName,
  String? iconKey,
  String? giftId,
}) {
  final key = '${iconKey ?? ''}|${giftId ?? ''}|$giftName'.toLowerCase();
  if (key.contains('gold')) {
    return AppTheme.pureGoldBright;
  }
  if (key.contains('crystal')) {
    return AppTheme.crystalBlue;
  }
  if (key.contains('black')) {
    return AppTheme.textDark;
  }
  if (key.contains('blue') || key.contains('rain')) {
    return const Color(0xFF5B8CFF);
  }
  if (key.contains('white')) {
    return const Color(0xFFE8E8E8);
  }
  if (key.contains('yellow')) {
    return const Color(0xFFF2C94C);
  }
  if (key.contains('lavender') || key.contains('sparkle')) {
    return const Color(0xFFC197FF);
  }
  if (key.contains('neon')) {
    return const Color(0xFF6C63FF);
  }
  if (key.contains('burning')) {
    return const Color(0xFFFF8A50);
  }
  if (key.contains('bouquet')) {
    return const Color(0xFFFF6B8A);
  }
  if (key.contains('seasonal')) {
    return const Color(0xFF35D0FF);
  }
  return const Color(0xFFFF6B8A);
}
