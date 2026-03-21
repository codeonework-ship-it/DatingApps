import 'package:flutter/material.dart';

/// Active design-system theme used by the app.
class AppTheme {
  AppTheme._();

  static const PageTransitionsTheme _burstPageTransitionsTheme =
      PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _BurstPageTransitionsBuilder(),
          TargetPlatform.iOS: _BurstPageTransitionsBuilder(),
          TargetPlatform.linux: _BurstPageTransitionsBuilder(),
          TargetPlatform.macOS: _BurstPageTransitionsBuilder(),
          TargetPlatform.windows: _BurstPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _BurstPageTransitionsBuilder(),
        },
      );

  // ==========================================================================
  // DESIGN TOKENS: COLORS
  // ==========================================================================

  // Core brand colors from the design spec
  static const Color trustBlue = Color(0xFF8C6A00);
  static const Color safetyGreen = Color(0xFF10B981);
  static const Color warmOrange = Color(0xFFC7920A);
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color accentCyan = Color(0xFFB88A12);
  static const Color crystalAqua = Color(0xFFE8C15A);
  static const Color crystalBlue = Color(0xFFD4A53A);
  static const Color crystalMint = Color(0xFFF0DDA4);
  static const Color crystalRose = Color(0xFFECC47C);
  static const Color crystalGoldDeep = Color(0xFF6E5200);
  static const Color crystalGoldSoft = Color(0xFFE2B84F);
  static const Color crystalGoldFog = Color(0xFFF7E8BE);
  static const Color pureGoldCore = Color(0xFFC88A12);
  static const Color pureGoldBright = Color(0xFFF4C84E);
  static const Color pureGoldHighlight = Color(0xFFFFE7A2);
  static const Color pureGoldInk = Color(0xFF2D1900);

  // Backward-compatible aliases used throughout existing screens
  static const Color primaryRed = trustBlue;
  static const Color primaryOrange = warmOrange;
  static const Color errorRed = alertRed;
  static const Color successGreen = safetyGreen;
  static const Color warningOrange = warmOrange;
  static const Color infoBlue = accentCyan;

  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textGrey = neutralGray;
  static const Color textHint = Color(0xFF94A3B8);

  // Glass layers (D1 spec)
  static const double glassLayerUltraOpacity = 0.46;
  static const double glassLayerRegularOpacity = 0.52;
  static const double glassLayerThickOpacity = 0.60;
  static const double glassBlurUltra = 14;
  static const double glassBlurRegular = 22;
  static const double glassBlurThick = 28;
  static const bool forceCrystalEverywhere = true;

  static const Color glassLight = Color(0xFFFFFFFF);
  static const Color glassDark = Color(0xFF1F2937);
  static final Color glassContainer = Colors.white.withValues(
    alpha: glassLayerRegularOpacity,
  );
  static final Color glassContainerBorder = Colors.white.withValues(
    alpha: 0.24,
  );

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B4300), crystalGoldDeep, crystalGoldSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient bgGradient = LinearGradient(
    colors: [
      Color(0xFF1F1403),
      Color(0xFF4C3307),
      Color(0xFF7A540E),
      Color(0xFFB7861E),
    ],
    stops: [0.0, 0.33, 0.72, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );

  /// Softer surface used after login for better readability.
  static const Gradient postLoginGradient = LinearGradient(
    colors: [
      Color(0xFFFFFBF1),
      Color(0xFFFFF2D9),
      Color(0xFFF9E3B8),
      Color(0xFFEFCD90),
    ],
    stops: [0.0, 0.28, 0.68, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );

  static const Gradient crystalSurfaceGradient = LinearGradient(
    colors: [Color(0x8CFFFFFF), Color(0x52FFFFFF), Color(0x24FFFFFF)],
    stops: [0.0, 0.46, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient crystalGlowGradient = LinearGradient(
    colors: [crystalGoldSoft, trustBlue, crystalMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================================
  // DESIGN TOKENS: TYPOGRAPHY / SPACING
  // ==========================================================================

  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 24;
  static const double radiusXL = 28;
  static const double buttonHeight = 48;
  static const double contentMaxWidth = 560;

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme.apply(fontFamily: 'Avenir Next');
    final isDark = brightness == Brightness.dark;
    final primaryText = isDark ? textLight : textDark;
    final secondaryText = isDark ? const Color(0xFFCBD5E1) : neutralGray;
    final hintText = isDark ? const Color(0xFF94A3B8) : textHint;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.4,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primaryText,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: hintText,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  static ButtonStyle _goldSlidingButtonStyle(
    Brightness brightness, {
    bool compact = false,
    bool outlined = false,
  }) {
    final textStyle = compact
        ? _buildTextTheme(
            brightness,
          ).titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : _buildTextTheme(
            brightness,
          ).labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700);

    return ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return pureGoldInk.withValues(alpha: 0.52);
        }
        return pureGoldInk;
      }),
      backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      ),
      side: outlined
          ? WidgetStatePropertyAll<BorderSide>(
              BorderSide(
                color: pureGoldHighlight.withValues(alpha: 0.82),
                width: 1.15,
              ),
            )
          : null,
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        compact
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      minimumSize: compact
          ? const WidgetStatePropertyAll<Size?>(Size(0, 40))
          : const WidgetStatePropertyAll<Size?>(Size.fromHeight(buttonHeight)),
      shadowColor: WidgetStatePropertyAll<Color>(
        pureGoldBright.withValues(
          alpha: brightness == Brightness.dark ? 0.34 : 0.24,
        ),
      ),
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.disabled)) {
          return 0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 0.6;
        }
        return compact ? 0.9 : 1.2;
      }),
      splashFactory: NoSplash.splashFactory,
      animationDuration: const Duration(milliseconds: 180),
      backgroundBuilder: (context, states, child) => _GoldButtonBackgroundLayer(
        states: states,
        outlined: outlined,
        child: child,
      ),
      foregroundBuilder: (context, states, child) =>
          _GoldButtonForegroundLayer(states: states, child: child),
    );
  }

  static ButtonStyle _goldSlidingIconButtonStyle(
    Brightness brightness,
  ) => ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return pureGoldInk.withValues(alpha: 0.5);
      }
      return pureGoldInk;
    }),
    backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
    ),
    fixedSize: const WidgetStatePropertyAll<Size>(Size(40, 40)),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.all(8),
    ),
    shadowColor: WidgetStatePropertyAll<Color>(
      pureGoldBright.withValues(
        alpha: brightness == Brightness.dark ? 0.34 : 0.24,
      ),
    ),
    elevation: WidgetStateProperty.resolveWith<double>((states) {
      if (states.contains(WidgetState.disabled)) {
        return 0;
      }
      if (states.contains(WidgetState.pressed)) {
        return 0.6;
      }
      return 1;
    }),
    splashFactory: NoSplash.splashFactory,
    animationDuration: const Duration(milliseconds: 180),
    backgroundBuilder: (context, states, child) => _GoldButtonBackgroundLayer(
      states: states,
      outlined: false,
      child: child,
    ),
    foregroundBuilder: (context, states, child) =>
        _GoldButtonForegroundLayer(states: states, child: child),
  );

  // ==========================================================================
  // LIGHT THEME
  // ==========================================================================

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: trustBlue,
      onPrimary: Colors.white,
      secondary: warmOrange,
      onSecondary: Colors.white,
      tertiary: safetyGreen,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: textDark,
      error: alertRed,
      onError: Colors.white,
      outline: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFF4DA),
      textTheme: _buildTextTheme(Brightness.light),
      pageTransitionsTheme: _burstPageTransitionsTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFFF1CF).withValues(alpha: 0.94),
        foregroundColor: textDark,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: _buildTextTheme(
          Brightness.light,
        ).headlineMedium?.copyWith(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFF7E4),
        elevation: 0,
        shadowColor: trustBlue.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.42)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.light),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.light),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.light, outlined: true),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.light, compact: true),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.62),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: crystalGoldDeep, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: alertRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: trustBlue,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFFF3D9),
        selectedColor: trustBlue,
        checkmarkColor: Colors.white,
        labelStyle: _buildTextTheme(Brightness.light).bodyMedium,
        secondaryLabelStyle: _buildTextTheme(
          Brightness.light,
        ).bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFDF4),
        elevation: 4,
        shadowColor: trustBlue.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pureGoldCore,
        foregroundColor: pureGoldInk,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _goldSlidingIconButtonStyle(Brightness.light),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: trustBlue,
        contentTextStyle: _buildTextTheme(Brightness.light).bodyMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: trustBlue,
        textColor: textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.42),
        thickness: 0.8,
      ),
    );
  }

  // ==========================================================================
  // DARK THEME
  // ==========================================================================

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: trustBlue,
      onPrimary: Colors.white,
      secondary: warmOrange,
      onSecondary: Colors.white,
      tertiary: safetyGreen,
      onTertiary: Colors.white,
      surface: Color(0xFF111827),
      onSurface: textLight,
      error: alertRed,
      onError: Colors.white,
      outline: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E0902),
      textTheme: _buildTextTheme(Brightness.dark),
      pageTransitionsTheme: _burstPageTransitionsTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF231803),
        foregroundColor: textLight,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: _buildTextTheme(
          Brightness.dark,
        ).headlineMedium?.copyWith(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.dark),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.dark),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.dark, outlined: true),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _goldSlidingButtonStyle(Brightness.dark, compact: true),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: crystalGoldSoft, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF241A06).withValues(alpha: 0.92),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pureGoldCore,
        foregroundColor: pureGoldInk,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _goldSlidingIconButtonStyle(Brightness.dark),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF251A05),
        contentTextStyle: _buildTextTheme(Brightness.dark).bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF111827).withValues(alpha: 0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: crystalGoldSoft,
        textColor: textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.16),
        thickness: 0.8,
      ),
    );
  }
}

