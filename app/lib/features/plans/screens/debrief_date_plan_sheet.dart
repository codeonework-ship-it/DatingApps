import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../models/date_plan.dart';
import '../providers/plans_provider.dart';

/// The ten-second post-date debrief. Answers stay private to the member; the
/// other member only learns that a debrief was given. Resolves to the updated
/// plan, or null when the member backed out or the request failed.
Future<DatePlan?> showDebriefDatePlanSheet({
  required BuildContext context,
  required String matchId,
  required DatePlan plan,
}) => showModalBottomSheet<DatePlan?>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _DebriefSheet(matchId: matchId, plan: plan),
);

class _DebriefSheet extends ConsumerStatefulWidget {
  const _DebriefSheet({required this.matchId, required this.plan});

  final String matchId;
  final DatePlan plan;

  @override
  ConsumerState<_DebriefSheet> createState() => _DebriefSheetState();
}

class _DebriefSheetState extends ConsumerState<_DebriefSheet> {
  bool? _happened;
  bool? _wouldMeetAgain;
  bool? _feltSafe;
  bool _shareMutualInterest = false;
  final _note = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Read before the first await: the sheet may be gone by the time the
    // request returns.
    final l10n = AppLocalizations.of(context);
    final happened = _happened;
    if (happened == null) {
      setState(() => _error = l10n.debriefMissingHappened);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final notifier = ref.read(matchPlansProvider(widget.matchId).notifier);
    final updated = await notifier.debrief(
      planId: widget.plan.id,
      happened: happened,
      shareMutualInterest:
          happened && _wouldMeetAgain == true && _shareMutualInterest,
      wouldMeetAgain: happened ? _wouldMeetAgain : null,
      feltSafe: happened ? _feltSafe : null,
      note: _note.text,
    );
    if (!mounted) {
      return;
    }
    if (updated == null) {
      setState(() {
        _submitting = false;
        _error =
            ref.read(matchPlansProvider(widget.matchId)).error ??
            l10n.debriefSaveFailed;
      });
      return;
    }
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.debriefTitle(widget.plan.partnerName),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              l10n.debriefIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppLayout.space5),
            _YesNo(
              question: l10n.debriefHappened,
              keyPrefix: 'qa.debrief.happened',
              value: _happened,
              onChanged: (v) => setState(() => _happened = v),
            ),
            if (_happened ?? false) ...[
              const SizedBox(height: AppLayout.space4),
              _YesNo(
                question: l10n.debriefMeetAgain,
                keyPrefix: 'qa.debrief.again',
                value: _wouldMeetAgain,
                onChanged: (v) => setState(() => _wouldMeetAgain = v),
              ),
              const SizedBox(height: AppLayout.space4),
              if (_wouldMeetAgain == true &&
                  (ref
                          .watch(runtimeFeatureFlagsProvider)
                          .valueOrNull
                          ?.enabled(
                            'intentional_dating_enabled',
                            fallback: false,
                          ) ??
                      false))
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  key: const ValueKey('qa.debrief.second_yes'),
                  title: const Text('Share a second yes'),
                  subtitle: const Text(
                    'Reveal that you want to meet again only if your match also says yes and agrees to share. Your other answers stay private.',
                  ),
                  value: _shareMutualInterest,
                  onChanged: (v) => setState(() => _shareMutualInterest = v),
                ),
              _YesNo(
                question: l10n.debriefFeltSafe,
                keyPrefix: 'qa.debrief.safe',
                value: _feltSafe,
                onChanged: (v) => setState(() => _feltSafe = v),
              ),
            ],
            const SizedBox(height: AppLayout.space4),
            TextField(
              key: const ValueKey('qa.debrief.note'),
              controller: _note,
              maxLength: 280,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.debriefNoteLabel),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppLayout.space3),
              Text(
                _error!,
                key: const ValueKey('qa.debrief.error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppLayout.space5),
            SizedBox(
              width: double.infinity,
              height: AppLayout.minTapTarget,
              child: FilledButton.icon(
                key: const ValueKey('qa.debrief.submit'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.debriefSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({
    required this.question,
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final String keyPrefix;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppLayout.space2),
        Wrap(
          spacing: AppLayout.space2,
          children: [
            ChoiceChip(
              key: ValueKey('$keyPrefix.yes'),
              label: Text(l10n.commonYes),
              selected: value ?? false,
              onSelected: (_) => onChanged(true),
            ),
            ChoiceChip(
              key: ValueKey('$keyPrefix.no'),
              label: Text(l10n.commonNo),
              selected: value == false,
              onSelected: (_) => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

/// After a "did not feel safe" answer, offer the report flow once. Kept apart
/// from the sheet so the plan card can call it after the sheet closes.
Future<void> offerReportAfterUnsafeDebrief({
  required BuildContext context,
  required WidgetRef ref,
  required DatePlan plan,
}) async {
  final l10n = AppLocalizations.of(context);
  final report = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.debriefUnsafeTitle),
      content: Text(l10n.debriefUnsafeBody(plan.partnerName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.debriefNotNow),
        ),
        FilledButton(
          key: const ValueKey('qa.debrief.report'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.debriefReport),
        ),
      ],
    ),
  );
  if (report != true || !context.mounted) {
    return;
  }
  await showReportUserSheet(
    context: context,
    onSubmit: ({required reason, description}) => ref
        .read(safetyActionsProvider)
        .reportUser(
          reportedUserId: plan.partnerUserId,
          reason: reason,
          description: description,
        ),
  );
}
