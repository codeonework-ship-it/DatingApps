import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glassmorphism container with crystal-like glossy highlights.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
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
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.backgroundColor,
    this.textColor,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
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
    final buttonTextColor = widget.textColor ?? Colors.white;
    final baseColor = widget.backgroundColor ?? AppTheme.trustBlue;
    final radius = BorderRadius.circular(AppTheme.radiusM);

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
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: [
                    baseColor.withValues(alpha: 0.94),
                    AppTheme.crystalBlue.withValues(alpha: 0.88),
                    AppTheme.crystalMint.withValues(alpha: 0.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
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
                      vertical: 14,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
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
    super.key,
    required this.child,
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
    super.key,
    required this.child,
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
    super.key,
    required this.gradient,
    required this.style,
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
    super.key,
    required this.isLoading,
    required this.child,
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
