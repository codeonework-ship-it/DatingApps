import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/api_client_provider.dart';
import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../graduation/models/graduation_labels.dart';
import '../graduation/providers/graduation_provider.dart';
import '../swipe/providers/curated_daily_set_provider.dart';
import '../friends/providers/friend_social_provider.dart';

const datingActivities = <String, String>{
  'coffee': 'Coffee',
  'walk': 'A daytime walk',
  'meal': 'A meal',
  'activity': 'Something playful',
  'event': 'An event',
  'video_call': 'A video hello',
  'drinks': 'Drinks',
  'other': 'Something else',
};
const datingBudgets = <String, String>{
  'flexible': 'Let’s decide together',
  'free': 'Keep it free',
  'modest': 'Keep it modest',
  'treat': 'A little treat',
};

/// The localized label for a first-date activity id ([datingActivities]
/// keys); an unknown id is shown as is.
String datingActivityLabel(AppLocalizations l10n, String id) => switch (id) {
  'coffee' => l10n.todayActivityCoffee,
  'walk' => l10n.todayActivityWalk,
  'meal' => l10n.todayActivityMeal,
  'activity' => l10n.todayActivityPlayful,
  'event' => l10n.todayActivityEvent,
  'video_call' => l10n.todayActivityVideoCall,
  'drinks' => l10n.todayActivityDrinks,
  'other' => l10n.todayActivityOther,
  _ => id,
};

/// The localized label for a date budget id ([datingBudgets] keys); an
/// unknown id falls back to "Let’s decide together".
String datingBudgetLabel(AppLocalizations l10n, String? id) => switch (id) {
  'free' => l10n.todayBudgetFree,
  'modest' => l10n.todayBudgetModest,
  'treat' => l10n.todayBudgetTreat,
  _ => l10n.todayBudgetFlexible,
};

final datingRhythmProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider).userId;
  if (user == null) return {};
  final response = await ref
      .read(apiClientProvider)
      .get<dynamic>('/account/$user/dating-preferences');
  return ((response.data as Map?)?['preferences'] as Map?)
          ?.cast<String, dynamic>() ??
      {};
});

Future<void> openDatingRhythm(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const DatingRhythmScreen()));

class DatingRhythmScreen extends ConsumerWidget {
  const DatingRhythmScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).todayRhythmTitle)),
    body: ref
        .watch(datingRhythmProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).todayRhythmLoadFailed),
                TextButton(
                  onPressed: () => ref.invalidate(datingRhythmProvider),
                  child: Text(AppLocalizations.of(context).todayTryAgain),
                ),
              ],
            ),
          ),
          data: (data) =>
              _RhythmEditor(key: ValueKey(data['version']), initial: data),
        ),
  );
}

class _RhythmEditor extends ConsumerStatefulWidget {
  const _RhythmEditor({super.key, required this.initial});
  final Map<String, dynamic> initial;
  @override
  ConsumerState<_RhythmEditor> createState() => _RhythmEditorState();
}

