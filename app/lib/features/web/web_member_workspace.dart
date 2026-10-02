import 'dart:async';
import '../blog/blog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/browser_context.dart';
import '../../core/providers/runtime_feature_flags_provider.dart';
import '../../core/widgets/connect_brand.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../common/screens/main_navigation_screen.dart';
import '../matching/screens/matches_list_screen.dart';
import '../first_chapter/chapter_studio_screen.dart';
import '../common/screens/account_data_screen.dart';
import '../common/screens/privacy_safety_screen.dart';
import '../common/screens/help_support_screen.dart';
import '../common/screens/notification_settings_screen.dart';
import '../common/screens/blocked_users_screen.dart';
import '../common/screens/emergency_contacts_screen.dart';
import '../common/screens/moderation_appeals_screen.dart';
import '../engagement/screens/daily_prompt_screen.dart';
import '../engagement/screens/level_progression_screen.dart';
import '../engagement/screens/trust_badges_screen.dart';
import '../engagement/screens/trust_filter_screen.dart';
import '../engagement/screens/voice_icebreakers_screen.dart';
import '../engagement/screens/circle_challenges_screen.dart';
import '../engagement/screens/group_coffee_polls_screen.dart';
import '../engagement/screens/conversation_rooms_screen.dart';
import '../engagement/screens/match_nudges_screen.dart';
import '../friends/screens/friends_screen.dart';
import '../groups/groups_screen.dart';
import '../calls/screens/call_history_screen.dart';
import '../notifications/screens/notification_inbox_screen.dart';
import '../payment/screens/subscription_screen.dart';
import '../plans/screens/plans_screen.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../profile/screens/setup/setup_photos_screen.dart';
import '../profile/screens/setup/setup_preferences_screen.dart';
import '../swipe/screens/liked_me_screen.dart';
import '../verification/screens/verification_landing_screen.dart';

class WebDestination {
  const WebDestination(
    this.path,
    this.label,
    this.icon,
    this.build, {
    this.flag,
    this.labelOf,
  });
  final String path;

  /// English name; stable for code and tests. Show [labelFor] to members.
  final String label;

  /// The name in the member's language.
  final String Function(AppLocalizations l10n)? labelOf;

  String labelFor(AppLocalizations l10n) => labelOf?.call(l10n) ?? label;
  final IconData icon;
  final Widget Function() build;

  /// Runtime flag that must be on for this destination to be reachable.
  final String? flag;

  bool availableWith(RuntimeFeatureFlags flags) =>
      flag == null || flags.enabled(flag!, fallback: true);
}

