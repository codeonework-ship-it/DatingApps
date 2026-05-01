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

/// Main discovery / swipe screen.
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
  late final AnimationController _likeBurstController;
  bool _showLikeBurst = false;
  bool _isSuperLikeBurst = false;
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _likeBurstController =
        AnimationController(
          duration: const Duration(milliseconds: 1400),
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

  Future<void> _triggerLikeBurst({required bool isSuperLike}) async {
    if (mounted) {
      setState(() {
        _showLikeBurst = true;
        _isSuperLikeBurst = isSuperLike;
      });
    }
    _likeBurstController.forward(from: 0);
  }

  Future<void> _runLocked(Future<void> Function() action) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _handleLike({
    required SwipeNotifier notifier,
    required DiscoveryProfile profile,
    required bool isSuperLike,
    bool showSnack = false,
  }) async {
    await _triggerLikeBurst(isSuperLike: isSuperLike);
    final matchId = await notifier.likeProfile();
    if (!mounted) return;
    if (matchId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => MatchNotificationScreen(
            matchId: matchId,
            otherUserId: profile.id,
            otherUserName: profile.name,
            otherUserPhotoUrl: profile.photoUrls.first,
          ),
        ),
      );
      return;
    }
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Super like sent to ${profile.name}')),
      );
    }
  }

  Future<void> _openConversation({
    required DiscoveryProfile profile,
    required SwipeNotifier notifier,
  }) async {
    final matchState = ref.read(matchNotifierProvider);
    Match? selected;
    for (final m in matchState.matches) {
      if (m.userId == profile.id) {
        selected = m;
        break;
      }
    }
    if (selected == null) {
      final matchId = await notifier.likeProfile();
      if (!mounted) return;
      if (matchId != null && matchId.trim().isNotEmpty) {
        selected = Match(
          id: matchId,
          userId: profile.id,
          userName: profile.name,
          userPhoto: profile.photoUrls.isNotEmpty
              ? profile.photoUrls.first
              : '',
          lastMessage: 'Say hi',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          isOnline: false,
        );
        await ref.read(matchNotifierProvider.notifier).refresh();
      }
    }
    if (!mounted) return;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can chat with ${profile.name} after a real match is created.',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          matchId: selected!.id,
          otherUserId: selected.userId,
          userName: selected.userName,
          userPhotoUrl: selected.userPhoto,
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
                  _DiscoverHeader(
                    onOpenFilters: widget.onOpenFilters,
                    onOpenMessages: widget.onOpenMessages,
                    activeFilterChips: widget.activeFilterChips,
                    passedCount: swipeState.passedProfiles.length,
                    unreadNotifications: unreadNotifications,
                  ),
                  if (!isSpotlightMode && spotlightProfiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _SpotlightRail(
                        profiles: spotlightProfiles,
                        onOpenProfile: (p) async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProfileDetailsScreen(profile: p),
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
                    child: _buildCardArea(
                      context,
                      swipeState: swipeState,
                      swipeNotifier: swipeNotifier,
                      isSpotlightMode: isSpotlightMode,
                    ),
                  ),
                ],
              ),
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

  Widget _buildCardArea(
    BuildContext context, {
    required SwipeState swipeState,
    required SwipeNotifier swipeNotifier,
    required bool isSpotlightMode,
  }) {
    if (swipeState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.trustBlue),
        ),
      );
    }
    if (swipeState.error != null && swipeState.profiles.isEmpty) {
      return _DiscoveryErrorState(
        error: swipeState.error!,
        onRetry: () => swipeNotifier.refreshProfiles(),
      );
    }
    if (swipeState.profiles.isEmpty) {
      return _EmptyState(
        isSpotlightMode: isSpotlightMode,
        trustFilterActive: swipeState.trustFilterActive,
        filteredOutCount: swipeState.trustFilteredOutCount,
        onRefresh: () => swipeNotifier.refreshProfiles(),
      );
    }
    if (swipeState.currentIndex >= swipeState.profiles.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.trustBlue, size: 64),
            const SizedBox(height: 16),
            Text(
              isSpotlightMode ? 'Spotlight reviewed!' : 'All reviewed!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textDark),
            ),
          ],
        ),
      );
    }
    final currentProfile = swipeState.profiles[swipeState.currentIndex];
    return _SwipeArea(
      profile: currentProfile,
      swipeState: swipeState,
      swipeNotifier: swipeNotifier,
      isActionBusy: _isActionBusy,
      onPass: () => _runLocked(swipeNotifier.passProfile),
      onLike: () => _runLocked(
        () => _handleLike(
          notifier: swipeNotifier,
          profile: currentProfile,
          isSuperLike: false,
        ),
      ),
      onSuperLike: () => _runLocked(
        () => _handleLike(
          notifier: swipeNotifier,
          profile: currentProfile,
          isSuperLike: true,
          showSnack: true,
        ),
      ),
      onMessage: () => _runLocked(
        () =>
            _openConversation(profile: currentProfile, notifier: swipeNotifier),
      ),
      onUndo: swipeNotifier.undoSwipe,
      onOpenProfile: () async {
        swipeNotifier.recordProfileView(currentProfile.id);
        final action = await Navigator.of(context).push<ProfileDetailsAction>(
          MaterialPageRoute<ProfileDetailsAction>(
            builder: (_) => ProfileDetailsScreen(profile: currentProfile),
          ),
        );
        if (!context.mounted) return;
        if (action == ProfileDetailsAction.love) {
          await _runLocked(
            () => _handleLike(
              notifier: swipeNotifier,
              profile: currentProfile,
              isSuperLike: true,
              showSnack: true,
            ),
          );
        } else if (action == ProfileDetailsAction.message) {
          await _runLocked(
            () => _openConversation(
              profile: currentProfile,
              notifier: swipeNotifier,
            ),
          );
        }
      },
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.onOpenFilters,
    required this.onOpenMessages,
    required this.activeFilterChips,
    required this.passedCount,
    required this.unreadNotifications,
  });
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;
  final List<String> activeFilterChips;
  final int passedCount;
  final List<DiscoveryNotificationItem> unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.14)),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Matches',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find meaningful verified matches',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                      if (activeFilterChips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: activeFilterChips
                              .map((c) => _FilterChip(label: c))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _NotificationBell(
                  count: unreadNotifications.length,
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _NotificationsSheet(
                        notifications: unreadNotifications,
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
                  child: _ActionChip(
                    icon: Icons.history,
                    label: 'Passed ($passedCount)',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PassedProfilesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    onTap: onOpenMessages,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.tune_rounded,
                    label: 'Filters',
                    onTap: onOpenFilters,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeArea extends StatelessWidget {
  const _SwipeArea({
    required this.profile,
    required this.swipeState,
    required this.swipeNotifier,
    required this.isActionBusy,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
    required this.onUndo,
    required this.onOpenProfile,
  });
  final DiscoveryProfile profile;
  final SwipeState swipeState;
  final SwipeNotifier swipeNotifier;
  final bool isActionBusy;
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final Future<void> Function() onSuperLike;
  final Future<void> Function() onMessage;
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
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: SwipeCard(
                      profile: profile,
                      isActionLocked: isActionBusy,
                      onPassTap: () async => onPass(),
                      onLikeTap: () async => onLike(),
                      onMessageTap: () async => onMessage(),
                      onTap: onOpenProfile,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SwipeButtons(
                  onPass: onPass,
                  onLike: onLike,
                  onSuperLike: onSuperLike,
                  onMessage: onMessage,
                  onUndo: onUndo,
                  canUndo: swipeState.currentIndex > 0,
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

class _DiscoveryErrorState extends StatelessWidget {
  const _DiscoveryErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.textHint.withValues(alpha: 0.7),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profiles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              width: 180,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pureGoldCore,
                  foregroundColor: AppTheme.pureGoldInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSpotlightMode,
    required this.trustFilterActive,
    required this.filteredOutCount,
    required this.onRefresh,
  });
  final bool isSpotlightMode;
  final bool trustFilterActive;
  final int filteredOutCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            color: AppTheme.textHint,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSpotlightMode ? 'No spotlight profiles' : 'No profiles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textDark),
          ),
          if (trustFilterActive && filteredOutCount > 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Trust filters hid $filteredOutCount profile(s). '
                'Try relaxing trust filters.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Material(
            color: AppTheme.pureGoldCore,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: AppTheme.pureGoldInk, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: AppTheme.pureGoldInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                    horizontal: 3,
                    vertical: 1,
                  ),
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
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.notifications});
  final List<DiscoveryNotificationItem> notifications;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              (n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
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
                      n.type == DiscoveryNotificationType.whoRepliedMe
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
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            n.subtitle,
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
}

class _SpotlightRail extends StatelessWidget {
  const _SpotlightRail({
    required this.profiles,
    required this.onOpenProfile,
    required this.onViewMore,
  });
  final List<DiscoveryProfile> profiles;
  final Future<void> Function(DiscoveryProfile) onOpenProfile;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    final items = profiles.take(6).toList(growable: false);
    final sw = MediaQuery.sizeOf(context).width;
    final cardW = sw < 390
        ? 104.0
        : sw < 600
        ? 120.0
        : 132.0;
    final railH = sw < 390
        ? 124.0
        : sw < 600
        ? 134.0
        : 144.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.trustBlue.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.trustBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
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
              TextButton(
                onPressed: onViewMore,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'View more',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: railH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final p = items[index];
                return GestureDetector(
                  onTap: () => onOpenProfile(p),
                  child: SizedBox(
                    width: cardW,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (p.photoUrls.isNotEmpty)
                            Image.network(
                              p.photoUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            )
                          else
                            Container(
                              color: Colors.white,
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.textHint,
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
                                    p.name,
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
                                if (p.isVerified)
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
                        ? AppTheme.crystalRose.withValues(alpha: 0.96)
                        : AppTheme.crystalRose.withValues(alpha: 0.84),
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
