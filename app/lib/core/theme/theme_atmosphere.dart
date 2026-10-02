import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'cinematic_clock.dart';
import 'cinematic_motion.dart';
import 'theme_motifs.dart';
import 'theme_presets.dart';

/// Atmosphere painted behind every post-login screen for a themed preset:
/// the thing that makes a look feel like a film set rather than a palette.
///
/// Each preset gets its own scene in three layers:
///
/// * a **back plate** (blooms, moon, skyline, rose window...) recorded once
///   per size into a cached [ui.Picture],
/// * a **motion layer** (embers, snowfall, drifting petals, star drift,
///   scrolling neon floor, flickering candles...) painted from the shared
///   [CinematicClock] at 30 frames a second, and
/// * a **front plate** (snow drifts, scanlines, vignette) also cached, with
///   a light film grain on the dark looks.
///
/// Everything is deterministic (seeded), low alpha so content stays
/// readable, wrapped in [IgnorePointer] and [ExcludeSemantics] so it can
/// never take a tap or reach a screen reader, and isolated in a
/// [RepaintBoundary] so a moving scene never repaints the page over it.
///
/// Motion stops (the scene holds its first frame) when the platform asks
/// for reduced motion, when the subtree's [TickerMode] is off (a covered
/// route or a hidden tab), when [ambient] is false (small previews) and
/// when the app is in the background. The Calm look paints nothing.
class ThemeAtmosphere extends StatefulWidget {
  const ThemeAtmosphere({
    required this.preset,
    this.ambient = true,
    this.film = true,
    super.key,
  });

  final ThemePreset preset;

  /// Whether the scene may move. Off for small, numerous previews such as
  /// the theme picker's chips.
  final bool ambient;

  /// Whether the film layer (vignette and grain) is painted.
  final bool film;

  @override
  State<ThemeAtmosphere> createState() => _ThemeAtmosphereState();
}

class _ThemeAtmosphereState extends State<ThemeAtmosphere>
    with CinematicClockSubscriber<ThemeAtmosphere> {
  void _sync() => syncCinematicClock(
    wantsMotion:
        widget.ambient &&
        !widget.preset.reducedMotion &&
        !AppTheme.reduceMotionOf(context),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ThemeAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ThemeAtmospherePainter(
            preset: widget.preset,
            clock: cinematicClockLive ? CinematicClock.instance.time : null,
            film: widget.film,
          ),
          isComplex: true,
          willChange: cinematicClockLive,
          size: Size.infinite,
        ),
      ),
    ),
  );
}

/// Paints one frame of a preset's scene. With a [clock] it repaints on each
/// ambient frame; without one it paints the still frame at [time].
class ThemeAtmospherePainter extends CustomPainter {
  ThemeAtmospherePainter({
    required this.preset,
    this.clock,
    this.time = 0,
    this.film = true,
  }) : super(repaint: clock);

  final ThemePreset preset;
  final ValueListenable<double>? clock;
  final double time;
  final bool film;

  /// Presets whose scene has its own animated motion layer.
  static const Set<String> animatedScenes = {
    'forge',
    'neongrid',
    'crimsonalloy',
    'circuit',
    'deepfield',
    'love',
    'rose',
    'bluerose',
    'bluelotus',
    'petal',
    'snow',
    'gothic',
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (preset.reducedMotion ||
        size.isEmpty ||
        !size.width.isFinite ||
        !size.height.isFinite) {
      return;
    }
    final t = clock?.value ?? time;
    final scene = _Scene(preset, size);
    canvas.drawPicture(
      _PictureCache.get('back|${preset.id}', size, scene.back),
    );
    scene.motion(canvas, t);
    canvas.drawPicture(
      _PictureCache.get(
        'front|${preset.id}|$film',
        size,
        (c) => scene.front(c, film: film),
      ),
    );
    scene.overlay(canvas, t);
    if (film && scene.grainy) {
      scene.grain(canvas, t);
    }
  }

  @override
  bool shouldRepaint(ThemeAtmospherePainter old) =>
      old.preset.id != preset.id ||
      old.clock != clock ||
      old.time != time ||
      old.film != film;
}

/// A small least-recently-used cache of recorded static layers, keyed by
/// layer and size. Recording a back plate costs a few hundred draw calls;
/// replaying it is one.
abstract final class _PictureCache {
  static const int _capacity = 40;
  static final LinkedHashMap<String, ui.Picture> _pictures =
      LinkedHashMap<String, ui.Picture>();

  static ui.Picture get(String layer, Size size, void Function(Canvas) draw) {
    final key = '$layer|${size.width.round()}x${size.height.round()}';
    final hit = _pictures.remove(key);
    if (hit != null) {
      _pictures[key] = hit;
      return hit;
    }
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder, Offset.zero & size));
    final picture = recorder.endRecording();
    _pictures[key] = picture;
    while (_pictures.length > _capacity) {
      _pictures.remove(_pictures.keys.first);
    }
    return picture;
  }
}

/// One deterministic particle in normalised units.
class _Mote {
  _Mote(math.Random r)
    : x = r.nextDouble(),
      y = r.nextDouble(),
      speed = r.nextDouble(),
      size = r.nextDouble(),
      phase = r.nextDouble() * math.pi * 2,
      sway = r.nextDouble(),
      tone = r.nextInt(4);

  final double x, y, speed, size, phase, sway;
  final int tone;
}

final Map<int, List<_Mote>> _moteCache = <int, List<_Mote>>{};

List<_Mote> _motes(int seed, int count) =>
    _moteCache.putIfAbsent(seed * 1000 + count, () {
      final r = math.Random(seed);
      return List<_Mote>.generate(count, (_) => _Mote(r));
    });

double _loop(double v) => v - v.floorToDouble();

/// 0..1 breathing at [period] seconds.
double _wave(double t, double period, [double phase = 0]) =>
    0.5 + 0.5 * math.sin(t * 2 * math.pi / period + phase);

final Path _unitPetal = ThemeMotifs.petal(1);
final Map<int, Path> _flakePaths = <int, Path>{};

Path _flake(double radius, int detail) => _flakePaths.putIfAbsent(
  (radius * 2).round() * 4 + detail,
  () => ThemeMotifs.snowflake((radius * 2).round() / 2, detail: detail),
);

class _Trace {
  const _Trace(this.points, this.alpha);
  final List<Offset> points;
  final double alpha;

  Offset at(double fraction) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    if (total == 0) {
      return points.first;
    }
    var remaining = fraction.clamp(0.0, 1.0) * total;
    for (var i = 1; i < points.length; i++) {
      final seg = (points[i] - points[i - 1]).distance;
      if (remaining <= seg && seg > 0) {
        return Offset.lerp(points[i - 1], points[i], remaining / seg)!;
      }
      remaining -= seg;
    }
    return points.last;
  }
}

final Map<String, List<_Trace>> _traceCache = <String, List<_Trace>>{};

class _Scene {
  _Scene(this.p, this.size) : w = size.width, h = size.height;

  final ThemePreset p;
  final Size size;
  final double w;
  final double h;

  /// Dark cinematic looks get film grain on the ground; the light looks
  /// stay clean.
  bool get grainy =>
      p.isDark && ThemeAtmospherePainter.animatedScenes.contains(p.id);

  // ---------------------------------------------------------------------------
  // Layers
  // ---------------------------------------------------------------------------

  void back(Canvas c) {
    switch (p.id) {
      case 'neongrid':
        _neonGridBack(c);
      case 'forge':
        _forgeBack(c);
      case 'crimsonalloy':
        _crimsonBack(c);
      case 'circuit':
        _circuitBack(c);
      case 'deepfield':
        _deepFieldBack(c);
      case 'love':
        _loveBack(c);
      case 'rose':
        _roseBack(c);
      case 'bluerose':
        _blueRoseBack(c);
      case 'bluelotus':
        _lotusBack(c);
      case 'petal':
        _petalBack(c);
      case 'snow':
        _snowBack(c);
      case 'gothic':
        _gothicBack(c);
      default:
        _blooms(c);
    }
  }

  void motion(Canvas c, double t) {
    switch (p.id) {
      case 'neongrid':
        _neonGridMotion(c, t);
      case 'forge':
        _forgeMotion(c, t);
      case 'crimsonalloy':
        _crimsonMotion(c, t);
      case 'circuit':
        _circuitMotion(c, t);
      case 'deepfield':
        _deepFieldMotion(c, t);
      case 'love':
        _loveMotion(c, t);
      case 'rose':
        _roseMotion(c, t);
      case 'bluerose':
        _blueRoseMotion(c, t);
      case 'bluelotus':
        _lotusMotion(c, t);
      case 'petal':
        _petalMotion(c, t);
      case 'snow':
        _snowMotion(c, t);
      case 'gothic':
        _gothicMotion(c, t);
      default:
        _bloom(
          c,
          Offset(w * 1.05, -h * 0.05),
          w * 0.6,
          p.primary,
          alpha: 0.08 * _wave(t, 8),
        );
    }
  }