final webDestinations = <WebDestination>[
  WebDestination(
    '/blog',
    'Blog',
    labelOf: (l) => l.webDestBlog,
    Icons.menu_book_outlined,
    () => const BlogScreen(),
    flag: 'intentional_dating_enabled',
  ),
  WebDestination(
    '/first-chapter',
    'First Chapter Studio',
    labelOf: (l) => l.webDestFirstChapter,
    Icons.auto_stories_outlined,
    () => const ChapterStudioScreen(),
    flag: 'intentional_dating_enabled',
  ),
  WebDestination(
    '/preferences',
    'Dating preferences',
    labelOf: (l) => l.webDestDatingPreferences,
    Icons.tune_rounded,
    () => const SetupPreferencesScreen(isSetupFlow: false),
  ),
  WebDestination(
    '/edit-profile',
    'Edit profile',
    labelOf: (l) => l.webDestEditProfile,
    Icons.edit_outlined,
    () => const EditProfileScreen(),
  ),
  WebDestination(
    '/photos',
    'Profile photos',
    labelOf: (l) => l.webDestProfilePhotos,
    Icons.photo_library_outlined,
    () => const SetupPhotosScreen(),
  ),
  // Matches the action route of the "Someone liked you" notification.
  WebDestination(
    '/likes',
    'Liked you',
    labelOf: (l) => l.webDestLikedYou,
    Icons.favorite_border_rounded,
    () => const LikedMeScreen(),
  ),
  WebDestination(
    '/notifications',
    'Notifications',
    labelOf: (l) => l.webDestNotifications,
    Icons.notifications_outlined,
    () => const NotificationInboxScreen(),
  ),
  WebDestination(
    '/daily-prompt',
    'Daily prompt',
    labelOf: (l) => l.webDestDailyPrompt,
    Icons.lightbulb_outline_rounded,
    () => const DailyPromptScreen(),
    flag: 'daily_prompts_enabled',
  ),
  WebDestination(
    '/progression',
    'Levels & progress',
    labelOf: (l) => l.webDestLevels,
    Icons.insights_rounded,
    () => const LevelProgressionScreen(),
    flag: 'level_progression_enabled',
  ),
  WebDestination(
    '/trust',
    'Trust badges',
    labelOf: (l) => l.webDestTrustBadges,
    Icons.verified_outlined,
    () => const TrustBadgesScreen(),
  ),
  WebDestination(
    '/trust-filters',
    'Trust filters',
    labelOf: (l) => l.webDestTrustFilters,
    Icons.filter_alt_outlined,
    () => const TrustFilterScreen(),
  ),
  WebDestination(
    '/icebreakers',
    'Icebreakers',
    labelOf: (l) => l.webDestIcebreakers,
    Icons.record_voice_over_outlined,
    () => const VoiceIcebreakersScreen(),
    flag: 'voice_icebreakers_enabled',
  ),
  WebDestination(
    '/challenges',
    'Circle challenges',
    labelOf: (l) => l.webDestCircleChallenges,
    Icons.emoji_events_outlined,
    () => const CircleChallengesScreen(),
    flag: 'circles_enabled',
  ),
  WebDestination(
    '/coffee',
    'Coffee polls',
    labelOf: (l) => l.webDestCoffeePolls,
    Icons.coffee_outlined,
    () => const GroupCoffeePollsScreen(),
    flag: 'group_coffee_polls_enabled',
  ),
  WebDestination(
    '/groups',
    'Groups',
    labelOf: (l) => l.webDestGroups,
    Icons.groups_outlined,
    () => const GroupsScreen(),
    flag: 'groups_enabled',
  ),
  WebDestination(
    '/rooms',
    'Conversation rooms',
    labelOf: (l) => l.webDestRooms,
    Icons.forum_outlined,
    () => const ConversationRoomsScreen(),
    flag: 'rooms_enabled',
  ),
  WebDestination(
    '/nudges',
    'Match nudges',
    labelOf: (l) => l.webDestMatchNudges,
    Icons.waving_hand_outlined,
    () => const MatchNudgesScreen(),
    flag: 'match_nudges_enabled',
  ),
  WebDestination(
    '/friends',
    'Friends',
    labelOf: (l) => l.webDestFriends,
    Icons.people_outline_rounded,
    () => const FriendsScreen(),
  ),
  WebDestination(
    '/plans',
    'Date plans',
    labelOf: (l) => l.webDestDatePlans,
    Icons.event_available_rounded,
    () => const PlansScreen(),
    flag: 'date_plans_enabled',
  ),
  WebDestination(
    '/calls',
    'Call history',
    labelOf: (l) => l.webDestCallHistory,
    Icons.call_outlined,
    () => const CallHistoryScreen(),
    flag: 'calls_enabled',
  ),
  WebDestination(
    '/membership',
    'Membership',
    labelOf: (l) => l.webDestMembership,
    Icons.workspace_premium_outlined,
    () => const SubscriptionScreen(),
    flag: 'billing_enabled',
  ),
  WebDestination(
    '/verification',
    'Verification',
    labelOf: (l) => l.webDestVerification,
    Icons.badge_outlined,
    () => const VerificationLandingScreen(),
    flag: 'identity_verification_enabled',
  ),
  WebDestination(
    '/safety',
    'Privacy & safety',
    labelOf: (l) => l.webDestPrivacySafety,
    Icons.shield_outlined,
    () => const PrivacySafetyScreen(),
  ),
  WebDestination(
    '/account',
    'Account & data',
    labelOf: (l) => l.webDestAccountData,
    Icons.manage_accounts_outlined,
    () => const AccountDataScreen(),
  ),
  WebDestination(
    '/blocked',
    'Blocked members',
    labelOf: (l) => l.webDestBlockedMembers,
    Icons.block_outlined,
    () => const BlockedUsersScreen(),
  ),
  WebDestination(
    '/emergency-contacts',
    'Emergency contacts',
    labelOf: (l) => l.webDestEmergencyContacts,
    Icons.contact_emergency_outlined,
    () => const EmergencyContactsScreen(),
  ),
  WebDestination(
    '/appeals',
    'Moderation appeals',
    labelOf: (l) => l.webDestModerationAppeals,
    Icons.fact_check_outlined,
    () => const ModerationAppealsScreen(),
  ),
  WebDestination(
    '/notification-settings',
    'Notification preferences',
    labelOf: (l) => l.webDestNotificationPreferences,
    Icons.notifications_active_outlined,
    () => const NotificationSettingsScreen(),
  ),
  WebDestination(
    '/help',
    'Help & support',
    labelOf: (l) => l.webDestHelpSupport,
    Icons.help_outline_rounded,
    () => const HelpSupportScreen(),
  ),
];

const _primaryPaths = [
  '/discover',
  '/matches',
  '/engagement',
  '/profile',
  '/settings',
];
List<String> _primaryLabels(AppLocalizations l10n) => [
  l10n.navDiscover,
  l10n.navMatches,
  l10n.webNavExplore,
  l10n.webNavMyProfile,
  l10n.navSettings,
];
const _primaryIcons = [
  Icons.explore_outlined,
  Icons.favorite_border_rounded,
  Icons.grid_view_rounded,
  Icons.person_outline_rounded,
  Icons.settings_outlined,
];

