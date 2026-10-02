import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'couture.dart';

/// Named looks a member can pick in Settings → Appearance.
///
/// Every preset is a full palette (ground, paper, ink, accents) plus the
/// display typeface. `classic` is the pair the product ships with: Daylight
/// (the website's cream-and-ink editorial look) in light mode and Afterdark
/// Ember in dark mode, following the Light / Dark / Match device switch. The
/// themed presets have a fixed brightness.
class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.label,
    required this.tagline,
    required this.brightness,
    required this.ground,
    required this.groundGlow,
    required this.paper,
    required this.paperSunk,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.rule,
    required this.ruleStrong,
    required this.primary,
    required this.onPrimary,
    required this.primaryTint,
    required this.secondary,
    required this.secondaryTint,
    required this.tertiary,
    required this.tertiaryTint,
    required this.jewel,
    required this.trim,
    required this.swatch,
    this.displayFamily = AppTheme.displayFamily,
    this.reducedMotion = false,
  });

  final String id;
  final String label;
  final String tagline;
  final Brightness brightness;
  final Color ground;

  /// Second ground colour the backdrop blooms toward.
  final Color groundGlow;
  final Color paper;
  final Color paperSunk;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color rule;
  final Color ruleStrong;
  final Color primary;
  final Color onPrimary;
  final Color primaryTint;
  final Color secondary;
  final Color secondaryTint;
  final Color tertiary;
  final Color tertiaryTint;

  /// The colour a primary action rolls into from [primary]: a second hue, so
  /// buttons are a pairing (rose into champagne gold, sapphire into
  /// amethyst) rather than one flat accent. [onPrimary] must read on it.
  final Color jewel;

  /// The look's trim: the metal of its hairlines (gold, chrome, platinum),
  /// used on button rims, outlined buttons and the lit edge of cards.
  final Color trim;

  /// Three colours shown on the picker chip.
  final List<Color> swatch;
  final String displayFamily;

  /// The look asks the app to hold still: no atmosphere scene, no title
  /// card, and every place that already honours the platform's reduce-motion
  /// setting treats this as if it were on. Only [ThemePresets.calm] sets it.
  final bool reducedMotion;

  bool get isDark => brightness == Brightness.dark;

  Gradient get groundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ground, groundGlow, ground],
    stops: const [0, 0.55, 1],
  );

  Gradient get accentGradient => LinearGradient(colors: [primary, secondary]);

  /// Fill of a primary action: [primary] rolling into [jewel].
  Gradient get actionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, jewel],
  );
}

/// Palette hooks for widgets that want the preset's accents without reaching
/// for the static [AppTheme] constants.
class ConnectPalette extends ThemeExtension<ConnectPalette> {
  const ConnectPalette({required this.preset});

  final ThemePreset preset;

  @override
  ConnectPalette copyWith({ThemePreset? preset}) =>
      ConnectPalette(preset: preset ?? this.preset);

  @override
  ConnectPalette lerp(ThemeExtension<ConnectPalette>? other, double t) =>
      t < 0.5 ? this : (other as ConnectPalette? ?? this);

  // Presets are immutable constants with unique ids: two palettes for the
  // same look are the same palette. Keeps rebuilt ThemeData equal so the
  // app's theme morph only plays when the look really changes.
  @override
  bool operator ==(Object other) =>
      other is ConnectPalette && other.preset.id == preset.id;

  @override
  int get hashCode => preset.id.hashCode;
}

abstract final class ThemePresets {
  static const String classicId = 'classic';

