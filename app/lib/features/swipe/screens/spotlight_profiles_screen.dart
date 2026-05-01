import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/discovery_profile.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'profile_details_screen.dart';

/// Spotlight profiles viewer with local filtering.
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
    _likeBurstController = AnimationController(
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
    return source.where((profile) {
      final age = profile.age;
      if (_verifiedOnly && !profile.isVerified) return false;
      if (age < _ageRange.start || age > _ageRange.end) return false;
      return true;
    }).toList(growable: false);
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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
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
    if (_currentIndex >= filteredLength) return;
    setState(() {
      _history.add(action);
      if (action == _SpotlightSwipeAction.pass) _passedCount += 1;
      if (action == _SpotlightSwipeAction.message) _unreadCount += 1;
      _currentIndex += 1;
    });
  }

  void _undo() {
    if (_currentIndex <= 0 || _history.isEmpty) return;
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
                  // ── Header ─────────────────────────────────────
                  _SpotlightHeader(
                    verifiedOnly: _verifiedOnly,
                    ageRange: _ageRange,
                    passedCount: _passedCount,
                    unreadCount: _unreadCount,
                    onBack: () => Navigator.of(context).maybePop(),
                    onFilters: _openSpotlightFilters,
                  ),

                  // ── Card area ──────────────────────────────────
                  Expanded(
                    child: currentProfile == null
                        ? _SpotlightEmptyState(
                            filteredCount: filteredProfiles.length,
                          )
                        : _SpotlightCardArea(
                            profile: currentProfile,
                            index: _currentIndex,
                            total: filteredProfiles.length,
                            canUndo: _currentIndex > 0,
                            onPass: () {
                              _advance(_SpotlightSwipeAction.pass);
                            },
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
                              _advance(_SpotlightSwipeAction.superLike);
                            },
                            onMessage: () {
                              _advance(_SpotlightSwipeAction.message);
                            },
                            onUndo: _undo,
                            onOpenProfile: () async {
                              final action = await Navigator.of(context)
                                  .push<ProfileDetailsAction>(
                                MaterialPageRoute<ProfileDetailsAction>(
                                  builder: (_) => ProfileDetailsScreen(
                                    profile: currentProfile,
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              if (action == ProfileDetailsAction.love) {
                                await _triggerLikeBurst(
                                  isSuperLike: true,
                                  waitForCompletion: false,
                                );
                                _advance(_SpotlightSwipeAction.superLike);
                              } else if (action ==
                                  ProfileDetailsAction.message) {
                                _advance(_SpotlightSwipeAction.message);
                              }
                            },
                          ),
                  ),
                ],
              ),

              // ── Like-burst overlay ───────────────────────────
              if (_showLikeBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _likeBurstController,
                      builder: (_, __) => _LikeBurst(
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

// ═══════════════════════════════════════════════════════════════════════════
// ── Action enum ─────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

enum _SpotlightSwipeAction { pass, like, superLike, message }

// ═══════════════════════════════════════════════════════════════════════════
// ── Header ──────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SpotlightHeader extends StatelessWidget {
  const _SpotlightHeader({
    required this.verifiedOnly,
    required this.ageRange,
    required this.passedCount,
    required this.unreadCount,
    required this.onBack,
    required this.onFilters,
  });
  final bool verifiedOnly;
  final RangeValues ageRange;
  final int passedCount;
  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.trustBlue.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.trustBlue.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            ?.copyWith(color: AppTheme.textGrey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (verifiedOnly)
                            _chip(context, 'Verified only'),
                          _chip(
                            context,
                            '${ageRange.start.round()}–${ageRange.end.round()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _bellButton(context, unreadCount),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    context,
                    icon: Icons.history,
                    label: 'Passed ($passedCount)',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Open chats from Discover'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    context,
                    icon: Icons.tune_rounded,
                    label: 'Filters',
                    onTap: onFilters,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.trustBlue.withValues(alpha: 0.12),
        border:
            Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.24)),
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

  Widget _bellButton(BuildContext context, int count) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new notifications')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.88),
          border:
              Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_rounded,
                size: 18, color: AppTheme.textDark),
            if (count > 0)
              Positioned(
                right: -7,
                top: -6,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.88),
          border:
              Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppTheme.textDark),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Card area ───────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SpotlightCardArea extends StatelessWidget {
  const _SpotlightCardArea({
    required this.profile,
    required this.index,
    required this.total,
    required this.canUndo,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
    required this.onUndo,
    required this.onOpenProfile,
  });
  final DiscoveryProfile profile;
  final int index;
  final int total;
  final bool canUndo;
  final VoidCallback onPass;
  final Future<void> Function() onLike;
  final Future<void> Function() onSuperLike;
  final VoidCallback onMessage;
  final VoidCallback onUndo;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hPad = width < 390
            ? 12.0
            : width < 600
                ? 16.0
                : 24.0;

        return Column(
          children: [
            // Progress bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? (index + 1) / total : 0,
                  minHeight: 4,
                  backgroundColor: AppTheme.textHint.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.trustBlue,
                  ),
                ),
              ),
            ),

            // Card
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: SwipeCard(
                      profile: profile,
                      isActionLocked: false,
                      onPassTap: onPass,
                      onLikeTap: onLike,
                      onMessageTap: onMessage,
                      onTap: onOpenProfile,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SwipeButtons(
                  onPass: () async => onPass(),
                  onLike: onLike,
                  onSuperLike: onSuperLike,
                  onMessage: () async => onMessage(),
                  onUndo: onUndo,
                  canUndo: canUndo,
                  isSpotlightContext: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Empty / reviewed state ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SpotlightEmptyState extends StatelessWidget {
  const _SpotlightEmptyState({required this.filteredCount});
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle,
              color: AppTheme.trustBlue, size: 64),
          const SizedBox(height: 16),
          Text(
            filteredCount == 0
                ? 'No spotlight profiles match filters'
                : 'All spotlight profiles reviewed!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new spotlight profiles',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Like-burst animation ────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _LikeBurst extends StatelessWidget {
  const _LikeBurst({required this.progress, required this.isSuperLike});
  final double progress;
  final bool isSuperLike;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        return Stack(
          children: List.generate(3, (i) {
            final delay = i * 0.17;
            final t =
                ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
            if (t <= 0) return const SizedBox.shrink();

            final eased = Curves.easeOutCubic.transform(t);
            final sway = ((i - 1) * (isSuperLike ? 26 : 20)) +
                math.sin(t * math.pi * 1.5) * (isSuperLike ? 7 : 5);
            final scale = (isSuperLike ? 1.12 : 0.9) +
                (1 - t) * (isSuperLike ? 0.32 : 0.18);
            final opacity = ((1 - t) * 0.82).clamp(0.0, 0.82);

            return Positioned(
              left: cx + sway - 16,
              bottom:
                  126 + (eased * (isSuperLike ? 172 : 136)) + (i * 7),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: i == 1
                        ? AppTheme.crystalRose
                            .withValues(alpha: 0.96)
                        : AppTheme.crystalRose
                            .withValues(alpha: 0.84),
                    size: isSuperLike
                        ? (i == 1 ? 72 : 62)
                        : (i == 1 ? 48 : 42),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