  void front(Canvas c, {required bool film}) {
    switch (p.id) {
      case 'neongrid':
        _scanlines(c, 0.28);
      case 'circuit':
        _scanlines(c, 0.2);
      case 'snow':
        _drifts(c);
    }
    if (film && !ThemePresets.isEveryday(p)) {
      _vignette(c);
    }
  }

  void overlay(Canvas c, double t) {
    switch (p.id) {
      case 'neongrid':
        _scanBand(c, t, p.primary, alpha: 0.05, period: 7);
      case 'circuit':
        _scanBand(c, t, p.primary, alpha: 0.035, period: 9);
      case 'snow':
        _driftGlints(c, t);
    }
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  void _bloom(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double alpha = 0.35,
  }) {
    if (alpha <= 0 || radius <= 0) {
      return;
    }
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.4, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _blooms(Canvas canvas) {
    _bloom(
      canvas,
      Offset(w * 1.05, -h * 0.05),
      w * 0.6,
      p.primary,
      alpha: 0.28,
    );
    _bloom(
      canvas,
      Offset(-w * 0.15, h * 1.05),
      w * 0.55,
      p.secondary,
      alpha: 0.24,
    );
  }

  /// Darkened edges that pull the eye to the middle of the frame. Dark looks
  /// fall to black; light looks only breathe a little of their own accent in
  /// at the corners (grey would read as dirt on a pale ground).
  void _vignette(Canvas c) {
    final rect = Offset.zero & size;
    final edge = p.isDark
        ? Colors.black.withValues(alpha: 0.42)
        : p.primary.withValues(alpha: 0.05);
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.25,
          colors: [edge.withValues(alpha: 0), edge],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  /// Fine film grain: one cached field of light and dark specks, re-seated
  /// twelve times a second (a film gate rate) by offsetting it.
  void grain(Canvas c, double t) {
    const margin = 64.0;
    final field = _PictureCache.get('grain', Size(w + margin, h + margin), (g) {
      final count = ((w * h) / 260).clamp(300, 3200).toInt();
      final rnd = math.Random(4242);
      Float32List points() {
        final list = Float32List(count * 2);
        for (var i = 0; i < count; i++) {
          list[i * 2] = rnd.nextDouble() * (w + margin);
          list[i * 2 + 1] = rnd.nextDouble() * (h + margin);
        }
        return list;
      }

      g
        ..drawRawPoints(
          ui.PointMode.points,
          points(),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.05)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        )
        ..drawRawPoints(
          ui.PointMode.points,
          points(),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.08)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
    });
    final frame = (t * 12).floor();
    final dx = -((frame * 37) % margin.toInt()).toDouble();
    final dy = -((frame * 53) % margin.toInt()).toDouble();
    c
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(dx, dy)
      ..drawPicture(field)
      ..restore();
  }

  /// A soft diagonal band of light crossing the frame once every [period]
  /// seconds, taking [length] seconds: the sheen of a lamp passing over
  /// chrome or lacquer.
  void _sweep(
    Canvas c,
    double t, {
    required double period,
    required double length,
    required Color color,
    required double alpha,
    double angle = -0.35,
  }) {
    final local = (t % period) / length;
    if (local <= 0 || local >= 1) {
      return;
    }
    final e = Curves.easeInOut.transform(local);
    final band = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.28,
      height: h * 1.8,
    );
    c
      ..save()
      ..translate(-w * 0.4 + w * 1.8 * e, h / 2)
      ..rotate(angle)
      ..drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: alpha * math.sin(math.pi * local)),
              color.withValues(alpha: 0),
            ],
          ).createShader(band),
      )
      ..restore();
  }

  /// Sparks rising and fading, swaying as they go.
  void _embers(
    Canvas c,
    double t, {
    required int seed,
    required int count,
    required Color cool,
    required Color hot,
    double left = 0,
    double right = 1,
    double from = 1.04,
    double to = -0.06,
    double rate = 1,
  }) {
    final paint = Paint();
    for (final m in _motes(seed, count)) {
      final speed = (0.025 + m.speed * 0.05) * rate;
      final q = _loop(m.y + t * speed);
      final y = h * (from + (to - from) * q);
      final x =
          w * (left + (right - left) * m.x) +
          w * 0.03 * (0.5 + m.sway) * math.sin(t * (0.6 + m.sway) + m.phase);
      final life = math.sin(math.pi * q);
      final r = 0.8 + m.size * 1.8;
      final color = Color.lerp(cool, hot, m.size)!;
      paint.color = color.withValues(alpha: 0.16 * life);
      c.drawCircle(Offset(x, y), r * 3, paint);
      paint.color = color.withValues(alpha: 0.75 * life);
      c.drawCircle(Offset(x, y), r, paint);
    }
  }

  /// A drifting petal (or leaf) that turns over as it falls: the horizontal
  /// squash fakes the petal rotating in depth.
  void _fallingPetals(
    Canvas c,
    double t, {
    required int seed,
    required int count,
    required List<Color> colors,
    required double minLength,
    required double maxLength,
    required double alpha,
    double drift = 0.18,
    Color? leaf,
  }) {
    final shaders = <Color, Shader>{};
    Shader shaderFor(Color color) => shaders.putIfAbsent(
      color,
      () => RadialGradient(
        center: const Alignment(0, 0.6),
        colors: [color, color.withValues(alpha: 0.45)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: 1, height: 1)),
    );
    final paint = Paint();
    var i = 0;
    for (final m in _motes(seed, count)) {
      final isLeaf = leaf != null && i % 6 == 0;
      i++;
      final speed = 0.018 + m.speed * 0.03;
      final q = _loop(m.y + t * speed);
      final y = h * (-0.06 + q * 1.12);
      final x =
          w * _loop(m.x + q * drift) + w * 0.025 * math.sin(t * 0.9 + m.phase);
      final length = isLeaf
          ? minLength + 4 + m.size * 10
          : minLength + m.size * (maxLength - minLength);
      final angle = -0.6 + m.sway * 1.4 + 0.5 * math.sin(t * 0.7 + m.phase);
      final turn = math.cos(t * (0.8 + m.speed) + m.phase);
      final color = isLeaf ? leaf : colors[m.tone % colors.length];
      paint
        ..shader = shaderFor(color)
        ..color = Colors.black.withValues(
          alpha: isLeaf ? 0.34 : alpha + 0.12 * m.sway,
        );
      c
        ..save()
        ..translate(x, y)
        ..rotate(angle)
        ..scale(length * (0.3 + 0.7 * turn.abs()), length)
        ..drawPath(_unitPetal, paint)
        ..restore();
    }
  }

  void _twinkles(
    Canvas c,
    double t, {
    required int seed,
    required int count,
    required Color color,
    double alpha = 0.4,
  }) {
    final paint = Paint();
    for (final m in _motes(seed, count)) {
      paint.color = color.withValues(
        alpha: alpha * (0.25 + 0.75 * _wave(t, 2.2 + m.speed * 2.4, m.phase)),
      );
      c.drawCircle(Offset(m.x * w, m.y * h), 0.8 + m.size * 1.4, paint);
    }
  }

  void _scanlines(Canvas c, double alpha) {
    final rect = Offset.zero & size;
    final line = Colors.black.withValues(alpha: alpha);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            line,
            line,
            line.withValues(alpha: 0),
            line.withValues(alpha: 0),
          ],
          stops: const [0, 0.34, 0.34, 1],
          tileMode: TileMode.repeated,
        ).createShader(const Rect.fromLTWH(0, 0, 1, 3)),
    );
  }

  /// A soft bright band rolling down the frame, like a CRT refresh.
  void _scanBand(
    Canvas c,
    double t,
    Color color, {
    required double alpha,
    required double period,
  }) {
    final y = -h * 0.1 + h * 1.2 * ((t % period) / period);
    final band = Rect.fromLTWH(0, y - 40, w, 80);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  // ---------------------------------------------------------------------------
  // Neon Grid: a perspective floor of light-lines rolling toward the camera
  // under an amber sun, a flickering horizon and CRT scanlines.
  // ---------------------------------------------------------------------------

  double get _horizon => h * 0.58;

  void _neonGridBack(Canvas c) {
    _bloom(c, Offset(w * 0.5, h * 0.98), w * 0.8, p.secondary, alpha: 0.22);
    final line = Paint()
      ..color = p.primary.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final vanishing = Offset(w / 2, _horizon - h * 0.08);
    for (var i = -8; i <= 8; i++) {
      final x = w / 2 + i * w * 0.16;
      c.drawLine(Offset(x, h), vanishing, line);
    }
    _bloom(c, Offset(w * 0.9, h * 0.08), w * 0.45, p.primary, alpha: 0.18);
  }

  /// Neon tubes stutter: two short dips in a third of a second, once every
  /// 5.3 seconds. Never more than two changes a second.
  static double neonFlicker(double t) {
    final cycle = t % 5.3;
    if (cycle > 3.6 && cycle < 3.72) {
      return 0.5;
    }
    if (cycle > 3.86 && cycle < 3.94) {
      return 0.72;
    }
    return 1;
  }

  void _neonGridMotion(Canvas c, double t) {
    final line = Paint()..strokeWidth = 1;
    final roll = _loop(t * 0.16);
    for (var i = 0; i < 14; i++) {
      final f = (i + roll) / 14;
      final y = _horizon + (h - _horizon) * f * f;
      line.color = p.primary.withValues(alpha: 0.05 + 0.18 * f);
      c.drawLine(Offset(0, y), Offset(w, y), line);
    }
    final glowRect = Rect.fromLTWH(0, _horizon - 24, w, 48);
    c.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.primary.withValues(alpha: 0),
            p.primary.withValues(alpha: 0.28 * neonFlicker(t)),
            p.primary.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );
    // The sun breathes.
    _bloom(
      c,
      Offset(w * 0.9, h * 0.08),
      w * 0.3,
      p.secondary,
      alpha: 0.06 * _wave(t, 7),
    );
  }

  // ---------------------------------------------------------------------------
  // Forge: brushed chrome streaks, a breathing furnace, embers rising, a lamp
  // passing over the metal and, rarely, an arc across the plate.
  // ---------------------------------------------------------------------------

  Offset get _plate => Offset(w * 0.86, h * 0.16);

  void _forgeBack(Canvas c) {
    final streak = Paint()..strokeWidth = 1;
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final y = rnd.nextDouble() * h;
      final sw = w * (0.3 + rnd.nextDouble() * 0.9);
      final x = rnd.nextDouble() * w - sw * 0.5;
      streak.shader = LinearGradient(
        colors: [
          p.tertiary.withValues(alpha: 0),
          p.tertiary.withValues(alpha: 0.05 + rnd.nextDouble() * 0.08),
          p.tertiary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(x, y, sw, 2));
      c.drawLine(Offset(x, y), Offset(x + sw, y - h * 0.08), streak);
    }
    _bloom(c, Offset(w * 0.12, h * 0.1), w * 0.55, p.primary, alpha: 0.28);
    _bloom(c, Offset(w * 0.95, h * 0.9), w * 0.65, p.secondary, alpha: 0.3);
    c.drawPath(
      _hex(_plate, w * 0.16),
      Paint()
        ..color = p.tertiary.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Path _hex(Offset center, double r) {
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i - math.pi / 6;
      final pt = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
    }
    return hex..close();
  }

  void _forgeMotion(Canvas c, double t) {
    _bloom(
      c,
      Offset(w * 0.12, h * 0.1),
      w * 0.5,
      p.primary,
      alpha: 0.1 * _wave(t, 6),
    );
    _sweep(c, t, period: 9, length: 1.8, color: p.tertiary, alpha: 0.09);
    _embers(
      c,
      t,
      seed: 71,
      count: 26,
      cool: p.primary,
      hot: Color.lerp(p.primary, const Color(0xFFFFB74D), 0.7)!,
    );
    _forgeArc(c, t);
  }

  /// One faint arc across the hex plate for a fifth of a second every 11
  /// seconds: a thin line, never a flash of the frame.
  void _forgeArc(Canvas c, double t) {
    const period = 11.0;
    final local = ((t % period) - 6.2) / 0.22;
    if (local <= 0 || local >= 1) {
      return;
    }
    final rnd = math.Random((t / period).floor());
    final r = w * 0.15;
    final a = rnd.nextDouble() * math.pi * 2;
    final from = _plate + Offset(math.cos(a), math.sin(a)) * r;
    final to = _plate - Offset(math.cos(a), math.sin(a)) * r;
    final normal = Offset(-(to - from).dy, (to - from).dx) / (2 * r);
    final bolt = Path()..moveTo(from.dx, from.dy);
    for (var i = 1; i < 7; i++) {
      final along = Offset.lerp(from, to, i / 7)!;
      final jag = along + normal * (rnd.nextDouble() - 0.5) * r * 0.3;
      bolt.lineTo(jag.dx, jag.dy);
    }
    bolt.lineTo(to.dx, to.dy);
    final strength = math.sin(math.pi * local);
    c
      ..drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = p.secondary.withValues(alpha: 0.12 * strength),
      )
      ..drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = p.tertiary.withValues(alpha: 0.4 * strength),
      );
  }

  // ---------------------------------------------------------------------------
  // Crimson Alloy: a power core sending slow ripples out under a crimson
  // vignette, its spokes turning and gold sparks in orbit.
  // ---------------------------------------------------------------------------

  Offset get _core => Offset(w * 0.82, h * 0.86);

  void _crimsonBack(Canvas c) {
    _bloom(c, Offset(w * 0.1, h * 0.05), w * 0.7, p.primary, alpha: 0.3);
    _bloom(c, _core, w * 0.5, p.tertiary, alpha: 0.28);
    final ring = Paint()..style = PaintingStyle.stroke;
    for (var i = 1; i <= 6; i++) {
      ring
        ..strokeWidth = i.isEven ? 2 : 1
        ..color = p.tertiary.withValues(alpha: 0.12 - i * 0.015);
      c.drawCircle(_core, w * 0.05 * i, ring);
    }
    _bloom(c, Offset(w * 0.95, h * 0.15), w * 0.4, p.secondary, alpha: 0.18);
  }

  void _crimsonMotion(Canvas c, double t) {
    final spoke = Paint()
      ..color = p.tertiary.withValues(alpha: 0.12)
      ..strokeWidth = 3;
    final turn = t * 2 * math.pi / 48;
    for (var i = 0; i < 10; i++) {
      final a = math.pi * 2 / 10 * i + turn;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(_core + dir * w * 0.12, _core + dir * w * 0.2, spoke);
    }
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var k = 0; k < 3; k++) {
      final q = _loop(t / 4.5 + k / 3);
      ripple.color = p.tertiary.withValues(
        alpha: 0.2 * (1 - q) * (q * 6).clamp(0.0, 1.0),
      );
      c.drawCircle(_core, w * (0.06 + 0.34 * q), ripple);
    }
    _bloom(c, _core, w * 0.12, p.tertiary, alpha: 0.42 + 0.14 * _wave(t, 3.2));
    final spark = Paint();
    for (final m in _motes(97, 14)) {
      final radius = w * (0.14 + 0.18 * m.size);
      final a =
          m.phase + t * (0.08 + 0.12 * m.speed) * (m.tone.isEven ? 1 : -1);
      final at =
          _core + Offset(math.cos(a) * radius, math.sin(a) * radius * 0.55);
      spark.color = p.secondary.withValues(
        alpha: 0.2 + 0.4 * _wave(t, 1.6 + m.sway, m.phase),
      );
      c.drawCircle(at, 1 + m.size * 1.2, spark);
    }
    _sweep(
      c,
      t + 4,
      period: 11,
      length: 2,
      color: p.secondary,
      alpha: 0.05,
      angle: -0.45,
    );
  }

  // ---------------------------------------------------------------------------
  // Circuit: traces with solder nodes, signals racing along them, a violet
  // bloom and a slow scan.
  // ---------------------------------------------------------------------------

  List<_Trace> get _traces =>
      _traceCache.putIfAbsent('${w.round()}x${h.round()}', () {
        final rnd = math.Random(42);
        final step = w / 12;
        final traces = <_Trace>[];
        for (var i = 0; i < 22; i++) {
          var pt = Offset(rnd.nextInt(12) * step, rnd.nextDouble() * h);
          final alpha = 0.06 + rnd.nextDouble() * 0.1;
          final points = <Offset>[pt];
          for (var s = 0; s < 4; s++) {
            final horizontal = rnd.nextBool();
            final len = step * (1 + rnd.nextInt(3));
            pt = horizontal
                ? Offset(
                    (pt.dx + (rnd.nextBool() ? len : -len)).clamp(0, w),
                    pt.dy,
                  )
                : Offset(
                    pt.dx,
                    (pt.dy + (rnd.nextBool() ? len : -len)).clamp(0, h),
                  );
            points.add(pt);
          }
          traces.add(_Trace(points, alpha));
        }
        return traces;
      });

  void _circuitBack(Canvas c) {
    _bloom(c, Offset(w * 0.9, h * 0.12), w * 0.5, p.secondary, alpha: 0.26);
    _bloom(c, Offset(w * 0.1, h * 0.95), w * 0.6, p.primary, alpha: 0.2);
    final trace = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final node = Paint();
    for (final tr in _traces) {
      trace.color = p.primary.withValues(alpha: tr.alpha);
      node.color = p.primary.withValues(alpha: tr.alpha + 0.12);
      c.drawCircle(tr.points.first, 2.5, node);
      for (var i = 1; i < tr.points.length; i++) {
        c.drawLine(tr.points[i - 1], tr.points[i], trace);
      }
      c.drawCircle(tr.points.last, 2.5, node);
    }
  }

  void _circuitMotion(Canvas c, double t) {
    final dot = Paint();
    final traces = _traces;
    for (var i = 0; i < math.min(12, traces.length); i++) {
      final tr = traces[i];
      final speed = 0.09 + (i % 5) * 0.025;
      final q = _loop(t * speed + i * 0.37) * 1.5;
      if (q > 1.06) {
        continue;
      }
      for (var k = 2; k >= 0; k--) {
        final at = tr.at(q - k * 0.035);
        final fade = k == 0 ? 1.0 : 0.45 / k;
        dot.color = p.primary.withValues(alpha: 0.14 * fade);
        c.drawCircle(at, 6, dot);
        dot.color = p.primary.withValues(alpha: 0.75 * fade);
        c.drawCircle(at, k == 0 ? 2 : 1.4, dot);
      }
      if (q > 0.94) {
        _bloom(
          c,
          tr.points.last,
          14,
          p.primary,
          alpha: 0.35 * (1.06 - q) / 0.12,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Deep Field: three depths of stars drifting out from the centre (a slow
  // dolly through space), bright ones twinkling, an occasional shooting
  // star and two distant plasma glows.
  // ---------------------------------------------------------------------------

  Offset get _fieldCentre => Offset(w * 0.52, h * 0.46);

  void _deepFieldBack(Canvas c) {
    final rnd = math.Random(1977);
    _bloom(c, Offset(w * 0.08, h * 0.18), w * 0.62, p.primary, alpha: 0.2);
    _bloom(c, Offset(w * 0.96, h * 0.82), w * 0.52, p.secondary, alpha: 0.14);
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;
    for (var i = 0; i < 22; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final inner = w * (0.12 + rnd.nextDouble() * 0.26);
      final outer = inner + w * (0.08 + rnd.nextDouble() * 0.2);
      final dir = Offset(math.cos(angle), math.sin(angle));
      streak.color = p.primary.withValues(alpha: 0.04 + rnd.nextDouble() * 0.1);
      c.drawLine(
        _fieldCentre + dir * inner,
        _fieldCentre + dir * outer,
        streak,
      );
    }
    final orbit = Offset(w * 0.82, h * 0.2);
    _bloom(c, orbit, w * 0.09, p.tertiary, alpha: 0.18);
  }

  void _deepFieldMotion(Canvas c, double t) {
    final reach = math.sqrt(w * w + h * h) * 0.62;
    final star = Paint()..strokeCap = StrokeCap.round;
    final motes = _motes(1977, 96);
    for (var i = 0; i < motes.length; i++) {
      final m = motes[i];
      final depth = i % 3;
      final speed = const [0.006, 0.012, 0.024][depth] * (0.7 + m.speed * 0.6);
      final q = _loop(m.y + t * speed);
      final dist = reach * (0.04 + q * q * 0.96);
      final at =
          _fieldCentre + Offset(math.cos(m.phase), math.sin(m.phase)) * dist;
      if (at.dx < -4 || at.dy < -4 || at.dx > w + 4 || at.dy > h + 4) {
        continue;
      }
      final bright = i % 13 == 0;
      final radius =
          (bright ? 1.4 : 0.45 + m.size * 0.6) * (0.6 + q * (depth + 1) * 0.5);
      final fadeIn = (q * 5).clamp(0.0, 1.0);
      final twinkle = bright
          ? 0.55 + 0.45 * _wave(t, 2.6 + m.sway * 2, m.phase)
          : 1.0;
      star.color = (bright ? p.tertiary : p.ink).withValues(
        alpha: (bright ? 0.62 : 0.18 + m.sway * 0.36) * fadeIn * twinkle,
      );
      c.drawCircle(at, radius, star);
      if (bright) {
        star
          ..color = p.tertiary.withValues(alpha: 0.2 * fadeIn * twinkle)
          ..strokeWidth = 0.8;
        c.drawLine(
          at.translate(-radius * 3.5, 0),
          at.translate(radius * 3.5, 0),
          star,
        );
      }
    }
    _shootingStar(c, t);
  }

  void _shootingStar(Canvas c, double t) {
    const period = 9.5;
    final local = ((t % period) - 5) / 0.9;
    if (local <= 0 || local >= 1) {
      return;
    }
    final rnd = math.Random((t / period).floor() + 7);
    final start = Offset(
      w * (0.25 + 0.6 * rnd.nextDouble()),
      h * (0.05 + 0.25 * rnd.nextDouble()),
    );
    final a = 2.4 + rnd.nextDouble() * 0.4;
    final dir = Offset(math.cos(a), math.sin(a));
    final head = start + dir * w * 0.45 * Curves.easeOut.transform(local);
    final tail = head - dir * w * 0.14;
    final strength = math.sin(math.pi * local);
    c.drawLine(
      tail,
      head,
      Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            p.tertiary.withValues(alpha: 0),
            p.tertiary.withValues(alpha: 0.6 * strength),
          ],
        ).createShader(Rect.fromPoints(tail, head)),
    );
  }

  // ---------------------------------------------------------------------------
  // Love: soft rose bokeh rising slowly through warm light, gold sparkle.
  // ---------------------------------------------------------------------------

  void _loveBack(Canvas c) {
    _bloom(c, Offset(w * 0.85, h * 0.08), w * 0.55, p.secondary, alpha: 0.45);
    _bloom(c, Offset(w * 0.1, h * 0.92), w * 0.6, p.primary, alpha: 0.2);
  }

  void _loveMotion(Canvas c, double t) {
    final fill = Paint();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in _motes(3, 16)) {
      final speed = 0.008 + 0.014 * m.speed;
      final y = h * (1.1 - _loop(m.y + t * speed) * 1.2);
      final x = w * m.x + w * 0.02 * math.sin(t * 0.5 + m.phase);
      final r = 10 + m.size * 34;
      final color = m.tone.isEven ? p.secondary : p.tertiary;
      final breathe = 0.7 + 0.3 * _wave(t, 5 + m.speed * 4, m.phase);
      fill.color = color.withValues(alpha: (0.05 + 0.08 * m.sway) * breathe);
      ring.color = color.withValues(alpha: 0.12 * breathe);
      c
        ..drawCircle(Offset(x, y), r, fill)
        ..drawCircle(Offset(x, y), r, ring);
    }
    _twinkles(c, t, seed: 33, count: 24, color: p.tertiary, alpha: 0.4);
  }

  // ---------------------------------------------------------------------------
  // Rose: velvet glow, two rose blooms in the corners, petals tumbling down
  // and gold glints.
  // ---------------------------------------------------------------------------

  void _roseBack(Canvas c) {
    _bloom(c, Offset(w * 0.9, h * 0.05), w * 0.6, p.primary, alpha: 0.32);
    _bloom(c, Offset(w * 0.05, h * 0.95), w * 0.55, p.secondary, alpha: 0.18);
    ThemeMotifs.drawRose(
      c,
      Offset(w * 0.96, h * 0.06),
      w * 0.3,
      heart: p.primary,
      edge: p.secondary,
      alpha: 0.26,
      petals: 34,
    );
    ThemeMotifs.drawRose(
      c,
      Offset(w * 0.02, h * 0.9),
      w * 0.24,
      heart: p.primary,
      edge: p.secondary,
      alpha: 0.18,
      petals: 34,
    );
  }

  void _roseMotion(Canvas c, double t) {
    _fallingPetals(
      c,
      t,
      seed: 11,
      count: 14,
      colors: [p.primary, p.secondary],
      minLength: 10,
      maxLength: 26,
      alpha: 0.14,
      drift: 0.08,
    );
    _twinkles(c, t, seed: 12, count: 18, color: p.tertiary, alpha: 0.42);
  }

  // ---------------------------------------------------------------------------
  // Blue Rose: sapphire glow, two blue roses in the corners with ice-lit
  // rims, cool petals tumbling down, platinum glints and a slow lamp sweep.
  // ---------------------------------------------------------------------------

  static const Color _sapphire = Color(0xFF1E4FD8);

  void _blueRoseBack(Canvas c) {
    _bloom(c, Offset(w * 0.9, h * 0.05), w * 0.6, p.primary, alpha: 0.3);
    _bloom(c, Offset(w * 0.05, h * 0.95), w * 0.55, p.jewel, alpha: 0.14);
    ThemeMotifs.drawRose(
      c,
      Offset(w * 0.96, h * 0.06),
      w * 0.3,
      heart: _sapphire,
      edge: p.primary,
      alpha: 0.3,
      petals: 34,
    );
    ThemeMotifs.drawRose(
      c,
      Offset(w * 0.02, h * 0.9),
      w * 0.24,
      heart: _sapphire,
      edge: p.jewel,
      alpha: 0.2,
      petals: 34,
    );
  }

  void _blueRoseMotion(Canvas c, double t) {
    _fallingPetals(
      c,
      t,
      seed: 21,
      count: 14,
      colors: [p.primary, p.jewel, _sapphire],
      minLength: 10,
      maxLength: 26,
      alpha: 0.14,
      drift: 0.08,
    );
    _twinkles(c, t, seed: 22, count: 20, color: p.tertiary, alpha: 0.45);
    _sweep(c, t, period: 13, length: 2.4, color: p.trim, alpha: 0.05);
  }

  // ---------------------------------------------------------------------------
  // Blue Lotus: looking down on a moonlit pond. Lily pads and two open
  // blooms sit in the corners; rings spread slowly over the water from each
  // bloom, gold pollen drifts up and the moon's light crosses now and then.
  // ---------------------------------------------------------------------------

  /// x, y, radius (as a share of the width) and where the pad's notch points.
  static const List<(double, double, double, double)> _lilyPads = [
    (0.32, 0.99, 0.16, -1.1),
    (-0.03, 0.7, 0.13, 0.5),
    (0.74, 0.0, 0.12, 2.2),
    (1.03, 0.2, 0.1, -2.8),
  ];

  /// x, y, radius (as a share of the width) and strength of each bloom.
  static const List<(double, double, double, double)> _lotuses = [
    (0.06, 0.91, 0.2, 0.36),
    (0.95, 0.06, 0.14, 0.26),
  ];

  void _lotusBack(Canvas c) {
    _bloom(c, Offset(w * 0.9, h * 0.04), w * 0.7, p.secondary, alpha: 0.2);
    _bloom(c, Offset(w * 0.08, h * 0.96), w * 0.75, p.primary, alpha: 0.26);
    for (final (x, y, r, notch) in _lilyPads) {
      _lilyPad(c, Offset(w * x, h * y), w * r, notch);
    }
    for (final (x, y, r, strength) in _lotuses) {
      final at = Offset(w * x, h * y);
      // Light pooling on the water under the bloom.
      _bloom(c, at, w * r * 1.7, p.tertiary, alpha: 0.1);
      ThemeMotifs.drawLotus(
        c,
        at,
        w * r,
        heart: Color.lerp(p.secondary, Colors.white, 0.4)!,
        edge: p.primary,
        stamen: p.tertiary,
        alpha: strength,
        twist: x * 2,
      );
    }
  }

  void _lilyPad(Canvas c, Offset at, double r, double notch) {
    const gap = 0.2;
    final rect = Rect.fromCircle(center: at, radius: r);
    final pad = Path()
      ..moveTo(at.dx, at.dy)
      ..arcTo(rect, notch + gap, math.pi * 2 - gap * 2, false)
      ..close();
    final leaf = Color.lerp(const Color(0xFF1C6B63), p.primary, 0.18)!;
    c
      ..drawPath(
        pad,
        Paint()
          ..shader = RadialGradient(
            colors: [
              leaf.withValues(alpha: 0.36),
              leaf.withValues(alpha: 0.16),
            ],
          ).createShader(rect),
      )
      ..drawPath(
        pad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = p.primary.withValues(alpha: 0.18),
      );
    final vein = Paint()
      ..strokeWidth = 0.8
      ..color = p.ink.withValues(alpha: 0.05);
    for (var k = 1; k < 9; k++) {
      final a = notch + gap + (math.pi * 2 - gap * 2) * k / 9;
      c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * r * 0.92, vein);
    }
  }

  void _lotusMotion(Canvas c, double t) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < _lotuses.length; i++) {
      final (x, y, r, _) = _lotuses[i];
      final at = Offset(w * x, h * y);
      for (var k = 0; k < 3; k++) {
        final q = _loop(t / 9 + k / 3 + i * 0.17);
        ring.color = p.primary.withValues(alpha: 0.2 * math.sin(math.pi * q));
        c.drawCircle(at, w * r * (1.05 + 1.6 * q), ring);
      }
    }
    _embers(
      c,
      t,
      seed: 31,
      count: 12,
      cool: p.tertiary,
      hot: const Color(0xFFFFF1C2),
      rate: 0.45,
    );
    _twinkles(c, t, seed: 32, count: 22, color: p.ink, alpha: 0.3);
    _sweep(c, t, period: 14, length: 3, color: p.secondary, alpha: 0.045);
  }

  // ---------------------------------------------------------------------------
  // Petal: blush light with petals and sage leaves falling on a gentle
  // diagonal, turning over as they go.
  // ---------------------------------------------------------------------------

  void _petalBack(Canvas c) {
    _bloom(c, Offset(w * 0.8, h * 0.1), w * 0.6, p.secondary, alpha: 0.32);
    _bloom(c, Offset(w * 0.15, h * 0.85), w * 0.5, p.tertiary, alpha: 0.12);
  }

  void _petalMotion(Canvas c, double t) {
    _fallingPetals(
      c,
      t,
      seed: 5,
      count: 24,
      colors: [p.secondary, p.primary, p.secondary],
      minLength: 12,
      maxLength: 34,
      alpha: 0.16,
      leaf: p.tertiary,
    );
  }

  // ---------------------------------------------------------------------------
  // Snow: a moon behind thin cloud, a swaying ribbon of aurora with light
  // running along it, frost ferns in the top corners, snow falling at three
  // depths and drifts along the bottom with glints that catch the light.
  // ---------------------------------------------------------------------------

  void _snowBack(Canvas c) {
    final moon = Offset(w * 0.84, h * 0.07);
    _bloom(c, moon, w * 0.62, p.secondary, alpha: 0.14);
    _bloom(c, moon, w * 0.16, Colors.white, alpha: 0.95);
    c.drawCircle(
      moon,
      w * 0.05,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final frost = Paint()
      ..color = p.secondary.withValues(alpha: 0.12)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    final frostRnd = math.Random(19);
    for (var i = 0; i < 5; i++) {
      _frostFern(
        c,
        Offset.zero,
        0.15 + i * 0.3 + frostRnd.nextDouble() * 0.1,
        w * (0.14 + frostRnd.nextDouble() * 0.08),
        3,
        frost,
        frostRnd,
      );
      _frostFern(
        c,
        Offset(w, 0),
        math.pi - 0.15 - i * 0.3 - frostRnd.nextDouble() * 0.1,
        w * (0.1 + frostRnd.nextDouble() * 0.06),
        3,
        frost,
        frostRnd,
      );
    }
  }

  void _snowAurora(Canvas c) {
    _aurora(
      c,
      color: p.tertiary,
      top: h * 0.1,
      wave: h * 0.035,
      depth: h * 0.09,
      phase: 0.4,
      alpha: 0.13,
    );
    _aurora(
      c,
      color: p.primary,
      top: h * 0.17,
      wave: h * 0.028,
      depth: h * 0.06,
      phase: 2.2,
      alpha: 0.08,
    );
  }

  void _snowMotion(Canvas c, double t) {
    final aurora = _PictureCache.get('aurora|${p.id}', size, _snowAurora);
    c
      ..save()
      ..translate(
        w * 0.035 * math.sin(t * 2 * math.pi / 16),
        h * 0.006 * math.sin(t * 2 * math.pi / 11),
      )
      ..drawPicture(aurora)
      ..restore();
    // Light running along the ribbon.
    _bloom(
      c,
      Offset(w * (-0.2 + 1.4 * _loop(t / 13)), h * 0.15),
      w * 0.22,
      p.tertiary,
      alpha: 0.07,
    );

    // Far: fine dust.
    final dust = Paint();
    for (final m in _motes(1225, 70)) {
      final q = _loop(m.y + t * (0.012 + 0.02 * m.speed));
      dust.color = p.primary.withValues(alpha: 0.08 + m.sway * 0.14);
      c.drawCircle(
        Offset(
          w * m.x + 6 * math.sin(t * 0.4 + m.phase),
          h * (-0.02 + q * 0.94),
        ),
        0.6 + m.size,
        dust,
      );
    }
    // Mid: small crisp crystals turning as they fall.
    final crisp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    for (final m in _motes(1226, 18)) {
      final q = _loop(m.y + t * (0.03 + 0.03 * m.speed));
      crisp.color = p.secondary.withValues(alpha: 0.2 + m.speed * 0.14);
      _crystal(
        c,
        Offset(
          w * m.x + w * 0.02 * math.sin(t * 0.5 + m.phase),
          h * (-0.03 + q * 0.92),
        ),
        3 + m.size * 4,
        m.sway + t * 0.05 * (m.tone.isEven ? 1 : -1),
        1,
        crisp,
      );
    }
    // Near: big soft crystals, a white core over a glacier-blue halo so they
    // read on the pale ground.
    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.85);
    for (final m in _motes(1227, 7)) {
      final q = _loop(m.y + t * (0.05 + 0.04 * m.speed));
      final at = Offset(
        w * m.x + w * 0.04 * math.sin(t * 0.35 + m.phase),
        h * (-0.05 + q * 0.92),
      );
      final radius = 10 + m.size * 10;
      final turn = m.sway + t * 0.03;
      halo.color = p.primary.withValues(alpha: 0.08 + m.speed * 0.05);
      _crystal(c, at, radius, turn, 2, halo);
      _crystal(c, at, radius, turn, 2, core);
    }
  }

  void _aurora(
    Canvas canvas, {
    required Color color,
    required double top,
    required double wave,
    required double depth,
    required double phase,
    required double alpha,
  }) {
    double edge(double x) =>
        top +
        wave * math.sin(x / w * math.pi * 1.6 + phase) +
        wave * 0.4 * math.sin(x / w * math.pi * 4.2 + phase * 2);
    final band = Path()..moveTo(-w * 0.1, edge(-w * 0.1));
    for (var x = -w * 0.1; x <= w * 1.1; x += 8) {
      band.lineTo(x, edge(x));
    }
    for (var x = w * 1.1; x >= -w * 0.1; x -= 8) {
      band.lineTo(
        x,
        edge(x) + depth * (0.65 + 0.35 * math.sin(x / w * 7 + phase)),
      );
    }
    band.close();
    final bounds = Rect.fromLTWH(0, top - wave * 2, w, depth + wave * 4);
    canvas.drawPath(
      band,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.5),
            color.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );
    final ray = Paint()
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final rnd = math.Random(phase.hashCode);
    for (var x = -w * 0.1 + 4; x < w * 1.1; x += 5 + rnd.nextDouble() * 9) {
      final y = edge(x) + wave * 0.3 * rnd.nextDouble();
      final length = depth * (0.6 + 1.2 * rnd.nextDouble());
      final glow = alpha * (0.2 + 0.5 * rnd.nextDouble());
      ray.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: glow),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.25, 1],
      ).createShader(Rect.fromLTWH(x, y, 1, length));
      canvas.drawLine(Offset(x, y), Offset(x, y + length), ray);
    }
  }

  void _frostFern(
    Canvas canvas,
    Offset from,
    double angle,
    double length,
    int depth,
    Paint paint,
    math.Random rnd,
  ) {
    if (length < 3 || depth < 0) {
      return;
    }
    final to = from + Offset(math.cos(angle), math.sin(angle)) * length;
    canvas.drawLine(from, to, paint);
    if (depth == 0) {
      return;
    }
    for (final at in const [0.35, 0.6, 0.85]) {
      final base = Offset.lerp(from, to, at)!;
      final side = (rnd.nextBool() ? 1 : -1) * (0.6 + rnd.nextDouble() * 0.3);
      _frostFern(
        canvas,
        base,
        angle + side,
        length * (0.42 - at * 0.18),
        depth - 1,
        paint,
        rnd,
      );
    }
  }

  void _crystal(
    Canvas canvas,
    Offset at,
    double radius,
    double turn,
    int detail,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(turn * math.pi / 3)
      ..drawPath(_flake(radius, detail), paint)
      ..restore();
  }

  void _drifts(Canvas canvas) {
    Path drift(double crest, double swell, double phase) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 6) {
        final y =
            h -
            crest -
            swell * math.sin(x / w * math.pi * 1.3 + phase) -
            swell * 0.35 * math.sin(x / w * math.pi * 3.7 + phase * 1.7);
        path.lineTo(x, y);
      }
      return path
        ..lineTo(w, h)
        ..close();
    }

    final layers = [
      (h * 0.115, h * 0.022, 0.6, p.paperSunk),
      (h * 0.085, h * 0.02, 2.4, p.paper),
      (h * 0.05, h * 0.018, 4.1, Colors.white),
    ];
    for (final (crest, swell, phase, color) in layers) {
      final path = drift(crest, swell, phase);
      canvas
        ..drawPath(
          path.shift(const Offset(0, -3)),
          Paint()
            ..color = p.primary.withValues(alpha: 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawPath(path, Paint()..color = color.withValues(alpha: 0.92));
    }
  }

  /// Glints on the drift crests catch the light one by one.
  void _driftGlints(Canvas canvas, double t) {
    final glint = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final motes = _motes(31, 14);
    for (final m in motes) {
      final at = Offset(m.x * w, h - m.y * h * 0.1);
      final r = 1.5 + m.size * 2.5;
      final shine = _wave(t, 2.4 + m.speed * 2, m.phase);
      glint.color = p.primary.withValues(alpha: 0.12 + 0.3 * shine);
      final s = r * (0.7 + 0.5 * shine);
      canvas
        ..drawLine(at.translate(-s, 0), at.translate(s, 0), glint)
        ..drawLine(at.translate(0, -s), at.translate(0, s), glint);
    }
  }

  // ---------------------------------------------------------------------------
  // Gothic: a full moon with bats circling it, a cathedral rose window, a
  // spired skyline with windows lit by flickering candles, fog rolling along
  // the ground and three candles burning in the foreground, sparks rising.
  // ---------------------------------------------------------------------------

  Offset get _gothicMoon => Offset(w * 0.8, h * 0.1);
  double get _gothicMoonRadius => w * 0.085;

  static const List<(double, double)> _candles = [
    (0.08, 0.075),
    (0.15, 0.05),
    (0.21, 0.064),
  ];

  void _gothicBack(Canvas c) {
    _bloom(c, Offset(w * 0.5, h * 1.02), w * 0.95, p.primary, alpha: 0.24);
    _bloom(c, Offset(w * 0.08, h * 0.14), w * 0.6, p.secondary, alpha: 0.12);

    final moon = _gothicMoon;
    final moonRadius = _gothicMoonRadius;
    _bloom(c, moon, moonRadius * 4.6, p.ink, alpha: 0.1);
    c.drawCircle(
      moon,
      moonRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            p.ink.withValues(alpha: 0.4),
            p.inkMuted.withValues(alpha: 0.24),
          ],
        ).createShader(Rect.fromCircle(center: moon, radius: moonRadius)),
    );
    final crater = Paint()..color = p.ground.withValues(alpha: 0.08);
    c
      ..drawCircle(
        moon.translate(moonRadius * 0.3, moonRadius * 0.15),
        moonRadius * 0.22,
        crater,
      )
      ..drawCircle(
        moon.translate(-moonRadius * 0.35, moonRadius * 0.4),
        moonRadius * 0.14,
        crater,
      )
      ..drawCircle(
        moon.translate(-moonRadius * 0.1, -moonRadius * 0.45),
        moonRadius * 0.1,
        crater,
      );

    _roseWindow(c, Offset(w * 0.5, h * 0.34), w * 0.42);
    _skyline(c);

    for (final (x, tall) in _candles) {
      final base = Offset(w * x, h * 0.9);
      final top = base.translate(0, -h * tall);
      final stick = RRect.fromRectAndRadius(
        Rect.fromLTRB(top.dx - w * 0.016, top.dy, top.dx + w * 0.016, base.dy),
        const Radius.circular(2),
      );
      c.drawRRect(
        stick,
        Paint()
          ..shader = LinearGradient(
            colors: [
              p.ink.withValues(alpha: 0.14),
              p.inkMuted.withValues(alpha: 0.06),
            ],
          ).createShader(stick.outerRect),
      );
    }
  }

  void _gothicFog(Canvas c) {
    final rnd = math.Random(1313);
    for (var i = 0; i < 6; i++) {
      final at = Offset(
        rnd.nextDouble() * w,
        h * (0.7 + rnd.nextDouble() * 0.28),
      );
      c.drawOval(
        Rect.fromCenter(
          center: at,
          width: w * (0.6 + rnd.nextDouble() * 0.6),
          height: h * 0.05,
        ),
        Paint()
          ..color = p.ink.withValues(alpha: 0.035 + rnd.nextDouble() * 0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
  }

  /// A candle flame's flicker: three slow sines, the fastest 2.2 Hz, so it
  /// wavers rather than strobes.
  static double candleFlicker(double t, int i) =>
      1 +
      0.08 * math.sin(t * 9.4 + i * 1.3) +
      0.05 * math.sin(t * 5.3 + i * 2.1) +
      0.03 * math.sin(t * 13.8 + i);

  void _gothicMotion(Canvas c, double t) {
    // Lit windows waver with the candles inside.
    final windows = _skylineWindows();
    for (var i = 0; i < windows.length; i++) {
      _bloom(
        c,
        windows[i].center,
        windows[i].width * 2.4,
        p.tertiary,
        alpha: 0.05 + 0.05 * (candleFlicker(t, i + 5) - 0.84) / 0.32,
      );
    }

    // Bats circling the moon, beating their wings.
    final batFill = Paint()..color = Color.lerp(p.ground, Colors.black, 0.6)!;
    final batRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = p.inkMuted.withValues(alpha: 0.3);
    const bats = [
      (-0.9, 0.2, 0.09, 0.6, -0.2),
      (-0.2, -0.5, 0.06, -0.4, 0.15),
      (0.6, 0.55, 0.05, 0.9, 0.1),
      (-1.9, 0.9, 0.045, -0.8, -0.1),
      (-2.6, -0.2, 0.035, 0.3, 0.2),
    ];
    var i = 0;
    for (final (dx, dy, span, flap, tilt) in bats) {
      final orbit = t * 0.035 * (i.isEven ? 1 : -1);
      final base = Offset(dx, dy) * _gothicMoonRadius;
      final turned = Offset(
        base.dx * math.cos(orbit) - base.dy * math.sin(orbit),
        base.dx * math.sin(orbit) + base.dy * math.cos(orbit),
      );
      final at =
          _gothicMoon +
          turned +
          Offset(0, math.sin(t * 0.8 + i) * _gothicMoonRadius * 0.08);
      final beat = t == 0 ? flap : math.sin(t * (5.5 + i * 0.7) + i);
      final path = ThemeMotifs.bat(w * span, flap: beat);
      c
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(tilt + 0.08 * math.sin(t * 0.6 + i))
        ..drawPath(path, batFill)
        ..drawPath(path, batRim)
        ..restore();
      i++;
    }

    // Fog rolling slowly along the ground, looping seamlessly.
    final fog = _PictureCache.get('fog|${p.id}', size, _gothicFog);
    final dx = (t * 7) % w;
    c
      ..save()
      ..translate(dx, 0)
      ..drawPicture(fog)
      ..translate(-w, 0)
      ..drawPicture(fog)
      ..restore();

    // Candle flames and sparks rising from them.
    var k = 0;
    for (final (x, tall) in _candles) {
      final top = Offset(w * x, h * 0.9 - h * tall);
      final flicker = candleFlicker(t, k);
      final flame = top.translate(0, -h * 0.014);
      _bloom(
        c,
        flame,
        w * 0.12 * (0.94 + 0.06 * flicker),
        p.tertiary,
        alpha: 0.2 + 0.1 * (flicker - 1),
      );
      final lean = w * 0.004 * math.sin(t * 1.7 + k);
      final tip = flame.translate(lean, -h * 0.014 * flicker);
      final tongue = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(
          flame.dx + w * 0.012,
          flame.dy,
          flame.dx,
          flame.dy + h * 0.008,
        )
        ..quadraticBezierTo(flame.dx - w * 0.012, flame.dy, tip.dx, tip.dy)
        ..close();
      c.drawPath(
        tongue,
        Paint()
          ..color = Color.lerp(
            p.tertiary,
            Colors.white,
            0.35,
          )!.withValues(alpha: 0.6),
      );
      k++;
    }
    _embers(
      c,
      t,
      seed: 1414,
      count: 10,
      cool: p.primary,
      hot: p.tertiary,
      left: 0.05,
      right: 0.24,
      from: 0.82,
      to: 0.5,
      rate: 0.8,
    );
  }

  void _roseWindow(Canvas canvas, Offset center, double radius) {
    final lead = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = p.tertiary.withValues(alpha: 0.11);
    canvas
      ..drawCircle(center, radius, lead)
      ..drawCircle(center, radius * 0.93, lead)
      ..drawCircle(center, radius * 0.32, lead);
    final hw = radius * 0.11;
    final lancet = Path()
      ..moveTo(-hw * 0.6, -radius * 0.36)
      ..lineTo(-hw, -radius * 0.7)
      ..quadraticBezierTo(-hw, -radius * 0.86, 0, -radius * 0.9)
      ..quadraticBezierTo(hw, -radius * 0.86, hw, -radius * 0.7)
      ..lineTo(hw * 0.6, -radius * 0.36)
      ..close();
    for (var i = 0; i < 12; i++) {
      final glass = Paint()
        ..color = (i.isEven ? p.primary : p.secondary).withValues(alpha: 0.045);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(math.pi * 2 / 12 * i)
        ..drawPath(lancet, glass)
        ..drawPath(lancet, lead)
        ..drawCircle(Offset(0, -radius * 0.74), hw * 0.5, lead)
        ..rotate(math.pi / 12)
        ..drawCircle(Offset(0, -radius * 0.86), radius * 0.045, lead)
        ..restore();
    }
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius * 0.16,
        radius * 0.1,
        lead,
      );
    }
    _bloom(canvas, center, radius * 0.3, p.primary, alpha: 0.1);
  }

  // (centre x, width, height, spire height) as fractions of the screen.
  static const List<(double, double, double, double)> _towers = [
    (0.04, 0.1, 0.05, 0.03),
    (0.2, 0.08, 0.07, 0.05),
    (0.36, 0.09, 0.15, 0.11),
    (0.5, 0.2, 0.1, 0.04),
    (0.64, 0.09, 0.15, 0.11),
    (0.8, 0.08, 0.08, 0.06),
    (0.95, 0.12, 0.055, 0.03),
  ];

  double get _ground => h * 0.88;

  List<Rect> _skylineWindows() => [
    for (final (x, width, tall, _) in _towers)
      if (tall > 0.06)
        Rect.fromCenter(
          center: Offset(w * x, _ground - h * tall + h * tall * 0.35),
          width: w * width * 0.22,
          height: h * 0.022,
        ),
  ];

  void _skyline(Canvas canvas) {
    final city = Path()..addRect(Rect.fromLTRB(0, _ground - h * 0.03, w, h));
    for (final (x, width, tall, spire) in _towers) {
      final left = w * (x - width / 2);
      final right = w * (x + width / 2);
      final top = _ground - h * tall;
      city
        ..addRect(Rect.fromLTRB(left, top, right, h))
        ..addPath(
          Path()
            ..moveTo(left - 2, top)
            ..lineTo(w * x, top - h * spire)
            ..lineTo(right + 2, top)
            ..close(),
          Offset.zero,
        );
    }
    canvas.drawPath(
      city,
      Paint()..color = Color.lerp(p.ground, Colors.black, 0.45)!,
    );
    final lit = Paint()..color = p.tertiary.withValues(alpha: 0.26);
    for (final r in _skylineWindows()) {
      final arch = Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + r.height * 0.35)
        ..quadraticBezierTo(r.left, r.top, r.center.dx, r.top)
        ..quadraticBezierTo(r.right, r.top, r.right, r.top + r.height * 0.35)
        ..lineTo(r.right, r.bottom)
        ..close();
      canvas.drawPath(arch, lit);
      _bloom(canvas, r.center, r.width * 2.4, p.tertiary, alpha: 0.05);
    }
  }
}

