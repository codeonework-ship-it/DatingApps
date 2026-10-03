// Control tests for the chat's connection card and the private "A little
// chemistry" sheet (lib/features/intentional_dating/connection_card.dart),
// against the recording fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

const _connection = '/matches/m/connection';

Map<String, dynamic> _openMoment() => {
  'id': 'mo-1',
  'prompt': 'sunday',
  'status': 'open',
  'options': {'food': 'Brunch first', 'bookstore': 'A bookstore wander'},
};

/// A stateful fake: the connection read reflects what the member sent.
class _ChemistryWorld {
  _ChemistryWorld({Map<String, dynamic>? moment, this.reasons = const []})
    : _moment = moment {
    api
      ..on('GET $_connection', (_) => qaOk(read()))
      ..on('POST /matches/m/moments', (call) {
        _moment = {..._openMoment(), 'id': call.body['id']};
        return qaOk({'moment': _moment});
      })
      ..on('POST /matches/m/moments/*/answer', (call) {
        _moment = {
          ..._moment!,
          'status': 'waiting',
          'my_answer': call.body['answer'],
        };
        return qaOk({'moment': _moment});
      });
  }

  final api = QaApi();
  final List<String> reasons;
  Map<String, dynamic>? _moment;

  Map<String, dynamic> read() => {
    'chapter_status': '',
    'reasons': reasons,
    'moment': _moment,
  };

  void heal() {
    api.on('GET $_connection', (_) => qaOk(read()));
  }
}

Future<void> _pumpSheet(WidgetTester t, _ChemistryWorld w, {Locale? locale}) =>
    pumpQa(
      t,
      w.api,
      const Scaffold(body: ChemistrySheet(matchId: 'm')),
      locale: locale,
    );

