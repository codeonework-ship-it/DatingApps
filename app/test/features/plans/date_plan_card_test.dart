import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/models/date_plan_labels.dart';
import 'package:verified_dating_app/features/plans/widgets/date_plan_card.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'invitee-1');
}

/// In-memory BFF for a single match: answers the plan snapshot and records
/// every command it receives.
class _FakePlansApi {
  _FakePlansApi({required this.snapshot});

  Map<String, dynamic> snapshot;
  final List<({String path, Map<String, dynamic> body})> commands = [];

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET' && options.path.endsWith('/plans')) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: snapshot,
              ),
            );
            return;
          }
          if (options.method == 'POST') {
            final body = (options.data as Map).cast<String, dynamic>();
            commands.add((path: options.path, body: body));
            final plan = Map<String, dynamic>.from(
              snapshot['plan'] as Map<String, dynamic>,
            );
            if (options.path.endsWith('/decision')) {
              plan['status'] = body['decision'] == 'accept'
                  ? 'accepted'
                  : 'declined';
              plan['next_action'] = body['decision'] == 'accept'
                  ? 'upcoming'
                  : 'propose';
            } else if (options.path.endsWith('/debrief')) {
              plan['next_action'] = 'none';
              plan['debrief'] = {
                'user_id': 'invitee-1',
                'happened': body['happened'],
                'felt_safe': body['felt_safe'],
                'created_at': '2026-09-28T21:00:00Z',
              };
              plan['partner_debriefed'] = false;
            } else if (options.path.endsWith('/checkin')) {
              plan['next_action'] = 'none';
              plan['checkins'] = [
                {
                  'user_id': 'invitee-1',
                  'status': body['status'],
                  'at': '2026-09-28T20:30:00Z',
                },
              ];
            }
            snapshot = {...snapshot, 'plan': plan};
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'plan': plan},
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
                data: {'error': 'unexpected ${options.method} ${options.path}'},
              ),
            ),
          );
        },
      ),
    );
    return dio;
  }
}

Map<String, dynamic> _proposedPlan({
  String nextAction = 'decide',
  String viewerRole = 'invitee',
}) => {
  'id': 'plan-1',
  'match_id': 'match-1',
  'proposer_user_id': 'proposer-1',
  'invitee_user_id': 'invitee-1',
  'status': 'proposed',
  'window_start': '2026-09-28T16:00:00Z',
  'window_end': '2026-09-28T18:00:00Z',
  'venue_category': 'coffee',
  'venue_area': 'Indiranagar',
  'note': 'Third Wave?',
  'proposer_group_ids': <String>[],
  'invitee_group_ids': <String>[],
  'checkin_due_at': '2026-09-28T19:00:00Z',
  'created_at': '2026-09-27T10:00:00Z',
  'updated_at': '2026-09-27T10:00:00Z',
  'lock_version': 0,
  'viewer_role': viewerRole,
  'partner_user_id': 'proposer-1',
  'partner_name': 'Arjun',
  'checkins': <Map<String, dynamic>>[],
  'next_action': nextAction,
};

Widget _host(_FakePlansApi api) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.build()),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: DatePlanCard(matchId: 'match-1', partnerName: 'Arjun'),
    ),
  ),
);

