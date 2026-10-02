import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/date_plan.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../../intentional_dating/connection_card.dart';
import '../models/date_plan_labels.dart';
import '../providers/plans_provider.dart';
import '../widgets/plan_preferences_summary.dart';

/// Opens the propose sheet for a match. Resolves to the created plan, or null
/// when the member backed out or the request failed (the error is shown
/// inside the sheet).
Future<DatePlan?> showProposeDatePlanSheet({
  required BuildContext context,
  required String matchId,
  required String partnerName,
  DatePlan? counterTo,
  String? initialNote,
  String? initialVenueCategory,
  String? sourceBlogResponseId,
}) => showModalBottomSheet<DatePlan?>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 760),
  builder: (_) => _ProposeDatePlanSheet(
    matchId: matchId,
    partnerName: partnerName,
    counterTo: counterTo,
    initialNote: initialNote,
    sourceBlogResponseId: sourceBlogResponseId,
    initialVenueCategory: initialVenueCategory,
  ),
);

/// Lets the invitee pick which of their groups hear about an accepted plan.
/// Resolves to the chosen group ids, or null when they backed out.
Future<List<String>?> showAcceptDatePlanSheet({
  required BuildContext context,
  required DatePlan plan,
  required List<DatePlanShareGroup> groups,
}) => showModalBottomSheet<List<String>?>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 760),
  builder: (_) => _AcceptDatePlanSheet(plan: plan, groups: groups),
);

class _ProposeDatePlanSheet extends ConsumerStatefulWidget {
  const _ProposeDatePlanSheet({
    required this.matchId,
    required this.partnerName,
    this.counterTo,
    this.initialNote,
    this.initialVenueCategory,
    this.sourceBlogResponseId,
  });

  final String matchId;
  final String partnerName;
  final DatePlan? counterTo;
  final String? initialNote, initialVenueCategory, sourceBlogResponseId;

  @override
  ConsumerState<_ProposeDatePlanSheet> createState() =>
      _ProposeDatePlanSheetState();
}

