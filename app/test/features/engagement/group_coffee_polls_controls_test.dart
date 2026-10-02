// Group Coffee Polls: create, vote, finalize, refresh and every form field,
// asserted against the recording fake BFF (request body, list reload and
// what the member sees).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/group_coffee_polls_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _list = '/engagement/group-coffee-polls';
const _participants = ValueKey('qa.coffee.participants');
const _deadline = ValueKey('qa.coffee.deadline');
const _create = ValueKey('qa.coffee.create');
const _actor = ValueKey('qa.coffee.actor');
const _vote2 = ValueKey('qa.coffee.vote.poll-1.opt-2');
const _finalize = ValueKey('qa.coffee.finalize.poll-1');

Map<String, dynamic> _poll({
  String id = 'poll-1',
  String status = 'open',
  int votes1 = 1,
  int votes2 = 0,
  List<String> participants = const ['me', 'ana'],
}) => {
  'id': id,
  'creator_user_id': 'me',
  'participant_user_ids': participants,
  'options': [
    {
      'id': 'opt-1',
      'day': 'Saturday',
      'time_window': '10:00-12:00',
      'neighborhood': 'Indiranagar',
      'votes_count': votes1,
    },
    {
      'id': 'opt-2',
      'day': 'Sunday',
      'time_window': '11:00-13:00',
      'neighborhood': 'Koramangala',
      'votes_count': votes2,
    },
  ],
  'status': status,
  'deadline_at': '2026-10-03T10:00:00Z',
  'finalized_option_id': status == 'finalized' ? 'opt-2' : '',
};

QaApi _api([List<Map<String, dynamic>>? polls]) => QaApi()
  ..json('GET $_list', {
    'polls': polls ?? [_poll()],
  });

Future<void> _open(WidgetTester tester, QaApi api) =>
    pumpQa(tester, api, const GroupCoffeePollsScreen());