void main() {
  testWidgets('invitee sees the proposal and accepts it', (tester) async {
    final api = _FakePlansApi(
      snapshot: {
        'match_id': 'match-1',
        'plan': _proposedPlan(),
        'history': <dynamic>[],
        'share_groups': <dynamic>[],
        'can_propose': false,
        'unlock_state': 'conversation_unlocked',
      },
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('Arjun proposed a date'), findsOneWidget);
    expect(find.textContaining('Coffee · Indiranagar'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.plan.accept')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qa.plan.accept')));
    await tester.pumpAndSettle();

    expect(api.commands, hasLength(1));
    expect(api.commands.single.path, endsWith('/plans/plan-1/decision'));
    expect(api.commands.single.body['decision'], 'accept');
    expect(find.text('It is a plan'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.plan.cancel')), findsOneWidget);
  });

  testWidgets('after the window the member can check in safe', (tester) async {
    final api = _FakePlansApi(
      snapshot: {
        'match_id': 'match-1',
        'plan': {..._proposedPlan(nextAction: 'checkin'), 'status': 'accepted'},
        'history': <dynamic>[],
        'share_groups': <dynamic>[],
        'can_propose': false,
        'unlock_state': 'conversation_unlocked',
      },
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('How did it go?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.plan.safe')));
    await tester.pumpAndSettle();

    expect(api.commands.single.path, endsWith('/plans/plan-1/checkin'));
    expect(api.commands.single.body['status'], 'safe');
    expect(find.text('You checked in safe'), findsOneWidget);
  });

  testWidgets('shows the propose call to action only when allowed', (
    tester,
  ) async {
    final api = _FakePlansApi(
      snapshot: {
        'match_id': 'match-1',
        'plan': null,
        'history': <dynamic>[],
        'share_groups': <dynamic>[],
        'can_propose': true,
        'unlock_state': 'conversation_unlocked',
      },
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.plan.propose_cta')), findsOneWidget);
    expect(find.text('Plan a date with Arjun'), findsOneWidget);
  });

  testWidgets('hides the propose call to action while the chat is locked', (
    tester,
  ) async {
    final locked = _FakePlansApi(
      snapshot: {
        'match_id': 'match-1',
        'plan': null,
        'history': <dynamic>[],
        'share_groups': <dynamic>[],
        'can_propose': false,
        'unlock_state': 'quest_pending',
      },
    );
    await tester.pumpWidget(_host(locked));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.plan.propose_cta')), findsNothing);
  });

  testWidgets('after checking in the member answers the debrief', (
    tester,
  ) async {
    final api = _FakePlansApi(
      snapshot: {
        'match_id': 'match-1',
        'plan': {
          ..._proposedPlan(nextAction: 'debrief'),
          'status': 'accepted',
          'checkins': [
            {
              'user_id': 'invitee-1',
              'status': 'safe',
              'at': '2026-09-28T20:30:00Z',
            },
          ],
        },
        'history': <dynamic>[],
        'share_groups': <dynamic>[],
        'can_propose': false,
        'unlock_state': 'conversation_unlocked',
      },
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('How was it?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.plan.debrief')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qa.debrief.happened.yes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.debrief.safe.yes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.debrief.submit')));
    await tester.pumpAndSettle();

    expect(api.commands.single.path, endsWith('/plans/plan-1/debrief'));
    expect(api.commands.single.body['happened'], isTrue);
    expect(api.commands.single.body['felt_safe'], isTrue);
    expect(find.text("Waiting for Arjun's debrief"), findsOneWidget);
  });

  test('models parse the BFF payloads', () {
    final plan = DatePlan.fromJson(_proposedPlan());
    expect(plan.isProposed, isTrue);
    expect(plan.viewerIsInvitee, isTrue);
    final en = lookupAppLocalizations(const Locale('en'));
    expect(datePlanVenueLabel(en, plan.venueCategory), 'Coffee');
    expect(plan.localizedSummary(en), contains('Indiranagar'));

    final friend = FriendPlan.fromJson(
      jsonDecode('''
        {"plan_id":"p","friend_user_id":"f","friend_name":"Meera",
         "partner_name":"Dev","status":"accepted","latest_update":"need_help",
         "title":"Meera needs help","description":"Please reach out",
         "window_start":"2026-09-28T16:00:00Z","window_end":"2026-09-28T18:00:00Z",
         "venue_category":"meal","via":"group","updated_at":"2026-09-28T19:00:00Z",
         "checkins":[{"user_id":"f","status":"need_help","at":"2026-09-28T19:00:00Z"}]}
      ''')
          as Map<String, dynamic>,
    );
    expect(friend.needsHelp, isTrue);
    expect(friend.checkedInSafe, isFalse);
    expect(datePlanVenueLabel(en, friend.venueCategory), 'A meal');
  });

  test('[case:l10n-plan-fallback-names-german] a plan without names reads '
      'in German', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final plan = DatePlan.fromJson(_proposedPlan()..remove('partner_name'));
    final friend = FriendPlan.fromJson(const <String, dynamic>{'plan_id': 'p'});
    const group = DatePlanShareGroup(id: 'g', name: '');
    // The model keeps no English stand-in; the widget-facing label speaks
    // the member's language.
    expect(plan.partnerName, isEmpty);
    expect(plan.partnerLabel(de), de.matchesFallbackName);
    expect(plan.partnerLabel(de), isNot('Your match'));
    expect(friend.friendLabel(de), de.planSharingFriendFallback);
    expect(friend.friendLabel(de), isNot('A friend'));
    expect(group.label(de), de.groupsDetailTitleFallback);
    expect(
      DatePlan.fromJson(_proposedPlan()).partnerLabel(de),
      isNot(de.matchesFallbackName),
    );
  });
}
