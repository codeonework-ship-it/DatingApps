import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/cinematic_effects.dart';
import '../../core/theme/cinematic_motion.dart';
import '../../core/theme/theme_motifs.dart';
import '../../core/theme/theme_presets.dart';
import 'reward_ledger.dart';

export 'reward_ledger.dart' show RewardBurst, RewardBurstKind;

/// Which particles a reward burst throws, chosen by the member's look.
enum RewardBurstStyle {
  /// Snow: crystals radiate out, twinkle and drift down.
  snow,

  /// Rose, Blue Rose and Petal: whole roses and loose petals spin out and
  /// tumble. Blue Rose throws sapphire blooms.
  roses,

  /// Blue Lotus: open lotus blooms, loose petals and lily pads spin out and
  /// settle slowly, as if onto water.
  lotus,

  /// Gothic: bats swirl out past a flash of moonlight with crimson embers
  /// and candle sparks rising.
  gothic,

  /// Every other look: confetti in the look's own three accents.
  confetti;

  static RewardBurstStyle forPreset(ThemePreset? preset) =>
      switch (preset?.id) {
        'snow' => snow,
        'rose' || 'petal' || 'bluerose' => roses,
        'bluelotus' => lotus,
        'gothic' => gothic,
        _ => confetti,
      };

  static RewardBurstStyle of(BuildContext context) =>
      forPreset(Theme.of(context).extension<ConnectPalette>()?.preset);

  IconData get icon => switch (this) {
    snow => Icons.ac_unit_rounded,
    roses => Icons.local_florist_rounded,
    lotus => Icons.spa_rounded,
    gothic => Icons.nights_stay_rounded,
    confetti => Icons.celebration_rounded,
  };
}

/// Plays a theme-aware burst with a small card naming the reward, above every
/// route, without blocking the screen underneath. Bursts queue: a second call
/// waits for the first card to close. Completes when the card is gone.
///
/// Reduced motion (the platform setting or the Calm look) shows the card with
/// no particles and no haptic.
Future<void> showRewardBurst(BuildContext context, RewardBurst burst) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return Future<void>.value();
  }
  final done = Completer<void>();
  _queue.add(_QueuedBurst(overlay, burst, done));
  _pumpQueue();
  return done.future;
}

class _QueuedBurst {
  _QueuedBurst(this.overlay, this.burst, this.done);
  final OverlayState overlay;
  final RewardBurst burst;
  final Completer<void> done;
}

final List<_QueuedBurst> _queue = <_QueuedBurst>[];
OverlayEntry? _activeEntry;

void _pumpQueue() {
  if (_activeEntry != null) {
    return;
  }
  while (_queue.isNotEmpty) {
    final next = _queue.removeAt(0);
    if (!next.overlay.mounted) {
      next.done.complete();
      continue;
    }
    late final OverlayEntry entry;
    var closed = false;
    entry = OverlayEntry(
      builder: (_) => RewardBurstOverlay(
        burst: next.burst,
        onDone: () {
          if (closed) {
            return;
          }
          closed = true;
          entry.remove();
          _activeEntry = null;
          next.done.complete();
          _pumpQueue();
        },
      ),
    );
    _activeEntry = entry;
    next.overlay.insert(entry);
    return;
  }
}

/// Clears queued and showing bursts between widget tests.
@visibleForTesting
void debugResetRewardBursts() {
  _queue.clear();
  final active = _activeEntry;
  _activeEntry = null;
  if (active != null && active.mounted) {
    active.remove();
  }
}

/// The burst and its card. Particles ignore pointers and screen readers; the
/// card is a live region with a 48pt close button and closes itself after a
/// few seconds (longer when a screen reader is on).
class RewardBurstOverlay extends StatefulWidget {
  const RewardBurstOverlay({
    required this.burst,
    required this.onDone,
    this.lingerFor = const Duration(seconds: 6),
    super.key,
  });

  final RewardBurst burst;
  final VoidCallback onDone;
  final Duration lingerFor;

  @override
  State<RewardBurstOverlay> createState() => _RewardBurstOverlayState();
}

