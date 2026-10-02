import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
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
            fallback: AppLocalizations.of(context).cityPilotSaveFailed,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cityPilotLeaveTitle),
        content: Text(l10n.cityPilotLeaveBody),
        actions: [
          TextButton(
            key: const ValueKey('qa.city_pilot.leave_stay'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cityPilotStay),
          ),
          FilledButton(
            key: const ValueKey('qa.city_pilot.leave_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cityPilotLeave),
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
      }, l10n.cityPilotLeftNotice);
    }
  }

  Future<void> _book(Map<String, dynamic> event) async {
    final l10n = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cityPilotJoinEventTitle('${event['title']}')),
        content: SingleChildScrollView(
          child: Text(
            l10n.cityPilotBookingTerms(
              '${event['host']}',
              '${event['safety_contact']}',
              '${event['accessibility']}',
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('qa.city_pilot.booking_not_now'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.debriefNotNow),
          ),
          FilledButton(
            key: const ValueKey('qa.city_pilot.booking_accept'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cityPilotAcceptReserve),
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
      }, l10n.cityPilotReservedNotice);
  }

  Future<void> _feedback(Map<String, dynamic> event) async {
    final l10n = AppLocalizations.of(context);
    bool? attended, worthwhile;
    final answers = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(l10n.cityPilotFeedbackTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.cityPilotFeedbackIntro),
                const SizedBox(height: 16),
                Text(l10n.cityPilotDidYouAttend),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in [true, false])
                      ChoiceChip(
                        key: ValueKey('qa.city_pilot.attended.$value'),
                        label: Text(
                          value
                              ? l10n.cityPilotAttendedYes
                              : l10n.cityPilotAttendedNo,
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
                  Text(l10n.cityPilotWorthwhileQuestion),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in [true, false])
                        ChoiceChip(
                          key: ValueKey('qa.city_pilot.worthwhile.$value'),
                          label: Text(
                            value ? l10n.commonYes : l10n.cityPilotNotThisTime,
                          ),
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
              key: const ValueKey('qa.city_pilot.feedback_skip'),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cityPilotSkip),
            ),
            FilledButton(
              key: const ValueKey('qa.city_pilot.feedback_share'),
              onPressed: attended == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'attended': attended,
                      'worthwhile': worthwhile,
                    }),
              child: Text(l10n.cityPilotShareFeedback),
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
      }, l10n.cityPilotFeedbackThanks);
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return AppLocalizations.of(context).cityPilotTimeTbc;
    }
    final locale = Localizations.localeOf(context);
    final localeName = locale.toString();
    final local = parsed.toLocal();
    // English keeps its original pattern; other languages use their own
    // weekday/day/month order and 12/24-hour clock.
    if (locale.languageCode == 'en') {
      return DateFormat('EEE, d MMM · h:mm a', localeName).format(local);
    }
    return '${DateFormat.MMMEd(localeName).format(local)} · '
        '${DateFormat.jm(localeName).format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cityPilotProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(l10n.cityPilotTitle),
        actions: [
          IconButton(
            key: const ValueKey('qa.city_pilot.refresh'),
            tooltip: l10n.cityPilotRefreshTooltip,
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
                      l10n.cityPilotHeroTitle,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.cityPilotHeroBody,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _step('01', l10n.cityPilotStep1Title, l10n.cityPilotStep1Body),
              _step('02', l10n.cityPilotStep2Title, l10n.cityPilotStep2Body),
              _step('03', l10n.cityPilotStep3Title, l10n.cityPilotStep3Body),
              if (_busy)
                LinearProgressIndicator(semanticsLabel: l10n.cityPilotSaving),
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
                error: (_, _) => _panel(l10n.cityPilotUnavailableTitle, [
                  Text(l10n.cityPilotUnavailableBody),
                  TextButton(
                    key: const ValueKey('qa.city_pilot.retry'),
                    onPressed: () => ref.invalidate(cityPilotProvider),
                    child: Text(l10n.chatTryAgain),
                  ),
                ]),
                data: (data) {
                  final pilot = (data['pilot'] as Map?)
                      ?.cast<String, dynamic>();
                  final joined = data['membership'] == 'joined';
                  if (pilot == null)
                    return _panel(l10n.cityPilotComingSoonTitle, [
                      Text(l10n.cityPilotComingSoonBody),
                    ]);
                  final events = ((data['experiences'] as List?) ?? [])
                      .map((e) => (e as Map).cast<String, dynamic>())
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panel(
                        joined
                            ? l10n.cityPilotPanelTitleJoined('${pilot['city']}')
                            : l10n.cityPilotPanelTitleOpen('${pilot['city']}'),
                        [
                          Text(
                            l10n.cityPilotRecruitmentCloses(
                              _date(pilot['closes_at']),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (pilot['status'] == 'paused' ||
                              pilot['enabled'] == false)
                            Text(l10n.cityPilotPaused),
                          if (pilot['status'] == 'completed')
                            Text(l10n.cityPilotCompleted),
                          Text(l10n.cityPilotMeasurement),
                          const SizedBox(height: 12),
                          Text(l10n.cityPilotPrivacy),
                          if (data['can_join'] == true) ...[
                            CheckboxListTile(
                              key: const ValueKey('qa.city_pilot.consent'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.cityPilotConsent),
                              value: _consent,
                              onChanged: _busy
                                  ? null
                                  : (v) =>
                                        setState(() => _consent = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            FilledButton.icon(
                              key: const ValueKey('qa.city_pilot.join'),
                              onPressed: _busy || !_consent
                                  ? null
                                  : () => _save((dio) async {
                                      await dio.post<dynamic>(
                                        '/city-pilot/membership',
                                        data: {
                                          'pilot_id': pilot['id'],
                                          'consent_version': 'city-pilot-v1',
                                        },
                                      );
                                    }, l10n.cityPilotJoinedNotice),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(l10n.cityPilotJoin),
                            ),
                          ] else if (joined) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              key: const ValueKey('qa.city_pilot.leave'),
                              onPressed: _busy
                                  ? null
                                  : () => _leave(pilot['id'] as String),
                              child: Text(l10n.cityPilotLeave),
                            ),
                          ] else if (data['membership'] == 'withdrawn')
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(l10n.cityPilotWithdrawn),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(l10n.cityPilotNotAccepting),
                            ),
                        ],
                      ),
                      if (joined) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.cityPilotExperiencesHeading,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (events.isEmpty) Text(l10n.cityPilotNoExperiences),
                        for (final event in events)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _panel(event['title'] as String, [
                              Text(event['summary'] as String),
                              const SizedBox(height: 12),
                              Text(
                                l10n.cityPilotEventDetails(
                                  _date(event['starts_at']),
                                  _date(event['ends_at']),
                                  '${event['venue']}',
                                  '${event['host']}',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.cityPilotAccessibility(
                                  '${event['accessibility']}',
                                ),
                              ),
                              Text(
                                l10n.cityPilotSafetyContact(
                                  '${event['safety_contact']}',
                                ),
                              ),
                              if (event['status'] == 'cancelled')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(l10n.cityPilotEventCancelled),
                                ),
                              if (event['registration'] == 'registered' &&
                                  event['status'] != 'cancelled') ...[
                                const SizedBox(height: 12),
                                Text(l10n.cityPilotPlaceReserved),
                                OutlinedButton(
                                  key: ValueKey(
                                    'qa.city_pilot.cancel.${event['id']}',
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => _save((dio) async {
                                          await dio.delete<dynamic>(
                                            '/city-pilot/events/${event['id']}/registration',
                                          );
                                        }, l10n.cityPilotBookingCancelled),
                                  child: Text(l10n.cityPilotCancelPlace),
                                ),
                              ] else if (event['can_register'] == true)
                                FilledButton(
                                  key: ValueKey(
                                    'qa.city_pilot.reserve.${event['id']}',
                                  ),
                                  onPressed: _busy ? null : () => _book(event),
                                  child: Text(l10n.cityPilotReserveFree),
                                ),
                              if (event['can_feedback'] == true)
                                TextButton(
                                  key: ValueKey(
                                    'qa.city_pilot.feedback.${event['id']}',
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => _feedback(event),
                                  child: Text(
                                    l10n.cityPilotShareOptionalFeedback,
                                  ),
                                ),
                              if (event['feedback'] != null)
                                Text(l10n.cityPilotFeedbackReceived),
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
