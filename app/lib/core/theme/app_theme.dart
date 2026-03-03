import 'package:flutter/material.dart';

/// Active design-system theme used by the app.
class AppTheme {
  AppTheme._();

  // ==========================================================================
  // DESIGN TOKENS: COLORS
  // ==========================================================================

  // Core brand colors from the design spec
  static const Color trustBlue = Color(0xFF2B5995);
  static const Color safetyGreen = Color(0xFF10B981);
  static const Color warmOrange = Color(0xFFFF9500);
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color crystalAqua = Color(0xFF67E8F9);
  static const Color crystalBlue = Color(0xFF60A5FA);
  static const Color crystalMint = Color(0xFF86EFAC);
  static const Color crystalRose = Color(0xFFFDA4AF);

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
    colors: [trustBlue, crystalBlue, crystalAqua],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient bgGradient = LinearGradient(
    colors: [
      Color(0xFF071226),
      Color(0xFF133D71),
      Color(0xFF1F7A96),
      Color(0xFF39BFC4),
    ],
    stops: [0.0, 0.33, 0.72, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );

  /// Softer surface used after login for better readability.
  static const Gradient postLoginGradient = LinearGradient(
    colors: [
      Color(0xFFF8FBFF),
      Color(0xFFEFF6FF),
      Color(0xFFE4EEFA),
      Color(0xFFD8E7F8),
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
    colors: [crystalAqua, crystalBlue, crystalMint],
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
      outline: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5FBFF),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        foregroundColor: textDark,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: _buildTextTheme(
          Brightness.light,
        ).headlineMedium?.copyWith(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: trustBlue.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.42)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: trustBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: _buildTextTheme(
            Brightness.light,
          ).labelLarge?.copyWith(fontSize: 16),
          elevation: 1,
          shadowColor: trustBlue.withValues(alpha: 0.24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: trustBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: _buildTextTheme(Brightness.light).labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: trustBlue,
          minimumSize: const Size.fromHeight(buttonHeight),
          side: const BorderSide(color: trustBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: trustBlue,
          textStyle: _buildTextTheme(Brightness.light).titleMedium,
        ),
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
          borderSide: const BorderSide(color: crystalBlue, width: 2),
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
        selectedItemColor: crystalBlue,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
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
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: trustBlue.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: trustBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textDark,
          backgroundColor: Colors.white.withValues(alpha: 0.82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
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
      surface: const Color(0xFF111827),
      onSurface: textLight,
      error: alertRed,
      onError: Colors.white,
      outline: const Color(0xFF334155),
      surfaceContainerHighest: const Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF050A14),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: textLight,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: _buildTextTheme(
          Brightness.dark,
        ).headlineMedium?.copyWith(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: trustBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: _buildTextTheme(Brightness.dark).labelLarge,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.35),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: trustBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: _buildTextTheme(Brightness.dark).labelLarge,
        ),
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
          borderSide: const BorderSide(color: crystalAqua, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111827).withValues(alpha: 0.9),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: trustBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textLight,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
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
        iconColor: crystalAqua,
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
