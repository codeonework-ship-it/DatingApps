import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_client_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/cinematic_effects.dart';
import '../../core/theme/theme_presets.dart';
import '../auth/providers/auth_provider.dart';
import '../blog/blog_screen.dart';
import '../photo_themes/photo_theme_gallery_screen.dart';
import 'celebrations_data.dart';
import 'reward_burst.dart';

/// Watches for new wall tiers and plays the rose rain once per tier.
///
/// Place it once inside the signed-in shell. It checks on mount and whenever
/// the app returns to the foreground, shows one celebration at a time, and
/// marks each one seen when it is dismissed. It renders nothing itself.
class RoseRainHost extends ConsumerStatefulWidget {
  const RoseRainHost({super.key});

  @override
  ConsumerState<RoseRainHost> createState() => _RoseRainHostState();
}

class _RoseRainHostState extends ConsumerState<RoseRainHost>
    with WidgetsBindingObserver {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_showing || !mounted) {
      return;
    }
    if (ref.read(authNotifierProvider).userId == null) {
      return;
    }
    final api = ref.read(apiClientProvider);
    _showing = true;
    try {
      final items = await fetchWallCelebrations(api);
      for (final celebration in items) {
        if (!mounted) {
          return;
        }
        final open = await showRoseRain(context, celebration);
        await markWallCelebrationSeen(api, celebration.id);
        if (!mounted) {
          return;
        }
        if (open) {
          await _openContent(celebration);
          break;
        }
      }
    } finally {
      _showing = false;
    }
  }

  Future<void> _openContent(WallCelebration celebration) async {
    if (celebration.isPhoto && celebration.themeId.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhotoThemeGalleryScreen(themeId: celebration.themeId),
        ),
      );
    } else if (!celebration.isPhoto) {
      await openBlogPost(context, celebration.contentId);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Plays a short rose-petal shower with the tier card. Returns true when the
/// member chose to open the chapter or photo.
///
/// The Calm look and the platform's reduce-motion setting get the card with
/// no falling petals and no haptic.
Future<bool> showRoseRain(
  BuildContext context,
  WallCelebration celebration,
) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => RoseRainOverlay(celebration: celebration),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
  return result ?? false;
}

class RoseRainOverlay extends StatefulWidget {
  const RoseRainOverlay({required this.celebration, super.key});

  final WallCelebration celebration;

  @override
  State<RoseRainOverlay> createState() => _RoseRainOverlayState();
}

class _RoseRainOverlayState extends State<RoseRainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rain;
  late final List<_Petal> _petals = _Petal.shower(
    widget.celebration.contentId.hashCode ^ widget.celebration.tier,
  );
  bool _still = false;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a still (reduced-motion) card never touches it, and a
    // first lazy access inside dispose() would look up a deactivated tree.
    _rain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = AppTheme.reduceMotionOf(context);
    if (!_still && !_rain.isAnimating && _rain.value == 0) {
      HapticFeedback.mediumImpact();
      _rain.forward();
    }
  }

  @override
  void dispose() {
    _rain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Rose tones lead so it always reads as roses; the theme adds a hint.
    const rose = Color(0xFFD81B4A);
    final palette = <Color>[
      rose,
      const Color(0xFFFF8FAB),
      const Color(0xFFE8456B),
      const Color(0xFFFFB3C6),
      Color.lerp(colors.primary, rose, 0.6)!,
    ];
    // The shower follows the look: Rose and Petal get the rose burst on top
    // of the petal rain, Snow and Gothic their own burst instead, and every
    // other look keeps the classic petal rain.
    final style = RewardBurstStyle.of(context);
    final rain =
        style == RewardBurstStyle.confetti || style == RewardBurstStyle.roses;
    final burst = style != RewardBurstStyle.confetti;
    final preset = theme.extension<ConnectPalette>()?.preset;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover of the Week opens with one bloom of light, like a
          // flashbulb going off across the room.
          if (!_still && widget.celebration.isCover)
            IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _rain,
                  builder: (_, _) => CustomPaint(
                    painter: CinematicBloomPainter(
                      progress: _rain.value,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          if (!_still && rain)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _rain,
                builder: (_, _) => CustomPaint(
                  painter: _RoseRainPainter(
                    petals: _petals,
                    progress: _rain.value,
                    palette: palette,
                  ),
                ),
              ),
            ),
          if (!_still && burst)
            IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _rain,
                  builder: (_, _) => CustomPaint(
                    painter: RewardBurstPainter(
                      style: style,
                      progress: (_rain.value * 1.1).clamp(0.0, 1.0),
                      seed: widget.celebration.id.hashCode,
                      palette: RewardBurstPalette.from(preset, colors),
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _TierCard(
                celebration: widget.celebration,
                animate: !_still,
                icon: style == RewardBurstStyle.confetti
                    ? Icons.local_florist_rounded
                    : style.icon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.celebration,
    required this.animate,
    required this.icon,
  });

  final WallCelebration celebration;
  final bool animate;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.35),
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                ),
                child: Icon(icon, color: colors.onPrimary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                celebration.headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              if (celebration.title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '“${celebration.title}”',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                celebration.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('qa.rose_rain.close'),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Lovely'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('qa.rose_rain.open'),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        celebration.isPhoto ? 'See photo' : 'See chapter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!animate) {
      return card;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1).toDouble(),
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: card,
    );
  }
}