class _ProposeDatePlanSheetState extends ConsumerState<_ProposeDatePlanSheet> {
  late DateTime _start, _end;
  DateTimeRange? _sharedWindow;
  DatePlan? _counterTo;
  String _venueCategory = 'coffee', _budget = 'flexible';
  final _atmospheres = <String>{}, _accessibility = <String>{};
  final _venueName = TextEditingController(),
      _venueArea = TextEditingController(),
      _note = TextEditingController();
  bool _submitting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18);
    _end = _start.add(const Duration(hours: 2));
    _note.text = widget.initialNote ?? '';
    _venueCategory = widget.initialVenueCategory ?? 'coffee';
    if (widget.counterTo != null) _applyPlan(widget.counterTo!);
  }

  void _applyPlan(DatePlan p) {
    _counterTo = p;
    _start = p.windowStart.toLocal();
    _end = p.windowEnd.toLocal();
    _sharedWindow = null;
    _venueCategory = p.venueCategory;
    _budget = p.budgetPreference;
    _venueName.text = p.venueName;
    _venueArea.text = p.venueArea;
    _note.text = p.note;
    _atmospheres
      ..clear()
      ..addAll(p.atmospherePreferences);
    _accessibility
      ..clear()
      ..addAll(p.accessibilityPreferences);
  }

  @override
  void dispose() {
    _venueName.dispose();
    _venueArea.dispose();
    _note.dispose();
    super.dispose();
  }

  void _changeStart(DateTime start) {
    final duration = _end.difference(_start);
    setState(() {
      _start = start;
      _end = start.add(duration);
      _sharedWindow = null;
    });
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 90));
    final initial = _start.isBefore(first)
        ? first
        : _start.isAfter(last)
        ? last
        : _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted)
      _changeStart(
        DateTime(
          picked.year,
          picked.month,
          picked.day,
          _start.hour,
          _start.minute,
        ),
      );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (picked != null && mounted)
      _changeStart(
        DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        ),
      );
  }

  Future<void> _submit() async {
    if (!_start.isAfter(DateTime.now())) {
      setState(() => _error = AppLocalizations.of(context).planFutureTimeError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final plan = await ref
        .read(matchPlansProvider(widget.matchId).notifier)
        .propose(
          counterTo: _counterTo,
          sourceBlogResponseId: widget.sourceBlogResponseId,
          budgetPreference: _budget,
          atmospherePreferences: _atmospheres.toList(),
          accessibilityPreferences: _accessibility.toList(),
          sharedWindow: _sharedWindow == null
              ? null
              : {
                  'start': _sharedWindow!.start.toUtc().toIso8601String(),
                  'end': _sharedWindow!.end.toUtc().toIso8601String(),
                },
          windowStart: _start,
          windowEnd: _end,
          venueCategory: _venueCategory,
          venueName: _venueName.text,
          venueArea: _venueArea.text,
          note: _note.text,
        );
    if (!mounted) return;
    if (plan == null) {
      final l10n = AppLocalizations.of(context);
      final state = ref.read(matchPlansProvider(widget.matchId));
      setState(() {
        _submitting = false;
        _error = state.error == null
            ? l10n.planProposeErrorKept
            : localizedDatePlanError(l10n, state.error!, state.failure);
      });
      return;
    }
    Navigator.of(context).pop(plan);
  }

  Future<void> _reloadPlan() async {
    setState(() => _submitting = true);
    await ref.read(matchPlansProvider(widget.matchId).notifier).load();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(matchPlansProvider(widget.matchId));
    final plan = state.plan;
    setState(() {
      _submitting = false;
      if (state.error != null) {
        _error = localizedDatePlanError(l10n, state.error!, state.failure);
      } else if (plan == null || plan.nextAction != 'decide') {
        _error = l10n.planChangedError;
      } else {
        _applyPlan(plan);
        _error = null;
      }
    });
  }

  List<DateTimeRange> _windows(Map<String, dynamic>? data) {
    final now = DateTime.now();
    final result = <DateTimeRange>[];
    for (final raw in data?['overlap'] as List? ?? <dynamic>[]) {
      if (raw is! Map) continue;
      var start = DateTime.tryParse(raw['start'].toString())?.toLocal();
      final end = DateTime.tryParse(raw['end'].toString())?.toLocal();
      if (start == null || end == null) continue;
      if (!start.isAfter(now))
        start = DateTime.fromMillisecondsSinceEpoch(
          ((now.millisecondsSinceEpoch ~/ 900000) + 1) * 900000,
        );
      if (end.difference(start).inMinutes < 30) continue;
      result.add(DateTimeRange(start: start, end: end));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final connection = ref.watch(datingConnectionProvider(widget.matchId));
    final windows = connection.hasError
        ? <DateTimeRange>[]
        : _windows(connection.valueOrNull);
    final duration = _end.difference(_start).inMinutes;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _counterTo == null
                  ? l10n.planProposeHeadline
                  : l10n.planCounterHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: AppTheme.displayFamily,
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.planProposeLead(widget.partnerName)),
            const SizedBox(height: 20),
            _panel(
              context,
              title: l10n.planFindTimeTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.planFindTimeBody),
                  const SizedBox(height: 10),
                  if (connection.isLoading && !connection.hasValue)
                    const LinearProgressIndicator()
                  else if (connection.hasError)
                    Text(l10n.planSharedTimesFailed)
                  else if (windows.isEmpty)
                    Text(l10n.planSharedTimesEmpty),
                  if (windows.isNotEmpty) ...[
                    for (var i = 0; i < windows.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          key: ValueKey('qa.plan.overlap.$i'),
                          onPressed: _submitting
                              ? null
                              : () => setState(() {
                                  _start = windows[i].start;
                                  _end = windows[i].end;
                                  _sharedWindow = windows[i];
                                }),
                          icon: Icon(
                            _sharedWindow == windows[i]
                                ? Icons.check_circle_outline
                                : Icons.schedule_outlined,
                          ),
                          label: Text(
                            describeDatePlanWindow(
                              windows[i].start,
                              windows[i].end,
                              locale: locale,
                            ),
                          ),
                        ),
                      ),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => ref.invalidate(
                                datingConnectionProvider(widget.matchId),
                              ),
                        child: Text(l10n.planRefreshSharedTimes),
                      ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                await openDatingRhythm(context);
                                if (mounted)
                                  ref.invalidate(
                                    datingConnectionProvider(widget.matchId),
                                  );
                              },
                        child: Text(l10n.planSetAvailability),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _panel(
              context,
              title: l10n.planWhenTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sharedWindow == null
                        ? l10n.planTimeSourceManual
                        : l10n.planTimeSourceShared,
                    key: const ValueKey('qa.plan.time_source'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        key: const ValueKey('qa.plan.pick_day'),
                        avatar: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(
                          describeDatePlanDay(_start, locale: locale),
                        ),
                        onPressed: _submitting ? null : _pickDay,
                      ),
                      ActionChip(
                        key: const ValueKey('qa.plan.pick_time'),
                        avatar: const Icon(Icons.schedule_outlined, size: 18),
                        label: Text(
                          '${describeDatePlanTime(_start)}–${describeDatePlanTime(_end)}',
                        ),
                        onPressed: _submitting ? null : _pickTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.planLocalTimeNote(duration, _start.timeZoneName)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final minutes in const [30, 60, 90, 120, 180])
                        ChoiceChip(
                          key: ValueKey('qa.plan.duration.$minutes'),
                          label: Text(l10n.planDurationChip(minutes)),
                          selected: duration == minutes,
                          onSelected: _submitting
                              ? null
                              : (_) => setState(() {
                                  _end = _start.add(Duration(minutes: minutes));
                                  if (_sharedWindow != null &&
                                      _end.isAfter(_sharedWindow!.end))
                                    _sharedWindow = null;
                                }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _panel(
              context,
              title: l10n.planEnjoyTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in datePlanVenueOrder)
                        ChoiceChip(
                          key: ValueKey('qa.plan.venue.$category'),
                          label: Text(datePlanVenueLabel(l10n, category)),
                          selected: _venueCategory == category,
                          onSelected: _submitting
                              ? null
                              : (_) =>
                                    setState(() => _venueCategory = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('qa.plan.venue_name'),
                    controller: _venueName,
                    enabled: !_submitting,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.planPlaceLabel,
                      hintText: l10n.planPlaceHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('qa.plan.venue_area'),
                    controller: _venueArea,
                    enabled: !_submitting,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.planAreaLabel,
                      hintText: l10n.planAreaHint,
                    ),
                  ),
                ],
              ),
            ),
            _panel(
              context,
              title: l10n.planBudgetTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.planBudgetBody),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in datingBudgets.entries)
                        ChoiceChip(
                          key: ValueKey('qa.plan.budget.${b.key}'),
                          label: Text(datingBudgetLabel(l10n, b.key)),
                          selected: _budget == b.key,
                          onSelected: _submitting
                              ? null
                              : (_) => setState(() => _budget = b.key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _panel(
              context,
              title: l10n.planAtmosphereTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.planAtmosphereBody),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in planAtmospheres.entries)
                        FilterChip(
                          key: ValueKey('qa.plan.atmosphere.${a.key}'),
                          label: Text(
                            planAtmosphereLabel(l10n, a.key) ?? a.value,
                          ),
                          selected: _atmospheres.contains(a.key),
                          onSelected:
                              _submitting ||
                                  (!_atmospheres.contains(a.key) &&
                                      _atmospheres.length >= 3)
                              ? null
                              : (v) => setState(() {
                                  v
                                      ? _atmospheres.add(a.key)
                                      : _atmospheres.remove(a.key);
                                }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _panel(
              context,
              title: l10n.planComfortTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.planComfortBody),
                  const SizedBox(height: 12),
                  for (final a in planAccessibility.entries)
                    CheckboxListTile(
                      key: ValueKey('qa.plan.accessibility.${a.key}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        planAccessibilityLabel(l10n, a.key) ?? a.value,
                      ),
                      value: _accessibility.contains(a.key),
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() {
                              v == true
                                  ? _accessibility.add(a.key)
                                  : _accessibility.remove(a.key);
                            }),
                    ),
                  Text(l10n.planComfortDisclaimer),
                ],
              ),
            ),
            TextField(
              key: const ValueKey('qa.plan.note'),
              controller: _note,
              enabled: !_submitting,
              maxLength: 280,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.planNoteLabel,
                hintText: l10n.planNoteHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.planReviewBeforeSending),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('qa.plan.error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
              if (_counterTo != null)
                TextButton(
                  onPressed: _submitting ? null : _reloadPlan,
                  child: Text(l10n.planReloadLatest),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('qa.plan.submit'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _submitting
                      ? l10n.planSending
                      : _counterTo == null
                      ? l10n.planSendButton
                      : l10n.planSendSuggestion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _AcceptDatePlanSheet extends StatefulWidget {
  const _AcceptDatePlanSheet({required this.plan, required this.groups});

  final DatePlan plan;
  final List<DatePlanShareGroup> groups;

  @override
  State<_AcceptDatePlanSheet> createState() => _AcceptDatePlanSheetState();
}

class _AcceptDatePlanSheetState extends State<_AcceptDatePlanSheet> {
  final Set<String> _groupIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.planAcceptTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            widget.plan.localizedSummary(l10n, locale: localeName),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppLayout.space3),
          PlanPreferencesSummary(plan: widget.plan),
          const SizedBox(height: 12),
          Text(
            l10n.planAcceptIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.groups.isNotEmpty) ...[
            const SizedBox(height: AppLayout.space3),
            Wrap(
              spacing: AppLayout.space2,
              runSpacing: AppLayout.space2,
              children: [
                for (final group in widget.groups)
                  FilterChip(
                    label: Text(group.name),
                    selected: _groupIds.contains(group.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _groupIds.add(group.id);
                      } else {
                        _groupIds.remove(group.id);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppLayout.space5),
          SizedBox(
            width: double.infinity,
            height: AppLayout.minTapTarget,
            child: FilledButton.icon(
              key: const ValueKey('qa.plan.accept_confirm'),
              onPressed: () => Navigator.of(context).pop(_groupIds.toList()),
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.planAcceptButton),
            ),
          ),
        ],
      ),
    );
  }
}