  /// Default brand: warm daylight and a quiet forest evening.
  static const realLife = ThemePreset(
    id: 'real-life',
    label: 'Today',
    tagline: 'Warm ivory, forest and apricot.',
    brightness: Brightness.light,
    ground: Color(0xFFF8F4ED),
    groundGlow: Color(0xFFF8F4ED),
    paper: Color(0xFFFFFDF9),
    paperSunk: Color(0xFFF0EEE5),
    ink: Color(0xFF1C2923),
    inkMuted: Color(0xFF58665E),
    inkFaint: Color(0xFF58665E),
    rule: Color(0xFFDCDED5),
    ruleStrong: Color(0xFFB9C3B8),
    primary: Color(0xFF194C3F),
    onPrimary: Colors.white,
    primaryTint: Color(0xFFE4EEE7),
    secondary: Color(0xFF8B4929),
    secondaryTint: Color(0xFFFFE2CE),
    tertiary: Color(0xFF685B32),
    tertiaryTint: Color(0xFFF1EACF),
    jewel: Color(0xFF1F7A80),
    trim: Color(0xFFB08A3C),
    swatch: [Color(0xFFF8F4ED), Color(0xFF194C3F), Color(0xFFFFE2CE)],
  );
  static const realLifeNight = ThemePreset(
    id: 'real-life-night',
    label: 'Today · evening',
    tagline: 'Forest, soft mint and candlelight.',
    brightness: Brightness.dark,
    ground: Color(0xFF121E1A),
    groundGlow: Color(0xFF121E1A),
    paper: Color(0xFF1C2B25),
    paperSunk: Color(0xFF16221D),
    ink: Color(0xFFF8F4ED),
    inkMuted: Color(0xFFBBC9BF),
    inkFaint: Color(0xFFBBC9BF),
    rule: Color(0xFF43554B),
    ruleStrong: Color(0xFF63796B),
    primary: Color(0xFFBAE5CF),
    onPrimary: Color(0xFF163A2F),
    primaryTint: Color(0xFF294639),
    secondary: Color(0xFFFFCCA8),
    secondaryTint: Color(0xFF493526),
    tertiary: Color(0xFFE7D997),
    tertiaryTint: Color(0xFF403D28),
    jewel: Color(0xFFE7D997),
    trim: Color(0xFFE7D997),
    swatch: [Color(0xFF121E1A), Color(0xFFBAE5CF), Color(0xFFFFCCA8)],
  );

  /// The website look: cream ground, white cards with hairline rules, ink
  /// type, raspberry accent.
  static const daylight = ThemePreset(
    id: 'daylight',
    label: 'Daylight',
    tagline: 'Cream, ink and a raspberry accent, like the website.',
    brightness: Brightness.light,
    ground: AppTheme.ground,
    groundGlow: Color(0xFFFFEFEA),
    paper: AppTheme.paper,
    paperSunk: AppTheme.paperSunk,
    ink: AppTheme.ink,
    inkMuted: AppTheme.inkMuted,
    inkFaint: AppTheme.inkFaint,
    rule: AppTheme.rule,
    ruleStrong: AppTheme.ruleStrong,
    primary: AppTheme.ember,
    onPrimary: Colors.white,
    primaryTint: AppTheme.emberTint,
    secondary: AppTheme.violet,
    secondaryTint: AppTheme.violetTint,
    tertiary: AppTheme.gold,
    tertiaryTint: AppTheme.goldTint,
    jewel: AppTheme.violet,
    trim: AppTheme.gold,
    swatch: [AppTheme.ground, AppTheme.ember, AppTheme.ink],
  );

  /// The current dark look: plum-black lit by ember and violet blooms.
  static const ember = ThemePreset(
    id: 'ember',
    label: 'Afterdark Ember',
    tagline: 'Plum-black night with ember and violet glow.',
    brightness: Brightness.dark,
    ground: AppTheme.groundDark,
    groundGlow: Color(0xFF2A1226),
    paper: AppTheme.paperDark,
    paperSunk: AppTheme.paperSunkDark,
    ink: AppTheme.inkOnDark,
    inkMuted: AppTheme.inkMutedOnDark,
    inkFaint: AppTheme.inkFaintOnDark,
    rule: AppTheme.ruleDark,
    ruleStrong: Color(0xFF4A3756),
    primary: AppTheme.emberBright,
    onPrimary: AppTheme.ink,
    primaryTint: AppTheme.emberTintDark,
    secondary: AppTheme.violetBright,
    secondaryTint: AppTheme.violetTintDark,
    tertiary: AppTheme.goldBright,
    tertiaryTint: Color(0xFF3A2A12),
    jewel: AppTheme.violetBright,
    trim: AppTheme.goldBright,
    swatch: [AppTheme.groundDark, AppTheme.emberBright, AppTheme.violetBright],
  );

