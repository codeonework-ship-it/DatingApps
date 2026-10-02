// The 2-minute This-or-That activity: start, answer, submit, summaries and
// share, against the recording fake BFF — the exact requests and what the
// member reads, including each failure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/matching/providers/activity_session_provider.dart';
import 'package:verified_dating_app/features/matching/screens/activity_session_screen.dart';

import '../../support/qa_api.dart';

final _questions = buildDefaultActivityQuestions();

Map<String, dynamic> _session({
  String status = 'active',
  Duration left = const Duration(minutes: 3),
}) => {
  'id': 'act-1',
  'status': status,
  'activity_type': 'this_or_that',
  'started_at': DateTime.now().toUtc().toIso8601String(),
  'expires_at': DateTime.now().toUtc().add(left).toIso8601String(),
};

Map<String, dynamic> _summary({
  String status = 'completed',
  List<String> completed = const ['me', 'maya'],
  String insight = 'You both picked the long walk.',
}) => {
  'summary': {
    'session_id': 'act-1',
    'match_id': 'm1',
    'status': status,
    'total_participants': 2,
    'responses_submitted': completed.length,
    'participants_completed': completed,
    'participants_pending': <String>[],
    'insight': insight,
  },
  'session': {'id': 'act-1', 'status': status},
};

QaApi _api({Duration left = const Duration(minutes: 3)}) => QaApi()
  ..json('POST /activities/sessions/start', {'session': _session(left: left)})
  ..json('POST /activities/sessions/act-1/submit', {
    'session': _session(status: 'completed'),
  })
  ..json('GET /activities/sessions/act-1/summary', _summary());

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  bool share = false,
}) => pumpQa(
  tester,
  api,
  ActivitySessionScreen(
    matchId: 'm1',
    otherUserId: 'maya',
    otherUserName: 'Maya',
    enableShareToChat: share,
  ),
  launcher: true,
);

/// Stops the countdown before the test ends.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await qaSettle(tester, frames: 5);
}

Future<void> _answerAll(WidgetTester tester, {int except = -1}) async {
  for (final (i, q) in _questions.indexed) {
    if (i == except) continue;
    await _tap(tester, ValueKey('qa.activity.answer.${q.id}.0'));
  }
}

