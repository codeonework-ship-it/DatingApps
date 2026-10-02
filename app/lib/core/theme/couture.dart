import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cinematic_effects.dart';
import 'theme_presets.dart';

/// The finishing layer every look shares: the difference between a palette
/// and something that feels made.
///
/// * **Primary actions** roll from the look's primary into its
///   [ThemePreset.jewel] (rose into champagne gold, sapphire into amethyst),
///   lit from above and edged with a hairline in the look's
///   [ThemePreset.trim], so a Rose button is not simply pink.
/// * **Cards and panels** get a bevelled hairline that catches the trim at
///   the top-left and falls away to the quiet rule, a soft lift off the
///   ground and, on dark looks, a satin fill.
/// * **Small ornaments** (the rule beside an eyebrow, the selected tab) use
///   the same gradient, so one screen carries two or three colours of the
///   look rather than one.
///
/// Everything reads from the [ConnectPalette] on the theme. Without one (the
/// bare [ThemeData] some tests pump) every helper falls back to the flat
/// Today drawing. The Calm look keeps the sharp hairlines but none of the
/// glow: its jewel is a deeper shade of its one accent and it casts no
/// coloured shadow.
abstract final class Couture {
  static ThemePreset? presetOf(BuildContext context) =>
      Theme.of(context).extension<ConnectPalette>()?.preset;

  /// Hairline colours for a card, top-left to bottom-right.
  static List<Color> rimColors(ThemePreset p) => [
    Color.lerp(p.ruleStrong, p.trim, p.isDark ? 0.62 : 0.5)!,
    p.ruleStrong,
    p.rule,
  ];

  /// The hairline itself, as a shape for cards, dialogs and decorations.
  static CoutureBorder rim(
    ThemePreset p, {
    BorderRadius radius = const BorderRadius.all(Radius.circular(20)),
  }) => CoutureBorder(colors: rimColors(p), borderRadius: radius);

  /// Satin: on a dark look a card falls away from the light toward its
  /// foot, settling into the sunk paper. It only ever darkens under light
  /// text, so depth never costs contrast. Light looks and Calm keep flat
  /// paper (null): shading white paper would dim the text on it.
  static Gradient? satin(ThemePreset p) => !p.isDark || p.reducedMotion
      ? null
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.paper, p.paper, Color.lerp(p.paper, p.paperSunk, 0.7)!],
          stops: const [0, 0.4, 1],
        );

  /// One soft shadow that seats a card on its ground.
  static List<BoxShadow> lift(ThemePreset p) => p.reducedMotion
      ? const <BoxShadow>[]
      : [
          BoxShadow(
            color: p.isDark
                ? Colors.black.withValues(alpha: 0.32)
                : p.ink.withValues(alpha: 0.07),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ];

  /// The coloured light under a primary action.
  static Color glow(ThemePreset p) => Color.lerp(
    p.primary,
    p.jewel,
    0.5,
  )!.withValues(alpha: p.isDark ? 0.5 : 0.36);

  /// Fill and shadow for a panel. With no look on the theme this is the
  /// flat Today card, border included.
  static BoxDecoration panel(
    BuildContext context, {
    BorderRadius radius = const BorderRadius.all(Radius.circular(20)),
    Color? color,
    List<BoxShadow>? shadows,
  }) {
    final p = presetOf(context);
    final scheme = Theme.of(context).colorScheme;
    if (p == null) {
      return BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: shadows,
      );
    }
    final fill = color == null ? satin(p) : null;
    return BoxDecoration(
      color: fill == null ? (color ?? p.paper) : null,
      gradient: fill,
      borderRadius: radius,
      // A shadow shows through a translucent fill and would grey it (and
      // the text on it), so only an opaque panel is lifted.
      boxShadow: shadows ?? (color != null && color.a < 1 ? null : lift(p)),
    );
  }

  /// The bevelled hairline painted over a [panel]; null with no look.
  static Decoration? panelRim(
    BuildContext context, {
    BorderRadius radius = const BorderRadius.all(Radius.circular(20)),
  }) {
    final p = presetOf(context);
    return p == null ? null : ShapeDecoration(shape: rim(p, radius: radius));
  }
}

/// A rounded hairline whose colour runs along a gradient from the top-left
/// to the bottom-right, so an edge looks bevelled rather than drawn.
class CoutureBorder extends OutlinedBorder {
  const CoutureBorder({
    required this.colors,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.width = 1,
    super.side,
  });

  final List<Color> colors;
  final BorderRadius borderRadius;
  final double width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  CoutureBorder copyWith({BorderSide? side}) => CoutureBorder(
    colors: colors,
    borderRadius: borderRadius,
    width: width,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => CoutureBorder(
    colors: colors,
    borderRadius: borderRadius * t,
    width: width * t,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is CoutureBorder && a.colors.length == colors.length
      ? _lerpRim(a, this, t)
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is CoutureBorder && b.colors.length == colors.length
      ? _lerpRim(this, b, t)
      : super.lerpTo(b, t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.toRRect(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.toRRect(rect).deflate(width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) {
      return;
    }
    final paint = Paint()..style = PaintingStyle.stroke;
    // A button theme may hand this shape a solid side: honour it.
    if (side.style != BorderStyle.none && side.width > 0) {
      paint
        ..color = side.color
        ..strokeWidth = side.width;
      canvas.drawRRect(
        borderRadius.toRRect(rect).deflate(side.width / 2),
        paint,
      );
      return;
    }
    if (width <= 0 || colors.isEmpty) {
      return;
    }
    paint
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.length == 1 ? [colors.first, colors.first] : colors,
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(width / 2), paint);
  }

  @override
  bool operator ==(Object other) =>
      other is CoutureBorder &&
      listEquals(other.colors, colors) &&
      other.borderRadius == borderRadius &&
      other.width == width &&
      other.side == side;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(colors), borderRadius, width, side);
}

CoutureBorder _lerpRim(CoutureBorder a, CoutureBorder b, double t) =>
    CoutureBorder(
      colors: [
        for (var i = 0; i < a.colors.length; i++)
          Color.lerp(a.colors[i], b.colors[i], t)!,
      ],
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      width: a.width + (b.width - a.width) * t,
      side: BorderSide.lerp(a.side, b.side, t),
    );

/// Paints a primary action's finish under its label: the look's action
/// gradient, a soft light from above (or, under a light label, a shade
/// toward the foot), and a trim hairline that is bright at the top edge and
/// nearly gone at the foot.
class CoutureActionPainter extends CustomPainter {
  const CoutureActionPainter({
    required this.preset,
    this.shape = const StadiumBorder(),
    this.pressed = false,
    this.textDirection,
  });