  /// Furnace red and steel blue on brushed gunmetal.
  static const forge = ThemePreset(
    id: 'forge',
    label: 'Forge',
    tagline: 'Furnace red, steel blue, gunmetal chrome.',
    brightness: Brightness.dark,
    ground: Color(0xFF0B1020),
    groundGlow: Color(0xFF1A2440),
    paper: Color(0xFF151C30),
    paperSunk: Color(0xFF0F1526),
    ink: Color(0xFFF2F5FF),
    inkMuted: Color(0xFFB7C1DD),
    inkFaint: Color(0xFF7E8AAB),
    rule: Color(0xFF2A3554),
    ruleStrong: Color(0xFF3C4A70),
    primary: Color(0xFFE53935),
    onPrimary: Colors.white,
    primaryTint: Color(0xFF3A1519),
    secondary: Color(0xFF3D8BFF),
    secondaryTint: Color(0xFF14264A),
    tertiary: Color(0xFFC9D3E6),
    tertiaryTint: Color(0xFF26314A),
    jewel: Color(0xFF2F6BDC),
    trim: Color(0xFFC9D3E6),
    swatch: [Color(0xFF0B1020), Color(0xFFE53935), Color(0xFF3D8BFF)],
    displayFamily: 'Orbitron',
  );

  /// Black glass, cyan light-lines, an amber counter-glow.
  static const neonGrid = ThemePreset(
    id: 'neongrid',
    label: 'Neon Grid',
    tagline: 'Black glass, cyan light-lines, amber pulse.',
    brightness: Brightness.dark,
    ground: Color(0xFF02070C),
    groundGlow: Color(0xFF051A24),
    paper: Color(0xFF071219),
    paperSunk: Color(0xFF040C12),
    ink: Color(0xFFE6FBFF),
    inkMuted: Color(0xFF8FD6E6),
    inkFaint: Color(0xFF5A96A6),
    rule: Color(0xFF0E3340),
    ruleStrong: Color(0xFF15586B),
    primary: Color(0xFF00E5FF),
    onPrimary: Color(0xFF02141A),
    primaryTint: Color(0xFF063139),
    secondary: Color(0xFFFF8A00),
    secondaryTint: Color(0xFF3A2206),
    tertiary: Color(0xFFBFF6FF),
    tertiaryTint: Color(0xFF0B3A44),
    jewel: Color(0xFF6C9BFF),
    trim: Color(0xFFFF8A00),
    swatch: [Color(0xFF02070C), Color(0xFF00E5FF), Color(0xFFFF8A00)],
    displayFamily: 'Orbitron',
  );

  /// Crimson lacquer and molten gold on deep maroon.
  static const crimsonAlloy = ThemePreset(
    id: 'crimsonalloy',
    label: 'Crimson Alloy',
    tagline: 'Crimson lacquer, molten gold, midnight maroon.',
    brightness: Brightness.dark,
    ground: Color(0xFF140507),
    groundGlow: Color(0xFF3A0B10),
    paper: Color(0xFF220A0E),
    paperSunk: Color(0xFF19070A),
    ink: Color(0xFFFFF4EC),
    inkMuted: Color(0xFFE2BDB6),
    inkFaint: Color(0xFFA37F7A),
    rule: Color(0xFF4A1A20),
    ruleStrong: Color(0xFF6B262F),
    primary: Color(0xFFD32F2F),
    onPrimary: Colors.white,
    primaryTint: Color(0xFF3F1216),
    secondary: Color(0xFFFFB300),
    secondaryTint: Color(0xFF3F2E06),
    tertiary: Color(0xFF7FE9FF),
    tertiaryTint: Color(0xFF0E2F38),
    jewel: Color(0xFFA8500F),
    trim: Color(0xFFFFB300),
    swatch: [Color(0xFF140507), Color(0xFFD32F2F), Color(0xFFFFB300)],
  );

  /// Circuit green and signal violet on carbon black.
  static const circuit = ThemePreset(
    id: 'circuit',
    label: 'Circuit',
    tagline: 'Circuit green, signal violet, carbon black.',
    brightness: Brightness.dark,
    ground: Color(0xFF030A07),
    groundGlow: Color(0xFF0A2418),
    paper: Color(0xFF081510),
    paperSunk: Color(0xFF05100B),
    ink: Color(0xFFEAFFF3),
    inkMuted: Color(0xFF9FD9B8),
    inkFaint: Color(0xFF5F9A78),
    rule: Color(0xFF12352A),
    ruleStrong: Color(0xFF1D5540),
    primary: Color(0xFF00FF88),
    onPrimary: Color(0xFF03150C),
    primaryTint: Color(0xFF0B3A25),
    secondary: Color(0xFFA36BFF),
    secondaryTint: Color(0xFF2A1A4A),
    tertiary: Color(0xFFFFE066),
    tertiaryTint: Color(0xFF3A3210),
    jewel: Color(0xFF3DE8FF),
    trim: Color(0xFFA36BFF),
    swatch: [Color(0xFF030A07), Color(0xFF00FF88), Color(0xFFA36BFF)],
    displayFamily: 'Orbitron',
  );

