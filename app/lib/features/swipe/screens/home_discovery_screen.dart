import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../engagement/providers/daily_prompt_provider.dart';
import '../../engagement/screens/daily_prompt_screen.dart';
import '../../matching/providers/match_provider.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../../messaging/screens/chat_screen.dart';
import '../models/discovery_profile.dart';
import '../providers/swipe_provider.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'liked_profiles_screen.dart';
import 'passed_profiles_screen.dart';
import 'profile_details_screen.dart';

class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  const HomeDiscoveryScreen({super.key, this.onOpenFilters, this.onOpenMessages});
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;

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
    final dailyPromptState = ref.watch(dailyPromptProvider);
    final spotlightProfiles = swipeState.spotlightProfiles;
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
                          final compact = constraints.maxWidth < 430;
                          final medium = constraints.maxWidth < 760;
                          final likesValue = swipeState.likeCount.toString();
                          final passedValue = swipeState.passedProfiles.length
                              .toString();
                          final leftValue =
                              (swipeState.profiles.length -
                                      swipeState.currentIndex)
                                  .clamp(0, swipeState.profiles.length)
                                  .toString();

                          Widget titleBlock() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSpotlightMode ? 'Spotlight' : 'Discover',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSpotlightMode
                                    ? 'Top boosted profiles for you'
                                    : 'Find meaningful verified matches',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DiscoveryModeChip(
                                    label: 'Discover',
                                    selected: !isSpotlightMode,
                                    onTap: () => swipeNotifier.setDiscoveryMode(
                                      SwipeNotifier.discoveryModeAll,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _DiscoveryModeChip(
                                    label: 'Spotlight',
                                    selected: isSpotlightMode,
                                    onTap: () => swipeNotifier.setDiscoveryMode(
                                      SwipeNotifier.discoveryModeSpotlight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );

                          Widget filtersButton() => GestureDetector(
                            onTap: widget.onOpenFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.88),
                                border: Border.all(
                                  color: AppTheme.trustBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                    color: AppTheme.textDark,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      color: AppTheme.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          Widget messagesButton() => GestureDetector(
                            onTap: widget.onOpenMessages,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.88),
                                border: Border.all(
                                  color: AppTheme.trustBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: AppTheme.textDark,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Messages',
                                    style: TextStyle(
                                      color: AppTheme.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          Widget passedButton() => GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PassedProfilesScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.88),
                                border: Border.all(
                                  color: AppTheme.trustBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history,
                                    size: 16,
                                    color: AppTheme.textDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Passed ($passedValue)',
                                    style: const TextStyle(
                                      color: AppTheme.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Expanded(child: titleBlock())]),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    passedButton(),
                                    messagesButton(),
                                    filtersButton(),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _MiniStatChip(
                                      label: 'Likes',
                                      value: likesValue,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const LikedProfilesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _MiniStatChip(
                                      label: 'Left',
                                      value: leftValue,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          if (medium) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Expanded(child: titleBlock())]),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniStatChip(
                                      label: 'Likes',
                                      value: likesValue,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const LikedProfilesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _MiniStatChip(
                                      label: 'Left',
                                      value: leftValue,
                                    ),
                                    messagesButton(),
                                    passedButton(),
                                    filtersButton(),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: titleBlock()),
                              const SizedBox(width: 8),
                              _MiniStatChip(
                                label: 'Likes',
                                value: likesValue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const LikedProfilesScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _MiniStatChip(label: 'Left', value: leftValue),
                              const SizedBox(width: 10),
                              messagesButton(),
                              const SizedBox(width: 10),
                              passedButton(),
                              const SizedBox(width: 10),
                              filtersButton(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (dailyPromptState.view != null ||
                      dailyPromptState.isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _DailyPromptReplyPanel(
                        state: dailyPromptState,
                        responders: dailyPromptState.responders,
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DailyPromptScreen(),
                            ),
                          );
                        },
                        onOpenProfile: (responder) => _openResponderProfile(
                          context,
                          responder,
                          swipeState.profiles,
                        ),
                        onOpenChat: (responder) => _openResponderChat(context),
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
                                final compactHeight =
                                    constraints.maxHeight < 760;
                                final controlsGap = compactHeight ? 8.0 : 24.0;
                                final bottomGap = compactHeight ? 8.0 : 72.0;
                                final currentProfile = swipeState
                                    .profiles[swipeState.currentIndex];

                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedSwitcher(
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
                                                    (1 - value) * (math.pi * 2);
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
                                                    alignment: Alignment.center,
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
                                                onDoubleTap: _triggerCardSpin,
                                                child: SwipeCard(
                                                  profile: currentProfile,
                                                  isActionLocked: _isActionBusy,
                                                  onPassTap: () =>
                                                      _runLockedAction(
                                                        swipeNotifier.passProfile,
                                                      ),
                                                  onLikeTap: () =>
                                                      _runLockedAction(
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
                                                        () =>
                                                            _openConversationForProfile(
                                                              profile:
                                                                  currentProfile,
                                                              swipeNotifier:
                                                                  swipeNotifier,
                                                            ),
                                                      ),
                                                  onTap: () async {
                                                    swipeNotifier
                                                        .recordProfileView(
                                                          currentProfile.id,
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

                                                    if (!context.mounted) {
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
                                                          isSuperLike: true,
                                                        ),
                                                      );
                                                    } else if (action ==
                                                        ProfileDetailsAction
                                                            .message) {
                                                      await _runLockedAction(
                                                        () =>
                                                            _openConversationForProfile(
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
                                              builder: (context, child) {
                                                final spinValue =
                                                    _cardSpinController
                                                        ?.value ??
                                                    0;
                                                return Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.identity()
                                                    ..setEntry(3, 2, 0.0017)
                                                    ..rotateY(
                                                      math.pi *
                                                          2 *
                                                          Curves.easeInOutCubic
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
                                        SizedBox(height: controlsGap),
                                        SwipeButtons(
                                          onPass: () async {
                                            await _runLockedAction(
                                              swipeNotifier.passProfile,
                                            );
                                          },
                                          onLike: () async {
                                            await _runLockedAction(
                                              () => _handleLikeAction(
                                                swipeNotifier: swipeNotifier,
                                                currentProfile: currentProfile,
                                                showSuperLikeSnack: false,
                                                isSuperLike: false,
                                              ),
                                            );
                                          },
                                          onSuperLike: () async {
                                            await _runLockedAction(
                                              () => _handleLikeAction(
                                                swipeNotifier: swipeNotifier,
                                                currentProfile: currentProfile,
                                                showSuperLikeSnack: true,
                                                isSuperLike: true,
                                              ),
                                            );
                                          },
                                          onMessage: () async {
                                            await _runLockedAction(
                                              () => _openConversationForProfile(
                                                profile: currentProfile,
                                                swipeNotifier: swipeNotifier,
                                              ),
                                            );
                                          },
                                          onUndo: swipeNotifier.undoSwipe,
                                          canUndo: swipeState.currentIndex > 0,
                                        ),
                                        SizedBox(height: bottomGap),
                                      ],
                                    ),
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

  void _openResponderProfile(
    BuildContext context,
    DailyPromptResponderPreview responder,
    List<DiscoveryProfile> profiles,
  ) {
    for (final profile in profiles) {
      if (profile.id != responder.userId) {
        continue;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileDetailsScreen(profile: profile),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile preview unavailable for ${responder.displayName}.',
        ),
      ),
    );
  }

  Future<void> _openResponderChat(BuildContext context) async {
    if (widget.onOpenMessages != null) {
      widget.onOpenMessages!();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MatchesListScreen()));
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

class _DiscoveryModeChip extends StatelessWidget {
  const _DiscoveryModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? AppTheme.trustBlue.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.86),
          border: Border.all(
            color: selected
                ? AppTheme.trustBlue.withValues(alpha: 0.35)
                : AppTheme.trustBlue.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.trustBlue : AppTheme.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.88),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textGrey),
          ),
        ],
      ),
    ),
  );
}

class _SpotlightRail extends StatelessWidget {
  const _SpotlightRail({required this.profiles, required this.onOpenProfile});

  final List<DiscoveryProfile> profiles;
  final ValueChanged<DiscoveryProfile> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final items = profiles.take(6).toList(growable: false);
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
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final profile = items[index];
                final tier = (profile.spotlightTier ?? '').trim();
                final tierLabel = tier.isEmpty
                    ? 'Spotlight'
                    : '${tier[0].toUpperCase()}${tier.substring(1)}';
                return GestureDetector(
                  onTap: () => onOpenProfile(profile),
                  child: Container(
                    width: 188,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.trustBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: profile.photoUrls.isNotEmpty
                              ? NetworkImage(profile.photoUrls.first)
                              : null,
                          child: profile.photoUrls.isEmpty
                              ? const Icon(Icons.person_outline_rounded)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tierLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _DailyPromptReplyPanel extends StatelessWidget {
  const _DailyPromptReplyPanel({
    required this.state,
    required this.responders,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onOpenChat,
  });

  final DailyPromptState state;
  final List<DailyPromptResponderPreview> responders;
  final VoidCallback onOpen;
  final ValueChanged<DailyPromptResponderPreview> onOpenProfile;
  final ValueChanged<DailyPromptResponderPreview> onOpenChat;

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    if (state.isLoading && view == null) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        blur: 8,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.trustBlue),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading daily prompt activity...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }
    if (view == null) {
      return const SizedBox.shrink();
    }

    final statusLine = view.answer == null
        ? 'Today: ${view.spark.participantsToday} replies'
        : 'You replied · ${view.spark.similarAnswerCount} similar answers';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      blur: 8,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.trustBlue.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: AppTheme.trustBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See who replied',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      statusLine,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onOpen, child: const Text('Open')),
            ],
          ),
          if (state.isRespondersLoading && responders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (responders.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...responders
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: item.photoUrl.trim().isEmpty
                              ? null
                              : NetworkImage(item.photoUrl),
                          child: item.photoUrl.trim().isEmpty
                              ? Text(
                                  item.displayName.isNotEmpty
                                      ? item.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onOpenProfile(item),
                          icon: const Icon(Icons.person_outline, size: 18),
                          tooltip: 'Open profile',
                        ),
                        IconButton(
                          onPressed: () => onOpenChat(item),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          tooltip: 'Open chat',
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
