import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/cinematic_effects.dart';
import 'package:verified_dating_app/core/theme/cinematic_motion.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';

/// The app-wide page cut and the tab cut: cinematic looks get depth, the
/// everyday look stays quiet, reduced motion gets none, and back still pops.
void main() {
  final themes = <String, ThemeData>{};

  Widget app(
    ThemePreset preset, {
    bool reduceMotion = false,
    TargetPlatform? platform,
    GlobalKey<NavigatorState>? navigator,
    Widget? home,
  }) {
    // One ThemeData per look, so rebuilding the app does not start a
    // theme animation (the cinematic button style holds a closure).
    var theme = themes.putIfAbsent(
      preset.id,
      () => ThemePresets.themeFor(preset),
    );
    if (platform != null) {
      theme = theme.copyWith(platform: platform);
    }
    return MaterialApp(
      navigatorKey: navigator,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: home ?? const Scaffold(body: Center(child: Text('First'))),
    );
  }

  Route<void> next({bool guarded = false, VoidCallback? onBlocked}) =>
      MaterialPageRoute<void>(
        builder: (_) => PopScope(
          canPop: !guarded,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              onBlocked?.call();
            }
          },
          child: const Scaffold(body: Center(child: Text('Second'))),
        ),
      );

  Iterable<double> opacitiesAbove(WidgetTester tester, String text) => tester
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(FadeTransition),
        ),
      )
      .map((f) => f.opacity.value);

  Iterable<double> scalesAbove(WidgetTester tester, String text) => tester
      .widgetList<ScaleTransition>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(ScaleTransition),
        ),
      )
      .map((s) => s.scale.value);

  test('cinematic looks put a sheen behind primary buttons', () {
    final cinematic = ThemePresets.themeFor(ThemePresets.forge);
    final everyday = ThemePresets.themeFor(ThemePresets.realLife);
    final calm = ThemePresets.themeFor(ThemePresets.calm);
    final builder = cinematic.filledButtonTheme.style?.backgroundBuilder;
    expect(builder, isNotNull);
    // A static tear-off: the same function for every build of the look.
    expect(
      ThemePresets.themeFor(
        ThemePresets.forge,
      ).filledButtonTheme.style?.backgroundBuilder,
      same(builder),
    );
    // Everyday looks and Calm keep the couture fill but get no sheen: a
    // different builder from the cinematic one.
    final quiet = everyday.filledButtonTheme.style?.backgroundBuilder;
    expect(quiet, isNotNull);
    expect(quiet, isNot(same(builder)));
    expect(calm.filledButtonTheme.style?.backgroundBuilder, same(quiet));
  });

  testWidgets('only cinematic looks mount a sheen on primary buttons', (
    tester,
  ) async {
    for (final (preset, sheens) in [
      (ThemePresets.forge, 1),
      (ThemePresets.realLife, 0),
      (ThemePresets.calm, 0),
    ]) {
      // A fresh app per look, so no theme morph is in flight.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.themeFor(preset),
          home: Scaffold(
            body: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );
      expect(
        find.byType(CinematicSheen),
        findsNWidgets(sheens),
        reason: preset.id,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('every platform uses the cinematic builder', () {
    final builders = ThemePresets.themeFor(
      ThemePresets.forge,
    ).pageTransitionsTheme.builders;
    for (final platform in TargetPlatform.values) {
      expect(builders[platform], isA<CinematicPageTransitionsBuilder>());
    }
  });

  testWidgets('a cinematic look cuts with depth: fade, settle and dim', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(ThemePresets.forge, navigator: navigator));
    unawaited(navigator.currentState!.push(next()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(opacitiesAbove(tester, 'Second').any((o) => o < 1), isTrue);
    expect(scalesAbove(tester, 'Second').any((s) => s > 1), isTrue);
    // The page underneath sinks back.
    expect(scalesAbove(tester, 'First').any((s) => s < 1), isTrue);

    await tester.pumpAndSettle();
    expect(opacitiesAbove(tester, 'Second').every((o) => o == 1), isTrue);
    expect(scalesAbove(tester, 'Second').every((s) => s == 1), isTrue);
  });

  testWidgets('the everyday look keeps its quiet fade and rise', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(ThemePresets.realLife, navigator: navigator));
    unawaited(navigator.currentState!.push(next()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(opacitiesAbove(tester, 'Second').any((o) => o < 1), isTrue);
    // No depth, no dimming of the page underneath.
    expect(scalesAbove(tester, 'Second').every((s) => s == 1), isTrue);
    expect(scalesAbove(tester, 'First').every((s) => s == 1), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: the next page simply appears', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      app(ThemePresets.gothic, navigator: navigator, reduceMotion: true),
    );
    unawaited(navigator.currentState!.push(next()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(opacitiesAbove(tester, 'Second').every((o) => o == 1), isTrue);
    expect(scalesAbove(tester, 'Second').every((s) => s == 1), isTrue);
    expect(scalesAbove(tester, 'First').every((s) => s == 1), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('the Calm look is treated as reduced motion', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(ThemePresets.calm, navigator: navigator));
    unawaited(navigator.currentState!.push(next()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacitiesAbove(tester, 'Second').every((o) => o == 1), isTrue);
    await tester.pumpAndSettle();
  });

  for (final preset in [ThemePresets.forge, ThemePresets.realLife]) {
    testWidgets('system back still pops (${preset.label})', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(preset, navigator: navigator));
      unawaited(navigator.currentState!.push(next()));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);

      // Android's back button / gesture arrives as a pop-route message.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('First'), findsOneWidget);
    });
  }

  testWidgets('PopScope still intercepts back under the cinematic cut', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    var blocked = 0;
    await tester.pumpWidget(app(ThemePresets.neonGrid, navigator: navigator));
    unawaited(
      navigator.currentState!.push(
        next(guarded: true, onBlocked: () => blocked++),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(blocked, 1);
  });

  testWidgets('iOS keeps the edge swipe back', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      app(
        ThemePresets.deepField,
        navigator: navigator,
        platform: TargetPlatform.iOS,
      ),
    );
    unawaited(navigator.currentState!.push(next()));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(4, 300));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    // Mid-swipe the page follows the finger.
    final slides = tester.widgetList<SlideTransition>(
      find.ancestor(
        of: find.text('Second'),
        matching: find.byType(SlideTransition),
      ),
    );
    expect(slides.any((s) => s.position.value.dx > 0), isTrue);
    await gesture.moveBy(const Offset(500, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(find.text('First'), findsOneWidget);
  });

  group('CinematicTabStack', () {
    Widget tabs(ThemePreset preset, int index, {bool reduceMotion = false}) =>
        app(
          preset,
          reduceMotion: reduceMotion,
          home: Scaffold(
            body: CinematicTabStack(
              index: index,
              children: [
                for (final name in ['Tab A', 'Tab B', 'Tab C'])
                  Builder(
                    builder: (context) {
                      final live = TickerMode.valuesOf(context).enabled;
                      return Text('$name ${live ? 'live' : 'paused'}');
                    },
                  ),
              ],
            ),
          ),
        );

    testWidgets('keeps every tab alive and pauses hidden ones', (tester) async {
      await tester.pumpWidget(tabs(ThemePresets.forge, 0));
      expect(find.text('Tab A live'), findsOneWidget);
      expect(find.text('Tab B paused', skipOffstage: false), findsOneWidget);
      expect(find.text('Tab C paused', skipOffstage: false), findsOneWidget);

      await tester.pumpWidget(tabs(ThemePresets.forge, 2));
      await tester.pumpAndSettle();
      expect(find.text('Tab C live'), findsOneWidget);
      expect(find.text('Tab A paused', skipOffstage: false), findsOneWidget);
    });

    testWidgets('a cinematic look cuts between tabs', (tester) async {
      await tester.pumpWidget(tabs(ThemePresets.forge, 0));
      await tester.pumpWidget(tabs(ThemePresets.forge, 1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(opacitiesAbove(tester, 'Tab B live').any((o) => o < 1), isTrue);
      expect(scalesAbove(tester, 'Tab B live').any((s) => s < 1), isTrue);
      await tester.pumpAndSettle();
      expect(opacitiesAbove(tester, 'Tab B live').every((o) => o == 1), isTrue);
    });

    testWidgets('the everyday look only fades', (tester) async {
      await tester.pumpWidget(tabs(ThemePresets.realLife, 0));
      await tester.pumpWidget(tabs(ThemePresets.realLife, 1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(opacitiesAbove(tester, 'Tab B live').any((o) => o < 1), isTrue);
      expect(scalesAbove(tester, 'Tab B live').every((s) => s == 1), isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion switches instantly', (tester) async {
      await tester.pumpWidget(tabs(ThemePresets.forge, 0, reduceMotion: true));
      await tester.pumpWidget(tabs(ThemePresets.forge, 1, reduceMotion: true));
      await tester.pump();
      expect(opacitiesAbove(tester, 'Tab B live').every((o) => o == 1), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