/// Signed-out entry pages. A member who already has a session lands on
/// Discover instead of a "page not found" workspace.
const _signedOutRoutes = {
  '/',
  '/signin',
  '/signup',
  '/welcome',
  '/introducer/signup',
};

/// The workspace route to show a signed-in member for the browser [path].
String webMemberRoute(String path) =>
    _signedOutRoutes.contains(path) ? '/discover' : path;

/// The workspace pages a member has visited, oldest first, so the phone
/// header's Back can return to the page they came from (WEB-09).
///
/// It mirrors the browser history entries the workspace creates: a new page
/// is pushed, and arriving at the page before the current one — through
/// Back, the browser's own Back button or a link — pops instead, so stepping
/// back repeatedly walks the trail rather than bouncing between two pages.
class WebPageTrail {
  static const _limit = 50;
  final List<String> _pages = [];

  /// The page before the current one, or `null` when the member arrived on
  /// the current page directly (a deep link or a fresh tab).
  String? get previous => _pages.length > 1 ? _pages[_pages.length - 2] : null;

  void visit(String path) {
    if (_pages.isNotEmpty && _pages.last == path) {
      return;
    }
    if (previous == path) {
      _pages.removeLast();
      return;
    }
    _pages.add(path);
    if (_pages.length > _limit) {
      _pages.removeAt(0);
    }
  }
}

class WebMemberWorkspace extends ConsumerStatefulWidget {
  const WebMemberWorkspace({super.key});
  @override
  ConsumerState<WebMemberWorkspace> createState() => _WebMemberWorkspaceState();
}

class _WebMemberWorkspaceState extends ConsumerState<WebMemberWorkspace> {
  late String _path;
  late StreamSubscription<void> _routes;
  final _trail = WebPageTrail();
  @override
  void initState() {
    super.initState();
    _path = webMemberRoute(currentWebRoute());
    _routes = webRouteChanges.listen((_) => _applyRoute(currentWebRoute()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _go(_path);
    });
  }

  void _applyRoute(String path) {
    if (!mounted) return;
    final memberPath = webMemberRoute(path);
    if (memberPath != path) {
      // A signed-in member opened a sign-in/sign-up link (the website's
      // "Sign in" button, a bookmark or browser history): send them home.
      // After sign-out (or an expired session) the route to `/signin` lands
      // here before this workspace is replaced; leave it alone then.
      if (ref.read(authNotifierProvider).isAuthenticated) _go(memberPath);
      return;
    }
    final index = _primaryPaths.indexOf(path);
    if (index >= 0)
      ref.read(mainNavigationIndexProvider.notifier).state = index;
    _trail.visit(path);
    setState(() => _path = path);
  }

  /// The phone header's Back: return to the page the member came from, like
  /// the browser's Back button. In a browser the history step brings the
  /// previous route back through [webRouteChanges]; when there is no earlier
  /// entry of this app to step to (a deep link) the workspace navigates
  /// itself, to the previous page it saw or else to Explore.
  void _back() {
    if (webHistoryBack()) {
      return;
    }
    _go(_trail.previous ?? '/engagement');
  }

  void _go(String path) {
    if (path == '/matches')
      ref.read(matchesViewProvider.notifier).state = MatchesView.discover;
    setWebRoute(path);
    _applyRoute(path);
  }

