import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../engagement/providers/daily_prompt_provider.dart';
import '../../matching/providers/match_provider.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../../messaging/screens/chat_screen.dart';
import '../models/discovery_profile.dart';
import '../models/discovery_notification_item.dart';
import '../providers/swipe_provider.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'passed_profiles_screen.dart';
import 'profile_details_screen.dart';
import 'spotlight_profiles_screen.dart';

class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  const HomeDiscoveryScreen({
    super.key,
    this.onOpenFilters,
    this.onOpenMessages,
    this.activeFilterChips = const <String>[],
  });
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;
  final List<String> activeFilterChips;

  @override
  ConsumerState<HomeDiscoveryScreen> createState() =>
      _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends ConsumerState<HomeDiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _likeBurstController;
  AnimationController? _cardSpinController;
  bool _showLikeBurst = false;
  bool _isSuperLikeBurst = false;
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerController.forward();

    _likeBurstController =
        AnimationController(
          duration: const Duration(milliseconds: 1400),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showLikeBurst = false);
          }
        });

    _cardSpinController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _likeBurstController.dispose();
    _cardSpinController?.dispose();
    super.dispose();
  }

  void _triggerCardSpin() {
    final controller = _cardSpinController;
    if (controller == null || controller.isAnimating) {
      return;
    }
    controller.forward(from: 0);
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

    _likeBurstController.reset();
    if (waitForCompletion) {
      await _likeBurstController.forward();
      return;
    }
    _likeBurstController.forward();
  }

  Future<void> _handleLikeAction({
    required SwipeNotifier swipeNotifier,
    required DiscoveryProfile currentProfile,
    required bool showSuperLikeSnack,
    required bool isSuperLike,
  }) async {
    if (isSuperLike) {
      await _triggerLikeBurst(isSuperLike: true, waitForCompletion: true);
    } else {
      await _triggerLikeBurst(isSuperLike: false, waitForCompletion: false);
    }

    final matchId = await swipeNotifier.likeProfile();
    if (!mounted) return;

    if (matchId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => MatchNotificationScreen(
            matchId: matchId,
            otherUserId: currentProfile.id,
            otherUserName: currentProfile.name,
            otherUserPhotoUrl: currentProfile.photoUrls.first,
          ),
        ),
      );
      return;
    }

    if (showSuperLikeSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Super like sent to ${currentProfile.name}')),
      );
    }
  }

  Future<void> _runLockedAction(Future<void> Function() action) async {
    if (_isActionBusy) {
      return;
    }
    if (mounted) {
      setState(() => _isActionBusy = true);
    }
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  Future<void> _openConversationForProfile({
    required DiscoveryProfile profile,
    required SwipeNotifier swipeNotifier,
  }) async {
    final matchState = ref.read(matchNotifierProvider);
    Match? selectedMatch;

    for (final candidate in matchState.matches) {
      if (candidate.userId == profile.id) {
        selectedMatch = candidate;
        break;
      }
    }

    if (selectedMatch == null) {
      final matchId = await swipeNotifier.likeProfile();
      if (!mounted) return;
      if (matchId != null && matchId.trim().isNotEmpty) {
        selectedMatch = Match(
          id: matchId,
          userId: profile.id,
          userName: profile.name,
          userPhoto: profile.photoUrls.isNotEmpty
              ? profile.photoUrls.first
              : '',
          lastMessage: 'Say hi 👋',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          isOnline: false,
        );
      }
    }

    if (!mounted) return;

    if (selectedMatch == null) {
      selectedMatch = Match(
        id: 'pending-${profile.id}',
        userId: profile.id,
        userName: profile.name,
        userPhoto: profile.photoUrls.isNotEmpty ? profile.photoUrls.first : '',
        lastMessage: 'Start your conversation',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation started with ${profile.name}')),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          matchId: selectedMatch!.id,
          otherUserId: selectedMatch.userId,
          userName: selectedMatch.userName,
          userPhotoUrl: selectedMatch.userPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeNotifierProvider);
    final swipeNotifier = ref.read(swipeNotifierProvider.notifier);
    final matchState = ref.watch(matchNotifierProvider);
    final dailyPromptState = ref.watch(dailyPromptProvider);
    final spotlightProfiles = swipeState.spotlightProfiles;
    final unreadNotifications = buildDiscoveryNotificationStack(
      repliedCount: dailyPromptState.responders.length,
      likedMeCount: matchState.matches.length,
    );
    final isSpotlightMode =
        swipeState.discoveryMode == SwipeNotifier.discoveryModeSpotlight;

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
                          final smallActionLabel = width < 390;
                          final passedValue = swipeState.passedProfiles.length
                              .toString();

                          Widget filtersButton() => _HeaderActionButton(
                            icon: Icons.tune_rounded,
                            label: 'Filters',
                            onTap: widget.onOpenFilters,
                            compact: smallActionLabel,
                          );

                          Widget notificationsButton() =>
                              _NotificationBellButton(
                                unreadCount: unreadNotifications.length,
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => _UnreadNotificationsSheet(
                                      notifications: unreadNotifications,
                                    ),
                                  );
                                },
                              );

                          Widget messagesButton() => _HeaderActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Messages',
                            onTap: widget.onOpenMessages,
                            compact: smallActionLabel,
                          );

                          Widget passedButton() => _HeaderActionButton(
                            icon: Icons.history,
                            label: 'Passed ($passedValue)',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PassedProfilesScreen(),
                                ),
                              );
                            },
                            compact: smallActionLabel,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Discover Matches',
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
                                          'Find meaningful verified matches',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textGrey,
                                              ),
                                        ),
                                        if (widget.activeFilterChips.isNotEmpty)
                                          const SizedBox(height: 6),
                                        if (widget.activeFilterChips.isNotEmpty)
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: widget.activeFilterChips
                                                .map(
                                                  (chip) => _ActiveFilterChip(
                                                    label: chip,
                                                  ),
                                                )
                                                .toList(growable: false),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  notificationsButton(),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: passedButton()),
                                  SizedBox(width: actionSpacing),
                                  Expanded(child: messagesButton()),
                                  SizedBox(width: actionSpacing),
                                  Expanded(child: filtersButton()),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (!isSpotlightMode && spotlightProfiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _SpotlightRail(
                        profiles: spotlightProfiles,
                        onOpenProfile: (profile) async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ProfileDetailsScreen(profile: profile),
                            ),
                          );
                        },
                        onViewMore: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SpotlightProfilesScreen(
                                profiles: spotlightProfiles,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: swipeState.isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.trustBlue,
                              ),
                            )
                          : swipeState.profiles.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sentiment_dissatisfied,
                                  color: AppTheme.textHint,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSpotlightMode
                                      ? 'No spotlight profiles'
                                      : 'No profiles',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: AppTheme.textDark),
                                ),
                                if (swipeState.trustFilterActive &&
                                    swipeState.trustFilteredOutCount > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Trust filters hid ${swipeState.trustFilteredOutCount} profile(s). Try relaxing trust filters.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textGrey.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                  ),
                                ],
                              ],
                            )
                          : swipeState.currentIndex >=
                                swipeState.profiles.length
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
                                  isSpotlightMode
                                      ? 'Spotlight reviewed!'
                                      : 'All reviewed!',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: AppTheme.textDark),
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final controlsGap = 8.0;
                                final bottomGap = 12.0;
                                final width = constraints.maxWidth;
                                final horizontalContentPadding = width < 390
                                    ? 12.0
                                    : width < 600
                                    ? 16.0
                                    : width < 900
                                    ? 24.0
                                    : 32.0;
                                final currentProfile = swipeState
                                    .profiles[swipeState.currentIndex];

                                return SizedBox(
                                  height: constraints.maxHeight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  horizontalContentPadding,
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 820,
                                              ),
                                              switchInCurve:
                                                  Curves.easeOutCubic,
                                              switchOutCurve:
                                                  Curves.easeInCubic,
                                              transitionBuilder: (child, animation) {
                                                final fade = CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeOut,
                                                );
                                                return AnimatedBuilder(
                                                  animation: animation,
                                                  child: child,
                                                  builder: (context, child) {
                                                    final value =
                                                        animation.value;
                                                    final angle =
                                                        (1 - value) *
                                                        (math.pi * 2);
                                                    final scale =
                                                        0.94 + (value * 0.06);
                                                    final perspective =
                                                        Matrix4.identity()
                                                          ..setEntry(
                                                            3,
                                                            2,
                                                            0.0012,
                                                          )
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
                                                  'profile-${currentProfile.id}-${swipeState.currentIndex}',
                                                ),
                                                child: AnimatedBuilder(
                                                  animation:
                                                      _cardSpinController ??
                                                      const AlwaysStoppedAnimation<
                                                        double
                                                      >(0),
                                                  child: GestureDetector(
                                                    onDoubleTap:
                                                        _triggerCardSpin,
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                            maxWidth: 720,
                                                          ),
                                                      child: SwipeCard(
                                                        profile: currentProfile,
                                                        isActionLocked:
                                                            _isActionBusy,
                                                        onPassTap: () =>
                                                            _runLockedAction(
                                                              swipeNotifier
                                                                  .passProfile,
                                                            ),
                                                        onLikeTap: () => _runLockedAction(
                                                          () => _handleLikeAction(
                                                            swipeNotifier:
                                                                swipeNotifier,
                                                            currentProfile:
                                                                currentProfile,
                                                            showSuperLikeSnack:
                                                                false,
                                                            isSuperLike: false,
                                                          ),
                                                        ),
                                                        onMessageTap: () =>
                                                            _runLockedAction(
                                                              () => _openConversationForProfile(
                                                                profile:
                                                                    currentProfile,
                                                                swipeNotifier:
                                                                    swipeNotifier,
                                                              ),
                                                            ),
                                                        onTap: () async {
                                                          swipeNotifier
                                                              .recordProfileView(
                                                                currentProfile
                                                                    .id,
                                                              );
                                                          final action =
                                                              await Navigator.of(
                                                                context,
                                                              ).push<
                                                                ProfileDetailsAction
                                                              >(
                                                                MaterialPageRoute<
                                                                  ProfileDetailsAction
                                                                >(
                                                                  builder: (_) =>
                                                                      ProfileDetailsScreen(
                                                                        profile:
                                                                            currentProfile,
                                                                      ),
                                                                ),
                                                              );

                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }
                                                          if (action ==
                                                              ProfileDetailsAction
                                                                  .love) {
                                                            await _runLockedAction(
                                                              () => _handleLikeAction(
                                                                swipeNotifier:
                                                                    swipeNotifier,
                                                                currentProfile:
                                                                    currentProfile,
                                                                showSuperLikeSnack:
                                                                    true,
                                                                isSuperLike:
                                                                    true,
                                                              ),
                                                            );
                                                          } else if (action ==
                                                              ProfileDetailsAction
                                                                  .message) {
                                                            await _runLockedAction(
                                                              () => _openConversationForProfile(
                                                                profile:
                                                                    currentProfile,
                                                                swipeNotifier:
                                                                    swipeNotifier,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  builder: (context, child) {
                                                    final spinValue =
                                                        _cardSpinController
                                                            ?.value ??
                                                        0;
                                                    return Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: Matrix4.identity()
                                                        ..setEntry(3, 2, 0.0017)
                                                        ..rotateY(
                                                          math.pi *
                                                              2 *
                                                              Curves
                                                                  .easeInOutCubic
                                                                  .transform(
                                                                    spinValue,
                                                                  ),
                                                        ),
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: controlsGap),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: horizontalContentPadding,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 720,
                                          ),
                                          child: SwipeButtons(
                                            onPass: () async {
                                              await _runLockedAction(
                                                swipeNotifier.passProfile,
                                              );
                                            },
                                            onLike: () async {
                                              await _runLockedAction(
                                                () => _handleLikeAction(
                                                  swipeNotifier: swipeNotifier,
                                                  currentProfile:
                                                      currentProfile,
                                                  showSuperLikeSnack: false,
                                                  isSuperLike: false,
                                                ),
                                              );
                                            },
                                            onSuperLike: () async {
                                              await _runLockedAction(
                                                () => _handleLikeAction(
                                                  swipeNotifier: swipeNotifier,
                                                  currentProfile:
                                                      currentProfile,
                                                  showSuperLikeSnack: true,
                                                  isSuperLike: true,
                                                ),
                                              );
                                            },
                                            onMessage: () async {
                                              await _runLockedAction(
                                                () =>
                                                    _openConversationForProfile(
                                                      profile: currentProfile,
                                                      swipeNotifier:
                                                          swipeNotifier,
                                                    ),
                                              );
                                            },
                                            onUndo: swipeNotifier.undoSwipe,
                                            canUndo:
                                                swipeState.currentIndex > 0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: bottomGap),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
              if (_showLikeBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _likeBurstController,
                      builder: (_, _) => _LikeDecisionBurst(
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

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label});

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

class _LikeDecisionBurst extends StatelessWidget {
  const _LikeDecisionBurst({required this.progress, required this.isSuperLike});

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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 14 : 15, color: AppTheme.textDark),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10 : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.2)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_rounded,
            size: 18,
            color: AppTheme.textDark,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -7,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
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

class _UnreadNotificationsSheet extends StatelessWidget {
  const _UnreadNotificationsSheet({required this.notifications});

  final List<DiscoveryNotificationItem> notifications;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest unread notifications',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (notifications.isEmpty)
          Text(
            'No unread notifications',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
          )
        else
          ...notifications.map(
            (notification) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.trustBlue.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppTheme.trustBlue.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    notification.type == DiscoveryNotificationType.whoRepliedMe
                        ? Icons.visibility_outlined
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: AppTheme.trustBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          notification.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _SpotlightRail extends StatelessWidget {
  const _SpotlightRail({
    required this.profiles,
    required this.onOpenProfile,
    required this.onViewMore,
  });

  final List<DiscoveryProfile> profiles;
  final ValueChanged<DiscoveryProfile> onOpenProfile;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    final items = profiles.take(6).toList(growable: false);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 390
        ? 112.0
        : screenWidth < 600
        ? 128.0
        : 140.0;
    final railHeight = screenWidth < 390
        ? 132.0
        : screenWidth < 600
        ? 142.0
        : 152.0;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      blur: 12,
      crystalEffect: true,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.trustBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Spotlight',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onViewMore, child: const Text('View more')),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final profile = items[index];
                return GestureDetector(
                  onTap: () => onOpenProfile(profile),
                  child: SizedBox(
                    width: cardWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            profile.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.white,
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.58),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                if (profile.isVerified)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