  /// A cinematic deep-space look with opposing plasma accents and warm
  /// starlight. The scene is drawn in-app and does not depend on licensed
  /// character art, logos, or external assets.
  static const deepField = ThemePreset(
    id: 'deepfield',
    label: 'Deep Field',
    tagline: 'Deep space, plasma blue and a flash of starlight gold.',
    brightness: Brightness.dark,
    ground: Color(0xFF02040A),
    groundGlow: Color(0xFF081229),
    paper: Color(0xFF0A1020),
    paperSunk: Color(0xFF050A14),
    ink: Color(0xFFF6F7FB),
    inkMuted: Color(0xFFB8C3D9),
    inkFaint: Color(0xFF75829C),
    rule: Color(0xFF1B2A47),
    ruleStrong: Color(0xFF365079),
    primary: Color(0xFF58B8FF),
    onPrimary: Color(0xFF03101B),
    primaryTint: Color(0xFF0B2942),
    secondary: Color(0xFFFF4057),
    secondaryTint: Color(0xFF3C1019),
    tertiary: Color(0xFFFFD54A),
    tertiaryTint: Color(0xFF372D08),
    jewel: Color(0xFFB48CFF),
    trim: Color(0xFFFFD54A),
    swatch: [Color(0xFF02040A), Color(0xFF58B8FF), Color(0xFFFFD54A)],
    displayFamily: 'Orbitron',
  );

  /// Blush and rose: soft, warm, unmistakably romantic.
  static const love = ThemePreset(
    id: 'love',
    label: 'Love',
    tagline: 'Blush, rose and a little gold.',
    brightness: Brightness.light,
    ground: Color(0xFFFFF0F4),
    groundGlow: Color(0xFFFFE1EA),
    paper: Color(0xFFFFFFFF),
    paperSunk: Color(0xFFFFE7EE),
    ink: Color(0xFF3B1020),
    inkMuted: Color(0xFF7D4A5C),
    inkFaint: Color(0xFFA37A89),
    rule: Color(0xFFF7D3DE),
    ruleStrong: Color(0xFFEDB4C6),
    primary: Color(0xFFE0245E),
    onPrimary: Colors.white,
    primaryTint: Color(0xFFFFE0E9),
    secondary: Color(0xFFFF7EB3),
    secondaryTint: Color(0xFFFFE8F1),
    tertiary: Color(0xFFD69E2E),
    tertiaryTint: Color(0xFFFFF3D6),
    jewel: Color(0xFF9C36C9),
    trim: Color(0xFFD69E2E),
    swatch: [Color(0xFFFFF0F4), Color(0xFFE0245E), Color(0xFFFF7EB3)],
  );

  /// Velvet evening: deep wine ground, rose-red accents, blush and gold.
  /// The backdrop paints full rose blooms in the corners.
  static const rose = ThemePreset(
    id: 'rose',
    label: 'Rose',
    tagline: 'Velvet wine, rose red and a little gold.',
    brightness: Brightness.dark,
    ground: Color(0xFF1A0710),
    groundGlow: Color(0xFF35101F),
    paper: Color(0xFF26101A),
    paperSunk: Color(0xFF1F0B14),
    ink: Color(0xFFFFF0F3),
    inkMuted: Color(0xFFE7BFC9),
    inkFaint: Color(0xFFC2909E),
    rule: Color(0xFF4A2030),
    ruleStrong: Color(0xFF6B2E45),
    primary: Color(0xFFFF4F7B),
    onPrimary: Color(0xFF1A0710),
    primaryTint: Color(0xFF4A1426),
    secondary: Color(0xFFFFB3C6),
    secondaryTint: Color(0xFF3D1422),
    tertiary: Color(0xFFE8B86D),
    tertiaryTint: Color(0xFF3A2A12),
    jewel: Color(0xFFE8B86D),
    trim: Color(0xFFFFE2A8),
    swatch: [Color(0xFF1A0710), Color(0xFFFF4F7B), Color(0xFFE8B86D)],
  );

