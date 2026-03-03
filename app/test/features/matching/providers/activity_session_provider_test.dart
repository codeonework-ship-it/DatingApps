import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/matching/providers/activity_session_provider.dart';

void main() {
  group('ActivitySessionState', () {
    test('allQuestionsAnswered true when every question has a selection', () {
      final questions = buildDefaultActivityQuestions();
      final state = ActivitySessionState(
        questions: questions,
        selectedAnswers: <String, String>{
          questions[0].id: questions[0].options.first,
          questions[1].id: questions[1].options.first,
          questions[2].id: questions[2].options.first,
        },
      );

      expect(state.allQuestionsAnswered, isTrue);
    });

    test('allQuestionsAnswered false when answers are incomplete', () {
      final questions = buildDefaultActivityQuestions();
      final state = ActivitySessionState(
        questions: questions,
        selectedAnswers: <String, String>{
          questions[0].id: questions[0].options.first,
        },
      );

      expect(state.allQuestionsAnswered, isFalse);
    });

    test('isTerminal true for timeout terminal states', () {
      expect(
        const ActivitySessionState(status: 'timed_out').isTerminal,
        isTrue,
      );
      expect(
        const ActivitySessionState(status: 'partial_timeout').isTerminal,
        isTrue,
      );
    });

    test('copyWith clearError clears previous failure state', () {
      const initial = ActivitySessionState(error: 'submit failed');
      final updated = initial.copyWith(clearError: true);

      expect(initial.error, isNotNull);
      expect(updated.error, isNull);
    });
  });

  group('ActivitySummary.fromJson', () {
    test('maps happy path payload values', () {
      final summary = ActivitySummary.fromJson(<String, dynamic>{
        'session_id': 'session-1',
        'match_id': 'match-1',
        'status': 'completed',
        'total_participants': 2,
        'responses_submitted': 2,
        'participants_completed': <String>['user-a', 'user-b'],
        'participants_pending': const <String>[],
        'insight': 'Both completed.',
        'generated_at': '2026-03-01T10:00:00Z',
      });

      expect(summary.sessionId, 'session-1');
      expect(summary.status, 'completed');
      expect(summary.responsesSubmitted, 2);
      expect(summary.participantsCompleted, hasLength(2));
      expect(summary.generatedAt, isNotNull);
    });

    test('uses safe defaults for malformed payload values', () {
      final summary = ActivitySummary.fromJson(<String, dynamic>{
        'total_participants': 'invalid',
        'responses_submitted': null,
        'participants_completed': null,
        'generated_at': 'not-a-date',
      });

      expect(summary.sessionId, isEmpty);
      expect(summary.totalParticipants, 0);
      expect(summary.responsesSubmitted, 0);
      expect(summary.participantsCompleted, isEmpty);
      expect(summary.generatedAt, isNull);
    });
  });

  group('buildDefaultActivityQuestions', () {
    test('returns three required activity interfaces', () {
      final questions = buildDefaultActivityQuestions();

      expect(questions, hasLength(3));
      expect(questions[0].type, ActivityQuestionType.thisOrThat);
      expect(questions[1].type, ActivityQuestionType.valueMatch);
      expect(questions[2].type, ActivityQuestionType.scenarioChoice);
      expect(questions.every((q) => q.options.isNotEmpty), isTrue);
    });
  });

  group('computeActivityRemainingSeconds', () {
    test('returns zero when session already expired', () {
      final now = DateTime.utc(2026, 3, 1, 12, 0, 0);
      final expiresAt = now.subtract(const Duration(seconds: 3));

      final remaining = computeActivityRemainingSeconds(expiresAt, now);

      expect(remaining, 0);
    });

    test('returns positive seconds for active session', () {
      final now = DateTime.utc(2026, 3, 1, 12, 0, 0);
      final expiresAt = now.add(const Duration(seconds: 180));

      final remaining = computeActivityRemainingSeconds(expiresAt, now);

      expect(remaining, 180);
    });
  });
}