class _BurstPageTransitionsBuilder extends PageTransitionsBuilder {
  const _BurstPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );

    final burstScale =
        TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.93, end: 1.035),
            weight: 46,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.035, end: 1),
            weight: 54,
          ),
        ]).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    final settle =
        Tween<Offset>(begin: const Offset(0, 0.028), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: settle,
        child: ScaleTransition(scale: burstScale, child: child),
      ),
    );
  }
}

class _GoldButtonBackgroundLayer extends StatelessWidget {
  const _GoldButtonBackgroundLayer({
    required this.states,
    required this.outlined,
    required this.child,
  });

  final Set<WidgetState> states;
  final bool outlined;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final radius = BorderRadius.circular(AppTheme.radiusM);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE0B238).withValues(alpha: disabled ? 0.58 : 0.98),
            const Color(0xFFF0C54B).withValues(alpha: disabled ? 0.56 : 0.99),
            const Color(0xFFF4CC61).withValues(alpha: disabled ? 0.54 : 0.99),
            const Color(0xFFE8BB3F).withValues(alpha: disabled ? 0.5 : 0.99),
            const Color(0xFFF1C95A).withValues(alpha: disabled ? 0.48 : 0.98),
          ],
          stops: const [0.0, 0.22, 0.54, 0.82, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: outlined
            ? Border.all(
                color: AppTheme.pureGoldHighlight.withValues(
                  alpha: disabled ? 0.42 : 0.82,
                ),
                width: 1.15,
              )
            : null,
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppTheme.pureGoldBright.withValues(alpha: 0.24),
                  blurRadius: pressed ? 12 : 20,
                  offset: Offset(0, pressed ? 4 : 9),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: pressed ? 6 : 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _GoldButtonForegroundLayer extends StatefulWidget {
  const _GoldButtonForegroundLayer({required this.states, required this.child});

  final Set<WidgetState> states;
  final Widget? child;

  @override
  State<_GoldButtonForegroundLayer> createState() =>
      _GoldButtonForegroundLayerState();
}

class _GoldButtonForegroundLayerState extends State<_GoldButtonForegroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _GoldButtonForegroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final disabled = widget.states.contains(WidgetState.disabled);
    if (disabled) {
      _controller.stop();
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.states.contains(WidgetState.disabled);
    final radius = BorderRadius.circular(AppTheme.radiusM);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (widget.child != null) widget.child!,
          if (!disabled)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final left = -1.3 + (2.6 * t);
                    final right = left + 0.78;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(left, -1),
                          end: Alignment(right, 1),
                          colors: [
                            Colors.transparent,
                            AppTheme.pureGoldHighlight.withValues(alpha: 0.14),
                            Colors.white.withValues(alpha: 0.24),
                            AppTheme.pureGoldBright.withValues(alpha: 0.34),
                            Colors.white.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.32, 0.46, 0.58, 0.72, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.pureGoldHighlight.withValues(
                        alpha: disabled ? 0.18 : 0.34,
                      ),
                      Colors.white.withValues(alpha: disabled ? 0.04 : 0.08),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 0.6],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
