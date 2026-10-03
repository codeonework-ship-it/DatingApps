// Local Circle Challenges: join, write and submit this week's entry, refresh.
// Every API-calling control is asserted against the recording fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/circle_challenges_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _books = 'circle-blr-books';
const _join = ValueKey('qa.circles.join.$_books');
const _field = ValueKey('qa.circles.response.$_books');
const _submit = ValueKey('qa.circles.submit.$_books');

Map<String, dynamic> _circle(
  String id,
  String topic, {
  bool joined = false,
  int count = 12,
  String? entry,
}) => {
  'circle_challenge': {
    'circle_id': id,
    'challenge': {
      'id': '$id-2026-W40',
      'city': 'Bengaluru',
      'topic': topic,
      'prompt_text': '$topic prompt of the week',
    },
    'participation_count': count,
    'is_joined': joined,
    if (entry != null) 'user_entry': {'entry_text': entry},
  },
};

QaApi _api({int booksCount = 12}) => QaApi()
  ..json(
    'GET /engagement/circles/circle-blr-books/challenge',
    _circle(_books, 'Books', count: booksCount),
  )
  ..json(
    'GET /engagement/circles/circle-blr-fitness/challenge',
    _circle(
      'circle-blr-fitness',
      'Fitness',
      joined: true,
      count: 7,
      entry: '5k run',
    ),
  )
  ..json(
    'GET /engagement/circles/circle-blr-music/challenge',
    _circle('circle-blr-music', 'Music', joined: true, count: 3),
  );

Future<void> _open(WidgetTester tester, QaApi api) =>
    pumpQa(tester, api, const CircleChallengesScreen());

Future<void> _submitBooks(WidgetTester tester) async {
  await qaScrollTo(tester, find.byKey(_submit));
  await tester.tap(find.byKey(_submit));
  await qaSettle(tester);
}

const _entriesPath = '/engagement/circles/circle-blr-books/challenge/entries';

