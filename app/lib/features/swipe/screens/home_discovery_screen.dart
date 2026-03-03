import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../engagement/providers/daily_prompt_provider.dart';
import '../../engagement/screens/daily_prompt_screen.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../models/discovery_profile.dart';
import '../providers/swipe_provider.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'passed_profiles_screen.dart';
import 'profile_details_screen.dart';

class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  const HomeDiscoveryScreen({Key? key, this.onOpenFilters, this.onOpenMessages})
    : super(key: key);
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
  bool _showLikeBurst = false;
  bool _isSuperLikeBurst = false;

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
          duration: const Duration(milliseconds: 980),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showLikeBurst = false);
          }
        });
  }

  @override
  void dispose() {
    _headerController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeNotifierProvider);
    final swipeNotifier = ref.read(swipeNotifierProvider.notifier);
    final dailyPromptState = ref.watch(dailyPromptProvider);

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
                                'Discover',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find meaningful verified matches',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                Row(
                                  children: [
                                    Expanded(child: titleBlock()),
                                    const SizedBox(width: 8),
                                    passedButton(),
                                    const SizedBox(width: 8),
                                    filtersButton(),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _MiniStatChip(
                                      label: 'Likes',
                                      value: likesValue,
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

                          return Row(
                            children: [
                              Expanded(child: titleBlock()),
                              const SizedBox(width: 8),
                              _MiniStatChip(label: 'Likes', value: likesValue),
                              const SizedBox(width: 8),
                              _MiniStatChip(label: 'Left', value: leftValue),
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
                                  'No profiles',
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
                                  'All reviewed!',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: AppTheme.textDark),
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final compactHeight =
                                    constraints.maxHeight < 760;
                                final controlsGap = compactHeight ? 12.0 : 24.0;
                                final bottomGap = compactHeight ? 18.0 : 72.0;
                                final currentProfile = swipeState
                                    .profiles[swipeState.currentIndex];

                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
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
                                            milliseconds: 520,
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
                                                    (1 - value) * 0.30;
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
                                            child: SwipeCard(
                                              profile: currentProfile,
                                              onTap: () async {
                                                swipeNotifier.recordProfileView(
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

                                                if (!context.mounted) return;
                                                if (action ==
                                                    ProfileDetailsAction.like) {
                                                  await _handleLikeAction(
                                                    swipeNotifier:
                                                        swipeNotifier,
                                                    currentProfile:
                                                        currentProfile,
                                                    showSuperLikeSnack: false,
                                                    isSuperLike: false,
                                                  );
                                                } else if (action ==
                                                    ProfileDetailsAction.pass) {
                                                  await swipeNotifier
                                                      .passProfile();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: controlsGap),
                                        SwipeButtons(
                                          onPass: () async {
                                            await swipeNotifier.passProfile();
                                          },
                                          onLike: () async {
                                            await _handleLikeAction(
                                              swipeNotifier: swipeNotifier,
                                              currentProfile: currentProfile,
                                              showSuperLikeSnack: false,
                                              isSuperLike: false,
                                            );
                                          },
                                          onSuperLike: () async {
                                            final currentProfile =
                                                swipeState.profiles[swipeState
                                                    .currentIndex];
                                            await _handleLikeAction(
                                              swipeNotifier: swipeNotifier,
                                              currentProfile: currentProfile,
                                              showSuperLikeSnack: true,
                                              isSuperLike: true,
                                            );
                                          },
                                          onMessage: () async {
                                            if (widget.onOpenMessages != null) {
                                              widget.onOpenMessages!();
                                              return;
                                            }
                                            await Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const MatchesListScreen(),
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
                      builder: (_, __) => _LikeDecisionBurst(
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
          final delay = index * 0.11;
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
                      ? (index == 1 ? 56 : 48)
                      : (index == 1 ? 30 : 28),
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
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
  );
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