  /// A rose that does not exist: sapphire blooms on midnight velvet, frost
  /// pink for the second accent and platinum for the trim. The backdrop
  /// paints blue roses in the corners with ice-edged petals tumbling down.
  static const blueRose = ThemePreset(
    id: 'bluerose',
    label: 'Blue Rose',
    tagline: 'Midnight velvet, sapphire roses and a platinum edge.',
    brightness: Brightness.dark,
    ground: Color(0xFF050C1C),
    groundGlow: Color(0xFF0C2148),
    paper: Color(0xFF0D1730),
    paperSunk: Color(0xFF091124),
    ink: Color(0xFFF2F6FF),
    inkMuted: Color(0xFFBCC8E4),
    inkFaint: Color(0xFF8E9CC0),
    rule: Color(0xFF1F2D52),
    ruleStrong: Color(0xFF31457A),
    primary: Color(0xFF5AA2FF),
    onPrimary: Color(0xFF04101F),
    primaryTint: Color(0xFF12284F),
    secondary: Color(0xFFFF9EC4),
    secondaryTint: Color(0xFF3A1830),
    tertiary: Color(0xFFD9E2F2),
    tertiaryTint: Color(0xFF262E42),
    jewel: Color(0xFF6FE0FF),
    trim: Color(0xFFE6ECF7),
    swatch: [Color(0xFF050C1C), Color(0xFF5AA2FF), Color(0xFFFF9EC4)],
  );

  /// The sacred blue water lily on a moonlit pond: indigo water, periwinkle
  /// petals fading to lilac and a golden heart. The backdrop looks down on
  /// lily pads and two open blooms, with slow ripples and gold pollen
  /// drifting over the water. Rewards burst out as lotus blooms.
  static const blueLotus = ThemePreset(
    id: 'bluelotus',
    label: 'Blue Lotus',
    tagline: 'Moonlit water, sapphire petals and a golden heart.',
    brightness: Brightness.dark,
    ground: Color(0xFF070B1E),
    groundGlow: Color(0xFF141B45),
    paper: Color(0xFF121838),
    paperSunk: Color(0xFF0C1129),
    ink: Color(0xFFF1F3FF),
    inkMuted: Color(0xFFBFC6EA),
    inkFaint: Color(0xFF8F98C4),
    rule: Color(0xFF262F5E),
    ruleStrong: Color(0xFF3A4686),
    primary: Color(0xFF7C9BFF),
    onPrimary: Color(0xFF070B1E),
    primaryTint: Color(0xFF1B2557),
    secondary: Color(0xFFC6A6FF),
    secondaryTint: Color(0xFF2A1F52),
    tertiary: Color(0xFFF2C562),
    tertiaryTint: Color(0xFF3A2F12),
    jewel: Color(0xFFC08CFF),
    trim: Color(0xFFF2C562),
    swatch: [Color(0xFF070B1E), Color(0xFF7C9BFF), Color(0xFFF2C562)],
  );

  /// Morning garden: blush paper, petal pinks and sage leaves. The backdrop
  /// scatters soft petals drifting across the page.
  static const petal = ThemePreset(
    id: 'petal',
    label: 'Petal',
    tagline: 'Blush paper, drifting petals, a hint of sage.',
    brightness: Brightness.light,
    ground: Color(0xFFFFF6F4),
    groundGlow: Color(0xFFFFE9EC),
    paper: Color(0xFFFFFFFF),
    paperSunk: Color(0xFFFFEEF0),
    ink: Color(0xFF3A1622),
    inkMuted: Color(0xFF7A4E5A),
    inkFaint: Color(0xFF8F6672),
    rule: Color(0xFFF6D6DD),
    ruleStrong: Color(0xFFEBB8C4),
    primary: Color(0xFFC2185B),
    onPrimary: Colors.white,
    primaryTint: Color(0xFFFFE0EA),
    secondary: Color(0xFFF48FB1),
    secondaryTint: Color(0xFFFFEDF3),
    tertiary: Color(0xFF6B8F71),
    tertiaryTint: Color(0xFFE6F0E7),
    jewel: Color(0xFF8A2A8C),
    trim: Color(0xFF6B8F71),
    swatch: [Color(0xFFFFF6F4), Color(0xFFF48FB1), Color(0xFF6B8F71)],
  );

