import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'theme_presets.dart';

/// How much cinema a context gets.
enum CinematicLevel {
  /// Reduced motion (the platform setting or the Calm look): no motion, no
  /// flashes, scenes hold still.
  still,

  /// The everyday looks (Today, Daylight, Ember): short, quiet transitions
  /// and nothing ambient: no grain, glow or sheen.
  subtle,

  /// A cinematic look (Forge, Neon Grid, Snow, Gothic...): animated scenes,
  /// depth transitions, sheen and glow.
  full;

  static CinematicLevel of(BuildContext context) {
    if (AppTheme.reduceMotionOf(context)) {
      return still;
    }
    final preset = Theme.of(context).extension<ConnectPalette>()?.preset;
    return forPreset(preset);
  }

  static CinematicLevel forPreset(ThemePreset? preset) {
    if (preset == null) {
      return subtle;
    }
    if (preset.reducedMotion) {
      return still;
    }
    return ThemePresets.isEveryday(preset) ? subtle : full;
  }
}

/// The app's motion vocabulary, so a page cut, a tab change, a title card
/// and a reward burst all move with the same timing.
abstract final class CinematicMotion {
  /// The camera settling: fast out, long soft landing.
  static const Curve settle = Cubic(0.16, 1, 0.3, 1);

  /// A scene leaving: gentle acceleration away.
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);

  /// Everyday entrances.
  static const Curve enter = Curves.easeOutCubic;

  static const Duration pageCut = Duration(milliseconds: 420);
  static const Duration tabCut = Duration(milliseconds: 360);
  static const Duration tabCutSubtle = Duration(milliseconds: 200);
}

/// The app-wide page transition.
///
/// * Cinematic looks: a depth cut. The incoming page fades up while the
///   camera settles from 4% too close; the page underneath sinks back to 94%
///   and dims, like a shot pulling focus to the next one. Popping plays it
///   in reverse.
/// * Everyday looks (Today): the quiet fade and 3.5% rise the app has always
///   had, nothing on the page underneath.
/// * Reduced motion: no animation at all; the page simply appears.
///
/// iOS and macOS keep the edge swipe-back gesture: the page is wrapped in
/// Cupertino's own transition (driven at rest so it adds no motion of its
/// own) purely for its gesture detector, and while a swipe is in progress
/// both pages follow the finger linearly instead of playing the cut. Android
/// back (button, gesture or [PopScope]) pops through the navigator as usual;
/// this builder only decides how the pop looks.
class CinematicPageTransitionsBuilder extends PageTransitionsBuilder {
  const CinematicPageTransitionsBuilder();

  @override
  Duration get transitionDuration => CinematicMotion.pageCut;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    var page = child;
    final platform = Theme.of(context).platform;
    final cupertinoGesture =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (cupertinoGesture) {
      page = CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        route,
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      );
    }
    final gesture =
        cupertinoGesture &&
        (route.popGestureInProgress ||
            (route.navigator?.userGestureInProgress ?? false));
    return CinematicPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      level: CinematicLevel.of(context),
      fingerDriven: gesture,
      child: page,
    );
  }
}

/// One page's half of a cut. The widget structure is identical in every
/// mode (only the animations driving it change), so switching between a
/// depth cut, a quiet rise, no motion or a finger-driven swipe never
/// remounts the page: a swipe-back in progress survives, and so does every
/// screen's state when a member changes looks.
class CinematicPageTransition extends StatelessWidget {
  const CinematicPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.level,
    required this.child,
    this.fingerDriven = false,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final CinematicLevel level;

  /// Both pages track an iOS swipe-back linearly.
  final bool fingerDriven;
  final Widget child;

  static const Animation<double> _one = AlwaysStoppedAnimation<double>(1);
  static const Animation<double> _zero = AlwaysStoppedAnimation<double>(0);
  static const Animation<Offset> _still = AlwaysStoppedAnimation<Offset>(
    Offset.zero,
  );

