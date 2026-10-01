import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cinematic/env_stub.dart'
    if (dart.library.io) 'cinematic/env_io.dart'
    as env;

/// The one clock every ambient effect in the app shares: the atmosphere
/// scenes behind each screen, the sheen on primary buttons and the glow on
/// live indicators.
///
/// One [Ticker] drives them all, so ten things drifting on screen cost one
/// frame callback, not ten. It runs only while
///
/// * at least one visible, motion-allowed effect is subscribed (an effect in
///   a route covered by another, or in a hidden tab, unsubscribes through
///   [TickerMode]; reduced motion never subscribes),
/// * the app is in the foreground (paused, hidden or detached stops it), and
/// * [ambientEnabled] is true (it is off under `flutter test`, so
///   `pumpAndSettle` still settles; tests that exercise the clock switch it
///   on).
///
/// Ambient motion is paced to [framesPerSecond] (30): after each tick the
/// ticker is muted, which also stops it scheduling frames, and a short timer
/// unmutes it for the next vsync. A screen whose only motion is ambient
/// therefore renders 30 frames a second rather than 60 or 120.
///
/// [time] is seconds of *running* time. It freezes while the clock is
/// stopped and resumes from the same value, so a scene never jumps when the
/// app comes back to the foreground.
class CinematicClock with WidgetsBindingObserver {
  CinematicClock._();

  static final CinematicClock instance = CinematicClock._();

  /// Frame budget for ambient motion.
  static const int framesPerSecond = 30;

  static const int _paceMs = (1000 ~/ framesPerSecond) - 6;

  /// Master switch for ambient motion. Off under `flutter test` by default.
  static bool ambientEnabled = !env.isRunningUnderFlutterTest;

  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Ticker? _ticker;
  Timer? _pacer;
  int _subscribers = 0;
  bool _observing = false;
  bool _foreground = true;
  Duration _banked = Duration.zero;
  Duration _run = Duration.zero;

  /// Seconds of running time. Listen to it (for example as a
  /// [CustomPainter]'s `repaint`) to redraw on each ambient frame.
  ValueListenable<double> get time => _time;

  /// Whether the shared ticker is currently running.
  bool get isTicking => _ticker?.isActive ?? false;

  /// How many effects are currently subscribed.
  int get subscriberCount => _subscribers;

  /// Whether the app is currently treated as in the foreground.
  bool get isForeground => _foreground;

  /// Registers one visible effect. Pair every call with [unsubscribe].
  void subscribe() {
    _subscribers++;
    _observe();
    _sync();
  }

  /// Releases one effect registered with [subscribe].
  void unsubscribe() {
    if (_subscribers > 0) {
      _subscribers--;
    }
    _sync();
  }

  /// Re-reads [ambientEnabled] (call after changing it).
  void refresh() => _sync();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Inactive is still on screen (a system sheet over the app); everything
    // else means nobody can see the scene.
    _foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _sync();
  }

  void _observe() {
    if (_observing) {
      return;
    }
    _observing = true;
    final binding = WidgetsBinding.instance..addObserver(this);
    final state = binding.lifecycleState;
    if (state != null) {
      _foreground =
          state == AppLifecycleState.resumed ||
          state == AppLifecycleState.inactive;
    }
  }

  void _sync() {
    final run = ambientEnabled && _foreground && _subscribers > 0;
    if (run && !isTicking) {
      _start();
    } else if (!run && isTicking) {
      _stop();
    }
  }

  void _start() {
    final ticker = _ticker ??= Ticker(_onTick, debugLabel: 'CinematicClock');
    _run = Duration.zero;
    ticker
      ..muted = false
      ..start();
  }

  void _stop() {
    _pacer?.cancel();
    _pacer = null;
    _banked += _run;
    _run = Duration.zero;
    _ticker
      ?..muted = false
      ..stop();
  }

  void _onTick(Duration elapsed) {
    _run = elapsed;
    _time.value = (_banked + elapsed).inMicroseconds / 1e6;
    // Hold the next ambient frame back to the frame budget.
    final ticker = _ticker;
    if (ticker == null) {
      return;
    }
    ticker.muted = true;
    _pacer?.cancel();
    _pacer = Timer(const Duration(milliseconds: _paceMs), () {
      _pacer = null;
      if (isTicking) {
        ticker.muted = false;
      }
    });
  }

  /// Returns the clock to its initial state between tests.
  @visibleForTesting
  void debugReset() {
    _stop();
    _ticker?.dispose();
    _ticker = null;
    _subscribers = 0;
    _banked = Duration.zero;
    _time.value = 0;
    _foreground = true;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    ambientEnabled = !env.isRunningUnderFlutterTest;
  }
}

/// Subscribes its subtree's effect to the [CinematicClock] while it is
/// visible and motion is allowed, and unsubscribes otherwise. Mix into the
/// [State] of any ambient effect and call [syncCinematicClock] from
/// `didChangeDependencies` and `didUpdateWidget`.
mixin CinematicClockSubscriber<T extends StatefulWidget> on State<T> {
  bool _clockSubscribed = false;

  /// Whether this effect is currently subscribed (and so animating).
  bool get cinematicClockLive => _clockSubscribed;

  /// Subscribes when [wantsMotion] and the subtree's [TickerMode] is on.
  void syncCinematicClock({required bool wantsMotion}) {
    final want = wantsMotion && TickerMode.valuesOf(context).enabled;
    if (want == _clockSubscribed) {
      return;
    }
    _clockSubscribed = want;
    if (want) {
      CinematicClock.instance.subscribe();
    } else {
      CinematicClock.instance.unsubscribe();
    }
  }

  @override
  void dispose() {
    if (_clockSubscribed) {
      _clockSubscribed = false;
      CinematicClock.instance.unsubscribe();
    }
    super.dispose();
  }
}
