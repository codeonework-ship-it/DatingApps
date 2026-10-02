// Level & XP (release-excluded flag `level_progression_enabled`; the hub
// tests cover the gated state): claim, refresh and retry against the
// recording fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _claimStarter = ValueKey('qa.level.claim.starter_accent');
const _claimPriority = ValueKey('qa.level.claim.prompt_priority');
const _retry = ValueKey('qa.level.retry');

Map<String, dynamic> _progression({
  bool frozen = false,
  bool claimed = false,
  bool trust = true,
  int xp = 320,
}) => {
  'progression': {
    'total_xp': xp,
    'current_level': 3,
    'level_name': 'Reliable Participant',
    'current_level_xp': 70,
    'next_level_xp': 500,
    'progress_percent': 28,
    'trust_gate_satisfied': trust,
    'progression_frozen': frozen,
    'projection_lag_seconds': 0,
    'levels': [
      {
        'level': 3,
        'name': 'Reliable Participant',
        'threshold_xp': 250,
        'trust_gate': false,
        'reward_summary': 'Weekly visibility micro-boost',
      },
    ],
    'rewards': [
      {
        'reward_key': 'starter_accent',
        'level': 2,
        'name': 'Starter accent',
        'description': 'A profile accent earned through activity.',
        'reward_type': 'cosmetic',
        'trust_required': false,
        'claimed': claimed,
      },
      {
        'reward_key': 'prompt_priority',
        'level': 5,
        'name': 'Prompt priority',
        'description': 'Compatible prompts first.',
        'reward_type': 'feature',
        'trust_required': true,
        'claimed': false,
      },
    ],
  },
};

const _ledger = {
  'entries': [
    {
      'sequence': 1,
      'source': 'daily_prompt_submitted',
      'awarded_xp': 20,
      'multiplier': 1,
      'occurred_at': '2026-10-01T10:00:00Z',
    },
  ],
};

QaApi _api() => QaApi()
  ..json('GET /progression/me', _progression())
  ..json('GET /progression/me/ledger', _ledger);

Future<void> _open(WidgetTester tester, QaApi api) =>
    pumpQa(tester, api, const LevelProgressionScreen());