/// One falling petal, described in normalised screen units so the shower
/// looks the same on every device size.
class _Petal {
  const _Petal({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.swaySpeed,
    required this.spin,
    required this.size,
    required this.color,
  });

  /// A seeded shower: deterministic for a given celebration.
  static List<_Petal> shower(int seed) {
    final rnd = math.Random(seed);
    return List<_Petal>.generate(
      72,
      (_) => _Petal(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.45,
        fall: 0.45 + rnd.nextDouble() * 0.35,
        sway: 0.02 + rnd.nextDouble() * 0.05,
        swaySpeed: 1.5 + rnd.nextDouble() * 2.5,
        spin: (rnd.nextBool() ? 1 : -1) * (1 + rnd.nextDouble() * 3),
        size: 12 + rnd.nextDouble() * 18,
        color: rnd.nextInt(5),
      ),
    );
  }

  final double x, delay, fall, sway, swaySpeed, spin, size;
  final int color;
}

class _RoseRainPainter extends CustomPainter {
  _RoseRainPainter({
    required this.petals,
    required this.progress,
    required this.palette,
  });

  final List<_Petal> petals;
  final double progress;
  final List<Color> palette;

  Path _petalPath(double length) {
    final w = length * 0.62;
    final h = length / 2;
    return Path()
      ..moveTo(0, h)
      ..cubicTo(w * 0.9, h * 0.55, w * 0.75, -h * 0.85, w * 0.12, -h)
      ..quadraticBezierTo(0, -h * 0.82, -w * 0.12, -h)
      ..cubicTo(-w * 0.75, -h * 0.85, -w * 0.9, h * 0.55, 0, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final local = ((progress - petal.delay) / petal.fall).clamp(0.0, 1.0);
      if (local <= 0) {
        continue;
      }
      // Fade in at the top, fade out as the shower settles.
      final fade = progress > 0.8 ? (1 - progress) / 0.2 : 1.0;
      final opacity = (math.min(local * 4, 1) * fade).clamp(0.0, 1.0);
      final y = -0.08 + local * 1.16;
      final x =
          petal.x + math.sin(local * math.pi * petal.swaySpeed) * petal.sway;
      final center = Offset(x * size.width, y * size.height);
      final color = palette[petal.color % palette.length];
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(local * petal.spin * math.pi)
        // Tumbling: a petal turning edge-on looks narrower.
        ..scale(0.55 + 0.45 * math.cos(local * petal.spin * 2).abs(), 1);
      final path = _petalPath(petal.size);
      canvas
        ..drawPath(
          path,
          Paint()
            ..shader =
                RadialGradient(
                  center: const Alignment(0, 0.6),
                  colors: [
                    color.withValues(alpha: 0.95 * opacity),
                    color.withValues(alpha: 0.55 * opacity),
                  ],
                ).createShader(
                  Rect.fromCircle(center: Offset.zero, radius: petal.size),
                ),
        )
        ..drawLine(
          Offset(0, petal.size * 0.38),
          Offset(0, -petal.size * 0.25),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35 * opacity)
            ..strokeWidth = 0.8,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_RoseRainPainter old) => old.progress != progress;
}
