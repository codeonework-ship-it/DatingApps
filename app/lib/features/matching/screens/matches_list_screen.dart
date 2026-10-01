import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../calls/screens/call_history_screen.dart';
import '../../calls/screens/call_session_screen.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../../engagement/providers/match_nudge_provider.dart';
import '../../graduation/screens/propose_graduation_sheet.dart';
import '../../messaging/screens/chat_screen.dart';
import '../../plans/screens/propose_date_plan_sheet.dart';
import '../../swipe/screens/home_discovery_screen.dart';
import '../../first_chapter/chapter_studio_screen.dart';
import '../../friends/friend_actions.dart';
import '../providers/match_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/match_overview_card.dart';
import 'activity_session_screen.dart';

enum MatchesView { discover, people, conversations }

final matchesViewProvider = StateProvider<MatchesView>(
  (ref) => MatchesView.discover,
);

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({
    super.key,
    this.onOpenFilters,
    this.activeFilterChips = const [],
    this.isActive = true,
  });
  final VoidCallback? onOpenFilters;
  final List<String> activeFilterChips;
  final bool isActive;

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  final _scrollController = ScrollController();
  String _query = '';
  bool _unreadOnly = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(matchesViewProvider);
    if (view == MatchesView.discover) {
      return Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _viewTabs(view),
                ),
              ),
            ),
            Expanded(
              child: HomeDiscoveryScreen(
                browseOnly: true,
                isActive: widget.isActive,
                onOpenFilters: widget.onOpenFilters,
                activeFilterChips: widget.activeFilterChips,
                onOpenMessages: () =>
                    ref.read(matchesViewProvider.notifier).state =
                        MatchesView.conversations,
              ),
            ),
          ],
        ),
      );
    }
    final matchState = ref.watch(matchNotifierProvider);
    final conversations =
        ref.watch(matchesViewProvider) == MatchesView.conversations;
    final runtimeFlags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final callsEnabled =
        FeatureFlags.enableVideoCall && runtimeFlags.enabled('calls_enabled');
    final nudgesEnabled = runtimeFlags.enabled('match_nudges_enabled');
    final activitiesEnabled = runtimeFlags.enabled('activity_sessions_enabled');
    final matchNotifier = ref.read(matchNotifierProvider.notifier);
    final visibleMatches = matchState.matches
        .where(
          (match) =>
              (!conversations || !_unreadOnly || match.unreadCount > 0) &&
              (match.userName.toLowerCase().contains(_query.toLowerCase()) ||
                  conversations &&
                      match.lastMessage.toLowerCase().contains(
                        _query.toLowerCase(),
                      )),
        )
        .toList();
    final unreadCount = matchState.matches
        .where((match) => match.unreadCount > 0)
        .length;
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Matches',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  if (callsEnabled)
                    IconButton(
                      key: const ValueKey('qa.calls.history'),
                      tooltip: 'Call history',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CallHistoryScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.video_call_outlined),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.7),
                        blur: AppTheme.glassBlurUltra,
                        crystalEffect: true,
                        child: Text(
                          '${matchState.matches.length} ${matchState.matches.length == 1 ? 'match' : 'matches'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversations
                            ? 'A little closer, one message at a time.'
                            : 'People you chose. Possibilities you shape together.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _viewTabs(view),
                      const SizedBox(height: 16),
                      TextField(
                        key: const ValueKey('qa.chat.search_conversations'),
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: conversations
                              ? 'Search conversations'
                              : 'Search your matches',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (conversations)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All conversations'),
                              selected: !_unreadOnly,
                              onSelected: (_) =>
                                  setState(() => _unreadOnly = false),
                            ),
                            ChoiceChip(
                              label: Text('Unread · $unreadCount'),
                              selected: _unreadOnly,
                              onSelected: (_) =>
                                  setState(() => _unreadOnly = true),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Matches List or Empty/Error State
              if (matchState.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading matches...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (matchState.error != null && matchState.matches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load matches',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchState.error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                          GlassButton(
                            label: 'Retry',
                            onPressed: () => matchNotifier.refresh(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (matchState.matches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matches yet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          matchState.trustFilterActive &&
                                  matchState.trustFilteredOutCount > 0
                              ? 'Trust filters hid ${matchState.trustFilteredOutCount} match(es). Try relaxing trust filters from Discover.'
                              : 'Visit Today to discover someone you’d like to meet.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (visibleMatches.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      conversations
                          ? 'No conversations here yet. Try another search or filter.'
                          : 'No matches found. Try another name.',
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final match = visibleMatches[index];
                    void openChat() {
                      matchNotifier.markAsRead(match.id);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(
                            matchId: match.id,
                            otherUserId: match.userId,
                            userName: match.userName,
                            userPhotoUrl: match.userPhoto,
                          ),
                        ),
                      );
                    }

                    void openOptions() => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (sheetContext) => SingleChildScrollView(
                        child: _buildMatchOptionsSheet(
                          pageContext: context,
                          sheetContext: sheetContext,
                          ref: ref,
                          match: match,
                          matchNotifier: matchNotifier,
                          callsEnabled: callsEnabled,
                          activitiesEnabled: activitiesEnabled,
                          nudgesEnabled: nudgesEnabled,
                          plansEnabled: runtimeFlags.enabled(
                            'date_plans_enabled',
                            fallback: true,
                          ),
                          graduationEnabled: runtimeFlags.enabled(
                            'graduation_enabled',
                            fallback: true,
                          ),
                        ),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: conversations
                          ? Semantics(
                              label: 'qa.matches.match_row.${match.id}',
                              button: true,
                              child: MatchCard(
                                key: ValueKey(
                                  'qa.matches.match_row.${match.id}',
                                ),
                                match: match,
                                onTap: openChat,
                                onOptions: openOptions,
                              ),
                            )
                          : MatchOverviewCard(
                              key: ValueKey('qa.matches.person.${match.id}'),
                              match: match,
                              onChat: openChat,
                              onOptions: openOptions,
                              onChapter:
                                  runtimeFlags.enabled(
                                    'intentional_dating_enabled',
                                    fallback: false,
                                  )
                                  ? () => openChapterStudio(
                                      context,
                                      matchId: match.id,
                                      partnerName: match.userName,
                                    )
                                  : null,
                              onPlan:
                                  runtimeFlags.enabled(
                                    'date_plans_enabled',
                                    fallback: true,
                                  )
                                  ? () => showProposeDatePlanSheet(
                                      context: context,
                                      matchId: match.id,
                                      partnerName: match.userName,
                                    )
                                  : null,
                            ),
                    );
                  }, childCount: visibleMatches.length),
                ),

              // Bottom spacing
              SliverPadding(padding: EdgeInsets.only(bottom: bottomClearance)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewTabs(MatchesView selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in const {
        MatchesView.discover: 'Discover',
        MatchesView.people: 'Your matches',
        MatchesView.conversations: 'Conversations',
      }.entries)
        ChoiceChip(
          key: ValueKey('qa.matches.${entry.key.name}_tab'),
          label: Text(entry.value),
          selected: selected == entry.key,
          onSelected: (_) =>
              ref.read(matchesViewProvider.notifier).state = entry.key,
        ),
    ],
  );

  Widget _buildMatchOptionsSheet({
    required BuildContext pageContext,
    required BuildContext sheetContext,
    required WidgetRef ref,
    required Match match,
    required MatchNotifier matchNotifier,
    required bool callsEnabled,
    required bool nudgesEnabled,
    required bool activitiesEnabled,
    bool plansEnabled = true,
    bool graduationEnabled = true,
  }) => GlassContainer(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    backgroundColor: Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0.9),
    blur: 10,
    borderRadius: const BorderRadius.all(Radius.circular(24)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        if (callsEnabled)
          ListTile(
            key: const ValueKey('qa.matches.call_action'),
            leading: Icon(
              Icons.video_call_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Start call session'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(pageContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => CallSessionScreen(
                    matchId: match.id,
                    recipientUserId: match.userId,
                    recipientName: match.userName,
                  ),
                ),
              );
            },
          ),
        // The mini-activity journey was built end to end — lifecycle APIs
        // (Story 4.1), a Riverpod provider, and ActivitySessionScreen — but no
        // screen ever constructed it, so none of it was reachable. This is the
        // missing entry point; it mirrors the call action above because the
        // screen takes the same match/counterparty shape.
        if (activitiesEnabled)
          ListTile(
            key: const ValueKey('qa.matches.activity_action'),
            leading: Icon(
              Icons.extension_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Start an activity'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(pageContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActivitySessionScreen(
                    matchId: match.id,
                    otherUserId: match.userId,
                    otherUserName: match.userName,
                  ),
                ),
              );
            },
          ),
        if (plansEnabled)
          ListTile(
            key: const ValueKey('qa.matches.plan_action'),
            leading: Icon(
              Icons.event_available_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Plan a date'),
            subtitle: const Text('Choose a time and what you want to share'),
            onTap: () {
              Navigator.pop(sheetContext);
              Future<void>.delayed(Duration.zero, () async {
                if (!pageContext.mounted) return;
                final plan = await showProposeDatePlanSheet(
                  context: pageContext,
                  matchId: match.id,
                  partnerName: match.userName,
                );
                if (!pageContext.mounted || plan == null) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text('Plan sent to ${match.userName}.')),
                );
              });
            },
          ),
        if (graduationEnabled)
          ListTile(
            key: const ValueKey('qa.matches.graduation_action'),
            leading: Icon(
              Icons.favorite_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('We found each other'),
            subtitle: const Text('Leave Connect together; your chat stays'),
            onTap: () {
              Navigator.pop(sheetContext);
              Future<void>.delayed(Duration.zero, () async {
                if (!pageContext.mounted) {
                  return;
                }
                final graduation = await showProposeGraduationSheet(
                  context: pageContext,
                  matchId: match.id,
                  partnerName: match.userName,
                );
                if (!pageContext.mounted || graduation == null) {
                  return;
                }
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Asked ${match.userName} to leave together. '
                      'They can confirm from your chat.',
                    ),
                  ),
                );
              });
            },
          ),
        // Add friend / Requested / Accept / Message, kept live inside the
        // sheet by the widget's own provider watch.
        AddFriendButton(
          userId: match.userId,
          name: match.userName,
          source: FriendRequestSource.match,
          style: AddFriendStyle.tile,
        ),
        if (nudgesEnabled)
          ListTile(
            key: const ValueKey('qa.matches.nudge_action'),
            leading: Icon(
              Icons.waving_hand_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Send a nudge'),
            onTap: () {
              Navigator.pop(sheetContext);
              Future<void>.delayed(Duration.zero, () async {
                final nudge = await ref
                    .read(matchNudgeProvider.notifier)
                    .send(matchId: match.id, counterpartyUserId: match.userId);
                if (!pageContext.mounted) return;
                final error = ref
                    .read(matchNudgeProvider)
                    .errorByMatchId[match.id];
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      nudge != null
                          ? 'Nudge sent to ${match.userName}.'
                          : error ?? 'Unable to send this nudge.',
                    ),
                  ),
                );
              });
            },
          ),
        Semantics(
          label: 'qa.matches.unmatch_action',
          button: true,
          child: ListTile(
            key: const ValueKey('qa.matches.unmatch_action'),
            leading: Icon(
              Icons.block,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Close conversation'),
            subtitle: const Text('Make space, without an explanation.'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final close = await showDialog<bool>(
                context: pageContext,
                builder: (dialog) => AlertDialog(
                  title: const Text('Close this conversation?'),
                  content: const Text(
                    'It is okay if this connection is not for you. This ends the match. You do not need to send an explanation. Reporting remains a separate choice.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Keep talking'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Close conversation'),
                    ),
                  ],
                ),
              );
              if (close == true) await matchNotifier.unmatch(match.id);
            },
          ),
        ),
        Semantics(
          label: 'qa.matches.report_action',
          button: true,
          child: ListTile(
            key: const ValueKey('qa.matches.report_action'),
            leading: const Icon(
              Icons.flag_rounded,
              color: AppTheme.warningOrange,
            ),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(sheetContext);
              Future<void>.delayed(Duration.zero, () async {
                final reportId = await showReportUserSheet(
                  context: pageContext,
                  onSubmit: ({required reason, description}) async => ref
                      .read(safetyActionsProvider)
                      .reportUser(
                        reportedUserId: match.userId,
                        reason: reason,
                        description: description,
                      ),
                );

                if (!pageContext.mounted) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: const Text('Report submitted. Thank you.'),
                    action: SnackBarAction(
                      label: 'Appeal',
                      onPressed: () {
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ModerationAppealsScreen(
                              initialReason:
                                  'Review moderation outcome for report on user ${match.userId}',
                              initialReportId: reportId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    ),
  );
}
