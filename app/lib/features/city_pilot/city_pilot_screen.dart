import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';

final cityPilotProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  ref.watch(authNotifierProvider.select((a) => a.userId));
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/city-pilot');
  return (response.data as Map).cast<String, dynamic>();
});

class CityPilotScreen extends ConsumerStatefulWidget {
  const CityPilotScreen({super.key});
  @override
  ConsumerState<CityPilotScreen> createState() => _CityPilotScreenState();
}

class _CityPilotScreenState extends ConsumerState<CityPilotScreen> {
  bool _consent = false, _busy = false;
  String? _error, _notice;

  Future<void> _save(Future<void> Function(Dio) action, String notice) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(ref.read(apiClientProvider));
      if (!mounted) return;
      ref.invalidate(cityPilotProvider);
      setState(() {
        _notice = notice;
        _consent = false;
      });
    } on Object catch (e) {
      if (mounted)
        setState(
          () => _error = apiErrorMessage(
            e,
            fallback:
                'We couldn’t confirm that change. Refresh to check before trying again.',
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the city pilot?'),
        content: const Text(
          'Your pilot bookings will be cancelled and experience feedback removed. Your activity will stop contributing to current pilot results. Your matches and conversations stay. You cannot rejoin this pilot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay in pilot'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave pilot'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _save((dio) async {
        await dio.delete<dynamic>(
          '/city-pilot/membership',
          data: {'pilot_id': id},
        );
      }, 'You have left the pilot. Your matches stay with you.');
    }
  }

  Future<void> _book(Map<String, dynamic> event) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${event['title']}?'),
        content: SingleChildScrollView(
          child: Text(
            'This experience is free. Meet at the public venue, respect other people’s boundaries, and arrange your own travel. You can leave at any time.\n\nHost: ${event['host']}\nSafety contact: ${event['safety_contact']}\n\nAccessibility: ${event['accessibility']}\n\nFor immediate danger, contact local emergency services.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept & reserve a place'),
          ),
        ],
      ),
    );
    if (accepted == true)
      await _save((dio) async {
        await dio.post<dynamic>(
          '/city-pilot/events/${event['id']}/registration',
          data: {'safety_terms_accepted': true},
        );
      }, 'Your place is reserved. You can cancel here at any time.');
  }

  Future<void> _feedback(Map<String, dynamic> event) async {
    bool? attended, worthwhile;
    final answers = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('How was the experience?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Optional. Answers contribute to the pilot’s combined results. They aren’t shown to other members or the host.',
                ),
                const SizedBox(height: 16),
                const Text('Did you attend?'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in [true, false])
                      ChoiceChip(
                        label: Text(
                          value ? 'Yes, I went' : 'I couldn’t make it',
                        ),
                        selected: attended == value,
                        onSelected: (_) => update(() {
                          attended = value;
                          worthwhile = null;
                        }),
                      ),
                  ],
                ),
                if (attended == true) ...[
                  const SizedBox(height: 16),
                  const Text('Was it worth your time? (optional)'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in [true, false])
                        ChoiceChip(
                          label: Text(value ? 'Yes' : 'Not this time'),
                          selected: worthwhile == value,
                          onSelected: (selected) => update(
                            () => worthwhile = selected ? value : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: attended == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'attended': attended,
                      'worthwhile': worthwhile,
                    }),
              child: const Text('Share feedback'),
            ),
          ],
        ),
      ),
    );
    if (answers != null)
      await _save((dio) async {
        await dio.post<dynamic>(
          '/city-pilot/events/${event['id']}/feedback',
          data: answers,
        );
      }, 'Thank you. Your feedback has been recorded privately.');
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null
        ? 'Time to be confirmed'
        : DateFormat('EEE, d MMM · h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cityPilotProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('The city pilot'),
        actions: [
          IconButton(
            tooltip: 'Refresh pilot',
            onPressed: _busy ? null : () => ref.invalidate(cityPilotProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      size: 36,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'A little closer.\nA lot more real.',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'One city. A small community. More chances for a conversation to become a plan.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _step(
                '01',
                'Start with a conversation',
                'Meet at your pace through your existing introductions.',
              ),
              _step(
                '02',
                'Make room for a real date',
                'Shape a plan together. Share how it went only if you want to.',
              ),
              _step(
                '03',
                'Try something together',
                'Small, hosted experiences come after the first pilot review.',
              ),
              if (_busy)
                const LinearProgressIndicator(
                  semanticsLabel: 'Saving pilot preference',
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: colors.error)),
                  ),
                ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_notice!)),
                ),
              const SizedBox(height: 12),
              state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _panel('Your pilot is unavailable', [
                  const Text(
                    'Check your connection and refresh to see your latest participation and bookings.',
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(cityPilotProvider),
                    child: const Text('Try again'),
                  ),
                ]),
                data: (data) {
                  final pilot = (data['pilot'] as Map?)
                      ?.cast<String, dynamic>();
                  final joined = data['membership'] == 'joined';
                  if (pilot == null)
                    return _panel('Coming to a city near you', [
                      const Text(
                        'There isn’t an open pilot for your profile city yet. When one opens, you can choose whether to take part. Your current dating experience carries on as usual.',
                      ),
                    ]);
                  final events = ((data['experiences'] as List?) ?? [])
                      .map((e) => (e as Map).cast<String, dynamic>())
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panel(
                        '${pilot['city']} · ${joined ? 'You’re part of it' : 'City pilot'}',
                        [
                          Text(
                            'Recruitment closes ${_date(pilot['closes_at'])} (your local time).',
                          ),
                          const SizedBox(height: 12),
                          if (pilot['status'] == 'paused' ||
                              pilot['enabled'] == false)
                            const Text(
                              'New participation and bookings are paused. You can still leave or cancel.',
                            ),
                          if (pilot['status'] == 'completed')
                            const Text(
                              'This pilot is complete. Thank you for being part of it.',
                            ),
                          const Text(
                            'Joining lets us count conversations, accepted plans and optional “did the date happen?” answers for new matches where both people joined this pilot. We use 7-day conversation and 28-day date windows. We don’t read message text or private feedback notes for the pilot.',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Participation stays private. There’s no public attendance list or dating score. Leaving excludes your activity from current pilot results and cancels pilot bookings. Previously reviewed combined results cannot be un-seen.',
                          ),
                          if (data['can_join'] == true) ...[
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'I agree to take part in this pilot and its outcome measurement.',
                              ),
                              value: _consent,
                              onChanged: _busy
                                  ? null
                                  : (v) =>
                                        setState(() => _consent = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            FilledButton.icon(
                              onPressed: _busy || !_consent
                                  ? null
                                  : () => _save(
                                      (dio) async {
                                        await dio.post<dynamic>(
                                          '/city-pilot/membership',
                                          data: {
                                            'pilot_id': pilot['id'],
                                            'consent_version': 'city-pilot-v1',
                                          },
                                        );
                                      },
                                      'You’re in. Keep meeting people at your own pace.',
                                    ),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Join the city pilot'),
                            ),
                          ] else if (joined) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _leave(pilot['id'] as String),
                              child: const Text('Leave pilot'),
                            ),
                          ] else if (data['membership'] == 'withdrawn')
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'You’ve left this pilot. Your matches and conversations are unchanged.',
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'This pilot is not accepting new members right now.',
                              ),
                            ),
                        ],
                      ),
                      if (joined) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Small plans. Shared experiences.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (events.isEmpty)
                          const Text(
                            'Hosted experiences aren’t open yet. They’ll appear here after an outcome and safety review.',
                          ),
                        for (final event in events)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _panel(event['title'] as String, [
                              Text(event['summary'] as String),
                              const SizedBox(height: 12),
                              Text(
                                '${_date(event['starts_at'])} → ${_date(event['ends_at'])}\nYour local time · Free\n${event['venue']}\nHosted by ${event['host']}',
                              ),
                              const SizedBox(height: 12),
                              Text('Accessibility · ${event['accessibility']}'),
                              Text(
                                'Safety contact · ${event['safety_contact']}',
                              ),
                              if (event['status'] == 'cancelled')
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'This experience has been cancelled. Please do not travel to the venue.',
                                  ),
                                ),
                              if (event['registration'] == 'registered' &&
                                  event['status'] != 'cancelled') ...[
                                const SizedBox(height: 12),
                                const Text('Your place is reserved.'),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _save((dio) async {
                                          await dio.delete<dynamic>(
                                            '/city-pilot/events/${event['id']}/registration',
                                          );
                                        }, 'Your booking is cancelled.'),
                                  child: const Text('Cancel my place'),
                                ),
                              ] else if (event['can_register'] == true)
                                FilledButton(
                                  onPressed: _busy ? null : () => _book(event),
                                  child: const Text('Reserve a free place'),
                                ),
                              if (event['can_feedback'] == true)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _feedback(event),
                                  child: const Text('Share optional feedback'),
                                ),
                              if (event['feedback'] != null)
                                const Text(
                                  'Your feedback has been received. Thank you.',
                                ),
                            ]),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String title, String detail) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(number),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(detail),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _panel(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}
