import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/cinematic_clock.dart';
import 'package:verified_dating_app/core/theme/cinematic_effects.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';

/// The one shared ambient clock: it runs only while something visible and
/// motion-allowed is subscribed and the app is in the foreground.
void main() {
  final clock = CinematicClock.instance;

  setUp(() {
    clock.debugReset();
    CinematicClock.ambientEnabled = true;
  });

  tearDown(clock.debugReset);

  Widget app(
    ThemePreset preset, {
    bool reduceMotion = false,
    Widget? home,
  }) => MaterialApp(
    theme: ThemePresets.themeFor(preset),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home:
        home ?? const Scaffold(body: PostLoginBackdrop(child: Text('content'))),
  );

  test('is off under flutter test unless a test switches it on', () {
    clock.debugReset();
    expect(CinematicClock.ambientEnabled, isFalse);
    clock.subscribe();
    expect(clock.isTicking, isFalse);
    clock.unsubscribe();
  });

  testWidgets('one ticker runs while a cinematic scene is on screen', (
    tester,
  ) async {
    await tester.pumpWidget(app(ThemePresets.forge));
    expect(find.byType(ThemeAtmosphere), findsOneWidget);
    expect(clock.subscriberCount, 1);
    expect(clock.isTicking, isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(clock.time.value, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(clock.subscriberCount, 0);
    expect(clock.isTicking, isFalse);
  });

  testWidgets('backgrounding the app pauses the clock and resumes in place', (
    tester,
  ) async {
    await tester.pumpWidget(app(ThemePresets.snow));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(clock.isTicking, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(clock.isTicking, isTrue, reason: 'inactive is still on screen');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(clock.isTicking, isFalse);
    final frozen = clock.time.value;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.time.value, frozen);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(clock.isTicking, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    // No jump: time continues from where it froze.
    expect(clock.time.value, greaterThanOrEqualTo(frozen));
    expect(clock.time.value, lessThan(frozen + 1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion never subscribes: the scene holds still', (
    tester,
  ) async {
    await tester.pumpWidget(app(ThemePresets.gothic, reduceMotion: true));
    expect(find.byType(ThemeAtmosphere), findsOneWidget);
    expect(clock.subscriberCount, 0);
    expect(clock.isTicking, isFalse);
  });

  testWidgets('Calm paints no scene and runs no clock', (tester) async {
    await tester.pumpWidget(app(ThemePresets.calm));
    expect(find.byType(ThemeAtmosphere), findsNothing);
    expect(clock.isTicking, isFalse);
  });

  testWidgets('the everyday Today look runs nothing ambient', (tester) async {
    await tester.pumpWidget(
      app(
        ThemePresets.realLife,
        home: Scaffold(
          body: PostLoginBackdrop(
            child: Column(
              children: [
                GlassButton(label: 'Go', onPressed: () {}),
                const CinematicGlowPulse(child: SizedBox(width: 8, height: 8)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ThemeAtmosphere), findsNothing);
    expect(clock.subscriberCount, 0);
    expect(clock.isTicking, isFalse);
  });

  testWidgets('a still preview (ambient: false) never subscribes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ThemeAtmosphere(preset: ThemePresets.deepField, ambient: false),
      ),
    );
    expect(clock.subscriberCount, 0);
  });

  testWidgets('a scene covered by another route stops ticking', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemePresets.themeFor(ThemePresets.neonGrid),
        home: const Scaffold(body: PostLoginBackdrop(child: Text('home'))),
      ),
    );
    expect(clock.subscriberCount, 1);

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('plain page')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    // The covered route is offstage: its TickerMode is off.
    expect(clock.subscriberCount, 0);
    expect(clock.isTicking, isFalse);

    navigator.currentState!.pop();
    await tester.pump();
    expect(clock.subscriberCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('primary buttons in a cinematic look share the same ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ThemePresets.crimsonAlloy,
        home: Scaffold(
          body: PostLoginBackdrop(
            child: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('One')),
                GlassButton(label: 'Two', onPressed: () {}),
                const CinematicGlowPulse(child: SizedBox(width: 8, height: 8)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CinematicSheen), findsNWidgets(2));
    // Scene + two sheens + one glow, all on one ticker.
    expect(clock.subscriberCount, 4);
    expect(clock.isTicking, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(clock.subscriberCount, 0);
  });
}