void main() {
  final en = qaL10n(const Locale('en'));

  testWidgets('tapping "A little chemistry?" on the card opens the sheet for '
      'this match, and Close dismisses it '
      '[case:intentional_dating.connection_card.connection_chemistry.action] '
      '[case:intentional_dating.connection_card.a_little_chemistry.action]', (
    t,
  ) async {
    final w = _ChemistryWorld(reasons: ['You both enjoy coffee']);
    await pumpQa(
      t,
      w.api,
      const Scaffold(body: DatingConnectionCard(matchId: 'm')),
    );
    expect(find.byType(ChemistrySheet), findsNothing);

    await t.tap(find.byKey(const ValueKey('qa.connection.chemistry')));
    await qaSettle(t);

    final sheet = t.widget<ChemistrySheet>(find.byType(ChemistrySheet));
    expect(sheet.matchId, 'm');
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(en.chemistryTitle), findsOneWidget);
    expect(find.text('You both enjoy coffee'), findsOneWidget);
    expect(find.text(en.chemistryChooseMoment), findsOneWidget);
    expect(find.text(en.chemistryPromptSunday), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('qa.chemistry.close')));
    await qaSettle(t);
    expect(find.byType(ChemistrySheet), findsNothing);
    expect(find.byKey(const ValueKey('qa.connection.chemistry')), findsOne);
    await idTeardown(t);
  });

  testWidgets(
    'tapping "Create your first chapter" opens First Chapter Studio '
    'for this match '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.connection_card.create_your_first_chapter.action]',
    (t) async {
      final w = _ChemistryWorld();
      await pumpQa(
        t,
        w.api,
        const Scaffold(body: DatingConnectionCard(matchId: 'm')),
      );
      expect(find.byType(ChapterStudioScreen), findsNothing);

      await t.tap(find.text(en.datingConnectionCreate));
      await qaSettle(t);

      final studio = t.widget<ChapterStudioScreen>(
        find.byType(ChapterStudioScreen),
      );
      expect(studio.matchId, 'm');
      expect(w.api.sent('GET', '/matches/m/chapter'), isNotEmpty);
      await idTeardown(t);
    },
  );

  testWidgets(
    'choosing an answer sends it for the open moment and shows the '
    'private waiting state '
    '[case:intentional_dating.connection_card.outlinedbutton_onpressed.action]',
    (t) async {
      final w = _ChemistryWorld(moment: _openMoment());
      await _pumpSheet(t, w);
      expect(find.text(en.chemistryQuestionSunday), findsOneWidget);
      expect(find.text('Brunch first'), findsOneWidget);

      await t.tap(find.widgetWithText(OutlinedButton, 'A bookstore wander'));
      await qaSettle(t);

      final answer = w.api.sent('POST', '/matches/m/moments/mo-1/answer');
      expect(answer, hasLength(1));
      expect(answer.single.body, {'answer': 'bookstore'});
      // The sheet re-reads the connection and shows the saved choice only.
      expect(w.api.sent('GET', _connection), hasLength(2));
      expect(find.text(en.chemistryWaitingBody), findsOneWidget);
      expect(
        find.text(en.chemistryYourChoice('A bookstore wander')),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Brunch first'), findsNothing);
      await idTeardown(t);
    },
  );

  testWidgets(
    'choosing a moment starts it with one id that a retry after a '
    'failure reuses '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.connection_card.outlinedbutton_onpressed_2.action]',
    (t) async {
      final w = _ChemistryWorld();
      w.api.fail('POST /matches/m/moments', message: 'Moments are resting.');
      await _pumpSheet(t, w);

      await t.tap(
        find.widgetWithText(OutlinedButton, en.chemistryPromptSunday),
      );
      await qaSettle(t);
      final first = w.api.sent('POST', '/matches/m/moments').single.body;
      expect(first['prompt'], 'sunday');
      expect(first['id'], isA<String>());
      expect((first['id'] as String).length, 36);
      expect(find.text('Moments are resting.'), findsOneWidget);
      // The choices stay available.
      expect(
        find.widgetWithText(OutlinedButton, en.chemistryPromptSunday),
        findsOneWidget,
      );

      w.api.on('POST /matches/m/moments', (call) {
        w._moment = {..._openMoment(), 'id': call.body['id']};
        return qaOk({'moment': w._moment});
      });
      await t.tap(
        find.widgetWithText(OutlinedButton, en.chemistryPromptSunday),
      );
      await qaSettle(t);
      final sent = w.api.sent('POST', '/matches/m/moments');
      expect(sent, hasLength(2));
      expect(sent.last.body, {'id': first['id'], 'prompt': 'sunday'});
      expect(find.text('Moments are resting.'), findsNothing);
      // The started moment's question replaces the prompt list.
      expect(find.text(en.chemistryQuestionSunday), findsOneWidget);
      expect(find.text('Brunch first'), findsOneWidget);
      await idTeardown(t);
    },
  );

  testWidgets('"Try loading again" re-reads the connection after a failed '
      'load and shows the moments '
      '[case:intentional_dating.connection_card.try_loading_again.action]', (
    t,
  ) async {
    final w = _ChemistryWorld();
    w.api.fail('GET $_connection');
    await _pumpSheet(t, w);
    expect(find.text(en.chemistryRetry), findsOneWidget);
    expect(find.text(en.chemistryPromptSunday), findsNothing);
    final before = w.api.sent('GET', _connection).length;

    w.heal();
    await t.tap(find.text(en.chemistryRetry));
    await qaSettle(t);

    expect(w.api.sent('GET', _connection).length, before + 1);
    expect(find.text(en.chemistryRetry), findsNothing);
    expect(find.text(en.chemistryPromptSunday), findsOneWidget);
    await idTeardown(t);
  });

  testWidgets('the chemistry sheet renders translated in every locale '
      '[case:intentional_dating.connection_card.l10n]', (t) async {
    // The choose-a-moment state.
    await idSweepLocales(
      t,
      pump: (locale) =>
          _pumpSheet(t, _ChemistryWorld(reasons: ['Kaffee']), locale: locale),
      labels: (l10n) => [
        l10n.chemistryTitle,
        l10n.chemistryIntro,
        l10n.chemistryChooseMoment,
        l10n.chemistryPromptSunday,
        l10n.chemistryPromptAdventure,
        l10n.chemistryPromptFirstDate,
      ],
      fixture: {'Kaffee'},
    );
    // An open moment and a revealed one.
    await idSweepLocales(
      t,
      pump: (locale) =>
          _pumpSheet(t, _ChemistryWorld(moment: _openMoment()), locale: locale),
      labels: (l10n) => [l10n.chemistryQuestionSunday],
      fixture: {'Brunch first', 'A bookstore wander'},
    );
    await idSweepLocales(
      t,
      pump: (locale) => _pumpSheet(
        t,
        _ChemistryWorld(
          moment: {
            ..._openMoment(),
            'status': 'revealed',
            'my_answer': 'food',
            'partner_answer': 'bookstore',
          },
        ),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.chemistryRevealedTitle,
        l10n.chemistryYouPicked,
        l10n.chemistryMatchPicked,
        l10n.chemistryRevealedBody,
        l10n.chemistryAnotherMoment,
      ],
      fixture: {'Brunch first', 'A bookstore wander'},
    );
    // The card in the chat.
    await idSweepLocales(
      t,
      pump: (locale) => pumpQa(
        t,
        _ChemistryWorld().api,
        const Scaffold(body: DatingConnectionCard(matchId: 'm')),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.datingConnectionCreate,
        l10n.datingConnectionBody,
        l10n.chemistryCardEntry,
      ],
    );
  });
}
