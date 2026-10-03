import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/friends/friend_actions.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

import '../../support/qa_api.dart';

// AddFriendButton is the one friend action every surface embeds (matches,
// profiles, rooms, groups, search). Each relation and each style is driven
// here against a stateful fake friends BFF.

Map<String, dynamic> _row(String status, String direction) => {
  'friend_user_id': 'asha',
  'friend_name': 'Asha',
  'status': status,
  'direction': direction,
  'updated_at': '2026-09-30T00:00:00Z',
};

class _World {
  _World({Map<String, dynamic>? asha}) {
    if (asha != null) rows['asha'] = asha;
    api
      ..on('GET /friends/me', (_) => qaOk({'friends': rows.values.toList()}))
      ..json('GET /friends/me/activities', {'activities': <dynamic>[]})
      ..on('POST /friends/me', (c) {
        rows['asha'] = _row('pending', 'outgoing');
        return qaOk({'friend': rows['asha']});
      })
      ..on('POST /friends/me/*/decision', (c) {
        rows['asha'] = _row('accepted', '');
        return qaOk({'success': true});
      })
      ..on('DELETE /friends/me/*', (c) {
        rows.remove('asha');
        return qaOk({'success': true});
      })
      ..json('POST /social/friends/*/channel', {
        'channel': {
          'id': 'ch-asha',
          'kind': 'friend',
          'title': 'Asha',
          'peer_id': 'asha',
        },
      });
  }

  final api = QaApi();
  final rows = <String, Map<String, dynamic>>{};
}

Future<void> _pump(
  WidgetTester tester,
  _World world, {
  AddFriendStyle style = AddFriendStyle.button,
  String name = 'Asha',
  String userId = 'asha',
  Locale? locale,
}) => pumpQa(
  tester,
  world.api,
  Scaffold(
    body: Center(
      child: SizedBox(
        width: 360,
        child: AddFriendButton(
          userId: userId,
          name: name,
          source: FriendRequestSource.room,
          style: style,
        ),
      ),
    ),
  ),
  locale: locale,
);

const _button = ValueKey('qa.add_friend.asha');

String _label(WidgetTester tester) => find
    .descendant(of: find.byKey(_button), matching: find.byType(Text))
    .evaluate()
    .map((e) => (e.widget as Text).data)
    .first!;

