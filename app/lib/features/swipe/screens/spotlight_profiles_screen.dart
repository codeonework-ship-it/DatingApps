import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/discovery_profile.dart';
import '../profile_actions.dart';
import '../providers/swipe_provider.dart';
import 'passed_profiles_screen.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'profile_details_screen.dart';

/// Spotlight profiles viewer with local filtering.
class SpotlightProfilesScreen extends ConsumerStatefulWidget {
  const SpotlightProfilesScreen({super.key, required this.profiles});
  final List<DiscoveryProfile> profiles;

  @override
  ConsumerState<SpotlightProfilesScreen> createState() =>
      _SpotlightProfilesScreenState();
}

class _SpotlightProfilesScreenState
    extends ConsumerState<SpotlightProfilesScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _passedCount = 0;
  int _unreadCount = 0;
  final List<_SpotlightSwipeAction> _history = <_SpotlightSwipeAction>[];
  bool _verifiedOnly = false;
  static const _defaultAgeRange = RangeValues(20, 50);
  RangeValues _ageRange = _defaultAgeRange;
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
          if (_verifiedOnly && !profile.isVerified) return false;
          // Hidden ages were checked by server eligibility and stay private.
          if (age != null && (age < _ageRange.start || age > _ageRange.end))
            return false;
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
            final l10n = AppLocalizations.of(context);
            return Container(
              decoration: BoxDecoration(
                gradient: AppTheme.groundGradientOf(context),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.discoverSpotlightFiltersTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      key: const ValueKey('qa.spotlight.filters.verified_only'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.discoverVerifiedOnly),
                      value: localVerifiedOnly,
                      onChanged: (value) {
                        setSheetState(() => localVerifiedOnly = value);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.discoverAgeRange(
                        localAgeRange.start.round(),
                        localAgeRange.end.round(),
                      ),
                    ),
                    RangeSlider(
                      key: const ValueKey('qa.spotlight.filters.age_range'),
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
                            key: const ValueKey('qa.spotlight.filters.reset'),
                            // Off while the filters already are the defaults:
                            // there is nothing to reset.
                            onPressed:
                                !localVerifiedOnly &&
                                    localAgeRange == _defaultAgeRange
                                ? null
                                : () {
                                    setSheetState(() {
                                      localVerifiedOnly = false;
                                      localAgeRange = _defaultAgeRange;
                                    });
                                  },
                            child: Text(l10n.commonReset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            key: const ValueKey('qa.spotlight.filters.apply'),
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
                            child: Text(l10n.commonApply),
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

  bool _deciding = false;

  /// Saves a like or pass for [profile], then moves to the next card.
  Future<void> _decide(
    DiscoveryProfile profile,
    _SpotlightSwipeAction action,
  ) async {
    if (_deciding) {
      return;
    }
    _deciding = true;
    try {
      final like = action != _SpotlightSwipeAction.pass;
      final saved = like
          ? await ProfileActions.love(context, ref, profile)
          : await ProfileActions.pass(context, ref, profile);
      if (!saved || !mounted) {
        return;
      }
      if (like) {
        await _triggerLikeBurst(
          isSuperLike: action == _SpotlightSwipeAction.superLike,
          waitForCompletion: false,
        );
      }
      _advance(action);
    } finally {
      _deciding = false;
    }
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
    // Passes and likes made here are recorded in the swipe state, which is
    // also what "Passed (n)" opens: keep it alive while Spotlight is open,
    // whatever screen it was opened from.
    ref.listen(swipeNotifierProvider, (_, _) {});
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
                            // Every button acts on this member through
                            // ProfileActions (these used to only move a local
                            // counter and never reached the server); the card
                            // advances only once the decision is saved.
                            onPass: () => _decide(
                              currentProfile,
                              _SpotlightSwipeAction.pass,
                            ),
                            onLike: () => _decide(
                              currentProfile,
                              _SpotlightSwipeAction.like,
                            ),
                            onSuperLike: () => _decide(
                              currentProfile,
                              _SpotlightSwipeAction.superLike,
                            ),
                            onMessage: () => ProfileActions.message(
                              context,
                              ref,
                              currentProfile,
                            ),
                            onUndo: _undo,
                            onOpenProfile: () async {
                              // Every other way into a profile records the
                              // view ("who viewed me"); Spotlight did not.
                              ref
                                  .read(swipeNotifierProvider.notifier)
                                  .recordProfileView(currentProfile.id)
                                  .ignore();
                              final action = await Navigator.of(context)
                                  .push<ProfileDetailsAction>(
                                    MaterialPageRoute<ProfileDetailsAction>(
                                      builder: (_) => ProfileDetailsScreen(
                                        profile: currentProfile,
                                      ),
                                    ),
                                  );
                              // The profile page saved the Love itself.
                              if (!context.mounted) return;
                              if (action == ProfileDetailsAction.love) {
                                await _triggerLikeBurst(
                                  isSuperLike: true,
                                  waitForCompletion: false,
                                );
                                _advance(_SpotlightSwipeAction.superLike);
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  container: true,
                  button: true,
                  label: l10n.commonBack,
                  child: GestureDetector(
                    key: const ValueKey('qa.spotlight.back_button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack,
                    // The 32pt tile sits inside a full 48pt tap target.
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: scheme.surfaceContainerHigh,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.discoverSpotlightTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.discoverSpotlightSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (verifiedOnly)
                            _chip(context, l10n.discoverVerifiedOnly),
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
                    qaKey: 'qa.spotlight.passed_button',
                    icon: Icons.history,
                    label: l10n.discoverPassedCount(passedCount),
                    // The members passed on (here and on Discover), where a
                    // pass can be reconsidered.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PassedProfilesScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    context,
                    qaKey: 'qa.spotlight.messages_button',
                    icon: Icons.chat_bubble_outline_rounded,
                    label: l10n.discoverMessages,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.discoverOpenChatsFromDiscover),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    context,
                    qaKey: 'qa.spotlight.filters_button',
                    icon: Icons.tune_rounded,
                    label: l10n.discoverFilters,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primaryContainer,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bellButton(BuildContext context, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: AppLocalizations.of(context).notificationsTitle,
      child: GestureDetector(
        key: const ValueKey('qa.spotlight.notifications_button'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).discoverNoNewNotifications,
              ),
            ),
          );
        },
        // The 44x36 pill sits inside a full 48pt tap target.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.surface,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    size: 18,
                    color: scheme.onSurface,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -7,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onError,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _actionButton(
    BuildContext context, {
    required String qaKey,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: ValueKey(qaKey),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? (index + 1) / total : 0,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
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
                      qaScope: 'qa.spotlight',
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
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            filteredCount == 0
                ? AppLocalizations.of(context).discoverNoSpotlightMatchFilters
                : AppLocalizations.of(context).discoverAllSpotlightReviewed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).discoverSpotlightCheckBackLater,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
            if (t <= 0) return const SizedBox.shrink();

            final eased = Curves.easeOutCubic.transform(t);
            final sway =
                ((i - 1) * (isSuperLike ? 26 : 20)) +
                math.sin(t * math.pi * 1.5) * (isSuperLike ? 7 : 5);
            final scale =
                (isSuperLike ? 1.12 : 0.9) +
                (1 - t) * (isSuperLike ? 0.32 : 0.18);
            final opacity = ((1 - t) * 0.82).clamp(0.0, 0.82);

            return Positioned(
              left: cx + sway - 16,
              bottom: 126 + (eased * (isSuperLike ? 172 : 136)) + (i * 7),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: i == 1
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.96)
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.84),
                    size: isSuperLike ? (i == 1 ? 72 : 62) : (i == 1 ? 48 : 42),
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
