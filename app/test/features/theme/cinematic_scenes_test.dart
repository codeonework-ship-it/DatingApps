import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/cinematic_clock.dart';
import 'package:verified_dating_app/core/theme/cinematic_effects.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';

/// Every scene paints at every size and moment, the motion stays inside
/// photosensitivity limits, and the title card behaves as a scene change.
void main() {
  const sizes = [
    Size.zero,
    Size(1, 1),
    Size(88, 88),
    Size(360, 640),
    Size(412, 915),
    Size(1280, 800),
    Size(2560, 1440),
  ];
  // Still frame, mid motion, inside the neon flicker, the forge arc and the
  // shooting star windows, and a long-running session.
  const moments = [0.0, 1.7, 3.65, 3.9, 5.5, 6.3, 9.0, 61.37, 86400.5];

  for (final preset in ThemePresets.all) {
    test('${preset.label} scene paints at every size and moment', () {
      for (final size in sizes) {
        for (final film in [true, false]) {
          for (final t in moments) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            ThemeAtmospherePainter(
              preset: preset,
              time: t,
              film: film,
            ).paint(canvas, size);
            recorder.endRecording().dispose();
          }
        }
      }
    });
  }

  test('every cinematic look has a moving scene', () {
    for (final preset in ThemePresets.themed) {
      if (preset.reducedMotion) {
        continue;
      }
      expect(
        ThemeAtmospherePainter.animatedScenes,
        contains(preset.id),
        reason: preset.id,
      );
    }
  });

  test('a scene repaints with the clock and not otherwise', () {
    final clock = ValueNotifier<double>(0);
    final live = ThemeAtmospherePainter(
      preset: ThemePresets.snow,
      clock: clock,
    );
    final still = ThemeAtmospherePainter(preset: ThemePresets.snow);
    expect(live.shouldRepaint(still), isTrue);
    expect(
      still.shouldRepaint(ThemeAtmospherePainter(preset: ThemePresets.snow)),
      isFalse,
    );
    expect(
      still.shouldRepaint(ThemeAtmospherePainter(preset: ThemePresets.gothic)),
      isTrue,
    );
    clock.dispose();
  });

  test('neon flicker never changes more than six times a second', () {
    // Three flashes a second is the WCAG 2.3.1 general flash threshold; a
    // flash is a pair of opposing changes, so at most six changes.
    const step = 0.005;
    final changes = <double>[];
    var last = debugNeonFlicker(0);
    for (var t = step; t < 120; t += step) {
      final v = debugNeonFlicker(t);
      if (v != last) {
        changes.add(t);
      }
      last = v;
    }
    expect(changes, isNotEmpty);
    for (var i = 0; i < changes.length; i++) {
      final inWindow = changes
          .where((c) => c >= changes[i] && c < changes[i] + 1)
          .length;
      expect(inWindow, lessThanOrEqualTo(6), reason: 'at ${changes[i]}s');
    }
  });

  test('candles waver gently rather than strobe', () {
    for (var t = 0.0; t < 60; t += 0.01) {
      for (var i = 0; i < 3; i++) {
        final v = debugCandleFlicker(t, i);
        expect(v, inInclusiveRange(0.8, 1.2));
      }
    }
  });

  test('a big-moment bloom is one soft swell, not a flash sequence', () {
    var peaks = 0;
    var prev = CinematicBloomPainter.strengthAt(0);
    var rising = false;
    for (var p = 0.001; p <= 1; p += 0.001) {
      final s = CinematicBloomPainter.strengthAt(p);
      if (s > prev) {
        rising = true;
      } else if (s < prev && rising) {
        peaks++;
        rising = false;
      }
      prev = s;
    }
    expect(peaks, 1);
    expect(CinematicBloomPainter.strengthAt(0), 0);
    expect(CinematicBloomPainter.strengthAt(0.6), 0);
  });

  test('title flares paint for every look across their run', () {
    for (final preset in ThemePresets.all) {
      for (var p = 0.0; p <= 1; p += 0.125) {
        final recorder = ui.PictureRecorder();
        TitleFlarePainter(
          preset: preset,
          progress: p,
        ).paint(Canvas(recorder), const Size(412, 915));
        recorder.endRecording().dispose();
      }
    }
  });

  group('title card', () {
    setUp(CinematicClock.instance.debugReset);

    Future<BuildContext> mount(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('slides in letterbox bars, reveals the title, then leaves', (
      tester,
    ) async {
      final context = await mount(tester);
      unawaited(showThemeTitleCard(context, ThemePresets.forge));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final bars = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == Colors.black,
      );
      expect(bars, findsNWidgets(2));
      final topEarly = tester.getRect(bars.first).bottom;

      await tester.pump(const Duration(milliseconds: 560));
      expect(find.text('NOW SHOWING'), findsOneWidget);
      expect(find.text('Forge'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TitleFlarePainter,
        ),
        findsOneWidget,
      );
      expect(tester.getRect(bars.first).bottom, greaterThan(topEarly));

      await tester.pump(kThemeTitleCardHold);
      await tester.pumpAndSettle();
      expect(find.text('NOW SHOWING'), findsNothing);
    });

    testWidgets('a tap dismisses it early', (tester) async {
      final context = await mount(tester);
      unawaited(showThemeTitleCard(context, ThemePresets.snow));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('NOW SHOWING'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('NOW SHOWING'), findsNothing);
      // The hold timer was cancelled with the card.
      await tester.pump(kThemeTitleCardHold);
    });

    testWidgets('reduced motion: no flare, no fade, still dismisses', (
      tester,
    ) async {
      final context = await mount(tester, reduceMotion: true);
      unawaited(showThemeTitleCard(context, ThemePresets.gothic));
      await tester.pump();
      expect(find.text('Gothic'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TitleFlarePainter,
        ),
        findsNothing,
      );
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(kThemeTitleCardHold);
      await tester.pump();
      expect(find.text('Gothic'), findsNothing);
    });

    testWidgets('Calm skips the card', (tester) async {
      final context = await mount(tester);
      await showThemeTitleCard(context, ThemePresets.calm);
      await tester.pump();
      expect(find.text('NOW SHOWING'), findsNothing);
    });
  });
}
