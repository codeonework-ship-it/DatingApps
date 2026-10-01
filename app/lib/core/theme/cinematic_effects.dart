import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cinematic_clock.dart';
import 'cinematic_motion.dart';
import 'theme_presets.dart';

/// A band of light that glides across a primary button every few seconds in
/// the cinematic looks, like a lamp passing over lacquer.
///
/// Nothing is drawn (and nothing repaints) for the everyday looks or under
/// reduced motion. Between sweeps the painter is not even asked to repaint:
/// the shared clock is gated so only the 1.1 s of each 7 s cycle when the
/// band is on the button costs frames. The sheen ignores pointers and
/// screen readers.
class CinematicSheen extends StatefulWidget {
  const CinematicSheen({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Off for disabled buttons.
  final bool enabled;

  /// Seconds between sweeps, and how long one sweep takes.
  static const double period = 7;
  static const double sweep = 1.1;

  @override
  State<CinematicSheen> createState() => _CinematicSheenState();
}

class _CinematicSheenState extends State<CinematicSheen>
    with CinematicClockSubscriber<CinematicSheen> {
  final _GatedClock _gate = _GatedClock(
    period: CinematicSheen.period,
    activeFor: CinematicSheen.sweep + 0.1,
  );
  bool _full = false;

  void _sync() {
    _full = CinematicLevel.of(context) == CinematicLevel.full;
    syncCinematicClock(wantsMotion: _full && widget.enabled);
    _gate.attach(cinematicClockLive ? CinematicClock.instance.time : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CinematicSheen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _gate.dispose();
    super.dispose();
  }

  // Painted behind the child: over the button's fill, under its label.
  // Always a CustomPaint (with no painter when idle) so the button's content
  // is never remounted when the sheen starts or stops.
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: cinematicClockLive
        ? _SheenPainter(
            clock: _gate,
            time: CinematicClock.instance.time,
            radius: widget.borderRadius,
          )
        : null,
    child: widget.child,
  );
}

/// Forwards clock ticks only while `t % period` is within the first
/// [activeFor] seconds (plus one tick after, so the last frame clears).
class _GatedClock extends ChangeNotifier {
  _GatedClock({required this.period, required this.activeFor});

  final double period;
  final double activeFor;
  ValueListenable<double>? _source;
  bool _wasActive = false;

  void attach(ValueListenable<double>? source) {
    if (identical(source, _source)) {
      return;
    }
    _source?.removeListener(_tick);
    _source = source;
    _source?.addListener(_tick);
  }

  void _tick() {
    final t = _source?.value ?? 0;
    final active = (t % period) < activeFor;
    if (active || _wasActive) {
      notifyListeners();
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    _source?.removeListener(_tick);
    super.dispose();
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.clock, required this.time, required this.radius})
    : super(repaint: clock);

  final Listenable clock;
  final ValueListenable<double> time;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final local = (time.value % CinematicSheen.period) / CinematicSheen.sweep;
    if (local <= 0 || local >= 1 || size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final e = Curves.easeInOut.transform(local);
    final band = size.width * 0.35;
    final x = -band + (size.width + band * 2) * e;
    canvas
      ..save()
      ..clipRRect(radius.toRRect(rect))
      ..translate(x, size.height / 2)
      ..rotate(-0.4);
    final shine = Rect.fromCenter(
      center: Offset.zero,
      width: band,
      height: size.height * 3,
    );
    canvas
      ..drawRect(
        shine,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.26 * math.sin(math.pi * local)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(shine),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.radius != radius;
}

/// A soft glow that breathes behind a live indicator ("here now", "live")
/// in the cinematic looks: one slow pulse every 2.4 s, never a blink.
///
/// Everyday looks get the child alone (no glow); reduced motion gets a
/// steady glow with no pulse.
class CinematicGlowPulse extends StatefulWidget {
  const CinematicGlowPulse({
    required this.child,
    this.color,
    this.radius = 14,
    super.key,
  });

  final Widget child;

  /// Glow colour; the theme's primary by default.
  final Color? color;

  /// How far the glow spreads beyond the child.
  final double radius;

  static const double period = 2.4;

  @override
  State<CinematicGlowPulse> createState() => _CinematicGlowPulseState();
}

class _CinematicGlowPulseState extends State<CinematicGlowPulse>
    with CinematicClockSubscriber<CinematicGlowPulse> {
  CinematicLevel _level = CinematicLevel.subtle;

  void _sync() {
    _level = CinematicLevel.of(context);
    syncCinematicClock(wantsMotion: _level == CinematicLevel.full);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CinematicGlowPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    // Everyday looks (and Calm) stay restrained: no glow at all. A
    // cinematic look under the platform's reduce-motion setting keeps a
    // steady glow.
    final look = CinematicLevel.forPreset(
      Theme.of(context).extension<ConnectPalette>()?.preset,
    );
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: look == CinematicLevel.full
          ? _GlowPainter(
              color: color,
              spread: widget.radius,
              time: cinematicClockLive ? CinematicClock.instance.time : null,
            )
          : null,
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.spread, this.time})
    : super(repaint: time);

  final Color color;
  final double spread;
  final ValueListenable<double>? time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time?.value;
    final pulse = t == null
        ? 0.5
        : 0.5 + 0.5 * math.sin(t * 2 * math.pi / CinematicGlowPulse.period);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 + spread * (0.7 + 0.3 * pulse);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18 + 0.22 * pulse),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.spread != spread || old.time != time;
}

/// Moves a full-bleed image against the scroll, so a hero photo seems to sit
/// a little deeper than the card that frames it.
///
/// The child is painted slightly enlarged and offset by up to [depth] of its
/// height as the card travels through the viewport; it never shows an edge.
/// The cinematic looks get the full depth, everyday looks a third of it,
/// and reduced motion (or no enclosing [Scrollable]) none.
class CinematicParallax extends StatelessWidget {
  const CinematicParallax({required this.child, this.depth = 0.08, super.key});

  final Widget child;

  /// Maximum travel as a fraction of the child's height (each way).
  final double depth;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final level = CinematicLevel.of(context);
    // Always a Flow (with no travel when still) so the image is never
    // remounted when motion settings change.
    final amount = scrollable == null
        ? 0.0
        : switch (level) {
            CinematicLevel.still => 0.0,
            CinematicLevel.subtle => depth / 3,
            CinematicLevel.full => depth,
          };
    return Flow(
      clipBehavior: Clip.hardEdge,
      delegate: _ParallaxDelegate(
        scrollable: scrollable,
        itemContext: context,
        depth: amount,
      ),
      children: [child],
    );
  }
}

class _ParallaxDelegate extends FlowDelegate {
  _ParallaxDelegate({
    required this.itemContext,
    required this.depth,
    this.scrollable,
  }) : super(repaint: scrollable?.position);

