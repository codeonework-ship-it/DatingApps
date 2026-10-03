// Daily Prompt Streak: every control performs its action against the
// recording fake BFF and the member sees the outcome.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/daily_prompt_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _promptId = 'dp-2026-10-02';
const _field = ValueKey('qa.daily_prompt.answer');
const _submit = ValueKey('qa.daily_prompt.submit');

Map<String, dynamic> _answer(
  String text, {
  String editUntil = '2099-01-01T00:00:00Z',
  bool edited = false,
}) => {
  'user_id': 'me',
  'prompt_id': _promptId,
  'prompt_date': '2026-10-02',
  'answer_text': text,
  'answered_at': '2026-10-02T08:00:00Z',
  'updated_at': '2026-10-02T08:00:00Z',
  'edit_window_until': editUntil,
  'is_edited': edited,
};

Map<String, dynamic> _view({
  Map<String, dynamic>? answer,
  int replied = 4,
  int similar = 0,
  int streak = 0,
  int maxChars = 240,
}) => {
  'daily_prompt': {
    'prompt': {
      'id': _promptId,
      'prompt_date': '2026-10-02',
      'domain': 'values',
      'prompt_text': 'What makes you feel respected?',
      'min_chars': 1,
      'max_chars': maxChars,
      'response_mode': 'text',
    },
    'answer': ?answer,
    'streak': {
      'current_days': streak,
      'longest_days': 5,
      'last_answered_date': '2026-10-01',
      'next_milestone': 3,
      'milestone_reached': 0,
    },
    'spark': {
      'participants_today': replied,
      'similar_answer_count': similar,
      'similar_user_ids': <String>[],
    },
  },
};

const _responders = {
  'responders': <Object>[],
  'pagination': {'has_more': false, 'next_offset': 0},
};

QaApi _api({Map<String, dynamic>? view}) => QaApi()
  ..json('GET /engagement/daily-prompt/me', view ?? _view())
  ..json('GET /engagement/daily-prompt/me/responders', _responders);

Future<void> _open(WidgetTester tester, QaApi api) async {
  await pumpQa(tester, api, const DailyPromptScreen());
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await qaScrollTo(tester, find.byKey(_submit));
  await tester.tap(find.byKey(_submit));
  await qaSettle(tester);
}