  final ThemePreset preset;
  final ShapeBorder shape;
  final bool pressed;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final outline = shape.getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(
      outline,
      Paint()..shader = preset.actionGradient.createShader(rect),
    );
    // Calm holds still and flat: the gradient is tonal and nothing shines.
    if (!preset.reducedMotion) {
      // Depth must never cost the label its contrast. Under a dark label
      // the fill is lit from above (lighter, so the label reads better);
      // under a light label it deepens toward the foot instead.
      final darkLabel = preset.onPrimary.computeLuminance() < 0.5;
      final band = darkLabel
          ? Rect.fromLTWH(0, 0, size.width, size.height * 0.55)
          : Rect.fromLTWH(
              0,
              size.height * 0.35,
              size.width,
              size.height * 0.65,
            );
      final tone = darkLabel ? Colors.white : Colors.black;
      canvas
        ..save()
        ..clipPath(outline)
        ..drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              begin: darkLabel ? Alignment.topCenter : Alignment.bottomCenter,
              end: darkLabel ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                tone.withValues(alpha: darkLabel ? 0.2 : 0.16),
                tone.withValues(alpha: 0),
              ],
            ).createShader(band),
        )
        ..restore();
    }
    if (pressed) {
      canvas.drawPath(
        outline,
        Paint()..color = Colors.black.withValues(alpha: 0.14),
      );
    }
    canvas.drawPath(
      shape.getOuterPath(rect.deflate(0.5), textDirection: textDirection),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            preset.trim.withValues(alpha: 0.85),
            preset.trim.withValues(alpha: 0.12),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(CoutureActionPainter old) =>
      old.preset.id != preset.id ||
      old.shape != shape ||
      old.pressed != pressed ||
      old.textDirection != textDirection;
}

/// The background of a themed primary button (`FilledButton`,
/// `ElevatedButton`): [CoutureActionPainter] behind the label and, in the
/// cinematic looks, the passing [CinematicSheen].
///
/// A button whose call site chose its own fill (a destructive red, a tonal
/// tint) or that is disabled keeps that fill untouched: the finish is only
/// painted when the button's surface is the look's primary. The button's own
/// shape is followed, so a call site with squarer corners is dressed to
/// those corners.
class CoutureActionFill extends StatelessWidget {
  const CoutureActionFill({
    required this.child,
    this.states = const <WidgetState>{},
    this.sheen = false,
    super.key,
  });

  final Widget child;
  final Set<WidgetState> states;

  /// Whether the look's sheen glides over the fill (cinematic looks only).
  final bool sheen;

  @override
  Widget build(BuildContext context) {
    final preset = Couture.presetOf(context);
    final surface = context.findAncestorWidgetOfExactType<Material>();
    final dressed =
        preset != null &&
        surface != null &&
        surface.color == preset.primary &&
        !states.contains(WidgetState.disabled);
    // Always a CustomPaint (with no painter when plain) so the label is never
    // remounted when the button changes state.
    return CustomPaint(
      painter: dressed
          ? CoutureActionPainter(
              preset: preset,
              shape: surface.shape ?? const StadiumBorder(),
              pressed: states.contains(WidgetState.pressed),
              textDirection: Directionality.maybeOf(context),
            )
          : null,
      child: sheen
          ? CinematicSheen(
              enabled: !states.contains(WidgetState.disabled),
              child: child,
            )
          : child,
    );
  }
}

/// The short gradient rule that sits before an eyebrow: the look's primary
/// running into its jewel. Decorative; hidden from screen readers.
class CoutureRule extends StatelessWidget {
  const CoutureRule({this.width = 16, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    final p = Couture.presetOf(context);
    if (p == null) {
      return const SizedBox.shrink();
    }
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: width,
          height: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.primary, p.jewel]),
              borderRadius: const BorderRadius.all(Radius.circular(1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected destination in the tab bar: its icon set in a small jewel
/// pill, the same finish as a primary button. Unselected icons sit in a box
/// of the same height so the row never jumps.
class CoutureNavIcon extends StatelessWidget {
  const CoutureNavIcon(this.icon, {this.selected = false, super.key});

  final IconData icon;
  final bool selected;

  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final p = Couture.presetOf(context);
    if (!selected || p == null) {
      return SizedBox(height: height, child: Icon(icon));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(height / 2)),
        boxShadow: p.reducedMotion
            ? null
            : [
                BoxShadow(
                  color: Couture.glow(p).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: CustomPaint(
        painter: CoutureActionPainter(preset: p),
        child: SizedBox(
          width: 52,
          height: height,
          child: Icon(icon, size: 20, color: p.onPrimary),
        ),
      ),
    );
  }
}
