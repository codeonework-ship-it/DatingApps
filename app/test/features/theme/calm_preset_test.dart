import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';

/// Calm is the low-stimulation look: a flat ground, no atmosphere scene, no
/// title card, and every reduce-motion gate treats it as if the OS setting
/// were on.
void main() {
  Future<BuildContext> mountBackdrop(
    WidgetTester tester,
    ThemePreset preset,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.themeFor(preset),
        home: Scaffold(
          body: PostLoginBackdrop(
            child: Builder(
              builder: (context) {
                captured = context;
                return const Text('content');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  testWidgets('calm backdrop draws a flat ground with no atmosphere', (
    tester,
  ) async {
    final context = await mountBackdrop(tester, ThemePresets.calm);

    expect(ThemePresets.calm.reducedMotion, isTrue);
    expect(find.byType(ThemeAtmosphere), findsNothing);
    expect(find.byType(CrystalBloom), findsNothing);
    expect(find.text('content'), findsOneWidget);
    expect(AppTheme.reduceMotionOf(context), isTrue);
    // No OS setting is on: the palette alone is what asked for stillness.
    expect(MediaQuery.disableAnimationsOf(context), isFalse);
  });

  testWidgets('a cinematic preset still gets its atmosphere', (tester) async {
    final context = await mountBackdrop(tester, ThemePresets.deepField);

    expect(ThemePresets.deepField.reducedMotion, isFalse);
    expect(find.byType(ThemeAtmosphere), findsOneWidget);
    expect(AppTheme.reduceMotionOf(context), isFalse);
  });

  testWidgets('choosing calm shows no title card', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final calmCard = showThemeTitleCard(captured, ThemePresets.calm);
    await tester.pump();
    expect(find.text('NOW SHOWING'), findsNothing);
    expect(find.text('Calm'), findsNothing);
    await calmCard;

    // The same call for a cinematic look does put the card up.
    unawaited(showThemeTitleCard(captured, ThemePresets.deepField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('NOW SHOWING'), findsOneWidget);
    expect(find.text('Deep Field'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  });
}