void main() {
  testWidgets(
    'Add friend sends a request from its source and turns into Requested '
    '[case:friends.friend_actions.filledbutton_tonalicon_onpressed.action]',
    (tester) async {
      final world = _World();
      await _pump(tester, world);
      expect(_label(tester), 'Add friend');
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(world.api.writeLines, ['POST /friends/me']);
      expect(world.api.writes.single.body, {
        'friend_user_id': 'asha',
        'source': 'room',
      });
      expect(find.text('Friend request sent to Asha.'), findsOneWidget);
      expect(_label(tester), 'Requested');
      expect(find.byType(OutlinedButton), findsOneWidget);
    },
  );

  testWidgets(
    'Accept friend on an incoming request accepts it; Message opens the chat '
    '[case:friends.friend_actions.filledbutton_tonalicon_onpressed.incoming_and_friends]',
    (tester) async {
      final world = _World(asha: _row('pending', 'incoming'));
      await _pump(tester, world);
      expect(_label(tester), 'Accept friend');
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(world.api.writeLines, ['POST /friends/me/asha/decision']);
      expect(world.api.writes.single.body, {'decision': 'accept'});
      expect(find.text('You and Asha are now friends.'), findsOneWidget);
      expect(_label(tester), 'Message');

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(world.api.writeLines.last, 'POST /social/friends/asha/channel');
      final chat = tester.widget<SocialChatScreen>(
        find.byType(SocialChatScreen),
      );
      expect(chat.channelId, 'ch-asha');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  group('cancelling a request', () {
    testWidgets('Requested asks first; Keep it sends nothing '
        '[case:friends.friend_actions.outlinedbutton_icon_onpressed.action] '
        '[case:friends.friend_actions.cancel_request.action] '
        '[case:friends.friend_actions.keep_it.action]', (tester) async {
      final world = _World(asha: _row('pending', 'outgoing'));
      await _pump(tester, world);
      expect(_label(tester), 'Requested');
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(find.text('Cancel your friend request?'), findsOneWidget);
      expect(
        find.text('Asha won’t see your request any more.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(_label(tester), 'Requested');
    });

    testWidgets(
      'Cancel request withdraws it and the button is Add friend again '
      '[case:friends.friend_actions.cancel_request_2.action]',
      (tester) async {
        final world = _World(asha: _row('pending', 'outgoing'));
        await _pump(tester, world);
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Cancel request'));
        await tester.pumpAndSettle();
        expect(world.api.writeLines, ['DELETE /friends/me/asha']);
        expect(find.text('Request cancelled.'), findsOneWidget);
        expect(_label(tester), 'Add friend');
      },
    );

    testWidgets('a failed cancel says why and stays Requested '
        '[case:friends.friend_actions.cancel_request_2.api_failure]', (
      tester,
    ) async {
      final world = _World(asha: _row('pending', 'outgoing'))
        ..api.fail('DELETE /friends/me/*', message: 'Already accepted.');
      await _pump(tester, world);
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel request'));
      await tester.pumpAndSettle();
      expect(find.text('Already accepted.'), findsOneWidget);
      expect(_label(tester), 'Requested');
    });

    testWidgets('without a name the dialog and messages say "this member" '
        '[case:friends.friend_actions.cancel_request.unnamed]', (tester) async {
      final world = _World(asha: _row('pending', 'outgoing'));
      await _pump(tester, world, name: '  ');
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(
        find.text('this member won’t see your request any more.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('the icon style sends the request from the app bar '
      '[case:friends.friend_actions.iconbutton_onpressed.action]', (
    tester,
  ) async {
    final world = _World();
    await _pump(tester, world, style: AddFriendStyle.icon);
    expect(find.byTooltip('Add friend'), findsOneWidget);
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(world.api.writeLines, ['POST /friends/me']);
    expect(find.byTooltip('Requested'), findsOneWidget);
  });

  testWidgets(
    'the tile style (option sheets) sends the request and explains itself '
    '[case:friends.friend_actions.listtile_ontap.action]',
    (tester) async {
      final world = _World();
      await _pump(tester, world, style: AddFriendStyle.tile);
      expect(
        find.text('Friends can message and plan things together'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(world.api.writeLines, ['POST /friends/me']);
      expect(find.text('Waiting for Asha. Tap to cancel.'), findsOneWidget);
    },
  );

  testWidgets(
    'a refused request shows the server reason and the button stays usable; '
    'while sending a second tap sends nothing '
    '[case:friends.friend_actions.filledbutton_tonalicon_onpressed.api_failure]',
    (tester) async {
      final world = _World()
        ..api.fail(
          'POST /friends/me',
          status: 429,
          message: 'You can send 30 requests a day.',
        );
      await _pump(tester, world);
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(find.text('You can send 30 requests a day.'), findsOneWidget);
      expect(_label(tester), 'Add friend');

      // Slow server: the button is busy and ignores another tap.
      world.api.on(
        'POST /friends/me',
        (_) => QaReply(200, {
          'friend': _row('pending', 'outgoing'),
        }, delay: const Duration(milliseconds: 500)),
      );
      world.rows['asha'] = _row('pending', 'outgoing');
      await tester.tap(find.byKey(_button));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(_button), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(world.api.sent('POST', '/friends/me'), hasLength(2));

      // Offline: the localized fallback for a request with no reply.
      world.rows.clear();
      await tester.pumpWidget(const SizedBox());
      final offline = _World()..api.offline('POST /friends/me');
      await _pump(tester, offline);
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(
        find.text(qaL10n(const Locale('en')).networkOfflineTryAgain),
        findsOneWidget,
      );
    },
  );

  testWidgets('the button is hidden on my own profile '
      '[case:friends.friend_actions.self_hidden]', (tester) async {
    final world = _World();
    await _pump(tester, world, userId: 'me');
    expect(find.byKey(const ValueKey('qa.add_friend.me')), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the friend action renders translated in every locale '
      '[case:friends.friend_actions.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await _pump(tester, _World(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(_label(tester), qaL10n(locale).friendsAddFriend);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
