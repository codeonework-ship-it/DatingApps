import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glassmorphism container with crystal-like glossy highlights.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.blur = AppTheme.glassBlurRegular,
    this.opacity = AppTheme.glassLayerRegularOpacity,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useCrystal = AppTheme.forceCrystalEverywhere || crystalEffect;
    final baseColor =
        backgroundColor ??
        (isDark
            ? AppTheme.glassDark.withValues(alpha: opacity)
            : AppTheme.glassLight.withValues(alpha: opacity));
    final outerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.58);
    final innerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.34);

    final content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: border ?? Border.all(color: outerBorderColor, width: 1),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: AppTheme.trustBlue.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.28),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
              if (useCrystal)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        gradient: AppTheme.crystalSurfaceGradient,
                      ),
                    ),
                  ),
                ),
              if (useCrystal)
                Positioned(
                  top: -24,
                  left: -12,
                  right: 24,
                  height: 110,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: isDark ? 0.18 : 0.42,
                            ),
                            Colors.white.withValues(alpha: 0),
                          ],
                          radius: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(color: innerBorderColor, width: 0.95),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
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
    this.shinyEffect = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final bool shinyEffect;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  AnimationController? _shineController;

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
    if (widget.shinyEffect) {
      _shineController = AnimationController(
        duration: const Duration(milliseconds: 1900),
        vsync: this,
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shinyEffect == widget.shinyEffect) {
      return;
    }

    if (widget.shinyEffect) {
      _shineController = AnimationController(
        duration: const Duration(milliseconds: 1900),
        vsync: this,
      )..repeat();
    } else {
      _shineController?.dispose();
      _shineController = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shineController?.dispose();
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
    final buttonTextColor = widget.textColor ?? AppTheme.pureGoldInk;
    final baseColor = widget.backgroundColor ?? AppTheme.pureGoldCore;
    final radius = BorderRadius.circular(AppTheme.radiusM);
    final buttonStops = widget.shinyEffect
        ? const [0.0, 0.22, 0.54, 0.82, 1.0]
        : const [0.0, 0.5, 1.0];
    final buttonGradient = LinearGradient(
      colors: widget.shinyEffect
          ? [
              const Color(0xFFE0B238).withValues(alpha: 0.98),
              const Color(0xFFF0C54B).withValues(alpha: 0.99),
              const Color(0xFFF4CC61).withValues(alpha: 0.99),
              const Color(0xFFE8BB3F).withValues(alpha: 0.99),
              const Color(0xFFF1C95A).withValues(alpha: 0.98),
            ]
          : [
              const Color(0xFFE2B53B).withValues(alpha: 0.94),
              const Color(0xFFF0C54A).withValues(alpha: 0.96),
              const Color(0xFFE8BB40).withValues(alpha: 0.94),
            ],
      stops: buttonStops,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1 : 0.55,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GlassContainer(
            width: widget.width ?? double.infinity,
            padding: EdgeInsets.zero,
            borderRadius: radius,
            backgroundColor: baseColor.withValues(alpha: 0.34),
            blur: AppTheme.glassBlurThick,
            opacity: AppTheme.glassLayerThickOpacity,
            shadows: [
              BoxShadow(
                color: AppTheme.pureGoldBright.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: buttonGradient,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: radius,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            gradient: RadialGradient(
                              center: const Alignment(-0.85, -0.9),
                              radius: 1.35,
                              colors: [
                                AppTheme.pureGoldHighlight.withValues(
                                  alpha: 0.28,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.78],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: radius,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            gradient: RadialGradient(
                              center: const Alignment(0.95, 1.1),
                              radius: 1.1,
                              colors: [
                                const Color(0xFFFFC640).withValues(alpha: 0.34),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.78],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.shinyEffect)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: radius,
                          child: AnimatedBuilder(
                            animation: _shineController ?? _controller,
                            builder: (context, child) {
                              final t = _shineController?.value ?? 0;
                              final primaryLeft = -1.4 + (2.8 * t);
                              final primaryRight = primaryLeft + 0.96;
                              final secondaryLeft = -1.9 + (2.8 * t);
                              final secondaryRight = secondaryLeft + 0.82;

                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: radius,
                                      gradient: LinearGradient(
                                        begin: Alignment(primaryLeft, -1),
                                        end: Alignment(primaryRight, 1),
                                        colors: [
                                          Colors.transparent,
                                          const Color(
                                            0xFFFFE7A3,
                                          ).withValues(alpha: 0.18),
                                          Colors.white.withValues(alpha: 0.22),
                                          const Color(
                                            0xFFFFC640,
                                          ).withValues(alpha: 0.34),
                                          Colors.transparent,
                                        ],
                                        stops: const [
                                          0.0,
                                          0.35,
                                          0.52,
                                          0.66,
                                          1.0,
                                        ],
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: radius,
                                      gradient: LinearGradient(
                                        begin: Alignment(secondaryLeft, -1),
                                        end: Alignment(secondaryRight, 1),
                                        colors: [
                                          Colors.transparent,
                                          const Color(
                                            0xFFFFF0C9,
                                          ).withValues(alpha: 0.14),
                                          AppTheme.pureGoldBright.withValues(
                                            alpha: 0.28,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.45, 0.56, 1.0],
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: radius,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.pureGoldHighlight.withValues(
                                            alpha: 0.24,
                                          ),
                                          const Color(
                                            0xFFFFD36B,
                                          ).withValues(alpha: 0.08),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.36, 0.72],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.34),
                              Colors.white.withValues(alpha: 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                buttonTextColor,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: buttonTextColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: buttonTextColor),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
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
      Color(0x66FFFFFF),
      Color(0x2EC7F9FF),
      Color(0x00FFFFFF),
    ],
  });
  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors, radius: 0.9),
        ),
      ),
    ),
  );
}

/// Glossy shell for full-screen pages.
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
    final content = maxContentWidth == null
        ? paddedContent
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth!),
              child: paddedContent,
            ),
          );

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Stack(
        children: [
          const CrystalBloom(alignment: Alignment.topRight, size: 260),
          const CrystalBloom(
            alignment: Alignment.bottomLeft,
            size: 240,
            colors: [Color(0x4DFFFFFF), Color(0x2693C5FF), Color(0x00FFFFFF)],
          ),
          Positioned.fill(child: content),
        ],
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
    final content = maxContentWidth == null
        ? paddedContent
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth!),
              child: paddedContent,
            ),
          );

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.postLoginGradient),
      child: Stack(
        children: [
          const CrystalBloom(
            alignment: Alignment.topRight,
            size: 300,
            colors: [Color(0x42FFFFFF), Color(0x2D9ED6FF), Color(0x00FFFFFF)],
          ),
          const CrystalBloom(
            alignment: Alignment.bottomLeft,
            size: 270,
            colors: [Color(0x38FFFFFF), Color(0x2667E8F9), Color(0x00FFFFFF)],
          ),
          const CrystalBloom(
            alignment: Alignment.center,
            size: 220,
            colors: [Color(0x1FFFFFFF), Color(0x1486EFAC), Color(0x00FFFFFF)],
          ),
          Positioned.fill(child: content),
        ],
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