  /// First snow: a frosted ice-white page with glacier-blue accents, deep
  /// winter-navy ink and an aurora-green third accent. The backdrop paints a
  /// moonlit aurora, three depths of snow crystals, frost ferns creeping in
  /// from the corners and soft drifts gathering along the bottom. Rewards
  /// burst out as snowflakes.
  static const snow = ThemePreset(
    id: 'snow',
    label: 'Snow',
    tagline: 'Fresh snowfall, frosted glass and a ribbon of aurora.',
    brightness: Brightness.light,
    ground: Color(0xFFEEF4FA),
    groundGlow: Color(0xFFDDEBF7),
    paper: Color(0xFFFBFDFF),
    paperSunk: Color(0xFFE6EFF7),
    ink: Color(0xFF0F2138),
    inkMuted: Color(0xFF44586F),
    inkFaint: Color(0xFF566A82),
    rule: Color(0xFFD3E1EE),
    ruleStrong: Color(0xFFA9C1D8),
    primary: Color(0xFF1F5F99),
    onPrimary: Colors.white,
    primaryTint: Color(0xFFDCEAF7),
    secondary: Color(0xFF2F6F96),
    secondaryTint: Color(0xFFE1F0F8),
    tertiary: Color(0xFF2B6E62),
    tertiaryTint: Color(0xFFDCF0EA),
    jewel: Color(0xFF217A6E),
    trim: Color(0xFF8FA9C4),
    swatch: [Color(0xFFEEF4FA), Color(0xFF1F5F99), Color(0xFF8EC9E0)],
  );

  /// Candlelit cathedral: near-black velvet, garnet crimson, amethyst and
  /// tarnished antique gold, set in the high-contrast Bodoni display face.
  /// The backdrop paints a rose window's tracery under a full moon, bats
  /// crossing it, a spired skyline, low fog and three candles. Rewards burst
  /// out as a swirl of bats and crimson embers.
  static const gothic = ThemePreset(
    id: 'gothic',
    label: 'Gothic',
    tagline: 'Moonlit tracery, garnet, candle smoke and antique gold.',
    brightness: Brightness.dark,
    ground: Color(0xFF0B0810),
    groundGlow: Color(0xFF1E0E1C),
    paper: Color(0xFF17111C),
    paperSunk: Color(0xFF110D16),
    ink: Color(0xFFF2EBE3),
    inkMuted: Color(0xFFC4B8C6),
    inkFaint: Color(0xFF978C9E),
    rule: Color(0xFF2E2433),
    ruleStrong: Color(0xFF4A3A50),
    primary: Color(0xFFEC5577),
    onPrimary: Color(0xFF14070C),
    primaryTint: Color(0xFF34101B),
    secondary: Color(0xFFB094E0),
    secondaryTint: Color(0xFF2A1B3D),
    tertiary: Color(0xFFCDA95E),
    tertiaryTint: Color(0xFF33270F),
    jewel: Color(0xFFB094E0),
    trim: Color(0xFFCDA95E),
    swatch: [Color(0xFF0B0810), Color(0xFFEC5577), Color(0xFFCDA95E)],
  );

  /// Low-stimulation look for members who find glow and motion tiring.
  ///
  /// Neutral off-white ground with no bloom (`groundGlow` equals `ground`, so
  /// the backdrop is flat), near-black ink for the highest contrast of any
  /// light preset, and one muted slate-blue accent that doubles as the
  /// secondary so nothing on screen shouts. [ThemePreset.reducedMotion]
  /// turns off the atmosphere scene, the title card and the animations that
  /// already defer to the platform's reduce-motion setting.
  static const calm = ThemePreset(
    id: 'calm',
    label: 'Calm',
    tagline: 'Low stimulation, high contrast. Still backdrop, no motion.',
    brightness: Brightness.light,
    ground: Color(0xFFF7F6F3),
    groundGlow: Color(0xFFF7F6F3),
    paper: Color(0xFFFFFFFF),
    paperSunk: Color(0xFFEFEDE9),
    ink: Color(0xFF0D0F12),
    inkMuted: Color(0xFF4A4F57),
    inkFaint: Color(0xFF6B7079),
    rule: Color(0xFFD9D6D0),
    ruleStrong: Color(0xFFB8B4AC),
    primary: Color(0xFF2F5D7C),
    onPrimary: Colors.white,
    primaryTint: Color(0xFFE3ECF2),
    secondary: Color(0xFF2F5D7C),
    secondaryTint: Color(0xFFE3ECF2),
    tertiary: Color(0xFF5C6670),
    tertiaryTint: Color(0xFFECEEF0),
    jewel: Color(0xFF244B66),
    trim: Color(0xFFB8B4AC),
    swatch: [Color(0xFFF7F6F3), Color(0xFF2F5D7C), Color(0xFF0D0F12)],
    reducedMotion: true,
  );