  final ScrollableState? scrollable;
  final BuildContext itemContext;
  final double depth;

  /// Where the item's centre sits in the viewport, -1 (top) to 1 (bottom).
  double _travel() {
    final scrollable = this.scrollable;
    if (scrollable == null || depth == 0) {
      return 0;
    }
    final viewport = scrollable.context.findRenderObject();
    final item = itemContext.findRenderObject();
    if (viewport is! RenderBox ||
        item is! RenderBox ||
        !viewport.hasSize ||
        !item.hasSize ||
        !item.attached) {
      return 0;
    }
    final centre = item.localToGlobal(
      item.size.center(Offset.zero),
      ancestor: viewport,
    );
    final vertical = scrollable.position.axis == Axis.vertical;
    final extent = vertical ? viewport.size.height : viewport.size.width;
    if (extent <= 0) {
      return 0;
    }
    final along = vertical ? centre.dy : centre.dx;
    return (along / extent * 2 - 1).clamp(-1.0, 1.0);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    if (depth == 0) {
      context.paintChild(0);
      return;
    }
    final travel = _travel();
    final scale = 1 + depth * 2;
    final vertical = scrollable?.position.axis != Axis.horizontal;
    final shift = -travel * depth * (vertical ? size.height : size.width);
    final transform = Matrix4.identity()
      ..translateByDouble(
        size.width / 2 + (vertical ? 0 : shift),
        size.height / 2 + (vertical ? shift : 0),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
    context.paintChild(0, transform: transform);
  }

  @override
  bool shouldRepaint(_ParallaxDelegate old) =>
      old.scrollable != scrollable ||
      old.itemContext != itemContext ||
      old.depth != depth;
}

/// Plays a once-per-open staggered entrance for the [CinematicEntrance]
/// children below it: each fades in and rises 12 pt, a beat after the one
/// before. Reduced motion shows everything at once.
class CinematicStaggerScope extends StatefulWidget {
  const CinematicStaggerScope({required this.child, super.key});

  final Widget child;

  @override
  State<CinematicStaggerScope> createState() => _CinematicStaggerScopeState();
}

class _CinematicStaggerScopeState extends State<CinematicStaggerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (CinematicLevel.of(context) == CinematicLevel.still) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _StaggerScope(animation: _entrance, child: widget.child);
}

class _StaggerScope extends InheritedWidget {
  const _StaggerScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_StaggerScope old) => old.animation != animation;
}

/// One item in a [CinematicStaggerScope]. Without a scope it is just its
/// child.
class CinematicEntrance extends StatelessWidget {
  const CinematicEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StaggerScope>();
    if (scope == null) {
      return child;
    }
    final start = math.min(index * 0.07, 0.45);
    final eased = scope.animation.drive(
      CurveTween(
        curve: Interval(
          start,
          math.min(start + 0.55, 1),
          curve: CinematicMotion.settle,
        ),
      ),
    );
    return FadeTransition(
      opacity: eased,
      child: AnimatedBuilder(
        animation: eased,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - eased.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// A single soft bloom of light from [origin] for a big moment (a level-up,
/// Cover of the Week): it swells for a fifth of [progress], then falls away.
/// One bloom per moment, at most 22% white, so it never reads as a flash
/// sequence.
class CinematicBloomPainter extends CustomPainter {
  CinematicBloomPainter({
    required this.progress,
    required this.color,
    this.origin = Alignment.center,
  });

  final double progress;
  final Color color;
  final Alignment origin;

  /// Bloom strength at [progress]: 0 at the ends, one peak at 0.08.
  static double strengthAt(double progress) {
    if (progress <= 0 || progress >= 0.5) {
      return 0;
    }
    if (progress < 0.08) {
      return Curves.easeOut.transform(progress / 0.08);
    }
    return 1 - Curves.easeIn.transform((progress - 0.08) / 0.42);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = strengthAt(progress);
    if (s <= 0 || size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: origin,
          radius: 0.9 + 0.5 * progress,
          colors: [
            Colors.white.withValues(alpha: 0.22 * s),
            color.withValues(alpha: 0.16 * s),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(CinematicBloomPainter old) =>
      old.progress != progress || old.color != color || old.origin != origin;
}