class _RhythmEditorState extends ConsumerState<_RhythmEditor> {
  late Map<String, dynamic> draft;
  late Set<String> activities;
  late Map<String, Map<String, String>> windows;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    draft = Map.of(widget.initial);
    activities = (draft['activities'] as List? ?? []).cast<String>().toSet();
    windows = {};
    for (final raw in draft['availability'] as List? ?? []) {
      final row = (raw as Map).cast<String, dynamic>();
      final start = DateTime.tryParse(row['start'] as String? ?? '');
      if (start != null) {
        windows[start.toUtc().toIso8601String()] = {
          'start': start.toUtc().toIso8601String(),
          'end': row['end'].toString(),
        };
      }
    }
  }

  bool flag(String key) => draft[key] == true;
  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final user = ref.read(authNotifierProvider).userId;
      final data = <String, dynamic>{
        ...draft,
        'activities': activities.toList(),
        'availability': flag('share_availability')
            ? windows.values.toList()
            : <dynamic>[],
        'version': draft['version'] ?? 0,
      };
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>('/account/$user/dating-preferences', data: data);
      draft = ((response.data as Map)['preferences'] as Map)
          .cast<String, dynamic>();
      ref.invalidate(curatedDailySetProvider);
      ref.invalidate(friendSocialProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.todayRhythmSaved)));
    } catch (e) {
      if (mounted)
        setState(
          () =>
              error = apiErrorMessage(e, fallback: l10n.todayRhythmSaveFailed),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final pause = ref.watch(discoveryPauseProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              l10n.todayRhythmHeadline,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(l10n.todayRhythmIntro),
            section(l10n.todayRhythmOpenTo),
            choices('intent', {
              '': l10n.todayRhythmIntentNone,
              'relationship': l10n.todayRhythmIntentRelationship,
              'exploring': l10n.todayRhythmIntentExploring,
              'casual': l10n.todayRhythmIntentCasual,
            }),
            section(l10n.todayRhythmPaceSection),
            choices('pace', {
              '': l10n.todayRhythmPaceNone,
              'slow': l10n.todayRhythmPaceSlow,
              'steady': l10n.todayRhythmPaceSteady,
              'frequent': l10n.todayRhythmPaceFrequent,
            }),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.todayRhythmSlowWeek),
              subtitle: Text(l10n.todayRhythmSlowWeekHint),
              value: draft['pace_status'] == 'slow_week',
              onChanged: saving
                  ? null
                  : (v) => setState(
                      () => draft['pace_status'] = v ? 'slow_week' : '',
                    ),
            ),
            toggle(
              'share_pace',
              l10n.todayRhythmSharePace,
              l10n.todayRhythmSharePaceHint,
            ),
            section(l10n.todayRhythmFirstDate),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in datingActivities.entries)
                  FilterChip(
                    label: Text(datingActivityLabel(l10n, entry.key)),
                    selected: activities.contains(entry.key),
                    onSelected: saving
                        ? null
                        : (v) => setState(() {
                            if (v && activities.length < 5) {
                              activities.add(entry.key);
                            } else if (!v) {
                              activities.remove(entry.key);
                            }
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.todayRhythmChooseFive),
            section(l10n.todayRhythmWeekSection),
            toggle(
              'share_availability',
              l10n.todayRhythmShareAvailability,
              l10n.todayRhythmShareAvailabilityHint,
            ),
            if (flag('share_availability')) ...[
              Text(l10n.todayRhythmAvailabilityHint),
              for (var day = 0; day < 7; day++) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  child: Text(
                    _dayLabel(
                      locale,
                      DateTime(now.year, now.month, now.day + day),
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in [
                      (label: l10n.todayRhythmMorning, hour: 9),
                      (label: l10n.todayRhythmAfternoon, hour: 14),
                      (label: l10n.todayRhythmEvening, hour: 18),
                    ])
                      if (DateTime(
                        now.year,
                        now.month,
                        now.day + day,
                        slot.hour + 3,
                      ).isAfter(now))
                        windowChip(
                          DateTime(
                            now.year,
                            now.month,
                            now.day + day,
                            slot.hour,
                          ),
                          slot.label,
                        ),
                  ],
                ),
              ],
            ],
            section(l10n.todayRhythmIntrosSection),
            toggle(
              'allow_friend_intros',
              l10n.todayRhythmFriendIntros,
              l10n.todayRhythmFriendIntrosHint,
            ),
            if (flag('allow_friend_intros')) ...[
              toggle(
                'intro_share_photo',
                l10n.todayRhythmIntroPhoto,
                l10n.todayRhythmIntroPhotoHint,
              ),
              toggle(
                'intro_share_city',
                l10n.todayRhythmIntroCity,
                l10n.todayRhythmIntroCityHint,
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (error != null)
              TextButton(
                onPressed: saving
                    ? null
                    : () => ref.invalidate(datingRhythmProvider),
                child: Text(l10n.todayRhythmReload),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('qa.rhythm.save'),
              onPressed: saving ? null : save,
              icon: Icon(saving ? Icons.hourglass_top : Icons.check),
              label: Text(
                saving ? l10n.todayRhythmSaving : l10n.todayRhythmSave,
              ),
            ),
            const Divider(height: 48),
            Text(l10n.todayRhythmBreakTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.todayRhythmBreakBody),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: pause.isMutating
                  ? null
                  : () async {
                      final notifier = ref.read(
                        discoveryPauseProvider.notifier,
                      );
                      final ok = pause.paused
                          ? await notifier.resumeDiscovery()
                          : await notifier.pauseDiscovery();
                      if (context.mounted && !ok) {
                        final failed = ref.read(discoveryPauseProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              failed.error == null
                                  ? l10n.todayRhythmPauseFailed
                                  : localizedGraduationError(
                                      l10n,
                                      failed.error!,
                                      failed.failure,
                                    ),
                            ),
                          ),
                        );
                      }
                    },
              icon: Icon(pause.paused ? Icons.play_arrow : Icons.pause),
              label: Text(
                pause.paused ? l10n.todayRhythmResume : l10n.todayRhythmPause,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Fri, 2 Oct" in English and the locale's own short form elsewhere
  /// ("Fr., 2. Okt."), falling back to English when date symbols for that
  /// locale are not loaded.
  static String _dayLabel(Locale locale, DateTime day) {
    try {
      if (locale.languageCode == 'en') {
        return DateFormat('EEE, d MMM', locale.toLanguageTag()).format(day);
      }
      return DateFormat.MMMEd(locale.toLanguageTag()).format(day);
    } on Object {
      return DateFormat('EEE, d MMM', 'en').format(day);
    }
  }

  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget choices(String key, Map<String, String> labels) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in labels.entries)
        ChoiceChip(
          label: Text(entry.value),
          selected: (draft[key] ?? '') == entry.key,
          onSelected: saving
              ? null
              : (_) => setState(() => draft[key] = entry.key),
        ),
    ],
  );
  Widget toggle(String key, String title, String subtitle) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        value: flag(key),
        onChanged: saving ? null : (v) => setState(() => draft[key] = v),
      );
  Widget windowChip(DateTime start, String label) {
    final key = start.toUtc().toIso8601String();
    return FilterChip(
      label: Text(label),
      selected: windows.containsKey(key),
      onSelected: saving
          ? null
          : (v) => setState(() {
              if (v) {
                windows[key] = {
                  'start': key,
                  'end': start
                      .add(const Duration(hours: 3))
                      .toUtc()
                      .toIso8601String(),
                };
              } else {
                windows.remove(key);
              }
            }),
    );
  }
}
