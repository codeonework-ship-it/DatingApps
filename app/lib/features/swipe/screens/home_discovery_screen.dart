import '../../intentional_dating/today_introductions.dart';
import '../../intentional_dating/dating_rhythm.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../engagement/providers/daily_prompt_provider.dart';
import '../../matching/providers/match_provider.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../../messaging/screens/chat_screen.dart';
import '../models/discovery_profile.dart';
import '../models/discovery_notification_item.dart';
import '../../payment/providers/entitlements_provider.dart';
import '../../payment/screens/subscription_screen.dart';
import '../providers/curated_daily_set_provider.dart';
import '../providers/liked_me_provider.dart';
import '../providers/swipe_provider.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/swipe_card.dart';
import 'liked_me_screen.dart';
import 'passed_profiles_screen.dart';
import 'profile_details_screen.dart';
import 'spotlight_profiles_screen.dart';

/// Main discovery / swipe screen.
class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  const HomeDiscoveryScreen({
    super.key,
    this.onOpenFilters,
    this.onOpenMessages,
    this.onBrowse,
    this.activeFilterChips = const <String>[],
    this.browseOnly = false,
    this.isActive = true,
  });
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;

  /// Route browsing to the Matches destination when hosted by main navigation.
  final VoidCallback? onBrowse;
  final List<String> activeFilterChips;

  /// Open the complete discovery deck directly instead of the Today preview.
  /// This is a navigation choice, independent of the member's paid plan.
  final bool browseOnly;

  /// An offstage Today screen must not open a second quota dialog when the
  /// same discovery provider is used from Matches.
  final bool isActive;

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
  int _cardFlipToken = 0;
  bool _browsing = false;

  @override
  void initState() {
    super.initState();
    _likeBurstController =
        AnimationController(
          duration: const Duration(milliseconds: 650),
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
    if (AppTheme.reduceMotionOf(context)) {
      return;
    }
    if (mounted) {
      setState(() {
        _showLikeBurst = true;
        _isSuperLikeBurst = isSuperLike;
        // Spin the card through a full turn on the same beat as the hearts.
        // Keep the profile readable while acknowledging the action.
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
    final result = ref.read(swipeNotifierProvider);
    if (result.error != null || result.dailyLimit != null) {
      if (result.error != null)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    ref.invalidate(curatedDailySetProvider);
    if (matchId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => MatchNotificationScreen(
            matchId: matchId,
            otherUserId: profile.id,
            otherUserName: profile.name,
            otherUserPhotoUrl: profile.photoUrls.isEmpty
                ? ''
                : profile.photoUrls.first,
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
      final result = ref.read(swipeNotifierProvider);
      if (result.error != null || result.dailyLimit != null) {
        if (result.error != null)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.error!)));
        return;
      }
      ref.invalidate(curatedDailySetProvider);
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

  Future<void> _showDailyLimitSheet(
    BuildContext context,
    Map<String, dynamic> refusal,
  ) async {
    final limit = DailyLimit.fromRefusal(refusal);
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.favorite_rounded, size: 40, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              limit?.headline ?? "You've used today's likes",
              textAlign: TextAlign.center,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              limit == null
                  ? 'Come back tomorrow, or upgrade for more likes every day.'
                  : '${limit.resetLabel}. Upgrade for more likes every day.',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              child: const Text('See plans'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
    ref.read(swipeNotifierProvider.notifier).clearDailyLimit();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, dynamic>?>(
      swipeNotifierProvider.select((s) => s.dailyLimit),
      (previous, next) {
        if (widget.isActive && next != null && previous == null) {
          _showDailyLimitSheet(context, next);
        }
      },
    );
    final swipeState = ref.watch(swipeNotifierProvider);
    final swipeNotifier = ref.read(swipeNotifierProvider.notifier);
    // Today's curated picks: gated by the runtime flag, hidden when the
    // server has nothing for today or the request failed.
    final runtimeFlags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final curatedEnabled = runtimeFlags.enabled(
      'curated_daily_set_enabled',
      fallback: true,
    );
    final todayProfiles = curatedEnabled
        ? ref.watch(curatedDailySetProvider).profiles
        : const <DiscoveryProfile>[];
    if (!widget.browseOnly &&
        curatedEnabled &&
        runtimeFlags.enabled('intentional_dating_enabled', fallback: false) &&
        !_browsing) {
      return TodayIntroductions(
        onOpenProfile: _openTodayProfile,
        onOpenFilters: widget.onOpenFilters,
        onBrowse: widget.onBrowse ?? () => setState(() => _browsing = true),
        activeFilterChips: widget.activeFilterChips,
      );
    }
    final dailyPromptState = ref.watch(dailyPromptProvider);
    // Pending likes only: members who liked me and are waiting on an answer.
    final likedMeCount = ref.watch(likedMeProvider.select((s) => s.count));
    final unreadNotifications = buildDiscoveryNotificationStack(
      repliedCount: dailyPromptState.responders.length,
      likedMeCount: likedMeCount,
    );
    final isSpotlightMode =
        swipeState.discoveryMode == SwipeNotifier.discoveryModeSpotlight;

    return LayoutBuilder(
      builder: (context, viewport) {
        // Browser windows get a two-column desk instead of the phone stack.
        final desktop = kIsWeb && viewport.maxWidth >= _desktopBreakpoint;
        return Scaffold(
          appBar: _browsing && !widget.browseOnly
              ? AppBar(
                  leading: IconButton(
                    tooltip: 'Back to Today',
                    onPressed: () => setState(() => _browsing = false),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  title: const Text('Explore'),
                )
              : null,
          body: PostLoginBackdrop(
            maxContentWidth: desktop ? null : AppTheme.contentMaxWidth,
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (desktop)
                    _buildDesktop(
                      context,
                      swipeState: swipeState,
                      swipeNotifier: swipeNotifier,
                      unreadNotifications: unreadNotifications,
                      isSpotlightMode: isSpotlightMode,
                      todayProfiles: todayProfiles,
                    )
                  else
                    _buildMobile(
                      context,
                      swipeState: swipeState,
                      swipeNotifier: swipeNotifier,
                      unreadNotifications: unreadNotifications,
                      isSpotlightMode: isSpotlightMode,
                      todayProfiles: todayProfiles,
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
      },
    );
  }

  Future<void> _openSpotlightProfile(DiscoveryProfile p) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProfileDetailsScreen(profile: p)),
    );
  }

  /// A curated pick opens the same profile detail the deck uses. When the
  /// member is still in the deck the deck jumps to their card, so a love or
  /// message chosen on the detail screen acts on that member and not on
  /// whoever happened to be on top.
  Future<void> _openTodayProfile(DiscoveryProfile p) async {
    final notifier = ref.read(swipeNotifierProvider.notifier);
    notifier.selectIntroduction(p);
    unawaited(notifier.recordProfileView(p.id));
    final action = await Navigator.of(context).push<ProfileDetailsAction>(
      MaterialPageRoute<ProfileDetailsAction>(
        builder: (_) => ProfileDetailsScreen(profile: p),
      ),
    );
    if (!mounted || !notifier.selectProfile(p.id)) {
      return;
    }
    if (action == ProfileDetailsAction.love) {
      await _runLocked(
        () => _handleLike(
          notifier: notifier,
          profile: p,
          isSuperLike: true,
          showSnack: true,
        ),
      );
    } else if (action == ProfileDetailsAction.message) {
      await _runLocked(() => _openConversation(profile: p, notifier: notifier));
    }
  }

  void _openSpotlightList(List<DiscoveryProfile> profiles) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpotlightProfilesScreen(profiles: profiles),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required SwipeState swipeState,
    required SwipeNotifier swipeNotifier,
    required List<DiscoveryNotificationItem> unreadNotifications,
    required bool isSpotlightMode,
    required List<DiscoveryProfile> todayProfiles,
  }) {
    final spotlightProfiles = swipeState.spotlightProfiles;
    final wideAside = MediaQuery.sizeOf(context).width >= 1280;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DesktopDiscoverHeader(
                isSpotlightMode: isSpotlightMode,
                onOpenFilters: widget.onOpenFilters,
                onOpenMessages: widget.onOpenMessages,
                unreadNotifications: unreadNotifications,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildCardArea(
                        context,
                        swipeState: swipeState,
                        swipeNotifier: swipeNotifier,
                        isSpotlightMode: isSpotlightMode,
                        cardMaxWidth: 480,
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: wideAside ? 320 : 280,
                      child: _DesktopDiscoverAside(
                        visibleProfiles: swipeState.profiles.length,
                        likeCount: swipeState.likeCount,
                        passCount: swipeState.passCount,
                        activeFilterChips: widget.activeFilterChips,
                        onOpenFilters: widget.onOpenFilters,
                        spotlightProfiles: isSpotlightMode
                            ? const <DiscoveryProfile>[]
                            : spotlightProfiles,
                        onOpenSpotlightProfile: _openSpotlightProfile,
                        onViewSpotlight: () =>
                            _openSpotlightList(spotlightProfiles),
                        todayProfiles: isSpotlightMode
                            ? const <DiscoveryProfile>[]
                            : todayProfiles,
                        onOpenTodayProfile: _openTodayProfile,
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
  }

  Widget _buildMobile(
    BuildContext context, {
    required SwipeState swipeState,
    required SwipeNotifier swipeNotifier,
    required List<DiscoveryNotificationItem> unreadNotifications,
    required bool isSpotlightMode,
    required List<DiscoveryProfile> todayProfiles,
  }) {
    final spotlightProfiles = swipeState.spotlightProfiles;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _DiscoverHeader(
                onOpenFilters: widget.onOpenFilters,
                onOpenMessages: widget.onOpenMessages,
                activeFilterChips: widget.activeFilterChips,
                passedCount: swipeState.passedProfiles.length,
                unreadNotifications: unreadNotifications,
                visibleProfiles: swipeState.profiles.length,
                likeCount: swipeState.likeCount,
                passCount: swipeState.passCount,
              ),
            ),
            if (!isSpotlightMode && todayProfiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _TodayRail(
                  profiles: todayProfiles,
                  onOpenProfile: _openTodayProfile,
                ),
              ),
            if (!isSpotlightMode && spotlightProfiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _SpotlightRail(
                  profiles: spotlightProfiles,
                  onOpenProfile: _openSpotlightProfile,
                  onViewMore: () => _openSpotlightList(spotlightProfiles),
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
        );
        if (constraints.maxHeight < 650) {
          return SingleChildScrollView(
            child: SizedBox(height: 900, child: content),
          );
        }
        return content;
      },
    );
  }

  Widget _buildCardArea(
    BuildContext context, {
    required SwipeState swipeState,
    required SwipeNotifier swipeNotifier,
    required bool isSpotlightMode,
    double cardMaxWidth = 680,
  }) {
    if (swipeState.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
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
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isSpotlightMode ? 'Spotlight reviewed!' : 'All reviewed!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
      cardMaxWidth: cardMaxWidth,
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
      cardFlipToken: _cardFlipToken,
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

/// Content width at which the browser app switches to the desktop layout.
const double _desktopBreakpoint = 800;

/// Small uppercase label with a raspberry dot, matching the website's eyebrow.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

/// White card with a hairline rule, the website's `.card`.
class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({required this.child, this.tinted = false});
  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tinted ? scheme.surfaceContainerHighest : scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: tinted ? null : Border.all(color: scheme.outline),
      ),
      child: child,
    );
  }
}

class _DesktopDiscoverHeader extends StatelessWidget {
  const _DesktopDiscoverHeader({
    required this.isSpotlightMode,
    required this.onOpenFilters,
    required this.onOpenMessages,
    required this.unreadNotifications,
  });
  final bool isSpotlightMode;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;
  final List<DiscoveryNotificationItem> unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = unreadNotifications.length;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(isSpotlightMode ? 'Spotlight' : 'Curated for you'),
              const SizedBox(height: 12),
              Text(
                'Discover Matches',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: scheme.onSurface,
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A little curiosity. A real connection.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: 'qa.discovery.messages_button',
          button: true,
          child: OutlinedButton.icon(
            onPressed: onOpenMessages,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Messages'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              backgroundColor: scheme.surface,
              side: BorderSide(color: scheme.outlineVariant),
              padding: buttonPadding,
              minimumSize: const Size(0, 52),
              shape: buttonShape,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: 'qa.discovery.filter_button',
          button: true,
          child: FilledButton.icon(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Filters'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.onSurface,
              foregroundColor: scheme.surface,
              padding: buttonPadding,
              minimumSize: const Size(0, 52),
              shape: buttonShape,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Notifications',
          child: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 9 ? '9+' : '$count'),
            backgroundColor: scheme.primary,
            child: IconButton.outlined(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _NotificationsSheet(
                      notifications: unreadNotifications,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: scheme.onSurface,
                backgroundColor: scheme.surface,
                side: BorderSide(color: scheme.outlineVariant),
                fixedSize: const Size(52, 52),
                shape: buttonShape,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopDiscoverAside extends StatelessWidget {
  const _DesktopDiscoverAside({
    required this.visibleProfiles,
    required this.likeCount,
    required this.passCount,
    required this.activeFilterChips,
    required this.onOpenFilters,
    required this.spotlightProfiles,
    required this.onOpenSpotlightProfile,
    required this.onViewSpotlight,
    required this.todayProfiles,
    required this.onOpenTodayProfile,
  });
  final int visibleProfiles;
  final int likeCount;
  final int passCount;
  final List<String> activeFilterChips;
  final VoidCallback? onOpenFilters;
  final List<DiscoveryProfile> spotlightProfiles;
  final Future<void> Function(DiscoveryProfile) onOpenSpotlightProfile;
  final VoidCallback onViewSpotlight;
  final List<DiscoveryProfile> todayProfiles;
  final Future<void> Function(DiscoveryProfile) onOpenTodayProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heading = theme.textTheme.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your deck', style: heading),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DeckStat(value: visibleProfiles, label: 'Ready'),
                    ),
                    Expanded(
                      child: _DeckStat(value: likeCount, label: 'Liked'),
                    ),
                    Expanded(
                      child: _DeckStat(
                        value: passCount,
                        label: 'Passed',
                        semanticLabel: 'qa.discovery.passed_button',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PassedProfilesScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: scheme.outline),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('Filters', style: heading)),
                    TextButton(
                      onPressed: onOpenFilters,
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (activeFilterChips.isEmpty)
                  Text('Showing everyone in your preferences.', style: muted)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final chip in activeFilterChips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            chip,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (todayProfiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DesktopPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow('Curated for you'),
                  const SizedBox(height: 8),
                  Text('Today', style: heading),
                  const SizedBox(height: 4),
                  Text('Five picks, refreshed every day.', style: muted),
                  const SizedBox(height: 12),
                  _TodayRail(
                    profiles: todayProfiles,
                    onOpenProfile: onOpenTodayProfile,
                    showHeader: false,
                  ),
                ],
              ),
            ),
          ],
          if (spotlightProfiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DesktopPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Spotlight', style: heading)),
                      TextButton(
                        onPressed: onViewSpotlight,
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final p in spotlightProfiles.take(4))
                    _SpotlightRow(
                      profile: p,
                      onTap: () => onOpenSpotlightProfile(p),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DesktopPanel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: scheme.primary, size: 22),
                const SizedBox(height: 12),
                Text('Match on your terms', style: heading),
                const SizedBox(height: 8),
                Text(
                  'Mutual interest creates a match. You can block or report '
                  'anyone from their profile or conversation.',
                  style: muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckStat extends StatelessWidget {
  const _DeckStat({
    required this.value,
    required this.label,
    this.onTap,
    this.semanticLabel,
  });
  final int value;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.onSurface,
              fontSize: 32,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: body,
      ),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({required this.profile, required this.onTap});
  final DiscoveryProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo = profile.photoUrls.isEmpty ? null : profile.photoUrls.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundImage: photo == null ? null : NetworkImage(photo),
              child: Icon(Icons.person, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (profile.isVerified)
              Icon(Icons.verified_rounded, size: 16, color: scheme.secondary),
            const SizedBox(width: 4),
            Icon(
              Icons.north_east_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
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
    required this.visibleProfiles,
    required this.likeCount,
    required this.passCount,
  });
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenMessages;
  final List<String> activeFilterChips;
  final int passedCount;
  final List<DiscoveryNotificationItem> unreadNotifications;
  final int visibleProfiles;
  final int likeCount;
  final int passCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, compact ? 4 : 8, 4, 4),
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
                      'CURATED FOR YOU',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover Matches',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: AppTheme.displayFamily,
                        color: colors.onSurface,
                        fontSize: compact ? 28 : 32,
                        height: 1.12,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A little curiosity. A real connection.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
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
                    builder: (_) =>
                        _NotificationsSheet(notifications: unreadNotifications),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Ready',
                  value: '$visibleProfiles',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  label: 'Liked',
                  value: '$likeCount',
                  icon: Icons.favorite_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  label: 'Passed',
                  value: '$passCount',
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
          if (activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: activeFilterChips
                  .map((c) => _FilterChip(label: c))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.history,
                  label: 'Passed',
                  semanticLabel: 'qa.discovery.passed_button',
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
                  semanticLabel: 'qa.discovery.messages_button',
                  onTap: onOpenMessages,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.tune_rounded,
                  label: 'Filters',
                  semanticLabel: 'qa.discovery.filter_button',
                  onTap: onOpenFilters,
                ),
              ),
            ],
          ),
        ],
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
    required this.cardFlipToken,
    this.cardMaxWidth = 680,
  });
  final DiscoveryProfile profile;
  final double cardMaxWidth;
  final SwipeState swipeState;
  final SwipeNotifier swipeNotifier;
  final bool isActionBusy;
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final Future<void> Function() onSuperLike;
  final Future<void> Function() onMessage;
  final VoidCallback onUndo;
  final VoidCallback onOpenProfile;

  /// Bumped by the parent on every like so the card spins in step with the
  /// hearts.
  final int cardFlipToken;

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
        final deck = Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: SwipeCard(
                      profile: profile,
                      flipToken: cardFlipToken,
                      maxHeight: math.max(280, constraints.maxHeight - 112),
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
                constraints: BoxConstraints(maxWidth: cardMaxWidth + 40),
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
        if (constraints.maxHeight < 360) {
          return SingleChildScrollView(
            child: SizedBox(height: 480, child: deck),
          );
        }
        return deck;
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
    return _ResponsiveStateCenter(
      child: _PremiumStateCard(
        semanticLabel: 'qa.discovery.retry_state',
        icon: Icons.cloud_off_rounded,
        eyebrow: 'Connection paused',
        title: 'Unable to load profiles',
        message: error,
        actionLabel: 'Try Again',
        onAction: onRetry,
      ),
    );
  }
}

class _ResponsiveStateCenter extends StatelessWidget {
  const _ResponsiveStateCenter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _PremiumStateCard extends StatelessWidget {
  const _PremiumStateCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.semanticLabel,
    this.footer,
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? semanticLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(28),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  eyebrow.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 14), footer!],
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: Semantics(
                    label: 'qa.discovery.state_action_button',
                    button: true,
                    child: ElevatedButton.icon(
                      key: const ValueKey('qa.discovery.state_action_button'),
                      onPressed: onAction,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(actionLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final trustMessage = trustFilterActive && filteredOutCount > 0
        ? 'Trust filters hid $filteredOutCount profile(s). Try relaxing '
              'trust filters or refresh to rebuild your deck.'
        : 'Your curated deck is being prepared. Refresh to check for new '
              'verified profiles near you.';
    return _ResponsiveStateCenter(
      child: _PremiumStateCard(
        semanticLabel: 'qa.discovery.empty_state',
        icon: Icons.diamond_outlined,
        eyebrow: isSpotlightMode ? 'Spotlight' : 'Check back soon',
        title: isSpotlightMode ? 'No spotlight profiles' : 'No profiles',
        message: trustMessage,
        actionLabel: 'Refresh',
        onAction: onRefresh,
        footer: const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyPromiseChip(icon: Icons.verified_rounded, label: 'Verified'),
            _TinyPromiseChip(icon: Icons.lock_rounded, label: 'Private'),
            _TinyPromiseChip(icon: Icons.auto_awesome, label: 'Premium'),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPromiseChip extends StatelessWidget {
  const _TinyPromiseChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
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
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    this.semanticLabel,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = label == 'Filters';
    final foreground = primary ? colors.onPrimary : colors.onSurface;
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      child: Material(
        key: semanticLabel == null ? null : ValueKey<String>(semanticLabel!),
        color: primary ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    // A full 48pt tap target (androidTapTargetGuideline).
    return Semantics(
      container: true,
      button: true,
      label: count > 0 ? 'Notifications, $count unread' : 'Notifications',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest unread notifications',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (notifications.isEmpty)
            Text(
              'No unread notifications',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...notifications.map((n) {
              // Who liked me opens the list of pending likes; the sheet
              // closes first so back returns to Discover.
              final opensLikes = n.type == DiscoveryNotificationType.whoLikedMe;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  key: opensLikes
                      ? const ValueKey('qa.discovery.notification.who_liked_me')
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  onTap: opensLikes
                      ? () {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LikedMeScreen(),
                            ),
                          );
                        }
                      : null,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          n.type == DiscoveryNotificationType.whoRepliedMe
                              ? Icons.visibility_outlined
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                n.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (opensLikes)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Spotlight',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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

/// Today's curated picks: a horizontal rail of up to five compact cards
/// (photo, name, up to two reason chips). Tapping a card opens the same
/// profile detail the deck uses. The rail sizes to its cards, so a larger
/// text scale grows it instead of clipping it.
class _TodayRail extends ConsumerWidget {
  const _TodayRail({
    required this.profiles,
    required this.onOpenProfile,
    this.showHeader = true,
  });
  final List<DiscoveryProfile> profiles;
  final Future<void> Function(DiscoveryProfile) onOpenProfile;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = profiles.take(5).toList(growable: false);
    final cardWidth = MediaQuery.sizeOf(context).width < 390 ? 132.0 : 148.0;
    return Column(
      key: const ValueKey('qa.discover.today.rail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ref
                .watch(runtimeFeatureFlagsProvider)
                .valueOrNull
                ?.enabled('intentional_dating_enabled', fallback: false) ==
            true)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => openDatingRhythm(context),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Fits your week'),
            ),
          ),
        if (showHeader) ...[
          Row(
            children: [
              Icon(Icons.today_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                items.length == 1 ? '1 pick' : '${items.length} picks',
                key: const ValueKey('qa.discover.today.count'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _TodayCard(
                  index: i,
                  profile: items[i],
                  width: cardWidth,
                  onTap: () => onOpenProfile(items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.index,
    required this.profile,
    required this.width,
    required this.onTap,
  });
  final int index;
  final DiscoveryProfile profile;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reasons = profile.reasons.take(2).toList(growable: false);
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.person_outline_rounded, color: scheme.onSurfaceVariant),
    );
    return Semantics(
      button: true,
      label:
          '${profile.displayName}. ${profile.why ?? 'Picked for you today.'}',
      child: GlassContainer(
        key: ValueKey('qa.discover.today.card.$index'),
        width: width,
        padding: const EdgeInsets.all(8),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 88,
                width: double.infinity,
                child: profile.photoUrls.isEmpty
                    ? fallback
                    : Image.network(
                        profile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (profile.isVerified)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.verified,
                      color: scheme.primary,
                      size: 14,
                    ),
                  ),
              ],
            ),
            for (var j = 0; j < reasons.length; j++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _ReasonChip(
                  key: ValueKey('qa.discover.today.reason.$index.$j'),
                  label: reasons[j],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One explainability chip from the curated set catalogue.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LikeBurst extends StatelessWidget {
  const _LikeBurst({required this.progress, required this.isSuperLike});
  final double progress;
  final bool isSuperLike;

  /// Hearts rise from the action bar to the top of the screen, then hold and
  /// drift there before fading.
  ///
  /// The previous burst lifted three hearts about 150px off the button row and
  /// faded them immediately, so the gesture read as a small local pop rather
  /// than something that filled the screen. The travel is now measured against
  /// the real viewport height and split into a rise and a float, so the hearts
  /// actually reach the top and linger.
  static const int _heartCount = 9;
  static const double _riseFraction = 0.62;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        final travel = constraints.maxHeight - topInset - 96;

        return Stack(
          children: List.generate(_heartCount, (i) {
            // Deterministic per-heart variation: a seeded spread reads as
            // natural without pulling in a random source that would make the
            // effect impossible to reproduce in a golden test.
            final phase = (i * 0.113) % 1.0;
            final delay = phase * 0.34;
            final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
            if (t <= 0) {
              return const SizedBox.shrink();
            }

            final rising = (t / _riseFraction).clamp(0.0, 1.0);
            final floating = ((t - _riseFraction) / (1 - _riseFraction)).clamp(
              0.0,
              1.0,
            );
            final lift = Curves.easeOutCubic.transform(rising) * travel;

            // Sway widens as the heart climbs, then keeps drifting gently once
            // it is floating at the top.
            final spread = (i - (_heartCount - 1) / 2) * 26.0;
            final sway =
                spread * Curves.easeOutCubic.transform(rising) +
                math.sin((t * 3.1 + phase * math.pi * 2)) *
                    (10 + 14 * floating);

            final bob =
                math.sin(floating * math.pi * 2 + phase * 6) * 9 * floating;
            final scale =
                (isSuperLike ? 1.05 : 0.86) +
                (1 - rising) * 0.28 -
                floating * 0.16;
            final opacity =
                (floating <= 0
                        ? 0.28 + rising * 0.7
                        : (1 - floating * floating))
                    .clamp(0.0, 1.0);
            final size = (isSuperLike ? 46.0 : 38.0) + (i % 3) * 7.0;

            return Positioned(
              left: cx + sway - size / 2,
              bottom: 118 + lift + bob,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: math.sin(phase * math.pi * 2) * 0.34,
                    child: Icon(
                      isSuperLike ? Icons.star_rounded : Icons.favorite_rounded,
                      color:
                          (i.isEven
                                  ? AppTheme.crystalRose
                                  : AppTheme.irisBright)
                              .withValues(alpha: 0.94),
                      size: size,
                      shadows: [
                        BoxShadow(
                          color: AppTheme.crystalRose.withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ],
                    ),
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