Future<void> _type(WidgetTester tester, Key key, String text) async {
  await qaScrollTo(tester, find.byKey(key));
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await qaScrollTo(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await qaSettle(tester);
}

String _summary(String day, String time, String area, int votes) =>
    en.engagementCoffeeOptionSummary(day, time, area, votes);

const _defaultOptions = [
  {
    'day': 'Saturday',
    'time_window': '10:00-12:00',
    'neighborhood': 'Indiranagar',
  },
  {
    'day': 'Sunday',
    'time_window': '11:00-13:00',
    'neighborhood': 'Koramangala',
  },
];

void main() {
  group('Create Poll', () {
    testWidgets(
      'Create Poll sends the participants, both options and the deadline, then lists the new poll [case:engagement.group_coffee_polls.create_poll.action]',
      (tester) async {
        final api = _api([])
          ..json('POST $_list', {'poll': _poll(id: 'poll-2')});
        await _open(tester, api);
        await qaScrollTo(tester, find.text(en.engagementCoffeeEmpty));
        expect(find.text(en.engagementCoffeeEmpty), findsOneWidget);
        final lists0 = api.sent('GET', _list).length;

        await _type(tester, _participants, 'ana, ravi');
        await _type(tester, _deadline, '2026-10-05T18:00:00Z');
        api.json('GET $_list', {
          'polls': [
            _poll(id: 'poll-2', participants: ['me', 'ana', 'ravi']),
          ],
        });
        await _tap(tester, _create);

        final posts = api.sent('POST', _list);
        expect(posts, hasLength(1));
        expect(posts.single.body, {
          'creator_user_id': 'me',
          'participant_user_ids': ['ana', 'ravi'],
          'options': _defaultOptions,
          'deadline_at': '2026-10-05T18:00:00Z',
        });
        final lists = api.sent('GET', _list);
        expect(lists, hasLength(lists0 + 1));
        expect(lists.last.query, {'user_id': 'me', 'limit': 50});
        await qaScrollTo(
          tester,
          find.text(en.engagementCoffeePollId('poll-2')),
        );
        expect(
          find.text(en.engagementCoffeeParticipants('me, ana, ravi')),
          findsOneWidget,
        );
        expect(find.text(en.engagementCoffeeEmpty), findsNothing);
      },
    );

    for (final (label, failure, message) in [
      (
        '400 with the server validation message',
        qaError(400, message: 'participants must be between 2 and 4 users'),
        'participants must be between 2 and 4 users',
      ),
      ('offline', qaOffline, 'Unable to create group poll right now.'),
    ]) {
      testWidgets(
        'a failed create ($label) shows the message in view, keeps the form and retries [case:engagement.group_coffee_polls.create_poll.api_failure]',
        (tester) async {
          final api = _api()..on('POST $_list', (_) => failure);
          await _open(tester, api);
          final lists0 = api.sent('GET', _list).length;
          await _type(tester, _participants, 'ana, ravi');
          await _tap(tester, _create);

          expect(find.text(message), findsOneWidget);
          expect(tester.getRect(find.text(message)).top, lessThan(932));
          expect(qaFieldText(tester, find.byKey(_participants)), 'ana, ravi');
          expect(qaEnabled(tester, find.byKey(_create)), isTrue);
          expect(api.sent('POST', _list), hasLength(1));
          expect(api.sent('GET', _list), hasLength(lists0));

          api.json('POST $_list', {'poll': _poll()});
          await _tap(tester, _create);
          expect(find.text(message), findsNothing);
          expect(api.sent('POST', _list), hasLength(2));
          expect(api.sent('GET', _list), hasLength(lists0 + 1));
        },
      );
    }
  });

  group('participants field', () {
    testWidgets(
      'typed participant ids are split on commas into the create request [case:engagement.group_coffee_polls.participant_user_ids_comma_separ_input.action]',
      (tester) async {
        final api = _api()..json('POST $_list', {'poll': _poll()});
        await _open(tester, api);
        expect(find.text(en.engagementCoffeeParticipantsLabel), findsOneWidget);
        await _type(tester, _participants, 'ana');
        expect(qaFieldText(tester, find.byKey(_participants)), 'ana');
        expect(api.writes, isEmpty);
        await _tap(tester, _create);
        expect(api.sent('POST', _list).single.body['participant_user_ids'], [
          'ana',
        ]);
      },
    );

    testWidgets(
      'blank segments are dropped; an empty list is refused by the server with its message and the form is kept [case:engagement.group_coffee_polls.participant_user_ids_comma_separ_input.validation]',
      (tester) async {
        final api = _api()
          ..on(
            'POST $_list',
            (call) => (call.body['participant_user_ids'] as List).isEmpty
                ? qaError(
                    400,
                    message: 'participants must be between 2 and 4 users',
                  )
                : qaOk({'poll': _poll()}),
          );
        await _open(tester, api);
        await _type(tester, _participants, '   ');
        await _tap(tester, _create);
        expect(
          api.sent('POST', _list).single.body['participant_user_ids'],
          isEmpty,
        );
        expect(
          find.text('participants must be between 2 and 4 users'),
          findsOneWidget,
        );
        expect(qaFieldText(tester, find.byKey(_participants)), '   ');

        await _type(tester, _participants, ' , ana ,, ravi , ');
        await _tap(tester, _create);
        expect(api.sent('POST', _list).last.body['participant_user_ids'], [
          'ana',
          'ravi',
        ]);
        expect(
          find.text('participants must be between 2 and 4 users'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'emoji and right-to-left participant ids reach the server byte-for-byte [case:engagement.group_coffee_polls.participant_user_ids_comma_separ_input.validation]',
      (tester) async {
        final api = _api()..json('POST $_list', {'poll': _poll()});
        await _open(tester, api);
        await _type(tester, _participants, 'مريم, 🦊fox-𝔁');
        await _tap(tester, _create);
        final ids =
            api.sent('POST', _list).single.body['participant_user_ids'] as List;
        expect(ids, ['مريم', '🦊fox-𝔁']);
        expect((ids[1] as String).codeUnits, '🦊fox-𝔁'.codeUnits);
      },
    );
  });

  group('deadline field', () {
    testWidgets(
      'a typed deadline is sent as deadline_at [case:engagement.group_coffee_polls.deadline_iso_optional_input.action]',
      (tester) async {
        final api = _api()..json('POST $_list', {'poll': _poll()});
        await _open(tester, api);
        expect(find.text(en.engagementCoffeeDeadlineLabel), findsOneWidget);
        await _type(tester, _participants, 'ana');
        await _type(tester, _deadline, ' 2026-10-04T09:30:00+05:30 ');
        expect(
          qaFieldText(tester, find.byKey(_deadline)),
          ' 2026-10-04T09:30:00+05:30 ',
        );
        await _tap(tester, _create);
        expect(
          api.sent('POST', _list).single.body['deadline_at'],
          '2026-10-04T09:30:00+05:30',
        );
      },
    );

    testWidgets(
      'an empty or whitespace-only deadline is left out; a past deadline is refused with the server message [case:engagement.group_coffee_polls.deadline_iso_optional_input.validation]',
      (tester) async {
        final api = _api()
          ..on(
            'POST $_list',
            (call) => call.body['deadline_at'] == '2020-01-01T00:00:00Z'
                ? qaError(400, message: 'deadline_at must be in the future')
                : qaOk({'poll': _poll()}),
          );
        await _open(tester, api);
        await _type(tester, _participants, 'ana');
        await _type(tester, _deadline, '   ');
        await _tap(tester, _create);
        expect(
          api.sent('POST', _list).single.body.containsKey('deadline_at'),
          isFalse,
        );

        await _type(tester, _deadline, '2020-01-01T00:00:00Z');
        await _tap(tester, _create);
        expect(find.text('deadline_at must be in the future'), findsOneWidget);
        expect(
          qaFieldText(tester, find.byKey(_deadline)),
          '2020-01-01T00:00:00Z',
        );

        await _type(tester, _deadline, '٢٠٢٦-١٠-٠٤ 🕘');
        await _tap(tester, _create);
        expect(
          (api.sent('POST', _list).last.body['deadline_at'] as String)
              .codeUnits,
          '٢٠٢٦-١٠-٠٤ 🕘'.codeUnits,
        );
      },
    );
  });

  group('option fields', () {
    for (final (name, field, bodyKey, typed, actionTag, validationTag) in [
      (
        'Day',
        'qa.coffee.option1.day',
        'day',
        'Friday',
        '[case:engagement.group_coffee_polls.day_input.action]',
        '[case:engagement.group_coffee_polls.day_input.validation]',
      ),
      (
        'Time window',
        'qa.coffee.option1.time',
        'time_window',
        '18:00-19:30',
        '[case:engagement.group_coffee_polls.time_window_input.action]',
        '[case:engagement.group_coffee_polls.time_window_input.validation]',
      ),
      (
        'Neighborhood',
        'qa.coffee.option1.area',
        'neighborhood',
        'Jayanagar',
        '[case:engagement.group_coffee_polls.neighborhood_input.action]',
        '[case:engagement.group_coffee_polls.neighborhood_input.validation]',
      ),
    ]) {
      testWidgets(
        '$name field edits option 1 in the create request $actionTag',
        (tester) async {
          final api = _api()..json('POST $_list', {'poll': _poll()});
          await _open(tester, api);
          final key = ValueKey(field);
          expect(qaFieldText(tester, find.byKey(key)), isNotEmpty);
          await _type(tester, _participants, 'ana');
          await _type(tester, key, typed);
          expect(qaFieldText(tester, find.byKey(key)), typed);
          await _tap(tester, _create);
          final options =
              api.sent('POST', _list).single.body['options'] as List<Object?>;
          expect((options.first! as Map)[bodyKey], typed);
          expect(options.last, _defaultOptions.last);
        },
      );

      testWidgets(
        '$name blank is refused by the server with its message and kept; emoji/RTL is preserved $validationTag',
        (tester) async {
          const unicode = 'שישי 🌙 ليلة';
          final api = _api()
            ..on(
              'POST $_list',
              (call) =>
                  ((call.body['options'] as List).first as Map)[bodyKey] == ''
                  ? qaError(
                      400,
                      message:
                          'each option requires day, time_window, and neighborhood',
                    )
                  : qaOk({'poll': _poll()}),
            );
          await _open(tester, api);
          final key = ValueKey(field);
          await _type(tester, _participants, 'ana');
          await _type(tester, key, '   ');
          await _tap(tester, _create);
          expect(
            ((api.sent('POST', _list).single.body['options'] as List).first
                as Map)[bodyKey],
            '',
          );
          expect(
            find.text(
              'each option requires day, time_window, and neighborhood',
            ),
            findsOneWidget,
          );
          expect(qaFieldText(tester, find.byKey(key)), '   ');

          await _type(tester, key, unicode);
          await _tap(tester, _create);
          final sent =
              ((api.sent('POST', _list).last.body['options'] as List).first
                      as Map)[bodyKey]
                  as String;
          expect(sent.codeUnits, unicode.codeUnits);
          expect(
            find.text(
              'each option requires day, time_window, and neighborhood',
            ),
            findsNothing,
          );
        },
      );
    }
  });

  group('Vote', () {
    testWidgets(
      'Vote records my vote for that option and the list shows the new count [case:engagement.group_coffee_polls.vote.action]',
      (tester) async {
        final api = _api()
          ..json('POST $_list/poll-1/votes', {'poll': _poll(votes2: 1)});
        await _open(tester, api);
        await qaScrollTo(tester, find.byKey(_vote2));
        expect(
          find.text(_summary('Sunday', '11:00-13:00', 'Koramangala', 0)),
          findsOneWidget,
        );
        final lists0 = api.sent('GET', _list).length;
        api.json('GET $_list', {
          'polls': [_poll(votes2: 1)],
        });

        await _tap(tester, _vote2);

        final votes = api.sent('POST', '$_list/poll-1/votes');
        expect(votes, hasLength(1));
        expect(votes.single.body, {'user_id': 'me', 'option_id': 'opt-2'});
        expect(api.sent('GET', _list), hasLength(lists0 + 1));
        expect(
          find.text(_summary('Sunday', '11:00-13:00', 'Koramangala', 1)),
          findsOneWidget,
        );
        expect(qaEnabled(tester, find.byKey(_vote2)), isTrue);
      },
    );

    for (final (label, failure, message) in [
      (
        '409 with the server message',
        qaError(409, message: 'poll is finalized'),
        'poll is finalized',
      ),
      ('offline', qaOffline, 'Unable to vote right now.'),
    ]) {
      testWidgets(
        'a failed vote ($label) shows the message, keeps the counts and retries [case:engagement.group_coffee_polls.vote.api_failure]',
        (tester) async {
          final api = _api()..on('POST $_list/poll-1/votes', (_) => failure);
          await _open(tester, api);
          final lists0 = api.sent('GET', _list).length;
          await _tap(tester, _vote2);

          expect(find.text(message), findsOneWidget);
          expect(
            find.text(_summary('Sunday', '11:00-13:00', 'Koramangala', 0)),
            findsOneWidget,
          );
          expect(qaEnabled(tester, find.byKey(_vote2)), isTrue);
          expect(api.sent('POST', '$_list/poll-1/votes'), hasLength(1));
          expect(api.sent('GET', _list), hasLength(lists0));

          api.json('POST $_list/poll-1/votes', {'poll': _poll(votes2: 1)});
          await _tap(tester, _vote2);
          expect(find.text(message), findsNothing);
          expect(api.sent('POST', '$_list/poll-1/votes'), hasLength(2));
        },
      );
    }
  });

  group('Finalize Poll', () {
    testWidgets(
      'Finalize Poll closes the poll for everyone and the button goes away [case:engagement.group_coffee_polls.finalize_poll.action]',
      (tester) async {
        final api = _api()
          ..json('POST $_list/poll-1/finalize', {
            'poll': _poll(status: 'finalized'),
          });
        await _open(tester, api);
        await qaScrollTo(tester, find.byKey(_finalize));
        expect(
          find.text(en.engagementCoffeeStatus(en.engagementCoffeeStatusOpen)),
          findsOneWidget,
        );
        api.json('GET $_list', {
          'polls': [_poll(status: 'finalized')],
        });

        await _tap(tester, _finalize);

        expect(api.sent('POST', '$_list/poll-1/finalize').single.body, {
          'user_id': 'me',
        });
        expect(api.sent('GET', _list).last.query, {
          'user_id': 'me',
          'limit': 50,
        });
        expect(
          find.text(
            en.engagementCoffeeStatus(en.engagementCoffeeStatusFinalized),
          ),
          findsOneWidget,
        );
        expect(find.byKey(_finalize), findsNothing);
      },
    );

    for (final (label, failure, message) in [
      (
        '403 with the server message',
        qaError(403, message: 'only the creator can finalize'),
        'only the creator can finalize',
      ),
      ('offline', qaOffline, 'Unable to finalize poll right now.'),
    ]) {
      testWidgets(
        'a failed finalize ($label) shows the message, stays open and retries [case:engagement.group_coffee_polls.finalize_poll.api_failure]',
        (tester) async {
          final api = _api()..on('POST $_list/poll-1/finalize', (_) => failure);
          await _open(tester, api);
          await _tap(tester, _finalize);

          expect(find.text(message), findsOneWidget);
          expect(
            find.text(en.engagementCoffeeStatus(en.engagementCoffeeStatusOpen)),
            findsOneWidget,
          );
          expect(qaEnabled(tester, find.byKey(_finalize)), isTrue);
          expect(api.sent('POST', '$_list/poll-1/finalize'), hasLength(1));

          api.json('POST $_list/poll-1/finalize', {
            'poll': _poll(status: 'finalized'),
          });
          api.json('GET $_list', {
            'polls': [_poll(status: 'finalized')],
          });
          await _tap(tester, _finalize);
          expect(find.text(message), findsNothing);
          expect(find.byKey(_finalize), findsNothing);
        },
      );
    }
  });

  group('action user override field', () {
    testWidgets(
      'an override id is sent as the vote and finalize actor; the server refuses a foreign actor and says so [case:engagement.group_coffee_polls.action_user_id_override_optional_input.action]',
      (tester) async {
        const refusal = 'request actor does not match the authenticated user';
        final api = _api()
          ..fail('POST $_list/poll-1/votes', status: 403, message: refusal)
          ..fail('POST $_list/poll-1/finalize', status: 403, message: refusal);
        await _open(tester, api);
        expect(find.text(en.engagementCoffeeActorLabel), findsOneWidget);
        await _type(tester, _actor, 'ana');
        expect(qaFieldText(tester, find.byKey(_actor)), 'ana');

        await _tap(tester, _vote2);
        expect(api.sent('POST', '$_list/poll-1/votes').single.body, {
          'user_id': 'ana',
          'option_id': 'opt-2',
        });
        expect(find.text(refusal), findsOneWidget);

        await _tap(tester, _finalize);
        expect(api.sent('POST', '$_list/poll-1/finalize').single.body, {
          'user_id': 'ana',
        });
        expect(find.text(refusal), findsOneWidget);
        expect(qaFieldText(tester, find.byKey(_actor)), 'ana');
      },
    );

    testWidgets(
      'a whitespace-only override falls back to me; emoji/RTL ids are sent byte-for-byte (trimmed) [case:engagement.group_coffee_polls.action_user_id_override_optional_input.validation]',
      (tester) async {
        final api = _api()
          ..json('POST $_list/poll-1/votes', {'poll': _poll(votes2: 1)});
        await _open(tester, api);
        await _type(tester, _actor, '   ');
        await _tap(tester, _vote2);
        expect(
          api.sent('POST', '$_list/poll-1/votes').single.body['user_id'],
          'me',
        );

        await _type(tester, _actor, ' نور🌟 ');
        await _tap(tester, _vote2);
        expect(
          (api.sent('POST', '$_list/poll-1/votes').last.body['user_id']
                  as String)
              .codeUnits,
          'نور🌟'.codeUnits,
        );
      },
    );
  });

  group('pull to refresh', () {
    testWidgets(
      'pull to refresh reloads my polls and shows the latest state [case:engagement.group_coffee_polls.finalize_poll_onrefresh.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        final lists0 = api.sent('GET', _list).length;
        api.json('GET $_list', {
          'polls': [_poll(votes1: 3), _poll(id: 'poll-9', status: 'finalized')],
        });
        await qaPullToRefresh(tester);

        final lists = api.sent('GET', _list);
        expect(lists, hasLength(lists0 + 1));
        expect(lists.last.query, {'user_id': 'me', 'limit': 50});
        await qaScrollTo(
          tester,
          find.text(en.engagementCoffeePollId('poll-9')),
        );
        expect(find.text(en.engagementCoffeePollId('poll-9')), findsOneWidget);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed refresh shows the error in view and keeps the polls and the form [case:engagement.group_coffee_polls.finalize_poll_onrefresh.api_failure]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        await _type(tester, _participants, 'ana');
        api.fail('GET $_list', message: 'Polls are unavailable.');
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -2000),
        );
        await tester.pump();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
        await tester.pump();
        await qaPullToRefresh(tester);

        expect(find.text('Polls are unavailable.'), findsOneWidget);
        expect(qaFieldText(tester, find.byKey(_participants)), 'ana');
        await qaScrollTo(tester, find.byKey(_finalize));
        expect(find.text(en.engagementCoffeePollId('poll-1')), findsOneWidget);

        api.json('GET $_list', {
          'polls': [_poll()],
        });
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pump();
        await qaPullToRefresh(tester);
        expect(find.text('Polls are unavailable.'), findsNothing);
      },
    );
  });

  testWidgets(
    'Group coffee polls render translated in every locale without overflow [case:engagement.group_coffee_polls.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        await pumpQa(
          tester,
          _api(),
          const GroupCoffeePollsScreen(),
          locale: locale,
        );
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementCoffeeTitle), findsOneWidget);
        expect(find.text(l.engagementCoffeeParticipantsLabel), findsOneWidget);
        await qaScrollTo(tester, find.byKey(_finalize));
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementCoffeeVote), findsWidgets);
        expect(find.text(l.engagementCoffeeFinalize), findsOneWidget);
        await qaUnmount(tester);
      }
    },
  );
}
