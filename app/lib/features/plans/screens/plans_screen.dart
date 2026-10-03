import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../messaging/screens/chat_screen.dart';
import '../models/date_plan.dart';
import '../models/date_plan_labels.dart';
import '../providers/plans_provider.dart';
import 'plan_sharing_sheet.dart';
import '../widgets/plan_preferences_summary.dart';

/// Two feeds: the member's own plans across matches, and the plans their
/// friends explicitly shared with them as trusted contacts.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plansFeedProvider);
    final notifier = ref.read(plansFeedProvider.notifier);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plansTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              key: const ValueKey('qa.plans.tab.mine'),
              text: l10n.plansTabMine,
            ),
            Tab(
              key: const ValueKey('qa.plans.tab.friends'),
              text: l10n.plansTabFriends,
            ),
          ],
        ),
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: [
              _MyPlansTab(state: state, onRefresh: notifier.load),
              _FriendPlansTab(state: state, onRefresh: notifier.load),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPlansTab extends StatelessWidget {
  const _MyPlansTab({required this.state, required this.onRefresh});

  final PlansFeedState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.mine.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.error != null)
            _ErrorLine(
              localizedDatePlanError(l10n, state.error!, state.failure),
            ),
          if (state.mine.isEmpty)
            _Empty(
              icon: Icons.event_available_rounded,
              title: l10n.plansEmptyMineTitle,
              body: l10n.plansEmptyMineBody,
            )
          else
            for (final plan in state.mine) _MyPlanTile(plan: plan),
        ],
      ),
    );
  }
}

class _MyPlanTile extends StatelessWidget {
  const _MyPlanTile({required this.plan});

  final DatePlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    return GlassContainer(
      key: ValueKey('qa.plans.mine.${plan.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
      blur: 8,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            matchId: plan.matchId,
            otherUserId: plan.partnerUserId,
            userName: plan.partnerLabel(l10n),
            userPhotoUrl: '',
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.plansWith(plan.partnerLabel(l10n)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PlanStatusPill(status: plan.status),
            ],
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            plan.localizedSummary(l10n, locale: localeName),
            style: theme.textTheme.bodyMedium,
          ),
          PlanPreferencesSummary(plan: plan),
          const SizedBox(height: AppLayout.space2),
          Text(
            _nextActionLine(l10n, plan),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton.icon(
            key: ValueKey('qa.plans.sharing.${plan.id}'),
            onPressed: () => showPlanSharingSheet(context, plan),
            icon: const Icon(Icons.shield_outlined),
            label: Text(l10n.plansManageSharing),
          ),
        ],
      ),
    );
  }

  String _nextActionLine(AppLocalizations l10n, DatePlan plan) =>
      switch (plan.nextAction) {
        'decide' => l10n.plansNextDecide,
        'await_decision' => l10n.plansNextAwait(plan.partnerLabel(l10n)),
        'upcoming' => l10n.plansNextUpcoming,
        'checkin' => l10n.plansNextCheckin,
        'debrief' => l10n.plansNextDebrief,
        _ =>
          plan.status == 'cancelled'
              ? l10n.plansNextCancelled
              : l10n.plansNextDone,
      };
}

class _FriendPlansTab extends StatelessWidget {
  const _FriendPlansTab({required this.state, required this.onRefresh});

  final PlansFeedState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.error != null)
            _ErrorLine(
              localizedDatePlanError(l10n, state.error!, state.failure),
            ),
          if (state.friends.isEmpty)
            _Empty(
              icon: Icons.people_outline_rounded,
              title: l10n.plansEmptyFriendsTitle,
              body: l10n.plansEmptyFriendsBody,
            )
          else
            for (final plan in state.friends) _FriendPlanTile(plan: plan),
        ],
      ),
    );
  }
}

class _FriendPlanTile extends StatelessWidget {
  const _FriendPlanTile({required this.plan});

  final FriendPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final alert = plan.needsHelp || plan.missedCheckin;
    final accent = plan.needsHelp
        ? theme.colorScheme.error
        : plan.missedCheckin
        ? AppTheme.warningOrange
        : plan.checkedInSafe
        ? AppTheme.successGreen
        : theme.colorScheme.primary;
    return Semantics(
      identifier: 'qa.plans.friend.${plan.latestUpdate}',
      container: true,
      child: GlassContainer(
        key: ValueKey('qa.plans.friend.${plan.planId}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        backgroundColor: alert
            ? accent.withValues(alpha: 0.10)
            : theme.colorScheme.surface,
        blur: 8,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon(plan), color: accent),
                const SizedBox(width: AppLayout.space3),
                Expanded(
                  child: Text(
                    plan.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              plan.localizedSummary(l10n, locale: localeName),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              _footer(l10n, plan),
              style: theme.textTheme.bodySmall?.copyWith(
                color: alert ? accent : theme.colorScheme.onSurfaceVariant,
                fontWeight: alert ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(FriendPlan plan) {
    if (plan.needsHelp) {
      return Icons.sos_rounded;
    }
    if (plan.missedCheckin) {
      return Icons.timer_off_outlined;
    }
    if (plan.checkedInSafe) {
      return Icons.verified_user_rounded;
    }
    return Icons.event_available_rounded;
  }

  String _footer(AppLocalizations l10n, FriendPlan plan) {
    final via = plan.via == 'group' ? l10n.plansViaGroup : l10n.plansViaFriend;
    if (plan.needsHelp) {
      return l10n.plansFriendNeedsHelp(plan.friendLabel(l10n));
    }
    if (plan.missedCheckin) {
      return l10n.plansFriendMissedCheckin(plan.friendLabel(l10n));
    }
    if (plan.checkedInSafe) {
      return l10n.plansFriendCheckedInSafe(plan.friendLabel(l10n), via);
    }
    return l10n.plansFriendStatusLine(via, _statusWord(l10n, plan.status));
  }

  String _statusWord(AppLocalizations l10n, String status) => switch (status) {
    'proposed' => l10n.plansStatusWordProposed,
    'accepted' => l10n.plansStatusWordConfirmed,
    'cancelled' => l10n.plansStatusWordCancelled,
    'completed' => l10n.plansStatusWordHappened,
    _ => status,
  };
}

class _PlanStatusPill extends StatelessWidget {
  const _PlanStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'accepted' => AppTheme.successGreen,
      'proposed' => scheme.primary,
      'cancelled' || 'declined' || 'expired' => scheme.onSurfaceVariant,
      _ => scheme.primary,
    };
    final label = datePlanStatusLabel(l10n, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppLayout.space3),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
