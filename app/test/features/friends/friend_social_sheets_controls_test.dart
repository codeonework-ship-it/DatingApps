import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/friends/providers/friends_provider.dart';
import 'package:verified_dating_app/features/friends/widgets/friend_social_sheets.dart';

import '../../support/qa_api.dart';

// The vouch and intro sheets: what they send, what they refuse to send, and
// how they behave when the server says no.

const _dev = FriendConnection(
  friendUserId: 'dev',
  friendName: 'Dev',
  status: 'accepted',
  direction: '',
  updatedAt: '',
);
const _meera = FriendConnection(
  friendUserId: 'meera',
  friendName: 'Meera',
  status: 'accepted',
  direction: '',
  updatedAt: '',
);
const _tara = FriendConnection(
  friendUserId: 'tara',
  friendName: 'Tara',
  status: 'pending',
  direction: 'outgoing',
  updatedAt: '',
);

QaApi _api() => QaApi()
  ..json('GET /friends/me/vouches', {
    'about_me': <dynamic>[],
    'written': <dynamic>[],
  })
  ..json('GET /friends/me/intros', {
    'received': <dynamic>[],
    'made': <dynamic>[],
  })
  ..json('POST /friends/me/vouches', {'success': true})
  ..json('POST /friends/me/intros', {'success': true});

/// Opens [sheet] from a page and records what it resolves to.
Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api,
  Future<bool?> Function(BuildContext context) sheet, {
  Locale? locale,
}) async {
  final results = <Object?>[];
  await pumpQa(
    tester,
    api,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => results.add(await sheet(context)),
            child: const Text('open sheet'),
          ),
        ),
      ),
    ),
    locale: locale,
  );
  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
  return results;
}

Future<List<Object?>> _vouch(
  WidgetTester tester,
  QaApi api, {
  Locale? locale,
}) => _open(
  tester,
  api,
  (c) => showVouchSheet(context: c, friend: _dev),
  locale: locale,
);

Future<List<Object?>> _intro(
  WidgetTester tester,
  QaApi api, {
  List<FriendConnection> friends = const [_dev, _meera, _tara],
  FriendConnection? preselected,
  Locale? locale,
}) => _open(
  tester,
  api,
  (c) => showIntroSheet(context: c, friends: friends, preselected: preselected),
  locale: locale,
);

Finder _key(String key) => find.byKey(ValueKey(key));

const _vouchText = ValueKey('qa.friends.vouch_text');
const _vouchSubmit = ValueKey('qa.friends.vouch_submit');