  static final Animatable<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.035),
    end: Offset.zero,
  ).chain(CurveTween(curve: CinematicMotion.enter));
  static final Animatable<double> _quietFade = CurveTween(
    curve: CinematicMotion.enter,
  );
  static final Animatable<double> _fadeIn = CurveTween(
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  static final Animatable<double> _settle = Tween<double>(
    begin: 1.04,
    end: 1,
  ).chain(CurveTween(curve: CinematicMotion.settle));
  static final Animatable<double> _sink = Tween<double>(
    begin: 1,
    end: 0.94,
  ).chain(CurveTween(curve: CinematicMotion.settle));
  static final Animatable<double> _dim = Tween<double>(
    begin: 0,
    end: 0.42,
  ).chain(CurveTween(curve: Curves.easeOut));
  static final Animatable<Offset> _inFromRight = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  );
  static final Animatable<Offset> _outToLeft = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1 / 3, 0),
  );

  @override
  Widget build(BuildContext context) {
    final depth = level == CinematicLevel.full && !fingerDriven;
    final quiet = level == CinematicLevel.subtle && !fingerDriven;
    return SlideTransition(
      position: fingerDriven ? secondaryAnimation.drive(_outToLeft) : _still,
      child: SlideTransition(
        position: fingerDriven
            ? animation.drive(_inFromRight)
            : quiet
            ? animation.drive(_rise)
            : _still,
        child: ScaleTransition(
          // The page underneath sinks back as the next shot takes over.
          scale: depth ? secondaryAnimation.drive(_sink) : _one,
          child: FadeTransition(
            opacity: depth
                ? animation.drive(_fadeIn)
                : quiet
                ? animation.drive(_quietFade)
                : _one,
            child: ScaleTransition(
              // The camera settles from slightly too close.
              scale: depth ? animation.drive(_settle) : _one,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child,
                  // Dims this page while the next one covers it. Pure
                  // paint: never takes a tap or reaches a screen reader.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Dim(
                        animation: depth
                            ? secondaryAnimation.drive(_dim)
                            : _zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dim extends AnimatedWidget {
  const _Dim({required Animation<double> animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value;
    if (value <= 0.001) {
      return const SizedBox.expand();
    }
    return ColoredBox(
      color: Colors.black.withValues(alpha: value.clamp(0.0, 1.0)),
    );
  }
}

/// An [IndexedStack] for the bottom-navigation tabs with a cinematic cut.
///
/// Every tab stays alive exactly as in an [IndexedStack]. Hidden tabs have
/// their tickers paused ([TickerMode]) so their scenes and animations stop
/// while nobody can see them, and their heroes disabled ([HeroMode]) so a
/// photo can fly from the visible tab only.
///
/// Switching tabs fades the new tab up from the ground; a cinematic look
/// adds a slight slide in the direction of travel and a settle in scale.
/// Reduced motion switches instantly.
class CinematicTabStack extends StatefulWidget {
  const CinematicTabStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  State<CinematicTabStack> createState() => _CinematicTabStackState();
}

class _CinematicTabStackState extends State<CinematicTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cut = AnimationController(
    vsync: this,
    duration: CinematicMotion.tabCut,
    value: 1,
  );
  int _direction = 0;
  CinematicLevel _level = CinematicLevel.subtle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _level = CinematicLevel.of(context);
  }

  @override
  void didUpdateWidget(CinematicTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) {
      return;
    }
    _direction = (widget.index - oldWidget.index).sign;
    if (_level == CinematicLevel.still) {
      _cut.value = 1;
      return;
    }
    _cut
      ..duration = _level == CinematicLevel.full
          ? CinematicMotion.tabCut
          : CinematicMotion.tabCutSubtle
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _cut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.index,
    children: [
      for (var i = 0; i < widget.children.length; i++)
        HeroMode(
          enabled: i == widget.index,
          child: TickerMode(
            enabled: i == widget.index,
            child: _TabCut(
              animation: i == widget.index ? _cut : kAlwaysCompleteAnimation,
              direction: _direction,
              full: _level == CinematicLevel.full,
              child: widget.children[i],
            ),
          ),
        ),
    ],
  );
}

class _TabCut extends StatelessWidget {
  const _TabCut({
    required this.animation,
    required this.direction,
    required this.full,
    required this.child,
  });

  final Animation<double> animation;
  final int direction;
  final bool full;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eased = animation.drive(
      CurveTween(curve: full ? CinematicMotion.settle : CinematicMotion.enter),
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(full ? 0.04 * direction : 0, 0),
          end: Offset.zero,
        ).animate(eased),
        child: ScaleTransition(
          scale: Tween<double>(begin: full ? 0.985 : 1, end: 1).animate(eased),
          child: child,
        ),
      ),
    );
  }
}