/// Neon flicker level at [t] seconds (1 is fully lit). Exposed for the
/// photosensitivity test: it never changes more than twice a second.
@visibleForTesting
double debugNeonFlicker(double t) => _Scene.neonFlicker(t);

/// Candle flicker for candle [i] at [t] seconds.
@visibleForTesting
double debugCandleFlicker(double t, int i) => _Scene.candleFlicker(t, i);

// -----------------------------------------------------------------------------
// Title card
// -----------------------------------------------------------------------------

/// How long the title card holds before it dissolves into the app.
const Duration kThemeTitleCardHold = Duration(milliseconds: 1700);

/// A "scene change" when a look is chosen: letterbox bars slide in, the
/// look's name tracks in from a soft focus in its display face over its own
/// moving atmosphere, a light effect tuned to the look crosses the frame (an
/// anamorphic streak for the metal and space looks, a warm light leak for
/// the romantic ones, a frost glint for Snow and Blue Rose, candle glow and a
/// moonbeam for Gothic and Blue Lotus), then the card dissolves into the newly coloured app. The app's
/// theme morphs underneath ([MaterialApp]'s theme animation), so the reveal
/// lands on the new palette. Auto dismisses; a tap dismisses early.
///
/// A [ThemePreset.reducedMotion] look skips the card entirely. With the
/// platform's reduce-motion setting on, the card appears and leaves without
/// any motion, flare or fade.
Future<void> showThemeTitleCard(BuildContext context, ThemePreset preset) {
  if (preset.reducedMotion) {
    return Future<void>.value();
  }
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Theme preview',
    barrierColor: Colors.transparent,
    transitionDuration: still
        ? Duration.zero
        : const Duration(milliseconds: 420),
    pageBuilder: (dialogContext, _, _) => ThemeTitleCard(
      preset: preset,
      still: still,
      onDone: () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      },
    ),
    transitionBuilder: (_, animation, _, child) => still
        ? child
        : FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: child,
          ),
  );
}