void main() {
  group('vouch sheet', () {
    testWidgets(
      'opens for that friend with the field and Send vouch '
      '[case:friends.friend_social_sheets.showmodalbottomsheet_open.action]',
      (tester) async {
        await _vouch(tester, _api());
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Vouch for Dev'), findsOneWidget);
        expect(find.byKey(_vouchText), findsOneWidget);
        expect(find.byKey(_vouchSubmit), findsOneWidget);
      },
    );

    testWidgets('typing fills the vouch and counts towards 200 characters '
        '[case:friends.friend_social_sheets.friends_vouch_text_input.action]', (
      tester,
    ) async {
      await _vouch(tester, _api());
      await tester.enterText(find.byKey(_vouchText), 'Kind and funny');
      await tester.pump();
      expect(find.text('Kind and funny'), findsOneWidget);
      expect(find.text('14/200'), findsOneWidget);
    });

    testWidgets(
      'too short (after trimming) is refused with a message and nothing is '
      'sent; the field stops at 200; emoji and RTL text are sent as typed '
      '[case:friends.friend_social_sheets.friends_vouch_text_input.validation]',
      (tester) async {
        final api = _api();
        await _vouch(tester, api);
        for (final text in ['', '   short    ', '           ']) {
          await tester.enterText(find.byKey(_vouchText), text);
          await tester.tap(find.byKey(_vouchSubmit));
          await tester.pump();
          expect(
            find.text('Say a little more (at least 12 characters).'),
            findsOneWidget,
          );
        }
        expect(api.writes, isEmpty);

        await tester.enterText(find.byKey(_vouchText), 'x' * 250);
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byKey(_vouchText)).controller!.text,
          hasLength(200),
        );

        const unicode = 'Всегда приходит вовремя 😊 دائما لطيف';
        await tester.enterText(find.byKey(_vouchText), '  $unicode  ');
        await tester.tap(find.byKey(_vouchSubmit));
        await tester.pumpAndSettle();
        expect(api.sent('POST', '/friends/me/vouches').single.body, {
          'for_user_id': 'dev',
          'text': unicode,
        });
      },
    );

    testWidgets('Send vouch posts it, reloads vouches and closes with true '
        '[case:friends.friend_social_sheets.friends_vouch_submit.action]', (
      tester,
    ) async {
      final api = _api();
      final results = await _vouch(tester, api);
      await tester.enterText(
        find.byKey(_vouchText),
        'Kind, funny and always on time.',
      );
      await tester.tap(find.byKey(_vouchSubmit));
      await tester.pumpAndSettle();

      expect(api.writeLines, ['POST /friends/me/vouches']);
      expect(api.writes.single.body, {
        'for_user_id': 'dev',
        'text': 'Kind, funny and always on time.',
      });
      expect(api.calls.last.method, 'GET', reason: 'reloaded after send');
      expect(find.byType(BottomSheet), findsNothing);
      expect(results, [true]);
    });

    testWidgets(
      'a refused vouch stays open with the reason, keeps the text, and a '
      'retry sends once more [case:friends.friend_social_sheets.friends_vouch_submit.api_failure]',
      (tester) async {
        final api = _api()
          ..fail(
            'POST /friends/me/vouches',
            status: 409,
            message: 'You already vouched for Dev.',
          );
        final results = await _vouch(tester, api);
        await tester.enterText(
          find.byKey(_vouchText),
          'Kind, funny and always on time.',
        );
        await tester.tap(find.byKey(_vouchSubmit));
        await tester.pumpAndSettle();
        expect(find.text('You already vouched for Dev.'), findsOneWidget);
        expect(find.text('Kind, funny and always on time.'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byKey(_vouchSubmit)).onPressed,
          isNotNull,
        );

        api.on('POST /friends/me/vouches', (_) => const QaReply(500, null));
        await tester.tap(find.byKey(_vouchSubmit));
        await tester.pumpAndSettle();
        expect(find.text('Unable to send this vouch.'), findsOneWidget);

        api.json('POST /friends/me/vouches', {'success': true});
        await tester.tap(find.byKey(_vouchSubmit));
        await tester.pumpAndSettle();
        expect(api.sent('POST', '/friends/me/vouches'), hasLength(3));
        expect(results, [true]);
      },
    );
  });

  group('intro sheet', () {
    testWidgets(
      'opens with two pickers of accepted friends only '
      '[case:friends.friend_social_sheets.showmodalbottomsheet_open_2.action]',
      (tester) async {
        await _intro(tester, _api());
        expect(find.text('Introduce two friends'), findsOneWidget);
        expect(_key('qa.friends.intro_first.dev'), findsOneWidget);
        expect(_key('qa.friends.intro_second.meera'), findsOneWidget);
        expect(_key('qa.friends.intro_first.tara'), findsNothing);
      },
    );

    testWidgets(
      'choosing a first friend selects it and removes it from the second '
      'list [case:friends.friend_social_sheets.friends_intro_first.action]',
      (tester) async {
        await _intro(tester, _api());
        await tester.tap(_key('qa.friends.intro_first.dev'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ChoiceChip>(_key('qa.friends.intro_first.dev'))
              .selected,
          isTrue,
        );
        expect(_key('qa.friends.intro_second.dev'), findsNothing);
      },
    );

    testWidgets(
      'choosing a second friend selects it and removes it from the first '
      'list [case:friends.friend_social_sheets.friends_intro_second.action]',
      (tester) async {
        await _intro(tester, _api());
        await tester.tap(_key('qa.friends.intro_second.meera'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ChoiceChip>(_key('qa.friends.intro_second.meera'))
              .selected,
          isTrue,
        );
        expect(_key('qa.friends.intro_first.meera'), findsNothing);
      },
    );

    testWidgets(
      'the note is sent trimmed with the intro and the sheet closes with true '
      '[case:friends.friend_social_sheets.friends_intro_message_input.action]',
      (tester) async {
        final api = _api();
        final results = await _intro(tester, api, preselected: _dev);
        expect(
          tester
              .widget<ChoiceChip>(_key('qa.friends.intro_first.dev'))
              .selected,
          isTrue,
        );
        await tester.tap(_key('qa.friends.intro_second.meera'));
        await tester.enterText(
          _key('qa.friends.intro_message'),
          '  You both love jazz.  ',
        );
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(api.sent('POST', '/friends/me/intros').single.body, {
          'first_user_id': 'dev',
          'second_user_id': 'meera',
          'message': 'You both love jazz.',
        });
        expect(results, [true]);
      },
    );

    testWidgets(
      'one friend is not enough; a blank note is left out; the note stops at '
      '200 and keeps emoji '
      '[case:friends.friend_social_sheets.friends_intro_message_input.validation]',
      (tester) async {
        final api = _api();
        await _intro(tester, api);
        await tester.tap(_key('qa.friends.intro_first.dev'));
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(find.text('Choose two different friends.'), findsOneWidget);
        expect(api.writes, isEmpty);

        await tester.enterText(_key('qa.friends.intro_message'), 'y' * 260);
        await tester.pump();
        expect(
          tester
              .widget<TextField>(_key('qa.friends.intro_message'))
              .controller!
              .text,
          hasLength(200),
        );
        await tester.enterText(_key('qa.friends.intro_message'), '    ');
        await tester.tap(_key('qa.friends.intro_second.meera'));
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(api.sent('POST', '/friends/me/intros').single.body, {
          'first_user_id': 'dev',
          'second_user_id': 'meera',
        });

        // With fewer than two accepted friends the sheet explains and the
        // button is off.
        await tester.pumpWidget(const SizedBox());
        await _intro(tester, _api(), friends: const [_dev, _tara]);
        expect(
          find.text('You need at least two accepted friends to make an intro.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(_key('qa.friends.intro_submit'))
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'a refused intro stays open with the reason and a retry works '
      '[case:friends.friend_social_sheets.friends_intro_submit.api_failure]',
      (tester) async {
        final api = _api()
          ..fail(
            'POST /friends/me/intros',
            status: 409,
            message: 'Dev and Meera already know each other.',
          );
        final results = await _intro(tester, api);
        await tester.tap(_key('qa.friends.intro_first.dev'));
        await tester.tap(_key('qa.friends.intro_second.meera'));
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(
          find.text('Dev and Meera already know each other.'),
          findsOneWidget,
        );
        expect(find.text('Introduce two friends'), findsOneWidget);

        api.offline('POST /friends/me/intros');
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(
          find.text(qaL10n(const Locale('en')).networkCannotReachService),
          findsOneWidget,
        );

        api.json('POST /friends/me/intros', {'success': true});
        await tester.tap(_key('qa.friends.intro_submit'));
        await tester.pumpAndSettle();
        expect(api.sent('POST', '/friends/me/intros'), hasLength(3));
        expect(results, [true]);
      },
    );
  });

  testWidgets('both sheets render translated in every locale '
      '[case:friends.friend_social_sheets.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await _vouch(tester, _api(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale vouch');
      expect(find.text(l10n.friendsVouchTitle('Dev')), findsOneWidget);
      expect(find.text(l10n.friendsVouchSend), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      await _intro(tester, _api(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale intro');
      expect(find.text(l10n.friendsIntroSheetTitle), findsOneWidget);
      expect(find.text(l10n.friendsIntroSubmit), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
