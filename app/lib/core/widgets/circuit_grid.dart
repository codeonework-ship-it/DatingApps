import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The grid the interface stands on.
///
/// A flat dark fill reads as absence — the screen looks switched off rather
/// than powered. A perspective grid with a charge running along it gives the
/// ground depth and a pulse, which is the whole difference between "dark
/// theme" and "cinematic".
///
/// Three rules keep it environment rather than decoration:
///
/// * It only draws on dark grounds. Over the light theme the same lines read
///   as a fax artefact.
/// * Lines are dim ([AppTheme.circuitLine] is ~10% alpha). Anything brighter
///   competes with the content sitting on top of it.
/// * The traces are seeded, not random, so the layout is stable across rebuilds
///   and reproducible in golden tests.
class CircuitGrid extends StatefulWidget {
  const CircuitGrid({super.key, this.animate = true, this.opacity = 1.0});

  /// When false the grid is painted static. Used for tests and for anyone who
  /// has asked the platform to reduce motion.
  final bool animate;
  final double opacity;

  @override
  State<CircuitGrid> createState() => _CircuitGridState();
}

class _CircuitGridState extends State<CircuitGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs once on arrival, then rests.
    //
    // This deliberately does not `repeat()`. An ambient loop is a permanent
    // repaint for the whole life of the screen — this codebase already tore
    // out a repeating shimmer controller for that reason — and it also means
    // the widget tree never settles, so every `pumpAndSettle` in the suite
    // times out.
    //
    // A single sweep is the better effect anyway: the grid energises as the
    // surface comes up, the way a HUD boots, and then holds. Motion that never
    // stops stops being read as motion.
    final wantsMotion = widget.animate && !AppTheme.reduceMotionOf(context);
    if (wantsMotion && _pulse.status == AnimationStatus.dismissed) {
      _pulse.forward();
    } else if (!wantsMotion) {
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            painter: _CircuitPainter(
              phase: _pulse.value,
              opacity: widget.opacity,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({required this.phase, required this.opacity});

  final double phase;
  final double opacity;

  static const int _columns = 7;
  static const int _rows = 11;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final cell = size.width / _columns;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.circuitLine.withValues(
        alpha: AppTheme.circuitLine.a * opacity,
      );

    // Verticals fade toward the horizon so the plane recedes instead of
    // sitting flat against the glass.
    for (var c = 0; c <= _columns; c++) {
      final x = c * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var r = 0; r <= _rows; r++) {
      final t = r / _rows;
      final y = size.height * math.pow(t, 1.35).toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // Charge running the seams. Each trace is offset by a fixed fraction so
    // they never pulse in unison, which would read as a flashing screen.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var i = 0; i < 4; i++) {
      final lane = ((i * 2) + 1).clamp(0, _columns).toDouble();
      final x = lane * cell;
      final travel = (phase + i * 0.25) % 1.0;
      final head = size.height * travel;
      final tail = head - size.height * 0.22;

      // Fade the charge out over the last third of the sweep so the grid is
      // left as a quiet lattice rather than four stranded streaks.
      final decay = (1 - math.max(0, (phase - 0.66) / 0.34)).clamp(0.0, 1.0);
      glow.color = (i.isEven ? AppTheme.arcGlow : AppTheme.armourGoldBright)
          .withValues(alpha: 0.5 * opacity * decay);
      canvas.drawLine(Offset(x, math.max(0, tail)), Offset(x, head), glow);

      final node = Paint()
        ..color = AppTheme.circuitNode.withValues(alpha: 0.85 * opacity * decay)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, head), 2.4, node);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.opacity != opacity;
}
