import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/date_plan.dart';
import 'plan_preferences_summary.dart';
import '../models/date_plan_labels.dart';
import '../providers/plans_provider.dart';
import '../screens/debrief_date_plan_sheet.dart';
import '../screens/plan_sharing_sheet.dart';
import '../screens/propose_date_plan_sheet.dart';

/// The pinned plan card at the top of a conversation. It shows the one open
/// plan for the match and the server's next action for the viewer, or a
/// "plan a date" call to action when there is no open plan and the
/// conversation is unlocked.
class DatePlanCard extends ConsumerWidget {
  const DatePlanCard({
    required this.matchId,
    required this.partnerName,
    super.key,
  });

  final String matchId;
  final String partnerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchPlansProvider(matchId));
    final notifier = ref.read(matchPlansProvider(matchId).notifier);
    final viewerId = ref.watch(authNotifierProvider).userId ?? '';
    final plan = state.plan;
    final intentional =
        ref
            .watch(runtimeFeatureFlagsProvider)
            .valueOrNull
            ?.enabled('intentional_dating_enabled', fallback: false) ??
        false;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();

    if (!state.loaded) {
      return const SizedBox.shrink();
    }
    if (plan == null) {
      if (intentional &&
          state.snapshot.history.isNotEmpty &&
          state.snapshot.history.first.mutualSecondYes) {
        return _Shell(
          qaId: 'qa.plan.second_yes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planSecondYesHeadline,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.planSecondYesCardBody),
              if (state.snapshot.canPropose)
                TextButton(
                  key: const ValueKey('qa.plan.another_hello'),
                  onPressed: () => showProposeDatePlanSheet(
                    context: context,
                    matchId: matchId,
                    partnerName: partnerName,
                  ),
                  child: Text(l10n.planAnotherHello),
                ),
            ],
          ),
        );
      }
      if (!state.snapshot.canPropose) {
        return const SizedBox.shrink();
      }
      return _Shell(
        qaId: 'qa.plan.card.propose',
        child: Row(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppLayout.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.planProposeTitle(partnerName),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.planProposeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.space2),
            FilledButton.tonal(
              key: const ValueKey('qa.plan.propose_cta'),
              style: FilledButton.styleFrom(minimumSize: _tapTarget),
              onPressed: state.isMutating
                  ? null
                  : () => showProposeDatePlanSheet(
                      context: context,
                      matchId: matchId,
                      partnerName: partnerName,
                    ),
              child: Text(l10n.planProposeButton),
            ),
          ],
        ),
      );
    }

    final ownCheckin = plan.checkinFor(viewerId);
    return _Shell(
      qaId: 'qa.plan.card.${plan.status}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(plan), color: _colorFor(context, plan)),
              const SizedBox(width: AppLayout.space3),
              Expanded(
                child: Text(
                  _headline(l10n, plan, ownCheckin),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(plan: plan),
            ],
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            plan.localizedSummary(l10n, locale: localeName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          PlanPreferencesSummary(plan: plan),
          if (intentional && plan.nextAction == 'decide')
            TextButton.icon(
              key: const ValueKey('qa.plan.counter'),
              onPressed: state.isMutating
                  ? null
                  : () => showProposeDatePlanSheet(
                      context: context,
                      matchId: matchId,
                      partnerName: partnerName,
                      counterTo: plan,
                    ),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l10n.planSuggestChange),
            ),
          if (plan.note.isNotEmpty) ...[
            const SizedBox(height: AppLayout.space1),
            Text(
              l10n.planQuotedNote(plan.note),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: AppLayout.space2),
            Text(
              localizedDatePlanError(l10n, state.error!, state.failure),
              key: const ValueKey('qa.plan.card_error'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppLayout.space3),
          TextButton.icon(
            key: const ValueKey('qa.plan.sharing'),
            onPressed: state.isMutating
                ? null
                : () => showPlanSharingSheet(context, plan),
            icon: const Icon(Icons.shield_outlined),
            label: Text(l10n.planChooseUpdates),
          ),
          _Actions(
            matchId: matchId,
            plan: plan,
            busy: state.isMutating,
            shareGroups: const [],
            notifier: notifier,
          ),
        ],
      ),
    );
  }

  String _headline(
    AppLocalizations l10n,
    DatePlan plan,
    DatePlanCheckin? ownCheckin,
  ) {
    switch (plan.nextAction) {
      case 'decide':
        return l10n.planHeadlineProposed(partnerName);
      case 'await_decision':
        return l10n.planHeadlineWaiting(partnerName);
      case 'upcoming':
        return l10n.planHeadlineUpcoming;
      case 'checkin':
        return l10n.planHeadlineCheckin;
      case 'debrief':
        return l10n.planHeadlineDebrief;
      case 'none':
        if (plan.debrief != null) {
          return plan.partnerDebriefed
              ? l10n.planHeadlineDebriefComplete
              : l10n.planHeadlineWaitingDebrief(partnerName);
        }
        if (ownCheckin != null) {
          return ownCheckin.isSafe
              ? l10n.planHeadlineCheckedInSafe
              : l10n.planHeadlineFriendsAlerted;
        }
        return l10n.planHeadlineDefault;
      default:
        return l10n.planHeadlineDefault;
    }
  }

  IconData _iconFor(DatePlan plan) => switch (plan.nextAction) {
    'decide' => Icons.mark_email_unread_outlined,
    'await_decision' => Icons.hourglass_top_rounded,
    'upcoming' => Icons.event_available_rounded,
    'checkin' => Icons.health_and_safety_outlined,
    'debrief' => Icons.rate_review_outlined,
    _ => Icons.event_rounded,
  };

  Color _colorFor(BuildContext context, DatePlan plan) =>
      switch (plan.nextAction) {
        'checkin' => AppTheme.warningOrange,
        'upcoming' => AppTheme.successGreen,
        _ => Theme.of(context).colorScheme.primary,
      };
}

