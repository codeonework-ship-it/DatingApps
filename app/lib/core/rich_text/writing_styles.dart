import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'rich_document.dart';

/// Bundled families only (pubspec.yaml `fonts:`); nothing is fetched.
const _serif =
    AppTheme.displayFamily; // Bodoni Moda: regular/semibold/bold + italics
const _sans = AppTheme.uiFamily; // Figtree
const _mono = 'Chakra Petch'; // squared, evenly spaced technical face

/// How a [WritingStyle] looks. Every colour comes from the [ColorScheme] so
/// each theme (Daylight, Ember, cinematic presets) keeps readable contrast.
class WritingStyleSpec {
  const WritingStyleSpec({
    required this.family,
    required this.size,
    required this.height,
    this.italic = false,
    this.letterSpacing = 0,
    this.headingFamily,
    this.headingItalic = false,
    this.headingLetterSpacing = 0,
    this.centered = false,
    this.blockGap = 8,
  });

  factory WritingStyleSpec.of(WritingStyle style) => switch (style) {
    WritingStyle.classic => const WritingStyleSpec(
      family: _serif,
      size: 18,
      height: 1.7,
    ),
    // The look plain chapters always had: Figtree body at reading size.
    WritingStyle.modern => const WritingStyleSpec(
      family: _sans,
      size: 16,
      height: 1.65,
      headingFamily: _sans,
    ),
    WritingStyle.journal => const WritingStyleSpec(
      family: _serif,
      size: 18,
      height: 1.8,
      italic: true,
      headingItalic: true,
    ),
    WritingStyle.typewriter => const WritingStyleSpec(
      family: _mono,
      size: 15,
      height: 1.75,
      letterSpacing: .6,
      headingFamily: _mono,
      headingLetterSpacing: 1.2,
    ),
    WritingStyle.poetic => const WritingStyleSpec(
      family: _serif,
      size: 19,
      height: 2,
      centered: true,
      blockGap: 16,
    ),
  };
  final String family;
  final double size, height, letterSpacing, headingLetterSpacing, blockGap;
  final bool italic, headingItalic;
  final String? headingFamily;

  /// Poetic: start-aligned blocks render centred (explicit "end" still wins).
  final bool centered;

  /// Body text. [scale] lets compact surfaces (story cards) size up or down.
  TextStyle body(ThemeData theme, {double scale = 1}) => TextStyle(
    fontFamily: family,
    fontSize: size * scale,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: FontWeight.w400,
    color: theme.colorScheme.onSurface,
  );

  TextStyle heading(ThemeData theme, {bool sub = false, double scale = 1}) =>
      TextStyle(
        fontFamily: headingFamily ?? family,
        fontSize: (sub ? size * 1.2 : size * 1.5) * scale,
        height: 1.3,
        letterSpacing: headingLetterSpacing,
        fontStyle: headingItalic ? FontStyle.italic : FontStyle.normal,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      );

  TextAlign align(RichAlign value) => switch (value) {
    RichAlign.center => TextAlign.center,
    RichAlign.end => TextAlign.end,
    RichAlign.start => centered ? TextAlign.center : TextAlign.start,
  };
}

/// Inline marks applied on top of a block style.
TextStyle applyRichMarks(
  TextStyle base,
  Set<RichMark> marks,
  ColorScheme colors,
) {
  var style = base;
  if (marks.contains(RichMark.bold)) {
    style = style.copyWith(fontWeight: FontWeight.w700);
  }
  if (marks.contains(RichMark.italic)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  final decorations = <TextDecoration>[
    if (marks.contains(RichMark.underline) || marks.contains(RichMark.link))
      TextDecoration.underline,
    if (marks.contains(RichMark.strikethrough)) TextDecoration.lineThrough,
  ];
  if (decorations.isNotEmpty) {
    style = style.copyWith(
      decoration: TextDecoration.combine(decorations),
      decorationColor: marks.contains(RichMark.link) ? colors.primary : null,
    );
  }
  if (marks.contains(RichMark.highlight)) {
    // A container/on-container pair keeps contrast in light, dark and preset themes.
    style = style.copyWith(
      backgroundColor: colors.tertiaryContainer,
      color: colors.onTertiaryContainer,
    );
  }
  if (marks.contains(RichMark.link)) {
    style = style.copyWith(
      color: marks.contains(RichMark.highlight)
          ? colors.onTertiaryContainer
          : colors.primary,
    );
  }
  return style;
}

String writingStyleName(AppLocalizations l, WritingStyle style) =>
    switch (style) {
      WritingStyle.classic => l.richStyleClassic,
      WritingStyle.modern => l.richStyleModern,
      WritingStyle.journal => l.richStyleJournal,
      WritingStyle.typewriter => l.richStyleTypewriter,
      WritingStyle.poetic => l.richStylePoetic,
    };

String writingStyleDescription(AppLocalizations l, WritingStyle style) =>
    switch (style) {
      WritingStyle.classic => l.richStyleClassicHint,
      WritingStyle.modern => l.richStyleModernHint,
      WritingStyle.journal => l.richStyleJournalHint,
      WritingStyle.typewriter => l.richStyleTypewriterHint,
      WritingStyle.poetic => l.richStylePoeticHint,
    };
