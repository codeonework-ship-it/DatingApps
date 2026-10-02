// Shared fixture for the date-plan control tests: one match ("match-1")
// between the signed-in member ("me") and Arjun, served by the recording
// fake BFF from test/support/qa_api.dart. The fake keeps server state so a
// command changes what the next GET returns, like the real BFF does.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/qa_api.dart';

const matchId = 'match-1';
const partnerId = 'arjun';
const partnerName = 'Arjun';

/// A future start: local [hour]:00, [days] from today.
DateTime planStart({int days = 3, int hour = 16}) {
  final day = DateTime.now().add(Duration(days: days));
  return DateTime(day.year, day.month, day.day, hour);
}

String iso(DateTime value) => value.toUtc().toIso8601String();

Map<String, dynamic> planJson({
  String id = 'plan-1',
  String status = 'proposed',
  String nextAction = 'decide',
  String viewerRole = 'invitee',
  DateTime? start,
  int minutes = 120,
  String venueCategory = 'coffee',
  String venueName = '',
  String venueArea = 'Indiranagar',
  String note = 'Third Wave?',
  String budget = 'flexible',
  List<String> atmospheres = const [],
  List<String> accessibility = const [],
  int lockVersion = 4,
  List<Map<String, dynamic>> checkins = const [],
  Map<String, dynamic>? debrief,
  bool mutualSecondYes = false,
  int friendRecipients = 0,
}) {
  final from = start ?? planStart();
  final to = from.add(Duration(minutes: minutes));
  return {
    'id': id,
    'match_id': matchId,
    'proposer_user_id': viewerRole == 'proposer' ? 'me' : partnerId,
    'invitee_user_id': viewerRole == 'proposer' ? partnerId : 'me',
    'status': status,
    'window_start': iso(from),
    'window_end': iso(to),
    'venue_category': venueCategory,
    'venue_name': venueName,
    'venue_area': venueArea,
    'note': note,
    'checkin_due_at': iso(to.add(const Duration(hours: 1))),
    'viewer_role': viewerRole,
    'partner_user_id': partnerId,
    'partner_name': partnerName,
    'next_action': nextAction,
    'lock_version': lockVersion,
    'budget_preference': budget,
    'atmosphere_preferences': atmospheres,
    'accessibility_preferences': accessibility,
    'checkins': checkins,
    'debrief': ?debrief,
    'mutual_second_yes': mutualSecondYes,
    'friend_recipients': friendRecipients,
  };
}

Map<String, dynamic> friendPlanJson({
  String id = 'friend-plan-1',
  String friendName = 'Meera',
  String status = 'accepted',
  String latestUpdate = 'accepted',
  String title = 'Meera has a date with Dev',
}) {
  final from = planStart(days: 1, hour: 19);
  return {
    'plan_id': id,
    'friend_user_id': 'meera',
    'friend_name': friendName,
    'partner_name': 'Dev',
    'status': status,
    'latest_update': latestUpdate,
    'title': title,
    'description': 'Coffee · Koramangala',
    'window_start': iso(from),
    'window_end': iso(from.add(const Duration(hours: 2))),
    'venue_category': 'coffee',
    'venue_area': 'Koramangala',
    'via': 'friend',
    'updated_at': iso(DateTime.now()),
    'checkins': <dynamic>[],
  };
}

/// The server side of one match's plans, the member's feeds, contact
/// sharing and reports. Every request is recorded in [api].
class PlansWorld {
  PlansWorld({
    this.plan,
    List<Map<String, dynamic>>? history,
    this.canPropose = false,
    List<Map<String, dynamic>>? contacts,
    List<String>? sharedWith,
    List<Map<String, dynamic>>? mine,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? overlap,
  }) : history = history ?? [],
       contacts =
           contacts ??
           [
             {'id': 'meera', 'name': 'Meera'},
             {'id': 'dev', 'name': 'Dev'},
           ],
       sharedWith = sharedWith ?? [],
       mine = mine ?? [],
       friends = friends ?? [],
       overlap = overlap ?? [] {
    _install();
  }

  final api = QaApi();
  Map<String, dynamic>? plan;
  List<Map<String, dynamic>> history;
  bool canPropose;
  List<Map<String, dynamic>> contacts;
  List<String> sharedWith;
  int sharingVersion = 3;
  List<Map<String, dynamic>> mine;
  List<Map<String, dynamic>> friends;
  List<Map<String, dynamic>> overlap;

  Map<String, dynamic> get snapshot => {
    'match_id': matchId,
    'plan': plan,
    'history': history,
    'share_groups': <dynamic>[],
    'can_propose': canPropose,
    'unlock_state': 'conversation_unlocked',
  };

  /// Delay applied to every command (POST) reply, to observe the busy state.
  Duration? commandDelay;

  QaHandler _slow(QaHandler handler) => (call) {
    final reply = handler(call);
    return QaReply(
      reply.status,
      reply.body,
      offline: reply.offline,
      delay: commandDelay,
    );
  };

  /// (Re)installs every happy route, e.g. after a test failed one of them.
  /// The failure may have been set on the exact path, which would win over
  /// the happy `*` route, so every route is cleared first.
  void serve() {
    api.clearRoutes();
    _install();
  }