class _Shell extends StatelessWidget {
  const _Shell({required this.qaId, required this.child});

  /// Automation id (semantics identifier and key); the card is read by its
  /// own text.
  final String qaId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: qaId,
    container: true,
    // The chat screen caps the card's height; the card scrolls inside that
    // cap at large text scales so the conversation stays usable.
    child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: GlassContainer(
        key: ValueKey(qaId),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.surface,
        blur: 10,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: child,
      ),
    ),
  );
}

/// Buttons inside the card meet the 48pt tap-target guideline.
const _tapTarget = Size(AppLayout.minTapTarget, AppLayout.minTapTarget);

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.plan});

  final DatePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = datePlanStatusLabel(l10n, plan.status);
    final accent = plan.isAccepted
        ? AppTheme.successGreen
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.matchId,
    required this.plan,
    required this.busy,
    required this.shareGroups,
    required this.notifier,
  });

  final String matchId;
  final DatePlan plan;
  final bool busy;
  final List<DatePlanShareGroup> shareGroups;
  final MatchPlansNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    switch (plan.nextAction) {
      case 'debrief':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('qa.plan.debrief'),
            style: FilledButton.styleFrom(minimumSize: _tapTarget),
            onPressed: busy ? null : () => _debrief(context, ref),
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(l10n.planDebriefButton),
          ),
        );
      case 'decide':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('qa.plan.decline'),
                style: OutlinedButton.styleFrom(minimumSize: _tapTarget),
                onPressed: busy
                    ? null
                    : () => notifier.decide(
                        planId: plan.id,
                        accept: false,
                        expectedVersion: plan.lockVersion,
                      ),
                child: Text(l10n.planDecline),
              ),
            ),
            const SizedBox(width: AppLayout.space2),
            Expanded(
              child: FilledButton(
                key: const ValueKey('qa.plan.accept'),
                style: FilledButton.styleFrom(minimumSize: _tapTarget),
                onPressed: busy ? null : () => _accept(context),
                child: Text(l10n.planAccept),
              ),
            ),
          ],
        );
      case 'await_decision':
      case 'upcoming':
        return Row(
          children: [
            if (plan.friendRecipients > 0 || plan.isAccepted)
              Expanded(
                child: Text(
                  plan.isAccepted
                      ? l10n.planFriendsKnowAccepted
                      : l10n.planFriendsKnowProposed,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              const Spacer(),
            TextButton(
              key: const ValueKey('qa.plan.cancel'),
              style: TextButton.styleFrom(minimumSize: _tapTarget),
              onPressed: busy ? null : () => _cancel(context),
              child: Text(l10n.planCancel),
            ),
          ],
        );
      case 'checkin':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('qa.plan.need_help'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: _tapTarget,
                ),
                onPressed: busy
                    ? null
                    : () => notifier.checkin(planId: plan.id, safe: false),
                icon: const Icon(Icons.sos_rounded),
                label: Text(l10n.planNeedHelp),
              ),
            ),
            const SizedBox(width: AppLayout.space2),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('qa.plan.safe'),
                style: FilledButton.styleFrom(minimumSize: _tapTarget),
                onPressed: busy
                    ? null
                    : () => notifier.checkin(planId: plan.id, safe: true),
                icon: const Icon(Icons.verified_user_rounded),
                label: Text(l10n.planImSafe),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _debrief(BuildContext context, WidgetRef ref) async {
    final updated = await showDebriefDatePlanSheet(
      context: context,
      matchId: matchId,
      plan: plan,
    );
    if (updated == null || !context.mounted) {
      return;
    }
    if (updated.debrief?.feltSafe == false) {
      await offerReportAfterUnsafeDebrief(
        context: context,
        ref: ref,
        plan: updated,
      );
    }
  }

  Future<void> _accept(BuildContext context) async {
    var groupIds = const <String>[];
    if (shareGroups.isNotEmpty) {
      final chosen = await showAcceptDatePlanSheet(
        context: context,
        plan: plan,
        groups: shareGroups,
      );
      if (chosen == null) {
        return;
      }
      groupIds = chosen;
    }
    await notifier.decide(
      planId: plan.id,
      accept: true,
      groupIds: groupIds,
      expectedVersion: plan.lockVersion,
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.planCancelDialogTitle),
        content: Text(l10n.planCancelDialogBody(plan.partnerLabel(l10n))),
        actions: [
          TextButton(
            key: const ValueKey('qa.plan.keep_it'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.planKeepIt),
          ),
          FilledButton(
            key: const ValueKey('qa.plan.cancel_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.planCancel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.cancel(planId: plan.id);
    }
  }
}
