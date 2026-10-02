import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/app_l10n.dart';
import '../theme/app_theme.dart';
import '../theme/cinematic_effects.dart';
import '../theme/couture.dart';
import '../theme/theme_atmosphere.dart';
import '../theme/theme_presets.dart';

/// Shared bordered surface, drawn the way Today draws its cards: the
/// theme's paper colour, a hairline border and a 20pt radius, finished by
/// [Couture] (satin fill, bevelled hairline, a soft lift) unless the call
/// site brings its own [border]. Legacy name and parameters retained for
/// existing consumers; [blur], [opacity] and [crystalEffect] no longer change
/// the look.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.blur = AppTheme.glassBlurRegular,
    this.opacity = AppTheme.glassLayerRegularOpacity,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.border,
    this.shadows,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
    this.crystalEffect = true,
  });
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Border? border;
  final List<BoxShadow>? shadows;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool crystalEffect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      width: width,
      height: height,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: border == null
          ? Couture.panel(
              context,
              radius: borderRadius,
              color: backgroundColor,
              shadows: shadows,
            )
          : BoxDecoration(
              color: backgroundColor ?? scheme.surface,
              borderRadius: borderRadius,
              border: border,
              boxShadow: shadows ?? const <BoxShadow>[],
            ),
      foregroundDecoration: border == null
          ? Couture.panelRim(context, radius: borderRadius)
          : null,
      padding: padding,
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Animated glossy glass button.
class GlassButton extends StatefulWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.fontWeight,
    this.shinyEffect = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final FontWeight? fontWeight;

  /// No longer read. Kept so existing call sites compile.
  @Deprecated('No longer has any effect; remove this argument from call sites.')
  final bool shinyEffect;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    final onPressed = widget.onPressed;
    if (onPressed == null || widget.isLoading) {
      return;
    }
    onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final scheme = Theme.of(context).colorScheme;
    final fill = widget.backgroundColor ?? scheme.primary;
    final buttonTextColor = widget.textColor ?? scheme.onPrimary;
    final radius = BorderRadius.circular(999);
    final width = widget.width;

    final content = Container(
      width: width ?? double.infinity,
      constraints: const BoxConstraints(minHeight: AppTheme.buttonHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: widget.isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: buttonTextColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: buttonTextColor,
                      fontWeight: widget.fontWeight ?? FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
    // A button in the look's own primary gets the couture finish (primary
    // rolling into the jewel, a trim hairline, coloured light underneath); a
    // call site that chose its own fill keeps it flat.
    final preset = Couture.presetOf(context);
    final dressed =
        preset != null && widget.backgroundColor == null && isEnabled;
    // The fill, then the cinematic looks' passing sheen, then the label.
    final buttonChild = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: fill,
        boxShadow: dressed && !preset.reducedMotion
            ? [
                BoxShadow(
                  color: Couture.glow(preset).withValues(alpha: 0.34),
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: dressed ? CoutureActionPainter(preset: preset) : null,
        child: CinematicSheen(
          enabled: isEnabled,
          borderRadius: radius,
          child: content,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.isLoading
          ? l10nOrEnglish(context).commonLoadingLabel(widget.label)
          : widget.label,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: isEnabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled ? _onTapDown : null,
          onTapUp: isEnabled ? _onTapUp : null,
          onTapCancel: isEnabled ? _onTapCancel : null,
          child: ScaleTransition(scale: _scaleAnimation, child: buttonChild),
        ),
      ),
    );
  }
}

/// Compact gold navigation control used by auth/onboarding screens.
class GoldBackButton extends StatelessWidget {
  const GoldBackButton({required this.onTap, super.key, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tooltip ?? l10nOrEnglish(context).commonBack,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(
              color: switch (Couture.presetOf(context)) {
                final p? => Color.lerp(p.ruleStrong, p.trim, 0.6)!,
                null => scheme.outlineVariant,
              },
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: scheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Soft crystal highlight blob to layer over gradient backgrounds.
class CrystalBloom extends StatelessWidget {
  const CrystalBloom({
    super.key,
    this.alignment = Alignment.topRight,
    this.size = 220,
    this.colors = const [
      Color(0x66FF5C7A),
      Color(0x1FFF5C7A),
      Color(0x00FF5C7A),
    ],
  });
  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: SizedBox(
        // Oversized and mostly transparent. The previous bloom held ~18% alpha
        // across its middle, which gave the falloff a plateau and made it read
        // as a flat grey disc pasted on the ground rather than light in it.
        width: size * 1.9,
        height: size * 1.9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors,
              stops: const [0, 0.34, 0.82],
              radius: 0.62,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Full-screen page shell on the theme's flat ground, like Today.
class CrystalScaffold extends StatelessWidget {
  const CrystalScaffold({
    required this.child,
    super.key,
    this.padding,
    this.maxContentWidth = AppTheme.contentMaxWidth,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final paddedContent = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.groundGradientOf(context)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = MediaQuery.sizeOf(context);
            final maxWidth =
                constraints.hasBoundedWidth &&
                    constraints.maxWidth.isFinite &&
                    constraints.maxWidth > 0
                ? constraints.maxWidth
                : viewport.width;
            final maxHeight =
                constraints.hasBoundedHeight &&
                    constraints.maxHeight.isFinite &&
                    constraints.maxHeight > 0
                ? constraints.maxHeight
                : viewport.height;

            final contentWidth = maxContentWidth == null
                ? maxWidth
                : maxContentWidth!.clamp(0, maxWidth).toDouble();

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      height: maxHeight,
                      child: paddedContent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Light glossy shell used for post-login tab pages.
class PostLoginBackdrop extends StatelessWidget {
  const PostLoginBackdrop({
    required this.child,
    super.key,
    this.padding,
    this.maxContentWidth = AppTheme.contentMaxWidth,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final paddedContent = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.groundGradientOf(context)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = MediaQuery.sizeOf(context);
            final maxWidth =
                constraints.hasBoundedWidth &&
                    constraints.maxWidth.isFinite &&
                    constraints.maxWidth > 0
                ? constraints.maxWidth
                : viewport.width;
            final maxHeight =
                constraints.hasBoundedHeight &&
                    constraints.maxHeight.isFinite &&
                    constraints.maxHeight > 0
                ? constraints.maxHeight
                : viewport.height;

            final contentWidth = maxContentWidth == null
                ? maxWidth
                : maxContentWidth!.clamp(0, maxWidth).toDouble();

            final themed = Theme.of(
              context,
            ).extension<ConnectPalette>()?.preset;
            // A reduced-motion look (Calm) gets the flat ground alone.
            final still = themed?.reducedMotion ?? false;
            final cinematic =
                !still && themed != null && !ThemePresets.isEveryday(themed);
            return Stack(
              fit: StackFit.expand,
              children: [
                // Today's look: the classic family sits on a flat ground;
                // only the cinematic looks paint an atmosphere scene.
                if (cinematic) ThemeAtmosphere(preset: themed),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      height: maxHeight,
                      child: paddedContent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Gradient text widget.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    required this.gradient,
    required this.style,
    super.key,
  });
  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) =>
        gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
    child: Text(text, style: style.copyWith(color: Colors.white)),
  );
}

/// Animated loading overlay.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.message,
  });
  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading)
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.crystalBlue,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}