  /// Presets a member can choose from. `classic` is represented by
  /// [daylight] / [ember] depending on the Light / Dark switch.
  static const List<ThemePreset> themed = [
    forge,
    neonGrid,
    crimsonAlloy,
    circuit,
    deepField,
    love,
    rose,
    blueRose,
    blueLotus,
    petal,
    snow,
    gothic,
    calm,
  ];

  static const List<ThemePreset> all = [
    realLife,
    realLifeNight,
    daylight,
    ember,
    ...themed,
  ];

  /// The everyday looks (Today's Real life pair and the Daylight / Ember
  /// pair) sit on a flat ground with no atmosphere scene, exactly like the
  /// Today screen.
  static bool isEveryday(ThemePreset preset) =>
      preset.id == realLife.id ||
      preset.id == realLifeNight.id ||
      preset.id == daylight.id ||
      preset.id == ember.id;

  static ThemePreset? byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  /// Builds a full [ThemeData] for a preset on top of the base theme of the
  /// same brightness, so component styling stays consistent across looks.
  static ThemeData themeFor(ThemePreset preset) {
    final base = preset.isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    final scheme = base.colorScheme.copyWith(
      primary: preset.primary,
      onPrimary: preset.onPrimary,
      primaryContainer: preset.primaryTint,
      onPrimaryContainer: preset.isDark ? preset.primary : preset.ink,
      secondary: preset.secondary,
      secondaryContainer: preset.secondaryTint,
      onSecondaryContainer: preset.isDark ? preset.secondary : preset.ink,
      tertiary: preset.tertiary,
      tertiaryContainer: preset.tertiaryTint,
      onTertiaryContainer: preset.ink,
      surface: preset.paper,
      onSurface: preset.ink,
      onSurfaceVariant: preset.inkMuted,
      outline: preset.rule,
      outlineVariant: preset.ruleStrong,
      surfaceContainerHighest: preset.paperSunk,
    );
    final text = _retype(base.textTheme, preset);
    final primaryButton = base.filledButtonTheme.style?.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return preset.primary.withValues(alpha: 0.32);
        }
        return preset.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.disabled)
            ? preset.onPrimary.withValues(alpha: 0.55)
            : preset.onPrimary,
      ),
      // The light under the button takes both colours of its fill.
      shadowColor: WidgetStatePropertyAll<Color>(
        preset.reducedMotion
            ? preset.primary.withValues(alpha: 0.35)
            : Couture.glow(preset),
      ),
      // Every look: the couture fill (primary rolling into the look's jewel
      // under a trim hairline). Cinematic looks add a band of light gliding
      // over it every few seconds; everyday looks and reduced motion do not.
      // Static tear-offs (not closures) keep ThemeData equal between
      // rebuilds, so an unrelated rebuild never replays the theme morph.
      backgroundBuilder: isEveryday(preset) || preset.reducedMotion
          ? _coutureBackground
          : _sheenBackground,
    );
    // Outlined buttons and the lit edge of cards share the look's trim.
    final trimLine = Color.lerp(preset.ruleStrong, preset.trim, 0.6)!;
    // On a dark look the second accent reads on its own tint; on a light
    // look the tint carries ink.
    final chipInk = preset.isDark ? preset.secondary : preset.ink;
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: preset.ground,
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: preset.ground,
        foregroundColor: preset.ink,
        titleTextStyle: text.headlineMedium,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: preset.paper,
        shape: Couture.rim(
          preset,
          radius: BorderRadius.circular(AppTheme.radiusL),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll<Color>(preset.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll<Color>(preset.ink),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: trimLine, width: 1.2),
          ),
        ),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: preset.primary,
        unselectedItemColor: preset.inkFaint,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        indicatorColor: preset.primaryTint,
      ),
      // A chosen chip wears the look's second accent, so a screen with a
      // primary action and a row of choices carries two colours, not one.
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: preset.paperSunk,
        selectedColor: preset.secondaryTint,
        checkmarkColor: chipInk,
        side: BorderSide(color: preset.rule),
        labelStyle: text.bodySmall?.copyWith(
          color: preset.inkMuted,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: text.bodySmall?.copyWith(
          color: chipInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: preset.paper,
        shape: Couture.rim(
          preset,
          radius: BorderRadius.circular(AppTheme.radiusXL),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: preset.paper,
        dragHandleColor: preset.ruleStrong,
      ),
      // The floating action wears the jewel, not the primary: a second
      // colour of the look on the screen's loudest control.
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: preset.jewel,
        foregroundColor: preset.onPrimary,
      ),
      iconTheme: base.iconTheme.copyWith(color: preset.inkMuted),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: preset.inkMuted,
        textColor: preset.ink,
      ),
      switchTheme: base.switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? preset.primary
              : preset.ruleStrong,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: preset.primary,
        inactiveTrackColor: preset.rule,
        thumbColor: preset.jewel,
        overlayColor: preset.primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: preset.primary,
        linearTrackColor: preset.rule,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: preset.ink,
        unselectedLabelColor: preset.inkFaint,
        indicatorColor: preset.jewel,
        dividerColor: preset.rule,
      ),
      dividerTheme: DividerThemeData(color: preset.rule, thickness: 1),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: preset.isDark ? preset.paperSunk : preset.ink,
        // Same colour as the message so the action always reads on the bar.
        actionTextColor: preset.isDark ? preset.ink : preset.paper,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: preset.isDark ? preset.ink : preset.paper,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: preset.paperSunk,
        hintStyle: text.bodyMedium?.copyWith(color: preset.inkFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: preset.rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: preset.primary, width: 1.5),
        ),
      ),
      extensions: [ConnectPalette(preset: preset)],
    );
  }

  static Widget _sheenBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) => CoutureActionFill(
    states: states,
    sheen: true,
    child: child ?? const SizedBox.shrink(),
  );

  static Widget _coutureBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) => CoutureActionFill(
    states: states,
    child: child ?? const SizedBox.shrink(),
  );

  static TextTheme _retype(TextTheme base, ThemePreset preset) {
    TextStyle? display(TextStyle? style) =>
        style?.copyWith(color: preset.ink, fontFamily: preset.displayFamily);
    TextStyle? body(TextStyle? style, Color color) =>
        style?.copyWith(color: color);
    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: display(base.headlineMedium),
      headlineSmall: display(base.headlineSmall),
      titleLarge: body(base.titleLarge, preset.ink),
      titleMedium: body(base.titleMedium, preset.ink),
      titleSmall: body(base.titleSmall, preset.ink),
      bodyLarge: body(base.bodyLarge, preset.ink),
      bodyMedium: body(base.bodyMedium, preset.inkMuted),
      bodySmall: body(base.bodySmall, preset.inkMuted),
      labelLarge: body(base.labelLarge, preset.ink),
      labelMedium: body(base.labelMedium, preset.inkMuted),
      labelSmall: body(base.labelSmall, preset.inkFaint),
    );
  }
}

/// [ThemePreset.tagline] in the member's language. The look's name
/// ([ThemePreset.label]) is a product name and stays untranslated.
String localizedPresetTagline(AppLocalizations l10n, ThemePreset preset) =>
    switch (preset.id) {
      'real-life' => l10n.themeTaglineRealLife,
      'real-life-night' => l10n.themeTaglineRealLifeNight,
      'daylight' => l10n.themeTaglineDaylight,
      'ember' => l10n.themeTaglineEmber,
      'forge' => l10n.themeTaglineForge,
      'neongrid' => l10n.themeTaglineNeongrid,
      'crimsonalloy' => l10n.themeTaglineCrimsonalloy,
      'circuit' => l10n.themeTaglineCircuit,
      'deepfield' => l10n.themeTaglineDeepfield,
      'love' => l10n.themeTaglineLove,
      'rose' => l10n.themeTaglineRose,
      'bluerose' => l10n.themeTaglineBluerose,
      'bluelotus' => l10n.themeTaglineBluelotus,
      'petal' => l10n.themeTaglinePetal,
      'snow' => l10n.themeTaglineSnow,
      'gothic' => l10n.themeTaglineGothic,
      'calm' => l10n.themeTaglineCalm,
      _ => preset.tagline,
    };
