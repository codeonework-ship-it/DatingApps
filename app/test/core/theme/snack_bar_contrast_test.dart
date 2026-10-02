import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// AND-09: the SnackBar action ("Open", "Undo") sank into the dark bar.
void main() {
  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    for (final preset in ThemePresets.all)
      preset.id: ThemePresets.themeFor(preset),
  };
  for (final entry in themes.entries) {
    test('${entry.key}: SnackBar action is readable on the bar', () {
      final bar = entry.value.snackBarTheme;
      expect(bar.backgroundColor, isNotNull);
      expect(bar.actionTextColor, isNotNull);
      expect(
        _contrast(bar.actionTextColor!, bar.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
}
