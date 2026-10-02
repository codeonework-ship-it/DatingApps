import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/core/theme/theme_motifs.dart';
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
  const looks = [ThemePresets.blueRose, ThemePresets.blueLotus];

  test('Blue Rose and Blue Lotus are selectable dark looks', () {
    for (final preset in looks) {
      expect(ThemePresets.themed, contains(same(preset)), reason: preset.id);
      expect(ThemePresets.byId(preset.id), same(preset));
      expect(preset.brightness, Brightness.dark);
      expect(preset.tagline, isNotEmpty);
      expect(preset.swatch, hasLength(3));
      expect(preset.reducedMotion, isFalse);
      expect(ThemePresets.isEveryday(preset), isFalse);
      expect(
        ThemeAtmospherePainter.animatedScenes,
        contains(preset.id),
        reason: '${preset.id} has its own scene',
      );
      final selection = AppThemeSelection.fromWire('auto:${preset.id}');
      expect(selection.preset, same(preset));
      expect(selection.themeMode, ThemeMode.dark);
      expect(selection.wireValue, 'auto:${preset.id}');
    }
    expect(ThemePresets.blueRose.label, 'Blue Rose');
    expect(ThemePresets.blueLotus.label, 'Blue Lotus');
    // Calm stays last in the strip as the quiet option.
    expect(ThemePresets.themed.last, same(ThemePresets.calm));
  });

  test('the blue looks meet WCAG AA everywhere text sits', () {
    for (final p in looks) {
      for (final surface in [p.ground, p.paper, p.paperSunk]) {
        expect(
          _contrast(p.ink, surface),
          greaterThanOrEqualTo(7),
          reason: p.id,
        );
        for (final text in [
          p.inkMuted,
          p.inkFaint,
          // Text buttons and links use the accents as text colours.
          p.primary,
          p.secondary,
          p.tertiary,
        ]) {
          expect(
            _contrast(text, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${p.id} $text on $surface',
          );
        }
      }
      expect(_contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.onPrimary, p.jewel), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.primary, p.primaryTint), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(p.secondary, p.secondaryTint),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('the lotus motif paints at any size and strength', () {
    for (final radius in [0.0, 6.0, 40.0, 180.0]) {
      for (final alpha in [0.0, 0.3, 1.0, 1.4]) {
        final recorder = ui.PictureRecorder();
        ThemeMotifs.drawLotus(
          Canvas(recorder),
          const Offset(100, 100),
          radius,
          heart: Colors.white,
          edge: Colors.blue,
          stamen: Colors.amber,
          alpha: alpha,
          twist: radius,
        );
        recorder.endRecording().dispose();
      }
    }
  });

  test('each blue scene paints still and in motion', () {
    for (final preset in looks) {
      for (final t in [0.0, 1.3, 9.0, 14.5, 61.0]) {
        final recorder = ui.PictureRecorder();
        ThemeAtmospherePainter(
          preset: preset,
          time: t,
        ).paint(Canvas(recorder), const Size(390, 844));
        recorder.endRecording().dispose();
      }
    }
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