  void _install() {
    api
      ..on('GET /matches/$matchId/plans', (_) => qaOk(snapshot))
      ..on(
        'GET /matches/$matchId/connection',
        (_) => qaOk({'overlap': overlap}),
      )
      ..on('POST /matches/$matchId/plans', _slow((call) => _propose(call.body)))
      ..on(
        'POST /matches/$matchId/plans/*/counter',
        _slow((call) => _propose(call.body, counter: true)),
      )
      ..on(
        'POST /matches/$matchId/plans/*/decision',
        _slow((call) {
          final accept = call.body['decision'] == 'accept';
          final updated = {
            ...plan!,
            'status': accept ? 'accepted' : 'declined',
            'next_action': accept ? 'upcoming' : 'none',
            'lock_version': (plan!['lock_version'] as int) + 1,
          };
          if (accept) {
            plan = updated;
          } else {
            plan = null;
            history.insert(0, updated);
            canPropose = true;
          }
          return qaOk({'plan': updated});
        }),
      )
      ..on(
        'POST /matches/$matchId/plans/*/cancel',
        _slow((call) {
          final updated = {
            ...plan!,
            'status': 'cancelled',
            'next_action': 'none',
          };
          plan = null;
          history.insert(0, updated);
          canPropose = true;
          return qaOk({'plan': updated});
        }),
      )
      ..on(
        'POST /matches/$matchId/plans/*/checkin',
        _slow((call) {
          plan = {
            ...plan!,
            'next_action': 'none',
            'checkins': [
              {
                'user_id': 'me',
                'status': call.body['status'],
                'at': iso(DateTime.now()),
              },
            ],
          };
          return qaOk({'plan': plan});
        }),
      )
      ..on(
        'POST /matches/$matchId/plans/*/debrief',
        _slow((call) {
          plan = {
            ...plan!,
            'next_action': 'none',
            'debrief': {
              'happened': call.body['happened'],
              'would_meet_again': call.body['would_meet_again'],
              'felt_safe': call.body['felt_safe'],
              'share_mutual_interest': call.body['share_mutual_interest'],
            },
            'partner_debriefed': false,
          };
          return qaOk({'plan': plan});
        }),
      )
      ..on(
        'GET /matches/$matchId/plans/*/sharing',
        (_) => qaOk({
          'version': sharingVersion,
          'contact_ids': sharedWith,
          'contacts': contacts,
        }),
      )
      ..on(
        'POST /matches/$matchId/plans/*/sharing',
        _slow((call) {
          sharedWith = (call.body['contact_ids'] as List).cast<String>();
          sharingVersion++;
          return qaOk({'version': sharingVersion, 'contact_ids': sharedWith});
        }),
      )
      ..json('POST /safety/report', {
        'report': {'id': 'report-1'},
      })
      ..on('GET /plans/me', (_) => qaOk({'plans': mine}))
      ..on('GET /friends/me/plans', (_) => qaOk({'plans': friends}))
      ..json('GET /account/me/dating-preferences', {
        'preferences': <String, dynamic>{},
      });
  }

  QaReply _propose(Map<String, dynamic> body, {bool counter = false}) {
    final created = {
      ...planJson(
        id: counter ? 'plan-2' : 'plan-1',
        viewerRole: 'proposer',
        nextAction: 'await_decision',
        venueCategory: body['venue_category'] as String,
        venueName: body['venue_name'] as String? ?? '',
        venueArea: body['venue_area'] as String? ?? '',
        note: body['note'] as String? ?? '',
        budget: body['budget_preference'] as String,
        atmospheres: (body['atmosphere_preferences'] as List).cast<String>(),
        accessibility: (body['accessibility_preferences'] as List)
            .cast<String>(),
        lockVersion: 0,
      ),
      'window_start': body['window_start'],
      'window_end': body['window_end'],
    };
    plan = created;
    canPropose = false;
    return qaOk({'plan': created});
  }
}

Finder byKey(String key) => find.byKey(ValueKey(key));

/// Scrolls [key] into view and taps it, then settles.
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(byKey(key));
  await settle(tester);
}

/// pumpAndSettle, then one more frame: a provider reload started in the
/// last settled frame leaves a zero-length Dio timer behind.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pumpAndSettle();
    await tester.pump();
  }
}

/// Disposes the tree (and the shared-availability poller) at the end of a
/// test.
Future<void> teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// A page with one button that opens a sheet the way the app does and keeps
/// what the sheet resolved to.
class SheetLauncher extends StatelessWidget {
  const SheetLauncher({required this.open, required this.results, super.key});

  final Future<Object?> Function(BuildContext context) open;
  final List<Object?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('qa.test.open_sheet'),
        onPressed: () async => results.add(await open(context)),
        child: const Text('open sheet'),
      ),
    ),
  );
}

/// The text of the widget with [key] (a Text, or the text a TextField holds).
String textOf(WidgetTester tester, String key) {
  final widget = tester.widget(byKey(key));
  if (widget is Text) {
    return widget.data ?? '';
  }
  if (widget is TextField) {
    return widget.controller!.text;
  }
  throw StateError('$key is a ${widget.runtimeType}');
}

/// Whether the control with [key] currently accepts input.
bool isEnabled(WidgetTester tester, String key) {
  final widget = tester.widget(byKey(key));
  return switch (widget) {
    final ButtonStyleButton b => b.onPressed != null,
    final IconButton b => b.onPressed != null,
    final ActionChip c => c.onPressed != null,
    final ChoiceChip c => c.onSelected != null,
    final FilterChip c => c.onSelected != null,
    final CheckboxListTile c => c.onChanged != null,
    final SwitchListTile c => c.onChanged != null,
    final TextField t => t.enabled ?? true,
    _ => throw StateError('$key is a ${widget.runtimeType}'),
  };
}