void main() {
  group('Update Answer', () {
    testWidgets(
      'Update Answer saves the edited answer, reloads responders and shows the new state [case:engagement.daily_prompt.daily_prompt_submit.action]',
      (tester) async {
        final api = _api(view: _view(answer: _answer('Being listened to.')));
        api.json(
          'POST /engagement/daily-prompt/me/answer',
          _view(
            answer: _answer('Being heard, really.', edited: true),
            replied: 5,
            similar: 2,
            streak: 1,
          ),
        );
        await _open(tester, api);

        expect(qaFieldText(tester, find.byKey(_field)), 'Being listened to.');
        expect(find.text(en.engagementDailyPromptUpdate), findsOneWidget);
        expect(find.text(en.engagementDailyPromptEdited), findsNothing);
        final respondersBefore = api
            .sent('GET', '/engagement/daily-prompt/me/responders')
            .length;

        await tester.enterText(find.byKey(_field), 'Being heard, really.');
        await _tapSubmit(tester);

        final posts = api.sent('POST', '/engagement/daily-prompt/me/answer');
        expect(posts, hasLength(1));
        expect(posts.single.body, {
          'prompt_id': _promptId,
          'answer_text': 'Being heard, really.',
        });
        final responders = api.sent(
          'GET',
          '/engagement/daily-prompt/me/responders',
        );
        expect(responders, hasLength(respondersBefore + 1));
        expect(responders.last.query, {'limit': 6, 'offset': 0});
        expect(
          api.calls.indexOf(responders.last),
          greaterThan(api.calls.indexOf(posts.single)),
        );
        expect(find.text(en.engagementDailyPromptEdited), findsOneWidget);
        expect(
          find.text(en.engagementDailyPromptSparkSummary(5, 2)),
          findsOneWidget,
        );
        expect(qaFieldText(tester, find.byKey(_field)), 'Being heard, really.');
        expect(qaEnabled(tester, find.byKey(_submit)), isTrue);
        expect(api.unhandled, isEmpty);
      },
    );

    testWidgets(
      'first answer of the day uses Submit Daily Answer and then offers Update Answer [case:engagement.daily_prompt.daily_prompt_submit.action]',
      (tester) async {
        final api = _api();
        api.json(
          'POST /engagement/daily-prompt/me/answer',
          _view(answer: _answer('Kindness.'), replied: 5, streak: 1),
        );
        await _open(tester, api);
        expect(find.text(en.engagementDailyPromptSubmit), findsOneWidget);
        expect(
          find.text(en.engagementDailyPromptSparkSummary(4, 0)),
          findsOneWidget,
        );

        await tester.enterText(find.byKey(_field), 'Kindness.');
        await _tapSubmit(tester);

        expect(
          api.sent('POST', '/engagement/daily-prompt/me/answer').single.body,
          {'prompt_id': _promptId, 'answer_text': 'Kindness.'},
        );
        expect(find.text(en.engagementDailyPromptUpdate), findsOneWidget);
        expect(find.text(en.engagementDailyPromptSubmit), findsNothing);
        expect(
          find.text(
            en.engagementDailyPromptStatCurrent(
              en.engagementDailyPromptDays(1),
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when the edit window has closed the answer and button are locked and nothing is sent [case:engagement.daily_prompt.daily_prompt_submit.edit_window_closed]',
      (tester) async {
        final api = _api(
          view: _view(
            answer: _answer('Old answer', editUntil: '2026-10-01T00:00:00Z'),
          ),
        );
        await _open(tester, api);
        expect(find.text(en.engagementDailyPromptEditClosed), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_submit)), isFalse);
        expect(tester.widget<TextField>(find.byKey(_field)).enabled, isFalse);
        await tester.tap(find.byKey(_submit), warnIfMissed: false);
        await qaSettle(tester);
        expect(api.writes, isEmpty);
      },
    );

    for (final (label, failure, message) in [
      (
        '500 shows the server message',
        qaError(500, message: 'Answer service is down.'),
        'Answer service is down.',
      ),
      (
        'offline shows the localized fallback',
        qaOffline,
        'Unable to submit answer. Please try again.',
      ),
    ]) {
      testWidgets(
        'Update Answer failure ($label), keeps the typed text and retries cleanly [case:engagement.daily_prompt.daily_prompt_submit.api_failure]',
        (tester) async {
          final api = _api(view: _view(answer: _answer('Being listened to.')));
          api.on('POST /engagement/daily-prompt/me/answer', (_) => failure);
          await _open(tester, api);

          await tester.enterText(find.byKey(_field), 'Curiosity, mostly.');
          await _tapSubmit(tester);

          expect(find.text(message), findsOneWidget);
          expect(qaFieldText(tester, find.byKey(_field)), 'Curiosity, mostly.');
          expect(qaEnabled(tester, find.byKey(_submit)), isTrue);
          expect(find.text(en.engagementDailyPromptEdited), findsNothing);
          expect(
            api.sent('POST', '/engagement/daily-prompt/me/answer'),
            hasLength(1),
          );

          api.json(
            'POST /engagement/daily-prompt/me/answer',
            _view(answer: _answer('Curiosity, mostly.', edited: true)),
          );
          await _tapSubmit(tester);
          expect(find.text(message), findsNothing);
          expect(find.text(en.engagementDailyPromptEdited), findsOneWidget);
          final posts = api.sent('POST', '/engagement/daily-prompt/me/answer');
          expect(posts, hasLength(2));
          expect(posts.last.body['answer_text'], 'Curiosity, mostly.');
        },
      );
    }
  });

  group('answer field', () {
    testWidgets(
      'typing fills the answer field and counts characters against the prompt limit [case:engagement.daily_prompt.daily_prompt_answer_input.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        expect(find.text(en.engagementDailyPromptHint), findsOneWidget);

        await tester.tap(find.byKey(_field));
        await tester.enterText(find.byKey(_field), 'Being on time');
        await tester.pump();

        expect(qaFieldText(tester, find.byKey(_field)), 'Being on time');
        expect(find.text('13/240'), findsOneWidget);
        expect(api.writes, isEmpty, reason: 'typing alone sends nothing');
      },
    );

    testWidgets(
      'empty and whitespace-only answers are blocked with a localized message [case:engagement.daily_prompt.daily_prompt_answer_input.validation]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        for (final blank in ['', '   \n  ']) {
          await tester.enterText(find.byKey(_field), blank);
          await _tapSubmit(tester);
          expect(
            find.text(en.engagementDailyPromptEnterAnswer),
            findsOneWidget,
          );
        }
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'max+1 characters are capped at the prompt limit before sending [case:engagement.daily_prompt.daily_prompt_answer_input.validation]',
      (tester) async {
        final api = _api(view: _view(maxChars: 20));
        api.json(
          'POST /engagement/daily-prompt/me/answer',
          _view(answer: _answer('a' * 20), maxChars: 20),
        );
        await _open(tester, api);
        await tester.enterText(find.byKey(_field), 'a' * 21);
        await tester.pump();
        expect(qaFieldText(tester, find.byKey(_field)), 'a' * 20);
        expect(find.text('20/20'), findsOneWidget);
        await _tapSubmit(tester);
        expect(
          api
              .sent('POST', '/engagement/daily-prompt/me/answer')
              .single
              .body['answer_text'],
          'a' * 20,
        );
      },
    );

    testWidgets(
      'emoji and right-to-left text reach the server byte-for-byte (trimmed) [case:engagement.daily_prompt.daily_prompt_answer_input.validation]',
      (tester) async {
        const unicode = 'שלום 👋🏽 مرحبا — café';
        final api = _api();
        api.json(
          'POST /engagement/daily-prompt/me/answer',
          _view(answer: _answer(unicode)),
        );
        await _open(tester, api);
        await tester.enterText(find.byKey(_field), '  $unicode  ');
        await _tapSubmit(tester);
        final sent =
            api
                    .sent('POST', '/engagement/daily-prompt/me/answer')
                    .single
                    .body['answer_text']
                as String;
        expect(sent, unicode);
        expect(sent.codeUnits, unicode.codeUnits);
        expect(qaFieldText(tester, find.byKey(_field)), unicode);
      },
    );
  });

  group('pull to refresh', () {
    testWidgets(
      'pull to refresh reloads the prompt and responders and shows the new counts [case:engagement.daily_prompt.update_answer_onrefresh.action]',
      (tester) async {
        final api = _api(view: _view(answer: _answer('Kindness.')));
        await _open(tester, api);
        expect(
          find.text(en.engagementDailyPromptSparkSummary(4, 0)),
          findsOneWidget,
        );
        final prompts0 = api.sent('GET', '/engagement/daily-prompt/me').length;
        final responders0 = api
            .sent('GET', '/engagement/daily-prompt/me/responders')
            .length;

        api.json(
          'GET /engagement/daily-prompt/me',
          _view(answer: _answer('Kindness.'), replied: 9, similar: 3),
        );
        await qaPullToRefresh(tester);

        expect(
          api.sent('GET', '/engagement/daily-prompt/me'),
          hasLength(prompts0 + 1),
        );
        expect(
          api.sent('GET', '/engagement/daily-prompt/me/responders'),
          hasLength(responders0 + 1),
        );
        expect(
          find.text(en.engagementDailyPromptSparkSummary(9, 3)),
          findsOneWidget,
        );
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed refresh shows the error, keeps the prompt and the typed answer, and the next pull recovers [case:engagement.daily_prompt.update_answer_onrefresh.api_failure]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        await tester.enterText(find.byKey(_field), 'Draft in progress');

        api.fail(
          'GET /engagement/daily-prompt/me',
          message: 'Prompt service is down.',
        );
        await qaPullToRefresh(tester);
        expect(find.text('Prompt service is down.'), findsOneWidget);
        expect(find.text('What makes you feel respected?'), findsOneWidget);
        expect(qaFieldText(tester, find.byKey(_field)), 'Draft in progress');
        expect(tester.takeException(), isNull);

        api.json('GET /engagement/daily-prompt/me', _view(replied: 6));
        await qaPullToRefresh(tester);
        expect(find.text('Prompt service is down.'), findsNothing);
        expect(
          find.text(en.engagementDailyPromptSparkSummary(6, 0)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a first load that fails explains why and offers pull to refresh [case:engagement.daily_prompt.update_answer_onrefresh.api_failure]',
      (tester) async {
        final api = _api()..offline('GET /engagement/daily-prompt/me');
        await _open(tester, api);
        expect(find.text(en.engagementDailyPromptUnavailable), findsOneWidget);
        expect(find.text(en.engagementDailyPromptLoadFailed), findsOneWidget);
        expect(find.byKey(_submit), findsNothing);

        api.json('GET /engagement/daily-prompt/me', _view());
        await qaPullToRefresh(tester);
        expect(find.text('What makes you feel respected?'), findsOneWidget);
        expect(find.byKey(_submit), findsOneWidget);
      },
    );

    testWidgets(
      'regression: when today has no prompt (404) a refresh drops the stale prompt instead of keeping it [case:engagement.daily_prompt.update_answer_onrefresh.no_prompt_today]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        expect(find.text('What makes you feel respected?'), findsOneWidget);

        api.fail('GET /engagement/daily-prompt/me', status: 404);
        await qaPullToRefresh(tester);

        expect(find.text('What makes you feel respected?'), findsNothing);
        expect(find.byKey(_submit), findsNothing);
        expect(find.text(en.engagementDailyPromptUnavailable), findsOneWidget);
        expect(
          find.text(en.engagementDailyPromptPullToRefresh),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets(
    'Daily prompt renders translated in every locale without overflow [case:engagement.daily_prompt.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        final api = _api(view: _view(answer: _answer('Kindness.')));
        await pumpQa(tester, api, const DailyPromptScreen(), locale: locale);
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementDailyPromptTitle), findsOneWidget);
        expect(find.text(l.engagementDailyPromptYourAnswer), findsOneWidget);
        expect(find.text(l.engagementDailyPromptUpdate), findsOneWidget);
        expect(find.text(l.engagementDailyPromptSparkTitle), findsOneWidget);
        await qaUnmount(tester);
      }
    },
  );
}