  @override
  void dispose() {
    _routes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<int>(mainNavigationIndexProvider, (_, index) {
      if (_primaryPaths.contains(_path) && _primaryPaths[index] != _path) {
        _path = _primaryPaths[index];
        _trail.visit(_path);
        setWebRoute(_path);
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final colors = Theme.of(context).colorScheme;
    final flags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final primaryIndex = _primaryPaths.indexOf(_path);
    final destinations = webDestinations.where((d) => d.path == _path);
    final destination = destinations.isEmpty ? null : destinations.first;
    final Widget content = primaryIndex >= 0
        ? const MainNavigationScreen()
        : _path == '/features'
        ? _FeatureDirectory(
            onOpen: _go,
            destinations: webDestinations
                .where((d) => d.availableWith(flags))
                .toList(growable: false),
          )
        : destination != null && !destination.availableWith(flags)
        ? _UnavailableDestination(
            label: destination.labelFor(l10n),
            onBack: () => _go('/discover'),
          )
        : destination != null
        ? destination.build()
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.webPageNotFound),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _go('/discover'),
                  child: Text(l10n.webBackToDiscover),
                ),
              ],
            ),
          );
    final title = primaryIndex >= 0
        ? (primaryIndex == 0 &&
                  flags.enabled(
                    'intentional_dating_enabled',
                    fallback: false,
                  ) &&
                  flags.enabled('curated_daily_set_enabled', fallback: true)
              ? l10n.navToday
              : _primaryLabels(l10n)[primaryIndex])
        : destination?.labelFor(l10n) ?? l10n.webNavAllFeatures;
    if (!wide) {
      // A Scaffold, like the wide layout: the directory and "not available"
      // pages have none of their own, and without a Material ancestor their
      // text falls back to the framework's red error style.
      return Scaffold(
        body: Column(
          children: [
            if (primaryIndex < 0)
              Material(
                color: colors.surface,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      BackButton(onPressed: _back),
                      Expanded(child: Text(title)),
                      IconButton(
                        tooltip: l10n.webNavAllFeatures,
                        onPressed: () => _go('/features'),
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          // Keyboard focus finishes the sidebar before the page (WEB-13);
          // without groups Tab zig-zags between them by height on screen.
          FocusTraversalGroup(
            child: Container(
              key: const ValueKey<String>('qa.web.sidebar'),
              width: 264,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(right: BorderSide(color: colors.outline)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: ConnectBrand(
                        onDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (var i = 0; i < _primaryPaths.length; i++)
                            _nav(
                              _primaryPaths[i],
                              i == 0 &&
                                      flags.enabled(
                                        'intentional_dating_enabled',
                                        fallback: false,
                                      ) &&
                                      flags.enabled(
                                        'curated_daily_set_enabled',
                                        fallback: true,
                                      )
                                  ? l10n.navToday
                                  : _primaryLabels(l10n)[i],
                              _primaryIcons[i],
                            ),
                          if (flags.enabled(
                            'intentional_dating_enabled',
                            fallback: true,
                          ))
                            _nav(
                              '/blog',
                              l10n.webDestBlog,
                              Icons.menu_book_outlined,
                            ),
                          _SidebarLabel(l10n.webNavMoreForYou),
                          _nav(
                            '/features',
                            l10n.webNavAllFeatures,
                            Icons.apps_rounded,
                          ),
                          _nav(
                            '/preferences',
                            l10n.webNavPreferences,
                            Icons.tune_rounded,
                          ),
                          _nav(
                            '/notifications',
                            l10n.webDestNotifications,
                            Icons.notifications_outlined,
                          ),
                          if (flags.enabled('billing_enabled', fallback: true))
                            _nav(
                              '/membership',
                              l10n.webDestMembership,
                              Icons.workspace_premium_outlined,
                            ),
                          _nav(
                            '/safety',
                            l10n.webDestPrivacySafety,
                            Icons.shield_outlined,
                          ),
                          _nav(
                            '/help',
                            l10n.webDestHelpSupport,
                            Icons.help_outline_rounded,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.outline),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          _SidebarItem(
                            label: l10n.webNavWebsite,
                            icon: Icons.open_in_new_rounded,
                            onTap: openWebsiteHome,
                          ),
                          _SidebarItem(
                            label: l10n.webNavSignOut,
                            icon: Icons.logout_rounded,
                            onTap: () async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                              setWebRoute('/signin');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(bottom: BorderSide(color: colors.outline)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.webTagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: FocusTraversalGroup(child: content)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(String path, String label, IconData icon) => _SidebarItem(
    label: label,
    icon: icon,
    selected: _path == path,
    onTap: () => _go(path),
  );
}

/// Sidebar group heading in the website's eyebrow style.
class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 28, 12, 8),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? c.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: c.surfaceContainerHighest,
            child: Container(
              // A full 48pt row, whatever the label's line height.
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? c.primary : c.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: c.onSurface,
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

/// Shown when a destination's capability is switched off, including when a
/// member opens its URL directly.
class _UnavailableDestination extends StatelessWidget {
  const _UnavailableDestination({required this.label, required this.onBack});
  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).webUnavailableTitle(label),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).webUnavailableBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(AppLocalizations.of(context).webBackToDiscover),
          ),
        ],
      ),
    ),
  );
}

class _FeatureDirectory extends StatelessWidget {
  const _FeatureDirectory({required this.onOpen, required this.destinations});
  final ValueChanged<String> onOpen;
  final List<WebDestination> destinations;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).webDirectoryTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).webDirectorySubtitle),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, bounds) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final item in destinations)
                    SizedBox(
                      width: bounds.maxWidth >= 700
                          ? (bounds.maxWidth - 32) / 3
                          : bounds.maxWidth >= 440
                          ? (bounds.maxWidth - 16) / 2
                          : bounds.maxWidth,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            item.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            item.labelFor(AppLocalizations.of(context)),
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: const Icon(
                            Icons.north_east_rounded,
                            size: 17,
                          ),
                          onTap: () => onOpen(item.path),
                        ),
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
