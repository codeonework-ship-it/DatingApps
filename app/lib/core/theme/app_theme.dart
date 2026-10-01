import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'cinematic_motion.dart';
import 'theme_presets.dart';

/// Afterdark Ember design tokens.
///
/// The system is dark-first: a plum-black ground lit from below by an ember
/// glow, with a raspberry-to-coral primary, an electric violet secondary and
/// amber gold reserved for premium moments (gifts, boosts, spotlight). Display
/// type is the bundled Bodoni Moda serif; interface type is Figtree.
///
/// Legacy token names (iris, aqua, marigold, crystal*, pureGold*, trustBlue…)
/// are kept as aliases so every existing screen picks up the new palette
/// without call-site churn.
class AppTheme {
  AppTheme._();

  /// Every platform uses the cinematic cut: a depth cut in the cinematic
  /// looks, a quiet fade-and-rise in the everyday looks, nothing under
  /// reduced motion, and the iOS swipe-back gesture kept.
  static const PageTransitionsTheme _burstPageTransitionsTheme =
      PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CinematicPageTransitionsBuilder(),
          TargetPlatform.iOS: CinematicPageTransitionsBuilder(),
          TargetPlatform.linux: CinematicPageTransitionsBuilder(),
          TargetPlatform.macOS: CinematicPageTransitionsBuilder(),
          TargetPlatform.windows: CinematicPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CinematicPageTransitionsBuilder(),
        },
      );

  // ---------------------------------------------------------------------------
  // Ground & paper
  // ---------------------------------------------------------------------------

  /// Light ground: warm blush cream rather than clinical white.
  static const Color ground = Color(0xFFFFF7F3);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color paperSunk = Color(0xFFF8ECE8);

  /// Dark ground: plum-black. Reads as night-out lighting, not "off".
  static const Color groundDark = Color(0xFF0E0A14);
  static const Color paperDark = Color(0xFF1C1426);
  static const Color paperSunkDark = Color(0xFF150E1E);

  // ---------------------------------------------------------------------------
  // Ink
  // ---------------------------------------------------------------------------

  static const Color ink = Color(0xFF1F1024);
  static const Color inkMuted = Color(0xFF6A5570);
  static const Color inkFaint = Color(0xFF80708A);
  static const Color inkOnDark = Color(0xFFFBF4F7);
  static const Color inkMutedOnDark = Color(0xFFCDBFD3);
  static const Color inkFaintOnDark = Color(0xFF9C8BA5);

  static const Color rule = Color(0xFFF1DFE2);
  static const Color ruleStrong = Color(0xFFDDC4CA);
  static const Color ruleDark = Color(0xFF34263F);

  // ---------------------------------------------------------------------------
  // Ember — primary. Raspberry on light, coral-neon on dark.
  // ---------------------------------------------------------------------------

  static const Color ember = Color(0xFFB8143F);
  static const Color emberBright = Color(0xFFFF5C7A);
  static const Color emberDeep = Color(0xFF8F0F32);
  static const Color emberHot = Color(0xFFE8385F);
  static const Color emberPale = Color(0xFFFFC2CE);
  static const Color emberTint = Color(0xFFFFEEF1);
  static const Color emberTintDark = Color(0xFF3A1626);

  // ---------------------------------------------------------------------------
  // Violet — secondary. Electric, used for chat, energy and highlights.
  // ---------------------------------------------------------------------------

  static const Color violet = Color(0xFF6D3FD6);
  static const Color violetDeep = Color(0xFF4E2AA8);
  static const Color violetBright = Color(0xFFB79CFF);
  static const Color violetTint = Color(0xFFEFE8FF);
  static const Color violetTintDark = Color(0xFF2A1D45);

  // ---------------------------------------------------------------------------
  // Gold — tertiary. Premium, gifts, spotlight, streaks.
  // ---------------------------------------------------------------------------

  static const Color gold = Color(0xFFB9700A);
  static const Color goldBright = Color(0xFFF5A623);
  static const Color goldHighlight = Color(0xFFFFD98A);
  static const Color goldTint = Color(0xFFFFF3DD);

  // ---------------------------------------------------------------------------
  // Mint — success / verified / safe.
  // ---------------------------------------------------------------------------

  static const Color mint = Color(0xFF178A62);
  static const Color mintDeep = Color(0xFF0F6B4B);
  static const Color mintBright = Color(0xFF4FD8A6);
  static const Color mintTint = Color(0xFFE3F8EF);

  static const Color danger = Color(0xFFD4381C);
  static const Color dangerOnDark = Color(0xFFFF7A5C);
  static const Color warning = Color(0xFFF08A24);
  static const Color info = violet;

  // ---------------------------------------------------------------------------
  // Legacy aliases — every existing screen resolves through these.
  // ---------------------------------------------------------------------------

  static const Color iris = ember;
  static const Color irisBright = emberBright;
  static const Color irisDeep = emberDeep;
  static const Color irisPale = emberPale;
  static const Color irisTint = emberTint;
  static const Color irisTintDark = emberTintDark;

  static const Color aqua = mint;
  static const Color aquaDeep = mintDeep;
  static const Color aquaBright = mintBright;
  static const Color aquaTint = mintTint;

  static const Color marigold = gold;
  static const Color marigoldBright = goldBright;
  static const Color marigoldHighlight = goldHighlight;
  static const Color marigoldTint = goldTint;

  static const Color armourRed = ember;
  static const Color armourRedBright = emberBright;
  static const Color armourGold = gold;
  static const Color armourGoldBright = goldBright;

  static const Color arcCore = Color(0xFFFFF0F4);
  static const Color arcGlow = emberBright;
  static const Color arcDeep = emberDeep;

  static const Color circuitLine = Color(0x1AFF5C7A);
  static const Color circuitNode = Color(0x33B79CFF);

  static const Color trustBlue = ember;
  static const Color safetyGreen = mint;
  static const Color warmOrange = warning;
  static const Color neutralGray = inkMuted;
  static const Color alertRed = danger;

  static const Color accentCyan = violet;
  static const Color crystalAqua = violetBright;
  static const Color crystalBlue = emberBright;
  static const Color crystalMint = mintTint;
  static const Color crystalRose = Color(0xFFFF8FA8);
  static const Color crystalGoldDeep = emberDeep;

  static const Color crystalGoldSoft = emberBright;
  static const Color crystalGoldFog = emberTint;
  static const Color pureGoldCore = gold;
  static const Color pureGoldBright = goldBright;
  static const Color pureGoldHighlight = goldHighlight;

  static const Color pureGoldInk = ink;

  static const Color primaryRed = ember;
  static const Color primaryOrange = warning;
  static const Color errorRed = danger;
  static const Color successGreen = mint;
  static const Color warningOrange = warning;
  static const Color infoBlue = violet;

  static const Color textDark = ink;
  static const Color textLight = inkOnDark;
  static const Color textGrey = inkMuted;
  static const Color textHint = inkFaint;

  // ---------------------------------------------------------------------------
  // Glass
  // ---------------------------------------------------------------------------

  static const double glassLayerUltraOpacity = 0.10;
  static const double glassLayerRegularOpacity = 0.14;
  static const double glassLayerThickOpacity = 0.20;
  static const double glassBlurUltra = 20;
  static const double glassBlurRegular = 28;
  static const double glassBlurThick = 36;

  static const bool forceCrystalEverywhere = false;

  static const Color glassLight = Color(0xFFFFFFFF);
  static const Color glassDark = Color(0xFFFFFFFF);
  static final Color glassContainer = Colors.white.withValues(
    alpha: glassLayerRegularOpacity,
  );
  static final Color glassContainerBorder = Colors.white.withValues(
    alpha: 0.28,
  );

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Primary action fill: deep raspberry rolling into hot coral.
  static const Gradient primaryGradient = LinearGradient(
    colors: [emberDeep, ember, emberHot],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The signature "aurora": ember → violet → gold. Used sparingly on hero
  /// moments (brand mark, match celebrations, primary CTA hairlines).
  static const Gradient auroraGradient = LinearGradient(
    colors: [emberBright, violetBright, goldBright],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Pre-login ground: plum-black warmed by an ember glow at the foot.
  static const Gradient bgGradient = LinearGradient(
    colors: [
      Color(0xFF0B0812),
      Color(0xFF130C1E),
      Color(0xFF1E1029),
      Color(0xFF2B1230),
      Color(0xFF3A1230),
    ],
    stops: [0.0, 0.28, 0.56, 0.82, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient postLoginGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFF7F3),
      Color(0xFFFDF2EE),
      Color(0xFFFBEDEA),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );

  static const Gradient postLoginGradientDark = LinearGradient(
    colors: [
      Color(0xFF0E0A14),
      Color(0xFF120C1B),
      Color(0xFF170F22),
      Color(0xFF1C1128),
    ],
    stops: [0.0, 0.34, 0.72, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );

  static Gradient groundGradientOf(BuildContext context) {
    final palette = Theme.of(context).extension<ConnectPalette>();
    if (palette != null) {
      final preset = palette.preset;
      // Everyday looks match Today: one flat ground colour, no blush.
      return ThemePresets.isEveryday(preset)
          ? LinearGradient(colors: [preset.ground, preset.ground])
          : preset.groundGradient;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? postLoginGradientDark
        : postLoginGradient;
  }

  /// Whether motion should be held back here: the platform's reduce-motion
  /// setting, or a palette that asks for it ([ThemePreset.reducedMotion]).
  ///
  /// Every animation that already defers to
  /// `MediaQuery.disableAnimationsOf` should ask this instead, so the Calm
  /// look and the OS setting are honoured by the same code path.
  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      (Theme.of(context).extension<ConnectPalette>()?.preset.reducedMotion ??
          false);

  static const Gradient chromeGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFF8F5),
      Color(0xFFF6E3E6),
      Color(0xFFFBEFEC),
      Color(0xFFFFFCFB),
    ],
    stops: [0.0, 0.22, 0.52, 0.78, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gunmetalGradient = LinearGradient(
    colors: [
      Color(0xFF2A1C36),
      Color(0xFF20152C),
      Color(0xFF160E1F),
      Color(0xFF241730),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient energonGradient = LinearGradient(
    colors: [emberDeep, ember, violet, violetBright],
    stops: [0.0, 0.42, 0.78, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient crystalSurfaceGradient = LinearGradient(
    colors: [
      Color(0x59FFFFFF),
      Color(0x0DFFFFFF),
      Color(0x00FFFFFF),
      Color(0x1AFFFFFF),
    ],
    stops: [0.0, 0.30, 0.72, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient crystalGlowGradient = auroraGradient;

  // ---------------------------------------------------------------------------
  // Shape & metrics
  // ---------------------------------------------------------------------------

  static const double radiusS = 14;
  static const double radiusM = 20;
  static const double radiusL = 28;

  static const double chamfer = 14;
  static const double chamferSmall = 8;
  static const double radiusXL = 34;
  static const double buttonHeight = 54;
  static const double contentMaxWidth = 560;

  static List<BoxShadow> get shadow1 => [
    BoxShadow(
      color: ink.withValues(alpha: 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get shadow2 => [
    BoxShadow(
      color: ink.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Coloured light bleed under a primary surface. The difference between a
  /// button and a button that looks lit.
  static List<BoxShadow> get emberGlow => [
    BoxShadow(
      color: emberBright.withValues(alpha: 0.38),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: emberDeep.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get violetGlow => [
    BoxShadow(
      color: violetBright.withValues(alpha: 0.32),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Type
  // ---------------------------------------------------------------------------

  /// Serif display family. Bundled; see pubspec fonts.
  static const String displayFamily = 'Bodoni Moda';
  static const String _displayFamily = displayFamily;
  static const List<String> _displayFallback = <String>[
    'Bodoni Moda',
    'Georgia',
    'serif',
  ];

  static const String _technicalFamily = 'Figtree';
  static const List<String> _technicalFallback = <String>[
    'Figtree',
    'sans-serif',
  ];

  static TextStyle technical(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 1.1,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: _technicalFamily,
    fontFamilyFallback: _technicalFallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Interface family.
  static const String uiFamily = 'Figtree';
  static const String _uiFamily = uiFamily;
  static const List<String> _uiFallback = <String>[
    'Avenir Next',
    'Avenir',
    'Helvetica Neue',
    'Roboto',
    'sans-serif',
  ];

  /// Serif display style for hero copy outside the text theme.
  static TextStyle display(
    double size,
    Color color, {
    double height = 1.04,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
    double tracking = -0.01,
  }) => TextStyle(
    fontFamily: _displayFamily,
    fontFamilyFallback: _displayFallback,
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    color: color,
    height: height,
    letterSpacing: size * tracking,
  );

  static TextStyle _display(
    double size,
    Color color, {
    double height = 1.04,
    FontWeight weight = FontWeight.w600,
    double tracking = -0.01,
  }) =>
      display(size, color, height: height, weight: weight, tracking: tracking);

  static TextStyle _ui({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: _uiFamily,
    fontFamilyFallback: _uiFallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryText = isDark ? inkOnDark : ink;
    final secondaryText = isDark ? inkMutedOnDark : inkMuted;
    final hintText = isDark ? inkFaintOnDark : inkFaint;

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: _uiFamily,
      brightness: brightness,
    ).textTheme;

    return base.copyWith(
      displayLarge: _display(44, primaryText, height: 1, tracking: -0.015),
      displayMedium: _display(38, primaryText, height: 1.02),
      displaySmall: _display(30, primaryText, height: 1.1),
      headlineLarge: _display(28, primaryText, height: 1.12),
      headlineMedium: _display(
        24,
        primaryText,
        height: 1.16,
        weight: FontWeight.w600,
      ),
      headlineSmall: _display(21, primaryText, height: 1.2),

      titleLarge: _ui(
        size: 19,
        weight: FontWeight.w700,
        color: primaryText,
        height: 1.3,
        letterSpacing: -0.3,
      ),
      titleMedium: _ui(
        size: 16,
        weight: FontWeight.w600,
        color: primaryText,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      titleSmall: _ui(
        size: 14,
        weight: FontWeight.w600,
        color: primaryText,
        height: 1.4,
      ),
      bodyLarge: _ui(
        size: 16,
        weight: FontWeight.w400,
        color: primaryText,
        height: 1.55,
      ),
      bodyMedium: _ui(
        size: 14,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.5,
      ),
      bodySmall: _ui(
        size: 12.5,
        weight: FontWeight.w400,
        color: hintText,
        height: 1.45,
      ),
      labelSmall: technical(
        11,
        secondaryText,
        weight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
      labelMedium: technical(
        12.5,
        secondaryText,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      labelLarge: technical(
        15,
        primaryText,
        weight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Component styles
  // ---------------------------------------------------------------------------

  static ButtonStyle _primaryButtonStyle(
    Brightness brightness, {
    bool compact = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final fill = isDark ? emberBright : ember;
    final pressedFill = isDark ? emberHot : emberDeep;
    final onFill = isDark ? ink : Colors.white;

    return ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        _ui(
          size: compact ? 14 : 15,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.disabled)
            ? onFill.withValues(alpha: 0.55)
            : onFill,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return fill.withValues(alpha: 0.32);
        }
        if (states.contains(WidgetState.pressed)) {
          return pressedFill;
        }
        return fill;
      }),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      shadowColor: WidgetStatePropertyAll<Color>(
        fill.withValues(alpha: isDark ? 0.45 : 0.35),
      ),
      elevation: WidgetStateProperty.resolveWith<double>(
        (states) =>
            states.contains(WidgetState.disabled) ||
                states.contains(WidgetState.pressed)
            ? 0
            : 6,
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        compact
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      minimumSize: compact
          ? const WidgetStatePropertyAll<Size?>(Size(0, 40))
          : const WidgetStatePropertyAll<Size?>(Size.fromHeight(buttonHeight)),
      animationDuration: const Duration(milliseconds: 140),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static ButtonStyle _outlinedButtonStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final label = isDark ? inkOnDark : ink;
    final border = isDark ? ruleDark : ruleStrong;
    final accent = isDark ? emberBright : ember;

    return ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        _ui(size: 15, weight: FontWeight.w600),
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.disabled)
            ? label.withValues(alpha: 0.4)
            : label,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.pressed)
            ? (isDark ? paperSunkDark : paperSunk)
            : Colors.transparent,
      ),
      side: WidgetStateProperty.resolveWith<BorderSide>(
        (states) => BorderSide(
          color: states.contains(WidgetState.pressed) ? accent : border,
          width: 1.2,
        ),
      ),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      minimumSize: const WidgetStatePropertyAll<Size?>(
        Size.fromHeight(buttonHeight),
      ),
      animationDuration: const Duration(milliseconds: 140),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static ButtonStyle _textButtonStyle(Brightness brightness) {
    final accent = brightness == Brightness.dark ? emberBright : ember;
    return ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        _ui(size: 15, weight: FontWeight.w600),
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.disabled)
            ? accent.withValues(alpha: 0.45)
            : accent,
      ),
      backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, 40)),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static ButtonStyle _iconButtonStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? inkMutedOnDark : inkMuted;
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.disabled)
            ? fg.withValues(alpha: 0.4)
            : fg,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.pressed)
            ? (isDark ? paperSunkDark : paperSunk)
            : Colors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
      fixedSize: const WidgetStatePropertyAll<Size>(Size(42, 42)),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.all(8),
      ),
      animationDuration: const Duration(milliseconds: 140),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static InputDecorationTheme _inputTheme(
    Brightness brightness,
    TextTheme textTheme,
  ) {
    final isDark = brightness == Brightness.dark;
    final fill = isDark ? paperSunkDark : paper;
    final line = isDark ? ruleDark : ruleStrong;
    final focus = isDark ? emberBright : ember;
    final error = isDark ? dangerOnDark : danger;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: textTheme.bodyLarge?.copyWith(
        color: isDark ? inkFaintOnDark : inkFaint,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: isDark ? inkMutedOnDark : inkMuted,
      ),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: focus,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: isDark ? inkFaintOnDark : inkFaint,
      suffixIconColor: isDark ? inkFaintOnDark : inkFaint,
      border: border(line),
      enabledBorder: border(line),
      focusedBorder: border(focus, 1.8),
      errorBorder: border(error),
      focusedErrorBorder: border(error, 1.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // ---------------------------------------------------------------------------
  // Themes
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: ember,
      onPrimary: Colors.white,
      primaryContainer: emberTint,
      onPrimaryContainer: emberDeep,
      secondary: violet,
      onSecondary: Colors.white,
      secondaryContainer: violetTint,
      onSecondaryContainer: violetDeep,
      tertiary: gold,
      onTertiary: ink,
      tertiaryContainer: goldTint,
      onTertiaryContainer: ink,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      error: danger,
      onError: Colors.white,
      outline: rule,
      outlineVariant: ruleStrong,
      surfaceContainerHighest: paperSunk,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _buildTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      fontFamily: _uiFamily,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ground,
      textTheme: textTheme,
      pageTransitionsTheme: _burstPageTransitionsTheme,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ground,
        foregroundColor: ink,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        shadowColor: ink.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: const BorderSide(color: rule),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(Brightness.light),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(Brightness.light),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(Brightness.light),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(Brightness.light),
      ),
      inputDecorationTheme: _inputTheme(Brightness.light, textTheme),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: ember,
        unselectedItemColor: inkFaint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: emberTint,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium?.copyWith(letterSpacing: 0.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paperSunk,
        selectedColor: emberTint,
        checkmarkColor: ember,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: inkMuted,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: ember,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: rule),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        elevation: 0,
        shadowColor: ink.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ember,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(Brightness.light),
      ),
      iconTheme: const IconThemeData(color: inkMuted, size: 22),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: inkOnDark,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
        showDragHandle: true,
        dragHandleColor: ruleStrong,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) =>
              states.contains(WidgetState.selected) ? ember : ruleStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ember,
        inactiveTrackColor: rule,
        thumbColor: ember,
        overlayColor: ember.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ember,
        linearTrackColor: rule,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: inkFaint,
        indicatorColor: ember,
        dividerColor: rule,
      ),
      dividerTheme: const DividerThemeData(color: rule, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: emberBright,
      onPrimary: ink,
      primaryContainer: emberTintDark,
      onPrimaryContainer: emberPale,
      secondary: violetBright,
      onSecondary: ink,
      secondaryContainer: violetTintDark,
      onSecondaryContainer: violetBright,
      tertiary: goldBright,
      onTertiary: ink,
      tertiaryContainer: Color(0xFF3A2A12),
      onTertiaryContainer: goldHighlight,
      surface: paperDark,
      onSurface: inkOnDark,
      onSurfaceVariant: inkMutedOnDark,
      error: dangerOnDark,
      onError: ink,
      outline: ruleDark,
      outlineVariant: Color(0xFF4A3859),
      surfaceContainerHighest: paperSunkDark,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _buildTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      fontFamily: _uiFamily,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: groundDark,
      textTheme: textTheme,
      pageTransitionsTheme: _burstPageTransitionsTheme,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: groundDark,
        foregroundColor: inkOnDark,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: paperDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: const BorderSide(color: ruleDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(Brightness.dark),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(Brightness.dark),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(Brightness.dark),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(Brightness.dark),
      ),
      inputDecorationTheme: _inputTheme(Brightness.dark, textTheme),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: emberBright,
        unselectedItemColor: inkFaintOnDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: emberTintDark,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium?.copyWith(letterSpacing: 0.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paperSunkDark,
        selectedColor: emberTintDark,
        checkmarkColor: emberBright,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: inkMutedOnDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: emberBright,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: ruleDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paperDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emberBright,
        foregroundColor: ink,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(Brightness.dark),
      ),
      iconTheme: const IconThemeData(color: inkMutedOnDark, size: 22),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A1C36),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: inkOnDark,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: paperDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
        showDragHandle: true,
        dragHandleColor: ruleDark,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkMutedOnDark,
        textColor: inkOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) =>
              states.contains(WidgetState.selected) ? emberBright : ruleDark,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: emberBright,
        inactiveTrackColor: ruleDark,
        thumbColor: emberBright,
        overlayColor: emberBright.withValues(alpha: 0.16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: emberBright,
        linearTrackColor: ruleDark,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: inkOnDark,
        unselectedLabelColor: inkFaintOnDark,
        indicatorColor: emberBright,
        dividerColor: ruleDark,
      ),
      dividerTheme: const DividerThemeData(color: ruleDark, thickness: 1),
    );
  }
}

class ChamferBorder extends OutlinedBorder {
  const ChamferBorder({
    super.side,
    this.cut = AppTheme.chamfer,
    this.topLeft = false,
    this.topRight = true,
    this.bottomRight = false,
    this.bottomLeft = true,
  });

  final double cut;
  final bool topLeft;
  final bool topRight;
  final bool bottomRight;
  final bool bottomLeft;

  @override
  ChamferBorder copyWith({BorderSide? side, double? cut}) => ChamferBorder(
    side: side ?? this.side,
    cut: cut ?? this.cut,
    topLeft: topLeft,
    topRight: topRight,
    bottomRight: bottomRight,
    bottomLeft: bottomLeft,
  );

  Path _build(Rect rect) {
    final c = math.min(cut, math.min(rect.width, rect.height) / 2);
    final path = Path()
      ..moveTo(rect.left + (topLeft ? c : 0), rect.top)
      ..lineTo(rect.right - (topRight ? c : 0), rect.top);
    if (topRight) {
      path.lineTo(rect.right, rect.top + c);
    }
    path.lineTo(rect.right, rect.bottom - (bottomRight ? c : 0));
    if (bottomRight) {
      path.lineTo(rect.right - c, rect.bottom);
    }
    path.lineTo(rect.left + (bottomLeft ? c : 0), rect.bottom);
    if (bottomLeft) {
      path.lineTo(rect.left, rect.bottom - c);
    }
    path.lineTo(rect.left, rect.top + (topLeft ? c : 0));
    if (topLeft) {
      path.lineTo(rect.left + c, rect.top);
    }
    return path..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _build(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) {
      return;
    }
    canvas.drawPath(_build(rect.deflate(side.strokeInset)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => ChamferBorder(
    side: side.scale(t),
    cut: cut * t,
    topLeft: topLeft,
    topRight: topRight,
    bottomRight: bottomRight,
    bottomLeft: bottomLeft,
  );

  @override
  bool operator ==(Object other) =>
      other is ChamferBorder &&
      other.side == side &&
      other.cut == cut &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode =>
      Object.hash(side, cut, topLeft, topRight, bottomRight, bottomLeft);
}