void main() {
  group('Join Circle', () {
    testWidgets(
      'Join Circle joins this member and flips the card to Joined [case:engagement.circle_challenges.circles_join_x.action]',
      (tester) async {
        final api = _api()
          ..json('POST /engagement/circles/circle-blr-books/join', {
            'membership': {'circle_id': _books, 'user_id': 'me'},
          });
        await _open(tester, api);
        expect(find.text('Books · Bengaluru'), findsOneWidget);
        expect(find.text(en.engagementCirclesNotJoined), findsOneWidget);

        await tester.tap(find.byKey(_join));
        await qaSettle(tester);

        final joins = api.sent(
          'POST',
          '/engagement/circles/circle-blr-books/join',
        );
        expect(joins, hasLength(1));
        expect(joins.single.body, {'user_id': 'me'});
        expect(find.byKey(_join), findsNothing);
        expect(find.text(en.engagementCirclesNotJoined), findsNothing);
        expect(api.writeLines, [
          'POST /engagement/circles/circle-blr-books/join',
        ]);
      },
    );

    testWidgets(
      'a failed join shows the server message, stays Not joined and can be retried [case:engagement.circle_challenges.circles_join_x.api_failure]',
      (tester) async {
        final api = _api()
          ..fail(
            'POST /engagement/circles/circle-blr-books/join',
            status: 409,
            message: 'This circle is full this week.',
          );
        await _open(tester, api);
        await tester.tap(find.byKey(_join));
        await qaSettle(tester);

        expect(find.text('This circle is full this week.'), findsOneWidget);
        expect(find.text(en.engagementCirclesNotJoined), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_join)), isTrue);
        expect(
          api.sent('POST', '/engagement/circles/circle-blr-books/join'),
          hasLength(1),
        );

        api.json(
          'POST /engagement/circles/circle-blr-books/join',
          <String, dynamic>{},
        );
        await tester.tap(find.byKey(_join));
        await qaSettle(tester);
        expect(find.text('This circle is full this week.'), findsNothing);
        expect(find.byKey(_join), findsNothing);
        expect(
          api.sent('POST', '/engagement/circles/circle-blr-books/join'),
          hasLength(2),
        );
      },
    );

    testWidgets(
      'offline join falls back to the localized message [case:engagement.circle_challenges.circles_join_x.api_failure]',
      (tester) async {
        final api = _api()
          ..offline('POST /engagement/circles/circle-blr-books/join');
        await _open(tester, api);
        await tester.tap(find.byKey(_join));
        await qaSettle(tester);
        expect(find.text(en.engagementCirclesJoinFailed), findsOneWidget);
        expect(find.byKey(_join), findsOneWidget);
      },
    );
  });

  group('weekly challenge response', () {
    testWidgets(
      'the response field takes typed text and shows the saved entry of a joined circle [case:engagement.circle_challenges.circles_response_x_input.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        expect(find.text(en.engagementCirclesResponseLabel), findsWidgets);

        await tester.tap(find.byKey(_field));
        await tester.enterText(find.byKey(_field), 'Dune, again');
        await tester.pump();
        expect(qaFieldText(tester, find.byKey(_field)), 'Dune, again');
        expect(find.text('11/$kCircleEntryMaxChars'), findsOneWidget);

        const fitness = ValueKey('qa.circles.response.circle-blr-fitness');
        await qaScrollTo(tester, find.byKey(fitness));
        expect(qaFieldText(tester, find.byKey(fitness)), '5k run');
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'empty and whitespace-only entries are blocked with a localized message [case:engagement.circle_challenges.circles_response_x_input.validation]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        for (final blank in ['', '  \n ']) {
          await tester.enterText(find.byKey(_field), blank);
          await _submitBooks(tester);
          expect(find.text(en.engagementCirclesEnterResponse), findsOneWidget);
        }
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'regression: an entry longer than the server limit is capped at 280 characters before it is sent [case:engagement.circle_challenges.circles_response_x_input.validation]',
      (tester) async {
        final api = _api()..json('POST $_entriesPath', <String, dynamic>{});
        await _open(tester, api);
        await tester.enterText(
          find.byKey(_field),
          'x' * (kCircleEntryMaxChars + 1),
        );
        await tester.pump();
        expect(
          qaFieldText(tester, find.byKey(_field)),
          'x' * kCircleEntryMaxChars,
        );
        await _submitBooks(tester);
        expect(
          api.sent('POST', _entriesPath).single.body['entry_text'],
          'x' * kCircleEntryMaxChars,
        );
      },
    );

    testWidgets(
      'emoji and right-to-left entries reach the server byte-for-byte (trimmed) [case:engagement.circle_challenges.circles_response_x_input.validation]',
      (tester) async {
        const unicode = 'كتاب جميل 📚🇮🇳 — שבוע טוב';
        final api = _api()
          ..json('POST $_entriesPath', {
            'circle_challenge': {'participation_count': 13},
            'entry': {'entry_text': unicode},
          });
        await _open(tester, api);
        await tester.enterText(find.byKey(_field), '\n $unicode  ');
        await _submitBooks(tester);
        final sent =
            api.sent('POST', _entriesPath).single.body['entry_text'] as String;
        expect(sent.codeUnits, unicode.codeUnits);
      },
    );
  });

  group('Submit Entry', () {
    testWidgets(
      "Submit Entry posts this week's entry and the card shows Joined and the new count [case:engagement.circle_challenges.circles_submit_x.action]",
      (tester) async {
        final api = _api()
          ..json('POST $_entriesPath', {
            'circle_challenge': {'participation_count': 13},
            'entry': {'entry_text': 'Dune, again'},
          });
        await _open(tester, api);
        expect(find.text(en.engagementCirclesParticipants(12)), findsOneWidget);

        await tester.enterText(find.byKey(_field), 'Dune, again');
        await _submitBooks(tester);

        final posts = api.sent('POST', _entriesPath);
        expect(posts, hasLength(1));
        expect(posts.single.body, {
          'challenge_id': 'circle-blr-books-2026-W40',
          'user_id': 'me',
          'entry_text': 'Dune, again',
        });
        await tester.scrollUntilVisible(
          find.text('Books · Bengaluru'),
          -250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(en.engagementCirclesParticipants(13)), findsOneWidget);
        expect(find.text(en.engagementCirclesNotJoined), findsNothing);
        expect(find.byKey(_join), findsNothing);
        expect(qaFieldText(tester, find.byKey(_field)), 'Dune, again');
      },
    );

    for (final (label, failure, message) in [
      (
        '500 with the server message',
        qaError(500, message: 'Entries are closed for this week.'),
        'Entries are closed for this week.',
      ),
      ('offline', qaOffline, 'Unable to submit challenge entry right now.'),
    ]) {
      testWidgets(
        'a failed submit ($label) keeps the entry text, re-enables Submit and retries [case:engagement.circle_challenges.circles_submit_x.api_failure]',
        (tester) async {
          final api = _api()..on('POST $_entriesPath', (_) => failure);
          await _open(tester, api);
          await tester.enterText(find.byKey(_field), 'Dune, again');
          await _submitBooks(tester);

          expect(find.text(message), findsOneWidget);
          expect(qaFieldText(tester, find.byKey(_field)), 'Dune, again');
          expect(qaEnabled(tester, find.byKey(_submit)), isTrue);
          expect(api.sent('POST', _entriesPath), hasLength(1));
          await tester.scrollUntilVisible(
            find.text('Books · Bengaluru'),
            -250,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.text(en.engagementCirclesParticipants(12)),
            findsOneWidget,
          );
          expect(find.text(en.engagementCirclesNotJoined), findsOneWidget);

          api.json('POST $_entriesPath', {
            'circle_challenge': {'participation_count': 13},
          });
          await _submitBooks(tester);
          expect(find.text(message), findsNothing);
          expect(api.sent('POST', _entriesPath), hasLength(2));
        },
      );
    }
  });

  group('pull to refresh', () {
    testWidgets(
      "pull to refresh reloads every circle's challenge for this member and shows new counts [case:engagement.circle_challenges.submit_entry_onrefresh.action]",
      (tester) async {
        final api = _api();
        await _open(tester, api);
        final before = api.calls.length;
        api.json(
          'GET /engagement/circles/circle-blr-books/challenge',
          _circle(_books, 'Books', count: 30),
        );
        await qaPullToRefresh(tester);

        final reloads = api.calls.sublist(before);
        expect(reloads.map((c) => '${c.method} ${c.path}'), [
          'GET /engagement/circles/circle-blr-books/challenge',
          'GET /engagement/circles/circle-blr-fitness/challenge',
          'GET /engagement/circles/circle-blr-music/challenge',
        ]);
        for (final call in reloads) {
          expect(call.query, {'user_id': 'me'});
        }
        expect(find.text(en.engagementCirclesParticipants(30)), findsOneWidget);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed refresh shows the error once and keeps the circles and typed text [case:engagement.circle_challenges.submit_entry_onrefresh.api_failure]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        await tester.enterText(find.byKey(_field), 'half-written');
        api.fail(
          'GET /engagement/circles/circle-blr-fitness/challenge',
          message: 'Circles are resting.',
        );
        await qaPullToRefresh(tester);

        expect(find.text('Circles are resting.'), findsOneWidget);
        expect(find.text('Books · Bengaluru'), findsOneWidget);
        expect(qaFieldText(tester, find.byKey(_field)), 'half-written');

        api.json(
          'GET /engagement/circles/circle-blr-fitness/challenge',
          _circle('circle-blr-fitness', 'Fitness', joined: true),
        );
        await qaPullToRefresh(tester);
        expect(find.text('Circles are resting.'), findsNothing);
      },
    );

    testWidgets(
      'regression: a first load that fails shows the empty card with the error once, and a pull recovers [case:engagement.circle_challenges.submit_entry_onrefresh.api_failure]',
      (tester) async {
        final api = _api()
          ..offline('GET /engagement/circles/circle-blr-books/challenge');
        await _open(tester, api);
        expect(find.text(en.engagementCirclesEmptyTitle), findsOneWidget);
        expect(find.text(en.engagementCirclesLoadFailed), findsOneWidget);

        api.json(
          'GET /engagement/circles/circle-blr-books/challenge',
          _circle(_books, 'Books'),
        );
        await qaPullToRefresh(tester);
        expect(find.text(en.engagementCirclesEmptyTitle), findsNothing);
        expect(find.text('Books · Bengaluru'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Circle challenges render translated in every locale without overflow [case:engagement.circle_challenges.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        await pumpQa(
          tester,
          _api(),
          const CircleChallengesScreen(),
          locale: locale,
        );
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementCirclesTitle), findsOneWidget);
        expect(find.text(l.engagementCirclesJoin), findsOneWidget);
        expect(find.text(l.engagementCirclesNotJoined), findsOneWidget);
        expect(find.text(l.engagementCirclesSubmit), findsWidgets);
        await qaUnmount(tester);
      }
    },
  );
}
