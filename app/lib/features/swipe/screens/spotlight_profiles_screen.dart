import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/discovery_profile.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'profile_details_screen.dart';

class SpotlightProfilesScreen extends StatefulWidget {
  const SpotlightProfilesScreen({super.key, required this.profiles});

  final List<DiscoveryProfile> profiles;

  @override
  State<SpotlightProfilesScreen> createState() =>
      _SpotlightProfilesScreenState();
}

class _SpotlightProfilesScreenState extends State<SpotlightProfilesScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _passedCount = 0;
  int _unreadCount = 0;
  final List<_SpotlightSwipeAction> _history = <_SpotlightSwipeAction>[];
  bool _verifiedOnly = false;
  RangeValues _ageRange = const RangeValues(20, 50);
  late AnimationController _likeBurstController;
  bool _showLikeBurst = false;
  bool _isSuperLikeBurst = false;

  @override
  void initState() {
    super.initState();
    _likeBurstController =
        AnimationController(
          duration: const Duration(milliseconds: 1200),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showLikeBurst = false);
          }
        });
  }

  @override
  void dispose() {
    _likeBurstController.dispose();
    super.dispose();
  }

  Future<void> _triggerLikeBurst({
    required bool isSuperLike,
    required bool waitForCompletion,
  }) async {
    if (mounted) {
      setState(() {
        _showLikeBurst = true;
        _isSuperLikeBurst = isSuperLike;
      });
    }

    if (waitForCompletion) {
      await _likeBurstController.forward(from: 0);
      return;
    }
    _likeBurstController.forward(from: 0);
  }

  List<DiscoveryProfile> _applyFilters(List<DiscoveryProfile> source) {
    return source
        .where((profile) {
          final age = profile.age;
          if (_verifiedOnly && !profile.isVerified) {
            return false;
          }
          if (age < _ageRange.start || age > _ageRange.end) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _openSpotlightFilters() async {
    var localVerifiedOnly = _verifiedOnly;
    var localAgeRange = _ageRange;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.postLoginGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textHint.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Spotlight Filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Verified only'),
                      value: localVerifiedOnly,
                      onChanged: (value) {
                        setSheetState(() => localVerifiedOnly = value);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Age range: ${localAgeRange.start.round()} - ${localAgeRange.end.round()}',
                    ),
                    RangeSlider(
                      values: localAgeRange,
                      min: 18,
                      max: 60,
                      divisions: 42,
                      onChanged: (value) {
                        setSheetState(() => localAgeRange = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                localVerifiedOnly = false;
                                localAgeRange = const RangeValues(20, 50);
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _verifiedOnly = localVerifiedOnly;
                                _ageRange = localAgeRange;
                                _currentIndex = 0;
                                _history.clear();
                                _passedCount = 0;
                                _unreadCount = 0;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _advance(_SpotlightSwipeAction action) {
    final filteredLength = _applyFilters(widget.profiles).length;
    if (_currentIndex >= filteredLength) {
      return;
    }
    setState(() {
      _history.add(action);
      if (action == _SpotlightSwipeAction.pass) {
        _passedCount += 1;
      }
      if (action == _SpotlightSwipeAction.message) {
        _unreadCount += 1;
      }
      _currentIndex += 1;
    });
  }

  void _undo() {
    if (_currentIndex <= 0 || _history.isEmpty) {
      return;
    }
    final last = _history.removeLast();
    setState(() {
      _currentIndex -= 1;
      if (last == _SpotlightSwipeAction.pass && _passedCount > 0) {
        _passedCount -= 1;
      }
      if (last == _SpotlightSwipeAction.message && _unreadCount > 0) {
        _unreadCount -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProfiles = _applyFilters(widget.profiles);
    final currentProfile = _currentIndex < filteredProfiles.length
        ? filteredProfiles[_currentIndex]
        : null;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      blur: 12,
                      crystalEffect: true,
                      borderRadius: BorderRadius.circular(18),
                      shadows: [
                        BoxShadow(
                          color: AppTheme.trustBlue.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final actionSpacing = width < 390 ? 6.0 : 8.0;
                          final compact = width < 390;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GlassContainer(
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                    padding: const EdgeInsets.all(8),
                                    borderRadius: BorderRadius.circular(12),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.72,
                                    ),
                                    blur: 10,
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Spotlight Matches',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppTheme.textDark,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Curated premium connections',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textGrey,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (_verifiedOnly)
                                              _SpotlightFilterChip(
                                                label: 'Verified only',
                                              ),
                                            _SpotlightFilterChip(
                                              label:
                                                  '${_ageRange.start.round()}–${_ageRange.end.round()}',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SpotlightNotificationButton(
                                    unreadCount: _unreadCount,
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('No new notifications'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SpotlightActionButton(
                                      icon: Icons.history,
                                      label: 'Passed ($_passedCount)',
                                      compact: compact,
                                      onTap: () {},
                                    ),
                                  ),
                                  SizedBox(width: actionSpacing),
                                  Expanded(
                                    child: _SpotlightActionButton(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      label: 'Messages',
                                      compact: compact,
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Open chats from Discover',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: actionSpacing),
                                  Expanded(
                                    child: _SpotlightActionButton(
                                      icon: Icons.tune_rounded,
                                      label: 'Filters',
                                      compact: compact,
                                      onTap: _openSpotlightFilters,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: currentProfile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.trustBlue,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                filteredProfiles.isEmpty
                                    ? 'No spotlight profiles for current filters'
                                    : 'Spotlight reviewed!',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: AppTheme.textDark),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final horizontalPadding = width < 390
                                  ? 12.0
                                  : width < 600
                                  ? 16.0
                                  : width < 900
                                  ? 24.0
                                  : 32.0;

                              return Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: horizontalPadding,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 680,
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 820,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder: (child, animation) {
                                              final fade = CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOut,
                                              );
                                              return AnimatedBuilder(
                                                animation: animation,
                                                child: child,
                                                builder: (context, child) {
                                                  final value = animation.value;
                                                  final angle =
                                                      (1 - value) *
                                                      (math.pi * 2);
                                                  final scale =
                                                      0.94 + (value * 0.06);
                                                  final perspective =
                                                      Matrix4.identity()
                                                        ..setEntry(3, 2, 0.0012)
                                                        ..rotateY(angle)
                                                        ..multiply(
                                                          Matrix4.diagonal3Values(
                                                            scale,
                                                            scale,
                                                            1,
                                                          ),
                                                        );

                                                  return FadeTransition(
                                                    opacity: fade,
                                                    child: Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: perspective,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: KeyedSubtree(
                                              key: ValueKey<String>(
                                                'spotlight-${currentProfile.id}-$_currentIndex',
                                              ),
                                              child: SwipeCard(
                                                profile: currentProfile,
                                                onPassTap: () => _advance(
                                                  _SpotlightSwipeAction.pass,
                                                ),
                                                onLikeTap: () async {
                                                  await _triggerLikeBurst(
                                                    isSuperLike: false,
                                                    waitForCompletion: false,
                                                  );
                                                  _advance(
                                                    _SpotlightSwipeAction.like,
                                                  );
                                                },
                                                onMessageTap: () => _advance(
                                                  _SpotlightSwipeAction.message,
                                                ),
                                                onTap: () async {
                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          ProfileDetailsScreen(
                                                            profile:
                                                                currentProfile,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 680,
                                      ),
                                      child: SwipeButtons(
                                        onPass: () async => _advance(
                                          _SpotlightSwipeAction.pass,
                                        ),
                                        onLike: () async {
                                          await _triggerLikeBurst(
                                            isSuperLike: false,
                                            waitForCompletion: false,
                                          );
                                          _advance(_SpotlightSwipeAction.like);
                                        },
                                        onSuperLike: () async {
                                          await _triggerLikeBurst(
                                            isSuperLike: true,
                                            waitForCompletion: false,
                                          );
                                          _advance(
                                            _SpotlightSwipeAction.superLike,
                                          );
                                        },
                                        onMessage: () async => _advance(
                                          _SpotlightSwipeAction.message,
                                        ),
                                        onUndo: _undo,
                                        canUndo: _currentIndex > 0,
                                        isSpotlightContext: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
              if (_showLikeBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _likeBurstController,
                      builder: (_, _) => _SpotlightLikeBurst(
                        progress: _likeBurstController.value,
                        isSuperLike: _isSuperLikeBurst,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SpotlightSwipeAction { pass, like, superLike, message }

class _SpotlightLikeBurst extends StatelessWidget {
  const _SpotlightLikeBurst({
    required this.progress,
    required this.isSuperLike,
  });

  final double progress;
  final bool isSuperLike;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final centerX = constraints.maxWidth / 2;
      return Stack(
        children: List<Widget>.generate(3, (index) {
          final delay = index * 0.17;
          final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
          if (local <= 0) {
            return const SizedBox.shrink();
          }

          final eased = Curves.easeOutCubic.transform(local);
          final sway =
              ((index - 1) * (isSuperLike ? 26 : 20)) +
              math.sin(local * math.pi * 1.5) * (isSuperLike ? 7 : 5);
          final scale =
              (isSuperLike ? 1.12 : 0.9) +
              (1 - local) * (isSuperLike ? 0.32 : 0.18);
          final opacity = ((1 - local) * 0.82).clamp(0.0, 0.82);

          return Positioned(
            left: centerX + sway - 16,
            bottom: 126 + (eased * (isSuperLike ? 172 : 136)) + (index * 7),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite_rounded,
                  color: index == 1
                      ? AppTheme.crystalRose.withValues(alpha: 0.96)
                      : AppTheme.crystalRose.withValues(alpha: 0.84),
                  size: isSuperLike
                      ? (index == 1 ? 72 : 62)
                      : (index == 1 ? 48 : 42),
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}

class _SpotlightFilterChip extends StatelessWidget {
  const _SpotlightFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.trustBlue.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SpotlightActionButton extends StatelessWidget {
  const _SpotlightActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppTheme.textDark,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 11 : null,
    );

    return GlassContainer(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 9 : 10,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.72),
      blur: 10,
      crystalEffect: true,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 15 : 16, color: AppTheme.textDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightNotificationButton extends StatelessWidget {
  const _SpotlightNotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassContainer(
          onTap: onTap,
          padding: const EdgeInsets.all(10),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          blur: 10,
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.textDark,
            size: 19,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
