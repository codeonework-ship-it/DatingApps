import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small vector motifs shared by the theme atmosphere scenes and the reward
/// bursts: a six-armed snow crystal, a bat in flight, a rose petal and a full
/// rose bloom. Every path is centred on the origin so callers translate,
/// rotate and scale the canvas around it.
abstract final class ThemeMotifs {
  /// A six-armed snow crystal of [radius]. [detail] 0 is a plain asterisk,
  /// 1 adds one pair of side branches per arm, 2 adds a second, shorter pair
  /// near the tip (the classic stellar dendrite). Stroke it, do not fill it.
  static Path snowflake(double radius, {int detail = 2}) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      path
        ..moveTo(0, 0)
        ..lineTo(dir.dx * radius, dir.dy * radius);
      final branches = <(double, double)>[
        if (detail >= 1) (0.42, 0.3),
        if (detail >= 2) (0.7, 0.2),
      ];
      for (final (at, length) in branches) {
        final base = dir * (radius * at);
        for (final side in const [-1, 1]) {
          final b = a + side * math.pi / 3;
          path
            ..moveTo(base.dx, base.dy)
            ..lineTo(
              base.dx + math.cos(b) * radius * length,
              base.dy + math.sin(b) * radius * length,
            );
        }
      }
    }
    return path;
  }

  /// A bat seen from below, wings spread across [span]. [flap] runs from -1
  /// (wings swept down) to 1 (wings raised); animating it with a sine makes
  /// the bat beat its wings. Fill it.
  static Path bat(double span, {double flap = 0}) {
    final w = span / 2;
    final lift = flap.clamp(-1.0, 1.0) * w * 0.42;
    // Right half, from the crown down the scalloped trailing edge to the
    // tail, closed along the centre line. The left half is its mirror.
    final half = Path()
      ..moveTo(0, -w * 0.1)
      ..lineTo(w * 0.05, -w * 0.22)
      ..lineTo(w * 0.09, -w * 0.08)
      ..quadraticBezierTo(w * 0.45, -w * 0.2 - lift, w, -w * 0.06 - lift)
      ..quadraticBezierTo(
        w * 0.84,
        w * 0.02 - lift * 0.7,
        w * 0.78,
        w * 0.16 - lift * 0.55,
      )
      ..quadraticBezierTo(
        w * 0.64,
        w * 0.07 - lift * 0.45,
        w * 0.5,
        w * 0.2 - lift * 0.35,
      )
      ..quadraticBezierTo(
        w * 0.36,
        w * 0.1 - lift * 0.25,
        w * 0.22,
        w * 0.22 - lift * 0.12,
      )
      ..quadraticBezierTo(w * 0.12, w * 0.12, w * 0.06, w * 0.2)
      ..lineTo(0, w * 0.3)
      ..close();
    final mirror = Matrix4.diagonal3Values(-1, 1, 1).storage;
    return Path()
      ..addPath(half, Offset.zero)
      ..addPath(half.transform(mirror), Offset.zero);
  }

  /// One petal: a soft teardrop with a notched tip, pointing up. [length] is
  /// tip to base. The same shape the rose rain and the Rose scene use.
  static Path petal(double length) {
    final w = length * 0.62;
    final h = length / 2;
    return Path()
      ..moveTo(0, h)
      ..cubicTo(w * 0.9, h * 0.55, w * 0.75, -h * 0.85, w * 0.12, -h)
      ..quadraticBezierTo(0, -h * 0.82, -w * 0.12, -h)
      ..cubicTo(-w * 0.75, -h * 0.85, -w * 0.9, h * 0.55, 0, h)
      ..close();
  }

  /// Paints one shaded petal at [at], turned by [angle].
  static void drawPetal(
    Canvas canvas,
    Offset at,
    double length,
    double angle,
    Color color,
    double alpha, {
    Color? vein,
  }) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(angle);
    final bounds = Rect.fromCenter(
      center: Offset.zero,
      width: length,
      height: length,
    );
    canvas
      ..drawPath(
        petal(length),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.6),
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.5),
            ],
          ).createShader(bounds),
      )
      ..drawLine(
        Offset(0, length * 0.38),
        Offset(0, -length * 0.25),
        Paint()
          ..color = (vein ?? color).withValues(alpha: alpha * 0.55)
          ..strokeWidth = 0.8,
      )
      ..restore();
  }

  /// One water-lily petal: a slim pointed blade with its base on the origin
  /// and its tip [length] straight up.
  static Path lotusPetal(double length) {
    final w = length * 0.3;
    return Path()
      ..moveTo(0, 0)
      ..cubicTo(w, -length * 0.22, w * 0.95, -length * 0.68, 0, -length)
      ..cubicTo(-w * 0.95, -length * 0.68, -w, -length * 0.22, 0, 0)
      ..close();
  }

  /// A blue lotus seen from above: three rings of pointed petals, [edge] at
  /// the rim deepening to [heart] at the centre, around a [stamen] crown.
  /// [twist] turns the whole bloom.
  static void drawLotus(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color heart,
    required Color edge,
    required Color stamen,
    double alpha = 1,
    double twist = 0,
  }) {
    // (petals, length as a share of the radius, turn in petal widths)
    const rings = [(14, 1.0, 0.0), (11, 0.74, 0.5), (8, 0.5, 0.0)];
    for (var ring = 0; ring < rings.length; ring++) {
      final (count, share, turn) = rings[ring];
      final length = radius * share;
      final color = Color.lerp(edge, heart, ring / (rings.length - 1))!;
      final petal = lotusPetal(length);
      final bounds = Rect.fromLTRB(-length * 0.3, -length, length * 0.3, 0);
      // Translucent at the base, full at the tip: petals overlap like silk.
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withValues(alpha: (alpha * 0.3).clamp(0.0, 1.0)),
            color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          ],
        ).createShader(bounds);
      final vein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, radius * 0.012)
        ..color = Color.lerp(
          color,
          Colors.white,
          0.5,
        )!.withValues(alpha: (alpha * 0.55).clamp(0.0, 1.0));
      for (var k = 0; k < count; k++) {
        canvas
          ..save()
          ..translate(center.dx, center.dy)
          ..rotate(twist + (k + turn) * 2 * math.pi / count)
          ..drawPath(petal, fill)
          ..drawPath(petal, vein)
          ..restore();
      }
    }
    final gold = Paint()
      ..color = stamen.withValues(alpha: (alpha * 0.95).clamp(0.0, 1.0));
    canvas.drawCircle(center, radius * 0.12, gold);
    for (var k = 0; k < 12; k++) {
      final a = twist + k * math.pi / 6;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius * 0.19,
        math.max(0.8, radius * 0.028),
        gold,
      );
    }
  }

  /// A full rose bloom: petals spiralling out on the golden angle, darker and
  /// tighter at the heart ([heart]) and opening to [edge] at the rim.
  /// [twist] turns the whole bloom, so a spinning rose is one parameter.
  static void drawRose(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color heart,
    required Color edge,
    double alpha = 1,
    double twist = 0,
    int petals = 26,
  }) {
    const golden = 2.399963;
    for (var k = petals; k >= 0; k--) {
      final t = k / petals;
      final angle = k * golden + twist;
      final distance = radius * 0.62 * math.sqrt(t);
      final at = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      drawPetal(
        canvas,
        at,
        radius * (0.32 + 0.55 * t),
        angle + math.pi / 2,
        Color.lerp(heart, edge, t)!,
        (alpha * (1.1 - t * 0.45)).clamp(0.0, 1.0),
        vein: heart,
      );
    }
    // The rose's heart: a tight, darker spiral of furled petals.
    final swirl = Path();
    for (var i = 0; i <= 24; i++) {
      final a = twist + i / 24 * math.pi * 3;
      final r = radius * 0.04 + radius * 0.16 * i / 24;
      final at = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? swirl.moveTo(at.dx, at.dy) : swirl.lineTo(at.dx, at.dy);
    }
    canvas
      ..drawCircle(
        center,
        radius * 0.2,
        Paint()..color = heart.withValues(alpha: (alpha * 0.9).clamp(0, 1)),
      )
      ..drawPath(
        swirl,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1, radius * 0.05)
          ..color = Color.lerp(
            heart,
            Colors.black,
            0.4,
          )!.withValues(alpha: (alpha * 0.8).clamp(0, 1)),
      );
  }
}
