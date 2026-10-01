import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final light = la > lb ? la : lb;
  final dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  const looks = [ThemePresets.snow, ThemePresets.gothic];

  test('Snow and Gothic are selectable looks with taglines', () {
    for (final preset in looks) {
      expect(ThemePresets.themed, contains(same(preset)), reason: preset.id);
      expect(ThemePresets.byId(preset.id), same(preset));
      expect(preset.tagline, isNotEmpty);
      expect(preset.swatch, hasLength(3));
      expect(preset.reducedMotion, isFalse);
      expect(ThemePresets.isEveryday(preset), isFalse);
      final selection = AppThemeSelection.fromWire('auto:${preset.id}');
      expect(selection.preset, same(preset));
      expect(selection.wireValue, 'auto:${preset.id}');
    }
    expect(ThemePresets.snow.label, 'Snow');
    expect(ThemePresets.snow.brightness, Brightness.light);
    expect(ThemePresets.gothic.label, 'Gothic');
    expect(ThemePresets.gothic.brightness, Brightness.dark);
    // Calm stays last in the strip as the quiet option.
    expect(ThemePresets.themed.last, same(ThemePresets.calm));
  });

  test('Snow and Gothic meet WCAG AA everywhere text sits', () {
    for (final p in looks) {
      for (final surface in [p.ground, p.paper, p.paperSunk]) {
        expect(
          _contrast(p.ink, surface),
          greaterThanOrEqualTo(7),
          reason: p.id,
        );
        expect(
          _contrast(p.inkMuted, surface),
          greaterThanOrEqualTo(4.5),
          reason: '${p.id} muted',
        );
        expect(
          _contrast(p.inkFaint, surface),
          greaterThanOrEqualTo(4.5),
          reason: '${p.id} faint',
        );
        // Text buttons and links use the accents as text colours.
        for (final accent in [p.primary, p.secondary, p.tertiary]) {
          expect(
            _contrast(accent, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${p.id} accent $accent on $surface',
          );
        }
      }
      expect(
        _contrast(p.onPrimary, p.primary),
        greaterThanOrEqualTo(4.5),
        reason: '${p.id} label on primary',
      );
      // Selected chips: the accent on its own tint.
      expect(
        _contrast(p.isDark ? p.primary : p.ink, p.primaryTint),
        greaterThanOrEqualTo(4.5),
        reason: '${p.id} on primary tint',
      );
      expect(
        _contrast(p.isDark ? p.secondary : p.ink, p.secondaryTint),
        greaterThanOrEqualTo(4.5),
        reason: '${p.id} on secondary tint',
      );
    }
  });

  test('Gothic uses a display face that ships with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${ThemePresets.gothic.displayFamily}'));
    expect(pubspec, contains('family: ${ThemePresets.snow.displayFamily}'));
  });

  for (final preset in looks) {
    testWidgets('${preset.label} atmosphere and title card paint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.themeFor(preset),
          home: Scaffold(
            body: Builder(
              builder: (context) => Stack(
                children: [
                  ThemeAtmosphere(preset: preset),
                  Center(
                    child: TextButton(
                      onPressed: () => showThemeTitleCard(context, preset),
                      child: const Text('Show'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Show'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(preset.label), findsOneWidget);
      expect(find.text(preset.tagline), findsOneWidget);
      // The title card dismisses itself.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(preset.tagline), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
