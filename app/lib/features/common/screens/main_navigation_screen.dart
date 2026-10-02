import '../../social_chat/social_chat_data.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/preference_limits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/network_quality_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/couture.dart';
import '../../../core/theme/cinematic_motion.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/screens/settings_screen.dart';
import '../../celebrations/reward_burst_host.dart';
import '../../celebrations/rose_rain.dart';
import '../../engagement/screens/engagement_hub_screen.dart';
import '../../engagement/screens/match_nudges_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../matching/providers/match_provider.dart';
import '../../matching/providers/trust_filter_provider.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_inbox_screen.dart';
import '../../plans/screens/plans_screen.dart';
import '../../profile/providers/preference_master_data_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../profile/providers/profile_setup_provider.dart';
import '../../profile/screens/setup/setup_preferences_screen.dart';
import '../../swipe/providers/swipe_provider.dart';
import '../../swipe/screens/home_discovery_screen.dart';
import '../../swipe/screens/liked_me_screen.dart';
import '../../support/support_routes.dart';
import '../../verification/screens/verification_upload_id_screen.dart';

final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  bool _filtersSeededFromProfile = false;
  RangeValues _filterAge = const RangeValues(20, 50);
  double _filterDistance = 50;
  bool _filterVerifiedOnly = false;
  String? _filterReligion;
  String? _filterMotherTongue;
  String? _filterCountry;
  String? _filterState;
  String? _filterCity;
  String? _filterRelationshipStatus;
  String? _filterSmoking;
  String? _filterDrinking;
  String? _filterPersonalityType;
  bool _filterPartyLoverOnly = false;
  bool _filterHookupOnly = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabController.forward();
  }

  // The open in-app notification banner, if any. It belongs to this member's
  // session, so it must not outlive the shell (sign-out, account switch).
  ScaffoldMessengerState? _messenger;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _fabController.dispose();
    // Banners with an action never time out while an accessibility service
    // is on, so the previous member's notification stayed over the welcome
    // and sign-in screens (covering "Sign in"). Close it once the tree is
    // unlocked; a banner something else already closed is left alone.
    final messenger = _messenger;
    final banner = _banner;
    if (messenger != null && banner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messenger.mounted && identical(_banner, banner)) {
          banner.close();
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        (ref
              ..listen<AppNotification?>(
                notificationProvider.select((state) => state.foregroundEvent),
                (previous, next) {
                  if (next != null && next.id != previous?.id) {
                    _showForegroundNotification(next);
                  }
                },
              )
              ..listen<PushNotificationAction?>(
                notificationProvider.select((state) => state.pushAction),
                (previous, next) {
                  if (next != null && !identical(previous, next)) {
                    _openPushAction(next);
                  }
                },
              ))
            .watch(notificationProvider);
    final isOffline = ref.watch(preferenceMasterDataOfflineProvider);
    final networkState = ref.watch(networkQualityProvider);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);
    final l10n = AppLocalizations.of(context);
    const qaAutomationShortcuts = kEnableQaAutomation;

    final screens = <Widget>[
      HomeDiscoveryScreen(
        isActive: selectedIndex == 0,
        onBrowse: () => _setSelectedIndex(1),
        onOpenFilters: () => _openFilterSheet(context),
        onOpenMessages: () {
          _setSelectedIndex(1);
          ref.read(matchesViewProvider.notifier).state =
              MatchesView.conversations;
        },
        activeFilterChips: _discoverActiveFilterChips,
      ),
      MatchesListScreen(
        isActive: selectedIndex == 1,
        onOpenFilters: () => _openFilterSheet(context),
        activeFilterChips: _discoverActiveFilterChips,
      ),
      const EngagementHubScreen(),
      const ProfileViewScreen(),
      const SettingsScreen(),
    ];

    // Android back on Matches, Engage, Profile or Settings returns to
    // Today instead of closing the app; back on Today leaves as usual.
    // Screens pushed on top (a chapter, a sub-page) still pop first.
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setSelectedIndex(0);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                if (isOffline)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: const SafeArea(
                      bottom: false,
                      child: Text(
                        'Offline mode: Some data may be outdated.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (networkState.status != NetworkQualityStatus.healthy)
                  Builder(
                    builder: (context) {
                      // Offline is a hard failure and stays loud. A weak
                      // connection is advisory, so it gets a tinted strip with
                      // dark ink instead of a full-bleed alert — it still reads
                      // at a glance without shouting over the whole app.
                      final isOfflineBanner =
                          networkState.status == NetworkQualityStatus.offline;
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isOfflineBanner
                              ? Theme.of(context).colorScheme.error
                              : AppTheme.marigoldTint,
                          border: isOfflineBanner
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: AppTheme.marigold),
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOfflineBanner
                                    ? Icons.cloud_off_rounded
                                    : Icons.network_check_rounded,
                                size: 15,
                                color: isOfflineBanner
                                    ? Colors.white
                                    : AppTheme.warning,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  networkState.message ??
                                      'Weak network detected. Use at least '
                                          '5 Mbps for smoother app performance.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isOfflineBanner
                                            ? Colors.white
                                            : AppTheme.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Expanded(
                  // An IndexedStack with a cinematic cut between tabs;
                  // hidden tabs pause their tickers and heroes.
                  child: CinematicTabStack(
                    index: selectedIndex,
                    children: screens
                        .map((screen) => SizedBox.expand(child: screen))
                        .toList(),
                  ),
                ),
              ],
            ),
            // Plays the rose rain when a chapter or photo reaches a new wall tier.
            const RoseRainHost(),
            // Bursts snow, roses, bats or confetti (by look) for every new
            // reward, level-up and badge.
            const RewardBurstHost(),
            if (qaAutomationShortcuts)
              _buildQaAutomationSurface(
                selectedIndex,
                topInset:
                    (isOffline ? 44.0 : 0.0) +
                    (networkState.status != NetworkQualityStatus.healthy
                        ? 70.0
                        : 0.0),
              ),
          ],
        ),
        bottomNavigationBar: kIsWeb && MediaQuery.sizeOf(context).width >= 900
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.contentMaxWidth,
                    ),
                    child: GlassContainer(
                      blur: 18,
                      opacity: 0.76,
                      padding: EdgeInsets.zero,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.94),
                      // A look brings its own bevelled hairline (Couture);
                      // the bare theme keeps the plain one.
                      border: Couture.presetOf(context) != null
                          ? null
                          : Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.22)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                            ),
                      shadows: Theme.of(context).brightness == Brightness.dark
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.shadow.withValues(alpha: 0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : AppTheme.shadow2,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: BottomNavigationBar(
                          currentIndex: selectedIndex,
                          onTap: _setSelectedIndex,
                          type: BottomNavigationBarType.fixed,
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          selectedItemColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          unselectedItemColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          selectedFontSize: 11,
                          unselectedFontSize: 11,
                          selectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                          items: [
                            BottomNavigationBarItem(
                              icon: Semantics(
                                label: 'qa.nav.discover',
                                button: true,
                                child: const CoutureNavIcon(Icons.home_rounded),
                              ),
                              activeIcon: Semantics(
                                label: 'qa.nav.discover',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.home_rounded,
                                  selected: true,
                                ),
                              ),
                              label:
                                  ref
                                          .watch(runtimeFeatureFlagsProvider)
                                          .valueOrNull
                                          ?.enabled(
                                            'intentional_dating_enabled',
                                            fallback: false,
                                          ) ==
                                      true
                                  ? 'Today'
                                  : l10n.navDiscover,
                            ),
                            BottomNavigationBarItem(
                              icon: Semantics(
                                label: 'qa.nav.matches',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.favorite_rounded,
                                ),
                              ),
                              activeIcon: Semantics(
                                label: 'qa.nav.matches',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.favorite_rounded,
                                  selected: true,
                                ),
                              ),
                              label: l10n.navMatches,
                            ),
                            BottomNavigationBarItem(
                              icon: Semantics(
                                label: 'qa.nav.engage',
                                button: true,
                                child: const CoutureNavIcon(Icons.bolt_rounded),
                              ),
                              activeIcon: Semantics(
                                label: 'qa.nav.engage',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.bolt_rounded,
                                  selected: true,
                                ),
                              ),
                              label: l10n.navEngage,
                            ),
                            BottomNavigationBarItem(
                              icon: Semantics(
                                label: 'qa.nav.profile',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.person_rounded,
                                ),
                              ),
                              activeIcon: Semantics(
                                label: 'qa.nav.profile',
                                button: true,
                                child: const CoutureNavIcon(
                                  Icons.person_rounded,
                                  selected: true,
                                ),
                              ),
                              label: l10n.navProfile,
                            ),
                            BottomNavigationBarItem(
                              icon: Semantics(
                                label: 'qa.nav.settings',
                                button: true,
                                child: Badge(
                                  isLabelVisible: notifications.unreadCount > 0,
                                  label: Text('${notifications.unreadCount}'),
                                  child: const CoutureNavIcon(
                                    Icons.settings_rounded,
                                  ),
                                ),
                              ),
                              activeIcon: Semantics(
                                label: 'qa.nav.settings',
                                button: true,
                                child: Badge(
                                  isLabelVisible: notifications.unreadCount > 0,
                                  label: Text('${notifications.unreadCount}'),
                                  child: const CoutureNavIcon(
                                    Icons.settings_rounded,
                                    selected: true,
                                  ),
                                ),
                              ),
                              label: l10n.navSettings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showForegroundNotification(AppNotification notification) {
    if (!mounted) {
      return;
    }
    // Already reading that conversation: the message is on screen.
    if (notification.eventType == 'social.message.new' &&
        SocialChatFocus.open.contains(notification.payload['channel_id'])) {
      ref.read(notificationProvider.notifier).markRead(notification.id);
      return;
    }
    if (notification.eventType == 'call.incoming') {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.successGreen,
                  child: Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  notification.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(notification.body, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(notificationProvider.notifier)
                              .markRead(notification.id);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.call_end_rounded),
                        label: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(notificationProvider.notifier)
                              .markRead(notification.id);
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationInboxScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_rounded),
                        label: const Text('View'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final banner = _banner = messenger.showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.body}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            ref.read(notificationProvider.notifier).markRead(notification.id);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationInboxScreen(),
              ),
            );
          },
        ),
      ),
    );
    banner.closed.whenComplete(() {
      if (identical(_banner, banner)) {
        _banner = null;
      }
    });
  }

  void _openPushAction(PushNotificationAction action) {
    if (!mounted) {
      return;
    }
    ref.read(notificationProvider.notifier).consumePushAction();
    // Support replies and status changes open the ticket thread.
    final supportTicketId = action.data['ticket_id']?.toString() ?? '';
    if (openSupportRoute(
      context,
      action.actionRoute ??
          (action.eventType.startsWith('support.') && supportTicketId.isNotEmpty
              ? '/support/tickets/$supportTicketId'
              : null),
    )) {
      return;
    }
    if (action.eventType.startsWith('friend_vouch.') ||
        action.eventType.startsWith('friend_intro.') ||
        action.eventType.startsWith('friend_request.')) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const FriendsScreen()));
      return;
    }
    if (action.category == 'friend_plan' ||
        action.eventType.startsWith('date_plan.')) {
      // Friends' plan updates open the friends feed; a decision request or
      // check-in reminder on my own plan opens my plans.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PlansScreen(initialTab: action.category == 'friend_plan' ? 1 : 0),
        ),
      );
      return;
    }
    if (action.eventType == 'like.received') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const LikedMeScreen()));
      return;
    }
    if (action.category == 'nudge' ||
        action.eventType == 'match_nudge.received') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MatchNudgesScreen()),
      );
      return;
    }
    if (action.category == 'call' || action.eventType == 'call.incoming') {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.successGreen,
                  child: Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Incoming call',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A match is calling you.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationInboxScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_rounded),
                  label: const Text('View call details'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationInboxScreen()),
    );
  }

  Widget _buildQaAutomationSurface(int selectedIndex, {double topInset = 0}) {
    final isDiscover = selectedIndex == 0;
    final isProfileOrSettings = selectedIndex == 3 || selectedIndex == 4;
    if (!isDiscover && !isProfileOrSettings) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      // Cleared past any connectivity banners. This surface is pinned to the
      // top of the Stack while the banners live in the Column beneath it, so
      // without the inset the automation row lands on top of the banner text.
      top: MediaQuery.paddingOf(context).top + 8 + topInset,
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SizedBox(
              height: 48,
              child: isDiscover
                  ? Row(
                      children: [
                        const Spacer(),
                        Semantics(
                          label: 'qa.discovery.filter_button',
                          button: true,
                          child: SizedBox(
                            width: 96,
                            height: 44,
                            child: TextButton(
                              onPressed: () => _openFilterSheet(context),
                              child: const Text('Filters'),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Semantics(
                            label: 'qa.verification.shortcut_upload',
                            button: true,
                            child: SizedBox(
                              width: 112,
                              height: 44,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const VerificationUploadIdScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Verify'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label:
                                'Edit Profile Kalyan Test Viewer About you '
                                'Location Dating preferences Kalyan '
                                'Maharashtra India',
                            button: true,
                            child: SizedBox(
                              width: 132,
                              height: 44,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _setSelectedIndex(int index) {
    if (index == 1)
      ref.read(matchesViewProvider.notifier).state = MatchesView.discover;
    ref.read(mainNavigationIndexProvider.notifier).state = index;
    if (index == 0) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: _buildFilterSheet,
    );
  }

  /// Treats an empty or whitespace-only stored value as unset.
  ///
  /// A dropdown whose value is "" matches no option, which makes the field
  /// render blank instead of falling back to "Any".
  static String? _presentOrNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Builds the filter surface shown in the Discover filter bottom sheet.
  ///
  /// The provider reads live inside a [Consumer] rather than on the enclosing
  /// State. `showModalBottomSheet` builds its child in a separate route, so a
  /// `ref.watch` performed here would register the dependency against
  /// MainNavigationScreen and rebuild *that* — never the open sheet. The sheet
  /// therefore rendered whatever the providers happened to hold on the frame it
  /// opened, which for a cold read is `AsyncLoading`: no saved preferences and
  /// an empty master list, so every control fell back to "Any" and the sliders
  /// to their hardcoded 20-50 / 50km. Watching from inside the sheet's own
  /// subtree lets it rebuild when the drafts and master data arrive.
  Widget _buildFilterSheet(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final trustState = ref.watch(trustFilterNotifierProvider);
      final trustNotifier = ref.read(trustFilterNotifierProvider.notifier);
      final masterData = ref
          .watch(preferenceMasterDataProvider)
          .maybeWhen(data: (data) => data, orElse: PreferenceMasterData.empty);
      // Seed once. A cleared value must remain clear after provider rebuilds
      // and when reopening the sheet.
      final savedPreferences = ref
          .watch(profileSetupNotifierProvider)
          .maybeWhen(data: (draft) => draft, orElse: () => null);
      if (savedPreferences != null && !_filtersSeededFromProfile) {
        _filtersSeededFromProfile = true;
        // Age and distance had the same defect as the dropdowns: the sheet always
        // opened on a hardcoded 20-50 / 50km regardless of what the member had
        // saved. Clamped to the slider bounds, because a stored value outside
        // them makes RangeSlider assert rather than degrade.
        final lowerAge = savedPreferences.minAgeYears
            .clamp(PreferenceLimits.minAge, PreferenceLimits.maxAge)
            .toDouble();
        final upperAge = savedPreferences.maxAgeYears
            .clamp(PreferenceLimits.minAge, PreferenceLimits.maxAge)
            .toDouble();
        _filterAge = RangeValues(
          lowerAge <= upperAge ? lowerAge : upperAge,
          lowerAge <= upperAge ? upperAge : lowerAge,
        );
        _filterDistance = savedPreferences.maxDistanceKm
            .clamp(
              PreferenceLimits.minDistanceKm,
              PreferenceLimits.maxDistanceKm,
            )
            .toDouble();
        _filterVerifiedOnly = savedPreferences.verifiedOnly;
        _filterHookupOnly = savedPreferences.hookupOnly;
        _filterCountry ??= _presentOrNull(savedPreferences.country);
        _filterState ??= _presentOrNull(savedPreferences.regionState);
        _filterCity ??= _presentOrNull(savedPreferences.city);
        _filterMotherTongue ??= _presentOrNull(savedPreferences.motherTongue);
        _filterReligion ??= _presentOrNull(savedPreferences.religion);
        _filterSmoking ??= _presentOrNull(savedPreferences.smoking);
        _filterDrinking ??= _presentOrNull(savedPreferences.drinking);
      }
      var trustEnabled = trustState.enabled;
      var minimumActiveBadges = trustState.minimumActiveBadges;
      final requiredBadgeCodes = trustState.requiredBadgeCodes.toSet();

      return Semantics(
        label: 'qa.filters.sheet',
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              gradient: AppTheme.groundGradientOf(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.8),
                    blur: AppTheme.glassBlurUltra,
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.14),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filter Matches',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setSheetState) => ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Age Range',
                            value:
                                '${_filterAge.start.round()}'
                                ' – '
                                '${_filterAge.end.round()}',
                            child: Semantics(
                              label: 'qa.filters.age_range_slider',
                              child: RangeSlider(
                                key: const ValueKey(
                                  'qa.filters.age_range_slider',
                                ),
                                values: _filterAge,
                                min: PreferenceLimits.minAge,
                                max: PreferenceLimits.maxAge,
                                divisions: PreferenceLimits.ageDivisions,
                                labels: RangeLabels(
                                  _filterAge.start.round().toString(),
                                  _filterAge.end.round().toString(),
                                ),
                                onChanged: (values) =>
                                    setSheetState(() => _filterAge = values),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Profile & Lifestyle Filters',
                            child: Column(
                              children: [
                                _buildDropdownFilterField(
                                  label: 'Country',
                                  value: _filterCountry,
                                  options: masterData.countries,
                                  onChanged: (value) => setSheetState(() {
                                    _filterCountry = value;
                                    _filterState = null;
                                    _filterCity = null;
                                  }),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdownFilterField(
                                  label: 'State',
                                  value: _filterState,
                                  options:
                                      masterData
                                          .statesByCountry[_filterCountry] ??
                                      const <String>[],
                                  onChanged: (value) => setSheetState(() {
                                    _filterState = value;
                                    _filterCity = null;
                                  }),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdownFilterField(
                                  label: 'City',
                                  value: _filterCity,
                                  options:
                                      masterData.citiesByState[_filterState] ??
                                      const <String>[],
                                  onChanged: (value) =>
                                      setSheetState(() => _filterCity = value),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdownFilterField(
                                  label: 'Mother Tongue',
                                  value: _filterMotherTongue,
                                  options: masterData.motherTongues,
                                  onChanged: (value) => setSheetState(
                                    () => _filterMotherTongue = value,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdownFilterField(
                                  label: 'Religion',
                                  value: _filterReligion,
                                  options: masterData.religions,
                                  onChanged: (value) => setSheetState(
                                    () => _filterReligion = value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdownFilterField(
                                  label: 'Relationship Status',
                                  value: _filterRelationshipStatus,
                                  options: const [
                                    'Single',
                                    'Divorced',
                                    'Widowed',
                                    'Separated',
                                    'Complicated',
                                  ],
                                  onChanged: (value) => setSheetState(
                                    () => _filterRelationshipStatus = value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdownFilterField(
                                  label: 'Smoking',
                                  value: _filterSmoking,
                                  options: const [
                                    'Never',
                                    'Occasionally',
                                    'Regularly',
                                  ],
                                  onChanged: (value) => setSheetState(
                                    () => _filterSmoking = value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdownFilterField(
                                  label: 'Drinking',
                                  value: _filterDrinking,
                                  options: const [
                                    'Never',
                                    'Occasionally',
                                    'Socially',
                                    'Regularly',
                                  ],
                                  onChanged: (value) => setSheetState(
                                    () => _filterDrinking = value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdownFilterField(
                                  label: 'Personality Type',
                                  value: _filterPersonalityType,
                                  options: const [
                                    'Introvert',
                                    'Ambivert',
                                    'Extrovert',
                                  ],
                                  onChanged: (value) => setSheetState(
                                    () => _filterPersonalityType = value,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Party lover only',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Semantics(
                                      label: 'qa.filters.party_lover_switch',
                                      toggled: _filterPartyLoverOnly,
                                      child: Switch(
                                        key: const ValueKey(
                                          'qa.filters.party_lover_switch',
                                        ),
                                        value: _filterPartyLoverOnly,
                                        onChanged: (value) => setSheetState(
                                          () => _filterPartyLoverOnly = value,
                                        ),
                                        activeThumbColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        activeTrackColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Hookups only',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Semantics(
                                      label: 'qa.filters.hookup_switch',
                                      toggled: _filterHookupOnly,
                                      child: Switch(
                                        key: const ValueKey(
                                          'qa.filters.hookup_switch',
                                        ),
                                        value: _filterHookupOnly,
                                        onChanged: (value) => setSheetState(
                                          () => _filterHookupOnly = value,
                                        ),
                                        activeThumbColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        activeTrackColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Advanced Bio Filters',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Books, novels, songs, hobbies, location and '
                                  'extra-curricular tags can be managed in '
                                  'Settings → Dating Preferences.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const SetupPreferencesScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Open Dating Preferences'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Distance (km)',
                            value: '${_filterDistance.round()} km',
                            child: Semantics(
                              label: 'qa.filters.distance_slider',
                              child: Slider(
                                key: const ValueKey(
                                  'qa.filters.distance_slider',
                                ),
                                value: _filterDistance,
                                min: PreferenceLimits.minDistanceKm,
                                max: PreferenceLimits.maxDistanceKm,
                                divisions: PreferenceLimits.distanceDivisions,
                                label: '${_filterDistance.round()} km',
                                onChanged: (value) => setSheetState(
                                  () => _filterDistance = value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Verified Only',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Show only verified profiles',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Semantics(
                                  label: 'qa.filters.verified_only_switch',
                                  toggled: _filterVerifiedOnly,
                                  child: Switch(
                                    key: const ValueKey(
                                      'qa.filters.verified_only_switch',
                                    ),
                                    value: _filterVerifiedOnly,
                                    onChanged: (value) => setSheetState(
                                      () => _filterVerifiedOnly = value,
                                    ),
                                    activeThumbColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    activeTrackColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.96),
                          blur: 8,
                          child: _buildFilterSection(
                            context,
                            'Trust Filters',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Enable trust-based filtering',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Semantics(
                                      label: 'qa.filters.trust_switch',
                                      toggled: trustEnabled,
                                      child: Switch(
                                        key: const ValueKey(
                                          'qa.filters.trust_switch',
                                        ),
                                        value: trustEnabled,
                                        onChanged: (value) {
                                          setSheetState(() {
                                            trustEnabled = value;
                                          });
                                        },
                                        activeThumbColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        activeTrackColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Minimum active trust badges: '
                                  '$minimumActiveBadges',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Semantics(
                                  label: 'qa.filters.trust_badge_slider',
                                  child: Slider(
                                    key: const ValueKey(
                                      'qa.filters.trust_badge_slider',
                                    ),
                                    value: minimumActiveBadges.toDouble(),
                                    min: 0,
                                    max: 4,
                                    divisions: 4,
                                    label: minimumActiveBadges.toString(),
                                    onChanged: trustEnabled
                                        ? (value) {
                                            setSheetState(() {
                                              minimumActiveBadges = value
                                                  .round();
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: trustState.availableBadges
                                      .map((badge) {
                                        final selected = requiredBadgeCodes
                                            .contains(badge.code);
                                        return FilterChip(
                                          label: Text(badge.label),
                                          selected: selected,
                                          onSelected: trustEnabled
                                              ? (value) {
                                                  setSheetState(() {
                                                    if (value) {
                                                      requiredBadgeCodes.add(
                                                        badge.code,
                                                      );
                                                    } else {
                                                      requiredBadgeCodes.remove(
                                                        badge.code,
                                                      );
                                                    }
                                                  });
                                                }
                                              : null,
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                                if (trustState.isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: LinearProgressIndicator(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: 'qa.filters.reset_button',
                                button: true,
                                child: OutlinedButton(
                                  key: const ValueKey(
                                    'qa.filters.reset_button',
                                  ),
                                  onPressed: trustState.isSaving
                                      ? null
                                      : () {
                                          setSheetState(() {
                                            _filterAge = const RangeValues(
                                              20,
                                              50,
                                            );
                                            _filterDistance = 50;
                                            _filterVerifiedOnly = false;
                                            _filterReligion = null;
                                            _filterMotherTongue = null;
                                            _filterCountry = null;
                                            _filterState = null;
                                            _filterCity = null;
                                            _filterRelationshipStatus = null;
                                            _filterSmoking = null;
                                            _filterDrinking = null;
                                            _filterPersonalityType = null;
                                            _filterPartyLoverOnly = false;
                                            _filterHookupOnly = false;
                                          });
                                          ref
                                              .read(
                                                swipeNotifierProvider.notifier,
                                              )
                                              .setManualFilters(
                                                const <String, String>{},
                                              );
                                          setSheetState(() {
                                            trustEnabled = false;
                                            minimumActiveBadges = 0;
                                            requiredBadgeCodes.clear();
                                          });
                                        },
                                  child: const Text('Reset'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Semantics(
                                label: 'qa.filters.apply_button',
                                button: true,
                                child: ElevatedButton(
                                  key: const ValueKey(
                                    'qa.filters.apply_button',
                                  ),
                                  onPressed: trustState.isSaving
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          await trustNotifier.save(
                                            enabled: trustEnabled,
                                            minimumActiveBadges:
                                                minimumActiveBadges,
                                            requiredBadgeCodes:
                                                requiredBadgeCodes.toList(),
                                          );
                                          if (!context.mounted) return;
                                          final latestTrust = ref.read(
                                            trustFilterNotifierProvider,
                                          );
                                          if (latestTrust.error != null) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  latestTrust.error!,
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          ref
                                              .read(
                                                swipeNotifierProvider.notifier,
                                              )
                                              .setManualFilters(
                                                _manualFiltersPayload,
                                              );
                                          await ref
                                              .read(
                                                swipeNotifierProvider.notifier,
                                              )
                                              .refreshProfiles();
                                          await ref
                                              .read(
                                                matchNotifierProvider.notifier,
                                              )
                                              .refresh();

                                          if (!context.mounted) {
                                            return;
                                          }

                                          Navigator.of(context).pop();

                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Filters saved: '
                                                '${_filterAge.start.round()}-'
                                                '${_filterAge.end.round()} yrs, '
                                                '${_filterDistance.round()} km'
                                                '${_filterVerifiedOnly ? ', '
                                                          'verified only' : ''}'
                                                '${trustEnabled ? ', trust '
                                                          'filter on' : ', trust '
                                                          'filter off'}',
                                              ),
                                            ),
                                          );
                                        },
                                  child: trustState.isSaving
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Apply'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildFilterSection(
    BuildContext context,
    String title, {
    required Widget child,
    String? value,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          // Slider labels only surface while a thumb is being dragged, so at
          // rest the sheet showed a filter with no readable value at all — the
          // user could not tell what range was selected without grabbing it.
          // The readout keeps the current value visible the whole time.
          if (value != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  );

  Map<String, String> get _manualFiltersPayload {
    final payload = <String, String>{
      'min_age': _filterAge.start.round().toString(),
      'max_age': _filterAge.end.round().toString(),
      'max_distance_km': _filterDistance.round().toString(),
      'verified_only': _filterVerifiedOnly.toString(),
    };

    void put(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        payload[key] = normalized;
      }
    }

    put('religion', _filterReligion);
    put('mother_tongue', _filterMotherTongue);
    put('country', _filterCountry);
    put('state', _filterState);
    put('city', _filterCity);
    put('relationship_status', _filterRelationshipStatus);
    put('smoking', _filterSmoking);
    put('drinking', _filterDrinking);
    put('personality_type', _filterPersonalityType);
    if (_filterPartyLoverOnly) {
      payload['party_lover'] = 'true';
    }
    if (_filterHookupOnly) {
      payload['hookup_only'] = 'true';
    }

    return payload;
  }

  List<String> get _discoverActiveFilterChips {
    final chips = <String>[];

    if (_filterVerifiedOnly) {
      chips.add('Verified only');
    }

    if (_filterAge != const RangeValues(20, 50)) {
      chips.add('${_filterAge.start.round()}–${_filterAge.end.round()}');
    }

    if (_filterDistance.round() != 50) {
      chips.add('${_filterDistance.round()} km');
    }

    void addIfSet(String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        chips.add(normalized);
      }
    }

    addIfSet(_filterReligion);
    addIfSet(_filterMotherTongue);
    addIfSet(_filterCountry);
    addIfSet(_filterState);
    addIfSet(_filterCity);

    if (_filterPartyLoverOnly) {
      chips.add('Party lover');
    }
    if (_filterHookupOnly) {
      chips.add('Hookup only');
    }

    return chips;
  }

  Widget _buildDropdownFilterField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final resolvedValue = options.contains(value) ? value : null;
    final qaId = 'qa.filters.${_qaIdForLabel(label)}_dropdown';
    return Semantics(
      label: qaId,
      button: true,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: ValueKey<String>(qaId),
            value: resolvedValue,
            isExpanded: true,
            hint: const Text('Any'),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Any')),
              ...options.map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  String _qaIdForLabel(String label) => label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
