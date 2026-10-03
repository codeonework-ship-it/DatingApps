// Match nudges: the Nudge button against the recording fake BFF, with the
// real matches provider loading from GET /matches/me.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/match_nudges_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _send = '/engagement/match-nudges/send';
const _nudgeMaya = ValueKey('qa.nudges.send.match-1');

QaApi _api() => QaApi()
  ..json('GET /matches/me', {
    'matches': [
      {'id': 'match-1', 'user_id': 'maya', 'user_name': 'Maya'},
      {'id': 'match-2', 'user_id': 'theo', 'user_name': 'Theo'},
    ],
  });

Map<String, dynamic> _nudge() => {
  'nudge': {
    'id': 'nudge-1',
    'match_id': 'match-1',
    'user_id': 'me',
    'counterparty_user_id': 'maya',
    'nudge_type': 'stalled_24h',
    'sent_at': '2026-10-02T09:00:00Z',
  },
};

Future<void> _open(WidgetTester tester, QaApi api) =>
    pumpQa(tester, api, const MatchNudgesScreen());

Finder _status(String text) => find.descendant(
  of: find.ancestor(of: find.text('Maya'), matching: find.byType(Row)).first,
  matching: find.text(text),
);

void main() {
  testWidgets(
    'Nudge sends a stalled-conversation nudge for that match, confirms it and marks the row sent [case:engagement.match_nudges.nudge.action]',
    (tester) async {
      final api = _api()..json('POST $_send', _nudge());
      await _open(tester, api);
      expect(_status(en.engagementNudgesReady), findsOneWidget);

      await tester.tap(find.byKey(_nudgeMaya));
      await qaSettle(tester);

      final sent = api.sent('POST', _send);
      expect(sent, hasLength(1));
      expect(sent.single.body, {
        'match_id': 'match-1',
        'user_id': 'me',
        'counterparty_user_id': 'maya',
        'nudge_type': 'stalled_24h',
      });
      expect(qaSnackText(tester), en.engagementNudgesSentTo('Maya'));
      expect(_status(en.engagementNudgesSentInSession), findsOneWidget);
      expect(
        find.text(en.engagementNudgesReady),
        findsOneWidget,
        reason: 'Theo is untouched',
      );
      expect(qaEnabled(tester, find.byKey(_nudgeMaya)), isTrue);
    },
  );

  for (final (label, failure, message) in [
    (
      '429 with the server message',
      qaError(429, message: 'Daily nudge limit reached.'),
      'Daily nudge limit reached.',
    ),
    (
      'offline',
      qaOffline,
      "Can't connect right now. Check your internet connection and try again.",
    ),
    (
      'a reply without the nudge',
      qaOk({'ok': true}),
      'Unable to send this nudge.',
    ),
  ]) {
    testWidgets(
      'a failed nudge ($label) shows the reason on that row, no confirmation, and retries [case:engagement.match_nudges.nudge.api_failure]',
      (tester) async {
        final api = _api()..on('POST $_send', (_) => failure);
        await _open(tester, api);
        await tester.tap(find.byKey(_nudgeMaya));
        await qaSettle(tester);

        expect(_status(message), findsOneWidget);
        expect(qaSnackText(tester), isNull);
        expect(qaEnabled(tester, find.byKey(_nudgeMaya)), isTrue);
        expect(api.sent('POST', _send), hasLength(1));

        api.json('POST $_send', _nudge());
        await tester.tap(find.byKey(_nudgeMaya));
        await qaSettle(tester);
        expect(_status(message), findsNothing);
        expect(_status(en.engagementNudgesSentInSession), findsOneWidget);
        expect(api.sent('POST', _send), hasLength(2));
      },
    );
  }

  testWidgets(
    'with no matches there is nothing to nudge and nothing is sent [case:engagement.match_nudges.nudge.empty]',
    (tester) async {
      final api = QaApi()..json('GET /matches/me', {'matches': <Object>[]});
      await _open(tester, api);
      expect(find.text(en.engagementNudgesEmpty), findsOneWidget);
      expect(find.text(en.engagementNudgesAction), findsNothing);
      expect(api.writes, isEmpty);
    },
  );

  testWidgets(
    'Match nudges render translated in every locale without overflow [case:engagement.match_nudges.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        await pumpQa(tester, _api(), const MatchNudgesScreen(), locale: locale);
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementNudgesTitle), findsOneWidget);
        expect(find.text(l.engagementNudgesIntro), findsOneWidget);
        expect(find.text(l.engagementNudgesAction), findsNWidgets(2));
        expect(find.text(l.engagementNudgesReady), findsNWidgets(2));
        await qaUnmount(tester);
      }
    },
  );
}