class _RewardBurstOverlayState extends State<RewardBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;
  Timer? _linger;
  bool _still = false;
  bool _started = false;
  late RewardBurstStyle _style;

  /// Big moments open with a single bloom of light before the particles.
  bool get _bigMoment => widget.burst.kind == RewardBurstKind.levelUp;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = AppTheme.reduceMotionOf(context);
    _style = RewardBurstStyle.of(context);
    if (_started) {
      return;
    }
    _started = true;
    if (!_still) {
      // A level-up lands harder than a single reward.
      if (_bigMoment) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      _burst.forward();
    }
    final reader = MediaQuery.accessibleNavigationOf(context);
    _linger = Timer(widget.lingerFor * (reader ? 2 : 1), widget.onDone);
  }

  @override
  void dispose() {
    _linger?.cancel();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = Theme.of(context).extension<ConnectPalette>()?.preset;
    final colors = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_still && _bigMoment)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (_, _) => CustomPaint(
                      painter: CinematicBloomPainter(
                        progress: _burst.value,
                        color: colors.primary,
                        origin: const Alignment(0, -0.62),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_still)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (_, _) => CustomPaint(
                      painter: RewardBurstPainter(
                        style: _style,
                        progress: _burst.value,
                        seed: widget.burst.title.hashCode,
                        palette: RewardBurstPalette.from(preset, colors),
                        origin: const Alignment(0, -0.62),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: RewardBurstCard(
                  burst: widget.burst,
                  style: _style,
                  animate: !_still,
                  onClose: widget.onDone,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small card that names the reward. Swipe it up or tap Close.
class RewardBurstCard extends StatelessWidget {
  const RewardBurstCard({
    required this.burst,
    required this.style,
    required this.onClose,
    this.animate = true,
    super.key,
  });

  final RewardBurst burst;
  final RewardBurstStyle style;
  final VoidCallback onClose;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOrEnglish(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 32,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                ),
                child: Icon(
                  burst.kind == RewardBurstKind.levelUp
                      ? Icons.military_tech_rounded
                      : style.icon,
                  color: colors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: burst.announcementIn(l10n),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                burst.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (burst.xp > 0) ...[
                              const SizedBox(width: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    l10n.rewardXpPill(burst.xp),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colors.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (burst.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            burst.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        for (final line in burst.lines) ...[
                          const SizedBox(height: 4),
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('qa.reward_burst.close'),
                tooltip: l10n.commonClose,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
    final announced = Dismissible(
      key: ValueKey<Object>(burst),
      direction: DismissDirection.up,
      onDismissed: (_) => onClose(),
      child: card,
    );
    if (!animate) {
      return announced;
    }
    // The same settle the page cuts and title cards use.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: CinematicMotion.settle,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1).toDouble(),
        child: Transform.translate(
          offset: Offset(0, -16 * (1 - t)),
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        ),
      ),
      child: announced,
    );
  }
}

/// Colours a burst draws with, taken from the look so every burst belongs
/// to its theme.
class RewardBurstPalette {
  const RewardBurstPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.ink,
    required this.glow,
    this.bloomHeart,
    this.bloomEdge,
  });

  factory RewardBurstPalette.from(ThemePreset? preset, ColorScheme colors) =>
      RewardBurstPalette(
        // Blue Rose throws blue roses; every other look keeps the red ones.
        bloomHeart: preset?.id == 'bluerose' ? const Color(0xFF1E4FD8) : null,
        bloomEdge: preset?.id == 'bluerose' ? preset?.jewel : null,
        primary: preset?.primary ?? colors.primary,
        secondary: preset?.secondary ?? colors.secondary,
        tertiary: preset?.tertiary ?? colors.tertiary,
        ink: preset?.ink ?? colors.onSurface,
        glow: preset != null && preset.swatch.length > 2
            ? preset.swatch[2]
            : colors.secondaryContainer,
      );

  final Color primary, secondary, tertiary, ink, glow;

  /// Colours of a thrown rose, heart and rim. Null for the classic red rose.
  final Color? bloomHeart, bloomEdge;
}

/// One particle in normalised units: [angle] and [speed] set where it flies,
/// [delay] and [life] when, the rest how it looks on the way.
class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.delay,
    required this.life,
    required this.sway,
    required this.phase,
    required this.tone,
    required this.kind,
  });

  final double angle, speed, size, spin, delay, life, sway, phase;
  final int tone, kind;
}

List<_Particle> _particles(RewardBurstStyle style, int seed) {
  final rnd = math.Random(seed ^ style.index);
  _Particle make({
    required int kind,
    double minSize = 4,
    double maxSize = 12,
    double minSpeed = 0.3,
    double maxSpeed = 1,
    double maxDelay = 0.12,
    double minLife = 0.6,
  }) => _Particle(
    angle: rnd.nextDouble() * math.pi * 2,
    speed: minSpeed + rnd.nextDouble() * (maxSpeed - minSpeed),
    size: minSize + rnd.nextDouble() * (maxSize - minSize),
    spin: (rnd.nextBool() ? 1 : -1) * (0.5 + rnd.nextDouble() * 2.5),
    delay: rnd.nextDouble() * maxDelay,
    life: minLife + rnd.nextDouble() * (0.98 - minLife),
    sway: 0.02 + rnd.nextDouble() * 0.06,
    phase: rnd.nextDouble() * math.pi * 2,
    tone: rnd.nextInt(4),
    kind: kind,
  );

  return switch (style) {
    RewardBurstStyle.snow => [
      for (var i = 0; i < 26; i++) make(kind: 0, minSize: 7, maxSize: 16),
      for (var i = 0; i < 40; i++)
        make(kind: 1, minSize: 1.5, maxSize: 3.5, maxDelay: 0.3),
    ],
    RewardBurstStyle.roses || RewardBurstStyle.lotus => [
      for (var i = 0; i < 9; i++)
        make(kind: 0, minSize: 18, maxSize: 30, minSpeed: 0.45),
      for (var i = 0; i < 44; i++)
        make(kind: 1, minSize: 9, maxSize: 18, maxDelay: 0.25),
      for (var i = 0; i < 8; i++) make(kind: 2, minSize: 10, maxSize: 16),
    ],
    RewardBurstStyle.gothic => [
      for (var i = 0; i < 16; i++)
        make(kind: 0, minSize: 18, maxSize: 34, minSpeed: 0.4, minLife: 0.75),
      for (var i = 0; i < 36; i++)
        make(kind: 1, minSize: 1.5, maxSize: 3.5, maxDelay: 0.4),
      for (var i = 0; i < 18; i++) make(kind: 2, minSize: 6, maxSize: 12),
    ],
    RewardBurstStyle.confetti => [
      for (var i = 0; i < 70; i++)
        make(kind: i % 3 == 0 ? 1 : 0, minSize: 5, maxSize: 10),
    ],
  };
}

/// Paints one frame of a reward burst. Everything radiates from [origin],
/// eases out, then drifts according to the style: snow floats down twinkling,
/// roses tumble under gravity, bats spiral outward while embers rise, and
/// confetti flutters down.
class RewardBurstPainter extends CustomPainter {
  RewardBurstPainter({
    required this.style,
    required this.progress,
    required this.palette,
    this.seed = 0,
    this.origin = Alignment.center,
  }) : _items = _particles(style, seed);

  final RewardBurstStyle style;
  final double progress;
  final RewardBurstPalette palette;
  final int seed;
  final Alignment origin;
  final List<_Particle> _items;

  static double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final center = origin.alongSize(size);
    final reach = size.shortestSide * 0.62;
    _scrim(canvas, size, center);
    _flash(canvas, center, reach);
    for (final p in _items) {
      final local = ((progress - p.delay) / p.life).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) {
        continue;
      }
      final fade = math.min(local * 8, 1) * (1 - _smooth(0.72, 1, local));
      final (at, heading) = _position(p, local, center, reach, size);
      switch (style) {
        case RewardBurstStyle.snow:
          _snowflake(canvas, p, at, local, fade);
        case RewardBurstStyle.roses:
          _rose(canvas, p, at, local, fade);
        case RewardBurstStyle.lotus:
          _lotus(canvas, p, at, local, fade);
        case RewardBurstStyle.gothic:
          _gothic(canvas, p, at, heading, local, fade);
        case RewardBurstStyle.confetti:
          _confetti(canvas, p, at, local, fade);
      }
    }
  }

  static double _smooth(double a, double b, double t) {
    final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  (Offset, double) _position(
    _Particle p,
    double local,
    Offset center,
    double reach,
    Size size,
  ) {
    final out = _ease(math.min(local * 1.6, 1)) * p.speed * reach;
    var angle = p.angle;
    var drop = 0.0;
    var swayX = math.sin(local * math.pi * 3 + p.phase) * p.sway * reach;
    switch (style) {
      case RewardBurstStyle.snow:
        drop = local * local * size.height * 0.32;
      case RewardBurstStyle.roses:
        drop = local * local * size.height * 0.55;
      case RewardBurstStyle.lotus:
        drop = local * local * size.height * 0.38;
      case RewardBurstStyle.gothic:
        if (p.kind == 0) {
          // Bats spiral outward and climb away.
          angle += p.spin.sign * local * 1.6;
          drop = -local * local * size.height * 0.2;
          swayX = 0;
        } else {
          // Embers and sparks rise like heat off a candle.
          drop = -local * size.height * 0.3;
        }
      case RewardBurstStyle.confetti:
        drop = local * local * size.height * 0.6;
    }
    final at =
        center +
        Offset(math.cos(angle), math.sin(angle)) * out +
        Offset(swayX, drop);
    return (at, angle);
  }

  void _scrim(Canvas canvas, Size size, Offset center) {
    // A soft dim that lets white snow and dark bats read on any ground,
    // fading in with the burst and out as it settles.
    final strength =
        _smooth(0, 0.12, progress) * (1 - _smooth(0.7, 1, progress));
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: origin,
          radius: 1.1,
          colors: [
            Colors.black.withValues(alpha: 0.34 * strength),
            Colors.black.withValues(alpha: 0.12 * strength),
          ],
        ).createShader(rect),
    );
  }

  void _flash(Canvas canvas, Offset center, double reach) {
    final t = _smooth(0, 0.35, progress);
    final alpha = (1 - t) * _smooth(0, 0.04, progress);
    if (alpha <= 0) {
      return;
    }
    switch (style) {
      case RewardBurstStyle.snow:
        // A frost ring blooming outward.
        canvas.drawCircle(
          center,
          reach * (0.1 + 0.9 * t),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * (1 - t) + 1
            ..color = Colors.white.withValues(alpha: 0.8 * alpha),
        );
        canvas.drawCircle(
          center,
          reach * (0.1 + 0.9 * t),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14 * (1 - t) + 2
            ..color = palette.glow.withValues(alpha: 0.35 * alpha),
        );
      case RewardBurstStyle.gothic:
        // A pale moon swelling behind the bats.
        final r = reach * (0.25 + 0.2 * t);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                palette.ink.withValues(alpha: 0.55 * alpha),
                palette.ink.withValues(alpha: 0.2 * alpha),
                palette.primary.withValues(alpha: 0),
              ],
              stops: const [0, 0.6, 1],
            ).createShader(Rect.fromCircle(center: center, radius: r)),
        );
      case RewardBurstStyle.roses:
      case RewardBurstStyle.lotus:
      case RewardBurstStyle.confetti:
        canvas.drawCircle(
          center,
          reach * (0.2 + 0.5 * t),
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    palette.secondary.withValues(alpha: 0.45 * alpha),
                    palette.secondary.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: center,
                    radius: reach * (0.2 + 0.5 * t),
                  ),
                ),
        );
    }
  }

  void _snowflake(
    Canvas canvas,
    _Particle p,
    Offset at,
    double local,
    double fade,
  ) {
    final twinkle = 0.65 + 0.35 * math.sin(local * 26 + p.phase);
    final alpha = (fade * twinkle).clamp(0.0, 1.0);
    final tint = [
      palette.glow,
      palette.secondary,
      palette.primary,
      Colors.white,
    ][p.tone];
    if (p.kind == 1) {
      canvas
        ..drawCircle(
          at,
          p.size * 1.8,
          Paint()..color = tint.withValues(alpha: 0.25 * alpha),
        )
        ..drawCircle(
          at,
          p.size,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      return;
    }
    final path = ThemeMotifs.snowflake(p.size, detail: p.size > 11 ? 2 : 1);
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(local * p.spin * math.pi * 0.6)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.4
          ..color = tint.withValues(alpha: 0.45 * alpha),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: alpha),
      )
      ..drawCircle(
        Offset.zero,
        p.size * 0.14,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      )
      ..restore();
  }

  void _rose(Canvas canvas, _Particle p, Offset at, double local, double fade) {
    final deepRose = palette.bloomHeart ?? const Color(0xFFB0123F);
    final blush = palette.bloomEdge ?? const Color(0xFFFF8FAB);
    final heart = Color.lerp(deepRose, palette.primary, 0.3)!;
    final edge = palette.bloomEdge == null
        ? Color.lerp(blush, palette.secondary, 0.4)!
        : blush;
    switch (p.kind) {
      case 0:
        ThemeMotifs.drawRose(
          canvas,
          at,
          p.size * (0.7 + 0.3 * _ease(math.min(local * 3, 1))),
          heart: heart,
          edge: edge,
          alpha: 0.95 * fade,
          twist: local * p.spin * math.pi,
          petals: 20,
        );
      case 1:
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(local * p.spin * math.pi * 2)
          ..scale(0.5 + 0.5 * math.cos(local * p.spin * 5).abs(), 1);
        ThemeMotifs.drawPetal(
          canvas,
          Offset.zero,
          p.size,
          0,
          [heart, edge, deepRose, blush][p.tone],
          0.92 * fade,
          vein: Colors.white,
        );
        canvas.restore();
      default:
        // A leaf: a slim sage-green petal shape.
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(local * p.spin * math.pi * 1.5)
          ..scale(0.55, 1);
        ThemeMotifs.drawPetal(
          canvas,
          Offset.zero,
          p.size,
          0,
          const Color(0xFF5E8A5F),
          0.85 * fade,
        );
        canvas.restore();
    }
  }

  void _lotus(
    Canvas canvas,
    _Particle p,
    Offset at,
    double local,
    double fade,
  ) {
    switch (p.kind) {
      case 0:
        // A bloom opening as it flies: it swells and turns slowly.
        ThemeMotifs.drawLotus(
          canvas,
          at,
          p.size * (0.75 + 0.45 * _ease(math.min(local * 3, 1))),
          heart: Color.lerp(palette.secondary, Colors.white, 0.45)!,
          edge: palette.primary,
          stamen: palette.tertiary,
          alpha: 0.95 * fade,
          twist: local * p.spin * math.pi * 0.5,
        );
      case 1:
        // A loose petal, turning over as it drifts.
        final color = [
          palette.primary,
          palette.secondary,
          Color.lerp(palette.primary, Colors.white, 0.5)!,
          palette.secondary,
        ][p.tone];
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(local * p.spin * math.pi * 2)
          ..scale(0.5 + 0.5 * math.cos(local * p.spin * 5).abs(), 1)
          ..translate(0, p.size * 0.6)
          ..drawPath(
            ThemeMotifs.lotusPetal(p.size * 1.2),
            Paint()..color = color.withValues(alpha: 0.9 * fade),
          )
          ..restore();
      default:
        // Gold pollen.
        canvas
          ..drawCircle(
            at,
            p.size * 0.42,
            Paint()..color = palette.tertiary.withValues(alpha: 0.18 * fade),
          )
          ..drawCircle(
            at,
            p.size * 0.14,
            Paint()..color = palette.tertiary.withValues(alpha: 0.95 * fade),
          );
    }
  }

  void _gothic(
    Canvas canvas,
    _Particle p,
    Offset at,
    double heading,
    double local,
    double fade,
  ) {
    switch (p.kind) {
      case 0:
        final flap = math.sin(local * 38 + p.phase);
        final path = ThemeMotifs.bat(p.size, flap: flap);
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(math.sin(heading) * 0.3 + p.spin * 0.05)
          ..drawPath(
            path,
            Paint()
              ..color = palette.primary.withValues(alpha: 0.5 * fade)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          )
          ..drawPath(
            path,
            Paint()..color = const Color(0xFF0A0610).withValues(alpha: fade),
          )
          ..drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9
              ..color = palette.primary.withValues(alpha: 0.85 * fade),
          )
          ..restore();
      case 1:
        // A crimson ember with a flickering glow.
        final flicker = 0.6 + 0.4 * math.sin(local * 30 + p.phase);
        final color = p.tone.isEven ? palette.primary : palette.tertiary;
        canvas
          ..drawCircle(
            at,
            p.size * 3,
            Paint()..color = color.withValues(alpha: 0.18 * fade * flicker),
          )
          ..drawCircle(
            at,
            p.size,
            Paint()
              ..color = Color.lerp(
                color,
                Colors.white,
                0.3,
              )!.withValues(alpha: fade * flicker),
          );
      default:
        // A candle spark: a short gold streak along its heading.
        final dir = Offset(math.cos(heading), math.sin(heading) - 0.6);
        canvas.drawLine(
          at,
          at - dir * p.size,
          Paint()
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..color = palette.tertiary.withValues(alpha: 0.9 * fade),
        );
    }
  }

  void _confetti(
    Canvas canvas,
    _Particle p,
    Offset at,
    double local,
    double fade,
  ) {
    final color = [
      palette.primary,
      palette.secondary,
      palette.tertiary,
      palette.glow,
    ][p.tone];
    final paint = Paint()..color = color.withValues(alpha: 0.95 * fade);
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(local * p.spin * math.pi * 2)
      ..scale(1, 0.25 + 0.75 * math.cos(local * p.spin * 6).abs());
    if (p.kind == 1) {
      canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RewardBurstPainter old) =>
      old.progress != progress || old.style != style;
}