Future<void> _tap(WidgetTester tester, Key key) async {
  await qaScrollTo(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await qaSettle(tester);
}

/// Lets the reward card (6 s) and its particles finish.
Future<void> _pastBurst(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

String _label(WidgetTester tester, Key key) {
  final texts = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(texts.last).data!;
}

void main() {
  group('Claim', () {
    testWidgets(
      'Claim redeems an unlocked reward, reloads my progress and celebrates it [case:engagement.level_progression.locked_onclaim.action]',
      (tester) async {
        final api = _api()
          ..json('POST /progression/me/rewards/claim', {
            'reward': {'reward_key': 'starter_accent', 'claimed': true},
          });
        await _open(tester, api);
        await qaScrollTo(tester, find.byKey(_claimStarter));
        expect(_label(tester, _claimStarter), en.engagementLevelClaim);
        expect(qaEnabled(tester, find.byKey(_claimStarter)), isTrue);
        final gets0 = api.sent('GET', '/progression/me').length;
        api.json('GET /progression/me', _progression(claimed: true, xp: 345));

        await _tap(tester, _claimStarter);

        final claims = api.sent('POST', '/progression/me/rewards/claim');
        expect(claims, hasLength(1));
        expect(claims.single.body, {'reward_key': 'starter_accent'});
        expect(api.sent('GET', '/progression/me'), hasLength(gets0 + 1));
        expect(api.sent('GET', '/progression/me/ledger').last.query, {
          'limit': 30,
        });
        expect(find.text('Reward claimed'), findsOneWidget);
        expect(_label(tester, _claimStarter), en.engagementLevelClaimed);
        expect(qaEnabled(tester, find.byKey(_claimStarter)), isFalse);
        await _pastBurst(tester);
        expect(find.text('Reward claimed'), findsNothing);
        await qaUnmount(tester);
      },
    );

    testWidgets(
      'locked, trust-gated and paused rewards cannot be claimed and send nothing [case:engagement.level_progression.locked_onclaim.gated]',
      (tester) async {
        final api = _api()
          ..json(
            'GET /progression/me',
            _progression(frozen: true, trust: false),
          );
        await _open(tester, api);
        expect(find.text(en.engagementLevelFrozen), findsOneWidget);
        await qaScrollTo(tester, find.byKey(_claimPriority));
        expect(_label(tester, _claimPriority), en.engagementLevelLocked);
        expect(qaEnabled(tester, find.byKey(_claimPriority)), isFalse);
        expect(_label(tester, _claimStarter), en.engagementLevelClaim);
        expect(
          qaEnabled(tester, find.byKey(_claimStarter)),
          isFalse,
          reason: 'progression is paused',
        );
        await tester.tap(find.byKey(_claimPriority), warnIfMissed: false);
        await tester.tap(find.byKey(_claimStarter), warnIfMissed: false);
        await qaSettle(tester);
        expect(api.writes, isEmpty);
      },
    );

    for (final (label, failure, message) in [
      (
        '409 with the server message',
        qaError(409, message: 'Reward already claimed.'),
        'Reward already claimed.',
      ),
      ('offline', qaOffline, 'Unable to claim this reward right now.'),
    ]) {
      testWidgets(
        'a failed claim ($label) explains it, keeps Claim available, does not celebrate and retries [case:engagement.level_progression.locked_onclaim.api_failure]',
        (tester) async {
          final api = _api()
            ..on('POST /progression/me/rewards/claim', (_) => failure);
          await _open(tester, api);
          final gets0 = api.sent('GET', '/progression/me').length;
          await _tap(tester, _claimStarter);

          expect(find.text(message), findsOneWidget);
          expect(find.text('Reward claimed'), findsNothing);
          expect(_label(tester, _claimStarter), en.engagementLevelClaim);
          expect(qaEnabled(tester, find.byKey(_claimStarter)), isTrue);
          expect(
            api.sent('POST', '/progression/me/rewards/claim'),
            hasLength(1),
          );
          expect(api.sent('GET', '/progression/me'), hasLength(gets0));

          api.json('POST /progression/me/rewards/claim', <String, dynamic>{});
          api.json('GET /progression/me', _progression(claimed: true));
          await _tap(tester, _claimStarter);
          expect(find.text(message), findsNothing);
          expect(_label(tester, _claimStarter), en.engagementLevelClaimed);
          expect(
            api.sent('POST', '/progression/me/rewards/claim'),
            hasLength(2),
          );
          await _pastBurst(tester);
          await qaUnmount(tester);
        },
      );
    }
  });

  testWidgets(
    'regression: with a full ledger a failed claim is reported in view, not after the last ledger row [case:engagement.level_progression.locked_onclaim.api_failure]',
    (tester) async {
      final api = _api()
        ..json('GET /progression/me/ledger', {
          'entries': [
            for (var i = 0; i < 30; i++)
              {
                'sequence': i,
                'source': 'daily_prompt_submitted',
                'awarded_xp': 20,
                'multiplier': 1,
              },
          ],
        })
        ..fail(
          'POST /progression/me/rewards/claim',
          status: 409,
          message: 'Reward already claimed.',
        );
      await _open(tester, api);
      await _tap(tester, _claimStarter);

      final error = find.text('Reward already claimed.');
      expect(error, findsOneWidget);
      final rect = tester.getRect(error);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(932));
      expect(error.hitTestable(), findsOneWidget);
    },
  );

  group('pull to refresh', () {
    testWidgets(
      'pull to refresh reloads progress and ledger and shows the paused notice [case:engagement.level_progression.progression_is_paused_while_an_a_onrefresh.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        expect(find.text(en.engagementLevelFrozen), findsNothing);
        expect(find.text(en.engagementLevelXp('320')), findsOneWidget);
        final before = api.calls.length;
        api.json('GET /progression/me', _progression(frozen: true, xp: 360));

        await qaPullToRefresh(tester);

        final reloads = api.calls
            .sublist(before)
            .map((c) => '${c.method} ${c.path} ${c.query}')
            .toList();
        expect(
          reloads,
          unorderedEquals([
            'GET /progression/me {}',
            'GET /progression/me/ledger {limit: 30}',
          ]),
        );
        expect(find.text(en.engagementLevelFrozen), findsOneWidget);
        expect(find.text(en.engagementLevelXp('360')), findsOneWidget);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed refresh keeps my progress on screen, shows the reason and Retry recovers [case:engagement.level_progression.progression_is_paused_while_an_a_onrefresh.api_failure]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        api.fail(
          'GET /progression/me/ledger',
          message: 'Ledger is rebuilding.',
        );
        await qaPullToRefresh(tester);

        expect(find.text('Reliable Participant'), findsWidgets);
        expect(
          find.text('Ledger is rebuilding.').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        api.json('GET /progression/me/ledger', _ledger);
        await _tap(tester, _retry);
        expect(find.text('Ledger is rebuilding.'), findsNothing);
        expect(find.byKey(_retry), findsNothing);
      },
    );
  });

  group('error card Retry', () {
    testWidgets(
      'Retry after a failed first load fetches progress and ledger and shows my level [case:engagement.level_progression.errorcard_onretry_onretry.action]',
      (tester) async {
        final api = _api()..offline('GET /progression/me');
        await _open(tester, api);
        expect(find.text(en.engagementLevelLoadFailed), findsOneWidget);
        expect(find.text('Reliable Participant'), findsNothing);
        final before = api.calls.length;

        api.json('GET /progression/me', _progression());
        await _tap(tester, _retry);

        expect(
          api.calls.sublist(before).map((c) => '${c.method} ${c.path}'),
          unorderedEquals([
            'GET /progression/me',
            'GET /progression/me/ledger',
          ]),
        );
        expect(find.text(en.engagementLevelLoadFailed), findsNothing);
        expect(find.text('Reliable Participant'), findsWidgets);
        expect(find.text(en.engagementLevelNumber(3)), findsOneWidget);
      },
    );

    testWidgets(
      'a Retry that fails again keeps the card with the new reason; the next Retry succeeds [case:engagement.level_progression.errorcard_onretry_onretry.api_failure]',
      (tester) async {
        final api = _api()..fail('GET /progression/me', message: 'Try later.');
        await _open(tester, api);
        expect(find.text('Try later.'), findsOneWidget);

        api.fail('GET /progression/me', status: 503, message: 'Still down.');
        await _tap(tester, _retry);
        expect(find.text('Still down.'), findsOneWidget);
        expect(find.text('Try later.'), findsNothing);
        expect(qaEnabled(tester, find.byKey(_retry)), isTrue);
        expect(tester.takeException(), isNull);

        api.json('GET /progression/me', _progression());
        await _tap(tester, _retry);
        expect(find.byKey(_retry), findsNothing);
        expect(find.text('Reliable Participant'), findsWidgets);
        expect(api.sent('GET', '/progression/me'), hasLength(3));
      },
    );
  });

  testWidgets(
    'Level & XP renders translated in every locale without overflow [case:engagement.level_progression.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        await pumpQa(
          tester,
          _api(),
          const LevelProgressionScreen(),
          locale: locale,
          flags: const {'level_progression_enabled': true},
        );
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementLevelTitle), findsOneWidget);
        expect(find.text(l.engagementLevelPathTitle), findsOneWidget);
        await qaScrollTo(tester, find.byKey(_claimPriority));
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementLevelClaim), findsOneWidget);
        expect(find.text(l.engagementLevelLocked), findsOneWidget);
        await qaUnmount(tester);
      }
    },
  );
}