void main() {
  testWidgets('opening starts a session for this match '
      '[case:matching.activity_session.start_a_new_session.api_contract]', (
    tester,
  ) async {
    final api = _api();
    await _open(tester, api);

    expect(api.sent('POST', '/activities/sessions/start').single.body, {
      'match_id': 'm1',
      'initiator_user_id': 'me',
      'participant_user_id': 'maya',
      'activity_type': 'this_or_that',
      'metadata': {
        'ui_variant': 'story_4_2',
        'question_set': 'this_or_that_eight_cards_v1',
      },
    });
    expect(find.text('Complete this with Maya'), findsOneWidget);
    expect(find.text('Status: active'), findsOneWidget);
    expect(find.textContaining('Time left 0'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('Start a new session starts again and clears the answers '
      '[case:matching.activity_session.start_a_new_session.action]', (
    tester,
  ) async {
    final api = _api();
    await _open(tester, api);
    await _tap(tester, ValueKey('qa.activity.answer.${_questions[0].id}.1'));
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(ValueKey('qa.activity.answer.${_questions[0].id}.1')),
          )
          .selected,
      isTrue,
    );

    await _tap(tester, const ValueKey('qa.activity.restart'));

    expect(api.sent('POST', '/activities/sessions/start'), hasLength(2));
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(ValueKey('qa.activity.answer.${_questions[0].id}.1')),
          )
          .selected,
      isFalse,
    );
    await _close(tester);
  });

  testWidgets('a session that cannot start says so '
      '[case:matching.activity_session.start_a_new_session.api_failure]', (
    tester,
  ) async {
    final api = _api()..offline('POST /activities/sessions/start');
    await _open(tester, api);

    expect(
      find.text('Unable to start activity right now. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('qa.activity.submit')),
          )
          .onPressed,
      isNull,
      reason: 'nothing to submit to',
    );
    // Regression (2026-10-02): with no session the screen offered "Time is
    // up — Load Summary", which had no session to load and did nothing.
    expect(
      find.byKey(const ValueKey('qa.activity.time_up_load')),
      findsNothing,
    );
    expect(find.text('Time is up — Load Summary'), findsNothing);

    // Restart is the way forward: it starts the session for real.
    api.json('POST /activities/sessions/start', {'session': _session()});
    await _tap(tester, const ValueKey('qa.activity.restart'));
    expect(api.sent('POST', '/activities/sessions/start'), hasLength(2));
    expect(
      find.text('Unable to start activity right now. Please try again.'),
      findsNothing,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('qa.activity.submit')),
          )
          .onPressed,
      isNotNull,
    );
    await _close(tester);
  });

  testWidgets('choosing an answer selects it '
      '[case:matching.activity_session.questioncard_onselected.action]', (
    tester,
  ) async {
    final api = _api();
    await _open(tester, api);
    final first = ValueKey('qa.activity.answer.${_questions[0].id}.0');
    final second = ValueKey('qa.activity.answer.${_questions[0].id}.1');

    await _tap(tester, first);
    expect(tester.widget<ChoiceChip>(find.byKey(first)).selected, isTrue);
    await _tap(tester, second);
    expect(tester.widget<ChoiceChip>(find.byKey(first)).selected, isFalse);
    expect(tester.widget<ChoiceChip>(find.byKey(second)).selected, isTrue);
    expect(api.writes.map((c) => c.path), ['/activities/sessions/start']);
    await _close(tester);
  });

  testWidgets('Submit with a round unanswered asks for all answers '
      '[case:matching.activity_session.submit_responses.validation]', (
    tester,
  ) async {
    final api = _api();
    await _open(tester, api);
    await _answerAll(tester, except: 7);
    await _tap(tester, const ValueKey('qa.activity.submit'));

    expect(
      find.text('Please answer all prompts before submitting.'),
      findsOneWidget,
    );
    expect(api.sent('POST', '/activities/sessions/act-1/submit'), isEmpty);
    await _close(tester);
  });

  testWidgets('Submit sends every answer, then shows the summary '
      '[case:matching.activity_session.submit_responses.action] '
      '[case:matching.activity_session.submit_responses.api_contract]', (
    tester,
  ) async {
    final api = _api();
    await _open(tester, api);
    await _answerAll(tester);
    await _tap(tester, const ValueKey('qa.activity.submit'));

    expect(api.sent('POST', '/activities/sessions/act-1/submit').single.body, {
      'user_id': 'me',
      'responses': [for (final q in _questions) '${q.id}:${q.options.first}'],
    });
    expect(api.sent('GET', '/activities/sessions/act-1/summary'), hasLength(1));
    expect(find.text('Activity Summary'), findsOneWidget);
    expect(find.text('Participants completed: 2/2'), findsOneWidget);
    expect(find.text('You both picked the long walk.'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a failed submit says so and keeps the answers '
      '[case:matching.activity_session.submit_responses.api_failure]', (
    tester,
  ) async {
    final api = _api()..fail('POST /activities/sessions/act-1/submit');
    await _open(tester, api);
    await _answerAll(tester);
    await _tap(tester, const ValueKey('qa.activity.submit'));

    expect(find.text('Something broke on our side.'), findsOneWidget);
    expect(find.text('Activity Summary'), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(ValueKey('qa.activity.answer.${_questions[7].id}.0')),
          )
          .selected,
      isTrue,
    );
    await _close(tester);
  });

  testWidgets('waiting on the other person: Refresh Summary fetches it '
      '[case:matching.activity_session.refresh_summary.action] '
      '[case:matching.activity_session.refresh_summary.api_contract]', (
    tester,
  ) async {
    final api = _api()
      ..json('POST /activities/sessions/act-1/submit', {'session': _session()})
      ..json(
        'GET /activities/sessions/act-1/summary',
        _summary(status: 'active', completed: ['me'], insight: ''),
      );
    await _open(tester, api);
    await _answerAll(tester);
    await _tap(tester, const ValueKey('qa.activity.submit'));
    expect(
      find.text('Responses sent. Waiting for the other participant to finish.'),
      findsOneWidget,
    );

    await _tap(tester, const ValueKey('qa.activity.refresh_summary'));

    expect(api.sent('GET', '/activities/sessions/act-1/summary'), hasLength(1));
    expect(find.text('Participants completed: 1/2'), findsOneWidget);
    expect(find.text('Summary will appear once available.'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a failed Refresh Summary says to try again '
      '[case:matching.activity_session.refresh_summary.api_failure]', (
    tester,
  ) async {
    final api = _api()
      ..json('POST /activities/sessions/act-1/submit', {'session': _session()})
      ..offline('GET /activities/sessions/act-1/summary');
    await _open(tester, api);
    await _answerAll(tester);
    await _tap(tester, const ValueKey('qa.activity.submit'));
    await _tap(tester, const ValueKey('qa.activity.refresh_summary'));

    expect(
      find.text('Unable to fetch summary yet. Please try again.'),
      findsOneWidget,
    );
    await _close(tester);
  });

  testWidgets('when time is up the summary loads once, and Load Summary '
      'fetches it again '
      '[case:matching.activity_session.time_is_up_load_summary.action] '
      '[case:matching.activity_session.time_is_up_load_summary.api_contract]', (
    tester,
  ) async {
    final api = _api(left: Duration.zero)
      ..json(
        'GET /activities/sessions/act-1/summary',
        // The server has not closed the session yet.
        _summary(status: 'active', completed: [], insight: ''),
      );
    await _open(tester, api);
    await qaSettle(tester, frames: 30);

    expect(api.sent('GET', '/activities/sessions/act-1/summary'), hasLength(1));
    expect(find.text('Time is up — Load Summary'), findsOneWidget);

    await _tap(tester, const ValueKey('qa.activity.time_up_load'));
    expect(api.sent('GET', '/activities/sessions/act-1/summary'), hasLength(2));
    await _close(tester);
  });

  // Regression (2026-10-02): with the session still "active" after time ran
  // out (or the summary failing) the screen re-requested the summary every
  // second for as long as it stayed open.
  testWidgets('a failing summary after time is up is not polled every second '
      '[case:matching.activity_session.time_is_up_load_summary.api_failure]', (
    tester,
  ) async {
    final api = _api(left: Duration.zero)
      ..fail('GET /activities/sessions/act-1/summary', status: 503);
    await _open(tester, api);
    await qaSettle(tester, frames: 50); // five seconds

    expect(api.sent('GET', '/activities/sessions/act-1/summary'), hasLength(1));
    expect(find.text('Something broke on our side.'), findsOneWidget);
    expect(find.text('Time is up — Load Summary'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('Share Result to Chat hands the result back to the opener '
      '[case:matching.activity_session.share_result_to_chat_onshare.action]', (
    tester,
  ) async {
    final api = _api();
    final results = await _open(tester, api, share: true);
    await _answerAll(tester);
    await _tap(tester, const ValueKey('qa.activity.submit'));
    await _tap(tester, const ValueKey('qa.activity.share_result'));
    await qaSettle(tester);

    expect(find.byType(ActivitySessionScreen), findsNothing);
    expect(results, [
      '2-Min This-or-That result: completed • 2/2 completed • '
          'You both picked the long walk.',
    ]);
  });
}