/// The title card itself. See [showThemeTitleCard].
class ThemeTitleCard extends StatefulWidget {
  const ThemeTitleCard({
    required this.preset,
    required this.onDone,
    this.still = false,
    super.key,
  });

  final ThemePreset preset;
  final VoidCallback onDone;

  /// No motion: bars in place, title shown, no light effect.
  final bool still;

  @override
  State<ThemeTitleCard> createState() => _ThemeTitleCardState();
}

class _ThemeTitleCardState extends State<ThemeTitleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: kThemeTitleCardHold,
  );
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    if (widget.still) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
    _hold = Timer(kThemeTitleCardHold, () {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  double _phase(
    double from,
    double to, [
    Curve curve = CinematicMotion.settle,
  ]) {
    final v = ((_reveal.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final size = MediaQuery.sizeOf(context);
    final barHeight = size.height * 0.11;
    return GestureDetector(
      onTap: widget.onDone,
      child: Material(
        color: preset.ground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ThemeAtmosphere(preset: preset),
            AnimatedBuilder(
              animation: _reveal,
              builder: (context, _) {
                final bars = _phase(0, 0.2);
                final title = _phase(0.1, 0.5);
                final rule = _phase(0.3, 0.6);
                final tagline = _phase(0.4, 0.7);
                final blur = widget.still ? 0.0 : 8 * (1 - title);
                final heading = Text(
                  preset.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: preset.displayFamily,
                    fontSize: 44,
                    height: 1,
                    letterSpacing: 14 * (1 - title),
                    fontWeight: FontWeight.w700,
                    color: preset.ink,
                    shadows: [
                      Shadow(
                        color: preset.primary.withValues(alpha: 0.6),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!widget.still)
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: TitleFlarePainter(
                              preset: preset,
                              progress: _phase(0.22, 0.85, Curves.easeInOut),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: title,
                              child: Text(
                                'NOW SHOWING',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w700,
                                  color: preset.inkMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: title,
                              child: blur > 0.05
                                  ? ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                        sigmaX: blur,
                                        sigmaY: blur,
                                      ),
                                      child: heading,
                                    )
                                  : heading,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 64 * rule,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: preset.accentGradient,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: tagline,
                              child: Text(
                                preset.tagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: preset.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Letterbox bars.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -barHeight * (1 - bars),
                      height: barHeight,
                      child: const ColoredBox(color: Colors.black),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -barHeight * (1 - bars),
                      height: barHeight,
                      child: const ColoredBox(color: Colors.black),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The light effect that crosses a title card, by look. [progress] runs 0 to
/// 1 once; the effect fades in and out within it, so it never flashes.
class TitleFlarePainter extends CustomPainter {
  TitleFlarePainter({required this.preset, required this.progress});

  final ThemePreset preset;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.isEmpty) {
      return;
    }
    final strength = math.sin(math.pi * progress);
    switch (preset.id) {
      case 'love' || 'rose' || 'petal':
        _lightLeak(canvas, size, strength, warm: true);
      case 'snow' || 'bluerose':
        _frostGlint(canvas, size, strength);
      case 'gothic' || 'bluelotus':
        _lightLeak(canvas, size, strength, warm: false);
      default:
        _anamorphic(canvas, size, strength);
    }
  }

  /// A thin horizontal streak through the title with a hot spot gliding
  /// across it and two faint lens ghosts on the diagonal.
  void _anamorphic(Canvas canvas, Size size, double strength) {
    final y = size.height * 0.5 - 8;
    final x = size.width * (-0.1 + 1.2 * progress);
    final streak = Rect.fromLTWH(0, y - 1.5, size.width, 3);
    canvas
      ..drawRect(
        streak,
        Paint()
          ..shader = LinearGradient(
            colors: [
              preset.primary.withValues(alpha: 0),
              preset.primary.withValues(alpha: 0.55 * strength),
              Colors.white.withValues(alpha: 0.7 * strength),
              preset.primary.withValues(alpha: 0.55 * strength),
              preset.primary.withValues(alpha: 0),
            ],
            stops: [
              0,
              (x / size.width - 0.2).clamp(0.01, 0.97),
              (x / size.width).clamp(0.02, 0.98),
              (x / size.width + 0.2).clamp(0.03, 0.99),
              1,
            ],
          ).createShader(streak),
      )
      ..drawCircle(
        Offset(x, y),
        36,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.35 * strength),
              preset.primary.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 36)),
      );
    final centre = size.center(Offset.zero);
    final ghostLine = centre - Offset(x, y);
    for (final (k, r) in const [(0.6, 18.0), (1.4, 30.0)]) {
      final at = centre + ghostLine * k;
      canvas.drawCircle(
        at,
        r,
        Paint()..color = preset.secondary.withValues(alpha: 0.08 * strength),
      );
    }
  }

  /// Soft overexposed colour washing in from a corner, the way light leaks
  /// across the edge of a film frame.
  void _lightLeak(
    Canvas canvas,
    Size size,
    double strength, {
    required bool warm,
  }) {
    final leak = warm ? const Color(0xFFFF9A6B) : preset.tertiary;
    final from = warm
        ? Offset(size.width * (1.1 - 0.4 * progress), size.height * 0.15)
        : Offset(size.width * (-0.1 + 0.3 * progress), size.height * 0.85);
    final radius = size.longestSide * 0.55;
    canvas.drawCircle(
      from,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            leak.withValues(alpha: 0.32 * strength),
            preset.secondary.withValues(alpha: 0.12 * strength),
            leak.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: from, radius: radius)),
    );
    if (!warm) {
      // A moonbeam slanting down from the top right.
      final beam = Path()
        ..moveTo(size.width * 0.75, 0)
        ..lineTo(size.width * 0.95, 0)
        ..lineTo(size.width * 0.35, size.height)
        ..lineTo(size.width * 0.05, size.height)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              preset.ink.withValues(alpha: 0.1 * strength),
              preset.ink.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
  }

  /// A four-point star glinting above the title and a cool sheen.
  void _frostGlint(Canvas canvas, Size size, double strength) {
    final at = Offset(size.width * 0.5 + 92, size.height * 0.5 - 40);
    final r = 26 * strength;
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * strength)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(at.translate(-r, 0), at.translate(r, 0), glint)
      ..drawLine(at.translate(0, -r * 1.3), at.translate(0, r * 1.3), glint)
      ..drawCircle(
        at,
        r * 0.9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              preset.secondary.withValues(alpha: 0.35 * strength),
              preset.secondary.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: r * 0.9 + 1)),
      );
    final band = Rect.fromLTWH(
      size.width * (-0.3 + 1.3 * progress),
      0,
      size.width * 0.3,
      size.height,
    );
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.18 * strength),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(TitleFlarePainter old) =>
      old.progress != progress || old.preset.id != preset.id;
}
