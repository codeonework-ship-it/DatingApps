import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/api_client_provider.dart';
import '../../core/network/api_error_message.dart';
import '../auth/providers/auth_provider.dart';
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
    appBar: AppBar(title: const Text('Your dating rhythm')),
    body: ref
        .watch(datingRhythmProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load your preferences.'),
                TextButton(
                  onPressed: () => ref.invalidate(datingRhythmProvider),
                  child: const Text('Try again'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your dating rhythm is saved.')),
      );
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Unable to save. Your choices are still here.',
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final pause = ref.watch(discoveryPauseProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Make room for the way you date.',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose what fits your life. Availability and introductions are optional, and you can change your mind.',
            ),
            section('What are you open to?'),
            choices('intent', {
              '': 'Prefer not to say',
              'relationship': 'A relationship',
              'exploring': 'Finding my direction',
              'casual': 'Something casual',
            }),
            section('Your conversation pace'),
            choices('pace', {
              '': 'No preference',
              'slow': 'A little slower',
              'steady': 'A steady conversation',
              'frequent': 'Frequent conversation',
            }),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Slow replies this week'),
              subtitle: const Text('This status clears after seven days.'),
              value: draft['pace_status'] == 'slow_week',
              onChanged: saving
                  ? null
                  : (v) => setState(
                      () => draft['pace_status'] = v ? 'slow_week' : '',
                    ),
            ),
            toggle(
              'share_pace',
              'Share this status with my matches',
              'Only current matches can see your temporary status.',
            ),
            section('Your kind of first date'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in datingActivities.entries)
                  FilterChip(
                    label: Text(entry.value),
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
            const Text(
              'Choose up to five. Shared preferences help explain your introductions.',
            ),
            section('A little room in your week'),
            toggle(
              'share_availability',
              'Use my broad availability',
              'Only genuine overlap is shown. Your full schedule is private. Turning this off deletes saved windows.',
            ),
            if (flag('share_availability')) ...[
              const Text(
                'Tap any morning, afternoon or evening that suits you. Times use this device’s local time and expire automatically.',
              ),
              for (var day = 0; day < 7; day++) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  child: Text(
                    DateFormat(
                      'EEE, d MMM',
                    ).format(DateTime(now.year, now.month, now.day + day)),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in const {
                      'Morning': 9,
                      'Afternoon': 14,
                      'Evening': 18,
                    }.entries)
                      if (DateTime(
                        now.year,
                        now.month,
                        now.day + day,
                        slot.value + 3,
                      ).isAfter(now))
                        windowChip(
                          DateTime(
                            now.year,
                            now.month,
                            now.day + day,
                            slot.value,
                          ),
                          slot.key,
                        ),
                  ],
                ),
              ],
            ],
            section('Introductions with your permission'),
            toggle(
              'allow_friend_intros',
              'Allow introductions from accepted friends',
              'Both people must opt in. Your friend receives no match or decline updates. A preview includes your name and age.',
            ),
            if (flag('allow_friend_intros')) ...[
              toggle(
                'intro_share_photo',
                'Include my profile photos',
                'Only the person receiving an introduction can see them.',
              ),
              toggle(
                'intro_share_city',
                'Include my city',
                'Your exact location is never included.',
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
                child: const Text('Reload saved choices'),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('qa.rhythm.save'),
              onPressed: saving ? null : save,
              icon: Icon(saving ? Icons.hourglass_top : Icons.check),
              label: Text(saving ? 'Saving…' : 'Save my rhythm'),
            ),
            const Divider(height: 48),
            Text('A break is always okay.', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Pause new introductions whenever you need. Your existing conversations stay available.',
            ),
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
                      if (context.mounted && !ok)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(discoveryPauseProvider).error ??
                                  'Unable to update your pause.',
                            ),
                          ),
                        );
                    },
              icon: Icon(pause.paused ? Icons.play_arrow : Icons.pause),
              label: Text(
                pause.paused ? 'Resume introductions' : 'Pause introductions',
              ),
            ),
          ],
        ),
      ),
    );
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
