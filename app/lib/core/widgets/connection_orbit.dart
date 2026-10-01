import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The two intersecting paths are Afterglow's connection motif.
/// Painted locally, deterministic, and intentionally static behind content.
class ConnectionOrbit extends StatelessWidget {
  const ConnectionOrbit({super.key, this.opacity = 1});
  final double opacity;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: CustomPaint(painter: _OrbitPainter(opacity), size: Size.infinite),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.opacity);
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    final unit = math.min(size.width, size.height);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i == 0 ? -.62 : .62);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: unit * .87,
        height: unit * .53,
      );
      line.shader = LinearGradient(
        colors: [
          AppTheme.irisPale.withValues(alpha: .85 * opacity),
          AppTheme.irisBright.withValues(alpha: .12 * opacity),
          AppTheme.marigoldHighlight.withValues(alpha: .8 * opacity),
        ],
      ).createShader(rect);
      canvas.drawOval(rect, line);
      canvas.restore();
    }
    final dot = Paint()..color = AppTheme.irisPale.withValues(alpha: opacity);
    canvas.drawCircle(center + Offset(unit * .35, -unit * .25), 4, dot);
    canvas.drawCircle(center + Offset(-unit * .35, unit * .25), 3, dot);
    final star = Path()
      ..moveTo(center.dx, center.dy - 13)
      ..quadraticBezierTo(
        center.dx + 3,
        center.dy - 3,
        center.dx + 13,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + 3,
        center.dy + 3,
        center.dx,
        center.dy + 13,
      )
      ..quadraticBezierTo(
        center.dx - 3,
        center.dy + 3,
        center.dx - 13,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - 3,
        center.dy - 3,
        center.dx,
        center.dy - 13,
      );
    canvas.drawPath(star, dot);
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
